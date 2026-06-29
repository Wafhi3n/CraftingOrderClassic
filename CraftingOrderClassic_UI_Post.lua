-- CraftingOrderClassic_UI_Post.lua — onglet « Commande » : sélection de plan (gauche) +
-- réactifs « je fournis » / commission g-s-c / ciblage artisan (droite). Chargé après _UI.lua.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L   -- localisation du chrome (clé = FR ; overlay enUS). NB : les VALEURS canoniques
                     -- de destinataire restent en FR (clé) pour rester identiques sur le réseau.

local PLH = 20    -- hauteur ligne plan
local RRH = 21    -- hauteur ligne réactif
local ARH = 26    -- hauteur ligne artisan

-- Filtre qualité MINIMALE (cycle) : false = Toutes, sinon seuil WoW (2=Inhabituel, 3=Rare, 4=Épique).
-- Les NOMS de qualité sont localisés par le client via _G["ITEM_QUALITY<n>_DESC"] (zéro clé à baker).
local QUALITY_STEPS = { false, 2, 3, 4 }

local SEP  = 308   -- x séparateur gauche/droite
local LW   = SEP - 14          -- largeur panneau gauche (zone visible)
local LSW  = LW - 22           -- largeur scroll gauche (laisse la place à la scrollbar avant le séparateur)
local RX   = SEP + 8           -- x départ panneau droit
local REDGE = 846              -- bord droit utile (sous la bordure dorée)
local RW   = 818 - RX          -- largeur scroll droit (scrollbar finit avant REDGE)

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end
local function isSoulbound(id) return id and GetItemInfo and select(14, GetItemInfo(id)) == 1 end
local function entryName(e)
    local c = CL(); if not c then return "?" end
    return e.itemID and c:ItemName(e.itemID) or c:RecipeName(e.spellID)
end
local function sep1px(parent, x1, x2, y)
    local s = parent:CreateTexture(nil, "ARTWORK"); s:SetHeight(1)
    s:SetColorTexture(Skin.color.separator[1], Skin.color.separator[2], Skin.color.separator[3], 0.5)
    s:SetSize(x2 - x1, 1); s:SetPoint("TOPLEFT", x1, y); return s
end

-- =========================================================================
-- Construction principale
-- =========================================================================
function UI:BuildPostTab(f)
    local panel = CreateFrame("Frame", nil, f); self.insetPanel(panel, f); panel:Hide()
    self.postPanel   = panel
    self.postProvide = {}
    self.postTarget  = "all"
    self.postSource  = "guild"

    sep1px(panel, SEP, SEP + 1, -82):SetSize(1, 494)    -- ligne verticale gauche/droite

    self:_BuildPostLeft(panel)
    self:_BuildPostRight(panel)
    -- (résolution des noms async : handler central dans _UI.lua)
end

-- Professions de récolte pure (aucune recette) → exclues de l'onglet Commande, elles vivent
-- dans l'onglet Récolte. Mining reste ici (fonte = recettes) ET dans Récolte (minerais).
local GATHER_ONLY = { Fishing = true, Herbalism = true, Skinning = true }

