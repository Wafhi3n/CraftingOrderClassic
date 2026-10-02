-- Directory_Seen.lua — les artisans connus SANS l'addon (vus crafter, lien de métier, clic sur son
-- lien) : ce qu'on en garde, et qui sait faire quoi (spec docs/specs/lien-metier.md).
--
-- Deux purges, à la connexion, après Dir:PruneRoster (7 jours, 500 fiches) :
--   * la REDONDANCE (D13, règle du user) : un artisan dont un porteur de l'addon de ma guilde, ou vu
--     ces derniers jours, sait déjà faire ce qu'il sait faire, n'est gardé qu'une journée ;
--   * le PLAFOND (D9, filet de sécurité) : au plus SEEN_CAP par métier, les mieux renseignés.
-- Et la requête du POC (D16) : qui, sans l'addon, sait faire telle recette. Ces données ne servent
-- jamais à router une commande (D10) : RecipeTester ne lit que les vraies données réseau.
-- Méthodes sur COC.Directory (créé par Directory.lua, chargé avant dans le .toc).

local COC = CraftingOrderClassic
local Dir = COC.Directory

-- Vraies données réseau (SK, RK, RI, CD) : elles font un PORTEUR, et priment toujours.
function Dir._HasNetData(r, prof)
    return ((r.skill and r.skill[prof]) or (r.recipes and r.recipes[prof])
        or (r.recipeIDs and r.recipeIDs[prof])) ~= nil
end
function Dir._IsCarrier(r) return (r.skill or r.recipes or r.recipeIDs or r.cooldowns) ~= nil end
local isCarrier = Dir._IsCarrier

