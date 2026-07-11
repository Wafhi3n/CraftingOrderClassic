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

-- En-tête : chevron +/- (TEXTURE native — la police rend « ▾ » en tofu), libellé doré (section) ou
-- bronze (sous-catégorie, indentée), et compte. Cliquable → replie/déplie.
function UI:_FillGatherHeader(row, item)
    local sub  = (item.depth == 2)
    local open = not self:_GatherCollapseTable()[item.ckey] or (self.gatherSearch or "") ~= ""
    row.badge:Hide(); row.stack:SetText(""); row.entry = nil; row.tipItemID = nil
    row.expand:SetTexture(open and "Interface\\Buttons\\UI-MinusButton-Up" or "Interface\\Buttons\\UI-PlusButton-Up")
    row.expand:ClearAllPoints(); row.expand:SetPoint("LEFT", sub and 14 or 2, 0); row.expand:Show()
    row.name:ClearAllPoints(); row.name:SetPoint("LEFT", row.expand, "RIGHT", 2, 0)
    local cnt = (item.count and item.count > 0) and string.format(" |cFF888888(%d)|r", item.count) or ""
    row.name:SetText((sub and "|cFFC9A227" or "|cFFE8B84B") .. (item.label or "") .. "|r" .. cnt)
    row.name:SetTextColor(1, 1, 1)
    local ckey = item.ckey
    row:SetScript("OnClick", function() UI:ToggleGatherSection(ckey) end)
end

-- Ressource : badge de rareté + nom (indenté sous sa sous-catégorie), sélection en doré.
function UI:_FillGatherRow(row, item)
    local e = item.e
    local indent = item._sub and 14 or 0
    local r, g, b = Skin.RarityColor(e.itemID)
    row.expand:Hide()
    row.badge:ClearAllPoints(); row.badge:SetPoint("LEFT", 2 + indent, 0); row.badge:Show()
    row.badge:Paint(r, g, b, Skin.FirstChar(item.name), Skin.Icon(e.itemID))
    row.name:ClearAllPoints(); row.name:SetPoint("LEFT", 20 + indent, 0)
    local disp = item.name:match("^item:") and ("|cFF777777" .. L["Chargement…"] .. "|r") or item.name
    row.name:SetText(disp); row.name:SetTextColor(r, g, b)
    if e == self.gatherEntry then row.name:SetTextColor(1, 0.85, 0.27) end
    -- Valeur HV Lazy Gold (à droite) : prix vendeur ou hôtel des ventes. Vide si Lazy Gold absent ou
    -- prix inconnu. C'est l'usage phare de Lazy Gold pour la récolte (cf. sa vue Minage).
    local val = COC.LazyGold and COC.LazyGold:ItemValue(e.itemID)
    row.stack:SetText(val and GetCoinTextureString(val) or "")
    row.entry = e; row.tipItemID = e.itemID
    row:SetScript("OnClick", function() UI:SelectGatherItem(e) end)
end
