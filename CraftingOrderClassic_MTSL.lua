-- CraftingOrderClassic_MTSL.lua — pont LECTURE SEULE vers l'addon « Missing TradeSkills List » (MTSL).
--
-- BUT : afficher, dans la vue métier, les recettes que le personnage courant N'A PAS encore apprises,
-- et d'où elles viennent (formateur/prix, butin, quête, réputation…). Ces recettes sont par définition
-- ABSENTES de la fenêtre de métier native, donc invisibles pour COC.Craft:ReadRecipes() — seule une
-- base de données externe les connaît. MTSL en fournit une, complète et localisée.
--
-- DÉPENDANCE MOLLE, JAMAIS DURE : COC reste autonome. Si MTSL n'est pas installé (ou pas encore
-- chargé), IsAvailable() renvoie false et la fonctionnalité s'efface — aucun plantage, aucun toc à
-- modifier. On lit ses globales, on n'appelle JAMAIS son UI ni sa logique interne.
--
-- CE QU'ON LIT (globales publiques de MTSL) :
--   MTSL_DATA.skills[prof]                          toutes les recettes : { id=spellID, min_skill,
--                                                    name={langue=…}, phase, trainers/reputation/… }
--   MTSL_CURRENT_PLAYER.TRADESKILLS[prof].MISSING_SKILLS   spellID manquants pour CE perso (calculé
--                                                    par MTSL au login à partir des skills appris)
--   MTSL_DATA.npcs / zones / factions / reputation_levels   pour résoudre les sources en texte lisible.
--
-- CE QU'ON NE BAKE JAMAIS : les noms restent puisés dans MTSL au runtime selon la langue du client —
-- rien n'est figé en anglais, cohérent avec le reste de l'écosystème.

local COC = CraftingOrderClassic
local MTSL = {}
COC.MTSL = MTSL

-- MTSL nomme les métiers en anglais AVEC espaces ; nos profKey CraftLink sont sans espace pour deux
-- d'entre eux. Table de correspondance profKey COC -> clé MTSL (identité pour tous les autres).
local PROF_KEY = { FirstAid = "First Aid" }

-- GetLocale() -> clé de langue MTSL. Repli anglais pour toute langue non couverte.
local LOCALE = {
    enUS = "English", enGB = "English", frFR = "French", deDE = "German",
    esES = "Spanish", esMX = "Mexican", ruRU = "Russian", koKR = "Korean",
    zhCN = "Chinese", zhTW = "Taiwanese", ptBR = "Portuguese", ptPT = "Portuguese",
}
local function lang()
    return LOCALE[GetLocale and GetLocale() or "enUS"] or "English"
end

-- Nom localisé depuis une sous-table { English=…, French=… } de MTSL (repli anglais puis "?").
local function loc(names)
    if type(names) ~= "table" then return tostring(names or "?") end
    return names[lang()] or names.English or "?"
end

function MTSL:IsAvailable()
    return type(_G.MTSL_DATA) == "table" and type(MTSL_DATA.skills) == "table"
end

local function mtslProf(profKey)
    return profKey and (PROF_KEY[profKey] or profKey) or nil
end

-- Index paresseux spellID -> skill, par métier (les données MTSL sont des LISTES, pas des maps).
local skillIndex = {}
local function indexOf(mprof)
    if skillIndex[mprof] then return skillIndex[mprof] end
    local map = {}
    for _, sk in ipairs((MTSL_DATA.skills or {})[mprof] or {}) do
        if sk.id then map[sk.id] = sk end
    end
    skillIndex[mprof] = map
    return map
end

-- Lookups paresseux par id sur les tables-listes de MTSL (npcs, zones, factions, rep levels).
local byId = {}
local function lookup(kind)
    if byId[kind] then return byId[kind] end
    local map = {}
    for _, row in ipairs((MTSL_DATA or {})[kind] or {}) do
        if row.id then map[row.id] = row end
    end
    byId[kind] = map
    return map
end

-- Reverse paresseux spellID -> objet-recette qui l'enseigne, depuis CraftLink taughtBy (recipeItemID
-- -> spellID). Beaucoup de recettes de haut niveau ne s'apprennent PAS au formateur mais via un objet
-- (butin/vendeur) : MTSL range ces sources dans items.lua, pas dans le skill → sans ce repli elles
-- retomberaient en « inconnu ». Par métier, construit à la 1re demande.
local taughtRev = {}
local function recipeItemFor(profKey, spellID)
    local rev = taughtRev[profKey]
    if not rev then
        rev = {}
        local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
        local def = lib and lib.GetProfession and lib:GetProfession(profKey)
        for itemID, sid in pairs(def and def.taughtBy or {}) do rev[sid] = itemID end
        taughtRev[profKey] = rev
    end
    return rev[spellID]
