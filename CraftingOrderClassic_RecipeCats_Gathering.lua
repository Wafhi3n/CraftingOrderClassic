-- CraftingOrderClassic_RecipeCats_Gathering.lua — sous-catégories des métiers de RÉCOLTE.
-- GÉNÉRÉ par tools/gen_gathercats.lua (source : Wowhead) — NE PAS ÉDITER À LA MAIN.
--
-- Une peau ou un minerai n'est PAS une recette : aucun `learnedAt` à lire, le tri automatique « du
-- plus haut au plus bas » n'a rien sur quoi s'appuyer. C'est donc l'ORDRE DÉCLARÉ ci-dessous qui fait
-- foi (cf. le contrat dans _RecipeCats.lua) : chaque groupe est rangé du plus haut niveau au plus bas,
-- d'après le niveau d'objet Wowhead. Les noms en commentaire ne servent QU'À LA RELECTURE — seuls les
-- itemID comptent, le client localise tout seul.
--
-- Un itemID absent de ces listes n'est pas perdu : il tombe dans « Divers » de sa section.

local COC = CraftingOrderClassic
if not (COC and COC.RecipeCats) then return end

COC.RecipeCats:Register("Skinning", {
    { name = "Peaux",
      items = {
        12731,  -- Pristine Hide of the Beast (60)
        8171,   -- Rugged Hide (50)
        8169,   -- Thick Hide (40)
        4235,   -- Heavy Hide (30)
        4232,   -- Medium Hide (20)
        783,    -- Light Hide (10)
      } },
    { name = "Cuirs",
      items = {
        33568,  -- Borean Leather (70)
        33567,  -- Borean Leather Scraps (70)
        17012,  -- Core Leather (60)
        25699,  -- Crystal Infused Leather (60)
        21887,  -- Knothide Leather (60)
        25708,  -- Thick Clefthoof Leather (60)
        8170,   -- Rugged Leather (50)
        4304,   -- Thick Leather (40)
        4234,   -- Heavy Leather (30)
        2319,   -- Medium Leather (20)
        2318,   -- Light Leather (10)
        2934,   -- Ruined Leather Scraps (5)
      } },
    { name = "Écailles",
      items = {
        38561,  -- Jormungar Scale (75)
        12607,  -- Brilliant Chromatic Scale (60)
        29539,  -- Cobra Scales (60)
        25700,  -- Fel Scales (60)
        15410,  -- Scale of Onyxia (60)
        15408,  -- Heavy Scorpid Scale (55)
        8154,   -- Scorpid Scale (45)
        5785,   -- Thick Murloc Scale (35)
        6471,   -- Perfect Deviate Scale (25)
        6470,   -- Deviate Scale (20)
        7287,   -- Red Whelp Scale (20)
        5784,   -- Slimy Murloc Scale (15)
      } },
})

COC.RecipeCats:Register("Mining", {
    { name = "Minerais",
      items = {
        36910,  -- Titanium Ore (80)
        36912,  -- Saronite Ore (75)
        36909,  -- Cobalt Ore (72)
        23425,  -- Adamantite Ore (65)
        23424,  -- Fel Iron Ore (60)
        10620,  -- Thorium Ore (50)
        3858,   -- Mithril Ore (40)
        2772,   -- Iron Ore (30)
        2771,   -- Tin Ore (20)
        2770,   -- Copper Ore (10)
      } },
})

