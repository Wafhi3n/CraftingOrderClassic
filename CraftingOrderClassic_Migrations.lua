-- CraftingOrderClassic_Migrations.lua — versionnage du schéma SavedVariables.
--
-- Les SavedVariables sont PAR COMPTE et les utilisateurs sautent des versions (v1.2 → v1.8 direct).
-- Une échelle ORDONNÉE de migrations, bornée par `db.schemaVer`, garantit qu'un palier ne tourne
-- NI deux fois NI jamais. Remplace l'ancienne migration ad hoc « knownRecipes v2 » (ex-inline dans
-- CraftingOrderClassic.lua). Les défauts PARESSEUX (COC.db.orders = … or {}, etc.) restent posés à
-- leur point d'usage — ce module ne gère QUE les transformations de format entre versions.
--
-- PUR : aucune dépendance à l'API WoW ni à LibStub → testable hors client (tests headless Elune).

local COC = CraftingOrderClassic
local Migrations = { VER = 1 }
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
