-- CraftingOrderClassic_RecipeCats_Enchanting.lua — sous-catégories de l'ENCHANTEMENT.
--
-- PARTICULARITÉ : les essences, poussières et éclats ne sont PAS des recettes — on ne les fabrique
-- pas, on les obtient en DÉSENCHANTANT un objet. Ils n'ont donc pas de spellID ni de `learnedAt`.
-- Conséquences (cf. le contrat dans _RecipeCats.lua) :
--   * ils sont commandables (on demande à un enchanteur de désenchanter pour nous), donc l'onglet
--     Commande les laisse passer malgré l'absence de spellID (cf. RefreshPostPlans) ;
--   * sans learnedAt, le tri automatique n'a rien à lire → c'est l'ORDRE DÉCLARÉ ci-dessous qui fait
--     foi. Ils sont donc rangés à la main, du plus haut niveau au plus bas.
-- Les noms en commentaire viennent de la table `disenchant` de CraftLink (Data/Vanilla/Enchanting.lua)
-- et ne servent QU'À LA RELECTURE : seuls les itemID comptent, le client localise.

local COC = CraftingOrderClassic
if not (COC and COC.RecipeCats) then return end

COC.RecipeCats:Register("Enchanting", {
    { name = "Éclats",
      items = {
        20725,  -- Nexus Crystal
        14344,  -- Large Brilliant Shard
        14343,  -- Small Brilliant Shard
        11178,  -- Large Radiant Shard
        11177,  -- Small Radiant Shard
        11139,  -- Large Glowing Shard
        11138,  -- Small Glowing Shard
        11084,  -- Large Glimmering Shard
        10978,  -- Small Glimmering Shard
      } },

    { name = "Essences",
      items = {
        16203,  -- Greater Eternal Essence
        16202,  -- Lesser Eternal Essence
        11175,  -- Greater Nether Essence
        11174,  -- Lesser Nether Essence
        11135,  -- Greater Mystic Essence
        11134,  -- Lesser Mystic Essence
        11082,  -- Greater Astral Essence
        10998,  -- Lesser Astral Essence
        10939,  -- Greater Magic Essence
        10938,  -- Lesser Magic Essence
      } },

    { name = "Poussières",
      items = {
        16204,  -- Illusion Dust
        11176,  -- Dream Dust
        11137,  -- Vision Dust
        11083,  -- Soul Dust
        10940,  -- Strange Dust
      } },
})
