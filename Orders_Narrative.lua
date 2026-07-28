-- Orders_Narrative.lua — TITRE et DESCRIPTION libres d'une commande : « donne un nom et une histoire
-- à ce que tu demandes ». C'est le premier étage de la convergence commande ⇄ quête (le suivi à
-- l'écran et, plus tard, le journal en parchemin les affichent comme une quête).
--
-- Deux voies, choisies pour des raisons opposées :
--   · TTL (titre) voyage AVEC le NEW — sans lui, une commande apparaîtrait sans nom chez tout le
--     monde et il faudrait N chuchotements pour le récupérer ;
--   · TXQ/TXT (description) ne se diffuse JAMAIS : on la demande à l'auteur en 1:1. Un pavé de texte
--     libre par commande postée sur le canal du royaume serait à la fois du gaspillage et une
--     nuisance à grande échelle.
--
-- SÉCURITÉ — c'est ici que vit la surface de texte libre de l'addon, donc la règle est stricte :
--   · un titre/texte n'est accepté QUE de l'acheteur de la commande (samePlayer). Conséquence
--     ASSUMÉE : une commande arrivée par relais mesh n'a pas de titre tant que son auteur ne nous
--     l'a pas envoyé — récupérable par TXQ. On préfère une commande sans nom à un nom que
--     n'importe qui aurait pu écrire à la place d'autrui ;
--   · le contenu est ré-assaini À LA RÉCEPTION (Codec.CleanText retire `|`, donc toute fabrication
--     de faux lien, de texture ou de couleur) — on ne fait jamais confiance à la forme reçue ;
--   · rien n'est stocké venant d'un joueur en sourdine ;
--   · répondre à un TXQ est throttlé par demandeur : sinon un seul joueur transforme notre client en
--     amplificateur de chuchotements.

local COC       = CraftingOrderClassic
local Orders    = COC.Orders
local Codec     = COC.OrdersCodec
local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
local L         = COC.L

local ANSWER_THROTTLE = 10    -- s entre deux réponses TXQ au MÊME demandeur
local PENDING_MAX        = 20 -- titres en attente de leur NEW (borne anti-gonflement)
local PENDING_PER_SENDER = 4  -- … dont au plus 4 par émetteur (anti-éviction, cf. stashTitle)

local function me()  return (UnitName and UnitName("player")) or "?" end
local function pmsg(m) print("|cFF33DD88Crafting Order|r " .. m) end
local function myChar(n) return n == me() or (COC.IsMyChar and COC:IsMyChar(n)) or false end

local function samePlayer(a, b)
    if not (a and b) then return false end
    if a == b then return true end
    local D = COC.Directory
    return (D and D.SamePlayer and D:SamePlayer(a, b)) == true
end

-- Commande NOMMÉE = destinataire = un joueur précis, pas une portée. Même table que Orders_Net.
local KEYWORD_RCPT = { Tous = true, Guilde = true, Amis = true }
local function isNamed(o)
    local r = o and o.recipient
    return (r and r ~= "" and not KEYWORD_RCPT[r]) and true or false
end

local function muted(who)
    local M = COC.Moderation
    return (M and M.IsMuted and who and M:IsMuted(who)) and true or false
end

local function trace(msg) if COC.Trace then COC.Trace:Log("narr", msg) end end

-- ------------------------------------------------------------------
-- Titres arrivés AVANT leur commande
-- ------------------------------------------------------------------
-- Le transport ne garantit pas l'ordre : un TTL peut précéder son NEW (files whisper/canal
-- distinctes). Sans ce sas, le titre serait purement perdu au moment le plus courant — la première
-- diffusion. Borné et volontairement NON persisté : c'est un tampon de quelques secondes.
local pending, pendingOrder = {}, {}

