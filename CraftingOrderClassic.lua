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
    if changed then CraftLink:SaveMyRecipes(self.db.knownRecipes) end
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

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
-- Capture autonome : on scanne à l'ouverture/maj des fenêtres TradeSkill ET Craft (Enchantement).
f:RegisterEvent("TRADE_SKILL_SHOW")
f:RegisterEvent("TRADE_SKILL_UPDATE")
f:RegisterEvent("CRAFT_SHOW")
f:RegisterEvent("CRAFT_UPDATE")
f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        CraftingOrderClassicDB = CraftingOrderClassicDB or {}
        COC.db = CraftingOrderClassicDB
        COC.db.knownRecipes = COC.db.knownRecipes or {}
    elseif event == "PLAYER_LOGIN" then
        if CraftLink and COC.db then CraftLink:LoadMyRecipes(COC.db.knownRecipes) end
        if COC.Directory then COC.Directory:Start() end   -- transport + annuaire global
        SLASH_CRAFTINGORDER1 = "/co"
        SLASH_CRAFTINGORDER2 = "/craftorder"
        SlashCmdList["CRAFTINGORDER"] = function(msg)
            local arg = (msg or ""):lower():gsub("%s+", "")
            if (arg == "refresh" or arg == "scan") and COC.Directory then
                COC.Directory:Refresh()
                p("réseau : sollicitation envoyée (HI global + PING proximité).")
            else
                COC:Status()
            end
        end
        p("loaded — |cFFFFFFFF/co|r statut, |cFFFFFFFF/co refresh|r sollicite l'annuaire. (Réseau global — autonome.)")
    else
        -- TRADE_SKILL_* / CRAFT_* : la fenêtre est lisible → on capte.
        pcall(function() COC:Scan() end)
    end
end)
