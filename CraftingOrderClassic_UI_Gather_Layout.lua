-- CraftingOrderClassic_UI_Gather_Layout.lua — GÉOMÉTRIE de l'onglet « Récolte » : la SPEC (structure
-- éditable, cf. l'onglet Commande qui a VALIDÉ le modèle 2026-07-12) + les métriques dérivées.
-- Chargé AVANT _UI_Gather.lua (cf. les 3 .toc). Même contrat que _UI_Post_Layout.lua :
--   · la SPEC déclare la STRUCTURE (zones, tailles, pads) — le CONTENU vit dans les builders ;
--   · pad/padL/padR/padT/padB réglables par nœud ; un écart = spacer explicite `{ h = n, sep = false }` ;
--   · les listes LISENT la largeur de leur zone (GetWidth au build) → régler la SPEC suffit.
-- Miroir de l'onglet Commande : mêmes colonnes (gauche 333 / droite), mêmes ids quand la zone joue le
-- même rôle (filters/srch, detail/ItemSelected, price, scope) — on apprend UNE grammaire, pas deux.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin

-- Spécificités Récolte vs Commande :
--   · verPills : rangée dédiée aux pills d'extension (visibles seulement pour « Élémentaire » —
--     la bande reste vide sinon, comme l'ancienne rangée fixe) ;
--   · detail = en-tête (icône+nom+métier) / rangée quantité+stacks / texte d'info (flex) ;
--   · gatherers = la liste des récolteurs (ligne « toute la liste » épinglée + scroll).
local PRICE_H = 54   -- hauteur de la zone « prix proposé » (centrage vertical, cf. UI.GATHER)
local SPEC = {
    x1 = 0, x2 = 848, vBottom = 18,
    { id = "left", w = 333, top = -63, bottom = 20,
      { id = "filters", h = 34, bg = true, dir = "cols",
        { id = "srch" } },
      { id = "verPills", h = 22, sep = false },
      { dir = "cols", sep = false,
        { id = "resources" },
        { id = "resGutter", w = 22, sep = false } } },
    { top = -63, bottom = 20,
      { id = "detail", h = 160, padL = 5, padR = 5,
        { id = "ItemSelected", h = 46, dir = "cols",
          { id = "resIcon",  w = 50 },
          { id = "resText",  sep = false } },
        { id = "qtyRow", h = 26, dir = "cols",
          { id = "qtyHdr" },
          { id = "qtyCtl", w = 150, sep = false } },
        { id = "info", sep = false } },
      { id = "price", h = PRICE_H, major = true, padL = 10 },
      { id = "scope", h = 36, major = true, bg = true, padL = 10, padT = 4 },
      { id = "gatherers", padL = 10 } },
}

-- Métriques dérivées (mêmes rôles que UI.POST) : PAD marge intérieure · LEFT_W largeur du flyout ·
-- PRICE_H centrage de la rangée prix · LIST_W / WIDE_W = REPLIS seulement (les zones se mesurent).
local PAD, GUTTER = 0, 22
UI.GATHER = {
    PAD     = PAD,
    LEFT_W  = SPEC[1].w - 3,
    LIST_W  = SPEC[1].w - (GUTTER + 6) - 2 * PAD,
    WIDE_W  = (SPEC.x2 - SPEC.x1) - SPEC[1].w - GUTTER - 2 * PAD,
    PRICE_H = PRICE_H,
}

function UI:_BuildGatherSections(panel)
    self.gatherSec = Skin.MakeSections(panel, SPEC)
end

-- Frame d'une zone de l'onglet Récolte (parent + repère d'ancrage de son contenu).
function UI:GatherSec(id)
    return self.gatherSec and self.gatherSec[id]
end
