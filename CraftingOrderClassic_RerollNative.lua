-- CraftingOrderClassic_RerollNative.lua — la vue REROLL à l'allure de la fenêtre de métier du jeu
-- (spec docs/specs/vue-reroll-native.md). Une fenêtre à nous, au cadre du jeu : la liste de recettes du
-- jeu à gauche (remplie avec les recettes connues du reroll), le panneau recette du jeu à droite, et
-- notre colonne Commandes collée à droite. Remplace l'ancienne vue reroll sur Forever : on y entre par
-- PW:OpenForReroll (clic de l'icône de la minicarte, « Mes artisans »), cf. _ProfWindow_Camelot_Open.
--
-- Mesuré au labo le 2026-10-03 (build 70205), rien de deviné :
--  * le jeu décrit la recette d'un reroll SANS fenêtre ouverte (GetRecipeInfo, GetRecipeSchematic) ;
--  * le panneau recette (`ProfessionsRecipeSchematicFormTemplate`) marche créé dans NOTRE cadre, en mode
--    inspection posé AVANT Init (le mixin ne le lit qu'à Init) ;
--  * la liste du jeu marche avec NOTRE fabrique de lignes. Celle de Blizzard appelle GetCraftableCount
--    (les sacs du perso connecté) et ouvre un menu MenuUtil au clic droit, interdit depuis un addon.
-- On ne touche ni à ProfessionsFrame ni à InspectRecipeFrame : aucun cadre global de Blizzard piloté.

local COC  = CraftingOrderClassic
local Api  = COC.Api
local L    = COC.L
local PW   = COC.ProfWindow
local RN   = COC.RerollNative
if not (Api and Api.IS_MAINLINE and PW and RN) then return end

local RNF = {}
COC.RerollNativeFrame = RNF

-- Mesures de la page de métier de FOREVER, lues dans la source (Camelot/Blizzard_ProfessionsCrafting.lua
-- et Blizzard_ProfessionsFrame.xml) : cadre 594 de haut, liste 304 à (5, -72), panneau recette 360 de
-- large (SchematicFormCraftingTemplate, 484 de haut, bordure « common-insideframe »), barre de rang à
-- (110, -40). Copiées, pas devinées : c'est ce qui fait que la vue « ressemble » (retour du user du
-- 2026-10-03 sur la 1re version, plus large, sans bordure ni barre de rang, colonne à part).
local FRAME_H, LIST_X, LIST_TOP, LIST_W = 594, 5, 72, 304
local FORM_W, FORM_H, GAP = 360, 484, 2
local BASE_W = LIST_X + LIST_W + GAP + FORM_W + LIST_X
local frame                                     -- construit au premier usage

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end
local function Skin() return COC.UI and COC.UI.Skin end

-- Les modèles vivent dans un module de Blizzard chargé à la demande. On charge le seul module des
-- modèles : il ne crée pas la fenêtre de métier du jeu.
local TEMPLATES = "Blizzard_ProfessionsTemplates"
local function templatesReady()
    local A = C_AddOns
    if not (A and A.IsAddOnLoaded and A.LoadAddOn) then return false end
    if not A.IsAddOnLoaded(TEMPLATES) then pcall(A.LoadAddOn, TEMPLATES) end
    return A.IsAddOnLoaded(TEMPLATES) and true or false
end

-- ---------------------------------------------------------------- liste

-- La surbrillance suit la recette choisie, sur les lignes visibles comme sur celles qui se recréent.
local function paintSelection()
    if not frame then return end
    frame.List.ScrollBox:ForEachFrame(function(b, node)
        local d = node and node.GetData and node:GetData()
        if d and d.recipeInfo and b.SetSelected then b:SetSelected(d.recipeInfo.recipeID == frame.selected) end
    end)
end

local function initCategory(b, node)
    b:Init(node)
    b:SetScript("OnClick", function()
        node:ToggleCollapsed()
        b:UpdateCollapsedState(node:IsCollapsed())
    end)
end

-- Le modèle de ligne du jeu, nos scripts. `Init` en pcall : une ligne qui ne s'initialise pas garde
-- au moins son nom, plutôt que de casser toute la liste.
local function initRecipe(b, node)
    local d = node:GetData()
    if not pcall(b.Init, b, node, true) then b.Label:SetText(d.recipeInfo.name or "?") end
    b:SetSelected(d.recipeInfo.recipeID == frame.selected)
    b:SetScript("OnClick", function(_, button)
        if button == "LeftButton" then RNF:ShowRecipe(d.recipeInfo.recipeID) end
    end)
end

local function factory(make, node)
    local d = node:GetData()
    if d.categoryInfo then
        make("ProfessionsRecipeListCategoryTemplate", initCategory)
    elseif d.recipeInfo then
        make("ProfessionsRecipeListRecipeTemplate", initRecipe)
    else
        make("Frame")
    end
end

-- Arbre des données (RN.Tree) → fournisseur d'arbre de la liste du jeu. Rend le sort de la première
-- recette de la liste : la fenêtre du jeu s'ouvre sur une recette choisie, pas sur un panneau vide.
local function provide()
    local entries = RN.Entries(frame.key, frame.prof)
    local shown = RN.Filter(entries, frame.search)
    local dp, first = CreateTreeDataProvider(), nil
    local function add(parent, nodes)
        for _, n in ipairs(nodes) do
            if n.categoryInfo then add(parent:Insert({ categoryInfo = n.categoryInfo }), n.children)
            else
                first = first or n.recipeInfo.recipeID
                parent:Insert({ recipeInfo = n.recipeInfo })
            end
        end
    end
    add(dp, RN.Tree(frame.prof, shown))
    frame.List.ScrollBox:SetDataProvider(dp)
    local empty = frame.List.NoResultsText
    if #entries == 0 then
        empty:SetText(L["Ouvre ce métier une fois sur ce perso : l'addon lira ses recettes."])
    elseif #shown == 0 then
        empty:SetText(L["Aucune recette ne correspond."])
    end
    empty:SetShown(#shown == 0)
    return first
end

-- ---------------------------------------------------------------- panneau

-- Recette que le jeu ne décrit pas (absente du client) : ce que le catalogue sait, à la place du
-- panneau du jeu, plutôt qu'un panneau vide.
local function showFallback(sid)
    local c, fb = CL(), frame.Fallback
    local itemID = c and c.RecipeProduct and c:RecipeProduct(frame.prof, sid)
    local S = Skin()
    fb.icon:SetTexture((S and S.Icon and S.Icon(itemID, sid)) or 134400)
    fb.name:SetText((c and c.RecipeName and c:RecipeName(sid)) or ("spell:" .. sid))
    local lines = {}
    for _, rg in ipairs((c and c.RecipeReagents and c:RecipeReagents(frame.prof, sid)) or {}) do
        lines[#lines + 1] = string.format("%d x %s", rg[2] or 1, (c.ItemName and c:ItemName(rg[1])) or ("item:" .. rg[1]))
    end
    fb.reagents:SetText(#lines > 0 and (L["Réactifs :"] .. "\n" .. table.concat(lines, "\n")) or "")
    fb:Show()
end

function RNF:ShowRecipe(sid)
    if not frame then return end
    frame.selected = sid
    frame.Hint:Hide()
    frame.Fallback:Hide()
    local info = sid and C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo and C_TradeSkillUI.GetRecipeInfo(sid)
    local ok = info and pcall(frame.Form.Init, frame.Form, info)
    frame.Form:SetShown(ok and true or false)
    if not ok and sid then showFallback(sid) end
    paintSelection()
end

local function clearRecipe()
    frame.selected = nil
    frame.Form:Hide()
    frame.Fallback:Hide()
    frame.Hint:Show()
    paintSelection()
end

-- ---------------------------------------------------------------- construction

local function buildFallback()
    local fb = CreateFrame("Frame", nil, frame)
    fb:SetPoint("TOPLEFT", frame.List, "TOPRIGHT", 16, -16)
    fb:SetSize(FORM_W - 24, FORM_H - 32)
    fb.icon = fb:CreateTexture(nil, "ARTWORK")
    fb.icon:SetSize(40, 40); fb.icon:SetPoint("TOPLEFT")
    fb.name = fb:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    fb.name:SetPoint("LEFT", fb.icon, "RIGHT", 10, 0); fb.name:SetPoint("RIGHT", fb, "RIGHT")
    fb.name:SetJustifyH("LEFT")
    fb.reagents = fb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fb.reagents:SetPoint("TOPLEFT", fb.icon, "BOTTOMLEFT", 0, -16); fb.reagents:SetPoint("RIGHT", fb, "RIGHT")
    fb.reagents:SetJustifyH("LEFT"); fb.reagents:SetSpacing(4)
    fb:Hide()
    frame.Fallback = fb
end

local function buildList()
    local list = CreateFrame("Frame", nil, frame, "ProfessionsRecipeListTemplate")
    list:SetPoint("TOPLEFT", LIST_X, -LIST_TOP); list:SetPoint("BOTTOMLEFT", LIST_X, LIST_X); list:SetWidth(LIST_W)
    list.FilterDropdown:Hide()                       -- ses filtres ne valent que pour le perso connecté
    list.ScrollBox:GetView():SetElementFactory(factory)
    list.SearchBox:HookScript("OnTextChanged", function(box)
        local text = box:GetText() or ""
        if text == frame.search then return end
        frame.search = text
        provide()
    end)
    frame.List = list
end

-- Le panneau de la PAGE DE MÉTIER (SchematicFormCraftingTemplate : bordure comprise), pas le panneau nu
-- d'InspectRecipeFrame. Le fond dessiné du métier n'est pas dans le modèle : la page de Blizzard le
-- pose elle-même (`Background`) ; on fait pareil, derrière, à toute la taille du panneau.
local function buildForm()
    local form = CreateFrame("Frame", nil, frame, "SchematicFormCraftingTemplate")
    form.isInspection = true                         -- lu par Init seulement : posé avant le premier
    form:SetSize(FORM_W, FORM_H)
    form:SetPoint("TOPLEFT", frame.List, "TOPRIGHT", GAP, 0)
    form.Background = form:CreateTexture(nil, "BACKGROUND")
    form.Background:SetAllPoints()
    if form.OutputIcon and form.OutputIcon.Icon then form.OutputIcon.Icon:SetSize(53, 53) end   -- comme Forever
    form:Hide()
    frame.Form = form
    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    hint:SetPoint("CENTER", form, "CENTER")
    hint:SetText(L["Choisis une recette à gauche."])
    frame.Hint = hint
end

-- La barre de rang du jeu, avec le rang du REROLL. `ownerManagesEvents` : sans lui, elle s'abonne aux
-- changements de compétence et se repeint avec le métier du perso connecté.
local function buildRankBar()
    local bar = CreateFrame("Frame", nil, frame, "ProfessionsRankBarTemplate")
    bar.ownerManagesEvents = true
    bar:SetPoint("TOPLEFT", 110, -40)
    bar:Hide()
    frame.RankBar = bar
end

local function build()
    frame = CreateFrame("Frame", "CraftingOrderRerollFrame", UIParent, "PortraitFrameTemplate")
    frame:SetSize(BASE_W, FRAME_H)
    frame:SetPoint("CENTER", -150, 0)
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true); frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetScript("OnHide", function() RNF:_OnHidden() end)
    tinsert(UISpecialFrames, "CraftingOrderRerollFrame")   -- Échap la ferme, comme une fenêtre du jeu
    buildList()
    buildForm()
    buildRankBar()
    buildFallback()
end

-- Rang du reroll, gardé par l'addon (db.mySkillsByChar) : { rang, max }, ou nil s'il ne l'a jamais lu.
local function rerollRank()
    local mc = COC.db and COC.db.mySkillsByChar and COC.db.mySkillsByChar[frame.key]
    local sk = mc and mc[frame.prof]
    return sk and sk[1], sk and sk[2]
end

-- Le décor du métier, tel que le jeu le donne pour une de ses recettes : portrait, fond dessiné du
-- panneau, barre de rang. Le jeu décrit le métier (nom, identifiant, style) ; le RANG, lui, est celui
-- du reroll — le jeu donnerait celui du perso connecté.
local function dressFor(sid)
    local T = C_TradeSkillUI
    local pinfo = sid and T and T.GetProfessionInfoByRecipeID and T.GetProfessionInfoByRecipeID(sid)
    local tex = pinfo and pinfo.professionID and T.GetTradeSkillTexture and T.GetTradeSkillTexture(pinfo.professionID)
    local S = Skin()
    tex = tex or (S and S.ProfIcon and S.ProfIcon(frame.prof))
    if tex and frame.SetPortraitToAsset then frame:SetPortraitToAsset(tex) end
    local P = _G.Professions
    local atlas = pinfo and P and P.GetProfessionBackgroundAtlas and P.GetProfessionBackgroundAtlas(pinfo)
    if atlas then frame.Form.Background:SetAtlas(atlas, TextureKitConstants.IgnoreAtlasSize) end
    frame.Form.Background:SetShown(atlas ~= nil)
    local rank, max = rerollRank()
    local shown = false
    if pinfo and rank and max then
        local info = {}
        for k, v in pairs(pinfo) do info[k] = v end
        info.skillLevel, info.maxSkillLevel, info.skillModifier = rank, max, 0
        frame.RankBar:Show()
        shown = pcall(frame.RankBar.Update, frame.RankBar, info)
    end
    frame.RankBar:SetShown(shown and true or false)
end

-- ---------------------------------------------------------------- la colonne

-- Notre colonne, ENCASTRÉE dans le cadre comme dans la fenêtre de métier du jeu (dépouillée de son
-- titre et de sa croix, le cadre élargi d'autant, mêmes retraits que la greffe : PW.TUNE). En mode
-- reroll : elle lit les recettes du reroll (PW.CanFulfill → RerollKnows) et le métier ouvert ici.
function RNF:_DockColumn()
    PW:Build()
    local col, T = PW.frame, PW.TUNE or {}
    local gap = T.graftGap or 6
    PW.docked = true
    PW._compact = nil
    PW:_ApplyMode(true)
    if PW.vanillaBtn then PW.vanillaBtn:Hide() end
    -- Largeur : celle de la greffe (cf. sizeColumn de _ProfWindow_Camelot), sans en vider rerollKey.
    local colW = math.max(col:GetWidth() or 310, (PW._ViewTabsWidth and PW:_ViewTabsWidth()) or 0)
    col:SetWidth(colW)
    if PW._SyncOrdWidth then PW:_SyncOrdWidth() end
    if PW._PlaceOrdTabs then PW:_PlaceOrdTabs(true) end
    if PW._CamelotStripChrome then PW._CamelotStripChrome(col) end
    frame:SetWidth(BASE_W + colW + gap * 2)
    col:SetMovable(false)
    col:RegisterForDrag()
    col:SetParent(frame)
    col:ClearAllPoints()
    col:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -gap, -(T.graftTopInset or 26))
    col:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -gap, LIST_X)
    if col.SetToplevel then col:SetToplevel(false) end
    col:SetFrameStrata(frame:GetFrameStrata())
    col:SetFrameLevel(frame:GetFrameLevel() + 10)
    col:Show()
    PW:Refresh()
end

-- La colonne est-elle chez nous ? Vérité = son parent, pas un drapeau : la fenêtre de métier du jeu
-- peut la reprendre à tout moment (CamelotAttach la reparente).
function RNF:HasColumn()
    return frame ~= nil and PW.frame ~= nil and PW.frame:GetParent() == frame
end

-- Rafraîchir la colonne chez nous : le métier du reroll, pas le métier ouvert dans le jeu (il n'y en
-- a pas). Le reste (_RefreshDock) ferme le dock quand aucune fenêtre du jeu n'est ouverte.
local baseRefreshDock = PW._RefreshDock
function PW:_RefreshDock()
    if not RNF:HasColumn() then return baseRefreshDock(self) end
    self.profKey = self.standaloneKey
    self:_SetTitle(L["Commandes"], nil)
    if self.RefreshOrders then self:RefreshOrders() end
end

-- Une commande choisie dans la colonne : sa recette s'affiche dans le panneau.
hooksecurefunc(PW, "_RenderOrdSelected", function(_, it)
    if not (RNF:HasColumn() and frame:IsShown() and it and it.o) then return end
    local sid = RN.SpellOfOrder(it.o)
    if sid then RNF:ShowRecipe(sid) end
end)

-- La fenêtre de métier du jeu reprend la colonne (le joueur ouvre SON métier) : la vue reroll se ferme.
hooksecurefunc(PW, "CamelotAttach", function()
    if frame and frame:IsShown() and not RNF:HasColumn() then frame:Hide() end
end)

-- ---------------------------------------------------------------- ouverture / fermeture

-- Ouvre la vue pour (métier, clé « Prénom-Royaume », prénom). Rend false si les modèles du jeu ne
-- sont pas là : l'appelant retombe alors sur l'ancienne vue.
function RNF:Open(prof, key, short)
    if not (prof and key) or not templatesReady() then return false end
    if not frame and not pcall(build) then frame = nil; return false end
    frame.prof, frame.key, frame.short, frame.search = prof, key, short or key, ""
    frame.List.SearchBox:SetText("")
    local S = Skin()
    frame:SetTitle(string.format(L["%s — %s (lecture seule)"], frame.short,
        (S and S.ProfLabel and S.ProfLabel(prof)) or prof))
    local any = RN.Entries(key, prof)[1]
    dressFor(any and any.spellID)
    local first = provide()
    PW.rerollKey, PW.rerollName, PW.standaloneKey = key, frame.short, prof
    frame:Show()
    frame:Raise()
    self:_DockColumn()
    if first then self:ShowRecipe(first) else clearRecipe() end
    return true
end

-- Fermée (croix, Échap, ou reprise par la fenêtre du jeu) : la colonne redevient libre, le mode reroll
-- s'éteint. Si la fenêtre du jeu l'a déjà reprise, on ne la lui arrache pas.
function RNF:_OnHidden()
    if not self:HasColumn() then return end
    PW.rerollKey, PW.rerollName, PW.standaloneKey = nil, nil, nil
    PW:CamelotDetach(_G.ProfessionsFrame)
end

function RNF:IsShown() return frame ~= nil and frame:IsShown() end
