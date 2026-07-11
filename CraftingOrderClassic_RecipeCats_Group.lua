-- CraftingOrderClassic_RecipeCats_Group.lua — REGROUPEMENT partagé : transforme une liste plate
-- d'entrées (recettes, plans, ressources…) en liste d'AFFICHAGE à deux niveaux :
--
--     Section (COC.SectionOf)  >  Sous-catégorie (COC.RecipeCats)  >  les objets, triés
--
-- Écrit une fois ici parce que QUATRE listes en ont besoin et qu'elles n'ont pas la même structure
-- de ligne : vue métier (recettes de l'API), onglet Commande (plans du catalogue), Mes artisans
-- (recettes connues), onglet Récolte (ressources). Chacune passe juste un accesseur d'itemID ; le
-- rendu des lignes reste chez elle.
--
-- DEUX POINTS NON ÉVIDENTS :
--  * un objet peut appartenir à PLUSIEURS sous-catégories (une potion de rajeunissement rend vie ET
--    mana). On émet donc une VUE par appartenance — la même entrée apparaît sous deux en-têtes. Les
--    vues héritent de l'entrée d'origine (__index), donc le code de rendu existant continue de lire
--    ses champs habituels (`e`, `name`, `index`, `ready`…) sans rien changer ;
--  * un en-tête REPLIÉ reste affiché mais masque son contenu. L'état de repliage est fourni par
--    l'appelant (nil = tout déplié — c'est ce qu'on veut pendant une recherche, sinon un résultat
--    pourrait rester invisible sous un en-tête fermé).

local COC = CraftingOrderClassic
local RC  = COC.RecipeCats

-- Clés d'état de repliage : uniques par (section) et par (section, sous-catégorie).
function RC.KeySection(sec) return "S\1" .. tostring(sec) end
function RC.KeySub(sec, sub) return "B\1" .. tostring(sec) .. "\1" .. tostring(sub) end

-- Une VUE = l'entrée d'origine + son classement. Une entrée par sous-catégorie d'appartenance.
local function viewsOf(profKey, entries, getItemID)
    local out = {}
    for _, entry in ipairs(entries) do
        local itemID = getItemID(entry)
        local sec, secOrder = COC.SectionOf(itemID)
        local subs = RC:HasCategories(profKey) and RC:SubsOf(profKey, itemID) or nil
        if subs then
            for _, s in ipairs(subs) do
                out[#out + 1] = setmetatable(
                    { _sec = sec, _secOrder = secOrder, _sub = s.sub, _subOrder = s.order, _tier = s.tier },
                    { __index = entry })
            end
        else   -- métier sans table déclarée → affichage à plat d'avant, inchangé
            out[#out + 1] = setmetatable({ _sec = sec, _secOrder = secOrder, _subOrder = 0, _tier = 0 },
                                         { __index = entry })
        end
    end
    return out
end

-- Tri : section, sous-catégorie, puis critère prioritaire de l'appelant (ex. « prêt à fabriquer »),
-- puis NIVEAU DÉCROISSANT (la version majeure d'une potion passe devant la mineure), puis nom.
local function sortViews(views, opts)
    local name, before = opts.name, opts.before
    table.sort(views, function(a, b)
        if a._secOrder ~= b._secOrder then return a._secOrder < b._secOrder end
        if a._sec      ~= b._sec      then return a._sec      < b._sec      end
        if a._subOrder ~= b._subOrder then return a._subOrder < b._subOrder end
        if before then
            local r = before(a, b)
            if r ~= nil then return r end
        end
        if a._tier ~= b._tier then return a._tier > b._tier end
        return (name and name(a) or "") < (name and name(b) or "")
    end)
end

-- Aplatit les vues triées en insérant les en-têtes. Un en-tête porte `name` ET `label` : les quatre
-- listes n'utilisent pas le même champ pour leur texte, autant les servir toutes les deux.
local function flatten(views, collapsed)
    local col, counts = collapsed or {}, {}
    for _, v in ipairs(views) do
        local ks = RC.KeySection(v._sec); counts[ks] = (counts[ks] or 0) + 1
        if v._sub then local kb = RC.KeySub(v._sec, v._sub); counts[kb] = (counts[kb] or 0) + 1 end
    end
    local out, lastSec, lastSub = {}, nil, nil
    for _, v in ipairs(views) do
        local ks = RC.KeySection(v._sec)
        if v._sec ~= lastSec then
            out[#out + 1] = { isHeader = true, depth = 1, name = v._sec, label = v._sec,
                              ckey = ks, count = counts[ks] }
            lastSec, lastSub = v._sec, nil
        end
        if not col[ks] then
            local kb = v._sub and RC.KeySub(v._sec, v._sub)
            if kb and v._sub ~= lastSub then
                out[#out + 1] = { isHeader = true, depth = 2, name = v._sub, label = v._sub,
                                  ckey = kb, count = counts[kb] }
                lastSub = v._sub
            end
            if not (kb and col[kb]) then out[#out + 1] = v end
        end
    end
    return out
end

-- Point d'entrée unique.
--   opts.itemID    (obligatoire) entrée → itemID de l'objet classé
--   opts.name      (optionnel)   entrée → nom, pour le départage alphabétique
--   opts.before    (optionnel)   comparateur prioritaire ; renvoie nil s'il ne tranche pas
--   opts.collapsed (optionnel)   table d'état de repliage ; nil = tout déplié
function RC:BuildDisplay(profKey, entries, opts)
    if not (entries and opts and opts.itemID) then return {} end
    local views = viewsOf(profKey, entries, opts.itemID)
    sortViews(views, opts)
    return flatten(views, opts.collapsed)
end
