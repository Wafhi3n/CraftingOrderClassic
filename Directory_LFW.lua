-- Directory_LFW.lua — statut « recherche de travail » (Looking For Work) + OFFRE par métier.
--
-- Un artisan se déclare dispo pour UN métier → diffusé au ROYAUME via le canal-texte (verbe LFW, réutilise
-- l'infra canal v1.11.0, cf. balise/texte canal CraftLink). Les autres stockent { prof, expiry } EN RUNTIME
-- (statut transitoire, non persisté) et l'affichent (nameplate + annuaire, couches à part). SÛR par
-- construction : le stockage est clé par SENDER (émetteur réel, non falsifiable par le transport) → on ne
-- peut déclarer QUE soi-même LFW. MON propre choix (COC.db.lfw.prof) PERSISTE et se ré-affirme au login +
-- périodiquement (le récepteur applique un TTL, donc sans ré-émission je disparais de son radar).
--
-- OFFRE (v1.18) : détails par MÉTIER attachés au LFW — « je fournis les compos de base », liste de
-- composants fournis, commission fixe par craft, restriction « seulement si le plan me fait progresser ».
-- Config persistée dans COC.db.lfwOffer[profKey] (éditable même LFW éteint), diffusée par un verbe SÉPARÉ
-- `LFO|<prof>|<flags>|<feeCopper>|<id1,id2,…>` : étendre LFW|on casserait les vieux clients (leur pattern
-- avalerait les champs dans la clé métier), alors qu'un verbe inconnu est ignoré proprement par _Dispatch.
-- Wire 100 % neutre en langue (IDs, cuivre, lettres). Un LFO seul VAUT LFW-on (robuste à la perte d'une
-- ligne) ; l'offre reçue vit sur l'entrée Dir.lfw[sender].offer et meurt avec elle (même TTL).

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

local OFFER_MAX_ITEMS   = 15       -- cap composants fournis : ligne LFO ≈ 135 chars, sous la limite canal
local OFFER_MAX_RECIPES = 12       -- cap recettes proposées : ligne LFR ≈ 100 chars ; la plaque n'en montre qu'1 (+N)
local OFFER_MAX_FEE   = 9999999    -- cap commission (cuivre) : 999g 99s 99c, borne encode ET décode
local OFFER_DEBOUNCE  = 5          -- s : regroupe les changements de config avant re-diffusion
Dir.OFFER_MAX_ITEMS   = OFFER_MAX_ITEMS     -- exposé : le panneau de config (ProfWindow_LFW) montre « n/15 »
Dir.OFFER_MAX_RECIPES = OFFER_MAX_RECIPES   -- exposé : la colonne de cases (ProfWindow_Recipes) borne la sélection

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

-- Réception LFO|<prof>|<flags>|<fee>|<ids> : l'OFFRE attachée au LFW d'un joueur. Validation stricte
-- (flags whitelist B/S, fee et items CAPPÉS côté décodage : un émetteur trafiqué ne gonfle ni le fee ni
-- la liste). Crée OU rafraîchit l'entrée LFW : les deux lignes partent en file FIFO mais une perte est
-- possible — un LFO seul vaut donc LFW-on. Clé par SENDER, même sûreté que LFW.
function Dir:OnLFO(sender, message)
    if not sender or sender == me() then return end
    -- ⚠️ profKey = lettres ET espaces : « First Aid » est une clé canonique valide — un `%a+` seul
    -- casserait silencieusement toute offre Secourisme (bug attrapé en revue avant release).
    local prof, flags, fee, items = message:match("^LFO|([%a ]+)|([%-A-Z]*)|(%d+)|?([%d,]*)$")
    if not prof or prof == "" then return end
    fee = math.min(tonumber(fee) or 0, OFFER_MAX_FEE)
    local o = {}
    if flags:find("B", 1, true) then o.basics = true end
    if flags:find("S", 1, true) then o.skillUpOnly = true end
    if fee > 0 then o.fee = fee end
    for id in (items or ""):gmatch("%d+") do
        local n = tonumber(id)
        if n and n > 0 then
            o.items = o.items or {}
            if #o.items < OFFER_MAX_ITEMS then o.items[#o.items + 1] = n end
        end
    end
    self.lfw = self.lfw or {}
    local e = self.lfw[sender]
    if not (e and e.prof == prof) then e = { prof = prof }; self.lfw[sender] = e end
    e.expiry = time() + LFW_TTL
    e.offer = (o.basics or o.skillUpOnly or o.fee or o.items) and o or nil
    if COC.Nameplate and COC.Nameplate.Refresh then COC.Nameplate:Refresh(sender) end
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
end

-- Réception LFR|<prof>|<spellID,…> : les RECETTES précises que l'artisan propose (verbe séparé de LFO, même
-- raison — étendre LFO casserait le pattern ancré des vieux clients ; un verbe inconnu est ignoré proprement).
-- Identifiant = spellID de la RECETTE (résolu en NOM par GetSpellInfo chez tout récepteur, même non-apprise).
-- Stocké sur e.recipes (frère de e.offer) → LFO et LFR ont des champs DISJOINTS sur l'entrée : ni l'ordre
-- d'arrivée ni la perte d'une des deux lignes ne s'écrasent l'un l'autre. Clé par SENDER (sûr). Cap au décodage.
function Dir:OnLFR(sender, message)
    if not sender or sender == me() then return end
    local prof, ids = message:match("^LFR|([%a ]+)|?([%d,]*)$")
    if not prof or prof == "" then return end
    local list = {}
    for id in (ids or ""):gmatch("%d+") do
        local n = tonumber(id)
        if n and n > 0 and #list < OFFER_MAX_RECIPES then list[#list + 1] = n end
    end
    self.lfw = self.lfw or {}
    local e = self.lfw[sender]
    if not (e and e.prof == prof) then e = { prof = prof }; self.lfw[sender] = e end
    e.expiry  = time() + LFW_TTL           -- un LFR seul vaut LFW-on (robuste à la perte du LFW|on)
    e.recipes = (#list > 0) and list or nil
    if COC.Nameplate and COC.Nameplate.Refresh then COC.Nameplate:Refresh(sender) end
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
end

-- Prospect LFW vu dans le CHAT (joueur SANS l'addon, cf. LFWChat). Display-only : entrée annuaire (source
-- classée guilde/ami sinon « recent » ; craftSeen = métier connu SANS niveau → « vu (sans l'addon) ») +
-- statut LFW (badge [Dispo] + nameplate, même TTL), marqué viaChat. NE marque PAS online (non-porteur) et ne
-- pousse aucune commande (le protocole lui est indisponible). Un vrai LFW addon (OnLFW) écrase ensuite proprement.
function Dir:NoteChatLFW(name, prof)
    if not (name and prof) or name == me() then return end
    self.roster = self.roster or {}
    local r = self.roster[name]; if not r then r = {}; self.roster[name] = r end
    if self._ApplySource then self:_ApplySource(name, r) end
    r.faction = self._MyFaction and self:_MyFaction() or r.faction
    r.lastSeen = time(); r.viaChat = true
    r.craftSeen = r.craftSeen or {}
    if r.craftSeen[prof] == nil then r.craftSeen[prof] = 0 end   -- 0 = connu sans l'addon, niveau inconnu
    self.lfw = self.lfw or {}
    local e = self.lfw[name]
    if not (e and e.prof == prof) then e = { prof = prof }; self.lfw[name] = e end
    e.expiry = time() + LFW_TTL; e.viaChat = true
    if COC.Nameplate and COC.Nameplate.Refresh then COC.Nameplate:Refresh(name) end
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
end

-- Encode MON offre en ligne LFO (nil si l'offre est vide → rien à diffuser). Pur, iso-fil (testé headless).
-- Caps appliqués aussi à l'ÉMISSION : la ligne reste courte quel que soit l'état de la config.
function Dir:_EncodeLFO(profKey, o)
    if not (profKey and o) then return nil end
    local flags = (o.basics and "B" or "") .. (o.skillUpOnly and "S" or "")
    local fee = math.min(tonumber(o.fee) or 0, OFFER_MAX_FEE)
    local ids = {}
    for i, id in ipairs(o.items or {}) do
        if i > OFFER_MAX_ITEMS then break end
        ids[#ids + 1] = tostring(id)
    end
    if flags == "" and fee == 0 and #ids == 0 then return nil end
    return string.format("LFO|%s|%s|%d|%s", profKey, flags == "" and "-" or flags, fee, table.concat(ids, ","))
end

-- Encode MES recettes proposées en ligne LFR (nil si aucune → rien à diffuser). Pur, iso-fil (testé headless).
-- Cap appliqué à l'ÉMISSION : la ligne reste courte quel que soit l'état de la config.
function Dir:_EncodeLFR(profKey, o)
    if not (profKey and o and o.recipes and #o.recipes > 0) then return nil end
    local ids = {}
    for i, id in ipairs(o.recipes) do
        if i > OFFER_MAX_RECIPES then break end
        ids[#ids + 1] = tostring(id)
    end
    if #ids == 0 then return nil end
    return string.format("LFR|%s|%s", profKey, table.concat(ids, ","))
end

-- Diffuse MON statut au royaume (canal-texte). Émetteurs = OnNetworkReady (login) et le ticker : AUCUN
-- n'est sous hardware event → on ENFILE (QueueText) au lieu de tenter un envoi immédiat. Un SendChatMessage
-- hors input déclencherait ADDON_ACTION_BLOCKED (que le pcall n'attrape pas → popup d'erreur au login).
-- La file draine au prochain clic/touche. Verbe de DONNÉES → pas de balise requise. L'offre du métier
-- actif part juste derrière le LFW|on (même file FIFO) ; offre vide → pas de ligne LFO.
function Dir:_BroadcastLFW()
    local c = CL(); if not (c and c.QueueText) then return end
    local db = COC.db and COC.db.lfw
    if db and db.prof then
        c:QueueText("LFW|on|" .. db.prof)
        local lfo = self:_EncodeLFO(db.prof, self:MyLFWOffer(db.prof))
        if lfo then c:QueueText(lfo) end
        local lfr = self:_EncodeLFR(db.prof, self:MyLFWOffer(db.prof))
        if lfr then c:QueueText(lfr) end
    else
        c:QueueText("LFW|off")
    end
end

-- Ma clé de métier LFW (ou nil).
function Dir:MyLFW() return COC.db and COC.db.lfw and COC.db.lfw.prof or nil end

-- MA config d'offre pour un métier (persistée, PAR métier — survit au changement de métier LFW actif).
function Dir:MyLFWOffer(profKey)
    local t = COC.db and COC.db.lfwOffer
    return (t and profKey) and t[profKey] or nil
end

-- Enregistre MA config d'offre d'un métier (nil = effacer) + re-diffusion DÉBOUNCÉE si le LFW de CE
-- métier est actif (le panneau sauve à chaque coche : sans débounce, chaque clic mettrait une ligne en
-- file). Config d'un métier NON actif : on sauve sans rien diffuser (elle partira au prochain SetLFW).
function Dir:SetLFWOffer(profKey, offer)
    if not profKey then return end
    COC.db = COC.db or {}
    COC.db.lfwOffer = COC.db.lfwOffer or {}
    COC.db.lfwOffer[profKey] = offer
    if self:MyLFW() ~= profKey then return end
    if not (C_Timer and C_Timer.NewTimer) then return end
    if self._lfoDebounce then self._lfoDebounce:Cancel() end
    self._lfoDebounce = C_Timer.NewTimer(OFFER_DEBOUNCE, function()
        Dir._lfoDebounce = nil
        if Dir:MyLFW() == profKey then Dir:_BroadcastLFW() end
    end)
end

-- Lignes d'affichage de l'offre LFW d'un joueur, prêtes pour un tooltip (monde + annuaire = source
-- unique). nil si pas d'offre vivante. Noms d'objets au runtime (multilingue) ; « +N » = neutre.
function Dir:LFWOfferLines(name)
    local e = self:LFWOf(name)
    if not e then return nil end
    local o = e.offer
    local out = {}
    if o and o.basics then out[#out + 1] = L["fournit les composants de base (marchand)"] end
    if o and o.items and #o.items > 0 then
        local c = CL()
        local names = {}
        for i = 1, math.min(3, #o.items) do
            local id = o.items[i]
            names[#names + 1] = (c and c.ItemName and c:ItemName(id)) or ("item:" .. id)
        end
        local extra = (#o.items > 3) and (" |cFF888888+" .. (#o.items - 3) .. "|r") or ""
        out[#out + 1] = string.format(L["fournit : %s"], table.concat(names, ", ") .. extra)
    end
    if o and o.fee and o.fee > 0 then
        local money = (GetCoinTextureString and GetCoinTextureString(o.fee)) or tostring(o.fee)
        out[#out + 1] = string.format(L["commission : %s par craft"], money)
    end
    if o and o.skillUpOnly then out[#out + 1] = L["composants fournis seulement si le plan fait progresser"] end
    -- Recettes proposées (verbe LFR, entrée e.recipes) : noms résolus au runtime par GetSpellInfo (via CraftLink).
    if e.recipes and #e.recipes > 0 then
        local c = CL()
        local names = {}
        for i = 1, math.min(3, #e.recipes) do
            local sid = e.recipes[i]
            names[#names + 1] = (c and c.RecipeName and c:RecipeName(sid)) or ("spell:" .. sid)
        end
        local extra = (#e.recipes > 3) and (" |cFF888888+" .. (#e.recipes - 3) .. "|r") or ""
        out[#out + 1] = string.format(L["propose : %s"], table.concat(names, ", ") .. extra)
    end
    return (#out > 0) and out or nil
end

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

-- Câblage : handlers des verbes LFW + LFO + ré-affirmation à chaque (re)acquisition du canal. Appelé
-- par Dir:Start. (Vieux clients : LFO = verbe inconnu, ignoré proprement par _Dispatch.)
function Dir:StartLFW()
    local c = CL(); if not c then return end
    c:RegisterHandler("LFW", function(s, m) Dir:OnLFW(s, m) end)
    c:RegisterHandler("LFO", function(s, m) Dir:OnLFO(s, m) end)
    c:RegisterHandler("LFR", function(s, m) Dir:OnLFR(s, m) end)
    if c.OnNetworkReady then
        c:OnNetworkReady(function()
            if COC.db and COC.db.lfw and COC.db.lfw.prof then Dir:_BroadcastLFW(); Dir:_StartLFWTicker() end
        end)
    end
end
