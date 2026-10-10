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
        buttonBar = true, insets = true,   -- barre d'actions (Destinataire/Poster) ; encarts des métiers (P6)
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
-- LE DESTINATAIRE (Commande/Récolte) — piste 2 de la maquette « destinataire », choisie par le user le
-- 2026-09-30. Avant, un seul choix vivait à cinq endroits : un menu de portée qui ressemblait à un
-- destinataire, la bulle « Diffuser à tous » au bout de la bande, une ligne « toute la guilde » qui
-- portait la MÊME bulle, la case Commerce et le rappel en bas. Maintenant chaque destinataire est une
-- LIGNE de la liste, avec la même surbrillance : « Tous (avec l'addon) », le groupe entier (guilde /
-- amis), puis un joueur. Le routage est inchangé (recipient "Tous"/"Guilde"/"Amis"/Nom, cf.
-- Orders:VisibleTo). Sélection seule → on poste via « Poster ». Partagé par _UI_Post + _UI_Gather.
-- ALL_RX/RW = place par défaut (Récolte) ; ALL_ARH = hauteur d'une ligne d'artisan, SEULE source.
local ALL_RX, ALL_RW, ALL_ARH, PIN_GAP = 316, 502, 26, 6
-- LIST_BAR : la place de la barre de défilement au bord droit de la liste (MinimalScrollBar 8 + écart
-- 4, Skin.MakeScrollList). Les lignes épinglées, la légende et le menu de la bande s'arrêtent là, sur
-- la même verticale que les lignes de la liste ; la liste elle-même, barre comprise, prend toute la
-- largeur de la bande (capture du user : le menu dépassait les lignes de 15 px, 2026-09-30).
local LIST_BAR = 12
local GROUP_LABEL = { guild = "Toute la guilde", friend = "Tous les amis" }

-- Icône du groupe : le tabard de guilde, ou l'atlas de l'onglet Amis du volet social (vérifié en jeu
-- le 2026-09-28, skill coc-native-ui). Plus la bulle de « Tous » : une image pour deux destinataires.
local FRIEND_ATLAS = "friends-icon-tab-friends"
local function paintGroupIcon(ic, grp)
    if grp == "friend" and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(FRIEND_ATLAS) then
        ic:SetAtlas(FRIEND_ATLAS); return
    end
    if grp == "friend" then ic:SetTexture(Skin.tex.online); ic:SetTexCoord(0, 1, 0, 1)
    else ic:SetTexture(Skin.tex.guild); ic:SetTexCoord(0.08, 0.92, 0.08, 0.92) end   -- rogne la bordure cuite
end

-- Une ligne épinglée : icône 14 px, libellé doré, surbrillance de MakeFlatRow.
local function pinnedRow(panel, w)
    local row = Skin.MakeFlatRow(panel, w - LIST_BAR, ALL_ARH)
    row.icon = row:CreateTexture(nil, "OVERLAY"); row.icon:SetSize(14, 14); row.icon:SetPoint("LEFT", 5, 0)
    row.label = row.text   -- alias historique ; ré-ancré après l'icône
    row.label:ClearAllPoints(); row.label:SetPoint("LEFT", 24, 0)
    row.label:SetWidth(w - 60); row.label:SetTextColor(Skin.unpack(Skin.color.gold))
    return row
end

