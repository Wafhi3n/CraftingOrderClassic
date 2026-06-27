-- Crafting Order - Classic — réseau GLOBAL et SOCIAL de commandes de craft.
--
-- Addon AUTONOME : fonctionne SANS Guild Economy. Il consomme l'infra partagée CraftLink-1.0
-- (catalogue de recettes + registre + — à venir — transports global/guilde/proximité), embarquée
-- via LibStub : la MÊME instance que Guild Economy si les deux sont installés, sans dupliquer la
-- logique. À terme : carnet d'ordres global, annuaire « qui peut crafter quoi », profils,
-- réputation (compteur de crafts livrés), favoris/suivi, présence.
--
-- État actuel : SCAFFOLD. Le carnet d'ordres et la couche sociale arrivent (étapes C/D). Pour
-- l'instant cet addon prouve qu'il lit CraftLink (catalogue + registre) depuis un addon distinct.
-- Tant que le registre n'a pas migré dans CraftLink (étape A3), il lit aussi le registre live de
-- Guild Economy via un pont temporaire — purement optionnel (l'addon marche sans).

local ADDON = ...
CraftingOrderClassic = {}
local COC = CraftingOrderClassic

local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)

local function p(msg) print("|cFF33DD88Crafting Order|r " .. msg) end

-- /co : statut. Démontre l'accès à CraftLink (catalogue + dataVersion + protocolVersion) depuis CE
-- second addon, et — pont temporaire — au registre live de Guild Economy s'il est présent.
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

    local reg = _G.TradeScanner and _G.TradeScanner.Registry
    if reg and reg.Summary then
        local s = reg:Summary()
        if #s > 0 then
            local parts = {}
            for _, e in ipairs(s) do parts[#parts + 1] = e.prof .. " " .. e.known .. "/" .. e.total end
            p("registre joignable — mes recettes : " .. table.concat(parts, ", "))
        else
            p("registre joignable — aucune recette captée (ouvre un métier une fois).")
        end
    else
        p("registre live non joignable (Guild Economy non chargé) — autonomie complète à l'étape A3.")
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        CraftingOrderClassicDB = CraftingOrderClassicDB or {}
        COC.db = CraftingOrderClassicDB
    elseif event == "PLAYER_LOGIN" then
        SLASH_CRAFTINGORDER1 = "/co"
        SLASH_CRAFTINGORDER2 = "/craftorder"
        SlashCmdList["CRAFTINGORDER"] = function() COC:Status() end
        p("loaded — |cFFFFFFFF/co|r pour le statut. (Réseau global de commandes de craft — autonome, embarque CraftLink.)")
    end
end)
