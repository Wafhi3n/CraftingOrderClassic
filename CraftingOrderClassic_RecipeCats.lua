-- CraftingOrderClassic_RecipeCats.lua — SOUS-CATÉGORIES de recettes (moteur + registre).
--
-- POURQUOI : le client Classic Era ne distingue pas les types de consommables — toutes les potions,
-- élixirs et flacons d'alchimie ont la MÊME classe d'objet (« Consommable »). GetItemInfoInstant ne
-- peut donc pas répondre « ceci est une potion de mana » : l'information n'existe pas côté jeu, il
-- faut l'apporter. C'est ce que fait ce module : un niveau de regroupement EN PLUS de la section
-- dérivée de l'objet (COC.SectionOf), déclaré à la main par métier.
--
-- ARBRE OBTENU dans la vue métier :   Consommable  >  Potions de mana  >  les recettes
--                                     (COC.SectionOf)   (ce module)        (tri par niveau ↓)
--
-- CONTRAT DES DONNÉES (voir _RecipeCats_Alchemy.lua pour l'exemple) :
--   * on déclare des groupes de itemID — JAMAIS des noms. Les noms d'objets sont localisés par le
--     client, donc toute règle textuelle (« ça contient Mana ») casserait hors anglais ;
--   * l'ORDRE des itemID dans un groupe n'a aucune importance : le tri interne est fait par le
--     niveau de métier de la recette (learnedAt, donnée statique CraftLink), du plus haut au plus
--     bas. Aucune dépendance au cache d'objets du client → classement correct dès le 1er rendu ;
--   * la SECTION parente n'est pas déclarée : chaque objet garde celle que COC.SectionOf lui donne.
--     Un groupe peut donc s'afficher sous deux sections (les huiles d'alchimie sont pour partie des
--     consommables, pour partie des composants) — c'est voulu, chaque en-tête est unique par couple
--     (section, sous-catégorie) ;
--   * APPARTENANCE MULTIPLE assumée : un même itemID peut être listé dans PLUSIEURS groupes, et la
--     recette apparaîtra alors sous chacun. C'est nécessaire, pas un effet de bord : la potion de
--     rajeunissement rend vie ET mana, donc un artisan la cherchera aussi bien sous « soin » que
--     sous « mana ». Le classement est un système d'étiquettes, pas une partition ;
--   * tout itemID non déclaré retombe dans « Divers » de sa section : rien ne disparaît jamais de la
--     liste si la table est incomplète.
--
-- Un métier SANS table déclarée garde exactement l'affichage d'avant (sections à plat, pas de
-- sous-niveau) : ce module est purement additif.

local COC = CraftingOrderClassic
local L   = COC.L

local RC = {}
COC.RecipeCats = RC

-- [profKey] = { { name = <clé de locale>, items = { itemID, ... } }, ... }  (ordre = ordre d'affichage)
local defs = {}
-- Index construit à la demande : [profKey][itemID] = { {sub = <libellé localisé>, order = <rang>}, ... }
-- C'est une LISTE : un objet peut appartenir à plusieurs sous-catégories (rajeunissement = soin + mana).
local index = {}

local UNSORTED_ORDER = 999   -- « Divers » toujours en fin de section

-- Déclare les sous-catégories d'un métier. profKey = clé canonique CraftLink (« Alchemy »), telle que
-- rendue par Craft:OpenProfessionKey(). Appelé au chargement par les fichiers de données.
-- APPEND si le métier a déjà des groupes : un même métier peut déclarer ses sous-catégories depuis
-- PLUSIEURS fichiers (le Minage = « Minerais » côté récolte + « Lingots » côté fonte). Dédup par NOM
-- de groupe → idempotent (une re-déclaration à chaud n'ajoute pas de doublon).
function RC:Register(profKey, groups)
    if not (profKey and groups) then return end
    local existing = defs[profKey]
    if existing then
        local seen = {}
        for _, g in ipairs(existing) do seen[g.name] = true end
        for _, g in ipairs(groups) do if not seen[g.name] then existing[#existing + 1] = g end end
    else
        defs[profKey] = groups
    end
    index[profKey] = nil   -- invalide l'index (nouvelle déclaration ou ajout)
end

function RC:HasCategories(profKey)
    return profKey ~= nil and defs[profKey] ~= nil
end

local function buildIndex(profKey)
    local map = {}
    for order, group in ipairs(defs[profKey] or {}) do
        local label = L[group.name] or group.name
        local items = group.items or {}
        local n = #items
        for pos, itemID in ipairs(items) do
            local list = map[itemID]
            if not list then list = {}; map[itemID] = list end
            -- Rang interne au groupe : le niveau de métier de la recette si on le connaît (tri auto
            -- « du plus fort au plus faible », l'ordre de la liste n'a alors aucune importance) ;
            -- SINON l'ORDRE DÉCLARÉ fait foi — 1re ligne du groupe = 1re affichée. C'est le cas des
            -- métiers de RÉCOLTE : une peau ou un minerai n'est pas une recette, il n'a pas de
            -- learnedAt, donc c'est l'auteur du fichier qui range du plus haut niveau au plus bas.
            local tier = RC:Tier(profKey, itemID)
            if tier == 0 then tier = n - pos + 1 end
            list[#list + 1] = { sub = label, order = order, tier = tier }   -- appartenance CUMULATIVE
        end
    end
    index[profKey] = map
    return map
end

-- Sous-catégories d'un objet : LISTE de { sub = <libellé localisé>, order = <rang>, tier = <rang interne> }.
-- Plusieurs entrées = l'objet s'affiche sous plusieurs en-têtes (il a plusieurs effets).
-- Renvoie nil si le métier n'a aucune table déclarée → l'appelant garde l'affichage à plat d'avant.
function RC:SubsOf(profKey, itemID)
    if not (profKey and defs[profKey]) then return nil end
    local map = index[profKey] or buildIndex(profKey)
    local hit = itemID and map[itemID]
    if hit then return hit end
    return { { sub = L["Divers"], order = UNSORTED_ORDER, tier = self:Tier(profKey, itemID) } }
end

-- Rang de tri INTERNE à une sous-catégorie : le niveau de métier auquel la recette s'apprend
-- (donnée statique CraftLink, lisible sans cache). Le plus haut d'abord → la potion de mana majeure
-- (295) passe devant la mineure (25). 0 si inconnu (la recette tombe en fin de groupe).
function RC:Tier(profKey, itemID)
    if not (profKey and itemID) then return 0 end
    local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    if not lib then return 0 end
    local i2s = lib.ItemToSpell and lib:ItemToSpell(profKey)
    local spellID = i2s and i2s[itemID]
    if not spellID then return 0 end
    return (lib.RecipeLearnedAt and lib:RecipeLearnedAt(profKey, spellID)) or 0
end
