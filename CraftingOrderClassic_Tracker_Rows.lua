-- CraftingOrderClassic_Tracker_Rows.lua — LIGNES du suivi à l'écran : pool réutilisable + peinture
-- d'un groupe de sections rendu par COC.Journal:Grouped. La coque (fenêtre, déplacement, événements,
-- cadence) vit dans _Tracker.lua ; ici, uniquement du texte posé au pixel.
--
-- Fidélité au suivi de quête NATIF — valeurs LUES dans Blizzard_UIPanels_Game\Vanilla\QuestLogFrame,
-- pas approchées à l'œil :
--   · une ligne = 13 px (QuestWatchFrame:SetHeight(watchTextIndex * 13)), largeur = max + 10 ;
--   · titre dont tous les objectifs sont remplis → NORMAL_FONT_COLOR, sinon 0.75/0.61/0 ;
--   · objectif rempli → HIGHLIGHT_FONT_COLOR, sinon 0.8/0.8/0.8 ;
--   · la coche des quêtes terminées = Interface\Buttons\UI-CheckBox-Check (Skin.tex.checkMark) ;
--   · le [-]/[+] d'une section = UI-MinusButton-UP / UI-PlusButton-UP (QuestLogTitleButtonTemplate).
-- Aucune police custom : les GameFont* portent déjà l'ombre qui rend le texte lisible sur le monde.

local COC = CraftingOrderClassic
COC.Tracker = COC.Tracker or {}
local Tracker = COC.Tracker
local Skin = COC.UI and COC.UI.Skin
local L    = COC.L

local LINE_H    = 13     -- hauteur d'une ligne du suivi natif
local MAX_LINES = 30     -- MAX_QUESTWATCH_LINES
local PAD_W     = 10     -- QuestWatchFrame : SetWidth(questWatchMaxWidth + 10)
local IND_TITLE = 12     -- indentation d'un titre sous son en-tête de section
local IND_OBJ   = 22     -- indentation d'un objectif sous son titre

local COLOR = {
    header    = { 1.00, 0.82, 0.00 },   -- NORMAL_FONT_COLOR
    titleDone = { 1.00, 0.82, 0.00 },   -- titre dont TOUS les objectifs sont remplis
    title     = { 0.75, 0.61, 0.00 },   -- titre incomplet (valeur exacte du suivi natif)
    objDone   = { 1.00, 1.00, 1.00 },   -- HIGHLIGHT_FONT_COLOR
    obj       = { 0.80, 0.80, 0.80 },
    unknown   = { 0.60, 0.60, 0.60 },   -- réactifs inconnus du catalogue : dit, jamais deviné
}

local TEX_MINUS = "Interface\\Buttons\\UI-MinusButton-UP"
local TEX_PLUS  = "Interface\\Buttons\\UI-PlusButton-UP"

-- ------------------------------------------------------------------
-- Pool de lignes
-- ------------------------------------------------------------------
-- Une ligne = un Button (il faut le clic et le survol ; le suivi natif, lui, n'est pas cliquable).
-- Elle porte tout ce dont les trois rôles ont besoin — on n'instancie pas trois types de lignes pour
-- économiser trois textures : la ligne se REconfigure à chaque peinture.
function Tracker:_Row(i)
    self.rows = self.rows or {}
    local r = self.rows[i]
    if r then return r end
    r = CreateFrame("Button", nil, self.frame)
    r:SetHeight(LINE_H)
    r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    -- Déplacement : on saisit N'IMPORTE QUELLE ligne. Pas de zone de préhension transparente — un
    -- cadre plein écran EnableMouse mangerait les clics sur le monde derrière le suivi.
    r:RegisterForDrag("LeftButton")
    r:SetScript("OnDragStart", function() Tracker:BeginDrag() end)
    r:SetScript("OnDragStop",  function() Tracker:EndDrag() end)

    local fs = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetJustifyH("LEFT")
    r.text = fs

    local icon = r:CreateTexture(nil, "OVERLAY")
    icon:SetSize(LINE_H, LINE_H)
    icon:Hide()
    r.icon = icon

    local hl = r:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
    hl:SetBlendMode("ADD"); hl:SetAlpha(0.4)

    if Skin and Skin.WireItemTooltip then Skin.WireItemTooltip(r) end
    r:SetScript("OnClick", function(row, button)
        if row.onClick then row.onClick(button) end
    end)
    self.rows[i] = r
    return r
end

-- Remet une ligne à zéro avant de lui donner un rôle (les lignes sont recyclées entre peintures :
-- un reliquat d'icône ou de tooltip d'un ancien rôle donne des lignes « fantômes »).
local function reset(r, indent, y, parent)
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", parent, "TOPLEFT", indent, y)
    r:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
    r.icon:Hide()
    r.onClick, r.tipItemID, r.tipSpellID = nil, nil, nil
    r:Show()
end

-- Ré-ancrage EXPLICITE du texte à chaque rôle : re-SetPoint sur un point déjà posé est ambigu, on
-- repart toujours d'un ClearAllPoints (une ligne recyclée gardait sinon le décalage de son rôle
-- précédent — icône présente puis absente).
local function textAt(r, x)
    r.text:ClearAllPoints()
    r.text:SetPoint("LEFT", r, "LEFT", x, 0)
