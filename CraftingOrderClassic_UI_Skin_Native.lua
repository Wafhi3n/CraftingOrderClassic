-- CraftingOrderClassic_UI_Skin_Native.lua — kit de chrome Blizzard NATIF (le « framework » UI de COC).
-- Complète CraftingOrderClassic_UI_Skin.lua : Skin.lua garde les TOKENS (couleurs, hex) et les helpers
-- SÉMANTIQUES (métiers, statuts, rareté, quantités) ; ce fichier porte les CONSTRUCTEURS de chrome.
-- Kit INTERNE à COC, pas une lib LibStub : un seul consommateur (TradeScanner garde son skin tavern,
-- décision « COC seulement » 2026-07-11) — on promouvra en lib partagée si un 2ᵉ client apparaît.
-- Tout vit dans la même table `Skin` : les appelants ne savent pas quel fichier définit quoi.
--
-- API : MakeWindow (fenêtre ButtonFrameTemplate complète) · SetWindowPortrait · MakeTabs (onglets bas
-- natifs) · MakeGoldButton (bouton 3-tranches natif, anti-reskin, variante sécurisée) · MakeFlatRow
-- (ligne de liste/flyout plate) · MakeIconButton (carré à icône, filtres/pills).
-- INTOUCHABLE ici aussi : le langage couleur (statuts d'ordre, rareté) n'est jamais recoloré.

local COC  = CraftingOrderClassic
local Skin = COC.UI.Skin

-- =========================================================================
-- Bouton : look NATIF Blizzard, mais SANS hériter d'UIPanelButtonTemplate.
-- =========================================================================
-- Pourquoi ne pas hériter du template : un addon d'interface tiers re-skinne (chez le user : en ROUGE)
-- TOUT ce qui hérite d'UIPanelButtonTemplate — y compris les boutons de Blizzard eux-mêmes (le
-- « Quitter » de la fenêtre de métier native vire au rouge). C'était la raison d'être du bouton or
-- « maison » d'origine (« échappe aux re-skins externes »). On veut les DEUX : l'apparence du jeu ET
-- l'immunité au re-skin. Solution : on REPEINT à la main le 3-tranches natif —
-- `UI-DialogBox-goldbutton-{up,down,disabled}-{left,middle,right}`, qui est littéralement l'art
-- d'UIPanelButtonTemplate — sans le template, et sans les clés `Left`/`Middle`/`Right` sur lesquelles
-- les skinners s'accrochent (nommées `_l`/`_m`/`_r` ici).
local BTN = "Interface\\Buttons\\UI-DialogBox-goldbutton-"

local function btnPaint(b, state)   -- state = "up" | "down" | "disabled"
    b._l:SetTexture(BTN .. state .. "-left")
    b._m:SetTexture(BTN .. state .. "-middle")
    b._r:SetTexture(BTN .. state .. "-right")
end

-- Repos = l'état RÉEL du bouton (désactivé > sélectionné > normal).
local function btnRest(b)
    if not b:IsEnabled() then return btnPaint(b, "disabled") end
    btnPaint(b, b.selected and "down" or "up")
end

-- Caps latéraux : 32 px en natif. Sur les petits boutons (pills 24 px, filtres), gauche+droite (64)
-- dépasseraient la largeur → on borne à w/3. Recalculé à CHAQUE redimensionnement : plusieurs
-- appelants créent le bouton étroit puis l'élargissent après avoir mesuré leur texte (GetStringWidth).
local function btnSide(b)
    local s = math.min(32, math.max(4, math.floor((b:GetWidth() or 12) / 3)))
    b._l:SetWidth(s); b._r:SetWidth(s)
end

