-- CraftingOrderClassic_Craft_Mainline.lua — 3ᵉ backend de lecture de la fenêtre métier, pour les
-- clients MAINLINE/Retail (WoW: Forever / Camelot, interface 16001).
--
-- Le socle `_Craft.lua` sait lire deux API indexées : TradeSkill (métiers normaux) et Craft
-- (Enchantement en Classic Era). Sur Forever AUCUNE des deux n'existe — tout passe par
-- `C_TradeSkillUI`, et surtout le modèle change : les recettes ne sont plus des INDEX dans une
-- liste, elles sont clefées par **`recipeSpellID`**.
--
-- Ce fichier réconcilie les deux mondes : il tient une liste ORDONNÉE de recipeID et expose la
-- même table d'API indexée que les deux autres backends. Le socle et tous ses appelants
-- (ProfWindow, ProfOrders, Enchant_Trade…) continuent de raisonner en index, sans le savoir.
--
-- Deux simplifications offertes par le client, à ne pas réimplémenter :
--   * `relativeDifficulty` donne la couleur de seuil en direct (0 Optimal / 1 Medium / 2 Easy /
--     3 Trivial) → nos `skillColors` générés (lib v11) ne servent plus sur cette cible.
--   * `learned` dit si le joueur connaît la recette → c'est l'entrée du registre, sans déduction.
--
-- Mesuré en jeu le 2026-09-18 (Cuisine) : `supportsQualities = false` partout — Forever n'utilise
-- PAS les paliers de qualité Dragonflight, le modèle d'ordre de COC passe intact.

local COC = CraftingOrderClassic
local Craft = COC.Craft
if not Craft then return end

local Api = COC.Api

-- ⚠️ GARDE DE SAVEUR, non négociable. La parité des `.toc` impose que ce fichier soit listé dans
-- les QUATRE (base / _TBC / _Wrath / _Camelot) — il est donc CHARGÉ sur l'Era aussi. Or le socle
-- teste `Craft.MAINLINE_API` en PREMIER : s'il était posé sur un client Classic, tout le produit
-- live basculerait sur une API qui n'y existe pas. On ne s'enregistre que sur un vrai client
-- MAINLINE, et on exige en plus l'énumérateur moderne (ceinture et bretelles : `C_TradeSkillUI`
-- existe aussi en Era, ce n'est donc PAS un discriminant valable).
local IS_MAINLINE = Api and Api.IS_MAINLINE
local HAS_MODERN  = C_TradeSkillUI
    and (C_TradeSkillUI.GetFilteredRecipeIDs or C_TradeSkillUI.GetAllRecipeIDs) ~= nil
if not (IS_MAINLINE and HAS_MODERN) then return end

-- ---------------------------------------------------------------- cache de la liste

-- `GetFilteredRecipeIDs` rend les recettes APPRISES de la ligne ouverte, dans l'ordre d'affichage.
-- On la relit à chaque `getNum()` (début de passe de lecture) et on sert le reste depuis le cache :
-- sans ça, `ReadRecipes` la rappellerait à chaque ligne, soit du O(n²) pour rien.
local ids, infoCache, schemCache = {}, {}, {}

local function refresh()
    local get = C_TradeSkillUI
        and (C_TradeSkillUI.GetFilteredRecipeIDs or C_TradeSkillUI.GetAllRecipeIDs)
    local ok, list = pcall(get or function() end)
    ids = (ok and type(list) == "table") and list or {}
    infoCache, schemCache = {}, {}
    return ids
end

-- `false` mémorise un échec pour ne pas re-tenter en boucle (nil = pas encore demandé).
local function infoOf(i)
    local id = ids[i]; if not id then return nil end
    local c = infoCache[id]
    if c == nil then
        local ok, r = pcall(C_TradeSkillUI.GetRecipeInfo, id)
        c = (ok and type(r) == "table" and r) or false
        infoCache[id] = c
    end
    return c or nil
end

local function schemOf(i)
    local id = ids[i]; if not id then return nil end
    local c = schemCache[id]
    if c == nil then
        local ok, r = pcall(C_TradeSkillUI.GetRecipeSchematic, id, false)
        c = (ok and type(r) == "table" and r) or false
        schemCache[id] = c
    end
    return c or nil
end

-- ---------------------------------------------------------------- normalisation

-- Le socle et `Craft:DifficultyColor` raisonnent en CHAÎNES Classic. Le client rend un enum.
local DIFF = { [0] = "optimal", [1] = "medium", [2] = "easy", [3] = "trivial" }

local function slotOf(i, j)
    local s = schemOf(i)
    local slots = s and s.reagentSlotSchematics
    return slots and slots[j] or nil
