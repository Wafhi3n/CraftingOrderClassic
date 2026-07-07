-- Orders_Net.lua — couche « fil réseau » du carnet d'ordres (protocole ORD|).
--
-- Extrait de Orders.lua (anti-monolithe) : ENCODAGE (Broadcast / _NewPayload + fanout par portée) et
-- DÉCODAGE (OnNetwork : NEW/CANCEL/ACK/DONE/NACK/SUGG → cache COC.db.orders). Les méthodes restent sur
-- la table COC.Orders (créée par Orders.lua, chargé AVANT) → appelées via self: depuis les deux fichiers.
-- Le cycle local (Post/Accept/Deliver/Cancel/Decline), l'alerting et les helpers restent dans Orders.lua.

local COC    = CraftingOrderClassic
local Orders = COC.Orders
local L      = COC.L

local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
local Codec     = COC.OrdersCodec   -- sérialisation ⇄ parsing ORD| (Orders_Codec.lua, chargé avant)

local function me()  return (UnitName and UnitName("player")) or "?" end
local function pmsg(m) print("|cFF33DD88Crafting Order|r " .. m) end

local KEYWORD_RCPT = { Tous = true, Guilde = true, Amis = true }

-- ------------------------------------------------------------------
-- Émission (encodage ORD| + routage par portée)
-- ------------------------------------------------------------------
-- Sérialise un ORD|NEW (partagé par Broadcast et le push à la connexion). Dernier champ = liste CSV
-- des itemID que l'ACHETEUR fournit (vide si aucun) → l'artisan voit « À FOURNIR » vs déjà fournis.
function Orders:_NewPayload(o)
    return Codec.Encode("NEW", o)
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

-- Cibles dirigées (whisper) pour les transitions de cycle. Sens des messages :
--   ACK/DLV : crafteur → ACHETEUR (j'accepte / j'ai remis) ;
--   DONE    : acheteur → CRAFTEUR (je confirme la réception → il est crédité) ;
--   CANCEL  : → l'artisan qui avait accepté + le destinataire nommé. Fiable même canal HS.
function Orders:_CycleTargets(action, o)
    local t, m = {}, me()
    local function add(n) if n and n ~= "" and n ~= m and not KEYWORD_RCPT[n] then t[n] = true end end
    if action == "ACK" or action == "DLV" then add(o.buyer)
    elseif action == "DONE" then add(o.acceptedBy)
    elseif action == "CANCEL" then add(o.acceptedBy); add(o.recipient) end
    return t
end

function Orders:Broadcast(action, o)
    if not CraftLink then return end
    local payload = Codec.Encode(action, o)   -- NEW/CANCEL/ACK/DLV/DONE (nil sinon)
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

-- ------------------------------------------------------------------
-- Réception (protocole) — met à jour le cache
-- ------------------------------------------------------------------
-- ORD|NEW : nouvelle commande (ou re-broadcast). Peuple/rafraîchit le cache + alerte si pertinent.
function Orders:_OnNew(message)
    local f = Codec.Decode(message)
    if not f or not f.id or f.id == "" then return end
    local id, buyer, kind, oid, qty, prof, price, recipient, byStack, prov =
        f.id, f.buyer, f.kind, f.oid, f.qty, f.prof, f.price, f.recipient, f.byStack, f.prov
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
    if not existed and o.buyer ~= me() and COC.Moderation then COC.Moderation:NotePost(o.buyer) end   -- anti-spam
    if not existed and o.buyer ~= me() and o.status == "open" and self:_ShouldAlert(o) then self:AlertTargeted(o) end
end

