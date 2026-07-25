-- CraftingOrderClassic_ProfWindow_Route.lua — fenêtre « PLAN DE ROUTE » de montée de métier
-- (étage ③ de l'aide à la progression) : « du rang actuel au plafond, quoi crafter, combien de
-- fois, pour combien ». Le CALCUL (marche gloutonne, seuils réels, amortissement des plans,
-- exclusions cooldown/coût partiel) vit dans CraftingOrderClassic_Route.lua (COC.Route), partagé
-- avec la bourse d'artisan — ici : le câblage MON perso (recettes de la fenêtre native + couleur
-- LIVE du client au rang courant, cohérence avec le badge de la liste) et toute l'UI.
-- Tout est soft-dep : sans Lazy Gold, le bouton ouvre la popup NeedLazyGold ; sans ce fichier,
-- rien ne change (hooks sous garde nil dans _ProfWindow_Toolbar).

local COC  = CraftingOrderClassic
local PW   = COC.ProfWindow
local Skin = COC.UI.Skin
local L    = COC.L

local ROW_H = 18
-- Flèche « vers » en TEXTURE native : la police rend « → » en tofu (piège wow-ui-tofu-textures,
-- vu en jeu sur la capture user 2026-07-17 — « Rank 250 □ 300 »).
local ARROW = "|TInterface\\ChatFrame\\ChatFrameExpandArrow:12:12|t"

