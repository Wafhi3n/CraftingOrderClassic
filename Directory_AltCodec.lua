-- Directory_AltCodec.lua — codec du fil ALT (liste des persos d'un même joueur) + vérification
-- par réciprocité. PUR (aucune API WoW, aucun LibStub) : testable headless (tests/test_alt_codec.lua),
-- même discipline que Directory_RelayCodec.lua.
--
-- Fil : "ALT|<main>|<nom1>,<nom2>,..." (noms courts triés, le set INCLUT le main et l'émetteur) ;
-- "ALT|-|" = dissolution (opt-out). AUCUNE règle de confiance ici : le stockage sous le sender,
-- le rate-cap et la garde « sender ∈ set » vivent dans Directory_Alts.OnAlt. La SÉCURITÉ du
-- regroupement repose sur la réciprocité (Component) : un lien A↔B n'existe que si A a annoncé B
-- ET B a annoncé A — les deux annonces sortant de la même SavedVariable de compte, un imposteur
-- ne peut pas produire la moitié « victime » de la paire.

local COC = CraftingOrderClassic
local AltCodec = {}
COC.AltCodec = AltCodec

AltCodec.MAX_NAMES = 12    -- persos max par déclaration (borne aussi le BFS de Component)
AltCodec.MAX_BYTES = 240   -- marge sous la limite AddonMessage (255)

-- Nom court plausible : 2..24 octets (12 caractères Blizzard, UTF-8 accentué ≤ 2 o/car),
-- sans séparateurs du fil (| ,) ni espace ni tiret (réservé au suffixe royaume).
local function validName(n)
    if type(n) ~= "string" then return false end
    if #n < 2 or #n > 24 then return false end
    return not n:find("[|,%s%-]")
end

-- Sérialise une déclaration. `names` est en ORDRE DE PRIORITÉ (l'appelant met main + émetteur en
-- tête) : dédoublonné puis plafonné à MAX_NAMES, et en cas de dépassement d'octets on retire par
-- la FIN de cet ordre (jamais le main) — le fil reste alors valide au lieu d'échouer en silence.
-- Le tri octet-croissant n'est appliqué qu'à la sérialisation (rendu déterministe, goldens).
-- Encode(nil) ou Encode("-") = dissolution. Retour nil si entrée invalide.
function AltCodec.Encode(main, names)
    if main == nil or main == "-" then return "ALT|-|" end
    if not validName(main) or type(names) ~= "table" then return nil end
    local kept, seen = {}, {}
    for i = 1, #names do
        local n = names[i]
        if not validName(n) then return nil end
        if not seen[n] and #kept < AltCodec.MAX_NAMES then seen[n] = true; kept[#kept + 1] = n end
    end
    if not seen[main] then return nil end   -- main ∈ set exigé (le récepteur le revalide)
    local function serialize()
        local sorted = {}
        for i = 1, #kept do sorted[i] = kept[i] end
        table.sort(sorted)
        return "ALT|" .. main .. "|" .. table.concat(sorted, ",")
    end
    local msg = serialize()
    while #msg > AltCodec.MAX_BYTES and #kept > 1 do
        local last = table.remove(kept)                       -- retire le moins prioritaire
        if last == main then kept[#kept + 1] = last; table.remove(kept, #kept - 1) end
        msg = serialize()
    end
    if #msg > AltCodec.MAX_BYTES then return nil end
    return msg
end

-- → { main=, list={...}, set={[nom]=true} } ou { dissolve=true } ou nil si malformé.
-- Rejets : >240 o, liste vide (sauf dissolution), nom invalide, doublon, virgule pendante/double,
-- main hors du set, plus de MAX_NAMES noms.
function AltCodec.Decode(message)
    if type(message) ~= "string" or #message > AltCodec.MAX_BYTES then return nil end
    local main, body = message:match("^ALT|([^|]+)|([^|]*)$")
    if not main then return nil end
    if main == "-" then
        if body ~= "" then return nil end
        return { dissolve = true }
    end
    if body == "" or body:find("^,") or body:find(",$") or body:find(",,", 1, true) then return nil end
    local list, set = {}, {}
    for name in body:gmatch("[^,]+") do
        if not validName(name) or set[name] then return nil end
        if #list >= AltCodec.MAX_NAMES then return nil end
        set[name] = true
        list[#list + 1] = name
    end
    if not validName(main) or not set[main] then return nil end
    return { main = main, list = list, set = set }
end

-- Une déclaration (claim) contient-elle ce nom ? Scan de l'array (≤ MAX_NAMES : trivial).
local function claimHas(claim, name)
    local list = claim and claim.list
    if not list then return false end
    for i = 1, #list do if list[i] == name then return true end end
    return false
end

-- Lien VÉRIFIÉ : chacun apparaît dans la déclaration de l'autre (réciprocité).
local function verified(claims, a, b)
    return a ~= b and claimHas(claims[a], b) and claimHas(claims[b], a)
end
AltCodec.Verified = verified   -- exposé pour tests/diagnostic

-- Composante de liens MUTUELS contenant `start` (BFS borné). claims = { [nom] = {list=...} } —
-- injectable, donc pur. Retourne (set, array dans l'ordre de découverte, start en premier).
-- Un perso sans lien vérifié = composante singleton (jamais fusionné, jamais routé).
function AltCodec.Component(claims, start, cap)
    cap = cap or AltCodec.MAX_NAMES
    local comp, order, qi = { [start] = true }, { start }, 1
    while qi <= #order and #order < cap do
        local cur = order[qi]; qi = qi + 1
        local list = claims[cur] and claims[cur].list
        if list then
            for i = 1, #list do
                local nb = list[i]
                if not comp[nb] and #order < cap and verified(claims, cur, nb) then
                    comp[nb] = true
                    order[#order + 1] = nb
                end
            end
        end
    end
    return comp, order
end
