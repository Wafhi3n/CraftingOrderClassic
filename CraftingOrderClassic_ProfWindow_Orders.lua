-- CraftingOrderClassic_ProfWindow_Orders.lua — colonne « Commandes » de la vue métier (cabine de
-- l'artisan) : construction (onglets de relation, en-tête, scroll), vue LISTE (une ligne par
-- commande : demandeur + prix + âge ; une ligne sourdine cliquée se réaffiche), collecte/tri et
-- rafraîchissement. La vue SÉLECTIONNÉE (carte complète : composants, Lazy Gold, ACCEPTER/REFUSER/
-- CHUCHOTER) vit dans _ProfWindow_Orders_Card.lua (anti-monolithe). Onglets de relation (Tous /
-- Guilde / Amis / Annuaire) + onglet de SOURCE « Entrantes » (chat capté /commerce·/guilde et
-- ordres `captured`, avec badge de comptage) au header.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L
local PW   = COC.ProfWindow

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

PW.ORD_CARD_W = 280          -- largeur de la carte (partagée avec _Orders_Card)
local ROW_H   = 22           -- ligne de la vue LISTE (une commande = une ligne)

-- 4 onglets de RELATION (qui est l'acheteur) + 1 onglet de SOURCE : « Entrantes » isole ce qui
-- vient du CHAT (demandes captées /commerce·/guilde + ordres `captured` poussés par un pair) —
-- autre nature que les commandes réseau (pas de cycle ACK/DONE, réponse en chuchotement manuel),
-- donc jamais mélangées aux onglets de relation (demande user 2026-07-23).
local REL = {
    { id = "all",     label = L["Tous"]    },
    { id = "guild",   label = L["Guilde"]  },
    { id = "friend",  label = L["Amis"]    },
    { id = "recent",  label = L["Annuaire"] },
    { id = "inbound", label = L["Entrantes"] },
}
PW.ORD_REL_COL = { guild = "FF8FD98F", friend = "FF6FB7FF", recent = "FFCBB389" }

-- Relation du demandeur (depuis l'annuaire) : "guild"/"friend"/"recent", ou nil si inconnu.
function PW:_OrdRelation(name)
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
function PW:_OrderReagents(o)
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
function PW:_OrderItemName(o, c)
    return (c and c:ItemName(o.itemID, o.itemName))
        or (o.spellID and c and c:RecipeName(o.spellID))
        or ("item:" .. (o.itemID or 0))
end

-- Difficulté (couleur de plan) d'une commande POUR MOI : résolue par l'objet produit (métiers
-- TradeSkill) ou le spellID du lien enchant (API Craft) depuis les recettes du métier OUVERT.
-- nil si plan inconnu / non appris / récolte. Map invalidée à chaque RefreshOrders (un skill-up
-- change les couleurs).
function PW:_OrderDifficulty(o)
    local m = self._ordDiffMap
    if not m then
        m = { item = {}, spell = {} }
        for _, r in ipairs(self.recipes or {}) do
            if not r.isHeader and r.difficulty then
                if r.itemID then m.item[r.itemID] = r.difficulty end
                local sid = r.link and tonumber(r.link:match("|Henchant:(%d+)"))
                if sid then m.spell[sid] = r.difficulty end
            end
        end
        self._ordDiffMap = m
    end
    return (o.itemID and m.item[o.itemID]) or (o.spellID and m.spell[o.spellID]) or nil
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

-- Vue pleine : barre calée à DROITE du cadre — à 5 languettes elle est PLUS LARGE que la colonne
-- Commandes, calée à gauche de la colonne elle débordait du cadre (retour terrain 2026-07-23) ; en
-- grandissant vers la gauche elle mord sur le marbre au-dessus du détail, où il y a la place.
-- Compact/dock (fenêtre 300 px) : bord gauche + rétrécissement à l'échelle si la barre dépasse
-- (les offsets sont re-divisés par l'échelle : un SetPoint s'exprime dans l'espace LOCAL du frame).
-- Re-appelée après chaque badge « Entrantes (N) » (RefreshOrders) : la largeur de la barre vit.
function PW:_PlaceOrdTabs(compact)
    local bar = self.ordRelTabs
    local first = bar and bar.buttons[REL[1].id]
    if not first then return end
    local total = -4 * (#REL - 1)                     -- chevauchement natif des languettes (−4 px)
    for _, d in ipairs(REL) do total = total + bar.buttons[d.id]:GetWidth() end
    local fw = self.frame:GetWidth() or 0
    local s = (compact and fw > 0 and total > fw - 16) and math.max((fw - 16) / total, 0.7) or 1
    for _, d in ipairs(REL) do bar.buttons[d.id]:SetScale(s) end
    first:ClearAllPoints()
    if compact or fw == 0 then                        -- fw 0 = build avant sizing (re-posée au 1er refresh)
        first:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 8 / s, -28 / s)
    else
        first:SetPoint("TOPLEFT", self.frame, "TOPLEFT", fw - total - 12, -28)
    end
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
    -- ▲ « progression d'abord » : les commandes dont le plan ME rapporte un point passent en tête
    -- (pendant du tri progression de la colonne Recettes). État runtime, liseré doré = actif.
    local lvl = Skin.MakeIconButton(bz, 16, "Interface\\Buttons\\UI-MicroStream-Green")
    lvl:SetPoint("TOPRIGHT", -6, -5)
    lvl.icon:SetDesaturated(true)
    lvl:SetScript("OnClick", function()
        PW.ordSortLevel = not PW.ordSortLevel
        lvl:SetSelected(PW.ordSortLevel and true or false)
        lvl.icon:SetDesaturated(not PW.ordSortLevel)
        PW:RefreshOrders()
    end)
    lvl:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText(PW.ordSortLevel and L["Progression d'abord — clic pour revenir aux récentes."]
            or L["Trier : les commandes qui me font progresser d'abord."], 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    lvl:SetScript("OnLeave", GameTooltip_Hide)
    self.ordLevelBtn = lvl
    local scroll = CreateFrame("ScrollFrame", "CraftingOrderProfWinOrdScroll", bz, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 6, -26); scroll:SetPoint("BOTTOMRIGHT", -24, 0)
    local content = CreateFrame("Frame", nil, scroll); content:SetSize(PW.ORD_CARD_W, 10); scroll:SetScrollChild(content)
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
    -- Liseré vertical au bord gauche = couleur de DIFFICULTÉ du plan pour MOI (orange = un point
    -- garanti au craft). Langage couleur natif des métiers — jamais recoloré par le chrome.
    r.diff = r:CreateTexture(nil, "ARTWORK")
    r.diff:SetSize(3, ROW_H - 6); r.diff:SetPoint("LEFT", 0, 0); r.diff:Hide()
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
    Skin.WireItemLink(r)      -- shift-clic → lien chat de l'objet voulu
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
        row.badge:Hide(); row.item:Hide(); row.diff:Hide()
        row.tipItemID, row.tipSpellID = nil, nil   -- pas de tooltip sur une ligne repliée
        row:Show(); return
    end
    local diff = self:_OrderDifficulty(o)
    if diff then
        local dr, dg, db = COC.Craft:DifficultyColor(diff)
        row.diff:SetColorTexture(dr, dg, db, 0.9); row.diff:Show()
    else
        row.diff:Hide()
    end
    local rel = self:_OrdRelation(o.buyer) or "recent"
    local tag = (it.kind == "inbound") and (" |T" .. Skin.tex.dotYellow .. ":10|t") or ""
    row.name:SetText("|c" .. (PW.ORD_REL_COL[rel] or "FFFFFFFF") .. (o.buyer or "?") .. "|r" .. tag)
    local nm = self:_OrderItemName(o, c)
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

-- ------------------------------------------------------------------
-- Rafraîchissement : collecte (carnet + entrantes) filtrée par métier ouvert + relation.
-- ------------------------------------------------------------------
-- Entrantes /commerce du métier ouvert : ÉPHÉMÈRES (Inbound:Prune — jamais de « 20 h » ici) et
-- seulement celles que je peux réellement servir (Inbound:VisibleInProfView, scope "mine").
-- `list` nil = comptage seul (badge de l'onglet Entrantes depuis un autre onglet). Renvoie le
-- nombre retenu (toutes comptent « en attente »).
function PW:_CollectInbound(list, prof)
    local Inb, n = COC.Inbound, 0
    if Inb then Inb:Prune() end
    for _, e in pairs((COC.db and COC.db.inbound) or {}) do
        if e.profession == prof and e.status ~= "dismissed"
           and (not Inb or Inb:VisibleInProfView(e)) then
            n = n + 1
            if list then list[#list + 1] = { o = e, kind = "inbound" } end
        end
    end
    return n
end

-- Tri de la vue liste : récentes d'abord ; « progression d'abord » (▲ du header) fait passer les
-- commandes dont le plan ME rapporte un point (orange) en tête, puis jaune/vert ; plan gris ou
-- inconnu derrière — à rang égal, récentes d'abord (le tri est refait dans le comparateur,
-- table.sort n'est pas stable). Les sourdines sont repliées à la FIN (cf. mockup Vue Métier).
function PW:_SortOrdList(list, mutedList)
    table.sort(list, function(a, b) return (a.o.ts or 0) > (b.o.ts or 0) end)
    if self.ordSortLevel then
        local RANK = { optimal = 1, medium = 2, easy = 3, trivial = 4 }
        table.sort(list, function(a, b)
            local ra = RANK[self:_OrderDifficulty(a.o)] or 5
            local rb = RANK[self:_OrderDifficulty(b.o)] or 5
            if ra ~= rb then return ra < rb end
            return (a.o.ts or 0) > (b.o.ts or 0)
        end)
    end
    table.sort(mutedList, function(a, b) return (a.o.ts or 0) > (b.o.ts or 0) end)
    for _, it in ipairs(mutedList) do list[#list + 1] = it end
end

-- Collecte les commandes du métier : visibles triées récentes d'abord, puis les sourdines repliées
-- en bas. Onglet « Entrantes » (canal) = SEULEMENT le chat (captées + `captured`) ; les onglets de
-- relation n'en montrent plus aucune. Renvoie (liste, en attente, acceptées, nb sourdines,
-- nb Canal) — le dernier alimente le badge de l'onglet Entrantes quel que soit l'onglet actif.
function PW:_CollectOrders()
    local prof, relTab = self.profKey, self.ordRelTab or "all"
    local canal = relTab == "inbound"
    local muted = (COC.db and COC.db.muted) or {}
    local O, Mod, now = COC.Orders, COC.Moderation, time()
    local H = COC.Handoff
    local ttl = (O and O.ORDER_TTL) or (6 * 3600)
    local function keep(name) return relTab == "all" or PW:_OrdRelation(name) == relTab end
    -- Mêmes règles que le Carnet (Orders:All) : routage VisibleTo + TTL (une vue de relation seule
    -- montrerait les commandes NOMMÉES pour un TIERS et les OUVERTES expirées). Une commande CAPTÉE
    -- (demandeur sans addon, poussée par un pair) suit la règle de son alerte (_OnSuggest : « ssi
    -- ICanCraft ») : sans la recette, rien à en faire au cockpit.
    local function shown(o)
        if O and O.VisibleTo and not O:VisibleTo(o) then return false end
        if o.captured and H and not H:ICanCraft(o) then return false end
        return not (o.status == "open" and (now - (o.ts or now)) > ttl)
    end
    -- Sourdine : par ID d'ordre (db.muted) OU par JOUEUR (Moderation) — un acheteur muté ne doit pas
    -- continuer à remplir la vue métier. Les deux sont repliés en bas, pas supprimés.
    local function isMuted(o)
        return (muted[o.id] or (Mod and Mod.IsMuted and Mod:IsMuted(o.buyer))) and true or false
    end
    local list, mutedList, pending, accepted, mutedN, canalN = {}, {}, 0, 0, 0, 0
    local function add(o)
        if isMuted(o) then
            mutedN = mutedN + 1
            mutedList[#mutedList + 1] = { o = o, kind = "order", muted = true }
        else
            list[#list + 1] = { o = o, kind = "order" }
            if o.status == "open" then pending = pending + 1
            elseif o.status == "accepted" then accepted = accepted + 1 end
        end
    end
    for _, o in pairs((COC.db and COC.db.orders) or {}) do
        if o.profession == prof and o.status ~= "cancelled" and o.status ~= "done" and shown(o) then
            if o.captured then
                canalN = canalN + 1
                if canal then add(o) end
            elseif not canal and keep(o.buyer) then add(o) end
        end
    end
    local inbN = self:_CollectInbound(canal and list or nil, prof)
    canalN = canalN + inbN
    if canal then pending = pending + inbN end
    self:_SortOrdList(list, mutedList)
    return list, pending, accepted, mutedN, canalN
end

function PW:RefreshOrders()
    if not self.ordContent then return end
    self._ordDiffMap = nil   -- couleurs de difficulté re-lues à chaque refresh (un skill-up les change)
    local list, pending, accepted, mutedN, canalN = self:_CollectOrders()
    -- Badge de l'onglet Entrantes : « Entrantes (2) » dès qu'il y a du chat capté pour ce métier —
    -- visible depuis n'importe quel onglet (MakeTabs:SetText re-mesure la languette).
    if self.ordRelTabs then
        self.ordRelTabs:SetText("inbound",
            canalN > 0 and (L["Entrantes"] .. " (" .. canalN .. ")") or L["Entrantes"])
    end
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

-- (Vue SÉLECTIONNÉE — _OrdCard/_FillCard/_RenderOrdSelected — dans _ProfWindow_Orders_Card.lua.)
