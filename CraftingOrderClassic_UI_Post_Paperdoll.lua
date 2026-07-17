-- CraftingOrderClassic_UI_Post_Paperdoll.lua — onglet « Commande », vue SILHOUETTE de l'Enchantement.
-- Choisir un enchant en cliquant l'EMPLACEMENT (comme sur son personnage) au lieu de fouiller ~300
-- plans : clic sur l'icône → menu des stats de cet emplacement → clic sur une stat → ses variantes,
-- de la plus forte à la plus faible. La sélection rejoint le flux NORMAL de l'onglet (SelectPostPlan
-- avec l'entrée du CATALOGUE) : réactifs, commission, ciblage d'artisan et Poster restent inchangés.
-- Chargé après _UI_Post_Categories.lua ; partage le namespace UI. NB : _Enchant.lua est chargé APRÈS
-- nous (cf. les 3 .toc) → ne toucher à COC.Enchant qu'au RUNTIME, jamais au chargement.
--
-- ALTERNATIVE à la liste, jamais un remplacement (d'où la bascule dans la bande de filtres) : les
-- produits de désenchantement (essences, poussières, éclats) et les huiles/baguettes n'ont pas
-- d'emplacement — ils n'existent pas ici et resteraient introuvables sans la liste.
--
-- Deux appuis natifs, donc zéro asset à livrer et zéro clé de locale pour le chrome d'emplacement :
--   · `GetInventorySlotInfo(slotName)` rend le chemin de la TEXTURE en 2ᵉ retour (PaperDollFrame.lua:711) ;
--   · `_G[strupper(slotName)]` rend son LIBELLÉ déjà localisé (PaperDollFrame.lua:873).
-- Ce que le métier sait enchanter se DÉRIVE du catalogue (Enchant:HasCatalogFor), jamais d'une liste
-- en dur : ça change d'une couche à l'autre, et ni la tête ni les épaules n'ont d'enchant nulle part
-- (arcanums/inscriptions = des OBJETS). Ces emplacements-là s'affichent DÉSATURÉS : la silhouette
-- reste lisible, et un emplacement mort se voit au lieu de manquer.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local ICON, STEP, FLY_W = 38, 42, 210
local FLY_TITLE_H = 18

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

-- La silhouette : disposition du paperdoll natif. `words` = les mots d'emplacement d'enchant que CETTE
-- icône couvre (plusieurs quand Blizzard en emploie plusieurs pour le même endroit : Bracer+Bracers,
-- ou quand un même endroit porte des familles distinctes : Weapon/2H Weapon/Staff). Sans `words`,
-- l'emplacement n'est enchantable dans AUCUNE couche → icône désaturée, présente pour la lecture.
-- Main gauche : volontairement PAS « Weapon » (une arme de main gauche accepte pourtant les enchants
-- d'arme, cf. EQUIP_WORDS) — ça dupliquerait toute la famille Arme sous l'icône Bouclier. Une commande
-- porte sur un enchant, pas sur une main : les enchants d'arme vivent sous Main droite, point.
local LEFT_COL = {
    { slot = "HeadSlot" },
    { slot = "NeckSlot" },
    { slot = "ShoulderSlot" },
    { slot = "BackSlot",  words = { "Cloak" } },
    { slot = "ChestSlot", words = { "Chest" } },
    { slot = "ShirtSlot" },
    { slot = "TabardSlot" },
    { slot = "WristSlot", words = { "Bracer", "Bracers" } },
}
local RIGHT_COL = {
    { slot = "HandsSlot",   words = { "Gloves" } },
    { slot = "WaistSlot" },
    { slot = "LegsSlot" },
    { slot = "FeetSlot",    words = { "Boots" } },
    { slot = "Finger0Slot", words = { "Ring" } },
    { slot = "Finger1Slot", words = { "Ring" } },
    { slot = "Trinket0Slot" },
    { slot = "Trinket1Slot" },
}
local BOTTOM_ROW = {
    { slot = "MainHandSlot",      words = { "Weapon", "2H Weapon", "Staff" } },
    { slot = "SecondaryHandSlot", words = { "Shield", "Off-Hand" } },
    { slot = "RangedSlot" },
}

-- Texture + libellé natifs d'un emplacement. ⚠️ PAS de `GetInventorySlotInfo and GetInventorySlotInfo(s)`
-- en assignation multiple : `and` TRONQUE le multi-retour à UNE valeur (mémoire lua-and-truncates-
-- multireturn) → on perdrait précisément la texture, qui est le 2ᵉ retour.
local function slotArt(slotName)
    local tex
    if GetInventorySlotInfo then
        local _, t = GetInventorySlotInfo(slotName)
        tex = t
    end
    return tex, _G[strupper(slotName)] or slotName
end

-- Les mots de CETTE icône réellement servis par le catalogue de la couche courante (⇒ {} = icône morte).
local function liveWords(def)
    local out = {}
    if not COC.Enchant then return out end
    for _, w in ipairs(def.words or {}) do
        if COC.Enchant:HasCatalogFor(w) then out[#out + 1] = w end
    end
    return out
end

-- API PARTAGÉE — le greffon d'ÉCHANGE (_Enchant_Trade_Ask) rejoue la MÊME silhouette avec une autre
-- action au clic (demander la pièce au partenaire, au lieu de choisir un enchant). On exporte la
-- DISPOSITION et les deux dérivations pures, PAS les boutons : les deux vues n'ont ni le même clic, ni
-- le même tooltip, ni le même parent. Une seule source de vérité pour « quels emplacements existent et
-- quels mots d'enchant ils couvrent » — sans quoi une couche saisonnière ajoutant un emplacement
-- (Wrath a ajouté le bâton) ne serait corrigée qu'à un seul endroit sur deux.
UI.DOLL = {
    LEFT = LEFT_COL, RIGHT = RIGHT_COL, BOTTOM = BOTTOM_ROW,
    ICON = ICON, STEP = STEP,
    SlotArt = slotArt, LiveWords = liveWords,
}

-- Entrée du CATALOGUE d'un spellID. Il faut l'entrée EXACTE (identité de table) et non une copie :
-- la liste des plans compare `e == self.postEntry` pour la surbrillance. Le catalogue est mémoïsé
-- côté lib (`_profCatCache`) → la table est stable d'un appel à l'autre.
local function catalogEntry(spellID)
    local c = CL(); if not c then return nil end
    for _, e in ipairs(c:ProfessionCatalogue("Enchanting") or {}) do
        if e.spellID == spellID then return e end
    end
end

-- =========================================================================
-- Le flyout (2 étapes dans UN seul puits)
-- =========================================================================
-- Étape 1 = les stats de l'emplacement, étape 2 = les variantes de la stat + une ligne de retour.
-- UN SEUL flyout, pas deux empilés : MakeFlyout pose un « closer » plein écran sous son puits, donc
-- deux flyouts ouverts ensemble = le closer du 2ᵉ mange les clics du 1ᵉʳ (il est au-dessus). Naviguer
-- dans le même puits évite tout le problème, et garde un seul point de fermeture.
local function dollFlyout()
    local fly = UI.postDollFly
    if fly then return fly end
    fly = Skin.MakeFlyout("COCPostDollFlyout", FLY_W)
    fly.title = fly:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fly.title:SetPoint("TOPLEFT", 6, -5); fly.title:SetPoint("RIGHT", -6, 0)
    fly.title:SetJustifyH("LEFT"); fly.title:SetTextColor(Skin.unpack(Skin.color.gold))
    Skin.ApplyShadow(fly.title)
    UI.postDollFly = fly
    return fly
end

-- Pose n lignes SOUS le titre et fixe la hauteur (le pool de MakeFlyout ancre ses lignes en haut du
-- puits : géométrie libre = ré-ancrer après coup et écraser la hauteur APRÈS SetCount, cf. le contrat
-- du kit et le menu minimap). Rend la i-ème ligne prête à peupler.
local function flyRow(fly, i)
    local r = fly:Row(i)
    r:ClearAllPoints(); r:SetPoint("TOPLEFT", 2, -(2 + FLY_TITLE_H + (i - 1) * 20))
    return r
end
local function flySetCount(fly, n)
    fly:SetCount(n)
    fly:SetHeight(math.max(n * 20 + 4 + FLY_TITLE_H, 24 + FLY_TITLE_H))
end

-- Étape 2 : les variantes d'une stat, de la plus forte à la plus faible.
-- Suffixe d'emplacement quand le GROUPE mélange des familles (« Impact » existe en 1 main ET en 2 mains,
-- et ShortName rendrait « Impact supérieur » pour les deux → deux lignes identiques, indiscernables).
-- Le suffixe est le libellé de section (SectionFor), donc déjà localisé par le client.
local function fillVariants(def, g)
    local fly, c = dollFlyout(), CL()
    fly.title:SetText(g.stat)
    local secs, nsec = {}, 0
    for _, v in ipairs(g.variants) do
        -- ⚠️ `and` tronque le multi-retour → SectionFor sort d'un `if`, pas d'une garde en ligne.
        local s
        if COC.Enchant then s = COC.Enchant:SectionFor(v.spellID) end
        v._sec = s
        if s and not secs[s] then secs[s] = true; nsec = nsec + 1 end
    end
    for i, v in ipairs(g.variants) do
        local r = flyRow(fly, i)
        local nm = (c and c:RecipeName(v.spellID)) or tostring(v.spellID)
        local txt = (COC.Enchant and COC.Enchant:ShortName(nm, v.spellID)) or nm
        if nsec > 1 and v._sec then txt = txt .. " |cFF888888(" .. v._sec .. ")|r" end
        r:SetText(txt); r:SetSelected(false)
        r:SetScript("OnClick", function()
            local e = catalogEntry(v.spellID)
            if e then UI:SelectPostPlan(e) end
            fly:Hide()
        end)
    end
    -- Chevron en ASCII : la police rend en tofu tout ce qui sort du Latin-1 (mémoire wow-ui-tofu-textures) —
    -- « ‹ » (U+2039) n'apparaît nulle part ailleurs dans du texte AFFICHÉ, on ne l'étrenne pas ici.
    local back = flyRow(fly, #g.variants + 1)
    back:SetText("|cFF888888< " .. L["Retour"] .. "|r"); back:SetSelected(false)
    back:SetScript("OnClick", function() UI:_FillDollStats(def) end)
    flySetCount(fly, #g.variants + 1)
end

-- Étape 1 : les stats disponibles pour l'emplacement. Méthode (pas local) : la ligne « Retour »
-- de l'étape 2 y revient, et une fonction locale ne serait pas encore définie à ce moment-là.
function UI:_FillDollStats(def)
    local fly = dollFlyout()
    local _, label = slotArt(def.slot)
    fly.title:SetText(label)
    local groups = COC.Enchant and COC.Enchant:CatalogGroups(liveWords(def)) or {}
    for i, g in ipairs(groups) do
        local r = flyRow(fly, i)
        local n = #g.variants
        r:SetText(g.stat .. (n > 1 and (" |cFF888888(" .. n .. ")|r") or "")); r:SetSelected(false)
        r:SetScript("OnClick", function()
            if n == 1 then                       -- une seule variante : pas d'étape 2 pour rien
                local e = catalogEntry(g.variants[1].spellID)
                if e then UI:SelectPostPlan(e) end
                fly:Hide()
            else
                fillVariants(def, g)
            end
        end)
    end
    flySetCount(fly, #groups)
end

-- =========================================================================
-- La silhouette
-- =========================================================================
local function makeSlot(sec, def)
    local tex, label = slotArt(def.slot)
    local b = Skin.MakeIconButton(sec, ICON, tex)
    b:SetFrameLevel(sec:GetFrameLevel() + 4)   -- au-dessus du modèle 3D (frame sœur, cf. _BuildPostDoll)
    b.def = def
    -- Le nom d'emplacement SEUL : il vient déjà localisé du client (cf. l'en-tête) et une icône grisée
    -- se lit sans notice. Zéro clé de locale pour toute la silhouette.
    b:SetScript("OnEnter", function(self2)
        GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
        GameTooltip:SetText(label, 1, 1, 1)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    b:SetScript("OnClick", function(self2)
        if not self2.live then return end
        local fly = dollFlyout()
        if fly:IsShown() and fly.owner == self2 then fly:Hide(); return end
        fly.owner = self2
        UI:_FillDollStats(self2.def)
        fly:ClearAllPoints(); fly:SetPoint("TOPLEFT", self2, "TOPRIGHT", 4, 0); fly:Show()
    end)
    return b
end

-- Une colonne (ou la rangée d'armes) : ancrage RELATIF au bloc « plans », comme tout le contenu de
-- l'onglet (cf. l'en-tête de _UI_Post_Layout).
local function buildRun(sec, list, point, x, y, dx, dy, store)
    for i, def in ipairs(list) do
        local b = makeSlot(sec, def)
        b:SetPoint(point, sec, point, x + (i - 1) * dx, y - (i - 1) * dy)
        store[#store + 1] = b
    end
end

function UI:_BuildPostDoll()
    local sec = self:PostSec("plans"); if not sec then return end
    local root = CreateFrame("Frame", nil, sec)
    root:SetPoint("TOPLEFT", 0, 0); root:SetPoint("BOTTOMRIGHT", 0, 0); root:Hide()
    self.postDollPanel = root
    self.postDollBtns = {}
    -- Modèle 3D au centre, DERRIÈRE les icônes : c'est lui qui fait la silhouette (sinon deux colonnes
    -- d'icônes collées aux bords avec un grand vide au milieu). Purement décoratif — sous pcall, et
    -- s'il ne rend rien la vue reste parfaitement utilisable.
    local m = CreateFrame("PlayerModel", nil, root)
    m:SetPoint("TOPLEFT", 58, -10); m:SetPoint("BOTTOMRIGHT", -58, 66)
    m:SetFrameLevel(root:GetFrameLevel())
    -- `SetUnit` SEUL : son cadrage par défaut est le personnage en pied, ce qu'on veut. (Pas de
    -- SetPortraitZoom — il cadre sur le VISAGE, c'est le réglage du médaillon, pas du paperdoll.)
    if not pcall(function() m:SetUnit("player") end) then m:Hide() end
    self.postDollModel = m
    buildRun(root, LEFT_COL,   "TOPLEFT",  12, -10, 0, STEP, self.postDollBtns)
    buildRun(root, RIGHT_COL,  "TOPRIGHT", -12, -10, 0, STEP, self.postDollBtns)
    -- Rangée d'armes : centrée sous les colonnes (3 icônes + 2 écarts de 6). Largeur LUE sur la zone,
    -- avec le même repli que la liste (cf. _BuildPostLeft) si le layout n'a pas encore mesuré.
    local w = sec:GetWidth(); if w <= 1 then w = UI.POST.LIST_W + 6 end
    local w3 = 3 * ICON + 2 * 6
    buildRun(root, BOTTOM_ROW, "TOPLEFT", (w - w3) / 2, -(10 + 8 * STEP + 8),
             ICON + 6, 0, self.postDollBtns)
end

-- Désature les emplacements que le catalogue de la couche courante ne sert pas. Appelé au 1er affichage
-- (le catalogue de la lib peut n'être pas prêt au build) puis à chaque bascule — idempotent.
function UI:_RefreshPostDoll()
    for _, b in ipairs(self.postDollBtns or {}) do
        local live = #liveWords(b.def) > 0
        b.live = live
        b.icon:SetDesaturated(not live)
        b.icon:SetAlpha(live and 1 or 0.45)
    end
end

-- =========================================================================
-- Bascule liste ↔ silhouette
-- =========================================================================
-- Le déclencheur vit à DROITE du slot de RECHERCHE, pas dans un slot à lui dans la SPEC : un slot fixe
-- volerait sa largeur à la recherche (le seul flex de la bande) EN PERMANENCE, alors que le bouton ne
-- sert qu'à un métier sur douze. Il n'apparaît qu'en Enchantement, et la recherche récupère la place
-- dès qu'on en sort (_SyncPostDollView ré-ancre son bord droit).
function UI:_BuildPostDollToggle(sSlot, srch)
    self.postSearchBox = srch
    local b = Skin.MakeIconButton(sSlot, 20, "Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest")
    b:SetPoint("RIGHT", -2, 0)
    b:SetScript("OnEnter", function(self2)
        GameTooltip:SetOwner(self2, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText(L["Choisir par emplacement"], 1, 1, 1)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    b:SetScript("OnClick", function() UI:_TogglePostDollView() end)
    b:Hide()
    self.postDollBtn = b
end

-- La silhouette n'a de sens QUE pour l'Enchantement : `postDollOn` est donc un vœu, et la vue effective
-- est ce vœu ∧ (métier == Enchanting). Changer de métier ne l'efface pas — revenir à l'Enchantement
-- retrouve la vue qu'on y avait laissée.
function UI:_PostDollActive()
    return self.postDollOn and self.postProf == "Enchanting" and self.postDollPanel ~= nil
end

-- Applique la vue : silhouette OU (scroll + gouttière). Appelé au refresh des plans et à la bascule.
function UI:_SyncPostDollView()
    local on      = self:_PostDollActive()
    local offered = self.postProf == "Enchanting"
    local b = self.postDollBtn
    if b then
        b:SetShown(offered); b:SetSelected(on and true or false)
        -- La recherche reprend la place du bouton hors Enchantement (cf. _BuildPostDollToggle).
        local srch = self.postSearchBox
        if srch then
            srch:ClearAllPoints()
            srch:SetPoint("LEFT", 10, 0); srch:SetPoint("RIGHT", offered and -26 or -2, 0)
        end
    end
    if self.postDollPanel then self.postDollPanel:SetShown(on) end
    -- Cacher le SCROLL suffit : la scrollbar est SON enfant, elle suit. (La gouttière de la SPEC est
    -- une zone nue — ni fond ni filet — donc rien à masquer de ce côté.)
    if self.postPlanScroll then self.postPlanScroll:SetShown(not on) end
    if on then
        self:_RefreshPostDoll()
    elseif self.postDollFly then
        self.postDollFly:Hide()
    end
end

function UI:_TogglePostDollView()
    self.postDollOn = not self.postDollOn
    self:_SyncPostDollView()
end
