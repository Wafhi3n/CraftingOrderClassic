-- CraftingOrderClassic_Inbound.lua — couche réseau « passive » : capte les demandes de craft
-- postées dans /commerce (Trade) et /guilde par des joueurs SANS l'addon, alerte le joueur, et
-- les range dans une file « Entrantes » (acceptable / ignorable). Calqué sur le scanner de Guild
-- Economy (TradeScanner). Ces commandes portent viaAddon=false ; l'acceptation ne prévient plus
-- automatiquement le demandeur (WhisperPub retiré, v1.2.0) — à faire manuellement dans le chat.

local COC     = CraftingOrderClassic
local Inbound = {}
COC.Inbound   = Inbound
local L       = COC.L

local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)

local EXPIRY   = 1800   -- 30 min
local MAX_IN   = 60

-- Mots-clés « demande d'achat / de craft » (FR + EN). STEM = sous-chaîne (conjugaisons : achat,
-- achète, cherchent, crafting…) ; TOKEN = mot ENTIER requis pour les sigles courts ambigus
-- (sinon « ACH » ⊂ « eACH », « LF » ⊂ « woLF », « ISO » ⊂ « comparISOn »).
local KW_REQ_STEM  = { "ACHAT", "ACHET", "CHERCHE", "RECHERCHE", "BESOIN", "FABRIQU", "RECETTE", "ENCHANT", "CRAFT", "BUY", "NEED" }
local KW_REQ_TOKEN = { "WTB", "WTC", "ISO", "LF", "B>" }
-- Mots-clés « OFFRE » (vente OU service d'artisan) : si présents → ce n'est PAS une demande, on
-- ignore. WTS = vendre ; LFW = « looking for work » (un ARTISAN qui propose ses services, pas un
-- client) ; « your mats » = il craft avec TES réactifs. NB : « LF » (looking for) reste une demande.
-- OFFER/PROPOSE : un artisan qui annonce « Crafting [X], also offer... » matche le stem CRAFT
-- (demande) sans jamais contenir WTS/VEND ; OFFER/PROPOSE lève l'ambiguïté (bug 2026-07-01).
local KW_OFFER     = { "WTS", "VDS", "S>", "VEND", "SELL", "LFW", "YOUR MATS", "VOS MATS", "OFFER", "PROPOSE" }
-- Verbes d'OFFRE en TÊTE de message : un artisan qui annonce son service commence par « Crafting [X]
-- for … », « Making … », « Can craft … » (≠ un client « WTB [X] » / « need [X] crafted »). Lève
-- l'ambiguïté du stem CRAFT, présent dans « Crafting » (offre) comme dans « crafted » (demande) —
-- cas réel manqué : « Crafting [Mageweave Bag] 12 slot for 22 [Mageweave Cloth] at org bank ».
local KW_OFFER_LEAD = { "CRAFTING", "MAKING", "CAN CRAFT", "CAN MAKE", "I CRAFT", "I MAKE", "I CAN CRAFT", "I CAN MAKE" }

local function me() return (UnitName and UnitName("player")) or "?" end
local function pmsg(m) print("|cFF33DD88Crafting Order|r " .. m) end

local function StripMarkup(msg)
    msg = msg:gsub("|H.-|h%[.-%]|h", " "):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    return msg
end

-- Le mot-clé est-il un MOT ENTIER (non collé à une lettre/chiffre) ? Évite ACH⊂EACH, LF⊂WOLF.
local function findToken(up, kw)
    local s = up:find(kw, 1, true)
    while s do
        local b, a = up:sub(s - 1, s - 1), up:sub(s + #kw, s + #kw)
        if not b:match("%w") and not a:match("%w") then return true end
        s = up:find(kw, s + 1, true)
    end
    return false
end

local function HasRequestKW(msg)
    local up = " " .. msg:upper() .. " "
    for _, kw in ipairs(KW_REQ_STEM)  do if up:find(kw, 1, true) then return true end end
    for _, kw in ipairs(KW_REQ_TOKEN) do if findToken(up, kw)    then return true end end
    return false
end

-- Offre (vente WTS, ou service d'artisan LFW / « your mats ») ? → jamais une commande entrante.
local function IsOffer(msg)
    local up = " " .. msg:upper() .. " "
    for _, kw in ipairs(KW_OFFER_LEAD) do
        if up:find("^%s*" .. kw) then return true end   -- « Crafting [X]… », « Making… » en tête = offre
    end
    for _, kw in ipairs(KW_OFFER) do
        if (#kw <= 3 and findToken(up, kw)) or (#kw > 3 and up:find(kw, 1, true)) then return true end
    end
    return false
end

-- IDs des objets liés + leur NOM affiché, tiré du lien lui-même (|Hitem:..|h[Nom]|h). Le nom vient
-- DU MESSAGE → aucune dépendance au cache client (corrige l'affichage « item:10050 » quand l'objet
-- n'est pas encore résolu par GetItemInfo). Renvoie une liste { id, name }.
local function ExtractItems(msg)
    local out = {}
    for itemStr, name in msg:gmatch("|H(item:%d+[^|]*)|h%[(.-)%]|h") do
        local id = tonumber(itemStr:match("item:(%d+)"))
        if id then out[#out + 1] = { id = id, name = name } end
    end
    return out
end

-- Prix libre lisible : « 12g 50s », « 5g », « 80s ». Renvoie une chaîne ou nil.
local function ExtractPrice(msg)
    msg = StripMarkup(msg)
    local g, s = msg:match("(%d+)%s*[gGpoPO]%s*(%d+)%s*[sSpaPA]")
    if g then return g .. "po " .. s .. "pa" end
    g = msg:match("(%d+)%s*[gGpoPO]%f[%A]")
    if g then return g .. "po" end
    s = msg:match("(%d+)%s*[sSpaPA]%f[%A]")
    if s then return s .. "pa" end
    return nil
end

local function ExtractQty(msg)
    msg = StripMarkup(msg)
    return tonumber(msg:match("[xX]%s*(%d+)")) or tonumber(msg:match("(%d+)%s*[xX]%f[%s%z]")) or 1
end

-- ------------------------------------------------------------------
-- Parsing
-- ------------------------------------------------------------------
-- Portée du scanner chat (COC.db.inboundScope, cf /co scan) :
--   mine (défaut) = SEULEMENT un métier que j'ai (mySkills) → aucun bruit pour un métier qu'on n'a pas ;
--   all = tout objet fabricable ; off = rien (court-circuité en amont).
local function scanScope() return (COC.db and COC.db.inboundScope) or "mine" end
function Inbound:_WantProf(prof)
    if scanScope() == "all" then return true end
    local D = COC.Directory
    return (D and D.mySkills and D.mySkills[prof]) ~= nil
end

function Inbound:OnChat(msg, player, source)
    if not (msg and player) or player == me() then return end
    if scanScope() == "off" then return end
    if IsOffer(msg) then return end              -- WTS (vente) ou LFW (artisan offrant) = pas une demande
    if not HasRequestKW(msg) then return end
    local items = ExtractItems(msg)
    if #items == 0 then return end
    local Orders = COC.Orders
    for _, it in ipairs(items) do
        local prof = Orders and Orders:ProfForItem(it.id)
        if prof and self:_WantProf(prof) then   -- objet fabricable dans un métier que je surveille
            local canCraft = CraftLink and CraftLink:IKnowRecipeForItem(prof, it.id) or false
            self:Add({
                buyer = player, itemID = it.id, itemName = it.name, qty = ExtractQty(msg),
                price = ExtractPrice(msg), profession = prof, source = source,
                canCraft = canCraft, raw = msg,
            })
        end
    end
end

function Inbound:Add(e)
    if not COC.db then return end
    if e.itemID and GetItemInfo then GetItemInfo(e.itemID) end   -- amorce le cache (nom localisé + rareté)
    COC.db.inbound = COC.db.inbound or {}
    local id = e.buyer .. "_" .. e.itemID
    local existing = COC.db.inbound[id]
    e.id = id; e.ts = time()
    e.status = (existing and existing.status == "dismissed") and "dismissed" or (existing and existing.status) or "new"
    COC.db.inbound[id] = e
    -- Purge des trop vieilles (EXPIRY) PUIS plafond MAX_IN (retire les plus anciennes) — anti-explosion
    -- mémoire sur un canal Commerce actif. `e` vient d'être posée (ts = maintenant) → jamais retirée.
    local survivors = {}
    for k, v in pairs(COC.db.inbound) do
        if (time() - (v.ts or 0)) > EXPIRY then COC.db.inbound[k] = nil
        else survivors[#survivors + 1] = { k = k, ts = v.ts or 0 } end
    end
    if #survivors > MAX_IN then
        table.sort(survivors, function(a, b) return a.ts > b.ts end)   -- plus récentes d'abord
        for i = MAX_IN + 1, #survivors do COC.db.inbound[survivors[i].k] = nil end
    end
    if e.status == "new" then self:Alert(e) end
    if e.status == "new" and COC.Moderation then COC.Moderation:NotePost(e.buyer) end   -- anti-spam
    -- « Garder pour un ami capable » : si un artisan connu sait la faire, on me le signale et on la
    -- lui pousse (maintenant s'il est en ligne, sinon à sa connexion via Handoff:OnArtisanOnline).
    if e.status == "new" and COC.Handoff then COC.Handoff:NoteInbound(e) end
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
end

function Inbound:Alert(e)
    -- Même discipline que les toasts P2P (Orders:_ShouldAlert) : « /co notify off » et les joueurs
    -- mutés ne déclenchent AUCUNE notif (chat/toast/son). L'entrée reste dans le Carnet › Entrantes.
    if COC.Moderation and COC.Moderation:IsMuted(e.buyer) then
        if COC.Trace then COC.Trace:Log("mod", "entrante silencée : " .. tostring(e.buyer) .. " (muté)") end
        return
    end
    if COC.db and (COC.db.notifyScope == "off"
        or (COC.db.mutedPlayers and COC.db.mutedPlayers[e.buyer])) then return end
    if COC.Moderation and COC.Moderation:BelowThreshold(e.buyer) then return end   -- petit perso (si connu)
    local c = CraftLink
    local nm = (c and c:ItemName(e.itemID, e.itemName)) or e.itemName or ("item:" .. e.itemID)
    local src = (e.source == "guild") and L["guilde"] or L["commerce"]
    local Skin = COC.UI and COC.UI.Skin
    local qty = (Skin and Skin.QtySuffix(e)) or ""
    local pr  = e.price and (" — |cFFFFDD00" .. e.price .. "|r") or ""
    local msg = string.format(L["|cFFFF8800entrante|r |cFFFFFFFF%s|r (%s) : %s%s%s"], e.buyer, src, nm, qty, pr)
    pmsg((Skin and ("|T" .. Skin.tex.workorder .. ":0|t ") or "") .. msg)
    if COC.UI and COC.UI.Toast then COC.UI:Toast(msg) end
    if e.canCraft then print(L["   |cFF33DD33→ tu sais la crafter|r — Carnet › Entrantes"]) end
    pcall(function() PlaySound(SOUNDKIT and SOUNDKIT.TELL_MESSAGE or 3081, "Master") end)
end

-- ------------------------------------------------------------------
-- Lecture + actions
-- ------------------------------------------------------------------
function Inbound:All()
    local out = {}
    for _, e in pairs(COC.db and COC.db.inbound or {}) do
        if e.status ~= "dismissed" then out[#out + 1] = e end
    end
    table.sort(out, function(a, b) return (a.ts or 0) > (b.ts or 0) end)
    return out
end

function Inbound:Count()
    local n = 0
    for _, e in pairs(COC.db and COC.db.inbound or {}) do if e.status == "new" then n = n + 1 end end
    return n
end

function Inbound:Accept(id)
    local e = id and COC.db.inbound and COC.db.inbound[id]; if not e then return end
    e.status = "accepted"
    pmsg(string.format(L["entrante acceptée : |cFFFFFFFF%s|r"], e.buyer))
    if COC.UI and COC.UI.Refresh then COC.UI:Refresh() end
end

function Inbound:Dismiss(id)
    local e = id and COC.db.inbound and COC.db.inbound[id]; if not e then return end
    e.status = "dismissed"
    if COC.UI and COC.UI.Refresh then COC.UI:Refresh() end
end

-- ------------------------------------------------------------------
-- Démarrage
-- ------------------------------------------------------------------
function Inbound:Start()
    if not COC.db then return end
    COC.db.inbound = COC.db.inbound or {}
    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_CHANNEL")
    f:RegisterEvent("CHAT_MSG_GUILD")
    f:SetScript("OnEvent", function(_, event, msg, player, _, channelName)
        if scanScope() == "off" then return end
        local who = player and (player:match("^([^%-]+)") or player)
        if event == "CHAT_MSG_CHANNEL" then
            local cn = (channelName or ""):lower()
            if cn:find("trade") or cn:find("commerce") or cn:find("échange") or cn:find("echange") then
                Inbound:OnChat(msg, who, "trade")
            end
        elseif event == "CHAT_MSG_GUILD" then
            Inbound:OnChat(msg, who, "guild")
        end
    end)
end
