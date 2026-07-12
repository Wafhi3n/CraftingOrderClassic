-- CraftingOrderClassic_UI_Skin_Native.lua — kit de chrome Blizzard NATIF (le « framework » UI de COC).
-- Complète CraftingOrderClassic_UI_Skin.lua : Skin.lua garde les TOKENS (couleurs, hex) et les helpers
-- SÉMANTIQUES (métiers, statuts, rareté, quantités) ; ce fichier porte les CONSTRUCTEURS de chrome.
-- Kit INTERNE à COC, pas une lib LibStub : un seul consommateur (TradeScanner garde son skin tavern,
-- décision « COC seulement » 2026-07-11) — on promouvra en lib partagée si un 2ᵉ client apparaît.
-- Tout vit dans la même table `Skin` : les appelants ne savent pas quel fichier définit quoi.
--
-- API : MakeWindow (fenêtre ButtonFrameTemplate complète) · SetWindowPortrait · SetPortraitClickable
-- (médaillon-déclencheur + flèche) · MakeTabs (onglets bas natifs) · MakeGoldButton (bouton 3-tranches
-- natif, anti-reskin, variante sécurisée) · MakeFlatRow (ligne de liste/flyout plate) · MakeIconButton
-- (carré à icône, filtres/pills) · MakeFlyout (dropdown maison : puits + closer + pool de lignes).
-- INTOUCHABLE ici aussi : le langage couleur (statuts d'ordre, rareté) n'est jamais recoloré.

local COC  = CraftingOrderClassic
local Skin = COC.UI.Skin

-- =========================================================================
-- Bouton : hérite du template NATIF `UIPanelButtonTemplate`.
-- =========================================================================
-- On a d'abord tenté de REPEINDRE le 3-tranches à la main (croyant devoir « échapper » à un addon de
-- re-skin qui peignait les boutons en ROUGE). MESURE À L'APPUI (PIL) : l'art natif `UI-DialogBox-
-- goldbutton-*` EST rouge (up-middle ≈ RGB (104,23,8), le « gold » du nom = le liseré), et le
-- « Quitter » de la fenêtre de métier Blizzard est rouge pour la MÊME raison → aucun skinner, la
-- théorie était fausse. Le repaint manuel, lui, cassait le rendu : caps latéraux de largeur FIXE en
-- natif (Left 64 / Right 32, SEUL le middle s'étire — cf. UIPanelGoldButtonTemplate), que je
-- redimensionnais à w/3 → bords « plats/écrasés ». D'où le RETOUR au template natif, qui gère caps,
-- états (up/down/disabled) et survol tout seul, correctement à toute largeur.
-- Le SEUL correctif nécessaire : le template ancre son texte `BOTTOM, 0, 12` (calibré pour h=32) → sur
-- nos boutons de 16–24 px il monte trop haut. On le RE-ANCRE au CENTRE.
-- Contrat conservé (≈35 appelants) : `b.text` (FontString natif, ré-ancrable/mesurable/recolorable),
-- `b:SetText`/`b:GetFontString` (natifs), `b:SetSelected(on)` (enfoncé natif, reste CLIQUABLE),
-- `template` = variante SÉCURISÉE ("SecureActionButtonTemplate", DoCraft protégé) — NE JAMAIS RETIRER.
-- Doré plus tard (si le user tranche) : SetDesaturated(true)+SetVertexColor(or) sur b.Left/Middle/Right.
function Skin.MakeGoldButton(parent, w, h, text, template)
    local b = CreateFrame("Button", nil, parent,
        template and ("UIPanelButtonTemplate, " .. template) or "UIPanelButtonTemplate")
    b:SetSize(w, h)
    if h <= 16 then
        b:SetNormalFontObject("GameFontNormalSmall")
        b:SetHighlightFontObject("GameFontHighlightSmall")
        b:SetDisabledFontObject("GameFontDisableSmall")
    end
    if text then b:SetText(text) end
    local fs = b:GetFontString()
    fs:ClearAllPoints(); fs:SetPoint("CENTER", 0, 0)   -- re-centre (le template ancre BOTTOM+12, calibré h=32)
    Skin.ApplyShadow(fs)
    b.text = fs
    b.selected = false
    b.SetSelected = function(self, on)
        self.selected = on and true or false
        if self.selected then self:SetButtonState("PUSHED", true); self:LockHighlight()
        else self:SetButtonState("NORMAL"); self:UnlockHighlight() end
    end
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

-- Médaillon de la fenêtre (rond, haut-gauche). ⚠️ SetPortraitToTexture EXIGE une texture 64×64 —
-- le format des icônes standard (Interface\Icons\*, retours de GetSpellTexture) — et LÈVE UNE ERREUR
-- pour toute autre taille (vécu : WorkOrderGossipIcon, petite icône de gossip). D'où pcall + repli :
-- SetTexture brut + masque alpha rond (SetMask), l'anneau du cadre recouvrant les bords.
-- Sert aussi de feedback dynamique (ex. onglet Commande : le portrait devient l'icône du métier choisi
-- — icônes de sort 64×64, donc chemin heureux).
function Skin.SetWindowPortrait(f, tex)
    if not (f and f.portrait and tex) then return end
    if SetPortraitToTexture and pcall(SetPortraitToTexture, f.portrait, tex) then return end
    f.portrait:SetTexture(tex)
    if f.portrait.SetMask then f.portrait:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask") end
end

-- Rend le médaillon CLIQUABLE, avec une petite flèche d'affordance (sinon un rond ne se devine pas
-- cliquable). Idempotent : un 2ᵉ appel ne recrée rien, il re-câble juste le handler/tooltip — utile
-- pour un déclencheur dont le comportement dépend de l'onglet actif. `f.portrait` fait l'objet exact
-- du clic (SetAllPoints) : couvre le médaillon sans mordre sur le reste de la barre de titre.
-- Renvoie (bouton, flèche) — la flèche s'expose pour que l'appelant la masque hors contexte (ex. un
-- onglet où le clic ne fait rien) via `arrow:SetShown(bool)`.
function Skin.SetPortraitClickable(f, onClick, tooltipText)
    if not (f and f.portrait) then return end
    local btn, arrow = f._portraitBtn, f._portraitArrow
    if not btn then
        btn = CreateFrame("Button", nil, f)
        btn:SetAllPoints(f.portrait)
        btn:SetFrameLevel(f:GetFrameLevel() + 10)
        local hi = btn:CreateTexture(nil, "HIGHLIGHT")
        hi:SetAllPoints(); hi:SetColorTexture(1, 1, 1, 0.18)
        arrow = f:CreateTexture(nil, "OVERLAY")
        arrow:SetSize(14, 14); arrow:SetTexture(Skin.tex.arrowDown)
        arrow:SetPoint("BOTTOMRIGHT", f.portrait, "BOTTOMRIGHT", 3, -1)
        f._portraitBtn, f._portraitArrow = btn, arrow
    end
    btn:SetScript("OnClick", onClick)
    btn:SetScript("OnEnter", tooltipText and function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(tooltipText, 1, 1, 1)
        GameTooltip:Show()
    end or nil)
    btn:SetScript("OnLeave", tooltipText and GameTooltip_Hide or nil)
    return btn, arrow
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
    row.SetText = function(self, t) self.text:SetText(t) end   -- les appelants écrivent sur le BOUTON
    row.SetSelected = function(self, on) self.selTex:SetShown(on and true or false) end
    return row
