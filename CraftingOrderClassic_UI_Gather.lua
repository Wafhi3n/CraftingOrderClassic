-- CraftingOrderClassic_UI_Gather.lua — onglet « Récolte » : ressources de récolte (minéraux,
-- herbes, cuirs, poissons) + demande de quantité + prix par pile + ciblage récolteur.
-- Structure calquée sur _UI_Post.lua (même layout gauche/droite). Chargé après _UI_Post.lua.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin

local GLH = 20    -- hauteur ligne ressource
local ARH = 26    -- hauteur ligne artisan

local SEP   = 308
local LW    = SEP - 14
local LSW   = LW - 22
local RX    = SEP + 8
local REDGE = 846
local RW    = 818 - RX

-- Professions de récolte reconnues (clés internes CraftLink). On affiche UNIQUEMENT celles
-- qui existent dans le catalogue CraftLink côté client.
local GATHER_PROFS = { "Mining", "Herbalism", "Skinning", "Fishing" }

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end
local function sep1px(parent, x1, x2, y)
    local s = parent:CreateTexture(nil, "ARTWORK"); s:SetHeight(1)
    s:SetColorTexture(Skin.color.separator[1], Skin.color.separator[2], Skin.color.separator[3], 0.5)
    s:SetSize(x2 - x1, 1); s:SetPoint("TOPLEFT", x1, y); return s
end

-- =========================================================================
-- Construction
-- =========================================================================
function UI:BuildGatherTab(f)
    local panel = CreateFrame("Frame", nil, f); self.insetPanel(panel, f); panel:Hide()
    self.gatherPanel     = panel
    self.gatherTarget    = "all"
    self.gatherSrc       = "guild"

    sep1px(panel, SEP, SEP + 1, -82):SetSize(1, 494)

    self:_BuildGatherLeft(panel)
    self:_BuildGatherRight(panel)
end

