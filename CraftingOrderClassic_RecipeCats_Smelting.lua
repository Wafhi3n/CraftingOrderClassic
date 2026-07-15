-- CraftingOrderClassic_RecipeCats_Smelting.lua — sous-catégorie « Lingots » du Minage (facette FONTE).
--
-- Le Minage fusionne ses deux facettes dans les listes de commande : les MINERAIS bruts (récolte,
-- déclarés en « Minerais » par RecipeCats_Gathering) ET les LINGOTS de fonte (craft). Ce fichier
-- déclare le second groupe ; RC:Register APPEND (cf. _RecipeCats.lua) → le Minage porte les deux.
--
-- Contrairement aux minerais, un lingot EST une recette (learnedAt connu via itemToSpell) : le moteur
-- le trie automatiquement du plus haut palier au plus bas, donc l'ordre de la liste ci-dessous est
-- indifférent. Superset toutes saveurs (Vanilla/TBC/Wrath) : un lingot absent du client courant est
-- simplement filtré à l'affichage (Skin.ItemExists). Chargé APRÈS RecipeCats_Gathering (parité .toc).

local COC = CraftingOrderClassic
if not (COC and COC.RecipeCats) then return end

COC.RecipeCats:Register("Mining", {
    { name = "Lingots",
      items = {
        2840,   -- Copper Bar
        2841,   -- Bronze Bar
        2842,   -- Silver Bar
        3575,   -- Iron Bar
        3576,   -- Tin Bar
        3577,   -- Gold Bar
        3859,   -- Steel Bar
        3860,   -- Mithril Bar
        6037,   -- Truesilver Bar
        11371,  -- Dark Iron Bar
        12359,  -- Thorium Bar
        17771,  -- Elementium Bar
        23445,  -- Fel Iron Bar (TBC)
        23446,  -- Adamantite Bar (TBC)
        23447,  -- Eternium Bar (TBC)
        23573,  -- Khorium Bar (TBC)
        36913,  -- Saronite Bar (WotLK)
        36916,  -- Cobalt Bar (WotLK)
        37663,  -- Titansteel Bar (WotLK)
        41163,  -- Titanium Bar (WotLK)
      } },
})
