-- Crafting Order - Classic — Debug : mode solo pour "jouer" un réseau fictif.
--
-- Sans 2e client, on ne peut pas voir d'artisans ni d'ordres venant des autres. Ce module injecte
-- un faux roster (artisans avec métiers + niveaux de skill + recettes connues réelles encodées) et
-- de fausses commandes, dans le MÊME cache que le réseau (Directory.roster / online, COC.db.orders),
-- pour tester visuellement les onglets Carnet / Commande / Récolte / Artisans en solo.
--
-- Tout est marqué `fake=true` → `/co solo off` purge proprement les faux sans toucher au réel.
--
-- Depuis le 2026-10-11 (décision du user), `/co debug` est le mode VERBEUX (l'ancien `/co verbose`,
-- gardé en alias) et le mode solo s'appelle `/co solo`. Règle `chat-output` : un mode qui rend
-- l'addon bavard ne s'allume que par le joueur, et `/co` (le statut) dit qu'il est allumé. Les deux
-- commandes sont à deux états : tapées seules, elles DISENT l'état ; seuls on/off le changent.

local COC   = CraftingOrderClassic
local Debug = {}
COC.Debug = Debug

local L = COC.L
local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end
local function me() return COC.Api.PlayerName() end   -- nom RÉSEAU (« Prénom Nom » sur Forever)

-- Faux artisans (mock proche du template Claude Design). Clés métier = clés internes EN du catalogue.
-- source = guild|friend|added|recent|confed (confed = co-guildes GreenWall, visibles en debug/SoD live).
Debug.fakeArtisans = {
    { name = "Grizzlyy", level = 60, online = true,  source = "guild",  skill = { Blacksmithing = {250,300}, Mining = {250,300} } },
    { name = "Koraud",   level = 60, online = true,  source = "guild",  skill = { Alchemy = {300,300}, Herbalism = {300,300} } },
    { name = "Monomo",   level = 60, online = true,  source = "guild",  skill = { Tailoring = {285,300}, Skinning = {300,300} } },
    { name = "Elara",    level = 58, online = false, source = "guild",  skill = { Enchanting = {240,300}, Tailoring = {300,300} } },
    { name = "Brewn",    level = 60, online = true,  source = "friend", skill = { Engineering = {300,300} } },
    { name = "Sylpha",   level = 60, online = true,  source = "friend", skill = { Leatherworking = {300,300}, Skinning = {300,300} } },
    { name = "Tandru",   level = 55, online = false, source = "friend", skill = { Cooking = {300,300}, Fishing = {225,300} } },
    { name = "Maelo",    level = 60, online = true,  source = "added",  skill = { Alchemy = {285,300} } },
    { name = "Norvyn",   level = 60, online = true,  source = "added",  skill = { Blacksmithing = {300,300} } },
    { name = "Pim",      level = 52, online = false, source = "added",  skill = { ["First Aid"] = {300,300}, Cooking = {180,300} } },
    -- « Croisés » : rencontrés via la présence, pas encore ajoutés.
    { name = "Tova",     level = 44, online = true,  source = "recent", skill = { Tailoring = {210,225} } },
    { name = "Borgrim",  level = 60, online = false, source = "recent", skill = { Mining = {300,300}, Blacksmithing = {290,300} } },
    -- « Confédération » : co-guildes GreenWall (onglet visible seulement si GreenWall actif / en debug).
    { name = "Faelin",   level = 60, online = true,  source = "confed", skill = { Enchanting = {300,300} } },
    { name = "Ordwin",   level = 58, online = false, source = "confed", skill = { Engineering = {290,300}, Mining = {300,300} } },
}

-- Fausses commandes (mock du template). itemID réels → noms localisés par GetItemInfo.
local function fakeOrders()
    return {
        { id = "DBG-1", buyer = "Brewn", kind = "item", itemID = 13510, qty = 2, profession = "Alchemy",
          price = "84po 16pa", status = "accepted", acceptedBy = "Koraud", recipient = "Koraud" },   -- Flacon des Titans
        { id = "DBG-2", buyer = me(), kind = "item", itemID = 12426, qty = 1, profession = "Blacksmithing",
          price = "15po", status = "open", recipient = "Tous" },                                      -- Bottes barbares en fer
        { id = "DBG-3", buyer = me(), kind = "item", itemID = 10620, qty = 40, profession = "Mining",
          price = "30po", status = "open", recipient = "Tous" },                                      -- Minerai de thorium
    }
end