end

-- Un emplacement peut proposer PLUSIEURS réactifs interchangeables (qualités Retail). Forever ne
-- s'en sert pas (`supportsQualities` false partout), donc le premier suffit — mais on passe par
-- cette fonction pour que le jour où ça change, il n'y ait qu'un endroit à reprendre.
local function reagentItemID(slot)
    local r = slot and slot.reagents and slot.reagents[1]
    return r and r.itemID or nil
end

-- ---------------------------------------------------------------- table d'API

local MAINLINE_API = {
    getNum = function() return #refresh() end,

    -- Contrat du socle : (nom, difficulté, nbRéalisables).
    norm = function(i)
        local info = infoOf(i)
        if not info then return nil end
        local avail = 0
        local ok, n = pcall(C_TradeSkillUI.GetCraftableCount, ids[i])
        if ok and tonumber(n) then avail = tonumber(n) end
        return info.name, DIFF[info.relativeDifficulty] or "optimal", avail
    end,

    getInfo = function(i)
        local info = infoOf(i)
        if not info then return nil end
        return info.name, DIFF[info.relativeDifficulty] or "optimal", 0
    end,

    -- Aucun en-tête : la liste de recipeID est PLATE (les catégories sont une donnée à part,
    -- `categoryID` sur chaque recette). Le socle filtre donc zéro ligne ici.
    isHeader = function() return false end,

    -- ⚠️ Le client rend AUSSI les recettes NON APPRISES : `Professions.SetDefaultFilters`
    -- (Blizzard_Professions.lua) pose `SetShowUnlearned(true)` À CHAQUE ouverture de la fenêtre, et
    -- `GetFilteredRecipeIDs` respecte ce filtre. Sans ce témoin, le socle prenait tout pour acquis :
    -- « ce que je sais faire » incluait ce que le perso ne sait PAS faire. `learned` est non-nilable
    -- dans `TradeSkillRecipeInfo`, mais on ne suppose rien d'une fiche absente (= non apprise).
    getLearned = function(i)
        local info = infoOf(i)
        return (info and info.learned == true) or false
    end,

    getLink = function(i) local info = infoOf(i); return info and info.hyperlink or nil end,
    getIcon = function(i) local info = infoOf(i); return info and info.icon or nil end,

    -- La recette EST un sort : le recipeID est le spellID. Plus besoin de le déduire d'un
    -- lien |Henchant: comme sur les deux backends Classic.
    getSpellID = function(i) return ids[i] end,
    getRecipeLink = function(i)
        local id = ids[i]
        if not id then return nil end
        local get = C_Spell and C_Spell.GetSpellLink
        local ok, link = pcall(get or function() end, id)
        return (ok and link) or nil
    end,

    getNumMade = function(i)
        local s = schemOf(i)
        if not s then return 1, 1 end
        return s.quantityMin or 1, s.quantityMax or s.quantityMin or 1
    end,

    getNumReag = function(i)
        local s = schemOf(i)
        local slots = s and s.reagentSlotSchematics
        return slots and #slots or 0
    end,

    getReagInfo = function(i, j)
        local slot = slotOf(i, j)
        local itemID = reagentItemID(slot)
        if not itemID then return nil end
        local name = Api.GetItemInfo and Api.GetItemInfo(itemID) or nil
        local tex  = Api.GetItemIcon and Api.GetItemIcon(itemID) or nil
        local have = (Api.GetItemCount and Api.GetItemCount(itemID, false)) or 0
        return name, tex, slot.quantityRequired or 0, have
    end,

    getReagLink = function(i, j)
        local itemID = reagentItemID(slotOf(i, j))
        if not itemID or not Api.GetItemInfo then return nil end
        return (select(2, Api.GetItemInfo(itemID)))
    end,

    getSkillName = function()
        local get = C_TradeSkillUI and C_TradeSkillUI.GetProfessionSkillLineID
        local ok, lineID = pcall(get or function() end)
        if ok and lineID and C_TradeSkillUI.GetTradeSkillDisplayName then
            local ok2, name = pcall(C_TradeSkillUI.GetTradeSkillDisplayName, lineID)
            if ok2 and name and name ~= "" then return name end
        end
        -- Repli : la fiche de métier porte aussi le nom, et ne demande aucun argument.
        local ok3, info = pcall(C_TradeSkillUI.GetBaseProfessionInfo)
        return (ok3 and type(info) == "table" and info.professionName) or nil
    end,

    -- `DoCraft` était protégé, `CraftRecipe` ne l'est pas : le montage SecureActionButton +
    -- CraftCreateButton du socle n'a plus lieu d'être sur cette cible.
    craft = function(i, n)
        local id = ids[i]
        if not (id and C_TradeSkillUI and C_TradeSkillUI.CraftRecipe) then return end
        pcall(C_TradeSkillUI.CraftRecipe, id, n or 1)
    end,
}

