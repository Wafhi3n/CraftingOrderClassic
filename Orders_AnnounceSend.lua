-- Orders_AnnounceSend.lua — l'ENVOI d'une annonce sur Trade (Services) (spec annonce-commerce, palier 2).
--
-- Le format vit dans Orders_Announce.lua ; ici, ce qui touche au jeu : trouver le canal, résoudre les
-- liens d'objet, garder mon lien de métier, poser les garde-fous, écrire la ligne. Décisions du user (2026-09-29) : le canal est
-- Trade (Services), celui des services d'artisans ; une annonce part d'un CLIC (le jeu l'exige, et un
-- espace public ne se remplit pas tout seul) ; « Rappeler » au plus une fois par quart d'heure et par
-- commande. Mesuré le même soir (constat C15) : l'addon écrit sur ce canal depuis une action du joueur,
-- et le canal relie toutes les capitales.

local COC = CraftingOrderClassic
local L = COC.L
local S = {}
COC.AnnounceSend = S

S.COOLDOWN = 60    -- s entre deux annonces du même joueur (le serveur bloque vite, et c'est un espace public)
S.REMIND   = 900   -- s : une commande se rappelle au plus une fois par quart d'heure

local function p(msg) print("|cFF33DD88Crafting Order|r " .. msg) end
local function now() return (time and time()) or 0 end
local function me() return COC.Api and COC.Api.PlayerName and COC.Api.PlayerName() end

-- Trade (Services) : nom localisé par le client (« Trade (Services) - English », « Commerce (Services) »,
-- « Handel (Dienstleistungen) », « Comercio (Servicios) »). nil hors d'une capitale.
local TRADE   = { "trade", "commerce", "handel", "comercio" }
local SERVICE = { "servic", "dienst" }

local function has(low, list)
    for _, w in ipairs(list) do if low:find(w, 1, true) then return true end end
    return false
end

function S.ChannelIndex()
    if type(GetChannelName) ~= "function" then return nil end
    for i = 1, 20 do
        local _, name = GetChannelName(i)
        if type(name) == "string" then
            local low = name:lower()
            if has(low, TRADE) and has(low, SERVICE) then return i, name end
        end
    end
end

-- Forever : pas de GetItemInfo global (C_Item.GetItemInfo). Un objet pas encore en cache rend nil.
local function itemLink(id)
    local fn = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo
    if not (fn and id) then return nil end
    local ok, _, link = pcall(fn, id)
    return ok and link or nil
end

local function spellLink(id)
    local fn = (C_Spell and C_Spell.GetSpellLink) or _G.GetSpellLink
    if not (fn and id) then return nil end
    local ok, link = pcall(fn, id)
    return ok and link or nil
end

-- Les réactifs FOURNIS par l'acheteur, en liens, avec leur quantité (réactif de la recette × quantité
-- commandée) quand la recette est connue de CraftLink ; sinon le lien seul.
local function providedMats(o)
    local per = {}
    local c = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    if c and c.RecipeReagents and o.spellID and o.profession then
        for _, rg in ipairs(c:RecipeReagents(o.profession, o.spellID) or {}) do per[rg[1]] = rg[2] end
    end
    local out = {}
    for _, id in ipairs(o.provided or {}) do
        local link = itemLink(id)
        if link then out[#out + 1] = { link = link, qty = per[id] and per[id] * (tonumber(o.qty) or 1) or nil } end
    end
    return out
end

local function isPublic(o) return o.recipient == nil or o.recipient == "" or o.recipient == "Tous" end

-- Le délai d'une minute et la présence du canal : communs à la commande et à la dispo (un seul
-- compteur, c'est le même joueur sur le même canal). Texte au joueur, ou nil.
local function channelWhyNot()
    local left = S.COOLDOWN - (now() - ((COC.db and COC.db.announceLast) or 0))
    if left > 0 then return string.format(L["une annonce par minute au plus : attends encore %d s."], left) end
    if not S.ChannelIndex() then return L["pas de canal Trade (Services) ici : il faut être dans une capitale."] end
    return nil
end

-- Écrit `line` sur Trade (Services) et arme le délai. Rend le nom du canal, ou nil (refus déjà dit).
local function write(line)
    local idx, name = S.ChannelIndex()
    local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or _G.SendChatMessage
    if not (idx and send and pcall(send, line, "CHANNEL", nil, idx)) then p(L["annonce refusée par le jeu."]); return nil end
    if COC.db then COC.db.announceLast = now() end
    return name
end

-- Pourquoi cette commande ne peut pas partir maintenant (texte au joueur), ou nil.
function S:WhyNot(o, isRemind)
    if not (o and o.buyer == me() and o.status == "open") then return L["seule une commande ouverte, à toi, s'annonce."] end
    if not isPublic(o) then return L["commande privée : elle ne s'annonce pas sur Commerce."] end
    local t = now()
    if isRemind and o.announcedAt and t - o.announcedAt < S.REMIND then
        return string.format(L["déjà annoncée : tu pourras la rappeler dans %d min."], math.ceil((S.REMIND - (t - o.announcedAt)) / 60))
    end
    return channelWhyNot()
end

-- Le clic « droit » du Carnet propose-t-il d'annoncer (ou de rappeler) cette commande ?
function S:CanRemind(o)
    if not (o and o.buyer == me() and o.status == "open" and isPublic(o)) then return false end
    return not o.announcedAt or (now() - o.announcedAt) >= S.REMIND
end

-- La ligne de la commande, ou nil (objet pas encore en cache, commande privée…).
function S:LineFor(o)
    local target = (o.itemID and itemLink(o.itemID)) or (o.spellID and spellLink(o.spellID))
    if not target then return nil end
    local Skin = COC.UI and COC.UI.Skin
    local copper = Skin and Skin.PriceCopper and Skin.PriceCopper(o.price) or nil
    return COC.Announce.BuildWTB(o, target, providedMats(o), copper)
end

-- Écrit la ligne sur Trade (Services). À appeler depuis un CLIC du joueur. Rend true si elle est partie.
function S:Post(o, isRemind)
    local why = self:WhyNot(o, isRemind)
    if why then p(why); return false end
    local line = self:LineFor(o)
    if not line then p(L["annonce impossible : un objet n'est pas encore connu du jeu, réessaie dans un instant."]); return false end
    local name = write(line)
    if not name then return false end
    o.announcedAt = now()
    if COC.Trace then COC.Trace:Log("send", "annonce " .. tostring(o.id) .. " sur " .. tostring(name)) end
    p(string.format(L["commande annoncée sur %s."], name))
    return true
end

-- ------------------------------------------------------------------
-- Mon lien de métier, pour la ligne LFW (user, 2026-10-03) : un joueur sans l'addon le clique et voit
-- mes recettes. Le jeu ne le donne que fenêtre de MON métier ouverte (`GetTradeSkillListLink`, réf.
-- wow-forever-api `metiers-et-objets`) : on le garde à chaque ouverture, par personnage (GUID, les
-- SavedVariables sont au compte) et par métier, pour /co lfw tapé fenêtre fermée. N'entre qu'un lien
-- à MOI (GUID) dont le libellé se résout en métier : jamais celui d'une vue liée ou de la guilde.
-- ⚠️ À ÉPROUVER au banc : un lien gardé d'une session précédente s'ouvre-t-il encore chez l'autre ?
-- Un lien fabriqué pour un métier jamais partagé s'ouvre vide (relevé du 2026-09-27).
-- ------------------------------------------------------------------
local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end
local function myGUID() return UnitGUID and UnitGUID("player") end

local function profOfLabel(label)
    local c = CL()
    if not (c and c.ResolveProfession and label and label ~= "") then return nil end
    local key = c:ResolveProfession(label)
    return (c.professions and c.professions[key]) and key or nil
end

-- Relit le lien du métier ouvert et le garde. Rend la clé du métier gardé, ou nil. Même garde que le
-- bouton « lien » de Blizzard (`CanTradeSkillListLink`, Blizzard_ProfessionsCrafting.lua) : jamais un
-- lien que le jeu lui-même ne proposerait pas.
function S.CaptureTradeLink()
    local ts, c = C_TradeSkillUI, CL()
    if not (ts and ts.GetTradeSkillListLink and COC.db) then return nil end
    if ts.CanTradeSkillListLink then
        local ok, can = pcall(ts.CanTradeSkillListLink)
        if not (ok and can) then return nil end
    end
    if c and c.IsOwnProfessionOpen and not c:IsOwnProfessionOpen() then return nil end
    local ok, link = pcall(ts.GetTradeSkillListLink)
    if not (ok and type(link) == "string") or COC.Api.IsSecret(link) then return nil end
    local t, guid = COC.Announce.ParseTradeLink(link), myGUID()
    if not (t and guid and t.owner == guid) then return nil end
    local key = profOfLabel(t.label)
    if not key then return nil end
    COC.db.tradeLinks = COC.db.tradeLinks or {}
    COC.db.tradeLinks[guid] = COC.db.tradeLinks[guid] or {}
    COC.db.tradeLinks[guid][key] = link
    return key
end

-- Mon lien pour ce métier et sa provenance (« frais » : fenêtre ouverte ; « gardé » : d'une ouverture
-- précédente), ou nil. La provenance va dans la trace : c'est ce que le banc doit départager.
function S.TradeLink(profKey)
    local fresh = S.CaptureTradeLink() == profKey
    local guid = myGUID()
    local mine = guid and COC.db and COC.db.tradeLinks and COC.db.tradeLinks[guid]
    local link = mine and mine[profKey]
    if not link then return nil end
    return link, fresh and "frais" or "gardé"
end

if CreateFrame and COC.Api and COC.Api.RegisterEventsSafe then
    local f = CreateFrame("Frame")
    COC.Api.RegisterEventsSafe(f, { "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE" })
    f:SetScript("OnEvent", function() S.CaptureTradeLink() end)
end

-- La dispo d'un artisan (palier 4) : « LFW <métier> #CO », quand il l'ACTIVE et seulement si la case
-- « Annoncer en Commerce » est cochée (même réglage que le formulaire de commande). À appeler depuis
-- son clic (bouton, bande « Chercher du travail », /co lfw) — jamais depuis le renouvellement
-- automatique de la dispo (ticker, riposte) : le jeu exige un geste, et Commerce n'est pas à nous.
-- Le lien se lit dans le même geste, sans délai, avant l'écriture.
function S:PostLFW(profKey)
    if not (profKey and COC.db and COC.db.announceTrade) then return false end
    local why = channelWhyNot()
    if why then p(why); return false end
    local link, from = S.TradeLink(profKey)
    local line = COC.Announce.BuildLFW({ profKey }, link and { [profKey] = link })
    local name = line and write(line)
    if not name then return false end
    if COC.Trace then
        local how = (line:find("|Htrade:", 1, true) and (" avec le lien " .. from)) or " sans lien"
        COC.Trace:Log("send", "dispo " .. profKey .. " annoncée sur " .. tostring(name) .. how)
    end
    p(string.format(L["dispo annoncée sur %s."], name))
    return true
end
