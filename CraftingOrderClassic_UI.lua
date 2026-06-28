-- CraftingOrderClassic_UI.lua — fenêtre principale (skin tavern doré).
-- Deux onglets : Carnet d'ordres (poster/accepter/livrer/annuler) et Artisans (annuaire global).
-- Lit le cache (COC.db.orders + Directory), jamais le réseau directement.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L
local ROW_H = 22

local function me() return (UnitName and UnitName("player")) or "?" end
local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

-- Une commande passe-t-elle le filtre relationnel du Carnet ? « all » = tout ; sinon on regarde
-- la source du demandeur dans l'annuaire (guild/friend/recent). Mes propres commandes : partout.
local function orderMatchesFilter(o, filter)
    if filter == "all" then return true end
    if o.buyer == me() then return true end
    local D = COC.Directory
    local r = D and D.roster and D.roster[o.buyer]
    return (r and (r.source or "recent") or "recent") == filter
end

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
    sub:SetPoint("TOP", title, "BOTTOM", 0, -1); sub:SetText(L["Classic · canal global"])
    sub:SetTextColor(0.6, 1.0, 0.6); Skin.ApplyShadow(sub)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -8, -8)

    local status = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    status:SetPoint("BOTTOMLEFT", 16, 14); status:SetJustifyH("LEFT")
    Skin.ApplyShadow(status); self.status = status

    self:BuildTabs(f)
    self:BuildOrdersTab(f)
    self:BuildArtisansTab(f)
    if self.BuildPostTab   then self:BuildPostTab(f)   end
    if self.BuildGatherTab then self:BuildGatherTab(f) end
    self:ShowTab("orders")

    -- Résolution asynchrone des noms : Blizzard renvoie les infos d'objet en différé. Un seul
    -- handler central rafraîchit l'onglet actif (Carnet, réactifs, listes…) dès qu'un nom arrive.
    local nameEv = CreateFrame("Frame")
    nameEv:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    nameEv:SetScript("OnEvent", function() UI:_NamesDirty() end)

    return f
end

function UI:_NamesDirty()
    if self._nameTimer or not C_Timer then return end
    self._nameTimer = true
    C_Timer.After(0.3, function()
        UI._nameTimer = nil
        if UI.frame and UI.frame:IsShown() then UI:Refresh() end
    end)
end

function UI:BuildTabs(f)
    self.tabs = {}
    local defs = {
        { id = "orders",  label = L["Carnet"]   },
        { id = "post",    label = L["Commande"] },
        { id = "gather",  label = L["Récolte"]  },
        { id = "artisans",label = L["Artisans"] },
    }
    for i, d in ipairs(defs) do
        local b = Skin.MakeGoldButton(f, 118, 24, d.label)
        b:SetPoint("TOPLEFT", 12 + (i - 1) * 122, -54)
        b:SetScript("OnClick", function() UI:ShowTab(d.id) end)
        self.tabs[d.id] = b
    end
end

function UI:ShowTab(id)
    -- Changement d'onglet → on réinitialise les sélections (évite les faux clics / sélections
    -- fantômes d'un onglet à l'autre, ex. « Sélection : Écaille » qui traînait sous Élémentaire).
    if id ~= self.activeTab then
        self.postEntry = nil; self.postProvide = {}
        self.gatherEntry = nil
    end
    self.activeTab = id
    for tid, b in pairs(self.tabs) do b:SetSelected(tid == id) end
    self.ordersPanel:SetShown(id == "orders")
    if self.postPanel   then self.postPanel:SetShown(id == "post")    end
    if self.gatherPanel then self.gatherPanel:SetShown(id == "gather") end
    self.artisansPanel:SetShown(id == "artisans")
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
-- Onglet Carnet d'ordres — table (Commande · Qté · Prix · Métier · Destinataire · Statut)
-- ------------------------------------------------------------------
local ROW_T = 30
local COL = { name = 8, qty = 320, price = 372, prof = 500, dest = 612, status = 716 }

