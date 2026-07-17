-- CraftingOrderClassic_UI_Skin_Native.lua — kit de chrome Blizzard NATIF (le « framework » UI de COC).
-- Complète CraftingOrderClassic_UI_Skin.lua : Skin.lua garde les TOKENS (couleurs, hex) et les helpers
-- SÉMANTIQUES (métiers, statuts, rareté, quantités) ; ce fichier porte les CONSTRUCTEURS de chrome.
-- Kit INTERNE à COC, pas une lib LibStub : un seul consommateur (TradeScanner garde son skin tavern,
-- décision « COC seulement » 2026-07-11) — on promouvra en lib partagée si un 2ᵉ client apparaît.
-- Tout vit dans la même table `Skin` : les appelants ne savent pas quel fichier définit quoi.
--
-- API : MakeWindow (fenêtre ButtonFrameTemplate complète) · SetWindowPortrait · SetPortraitClickable
-- (médaillon-déclencheur + flèche) · MakeTabs (languettes natives TabButtonTemplate, en haut) · MakeGoldButton (bouton 3-tranches
-- natif, anti-reskin, variante sécurisée) · MakeFlatRow (ligne de liste/flyout plate) · MakeIconButton
-- (carré à icône, filtres/pills) · MakeFilterButton (bande de filtre style hôtel des ventes) · MakeFlyout
-- (dropdown maison : puits + closer + pool de lignes) · MakeDropdown (dropdown NATIF UIDropDownMenu,
-- le sélecteur gris de l'HdV) · MakeCheckButton (case à cocher NATIVE, style « Objets utilisables »
-- de l'HdV) · FieldLabel (légende de champ style HdV). Les primitives de SECTIONS (MakeInset,
-- MakeDivider, MakeDividerV) vivent dans _UI_Skin_Sections.lua (même table Skin, anti-monolithe).
-- MakeFlyout vs MakeDropdown : le premier est un MENU maison (géométrie libre, lignes riches : métiers,
-- menu minimap) ; le second est le SÉLECTEUR natif (une valeur parmi N, coche, look HdV) — préférer
-- MakeDropdown dès qu'il s'agit de choisir UNE valeur dans une liste courte.
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
-- Échap ferme la fenêtre (comme le bouton X). On n'inscrit PAS la fenêtre elle-même dans
-- UISpecialFrames : la vue métier est PROTÉGÉE par contagion (bouton « Créer » sécurisé descendant)
-- → le Hide() déclenché par Échap serait bloqué en combat (ADDON_ACTION_BLOCKED, vu en jeu
-- 2026-07-17). Un PROXY invisible et non protégé porte donc l'Échap et rejoue la logique du X.
-- Garde alpha : une fenêtre escamotée en combat (alpha 0, cf. PW:Hide) ne doit pas « se fermer ».
local function attachEscProxy(f, name, onClose)
    local esc = CreateFrame("Frame", name .. "EscProxy", UIParent)
    esc:Hide()
    esc:SetScript("OnHide", function()
        if not f:IsShown() or f:GetAlpha() == 0 then return end
        if onClose then onClose() else f:Hide() end
    end)
    f:HookScript("OnShow", function() esc:Show() end)
    f:HookScript("OnHide", function() esc:Hide() end)
    f.escProxy = esc
    tinsert(UISpecialFrames, name .. "EscProxy")
