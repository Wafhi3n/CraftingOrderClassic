-- CraftingOrderClassic_Route.lua — cœur de CALCUL du plan de route de montée de métier,
-- PARAMÉTRABLE : marche gloutonne rang par rang (recette au meilleur coût/point ESPÉRÉ), seuils
-- réels CraftLink `skillColors` aux rangs futurs, amortissement du prix des plans à acheter,
-- exclusion des recettes à cooldown et des coûts partiels. Deux consommateurs :
--   · la fenêtre « Plan de route » de la Vue Métier (_ProfWindow_Route.lua — MON perso : recettes
--     de la fenêtre native + couleur LIVE du client au rang courant) ;
--   · la « bourse d'artisan » de l'onglet Artisans (_UI_Artisans_Needs.lua — un TIERS du roster :
--     rang SK diffusé + recettes décodées de son bitfield RK ; pas de couleur live).
-- Les hypothèses (chance de point par couleur) sont ALIGNÉES sur _ProfWindow_Leveling : le badge
-- coût/point, la route et la bourse doivent raconter la même histoire. Aucune UI ici.

local COC   = CraftingOrderClassic
local Route = {}
COC.Route   = Route

-- Chance de point par couleur — MÊMES paliers que _ProfWindow_Leveling.
local CHANCE = { optimal = 1.0, medium = 0.75, easy = 0.25 }
-- Plafonds d'entraînement, repli quand l'appelant ne connaît pas de maxRank.
local CAPS = { 75, 150, 225, 300, 375, 450 }

-- Couleur d'une recette à un rang FUTUR, d'après ses seuils réels {orange, jaune, vert, gris}.
local function colorAt(c, r)
    if r >= c[4] then return nil end
    if r >= c[3] then return "easy" end
    if r >= c[2] then return "medium" end
    return "optimal"
end

