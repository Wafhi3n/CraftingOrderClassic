-- CraftingOrderClassic_UI_MyArtisans_Layout.lua — GÉOMÉTRIE de l'onglet « Mes artisans ».
-- Chargé AVANT _UI_MyArtisans.lua (cf. les 3 .toc). Même contrat que les autres Layouts : SPEC =
-- structure éditable, contenu dans les builders, largeurs LUES sur les zones.
-- Particularité : un BANDEAU pleine largeur (opt-in de partage + vitrine) au-dessus des deux
-- colonnes → la racine est UNE colonne, et le découpage gauche│droite est un nœud `cols` interne
-- (`major = true` sur la colonne recettes = jointure verticale LOURDE, l'équivalent de la frontière).

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin

-- help / helpDir : accroches de l'AIDE CONTEXTUELLE (bouton « i », dispatch par onglet dans
-- _UI_HelpPlate.lua). Bandeau → DOWN ; colonne gauche (métiers) → RIGHT ; colonne droite (recettes) → LEFT.
local SPEC = {
    x1 = 0, x2 = 848, vBottom = 18,
    { top = -63, bottom = 20,
      { id = "shareBar", h = 36, bg = true, dir = "cols", help = "shareBar", helpDir = "DOWN",
        { id = "shareOptIn" },                       -- case « Partager mes rerolls sur le réseau »
        { id = "showcase", w = 260, sep = false } }, -- « Vitrine : » + sélecteur du perso principal
      { dir = "cols", sep = false,
        { id = "accountProfs", w = 300,              -- colonne gauche : métiers du compte
          { id = "allRealm", h = 28, help = "allRealm", helpDir = "RIGHT" },   -- bouton « Tous les plans du royaume »
          { dir = "cols", sep = false,
            { id = "profsList", help = "profsList", helpDir = "RIGHT" },
            { id = "profsGutter", w = 22, sep = false } } },
        { id = "recipesCol", major = true,padL= 5 ,           -- colonne droite : recettes du métier choisi
          { id = "recTools", h = 30, bg = true, dir = "cols", help = "recTools", helpDir = "LEFT",
            { id = "recTitle" },                     -- titre dynamique (métier · N recettes)
            { id = "recButtons", w = 230, sep = false } },   -- Manquantes + outils Lazy Gold
          { dir = "cols", sep = false,
            { id = "recList", help = "recList", helpDir = "LEFT" },
            { id = "recGutter", w = 22, sep = false } } } } },
}

-- Métriques : PAD marge intérieure · LEFT_W/WIDE_W = REPLIS (les zones se mesurent au build).
local PAD, GUTTER = 0, 22
UI.MYART = {
    PAD    = PAD,
    LEFT_W = 300 - GUTTER,
    WIDE_W = (SPEC.x2 - SPEC.x1) - 300 - GUTTER,
}

-- Zones porteuses d'aide contextuelle, extraites de la SPEC (cf. _UI_HelpPlate.lua, dispatch onglet).
UI.MYART.helpNodes = Skin.CollectHelp(SPEC)

function UI:_BuildMyArtSections(panel)
    self.myArtSec = Skin.MakeSections(panel, SPEC)
end

-- Frame d'une zone de l'onglet Mes artisans (parent + repère d'ancrage de son contenu).
function UI:MyArtSec(id)
    return self.myArtSec and self.myArtSec[id]
end