end

-- =========================================================================
-- Ligne « personne » des listes d'artisans/récolteurs (pastille + nom + source).
-- =========================================================================
-- Constructeur partagé Commande/Récolte (il était dupliqué dans les deux) : pastille de présence à
-- gauche, nom extensible, étiquette source alignée à droite, surbrillance au survol + texture de
-- sélection. Contrat : .dot (MakeStatusIcon), .name, .src (FontStrings), .selTex (:SetShown(on)).
-- L'appelant garde le peuplement (grouping rerolls, filtre métier…) — ici que la GÉOMÉTRIE.
function Skin.MakeArtisanRow(parent, w, h)
    local r = CreateFrame("Button", nil, parent)
    r:SetSize(w, h)
    local hi = r:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints()
    hi:SetColorTexture(Skin.unpack(Skin.color.rowHover))
    local st = r:CreateTexture(nil, "BACKGROUND"); st:SetAllPoints()
    st:SetColorTexture(Skin.color.tabActive[1], Skin.color.tabActive[2], Skin.color.tabActive[3], 0.30)
    st:Hide(); r.selTex = st
    r.dot  = Skin.MakeStatusIcon(r, 14); r.dot:SetPoint("LEFT", 4, 0)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.name:SetPoint("LEFT", 18, 0); r.name:SetWidth(w - 78); r.name:SetJustifyH("LEFT"); Skin.ApplyShadow(r.name)
    r.src  = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.src:SetPoint("RIGHT", -4, 0); Skin.ApplyShadow(r.src)
    return r