-- Transitions de cycle (CANCEL/ACK/DLV/DONE/NACK). Voir _CycleTargets pour le sens des messages.
-- `sender` = émetteur RÉEL (nom court, posé par le transport, non falsifiable) → on l'utilise pour
-- AUTORISER la transition, au lieu de faire confiance aveuglément au champ du payload (anti-griefing :
-- sans ça, n'importe quel porteur pouvait annuler la commande d'autrui ou usurper l'accepteur/refuseur).
function Orders:_OnCycle(action, message, sender)
    if action == "NACK" then return self:_OnNack(message, sender) end
    local f = Codec.Decode(message)
    local o = f and f.id and COC.db.orders[f.id]
    if not o then return end
    if action == "CANCEL" then
        if sender == o.buyer then o.status = "cancelled" end   -- seul l'AUTEUR peut annuler
    elseif action == "ACK" then
        o.status = "accepted"; o.acceptedBy = sender or (f.crafter ~= "" and f.crafter) or nil   -- l'accepteur = l'émetteur
    elseif action == "DLV" then
        -- Crafteur → acheteur : « j'ai remis ». Passe « remise » (pas encore terminée) ; côté acheteur
        -- on l'invite à confirmer la réception (bouton / auto-loot). L'émetteur EST le crafteur.
        if o.status ~= "done" then
            o.status = "delivered"; o.acceptedBy = sender or (f.crafter ~= "" and f.crafter) or o.acceptedBy
            if o.buyer == me() then self:AlertDelivered(o) end
        end
    elseif action == "DONE" then
        -- Acheteur → crafteur : confirmation de réception. Idempotent (DONE arrive en global ET whisper) :
        -- réputation créditée à la 1re transition vers « terminée », et seulement si JE suis le crafteur.
        -- SEUL l'acheteur peut confirmer (sinon un tiers pourrait gonfler la réputation d'un crafteur).
        if o.status ~= "done" and sender == o.buyer then
            o.acceptedBy = (f.crafter ~= "" and f.crafter) or o.acceptedBy   -- attesté par l'acheteur : qui créditer
            o.status = "done"
            if o.acceptedBy == me() then
                COC.db.delivered = (COC.db.delivered or 0) + 1   -- réputation : créditée à la confirmation acheteur
                if COC.Directory then COC.Directory:AnnounceSkills() end
                pmsg(string.format(L["réception confirmée par %s ! crafts livrés au total : %d"], o.buyer or "?", COC.db.delivered))
            end
        end
    end
end

-- ORD|NACK : refus/désistement d'un artisan. acceptedBy==who → réouverte ; ordre nommé à moi → refusée.
-- `who` = l'émetteur RÉEL (anti-spoof : sinon un tiers pouvait relâcher la commande acceptée par autrui).
function Orders:_OnNack(message, sender)
    local f = Codec.Decode(message); local o = f and f.id and COC.db.orders[f.id]
    local who = sender or (f and f.who)
    if not (o and who and who ~= "") then return end
    if o.acceptedBy == who then
        o.status = "open"; o.acceptedBy = nil                   -- l'artisan se désiste → réouverte
    elseif o.buyer == me() and o.recipient == who then
        o.status = "declined"; o.declinedBy = who               -- commande nommée refusée → refusée
    end
    if o.buyer == me() then
        local txt = string.format(L["%s a refusé ta commande : %s"], who, self:OrderName(o))
        pmsg(txt)
        if o.status == "declined" and COC.UI and COC.UI.Toast then
            local Skin = COC.UI.Skin; COC.UI:Toast(txt, Skin and Skin.tex.fail)
        end
    end
end

function Orders:OnNetwork(sender, message)
    local action = message:match("^ORD|([A-Z]+)|")
    if action == "NEW" then self:_OnNew(message)
    elseif action == "SUGG" then self:_OnSuggest(message)
    else self:_OnCycle(action, message, sender) end
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end   -- maj live coalescée (rafales de fanout)
    local PW = COC.ProfWindow
    if PW and PW.RefreshOrders and PW.frame and PW.frame:IsShown() then PW:RefreshOrders() end
end

-- Nudge « garde pour toi » (ORD|SUGG|id[|1]) : un pair me signale une commande de son cache que JE
-- saurais faire. « |1 » = captée /commerce·/guilde → viaAddon=false + captured. Alerte ssi H:ICanCraft.
function Orders:_OnSuggest(message)
    local f = Codec.Decode(message)
    local o = f and f.id and COC.db.orders[f.id]
    if not o then return end
    if f.captured == "1" then o.viaAddon = false; o.captured = true end
    -- Hors portée : ordre nommé à un TIERS précis → ne pas suggérer à moi (fuite d'info sur commande privée).
    local rcpt = o.recipient or "Tous"
    if not KEYWORD_RCPT[rcpt] and rcpt ~= me() then return end
    local H = COC.Handoff
    if H and o.status == "open" and o.buyer ~= me() and o.recipient ~= me() then
        if H:ICanCraft(o) then H:AlertCapable(o)
        else local alt = H:MyRerollCanCraft(o); if alt then H:AlertReroll(o, alt) end end
    end
end
