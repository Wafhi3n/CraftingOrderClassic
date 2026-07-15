-- CraftingOrderClassic_ProfWindow_Orders_Card.lua — vue SÉLECTIONNÉE de la colonne « Commandes » :
-- la carte complète d'une commande (composants fournis, repères Lazy Gold, ACCEPTER / REFUSER /
-- CHUCHOTER ; croix en haut à droite = retour liste). Sorti de _ProfWindow_Orders.lua
-- (anti-monolithe) — la LISTE, la collecte et les helpers partagés (_OrderReagents, _OrderItemName,
-- _OrdRelation, PW.ORD_REL_COL, PW.ORD_CARD_W) restent là-bas.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L
local PW   = COC.ProfWindow

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

local CARD_W     = PW.ORD_CARD_W or 280
local REAG_RH    = 50        -- hauteur d'une ligne de réactif dans le panneau « composants »
local MAX_REAG   = 8         -- plafond d'affichage (au-delà : tronqué ; rare en Classic)
local PANEL_HDR  = 16        -- hauteur de l'en-tête du panneau « COMPOSANTS FOURNIS »

-- Mini-SPEC de la CARTE de commande — même grammaire que les vues (h / bg / pad éditables ici).
-- Trois zones : en-tête (demandeur + âge + inviter), corps FLEX (objet, prix, composants, Lazy Gold),
-- pied (Accepter / Refuser / Chuchoter). Le flex est ancré haut ET bas → quand la carte change de
-- hauteur (panneau composants variable), le pied reste collé en bas tout seul.
local CARD_HDR, CARD_FOOT = 20, 24
local CARD_COMPACT = CARD_HDR + 26 + CARD_FOOT   -- carte sans plan connu (objet seul / récolte)
local CARD = {
    x1 = 0, x2 = CARD_W, sepInset = 6 ,
    { top = 0, bottom = 0, left = 2,
        { id = "hdr",  h = CARD_HDR, bg = true },
        { id = "body" },
        { id = "foot", h = CARD_FOOT , bg = true},
    },
}

-- ------------------------------------------------------------------
-- Construction (pool, hauteur variable)
-- ------------------------------------------------------------------
-- Panneau « composants » de la carte : en-tête X/Y + pool de lignes réactif (coche fournie / À FOURNIR).
-- Hauteur ajustée au remplissage (cf. _FillReagPanel) ; masqué quand le plan est inconnu.
-- `bz` = zone CORPS de la carte (le panneau vit sous la rangée objet/prix, à −26).
local function buildReagPanel(c, bz)
    local p = CreateFrame("Frame", nil, bz, "BackdropTemplate")
    p:SetPoint("TOPLEFT", 8, -26); p:SetPoint("RIGHT", bz, "RIGHT", -8, 0); Skin.SkinWell(p)
    p.hdr = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    p.hdr:SetPoint("TOPLEFT", 6, -3); p.hdr:SetPoint("RIGHT", -24, 0); p.hdr:SetJustifyH("LEFT"); Skin.ApplyShadow(p.hdr)
    -- Bouton « diffuser les réactifs » (liste de courses) dans l'en-tête du panneau, à droite du compteur.
    p.share = Skin.MakeIconButton(p, 15, "Interface\\ChatFrame\\UI-ChatIcon-ArmoryChat")
    p.share:SetPoint("TOPRIGHT", -4, -2)
    p.share:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_LEFT"); GameTooltip:SetText(L["Diffuser les réactifs dans un canal"], 1, 1, 1); GameTooltip:Show()
    end)
    p.share:SetScript("OnLeave", GameTooltip_Hide)
    p.rows = {}
    for j = 1, MAX_REAG do
        local r = CreateFrame("Frame", nil, p)
        r:SetSize(200, REAG_RH); r:SetPoint("TOPLEFT", 6, -PANEL_HDR - (j - 1) * REAG_RH); r:SetPoint("RIGHT", p, "RIGHT", -6, 0)
        r.mark = r:CreateTexture(nil, "ARTWORK"); r.mark:SetSize(11, 11); r.mark:SetPoint("LEFT", 0, 0)
        r.info = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        r.info:SetPoint("RIGHT", 0, 0); r.info:SetJustifyH("RIGHT"); Skin.ApplyShadow(r.info)
        r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.name:SetPoint("LEFT", r.mark, "RIGHT", 4, 0); r.name:SetPoint("RIGHT", r.info, "LEFT", -4, 0)
        r.name:SetJustifyH("LEFT"); r.name:SetWordWrap(false); Skin.ApplyShadow(r.name)
        r:Hide(); p.rows[j] = r
    end
    p:Hide(); c.reagPanel = p
