-- CraftingOrderClassic_UI.lua — fenêtre principale (chrome Blizzard natif, kit UI_Skin_Native).
-- Onglets : Carnet / Commande / Récolte / Artisans / Mes artisans / Aide / Nouveautés.
-- Lit le cache (COC.db.orders + Directory), jamais le réseau directement.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local function me() return (UnitName and UnitName("player")) or "?" end

-- Le Carnet = MES commandes (postées par moi). L'acceptation/livraison se fait dans la VUE MÉTIER,
-- pas ici → ce fichier ne filtre plus par relation : il liste mes ordres (actifs vs archivés).

-- ------------------------------------------------------------------
-- Construction du cadre
-- ------------------------------------------------------------------
function UI:Build()
    if self.frame then return self.frame end
    -- Chrome Blizzard natif via le kit (CraftingOrderClassic_UI_Skin_Native.lua) : barre de titre +
    -- portrait + bouton fermer + panneau encastré marbre (f.Inset). Le langage couleur (statuts
    -- d'ordre / rareté d'objet) reste INTOUCHÉ ; seul le chrome change.
    local f = Skin.MakeWindow("CraftingOrderClassicWindow", 868, 600, {
        title = "Crafting & Gathering Order", portrait = Skin.tex.scroll,
    })
    self.frame = f

    -- Portrait cliquable : sur l'onglet Commande, ouvre le choix de métier (remplace le gros bouton
    -- dropdown — cf. UI_Post.lua). No-op ailleurs ; ShowTab masque la flèche hors de cet onglet.
    Skin.SetPortraitClickable(f, function() if UI.activeTab == "post" and UI._ToggleProfFlyout then UI:_ToggleProfFlyout() end end,
        L["Cliquer pour changer de métier"])

    local status = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    status:SetPoint("BOTTOMLEFT", 16, 14); status:SetJustifyH("LEFT")
    Skin.ApplyShadow(status); self.status = status

    self:BuildTabs(f)
    self:BuildOrdersTab(f)
    self:BuildArtisansTab(f)
    if self.BuildMyArtisansTab then self:BuildMyArtisansTab(f) end
    if self.BuildPostTab   then self:BuildPostTab(f)   end
    if self.BuildGatherTab then self:BuildGatherTab(f) end
    if self.BuildHelpTab   then self:BuildHelpTab(f)   end
    if self.BuildNewsTab   then self:BuildNewsTab(f)   end
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
        { id = "orders",    label = L["Carnet"]      },
        { id = "post",      label = L["Commande"]    },
        { id = "gather",    label = L["Récolte"]     },
        { id = "artisans",  label = L["Artisans"]    },
        { id = "myartisans",label = L["Mes artisans"] },
        { id = "help",      label = L["Aide"]        },
        { id = "news",      label = L["Nouveautés"]  },
    }
    -- Onglets natifs « bas de cadre » via le kit (pièges du template gérés là-bas). self.tabs reste
    -- l'index id→bouton (compat) ; la sélection et les SetText passent par self.tabBar.
    self.tabBar = Skin.MakeTabs(f, defs, function(id) UI:ShowTab(id) end)
    self.tabs = self.tabBar.buttons
end

function UI:ShowTab(id)
    -- Changement d'onglet → on réinitialise les sélections (évite les faux clics / sélections
    -- fantômes d'un onglet à l'autre, ex. « Sélection : Écaille » qui traînait sous Élémentaire).
    if id ~= self.activeTab then
        self.postEntry = nil; self.postProvide = {}
        self.gatherEntry = nil
    end
    self.activeTab = id
    self.tabBar:Select(id)
    self.ordersPanel:SetShown(id == "orders")
    if self.postPanel   then self.postPanel:SetShown(id == "post")    end
    if self.gatherPanel then self.gatherPanel:SetShown(id == "gather") end
    self.artisansPanel:SetShown(id == "artisans")
    if self.myArtisansPanel then self.myArtisansPanel:SetShown(id == "myartisans") end
    if self.helpPanel   then self.helpPanel:SetShown(id == "help")    end
    if self.newsPanel   then self.newsPanel:SetShown(id == "news")    end
    -- Affordance du portrait cliquable (flèche) : visible seulement là où le clic fait quelque chose.
    if self.frame._portraitArrow then self.frame._portraitArrow:SetShown(id == "post") end
    self:Refresh()
