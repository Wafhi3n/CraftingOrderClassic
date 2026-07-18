-- Crafting Order - Classic — Orders : carnet d'ordres GLOBAL (modèle + cycle + protocole).
--
-- Un ordre = une demande de craft postée par un acheteur, visible/acceptable par n'importe quel
-- porteur de l'addon sur le royaume (canal global), sans guilde commune. Cycle :
--   poster (NEW) → accepter (ACK) → livrer (DONE) ; annuler (CANCEL) à tout moment par l'auteur.
--
-- Discipline cache : tout passe par COC.db.orders (persistant) ; l'UI (à venir) lira CE cache.
-- Protocole sur le transport CraftLink (portée "global" par défaut) : 7 verbes
--   NEW / CANCEL / ACK / DLV / DONE / NACK / SUGG, sérialisés/parsés par Orders_Codec.lua.
--   Grammaire filaire complète + règles d'autorité (anti-spoof sender==buyer) : docs\protocol-ord.md.

local COC = CraftingOrderClassic
local Orders = {}
COC.Orders = Orders
local L = COC.L

local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
local Codec     = COC.OrdersCodec   -- sérialisation ORD| (Orders_Codec.lua, chargé avant)

local ORDER_TTL  = 6 * 3600     -- 6 h : au-delà, une commande OUVERTE est tenue pour expirée (cachée/élaguée)
Orders.ORDER_TTL = ORDER_TTL    -- exposé : la vue métier (ProfWindow_Orders) applique le MÊME TTL que le Carnet
local REBROADCAST = 2 * 3600    -- 2 h : ré-émission périodique de MES commandes ouvertes (anti-oubli réseau)
local DONE_RETENTION = 7 * 86400 -- 7 j (depuis la création) : au-delà, une commande TERMINÉE est purgée du cache

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
-- Encodage ORD| + routage par portée (KEYWORD_RCPT, _NewPayload, _ScopeMatch, _FanoutTargets,
-- _CycleTargets, Broadcast) → déplacés dans Orders_Net.lua (couche « fil réseau », anti-monolithe).
-- Ces méthodes restent sur la table COC.Orders → appelées via self: depuis le cycle local ci-dessous.

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
    -- Nommée sur un de mes REROLLS (décision 100 % locale : MA SavedVariable, sans opt-in) :
    -- visible depuis n'importe quel perso du compte — le Carnet/la vue métier l'affichent, l'alerte suit.
    if who == me() and COC.IsMyChar and COC:IsMyChar(rcpt) then return true end
    local D = COC.Directory
    if rcpt == "Guilde" then return (D and D._guildSet  and D._guildSet[o.buyer]) == true end
    if rcpt == "Amis"   then return (D and D._friendSet and D._friendSet[o.buyer]) == true end
    return false                                    -- ciblée sur un AUTRE joueur → pas pour moi
end

-- ------------------------------------------------------------------
-- Cycle (actions locales → diffusion)
-- ------------------------------------------------------------------
-- « Agit pour » : moi-même, ou — rerolls OPT-IN actifs — un perso de MON compte (IsMyChar, local).
-- Le gating sur altsEnabled évite d'émettre une transition inter-perso que les pairs (qui exigent
-- la réciprocité ALT) rejetteraient en face : sans opt-in, strictement équivalent à « == me() ».
local function actsFor(name)
    if not name then return false end
    if name == me() then return true end
    return (COC.db and COC.db.altsEnabled and COC.IsMyChar and COC:IsMyChar(name)) or false
end

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
    self:Broadcast("NEW", o, { channel = true })   -- {channel} = diffusion voulue → portée royaume si publique
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
    self:Broadcast("NEW", o, { channel = true })   -- {channel} = diffusion voulue → portée royaume si publique
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
    if not actsFor(o.buyer) then pmsg(L["ce n'est pas ta commande."]); return end
    -- {channel} : une commande PUBLIQUE a pu atteindre, par texte-canal, des artisans hors de mon roster
    -- whisperable. Son annulation doit suivre le même chemin, sinon ils la voient « open » jusqu'au TTL.
    o.status = "cancelled"; self:Broadcast("CANCEL", o, { channel = true })
    pmsg(L["commande annulée : "] .. id)