-- =========================================================================
-- Panneau gauche : dropdown métier de récolte + liste des ressources
-- =========================================================================
function UI:_BuildGatherLeft(panel)
    local hdr = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hdr:SetPoint("TOPLEFT", 14, -80); hdr:SetText("MÉTIER DE RÉCOLTE")
    hdr:SetTextColor(Skin.unpack(Skin.color.textMuted))

    local gBtn = Skin.MakeGoldButton(panel, LW, 22, "—"); gBtn:SetPoint("TOPLEFT", 12, -98)
    self.gatherProfBadge = Skin.MakeBadge(gBtn, 16); self.gatherProfBadge:SetPoint("LEFT", 5, 0)
    gBtn.text:SetJustifyH("LEFT"); gBtn.text:ClearAllPoints(); gBtn.text:SetPoint("LEFT", 26, 0)
    local arrow = gBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    arrow:SetPoint("RIGHT", -6, 0); arrow:SetText("▾"); arrow:SetTextColor(Skin.unpack(Skin.color.gold))
    self.gatherProfBtn = gBtn
    gBtn:SetScript("OnClick", function() UI:_ToggleGatherFlyout() end)

    local fly = CreateFrame("Frame", "COCGatherFlyout", UIParent, "BackdropTemplate")
    fly:SetSize(LW, 10); fly:SetFrameStrata("DIALOG"); fly:Hide(); Skin.SkinWell(fly)
    self.gatherProfFlyout = fly; self.gatherProfFlyRows = {}
    local closer = CreateFrame("Button", nil, UIParent)
    closer:SetAllPoints(); closer:SetFrameStrata("DIALOG"); closer:Hide()
    fly:SetFrameLevel(closer:GetFrameLevel() + 1)
    closer:SetScript("OnClick", function() fly:Hide(); closer:Hide() end)
    fly:SetScript("OnShow", function() closer:Show() end)
    fly:SetScript("OnHide", function() closer:Hide() end)

    local srch = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    srch:SetSize(LW, 16); srch:SetPoint("TOPLEFT", 12, -129); srch:SetAutoFocus(false)
    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("LEFT", srch, "LEFT", 4, 0); hint:SetText("○ Rechercher une ressource")
    srch:SetScript("OnTextChanged", function(b)
        hint:SetShown(b:GetText() == "")
        UI.gatherSearch = b:GetText():lower(); UI:RefreshGatherList()
    end)
    srch:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)

    -- Sélecteur d'extension (affiché seulement pour le pseudo-métier « Élémentaire »).
    self.gatherExp = 0   -- 0 = Toutes, 1 = Classic, 2 = TBC, 3 = WotLK
    self.gatherVerPills = {}
    local verDefs = { {0,"Toutes"}, {1,"Classic"}, {2,"TBC"}, {3,"WotLK"} }
    local vx = 12
    for _, d in ipairs(verDefs) do
        local b = Skin.MakeGoldButton(panel, 10, 16, d[2])
        b:SetWidth(b.text:GetStringWidth() + 14)
        b:SetPoint("TOPLEFT", vx, -150)
        b:SetScript("OnClick", function() UI.gatherExp = d[1]; UI:_RefreshGatherVerPills(); UI:RefreshGatherList() end)
        self.gatherVerPills[#self.gatherVerPills + 1] = { btn = b, exp = d[1] }
        vx = vx + b:GetWidth() + 4
    end

    sep1px(panel, 12, SEP - 2, -172)

    local lhdr = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    lhdr:SetPoint("TOPLEFT", 14, -178); lhdr:SetText("LISTE DES RESSOURCES")
    lhdr:SetTextColor(Skin.unpack(Skin.color.textMuted))

    local gscroll = CreateFrame("ScrollFrame", "COCGatherListScroll", panel, "UIPanelScrollFrameTemplate")
    gscroll:SetPoint("TOPLEFT", 12, -192); gscroll:SetPoint("BOTTOMLEFT", 12, 22); gscroll:SetWidth(LSW)
    local gc = CreateFrame("Frame", nil, gscroll); gc:SetSize(LW - 22, 10); gscroll:SetScrollChild(gc)
    self.gatherListContent = gc; self.gatherListRows = {}
end

function UI:_ToggleGatherFlyout()
    local fly = self.gatherProfFlyout; if not fly then return end
    if fly:IsShown() then fly:Hide(); return end
    fly:ClearAllPoints(); fly:SetPoint("TOPLEFT", self.gatherProfBtn, "BOTTOMLEFT", 0, -2); fly:Show()
end

-- =========================================================================
-- Panneau droit : détail ressource + quantité + prix + récolteur
-- =========================================================================
function UI:_BuildGatherRight(panel)
    self.gatherResBadge = Skin.MakeBadge(panel, 20); self.gatherResBadge:SetPoint("TOPLEFT", RX, -83)
    self.gatherResName  = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.gatherResName:SetPoint("LEFT", self.gatherResBadge, "RIGHT", 6, 0)
    self.gatherResName:SetWidth(RW - 40); self.gatherResName:SetJustifyH("LEFT"); Skin.ApplyShadow(self.gatherResName)
    self.gatherResInfo = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.gatherResInfo:SetPoint("TOPLEFT", RX + 28, -105); Skin.ApplyShadow(self.gatherResInfo)

    sep1px(panel, RX, REDGE, -120)

    -- Demande quantité
    local qhdr = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    qhdr:SetPoint("TOPLEFT", RX, -128); qhdr:SetText("|cFFE8B84BDemande de récolte — quantité voulue|r"); Skin.ApplyShadow(qhdr)

    -- Case « stacks » : si cochée, la quantité est un nombre de PILES, pas d'unités.
    self.gatherByStack = false
    local stLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    stLbl:SetPoint("TOPRIGHT", -22, -128); stLbl:SetText("stacks"); Skin.ApplyShadow(stLbl)
    local stChk = Skin.MakeGoldButton(panel, 20, 20, "□"); stChk:SetPoint("RIGHT", stLbl, "LEFT", -4, 0)
    -- Icône caisse affichée SUR la case quand « stacks » est coché (sinon □).
    local crateTex = stChk:CreateTexture(nil, "ARTWORK")
    crateTex:SetPoint("CENTER"); crateTex:SetSize(16, 16)
    crateTex:SetTexture(Skin.tex.crate); crateTex:SetTexCoord(0.08, 0.92, 0.08, 0.92); crateTex:Hide()
    stChk.crate = crateTex
    -- Coché = caisse (commande par pile) ; décoché = icône de l'objet voulu (commande à l'unité).
    stChk.Update = function()
        local tex = UI.gatherByStack and Skin.tex.crate
                 or (UI.gatherEntry and Skin.Icon(UI.gatherEntry.itemID))
        if tex then crateTex:SetTexture(tex); crateTex:Show(); stChk:SetText("")
        else crateTex:Hide(); stChk:SetText("□") end
    end
    stChk:SetScript("OnClick", function()
        UI.gatherByStack = not UI.gatherByStack
        stChk.Update(); UI:_RefreshGatherDetail()
    end)
    self.gatherStackChk = stChk; stChk.Update()
    self.gatherQty = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    self.gatherQty:SetSize(46, 16); self.gatherQty:SetPoint("RIGHT", stChk, "LEFT", -8, 0)
    self.gatherQty:SetAutoFocus(false); self.gatherQty:SetNumeric(true); self.gatherQty:SetText("1")
    self.gatherQty:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)

    self.gatherInfoTxt = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.gatherInfoTxt:SetPoint("TOPLEFT", RX, -148); self.gatherInfoTxt:SetWidth(RW); self.gatherInfoTxt:SetJustifyH("LEFT")
    self.gatherInfoTxt:SetTextColor(Skin.unpack(Skin.color.textMuted)); Skin.ApplyShadow(self.gatherInfoTxt)

    sep1px(panel, RX, REDGE, -280)

    -- Prix par pile
    local pLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pLbl:SetPoint("TOPLEFT", RX, -288); pLbl:SetText("|cFFE8B84BPrix proposé|r"); Skin.ApplyShadow(pLbl)
    self.gatherGold, self.gatherSilver, self.gatherCopper = self:_MakeGSCGather(panel, RX + 96, -286)

    sep1px(panel, RX, REDGE, -308)

    self:_BuildGatherArtisanSection(panel)
