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
-- Les noms COURTS du jeu, ceux de la fenêtre Chat Channels (GetChannelDisplayInfo ; mesurés le
-- 2026-09-30, client anglais) : « Services » et « TradeLocal ». La liste et les lecteurs passent par
-- les noms LONGS (GetChannelName, CHAT_MSG_CHANNEL) ; ceci évite seulement une réponse FAUSSE à qui
-- donnerait un nom court (« TradeLocal » se lisait Trade, « Services » rien).
local SHORT = { services = "trade_services", tradelocal = "trade_local" }

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
    if SHORT[low] then return SHORT[low] end
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
local DEFAULTS = { trade_services = true, trade = true, trade_local = true, guild = true, sayyell = true, general = false,
                   notif_follow = true, notif_login = true,
                   notif_way_chat = true, notif_way_toast = true, notif_way_sound = true }
-- Deux cases ne disent pas OÙ lire mais s'il faut PRÉVENIR (ligne de chat, bandeau, son) : ce réglage
-- n'existait que par /co notify, qu'aucun joueur ne trouvait (demande du user, 2026-09-30).
--   notif_orders = les commandes reçues par l'addon : lit notifyScope, la vérité de /co notify.
--   notif_chat   = les demandes lues dans le chat. Jamais touchée, elle suit notifyScope : qui avait
--                  tout coupé par /co notify off reste sans alerte. Une fois cochée ou décochée, elle
--                  ne dépend plus que d'elle-même.
--   notify:<mode> = les trois portées de /co notify (all, directed, named), une seule cochée. Décocher
--                  « Commandes » garde la portée dans notifyScopeOn : la recocher la rend.
--   notif_follow  = le suivi de MES commandes (remise, confirmée, refusée) ; notif_login = la ligne du login.
--   notif_way_*   = COMMENT prévenir (chat, bandeau, son), pour toutes ces alertes : COC.Notify les lit.
Ch.WATCH_KEYS = { "trade_services", "trade", "trade_local", "general", "guild", "sayyell", "room", "nearby",
                  "notif_orders", "notif_chat", "notif_follow", "notif_login",
                  "notif_way_chat", "notif_way_toast", "notif_way_sound" }
Ch.NOTIFY_MODES = { "all", "directed", "named" }

local function clubId(key) return type(key) == "string" and key:match("^club:(.+)$") or nil end
local function notifyMode(key) return type(key) == "string" and key:match("^notify:(%a+)$") or nil end

-- La portée choisie, même quand les commandes sont coupées (la case la montre alors grisée).
local function currentMode(db)
    local m = db and db.notifyScope
    if m and m ~= "off" then return m end
    return (db and db.notifyScopeOn) or "all"
end

-- Change notifyScope. La case chat suivait ce réglage : on fige d'abord ce qu'elle montrait.
local function setScope(db, scope)
    db.watch = db.watch or {}
    if db.watch.notif_chat == nil then db.watch.notif_chat = Ch.IsWatched("notif_chat") end
    if scope == "off" then db.notifyScopeOn = currentMode(db) end
    db.notifyScope = scope
    if COC.UI and COC.UI.RefreshOrderIndicator then COC.UI:RefreshOrderIndicator() end   -- comme /co notify
end

function Ch.IsWatched(key)
    local db = COC.db
    if key == "room" then return not (db and db.roomOff) end
    if key == "nearby" then return (db and db.crafterScan) and true or false end
    local ordersOn = not (db and db.notifyScope == "off")
    if key == "notif_orders" then return ordersOn end
    local mode = notifyMode(key)
    if mode then return currentMode(db) == mode end
    if key == "notif_chat" then
        local own = db and db.watch and db.watch.notif_chat
        if own == nil then return ordersOn end
        return own == true
    end
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
    elseif key == "notif_orders" then setScope(db, on and currentMode(db) or "off")
    elseif notifyMode(key) then
        if on then setScope(db, notifyMode(key)) end   -- une portée ne se décoche pas : on en choisit une autre
    else
        db.watch = db.watch or {}
        db.watch[key] = on
    end
    -- La section de l'onglet Artisans suit, d'où que vienne le changement (clic, /co watch).
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
end

