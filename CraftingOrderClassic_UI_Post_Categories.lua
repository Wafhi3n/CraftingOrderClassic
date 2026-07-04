-- CraftingOrderClassic_UI_Post_Categories.lua — onglet « Commande », panneau gauche :
-- regroupe la LISTE DES PLANS en sections type fenêtre native (emplacement puis type pour les
-- équipements, type pour les armes, catégorie pour le reste). Extrait de _UI_Post.lua
-- (anti-monolithe) : partage le même namespace UI. Chargé après _UI_Post_Artisans.lua.
--
-- La catégorie est dérivée de GetItemInfoInstant, qui lit la DB STATIQUE du client → disponible
-- SANS cache (contrairement à GetItemInfo pour le nom), donc le classement est fiable au 1er rendu.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local PLH   = 20         -- hauteur ligne (plan ET en-tête : pool virtualisé homogène ; DOIT égaler _UI_Post.lua)

local INSTANT = GetItemInfoInstant

-- Ordre canonique des emplacements d'armure (token INVTYPE -> rang) : suit le paperdoll
-- (tête → pieds), puis doigts/bijoux, bouclier/tenu. Sert de tri PRIMAIRE des sections.
local SLOT_ORDER = {
    INVTYPE_HEAD = 1, INVTYPE_NECK = 2, INVTYPE_SHOULDER = 3, INVTYPE_CLOAK = 4,
    INVTYPE_CHEST = 5, INVTYPE_ROBE = 5, INVTYPE_BODY = 6, INVTYPE_TABARD = 7,
    INVTYPE_WRIST = 8, INVTYPE_HAND = 9, INVTYPE_WAIST = 10, INVTYPE_LEGS = 11,
    INVTYPE_FEET = 12, INVTYPE_FINGER = 13, INVTYPE_TRINKET = 14,
    INVTYPE_SHIELD = 15, INVTYPE_HOLDABLE = 16,
}

-- Sous-classes d'armure « à matériau » (Tissu/Cuir/Mailles/Plaques) : pour elles on suffixe le
-- type après l'emplacement (« Torse · Plaques »), sinon l'emplacement seul suffit (bijoux, dos…).
local MATERIAL_ARMOR = { [1] = true, [2] = true, [3] = true, [4] = true }

