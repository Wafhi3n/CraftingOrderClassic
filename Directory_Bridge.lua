-- Directory_Bridge.lua — pont entre royaumes, paliers 2 et 3 (spec docs/specs/pont-royaumes.md).
--
-- Sous le méga-serveur de Forever, un canal s'arrête au royaume (mesuré le 2026-10-07) : chaque royaume
-- a sa copie de la salle CraftLinkNet, et du Commerce du jeu. Le chuchotement, lui, traverse. Un porteur
-- qui arrive se présente donc lui-même aux AUTRES royaumes :
--   1. à sa connexion, la première réponse directe d'un porteur d'un autre royaume (son `rm=` vient avec
--      sa fiche, palier 1) reçoit « présente-moi » : INT en whisper ;
--   2. ce passeur poste la présentation dans SA salle : INT sur la salle ;
--   3. chaque membre de cette salle qui ne connaît pas l'arrivant lui dit un bonjour LÉGER (HL : sa fiche
--      de métiers, rien d'autre), qui reçoit au plus un bonjour léger en retour.
-- Ensuite, tout passe par les chemins existants (chuchotement aux pairs connus, D9 : mes commandes
-- ouvertes qui le concernent partent au premier contact, comme pour tout pair qui passe en ligne).
--
-- Fil :  INT|<Prénom Nom>|<royaume>                  whisper (demande) ou salle (présentation postée)
--        HL|SK|lvl=…|rm=…;…   ou   HL|rm=<royaume>       bonjour léger, whisper
-- Palier 3 : l'arrivant qui ne connaît personne ailleurs est présenté par le passeur ÉLU de sa salle
-- (le plus petit nom des porteurs à jour présents). La salle d'en face n'accepte une demande pour un
-- AUTRE que de la part d'un pair qu'elle connaît en direct et dont le royaume est celui du présenté ;
-- sinon, seulement de l'arrivant lui-même (palier 2). Budget (D7) :
-- 10 présentations par émetteur / 10 min ; une même personne pas représentée plus d'une fois / 6 h,
-- gardé en SavedVariables à l'heure réelle (une minuterie de session repartirait à chaque connexion).
-- Coupé avec la salle (D8 : /co channel room off). Jamais un second saut : une présentation reçue ne
-- déclenche jamais de demande.

local COC = CraftingOrderClassic
local Dir = COC.Directory

local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)

local ASK_WINDOW      = 120          -- s après le chargement : la fenêtre où l'arrivant se présente
local REPEAT_EVERY    = 6 * 3600     -- s, heure réelle : une personne n'est pas représentée plus souvent
local SEEN_FOR        = 600          -- s : une présentation vue dans la salle n'y est pas reposée
local CAP, CAP_WINDOW = 10, 600      -- présentations acceptées par émetteur, par fenêtre (s)
local HL_FOR          = 600          -- s : après mon bonjour léger, le sien est une réponse
local POST_JITTER     = 3            -- s : délai aléatoire avant de poster (un second passeur se tait)
local HELLO_JITTER    = 5            -- s : étale les bonjours légers des membres de la salle
local HL_PER_MIN      = 20           -- bonjours légers spontanés par minute, tous noms confondus
local SHORT_LOCK      = 600          -- s, heure réelle : verrou d'une demande pas encore confirmée
local RETRY_AFTER     = 30           -- s : sans confirmation, un 2e passeur du même royaume est essayé

local function now() return (GetTime and GetTime()) or 0 end
local function clock() return (time and time()) or 0 end
local function trace(msg) if COC.Trace then COC.Trace:Log("net", msg) end end
local function me() return COC.Api.PlayerName() end
local function fullName(n) local f = COC.Api.IsFullPlayerName; return n ~= nil and (not f or f(n)) end
local function after(delay, fn)
    if C_Timer and C_Timer.After then C_Timer.After(delay, fn) else fn() end
end

local loadedAt = now()