end

-- Index paresseux objet-recette (itemID -> entrée items.lua avec ses sources vendors/drops/quests),
-- par métier. C'est là que MTSL range OÙ trouver l'objet qui enseigne une recette de butin/vendeur.
local itemIndex = {}
local function itemsOf(mprof)
    if itemIndex[mprof] then return itemIndex[mprof] end
    local map = {}
    for _, it in ipairs((MTSL_DATA.items or {})[mprof] or {}) do
        if it.id then map[it.id] = it end
    end
    itemIndex[mprof] = map
    return map
end

-- Une ligne PNJ prête à afficher : « [niveau] Nom — Zone (x, y) », comme la fiche MTSL. Coords/zone
-- résolues via npcs.lua + zones.lua. Renvoie nil si le PNJ est inconnu.
local function npcLine(npcId)
    local npc = lookup("npcs")[npcId]; if not npc then return nil end
    local lvl = npc.xp_level and npc.xp_level.max
    local zone = npc.zone_id and lookup("zones")[npc.zone_id]
    local coord = npc.location and npc.location.x and npc.location.y
        and string.format(" (%s, %s)", npc.location.x, npc.location.y) or ""
    local lvlTag = lvl and lvl > 0 and ("|cFF888888[" .. lvl .. "]|r ") or ""
    return lvlTag .. loc(npc.name) .. (zone and (" |cFF888888— " .. loc(zone.name) .. coord .. "|r") or "")
end

