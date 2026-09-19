-- CraftingOrderClassic_UI_Skin_HelpPlate.lua — kit d'AIDE CONTEXTUELLE (le « bouton i » de retail).
-- À NE PAS confondre avec _UI_Help.lua (l'onglet « Aide », une PAGE de doc défilante qu'on lit). Ici
-- c'est l'overlay EN PLACE : un clic fige la fenêtre et pose des bulles sur ses vrais contrôles. Le jeu
-- retail a les deux ; complémentaires (bulles courtes ici, détail dans l'onglet Aide).
--
-- Même table `Skin` que les autres _UI_Skin*. Le RENDU est celui de l'aide native de retail (tuiles
-- surlignées, pastilles « i », bulles fléchées), mais ce sont NOS exemplaires des gabarits de
-- `Blizzard_HelpPlate`, pas le système lui-même : cf. « le voile, A NOUS » plus bas. Zéro asset.
--
-- LE PARI « aide sur les objets SPEC » (idée user) : `Skin.MakeSections` rend `{ [id] = frame }`, donc
-- chaque section EST une vraie frame positionnée. Au lieu de coder les coordonnées à la main (ce que
-- fait Blizzard), on TAGUE le nœud SPEC (`help = "<id>"`, `helpDir = "LEFT|RIGHT|UP|DOWN"`) et on dérive
-- la tuile du rectangle RÉEL de la frame, à l'ouverture. Le TEXTE reste du contenu (locale),
-- déclaré côté consommateur — la SPEC ne porte que le point d'accroche (cf. discipline SPEC=structure).
--
-- ⚠️ ÉCHELLES : le voile vit sur UIParent (il ne doit pas devenir l'enfant d'une fenêtre qui peut être
-- protégée, cf. la greffe de Forever) mais on lui donne l'échelle EFFECTIVE de la fenêtre : toutes ses
-- coordonnées sont alors celles de la fenêtre, quelle que soit l'échelle d'UI.

local COC  = CraftingOrderClassic
local Skin = COC.UI.Skin

