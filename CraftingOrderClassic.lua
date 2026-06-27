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
    local profs = 0
    for _ in pairs(CraftLink.catalog or {}) do profs = profs + 1 end
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
        SLASH_CRAFTINGORDER1 = "/co"
        SLASH_CRAFTINGORDER2 = "/craftorder"
        SlashCmdList["CRAFTINGORDER"] = function() COC:Status() end
        p("loaded — |cFFFFFFFF/co|r pour le statut. (Réseau global de commandes de craft — autonome, embarque CraftLink.)")
    else
        -- TRADE_SKILL_* / CRAFT_* : la fenêtre est lisible → on capte.
        pcall(function() COC:Scan() end)
    end
end)
