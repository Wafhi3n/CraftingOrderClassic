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

local SEP   = 308
local LW    = SEP - 14   -- largeur panneau gauche (= locale de _UI_Post.lua)
local PLH   = 20         -- hauteur ligne plan (DOIT égaler _UI_Post.lua : mêmes frames)
local HDR_H = 22         -- hauteur ligne d'en-tête de section

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

-- Ligne d'en-tête de section (frame non cliquable) : libellé doré + filet de séparation.
function UI:_PostHeaderRow(i)
    local r = self.postPlanHeaders[i]; if r then return r end
    r = CreateFrame("Frame", nil, self.postPlanContent); r:SetSize(LW - 22, HDR_H)
    local ln = r:CreateTexture(nil, "ARTWORK"); ln:SetHeight(1)
    ln:SetColorTexture(Skin.color.gold[1], Skin.color.gold[2], Skin.color.gold[3], 0.25)
    ln:SetPoint("BOTTOMLEFT", 2, 3); ln:SetPoint("BOTTOMRIGHT", -2, 3)
    r.text = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.text:SetPoint("BOTTOMLEFT", 4, 5); r.text:SetJustifyH("LEFT")
    r.text:SetTextColor(Skin.unpack(Skin.color.gold)); Skin.ApplyShadow(r.text)
    self.postPlanHeaders[i] = r; return r
end

-- Trie la liste filtrée par (section, prêt, nom) et rend en-têtes + lignes de plan interleavés.
-- Position par curseur `y` accumulé (les en-têtes et les plans n'ont pas la même hauteur), avec
-- deux pools indépendants (postPlanHeaders / postPlanRows). Appelé par RefreshPostPlans.
function UI:_RenderPostPlanRows(list)
    self.postPlanHeaders = self.postPlanHeaders or {}
    for _, item in ipairs(list) do
        item.section, item.secOrder = sectionOf(item.e.itemID)
    end
    table.sort(list, function(a, b)
        if a.secOrder ~= b.secOrder then return a.secOrder < b.secOrder end
        if a.section  ~= b.section  then return a.section  < b.section  end
        if a.ready    ~= b.ready    then return a.ready end   -- « prêt » en tête de SA section (P2)
        return a.name < b.name
    end)
    local pIdx, hIdx, y, lastSec = 0, 0, 0, nil
    for _, item in ipairs(list) do
        if item.section ~= lastSec then
            hIdx = hIdx + 1; local hr = self:_PostHeaderRow(hIdx)
            hr:ClearAllPoints(); hr:SetPoint("TOPLEFT", 0, -y)
            hr.text:SetText(item.section); hr:Show()
            y = y + HDR_H; lastSec = item.section
        end
        pIdx = pIdx + 1; local row = self:_PostPlanRow(pIdx); local e = item.e
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -y)
        local r, g, b = Skin.RarityColor(e.itemID)
        row.badge:Paint(r, g, b, Skin.FirstChar(item.name), Skin.Icon(e.itemID, e.spellID))
        local disp = item.name:match("^item:") and "|cFF777777" .. L["Chargement…"] .. "|r" or item.name
        if item.ready then disp = "|cFF33DD33" .. L["[Prêt]"] .. "|r " .. disp end
        row.name:SetText(disp)
        row.name:SetTextColor(e == self.postEntry and 1 or r, e == self.postEntry and 0.85 or g, e == self.postEntry and 0.27 or b)
        row.entry = e; row.tipItemID, row.tipSpellID = e.itemID, e.spellID
        row:SetScript("OnClick", function() UI:SelectPostPlan(e) end); row:Show()
        y = y + PLH
    end
    for i = pIdx + 1, #self.postPlanRows    do self.postPlanRows[i]:Hide() end
    for i = hIdx + 1, #self.postPlanHeaders do self.postPlanHeaders[i]:Hide() end
    self.postPlanContent:SetHeight(math.max(y, 10))
    Skin.AutoHideScroll("COCPostPlanScroll", self.postPlanContent)
end
