-- CraftingOrderClassic_ProfWindow_Orders.lua — colonne « Commandes » de la vue métier (cabine de
-- l'artisan). Cartes par demandeur avec onglets de relation (Guilde / Amis / Croisés / Tous),
-- marqueur « je sais faire » (✓/✗ en TEXTURE), prix, résumé des composants fournis, et actions
-- ACCEPTER / LIVRER + CHUCHOTER ; clic droit = sourdine (ordre) / ignorer (entrante). Inclut les
-- demandes captées (/commerce, /guilde). Sorti de _ProfWindow.lua (anti-monolithe).

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L
local PW   = COC.ProfWindow

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

local CARD_H, CARD_W = 84, 232
local REL = {
    { id = "all",    label = L["Tous"]    },
    { id = "guild",  label = L["Guilde"]  },
    { id = "friend", label = L["Amis"]    },
    { id = "recent", label = L["Croisés"] },
}
local REL_COL = { guild = "FF8FD98F", friend = "FF6FB7FF", recent = "FFCBB389" }

-- Relation du demandeur (depuis l'annuaire) : "guild"/"friend"/"recent", ou nil si inconnu.
local function relationOf(name)
    local D = COC.Directory; local r = D and D.roster and D.roster[name]
    if not r then return nil end
    if r.isGuild  then return "guild"  end
    if r.isFriend then return "friend" end
    return "recent"
end

-- Résumé « composants fournis par l'acheteur » : X/Y (Y = nb de réactifs). Vide hors craft.
local function providedSummary(o)
    if not (o.spellID and o.profession) then return "" end
    local c = CL(); local reag = c and c:RecipeReagents(o.profession, o.spellID)
    if not (reag and #reag > 0) then return "" end
    local prov = {}; for _, id in ipairs(o.provided or {}) do prov[id] = true end
    local x = 0; for _, rg in ipairs(reag) do if prov[rg[1]] then x = x + 1 end end
    return string.format("|T%s:11|t |cFF999999%d/%d %s|r", Skin.tex.ok, x, #reag, L["fournis"])
end

-- ------------------------------------------------------------------
-- Construction (en-tête + onglets de relation + scroll de cartes)
-- ------------------------------------------------------------------
function PW:_BuildOrders(col)
    self.ordRelTab = self.ordRelTab or "all"
    local hdr = col:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr:SetPoint("TOPLEFT", 8, -6); hdr:SetText("|cFFE8B84B" .. L["Commandes"] .. "|r"); self.ordHdr = hdr
    self.ordRelBtns = {}
    local x = 6
    for _, d in ipairs(REL) do
        local b = Skin.MakeGoldButton(col, 54, 16, d.label); b:SetPoint("TOPLEFT", x, -26)
        b:SetScript("OnClick", function() PW.ordRelTab = d.id; PW:_RefreshRelTabs(); PW:RefreshOrders() end)
        self.ordRelBtns[d.id] = b; x = x + 56
    end
    self:_RefreshRelTabs()
    local scroll = CreateFrame("ScrollFrame", "CraftingOrderProfWinOrdScroll", col, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 6, -48); scroll:SetPoint("BOTTOMRIGHT", -24, 6)
    local content = CreateFrame("Frame", nil, scroll); content:SetSize(CARD_W, 10); scroll:SetScrollChild(content)
    self.ordContent = content; self.ordCards = {}
end

function PW:_RefreshRelTabs()
    for id, b in pairs(self.ordRelBtns or {}) do b:SetSelected(id == self.ordRelTab) end
end

function PW:_Age(ts)
    if not ts then return "" end
    local d = time() - ts
    if d < 60 then return d .. "s" elseif d < 3600 then return math.floor(d / 60) .. "m"
    elseif d < 86400 then return math.floor(d / 3600) .. "h" else return math.floor(d / 86400) .. "j" end
end

-- ------------------------------------------------------------------
-- Carte (pool, hauteur fixe)
-- ------------------------------------------------------------------
function PW:_OrdCard(i)
    local c = self.ordCards[i]; if c then return c end
    c = CreateFrame("Frame", nil, self.ordContent, "BackdropTemplate")
    c:SetSize(CARD_W, CARD_H); c:SetPoint("TOPLEFT", 0, -(i - 1) * (CARD_H + 4)); Skin.SkinWell(c)
    c.dot = Skin.MakeStatusIcon(c, 12); c.dot:SetPoint("TOPLEFT", 8, -7)
    c.who = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    c.who:SetPoint("LEFT", c.dot, "RIGHT", 4, 0); Skin.ApplyShadow(c.who)
    c.age = c:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    c.age:SetPoint("TOPRIGHT", -8, -8); Skin.ApplyShadow(c.age)
    c.badge = Skin.MakeBadge(c, 16); c.badge:SetPoint("TOPLEFT", 8, -25)
    c.item = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    c.item:SetPoint("LEFT", c.badge, "RIGHT", 4, 0); c.item:SetWidth(140); c.item:SetJustifyH("LEFT"); Skin.ApplyShadow(c.item)
    c.price = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    c.price:SetPoint("TOPRIGHT", -8, -27); Skin.ApplyShadow(c.price)
    c.reag = c:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    c.reag:SetPoint("TOPLEFT", 10, -44); c.reag:SetWidth(214); c.reag:SetJustifyH("LEFT"); Skin.ApplyShadow(c.reag)
    c.act = Skin.MakeGoldButton(c, 96, 18, L["Accepter"]); c.act:SetPoint("BOTTOMLEFT", 8, 6)
    c.whisper = Skin.MakeGoldButton(c, 78, 18, L["Chuchoter"]); c.whisper:SetPoint("LEFT", c.act, "RIGHT", 6, 0)
    c:EnableMouse(true); Skin.WireItemTooltip(c)
    self.ordCards[i] = c; return c
end

-- Actions de la carte : bouton principal (accepter/livrer), chuchoter, clic droit = sourdine/ignorer.
function PW:_CardActions(card, it)
    local o, kind = it.o, it.kind
    local label, fn
    if kind == "inbound" then label, fn = L["Accepter"], function() COC.Inbound:Accept(o.id) end
    else label, fn = COC.Orders:ProfRowAction(o) end
    card.act:SetShown(fn ~= nil)
    if fn then
        card.act:SetText(label)
        card.act:SetScript("OnClick", function() fn(); PW:RefreshOrders(); if COC.UI then COC.UI:Refresh() end end)
    end
    card.whisper:SetScript("OnClick", function() if ChatFrame_SendTell then ChatFrame_SendTell(o.buyer) end end)
    card:SetScript("OnMouseUp", function(_, btn)
        if btn ~= "RightButton" then return end
        if kind == "inbound" then COC.Inbound:Dismiss(o.id)
        else COC.db.muted = COC.db.muted or {}; COC.db.muted[o.id] = true end
        PW:RefreshOrders()
    end)
end

function PW:_FillCard(card, it)
    local o, kind = it.o, it.kind; local c = CL()
    local nm = (c and c:ItemName(o.itemID)) or (o.spellID and c and c:RecipeName(o.spellID)) or ("item:" .. (o.itemID or 0))
    local rr, gg, bb = Skin.RarityColor(o.itemID)
    card.tipItemID = o.itemID
    card.badge:Paint(rr, gg, bb, Skin.FirstChar(nm), Skin.Icon(o.itemID, o.spellID) or Skin.tex.unknown)
    local able = PW.CanFulfill(o)
    local mk = (able == true) and ("|T" .. Skin.tex.ok .. ":12|t ") or (able == false) and ("|T" .. Skin.tex.fail .. ":12|t ") or ""
    card.item:SetText(mk .. ((nm:match("^item:") and L["Chargement…"]) or nm)); card.item:SetTextColor(rr, gg, bb)
    local rel = relationOf(o.buyer) or "recent"
    local online = COC.Directory and COC.Directory.online and COC.Directory.online[o.buyer]
    card.dot:SetOnline(online and true or false)
    local tag = (kind == "inbound") and (" |T" .. Skin.tex.dotYellow .. ":10|t") or ""
    card.who:SetText("|c" .. (REL_COL[rel] or "FFFFFFFF") .. (o.buyer or "?") .. "|r" .. tag)
    card.age:SetText("|cFF777777" .. self:_Age(o.ts) .. "|r")
    local qty = o.byStack and ((o.qty or 1) .. " st") or ("×" .. (o.qty or 1))
    local price = o.price and ("|cFFFFDD00" .. o.price .. "|r") or ("|cFF888888" .. L["Don / gratuit"] .. "|r")
    card.price:SetText("|cFFCCCCCC" .. qty .. "|r  " .. price)
    card.reag:SetText(providedSummary(o))
    self:_CardActions(card, it)
    card:Show()
end

-- ------------------------------------------------------------------
-- Rafraîchissement : collecte (carnet + entrantes) filtrée par métier ouvert + relation.
-- ------------------------------------------------------------------
function PW:RefreshOrders()
    if not self.ordContent then return end
    local prof, relTab = self.profKey, self.ordRelTab or "all"
    local muted = (COC.db and COC.db.muted) or {}
    local function keep(name) return relTab == "all" or relationOf(name) == relTab end
    local list = {}
    for _, o in pairs((COC.db and COC.db.orders) or {}) do
        if o.profession == prof and o.status ~= "cancelled" and o.status ~= "done" and not muted[o.id] and keep(o.buyer) then
            list[#list + 1] = { o = o, kind = "order" }
        end
    end
    for _, e in pairs((COC.db and COC.db.inbound) or {}) do
        if e.profession == prof and e.status ~= "dismissed" and keep(e.buyer) then
            list[#list + 1] = { o = e, kind = "inbound" }
        end
    end
    table.sort(list, function(a, b) return (a.o.ts or 0) > (b.o.ts or 0) end)
    local n = 0
    for _, it in ipairs(list) do n = n + 1; self:_FillCard(self:_OrdCard(n), it) end
    for i = n + 1, #self.ordCards do self.ordCards[i]:Hide() end
    self.ordContent:SetHeight(math.max(n * (CARD_H + 4), 10))
    Skin.AutoHideScroll("CraftingOrderProfWinOrdScroll", self.ordContent)
    self.ordHdr:SetText("|cFFE8B84B" .. L["Commandes"] .. "|r |cFF888888(" .. n .. ")|r")
end
