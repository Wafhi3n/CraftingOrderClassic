-- CraftingOrderClassic_MinimapIndicator_Orders.lua — icônes « une commande t'attend » dans la barre
-- de la minicarte. Spec : docs/specs/icone-commande-recue.md (rangs 4.xx, cf. icone-minicarte.md).
--
-- Une icône PAR MÉTIER : l'icône du métier où la commande est arrivée, avec le nombre de commandes
-- dans le coin (décision du user, 2026-09-28, 2e tour). Chaque icône est un ÉTAT, pas un « non lu » :
-- elle reste tant qu'au moins une commande NOMMÉE pour moi (ou pour un de mes rerolls) attend ma
-- réponse dans ce métier, et s'éteint seule quand plus aucune n'attend — acceptée, refusée, annulée,
-- masquée, expirée. C'est le comportement de l'icône des commandes personnelles de Blizzard
-- (MiniMapCraftingOrderFrameMixin, Blizzard_Minimap/Mainline/Minimap.lua).
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
local UNKNOWN  = "?"   -- métier inconnu du catalogue : l'icône générique des commandes

-- Rang de chaque métier dans la barre : 4 + position / 100, dans un ordre FIXE — une commande qui
-- arrive dans un nouveau métier ne fait pas sauter les icônes déjà là. Tout reste sous 5, rang
-- réservé à la prochaine icône (« livrée »). La barre trie numériquement (LayoutFrame.lua).
local PROF_ORDER = { "Alchemy", "Blacksmithing", "Enchanting", "Engineering", "Inscription",
    "Jewelcrafting", "Leatherworking", "Tailoring", "Cooking", "First Aid", "Fishing",
    "Herbalism", "Mining", "Skinning", "Elemental", "Poisons" }
local extraRank = 0    -- métier hors liste : un rang à part, attribué dans l'ordre d'arrivée

local function rankOf(prof)
    if prof == UNKNOWN then return 4.99 end
    for i, p in ipairs(PROF_ORDER) do if p == prof then return 4 + i / 100 end end
    extraRank = extraRank + 1
    return 4.8 + extraRank / 1000   -- deux rangs identiques s'ordonneraient au hasard
end

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

-- Les mêmes, rangées par métier : { [prof] = { o, … } }, chaque liste plus récente d'abord.
local function byProfession(list)
    local groups = {}
    for _, o in ipairs(list) do
        local p = o.profession or UNKNOWN
        groups[p] = groups[p] or {}
        groups[p][#groups[p] + 1] = o
    end
    return groups
end

local function waitingIn(prof) return byProfession(UI:OrdersWaitingForMe())[prof] or {} end

-- Au moins une commande à MON nom (pas à un reroll) : la fenêtre native ne connaît que le perso
-- connecté, elle ne saurait pas ouvrir le métier d'un autre.
local function hasMine(list)
    for _, o in ipairs(list) do if o.recipient == me() then return true end end
    return false
end

-- ------------------------------------------------------------------
-- Une icône par métier
-- ------------------------------------------------------------------
local function tipLine(o)
    local O, Skin = COC.Orders, UI.Skin
    local name = (O and O.OrderName) and O:OrderName(o) or "?"
    local qty  = (Skin and Skin.QtySuffix) and Skin.QtySuffix(o) or ""
    local who  = (o.recipient ~= me()) and ("  |cFF888888" .. string.format(L["pour %s"], o.recipient) .. "|r") or ""
    return "|cFFFFFFFF" .. tostring(o.buyer) .. "|r : " .. name .. qty .. who
end

local function openable(prof, list) return prof ~= UNKNOWN and hasMine(list) end

local function fillTip(tt, prof)
    local list, Skin = waitingIn(prof), UI.Skin
    if prof ~= UNKNOWN and Skin and Skin.ProfLabel then tt:AddLine(Skin.ProfLabel(prof), 1, 0.82, 0) end
    tt:AddLine(string.format(L["Commandes à ton nom : %d"], #list), 1, 1, 1)
    for i = 1, math.min(#list, TIP_MAX) do tt:AddLine(tipLine(list[i]), 0.8, 0.8, 0.8) end
    if #list > TIP_MAX then tt:AddLine(string.format(L["+%d de plus"], #list - TIP_MAX), 0.6, 0.6, 0.6) end
    if openable(prof, list) then tt:AddLine(L["Clic : ouvrir cette fenêtre de métier."], 0.6, 1, 0.6) end
end

-- Clic : ce métier-là. Seul un reroll attend, ou métier inconnu : la liste dans le chat.
local function open(prof)
    local PW = COC.ProfWindow
    if openable(prof, waitingIn(prof)) and PW and PW.OpenFor then return PW:OpenFor(prof) end
    if COC.Orders and COC.Orders.PrintList then COC.Orders:PrintList() end
end

-- Définie la première fois qu'une commande arrive dans ce métier. Icône carrée du métier, 22 px (la
-- taille de l'outil) ; sans icône connue, celle des commandes de Blizzard à sa taille native (20 x 15,
-- vue au labo le 2026-09-27 et en jeu le 2026-09-28).
local function define(prof)
    local key = "order:" .. prof
    if UI._indicators[key] then return end
    local Skin = UI.Skin
    local tex = prof ~= UNKNOWN and Skin and Skin.ProfIcon and Skin.ProfIcon(prof) or nil
    local def = {
        order   = rankOf(prof),
        tooltip = function(tt) fillTip(tt, prof) end,
        onClick = function() open(prof) end,
    }
    if tex then
        def.texture = tex
    else
        def.atlas, def.useAtlasSize, def.width, def.height = "UI-HUD-Minimap-CraftingOrder-Up", true, 20, 15
    end
    UI:DefineIndicator(key, def)
end

-- ------------------------------------------------------------------
-- Recalcul
-- ------------------------------------------------------------------
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

-- Chaque icône de métier reçoit son état et son nombre. L'outil ne recompose la barre (cadre du mode
-- Édition) que quand une icône apparaît ou disparaît ; sans la barre, il ne retient rien et le
-- recalcul suivant réessaiera.
local function apply()
    local list = UI:OrdersWaitingForMe()
    local groups = byProfession(list)
    for prof in pairs(groups) do define(prof) end
    for key in pairs(UI._indicators) do
        local prof = key:match("^order:(.+)$")
        if prof then
            local g = groups[prof]
            UI:SetIndicator(key, g ~= nil, g and #g or nil)
        end
    end
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
