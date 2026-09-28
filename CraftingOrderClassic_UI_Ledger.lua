-- CraftingOrderClassic_UI_Ledger.lua — onglet CARNET : MES commandes, en table (Commande · Qté · Prix ·
-- Métier · Artisan · Statut), filtres En cours / Archivées / Confiées, colonnes TRIABLES au clic sur
-- l'en-tête (palier 5 de la revue d'interface, calqué sur « Mes commandes » des Commandes
-- d'artisanat ; en-tête : Skin.MakeSortHeader). Sorti de _UI.lua au palier 5, qui touchait le
-- plafond des 500 lignes ; la fenêtre (_UI.lua) l'appelle par BuildOrdersTab / RefreshOrders.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local function me() return COC.Api.PlayerName() end   -- nom RÉSEAU (« Prénom Nom » sur Forever)

local ROW_T = 30
local COL = { name = 8, qty = 320, price = 372, prof = 500, dest = 612, status = 716 }

-- Carnet = MES commandes. Commande REMISE par le crafteur → bouton « J'ai reçu » (confirme la
-- réception → terminée + crédite le crafteur). Sinon, tant qu'ouverte/acceptée → annuler. Accepter/
-- livrer une commande d'AUTRUI se fait dans la vue métier (Orders:ProfRowAction).
local function orderActionFor(o)
    if o.buyer == me() and o.status == "delivered" then
        return L["J'ai reçu"], function() COC.Orders:Confirm(o.id) end
    end
    if o.buyer == me() and o.status ~= "done" and o.status ~= "cancelled" then
        return L["Annuler"], function() COC.Orders:Cancel(o.id) end
    end
    return nil
end

-- Une commande est « passée » (archivée) si livrée ou annulée → hors du tableau actif.
local function isPastOrder(o) return o.status == "done" or o.status == "cancelled" end

-- ------------------------------------------------------------------ tri
-- Clé de tri d'une ligne par colonne. Une ligne = { o = commande } ou { h = remise } (Confiées) : les
-- deux vues partagent l'en-tête, chaque clé sait lire les deux.
local SORT = {
    name   = function(it) return ((it.o and COC.Orders:OrderName(it.o)) or (it.h and it.h.name) or ""):lower() end,
    qty    = function(it) return tonumber((it.o or it.h).qty) or 1 end,
    price  = function(it) return Skin.PriceCopper((it.o or it.h).price) end,
    prof   = function(it) return Skin.ProfLabel((it.o or it.h).profession) or "" end,
    dest   = function(it) return (it.h and it.h.target) or it.o.acceptedBy or it.o.recipient or "" end,
    status = function(it)
        if it.h then return it.h.delivered and "1" or "0" end
        return (Skin.StatusInfo(it.o.status)) or ""
    end,
}

-- Colonne choisie (croissant ou décroissant), puis la plus récente d'abord : l'ordre par défaut du
-- Carnet, qui départage aussi les égalités.
local function sortItems(items, st)
    local key = st and SORT[st.key]
    table.sort(items, function(a, b)
        if key then
            local va, vb = key(a), key(b)
            if va ~= vb then if st.asc then return va < vb else return va > vb end end
        end
        return ((a.o or a.h).ts or 0) > ((b.o or b.h).ts or 0)
    end)
end

-- Clic sur un en-tête : la même colonne inverse le sens, une autre colonne trie en croissant (comme
-- « Mes commandes »). Un nouveau tri repart du haut de la liste.
function UI:_SortOrders(id)
    local st = self.ordersSort or {}
    if st.key == id then st.asc = not st.asc else st.key, st.asc = id, true end
    self.ordersSort = st
    if self.ordersHeader then self.ordersHeader:SetSort(st.key, st.asc) end
    self._ordersFor = nil
    self:RefreshOrders()
end

