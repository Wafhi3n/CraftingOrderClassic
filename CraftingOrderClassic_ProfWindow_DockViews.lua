-- CraftingOrderClassic_ProfWindow_DockViews.lua — la colonne Commandes CHANGE DE CONTENU au lieu
-- d'ouvrir des fenêtres par-dessus. Trois vues, deux boutons dans son en-tête :
--   · Commandes (défaut)   · Plan de route   · Manquantes
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

-- view = nil (commandes) | "route" | "learn". Repasser la vue ACTIVE la referme : les deux boutons
-- sont des bascules, comme partout ailleurs dans COC.
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
    if view == "route" then self:_FillRoute()
    elseif view == "learn" then self:_FillDockMissing()
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
    -- Bas à 20 (au lieu de 46) : la colonne n'a pas la note d'estimation en pied de la fenêtre,
    -- seulement la case « inclure les plans ».
    self:_BuildRouteBody(rp, rp, "CraftingOrderDockRouteScroll", 20)

    -- Panneau MANQUANTES : liste simple, tout le détail en infobulle.
    local mp = CreateFrame("Frame", nil, host)
    mp:SetAllPoints(rp)
    mp:Hide()
    local hdr = mp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr:SetPoint("TOPLEFT", 8, -8); mp.hdr = hdr
    local scroll = CreateFrame("ScrollFrame", "CraftingOrderDockMissScroll", mp, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 6, -24); scroll:SetPoint("BOTTOMRIGHT", -26, 6)
    Skin.ScrollTrack("CraftingOrderDockMissScroll")
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(10, 1); scroll:SetScrollChild(content)
    mp.scroll, mp.content, mp.rows = scroll, content, {}
    local msg = mp:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    msg:SetPoint("CENTER", 0, 10); msg:SetWidth(180); msg:Hide(); mp.msg = msg
    self.missPanel = mp
end

-- ------------------------------------------------------------------
-- Vue « Manquantes »
-- ------------------------------------------------------------------

-- L'infobulle porte TOUT ce que la ligne n'a pas la place de dire. Priorité au texte du CLIENT
-- (autoritaire sur Forever, déjà traduit) ; notre nature déduite ne sert que de repli, et elle
-- s'annonce comme telle.
local function missTooltip(row)
    local S, prof, sid = COC.Sources, PW.profKey, row.sid
    if not (S and sid) then return end
    GameTooltip:SetOwner(row, "ANCHOR_LEFT")
    GameTooltip:SetText(row.rname or "?", 1, 1, 1, 1, true)
    GameTooltip:AddLine(string.format(L["Niveau requis : %d"], row.rlevel or 0), 0.6, 0.75, 0.91)
    local fromGame = S.SourceText and S:SourceText(prof, sid)
    if fromGame then
        GameTooltip:AddLine(fromGame, 0.91, 0.72, 0.29, true)
    else
        local kind = S:SourceKind(prof, sid)
        local txt = KIND_TEXT[kind] and KIND_TEXT[kind]() or L["Source inconnue"]
        if kind == "trainer" and S:IsInferred(prof, sid) then txt = txt .. " |cFF888888?|r" end
        GameTooltip:AddLine(txt, 0.91, 0.72, 0.29)
        local npc = S.SourceNpcLine and S:SourceNpcLine(prof, sid)
        if npc then GameTooltip:AddLine(npc, 0.8, 0.8, 0.8) end
    end
    local price = S.SourcePrice and S:SourcePrice(prof, sid)
    if price then GameTooltip:AddLine(L["Prix"] .. " : " .. COC.Api.Coin(price), 1, 1, 1) end
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
    local nm = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nm:SetPoint("LEFT", ic, "RIGHT", 4, 0); nm:SetJustifyH("LEFT"); row.nm = nm
    local lv = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    lv:SetPoint("RIGHT", -4, 0); row.lv = lv
    nm:SetPoint("RIGHT", lv, "LEFT", -4, 0)
    row:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight", "ADD")
    row:SetScript("OnEnter", missTooltip)
    row:SetScript("OnLeave", GameTooltip_Hide)
    mp.rows[i] = row
    return row
end

