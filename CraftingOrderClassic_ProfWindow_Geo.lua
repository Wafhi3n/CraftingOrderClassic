-- CraftingOrderClassic_ProfWindow_Geo.lua — `/co geo` : le RELEVÉ de la colonne, en pixels écran,
-- écrit dans la SavedVariable pour être relu HORS DU JEU.
--
-- POURQUOI CE FICHIER EXISTE. Toute la mise au point de la colonne greffée s'est faite en calculant
-- sur des captures d'écran : « les trois languettes tiennent-elles ? », « le bouton d'aide touche-t-il
-- la croix native ? ». Ces questions-là ne sont pas des questions de goût — ce sont des mesures, et
-- les faire juger à l'œil, puis recopier à la main, est une perte de temps pour tout le monde. Le
-- relevé part donc sur le DISQUE (`COC.db.geo`), seul canal qu'un addon peut écrire ; la sortie
-- chat n'est qu'un confort de contrôle immédiat.
--
-- ⚠️ La SavedVariable n'est écrite qu'au `/reload` ou à la déconnexion. Le relevé vit donc en
-- mémoire jusque-là : ouvrir un métier, `/co geo`, PUIS `/reload`.
--
-- ⚠️ TOUT EST RAMENÉ EN PIXELS ÉCRAN (× GetEffectiveScale). C'est LE point qui rend ce relevé
-- utilisable : `GetLeft()` rend une coordonnée dans l'espace du frame, et nos rangées d'onglets sont
-- justement RÉDUITES À L'ÉCHELLE quand elles ne tiennent pas (cf. _PlaceOrdTabs). Comparer deux
-- rectangles sans normaliser, c'est comparer des centimètres à des pouces — le même piège que
-- l'écart des onglets latéraux mesuré dans les unités du cadre natif (cf. _ProfWindow_Camelot).
--
-- Un relevé est une MESURE DATÉE, pas un état courant : chaque passage écrase le précédent ET
-- réécrit son horodatage, pour qu'un vieux relevé ne puisse jamais se faire passer pour le dernier.
--
-- Sortie brute et technique, jamais localisée : c'est un instrument, pas du chrome.

local COC = CraftingOrderClassic
local PW  = COC.ProfWindow

-- Rectangle en pixels ÉCRAN. nil quand le frame n'a pas (encore) de position résolue — ce qui est
-- une réponse en soi : un frame sans ancre valide ne s'affiche nulle part.
local function rect(f)
    if not (f and f.GetLeft and f:GetLeft()) then return nil end
    local s = (f.GetEffectiveScale and f:GetEffectiveScale()) or 1
    return { l = math.floor(f:GetLeft() * s + 0.5),   r = math.floor(f:GetRight() * s + 0.5),
             t = math.floor(f:GetTop() * s + 0.5),    b = math.floor(f:GetBottom() * s + 0.5),
             shown = (f.IsShown and f:IsShown()) and true or false,
             lvl = (f.GetFrameLevel and f:GetFrameLevel()) or -1 }
end

-- Recouvrement de deux rectangles, en pixels. nil = ils ne se touchent pas.
local function clash(a, b)
    if not (a and b and a.shown and b.shown) then return nil end
    local w = math.min(a.r, b.r) - math.max(a.l, b.l)
    local h = math.min(a.t, b.t) - math.max(a.b, b.b)
    if w <= 0 or h <= 0 then return nil end
    return w, h
end

-- Enveloppe d'une rangée d'onglets : on n'a pas besoin de leur ORDRE (les tables `buttons` sont
-- indexées par id), seulement des bords extrêmes — et du compte de ceux réellement affichés.
local function barRect(bar)
    if not (bar and bar.buttons) then return nil end
    local env = nil
    for _, b in pairs(bar.buttons) do
        local r = rect(b)
        if r and r.shown then
            if not env then env = r; env.n = 1
            else
                env.l = math.min(env.l, r.l); env.r = math.max(env.r, r.r)
                env.t = math.max(env.t, r.t); env.b = math.min(env.b, r.b)
                env.lvl = math.min(env.lvl, r.lvl); env.n = env.n + 1
            end
        end
    end
    return env
end

-- La croix native de la fenêtre hôte : son nom varie selon le gabarit de portrait, on sonde.
local function hostClose(native)
    if not native then return nil end
    return native.CloseButton or native.ClosePanelButton
        or (native.TitleContainer and native.TitleContainer.CloseButton)
end

-- Le piège « affichée, complète, bien placée... et invisible » : la colonne ENTERRÉE sous un enfant
-- opaque de l'hôte (relevé du 2026-09-19, cadre=1 mais BookPage=100). Se mesure, ne se devine pas.
local function burial(native, f)
    if not (native and f and native.GetChildren) then return nil end
    local top, name = -1, "?"
    for _, c in ipairs({ native:GetChildren() }) do
        local lv = (c.GetFrameLevel and c:GetFrameLevel()) or -1
        if lv > top and c ~= f then top, name = lv, (c.GetName and c:GetName()) or "(anonyme)" end
    end
    return { mine = (f.GetFrameLevel and f:GetFrameLevel()) or -1, top = top, name = name }
