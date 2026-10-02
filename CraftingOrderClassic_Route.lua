-- CraftingOrderClassic_Route.lua — cœur de CALCUL du plan de route de montée de métier,
-- PARAMÉTRABLE : marche gloutonne rang par rang (recette au meilleur coût/point ESPÉRÉ), seuils
-- réels CraftLink `skillColors` aux rangs futurs, amortissement du prix des plans à acheter,
-- exclusion des recettes à cooldown et des coûts partiels, STOCK (sacs + produits de la route)
-- déduit avant de payer quoi que ce soit au prix HV. Consommateurs :
--   · la fenêtre « Plan de route » de la Vue Métier (_ProfWindow_Route.lua — MON perso : recettes
--     de la fenêtre native + couleur LIVE du client au rang courant + mes sacs) ;
--   · le suivi à l'écran (_Tracker_Next.lua — MON perso, prochain point seulement + mes sacs) ;
--   · la « bourse d'artisan » de l'onglet Artisans (_UI_Artisans_Needs.lua — un TIERS du roster :
--     rang SK diffusé + recettes décodées de son bitfield RK ; ni couleur live, ni sacs).
-- Les hypothèses (chance de point par couleur) sont ALIGNÉES sur _ProfWindow_Leveling : le badge
-- coût/point, la route et la bourse doivent raconter la même histoire. Aucune UI ici.
-- ⚠️ Le badge, lui, ignore les sacs : il chiffre UNE recette au prix HV, pas un chemin. Il ne vit
-- que dans notre liste pleine vue — la colonne greffée de Forever montre la liste de Blizzard.
-- DEUX MODES (spec docs/specs/route-cout-net.md) : par défaut la route choisit sur ce qui SORT de la
-- bourse (le sac est gratuit, le produit ne vaut rien) -- c'est la bourse d'artisan, et tous les
-- appels sans `opts.value`. Avec `opts.value` (Route:MyValuation, fenêtre + suivi), elle choisit sur
-- le coût NET : le sac vaut sa revente, le produit est crédité de la sienne (Route_Value.lua).

local COC   = CraftingOrderClassic
local Route = {}
COC.Route   = Route

-- Chance de point par couleur — MÊMES paliers que _ProfWindow_Leveling.
local CHANCE = { optimal = 1.0, medium = 0.75, easy = 0.25 }
-- Plafonds d'entraînement, repli quand l'appelant ne connaît pas de maxRank.
local CAPS = { 75, 150, 225, 300, 375, 450 }
Route.CAPS = CAPS   -- lu par _Route_Gateway (palier suivant)

-- Couleur d'une recette à un rang FUTUR, d'après ses seuils réels {orange, jaune, vert, gris}.
local function colorAt(c, r)
    if r >= c[4] then return nil end
    if r >= c[3] then return "easy" end
    if r >= c[2] then return "medium" end
    return "optimal"
end

-- Objets qui servent de RÉACTIF à au moins une recette du métier. Une recette dont le produit est
-- dans ce set est une CONVERSION (retailles → cuir léger, étoffe → rouleau, essences) : cf. le
-- bloc « stock » plus bas, qui lui interdit de puiser dans ce que la route a fabriqué.
local function reagentSet(lib, profKey)
    local set = {}
    for _, sid in ipairs((lib.GetRecipes and lib:GetRecipes(profKey)) or {}) do
        for _, rg in ipairs((lib.RecipeReagents and lib:RecipeReagents(profKey, sid)) or {}) do
            set[rg[1]] = true
        end
    end
    return set
end