-- =========================================================================
-- Panneau gauche : dropdown métier + liste des plans
-- =========================================================================
function UI:_BuildPostLeft(panel)
    local hdrLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hdrLbl:SetPoint("TOPLEFT", 14, -80); hdrLbl:SetText(L["MÉTIER"])
    hdrLbl:SetTextColor(Skin.unpack(Skin.color.textMuted))

    local pBtn = Skin.MakeGoldButton(panel, LW, 22, "—"); pBtn:SetPoint("TOPLEFT", 12, -98)
    -- L'icône du métier est DANS le dropdown, collée au nom du métier sélectionné.
    self.postProfBadge = Skin.MakeBadge(pBtn, 16); self.postProfBadge:SetPoint("LEFT", 5, 0)
    pBtn.text:SetJustifyH("LEFT"); pBtn.text:ClearAllPoints(); pBtn.text:SetPoint("LEFT", 26, 0)
    local arrow = pBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    arrow:SetPoint("RIGHT", -6, 0); arrow:SetText("▾"); arrow:SetTextColor(Skin.unpack(Skin.color.gold))
    self.postProfBtn = pBtn
    pBtn:SetScript("OnClick", function() UI:_ToggleProfFlyout() end)

    -- Flyout (hors hiérarchie du panel pour passer au-dessus)
    local fly = CreateFrame("Frame", "COCProfFlyout", UIParent, "BackdropTemplate")
    fly:SetSize(LW, 10); fly:SetFrameStrata("DIALOG"); fly:Hide(); Skin.SkinWell(fly)
    self.postProfFlyout = fly; self.postProfFlyRows = {}

    -- Fermer flyout sur clic ailleurs
    local closer = CreateFrame("Button", nil, UIParent)
    closer:SetAllPoints(); closer:SetFrameStrata("DIALOG"); closer:Hide()
    fly:SetFrameLevel(closer:GetFrameLevel() + 1)
    closer:SetScript("OnClick", function() fly:Hide(); closer:Hide() end)
    fly:SetScript("OnShow",     function() closer:Show() end)
    fly:SetScript("OnHide",     function() closer:Hide() end)

    -- Filtre qualité (pill) + recherche
    self.postQualityIdx = 1
    local qBtn = Skin.MakeGoldButton(panel, 104, 18, "")
    qBtn:SetPoint("TOPLEFT", 12, -128); self.postQualityBtn = qBtn
    qBtn:SetScript("OnClick", function()
        UI.postQualityIdx = (UI.postQualityIdx % #QUALITY_STEPS) + 1
        UI:_RefreshQualityBtn(); UI:RefreshPostPlans()
    end)
    self:_RefreshQualityBtn()

    local srch = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    srch:SetSize(LW - 110, 16); srch:SetPoint("TOPLEFT", 116, -129); srch:SetAutoFocus(false)
    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("LEFT", srch, "LEFT", 4, 0); hint:SetText("○ " .. L["Rechercher un plan"])
    srch:SetScript("OnTextChanged", function(b)
        hint:SetShown(b:GetText() == "")
        UI.postSearch = b:GetText():lower(); UI:RefreshPostPlans()
    end)
    srch:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)

    sep1px(panel, 12, SEP - 2, -150)

    local lhdr = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    lhdr:SetPoint("TOPLEFT", 14, -156); lhdr:SetText(L["LISTE DES PLANS"])
    lhdr:SetTextColor(Skin.unpack(Skin.color.textMuted))

    local pscroll = CreateFrame("ScrollFrame", "COCPostPlanScroll", panel, "UIPanelScrollFrameTemplate")
    pscroll:SetPoint("TOPLEFT", 12, -170); pscroll:SetPoint("BOTTOMLEFT", 12, 22); pscroll:SetWidth(LSW)
    local pc = CreateFrame("Frame", nil, pscroll); pc:SetSize(LW - 22, 10); pscroll:SetScrollChild(pc)
    self.postPlanContent = pc; self.postPlanRows = {}
end

function UI:_ToggleProfFlyout()
    local fly = self.postProfFlyout; if not fly then return end
    if fly:IsShown() then fly:Hide(); return end
    fly:ClearAllPoints(); fly:SetPoint("TOPLEFT", self.postProfBtn, "BOTTOMLEFT", 0, -2); fly:Show()
end

function UI:_RefreshQualityBtn()
    if not self.postQualityBtn then return end
    local q = QUALITY_STEPS[self.postQualityIdx or 1]
    local name = q and ((_G["ITEM_QUALITY" .. q .. "_DESC"] or "?") .. "+") or L["Toutes"]
    self.postQualityBtn:SetText(L["Qualité : "] .. name)
end