COC.RecipeCats:Register("Herbalism", {
    { name = "Herbes",
      items = {
        36906,  -- Icethorn (80)
        36905,  -- Lichbloom (80)
        36903,  -- Adder's Tongue (77)
        39970,  -- Fire Leaf (75)
        22793,  -- Mana Thistle (75)
        22792,  -- Nightmare Vine (73)
        37921,  -- Deadnettle (72)
        36901,  -- Goldclover (72)
        36907,  -- Talandra's Rose (72)
        22791,  -- Netherbloom (70)
        22790,  -- Ancient Lichen (68)
        22787,  -- Ragveil (65)
        22786,  -- Dreaming Glory (60)
        22785,  -- Felweed (60)
        22789,  -- Terocone (60)
        13467,  -- Icecap (58)
        13466,  -- Plaguebloom (57)
        13465,  -- Mountain Silversage (56)
        13463,  -- Dreamfoil (54)
        13464,  -- Golden Sansam (52)
        8846,   -- Gromsblood (50)
        8839,   -- Blindweed (47)
        8845,   -- Ghost Mushroom (47)
        8838,   -- Sungrass (46)
        8836,   -- Arthas' Tears (44)
        8831,   -- Purple Lotus (42)
        4625,   -- Firebloom (41)
        3819,   -- Wintersbite (39)
        3358,   -- Khadgar's Whisker (37)
        3821,   -- Goldthorn (34)
        3818,   -- Fadeleaf (32)
        3357,   -- Liferoot (30)
        3369,   -- Grave Moss (24)
        3356,   -- Kingsblood (24)
        3355,   -- Wild Steelbloom (22)
        2453,   -- Bruiseweed (20)
        3820,   -- Stranglekelp (20)
        2450,   -- Briarthorn (15)
        2452,   -- Swiftthistle (15)
        785,    -- Mageroyal (10)
        2449,   -- Earthroot (5)
        2447,   -- Peacebloom (5)
        765,    -- Silverleaf (5)
      } },
})

COC.RecipeCats:Register("Fishing", {
    { name = "Poissons",
      items = {
        43572,  -- Magic Eater (80)
        43571,  -- Sewer Carp (80)
        43647,  -- Shimmering Minnow (80)
        43652,  -- Slippery Eel (80)
        43646,  -- Fountain Goldfish (75)
        41812,  -- Barrelhead Goby (70)
        41808,  -- Bonescale Snapper (70)
        41805,  -- Borean Man O' War (70)
        41800,  -- Deep Sea Monsterbelly (70)
        41807,  -- Dragonfin Angelfish (70)
        41810,  -- Fangtooth Herring (70)
        35285,  -- Giant Sunfish (70)
        41809,  -- Glacial Salmon (70)
        41814,  -- Glassfin Minnow (70)
        41802,  -- Imperial Manta Ray (70)
        41801,  -- Moonglow Cuttlefish (70)
        41806,  -- Musselback Sculpin (70)
        41813,  -- Nettlefish (70)
        41803,  -- Rockfin Grouper (70)
        33823,  -- Bloodfin Catfish (65)
        33824,  -- Crescent-Tail Skullfish (65)
        27422,  -- Barbed Gill Trout (60)
        27435,  -- Figluster's Mudfish (60)
        27439,  -- Furious Crawdad (60)
        27438,  -- Golden Darter (60)
        27437,  -- Icefin Bluefish (60)
        27425,  -- Spotted Feltail (60)
        27429,  -- Zangarian Sporefish (60)
        13888,  -- Darkclaw Lobster (55)
        13890,  -- Plated Armorfish (55)
        13889,  -- Raw Whitescale Salmon (55)
        13754,  -- Raw Glossy Mightfish (45)
        13759,  -- Raw Nightfin Snapper (45)
        13758,  -- Raw Redgill (45)
        4603,   -- Raw Spotted Yellowtail (45)
        13756,  -- Raw Summer Bass (45)
        13760,  -- Raw Sunscale Salmon (45)
        7974,   -- Zesty Clam Meat (45)
        21153,  -- Raw Greater Sagefish (40)
        8365,   -- Raw Mithril Head Trout (35)
        6362,   -- Raw Rockscale Cod (35)
        6308,   -- Raw Bristle Whisker Catfish (25)
        21071,  -- Raw Sagefish (20)
        6317,   -- Raw Loch Frenzy (15)
        6289,   -- Raw Longjaw Mud Snapper (15)
        6361,   -- Raw Rainbow Fin Albacore (15)
        6291,   -- Raw Brilliant Smallfish (5)
        6303,   -- Raw Slitherskin Mackerel (5)
        45907,  -- Mostly-eaten Bonescale Snapper (1)
      } },
})