-- La route de MON perso : rang/plafond de la session ouverte + couleur LIVE du client au rang
-- courant (les seuils Wowhead basculent à ±1 rang des couleurs réelles — dump user 2026-07-18,
-- 4 recettes au rang pile sur un seuil ; les seuils data ne projettent que les rangs FUTURS),
-- recettes apprises de la fenêtre native, plans achetables INCLUS. Calcul : COC.Route.
function PW:_ComputeRoute()
    -- ⚠️ PAS de `X and X:f()` en assignation multiple : `and` TRONQUE le multi-retour (maxRank perdu
    -- → la route s'arrêtait au prochain palier CAPS au lieu du vrai plafond entraîné).
    local rank, maxRank
    if COC.Craft then rank, maxRank = COC.Craft:OpenRank() end
    if not (rank and COC.Route) then return nil end
    local live = {}
    for _, e in ipairs(self.recipes or {}) do
        if e.difficulty and not e.isMissing then
            if e.spellID then live["s" .. e.spellID] = e.difficulty end
            if e.itemID  then live["i" .. e.itemID]  = e.difficulty end
        end
    end
    -- Plans achetables INCLUS par défaut (case « inclure les plans » — db.routePlans, nil = coché) :
    -- indépendante de celle de la bourse (db.needsPlans) — deux fenêtres, deux préférences.
    local withPlans = not (COC.db and COC.db.routePlans == false)
    return COC.Route:Compute(self.profKey, rank, maxRank,
        { known = self:_KnownRecipeSet(), live = live, plans = withPlans })
end

-- Nom affichable d'un segment : objet produit (localisé si en cache client), repli nom canonique
-- CraftLink puis nom de sort (enchants = services sans objet).
local function segName(sid, prod)
    local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    local nm = prod and GetItemInfo and GetItemInfo(prod)
    if not nm and prod and lib and lib.ItemName then nm = lib:ItemName(prod) end
    if not nm and GetSpellInfo then nm = GetSpellInfo(sid) end
    if not nm and lib and lib.RecipeName then nm = lib:RecipeName(sid) end
    return nm or ("spell:" .. sid)
end

-- En-tête riche façon bourse : icône du métier + libellé + rang ARROW cible (une ligne). Le total
-- reste dans le coin droit (f.sub).
local function headText(profKey, from, to)
    local icon = Skin.ProfIcon(profKey)
    return (icon and ("|T" .. icon .. ":14:14|t ") or "")
        .. "|cFFE8B84B" .. (Skin.ProfLabel(profKey) or "?") .. "|r  "
        .. "|cFF9AC0E8" .. from .. "|r" .. ARROW .. "|cFF9AC0E8" .. to .. "|r"
end

local function segTooltip(row)
    local s = row.seg; if not s then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT"); GameTooltip:ClearLines()
    -- Fiche COMPLÈTE de l'objet produit en tête (repli nom : enchants sans objet, item hors cache
    -- — retour user 2026-07-19, le survol des segments ne montrait pas l'objet).
    if not s.gap and s.prod then Skin.TipItem(GameTooltip, s.prod, segName(s.sid, s.prod))
    else GameTooltip:SetText(row.name:GetText() or "", 1, 1, 1) end
    if s.gap then
        GameTooltip:AddLine(L["Aucune recette calculable sur ce segment (prix HV manquants, ou plans introuvables)."], 0.8, 0.8, 0.8, true)
    else
        GameTooltip:AddLine(string.format(L["Crafts attendus : ~%d"], math.ceil(s.crafts - 0.001)), 0.60, 0.75, 0.91)
        GameTooltip:AddLine(L["Réactifs (espéré)"] .. " : " .. GetCoinTextureString(math.floor(s.cost + 0.5)), 0.60, 0.75, 0.91)
        if (s.plan or 0) > 0 then
            GameTooltip:AddLine(L["Plan à acheter"] .. " : " .. GetCoinTextureString(s.plan), 0.91, 0.72, 0.29)
        end
        if s.partial then
            GameTooltip:AddLine(L["Coût partiel : au moins un réactif sans prix HV."], 0.8, 0.8, 0.8, true)
        end
    end
    GameTooltip:Show()
end

-- Fenêtre (construction paresseuse) : en-tête « rang → cible » + total, liste scrollée de segments,
-- note d'estimation en pied. Position persistée (db.routeWinPos). Échap la ferme (proxy MakeWindow).
function PW:_BuildRouteWin()
    local f = Skin.MakeWindow("CraftingOrderRouteWindow", 430, 400, {
        title = L["Plan de route"], portrait = "Interface\\Icons\\INV_Misc_Map_01",
        strata = "FULLSCREEN_DIALOG",
        pos = COC.db and COC.db.routeWinPos,
        onMoved = function(p, rp, x, y) if COC.db then COC.db.routeWinPos = { p, rp, x, y } end end,
    })
    local inset = f.Inset or f
    local head = inset:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    head:SetPoint("TOPLEFT", 10, -9); f.head = head
    local sub = inset:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sub:SetPoint("TOPRIGHT", -30, -10); sub:SetJustifyH("RIGHT"); f.sub = sub
    local scroll = CreateFrame("ScrollFrame", "CraftingOrderRouteScroll", inset, "UIPanelScrollFrameTemplate")
    -- Bas relevé (46) : place pour la case « inclure les plans » sous la zone scrollée.
    scroll:SetPoint("TOPLEFT", 6, -30); scroll:SetPoint("BOTTOMRIGHT", -26, 46)
    Skin.ScrollTrack("CraftingOrderRouteScroll")
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(370, 1); scroll:SetScrollChild(content)
    f.scroll, f.content, f.rows = scroll, content, {}
    f.slots, f.lines = {}, {}   -- pools du bloc « fournitures » (helpers partagés de la bourse)
    -- Bandeau « Étapes (N) » repliable en tête du contenu scrollé (db.routeSegCollapsed) : dans la
    -- petite fenêtre, replier les segments remonte le bloc fournitures au-dessus de la ligne de flottaison.
    local seg = CreateFrame("Button", nil, content)
    seg:SetHeight(ROW_H); seg:SetPoint("RIGHT", content, "RIGHT", 0, 0)
    local sico = seg:CreateTexture(nil, "ARTWORK"); sico:SetSize(14, 14); sico:SetPoint("LEFT", 2, 0); seg.ico = sico
    local slbl = seg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    slbl:SetPoint("LEFT", sico, "RIGHT", 4, 0); slbl:SetJustifyH("LEFT"); seg.lbl = slbl
    seg:SetScript("OnClick", function()
        if COC.db then COC.db.routeSegCollapsed = not COC.db.routeSegCollapsed end
        PW:_FillRoute()
    end)
    seg:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_RIGHT"); GameTooltip:SetText(L["Replier / déplier les étapes."], 1, 1, 1); GameTooltip:Show()
    end)
    seg:SetScript("OnLeave", GameTooltip_Hide)
    seg:Hide(); f.segToggle = seg
    local msg = inset:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    msg:SetPoint("CENTER", 0, 10); msg:SetWidth(340); msg:Hide(); f.msg = msg
    -- Case « inclure les plans à acheter » (parité avec la bourse) — recalcule la route au clic.
    local chk = Skin.MakeCheckButton(inset, L["Inclure les plans à acheter"], 18)
    chk:SetPoint("BOTTOMLEFT", 8, 24)
    chk:SetScript("OnClick", function(cb)
        if COC.db then COC.db.routePlans = cb:GetChecked() and true or false end
        PW:_FillRoute()
    end)
    f.chk = chk
    local cav = inset:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    cav:SetPoint("BOTTOMLEFT", 10, 7); cav:SetPoint("BOTTOMRIGHT", -10, 7); cav:SetJustifyH("LEFT")
    cav:SetText(L["Estimation : chance de point par couleur, prix du dernier scan HV (Lazy Gold)."])
    -- Aide contextuelle « bouton i » (même mécanisme que la fenêtre principale ; soft-dep HelpPlate).
    if HelpPlate then
        f.helpBtn = Skin.MakeHelpButton(f, function() PW:_ToggleRouteHelp() end, {
            point   = { "CENTER", f, "TOPLEFT", 8, 6 },
            tooltip = L["Aide : survole les zones surlignées pour comprendre chaque fonction."],
        })
    end
    self.routeWin = f
    return f
