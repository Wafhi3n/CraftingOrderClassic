-- CraftingOrderClassic_UI.lua — fenêtre principale (skin tavern doré).
-- Deux onglets : Carnet d'ordres (poster/accepter/livrer/annuler) et Artisans (annuaire global).
-- Lit le cache (COC.db.orders + Directory), jamais le réseau directement.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local ROW_H = 22

local function me() return (UnitName and UnitName("player")) or "?" end

-- ------------------------------------------------------------------
-- Construction du cadre
-- ------------------------------------------------------------------
function UI:Build()
    if self.frame then return self.frame end
    local f = CreateFrame("Frame", "CraftingOrderClassicWindow", UIParent, "BackdropTemplate")
    f:SetSize(868, 600)
    f:SetPoint("CENTER")
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true); f:SetFrameStrata("HIGH")
    Skin.SkinFrameBackdrop(f)
    f:Hide()
    self.frame = f

    -- Fond tavern peint + voile assombrissant (lisibilité), à l'intérieur du cadre or.
    local bg = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    bg:SetPoint("TOPLEFT", 12, -12); bg:SetPoint("BOTTOMRIGHT", -12, 12)
    bg:SetTexture("Interface\\AddOns\\CraftingOrderClassic\\Textures\\tavern-bg.tga")
    local veil = f:CreateTexture(nil, "BACKGROUND", nil, 2)
    veil:SetPoint("TOPLEFT", bg); veil:SetPoint("BOTTOMRIGHT", bg)
    veil:SetColorTexture(0.04, 0.03, 0.02, 0.66)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFontObject(Skin.WordmarkFont())
    title:SetPoint("TOP", 0, -14); title:SetText("Crafting Order")
    local sub = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sub:SetPoint("TOP", title, "BOTTOM", 0, -1); sub:SetText("Classic · canal global")
    sub:SetTextColor(0.6, 1.0, 0.6); Skin.ApplyShadow(sub)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -8, -8)

    local status = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    status:SetPoint("BOTTOMLEFT", 16, 14); status:SetJustifyH("LEFT")
    Skin.ApplyShadow(status); self.status = status

    self:BuildTabs(f)
    self:BuildOrdersTab(f)
    self:BuildArtisansTab(f)
    if self.BuildPostTab then self:BuildPostTab(f) end
    self:ShowTab("orders")
    return f
end

function UI:BuildTabs(f)
    self.tabs = {}
    local defs = { { id = "orders", label = "Carnet" }, { id = "post", label = "Commande" }, { id = "artisans", label = "Artisans" } }
    for i, d in ipairs(defs) do
        local b = Skin.MakeGoldButton(f, 124, 24, d.label)
        b:SetPoint("TOPLEFT", 12 + (i - 1) * 128, -54)
        b:SetScript("OnClick", function() UI:ShowTab(d.id) end)
        self.tabs[d.id] = b
    end
end

function UI:ShowTab(id)
    self.activeTab = id
    for tid, b in pairs(self.tabs) do b:SetSelected(tid == id) end
    self.ordersPanel:SetShown(id == "orders")
    self.artisansPanel:SetShown(id == "artisans")
    if self.postPanel then self.postPanel:SetShown(id == "post") end
    self:Refresh()
end

-- ------------------------------------------------------------------
-- Helpers de liste (pool de lignes simple, non virtualisé : petits volumes)
-- ------------------------------------------------------------------
local function makeScroll(parent, name)
    local scroll = CreateFrame("ScrollFrame", name, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -78); scroll:SetPoint("BOTTOMRIGHT", -32, 64)
    local content = CreateFrame("Frame", nil, scroll); content:SetSize(440, 10)
    scroll:SetScrollChild(content)
    return scroll, content
end

-- ------------------------------------------------------------------
-- Onglet Carnet d'ordres
-- ------------------------------------------------------------------
function UI:BuildOrdersTab(f)
    local panel = CreateFrame("Frame", nil, f); panel:SetAllPoints(f); self.ordersPanel = panel
    local scroll, content = makeScroll(panel, "CraftingOrderOrdersScroll")
    self.ordersContent = content; self.orderRows = {}

    -- Barre de post : editbox (shift-clic objet) + bouton.
    local eb = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    eb:SetSize(330, 20); eb:SetPoint("BOTTOMLEFT", 18, 38); eb:SetAutoFocus(false)
    eb:SetScript("OnEnterPressed", function(self) UI:DoPost(self) end)
    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", eb, "TOPLEFT", 2, 2)
    hint:SetText("Shift-clic un objet ici, puis « Poster »  (ex: [Objet] x5 50g)")
    self.postBox = eb
    local post = Skin.MakeGoldButton(panel, 70, 22, "Poster")
    post:SetPoint("LEFT", eb, "RIGHT", 8, 0)
    post:SetScript("OnClick", function() UI:DoPost(eb) end)
end

function UI:DoPost(eb)
    local txt = eb:GetText()
    if txt and txt:match("item:%d+") then
        COC.Orders:PostFromInput(txt); eb:SetText(""); eb:ClearFocus(); self:Refresh()
    end
end

local function orderActionFor(o)
    local m = me()
    if o.status == "open" and o.buyer ~= m then return "Accepter", function() COC.Orders:Accept(o.id) end end
    if o.buyer == m and o.status ~= "done" and o.status ~= "cancelled" then
        return "Annuler", function() COC.Orders:Cancel(o.id) end
    end
    if o.acceptedBy == m and o.status == "accepted" then return "Livré", function() COC.Orders:Deliver(o.id) end end
    return nil
end

