-- CraftingOrderClassic_ProfWindow_Layout.lua — GÉOMÉTRIE de la vue métier (fenêtre 3 colonnes).
-- Chargé APRÈS ProfWindow.lua (la table PW doit exister), AVANT les modules de colonnes. Même contrat
-- que les Layouts d'onglets : SPEC = structure éditable, contenu dans _Recipes/_Detail/_Orders.
-- Les 3 anciens « puits » (SkinWell par colonne) deviennent le modèle UNE SURFACE + frontières
-- verticales lourdes calculées — le même langage que la fenêtre principale.
--
-- MODES : la SPEC décrit la vue PLEINE (3 colonnes). Le mode COMPACT/DOCK (colonne Commandes seule,
-- fenêtre 300 px) masque le panneau de sections et RE-PARENTE la zone « orders » sur la fenêtre ;
-- le retour en vue pleine la re-parente au panneau avec les constantes ORD_* dérivées d'ici
-- (cf. PW:_ApplyMode). Éditer la SPEC suffit : ORD_* suivent.

local COC  = CraftingOrderClassic
local Skin = COC.UI.Skin
local PW   = COC.ProfWindow

-- vTop / vBottom = LONGUEUR des barres verticales lourdes (indépendant des top/bottom des colonnes,
-- qui ne bougent que le CONTENU) : 0 = du haut au bas du marbre ; négatif sur vBottom = déborde.
-- help / helpDir : point d'accroche de l'AIDE CONTEXTUELLE (bouton « i », cf. _ProfWindow_HelpPlate.lua).
-- Tag STRUCTUREL only : quelle zone porte une bulle et de quel côté elle pointe ; le TEXTE est mappé
-- côté glue (id → L[...]). Ajouter une bulle = poser help="<id>" (+ helpDir) sur un nœud, rien d'autre.
local SPEC = {
    x1 = 4, x2 = 800, vTop = 0, vBottom = 0,
    { id = "recipes", w = 230, padR = 5, top = -4, bottom = 5,     -- colonne Recettes
        { id = "recHeader",  h = 24, bg = true, dir = "cols",   -- en-tête « Recettes » + slot bouton à droite
            { id = "recTitle", sep = false },                   -- titre dynamique (flex, cf. _SyncSortHeader)
            { id = "recHeaderTools", w = 24, sep = false } },   -- bouton « acquérables » (mode manquantes) — POSITION réglable ici
        -- Deux encarts d'aide distincts (retour user) : la barre de FILTRES (chaque icône) et la LISTE
        -- (les icônes de droite : rentabilité / demandé / source du plan) — cf. _ProfWindow_HelpPlate.
        { id = "recFilters", h = 26, dir = "cols", help = "recFilters", helpDir = "RIGHT",  -- barre d'outils en SLOTS :
            { id = "recTools",  w = 92, sep = false },   --   « 123 » + pièce d'or (Lazy Gold) + ▲ progression + carte (plan de route)
            { id = "recSearch", sep = false },           --   la recherche REMPLIT le reste
            { id = "recFilterToggles", w = 48, sep = false } }, -- filtres : sac « j'ai les matériaux » (+ palier)
        { dir = "cols", sep = false,
            { id = "recList", help = "recList", helpDir = "RIGHT" },   -- liste virtualisée
            { id = "recGutter", w = 22, sep = false } }, -- gouttière scrollbar
    },
    { id = "detail",  w = 256, top = -4, bottom = 0,     -- colonne du milieu
        help = "detail", helpDir = "UP",
        { id = "detBody" },                              -- détail de la recette + réactifs + info
        { id = "detFoot", h = 34, bg = true },           -- pied : Qté + Créer tout + Créer
    },
    { id = "orders",  top = 0, bottom = 2,               -- commandes du métier
        help = "orders", helpDir = "LEFT",
        { id = "ordBody" },                              -- liste des commandes / carte sélectionnée
        { id = "ordFoot", h = 22, bg = true },           -- pied : en attente · acceptées · sourdine
    },
}

-- LARGEUR DE FENÊTRE DÉRIVÉE DE x2 : le panneau de sections est en retrait de 4 (gauche) + 6 (droite)
-- dans la fenêtre → agrandir x2 agrandit VRAIMENT la fenêtre (sinon la colonne flex déborderait du
-- marbre). C'est ici que la vue métier se règle en largeur ; la hauteur reste PW.FRAME_H (ProfWindow).
PW.FRAME_W = SPEC.x2

-- Zones porteuses d'aide contextuelle, extraites de la SPEC (id + direction de bulle). Consommé par
-- _ProfWindow_HelpPlate.lua, qui mappe chaque id vers son texte localisé. Skin.CollectHelp vient du kit.
PW.helpNodes = Skin.CollectHelp(SPEC)

-- Constantes du mode plein pour la zone Commandes (restauration après compact/dock) — DÉRIVÉES.
PW.ORD_X      = SPEC.x1 + SPEC[1].w + SPEC[2].w
PW.ORD_W      = (SPEC.x2 - SPEC.x1) - SPEC[1].w - SPEC[2].w
PW.ORD_TOP    = SPEC[3].top
PW.ORD_BOTTOM = SPEC[3].bottom

-- Panneau hôte des sections : couvre le marbre de la fenêtre (mêmes marges que l'inset natif),
-- sous la bande d'en-tête (titre + contrôles, qui restent du chrome).
function PW:_BuildSections(f)
    local panel = CreateFrame("Frame", nil, f)
    panel:SetPoint("TOPLEFT", 4, -60); panel:SetPoint("BOTTOMRIGHT", -6, 2)
    self.secPanel = panel
    self.pwSec = Skin.MakeSections(panel, SPEC)
end

-- Frame d'une zone de la vue métier (parent + repère d'ancrage de son contenu).
function PW:Sec(id)
    return self.pwSec and self.pwSec[id]
end
