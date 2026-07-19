-- CraftingOrderClassic_ProfWindow_Detail.lua — colonne CENTRE : détail de la recette sélectionnée
-- (icône, réactifs have/need) + boutons Créer / Créer tout. Craft via COC.Craft:Do (DoTradeSkill /
-- DoCraft). Port de TradeScanner_ProfWindow_Detail.lua adapté à COC.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L
local PW   = COC.ProfWindow

local REAG_H, MAX_REAG = 18, 8

-- Redirection sécurisée vers un bouton natif DÉSACTIVÉ (réactifs manquants) = no-op SILENCIEUX (le
-- natif n'affiche pas d'erreur) → on prévient. Partagé par les PreClick de Créer et Enchanter équipé.
local function warnIfNativeDisabled()
    local cb = _G.CraftCreateButton
    if cb and cb.IsEnabled and not cb:IsEnabled() then
        print("|cFF33DD88Crafting Order|r " .. L["réactifs insuffisants."])
    end
end

function PW:_BuildReagentRow(parent, i)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(228, REAG_H); row:SetPoint("TOPLEFT", 10, -(i - 1) * REAG_H)
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(REAG_H - 4, REAG_H - 4); icon:SetPoint("LEFT", 0, 0); icon:SetTexCoord(0.07, 0.93, 0.07, 0.93); row.icon = icon
    local nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameFS:SetPoint("LEFT", icon, "RIGHT", 4, 0); nameFS:SetJustifyH("LEFT"); nameFS:SetWordWrap(false); nameFS:SetWidth(140); row.nameFS = nameFS
    local cntFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cntFS:SetPoint("RIGHT", 0, 0); cntFS:SetJustifyH("RIGHT"); row.cntFS = cntFS
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(r)
        if not r.reagLink then return end
        GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
        if pcall(GameTooltip.SetHyperlink, GameTooltip, r.reagLink) then GameTooltip:Show() else GameTooltip:Hide() end
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    Skin.WireItemLink(row)   -- shift-clic → lien chat du réactif (tipLink posé au remplissage)
    row:Hide(); return row
end

-- Zones SPEC de la colonne (cf. _ProfWindow_Layout.lua) : detBody (contenu) / detFoot (bande pied :
-- Qté + Créer tout + Créer, ancrés LEFT/RIGHT = centrés verticalement dans la bande).
function PW:_BuildDetail(col)
    local body = self:Sec("detBody") or col
    local fz   = self:Sec("detFoot") or col
    self.detColFrame = body   -- réutilisé par le panneau d'INFO en sections (cf. _ProfWindow_Info.lua)
    local iconBig = body:CreateTexture(nil, "ARTWORK")
    iconBig:SetSize(34, 34); iconBig:SetPoint("TOPLEFT", 12, -10); iconBig:SetTexCoord(0.07, 0.93, 0.07, 0.93); iconBig:Hide()
    self.detIcon = iconBig
    -- Une Texture ne reçoit pas la souris : bouton invisible par-dessus pour le tooltip de l'objet
    -- produit. Il couvre l'icône ET le nom (retour user 2026-07-19 : survoler « [Pendant of …] »
    -- ne montrait rien — la zone de tooltip s'arrêtait aux 34 px de l'icône).
    local iconBtn = CreateFrame("Button", nil, body)
    iconBtn:SetPoint("TOPLEFT", iconBig, "TOPLEFT", 0, 0)
    iconBtn:SetPoint("BOTTOMLEFT", iconBig, "BOTTOMLEFT", 0, 0)
    iconBtn:SetPoint("RIGHT", body, "RIGHT", -10, 0)
    iconBtn:SetScript("OnEnter", function(r) PW:_ProductTooltip(r) end)
    iconBtn:SetScript("OnLeave", GameTooltip_Hide)
    Skin.WireItemLink(iconBtn)   -- shift-clic sur l'icône produit → lien chat
    self.detIconBtn = iconBtn

    local nameFS = body:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameFS:SetPoint("TOPLEFT", iconBig, "TOPRIGHT", 8, -2); nameFS:SetPoint("RIGHT", -10, 0)
    nameFS:SetJustifyH("LEFT"); nameFS:SetText("|cFF888888" .. L["Sélectionne une recette."] .. "|r"); self.detNameFS = nameFS

    local makesFS = body:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    makesFS:SetPoint("TOPLEFT", iconBig, "BOTTOMRIGHT", 8, -2); makesFS:SetTextColor(Skin.unpack(Skin.color.textMuted)); self.detMakesFS = makesFS

    local reagHdr = body:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    reagHdr:SetPoint("TOPLEFT", 12, -52); reagHdr:SetText("|cFFE8B84B" .. L["Réactifs :"] .. "|r"); self.detReagHdr = reagHdr

    -- Bouton « Diffuser » (liste de courses) : ouvre la popup canal + envoie les liens des réactifs.
    local shareBtn = Skin.MakeGoldButton(body, 82, 18, L["Diffuser"])
    shareBtn:SetPoint("LEFT", reagHdr, "RIGHT", 14, 1)
    shareBtn:SetScript("OnClick", function() PW:_ShareReagents() end)
    shareBtn:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_RIGHT"); GameTooltip:SetText(L["Diffuser les réactifs dans un canal"], 1, 1, 1); GameTooltip:Show()
    end)
    shareBtn:SetScript("OnLeave", GameTooltip_Hide)
    shareBtn:Hide(); self.detShareBtn = shareBtn

    local rContainer = CreateFrame("Frame", nil, body)
    rContainer:SetPoint("TOPLEFT", 0, -70); rContainer:SetPoint("RIGHT", body, "RIGHT", 0, 0); rContainer:SetHeight(MAX_REAG * REAG_H)
    self.detReagRows = {}
    for i = 1, MAX_REAG do self.detReagRows[i] = self:_BuildReagentRow(rContainer, i) end

    self:_BuildDetailFooter(fz)