end

-- ------------------------------------------------------------------
-- Ligne « toute la liste » (Commande/Récolte) : bouton épinglé EN TÊTE de la liste d'artisans qui
-- cible explicitement TOUTE la source courante (toute la guilde / tous les amis). Le routage existe
-- déjà côté réseau (recipient "Guilde"/"Amis" ; cf. Orders:_ScopeMatch/VisibleTo) : ici on rend ce
-- choix VISIBLE et re-sélectionnable (sinon il n'existait qu'en effet de bord du clic sur l'onglet
-- source). Sélection seule → on poste ensuite via « Poster ». Partagé par _UI_Post + _UI_Gather.
-- ALL_RX/RW/ARH = mêmes valeurs que les locaux RX/RW/ARH de ces deux fichiers (layout identique).
local ALL_RX, ALL_RW, ALL_ARH = 316, 502, 26
local ALL_SRC_LABEL = {
    guild  = "Toute la guilde",  friend = "Tous les amis",
    added  = "Tous les ajoutés", recent = "Tous les croisés",
}

-- kind = "post" | "gather" ; top = Y de la ligne épinglée. Construit la ligne + le ScrollFrame (4
-- lignes visibles) juste en dessous, et renseigne self.<kind>AllRow / <kind>ArtContent / <kind>ArtRows.
function UI:_BuildAllRowAndScroll(panel, scrollName, kind, top)
    local row = Skin.MakeFlatRow(panel, ALL_RW - 22, ALL_ARH)
    row:SetPoint("TOPLEFT", ALL_RX, top)
    local ic = row:CreateTexture(nil, "OVERLAY"); ic:SetSize(14, 14); ic:SetPoint("LEFT", 5, 0); ic:SetTexture(Skin.tex.broadcast)
    row.label = row.text   -- alias historique (_RefreshAllRow) ; ré-ancré après l'icône
    row.label:ClearAllPoints(); row.label:SetPoint("LEFT", 24, 0)
    row.label:SetWidth(ALL_RW - 60); row.label:SetTextColor(Skin.unpack(Skin.color.gold))
    row:SetScript("OnClick", function()
        if kind == "post" then UI.postTarget = UI.postSource; UI:RefreshPostArtisans(); UI:RefreshPostPlans()
        else UI.gatherTarget = UI.gatherSrc; UI:_RefreshGatherArtisans() end
    end)
    self[kind .. "AllRow"] = row

    local scroll = CreateFrame("ScrollFrame", scrollName, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", ALL_RX, top - ALL_ARH - 2); scroll:SetSize(ALL_RW, 4 * ALL_ARH)
    local content = CreateFrame("Frame", nil, scroll); content:SetSize(ALL_RW - 22, 10); scroll:SetScrollChild(content)
    self[kind .. "ArtContent"] = content; self[kind .. "ArtRows"] = {}
end

-- Rafraîchit le libellé + l'état sélectionné de la ligne « toute la liste » selon la source courante.
function UI:_RefreshAllRow(kind)
    local row = self[kind .. "AllRow"]; if not row then return end
    local src = (kind == "post") and (self.postSource or "guild") or (self.gatherSrc or "guild")
    local tgt = (kind == "post") and self.postTarget or self.gatherTarget
    row.label:SetText(L[ALL_SRC_LABEL[src] or "Tous les croisés"])
    row.selTex:SetShown(tgt == src)
    local diff = self[kind .. "DiffBtn"]; if diff then diff:SetSelected(tgt == "all") end
end

-- ------------------------------------------------------------------
-- Onglet Carnet d'ordres — table (Commande · Qté · Prix · Métier · Destinataire · Statut)
-- ------------------------------------------------------------------
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

-- Marge intérieure commune : décale TOUT le contenu d'un panneau d'un coup, sans retoucher chaque
-- coordonnée. LEVIER CENTRAL du haut de page : les 7 onglets s'ancrent ici, donc PAD_TOP règle d'un
-- seul geste la hauteur du « band » vide sous la barre de titre. Avec l'ancien chrome (wordmark +
-- onglets EN HAUT), ce band réservait ~80 px ; ce chrome est parti (titre natif, onglets en bas) → on
-- REMONTE le contenu (PAD_TOP négatif : le panneau démarre 6 px au-dessus du cadre, ses enfants
-- retombent dans le marbre). Garde-fou : le contenu le plus HAUT de tous les onglets est à −74
-- (Aide/Nouveautés) → avec PAD_TOP=−6 il atterrit à f−68, soit 8 px sous le sommet de l'inset (f−60) :
-- reste dans le marbre, jamais dans la barre de titre. Ne pas descendre PAD_TOP sous −8 sans re-auditer.
local PAD_X, PAD_TOP, PAD_BOT = 8, -6, 8
local function insetPanel(panel, f)
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", f, "TOPLEFT", PAD_X, -PAD_TOP)
    panel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD_X, PAD_BOT)
