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