end

function Orders:Accept(id)
    local o = id and COC.db.orders[id]
    if not o or o.status ~= "open" then pmsg(L["commande non disponible : "] .. tostring(id)); return end
    -- IsMyChar (sans opt-in) : ferme aussi l'auto-acceptation entre rerolls du même compte (rep).
    if o.buyer == me() or (COC.IsMyChar and COC:IsMyChar(o.buyer)) then pmsg(L["c'est ta propre commande."]); return end
    if not self:VisibleTo(o) then pmsg(L["cette commande ne t'est pas destinée."]); return end
    -- Nommée pour un de mes rerolls SANS opt-in : l'acheteur (réciprocité) rejetterait l'ACK —
    -- on n'émet pas un demi-état, on explique quoi faire.
    local rcpt = o.recipient
    if rcpt and rcpt ~= me() and COC.IsMyChar and COC:IsMyChar(rcpt) and not (COC.db and COC.db.altsEnabled) then
        pmsg(string.format(L["commande nommée pour %s : connecte ce perso, ou active /co alts on pour accepter d'ici."], rcpt))
        return
    end
    o.status = "accepted"; o.acceptedBy = me(); self:Broadcast("ACK", o)
    pmsg(string.format(L["commande acceptée : %s (%s)"], id, itemName(o.itemID)))
end

-- Le crafteur REMET l'objet (bouton « Livrer » de la vue métier) : la commande passe « remise »
-- (delivered) et NON directement « terminée ». C'est désormais l'ACHETEUR qui finalise (confirmation
-- de réception : auto au loot / bouton « J'ai reçu »), moment où la réputation du crafteur est créditée
-- (cf. OnNetwork DONE). Évite qu'un crafteur se crédite un craft sans que l'acheteur ait rien reçu.
function Orders:Deliver(id)
    local o = id and COC.db.orders[id]
    if not o then pmsg(L["commande introuvable : "] .. tostring(id)); return end
    if not actsFor(o.acceptedBy) then pmsg(L["tu n'as pas accepté cette commande."]); return end
    o.status = "delivered"; self:Broadcast("DLV", o)
    pmsg(string.format(L["remise — en attente de confirmation de %s : %s"], o.buyer or "?", self:OrderName(o)))
end

-- L'ACHETEUR confirme avoir REÇU l'objet → la commande passe « terminée » et le crafteur est crédité
-- (ORD|DONE). Déclenché par le bouton « J'ai reçu » (Carnet) OU l'auto-détection de réception
-- (TryAutoComplete). `auto` = silencieux si rien à confirmer (évite le spam sur chaque loot).
function Orders:Confirm(id, auto)
    local o = id and COC.db.orders[id]
    if not o then if not auto then pmsg(L["commande introuvable : "] .. tostring(id)) end; return end
    if not actsFor(o.buyer) then if not auto then pmsg(L["ce n'est pas ta commande."]) end; return end
    if o.status == "done" then return end
    o.status = "done"; self:Broadcast("DONE", o)
    pmsg(string.format(L["réception confirmée : %s"], self:OrderName(o)))
    if COC.UI and COC.UI.Refresh then COC.UI:Refresh() end
end

-- Auto-complétion à la RÉCEPTION d'un objet. `source` = "loot" aujourd'hui ; point d'entrée UNIQUE
-- pour brancher plus tard l'échange et le courrier (il suffira d'appeler ceci depuis ces détecteurs).
-- Confirme la 1re commande À MOI, « remise », dont l'objet correspond (dédup par le statut done).
function Orders:TryAutoComplete(itemID, source)
    if not (itemID and COC.db and COC.db.orders) then return false end
    for id, o in pairs(COC.db.orders) do
        if actsFor(o.buyer) and o.status == "delivered" and o.itemID == itemID then
            self:Confirm(id, true)
            return true
        end
    end
    return false