-- ------------------------------------------------------------------ construction
function UI:BuildOrdersTab(f)
    local panel = CreateFrame("Frame", nil, f); UI.insetPanel(panel, f); self.ordersPanel = panel

    -- Carnet = MES commandes : En cours (ouvertes/acceptées) / Archivées (livrées/annulées) / Confiées.
    -- Trois VUES EXCLUSIVES du même carnet (une valeur parmi N), pas trois actions : le contrat du
    -- sélecteur gris de l'HdV (Skin.MakeDropdown). Entrantes (/commerce, /guilde) : dans la VUE MÉTIER.
    self.orderFilter = "active"
    local fdefs = {
        { value = "active",   text = L["En cours"] },
        { value = "archived", text = L["Archivées"] },
        { value = "handoff",  text = L["Confiées"] },
    }
    local dd = Skin.MakeDropdown("COCLedgerFilterDD", panel, 100, fdefs, {
        onSelect = function(v) UI.orderFilter = v; UI:RefreshOrders() end,
    })
    dd:SetPointVisual("TOPLEFT", panel, "TOPLEFT", 12, -72)
    self.orderFilterDD = dd
    self:_RefreshOrderFilterTabs()

    -- En-tête TRIABLE (palier 5), aligné sur les colonnes des lignes : le texte de chaque en-tête
    -- tombe au début de sa colonne (x = 12 + COL, 12 = la marge de la liste dans le panneau).
    local order = { "name", "qty", "price", "prof", "dest", "status" }
    local labels = { name = L["COMMANDE"], qty = L["QTÉ"], price = L["PRIX PROPOSÉ"], prof = L["MÉTIER"],
                     dest = L["ARTISAN"], status = L["STATUT"] }
    local defs = {}
    for i, id in ipairs(order) do
        local nextCol = order[i + 1] and COL[order[i + 1]]
        defs[i] = { id = id, label = labels[id], x = 12 + COL[id], w = nextCol and (nextCol - COL[id]) or 100 }
    end
    self.ordersHeader = Skin.MakeSortHeader(panel, -102, defs, function(id) UI:_SortOrders(id) end)
    Skin.PanelInset(panel, "list", 8, -98, -16, 18)   -- le tableau dans un encart de liste (palier 6)
    self.hdrDest = self.ordersHeader.buttons.dest

    -- La liste défilante du kit (palier 2c) ; sa barre se loge dans le bord droit, où était celle de
    -- l'ancien cadre. L'aide contextuelle (« i ») la pointe par UI.ordersHost.
    local host = CreateFrame("Frame", nil, panel)
    host:SetPoint("TOPLEFT", 12, -124); host:SetPoint("BOTTOMRIGHT", -20, 22)
    self.ordersHost = host
    self.orderList = Skin.MakeScrollList(host, {
        extent = ROW_T,
        build  = function(row) UI:_BuildOrderRow(row) end,
        fill   = function(row, it) UI:_FillOrderRow(row, it) end,
    })
end

-- Reflète l'état `orderFilter` dans le dropdown (libellé + coche). Nom conservé : ~2 appelants.
function UI:_RefreshOrderFilterTabs()
    if self.orderFilterDD then self.orderFilterDD:SetValue(self.orderFilter or "active") end
end

-- Construite une fois par cadre de la liste défilante. Colonnes à positions FIXES, alignées sur les
-- en-têtes ; une ligne chacune, tronquée par « … » au lieu de passer à la ligne.
function UI:_BuildOrderRow(row)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local hi = row:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints()
    hi:SetColorTexture(Skin.unpack(Skin.color.rowHover))
    row.badge = Skin.MakeBadge(row, 18); row.badge:SetPoint("LEFT", COL.name, 0)
    local function col(x, w)
        local fs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("LEFT", x, 0); fs:SetWidth(w); fs:SetJustifyH("LEFT"); fs:SetWordWrap(false)
        Skin.ApplyShadow(fs); return fs
    end
    row.name   = col(COL.name + 24, 284)
    row.qty    = col(COL.qty, 44)
    row.price  = col(COL.price, 120)
    row.prof   = col(COL.prof, 104)
    row.dest   = col(COL.dest, 96)
    row.status = col(COL.status, 80)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- ------------------------------------------------------------------ remplissage
