-- CraftingOrderClassic_Craft_Mainline.lua — backend de lecture de la fenêtre métier, pour les
-- clients MAINLINE/Retail (WoW: Forever / Camelot, interface 16001). Le SEUL depuis le 2026-09-21 :
-- les deux backends Classic (TradeSkill, Craft) ont été retirés avec l'Era.
--
-- Tout passe par `C_TradeSkillUI`, et le modèle n'est plus celui de l'Era : les recettes ne sont
-- plus des INDEX dans une liste, elles sont clefées par **`recipeSpellID`**. Ce fichier tient une
-- liste ORDONNÉE de recipeID et expose une table d'API INDEXÉE : le socle et tous ses appelants
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

-- ⚠️ GARDE DE SAVEUR, non négociable. Elle datait de l'époque où la parité des `.toc` imposait que
-- ce fichier soit listé dans les QUATRE (base / _TBC / _Wrath / _Camelot), donc CHARGÉ sur l'Era
-- aussi. Depuis le 2026-09-20 il n'y a plus qu'UN SEUL `.toc` (16001) et cette exposition a disparu
-- — la garde RESTE quand même : le socle teste `Craft.MAINLINE_API` en PREMIER, et se poser sur un
-- client Classic basculerait tout le produit sur une API qui n'y existe pas. On ne s'enregistre que
-- sur un vrai client MAINLINE, et on exige en plus l'énumérateur moderne (ceinture et bretelles :
-- `C_TradeSkillUI` existe aussi en Era, ce n'est donc PAS un discriminant valable).
local IS_MAINLINE = Api and Api.IS_MAINLINE
local HAS_MODERN  = C_TradeSkillUI
    and (C_TradeSkillUI.GetFilteredRecipeIDs or C_TradeSkillUI.GetAllRecipeIDs) ~= nil
if not (IS_MAINLINE and HAS_MODERN) then return end

-- ---------------------------------------------------------------- cache de la liste

-- `GetFilteredRecipeIDs` rend les recettes de la ligne ouverte — apprises ET non apprises (cf.
-- `getLearned`) — dans l'ordre d'affichage.
-- On la relit à chaque `getNum()` (début de passe de lecture) et on sert le reste depuis le cache :
-- sans ça, `ReadRecipes` la rappellerait à chaque ligne, soit du O(n²) pour rien.
local ids, infoCache, schemCache = {}, {}, {}

-- La FILTRÉE d'abord, à dessein : cette liste alimente une VUE qui reproduit ce que la fenêtre
-- native affiche (recherche et catégories du joueur comprises). La lib CraftLink, qui CAPTE le
-- registre, prend l'inverse (`GetAllRecipeIDs` d'abord) : une capture ne doit pas dépendre d'un filtre.
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

-- ---------------------------------------------------------------- SCHÉMA de fabrication PAR SON SORT

-- Ce qu'une recette COÛTE et ce qu'elle PRODUIT, lu sur le client : `GetRecipeSchematic` rend
-- l'objet produit, la taille du lot et les emplacements de réactifs, pour tout sort que le client
-- connaît. C'est la même source que le panneau de détail de Blizzard — donc la plus à jour qui
-- soit, là où nos données générées ont 357 recettes SANS objet produit sur Camelot (Wowhead se
-- remplit encore par observation). Les deux ne se remplacent pas : le client fait foi, le
-- catalogue reste le repli (cf. COC.LazyGold, qui arbitre champ par champ).
--
-- ⚠️ Rend une TABLE, jamais une suite de valeurs. `local a, b = X and X:f()` n'en rendrait qu'UNE
-- (piège payé quatre fois dans ce dépôt), et ce schéma a justement trois champs à porter.
--
-- Les emplacements MODIFIANTS / de FINITION (qualités Retail) ne sont pas un coût de fabrication :
-- ils sont facultatifs. Forever ne s'en sert pas (`supportsQualities` false partout, mesuré
-- 2026-09-18), mais on filtre quand même — le jour où ça change, le coût ne se mettra pas à
-- compter des réactifs que personne ne pose.
-- Le repli `or 1` n'est pas une supposition : `Enum.CraftingReagentType` est déclaré dans le source
-- du client lui-même (`Blizzard_APIDocumentationGenerated/ProfessionConstantsDocumentation.lua`,
-- worktree `wow-ui-source-forever` épinglé sur la build live) avec Modifying=0, **Basic=1**,
-- Finishing=2, Automatic=3. On lit la table quand elle est là, et le repli porte la MÊME valeur —
-- pas un nombre choisi parce qu'il tombait bien.
local BASIC_REAGENT = (Enum and Enum.CraftingReagentType and Enum.CraftingReagentType.Basic) or 1

function Craft:MainlineRecipeCraft(spellID)
    local get = C_TradeSkillUI and C_TradeSkillUI.GetRecipeSchematic
    if not (spellID and get) then return nil end
    local ok, s = pcall(get, spellID, false)
    -- Même exigence que MainlineRecipeFacts : on veut une réponse SUR CE SORT-LÀ, pas la fiche
    -- résiduelle d'un autre (un id hors catalogue du client rend nil ou parle d'autre chose).
    if not (ok and type(s) == "table" and s.recipeID == spellID) then return nil end
    local reagents = {}
    for _, slot in ipairs(s.reagentSlotSchematics or {}) do
        local kind = slot.reagentType
        local itemID = (kind == nil or kind == BASIC_REAGENT) and reagentItemID(slot) or nil
        if itemID then reagents[#reagents + 1] = { itemID, slot.quantityRequired or 1 } end
    end
    -- `quantityMin` et non la moyenne min/max : sur un lot variable, la borne basse est la seule
    -- qu'on soit sûr d'obtenir. Un profit annoncé plus bas que le réel se corrige tout seul à la
    -- première fabrication ; l'inverse fait fabriquer à perte.
    return { productID = s.outputItemID, numMade = s.quantityMin or 1,
             numMadeMax = s.quantityMax or s.quantityMin or 1, reagents = reagents }
end
