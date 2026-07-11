-- Directory_Alts.lua — regroupement des rerolls : identité « joueur » multi-persos (verbe ALT).
--
-- OPT-IN (/co alts on, désactivé par défaut) : le joueur choisit un perso PRINCIPAL et annonce la
-- liste de ses persos au réseau (dans le sillage de Announce/AnnounceTo — aucun nouveau déclencheur).
-- Réception → roster[sender].altClaim (1 déclaration par perso, sous le SENDER transport, donc
-- infalsifiable). Un lien A↔B n'est VÉRIFIÉ que par réciprocité (AltCodec.Component) : les deux
-- annonces sortent de la même SavedVariable de compte — un imposteur ne peut pas faire mentir sa
-- victime, donc jamais de routage/fusion sur claim unilatérale. Mes PROPRES persos (IsMyChar) se
-- lisent localement dans MA SV : aucune confiance réseau côté réception.
-- Codec pur dans Directory_AltCodec.lua ; méthodes sur COC.Directory (chargé avant, .toc).

local COC = CraftingOrderClassic
local Dir = COC.Directory
local Codec = COC.AltCodec
local L = COC.L

local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)

local function p(msg) print("|cFF33DD88Crafting Order|r " .. msg) end
local function now() return (GetTime and GetTime()) or 0 end     -- uptime : rate-cap
local function me() return (UnitName and UnitName("player")) or "?" end
local function myRealm() return (GetRealmName and GetRealmName()) or "" end

local ALT_KEEP              = 30 * 86400   -- claim jamais rafraîchie depuis 30 j → périmée
local RATE_WINDOW, RATE_MAX = 300, 10      -- réception : 10 msgs ALT max / 5 min / émetteur

