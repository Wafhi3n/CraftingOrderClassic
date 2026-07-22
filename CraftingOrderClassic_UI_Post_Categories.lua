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
-- Exposé en COC.SLOT_ORDER : source UNIQUE du rang d'emplacement — _Enchant.lua en dérive l'ordre
-- de ses sections d'enchants pour que les deux vues restent alignées sans copie à synchroniser.
local SLOT_ORDER = {
    INVTYPE_HEAD = 1, INVTYPE_NECK = 2, INVTYPE_SHOULDER = 3, INVTYPE_CLOAK = 4,
    INVTYPE_CHEST = 5, INVTYPE_ROBE = 5, INVTYPE_BODY = 6, INVTYPE_TABARD = 7,
    INVTYPE_WRIST = 8, INVTYPE_HAND = 9, INVTYPE_WAIST = 10, INVTYPE_LEGS = 11,
    INVTYPE_FEET = 12, INVTYPE_FINGER = 13, INVTYPE_TRINKET = 14,
    INVTYPE_SHIELD = 15, INVTYPE_HOLDABLE = 16,
}
COC.SLOT_ORDER = SLOT_ORDER

-- Sous-classes d'armure « à matériau » (Tissu/Cuir/Mailles/Plaques) : pour elles on suffixe le
-- type après l'emplacement (« Torse · Plaques »), sinon l'emplacement seul suffit (bijoux, dos…).
local MATERIAL_ARMOR = { [1] = true, [2] = true, [3] = true, [4] = true }

-- Section (libellé localisé) + rang de tri d'un objet produit. Libellés issus des globales client
-- (déjà localisées : noms d'emplacement _G[INVTYPE_*], sous-classe/type via GetItemInfoInstant).
--   * gemme (classID 3)    → par COULEUR                            rang 250+
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
    elseif classID == 3 then
        -- Gemme : le subclassID EST la couleur, et `iSub` en porte déjà le libellé LOCALISÉ (« Bleu »).
        -- Sans ce cas, toute la Joaillerie tombait sous un unique en-tête « Gemme » via la branche
        -- fourre-tout du bas. La TAILLE (la stat) est le niveau du dessous : cf. COC.Gem:StatFor.
        return iSub or iType or L["Autres"], 250 + (subclassID or 0)
    elseif classID == 1 then
        return iSub or iType or L["Autres"], 400
    end
    return iType or L["Autres"], 500 + (classID or 99)
end
COC.SectionOf = sectionOf
function UI:_PostSection(itemID) return sectionOf(itemID) end

-- État de repliage des en-têtes, MÉMORISÉ PAR MÉTIER (durée de session).
function UI:_PostCollapseTable()
    self.postCollapsed = self.postCollapsed or {}
    local k = self.postProf or "?"
    self.postCollapsed[k] = self.postCollapsed[k] or {}
    return self.postCollapsed[k]
end

function UI:TogglePostSection(ckey)
    if not ckey then return end
    local col = self:_PostCollapseTable()
    col[ckey] = (not col[ckey]) or nil
    self:RefreshPostPlans()
end

-- Construit la liste d'AFFICHAGE plate (en-têtes de section, de sous-catégorie, et plans interleavés
-- — hauteurs homogènes PLH) puis fenêtre le pool virtualisé. Appelé par RefreshPostPlans. Le rendu
-- réel (positionnement + remplissage) est dans _RenderPostPlanWindow.
-- Le regroupement lui-même (sections, sous-catégories, tri par niveau ↓, repliage) est délégué à
-- COC.RecipeCats:BuildDisplay — MÊME moteur que la vue métier, donc mêmes catégories des deux côtés.
-- Le « prêt » (P2) reste prioritaire, mais à l'intérieur de SA sous-catégorie : le regroupement prime.
-- Pendant une RECHERCHE le repliage est ignoré, sinon un résultat pourrait rester invisible.
function UI:_RenderPostPlanRows(list)
    local searching = (self.postSearch or "") ~= ""
    -- Tri par rentabilité (Lazy Gold) : liste À PLAT, sans sections — on veut le classement global du
    -- plus rentable au moins. Sinon, regroupement normal.
    -- Classement dérivé du sort (enchantements : emplacement › stat ; gemmes : couleur › taille) —
    -- MÊME dispatch que la vue métier, écrit une seule fois : cf. RecipeCats.SectionForSpell.
    local disp = self:_PostProfitFlat(list) or COC.RecipeCats:BuildDisplay(self.postProf, list, {
        itemID    = function(it) return it.e and it.e.itemID end,
        section   = function(it) return COC.RecipeCats.SectionForSpell(it.e and it.e.spellID) end,
        sub       = function(it)
            local e = it.e
            return COC.RecipeCats.SubForSpell(self.postProf, e and e.spellID, e and e.itemID)
        end,
        name      = function(it) return it.name or "" end,
        before    = function(a, b) if a.ready ~= b.ready then return a.ready end end,
        collapsed = searching and nil or self:_PostCollapseTable(),
    })
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
-- En-tête : chevron +/-, libellé (doré pour une section, bronze pour une sous-catégorie indentée) et
-- compte. Cliquable → replie/déplie (cf. OnClick de _PostPlanRow).
function UI:_FillPostPlanHeader(row, item)
    row:EnableMouse(true)
    row.badge:Hide(); row.name:Hide()
    if row.profit then row.profit:Hide() end   -- ligne recyclée : sinon le montant du plan précédent reste
    row.tipItemID, row.tipSpellID = nil, nil
    local sub  = (item.depth == 2)
    local open = not self:_PostCollapseTable()[item.ckey] or (self.postSearch or "") ~= ""
    row.expand:SetTexture(open and "Interface\\Buttons\\UI-MinusButton-Up" or "Interface\\Buttons\\UI-PlusButton-Up")
    row.expand:ClearAllPoints(); row.expand:SetPoint("LEFT", sub and 14 or 2, 0); row.expand:Show()
    local label = item.label or ""
    if item.count and item.count > 0 then label = label .. string.format(" |cFF888888(%d)|r", item.count) end
    row.hdr:ClearAllPoints(); row.hdr:SetPoint("LEFT", row.expand, "RIGHT", 2, 0)
    row.hdr:SetText(label); row.hdr:Show()
    if sub then row.hdr:SetTextColor(0.79, 0.64, 0.15) else row.hdr:SetTextColor(Skin.unpack(Skin.color.gold)) end
    row.hdrLine:SetShown(not sub)   -- le filet ne souligne que les sections, sinon la liste est zébrée
