-- Crafting Order - Classic — Orders : carnet d'ordres GLOBAL (modèle + cycle + protocole).
--
-- Un ordre = une demande de craft postée par un acheteur, visible/acceptable par n'importe quel
-- porteur de l'addon sur le royaume (canal global), sans guilde commune. Cycle :
--   poster (NEW) → accepter (ACK) → livrer (DONE) ; annuler (CANCEL) à tout moment par l'auteur.
--
-- Discipline cache : tout passe par COC.db.orders (persistant) ; l'UI (à venir) lira CE cache.
-- Protocole sur le transport CraftLink (portée "global" par défaut) :
--   ORD|NEW|id|buyer|kind|objId|qty|prof|price
--   ORD|CANCEL|id
--   ORD|ACK|id|crafter
--   ORD|DONE|id|crafter

local COC = CraftingOrderClassic
local Orders = {}
COC.Orders = Orders
local L = COC.L

local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)

local ORDER_TTL  = 6 * 3600   -- 6 h : au-delà, une commande OUVERTE est tenue pour expirée (cachée/élaguée)
local REBROADCAST = 2 * 3600  -- 2 h : ré-émission périodique de MES commandes ouvertes (anti-oubli réseau)

local function me()  return (UnitName and UnitName("player")) or "?" end
local function pmsg(m) print("|cFF33DD88Crafting Order|r " .. m) end
local function itemName(id) return (id and GetItemInfo and (GetItemInfo(id))) or (id and ("item:" .. id)) or "?" end

-- Métier qui produit cet itemID (depuis le catalogue itemToSpell), ou nil.
function Orders:ProfForItem(itemID)
    if not (CraftLink and itemID) then return nil end
    for prof in pairs(CraftLink.professions or {}) do
        local i2s = CraftLink:ItemToSpell(prof)
        if i2s and i2s[itemID] then return prof end
    end
    return nil
end

-- ------------------------------------------------------------------
-- Émission (protocole)
-- ------------------------------------------------------------------
function Orders:Broadcast(action, o)
    if not CraftLink then return end
    local payload
    if action == "NEW" then
        payload = string.format("ORD|NEW|%s|%s|%s|%d|%d|%s|%s|%s|%d",
            o.id, o.buyer, o.kind, o.itemID or o.spellID or 0, o.qty or 1,
            o.profession or "", (o.price or ""):gsub("|", ""),
            (o.recipient or "Tous"):gsub("|", ""), o.byStack and 1 or 0)
    elseif action == "CANCEL" then payload = "ORD|CANCEL|" .. o.id
    elseif action == "ACK"    then payload = string.format("ORD|ACK|%s|%s", o.id, o.acceptedBy or "")
    elseif action == "DONE"   then payload = string.format("ORD|DONE|%s|%s", o.id, o.acceptedBy or "")
    end
    if payload then
        CraftLink:Send(payload, "global")
        -- Portée guilde : on double l'envoi sur le transport GUILD pour toucher les membres qui ne
        -- sont pas sur le canal caché (Amis/@Nom restent un filtre de réception, pas de transport dédié).
        if action == "NEW" and o.recipient == "Guilde" then CraftLink:Send(payload, "guild") end
    end
end

-- Routage par destinataire. Le canal étant global, tout le monde REÇOIT tout : ce filtre décide ce
-- qui m'est destiné (affichage Carnet + acceptation). Valeurs canoniques (FR) côté réseau : "Tous",
-- "Guilde", "Amis", ou un nom de joueur. NB : "Guilde"/"Amis" s'évaluent via MES relations (buyer ∈
-- ma guilde / mes amis) — best-effort v1 (on ne connaît pas les relations du posteur).
function Orders:VisibleTo(o, who)
    who = who or me()
    local rcpt = o.recipient
    if not rcpt or rcpt == "" or rcpt == "Tous" then return true end
    if o.buyer == who then return true end          -- ma propre commande : toujours visible
    if rcpt == who then return true end             -- ciblée nommément sur moi (@Nom)
    local D = COC.Directory
    if rcpt == "Guilde" then return (D and D._guildSet  and D._guildSet[o.buyer]) == true end
    if rcpt == "Amis"   then return (D and D._friendSet and D._friendSet[o.buyer]) == true end
    return false                                    -- ciblée sur un AUTRE joueur → pas pour moi