end

function UI:_MakeGSCGather(parent, x, y)
    local cfg = { {40, "gold"}, {34, "silver"}, {34, "copper"} }
    local fields, cx = {}, x
    for i, c in ipairs(cfg) do
        local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
        eb:SetSize(c[1], 16); eb:SetPoint("TOPLEFT", cx, y)
        eb:SetAutoFocus(false); eb:SetNumeric(true); eb:SetText("0")
        eb:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)
        Skin.MoneyIcon(parent, c[2], eb)
        fields[i] = eb; cx = cx + c[1] + 20
    end
    return fields[1], fields[2], fields[3]
end

function UI:_BuildGatherArtisanSection(panel)
    local srcDefs = { {id="guild",label="Guilde"}, {id="friend",label="Amis"}, {id="added",label="Ajoutés"}, {id="recent",label="Croisés"} }
    self.gatherSrcBtns = {}
    for i, d in ipairs(srcDefs) do
        local b = Skin.MakeGoldButton(panel, 58, 20, d.label); b:SetPoint("TOPLEFT", RX + (i-1)*62, -317)
        b:SetScript("OnClick", function()
            UI.gatherSrc = d.id; UI.gatherTarget = d.id   -- cibler TOUTE cette liste
            UI:_RefreshGatherSrcTabs(); UI:_RefreshGatherArtisans()
        end)
        self.gatherSrcBtns[d.id] = b
    end
    self.gatherSrc = "guild"; self.gatherTarget = "all"; self:_RefreshGatherSrcTabs()

    local diffBtn = Skin.MakeGoldButton(panel, 124, 20, "Diffuser à tous"); diffBtn:SetPoint("TOPRIGHT", -22, -317)
    local diffIc = diffBtn:CreateTexture(nil, "OVERLAY"); diffIc:SetSize(14, 14)
    diffIc:SetPoint("LEFT", 5, 0); diffIc:SetTexture(Skin.tex.broadcast)
    diffBtn.text:ClearAllPoints(); diffBtn.text:SetPoint("LEFT", 22, 0)
    diffBtn:SetScript("OnClick", function()
        UI.gatherTarget = "all"; UI:_RefreshGatherArtisans()
    end)

    local ascroll = CreateFrame("ScrollFrame", "COCGatherArtScroll", panel, "UIPanelScrollFrameTemplate")
    ascroll:SetPoint("TOPLEFT", RX, -342); ascroll:SetSize(RW, 5 * ARH)
    local ac = CreateFrame("Frame", nil, ascroll); ac:SetSize(RW - 22, 10); ascroll:SetScrollChild(ac)
    self.gatherArtContent = ac; self.gatherArtRows = {}

    local artLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    artLbl:SetPoint("TOPLEFT", RX, -475); artLbl:SetText("|cFFE8B84BRécolteur :|r"); Skin.ApplyShadow(artLbl)
    self.gatherArtisanName = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.gatherArtisanName:SetPoint("LEFT", artLbl, "RIGHT", 6, 0); Skin.ApplyShadow(self.gatherArtisanName)
    self:_UpdateGatherArtisanLabel()

    local posterBtn = Skin.MakeGoldButton(panel, 82, 24, "Poster"); posterBtn:SetPoint("BOTTOMRIGHT", -22, 36)
    posterBtn:SetScript("OnClick", function() UI:DoGatherOrder() end)

    self.gatherSelLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.gatherSelLbl:SetPoint("BOTTOMLEFT", RX, 40); self.gatherSelLbl:SetWidth(RW - 100); self.gatherSelLbl:SetJustifyH("LEFT")
    self.gatherSelLbl:SetText("|cFF888888Choisis un métier de récolte puis une ressource.|r")
