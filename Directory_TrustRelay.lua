-- Directory_TrustRelay.lua — relais de confiance (spec docs/specs/relais-confiance.md).
--
-- Une salle CraftLinkNet s'arrête au royaume (mesuré le 2026-10-07). Le pont (Directory_Bridge)
-- présente un arrivant aux autres salles, mais un joueur entré là-bas APRÈS la présentation ne le
-- connaît pas, et « à tous » plafonne à 40 chuchotements. Ici, la SOURCE A confie son LFW et ses
-- commandes « Tous » à un RELAIS par royaume étranger, qui les poste dans SA salle : tous ses présents
-- les voient d'un coup. La source tranche au premier geste (idée du user) : un LFW relayé est vérifié
-- auprès de A quand on clique dessus, et un relais qui a menti est écarté.
--
-- Fil :  RL|<A>|<n>|<message>        A → relais (whisper), puis relais → sa salle, tel quel
--        RLA|<n>                     relais → A : posté
--        VRF|<métier>|<relais>       D → A : « tu es bien en LFW ? »
--        VRF|ok|<métier>   VRF|no|<métier>|old   VRF|no|<métier>
-- <message> ∈ { LFW|on|<métier>, LFW|off, ORD|NEW|… (acheteur = A) }. Jamais un second saut. Rien en
-- instance (le jeu refuse), rien salle coupée (D-R10). Le royaume n'apparaît nulle part à l'écran.

local COC = CraftingOrderClassic
local Dir = COC.Directory

local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)

local MAX_REALMS    = 5            -- un relais par royaume étranger, au plus 5
local LFW_EVERY     = 15 * 60      -- s : mon LFW relayé au plus toutes les 15 min (D-R6)
local ORDER_EVERY   = 2 * 3600     -- s, heure réelle : une commande relayée au plus toutes les 2 h
local RELAYED_TTL   = 25 * 60      -- s, heure réelle : une entrée LFW relayée sans rafraîchissement
local STALE_FOR     = 35 * 60      -- s : ce que j'ai confié à un relais depuis moins de ça peut traîner
local ACK_WAIT      = 30           -- s : un relais qui n'a pas accusé réception…
local SILENT_SKIP   = 30 * 60      -- s : … n'est plus choisi pendant 30 min
local CAP_WINDOW    = 600          -- s : fenêtre des plafonds (D-R7)
local CAP_SOURCE, CAP_ALL, CAP_MEMBER = 6, 30, 10
local BAN_FOR       = 24 * 3600    -- s, heure réelle : un relais qui a menti, écarté chez qui l'a vu
local MAX_BYTES     = 255          -- le jeu coupe un message d'addon au-delà, sans prévenir

local function now() return (GetTime and GetTime()) or 0 end
local function clock() return (time and time()) or 0 end
local function trace(msg) if COC.Trace then COC.Trace:Log("net", msg) end end
local function me() return COC.Api.PlayerName() end
local function fullName(n) local f = COC.Api.IsFullPlayerName; return n ~= nil and (not f or f(n)) end
local function myChar(n) return n == me() or (COC.IsMyChar and COC:IsMyChar(n)) or false end
local function canSend() return not Dir._BridgeCanSend or Dir._BridgeCanSend() end
local function validRealm(r) return Dir._ValidRealm and Dir._ValidRealm(r) end
local function myRealm() return Dir._MyRealmID and Dir:_MyRealmID() end
local function enabled() return CraftLink ~= nil and Dir.RoomEnabled ~= nil and Dir:RoomEnabled() end

local function state()
    local s = Dir._trust
    if not s then
        s = { seq = 0, pending = {}, silent = {}, seen = {}, caps = {}, capTraced = {} }
        Dir._trust = s
    end
    return s
end

-- Ce qui doit survivre à un /reload : les dates d'envoi (heure réelle), ce que j'ai confié à chaque
-- relais (pour distinguer périmé et mensonge), les relais écartés.
local function store()
    if not COC.db then return nil end
    COC.db.trust = COC.db.trust or {}
    local t = COC.db.trust
    t.orders, t.confided, t.banned, t.liars = t.orders or {}, t.confided or {}, t.banned or {}, t.liars or {}
    return t