end

-- Les collisions qui nous ont réellement coûté un aller-retour. Chacune est NOMMÉE : un relevé qui
-- dit « chevauchement » sans dire lequel ne fait que déplacer la question.
local function clashes(snap)
    local F, B = snap.frames, snap.bars
    local watch = {
        { "aide x vues",      F.aide,     B.vues },
        { "aide x croix",     F.aide,     F.croix },
        { "vues x relation",  B.vues,     B.relation },
        { "vues x liste",     B.vues,     F.liste },
        { "relation x tri",   B.relation, F.tri },
        { "relation x liste", B.relation, F.liste },
    }
    local out = {}
    for _, p in ipairs(watch) do
        local w, h = clash(p[2], p[3])
        if w then out[#out + 1] = { p[1], w, h } end
    end
    return out
end

-- Le FOND de la page native. `CraftingPage` porte une texture d'atlas posée en `useAtlasSize` :
-- elle ne s'étire donc PAS quand on élargit le cadre, et s'arrête net là où la fenêtre d'origine
-- finissait. C'est ce bord-là qu'on voit dans la bande ajoutée. On le MESURE, avec le nom de son
-- atlas, plutôt que de le déduire d'une capture : sans ça on ne sait ni où prolonger, ni avec quoi.
local function pageArt(native)
    local page = native and native.CraftingPage
    if not (page and page.GetRegions) then return nil end
    for _, r in ipairs({ page:GetRegions() }) do
        if r.GetObjectType and r:GetObjectType() == "Texture"
           and r.GetDrawLayer and r:GetDrawLayer() == "BACKGROUND" then
            local box = rect(r)
            if box then
                box.atlas = (r.GetAtlas and r:GetAtlas()) or (r.GetTexture and r:GetTexture()) or "?"
                return box
            end
        end
    end
    return nil
end

-- LES MARGES, et le seul étalon qui vaille : celles de BLIZZARD. « Est-ce que l'écart à droite est
-- bien ? » n'a pas de réponse dans l'absolu — elle vaut par comparaison avec ce que la fenêtre
-- native s'accorde à elle-même pour son propre contenu (`CraftingPage`). On rend donc les nôtres ET
-- les siennes, côte à côte : l'écart entre les deux colonnes de chiffres EST le verdict.
local function margins(snap)
    local col, host = snap.frames.colonne, snap.frames.hote
    if not (col and host) then return nil end
    local m = {
        droite_nous = host.r - col.r,
        haut_nous   = host.t - col.t,
        bas_nous    = col.b - host.b,
    }
    -- L'étalon, c'est le FOND de la page native — pas `CraftingPage`, qui couvre tout le cadre bord
    -- à bord (mesuré 2026-09-20) et rendrait « marges Blizzard = 0 0 0 0 » : un chiffre faux qui a
    -- l'air d'un fait. Le fond, lui, est posé en taille fixe : ses écarts au cadre SONT ceux que
    -- Blizzard s'accorde, et la gouttière à notre gauche se mesure depuis son bord droit.
    local art = snap.frames.fondNatif
    if art then
        m.gauche_nous  = col.l - art.r
        m.gauche_natif = art.l - host.l
        -- Après élargissement, « l'écart à droite » de l'art natif n'est plus une marge : c'est la
        -- BANDE que la greffe a ajoutée et que l'art ne couvre pas. On la nomme pour ce qu'elle est.
        m.bande_sans_art = host.r - art.r
        m.haut_natif   = host.t - art.t
        m.bas_natif    = art.b - host.b
    end
    return m
end

-- LE RELEVÉ. Une seule collecte, deux consommateurs (chat + disque) : sans ça les deux finissent par
-- diverger, et c'est toujours celui qu'on ne regarde pas qui ment.
local function snapshot(self)
    local f, native = self.frame, _G.ProfessionsFrame
    local snap = {
        at   = (date and date("%Y-%m-%d %H:%M:%S")) or "?",
        prof = tostring(self.profKey),
        mode = { docked = self.docked and true or false, compact = self._compact and true or false,
                 chrome = tostring(f._cocStripped or "complet"),
                 view = tostring(self.dockView or "orders"), band = self:_TabBand() },
        frames = {
            colonne = rect(f),                   hote  = rect(native),
            page    = rect(native and native.CraftingPage),
            croix   = rect(hostClose(native)),   aide  = rect(self.helpBtn),
            ordBody = rect(self:Sec("ordBody")), liste = rect(self.ordScroll),
            tri     = rect(self.ordLevelBtn),    route = rect(self.routePanel),
            ordFoot = rect(self:Sec("ordFoot")),
            manquantes = rect(self.missPanel),
            -- La CARTE d'une commande sélectionnée, et sa croix de retour : la croix passait sous
            -- le fond opaque du puits. Un niveau se mesure, il ne se suppose pas.
            fondNatif  = pageArt(native),
            -- Notre prolongement d'art : présent = le fichier _Camelot_PageArt est bien chargé.
            fondAjoute = rect(native and native.CraftingPage and native.CraftingPage._cocPageFill),
            selecteur  = rect(self.ordRelDD),
            carte      = rect(self.ordCards and self.ordCards[1]),
            croixCarte = rect(self.ordCards and self.ordCards[1] and self.ordCards[1].closeSel),
        },
        bars = { vues = barRect(self.viewTabs), relation = barRect(self.ordRelTabs) },
        enterree = burial(native, f),
    }
    snap.collisions = clashes(snap)
    snap.marges = margins(snap)
    -- Marge à droite : négative = la rangée DÉBORDE de la colonne et se fera rogner par la bordure
    -- native — le défaut vécu au 1er essai du POC (« Incoming » coupé).
    local col = snap.frames.colonne
    for _, bar in pairs(snap.bars) do
        if col and bar then bar.marge = col.r - bar.r end
    end
    return snap
end

local function out(fmt, ...)
    print("|cFF33DD88COC|r geo  " .. ((select("#", ...) > 0) and string.format(fmt, ...) or fmt))
end

local FRAME_ORDER = { "colonne", "hote", "page", "croix", "aide", "ordBody", "liste", "tri",
                      "ordFoot", "route", "manquantes", "fondNatif", "fondAjoute", "selecteur",
                      "carte", "croixCarte" }

local function render(snap)
    local m = snap.mode
    out("%s - %s | docked=%s compact=%s chrome=%s vue=%s bande=%d",
        snap.at, snap.prof, tostring(m.docked), tostring(m.compact), m.chrome, m.view, m.band)
    for _, id in ipairs(FRAME_ORDER) do
        local r = snap.frames[id]
        if r then out("%-11s x %d..%d  y %d..%d  (%dx%d) lvl=%d %s", id, r.l, r.r, r.b, r.t,
                      r.r - r.l, r.t - r.b, r.lvl, r.shown and "shown" or "HIDDEN")
        else out("%-11s ABSENT (ni ancre ni position)", id) end
    end
    for _, id in ipairs({ "vues", "relation" }) do
        local b = snap.bars[id]
        if b then out("rangee %-9s x %d..%d  y %d..%d  (%d onglets, lvl>=%d, marge droite %d)",
                      id, b.l, b.r, b.b, b.t, b.n, b.lvl, b.marge or 0)
        else out("rangee %-9s aucune languette affichee", id) end
    end
    local e = snap.enterree
    if e then out("%s", (e.mine <= e.top)
        and string.format("  !! ENTERREE : colonne lvl=%d sous %s lvl=%d", e.mine, e.name, e.top)
        or  string.format("  ok, colonne lvl=%d au-dessus de %s lvl=%d", e.mine, e.name, e.top)) end
    local art = snap.frames.fondNatif
    if art then out("fond natif   : s'arrete a x=%d  (atlas %s)", art.r, tostring(art.atlas)) end
    local mg = snap.marges
    if mg then
        out("marges nous  : g=%s d=%d h=%d b=%d", tostring(mg.gauche_nous or "?"),
            mg.droite_nous, mg.haut_nous, mg.bas_nous)
        if mg.gauche_natif then
            out("marges blizz : g=%d d=%d h=%d b=%d",
                mg.gauche_natif, mg.droite_natif, mg.haut_natif, mg.bas_natif)
        end
    end
    for _, c in ipairs(snap.collisions) do out("  !! %s : %d x %d px", c[1], c[2], c[3]) end
    if #snap.collisions == 0 then out("  ok, aucune des 6 paires surveillees ne se chevauche") end
end

-- `/co geo` — relève, affiche, et POSE sur le disque. Sans fenêtre de métier, on le dit et on
-- s'arrête : mesurer une colonne non posée rendrait des nombres faux plutôt qu'une absence de
-- nombres, et un faux nombre se recopie aussi bien qu'un vrai.
function PW:_GeoDump()
    local f = self.frame
    if not (f and f:IsShown()) then
        return out("colonne non affichee - ouvre un metier d'abord.")
    end
    local snap = snapshot(self)
    render(snap)
    if COC.db then
        -- UN RELEVÉ PAR VUE, côte à côte. Les trois vues ne se mesurent pas dans la même passe, et
        -- la SavedVariable ne part sur le disque qu'au `/reload` : les laisser s'écraser aurait
        -- imposé trois cycles de rechargement pour lire trois vues.
        local g = COC.db.geo
        if type(g) ~= "table" or g.frames then g = {} end   -- ancien format à plat : on repart propre
        g[snap.mode.view] = snap
        COC.db.geo = g
        out("releve '%s' ecrit - change de vue et relance, puis /reload pour tout poser sur le disque.",
            snap.mode.view)
    end
    return snap
end
