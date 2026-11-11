---@diagnostic disable: undefined-global
-- tools/gen_writs.lua — GÉNÈRE CraftingOrderClassic_Writs_Data.lua (hors-jeu) : chaque Craftsman's
-- Writ de WoW: Forever → sa quête journalière, son palier, l'objet qu'elle demande.
--
-- POURQUOI CET OUTIL : le writ et l'objet demandé ne se reconnaissent en jeu que par leurs
-- identifiants (les noms sont traduits). Or les deux pages qui les relient sont en anglais : la
-- recherche Wowhead nomme chaque writ « Craftsman's Writ: <objet> », et les pages Forever des
-- métiers donnent l'identifiant de chaque objet fabriqué. On recoud ici, une fois pour toutes.
-- Spec : docs/specs/writs-aca.md.
--
-- ⚠️ IDENTIFIANTS DE FOREVER, JAMAIS DE CLASSIC : Forever a réattribué des identifiants d'objets
-- (cf. l'en-tête de CraftingOrderClassic_Sources.lua). On ne lit donc que les pages `forever_*`.
--
-- CE QUI SORT DU GÉNÉRATEUR : uniquement des identifiants. Les noms anglais ne restent qu'en
-- commentaire, pour la relecture.
--
-- IL ÉCHOUE PLUTÔT QUE D'ÉCRIRE UN FICHIER PARTIEL : un nom introuvable, un nom qui désigne deux
-- objets sans être déclaré dans HOMONYMS, un writ sans quête, un palier qui ne colle pas à la
-- réputation de sa quête. Un writ qui pointerait vers le mauvais objet ferait commander la mauvaise
-- chose, avec assurance.
--
-- PRÉREQUIS
--   1. La page de recherche « Craftsman's writ » de wowhead.com/forever, EN ANGLAIS, enregistrée par
--      l'extension tools\wowhead-page (elle atterrit dans <Téléchargements>\wowhead\autres\).
--   2. Les pages Forever des cinq métiers dans le cache de CraftLink (CraftLink\tools\wh\
--      forever_<Métier>.html, hors dépôt) ; voir CraftLink\tools\README.md pour les rafraîchir.
--
-- Lancer, depuis la racine de l'atelier :
--   tools\elune\bin\lua.exe CraftingOrderClassic\tools\gen_writs.lua <page de recherche> [<dossier wh>]

local HERE    = (arg[0]:match("^(.*)[/\\]") or ".")
local COCDIR  = HERE .. "/.."
local SEARCH  = arg[1]
local WHDIR   = arg[2] or (COCDIR .. "/../CraftLink/tools/wh")
local OUT     = COCDIR .. "/CraftingOrderClassic_Writs_Data.lua"

local PROFS   = { "Alchemy", "Blacksmithing", "Engineering", "Leatherworking", "Tailoring" }
local TIERS   = { Journeyman = 1, Expert = 2, Artisan = 3 }
local REP     = { 75, 125, 200 }   -- réputation de la quête selon le palier (lue sur Wowhead)
local WRIT_QUEST_CATEGORY = "16941"   -- les writs de Forever ; ceux d'Era (cat. 139) sont un autre système

-- Le writ et l'objet ne s'écrivent pas toujours pareil. Chaque écart est déclaré ici, à la main,
-- avec le seul objet du bon nom trouvé dans les pages Forever (vérifié le 2026-10-16).
local ALIASES = {
    ["Elixir of Ogre's Strength"] = "Elixir of Ogre Strength",    -- 3391
    ["Potion of Demonslaying"]    = "Potion of Demon Slaying",    -- 9224
    ["Gyromatic Micro-Adjuster"]  = "Gyromatic Micro-Adjustor",   -- 10498
}
-- Deux recettes, deux objets, un seul nom. On garde les deux : la quête acceptée dira lequel.
local HOMONYMS = { ["Golden Scale Gauntlets"] = true }   -- 9366, 217273

local function die(msg) io.stderr:write("[gen_writs] ERREUR : " .. msg .. "\n"); os.exit(1) end

local function slurp(path)
    local f = io.open(path, "rb")
    if not f then die("fichier introuvable : " .. tostring(path)) end
    local s = f:read("*a"); f:close(); return s
end

-- Les objets de PREMIER NIVEAU d'un tableau JSON qui commence à `from` (le « [ »). Accolades
-- équilibrées, chaînes respectées : chaque ligne imbrique `envChange`, `sourcemore`, `appearances`.
local function topObjects(s, from)
    local out, depth, start, inStr, esc = {}, 0, nil, false, false
    for i = from + 1, #s do
        local c = s:sub(i, i)
        if inStr then
            if esc then esc = false
            elseif c == "\\" then esc = true
            elseif c == '"' then inStr = false end
        elseif c == '"' then inStr = true
        elseif c == "{" then
            if depth == 0 then start = i end
            depth = depth + 1
        elseif c == "}" then
            depth = depth - 1
            if depth == 0 then out[#out + 1] = s:sub(start, i) end
        elseif c == "]" and depth == 0 then
            return out
        end
    end
    die("tableau JSON non refermé")
end

-- Champs lus d'une ligne. `"id":` exige le guillemet ouvrant : `"displayid":` ne matche pas.
local function field(obj, key) return obj:match('"' .. key .. '":"([^"]*)"') or obj:match('"' .. key .. '":(%-?%d+)') end

-- Les lignes d'une Listview de la page de RECHERCHE : ses données vivent dans un bloc
-- <script type="application/json" id="data.<guid>"> séparé, nommé par WH.getPageData("<guid>").
local function searchRows(html, lvid)
    local at = html:find('id: "' .. lvid .. '"', 1, true) or die("listview « " .. lvid .. " » absente de la page")
    local guid = html:match('WH%.getPageData%("([^"]+)"%)', at) or die("données de « " .. lvid .. " » introuvables")
    local tag = 'id="data.' .. guid .. '">'
    local s = html:find(tag, 1, true) or die("bloc JSON " .. guid .. " absent")
    return topObjects(html, s + #tag)
end

-- Les lignes d'une Listview d'une page de MÉTIER : données en ligne, après « data: [ ».
local function inlineRows(html, lvid, page)
    local at = html:find("id: '" .. lvid .. "'", 1, true) or die("listview « " .. lvid .. " » absente de " .. page)
    local s = html:find("data: [", at, true) or die("données de « " .. lvid .. " » absentes de " .. page)
    return topObjects(html, s + 6)
end

-- =========================================================================
-- 1. Les writs et leurs quêtes (page de recherche)
-- =========================================================================
if not SEARCH then die("usage : lua gen_writs.lua <page de recherche Wowhead> [<dossier wh de CraftLink>]") end
local search = slurp(SEARCH)

local questByName = {}
for _, q in ipairs(searchRows(search, "quests")) do
    local name = field(q, "name")
    if field(q, "category") == WRIT_QUEST_CATEGORY and field(q, "daily") == "1" and name then
        if questByName[name] then die("deux quêtes portent le nom « " .. name .. " »") end
        questByName[name] = { id = tonumber(field(q, "id")), rep = tonumber(q:match('"reprewards":%[%[%d+,(%d+)%]')) }
    end
end

local writs = {}
for _, it in ipairs(searchRows(search, "items")) do
    local name, tier = field(it, "name"), TIERS[field(it, "namedesc") or ""]
    local target = name and name:match("^Craftsman's Writ: (.+)$")
    if target and tier then
        local q = questByName[name] or die("writ sans quête : " .. name)
        if q.rep ~= REP[tier] then die(("palier et réputation en désaccord : %s (%s)"):format(name, tostring(q.rep))) end
        writs[#writs + 1] = { id = tonumber(field(it, "id")), quest = q.id, tier = tier, target = target }
    end
end
table.sort(writs, function(a, b) return a.id < b.id end)

-- =========================================================================
-- 2. Les objets fabriqués, par nom anglais (pages Forever des métiers)
-- =========================================================================
-- Clé en MINUSCULES : le writ écrit « Pearl-Handled Dagger », l'objet « Pearl-handled Dagger ».
local itemsByName = {}
for _, prof in ipairs(PROFS) do
    local page = "forever_" .. prof .. ".html"
    for _, row in ipairs(inlineRows(slurp(WHDIR .. "/" .. page), "crafted-items", page)) do
        local id, name = tonumber(field(row, "id")), field(row, "name")
        name = name and name:lower()
        if id and name then
            local ids = itemsByName[name] or {}
            itemsByName[name] = ids
            local seen = false
            for _, x in ipairs(ids) do if x == id then seen = true end end
            if not seen then ids[#ids + 1] = id end   -- un même objet de deux métiers (Gordok Ogre Suit) : une fois
        end
    end
end

-- =========================================================================
-- 3. Recoudre, ou échouer
-- =========================================================================
for _, w in ipairs(writs) do
    local ids = itemsByName[(ALIASES[w.target] or w.target):lower()] or die("objet introuvable dans les pages Forever : " .. w.target)
    if #ids > 1 and not HOMONYMS[w.target] then die("« " .. w.target .. " » désigne plusieurs objets sans être déclaré dans HOMONYMS") end
    table.sort(ids)
    w.items = ids
end
if #writs == 0 then die("aucun writ lu : est-ce bien la page de recherche « Craftsman's writ » en anglais ?") end

-- =========================================================================
-- 4. Écrire
-- =========================================================================
local srcName = SEARCH:match("([^/\\]+)$")
local lines = {
    "-- CraftingOrderClassic_Writs_Data.lua — les Craftsman's Writ de WoW: Forever.",
    "-- GÉNÉRÉ par tools/gen_writs.lua le " .. os.date("%Y-%m-%d") .. " — NE PAS ÉDITER À LA MAIN.",
    "-- Sources : " .. srcName .. " (recherche « Craftsman's writ », wowhead.com/forever, anglais)",
    "-- et les pages forever_<Métier>.html du cache de CraftLink (objets fabriqués).",
    "--",
    "-- Une ligne : [writ] = { quête, palier, objet demandé [, autre objet du même nom] }.",
    "-- Palier : 1 Journeyman, 2 Expert, 3 Artisan. Les noms en commentaire ne servent qu'à la relecture.",
    "",
    "local COC = CraftingOrderClassic",
    "if not (COC and COC.Writs) then return end",
    "",
    "COC.Writs:Load({",
}
for _, w in ipairs(writs) do
    local row = ("    [%d] = { %d, %d, %s },"):format(w.id, w.quest, w.tier, table.concat(w.items, ", "))
    lines[#lines + 1] = row .. string.rep(" ", math.max(1, 44 - #row)) .. "-- " .. w.target
end
lines[#lines + 1] = "})"

local f = io.open(OUT, "wb") or die("écriture impossible : " .. OUT)
f:write(table.concat(lines, "\n"), "\n"); f:close()
local count = { 0, 0, 0 }
for _, w in ipairs(writs) do count[w.tier] = count[w.tier] + 1 end
print(("[gen_writs] %d writs (Journeyman %d, Expert %d, Artisan %d) -> %s"):format(#writs, count[1], count[2], count[3], OUT))