end

-- Toast côté ACHETEUR quand le crafteur vient de remettre l'objet (reçu ORD|DLV) : l'invite à
-- confirmer la réception. La confirmation auto au loot peut arriver juste après (double sécurité).
function Orders:AlertDelivered(o)
    if not o then return end
    local txt = string.format(L["%s a remis ta commande : %s — clique « J'ai reçu » pour confirmer"],
        o.acceptedBy or "?", self:OrderName(o))
    pmsg(txt)
    if COC.UI and COC.UI.Toast then
        local Skin = COC.UI and COC.UI.Skin
        COC.UI:Toast(txt, Skin and Skin.tex.workorder)
    end
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
    if actsFor(o.acceptedBy) and o.status == "accepted" then
        o.status = "open"; o.acceptedBy = nil
        if CraftLink then
            local nack = Codec.Encode("NACK", { id = o.id, who = m })
            CraftLink:Send(nack, "global")
            if o.buyer and o.buyer ~= m then CraftLink:Send(nack, "whisper", o.buyer) end
        end
        pmsg(L["commande relâchée : "] .. o.id)
    else
        COC.db.muted = COC.db.muted or {}; COC.db.muted[o.id] = true
        -- Refus d'une commande qui me visait NOMMÉMENT → j'alerte l'acheteur (il la verra « Refusée »).
        -- Portée large (Tous/Guilde/Amis) → silencieux : d'autres artisans la voient encore.
        if CraftLink and o.buyer and o.buyer ~= m and (o.recipient == m or actsFor(o.recipient)) then
            CraftLink:Send(Codec.Encode("NACK", { id = o.id, who = m }), "whisper", o.buyer)
        end
    end
end

-- Action d'une ligne de commande dans la VUE MÉTIER (fenêtre de craft) : c'est LÀ qu'un artisan
-- accepte/livre — le Carnet ne fait que LISTER mes propres commandes. Renvoie (label, fn) ou nil.
function Orders:ProfRowAction(o)
    if not o then return nil end
    local mine = o.buyer == me() or (COC.IsMyChar and COC:IsMyChar(o.buyer))   -- miroir de Accept (anti auto-farm)
    if o.status == "open" and not mine and self:VisibleTo(o) then
        return L["Accepter"], function() Orders:Accept(o.id) end
    end
    if actsFor(o.acceptedBy) and o.status == "accepted" then
        return L["Livrer"], function() Orders:Deliver(o.id) end
    end
    return nil
end

-- Réception protocole (OnNetwork : NEW/CANCEL/ACK/DONE/NACK/SUGG, + _OnSuggest) → déplacée dans
-- Orders_Net.lua (couche « fil réseau »). _ShouldAlert / AlertTargeted (alerting) restent ci-dessous
-- car appelés par OnNetwork via self: sur la table partagée COC.Orders.

-- Notifier (toast) à la 1re réception ? Selon COC.db.notifyScope : all(défaut)/directed/named/off ; cf. /co notify.
function Orders:_ShouldAlert(o)
    local m = (COC.db and COC.db.notifyScope) or "all"
    if COC.Moderation and COC.Moderation:IsMuted(o.buyer) then
        if COC.Trace then COC.Trace:Log("mod", "toast P2P silencé : " .. tostring(o.buyer) .. " (muté)") end
        return false
    end
    if m == "off" then return false end   -- mute déjà couvert par IsMuted ci-dessus (source unique)
    -- Nommée sur moi OU sur un de mes rerolls (IsMyChar = MA SavedVariable — aucun message réseau
    -- ne peut m'assigner un reroll, donc pas d'alerte forcée) : toujours (même petit perso).
    if o.recipient == me() or (COC.IsMyChar and COC:IsMyChar(o.recipient)) then return true end
    -- Commande NON nommée sur moi : ne notifier QUE pour un métier que J'AI (mySkills du perso
    -- courant), QUEL QUE SOIT le transport. Le gate ne couvrait que le canal-texte ; or le relais
    -- mesh à la connexion (OnArtisanOnline → whisper) le contournait → toast chez un joueur sans
    -- le métier (rapport sosh13 : Lodestone of Retaliation sans Enchantement). DÉCOUPLÉ du scanner
    -- de chat (/co scan).
    -- Métier inconnu (nil, objet hors catalogue) → fail-open : ne pas rendre une commande publique muette.
    if o.profession then
        local D = COC.Directory
        if not (D and D.mySkills and D.mySkills[o.profession]) then return false end
    end
    if m == "named" or not self:VisibleTo(o) or (COC.Moderation and COC.Moderation:BelowThreshold(o.buyer)) then return false end  -- restreint / hors portée / bas niveau (anti-bot)
    return (o.recipient and o.recipient ~= "" and o.recipient ~= "Tous") or m == "all"  -- Guilde/Amis vs large
