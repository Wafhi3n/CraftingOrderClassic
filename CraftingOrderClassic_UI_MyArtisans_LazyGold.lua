-- CraftingOrderClassic_UI_MyArtisans_LazyGold.lua — onglet « Mes artisans » : couche Lazy Gold.
--   * barre d'outils : pièce (tri rentabilité), « 123 » (valeurs exactes, réglage PARTAGÉ avec la
--     vue métier), et « Tout le royaume » ;
--   * « Tout le royaume » = TOUS les métiers du compte fusionnés en une seule liste à plat triée par
--     profit : la réponse d'un coup d'œil à « lequel de mes rerolls a des sous à se faire ? ».
-- Lecture seule, inerte si Lazy Gold est absent.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local L    = COC.L

local function LG() local g = COC.LazyGold; return (g and g:IsAvailable()) and g or nil end

-- Profit d'une recette, MÉMORISÉ le temps du refresh (« Tout le royaume » balaie des centaines de
-- plans : sans mémo on interrogerait Auctionator autant de fois).
-- `rc` = entrée de la liste. Sans spellID (essence de désenchantement, poisson…) il n'y a pas de
-- « profit de craft » : la valeur de vente EST le gain (le coût, c'est du temps, pas des réactifs).
function UI:_MyArtProfit(rc)
    local g = LG()
    if not (g and rc) then return nil end
    self._myArtProfitCache = self._myArtProfitCache or {}
    local k = rc.sid and ((rc.profKey or "?") .. ":" .. rc.sid) or ("i" .. (rc.itemID or 0))
    local v = self._myArtProfitCache[k]
    if v == nil then
        if rc.sid then
            local p = g:CraftProfit(rc.profKey, rc.sid, 1)
            v = (p and p.profit) or false
        else
            v = (rc.itemID and g:ItemValue(rc.itemID)) or false
        end
        self._myArtProfitCache[k] = v
    end
    return v or nil
end

-- =========================================================================
-- Barre d'outils
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

-- NB : le bouton « Tous les plans du royaume » vit dans la COLONNE DE GAUCHE (cf. _UI_MyArtisans.lua) :
-- c'est une alternative à la sélection d'un métier, pas un outil de la liste de droite.
function UI:_BuildMyArtLGBar(panel, anchor)
    local sortBtn = makeToolBtn(panel, function()
        return UI.myArtSortProfit and L["Tri par rentabilité — clic pour A-Z."]
            or L["Trier par rentabilité (Lazy Gold)."]
    end, function()
        if not LG() then return end
        UI.myArtSortProfit = not UI.myArtSortProfit
        UI:RefreshMyArtisans()
    end)
    sortBtn:SetPoint("RIGHT", anchor, "LEFT", -6, 0)
    local coin = sortBtn:CreateTexture(nil, "ARTWORK")
    coin:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon"); coin:SetSize(13, 13); coin:SetPoint("CENTER")
    sortBtn.coin = coin
    self.myArtSortBtn = sortBtn

    local exactBtn = makeToolBtn(panel, function()
        local g = COC.LazyGold
        return (g and g:ExactMode()) and L["Valeurs exactes — clic pour l'affichage compact."]
            or L["Afficher les valeurs exactes (po/pa/pc)."]
    end, function()
        local g = LG(); if not g then return end
        g:SetExactMode(not g:ExactMode())
        UI:RefreshMyArtisans()
    end)
    exactBtn:SetPoint("RIGHT", sortBtn, "LEFT", -2, 0)
    local num = exactBtn:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    num:SetPoint("CENTER"); num:SetText("123"); exactBtn.num = num
    self.myArtExactBtn = exactBtn
end

function UI:_SyncMyArtLGBar()
    local g = LG()
    if self.myArtAllBtn then
        self.myArtAllBtn:SetShown(g and true or false)
        self.myArtAllBtn:SetSelected(self.myArtAllProfs and true or false)
    end
    if self.myArtSortBtn then
        -- En mode « tout le royaume » le tri par profit est imposé : le bouton reste allumé, mais
        -- l'éteindre n'aurait pas de sens → on le désactive visuellement plutôt que de mentir.
        local on = g and (self.myArtSortProfit or self.myArtAllProfs)
        self.myArtSortBtn:SetShown(g and true or false)
        self.myArtSortBtn.onBG:SetShown(on and true or false)
        self.myArtSortBtn.coin:SetDesaturated(not on)
    end
    if self.myArtExactBtn then
        local ex = g and g:ExactMode()
        self.myArtExactBtn:SetShown(g and true or false)
        self.myArtExactBtn.onBG:SetShown(ex and true or false)
        self.myArtExactBtn.num:SetTextColor(ex and 1 or 0.55, ex and 0.82 or 0.55, ex and 0.29 or 0.55)
    end
end

-- =========================================================================
-- Listes à plat
-- =========================================================================
-- Tri décroissant par profit (les plans sans prix tombent à 0, donc en fin de liste).
function UI:_MyArtSortByProfit(recs)
    for _, rc in ipairs(recs) do rc._profit = self:_MyArtProfit(rc) or 0 end
    table.sort(recs, function(a, b)
        if a._profit ~= b._profit then return a._profit > b._profit end
        return (a.name or "") < (b.name or "")
    end)
    return recs
end

-- « Tous les plans du royaume » : les recettes CONNUES de tous les métiers du compte (MÊME FACTION —
-- le filtre est fait en amont par Dir:AggregateMyProfs), en une liste à plat triée par profit. On n'y
-- met PAS les manquantes : la question posée est « que puis-je fabriquer MAINTENANT pour gagner de
-- l'or », pas « que pourrais-je apprendre ».
-- `itemsOf` apporte les produits SANS recette (désenchantement, poissons…) : eux aussi rapportent.
function UI:_MyArtAllList(profs, entryOf, itemsOf)
    local recs = {}
    for _, e in ipairs(profs) do
        for sid in pairs(e.known) do recs[#recs + 1] = entryOf(e, sid, false) end
        for _, it in ipairs(itemsOf and itemsOf(e) or {}) do recs[#recs + 1] = it end
    end
    return self:_MyArtSortByProfit(recs)
end