-- Candidates de la route. opts = { known = set clé "s<spellID>"/"i<itemID>", live = map même clé →
-- difficulté client (nil pour un tiers), plans = inclure les manquantes ACHETABLES (prix
-- formateur/vendeur MTSL, sinon objet-plan coté à l'HV) }. Sans opts.plans : recettes CONNUES
-- seulement (pour un tiers, on ne présume pas de ce qu'il accepterait d'acheter — sauf demande).
-- nil si les briques manquent (lib sans seuils, Lazy Gold absent).
function Route:Candidates(profKey, opts)
    local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    local LG, M = COC.LazyGold, COC.MTSL
    if not (lib and lib.RecipeColors and LG and LG:IsAvailable() and profKey) then return nil end
    local known, live = opts.known or {}, opts.live or {}
    local out = {}
    for _, sid in ipairs((lib.GetRecipes and lib:GetRecipes(profKey)) or {}) do
        local colors = lib:RecipeColors(profKey, sid)
        local cd = lib.RecipeCooldown and lib:RecipeCooldown(profKey, sid)
        -- Coût des réactifs. Réactif(s) SANS prix HV → candidate de REPLI (`partial`) plutôt
        -- qu'exclue : l'exclusion trouait la route dès qu'un composant courant manquait au scan
        -- (vécu 2026-07-19 : Poussière étrange absente → Enchantement 12→75 réduit à 7 essences).
        -- pickBest ne la retient que si le rang n'a AUCUNE candidate au coût complet (un coût
        -- sous-estimé ne doit jamais rivaliser avec un coût sûr) ; le total passe en « > ».
        local reags = (colors and not cd) and lib.RecipeReagents and lib:RecipeReagents(profKey, sid) or nil
        local cost = (reags and #reags > 0)
            and (LG:CraftCost(profKey, sid) or { cost = 0, missing = true }) or nil
        if cost then
            local prod = lib.RecipeProduct and lib:RecipeProduct(profKey, sid)
            local isKnown = (known["s" .. sid] or (prod and known["i" .. prod])) and true or false
            local planPrice
            if not isKnown and opts.plans then
                local kind = (M and M:IsAvailable()) and M:SourceKind(profKey, sid) or "unknown"
                if kind == "trainer" or kind == "vendor" then
                    planPrice = (M and M:SourcePrice(profKey, sid)) or 0
                else   -- butin/quête/inconnu : achetable seulement si l'objet-plan est coté à l'HV
                    local ri = M and M:RecipeItem(profKey, sid)
                    planPrice = ri and LG:ItemValue(ri) or nil
                end
            end
            if isKnown or planPrice then
                out[#out + 1] = {
                    sid = sid, colors = colors, cost = cost.cost, prod = prod,
                    known = isKnown, planPrice = planPrice, partial = cost.missing or nil,
                    live = live["s" .. sid] or (prod and live["i" .. prod]) or nil,
                    learnAt = (lib.RecipeLearnedAt and lib:RecipeLearnedAt(profKey, sid)) or colors[1],
                }
            end
        end
    end
    return out
end

-- Meilleure candidate à un rang donné : coût/point espéré minimal ; le prix d'un plan pas encore
-- « acheté » est amorti sur les points qu'il peut encore servir d'ici sa couleur grise (ou la
-- cible). Au rang COURANT (`cur`), la couleur live du client — quand elle existe — remplace les
-- seuils data : le 1er segment raconte la même histoire que le badge de la liste.
local function pickBest(cands, r, cur, target, bought)
    local best, bestPer, bestChance, bestPartial
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
                -- Deux étages : une candidate au coût PARTIEL (réactif sans prix, sous-estimé) ne
                -- détrône JAMAIS une candidate au coût complet — repli quand le rang n'a qu'elle.
                local p = c.partial and true or false
                if not best or (bestPartial and not p) or (bestPartial == p and per < bestPer) then
                    best, bestPer, bestChance, bestPartial = c, per, chance, p
                end
            end
        end
    end
    return best, bestChance, bestPartial
end

-- La route : segments consécutifs { sid, from, to, crafts, cost, plan, prod, bought } (ou
-- { gap = true }), + totaux mats/plans. `done` = déjà au plafond. maxRank nil → prochain palier
-- CAPS. nil si briques absentes (cf. Candidates). opts : voir Candidates.
function Route:Compute(profKey, rank, maxRank, opts)
    if not rank then return nil end
    local target = (maxRank and maxRank > 0) and maxRank or nil
    if not target then
        for _, cap in ipairs(CAPS) do if rank < cap then target = cap; break end end
    end
    if not target or rank >= target then return { rank = rank, target = target or rank, segments = {}, mats = 0, plans = 0, done = true } end
    local cands = self:Candidates(profKey, opts or {})
    if not cands then return nil end
    local segs, mats, plans, bought, anyPartial = {}, 0, 0, {}, false
    for r = rank, target - 1 do
        local best, chance, isPartial = pickBest(cands, r, rank, target, bought)
        local seg = segs[#segs]
        if not best then
            if seg and seg.gap then seg.to = r + 1
            else segs[#segs + 1] = { gap = true, from = r, to = r + 1 } end
        else
            local planCost, boughtNow = 0, false
            if not best.known and not bought[best.sid] then
                bought[best.sid] = true; boughtNow = true
                planCost = best.planPrice or 0; plans = plans + planCost
            end
            if isPartial then anyPartial = true end
            local matCost = best.cost / chance   -- coût espéré des réactifs pour CE point
            mats = mats + matCost
            if seg and seg.sid == best.sid then
                seg.to = r + 1; seg.crafts = seg.crafts + 1 / chance
                seg.cost = seg.cost + matCost; seg.plan = seg.plan + planCost
            else
                segs[#segs + 1] = { sid = best.sid, from = r, to = r + 1, crafts = 1 / chance,
                    cost = matCost, plan = planCost, prod = best.prod, bought = boughtNow,
                    partial = isPartial or nil }
            end
        end
    end
    return { rank = rank, target = target, segments = segs, mats = mats, plans = plans,
        partial = anyPartial }
end

-- Ajoute `n` unités du réactif `id` au sac `acc`, avec deux raffinements terrain (retour user
-- 2026-07-19, capture Couture) :
--  · CRÉDIT de production : ce que la route CRAFTE déjà (acc.produced, ex. rouleaux montés pour
--    les points) sert d'abord aux recettes suivantes — pas de double compte ;
--  · DÉCOMPOSITION : un intermédiaire que le MÊME métier fabrique (acc.i2s : objet → recette,
--    ex. rouleau ← étoffe) est remplacé par ses composants de base, récursivement. Garde de
--    profondeur : les transmutations d'essences bouclent (A→B et B→A). numMade inconnu de la lib
--    → 1 craft = 1 objet supposé (vrai pour les rouleaux/barres ; estimation sinon).
local function addReagent(lib, profKey, acc, id, n, depth)
    local credit = acc.produced[id]
    if credit and credit > 0 then
        local used = (credit < n) and credit or n
        acc.produced[id] = credit - used
        n = n - used
        if n <= 0 then return end
    end
    local sid = (depth < 4) and acc.i2s[id]
    local sub = sid and lib.RecipeReagents and lib:RecipeReagents(profKey, sid)
    if sub and #sub > 0 then
        for _, rg in ipairs(sub) do addReagent(lib, profKey, acc, rg[1], n * (rg[2] or 1), depth + 1) end
    else
        if not acc.qty[id] then acc.qty[id] = 0; acc.order[#acc.order + 1] = id end
        acc.qty[id] = acc.qty[id] + n
    end
end

-- « Liste de courses » d'une route : réactifs AGRÉGÉS sur tous les segments (crafts espérés ×
-- quantité, crédit/décomposition cf. addReagent, arrondis au plafond par objet) + plans achetés
-- par la route (objet-plan à fournir, ou plan de FORMATEUR — pas d'objet, il devra l'apprendre au
-- PNJ). Sert à la bourse d'artisan. mats triés par coût total décroissant ; cost = prix unitaire
-- Lazy Gold (nil si inconnu) ; vendor = vendu par un PNJ (inutile de fournir, l'UI le sort de la
-- grille). gaps = des rangs sans candidate (liste incomplète).
function Route:Materials(profKey, route)
    local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    if not (lib and route) then return nil end
    local LG, M = COC.LazyGold, COC.MTSL
    local acc = { qty = {}, order = {}, produced = {},
        i2s = (lib.ItemToSpell and lib:ItemToSpell(profKey)) or {} }
    for _, s in ipairs(route.segments or {}) do
        if not s.gap and s.prod then acc.produced[s.prod] = (acc.produced[s.prod] or 0) + s.crafts end
    end
    local plans, gapPts, partial = {}, 0, false
    for _, s in ipairs(route.segments or {}) do
        if s.gap then gapPts = gapPts + (s.to - s.from)
        else
            if s.partial then partial = true end
            for _, reag in ipairs((lib.RecipeReagents and lib:RecipeReagents(profKey, s.sid)) or {}) do
                addReagent(lib, profKey, acc, reag[1], (reag[2] or 1) * s.crafts, 0)
            end
            if s.bought then
                local kind = (M and M:IsAvailable()) and M:SourceKind(profKey, s.sid) or "unknown"
                local ri = M and M:RecipeItem(profKey, s.sid)
                plans[#plans + 1] = { sid = s.sid, itemID = (kind ~= "trainer") and ri or nil,
                    price = s.plan or 0, trainer = (kind == "trainer") }
            end
        end
    end
    local mats = {}
    for _, id in ipairs(acc.order) do
        local n = math.ceil(acc.qty[id] - 0.001)
        if n > 0 then mats[#mats + 1] = { itemID = id, qty = n, cost = LG and LG:ItemValue(id) or nil,
            vendor = (LG and LG.IsVendorItem) and LG:IsVendorItem(id) or false } end
    end
    table.sort(mats, function(a, b) return ((a.cost or 0) * a.qty) > ((b.cost or 0) * b.qty) end)
    return { mats = mats, plans = plans, gaps = gapPts > 0, gapPts = gapPts, partial = partial }
end
