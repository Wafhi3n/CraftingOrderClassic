-- CraftingOrderClassic_Writs.lua — les Craftsman's Writ de WoW: Forever (réputation Azeroth
-- Commerce Authority) : quel writ lance quelle quête, quel objet elle demande, qui sait le faire, et
-- quels writs je porte.
--
-- Un writ est une commande d'artisan passée par un PNJ : la quête demande un objet fabriqué, tiré
-- parmi 150 sur cinq métiers SANS tenir compte des métiers du joueur, et un objet acheté ou fabriqué
-- par un autre est accepté (vu en jeu le 2026-10-16). D'où l'idée de COC : faire de ce writ une vraie
-- commande. Spec : docs/specs/writs-aca.md.
--
-- Tout passe par les IDENTIFIANTS (writ, quête, objet, recette), jamais par les noms : ils sont
-- traduits. La table vit dans CraftingOrderClassic_Writs_Data.lua, générée par tools/gen_writs.lua.
--
-- CONTRAT : les entrées rendues sont PARTAGÉES — à lire, jamais à modifier.
--   W:Info(writItemID)  → { writ, quest, tier, rep, items = { objet [, homonyme] } } | nil
--   W:ForQuest(questID) → la même entrée, retrouvée par sa quête | nil
--   W:All()             → writItemID → entrée, pour parcourir
--   W:WhoCanMake(entry) → { recipes, me, alts, crafters, online } | nil (objet inconnu de CraftLink)
--   W:Held()            → { { entry, inBag, onQuest, done }, … } : les writs que je porte, un par writ
--   W:WantedItems()     → objet demandé → entrée, pour les writs portés et pas encore remplis
-- `items` a deux objets pour un nom qui en désigne deux (« Golden Scale Gauntlets ») : la quête
-- acceptée dit lequel. Le métier n'est pas stocké : un objet peut en avoir deux (Gordok Ogre Suit),
-- il se lit dans CraftLink.
--
-- Aucune UI ici, aucun événement, aucune ligne de chat : ce module rend des données, à la demande.

local COC = CraftingOrderClassic
local W = {}
COC.Writs = W

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

-- Réputation de la quête selon le palier (1 Journeyman, 2 Expert, 3 Artisan), lue sur Wowhead : les
-- 150 quêtes la respectent, le générateur échoue si l'une s'en écarte.
W.REP = { 75, 125, 200 }

local byWrit, byQuest = {}, {}

function W:Load(data)
    for writ, row in pairs(data) do
        local items = {}
        for i = 3, #row do items[#items + 1] = row[i] end
        local e = { writ = writ, quest = row[1], tier = row[2], rep = self.REP[row[2]], items = items }
        byWrit[writ], byQuest[row[1]] = e, e
    end
end

function W:Info(writItemID) return byWrit[tonumber(writItemID) or -1] end
function W:ForQuest(questID) return byQuest[tonumber(questID) or -1] end
function W:All() return byWrit end

-- =========================================================================
-- Qui sait le faire
-- =========================================================================
-- Les recettes qui produisent les objets d'une entrée : { item, prof, spell } par couple trouvé dans
-- CraftLink. Un objet de deux métiers donne deux lignes ; un objet inconnu, aucune.
local function recipesOf(c, items)
    local out = {}
    for _, itemID in ipairs(items) do
        for prof in pairs(c.professions or {}) do
            local i2s = c:ItemToSpell(prof)
            local sid = i2s and i2s[itemID]
            if sid then out[#out + 1] = { item = itemID, prof = prof, spell = sid } end
        end
    end
    return out
end

-- Mes rerolls (perso courant exclu : il est jugé en direct par CraftLink) qui connaissent une des
-- recettes. Lit l'agrégat local de « Mes artisans » : aucun réseau, marche même /co alts off.
local function altsKnowing(recs)
    local D, cur = COC.Directory, UnitName and UnitName("player")
    local mine = (D and D.AggregateMyProfs and D:AggregateMyProfs()) or {}
    local seen, out = {}, {}
    for _, p in ipairs(mine) do
        for _, r in ipairs(recs) do
            if p.profKey == r.prof then
                for _, ch in ipairs(p.chars or {}) do
                    if ch.name ~= cur and not seen[ch.name] and ch.known and ch.known[r.spell] then
                        seen[ch.name] = true; out[#out + 1] = ch.name
                    end
                end
            end
        end
    end
    table.sort(out)
    return out
end

-- Les artisans de l'annuaire (cache, jamais le réseau) qui connaissent une des recettes, sans mes
-- propres persos (déjà comptés plus haut), un joueur une seule fois, en ligne d'abord.
local function crafters(recs)
    local D = COC.Directory
    local seen, out, online = {}, {}, 0
    for _, r in ipairs(recs) do
        for _, w in ipairs((D and D.WhoCanCraft and D:WhoCanCraft(r.prof, r.spell)) or {}) do
            if not seen[w.player] and not (COC.IsMyChar and COC:IsMyChar(w.player)) then
                seen[w.player] = true
                out[#out + 1] = w
                if w.online then online = online + 1 end
            end
        end
    end
    table.sort(out, function(a, b)
        if a.online ~= b.online then return a.online end
        return a.player < b.player
    end)
    return out, online
end

-- Du plus proche au plus lointain : moi, mes rerolls, l'annuaire. « Personne de connu » = me faux,
-- alts et crafters vides. nil = aucun objet de l'entrée n'est connu de CraftLink : rien à dire.
function W:WhoCanMake(entry)
    local c = CL()
    if not (entry and c) then return nil end
    local recs = recipesOf(c, entry.items or {})
    if #recs == 0 then return nil end
    local me = false
    for _, r in ipairs(recs) do
        if c:IKnowRecipeBySpell(r.prof, r.spell) then me = true end
    end
    local list, online = crafters(recs)
    return { recipes = recs, me = me, alts = altsKnowing(recs), crafters = list, online = online }
end

-- =========================================================================
-- Les writs que je porte
-- =========================================================================
local function inBags(itemID) return (COC.Api.GetItemCount(itemID, false) or 0) > 0 end

-- Un writ en sac (pas encore ouvert) ou sa quête acceptée : UNE entrée par writ, quel que soit le
-- chemin par lequel on le voit (cas « writ en sac + même quête en cours »). Quête abandonnée ou
-- journalières remises à zéro : le writ disparaît de lui-même, rien n'est retenu entre deux appels.
-- `done` = la quête est remplie, ou l'objet demandé est déjà dans mes sacs : plus rien à commander.
function W:Held()
    local A, out = COC.Api, {}
    for writ, e in pairs(byWrit) do
        local bag, quest = inBags(writ), A.IsOnQuest(e.quest)
        if bag or quest then
            local done = quest and A.IsQuestComplete(e.quest) or false
            for _, it in ipairs(e.items) do
                if not done and inBags(it) then done = true end
            end
            out[#out + 1] = { entry = e, inBag = bag, onQuest = quest, done = done }
        end
    end
    table.sort(out, function(a, b) return a.entry.writ < b.entry.writ end)
    return out
end

-- Les objets à commander : une clé par objet, donc deux writs pour un même objet font UNE marque.
function W:WantedItems()
    local out = {}
    for _, h in ipairs(self:Held()) do
        if not h.done then
            for _, it in ipairs(h.entry.items) do out[it] = h.entry end
        end
    end
    return out
end
