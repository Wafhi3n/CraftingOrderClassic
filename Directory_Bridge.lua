-- Directory_Bridge.lua — pont entre royaumes, palier 2 (spec docs/specs/pont-royaumes.md).
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
-- Palier 2 : une demande n'est acceptée que de l'arrivant LUI-MÊME (l'émetteur EST le présenté) ; le
-- passeur élu pour un arrivant qui ne connaît personne ailleurs viendra au palier 3. Budget (D7) :
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
    if not s then s = { asked = {}, seen = {}, cap = {}, capTraced = {}, hl = {} }; Dir._bridge = s end
    return s
end

local function store()
    if not COC.db then return nil end
    COC.db.bridge = COC.db.bridge or {}
    local b = COC.db.bridge
    b.selfIntro, b.posted = b.selfIntro or {}, b.posted or {}
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
-- suivent mon chargement, je lui demande de me présenter dans sa salle. Un seul par royaume et par
-- session, et pas plus d'une fois toutes les 6 heures par royaume, reconnexions comprises.
function Dir:BridgeOnRealm(sender, realm)
    local mine = myRealm()
    if not (enabled() and mine and realm and realm ~= mine and sender) then return end
    if now() - loadedAt > ASK_WINDOW then return end
    local s, db = state(), store()
    if s.asked[realm] or not db then return end
    s.asked[realm] = true
    if recent(db.selfIntro, realm) then return end
    local name = me()
    if not fullName(name) then return end
    db.selfIntro[realm] = clock()
    CraftLink:Send(("INT|%s|%d"):format(name, mine), "whisper", sender)
    trace(("présentation demandée à %s (royaume %d)"):format(sender, realm))
end

-- 2. Le passeur. « Présente-moi » reçu (palier 2 : de l'arrivant lui-même, d'un autre royaume). Je le
-- poste dans ma salle après un court délai, sauf s'il y a été vu entre-temps ou depuis moins de 10 min,
-- ou si je l'ai posté moi-même depuis moins de 6 h.
function Dir:_BridgeRequest(sender, name, realm)
    local mine = myRealm()
    if sender ~= name or not mine or realm == mine then return end
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

-- 3. Les membres de la salle. Une présentation postée : je la note (pour ne pas la reposter) et, si je
-- ne connais pas l'arrivant, je lui dis un bonjour léger, après un délai aléatoire (toute la salle ne
-- part pas dans la même seconde).
function Dir:_BridgeSeen(sender, name)
    state().seen[name] = now()
    local r = self.roster and self.roster[name]
    if r and r.lastSeen then return end
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
    if not (name and realm and sender and enabled()) or name == me() or not fullName(name) then return end
    if not underCap(sender) then return end
    if distribution == "WHISPER" then return self:_BridgeRequest(sender, name, realm) end
    self:_BridgeSeen(sender, name)                       -- posté dans ma salle : jamais un second saut
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
    local r = self:_Touch(sender)
    local body = message and message:match("^HL|(.+)$")
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

function Dir:StartBridge()
    if not (CraftLink and CraftLink.RegisterHandler) then return end
    CraftLink:RegisterHandler("INT", function(s, m, d) Dir:OnIntro(s, m, d) end)
    CraftLink:RegisterHandler("HL",  function(s, m)    Dir:OnLightHello(s, m) end)
end
