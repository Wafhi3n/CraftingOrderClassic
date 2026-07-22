-- CraftingOrderClassic_Gem.lua — spécifique à la JOAILLERIE : sous-catégorise les GEMMES TAILLÉES
-- par TAILLE (le mot qui porte la stat).
--
-- Une gemme taillée s'appelle « <Taille> <Gemme brute> » en anglais : « Stormy Azure Moonstone ».
-- La COULEUR est déjà connue du client (classID 3 = Gemme, et le subclassID EST la couleur) — c'est
-- COC.SectionOf qui en fait la section, comme pour n'importe quel objet. Reste la TAILLE, que rien
-- côté client ne donne : il faut la lire dans le nom.
--
-- ⚠️ Et le nom doit être l'ANGLAIS CANONIQUE (table `names` de CraftLink, lib v13), jamais le nom
-- runtime : en français l'adjectif passe en FIN et il S'ACCORDE — « Pierre de lune azur orageuSE »
-- (fém.) mais « Œil-de-nuit orageuX » (masc.). Regrouper sur le nom localisé éclaterait la taille en
-- deux groupes selon le genre de la gemme. Même piège, même remède que _Enchant.lua : clé canonique
-- anglaise, libellé lu sur le client.
--
-- API publique : Gem:StatFor (sous-catégorie pour RecipeCats:BuildDisplay) · Gem:CutFor · Gem:IsGem.
-- La correspondance TAILLE → STAT (« Stormy » = pénétration des sorts) se déclare à part, dans
-- _Gem_Stats.lua : voir Gem:RegisterStats plus bas.

local COC = CraftingOrderClassic
local Gem = {}
COC.Gem   = Gem
local L   = COC.L

local PROF    = "Jewelcrafting"
local INSTANT = GetItemInfoInstant

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

-- classID 3 = Gemme. Lu dans la DB STATIQUE du client (GetItemInfoInstant) → disponible sans cache,
-- donc le classement est fiable dès le premier rendu, avant même que les noms n'arrivent.
local GEM_CLASS = 3

function Gem:IsGem(itemID)
    if not (itemID and INSTANT) then return false end
    local classID = select(6, INSTANT(itemID))
    return classID == GEM_CLASS
end

-- =========================================================================
-- TAILLE → STAT (déclarée dans _Gem_Stats.lua, vide par défaut)
-- =========================================================================
-- Table de CORRECTION, pas source principale : la stat est normalement LUE SUR L'OBJET (COC.Stats),
-- donc juste et traduite sans rien saisir. On ne déclare ici que ce que le client ne dit pas bien.
-- Déclaration INVERSE — « cette stat, ces tailles » : une même stat porte des noms de taille
-- DIFFÉRENTS d'une extension à l'autre, et les lister ensemble est plus court à écrire ET
-- directement exploitable par un FILTRE (Gem:CutsForStat).
--   groups = { { stat = <clé de locale>, cuts = { "Stormy", … } }, … }
-- L'ORDRE des groupes EST l'ordre d'affichage ; les tailles non déclarées passent APRÈS, par ordre
-- alphabétique anglais. Deux tailles d'une même stat partagent le RANG : leurs en-têtes sortent
-- côte à côte, tous deux préfixés par la stat (« Endurance - Solide », « Endurance - Audacieux »).
local _statGroups, _statByCut, _statOrderByCut = {}, nil, nil

-- Déclarées ICI, avant RegisterStats, pour qu'il puisse purger le cache de libellés : sans ça une
-- déclaration arrivée APRÈS un premier affichage resterait sans effet (libellé déjà figé).
local _cutBySpell, _cutOrder, _repSpell, _labelCache

