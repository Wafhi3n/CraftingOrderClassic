-- CraftingOrderClassic_ProfWindow_Detail.lua — colonne CENTRE : détail de la recette sélectionnée
-- (icône, réactifs have/need) + boutons Créer / Créer tout. Craft via COC.Craft:Do (DoTradeSkill /
-- DoCraft). Port de TradeScanner_ProfWindow_Detail.lua adapté à COC.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L
local PW   = COC.ProfWindow

local REAG_H, MAX_REAG = 18, 8

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
    row:Hide(); return row
end

function PW:_BuildDetail(col)
    local iconBig = col:CreateTexture(nil, "ARTWORK")
    iconBig:SetSize(34, 34); iconBig:SetPoint("TOPLEFT", 12, -10); iconBig:SetTexCoord(0.07, 0.93, 0.07, 0.93); iconBig:Hide()
    self.detIcon = iconBig
    -- Une Texture ne reçoit pas la souris : bouton invisible par-dessus pour le tooltip de l'objet produit.
    local iconBtn = CreateFrame("Button", nil, col); iconBtn:SetAllPoints(iconBig)
    iconBtn:SetScript("OnEnter", function(r) PW:_ProductTooltip(r) end)
    iconBtn:SetScript("OnLeave", GameTooltip_Hide)
    self.detIconBtn = iconBtn

    local nameFS = col:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameFS:SetPoint("TOPLEFT", iconBig, "TOPRIGHT", 8, -2); nameFS:SetPoint("RIGHT", -10, 0)
    nameFS:SetJustifyH("LEFT"); nameFS:SetText("|cFF888888" .. L["Sélectionne une recette."] .. "|r"); self.detNameFS = nameFS

    local makesFS = col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    makesFS:SetPoint("TOPLEFT", iconBig, "BOTTOMRIGHT", 8, -2); makesFS:SetTextColor(Skin.unpack(Skin.color.textMuted)); self.detMakesFS = makesFS

    local reagHdr = col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    reagHdr:SetPoint("TOPLEFT", 12, -52); reagHdr:SetText("|cFFE8B84B" .. L["Réactifs :"] .. "|r"); self.detReagHdr = reagHdr

    local rContainer = CreateFrame("Frame", nil, col)
    rContainer:SetPoint("TOPLEFT", 0, -70); rContainer:SetPoint("RIGHT", col, "RIGHT", 0, 0); rContainer:SetHeight(MAX_REAG * REAG_H)
    self.detReagRows = {}
    for i = 1, MAX_REAG do self.detReagRows[i] = self:_BuildReagentRow(rContainer, i) end

    -- DoCraft (Enchantement) est PROTÉGÉE : un addon ne peut pas l'appeler. Le bouton « Créer » est
    -- donc SÉCURISÉ et redirige le clic vers le bouton natif de Blizzard quand un Craft (enchant) est
    -- ouvert (cf. _WireCreateButton). Métier normal → DoTradeSkill n'est pas protégé : on crafte en
    -- PostClick. On ne pose PAS de OnClick (le template sécurisé s'en sert pour la redirection).
    local createBtn = Skin.MakeGoldButton(col, 72, 22, L["Créer"], "SecureActionButtonTemplate")
    createBtn:SetPoint("BOTTOMRIGHT", -10, 12)
    createBtn:RegisterForClicks("AnyUp")
    createBtn:SetScript("PreClick", function()
        if COC.Craft:IsCraftOpen() then
            local e = PW:GetSelectedRecipe()
            if e and SelectCraft then SelectCraft(e.index) end   -- le bouton natif craftera CETTE recette
        end
    end)
    createBtn:SetScript("PostClick", function()
        if not COC.Craft:IsCraftOpen() then PW:_CraftSelected(false) end   -- TradeSkill : DoTradeSkill
    end)
    self.detCreateBtn = createBtn

    local allBtn = Skin.MakeGoldButton(col, 86, 22, L["Créer tout"])
    allBtn:SetPoint("BOTTOMRIGHT", createBtn, "BOTTOMLEFT", -6, 0)
    allBtn:SetScript("OnClick", function() PW:_CraftSelected(true) end); self.detAllBtn = allBtn

    local qtyBox = CreateFrame("EditBox", nil, col, "InputBoxTemplate")
    qtyBox:SetSize(38, 18); qtyBox:SetPoint("RIGHT", allBtn, "LEFT", -12, 0)
    qtyBox:SetAutoFocus(false); qtyBox:SetNumeric(true); qtyBox:SetText("1")
    qtyBox:SetScript("OnEscapePressed", function(b) b:ClearFocus() end); self.detQtyBox = qtyBox

    local qtyLbl = col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    qtyLbl:SetPoint("RIGHT", qtyBox, "LEFT", -4, 0); qtyLbl:SetText(L["Qté"]); self.detQtyLbl = qtyLbl
end

-- Tooltip de l'objet PRODUIT (grosse icône du détail). Même logique que la ligne de recette :
-- hyperlien si connu, sinon SetCraftSpell (enchant) / SetTradeSkillItem (métier normal) par index.
function PW:_ProductTooltip(anchor)
    local e = self:GetSelectedRecipe(); if not e then return end
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT"); GameTooltip:ClearLines()
    local ok = false
    if e.link then ok = pcall(GameTooltip.SetHyperlink, GameTooltip, e.link)
    elseif COC.Craft:IsCraftOpen() then ok = pcall(GameTooltip.SetCraftSpell, GameTooltip, e.index)
    else ok = pcall(GameTooltip.SetTradeSkillItem, GameTooltip, e.index) end
    if not ok then GameTooltip:SetText(e.name or "?", 1, 1, 1) end
    GameTooltip:Show()
end

function PW:_ClearDetail()
    self.detIcon:Hide()
    self.detNameFS:SetText("|cFF888888" .. L["Sélectionne une recette."] .. "|r")
    self.detMakesFS:SetText("")
    for _, r in ipairs(self.detReagRows) do r:Hide() end
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

function PW:RefreshDetail()
    if not self.detNameFS then return end
    local e = self:GetSelectedRecipe()
    if not e then return self:_ClearDetail() end

    self.detIcon:SetTexture(e.icon or "Interface\\Icons\\INV_Misc_QuestionMark"); self.detIcon:Show()
    self.detNameFS:SetText(e.link or e.name or "?")

    if (e.numMade or 1) > 1 or (e.numMadeMax or 1) > (e.numMade or 1) then
        local mx = e.numMadeMax or e.numMade
        local made = (mx > e.numMade) and (e.numMade .. "-" .. mx) or tostring(e.numMade)
        self.detMakesFS:SetText("|cFF888888" .. L["Produit "] .. made .. "|r")
    else
        self.detMakesFS:SetText("")
    end

    local reags = COC.Craft:Reagents(e.index)
    for i, row in ipairs(self.detReagRows) do
        local rg = reags[i]
        if rg then
            row.reagLink = rg.link
            row.icon:SetTexture(rg.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.nameFS:SetText(rg.name or "?")
            local enough = (rg.have or 0) >= (rg.need or 0)
            local cc = enough and "|cFF33DD33" or "|cFFFF5555"
            row.cntFS:SetText(string.format("%s%d|r|cFF888888/%d|r", cc, rg.have or 0, rg.need or 0))
            row:Show()
        else
            row:Hide()
        end
    end

    local avail   = e.numAvailable or 0
    local isCraft = COC.Craft:IsCraftOpen()
    self:_SetCraftButtons(avail > 0, (not isCraft) and avail > 1)
    self.detAllBtn:SetShown(not isCraft)
    self:_WireCreateButton(isCraft)
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
