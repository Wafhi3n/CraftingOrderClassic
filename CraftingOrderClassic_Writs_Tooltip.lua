-- CraftingOrderClassic_Writs_Tooltip.lua — l'infobulle d'un OBJET qu'un Craftsman's Writ demande,
-- partout où le jeu la montre (sac, hôtel des ventes, lien du chat…) : UNE ligne sous les siennes.
-- Spec : docs/specs/writs-aca.md, D10 (choix du user, 2026-11-11), D11 (une ligne, même jour).
--
-- C'est l'autre bout du writ : l'objet demandé, pas le parchemin (l'infobulle du writ lui-même, T3,
-- reste à faire et pourra se brancher ici). Aucun cadre créé, aucune ligne de chat, rien d'écrit
-- chez Blizzard.

local COC = CraftingOrderClassic
local W = COC.Writs
if not W then return end
local L = COC.L
local A = COC.Api

-- « Craftsman's Writ: +75 », rien de plus (D11) : l'infobulle d'objet est partagée avec le jeu et
-- les autres addons, on n'y empile pas des phrases. Le détail (writ porté, combien il en manque, ce
-- que vaut le writ) reste dans la vue Profit, dans la fenêtre de COC. La réputation est celle du writ
-- que tu portes quand deux writs demandent l'objet (ItemMark, comme la vue Profit).
local function addLines(tooltip, m)
    tooltip:AddLine(string.format(L["Writ d'artisan : +%d"], m.entry.rep or 0), 1, 0.82, 0)
end

-- Appelée par le jeu pour CHAQUE infobulle d'objet, comparaisons comprises : elle doit sortir vite.
-- Seules l'infobulle principale et celle d'un lien du chat reçoivent nos lignes (même filtre que le
-- code de Blizzard, Blizzard_PTRFeedback_Tooltips.lua) ; les comparaisons restent nues.
local function onItemTooltip(tooltip, data)
    if tooltip ~= _G.GameTooltip and tooltip ~= _G.ItemRefTooltip then return end
    local id = data and data.id
    -- Un identifiant SECRET (contexte restreint) casse l'indexation d'une table ET la comparaison,
    -- `id == nil` compris : on le teste AVANT tout autre usage (wow-forever-api, valeurs secrètes).
    if A and A.IsSecret and A.IsSecret(id) then return end
    if id == nil then return end
    -- Le cas de presque tous les objets : aucun writ ne le demande, on sort sans rien lire d'autre.
    if not W:ForItem(id) then return end
    -- La vue Profit ouvre son infobulle sur le lien de l'objet fabriqué, puis écrit SES lignes de
    -- writ (avec le prix du writ et le relevé) : ses lignes portent ce drapeau, pour ne pas doubler.
    local owner = tooltip.GetOwner and tooltip:GetOwner()
    if owner and owner.cocWritTip then return end
    local m = W:ItemMark(id)
    if m then addLines(tooltip, m) end
end

local TDP, T = _G.TooltipDataProcessor, _G.Enum and _G.Enum.TooltipDataType
if TDP and TDP.AddTooltipPostCall and T and T.Item then
    TDP.AddTooltipPostCall(T.Item, onItemTooltip)
end
