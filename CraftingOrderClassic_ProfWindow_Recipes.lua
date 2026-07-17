-- CraftingOrderClassic_ProfWindow_Recipes.lua — colonne GAUCHE : liste de recettes virtualisée
-- (scroll), recherche, couleur par difficulté, sélection, badge « demandé » (nb de commandes
-- ouvertes pour l'objet). Port de TradeScanner_ProfWindow_Recipes.lua adapté à COC.Craft.

local COC  = CraftingOrderClassic
local PW   = COC.ProfWindow
local Skin = COC.UI.Skin
local L    = COC.L

-- ROW_H = hauteur d'une ligne ; VISIBLE = taille du POOL de lignes physiques réutilisées.
-- INVARIANT : VISIBLE doit être ≥ au nb de lignes que le viewport peut afficher, sinon les
-- derniers items sont INatteignables (le scroll max = n - viewportRows ; le plus grand index
-- rendu = maxOff + VISIBLE ; s'il est < n, la queue de liste ne s'affiche jamais).
-- Viewport recettes = zone recList ≈ 352 px (col 402 − 24 recHeader − 26 recFilters) / 16 ≈ 22
-- lignes → 26 garde une marge confortable. RE-VÉRIFIER si les h de la SPEC recettes grossissent.
-- (bug 2026-07-01 : à 23, Bolt of Woolen/Linen Cloth manquaient en bas de la Couture.)
local ROW_H, VISIBLE = 16, 26

function PW:_BuildRecipeRow(parent, i)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(self.recListW or 196, ROW_H); row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
    local sel = row:CreateTexture(nil, "BACKGROUND"); sel:SetAllPoints()
    sel:SetColorTexture(0.91, 0.72, 0.29, 0.22); sel:Hide(); row.sel = sel
    local hi = row:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints(); hi:SetColorTexture(0.25, 0.45, 0.85, 0.25)
    -- Case « proposer cette recette » (LFW) : petit Button DÉDIÉ à gauche → un clic sur la case coche l'offre
    -- SANS déclencher l'OnClick de la ligne (sélection/repli). Visible seulement en mode LFW (cf. _FillRecipeRow).
    local chk = CreateFrame("Button", nil, row)
    chk:SetSize(ROW_H, ROW_H)
    chk.box = Skin.MakeCheck(chk, 13); chk.box:SetPoint("CENTER", chk, "CENTER", 0, 0)
    chk:SetScript("OnClick", function() PW:_ToggleLFWRecipe(row.entry) end)
    chk:SetScript("OnEnter", function(s)
        GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Proposer cette recette (recherche de travail)"], 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    chk:SetScript("OnLeave", GameTooltip_Hide)
    chk:Hide(); row.lfwChk = chk
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
    -- Rang requis (MTSL), à DROITE et SEULEMENT sous le filtre « montée de compétence » (cf. _FillRecipeRight).
    local niv = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    niv:SetPoint("RIGHT", -2, 0); niv:Hide(); row.niv = niv
    row:SetScript("OnClick", function(r)
        local e = r.entry; if not e then return end
        if e.isHeader then PW:ToggleRecipeSection(e.ckey) else PW:SelectRecipe(e) end
    end)
    row:SetScript("OnEnter", function(r) PW:_RecipeTooltip(r) end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    Skin.WireItemLink(row)   -- shift-clic → lien chat (tipLink/tipItemID posés au remplissage)
    row:Hide(); return row
end

-- Zones SPEC de la colonne (cf. _ProfWindow_Layout.lua) : recHeader (bande titre) / recFilters en
-- SLOTS (recTools = boutons de tri, recSearch = la recherche REMPLIT son slot) / recList +
-- recGutter (scrollbar). Ancres LEFT/RIGHT dans les bandes = centrage vertical gratuit ; largeur de
-- liste MESURÉE sur la zone.
function PW:_BuildRecipes(col)
    local hz = self:Sec("recTitle") or self:Sec("recHeader") or col
    local tz = self:Sec("recTools") or self:Sec("recFilters") or col
    local sz = self:Sec("recSearch") or self:Sec("recFilters") or col
    local hdr = hz:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr:SetPoint("LEFT", 8, 0); hdr:SetText("|cFFE8B84B" .. L["Recettes"] .. "|r")
    self.recHdr = hdr

    -- 8 px à gauche : l'art d'InputBoxTemplate déborde de ~5 px avant le rect de saisie.
    local search = CreateFrame("EditBox", nil, sz, "InputBoxTemplate")
    search:SetHeight(16); search:SetPoint("LEFT", 8, 0); search:SetPoint("RIGHT", -10, 0)
    search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", function(b) PW.recipeSearch = (b:GetText() or ""):lower(); PW:RefreshRecipes() end)
    search:SetScript("OnEscapePressed", function(b) b:SetText(""); b:ClearFocus() end)
    self.recipeSearchBox = search

    self:_BuildRecipeTools(tz)
    local ftz = self:Sec("recFilterToggles")
    if ftz then self:_BuildRecipeFilters(ftz) end
    local htz = self:Sec("recHeaderTools")   -- bouton « acquérables » dans son slot d'en-tête (à côté du titre)
    if htz and self._BuildAcquireFilter then self:_BuildAcquireFilter(htz) end

    -- Liste dans sa zone, scrollbar dans la gouttière (le −6 laisse respirer le bord, la barre
    -- déborde dans les 22 px de recGutter — même patron que toutes les listes converties).
    local lz = self:Sec("recList") or col
    local w = lz:GetWidth()
    self.recListW = ((w and w > 0) and w or 218) - 6
    local scroll = CreateFrame("ScrollFrame", "CraftingOrderProfWinRecScroll", lz, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 6, 0); scroll:SetPoint("BOTTOMRIGHT", 0, 0)
    Skin.ScrollTrack("CraftingOrderProfWinRecScroll")
    local content = CreateFrame("Frame", nil, scroll); content:SetSize(self.recListW, VISIBLE * ROW_H); scroll:SetScrollChild(content)
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
    if self._LevelingTooltip then self:_LevelingTooltip(e) end   -- coût/point + destination du plan (Leveling)
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
-- Set des recettes DÉJÀ apprises, indexé par spellID PUIS par objet produit (repli si le spellID
-- |Henchant: est absent). Base de la dédup des fausses-manquantes MTSL (cf. _ActiveRecipes / MissingCount).
function PW:_KnownRecipeSet()
    local known = {}
    for _, r in ipairs(self.recipes or {}) do
        if not r.isHeader then
            if r.spellID then known["s" .. r.spellID] = true end
            if r.itemID  then known["i" .. r.itemID]  = true end
        end
    end
    return known
end

-- true si la « manquante » MTSL m est en réalité DÉJÀ apprise (présente dans le set known). MTSL laisse
-- parfois de tels faux manquants dans MISSING_SKILLS (calcul pas rafraîchi, ou matching de sa base raté
-- sur l'Anniversary/TBC) → sans ce filtre la recette s'affiche EN DOUBLE : apprise + rouge « (niv. X) ».
local function knownAlready(known, m)
    return (m.spellID and known["s" .. m.spellID]) or (m.itemID and known["i" .. m.itemID]) or false
end

-- Mode « manquantes » : l'union COMPLÈTE apprises + non-apprises. Tri « progression » (By skill-up,
-- hors mode manquantes) : on n'injecte que les manquantes APPRENABLES MAINTENANT (niveau requis ≤
-- rang) — le conseil « va acheter ce plan » doit se voir sans ouvrir le mode manquantes (retour user
-- 2026-07-17), mais la vue par familles reste pur « ce que je sais faire » (pas d'inondation rouge).
function PW:_ActiveRecipes()
    local mode = (self.missingMode and "all") or (self.recipeSortLevel and "learnable") or nil
    if not (mode and COC.MTSL) then return self.recipes or {} end
    local out, known = {}, self:_KnownRecipeSet()
    for _, r in ipairs(self.recipes or {}) do out[#out + 1] = r end
    local rank = COC.Craft and COC.Craft:OpenRank()
    for _, m in ipairs(COC.MTSL:MissingRecipes(self.profKey) or {}) do
        if not knownAlready(known, m)
            and (mode == "all" or (rank and (m.level or 0) <= rank)) then out[#out + 1] = m end
    end
    return out
end

-- Nombre RÉEL de recettes manquantes APRÈS dédup (le MissingCount brut de MTSL compte les faux manquants
-- déjà appris → le libellé « Manquantes (N) » surestimerait). Chemin froid (bascule/refresh), jamais au
-- scroll. 0 si MTSL absent / métier inconnu.
function PW:MissingCount()
    if not (COC.MTSL and COC.MTSL:IsAvailable() and self.profKey) then return 0 end
    local known, n = self:_KnownRecipeSet(), 0
    for _, m in ipairs(COC.MTSL:MissingRecipes(self.profKey) or {}) do
        if not knownAlready(known, m) then n = n + 1 end
    end
    return n
end

-- Rang de tri « progression » : orange (point garanti) < jaune < vert < gris ; inconnu entre gris et
-- manquantes ; les MANQUANTES ferment la marche (pas craftables, donc aucun point à en tirer).
local DIFF_RANK = { optimal = 1, medium = 2, easy = 3, trivial = 4 }
local function levelRank(e)
    if e.isMissing then return 6 end
    return DIFF_RANK[e.difficulty] or 5
end

-- true si la recette MANQUANTE `e` est ACQUÉRABLE tout de suite : apprise au formateur, vendue par un PNJ,
-- ou dont l'objet-recette est actuellement price par Auctionator (donc listé à l'HV). Écarte butin/quête
-- (« va la farmer »). N'a de sens que sur une manquante — une apprise n'est pas « à acquérir ». Utilisé
-- SEULEMENT sous le filtre acquérables (mode manquantes) : coût nul le reste du temps.
function PW:_IsAcquirable(e)
    if not e.isMissing then return false end
    local M = COC.MTSL
    local kind = M and M:SourceKind(self.profKey, e.spellID) or "unknown"
    if kind == "trainer" or kind == "vendor" then return true end
    local LG = COC.LazyGold
    if LG and LG:IsAvailable() then
        local recItemID = M and M:RecipeItem(self.profKey, e.spellID)
        if recItemID and LG:ItemValue(recItemID) then return true end
    end
    return false
end

function PW:_RecipeDisplayList()
    local raw, search = self:_ActiveRecipes(), self.recipeSearch
    self._active = raw   -- mémorisé pour GetSelectedRecipe (résolution par clé, cf. entryKey)
    local sortProfit = self.recipeSortProfit and COC.LazyGold and COC.LazyGold:IsAvailable()
    local haveMats = self.recipeHaveMats   -- ne garder que les recettes craftables MAINTENANT (mats en sac)
    local skillUp  = self.recipeSkillUp    -- masquer le palier gris (trivial) : ne reste que ce qui progresse
    -- Filtre « acquérables » : n'a de sens qu'en mode manquantes (il ne garde QUE des manquantes achetables,
    -- masquant même les apprises de l'union). Désarmé hors mode par _SyncFilterButtons.
    local acquirable = self.missingMode and self.recipeAcquirable and COC.MTSL
    local items = {}
    for _, r in ipairs(raw) do
        if not r.isHeader
            and (not search or search == "" or (r.name and r.name:lower():find(search, 1, true)))
            and (not haveMats or (r.numAvailable or 0) > 0)
            and (not skillUp or r.difficulty ~= "trivial" or (r.isMissing and self._MissingLearnable and self:_MissingLearnable(r)))
            and (not acquirable or self:_IsAcquirable(r)) then
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
    -- Tri « progression » à PLAT : orange d'abord, gris en fin ; affiné coût/point par
    -- _ProfWindow_Leveling quand il est chargé (repli rang + A-Z sinon, ex. avant restart .toc).
    if self.recipeSortLevel then
        local less = self._ProgressionLess
        table.sort(items, function(a, b)
            if less then return less(self, a, b) end
            local ra, rb = levelRank(a), levelRank(b)
            if ra ~= rb then return ra < rb end
            return (a.name or "") < (b.name or "")
        end)
        return items
    end
    return COC.RecipeCats:BuildDisplay(self.profKey, items, {
        itemID    = function(r) return r.itemID end,
        -- Enchantement : un enchant est un SERVICE (aucun objet produit → COC.SectionOf le rangerait en
        -- « Autres/Divers », tous en vrac). On le classe EMPLACEMENT (section) › STAT DE BASE (sous-cat) ›
        -- variantes triées par niveau. ⚠️ PAS de `X and X:f()` : `and` TRONQUE le multi-retour.
        section   = function(r)
            if not COC.Enchant then return end
            return COC.Enchant:SectionFor(r.spellID)
        end,
        sub       = function(r)
            if not COC.Enchant then return end
            return COC.Enchant:StatFor(r.spellID)
        end,
        name      = function(r) return r.name or "" end,
        collapsed = ((search or "") ~= "") and nil or self:_CollapseTable(),
    })
end

function PW:RefreshRecipes()
    if not self.recScroll then return end
    self._profitCache, self._lvlCache = {}, {}   -- invalidés à chaque refresh (prix Auctionator ont pu changer)
    -- Mode « colonne de cases » : actif quand je CHERCHE du travail dans le métier ouvert (le mien, hors
    -- reroll). Pré-calcule l'ensemble des spellID déjà proposés pour cocher les lignes en O(1) au rendu.
    local D = COC.Directory
    self.lfwSelectMode = (not self.rerollKey) and D and D.MyLFW and D:MyLFW() == self.profKey and true or false
    self._lfwOfferSet = nil
    if self.lfwSelectMode then
        local o = D:MyLFWOffer(self.profKey)
        if o and o.recipes then
            self._lfwOfferSet = {}
            for _, sid in ipairs(o.recipes) do self._lfwOfferSet[sid] = true end
        end
    end
    self:_SyncSortHeader()   -- affiche/masque le bouton de tri selon la présence de Lazy Gold
    self:_SyncFilterButtons()
    self.wantedMap = self:_ComputeWantedMap()
    self.recDisplay = self:_RecipeDisplayList()
    if self._ComputeLevelBest then self:_ComputeLevelBest() end   -- badge « meilleur coût/point » (Leveling)
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
    row.tipLink, row.tipItemID = nil, nil   -- en-tête : pas d'objet à linker (ligne recyclée)
    row.icon:Hide(); row.badge:Hide(); row.sel:Hide(); row.profit:Hide(); row.niv:Hide()   -- sinon fantôme sur l'en-tête recyclé
    if row.srcTex then row.srcTex:Hide(); row.lvlTex:Hide() end   -- idem pour les icônes Leveling
    if row.lfwChk then row.lfwChk:Hide() end   -- pas de case sur un en-tête (ligne recyclée depuis une recette)
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
    row.tipLink, row.tipItemID = e.link, e.itemID   -- shift-clic → lien (enchant via link, manquante via itemID)
    row.expand:Hide()
    -- Case LFW à l'extrême gauche (seulement mes recettes APPRISES : une manquante n'a pas de spellID à
    -- proposer). Quand elle est là, l'icône se décale de sa largeur pour ne pas la recouvrir.
    local base = e._sub and 22 or 1
    local showChk = self.lfwSelectMode and e.spellID and not e.isMissing
    if showChk then
        row.lfwChk:ClearAllPoints(); row.lfwChk:SetPoint("LEFT", row, "LEFT", base, 0)
        row.lfwChk.box:SetChecked(self._lfwOfferSet and self._lfwOfferSet[e.spellID] or false)
        row.lfwChk:Show()
    else
        row.lfwChk:Hide()
    end
    row.icon:Show(); row.icon:SetTexture(e.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    row.icon:ClearAllPoints()
    row.icon:SetPoint("LEFT", row, "LEFT", base + (showChk and ROW_H or 0), 0)   -- décalé sous sa sous-catégorie (et après la case LFW)
    row.nameFS:ClearAllPoints()
    row.nameFS:SetPoint("LEFT", row.icon, "RIGHT", 4, 0); row.nameFS:SetPoint("RIGHT", -2, 0)
    local r, g, b = COC.Craft:DifficultyColor(e.difficulty)
    -- Enchant d'équipement : la STAT seule — l'emplacement est déjà porté par l'en-tête de section, et le
    -- nom complet (« Enchant Bracer - … » ×20) se faisait tronquer dans la colonne. Autres : nom entier.
    local label = (COC.Enchant and COC.Enchant:ShortName(e.name, e.spellID)) or e.name or "?"
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

-- Zone DROITE d'une ligne : niv requis (filtre skill-up) → profit → badge « demandé », de droite à
-- gauche. Rétrécit le nom jusqu'au premier élément présent pour éviter le chevauchement.
function PW:_FillRecipeRight(row, e)
    -- Rang requis MTSL à l'extrême droite, UNIQUEMENT sous le filtre « montée de compétence » (le seul
    -- contexte où le niveau de skill est pertinent). Nil sans MTSL / hors base / recette manquante.
    local anchor
    local ms = self.recipeSkillUp and not e.isMissing and COC.MTSL and e.spellID and COC.MTSL:MinSkill(self.profKey, e.spellID)
    if ms then row.niv:SetText("|cFF9AC0E8" .. ms .. "|r"); row.niv:Show(); anchor = row.niv else row.niv:Hide() end
    local prof = self:_RowProfit(e)
    -- Indicateur COMPACT (paliers de pièces) par défaut : la liste reste lisible. Le bouton « 123 »
    -- passe aux valeurs exactes en po/pa/pc (LG:ProfitText arbitre). Une perte n'affiche rien.
    local tier = prof and COC.LazyGold:ProfitText(prof) or ""
    if tier ~= "" then
        row.profit:ClearAllPoints()
        if anchor then row.profit:SetPoint("RIGHT", anchor, "LEFT", -4, 0) else row.profit:SetPoint("RIGHT", -2, 0) end
        row.profit:SetText(tier); row.profit:Show(); anchor = row.profit
    else
        row.profit:Hide()
    end
    local w = self.wantedMap and e.itemID and self.wantedMap[e.itemID]
    if w and w.count and w.count > 0 then
        row.badge:ClearAllPoints()
        if anchor then row.badge:SetPoint("RIGHT", anchor, "LEFT", -4, 0) else row.badge:SetPoint("RIGHT", -2, 0) end
        row.badge:SetText(string.format("|cFFFFCC00x%d|r", w.count)); row.badge:Show()
        anchor = row.badge
    else
        row.badge:Hide()
    end
    if self._FillLevelingRight then anchor = self:_FillLevelingRight(row, e, anchor) end
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
