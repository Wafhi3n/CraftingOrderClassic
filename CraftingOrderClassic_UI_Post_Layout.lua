-- CraftingOrderClassic_UI_Post_Layout.lua — GÉOMÉTRIE de l'onglet « Commande » : colonnes, zones,
-- séparateurs. Chargé AVANT _UI_Post.lua (cf. les 3 .toc) : les autres fichiers de l'onglet lisent
-- `UI.POST` au chargement et se parentent aux zones via `UI:PostSec(id)`.
--
-- PRINCIPE (refactor 2026-07-12) : le contenu d'une zone est ENFANT de sa zone, en offsets RELATIFS
-- (« PAD sous le bord ») — plus de coordonnées absolues de panneau recopiées entre fichiers. Déplacer /
-- redimensionner une section = éditer UNE hauteur dans COLUMNS ci-dessous, rien d'autre.
--
-- MODÈLE VISUEL (3ᵉ passe, la bonne — cf. liste d'Amis, pointée par le user) : UNE SEULE SURFACE, le
-- marbre `f.Inset` que MakeWindow fournit déjà, et des FILETS fins gravés aux jointures — PAS un puits
-- par section. Historique payé :
--   · 1ʳᵉ passe, un inset par section accolés → les bordures NineSlice ont une épaisseur, deux blocs
--     voisins = deux bordures dos à dos, du jeu partout ;
--   · 2ᵉ passe, deux puits (un par colonne) → mieux, mais encore des doubles bordures aux frontières
--     et l'ornement DialogBox-Divider trop massif en interne ;
--   · 3ᵉ passe : zéro inset ajouté, filets `Skin.MakeDivider`/`MakeDividerV` (l'art de la liste
--     d'Amis) sur les jointures CALCULÉES. Le jeu est impossible par construction : une jointure n'est
--     pas un espace entre deux cadres, c'est une ligne posée sur un bord partagé.
-- `Skin.MakeInset` reste la bonne brique pour des blocs FRANCHEMENT séparés (modèle « Canaux ») —
-- simplement pas pour des sections jointives.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin

-- Métriques UI.POST (définies plus bas, dérivées de la SPEC) : PAD (marge intérieure) · LEFT_W
-- (largeur du flyout de métier) · PRICE_H (centrage de la rangée commission) · LIST_W / WIDE_W =
-- REPLIS seulement — depuis la passe 2026-07-12, chaque liste LIT LA LARGEUR DE SA ZONE
-- (`sec:GetWidth()` au build) : régler un pad/une gouttière dans la SPEC suffit, le Lua suit.

-- L'ARBRE de l'onglet (croquis user 2026-07-12) — la nav bar (①) est la rangée d'onglets native, hors
-- panneau. Chaque nœud n'a que sa taille SÉMANTIQUE (h/w ; sans taille = flex) ; empilement,
-- séparateurs (jointures fines, frontières lourdes en T, débords) et fonds de bande : tout est fait
-- par `Skin.MakeSections` (kit). Les 3 BLOCS : ② colonne gauche · ③ plan+prix · ④ ciblage — d'où la
-- frontière verticale entre colonnes et `major` sur scope (frontière ③|④).
-- Sous-blocs de la colonne gauche (2ᵉ croquis) : filtres (UNE ligne, fond de bande grise) puis
-- liste + GOUTTIÈRE dédiée à la scrollbar (la barre ne flotte plus sur les lignes).
-- Hauteurs : detail = titre + en-tête + ~7 réactifs · price = commission + repère de prix ·
-- scope = la rangée portée + « Diffuser à tous ».
-- vBottom = 18 : la fenêtre porte désormais sa BARRE D'ACTIONS native (MakeWindow buttonBar), le
-- marbre s'arrête à f+26 = panneau+18 — la frontière verticale s'arrête à cette couture, elle ne
-- traverse pas la barre. Les bas de colonnes s'alignent au-dessus (20/64).
-- La bande de filtres contient des SLOTS de composants (idée user, SPEC 2026-07-12) : `dir = "cols"`,
-- un slot par contrôle — le contenu s'y ancre en LEFT et se retrouve CENTRÉ VERTICALEMENT tout seul
-- (c'était impossible proprement avec des offsets TOPLEFT). `srch` est le flex : dans un `cols`, la
-- somme des `w` fixes doit rester < largeur du conteneur, et le slot SANS `w` absorbe le reste (lui
-- redonner un `w` faisait déborder la rangée : 100+96+124+44 = 364 > 333). Recherche plus large =
-- réduire les `w` voisins ou élargir `left`. `sep = false` sur les slots : pas de filet entre eux.
-- RÉGLAGES D'ESPACEMENT dans la SPEC (demande user 2026-07-12) :
--   · padding : `pad = n` sur un nœud (surcharges par côté `padL/padR/padT/padB`) — le contenu et les
--     sous-nœuds reculent du bord, la bande grise et les filets restent sur le rect plein ;
--   · margin  : PAS de propriété — un écart entre sections se déclare en spacer EXPLICITE
--     `{ h = 8, sep = false }` (visible dans l'arbre, pas de jeu caché).
-- La SPEC déclare la STRUCTURE (géométrie, zones) ; le CONTENU (textes, widgets, `L[...]`) reste dans
-- les builders qui se parentent aux slots — `string=`/`type=` de l'essai user n'étaient pas des
-- propriétés du générateur, et `L` n'existe même pas dans ce fichier (crash au chargement).
local PRICE_H = 54   -- hauteur de la zone « commission » (réutilisée pour le centrage vertical, cf. UI.POST)
-- help / helpDir : accroches de l'AIDE CONTEXTUELLE (bouton « i », dispatch par onglet dans
-- _UI_HelpPlate.lua). Tag STRUCTUREL only (le TEXTE est mappé côté glue). Directions : colonne gauche
-- → RIGHT ; colonne droite (empilée) → LEFT.
local SPEC = {
    x1 = 0, x2 = 848, vBottom = 18,
    { id = "left", w = 333, top = -63, bottom = 20,
      { id = "filters", h = 34, bg = true, dir = "cols", help = "filters", helpDir = "RIGHT",
        { id = "srch" },
        { id = "qualityDropDown", w = 96,  sep = false },
        { id = "reagents",        w = 124, sep = false },
        { id = "AH_Filter",       w = 44,  sep = false } },
      -- 2e rangée de filtres : le sélecteur de STAT, seul. La 1re est pleine (96+124+44 de largeurs
      -- fixes ne laissent que ~69 px à la recherche) et les noms de stats sont longs (« Score de
      -- critique »), d'où une rangée à eux. Coût assumé : 34 px de hauteur de liste.
      { id = "statFilter", h = 30, bg = true, dir = "cols", sep = false,
        { id = "statDropDown" } },   -- outils Lazy Gold (tri + « 123 »)
      -- sep=false : la bande grise des filtres SE distingue déjà par sa teinte → pas de filet fin en
      -- plus (il créait un « jeu » visible entre la bande et la liste, signalé par le user).
      { dir = "cols", sep = false,
        { id = "plans", help = "plans", helpDir = "RIGHT" },
        { id = "plansGutter", w = 22, sep = false} }},
    { top = -63, bottom = 20,
      -- Sous-zones de detail (SPEC user) : en-tête du plan / liste des réactifs — la jointure fine
      -- entre les deux est posée par le générateur (le filet dessiné à la main dans _BuildPostDetail
      -- a été retiré). `reagentsList` et non « Reagents » : le slot de filtre « reagents » existe déjà,
      -- deux ids à une majuscule près = bug silencieux garanti.
      -- Détail « JSONifié » (demande user) : chaque morceau est une sous-zone paddable.
      -- ItemSelected (en-tête, 46 px) = cols{ icône+cadre doré · texte nom/niveau · pill JE FOURNIS }.
      -- reagentsList = rows{ en-tête réactifs · corps (le scroll) }, à côté de sa gouttière scrollbar.
      -- sep=false partout : pas de filet entre les slots d'un en-tête (la bande/le cadre suffisent).
      { id = "detail", h = 210, padL = 5, padR = 5,
        { id = "ItemSelected", h = 46, dir = "cols", help = "ItemSelected", helpDir = "LEFT",
          { id = "craftIcon",   w = 50 },
          { id = "craftText",   sep = false },
          { id = "providePill", w = 90, sep = false } },
        -- (ColReagentlist GARDE son séparateur d'entrée : le filet fin ItemSelected│réactifs, comme la
        --  ligne sous le nom dans la vue métier — ne pas remettre sep=false ici.)
        { id = "ColReagentlist", dir = "cols",
          { id = "reagentsList", dir = "rows", help = "reagentsList", helpDir = "LEFT",
            { id = "reagHeader", h = 22 },
            { id = "reagBody",   sep = false } },
          { id = "reagentsGutter", w = 22, sep = false } } },

      -- major sur price (choix user) : la jointure detail|prix passe en barre LOURDE — l'hypothèse
      -- 3-blocs d'origine ne mettait du lourd qu'à scope (③|④) ; à juger sur capture.
      { id = "price",  h = PRICE_H, major = true , padL = 10, help = "price", helpDir = "LEFT" },
      { id = "scope",  h = 36, major = true , bg = true , padL = 10 , padT = 4, help = "scope", helpDir = "LEFT"},
      { id = "artisans" , padL = 10, help = "artisans", helpDir = "LEFT" } },
}

-- Métriques DÉRIVÉES de la SPEC (une seule source de vérité : éditer la SPEC suffit, plus de largeurs
-- recopiées à la main qui divergent). GUTTER = la gouttière scrollbar déclarée ci-dessus.
-- PRICE_H exposé pour que _BuildPostPrice CENTRE sa rangée verticalement sans re-coder « 54 » (demande
-- user : centrer le bloc prix) — le builder calcule -(PRICE_H − hRangée)/2.
local PAD, GUTTER = 0, 22
UI.POST = {
    PAD     = PAD,
    LEFT_W  = SPEC[1].w - 3,   -- largeur du flyout de choix de métier
    -- REPLIS de largeur uniquement (jamais utilisés tant que les zones se mesurent normalement) :
    LIST_W  = SPEC[1].w - (GUTTER + 6) - 2 * PAD,
    WIDE_W  = (SPEC.x2 - SPEC.x1) - SPEC[1].w - GUTTER - 2 * PAD,
    PRICE_H = PRICE_H,
}

-- Zones porteuses d'aide contextuelle, extraites de la SPEC (cf. _UI_HelpPlate.lua, dispatch onglet).
UI.POST.helpNodes = Skin.CollectHelp(SPEC)

function UI:_BuildPostSections(panel)
    self.postSec = Skin.MakeSections(panel, SPEC)
end

-- Frame d'une zone (parent + repère d'ancrage de son contenu).
function UI:PostSec(id)
    return self.postSec and self.postSec[id]
end
