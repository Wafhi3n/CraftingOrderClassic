-- CraftingOrderClassic_UI_MyArtisans.lua — onglet « Mes artisans » : vue agrégée des métiers du
-- COMPTE (tous mes rerolls du royaume), en mode « connu ». 100 % LOCAL (lit ma SavedVariable via
-- Dir:AggregateMyProfs, aucun réseau, marche même avec /co alts off). Deux zones (patron Récolte) :
-- à gauche le sélecteur de métiers du compte, à droite les recettes connues du métier choisi + les
-- persos qui les portent. Chargé après UI_Artisans_Groups.lua (réutilise Skin/CraftLink).

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local PLH = 34    -- hauteur ligne métier (gauche)
local RLH = 18    -- hauteur ligne recette (droite)

local SEP   = 300
local LW    = SEP - 14
local RX    = SEP + 8
local RW    = 818 - RX

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end
local function sep1px(parent, x, y, w, h)
    local s = parent:CreateTexture(nil, "ARTWORK")
    s:SetColorTexture(Skin.color.separator[1], Skin.color.separator[2], Skin.color.separator[3], 0.5)
    s:SetSize(w, h); s:SetPoint("TOPLEFT", x, y); return s
end

-- =========================================================================
-- Construction
-- =========================================================================
function UI:BuildMyArtisansTab(f)
    local panel = CreateFrame("Frame", nil, f); self.insetPanel(panel, f); panel:Hide()
    self.myArtisansPanel = panel
    self.myArtSelProf = nil

    sep1px(panel, SEP, -82, 1, 494)

    local lhdr = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    lhdr:SetPoint("TOPLEFT", 14, -80); lhdr:SetText(L["MÉTIERS DU COMPTE"])
    lhdr:SetTextColor(Skin.unpack(Skin.color.textMuted))

    local lscroll = CreateFrame("ScrollFrame", "COCMyArtProfScroll", panel, "UIPanelScrollFrameTemplate")
    lscroll:SetPoint("TOPLEFT", 12, -98); lscroll:SetPoint("BOTTOMLEFT", 12, 22); lscroll:SetWidth(LW - 22)
    local lc = CreateFrame("Frame", nil, lscroll); lc:SetSize(LW - 24, 10); lscroll:SetScrollChild(lc)
    self.myArtProfContent = lc; self.myArtProfRows = {}

    local rhdr = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rhdr:SetPoint("TOPLEFT", RX, -80); Skin.ApplyShadow(rhdr); self.myArtDetailHdr = rhdr

    local rscroll = CreateFrame("ScrollFrame", "COCMyArtRecScroll", panel, "UIPanelScrollFrameTemplate")
    rscroll:SetPoint("TOPLEFT", RX, -102); rscroll:SetPoint("BOTTOMRIGHT", -30, 22)
    local rc = CreateFrame("Frame", nil, rscroll); rc:SetSize(RW - 24, 10); rscroll:SetScrollChild(rc)
    self.myArtRecContent = rc; self.myArtRecRows = {}
end

-- =========================================================================
-- Zone gauche : lignes de métier
-- =========================================================================
function UI:_MyArtProfRow(i)
    local r = self.myArtProfRows[i]; if r then return r end
    local lc = self.myArtProfContent
    r = CreateFrame("Button", nil, lc); r:SetSize(LW - 24, PLH); r:SetPoint("TOPLEFT", 0, -(i - 1) * PLH)
    local hi = r:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints(); hi:SetColorTexture(Skin.unpack(Skin.color.rowHover))
    local st = r:CreateTexture(nil, "BACKGROUND"); st:SetAllPoints()
    st:SetColorTexture(Skin.color.tabActive[1], Skin.color.tabActive[2], Skin.color.tabActive[3], 0.30)
    st:Hide(); r.selTex = st
    r.badge = Skin.MakeBadge(r, 22); r.badge:SetPoint("LEFT", 6, 0)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    r.name:SetPoint("TOPLEFT", 34, -5); r.name:SetWidth(LW - 70); r.name:SetJustifyH("LEFT"); Skin.ApplyShadow(r.name)
    r.sub = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.sub:SetPoint("TOPLEFT", 34, -19); r.sub:SetWidth(LW - 70); r.sub:SetJustifyH("LEFT"); Skin.ApplyShadow(r.sub)
    self.myArtProfRows[i] = r; return r
end