local SEEN_CAP       = 10            -- D9 : proposé par l'agent le 2026-10-02 (filet de sécurité)
local REDUNDANT_KEEP = 86400         -- D13 : un artisan couvert reste une journée (« session ou journée »)
local CARRIER_RECENT = 3 * 86400     -- D13 : porteur « co récemment » (proposé par l'agent)
Dir.SEEN_CAP = SEEN_CAP
-- Mêmes relations que celles que garde PruneRoster : on ne les oublie jamais.
local KEEP_SOURCE = { guild = true, friend = true, added = true, circle = true }
local SEEN_FIELDS = { "craftSeen", "linkSeen", "linkSpell", "linkRecipes", "seenRecipes", "cdSeen" }

-- Fiche qui ne porte RIEN d'autre que des métiers connus sans l'addon : seule candidate à l'oubli.
-- Un [Dispo] en cours en est exclu, sinon un « LFW [lien] » frais serait oublié à son arrivée.
function Dir:_SeenOnly(name, r)
    if r.manual or KEEP_SOURCE[r.source or ""] or r.isPartner or r.relayed then return false end
    if isCarrier(r) then return false end
    if self.LFWOf and self:LFWOf(name) then return false end
    return true
end

local function forgetProf(r, prof)
    for _, f in ipairs(SEEN_FIELDS) do
        local t = r[f]
        if t then t[prof] = nil; if next(t) == nil then r[f] = nil end end
    end
end

-- Niveau connu d'un artisan sans l'addon : le plancher « vu crafter », le niveau du dernier clic sur
-- son lien (D11), ou le niveau requis par la tranche de son lien (D14) — le plus haut. Les deux
-- derniers se lisent à chaque fois : une lecture fausse se corrige à la suivante.
function Dir._KnownLevel(r, prof)
    local lk = r.linkRecipes and r.linkRecipes[prof]
    local tierMin = Dir.LinkTier and Dir.LinkTier(r.linkSpell and r.linkSpell[prof]) or 0
    return math.max((r.craftSeen and r.craftSeen[prof]) or 0, (lk and lk.lvl) or 0, tierMin)
end
local knownLevel = Dir._KnownLevel

-- Ce que `r` sait faire dans `prof`, connu sans l'addon : recettes vues crafter, ou lues au clic.
local function seenRecipeSet(r, prof)
    local set = {}
    for id in pairs((r.seenRecipes and r.seenRecipes[prof]) or {}) do set[id] = true end
    local lk = r.linkRecipes and r.linkRecipes[prof]
    for _, id in ipairs((lk and lk.ids) or {}) do set[id] = true end
    return set
end

-- ------------------------------------------------------------------
-- Plafond par métier (D9)
-- ------------------------------------------------------------------
-- Garde les `cap` mieux renseignés pour `prof` (niveau connu le plus haut, puis le plus récent) ;
-- les autres oublient ce métier, et une fiche sans plus aucun métier disparaît. Rend le nombre oublié.
function Dir:CapSeen(prof, cap)
    cap = cap or SEEN_CAP
    local list = {}
    for name, r in pairs(self.roster or {}) do
        if r.craftSeen and r.craftSeen[prof] ~= nil and self:_SeenOnly(name, r) then
            list[#list + 1] = { name = name, r = r, lvl = knownLevel(r, prof),
                                t = (r.linkSeen and r.linkSeen[prof]) or r.lastSeen or 0 }
        end
    end
    if #list <= cap then return 0 end
    table.sort(list, function(a, b)
        if a.lvl ~= b.lvl then return a.lvl > b.lvl end
        if a.t ~= b.t then return a.t > b.t end
        return a.name < b.name                   -- départage stable : même résultat à chaque passe
    end)
    for i = cap + 1, #list do
        local e = list[i]
        forgetProf(e.r, prof)
        if not e.r.craftSeen then self.roster[e.name] = nil end
    end
    return #list - cap
end

function Dir:CapSeenAll(cap)
    local profs = {}
    for _, r in pairs(self.roster or {}) do
        for p in pairs(r.craftSeen or {}) do profs[p] = true end
    end
    for p in pairs(profs) do self:CapSeen(p, cap) end
end

-- ------------------------------------------------------------------
-- Redondance (D13)
-- ------------------------------------------------------------------
-- Porteurs qui COUVRENT : vraies données réseau, et de ma guilde ou vus il y a moins de 3 jours.
function Dir:_CoveringCarriers()
    local out, cutoff = {}, time() - CARRIER_RECENT
    for _, r in pairs(self.roster or {}) do
        if isCarrier(r) and (r.isGuild or r.source == "guild" or (r.lastSeen or 0) >= cutoff) then
            out[#out + 1] = r
        end
    end
    return out
end

-- `r` n'apporte rien pour `prof` que les porteurs `cars` n'apportent déjà ? Ses recettes connues
-- sont toutes dans le registre réseau d'un porteur ; sans recette connue, un porteur exerce le
-- métier à un niveau au moins égal au sien. Un registre illisible (autre dataVersion) ne couvre rien.
function Dir:_Covered(r, prof, cars)
    local set = seenRecipeSet(r, prof)
    if next(set) then
        local tests = {}
        for _, c in ipairs(cars) do
            local t = self.RecipeTester and self:RecipeTester(c, prof)
            if t then tests[#tests + 1] = t end
        end
        for id in pairs(set) do
            local known = false
            for _, t in ipairs(tests) do if t(id) then known = true; break end end
            if not known then return false end
        end
        return #tests > 0
    end
    local lvl = knownLevel(r, prof)
    for _, c in ipairs(cars) do
        local sk = c.skill and c.skill[prof]
        if sk and (tonumber(sk[1]) or 0) >= lvl then return true end
    end
    return false
end

-- Oublie, chez un artisan sans l'addon croisé il y a plus d'une journée, chaque métier déjà couvert.
-- Une fiche sans plus aucun métier disparaît. Rend le nombre de métiers oubliés.
function Dir:PruneRedundant()
    local cars = self:_CoveringCarriers()
    if #cars == 0 then return 0 end
    local cutoff, n = time() - REDUNDANT_KEEP, 0
    for name, r in pairs(self.roster or {}) do
        if r.craftSeen and (r.lastSeen or 0) < cutoff and self:_SeenOnly(name, r) then
            local profs = {}
            for prof in pairs(r.craftSeen) do profs[#profs + 1] = prof end
            for _, prof in ipairs(profs) do
                if self:_Covered(r, prof, cars) then forgetProf(r, prof); n = n + 1 end
            end
            if not r.craftSeen then self.roster[name] = nil end
        end
    end
    return n
end

-- ------------------------------------------------------------------
-- POC (D16) : qui, SANS l'addon, sait faire cette recette ? Liste { name, via = "link"|"seen", at },
-- la plus récente d'abord. Les porteurs n'y sont pas : ils sont dans le ciblage de la commande.
-- ------------------------------------------------------------------
function Dir:SeenWhoKnows(prof, spellID)
    local out = {}
    if not (prof and spellID) then return out end
    for name, r in pairs(self.roster or {}) do
        if not isCarrier(r) then
            local lk = r.linkRecipes and r.linkRecipes[prof]
            local seenAt = r.seenRecipes and r.seenRecipes[prof] and r.seenRecipes[prof][spellID]
            local inLink = false
            for _, id in ipairs((lk and lk.ids) or {}) do if id == spellID then inLink = true; break end end
            if inLink or seenAt then
                out[#out + 1] = { name = name, via = inLink and "link" or "seen",
                                  at = inLink and lk.at or seenAt }
            end
        end
    end
    table.sort(out, function(a, b)
        if (a.at or 0) ~= (b.at or 0) then return (a.at or 0) > (b.at or 0) end
        return a.name < b.name
    end)
    return out
end

-- À la connexion, juste après la purge existante : redondance d'abord, plafond ensuite. Directory.lua
-- est à 499 lignes (plafond anti-monolithe) : on s'accroche à PruneRoster plutôt que d'y ajouter un appel.
if hooksecurefunc and Dir.PruneRoster then
    hooksecurefunc(Dir, "PruneRoster", function(self) self:PruneRedundant(); self:CapSeenAll() end)
end