-- =========================================================================
-- Panneau droit : titre plan + réactifs + commission + ciblage artisan
-- =========================================================================
function UI:_BuildPostRight(panel)
    -- Titre du plan
    self.postPlanBadge = Skin.MakeBadge(panel, 20); self.postPlanBadge:SetPoint("TOPLEFT", RX, -83)
    self.postPlanName  = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.postPlanName:SetPoint("LEFT", self.postPlanBadge, "RIGHT", 6, 0)
    self.postPlanName:SetWidth(RW - 100); self.postPlanName:SetJustifyH("LEFT"); Skin.ApplyShadow(self.postPlanName)
    local jeLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    jeLabel:SetPoint("TOPRIGHT", -22, -85); jeLabel:SetText(L["JE FOURNIS"])
    jeLabel:SetTextColor(Skin.unpack(Skin.color.gold)); Skin.ApplyShadow(jeLabel)

    sep1px(panel, RX, REDGE, -106)

    local rhdr = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rhdr:SetPoint("TOPLEFT", RX, -112)
    rhdr:SetText("|cFFE8B84B" .. L["Réactifs"] .. "|r |cFF888888" .. L["(cocher = je fournis)"] .. "|r"); Skin.ApplyShadow(rhdr)
    self.postReagHdr = rhdr

    -- Compteur « je fournis » à droite de l'en-tête réactifs.
    self.postBQCount = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.postBQCount:SetPoint("TOPRIGHT", -22, -112); self.postBQCount:SetTextColor(Skin.unpack(Skin.color.textMuted))
    Skin.ApplyShadow(self.postBQCount)

    local rscroll = CreateFrame("ScrollFrame", "COCPostReagScroll", panel, "UIPanelScrollFrameTemplate")
    rscroll:SetPoint("TOPLEFT", RX, -127); rscroll:SetSize(RW, 8 * RRH)
    local rc = CreateFrame("Frame", nil, rscroll); rc:SetSize(RW - 22, 10); rscroll:SetScrollChild(rc)
    self.postReagContent = rc; self.postReagRows = {}

    sep1px(panel, RX, REDGE, -300)

    -- Commission g/s/c + Qté
    local comLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    comLbl:SetPoint("TOPLEFT", RX, -308); comLbl:SetText("|cFFE8B84B" .. L["Commission"] .. "|r"); Skin.ApplyShadow(comLbl)
    self.postGold, self.postSilver, self.postCopper = self:_MakeGSC(panel, RX + 92, -306)
    local qLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    qLbl:SetPoint("TOPLEFT", RX + 330, -308); qLbl:SetText(L["Qté"]); Skin.ApplyShadow(qLbl)
    self.postQty = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    self.postQty:SetSize(40, 16); self.postQty:SetPoint("TOPLEFT", RX + 352, -306)
    self.postQty:SetAutoFocus(false); self.postQty:SetNumeric(true); self.postQty:SetText("1")
    self.postQty:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)

    sep1px(panel, RX, REDGE, -328)

    self:_BuildPostArtisanSection(panel)
end

function UI:_MakeGSC(parent, x, y)
    local cfg = { {40, "gold"}, {34, "silver"}, {34, "copper"} }
    local fields, cx = {}, x
    for i, c in ipairs(cfg) do
        local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
        eb:SetSize(c[1], 16); eb:SetPoint("TOPLEFT", cx, y)
        eb:SetAutoFocus(false); eb:SetNumeric(true); eb:SetText("0")
        eb:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)
        Skin.MoneyIcon(parent, c[2], eb)               -- vraie icône or/argent/cuivre du jeu
        fields[i] = eb; cx = cx + c[1] + 20
    end
    return fields[1], fields[2], fields[3]
end

