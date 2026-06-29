-- CraftingOrderClassic_ProfWindow.lua — fenêtre métier custom 3 colonnes (migration depuis
-- Guild Economy) : Recettes | Détail+Craft | Commandes du métier. Remplace la fenêtre Blizzard
-- (neutralisée, jamais Hide() pour garder la session lisible). Colonnes dans _Recipes / _Detail ;
-- la colonne Commandes vit ici (réutilise le carnet/entrantes du métier ouvert).
--
-- EXPÉRIMENTAL : activé via `/co profwindow` (COC.db.profWindow). Quand ON, désactive le takeover
-- de Guild Economy (TradeScannerDB.replaceProfWindow=false) → jamais deux fenêtres à la fois.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L
local PW   = {}
COC.ProfWindow = PW

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

PW.FRAME_W, PW.FRAME_H = 792, 500
PW.HEADER_H = 56
PW.COL_W = { 236, 252, 252 }
PW.GAP, PW.PAD = 10, 14

local GATHER = { Mining = true, Herbalism = true, Skinning = true, Fishing = true }

-- Sais-je honorer cette commande ? (récolte = j'ai le skill ; craft = je connais la recette)
function PW.CanFulfill(o)
    local prof = o.profession; if not prof then return nil end
    local c, D = CL(), COC.Directory
    if GATHER[prof] then return (D and D.mySkills and D.mySkills[prof]) ~= nil end
    if not c then return nil end
    if o.itemID  and c:IKnowRecipeForItem(prof, o.itemID)  then return true end
    if o.spellID and c:IKnowRecipeBySpell(prof, o.spellID) then return true end
    return false
end

-- ------------------------------------------------------------------
-- Neutralisation de la frame native (garde la session vivante)
-- ------------------------------------------------------------------
local NATIVE = {}
local uiPanelDetached = false
local function detachUIPanels()
    if uiPanelDetached then return end
    uiPanelDetached = true
    if _G.UIPanelWindows then UIPanelWindows["TradeSkillFrame"] = nil; UIPanelWindows["CraftFrame"] = nil end
end
local function neutralize(frame, key)
    if not frame then return end
    if not NATIVE[key] then NATIVE[key] = { alpha = frame:GetAlpha(), mouse = frame:IsMouseEnabled() } end
    frame:SetAlpha(0); frame:EnableMouse(false)
end
local function restore(frame, key)
    if not frame or not NATIVE[key] then return end
    frame:SetAlpha(NATIVE[key].alpha or 1); frame:EnableMouse(NATIVE[key].mouse ~= false); NATIVE[key] = nil
end
function PW:NeutralizeNative()
    detachUIPanels(); neutralize(_G.TradeSkillFrame, "trade"); neutralize(_G.CraftFrame, "craft")
end
function PW:RestoreNative() restore(_G.TradeSkillFrame, "trade"); restore(_G.CraftFrame, "craft") end

-- ------------------------------------------------------------------
-- Construction du shell
-- ------------------------------------------------------------------
function PW:_BuildHeader(f)
    local mark = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mark:SetPoint("TOPLEFT", 14, -12); mark:SetText("Crafting Order")
    mark:SetTextColor(Skin.unpack(Skin.color.goldOre)); Skin.ApplyShadow(mark)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12); title:SetTextColor(Skin.unpack(Skin.color.goldHi)); Skin.ApplyShadow(title)
    self.titleFS = title

    local rank = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rank:SetPoint("TOP", title, "BOTTOM", 0, -2); rank:SetTextColor(Skin.unpack(Skin.color.text))
    Skin.ApplyShadow(rank); self.rankFS = rank

    local vanilla = Skin.MakeGoldButton(f, 96, 20, L["Vue Blizzard"])
    vanilla:SetPoint("TOPRIGHT", -36, -12)
    vanilla:SetScript("OnClick", function() PW:SetEnabled(false) end)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)
    close:SetScript("OnClick", function()
        if COC.Craft and COC.Craft:IsCraftOpen() then if CloseCraft then CloseCraft() end
        elseif CloseTradeSkill then CloseTradeSkill() end
        PW:Hide()
    end)
    Skin.MakeSeparator(f, -(self.HEADER_H - 2))
end

function PW:_BuildColumn(f, width, leftAnchor)
    local col = CreateFrame("Frame", nil, f)
    col:SetWidth(width)
    col:SetPoint("TOPLEFT", leftAnchor.frame, leftAnchor.point, leftAnchor.x, -self.HEADER_H)
    col:SetPoint("BOTTOM", f, "BOTTOM", 0, self.PAD)
    if Skin.SkinWell then Skin.SkinWell(col) end
    return col
