-- CraftingOrderClassic_Journal.lua — MODÈLE « journal » : la liste unique, triée par PRIORITÉ, de ce
-- sur quoi le joueur peut agir maintenant. C'est la couche que consomment le suivi à l'écran
-- (_Tracker*.lua, façon suivi de quête) et, plus tard, le journal COC en parchemin où commandes et
-- quêtes cohabiteront par sections. UNE seule définition de « qu'est-ce qui est prioritaire » :
-- deux vues qui trient différemment finissent toujours par se contredire (vécu avec l'alerte
-- Entrantes et son jumeau côté vue métier).
--
-- Une ENTRÉE ressemble volontairement à une quête :
--   { key, section, title, tag, complete, objectives = { {itemID, have, need, done}, … },
--     itemID/spellID (tooltip), sort, order }
-- `objectives = nil` ≠ `objectives = {}` : nil = on ne CONNAÎT pas les réactifs (catalogue muet) et
-- on ne prétend donc pas que la commande est prête ; {} = il n'y a rien à rassembler (tout fourni
-- par l'acheteur) → réellement prête.
--
-- Les fournisseurs d'entrées s'ENREGISTRENT (Journal:AddProvider) : chaque palier ajoute le sien
-- sans toucher ce fichier. Aucune UI ici.

local COC     = CraftingOrderClassic
local Journal = {}
COC.Journal   = Journal

local Skin = COC.UI and COC.UI.Skin
local L    = COC.L

-- Sections, DANS L'ORDRE DE PRIORITÉ. Une commande prête à livrer passe devant la montée de métier :
-- c'est un engagement envers quelqu'un, la progression peut attendre trente secondes.
Journal.SECTION_ORDER = { "ready", "active", "progress", "mine" }
Journal.SECTION_RANK  = {}
for i, s in ipairs(Journal.SECTION_ORDER) do Journal.SECTION_RANK[s] = i end

-- Titre de chaque section — l'équivalent de « Hellfire Peninsula » du journal. Résolu ICI, à la
-- charge (les overlays de locale sont déjà en place) : les vues consomment un libellé prêt à peindre
-- et le vérificateur de locale voit bien des clés littérales (il scanne aussi les commentaires : ne
-- jamais y écrire un appel de locale en exemple, il serait compté comme une clé à traduire).
Journal.SECTION_TITLE = {
    ready    = L["Prêt à livrer"],
    active   = L["En cours"],
    progress = L["Progression"],
    mine     = L["Mes commandes"],
}

Journal.PROVIDERS = {}
-- fn(entries, ctx) ; ctx = { bagCount = f(itemID), now }. Ajouter des entrées à `entries`, rien d'autre.
function Journal:AddProvider(fn)
    if type(fn) == "function" then self.PROVIDERS[#self.PROVIDERS + 1] = fn end
end

-- ------------------------------------------------------------------
-- Aides communes
-- ------------------------------------------------------------------
local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end
local function me() return (UnitName and UnitName("player")) or "?" end

-- Même sémantique que le `actsFor` d'Orders (rerolls seulement si l'opt-in ALT est actif) : le suivi
-- ne doit pas afficher comme « à moi » une commande que le protocole me refuserait de livrer.
local function actsFor(name)
    if not name then return false end
    if name == me() then return true end
    return (COC.db and COC.db.altsEnabled and COC.IsMyChar and COC:IsMyChar(name)) or false
end

-- Nombre de CRAFTS que représente une commande. `byStack` compte en PILES (cf. Skin.QtyText) : une
-- « 1 pile (20) » demande vingt fois les réactifs. La lib n'expose pas numMade (combien un craft
-- produit) → 1 craft = 1 objet supposé, même approximation assumée que Route.addReagent.
local function craftCount(o)
    local n = math.max(1, tonumber(o.qty) or 1)
    if not o.byStack then return n end
    local sz = o.itemID and GetItemInfo and select(8, GetItemInfo(o.itemID))
    return n * ((sz and sz > 1) and sz or 1)
end

-- Réactifs déjà promis par l'acheteur → à ne pas faire farmer au crafteur. `provided` vaut une table
-- d'itemID côté local et une CSV côté fil (Orders_Codec) : on accepte les deux plutôt que de parier.
local function providedSet(o)
    local set, p = {}, o.provided
    if type(p) == "string" then
        for id in p:gmatch("%d+") do set[tonumber(id)] = true end
    elseif type(p) == "table" then
        for _, id in ipairs(p) do set[tonumber(id) or id] = true end
    end
    return set
