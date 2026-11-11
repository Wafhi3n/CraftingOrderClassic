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
--   W:Held()            → { { entry, inBag, onQuest, done, required, have, need }, … } : les writs
--                         que je porte, un par writ ; les quantités seulement pour une quête acceptée
--   W:WantedItems()     → objet demandé → son writ porté (Held), pas encore rempli
--   W:ForItem(itemID)   → { entrée, … } dont la quête demande cet objet | nil
--   W:ProfitMark(itemID, wanted) → { entry, held, need, seen } | nil : la marque de la vue Profit
--   W:ItemMark(itemID)  → la même marque, sans `wanted` : ne lit que les writs de cet objet
--   W:Seen(questID)     → ce que COC a VU de cette quête en jeu (db.writsSeen) | nil
--   W:Learn(questID)    → relève quantité et or d'une quête de writ au journal ; LearnHeld() : toutes
--   W:Paid(questID, money) → relève l'or VERSÉ au rendu de la quête
-- `items` a deux objets pour un nom qui en désigne deux (« Golden Scale Gauntlets ») : la quête
-- acceptée dit lequel. Le métier n'est pas stocké : un objet peut en avoir deux (Gordok Ogre Suit),
-- il se lit dans CraftLink.
--
-- Aucune UI ici, aucun événement, aucune ligne de chat : ce module rend des données, à la demande.
-- Seul `Learn` écrit (dans db.writsSeen) ; le QUAND est dans _Writs_Seen.lua.

local COC = CraftingOrderClassic
local W = {}
COC.Writs = W

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

-- Réputation de la quête selon le palier (1 Journeyman, 2 Expert, 3 Artisan), lue sur Wowhead : les
-- 150 quêtes la respectent, le générateur échoue si l'une s'en écarte.
W.REP = { 75, 125, 200 }

local byWrit, byQuest, byItem = {}, {}, {}

function W:Load(data)
    for writ, row in pairs(data) do
        local items = {}
        for i = 3, #row do items[#items + 1] = row[i] end
        local e = { writ = writ, quest = row[1], tier = row[2], rep = self.REP[row[2]], items = items }
        byWrit[writ], byQuest[row[1]] = e, e
        for _, it in ipairs(items) do
            byItem[it] = byItem[it] or {}
            table.insert(byItem[it], e)
        end
    end
    -- Ordre STABLE (par writ) : `pairs` n'en a pas, et la marque prend le premier writ d'un objet.
    for _, list in pairs(byItem) do
        table.sort(list, function(a, b) return a.writ < b.writ end)
    end
end

function W:Info(writItemID) return byWrit[tonumber(writItemID) or -1] end
function W:ForQuest(questID) return byQuest[tonumber(questID) or -1] end
function W:All() return byWrit end
function W:ForItem(itemID) return byItem[tonumber(itemID) or -1] end

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

-- L'objectif « objet » d'une quête de writ : combien il en faut, combien le jeu en compte déjà (il
-- compte ceux des sacs). La quantité VARIE d'un writ à l'autre — 200 « Crafted Solid Shot », vu en jeu
-- le 2026-10-17 — et aucune page Wowhead lue ne la donne : seul le journal la connaît, une fois la
-- quête acceptée. Rend (demandé, déjà compté), ou nil si le journal ne dit rien.
function W:Objective(questID)
    local objs, pick = COC.Api.GetQuestObjectives(questID), nil
    for _, o in ipairs(objs) do
        if o.type == "item" then pick = o; break end
    end
    pick = pick or objs[1]
    if not (pick and pick.numRequired) then return nil end
    return pick.numRequired, pick.numFulfilled or 0
end

-- Un writ en sac (pas encore ouvert) ou sa quête acceptée : UNE entrée par writ, quel que soit le
-- chemin par lequel on le voit (cas « writ en sac + même quête en cours »). Quête abandonnée ou
-- journalières remises à zéro : le writ disparaît de lui-même, rien n'est retenu entre deux appels.
-- Quête acceptée : `required` / `have` / `need` (ce qui manque) viennent de son objectif, et `done`
-- dit qu'il ne manque plus rien. Writ pas encore ouvert : quantité INCONNUE (champs nil), jamais
-- devinée, et `done` reste faux — un objet en sac ne prouve rien tant qu'on ignore combien il en faut.
local function heldOf(self, e)
    local A = COC.Api
    local bag, quest = inBags(e.writ), A.IsOnQuest(e.quest)
    if not (bag or quest) then return nil end
    local h = { entry = e, inBag = bag, onQuest = quest, done = false }
    if quest then
        local req, have = self:Objective(e.quest)
        h.required, h.have = req, have
        h.need = req and math.max(0, req - have) or nil
        h.done = A.IsQuestComplete(e.quest) or h.need == 0
    end
    return h
end