-- ------------------------------------------------------------------
-- Mes persos (100 % local — la SV est par COMPTE)
-- ------------------------------------------------------------------
-- Trace du passage de CHAQUE perso du compte (clé « Nom-Royaume », format _MyKnownStore).
-- Stampé à chaque login, même sans opt-in : nourrit IsMyChar (visibilité/alertes locales).
-- On estampille AUSSI la FACTION du perso : un reroll d'en face n'est PAS un artisan exploitable
-- (le courrier et l'échange sont bloqués entre factions en Classic/TBC/WotLK), et le mélanger aux
-- autres dans « Mes artisans » donnerait une liste de plans qu'on ne peut pas se faire livrer.
-- Les persos vus AVANT cette version n'ont pas de faction : ils restent visibles jusqu'à leur
-- prochain login, où ils se rangent tout seuls (pas de purge, pas de perte de données).
function COC:StampMyChar()
    if not self.db then return end
    local key = me() .. "-" .. myRealm()
    self.db.myChars = self.db.myChars or {}
    self.db.myChars[key] = time()
    self.db.myCharFaction = self.db.myCharFaction or {}
    local f = UnitFactionGroup and UnitFactionGroup("player")
    if f == "Horde" or f == "Alliance" then self.db.myCharFaction[key] = f end
end

-- Ce nom court est-il un perso de MON compte (même royaume) ? Lit myChars + les partitions
-- existantes (persos passés avant cette version) — décision locale, jamais pilotable du réseau.
function COC:IsMyChar(short)
    if type(short) ~= "string" or short == "" or not self.db then return false end
    if short == me() then return true end
    local key = short .. "-" .. myRealm()
    local hit = (self.db.myChars and self.db.myChars[key])
        or (self.db.knownRecipes and self.db.knownRecipes[key])
        or (self.db.myCooldowns and self.db.myCooldowns[key])
    return not not hit   -- booléen strict (les partitions stockent des tables/timestamps)
end

-- Liste ANNONÇABLE de mes persos, en ordre de priorité (main, moi, puis stampés du royaume par
-- fraîcheur) — seul db.myChars fait foi : un perso doit se logger une fois pour être annoncé,
-- ce qui garantit qu'il pourra aussi produire SA moitié de la réciprocité.
function Dir:_MyAltNames()
    local db = COC.db
    if not db then return {} end
    local rl, cands = myRealm(), {}
    for key, ts in pairs(db.myChars or {}) do
        local short, realm = key:match("^([^%-]+)%-(.*)$")
        if short and realm == rl then cands[#cands + 1] = { n = short, t = tonumber(ts) or 0 } end
    end
    table.sort(cands, function(a, b) return a.t > b.t end)
    local names, seen = {}, {}
    local function add(n) if n and not seen[n] then seen[n] = true; names[#names + 1] = n end end
    add(db.altMain); add(me())
    for i = 1, #cands do add(cands[i].n) end
    return names
end

-- ------------------------------------------------------------------
-- Émission (dans le sillage de Announce/AnnounceTo — aucun nouveau déclencheur réseau)
-- ------------------------------------------------------------------
-- No-op sans opt-in (zéro octet ALT sur le fil) ou avec moins de 2 persos (rien à déclarer).
function Dir:AnnounceAlts(scope, target)
    if not (CraftLink and Codec and COC.db and COC.db.altsEnabled) then return end
    local names = self:_MyAltNames()
    if #names < 2 then return end
    local msg = Codec.Encode(COC.db.altMain or me(), names)
    if msg then CraftLink:Send(msg, scope or "global", target) end
end

-- ------------------------------------------------------------------
-- Réception
-- ------------------------------------------------------------------
-- Fenêtre glissante par émetteur (patron Dir:_RelayRateOk) : ALT est rare, 10/5 min suffit large.
function Dir:_AltRateOk(sender)
    local t = now()
    self._altRate = self._altRate or {}
    local e = self._altRate[sender]
    if not e or t - e.t0 > RATE_WINDOW then e = { t0 = t, n = 0 }; self._altRate[sender] = e end
    e.n = e.n + 1
    return e.n <= RATE_MAX
end

-- ALT reçu → déclaration stockée SOUS LE SENDER uniquement (les noms cités ne créent JAMAIS
-- d'entrée roster : pas de pollution). Gardes : rate-cap, sender ∈ set (il se déclare lui-même),
-- pas moi. Dissolution → claim effacée. Puis présence passive standard (patron OnCD).
function Dir:OnAlt(sender, message)
    if not (sender and Codec) or sender == me() then return end
    if not self:_AltRateOk(sender) then return end
    local f = Codec.Decode(message)
    if not f then return end
    if not f.dissolve and not f.set[sender] then return end   -- il doit se déclarer lui-même (AVANT toute écriture)
    self.roster = self.roster or {}
    local r = self.roster[sender]
    if not r then
        if f.dissolve then return end                          -- dissolution d'un inconnu : rien à créer
        r = {}; self.roster[sender] = r
    end
    if f.dissolve then
        r.altClaim = nil
    else
        r.altClaim = { main = f.main, list = f.list, ts = time() }
    end
    self:_ApplySource(sender, r)
    r.lastSeen = time()
    self.online[sender] = true          -- présence passive : un message prouve la présence
    self:_NoteLinked(sender, r)
    self:_BumpAltRev()
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
end

-- ------------------------------------------------------------------
-- Vérification (réciprocité) + requêtes — mémoïsé par révision (invalidé sur OnAlt/prune/wipe)
-- ------------------------------------------------------------------
function Dir:_BumpAltRev()
    self._altRev = (self._altRev or 0) + 1
end

function Dir:_AltState()
    local rev, memo = self._altRev or 0, self._altMemo
    if not memo or memo.rev ~= rev or memo.roster ~= self.roster then   -- roster ≠ : /co wipe, restart
        local claims = {}
        for name, r in pairs(self.roster or {}) do
            if r.altClaim then claims[name] = r.altClaim end
        end
        memo = { rev = rev, roster = self.roster, claims = claims, comp = {} }
        self._altMemo = memo
    end
    return memo
end

-- Composante VÉRIFIÉE de `name` → (set, array ordre de découverte). Singleton si aucun lien mutuel.
function Dir:PlayerChars(name)
    if not name then return nil end
    local st = self:_AltState()
    local c = st.comp[name]
    if not c then
        local set, order = Codec.Component(st.claims, name)
        c = { set = set, order = order }
        st.comp[name] = c
    end
    return c.set, c.order
end

-- Même joueur ? (liens MUTUELS uniquement — une claim unilatérale ne lie jamais.)
function Dir:SamePlayer(a, b)
    if not (a and b) then return false end
    if a == b then return true end
    local set = self:PlayerChars(a)
    return (set and set[b]) == true
end

-- Premier perso EN LIGNE du set vérifié de `name` (name lui-même inclus), ou nil.
function Dir:OnlineCharOf(name)
    local _, order = self:PlayerChars(name)
    if not order then return nil end
    for i = 1, #order do
        if self.online and self.online[order[i]] then return order[i] end
    end
    return nil
end

-- Vitrine du groupe : le main déclaré par la claim la plus récente qui en désigne un DANS la
-- composante ; repli = plus petit nom. Singleton → le perso lui-même.
function Dir:GroupLeader(name)
    local set, order = self:PlayerChars(name)
    if not order or #order <= 1 then return name end
    local st, best, bestTs = self:_AltState(), nil, nil
    for i = 1, #order do
        local c = st.claims[order[i]]
        if c and c.main and set[c.main] and (not bestTs or (c.ts or 0) > bestTs) then
            best, bestTs = c.main, c.ts or 0
        end
    end
    if best then return best end
    local min = order[1]
    for i = 2, #order do if order[i] < min then min = order[i] end end
    return min
end

-- ------------------------------------------------------------------
-- Entretien + commande + câblage
-- ------------------------------------------------------------------
-- Claims jamais rafraîchies depuis 30 j → périmées (appelé par PruneRoster au démarrage).
function Dir:PruneAlts()
    local cutoff = time() - ALT_KEEP
    for _, r in pairs(self.roster or {}) do
        if r.altClaim and (r.altClaim.ts or 0) < cutoff then r.altClaim = nil end
    end
    self:_BumpAltRev()   -- inconditionnel : PruneRoster a pu supprimer des entrées porteuses de claim
end

-- Retrouve un de MES persos par nom (insensible à la casse ASCII, royaume ignoré) — pour /co alts main.
function Dir:_FindMyChar(arg)
    local want = (arg or ""):match("^([^%-]+)") or ""
    want = want:lower()
    if want == "" then return nil end
    for _, n in ipairs(self:_MyAltNames()) do if n:lower() == want then return n end end
    local rl = myRealm()
    for key in pairs((COC.db and COC.db.knownRecipes) or {}) do
        local short, realm = key:match("^([^%-]+)%-(.*)$")
        if short and realm == rl and short:lower() == want then return short end
    end
    return nil
end

function Dir:_AltsStatus()
    local db = COC.db
    p(db.altsEnabled and L["rerolls : ACTIVÉS — ta liste de persos est annoncée au réseau."]
                      or L["rerolls : désactivés — rien n'est annoncé (opt-in : /co alts on)."])
    if db.altMain then p(string.format(L["perso principal (vitrine) : %s"], db.altMain)) end
    local names = self:_MyAltNames()
    if #names > 0 then p(string.format(L["persos du compte (%s) : %s"], myRealm(), table.concat(names, ", "))) end
    p(L["le lien n'est vérifié chez les autres qu'après une connexion de CHAQUE perso (addon actif)."])
end

-- /co alts [on|off|main <nom>] — dispatché depuis COC:Slash.
function Dir:AltsCmd(rest)
    local db = COC.db
    if not db then return end
    local sub, arg = (rest or ""):match("^(%S*)%s*(.-)%s*$")
    sub = (sub or ""):lower()
    if sub == "on" then
        db.altsEnabled = true
        if not db.altMain then db.altMain = me() end
        p(string.format(L["rerolls activés — perso principal : %s (changer : /co alts main <nom>)"], db.altMain))
        self:AnnounceThrottled()
    elseif sub == "off" then
        db.altsEnabled = nil
        if CraftLink and Codec then CraftLink:Send(Codec.Encode(nil), "global") end   -- dissolution one-shot
        p(L["rerolls désactivés — dissolution annoncée au réseau."])
    elseif sub == "main" then
        local found = self:_FindMyChar(arg)
        if not found then
            p(string.format(L["perso inconnu sur ce compte : %s (connecte-le une fois avec l'addon)"], arg or "?"))
            return
        end
        db.altMain = found
        p(string.format(L["perso principal (vitrine) : %s"], found))
        if db.altsEnabled then self:AnnounceThrottled() end
    else
        self:_AltsStatus()
    end
end

-- Câblage réseau — appelé par Dir:Start (Directory.lua) après StartRelay.
function Dir:StartAlts()
    COC:StampMyChar()
    if not (CraftLink and Codec) then return end
    CraftLink:RegisterHandler("ALT", function(s, m) Dir:OnAlt(s, m) end)
end
