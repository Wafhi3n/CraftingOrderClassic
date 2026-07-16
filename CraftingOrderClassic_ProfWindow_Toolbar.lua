-- CraftingOrderClassic_ProfWindow_Toolbar.lua — barre d'outils de la colonne Recettes (vue métier) :
-- les toggles de TRI (slot recTools, à gauche : rentabilité / valeurs exactes / progression — Lazy Gold)
-- et de FILTRE (slot recFilterToggles, à droite : « j'ai les matériaux » / « montée de compétence »).
-- Extrait de _ProfWindow_Recipes.lua (plafond anti-monolithe) : même table PW, les build sont appelés
-- par _BuildRecipes, les _Sync* par RefreshRecipes. Tri = RÉORDONNE la liste ; filtre = la RÉDUIT.

local COC  = CraftingOrderClassic
local PW   = COC.ProfWindow
local Skin = COC.UI.Skin
local L    = COC.L

-- Petit bouton bascule : fond doré quand actif, survol, tooltip DYNAMIQUE (tipFn est évalué au survol,
-- pas à la construction — le libellé dépend de l'état courant).
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

-- Barre d'outils du slot recTools : pièce d'or + « 123 » (Lazy Gold, masqués sans addon de prix,
-- cf. _SyncSortHeader) et ▲ verte (tri progression, toujours visible).
--   pièce d'or  → tri par rentabilité : liste à PLAT du plus rentable au moins (plus de catégories)
--   « 123 »     → valeurs EXACTES (po/pa/pc) au lieu de l'indicateur compact en paliers de pièces
--   ▲ verte     → tri par MONTÉE DE COMPÉTENCE : à plat, les plans qui rapportent un point d'abord
function PW:_BuildRecipeTools(tz)
    local sortBtn = makeToolBtn(tz, function()
        return PW.recipeSortProfit and L["Tri par rentabilité — clic pour A-Z."]
            or L["Trier par rentabilité (Lazy Gold)."]
    end, function() PW:_ToggleRecipeSort() end)
    sortBtn:SetPoint("LEFT", 24, 0)
    local coin = sortBtn:CreateTexture(nil, "ARTWORK")
    coin:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon"); coin:SetSize(14, 14); coin:SetPoint("CENTER")
    sortBtn.coin = coin
    self.recSortBtn = sortBtn

    local exactBtn = makeToolBtn(tz, function()
        return (COC.LazyGold and COC.LazyGold:ExactMode()) and L["Valeurs exactes — clic pour l'affichage compact."]
            or L["Afficher les valeurs exactes (po/pa/pc)."]
    end, function() PW:_ToggleProfitExact() end)
    exactBtn:SetPoint("LEFT", 2, 0)
    local num = exactBtn:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    num:SetPoint("CENTER"); num:SetText("123"); exactBtn.num = num
    self.recExactBtn = exactBtn

    local lvlBtn = makeToolBtn(tz, function()
        return PW.recipeSortLevel and L["Tri par montée de compétence — clic pour A-Z."]
            or L["Trier par montée de compétence (plans orange d'abord)."]
    end, function() PW:_ToggleRecipeLevelSort() end)
    lvlBtn:SetPoint("LEFT", 46, 0)
    local arrow = lvlBtn:CreateTexture(nil, "ARTWORK")
    arrow:SetTexture("Interface\\Buttons\\UI-MicroStream-Green"); arrow:SetSize(14, 14); arrow:SetPoint("CENTER")
    lvlBtn.arrow = arrow
    self.recLevelBtn = lvlBtn
end

-- Slot recFilterToggles (à DROITE de la recherche) : filtres qui RÉDUISENT la liste (vs. le tri, à
-- gauche, qui la RÉORDONNE). Actif = fond doré (comme les toggles de tri).
--   sac         → « j'ai les matériaux » (pendant du filtre natif « Réactifs en stock »)
--   ▲ orange    → « montée de compétence » : masque les recettes GRISES (triviales, aucun point)
function PW:_BuildRecipeFilters(fz)
    local matBtn = makeToolBtn(fz, function()
        return PW.recipeHaveMats and L["Filtre matériaux actif — clic pour tout afficher."]
            or L["N'afficher que les recettes dont j'ai les matériaux."]
    end, function() PW:_ToggleHaveMats() end)
    matBtn:SetPoint("LEFT", 4, 0)
    local bag = matBtn:CreateTexture(nil, "ARTWORK")
    bag:SetTexture("Interface\\Icons\\INV_Misc_Bag_08"); bag:SetSize(15, 15)
    bag:SetTexCoord(0.07, 0.93, 0.07, 0.93); bag:SetPoint("CENTER")
    matBtn.bag = bag
    self.recMatBtn = matBtn

    -- Filtre par PALIER de difficulté, donnée live (gratuit, sans MTSL). Flèche orange = couleur du
    -- palier « point garanti » ; grisée quand inactif (cf. _SyncFilterButtons).
    local upBtn = makeToolBtn(fz, function()
        return PW.recipeSkillUp and L["Filtre progression actif — clic pour tout afficher."]
            or L["N'afficher que les recettes qui font monter la compétence (masque le gris)."]
    end, function() PW:_ToggleSkillUp() end)
    upBtn:SetPoint("LEFT", 26, 0)
    local up = upBtn:CreateTexture(nil, "ARTWORK")
    up:SetTexture("Interface\\Buttons\\Arrow-Up-Up"); up:SetSize(16, 16); up:SetPoint("CENTER"); upBtn.up = up
    self.recSkillUpBtn = upBtn
end

-- Bouton du filtre « acquérables », dans son PROPRE slot d'en-tête (recHeaderTools, à côté du titre
-- « Recettes ») plutôt que dans la rangée de filtres déjà pleine — la position se règle dans la SPEC
-- (_ProfWindow_Layout). Centré dans son slot ; VISIBLE seulement en mode manquantes (cf. _SyncFilterButtons).
-- Ne garde que les manquantes obtenables tout de suite (formateur / vendeur / listées à l'HV). Icône
-- parchemin (texture déjà validée dans l'addon).
function PW:_BuildAcquireFilter(hz)
    local acqBtn = makeToolBtn(hz, function()
        return PW.recipeAcquirable and L["Filtre acquérables actif — clic pour tout afficher."]
            or L["N'afficher que les recettes acquérables (formateur, vendeur ou HV)."]
    end, function() PW:_ToggleAcquirable() end)
    acqBtn:SetPoint("CENTER", 0, 0)
    local scroll = acqBtn:CreateTexture(nil, "ARTWORK")
    scroll:SetTexture("Interface\\Icons\\INV_Scroll_03"); scroll:SetSize(15, 15)
    scroll:SetTexCoord(0.07, 0.93, 0.07, 0.93); scroll:SetPoint("CENTER"); acqBtn.gavel = scroll
    self.recAcquireBtn = acqBtn
end

-- Bascule le tri par rentabilité (sans effet si Lazy Gold absent). Met à jour l'en-tête + rafraîchit.
-- Exclusif avec le tri progression : un seul à-plat à la fois.
function PW:_ToggleRecipeSort()
    if not (COC.LazyGold and COC.LazyGold:IsAvailable()) then return end
    self.recipeSortProfit = not self.recipeSortProfit
    if self.recipeSortProfit then self.recipeSortLevel = nil end
    self:_SyncSortHeader()
    self:RefreshRecipes()
end

-- Bascule le tri par montée de compétence (exclusif avec le tri rentabilité). État runtime, comme lui.
function PW:_ToggleRecipeLevelSort()
    self.recipeSortLevel = not self.recipeSortLevel
    if self.recipeSortLevel then self.recipeSortProfit = nil end
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

-- Bascule les filtres (session : comme les toggles de tri, ils ne survivent pas au /reload — un filtre
-- qui masque des recettes silencieusement à la reconnexion surprendrait).
function PW:_ToggleHaveMats()
    self.recipeHaveMats = not self.recipeHaveMats
    self:RefreshRecipes()
end

function PW:_ToggleSkillUp()
    self.recipeSkillUp = not self.recipeSkillUp
    self:RefreshRecipes()
end

function PW:_ToggleAcquirable()
    self.recipeAcquirable = not self.recipeAcquirable
    self:RefreshRecipes()
end

-- Reflète l'état des boutons de tri (fond doré = actif) + le libellé de l'en-tête. Boutons Lazy Gold
-- masqués si l'addon est absent — inutile de proposer un tri ou des prix sans données ; la ▲
-- progression reste, elle ne dépend que des couleurs de difficulté du client.
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
    if self.recLevelBtn then
        local lon = self.recipeSortLevel and true or false
        self.recLevelBtn.onBG:SetShown(lon)
        self.recLevelBtn.arrow:SetDesaturated(not lon)
    end
    if self.recHdr then
        local label = (on and L["Par rentabilité"]) or (self.recipeSortLevel and L["Par progression"]) or L["Recettes"]
        self.recHdr:SetText("|cFFE8B84B" .. label .. "|r")
    end
end

-- Filtres (slot recFilterToggles) : ils n'ont de sens qu'en VUE PLEINE, où numAvailable/difficulty sont
-- lus en live sur la fenêtre native. En reroll (recettes du cache) ils masqueraient à tort → on les cache
-- et on désarme pour ne pas vider la liste au retour. Actif = fond doré ; icône vive vs. grisée.
function PW:_SyncFilterButtons()
    local show = not self.rerollKey
    if self.recMatBtn then
        self.recMatBtn:SetShown(show and true or false)
        if not show then self.recipeHaveMats = false
        else
            if self.recMatBtn.onBG then self.recMatBtn.onBG:SetShown(self.recipeHaveMats and true or false) end
            if self.recMatBtn.bag then self.recMatBtn.bag:SetDesaturated(not self.recipeHaveMats) end
        end
    end
    if self.recSkillUpBtn then
        self.recSkillUpBtn:SetShown(show and true or false)
        if not show then self.recipeSkillUp = false
        else
            local on = self.recipeSkillUp and true or false
            if self.recSkillUpBtn.onBG then self.recSkillUpBtn.onBG:SetShown(on) end
            if self.recSkillUpBtn.up then
                self.recSkillUpBtn.up:SetVertexColor(on and 1 or 0.5, on and 0.55 or 0.5, on and 0.25 or 0.5)
            end
        end
    end
    -- « Acquérables » : n'a de sens qu'en mode manquantes (il filtre des recettes à obtenir). Hors mode :
    -- masqué ET désarmé, sinon il viderait la liste des recettes apprises au retour.
    if self.recAcquireBtn then
        local am = (not self.rerollKey) and self.missingMode and true or false
        self.recAcquireBtn:SetShown(am)
        if not am then self.recipeAcquirable = false
        else
            local on = self.recipeAcquirable and true or false
            if self.recAcquireBtn.onBG then self.recAcquireBtn.onBG:SetShown(on) end
            if self.recAcquireBtn.gavel then self.recAcquireBtn.gavel:SetDesaturated(not on) end
        end
    end
end