end
UI.insetPanel = insetPanel

function UI:BuildOrdersTab(f)
    local panel = CreateFrame("Frame", nil, f); insetPanel(panel, f); self.ordersPanel = panel

    -- Carnet = MES commandes : En cours (ouvertes/acceptées) / Archivées (livrées/annulées) +
    -- la file Entrantes (demandes captées dans /commerce et /guilde de joueurs sans l'addon).
    self.orderFilter = "active"; self.orderFilterBtns = {}
    -- Entrantes (/commerce, /guilde) sont désormais dans la VUE MÉTIER, plus dans le Carnet.
    local fdefs = { {id="active",label=L["En cours"]}, {id="archived",label=L["Archivées"]}, {id="handoff",label=L["Confiées"]} }
    local fx = 12
    for _, d in ipairs(fdefs) do
        local w = 78
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
    hdr(L["MÉTIER"], COL.prof); self.hdrDest = hdr(L["ARTISAN"], COL.dest); hdr(L["STATUT"], COL.status)
    Skin.MakeSeparator(panel, -118)

    local scroll = CreateFrame("ScrollFrame", "CraftingOrderOrdersScroll", panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -124); scroll:SetPoint("BOTTOMRIGHT", -42, 22)
    local content = CreateFrame("Frame", nil, scroll); content:SetSize(800, 10); scroll:SetScrollChild(content)
    self.ordersContent = content; self.orderRows = {}
end

function UI:_RefreshOrderFilterTabs()
    for id, b in pairs(self.orderFilterBtns or {}) do b:SetSelected(id == self.orderFilter) end
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

-- Toast : notification éphémère skinnée (haut-centre), fade ≤160 ms + son. Réutilisable (ordre ciblé
-- reçu, entrante captée, artisan favori en ligne). Remplace/complète les print de chat.
function UI:Toast(text, icon)
    local t = self._toast
    if not t then
        t = CreateFrame("Frame", "CraftingOrderToast", UIParent, "BackdropTemplate")
        t:SetSize(330, 44); t:SetPoint("TOP", UIParent, "TOP", 0, -130)
        t:SetFrameStrata("FULLSCREEN_DIALOG"); Skin.SkinFrameBackdrop(t)
        t.icon = t:CreateTexture(nil, "ARTWORK"); t.icon:SetSize(28, 28); t.icon:SetPoint("LEFT", 10, 0)
        t.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        t.fs = t:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        t.fs:SetPoint("LEFT", t.icon, "RIGHT", 8, 0); t.fs:SetPoint("RIGHT", -10, 0)
        t.fs:SetJustifyH("LEFT"); Skin.ApplyShadow(t.fs)
        t:Hide(); self._toast = t
    end
    t.icon:SetTexture(icon or Skin.tex.workorder); t.fs:SetText(text)
    t:SetAlpha(0); t:Show()
    if UIFrameFadeIn then UIFrameFadeIn(t, 0.16, 0, 1) else t:SetAlpha(1) end
    if t._hideTimer then t._hideTimer:Cancel() end
    if C_Timer then
        t._hideTimer = C_Timer.NewTimer(4, function()
            if UIFrameFadeOut then UIFrameFadeOut(t, 0.3, t:GetAlpha(), 0) end
            C_Timer.After(0.3, function() t:Hide() end)
        end)
    end
end

-- Une commande est « passée » (archivée) si livrée ou annulée → hors du tableau actif.
local function isPastOrder(o) return o.status == "done" or o.status == "cancelled" end

function UI:RefreshOrders()
    if self.hdrDest then self.hdrDest:SetText(L["ARTISAN"]) end
    if self.orderFilter == "handoff" then return self:RefreshHandoff() end
    local archived, m = (self.orderFilter == "archived"), me()
    local mine = {}
    for _, o in pairs((COC.db and COC.db.orders) or {}) do if o.buyer == m then mine[#mine + 1] = o end end
    table.sort(mine, function(a, b) return (a.ts or 0) > (b.ts or 0) end)
    local n = 0
    for _, o in ipairs(mine) do
        if (archived and isPastOrder(o)) or (not archived and not isPastOrder(o)) then
            n = n + 1
            local row = self:_OrderRow(n)
            local nm = COC.Orders:OrderName(o)
            local r, g, b = Skin.RarityColor(o.itemID)
            row.badge:Paint(r, g, b, Skin.FirstChar(nm), Skin.Icon(o.itemID, o.spellID))
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

-- Filtre « Confiées » : commandes (miennes + entrantes captées) qu'un artisan CONNU sait faire,
-- gardées pour lui. Une ligne par (commande, artisan) ; statut = Remis (poussé cette session) vs
-- En attente (il n'est pas encore repassé). Réutilise le pool de lignes du Carnet (colonnes détournées).
function UI:RefreshHandoff()
    local rows = (COC.Handoff and COC.Handoff:Pending()) or {}
    local n = 0
    for _, it in ipairs(rows) do
        n = n + 1
        local row = self:_OrderRow(n)
        local r, g, b = Skin.RarityColor(it.itemID)
        row.badge:Paint(r, g, b, Skin.FirstChar(it.name or "?"), Skin.Icon(it.itemID, it.spellID)); row.badge:Show()
        row.name:SetText(it.name or "?"); row.name:SetTextColor(r, g, b)
        row.qty:SetText("|cFFCCCCCC" .. Skin.QtyText(it) .. "|r")
        row.price:SetText(it.price and ("|c" .. Skin.hex.price .. it.price .. "|r") or "|cFF666666—|r")
        row.prof:SetText("|c" .. Skin.hex.gold .. Skin.ProfLabel(it.profession) .. "|r")
        row.dest:SetText((it.online and "|cFF33DD33" or "|cFF888888") .. it.target .. "|r")
        row.status:SetText(it.delivered and ("|cFF33DD33" .. L["Remis"] .. "|r") or ("|cFFFFCC00" .. L["En attente"] .. "|r"))
        row:SetScript("OnClick", nil); row:SetScript("OnEnter", nil); row:Show()
    end
    for i = n + 1, #self.orderRows do self.orderRows[i]:Hide() end
    self.ordersContent:SetHeight(math.max(n * ROW_T, 10))
    Skin.AutoHideScroll("CraftingOrderOrdersScroll", self.ordersContent)
    if n == 0 and self.orderRows[1] then
        local row = self:_OrderRow(1); row.badge:Hide()
        row.name:SetText("|cFF888888" .. L["Aucune commande confiée pour l'instant."] .. "|r"); row.name:SetTextColor(0.6, 0.6, 0.6)
        row.qty:SetText(""); row.price:SetText(""); row.prof:SetText(""); row.dest:SetText(""); row.status:SetText("")
        row:SetScript("OnClick", nil); row:SetScript("OnEnter", nil); row:Show()
    end
end

-- (Les demandes « Entrantes » captées dans /commerce et /guilde sont désormais affichées dans la
-- VUE MÉTIER — colonne Commandes de _ProfWindow_Orders.lua — et non plus dans le Carnet.)

-- ------------------------------------------------------------------
-- Onglet Artisans (annuaire social) → CraftingOrderClassic_UI_Artisans.lua
-- (BuildArtisansTab / RefreshArtisans y sont définis ; chargé après ce fichier).
-- ------------------------------------------------------------------

-- ------------------------------------------------------------------
-- Refresh global + statut + toggle
-- ------------------------------------------------------------------
-- Refresh COALESCÉ (0,1 s) pour les rafales réseau : un fanout NEW arrive par salves de whispers
-- (~6/s) et chaque message appelait UI:Refresh → autant de redraws complets (dont RefreshPostPlans,
-- coûteux). On regroupe. Les chemins INTERACTIFS (ouverture, onglet, clic action) appellent Refresh
-- direct pour rester immédiats. Même patron que PW:Refresh / UI:_NamesDirty.
function UI:RefreshSoon()
    if not (C_Timer and C_Timer.After) then return self:Refresh() end
    if not (self.frame and self.frame:IsShown()) then return end
    if self._refreshPending then return end
    self._refreshPending = true
    C_Timer.After(0.1, function() UI._refreshPending = nil; UI:Refresh() end)
end

function UI:Refresh()
    if not self.frame or not self.frame:IsShown() then return end
    if     self.activeTab == "artisans"                          then self:RefreshArtisans()
    elseif self.activeTab == "myartisans" and self.RefreshMyArtisans then self:RefreshMyArtisans()
    elseif self.activeTab == "post"   and self.RefreshPost       then self:RefreshPost()
    elseif self.activeTab == "gather" and self.RefreshGather     then self:RefreshGather()
    elseif self.activeTab == "help"   and self.RefreshHelp       then self:RefreshHelp()
    elseif self.activeTab == "news"   and self.RefreshNews       then self:RefreshNews()
    else self:RefreshOrders() end
    -- Compteur d'ordres du Carnet = ce qui est RÉELLEMENT visible (All() applique TTL + routage
    -- VisibleTo), pas le cache brut → plus d'écart « Carnet (5) mais liste vide ».
    if self.tabs and self.tabs.orders and COC.Orders then
        local c, m = 0, me()   -- Carnet = MES commandes actives (livrées/annulées → « Archivées »)
        for _, o in pairs((COC.db and COC.db.orders) or {}) do
            if o.buyer == m and o.status ~= "done" and o.status ~= "cancelled" then c = c + 1 end
        end
        self.tabBar:SetText("orders", L["Carnet"] .. " (" .. c .. ")")   -- re-mesure la largeur (kit)
    end
    if self.orderFilterBtns then self:_RefreshOrderFilterTabs() end
    self:_SyncMainPortrait()
    local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    local D = COC.Directory
    self.status:SetText(string.format("|c%s" .. L["réseau"] .. "|r %s  ·  %d " .. L["en ligne"] .. "  ·  %d " .. L["artisan(s)"],
        Skin.hex.muted,
        (CraftLink and CraftLink:IsNetworkReady()) and ("|cFF33DD33" .. L["canal rejoint"] .. "|r") or "|cFFFFCC00…|r",
        D and D:CountOnline() or 0, D and D:CountKnownCrafters() or 0))
end

-- Portrait dynamique : icône du métier choisi sur l'onglet Commande, parchemin par défaut ailleurs
-- (même mécanisme que PW:_SyncPortrait — icônes de sort 64×64, chemin heureux de SetWindowPortrait).
-- Helper LÉGER, appelable directement au clic (sélection de métier dans le flyout) SANS déclencher un
-- UI:Refresh complet → le médaillon change instantanément, plus au prochain refresh réseau/onglet
-- (c'était le « délai » observé).
function UI:_SyncMainPortrait()
    if not self.frame then return end
    Skin.SetWindowPortrait(self.frame,
        (self.activeTab == "post" and Skin.ProfIcon(self.postProf)) or Skin.tex.scroll)
end

function UI:Toggle()
    self:Build()
    if self.frame:IsShown() then self.frame:Hide() else self.frame:Show(); self:Refresh() end
end