-- Deux gardes contre l'empoisonnement du sas. Les ids sont DEVINABLES (« Nom-seq », cf. _OnNew) :
--   · une entrée déjà posée n'est PAS écrasée par un autre émetteur — sinon il suffisait de prédire
--     l'id de la prochaine commande d'une victime pour faire perdre son titre légitime ;
--   · quota PAR ÉMETTEUR, pas seulement global : sans lui, un seul pair envoyant 20 TTL bidon
--     évinçait tous les titres en cours de propagation chez le client visé.
local function stashTitle(id, title, from)
    local cur = pending[id]
    if cur then
        if cur.from == from then cur.title = title end   -- même émetteur : simple mise à jour
        return
    end
    local mine = 0
    for _, p in pairs(pending) do if p.from == from then mine = mine + 1 end end
    if mine >= PENDING_PER_SENDER then return end
    if #pendingOrder >= PENDING_MAX then
        local oldest = table.remove(pendingOrder, 1)
        pending[oldest] = nil
    end
    pendingOrder[#pendingOrder + 1] = id
    pending[id] = { title = title, from = from }
end

-- Appelé par _OnNew une fois la commande en cache : le titre en attente ne vaut que s'il vient bien
-- de l'acheteur qui vient d'être établi.
function Orders:ApplyPendingTitle(o)
    local p = o and o.id and pending[o.id]
    if not p then return end
    pending[o.id] = nil
    for i, id in ipairs(pendingOrder) do
        if id == o.id then table.remove(pendingOrder, i); break end
    end
    if samePlayer(p.from, o.buyer) and not muted(p.from) then
        o.title, o.titleFrom = p.title, p.from
    end
end

-- ------------------------------------------------------------------
-- Côté auteur
-- ------------------------------------------------------------------
-- Pose titre/description sur MA commande. Le titre part aussitôt (même routage que le NEW) ; la
-- description reste locale jusqu'à ce qu'on la demande.
function Orders:SetNarrative(id, title, text)
    local o = id and COC.db and COC.db.orders and COC.db.orders[id]
    if not o then pmsg(L["commande introuvable : "] .. tostring(id)); return false end
    if not myChar(o.buyer) then pmsg(L["ce n'est pas ta commande."]); return false end
    if title ~= nil then
        o.title = Codec.CleanText(title, Codec.TITLE_MAX)
        if o.title == "" then o.title = nil end
        o.titleFrom = o.title and o.buyer or nil
        self:Broadcast("TTL", o, { channel = true })
    end
    if text ~= nil then
        o.text = Codec.CleanText(text, Codec.TEXT_MAX)
        if o.text == "" then o.text = nil end
    end
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
    return true
end

-- Pose le narratif sur une commande QU'ON VIENT DE CRÉER, sans diffuser (l'appelant enchaîne sur son
-- propre Broadcast). Vit ici plutôt que dans Orders.lua, qui est à deux lignes de son plafond
-- anti-monolithe — et c'est de toute façon la place logique : tout le narratif est dans ce fichier.
function Orders:AttachNarrative(o, title, text)
    if not o then return end
    local t = title and Codec.CleanText(title, Codec.TITLE_MAX) or nil
    local x = text  and Codec.CleanText(text,  Codec.TEXT_MAX)  or nil
    o.title     = (t and t ~= "") and t or nil
    o.text      = (x and x ~= "") and x or nil
    o.titleFrom = o.title and o.buyer or nil
end

-- Joint le titre à un push DIRIGÉ (`OnArtisanOnline`, quand un artisan revient en ligne). SEULEMENT
-- pour MES commandes : un TTL relayé par un tiers serait de toute façon rejeté à l'arrivée
-- (`samePlayer(sender, o.buyer)` strict). Une commande d'AUTRUI que je relaie arrive donc sans nom
-- tant que son auteur n'est pas là pour le rappeler — limite assumée, c'est le prix de
-- l'anti-usurpation, et il n'existe pas de verbe de re-demande de titre.
function Orders:PushTitleTo(who, o)
    if not (who and o and o.title and CraftLink and myChar(o.buyer)) then return end
    CraftLink:Send(Codec.Encode("TTL", o), "whisper", who)
    trace("TTL -> " .. tostring(who) .. " (" .. tostring(o.id) .. ")")
end

-- Demande la description à l'auteur (1:1). Sans effet sur ma propre commande, ou si l'auteur n'a pas
-- l'addon. `o.textAsked` évite de re-demander en boucle depuis un refresh d'interface.
function Orders:RequestText(id)
    local o = id and COC.db and COC.db.orders and COC.db.orders[id]
    if not (o and CraftLink and o.buyer) then return false end
    if myChar(o.buyer) or o.text or o.textAsked then return false end
    o.textAsked = time and time() or 0
    CraftLink:Send(Codec.Encode("TXQ", o), "whisper", o.buyer)
    trace("TXQ -> " .. tostring(o.buyer) .. " (" .. tostring(id) .. ")")
    return true
end