-- Contrat (≈35 appelants, hérité du bouton or « maison ») : `b.text` (FontString que les appelants
-- ré-ancrent / mesurent / recolorent), `b:SetText` / `b:GetFontString` (natifs via SetFontString),
-- `b:SetSelected(on)` (rendu « enfoncé », reste CLIQUABLE — pas de Disable, contrairement aux onglets).
-- `template` optionnel = bouton SÉCURISÉ ("SecureActionButtonTemplate") pour rediriger un clic vers une
-- fonction PROTÉGÉE de Blizzard (DoCraft des enchantements). NE JAMAIS RETIRER.
-- Pas d'OnEnter/OnLeave ici (surbrillance = couche HIGHLIGHT auto) → chaîner sous garde nil.
function Skin.MakeGoldButton(parent, w, h, text, template)
    local b = CreateFrame("Button", nil, parent, template)
    b:SetSize(w, h)
    local l = b:CreateTexture(nil, "BACKGROUND"); l:SetPoint("TOPLEFT"); l:SetPoint("BOTTOMLEFT")
    local r = b:CreateTexture(nil, "BACKGROUND"); r:SetPoint("TOPRIGHT"); r:SetPoint("BOTTOMRIGHT")
    local m = b:CreateTexture(nil, "BACKGROUND")
    m:SetPoint("TOPLEFT", l, "TOPRIGHT"); m:SetPoint("BOTTOMRIGHT", r, "BOTTOMLEFT")
    b._l, b._m, b._r = l, m, r

    local hi = b:CreateTexture(nil, "HIGHLIGHT")   -- surbrillance native (couche HIGHLIGHT = auto au survol)
    hi:SetTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    hi:SetTexCoord(0, 0.625, 0, 0.6875); hi:SetBlendMode("ADD")
    hi:SetPoint("TOPLEFT", 2, -1); hi:SetPoint("BOTTOMRIGHT", -2, 1)

    local fs = b:CreateFontString(nil, "OVERLAY", (h <= 16) and "GameFontNormalSmall" or "GameFontNormal")
    fs:SetPoint("CENTER"); Skin.ApplyShadow(fs)
    b:SetFontString(fs)   -- → SetText / GetFontString natifs
    b.text = fs
    if text then b:SetText(text) end

    b.selected = false
    b.SetSelected = function(self, on) self.selected = on and true or false; btnRest(self) end
    b:SetScript("OnMouseDown", function(self) if self:IsEnabled() then btnPaint(self, "down") end end)
    b:SetScript("OnMouseUp", btnRest)
    b:SetScript("OnEnable", btnRest)
    b:SetScript("OnDisable", btnRest)
    b:SetScript("OnSizeChanged", btnSide)
    btnSide(b); btnRest(b)
    return b
end

-- =========================================================================
-- Fenêtre native complète (ButtonFrameTemplate).
-- =========================================================================
-- Fournit d'un coup : barre de titre + portrait rond + bouton fermer + panneau encastré marbre
-- (`f.Inset`) + fond rocher. opts :
--   title     : texte de la barre de titre (SetTitle du PortraitFrameTemplateMixin)
--   portrait  : texture du médaillon (cf. SetWindowPortrait)
--   pos       : {point, relPoint, x, y} persisté, sinon CENTER
--   onMoved   : function(point, relPoint, x, y) à la fin d'un drag (pour persister)
--   onClose   : remplace le comportement du bouton fermer natif (ex. dock de la vue métier)
--   strata    : défaut "HIGH"
-- SetToplevel : les fenêtres COC partagent la strata → un clic remonte la fenêtre entière d'un bloc
-- (fini l'interclassement des éléments) ; Raise à l'ouverture = la dernière ouverte devant.
function Skin.MakeWindow(name, w, h, opts)
    opts = opts or {}
    local f = CreateFrame("Frame", name, UIParent, "ButtonFrameTemplate")
    f:SetSize(w, h)
    local p = opts.pos
    if p then f:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else f:SetPoint("CENTER") end
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(fr)
        fr:StopMovingOrSizing()
        if opts.onMoved then
            local pt, _, rp, x, y = fr:GetPoint()
            opts.onMoved(pt, rp, x, y)
        end
    end)
    f:SetClampedToScreen(true); f:SetFrameStrata(opts.strata or "HIGH")
    f:SetToplevel(true)
    f:SetScript("OnShow", function(fr) fr:Raise() end)
    if f.SetTitle and opts.title then f:SetTitle(opts.title) end
    if opts.portrait then Skin.SetWindowPortrait(f, opts.portrait) end
    if opts.onClose and f.CloseButton then f.CloseButton:SetScript("OnClick", opts.onClose) end
    -- Pas de barre de boutons en bas → le marbre descend jusqu'en bas (guardé : fonction du template).
    if ButtonFrameTemplate_HideButtonBar then ButtonFrameTemplate_HideButtonBar(f) end
    f:Hide()
    return f
end

