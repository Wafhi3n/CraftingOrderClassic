-- Orders_Announce.lua — le FORMAT d'une annonce en clair sur Commerce (spec docs/specs/annonce-commerce.md).
--
-- Pourquoi (2026-09-29) : sans canal général, une commande n'atteint que les porteurs connus. Commerce,
-- lui, relie toutes les capitales et se lit en clair (constat C15) : une ligne lisible par un humain,
-- que l'addon sait aussi relire, atteint à la fois les porteurs inconnus et les joueurs sans l'addon.
--
--   WTB [objet] x1 PROVIDE [mat]x2 [mat]x1 2g50s #CO27      une commande publique (id = <auteur>-27)
--   LFW Enchanting/Tailoring #CO                           un artisan disponible
--   LFW Blacksmithing/[Forge] #CO                          le même, avec son lien de métier
--
-- Ce fichier ne fait QUE le format : fabriquer une ligne, relire une ligne. Aucun appel au jeu (les
-- liens d'objet sont résolus par l'appelant), donc tout se teste sans WoW (tests/test_announce.lua).
-- Contrat PUBLIC : des clients déployés liront ces lignes. Toute évolution reste lisible par l'ancien
-- lecteur : on ajoute en fin de ligne, on ne réordonne pas ; le lien de métier de la ligne LFW entre
-- après son nom parce que l'ancien lecteur le prend pour un métier inconnu et le saute (2026-10-03).

local COC = CraftingOrderClassic
local A = {}
COC.Announce = A

A.MAX = 255   -- le chat coupe au-delà (octets, liens compris)

-- ------------------------------------------------------------------
-- Prix : jetons anglais à l'écriture (g/s/c, le jargon de Commerce), po/pa/pc acceptés à la lecture
-- ------------------------------------------------------------------
function A.PriceTokens(copper)
    copper = tonumber(copper)
    if not copper or copper <= 0 then return nil end
    local g, s, c = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
    local out = ""
    if g > 0 then out = out .. g .. "g" end
    if s > 0 then out = out .. s .. "s" end
    if c > 0 then out = out .. c .. "c" end
    return out
end

local UNIT = { g = 10000, po = 10000, s = 100, pa = 100, c = 1, pc = 1 }

-- « 2g50s », « 2po 50pa », « 80s » -> cuivre ; nil si aucun montant. Un nombre suivi d'autre chose
-- (« x1 PROVIDE ») ne compte pas : seules les unités connues comptent.
function A.ParsePrice(text)
    if type(text) ~= "string" then return nil end
    local total, found = 0, false
    for num, unit in text:gmatch("(%d+)%s*(%a+)") do
        local mult = UNIT[unit:lower()]
        if mult then total, found = total + tonumber(num) * mult, true end
    end
    return found and total or nil
end

-- ------------------------------------------------------------------
-- Écriture
-- ------------------------------------------------------------------
-- Commande publique seulement : nommée, de guilde ou d'amis ne s'annonce jamais sur Commerce.
local function isPublic(o) return o and (o.recipient == nil or o.recipient == "" or o.recipient == "Tous") end

-- Les matériaux qui tiennent : chacun n'entre que s'il reste la place de « +N » pour les suivants,
-- au cas où ceux-là ne tiendraient pas. Rend le morceau de ligne (« PROVIDE … » ou vide).
local function provideTokens(mats, room)
    if not mats or #mats == 0 then return "" end
    local out, kept = "", 0
    for i, m in ipairs(mats) do
        local piece = " " .. m.link .. (m.qty and ("x" .. m.qty) or "")
        local head = (kept == 0) and " PROVIDE" or ""
        local rest = #mats - i
        local reserve = (rest > 0) and #(" +" .. rest) or 0
        if #out + #head + #piece + reserve > room then break end
        out, kept = out .. head .. piece, kept + 1
    end
    local dropped = #mats - kept
    if dropped > 0 then
        local more = ((kept == 0) and " PROVIDE" or "") .. " +" .. dropped
        if #out + #more <= room then out = out .. more end
    end
    return out
end