-- ------------------------------------------------------------------
-- Réception
-- ------------------------------------------------------------------
function Orders:_OnTitle(message, sender)
    local f = Codec.Decode(message)
    if not f then return end
    local o = COC.db and COC.db.orders and COC.db.orders[f.id]
    if not o then return stashTitle(f.id, f.title, sender) end      -- TTL avant son NEW
    if not samePlayer(sender, o.buyer) then
        trace(string.format("TTL rejeté : %s n'est pas l'acheteur %s (%s)",
            tostring(sender), tostring(o.buyer), tostring(f.id)))
        return
    end
    if muted(sender) then return end
    o.title = (f.title ~= "" and f.title) or nil
    o.titleFrom = o.title and sender or nil
end

-- Je ne réponds que pour MES commandes, et seulement si j'ai quelque chose à dire. Throttle par
-- demandeur : une rafale de TXQ ne doit pas nous faire chuchoter en boucle (auto-spam sanctionnable).
local answered = {}
function Orders:_OnTextQuery(message, sender)
    local f = Codec.Decode(message)
    local o = f and COC.db and COC.db.orders and COC.db.orders[f.id]
    if not (o and sender and CraftLink) then return end
    if not myChar(o.buyer) or not o.text or o.text == "" then return end
    if muted(sender) then return end
    -- Commande NOMMÉE : ne répondre qu'au destinataire visé. Le payload NEW part sur le canal addon
    -- quelle que soit la portée, donc n'importe quel porteur du royaume connaît l'id d'une commande
    -- privée — sans ce filtre, il lui suffisait de chuchoter un TXQ pour lire un texte écrit pour
    -- une seule personne. Une commande de portée large n'a rien de privé : elle répond à tous.
    if isNamed(o) and not samePlayer(sender, o.recipient) then
        trace(string.format("TXQ refusé : %s n'est pas le destinataire %s (%s)",
            tostring(sender), tostring(o.recipient), tostring(f.id)))
        return
    end
    local now = (time and time()) or 0
    if answered[sender] and (now - answered[sender]) < ANSWER_THROTTLE then return end
    answered[sender] = now
    CraftLink:Send(Codec.Encode("TXT", o), "whisper", sender)
    trace("TXT -> " .. tostring(sender) .. " (" .. tostring(f.id) .. ")")
end

function Orders:_OnText(message, sender)
    local f = Codec.Decode(message)
    local o = f and COC.db and COC.db.orders and COC.db.orders[f.id]
    if not o then return end
    if not samePlayer(sender, o.buyer) then
        trace(string.format("TXT rejeté : %s n'est pas l'acheteur %s (%s)",
            tostring(sender), tostring(o.buyer), tostring(f.id)))
        return
    end
    if muted(sender) then return end
    o.text = (f.text ~= "" and f.text) or nil
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
end

-- Affiche une commande SOUS FORME DE QUÊTE (mode LECTURE de la fiche). C'est l'unique consommateur
-- de ce mode aujourd'hui — sans lui ce serait du code jamais exécuté, alors que c'est exactement le
-- chemin dont le futur journal en parchemin et RPQuestMaster auront besoin.
function Orders:ShowAsQuest(id)
    local o = id and COC.db and COC.db.orders and COC.db.orders[id]
    if not o then pmsg(L["commande introuvable : "] .. tostring(id)); return end
    if not COC.QuestSheet then return end
    self:RequestText(id)   -- la description peut arriver après l'ouverture : ce n'est pas bloquant
    local Skin = COC.UI and COC.UI.Skin
    COC.QuestSheet:Open({
        title     = o.title,
        text      = o.text,
        objective = self:OrderName(o) .. ((Skin and Skin.QtySuffix) and Skin.QtySuffix(o) or ""),
        reward    = o.price,
        giver     = o.buyer,
    })
end

-- ------------------------------------------------------------------
-- `/co title <id> <titre>` · `/co text <id> <description>`
-- ------------------------------------------------------------------
-- Entrée en attendant les champs de l'onglet Commande : sans une voie de saisie, le protocole n'est
-- pas testable de bout en bout. Sans texte → efface.
function Orders:NarrativeCmd(rest, which)
    local id, body = (rest or ""):match("^(%S+)%s*(.*)$")
    if not id or id == "" then
        pmsg(string.format(L["usage : /co %s <id> <texte>"], which == "text" and "text" or "title"))
        return
    end
    local ok
    if which == "text" then ok = self:SetNarrative(id, nil, body)
    else ok = self:SetNarrative(id, body, nil) end
    if not ok then return end
    local o = COC.db.orders[id]
    local shown = (which == "text") and o.text or o.title
    pmsg(shown and (self:OrderName(o) .. " — |cFFEEDD88" .. shown .. "|r")
              or string.format(L["texte effacé pour %s"], self:OrderName(o)))
end
