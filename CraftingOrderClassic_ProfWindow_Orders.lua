-- CraftingOrderClassic_ProfWindow_Orders.lua — colonne « Commandes » de la vue métier (cabine de
-- l'artisan). DEUX vues : LISTE (une ligne par commande : demandeur + prix + âge, sans bouton ;
-- une ligne sourdine cliquée se réaffiche) et SÉLECTIONNÉE (clic sur une ligne → la carte complète
-- remplit la colonne : composants fournis, repères Lazy Gold, ACCEPTER / REFUSER / CHUCHOTER ;
-- croix en haut à droite = retour liste). Onglets de relation (Tous / Guilde / Amis / Annuaire) au
-- header. Inclut les demandes captées (/commerce, /guilde). Sorti de _ProfWindow.lua (anti-monolithe).

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L
local PW   = COC.ProfWindow

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

local CARD_W     = 280
local ROW_H      = 22        -- ligne de la vue LISTE (une commande = une ligne)
local REAG_RH    = 50      -- hauteur d'une ligne de réactif dans le panneau « composants »
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
local REL = {
    { id = "all",    label = L["Tous"]    },
    { id = "guild",  label = L["Guilde"]  },
    { id = "friend", label = L["Amis"]    },
    { id = "recent", label = L["Annuaire"] },
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

-- spellID du plan derrière une commande : direct (poste local), ou résolu depuis l'objet produit
-- (vue artisan d'une commande REÇUE, qui n'a que itemID) → les composants s'affichent quand même.
local function orderSpellID(o)
    if o.spellID then return o.spellID end
    local c = CL()
    if o.itemID and o.profession and c and c.ItemToSpell then
        local i2s = c:ItemToSpell(o.profession); return i2s and i2s[o.itemID]
    end
end

-- Composants du plan : liste { {itemID, needTotal, fourni}, ... } + (nbFournis, total). needTotal =
-- qté/craft × qté commandée ; fourni = l'acheteur a coché « je fournis ». nil si plan inconnu.
local function orderReagents(o)
    local c, sid = CL(), orderSpellID(o)
    local reag = c and sid and c:RecipeReagents(o.profession, sid)
    if not (reag and #reag > 0) then return nil, 0, 0 end
    local prov = {}; for _, id in ipairs(o.provided or {}) do prov[id] = true end
    local out, mult, nProv = {}, o.qty or 1, 0
    for _, rg in ipairs(reag) do
        local p = prov[rg[1]] and true or false
        if p then nProv = nProv + 1 end
        out[#out + 1] = { rg[1], (rg[2] or 1) * mult, p }
    end
    return out, nProv, #reag
end

-- Nom lisible du PRODUIT d'une commande (repli « item:ID » tant que le client charge l'objet).
local function orderItemName(o, c)
    return (c and c:ItemName(o.itemID, o.itemName))
        or (o.spellID and c and c:RecipeName(o.spellID))
        or ("item:" .. (o.itemID or 0))
end

-- ------------------------------------------------------------------
-- Construction (onglets de relation + en-tête + scroll de cartes)
-- ------------------------------------------------------------------
-- Onglets de RELATION (Tous / Guilde / Amis / Annuaire) : languettes NATIVES (MakeTabs — le rendu
-- du volet Amis), posées au niveau du header AU-DESSUS de la colonne Commandes ; la SPEC lui réserve
-- la bande dessous (orders.top, cf. _ProfWindow_Layout.lua). Parentés à la FENÊTRE, pas à la
-- colonne : ils survivent au re-parentage compact/dock, seul leur X change (_PlaceOrdTabs).
function PW:_BuildRelTabs()
    self.ordRelTabs = Skin.MakeTabs(self.frame, REL, function(id)
        PW.ordRelTab = id; PW:_RefreshRelTabs(); PW:RefreshOrders()
    end)
    self:_PlaceOrdTabs(self._compact)
end

-- Vue pleine : au-dessus de la colonne Commandes (4 = offset du panneau de sections dans la fenêtre,
-- ORD_X = frontière détail|commandes). Compact/dock (fenêtre 300 px) : bord gauche. −62 = 2 px sous
-- le sommet du marbre (même placement que les onglets de la fenêtre principale).
function PW:_PlaceOrdTabs(compact)
    local first = self.ordRelTabs and self.ordRelTabs.buttons[REL[1].id]
    if not first then return end
    first:ClearAllPoints()
    first:SetPoint("TOPLEFT", self.frame, "TOPLEFT", compact and 10 or (4 + PW.ORD_X + 8), -28)
end

-- Zones SPEC de la colonne (cf. _ProfWindow_Layout.lua) : ordBody (en-tête + scroll liste/carte) /
-- ordFoot (bande pied : récap par statut). Les zones sont ENFANTS de la zone « orders » → elles
-- suivent le re-parentage compact/dock sans rien faire.
function PW:_BuildOrders(col)
    self.ordRelTab = self.ordRelTab or "all"
    self:_BuildRelTabs()
    self:_RefreshRelTabs()
    local bz = self:Sec("ordBody") or col
    local hdr = bz:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr:SetPoint("TOPLEFT", 8, -6); hdr:SetText("|cFFE8B84B" .. L["Commandes"] .. "|r"); self.ordHdr = hdr
    local scroll = CreateFrame("ScrollFrame", "CraftingOrderProfWinOrdScroll", bz, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 6, -26); scroll:SetPoint("BOTTOMRIGHT", -24, 0)
    local content = CreateFrame("Frame", nil, scroll); content:SetSize(CARD_W, 10); scroll:SetScrollChild(content)
    self.ordScroll, self.ordContent = scroll, content
    self.ordCards, self.ordRows = {}, {}
    -- Pied de colonne : récap par statut (en attente · acceptées · sourdine), filtré métier+relation.
    local fz = self:Sec("ordFoot") or col
    local foot = fz:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    foot:SetPoint("LEFT", 8, 0); foot:SetPoint("RIGHT", -8, 0)
    foot:SetJustifyH("CENTER"); Skin.ApplyShadow(foot); self.ordFoot = foot
end

function PW:_RefreshRelTabs()
    if self.ordRelTabs then self.ordRelTabs:Select(self.ordRelTab or "all") end
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
-- Panneau « composants » de la carte : en-tête X/Y + pool de lignes réactif (coche fournie / À FOURNIR).
-- Hauteur ajustée au remplissage (cf. _FillReagPanel) ; masqué quand le plan est inconnu.
-- `bz` = zone CORPS de la carte (le panneau vit sous la rangée objet/prix, à −26).
local function buildReagPanel(c, bz)
    local p = CreateFrame("Frame", nil, bz, "BackdropTemplate")
    p:SetPoint("TOPLEFT", 8, -26); p:SetPoint("RIGHT", bz, "RIGHT", -8, 0); Skin.SkinWell(p)
    p.hdr = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    p.hdr:SetPoint("TOPLEFT", 6, -3); p.hdr:SetPoint("RIGHT", -6, 0); p.hdr:SetJustifyH("LEFT"); Skin.ApplyShadow(p.hdr)
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
    local list, nProv, total = orderReagents(o)
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
    local list = orderReagents(o)
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

-- ------------------------------------------------------------------
-- Vue LISTE : une commande = une ligne (pastille + demandeur | prix | âge), SANS bouton — le clic
-- SÉLECTIONNE (la carte complète remplit alors la colonne). Une commande en sourdine s'affiche en
-- ligne grisée « Réafficher » : la cliquer la sort de la sourdine (remplace l'ancien bouton).
-- ------------------------------------------------------------------
function PW:_OrdRow(i)
    local r = self.ordRows[i]; if r then return r end
    r = CreateFrame("Button", nil, self.ordContent)
    r:SetHeight(ROW_H)
    Skin.PersonHighlight(r)
    r.dot = Skin.MakeStatusIcon(r, 10); r.dot:SetPoint("LEFT", 4, 0)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.name:SetPoint("LEFT", r.dot, "RIGHT", 4, 0); r.name:SetJustifyH("LEFT")
    r.name:SetWordWrap(false); Skin.ApplyShadow(r.name)
    -- Item VOULU : badge + nom à la suite du demandeur ; survol = tooltip de l'objet (WireItemTooltip).
    r.badge = Skin.MakeBadge(r, 14); r.badge:SetPoint("LEFT", r.name, "RIGHT", 6, 0)
    r.item = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.item:SetPoint("LEFT", r.badge, "RIGHT", 3, 0); r.item:SetJustifyH("LEFT")
    r.item:SetWordWrap(false); Skin.ApplyShadow(r.item)
    r.age = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.age:SetPoint("RIGHT", -4, 0); Skin.ApplyShadow(r.age)
    r.money = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.money:SetPoint("RIGHT", r.age, "LEFT", -8, 0); Skin.ApplyShadow(r.money)
    r.item:SetPoint("RIGHT", r.money, "LEFT", -6, 0)   -- l'item se rétrécit avant le prix
    r:SetScript("OnClick", function(b)
        local it = b.it; if not it then return end
        if it.muted then
            if COC.db and COC.db.muted then COC.db.muted[it.o.id] = nil end
        else
            PW.ordSelected = it.o.id
        end
        PW:RefreshOrders()
    end)
    Skin.WireItemTooltip(r)   -- survol → tooltip de l'objet (lit r.tipItemID / r.tipSpellID)
    self.ordRows[i] = r; return r
end

function PW:_FillOrdRow(row, it)
    local o = it.o; local c = CL()
    row.it = it
    local online = COC.Directory and COC.Directory.online and COC.Directory.online[o.buyer]
    row.dot:SetOnline(online and true or false)
    if it.muted then
        row.name:SetText("|cFF777777" .. (o.buyer or "?") .. " — " .. L["Sourdine"] .. "|r")
        row.money:SetText("|cFF888888" .. L["Réafficher"] .. "|r")
        row.age:SetText("")
        row.badge:Hide(); row.item:Hide()
        row.tipItemID, row.tipSpellID = nil, nil   -- pas de tooltip sur une ligne repliée
        row:Show(); return
    end
    local rel = relationOf(o.buyer) or "recent"
    local tag = (it.kind == "inbound") and (" |T" .. Skin.tex.dotYellow .. ":10|t") or ""
    row.name:SetText("|c" .. (REL_COL[rel] or "FFFFFFFF") .. (o.buyer or "?") .. "|r" .. tag)
    local nm = orderItemName(o, c)
    local rr, gg, bb = Skin.RarityColor(o.itemID)
    row.badge:Paint(rr, gg, bb, Skin.FirstChar(nm), Skin.Icon(o.itemID, o.spellID) or Skin.tex.unknown)
    row.badge:Show()
    row.item:SetText(nm:match("^item:") and L["Chargement…"] or nm); row.item:SetTextColor(rr, gg, bb)
    row.item:Show()
    row.tipItemID, row.tipSpellID = o.itemID, o.spellID
    local price = o.price and ("|cFFFFDD00" .. o.price .. "|r") or ("|cFF888888" .. L["Don / gratuit"] .. "|r")
    row.money:SetText("|cFFCCCCCC" .. Skin.QtyText(o) .. "|r  " .. price)
    row.age:SetText("|cFF777777" .. self:_Age(o.ts) .. "|r")
    row:Show()
end

function PW:_FillCard(card, it)
    local o, kind = it.o, it.kind; local c = CL()
    local nm = orderItemName(o, c)
    local rr, gg, bb = Skin.RarityColor(o.itemID)
    card.tipItemID = o.itemID
    card.badge:Paint(rr, gg, bb, Skin.FirstChar(nm), Skin.Icon(o.itemID, o.spellID) or Skin.tex.unknown)
    local able = PW.CanFulfill(o)
    local mk = (able == true) and ("|T" .. Skin.tex.ok .. ":12|t ") or (able == false) and ("|T" .. Skin.tex.fail .. ":12|t ") or ""
    card.item:SetText(mk .. ((nm:match("^item:") and L["Chargement…"]) or nm)); card.item:SetTextColor(rr, gg, bb)
    local rel = relationOf(o.buyer) or "recent"
    local online = COC.Directory and COC.Directory.online and COC.Directory.online[o.buyer]
    card.dot:SetOnline(online and true or false)
    card.invite:SetShown(online and true or false)   -- inviter en groupe seulement si l'acheteur est en ligne
    local tag = (kind == "inbound") and (" |T" .. Skin.tex.dotYellow .. ":10|t") or ""
    card.who:SetText("|c" .. (REL_COL[rel] or "FFFFFFFF") .. (o.buyer or "?") .. "|r" .. tag)
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

-- ------------------------------------------------------------------
-- Rafraîchissement : collecte (carnet + entrantes) filtrée par métier ouvert + relation.
-- ------------------------------------------------------------------
-- Collecte les commandes du métier : visibles triées récentes d'abord, puis les sourdines repliées
-- en bas. Renvoie (liste, en attente, acceptées, nb sourdines).
function PW:_CollectOrders()
    local prof, relTab = self.profKey, self.ordRelTab or "all"
    local muted = (COC.db and COC.db.muted) or {}
    local O, Mod, now = COC.Orders, COC.Moderation, time()
    local ttl = (O and O.ORDER_TTL) or (6 * 3600)
    local function keep(name) return relTab == "all" or relationOf(name) == relTab end
    -- La vue métier appliquait le seul filtre de RELATION : elle montrait donc aussi les commandes NOMMÉES
    -- pour un TIERS (fuite d'info sur une commande privée) et les commandes OUVERTES expirées. On applique
    -- ici les MÊMES règles que le Carnet (Orders:All) : routage VisibleTo + TTL.
    local function shown(o)
        if O and O.VisibleTo and not O:VisibleTo(o) then return false end
        return not (o.status == "open" and (now - (o.ts or now)) > ttl)
    end
    -- Sourdine : par ID d'ordre (db.muted) OU par JOUEUR (Moderation) — un acheteur muté ne doit pas
    -- continuer à remplir la vue métier. Les deux sont repliés en bas, pas supprimés.
    local function isMuted(o)
        return (muted[o.id] or (Mod and Mod.IsMuted and Mod:IsMuted(o.buyer))) and true or false
    end
    local list, mutedList, pending, accepted, mutedN = {}, {}, 0, 0, 0
    for _, o in pairs((COC.db and COC.db.orders) or {}) do
        if o.profession == prof and o.status ~= "cancelled" and o.status ~= "done"
           and keep(o.buyer) and shown(o) then
            if isMuted(o) then
                mutedN = mutedN + 1
                mutedList[#mutedList + 1] = { o = o, kind = "order", muted = true }
            else
                list[#list + 1] = { o = o, kind = "order" }
                if o.status == "open" then pending = pending + 1
                elseif o.status == "accepted" then accepted = accepted + 1 end
            end
        end
    end
    for _, e in pairs((COC.db and COC.db.inbound) or {}) do
        if e.profession == prof and e.status ~= "dismissed" and keep(e.buyer) then
            list[#list + 1] = { o = e, kind = "inbound" }; pending = pending + 1
        end
    end
    table.sort(list, function(a, b) return (a.o.ts or 0) > (b.o.ts or 0) end)
    table.sort(mutedList, function(a, b) return (a.o.ts or 0) > (b.o.ts or 0) end)
    -- Visibles d'abord, puis les commandes en sourdine repliées en bas (cf. mockup Vue Métier).
    for _, it in ipairs(mutedList) do list[#list + 1] = it end
    return list, pending, accepted, mutedN
end

function PW:RefreshOrders()
    if not self.ordContent then return end
    local list, pending, accepted, mutedN = self:_CollectOrders()
    -- La largeur de contenu suit le viewport (mode compact plus étroit → les lignes suivent).
    local sw = self.ordScroll and self.ordScroll:GetWidth() or 0
    if sw > 0 then self.ordContent:SetWidth(sw) end
    -- Vue SÉLECTIONNÉE si la commande cliquée est toujours visible (mutée/expirée/refusée → liste).
    local sel
    if self.ordSelected then
        for _, it in ipairs(list) do
            if not it.muted and it.o.id == self.ordSelected then sel = it; break end
        end
        if not sel then self.ordSelected = nil end
    end
    if sel then self:_RenderOrdSelected(sel) else self:_RenderOrdList(list) end
    Skin.AutoHideScroll("CraftingOrderProfWinOrdScroll", self.ordContent)
    self.ordHdr:SetText("|cFFE8B84B" .. L["Commandes"] .. "|r |cFF888888(" .. #list .. ")|r")
    if self.ordFoot then
        self.ordFoot:SetText(string.format("|cFFFFCC00%d|r %s · |cFF33CCFF%d|r %s · |cFF888888%d|r %s",
            pending, L["en attente"], accepted, L["acceptées"], mutedN, L["en sourdine"]))
    end
end

-- Rend la vue LISTE : une ligne par commande, pleine largeur, hauteur fixe.
function PW:_RenderOrdList(list)
    for _, c in ipairs(self.ordCards) do c:Hide() end
    local n = 0
    for _, it in ipairs(list) do
        n = n + 1
        local row = self:_OrdRow(n); self:_FillOrdRow(row, it)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -(n - 1) * ROW_H)
        row:SetPoint("RIGHT", self.ordContent, "RIGHT", 0, 0)
    end
    for i = n + 1, #self.ordRows do self.ordRows[i]:Hide() end
    self.ordContent:SetHeight(math.max(n * ROW_H, 10))
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
