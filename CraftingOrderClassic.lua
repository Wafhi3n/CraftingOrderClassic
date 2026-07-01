-- Crafting Order - Classic — réseau GLOBAL et SOCIAL de commandes de craft.
--
-- Addon AUTONOME : fonctionne SANS Guild Economy. Il consomme l'infra partagée CraftLink-1.0
-- (catalogue de recettes + registre « mes recettes » + — à venir — transports global/guilde/
-- proximité), embarquée via LibStub. À terme : carnet d'ordres global, annuaire « qui peut
-- crafter quoi », profils, réputation (compteur de crafts livrés), favoris/suivi, présence.
--
-- État actuel : capture AUTONOME des recettes (scan des fenêtres métier via CraftLink) +
-- persistance propre (CraftingOrderClassicDB). Le carnet d'ordres et le social arrivent (C/D).

local ADDON = ...
CraftingOrderClassic = {}
local COC = CraftingOrderClassic

local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)

local function p(msg) print("|cFF33DD88Crafting Order|r " .. msg) end

-- Registre de recettes PAR PERSO. La SavedVariables est partagée par COMPTE, donc on partitionne
-- knownRecipes[nom-royaume] : on ne charge/diffuse (RK) QUE la partition du perso courant — sinon les
-- métiers des alts fuiraient dans MON annonce (« Balragar forgeron » = recettes de Luletta, même compte).
-- Les partitions des alts sont CONSERVÉES (future feature « ton reroll X peut faire cette commande »).
function COC:_MyKnownStore()
    if not self.db then return nil end
    self.db.knownRecipes = self.db.knownRecipes or {}
    local n  = (UnitName and UnitName("player")) or "?"
    local rl = (GetRealmName and GetRealmName()) or ""
    local me = n .. "-" .. rl
    self.db.knownRecipes[me] = self.db.knownRecipes[me] or {}
    return self.db.knownRecipes[me]
end

-- Scan de la fenêtre métier ouverte → union dans CraftLink ; miroir vers MA partition SavedVariables.
function COC:Scan()
    if not (CraftLink and self.db) then return end
    local _, changed = CraftLink:ScanOpenKnown()
    if changed then
        local store = self:_MyKnownStore()
        if store then CraftLink:SaveMyRecipes(store) end     -- persiste à chaque plan appris
        if self.Directory then self.Directory:AnnounceThrottled() end   -- + rediffuse aux autres
    end
end