end

-- Voile d'aide de la fenêtre Route : deux bulles (en-tête rang/total + liste des segments).
function PW:_ToggleRouteHelp()
    if Skin.HelpIsOpen() then Skin.HideHelp(); return end
    local f = self.routeWin; if not f then return end
    Skin.ShowHelp(f, {
        { frame = f.head, dir = "DOWN",
          text = L["En tête : rang actuel, plafond entraînable, et coût total estimé (« > » = des rangs sans recette calculable, total incomplet)."] },
        { frame = f.scroll, dir = "RIGHT",
          text = L["Un segment par ligne : plage de rangs, recette au meilleur coût par point espéré, « ×~N » = crafts attendus, et le coût du segment (parchemin = plan à acheter d'abord, compté dedans). Survole une ligne pour le détail. La route se recalcule à chaque point gagné."] },
    }, f.helpBtn)
end

-- Ligne de segment du pool (créée à la demande) : plage de rangs, icône, nom ×~N, coût à droite.
-- La position VERTICALE est posée par _FillRoute (elle dépend du bandeau repliable + de l'index).
function PW:_RouteRow(i)
    local f = self.routeWin
    if f.rows[i] then return f.rows[i] end
    local row = CreateFrame("Button", nil, f.content)
    row:SetHeight(ROW_H)
    local rng = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rng:SetPoint("LEFT", 2, 0); rng:SetWidth(74); rng:SetJustifyH("LEFT"); row.rng = rng
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ROW_H - 4, ROW_H - 4); icon:SetPoint("LEFT", rng, "RIGHT", 2, 0)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93); row.icon = icon
    local cost = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cost:SetPoint("RIGHT", -4, 0); cost:SetJustifyH("RIGHT"); row.cost = cost
    local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    name:SetPoint("LEFT", icon, "RIGHT", 4, 0); name:SetPoint("RIGHT", cost, "LEFT", -6, 0)
    name:SetJustifyH("LEFT"); name:SetWordWrap(false); row.name = name
    row:SetScript("OnEnter", segTooltip)
    row:SetScript("OnLeave", GameTooltip_Hide)
    f.rows[i] = row
    return row
end