end

-- Alerte de nouvelle commande (toast + son), trois textes selon le destinataire : « pour TOI »
-- (nommée sur moi), « pour ton reroll » (nommée sur un de mes persos), sinon texte NEUTRE — une
-- commande de portée Tous/Guilde/Amis n'est PAS une demande personnelle, l'afficher « pour TOI »
-- se lisait comme une suggestion de craft (rapport sosh13).
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
    local msg
    local rcpt = o.recipient
    if rcpt and rcpt ~= me() and COC.IsMyChar and COC:IsMyChar(rcpt) then
        -- Nommée pour un de mes REROLLS (visible ici grâce à VisibleTo étendu) : texte dédié.
        msg = string.format(L["|cFFFFCC00commande pour ton reroll %s|r de |cFFFFFFFF%s|r : %s%s%s"], rcpt, o.buyer, nm, qty, pr)
    elseif rcpt == me() then
        msg = string.format(L["|cFFFFCC00commande pour TOI|r de |cFFFFFFFF%s|r : %s%s%s"], o.buyer, nm, qty, pr)
    else
        msg = string.format(L["|cFFFFCC00nouvelle commande|r de |cFFFFFFFF%s|r : %s%s%s"], o.buyer, nm, qty, pr)
    end
    pmsg((Skin and ("|T" .. Skin.tex.workorder .. ":0|t ") or "") .. msg)
    if COC.UI and COC.UI.Toast then COC.UI:Toast(msg) end
    pcall(function() PlaySound(SOUNDKIT and SOUNDKIT.TELL_MESSAGE or 3081, "Master") end)
    -- Reroll : commande nommée que mon perso COURANT ne sait pas faire, mais un alt du compte oui.
    -- Passe par Handoff:AlertReroll (chemin unique, dédupliqué par o._rerollAlertDone) pour éviter
    -- une double alerte si le même ordre arrive aussi via ORD|SUGG (_OnSuggest, Orders_Net.lua).
    if o.recipient == me() and COC.Handoff and not COC.Handoff:ICanCraft(o) then
        local alt = COC.Handoff:MyRerollCanCraft(o)
        if alt then COC.Handoff:AlertReroll(o, alt) end
    end
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
end

-- Ré-émet MES commandes ouvertes/acceptées. Appelée sur HI reçu, (re)acquisition du canal (bring-up)
-- et par le ticker périodique : un porteur qui (re)joint le canal finit par les recevoir. Idempotent
-- côté récepteur (dédup par id). L'appelant peut jitter (anti-burst).
function Orders:RebroadcastMine()
    for _, o in pairs(COC.db.orders or {}) do
        -- « Miennes » = celles de MON COMPTE (IsMyChar, local) : la SV étant partagée, les commandes
        -- d'un reroll hors ligne restent maintenues en vie par le perso connecté. Mesh-sûr (dédup id).
        local mine = o.buyer == me() or (COC.IsMyChar and COC:IsMyChar(o.buyer))
        if mine and (o.status == "open" or o.status == "accepted") then
            self:Broadcast("NEW", o)
        end
    end
end