-- Médaillon de la fenêtre (rond, haut-gauche). SetPortraitToTexture applique le masque circulaire aux
-- icônes carrées quand l'API existe ; sinon repli SetTexture (l'anneau du cadre recouvre les coins).
-- Sert aussi de feedback dynamique (ex. onglet Commande : le portrait devient l'icône du métier choisi).
function Skin.SetWindowPortrait(f, tex)
    if not (f and f.portrait and tex) then return end
    if SetPortraitToTexture then SetPortraitToTexture(f.portrait, tex)
    else f.portrait:SetTexture(tex) end
end

-- =========================================================================
-- Onglets natifs en bas de cadre (style fiche de personnage).
-- =========================================================================
-- CharacterFrameTabButtonTemplate : textures old-school garanties en Era — PAS PanelTabButtonTemplate,
-- basé atlas et incompatible avec PanelTemplates_SelectTab (clés *Active vs *Disabled). Le template
-- câble en dur son OnClick sur CharacterFrame et son OnShow sur CharacterFrame_TabBoundsCheck → on
-- REMPLACE les deux. Il exige un NOM GLOBAL (TabResize/SelectTab résolvent `_G[name.."Middle"]`…).
-- defs = { {id=, label=} } ; onSelect(id) au clic. Renvoie `bar` : .buttons[id], :Select(id),
-- :SetText(id, text) — TOUJOURS passer par bar:SetText (re-mesure la largeur, ex. « Carnet (3) »).
function Skin.MakeTabs(f, defs, onSelect, opts)
    local maxW = (opts and opts.maxTabWidth) or 120
    f.maxTabWidth = maxW   -- lu par l'OnEvent du template (DISPLAY_SIZE_CHANGED) : sinon repli à 88
    local bar, prev = { buttons = {} }, nil
    for i, d in ipairs(defs) do
        local b = CreateFrame("Button", (f:GetName() or "COCWin") .. "Tab" .. i, f,
            "CharacterFrameTabButtonTemplate")
        b:SetText(d.label)
        PanelTemplates_TabResize(b, 0, nil, 40, maxW)
        if prev then b:SetPoint("LEFT", prev, "RIGHT", -16, 0)
        else b:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 12, 2) end
        b:SetScript("OnShow", function(tab) PanelTemplates_TabResize(tab, 0, nil, 40, maxW) end)
        b:SetScript("OnClick", function() onSelect(d.id) end)
        bar.buttons[d.id] = b; prev = b
    end
    function bar:Select(id)
        for tid, b in pairs(self.buttons) do
            if tid == id then PanelTemplates_SelectTab(b) else PanelTemplates_DeselectTab(b) end
        end
    end
    function bar:SetText(id, text)
        local b = self.buttons[id]; if not b then return end
        b:SetText(text); PanelTemplates_TabResize(b, 0, nil, 40, maxW)
    end
    return bar
end

-- =========================================================================
-- Ligne plate de liste / flyout (PAS un bouton 3-tranches).
-- =========================================================================
-- Pour les rangées cliquables : lignes de dropdown maison, « toute la liste », rerolls, menu minimap…
-- Le bouton doré n'est PAS fait pour ça (l'ancien MakeGoldButton servait aussi de ligne, faute de
-- mieux). Contrat : .text (ré-ancrable), .selTex, :SetSelected(on). Surbrillance auto (HIGHLIGHT).
function Skin.MakeFlatRow(parent, w, h)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(w, h)
    local hi = row:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints()
    hi:SetColorTexture(Skin.unpack(Skin.color.rowHover))
    local sel = row:CreateTexture(nil, "BACKGROUND"); sel:SetAllPoints()
    sel:SetColorTexture(Skin.color.tabActive[1], Skin.color.tabActive[2], Skin.color.tabActive[3], 0.30)
    sel:Hide(); row.selTex = sel
    local fs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("LEFT", 6, 0); fs:SetJustifyH("LEFT"); Skin.ApplyShadow(fs)
    row.text = fs
    row.SetSelected = function(self, on) self.selTex:SetShown(on and true or false) end
    return row
end

-- =========================================================================
-- Bouton-icône carré (filtres par métier, pills).
-- =========================================================================
-- Icône native encadrée d'un liseré 1 px — même famille visuelle que Skin.MakeBadge. Contrat :
-- .icon (texture, désaturable par l'appelant), :SetSelected(on) = liseré doré vif.
function Skin.MakeIconButton(parent, size, tex)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(size, size)
    b:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    local ic = b:CreateTexture(nil, "ARTWORK")
    ic:SetPoint("TOPLEFT", 1, -1); ic:SetPoint("BOTTOMRIGHT", -1, 1)
    ic:SetTexCoord(0.08, 0.92, 0.08, 0.92)   -- rogne la bordure native de l'icône
    if tex then ic:SetTexture(tex) end
    b.icon = ic
    local hi = b:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints(); hi:SetColorTexture(1, 1, 1, 0.15)
    b.selected = false
    local function rest(self)
        if self.selected then
            self:SetBackdropBorderColor(Skin.unpack(Skin.color.goldHi)); self:SetBackdropColor(0, 0, 0, 1)
        else
            self:SetBackdropBorderColor(Skin.unpack(Skin.color.border)); self:SetBackdropColor(0, 0, 0, 0.6)
        end
    end
    b.SetSelected = function(self, on) self.selected = on and true or false; rest(self) end
    rest(b)
    return b
end
