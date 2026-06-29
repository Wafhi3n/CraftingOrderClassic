-- CraftLink-1.0 — Transport générique : 4 portées + dispatch par verbe + présence + santé réseau.
--
-- Infrastructure réseau réutilisable (pas spécifique aux recettes) : un addon enregistre des
-- handlers par verbe (`RegisterHandler("RK", fn)`) et émet via `Send(payload, scope[, target])`.
-- Portées :
--   * "global"  : canal caché à l'échelle du royaume (JoinTemporaryChannel + SendAddonMessage
--                 distribution "CHANNEL") — confirmé OK en Classic Era, sans hardware event.
--   * "guild"   : distribution "GUILD" (+ relais GreenWall à brancher — hardware-event only).
--   * "say"/"yell": proximité (SendAddonMessage "SAY"/"YELL"), limité par la portée.
--   * "whisper" : 1:1 DIRIGÉ vers `target` (SendAddonMessage "WHISPER"). FIABLE sans guilde ni canal
--                 (zéro race au login, zéro portée) → découverte dirigée + ordres ciblés (2 comptes).
--
-- Présence : on N'ENVOIE PAS de heartbeat — l'appartenance au canal caché EST la présence. Les
-- events CHAT_MSG_CHANNEL_JOIN/_LEAVE du canal sont relayés via `OnPresence(fn)`.
--
-- Santé : JoinTemporaryChannel est async ET le canal peut se perdre (reload, throttle login). Un
-- watchdog ré-résout l'index et rejoint si besoin ; `OnNetworkReady(fn)` se déclenche à chaque
-- (re)acquisition du canal → le produit (re)publie son annuaire (fini le « After(3s) » fragile).

local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
if not lib then return end

local PREFIX        = "CraftLink"
local CHANNEL_NAME  = "CraftLinkNet"   -- nom FIXE : on VEUT que tous les porteurs partagent le canal
local SEND_INTERVAL = 0.15             -- s entre 2 AddonMessage (~6-7/s, sous le plafond client)
local JOIN_RETRY    = 1.0              -- s : JoinTemporaryChannel est async, on résout l'index en différé
local WATCHDOG      = 8.0              -- s : ré-vérifie périodiquement que le canal est toujours là

lib._handlers    = lib._handlers    or {}   -- [verb] = { fn(sender, payload, distribution), ... }
lib._presenceCb  = lib._presenceCb  or nil  -- fn("join"|"leave", playerShort)
lib._readyCbs    = lib._readyCbs    or {}   -- { fn(), ... } appelés à chaque (re)acquisition du canal
lib._sendQueue   = lib._sendQueue   or {}
lib._sendBusy    = lib._sendBusy    or false

-- ------------------------------------------------------------------
-- Trace (optionnelle) : le produit branche un tracer ; la lib reste agnostique.
-- ------------------------------------------------------------------
function lib:SetTracer(fn) self._trace = fn end
local function trace(cat, msg) if lib._trace then pcall(lib._trace, cat, msg) end end

