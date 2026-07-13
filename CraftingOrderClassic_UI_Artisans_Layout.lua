-- CraftingOrderClassic_UI_Artisans_Layout.lua — GÉOMÉTRIE de l'onglet « Artisans » (annuaire social).
-- Chargé AVANT _UI_Artisans.lua (cf. les 3 .toc). Même contrat que les Layouts Commande/Récolte :
-- SPEC = structure éditable (zones, tailles, pads), contenu dans les builders, largeurs LUES sur les
-- zones. Deux colonnes : SIDEBAR (sources + ajout de joueur) · zone principale (bande de filtre
-- métier + liste des artisans avec sa gouttière de scrollbar).
-- Le panneau « En sourdine » (UI_Artisans_Muted) est un MODE de la zone liste : il se superpose aux
-- mêmes zones (profFilter/artisansList), le basculement reste piloté par _ShowMutedMode.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin

local SPEC = {
    x1 = 0, x2 = 848, vBottom = 18,
    { id = "sidebar", w = 212, top = -63, bottom = 20,
      { id = "sources" },                     -- en-tête SOURCE + boutons de filtre empilés (flex)
      { id = "addPlayer", h = 132 } },        -- cluster bas : Rafraîchir · AJOUTER UN JOUEUR · scan
    { top = -63, bottom = 20, left = 5,
      { id = "profFilter", h = 34,padL= 5, bg = true },   -- « Métier : » + pills d'icônes (bande grise)
      { dir = "cols", sep = false,
        { id = "artisansList" },
        { id = "artGutter", w = 22, sep = false } } },
}

-- Métriques : PAD marge intérieure · WIDE_W = REPLI de largeur de la liste (la zone se mesure).
local PAD, GUTTER = 0, 22
UI.ART = {
    PAD    = PAD,
    WIDE_W = (SPEC.x2 - SPEC.x1) - SPEC[1].w - GUTTER - 2 * PAD,
}

function UI:_BuildArtSections(panel)
    self.artSec = Skin.MakeSections(panel, SPEC)
end

-- Frame d'une zone de l'onglet Artisans (parent + repère d'ancrage de son contenu).
function UI:ArtSec(id)
    return self.artSec and self.artSec[id]
end
