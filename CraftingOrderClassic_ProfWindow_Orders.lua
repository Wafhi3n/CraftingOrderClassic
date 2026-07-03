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

local CARD_W       = 232
local CARD_COMPACT = 84      -- carte sans plan connu (objet seul / récolte) : hauteur fixe
local CARD_MUTED   = 22      -- ligne repliée d'une commande en sourdine (label + bouton Réafficher)
local REAG_RH      = 14      -- hauteur d'une ligne de réactif dans le panneau « composants »
local MAX_REAG     = 8       -- plafond d'affichage (au-delà : tronqué ; rare en Classic)
local PANEL_HDR    = 16      -- hauteur de l'en-tête du panneau « COMPOSANTS FOURNIS »
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
    scroll:SetPoint("TOPLEFT", 6, -48); scroll:SetPoint("BOTTOMRIGHT", -24, 22)   -- 22 px : place pour le pied
    local content = CreateFrame("Frame", nil, scroll); content:SetSize(CARD_W, 10); scroll:SetScrollChild(content)
    self.ordContent = content; self.ordCards = {}
    -- Pied de colonne : récap par statut (en attente · acceptées · sourdine), filtré métier+relation.
    local foot = col:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    foot:SetPoint("BOTTOMLEFT", 8, 6); foot:SetPoint("BOTTOMRIGHT", -8, 6)
    foot:SetJustifyH("CENTER"); Skin.ApplyShadow(foot); self.ordFoot = foot
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
-- Panneau « composants » de la carte : en-tête X/Y + pool de lignes réactif (coche fournie / À FOURNIR).
-- Hauteur ajustée au remplissage (cf. _FillReagPanel) ; masqué quand le plan est inconnu.
local function buildReagPanel(c)
    local p = CreateFrame("Frame", nil, c, "BackdropTemplate")
    p:SetPoint("TOPLEFT", 8, -44); p:SetPoint("RIGHT", c, "RIGHT", -8, 0); Skin.SkinWell(p)
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

function PW:_OrdCard(i)
    local c = self.ordCards[i]; if c then return c end
    c = CreateFrame("Frame", nil, self.ordContent, "BackdropTemplate")
    c:SetSize(CARD_W, CARD_COMPACT); c:SetPoint("TOPLEFT", 0, 0); Skin.SkinWell(c)
    c.dot = Skin.MakeStatusIcon(c, 12); c.dot:SetPoint("TOPLEFT", 8, -7)
    c.who = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    c.who:SetPoint("LEFT", c.dot, "RIGHT", 4, 0); Skin.ApplyShadow(c.who)
    -- Bouton « Inviter en groupe » (coin haut-droit ; visible si l'acheteur est en ligne) → l'artisan
    -- l'invite pour lui remettre les composants / la marchandise via l'échange.
    c.invite = CreateFrame("Button", nil, c)
    c.invite:SetSize(16, 16); c.invite:SetPoint("TOPRIGHT", -8, -6)
    c.invite:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
    c.invite:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-Down")
    c.invite:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
    c.invite:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_RIGHT"); GameTooltip:SetText(L["Inviter en groupe"], 1, 1, 1); GameTooltip:Show()
    end)
    c.invite:SetScript("OnLeave", GameTooltip_Hide)
    c.age = c:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    c.age:SetPoint("TOPRIGHT", c.invite, "TOPLEFT", -4, 0); Skin.ApplyShadow(c.age)
    c.badge = Skin.MakeBadge(c, 16); c.badge:SetPoint("TOPLEFT", 8, -25)
    c.item = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    c.item:SetPoint("LEFT", c.badge, "RIGHT", 4, 0); c.item:SetWidth(140); c.item:SetJustifyH("LEFT"); Skin.ApplyShadow(c.item)
    c.price = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    c.price:SetPoint("TOPRIGHT", -8, -27); Skin.ApplyShadow(c.price)
    buildReagPanel(c)
    -- 3 boutons compacts (≈208 px) qui tiennent dans la largeur VISIBLE de la colonne (scroll ~222 px) :
    -- Accepter / Refuser / Chuchoter, ancrés en chaîne (Refuser caché → Chuchoter glisse à gauche).
    c.act = Skin.MakeGoldButton(c, 66, 18, L["Accepter"]); c.act:SetPoint("BOTTOMLEFT", 8, 6)
    c.refuse = Skin.MakeGoldButton(c, 54, 18, L["Refuser"]); c.refuse:SetPoint("LEFT", c.act, "RIGHT", 4, 0)
    c.whisper = Skin.MakeGoldButton(c, 72, 18, L["Chuchoter"]); c.whisper:SetPoint("LEFT", c.refuse, "RIGHT", 4, 0)
    -- Ligne repliée (commande en sourdine) : label + demandeur/objet + bouton « Réafficher ». Occupe
    -- la carte entière (pool réutilisé) quand la commande est masquée ; cf. _FillCard branche muted.
    c.mutedLabel = c:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    c.mutedLabel:SetPoint("LEFT", 8, 0); Skin.ApplyShadow(c.mutedLabel)
    c.mutedLabel:SetText(L["Sourdine"]); c.mutedLabel:Hide()
    c.mutedText = c:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    c.mutedText:SetPoint("LEFT", c.mutedLabel, "RIGHT", 6, 0); c.mutedText:SetJustifyH("LEFT")
    c.mutedText:SetWordWrap(false); Skin.ApplyShadow(c.mutedText); c.mutedText:Hide()
    c.unmute = Skin.MakeGoldButton(c, 72, 18, L["Réafficher"]); c.unmute:SetPoint("RIGHT", -6, 0); c.unmute:Hide()
    c.mutedText:SetPoint("RIGHT", c.unmute, "LEFT", -6, 0)
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

