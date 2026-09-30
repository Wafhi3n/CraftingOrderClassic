-- Orders_AnnounceRecv.lua — la LECTURE d'une annonce de Commerce (spec annonce-commerce, palier 3).
--
-- Une ligne qui finit par `#CO` a été écrite par l'addon d'un autre porteur. Elle sert de balise :
--   WTB … #CO27  -> un aperçu dans mes Entrantes (id = <auteur>-27), et un bonjour chuchoté à l'auteur.
--                   Il me découvre, et son addon me pousse la commande complète (Orders:OnArtisanOnline),
--                   qui remplace l'aperçu (Inbound:TakeOver, appelé par Orders:_OnNew).
--   LFW … #CO    -> un bonjour seulement : il me répond son profil et sa dispo (Dir:OnHello).
-- Une ligne sans `#CO` n'est pas pour ici : le scanner de Commerce la lit comme une demande humaine.

local COC = CraftingOrderClassic
local R = {}
COC.AnnounceRecv = R

local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)

local function trace(msg) if COC.Trace then COC.Trace:Log("inbound", msg) end end

-- Même confinement que le réseau (CraftLink_Sender, _SameRealmGroup) : un émetteur d'un autre
-- royaume porte « -Royaume » ; on n'accepte que le mien et ceux qui lui sont connectés.
-- `C_AutoComplete` d'abord : le global n'est qu'un alias posé par Blizzard_DeprecatedAutoComplete.
local function sameRealmGroup(author)
    local realm = author:match("%-(.+)$")
    if not realm then return true end
    local mine = GetNormalizedRealmName and GetNormalizedRealmName()
    if mine and realm == mine then return true end
    local connected = (C_AutoComplete and C_AutoComplete.GetAutoCompleteRealms) or GetAutoCompleteRealms
    for _, r in ipairs((connected and connected()) or {}) do
        if r == realm then return true end
    end
    return false
end

-- Nom de métier lu sur la ligne (anglais, ou français, allemand, espagnol) -> clé, ou nil s'il est
-- inconnu (ResolveProfession rend le nom tel quel quand il ne le connaît pas).
local function resolveProf(name)
    if not (CraftLink and CraftLink.ResolveProfession) then return nil end
    local key = CraftLink:ResolveProfession(name)
    return (CraftLink.professions and CraftLink.professions[key]) and key or nil
end

-- Chaque porteur en ville lit la MÊME ligne et chuchote l'auteur, qui répond à chacun (profil, commandes
-- ouvertes) : on étale ces bonjours sur quelques secondes, et on se tait si l'auteur est déjà en contact
-- (en ligne chez moi : ses données, sa commande, sa dispo me parviennent déjà). Relecture protocole, 2026-09-30.
local HELLO_JITTER = 5   -- s

local function hello(author)
    local D = COC.Directory
    if not (D and D.DiscoverPlayer) then return end
    if D.online and D.online[author] then return end
    if C_Timer and C_Timer.After then
        C_Timer.After(math.random() * HELLO_JITTER, function() D:DiscoverPlayer(author) end)
    else
        D:DiscoverPlayer(author)
    end
end

-- L'aperçu d'une commande annoncée, si le scanner l'aurait gardé (métier surveillé). Rend true s'il
-- est posé. Un enchantement (lien de sort) n'a pas d'objet à montrer dans les Entrantes : seul le
-- bonjour part, et la commande complète arrive par chuchotement.
local function preview(t, msg)
    local Inbound, Orders = COC.Inbound, COC.Orders
    if not (Inbound and t.itemID) then return false end
    local prof = Orders and Orders:ProfForItem(t.itemID)
    if not (prof and Inbound:_WantProf(prof)) then return false end
    local Skin = COC.UI and COC.UI.Skin
    Inbound:Add({
        id = t.id, announce = true, buyer = t.author, itemID = t.itemID, itemName = t.name, qty = t.qty,
        price = t.copper and Skin and Skin.PriceText and Skin.PriceText(t.copper) or nil,
        profession = prof, source = "trade", raw = msg,
        canCraft = CraftLink and CraftLink:IKnowRecipeForItem(prof, t.itemID) or false,
    })
    return true
end

-- Une ligne de Commerce. Rend true si c'était une annonce : lue ici, ou écartée exprès (écho, muté,
-- autre royaume), elle ne doit pas non plus devenir une demande humaine dans le scanner.
function R:OnLine(msg, player)
    if type(msg) ~= "string" or type(player) ~= "string" then return false end
    -- Une valeur SECRÈTE (instance) est aussi de type string : elle casserait :match, == et les clés.
    if COC.Api.IsSecret(msg) or COC.Api.IsSecret(player) then return false end
    local author = player:match("^([^%-]+)") or player
    local t = COC.Announce and COC.Announce.Parse(msg, author, resolveProf)
    if not t then return false end
    if author == COC.Api.PlayerName() then return true end   -- ma propre ligne, revenue en écho
    if not sameRealmGroup(player) then trace("annonce d'un autre royaume ignorée : " .. player); return true end
    if COC.Moderation and COC.Moderation:IsMuted(author) then
        trace("annonce de " .. author .. " ignorée (muté)"); return true
    end
    if t.kind == "LFW" then
        trace("LFW de " .. author .. " (" .. table.concat(t.profs, "/") .. ") : bonjour")
        hello(author); return true
    end
    if COC.db and COC.db.orders and COC.db.orders[t.id] then   -- déjà reçue en entier (chuchotement)
        trace("annonce " .. t.id .. " : commande déjà reçue, rien à faire"); return true
    end
    -- Bonjour seulement pour ce que le scanner garderait (portée « mine » : un métier que j'ai) : chaque
    -- porteur en ville qui lit la ligne chuchote l'auteur, inutile d'y ajouter ceux que ça ne concerne pas.
    local Inbound = COC.Inbound
    if preview(t, msg) or (t.spellID and Inbound and Inbound:_WantProf("Enchanting"))
       or (COC.db and COC.db.inboundScope == "all") then
        trace("annonce " .. t.id .. " : bonjour à " .. author)
        hello(author)
    else
        trace("annonce " .. t.id .. " : métier non surveillé (/co scan), ignorée")
    end
    return true
end