function UI:_OrderRow(i)
    local row = self.orderRows[i]
    if row then return row end
    row = CreateFrame("Frame", nil, self.ordersContent); row:SetSize(436, ROW_H)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
    local hi = row:CreateTexture(nil, "BACKGROUND"); hi:SetAllPoints()
    hi:SetColorTexture(Skin.unpack(Skin.color.rowHover)); hi:Hide(); row.hi = hi
    row.fs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.fs:SetPoint("LEFT", 4, 0); row.fs:SetWidth(300); row.fs:SetJustifyH("LEFT"); Skin.ApplyShadow(row.fs)
    row.btn = Skin.MakeGoldButton(row, 66, 16); row.btn:SetPoint("RIGHT", -2, 0)
    row:SetScript("OnEnter", function(r) r.hi:Show() end)
    row:SetScript("OnLeave", function(r) r.hi:Hide() end)
    self.orderRows[i] = row
    return row
end

function UI:RefreshOrders()
    local all = COC.Orders and COC.Orders:All() or {}
    local n = 0
    for _, o in ipairs(all) do
        if o.status ~= "cancelled" then
            n = n + 1
            local row = self:_OrderRow(n)
            local nm = COC.Orders and COC.Orders:OrderName(o) or "?"
            local col = (o.status == "open") and Skin.hex.green or Skin.hex.gold
            row.fs:SetText(string.format("|c%s%s|r x%d  |c%s%s|r  |cFF888888%s%s|r",
                Skin.hex.gold, nm, o.qty or 1, Skin.hex.muted, o.profession or "?",
                o.status, o.acceptedBy and (" · " .. o.acceptedBy) or ""))
            local label, fn = orderActionFor(o)
            if label then row.btn:SetText(label); row.btn:SetScript("OnClick", function() fn(); UI:Refresh() end); row.btn:Show()
            else row.btn:Hide() end
            row:Show()
        end
    end
    for i = n + 1, #self.orderRows do self.orderRows[i]:Hide() end
    self.ordersContent:SetHeight(math.max(n * ROW_H, 10))
    if n == 0 and self.orderRows[1] then
        local row = self:_OrderRow(1); row.btn:Hide()
        row.fs:SetText("|cFF888888Aucune commande. Poste-en une ci-dessous.|r"); row:Show()
    end
end

-- ------------------------------------------------------------------
-- Onglet Artisans (annuaire global)
-- ------------------------------------------------------------------
function UI:BuildArtisansTab(f)
    local panel = CreateFrame("Frame", nil, f); panel:SetAllPoints(f); panel:Hide()
    self.artisansPanel = panel
    local scroll, content = makeScroll(panel, "CraftingOrderArtisansScroll")
    self.artisansContent = content; self.artisanRows = {}
    local refresh = Skin.MakeGoldButton(panel, 110, 22, "Solliciter")
    refresh:SetPoint("BOTTOMLEFT", 18, 38)
    refresh:SetScript("OnClick", function() if COC.Directory then COC.Directory:Refresh() end; UI:Refresh() end)
end

function UI:_ArtisanRow(i)
    local row = self.artisanRows[i]
    if row then return row end
    row = CreateFrame("Frame", nil, self.artisansContent); row:SetSize(436, ROW_H)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
    row.fs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.fs:SetPoint("LEFT", 4, 0); row.fs:SetWidth(420); row.fs:SetJustifyH("LEFT"); Skin.ApplyShadow(row.fs)
    self.artisanRows[i] = row
    return row
end

function UI:RefreshArtisans()
    local D = COC.Directory
    local list = {}
    if D then for p in pairs(D.roster or {}) do list[#list + 1] = p end end
    table.sort(list, function(a, b)
        local oa, ob = D and D.online[a], D and D.online[b]
        if (oa and true) ~= (ob and true) then return oa end
        return a < b
    end)
    local n = 0
    for _, p in ipairs(list) do
        n = n + 1
        local row = self:_ArtisanRow(n)
        local on = D.online[p] and ("|cFF33DD33●|r") or ("|cFF555555○|r")
        local profs = {}
        for prof, hex in pairs(D.roster[p].recipes or {}) do profs[#profs + 1] = prof end
        row.fs:SetText(string.format("%s |cFFFFFFFF%s|r  |cFF888888%s|r", on, p, table.concat(profs, ", ")))
        row:Show()
    end
    for i = n + 1, #self.artisanRows do self.artisanRows[i]:Hide() end
    self.artisansContent:SetHeight(math.max(n * ROW_H, 10))
    if n == 0 and self.artisanRows[1] then
        local row = self:_ArtisanRow(1)
        row.fs:SetText("|cFF888888Aucun artisan connu. Clique « Solliciter » près d'autres porteurs.|r")
        row:Show()
    end
end

-- ------------------------------------------------------------------
-- Refresh global + statut + toggle
-- ------------------------------------------------------------------
function UI:Refresh()
    if not self.frame or not self.frame:IsShown() then return end
    if self.activeTab == "artisans" then self:RefreshArtisans()
    elseif self.activeTab == "post" and self.RefreshPost then self:RefreshPost()
    else self:RefreshOrders() end
    local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    local D = COC.Directory
    self.status:SetText(string.format("|c%sréseau|r %s  ·  %d en ligne  ·  %d artisan(s)",
        Skin.hex.muted,
        (CraftLink and CraftLink:IsNetworkReady()) and "|cFF33DD33canal rejoint|r" or "|cFFFFCC00…|r",
        D and D:CountOnline() or 0, D and D:CountKnownCrafters() or 0))
end

function UI:Toggle()
    self:Build()
    if self.frame:IsShown() then self.frame:Hide() else self.frame:Show(); self:Refresh() end
end
