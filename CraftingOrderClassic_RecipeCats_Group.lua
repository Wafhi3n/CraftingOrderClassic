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
-- `opts.section` (optionnel) permet à un appelant de classer une entrée SANS objet produit, que
-- COC.SectionOf ne peut pas voir (un enchantement est un SERVICE : pas d'itemID → « Autres/Divers »).
-- Il rend `sec, order, flat` ; `flat` = pas de sous-catégorie (l'entrée pend direct sous sa section).
local function viewsOf(profKey, entries, opts)
    local getItemID, getSection, getSub = opts.itemID, opts.section, opts.sub
    local out = {}
    for _, entry in ipairs(entries) do
        local itemID = getItemID(entry)
        local sec, secOrder, flat
        if getSection then sec, secOrder, flat = getSection(entry) end
        if not sec then sec, secOrder = COC.SectionOf(itemID) end
        secOrder = secOrder or 900   -- garde : un rang nil ferait planter le tri (comparaison avec nil)
        -- ORDRE DE PRIORITÉ, et il compte :
        --  1. la table DÉCLARÉE (jugement humain : « Potions de soin », « Flacons » — des familles
        --     qu'aucune lecture d'objet ne devinera jamais) ;
        --  2. le classement DÉRIVÉ de l'appelant (enchant, taille de gemme, stat d'un consommable),
        --     qui ne COMBLE que ce que la table ne dit pas ;
        --  3. « Divers » en dernier recours.
        -- L'inverse (dérivé d'abord) écraserait « Potions de soin » par un groupe de stats.
        local subs
        if not flat then
            if RC:HasCategories(profKey) then subs = RC:SubsOfStrict(profKey, itemID) end
            if not subs and getSub then
                local sub, subOrder, tier, lone = getSub(entry)
                if sub then
                    subs = { { sub = sub, order = subOrder or 0, tier = tier or 0, lone = lone } }
                end
            end
            if not subs and RC:HasCategories(profKey) then subs = RC:SubsOf(profKey, itemID) end
        end
        if subs then
            for _, s in ipairs(subs) do
                out[#out + 1] = setmetatable(
                    { _sec = sec, _secOrder = secOrder, _sub = s.sub, _subOrder = s.order,
                      _tier = s.tier, _lone = s.lone },
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
        -- Deux sous-catégories DISTINCTES peuvent partager un rang : « Endurance - Solide » et
        -- « Endurance - Audacieux » viennent de la même stat déclarée. Sans ce départage elles
        -- s'entrelaceraient au tri suivant (niveau, nom) et flatten ré-émettrait l'en-tête à chaque
        -- bascule. Le `or ""` couvre les entrées SANS sous-catégorie (comparer nil lèverait une erreur).
        local sa, sb = a._sub or "", b._sub or ""
        if sa ~= sb then return sa < sb end
        if before then
            local r = before(a, b)
            if r ~= nil then return r end
        end
        if a._tier ~= b._tier then return a._tier > b._tier end
        return (name and name(a) or "") < (name and name(b) or "")
    end)
end

-- Sections où le niveau « sous-catégorie » n'apporte RIEN : toutes leurs sous-catégories n'ont qu'UN
-- élément. Vécu sur les gemmes méta (14 tailles, 14 gemmes) : on obtenait 14 en-têtes qui ne
-- faisaient que répéter le premier mot de l'unique ligne en dessous — « Bracing » puis « Bracing
-- Earthstorm Diamond ». La section entière repasse donc à plat.
--
-- DEUX GARDES, sinon le remède serait pire que le mal :
--  * OPT-IN (`_lone`) : seul un fournisseur de sous-catégorie qui le demande est concerné. Ailleurs
--    un groupe d'un seul élément reste légitime — « Flacons (1) » en Alchimie nomme une famille, ce
--    n'est pas un préfixe du nom de l'objet ;
--  * décision par SECTION, jamais par groupe : aplatir un groupe isolé au milieu de groupes garnis
--    laisserait une ligne orpheline entre deux en-têtes, ce qui se lit comme un bug d'affichage.
local function loneSections(views, counts)
    local flat = {}
    for _, v in ipairs(views) do
        if v._sub then
            if not v._lone or counts[RC.KeySub(v._sec, v._sub)] > 1 then
                flat[v._sec] = false
            elseif flat[v._sec] == nil then
                flat[v._sec] = true
            end
        end
    end
    return flat
end

