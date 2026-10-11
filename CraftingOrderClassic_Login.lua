-- CraftingOrderClassic_Login.lua — la seule ligne de chat de la connexion.
--
-- Règle du user du 2026-10-11 (skill publique `chat-output`) : à la connexion, rien, sauf UNE ligne
-- à la première connexion après une installation ou une mise à jour. Jusqu'à la v1.49.0, « chargé —
-- /co help » tombait à chaque connexion (case « Message à la connexion », cochée par défaut) : elle
-- est décochée par défaut, et qui l'a cochée la garde.
--
-- `COC.freshVersion` dit au reste de la session que cette connexion suit une mise à jour. Le rappel
-- de la communauté (Directory_Community, 15 s plus tard) le lit : `seenVersion` est déjà réécrit
-- quand il passe, il ne pourrait plus le savoir.
local COC = CraftingOrderClassic

local function addonVersion()
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    if not meta then return nil end
    local ok, v = pcall(meta, "CraftingOrderClassic", "Version")
    return ok and type(v) == "string" and v ~= "" and v or nil
end

function COC:LoginLine()
    local db, L = self.db, self.L
    if not db then return end
    local v = addonVersion()
    self.freshVersion = (v ~= nil and db.seenVersion ~= v)
    if v then db.seenVersion = v end
    local line
    if self.freshVersion then
        line = string.format(L["v%s installé — |cFFFFFFFF/co help|r pour les commandes."], v)
    elseif self.Channels and self.Channels.IsWatched("notif_login") then
        line = L["chargé — |cFFFFFFFF/co help|r pour les commandes. (Réseau global de craft — autonome.)"]
    end
    if line then print("|cFF33DD88Crafting Order|r " .. line) end
end
