-- CraftingOrderClassic_Migrations.lua — versionnage du schéma SavedVariables.
--
-- Les SavedVariables sont PAR COMPTE et les utilisateurs sautent des versions (v1.2 → v1.8 direct).
-- Une échelle ORDONNÉE de migrations, bornée par `db.schemaVer`, garantit qu'un palier ne tourne
-- NI deux fois NI jamais. Remplace l'ancienne migration ad hoc « knownRecipes v2 » (ex-inline dans
-- CraftingOrderClassic.lua). Les défauts PARESSEUX (COC.db.orders = … or {}, etc.) restent posés à
-- leur point d'usage — ce module ne gère QUE les transformations de format entre versions, et les
-- purges UNIQUES d'une donnée qu'une version a écrite fausse (palier 2).
--
-- PUR : aucune dépendance à l'API WoW ni à LibStub → testable hors client (tests headless Elune).

local COC = CraftingOrderClassic
local Migrations = { VER = 3 }
COC.Migrations = Migrations

-- Palier 3 : les tables rangées par perso, sous « Prénom-Royaume » jusqu'au build 71037 de Forever, sous
-- « Prénom- » depuis (COC.Api.CharKey ; spec docs/specs/cle-perso-sans-royaume.md).
local PER_CHAR = { "knownRecipes", "myCooldowns", "mySkillsByChar", "myChars", "myCharNames", "myCharFaction" }

local function deepCopy(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, x in pairs(v) do t[k] = deepCopy(x) end
    return t
end

-- Prénom → son ancien royaume, ou false s'il en a plusieurs (sur l'union des tables : un même prénom sur
-- deux royaumes, c'est deux persos, ou un transfert ; on ne devine pas lequel est « Prénom- »).
local function oldRealms(db)
    local seen = {}
    for _, name in ipairs(PER_CHAR) do
        for key in pairs(type(db[name]) == "table" and db[name] or {}) do
            local short, realm
            if type(key) == "string" then short, realm = key:match("^([^%-]+)%-(.+)$") end
            if short then
                if seen[short] == nil then seen[short] = realm
                elseif seen[short] ~= realm then seen[short] = false end
            end
        end
    end
    return seen
end

-- LADDER[v] fait passer une DB du schéma (v-1) au schéma v. Doit être IDEMPOTENT vis-à-vis d'une DB
-- déjà à ce format (une DB courante ou déjà migrée ne doit rien perdre).
Migrations.LADDER = {
    -- v1 : formalise l'ancienne migration « knownRecipes v2 ». L'ancien format de knownRecipes était
    -- PLAT (métier→recettes) et PARTAGÉ par compte → union polluée inter-persos, non attribuable. On
    -- le purge UNE fois (si jamais migré) ; chaque perso reconstruit sa partition knownRecipes[nom-royaume]
    -- en rouvrant sa fenêtre métier. Un client déjà migré (knownRecipesVer==2) n'est PAS re-purgé.
    [1] = function(db)
        db.knownRecipes = db.knownRecipes or {}
        if not db.knownRecipesVer then
            if next(db.knownRecipes) then db.knownRecipes = {} end
            db.knownRecipesVer = 2
        end
    end,
    -- v2 : purge les cooldowns relevés sur des recettes NON apprises. Avant CraftLink COOLDOWNS_REV 7,
    -- l'énumérateur de la fenêtre rendait aussi le non-appris, et le restant nil d'une recette qu'on n'a
    -- pas passait pour « prête ». Relevé le 2026-10-05 : un tailleur de rang 56 portait l'Étoffe lunaire
    -- (apprise à 250). Chaque perso du compte est nettoyé, rerolls compris : « Mes artisans » les affiche
    -- sans qu'ils rouvrent leur fenêtre. Un CD n'est gardé que si la recette est dans le registre du
    -- MÊME perso ; sans registre pour ce métier, pas d'avis, on garde.
    [2] = function(db)
        for char, byProf in pairs(type(db.myCooldowns) == "table" and db.myCooldowns or {}) do
            local known = type(db.knownRecipes) == "table" and db.knownRecipes[char] or nil
            for prof, set in pairs(type(byProf) == "table" and byProf or {}) do
                local k = type(known) == "table" and known[prof] or nil
                if type(k) == "table" and next(k) and type(set) == "table" then
                    for sid in pairs(set) do
                        if not k[sid] then set[sid] = nil end
                    end
                end
            end
        end
    end,
    -- v3 : depuis le build 71037, GetRealmName() rend "" et chaque perso écrit sous « Prénom- » ; ce qu'il
    -- avait sous « Prénom-Royaume » n'était plus lu (recettes muettes jusqu'à rouvrir chaque métier, rerolls
    -- absents de « Mes artisans »). On le recopie sous « Prénom- » quand celle-ci manque ou est vide, et
    -- seulement si le prénom n'a qu'un ancien royaume (règle du user, 2026-11-24). Les anciennes clés restent :
    -- rien ne s'efface, et tous les lecteurs les écartent (royaume ≠ COC.Api.LOCAL_REALM).
    [3] = function(db)
        local realms = oldRealms(db)
        for _, name in ipairs(PER_CHAR) do
            local tab = db[name]
            if type(tab) == "table" then
                for short, realm in pairs(realms) do
                    local new, old = short .. "-", (realm and tab[short .. "-" .. realm]) or nil
                    local cur = tab[new]
                    if old ~= nil and (cur == nil or (type(cur) == "table" and next(cur) == nil)) then
                        tab[new] = deepCopy(old)
                    end
                end
            end
        end
    end,
}

-- Applique les paliers manquants, dans l'ordre, et avance schemaVer. Sûr sur une DB neuve (vide),
-- héritée non migrée, déjà migrée, ou courante.
function Migrations.Apply(db)
    if type(db) ~= "table" then return end
    for v = (db.schemaVer or 0) + 1, Migrations.VER do
        local fn = Migrations.LADDER[v]
        if fn then fn(db) end
        db.schemaVer = v
    end
end
