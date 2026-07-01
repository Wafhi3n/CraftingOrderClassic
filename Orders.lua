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
--   ORD|NACK|id|crafter   (refus/désistement : l'artisan ne prend pas — ou relâche — la commande)

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
local KEYWORD_RCPT = { Tous = true, Guilde = true, Amis = true }

-- Sérialise un ORD|NEW (partagé par Broadcast et le push à la connexion). Dernier champ = liste CSV
-- des itemID que l'ACHETEUR fournit (vide si aucun) → l'artisan voit « À FOURNIR » vs déjà fournis.
function Orders:_NewPayload(o)
    return string.format("ORD|NEW|%s|%s|%s|%d|%d|%s|%s|%s|%d|%s",
        o.id, o.buyer, o.kind, o.itemID or o.spellID or 0, o.qty or 1,
        o.profession or "", (o.price or ""):gsub("|", ""),
        (o.recipient or "Tous"):gsub("|", ""), o.byStack and 1 or 0,
        table.concat(o.provided or {}, ","))
end

-- Un joueur (de mon annuaire) entre-t-il dans la portée d'un ordre ? Tous / guilde-amis / nommé.
-- Guilde/Amis = drapeaux de relation (isGuild/isFriend) → marche aussi pour un artisan AJOUTÉ qui est
-- ami/guildmate en jeu (sinon « added » l'exclurait à tort).
function Orders:_ScopeMatch(o, name, r)
    local rcpt = o.recipient or "Tous"
    if rcpt == "Tous"   then return true end
    if rcpt == "Guilde" then return r ~= nil and (r.isGuild  or r.source == "guild")  == true end
    if rcpt == "Amis"   then return r ~= nil and (r.isFriend or r.source == "friend") == true end
    return name == rcpt                                       -- ordre nommé sur un joueur précis
end

-- Artisans connus EN LIGNE concernés par un ordre → fanout whisper (le canal caché est peu fiable
-- sur PTR : on DOUBLE chaque NEW vers eux → livraison garantie sans dépendre du canal).
function Orders:_FanoutTargets(o)
    local D = COC.Directory
    if not (D and D.roster and D.online) then return {} end
    local m, out = me(), {}
    for name, r in pairs(D.roster) do
        if name ~= m and D.online[name] and self:_ScopeMatch(o, name, r) then out[name] = true end
    end
    return out
end

-- Cibles dirigées (whisper) pour les transitions de cycle : ACK/DONE → l'acheteur ;
-- CANCEL → l'artisan qui avait accepté + le destinataire nommé. Fiable même canal HS.
function Orders:_CycleTargets(action, o)
    local t, m = {}, me()
    local function add(n) if n and n ~= "" and n ~= m and not KEYWORD_RCPT[n] then t[n] = true end end
    if action == "ACK" or action == "DONE" then add(o.buyer)
    elseif action == "CANCEL" then add(o.acceptedBy); add(o.recipient) end
    return t
end

function Orders:Broadcast(action, o)
    if not CraftLink then return end
    local payload
    if action == "NEW" then
        payload = self:_NewPayload(o)
    elseif action == "CANCEL" then payload = "ORD|CANCEL|" .. o.id
    elseif action == "ACK"    then payload = string.format("ORD|ACK|%s|%s", o.id, o.acceptedBy or "")
    elseif action == "DONE"   then payload = string.format("ORD|DONE|%s|%s", o.id, o.acceptedBy or "")
    end
    if not payload then return end
    CraftLink:Send(payload, "global")
    if action == "NEW" then
        if o.recipient == "Guilde" then CraftLink:Send(payload, "guild") end
        -- Fanout whisper vers les artisans connus EN LIGNE concernés (contourne le canal caché HS).
        for name in pairs(self:_FanoutTargets(o)) do CraftLink:Send(payload, "whisper", name) end
    else
        for name in pairs(self:_CycleTargets(action, o)) do CraftLink:Send(payload, "whisper", name) end
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
    if not o then pmsg(L["commande introuvable : "] .. tostring(id)); return end
    if o.buyer ~= me() then pmsg(L["ce n'est pas ta commande."]); return end
    o.status = "cancelled"; self:Broadcast("CANCEL", o)
    pmsg(L["commande annulée : "] .. id)
end

function Orders:Accept(id)
    local o = id and COC.db.orders[id]
    if not o or o.status ~= "open" then pmsg(L["commande non disponible : "] .. tostring(id)); return end
    if o.buyer == me() then pmsg(L["c'est ta propre commande."]); return end
    if not self:VisibleTo(o) then pmsg(L["cette commande ne t'est pas destinée."]); return end
    o.status = "accepted"; o.acceptedBy = me(); self:Broadcast("ACK", o)
    self:WhisperPub(o)
    pmsg(string.format(L["commande acceptée : %s (%s)"], id, itemName(o.itemID)))
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
    if not o then pmsg(L["commande introuvable : "] .. tostring(id)); return end
    if o.acceptedBy ~= me() then pmsg(L["tu n'as pas accepté cette commande."]); return end
    o.status = "done"; self:Broadcast("DONE", o)
    COC.db.delivered = (COC.db.delivered or 0) + 1   -- réputation v1 : compteur de crafts livrés
    pmsg(string.format(L["livrée ! crafts livrés au total : %d"], COC.db.delivered))
end

-- Refuser/relâcher une commande (bouton « Refuser » de la vue métier ; le clic droit ne fait que
-- masquer localement). Deux cas :
--   * je l'avais ACCEPTÉE → je me DÉSISTE : elle repasse en ouverte + NACK à l'acheteur (il est
--     prévenu, un autre artisan peut reprendre). C'est la mise à jour qui manquait.
--   * commande ouverte que je ne prends pas → masquée chez moi ; si elle me VISAIT nommément, NACK à
--     l'auteur (sinon silencieux : d'autres artisans la voient encore).
function Orders:Decline(o)
    if not (o and COC.db) then return end
    local m = me()
    if o.acceptedBy == m and o.status == "accepted" then
        o.status = "open"; o.acceptedBy = nil
        if CraftLink then
            CraftLink:Send("ORD|NACK|" .. o.id .. "|" .. m, "global")
            if o.buyer and o.buyer ~= m then CraftLink:Send("ORD|NACK|" .. o.id .. "|" .. m, "whisper", o.buyer) end
        end
        pmsg(L["commande relâchée : "] .. o.id)
    else
        COC.db.muted = COC.db.muted or {}; COC.db.muted[o.id] = true
        -- Refus d'une commande qui me visait NOMMÉMENT → j'alerte l'acheteur (il la verra « Refusée »).
        -- Portée large (Tous/Guilde/Amis) → silencieux : d'autres artisans la voient encore.
        if CraftLink and o.buyer and o.buyer ~= m and o.recipient == m then
            CraftLink:Send("ORD|NACK|" .. o.id .. "|" .. m, "whisper", o.buyer)
        end
    end
end

-- Action d'une ligne de commande dans la VUE MÉTIER (fenêtre de craft) : c'est LÀ qu'un artisan
-- accepte/livre — le Carnet ne fait que LISTER mes propres commandes. Renvoie (label, fn) ou nil.
function Orders:ProfRowAction(o)
    if not o then return nil end
    local m = me()
    if o.status == "open" and o.buyer ~= m and self:VisibleTo(o) then
        return L["Accepter"], function() Orders:Accept(o.id) end
    end
    if o.acceptedBy == m and o.status == "accepted" then
        return L["Livrer"], function() Orders:Deliver(o.id) end
    end
    return nil
end

-- ------------------------------------------------------------------
-- Réception (protocole) — met à jour le cache
-- ------------------------------------------------------------------
function Orders:OnNetwork(sender, message)
    local action = message:match("^ORD|([A-Z]+)|")
    if action == "NEW" then
        local id, buyer, kind, oid, qty, prof, price, recipient, byStack, prov =
            message:match("^ORD|NEW|([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|(%d*)|?([%d,]*)$")
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
        if prov and prov ~= "" then                       -- réactifs fournis par l'acheteur (CSV itemID)
            local t = {}; for d in prov:gmatch("%d+") do t[#t + 1] = tonumber(d) end
            o.provided = t
        end
        o.viaAddon   = true   -- reçue par le canal addon → l'auteur a l'addon (pas de whisper de pub)
        o.status     = o.status or "open"
        o.ts         = o.ts or time()
        COC.db.orders[id] = o
        if not existed and o.buyer ~= me() and o.status == "open" and self:_ShouldAlert(o) then
            self:AlertTargeted(o)   -- toast à la 1re réception (portée réglée par COC.db.notifyScope)
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
    elseif action == "NACK" then
        local id, who = message:match("^ORD|NACK|([^|]*)|(.*)$"); local o = id and COC.db.orders[id]
        if o and who ~= "" then
            if o.acceptedBy == who then
                o.status = "open"; o.acceptedBy = nil               -- l'artisan se désiste → réouverte
            elseif o.buyer == me() and o.recipient == who then
                o.status = "declined"; o.declinedBy = who           -- commande nommée refusée → refusée
            end
            if o.buyer == me() then
                local txt = string.format(L["%s a refusé ta commande : %s"], who, self:OrderName(o))
                pmsg(txt)
                if o.status == "declined" and COC.UI and COC.UI.Toast then
                    local Skin = COC.UI.Skin; COC.UI:Toast(txt, Skin and Skin.tex.fail)
                end
            end
        end
    elseif action == "SUGG" then self:_OnSuggest(message)
    end
    if COC.UI and COC.UI.Refresh then COC.UI:Refresh() end   -- maj live de la fenêtre si ouverte
    local PW = COC.ProfWindow
    if PW and PW.RefreshOrders and PW.frame and PW.frame:IsShown() then PW:RefreshOrders() end
end

-- Nudge « garde pour toi » (ORD|SUGG|id[|1]) : un pair me signale une commande de son cache que JE
-- saurais faire. « |1 » = captée /commerce·/guilde → viaAddon=false + captured. Alerte ssi H:ICanCraft.
function Orders:_OnSuggest(message)
    local id, cap = message:match("^ORD|SUGG|([^|]*)|?(%d*)$")
    local o = id and COC.db.orders[id]
    if not o then return end
    if cap == "1" then o.viaAddon = false; o.captured = true end
    local H = COC.Handoff
    if H and o.status == "open" and o.buyer ~= me() and o.recipient ~= me() and H:ICanCraft(o) then
        H:AlertCapable(o)
    end
end

-- Notifier (toast) à la 1re réception ? Selon COC.db.notifyScope : all(défaut)/directed/named/off ; cf. /co notify.
function Orders:_ShouldAlert(o)
    local m = (COC.db and COC.db.notifyScope) or "all"
    if m == "off" or (COC.db and COC.db.mutedPlayers and COC.db.mutedPlayers[o.buyer]) then return false end
    if o.recipient == me() then return true end                     -- nommée : toujours
    if m == "named" or not self:VisibleTo(o) then return false end   -- mode restreint / hors portée
    return (o.recipient and o.recipient ~= "" and o.recipient ~= "Tous") or m == "all"  -- Guilde/Amis vs large
end

-- Alerte « commande pour TOI » : un joueur t'a ciblé nommément (recipient == ton nom).
-- L'objet n'est peut-être pas encore en cache (GetItemInfo est ASYNCHRONE) → on retente (jusqu'à ~3 s)
-- après avoir déclenché son chargement, sinon l'alerte afficherait « item:2307 » au lieu du nom.
function Orders:AlertTargeted(o, tries)
    local nm  = self:OrderName(o)
    if (nm:match("^item:") or nm:match("^spell:")) and (tries or 0) < 10 then
        if o.itemID and GetItemInfo then GetItemInfo(o.itemID) end   -- amorce le chargement async
        if C_Timer then C_Timer.After(0.3, function() Orders:AlertTargeted(o, (tries or 0) + 1) end); return end
    end
    local Skin = COC.UI and COC.UI.Skin
    local qty = (Skin and Skin.QtySuffix(o)) or ""
    local pr  = o.price and (" — |cFFFFDD00" .. o.price .. "|r") or ""
    local msg = string.format(L["|cFFFFCC00commande pour TOI|r de |cFFFFFFFF%s|r : %s%s%s"], o.buyer, nm, qty, pr)
    pmsg((Skin and ("|T" .. Skin.tex.workorder .. ":0|t ") or "") .. msg)
    if COC.UI and COC.UI.Toast then COC.UI:Toast(msg) end
    pcall(function() PlaySound(SOUNDKIT and SOUNDKIT.TELL_MESSAGE or 3081, "Master") end)
    if COC.UI and COC.UI.Refresh then COC.UI:Refresh() end
end

-- Ré-émet MES commandes ouvertes/acceptées. Appelée sur HI reçu, (re)acquisition du canal (bring-up)
-- et par le ticker périodique : un porteur qui (re)joint le canal finit par les recevoir. Idempotent
-- côté récepteur (dédup par id). L'appelant peut jitter (anti-burst).
function Orders:RebroadcastMine()
    local m = me()
    for _, o in pairs(COC.db.orders or {}) do
        if o.buyer == m and (o.status == "open" or o.status == "accepted") then
            self:Broadcast("NEW", o)
        end
    end
end

-- Resync sur HI : je ré-annonce MES commandes ouvertes/acceptées (jitté, anti-burst).
function Orders:OnHello()
    if not (CraftLink and C_Timer) then return end
    C_Timer.After(math.random() * 3, function() Orders:RebroadcastMine() end)
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

-- Faut-il RELAYER cette commande à un pair `who` qu'on vient de découvrir ? On propage en MESH :
-- toute commande OUVERTE non expirée, MÊME d'un autre joueur, MÊME si je ne sais pas la crafter (le
-- but est qu'elle atteigne le bon artisan via les croisements). On ne relaie pas une commande à son
-- propre auteur, ni une commande NOMMÉE sur quelqu'un d'autre (ciblée → livraison directe seulement).
-- Chaque récepteur filtre l'AFFICHAGE via VisibleTo ; il peut quand même la re-relayer (cache complet).
function Orders:_RelayMatch(o, who)
    if o.status ~= "open" then return false end
    if o.captured then return false end   -- demande captée poussée vers MOI : ne pas la re-répandre
    if (time() - (o.ts or 0)) > ORDER_TTL then return false end
    if o.buyer == who then return false end
    local rcpt = o.recipient or "Tous"
    if rcpt == "Tous" or rcpt == "Guilde" or rcpt == "Amis" then return true end
    return rcpt == who                                   -- nommé : seulement vers la cible
end

-- Un artisan apparaît EN LIGNE (présence JOIN ou découverte whisper) : je lui RELAIE en direct
-- (whisper) les commandes ouvertes en cache qui le concernent → propagation P2P fiable même si le
-- canal caché est muet. Plafonné (anti-burst) ; la dédup par id côté récepteur évite les boucles.
function Orders:OnArtisanOnline(who)
    if not (who and CraftLink) then return end
    local sent = 0
    for _, o in pairs(COC.db.orders or {}) do
        if sent < 25 and self:_RelayMatch(o, who) then
            CraftLink:Send(self:_NewPayload(o), "whisper", who)
            sent = sent + 1
        end
    end
    -- Palier « garder pour un ami capable » : nudges « tu sais le faire » + forward des entrantes.
    if COC.Handoff then COC.Handoff:OnArtisanOnline(who) end
end

function Orders:PrintList()
    local all = self:All()
    local shown = 0
    pmsg(L["carnet d'ordres :"])
    for _, o in ipairs(all) do
        if o.status ~= "cancelled" then
            shown = shown + 1
            print(string.format("  |cFFFFFFFF%s|r  %s x%d  [%s]  |cFFFFCC00%s|r%s",
                o.id, self:OrderName(o), o.qty or 1, o.profession or "?",
                o.status, o.acceptedBy and (L[" par "] .. o.acceptedBy) or ""))
        end
    end
    if shown == 0 then pmsg(L["  (aucune commande active)"]) end
end

-- /co post <shift-clic objet> [xN] [prix libre]
function Orders:PostFromInput(rest)
    rest = rest or ""
    local itemID = tonumber(rest:match("item:(%d+)"))
    if not itemID then pmsg(L["usage : /co post [shift-clic objet] [xN] [prix]"]); return end
    local qty = tonumber(rest:match("[xX](%d+)")) or 1
    local price = rest:gsub("|c%x-|H.-|h.-|h|r", ""):gsub("|H.-|h.-|h", "")
                      :gsub("[xX]%d+", ""):gsub("^%s+", ""):gsub("%s+$", "")
    local o = self:Post(itemID, qty, price ~= "" and price or nil)
    if o then
        pmsg(string.format(L["commande postée |cFFFFFFFF%s|r : %s x%d %s[%s]"],
            o.id, itemName(itemID), qty, o.price and (o.price .. " ") or "", o.profession or "?"))
    end
end

-- ------------------------------------------------------------------
-- Diagnostic réseau (/co ping) : aller-retour visible pour vérifier que le canal global marche.
-- Les messages réseau sont des AddonMessage (INVISIBLES dans le chat) — on ne « voit » donc jamais
-- le trafic ; ce ping le rend lisible : moi → PING global, chaque porteur → PONG dirigé en retour.
-- ------------------------------------------------------------------
function Orders:Ping()
    if not CraftLink then pmsg(L["CraftLink absent — l'infra réseau n'est pas chargée."]); return end
    local ts = me() .. "|" .. time()
    CraftLink:Send("PING|" .. ts, "global")
    -- Double en whisper vers les porteurs CONNUS en ligne (canal global peu fiable sur PTR à 2 comptes).
    local D, m, count = COC.Directory, me(), 0
    if D and D.online and D.roster then
        for name in pairs(D.online) do
            if name ~= m and D.roster[name] then CraftLink:Send("PING|" .. ts, "whisper", name); count = count + 1 end
        end
    end
    pmsg(string.format(L["PING envoyé (canal %s%s). En attente des PONG…"],
        CraftLink:IsNetworkReady() and ("|cFF33DD33" .. L["rejoint"] .. "|r") or ("|cFFFF4444" .. L["PAS rejoint"] .. "|r"),
        count > 0 and string.format(L[", +|cFFFFFFFF%d|r whisper(s)"], count) or ""))
end

function Orders:OnPing(sender)
    if CraftLink and sender then CraftLink:Send("PONG|" .. me(), "whisper", sender) end   -- réponse silencieuse
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
    CraftLink:RegisterHandler("PING", function(s) Orders:OnPing(s) end)
    -- PONG : plus d'affichage chat (c'était du debug). Dir:OnPong gère la présence en coulisse.
    -- Ré-émission périodique de MES commandes ouvertes/acceptées : un porteur qui rejoint le canal
    -- sans envoyer de HI finit par les recevoir (sinon il ne voit que ce qui est posté après lui).
    if C_Timer and C_Timer.NewTicker then
        C_Timer.NewTicker(REBROADCAST, function() Orders:RebroadcastMine() end)
    end
end
