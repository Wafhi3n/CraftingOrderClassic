-- CraftingOrderClassic_ProfWindow_Detail.lua — colonne CENTRE : détail de la recette sélectionnée
-- (icône, réactifs have/need) + boutons Créer / Créer tout. Craft via COC.Craft:Do.
-- Port de TradeScanner_ProfWindow_Detail.lua adapté à COC.

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
--
-- Le bouton « Créer » héritait de `SecureActionButtonTemplate` et redirigeait le clic vers le
-- bouton natif `CraftCreateButton` : le seul moyen de crafter un enchant sur l'Era, où `DoCraft`
-- est PROTÉGÉE. Sur la cible, `C_TradeSkillUI.CraftRecipe` ne l'est pas — bouton ORDINAIRE, clic
-- direct, et avec lui disparaissent la redirection, l'armement de la sélection native, le
-- cadre de rejeu en sortie de combat et l'avertissement « bouton natif désactivé ».
function PW:_BuildDetailFooter(fz)
    local createBtn = Skin.MakeGoldButton(fz, 72, 22, L["Créer"])
    createBtn:SetPoint("RIGHT", -10, 0)
    createBtn:SetScript("OnClick", function() PW:_CraftSelected(false) end)
    self.detCreateBtn = createBtn

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

-- Tooltip de l'objet PRODUIT (en-tête du détail : icône + nom). Même logique que la ligne de
-- recette : hyperlien si connu, MANQUANTE par itemID (repli nom via Skin.TipItem — objet pas
-- encore en cache = tooltip vide sinon), sinon SetTradeSkillItem par index.
function PW:_ProductTooltip(anchor)
    local e = self:GetSelectedRecipe(); if not e then return end
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT"); GameTooltip:ClearLines()
    local ok = false
    if e.link then ok = pcall(GameTooltip.SetHyperlink, GameTooltip, e.link)
    elseif e.isMissing then Skin.TipItem(GameTooltip, e.itemID, e.name); ok = true
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
        self:_SetCreateShown(true)
        self.detAllBtn:Show(); self.detQtyBox:Show(); self.detQtyLbl:Show()
    end
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

-- Simple affichage/masquage du bouton « Créer ». Il y avait ici tout un appareil de rejeu en
-- sortie de combat (_EnsureRegenFrame, _WireCreateButton, bouton « Enchanter équipé ») : Show/Hide et
-- SetAttribute sont VERROUILLÉS sur un bouton protégé en combat, il fallait mémoriser l'état
-- voulu et le rejouer à PLAYER_REGEN_ENABLED. Le bouton n'est plus protégé, tout ça a disparu.
--
-- ⚠️ La FENÊTRE, elle, reste protégée : `SetParent` dans `ProfessionsFrame` rend le cadre
-- `IsProtected()` DÉFINITIVEMENT, même re-parenté sur UIParent (mesuré, cf. taint.log). Le
-- masquage par SetAlpha de PW:Hide reste donc indispensable — ne pas le « simplifier » aussi.
-- Le 2ᵉ paramètre est ignoré : il disait s'il fallait câbler la redirection sécurisée.
function PW:_SetCreateShown(shown)
    local b = self.detCreateBtn
    if b then b:SetShown(shown and true or false) end
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
    self:_SetCreateShown(false)
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
    -- protection : un bouton caché n'est pas cliquable.
    if self.rerollKey then
        self:_SetCreateShown(false)
        self.detAllBtn:Hide()
        self.detQtyBox:Hide(); self.detQtyLbl:Hide()
        return
    end

    local avail = e.numAvailable or 0
    -- Plus de dichotomie Craft/TradeSkill : un seul comportement. L'API Craft de l'Era craftait
    -- 1 par clic (pas de compteur, comme l'UI Blizzard) et masquait donc « Créer tout » + la Qté ;
    -- `C_TradeSkillUI.CraftRecipe` prend un nombre de lancers, ils restent visibles partout.
    self:_SetCraftButtons(avail > 0, avail > 1)
    self.detAllBtn:Show(); self.detQtyBox:Show(); self.detQtyLbl:Show()
    self:_SetCreateShown(true)
end

function PW:_CraftSelected(all)
    local e = self:GetSelectedRecipe(); if not e then return end
    local avail = e.numAvailable or 0
    if avail <= 0 then print("|cFF33DD88Crafting Order|r " .. L["réactifs insuffisants."]); return end
    local qty
    if all then
        qty = avail
    else
        qty = tonumber(self.detQtyBox:GetText()) or 1
        if qty < 1 then qty = 1 end
        if qty > avail then qty = avail end
    end
    COC.Craft:Do(e.index, qty)
end