-- Réactifs d'une recette avec leur prix UNITAIRE — { id, qté, prix|nil } — et le coût d'un craft
-- au prix HV. Le prix unitaire est gardé parce que le stock se déduit réactif par réactif.
-- Réactif SANS prix HV → `missing` : la candidate devient un REPLI (`partial`) plutôt qu'exclue,
-- l'exclusion trouait la route dès qu'un composant courant manquait au scan (vécu 2026-07-19 :
-- Poussière étrange absente → Enchantement 12→75 réduit à 7 essences). pickBest ne la retient que
-- si le rang n'a AUCUNE candidate au coût complet ; le total passe en « > ».
local function pricedReagents(PR, reags)
    local out, cost, missing = {}, 0, false
    for _, rg in ipairs(reags) do
        local n, p = rg[2] or 1, PR:ItemValue(rg[1])
        out[#out + 1] = { rg[1], n, p }
        if p then cost = cost + p * n else missing = true end
    end
    return out, cost, missing
end

-- Prix du plan d'une recette NON apprise, vu par la route : planPrice (nil = pas achetable par la
-- route), planUnknown (prix inconnu : le segment s'affiche « (?) », le total « > »), planDoubt
-- (candidate de REPLI seulement, cf. pickBest). Fonction locale appelée directement : son
-- multi-retour ne passe par aucun `X and X:f()`, il ne se tronque pas.
local function planOf(M, PR, profKey, sid)
    local kind = (M and M:IsAvailable()) and M:SourceKind(profKey, sid) or "unknown"
    if kind ~= "trainer" and kind ~= "vendor" then
        -- butin/quête/inconnu : achetable seulement si l'objet-plan est coté à l'HV
        local ri = M and M:RecipeItem(profKey, sid)
        return ri and PR:ItemValue(ri) or nil
    end
    local price = M and M:SourcePrice(profKey, sid)
    if price then return price end
    -- Prix INCONNU (un plan de formateur tant qu'on n'est pas passé chez lui). On garde la recette
    -- candidate -- « va l'apprendre au formateur » reste le bon conseil -- mais on ne fait PAS
    -- passer l'inconnu pour de la gratuité : le segment est marqué partiel, donc le total
    -- s'affiche comme sous-évalué.
    -- ⚠️ PARTIEL N'EST PAS DOUTEUX. Un formateur ATTESTÉ (Sources:TrainerConfirmed) dont seul le prix
    -- manque concourt à part entière : quelques pièces amorties sur des dizaines de points ne
    -- renversent pas un choix. Le reléguer en repli, comme un réactif sans prix, l'excluait de la
    -- route dès qu'une autre recette était chiffrée -- capture user 2026-10-02 : Rough Grinding
    -- Stone (2 pierres, orange) écartée au profit de la Rough Sharpening Stone verte (4 pierres le
    -- point), jusqu'à ce qu'il l'apprenne. Le marchand au prix inconnu et le formateur seulement
    -- DÉDUIT restent en repli : l'un peut coûter cher, l'autre n'existe peut-être pas.
    local sure = kind == "trainer" and M.TrainerConfirmed and M:TrainerConfirmed(profKey, sid)
    return 0, true, not sure
end

-- Rang requis pour apprendre la recette : celui que le formateur EXIGE quand on l'a lu chez lui
-- (Sources:MinSkill), sinon celui des données, sinon le seuil orange.
local function learnAtOf(lib, M, profKey, sid, colors)
    local at = M and M.MinSkill and M:MinSkill(profKey, sid)
    if not at then at = lib.RecipeLearnedAt and lib:RecipeLearnedAt(profKey, sid) end
    return at or colors[1]
end

-- Valeur de revente mémoïsée le temps d'UN balayage de candidates : un même réactif sert des dizaines
-- de recettes. Sans Route_Value (tests, ancien .toc) : aucune valeur, la route en caisse n'en lit pas.
local function resaleMemo(route)
    if not route.ResaleValue then return function() return nil end end
    local memo = {}
    return function(id)
        if not id then return nil end
        local v = memo[id]
        if v == nil then v = route:ResaleValue(id) or false; memo[id] = v end
        return v or nil
    end
end

-- Candidates de la route. opts = { known = set clé "s<spellID>"/"i<itemID>", live = map même clé →
-- difficulté client (nil pour un tiers), plans = inclure les manquantes ACHETABLES (prix
-- formateur/vendeur, sinon objet-plan coté à l'HV) }. Sans opts.plans : recettes CONNUES
-- seulement (pour un tiers, on ne présume pas de ce qu'il accepterait d'acheter — sauf demande).
-- nil si les briques manquent (lib sans seuils, Auctionator absent). Indépendantes du stock (il
-- se déduit au moment du choix, cf. pickBest) : c'est ce qui les rend cachables (CachedCandidates).
function Route:Candidates(profKey, opts)
    local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    local PR, M = COC.Profit, COC.Sources
    if not (lib and lib.RecipeColors and PR and PR:IsAvailable() and profKey) then return nil end
    local known, live = opts.known or {}, opts.live or {}
    local isReagent = reagentSet(lib, profKey)
    local resaleOf = resaleMemo(self)
    local out = {}
    for _, sid in ipairs((lib.GetRecipes and lib:GetRecipes(profKey)) or {}) do
        local colors = lib:RecipeColors(profKey, sid)
        local cd = lib.RecipeCooldown and lib:RecipeCooldown(profKey, sid)
        local reags = (colors and not cd) and lib.RecipeReagents and lib:RecipeReagents(profKey, sid) or nil
        if reags and #reags > 0 then
            local priced, cost = pricedReagents(PR, reags)
            for _, rg in ipairs(priced) do rg[4] = resaleOf(rg[1]) end   -- valeur au stock (mode net)
            local prod = lib.RecipeProduct and lib:RecipeProduct(profKey, sid)
            local isKnown = (known["s" .. sid] or (prod and known["i" .. prod])) and true or false
            local planPrice, planUnknown, planDoubt
            -- L'exemplaire de l'AUTRE camp d'une recette jumelle (cf. Sources:IsOtherSideTwin) n'est
            -- pas un plan à acheter : aucun formateur ne l'enseignera à ce joueur.
            local otherSide = M and M.IsOtherSideTwin and M:IsOtherSideTwin(profKey, sid)
            if not isKnown and opts.plans and not otherSide then
                planPrice, planUnknown, planDoubt = planOf(M, PR, profKey, sid)
            end
            if isKnown or planPrice then
                out[#out + 1] = {
                    sid = sid, colors = colors, cost = cost, reags = priced, prod = prod,
                    resale = resaleOf(prod),   -- revente d'UN produit (numMade inconnu : 1, prudent)
                    conv = (prod and isReagent[prod]) or nil,
                    known = isKnown, planPrice = planPrice,
                    -- missing n'est PAS figé ici : un réactif sans prix mais en sac ne manque pas.
                    planUnknown = planUnknown or nil, planDoubt = planDoubt or nil,
                    live = live["s" .. sid] or (prod and live["i" .. prod]) or nil,
                    learnAt = learnAtOf(lib, M, profKey, sid, colors),
                }
            end
        end
    end
    return out
end

-- ------------------------------------------------------------------
-- Stock : ce que le joueur a DÉJÀ, et ce que la route fabrique en chemin
-- ------------------------------------------------------------------
-- Sans stock, la route payait au prix HV des réactifs qui dormaient dans les sacs. Retour user
-- 2026-09-26 : un tanneur rang 7, une pile de Ruined Leather Scraps, et la route prenait le Light
-- Armor Kit (1 cuir léger à 1s18 le point) contre la conversion (3 retailles à 40c = 1s20) — deux
-- cuivres d'écart, et les retailles n'apparaissaient jamais. Deux réserves :
--   · bag  = les sacs, lus À LA DEMANDE par opts.bag(itemID) (absent pour un tiers : tout vaut 0) ;
--   · made = ce que les segments précédents ont fabriqué — le cuir tiré des retailles nourrit les
--            kits d'après. numMade inconnu de la lib → 1 craft = 1 objet, comme Materials.
-- ⚠️ Une CONVERSION (cf. reagentSet) ne puise JAMAIS dans `made` : deux conversions réciproques
-- (essences d'enchanteur, transmutations élémentaires A→B puis B→A) s'y nourriraient l'une l'autre
-- et la route afficherait des points GRATUITS à l'infini. Les sacs sont finis : aucun cycle.
local EPS = 1e-6

local function newStock(bag)
    local lazy = setmetatable({}, { __index = function(t, id)
        local n = (bag and tonumber(bag(id))) or 0
        rawset(t, id, n)
        return n
    end })
    return { bag = lazy, made = {} }
end

-- Coût ESPÉRÉ du prochain point avec `c` (crafts = 1/chance), stock déduit : chaque réactif est
-- d'abord pris au stock (sacs, puis ce que la route a fabriqué), le reste payé au prix HV. Rend :
--   cash    -- ce qui sort de la bourse (stock vide → c.cost / chance, le calcul d'origine) ;
--   missing -- un reste qu'aucun prix ne couvre ;
--   net     -- en mode NET (`val`) : cash + valeur de ce qu'on prend au stock − revente du produit ;
--              sans `val`, net = cash (la route d'avant, à l'identique) ;
--   fromBag, credit -- la part des sacs et le crédit de revente, que l'infobulle détaille.
-- ⚠️ SYMÉTRIE : ce que la route fabrique est crédité à la production et débité au même prix quand
-- une étape suivante le consomme. Case « revente » décochée → ni crédit, ni débit : sinon une
-- conversion paierait sa sortie sans jamais en être créditée.
local function pointCost(c, crafts, st, val)
    local cash, missing, fromBag, fromMade = 0, false, 0, 0
    for _, rg in ipairs(c.reags) do
        local need = rg[2] * crafts
        local b = math.min(need, st.bag[rg[1]])
        local m = c.conv and 0 or math.min(need - b, st.made[rg[1]] or 0)
        local left = need - b - m
        if left > EPS then
            if rg[3] then cash = cash + left * rg[3] else missing = true end
        end
        fromBag, fromMade = fromBag + b * (rg[4] or 0), fromMade + m * (rg[4] or 0)
    end
    if not val then return cash, missing, cash, 0, 0 end
    if not val.resale then return cash, missing, cash + fromBag, fromBag, 0 end
    local credit = crafts * (c.resale or 0)
    return cash, missing, cash + fromBag + fromMade - credit, fromBag, credit
end

-- Engage le point : puise au stock (sacs d'abord), range le produit dans `made`, et note dans le
-- segment ce qui a été pris (seg.bag / seg.made : { [itemID] = qté }) — l'infobulle le dit.
local function consume(c, crafts, st, seg)
    for _, rg in ipairs(c.reags) do
        local id, need = rg[1], rg[2] * crafts
        local b = math.min(need, st.bag[id])
        local m = c.conv and 0 or math.min(need - b, st.made[id] or 0)
        if b > EPS then st.bag[id] = st.bag[id] - b; seg.bag[id] = (seg.bag[id] or 0) + b end
        if m > EPS then st.made[id] = st.made[id] - m; seg.made[id] = (seg.made[id] or 0) + m end
    end
    if c.prod then st.made[c.prod] = (st.made[c.prod] or 0) + crafts end
end

-- Départage de pickBest. Deux étages : une candidate DOUTEUSE (réactif sans prix, donc coût
-- sous-estimé ; plan au prix inconnu dont la source n'est pas attestée, cf. planOf) ne détrône
-- JAMAIS une candidate sûre — repli quand le rang n'a qu'elle. `p`/`bestP` = ce doute.
-- À coût ÉGAL — typiquement deux recettes gratuites parce que tout est en sac —, celle qui grisera
-- la PREMIÈRE passe devant : bientôt elle ne rapportera plus rien, l'autre peut attendre. C'est ce
-- qui met les retailles → cuir léger (gris à 40) AVANT le kit d'armure (gris à 60), qui mange
-- ensuite ce cuir. Sans ce départage, l'ordre du catalogue décidait.
local function better(p, per, c, bestP, bestPer, best)
    if bestP ~= p then return bestP end
    if per < bestPer - EPS then return true end
    if per > bestPer + EPS then return false end
    return c.colors[4] < best.colors[4]
end

-- Meilleure candidate à un rang donné : coût/point espéré minimal, stock `st` déduit ; le prix
-- d'un plan pas encore « acheté » est amorti sur les points qu'il peut encore servir d'ici sa
-- couleur grise (ou la cible). Au rang COURANT (`cur`), la couleur live du client — quand elle
-- existe — remplace les seuils data : le 1er segment raconte la même histoire que le badge.
-- ⚠️ GRIS MONOTONE : une recette TRIVIALE (grise) au rang courant l'est à TOUS les rangs supérieurs
-- (une recette ne « dé-grisonne » jamais en montant) → exclue de TOUTE la route (r n'itère que
-- >= cur). Sans ça, la couleur live l'écartait au rang courant mais les seuils Wowhead la
-- RESSUSCITAIENT en « vert » aux rangs suivants (données ≠ jeu à la frontière vert→gris) → la route
-- comptait, et recommandait, une recette DÉJÀ grise dans la liste du joueur.
-- Rend best, chance, partiel, le coût des réactifs de CE point (stock déduit, plan exclu),
-- « un réactif manque de prix », et le détail du point { cash, net, bag, credit } (cf. pointCost).
-- `val` = mode NET (cf. en-tête) : le choix se fait sur `net` au lieu de `cash`.
-- DEUX drapeaux, à ne pas confondre : le DOUTE classe (better), le PARTIEL s'affiche (« (?) » sur le
-- segment, « > » devant le total). Un plan de formateur attesté au prix inconnu est partiel sans
-- être douteux : il concourt, et le joueur voit quand même que le total est sous-évalué.
local function pickBest(cands, r, cur, target, bought, st, val)
    local best, bestPer, bestChance, bestDoubt, bestCost, bestMissing, bNet, bBag, bCredit
    for _, c in ipairs(cands) do
        if c.learnAt <= r and c.live ~= "trivial" then
            local col
            if r == cur and c.live then col = c.live
            else col = colorAt(c.colors, r) end
            local chance = col and CHANCE[col]
            if chance then
                local cost, missing, net, fromBag, credit = pointCost(c, 1 / chance, st, val)
                local per = net
                if not c.known and not bought[c.sid] then
                    per = per + (c.planPrice or 0) / math.max(1, math.min(c.colors[4], target) - r)
                end
                local doubt = (missing or c.planDoubt) and true or false
                if not best or better(doubt, per, c, bestDoubt, bestPer, best) then
                    best, bestPer, bestChance, bestDoubt, bestCost = c, per, chance, doubt, cost
                    bestMissing = missing and true or false
                    bNet, bBag, bCredit = net, fromBag, credit
                end
            end
        end
    end
    -- Partiel : un réactif sans prix, ou un plan au prix inconnu PAS ENCORE payé (une fois que la
    -- route l'a « acheté », les points suivants sont chiffrés juste).
    local partial = best and (bestMissing or (best.planUnknown and not bought[best.sid])) and true or false
    return best, bestChance, partial, bestCost, bestMissing,
        best and { cash = bestCost, net = bNet, bag = bBag, credit = bCredit } or nil
end

-- Plafond visé : maxRank s'il est connu, sinon le prochain palier CAPS au-dessus de `rank`.
local function targetFor(rank, maxRank)
    if maxRank and maxRank > 0 then return maxRank end
    for _, cap in ipairs(CAPS) do if rank < cap then return cap end end
    return nil
end

-- Le point `r` est gagné avec `best` : étend le segment courant ou en ouvre un.
-- `pt` = détail du point (pickBest). net/bagValue/resale/resaleQty ne servent qu'en mode NET ;
-- en caisse ils valent cost/0/0/0 et personne ne les affiche.
local function addPoint(segs, r, best, chance, pt, planCost, boughtNow, isPartial)
    local seg = segs[#segs]
    if not (seg and seg.sid == best.sid) then
        seg = { sid = best.sid, from = r, to = r, crafts = 0, cost = 0, plan = 0, prod = best.prod,
            bought = boughtNow, bag = {}, made = {}, net = 0, bagValue = 0, resale = 0, resaleQty = 0 }
        segs[#segs + 1] = seg
    end
    seg.to = r + 1; seg.crafts = seg.crafts + 1 / chance
    seg.cost = seg.cost + pt.cash; seg.plan = seg.plan + planCost
    seg.net, seg.bagValue = seg.net + pt.net, seg.bagValue + pt.bag
    if pt.credit > 0 then seg.resale, seg.resaleQty = seg.resale + pt.credit, seg.resaleQty + 1 / chance end
    if isPartial then seg.partial = true end
    return seg
end

-- La route : segments consécutifs { sid, from, to, crafts, cost, plan, prod, bought, partial,
-- missing, planUnknown, bag, made, net, bagValue, resale, resaleQty } (ou { gap = true }), + totaux
-- mats/plans (ce qui sort de la bourse) et, en mode NET (opts.value), net/bagValue/resale. `done` = déjà au plafond. maxRank nil →
-- prochain palier CAPS. nil si briques absentes (cf. Candidates). opts : voir Candidates, plus
-- opts.bag(itemID) → quantité en sac (MON perso seulement). `bag` est gardé sur la route : Materials
-- en a besoin pour dire ce qu'il reste à réunir.
function Route:Compute(profKey, rank, maxRank, opts)
    if not rank then return nil end
    opts = opts or {}
    local target = targetFor(rank, maxRank)
    if not target or rank >= target then return { rank = rank, target = target or rank, segments = {}, mats = 0, plans = 0, done = true } end
    local cands = self:Candidates(profKey, opts)
    if not cands then return nil end
    local st, val = newStock(opts.bag), opts.value
    local segs, mats, plans, bought, anyPartial = {}, 0, 0, {}, false
    local tot = { net = 0, bag = 0, resale = 0 }
    for r = rank, target - 1 do
        local best, chance, isPartial, cost, missing, pt = pickBest(cands, r, rank, target, bought, st, val)
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
            mats = mats + cost   -- coût espéré des réactifs pour CE point, stock déduit
            tot.net, tot.bag, tot.resale = tot.net + pt.net, tot.bag + pt.bag, tot.resale + pt.credit
            seg = addPoint(segs, r, best, chance, pt, planCost, boughtNow, isPartial)
            -- La RAISON du partiel, pour l'infobulle : le joueur n'y peut pas la même chose.
            if missing then seg.missing = true end
            if boughtNow and best.planUnknown then seg.planUnknown = true end
            consume(best, 1 / chance, st, seg)
        end
    end
    return { rank = rank, target = target, segments = segs, mats = mats, plans = plans,
        partial = anyPartial, bag = opts.bag,
        net = val and (tot.net + plans) or nil, bagValue = val and tot.bag or nil,
        resale = val and tot.resale or nil }
end

-- ------------------------------------------------------------------
-- Prochain point seulement (consommateur CHAUD : le suivi à l'écran)
-- ------------------------------------------------------------------
-- Candidates() balaie TOUTES les recettes du métier et interroge Auctionator pour chacune. Compute()
-- paie ça une fois puis marche rang par rang jusqu'au plafond : c'est un chemin FROID (on ouvre une
-- fenêtre). Le suivi à l'écran, lui, se recalcule à chaque BAG_UPDATE — d'où ce cache, même patron
-- que PR:BestPlanFor (clé + TTL). Clé : métier + inclusion des plans + version de données + nombre
-- de recettes connues (apprendre un plan doit rebattre les candidates).
local CANDS, CANDS_TTL = {}, 120

function Route:InvalidateCandidates(profKey)
    if profKey then CANDS[profKey] = nil else CANDS = {} end
end

local function candsKey(profKey, opts)
    local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    local dv = (lib and lib.DataVersion) and lib:DataVersion() or 0
    local n = 0
    for _ in pairs(opts.known or {}) do n = n + 1 end
    return profKey .. "|" .. (opts.plans and 1 or 0) .. "|" .. tostring(dv) .. "|" .. n
end

function Route:CachedCandidates(profKey, opts)
    local now = (GetTime and GetTime()) or 0
    local key = candsKey(profKey, opts)
    local c = CANDS[profKey]
    if c and c.key == key and (now - c.at) < CANDS_TTL then return c.cands end
    local cands = self:Candidates(profKey, opts)
    if not cands then return nil end
    CANDS[profKey] = { cands = cands, key = key, at = now }
    return cands
end

-- La MEILLEURE recette pour le prochain point, sans marcher jusqu'au plafond : un seul pickBest au
-- rang courant. `target` reste celui de la route complète — l'amortissement du prix d'un plan doit
-- raconter la même histoire ici et dans la fenêtre Plan de route (un plan cher se justifie sur tous
-- les points qu'il servira ENCORE, pas sur un seul). Rend nil si rien n'est calculable ou si le
-- métier est déjà au plafond. opts : voir Compute (opts.bag compris — le suivi et la fenêtre
-- doivent choisir la même recette). Le cache ne voit pas les sacs, et n'a pas à les voir : les
-- candidates n'en dépendent pas, le stock se déduit au choix.
-- perPoint = ce que le prochain point coûtera VRAIMENT, sacs déduits (0 si tout y est).
function Route:NextStep(profKey, rank, maxRank, opts)
    if not (profKey and rank) then return nil end
    opts = opts or {}
    local target = targetFor(rank, maxRank)
    if not target or rank >= target then return nil end
    local cands = self:CachedCandidates(profKey, opts)
    if not cands then return nil end
    local best, chance, partial, cost, _, pt = pickBest(cands, rank, rank, target, {}, newStock(opts.bag), opts.value)
    if not (best and chance) then return nil end
    return {
        sid = best.sid, prod = best.prod, rank = rank, target = target,
        cost = best.cost, chance = chance, perPoint = cost, perPointNet = pt and pt.net or nil,
        -- `plan` non nil = la route ACHÈTE ce plan pour ce point (le joueur ne le connaît pas encore).
        plan = (not best.known) and { price = best.planPrice or 0 } or nil,
        partial = partial or nil,
    }
end

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
    local acc = { qty = {}, order = {}, produced = {}, bag = newStock(route.bag).bag,
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
