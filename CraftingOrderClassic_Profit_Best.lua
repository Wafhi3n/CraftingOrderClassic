-- CraftingOrderClassic_Profit_Best.lua — le meilleur plan d'un métier (sorti de _Profit.lua, 2026-09-29).
--
-- Pur déplacement : ces fonctions ne lisent le calcul que par l'API publique de COC.Profit
-- (CraftProfit, IsAvailable). Elles ont quitté _Profit.lua pour qu'il tienne sous les 500 lignes.

local COC = CraftingOrderClassic
local PR  = COC.Profit

-- ---------------------------------------------------------------------------
-- Meilleur profit ATTEIGNABLE dans un métier, par niveau de compétence
-- ---------------------------------------------------------------------------
-- Sert à mettre en avant l'artisan dont le métier a un plan rentable. Calculer ça naïvement voudrait
-- dire, à chaque rendu et pour chaque artisan, évaluer les centaines de recettes du métier (donc des
-- milliers de lookups de prix). On construit donc UNE FOIS par métier une table indexée par niveau :
--   best[r] = meilleur profit parmi les recettes apprenables à un niveau <= r.
-- Lookup ensuite en O(1). Cache avec TTL : les prix Auctionator bougent, mais pas à la seconde.
local MAX_RANK, CACHE_TTL = 450, 120
local bestCache = {}   -- [profKey] = { at = <horodatage>, best = { [rank] = profit } }

-- best[r] = { profit, sid } du MEILLEUR plan atteignable à un niveau ≤ r (on garde le spellID, pas
-- seulement le montant : le tooltip d'artisan NOMME le plan — « le meilleur plan » sans son nom ne
-- dit pas quoi commander).
local function buildBest(profKey)
    local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    local best = {}
    -- Meilleur plan par niveau d'apprentissage EXACT, puis propagation en max cumulé.
    local atRank = {}
    for _, spellID in ipairs((lib and lib.GetRecipes and lib:GetRecipes(profKey)) or {}) do
        local p = PR:CraftProfit(profKey, spellID, nil)
        if p and p.profit and p.profit > 0 then
            local at = (lib.RecipeLearnedAt and lib:RecipeLearnedAt(profKey, spellID)) or 1
            if at < 0 then at = 0 elseif at > MAX_RANK then at = MAX_RANK end
            local cur = atRank[at]
            if not cur or p.profit > cur.profit then atRank[at] = { profit = p.profit, sid = spellID } end
        end
    end
    local running = nil
    for r = 0, MAX_RANK do
        local v = atRank[r]
        if v and (not running or v.profit > running.profit) then running = v end
        best[r] = running
    end
    return best
end

-- Entrée { profit, sid } du meilleur plan d'un métier pour un artisan de niveau `rank`, ou nil.
-- rank nil → on suppose le niveau max (on ne sait pas, autant ne pas sous-estimer).
function PR:BestPlanFor(profKey, rank)
    if not (self:IsAvailable() and profKey) then return nil end
    local now = GetTime and GetTime() or 0
    local c = bestCache[profKey]
    if not c or (now - c.at) > CACHE_TTL then
        c = { at = now, best = buildBest(profKey) }
        bestCache[profKey] = c
    end
    local r = tonumber(rank) or MAX_RANK
    if r < 0 then r = 0 elseif r > MAX_RANK then r = MAX_RANK end
    return c.best[r]
end

-- Montant seul (nil si aucun plan rentable / pas de prix).
function PR:BestProfitFor(profKey, rank)
    local e = self:BestPlanFor(profKey, rank)
    return e and e.profit or nil
end

-- Nom de l'objet produit par un plan { profit, sid } (« Iron Buckle »), ou nil.
function PR:PlanName(profKey, plan)
    local lib = plan and LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    if not lib then return nil end
    local itemID = lib.RecipeProduct and lib:RecipeProduct(profKey, plan.sid)
    local nm = itemID and lib:ItemName(itemID) or lib:RecipeName(plan.sid)
    if not nm or nm:match("^item:") or nm:match("^spell:") then return nil end
    return nm
end

-- Nom du meilleur plan ATTEIGNABLE à un rang (approximation, cf. BestPlanFor). Conservé pour les
-- appelants qui n'ont pas de fiche artisan (rang seul) — préférer BestKnownPlanFor + PlanName quand
-- une fiche `r` est disponible : plus honnête (ne nomme que ce que l'artisan a RÉELLEMENT appris).
function PR:BestPlanName(profKey, rank)
    return self:PlanName(profKey, self:BestPlanFor(profKey, rank))
end

-- ---------------------------------------------------------------------------
-- Meilleur plan RÉELLEMENT connu d'un artisan (pas seulement « atteignable à son niveau »). En
-- Classic, une recette dépasse un palier de compétence ne veut pas dire qu'on l'a apprise : elle
-- peut nécessiter un PNJ, un butin ou une quête à part. BestPlanFor (rang seul) peut donc nommer un
-- plan que l'artisan ne sait PAS fabriquer. Ici on décode le bitmask EXACT de ses recettes connues
-- (mêmes données que le filtre « connus » de l'onglet Commande, cf. _TargetArtisanFilter) et on ne
-- regarde que celles-là. Cache par (métier, bitmask) — pas par rang — car deux artisans de même
-- niveau peuvent avoir appris des recettes différentes.
local knownBestCache = {}   -- [profKey.."|"..hex] = { at, best = {profit, sid} | nil }

-- `known` = set { [spellID] = true } fourni par la couture (Directory_Recipes) : ce module n'a
-- pas a savoir si le registre est arrive en bitfield ou en identifiants.
local function buildBestKnown(profKey, known)
    if not known then return nil end
    local best
    for sid in pairs(known) do
        local p = PR:CraftProfit(profKey, sid, nil)
        if p and p.profit and p.profit > 0 and (not best or p.profit > best.profit) then
            best = { profit = p.profit, sid = sid }
        end
    end
    return best
end

-- `r` = fiche roster de l'artisan. Renvoie nil si son registre n'est pas EXPLOITABLE pour ce
-- métier (jamais croisé en direct, ou bitfield d'une autre version du catalogue) — dans ce cas
-- l'appelant retombe sur BestPlanFor(profKey, rank), une approximation moins fiable mais
-- toujours disponible. La forme du registre est l'affaire de la couture, pas la nôtre.
function PR:BestKnownPlanFor(profKey, r)
    if not (self:IsAvailable() and profKey and r) then return nil end
    local D = COC.Directory
    -- La clé de cache vient de la couture : elle intègre la FORME du registre, donc deux
    -- registres de formes différentes ne peuvent pas se répondre l'un pour l'autre.
    local k = D and D.RecipeFingerprint and D:RecipeFingerprint(r, profKey)
    if not k then return nil end
    local now = GetTime and GetTime() or 0
    local c = knownBestCache[k]
    if not c or (now - c.at) > CACHE_TTL then
        c = { at = now, best = buildBestKnown(profKey, D:RecipeKnownSet(r, profKey)) }
        knownBestCache[k] = c
    end
    return c.best
end