end

function UI:_FillPostPlanRow(row, item)
    if item.isHeader then return self:_FillPostPlanHeader(row, item) end
    row:EnableMouse(true); row.hdr:Hide(); row.hdrLine:Hide(); row.expand:Hide()
    local e = item.e
    local r, g, b = Skin.RarityColor(e.itemID)
    -- Les plans d'une sous-catégorie sont décalés sous leur en-tête.
    local indent = item._sub and 14 or 0
    row.badge:ClearAllPoints(); row.badge:SetPoint("LEFT", 2 + indent, 0)
    row.name:ClearAllPoints(); row.name:SetPoint("LEFT", 20 + indent, 0)
    row.badge:Paint(r, g, b, Skin.FirstChar(item.name), Skin.Icon(e.itemID, e.spellID)); row.badge:Show()
    -- Enchant d'équipement : la STAT seule — l'emplacement/stat de base est déjà porté par les 2 en-têtes
    -- au-dessus (« Enchant Bracer - … » ×N devient juste « Superior Strength » sous Wrist › Strength).
    local shortName = (COC.Enchant and COC.Enchant:ShortName(item.name, e.spellID)) or item.name
    local disp = item.name:match("^item:") and "|cFF777777" .. L["Chargement…"] .. "|r" or shortName
    if item.ready then disp = "|cFF33DD33" .. L["[Prêt]"] .. "|r " .. disp end
    row.name:SetText(disp); row.name:Show()
    row.name:SetTextColor(e == self.postEntry and 1 or r, e == self.postEntry and 0.85 or g, e == self.postEntry and 0.27 or b)
    self:_FillPostPlanProfit(row, item)   -- rentabilité Lazy Gold (rétrécit le nom si présente)
    row.tipItemID, row.tipSpellID = e.itemID, e.spellID
end