-- Ligne repliée d'une commande en sourdine : masque tout le contenu normal de la carte, affiche
-- juste le demandeur/objet et un bouton pour la réafficher (retire l'id de COC.db.muted).
function PW:_FillMutedRow(card, it)
    local o = it.o; local c = CL()
    local nm = (c and c:ItemName(o.itemID)) or (o.spellID and c and c:RecipeName(o.spellID)) or ("item:" .. (o.itemID or 0))
    card.dot:Hide(); card.invite:Hide(); card.age:Hide(); card.badge:Hide(); card.item:Hide(); card.price:Hide()
    card.reagPanel:Hide(); card.act:Hide(); card.refuse:Hide(); card.whisper:Hide(); card.who:Hide()
    card.mutedLabel:Show(); card.mutedText:Show(); card.unmute:Show()
    card.mutedText:SetText("|cFF999999" .. (o.buyer or "?") .. " — " .. (nm:match("^item:") and L["Chargement…"] or nm) .. "|r")
    card.unmute:SetScript("OnClick", function()
        if COC.db and COC.db.muted then COC.db.muted[o.id] = nil end
        PW:RefreshOrders()
    end)
    card:SetHeight(CARD_MUTED); card:Show()
end

function PW:_FillCard(card, it)
    if it.muted then self:_FillMutedRow(card, it); return end
    card.mutedLabel:Hide(); card.mutedText:Hide(); card.unmute:Hide()
    card.dot:Show(); card.badge:Show(); card.item:Show(); card.price:Show(); card.who:Show(); card.age:Show()
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
    card.invite:SetShown(online and true or false)   -- inviter en groupe seulement si l'acheteur est en ligne
    local tag = (kind == "inbound") and (" |T" .. Skin.tex.dotYellow .. ":10|t") or ""
    card.who:SetText("|c" .. (REL_COL[rel] or "FFFFFFFF") .. (o.buyer or "?") .. "|r" .. tag)
    card.age:SetText("|cFF777777" .. self:_Age(o.ts) .. "|r")
    local qty = Skin.QtyText(o)
    local price = o.price and ("|cFFFFDD00" .. o.price .. "|r") or ("|cFF888888" .. L["Don / gratuit"] .. "|r")
    card.price:SetText("|cFFCCCCCC" .. qty .. "|r  " .. price)
    local panelH = self:_FillReagPanel(card, o)
    card:SetHeight((panelH > 0) and (72 + panelH) or CARD_COMPACT)   -- 72 = haut + rangée d'actions
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
    local list, mutedList, pending, accepted, mutedN = {}, {}, 0, 0, 0
    for _, o in pairs((COC.db and COC.db.orders) or {}) do
        if o.profession == prof and o.status ~= "cancelled" and o.status ~= "done" and keep(o.buyer) then
            if muted[o.id] then
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
    local n, y = 0, 0   -- cartes à hauteur variable (panneau composants) → empilage cumulatif
    for _, it in ipairs(list) do
        n = n + 1
        local card = self:_OrdCard(n); self:_FillCard(card, it)
        card:ClearAllPoints(); card:SetPoint("TOPLEFT", 0, -y)
        y = y + card:GetHeight() + 4
    end
    for i = n + 1, #self.ordCards do self.ordCards[i]:Hide() end
    self.ordContent:SetHeight(math.max(y, 10))
    Skin.AutoHideScroll("CraftingOrderProfWinOrdScroll", self.ordContent)
    self.ordHdr:SetText("|cFFE8B84B" .. L["Commandes"] .. "|r |cFF888888(" .. n .. ")|r")
    if self.ordFoot then
        self.ordFoot:SetText(string.format("|cFFFFCC00%d|r %s · |cFF33CCFF%d|r %s · |cFF888888%d|r %s",
            pending, L["en attente"], accepted, L["acceptées"], mutedN, L["en sourdine"]))
    end
end