end

-- ------------------------------------------------------------------
-- Cycle (actions locales → diffusion)
-- ------------------------------------------------------------------
local function genId()
    COC.db.orderSeq = (COC.db.orderSeq or 0) + 1
    return me() .. "-" .. COC.db.orderSeq
end

-- opts (optionnel) : { spellID, profession, provided = { itemID,... } } depuis l'UI Poster.
function Orders:Post(itemID, qty, price, opts)
    if not (itemID and COC.db) then return nil end
    opts = opts or {}
    local o = {
        id = genId(), buyer = me(), kind = "item", itemID = itemID,
        qty = qty or 1, price = price,
        profession = opts.profession or self:ProfForItem(itemID),
        spellID = opts.spellID, provided = opts.provided,   -- réactifs fournis (local v1)
        status = "open", ts = time(),
    }
    COC.db.orders[o.id] = o
    self:Broadcast("NEW", o)
    return o
end

-- Poste depuis une entrée de catalogue : objet (itemID) OU service/enchant (spellID seul).
function Orders:PostEntry(entry, qty, price, opts)
    if not (entry and COC.db) then return nil end
    opts = opts or {}
    local o = {
        id = genId(), buyer = me(),
        kind = entry.itemID and "item" or "enchant",
        itemID = entry.itemID, spellID = entry.spellID,
        qty = qty or 1, price = price,
        profession = opts.profession or (entry.itemID and self:ProfForItem(entry.itemID)),
        provided = opts.provided, recipient = opts.recipient, byStack = opts.byStack,
        status = "open", ts = time(),
    }
    COC.db.orders[o.id] = o
    self:Broadcast("NEW", o)
    return o
end

-- Nom affichable d'un ordre : objet (GetItemInfo) ou enchant (GetSpellInfo). Multilingue.
function Orders:OrderName(o)
    local c = CraftLink
    if o.itemID then return c and c:ItemName(o.itemID) or ("item:" .. o.itemID) end
    if o.spellID then return c and c:RecipeName(o.spellID) or ("spell:" .. o.spellID) end
    return "?"
end

function Orders:Cancel(id)
    local o = id and COC.db.orders[id]
    if not o then pmsg("commande introuvable : " .. tostring(id)); return end
    if o.buyer ~= me() then pmsg("ce n'est pas ta commande."); return end
    o.status = "cancelled"; self:Broadcast("CANCEL", o)
    pmsg("commande annulée : " .. id)
end

function Orders:Accept(id)
    local o = id and COC.db.orders[id]
    if not o or o.status ~= "open" then pmsg("commande non disponible : " .. tostring(id)); return end
    if o.buyer == me() then pmsg("c'est ta propre commande."); return end
    if not self:VisibleTo(o) then pmsg("cette commande ne t'est pas destinée."); return end
    o.status = "accepted"; o.acceptedBy = me(); self:Broadcast("ACK", o)
    self:WhisperPub(o)
    pmsg(string.format("commande acceptée : %s (%s)", id, itemName(o.itemID)))
end

-- Pub : si l'auteur N'A PAS l'addon (commande captée dans /trade ou /g, pas reçue par le réseau),
-- on le prévient par whisper → l'acceptation lui parvient ET ça fait connaître l'addon.
-- Les commandes reçues via le canal addon portent o.viaAddon=true → pas de whisper (ACK suffit).
function Orders:WhisperPub(o)
    if not (SendChatMessage and o.buyer and o.buyer ~= me()) then return end
    if o.viaAddon or o.fake then return end
    local what = self:OrderName(o)
    local msg = "I accept your order of " .. what
        .. (o.price and (" costing " .. o.price) or "") .. " — via Crafting Order Classic"
    SendChatMessage(msg, "WHISPER", nil, o.buyer)
end