end

-- EN-TÊTE de la carte : pastille de présence + demandeur à gauche ; à droite, la CROIX de retour à
-- la vue liste (la carte n'apparaît qu'en vue sélectionnée), puis « Inviter » et l'âge.
local function buildCardHeader(c, hz)
    c.dot = Skin.MakeStatusIcon(hz, 12); c.dot:SetPoint("LEFT", 8, 0)
    c.who = hz:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    c.who:SetPoint("LEFT", c.dot, "RIGHT", 4, 0); Skin.ApplyShadow(c.who)
    c.closeSel = CreateFrame("Button", nil, hz, "UIPanelCloseButton")
    c.closeSel:SetSize(24, 24); c.closeSel:SetPoint("RIGHT", 2, 0)
    c.closeSel:SetScript("OnClick", function() PW.ordSelected = nil; PW:RefreshOrders() end)
    -- Bouton « Inviter en groupe » (visible si l'acheteur est en ligne) → l'artisan l'invite pour
    -- lui remettre les composants / la marchandise via l'échange.
    c.invite = CreateFrame("Button", nil, hz)
    c.invite:SetSize(16, 16); c.invite:SetPoint("RIGHT", -24, 0)
    c.invite:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
    c.invite:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-Down")
    c.invite:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
    c.invite:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_RIGHT"); GameTooltip:SetText(L["Inviter en groupe"], 1, 1, 1); GameTooltip:Show()
    end)
    c.invite:SetScript("OnLeave", GameTooltip_Hide)
    c.age = hz:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    c.age:SetPoint("RIGHT", c.invite, "LEFT", -4, 0); Skin.ApplyShadow(c.age)
end

-- CORPS de la carte : rangée objet (badge + nom + prix) puis panneau composants + ligne Lazy Gold.
local function buildCardBody(c, bz)
    c.badge = Skin.MakeBadge(bz, 16); c.badge:SetPoint("TOPLEFT", 8, -4)
    c.item = bz:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    c.item:SetPoint("LEFT", c.badge, "RIGHT", 4, 0); c.item:SetWidth(140); c.item:SetJustifyH("LEFT"); Skin.ApplyShadow(c.item)
    c.price = bz:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    c.price:SetPoint("TOPRIGHT", -8, -6); Skin.ApplyShadow(c.price)
    buildReagPanel(c, bz)
    -- Ligne « dois-je accepter ? » (Lazy Gold) : sous le panneau composants, au-dessus du pied.
    c.lgLine = bz:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    c.lgLine:SetPoint("TOPLEFT", c.reagPanel, "BOTTOMLEFT", 0, -3)
    c.lgLine:SetPoint("RIGHT", bz, "RIGHT", -8, 0)
    c.lgLine:SetJustifyH("LEFT"); c.lgLine:SetWordWrap(false); Skin.ApplyShadow(c.lgLine); c.lgLine:Hide()
end

function PW:_OrdCard(i)
    local c = self.ordCards[i]; if c then return c end
    c = CreateFrame("Frame", nil, self.ordContent, "BackdropTemplate")
    c:SetSize(CARD_W, CARD_COMPACT); c:SetPoint("TOPLEFT", 0, 0); Skin.SkinWell(c)
    -- Zones de la mini-SPEC sur une frame hôte dédiée (isole le découpage du puits de fond).
    local host = CreateFrame("Frame", nil, c); host:SetAllPoints(); c.zones = host
    local z = Skin.MakeSections(host, CARD)
    buildCardHeader(c, z.hdr)
    buildCardBody(c, z.body)
    -- PIED : 3 boutons compacts (≈208 px) qui tiennent dans la largeur VISIBLE de la colonne
    -- (scroll ~222 px) : Accepter / Refuser / Chuchoter (Refuser caché → Chuchoter glisse à gauche).
    c.act = Skin.MakeGoldButton(z.foot, 66, 18, L["Accepter"]); c.act:SetPoint("LEFT", 8, 0)
    c.refuse = Skin.MakeGoldButton(z.foot, 54, 18, L["Refuser"]); c.refuse:SetPoint("LEFT", c.act, "RIGHT", 4, 0)
    c.whisper = Skin.MakeGoldButton(z.foot, 72, 18, L["Chuchoter"]); c.whisper:SetPoint("LEFT", c.refuse, "RIGHT", 4, 0)
    c:EnableMouse(true); Skin.WireItemTooltip(c); Skin.WireItemLink(c)   -- survol = tooltip, shift-clic = lien
    self.ordCards[i] = c; return c
