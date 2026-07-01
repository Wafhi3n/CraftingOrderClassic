-- CraftingOrderClassic_UI_Artisans.lua — onglet « Artisans » : annuaire social.
-- Sidebar SOURCE (Guilde/Amis/Ajoutés + compteurs) + ajout manuel ; à droite, pills de filtre
-- métier + lignes artisan (présence, niveau, métiers, source, Chuchoter). Lit Directory (cache).

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local ARH    = 40              -- hauteur ligne artisan
local ASEP   = 212             -- x séparateur sidebar/liste
local ARX    = 220             -- x zone droite
local AREDGE = 846
local ARW    = AREDGE - ARX

local SRC_TAG = { guild = L["GUILDE"], friend = L["AMIS"], added = L["AJOUTÉ"], recent = L["CROISÉ"] }

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end
local function trim(s) return s and s:gsub("^%s+", ""):gsub("%s+$", "") or "" end

-- Connaît-on un métier de cet artisan ? UNION des niveaux SK (r.skill) ET des recettes RK (r.recipes) :
-- un artisan croisé sans avoir ouvert sa fenêtre métier n'a que des SK → il DOIT quand même s'afficher.
local function knowsProf(r, pf)
    return (r.skill and r.skill[pf]) or (r.recipes and r.recipes[pf]) or false
end

