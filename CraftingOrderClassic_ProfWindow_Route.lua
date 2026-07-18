-- CraftingOrderClassic_ProfWindow_Route.lua — PLAN DE ROUTE de montée de métier (étage ③ de l'aide
-- à la progression) : « du rang actuel au plafond, quoi crafter, combien de fois, pour combien ».
-- Marche gloutonne rang par rang : à chaque rang, la recette au meilleur coût/point ESPÉRÉ parmi
-- les candidates (apprises + manquantes ACHETABLES — formateur/vendeur prix MTSL, sinon objet-plan
-- coté à l'HV) ; au rang COURANT la couleur est celle du CLIENT (cohérence avec le badge de la
-- liste), aux rangs FUTURS elle vient des seuils réels CraftLink `skillColors` (lib v11, source
-- Wowhead, précis à ±1 rang aux bornes). Le prix d'un plan à acheter est AMORTI sur les points qu'il peut
-- encore servir (comparaison équitable avec les recettes déjà connues) puis compté UNE fois.
-- Exclues : recettes à cooldown (1/jour ≠ route) et recettes au coût partiel (réactif sans prix —
-- un coût sous-estimé détournerait toute la route). Les rangs sans candidate = segment « ? ».
-- Tout est soft-dep : sans Lazy Gold, le bouton ouvre la popup NeedLazyGold ; sans ce fichier,
-- rien ne change (hooks sous garde nil dans _ProfWindow_Toolbar).

local COC  = CraftingOrderClassic
local PW   = COC.ProfWindow
local Skin = COC.UI.Skin
local L    = COC.L

-- Chance de point par couleur — MÊMES paliers que _ProfWindow_Leveling (les deux doivent raconter
-- la même histoire) : orange garanti, jaune/vert décroissants, gris exclu.
local CHANCE = { optimal = 1.0, medium = 0.75, easy = 0.25 }
-- Plafonds d'entraînement, repli si OpenRank ne rend pas de maxRank (fiche annuaire sans max).
local CAPS = { 75, 150, 225, 300, 375, 450 }
local ROW_H = 18
-- Flèche « vers » en TEXTURE native : la police rend « → » en tofu (piège wow-ui-tofu-textures,
-- vu en jeu sur la capture user 2026-07-17 — « Rank 250 □ 300 »).
local ARROW = "|TInterface\\ChatFrame\\ChatFrameExpandArrow:12:12|t"

-- Couleur d'une recette à un rang FUTUR, d'après ses seuils réels {orange, jaune, vert, gris}.
local function colorAt(c, r)
    if r >= c[4] then return nil end
    if r >= c[3] then return "easy" end
    if r >= c[2] then return "medium" end
    return "optimal"
end