end

-- ------------------------------------------------------------------
-- Les trois rôles de ligne
-- ------------------------------------------------------------------
-- En-tête de section : le [-]/[+] et le libellé, comme « Hellfire Peninsula » du journal. Clic =
-- replier/déplier CETTE section (persisté). Le compteur entre parenthèses reprend « Quests: 9/25 ».
function Tracker:_PaintHeader(r, group, y, collapsed)
    reset(r, 0, y, self.frame)
    r.icon:SetTexture(collapsed and TEX_PLUS or TEX_MINUS)
    r.icon:ClearAllPoints(); r.icon:SetPoint("LEFT", r, "LEFT", 0, 0)
    r.icon:Show()
    textAt(r, LINE_H + 2)
    r.text:SetText(group.title .. " (" .. #group.entries .. ")")
    r.text:SetTextColor(unpack(COLOR.header))
    local section = group.section
    -- Gauche = replier la section ; DROITE = ouvrir le journal parchemin. Ajout pur : le clic gauche
    -- des en-têtes garde exactement son comportement.
    r.onClick = function(button)
        if button == "RightButton" and COC.JournalWin then return COC.JournalWin:Toggle() end
        Tracker:ToggleSection(section)
    end
    return r.text:GetStringWidth() + LINE_H + 2
end

-- Titre d'entrée : nom de l'objet + coche verte si tout est réuni, client à droite. Clic gauche =
-- ouvrir la vue du métier concerné (jamais de bouton SÉCURISÉ dans le suivi : il interdirait de
-- masquer le cadre en combat, cf. wow-protected-frame-hide-combat).
function Tracker:_PaintTitle(r, e, y)
    reset(r, IND_TITLE, y, self.frame)
    local txt = e.title or "?"
    if e.sub then txt = txt .. "  |cFF8C8C8C" .. e.sub .. "|r" end
    local hasCheck = e.complete and Skin and Skin.tex
    if hasCheck then
        r.icon:SetTexture(Skin.tex.checkMark)
        r.icon:ClearAllPoints(); r.icon:SetPoint("LEFT", r, "LEFT", 0, 0)
        r.icon:Show()
    end
    textAt(r, hasCheck and LINE_H or 0)
    r.text:SetText(txt)
    r.text:SetTextColor(unpack(e.complete and COLOR.titleDone or COLOR.title))
    r.tipItemID, r.tipSpellID = e.itemID, e.spellID
    r.onClick = function(button) Tracker:OnEntryClick(e, button) end
    return r.text:GetStringWidth() + IND_TITLE + (hasCheck and LINE_H or 0)
end

-- Objectif : « - Barre de fer : 14/20 ». Maj+clic insère le lien de l'objet dans le chat (réflexe
-- attendu quand on demande à quelqu'un d'en apporter).
function Tracker:_PaintObjective(r, obj, y)
    reset(r, IND_OBJ, y, self.frame)
    textAt(r, 0)
    local name = (obj.itemID and GetItemInfo and GetItemInfo(obj.itemID)) or nil
    if not name and obj.itemID then
        local c = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
        name = (c and c.ItemName) and c:ItemName(obj.itemID) or ("item:" .. obj.itemID)
    end
    r.text:SetText("- " .. (name or "?") .. ": " .. obj.have .. "/" .. obj.need)
    r.text:SetTextColor(unpack(obj.done and COLOR.objDone or COLOR.obj))
    r.tipItemID = obj.itemID
    r.onClick = function()
        if not (IsShiftKeyDown and IsShiftKeyDown() and obj.itemID and GetItemInfo) then return end
        local link = select(2, GetItemInfo(obj.itemID))
        if link and ChatEdit_InsertLink then ChatEdit_InsertLink(link) end
    end
    return r.text:GetStringWidth() + IND_OBJ
