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
-- 3e tour (2026-09-30) : les commandes NON nommées qu'un de mes persos sait faire l'allument aussi, la
-- couleur du nombre dit d'où vient la commande, et le clic va vers le perso qui sait faire (voir
-- MinimapIndicator_Who.lua).
--
-- Deux listes font la vérité, `UI:OrdersWaitingForMe()` et `UI:OrdersICanDo()`, qui relisent le cache. Les endroits où cet état
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

-- Les commandes NON nommées (guilde, amis, tous) qu'un de mes persos sait faire (3e tour, décision du
-- user du 2026-09-30). Mêmes règles que l'alerte d'une non nommée (Orders:_ShouldAlert) pour la portée,
-- sourdines et seuil anti-bot ; mais « sait faire » vaut pour TOUT le compte, pas le seul perso connecté.
function UI:OrdersICanDo()
    local out, db = {}, COC.db
    local m = db and db.notifyScope or "all"
    if not (db and db.orders) or m == "off" or m == "named" then return out end
    local O, Mod, masked, now, life = COC.Orders, COC.Moderation, db.muted or {}, time(), ttl()
    for id, o in pairs(db.orders) do
        local kind = o.status == "open" and self:_OrderKind(o)
        if kind and kind ~= "named" and not forMe(o.buyer) and (kind == "group" or m == "all")
           and (now - (o.ts or now)) <= life and not masked[id]
           and not (Mod and Mod.IsMuted and Mod:IsMuted(o.buyer))
           and not (Mod and Mod.BelowThreshold and Mod:BelowThreshold(o.buyer))
           and (not (O and O.VisibleTo) or O:VisibleTo(o)) and #self:_OrderKnowers(o) > 0 then
            out[#out + 1] = o
        end
    end
    table.sort(out, function(a, b) return (a.ts or 0) > (b.ts or 0) end)
    return out
end

-- Tout ce qui allume une icône, rangé par métier puis par type : { [prof] = { named = {…}, group = {…},
-- all = {…}, top = "named"|"group"|"all" } }, chaque liste plus récente d'abord.
local function byProfession()
    local groups = {}
    local function add(o)
        local p, kind = o.profession or UNKNOWN, UI:_OrderKind(o)
        local g = groups[p] or {}
        groups[p] = g
        g[kind] = g[kind] or {}
        g[kind][#g[kind] + 1] = o
        if not g.top or UI.ORDER_KIND_RANK[kind] < UI.ORDER_KIND_RANK[g.top] then g.top = kind end
    end
    for _, o in ipairs(UI:OrdersWaitingForMe()) do add(o) end
    for _, o in ipairs(UI:OrdersICanDo()) do add(o) end
    return groups
end

local function groupOf(prof) return byProfession()[prof] end

-- ------------------------------------------------------------------
-- Une icône par métier
-- ------------------------------------------------------------------
local function tipLine(o)
    local O, Skin = COC.Orders, UI.Skin
    local name = (O and O.OrderName) and O:OrderName(o) or "?"
    local qty  = (Skin and Skin.QtySuffix) and Skin.QtySuffix(o) or ""
    local named = UI:_OrderKind(o) == "named" and o.recipient ~= me()
    local who  = named and ("  |cFF888888" .. string.format(L["pour %s"], o.recipient) .. "|r") or ""
    return "|cFFFFFFFF" .. tostring(o.buyer) .. "|r : " .. name .. qty .. who
end

-- Le titre de chaque type, dans la couleur de son nombre : la couleur n'est jamais seule.
local function kindTitle(kind, n)
    if kind == "named" then return string.format(L["Commandes à ton nom : %d"], n) end
    if kind == "group" then return string.format(L["Pour ta guilde ou tes amis : %d"], n) end
    return string.format(L["Pour tous : %d"], n)
end

-- Où mène le clic : la plus récente commande du type affiché (celui du nombre).
local function clickTarget(g)
    local o = g and g[g.top] and g[g.top][1]
    return o, UI:_OrderClickTarget(o)
end

local function clickHint(prof, t)
    if t.kind == "native" then return L["Clic : ouvrir cette fenêtre de métier."] end
    if t.kind == "reroll" then
        local Skin = UI.Skin
        local label = (Skin and Skin.ProfLabel) and Skin.ProfLabel(prof) or prof
        return string.format(L["Clic : ouvrir %s de %s."], label, t.short)
    end
    return L["Clic : voir pourquoi."]
end

local function fillTip(tt, prof)
    local g, Skin, shown = groupOf(prof), UI.Skin, 0
    if not g then return end
    if prof ~= UNKNOWN and Skin and Skin.ProfLabel then tt:AddLine(Skin.ProfLabel(prof), 1, 0.82, 0) end
    local rest = 0
    for _, kind in ipairs({ "named", "group", "all" }) do
        local list = g[kind]
        if list then
            local c = UI:_OrderKindColor(kind)
            tt:AddLine(kindTitle(kind, #list), c[1], c[2], c[3])
            for i = 1, #list do
                if shown < TIP_MAX then tt:AddLine(tipLine(list[i]), 0.8, 0.8, 0.8); shown = shown + 1
                else rest = rest + 1 end
            end
        end
    end
    if rest > 0 then tt:AddLine(string.format(L["+%d de plus"], rest), 0.6, 0.6, 0.6) end
    local _, t = clickTarget(g)
    tt:AddLine(clickHint(prof, t), 0.6, 1, 0.6)
end

-- Clic : vers le perso qui sait faire (spec, 3e tour) — la native, la vue reroll, ou la popup.
local function open(prof)
    local g = groupOf(prof)
    local o, t = clickTarget(g)
    if not o then return end
    local PW = COC.ProfWindow
    if t.kind == "native" and PW and PW.OpenFor then return PW:OpenFor(prof) end
    if t.kind == "reroll" and PW and PW.OpenForReroll then
        -- La vue reroll détache la fenêtre native : pas en combat (cadre protégé).
        if InCombatLockdown and InCombatLockdown() then
            print("|cFF33DD88Crafting Order|r " .. L["Hors combat seulement."])
            return
        end
        return PW:OpenForReroll(prof, t.key, t.short)
    end
    UI:ShowNobodyKnows(o, #g[g.top])
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
-- Le nombre compte le type le plus personnel présent, dans sa couleur : 1 nommée + 3 publiques = « 1 » bleu.
local function apply()
    local groups, all = byProfession(), {}
    for prof, g in pairs(groups) do
        define(prof)
        for _, kind in ipairs({ "named", "group", "all" }) do
            for _, o in ipairs(g[kind] or {}) do all[#all + 1] = o end
        end
    end
    for key in pairs(UI._indicators) do
        local prof = key:match("^order:(.+)$")
        if prof then
            local g = groups[prof]
            UI:SetIndicator(key, g ~= nil, g and #g[g.top] or nil, g and UI:_OrderKindColor(g.top) or nil)
        end
    end
    armExpiry(all)
end

function UI:RefreshOrderIndicator()
    if not (C_Timer and C_Timer.After) then return apply() end
    if self._orderIndPending then return end
    self._orderIndPending = true
    C_Timer.After(DEBOUNCE, function() UI._orderIndPending = nil; apply() end)
end

-- Les commandes sont dans la SavedVariable : une commande arrivée avant la déconnexion attend encore.
-- Même événement que l'icône de Blizzard.
-- Le mode daltonien du jeu (Accessibilité) change la palette : les icônes affichées se repeignent.
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("CVAR_UPDATE")
ev:SetScript("OnEvent", function(_, event, name)
    if event == "CVAR_UPDATE" and name ~= "colorblindMode" then return end
    UI:RefreshOrderIndicator()
end)