end

function UI:_RefreshGatherSrcTabs()
    for id, b in pairs(self.gatherSrcBtns or {}) do b:SetSelected(id == self.gatherSrc) end
end

-- =========================================================================
-- Refresh
-- =========================================================================
function UI:RefreshGather()
    self:_RefreshGatherDropdown()
    self:RefreshGatherList()
    self:_RefreshGatherDetail()
    self:_RefreshGatherArtisans()
end

function UI:_RefreshGatherVerPills()
    local show = (self.gatherProf == "Elemental")
    -- Quelles extensions ont au moins un objet présent sur CE client ?
    local has = {}
    if show then
        for _, it in ipairs(COC.Elemental or {}) do
            if Skin.ItemExists(it.id) then has[it.exp] = true end
        end
    end
    -- Si l'extension choisie est vide ici, on retombe sur « Toutes ».
    if self.gatherExp ~= 0 and not has[self.gatherExp] then self.gatherExp = 0 end
    for _, p in ipairs(self.gatherVerPills or {}) do
        p.btn:SetShown(show)
        local enabled = (p.exp == 0) or has[p.exp]
        p.btn:SetSelected(p.exp == (self.gatherExp or 0))
        p.btn:SetAlpha(enabled and 1 or 0.35)
        p.btn:EnableMouse(enabled and true or false)
    end
end