-- Resync sur HI : je ré-annonce MES commandes ouvertes/acceptées. COALESCÉ (une salve de HI au
-- login en masse ne doit pas rediffuser tout mon carnet en global N fois) : un seul rebroadcast par
-- fenêtre ~3-6 s, jitté (anti-burst). Les pushes DIRIGÉS restent plafonnés ailleurs (OnArtisanOnline).
function Orders:OnHello()
    if not (CraftLink and C_Timer) then return end
    if self._rebTimer then return end
    self._rebTimer = true
    C_Timer.After(3 + math.random() * 3, function() Orders._rebTimer = nil; Orders:RebroadcastMine() end)
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

-- Entretien du cache d'ordres (au démarrage) :
--   * commandes OUVERTES d'autrui expirées (TTL) — les miennes restent (gardées pour réémission) ;
--   * commandes TERMINÉES (livrée/annulée/refusée) trop anciennes (rétention, depuis la création) —
--     sinon done/cancelled/declined + toutes mes archives s'accumulaient sans borne dans la SV ;
--   * ids « en sourdine » orphelins (leur commande a été purgée) — sinon COC.db.muted enflait sans fin.
function Orders:PruneExpired()
    if not COC.db then return end
    local now, m = time(), me()
    local orders = COC.db.orders or {}
    for id, o in pairs(orders) do
        local terminal = o.status == "done" or o.status == "cancelled" or o.status == "declined"
        -- « d'autrui » exclut mes REROLLS (IsMyChar) : la SV est partagée — sinon le login d'un perso
        -- purgerait les commandes ouvertes d'un alt du même compte.
        local foreign = o.buyer ~= m and not (COC.IsMyChar and COC:IsMyChar(o.buyer))
        if o.status == "open" and foreign and (now - (o.ts or now)) > ORDER_TTL then
            orders[id] = nil
        elseif terminal and (now - (o.ts or now)) > DONE_RETENTION then
            orders[id] = nil
        end
    end
    if COC.db.muted then
        for id in pairs(COC.db.muted) do if not orders[id] then COC.db.muted[id] = nil end end
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
    if rcpt == who then return true end                  -- nommé : vers la cible…
    local D = COC.Directory                              -- …ou un perso de son set VÉRIFIÉ (rerolls)
    return (D and D.SamePlayer and D:SamePlayer(rcpt, who)) == true
end

-- Un artisan apparaît EN LIGNE (présence JOIN ou découverte whisper) : je lui RELAIE en direct
-- (whisper) les commandes ouvertes en cache qui le concernent → propagation P2P fiable même si le
-- canal caché est muet. Plafonné (anti-burst) ; la dédup par id côté récepteur évite les boucles.
function Orders:OnArtisanOnline(who)
    if not (who and CraftLink) then return end
    -- Cooldown PAR CIBLE : un flapping join/leave du canal caché (ou un re-log rapide) refaisait rejouer
    -- jusqu'à 25 whispers À CHAQUE événement. 60 s couvre le flapping sans gêner un vrai retour en ligne.
    self._lastPush = self._lastPush or {}
    local t = (GetTime and GetTime()) or 0
    if (self._lastPush[who] or 0) + 60 > t then return end
    self._lastPush[who] = t
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
    CraftLink:RegisterHandler("ORD", function(s, m, d) Orders:OnNetwork(s, m, d) end)
    CraftLink:RegisterHandler("HI",  function() Orders:OnHello() end)
    CraftLink:RegisterHandler("PING", function(s) Orders:OnPing(s) end)
    -- PONG : plus d'affichage chat (c'était du debug). Dir:OnPong gère la présence en coulisse.
    -- Ré-émission périodique de MES commandes ouvertes/acceptées : un porteur qui rejoint le canal
    -- sans envoyer de HI finit par les recevoir (sinon il ne voit que ce qui est posté après lui).
    if C_Timer and C_Timer.NewTicker then
        C_Timer.NewTicker(REBROADCAST, function() Orders:RebroadcastMine() end)
    end
end
