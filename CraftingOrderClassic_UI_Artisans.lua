-- CraftingOrderClassic_UI_Artisans.lua — onglet « Artisans » : annuaire social.
-- Sidebar SOURCE (Guilde/Amis/Ajoutés + compteurs) + ajout manuel ; à droite, pills de filtre
-- métier + lignes artisan (présence, niveau, métiers, source, Chuchoter). Lit Directory (cache).

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local ARH    = 40              -- hauteur ligne artisan
local ASEP   = 212             -- x séparateur sidebar/liste
local ARX    = 220             -- x zone droite
local AREDGE = 846
local ARW    = AREDGE - ARX

local SRC_TAG = { guild = L["GUILDE"], friend = L["AMIS"], added = L["AJOUTÉ"], recent = L["CROISÉ"], confed = L["CONFÉDÉRÉ"] }

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end
local function trim(s) return s and s:gsub("^%s+", ""):gsub("%s+$", "") or "" end

-- Case à cocher CLIQUABLE : Skin.MakeCheck ne renvoie qu'une texture, on la pose sur un Button + libellé.
-- get() lit l'état courant, set(bool) l'applique. `.Sync()` recale la coche sur l'état réel (ex. slash).
local function makeToggle(parent, x, y, label, get, set)
    local btn = CreateFrame("Button", nil, parent); btn:SetPoint("BOTTOMLEFT", x, y)
    local box = Skin.MakeCheck(btn, 16); box:SetPoint("LEFT", 0, 0)
    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    fs:SetPoint("LEFT", box, "RIGHT", 5, 0); fs:SetText(label); fs:SetTextColor(Skin.unpack(Skin.color.textMuted))
    btn:SetSize(21 + fs:GetStringWidth() + 4, 18)
    btn:SetScript("OnClick", function() local nv = not get(); set(nv); box:SetChecked(nv) end)
    btn.Sync = function() box:SetChecked(get() and true or false) end
    btn.Sync()
    return btn
end

-- Annuaire d'affichage : on montre AUSSI les non-porteurs « vu crafter » (craftSeen) → variante OrSeen
-- du helper partagé (cf. Skin), contrairement aux onglets Commande/Récolte qui n'incluent QUE SK/RK.
local knowsProf = Skin.KnowsProfOrSeen