-- Fausses « entrantes » (demandes captées dans /commerce ou /guilde par des joueurs SANS l'addon).
local function fakeInbound()
    return {
        { buyer = "Aldwin", itemID = 13510, qty = 1, price = "80po",       profession = "Alchemy",       source = "trade", canCraft = false },
        { buyer = "Mirena", itemID = 12426, qty = 2, price = "25po",       profession = "Blacksmithing", source = "guild", canCraft = true  },
        { buyer = "Tomsk",  itemID = 12426, qty = 1, price = "11po 50pa",  profession = "Blacksmithing", source = "trade", canCraft = false },
    }
end

-- Construit un hex de recettes connues réelles pour un métier (les `count` premières du catalogue),
-- pour que WhoCanCraft / CountKnown répondent comme un vrai artisan.
local function buildHex(prof, count)
    local c = CL(); if not c then return "" end
    local known, got = {}, 0
    for _, e in ipairs(c:ProfessionCatalogue(prof) or {}) do
        if e.spellID then known[e.spellID] = true; got = got + 1; if got >= count then break end end
    end
    return (c:EncodeKnown(prof, known)) or ""
end

local function pmsg(m) print("|cFF33DD88Crafting Order|r |cFFFF8800[solo]|r " .. m) end

function Debug:Enable()
    local c, D = CL(), COC.Directory
    if not (c and D and COC.db) then pmsg(L["infra non prête."]); return end
    D.roster = D.roster or {}
    local myDV = c:DataVersion()
    for _, a in ipairs(self.fakeArtisans) do
        local r = D.roster[a.name] or {}
        r.recipes, r.skill = {}, {}
        for prof, sk in pairs(a.skill) do
            r.recipes[prof] = buildHex(prof, math.min(12, math.floor(sk[1] / 40) + 2))
            r.skill[prof]   = { sk[1], sk[2] }
        end
        r.recipeDV, r.level, r.source, r.fake, r.lastSeen = myDV, a.level, a.source, true, time()
        D.roster[a.name] = r
        D.online[a.name] = a.online or nil
    end
    COC.db.orders = COC.db.orders or {}
    for _, o in ipairs(fakeOrders()) do
        o.ts, o.fake = time(), true
        COC.db.orders[o.id] = o
    end
    COC.db.inbound = COC.db.inbound or {}
    for _, e in ipairs(fakeInbound()) do
        e.id = e.buyer .. "_" .. e.itemID
        e.ts, e.fake, e.status = time(), true, e.status or "new"
        COC.db.inbound[e.id] = e
    end
    COC.db.debug = true
    pmsg(string.format(L["activé — %d artisans + %d commandes + %d entrantes injectés."], #self.fakeArtisans, 3, 3))
    if COC.UI then COC.UI:Refresh() end
end

function Debug:Disable()
    local D = COC.Directory
    if D then
        for name, r in pairs(D.roster or {}) do
            if r.fake then D.roster[name] = nil; D.online[name] = nil end
        end
    end
    for id, o in pairs((COC.db and COC.db.orders) or {}) do
        if o.fake then COC.db.orders[id] = nil end
    end
    for id, e in pairs((COC.db and COC.db.inbound) or {}) do
        if e.fake then COC.db.inbound[id] = nil end
    end
    if COC.db then COC.db.debug = nil end
    pmsg(L["désactivé — faux artisans et commandes purgés."])
    if COC.UI then COC.UI:Refresh() end
end

function Debug:Toggle()
    if COC.db and COC.db.debug then self:Disable() else self:Enable() end
end

-- /co solo [on|off]. Le drapeau garde son nom d'avant (`db.debug`) : un mode solo laissé allumé
-- avant la mise à jour le reste, et Reapply le retrouve.
function Debug:SoloCmd(rest)
    local arg, on = (rest or ""):lower(), (COC.db and COC.db.debug) and true or false
    if arg == "on" and not on then return self:Enable() end
    if arg == "off" and on then return self:Disable() end
    pmsg(on and L["mode solo : activé (/co solo off pour le couper)"]
             or L["mode solo : désactivé (/co solo on pour l'activer)"])
end

local function say(m) print("|cFF33DD88Crafting Order|r " .. m) end

-- /co debug [on|off] (et son ancien nom, /co verbose) : les messages de coulisse dans le chat
-- (Handoff : « X peut faire une captée »). Tapée seule : l'état, et le mot qui le change.
function Debug:VerboseCmd(rest)
    if not COC.db then return end
    local arg = (rest or ""):lower()
    if arg == "on" then COC.db.verbose = true elseif arg == "off" then COC.db.verbose = nil end
    local on = COC.db.verbose and true or false
    if arg == "on" or arg == "off" then
        say(on and L["messages verbeux : activés"] or L["messages verbeux : désactivés"])
    else
        say(self:StatusLine() or L["messages verbeux : désactivés (/co debug on pour les activer)"])
    end
end

-- La ligne du statut (/co status) quand le mode verbeux est allumé ; nil sinon.
function Debug:StatusLine()
    if not (COC.db and COC.db.verbose) then return nil end
    return L["messages verbeux : activés (/co debug off pour les couper)"]
end

-- Au login : la présence (Dir.online) est en mémoire seule → perdue au reload alors que le roster
-- (persistant) garde les 10 artisans. Si le mode debug est actif, on ré-applique le online des faux.
function Debug:Reapply()
    if not (COC.db and COC.db.debug) then return end
    local D = COC.Directory; if not D then return end
    for _, a in ipairs(self.fakeArtisans) do
        if D.roster and D.roster[a.name] then D.online[a.name] = a.online or nil end
    end
    if COC.UI then COC.UI:Refresh() end
end