end

-- Ligne d'information sans rôle interactif (réactifs inconnus, « +N de plus »).
function Tracker:_PaintNote(r, text, y, indent)
    reset(r, indent or IND_OBJ, y, self.frame)
    textAt(r, 0)
    r.text:SetText(text)
    r.text:SetTextColor(unpack(COLOR.unknown))
    return r.text:GetStringWidth() + (indent or IND_OBJ)
end

-- ------------------------------------------------------------------
-- Peinture complète
-- ------------------------------------------------------------------
-- Peint une entrée + ses objectifs à partir de la ligne `n`. Rend (n suivant, y suivant, largeur max).
function Tracker:_PaintEntry(e, n, y, maxW)
    local w = self:_PaintTitle(self:_Row(n), e, y)
    if w > maxW then maxW = w end
    n, y = n + 1, y - LINE_H
    if e.objectives == nil then
        -- Catalogue muet sur cette recette : on le DIT plutôt que d'afficher « prêt » à tort.
        w = self:_PaintNote(self:_Row(n), L["réactifs inconnus"], y)
        if w > maxW then maxW = w end
        n, y = n + 1, y - LINE_H
    else
        for _, obj in ipairs(e.objectives) do
            if n > MAX_LINES then return n, y, maxW end
            w = self:_PaintObjective(self:_Row(n), obj, y)
            if w > maxW then maxW = w end
            n, y = n + 1, y - LINE_H
        end
    end
    -- Remarques de l'entrée (« Plan à acheter : … ») : après les objectifs, comme une annotation.
    -- Elles portent leurs propres codes couleur — _PaintNote grise le reste, les |cFF…|r priment.
    for _, note in ipairs(e.notes or {}) do
        if n > MAX_LINES then return n, y, maxW end
        w = self:_PaintNote(self:_Row(n), note, y)
        if w > maxW then maxW = w end
        n, y = n + 1, y - LINE_H
    end
    return n, y, maxW
end

-- Peint tous les groupes et dimensionne le cadre (largeur au texte : aucun reflow dans WoW).
-- Rend le nombre de lignes peintes — 0 = rien à suivre, la coque masque le cadre.
function Tracker:Paint(groups, overflow)
    local n, y, maxW = 1, 0, 0
    local collapsed = (COC.db and COC.db.tracker and COC.db.tracker.collapsed) or {}
    -- `skipped` compte ce que le plafond de LIGNES fait tomber, en plus de ce que le plafond
    -- d'ENTRÉES avait déjà écarté : une liste tronquée en silence ferait croire à un suivi complet.
    -- Une section REPLIÉE ne compte pas — son en-tête affiche déjà son effectif.
    local skipped = overflow or 0
    for _, g in ipairs(groups) do
        if n > MAX_LINES then
            skipped = skipped + #g.entries
        else
            local w = self:_PaintHeader(self:_Row(n), g, y, collapsed[g.section])
            if w > maxW then maxW = w end
            n, y = n + 1, y - LINE_H
            if not collapsed[g.section] then
                for i, e in ipairs(g.entries) do
                    if n > MAX_LINES then skipped = skipped + (#g.entries - i + 1); break end
                    n, y, maxW = self:_PaintEntry(e, n, y, maxW)
                end
            end
        end
    end
    if skipped > 0 and n <= MAX_LINES then
        local w = self:_PaintNote(self:_Row(n), string.format(L["+%d de plus"], skipped), y, IND_TITLE)
        if w > maxW then maxW = w end
        n, y = n + 1, y - LINE_H
    end
    for i = n, #(self.rows or {}) do self.rows[i]:Hide() end
    if n > 1 then
        self.frame:SetSize(maxW + PAD_W, (n - 1) * LINE_H)
    end
    return n - 1
end