-- Candidates de la route : toutes les recettes du catalogue CraftLink qui ont des seuils, un coût
-- de réactifs COMPLET, pas de cooldown, et qui sont soit apprises, soit au plan ACHETABLE (prix
-- formateur/vendeur MTSL, ou objet-plan coté à l'HV). nil si les briques manquent.
function PW:_RouteCandidates()
    local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    local LG, M = COC.LazyGold, COC.MTSL
    if not (lib and lib.RecipeColors and LG and LG:IsAvailable() and self.profKey) then return nil end
    -- Difficulté LIVE des recettes de la fenêtre métier ouverte : au rang COURANT le client fait foi
    -- (les seuils Wowhead basculent à ±1 rang des couleurs réelles — dump user 2026-07-18, 4 recettes
    -- au rang pile sur un seuil) ; les seuils data ne projettent que les rangs FUTURS.
    local live = {}
    for _, e in ipairs(self.recipes or {}) do
        if e.difficulty and not e.isMissing then
            if e.spellID then live["s" .. e.spellID] = e.difficulty end
            if e.itemID  then live["i" .. e.itemID]  = e.difficulty end
        end
    end
    local known, out = self:_KnownRecipeSet(), {}
    for _, sid in ipairs((lib.GetRecipes and lib:GetRecipes(self.profKey)) or {}) do
        local colors = lib:RecipeColors(self.profKey, sid)
        local cd = lib.RecipeCooldown and lib:RecipeCooldown(self.profKey, sid)
        local cost = (colors and not cd) and LG:CraftCost(self.profKey, sid) or nil
        if cost and not cost.missing then
            local prod = lib.RecipeProduct and lib:RecipeProduct(self.profKey, sid)
            local isKnown = (known["s" .. sid] or (prod and known["i" .. prod])) and true or false
            local planPrice
            if not isKnown then
                local kind = (M and M:IsAvailable()) and M:SourceKind(self.profKey, sid) or "unknown"
                if kind == "trainer" or kind == "vendor" then
                    planPrice = (M and M:SourcePrice(self.profKey, sid)) or 0
                else   -- butin/quête/inconnu : achetable seulement si l'objet-plan est coté à l'HV
                    local ri = M and M:RecipeItem(self.profKey, sid)
                    planPrice = ri and LG:ItemValue(ri) or nil
                end
            end
            if isKnown or planPrice then
                out[#out + 1] = {
                    sid = sid, colors = colors, cost = cost.cost, prod = prod,
                    known = isKnown, planPrice = planPrice,
                    live = live["s" .. sid] or (prod and live["i" .. prod]) or nil,
                    learnAt = (lib.RecipeLearnedAt and lib:RecipeLearnedAt(self.profKey, sid)) or colors[1],
                }
            end
        end
    end
    return out
end

-- Meilleure candidate à un rang donné : coût/point espéré minimal ; le prix d'un plan pas encore
-- « acheté » est amorti sur les points qu'il peut encore servir d'ici sa couleur grise (ou la cible).
-- Au rang COURANT (`cur`), la couleur live du client remplace les seuils data quand on la connaît :
-- le 1er segment de la route raconte alors la même histoire que le badge de la liste.
local function pickBest(cands, r, cur, target, bought)
    local best, bestPer, bestChance
    for _, c in ipairs(cands) do
        if c.learnAt <= r then
            local col
            if r == cur and c.live then col = (c.live ~= "trivial") and c.live or nil
            else col = colorAt(c.colors, r) end
            local chance = col and CHANCE[col]
            if chance then
                local per = c.cost / chance
                if not c.known and not bought[c.sid] then
                    per = per + (c.planPrice or 0) / math.max(1, math.min(c.colors[4], target) - r)
                end
                if not bestPer or per < bestPer then best, bestPer, bestChance = c, per, chance end
            end
        end
    end
    return best, bestChance
end

-- La route : segments consécutifs { sid, from, to, crafts, cost, plan, prod } (ou { gap = true }),
-- + totaux mats/plans. `done` = déjà au plafond. nil si rang inconnu ou briques absentes.
function PW:_ComputeRoute()
    local rank, maxRank = COC.Craft and COC.Craft:OpenRank()
    if not rank then return nil end
    local target = (maxRank and maxRank > 0) and maxRank or nil
    if not target then
        for _, cap in ipairs(CAPS) do if rank < cap then target = cap; break end end
    end
    if not target or rank >= target then return { rank = rank, target = target or rank, segments = {}, done = true } end
    local cands = self:_RouteCandidates()
    if not cands then return nil end
    local segs, mats, plans, bought = {}, 0, 0, {}
    for r = rank, target - 1 do
        local best, chance = pickBest(cands, r, rank, target, bought)
        local seg = segs[#segs]
        if not best then
            if seg and seg.gap then seg.to = r + 1
            else segs[#segs + 1] = { gap = true, from = r, to = r + 1 } end
        else
            local planCost = 0
            if not best.known and not bought[best.sid] then
                bought[best.sid] = true; planCost = best.planPrice or 0; plans = plans + planCost
            end
            local matCost = best.cost / chance   -- coût espéré des réactifs pour CE point
            mats = mats + matCost
            if seg and seg.sid == best.sid then
                seg.to = r + 1; seg.crafts = seg.crafts + 1 / chance
                seg.cost = seg.cost + matCost; seg.plan = seg.plan + planCost
            else
                segs[#segs + 1] = { sid = best.sid, from = r, to = r + 1, crafts = 1 / chance,
                    cost = matCost, plan = planCost, prod = best.prod }
            end
        end
    end
    return { rank = rank, target = target, segments = segs, mats = mats, plans = plans }
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

local function segTooltip(row)
    local s = row.seg; if not s then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT"); GameTooltip:ClearLines()
    GameTooltip:SetText(row.name:GetText() or "", 1, 1, 1)
    if s.gap then
        GameTooltip:AddLine(L["Aucune recette calculable sur ce segment (prix HV manquants, ou plans introuvables)."], 0.8, 0.8, 0.8, true)
    else
        GameTooltip:AddLine(string.format(L["Crafts attendus : ~%d"], math.ceil(s.crafts - 0.001)), 0.60, 0.75, 0.91)
        GameTooltip:AddLine(L["Réactifs (espéré)"] .. " : " .. GetCoinTextureString(math.floor(s.cost + 0.5)), 0.60, 0.75, 0.91)
        if (s.plan or 0) > 0 then
            GameTooltip:AddLine(L["Plan à acheter"] .. " : " .. GetCoinTextureString(s.plan), 0.91, 0.72, 0.29)
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
    scroll:SetPoint("TOPLEFT", 6, -30); scroll:SetPoint("BOTTOMRIGHT", -26, 24)
    Skin.ScrollTrack("CraftingOrderRouteScroll")
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(370, 1); scroll:SetScrollChild(content)
    f.scroll, f.content, f.rows = scroll, content, {}
    local msg = inset:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    msg:SetPoint("CENTER", 0, 10); msg:SetWidth(340); msg:Hide(); f.msg = msg
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
function PW:_RouteRow(i)
    local f = self.routeWin
    if f.rows[i] then return f.rows[i] end
    local row = CreateFrame("Button", nil, f.content)
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H); row:SetPoint("RIGHT", f.content, "RIGHT", 0, 0)
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
        row.cost:SetText(GetCoinTextureString(math.floor(s.cost + (s.plan or 0) + 0.5)))
    end
    row:Show()
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
    local segs = route and route.segments or {}
    for i, s in ipairs(segs) do fillSegRow(self:_RouteRow(i), s) end
    for i = #segs + 1, #f.rows do f.rows[i]:Hide(); f.rows[i].seg = nil end
    f.content:SetHeight(math.max(#segs * ROW_H, 1))
    if not route then
        f.head:SetText(""); f.sub:SetText("")
        f.msg:SetText(L["Rien à calculer — scanne l'HV (Auctionator) puis rouvre ce panneau."]); f.msg:Show()
        return
    end
    f.head:SetText(string.format(L["Rang %s"], route.rank .. " " .. ARROW .. " " .. route.target))
    if route.done then
        f.sub:SetText("")
        f.msg:SetText(L["Rang au plafond — vois le formateur pour débloquer la suite."]); f.msg:Show()
        return
    end
    local hasGap = false
    for _, s in ipairs(segs) do if s.gap then hasGap = true; break end end
    local total = GetCoinTextureString(math.floor(route.mats + route.plans + 0.5))
    f.sub:SetText(string.format(L["Total estimé : %s"], (hasGap and "> " or "") .. total))   -- « > » : ASCII (le ≥ risque le tofu)
    f.msg:SetShown(#segs == 0)
    if #segs == 0 then f.msg:SetText(L["Rien à calculer — scanne l'HV (Auctionator) puis rouvre ce panneau."]) end
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
