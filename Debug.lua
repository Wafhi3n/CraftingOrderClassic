-- Crafting Order - Classic — Debug : mode solo pour "jouer" un réseau fictif.
--
-- Sans 2e client, on ne peut pas voir d'artisans ni d'ordres venant des autres. Ce module injecte
-- un faux roster (artisans avec métiers + niveaux de skill + recettes connues réelles encodées) et
-- de fausses commandes, dans le MÊME cache que le réseau (Directory.roster / online, COC.db.orders),
-- pour tester visuellement les onglets Carnet / Commande / Récolte / Artisans en solo.
--
-- Tout est marqué `fake=true` → `/co debug` (toggle) purge proprement les faux sans toucher au réel.

local COC   = CraftingOrderClassic
local Debug = {}
COC.Debug = Debug

local L = COC.L
local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end
local function me() return (UnitName and UnitName("player")) or "?" end

-- Faux artisans (mock proche du template Claude Design). Clés métier = clés internes EN du catalogue.
-- 10 artisans, 7 en ligne → footer "7 en ligne · 10 artisan(s)". source = guild|friend|added.
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

local function pmsg(m) print("|cFF33DD88Crafting Order|r |cFFFF8800[debug]|r " .. m) end

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
