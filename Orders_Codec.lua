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
-- ENCODAGE — une fonction par verbe, expressions reprises telles quelles du code d'origine.
-- ------------------------------------------------------------------
local ENCODERS = {
    -- Champs : id, buyer, kind, itemID|spellID|0, qty|1, profession|"", price|"" (sans |),
    --          recipient|"Tous" (sans |), byStack 1/0, provided CSV itemID.
    NEW = function(o)
        return string.format("ORD|NEW|%s|%s|%s|%d|%d|%s|%s|%s|%d|%s",
            o.id, o.buyer, o.kind, o.itemID or o.spellID or 0, o.qty or 1,
            o.profession or "", (o.price or ""):gsub("|", ""),
            (o.recipient or "Tous"):gsub("|", ""), o.byStack and 1 or 0,
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
}

function Codec.Decode(message)
    if type(message) ~= "string" then return nil end
    local verb = message:match("^ORD|([A-Z]+)|")
    local d = verb and DECODERS[verb]
    if not d then return nil end
    return d(message)
end