-- kind = "post" | "gather" ; top = Y de la 1re ligne épinglée. Construit « Tous », la ligne de
-- groupe, la légende « ou un artisan » et la liste des personnes dessous ; renseigne
-- self.<kind>Pinned = { all, group, caption } et self.<kind>ArtList.
-- `panel` peut être un PANNEAU (Récolte : coordonnées absolues, x/w = ALL_RX/ALL_RW par défaut) ou une
-- SECTION (Commande, blocs natifs : on passe alors x = marge du bloc et w = largeur utile du bloc).
-- opts.fill(ligne, donnée) remplit une ligne d'artisan ; opts.bottom = marge au bas du panneau, où la
-- liste s'arrête ; opts.caption = clé de la légende.
function UI:_BuildAllRowAndScroll(panel, kind, top, x, w, opts)
    x, w = x or ALL_RX, w or ALL_RW
    local function pick(t)   -- t = nil : la liste affichée entière (guilde / amis)
        return function()
            if kind == "post" then UI.postTarget = t or UI.postSource; UI:RefreshPostArtisans(); UI:RefreshPostPlans()
            else UI.gatherTarget = t or UI.gatherSrc; UI:_RefreshGatherArtisans() end
        end
    end
    -- PIN_GAP de pierre sous la bande « Envoyer à » (la maquette en laissait 6) : « Tous », choisie par
    -- défaut, collait sa surbrillance au filet de la bande, et les deux aplats clairs se confondaient —
    -- la bande ne se lisait plus comme un en-tête (capture du user, 2026-09-30).
    local all = pinnedRow(panel, w)
    all:SetPoint("TOPLEFT", x, top - PIN_GAP); all.icon:SetTexture(Skin.tex.broadcast)
    all.label:SetText(L["Tous (avec l'addon)"]); all:SetScript("OnClick", pick("all"))
    local grp = pinnedRow(panel, w)
    grp:SetPoint("TOPLEFT", all, "BOTTOMLEFT", 0, -2); grp:SetScript("OnClick", pick(nil))
    -- Légende « ou un artisan » + filet : sépare les destinataires collectifs des personnes.
    local cap = CreateFrame("Frame", nil, panel); cap:SetSize(w - LIST_BAR, 16)
    local cfs = cap:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    cfs:SetPoint("LEFT", 6, 0); cfs:SetText(opts.caption or "")
    local rule = cap:CreateTexture(nil, "ARTWORK"); rule:SetHeight(1); rule:SetColorTexture(1, 1, 1, 0.12)
    rule:SetPoint("LEFT", cfs, "RIGHT", 6, 0); rule:SetPoint("RIGHT", cap, "RIGHT", -4, 0)
    self[kind .. "Pinned"] = { all = all, group = grp, caption = cap }

    -- Liste défilante du kit (palier 2), toute la largeur : ses lignes s'arrêtent à LIST_BAR du bord,
    -- sous les lignes épinglées, et sa barre loge dans ce reste.
    -- Elle descend jusqu'à `opts.bottom` : figée à 4 lignes, elle défilait au-dessus d'un grand vide.
    local host = CreateFrame("Frame", nil, panel)
    host:SetPoint("TOPLEFT", cap, "BOTTOMLEFT", 0, -2)
    host:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", x, opts.bottom or 22)
    host:SetWidth(w)
    self[kind .. "ArtList"] = Skin.MakeScrollList(host, {
        extent = ALL_ARH,
        build  = Skin.ArtisanRowArt,
        fill   = opts.fill,
    })
end

-- Rafraîchit les lignes épinglées selon la liste affichée et le destinataire courant. La ligne de
-- groupe n'existe que pour une liste routable ; sans elle, la légende remonte sous « Tous ».
function UI:_RefreshAllRow(kind)
    local p = self[kind .. "Pinned"]; if not p then return end
    local src = (kind == "post") and (self.postSource or "guild") or (self.gatherSrc or "guild")
    local tgt = ((kind == "post") and self.postTarget or self.gatherTarget) or "all"
    local grp = Skin.RoutableGroup(src)
    p.all.selTex:SetShown(tgt == "all")
    p.group:SetShown(grp ~= nil)
    if grp then
        p.group.label:SetText(L[GROUP_LABEL[grp]]); paintGroupIcon(p.group.icon, grp)
        p.group.selTex:SetShown(tgt == grp)
    end
    p.caption:ClearAllPoints(); p.caption:SetPoint("TOPLEFT", grp and p.group or p.all, "BOTTOMLEFT", 0, -4)
end

-- La bande au-dessus de la liste (zone « scope » des SPEC) : « Envoyer à » à gauche ; à droite le menu
-- de la LISTE affichée, précédé de son mot — sans lui, « Guilde » se lisait comme le destinataire.
-- `onSelect(valeur)` applique Skin.TargetAfterListChange. Rend le menu.
function UI:_BuildRecipientBand(scope, ddName, pad, onSelect)
    local defs = {
        { value = "guild",  text = L["Guilde"] },
        { value = "friend", text = L["Amis"] },
        { value = "added",  text = L["Ajoutés"] },
        { value = "recent", text = L["Annuaire"] },
    }
    local send = scope:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    send:SetPoint("LEFT", pad, 0); send:SetText(L["Envoyer à"]); Skin.ApplyShadow(send)
    local dd = Skin.MakeDropdown(ddName, scope, 96, defs, { onSelect = onSelect })
    dd:SetPointVisual("RIGHT", scope, "RIGHT", -pad - LIST_BAR, 0)   -- au bout des lignes du dessous
    local lbl = scope:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lbl:SetPoint("RIGHT", dd, "LEFT", -6, 0); lbl:SetText(L["Liste"])
    lbl:SetTextColor(Skin.unpack(Skin.color.textMuted)); Skin.ApplyShadow(lbl)
    return dd
end

-- ------------------------------------------------------------------
-- Onglet CARNET (mes commandes, en table triable) → CraftingOrderClassic_UI_Ledger.lua
-- (BuildOrdersTab / RefreshOrders y sont définis depuis le palier 5 ; chargé après ce fichier).
-- ------------------------------------------------------------------

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
    elseif self.activeTab == "help" or self.activeTab == "news" then   -- pages figées ; leur barre se gère seule
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
