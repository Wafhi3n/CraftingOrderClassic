-- Orders_AnnounceDiscord.lua — la ligne d'une commande de guilde dans le fil Discord de la guilde
-- (spec docs/specs/annonce-discord.md).
--
-- Pourquoi (2026-10-10) : sur Forever, une guilde peut relier son chat à un salon Discord, mais une
-- commande de COC part en messages d'addon, que Discord ne voit jamais. Mesuré le même jour (M1, M2) :
-- un addon écrit dans le fil « Discord » de la guilde depuis un geste du joueur, et ce fil n'existe
-- qu'en flux SÉPARÉ ; en flux mêlé, rien ne dit à un addon que la guilde est reliée (les fonctions de
-- C_Discord qui le diraient sont protégées). Décisions du user : automatique pour une commande publique
-- en portée « Guilde », au clic « Poster » seulement ; flux séparé seulement ; une ligne par minute ;
-- le nom du personnage dans la ligne (Discord affiche le compte Discord, jamais le personnage).
-- Rien n'est jamais écrit dans le chat de guilde ordinaire, et COC ne relit pas cette ligne : un
-- guildien qui a COC reçoit déjà la commande par le réseau.

local COC = CraftingOrderClassic
local L = COC.L
local D = {}
COC.AnnounceDiscord = D

D.COOLDOWN = 60   -- s entre deux lignes Discord du même joueur (compteur à part de celui de Commerce)

local function p(msg) print("|cFF33DD88Crafting Order|r " .. msg) end
local function now() return (time and time()) or 0 end
local function trace(msg) if COC.Trace then COC.Trace:Log("send", "discord : " .. msg) end end
local function secret(v) return COC.Api and COC.Api.IsSecret and COC.Api.IsSecret(v) end

local function isDiscord(s, want)
    local ok, yes = pcall(function() return s.streamType == want end)
    return ok and yes
end

-- Le fil « Discord » de MA guilde : (clubId, streamId), ou nil — pas de guilde, flux mêlé, guilde pas
-- reliée, clubs pas encore prêts juste après la connexion, verrou du chat. Relu à CHAQUE appel : le chef
-- peut délier ou décocher pendant la session. Seulement des fonctions sans `HasRestrictions`.
function D.DiscordStream()
    if not (_G.IsInGuild and _G.IsInGuild()) then return nil end
    local GI, Club = _G.C_GuildInfo, _G.C_Club
    local want = _G.Enum and _G.Enum.ClubStreamType and _G.Enum.ClubStreamType.Discord
    if not (want and GI and GI.IsDiscordStreamSeparate and Club and Club.GetGuildClubId and Club.GetStreams) then
        return nil
    end
    local okS, separate = pcall(GI.IsDiscordStreamSeparate)
    if not (okS and separate == true) then return nil end
    local okC, clubId = pcall(Club.GetGuildClubId)
    if not okC or clubId == nil or secret(clubId) then return nil end
    local okL, streams = pcall(Club.GetStreams, clubId)
    if not okL or type(streams) ~= "table" then return nil end
    for _, s in ipairs(streams) do
        if type(s) == "table" and isDiscord(s, want) then return clubId, s.streamId end
    end
    return nil
end

-- À appeler depuis le clic « Poster » (UI:DoPostOrder), après que la commande est partie : le jeu
-- exige un geste du joueur. Rend true si la ligne est partie. Une ligne perdue ne casse jamais la
-- commande : refus du jeu, flux mêlé ou guilde pas reliée = rien, sans message (le joueur n'a rien
-- demandé de particulier) ; seuls le délai et l'objet pas encore connu lui sont dits.
function D:Post(o)
    if not (o and o.recipient == "Guilde" and o.status == "open") then return false end
    local me = COC.Api and COC.Api.PlayerName and COC.Api.PlayerName()
    if not (me and o.buyer == me) then return false end
    local clubId, streamId = D.DiscordStream()
    if not clubId then trace("pas de fil Discord (flux mêlé ou guilde pas reliée), rien pour " .. tostring(o.id)); return false end
    local left = D.COOLDOWN - (now() - ((COC.db and COC.db.discordLast) or 0))
    if left > 0 then
        p(string.format(L["commande postée sans sa ligne Discord : une par minute au plus (encore %d s)."], left))
        trace("délai, " .. tostring(o.id) .. " sans ligne"); return false
    end
    local line = COC.AnnounceSend and COC.AnnounceSend:DiscordLineFor(o, me)
    if not line then
        p(L["commande postée sans sa ligne Discord : un objet n'est pas encore connu du jeu."])
        trace("ligne impossible pour " .. tostring(o.id)); return false
    end
    local ok, err = pcall(_G.C_Club.SendMessage, clubId, streamId, line)
    if not ok then trace("envoi refusé pour " .. tostring(o.id) .. " : " .. tostring(err)); return false end
    if COC.db then COC.db.discordLast = now() end
    o.discordAt = now()
    trace("ligne de " .. tostring(o.id) .. " envoyée dans le fil Discord")
    p(L["commande annoncée sur le Discord de la guilde."])
    return true
end
