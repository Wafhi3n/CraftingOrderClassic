-- Orders_AnnounceDiscord.lua — la ligne d'une commande de guilde dans le fil Discord de la guilde
-- (spec docs/specs/annonce-discord.md).
--
-- Pourquoi (2026-10-10) : sur Forever, une guilde peut relier son chat à un salon Discord, mais une
-- commande de COC part en messages d'addon, que Discord ne voit jamais. Mesuré le même jour (M1, M2) :
-- un addon écrit dans le fil « Discord » de la guilde depuis un geste du joueur, et ce fil n'existe
-- qu'en flux SÉPARÉ ; en flux mêlé, rien ne dit à un addon que la guilde est reliée (les fonctions de
-- C_Discord qui le diraient sont protégées). Décisions du user : sur CHOIX du joueur, la ligne de
-- destinataire « Toute la guilde + Discord » (D2 revue le 2026-10-10 : plus d'envoi automatique), au
-- clic « Poster » seulement ; flux séparé seulement ; une ligne par minute ; le nom du personnage dans
-- la ligne (Discord affiche le compte Discord, jamais le personnage). Sur le réseau, rien ne change :
-- la commande reste « Guilde » ; le choix Discord est un drapeau LOCAL du formulaire (UI.postDiscord).
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

-- Le joueur a-t-il choisi « Toute la guilde + Discord » ? `target` = UI.postTarget, `wanted` =
-- UI.postDiscord (posé par cette ligne seule). Un autre destinataire choisi ensuite l'annule de fait.
function D.Wanted(target, wanted) return wanted == true and target == "guild" end

-- La ligne de destinataire : (affichée, choisie). Seulement pour la liste « Guilde », et seulement si
-- la guilde est reliée en flux séparé (`linked` = D.DiscordStream() ~= nil) : ailleurs, rien à offrir.
function D.RowState(group, target, wanted, linked)
    local shown = group == "guild" and linked == true
    return shown, shown and D.Wanted(target, wanted)
end

-- Le chef peut relier, délier ou changer de flux fenêtre ouverte : la ligne « Toute la guilde +
-- Discord » se redessine sur ces événements (libres d'accès, mesurés le 2026-10-10 au basculement de la
-- case). Hors fenêtre, rien : la ligne se relit de toute façon à l'ouverture.
if CreateFrame and COC.Api and COC.Api.RegisterEventsSafe then
    local f = CreateFrame("Frame")
    COC.Api.RegisterEventsSafe(f, { "DISCORD_GUILD_SETTINGS_UPDATE", "DISCORD_LINK_UPDATE" })
    f:SetScript("OnEvent", function()
        local UI = COC.UI
        if UI and UI.frame and UI.frame:IsShown() and UI.RefreshPostArtisans then UI:RefreshPostArtisans() end
    end)
end

local function myName() return COC.Api and COC.Api.PlayerName and COC.Api.PlayerName() end
local function sinceLast() return now() - ((COC.db and COC.db.discordLast) or 0) end

-- Écrit la ligne WTB de `o` dans le fil (clubId, streamId) et la note. Rend true si elle est partie.
local function sendLine(o, who, clubId, streamId)
    local line = COC.AnnounceSend and COC.AnnounceSend:DiscordLineFor(o, who)
    if not line then
        p(L["commande postée sans sa ligne Discord : un objet n'est pas encore connu du jeu."])
        trace("ligne impossible pour " .. tostring(o.id)); return false
    end
    local ok, err = pcall(_G.C_Club.SendMessage, clubId, streamId, line)
    if not ok then trace("envoi refusé pour " .. tostring(o.id) .. " : " .. tostring(err)); return false end
    if COC.db then COC.db.discordLast = now() end
    o.discordAt, o.discordClub = now(), clubId   -- la guilde qui a reçu la ligne : seule à recevoir l'annulation
    trace("ligne de " .. tostring(o.id) .. " envoyée dans le fil Discord")
    p(L["commande annoncée sur le Discord de la guilde."])
    return true
end

-- ------------------------------------------------------------------
-- La file (D5 revue par le user le 2026-10-10 : une ligne arrivée dans la minute ATTEND au lieu d'être
-- perdue). `C_Club.SendMessage` exige un geste du joueur (HasRestrictions ; fait mesuré, skill public
-- wow-forever-api) : pas de minuteur, la ligne part au premier clic ou à la première touche du joueur
-- une fois la minute écoulée (le motif de CraftLink_TextQueue, pattern Deathlog). La file vit SUR LES
-- COMMANDES (`o.discordQueued`, `o.discordQueueClub`, SavedVariables) : un /reload la garde.
-- ------------------------------------------------------------------
local pending   -- mes commandes dont la ligne attend, première arrivée en tête ; nil = pas encore relue

local function queue()
    if pending then return pending end
    local db, who = COC.db, myName()
    if not (db and db.orders and who) then return nil end
    pending = {}
    for _, o in pairs(db.orders) do
        if o.discordQueued and not o.discordAt and o.status == "open" and o.buyer == who then pending[#pending + 1] = o end
    end
    table.sort(pending, function(a, b) return a.discordQueued < b.discordQueued end)
    return pending
end

-- Les crochets d'input, posés au premier besoin seulement (un joueur sans Discord n'en a aucun). Hors
-- combat : `SetPropagateKeyboardInput` y est restreint. `EnableKeyboard` est requis pour recevoir
-- OnKeyDown, et la propagation pour ne pas avaler les touches (relevés de CraftLink_TextQueue).
local function installDrain()
    if D._drainInstalled or not CreateFrame then return end
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_REGEN_ENABLED")
        f:SetScript("OnEvent", function(self) self:UnregisterAllEvents(); installDrain() end)
        return
    end
    D._drainInstalled = true
    local function drain() D:Drain() end
    if WorldFrame and WorldFrame.HookScript then WorldFrame:HookScript("OnMouseDown", drain) end
    local kf = CreateFrame("Frame", nil, UIParent)
    if kf.EnableKeyboard then kf:EnableKeyboard(true) end
    if kf.SetPropagateKeyboardInput then kf:SetPropagateKeyboardInput(true) end
    kf:SetScript("OnKeyDown", drain)
end

-- À chaque clic dans le monde et à chaque touche (CHEMIN CHAUD : la file vide sort à la 1re ligne).
-- Une ligne par minute, jamais en combat. La ligne ne part que pour la MÊME guilde et le MÊME
-- personnage qu'au clic « Poster » ; une commande annulée entre-temps sort de la file sans rien écrire.
function D:Drain()
    local q = pending or queue()
    if not (q and q[1]) then return end
    if sinceLast() < D.COOLDOWN or (_G.InCombatLockdown and _G.InCombatLockdown()) then return end
    local o = table.remove(q, 1)
    local club = o.discordQueueClub
    o.discordQueued, o.discordQueueClub = nil, nil
    local who = myName()
    if not (o.status == "open" and who and o.buyer == who) then trace("file : " .. tostring(o.id) .. " n'est plus à poster"); return end
    local clubId, streamId = D.DiscordStream()
    if not clubId or clubId ~= club then trace("file : " .. tostring(o.id) .. " hors de sa guilde, abandonnée"); return end
    sendLine(o, who, clubId, streamId)
end

-- À appeler depuis le clic « Poster » (UI:DoPostOrder), après que la commande est partie. Rend true si
-- la ligne est partie, "queued" si elle attend son tour, false sinon. Une ligne perdue ne casse jamais
-- la commande : refus du jeu, flux mêlé ou guilde pas reliée = rien, sans message (le joueur n'a rien
-- demandé de particulier) ; l'attente et l'objet pas encore connu lui sont dits.
function D:Post(o)
    if not (o and o.recipient == "Guilde" and o.status == "open") then return false end
    local who = myName()
    if not (who and o.buyer == who) then return false end
    local clubId, streamId = D.DiscordStream()
    if not clubId then trace("pas de fil Discord (flux mêlé ou guilde pas reliée), rien pour " .. tostring(o.id)); return false end
    local q = queue() or {}
    local left = D.COOLDOWN - sinceLast()
    if left <= 0 and not q[1] then return sendLine(o, who, clubId, streamId) end
    o.discordQueued, o.discordQueueClub = now(), clubId
    q[#q + 1] = o
    pending = q
    installDrain()
    p(string.format(L["ligne Discord en attente : elle partira dans %d s environ (une par minute)."],
        math.max(left, 0) + D.COOLDOWN * (#q - 1)))
    trace("file : " .. tostring(o.id) .. " en attente (" .. #q .. ")")
    return "queued"
end

-- Après un /reload, une file gardée dans les commandes reprend : les crochets se reposent.
if CreateFrame then
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(self)
        self:UnregisterAllEvents()
        local q = queue()
        if q and q[1] then installDrain() end
    end)
end

-- Appelée par Orders:Cancel (clic « Annuler » du Carnet, `/co cancel` tapée : un geste du joueur).
-- Écrit « CANCEL [objet] @Prénom Nom #CO<n> » pour que le bot barre la carte (D8, décisions du user le
-- 2026-10-10 : carte barrée, et l'annulation passe hors du délai d'une minute, sans le toucher). Une
-- fois par commande, seulement si sa ligne WTB est partie, par son auteur (pas un reroll : le `@nom`
-- doit être celui de la carte), et dans la MÊME guilde (un changement de guilde ne l'envoie nulle part).
function D:Cancel(o)
    if not (o and o.discordAt and o.discordClub and not o.discordCancelAt) then return false end
    local me = COC.Api and COC.Api.PlayerName and COC.Api.PlayerName()
    if not (me and o.buyer == me) then trace("annulation de " .. tostring(o.id) .. " par un autre perso : rien"); return false end
    local clubId, streamId = D.DiscordStream()
    if not clubId or clubId ~= o.discordClub then
        trace("annulation de " .. tostring(o.id) .. " : pas le fil Discord de la guilde d'origine, rien"); return false
    end
    local S = COC.AnnounceSend
    local line = COC.Announce.BuildDiscordCancel(o, S and S:TargetLink(o), me)
    if not line then return false end
    local ok, err = pcall(_G.C_Club.SendMessage, clubId, streamId, line)
    if not ok then trace("annulation refusée pour " .. tostring(o.id) .. " : " .. tostring(err)); return false end
    o.discordCancelAt = now()
    trace("annulation de " .. tostring(o.id) .. " envoyée dans le fil Discord")
    p(L["annulation signalée sur le Discord de la guilde."])
    return true
end
