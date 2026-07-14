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

local LFW_TTL     = 20 * 60    -- durée de vie côté récepteur SANS rafraîchissement : un joueur qui cesse
                               -- d'émettre (parti, ou FULL AFK — cf. ticker) sort du radar au bout de ça.
local LFW_REFRESH =  8 * 60    -- ré-émission tant que présent ET NON AFK (< TTL) : maintient le LFW frais.

Dir.lfw = Dir.lfw or {}         -- RUNTIME : [nom court] = { prof = <clé>, expiry = <time> } (AUTRES joueurs)

-- Statut LFW vivant d'un joueur (nil si absent/expiré). Le TTL est rafraîchi par les ré-émissions du
-- joueur ; s'il PART ou passe FULL AFK, il cesse d'émettre (cf. _StartLFWTicker : pas de ré-émission en
-- AFK, et un AFK ne peut de toute façon pas parler sur le canal) → il sort du radar au bout du TTL. On ne
-- veut PAS afficher « dispo » pour un joueur absent : ça leurrerait les gens. Purge paresseuse à la lecture.
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

-- Diffuse MON statut au royaume (canal-texte). Émetteurs = OnNetworkReady (login) et le ticker : AUCUN
-- n'est sous hardware event → on ENFILE (QueueText) au lieu de tenter un envoi immédiat. Un SendChatMessage
-- hors input déclencherait ADDON_ACTION_BLOCKED (que le pcall n'attrape pas → popup d'erreur au login).
-- La file draine au prochain clic/touche. Verbe de DONNÉES → pas de balise requise.
function Dir:_BroadcastLFW()
    local c = CL(); if not (c and c.QueueText) then return end
    local db = COC.db and COC.db.lfw
    if db and db.prof then c:QueueText("LFW|on|" .. db.prof) else c:QueueText("LFW|off") end
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

-- Ré-émission périodique : (1) maintient mon LFW FRAIS chez les autres (sinon le TTL l'expire), (2) atteint
-- les joueurs qui rejoignent le canal APRÈS mon annonce. STOPPÉE si je suis FULL AFK (UnitIsAFK) → je cesse
-- d'émettre et je sors du radar au bout du TTL, au lieu de leurrer les gens avec un « dispo » d'un absent.
-- Ticker unique, auto-annulé dès que je ne suis plus LFW. Envoi via la file (drainée au 1er input — un AFK
-- ne draine pas, cohérent : il n'émet plus).
function Dir:_StartLFWTicker()
    if not (C_Timer and C_Timer.NewTicker) or self._lfwTicker then return end
    self._lfwTicker = C_Timer.NewTicker(LFW_REFRESH, function()
        if not (COC.db and COC.db.lfw and COC.db.lfw.prof) then
            if Dir._lfwTicker then Dir._lfwTicker:Cancel(); Dir._lfwTicker = nil end
            return
        end
        if UnitIsAFK and UnitIsAFK("player") then return end   -- full AFK → on cesse d'émettre (anti-leurre)
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
