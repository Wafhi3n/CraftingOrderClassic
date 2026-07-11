-- CraftingOrderClassic_RecipeCats_Alchemy.lua — sous-catégories de l'ALCHIMIE (données, éditées à la
-- main). Voir _RecipeCats.lua pour le contrat ; en résumé :
--   * on liste des itemID (l'objet PRODUIT par la recette), jamais des noms — les noms sont localisés ;
--   * l'ordre des itemID dans un groupe est LIBRE : le tri se fait tout seul par niveau de métier
--     (learnedAt), du plus haut au plus bas — la potion de mana majeure passe devant la mineure ;
--   * l'ordre des GROUPES ci-dessous EST l'ordre d'affichage des sous-en-têtes ;
--   * un objet peut être listé dans PLUSIEURS groupes — c'est même le cas courant : une potion de
--     rajeunissement rend vie ET mana, un élixir de force brute donne force ET endurance. La recette
--     apparaît alors sous chaque en-tête concerné (système d'étiquettes, pas de partition) ;
--   * un objet absent de ces listes n'est pas perdu : il tombe dans « Divers » de sa section. C'est
--     le cas des recettes saisonnières (SoD), volontairement non classées ici.
-- Ajouter une sous-catégorie = ajouter un groupe + sa clé dans les 3 overlays de locale.

local COC = CraftingOrderClassic
if not (COC and COC.RecipeCats) then return end

COC.RecipeCats:Register("Alchemy", {
    -- Les potions de rajeunissement (2456, 18253) rendent vie ET mana → volontairement dans LES DEUX
    -- groupes ci-dessous : un artisan les cherchera sous l'un comme sous l'autre.
    { name = "Potions de soin",
      items = { 118, 858, 929, 1710, 3928, 13446, 4596, 2456, 18253, 9144, 215162 } },

    { name = "Potions de mana",
      items = { 2455, 3385, 3827, 6149, 13443, 13444, 20007, 2456, 18253, 9144, 215162 } },

    { name = "Flacons",
      items = { 13506, 13510, 13511, 13512, 13513 } },

    { name = "Élixirs de force",
      items = { 2454, 3391, 6662, 9206, 13453 } },

    { name = "Élixirs d'agilité",
      items = { 2457, 3390, 8949, 9187, 13452 } },

    -- 13453 (Force brute) donne force + endurance ; 13447 (Sages) intelligence + esprit.
    { name = "Élixirs d'endurance",
      items = { 2458, 3825, 13453 } },

    { name = "Élixirs de défense",
      items = { 5997, 3389, 8951, 13445, 13455, 3387 } },

    { name = "Élixirs d'esprit",
      items = { 3383, 9179, 13447 } },

    { name = "Élixirs de puissance des sorts",
      items = { 9155, 13454, 6373, 21546, 17708, 9264, 217398, 222952, 215162 } },

    { name = "Élixirs de puissance d'attaque",
      items = { 9224, 221024, 215162 } },

    { name = "Élixirs de vision",
      items = { 3828, 9154, 9233, 9197, 10592 } },

    { name = "Potions de protection",
      items = { 3384, 9036, 3386, 6048, 6049, 6050, 6051, 6052,
                13456, 13457, 13458, 13459, 13461, 9088 } },

    { name = "Potions de combat",
      items = { 5631, 5633, 13442, 20008, 4623, 19931 } },

    -- Régénération dans la durée : sang de troll (vie) et sang de mage (mana — donc aussi listé en mana).
    { name = "Potions de régénération",
      items = { 3382, 3388, 3826, 20004, 20007 } },

    { name = "Potions utilitaires",
      items = { 2459, 6372, 3823, 9172, 12190, 20002, 9030, 13462,
                5996, 18294, 9061, 5634 } },

    -- Les huiles sont pour partie des consommables (Huile d'ombre) et pour partie des composants
    -- (Huile de bouche-noire) : le groupe apparaît donc sous DEUX sections. C'est le comportement
    -- attendu — chaque en-tête est unique par couple (section, sous-catégorie).
    { name = "Huiles",
      items = { 3824, 3829, 8956, 6370, 6371, 13423 } },

    { name = "Transmutations",
      items = { 3577, 6037, 12360, 7068, 7076, 7078, 7080, 7082, 12803, 12808 } },
})
