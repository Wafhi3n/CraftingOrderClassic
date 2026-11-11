-- CraftingOrderClassic_Route_Materials.lua — « liste de courses » d'une route calculée par COC.Route :
-- réactifs agrégés sur tous les segments, sacs et production déduits, intermédiaires décomposés,
-- plans à acheter. Consommateurs : le bloc fournitures du Plan de route (_ProfWindow_Route_Supply)
-- et la bourse d'artisan (_UI_Artisans_Needs). Sorti de Route.lua le 2026-11-10 (500 lignes).
-- Chargé APRÈS Route.lua (.toc) : il lit Route.NewStock.

local COC   = CraftingOrderClassic
local Route = COC.Route
if not Route then return end

local EPS = 1e-6

-- Ajoute `n` unités du réactif `id` au sac `acc`, avec trois raffinements terrain (retours user
-- 2026-07-19, capture Couture, et 2026-09-26, capture Travail du cuir) :
--  · CRÉDIT de production : ce que la route CRAFTE déjà (acc.produced, ex. rouleaux montés pour
--    les points) sert d'abord aux recettes suivantes — pas de double compte ;
--  · SACS : ce que le joueur a déjà (acc.bag, vide pour un tiers) passe ensuite — la liste dit ce
--    qu'il RESTE à réunir, pas ce que la route consomme ;
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
    local inBag = acc.bag[id]
    if inBag > EPS then
        local used = (inBag < n) and inBag or n
        acc.bag[id] = inBag - used
        acc.fromBags = true
        n = n - used
        if n <= EPS then return end
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
-- Auctionator (nil si inconnu) ; vendor = vendu par un PNJ (inutile de fournir, l'UI le sort de la
-- grille). gaps = des rangs sans candidate (liste incomplète). fromBags = les sacs (route.bag, MON
-- perso seulement) ont couvert une partie des besoins : la liste est un RESTE, l'UI le dit.
function Route:Materials(profKey, route)
    local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    if not (lib and route) then return nil end
    local PR, M = COC.Profit, COC.Sources
    local acc = { qty = {}, order = {}, produced = {}, bag = Route.NewStock(route.bag).bag,
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
        if n > 0 then mats[#mats + 1] = { itemID = id, qty = n, cost = PR and PR:ItemValue(id) or nil,
            vendor = (PR and PR.IsVendorItem) and PR:IsVendorItem(id) or false } end
    end
    table.sort(mats, function(a, b) return ((a.cost or 0) * a.qty) > ((b.cost or 0) * b.qty) end)
    return { mats = mats, plans = plans, gaps = gapPts > 0, gapPts = gapPts, partial = partial,
        fromBags = acc.fromBags or nil }
end
