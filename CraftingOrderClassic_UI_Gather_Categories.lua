-- CraftingOrderClassic_UI_Gather_Categories.lua — onglet « Récolte », panneau gauche : repliage des
-- en-têtes et remplissage des lignes (en-tête de section/sous-catégorie, ou ressource). Extrait de
-- _UI_Gather.lua (anti-monolithe) ; même namespace UI, même patron que _UI_Post_Categories.lua.
--
-- Le REGROUPEMENT lui-même (sections, sous-catégories, tri) est délégué à COC.RecipeCats:BuildDisplay,
-- appelé par RefreshGatherList — un métier de récolte sans table de catégories déclarée garde la
-- liste plate d'avant. Particularité de la récolte : une peau ou un minerai n'est PAS une recette,
-- donc il n'a pas de niveau `learnedAt` ; c'est l'ordre déclaré dans _RecipeCats_Gathering.lua qui
-- fait foi (voir le contrat dans _RecipeCats.lua).

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

-- État de repliage des en-têtes, mémorisé PAR MÉTIER de récolte (durée de session).
function UI:_GatherCollapseTable()
    self.gatherCollapsed = self.gatherCollapsed or {}
    local k = self.gatherProf or "?"
    self.gatherCollapsed[k] = self.gatherCollapsed[k] or {}
    return self.gatherCollapsed[k]
end

function UI:ToggleGatherSection(ckey)
    if not ckey then return end
    local col = self:_GatherCollapseTable()
    col[ckey] = (not col[ckey]) or nil
    self:RefreshGatherList()
end

-- Hauteur d'une ligne, lue par la liste défilante pour chaque donnée : mêmes mesures que la liste
-- des plans de Commande (une section porte la barre d'en-tête des métiers, plus haute).
local H_SECTION, H_SUB, H_RES = 25, 20, 20
function UI:_GatherResExtent(item)
    if item.isHeader then return item.depth == 2 and H_SUB or H_SECTION end
    return H_RES
end

-- En-tête : barre sombre et libellé doré pour une section, libellé bronze indenté sans barre pour une
-- sous-catégorie, compte en gris, +/- à DROITE comme la liste des métiers (Skin.ListRowKind).
-- Cliquable → replie/déplie (OnClick de _BuildGatherResRow). Pendant une recherche, tout est ouvert.
function UI:_FillGatherHeader(row, item)
    local sub  = (item.depth == 2)
    local open = not self:_GatherCollapseTable()[item.ckey] or (self.gatherSearch or "") ~= ""
    row.badge:Hide(); row.name:Hide(); row.stack:SetText(""); row.tipItemID = nil
    Skin.ListRowKind(row, sub and "subheader" or "header", not open)
    local label = item.label or ""
    if item.count and item.count > 0 then label = label .. string.format(" |cFF888888(%d)|r", item.count) end
    row.hdr:SetFontObject(sub and "GameFontNormalSmall" or "GameFontNormal")
    row.hdr:ClearAllPoints()
    row.hdr:SetPoint("LEFT", sub and 14 or 8, 0)
    row.hdr:SetPoint("RIGHT", row.collapse, "LEFT", -4, 0)
    row.hdr:SetText(label); row.hdr:Show()
    if sub then row.hdr:SetTextColor(0.79, 0.64, 0.15) else row.hdr:SetTextColor(Skin.unpack(Skin.color.gold)) end
end

-- Ressource : badge de rareté + nom (indenté sous sa sous-catégorie). La ressource choisie porte la
-- surbrillance de sélection des métiers au lieu de voir son nom repeint en or : la couleur d'un objet
-- dit sa RARETÉ, et le chrome n'y touche pas (invariant du kit).
function UI:_FillGatherRow(row, item)
    if item.isHeader then return self:_FillGatherHeader(row, item) end
    Skin.ListRowKind(row, "item")
    row.hdr:Hide()
    local e = item.e
    local indent = item._sub and 14 or 0
    local r, g, b = Skin.RarityColor(e.itemID)
    row.badge:ClearAllPoints(); row.badge:SetPoint("LEFT", 2 + indent, 0); row.badge:Show()
    row.badge:Paint(r, g, b, Skin.FirstChar(item.name), Skin.Icon(e.itemID))
    row.name:ClearAllPoints(); row.name:SetPoint("LEFT", 20 + indent, 0)
    row.name:SetPoint("RIGHT", row.stack, "LEFT", -6, 0)
    local disp = item.name:match("^item:") and ("|cFF777777" .. L["Chargement…"] .. "|r") or item.name
    row.name:SetText(disp); row.name:SetTextColor(r, g, b); row.name:Show()
    row.selected:SetShown(e == self.gatherEntry)
    -- Valeur HV Auctionator (à droite) : prix vendeur ou hôtel des ventes. Vide si Auctionator absent ou
    -- prix inconnu. C'est l'usage phare de Auctionator pour la récolte (cf. sa vue Minage).
    local val = COC.Profit and COC.Profit:ItemValue(e.itemID)
    row.stack:SetText(val and COC.Api.Coin(val) or "")
    row.tipItemID = e.itemID
end
