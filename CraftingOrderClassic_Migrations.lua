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
local Migrations = { VER = 2 }
COC.Migrations = Migrations

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
