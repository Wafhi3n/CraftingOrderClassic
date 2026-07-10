-- Directory_LFW.lua — statut « recherche de travail » (Looking For Work).
--
-- Un artisan se déclare dispo pour UN métier → diffusé au ROYAUME via le canal-texte (verbe LFW, réutilise
-- l'infra canal v1.11.0, cf. balise/texte canal CraftLink). Les autres stockent { prof, expiry } EN RUNTIME
-- (statut transitoire, non persisté) et l'affichent (nameplate + annuaire, couches à part). SÛR par
-- construction : le stockage est clé par SENDER (émetteur réel, non falsifiable par le transport) → on ne
-- peut déclarer QUE soi-même LFW. MON propre choix (COC.db.lfw.prof) PERSISTE et se ré-affirme au login +
-- périodiquement (le récepteur applique un TTL, donc sans ré-émission je disparais de son radar).

local COC = CraftingOrderClassic
local Dir = COC.Directory
local L   = COC.L

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end
local function me() return (UnitName and UnitName("player")) or "?" end
local function pmsg(m) print("|cFF33DD88Crafting Order|r " .. m) end
local function profLabel(key)
    local Skin = COC.UI and COC.UI.Skin
    return (Skin and Skin.ProfLabel and Skin.ProfLabel(key)) or key
end

local LFW_TTL     = 45 * 60    -- durée de vie côté récepteur (s) : au-delà, l'artisan n'est plus « LFW »
local LFW_REFRESH = 20 * 60    -- ré-émission périodique tant que LFW (< TTL, marge de sécurité)

Dir.lfw = Dir.lfw or {}         -- RUNTIME : [nom court] = { prof = <clé>, expiry = <time> } (AUTRES joueurs)

-- Statut LFW vivant d'un joueur (nil si absent/expiré). Purge paresseuse de l'entrée expirée.
function Dir:LFWOf(name)
    local e = name and self.lfw and self.lfw[name]
    if not e then return nil end
    if e.expiry and time() >= e.expiry then self.lfw[name] = nil; return nil end
    return e
end

-- Réception LFW|on|<profKey> / LFW|off. `sender` = émetteur réel (clé, non falsifiable). Portée royaume.
function Dir:OnLFW(sender, message)
    if not sender or sender == me() then return end
    local sub, prof = message:match("^LFW|(%a+)|?(.*)$")
    if sub == "off" then
        if self.lfw then self.lfw[sender] = nil end
    elseif sub == "on" and prof ~= "" then
        self.lfw = self.lfw or {}
        self.lfw[sender] = { prof = prof, expiry = time() + LFW_TTL }
    else
        return
    end
    if COC.Nameplate and COC.Nameplate.Refresh then COC.Nameplate:Refresh(sender) end
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
end

-- Diffuse MON statut au royaume (canal-texte). Le clic/slash fournit le hardware event ; sinon la file
-- CraftLink draine au prochain input (TRANSPORT_REV 8). Verbe de DONNÉES → pas de balise requise.
function Dir:_BroadcastLFW()
    local c = CL(); if not (c and c.BroadcastText) then return end
    local db = COC.db and COC.db.lfw
    if db and db.prof then c:BroadcastText("LFW|on|" .. db.prof) else c:BroadcastText("LFW|off") end
end

-- Ma clé de métier LFW (ou nil).
function Dir:MyLFW() return COC.db and COC.db.lfw and COC.db.lfw.prof or nil end

-- Active (profKey) / désactive (nil) mon statut. Persiste + diffuse au royaume + (re)lance le ticker.
function Dir:SetLFW(profKey)
    COC.db = COC.db or {}
    COC.db.lfw = profKey and { prof = profKey } or nil
    self:_BroadcastLFW()
    self:_StartLFWTicker()
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
end

-- Ré-émission périodique tant que je suis LFW (sinon je sors du radar des autres au bout du TTL). Ticker
-- unique, qui s'auto-annule dès que je ne suis plus LFW. L'envoi passe par la file (drainée au prochain input).
function Dir:_StartLFWTicker()
    if not (C_Timer and C_Timer.NewTicker) or self._lfwTicker then return end
    self._lfwTicker = C_Timer.NewTicker(LFW_REFRESH, function()
        if not (COC.db and COC.db.lfw and COC.db.lfw.prof) then
            if Dir._lfwTicker then Dir._lfwTicker:Cancel(); Dir._lfwTicker = nil end
            return
        end
        Dir:_BroadcastLFW()
    end)
end

-- /co lfw [métier|off] : me déclarer dispo pour du travail dans un métier (ou couper). Sans argument :
-- affiche l'état. Le métier doit être un des MIENS (sinon annoncer un métier qu'on ne fait pas n'a pas de sens).
function Dir:LFWCmd(arg)
    arg = (arg or ""):match("^%s*(.-)%s*$")
    if arg == "" then
        local cur = self:MyLFW()
        if cur then pmsg(string.format(L["recherche de travail : |cFF33DD33%s|r — /co lfw off pour arrêter"], profLabel(cur)))
        else pmsg(L["recherche de travail : |cFFFFCC00désactivée|r — /co lfw <métier>"]) end
        return
    end
    if arg:lower() == "off" then self:SetLFW(nil); pmsg(L["recherche de travail arrêtée."]); return end
    local c = CL()
    local key = c and c.ResolveProfession and c:ResolveProfession(arg)
    if not key then pmsg(L["métier inconnu : "] .. arg); return end
    if not (self.mySkills and self.mySkills[key]) then
        pmsg(string.format(L["tu n'as pas le métier %s — impossible de chercher du travail dessus."], profLabel(key))); return
    end
    self:SetLFW(key)
    pmsg(string.format(L["recherche de travail : |cFF33DD33%s|r — visible au royaume"], profLabel(key)))
end

-- Câblage : handler du verbe LFW + ré-affirmation à chaque (re)acquisition du canal. Appelé par Dir:Start.
function Dir:StartLFW()
    local c = CL(); if not c then return end
    c:RegisterHandler("LFW", function(s, m) Dir:OnLFW(s, m) end)
    if c.OnNetworkReady then
        c:OnNetworkReady(function()
            if COC.db and COC.db.lfw and COC.db.lfw.prof then Dir:_BroadcastLFW(); Dir:_StartLFWTicker() end
        end)
    end
end
