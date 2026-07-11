-- CraftingOrderClassic_ProfWindow_Recipes.lua — colonne GAUCHE : liste de recettes virtualisée
-- (scroll), recherche, couleur par difficulté, sélection, badge « demandé » (nb de commandes
-- ouvertes pour l'objet). Port de TradeScanner_ProfWindow_Recipes.lua adapté à COC.Craft.

local COC = CraftingOrderClassic
local PW  = COC.ProfWindow
local L   = COC.L

-- ROW_H = hauteur d'une ligne ; VISIBLE = taille du POOL de lignes physiques réutilisées.
-- INVARIANT : VISIBLE doit être ≥ au nb de lignes que le viewport peut afficher, sinon les
-- derniers items sont INatteignables (le scroll max = n - viewportRows ; le plus grand index
-- rendu = maxOff + VISIBLE ; s'il est < n, la queue de liste ne s'affiche jamais).
-- Viewport recettes ≈ 398 px (col 430 - 26 haut - 6 bas) / 16 ≈ 25 lignes → 26 avec marge.
-- (bug 2026-07-01 : à 23, Bolt of Woolen/Linen Cloth manquaient en bas de la Couture.)
local ROW_H, VISIBLE = 16, 26

function PW:_BuildRecipeRow(parent, i)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(196, ROW_H); row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
    local sel = row:CreateTexture(nil, "BACKGROUND"); sel:SetAllPoints()
    sel:SetColorTexture(0.91, 0.72, 0.29, 0.22); sel:Hide(); row.sel = sel
    local hi = row:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints(); hi:SetColorTexture(0.25, 0.45, 0.85, 0.25)
    -- Chevron +/- des en-têtes : TEXTURE native (la police rend « ▾ » en tofu, cf. Skin).
    local expand = row:CreateTexture(nil, "ARTWORK")
    expand:SetSize(ROW_H - 2, ROW_H - 2); expand:Hide(); row.expand = expand
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ROW_H - 2, ROW_H - 2); icon:SetPoint("LEFT", 1, 0); icon:SetTexCoord(0.07, 0.93, 0.07, 0.93); row.icon = icon
    local nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameFS:SetPoint("LEFT", icon, "RIGHT", 4, 0); nameFS:SetPoint("RIGHT", -2, 0)
    nameFS:SetJustifyH("LEFT"); nameFS:SetWordWrap(false); row.nameFS = nameFS
    -- Profit Lazy Gold (le plus à droite), puis badge « demandé » à sa gauche. Les deux masqués par défaut.
    local profit = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    profit:SetPoint("RIGHT", -2, 0); profit:Hide(); row.profit = profit
    local badge = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    badge:SetPoint("RIGHT", -2, 0); badge:Hide(); row.badge = badge
    row:SetScript("OnClick", function(r)
        local e = r.entry; if not e then return end
        if e.isHeader then PW:ToggleRecipeSection(e.ckey) else PW:SelectRecipe(e) end
    end)
    row:SetScript("OnEnter", function(r) PW:_RecipeTooltip(r) end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:Hide(); return row
end

-- Petit bouton bascule de la barre d'outils Recettes : fond doré quand actif, survol, tooltip DYNAMIQUE
-- (tipFn est évalué au survol, pas à la construction — le libellé dépend de l'état courant).
local function makeToolBtn(col, tipFn, onClick)
    local b = CreateFrame("Button", nil, col)
    b:SetSize(20, 20)
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

function PW:_BuildRecipes(col)
    local hdr = col:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr:SetPoint("TOPLEFT", 8, -6); hdr:SetText("|cFFE8B84B" .. L["Recettes"] .. "|r")
    self.recHdr = hdr

    local search = CreateFrame("EditBox", nil, col, "InputBoxTemplate")
    search:SetSize(92, 16); search:SetPoint("TOPRIGHT", -10, -6); search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", function(b) PW.recipeSearch = (b:GetText() or ""):lower(); PW:RefreshRecipes() end)
    search:SetScript("OnEscapePressed", function(b) b:SetText(""); b:ClearFocus() end)
    self.recipeSearchBox = search

    -- Barre d'outils Lazy Gold, à gauche de la recherche. Les deux boutons sont MASQUÉS si Lazy Gold
    -- n'est pas installé (cf. _SyncSortHeader) : ni tri ni valeurs sans données de prix.
    --   pièce d'or  → tri par rentabilité : liste à PLAT du plus rentable au moins (plus de catégories)
    --   « 123 »     → valeurs EXACTES (po/pa/pc) au lieu de l'indicateur compact en paliers de pièces
    local sortBtn = makeToolBtn(col, function()
        return PW.recipeSortProfit and L["Tri par rentabilité — clic pour A-Z."]
            or L["Trier par rentabilité (Lazy Gold)."]
    end, function() PW:_ToggleRecipeSort() end)
    sortBtn:SetPoint("RIGHT", search, "LEFT", -6, 0)
    local coin = sortBtn:CreateTexture(nil, "ARTWORK")
    coin:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon"); coin:SetSize(14, 14); coin:SetPoint("CENTER")
    sortBtn.coin = coin
    self.recSortBtn = sortBtn

    local exactBtn = makeToolBtn(col, function()
        return (COC.LazyGold and COC.LazyGold:ExactMode()) and L["Valeurs exactes — clic pour l'affichage compact."]
            or L["Afficher les valeurs exactes (po/pa/pc)."]
    end, function() PW:_ToggleProfitExact() end)
    exactBtn:SetPoint("RIGHT", sortBtn, "LEFT", -2, 0)
    local num = exactBtn:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    num:SetPoint("CENTER"); num:SetText("123"); exactBtn.num = num
    self.recExactBtn = exactBtn

    local scroll = CreateFrame("ScrollFrame", "CraftingOrderProfWinRecScroll", col, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 6, -26); scroll:SetPoint("BOTTOMRIGHT", -24, 6)
    local content = CreateFrame("Frame", nil, scroll); content:SetSize(196, VISIBLE * ROW_H); scroll:SetScrollChild(content)
    scroll:HookScript("OnVerticalScroll", function() PW:RenderRecipes() end)
    self.recScroll, self.recContent = scroll, content
    self.recRows = {}
    for i = 1, VISIBLE do self.recRows[i] = self:_BuildRecipeRow(content, i) end
end

function PW:_RecipeTooltip(row)
    local e = row.entry; if not e or e.isHeader then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT"); GameTooltip:ClearLines()
    local ok = false
    if e.link then ok = pcall(GameTooltip.SetHyperlink, GameTooltip, e.link)
    -- Recette MANQUANTE : ni lien ni index d'API (elle n'est pas dans la fenêtre native) → on montre le
    -- tooltip de l'OBJET PRODUIT via son itemID, au lieu du nom nu.
    elseif e.isMissing and e.itemID then
        ok = pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. e.itemID)
    elseif e.index and COC.Craft:IsCraftOpen() then ok = pcall(GameTooltip.SetCraftSpell, GameTooltip, e.index)
    elseif e.index then ok = pcall(GameTooltip.SetTradeSkillItem, GameTooltip, e.index) end
    if not ok then GameTooltip:SetText(e.name or "?", 1, 1, 1) end
    -- Valeur EXACTE du profit au survol (l'indicateur de ligne n'est qu'un palier compact). Uniquement
    -- si POSITIF : on ne met rien pour une recette non rentable (le but est d'être rentable).
    local prof = self:_RowProfit(e)
    if prof and prof > 0 then
        GameTooltip:AddLine(L["Profit net"] .. " : |cFF33DD33" .. GetCoinTextureString(prof) .. "|r", 1, 1, 1)
    end
    GameTooltip:Show()
end

-- Carte « demandé » : itemID → nb de commandes ouvertes (carnet + entrantes) du métier.
function PW:_ComputeWantedMap()
    local map = {}
    local function add(o)
        if o.itemID then local m = map[o.itemID] or { count = 0 }; m.count = m.count + 1; map[o.itemID] = m end
    end
    for _, o in pairs((COC.db and COC.db.orders) or {}) do
        if o.profession == self.profKey and o.status ~= "cancelled" and o.status ~= "done" then add(o) end
    end
    for _, e in pairs((COC.db and COC.db.inbound) or {}) do
        if e.profession == self.profKey and e.status ~= "dismissed" then add(e) end
    end
    return map
end

-- État de repliage, MÉMORISÉ PAR MÉTIER (durée de session).
function PW:_CollapseTable()
    self.recCollapsed = self.recCollapsed or {}
    local k = self.profKey or "?"
    self.recCollapsed[k] = self.recCollapsed[k] or {}
    return self.recCollapsed[k]
end

function PW:ToggleRecipeSection(ckey)
    if not ckey then return end
    local col = self:_CollapseTable()
    col[ckey] = (not col[ckey]) or nil
    self:RefreshRecipes()
end

-- Liste d'affichage : filtre de recherche, puis le regroupement partagé (COC.RecipeCats:BuildDisplay)
-- fait tout le reste — sections, sous-catégories, tri par niveau décroissant, en-têtes, repliage.
-- Pendant une RECHERCHE on ignore le repliage : sinon un résultat pourrait rester invisible sous un
-- en-tête fermé.
-- Clé de sélection STABLE d'une recette : les recettes MANQUANTES (mode MTSL) n'ont pas d'index d'API
-- (elles ne sont pas dans la fenêtre native) → on les sélectionne par spellID ; les connues par index.
local function entryKey(e)
    if not e then return nil end
    if e.isMissing then return "s" .. (e.spellID or 0) end
    return "i" .. (e.index or 0)
end

-- Liste ACTIVE de recettes. Mode normal : les recettes APPRISES (fenêtre native). Mode « manquantes »
-- armé : l'UNION apprises + non-apprises (pont MTSL), pour montrer TOUT l'arbre du métier d'un coup —
-- les manquantes s'intercalent dans leurs sous-catégories, par niveau, et seront peintes en ROUGE
-- (cf. _FillRecipeRow). Les manquantes n'ont pas d'index d'API → sélectionnées par spellID (entryKey).
-- Le mode n'a de sens que sur SON propre métier ouvert : désarmé hors mode plein (cf. ProfWindow).
function PW:_ActiveRecipes()
    if not (self.missingMode and COC.MTSL) then return self.recipes or {} end
    local out = {}
    for _, r in ipairs(self.recipes or {}) do out[#out + 1] = r end
    for _, m in ipairs(COC.MTSL:MissingRecipes(self.profKey) or {}) do out[#out + 1] = m end
    return out
end

-- Bascule le tri par rentabilité (sans effet si Lazy Gold absent). Met à jour l'en-tête + rafraîchit.
function PW:_ToggleRecipeSort()
    if not (COC.LazyGold and COC.LazyGold:IsAvailable()) then return end
    self.recipeSortProfit = not self.recipeSortProfit
    self:_SyncSortHeader()
    self:RefreshRecipes()
end

-- Bascule l'affichage compact ↔ valeurs exactes (po/pa/pc). Préférence PERSISTÉE (db.lgExactProfit) :
-- c'est un confort de lecture, il doit survivre au /reload.
function PW:_ToggleProfitExact()
    local LG = COC.LazyGold
    if not (LG and LG:IsAvailable()) then return end
    LG:SetExactMode(not LG:ExactMode())
    self:_SyncSortHeader()
    self:RefreshRecipes()
end

-- Reflète l'état des deux boutons (fond doré = actif) + le libellé de l'en-tête. Boutons masqués si
-- Lazy Gold est absent — inutile de proposer un tri ou des prix sans données.
function PW:_SyncSortHeader()
    local LG = COC.LazyGold
    local ok = LG and LG:IsAvailable()
    local on = self.recipeSortProfit and ok
    if self.recSortBtn then
        self.recSortBtn:SetShown(ok and true or false)
        if self.recSortBtn.onBG then self.recSortBtn.onBG:SetShown(on and true or false) end
        if self.recSortBtn.coin then self.recSortBtn.coin:SetDesaturated(not on) end
    end
    if self.recExactBtn then
        local ex = ok and LG:ExactMode()
        self.recExactBtn:SetShown(ok and true or false)
        self.recExactBtn.onBG:SetShown(ex and true or false)
        self.recExactBtn.num:SetTextColor(ex and 1 or 0.55, ex and 0.82 or 0.55, ex and 0.29 or 0.55)
    end
    if self.recHdr then
        self.recHdr:SetText("|cFFE8B84B" .. (on and L["Par rentabilité"] or L["Recettes"]) .. "|r")
    end
end

function PW:_RecipeDisplayList()
    local raw, search = self:_ActiveRecipes(), self.recipeSearch
    self._active = raw   -- mémorisé pour GetSelectedRecipe (résolution par clé, cf. entryKey)
    local sortProfit = self.recipeSortProfit and COC.LazyGold and COC.LazyGold:IsAvailable()
    local items = {}
    for _, r in ipairs(raw) do
        if not r.isHeader and (not search or search == "" or (r.name and r.name:lower():find(search, 1, true))) then
            if sortProfit then r._profit = self:_RowProfit(r) end   -- pré-calc (mémorisé) pour le tri
            items[#items + 1] = r
        end
    end
    -- Tri « rentabilité » (Lazy Gold) : on ABANDONNE le regroupement — liste À PLAT, sans en-tête ni
    -- sous-catégorie, du plus rentable au moins rentable. C'est le but du mode : voir d'un coup quoi
    -- fabriquer en premier, peu importe la famille. Profit inconnu / à perte → en fin de liste.
    if sortProfit then
        table.sort(items, function(a, b)
            local pa, pb = a._profit or -math.huge, b._profit or -math.huge
            if pa ~= pb then return pa > pb end
            return (a.name or "") < (b.name or "")
        end)
        return items
    end
    return COC.RecipeCats:BuildDisplay(self.profKey, items, {
        itemID    = function(r) return r.itemID end,
        name      = function(r) return r.name or "" end,
        collapsed = ((search or "") ~= "") and nil or self:_CollapseTable(),
    })
end

function PW:RefreshRecipes()
    if not self.recScroll then return end
    self._profitCache = {}   -- invalidé à chaque refresh (prix Auctionator ont pu changer)
    self:_SyncSortHeader()   -- affiche/masque le bouton de tri selon la présence de Lazy Gold
    self.wantedMap = self:_ComputeWantedMap()
    self.recDisplay = self:_RecipeDisplayList()
    local n = #self.recDisplay
    if self.recContent then self.recContent:SetHeight(math.max(n * ROW_H, VISIBLE * ROW_H)) end
    -- Repli/recherche peuvent RÉTRÉCIR la liste sous le scroll courant → on le ramène dans les clous,
    -- sinon la vue reste sur du vide.
    local maxScroll = math.max(0, n * ROW_H - (self.recScroll:GetHeight() or 0))
    if (self.recScroll:GetVerticalScroll() or 0) > maxScroll then self.recScroll:SetVerticalScroll(maxScroll) end
    self:RenderRecipes()
end

function PW:RenderRecipes()
    local list = self.recDisplay or {}
    local off  = self.recScroll and math.floor(self.recScroll:GetVerticalScroll() / ROW_H) or 0
    for i = 1, #self.recRows do
        local row, listIdx = self.recRows[i], off + i
        local e = list[listIdx]
        if e then
            row.entry = e
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, -(listIdx - 1) * ROW_H)
            row:SetPoint("RIGHT", self.recContent, "RIGHT", -2, 0)
            self:_FillRecipeRow(row, e); row:Show()
        else
            row.entry = nil; row:Hide()
        end
    end
end

-- En-tête : chevron +/- (texture native), libellé doré (section) ou bronze (sous-catégorie, indentée),
-- et compte d'éléments. Cliquable → replie/déplie (voir OnClick du pool).
function PW:_FillHeaderRow(row, e)
    row.icon:Hide(); row.badge:Hide(); row.sel:Hide(); row.profit:Hide()   -- profit:Hide → sinon fantôme sur l'en-tête recyclé
    local open = not self:_CollapseTable()[e.ckey] or (self.recipeSearch or "") ~= ""
    row.expand:SetTexture(open and "Interface\\Buttons\\UI-MinusButton-Up" or "Interface\\Buttons\\UI-PlusButton-Up")
    row.expand:ClearAllPoints()
    row.expand:SetPoint("LEFT", row, "LEFT", (e.depth == 2) and 12 or 1, 0)
    row.expand:Show()
    row.nameFS:ClearAllPoints()
    row.nameFS:SetPoint("LEFT", row.expand, "RIGHT", 2, 0); row.nameFS:SetPoint("RIGHT", -2, 0)
    local color = (e.depth == 2) and "|cFFC9A227" or "|cFFE8B84B"
    local label = color .. (e.name or "") .. "|r"
    if e.count and e.count > 0 then label = label .. string.format(" |cFF888888(%d)|r", e.count) end
    row.nameFS:SetText(label); row.nameFS:SetTextColor(1, 1, 1)
end

function PW:_FillRecipeRow(row, e)
    if e.isHeader then return self:_FillHeaderRow(row, e) end
    row.expand:Hide()
    row.icon:Show(); row.icon:SetTexture(e.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    row.icon:ClearAllPoints()
    row.icon:SetPoint("LEFT", row, "LEFT", e._sub and 22 or 1, 0)   -- décalé sous sa sous-catégorie
    row.nameFS:ClearAllPoints()
    row.nameFS:SetPoint("LEFT", row.icon, "RIGHT", 4, 0); row.nameFS:SetPoint("RIGHT", -2, 0)
    local r, g, b = COC.Craft:DifficultyColor(e.difficulty)
    local label = e.name or "?"
    if e.isMissing then
        r, g, b = 0.92, 0.28, 0.28                         -- ROUGE : recette NON apprise (source au clic)
        label = label .. " |cFF884444(" .. L["niv."] .. " " .. (e.level or 0) .. ")|r"
    elseif (e.numAvailable or 0) > 0 then
        label = string.format("%s |cFF888888[%d]|r", label, e.numAvailable)
    end
    row.nameFS:SetText(label); row.nameFS:SetTextColor(r, g, b)
    row.sel:SetShown(self.selectedKey ~= nil and self.selectedKey == entryKey(e))
    self:_FillRecipeRight(row, e)
end

-- Profit Lazy Gold d'une ligne, MÉMORISÉ le temps du refresh (le rendu se refait à chaque scroll → on
-- éviterait sinon de rappeler Auctionator en boucle). `false` = calculé, sans valeur. Rien pour les
-- recettes manquantes (on ne peut pas les fabriquer) ni si Lazy Gold est absent.
function PW:_RowProfit(e)
    if not (COC.LazyGold and COC.LazyGold:IsAvailable()) then return nil end
    -- Les recettes MANQUANTES ont aussi un profit : c'est même l'info qui décide si ça vaut le coup
    -- d'aller l'apprendre.
    self._profitCache = self._profitCache or {}
    local k = e.itemID or 0
    local v = self._profitCache[k]
    if v == nil then v = COC.LazyGold:EntryProfit(self.profKey, e) or false; self._profitCache[k] = v end
    return v or nil
end

-- Zone DROITE d'une ligne : profit (le plus à droite) + badge « demandé » à sa gauche. Rétrécit le nom
-- jusqu'au premier élément présent pour éviter le chevauchement.
function PW:_FillRecipeRight(row, e)
    local prof = self:_RowProfit(e)
    -- Indicateur COMPACT (paliers de pièces) par défaut : la liste reste lisible. Le bouton « 123 »
    -- passe aux valeurs exactes en po/pa/pc (LG:ProfitText arbitre). Une perte n'affiche rien.
    local tier = prof and COC.LazyGold:ProfitText(prof) or ""
    if tier ~= "" then row.profit:SetText(tier); row.profit:Show() else row.profit:Hide() end
    local anchor = row.profit:IsShown() and row.profit or nil
    local w = self.wantedMap and e.itemID and self.wantedMap[e.itemID]
    if w and w.count and w.count > 0 then
        row.badge:ClearAllPoints()
        if anchor then row.badge:SetPoint("RIGHT", anchor, "LEFT", -4, 0) else row.badge:SetPoint("RIGHT", -2, 0) end
        row.badge:SetText(string.format("|cFFFFCC00x%d|r", w.count)); row.badge:Show()
        anchor = row.badge
    else
        row.badge:Hide()
    end
    if anchor then row.nameFS:SetPoint("RIGHT", anchor, "LEFT", -4, 0) else row.nameFS:SetPoint("RIGHT", row, "RIGHT", -2, 0) end
end

-- Sélection par ENTRÉE (plus par index) : robuste aux recettes manquantes sans index d'API. On garde
-- selectedIndex à jour pour le craft (DoTradeSkill/SelectCraft l'utilisent) — nil pour une manquante,
-- ce qui est correct : on ne peut pas crafter une recette qu'on n'a pas apprise.
function PW:SelectRecipe(e)
    if type(e) == "number" then   -- rétro-compat : ancien appel par index (aucun appelant restant, par sûreté)
        self.selectedKey, self.selectedIndex = "i" .. e, e
    else
        self.selectedKey, self.selectedIndex = entryKey(e), e and e.index or nil
    end
    self:RenderRecipes()
    if self.RefreshDetail then self:RefreshDetail() end
end

function PW:GetSelectedRecipe()
    if not self.selectedKey then return nil end
    for _, r in ipairs(self._active or self.recipes or {}) do
        if not r.isHeader and entryKey(r) == self.selectedKey then return r end
    end
    return nil
end