-- Nb de persos porteurs + libellé « porté par : A, B » (pour la sous-ligne / détail).
local function bearers(e)
    local names = {}
    for _, c in ipairs(e.chars) do names[#names + 1] = c.name end
    return table.concat(names, ", ")
end

function UI:_FillMyArtProfRow(row, e, selected)
    local pl = Skin.ProfLabel(e.profKey)
    row.badge:Paint(Skin.color.gold[1], Skin.color.gold[2], Skin.color.gold[3], Skin.FirstChar(pl), Skin.ProfIcon(e.profKey))
    local lvl = e.bestRank > 0 and (e.bestRank .. "/" .. e.bestMax) or L["niv ?"]
    row.name:SetText("|cFFFFFFFF" .. Skin.ProfLabel(e.profKey) .. "|r  |cFF888888" .. lvl .. "|r")
    local nrec = 0; for _ in pairs(e.known) do nrec = nrec + 1 end
    row.sub:SetText("|cFF888888" .. string.format(L["%d recettes"], nrec)
        .. "  ·  " .. bearers(e) .. "|r")
    row.selTex:SetShown(selected)
    row:SetScript("OnClick", function() UI.myArtSelProf = e.profKey; UI:RefreshMyArtisans() end)
    row:Show()
end

-- =========================================================================
-- Zone droite : recettes connues du métier sélectionné
-- =========================================================================
-- Rangée polyvalente (patron ProfWindow_Recipes) : header de section (doré, sans icône), ligne de
-- recette (icône + nom + niveau requis + porteurs), ou ligne de cooldown (icône horloge + label).
function UI:_MyArtRecRow(i)
    local r = self.myArtRecRows[i]; if r then return r end
    r = CreateFrame("Frame", nil, self.myArtRecContent); r:SetSize(RW - 24, RLH); r:SetPoint("TOPLEFT", 0, -(i - 1) * RLH)
    r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(14, 14); r.icon:SetPoint("LEFT", 2, 0)
    r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.name:SetJustifyH("LEFT"); Skin.ApplyShadow(r.name)
    r.who = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.who:SetPoint("RIGHT", -6, 0); r.who:SetJustifyH("RIGHT"); r.who:SetWidth(120); Skin.ApplyShadow(r.who)
    self.myArtRecRows[i] = r; return r
end

-- Ancre le libellé (nom) : après l'icône (x=20) ou collé au bord (header, x=4), largeur bornée pour
-- ne pas chevaucher la colonne « porté par ». SetPoint répété empile les ancres → ClearAllPoints.
local function anchorName(row, x)
    row.name:ClearAllPoints()
    row.name:SetPoint("LEFT", x, 0)
    row.name:SetWidth(RW - 24 - x - 126)
end

-- Persos du compte qui connaissent CE spellID (colonne « porté par »).
local function knowersOf(e, sid)
    local out = {}
    for _, c in ipairs(e.chars) do if c.known[sid] then out[#out + 1] = c.name end end
    return table.concat(out, ", ")
end

-- Bandeau cooldowns EN HAUT : une ligne par CD actif et par perso porteur (« Transmutation : dans
-- 14h — Qellorran »). Réutilise Social:CooldownLines sur une entrée SYNTHÉTIQUE {cooldowns=…} bâtie
-- depuis MA partition db.myCooldowns[Nom-Royaume], filtrée au métier sélectionné.
function UI:_MyArtCooldownItems(e)
    local So, db = COC.Social, COC.db
    if not (So and So.CooldownLines and db and db.myCooldowns) then return {} end
    local items = {}
    for _, c in ipairs(e.chars) do
        local part = c.key and db.myCooldowns[c.key]
        if part then
            for _, ln in ipairs(So:CooldownLines({ cooldowns = part }, nil, e.profKey) or {}) do
                items[#items + 1] = { cd = true, text = ln.text, ready = ln.ready, who = c.name }
            end
        end
    end
    return items
end

-- Construit la liste d'affichage : [bandeau CD] puis recettes GROUPÉES PAR SECTION (SectionOf du
-- produit, comme la vue métier). Chaque élément = { cd/header/recipe }.
function UI:_MyArtDisplayList(e)
    local c = CL()
    local list = self:_MyArtCooldownItems(e)
    local recs = {}
    for sid in pairs(e.known) do
        local itemID = c and c:RecipeProduct(e.profKey, sid)
        local label, rank = L["Autres"], 900
        if itemID and COC.SectionOf then label, rank = COC.SectionOf(itemID) end
        local nm = (c and c:RecipeName(sid)) or (c and itemID and c:ItemName(itemID)) or ("spell:" .. sid)
        recs[#recs + 1] = { sid = sid, name = nm, sec = label, secRank = rank or 900,
            at = c and c:RecipeLearnedAt(e.profKey, sid), itemID = itemID }
    end
    table.sort(recs, function(a, b)
        if a.secRank ~= b.secRank then return a.secRank < b.secRank end
        if a.sec ~= b.sec then return a.sec < b.sec end
        return a.name < b.name
    end)
    local curSec
    for _, rc in ipairs(recs) do
        if rc.sec ~= curSec then curSec = rc.sec; list[#list + 1] = { header = true, text = rc.sec } end
        list[#list + 1] = rc
    end
    return list
end

function UI:_FillMyArtRecipes(e)
    local list = self:_MyArtDisplayList(e)
    local n = 0
    for _, it in ipairs(list) do
        n = n + 1
        local row = self:_MyArtRecRow(n)
        if it.header then
            row.icon:Hide(); anchorName(row, 4)
            row.name:SetText("|cFFE8B84B" .. it.text .. "|r"); row.who:SetText("")
        elseif it.cd then
            row.icon:Show(); row.icon:SetTexture("Interface\\Icons\\Spell_Holy_BorrowedTime"); anchorName(row, 20)
            row.name:SetText((it.ready and "|cFF4CDB6E" or "|cFFFFA633") .. it.text .. "|r")
            row.who:SetText("|cFF888888" .. (it.who or "") .. "|r")
        else
            -- Icône de l'OBJET PRODUIT d'abord (GetItemIcon, fiable), repli sort — GetSpellTexture sur
            -- un spellID de recette rend souvent le placeholder « tête » en Classic Era.
            row.icon:Show(); row.icon:SetTexture(Skin.Icon(it.itemID, it.sid) or Skin.tex.unknown); anchorName(row, 20)
            row.name:SetText("|cFFFFFFFF" .. it.name .. "|r" .. (it.at and (" |cFF888888(" .. it.at .. ")|r") or ""))
            row.who:SetText("|cFF888888" .. knowersOf(e, it.sid) .. "|r")
        end
        row:Show()
    end
    for i = n + 1, #self.myArtRecRows do self.myArtRecRows[i]:Hide() end
    self.myArtRecContent:SetHeight(math.max(n * RLH, 10))
    Skin.AutoHideScroll("COCMyArtRecScroll", self.myArtRecContent)
    return n
end

-- =========================================================================
-- Refresh
-- =========================================================================
function UI:RefreshMyArtisans()
    local panel = self.myArtisansPanel; if not panel then return end
    local D = COC.Directory
    local list = (D and D.AggregateMyProfs and D:AggregateMyProfs()) or {}
    -- Tri par libellé LOCALISÉ à rang égal (le cœur trie déjà par bestRank desc puis clé EN).
    table.sort(list, function(a, b)
        if a.bestRank ~= b.bestRank then return a.bestRank > b.bestRank end
        return Skin.ProfLabel(a.profKey) < Skin.ProfLabel(b.profKey)
    end)

    -- Sélection par défaut = 1er métier ; conserve la sélection si elle existe encore.
    local sel = self.myArtSelProf
    local selE
    for _, e in ipairs(list) do if e.profKey == sel then selE = e end end
    if not selE and list[1] then selE = list[1]; self.myArtSelProf = selE.profKey end

    local n = 0
    for _, e in ipairs(list) do
        n = n + 1; self:_FillMyArtProfRow(self:_MyArtProfRow(n), e, e == selE)
    end
    for i = n + 1, #self.myArtProfRows do self.myArtProfRows[i]:Hide() end
    self.myArtProfContent:SetHeight(math.max(n * PLH, 10))
    Skin.AutoHideScroll("COCMyArtProfScroll", self.myArtProfContent)

    if n == 0 then
        self.myArtDetailHdr:SetText("|cFF888888" .. L["Aucun métier. Ouvre ta fenêtre métier sur chaque perso une fois."] .. "|r")
        for i = 1, #self.myArtRecRows do self.myArtRecRows[i]:Hide() end
        return
    end

    local lvl = selE.bestRank > 0 and (" |cFF888888" .. selE.bestRank .. "/" .. selE.bestMax .. "|r") or ""
    self.myArtDetailHdr:SetText("|cFFE8B84B" .. Skin.ProfLabel(selE.profKey) .. "|r" .. lvl)
    local shown = self:_FillMyArtRecipes(selE)
    if shown == 0 then
        local row = self:_MyArtRecRow(1)
        row.icon:SetTexture(Skin.tex.unknown)
        row.name:SetText("|cFF888888" .. L["Pas de recettes connues (métier de récolte ?)."] .. "|r")
        row.who:SetText(""); row:Show()
    end
end
