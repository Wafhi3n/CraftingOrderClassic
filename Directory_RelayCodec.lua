-- Directory_RelayCodec.lua — codec du fil RLY : relais de la fiche d'un artisan HORS LIGNE par
-- un de ses partenaires. PUR (aucune API WoW, aucun LibStub) : testable headless
-- (tests/test_relay_codec.lua), même discipline que Orders_Codec.lua.
--
-- Enveloppe : "RLY|<origin>|<age>|<payload interne SK/RK/CD>". `age` = secondes écoulées depuis
-- le dernier contact DIRECT relayeur↔origin (qualifie la fraîcheur du SK/RK ; le CD, lui, est
-- RECALCULÉ au moment du relais → son restant est courant). AUCUNE règle d'acceptation ici :
-- whisper-only, origin≠sender, caps et rate-limit vivent dans Directory_Relay.OnRelay.

local COC = CraftingOrderClassic
local RelayCodec = {}
COC.RelayCodec = RelayCodec

function RelayCodec.Wrap(origin, age, inner)
    if not (origin and origin ~= "" and inner and inner ~= "") then return nil end
    return string.format("RLY|%s|%d|%s", origin, math.max(0, math.floor(tonumber(age) or 0)), inner)
end

-- → { origin=, age=, inner=, verb= } ou nil si malformé. L'inner contient des « | » (capture
-- gourmande) ; `verb` = préfixe majuscule de l'inner (SK/RK/CD attendus — filtré par l'appelant).
function RelayCodec.Parse(message)
    local origin, age, inner = (message or ""):match("^RLY|([^|]+)|(%d+)|(.+)$")
    if not origin then return nil end
    local verb = inner:match("^([A-Z]+)|")
    if not verb then return nil end
    return { origin = origin, age = tonumber(age), inner = inner, verb = verb }
end

-- Reconstruit un payload SK depuis une entrée roster : MÊME format que Dir:_SkillPayload
-- ("SK|lvl=<n>|key,cur,max;…[;rep=<n>]") — verrouillé par golden test. Tri des métiers pour un
-- rendu déterministe (l'original itère pairs ; le récepteur est insensible à l'ordre).
function RelayCodec.BuildSK(entry)
    local parts = {}
    for key, sk in pairs(entry and entry.skill or {}) do
        parts[#parts + 1] = key .. "," .. (sk[1] or 0) .. "," .. (sk[2] or 0)
    end
    if #parts == 0 then return nil end
    table.sort(parts)
    local lvl, rep = entry.level or 0, entry.rep or 0
    return "SK|lvl=" .. lvl .. "|" .. table.concat(parts, ";") .. (rep > 0 and (";rep=" .. rep) or "")
end

-- Même format que CraftLink:BuildRK ("RK|prof|hex|dataVersion"), depuis les champs stockés.
function RelayCodec.BuildRK(prof, hex, dv)
    if not (prof and hex and hex ~= "") then return nil end
    return string.format("RK|%s|%s|%d", prof, hex, dv or 0)
end

-- Fil CD depuis les readyAt STOCKÉS (roster), recalculés à `now` : le restant relayé est donc
-- courant même si l'origin est hors ligne depuis des heures. Tri par spellID (déterministe).
function RelayCodec.BuildCD(prof, cds, now)
    if not (prof and cds and next(cds) and now) then return nil end
    local sids = {}
    for sid in pairs(cds) do sids[#sids + 1] = sid end
    table.sort(sids)
    local parts = {}
    for _, sid in ipairs(sids) do
        local remain = math.ceil((tonumber(cds[sid]) or 0) - now)
        if remain < 0 then remain = 0 end
        parts[#parts + 1] = sid .. "," .. remain
    end
    return "CD|" .. prof .. "|" .. table.concat(parts, ";")
end
