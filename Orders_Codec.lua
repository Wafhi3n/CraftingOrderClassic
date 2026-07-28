-- Orders_Codec.lua — codec du protocole filaire ORD| (sérialisation ⇄ parsing, SOURCE DE VÉRITÉ).
--
-- Centralise le format des commandes P2P, jusqu'ici éparpillé (Orders_Net:_NewPayload/Broadcast,
-- Orders:Decline pour NACK, Handoff pour SUGG). Table `ENCODERS`/`DECODERS` indexée par verbe :
--   * Codec.Encode(verb, o)   -> chaine filaire "ORD|VERBE|..."  (ou nil si verbe inconnu)
--   * Codec.Decode(message)   -> table plate { verb=, id=, ... } de champs BRUTS (ou nil si non parsable)
--
-- Contrat (docs\protocol-ord.md) : le codec PARSE et SÉRIALISE, un point c'est tout. Il n'applique NI
-- défaut/normalisation (kind ""->"item", recipient ""->"Tous"... restent dans Orders:_OnNew/_OnCycle),
-- NI autorisation (l'anti-spoof sender==buyer reste dans Orders:_OnCycle). Les octets produits sont
-- STRICTEMENT identiques au code d'origine (refactor iso-fil, pas de bump protocolVersion).
--
-- PUR : aucune dépendance à l'API WoW ni à LibStub → chargeable hors client (tests headless Elune).
-- Ne référence que la table globale CraftingOrderClassic (pour publier COC.OrdersCodec).

local COC = CraftingOrderClassic
local Codec = {}
COC.OrdersCodec = Codec

-- ------------------------------------------------------------------
-- Texte libre (titre / description d'une commande) — assainissement PARTAGÉ
-- ------------------------------------------------------------------
-- Bornes en OCTETS (un message addon plafonne à 255) : les accents français font 2 octets, compter
-- en caractères sous-estimerait la taille réelle d'un tiers.
Codec.TITLE_MAX = 80
Codec.TEXT_MAX  = 180

-- Tronque à `max` OCTETS sans couper une séquence UTF-8 : une coupe au milieu d'un « é » affiche un
-- caractère parasite chez TOUS les destinataires.
local function truncBytes(s, max)
    if #s <= max then return s end
    local i = max
    while i > 0 do
        local b = s:byte(i + 1)                      -- octet de CONTINUATION (10xxxxxx) ? on recule
        if not b or b < 128 or b >= 192 then break end
        i = i - 1
    end
    return s:sub(1, i)
end

-- Texte libre prêt pour le fil ET pour l'affichage. On retire :
--   · `|` — séparateur du fil, MAIS surtout préfixe de tous les échappements d'interface (|c couleur,
--     |T texture, |H lien) : sans ça un titre hostile fabrique un faux lien d'objet, colle une
--     texture, ou masque du texte dans l'interface de tout le monde ;
--   · `~` — séparateur du transport canal-texte (cf. BroadcastText) ;
--   · les caractères de contrôle (retours à la ligne compris), qui casseraient la mise en page.
-- ⚠️ À appliquer à l'ÉMISSION *et* à la RÉCEPTION : un pair hostile n'envoie pas ce que NOUS encodons.
function Codec.CleanText(s, max)
    if type(s) ~= "string" then return "" end
    s = s:gsub("[|~]", ""):gsub("%c", " "):gsub("^%s+", ""):gsub("%s+$", "")
    return truncBytes(s, max or Codec.TEXT_MAX)
end

-- ------------------------------------------------------------------
-- ENCODAGE — une fonction par verbe, expressions reprises telles quelles du code d'origine.
-- ------------------------------------------------------------------
local ENCODERS = {
    -- Champs : id, buyer, kind, itemID|spellID|0, qty|1, profession|"", price|"" (sans | ni ~),
    --          recipient|"Tous" (sans | ni ~), byStack 1/0, provided CSV itemID.
    -- On strippe `|` (séparateur du fil) ET `~` (séparateur du transport canal-texte, cf. BroadcastText :
    -- le canal remplace | par ~, un ~ littéral dans un champ décalerait le décodage à la réception canal).
    NEW = function(o)
        return string.format("ORD|NEW|%s|%s|%s|%d|%d|%s|%s|%s|%d|%s",
            o.id, o.buyer, o.kind, o.itemID or o.spellID or 0, o.qty or 1,
            o.profession or "", (o.price or ""):gsub("[|~]", ""),
            (o.recipient or "Tous"):gsub("[|~]", ""), o.byStack and 1 or 0,
            table.concat(o.provided or {}, ","))
    end,
    CANCEL = function(o) return "ORD|CANCEL|" .. o.id end,
    ACK    = function(o) return string.format("ORD|ACK|%s|%s",  o.id, o.acceptedBy or "") end,
    DLV    = function(o) return string.format("ORD|DLV|%s|%s",  o.id, o.acceptedBy or "") end,
    DONE   = function(o) return string.format("ORD|DONE|%s|%s", o.id, o.acceptedBy or "") end,
    -- NACK : `who` = l'émetteur réel (posé par l'appelant = me()).
    NACK   = function(o) return "ORD|NACK|" .. o.id .. "|" .. (o.who or "") end,
    -- SUGG : suffixe |1 si l'ordre a été capté dans /commerce·/guilde (entrante).
    SUGG   = function(o) return "ORD|SUGG|" .. o.id .. (o.captured and "|1" or "") end,
    -- ---------------------------------------------------------------
    -- Narratif : TTL (titre, diffusé avec le NEW) · TXQ (demande de description, 1:1) · TXT (réponse).
    -- Des verbes SÉPARÉS, jamais un champ de plus dans NEW : le motif de NEW est ancré sur `$`, un
    -- champ supplémentaire le ferait échouer EN BLOC chez tout client plus ancien — la commande
    -- deviendrait INVISIBLE, pas dégradée. Un verbe inconnu, lui, rend nil dans Codec.Decode et est
    -- ignoré proprement : c'est la SEULE extension rétro-compatible du protocole.
    -- La description ne se diffuse pas : elle se demande à l'auteur, en chuchotement (voie fiable du
    -- transport) — sinon chaque commande postée déverserait un pavé de texte libre sur le canal.
    TTL = function(o) return "ORD|TTL|" .. o.id .. "|" .. Codec.CleanText(o.title, Codec.TITLE_MAX) end,
    TXQ = function(o) return "ORD|TXQ|" .. o.id end,
    TXT = function(o) return "ORD|TXT|" .. o.id .. "|" .. Codec.CleanText(o.text, Codec.TEXT_MAX) end,
}