-- Métiers connus d'un artisan, en liste { key, sv } : niveau (SK) si connu, sinon recette seule (RK).
-- Union des deux sources, triée par libellé localisé — même ordre visuel que l'ancien texte concaténé.
local function profsList(r)
    local SEC = COC.SECONDARY_PROF or {}   -- Cuisine/Secours/Pêche jamais affichés (pas de commande)
    local seen, parts = {}, {}
    for key, sv in pairs(r.skill or {}) do
        if not SEC[key] then seen[key] = true; parts[#parts + 1] = { key = key, sv = sv } end
    end
    for key in pairs(r.recipes or {}) do
        if not (SEC[key] or seen[key]) then seen[key] = true; parts[#parts + 1] = { key = key } end
    end
    for key, floor in pairs(r.craftSeen or {}) do   -- non-porteur vu crafter : plancher estimé
        if not (SEC[key] or seen[key]) then seen[key] = true; parts[#parts + 1] = { key = key, est = floor } end
    end
    local rel = r.relayed                            -- fiche relayée par un partenaire (hors ligne)
    if rel then
        for key, sv in pairs(rel.skill or {}) do
            if not (SEC[key] or seen[key]) then seen[key] = true; parts[#parts + 1] = { key = key, sv = sv, relay = true } end
        end
        for key in pairs(rel.recipes or {}) do
            if not (SEC[key] or seen[key]) then seen[key] = true; parts[#parts + 1] = { key = key, relay = true } end
        end
    end
    table.sort(parts, function(a, b) return Skin.ProfLabel(a.key) < Skin.ProfLabel(b.key) end)
    return parts
end
UI._ProfsList = profsList   -- partagé avec la couche de fusion (UI_Artisans_Groups.lua)
UI._SrcTag    = SRC_TAG

-- =========================================================================
-- Construction
-- =========================================================================
function UI:BuildArtisansTab(f)
    local panel = CreateFrame("Frame", nil, f); self.insetPanel(panel, f); panel:Hide()
    self.artisansPanel = panel
    self.artSource     = "all"
    self.artProfFilter = nil
    self.artPillsBuilt = false

    local vs = panel:CreateTexture(nil, "ARTWORK")
    vs:SetColorTexture(Skin.color.separator[1], Skin.color.separator[2], Skin.color.separator[3], 0.5)
    vs:SetSize(1, 470); vs:SetPoint("TOPLEFT", ASEP, -78)

    -- Sidebar : SOURCE
    local srcHdr = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    srcHdr:SetPoint("TOPLEFT", 14, -80); srcHdr:SetText(L["SOURCE"])
    srcHdr:SetTextColor(Skin.unpack(Skin.color.textMuted))

    -- « Confédération » (confed) : bucket EN PLUS, masqué si GreenWall absent (cf. RefreshArtisans). Placé
    -- en dernier → le masquer ne laisse aucun trou dans la sidebar.
    -- « confed » reste EN DERNIER (masqué hors GreenWall → aucun trou). « muted » = panneau de gestion
    -- des mis en sourdine (données = COC.db.mutedPlayers, pas le roster ; cf. UI_Artisans_Muted.lua).
    local srcDefs = { {id="all",label=L["Tous"]}, {id="guild",label=L["Guilde"]}, {id="friend",label=L["Amis"]}, {id="added",label=L["Ajoutés"]}, {id="recent",label=L["Annuaire"]}, {id="muted",label=L["En sourdine"]}, {id="confed",label=L["Confédération"]} }
    self.artSrcBtns = {}
    for i, d in ipairs(srcDefs) do
        local b = Skin.MakeGoldButton(panel, 190, 28, d.label)
        b:SetPoint("TOPLEFT", 12, -96 - (i - 1) * 32)
        b.text:ClearAllPoints(); b.text:SetPoint("LEFT", 10, 0); b.text:SetJustifyH("LEFT")
        local cnt = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cnt:SetPoint("RIGHT", -10, 0); Skin.ApplyShadow(cnt); b.count = cnt
        b:SetScript("OnClick", function() UI.artSource = d.id; UI:_RefreshArtSrcTabs(); UI:RefreshArtisans() end)
        self.artSrcBtns[d.id] = b
    end
    self:_RefreshArtSrcTabs()

    self:_BuildArtisanAddScan(panel)   -- ajout manuel d'un joueur + bouton « Scanner la faction »

    -- Zone droite : libellé Métier + pills (construits paresseusement), puis liste
    self.artPillHdr = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.artPillHdr:SetPoint("TOPLEFT", ARX, -98); self.artPillHdr:SetText("|cFF888888" .. L["Métier :"] .. "|r"); Skin.ApplyShadow(self.artPillHdr)
    self.artPills = {}

    local ascroll = CreateFrame("ScrollFrame", "COCArtScroll", panel, "UIPanelScrollFrameTemplate")
    ascroll:SetPoint("TOPLEFT", ARX, -150); ascroll:SetPoint("BOTTOMRIGHT", -42, 22)
    -- Largeur < zone visible du scroll (sinon les lignes passent SOUS la scrollbar → boutons masqués).
    local ac = CreateFrame("Frame", nil, ascroll); ac:SetSize(ARW - 54, 10); ascroll:SetScrollChild(ac)
    self.artScroll = ascroll; self.artListContent = ac; self.artListRows = {}

    if self._BuildMutedList then self:_BuildMutedList(panel) end   -- panneau « En sourdine » (superposé, caché)
end

-- Cluster bas-gauche « remplir l'annuaire » : champ d'ajout manuel + bouton « Scanner la faction »
-- (brique Dead Faction : /who recense les EN LIGNE et pingue chaque nom en HELLO → les porteurs
-- remontent dans l'Annuaire ; UNE tranche par clic car SendWho = hardware event, cf. Directory_WhoScan).
function UI:_BuildArtisanAddScan(panel)
    local addHdr = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    addHdr:SetPoint("BOTTOMLEFT", 14, 86); addHdr:SetText(L["AJOUTER UN JOUEUR"])
    addHdr:SetTextColor(Skin.unpack(Skin.color.textMuted))
    local addBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    addBox:SetSize(150, 20); addBox:SetPoint("BOTTOMLEFT", 16, 60); addBox:SetAutoFocus(false)
    addBox:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)
    addBox:SetScript("OnEnterPressed", function(b) UI:_AddArtisan(b:GetText()); b:SetText(""); b:ClearFocus() end)
    local ghost = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ghost:SetPoint("LEFT", addBox, "LEFT", 4, 0); ghost:SetText(L["Nom du personnage"])
    addBox:SetScript("OnTextChanged", function(b) ghost:SetShown(b:GetText() == "") end)
    local addBtn = Skin.MakeGoldButton(panel, 26, 20, "+")
    addBtn:SetPoint("LEFT", addBox, "RIGHT", 6, 0)
    addBtn:SetScript("OnClick", function() UI:_AddArtisan(addBox:GetText()); addBox:SetText("") end)

    local refreshBtn = Skin.MakeGoldButton(panel, 190, 24, L["Rafraîchir l'annuaire"])
    refreshBtn:SetPoint("BOTTOMLEFT", 16, 112)
    refreshBtn:SetScript("OnClick", function() UI:_RefreshDirectory() end)
    self.artRefreshBtn = refreshBtn

    -- Toggle « détecter les crafteurs autour » (opt-in, en ville only) — cf. Directory_LootScan.
    self.artScanChk = makeToggle(panel, 16, 36, L["Repérer les crafteurs autour (en ville)"],
        function() return COC.Directory and COC.Directory:CrafterScanEnabled() end,
        function(nv) if COC.Directory then COC.Directory:SetCrafterScan(nv) end end)
end

-- Recale la case (ex. après « /co crafters on/off » en dehors de l'UI).
function UI:_SyncCrafterScanChk() if self.artScanChk then self.artScanChk.Sync() end end

function UI:_RefreshArtSrcTabs()
    for id, b in pairs(self.artSrcBtns or {}) do b:SetSelected(id == self.artSource) end
end

-- « Rafraîchir l'annuaire » : émet la balise CLNK1 + HI sur le canal CraftLink (le clic = hardware
-- event requis par la balise) → tous les porteurs EN LIGNE répondent en whisper et remontent dans
-- l'annuaire ; re-ping aussi les artisans déjà connus. (Remplace l'ancien scan /who, retiré.)
function UI:_RefreshDirectory()
    if COC.Directory and COC.Directory.Refresh then COC.Directory:Refresh() end
    print("|cFF33DD88Crafting Order|r " .. L["annuaire : appel lancé sur le canal — les porteurs en ligne vont répondre."])
    if C_Timer then C_Timer.After(2, function() if UI.RefreshArtisans then UI:RefreshArtisans() end end) end
end

-- Le bucket « Confédération » n'existe que si GreenWall est actif (display-only) : on le montre/masque et,
-- s'il était sélectionné alors que GreenWall a disparu, on retombe sur « Tous ».
function UI:_SyncConfedTab()
    local D = COC.Directory
    -- Visible si GreenWall actif — OU en mode solo (/co debug) pour tester l'UI sans SoD live.
    local gwOn = (D and D._GreenWallActive and D:_GreenWallActive()) or (COC.db and COC.db.debug)
    if self.artSrcBtns and self.artSrcBtns.confed then self.artSrcBtns.confed:SetShown(gwOn and true or false) end
    if not gwOn and self.artSource == "confed" then self.artSource = "all"; self:_RefreshArtSrcTabs() end
end

-- Pills de filtre métier (Tous + chaque métier), avec retour à la ligne.
function UI:_BuildArtPills(panel)
    local c = CL(); local profs = c and c:Professions() or {}
    local defs = { "Tous" }
    for _, p in ipairs(profs) do   -- primaires seulement : pas de pill Cuisine/Secours/Pêche
        if not (COC.SECONDARY_PROF and COC.SECONDARY_PROF[p]) then defs[#defs + 1] = p end
    end
    local x, y, rowH = 50, 0, 24      -- x départ = 50 pour dégager « Métier : »
    local maxW = ARW - 4
    for _, key in ipairs(defs) do
        local label = (key == "Tous") and L["Tous"] or Skin.ProfLabel(key)   -- "Tous" = sentinelle (pas localisée)
        local b = Skin.MakeGoldButton(panel, 10, 18, label)
        local w = b.text:GetStringWidth() + 16
        b:SetWidth(w)
        if x + w > maxW then x = 0; y = y + rowH end
        b:SetPoint("TOPLEFT", ARX + x, -94 - y)
        b:SetScript("OnClick", function()
            -- NB : surtout pas l'idiome `cond and nil or key` (Lua : `true and nil or key` == key).
            if key == "Tous" then UI.artProfFilter = nil else UI.artProfFilter = key end
            UI:_RefreshArtPills(); UI:RefreshArtisans()
        end)
        self.artPills[#self.artPills + 1] = { btn = b, key = key }
        x = x + w + 4
    end
    -- Recale le haut de la liste sous la dernière rangée de pills.
    self.artScroll:ClearAllPoints()
    self.artScroll:SetPoint("TOPLEFT", ARX, -(94 + y + 28))
    self.artScroll:SetPoint("BOTTOMRIGHT", -42, 22)
    self:_RefreshArtPills()
end

function UI:_RefreshArtPills()
    for _, p in ipairs(self.artPills or {}) do
        local active = (p.key == "Tous" and self.artProfFilter == nil) or (p.key == self.artProfFilter)
        p.btn:SetSelected(active)
    end
end

-- Ajout manuel (sera lié au vrai profil quand le joueur sera vu en ligne — backend Étape D).
function UI:_AddArtisan(name)
    name = trim(name)
    if name == "" then return end
    name = name:sub(1, 1):upper() .. name:sub(2)
    local D = COC.Directory; if not D then return end
    D.roster = D.roster or {}
    local r = D.roster[name] or {}
    r.source = "added"; r.recipes = r.recipes or {}; r.manual = true; r.lastSeen = time()
    D.roster[name] = r
    if D.DiscoverPlayer then D:DiscoverPlayer(name) end   -- ping immédiat : métiers + en ligne s'il a l'addon
    UI.artSource = "added"; UI:_RefreshArtSrcTabs(); UI:RefreshArtisans()
    print("|cFF33DD88Crafting Order|r " .. L["artisan ajouté : "] .. "|cFFFFFFFF" .. name ..
        "|r |cFF888888" .. L["(lié quand il sera en ligne avec l'addon)"] .. "|r")
end

-- Bascule le flag PARTENAIRE (drapeau explicite, distinct du isFriend automatique du client WoW —
-- cf. request/FEATURE_friend.md) : priorisé dans l'alerte de plan looté (CraftingOrderClassic_LootAlert.lua)
-- pour proposer un don en premier. Ajoute l'artisan à l'annuaire s'il n'y est pas encore (comme _AddArtisan).
function UI:_TogglePartner(name)
    name = trim(name)
    if name == "" then return end
    name = name:sub(1, 1):upper() .. name:sub(2)
    local D = COC.Directory; if not D then return end
    D.roster = D.roster or {}
    local r = D.roster[name]
    if not r then
        r = { source = "added", recipes = {}, manual = true, lastSeen = time() }
        D.roster[name] = r
        if D.DiscoverPlayer then D:DiscoverPlayer(name) end
    end
    r.isPartner = not r.isPartner
    UI:RefreshArtisans()
    print("|cFF33DD88Crafting Order|r " .. (r.isPartner
        and string.format(L["|cFFFFFFFF%s|r marqué comme partenaire — priorité sur les alertes de don."], name)
        or string.format(L["|cFFFFFFFF%s|r n'est plus marqué comme partenaire."], name)))
end

-- =========================================================================
-- Refresh
-- =========================================================================
function UI:RefreshArtisans()
    local panel = self.artisansPanel; if not panel then return end
    if not self.artPillsBuilt then self:_BuildArtPills(panel); self.artPillsBuilt = true end
    self:_SyncCrafterScanChk()
    local D = COC.Directory
    self:_SyncConfedTab()   -- montre/masque le bucket « Confédération » selon GreenWall (display-only)

    -- Compteurs par source (+ « all » = total ; « muted » = mis en sourdine, hors roster)
    local counts = { all = 0, guild = 0, friend = 0, added = 0, recent = 0, confed = 0 }
    for _, r in pairs(D and D.roster or {}) do
        local s = r.source or "recent"; counts[s] = (counts[s] or 0) + 1; counts.all = counts.all + 1
    end
    counts.muted = (COC.Moderation and COC.Moderation.MutedList) and #COC.Moderation:MutedList() or 0
    for id, b in pairs(self.artSrcBtns) do b.count:SetText("|cFFE8B84B" .. (counts[id] or 0) .. "|r") end

    -- Source « En sourdine » : panneau de gestion dédié (renderer + données propres) au lieu de la
    -- liste d'artisans. On bascule l'affichage et on sort avant tout le pipeline roster/filtre/tri.
    if self.artSource == "muted" then
        if self._ShowMutedMode then self:_ShowMutedMode(true) end
        if self.RefreshMuted then self:RefreshMuted() end
        return
    end
    if self._ShowMutedMode then self:_ShowMutedMode(false) end

    -- Liste filtrée (source + métier), FUSIONNÉE par joueur vérifié : les rerolls (liens ALT
    -- mutuels) tiennent sur UNE ligne, perso principal en vitrine (cf. UI_Artisans_Groups.lua).
    -- Le groupe passe le filtre si N'IMPORTE QUEL de ses persos le passe (union).
    local src, pf = self.artSource or "all", self.artProfFilter
    local list = self:_ArtisanGroups(function(r)
        return (src == "all" or (r.source or "recent") == src) and (not pf or knowsProf(r, pf))
    end)
    table.sort(list, function(a, b)
        if (a.anyPartner and true) ~= (b.anyPartner and true) then return a.anyPartner end   -- partenaires en tête
        if (a.onlineChar ~= nil) ~= (b.onlineChar ~= nil) then return a.onlineChar ~= nil end
        if a.repMax ~= b.repMax then return a.repMax > b.repMax end   -- réputation max du set, décroissante
        return a.leader < b.leader
    end)

    local n = 0
    for _, g in ipairs(list) do
        n = n + 1
        local row = self:_ArtRow(n)
        if #g.members > 1 then self:_FillArtGroupRow(row, g)
        else self:_FillArtRow(row, { name = g.leader, r = g.lead.r, online = g.lead.online }) end
    end
    for i = n + 1, #self.artListRows do self.artListRows[i]:Hide() end
    self.artListContent:SetHeight(math.max(n * ARH, 10))
    Skin.AutoHideScroll("COCArtScroll", self.artListContent)
    if n == 0 and self.artListRows[1] then
        local row = self:_ArtRow(1)
        row:SetScript("OnEnter", nil); row:SetScript("OnLeave", nil)
        row.dot:SetOnline(nil); row.name:SetText("|cFF888888" .. L["Aucun artisan dans cette source."] .. "|r")
        row.sub:SetText(""); UI:_SetArtProfIcons(row, {}); row.src:SetText(""); row.whisper:Hide(); row.addFriend:Hide()
        row:Show()
    end
end

-- Remplit une ligne artisan. Distingue les NON-porteurs (r.nonAddon, vus crafter via CHAT_MSG_LOOT) :
-- sous-ligne « vu crafter » + tag « VU » au lieu de présence/niveau/réputation.
function UI:_FillArtRow(row, a)
    row:SetScript("OnEnter", nil); row:SetScript("OnLeave", nil)   -- lignes poolées : purge le tooltip de groupe
    row.dot:SetOnline(a.online and true or false)
    local pTag = a.r.isPartner and ("|cFFFFD100" .. L["[Partenaire]"] .. "|r ") or ""   -- texte, pas de glyphe tofu
    row.name:SetText(pTag .. "|cFFFFFFFF" .. a.name .. "|r")
    -- « relayé » = fiche servie par un partenaire pendant que l'artisan est HORS LIGNE, sans aucune
    -- donnée directe ; « non-porteur » = vu crafter ET aucune vraie donnée réseau reçue de lui (s'il
    -- finit par diffuser ses SK/RK, on repasse en artisan normal même si le flag nonAddon traîne).
    local relayed  = a.r.relayed and not (a.r.skill or a.r.recipes)
    local nonAddon = a.r.nonAddon and not (a.r.skill or a.r.recipes) and not relayed
    if relayed then
        local rel = a.r.relayed
        row.sub:SetText("|cFF888888" .. string.format(L["via %s · il y a %s"], rel.via or "?",
            Skin.FormatDuration(math.max(0, time() - (rel.ts or time())))) .. "|r")
    elseif nonAddon then
        local mv = self:_SeenProfNames(a.r)   -- le métier VU (au moins un)
        row.sub:SetText("|cFF888888" .. L["vu crafter"] .. (mv ~= "" and (" : |cFFBBBBBB" .. mv) or "") .. "|r")
    else
        local lvl = a.r.level and (L["niv "] .. a.r.level) or L["niv ?"]
        local rep = (a.r.rep and a.r.rep > 0) and (" · " .. string.format(L["%d livrés"], a.r.rep)) or ""
        row.sub:SetText("|cFF888888" .. (a.online and L["En ligne"] or L["Hors ligne"]) .. " · " .. lvl .. rep .. "|r")
    end
    UI:_SetArtProfIcons(row, profsList(a.r), a.r)
    row.src:SetText("|cFF888888" .. (relayed and L["RELAIS"] or nonAddon and L["VU"]
        or (SRC_TAG[a.r.source or "recent"] or "")) .. "|r")
    self:_ArtRowButtons(row, a, nonAddon)
    row:Show()
end

-- Libellés des métiers VUS d'un non-porteur (« vu crafter : Couture, Alchimie »).
function UI:_SeenProfNames(r)
    local names = {}
    for _, it in ipairs(profsList(r)) do names[#names + 1] = Skin.ProfLabel(it.key) end
    return table.concat(names, ", ")
end

-- Boutons de droite. Chuchoter : si en ligne / pas un simple ajout hors-ligne. « Ajouter ami » : pour
-- un non-porteur vu crafter (on ne le connaît que de vue) pas déjà ami → les deux boutons s'empilent.
function UI:_ArtRowButtons(row, a, nonAddon)
    row.whisper:SetScript("OnClick", function() if ChatFrame_SendTell then ChatFrame_SendTell(a.name) end end)
    row.whisper:SetShown(a.online == true or a.r.source ~= "added")
    local D = COC.Directory
    local canFriend = nonAddon and not (D and D._friendSet and D._friendSet[a.name])
    if canFriend then
        row.whisper:ClearAllPoints(); row.whisper:SetPoint("RIGHT", -6, 9); row.whisper:SetHeight(18)
        row.addFriend:ClearAllPoints(); row.addFriend:SetPoint("RIGHT", -6, -9)
        row.addFriend:SetScript("OnClick", function() UI:_AddFriend(a.name) end)
        row.addFriend:Show()
    else
        row.whisper:ClearAllPoints(); row.whisper:SetPoint("RIGHT", -6, 0); row.whisper:SetHeight(22)
        row.addFriend:Hide()
    end
end

-- Ajoute le joueur à la liste d'amis WoW (un clic depuis l'annuaire). Au refresh suivant, ScanRelations
-- le reclasse en « Amis » → le bouton disparaît de lui-même.
function UI:_AddFriend(name)
    if C_FriendList and C_FriendList.AddFriend then C_FriendList.AddFriend(name) end
    print("|cFF33DD88Crafting Order|r " .. string.format(L["|cFFFFFFFF%s|r ajouté à tes amis."], name))
    if COC.Directory and COC.Directory.ScanRelations then COC.Directory:ScanRelations() end
    if C_Timer then C_Timer.After(1, function() if UI.RefreshArtisans then UI:RefreshArtisans() end end) end
end

function UI:_ArtRow(i)
    local r = self.artListRows[i]; if r then return r end
    r = CreateFrame("Button", nil, self.artListContent); r:SetSize(ARW - 54, ARH); r:SetPoint("TOPLEFT", 0, -(i - 1) * ARH)
    local hi = r:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints(); hi:SetColorTexture(Skin.unpack(Skin.color.rowHover))
    r.dot   = Skin.MakeStatusIcon(r, 14); r.dot:SetPoint("LEFT", 6, 0)
    r.name  = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    r.name:SetPoint("TOPLEFT", 22, -5); r.name:SetWidth(150); r.name:SetJustifyH("LEFT"); Skin.ApplyShadow(r.name)
    r.sub   = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.sub:SetPoint("TOPLEFT", 22, -22); r.sub:SetWidth(150); r.sub:SetJustifyH("LEFT"); Skin.ApplyShadow(r.sub)
    r.profsFrame = CreateFrame("Frame", nil, r)
    r.profsFrame:SetPoint("LEFT", 180, 0); r.profsFrame:SetSize(ARW - 320, ARH)
    r.profIconPool = {}
    r.src   = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); r.src:SetPoint("RIGHT", -94, 0); Skin.ApplyShadow(r.src)
    r.whisper = Skin.MakeGoldButton(r, 78, 22, L["Chuchoter"]); r.whisper:SetPoint("RIGHT", -6, 0)
    r.addFriend = Skin.MakeGoldButton(r, 78, 18, L["Ajouter ami"]); r.addFriend:SetPoint("RIGHT", -6, -9); r.addFriend:Hide()
    self.artListRows[i] = r; return r
end

-- Icônes de métier (survol = tooltip nom + niveau + cooldowns) à la place du texte concaténé.
local ARI = 22   -- pas horizontal entre icônes
function UI:_SetArtProfIcons(row, list, r)
    local pool = row.profIconPool
    for i, item in ipairs(list) do
        local ic = pool[i]
        if not ic then
            ic = CreateFrame("Frame", nil, row.profsFrame); ic:SetSize(18, 18)
            local tex = ic:CreateTexture(nil, "ARTWORK"); tex:SetAllPoints()
            tex:SetTexCoord(0.08, 0.92, 0.08, 0.92); ic.tex = tex
            ic:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(self.tipLabel or "", 1, 1, 1)
                if self.tipSub then GameTooltip:AddLine(self.tipSub, 0.910, 0.722, 0.294) end
                for _, ln in ipairs(self.tipCds or {}) do   -- cooldowns : vert = prête, orange = en recharge
                    if ln.ready then GameTooltip:AddLine(ln.text, 0.3, 0.9, 0.4)
                    else GameTooltip:AddLine(ln.text, 1.0, 0.65, 0.2) end
                end
                GameTooltip:Show()
            end)
            ic:SetScript("OnLeave", GameTooltip_Hide)
            pool[i] = ic
        end
        ic:ClearAllPoints(); ic:SetPoint("LEFT", (i - 1) * ARI, 0)
        ic.tex:SetTexture(Skin.ProfIcon(item.key) or Skin.tex.unknown)
        ic.tipLabel = Skin.ProfLabel(item.key)
        local sub = item.sv and ((item.sv[1] or "?") .. "/" .. (item.sv[2] or "?"))
            or (item.est ~= nil and ((item.est > 0) and string.format(L["%d+ · vu crafter"], item.est) or L["vu crafter (sans l'addon)"]))
            or nil
        if item.who then sub = (sub and (sub .. " — ") or "") .. item.who end   -- ligne fusionnée : PORTEUR du métier
        ic.tipSub = sub
        local rr = item.r or r                       -- fusion : les CD viennent du PORTEUR, pas de la vitrine
        local So = COC.Social
        ic.tipCds = (rr and So and So.CooldownLines) and So:CooldownLines(rr, 3, item.key) or nil
        ic:Show()
    end
    for i = #list + 1, #pool do pool[i]:Hide() end
end
