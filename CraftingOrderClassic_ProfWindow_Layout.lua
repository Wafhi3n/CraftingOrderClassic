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
            { id = "recTools",  w = 92, sep = false },   --   « 123 » + pièce d'or (Auctionator) + ▲ progression + carte (plan de route)
            { id = "recSearch", sep = false },           --   la recherche REMPLIT le reste
            { id = "recFilterToggles", w = 48, sep = false } }, -- filtres : sac « j'ai les matériaux » (+ palier)
        -- Rangée du filtre par STAT. Une rangée à elle seule parce que la colonne ne fait que 230 px :
        -- recTools (92) + recFilterToggles (48) ne laissent déjà que ~90 px à la recherche, un
        -- sélecteur de plus sur la même ligne ne serait pas lisible.
        { id = "statFilter", h = 28, bg = true, dir = "cols", sep = false,
            { id = "recStatDD" } },
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

-- BANDE D'EN-TÊTE, au-dessus de la rangée d'onglets : la place du chrome (titre, portrait,
-- contrôles) sur une vraie fenêtre. ENCASTRÉE dans la fenêtre native de Forever, la colonne n'a
-- plus de chrome DU TOUT (cf. stripChrome) : cette bande n'était plus qu'un trou de 28 px, et tout
-- le bloc d'onglets y flottait sans rien au-dessus de lui (relevé sur capture en jeu, 2026-09-20).
-- `frame._cocStripped` est posé par la greffe (_ProfWindow_Camelot, hideChrome) : "full" = chrome
-- entièrement retiré (encastré), "side" = portrait seul (accolé — le titre, lui, reste). C'est le
-- SEUL témoin fiable de « cette colonne a-t-elle encore un en-tête » : le mode ne suffit pas, car
-- l'accolé est greffé ET titré.
PW.TAB_BAND  = 28    -- vide réservé au chrome au-dessus des languettes
PW.TAB_ROW_H = 32    -- hauteur d'une languette native (Api.TabTemplate)

-- =========================================================================
-- RÉGLAGES AU PIXEL — la table à éditer pour pinailler, sans toucher à la logique.
-- =========================================================================
-- Tout est en UNITÉS DE CADRE, pas en pixels écran : le client applique ensuite son échelle
-- d'interface (≈ 0,71 sur le poste de test — une valeur de 28 ici sort à 20 px à l'écran).
-- `/co geo` mesure le résultat en pixels écran et l'écrit dans la SavedVariable : éditer une valeur
-- ici puis relancer le relevé donne l'aller-retour complet sans avoir à juger à l'œil.
--
-- Pourquoi une table Lua et pas du JSON : **un addon WoW ne peut lire aucun fichier**. Il n'y a pas
-- d'E/S disque, et seuls les `.lua`/`.xml` déclarés dans le `.toc` sont chargés — par le client,
-- comme du code. Un fichier de réglages JSON devrait donc être converti en Lua au build pour
-- finir… exactement ici. La table EST le format de réglage ; le JSON n'ajouterait qu'une étape.
PW.TUNE = {
    -- La colonne greffée dans la fenêtre native de Forever (cf. _ProfWindow_Camelot).
    graftGap      = 6,    -- respiration entre le contenu natif et notre bande
    graftTopInset = 26,   -- retrait sous la barre de titre native
    graftBotInset = 34,   -- retrait au-dessus de la rangée « Create All / Create »
    -- La colonne elle-même.
    colPad        = 14,   -- marge latérale de la zone Commandes dans le cadre
    -- La ligne d'en-tête de la liste (sélecteur de relation + bouton de tri).
    selTop        = 15,    -- écart AU-DESSUS du sélecteur
    selLeft       = 4,    -- écart à gauche
    selHeight     = 22,   -- hauteur du sélecteur
    selReserveR   = 34,   -- place gardée à droite pour le bouton de tri
    listBand      = 26,   -- bande réservée au-dessus de la liste
    viewTop       = 8,    -- marge en haut des vues Plan de route / Manquantes
    -- Prolonger le fond de page natif dans la bande ajoutée (false = bande laissée nue).
    pageFill      = true,
}

-- `PW.PAD` est posé dans ProfWindow.lua, qui se charge AVANT ce fichier : on l'aligne ici pour que
-- la table reste la seule source. Deux constantes qui disent la même chose finissent toujours par
-- ne plus la dire.
PW.PAD = PW.TUNE.colPad

function PW:_ChromeStripped()
    return (self.frame and self.frame._cocStripped == "full") and true or false
end

function PW:_TabBand()
    return self:_ChromeStripped() and 4 or PW.TAB_BAND
end

-- Y de la rangée d'onglets, et Y du contenu qui commence sous elle. Dérivés tous les deux : régler
-- la bande suffit, rien d'autre n'est à retoucher.
function PW:_TabTop()  return -self:_TabBand() end
function PW:_BodyTop() return -(self:_TabBand() + PW.TAB_ROW_H - PW.ORD_TOP) end

-- Panneau hôte des sections : couvre le marbre de la fenêtre (mêmes marges que l'inset natif),
-- sous la bande d'en-tête (titre + contrôles, qui restent du chrome).
function PW:_BuildSections(f)
    local panel = CreateFrame("Frame", nil, f)
    panel:SetPoint("TOPLEFT", 4, -60); panel:SetPoint("BOTTOMRIGHT", -6, 2)
    self.secPanel = panel
    self.pwSec = Skin.MakeSections(panel, SPEC)
end

-- ⚠️ Les zones de la SPEC sont dimensionnées en ABSOLU au build (`SetWidth`, cf. MakeSections) :
-- elles gardent la largeur de la VUE PLEINE et ne suivent pas la colonne qui rétrécit. Relevé du
-- 2026-09-20 : `ordBody` débordait de 28 px à droite de la colonne, et le bouton de tri, ancré à
-- SON bord droit, se retrouvait purement et simplement HORS du cadre.
--
-- Recalage par LARGEUR, pas par ancre. Un point RIGHT porte aussi un centre en Y : ajouté à
-- `ordFoot`, qui est ancré BOTTOMLEFT, il sur-déterminait sa position verticale et la faisait
-- dépendre de l'ordre de résolution des ancres. Ça « marchait », ce qui est précisément le genre de
-- chose qui cesse de marcher un jour, ailleurs, sans qu'on sache pourquoi.
--
-- Et la colonne elle-même suit la largeur RÉELLE du cadre, pas le 300 nominal : la greffe l'élargit
-- après coup pour que la rangée de vues tienne.
function PW:_SyncOrdWidth()
    if not self.ordCol then return end
    if self._compact then
        self.ordCol:SetWidth((self.frame:GetWidth() or 300) - 2 * self.PAD)
    end
    local w = self.ordCol:GetWidth() or 0
    if w <= 0 then return end
    for _, id in ipairs({ "ordBody", "ordFoot" }) do
        local z = self:Sec(id)
        if z then z:SetWidth(w) end
    end
end

-- Frame d'une zone de la vue métier (parent + repère d'ancrage de son contenu).
function PW:Sec(id)
    return self.pwSec and self.pwSec[id]
end