local function orderActionFor(o)
    local m = me()
    if o.status == "open" and o.buyer ~= m then return L["Accepter"], function() COC.Orders:Accept(o.id) end end
    if o.buyer == m and o.status ~= "done" and o.status ~= "cancelled" then
        return L["Annuler"], function() COC.Orders:Cancel(o.id) end
    end
    if o.acceptedBy == m and o.status == "accepted" then return L["Livrer"], function() COC.Orders:Deliver(o.id) end end
    return nil
end

-- Marge intérieure commune : décale TOUT le contenu d'un panneau vers l'intérieur d'un coup
-- (jeu sous les onglets + respiration contre la bordure dorée), sans retoucher chaque coordonnée.
local PAD_X, PAD_TOP, PAD_BOT = 8, 12, 8
local function insetPanel(panel, f)
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", f, "TOPLEFT", PAD_X, -PAD_TOP)
    panel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD_X, PAD_BOT)
end
UI.insetPanel = insetPanel

function UI:BuildOrdersTab(f)
    local panel = CreateFrame("Frame", nil, f); insetPanel(panel, f); self.ordersPanel = panel

    -- Rangée de filtres : relationnel (Tous/Guilde/Amis/Croisés) + file Entrantes (chat capté).
    self.orderFilter = "all"; self.orderFilterBtns = {}
    local fdefs = { {id="all",label=L["Tous"]}, {id="guild",label=L["Guilde"]}, {id="friend",label=L["Amis"]},
                    {id="recent",label=L["Croisés"]}, {id="inbound",label=L["Entrantes"]} }
    local fx = 12
    for _, d in ipairs(fdefs) do
        local w = (d.id == "inbound") and 104 or 78
        local b = Skin.MakeGoldButton(panel, w, 20, d.label); b:SetPoint("TOPLEFT", fx, -74)
        b:SetScript("OnClick", function() UI.orderFilter = d.id; UI:_RefreshOrderFilterTabs(); UI:RefreshOrders() end)
        self.orderFilterBtns[d.id] = b; fx = fx + w + 6
    end
    self:_RefreshOrderFilterTabs()

    -- En-tête de colonnes (libellés gris, alignés sur les colonnes des lignes)
    local function hdr(text, x)
        local h = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        h:SetPoint("TOPLEFT", 12 + x, -104); h:SetText(text)
        h:SetTextColor(Skin.unpack(Skin.color.textMuted)); Skin.ApplyShadow(h)
        return h
    end
    hdr(L["COMMANDE"], COL.name + 24); hdr(L["QTÉ"], COL.qty); hdr(L["PRIX PROPOSÉ"], COL.price)
    hdr(L["MÉTIER"], COL.prof); self.hdrDest = hdr(L["DESTINATAIRE"], COL.dest); hdr(L["STATUT"], COL.status)
    Skin.MakeSeparator(panel, -118)

    local scroll = CreateFrame("ScrollFrame", "CraftingOrderOrdersScroll", panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -124); scroll:SetPoint("BOTTOMRIGHT", -42, 22)
    local content = CreateFrame("Frame", nil, scroll); content:SetSize(800, 10); scroll:SetScrollChild(content)
    self.ordersContent = content; self.orderRows = {}
end

function UI:_RefreshOrderFilterTabs()
    for id, b in pairs(self.orderFilterBtns or {}) do b:SetSelected(id == self.orderFilter) end
    local ib = self.orderFilterBtns and self.orderFilterBtns.inbound
    if ib and COC.Inbound then
        local n = COC.Inbound:Count()
        ib:SetText(n > 0 and ("|cFFFF8800" .. L["Entrantes"] .. " (" .. n .. ")|r") or L["Entrantes"])
    end
end

function UI:_OrderRow(i)
    local row = self.orderRows[i]
    if row then return row end
    row = CreateFrame("Button", nil, self.ordersContent); row:SetSize(800, ROW_T)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_T)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local hi = row:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints()
    hi:SetColorTexture(Skin.unpack(Skin.color.rowHover))
    row.badge = Skin.MakeBadge(row, 18); row.badge:SetPoint("LEFT", COL.name, 0)
    local function col(x, w)
        local fs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("LEFT", x, 0); fs:SetWidth(w); fs:SetJustifyH("LEFT"); Skin.ApplyShadow(fs); return fs
    end
    row.name   = col(COL.name + 24, 284)
    row.qty    = col(COL.qty, 44)
    row.price  = col(COL.price, 120)
    row.prof   = col(COL.prof, 104)
    row.dest   = col(COL.dest, 96)
    row.status = col(COL.status, 80)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.orderRows[i] = row
    return row
