-- CraftingOrderClassic_UI_Skin_Table.lua — l'EN-TÊTE DE TABLEAU triable (palier 5 de la revue
-- d'interface : le Carnet façon « Mes commandes » des Commandes d'artisanat de Forever).
--
-- Pourquoi pas TableBuilder, que la revue prévoyait : il construit en-têtes et cellules à partir de
-- GABARITS XML nommés (ConstructHeader / ConstructCells), et tous ceux de Blizzard vivent dans des
-- modules chargés à la demande (hôtel des ventes, commandes d'artisanat, JcJ) qu'on n'hérite pas
-- (risque 2) ; écrire les nôtres en XML irait contre la règle du kit. Ce qui fait l'ASPECT de ces
-- tableaux tient en deux pièces toujours chargées, qu'on reprend telles quelles : l'en-tête
-- `ColumnDisplayButtonShortTemplate` (SharedXML) — les en-têtes des métiers et de l'hôtel des ventes
-- en HÉRITENT — et la flèche `auctionhouse-ui-sortarrow`, retournée par ses coordonnées de texture
-- pour dire le sens (ProfessionsCrafterTableHeaderStringMixin:UpdateArrow). Les lignes restent sur
-- la liste défilante du kit, alignées sur les mêmes positions de colonnes.

local COC  = CraftingOrderClassic
local Skin = COC.UI.Skin

local OVERLAP = 2   -- les en-têtes se chevauchent de 2 px, comme ceux de « Mes commandes »

local function makeArrow(b)
    local a = b:CreateTexture(nil, "OVERLAY")
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("auctionhouse-ui-sortarrow") then
        a:SetAtlas("auctionhouse-ui-sortarrow", true)
    else
        a:SetTexture("Interface\\Buttons\\UI-SortArrow"); a:SetSize(9, 8)
    end
    a:SetPoint("LEFT", b.Text or b:GetFontString() or b, "RIGHT", 3, 0)
    a:Hide()
    return a
end

-- Une rangée d'en-têtes dans `parent`, sa ligne haute à `y`. `defs` = { { id, label, x, w,
-- sortable = true|false }, ... } : `x` = début de la COLONNE (le texte de l'en-tête s'y aligne,
-- le bouton démarre 8 px avant, là où le gabarit pose son texte), `w` = sa largeur. `onSort(id)`
-- au clic d'une colonne triable. Rend { buttons = { [id] = bouton }, SetSort(id, ascendant) } ;
-- SetSort(nil) cache toutes les flèches (tri par défaut).
function Skin.MakeSortHeader(parent, y, defs, onSort)
    local hdr = { buttons = {} }
    for _, d in ipairs(defs) do
        local ok, b = pcall(CreateFrame, "Button", nil, parent, "ColumnDisplayButtonShortTemplate")
        if not ok then
            b = CreateFrame("Button", nil, parent); b:SetHeight(19)
            b:SetNormalFontObject("GameFontHighlightSmall")
        end
        b:SetPoint("TOPLEFT", parent, "TOPLEFT", d.x - 8, y)
        b:SetWidth(d.w + OVERLAP)
        b:SetText(d.label)
        b.arrow = makeArrow(b)
        if d.sortable ~= false then
            b:SetScript("OnClick", function() onSort(d.id) end)
        else
            b:EnableMouse(false)
        end
        hdr.buttons[d.id] = b
    end
    function hdr:SetSort(id, ascending)
        for bid, b in pairs(self.buttons) do
            local on = (bid == id)
            b.arrow:SetShown(on)
            if on then
                if ascending then b.arrow:SetTexCoord(0, 1, 1, 0) else b.arrow:SetTexCoord(0, 1, 0, 1) end
            end
        end
    end
    return hdr
end