end

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
    attachEscProxy(f, name, opts.onClose)
    -- BARRE D'ACTIONS native du template (opts.buttonBar) : ButtonFrameTemplate embarque une bande à
    -- boutons en bas de cadre (BtnCornerLeft/Right + tuile ButtonBottomBorder, le marbre s'arrêtant
    -- 26 px au-dessus du bas — SharedUIPanelTemplates.xml:765). C'est LE bloc « Destinataire + Poster »
    -- demandé par le user (maquette GIMP à l'appui) : zéro asset, le client assemble les pièces.
    -- `f.ActionBar` = frame posée sur la bande, à ancrer par le contenu (les onglets y posent un
    -- conteneur parenté à LEUR panneau : il se masque avec l'onglet). Sans l'option, comportement
    -- historique : la barre est retirée et le marbre descend jusqu'en bas.
    if opts.buttonBar then
        local bar = CreateFrame("Frame", nil, f)
        bar:SetPoint("TOPLEFT", f.Inset, "BOTTOMLEFT", 0, 0)
        bar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, 4)
        f.ActionBar = bar
    elseif ButtonFrameTemplate_HideButtonBar then
        ButtonFrameTemplate_HideButtonBar(f)
    end
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
-- Onglets EN HAUT, dans le marbre — vraies LANGUETTES natives (style « Amis/Ignorés » du volet Social).
-- =========================================================================
-- Deux itérations à NE PAS refaire :
--   (1) EN BAS via `CharacterFrameTabButtonTemplate` (art « fiche de perso ») — dessiné pour PENDRE
--       SOUS le cadre : posé en `BOTTOMLEFT` il dépassait de la FENÊTRE, recouvert par toute fenêtre
--       Blizzard ancrée plus bas (vécu : le volet Amis).
--   (2) EN HAUT mais en `MakeGoldButton` (3-tranches) → ça faisait des BOUTONS ROUGES, pas des
--       onglets : « ça fait pas du tout comme la liste d'Amis » (user, capture à l'appui).
-- Le volet Amis utilise `TabButtonTemplate` (les onglets Amis/Ignorés) : art GRIS `HelpFrameTab-*`
-- (Inactive/Active), forme de languette dont le corps est DANS la zone de contenu et le bas ouvert se
-- fond dans le marbre — EXACTEMENT le rendu demandé. On HÉRITE ce template natif (pas de re-peinture,
-- pas de XML maison : `CreateFrame(..., "TabButtonTemplate")` réutilise le template XML de Blizzard
-- tel quel — cf. note « pourquoi pas de XML » dans la skill). Contraintes du template : sélection via
-- `PanelTemplates_SelectTab/DeselectTab` (montre l'art Actif + désactive le clic sur l'onglet ACTIF,
-- comportement d'onglet voulu) → EXIGE un NOM GLOBAL (les helpers résolvent `_G[name.."Left"]`…), et
-- re-`TabResize` après chaque SetText (aucun reflow).
-- PLACEMENT (mesuré sur PortraitFrameTemplate) : la barre de titre GRISE occupe f0..f−21, puis la tuile
-- ROCK va de f−21 à l'inset (f−60) ; le PORTRAIT (61×61 en −6,8) déborde jusqu'à x≈55 / y≈−53. Le volet
-- Amis pose ses languettes SUR cette bande grise → on fait pareil : à DROITE du portrait (défaut tabX=62,
-- il dégage le bord droit du portrait x≈54) et dans le rock SOUS le titre (défaut tabY=−34, sous la tuile
-- de titre −21 et le nom de métier de l'en-tête −14). Le corps de la languette vit donc DANS le gris,
-- son bas ouvert plonge vers le contenu — le rendu « onglets sur la barre grise » demandé. La fenêtre
-- réserve la bande dessous (PAD_TOP, UI.lua). Contrat `bar` inchangé : .buttons[id], :Select, :SetText.
function Skin.MakeTabs(f, defs, onSelect, opts)
    local x = (opts and opts.tabX) or 62
    local y = (opts and opts.tabY) or -28
    local bar, prev = { buttons = {} }, nil
    for i, d in ipairs(defs) do
        local b = CreateFrame("Button", (f:GetName() or "COCWin") .. "Tab" .. i, f, "TabButtonTemplate")
        b:SetText(d.label)
        PanelTemplates_TabResize(b, 0)
        if prev then b:SetPoint("LEFT", prev, "RIGHT", -4, 0)
        else b:SetPoint("TOPLEFT", f, "TOPLEFT", x, y) end
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
        b:SetText(text); PanelTemplates_TabResize(b, 0)
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
-- Surbrillance de ligne « façon liste d'Amis » (réutilise le chrome natif du volet Social). La ligne
-- d'ami (FriendsFrameButtonTemplate) n'utilise PAS un aplat gris mais la BARRE `UI-QuestLogTitleHighlight`
-- en mode ADD, teintée en BLEU (SetVertexColor 0.243/0.570/1 — valeur exacte du OnLoad Blizzard) →
-- lueur bleue au survol, le marqueur visuel emblématique des listes de personnes du jeu. Ajoute la
-- couche HIGHLIGHT (auto au survol) + rend une texture de SÉLECTION (bleu léger, masquée) pour
-- :SetSelected. À utiliser partout où on liste des PERSONNES (artisans, récolteurs) pour l'homogénéité.
function Skin.PersonHighlight(row)
    local hi = row:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints()
    hi:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
    hi:SetBlendMode("ADD"); hi:SetVertexColor(0.243, 0.570, 1)
    local sel = row:CreateTexture(nil, "BACKGROUND"); sel:SetAllPoints()
    sel:SetColorTexture(0.243, 0.570, 1, 0.22); sel:Hide()
    return sel
end

function Skin.MakeArtisanRow(parent, w, h)
    local r = CreateFrame("Button", nil, parent)
    r:SetSize(w, h)
    r.selTex = Skin.PersonHighlight(r)   -- surbrillance bleue native (liste d'Amis)
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

-- =========================================================================
-- Dropdown natif (UIDropDownMenuTemplate) — le sélecteur gris de l'hôtel des ventes.
-- =========================================================================
-- Le widget EXACT du filtre « Rareté » de l'HdV : 3-tranches `CharacterCreate-LabelFrame` + flèche
-- dorée + liste déroulante à coches. On l'HÉRITE (cf. skill, piège n°9 : hériter le template XML natif,
-- ne pas en peindre un faux) — il existe bien en Era (SharedXML/Classic/UIDropDownMenuTemplates.xml:220)
-- et gère seul le survol, la coche de l'entrée active et la fermeture au clic ailleurs.
-- ⚠️ DEUX contraintes du template, toutes deux payées d'avance ici :
--  · il EXIGE un nom GLOBAL : ses tranches sont `$parentLeft/Middle/Right` et TOUS les helpers
--    UIDropDownMenu_* repassent par `frame:GetName()` → d'où `name` en 1er argument (comme MakeFlyout).
--  · son art porte une MARGE TRANSPARENTE (~15 px à gauche) et le cadre visible est centré dans les
--    32 px de haut de la frame : ancrer la frame « à x,y » ne pose donc PAS le bord visible à x,y.
--    D'où `:SetPointVisual`, qui prend les coordonnées du bord VISIBLE voulu et applique la compense.
-- Contrat : `dd:SetValue(v)` (coche + libellé) · `dd.value` · `items` = liste `{ {value=…, text=…}, … }`
-- ou FONCTION qui la rend (ré-évaluée à chaque ouverture : libellés localisés/dynamiques) ·
-- `opts.onSelect(v)` · `opts.label` (préfixe collé devant le libellé, ex. « Qualité : »).
-- NB : ne jamais utiliser `false` comme `value` (UIDropDownMenu_SetSelectedValue le traite comme
-- « pas de sélection ») — passer par un index ou 0, cf. le filtre qualité de l'onglet Commande.
local DD_INSET_X, DD_INSET_Y = 15, 2   -- marge transparente de l'art (gauche / haut) — affinés en jeu
function Skin.MakeDropdown(name, parent, w, items, opts)
    opts = opts or {}
    local dd = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    local function list() return (type(items) == "function") and items() or items end
    -- Valeur absente de la liste (liste pas encore peuplée : rerolls pas encore scannés au 1er affichage)
    -- → on affiche la valeur brute plutôt qu'un libellé VIDE, qui ferait croire à un sélecteur cassé.
    local function textFor(v)
        for _, it in ipairs(list()) do if it.value == v then return it.text or "" end end
        return (type(v) == "string") and v or ""
    end
    function dd:SetValue(v)
        self.value = v
        UIDropDownMenu_SetSelectedValue(self, v)
        UIDropDownMenu_SetText(self, (opts.label or "") .. textFor(v))
    end
    UIDropDownMenu_Initialize(dd, function(_, level)
        for _, it in ipairs(list()) do
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.value = it.text, it.value
            info.checked = (it.value == dd.value)
            info.func = function()
                dd:SetValue(it.value)
                if opts.onSelect then opts.onSelect(it.value) end
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetWidth(dd, w)
    UIDropDownMenu_JustifyText(dd, "LEFT")
    -- Ancre le bord VISIBLE du cadre (et non la frame, cf. marge transparente ci-dessus). Le SIGNE de la
    -- compense dépend du bord ancré : à GAUCHE il faut reculer la frame (−), à DROITE l'avancer (+) —
    -- sinon un dropdown ancré TOPRIGHT part 15 px trop à gauche (vécu : la vitrine de « Mes artisans »).
    function dd:SetPointVisual(point, rel, relPoint, x, y)
        local dx = point:find("RIGHT") and DD_INSET_X or -DD_INSET_X
        self:SetPoint(point, rel, relPoint, (x or 0) + dx, (y or 0) + DD_INSET_Y)
    end
    return dd
end

-- Case à cocher NATIVE (`UICheckButtonTemplate`, SharedUIPanelTemplates.xml:413) — le widget des
-- filtres « Objets utilisables » / « Afficher sur le personnage » du browse de l'HdV.
-- À ne pas confondre avec `Skin.MakeCheck` (Skin.lua) : celle-ci est une simple TEXTURE d'affichage
-- (état non cliquable, posée dans une ligne de liste) ; ici c'est un vrai bouton cliquable avec
-- survol/pressé/coche natifs. Le template fait 32×32 (calibré pour les panneaux Blizzard) → on le
-- réduit, et le libellé natif (parentKey `Text`) est ré-ancré à droite de la boîte.
-- Contrat : `c.text` (FontString) · `c:SetChecked/GetChecked` (natifs) · `c.Text` (alias natif).
function Skin.MakeCheckButton(parent, text, size)
    size = size or 20
    local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    c:SetSize(size, size)
    local fs = c.Text or c.text
    fs:ClearAllPoints(); fs:SetPoint("LEFT", c, "RIGHT", 2, 0)
    fs:SetFontObject("GameFontHighlightSmall")   -- police des libellés de filtre de l'HdV
    if text then fs:SetText(text) end
    Skin.ApplyShadow(fs)
    c.text = fs
    return c
end

-- (Blocs de section & séparateurs — MakeInset, MakeDivider, MakeDividerV — : voir
-- CraftingOrderClassic_UI_Skin_Sections.lua, même table Skin, découpé pour l'anti-monolithe.)

-- Légende de champ style HdV (« NOM », « RARETÉ » au-dessus de leur champ). Police EXACTE de l'HdV :
-- `GameFontHighlightSmall` (cf. BrowseNameText, Blizzard_AuctionUI.xml:126).
function Skin.FieldLabel(parent, text, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", x, y); fs:SetText(text); Skin.ApplyShadow(fs)
    return fs
end

-- =========================================================================
-- Bande de filtre verticale, style « catégories » de l'hôtel des ventes.
-- =========================================================================
-- Réplique fidèle de `AuctionClassButtonTemplate` (Blizzard_AuctionUITemplates.xml, HdV classique) :
-- fond plat `UI-AuctionFrame-FilterBg` (bande sombre étirable) + survol/sélection par le highlight
-- doré natif de l'onglet perso (`UI-Character-Tab-Highlight`, ADD). La SÉLECTION = `LockHighlight`,
-- exactement comme l'HdV (AuctionFrameFilter_OnClick verrouille le highlight du bouton actif) — donc
-- AUCUN bleu : l'effet bleu vu ailleurs venait d'une texture de highlight étrangère, pas de l'HdV.
-- Contrat aligné sur MakeGoldButton pour drop-in dans une sidebar : `b.text` (libellé gauche,
-- ré-ancrable/mesurable), `b:SetText`, `b:SetSelected(on)` (verrou doré, reste CLIQUABLE).
-- ⚠️ `UI-AuctionFrame-FilterBg` est de l'art PEINT figé (ancien monde), pas une tuile native : à
-- réserver aux listes de filtres facettés type HdV — ne pas en faire le chrome général (cf. skill).
function Skin.MakeFilterButton(parent, w, h, text)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, h or 20)
    local bg = b:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints()
    bg:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-FilterBg")
    bg:SetTexCoord(0, 0.53125, 0, 0.625)   -- sous-région exacte du template HdV
    b.bg = bg
    local hi = b:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints()
    hi:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight"); hi:SetBlendMode("ADD")
    b:SetNormalFontObject("GameFontNormalSmallLeft")
    b:SetHighlightFontObject("GameFontHighlightSmallLeft")
    if text then b:SetText(text) end
    local fs = b:GetFontString()
    fs:ClearAllPoints(); fs:SetPoint("LEFT", 8, 0); fs:SetJustifyH("LEFT"); Skin.ApplyShadow(fs)
    b.text = fs
    b.selected = false
    b.SetSelected = function(self, on)
        self.selected = on and true or false
        if self.selected then self:LockHighlight() else self:UnlockHighlight() end
    end
    return b
end