end

-- =========================================================================
-- Flyout : dropdown/menu léger maison (puits + closer + pool de lignes).
-- =========================================================================
-- Le pattern « puits DIALOG + bouton plein écran qui ferme au clic ailleurs » était dupliqué 4×
-- (métier Commande, métier Récolte, vitrine Mes artisans, menu minimap) → UNE primitive. Le closer
-- est UN NIVEAU SOUS le flyout dans la même strate : un clic dans le flyout agit, un clic n'importe
-- où ailleurs ferme. Il vit sur UIParent (hors hiérarchie du panneau appelant) pour passer au-dessus.
-- Contrat : fly.rows (pool) · fly:Row(i) (ligne MakeFlatRow poolée, empilée, :Show()-ée) ·
-- fly:SetCount(n) (masque le surplus + hauteur au contenu) · fly:ToggleAt(point, rel, relPoint, x, y)
-- (ferme si ouvert, sinon ancre + ouvre — renvoie true si désormais visible).
-- opts : rowStep (défaut 20) · rowH (= rowStep) · rowW (= w − 2·pad) · pad (2).
-- Un menu à géométrie libre (titres de section, hauteur custom) peut ré-ancrer les lignes du pool et
-- écraser la hauteur APRÈS SetCount — cf. le menu minimap.
function Skin.MakeFlyout(name, w, opts)
    opts = opts or {}
    local pad  = opts.pad or 2
    local step = opts.rowStep or 20
    local rowH, rowW = opts.rowH or step, opts.rowW or (w - 2 * pad)
    local fly = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    fly:SetSize(w, 10); fly:SetFrameStrata("DIALOG"); fly:Hide(); Skin.SkinWell(fly)
    local closer = CreateFrame("Button", nil, UIParent)
    closer:SetAllPoints(); closer:SetFrameStrata("DIALOG"); closer:Hide()
    fly:SetFrameLevel(closer:GetFrameLevel() + 1)
    closer:SetScript("OnClick", function() fly:Hide() end)   -- OnHide masque le closer
    fly:SetScript("OnShow", function() closer:Show() end)
    fly:SetScript("OnHide", function() closer:Hide() end)
    fly.rows = {}
    function fly:Row(i)
        local r = self.rows[i]
        if not r then
            r = Skin.MakeFlatRow(self, rowW, rowH)
            r:SetPoint("TOPLEFT", pad, -pad - (i - 1) * step)
            self.rows[i] = r
        end
        r:Show(); return r
    end
    function fly:SetCount(n)
        for i = n + 1, #self.rows do self.rows[i]:Hide() end
        self:SetHeight(math.max(n * step + 2 * pad, 24))
    end
    function fly:ToggleAt(point, rel, relPoint, x, y)
        if self:IsShown() then self:Hide(); return false end
        self:ClearAllPoints(); self:SetPoint(point, rel, relPoint, x, y); self:Show()
        return true
    end
    return fly
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
