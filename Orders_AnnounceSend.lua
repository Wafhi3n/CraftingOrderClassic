-- Orders_AnnounceSend.lua — l'ENVOI d'une annonce sur Trade (Services) (spec annonce-commerce, palier 2).
--
-- Le format vit dans Orders_Announce.lua ; ici, ce qui touche au jeu : trouver le canal, résoudre les
-- liens d'objet, poser les garde-fous, écrire la ligne. Décisions du user (2026-09-29) : le canal est
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

-- Pourquoi cette commande ne peut pas partir maintenant (texte au joueur), ou nil.
function S:WhyNot(o, isRemind)
    if not (o and o.buyer == me() and o.status == "open") then return L["seule une commande ouverte, à toi, s'annonce."] end
    if not isPublic(o) then return L["commande privée : elle ne s'annonce pas sur Commerce."] end
    local t = now()
    if isRemind and o.announcedAt and t - o.announcedAt < S.REMIND then
        return string.format(L["déjà annoncée : tu pourras la rappeler dans %d min."], math.ceil((S.REMIND - (t - o.announcedAt)) / 60))
    end
    local last = (COC.db and COC.db.announceLast) or 0
    if t - last < S.COOLDOWN then
        return string.format(L["une annonce par minute au plus : attends encore %d s."], S.COOLDOWN - (t - last))
    end
    if not S.ChannelIndex() then return L["pas de canal Trade (Services) ici : il faut être dans une capitale."] end
    return nil
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
    local idx, name = S.ChannelIndex()
    local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or _G.SendChatMessage
    if not (send and pcall(send, line, "CHANNEL", nil, idx)) then p(L["annonce refusée par le jeu."]); return false end
    local t = now()
    if COC.db then COC.db.announceLast = t end
    o.announcedAt = t
    p(string.format(L["commande annoncée sur %s."], name))
    return true
end