-- Ajoute jusqu'à `maxN` lignes PNJ (formateurs / vendeurs / mobs) à `lines` sous le libellé `label`.
local function addNpcLines(lines, label, sources, maxN)
    local shown = 0
    for _, npcId in ipairs(sources or {}) do
        local ln = npcLine(npcId)
        if ln then
            lines[#lines + 1] = { label = shown == 0 and label or "", value = ln }
            shown = shown + 1
            if shown >= (maxN or 3) then break end
        end
    end
    local total = #(sources or {})
    if total > shown then lines[#lines].value = lines[#lines].value .. string.format(" |cFF888888(+%d)|r", total - shown) end
end

-- Fiche DÉTAILLÉE d'une recette manquante -> { lines = { {label, value}, ... }, itemID = objet-recette }.
-- Reproduit l'essentiel de la fiche MTSL : niveau requis, réputation, prix, « appris de » (objet-recette),
-- « obtenu via » (formateur/vendeur/butin/quête) et la liste des PNJ (nom + zone + coords). Les libellés
-- sont localisés via COC.L ; les noms de données via MTSL selon la langue du client.
function MTSL:SkillDetail(profKey, spellID)
    local L = COC.L
    local lines = { }
    if not self:IsAvailable() then return { lines = lines } end
    local mprof = mtslProf(profKey)
    local sk = mprof and indexOf(mprof)[spellID]
    if not sk then return { lines = lines } end

    lines[#lines + 1] = { label = L["Niveau requis"], value = "|cFF33DD33" .. (sk.min_skill or 0) .. "|r" }
    if sk.reputation then
        local fac = lookup("factions")[sk.reputation.faction_id]
        local lvl = lookup("reputation_levels")[sk.reputation.level_id]
        lines[#lines + 1] = { label = L["Réputation"],
            value = (fac and loc(fac.name) or "?") .. " · " .. (lvl and loc(lvl.name) or "") }
    end

    local recItemID
    if sk.trainers then
        lines[#lines + 1] = { label = L["Obtenu via"], value = "|cFF88CCFF" .. L["Formateur"] .. "|r" }
        if sk.trainers.price and sk.trainers.price > 0 then
            lines[#lines + 1] = { label = L["Prix"], value = GetCoinTextureString(sk.trainers.price) }
        end
        addNpcLines(lines, L["Formateurs"], sk.trainers.sources, 4)
    else
        -- Recette apprise d'un OBJET : nom + sources de CET objet (vendeur/butin/quête) via items.lua.
        recItemID = recipeItemFor(profKey, spellID)
        local item = recItemID and itemsOf(mprof)[recItemID]
        if recItemID then
            local nm = (GetItemInfo and GetItemInfo(recItemID)) or (item and loc(item.name)) or ("item:" .. recItemID)
            lines[#lines + 1] = { label = L["Appris de"], value = nm }
        end
        if item and item.vendors then
            lines[#lines + 1] = { label = L["Obtenu via"], value = "|cFFEEDD88" .. L["Vendeur"] .. "|r" }
            if item.vendors.price and item.vendors.price > 0 then
                lines[#lines + 1] = { label = L["Prix"], value = GetCoinTextureString(item.vendors.price) }
            end
            addNpcLines(lines, L["Vendu par"], item.vendors.sources, 4)
        elseif item and item.drops then
            lines[#lines + 1] = { label = L["Obtenu via"], value = "|cFFEE8833" .. L["Butin"] .. "|r" }
            addNpcLines(lines, L["Butin sur"], item.drops.sources, 4)
        elseif item and item.quests then
            lines[#lines + 1] = { label = L["Obtenu via"], value = "|cFFFFCC00" .. L["Quête"] .. "|r" }
        elseif not recItemID then
            lines[#lines + 1] = { label = L["Obtenu via"], value = "|cFF888888" .. L["Source inconnue"] .. "|r" }
        end
    end
    return { lines = lines, itemID = recItemID }
end

-- Recettes MANQUANTES du perso courant pour un métier. Renvoie une liste d'entrées au MÊME format que
-- COC.Craft:ReadRecipes() (name, itemID, icon, difficulty…) + isMissing/spellID/level/source, pour que
-- la vue métier et le regroupement RecipeCats les traitent sans cas particulier. itemID = objet produit
-- (via CraftLink produces) → permet le classement en sous-catégories ET l'icône. Vide si MTSL absent,
-- ou si MTSL n'a pas encore calculé les manquants (fenêtre de métier jamais ouverte de la session).
function MTSL:MissingRecipes(profKey)
    if not self:IsAvailable() then return {} end
    local mprof = mtslProf(profKey); if not mprof then return {} end
    local player = _G.MTSL_CURRENT_PLAYER
    local ts = player and player.TRADESKILLS and player.TRADESKILLS[mprof]
    if not (ts and ts.MISSING_SKILLS) then return {} end

    local idx = indexOf(mprof)
    local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    local out = {}
    for _, spellID in ipairs(ts.MISSING_SKILLS) do
        local sk = idx[spellID]
        if sk then
            local itemID = lib and lib.RecipeProduct and lib:RecipeProduct(profKey, spellID) or nil
            -- Léger : on ne calcule PAS la fiche source ici (elle l'est à la sélection, cf. SkillDetail) —
            -- sinon on résoudrait PNJ/zones pour 100+ recettes à chaque rafraîchissement de liste.
            out[#out + 1] = {
                isMissing = true, spellID = spellID, itemID = itemID,
                name = loc(sk.name), level = sk.min_skill or 0,
                icon = itemID and GetItemIcon and GetItemIcon(itemID) or "Interface\\Icons\\INV_Scroll_03",
                difficulty = "trivial",   -- neutre : une recette non apprise n'a pas de couleur de difficulté
            }
        end
    end
    return out
end

-- Rang de compétence REQUIS d'une recette, par spellID, via l'index MTSL. nil si MTSL absent, métier
-- inconnu ou recette hors base. Sert à afficher « (niv. X) » sur les recettes APPRISES (les manquantes
-- portent déjà leur niveau via MissingRecipes). Même index paresseux que MissingRecipes → coût nul.
function MTSL:MinSkill(profKey, spellID)
    if not (self:IsAvailable() and spellID) then return nil end
    local mprof = mtslProf(profKey); if not mprof then return nil end
    local sk = indexOf(mprof)[spellID]
    return sk and sk.min_skill or nil
end

-- itemID de l'OBJET-RECETTE (parchemin/patron/plan) qui enseigne un plan, ou nil : recette de formateur
-- (apprise sans objet) ou hors base CraftLink. Sert au pont prix HV (Lazy Gold, « Acheter à l'HV ») et
-- au filtre « acquérables ». Repose sur taughtBy — indépendant du chargement de MTSL.
function MTSL:RecipeItem(profKey, spellID)
    return recipeItemFor(profKey, spellID)
end

-- Catégorie de SOURCE d'une recette, SANS résoudre les PNJ (le coûteux) : "trainer" | "vendor" | "drop"
-- | "quest" | "unknown". Léger (index paresseux déjà chauds) → utilisable pour FILTRER toute la liste à
-- chaque refresh. Le formateur se lit direct sur le skill ; sinon on classe l'objet-recette via items.lua.
function MTSL:SourceKind(profKey, spellID)
    if not (self:IsAvailable() and spellID) then return "unknown" end
    local mprof = mtslProf(profKey); if not mprof then return "unknown" end
    local sk = indexOf(mprof)[spellID]; if not sk then return "unknown" end
    if sk.trainers then return "trainer" end
    local recItemID = recipeItemFor(profKey, spellID)
    local item = recItemID and itemsOf(mprof)[recItemID]
    if item then
        if item.vendors then return "vendor"
        elseif item.drops then return "drop"
        elseif item.quests then return "quest" end
    end
    return "unknown"
end
