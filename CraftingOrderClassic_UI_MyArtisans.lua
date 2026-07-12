-- CraftingOrderClassic_UI_MyArtisans.lua — onglet « Mes artisans » : vue agrégée des métiers du
-- COMPTE (tous mes rerolls du royaume), en mode « connu ». 100 % LOCAL (lit ma SavedVariable via
-- Dir:AggregateMyProfs, aucun réseau, marche même avec /co alts off). Deux zones (patron Récolte) :
-- à gauche le sélecteur de métiers du compte, à droite les recettes connues du métier choisi + les
-- persos qui les portent. Chargé après UI_Artisans_Groups.lua (réutilise Skin/CraftLink).

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local PLH = 34    -- hauteur ligne métier (gauche)
local RLH = 18    -- hauteur ligne recette (droite)

local SEP   = 300
local LW    = SEP - 14
local RX    = SEP + 8
local RW    = 818 - RX

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end
local function sep1px(parent, x, y, w, h)
    local s = parent:CreateTexture(nil, "ARTWORK")
    s:SetColorTexture(Skin.color.separator[1], Skin.color.separator[2], Skin.color.separator[3], 0.5)
    s:SetSize(w, h); s:SetPoint("TOPLEFT", x, y); return s
end

-- =========================================================================
-- Construction
-- =========================================================================
function UI:BuildMyArtisansTab(f)
    local panel = CreateFrame("Frame", nil, f); self.insetPanel(panel, f); panel:Hide()
    self.myArtisansPanel = panel
    self.myArtSelProf = nil

    self:_BuildMyArtHeader(panel)          -- bandeau : activer le partage + choix de la vitrine
    sep1px(panel, SEP, -110, 1, 466)

    local lhdr = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    lhdr:SetPoint("TOPLEFT", 14, -108); lhdr:SetText(L["MÉTIERS DU COMPTE"])
    lhdr:SetTextColor(Skin.unpack(Skin.color.textMuted))

    -- « Tous les plans du royaume » : au-dessus de la liste des métiers, car c'est une ALTERNATIVE à
    -- la sélection d'un métier (on sort du découpage par métier), pas une option de la vue de droite.
    local allBtn = Skin.MakeGoldButton(panel, LW - 22, 20, L["Tous les plans du royaume"])
    allBtn:SetPoint("TOPLEFT", 12, -124); self.myArtAllBtn = allBtn
    allBtn:SetScript("OnClick", function()
        if not (COC.LazyGold and COC.LazyGold:IsAvailable()) then return end
        UI.myArtAllProfs = not UI.myArtAllProfs
        UI:RefreshMyArtisans()
    end)

    local lscroll = CreateFrame("ScrollFrame", "COCMyArtProfScroll", panel, "UIPanelScrollFrameTemplate")
    lscroll:SetPoint("TOPLEFT", 12, -150); lscroll:SetPoint("BOTTOMLEFT", 12, 22); lscroll:SetWidth(LW - 22)
    local lc = CreateFrame("Frame", nil, lscroll); lc:SetSize(LW - 24, 10); lscroll:SetScrollChild(lc)
    self.myArtProfContent = lc; self.myArtProfRows = {}

    local rhdr = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rhdr:SetPoint("TOPLEFT", RX, -108); Skin.ApplyShadow(rhdr); self.myArtDetailHdr = rhdr

    -- Bascule « recettes manquantes » : mêmes codes que la vue métier. Le manquant est calculé ICI à
    -- partir du catalogue CraftLink moins ce que le reroll connaît — surtout PAS via MTSL, dont les
    -- MISSING_SKILLS ne valent que pour le perso CONNECTÉ (faux pour un reroll).
    self.myArtMissing = false
    local mBtn = Skin.MakeGoldButton(panel, 110, 18, "")
    mBtn:SetPoint("TOPRIGHT", -30, -106); self.myArtMissBtn = mBtn
    mBtn:SetScript("OnClick", function()
        UI.myArtMissing = not UI.myArtMissing
        UI:RefreshMyArtisans()
    end)

    -- Barre Lazy Gold (pièce / « 123 » / « Tout le royaume »), à gauche du bouton Manquantes.
    self:_BuildMyArtLGBar(panel, mBtn)

    local rscroll = CreateFrame("ScrollFrame", "COCMyArtRecScroll", panel, "UIPanelScrollFrameTemplate")
    rscroll:SetPoint("TOPLEFT", RX, -128); rscroll:SetPoint("BOTTOMRIGHT", -30, 22)
    local rc = CreateFrame("Frame", nil, rscroll); rc:SetSize(RW - 24, 10); rscroll:SetScrollChild(rc)
    self.myArtRecContent = rc; self.myArtRecRows = {}