function UI:_RefreshGatherDropdown()
    local c = CL()
    -- Métiers de récolte présents dans le catalogue + le pseudo-métier « Élémentaire » (données addon).
    local avail = {}
    for _, prof in ipairs(GATHER_PROFS) do
        if c and c.professions and c.professions[prof] then avail[#avail+1] = prof end
    end
    avail[#avail + 1] = "Elemental"
    if not self.gatherProf and avail[1] then self.gatherProf = avail[1] end
    self:_RefreshGatherVerPills()
    local lbl = Skin.ProfLabel(self.gatherProf or "—")
    self.gatherProfBtn:SetText(lbl)
    self.gatherProfBadge:Paint(Skin.color.gold[1], Skin.color.gold[2], Skin.color.gold[3], Skin.FirstChar(lbl), Skin.ProfIcon(self.gatherProf))
    local fly, frows = self.gatherProfFlyout, self.gatherProfFlyRows
    local h = 0
    for i, prof in ipairs(avail) do
        local r = frows[i]
        if not r then
            r = Skin.MakeGoldButton(fly, LW - 4, 20, ""); r:SetPoint("TOPLEFT", 2, -2 - (i-1)*20)
            r.text:SetJustifyH("LEFT"); r.text:ClearAllPoints(); r.text:SetPoint("LEFT", 6, 0)
            frows[i] = r
        end
        r:SetText(Skin.ProfLabel(prof)); r:SetSelected(prof == self.gatherProf)
        r:SetScript("OnClick", function()
            UI.gatherProf = prof; UI.gatherEntry = nil
            UI:_RefreshGatherDropdown(); UI:RefreshGatherList()
            UI:_RefreshGatherDetail(); UI:_RefreshGatherArtisans(); fly:Hide()
        end)
        r:Show(); h = h + 20
    end
    for i = #avail + 1, #frows do frows[i]:Hide() end
    fly:SetHeight(h + 4)
end

function UI:RefreshGatherList()
    local c = CL(); if not (c and self.gatherListContent) then return end
    local s = self.gatherSearch
    local out = {}
    if self.gatherProf == "Elemental" then
        -- Pseudo-métier élémentaire : données addon, filtrées par extension + existence client.
        for _, it in ipairs(COC.Elemental or {}) do
            if (self.gatherExp == 0 or it.exp == self.gatherExp) and Skin.ItemExists(it.id) then
                local nm = c:ItemName(it.id)
                if not s or s == "" or nm:lower():find(s, 1, true) then
                    out[#out + 1] = { e = { itemID = it.id }, name = nm }
                end
            end
        end
    else
        -- Récolte = gathers purs (sans spellID) présents dans le client courant (filtre cross-version).
        local list = self.gatherProf and c:ProfessionCatalogue(self.gatherProf) or {}
        for _, e in ipairs(list) do
            if e.itemID and not e.spellID and not e.service and Skin.ItemExists(e.itemID) then
                local nm = c:ItemName(e.itemID)
                if not s or s == "" or nm:lower():find(s, 1, true) then
                    out[#out + 1] = { e = e, name = nm }
                end
            end
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    self.gatherOutList = out
    for i, item in ipairs(out) do
        local row = self:_GatherListRow(i); local e = item.e
        local r, g, b = Skin.RarityColor(e.itemID)
        row.badge:Paint(r, g, b, Skin.FirstChar(item.name), Skin.Icon(e.itemID))
        local disp = item.name:match("^item:") and "|cFF777777Chargement…|r" or item.name
        row.name:SetText(disp); row.name:SetTextColor(r, g, b)
        if e == self.gatherEntry then row.name:SetTextColor(1, 0.85, 0.27) end
        row.stack:SetText("")
        row.entry = e; row:SetScript("OnClick", function() UI:SelectGatherItem(e) end); row:Show()
    end
    for i = #out + 1, #self.gatherListRows do self.gatherListRows[i]:Hide() end
    self.gatherListContent:SetHeight(math.max(#out * GLH, 10))
    Skin.AutoHideScroll("COCGatherListScroll", self.gatherListContent)
end

function UI:_GatherListRow(i)
    local r = self.gatherListRows[i]; if r then return r end
    r = CreateFrame("Button", nil, self.gatherListContent); r:SetSize(LW - 22, GLH); r:SetPoint("TOPLEFT", 0, -(i-1)*GLH)
    local hi = r:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints(); hi:SetColorTexture(Skin.unpack(Skin.color.rowHover))
    r.badge = Skin.MakeBadge(r, 14); r.badge:SetPoint("LEFT", 2, 0)
    r.name  = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.name:SetPoint("LEFT", 20, 0); r.name:SetJustifyH("LEFT"); r.name:SetWidth(LW - 80); Skin.ApplyShadow(r.name)
    r.stack = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.stack:SetPoint("RIGHT", -4, 0); Skin.ApplyShadow(r.stack)
    self.gatherListRows[i] = r; return r
end

function UI:SelectGatherItem(entry)
    self.gatherEntry = entry
    self:RefreshGatherList(); self:_RefreshGatherDetail(); self:_RefreshGatherArtisans()
end

function UI:_RefreshGatherDetail()
    local e = self.gatherEntry; local c = CL()
    if self.gatherStackChk then self.gatherStackChk.Update() end   -- icône case = objet / caisse
    if not e then
        self.gatherResBadge:Hide(); self.gatherResName:SetText("|cFF888888Aucune ressource sélectionnée.|r")
        self.gatherResInfo:SetText(""); self.gatherInfoTxt:SetText("")
        if self.gatherSelLbl then self.gatherSelLbl:SetText("|cFF888888Choisis un métier de récolte puis une ressource.|r") end
        return
    end
    local nm = c and c:ItemName(e.itemID) or ("item:"..e.itemID)
    local r, g, b = Skin.RarityColor(e.itemID)
    -- « stacks » coché → icône caisse ; sinon l'icône de l'objet à récolter.
    local icon = self.gatherByStack and Skin.tex.crate or Skin.Icon(e.itemID)
    self.gatherResBadge:Paint(r, g, b, Skin.FirstChar(nm), icon); self.gatherResBadge:Show()
    self.gatherResName:SetText(nm); self.gatherResName:SetTextColor(r, g, b)
    local profLbl = Skin.ProfLabel(self.gatherProf or "")
    self.gatherResInfo:SetText("|cFF888888" .. profLbl .. "|r")
    local unit = self.gatherByStack and "par stack" or "à l'unité"
    if self.gatherProf == "Elemental" then
        self.gatherInfoTxt:SetText("Objet |cFFE8B84Bélémentaire|r (farmé sur les mobs, pas de métier). Diffusé à tous. Quantité et prix |cFFE8B84B" .. unit .. ".|r")
    else
        self.gatherInfoTxt:SetText("Diffusée aux récolteurs ayant |cFFE8B84B" .. profLbl .. ".|r Quantité et prix proposé |cFFE8B84B" .. unit .. ".|r")
    end
    self.gatherSelLbl:SetText("Sélection : |cFFFFFFFF"..nm.."|r")
end

function UI:_RefreshGatherArtisans()
    local D = COC.Directory; if not (D and self.gatherArtContent) then return end
    local src = self.gatherSrc or "guild"
    -- Élémentaire = farmé par n'importe qui → pas de filtre par métier.
    local prof = (self.gatherProf == "Elemental") and nil or self.gatherProf
    local list = {}
    for name, rd in pairs(D.roster or {}) do
        local artSrc = rd.source or "guild"
        if artSrc == src and (not prof or (rd.recipes and rd.recipes[prof])) then
            list[#list+1] = {name=name, r=rd, online=D.online[name]}
        end
    end
    table.sort(list, function(a, b)
        if (a.online and true) ~= (b.online and true) then return a.online end
        return a.name < b.name
    end)
    local n = 0
    for _, a in ipairs(list) do
        n = n + 1; local row = self:_GatherArtRow(n)
        row.dot:SetOnline(a.online and true or false)
        local profs2 = {}
        for p2 in pairs(a.r.recipes or {}) do profs2[#profs2+1] = Skin.ProfLabel(p2) end
        row.name:SetText("|cFFFFFFFF"..a.name.."|r  |cFF888888"..table.concat(profs2, " · ").."|r")
        row.src:SetText("|cFF888888"..(a.r.source or ""):upper().."|r")
        row.artEntry = a; row.selTex:SetShown(UI.gatherTarget == "@" .. a.name)
        row:SetScript("OnClick", function()
            UI.gatherTarget = "@" .. a.name; UI:_RefreshGatherArtisans()
        end)
        row:Show()
    end
    for i = n+1, #self.gatherArtRows do self.gatherArtRows[i]:Hide() end
    self.gatherArtContent:SetHeight(math.max(n * ARH, 10))
    Skin.AutoHideScroll("COCGatherArtScroll", self.gatherArtContent)
    self:_UpdateGatherArtisanLabel()
end

function UI:_GatherArtRow(i)
    local r = self.gatherArtRows[i]; if r then return r end
    r = CreateFrame("Button", nil, self.gatherArtContent); r:SetSize(RW - 22, ARH); r:SetPoint("TOPLEFT", 0, -(i-1)*ARH)
    local hi = r:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints(); hi:SetColorTexture(Skin.unpack(Skin.color.rowHover))
    local st = r:CreateTexture(nil, "BACKGROUND"); st:SetAllPoints()
    st:SetColorTexture(Skin.color.tabActive[1], Skin.color.tabActive[2], Skin.color.tabActive[3], 0.30)
    st:Hide(); r.selTex = st
    r.dot  = Skin.MakeStatusIcon(r, 14); r.dot:SetPoint("LEFT", 4, 0)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.name:SetPoint("LEFT", 18, 0); r.name:SetWidth(RW - 100); r.name:SetJustifyH("LEFT"); Skin.ApplyShadow(r.name)
    r.src  = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); r.src:SetPoint("RIGHT", -4, 0); Skin.ApplyShadow(r.src)
    self.gatherArtRows[i] = r; return r
end

local GATHER_TARGET_FR = { guild = "Guilde", friend = "Amis", added = "Ajoutés", recent = "Croisés" }
function UI:_GatherTargetLabel()
    local t = self.gatherTarget or "all"
    if t == "all" then return "Tous" end
    if t:sub(1, 1) == "@" then return t:sub(2) end
    return GATHER_TARGET_FR[t] or "Tous"
end

function UI:_UpdateGatherArtisanLabel()
    if self.gatherArtisanName then
        local t = self.gatherTarget or "all"
        local col = (t == "all") and "FFAAAAAA" or "FFFFFFFF"
        self.gatherArtisanName:SetText("|c" .. col .. self:_GatherTargetLabel() .. "|r")
    end
end

-- =========================================================================
-- Poster une commande de récolte
-- =========================================================================
function UI:DoGatherOrder()
    local e = self.gatherEntry
    if not e then self.gatherSelLbl:SetText("|cFFFF4444Choisis d'abord une ressource.|r"); return end
    local qty  = tonumber(self.gatherQty:GetText()) or 1
    local g    = tonumber(self.gatherGold:GetText()) or 0
    local s    = tonumber(self.gatherSilver:GetText()) or 0
    local cu   = tonumber(self.gatherCopper:GetText()) or 0
    local price = nil
    if g > 0 or s > 0 or cu > 0 then
        local parts = {}
        if g  > 0 then parts[#parts+1] = g.."po"  end
        if s  > 0 then parts[#parts+1] = s.."pa"  end
        if cu > 0 then parts[#parts+1] = cu.."pc" end
        price = table.concat(parts, " ")
    end
    COC.Orders:PostEntry(e, qty, price, {
        profession = self.gatherProf, recipient = self:_GatherTargetLabel(), byStack = self.gatherByStack,
    })
    self.gatherGold:SetText("0"); self.gatherSilver:SetText("0"); self.gatherCopper:SetText("0")
    self.gatherQty:SetText("1"); self.gatherEntry = nil
    self.gatherByStack = false; if self.gatherStackChk then self.gatherStackChk.Update() end
    self.gatherSelLbl:SetText("|cFF33DD33Commande de récolte postée !|r")
    self:ShowTab("orders")
end