Craft.MAINLINE_API = MAINLINE_API

-- Rang du métier ouvert, sans passer par l'annuaire : la fiche le porte directement.
function Craft:MainlineRank()
    local ok, info = pcall(C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo or function() end)
    if ok and type(info) == "table" and info.skillLevel then
        return info.skillLevel, info.maxSkillLevel
    end
    return nil
end

-- La session de métier est-elle lisible ? (équivalent Mainline de « la fenêtre est ouverte »)
function Craft:MainlineOpen()
    local ready = C_TradeSkillUI and C_TradeSkillUI.IsTradeSkillReady
    if ready then
        local ok, v = pcall(ready)
        if ok then return v and true or false end
    end
    return (MAINLINE_API.getSkillName() ~= nil)
end

-- ---------------------------------------------------------------- fiche d'une recette PAR SON SORT

-- `GetRecipeInfo` répond pour un recipeSpellID QUELCONQUE, appris ou NON. Mesuré en jeu le
-- 2026-09-20 sur le sort 2539 (« Spiced Wolf Meat », pas apprise) : fiche complète, avec le lien de
-- l'objet produit, son icône, la couleur de la recette AU RANG COURANT et le nombre de points
-- qu'elle rapporte encore. Sur une saveur jeune c'est la seule référence qui ne peut pas être
-- périmée, et elle répond sur une recette MANQUANTE là où nos données générées ne font qu'estimer.
--
-- ⚠️ CE QU'ELLE NE DIT PAS : LA PROVENANCE. `sourceType` est absent de la fiche (champ nilable non
-- renseigné) et `GetRecipeSourceText(2539)` rend vide ALORS QUE le client connaît parfaitement la
-- recette — ce n'est donc pas un raté de lookup, le client n'a rien à dire là-dessus. Le « où
-- aller » reste au catalogue et à l'observation ; ici on ne récolte que le « quoi » et le « est-ce
-- que ça vaut le coup ».
-- La recette appartient-elle au métier OUVERT ? `relativeDifficulty`, `canSkillUp` et
-- `maxTrivialLevel` sont des valeurs RELATIVES : le client les calcule contre la ligne de métier
-- OUVERTE, pas contre celle de la recette. Mesuré en jeu le 2026-09-20 -- la même recette de Cuisine
-- passe de « +1 point » à « ne rapporte plus de point » selon qu'on a la Cuisine ou l'Herboristerie
-- devant soi. L'IDENTITÉ (nom, lien, icône), elle, reste vraie quoi qu'il arrive : un objet est un
-- objet. On rend donc l'une toujours, et l'autre seulement quand elle veut dire quelque chose.
local function judgesThisLine(spellID)
    local byRecipe = C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoByRecipeID
    local open     = C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo
    if not (byRecipe and open) then return false end
    local ok1, a = pcall(byRecipe, spellID)
    local ok2, b = pcall(open)
    if not (ok1 and ok2 and type(a) == "table" and type(b) == "table") then return false end
    return a.professionID ~= nil and a.professionID == b.professionID
end

function Craft:MainlineRecipeFacts(spellID)
    if not (spellID and C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo) then return nil end
    local ok, i = pcall(C_TradeSkillUI.GetRecipeInfo, spellID)
    -- Un id hors de la ligne ouverte (recette fantôme du catalogue, métier d'à côté) rend nil ou
    -- une fiche qui parle d'AUTRE CHOSE : on exige que le client réponde bien sur CE sort-là.
    if not (ok and type(i) == "table" and i.recipeID == spellID and i.name) then return nil end
    -- Hors du métier ouvert, le verdict de progression n'a AUCUN sens : `difficulty` reste nil, et
    -- les appelants qui s'en servent de garde ne diront donc rien plutôt que de dire faux.
    local judges = judgesThisLine(spellID)
    return {
        name  = i.name, link = i.hyperlink, icon = i.icon,
        difficulty = judges and DIFF[i.relativeDifficulty] or nil,
        learned = i.learned == true,
        -- `canSkillUp` false ⇒ 0 point, sans se fier à `numSkillUps` qui garde sa dernière valeur.
        skillUps = (judges and i.canSkillUp and (i.numSkillUps or 1)) or 0,
        trivialAt = judges and i.maxTrivialLevel or nil,
        judgesThisLine = judges,
    }
end