end

function UI:RefreshOrders()
    if self.orderFilter == "inbound" then return self:_RefreshInbound() end
    if self.hdrDest then self.hdrDest:SetText(L["DESTINATAIRE"]) end
    local all = COC.Orders and COC.Orders:All() or {}
    local n = 0
    for _, o in ipairs(all) do
        if o.status ~= "cancelled" and orderMatchesFilter(o, self.orderFilter) then
            n = n + 1
            local row = self:_OrderRow(n)
            local nm = COC.Orders:OrderName(o)
            local r, g, b = Skin.RarityColor(o.itemID)
            row.badge:Paint(r, g, b, Skin.FirstChar(nm), Skin.Icon(o.itemID, o.spellID))
            row.name:SetText(nm); row.name:SetTextColor(r, g, b)
            row.qty:SetText("|cFFCCCCCC" .. (o.byStack and ((o.qty or 1) .. " st") or ("×" .. (o.qty or 1))) .. "|r")
            row.price:SetText(o.price and ("|c" .. Skin.hex.price .. o.price .. "|r") or "|cFF666666—|r")
            row.prof:SetText("|c" .. Skin.hex.gold .. Skin.ProfLabel(o.profession) .. "|r")
            row.dest:SetText("|cFFCCBB88" .. (o.recipient or "Tous") .. "|r")
            local slabel, scol = Skin.StatusInfo(o.status)
            row.status:SetText("|c" .. scol .. slabel .. "|r")
            local label, fn = orderActionFor(o)
            row:SetScript("OnClick", label and function() fn(); UI:Refresh() end or nil)
            row:SetScript("OnEnter", label and function(rr)
                GameTooltip:SetOwner(rr, "ANCHOR_RIGHT"); GameTooltip:AddLine(L["Clic : "] .. label, 1, 1, 1); GameTooltip:Show()
            end or nil)
            row:Show()
        end
    end
    for i = n + 1, #self.orderRows do self.orderRows[i]:Hide() end
    self.ordersContent:SetHeight(math.max(n * ROW_T, 10))
    Skin.AutoHideScroll("CraftingOrderOrdersScroll", self.ordersContent)
    if n == 0 and self.orderRows[1] then
        local row = self:_OrderRow(1); row.badge:Hide()
        row.name:SetText("|cFF888888" .. L["Aucune commande. Onglet « Commande » pour en poster une."] .. "|r")
        row.name:SetTextColor(0.6, 0.6, 0.6)
        row.qty:SetText(""); row.price:SetText(""); row.prof:SetText(""); row.dest:SetText(""); row.status:SetText("")
        row:SetScript("OnClick", nil); row:SetScript("OnEnter", nil); row:Show()
    end
end