end

-- Bandeau haut : case à cocher opt-in « partager mes rerolls » (délègue à Dir:AltsCmd on/off, qui
-- gère défaut du main + annonce/dissolution) + bouton « Vitrine : Nom » ouvrant un flyout des persos
-- du compte pour choisir le perso principal. Toute la logique réseau/sécurité reste dans Directory_Alts.
function UI:_BuildMyArtHeader(panel)
    local chk = CreateFrame("Button", nil, panel); chk:SetPoint("TOPLEFT", 14, -74)
    local box = Skin.MakeCheck(chk, 16); box:SetPoint("LEFT", 0, 0)
    local fs = chk:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("LEFT", box, "RIGHT", 5, 0); fs:SetText(L["Partager mes rerolls sur le réseau"])
    fs:SetTextColor(Skin.unpack(Skin.color.text)); Skin.ApplyShadow(fs)
    chk:SetSize(21 + fs:GetStringWidth() + 4, 18)
    chk:SetScript("OnClick", function()
        local on = not (COC.db and COC.db.altsEnabled)
        local D = COC.Directory
        if D and D.AltsCmd then D:AltsCmd(on and "on" or "off") end
        UI:RefreshMyArtisans()
    end)
    self.myArtEnableBox = box

    local mainBtn = Skin.MakeGoldButton(panel, 190, 20, "—"); mainBtn:SetPoint("TOPRIGHT", -30, -73)
    mainBtn.text:ClearAllPoints(); mainBtn.text:SetPoint("LEFT", 8, 0); mainBtn.text:SetJustifyH("LEFT")
    local arrow = mainBtn:CreateTexture(nil, "OVERLAY"); arrow:SetSize(14, 14)
    arrow:SetPoint("RIGHT", -4, 0); arrow:SetTexture(Skin.tex.arrowDown)
    mainBtn:SetScript("OnClick", function() UI:_ToggleMyArtMainFlyout() end)
    self.myArtMainBtn = mainBtn

    self.myArtMainFlyout = Skin.MakeFlyout("COCMyArtMainFlyout", 190)

    sep1px(panel, 12, -100, 822, 1)
end