function Orders:Deliver(id)
    local o = id and COC.db.orders[id]
    if not o then pmsg("commande introuvable : " .. tostring(id)); return end
    if o.acceptedBy ~= me() then pmsg("tu n'as pas accepté cette commande."); return end
    o.status = "done"; self:Broadcast("DONE", o)
    COC.db.delivered = (COC.db.delivered or 0) + 1   -- réputation v1 : compteur de crafts livrés
    pmsg(string.format("livrée ! crafts livrés au total : %d", COC.db.delivered))
end

-- ------------------------------------------------------------------
-- Réception (protocole) — met à jour le cache
-- ------------------------------------------------------------------
function Orders:OnNetwork(sender, message)
    local action = message:match("^ORD|([A-Z]+)|")
    if action == "NEW" then
        local id, buyer, kind, oid, qty, prof, price, recipient, byStack =
            message:match("^ORD|NEW|([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|(%d*)$")
        if not id or id == "" then return end
        local existed = COC.db.orders[id] ~= nil   -- déjà connue ? (anti-spam sur re-broadcast)
        local o = COC.db.orders[id] or {}
        o.id, o.buyer, o.kind = id, buyer, (kind ~= "" and kind) or "item"
        if o.kind == "enchant" then o.spellID = tonumber(oid) else o.itemID = tonumber(oid) end
        o.qty        = tonumber(qty) or 1
        o.profession = (prof ~= "" and prof) or nil
        o.price      = (price ~= "" and price) or nil
        o.recipient  = (recipient and recipient ~= "" and recipient) or "Tous"
        o.byStack    = byStack == "1"
        o.viaAddon   = true   -- reçue par le canal addon → l'auteur a l'addon (pas de whisper de pub)
        o.status     = o.status or "open"
        o.ts         = o.ts or time()
        COC.db.orders[id] = o
        -- Ciblage : une commande qui me nomme explicitement → alerte forte (1re réception seulement).
        if not existed and o.buyer ~= me() and o.recipient == me() and o.status == "open" then
            self:AlertTargeted(o)
        end
    elseif action == "CANCEL" then
        local id = message:match("^ORD|CANCEL|(.+)$"); local o = id and COC.db.orders[id]
        if o then o.status = "cancelled" end
    elseif action == "ACK" then
        local id, crafter = message:match("^ORD|ACK|([^|]*)|(.*)$"); local o = id and COC.db.orders[id]
        if o then o.status = "accepted"; o.acceptedBy = (crafter ~= "" and crafter) or nil end
    elseif action == "DONE" then
        local id, crafter = message:match("^ORD|DONE|([^|]*)|(.*)$"); local o = id and COC.db.orders[id]
        if o then o.status = "done"; o.acceptedBy = (crafter ~= "" and crafter) or o.acceptedBy end
    end
    if COC.UI and COC.UI.Refresh then COC.UI:Refresh() end   -- maj live de la fenêtre si ouverte
    local PW = COC.ProfWindow
    if PW and PW.RefreshOrders and PW.frame and PW.frame:IsShown() then PW:RefreshOrders() end
end

-- Alerte « commande pour TOI » : un joueur t'a ciblé nommément (recipient == ton nom).
function Orders:AlertTargeted(o)
    local nm  = self:OrderName(o)
    local qty = (o.qty and o.qty > 1) and (" ×" .. o.qty) or ""
    local pr  = o.price and (" — |cFFFFDD00" .. o.price .. "|r") or ""
    local msg = string.format(L["|cFFFFCC00◆ commande pour TOI|r de |cFFFFFFFF%s|r : %s%s%s"], o.buyer, nm, qty, pr)
    pmsg(msg)
    if COC.UI and COC.UI.Toast then COC.UI:Toast(msg) end
    pcall(function() PlaySound(SOUNDKIT and SOUNDKIT.TELL_MESSAGE or 3081, "Master") end)
    if COC.UI and COC.UI.Refresh then COC.UI:Refresh() end
end

-- Resync sur HI : je ré-annonce MES commandes ouvertes/acceptées (jitté, anti-burst).
function Orders:OnHello()
    if not (CraftLink and C_Timer) then return end
    C_Timer.After(math.random() * 3, function()
        for _, o in pairs(COC.db.orders or {}) do
            if o.buyer == me() and (o.status == "open" or o.status == "accepted") then
                Orders:Broadcast("NEW", o)
            end
        end
    end)
