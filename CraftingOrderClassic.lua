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

-- Scan de la fenêtre métier ouverte → union dans CraftLink ; miroir vers MA SavedVariables.
function COC:Scan()
    if not (CraftLink and self.db) then return end
    local _, changed = CraftLink:ScanOpenKnown()
    if changed then
        CraftLink:SaveMyRecipes(self.db.knownRecipes)        -- persiste à chaque plan appris
        if self.Directory then self.Directory:AnnounceThrottled() end   -- + rediffuse aux autres
    end
end

-- /co : statut. Infra CraftLink (catalogue + versions) + MES recettes captées (autonome).
function COC:Status()
    if not CraftLink then
        p("CraftLink introuvable — l'infra partagée n'est pas chargée.")
        return
    end
    -- On compte les métiers ENREGISTRÉS (table peuplée au load) — pas CraftLink.catalog, qui est
    -- construit paresseusement et serait encore vide à ce point (affichait 0 à tort).
    local profs = 0
    for _ in pairs(CraftLink.professions or {}) do profs = profs + 1 end
    p(string.format("infra CraftLink — dataVersion=|cFFE8B84B%d|r, protocole=v%d, catalogue=%d métier(s) %s",
        CraftLink:DataVersion(), CraftLink:ProtocolVersion(), profs,
        CraftLink:HasCatalog() and "|cFF33DD33prêt|r" or "|cFFFF4444vide|r"))

    local s = CraftLink:RecipeSummary()
    if #s > 0 then
        local parts = {}
        for _, e in ipairs(s) do parts[#parts + 1] = e.prof .. " " .. e.known .. "/" .. e.total end
        p("mes recettes captées : " .. table.concat(parts, ", "))
    else
        p("aucune recette captée — ouvre une fenêtre de métier une fois pour l'amorcer.")
    end

    local d = COC.Directory
    if d then
        p(string.format("réseau global : %s — |cFFFFFFFF%d|r en ligne, |cFFFFFFFF%d|r crafteur(s) connus",
            CraftLink:IsNetworkReady() and "|cFF33DD33canal rejoint|r" or "|cFFFFCC00connexion…|r",
            d:CountOnline(), d:CountKnownCrafters()))
    end
end

function COC:Help()
    p("commandes :")
    print("  |cFFFFFFFF/co|r — statut (infra, mes recettes, réseau)")
    print("  |cFFFFFFFF/co orders|r — carnet d'ordres")
    print("  |cFFFFFFFF/co post [shift-clic objet] [xN] [prix]|r — poster une commande")
    print("  |cFFFFFFFF/co accept <id>|r / |cFFFFFFFF/co done <id>|r / |cFFFFFFFF/co cancel <id>|r")
    print("  |cFFFFFFFF/co refresh|r — solliciter l'annuaire (présence + proximité)")
    print("  |cFFFFFFFF/co métier [nom]|r — vue commandes d'un métier (ou menu des métiers si vide)")
    print("  |cFFFFFFFF/co profwindow|r — basculer fenêtre métier custom / vue Blizzard")
    print("  |cFFFFFFFF/co debug|r — |cFFFF8800mode solo|r : injecte/retire un réseau fictif (artisans + commandes)")
    print("  |cFFFFFFFF/co trace|r — |cFFFF8800diag|r : journalise le réseau dans la SavedVariable (off | clear | dump)")
end

-- Dispatch des sous-commandes /co (extrait de OnEvent pour rester sous le seuil anti-monolithe).
function COC:Slash(msg)
    local cmd, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    cmd = (cmd or ""):lower()
    local O, D = COC.Orders, COC.Directory
    if cmd == "" then
        if COC.UI then COC.UI:Toggle() end
    elseif cmd == "status" then COC:Status()
    elseif cmd == "refresh" or cmd == "scan" then
        if D then D:Refresh(); p("réseau : sollicitation envoyée (HI global + PING proximité).") end
    elseif cmd == "orders" or cmd == "list" then if O then O:PrintList() end
    elseif cmd == "post"   then if O then O:PostFromInput(rest) end
    elseif cmd == "cancel" then if O then O:Cancel(rest) end
    elseif cmd == "accept" then if O then O:Accept(rest) end
    elseif cmd == "done"   then if O then O:Deliver(rest) end
    elseif cmd == "prof" or cmd == "métier" or cmd == "metier" then
        if rest and rest ~= "" and COC.ProfWindow and CraftLink then
            local key = CraftLink:ResolveProfession(rest)
            if key then COC.ProfWindow:OpenFor(key) else p("métier inconnu : " .. rest) end
        elseif COC.UI and COC.UI.ToggleProfMenu then COC.UI:ToggleProfMenu() end
    elseif cmd == "profwindow" or cmd == "pw" then
        if COC.ProfWindow then COC.ProfWindow:SetEnabled(not COC.ProfWindow:IsEnabled()) end
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
    elseif event == "PLAYER_LOGIN" then
        if CraftLink and COC.db then CraftLink:LoadMyRecipes(COC.db.knownRecipes) end
        -- Trace réseau persistée (diagnostic 2 comptes) : on branche le tracer de la lib sur COC.Trace.
        if CraftLink and CraftLink.SetTracer then
            CraftLink:SetTracer(function(c, m) if COC.Trace then COC.Trace:Log(c, m) end end)
        end
        if COC.Trace then COC.Trace:AutoEnablePTR() end   -- PTR/test → logs auto (sans /co trace)
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
        p("loaded — |cFFFFFFFF/co help|r pour les commandes. (Réseau global de craft — autonome.)")
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