function UI:_BuildPostArtisanSection(panel)
    local srcDefs = { {id="guild", label=L["Guilde"]}, {id="friend", label=L["Amis"]}, {id="added", label=L["Ajoutés"]}, {id="recent", label=L["Croisés"]} }
    self.postSrcBtns = {}
    for i, d in ipairs(srcDefs) do
        local b = Skin.MakeGoldButton(panel, 58, 20, d.label); b:SetPoint("TOPLEFT", RX + (i-1)*62, -337)
        b:SetScript("OnClick", function()
            UI.postSource = d.id; UI.postTarget = d.id   -- cibler TOUTE cette liste
            UI:_RefreshPostSrcTabs(); UI:RefreshPostArtisans()
        end)
        self.postSrcBtns[d.id] = b
    end
    self.postSource = "guild"; self.postTarget = "all"; self:_RefreshPostSrcTabs()

    local diffBtn = Skin.MakeGoldButton(panel, 124, 20, L["Diffuser à tous"]); diffBtn:SetPoint("TOPRIGHT", -22, -337)
    local diffIc = diffBtn:CreateTexture(nil, "OVERLAY"); diffIc:SetSize(14, 14)
    diffIc:SetPoint("LEFT", 5, 0); diffIc:SetTexture(Skin.tex.broadcast)
    diffBtn.text:ClearAllPoints(); diffBtn.text:SetPoint("LEFT", 22, 0)
    diffBtn:SetScript("OnClick", function()
        UI.postTarget = "all"; UI:RefreshPostArtisans()
    end)

    local ascroll = CreateFrame("ScrollFrame", "COCPostArtScroll", panel, "UIPanelScrollFrameTemplate")
    ascroll:SetPoint("TOPLEFT", RX, -362); ascroll:SetSize(RW, 5 * ARH)
    local ac = CreateFrame("Frame", nil, ascroll); ac:SetSize(RW - 22, 10); ascroll:SetScrollChild(ac)
    self.postArtContent = ac; self.postArtRows = {}

    local artLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    artLbl:SetPoint("TOPLEFT", RX, -495); artLbl:SetText("|cFFE8B84B" .. L["Destinataire :"] .. "|r"); Skin.ApplyShadow(artLbl)
    self.postArtisanName = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.postArtisanName:SetPoint("LEFT", artLbl, "RIGHT", 6, 0); Skin.ApplyShadow(self.postArtisanName)
    self:_UpdateArtisanLabel()

    local posterBtn = Skin.MakeGoldButton(panel, 82, 24, "Poster"); posterBtn:SetPoint("BOTTOMRIGHT", -22, 36)
    posterBtn:SetScript("OnClick", function() UI:DoPostOrder() end)

    self.postSelLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.postSelLbl:SetPoint("BOTTOMLEFT", RX, 40); self.postSelLbl:SetWidth(RW - 100); self.postSelLbl:SetJustifyH("LEFT")
    self.postSelLbl:SetText("|cFF888888" .. L["Choisis un métier puis un plan."] .. "|r")
end

function UI:_RefreshPostSrcTabs()
    for id, b in pairs(self.postSrcBtns or {}) do b:SetSelected(id == self.postSource) end
end

-- =========================================================================
-- Refresh
-- =========================================================================
function UI:RefreshPost()
    self:_RefreshProfDropdown()
    self:RefreshPostPlans()
    self:RefreshPostPlanDetail()
    self:RefreshPostArtisans()
end

