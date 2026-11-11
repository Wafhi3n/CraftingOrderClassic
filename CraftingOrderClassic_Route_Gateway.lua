-- CraftingOrderClassic_Route_Gateway.lua — « passerelles » de palier du Plan de route : quoi faire
-- une fois AU plafond entraîné (livre de rang curaté, formateur, ou vrai maximum de la saveur).
-- Sorti de CraftingOrderClassic_Route.lua le 2026-10-02 pour faire place au coût net : ce bloc ne
-- touche pas au calcul de la route, il ne fait que lire les données chargées. Chargé APRÈS lui
-- (.toc) : il s'accroche à COC.Route. Lecteurs : _ProfWindow_Route et _Route_Supply, sous garde nil.

local COC   = CraftingOrderClassic
local Route = COC.Route
if not Route then return end

-- « Passerelles » de palier : comment débloquer le rang MAX suivant une fois AU plafond entraîné.
-- La plupart des métiers entraînent le rang suivant au FORMATEUR (message générique) ; Premiers soins
-- fait exception — un LIVRE de rang acheté chez un PNJ, ABSENT de la liste de recettes (il ne produit
-- aucun objet) donc JAMAIS dans la route. Clé = profKey canonique CraftLink ("First Aid", avec
-- l'espace) → rang-plafond. item = livre à apprendre, name = repli si l'objet n'est pas en cache
-- client, vendors = PNJ des DEUX factions (MTSL filtre l'autre camp), price = repli prix vendeur,
-- nextCap = plafond entraînable après apprentissage. Étendre = ajouter une entrée (aucune autre modif).
local GATEWAY = {
    ["First Aid"] = {
        [300] = { item = 22012, name = "Master First Aid - Doctor in the House",
                  vendors = { 18991, 18990 }, price = 50000, nextCap = 375 },
    },
}

-- Vrai s'il existe, dans les données CHARGÉES (couche du client), au moins une recette apprise à un
-- rang STRICTEMENT supérieur à `rank` : le palier suivant existe donc RÉELLEMENT ici. Sur Era/Vanilla
-- (First Aid plafonne à 300, aucune recette au-dessus) → faux → on n'incite jamais à un palier fantôme.
function Route:HasHigherTier(profKey, rank)
    if not (profKey and rank) then return false end
    local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    if not (lib and lib.GetRecipes and lib.RecipeLearnedAt) then return false end
    for _, sid in ipairs(lib:GetRecipes(profKey) or {}) do
        local at = lib:RecipeLearnedAt(profKey, sid)
        if at and at > rank then return true end
    end
    return false
end

-- Passerelle CURATÉE pour (métier, rang-plafond) — { item, name, vendors, price, nextCap } — ou nil
-- si aucune, ou si le palier supérieur n'existe pas dans la saveur chargée (cohérence via HasHigherTier :
-- jamais promettre un livre pour un palier absent du client). Consommée par la fenêtre Plan de route.
function Route:Gateway(profKey, rank)
    local g = profKey and rank and GATEWAY[profKey] and GATEWAY[profKey][rank]
    if not g then return nil end
    if not self:HasHigherTier(profKey, rank) then return nil end
    return g
end

-- Prochain plafond de palier STANDARD strictement au-dessus de `rank` — repli pour l'en-tête d'un
-- palier entraîné au FORMATEUR (pas de nextCap curaté). Le +5 racial draeneï pousse le plafond
-- effectif à 230 : le palier VISÉ reste le suivant (300). nil si déjà au sommet des paliers connus.
function Route:NextTierCap(rank)
    if not rank then return nil end
    for _, cap in ipairs(Route.CAPS or {}) do if rank < cap then return cap end end
    return nil
end