local function state()
    local s = Dir._bridge
    if not s then s = { asked = {}, seen = {}, cap = {}, capTraced = {}, hl = {}, burst = {} }; Dir._bridge = s end
    return s
end

-- Un numéro de royaume plausible (le fil est lisible par tous : un nombre démesuré ne passe pas).
local function validRealm(r) return type(r) == "number" and r > 0 and r < 2147483647 end

local function store()
    if not COC.db then return nil end
    COC.db.bridge = COC.db.bridge or {}
    local b = COC.db.bridge
    b.selfIntro, b.posted, b.vouched = b.selfIntro or {}, b.posted or {}, b.vouched or {}
    return b
end

-- Vrai si `key` a une date de moins de 6 h ; les dates plus vieilles sont oubliées au passage.
local function recent(tbl, key)
    local t = clock()
    for k, at in pairs(tbl) do if t - at >= REPEAT_EVERY then tbl[k] = nil end end
    return tbl[key] ~= nil
end

local function enabled()
    return CraftLink ~= nil and Dir.RoomEnabled ~= nil and Dir:RoomEnabled()
end

local function myRealm() return Dir._MyRealmID and Dir:_MyRealmID() end

-- Au plus CAP présentations acceptées d'un même émetteur par fenêtre ; une trace au premier refus.
local function underCap(sender)
    local s, t = state(), now()
    local kept = {}
    for _, at in ipairs(s.cap[sender] or {}) do if t - at < CAP_WINDOW then kept[#kept + 1] = at end end
    s.cap[sender] = kept
    if #kept >= CAP then
        if not s.capTraced[sender] then trace("présentations de " .. sender .. " : plafond atteint, ignorées") end
        s.capTraced[sender] = true
        return false
    end
    kept[#kept + 1] = t
    return true
end

-- 1. L'arrivant. Un porteur d'un AUTRE royaume vient de me parler en direct : dans les 2 minutes qui
-- suivent mon chargement, je lui demande de me présenter dans sa salle. Un passeur par royaume ; sans
-- confirmation après 30 s, un second (au plus). Le verrou de 6 h ne se pose qu'à la CONFIRMATION (un
-- bonjour léger venu de ce royaume) : à l'envoi, un verrou de 10 min seulement. Sinon un passeur qui
-- ment sur son royaume, ou qui part, faisait perdre ma présentation pour 6 h (revue du 2026-10-07).
function Dir:BridgeOnRealm(sender, realm)
    local mine = myRealm()
    if not (enabled() and mine and validRealm(realm) and realm ~= mine and sender) then return end
    if now() - loadedAt > ASK_WINDOW then return end
    local s, db = state(), store()
    if not db then return end
    local a = s.asked[realm]
    if a and (a.confirmed or a.tries >= 2 or a.by == sender or now() - a.at < RETRY_AFTER) then return end
    if not a and recent(db.selfIntro, realm) then s.asked[realm] = { confirmed = true }; return end
    local name = me()
    if not fullName(name) then return end
    s.asked[realm] = { at = now(), by = sender, tries = (a and a.tries or 0) + 1 }
    db.selfIntro[realm] = clock() - (REPEAT_EVERY - SHORT_LOCK)   -- « récent » pendant 10 min seulement
    CraftLink:Send(("INT|%s|%d"):format(name, mine), "whisper", sender)
    trace(("présentation demandée à %s (royaume %d)"):format(sender, realm))
end

-- Un bonjour léger venu d'un royaume où j'ai demandé à être présenté : la présentation a eu lieu.
local function confirm(realm)
    local a = validRealm(realm) and state().asked[realm]
    if not a or a.confirmed then return end
    a.confirmed = true
    local db = store()
    if db then db.selfIntro[realm] = clock() end                -- maintenant, 6 h
end

-- 2. Le passeur. « Présente-moi » reçu, de l'arrivant lui-même (palier 2) ou du passeur élu de sa salle
-- (palier 3) : un pair que je connais en direct, et dont le royaume est celui du présenté. Je le poste
-- dans ma salle après un court délai, sauf s'il y a été vu entre-temps ou depuis moins de 10 min, ou si
-- je l'ai posté moi-même depuis moins de 6 h.
function Dir:_BridgeRequest(sender, name, realm)
    local mine = myRealm()
    if not mine or realm == mine then return end
    if sender ~= name then
        local r = self.roster and self.roster[sender]
        if not (r and r.lastSeen and r.realm == realm) then return end
    end
    if not (CraftLink.RoomJoined and CraftLink:RoomJoined()) then return end
    local db = store()
    if not db or recent(db.posted, name) then return end
    after(math.random() * POST_JITTER, function()
        local seenAt = state().seen[name]
        if seenAt and now() - seenAt < SEEN_FOR then
            trace(("présentation de %s déjà vue dans la salle : pas reposée"):format(name))
            return
        end
        if not CraftLink:RoomJoined() then return end
        db.posted[name], state().seen[name] = clock(), now()
        CraftLink:Send(("INT|%s|%d"):format(name, realm), "room")
        trace(("présentation de %s (royaume %d) postée dans la salle"):format(name, realm))
    end)
end

-- Au plus HL_PER_MIN bonjours légers spontanés par minute, tous noms confondus.
local function burstAllowed()
    local s, t = state(), now()
    local kept = {}
    for _, at in ipairs(s.burst) do if t - at < 60 then kept[#kept + 1] = at end end
    s.burst = kept
    if #kept >= HL_PER_MIN then return false end
    kept[#kept + 1] = t
    return true
end

-- 3. Les membres de la salle. Une présentation postée : je la note (pour ne pas la reposter) et, si je
-- ne connais pas l'arrivant, je lui dis un bonjour léger, après un délai aléatoire (toute la salle ne
-- part pas dans la même seconde). Une seule fois par nom et par 10 min, quel que soit le nombre de
-- présentations : sinon un menteur qui reposte la même « victime » faisait chuchoter toute la salle
-- vers elle à chaque fois (revue du 2026-10-07). Une salle ne présente que des étrangers.
function Dir:_BridgeSeen(sender, name, realm)
    local s, t = state(), now()
    local seenAt = s.seen[name]
    s.seen[name] = t
    if seenAt and t - seenAt < SEEN_FOR then return end
    if realm == myRealm() then return end
    local hl = s.hl[name]
    if hl and t - hl < HL_FOR then return end
    local r = self.roster and self.roster[name]
    if r and r.lastSeen then return end
    if not burstAllowed() then return end
    after(math.random() * HELLO_JITTER, function()
        local rr = Dir.roster and Dir.roster[name]
        if rr and rr.lastSeen then return end            -- il m'a parlé entre-temps
        Dir:_SendLightHello(name)
        trace(("bonjour léger → %s (présenté par %s)"):format(name, sender))
    end)
end

function Dir:OnIntro(sender, message, distribution)
    local name, realm = (message or ""):match("^INT|([^|]+)|(%d+)$")
    realm = tonumber(realm)
    if not (name and validRealm(realm) and sender and enabled()) or name == me() or not fullName(name) then return end
    if distribution ~= "WHISPER" and distribution ~= "CHANNEL" then return end   -- ni groupe, ni guilde
    if not underCap(sender) then return end
    if distribution == "WHISPER" then return self:_BridgeRequest(sender, name, realm) end
    self:_BridgeSeen(sender, name, realm)                -- posté dans ma salle : jamais un second saut
end

-- Le bonjour léger : ma fiche de métiers seule (le royaume dedans), ou mon royaume seul sans métier.
function Dir:_LightHelloPayload()
    local sk = self._SkillPayload and self:_SkillPayload()
    if sk then return "HL|" .. sk end
    local rm = myRealm()
    return rm and ("HL|rm=" .. rm) or "HL"
end

function Dir:_SendLightHello(name)
    state().hl[name] = now()
    CraftLink:Send(self:_LightHelloPayload(), "whisper", name)
end

-- Bonjour léger reçu : sa fiche entre dans l'annuaire, et il passe en ligne chez moi. Au plus un bonjour
-- léger en retour : si je lui en ai envoyé un depuis moins de 10 min, le sien est la réponse. Jamais
-- l'annonce complète, ni les fiches de mes partenaires, ni une découverte.
function Dir:OnLightHello(sender, message)
    if not (sender and enabled()) or sender == me() then return end
    local body = message and message:match("^HL|(.+)$")
    confirm(tonumber(body and body:match("rm=(%d+)")))         -- avant OnSkill : pas d'essai de 2e passeur
    local r = self:_Touch(sender)
    if body and body:find("^SK") then
        self:OnSkill(sender, body)
    else
        local rm = body and body:match("^rm=(%d+)$")
        if rm and r and self._NoteRealm then self:_NoteRealm(sender, tonumber(rm)) end
    end
    local sent = state().hl[sender]
    if sent and now() - sent < HL_FOR then return end
    self:_SendLightHello(sender)
    trace(("bonjour léger de %s : un bonjour léger en retour"):format(sender))
end

-- 4. Le passeur élu (palier 3). Un porteur à jour arrive dans MA salle : s'il ne connaît personne
-- ailleurs, personne ne le présente. Le plus petit nom de la salle le fait pour lui. Les candidats :
-- moi, et les porteurs de mon royaume que je vois en ligne (leur royaume connu = ils sont à jour). Deux
-- membres qui ne voient pas les mêmes présents peuvent se croire élus tous les deux, et l'arrivant a pu
-- se présenter lui-même : la salle d'en face absorbe le doublon (déjà vue, 10 min).
local PRESENT_MAX_REALMS = 5

local function iAmElected(arrivant, mine)
    local best = me()
    for n, r in pairs(Dir.roster or {}) do
        if n ~= arrivant and r.realm == mine and Dir.online[n] and n < best then best = n end
    end
    return best == me()
end

-- Un passeur en ligne par royaume étranger : un ami ou un membre de ma guilde d'abord, sinon le plus
-- récemment vu.
local function passeursByRealm(mine)
    local best = {}
    for n, r in pairs(Dir.roster or {}) do
        local x = r.realm
        if validRealm(x) and x ~= mine and Dir.online[n] and r.lastSeen then
            local score = ((r.isFriend or r.isGuild) and 1e12 or 0) + r.lastSeen
            if not best[x] or score > best[x].score then best[x] = { name = n, score = score } end
        end
    end
    return best
end

-- Bonjour d'arrivée lu dans ma salle (royaume = le mien). Une fois par arrivant et par 6 h ; jamais
-- pour moi-même ; au plus 5 royaumes étrangers.
function Dir:BridgeOnRoomHello(sender, realm)
    local mine = myRealm()
    if not (enabled() and mine and realm == mine and sender) or sender == me() or not fullName(sender) then return end
    local db = store()
    if not db or recent(db.vouched, sender) then return end
    after(math.random() * POST_JITTER, function()
        if not iAmElected(sender, mine) or recent(db.vouched, sender) then return end
        local n = 0
        for x, p in pairs(passeursByRealm(mine)) do
            if n >= PRESENT_MAX_REALMS then break end
            n = n + 1
            CraftLink:Send(("INT|%s|%d"):format(sender, mine), "whisper", p.name)
            trace(("présentation de %s demandée à %s (royaume %d) : passeur élu"):format(sender, p.name, x))
        end
        if n > 0 then db.vouched[sender] = clock() end
    end)
end

function Dir:StartBridge()
    if not (CraftLink and CraftLink.RegisterHandler) then return end
    CraftLink:RegisterHandler("INT", function(s, m, d) Dir:OnIntro(s, m, d) end)
    CraftLink:RegisterHandler("HL",  function(s, m)    Dir:OnLightHello(s, m) end)
end