end

-- ------------------------------------------------------------------
-- Lecture (cache) + commandes texte (avant l'UI)
-- ------------------------------------------------------------------
function Orders:All()
    local out, who, now = {}, me(), time()
    for _, o in pairs(COC.db.orders or {}) do
        -- Masque les commandes OUVERTES expirées (TTL) et celles qui ne me sont pas destinées (routage).
        local expired = o.status == "open" and (now - (o.ts or now)) > ORDER_TTL
        if not expired and self:VisibleTo(o, who) then out[#out + 1] = o end
    end
    table.sort(out, function(a, b) return (a.ts or 0) > (b.ts or 0) end)
    return out
end

-- Élague du cache les commandes ouvertes trop vieilles (sauf les miennes, gardées pour réémission).
function Orders:PruneExpired()
    if not COC.db then return end
    local now = time()
    for id, o in pairs(COC.db.orders or {}) do
        if o.status == "open" and o.buyer ~= me() and (now - (o.ts or now)) > ORDER_TTL then
            COC.db.orders[id] = nil
        end
    end
end

-- Un artisan se connecte (présence JOIN) : si j'ai une commande OUVERTE qui le cible nommément, je la
-- lui (re)pousse — il était peut-être hors-ligne au moment du post. Jitté (anti-burst).
function Orders:OnArtisanOnline(who)
    if not (who and CraftLink and C_Timer) then return end
    for _, o in pairs(COC.db.orders or {}) do
        if o.buyer == me() and o.status == "open" and o.recipient == who then
            C_Timer.After(math.random() * 2, function() Orders:Broadcast("NEW", o) end)
        end
    end
end

function Orders:PrintList()
    local all = self:All()
    local shown = 0
    pmsg("carnet d'ordres :")
    for _, o in ipairs(all) do
        if o.status ~= "cancelled" then
            shown = shown + 1
            print(string.format("  |cFFFFFFFF%s|r  %s x%d  [%s]  |cFFFFCC00%s|r%s",
                o.id, self:OrderName(o), o.qty or 1, o.profession or "?",
                o.status, o.acceptedBy and (" par " .. o.acceptedBy) or ""))
        end
    end
    if shown == 0 then pmsg("  (aucune commande active)") end
end

-- /co post <shift-clic objet> [xN] [prix libre]
function Orders:PostFromInput(rest)
    rest = rest or ""
    local itemID = tonumber(rest:match("item:(%d+)"))
    if not itemID then pmsg("usage : /co post [shift-clic objet] [xN] [prix]"); return end
    local qty = tonumber(rest:match("[xX](%d+)")) or 1
    local price = rest:gsub("|c%x-|H.-|h.-|h|r", ""):gsub("|H.-|h.-|h", "")
                      :gsub("[xX]%d+", ""):gsub("^%s+", ""):gsub("%s+$", "")
    local o = self:Post(itemID, qty, price ~= "" and price or nil)
    if o then
        pmsg(string.format("commande postée |cFFFFFFFF%s|r : %s x%d %s[%s]",
            o.id, itemName(itemID), qty, o.price and (o.price .. " ") or "", o.profession or "?"))
    end
end

-- ------------------------------------------------------------------
-- Démarrage
-- ------------------------------------------------------------------
function Orders:Start()
    if not (COC.db and CraftLink) then return end
    COC.db.orders = COC.db.orders or {}
    self:PruneExpired()                                  -- entretien au démarrage
    CraftLink:RegisterHandler("ORD", function(s, m) Orders:OnNetwork(s, m) end)
    CraftLink:RegisterHandler("HI",  function() Orders:OnHello() end)
    -- Ré-émission périodique de MES commandes ouvertes/acceptées : un porteur qui rejoint le canal
    -- sans envoyer de HI finit par les recevoir (sinon il ne voit que ce qui est posté après lui).
    if C_Timer and C_Timer.NewTicker then
        C_Timer.NewTicker(REBROADCAST, function()
            for _, o in pairs(COC.db.orders or {}) do
                if o.buyer == me() and (o.status == "open" or o.status == "accepted") then
                    Orders:Broadcast("NEW", o)
                end
            end
        end)
    end
end