-- /co : statut. Infra CraftLink (catalogue + versions) + MES recettes captées (autonome).
function COC:Status()
    local L = COC.L
    if not CraftLink then
        p(L["CraftLink introuvable — l'infra partagée n'est pas chargée."])
        return
    end
    -- On compte les métiers ENREGISTRÉS (table peuplée au load) — pas CraftLink.catalog, qui est
    -- construit paresseusement et serait encore vide à ce point (affichait 0 à tort).
    local profs = 0
    for _ in pairs(CraftLink.professions or {}) do profs = profs + 1 end
    p(string.format(L["infra CraftLink — dataVersion=|cFFE8B84B%d|r, protocole=v%d, catalogue=%d métier(s) %s"],
        CraftLink:DataVersion(), CraftLink:ProtocolVersion(), profs,
        CraftLink:HasCatalog() and ("|cFF33DD33" .. L["prêt"] .. "|r") or ("|cFFFF4444" .. L["vide"] .. "|r")))

    local s = CraftLink:RecipeSummary()
    if #s > 0 then
        local parts = {}
        for _, e in ipairs(s) do parts[#parts + 1] = e.prof .. " " .. e.known .. "/" .. e.total end
        p(L["mes recettes captées : "] .. table.concat(parts, ", "))
    else
        p(L["aucune recette captée — ouvre une fenêtre de métier une fois pour l'amorcer."])
    end

    local d = COC.Directory
    if d then
        p(string.format(L["réseau global : %s — |cFFFFFFFF%d|r en ligne, |cFFFFFFFF%d|r crafteur(s) connus"],
            CraftLink:IsNetworkReady() and ("|cFF33DD33" .. L["canal rejoint"] .. "|r") or ("|cFFFFCC00" .. L["connexion…"] .. "|r"),
            d:CountOnline(), d:CountKnownCrafters()))
    end
    if CraftLink.GlobalChannelKind then
        local kind  = CraftLink:GlobalChannelKind()
        local label = (CraftLink.GlobalChannelLabel and CraftLink:GlobalChannelLabel()) or "?"
        if kind == "custom" then
            p("  " .. string.format(L["canal : |cFFFFFFFF%s|r"], label))
        else
            p("  " .. L["canal : non rejoint — |cFFFFFFFF/co channel on|r pour réessayer"])
        end
    end
end

-- /co channel [on|off] : (dés)activer l'auto-join du canal réseau. Persistant via COC.db.channelOptOut.
function COC:ChannelCmd(arg)
    local L = COC.L
    if not CraftLink then p(L["CraftLink absent — l'infra réseau n'est pas chargée."]); return end
    arg = (arg or ""):lower()
    if arg == "off" then
        COC.db.channelOptOut = true
        if CraftLink.SetAutoJoin then CraftLink:SetAutoJoin(false) end
        p(L["auto-join du canal réseau désactivé — le carnet global ne fonctionnera plus (whisper/guilde restent actifs)."])
    elseif arg == "on" then
        COC.db.channelOptOut = nil
        if CraftLink.SetAutoJoin then CraftLink:SetAutoJoin(true) end
        if CraftLink.JoinNetwork then CraftLink:JoinNetwork() end
        p(L["canal réseau (re)rejoint."])
    else
        local label = (CraftLink.GlobalChannelLabel and CraftLink:GlobalChannelLabel()) or "?"
        p(string.format(L["canal global actuel : |cFFFFFFFF%s|r. |cFFFFFFFF/co channel off|r pour le quitter, |cFFFFFFFF/co channel on|r pour le rejoindre."], label))
    end
end

-- /co notify [all|directed|named|off] : portée des toasts de nouvelle commande (cf. Orders:_ShouldAlert).
-- Persistant via COC.db.notifyScope. Défaut "all" (toute commande visible notifie).
local NOTIFY_MODES = { all = true, directed = true, named = true, off = true }
function COC:NotifyCmd(arg)
    local L = COC.L
    arg = (arg or ""):lower()
    if NOTIFY_MODES[arg] then COC.db.notifyScope = arg end
    local cur = (COC.db and COC.db.notifyScope) or "all"
    p(string.format(L["notifications : |cFFFFFFFF%s|r — /co notify [all|directed|named|off]"], cur))
end

-- /co scan [on|off] : (dés)active le scanner du canal Commerce / de la guilde qui repère les demandes
-- de craft postées en clair (« WTB [objet] ») et les remonte en Entrantes + notif. Persistant via
-- COC.db.scanInbound (défaut ON). OFF = plus aucune détection depuis le chat public.
function COC:ScanCmd(arg)
    local L = COC.L
    arg = (arg or ""):lower()
    if arg == "on"  then COC.db.scanInbound = true
    elseif arg == "off" then COC.db.scanInbound = false end
    local on = COC.db and COC.db.scanInbound ~= false
    p(string.format(L["scan chat commerce/guilde : |cFFFFFFFF%s|r — /co scan [on|off]"],
        on and L["actif"] or L["coupé"]))
end

-- Avertit UNE FOIS que l'addon rejoint son canal réseau dédié (transparence : le joueur le verra
-- dans sa liste de canaux). Déclenché à la première acquisition du canal. Dialogue défini
-- paresseusement (Locale chargé au runtime).
function COC:ChannelNotice()
    if not COC.db or COC.db.channelNoticeShown then return end
    if not (StaticPopupDialogs and StaticPopup_Show) then return end
    local L = COC.L
    local label = (CraftLink and CraftLink.GlobalChannelLabel and CraftLink:GlobalChannelLabel()) or "CraftLinkNet"
    StaticPopupDialogs["COC_CHANNEL_NOTICE"] = {
        text = string.format(L["Crafting Order rejoint un canal dédié (|cFFFFD100%s|r) pour faire circuler le carnet de commandes entre joueurs de l'addon. Tu le verras dans ta liste de canaux ; aucun message lisible n'y est envoyé. Tu peux le quitter à tout moment — |cFFFFFFFF/co channel off|r."], label),
        button1 = OKAY or "OK",
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
    COC.db.channelNoticeShown = true
    StaticPopup_Show("COC_CHANNEL_NOTICE")
end

-- Balise TEXTE de découverte. À n'appeler QUE depuis une action joueur (hardware event) — sinon
-- ADDON_ACTION_BLOCKED (SendChatMessage interdit hors input). Émise au clic Poster et sur /co refresh.
-- Throttle (30 s plancher) géré par la lib. C'est le seul créneau où l'envoi canal fonctionne.
function COC:Beacon()
    if CraftLink and CraftLink.SendBeacon then CraftLink:SendBeacon() end
end

-- /co beacon : diag. Émet une balise TEXTE sur le canal SOUS hardware event (slash = touche Entrée).
-- Sert à valider que SendChatMessage de notre code, déclenché par une action joueur, est bien délivré
-- et reçu+parsé par l'autre porteur (lance |cFFFFFFFF/co trace dump|r sur l'AUTRE perso après).
function COC:BeaconDiag()
    local L = COC.L
    if not (CraftLink and CraftLink.SendBeacon) then p(L["CraftLink absent — l'infra réseau n'est pas chargée."]); return end
    CraftLink._lastBeacon = 0   -- diag : ignore le throttle pour ce test ponctuel
    local ok = CraftLink:SendBeacon("diag")
    p(string.format(L["balise TEXTE émise=%s (canal idx=%s) — lance |cFFFFFFFF/co trace dump|r sur l'AUTRE perso et cherche |cFFFFFFFF[recv] beacon|r."],
        tostring(ok), tostring(CraftLink._channelIndex)))
