-- CraftingOrderClassic_ProfWindow_DockViews.lua — la colonne Commandes CHANGE DE CONTENU au lieu
-- d'ouvrir des fenêtres par-dessus. Trois vues, deux boutons dans son en-tête :
--   · Commandes (défaut)   · Plan de route   · Manquantes
-- (la rangée de languettes qui les choisit vit dans _DockTabs.lua, la 4ᵉ vue dans _DockProfit.lua)
--
-- POURQUOI. Greffée dans la fenêtre native de Forever, la colonne est haute, étroite et le plus
-- souvent presque vide — « Orders (0) » et vingt centimètres de marbre. Faire surgir une fenêtre
-- flottante par-dessus elle pour montrer la route gaspillait deux fois la même place, et cassait
-- l'illusion que la colonne fait partie de la fenêtre du jeu. La place est déjà là : on s'en sert.
-- La largeur, elle, se rattrape par les INFOBULLES — une ligne affiche un nom et un rang, le détail
-- (source, PNJ, zone, prix) vit au survol.
--
-- En vue PLEINE (l'Era, 3 colonnes), rien de tout ça : la colonne Recettes occupe déjà l'espace et
-- la route garde sa fenêtre flottante. Ces vues n'existent que là où la colonne est SEULE.
--
-- ⚠️ LE COMBAT. Greffée, la colonne est enfant de `ProfessionsFrame` : elle en hérite la PROTECTION.
-- `Show`/`Hide` sur ses enfants sont donc refusés en combat (piège wow-protected-frame-hide-combat,
-- reconfirmé sur Forever). Changer de vue est un geste de confort, jamais urgent : on le refuse
-- franchement, avec un mot, plutôt que de laisser le jeu bloquer l'action sans explication.

local COC  = CraftingOrderClassic
local PW   = COC.ProfWindow
local Skin = COC.UI.Skin
local L    = COC.L

local ROW_H = 16

-- Icônes NATIVES de gossip, mêmes que la liste de recettes et la section « à apprendre ».
local ICON = {
    trainer = "Interface\\GossipFrame\\TrainerGossipIcon",
    vendor  = "Interface\\GossipFrame\\VendorGossipIcon",
    drop    = "Interface\\GossipFrame\\BattleMasterGossipIcon",
    quest   = "Interface\\GossipFrame\\ActiveQuestIcon",
    unknown = "Interface\\GossipFrame\\IncompleteQuestIcon",
}

local KIND_TEXT = {
    trainer = function() return L["Formateur"] end,
    vendor  = function() return L["Vendeur"] end,
    drop    = function() return L["Butin"] end,
    quest   = function() return L["Quête"] end,
}
PW._MissKindText = KIND_TEXT   -- le « où » en une ligne de la vue Profit dit la même nature (_DockMissing_Filter)

local MAP_ICON    = "Interface\\Icons\\INV_Misc_Map_01"
local SCROLL_ICON = "Interface\\Icons\\INV_Scroll_03"

local function lockedDown() return InCombatLockdown and InCombatLockdown() end

-- ------------------------------------------------------------------
-- Bascule de vue
-- ------------------------------------------------------------------

-- Les pièces de la vue COMMANDES : liste, pied de récap, et la barre d'onglets de relation (elle ne
-- parle que de commandes — la laisser affichée sur la route laisserait croire qu'elle filtre ce
-- qu'on regarde).
local function setOrdersShown(self, on)
    if self.ordScroll then self.ordScroll:SetShown(on) end
    if self.ordFoot then self.ordFoot:SetShown(on) end
    if self.ordLevelBtn then self.ordLevelBtn:SetShown(on) end
    -- Le filtre de relation a DEUX présentations selon le mode : sélecteur en colonne, languettes en
    -- vue pleine. En QUITTANT les Commandes on masque les deux — simple. Mais en Y REVENANT, il ne
    -- faut surtout pas les rallumer toutes les deux : seule `_PlaceOrdTabs` sait laquelle a cours.
    -- Le faire à sa place ressuscitait les anciennes languettes, qui reparaissaient AVEC leur ancre
    -- de vue pleine — donc posées HORS de la fenêtre, en plein décor (signalé en jeu 2026-09-20).
    -- Règle : un endroit décide de la présentation, les autres l'appellent.
    if self.ordRelDD then self.ordRelDD:Hide() end
    for _, b in pairs((self.ordRelTabs and self.ordRelTabs.buttons) or {}) do
        if b.Hide then b:Hide() end
    end
    if on and self._PlaceOrdTabs then self:_PlaceOrdTabs(self._compact) end
end

-- view = nil (commandes) | "route" | "learn" | "trade". Repasser la vue ACTIVE la referme : les deux
-- boutons sont des bascules, comme partout ailleurs dans COC. « trade » (mode Échange) n'a pas de
-- bouton : c'est _ProfWindow_Trade qui y entre et en sort, selon l'échange.
function PW:_SetDockView(view)
    if self.dockView == view then view = nil end
    if lockedDown() then
        print("|cFF33DD88Crafting Order|r " .. L["Impossible en combat — réessaie après le combat."])
        return
    end
    self.dockView = view
    self:_BuildDockViews()
    setOrdersShown(self, view == nil)
    if self.routePanel then self.routePanel:SetShown(view == "route") end
    if self.missPanel then self.missPanel:SetShown(view == "learn") end
    if view == "trade" and self._BuildTradeView then self:_BuildTradeView() end
    if self.tradePanel then self.tradePanel:SetShown(view == "trade") end
    if self.profitPanel then self.profitPanel:SetShown(view == "profit") end
    if view == "route" then self:_FillRoute()
    elseif view == "learn" then self:_FillDockMissing()
    elseif view == "trade" then self:_FillTradeView()
    elseif view == "profit" then self:_FillDockProfit()
    else self:RefreshOrders() end
    self:_SyncDockViewBtns()
end

-- Retour forcé à la vue Commandes quand la colonne change de mode (retour en vue pleine, vue
-- reroll, métier refermé). Sans ça, les panneaux restaient AFFICHÉS par-dessus la colonne dans un
-- mode où leurs boutons n'existent plus : plus aucun moyen de revenir en arrière.
-- En combat on ne touche à rien (cf. l'en-tête) ; le drapeau, lui, tombe tout de suite, et la
-- prochaine synchro hors combat remettra l'affichage d'aplomb.
function PW:_ResetDockView()
    self.dockView = nil
    if lockedDown() then return end
    if self.routePanel then self.routePanel:Hide() end
    if self.missPanel then self.missPanel:Hide() end
    if self.tradePanel then self.tradePanel:Hide() end
    if self.profitPanel then self.profitPanel:Hide() end
    setOrdersShown(self, true)
end

-- ------------------------------------------------------------------
-- Construction paresseuse des deux panneaux
-- ------------------------------------------------------------------

function PW:_BuildDockViews()
    if self.routePanel or not self.ordScroll then return end
    local host = self.ordScroll:GetParent()

    -- Panneau ROUTE : le MÊME corps que la fenêtre flottante (cf. PW:_BuildRouteBody), donc le même
    -- peintre, les mêmes pools et le même comportement. Seul le contenant change.
    -- Calés sur le HAUT de la zone, pas sur le scroll des commandes : la ligne d'en-tête de la liste
    -- (onglets de relation + tri) est masquée dans ces deux vues, leur réserver 22 px y rouvrait le
    -- même trou qu'en haut de colonne.
    local rp = CreateFrame("Frame", nil, host)
    rp:SetPoint("TOPLEFT", host, "TOPLEFT", 0, -PW.TUNE.viewTop)
    rp:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, 0)
    rp:Hide()
    self.routePanel = rp
    -- Même pied que la fenêtre (note d'estimation + deux cases) : il passait 20, croyant la note
    -- absente de la colonne, et la case des plans débordait sur la liste.
    self:_BuildRouteBody(rp, rp)

    -- Panneau MANQUANTES : liste simple, tout le détail en infobulle. Son en-tête porte le menu des
    -- catégories à droite (_DockMissing_Filter) ; le titre a une gauche et une droite sur la MÊME
    -- ligne que lui, et se tronque par « … » plutôt que de passer dessous.
    local mp = CreateFrame("Frame", nil, host)
    mp:SetAllPoints(rp)
    mp:Hide()
    if self._BuildMissFilter then self:_BuildMissFilter(mp) end
    local hdr = mp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr:SetPoint("LEFT", mp, "TOPLEFT", 8, -13)
    if mp.dd then hdr:SetPoint("RIGHT", mp.dd, "LEFT", -6, 0) end
    hdr:SetJustifyH("LEFT"); hdr:SetWordWrap(false); mp.hdr = hdr
    local scroll = Skin.MakeScrollFrameIn(mp)   -- barre fine, se cache seule (palier 7c)
    scroll:SetPoint("TOPLEFT", 6, -24); scroll:SetPoint("BOTTOMRIGHT", -26, 6)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(10, 1); scroll:SetScrollChild(content)
    mp.scroll, mp.content, mp.rows = scroll, content, {}
    local msg = mp:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    msg:SetPoint("CENTER", 0, 10); msg:SetWidth(180); msg:Hide(); mp.msg = msg
    self.missPanel = mp

    -- Panneau RENTABILITÉ : même contenant, même gabarit, son propre fichier (_DockProfit).
    -- Construit ici pour que les trois panneaux naissent dans la même passe et partagent l'ancre —
    -- un 4ᵉ panneau posé ailleurs finirait par dériver de 2 px et personne ne saurait pourquoi.
    if self._BuildDockProfit then self:_BuildDockProfit(host, rp) end
end

-- ------------------------------------------------------------------
-- Vue « Manquantes »
-- ------------------------------------------------------------------

-- L'infobulle porte TOUT ce que la ligne n'a pas la place de dire, et elle répond à DEUX questions
-- qu'il ne faut pas confondre : « qu'est-ce que c'est, et est-ce que ça vaut le coup ? », à quoi le
-- CLIENT répond même sur une recette pas apprise ; et « où je vais le chercher ? », à quoi il ne
-- répond pas du tout sur cette saveur (cf. Craft:MainlineRecipeFacts) — ça, c'est notre catalogue.

-- Fiche CLIENT de la recette (lien de l'objet produit, couleur, points), ou nil hors mainline.
local function factsOf(sid)
    local C = COC.Craft
    return (C and C.RecipeFacts) and C:RecipeFacts(sid) or nil
end

-- En-tête : l'objet PRODUIT, avec son infobulle NATIVE. Devant une recette qu'on n'a pas, la
-- première question est « ça fait quoi ? », et le jeu y répond mieux que nous (buff de cuisine,
-- stats, niveau de l'objet). Le client rend ce lien même sur une recette NON APPRISE. Sans lui
-- (Era, ou recette hors de la ligne ouverte) on retombe sur le nom seul, comme avant.
local function missHead(row, facts)
    -- ⚠️ `SetHyperlink` SOUS pcall, comme les six autres appels du dépôt. Un lien que le client
    -- refuse leve une erreur, et ici on est dans le `OnEnter` d'une ligne de liste : l'erreur
    -- emporterait tout ce qui suit dans l'infobulle -- le rang, les points, la source, le prix --
    -- ET le `Show()` final. Le joueur verrait une infobulle vide sans savoir pourquoi.
    if facts and facts.link and pcall(GameTooltip.SetHyperlink, GameTooltip, facts.link) then
        GameTooltip:AddLine(" ")
    else
        GameTooltip:SetText(row.rname or "?", 1, 1, 1, 1, true)
    end
end

-- « Il me manque combien, et est-ce que ça me fera encore progresser ? » Le rang requis vient du
-- catalogue ; le VERDICT vient du client, qui donne la couleur et le nombre de points AU RANG
-- COURANT, y compris sur une recette pas apprise. Nos seuils générés ne sont plus consultés ici :
-- deux réponses qui peuvent diverger valent moins qu'une.
local function missWorth(row, facts)
    local lvl  = row.rlevel
    local rank = (COC.Craft and COC.Craft.OpenRank) and COC.Craft:OpenRank() or nil
    if not lvl then
        -- On ne le sait pas, on le dit. Le client, lui, répond quand même sur la difficulté.
        GameTooltip:AddLine(L["Niveau requis : inconnu (la donnée manque pour cette recette)"],
            0.6, 0.75, 0.91, true)
        if not (facts and facts.difficulty) then return end
        return
    end
    local miss = (rank and lvl > rank) and (lvl - rank) or nil
    GameTooltip:AddLine(string.format(L["Niveau requis : %d"], lvl)
        .. (miss and (" |cFFFF6666" .. string.format(L["il t'en manque %d"], miss) .. "|r") or ""),
        0.6, 0.75, 0.91)
    if not (facts and facts.difficulty) then return end
    if facts.skillUps > 0 then
        local r, g, b = COC.Craft:DifficultyColor(facts.difficulty)
        GameTooltip:AddLine(string.format(L["+%d point de métier"], facts.skillUps), r, g, b)
    else
        GameTooltip:AddLine(L["Ne rapporte plus de point"], 0.5, 0.5, 0.5)
    end
end

-- Le « où aller ». Priorité au texte du CLIENT (autoritaire sur Forever, déjà traduit) ; notre
-- nature déduite ne sert que de repli, et elle s'annonce comme telle.
local function missWhere(prof, sid)
    local S = COC.Sources
    local fromGame = S.SourceText and S:SourceText(prof, sid)
    if fromGame then GameTooltip:AddLine(fromGame, 0.91, 0.72, 0.29, true); return end
    local kind = S:SourceKind(prof, sid)
    local txt = KIND_TEXT[kind] and KIND_TEXT[kind]() or L["Source inconnue"]
    if kind == "trainer" and S:IsInferred(prof, sid) then txt = txt .. " |cFF888888?|r" end
    GameTooltip:AddLine(txt, 0.91, 0.72, 0.29)
    -- L'ORIGINE, pas seulement le marchand : la créature qui lâche le plan et la quête qui le donne
    -- répondent aussi à « où je vais le chercher ? ». La nature est écrite juste au-dessus, donc la
    -- ligne peut rester un nom nu sans qu'on confonde « aller voir » et « aller tuer ».
    -- La garde SORT de l'assignation, et la fonction rend une TABLE : deux ceintures pour le même
    -- piège. Écrit `local a, b = S.f and S:f()`, `b` était toujours nil et le clic ne marchait pas.
    if not S.SourceOrigin then return nil end
    local origin = S:SourceOrigin(prof, sid)
    if not origin then return nil end
    GameTooltip:AddLine(origin.text, 0.8, 0.8, 0.8)
    return origin.pin
end
-- La même rédaction dans l'infobulle d'une recette pas apprise de la vue Profit (décision 19 de
-- docs/specs/rentabilite-forever.md). Rend le repère SEUL, jamais plusieurs valeurs.
PW._MissWhere = missWhere

local function missTooltip(row)
    -- Le métier vient de la LIGNE, pas de `PW.profKey` : le joueur peut changer d'onglet de métier
    -- entre le remplissage et le survol, et une ligne de Cuisine interrogée comme de l'Herboristerie
    -- répond « source inconnue » avec aplomb (relevé en jeu 2026-09-20). Une ligne et sa clé de
    -- métier partent ensemble ou pas du tout.
    local S, prof, sid = COC.Sources, row.prof or PW.profKey, row.sid
    if not (S and sid) then return end
    local facts = factsOf(sid)
    row.rlink = facts and facts.link or nil   -- mémorisé ici pour le shift-clic (cf. missRow)
    GameTooltip:SetOwner(row, "ANCHOR_LEFT")
    missHead(row, facts)
    missWorth(row, facts)
    row.pin = missWhere(prof, sid)
    -- Plan dont l'objet est demandé par un writ (D13 de writs-aca.md) : le détail de la vue Profit.
    if row.writ and PW._AddWritLines then PW._AddWritLines(row.writ) end
    local price = S.SourcePrice and S:SourcePrice(prof, sid)
    if price then GameTooltip:AddLine(L["Prix"] .. " : " .. COC.Api.Coin(price), 1, 1, 1) end
    -- L'invite n'apparait que s'il y a vraiment un repere a poser : annoncer un clic qui ne fait
    -- rien est pire que de ne rien annoncer.
    if row.pin then GameTooltip:AddLine(L["Clic : poser un repère sur ce PNJ."], 0.55, 0.75, 0.55) end
    GameTooltip:Show()
end

local function missRow(i)
    local mp = PW.missPanel
    local row = mp.rows[i]
    if row then return row end
    row = CreateFrame("Button", nil, mp.content)
    row:SetHeight(ROW_H)
    row:SetPoint("LEFT", mp.content, "LEFT", 0, 0)
    row:SetPoint("RIGHT", mp.content, "RIGHT", 0, 0)
    row:SetPoint("TOP", mp.content, "TOP", 0, -(i - 1) * ROW_H)
    local ic = row:CreateTexture(nil, "ARTWORK"); ic:SetSize(12, 12); ic:SetPoint("LEFT", 2, 0); row.ic = ic
    -- UNE ligne, tronquée par « … » : vu le 2026-10-02, « Enchant Cloak - Lesser Shadow Resistance »
    -- passait à la ligne et mordait sur la suivante (même piège que la vue Profit, coc-native-ui
    -- piège 28). Le nom entier reste dans l'infobulle (missHead).
    local nm = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nm:SetPoint("LEFT", ic, "RIGHT", 4, 0); nm:SetJustifyH("LEFT"); nm:SetWordWrap(false); row.nm = nm
    local lv = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    lv:SetPoint("RIGHT", -4, 0); row.lv = lv
    -- La marque d'un writ, entre le nom et le rang ; cachée tant qu'aucun writ ne demande l'objet.
    local wr = row:CreateTexture(nil, "ARTWORK"); wr:SetSize(12, 12)
    wr:SetPoint("RIGHT", lv, "LEFT", -3, 0); wr:Hide(); row.wr = wr
    nm:SetPoint("RIGHT", lv, "LEFT", -4, 0)
    row:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight", "ADD")
    row:SetScript("OnEnter", missTooltip)
    row:SetScript("OnLeave", GameTooltip_Hide)
    -- Cette ligne écrit ses propres lignes de writ : l'accroche d'infobulle d'objet (_Writs_Tooltip)
    -- se tait sur elle, sinon elles sortiraient deux fois.
    row.cocWritTip = true
    -- Shift-clic = lier l'objet produit en chat, comme n'importe quelle ligne de recette du jeu.
    -- Le lien est posé au SURVOL (missTooltip) : on ne clique pas une ligne sans l'avoir survolée,
    -- et ça évite un `GetRecipeInfo` par ligne à chaque remplissage de la liste.
    -- Deux gestes sur la meme ligne : Maj pour lier l'objet en chat, clic simple pour poser le
    -- repere sur le PNJ. Les deux s'appuient sur ce que le SURVOL a resolu (cf. missTooltip) -- on
    -- ne clique pas une ligne sans l'avoir survolee, et ca evite de calculer tout ca par ligne a
    -- chaque remplissage de la liste.
    row:RegisterForClicks("LeftButtonUp")
    row:SetScript("OnClick", function(r)
        if IsShiftKeyDown() then
            if r.rlink and ChatEdit_InsertLink then ChatEdit_InsertLink(r.rlink) end
        elseif r.pin and PW._SetNpcPin then
            PW:_SetNpcPin(r.pin)
        end
    end)
    mp.rows[i] = row
    return row
end

-- Toutes les manquantes du métier, du rang le plus BAS au plus haut : on lit une liste de
-- progression, pas un catalogue. Celles qu'on peut apprendre tout de suite sont en clair, les
-- autres grisées — la différence se voit sans rien cliquer.
function PW:_FillDockMissing()
    local mp = self.missPanel; if not mp then return end
    local S = COC.Sources
    local all = (S and S:MissingRecipes(self.profKey)) or {}
    -- Le filtre de l'en-tête (_DockMissing_Filter) : la liste AFFICHÉE, celle que le titre compte.
    local list = self._MissFilterApply and self:_MissFilterApply(mp, all) or all
    -- Niveau inconnu = EN FIN de liste, jamais en tête : trié comme un 0, il passait devant tout ce
    -- que le joueur peut réellement apprendre (vécu en Couture, 8 recettes sans niveau).
    table.sort(list, function(a, b)
        if (a.level == nil) ~= (b.level == nil) then return b.level == nil end
        if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) < (b.level or 0) end
        return (a.name or "") < (b.name or "")
    end)
    local rank = COC.Craft and COC.Craft:OpenRank() or 0
    mp.hdr:SetText("|cFFE8B84B" .. string.format(L["Manquantes (%d)"], #list) .. "|r")
    mp.msg:SetShown(#list == 0)
    if #list == 0 then mp.msg:SetText(L["Rien ne manque dans ce métier."]) end
    local w = mp.scroll:GetWidth() or 0
    if w > 0 then mp.content:SetWidth(w) end
    -- Les writs que je porte, lus UNE fois pour toute la liste (comme la vue Profit).
    local W, mark = COC.Writs, PW._MissMarkWrit
    local wanted = (W and mark and #list > 0) and W:WantedItems() or nil

    for i, e in ipairs(list) do
        local row = missRow(i)
        row.sid, row.rname, row.rlevel = e.spellID, e.name, e.level
        row.rlink, row.pin = nil, nil   -- ligne poolée : rien de la précédente ne survit
        row.prof = self.profKey   -- la ligne emporte le métier qui l'a produite (cf. missTooltip)
        row.ic:SetTexture(ICON[S:SourceKind(self.profKey, e.spellID)] or ICON.unknown)
        if mark then mark(row, e.itemID, wanted) end
        -- Trois états, pas deux : à portée, hors de portée (grisée), et NIVEAU INCONNU — celle-là
        -- n'est pas grisée (on ne sait pas), mais son « ? » dit qu'on ne promet rien.
        local outOfReach = e.level ~= nil and e.level > rank
        row.ic:SetDesaturated(outOfReach)
        row.nm:SetText((outOfReach and "|cFF777777" or "") .. (e.name or "?") .. (outOfReach and "|r" or ""))
        row.lv:SetText(e.level and tostring(e.level) or "|cFF777777?|r")
        row:Show()
    end
    for i = #list + 1, #mp.rows do mp.rows[i]:Hide(); mp.rows[i].sid = nil end
    mp.content:SetHeight(math.max(#list * ROW_H, 1))
end