function UI:RefreshOrders()
    if self.hdrDest then self.hdrDest:SetText(L["ARTISAN"]) end
    if self.orderFilter == "handoff" then return self:RefreshHandoff() end
    local archived, m = (self.orderFilter == "archived"), me()
    local items = {}
    for _, o in pairs((COC.db and COC.db.orders) or {}) do
        if o.buyer == m and archived == isPastOrder(o) then items[#items + 1] = { o = o } end
    end
    self:_SetOrderData(items, L["Aucune commande. Onglet « Commande » pour en poster une."])
end

-- Filtre « Confiées » : commandes (miennes + entrantes captées) qu'un artisan CONNU sait faire,
-- gardées pour lui. Une ligne par (commande, artisan) ; statut = Remis (poussé cette session) vs
-- En attente (il n'est pas encore repassé). Mêmes lignes que le Carnet (colonnes détournées).
function UI:RefreshHandoff()
    local items = {}
    for i, h in ipairs((COC.Handoff and COC.Handoff:Pending()) or {}) do items[i] = { h = h } end
    self:_SetOrderData(items, L["Aucune commande confiée pour l'instant."])
end

-- Trie (colonne choisie, puis la plus récente d'abord), puis remplit. Même filtre qu'au dernier
-- remplissage : la position est gardée ; un autre filtre, ou un autre tri, repart du haut. Le message
-- de liste vide dépend du filtre.
function UI:_SetOrderData(items, emptyText)
    if not self.orderList then return end
    sortItems(items, self.ordersSort)
    local same = (self._ordersFor == self.orderFilter)
    self._ordersFor = self.orderFilter
    self.orderList:SetEmpty(emptyText)
    self.orderList:SetData(items, same)
end

-- Une ligne pour `it` = { o = commande } (En cours / Archivées) ou { h = remise } (Confiées). Le cadre
-- sert tour à tour aux deux vues : tout est reposé, clic et survol compris.
function UI:_FillOrderRow(row, it)
    if it.h then return self:_FillHandoffRow(row, it.h) end
    local o = it.o
    local nm = COC.Orders:OrderName(o)
    local r, g, b = Skin.RarityColor(o.itemID)
    row.badge:Paint(r, g, b, Skin.FirstChar(nm), Skin.Icon(o.itemID, o.spellID)); row.badge:Show()
    row.name:SetText(nm); row.name:SetTextColor(r, g, b)
    row.qty:SetText("|cFFCCCCCC" .. Skin.QtyText(o) .. "|r")
    row.price:SetText(o.price and ("|c" .. Skin.hex.price .. o.price .. "|r") or "|cFF666666—|r")
    row.prof:SetText("|c" .. Skin.hex.gold .. Skin.ProfLabel(o.profession) .. "|r")
    row.dest:SetText(o.acceptedBy and ("|cFF33DD33" .. o.acceptedBy .. "|r")
        or ("|cFF888888" .. L[o.recipient or "Tous"] .. "|r"))
    local slabel, scol = Skin.StatusInfo(o.status)
    row.status:SetText("|c" .. scol .. slabel .. "|r")
    local label, fn = orderActionFor(o)
    row:SetScript("OnClick", label and function() fn(); UI:Refresh() end or nil)
    row:SetScript("OnEnter", label and function(rr)
        GameTooltip:SetOwner(rr, "ANCHOR_RIGHT"); GameTooltip:AddLine(L["Clic : "] .. label, 1, 1, 1); GameTooltip:Show()
    end or nil)
end

function UI:_FillHandoffRow(row, h)
    local r, g, b = Skin.RarityColor(h.itemID)
    row.badge:Paint(r, g, b, Skin.FirstChar(h.name or "?"), Skin.Icon(h.itemID, h.spellID)); row.badge:Show()
    row.name:SetText(h.name or "?"); row.name:SetTextColor(r, g, b)
    row.qty:SetText("|cFFCCCCCC" .. Skin.QtyText(h) .. "|r")
    row.price:SetText(h.price and ("|c" .. Skin.hex.price .. h.price .. "|r") or "|cFF666666—|r")
    row.prof:SetText("|c" .. Skin.hex.gold .. Skin.ProfLabel(h.profession) .. "|r")
    row.dest:SetText((h.online and "|cFF33DD33" or "|cFF888888") .. h.target .. "|r")
    row.status:SetText(h.delivered and ("|cFF33DD33" .. L["Remis"] .. "|r") or ("|cFFFFCC00" .. L["En attente"] .. "|r"))
    row:SetScript("OnClick", nil); row:SetScript("OnEnter", nil)
end