-- Métiers connus d'un artisan, en liste { key, sv } : niveau (SK) si connu, sinon recette seule (RK).
-- Union des deux sources, triée par libellé localisé — même ordre visuel que l'ancien texte concaténé.
local function profsList(r)
    local seen, parts = {}, {}
    for key, sv in pairs(r.skill or {}) do
        seen[key] = true
        parts[#parts + 1] = { key = key, sv = sv }
    end
    for key in pairs(r.recipes or {}) do
        if not seen[key] then seen[key] = true; parts[#parts + 1] = { key = key } end
    end
    table.sort(parts, function(a, b) return Skin.ProfLabel(a.key) < Skin.ProfLabel(b.key) end)
    return parts
end

-- =========================================================================
-- Construction
-- =========================================================================
function UI:BuildArtisansTab(f)
    local panel = CreateFrame("Frame", nil, f); self.insetPanel(panel, f); panel:Hide()
    self.artisansPanel = panel
    self.artSource     = "all"
    self.artProfFilter = nil
    self.artPillsBuilt = false

    local vs = panel:CreateTexture(nil, "ARTWORK")
    vs:SetColorTexture(Skin.color.separator[1], Skin.color.separator[2], Skin.color.separator[3], 0.5)
    vs:SetSize(1, 470); vs:SetPoint("TOPLEFT", ASEP, -78)

    -- Sidebar : SOURCE
    local srcHdr = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    srcHdr:SetPoint("TOPLEFT", 14, -80); srcHdr:SetText(L["SOURCE"])
    srcHdr:SetTextColor(Skin.unpack(Skin.color.textMuted))

    local srcDefs = { {id="all",label=L["Tous"]}, {id="guild",label=L["Guilde"]}, {id="friend",label=L["Amis"]}, {id="added",label=L["Ajoutés"]}, {id="recent",label=L["Croisés"]} }
    self.artSrcBtns = {}
    for i, d in ipairs(srcDefs) do
        local b = Skin.MakeGoldButton(panel, 190, 28, d.label)
        b:SetPoint("TOPLEFT", 12, -96 - (i - 1) * 32)
        b.text:ClearAllPoints(); b.text:SetPoint("LEFT", 10, 0); b.text:SetJustifyH("LEFT")
        local cnt = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cnt:SetPoint("RIGHT", -10, 0); Skin.ApplyShadow(cnt); b.count = cnt
        b:SetScript("OnClick", function() UI.artSource = d.id; UI:_RefreshArtSrcTabs(); UI:RefreshArtisans() end)
        self.artSrcBtns[d.id] = b
    end
    self:_RefreshArtSrcTabs()

    -- Sidebar : ajout manuel d'un joueur
    local addHdr = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    addHdr:SetPoint("BOTTOMLEFT", 14, 86); addHdr:SetText(L["AJOUTER UN JOUEUR"])
    addHdr:SetTextColor(Skin.unpack(Skin.color.textMuted))
    local addBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    addBox:SetSize(150, 20); addBox:SetPoint("BOTTOMLEFT", 16, 60); addBox:SetAutoFocus(false)
    addBox:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)
    addBox:SetScript("OnEnterPressed", function(b) UI:_AddArtisan(b:GetText()); b:SetText(""); b:ClearFocus() end)
    local ghost = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ghost:SetPoint("LEFT", addBox, "LEFT", 4, 0); ghost:SetText(L["Nom du personnage"])
    addBox:SetScript("OnTextChanged", function(b) ghost:SetShown(b:GetText() == "") end)
    local addBtn = Skin.MakeGoldButton(panel, 26, 20, "+")
    addBtn:SetPoint("LEFT", addBox, "RIGHT", 6, 0)
    addBtn:SetScript("OnClick", function() UI:_AddArtisan(addBox:GetText()); addBox:SetText("") end)

    -- Zone droite : libellé Métier + pills (construits paresseusement), puis liste
    self.artPillHdr = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.artPillHdr:SetPoint("TOPLEFT", ARX, -98); self.artPillHdr:SetText("|cFF888888" .. L["Métier :"] .. "|r"); Skin.ApplyShadow(self.artPillHdr)
    self.artPills = {}

    local ascroll = CreateFrame("ScrollFrame", "COCArtScroll", panel, "UIPanelScrollFrameTemplate")
    ascroll:SetPoint("TOPLEFT", ARX, -150); ascroll:SetPoint("BOTTOMRIGHT", -42, 22)
    -- Largeur < zone visible du scroll (sinon les lignes passent SOUS la scrollbar → boutons masqués).
    local ac = CreateFrame("Frame", nil, ascroll); ac:SetSize(ARW - 54, 10); ascroll:SetScrollChild(ac)
    self.artScroll = ascroll; self.artListContent = ac; self.artListRows = {}
end

function UI:_RefreshArtSrcTabs()
    for id, b in pairs(self.artSrcBtns or {}) do b:SetSelected(id == self.artSource) end
end

-- Pills de filtre métier (Tous + chaque métier), avec retour à la ligne.
function UI:_BuildArtPills(panel)
    local c = CL(); local profs = c and c:Professions() or {}
    local defs = { "Tous" }
    for _, p in ipairs(profs) do defs[#defs + 1] = p end
    local x, y, rowH = 50, 0, 24      -- x départ = 50 pour dégager « Métier : »
    local maxW = ARW - 4
    for _, key in ipairs(defs) do
        local label = (key == "Tous") and L["Tous"] or Skin.ProfLabel(key)   -- "Tous" = sentinelle (pas localisée)
        local b = Skin.MakeGoldButton(panel, 10, 18, label)
        local w = b.text:GetStringWidth() + 16
        b:SetWidth(w)
        if x + w > maxW then x = 0; y = y + rowH end
        b:SetPoint("TOPLEFT", ARX + x, -94 - y)
        b:SetScript("OnClick", function()
            -- NB : surtout pas l'idiome `cond and nil or key` (Lua : `true and nil or key` == key).
            if key == "Tous" then UI.artProfFilter = nil else UI.artProfFilter = key end
            UI:_RefreshArtPills(); UI:RefreshArtisans()
        end)
        self.artPills[#self.artPills + 1] = { btn = b, key = key }
        x = x + w + 4
    end
    -- Recale le haut de la liste sous la dernière rangée de pills.
    self.artScroll:ClearAllPoints()
    self.artScroll:SetPoint("TOPLEFT", ARX, -(94 + y + 28))
    self.artScroll:SetPoint("BOTTOMRIGHT", -42, 22)
    self:_RefreshArtPills()
end

function UI:_RefreshArtPills()
    for _, p in ipairs(self.artPills or {}) do
        local active = (p.key == "Tous" and self.artProfFilter == nil) or (p.key == self.artProfFilter)
        p.btn:SetSelected(active)
    end
end

-- Ajout manuel (sera lié au vrai profil quand le joueur sera vu en ligne — backend Étape D).
function UI:_AddArtisan(name)
    name = trim(name)
    if name == "" then return end
    name = name:sub(1, 1):upper() .. name:sub(2)
    local D = COC.Directory; if not D then return end
    D.roster = D.roster or {}
    local r = D.roster[name] or {}
    r.source = "added"; r.recipes = r.recipes or {}; r.manual = true; r.lastSeen = time()
    D.roster[name] = r
    if D.DiscoverPlayer then D:DiscoverPlayer(name) end   -- ping immédiat : métiers + en ligne s'il a l'addon
    UI.artSource = "added"; UI:_RefreshArtSrcTabs(); UI:RefreshArtisans()
    print("|cFF33DD88Crafting Order|r " .. L["artisan ajouté : "] .. "|cFFFFFFFF" .. name ..
        "|r |cFF888888" .. L["(lié quand il sera en ligne avec l'addon)"] .. "|r")
end

-- =========================================================================
-- Refresh
-- =========================================================================
function UI:RefreshArtisans()
    local panel = self.artisansPanel; if not panel then return end
    if not self.artPillsBuilt then self:_BuildArtPills(panel); self.artPillsBuilt = true end
    local D = COC.Directory

    -- Compteurs par source (+ « all » = total)
    local counts = { all = 0, guild = 0, friend = 0, added = 0, recent = 0 }
    for _, r in pairs(D and D.roster or {}) do
        local s = r.source or "recent"; counts[s] = (counts[s] or 0) + 1; counts.all = counts.all + 1
    end
    for id, b in pairs(self.artSrcBtns) do b.count:SetText("|cFFE8B84B" .. (counts[id] or 0) .. "|r") end

    -- Liste filtrée (source + métier). src == "all" → toutes sources confondues.
    local src, pf = self.artSource or "all", self.artProfFilter
    local list = {}
    for name, r in pairs(D and D.roster or {}) do
        if (src == "all" or (r.source or "recent") == src) and (not pf or knowsProf(r, pf)) then
            list[#list + 1] = { name = name, r = r, online = D.online[name] }
        end
    end
    table.sort(list, function(a, b)
        if (a.online and true) ~= (b.online and true) then return a.online end
        return a.name < b.name
    end)

    local n = 0
    for _, a in ipairs(list) do
        n = n + 1; local row = self:_ArtRow(n)
        row.dot:SetOnline(a.online and true or false)
        row.name:SetText("|cFFFFFFFF" .. a.name .. "|r")
        local lvl = a.r.level and (L["niv "] .. a.r.level) or L["niv ?"]
        row.sub:SetText("|cFF888888" .. (a.online and L["En ligne"] or L["Hors ligne"]) .. " · " .. lvl .. "|r")
        UI:_SetArtProfIcons(row, profsList(a.r))
        row.src:SetText("|cFF888888" .. (SRC_TAG[a.r.source or "recent"] or "") .. "|r")
        row.whisper:SetScript("OnClick", function()
            if ChatFrame_SendTell then ChatFrame_SendTell(a.name) end
        end)
        row.whisper:SetShown(a.online == true or a.r.source ~= "added")
        row:Show()
    end
    for i = n + 1, #self.artListRows do self.artListRows[i]:Hide() end
    self.artListContent:SetHeight(math.max(n * ARH, 10))
    Skin.AutoHideScroll("COCArtScroll", self.artListContent)
    if n == 0 and self.artListRows[1] then
        local row = self:_ArtRow(1)
        row.dot:SetOnline(nil); row.name:SetText("|cFF888888" .. L["Aucun artisan dans cette source."] .. "|r")
        row.sub:SetText(""); UI:_SetArtProfIcons(row, {}); row.src:SetText(""); row.whisper:Hide()
        row:Show()
    end
end

function UI:_ArtRow(i)
    local r = self.artListRows[i]; if r then return r end
    r = CreateFrame("Button", nil, self.artListContent); r:SetSize(ARW - 54, ARH); r:SetPoint("TOPLEFT", 0, -(i - 1) * ARH)
    local hi = r:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints(); hi:SetColorTexture(Skin.unpack(Skin.color.rowHover))
    r.dot   = Skin.MakeStatusIcon(r, 14); r.dot:SetPoint("LEFT", 6, 0)
    r.name  = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    r.name:SetPoint("TOPLEFT", 22, -5); r.name:SetWidth(150); r.name:SetJustifyH("LEFT"); Skin.ApplyShadow(r.name)
    r.sub   = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.sub:SetPoint("TOPLEFT", 22, -22); r.sub:SetWidth(150); r.sub:SetJustifyH("LEFT"); Skin.ApplyShadow(r.sub)
    r.profsFrame = CreateFrame("Frame", nil, r)
    r.profsFrame:SetPoint("LEFT", 180, 0); r.profsFrame:SetSize(ARW - 320, ARH)
    r.profIconPool = {}
    r.src   = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); r.src:SetPoint("RIGHT", -94, 0); Skin.ApplyShadow(r.src)
    r.whisper = Skin.MakeGoldButton(r, 78, 22, L["Chuchoter"]); r.whisper:SetPoint("RIGHT", -6, 0)
    self.artListRows[i] = r; return r
end

-- Icônes de métier (survol = tooltip nom + niveau) à la place du texte concaténé — moins encombrant.
local ARI = 22   -- pas horizontal entre icônes
function UI:_SetArtProfIcons(row, list)
    local pool = row.profIconPool
    for i, item in ipairs(list) do
        local ic = pool[i]
        if not ic then
            ic = CreateFrame("Frame", nil, row.profsFrame); ic:SetSize(18, 18)
            local tex = ic:CreateTexture(nil, "ARTWORK"); tex:SetAllPoints()
            tex:SetTexCoord(0.08, 0.92, 0.08, 0.92); ic.tex = tex
            ic:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(self.tipLabel or "", 1, 1, 1)
                if self.tipSub then GameTooltip:AddLine(self.tipSub, 0.910, 0.722, 0.294) end
                GameTooltip:Show()
            end)
            ic:SetScript("OnLeave", GameTooltip_Hide)
            pool[i] = ic
        end
        ic:ClearAllPoints(); ic:SetPoint("LEFT", (i - 1) * ARI, 0)
        ic.tex:SetTexture(Skin.ProfIcon(item.key) or Skin.tex.unknown)
        ic.tipLabel = Skin.ProfLabel(item.key)
        ic.tipSub = item.sv and ((item.sv[1] or "?") .. "/" .. (item.sv[2] or "?")) or nil
        ic:Show()
    end
    for i = #list + 1, #pool do pool[i]:Hide() end
end