end

-- ------------------------------------------------------------------
-- Remplissage
-- ------------------------------------------------------------------
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
    -- « Refuser » visible (plus seulement clic droit) quand la commande m'est actionnable : entrante →
    -- ignorer ; ordre → décliner (masque chez moi + prévient le demandeur s'il m'avait ciblé / si je
    -- me désiste d'une commande acceptée). Voir Orders:Decline.
    card.refuse:SetShown(fn ~= nil)
    card.refuse:SetScript("OnClick", function()
        if kind == "inbound" then COC.Inbound:Dismiss(o.id) else COC.Orders:Decline(o) end
        PW:RefreshOrders(); if COC.UI then COC.UI:Refresh() end
    end)
    card.whisper:Show()
    card.whisper:SetScript("OnClick", function() if ChatFrame_SendTell then ChatFrame_SendTell(o.buyer) end end)
    card.invite:SetScript("OnClick", function() if InviteUnit and o.buyer then InviteUnit(o.buyer) end end)
    card:SetScript("OnMouseUp", function(_, btn)
        if btn ~= "RightButton" then return end
        if IsShiftKeyDown and IsShiftKeyDown() and o.buyer and COC.Moderation then
            COC.Moderation:Mute(o.buyer)   -- shift-clic-droit = muter l'auteur (clic-droit simple = masquer l'ordre)
        elseif kind == "inbound" then COC.Inbound:Dismiss(o.id)
        else COC.db.muted = COC.db.muted or {}; COC.db.muted[o.id] = true end
        PW:RefreshOrders()
    end)
end