-- Ouvre/ferme le flyout de choix du perso principal (vitrine). Liste = mes persos du royaume
-- (Dir:_MyAltNames) ; clic → Dir:AltsCmd("main X") (revalide que c'est bien un de mes persos).
function UI:_ToggleMyArtMainFlyout()
    local fly = self.myArtMainFlyout; if not fly then return end
    if fly:IsShown() then fly:Hide(); return end
    local D = COC.Directory
    local names = (D and D._MyAltNames and D:_MyAltNames()) or {}
    if not names[1] then return end
    for n, nm in ipairs(names) do
        local row = fly:Row(n)
        row:SetText(nm)
        row:SetScript("OnClick", function()
            if D and D.AltsCmd then D:AltsCmd("main " .. nm) end
            fly:Hide(); UI:RefreshMyArtisans()
        end)
    end
    fly:SetCount(#names)
    fly:ToggleAt("TOPRIGHT", self.myArtMainBtn, "BOTTOMRIGHT", 0, -2)
end

-- Recale le bandeau sur l'état réel (coche + libellé vitrine) — le bouton vitrine n'a de sens que
-- si le partage est actif (masqué sinon).
function UI:_SyncMyArtHeader()
    local on = COC.db and COC.db.altsEnabled
    if self.myArtEnableBox then self.myArtEnableBox:SetChecked(on and true or false) end
    if self.myArtMainBtn then
        self.myArtMainBtn:SetShown(on and true or false)
        self.myArtMainBtn:SetText(string.format(L["Vitrine : %s"], (COC.db and COC.db.altMain) or "?"))
    end
    if not on and self.myArtMainFlyout then self.myArtMainFlyout:Hide() end
end

-- =========================================================================
-- Zone gauche : lignes de métier
-- =========================================================================
function UI:_MyArtProfRow(i)
    local r = self.myArtProfRows[i]; if r then return r end
    local lc = self.myArtProfContent
    r = CreateFrame("Button", nil, lc); r:SetSize(LW - 24, PLH); r:SetPoint("TOPLEFT", 0, -(i - 1) * PLH)
    local hi = r:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints(); hi:SetColorTexture(Skin.unpack(Skin.color.rowHover))
    local st = r:CreateTexture(nil, "BACKGROUND"); st:SetAllPoints()
    st:SetColorTexture(Skin.color.tabActive[1], Skin.color.tabActive[2], Skin.color.tabActive[3], 0.30)
    st:Hide(); r.selTex = st
    r.badge = Skin.MakeBadge(r, 22); r.badge:SetPoint("LEFT", 6, 0)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    r.name:SetPoint("TOPLEFT", 34, -5); r.name:SetWidth(LW - 70); r.name:SetJustifyH("LEFT"); Skin.ApplyShadow(r.name)
    r.sub = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.sub:SetPoint("TOPLEFT", 34, -19); r.sub:SetWidth(LW - 70); r.sub:SetJustifyH("LEFT"); Skin.ApplyShadow(r.sub)
    self.myArtProfRows[i] = r; return r
end

-- Nb de persos porteurs + libellé « porté par : A, B » (pour la sous-ligne / détail).
local function bearers(e)
    local names = {}
    for _, c in ipairs(e.chars) do names[#names + 1] = c.name end
    return table.concat(names, ", ")
end

function UI:_FillMyArtProfRow(row, e, selected)
    local pl = Skin.ProfLabel(e.profKey)
    row.badge:Paint(Skin.color.gold[1], Skin.color.gold[2], Skin.color.gold[3], Skin.FirstChar(pl), Skin.ProfIcon(e.profKey))
    local lvl = e.bestRank > 0 and (e.bestRank .. "/" .. e.bestMax) or L["niv ?"]
    row.name:SetText("|cFFFFFFFF" .. Skin.ProfLabel(e.profKey) .. "|r  |cFF888888" .. lvl .. "|r")
    local nrec = 0; for _ in pairs(e.known) do nrec = nrec + 1 end
    row.sub:SetText("|cFF888888" .. string.format(L["%d recettes"], nrec)
        .. "  ·  " .. bearers(e) .. "|r")
    row.selTex:SetShown(selected)
    row:SetScript("OnClick", function() UI.myArtSelProf = e.profKey; UI:RefreshMyArtisans() end)
    row:Show()
end

-- =========================================================================
-- Zone droite : recettes connues du métier sélectionné
-- =========================================================================
-- Rangée polyvalente (patron ProfWindow_Recipes) : header de section (doré, sans icône), ligne de
-- recette (icône + nom + niveau requis + porteurs), ou ligne de cooldown (icône horloge + label).
function UI:_MyArtRecRow(i)
    local r = self.myArtRecRows[i]; if r then return r end
    r = CreateFrame("Frame", nil, self.myArtRecContent); r:SetSize(RW - 24, RLH); r:SetPoint("TOPLEFT", 0, -(i - 1) * RLH)
    r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(14, 14); r.icon:SetPoint("LEFT", 2, 0)
    r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.name:SetJustifyH("LEFT"); Skin.ApplyShadow(r.name)
    -- Rentabilité Lazy Gold, tout à droite ; « porté par » se cale à sa gauche.
    r.profit = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.profit:SetPoint("RIGHT", -6, 0); r.profit:SetJustifyH("RIGHT"); Skin.ApplyShadow(r.profit)
    r.who = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.who:SetPoint("RIGHT", r.profit, "LEFT", -6, 0); r.who:SetJustifyH("RIGHT"); r.who:SetWidth(120); Skin.ApplyShadow(r.who)
    r:EnableMouse(true); Skin.WireItemTooltip(r)   -- tooltip d'objet/sort (lit tipItemID/tipSpellID)
    self.myArtRecRows[i] = r; return r
end

-- Ancre le libellé (nom) : après l'icône (x=20) ou collé au bord (header, x=4), largeur bornée pour
-- ne pas chevaucher « porté par » ni la colonne de profit. SetPoint répété empile les ancres
-- → ClearAllPoints. `reserve` = place prise à droite par le profit (0 si la ligne n'en a pas).
local function anchorName(row, x, reserve)
    row.name:ClearAllPoints()
    row.name:SetPoint("LEFT", x, 0)
    row.name:SetWidth(math.max(20, RW - 24 - x - 126 - (reserve or 0)))
end

-- Profit Lazy Gold d'une ligne (mémorisé le temps du refresh). Renvoie la largeur consommée, pour
-- que le nom se rétrécisse d'autant.
function UI:_FillMyArtProfit(row, rc)
    local LG = COC.LazyGold
    local txt = LG and LG:ProfitText(self:_MyArtProfit(rc)) or ""
    row.profit:SetText(txt)
    row.profit:SetShown(txt ~= "")
    return (txt ~= "") and (row.profit:GetStringWidth() + 6) or 0
end

-- Persos du compte qui connaissent CE spellID (colonne « porté par »).
local function knowersOf(e, sid)
    local out = {}
    for _, c in ipairs(e.chars) do if c.known[sid] then out[#out + 1] = c.name end end
    return table.concat(out, ", ")
end

-- Une entrée de recette (connue ou manquante). `who` et `profKey` sont figés à la construction : en
-- mode « tout le royaume » la ligne n'a plus de métier de contexte, elle doit se suffire à elle-même.
local function recEntryOf(e, sid, missing)
    local c = CL()
    local itemID = c and c:RecipeProduct(e.profKey, sid)
    local nm = (c and c:RecipeName(sid)) or (c and itemID and c:ItemName(itemID)) or ("spell:" .. sid)
    return { sid = sid, name = nm, itemID = itemID, missing = missing, profKey = e.profKey,
             who = missing and "" or knowersOf(e, sid),
             at = c and c:RecipeLearnedAt(e.profKey, sid) }
end

-- Bandeau cooldowns EN HAUT : une ligne par CD actif et par perso porteur (« Transmutation : dans
-- 14h — Qellorran »). Réutilise Social:CooldownLines sur une entrée SYNTHÉTIQUE {cooldowns=…} bâtie
-- depuis MA partition db.myCooldowns[Nom-Royaume], filtrée au métier sélectionné.
function UI:_MyArtCooldownItems(e)
    local So, db = COC.Social, COC.db
    if not (So and So.CooldownLines and db and db.myCooldowns) then return {} end
    local items = {}
    for _, c in ipairs(e.chars) do
        local part = c.key and db.myCooldowns[c.key]
        if part then
            for _, ln in ipairs(So:CooldownLines({ cooldowns = part }, nil, e.profKey) or {}) do
                items[#items + 1] = { cd = true, text = ln.text, ready = ln.ready, who = c.name }
            end
        end
    end
    return items
end

-- Construit la liste d'affichage : [bandeau CD] puis recettes groupées SECTION > SOUS-CATÉGORIE par
-- le moteur partagé (COC.RecipeCats:BuildDisplay) — mêmes catégories que la vue métier et l'onglet
-- Commande. Pas de repliage ici : les lignes de ce pool sont des Frame (non cliquables), contrairement
-- aux deux autres listes. Chaque élément = { cd | en-tête | recette }.
-- Produits du métier qui n'ont PAS de recette : essences/poussières/éclats de désenchantement,
-- poissons, minerais… On ne les FABRIQUE pas (aucun spellID), mais ils se vendent — et un métier
-- comme la Pêche n'a QUE ça. Règle unique : toute entrée du catalogue avec un itemID et sans
-- spellID. Ils appartiennent à quiconque a le métier, donc pas de filtre « connu ».
-- Skin.ItemExists écarte les objets ABSENTS du client (poissons TBC/WotLK dans le catalogue commun :
-- sur un client Era leur nom ne se résout pas et on afficherait « item:41800 »).
local function itemOnlyEntries(e)
    local c = CL()
    local out = {}
    for _, it in ipairs((c and c:ProfessionCatalogue(e.profKey)) or {}) do
        if it.itemID and not it.spellID and Skin.ItemExists(it.itemID) then
            local nm = c:ItemName(it.itemID)
            local who = {}
            for _, ch in ipairs(e.chars) do who[#who + 1] = ch.name end
            out[#out + 1] = { itemID = it.itemID, name = nm, profKey = e.profKey,
                              noSpell = true, who = table.concat(who, ", ") }
        end
    end
    return out
end

-- Recettes du métier que ce reroll NE connaît PAS = catalogue CraftLink moins e.known. Calcul local
-- et exact pour N'IMPORTE quel perso du compte (MTSL, lui, ne sait répondre que pour le connecté).
function UI:_MyArtMissing(e)
    if not self.myArtMissing then return 0 end
    local c = CL()
    local n = 0
    for _, sid in ipairs((c and c:GetRecipes(e.profKey)) or {}) do
        if not e.known[sid] then n = n + 1 end
    end
    return n
end

-- `profs` = tous les métiers du compte (utilisé seulement en mode « tout le royaume »).
function UI:_MyArtDisplayList(e, profs)
    -- « Tout le royaume » : liste à plat inter-métiers, triée par profit. Pas de bandeau CD (il est
    -- propre à un métier), pas de sections (le tri global est justement ce qu'on veut voir).
    if self.myArtAllProfs then return self:_MyArtAllList(profs or { e }, recEntryOf, itemOnlyEntries) end

    local c = CL()
    local recs = {}
    for sid in pairs(e.known) do recs[#recs + 1] = recEntryOf(e, sid, false) end
    for _, it in ipairs(itemOnlyEntries(e)) do recs[#recs + 1] = it end
    if self.myArtMissing then
        for _, sid in ipairs((c and c:GetRecipes(e.profKey)) or {}) do
            if not e.known[sid] then recs[#recs + 1] = recEntryOf(e, sid, true) end
        end
    end
    -- Tri par rentabilité : liste à PLAT (les catégories disparaissent), comme la vue métier.
    if self.myArtSortProfit and COC.LazyGold and COC.LazyGold:IsAvailable() then
        local flat = self:_MyArtCooldownItems(e)
        for _, rc in ipairs(self:_MyArtSortByProfit(recs)) do flat[#flat + 1] = rc end
        return flat
    end

    local list = self:_MyArtCooldownItems(e)
    local disp = COC.RecipeCats:BuildDisplay(e.profKey, recs, {
        itemID = function(rc) return rc.itemID end,
        name   = function(rc) return rc.name or "" end,
    })
    for _, it in ipairs(disp) do list[#list + 1] = it end
    return list
end

function UI:_FillMyArtRecipes(e, profs)
    local list = self:_MyArtDisplayList(e, profs)
    local n = 0
    for _, it in ipairs(list) do
        n = n + 1
        local row = self:_MyArtRecRow(n)
        row.tipItemID, row.tipSpellID = nil, nil   -- lignes poolées : purge le tooltip précédent
        if it.isHeader then
            -- Section (doré, collé au bord) ou sous-catégorie (bronze, indentée) + compte.
            local sub = (it.depth == 2)
            row.icon:Hide(); row.profit:Hide(); anchorName(row, sub and 14 or 4, 0)
            local cnt = (it.count and it.count > 0) and string.format(" |cFF888888(%d)|r", it.count) or ""
            row.name:SetText((sub and "|cFFC9A227" or "|cFFE8B84B") .. (it.label or "") .. "|r" .. cnt)
            row.who:SetText("")
        elseif it.cd then
            row.icon:Show(); row.profit:Hide(); anchorName(row, 20, 0)
            row.icon:SetTexture("Interface\\Icons\\Spell_Holy_BorrowedTime")
            row.name:SetText((it.ready and "|cFF4CDB6E" or "|cFFFFA633") .. it.text .. "|r")
            row.who:SetText("|cFF888888" .. (it.who or "") .. "|r")
        else
            -- Icône de l'OBJET PRODUIT d'abord (GetItemIcon, fiable), repli sort — GetSpellTexture sur
            -- un spellID de recette rend souvent le placeholder « tête » en Classic Era.
            row.icon:Show(); row.icon:SetTexture(Skin.Icon(it.itemID, it.sid) or Skin.tex.unknown)
            row.icon:ClearAllPoints(); row.icon:SetPoint("LEFT", it._sub and 16 or 2, 0)
            row.icon:SetDesaturated(it.missing and true or false)   -- non apprise = grisée, comme la vue métier
            local w = self:_FillMyArtProfit(row, it)
            anchorName(row, it._sub and 34 or 20, w)
            row.tipItemID, row.tipSpellID = it.itemID, it.sid   -- tooltip d'objet au survol
            local col = it.missing and "|cFFDD4444" or "|cFFFFFFFF"   -- non apprise = ROUGE
            -- Inter-métiers : la ligne n'a plus d'en-tête de métier au-dessus → on préfixe son icône.
            local pfx = self.myArtAllProfs and it.profKey
                and ("|T" .. (Skin.ProfIcon(it.profKey) or Skin.tex.unknown) .. ":12|t ") or ""
            row.name:SetText(pfx .. col .. it.name .. "|r" .. (it.at and (" |cFF888888(" .. it.at .. ")|r") or ""))
            row.who:SetText("|cFF888888" .. (it.who or "") .. "|r")
        end
        row:Show()
    end
    for i = n + 1, #self.myArtRecRows do self.myArtRecRows[i]:Hide() end
    self.myArtRecContent:SetHeight(math.max(n * RLH, 10))
    Skin.AutoHideScroll("COCMyArtRecScroll", self.myArtRecContent)
    return n
end

-- =========================================================================
-- Refresh
-- =========================================================================
function UI:RefreshMyArtisans()
    local panel = self.myArtisansPanel; if not panel then return end
    self:_SyncMyArtHeader()
    self._myArtProfitCache = {}   -- invalidé à chaque refresh (les prix Auctionator ont pu changer)
    self:_SyncMyArtLGBar()
    local D = COC.Directory
    local list = (D and D.AggregateMyProfs and D:AggregateMyProfs()) or {}
    -- Tri par libellé LOCALISÉ à rang égal (le cœur trie déjà par bestRank desc puis clé EN).
    table.sort(list, function(a, b)
        if a.bestRank ~= b.bestRank then return a.bestRank > b.bestRank end
        return Skin.ProfLabel(a.profKey) < Skin.ProfLabel(b.profKey)
    end)

    -- Sélection par défaut = 1er métier ; conserve la sélection si elle existe encore.
    local sel = self.myArtSelProf
    local selE
    for _, e in ipairs(list) do if e.profKey == sel then selE = e end end
    if not selE and list[1] then selE = list[1]; self.myArtSelProf = selE.profKey end

    local n = 0
    for _, e in ipairs(list) do
        n = n + 1; self:_FillMyArtProfRow(self:_MyArtProfRow(n), e, e == selE)
    end
    for i = n + 1, #self.myArtProfRows do self.myArtProfRows[i]:Hide() end
    self.myArtProfContent:SetHeight(math.max(n * PLH, 10))
    Skin.AutoHideScroll("COCMyArtProfScroll", self.myArtProfContent)

    if n == 0 then
        self.myArtDetailHdr:SetText("|cFF888888" .. L["Aucun métier. Ouvre ta fenêtre métier sur chaque perso une fois."] .. "|r")
        for i = 1, #self.myArtRecRows do self.myArtRecRows[i]:Hide() end
        return
    end

    -- En-tête : le métier sélectionné, ou « Tout le royaume » quand la vue est inter-métiers.
    if self.myArtAllProfs then
        self.myArtDetailHdr:SetText("|cFFE8B84B" .. L["Tous les plans du royaume"] .. "|r |cFF888888"
            .. string.format(L["%d métiers"], n) .. "|r")
    else
        local lvl = selE.bestRank > 0 and (" |cFF888888" .. selE.bestRank .. "/" .. selE.bestMax .. "|r") or ""
        self.myArtDetailHdr:SetText("|cFFE8B84B" .. Skin.ProfLabel(selE.profKey) .. "|r" .. lvl)
    end
    if self.myArtMissBtn then
        -- « Manquantes » n'a pas de sens inter-métiers (on y montre ce qu'on sait déjà faire).
        self.myArtMissBtn:SetShown(not self.myArtAllProfs)
        self.myArtMissBtn:SetSelected(self.myArtMissing)
        self.myArtMissBtn:SetText(self.myArtMissing
            and string.format(L["Manquantes (%d)"], self:_MyArtMissing(selE)) or L["Manquantes"])
    end
    local shown = self:_FillMyArtRecipes(selE, list)
    if shown == 0 then
        local row = self:_MyArtRecRow(1)
        row.icon:SetTexture(Skin.tex.unknown); row.profit:Hide()
        row.name:SetText("|cFF888888" .. L["Pas de recettes connues (métier de récolte ?)."] .. "|r")
        row.who:SetText(""); row:Show()
    end
end