function UI:_RefreshProfDropdown()
    local c = CL(); local all = c and c:Professions() or {}
    local profs = {}
    for _, p in ipairs(all) do if not GATHER_ONLY[p] then profs[#profs + 1] = p end end
    if (not self.postProf or GATHER_ONLY[self.postProf]) and profs[1] then self.postProf = profs[1] end
    local p = self.postProf or "—"; local lbl = Skin.ProfLabel(p)
    self.postProfBtn:SetText(lbl)
    self.postProfBadge:Paint(Skin.color.gold[1], Skin.color.gold[2], Skin.color.gold[3], Skin.FirstChar(lbl), Skin.ProfIcon(p))
    -- Peuplement du flyout
    local fly, frows = self.postProfFlyout, self.postProfFlyRows
    local h = 0
    for i, prof in ipairs(profs) do
        local r = frows[i]
        if not r then
            r = Skin.MakeGoldButton(fly, LW - 4, 20, ""); r:SetPoint("TOPLEFT", 2, -2 - (i-1)*20)
            r.text:SetJustifyH("LEFT"); r.text:ClearAllPoints(); r.text:SetPoint("LEFT", 6, 0)
            frows[i] = r
        end
        r:SetText(Skin.ProfLabel(prof)); r:SetSelected(prof == self.postProf)
        r:SetScript("OnClick", function()
            UI.postProf = prof; UI.postEntry = nil; UI:_RefreshProfDropdown()
            UI:RefreshPostPlans(); UI:RefreshPostPlanDetail(); UI:RefreshPostArtisans()
            fly:Hide()
        end)
        r:Show(); h = h + 20
    end
    for i = #profs + 1, #frows do frows[i]:Hide() end
    fly:SetHeight(h + 4)
end

function UI:RefreshPostPlans()
    local c = CL(); if not (c and self.postPlanContent) then return end
    local list = self.postProf and c:ProfessionCatalogue(self.postProf) or {}
    local s = self.postSearch
    local qmin = QUALITY_STEPS[self.postQualityIdx or 1]   -- seuil qualité minimal (ou false = Toutes)
    local out = {}
    for _, e in ipairs(list) do
        -- Commande = objets CRAFTABLES uniquement (recette/sort) ; les récoltes pures (sans spellID)
        -- vivent dans l'onglet Récolte. On masque les objets liés (non échangeables) et ceux absents
        -- du client (autre extension).
        if e.spellID and Skin.ItemExists(e.itemID) and not (e.itemID and isSoulbound(e.itemID)) then
            local okq = true
            if qmin and e.itemID then local q = select(3, GetItemInfo(e.itemID)); okq = q ~= nil and q >= qmin end
            local nm = entryName(e)
            if okq and (not s or s == "" or nm:lower():find(s, 1, true)) then
                out[#out + 1] = {e = e, name = nm}
            end
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    self.postPlanList = out
    for i, item in ipairs(out) do
        local row = self:_PostPlanRow(i); local e = item.e
        local r, g, b = Skin.RarityColor(e.itemID)
        row.badge:Paint(r, g, b, Skin.FirstChar(item.name), Skin.Icon(e.itemID, e.spellID))
        local disp = item.name:match("^item:") and "|cFF777777" .. L["Chargement…"] .. "|r" or item.name
        row.name:SetText(disp); row.name:SetTextColor(r, g, b)
        row.name:SetTextColor(e == self.postEntry and 1 or r, e == self.postEntry and 0.85 or g, e == self.postEntry and 0.27 or b)
        row.entry = e; row:SetScript("OnClick", function() UI:SelectPostPlan(e) end); row:Show()
    end
    for i = #out + 1, #self.postPlanRows do self.postPlanRows[i]:Hide() end
    self.postPlanContent:SetHeight(math.max(#out * PLH, 10))
    Skin.AutoHideScroll("COCPostPlanScroll", self.postPlanContent)
end

function UI:_PostPlanRow(i)
    local r = self.postPlanRows[i]; if r then return r end
    r = CreateFrame("Button", nil, self.postPlanContent); r:SetSize(LW - 22, PLH); r:SetPoint("TOPLEFT", 0, -(i-1)*PLH)
    local hi = r:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints(); hi:SetColorTexture(Skin.unpack(Skin.color.rowHover))
    r.badge = Skin.MakeBadge(r, 14); r.badge:SetPoint("LEFT", 2, 0)
    r.name  = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.name:SetPoint("LEFT", 20, 0); r.name:SetJustifyH("LEFT"); r.name:SetWidth(LW - 46); Skin.ApplyShadow(r.name)
    self.postPlanRows[i] = r; return r
end

function UI:RefreshPostPlanDetail()
    local e = self.postEntry
    if not e then
        self.postPlanBadge:Hide(); self.postPlanName:SetText("|cFF888888" .. L["Aucun plan sélectionné."] .. "|r")
        self.postReagHdr:SetShown(false); self.postBQCount:SetText("")
        for i = 1, #self.postReagRows do self.postReagRows[i]:Hide() end
        self.postReagContent:SetHeight(10)
        if self.postSelLbl then self.postSelLbl:SetText("|cFF888888" .. L["Choisis un métier puis un plan."] .. "|r") end
        return
    end
    local nm = entryName(e); local r, g, b = Skin.RarityColor(e.itemID)
    self.postPlanBadge:Paint(r, g, b, Skin.FirstChar(nm), Skin.Icon(e.itemID, e.spellID)); self.postPlanBadge:Show()
    self.postPlanName:SetText(nm); self.postPlanName:SetTextColor(r, g, b)
    self:RefreshPostReagents()
end

function UI:RefreshPostReagents()
    local c = CL()
    local reag = (c and self.postEntry and self.postEntry.spellID)
        and c:RecipeReagents(self.postProf, self.postEntry.spellID) or {}
    self.postCurrentReag = reag
    for i = 1, #self.postReagRows do self.postReagRows[i]:Hide() end
    for i, rg in ipairs(reag) do
        local row = self:_PostReagRow(i); local iid, qty = rg[1], rg[2]
        local cr, cg, cb = Skin.RarityColor(iid)
        local nm2 = c and c:ItemName(iid) or ("item:"..iid)
        local disp = nm2:match("^item:") and "|cFF777777" .. L["Chargement…"] .. "|r" or nm2
        row.badge:Paint(cr, cg, cb, Skin.FirstChar(nm2), Skin.Icon(iid))
        row.name:SetText(disp); row.name:SetTextColor(cr, cg, cb)
        row.qty:SetText("|cFFFFCC00×"..qty.."|r")
        row.check:SetText(UI.postProvide[iid] and "|cFF33DD33✓|r" or "|cFF888888□|r")
        row:SetScript("OnClick", function()
            UI.postProvide[iid] = not UI.postProvide[iid]
            row.check:SetText(UI.postProvide[iid] and "|cFF33DD33✓|r" or "|cFF888888□|r")
            UI:_UpdateProvidedCount()
        end)
        row:Show()
    end
    self.postReagContent:SetHeight(math.max(#reag * RRH, 10))
    Skin.AutoHideScroll("COCPostReagScroll", self.postReagContent)
    self.postReagHdr:SetShown(self.postEntry ~= nil)
    self:_UpdateProvidedCount()
end

function UI:_PostReagRow(i)
    local r = self.postReagRows[i]; if r then return r end
    r = CreateFrame("Button", nil, self.postReagContent); r:SetSize(RW - 22, RRH); r:SetPoint("TOPLEFT", 0, -(i-1)*RRH)
    local hi = r:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints(); hi:SetColorTexture(Skin.unpack(Skin.color.rowHover))
    r.badge = Skin.MakeBadge(r, 14); r.badge:SetPoint("LEFT", 2, 0)
    r.name  = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.name:SetPoint("LEFT", 20, 0); r.name:SetWidth(RW - 110); r.name:SetJustifyH("LEFT"); Skin.ApplyShadow(r.name)
    r.qty   = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); r.qty:SetPoint("RIGHT", -22, 0); Skin.ApplyShadow(r.qty)
    r.check = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); r.check:SetPoint("RIGHT", -4, 0); Skin.ApplyShadow(r.check)
    self.postReagRows[i] = r; return r
end

function UI:_UpdateProvidedCount()
    local reag = self.postCurrentReag or {}; local n = 0
    for _, rg in ipairs(reag) do if UI.postProvide[rg[1]] then n = n + 1 end end
    if self.postBQCount then self.postBQCount:SetText(n.." / "..#reag.." "..L["fournis"]) end
end

function UI:RefreshPostArtisans()
    local D = COC.Directory; if not (D and self.postArtContent) then return end
    local src, prof = self.postSource or "guild", self.postProf
    local list = {}
    for name, r in pairs(D.roster or {}) do
        local artSrc = r.source or "recent"
        if artSrc == src and (not prof or (r.recipes and r.recipes[prof])) then
            list[#list+1] = {name=name, r=r, online=D.online[name]}
        end
    end
    table.sort(list, function(a, b)
        if (a.online and true) ~= (b.online and true) then return a.online end
        return a.name < b.name
    end)
    local n = 0
    for _, a in ipairs(list) do
        n = n + 1; local row = self:_PostArtRow(n)
        local sk = a.r.skill and prof and a.r.skill[prof]
        local skTxt = sk and ("|cFF888888"..sk[1].."/"..sk[2].."|r  ") or ""
        local profs2 = {}
        for p2 in pairs(a.r.recipes or {}) do profs2[#profs2+1] = Skin.ProfLabel(p2) end
        row.dot:SetOnline(a.online and true or false)
        row.name:SetText("|cFFFFFFFF"..a.name.."|r  "..skTxt.."|cFF888888"..table.concat(profs2, " · ").."|r")
        row.src:SetText("|cFF888888"..(a.r.source or "recent"):upper().."|r")
        row.artEntry = a
        row.selTex:SetShown(UI.postTarget == "@" .. a.name)
        row:SetScript("OnClick", function()
            UI.postTarget = "@" .. a.name; UI:RefreshPostArtisans()
        end)
        row:Show()
    end
    for i = n+1, #self.postArtRows do self.postArtRows[i]:Hide() end
    self.postArtContent:SetHeight(math.max(n * ARH, 10))
    Skin.AutoHideScroll("COCPostArtScroll", self.postArtContent)
    self:_UpdateArtisanLabel()
end

function UI:_PostArtRow(i)
    local r = self.postArtRows[i]; if r then return r end
    r = CreateFrame("Button", nil, self.postArtContent); r:SetSize(RW - 22, ARH); r:SetPoint("TOPLEFT", 0, -(i-1)*ARH)
    local hi = r:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints(); hi:SetColorTexture(Skin.unpack(Skin.color.rowHover))
    local st = r:CreateTexture(nil, "BACKGROUND"); st:SetAllPoints()
    st:SetColorTexture(Skin.color.tabActive[1], Skin.color.tabActive[2], Skin.color.tabActive[3], 0.30)
    st:Hide(); r.selTex = st
    r.dot  = Skin.MakeStatusIcon(r, 14); r.dot:SetPoint("LEFT", 4, 0)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.name:SetPoint("LEFT", 18, 0); r.name:SetWidth(RW - 100); r.name:SetJustifyH("LEFT"); Skin.ApplyShadow(r.name)
    r.src  = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); r.src:SetPoint("RIGHT", -4, 0); Skin.ApplyShadow(r.src)
    self.postArtRows[i] = r; return r
end

-- Valeur CANONIQUE du destinataire (FR, identique sur le réseau ; cf. Orders:VisibleTo). Seuls
-- « Guilde » / « Amis » / @Nom sont routables ; « Ajoutés »/« Croisés » (listes perso, non évaluables
-- par un récepteur) retombent sur « Tous » (diffusion globale).
function UI:_PostTargetLabel()
    local t = self.postTarget or "all"
    if t == "all"        then return "Tous" end
    if t:sub(1, 1) == "@" then return t:sub(2) end
    if t == "guild"      then return "Guilde" end
    if t == "friend"     then return "Amis" end
    return "Tous"
end

function UI:_UpdateArtisanLabel()
    if self.postArtisanName then
        local t = self.postTarget or "all"
        local col = (t == "all") and "FFAAAAAA" or "FFFFFFFF"
        -- Affichage localisé ; la VALEUR canonique (FR) sert au réseau (cf. _PostTargetLabel / DoPostOrder).
        self.postArtisanName:SetText("|c" .. col .. L[self:_PostTargetLabel()] .. "|r")
    end
end

function UI:SelectPostPlan(entry)
    self.postEntry = entry; self.postProvide = {}
    self.postSelLbl:SetText(L["Sélection : "].."|cFFFFFFFF"..entryName(entry).."|r")
    self:RefreshPostPlans(); self:RefreshPostPlanDetail(); self:RefreshPostArtisans()
end

-- =========================================================================
-- Poster
-- =========================================================================
function UI:DoPostOrder()
    local e = self.postEntry
    if not e then self.postSelLbl:SetText("|cFFFF4444" .. L["Choisis d'abord un plan."] .. "|r"); return end
    local qty = tonumber(self.postQty:GetText()) or 1
    local g   = tonumber(self.postGold:GetText()) or 0
    local s   = tonumber(self.postSilver:GetText()) or 0
    local cu  = tonumber(self.postCopper:GetText()) or 0
    local price = nil
    if g > 0 or s > 0 or cu > 0 then
        local parts = {}
        if g  > 0 then parts[#parts+1] = g.."po"  end
        if s  > 0 then parts[#parts+1] = s.."pa"  end
        if cu > 0 then parts[#parts+1] = cu.."pc" end
        price = table.concat(parts, " ")
    end
    local provided = {}
    for iid, v in pairs(self.postProvide) do if v then provided[#provided+1] = iid end end
    COC.Orders:PostEntry(e, qty, price, {
        profession = self.postProf, provided = provided,
        recipient  = self:_PostTargetLabel(),
    })
    self.postGold:SetText("0"); self.postSilver:SetText("0"); self.postCopper:SetText("0")
    self.postQty:SetText("1"); self.postEntry = nil; self.postProvide = {}
    self.postSelLbl:SetText("|cFF33DD33" .. L["Commande postée !"] .. "|r")
    self:ShowTab("orders")
end