function W:Held()
    local out = {}
    for _, e in pairs(byWrit) do
        local h = heldOf(self, e)
        if h then out[#out + 1] = h end
    end
    table.sort(out, function(a, b) return a.entry.writ < b.entry.writ end)
    return out
end

-- Les objets à commander → leur writ porté (`Held`), pour lire `entry` et `need`. Une clé par
-- objet : deux writs pour un même objet font UNE marque.
function W:WantedItems()
    local out = {}
    for _, h in ipairs(self:Held()) do
        if not h.done then
            for _, it in ipairs(h.entry.items) do out[it] = h end
        end
    end
    return out
end

-- =========================================================================
-- La marque de la vue Profit (D7)
-- =========================================================================
-- L'objet que fabrique une recette est-il demandé par un writ ? `wanted` = le résultat de
-- `WantedItems()`, que l'appelant lit UNE fois par remplissage (le relire par ligne refait 150
-- lectures de sac et de journal à chaque ligne). Un writ que je PORTE passe avant les autres : c'est
-- celui qui me concerne. `need` = ce qui me manque, nil pour un writ pas ouvert (inconnu, D6).
function W:ProfitMark(itemID, wanted)
    local list = self:ForItem(itemID)
    if not list then return nil end
    local h = wanted and wanted[tonumber(itemID)]
    local e = h and h.entry or list[1]
    return { entry = e, held = h ~= nil, need = h and h.need or nil, seen = self:Seen(e.quest) }
end

-- La même marque, pour l'infobulle d'un objet (D10) : elle se refait à CHAQUE survol, d'où une
-- lecture des seuls writs de cet objet (un, deux pour un homonyme), jamais des 150 de `WantedItems()`.
-- Même règle : un writ dont la quête est remplie ne compte plus comme porté.
function W:ItemMark(itemID)
    local list = self:ForItem(itemID)
    if not list then return nil end
    local wanted = {}
    for _, e in ipairs(list) do
        local h = heldOf(self, e)
        if h and not h.done then
            for _, it in ipairs(e.items) do wanted[it] = h end
        end
    end
    return self:ProfitMark(itemID, wanted)
end

-- =========================================================================
-- Ce que COC a VU de chaque writ en jeu (D8)
-- =========================================================================
-- Ni la quantité ni l'or ne s'écrivent dans une page lue : seul le journal les donne, quête
-- acceptée. On les retient par quête, PAR COMPTE (db.writsSeen, créé à l'usage). Ce sont des
-- RELEVÉS : rien ne prouve qu'une quête demande toujours la même quantité, d'où le plus petit et le
-- plus grand gardés à côté du dernier ; et l'or d'une quête vanilla change souvent avec le niveau
-- (au niveau maximum, de l'or remplace l'expérience), d'où le niveau du personnage avec lui.
function W:Seen(questID)
    local t = COC.db and COC.db.writsSeen
    return t and t[tonumber(questID) or -1] or nil
end

function W:Learn(questID)
    local e = self:ForQuest(questID)
    local db = COC.db
    if not (e and db) then return nil end
    local req = self:Objective(e.quest)
    -- Journal pas encore prêt (objectif vide juste après l'acceptation) : rien, on relira.
    if not (req and req > 0) then return nil end
    db.writsSeen = db.writsSeen or {}
    local r = db.writsSeen[e.quest] or {}
    r.n = req
    r.nMin = math.min(r.nMin or req, req)
    r.nMax = math.max(r.nMax or req, req)
    local A = COC.Api
    local money = A.GetQuestRewardMoney and A.GetQuestRewardMoney(e.quest)
    -- Un 0 relu plus tard (récompense pas encore chargée) n'efface pas un montant déjà vu.
    if money and (money > 0 or r.money == nil) then
        r.money, r.level = money, UnitLevel and UnitLevel("player") or nil
    end
    -- Un writ rend une Coin Pouch, pas d'or (relevé du 2026-11-11 : 0 annoncé). L'objet se retient ;
    -- une relecture sans lui (récompense pas encore chargée) ne l'efface pas.
    local item = A.GetQuestRewardItem and A.GetQuestRewardItem(e.quest)
    if item then r.rewardItem, r.rewardCount = item.id, item.n end
    r.at = time and time() or r.at
    db.writsSeen[e.quest] = r
    return r
end

-- L'or VERSÉ au rendu (`QUEST_TURNED_IN`, son `moneyReward`) : le seul chiffre qui fasse foi. Celui du
-- journal est une annonce, et au niveau maximum l'expérience d'une quête vanilla peut se payer en or
-- en plus. Le coût de la réputation (T7) lira celui-ci d'abord.
function W:Paid(questID, money)
    local e, db = self:ForQuest(questID), COC.db
    if not (e and db and type(money) == "number") then return nil end
    db.writsSeen = db.writsSeen or {}
    local r = db.writsSeen[e.quest] or {}
    r.paid, r.paidLevel = money, UnitLevel and UnitLevel("player") or nil
    r.at = time and time() or r.at
    db.writsSeen[e.quest] = r
    return r
end

-- Toutes les quêtes de writ au journal (connexion) : celles acceptées avant que COC ne les relève.
function W:LearnHeld()
    for _, h in ipairs(self:Held()) do
        if h.onQuest then self:Learn(h.entry.quest) end
    end
end
