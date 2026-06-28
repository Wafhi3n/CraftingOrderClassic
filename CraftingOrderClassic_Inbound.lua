-- CraftingOrderClassic_Inbound.lua — couche réseau « passive » : capte les demandes de craft
-- postées dans /commerce (Trade) et /guilde par des joueurs SANS l'addon, alerte le joueur, et
-- les range dans une file « Entrantes » (acceptable / ignorable). Calqué sur le scanner de Guild
-- Economy (TradeScanner). Ces commandes portent viaAddon=false → l'acceptation déclenche un
-- whisper de pub (cf. Orders:WhisperPub).

local COC     = CraftingOrderClassic
local Inbound = {}
COC.Inbound   = Inbound

local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)

local EXPIRY   = 1800   -- 30 min
local MAX_IN   = 60

-- Mots-clés « demande » (FR + EN). Un message doit en contenir un + un lien d'objet CRAFTABLE.
local KW_REQUEST = {
    "WTB", "ACH", "ACHAT", "BUY", "B>", "CHERCHE", "RECHERCHE", "ISO", "LF ", "LFW",
    "NEED", "BESOIN", "CRAFT", "ENCHANT", "RECETTE", "FABRIQU",
}

local function me() return (UnitName and UnitName("player")) or "?" end
local function pmsg(m) print("|cFF33DD88Crafting Order|r " .. m) end

local function StripMarkup(msg)
    msg = msg:gsub("|H.-|h%[.-%]|h", " "):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    return msg
end

local function HasRequestKW(msg)
    local up = " " .. msg:upper() .. " "
    for _, kw in ipairs(KW_REQUEST) do if up:find(kw, 1, true) then return true end end
    return false
end

local function ExtractItemIDs(msg)
    local ids = {}
    for itemKey in msg:gmatch("|H(item:%d+[^|]*)|h") do
        local id = tonumber(itemKey:match("item:(%d+)"))
        if id then ids[#ids + 1] = id end
    end
    return ids
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
function Inbound:OnChat(msg, player, source)
    if not (msg and player) or player == me() then return end
    if not HasRequestKW(msg) then return end
    local ids = ExtractItemIDs(msg)
    if #ids == 0 then return end
    local Orders = COC.Orders
    for _, itemID in ipairs(ids) do
        local prof = Orders and Orders:ProfForItem(itemID)
        if prof then   -- objet réellement fabricable → c'est une demande de craft
            local canCraft = CraftLink and CraftLink:IKnowRecipeForItem(prof, itemID) or false
            self:Add({
                buyer = player, itemID = itemID, qty = ExtractQty(msg),
                price = ExtractPrice(msg), profession = prof, source = source,
                canCraft = canCraft, raw = msg,
            })
        end
    end
end

function Inbound:Add(e)
    if not COC.db then return end
    COC.db.inbound = COC.db.inbound or {}
    local id = e.buyer .. "_" .. e.itemID
    local existing = COC.db.inbound[id]
    e.id = id; e.ts = time()
    e.status = (existing and existing.status == "dismissed") and "dismissed" or (existing and existing.status) or "new"
    COC.db.inbound[id] = e
    -- Purge des trop vieilles / cap.
    local n = 0
    for k, v in pairs(COC.db.inbound) do
        if (time() - (v.ts or 0)) > EXPIRY then COC.db.inbound[k] = nil else n = n + 1 end
    end
    if e.status == "new" then self:Alert(e) end
    if COC.UI and COC.UI.Refresh then COC.UI:Refresh() end
end

function Inbound:Alert(e)
    local c = CraftLink
    local nm = (c and c:ItemName(e.itemID)) or ("item:" .. e.itemID)
    local src = (e.source == "guild") and "guilde" or "commerce"
    local qty = (e.qty and e.qty > 1) and (" ×" .. e.qty) or ""
    local pr  = e.price and (" — |cFFFFDD00" .. e.price .. "|r") or ""
    pmsg(string.format("|cFFFF8800◆ entrante|r |cFFFFFFFF%s|r (%s) : %s%s%s",
        e.buyer, src, nm, qty, pr))
    if e.canCraft then print("   |cFF33DD33→ tu sais la crafter|r — Carnet › Entrantes") end
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
    -- Whisper de pub : l'auteur n'a pas l'addon, on le prévient (et on fait connaître l'addon).
    if COC.Orders then COC.Orders:WhisperPub({ buyer = e.buyer, itemID = e.itemID, price = e.price }) end
    pmsg("entrante acceptée — réponse envoyée à |cFFFFFFFF" .. e.buyer .. "|r")
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
    if COC.db.scanInbound == nil then COC.db.scanInbound = true end
    COC.db.inbound = COC.db.inbound or {}
    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_CHANNEL")
    f:RegisterEvent("CHAT_MSG_GUILD")
    f:SetScript("OnEvent", function(_, event, msg, player, _, channelName)
        if not COC.db.scanInbound then return end
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
