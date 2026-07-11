-- CraftingOrderClassic_UI_Post_LazyGold.lua — onglet « Commande » : couche Lazy Gold (lecture seule).
--   * barre d'outils (pièce = tri par rentabilité, « 123 » = valeurs exactes) — mêmes codes que la
--     vue métier, et le mode exact est le MÊME réglage partagé (db.lgExactProfit) ;
--   * indicateur de profit sur chaque ligne de la LISTE DES PLANS ;
--   * tri par rentabilité : liste à PLAT (les sections disparaissent), du plus rentable au moins.
-- Tout est masqué/inerte si Lazy Gold n'est pas installé — COC reste autonome.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local L    = COC.L

local function LG() local g = COC.LazyGold; return (g and g:IsAvailable()) and g or nil end

-- =========================================================================
-- Barre d'outils (au-dessus de la liste des plans, à droite de « LISTE DES PLANS »)
-- =========================================================================
local function makeToolBtn(panel, tipFn, onClick)
    local b = CreateFrame("Button", nil, panel)
    b:SetSize(18, 18)
    local on = b:CreateTexture(nil, "BACKGROUND")
    on:SetAllPoints(); on:SetColorTexture(0.91, 0.72, 0.29, 0.30); on:Hide(); b.onBG = on
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:SetScript("OnClick", onClick)
    b:SetScript("OnEnter", function(s)
        GameTooltip:SetOwner(s, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText(tipFn(), 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    return b
end

function UI:_BuildPostLGBar(panel, anchor)
    local sortBtn = makeToolBtn(panel, function()
        return UI.postSortProfit and L["Tri par rentabilité — clic pour A-Z."]
            or L["Trier par rentabilité (Lazy Gold)."]
    end, function()
        if not LG() then return end
        UI.postSortProfit = not UI.postSortProfit
        UI:_SyncPostLGBar(); UI:RefreshPostPlans()
    end)
    sortBtn:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", 0, 2)
    local coin = sortBtn:CreateTexture(nil, "ARTWORK")
    coin:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon"); coin:SetSize(13, 13); coin:SetPoint("CENTER")
    sortBtn.coin = coin
    self.postSortBtn = sortBtn

    local exactBtn = makeToolBtn(panel, function()
        local g = COC.LazyGold
        return (g and g:ExactMode()) and L["Valeurs exactes — clic pour l'affichage compact."]
            or L["Afficher les valeurs exactes (po/pa/pc)."]
    end, function()
        local g = LG(); if not g then return end
        g:SetExactMode(not g:ExactMode())
        UI:_SyncPostLGBar(); UI:RefreshPostPlans(); UI:_RefreshPostPriceHint(UI.postEntry)
    end)
    exactBtn:SetPoint("RIGHT", sortBtn, "LEFT", -2, 0)
    local num = exactBtn:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    num:SetPoint("CENTER"); num:SetText("123"); exactBtn.num = num
    self.postExactBtn = exactBtn
    self:_SyncPostLGBar()
end

function UI:_SyncPostLGBar()
    local g = LG()
    if self.postSortBtn then
        self.postSortBtn:SetShown(g and true or false)
        self.postSortBtn.onBG:SetShown((g and self.postSortProfit) and true or false)
        self.postSortBtn.coin:SetDesaturated(not (g and self.postSortProfit))
    end
    if self.postExactBtn then
        local ex = g and g:ExactMode()
        self.postExactBtn:SetShown(g and true or false)
        self.postExactBtn.onBG:SetShown(ex and true or false)
        self.postExactBtn.num:SetTextColor(ex and 1 or 0.55, ex and 0.82 or 0.55, ex and 0.29 or 0.55)
    end
end

-- =========================================================================
-- Profit d'une ligne de plan
-- =========================================================================
-- MÉMORISÉ le temps du refresh : le rendu se refait à chaque scroll (pool virtualisé), on
-- interrogerait sinon Auctionator en boucle. `false` = calculé, sans valeur exploitable.
function UI:_PostRowProfit(e)
    local g = LG()
    if not (g and e and e.spellID and self.postProf) then return nil end
    self._postProfitCache = self._postProfitCache or {}
    local k = e.spellID
    local v = self._postProfitCache[k]
    if v == nil then
        local p = g:CraftProfit(self.postProf, e.spellID, 1)
        v = (p and p.profit) or false
        self._postProfitCache[k] = v
    end
    return v or nil
end

-- Colonne de droite d'une ligne de plan. Rétrécit le nom pour ne pas chevaucher.
function UI:_FillPostPlanProfit(row, item)
    if not row.profit then return end
    local g = LG()
    local txt = g and item.e and g:ProfitText(self:_PostRowProfit(item.e)) or ""
    if txt == "" then
        row.profit:Hide()
        row.name:SetWidth(math.max(20, row:GetWidth() - 26 - (item._sub and 14 or 0)))
        return
    end
    row.profit:SetText(txt); row.profit:Show()
    row.name:SetWidth(math.max(20, row:GetWidth() - 26 - (item._sub and 14 or 0) - row.profit:GetStringWidth() - 6))
end

-- =========================================================================
-- Tri par rentabilité : liste À PLAT (pas de sections — on veut le classement global)
-- =========================================================================
-- Renvoie nil si le tri n'est pas actif : l'appelant retombe alors sur le regroupement normal.
function UI:_PostProfitFlat(list)
    if not (self.postSortProfit and LG()) then return nil end
    local items = {}
    for _, it in ipairs(list) do
        it._profit = self:_PostRowProfit(it.e) or 0
        items[#items + 1] = it
    end
    table.sort(items, function(a, b)
        if a._profit ~= b._profit then return a._profit > b._profit end
        return (a.name or "") < (b.name or "")
    end)
    return items
end