-- ------------------------------------------------------------------
-- API publique d'enregistrement
-- ------------------------------------------------------------------
-- Plusieurs modules peuvent écouter le même verbe (ex. HI : présence ET resync d'ordres).
function lib:RegisterHandler(verb, fn)
    local list = self._handlers[verb]
    if not list then list = {}; self._handlers[verb] = list end
    list[#list + 1] = fn
end
function lib:OnPresence(fn)            self._presenceCb = fn end
function lib:IsNetworkReady()          return self._channelJoined == true end
function lib:ChannelName()             return CHANNEL_NAME end

-- Callback « réseau prêt » : déclenché à chaque (re)acquisition du canal. Si déjà prêt à
-- l'enregistrement → déclenché tout de suite (le produit ne rate jamais la fenêtre).
function lib:OnNetworkReady(fn)
    if type(fn) ~= "function" then return end
    self._readyCbs[#self._readyCbs + 1] = fn
    if self._channelJoined then pcall(fn) end
end

local function fireReady()
    trace("net", "canal acquis (idx=" .. tostring(lib._channelIndex) .. ") → ready callbacks")
    for _, fn in ipairs(lib._readyCbs) do pcall(fn) end
end

local function playerShort(name)
    if not name then return nil end
    return name:match("^([^%-]+)") or name
end

-- ------------------------------------------------------------------
-- Canal global caché
-- ------------------------------------------------------------------
local function hideChannelFromChat()
    if not ChatFrame_RemoveChannel then return end
    for i = 1, (NUM_CHAT_WINDOWS or 10) do
        local cf = _G["ChatFrame" .. i]
        if cf then pcall(ChatFrame_RemoveChannel, cf, CHANNEL_NAME) end
    end
end

-- Rejoint le canal caché et résout son index (async → retry borné). Idempotent.
function lib:JoinNetwork(attempt)
    attempt = attempt or 1
    if self._channelJoined then return end
    if JoinTemporaryChannel then JoinTemporaryChannel(CHANNEL_NAME) end
    local idx = GetChannelName and GetChannelName(CHANNEL_NAME) or 0
    if idx and idx > 0 then
        self._channelIndex  = idx
        self._channelJoined = true
        hideChannelFromChat()
        fireReady()
    elseif attempt < 15 and C_Timer and C_Timer.After then
        trace("net", "join tentative " .. attempt .. " — index pas encore résolu")
        C_Timer.After(JOIN_RETRY, function() lib:JoinNetwork(attempt + 1) end)
    else
        trace("net", "join ÉCHEC après " .. attempt .. " tentatives (le watchdog réessaiera)")
    end
end

-- Watchdog : si on a perdu le canal (reload, kick, throttle), on ré-résout/rejoint. Self-healing.
function lib:_Watchdog()
    local idx = GetChannelName and GetChannelName(CHANNEL_NAME) or 0
    if idx and idx > 0 then
        if not self._channelJoined or self._channelIndex ~= idx then
            self._channelIndex  = idx
            local was = self._channelJoined
            self._channelJoined = true
            hideChannelFromChat()
            if not was then trace("net", "watchdog : canal ré-acquis (idx=" .. idx .. ")"); fireReady() end
        end
    else
        if self._channelJoined then trace("net", "watchdog : canal PERDU → rejoin") end
        self._channelJoined = false
        self._channelIndex  = nil
        self:JoinNetwork()
    end
end

-- ------------------------------------------------------------------
-- Envoi (file FIFO throttlée, partagée par toutes les portées)
-- ------------------------------------------------------------------
local function rawSend(payload, scope, target)
    if not (C_ChatInfo and C_ChatInfo.SendAddonMessage) then return end
    if scope == "guild" then
        C_ChatInfo.SendAddonMessage(PREFIX, payload, "GUILD")
    elseif scope == "whisper" then
        if target and target ~= "" then C_ChatInfo.SendAddonMessage(PREFIX, payload, "WHISPER", target) end
    elseif scope == "say" or scope == "yell" then
        C_ChatInfo.SendAddonMessage(PREFIX, payload, scope == "yell" and "YELL" or "SAY")
    else -- "global"
        if lib._channelIndex then
            C_ChatInfo.SendAddonMessage(PREFIX, payload, "CHANNEL", lib._channelIndex)
        else
            trace("send", "DROP global (canal pas prêt) : " .. payload:sub(1, 40))
        end
    end
end

function lib:_Pump()
    if self._sendBusy then return end
    local item = table.remove(self._sendQueue, 1)
    if not item then return end
    trace("send", (item.scope or "global") .. (item.target and ("→" .. item.target) or "") .. " : " .. item.payload:sub(1, 60))
    rawSend(item.payload, item.scope, item.target)
    self._sendBusy = true
    if C_Timer and C_Timer.After then
        C_Timer.After(SEND_INTERVAL, function() lib._sendBusy = false; lib:_Pump() end)
    else
        self._sendBusy = false
    end
end

-- scope : "global" (défaut) | "guild" | "say" | "yell" | "whisper" (requiert target).
function lib:Send(payload, scope, target)
    if not payload or payload == "" then return end
    self._sendQueue[#self._sendQueue + 1] = { payload = payload, scope = scope or "global", target = target }
    self:_Pump()
end

-- ------------------------------------------------------------------
-- Réception : dispatch par verbe
-- ------------------------------------------------------------------
function lib:_Dispatch(sender, message, distribution)
    if not message or message == "" then return end
    local verb = message:match("^([A-Z]+)")
    local list = verb and self._handlers[verb]
    local who = playerShort(sender)
    trace("recv", (distribution or "?") .. " " .. tostring(who) .. " : " .. message:sub(1, 60) .. (list and "" or " (verbe inconnu)"))
    if list then
        for _, fn in ipairs(list) do pcall(fn, who, message, distribution) end
    end
end

-- ------------------------------------------------------------------
-- Démarrage : enregistre le préfixe + les events, rejoint le canal. Idempotent.
-- ------------------------------------------------------------------
function lib:StartTransport()
    if self._transportStarted then return end
    if not (C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix) then return end
    self._transportStarted = true
    C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)

    local me = UnitName and UnitName("player") or "?"
    local f = CreateFrame("Frame", "CraftLinkTransportFrame")
    f:RegisterEvent("CHAT_MSG_ADDON")
    f:RegisterEvent("CHAT_MSG_CHANNEL_JOIN")
    f:RegisterEvent("CHAT_MSG_CHANNEL_LEAVE")
    f:SetScript("OnEvent", function(_, event, ...)
        if event == "CHAT_MSG_ADDON" then
            local prefix, message, distribution, sender = ...
            if prefix == PREFIX and playerShort(sender) ~= me then
                lib:_Dispatch(sender, message, distribution)
            end
        else
            -- CHANNEL_JOIN/_LEAVE : arg2 = joueur, arg8 = numéro de canal, arg9 = nom de base.
            local who      = select(2, ...)
            local chanNum  = select(8, ...)
            local chanName = select(9, ...)
            local mine = (chanName and chanName:upper() == CHANNEL_NAME:upper())
                      or (lib._channelIndex and chanNum == lib._channelIndex)
            if mine and lib._presenceCb then
                local kind = (event == "CHAT_MSG_CHANNEL_JOIN") and "join" or "leave"
                trace("pres", kind .. " " .. tostring(playerShort(who)))
                pcall(lib._presenceCb, kind, playerShort(who))
            end
        end
    end)

    self:JoinNetwork()
    if C_Timer and C_Timer.NewTicker then
        C_Timer.NewTicker(WATCHDOG, function() lib:_Watchdog() end)
    end
end