-- Toutes les manquantes du métier, du rang le plus BAS au plus haut : on lit une liste de
-- progression, pas un catalogue. Celles qu'on peut apprendre tout de suite sont en clair, les
-- autres grisées — la différence se voit sans rien cliquer.
function PW:_FillDockMissing()
    local mp = self.missPanel; if not mp then return end
    local S = COC.Sources
    local list = (S and S:MissingRecipes(self.profKey)) or {}
    table.sort(list, function(a, b)
        if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) < (b.level or 0) end
        return (a.name or "") < (b.name or "")
    end)
    local rank = COC.Craft and COC.Craft:OpenRank() or 0
    mp.hdr:SetText("|cFFE8B84B" .. string.format(L["Manquantes (%d)"], #list) .. "|r")
    mp.msg:SetShown(#list == 0)
    if #list == 0 then mp.msg:SetText(L["Rien ne manque dans ce métier."]) end
    local w = mp.scroll:GetWidth() or 0
    if w > 0 then mp.content:SetWidth(w) end
    for i, e in ipairs(list) do
        local row = missRow(i)
        row.sid, row.rname, row.rlevel = e.spellID, e.name, e.level
        row.ic:SetTexture(ICON[S:SourceKind(self.profKey, e.spellID)] or ICON.unknown)
        local reachable = (e.level or 0) <= rank
        row.ic:SetDesaturated(not reachable)
        row.nm:SetText((reachable and "" or "|cFF777777") .. (e.name or "?") .. (reachable and "" or "|r"))
        row.lv:SetText(tostring(e.level or 0))
        row:Show()
    end
    for i = #list + 1, #mp.rows do mp.rows[i]:Hide(); mp.rows[i].sid = nil end
    mp.content:SetHeight(math.max(#list * ROW_H, 1))
    Skin.AutoHideScroll("CraftingOrderDockMissScroll", mp.content)
end

-- ------------------------------------------------------------------
-- Les deux boutons de l'en-tête
-- ------------------------------------------------------------------

-- Les TROIS vues, dans l'ordre de lecture. À languettes et pas à interrupteurs, et c'est le fond du
-- sujet : trois états exclusifs dont un est TOUJOURS vrai ne se dessinent pas avec des bascules.
-- Deux icônes 16 px posées dans une bande vide se lisaient comme des boutons secondaires oubliés là,
-- et les désaturer pour dire « inactive » les faisait passer pour INDISPONIBLES (relevé sur capture
-- en jeu, 2026-09-19). Une languette sélectionnée dit la même chose sans ambiguïté, et c'est le
-- vocabulaire du jeu.
local VIEWS = {
    { id = "orders", label = function() return L["Commandes"] end },
    { id = "route",  label = function() return L["Plan de route"] end },
    { id = "learn",  label = function() return L["Manquantes"] end },
}

-- Construite par _BuildOrders (garde nil). Occupe la rangée du HAUT : les onglets de relation, eux,
-- descendent dans la vue Commandes à laquelle ils appartiennent (cf. _PlaceOrdTabs).
function PW:_BuildDockViewBtns()
    if self.viewTabs then return end
    local defs = {}
    for i, v in ipairs(VIEWS) do defs[i] = { id = v.id, label = v.label() } end
    self.viewTabs = Skin.MakeTabs(self.frame, defs, function(id)
        PW:_SetDockView(id ~= "orders" and id or nil)
    end, { tabX = 8, tabY = self:_TabTop(),
           namePrefix = (self.frame:GetName() or "COCWin") .. "View" })
    self.viewTabs:Select("orders")
    self:_HideViewTabs()
end

-- Re-posée à chaque changement de mode (_ApplyMode, sizeColumn) : la bande d'en-tête se referme une
-- fois la colonne encastrée, et la rangée doit remonter avec elle. Seule la PREMIÈRE languette porte
-- une ancre — les suivantes s'enchaînent sur elle.
function PW:_PlaceViewTabs()
    local bar = self.viewTabs
    local first = bar and bar.buttons[VIEWS[1].id]
    if not first then return end
    first:ClearAllPoints()
    first:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 8, self:_TabTop())
end

function PW:_HideViewTabs()
    for _, b in pairs((self.viewTabs and self.viewTabs.buttons) or {}) do b:Hide() end
end

-- Largeur RÉELLE de la rangée de vues, pour que la greffe dimensionne la colonne sur la PLUS LARGE
-- des deux rangées (cf. _ProfWindow_Camelot) : sinon la dernière languette se fait rogner par la
-- bordure, comme « Incoming » au premier essai du POC.
function PW:_ViewTabsWidth()
    local bar = self.viewTabs
    if not (bar and bar.buttons) then return 0 end
    local total, n = 0, 0
    for _, b in pairs(bar.buttons) do total = total + ((b.GetWidth and b:GetWidth()) or 0); n = n + 1 end
    if n == 0 then return 0 end
    return total - 4 * (n - 1) + 20
end

-- La rangée de vues n'existe que là où la colonne est SEULE et qu'un métier est ouvert : sans rang
-- courant il n'y a ni route à calculer ni manquantes à lister. Appelé par RefreshOrders, qui tourne
-- dans tous les modes.
function PW:_SyncDockViewBtns()
    local bar = self.viewTabs
    if not bar then return end
    local craft = COC.Craft
    local show = (self._compact or self.docked) and self.profKey and not self.rerollKey
        and craft and craft:GetOpenProfessionInfo() ~= nil
    for _, b in pairs(bar.buttons) do b:SetShown(show and true or false) end
    if not show then
        if self.dockView then self:_ResetDockView() end
        return
    end
    bar:Select(self.dockView or "orders")
    if self.dockView == "route" then self:_SyncRouteBtn() end
end