end

function PW:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", "CraftingOrderProfWindow", UIParent, "BackdropTemplate")
    f:SetSize(self.FRAME_W, self.FRAME_H)
    local pos = COC.db and COC.db.profWinPos               -- position persistée (drag) ou centre par défaut
    if pos then f:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else f:SetPoint("CENTER") end
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(fr)
        fr:StopMovingOrSizing()
        local p, _, rp, x, y = fr:GetPoint()
        if COC.db then COC.db.profWinPos = { p, rp, x, y } end
    end)
    f:SetClampedToScreen(true); f:SetFrameStrata("HIGH"); Skin.SkinFrameBackdrop(f); f:Hide()
    self.frame = f
    self:_BuildHeader(f)

    local recCol = self:_BuildColumn(f, self.COL_W[1], { frame = f, point = "TOPLEFT", x = self.PAD })
    local detCol = self:_BuildColumn(f, self.COL_W[2], { frame = recCol, point = "TOPRIGHT", x = self.GAP })
    local ordCol = self:_BuildColumn(f, self.COL_W[3], { frame = detCol, point = "TOPRIGHT", x = self.GAP })
    self.recCol, self.detCol, self.ordCol = recCol, detCol, ordCol

    if self._BuildRecipes then self:_BuildRecipes(recCol) end
    if self._BuildDetail  then self:_BuildDetail(detCol)  end
    self:_BuildOrders(ordCol)
end

-- ------------------------------------------------------------------
-- Colonne DROITE : commandes liées au métier ouvert (carnet + entrantes)
-- ------------------------------------------------------------------
local ORD_H = 30
function PW:_BuildOrders(col)
    local hdr = col:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr:SetPoint("TOPLEFT", 8, -6); hdr:SetText("|cFFE8B84B" .. L["Commandes"] .. "|r"); self.ordHdr = hdr

    local scroll = CreateFrame("ScrollFrame", "CraftingOrderProfWinOrdScroll", col, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 6, -28); scroll:SetPoint("BOTTOMRIGHT", -24, 6)
    local content = CreateFrame("Frame", nil, scroll); content:SetSize(210, 10); scroll:SetScrollChild(content)
    self.ordContent = content; self.ordRows = {}
end

function PW:_OrdRow(i)
    local r = self.ordRows[i]; if r then return r end
    r = CreateFrame("Frame", nil, self.ordContent); r:SetSize(210, ORD_H); r:SetPoint("TOPLEFT", 0, -(i - 1) * ORD_H)
    r.badge = Skin.MakeBadge(r, 16); r.badge:SetPoint("TOPLEFT", 2, -1)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.name:SetPoint("TOPLEFT", 22, -2); r.name:SetWidth(180); r.name:SetJustifyH("LEFT"); Skin.ApplyShadow(r.name)
    r.sub = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.sub:SetPoint("TOPLEFT", 22, -16); r.sub:SetWidth(184); r.sub:SetJustifyH("LEFT"); Skin.ApplyShadow(r.sub)
    r:EnableMouse(true)
    r:SetScript("OnEnter", function(self)
        if not self.tipItemID then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. self.tipItemID) then GameTooltip:Show() else GameTooltip:Hide() end
    end)
    r:SetScript("OnLeave", GameTooltip_Hide)
    self.ordRows[i] = r; return r
end