end

-- /co wipe : diag. Vide MON annuaire local (roster/en-ligne) — simule un « inconnu » pour retester la
-- découverte par balise seule. Ne touche ni MES commandes ni MES recettes. Exécute-le sur LES DEUX
-- comptes pour un test propre (sinon l'autre me connaît encore et me fanoute directement en whisper).
function COC:WipeRoster()
    local L = COC.L
    if not COC.db then return end
    COC.db.roster = {}
    if COC.Directory then COC.Directory.roster = COC.db.roster; COC.Directory.online = {} end
    p(L["annuaire local vidé (diag) — exécute aussi |cFFFFFFFF/co wipe|r sur l'autre compte pour un test de découverte propre."])
end

function COC:Help()
    local L = COC.L
    p(L["commandes :"])
    print("  |cFFFFFFFF/co|r — " .. L["statut (infra, mes recettes, réseau)"])
    print("  |cFFFFFFFF/co orders|r — " .. L["carnet d'ordres"])
    print("  |cFFFFFFFF/co post [shift-clic objet] [xN] [prix]|r — " .. L["poster une commande"])
    print("  |cFFFFFFFF/co accept <id>|r / |cFFFFFFFF/co done <id>|r / |cFFFFFFFF/co cancel <id>|r")
    print("  |cFFFFFFFF/co refresh|r — " .. L["solliciter l'annuaire (présence + proximité)"])
    print("  |cFFFFFFFF/co ping|r — |cFFFF8800" .. L["diag"] .. "|r : " .. L["teste l'aller-retour réseau (PING global → PONG des autres porteurs)"])
    print("  |cFFFFFFFF/co métier [nom]|r — " .. L["vue commandes d'un métier (ou menu des métiers si vide)"])
    print("  |cFFFFFFFF/co profwindow|r — " .. L["basculer fenêtre métier custom / vue Blizzard"])
    print("  |cFFFFFFFF/co channel [on|off]|r — " .. L["(dés)activer le canal réseau global"])
    print("  |cFFFFFFFF/co notify [all|directed|named|off]|r — " .. L["portée des notifications de commande"])
    print("  |cFFFFFFFF/co scan [on|off]|r — " .. L["détecter les demandes de craft postées en chat (commerce/guilde)"])
    print("  |cFFFFFFFF/co debug|r — |cFFFF8800" .. L["mode solo"] .. "|r : " .. L["injecte/retire un réseau fictif (artisans + commandes)"])
    print("  |cFFFFFFFF/co trace|r — |cFFFF8800" .. L["diag"] .. "|r : " .. L["journalise le réseau dans la SavedVariable (off | clear | dump)"])
end

-- Dispatch des sous-commandes /co (extrait de OnEvent pour rester sous le seuil anti-monolithe).
function COC:Slash(msg)
    local cmd, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    cmd = (cmd or ""):lower()
    local O, D = COC.Orders, COC.Directory
    if cmd == "" then
        if COC.UI then COC.UI:Toggle() end
    elseif cmd == "status" then COC:Status()
    elseif cmd == "refresh" then
        if D then D:Refresh(); p(COC.L["réseau : sollicitation envoyée (HI global + PING proximité)."]) end
    elseif cmd == "orders" or cmd == "list" then if O then O:PrintList() end
    elseif cmd == "post"   then if O then O:PostFromInput(rest) end
    elseif cmd == "cancel" then if O then O:Cancel(rest) end
    elseif cmd == "accept" then if O then O:Accept(rest) end
    elseif cmd == "done"   then if O then O:Deliver(rest) end
    elseif cmd == "ping"   then if O then O:Ping() end
    elseif cmd == "prof" or cmd == "métier" or cmd == "metier" then
        if rest and rest ~= "" and COC.ProfWindow and CraftLink then
            local key = CraftLink:ResolveProfession(rest)
            if key then COC.ProfWindow:OpenFor(key) else p(COC.L["métier inconnu : "] .. rest) end
        elseif COC.UI and COC.UI.ToggleProfMenu then COC.UI:ToggleProfMenu() end
    elseif cmd == "profwindow" or cmd == "pw" then
        if COC.ProfWindow then COC.ProfWindow:SetEnabled(not COC.ProfWindow:IsEnabled()) end
    elseif cmd == "channel" or cmd == "canal" then COC:ChannelCmd(rest)
    elseif cmd == "notify" or cmd == "notif" then COC:NotifyCmd(rest)
    elseif cmd == "scan" then COC:ScanCmd(rest)
    elseif cmd == "beacon" then COC:BeaconDiag()
    elseif cmd == "wipe"   then COC:WipeRoster()
    elseif cmd == "debug"  then if COC.Debug then COC.Debug:Toggle() end
    elseif cmd == "trace"  then if COC.Trace then COC.Trace:Cmd(rest) end
    elseif cmd == "help"   then COC:Help()
    else COC:Status() end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
-- Capture autonome : on scanne à l'ouverture/maj des fenêtres TradeSkill ET Craft (Enchantement).
f:RegisterEvent("TRADE_SKILL_SHOW")
f:RegisterEvent("TRADE_SKILL_UPDATE")
f:RegisterEvent("CRAFT_SHOW")
f:RegisterEvent("CRAFT_UPDATE")
f:RegisterEvent("SKILL_LINES_CHANGED")   -- gain de skill → recapture + rediffusion (Étape D)
f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        CraftingOrderClassicDB = CraftingOrderClassicDB or {}
        COC.db = CraftingOrderClassicDB
        COC.db.knownRecipes = COC.db.knownRecipes or {}
        -- Migration v2 : l'ancien format était PLAT (métier→recettes) et PARTAGÉ par compte → union
        -- polluée inter-persos, non attribuable. On le purge une fois ; chaque perso reconstruit sa
        -- partition propre (knownRecipes[nom-royaume]) en rouvrant sa fenêtre métier. Cf. COC:_MyKnownStore.
        if not COC.db.knownRecipesVer then
            if next(COC.db.knownRecipes) then COC.db.knownRecipes = {} end
            COC.db.knownRecipesVer = 2
        end
    elseif event == "PLAYER_LOGIN" then
        if CraftLink and COC.db then CraftLink:LoadMyRecipes(COC:_MyKnownStore()) end
        -- Trace réseau persistée (diagnostic 2 comptes) : on branche le tracer de la lib sur COC.Trace.
        if CraftLink and CraftLink.SetTracer then
            CraftLink:SetTracer(function(c, m) if COC.Trace then COC.Trace:Log(c, m) end end)
        end
        if COC.Trace then COC.Trace:AutoEnablePTR() end   -- PTR/test → logs auto (sans /co trace)
        -- Canal global : applique l'opt-out persistant AVANT de démarrer le transport ; et avertit le
        -- joueur UNE FOIS qu'on passe par le canal public Services (à la première acquisition).
        if CraftLink and CraftLink.SetAutoJoin then CraftLink:SetAutoJoin(not (COC.db and COC.db.channelOptOut)) end
        if CraftLink and CraftLink.OnNetworkReady then CraftLink:OnNetworkReady(function() COC:ChannelNotice() end) end
        if COC.Directory then COC.Directory:Start() end   -- transport + annuaire global
        if COC.Orders   then COC.Orders:Start()   end      -- carnet d'ordres global
        if COC.Social   then COC.Social:Start()   end      -- tooltip social + clic-droit (Étape D)
        if COC.Inbound  then COC.Inbound:Start()  end      -- capture /commerce + /guilde (non-addon)
        if COC.ProfOrders then COC.ProfOrders:Start() end  -- overlay « commandes du métier » sur la fenêtre métier
        if COC.UI and COC.UI.BuildMinimapButton then COC.UI:BuildMinimapButton() end
        if COC.Debug and C_Timer then C_Timer.After(1, function() COC.Debug:Reapply() end) end
        SLASH_CRAFTINGORDER1 = "/co"
        SLASH_CRAFTINGORDER2 = "/craftorder"
        SlashCmdList["CRAFTINGORDER"] = function(msg) COC:Slash(msg) end
        p(COC.L["chargé — |cFFFFFFFF/co help|r pour les commandes. (Réseau global de craft — autonome.)"])
    elseif event == "SKILL_LINES_CHANGED" then
        -- Gain de point / apprentissage : recapture mes niveaux et les rediffuse (throttlé).
        if COC.Directory and not COC._skillTimer and C_Timer then
            COC._skillTimer = true
            C_Timer.After(2, function()
                COC._skillTimer = nil
                COC.Directory:CaptureSkills(); COC.Directory:AnnounceSkills()
            end)
        end
    else
        -- TRADE_SKILL_* / CRAFT_* : la fenêtre est lisible → on capte.
        pcall(function() COC:Scan() end)
    end
end)