-- Remplit le panneau « composants » : pour chaque réactif du plan, coche verte si l'acheteur le
-- fournit, sinon « À FOURNIR » rouge (l'artisan doit aller le récolter). Renvoie la hauteur du
-- panneau (0 = plan inconnu → carte compacte).
function PW:_FillReagPanel(card, o)
    local list, nProv, total = self:_OrderReagents(o)
    local p = card.reagPanel
    if not list then p:Hide(); return 0 end
    local c = CL()
    local tail = (nProv == total) and (" |cFF33DD33— " .. L["complet"] .. "|r") or ""
    p.hdr:SetText(string.format("|cFFE8B84B%s|r  |cFF999999%d/%d|r%s", L["COMPOSANTS FOURNIS"], nProv, total, tail))
    local n = math.min(#list, MAX_REAG)
    for j = 1, n do
        local row, rg = p.rows[j], list[j]
        local iid, need, prov = rg[1], rg[2], rg[3]
        local nm = (c and c:ItemName(iid)) or ("item:" .. iid)
        local cr, cg, cb = Skin.RarityColor(iid)
        row.name:SetText(nm:match("^item:") and L["Chargement…"] or nm); row.name:SetTextColor(cr, cg, cb)
        row.mark:SetTexture(prov and Skin.tex.checkMark or Skin.tex.checkBox)
        row.info:SetText(prov and ("|cFF999999×" .. need .. "|r")
            or ("|cFFCCCCCC×" .. need .. "|r  |cFFFF6060" .. L["À FOURNIR"] .. "|r"))
        row:Show()
    end
    for j = n + 1, MAX_REAG do p.rows[j]:Hide() end
    if p.share then
        p.share:SetScript("OnClick", function()
            local items = {}   -- seulement « À FOURNIR » (compos NON fournis par l'acheteur) = la vraie liste de courses
            for _, rg in ipairs(list) do if not rg[3] then items[#items + 1] = { id = rg[1], qty = rg[2] } end end
            if COC.ShareReagents then COC.ShareReagents:Open(PW:_OrderItemName(o, c), items) end
        end)
    end
    local h = PANEL_HDR + n * REAG_RH + 6
    p:SetHeight(h); p:Show()
    return h
end

-- « Dois-je accepter ? » — les deux repères Lazy Gold : Valeur HV de la marchandise (× qté) et
-- Réactifs À MA CHARGE (coût HV des composants NON fournis). PAS de « profit net » : o.price est du
-- TEXTE LIBRE (« 15po », « 2 stacks de fer »…), le parser serait un devin — l'artisan compare lui-même
-- le prix proposé à ces repères. Renvoie la hauteur consommée (0 = rien).
function PW:_FillOrderProfit(card, o, hasPanel)
    local LG = COC.LazyGold
    if not (LG and LG:IsAvailable() and hasPanel) then card.lgLine:Hide(); return 0 end
    local list = self:_OrderReagents(o)
    local mine = 0
    for _, rg in ipairs(list or {}) do
        if not rg[3] then mine = mine + (LG:ItemValue(rg[1]) or 0) * (rg[2] or 1) end   -- non fourni = à moi
    end
    local val = (LG:ItemValue(o.itemID) or 0) * (o.qty or 1)
    if val <= 0 and mine <= 0 then card.lgLine:Hide(); return 0 end
    local parts = {}
    if val > 0 then parts[#parts + 1] = "|cFFE8B84B" .. L["Valeur HV"] .. ":|r " .. GetCoinTextureString(val) end
    if mine > 0 then parts[#parts + 1] = "|cFFE8B84B" .. L["À ma charge"] .. ":|r " .. GetCoinTextureString(mine) end
    card.lgLine:SetText(table.concat(parts, "   ")); card.lgLine:Show()
    return 16
end

function PW:_FillCard(card, it)
    local o, kind = it.o, it.kind; local c = CL()
    local nm = self:_OrderItemName(o, c)
    local rr, gg, bb = Skin.RarityColor(o.itemID)
    card.tipItemID = o.itemID
    card.badge:Paint(rr, gg, bb, Skin.FirstChar(nm), Skin.Icon(o.itemID, o.spellID) or Skin.tex.unknown)
    local able = PW.CanFulfill(o)
    local mk = (able == true) and ("|T" .. Skin.tex.ok .. ":12|t ") or (able == false) and ("|T" .. Skin.tex.fail .. ":12|t ") or ""
    card.item:SetText(mk .. ((nm:match("^item:") and L["Chargement…"]) or nm)); card.item:SetTextColor(rr, gg, bb)
    local rel = self:_OrdRelation(o.buyer) or "recent"
    local online = COC.Directory and COC.Directory.online and COC.Directory.online[o.buyer]
    card.dot:SetOnline(online and true or false)
    card.invite:SetShown(online and true or false)   -- inviter en groupe seulement si l'acheteur est en ligne
    local tag = (kind == "inbound") and (" |T" .. Skin.tex.dotYellow .. ":10|t") or ""
    card.who:SetText("|c" .. (PW.ORD_REL_COL[rel] or "FFFFFFFF") .. (o.buyer or "?") .. "|r" .. tag)
    card.age:SetText("|cFF777777" .. self:_Age(o.ts) .. "|r")
    local qty = Skin.QtyText(o)
    local price = o.price and ("|cFFFFDD00" .. o.price .. "|r") or ("|cFF888888" .. L["Don / gratuit"] .. "|r")
    card.price:SetText("|cFFCCCCCC" .. qty .. "|r  " .. price)
    local panelH = self:_FillReagPanel(card, o)
    local lgH    = self:_FillOrderProfit(card, o, panelH > 0)
    -- Hauteur = zones fixes (SPEC) + corps mesuré : 26 = rangée objet ; +4 = respiration sous le
    -- panneau composants. Le pied reste ancré en bas par construction (flex de la mini-SPEC).
    local bodyH = (panelH > 0) and (26 + panelH + lgH + 4) or 26
    card:SetHeight(CARD_HDR + bodyH + CARD_FOOT)
    self:_CardActions(card, it)
    card:Show()
end

-- Rend la vue SÉLECTIONNÉE : la carte complète remplit la colonne (au moins le viewport ; plus si
-- le panneau composants déborde → le scroll reprend). Croix de l'en-tête = retour liste.
function PW:_RenderOrdSelected(it)
    for _, r in ipairs(self.ordRows) do r:Hide() end
    for i = 2, #self.ordCards do self.ordCards[i]:Hide() end
    local card = self:_OrdCard(1); self:_FillCard(card, it)
    card:ClearAllPoints(); card:SetPoint("TOPLEFT", 0, 0)
    local vh = self.ordScroll and self.ordScroll:GetHeight() or 0
    if card:GetHeight() < vh then card:SetHeight(vh) end
    self.ordContent:SetHeight(card:GetHeight())
end