end

-- Bande PIED du détail : Créer / Créer tout / Qté. Extrait de _BuildDetail (anti-monolithe).
function PW:_BuildDetailFooter(fz)
    -- DoCraft (Enchantement) est PROTÉGÉE : un addon ne peut pas l'appeler. Le bouton « Créer » est
    -- donc SÉCURISÉ et redirige le clic vers le bouton natif de Blizzard quand un Craft (enchant) est
    -- ouvert (cf. _WireCreateButton). Métier normal → DoTradeSkill n'est pas protégé : on crafte en
    -- PostClick. On ne pose PAS de OnClick (le template sécurisé s'en sert pour la redirection).
    local createBtn = Skin.MakeGoldButton(fz, 72, 22, L["Créer"], "SecureActionButtonTemplate")
    createBtn:SetPoint("RIGHT", -10, 0)
    createBtn:RegisterForClicks("AnyUp")
    -- ⚠️ AUCUN SelectCraft au PreClick (prouvé en jeu : le bouton natif « Enchant » marche au 1er clic ;
    -- notre redirection demandait un spam). Cause : Blizzard DÉSACTIVE CraftCreateButton à CHAQUE
    -- CRAFT_UPDATE (`Blizzard_CraftUI.lua`), et SelectCraft() FIRE CRAFT_UPDATE. Un SelectCraft au
    -- PreClick re-désactivait donc le bouton natif juste AVANT que le clic sécurisé ne lui soit redirigé
    -- → clic dans le vide. La sélection native est DÉJÀ alignée à l'affichage de la recette
    -- (RefreshDetail → _SyncNativeCraftSelection), donc le PreClick est inutile : on le supprime, le
    -- bouton natif reste ACTIVÉ, le 1er clic crafte. (PostClick reste pour le métier normal, DoTradeSkill.)
    createBtn:SetScript("PostClick", function()
        if not COC.Craft:IsCraftOpen() then PW:_CraftSelected(false) end   -- TradeSkill : DoTradeSkill
    end)
    -- Enchant (craft) : le clic est redirigé vers le bouton natif — s'il est désactivé, on prévient.
    -- PreClick est non sécurisé (autorisé) et n'altère pas le clic sécurisé.
    createBtn:SetScript("PreClick", function()
        if COC.Craft:IsCraftOpen() then warnIfNativeDisabled() end
    end)
    self.detCreateBtn = createBtn
    self:_BuildEquipButton(fz)

    local allBtn = Skin.MakeGoldButton(fz, 86, 22, L["Créer tout"])
    allBtn:SetPoint("RIGHT", createBtn, "LEFT", -6, 0)
    allBtn:SetScript("OnClick", function() PW:_CraftSelected(true) end); self.detAllBtn = allBtn

    local qtyBox = CreateFrame("EditBox", nil, fz, "InputBoxTemplate")
    qtyBox:SetSize(38, 18); qtyBox:SetPoint("RIGHT", allBtn, "LEFT", -12, 0)
    qtyBox:SetAutoFocus(false); qtyBox:SetNumeric(true); qtyBox:SetText("1")
    qtyBox:SetScript("OnEscapePressed", function(b) b:ClearFocus() end); self.detQtyBox = qtyBox

    local qtyLbl = fz:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    qtyLbl:SetPoint("RIGHT", qtyBox, "LEFT", -4, 0); qtyLbl:SetText(L["Qté"]); self.detQtyLbl = qtyLbl
end

-- Bouton « Enchanter équipé » (enchants d'équipement seulement) : bouton SÉCURISÉ qui, dans le MÊME clic,
-- lance le DoCraft ET applique l'enchant sur la pièce PORTÉE via l'attribut `target-slot` (cf.
-- SecureTemplates OnActionButtonClick : après DoCraft, si SpellCanTargetItem() → UseInventoryItem(slot)).
-- Câblé/affiché par _SyncEquipButton selon la recette. PreClick : arme l'auto-accept de la popup
-- « Remplacer » + prévient si réactifs manquants (redirection sur bouton désactivé = no-op silencieux).
function PW:_BuildEquipButton(fz)
    local b = Skin.MakeGoldButton(fz, 132, 22, L["Enchanter équipé"], "SecureActionButtonTemplate")
    b:SetPoint("RIGHT", self.detCreateBtn, "LEFT", -6, 0)
    b:RegisterForClicks("AnyUp")
    -- Sélection changée EN COMBAT : SetAttribute est verrouillé → `target-slot` arme encore l'ANCIENNE
    -- pièce alors que DoCraft partirait sur la NOUVELLE sélection native (CraftFrame_SetSelection n'est
    -- pas protégée, elle, et RefreshDetail continue de l'appeler). On NEUTRALISE le clic via le bouton
    -- natif (Enable/Disable ne sont PAS protégés) plutôt que de laisser partir un couple incohérent ;
    -- PostClick ré-arme aussitôt la sélection courante (le bouton Créer reste fonctionnel).
    b:SetScript("PreClick", function(btn)
        local cur = GetCraftSelectionIndex and GetCraftSelectionIndex()
        if InCombatLockdown() and btn._armedIndex and cur and cur ~= btn._armedIndex then
            btn._blocked = true
            local cb = _G.CraftCreateButton
            if cb and cb.Disable then cb:Disable() end
            print("|cFF33DD88Crafting Order|r " .. L["Sélection changée en combat — réessaie après le combat."])
            return
        end
        warnIfNativeDisabled()
    end)
    b:SetScript("PostClick", function(btn)
        if not btn._blocked then return end
        btn._blocked = nil
        local cur = GetCraftSelectionIndex and GetCraftSelectionIndex()
        if cur then COC.Craft:ArmNativeSelection(cur) end
    end)
    b:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:SetText(L["Enchante directement la pièce équipée — sans cibler."], 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    b:Hide(); self.detEquipBtn = b
end

-- Tooltip de l'objet PRODUIT (en-tête du détail : icône + nom). Même logique que la ligne de
-- recette : hyperlien si connu, MANQUANTE par itemID (repli nom via Skin.TipItem — objet pas
-- encore en cache = tooltip vide sinon), sinon SetCraftSpell/SetTradeSkillItem par index.
function PW:_ProductTooltip(anchor)
    local e = self:GetSelectedRecipe(); if not e then return end
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT"); GameTooltip:ClearLines()
    local ok = false
    if e.link then ok = pcall(GameTooltip.SetHyperlink, GameTooltip, e.link)
    elseif e.isMissing then Skin.TipItem(GameTooltip, e.itemID, e.name); ok = true
    elseif e.index and COC.Craft:IsCraftOpen() then ok = pcall(GameTooltip.SetCraftSpell, GameTooltip, e.index)
    elseif e.index then ok = pcall(GameTooltip.SetTradeSkillItem, GameTooltip, e.index) end
    if not ok or GameTooltip:NumLines() == 0 then GameTooltip:SetText(e.name or "?", 1, 1, 1) end
    GameTooltip:Show()
end

function PW:_ClearDetail()
    self.detIcon:Hide()
    self.detIconBtn.tipLink, self.detIconBtn.tipItemID = nil, nil
    self.detNameFS:SetText("|cFF888888" .. L["Sélectionne une recette."] .. "|r")
    self.detMakesFS:SetText("")
    if self._HideInfoPanel then self:_HideInfoPanel() end
    self.detReagHdr:Show()
    if self.detShareBtn then self.detShareBtn:Hide() end
    for _, r in ipairs(self.detReagRows) do r:Hide() end
    -- Ré-affiche les boutons hors mode reroll (une visite en vue reroll a pu les masquer) — sinon ils
    -- restaient invisibles jusqu'à la prochaine sélection. En reroll : lecture seule, on les laisse cachés.
    if not self.rerollKey then
        local isCraft = COC.Craft and COC.Craft:IsCraftOpen()
        self:_SetCreateShown(true)
        self.detAllBtn:SetShown(not isCraft)
        self.detQtyBox:SetShown(not isCraft); self.detQtyLbl:SetShown(not isCraft)
    end
    self:_SyncEquipButton(nil)   -- aucune recette sélectionnée → pas d'enchant équipé
    self:_SetCraftButtons(false, false)
end

function PW:_SetCraftButtons(canCreate, canAll)
    local function paint(btn, on)
        if not btn then return end
        btn._on = on
        btn.text:SetTextColor(on and 0.941 or 0.45, on and 0.776 or 0.45, on and 0.455 or 0.45)
    end
    paint(self.detCreateBtn, canCreate); paint(self.detAllBtn, canAll)
end

-- Le bouton « Créer » hérite de SecureActionButtonTemplate → il est PROTÉGÉ, donc Show/Hide DESSUS
-- lèvent ADDON_ACTION_BLOCKED en combat — et masquer la FENÊTRE qui l'héberge affiché le lève AUSSI
-- (vu en jeu ; PW:Hide escamote alors via SetAlpha). On mémorise l'état voulu et on le rejoue à la
-- sortie de combat. En attendant, le bouton reste visible mais inoffensif : _SetCraftButtons le grise et
-- _CraftSelected refuse (numAvailable nil hors fenêtre native = 0 réactif).
-- `wireCraft` nil = ne pas toucher à la redirection sécurisée.
-- Cadre de rejeu en sortie de combat, PARTAGÉ par les 2 boutons sécurisés (Créer + Enchanter équipé) :
-- Show/Hide/SetAttribute sur un bouton protégé sont VERROUILLÉS en combat → on mémorise l'état voulu
-- (_createWant / _equipSlot+_equipIndex) et on le rejoue à PLAYER_REGEN_ENABLED.
function PW:_EnsureRegenFrame()
    if self._regenFrame then return end
    local rf = CreateFrame("Frame")
    rf:RegisterEvent("PLAYER_REGEN_ENABLED")
    rf:SetScript("OnEvent", function()
        PW:_SetCreateShown(PW._createWant, PW._createWire)
        PW:_SyncEquipButton(PW._equipSlot, PW._equipIndex)
    end)
    self._regenFrame = rf
end

function PW:_SetCreateShown(shown, wireCraft)
    self._createWant, self._createWire = shown, wireCraft
    local b = self.detCreateBtn
    if not b then return end
    if InCombatLockdown() then self:_EnsureRegenFrame(); return end
    b:SetShown(shown)
    if wireCraft ~= nil then self:_WireCreateButton(wireCraft) end
end

-- Affiche/masque + câble le bouton « Enchanter équipé ». `slot` = id d'emplacement d'inventaire ciblé
-- (nil = pas un enchant d'équipement → masqué) ; `index` = recette de craft armée, mémorisée sur le
-- bouton (le PreClick s'en sert pour détecter un `target-slot` périmé en combat). Câblage sécurisé :
-- type=click + clickbutton natif + target-slot → un seul clic fait DoCraft PUIS UseInventoryItem(slot)
-- (application auto sur la pièce portée). Différé en combat comme le bouton Créer (SetAttribute/Show
-- verrouillés) : l'état VOULU (_equipSlot/_equipIndex) est rejoué à PLAYER_REGEN_ENABLED.
function PW:_SyncEquipButton(slot, index)
    self._equipSlot, self._equipIndex = slot, index
    local b = self.detEquipBtn
    if not b then return end
    if InCombatLockdown() then self:_EnsureRegenFrame(); return end
    b:SetShown(slot and true or false)
    if slot then
        b:SetAttribute("type", "click")
        b:SetAttribute("clickbutton", _G.CraftCreateButton)
        b:SetAttribute("target-slot", slot)
        b._armedIndex = index
    else
        b:SetAttribute("type", nil); b:SetAttribute("clickbutton", nil); b:SetAttribute("target-slot", nil)
        b._armedIndex = nil
    end
end

-- Branche/débranche la redirection sécurisée du bouton « Créer » selon le métier ouvert. À n'appeler
-- QUE hors combat (SetAttribute est verrouillé en combat — de toute façon on ne crafte pas en combat).
function PW:_WireCreateButton(isCraft)
    local b = self.detCreateBtn
    if not b or InCombatLockdown() then return end
    if isCraft then
        b:SetAttribute("type", "click")
        b:SetAttribute("clickbutton", _G.CraftCreateButton)   -- bouton natif « Enchanter » (sécurisé)
    else
        b:SetAttribute("type", nil)
        b:SetAttribute("clickbutton", nil)
    end
end

-- Aligne la sélection native (et l'ARMEMENT de CraftCreateButton) sur la recette affichée. Toute la
-- mécanique — et l'historique du bug intermittent « Créer ne crafte pas » (SelectCraft n'émet pas de
-- CRAFT_UPDATE) — vit dans COC.Craft:ArmNativeSelection, PARTAGÉ avec le panneau d'échange
-- (_Enchant_Trade). Nos `e` ne sont jamais des en-têtes (filtrés en amont, cf. GetSelectedRecipe).
function PW:_SyncNativeCraftSelection(e)
    if not (e and e.index) then return end
    COC.Craft:ArmNativeSelection(e.index)
end

-- Détail d'une recette MANQUANTE : pas de réactifs ni de bouton Créer (on ne l'a pas apprise). À la
-- place, un panneau d'INFO en SECTIONS empilées (cf. _ProfWindow_Info.lua) — d'abord « Où l'obtenir »
-- (pont MTSL : niveau, prix, appris de, vendeur/butin + PNJ/zone/coords), et de la place pour d'autres
-- sections fournies par de futurs addons enregistrés.
function PW:_ShowMissingDetail(e)
    self.detIcon:SetTexture(e.icon or "Interface\\Icons\\INV_Scroll_03"); self.detIcon:Show()
    self.detIconBtn.tipLink, self.detIconBtn.tipItemID = nil, e.itemID   -- shift-clic → lien de l'objet produit
    self.detNameFS:SetText((e.name or "?") .. "  |cFF888888(" .. L["niveau"] .. " " .. (e.level or 0) .. ")|r")
    self.detMakesFS:SetText("|cFFFF8855" .. L["Non apprise"] .. "|r")
    self.detReagHdr:Hide()
    if self.detShareBtn then self.detShareBtn:Hide() end
    for _, r in ipairs(self.detReagRows) do r:Hide() end
    self:_RenderInfoPanel(e)

    -- Aucun craft possible : on masque Créer/Créer tout/Qté (differé en combat pour le bouton sécurisé).
    self:_SetCreateShown(false, false)
    self:_SyncEquipButton(nil)
    self.detAllBtn:Hide(); self.detQtyBox:Hide(); self.detQtyLbl:Hide()
end

-- Remplit les lignes de réactifs (have/need, ou « à fournir » sans have en mode reroll). Extrait de
-- RefreshDetail (anti-monolithe). Restaure aussi l'en-tête + la largeur du libellé que le détail
-- « manquante » a pu changer.
function PW:_FillReagentRows(e)
    self.detReagHdr:Show(); self.detReagHdr:SetText("|cFFE8B84B" .. L["Réactifs :"] .. "|r")
    local reags = self.rerollKey and self:_RerollReagents(e.index) or COC.Craft:Reagents(e.index)
    local nReag = 0
    for i, row in ipairs(self.detReagRows) do
        local rg = reags[i]
        if rg then
            nReag = i
            row.reagLink = rg.link
            row.tipLink = rg.link   -- shift-clic → lien chat (WireItemLink)
            row.icon:SetTexture(rg.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.nameFS:SetWidth(140)   -- restaure la largeur réactif (le détail « manquante » la passe à 230)
            row.nameFS:SetText(rg.name or "?")
            if rg.readonly then                       -- reroll : quantité requise seule (sacs inconnus)
                row.cntFS:SetText(string.format("|cFF888888x%d|r", rg.need or 0))
            else
                local enough = (rg.have or 0) >= (rg.need or 0)
                local cc = enough and "|cFF33DD33" or "|cFFFF5555"
                row.cntFS:SetText(string.format("%s%d|r|cFF888888/%d|r", cc, rg.have or 0, rg.need or 0))
            end
            row:Show()
        else
            row:Hide()
        end
    end
    if self.detShareBtn then self.detShareBtn:SetShown(nReag > 0) end
    -- Sections d'info SOUS les réactifs (ex. « Rentabilité » Lazy Gold). REAG_H = hauteur d'une ligne
    -- réactif ; on démarre juste sous la dernière + une petite marge. Vide (0 ligne) = rien ne s'affiche.
    if self._RenderInfoPanel then self:_RenderInfoPanel(e, -70 - nReag * REAG_H - 12) end
end

-- Diffuse les réactifs de la recette sélectionnée (liste de courses → popup canal). Utilise les mêmes
-- réactifs que l'affichage : reroll = « à fournir » (lecture seule), sinon les réactifs du métier ouvert.
function PW:_ShareReagents()
    local e = self:GetSelectedRecipe(); if not e then return end
    local reags = self.rerollKey and self:_RerollReagents(e.index) or COC.Craft:Reagents(e.index)
    local items = {}
    for _, rg in ipairs(reags or {}) do
        items[#items + 1] = { link = rg.link, name = rg.name, qty = rg.need }
    end
    if COC.ShareReagents then COC.ShareReagents:Open(e.name or "?", items) end
end

function PW:RefreshDetail()
    if not self.detNameFS then return end
    local e = self:GetSelectedRecipe()
    if not e then return self:_ClearDetail() end
    if e.isMissing then return self:_ShowMissingDetail(e) end

    self.detIcon:SetTexture(e.icon or "Interface\\Icons\\INV_Misc_QuestionMark"); self.detIcon:Show()
    self.detNameFS:SetText(e.link or e.name or "?")
    self.detIconBtn.tipLink, self.detIconBtn.tipItemID = e.link, e.itemID   -- shift-clic → lien produit

    if (e.numMade or 1) > 1 or (e.numMadeMax or 1) > (e.numMade or 1) then
        local mx = e.numMadeMax or e.numMade
        local made = (mx > e.numMade) and (e.numMade .. "-" .. mx) or tostring(e.numMade)
        self.detMakesFS:SetText("|cFF888888" .. L["Produit "] .. made .. "|r")
    else
        self.detMakesFS:SetText("")
    end

    self:_FillReagentRows(e)

    -- Vue reroll = LECTURE SEULE : aucun bouton créer (on n'est pas sur ce perso). Le Hide() EST la
    -- protection (un bouton caché n'est pas cliquable) et le désarmement de l'attribut sécurisé évite
    -- qu'un futur réaffichage hérite d'un clickbutton pointant sur CraftCreateButton natif. Les deux
    -- sont DIFFÉRÉS en combat (bouton protégé) → _SetCreateShown les rejoue à PLAYER_REGEN_ENABLED.
    if self.rerollKey then
        self:_SetCreateShown(false, false)
        self:_SyncEquipButton(nil)
        self.detAllBtn:Hide()
        self.detQtyBox:Hide(); self.detQtyLbl:Hide()
        return
    end

    local avail   = e.numAvailable or 0
    local isCraft = COC.Craft:IsCraftOpen()
    self:_SetCraftButtons(avail > 0, (not isCraft) and avail > 1)
    self.detAllBtn:SetShown(not isCraft)
    -- Craft (enchant) = 1 par clic (l'API n'a pas de compteur, comme l'UI Blizzard) → pas de Qté.
    self.detQtyBox:SetShown(not isCraft)
    self.detQtyLbl:SetShown(not isCraft)
    if isCraft then self:_SyncNativeCraftSelection(e) end   -- active CraftCreateButton pour CETTE recette
    self:_SetCreateShown(true, isCraft)
    -- Enchant d'équipement (slot résolu) → bouton « Enchanter équipé » (application directe sur la pièce
    -- portée). Huiles/baguettes/métier normal → pas de slot → masqué.
    local slot = isCraft and COC.Enchant and COC.Enchant:SlotFor(e.spellID) or nil
    self:_SyncEquipButton(slot, e.index)
end

function PW:_CraftSelected(all)
    local e = self:GetSelectedRecipe(); if not e then return end
    local avail = e.numAvailable or 0
    if avail <= 0 then print("|cFF33DD88Crafting Order|r " .. L["réactifs insuffisants."]); return end
    local qty
    if all then
        if COC.Craft:IsCraftOpen() then return end
        qty = avail
    else
        qty = tonumber(self.detQtyBox:GetText()) or 1
        if qty < 1 then qty = 1 end
        if qty > avail then qty = avail end
    end
    COC.Craft:Do(e.index, qty)
end