-- Section (libellé localisé) + rang de tri d'un objet produit. Libellés issus des globales client
-- (déjà localisées : noms d'emplacement _G[INVTYPE_*], sous-classe/type via GetItemInfoInstant).
--   * arme (classID 2)     → par TYPE (épée/hache/masse…)          rang 300+
--   * armure/bijou (4)     → par EMPLACEMENT, puis matériau         rang 100+
--   * conteneur (1)        → sac/carquois                           rang 400
--   * non équipable        → catégorie (matières, consommables…)    rang 500+
--   * service sans objet   → « Autres » (enchantements…)            rang 900
-- Exposée en COC.SectionOf : PARTAGÉE avec la vue métier (ProfWindow_Recipes) pour un découpage
-- identique. Fonction pure (aucun état UI) → sûre à appeler depuis n'importe quel module.
local function sectionOf(itemID)
    if not (itemID and INSTANT) then return L["Autres"], 900 end
    local _, iType, iSub, equip, _, classID, subclassID = INSTANT(itemID)
    if classID == 2 then
        return iSub or iType or L["Autres"], 300 + (subclassID or 0)
    elseif classID == 4 then
        local slotName = equip and equip ~= "" and _G[equip]
        if slotName then
            local rank = 100 + (SLOT_ORDER[equip] or 50)
            if MATERIAL_ARMOR[subclassID] and iSub then return slotName .. " · " .. iSub, rank end
            return slotName, rank
        end
        return iSub or iType or L["Autres"], 150
    elseif classID == 1 then
        return iSub or iType or L["Autres"], 400
    end
    return iType or L["Autres"], 500 + (classID or 99)
end
COC.SectionOf = sectionOf
function UI:_PostSection(itemID) return sectionOf(itemID) end

-- Trie la liste filtrée par (section, prêt, nom), construit la liste d'AFFICHAGE plate (en-têtes de
-- section + plans interleavés, hauteurs homogènes PLH) puis fenêtre le pool virtualisé. Appelé par
-- RefreshPostPlans. Le rendu réel (positionnement + remplissage) est dans _RenderPostPlanWindow.
function UI:_RenderPostPlanRows(list)
    for _, item in ipairs(list) do
        item.section, item.secOrder = sectionOf(item.e.itemID)
    end
    table.sort(list, function(a, b)
        if a.secOrder ~= b.secOrder then return a.secOrder < b.secOrder end
        if a.section  ~= b.section  then return a.section  < b.section  end
        if a.ready    ~= b.ready    then return a.ready end   -- « prêt » en tête de SA section (P2)
        return a.name < b.name
    end)
    local disp, lastSec = {}, nil
    for _, item in ipairs(list) do
        if item.section ~= lastSec then disp[#disp + 1] = { isHeader = true, label = item.section }; lastSec = item.section end
        disp[#disp + 1] = item
    end
    self.postPlanDisplay = disp
    self.postPlanContent:SetHeight(math.max(#disp * PLH, 10))
    -- Clamp du scroll si la liste a rétréci (nouveau filtre/recherche) → pas de vide en bas. Le hook
    -- OnVerticalScroll re-fenêtre si le scroll bouge ; on rappelle _RenderPostPlanWindow ensuite
    -- (idempotent) au cas où il n'a pas changé.
    local scroll = self.postPlanScroll
    if scroll then
        local maxScroll = math.max(0, #disp * PLH - (scroll:GetHeight() or 0))
        if (scroll:GetVerticalScroll() or 0) > maxScroll then scroll:SetVerticalScroll(maxScroll) end
    end
    self:_RenderPostPlanWindow()
    Skin.AutoHideScroll("COCPostPlanScroll", self.postPlanContent)
end

-- Fenêtrage : place le pool FIXE de lignes sur la tranche visible de postPlanDisplay (offset = scroll
-- / PLH). Appelé au scroll (hook) et après chaque _RenderPostPlanRows. Coût borné par #postPlanRows.
function UI:_RenderPostPlanWindow()
    local list = self.postPlanDisplay or {}
    local scroll = self.postPlanScroll
    local off = scroll and math.floor((scroll:GetVerticalScroll() or 0) / PLH) or 0
    if off < 0 then off = 0 end
    for i = 1, #(self.postPlanRows or {}) do
        local row, listIdx = self.postPlanRows[i], off + i
        local item = list[listIdx]
        if item then
            row.item = item
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -(listIdx - 1) * PLH)
            self:_FillPostPlanRow(row, item); row:Show()
        else
            row.item = nil; row:Hide()
        end
    end
end

-- Remplit une ligne du pool : soit un EN-TÊTE de section (libellé doré + filet, non interactif),
-- soit un PLAN (badge de rareté, nom, marqueur « [Prêt] », surbrillance de sélection, tooltip objet).
function UI:_FillPostPlanRow(row, item)
    if item.isHeader then
        row:EnableMouse(false)
        row.badge:Hide(); row.name:Hide()
        row.hdr:SetText(item.label); row.hdr:Show(); row.hdrLine:Show()
        row.tipItemID, row.tipSpellID = nil, nil
        return
    end
    row:EnableMouse(true); row.hdr:Hide(); row.hdrLine:Hide()
    local e = item.e
    local r, g, b = Skin.RarityColor(e.itemID)
    row.badge:Paint(r, g, b, Skin.FirstChar(item.name), Skin.Icon(e.itemID, e.spellID)); row.badge:Show()
    local disp = item.name:match("^item:") and "|cFF777777" .. L["Chargement…"] .. "|r" or item.name
    if item.ready then disp = "|cFF33DD33" .. L["[Prêt]"] .. "|r " .. disp end
    row.name:SetText(disp); row.name:Show()
    row.name:SetTextColor(e == self.postEntry and 1 or r, e == self.postEntry and 0.85 or g, e == self.postEntry and 0.27 or b)
    row.tipItemID, row.tipSpellID = e.itemID, e.spellID
end