-- Vue « Entrantes » : demandes captées dans /commerce et /guilde (joueurs SANS l'addon).
-- Clic gauche = accepter (whisper de pub au demandeur) ; clic droit = ignorer.
function UI:_RefreshInbound()
    if self.hdrDest then self.hdrDest:SetText(L["DEMANDEUR"]) end
    local c = CL()
    local all = COC.Inbound and COC.Inbound:All() or {}
    local n = 0
    for _, e in ipairs(all) do
        n = n + 1; local row = self:_OrderRow(n)
        local nm = (c and c:ItemName(e.itemID)) or ("item:" .. e.itemID)
        local r, g, b = Skin.RarityColor(e.itemID)
        row.badge:Paint(r, g, b, Skin.FirstChar(nm), Skin.Icon(e.itemID)); row.badge:Show()
        local warn = (not e.canCraft) and "  |cFFFF6666(hors skill)|r" or ""
        row.name:SetText((nm:match("^item:") and "|cFF777777Chargement…|r" or nm) .. warn)
        row.name:SetTextColor(r, g, b)
        row.qty:SetText("|cFFCCCCCC×" .. (e.qty or 1) .. "|r")
        row.price:SetText(e.price and ("|c" .. Skin.hex.price .. e.price .. "|r") or "|cFF666666—|r")
        row.prof:SetText("|c" .. Skin.hex.gold .. Skin.ProfLabel(e.profession) .. "|r")
        row.dest:SetText("|cFFFFFFFF" .. e.buyer .. "|r")
        local srcLbl = (e.source == "guild") and L["guilde"] or L["commerce"]
        row.status:SetText((e.status == "accepted") and ("|cFF33DD33" .. L["acceptée"] .. "|r")
            or ("|cFFFF8800◆ " .. srcLbl .. "|r"))
        row:SetScript("OnClick", function(_, button)
            if button == "RightButton" then COC.Inbound:Dismiss(e.id) else COC.Inbound:Accept(e.id) end
            UI:Refresh()
        end)
        row:SetScript("OnEnter", function(rr)
            GameTooltip:SetOwner(rr, "ANCHOR_RIGHT")
            GameTooltip:AddLine(L["Demande captée dans /"] .. srcLbl, 1, 1, 1)
            GameTooltip:AddLine(L["Clic gauche : accepter (whisper au demandeur)"], 0.6, 1, 0.6)
            GameTooltip:AddLine(L["Clic droit : ignorer"], 1, 0.6, 0.6)
            GameTooltip:Show()
        end)
        row:Show()
    end
    for i = n + 1, #self.orderRows do self.orderRows[i]:Hide() end
    self.ordersContent:SetHeight(math.max(n * ROW_T, 10))
    Skin.AutoHideScroll("CraftingOrderOrdersScroll", self.ordersContent)
    if n == 0 and self.orderRows[1] then
        local row = self:_OrderRow(1); row.badge:Hide()
        row.name:SetText("|cFF888888" .. L["Aucune commande entrante. (Capture /commerce et /guilde des joueurs sans l'addon.)"] .. "|r")
        row.name:SetTextColor(0.6, 0.6, 0.6)
        row.qty:SetText(""); row.price:SetText(""); row.prof:SetText(""); row.dest:SetText(""); row.status:SetText("")
        row:SetScript("OnClick", nil); row:SetScript("OnEnter", nil); row:Show()
    end
end

-- ------------------------------------------------------------------
-- Onglet Artisans (annuaire social) → CraftingOrderClassic_UI_Artisans.lua
-- (BuildArtisansTab / RefreshArtisans y sont définis ; chargé après ce fichier).
-- ------------------------------------------------------------------

-- ------------------------------------------------------------------
-- Refresh global + statut + toggle
-- ------------------------------------------------------------------
function UI:Refresh()
    if not self.frame or not self.frame:IsShown() then return end
    if     self.activeTab == "artisans"                          then self:RefreshArtisans()
    elseif self.activeTab == "post"   and self.RefreshPost       then self:RefreshPost()
    elseif self.activeTab == "gather" and self.RefreshGather     then self:RefreshGather()
    else self:RefreshOrders() end
    -- Compteur d'ordres actifs sur l'onglet Carnet (live, quel que soit l'onglet courant).
    if self.tabs and self.tabs.orders and COC.db then
        local c = 0; for _, o in pairs(COC.db.orders or {}) do if o.status ~= "cancelled" then c = c + 1 end end
        self.tabs.orders:SetText(L["Carnet"] .. " (" .. c .. ")")
    end
    if self.orderFilterBtns then self:_RefreshOrderFilterTabs() end
    local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    local D = COC.Directory
    self.status:SetText(string.format("|c%s" .. L["réseau"] .. "|r %s  ·  %d " .. L["en ligne"] .. "  ·  %d " .. L["artisan(s)"],
        Skin.hex.muted,
        (CraftLink and CraftLink:IsNetworkReady()) and ("|cFF33DD33" .. L["canal rejoint"] .. "|r") or "|cFFFFCC00…|r",
        D and D:CountOnline() or 0, D and D:CountKnownCrafters() or 0))
end

function UI:Toggle()
    self:Build()
    if self.frame:IsShown() then self.frame:Hide() else self.frame:Show(); self:Refresh() end
end
