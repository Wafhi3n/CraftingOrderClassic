-- CraftingOrderClassic_UI_Artisans.lua — onglet « Artisans » : annuaire social.
-- Sidebar SOURCE (Guilde/Amis/Croisés + compteurs), canaux surveillés, sourdine et ajout manuel ; à
-- droite, pills de filtre métier + lignes artisan (présence, niveau, métiers, source, Chuchoter).
-- Lit Directory (cache). Les TEXTES d'une ligne viennent de _UI_Artisans_Text.lua (purs, testés).

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local ARH = 40              -- hauteur ligne artisan
local A   = UI.ART          -- métriques dérivées de la SPEC — cf. _UI_Artisans_Layout.lua

local function trim(s) return s and s:gsub("^%s+", ""):gsub("%s+$", "") or "" end

-- Annuaire d'affichage : on montre AUSSI les non-porteurs « vu crafter » (craftSeen) → variante OrSeen
-- du helper partagé (cf. Skin), contrairement aux onglets Commande/Récolte qui n'incluent QUE SK/RK.
local knowsProf = Skin.KnowsProfOrSeen

-- Métiers connus d'un artisan, en liste { key, sv } : niveau (SK) si connu, sinon recette seule (RK).
-- Union des deux sources : métiers principaux d'abord, puis secondaires, chacun par libellé (Skin.ProfLess).
local function profsList(r)
    local SEC = COC.HIDDEN_PROF or {}      -- seuls les Poisons sautent (Cuisine/Secours/Pêche s'affichent)
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
    table.sort(parts, Skin.ProfLess)   -- principaux d'abord, puis secondaires
    return parts
end
UI._ProfsList = profsList   -- partagé avec la couche de fusion (UI_Artisans_Groups.lua)

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

    -- Deux buckets CONDITIONNELS en fin de liste : « Confédération » (masqué sans GreenWall) et
    -- « Cercle » (masqué si aucune communauté marquée). Ils ne sont plus posés à un rang fixe : dès
    -- qu'il y en a DEUX, en masquer un seul laisserait un trou au milieu de la bande. La position
    -- est donc recalculée sur les seuls boutons visibles (cf. _RelayoutArtSrcTabs). « Ajoutés » aussi
    -- est conditionnelle : pas de bande tant qu'aucun joueur n'a été ajouté (_SyncOptionalArtTabs).
    -- « muted » n'est PAS une source : c'est le panneau de gestion des mis en sourdine (données =
    -- COC.db.mutedPlayers, pas le roster ; cf. UI_Artisans_Muted.lua). Sa bande vit en bas, avec
    -- l'ajout de joueur, hors de la pile des sources (refonte du 2026-09-30) : elle garde son compteur
    -- et sa sélection (artSrcBtns), mais pas de rang dans artSrcOrder.
    -- Les cercles n'ont pas de bande fixe : une bande PAR cercle, créée à la demande (_SyncCircleTabs).
    local srcDefs = { {id="all",label=L["Tous"]}, {id="guild",label=L["Guilde"]}, {id="friend",label=L["Amis"]}, {id="added",label=L["Ajoutés"]}, {id="recent",label=L["Croisés"]}, {id="confed",label=L["Confédération"]}, {id="muted",label=L["En sourdine"]} }
    self.artSrcBtns, self.artSrcOrder = {}, {}
    for _, d in ipairs(srcDefs) do
        local muted = d.id == "muted"
        local b = Skin.MakeFilterButton(muted and self:ArtSec("addPlayer") or sz, 190, 24, d.label)   -- bande de filtre style HdV (verrou doré, pas de bleu)
        local cnt = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cnt:SetPoint("RIGHT", -10, 0); Skin.ApplyShadow(cnt); b.count = cnt
        b:SetScript("OnClick", function() UI.artSource = d.id; UI:_RefreshArtSrcTabs(); UI:RefreshArtisans() end)
        self.artSrcBtns[d.id] = b
        if muted then b:SetPoint("BOTTOMLEFT", 12, 58)
        else self.artSrcOrder[#self.artSrcOrder + 1] = d.id end
    end
    self:_BuildArtChannels(sz)   -- « Canaux surveillés », sous les bandes (_UI_Artisans_Channels.lua)
    self:_RelayoutArtSrcTabs()
    self:_RefreshArtSrcTabs()

    self:_BuildArtisanAddScan(self:ArtSec("addPlayer"))   -- cluster bas de la sidebar (sa zone)
    self:_BuildArtRefreshBar(panel, f)                    -- « Rafraîchir l'annuaire », dans la barre du bas

    -- Bande de filtre métier : libellé + pills (construits paresseusement dans la zone, cf. Icons)
    local band = self:ArtSec("profFilter")
    self.artPillHdr = band:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.artPillHdr:SetPoint("LEFT", A.PAD + 4, 0); self.artPillHdr:SetText("|cFF888888" .. L["Métier :"] .. "|r"); Skin.ApplyShadow(self.artPillHdr)
    self.artPills = {}

    self:_BuildArtList()
    if self._BuildMutedList then self:_BuildMutedList() end   -- panneau « En sourdine » (superposé aux zones, caché)
end

-- Liste des artisans : la liste défilante du kit (palier 2b de la revue d'UI), ancrée aux quatre
-- coins de la zone (la SPEC pilote le pad). `artScroll` garde son nom : le mode « En sourdine »
-- (_UI_Artisans_Muted) le masque quand il prend la place de la liste.
function UI:_BuildArtList()
    local host = CreateFrame("Frame", nil, self:ArtSec("artisansList"))
    host:SetPoint("TOPLEFT", A.PAD, 0)
    host:SetPoint("BOTTOMRIGHT", self:ArtSec("artGutter"), "BOTTOMRIGHT", -Skin.LIST_EDGE, A.PAD)
    self.artScroll = host
    self.artList = Skin.MakeScrollList(host, {
        extent = ARH,
        build  = function(row) UI:_BuildArtRow(row) end,
        fill   = function(row, g)
            if #g.members > 1 then UI:_FillArtGroupRow(row, g)
            else UI:_FillArtRow(row, { name = g.leader, r = g.lead.r, online = g.lead.online }) end
        end,
        empty  = "|cFF888888" .. L["Aucun artisan dans cette source."] .. "|r",
    })
end

-- Cluster du bas de la sidebar (zone « addPlayer » de la SPEC) : la bande « En sourdine » (posée par
-- BuildArtisansTab) et le champ d'ajout manuel — offsets RELATIFS au bas de la zone. La case de
-- repérage des crafteurs a rejoint la liste des canaux surveillés (spec canaux-surveilles), et
-- « Rafraîchir l'annuaire » la barre du bas (_BuildArtRefreshBar) : la place va à la liste des canaux.
function UI:_BuildArtisanAddScan(sec)
    local addHdr = sec:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    addHdr:SetPoint("BOTTOMLEFT", 14, 42); addHdr:SetText(L["AJOUTER UN JOUEUR"])
    addHdr:SetTextColor(Skin.unpack(Skin.color.textMuted))
    local addBox = CreateFrame("EditBox", nil, sec, "InputBoxTemplate")
    addBox:SetSize(150, 20); addBox:SetPoint("BOTTOMLEFT", 16, 16); addBox:SetAutoFocus(false)
    addBox:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)
    addBox:SetScript("OnEnterPressed", function(b) UI:_AddArtisan(b:GetText()); b:SetText(""); b:ClearFocus() end)
    local ghost = sec:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ghost:SetPoint("LEFT", addBox, "LEFT", 4, 0); ghost:SetText(L["Nom du personnage"])
    addBox:SetScript("OnTextChanged", function(b) ghost:SetShown(b:GetText() == "") end)
    local addBtn = Skin.MakeGoldButton(sec, 26, 20, "+")
    addBtn:SetPoint("LEFT", addBox, "RIGHT", 6, 0)
    addBtn:SetScript("OnClick", function() UI:_AddArtisan(addBox:GetText()); addBox:SetText("") end)
end

-- « Rafraîchir l'annuaire » dans la barre du bas de la fenêtre, à côté du compte d'artisans qu'il met
-- à jour. Même montage que la barre d'actions de Commande (_BuildPostActionBar) : un cadre enfant du
-- PANNEAU (il se masque avec l'onglet), calé sur la bande native ; la gauche reste à la ligne réseau.
function UI:_BuildArtRefreshBar(panel, f)
    local bar = CreateFrame("Frame", nil, panel)
    bar:SetAllPoints(f.ActionBar)
    local b = Skin.MakeGoldButton(bar, 150, 20, L["Rafraîchir l'annuaire"])
    b:SetWidth(math.max(150, b.text:GetStringWidth() + 28))   -- pas de reflow : largeur au texte, à la main
    b:SetPoint("RIGHT", -8, 0)
    b:SetScript("OnClick", function() UI:_RefreshDirectory() end)
    self.artRefreshBtn = b
end

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

-- Repose les boutons de source VISIBLES les uns sous les autres. Sans ça, masquer un bucket
-- conditionnel qui n'est pas le dernier laisse un trou dans la bande.
function UI:_RelayoutArtSrcTabs()
    if not (self.artSrcBtns and self.artSrcOrder) then return end
    local row = 0
    for _, id in ipairs(self.artSrcOrder) do
        local b = self.artSrcBtns[id]
        if b and b:IsShown() then
            b:SetPoint("TOPLEFT", 12, -22 - row * 26)
            row = row + 1
        end
    end
    self:_PlaceArtChannels(-22 - row * 26)   -- la liste des canaux commence sous la dernière bande
end

-- Les bandes conditionnelles : « Confédération » n'existe que si GreenWall est chargé, et chaque
-- cercle MARQUÉ a la sienne (_SyncCircleTabs). Si celle qui était sélectionnée disparaît, on retombe
-- sur « Tous » plutôt que d'afficher une liste vide sans explication. Un cercle a sa bande dès qu'il
-- est marqué, même vide (on s'en exclut soi-même) : une bande vide se lit « c'est bien branché ».
-- « Ajoutés », elle, n'apparaît qu'à partir d'un joueur ajouté (`counts` = UI._ArtCounts) : à zéro,
-- elle prenait une ligne à la liste des canaux sans rien filtrer.
function UI:_SyncOptionalArtTabs(counts)
    local D = COC.Directory
    if not self.artSrcBtns then return end
    local hasAdded = ((counts and counts.added) or 0) > 0
    if self.artSrcBtns.added then self.artSrcBtns.added:SetShown(hasAdded) end
    if not hasAdded and self.artSource == "added" then self.artSource = "all" end
    -- Mode solo (/co debug) : on montre tout, pour pouvoir travailler l'UI sans GreenWall.
    local debug = COC.db and COC.db.debug
    local shown = (D and D._GreenWallActive and D:_GreenWallActive()) or debug
    local b = self.artSrcBtns.confed
    if b then b:SetShown(shown and true or false) end
    if not shown and self.artSource == "confed" then self.artSource = "all" end
    if self.artSource == "circle" then self.artSource = "all" end   -- ancienne bande unique, disparue
    self:_SyncCircleTabs()
    self:_RelayoutArtSrcTabs()
    self:_RefreshArtSrcTabs()
end

-- Une bande PAR CERCLE, au nom de la communauté (demandé par le user le 2026-09-28) : on voit d'où vient
-- l'artisan. Boutons créés à la demande puis réutilisés (id « circle:<clubId> »), ajoutés en fin d'ordre ;
-- celui d'un cercle quitté ou démarqué est masqué. Plafond : la bande n'a de place que pour quelques lignes.
local MAX_CIRCLE_TABS = 4
function UI:_SyncCircleTabs()
    local D, want = COC.Directory, {}
    local circles = (D and D.CircleList and D:CircleList()) or {}
    self.artCircleNames = {}   -- id → nom de TOUS les cercles : l'étiquette de source d'une ligne le lit
    for _, c in ipairs(circles) do self.artCircleNames[tostring(c.id)] = c.name end
    for i, c in ipairs(circles) do
        if i > MAX_CIRCLE_TABS then break end
        local id = "circle:" .. c.id
        want[id] = true
        local b = self.artSrcBtns[id]
        if not b then
            b = Skin.MakeFilterButton(self:ArtSec("sources"), 190, 24, c.name)
            local cnt = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            cnt:SetPoint("RIGHT", -10, 0); Skin.ApplyShadow(cnt); b.count = cnt
            b.text:SetPoint("RIGHT", cnt, "LEFT", -4, 0); b.text:SetWordWrap(false)   -- nom long : tronqué
            b:SetScript("OnClick", function() UI.artSource = id; UI:_RefreshArtSrcTabs(); UI:RefreshArtisans() end)
            self.artSrcBtns[id] = b
            self.artSrcOrder[#self.artSrcOrder + 1] = id
        end
        b:SetText(c.name)   -- une communauté peut être renommée
    end
    for id, btn in pairs(self.artSrcBtns) do
        if id:find("^circle:") then
            btn:SetShown(want[id] == true)
            if not want[id] and self.artSource == id then self.artSource = "all" end
        end
    end
end

-- Un artisan est-il dans la source choisie ? Une bande de cercle filtre sur SON cercle (r.circle).
local function inSource(r, src)
    if src == "all" then return true end
    local circle = src:match("^circle:(.+)$")
    if circle then return r.source == "circle" and r.circle == circle end
    return (r.source or "recent") == src
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
    local D = COC.Directory
    -- Compteurs par source (+ « all » = total ; « muted » = mis en sourdine, hors roster). Comptés
    -- AVANT les bandes : « Ajoutés » n'existe qu'à partir d'un joueur ajouté.
    local counts = UI._ArtCounts(D)
    counts.muted = (COC.Moderation and COC.Moderation.MutedList) and #COC.Moderation:MutedList() or 0
    self:_SyncOptionalArtTabs(counts)   -- montre/masque « Ajoutés », « Confédération » et les cercles
    self:_RefreshArtChannels()          -- les cases des canaux surveillés (dont le repérage des crafteurs)
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
        return inSource(r, src) and (not pf or knowsProf(r, pf))
    end)
    table.sort(list, function(a, b)
        if (a.anyPartner and true) ~= (b.anyPartner and true) then return a.anyPartner end   -- partenaires en tête
        if a.presRank ~= b.presRank then return a.presRank > b.presRank end   -- joignable > sans addon > hors ligne
        if a.repMax ~= b.repMax then return a.repMax > b.repMax end   -- réputation max du set, décroissante
        return a.leader < b.leader
    end)

    -- La liste défilante place et remplit les lignes visibles, et dit « aucun artisan » d'elle-même.
    self.artList:SetData(list, true)
end

-- Remplit une ligne artisan. Distingue les NON-porteurs (r.nonAddon, vus crafter via CHAT_MSG_LOOT) :
-- sous-ligne « vu crafter » + tag « VU » au lieu de présence/niveau/réputation.
function UI:_FillArtRow(row, a)
    row:SetScript("OnEnter", nil); row:SetScript("OnLeave", nil)   -- lignes poolées : purge le tooltip de groupe
    local D0 = COC.Directory
    local pres = (D0 and D0.PresenceOf and D0:PresenceOf(a.name)) or (a.online and "online" or "offline")
    row.dot:SetPresence(pres)
    -- Pas de préfixe « partenaire » : l'icône allumée à droite et le tri en tête le disent déjà, et le
    -- préfixe coupait le nom (« Syrine Lytha… », capture du 2026-09-30). Hors ligne, le nom est gris.
    local lfwE = D0 and D0.LFWOf and D0:LFWOf(a.name)
    local lfwTag = lfwE and ("|cFF4CDB6E" .. L["[Dispo]"] .. "|r ") or ""
    row.name:SetText(lfwTag .. UI._ArtNameHex(pres) .. a.name .. "|r")
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
            if lfwE.via then   -- relayé (Directory_TrustRelay) : provenance et fraîcheur
                GameTooltip:AddLine(string.format(L["via %s · il y a %s"], lfwE.via,
                    Skin.FormatDuration(math.max(0, time() - (lfwE.ts or time())))), 0.55, 0.55, 0.55)
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
        row.sub:SetText("|cFF888888" .. UI._ArtSubLine(pres, a.r.level, a.r.rep) .. "|r")
    end
    -- Sa note de membre de la communauté, posée à la main : visible même hors ligne (Directory_Note).
    if a.r.memberNote then row.sub:SetText(row.sub:GetText() .. "|cFF888888 · |r|cFFD8CFA0" .. a.r.memberNote .. "|r") end
    UI:_SetArtProfIcons(row, profsList(a.r), a.r, a.name)
    row.src:SetText("|cFF888888" .. UI._ArtSrcTag(a.r, self.artSource, self.artCircleNames, relayed, nonAddon) .. "|r")
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
    row.whisper:SetScript("OnClick", function()
        if D and D.TrustVerify then D:TrustVerify(a.name) end   -- un LFW relayé : vérifié auprès de lui
        if ChatFrame_SendTell then ChatFrame_SendTell(a.name) end
    end)
    -- Présence 3 ÉTATS : « en ligne sans addon » (game) reste joignable par /w — le bouton suit la
    -- pastille jaune. Caché seulement pour une entrée « ajoutée » réellement hors ligne.
    local pres = (D and D.PresenceOf and D:PresenceOf(a.name)) or (a.online and "online" or "offline")
    row.whisper:SetShown(pres ~= "offline" or a.r.source ~= "added")
    -- Hors ligne, le bouton reste (la présence peut se tromper, et /w marche dès son retour) mais
    -- s'éteint : une colonne de boutons rouges, hors-ligne compris, ne disait plus qui est joignable.
    row.whisper:SetQuiet(pres == "offline")
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

-- Construit une ligne de l'annuaire, la première fois que la liste défilante crée ce cadre. Le
-- remplissage (_FillArtRow / _FillArtGroupRow) repose tout : il était déjà écrit pour un pool.
function UI:_BuildArtRow(r)
    Skin.PersonHighlight(r)   -- surbrillance bleue native (liste d'Amis) — homogène avec Commande/Récolte
    r.dot   = Skin.MakeStatusIcon(r, 14); r.dot:SetPoint("LEFT", 6, 0)
    r.name  = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    r.name:SetPoint("TOPLEFT", 22, -5); r.name:SetWidth(150); r.name:SetJustifyH("LEFT"); Skin.ApplyShadow(r.name)
    r.sub   = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.sub:SetPoint("TOPLEFT", 22, -22); r.sub:SetWidth(150); r.sub:SetJustifyH("LEFT"); Skin.ApplyShadow(r.sub)
    -- Une ligne chacun, tronquée par « … » : « [Partenaire] » + prénom + nom de famille dépassait 150 px
    -- et le nom retombait SUR la sous-ligne (vu en jeu le 2026-09-28).
    r.name:SetWordWrap(false); r.sub:SetWordWrap(false)
    r.profsFrame = CreateFrame("Frame", nil, r)
    -- Ancrée et pas dimensionnée : de x = 180 jusqu'à 126 du bord droit (source, étoile, boutons).
    r.profsFrame:SetPoint("TOPLEFT", 180, 0); r.profsFrame:SetPoint("BOTTOMRIGHT", -126, 0)
    r.profIconPool = {}
    r.src   = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); r.src:SetPoint("RIGHT", -116, 0); Skin.ApplyShadow(r.src)
    r.src:SetWidth(84); r.src:SetJustifyH("RIGHT"); r.src:SetWordWrap(false)   -- un nom de communauté peut être long
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
end
