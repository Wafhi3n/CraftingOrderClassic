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
-- Ce fichier ne fait QUE le nom -> la clé. Aucun appel au jeu : tout se teste sans WoW
-- (tests/test_channels.lua). Les clés sont PERSISTÉES (COC.db.watch) : on en ajoute, on n'en renomme pas.
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
