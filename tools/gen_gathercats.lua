---@diagnostic disable: undefined-global
-- tools/gen_gathercats.lua — GÉNÈRE CraftingOrderClassic_RecipeCats_Gathering.lua (hors-jeu).
--
-- POURQUOI CET OUTIL : les tables `gathers` de CraftLink ne contiennent que des itemID, sans nom (le
-- client les résout au runtime via GetItemInfo). Impossible, donc, de savoir depuis le dépôt qu'un
-- itemID est une écaille plutôt qu'une peau — et classer de mémoire se paie cash : 12607 n'est PAS
-- « Core Leather » (c'est 17012) mais « Brilliant Chromatic Scale ». Une écaille rangée dans les
-- cuirs est pire que pas de catégorie du tout. Cet outil va donc chercher la vérité chez Wowhead.
--
-- CE QUI SORT DU GÉNÉRATEUR : uniquement des itemID. Les NOMS ne sont jamais bakés dans l'addon —
-- ils ne servent qu'ici, à la classification. La localisation reste donc intacte.
--
-- PRÉREQUIS — récupérer le HTML des pages de LISTE (une page = toute une catégorie d'objets, avec
-- id + name + level dans sa table JS ; WebFetch ne marche pas, il jette le JS). Depuis tools/ :
--   for c in leather herb metal-and-stone meat elemental other ; do
--     curl -sL -A "Mozilla/5.0" "https://www.wowhead.com/classic/items/trade-goods/$c" -o "wh/classic_$c.html"
--   done
--   curl -sL -A "Mozilla/5.0" "https://www.wowhead.com/classic/items/miscellaneous/reagent"     -o wh/classic_reagent.html
--   curl -sL -A "Mozilla/5.0" "https://www.wowhead.com/classic/items/consumables/food-and-drink" -o wh/food.html
--   # idem pour tbc/ et wotlk/ (leather herb metal-and-stone meat + miscellaneous/reagent)
-- ATTENTION : -L est obligatoire (Wowhead redirige ; sans lui on récupère 0 octet).
--
-- Lancer :  tools\elune\bin\lua.exe CraftingOrderClassic\tools\gen_gathercats.lua

local ROOT = "f:\\AddonDevellopement\\CraftingOrderClassic\\"
local WH   = ROOT .. "tools\\wh\\"
local OUT  = ROOT .. "CraftingOrderClassic_RecipeCats_Gathering.lua"

local PAGES = {
    "classic_leather", "classic_herb", "classic_metal-and-stone", "classic_meat",
    "classic_elemental", "classic_other", "classic_reagent", "food",
    "tbc_leather", "tbc_herb", "tbc_metal-and-stone", "tbc_meat", "tbc_reagent",
    "wotlk_leather", "wotlk_herb", "wotlk_metal-and-stone", "wotlk_meat", "wotlk_reagent",
}

-- =========================================================================
-- 1. Table itemID -> { name, level } depuis les pages Wowhead
-- =========================================================================
-- Les enregistrements contiennent des objets IMBRIQUÉS (« sourcemore ») : on ne peut pas découper sur
-- {...} sans imbrication (c'était le bug de la 1re passe, qui perdait 1 objet sur 4). On lit donc les
-- champs dans l'ordre où Wowhead les émet.
local function loadItems()
    local db = {}
    for _, page in ipairs(PAGES) do
        local f = io.open(WH .. page .. ".html", "r")
        if f then
            local html = f:read("*a"); f:close()
            for id, lvl, name in html:gmatch('"id":(%d+),"level":(%d+),"name":"([^"]*)"') do
                id = tonumber(id)
                if id and not db[id] then db[id] = { name = name, level = tonumber(lvl) or 0 } end
            end
        else
            print("  [!] page absente : " .. page .. ".html")
        end
    end
    return db
end

-- =========================================================================
-- 2. Listes `gathers` : lues DANS les données CraftLink (jamais recopiées à la main)
-- =========================================================================
local function loadGathers()
    local profs = {}
    local stub = {}
    function stub:RegisterProfession(name, def) profs[name] = def.gathers or {} end
    LibStub = { GetLibrary = function() return stub end }
    dofile(ROOT .. "Libs\\CraftLink-1.0\\Data\\Gathering.lua")
    return profs
end

-- =========================================================================
-- 3. Classification par NOM ANGLAIS (hors-jeu : aucun risque de locale)
-- =========================================================================
-- Ordre = ordre d'affichage des sous-catégories. Le 1er motif qui matche gagne.
local RULES = {
    Skinning = {
        { group = "Cuirs",     match = { "Leather", "Scraps" } },
        { group = "Peaux",     match = { "Hide" } },
        { group = "Écailles",  match = { "Scale", "Armorfish" } },
    },
    Mining     = { { group = "Minerais", match = { "Ore" } } },
    Herbalism  = { { group = "Herbes",   match = { "" } } },   -- "" = tout (une seule sous-catégorie)
    Fishing    = { { group = "Poissons", match = { "" } } },
}

-- Niveau d'objet CORRIGÉ À LA MAIN. Wowhead donne un `level` de 1 aux objets rangés en
-- « Miscellaneous > Reagent » (Écaille déviante, Écaille chromatique éclatante…) : ce champ ne
-- reflète alors PAS la progression, et trier dessus collerait l'écaille chromatique (fin de jeu) tout
-- en bas du groupe. Ces valeurs sont un choix ÉDITORIAL de tri (elles n'affectent que l'ordre
-- d'affichage, jamais la catégorie) : niveau approximatif de la zone où l'objet se récolte.
local LEVEL_FIX = {
    [10620] = 50,   -- Thorium Ore : même niveau d'objet (40) que le Mithril, mais se mine 70 points de
                    -- métier plus haut (245 vs 175) → sans ça le départage alphabétique le range SOUS
                    -- le mithril, ce qui est faux dans une liste censée aller du plus haut au plus bas.
    [12607] = 60,   -- Brilliant Chromatic Scale (fin de jeu)
    [12731] = 60,   -- Pristine Hide of the Beast (fin de jeu)
    [7287]  = 20,   -- Red Whelp Scale
    [6471]  = 25,   -- Perfect Deviate Scale
    [6470]  = 20,   -- Deviate Scale
}

-- Objets ABSENTS des pages de liste (Blizzard les range ailleurs que dans leur catégorie évidente) :
-- résolus un par un sur leur page objet — curl -sL "https://www.wowhead.com/wotlk/item=<id>".
-- NB : 28547 (Elemental Power Extractor) et 38568 (Drakkari Charm Bracelet) sont aussi dans la liste
-- `gathers` du Dépeçage mais ne sont NI cuir NI peau NI écaille → volontairement non classés (Divers).
local ITEM_FIX = {
    [12607] = { name = "Brilliant Chromatic Scale", level = 60 },
    [12731] = { name = "Pristine Hide of the Beast", level = 60 },
}

local function groupOf(prof, name)
    for _, rule in ipairs(RULES[prof] or {}) do
        for _, pat in ipairs(rule.match) do
            if pat == "" or name:find(pat, 1, true) then return rule.group end
        end
    end
    return nil   -- non classé -> « Divers » au runtime (l'objet reste visible)
end

-- =========================================================================
-- 4. Génération
-- =========================================================================
local items, gathers = loadItems(), loadGathers()
for id, e in pairs(ITEM_FIX) do items[id] = items[id] or e end
local ORDER = { "Skinning", "Mining", "Herbalism", "Fishing" }

local out, unknown = {}, {}
for _, prof in ipairs(ORDER) do
    local groups, seen = {}, {}
    for _, id in ipairs(gathers[prof] or {}) do
        local it = items[id]
        if not it then
            unknown[#unknown + 1] = string.format("%s %d", prof, id)
        else
            local g = groupOf(prof, it.name)
            if g then
                if not seen[g] then seen[g] = { name = g, list = {} }; groups[#groups + 1] = seen[g] end
                local lvl = LEVEL_FIX[id] or it.level
                table.insert(seen[g].list, { id = id, name = it.name, level = lvl })
            end
        end
    end
    -- Tri DÉCROISSANT : le plus haut niveau en tête (départage par nom, pour un diff stable).
    for _, g in ipairs(groups) do
        table.sort(g.list, function(a, b)
            if a.level ~= b.level then return a.level > b.level end
            return a.name < b.name
        end)
    end
    out[prof] = groups
end

local fh = assert(io.open(OUT, "w"))
fh:write([[
-- CraftingOrderClassic_RecipeCats_Gathering.lua — sous-catégories des métiers de RÉCOLTE.
-- GÉNÉRÉ par tools/gen_gathercats.lua (source : Wowhead) — NE PAS ÉDITER À LA MAIN.
--
-- Une peau ou un minerai n'est PAS une recette : aucun `learnedAt` à lire, le tri automatique « du
-- plus haut au plus bas » n'a rien sur quoi s'appuyer. C'est donc l'ORDRE DÉCLARÉ ci-dessous qui fait
-- foi (cf. le contrat dans _RecipeCats.lua) : chaque groupe est rangé du plus haut niveau au plus bas,
-- d'après le niveau d'objet Wowhead. Les noms en commentaire ne servent QU'À LA RELECTURE — seuls les
-- itemID comptent, le client localise tout seul.
--
-- Un itemID absent de ces listes n'est pas perdu : il tombe dans « Divers » de sa section.

local COC = CraftingOrderClassic
if not (COC and COC.RecipeCats) then return end
]])

for _, prof in ipairs(ORDER) do
    local groups = out[prof]
    if groups and #groups > 0 then
        fh:write("\nCOC.RecipeCats:Register(\"" .. prof .. "\", {\n")
        for _, g in ipairs(groups) do
            fh:write("    { name = \"" .. g.name .. "\",\n      items = {\n")
            for _, e in ipairs(g.list) do
                fh:write(string.format("        %-7s -- %s (%d)\n", e.id .. ",", e.name, e.level))
            end
            fh:write("      } },\n")
        end
        fh:write("})\n")
    end
end
fh:close()

print("Ecrit : " .. OUT)
for _, prof in ipairs(ORDER) do
    local n = 0
    for _, g in ipairs(out[prof] or {}) do n = n + #g.list end
    print(string.format("  %-12s %d groupe(s), %d objet(s) classes", prof, #(out[prof] or {}), n))
end
if #unknown > 0 then
    print("  Non resolus (restent en Divers, visibles) : " .. table.concat(unknown, ", "))
end
