-- CraftingOrderClassic_Writs_Tooltip.lua — l'infobulle d'un OBJET qu'un Craftsman's Writ demande,
-- partout où le jeu la montre (sac, hôtel des ventes, lien du chat…) : deux lignes sous les siennes.
-- Spec : docs/specs/writs-aca.md, D10 (choix du user, 2026-11-11).
--
-- C'est l'autre bout du writ : l'objet demandé, pas le parchemin (l'infobulle du writ lui-même, T3,
-- reste à faire et pourra se brancher ici). Les lignes sont celles de la vue Profit, avec les mêmes
-- clés de locale. Aucun cadre créé, aucune ligne de chat, rien d'écrit chez Blizzard.

local COC = CraftingOrderClassic
local W = COC.Writs
if not W then return end
local L = COC.L
local A = COC.Api

local function addLines(tooltip, m)
    tooltip:AddLine(string.format(L["Demandé par un writ d'artisan (+%d de réputation)."], m.entry.rep or 0),
        1, 0.82, 0, true)
    if m.held then
        tooltip:AddLine(m.need and string.format(L["Tu portes ce writ : il t'en manque %d."], m.need)
            or L["Tu portes ce writ : ouvre-le pour savoir combien il en faut."], 1, 1, 1, true)
    else
        tooltip:AddLine(L["Les porteurs de ce writ cherchent cet objet."], 0.7, 0.7, 0.7, true)
    end
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
