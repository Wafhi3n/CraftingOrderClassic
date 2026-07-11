-- CraftingOrderClassic_ProfWindow_Info.lua — PANNEAU D'INFO en SECTIONS pour la colonne centrale de la
-- vue métier. Affiché à la place des réactifs quand la recette sélectionnée n'est pas apprise (mode
-- « manquantes »). Conçu comme un CADRE EXTENSIBLE : chaque bloc d'info est une SECTION fournie par une
-- fonction enregistrée, pour brancher facilement d'autres addons plus tard (une idée = une section).
--
-- ENREGISTRER UNE SECTION :
--   COC.ProfWindow:RegisterInfoSection(function(ctx)
--       -- ctx = { profKey = <clé métier>, entry = <recette sélectionnée> }
--       -- retourne { title = <libellé>, lines = { { label = , value = }, ... } }  ou nil pour rien afficher
--   end)
-- Les sections sont rendues dans l'ordre d'enregistrement ; celles qui renvoient nil sont sautées.
-- `label` peut être "" (ligne de continuation, ex. PNJ supplémentaires sous « Vendu par »).

local COC = CraftingOrderClassic
local PW  = COC.ProfWindow
local L   = COC.L

local ROW_H, LABEL_W, MAX_ROWS = 15, 92, 24

PW.infoSections = PW.infoSections or {}

function PW:RegisterInfoSection(fn)
    if type(fn) == "function" then self.infoSections[#self.infoSections + 1] = fn end
end

-- Une ligne du pool : sert SOIT d'en-tête de section (titre doré + filet), SOIT de ligne de données
-- (libellé à gauche, valeur à droite). Créée à la demande dans la colonne détail.
-- Une ligne du pool : en-tête de section (titre doré + filet), ou ligne de données (libellé + valeur).
-- La VALEUR s'enroule sur plusieurs lignes (les sources MTSL — « [54] Brikk Keencraft — Forge (23, 55) »
-- — dépassent largement la colonne) : sa largeur est posée au rendu et la hauteur de la ligne suit.
local function buildRow(col)
    local row = CreateFrame("Frame", nil, col)
    row:SetHeight(ROW_H)
    local hdr = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr:SetPoint("BOTTOMLEFT", 2, 3); hdr:SetJustifyH("LEFT"); hdr:SetTextColor(0.91, 0.72, 0.29); row.hdr = hdr
    local line = row:CreateTexture(nil, "ARTWORK"); line:SetHeight(1)
    line:SetColorTexture(0.91, 0.72, 0.25, 0.25)
    line:SetPoint("BOTTOMLEFT", 2, 1); line:SetPoint("BOTTOMRIGHT", -2, 1); row.hline = line
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", 4, -1); label:SetWidth(LABEL_W); label:SetJustifyH("LEFT")
    label:SetTextColor(0.72, 0.66, 0.5); row.label = label
    local value = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    value:SetJustifyH("LEFT"); value:SetWordWrap(true); value:SetTextColor(1, 1, 1); row.value = value
    row:Hide(); return row
end

function PW:_EnsureInfoPool()
    if self.infoRows then return end
    local col = self.detColFrame; if not col then return end
    self.infoRows = {}
    for i = 1, MAX_ROWS do self.infoRows[i] = buildRow(col) end   -- ancrage vertical posé au rendu (startY variable)
end

local function fillHeader(row, title)
    row.label:Hide(); row.value:Hide()
    row.hdr:SetText(title or ""); row.hdr:Show(); row.hline:Show()
    row:SetHeight(ROW_H)
    return ROW_H
end

-- Remplit une ligne de données et RENVOIE sa hauteur (le texte peut tenir sur plusieurs lignes).
-- `label` vide = ligne de CONTINUATION (ex. PNJ suivants) : la valeur prend alors TOUTE la largeur,
-- ce qui récupère la colonne de libellé et évite de tronquer.
local function fillLine(row, ln, colW)
    row.hdr:Hide(); row.hline:Hide()
    local hasLabel = (ln.label or "") ~= ""
    row.label:SetText(hasLabel and ("|cFFCBB79A" .. ln.label .. "|r") or "")
    row.label:SetShown(hasLabel)
    row.value:ClearAllPoints()
    local indent = hasLabel and (LABEL_W + 8) or 10
    row.value:SetPoint("TOPLEFT", row, "TOPLEFT", indent, -1)
    row.value:SetWidth(math.max(40, colW - indent - 8))
    row.value:SetText(ln.value or ""); row.value:Show()
    local h = math.max(ROW_H, math.ceil(row.value:GetStringHeight() or 0) + 3)
    row:SetHeight(h)
    return h
end

-- Rend toutes les sections (en-tête + lignes) dans le pool, empilées depuis `startY` (offset Y sous le
-- haut de la colonne détail : ~-52 pour une recette manquante — zone libre ; plus bas pour une recette
-- apprise, sous les réactifs). Une section vide (nil ou sans ligne) est sautée. Retourne le nombre de
-- lignes rendues (0 = rien à montrer). Tronque au-delà de MAX_ROWS (ne devrait pas arriver).
function PW:_RenderInfoPanel(entry, startY)
    self:_EnsureInfoPool()
    if not self.infoRows then return 0 end
    startY = startY or -52
    local col = self.detColFrame
    local colW = (col and col:GetWidth() or 240) - 14   -- largeur utile (marges gauche/droite du panneau)
    local ctx = { profKey = self.profKey, entry = entry }
    -- On empile les lignes en cumulant leur hauteur RÉELLE : une valeur longue (source MTSL) tient sur
    -- plusieurs lignes, donc un pas fixe se chevaucherait.
    local n, y = 0, startY
    local function place(row, h)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", col, "TOPLEFT", 8, y)
        row:SetPoint("RIGHT", col, "RIGHT", -6, 0)
        row:Show()
        y = y - h
    end
    for _, fn in ipairs(self.infoSections) do
        local ok, sec = pcall(fn, ctx)
        if ok and sec and sec.lines and #sec.lines > 0 then
            if n < MAX_ROWS then
                n = n + 1
                place(self.infoRows[n], fillHeader(self.infoRows[n], sec.title))
            end
            for _, ln in ipairs(sec.lines) do
                if n < MAX_ROWS then
                    n = n + 1
                    place(self.infoRows[n], fillLine(self.infoRows[n], ln, colW))
                end
            end
        end
    end
    for i = n + 1, #self.infoRows do self.infoRows[i]:Hide() end
    return n
end

function PW:_HideInfoPanel()
    if not self.infoRows then return end
    for _, row in ipairs(self.infoRows) do row:Hide() end
end

-- Section INTÉGRÉE : « Où l'obtenir » via le pont MTSL (formateur/vendeur/butin + PNJ, zone, coords).
-- Nil si MTSL absent ou si la recette n'a pas de fiche → la section ne s'affiche simplement pas.
PW:RegisterInfoSection(function(ctx)
    local M = COC.MTSL
    if not (M and M:IsAvailable() and ctx.entry and ctx.entry.spellID) then return nil end
    local d = M:SkillDetail(ctx.profKey, ctx.entry.spellID)
    if not (d and d.lines and #d.lines > 0) then return nil end
    return { title = L["Où l'obtenir"], lines = d.lines }
end)
