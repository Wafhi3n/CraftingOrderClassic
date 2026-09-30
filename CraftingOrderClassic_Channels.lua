-- CraftingOrderClassic_Channels.lua — RECONNAÎTRE un canal du jeu (spec docs/specs/canaux-surveilles.md).
--
-- Pourquoi (2026-09-30) : chaque lecteur du chat (demandes, lignes LFW, annonces #CO) testait le nom
-- du canal à sa façon, et « trade » avalait d'un coup Trade, Trade (Services) et Trade (Local). Pour
-- donner une case à CHAQUE canal, il faut une seule réponse à « quel canal est-ce ? », quelle que soit
-- la langue du client.
--
--   « 4. Trade (Services) - English »    -> trade_services
--   « Commerce - Français »              -> trade
--   « Handel (Lokal) - Eisenschmiede »   -> trade_local
--   « Général - Dun Morogh »             -> general
--   LocalDefense, un canal perso…        -> nil
--
-- Deux choses ici, et rien d'autre : le nom -> la clé (KeyOf), et la case de chaque clé (IsWatched,
-- SetWatched). Aucun appel au jeu : tout se teste sans WoW (tests/test_channels.lua,
-- tests/test_channel_watch.lua). Les clés sont PERSISTÉES (COC.db.watch) : on en ajoute, on n'en
-- renomme pas.
--
-- Mesuré sur Forever, client anglais (COCProbe, 2026-09-29) : « Trade (Services) - English » et
-- « Trade (Local) - Ironforge ». Le nom français, allemand ou espagnol de Trade (Local) n'est PAS
-- mesuré : il se reconnaît à sa forme (un canal de Commerce, avec une parenthèse qui n'est pas
-- « Services »). Un canal PERSO qui s'appellerait « Trade » n'est pas distingué ici : c'est à
-- l'appelant de savoir, par le jeu, qu'un canal est perso.

local COC = CraftingOrderClassic
local Ch = {}
COC.Channels = Ch

Ch.KEYS = { "trade_services", "trade", "trade_local", "general" }   -- ordre d'affichage

-- `lower` ne touche pas aux majuscules accentuées : « Échange » se cherche sous ses deux casses.
local TRADE   = { "trade", "commerce", "échange", "Échange", "echange", "handel", "comercio" }
local SERVICE = { "servic", "dienst" }
local GENERAL = { "general", "général", "allgemein" }

local function has(low, list)
    for _, w in ipairs(list) do if low:find(w, 1, true) then return true end end
    return false
end

-- Le nom nu : sans le numéro (« 4. ») ni le suffixe de langue ou de zone (« - English »,
-- « - Ironforge »). Le suffixe part AVANT la recherche : « General - Trade District » n'est pas un
-- canal de Commerce.
function Ch.BaseName(name)
    if type(name) ~= "string" then return nil end
    local base = name:gsub("^%s*%d+%.%s*", "")
    base = base:match("^(.-)%s+%-%s+") or base
    return (base:gsub("%s+$", ""))
end

-- La clé d'un canal du jeu, ou nil s'il n'en est pas un que l'addon exploite.
function Ch.KeyOf(name)
    local base = Ch.BaseName(name)
    if not base or base == "" then return nil end
    local low = base:lower()
    if has(low, TRADE) then
        if has(low, SERVICE) then return "trade_services" end
        if low:find("(", 1, true) then return "trade_local" end
        return "trade"
    end
    if has(low, GENERAL) then return "general" end
    return nil
end

-- ------------------------------------------------------------------
-- Les cases « surveiller »
-- ------------------------------------------------------------------
-- Les réglages qui existaient AVANT la liste restent la vérité de leur case, sous leur nom (pas de
-- migration, donc rien à perdre) : `room` lit roomOff, `nearby` lit crafterScan, `club:<id>` lit
-- circles. Le reste vit dans COC.db.watch : absent = le défaut, false = décoché par le joueur.
local DEFAULTS = { trade_services = true, trade = true, trade_local = true, guild = true, sayyell = true, general = false }
Ch.WATCH_KEYS = { "trade_services", "trade", "trade_local", "general", "guild", "sayyell", "room", "nearby" }

local function clubId(key) return type(key) == "string" and key:match("^club:(.+)$") or nil end

function Ch.IsWatched(key)
    local db = COC.db
    if key == "room" then return not (db and db.roomOff) end
    if key == "nearby" then return (db and db.crafterScan) and true or false end
    local id = clubId(key)
    if id then return (db and db.circles and db.circles[id]) == true end
    local v = db and db.watch and db.watch[key]
    if v == nil then return DEFAULTS[key] == true end
    return v == true
end

-- Coche ou décoche. Les anciens réglages passent par LEUR porte : elle a des effets (quitter la
-- salle, armer le repérage, reprendre la présence d'un cercle) qu'une simple écriture manquerait.
function Ch.SetWatched(key, on)
    on = on and true or false
    local db, D = COC.db, COC.Directory
    if not db then return end
    local id = clubId(key)
    if key == "room" then if D and D.SetRoom then D:SetRoom(on) end
    elseif key == "nearby" then if D and D.SetCrafterScan then D:SetCrafterScan(on) end
    elseif id then if D and D.SetCircle then D:SetCircle(id, on) end
    else
        db.watch = db.watch or {}
        db.watch[key] = on
    end
end

-- /co watch [clé on|off] — diagnostic, non localisé : l'état des cases, et de quoi en changer une
-- avant que l'onglet Artisans ne les montre.
function Ch:Cmd(arg)
    local key, state = (arg or ""):lower():match("^%s*(%S*)%s*(%S*)")
    if state == "on" or state == "off" then
        local known = false
        for _, k in ipairs(Ch.WATCH_KEYS) do known = known or k == key end
        if known then Ch.SetWatched(key, state == "on")
        else print("|cFF33DD88Crafting Order|r clé inconnue : " .. tostring(key)) end
    end
    print("|cFF33DD88Crafting Order|r canaux surveillés (/co watch <clé> on/off) :")
    for _, k in ipairs(Ch.WATCH_KEYS) do
        print("  " .. k .. " : " .. (Ch.IsWatched(k) and "|cFF33DD33coché|r" or "|cFFFFCC00décoché|r"))
    end
end