-- La ligne « WTB » d'une commande. `targetLink` = lien de l'objet (ou de l'enchantement) commandé ;
-- `mats` = { { link =, qty = }, … } déjà résolus ; `copper` = commission. nil si la commande est privée,
-- sans numéro, ou si même sans matériaux la ligne ne tient pas.
function A.BuildWTB(o, targetLink, mats, copper)
    if not (isPublic(o) and type(targetLink) == "string") then return nil end
    local n = type(o.id) == "string" and o.id:match("%-(%d+)$")
    if not n then return nil end
    local head = "WTB " .. targetLink .. " x" .. (tonumber(o.qty) or 1)
    local price = A.PriceTokens(copper)
    local tail = (price and (" " .. price) or "") .. " #CO" .. n
    if #head + #tail > A.MAX then return nil end
    return head .. provideTokens(mats, A.MAX - #head - #tail) .. tail
end

-- « LFW Enchanting/Tailoring #CO » : les noms anglais des métiers (clés de CraftLink). `links` =
-- { [métier] = lien de métier de l'auteur }, facultatif : un joueur sans l'addon clique le lien et voit
-- les recettes (user, 2026-10-03). Le lien suit son nom comme un métier de plus, après un « / » : un
-- client ≤ v1.43.0 n'y reconnaît aucun métier, le saute, et lit toujours le nom. Un lien qui porte un
-- « / » casserait ce découpage : il n'entre pas. Trop long avec les liens : la ligne part sans eux.
function A.BuildLFW(profs, links)
    if type(profs) ~= "table" or #profs == 0 then return nil end
    local parts = {}
    for _, prof in ipairs(profs) do
        parts[#parts + 1] = prof
        local link = type(links) == "table" and links[prof]
        if type(link) == "string" and link ~= "" and not link:find("/", 1, true) then parts[#parts + 1] = link end
    end
    local line = "LFW " .. table.concat(parts, "/") .. " #CO"
    if #line > A.MAX and links then return A.BuildLFW(profs) end
    return (#line <= A.MAX) and line or nil
end

-- Un lien de métier de Forever (relevé du 2026-09-27) : |Htrade:<GUID du propriétaire>:<sort de rang>:
-- <ligne de métier>|h[Libellé]|h, libellé dans la langue de son client. -> { owner, spell, line, label } ou nil.
function A.ParseTradeLink(link)
    if type(link) ~= "string" then return nil end
    local owner, spell, line, label = link:match("|Htrade:([^:|]+):(%d+):(%d+)[^|]*|h%[([^%]]*)%]|h")
    if not owner then return nil end
    return { owner = owner, spell = tonumber(spell), line = tonumber(line), label = label }
end

-- ------------------------------------------------------------------
-- Lecture
-- ------------------------------------------------------------------
-- Liens sans couleur ni fin de couleur : « |Hitem:765:…|h[Silverleaf]|h ». Couleurs de Forever
-- (« |cnIQ1: ») comme classiques (« |cffffffff »). « × » (UTF-8) vaut « x ».
local function clean(s)
    return (s:gsub("|c[^|]*", ""):gsub("|r", ""):gsub("\195\151", "x"))
end

local LINK = "|H(%a+):(%d+)[^|]*|h([^|]*)|h"

local function target(head)
    local kind, id, name = head:match(LINK)
    if not kind then return nil end
    -- 4ᵉ capture, prise à part : `x:match(…) or ""` ne garderait que la PREMIÈRE (piège Lua connu).
    local _, _, _, after = head:match(LINK .. "(.*)$")
    local qty = tonumber((after or ""):match("^%s*[xX:]%s*(%d+)"))
    local t = { linkType = kind, name = name, qty = qty or 1 }
    if kind == "item" then t.itemID = tonumber(id) else t.spellID = tonumber(id) end
    return t
end

local function materials(provide)
    local mats, more = {}, 0
    for kind, id, following in provide:gmatch("|H(%a+):(%d+)[^|]*|h[^|]*|h([^|]*)") do
        if kind == "item" then
            mats[#mats + 1] = { itemID = tonumber(id), qty = tonumber(following:match("^%s*[xX:]%s*(%d+)")) }
        end
        more = tonumber(following:match("%+(%d+)")) or more
    end
    return mats, more
end

local function parseWTB(rest, author, n)
    local p = rest:upper():find("%sPROVIDE%s")
    local head = p and rest:sub(1, p - 1) or rest
    local t = target(head)
    if not t then return nil end
    t.kind, t.author, t.seq, t.id = "WTB", author, tonumber(n), author .. "-" .. n
    t.mats, t.more = {}, 0
    if p then t.mats, t.more = materials(rest:sub(p + 9)) end
    -- Le prix se lit hors des liens (un nom d'objet pourrait contenir « 5g »).
    t.copper = A.ParsePrice((rest:gsub(LINK, " ")))
    return t
end

-- Un lien se lit par son libellé (« [Forge] » -> « Forge ») : le même métier, nommé puis lié, ne
-- compte qu'une fois.
local function parseLFW(rest, author, resolveProf)
    rest = rest:gsub("|H[^|]*|h%[([^%]]*)%]|h", "%1")
    local profs, seen = {}, {}
    for name in rest:gmatch("[^/]+") do
        name = name:match("^%s*(.-)%s*$")
        local key = (resolveProf and resolveProf(name)) or (not resolveProf and name) or nil
        if key and key ~= "" and not seen[key] then seen[key] = true; profs[#profs + 1] = key end
    end
    if #profs == 0 then return nil end
    return { kind = "LFW", author = author, profs = profs }
end

-- Une ligne de Commerce -> { kind = "WTB" | "LFW", … } ou nil. Seules les lignes qui FINISSENT par
-- l'étiquette `#CO` sont des annonces : le reste est une demande humaine, que le scanner traite déjà.
-- `author` = nom réseau de l'auteur (l'id de la commande en dérive) ; `resolveProf(nom)` -> clé du
-- métier (noms anglais, français, allemands, espagnols : CraftLink:ResolveProfession).
function A.Parse(msg, author, resolveProf)
    if type(msg) ~= "string" or type(author) ~= "string" or author == "" then return nil end
    local body, n = clean(msg):match("^(.-)%s*#[Cc][Oo](%d*)%s*$")
    if not body then return nil end
    local verb, rest = body:match("^%s*(%a+)%s+(.+)$")
    verb = verb and verb:upper()
    -- « #CO0005 » vaut « #CO5 » : l'id doit retomber sur celui de la commande (<auteur>-5).
    if verb == "WTB" and n ~= "" then return parseWTB(rest, author, tostring(tonumber(n))) end
    if verb == "LFW" and n == "" then return parseLFW(rest, author, resolveProf) end
    return nil
end
