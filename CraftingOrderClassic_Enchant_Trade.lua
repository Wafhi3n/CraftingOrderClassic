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

-- ------------------------------------------------------------------
-- « Ses composants désignent quoi ? » (T5)
-- ------------------------------------------------------------------

-- Ce qu'il pose désigne-t-il cette recette ? Deux conditions, et les deux comptent :
--   · TOUT ce qu'il a posé sert à la recette — s'il pose un éclat en plus, il vise autre chose ;
--   · chaque réactif est couvert par CE QU'IL POSE, jamais par mes sacs : on lit SON intention, pas
--     ma capacité à fabriquer (sinon toutes mes recettes « faisables » remonteraient).
-- Rend "exact" quand les quantités tombent JUSTE, "couvre" quand il en pose plus que nécessaire, et
-- false sinon. La nuance décide de tout : deux poussières posées couvrent aussi l'enchant qui n'en
-- demande qu'une, et sans elle la colonne dirait « plusieurs » alors que l'intention est claire.
-- Un réactif dont on ne sait pas lire l'objet fait échouer la reconnaissance : mieux vaut ne rien
-- dire que nommer un enchant au hasard.
function ET.OfferMatches(e, offer)
    local reags = COC.Craft:Reagents(e.index)
    if #reags == 0 then return false end
    local need = {}
    for _, r in ipairs(reags) do
        local id = r.link and tonumber(r.link:match("|Hitem:(%d+)"))
        if not id then return false end
        need[id] = (need[id] or 0) + (r.need or 0)
    end
    local posed = false
    for id in pairs(offer) do
        if not need[id] then return false end
        posed = true
    end
    if not posed then return false end
    local exact = true
    for id, n in pairs(need) do
        local given = offer[id] or 0
        if given < n then return false end
        if given > n then exact = false end
    end
    return exact and "exact" or "couvre"
end

-- Les enchants que son offre désigne, parmi `crafts` (les MIENS, applicables à la pièce posée).
-- Rend une LISTE : deux recettes peuvent demander exactement les mêmes réactifs, et en nommer une
-- au hasard serait une fausse précision — l'appelant dira « plusieurs » plutôt que de choisir.
function ET.GuessFromOffer(crafts, offer)
    offer = offer or ET.PartnerOffer()
    local exact, covers = {}, {}
    if not next(offer) then return exact end
    for _, e in ipairs(crafts or {}) do
        local how = ET.OfferMatches(e, offer)
        if how == "exact" then exact[#exact + 1] = e
        elseif how == "couvre" then covers[#covers + 1] = e end
    end
    -- Le JUSTE prime : s'il pose la quantité exacte d'une recette, c'est celle-là qu'il demande,
    -- même si ce qu'il pose couvre aussi des recettes plus modestes.
    return (#exact > 0) and exact or covers
end

-- Signature de l'offre, pour ne recalculer que si la table a changé (la déduction relit toutes mes
-- recettes : la refaire à chaque rafraîchissement de la colonne coûterait cher pour rien).
function ET.OfferKey(offer)
    local ids = {}
    for id in pairs(offer or {}) do ids[#ids + 1] = id end
    table.sort(ids)
    local parts = {}
    for i, id in ipairs(ids) do parts[i] = id .. "x" .. offer[id] end
    return table.concat(parts, ",")
end