function PW:RefreshOrders()
    if not self.ordContent then return end
    local prof = self.profKey; local c = CL()
    local list = {}
    for _, o in pairs((COC.db and COC.db.orders) or {}) do
        if o.profession == prof and o.status ~= "cancelled" and o.status ~= "done" then
            list[#list + 1] = { o = o, kind = "order" }
        end
    end
    for _, e in pairs((COC.db and COC.db.inbound) or {}) do
        if e.profession == prof and e.status ~= "dismissed" then list[#list + 1] = { o = e, kind = "inbound" } end
    end
    table.sort(list, function(a, b) return (a.o.ts or 0) > (b.o.ts or 0) end)
    local n = 0
    for _, it in ipairs(list) do
        n = n + 1; local row = self:_OrdRow(n); local o = it.o
        local nm = (c and c:ItemName(o.itemID)) or (o.spellID and c and c:RecipeName(o.spellID)) or ("item:" .. (o.itemID or 0))
        local r, g, b = Skin.RarityColor(o.itemID)
        row.tipItemID = o.itemID
        row.badge:Paint(r, g, b, Skin.FirstChar(nm), Skin.Icon(o.itemID, o.spellID) or Skin.tex.unknown)
        local able = PW.CanFulfill(o)
        local tag = (able == true) and "|cFF33DD33✓|r " or (able == false) and "|cFFFF5555✗|r " or ""
        row.name:SetText(tag .. ((nm:match("^item:") and L["Chargement…"]) or nm)); row.name:SetTextColor(r, g, b)
        local who = (it.kind == "inbound") and (L["entrante · "] .. o.buyer) or (o.buyer or "?")
        local qty = o.byStack and ((o.qty or 1) .. " st") or ("×" .. (o.qty or 1))
        row.sub:SetText("|cFF999999" .. qty .. " · " .. who .. "|r" .. (o.price and ("  |cFFFFDD00" .. o.price .. "|r") or ""))
        row:Show()
    end
    for i = n + 1, #self.ordRows do self.ordRows[i]:Hide() end
    self.ordContent:SetHeight(math.max(n * ORD_H, 10))
    Skin.AutoHideScroll("CraftingOrderProfWinOrdScroll", self.ordContent)
    self.ordHdr:SetText("|cFFE8B84B" .. L["Commandes"] .. "|r |cFF888888(" .. n .. ")|r")
end

-- ------------------------------------------------------------------
-- Refresh global (coalescé)
-- ------------------------------------------------------------------
function PW:Hide() if self.frame then self.frame:Hide() end end

function PW:_DoRefresh()
    self._pending = false
    if not self.frame or not self.frame:IsShown() then return end
    local craft = COC.Craft; if not craft then return end
    local name = craft:GetOpenProfessionInfo(); if not name then return end
    self.profKey = craft:OpenProfessionKey()
    self.titleFS:SetText(name)
    local rank, maxRank = craft:OpenRank()
    self.rankFS:SetText((rank and maxRank) and string.format("|cFFE8B84B%d|r / %d", rank, maxRank) or "")
    self.recipes = craft:ReadRecipes() or {}
    if self.RefreshRecipes then self:RefreshRecipes() end
    if self.RefreshDetail  then self:RefreshDetail()  end
    self:RefreshOrders()
end

function PW:Refresh()
    if not (C_Timer and C_Timer.After) then return self:_DoRefresh() end
    if self._pending then return end
    self._pending = true
    C_Timer.After(0.1, function() PW:_DoRefresh() end)
end

-- ------------------------------------------------------------------
-- Entrées (depuis le coordinateur d'événements ProfOrders) + bascule
-- ------------------------------------------------------------------
function PW:IsEnabled() return COC.db and COC.db.profWindow == true end

-- Active/désactive la fenêtre custom. ON → coupe le takeover de Guild Economy (anti-conflit).
function PW:SetEnabled(on)
    if COC.db then COC.db.profWindow = on and true or false end
    if on then
        if _G.TradeScannerDB then TradeScannerDB.replaceProfWindow = false end   -- GE laisse la main
        print("|cFF33DD88Crafting Order|r " .. L["fenêtre métier custom |cFF33DD33activée|r — ouvre un métier. (Guild Economy laisse la main.)"])
        self:OnProfessionShow()
    else
        self:Hide(); self:RestoreNative()
        print("|cFF33DD88Crafting Order|r " .. L["fenêtre métier custom |cFFFFCC00désactivée|r (vue Blizzard)."])
        -- L'overlay « commandes du métier » reprend la main si une fenêtre est ouverte.
        if COC.ProfOrders and COC.ProfOrders.OnProfShow then COC.ProfOrders:OnProfShow() end
    end
end

local function silenceGE()
    if _G.TradeScannerDB then TradeScannerDB.replaceProfWindow = false end
    if _G.TradeScanner and TradeScanner.ProfWindow and TradeScanner.ProfWindow.Hide then
        TradeScanner.ProfWindow:Hide()
    end
end

function PW:OnProfessionShow()
    if not self:IsEnabled() then return end
    local craft = COC.Craft
    if not (craft and craft:GetOpenProfessionInfo()) then return end
    silenceGE()                         -- coexistence : pas de double panneau si GE est chargé
    self:Build(); self:NeutralizeNative()
    if not self.frame:IsShown() then self.frame:Show() end
    self:Refresh()
    -- L'ordre de dispatch des events entre addons n'est pas garanti : si GE traite SHOW APRÈS nous
    -- (et restaure la frame native / réaffiche sa fenêtre), on re-museler juste après.
    if C_Timer then C_Timer.After(0.05, function() silenceGE(); PW:NeutralizeNative() end) end
end

function PW:OnProfessionClose()
    self.selectedIndex = nil
    self:Hide(); self:RestoreNative()
end
