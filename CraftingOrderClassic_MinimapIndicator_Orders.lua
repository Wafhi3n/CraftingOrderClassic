-- CraftingOrderClassic_MinimapIndicator_Orders.lua — 2e icône de la barre de la minicarte : « une
-- commande t'attend ». Spec : docs/specs/icone-commande-recue.md (rang 4, cf. icone-minicarte.md).
--
-- L'icône est un ÉTAT, pas un « non lu » (décision du user, 2026-09-28) : elle reste allumée tant
-- qu'au moins une commande NOMMÉE pour moi (ou pour un de mes rerolls) attend ma réponse, et s'éteint
-- seule quand plus aucune n'attend — acceptée, refusée, annulée, masquée, expirée. C'est le
-- comportement de l'icône des commandes personnelles de Blizzard (MiniMapCraftingOrderFrameMixin,
-- Blizzard_Minimap/Mainline/Minimap.lua).
--
-- Une seule source de vérité, `UI:OrdersWaitingForMe()`, qui relit le cache. Les endroits où cet état
-- change appellent `UI:RefreshOrderIndicator()` : réception réseau (Orders:OnNetwork), accepter /
-- refuser (Orders:Accept / Decline), masquer / réafficher une commande (vue métier), sourdine d'un
-- joueur (Moderation:Mute / Unmute), /co notify. L'entrée en jeu et l'expiration (un minuteur unique
-- armé sur la plus proche échéance) sont gérées ici. Pas de ticker.

local COC = CraftingOrderClassic
local UI  = COC.UI
local L   = COC.L

local TIP_MAX  = 5     -- commandes listées dans l'infobulle ; au-delà, « +N de plus »
local DEBOUNCE = 0.2   -- les rafales réseau (fanout, relais à la connexion) arrivent groupées

local function me() return COC.Api.PlayerName() end   -- nom RÉSEAU (« Prénom Nom » sur Forever)

-- Moi, ou un perso de MON compte (IsMyChar lit MA SavedVariable : aucun message réseau ne peut
-- m'attribuer un reroll).
local function forMe(name)
    if not name then return false end
    return name == me() or (COC.IsMyChar and COC:IsMyChar(name)) or false
end

local function ttl() return (COC.Orders and COC.Orders.ORDER_TTL) or (6 * 3600) end

-- Les commandes qui attendent ma réponse, plus récente d'abord. Mêmes règles que l'alerte d'une
-- commande nommée (Orders:_ShouldAlert) : ce qui ne sonnerait pas n'allume pas l'icône.
function UI:OrdersWaitingForMe()
    local out, db = {}, COC.db
    if not (db and db.orders) or db.notifyScope == "off" then return out end
    local Mod, masked, now, life = COC.Moderation, db.muted or {}, time(), ttl()
    for id, o in pairs(db.orders) do
        if o.status == "open" and forMe(o.recipient) and not forMe(o.buyer)
           and (now - (o.ts or now)) <= life and not masked[id]
           and not (Mod and Mod.IsMuted and Mod:IsMuted(o.buyer)) then
            out[#out + 1] = o
        end
    end
    table.sort(out, function(a, b) return (a.ts or 0) > (b.ts or 0) end)
    return out
end

-- ------------------------------------------------------------------
-- L'icône
-- ------------------------------------------------------------------
local function tipLine(o)
    local O, Skin = COC.Orders, UI.Skin
    local name = (O and O.OrderName) and O:OrderName(o) or "?"
    local qty  = (Skin and Skin.QtySuffix) and Skin.QtySuffix(o) or ""
    local who  = (o.recipient ~= me()) and ("  |cFF888888" .. string.format(L["pour %s"], o.recipient) .. "|r") or ""
    return "|cFFFFFFFF" .. tostring(o.buyer) .. "|r : " .. name .. qty .. who
end

-- La plus récente commande à MON nom (pas à un reroll) : la fenêtre native ne connaît que le perso
-- connecté, elle ne saurait pas ouvrir le métier d'un autre.
local function newestMine(list)
    for _, o in ipairs(list) do
        if o.recipient == me() then return o end
    end
end

UI:DefineIndicator("order", {
    -- L'icône des commandes d'artisanat de Blizzard, à sa taille native : celle vue au labo le
    -- 2026-09-27 (`/tlab indica`, 20 x 15) et vérifiée par sa sonde d'atlas.
    atlas = "UI-HUD-Minimap-CraftingOrder-Up", useAtlasSize = true, width = 20, height = 15,
    order = 4,
    tooltip = function(tt)
        local list = UI:OrdersWaitingForMe()
        tt:AddLine(string.format(L["Commandes à ton nom : %d"], #list), 1, 1, 1)
        for i = 1, math.min(#list, TIP_MAX) do tt:AddLine(tipLine(list[i]), 0.8, 0.8, 0.8) end
        if #list > TIP_MAX then tt:AddLine(string.format(L["+%d de plus"], #list - TIP_MAX), 0.6, 0.6, 0.6) end
        tt:AddLine(L["Clic : ouvrir le métier de la plus récente."], 0.6, 1, 0.6)
    end,
    onClick = function()
        local o, PW = newestMine(UI:OrdersWaitingForMe()), COC.ProfWindow
        if o and o.profession and PW and PW.OpenFor then return PW:OpenFor(o.profession) end
        if COC.Orders and COC.Orders.PrintList then COC.Orders:PrintList() end   -- reroll seul, métier inconnu
    end,
})

-- ------------------------------------------------------------------
-- Recalcul
-- ------------------------------------------------------------------
local lit      = false   -- dernier état POSÉ : la barre (cadre du mode Édition) n'est recomposée que s'il change
local expiryGen = 0      -- chaque recalcul périme le minuteur précédent

-- Aucun événement ne dit qu'une commande a expiré : un minuteur unique, armé sur la plus proche
-- échéance, rappelle le recalcul.
local function armExpiry(list)
    expiryGen = expiryGen + 1
    if #list == 0 or not (C_Timer and C_Timer.After) then return end
    local now, life, soonest = time(), ttl(), nil
    for _, o in ipairs(list) do
        local left = (o.ts or now) + life - now
        if not soonest or left < soonest then soonest = left end
    end
    local gen = expiryGen
    C_Timer.After(math.max(1, soonest + 1), function()
        if gen == expiryGen then UI:RefreshOrderIndicator() end
    end)
end

local function apply()
    local list = UI:OrdersWaitingForMe()
    local want = #list > 0
    -- Sans la barre (hors Forever, ou pas encore construite), SetIndicator rend faux : on ne retient
    -- pas un allumage qui n'a pas eu lieu, le prochain recalcul réessaiera.
    if want ~= lit and (UI:SetIndicator("order", want) or not want) then lit = want end
    armExpiry(list)
end

function UI:RefreshOrderIndicator()
    if not (C_Timer and C_Timer.After) then return apply() end
    if self._orderIndPending then return end
    self._orderIndPending = true
    C_Timer.After(DEBOUNCE, function() UI._orderIndPending = nil; apply() end)
end

-- Les commandes sont dans la SavedVariable : une commande arrivée avant la déconnexion attend encore.
-- Même événement que l'icône de Blizzard.
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function() UI:RefreshOrderIndicator() end)