end

-- Recette (profKey, spellID) derrière une commande, ou nil si le catalogue ne la connaît pas.
-- ⚠️ jamais `local a, b = X and X:f()` : `and` TRONQUE le multi-retour (piège maison).
local function recipeOf(o)
    local c = CL()
    if not (c and o) then return nil end
    local prof = o.profession
    if not prof and o.itemID and COC.Orders then prof = COC.Orders:ProfForItem(o.itemID) end
    if not prof then return nil end
    if o.spellID then return prof, o.spellID end
    local i2s = (o.itemID and c.ItemToSpell) and c:ItemToSpell(prof) or nil
    local sid = i2s and i2s[o.itemID]
    if not sid then return nil end
    return prof, sid
end

-- Exposé : le suivi en a besoin pour savoir QUELLE fenêtre de métier ouvrir au clic.
function Journal:RecipeOf(o) return recipeOf(o) end

-- ------------------------------------------------------------------
-- Objectifs (les « - Cursed Talisman : 12/12 » du journal)
-- ------------------------------------------------------------------
-- Rend (liste, nbFaits) ou nil si les réactifs sont inconnus. La liste PEUT être vide : tout est
-- fourni par l'acheteur, il n'y a rien à rassembler — c'est un succès, pas une absence de données.
function Journal:ObjectivesFor(o, ctx)
    local prof, sid = recipeOf(o)
    local c = CL()
    if not (prof and sid and c and c.RecipeReagents) then return nil end
    local reag = c:RecipeReagents(prof, sid)
    if not (reag and #reag > 0) then return nil end
    local given, out, done = providedSet(o), {}, 0
    local mult = craftCount(o)
    for _, rg in ipairs(reag) do
        local id, per = rg[1], (rg[2] or 1)
        if not given[id] then
            local need = per * mult
            local have = ctx.bagCount(id)
            local ok   = have >= need
            if ok then done = done + 1 end
            out[#out + 1] = { itemID = id, have = have, need = need, done = ok }
        end
    end
    return out, done
end

-- ------------------------------------------------------------------
-- Fournisseur du palier 1 : les commandes que J'AI acceptées
-- ------------------------------------------------------------------
-- Deux sections selon les sacs : tous les réactifs réunis → « Prêt à livrer » (l'équivalent du
-- « (Terminé) » vert du journal), sinon « En cours ». Le tri interne est posé ici (`sort`) :
--   · ready  → la plus ANCIENNE d'abord (elle attend depuis le plus longtemps) ;
--   · active → la plus AVANCÉE d'abord (le dernier réactif manquant est le plus motivant).
-- Titre et remarques d'une commande selon qu'elle porte un NARRATIF (titre/description libres de son
-- auteur — cf. Orders_Narrative.lua). Avec un titre, la commande se lit comme une quête : le nom
-- donné par l'auteur en tête, et l'objet demandé rappelé juste dessous — jamais escamoté, c'est LUI
-- qu'il faut crafter. Rend (titre affichable, notes ou nil).
local function narrative(o, itemLabel)
    local notes
    if o.title and o.title ~= "" then notes = { "|cFF9D9D9D— " .. itemLabel .. "|r" } end
    if o.text and o.text ~= "" then
        notes = notes or {}
        notes[#notes + 1] = "|cFFB0A080\"" .. o.text .. "\"|r"
    end
    return (o.title ~= "" and o.title) or itemLabel, notes
end

local function acceptedProvider(entries, ctx)
    local O = COC.Orders
    if not (O and O.All) then return end
    for _, o in ipairs(O:All() or {}) do
        if o.status == "accepted" and actsFor(o.acceptedBy) then
            local objs, done = Journal:ObjectivesFor(o, ctx)
            local total    = objs and #objs or 0
            local complete = (objs ~= nil) and (done == total)
            local ratio    = (total > 0) and (done / total) or 1
            local label    = O:OrderName(o) .. ((Skin and Skin.QtySuffix) and Skin.QtySuffix(o) or "")
            local title, notes = narrative(o, label)
            entries[#entries + 1] = {
                key       = "ord:" .. tostring(o.id),
                section   = complete and "ready" or "active",
                title     = title,
                notes     = notes,
                sub       = o.buyer,
                complete  = complete,
                objectives = objs,
                itemID    = o.itemID, spellID = o.spellID,
                prof      = recipeOf(o),   -- 1re valeur = profKey (le sid ne sert pas ici)
                order     = o,
                sort      = complete and (o.ts or 0) or -ratio,
            }
        end
    end
end
Journal:AddProvider(acceptedProvider)

-- ------------------------------------------------------------------
-- Fournisseur : MES commandes (celles que j'ai postées)
-- ------------------------------------------------------------------
-- Côté ACHETEUR il n'y a rien à rassembler → `objectives = {}` : une liste VIDE, surtout pas `nil`
-- (qui afficherait « réactifs inconnus »). « Remise » est le seul état réellement actionnable — il
-- reste à confirmer la réception — donc il monte en tête de section et porte la coche, comme une
-- quête à rendre. Les états terminaux (livrée/annulée/refusée) n'ont pas leur place à l'écran.
local MINE_RANK = { delivered = 1, accepted = 2, open = 3 }

local function mineProvider(entries)
    local O = COC.Orders
    if not (O and O.All) then return end
    for _, o in ipairs(O:All() or {}) do
        local rank = MINE_RANK[o.status or ""]
        if rank and actsFor(o.buyer) then
            local status = (Skin and Skin.StatusInfo) and Skin.StatusInfo(o.status) or nil
            local label  = O:OrderName(o) .. ((Skin and Skin.QtySuffix) and Skin.QtySuffix(o) or "")
            local title, notes = narrative(o, label)
            entries[#entries + 1] = {
                key      = "mine:" .. tostring(o.id),
                section  = "mine",
                title    = title,
                notes    = notes,
                sub      = (o.status == "accepted" and o.acceptedBy) or status or o.status,
                complete = (o.status == "delivered"),
                objectives = {},
                itemID   = o.itemID, spellID = o.spellID,
                prof     = recipeOf(o),
                order    = o,
                -- État d'abord ; à état égal, la plus ANCIENNE en tête (elle attend depuis le plus
                -- longtemps). Le ts divisé reste un départage, il ne peut pas franchir un rang.
                sort     = rank + (o.ts or 0) / 1e12,
            }
        end
    end
end
Journal:AddProvider(mineProvider)

-- ------------------------------------------------------------------
-- Assemblage
-- ------------------------------------------------------------------
-- Tri final : section (priorité), puis `sort` interne, puis clé (stable — deux entrées à égalité ne
-- doivent pas permuter d'un refresh à l'autre, ça fait « clignoter » la liste sous les yeux).
local function byPriority(a, b)
    local ra = Journal.SECTION_RANK[a.section] or 99
    local rb = Journal.SECTION_RANK[b.section] or 99
    if ra ~= rb then return ra < rb end
    local sa, sb = a.sort or 0, b.sort or 0
    if sa ~= sb then return sa < sb end
    return tostring(a.key) < tostring(b.key)
end

-- La liste complète, triée. `GetItemCount` est mémoïsé le temps de CET appel : un même réactif
-- (Étoffe de lin…) revient dans plusieurs commandes et le suivi se recalcule à chaque BAG_UPDATE.
function Journal:Entries()
    local cache = {}
    local ctx = {
        now = time and time() or 0,
        bagCount = function(id)
            local v = cache[id]
            if v == nil then v = (GetItemCount and GetItemCount(id, false)) or 0; cache[id] = v end
            return v
        end,
    }
    local entries = {}
    for _, fn in ipairs(self.PROVIDERS) do
        local ok, err = pcall(fn, entries, ctx)
        -- Un fournisseur qui explose (données de lib absentes sur une saveur…) ne doit pas
        -- emporter tout le suivi : on le saute et on trace.
        if not ok and COC.Trace then COC.Trace:Log("journal", "provider error: " .. tostring(err)) end
    end
    table.sort(entries, byPriority)
    return entries
end

-- Regroupement prêt à peindre : { { section, title, entries = {…} }, … } dans l'ordre de priorité.
-- `max` (optionnel) borne le nombre total d'ENTRÉES rendues (le suivi à l'écran a une hauteur finie ;
-- le journal, lui, appellera sans borne). Rend aussi le nombre d'entrées écartées par la borne.
function Journal:Grouped(max)
    local entries, groups, index, kept = self:Entries(), {}, {}, 0
    for _, e in ipairs(entries) do
        if max and kept >= max then break end
        local g = index[e.section]
        if not g then
            g = { section = e.section, title = self.SECTION_TITLE[e.section] or e.section, entries = {} }
            index[e.section] = g; groups[#groups + 1] = g
        end
        g.entries[#g.entries + 1] = e
        kept = kept + 1
    end
    return groups, #entries - kept
end