-- ------------------------------------------------------------------
-- La liste de l'onglet Artisans
-- ------------------------------------------------------------------
-- Les deux derniers groupes : QUELLES alertes, puis COMMENT elles préviennent.
local function notifRows(L, rows, head, item)
    head(L["NOTIFICATIONS"], L["Ce qui te prévient : une ligne dans le chat, un bandeau et un son. Décochée, une case ne retire aucune commande : tout reste dans le Carnet et la vue métier."])
    item("notif_chat", L["Demandes lues dans le chat"], true, nil, L["Les demandes (« WTB [objet] ») lues dans les canaux cochés plus haut, pour ce que tu sais crafter."])
    item("notif_orders", L["Commandes de l'addon"], true, nil, L["Les commandes que les autres joueurs de l'addon t'envoient ou publient."])
    -- Les portées, sous leur case (`sub` : en retrait dans l'onglet, absentes du panneau de première
    -- connexion). Grisées quand les commandes sont coupées : le choix, lui, est gardé.
    local ordersOn = Ch.IsWatched("notif_orders")
    local modes = {
        all      = { L["Toutes"], L["Aussi les commandes publiques, pour un métier que tu as."] },
        directed = { L["Guilde, amis et pour moi"], L["Pas les commandes publiques ouvertes à tous."] },
        named    = { L["Seulement pour moi"], L["Les commandes à ton nom ou à celui d'un de tes persos."] },
    }
    for _, m in ipairs(Ch.NOTIFY_MODES) do
        item("notify:" .. m, modes[m][1], ordersOn, nil, modes[m][2])
        rows[#rows].sub = true
    end
    item("notif_follow", L["Suivi de mes commandes"], true, nil, L["Une commande qu'on t'a remise, dont on a confirmé la réception, ou qu'on a refusée."])
    item("notif_login", L["Message à la connexion"], true, nil, L["La ligne « chargé — /co help » quand tu te connectes."])
    head(L["FAÇON DE PRÉVENIR"], L["Pour toutes les alertes cochées au-dessus."])
    item("notif_way_chat", L["Ligne dans le chat"], true)
    item("notif_way_toast", L["Bandeau à l'écran"], true)
    item("notif_way_sound", L["Son"], true)
end

-- Les lignes de la section « Canaux surveillés » : des en-têtes de groupe et des lignes à case.
-- PURE : l'appelant dit où le joueur se trouve (`joined[clé]` = le nom du canal tel que le jeu
-- l'écrit), s'il a une guilde, et ses communautés ({ id, name }). `there` = le joueur y est en ce
-- moment (sinon la ligne est grisée ; son choix, lui, est gardé).
-- Un canal perso autre que la salle n'a PAS de ligne tant qu'aucun lecteur ne s'en sert (palier 4
-- de la spec) : une case qui ne fait rien est pire que pas de case.
function Ch.BuildRows(joined, clubs, inGuild)
    local L, rows = COC.L, {}
    joined, clubs = joined or {}, clubs or {}
    local function head(text, tip) rows[#rows + 1] = { kind = "header", text = text, tip = tip } end
    local function item(key, label, there, note, tip)
        rows[#rows + 1] = { kind = "item", key = key, label = label, there = there and true or false,
                            note = note, tip = tip, on = Ch.IsWatched(key) }
    end
    head(L["ANNONCES LUES"], L["L'addon y lit les demandes, les dispos et les annonces des autres joueurs de l'addon. Il n'écrit que sur Trade (Services), et seulement si tu coches « Annoncer en Commerce »."])
    -- Le nom du jeu quand le joueur est dans le canal ; sinon (hors d'une ville) notre libellé.
    -- Clés écrites en toutes lettres : une clé calculée est invisible à check_locale.
    local fallback = { trade_services = L["Commerce (Services)"], trade = L["Commerce"],
                       trade_local = L["Commerce (local)"], general = L["Général"] }
    for _, key in ipairs(Ch.KEYS) do
        local name = joined[key]
        -- General existe partout : ne pas y être n'a rien à voir avec la ville.
        item(key, name or fallback[key], name ~= nil, (not name and key ~= "general") and L["en ville"] or nil)
    end
    item("guild", L["Guilde"], inGuild)
    head(L["RÉSEAU DE L'ADDON"], L["L'addon s'y présente par un message invisible aux joueurs de ta salle ; ensuite, tout passe en chuchotement."])
    item("room", "CraftLinkNet", true, L["salle"])
    -- « COMMUNAUTÉS », pas « ANNUAIRE » : le mot désignait déjà une bande SOURCE et l'annuaire entier
    -- (revue de design de l'onglet Artisans, constat 8, 2026-09-30).
    head(L["COMMUNAUTÉS"], L["Les membres d'une communauté cochée rejoignent ton annuaire, même hors ligne. Aucune donnée de l'addon n'y passe."])
    for _, c in ipairs(clubs) do item("club:" .. c.id, c.name, true) end
    if #clubs == 0 then rows[#rows + 1] = { kind = "note", text = L["aucune communauté"] } end
    head(L["AUTOUR DE MOI"], L["Ce que les joueurs disent ou crient près de toi (les lignes LFW), et, en ville, ceux que tu vois crafter."])
    item("sayyell", L["Dire et crier"], true)
    item("nearby", L["Crafteurs autour"], true, L["en ville"], L["Repérer les crafteurs autour (en ville)"])
    notifRows(L, rows, head, item)
    return rows
end

-- ------------------------------------------------------------------
-- Le panneau de première connexion
-- ------------------------------------------------------------------
-- Faut-il l'ouvrir ? "done" = déjà vu, "wait" = pas maintenant (combat, instance où les communautés
-- sont illisibles, SavedVariable pas encore là), "show" = oui.
-- `setupSeen` porte la version où le joueur l'a validé, POUR MÉMOIRE seulement : on ne la compare
-- jamais à la version courante, sinon le panneau reviendrait à chaque mise à jour. Le jour où il
-- doit revenir exprès, c'est un autre repère qu'il faudra, pas celui-ci.
function Ch.SetupState(db, inCombat, inInstance)
    if not db then return "wait" end
    if db.setupSeen ~= nil then return "done" end
    if inCombat or inInstance then return "wait" end
    return "show"
end

-- Validé, ou fermé (croix, Échap) : dans les deux cas le joueur a vu ce qui est coché, et les cases
-- agissent dès le clic. Le premier passage fait foi ; un second ne réécrit rien.
function Ch.MarkSetupSeen(db, version)
    if db and db.setupSeen == nil then db.setupSeen = version or true end
end

-- /co watch [clé on|off] — diagnostic, non localisé : l'état des cases, et de quoi en changer une
-- hors de l'onglet Artisans. /co watch setup rouvre le panneau de première connexion.
function Ch:Cmd(arg)
    local key, state = (arg or ""):lower():match("^%s*(%S*)%s*(%S*)")
    if key == "setup" then
        if COC.UI and COC.UI.ShowSetup then COC.UI:ShowSetup() end
        return
    end
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