-- Aplatit les vues triées en insérant les en-têtes. Un en-tête porte `name` ET `label` : les quatre
-- listes n'utilisent pas le même champ pour leur texte, autant les servir toutes les deux.
local function flatten(views, collapsed)
    local col, counts = collapsed or {}, {}
    for _, v in ipairs(views) do
        local ks = RC.KeySection(v._sec); counts[ks] = (counts[ks] or 0) + 1
        if v._sub then local kb = RC.KeySub(v._sec, v._sub); counts[kb] = (counts[kb] or 0) + 1 end
    end
    local flatSec = loneSections(views, counts)
    local out, lastSec, lastSub = {}, nil, nil
    for _, v in ipairs(views) do
        local ks = RC.KeySection(v._sec)
        -- Section dont AUCUNE sous-catégorie ne regroupe : on la rend à plat (cf. loneSections).
        if v._sub and flatSec[v._sec] then v._sub = nil end
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
--   opts.section   (optionnel)   entrée → sec, order, flat : classe une entrée SANS itemID (enchants)
--   opts.sub       (optionnel)   entrée → sub, order, tier, lone : sous-catégorie fournie (idem),
--                                prioritaire sur RC:SubsOf ; nil → repli sur le classement par itemID.
--                                `lone` = « si cette sous-catégorie n'a qu'un élément, son en-tête ne
--                                vaut pas la ligne qu'il coûte » (cf. loneSections)
--   opts.name      (optionnel)   entrée → nom, pour le départage alphabétique
--   opts.before    (optionnel)   comparateur prioritaire ; renvoie nil s'il ne tranche pas
--   opts.collapsed (optionnel)   table d'état de repliage ; nil = tout déplié
function RC:BuildDisplay(profKey, entries, opts)
    if not (entries and opts and opts.itemID) then return {} end
    local views = viewsOf(profKey, entries, opts)
    sortViews(views, opts)
    return flatten(views, opts.collapsed)
end

-- Classement dérivé du SORT plutôt que de l'objet produit — à passer tel quel en `opts.section` /
-- `opts.sub`. Deux métiers en ont besoin, pour des raisons opposées :
--   * Enchantement : un enchant est un SERVICE (aucun objet), que COC.SectionOf rangerait en vrac
--     sous « Autres » → emplacement en section, stat de base en sous-catégorie ;
--   * Joaillerie : la gemme EST un objet et sa COULEUR fait déjà la section (COC.SectionOf la lit
--     sur l'objet) ; seule la TAILLE, invisible côté client, se dérive ici.
-- Écrit ICI et pas dans chaque vue : l'onglet Commande et la vue métier doivent classer À
-- L'IDENTIQUE, et un dispatch recopié des deux côtés finit toujours par diverger.
-- ⚠️ PAS de `X and X:f()` : `and` TRONQUE le multi-retour (cf. mémoire lua-and-truncates-multireturn).
function RC.SectionForSpell(spellID)
    if not (spellID and COC.Enchant) then return nil end
    return COC.Enchant:SectionFor(spellID)
end

-- Rang des groupes DÉRIVÉS d'une stat de consommable : après les groupes déclarés (qui portent leur
-- index de déclaration, 1..n) et avant « Divers » (999). Tous le même, donc c'est le LIBELLÉ qui les
-- ordonne entre eux — sortViews départage sur `_sub` à rang égal.
local CONSUMABLE_STAT_ORDER = 600
local CONSUMABLE_CLASS = 0   -- classID 0 = Consommable

function RC.SubForSpell(profKey, spellID, itemID)
    if COC.Enchant and spellID then
        local label, order, tier = COC.Enchant:StatFor(spellID)
        if label then return label, order, tier end   -- pas de `lone` : un enchant seul garde son en-tête
    end
    if COC.Gem and spellID then
        local label, order, tier, lone = COC.Gem:StatFor(spellID)
        if label then return label, order, tier, lone end
    end
    -- Consommables : un élixir n'a pas de stat d'OBJET, il applique un effet — mais c'est bien une
    -- stat qu'il donne, et c'est ainsi qu'on le cherche. Une seule stat en en-tête (le libellé sert
    -- de titre de groupe, pas de fiche technique). Restreint aux consommables : ailleurs, un niveau
    -- « par stat » doublonnerait le classement par emplacement, déjà plus parlant.
    if COC.Stats and itemID and GetItemInfoInstant
        and select(6, GetItemInfoInstant(itemID)) == CONSUMABLE_CLASS then
        local label = COC.Stats:LabelFor(itemID, 1)
        -- `Tier` = le rang de métier de la recette : c'est lui qui met l'élixir majeur devant le
        -- mineur DANS le groupe. Il exige le métier, d'où sa présence dans la signature.
        if label then return label, CONSUMABLE_STAT_ORDER, RC:Tier(profKey, itemID) end
    end
    return nil
end