local function fillSegRow(row, s)
    row.seg = s
    row.rng:SetText("|cFF9AC0E8" .. s.from .. "|r" .. ARROW .. "|cFF9AC0E8" .. s.to .. "|r")
    if s.gap then
        row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); row.icon:SetDesaturated(true)
        row.name:SetText("|cFF888888" .. L["aucune recette calculable"] .. "|r")
        row.cost:SetText("")
    else
        row.icon:SetTexture((s.prod and GetItemIcon and GetItemIcon(s.prod))
            or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.icon:SetDesaturated(false)
        local plan = (s.plan or 0) > 0 and "|TInterface\\Icons\\INV_Scroll_03:12:12|t " or ""
        row.name:SetText(plan .. segName(s.sid, s.prod)
            .. string.format(" |cFFAAAAAA×~%d|r", math.ceil(s.crafts - 0.001)))
        row.cost:SetText(GetCoinTextureString(math.floor(s.cost + (s.plan or 0) + 0.5))
            .. (s.partial and " |cFF888888(?)|r" or ""))   -- coût partiel : réactif sans prix HV
    end
    row:Show()
end

-- Bandeau « Étapes (N) » repliable : positionne + peint (icône +/− selon l'état), ou masque s'il
-- n'y a aucun segment. Renvoie le décalage vertical à appliquer au contenu (0 si masqué).
function PW:_SyncSegToggle(f, n, collapsed)
    local t = f.segToggle
    if not t or n == 0 then if t then t:Hide() end; return 0 end
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT", 0, 0); t:SetPoint("RIGHT", f.content, "RIGHT", 0, 0)
    t.ico:SetTexture(collapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
    t.lbl:SetText("|cFFE8B84B" .. string.format(L["Étapes (%d)"], n) .. "|r")
    t:Show()
    return ROW_H
end

-- (Re)calcule et peint la route. Mémorise (métier, rang) du calcul — _SyncRouteBtn re-remplit
-- quand l'un des deux change (la route avance en direct à chaque point gagné).
function PW:_FillRoute()
    local f = self.routeWin; if not f then return end
    local route = self:_ComputeRoute()
    self._routeProf, self._routeRank = self.profKey, route and route.rank or nil
    self._routeAt = GetTime and GetTime() or 0
    Skin.SetWindowPortrait(f, Skin.ProfIcon(self.profKey) or "Interface\\Icons\\INV_Misc_Map_01")
    if f.SetTitle then f:SetTitle(L["Plan de route"] .. " — " .. Skin.ProfLabel(self.profKey)) end
    if f.chk then f.chk:SetChecked(not (COC.db and COC.db.routePlans == false)) end
    local segs = route and route.segments or {}
    -- Bandeau repliable en tête ; segments décalés dessous (ou masqués si replié).
    local collapsed = (COC.db and COC.db.routeSegCollapsed) and true or false
    local baseY = self:_SyncSegToggle(f, #segs, collapsed)
    if collapsed then
        for i = 1, #f.rows do f.rows[i]:Hide(); f.rows[i].seg = nil end
    else
        for i, s in ipairs(segs) do
            local row = self:_RouteRow(i)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, -(baseY + (i - 1) * ROW_H))
            row:SetPoint("RIGHT", f.content, "RIGHT", 0, 0)
            fillSegRow(row, s)
        end
        for i = #segs + 1, #f.rows do f.rows[i]:Hide(); f.rows[i].seg = nil end
    end
    self:_FillRouteSupply(f, route, baseY + (collapsed and 0 or #segs * ROW_H))
    if not route then
        f.head:SetText(""); f.sub:SetText("")
        f.msg:SetText(L["Rien à calculer — scanne l'HV (Auctionator) puis rouvre ce panneau."]); f.msg:Show()
        return
    end
    f.head:SetText(headText(self.profKey, route.rank, route.target))
    if route.done then
        f.sub:SetText("")
        local R = COC.Route
        local g = (R and R.Gateway) and R:Gateway(self.profKey, route.rank)
        local higher = (R and R.HasHigherTier) and R:HasHigherTier(self.profKey, route.rank)
        if g or higher then
            -- Un palier supérieur existe (livre curaté OU formateur) : le bloc livre/formateur est
            -- peint par _FillRouteSupply ; l'en-tête pointe vers le plafond visé (nextCap curaté, ou
            -- prochain palier standard — le +5 racial ne change pas le palier ciblé).
            local nextCap = (g and g.nextCap) or (R.NextTierCap and R:NextTierCap(route.rank)) or route.target
            f.head:SetText(headText(self.profKey, route.rank, nextCap))
            f.msg:Hide()
        else
            -- Aucune recette au-dessus dans la saveur chargée : c'est réellement le maximum ici.
            f.msg:SetText(L["Rang au plafond — c'est le maximum ici."]); f.msg:Show()
        end
        return
    end
    local hasGap = false
    for _, s in ipairs(segs) do if s.gap then hasGap = true; break end end
    local total = GetCoinTextureString(math.floor(route.mats + route.plans + 0.5))
    -- « > » (ASCII, le ≥ risque le tofu) : trous OU coûts partiels → le total est un plancher.
    f.sub:SetText(string.format(L["Total estimé : %s"], ((hasGap or route.partial) and "> " or "") .. total))
    f.msg:SetShown(#segs == 0)
    if #segs == 0 then f.msg:SetText(L["Rien à calculer — scanne l'HV (Auctionator) puis rouvre ce panneau."]) end
end

-- Bloc « FOURNITURES » sous les segments (demande user 2026-07-19, après la bourse) : composants
-- AGRÉGÉS de toute la route (décomposition/crédit, vendeur en note) + plans à acheter avec le PNJ
-- où aller. Helpers PARTAGÉS de la bourse (_UI_Artisans_Needs — garde nil : soft-dep, sans ce
-- fichier la fenêtre garde ses segments seuls). Fixe la hauteur finale du contenu scrollé.
function PW:_FillRouteSupply(f, route, startY)
    local segs = route and route.segments or {}
    local y = startY or (#segs * ROW_H)
    local used = { head = 0, slot = 0, line = 0 }
    local U = COC.UI
    if route and route.done then
        y = self:_FillRouteGateway(f, used, y, route)   -- au plafond : comment débloquer la suite
    elseif route and not route.done and U and U._FillSupplyBlock and COC.Route then
        local m = COC.Route:Materials(self.profKey, route)
        if m and (#m.mats > 0 or #m.plans > 0) then
            y = U:_NeedsTextLine(f, used, y + 8, "|cFFE8B84B" .. L["Fournitures (agrégées)"] .. "|r")
            y = U:_FillSupplyBlock(f, used, y, self.profKey, m)
        end
    end
    for i = used.slot + 1, #(f.slots or {}) do f.slots[i]:Hide() end
    for i = used.line + 1, #(f.lines or {}) do f.lines[i]:Hide() end
    f.content:SetHeight(math.max(y, 1))
end

-- PNJ formateur du PALIER SUIVANT : première recette apprise plus haut que `rank` ET enseignée au
-- FORMATEUR (SourceKind), résolue en ligne PNJ MTSL « [niv] Nom — Zone (x, y) ». C'est le même PNJ
-- qui débloque le rang supérieur (ex. Artisan Joaillerie). nil si MTSL absent ou rien de résolu.
local function nextTrainerLine(profKey, rank)
    local M = COC.MTSL
    local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    if not (M and M.SourceNpcLine and M.SourceKind and lib and lib.GetRecipes and lib.RecipeLearnedAt) then return nil end
    local cands = {}
    for _, sid in ipairs(lib:GetRecipes(profKey) or {}) do
        local at = lib:RecipeLearnedAt(profKey, sid)
        if at and at > rank then cands[#cands + 1] = { sid = sid, at = at } end
    end
    table.sort(cands, function(a, b) return a.at < b.at end)
    for _, c in ipairs(cands) do
        if M:SourceKind(profKey, c.sid) == "trainer" then
            local ln = M:SourceNpcLine(profKey, c.sid)
            if ln then return ln end
        end
    end
    return nil
end

-- Bloc « débloquer le palier suivant » (fenêtre AU plafond) : DEUX voies. (1) Passerelle curatée
-- (COC.Route:Gateway) = un LIVRE de rang acheté chez un PNJ (Premiers soins) → icône + nom + prix +
-- vendeur. (2) Sinon, palier supérieur présent dans les données (HasHigherTier) mais entraîné au
-- FORMATEUR (Joaillerie & co) → « entraîne le rang supérieur » + le PNJ formateur (MTSL). Rien si ni
-- l'un ni l'autre (vrai maximum). PNJ/faction résolus par MTSL, repli texte sans lui. Renvoie le y.
function PW:_FillRouteGateway(f, used, y, route)
    local U, R = COC.UI, COC.Route
    if not (route and U and U._NeedsTextLine and R) then return y end
    local g = R.Gateway and R:Gateway(self.profKey, route.rank)
    local higher = R.HasHigherTier and R:HasHigherTier(self.profKey, route.rank)
    if not (g or higher) then return y end
    y = U:_NeedsTextLine(f, used, y + 8, "|cFFE8B84B" .. L["Débloquer le palier suivant"] .. "|r")
    if g then
        local nm = (g.item and GetItemInfo and GetItemInfo(g.item)) or g.name or L["Livre de rang"]
        local price = (g.price and g.price > 0) and (" — " .. GetCoinTextureString(g.price)) or ""
        y = U:_NeedsTextLine(f, used, y, "|TInterface\\Icons\\INV_Scroll_03:12:12|t |cFFEEDD88"
            .. string.format(L["À apprendre : %s"], nm) .. price .. "|r")
        local M, npc = COC.MTSL, nil
        for _, id in ipairs(g.vendors or {}) do
            npc = (M and M.NpcLine) and M:NpcLine(id) or nil
            if npc then break end
        end
        y = U:_NeedsTextLine(f, used, y, "|cFF888888" .. (npc
            and string.format(L["Vendu par : %s"], npc)
            or L["Vendu chez un PNJ — installe MTSL pour voir où."]) .. "|r")
    else
        y = U:_NeedsTextLine(f, used, y, "|cFF88CCFF"
            .. L["Entraîne le rang supérieur chez ton formateur de métier."] .. "|r")
        local ln = nextTrainerLine(self.profKey, route.rank)
        if ln then y = U:_NeedsTextLine(f, used, y, "|cFF888888" .. string.format(L["Formateur : %s"], ln) .. "|r") end
    end
    return y
end

-- Ouvre/ferme le panneau (bouton carte de la barre d'outils Recettes). Sans Lazy Gold : popup
-- d'incitation (même pattern que les toggles de tri).
function PW:ToggleRoute()
    local LG = COC.LazyGold
    if not (LG and LG:IsAvailable()) then COC:NeedLazyGold(); return end
    local f = self.routeWin or self:_BuildRouteWin()
    if f:IsShown() then f:Hide() else self:_FillRoute(); f:Show() end
    self:_SyncRouteBtn()
end

-- Bouton « carte » dans le slot recTools (construit par _BuildRecipeTools sous garde nil).
function PW:_BuildRouteBtn(tz)
    local b = self:_MakeToolBtn(tz, function()
        return L["Plan de route : quoi crafter pour monter au moins cher."]
    end, function() PW:ToggleRoute() end)
    b:SetPoint("LEFT", 68, 0)
    local map = b:CreateTexture(nil, "ARTWORK")
    map:SetTexture("Interface\\Icons\\INV_Misc_Map_01"); map:SetSize(15, 15)
    map:SetTexCoord(0.07, 0.93, 0.07, 0.93); map:SetPoint("CENTER"); b.map = map
    self.recRouteBtn = b
end

-- État du bouton (appelé par _SyncSortHeader à chaque refresh) : masqué en reroll ; coloré si Lazy
-- Gold absent (incite au clic → popup) ou panneau ouvert, grisé sinon. Fenêtre ouverte : re-remplit
-- à chaque refresh de la liste (throttle 1 s) — même cadence que le badge « meilleur coût/point »,
-- pour que la route suive AUSSI les prix Lazy Gold (vécu 2026-07-18 : route figée sur d'anciens prix
-- ≠ badge recalculé → les deux guides se contredisaient) ; immédiat si métier ou rang a changé.
function PW:_SyncRouteBtn()
    local b = self.recRouteBtn
    if b then
        local show = not self.rerollKey
        b:SetShown(show and true or false)
        local ok = COC.LazyGold and COC.LazyGold:IsAvailable()
        local active = (self.routeWin and self.routeWin:IsShown()) and true or false
        if b.onBG then b.onBG:SetShown(active) end
        if b.map then b.map:SetDesaturated((ok and not active) and true or false) end
    end
    local f = self.routeWin
    if f and f:IsShown() then
        local rank = COC.Craft and COC.Craft:OpenRank()
        local fresh = ((GetTime and GetTime() or 0) - (self._routeAt or 0)) < 1
        if self._routeProf ~= self.profKey or (rank and rank ~= self._routeRank) or not fresh then
            self:_FillRoute()
        end
    end
end
