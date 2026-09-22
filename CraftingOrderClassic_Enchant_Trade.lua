-- CraftingOrderClassic_Enchant_Trade.lua — « ses composants désignent quel enchant ? »
--
-- Ce fichier portait un PANNEAU flottant accroché à droite de la fenêtre d'échange : la liste de mes
-- enchants applicables à la pièce posée, classée par pertinence. Le panneau est SUPPRIMÉ (T4, spec
-- docs/specs/enchant-echange-forever.md) — sur Forever, la fenêtre de métier se dessine exactement
-- par-dessus, et la liste native filtrée (T2) le remplace avantageusement : c'est celle de Blizzard,
-- avec sa recherche, ses catégories et son bouton de craft.
--
-- Ce qui RESTE ici est ce que la liste native ne sait pas faire : lire ce que le partenaire a posé
-- sur la table d'échange et dire quel enchant ses composants désignent. La colonne en mode Échange
-- s'en servira pour son indice (T5).
--
-- ⚠️ Les mats posés dans l'échange ne sont PAS encore dans mes sacs → `numAvailable` vaut 0 tant que
-- l'échange n'est pas validé : trier sur lui SEUL ne peut donc pas remonter la bonne recette (retour
-- terrain : mats de Fiery Weapon échangés, l'enchant n'était même pas suggéré).

local COC = CraftingOrderClassic

local ET = {}
COC.EnchantTrade = ET

-- Réactifs posés par le partenaire dans les emplacements ÉCHANGEABLES (1..MAX_TRADABLE_ITEMS) —
-- l'emplacement d'enchantement porte l'OBJET, jamais les mats. Rend { [itemID] = quantité }.
-- ⚠️ PAS de `GetTradeTargetItemInfo and GetTradeTargetItemInfo(i)` en assignation multiple : `and`
-- TRONQUE le multi-retour à UNE valeur → la quantité serait perdue.
function ET.PartnerOffer()
    local offer = {}
    if not (_G.TradeFrame and TradeFrame:IsShown() and GetTradeTargetItemLink) then return offer end
    for i = 1, (_G.MAX_TRADABLE_ITEMS or 6) do
        local link = GetTradeTargetItemLink(i)
        local id = link and tonumber(link:match("|Hitem:(%d+)"))
        if id then
            local qty = 1
            if GetTradeTargetItemInfo then
                local _, _, n = GetTradeTargetItemInfo(i)   -- name, texture, numItems, …
                qty = n or 1
            end
            offer[id] = (offer[id] or 0) + qty
        end
    end
    return offer
end

-- Pertinence d'un enchant face à ce que le partenaire pose sur la table :
--   3 = il fournit des mats ET la recette est couverte (sacs + offre) → c'est CE qu'il demande ;
--   2 = il fournit des mats, mais il en manque encore ;
--   1 = faisable avec MES sacs seuls ;  0 = le reste.
function ET.OfferRank(e, offer)
    local reags = COC.Craft:Reagents(e.index)
    if #reags == 0 then return ((e.numAvailable or 0) > 0) and 1 or 0 end
    local hit, covered = false, true
    for _, r in ipairs(reags) do
        local id = r.link and tonumber(r.link:match("|Hitem:(%d+)"))
        local given = (id and offer[id]) or 0
        if given > 0 then hit = true end
        if (r.have or 0) + given < (r.need or 0) then covered = false end
    end
    if hit then return covered and 3 or 2 end
    return covered and 1 or 0
end

-- Classe MES enchants (tels que rendus par Enchant:CraftsForEquipLoc, qui a déjà posé `_lvl`) :
-- pertinence d'abord, puis rang de métier décroissant (meilleure variante), puis nom. Trie sur
-- place et pose `_rank` sur chaque entrée.
function ET.Rank(crafts)
    local offer = ET.PartnerOffer()
    for _, e in ipairs(crafts) do e._rank = ET.OfferRank(e, offer) end
    table.sort(crafts, function(a, b)
        if a._rank ~= b._rank then return a._rank > b._rank end
        if (a._lvl or 0) ~= (b._lvl or 0) then return (a._lvl or 0) > (b._lvl or 0) end
        return (a.name or "") < (b.name or "")
    end)
    return crafts
end
