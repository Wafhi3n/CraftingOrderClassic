-- CraftingOrderClassic_UI_Skin_Sections.lua — kit de chrome natif, volet SECTIONS : comment on
-- découpe l'intérieur d'une fenêtre en blocs et en zones. Même table `Skin` que _UI_Skin.lua /
-- _UI_Skin_Native.lua (découpé de Native pour l'anti-monolithe : les appelants ne voient pas la
-- frontière entre fichiers).
--
-- LE MODÈLE BLIZZARD, en deux échelles (les deux observées dans la source, cf. commentaires) :
--   · BLOCS FRANCHEMENT SÉPARÉS → un `MakeInset` chacun (fenêtre des Canaux : deux insets, un gap).
--     La bordure NineSlice d'un inset a une ÉPAISSEUR : deux insets accolés = deux bordures dos à dos,
--     un jeu inévitable — ne JAMAIS coller deux insets (payé sur l'onglet Commande, 1ʳᵉ passe).
--   · SECTIONS SOLIDAIRES d'un même bloc → UNE surface, et des FILETS fins à l'intérieur
--     (`MakeDivider`/`MakeDividerV`) — le modèle de la liste d'Amis, pointé par le user.

local COC  = CraftingOrderClassic
local Skin = COC.UI.Skin

-- =========================================================================
-- Bloc de section encastré (« InsetFrameTemplate ») — le puits marbré des fenêtres Blizzard.
-- =========================================================================
-- MÊME template que le panneau de contenu de MakeWindow (`f.Inset`) : fond marbre tuilé + bordure
-- NineSlice, qui s'adapte à toute taille. Blizzard l'IMBRIQUE dans une même fenêtre pour délimiter des
-- blocs distincts — la fenêtre des Canaux crée `LeftInset` (liste) et `RightInset` (roster) côte à côte
-- (ChannelFrame.xml:58 et :72). Aucun art à produire.
-- PARENTER LE CONTENU AU BLOC est le bon réflexe (et ce que fait Blizzard) : le template porte
-- `useParentLevel="true"`, le bloc reste donc au NIVEAU de son parent → ses enfants gardent exactement
-- le niveau qu'ils auraient eu en enfants directs du panneau, et le marbre (couche BACKGROUND) passe
-- sous eux. Bénéfice : les offsets du contenu deviennent RELATIFS au bloc, donc le contenu ne peut plus
-- dériver de sa bordure, et déplacer une section ne demande plus de re-piquer chaque coordonnée.
-- Cf. _UI_Post_Layout.lua (la géométrie déclarative de l'onglet Commande).
-- Rect en coordonnées du PANNEAU (comme tout le layout COC) : (x1,y1) coin haut-gauche, (x2,y2) coin
-- bas-droit, y négatifs. `y2 = nil` → le bloc descend jusqu'au BAS du panneau (marge `opts.bottom`).
-- `opts.thin` = variante `InsetFrameTemplate3` (bordure fine « champ de saisie », fond sombre) pour un
-- bloc discret plutôt qu'un vrai puits marbré.
function Skin.MakeInset(parent, x1, y1, x2, y2, opts)
    opts = opts or {}
    local f = CreateFrame("Frame", nil, parent,
        opts.thin and "InsetFrameTemplate3" or "InsetFrameTemplate")
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", x1, y1)
    if y2 then f:SetPoint("BOTTOMRIGHT", parent, "TOPLEFT", x2, y2)
    else f:SetPoint("BOTTOMRIGHT", parent, "BOTTOMLEFT", x2, opts.bottom or 0) end
    return f
end

-- =========================================================================
-- Séparateurs — DEUX GRAISSES, une hiérarchie (calée sur les fenêtres Blizzard, tranchée par le user) :
-- =========================================================================
--   · LOURD (`heavy`) : l'ornement `UI-DialogBox-Divider` (256×32, la barre sculptée de la fiche de
--     Réputation / du Calendrier) → frontières entre BLOCS de la fenêtre (les grandes régions).
--   · FIN (défaut)    : le filet gravé de la liste d'Amis (`UI-FriendsFrame-OnlineDivider`,
--     FriendsFrameFriendDividerTemplate — FriendsFrame.xml:36, 298×16) → jointures INTERNES d'un bloc.
-- ⚠️ Un fichier d'art peut MENTIR sur son étendue peinte (padding transparent de calage power-of-2).
-- MESURÉ (PIL, alpha bbox + profil d'épaisseur par colonne) : `UI-DialogBox-Divider` (256×32) ne peint
-- que u 0..0.754 / v 0..0.5 — rendu SANS recadrage, le trait s'arrêtait aux ¾ de la longueur demandée,
-- pommeau flottant (vécu, capture user). D'où `u1`/`v1` : le TexCoord recadre sur la zone PEINTE, qui
-- couvre alors 100 % de la géométrie demandée. Le filet fin garde ses fondus latéraux (voulus) → pas
-- de recadrage. Profil du lourd : POMMEAUX aux colonnes 0..3 et 189..192, FÛT (8 px d'épaisseur
-- constante) entre les deux → `shaft0/shaft1` permettent de COUPER un pommeau (jonction en T : le bout
-- coupé bute dans une barre croisée au lieu d'y superposer son pommeau).
-- Les deux arts portent leur trait au centre de la zone peinte → toujours CENTRÉS sur la jointure :
-- on passe l'ordonnée (ou l'abscisse) du bord partagé, sans recalcul.
local THIN  = { tex = "Interface\\FriendsFrame\\UI-FriendsFrame-OnlineDivider", th = 16 }
local HEAVY = { tex = "Interface\\DialogFrame\\UI-DialogBox-Divider",           th = 16,
                u1 = 0.754, v1 = 0.5, shaft0 = 8 / 256, shaft1 = 184 / 256 }

-- opts (art lourd seulement) : `capL = false` / `capR = false` = couper le pommeau de ce bout
-- (le TexCoord démarre/finit dans le fût) — pour un bout qui BUTE dans une barre croisée.
function Skin.MakeDivider(parent, x1, x2, y, heavy, opts)
    local d = heavy and HEAVY or THIN
    local u0, u1 = 0, d.u1 or 1
    if opts and opts.capL == false then u0 = d.shaft0 end
    if opts and opts.capR == false then u1 = d.shaft1 end
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetTexture(d.tex)
    t:SetTexCoord(u0, u1, 0, d.v1 or 1)
    t:SetSize(x2 - x1, d.th)
    t:SetPoint("TOPLEFT", x1, y + d.th / 2)
    return t
end

-- Variante VERTICALE (séparation de deux colonnes). Il n'existe pas d'art natif vertical → on PIVOTE
-- l'art horizontal de 90° via la forme à 8 arguments de SetTexCoord (UL, LL, UR, LR : le bord gauche
-- de l'art devient le haut ; même recadrage sur la zone peinte). Centré sur `x` ; `top` s'ancre au
-- bord HAUT du parent (y négatif), `bottom` à son bord BAS (y positif).
function Skin.MakeDividerV(parent, x, top, bottom, heavy)
    local d = heavy and HEAVY or THIN
    local u1, v1 = d.u1 or 1, d.v1 or 1
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetTexture(d.tex)
    t:SetTexCoord(0, v1, u1, v1, 0, 0, u1, 0)
    t:SetWidth(d.th)
    t:SetPoint("TOP", parent, "TOPLEFT", x, top)
    t:SetPoint("BOTTOM", parent, "BOTTOMLEFT", x, bottom)
    return t
end

-- Fond « groove » derrière la scrollbar d'un ScrollFrame (`UIPanelScrollFrameTemplate`) : sans lui, le
-- rail de la barre laisse voir le marbre nu (le fond « manque », demande user). Texture sombre parentée
-- à la BARRE elle-même, couche BACKGROUND → le curseur et les flèches (niveau supérieur) restent
-- au-dessus. Les 14 px rognés en haut/bas dégagent les boutons ▲▼. `scrollName` = le nom GLOBAL du
-- ScrollFrame (la barre est `<nom>ScrollBar`, convention du template). Réutilisable (toute liste COC).
function Skin.ScrollTrack(scrollName)
    local sb = _G[scrollName .. "ScrollBar"]
    if not sb then return end
    local t = sb:CreateTexture(nil, "BACKGROUND")
    t:SetPoint("TOPLEFT", 0, 14); t:SetPoint("BOTTOMRIGHT", 0, -14)
    t:SetColorTexture(0, 0, 0, 0.30)
    return t
end

-- =========================================================================
-- GÉNÉRATEUR de sections : ARBRE déclaratif de blocs/sous-blocs (rows/cols récursifs).
-- =========================================================================
-- LA porte d'entrée pour découper un panneau au look natif (modèle demandé par le user, croquis
-- 2026-07-12 : « on travaille par bloc/template, et on templatise chaque section ») : un NŒUD découpe
-- son rectangle en enfants empilés (`dir = "rows"`, défaut) ou juxtaposés (`dir = "cols"`), et chaque
-- enfant peut se re-découper pareil — ex. la colonne « liste de plans » = rows(filtres, cols(liste,
-- gouttière scrollbar)). Le générateur pose TOUT : empilement, séparateurs de jointure, fonds de
-- bande. AUCUN Y de contenu, aucun séparateur manuel.
-- Champs d'un nœud : `id` (exposé dans le résultat → parent du contenu) · `h`/`w` (taille sur l'axe
-- du parent ; UN enfant sans taille par conteneur = flex, prend le reste) · `dir` · `bg` (fond de
-- bande grise) · `major` (sa jointure d'entrée est une frontière de BLOC → barre lourde) ·
-- `sep = false` (pas de séparateur à sa jointure) · `pad` (+ `padL/padR/padT/padB`, marge intérieure,
-- cf. padOf ci-dessous) · enfants dans la partie tableau du nœud.
-- Racine (spec) : cols de la fenêtre — { x1, x2, sepInset (retrait latéral des filets fins, déf. 8),
-- bleed, vTop, vBottom } + colonnes { w (une
-- flex), top, bottom } ; frontières verticales lourdes ENTRE colonnes, dessinées en dernier (elles
-- recouvrent les bouts coupés → jonctions en T nettes). Une barre `major` court d'une frontière
-- (bout coupé qui bute dedans) à un bord de fenêtre (pommeau + débord `bleed` sous le chrome).
-- Rend { [id] = frame } : chaque section est le PARENT de son contenu (offsets relatifs).
local BAND = { 0.80, 0.80, 0.85, 0.08 }   -- fond « bande grise » d'un sous-bloc (bg = true)

-- `pad` d'un nœud (+ surcharges par côté `padL/padR/padT/padB`) : marge INTÉRIEURE réglable dans la
-- SPEC (demande user : « choisir les paddings directement dans l'objet »). Sémantique CSS : le fond
-- de bande et les jointures restent sur le rect PLEIN du nœud ; la frame ENREGISTRÉE (où le contenu
-- se parente, et où les enfants s'empilent) est le rect rétréci. Pas de `margin` : un écart ENTRE
-- sections se déclare en spacer explicite `{ h = 8, sep = false }` (visible dans l'arbre) — un
-- retrait caché recréerait le « jeu » que le modèle une-surface a justement éliminé.
local function padOf(node)
    local p = node.pad or 0
    return node.padL or p, node.padR or p, node.padT or p, node.padB or p
end

local function secFrame(parent, node, secs)
    local f = CreateFrame("Frame", nil, parent)
    if node.bg then
        local t = f:CreateTexture(nil, "BACKGROUND")
        t:SetAllPoints(); t:SetColorTexture(BAND[1], BAND[2], BAND[3], BAND[4])
    end
    local inner, pL, pR, pT, pB = f, padOf(node)
    if pL ~= 0 or pR ~= 0 or pT ~= 0 or pB ~= 0 then
        inner = CreateFrame("Frame", nil, f)
        inner:SetPoint("TOPLEFT", pL, -pT); inner:SetPoint("BOTTOMRIGHT", -pR, pB)
    end
    if node.id then secs[node.id] = inner end
    return f, inner
end

local buildNode   -- récursion mutuelle avec buildRows/buildCols

-- Empile les enfants VERTICALEMENT. Le flex est ancré haut ET bas (les enfants d'après s'ancrent au
-- BAS du conteneur) → tout suit si le conteneur change de hauteur. UN seul flex par pile (la hauteur
-- du conteneur n'est pas connue au build : impossible de partager le reste) — un 2ᵉ enfant sans `h`
-- est traité en h=0 plutôt que de planter le chargement. La jointure d'un enfant est posée sur SON
-- bord haut (elle le suit, où qu'il soit ancré).
local function buildRows(cf, node, w, ctx, secs)
    local flexI
    for i, c in ipairs(node) do if not c.h then flexI = i end end
    local above, below = 0, 0
    for i = (flexI or #node) + 1, #node do below = below + (node[i].h or 0) end
    for i, c in ipairs(node) do
        local f, inner = secFrame(cf, c, secs)
        f:SetWidth(w)
        if not flexI or i < flexI then
            f:SetPoint("TOPLEFT", 0, -above); f:SetHeight(c.h or 0); above = above + (c.h or 0)
        elseif i == flexI then
            f:SetPoint("TOPLEFT", 0, -above)
            f:SetPoint("BOTTOMLEFT", cf, "BOTTOMLEFT", 0, below)
        else
            below = below - (c.h or 0)
            f:SetPoint("BOTTOMLEFT", cf, "BOTTOMLEFT", 0, below); f:SetHeight(c.h or 0)
        end
        if i > 1 and c.sep ~= false then
            if c.major then
                Skin.MakeDivider(f, ctx.fL and 0 or -ctx.bleed, w + (ctx.fR and 0 or ctx.bleed),
                    0, true, { capL = not ctx.fL, capR = not ctx.fR })
            else
                Skin.MakeDivider(f, ctx.sepInset, w - ctx.sepInset, 0)
            end
        end
        local pL, pR = padOf(c)
        buildNode(inner, c, w - pL - pR, ctx, secs)
    end
end

-- Juxtapose les enfants HORIZONTALEMENT. Ici la largeur du conteneur EST connue → PLUSIEURS enfants
-- sans `w` sont permis : ils se PARTAGENT le reste à parts égales (comme des colonnes flex). Chaque
-- enfant prend toute la hauteur du conteneur ; la jointure (filet vertical) est posée sur son bord
-- gauche. C'est le conteneur des SLOTS de widgets (ex. rangée de filtres : chaque contrôle a son slot,
-- ancré en LEFT dedans → centré verticalement par construction).
local function buildCols(cf, node, w, ctx, secs)
    local fixed, nflex = 0, 0
    for _, c in ipairs(node) do
        if c.w then fixed = fixed + c.w else nflex = nflex + 1 end
    end
    local flexW = nflex > 0 and (w - fixed) / nflex or 0
    local x = 0
    for i, c in ipairs(node) do
        local cw = c.w or flexW
        local f, inner = secFrame(cf, c, secs)
        f:SetWidth(cw)
        f:SetPoint("TOPLEFT", x, 0)
        f:SetPoint("BOTTOMLEFT", cf, "BOTTOMLEFT", x, 0)
        if i > 1 and c.sep ~= false then Skin.MakeDividerV(f, 0, 0, 0, c.major) end
        local pL, pR = padOf(c)
        buildNode(inner, c, cw - pL - pR, ctx, secs)
        x = x + cw
    end
end

buildNode = function(f, node, w, ctx, secs)
    if #node == 0 then return end
    if node.dir == "cols" then buildCols(f, node, w, ctx, secs)
    else buildRows(f, node, w, ctx, secs) end
end

function Skin.MakeSections(panel, spec)
    local sepInset, bleed = spec.sepInset or 8, spec.bleed or 10
    local secs, frontiers = {}, {}
    local fixed = 0
    for _, c in ipairs(spec) do fixed = fixed + (c.w or 0) end
    local x = spec.x1
    for i, c in ipairs(spec) do
        local cw = c.w or (spec.x2 - spec.x1 - fixed)
        local f, inner = secFrame(panel, c, secs)
        f:SetWidth(cw)
        f:SetPoint("TOPLEFT", x, c.top or 0)
        f:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", x, c.bottom or 0)
        local pL, pR = padOf(c)
        buildNode(inner, c, cw - pL - pR,
            { sepInset = sepInset, bleed = bleed, fL = i > 1, fR = i < #spec }, secs)
        x = x + cw
        if i < #spec then frontiers[#frontiers + 1] = x end
    end
    for _, fx in ipairs(frontiers) do
        Skin.MakeDividerV(panel, fx, spec.vTop or -60, spec.vBottom or -8, true)
    end
    return secs
end