function Codec.Encode(verb, o)
    local e = ENCODERS[verb]
    if not e then return nil end
    return e(o)
end

-- ------------------------------------------------------------------
-- DÉCODAGE — motifs Lua repris tels quels ; renvoie les captures BRUTES sous des noms de champ.
-- ------------------------------------------------------------------
-- Fabrique un décodeur "id + queue" partagé par ACK/DLV/DONE/NACK (motif ^ORD|VERBE|([^|]*)|(.*)$).
-- Le 2e champ est vide-toléré (`(.*)`). `field` nomme la queue (crafter pour ACK/DLV/DONE, who pour NACK).
local function idTailDecoder(verb, field)
    local pat = "^ORD|" .. verb .. "|([^|]*)|(.*)$"
    return function(message)
        local id, tail = message:match(pat)
        if not id then return nil end
        return { verb = verb, id = id, [field] = tail }
    end
end

local DECODERS = {
    NEW = function(message)
        local id, buyer, kind, oid, qty, prof, price, recipient, byStack, prov =
            message:match("^ORD|NEW|([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|(%d*)|?([%d,]*)$")
        if not id then return nil end
        return { verb = "NEW", id = id, buyer = buyer, kind = kind, oid = oid, qty = qty,
                 prof = prof, price = price, recipient = recipient, byStack = byStack, prov = prov }
    end,
    CANCEL = function(message)
        local id = message:match("^ORD|CANCEL|(.+)$")   -- id gourmand : tolère un | dans l'id
        if not id then return nil end
        return { verb = "CANCEL", id = id }
    end,
    ACK  = idTailDecoder("ACK",  "crafter"),
    DLV  = idTailDecoder("DLV",  "crafter"),
    DONE = idTailDecoder("DONE", "crafter"),
    NACK = idTailDecoder("NACK", "who"),
    SUGG = function(message)
        local id, cap = message:match("^ORD|SUGG|([^|]*)|?(%d*)$")   -- suffixe |1 optionnel
        if not id then return nil end
        return { verb = "SUGG", id = id, captured = cap }
    end,
    -- Narratif. La queue est GOURMANDE (`.*`) : un émetteur hostile peut y glisser des `|`, et un
    -- motif strict rejetterait alors le message au lieu de le nettoyer. On capture tout, puis
    -- CleanText assainit — la confiance est placée dans le nettoyage, jamais dans la forme reçue.
    TTL = function(message)
        local id, title = message:match("^ORD|TTL|([^|]*)|(.*)$")
        if not id or id == "" then return nil end
        return { verb = "TTL", id = id, title = Codec.CleanText(title, Codec.TITLE_MAX) }
    end,
    TXQ = function(message)
        local id = message:match("^ORD|TXQ|(.+)$")
        if not id then return nil end
        return { verb = "TXQ", id = id }
    end,
    TXT = function(message)
        local id, text = message:match("^ORD|TXT|([^|]*)|(.*)$")
        if not id or id == "" then return nil end
        return { verb = "TXT", id = id, text = Codec.CleanText(text, Codec.TEXT_MAX) }
    end,
}

function Codec.Decode(message)
    if type(message) ~= "string" then return nil end
    local verb = message:match("^ORD|([A-Z]+)|")
    local d = verb and DECODERS[verb]
    if not d then return nil end
    return d(message)
end