-- Parcourt un arbre de SPEC (cf. MakeSections) et collecte les nœuds tagués `help`, en profondeur.
-- Rend { { id=, key=, dir= }, ... } dans l'ordre de déclaration. `key` = valeur brute de `help` (un id
-- de texte, résolu en locale par le consommateur — pas ici : la SPEC ne connaît pas COC.L).
function Skin.CollectHelp(spec)
    local out = {}
    local function walk(node)
        if node.help and node.id then
            out[#out + 1] = { id = node.id, key = node.help, dir = node.helpDir }
        end
        for _, child in ipairs(node) do walk(child) end
    end
    for _, col in ipairs(spec) do walk(col) end
    return out
end

-- Bouton rond « i », posé un peu HORS CADRE (retail). Template natif RinglessHelpPlateButtonTemplate
-- (help-i + surbrillance) ; repli défensif si absent. `onToggle` au clic. opts : size · point (ancre
-- {p, rel, relP, x, y}) · tooltip.
function Skin.MakeHelpButton(parent, onToggle, opts)
    opts = opts or {}
    local b
    local ok = pcall(function()
        b = CreateFrame("Button", nil, parent, "RinglessHelpPlateButtonTemplate")
    end)
    if not ok or not b then
        b = CreateFrame("Button", nil, parent)
        b:SetNormalTexture("Interface\\common\\help-i")
        b:SetHighlightTexture("Interface\\common\\help-i", "ADD")
    end
    b:SetSize(opts.size or 28, opts.size or 28)
    local a = opts.point or { "CENTER", parent, "TOPLEFT", 8, 6 }
    b:ClearAllPoints(); b:SetPoint(a[1], a[2], a[3], a[4], a[5])
    b:SetFrameStrata("HIGH"); b:SetFrameLevel(parent:GetFrameLevel() + 20)
    b:SetScript("OnClick", function() if onToggle then onToggle() end end)
    if opts.tooltip then
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(opts.tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", GameTooltip_Hide)
    end
    return b
end

-- ---------------------------------------------------------------- le voile, A NOUS
-- ON N'EMPRUNTE PLUS L'AIDE DE BLIZZARD : ON EN FABRIQUE NOTRE PROPRE EXEMPLAIRE. `HelpPlate.Show`
-- écrit une variable interne du module (`currentHelpInfo`). Appelé depuis un addon, il la marque à
-- notre nom pour TOUTE la session, même après `Hide`. Or Blizzard la relit à chaque fermeture du livre
-- des métiers (ProfessionsBookFrameMixin:OnHide → HelpPlate.Hide), juste avant de cacher les grilles
-- des barres d'action : en combat ce geste était refusé, et le jeu accusait COC, sans une ligne de
-- COC dans la pile. Prouvé le 2026-09-19 au labo (TaintLab, COC désactivé) : témoin = 0 blocage ;
-- un seul `HelpPlate.Show` + `Hide` = les mêmes blocages, accusés à TaintLab. Et notre aide s'ouvrait
-- d'elle-même à la 1re visite de chaque onglet (`helpSeen`) : il suffisait d'ouvrir la fenêtre.
-- RÈGLE : les GABARITS virtuels (HelpPlateTile, GlowBoxTemplate, textures HelpPlateArrow*) sont
-- permis, chaque CreateFrame fabrique un cadre à NOUS. Les SINGLETONS jamais : HelpPlate.*,
-- HelpPlateCanvas, HelpPlateTooltip. Et jamais le clavier sur le voile (il a déjà figé le joueur).

local BTN = 46   -- côté de la pastille « i » d'une tuile (gabarit HelpPlateTile)
local canvas, tip
local tiles = {}

-- Même montage que HelpPlateTooltip (Blizzard_HelpPlate.xml) : la bulle se pose du côté `dir` de la
-- pastille (`place`), la flèche sur son bord opposé (`point` sur `rel`), pointée vers la pastille
-- (`toward`). Les pointes latérales sont des pointes verticales tournées, d'où w/h inversés.
local ARROWS = {
    UP    = { point = "TOP",    rel = "BOTTOM", x = 0,  y = 3,  toward = "DOWN",  w = 53, h = 21,
              place = { "BOTTOM", "TOP", 0, 10 } },
    DOWN  = { point = "BOTTOM", rel = "TOP",    x = 0,  y = -3, toward = "UP",    w = 53, h = 21,
              place = { "TOP", "BOTTOM", 0, -10 } },
    RIGHT = { point = "RIGHT",  rel = "LEFT",   x = 3,  y = 0,  toward = "LEFT",  w = 21, h = 53,
              place = { "LEFT", "RIGHT", 10, 0 } },
    LEFT  = { point = "LEFT",   rel = "RIGHT",  x = -3, y = 0,  toward = "RIGHT", w = 21, h = 53,
              place = { "RIGHT", "LEFT", -10, 0 } },
}

-- Les pointes, taillées dans le même fichier que celles de Blizzard (coordonnées de
-- HelpPlateArrowDown et HelpPlateArrow-GlowDown, Blizzard_HelpPlate.xml) : dessinées pointe en BAS.
local PARTS = "Interface\\TalentFrame\\TalentFrame-Parts"
local ARROW_TC = { 0.78515625, 0.99218750, 0.54687500, 0.58789063 }
local GLOW_TC  = { 0.40625000, 0.66015625, 0.77343750, 0.82812500 }

-- ON N'UTILISE PAS SetClampedTextureRotation. Elle lit la taille de la texture (GetWidth) pour
-- intervertir largeur et hauteur ; or sur un cadre jamais affiché, GetWidth rend la taille CALCULEE,
-- qui vaut 0. Nos pointes latérales passaient à 0x0 et s'étalaient sur toute la bulle : deux grands
-- triangles jaunes en travers du texte (vu en jeu le 2026-09-19). Chez Blizzard ça marche parce que
-- la taille vient du XML. Ici : les 8 coordonnées sont données explicitement (coins UL, LL, UR, LR),
-- puis la taille, puis l'ancre - rien n'est relu.
local function orient(tx, c, toward)
    local l, r, t, b = c[1], c[2], c[3], c[4]
    if toward == "UP" then
        tx:SetTexCoord(l, r, b, t)                       -- retournée verticalement
    elseif toward == "RIGHT" then
        tx:SetTexCoord(r, t, l, t, r, b, l, b)           -- quart de tour : le bas passe à droite
    elseif toward == "LEFT" then
        tx:SetTexCoord(l, b, r, b, l, t, r, t)           -- quart de tour : le bas passe à gauche
    else
        tx:SetTexCoord(l, r, t, b)
    end
end

local function makeArrow(t, layer, coords, a)
    local tx = t:CreateTexture(nil, layer)
    tx:SetTexture(PARTS)
    orient(tx, coords, a.toward)
    tx:SetSize(a.w, a.h)
    tx:ClearAllPoints()
    tx:SetPoint(a.point, t, a.rel, a.x, a.y)
    tx:Hide()
    return tx
end

local function makeTip()
    local t = CreateFrame("Frame", nil, UIParent, "GlowBoxTemplate")
    t:SetSize(220, 100)
    t:SetFrameStrata("FULLSCREEN_DIALOG")
    t:Hide()
    t.Text = t:CreateFontString(nil, "OVERLAY", "GameFontHighlightLeft")
    t.Text:SetWidth(200); t.Text:SetPoint("TOPLEFT", 15, -15); t.Text:SetSpacing(4)
    t.arrows = {}
    for dir, a in pairs(ARROWS) do
        local glow = makeArrow(t, "BORDER", GLOW_TC, a)
        glow:SetBlendMode("ADD"); glow:SetAlpha(0.5)
        t.arrows[dir] = { makeArrow(t, "ARTWORK", ARROW_TC, a), glow }
    end
    return t
end

local function showTip(tile)
    tip = tip or makeTip()
    for _, pair in pairs(tip.arrows) do pair[1]:Hide(); pair[2]:Hide() end
    local dir = ARROWS[tile._dir] and tile._dir or "RIGHT"
    local p = ARROWS[dir].place
    tip:ClearAllPoints()
    tip:SetPoint(p[1], tile.Button, p[2], p[3], p[4])
    tip.arrows[dir][1]:Show(); tip.arrows[dir][2]:Show()
    tip.Text:SetText(tile._text or "")
    tip:SetHeight(tip.Text:GetHeight() + 30)
    tip:Show()
end

-- Pose le voile sur la fenetre, a son echelle EFFECTIVE (cf. en-tete) : ses coordonnees sont alors
-- celles de la fenetre. Rejoue des que la fenetre bouge sous l'aide : une fenetre de metier greffee
-- se fait pousser par le gestionnaire de panneaux quand un autre panneau s'ouvre.
local function placeCanvas(c, win)
    c._l, c._t, c._s = win:GetLeft(), win:GetTop(), win:GetEffectiveScale()
    c:SetScale(c._s / UIParent:GetEffectiveScale())
    c:ClearAllPoints()
    c:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", c._l, c._t)
    c:SetSize(win:GetWidth(), win:GetHeight())
end

local function makeCanvas()
    local c = CreateFrame("Button", nil, UIParent)
    c:SetFrameStrata("DIALOG"); c:SetToplevel(true)
    c:RegisterForClicks("AnyUp")
    -- Le voile couvre la fenêtre et en fige les clics : un clic n'importe où le referme. Sans ce
    -- script, les fenêtres devenaient inatteignables, croix comprise (vécu le 2026-09-19).
    c:SetScript("OnClick", function() Skin.HideHelp() end)
    -- La fenêtre se ferme sous l'aide (croix, Échap, bascule de vue) : le voile part avec elle. On le
    -- LIT depuis notre propre cadre ; aucun hook sur la fenêtre, qui peut être greffée chez Blizzard.
    c:SetScript("OnUpdate", function(self)
        local win = self.win
        if not (win and win:IsVisible()) then Skin.HideHelp(); return end
        if win:GetLeft() ~= self._l or win:GetTop() ~= self._t or win:GetEffectiveScale() ~= self._s then
            placeCanvas(self, win)
        end
    end)
    c:Hide()
    return c
end

-- Une tuile par index, créée à la demande puis réutilisée. Son OnEnter/OnLeave de gabarit (surbrillance
-- de la boîte) est gardé ; on y ajoute la bulle. Hooker NOTRE cadre ne teint rien de Blizzard.
local function acquireTile(i)
    if tiles[i] then return tiles[i] end
    local ok, t = pcall(CreateFrame, "Frame", nil, canvas, "HelpPlateTile")
    if not ok or not t then return nil end
    t:HookScript("OnEnter", showTip)
    t:HookScript("OnLeave", function() if tip then tip:Hide() end end)
    tiles[i] = t
    return t
end

-- Pose une tuile par entrée VISIBLE. Un cadre masqué garde ses coordonnées : sans le test IsVisible,
-- une section absente de la vue courante se faisait quand même entourer - des boîtes vides, parfois
-- hors du cadre (relevé du 2026-09-19 sur la fenêtre greffée de Forever, où seule la colonne Commandes
-- subsiste). Générique : vaut pour la vue custom, le dock et la greffe. Rend le nombre de tuiles.
local function placeTiles(win, entries)
    local ws, wl, wt = win:GetEffectiveScale(), win:GetLeft(), win:GetTop()
    local n = 0
    for _, e in ipairs(entries) do
        local fr = e.frame
        if fr and fr:IsVisible() and fr:GetLeft() then
            local tile = acquireTile(n + 1)
            if not tile then break end
            n = n + 1
            local k = fr:GetEffectiveScale() / ws          -- ramène la section à l'échelle du voile
            local x, y = fr:GetLeft() * k - wl, fr:GetTop() * k - wt   -- y ≤ 0 : sous le haut
            local w, h = fr:GetWidth() * k, fr:GetHeight() * k
            tile._text, tile._dir = e.text, e.dir or "RIGHT"
            tile:ClearAllPoints(); tile:SetSize(w, h)
            tile:SetPoint("TOPLEFT", canvas, "TOPLEFT", x, y)
            tile.Button:ClearAllPoints()
            tile.Button:SetPoint("TOPLEFT", canvas, "TOPLEFT", x + w / 2 - BTN / 2, y - h / 2 + BTN / 2)
            tile:Show(); tile.Button:Show()
        end
    end
    for i = n + 1, #tiles do tiles[i]:Hide() end
    return n
end

-- Ouvre le voile d'aide sur `win`, avec une tuile par entrée.
-- entries : { { frame = <Region>, text = <string>, dir = "UP|DOWN|LEFT|RIGHT" }, ... }.
-- La géométrie est LUE À CHAUD (positions réelles), donc appelable à chaque ouverture. Rend true si
-- posé. Un 3e argument (l'ancien bouton principal de HelpPlate) est accepté et ignoré.
function Skin.ShowHelp(win, entries)
    if not (win and win:GetLeft() and win:GetTop()) then return false end
    canvas = canvas or makeCanvas()
    placeCanvas(canvas, win)
    if placeTiles(win, entries) == 0 then Skin.HideHelp(); return false end
    canvas.win = win
    canvas:Show()
    Skin._helpOpen = true
    return true
end

function Skin.HideHelp()
    if canvas then canvas:Hide(); canvas.win = nil end
    if tip then tip:Hide() end
    Skin._helpOpen = nil
end

function Skin.HelpIsOpen()
    return Skin._helpOpen == true
end
