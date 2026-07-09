-- Directory_MyArtisans.lua — agrégation des métiers du COMPTE (onglet « Mes artisans »).
--
-- Feature 100 % LOCALE : lit MES SavedVariables partitionnées par perso (db.myChars,
-- db.knownRecipes, db.mySkillsByChar) et produit une vue « métiers du compte » — tous mes rerolls
-- du royaume confondus, perso principal (db.altMain) en tête, chaque métier affiché en mode
-- « connu » (niveau + recettes) comme s'il n'y avait qu'un personnage. AUCUN message réseau, aucun
-- verbe, aucune dépendance à l'opt-in /co alts : marche même désactivé. Le cœur `aggregate` est PUR
-- (SV + royaume injectés) → testable headless (tests/test_myartisans.lua). Méthodes sur
-- COC.Directory (créée par Directory.lua, chargé AVANT).

local COC = CraftingOrderClassic
local Dir = COC.Directory

local function me() return (UnitName and UnitName("player")) or "?" end
local function myRealm() return (GetRealmName and GetRealmName()) or "" end

-- Nom court d'une clé « Nom-Royaume » SI elle est du royaume `realm`, sinon nil. Le nom de perso
-- n'a pas de tiret (WoW l'interdit) ; le royaume PEUT contenir des espaces (« Wild Growth »).
local function charOfRealm(key, realm)
    local short, r = key:match("^([^%-]+)%-(.*)$")
    if short and r == realm then return short end
    return nil
end

-- Cœur PUR. Itère les persos du royaume (union des clés myChars ∪ knownRecipes ∪ mySkillsByChar),
-- agrège par métier (skill ∪ recipes, hors secondary), main en tête. Retourne une liste triée par
-- clé de métier (le tri par LIBELLÉ localisé reste côté UI). `main`/`realm` injectés (aucune API WoW).
local function aggregate(myChars, knownRecipes, mySkillsByChar, realm, main, secondary)
    knownRecipes, mySkillsByChar, secondary = knownRecipes or {}, mySkillsByChar or {}, secondary or {}
    -- 1) ensemble des persos du royaume (short → clé complète)
    local chars = {}
    local function note(key) local s = charOfRealm(key, realm); if s then chars[s] = key end end
    for key in pairs(myChars or {}) do note(key) end
    for key in pairs(knownRecipes) do note(key) end
    for key in pairs(mySkillsByChar) do note(key) end

    -- 2) agrégat par métier
    local byProf = {}
    local function ensure(prof)
        local e = byProf[prof]
        if not e then e = { profKey = prof, bestRank = 0, bestMax = 0, chars = {}, known = {} }; byProf[prof] = e end
        return e
    end
    for short, key in pairs(chars) do
        local skills = mySkillsByChar[key] or {}
        local recs   = knownRecipes[key] or {}
        local profs = {}
        for prof in pairs(skills) do if not secondary[prof] then profs[prof] = true end end
        for prof in pairs(recs)   do if not secondary[prof] then profs[prof] = true end end
        for prof in pairs(profs) do
            local e = ensure(prof)
            local sk = skills[prof]
            local rank, max = sk and sk[1] or nil, sk and sk[2] or nil
            local known = {}
            for sid in pairs(recs[prof] or {}) do known[sid] = true; e.known[sid] = true end
            e.chars[#e.chars + 1] = { name = short, key = key, rank = rank, max = max, isMain = (short == main), known = known }
            if (rank or 0) > e.bestRank then e.bestRank, e.bestMax = rank or 0, max or 0 end
        end
    end

    -- 3) tri des persos de chaque métier (main d'abord, puis rank desc, puis nom) + liste plate
    local out = {}
    for _, e in pairs(byProf) do
        table.sort(e.chars, function(a, b)
            if a.isMain ~= b.isMain then return a.isMain end
            if (a.rank or 0) ~= (b.rank or 0) then return (a.rank or 0) > (b.rank or 0) end
            return a.name < b.name
        end)
        out[#out + 1] = e
    end
    table.sort(out, function(a, b)
        if a.bestRank ~= b.bestRank then return a.bestRank > b.bestRank end
        return a.profKey < b.profKey
    end)
    return out
end
Dir._Aggregate = aggregate   -- exposé pour tests/test_myartisans.lua

-- Wrapper : lit MA SavedVariable + royaume courant, délègue au cœur pur. main = altMain sinon moi.
function Dir:AggregateMyProfs()
    local db = COC.db
    if not db then return {} end
    local main = db.altMain or me()
    return aggregate(db.myChars, db.knownRecipes, db.mySkillsByChar, myRealm(), main, COC.SECONDARY_PROF or {})
end

-- Cœur PUR. Une entrée par (perso ≠ `cur`, métier connu) du royaume — pour le menu « Mes métiers »
-- (section Rerolls). Métier « connu » = présent dans knownRecipes[key] OU mySkillsByChar[key] (un
-- métier de récolte sans recette n'apparaît que via le skill). Filtre les secondaires (Cooking,
-- First Aid, Fishing) pour afficher SEULEMENT les métiers primaires. Tri par nom de perso puis clé
-- de métier (libellé localisé côté UI).
local function rerollEntries(knownRecipes, mySkillsByChar, realm, cur, secondary)
    knownRecipes, mySkillsByChar = knownRecipes or {}, mySkillsByChar or {}
    secondary = secondary or {}
    local out = {}
    local function scan(store)
        for key, byProf in pairs(store) do
            local short = charOfRealm(key, realm)
            if short and short ~= cur then
                for prof in pairs(byProf) do
                    if not secondary[prof] then
                        out[short .. "|" .. prof] = { name = short, key = key, prof = prof }
                    end
                end
            end
        end
    end
    scan(mySkillsByChar); scan(knownRecipes)     -- union ; la 2e passe écrase par la même valeur
    local list = {}
    for _, e in pairs(out) do
        local sk = mySkillsByChar[e.key] and mySkillsByChar[e.key][e.prof]
        e.rank, e.max = sk and sk[1] or nil, sk and sk[2] or nil
        list[#list + 1] = e
    end
    table.sort(list, function(a, b)
        if a.name ~= b.name then return a.name < b.name end
        return a.prof < b.prof
    end)
    return list
end
Dir._RerollProfEntries = rerollEntries   -- exposé pour tests/test_myartisans.lua

-- Wrapper : (perso, métier) de MES rerolls du royaume courant (perso courant exclu), primaires seulement.
function Dir:RerollProfEntries()
    local db = COC.db
    if not db then return {} end
    return rerollEntries(db.knownRecipes, db.mySkillsByChar, myRealm(), me(), COC.SECONDARY_PROF or {})
end

-- Purge conservatrice des partitions de skill orphelines (perso supprimé en jeu) : clé absente à
-- LA FOIS de myChars ET de knownRecipes. Ne touche JAMAIS knownRecipes (feature reroll) ni le perso
-- courant. Appelé par PruneRoster au démarrage.
function Dir:PruneMySkills()
    local db = COC.db
    if not (db and db.mySkillsByChar) then return end
    local cur = me() .. "-" .. myRealm()
    for key in pairs(db.mySkillsByChar) do
        local orphan = key ~= cur
            and not (db.myChars and db.myChars[key])
            and not (db.knownRecipes and db.knownRecipes[key])
        if orphan then db.mySkillsByChar[key] = nil end
    end
end
