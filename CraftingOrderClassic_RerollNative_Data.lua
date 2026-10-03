-- CraftingOrderClassic_RerollNative_Data.lua — les DONNÉES de la vue reroll à l'allure de la fenêtre de
-- métier du jeu (spec docs/specs/vue-reroll-native.md, critères 1 à 3). Rien d'affiché ici : la fenêtre
-- (_RerollNative.lua) lit ces fonctions, les tests aussi.
--
-- Pourquoi un arbre fait par nous : le jeu rend `categoryID = 0` pour une recette que le perso connecté
-- ne connaît pas, ses catégories ne sont donc pas disponibles. On range avec le classement partagé
-- (COC.RecipeCats:BuildDisplay), celui des quatre autres listes, et on le replie en arbre pour la liste
-- de recettes du jeu (nœuds `categoryInfo` / `recipeInfo`).

local COC = CraftingOrderClassic
local RN  = {}
COC.RerollNative = RN

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

-- Les recettes CONNUES du reroll pour ce métier, lues dans db.knownRecipes["Prénom-Royaume"][métier] :
-- { spellID, index, itemID, name }, une par sort. Le nom vient du catalogue (le reroll est hors ligne) :
-- sort, sinon objet produit, sinon « spell:<id> » pour qu'une ligne ne soit jamais vide.
function RN.Entries(rerollKey, prof)
    local db, c = COC.db, CL()
    local part = db and db.knownRecipes and rerollKey and db.knownRecipes[rerollKey]
    local set = part and prof and part[prof]
    if not set then return {} end
    local out = {}
    for sid in pairs(set) do
        local itemID = c and c.RecipeProduct and c:RecipeProduct(prof, sid) or nil
        local name = (c and c.RecipeName and c:RecipeName(sid))
            or (itemID and c and c.ItemName and c:ItemName(itemID)) or ("spell:" .. sid)
        out[#out + 1] = { spellID = sid, index = sid, itemID = itemID, name = name }
    end
    return out
end

-- Recherche : le nom contient le texte, sans tenir compte de la casse (recherche littérale, pas un
-- motif Lua : « [ » ou « - » tapés par le joueur ne doivent rien casser). Texte vide = tout.
function RN.Filter(entries, text)
    if not text or text == "" then return entries end
    local needle, out = text:lower(), {}
    for _, e in ipairs(entries) do
        if e.name and e.name:lower():find(needle, 1, true) then out[#out + 1] = e end
    end
    return out
end

-- Rangement partagé (sections, sous-catégories, tri) → liste plate à en-têtes. Mêmes accesseurs que la
-- vue métier (_ProfWindow_Recipes) : un enchantement n'a pas d'objet, il se range par son sort.
local function display(prof, entries)
    local RC = COC.RecipeCats
    if not (RC and RC.BuildDisplay) then return nil end
    return RC:BuildDisplay(prof, entries, {
        itemID  = function(e) return e.itemID end,
        section = function(e) return RC.SectionForSpell and RC.SectionForSpell(e.spellID) end,
        sub     = function(e) return RC.SubForSpell and RC.SubForSpell(prof, e.spellID, e.itemID) end,
        name    = function(e) return e.name or "" end,
    })
end

-- Repli de la liste plate en ARBRE pour la liste du jeu. Un en-tête de niveau 1 ouvre une catégorie,
-- un en-tête de niveau 2 une sous-catégorie sous elle ; une recette pend sous le dernier ouvert.
-- Nœud catégorie : { categoryInfo = { name, categoryID }, children = {…} }.
-- Nœud recette   : { recipeInfo = { recipeID, name, learned = true }, entry = <entrée> }.
-- `learned = true` est voulu : le jeu rend false pour une recette du reroll, et la liste grise tout ce
-- qui n'est pas appris (décision de la spec).
function RN.Tree(prof, entries)
    local flat = display(prof, entries)
    local roots, sec, sub, nextID = {}, nil, nil, 0
    local function cat(name)
        nextID = nextID + 1
        return { categoryInfo = { name = name, categoryID = nextID }, children = {} }
    end
    local function leaf(e)
        return { recipeInfo = { recipeID = e.spellID, name = e.name, learned = true }, entry = e }
    end
    if not flat then   -- pas de classement chargé : une seule catégorie, triée par nom
        local sorted = { unpack(entries) }
        table.sort(sorted, function(a, b) return (a.name or "") < (b.name or "") end)
        local Skin = COC.UI and COC.UI.Skin
        local only = cat((Skin and Skin.ProfLabel and Skin.ProfLabel(prof)) or prof)
        for _, e in ipairs(sorted) do only.children[#only.children + 1] = leaf(e) end
        return #sorted > 0 and { only } or {}
    end
    for _, row in ipairs(flat) do
        if row.isHeader and row.depth == 1 then
            sec, sub = cat(row.name), nil
            roots[#roots + 1] = sec
        elseif row.isHeader then
            sub = cat(row.name)
            local parent = sec or cat("?")
            if not sec then sec = parent; roots[#roots + 1] = parent end
            parent.children[#parent.children + 1] = sub
        else
            local parent = sub or sec
            if not parent then sec = cat("?"); roots[#roots + 1] = sec; parent = sec end
            parent.children[#parent.children + 1] = leaf(row)
        end
    end
    return roots
end

-- Le sort d'une commande, pour afficher sa recette : le sien, sinon celui que le catalogue relie à
-- l'objet (une commande d'objet voyage SANS son sort, vu en jeu le 2026-10-02).
function RN.SpellOfOrder(o)
    if not o then return nil end
    if o.spellID then return o.spellID end
    local c = CL()
    local i2s = c and c.ItemToSpell and o.profession and o.itemID and c:ItemToSpell(o.profession)
    return i2s and i2s[o.itemID] or nil
end
