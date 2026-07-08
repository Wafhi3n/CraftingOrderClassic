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

-- Ce nom est-il un perso de MON compte ? (IsMyChar = MA SavedVariable, décision locale — cf.
-- Directory_Alts.) Sert à ne pas s'auto-alerter/anti-spammer sur les commandes de mes rerolls.
local function myChar(n) return n == me() or (COC.IsMyChar and COC:IsMyChar(n)) or false end

-- `a` agit-il pour `b` ? Lui-même, ou un perso de son set VÉRIFIÉ (réciprocité ALT : les deux
-- annonces sortent du même compte — une claim unilatérale ne lie JAMAIS, donc pas d'usurpation).
local function samePlayer(a, b)
    if not (a and b) then return false end
    if a == b then return true end
    local D = COC.Directory
    return (D and D.SamePlayer and D:SamePlayer(a, b)) == true
end

-- Ordre NOMMÉ (destinataire = un joueur précis, pas une portée Tous/Guilde/Amis).
local function isNamed(o)
    local rcpt = o and o.recipient
    return (rcpt and rcpt ~= "" and not KEYWORD_RCPT[rcpt]) == true
end

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
    -- Ordre NOMMÉ sur un joueur HORS LIGNE : whisper aussi son perso connecté VÉRIFIÉ (rerolls) —
    -- +1 cible max, uniquement sur lien mutuel (une claim unilatérale ne détourne jamais un whisper).
    local rcpt = o.recipient
    if rcpt and not KEYWORD_RCPT[rcpt] and rcpt ~= m and not D.online[rcpt] and D.OnlineCharOf then
        local alt = D:OnlineCharOf(rcpt)
        if alt and alt ~= m then out[alt] = true end
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
    elseif action == "DONE" then
        add(o.acceptedBy)
        -- L'accepteur a pu relog un reroll : whisper aussi son perso EN LIGNE vérifié (crédit fiable).
        local D = COC.Directory
        if o.acceptedBy and D and D.OnlineCharOf and not (D.online and D.online[o.acceptedBy]) then
            add(D:OnlineCharOf(o.acceptedBy))
        end
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
    if not existed and not myChar(o.buyer) and COC.Moderation then COC.Moderation:NotePost(o.buyer) end   -- anti-spam (pas sur mes rerolls)
    if not existed and not myChar(o.buyer) and o.status == "open" and self:_ShouldAlert(o) then self:AlertTargeted(o) end
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
        -- Seul l'AUTEUR peut annuler — ou un perso de son set VÉRIFIÉ (extension pure : jamais un tiers).
        if samePlayer(sender, o.buyer) then o.status = "cancelled" end
    elseif action == "ACK" then
        -- Un ACK ne s'applique qu'à un ordre OUVERT : ferme le vol d'attribution (re-ACK d'un ordre
        -- déjà accepté/livré/annulé/terminé pour s'en attribuer le crédit). Idempotent : la 2e copie
        -- (global + whisper) voit « accepted » et sort. Après un désistement NACK, l'ordre redevient
        -- « open » → un autre artisan peut ré-ACK (comportement voulu conservé).
        if o.status ~= "open" then return end
        -- Ordre NOMMÉ : seul le destinataire (ou son reroll VÉRIFIÉ) accepte — ferme le spoof
        -- « un tiers capture une commande privée ». Portées larges : premier arrivé (n'importe qui).
        if isNamed(o) and not samePlayer(sender, o.recipient) then return end
        o.status = "accepted"; o.acceptedBy = sender or (f.crafter ~= "" and f.crafter) or nil   -- l'accepteur = l'émetteur
    elseif action == "DLV" then
        -- Crafteur → acheteur : « j'ai remis ». Passe « remise » (pas terminée). Exclut « delivered »
        -- de l'entrée → idempotent (pas de double toast sur la copie global+whisper).
        if o.status ~= "done" and o.status ~= "delivered" then
            local ab = o.acceptedBy
            if isNamed(o) then
                -- NOMMÉ : autorisé au destinataire OU à l'accepteur (ou leurs rerolls liés). PAS de
                -- précondition de statut → préserve le cas « acheteur hors ligne pendant l'ACK » (chez
                -- lui l'ordre est encore « open », mais le vrai destinataire a le droit de livrer).
                if not (samePlayer(sender, o.recipient) or (ab and samePlayer(sender, ab))) then return end
            else
                -- PUBLIC : doit être passé par « accepted » PAR l'émetteur (ou son reroll lié) — ferme
                -- le DLV direct d'un tiers sur un ordre jamais accepté (vol d'attribution + réputation).
                if o.status ~= "accepted" or not (ab and samePlayer(sender, ab)) then return end
            end
            o.status = "delivered"
            -- Reroll qui livre (lié à l'accepteur) : on GARDE « accepté par X » ; sinon (nommé livré
            -- sans ACK vu) l'émetteur devient l'accepteur attesté.
            if not (ab and samePlayer(sender, ab)) then
                o.acceptedBy = sender or (f.crafter ~= "" and f.crafter) or ab
            end
            if myChar(o.buyer) then self:AlertDelivered(o) end
        end
    elseif action == "DONE" then
        -- Acheteur → crafteur : confirmation de réception. Idempotent (DONE arrive en global ET whisper) :
        -- réputation créditée à la 1re transition vers « terminée », et seulement si le crafteur est
        -- un perso de MON compte (la rep db.delivered est par compte — sinon elle se perdait quand un
        -- autre perso que l'accepteur recevait le DONE). SEUL l'acheteur (ou son reroll vérifié) confirme.
        if o.status ~= "done" and samePlayer(sender, o.buyer) then
            o.acceptedBy = (f.crafter ~= "" and f.crafter) or o.acceptedBy   -- attesté par l'acheteur : qui créditer
            o.status = "done"
            if myChar(o.acceptedBy) then
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
    if o.acceptedBy and samePlayer(who, o.acceptedBy) then
        o.status = "open"; o.acceptedBy = nil                   -- l'artisan (ou son reroll vérifié) se désiste → réouverte
    elseif myChar(o.buyer) and (o.recipient == who or samePlayer(who, o.recipient)) then
        o.status = "declined"; o.declinedBy = who               -- commande nommée refusée (par le perso ou son reroll)
    end
    if myChar(o.buyer) then
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
    elseif action == "SUGG" then self:_OnSuggest(message, sender)
    else self:_OnCycle(action, message, sender) end
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end   -- maj live coalescée (rafales de fanout)
    local PW = COC.ProfWindow
    if PW and PW.RefreshOrders and PW.frame and PW.frame:IsShown() then PW:RefreshOrders() end
end

-- Nudge « garde pour toi » (ORD|SUGG|id[|1]) : un pair me signale une commande de son cache que JE
-- saurais faire. « |1 » = captée /commerce·/guilde → viaAddon=false + captured. Alerte ssi H:ICanCraft.
function Orders:_OnSuggest(message, sender)
    local f = Codec.Decode(message)
    local o = f and f.id and COC.db.orders[f.id]
    if not o then return end
    -- `captured=1` coupe le relais mesh de l'ordre (_RelayMatch) : ne l'honorer que d'un porteur
    -- CONNU (présent dans le roster). Sinon un inconnu pourrait, avec un SUGG forgé, étouffer
    -- silencieusement et définitivement la propagation d'une commande vers les bons artisans.
    local known = sender and COC.Directory and COC.Directory.roster and COC.Directory.roster[sender]
    if f.captured == "1" and known then o.viaAddon = false; o.captured = true end
    -- Hors portée : ordre nommé à un TIERS précis → ne pas suggérer à moi (fuite d'info sur commande
    -- privée). « Moi » inclut mes rerolls (IsMyChar, local).
    local rcpt = o.recipient or "Tous"
    if not KEYWORD_RCPT[rcpt] and not myChar(rcpt) then return end
    local H = COC.Handoff
    -- Nommée sur moi OU un de mes persos → AlertTargeted (via _ShouldAlert) s'en charge, pas le nudge.
    if H and o.status == "open" and not myChar(o.buyer) and not myChar(o.recipient) then
        if H:ICanCraft(o) then H:AlertCapable(o)
        else local alt = H:MyRerollCanCraft(o); if alt then H:AlertReroll(o, alt) end end
    end
end