end

-- Au plus `limit` évènements par clé et par fenêtre (plafonds D-R7) ; une trace au premier refus.
local function under(bucket, key, limit)
    local s, t = state(), now()
    s.caps[bucket] = s.caps[bucket] or {}
    local kept = {}
    for _, at in ipairs(s.caps[bucket][key] or {}) do if t - at < CAP_WINDOW then kept[#kept + 1] = at end end
    s.caps[bucket][key] = kept
    if #kept >= limit then
        local tag = bucket .. ">" .. key
        if not s.capTraced[tag] then trace(("relais : plafond %s atteint pour %s"):format(bucket, key)) end
        s.capTraced[tag] = true
        return false
    end
    kept[#kept + 1] = t
    return true
end

-- ------------------------------------------------------------------ la source (A)

-- Un relais par royaume étranger : à jour (rl=1), en ligne, vu en direct ; un ami ou un membre de
-- guilde d'abord, sinon le plus récemment vu. Un relais qui n'a pas accusé réception de mon dernier
-- envoi est écarté 30 min ; un relais qui a menti ne l'est plus jamais (D-R5, D-R6).
local function pickRelays(mine)
    local s, db, t = state(), store(), now()
    for n, at in pairs(s.pending) do
        if t - at >= ACK_WAIT then s.silent[n], s.pending[n] = t + SILENT_SKIP, nil end
    end
    local best = {}
    for n, r in pairs(Dir.roster or {}) do
        local x = r.realm
        local muted = (s.silent[n] and s.silent[n] > t) or (db and db.liars[n])
        if r.relay and validRealm(x) and x ~= mine and Dir.online[n] and r.lastSeen and not muted then
            local score = ((r.isFriend or r.isGuild) and 1e12 or 0) + r.lastSeen
            if not best[x] or score > best[x].score then best[x] = { name = n, score = score } end
        end
    end
    return best
end

-- Confie `inner` à mes relais. Rend le nombre de relais visés (0 : rien n'est parti).
local function confide(inner, lfwProf)
    local mine = myRealm()
    if not (enabled() and canSend() and mine and fullName(me())) then return 0 end
    local s, db = state(), store()
    s.seq = s.seq + 1
    local env = ("RL|%s|%d|%s"):format(me(), s.seq, inner)
    if #env > MAX_BYTES then
        trace(("relais : %d octets, trop long pour être relayé"):format(#env))
        return 0
    end
    local n = 0
    for _, p in pairs(pickRelays(mine)) do
        if n >= MAX_REALMS then break end
        n = n + 1
        CraftLink:Send(env, "whisper", p.name)
        s.pending[p.name] = s.pending[p.name] or now()
        if lfwProf and db then db.confided[p.name] = { prof = lfwProf, at = clock() } end
        trace(("relais : %s confié à %s"):format(inner:sub(1, 24), p.name))
    end
    return n
end

-- Mon LFW change ou se rafraîchit (Directory_LFW, _BroadcastLFW). Activé : relayé tout de suite, puis
-- au plus toutes les 15 min. Coupé : relayé tout de suite, s'il avait été relayé.
function Dir:TrustRelayLFW(prof)
    local s = state()
    if prof then
        if s.lfwProf == prof and s.lfwAt and now() - s.lfwAt < LFW_EVERY then return end
        if confide("LFW|on|" .. prof, prof) > 0 then s.lfwProf, s.lfwAt = prof, now() end
    elseif s.lfwProf then
        confide("LFW|off")
        s.lfwProf, s.lfwAt = nil, nil
    end
end

-- Une de mes commandes part (Orders:Broadcast NEW). Relayée si elle est « Tous », ouverte, et pas
-- relayée depuis moins de 2 h (la republication part aussi à chaque bonjour reçu).
function Dir:TrustRelayOrder(o, payload)
    if not (o and o.id and payload and myChar(o.buyer)) then return end
    if (o.recipient or "Tous") ~= "Tous" or (o.status or "open") ~= "open" then return end
    local db = store()
    if not db then return end
    local last = db.orders[o.id]
    if last and clock() - last < ORDER_EVERY then return end
    for id, at in pairs(db.orders) do if clock() - at >= ORDER_EVERY then db.orders[id] = nil end end
    if confide(payload) > 0 then db.orders[o.id] = clock() end
end

-- ------------------------------------------------------------------ le relais (B)

-- Le message intérieur est-il relayable pour la source A ? LFW on/off, ou une commande dont A est
-- l'acheteur. Rien d'autre (D-R2).
local function relayable(A, inner)
    if inner == "LFW|off" or inner:match("^LFW|on|[%a ]+$") then return true end
    if inner:find("^ORD|NEW|") then
        local f = COC.OrdersCodec and COC.OrdersCodec.Decode(inner)
        return f ~= nil and f.buyer == A
    end
    return false
end

function Dir:_TrustAsRelay(sender, A, n, message, inner)
    if sender ~= A or not relayable(A, inner) or #message > MAX_BYTES then return end
    if not (enabled() and canSend() and CraftLink.RoomJoined and CraftLink:RoomJoined()) then return end
    local key = A .. "#" .. n
    if state().seen[key] then return end
    if not (under("source", A, CAP_SOURCE) and under("all", "*", CAP_ALL)) then return end
    state().seen[key] = now()
    CraftLink:Send(message, "room")
    CraftLink:Send("RLA|" .. n, "whisper", A)
    trace(("relais : %s de %s posté dans la salle"):format(inner:sub(1, 24), A))
end

-- ------------------------------------------------------------------ la salle (D)

local function refresh(name)
    if COC.Nameplate and COC.Nameplate.Refresh then COC.Nameplate:Refresh(name) end
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
end

-- Un inconnu en LFW relayé entre dans l'annuaire comme une fiche relayée (RLY) : sans présence ni
-- « vu le », marquée « via <relais> », oubliée après 7 jours (Dir:PruneRelays). Un pair connu, lui,
-- garde sa fiche ; seule l'entrée LFW dit « via ».
local function noteRelayedPeer(A, B)
    Dir.roster = Dir.roster or {}
    local r = Dir.roster[A]
    if not r then r = {}; Dir.roster[A] = r end
    if not r.faction and Dir._MyFaction then r.faction = Dir:_MyFaction() end
    if not r.lastSeen then r.relayed = r.relayed or { via = B, ts = clock() } end
end

-- LFW relayé : une entrée « via B » qui expire en 25 min, jamais à la place d'une entrée directe ; un
-- `LFW off` relayé n'efface qu'une entrée relayée (D-R4, critère 5).
local function relayedLFW(A, B, inner)
    Dir.lfw = Dir.lfw or {}
    local e = Dir.lfw[A]
    local direct = e and not e.via and (not e.expiry or clock() < e.expiry)
    if inner == "LFW|off" then
        if e and e.via then Dir.lfw[A] = nil end
    elseif not direct then
        Dir.lfw[A] = { prof = inner:match("^LFW|on|(.+)$"), expiry = clock() + RELAYED_TTL, via = B, ts = clock() }
        noteRelayedPeer(A, B)
    end
    refresh(A)
end

function Dir:_TrustAsMember(sender, A, n, inner)
    if sender == A or myChar(A) or not fullName(A) or not relayable(A, inner) then return end
    local db = store()
    local ban = db and db.banned[sender]
    if ban and clock() < ban then return end
    local key = A .. "#" .. n
    if state().seen[key] then return end
    if not under("member", sender, CAP_MEMBER) then return end
    state().seen[key] = now()
    if inner:find("^LFW|") then return relayedLFW(A, sender, inner) end
    local Orders = COC.Orders
    if not (Orders and Orders._OnNew) then return end
    Orders:_OnNew(inner, "RELAY", sender)                  -- créée par un tiers : jamais modifiée (D-R11)
    local f = COC.OrdersCodec and COC.OrdersCodec.Decode(inner)
    local o = f and COC.db and COC.db.orders and COC.db.orders[f.id]
    if o and o.buyer == A and not o.via then o.via = sender end
    trace(("relais : %s de %s reçu via %s"):format(inner:sub(1, 24), A, sender))
end

function Dir:OnTrustEnvelope(sender, message, distribution)
    if not (sender and enabled()) then return end
    local A, n, inner = (message or ""):match("^RL|([^|]+)|(%d+)|(.+)$")
    if not A then return end
    if distribution == "WHISPER" then return self:_TrustAsRelay(sender, A, n, message, inner) end
    if distribution == "CHANNEL" then return self:_TrustAsMember(sender, A, n, inner) end
end

function Dir:OnTrustAck(sender)
    if sender then state().pending[sender] = nil end
end

-- ------------------------------------------------------------------ la vérification (D-R5)

-- D agit sur l'entrée LFW relayée de A (bouton Chuchoter de l'onglet Artisans) : une question à A, une
-- seule fois par entrée.
function Dir:TrustVerify(A)
    local e = A and self.lfw and self.lfw[A]
    if not (e and e.via and not e.asked and CraftLink and canSend()) then return end
    e.asked = true
    CraftLink:Send(("VRF|%s|%s"):format(e.prof or "", e.via), "whisper", A)
    trace(("VRF : %s, est-ce bien vrai ? (relayé par %s)"):format(A, e.via))
end

-- A répond. Périmé (« old ») : ce LFW, je l'ai bien confié à ce relais il y a moins de 35 min.
local function answerQuestion(D, prof, relay)
    if not under("vrf", D, 3) then return end
    if Dir.MyLFW and Dir:MyLFW() == prof then return CraftLink:Send("VRF|ok|" .. prof, "whisper", D) end
    local db = store()
    local c = db and db.confided[relay]
    if c and c.prof == prof and clock() - c.at < STALE_FOR then
        return CraftLink:Send("VRF|no|" .. prof .. "|old", "whisper", D)
    end
    if db then db.liars[relay] = clock() end
    CraftLink:Send("VRF|no|" .. prof, "whisper", D)
    trace(("VRF : %s m'a prêté un LFW %s que je ne lui ai pas confié : je ne le choisis plus"):format(relay, prof))
end

-- D reçoit la réponse : oui, l'entrée reste ; périmé, elle disparaît ; démenti, elle disparaît et le
-- relais est écarté 24 h (ses messages ignorés).
local function receiveAnswer(A, verdict, prof, old)
    local e = Dir.lfw and Dir.lfw[A]
    if not (e and e.via and e.prof == prof) then return end
    if verdict == "ok" then e.vouched = true; return end
    Dir.lfw[A] = nil
    if old then
        trace(("VRF : %s n'est plus en LFW (copie périmée)"):format(A))
    else
        local db = store()
        if db then db.banned[e.via] = clock() + BAN_FOR end
        trace(("VRF : %s dément, relais %s écarté"):format(A, e.via))
    end
    refresh(A)
end

function Dir:OnTrustVerify(sender, message)
    if not (sender and CraftLink) then return end
    local verdict, prof, tail = (message or ""):match("^VRF|(%a+)|([^|]+)|?(.*)$")
    if verdict == "ok" or verdict == "no" then
        return receiveAnswer(sender, verdict, prof, tail == "old")
    end
    local qprof, relay = (message or ""):match("^VRF|([^|]+)|([^|]+)$")
    if qprof and relay then answerQuestion(sender, qprof, relay) end
end

function Dir:StartTrustRelay()
    if not (CraftLink and CraftLink.RegisterHandler) then return end
    CraftLink:RegisterHandler("RL",  function(s, m, d) Dir:OnTrustEnvelope(s, m, d) end)
    CraftLink:RegisterHandler("RLA", function(s)       Dir:OnTrustAck(s) end)
    CraftLink:RegisterHandler("VRF", function(s, m)    Dir:OnTrustVerify(s, m) end)
end