function Gem:RegisterStats(groups)
    if type(groups) ~= "table" then return end
    for _, g in ipairs(groups) do
        if g.stat and type(g.cuts) == "table" then _statGroups[#_statGroups + 1] = g end
    end
    _statByCut, _statOrderByCut = nil, nil   -- index invalidé (re-déclaration à chaud)
    if _labelCache then _labelCache = {} end
end

local function statIndex()
    if _statByCut then return end
    _statByCut, _statOrderByCut = {}, {}
    for order, g in ipairs(_statGroups) do
        for _, cut in ipairs(g.cuts) do
            if _statByCut[cut] == nil then
                _statByCut[cut], _statOrderByCut[cut] = g.stat, order
            end
        end
    end
end

-- Stat déclarée d'une taille (libellé localisé), ou nil tant que la table n'est pas remplie.
function Gem:StatOfCut(cut)
    statIndex()
    local key = cut and _statByCut[cut]
    if not key then return nil end
    return L[key] or key
end

-- Tailles anglaises d'une stat, pour un futur filtre. Rend une NOUVELLE table (jamais l'interne).
function Gem:CutsForStat(statKey)
    local out = {}
    for _, g in ipairs(_statGroups) do
        if g.stat == statKey then
            for _, cut in ipairs(g.cuts) do out[#out + 1] = cut end
        end
    end
    return out
end

-- =========================================================================
-- Maps dérivées du catalogue CraftLink
-- =========================================================================
-- spellID → taille anglaise, et rang alphabétique stable des tailles (le moteur trie sur un NOMBRE).
-- Restreint aux recettes dont l'objet produit EST une gemme : la Joaillerie fabrique aussi des
-- bagues, colliers, statues et figurines, qui gardent leur classement par emplacement.
-- (Les locales de ces maps sont déclarées plus haut — cf. RegisterStats.)

local function buildMaps()
    _cutBySpell, _cutOrder, _repSpell, _labelCache = {}, {}, {}, {}
    local c = CL()
    local def = c and c.GetProfession and c:GetProfession(PROF)
    if not def then return end
    local seen = {}
    for _, e in ipairs(def.names or {}) do
        local product = e.id and c.RecipeProduct and c:RecipeProduct(PROF, e.id)
        -- 1er mot du nom anglais, ET il doit rester quelque chose derrière (un nom d'un seul mot
        -- n'est pas une taille suivie d'une gemme).
        local cut = (product and Gem:IsGem(product) and e.name) and e.name:match("^(%S+)%s+%S")
        if cut then
            _cutBySpell[e.id] = cut
            seen[cut] = true
            -- Représentant de la taille = plus petit spellID : pairs() n'a pas d'ordre, il faut un
            -- départage STABLE (c'est lui qui portera le libellé lu sur le client).
            if not _repSpell[cut] or e.id < _repSpell[cut] then _repSpell[cut] = e.id end
        end
    end
    local list = {}
    for cut in pairs(seen) do list[#list + 1] = cut end
    table.sort(list)
    for i, cut in ipairs(list) do _cutOrder[cut] = i end
end

-- Nom LOCALISÉ du 1er réactif d'une recette. Pour une taille c'est la GEMME BRUTE, et c'est ce qui
-- permet d'isoler la taille dans le nom localisé (cf. deriveLabel).
local function reagentName(c, spellID)
    local def = c.GetProfession and c:GetProfession(PROF)
    local list = def and def.reagents and def.reagents[spellID]
    local first = list and list[1]
    if not (first and first[1]) then return nil end
    return (GetItemInfo(first[1]))
end

-- Libellé de la taille dans la langue du CLIENT, sans aucune traduction à maintenir : on RETRANCHE
-- le nom localisé de la gemme brute au nom localisé de la gemme taillée.
--   EN : « Stormy Azure Moonstone » − « Azure Moonstone » → « Stormy »   (le reste est APRÈS)
--   FR : « Pierre de lune azur orageuse » − « Pierre de lune azur » → « orageuse » (le reste est AVANT)
-- Recherche en TEXTE BRUT (find plain) : un nom de gemme peut contenir un tiret (« Œil-de-nuit »),
-- qui serait un quantificateur en motif Lua.
-- nil si l'un des deux noms n'est pas encore en cache, ou si le réactif n'apparaît pas dans le nom
-- produit (gemme sans taille) → l'appelant retombe sur le mot anglais, qui reste lisible.
local function deriveLabel(cut)
    local c, id = CL(), _repSpell[cut]
    local product = (c and id and c.RecipeProduct) and c:RecipeProduct(PROF, id) or nil
    local full = product and GetItemInfo(product) or nil
    local reag = (c and id) and reagentName(c, id) or nil
    if not (full and reag and reag ~= "") then return nil end
    local s, e = full:find(reag, 1, true)
    if not s then return nil end
    local rest = (s == 1) and full:sub(e + 1) or full:sub(1, s - 1)
    rest = rest:match("^%s*(.-)%s*$") or ""
    if rest == "" then return nil end
    return rest:sub(1, 1):upper() .. rest:sub(2)
end

-- Objet produit par la gemme REPRÉSENTANTE d'une taille — celui dont on lit les stats.
-- Toutes les gemmes d'une même taille portent la même stat, seule la VALEUR change avec la qualité.
local function repProduct(cut)
    local c, id = CL(), _repSpell[cut]
    if not (c and id and c.RecipeProduct) then return nil end
    return c:RecipeProduct(PROF, id)
end

-- Libellé affiché d'une taille : « <stat> - <taille> » (« Force - Audacieux ») quand la stat est
-- connue, la taille seule sinon. La STAT vient de la table déclarée si elle l'est, sinon elle est
-- LUE SUR L'OBJET (COC.Stats) — donc juste, traduite, et valable pour toutes les extensions sans
-- rien saisir. Rien n'est mis en cache tant que les deux morceaux ne sont pas tranchés : GetItemInfo
-- comme GetItemStats peuvent être froids au tout premier affichage.
local function cutLabel(cut)
    if _labelCache[cut] then return _labelCache[cut] end
    local name = deriveLabel(cut)
    local stat = Gem:StatOfCut(cut)
    local settled = (stat ~= nil)
    if not stat and COC.Stats then
        local product = repProduct(cut)
        settled = (product ~= nil) and (COC.Stats:Of(product) ~= nil)
        if settled then stat = COC.Stats:LabelFor(product) end
    end
    if not name then return stat or cut end       -- nom pas encore arrivé : rien à figer
    local label = stat and (stat .. " - " .. name) or name
    if settled then _labelCache[cut] = label end
    return label
end

-- Taille (anglais canonique) d'une recette de gemme, ou nil. C'est la CLÉ d'identité : c'est elle
-- que doit manipuler tout code de filtre, jamais le libellé affiché (traduit).
function Gem:CutFor(spellID)
    if not _cutBySpell then buildMaps() end
    return spellID and _cutBySpell[spellID] or nil
end

-- Sous-catégorie d'une gemme taillée pour RecipeCats:BuildDisplay. Rend `libellé, rang, niveau, lone` :
--   * libellé : la stat si elle est déclarée (_Gem_Stats.lua), sinon la taille localisée ;
--   * rang    : l'ordre de déclaration de la stat, sinon 500 + rang alphabétique anglais — les
--               tailles non encore rattachées à une stat passent donc APRÈS celles qui le sont ;
--   * niveau  : rang de métier de la recette → les variantes se trient du plus fort au plus faible ;
--   * lone    : toujours vrai ici. Le libellé d'une taille est le PREMIER MOT du nom de la gemme :
--               un en-tête pour une seule ligne ne fait que la répéter (« Bracing » / « Bracing
--               Earthstorm Diamond »). On autorise donc le moteur à aplatir une section dont aucune
--               taille ne regroupe — les gemmes MÉTA, où chaque taille est unique.
-- nil pour tout ce qui n'est pas une gemme taillée (bagues, colliers, statues) → classement normal.
function Gem:StatFor(spellID)
    local cut = self:CutFor(spellID)
    if not cut then return nil end
    statIndex()
    local order = _statOrderByCut[cut] or (500 + (_cutOrder[cut] or 400))
    local c = CL()
    local tier = (c and c.RecipeLearnedAt and c:RecipeLearnedAt(PROF, spellID)) or 0
    return cutLabel(cut), order, tier, true
end
