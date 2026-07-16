-- CraftingOrderClassic_UI_Artisans.lua — onglet « Artisans » : annuaire social.
-- Sidebar SOURCE (Guilde/Amis/Ajoutés + compteurs) + ajout manuel ; à droite, pills de filtre
-- métier + lignes artisan (présence, niveau, métiers, source, Chuchoter). Lit Directory (cache).

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local ARH = 40              -- hauteur ligne artisan
local A   = UI.ART          -- métriques dérivées de la SPEC — cf. _UI_Artisans_Layout.lua

local SRC_TAG = { guild = L["GUILDE"], friend = L["AMIS"], added = L["AJOUTÉ"], recent = L["CROISÉ"], confed = L["CONFÉDÉRÉ"] }

-- Libellés des 3 états de présence (cf. Dir:PresenceOf). « sans addon » n'est pas cosmétique : il dit
-- pourquoi ses métiers/niveaux peuvent être périmés et pourquoi une commande ne lui parviendra pas.
local PRES_LABEL = { online = L["En ligne"], game = L["En ligne · sans addon"], offline = L["Hors ligne"] }

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
    local skKnown = r.skill and next(r.skill)   -- SK = vérité terrain du perso : s'il est connu, il PRIME
    for key, sv in pairs(r.skill or {}) do
        if not SEC[key] then seen[key] = true; parts[#parts + 1] = { key = key, sv = sv } end
    end
    for key in pairs(r.recipes or {}) do
        -- Filet de sécurité : ne PAS afficher un métier vu en RK qui CONTREDIT un SK connu (fuite d'alt
        -- d'un vieux client, captée avant que la purge OnSkill ne passe) → « forgeron » ne montre pas
        -- « enchanteur » juste parce qu'un RK enchanteur a fuité. Sans SK connu, on affiche (cas légitime).
        if not (SEC[key] or seen[key]) and not (skKnown and not r.skill[key]) then
            seen[key] = true; parts[#parts + 1] = { key = key }
        end
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
UI._PresLabel = PRES_LABEL

-- =========================================================================
-- Construction
-- =========================================================================
function UI:BuildArtisansTab(f)
    local panel = CreateFrame("Frame", nil, f); self.insetPanel(panel, f); panel:Hide()
    self.artisansPanel = panel
    self.artSource     = "all"
    self.artProfFilter = nil
    self.artPillsBuilt = false

    self:_BuildArtSections(panel)   -- blocs + filets + frontière sidebar│liste : la SPEC (Layout)

    -- Sidebar : SOURCE (en-tête + boutons de filtre empilés dans la zone « sources »)
    local sz = self:ArtSec("sources")
    local srcHdr = sz:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    srcHdr:SetPoint("TOPLEFT", 14, -6); srcHdr:SetText(L["SOURCE"])
    srcHdr:SetTextColor(Skin.unpack(Skin.color.textMuted))

    -- « Confédération » (confed) : bucket EN PLUS, masqué si GreenWall absent (cf. RefreshArtisans),
    -- EN DERNIER → le masquer ne laisse aucun trou. « muted » = panneau de gestion des mis en
    -- sourdine (données = COC.db.mutedPlayers, pas le roster ; cf. UI_Artisans_Muted.lua).
    local srcDefs = { {id="all",label=L["Tous"]}, {id="guild",label=L["Guilde"]}, {id="friend",label=L["Amis"]}, {id="added",label=L["Ajoutés"]}, {id="recent",label=L["Annuaire"]}, {id="muted",label=L["En sourdine"]}, {id="confed",label=L["Confédération"]} }
    self.artSrcBtns = {}
    for i, d in ipairs(srcDefs) do
        local b = Skin.MakeFilterButton(sz, 190, 24, d.label)   -- bande de filtre style HdV (verrou doré, pas de bleu)
        b:SetPoint("TOPLEFT", 12, -22 - (i - 1) * 26)
        local cnt = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cnt:SetPoint("RIGHT", -10, 0); Skin.ApplyShadow(cnt); b.count = cnt
        b:SetScript("OnClick", function() UI.artSource = d.id; UI:_RefreshArtSrcTabs(); UI:RefreshArtisans() end)
        self.artSrcBtns[d.id] = b
    end
    self:_RefreshArtSrcTabs()

    self:_BuildArtisanAddScan(self:ArtSec("addPlayer"))   -- cluster bas de la sidebar (sa zone)

    -- Bande de filtre métier : libellé + pills (construits paresseusement dans la zone, cf. Icons)
    local band = self:ArtSec("profFilter")
    self.artPillHdr = band:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.artPillHdr:SetPoint("LEFT", A.PAD + 4, 0); self.artPillHdr:SetText("|cFF888888" .. L["Métier :"] .. "|r"); Skin.ApplyShadow(self.artPillHdr)
    self.artPills = {}

    -- Liste des artisans : largeur LUE sur la zone (SPEC pilote pad/gouttière ; −6 = la scrollbar
    -- déborde dans la gouttière). Les lignes suivent (cf. _ArtRow).
    local lz = self:ArtSec("artisansList")
    local w = lz:GetWidth(); if w <= 1 then w = A.WIDE_W end
    self.artListW = w - 6
    local ascroll = CreateFrame("ScrollFrame", "COCArtScroll", lz, "UIPanelScrollFrameTemplate")
    ascroll:SetPoint("TOPLEFT", A.PAD, 0); ascroll:SetPoint("BOTTOMLEFT", A.PAD, A.PAD)
    ascroll:SetWidth(self.artListW)
    local ac = CreateFrame("Frame", nil, ascroll); ac:SetSize(self.artListW, 10); ascroll:SetScrollChild(ac)
    self.artScroll = ascroll; self.artListContent = ac; self.artListRows = {}
    Skin.ScrollTrack("COCArtScroll")   -- rail sombre derrière la scrollbar (iso Commande/Récolte)

    if self._BuildMutedList then self:_BuildMutedList() end   -- panneau « En sourdine » (superposé aux zones, caché)
end

-- Cluster « remplir l'annuaire » (zone « addPlayer » de la SPEC, en bas de sidebar) : champ d'ajout
-- manuel + « Rafraîchir l'annuaire » + toggle de repérage — offsets RELATIFS au bas de la zone.
function UI:_BuildArtisanAddScan(sec)
    local addHdr = sec:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    addHdr:SetPoint("BOTTOMLEFT", 14, 66); addHdr:SetText(L["AJOUTER UN JOUEUR"])
    addHdr:SetTextColor(Skin.unpack(Skin.color.textMuted))
    local addBox = CreateFrame("EditBox", nil, sec, "InputBoxTemplate")
    addBox:SetSize(150, 20); addBox:SetPoint("BOTTOMLEFT", 16, 40); addBox:SetAutoFocus(false)
    addBox:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)
    addBox:SetScript("OnEnterPressed", function(b) UI:_AddArtisan(b:GetText()); b:SetText(""); b:ClearFocus() end)
    local ghost = sec:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ghost:SetPoint("LEFT", addBox, "LEFT", 4, 0); ghost:SetText(L["Nom du personnage"])
    addBox:SetScript("OnTextChanged", function(b) ghost:SetShown(b:GetText() == "") end)
    local addBtn = Skin.MakeGoldButton(sec, 26, 20, "+")
    addBtn:SetPoint("LEFT", addBox, "RIGHT", 6, 0)
    addBtn:SetScript("OnClick", function() UI:_AddArtisan(addBox:GetText()); addBox:SetText("") end)

    local refreshBtn = Skin.MakeGoldButton(sec, 190, 24, L["Rafraîchir l'annuaire"])
    refreshBtn:SetPoint("BOTTOMLEFT", 16, 92)
    refreshBtn:SetScript("OnClick", function() UI:_RefreshDirectory() end)
    self.artRefreshBtn = refreshBtn

    -- Toggle « détecter les crafteurs autour » (opt-in, en ville only) — cf. Directory_LootScan.
    self.artScanChk = makeToggle(sec, 16, 16, L["Repérer les crafteurs autour (en ville)"],
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

-- Pills de filtre métier + icônes de métier des lignes : cf. _UI_Artisans_Icons.lua
-- (UI:_BuildArtPills / _RefreshArtPills / _SetArtProfIcons / _SetArtProfitBorder).

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
    if not self.artPillsBuilt then self:_BuildArtPills(); self.artPillsBuilt = true end
    self:_SyncCrafterScanChk()
    local D = COC.Directory
    self:_SyncConfedTab()   -- montre/masque le bucket « Confédération » selon GreenWall (display-only)

    -- Compteurs par source (+ « all » = total ; « muted » = mis en sourdine, hors roster)
    local counts = { all = 0, guild = 0, friend = 0, added = 0, recent = 0, confed = 0 }
    for _, r in pairs(D and D.roster or {}) do
        if not (D and D._SameFaction) or D:_SameFaction(r) then   -- confinement faction (mêmes règles que la liste)
            local s = r.source or "recent"; counts[s] = (counts[s] or 0) + 1; counts.all = counts.all + 1
        end
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
        if a.presRank ~= b.presRank then return a.presRank > b.presRank end   -- joignable > sans addon > hors ligne
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
        row.sub:SetText(""); UI:_SetArtProfIcons(row, {}); row.src:SetText(""); row.whisper:Hide(); row.addFriend:Hide(); row.partner:Hide()
        row:Show()
    end
end

-- Remplit une ligne artisan. Distingue les NON-porteurs (r.nonAddon, vus crafter via CHAT_MSG_LOOT) :
-- sous-ligne « vu crafter » + tag « VU » au lieu de présence/niveau/réputation.
function UI:_FillArtRow(row, a)
    row:SetScript("OnEnter", nil); row:SetScript("OnLeave", nil)   -- lignes poolées : purge le tooltip de groupe
    local D0 = COC.Directory
    local pres = (D0 and D0.PresenceOf and D0:PresenceOf(a.name)) or (a.online and "online" or "offline")
    row.dot:SetPresence(pres)
    local pTag = a.r.isPartner and ("|cFFFFD100" .. L["[Partenaire]"] .. "|r ") or ""   -- texte, pas de glyphe tofu
    local lfwE = D0 and D0.LFWOf and D0:LFWOf(a.name)
    local lfwTag = lfwE and ("|cFF4CDB6E" .. L["[Dispo]"] .. "|r ") or ""
    row.name:SetText(lfwTag .. pTag .. "|cFFFFFFFF" .. a.name .. "|r")
    -- Tooltip d'OFFRE sur la ligne [Dispo] : métier cherché + détails (mêmes lignes que le tooltip
    -- monde, source unique Dir:LFWOfferLines). Posé ICI et purgé en tête de fill : lignes poolées.
    if lfwE then
        row:SetScript("OnEnter", function(rw)
            GameTooltip:SetOwner(rw, "ANCHOR_RIGHT")
            GameTooltip:SetText("|cFF4CDB6E" .. string.format(L["Cherche du travail : %s"],
                Skin.ProfLabel(lfwE.prof) or lfwE.prof) .. "|r")
            for _, ln in ipairs((D0.LFWOfferLines and D0:LFWOfferLines(a.name)) or {}) do
                GameTooltip:AddLine(ln, 0.72, 0.90, 0.78, true)
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", GameTooltip_Hide)
    end
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
        row.sub:SetText("|cFF888888" .. (PRES_LABEL[pres] or L["Hors ligne"]) .. " · " .. lvl .. rep .. "|r")
    end
    UI:_SetArtProfIcons(row, profsList(a.r), a.r, a.name)
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
-- Toggle Partenaire toujours présent ; `partnerOn` (nil = lit a.r.isPartner) permet à la ligne
-- FUSIONNÉE de refléter g.anyPartner (un reroll non-vitrine peut porter le drapeau).
function UI:_ArtRowButtons(row, a, nonAddon, partnerOn)
    local D = COC.Directory
    row.whisper:SetScript("OnClick", function() if ChatFrame_SendTell then ChatFrame_SendTell(a.name) end end)
    -- Présence 3 ÉTATS : « en ligne sans addon » (game) reste joignable par /w — le bouton suit la
    -- pastille jaune. Caché seulement pour une entrée « ajoutée » réellement hors ligne.
    local pres = (D and D.PresenceOf and D:PresenceOf(a.name)) or (a.online and "online" or "offline")
    row.whisper:SetShown(pres ~= "offline" or a.r.source ~= "added")
    if partnerOn == nil then partnerOn = a.r.isPartner and true or false end
    row.partner._on = partnerOn
    row.partner.tex:SetDesaturated(not partnerOn)
    row.partner.tex:SetAlpha(partnerOn and 1 or 0.4)
    row.partner:SetScript("OnClick", function() UI:_TogglePartnerSet(a.name) end)
    row.partner:Show()
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
    local rw = self.artListW or A.WIDE_W   -- largeur de la zone artisansList (lue au build)
    r = CreateFrame("Button", nil, self.artListContent); r:SetSize(rw, ARH); r:SetPoint("TOPLEFT", 0, -(i - 1) * ARH)
    Skin.PersonHighlight(r)   -- surbrillance bleue native (liste d'Amis) — homogène avec Commande/Récolte
    r.dot   = Skin.MakeStatusIcon(r, 14); r.dot:SetPoint("LEFT", 6, 0)
    r.name  = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    r.name:SetPoint("TOPLEFT", 22, -5); r.name:SetWidth(150); r.name:SetJustifyH("LEFT"); Skin.ApplyShadow(r.name)
    r.sub   = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.sub:SetPoint("TOPLEFT", 22, -22); r.sub:SetWidth(150); r.sub:SetJustifyH("LEFT"); Skin.ApplyShadow(r.sub)
    r.profsFrame = CreateFrame("Frame", nil, r)
    r.profsFrame:SetPoint("LEFT", 180, 0); r.profsFrame:SetSize(rw - 306, ARH)   -- resserré : place à l'étoile partenaire
    r.profIconPool = {}
    r.src   = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); r.src:SetPoint("RIGHT", -116, 0); Skin.ApplyShadow(r.src)
    -- Toggle « Partenaire » (drapeau explicite priorisé dans l'alerte de don) : icône pleine = partenaire,
    -- désaturée = non. Câblé sur _TogglePartnerSet (agit sur tout le set de rerolls vérifiés).
    r.partner = CreateFrame("Button", nil, r); r.partner:SetSize(18, 18); r.partner:SetPoint("RIGHT", -92, 0)
    r.partner.tex = r.partner:CreateTexture(nil, "ARTWORK"); r.partner.tex:SetAllPoints()
    r.partner.tex:SetTexture(Skin.tex.partner); r.partner.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    r.partner:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetText(btn._on and L["Retirer des partenaires"] or L["Marquer comme partenaire"], 1, 1, 1)
        GameTooltip:Show()
    end)
    r.partner:SetScript("OnLeave", GameTooltip_Hide)
    r.whisper = Skin.MakeGoldButton(r, 78, 22, L["Chuchoter"]); r.whisper:SetPoint("RIGHT", -6, 0)
    r.addFriend = Skin.MakeGoldButton(r, 78, 18, L["Ajouter ami"]); r.addFriend:SetPoint("RIGHT", -6, -9); r.addFriend:Hide()
    self.artListRows[i] = r; return r
end
