-- CraftingOrderClassic_UI.lua — fenêtre principale (chrome Blizzard natif, kit UI_Skin_Native).
-- Onglets : Carnet / Commande / Récolte / Artisans / Mes artisans / Aide / Nouveautés.
-- Lit le cache (COC.db.orders + Directory), jamais le réseau directement.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local function me() return COC.Api.PlayerName() end   -- nom RÉSEAU (« Prénom Nom » sur Forever)

-- Nom de la fenêtre ; ShowTab y ajoute l'onglet actif, dont l'onglet latéral ne montre que l'icône.
local TITLE = "Crafting & Gathering Order"

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
    -- 606 (pas 600) : 6 px ajoutés pour la bande des anciennes languettes d'onglets du haut (cf.
    -- PAD_TOP plus bas). Les onglets sont au flanc droit depuis le palier 3 ; la hauteur est gardée.
    local f = Skin.MakeWindow("CraftingOrderClassicWindow", 868, 606, {
        title = TITLE, portrait = Skin.tex.scroll,
        buttonBar = true,   -- barre d'actions native en bas (Destinataire/Poster de l'onglet Commande)
    })
    self.frame = f

    -- Portrait cliquable : ouvre le choix de métier de l'onglet actif — Commande OU Récolte (remplace
    -- les gros boutons dropdown des panneaux). No-op ailleurs ; ShowTab masque la flèche hors contexte.
    Skin.SetPortraitClickable(f, function()
        if UI.activeTab == "post" then UI:_ToggleProfFlyout()
        elseif UI.activeTab == "gather" then UI:_ToggleGatherFlyout() end
    end, L["Cliquer pour changer de métier"])
    -- JAUGE DE COMPÉTENCE dans la barre de titre, à DROITE du portrait (demande user : « comme la vue
    -- métier ») : une barre bleue native portant le NOM DU MÉTIER + le niveau (rang/max) de l'artisan
    -- CIBLÉ. Remplace l'ancien libellé texte du métier et l'annotation « <artisan> : connu » qui vivait
    -- dans la liste des plans. Le titre central reste « Crafting & Gathering Order ». Vide (masquée) hors
    -- onglets Commande/Récolte. Alimentée par UI:_SyncHeaderSkill (métier ← _SyncMainPortrait, cible ←
    -- _UpdateArtisanLabel). RÉGLAGES (position/taille/couleur) : ICI. Contenu : _SyncHeaderSkill.
    local skill = CreateFrame("StatusBar", nil, f, "BackdropTemplate")
    skill:SetSize(200, 15); skill:SetPoint("CENTER", f, "TOPLEFT", 434, -31)
    skill:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    skill:SetStatusBarColor(0.20, 0.42, 0.90)   -- bleu « compétence » (iso barre de métier native)
    skill:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    skill:SetBackdropColor(0, 0, 0, 0.5); skill:SetBackdropBorderColor(0, 0, 0, 0.8)
    skill:SetMinMaxValues(0, 1); skill:SetValue(0)
    skill.text = skill:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    skill.text:SetPoint("CENTER"); Skin.ApplyShadow(skill.text)
    self.headerSkill = skill

    local status = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    status:SetPoint("BOTTOMLEFT", 16, 10); status:SetJustifyH("LEFT")
    Skin.ApplyShadow(status); self.status = status

    self:BuildTabs(f)
    self:BuildOrdersTab(f)
    self:BuildArtisansTab(f)
    if self.BuildMyArtisansTab then self:BuildMyArtisansTab(f) end
    if self.BuildPostTab   then self:BuildPostTab(f)   end
    if self.BuildGatherTab then self:BuildGatherTab(f) end
    if self.BuildHelpTab   then self:BuildHelpTab(f)   end
    if self.BuildNewsTab   then self:BuildNewsTab(f)   end
    if self._BuildHelp     then self:_BuildHelp(f)     end   -- aide contextuelle « bouton i » (dépend. molle)
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
    -- Onglets LATÉRAUX au flanc droit (palier 3, décision D1 : « comme la vue métier ») : une icône
    -- chacun, le nom dans l'infobulle et dans le titre. Mes artisans prend l'icône d'onglet des métiers
    -- de Camelot ; Artisans, l'atlas de l'onglet Amis du social (repli : une tête, si l'atlas manque).
    local I = "Interface\\Icons\\"
    local defs = {
        { id = "orders",     label = L["Carnet"],       icon = I .. "INV_Misc_Book_09" },
        { id = "post",       label = L["Commande"],     icon = I .. "INV_Scroll_05" },
        { id = "gather",     label = L["Récolte"],      icon = I .. "INV_Pick_02" },
        { id = "artisans",   label = L["Artisans"],     icon = I .. "INV_Misc_Head_Human_01",
          atlas = { "friends-icon-tab-friends", "friends-icon-tab-friends-inactive" } },
        { id = "myartisans", label = L["Mes artisans"], icon = I .. "INV_SideTab_Professions_c60" },
        { id = "help",       label = L["Aide"],         icon = I .. "INV_Misc_QuestionMark" },
        { id = "news",       label = L["Nouveautés"],   icon = I .. "INV_Letter_15" },
    }
    -- self.tabs reste l'index id→bouton (compat) ; la sélection, l'infobulle et le compteur passent
    -- par self.tabBar (même contrat que les languettes d'avant, cf. _UI_Skin_SideTabs.lua).
    self.tabBar = Skin.MakeSideTabs(f, defs, function(id) UI:ShowTab(id) end)
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
    local label = self.tabBar.Label and self.tabBar:Label(id)
    if self.frame.SetTitle then self.frame:SetTitle(label and (TITLE .. " — " .. label) or TITLE) end
    self.ordersPanel:SetShown(id == "orders")
    if self.postPanel   then self.postPanel:SetShown(id == "post")    end
    if self.gatherPanel then self.gatherPanel:SetShown(id == "gather") end
    self.artisansPanel:SetShown(id == "artisans")
    if self.myArtisansPanel then self.myArtisansPanel:SetShown(id == "myartisans") end
    if self.helpPanel   then self.helpPanel:SetShown(id == "help")    end
    if self.newsPanel   then self.newsPanel:SetShown(id == "news")    end
    -- Affordance du portrait cliquable (flèche) : visible seulement là où le clic fait quelque chose.
    if self.frame._portraitArrow then self.frame._portraitArrow:SetShown(id == "post" or id == "gather") end
    self:Refresh()
    if self._MaybeAutoHelp then self:_MaybeAutoHelp(id) end   -- tutoriel one-shot au 1er passage sur un onglet aidé
end

-- ------------------------------------------------------------------
-- Ligne « toute la liste » (Commande/Récolte) : bouton épinglé EN TÊTE de la liste d'artisans qui
-- cible explicitement TOUTE la source courante (toute la guilde / tous les amis). Le routage existe
-- déjà côté réseau (recipient "Guilde"/"Amis" ; cf. Orders:_ScopeMatch/VisibleTo) : ici on rend ce
-- choix VISIBLE et re-sélectionnable (sinon il n'existait qu'en effet de bord du clic sur l'onglet
-- source). Sélection seule → on poste ensuite via « Poster ». Partagé par _UI_Post + _UI_Gather.
-- ALL_RX/RW = place par défaut (Récolte) ; ALL_ARH = hauteur d'une ligne d'artisan, SEULE source.
local ALL_RX, ALL_RW, ALL_ARH = 316, 502, 26
local ALL_SRC_LABEL = {
    guild  = "Toute la guilde",  friend = "Tous les amis",
    added  = "Tous les ajoutés", recent = "Tous les croisés",
}

-- kind = "post" | "gather" ; top = Y de la ligne épinglée. Construit la ligne + la liste des artisans
-- juste en dessous, et renseigne self.<kind>AllRow / <kind>ArtList.
-- `panel` peut être un PANNEAU (Récolte : coordonnées absolues, x/w = ALL_RX/ALL_RW par défaut) ou une
-- SECTION (Commande, blocs natifs : on passe alors x = marge du bloc et w = largeur utile du bloc).
-- opts.fill(ligne, donnée) remplit une ligne d'artisan ; opts.bottom = marge au bas du panneau, où la
-- liste s'arrête (au-dessus du statut de l'onglet).
function UI:_BuildAllRowAndScroll(panel, kind, top, x, w, opts)
    x, w = x or ALL_RX, w or ALL_RW
    local row = Skin.MakeFlatRow(panel, w - 22, ALL_ARH)
    row:SetPoint("TOPLEFT", x, top)
    local ic = row:CreateTexture(nil, "OVERLAY"); ic:SetSize(14, 14); ic:SetPoint("LEFT", 5, 0); ic:SetTexture(Skin.tex.broadcast)
    row.label = row.text   -- alias historique (_RefreshAllRow) ; ré-ancré après l'icône
    row.label:ClearAllPoints(); row.label:SetPoint("LEFT", 24, 0)
    row.label:SetWidth(w - 60); row.label:SetTextColor(Skin.unpack(Skin.color.gold))
    row:SetScript("OnClick", function()
        if kind == "post" then UI.postTarget = UI.postSource; UI:RefreshPostArtisans(); UI:RefreshPostPlans()
        else UI.gatherTarget = UI.gatherSrc; UI:_RefreshGatherArtisans() end
    end)
    self[kind .. "AllRow"] = row

    -- Liste défilante du kit (palier 2). w − 10 = largeur de la ligne épinglée + la barre de 8 px.
    -- Elle descend jusqu'à `opts.bottom` : figée à 4 lignes, elle défilait au-dessus d'un grand vide.
    local host = CreateFrame("Frame", nil, panel)
    host:SetPoint("TOPLEFT", x, top - ALL_ARH - 2)
    host:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", x, opts.bottom or 22)
    host:SetWidth(w - 10)
    self[kind .. "ArtList"] = Skin.MakeScrollList(host, {
        extent = ALL_ARH,
        build  = Skin.ArtisanRowArt,
        fill   = opts.fill,
    })
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
-- coordonnée. Jusqu'au palier 3, une rangée de languettes d'onglets occupait f−34..f−66 sur la bande
-- grise ; les onglets sont désormais au flanc DROIT (Skin.MakeSideTabs), la bande ne porte plus que
-- la jauge de compétence (Commande/Récolte). Le contenu le plus HAUT est à −74 (Aide/Nouveautés).
-- La fenêtre fait 606 (600 + 6 pour cette bande) : ne pas faire varier PAD_TOP sans elle, même delta,
-- sinon la hauteur UTILE des panneaux (offsets bas-ancrés : Poster, commission…) change.
local PAD_X, PAD_TOP, PAD_BOT = 8, 0, 8
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
    -- Trois boutons rouges côte à côte AVANT (demande user 2026-07-12) → UN dropdown natif : ce sont
    -- trois VUES EXCLUSIVES du même carnet (une valeur parmi N), pas trois actions — c'est exactement
    -- le contrat du sélecteur gris de l'HdV (Skin.MakeDropdown). Bonus : la rangée libérée rend sa
    -- largeur au tableau. Entrantes (/commerce, /guilde) vivent dans la VUE MÉTIER, plus ici.
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
-- en-têtes de BuildOrdersTab ; une ligne chacune, tronquée par « … » au lieu de passer à la ligne.
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
    local items = {}
    for _, o in pairs((COC.db and COC.db.orders) or {}) do
        if o.buyer == m and archived == isPastOrder(o) then items[#items + 1] = { o = o } end
    end
    table.sort(items, function(a, b) return (a.o.ts or 0) > (b.o.ts or 0) end)
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

-- Même filtre qu'au dernier remplissage : la position est gardée ; un autre filtre repart du haut.
-- Le message de liste vide dépend du filtre. (Avant la liste défilante, il ne s'écrivait que si une
-- ligne avait déjà existé : un Carnet vide dès l'ouverture restait muet.)
function UI:_SetOrderData(items, emptyText)
    if not self.orderList then return end
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
        self.tabBar:SetText("orders", L["Carnet"] .. " (" .. c .. ")")   -- infobulle de l'onglet
        self.tabBar:SetCount("orders", c)                                 -- chiffre sur son icône
    end
    self:_RefreshOrderFilterTabs()
    self:_SyncMainPortrait()
    local D = COC.Directory
    self.status:SetText(string.format("|c%s" .. L["réseau"] .. "|r %s  ·  %d " .. L["en ligne"] .. "  ·  %d " .. L["artisan(s)"],
        Skin.hex.muted, COC:NetworkLabel(),
        D and D:CountOnline() or 0, D and D:CountKnownCrafters() or 0))
end

-- Portrait dynamique : icône du métier choisi sur les onglets Commande/Récolte, parchemin par défaut
-- ailleurs (même mécanisme que PW:_SyncPortrait — icônes de sort 64×64, chemin heureux de
-- SetWindowPortrait). Helper LÉGER, appelable directement au clic (sélection de métier dans le flyout)
-- SANS déclencher un UI:Refresh complet → le médaillon change instantanément, plus au prochain refresh
-- réseau/onglet (c'était le « délai » observé).
function UI:_SyncMainPortrait()
    if not self.frame then return end
    local prof = (self.activeTab == "post" and self.postProf)
              or (self.activeTab == "gather" and self.gatherProf) or nil
    Skin.SetWindowPortrait(self.frame, (prof and Skin.ProfIcon(prof)) or Skin.tex.scroll)
    self:_SyncHeaderSkill(prof)
end

-- Jauge de compétence du header (cf. sa création dans BuildMainWindow). Affiche le NOM DU MÉTIER
-- toujours ; la barre bleue se REMPLIT au niveau (rang/max) de l'artisan CIBLÉ quand la cible est un
-- @Nom dont on a le SK pour ce métier — sinon nom seul, barre vide. `prof` optionnel (sinon recalculé).
function UI:_SyncHeaderSkill(prof)
    local bar = self.headerSkill; if not bar then return end
    prof = prof or (self.activeTab == "post" and self.postProf)
                or (self.activeTab == "gather" and self.gatherProf) or nil
    if not prof then bar:Hide(); return end
    bar:Show()
    local rank, maxr
    local t = (self.activeTab == "post" and self.postTarget)
           or (self.activeTab == "gather" and self.gatherTarget)
    if t and t:sub(1, 1) == "@" then
        local D = COC.Directory
        local r = D and D.roster and D.roster[t:sub(2)]
        local sk = r and r.skill and r.skill[prof]
        if sk then rank, maxr = sk[1], sk[2] end
    end
    -- Suffixe = repère du filtrage de la liste des plans (« connu / à portée », vert — posé par
    -- RefreshPostPlans quand un artisan cible la liste) : même bandeau que le nom/niveau, plus de
    -- texte flottant sur la liste.
    local mode = (self.activeTab == "post") and self.postArtMode
    local tail = mode and ("  |cFF33DD33· " .. mode .. "|r") or ""
    if rank and maxr and maxr > 0 then
        bar:SetMinMaxValues(0, maxr); bar:SetValue(rank)
        bar.text:SetText(Skin.ProfLabel(prof) .. "   |cFFFFFFFF" .. rank .. " / " .. maxr .. "|r" .. tail)
    else
        bar:SetMinMaxValues(0, 1); bar:SetValue(0)
        bar.text:SetText(Skin.ProfLabel(prof) .. tail)
    end
end

-- `tab` (optionnel) : onglet sur lequel ATTERRIR à l'ouverture. La minimap passe "post" → un clic
-- gauche ouvre toujours sur Commande (l'action principale de l'addon, demande user). Sans argument :
-- comportement historique (garde l'onglet courant).
function UI:Toggle(tab)
    self:Build()
    if self.frame:IsShown() then self.frame:Hide()
    else self.frame:Show(); if tab then self:ShowTab(tab) else self:Refresh() end end
end
