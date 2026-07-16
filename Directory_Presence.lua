-- Directory_Presence.lua — présence : la vérité JEU (amis/guilde) et sa fusion avec la vérité ADDON.
--
-- Deux sources, à ne JAMAIS confondre :
--   * Dir.online     — il RÉPOND en CraftLink (JOIN/LEAVE du canal, ou tout message reçu → _Touch).
--                      C'est la seule qui autorise une commande : ses données sont fraîches.
--   * Dir.onlineGame — le JEU le dit connecté (roster de guilde / liste d'amis / BNet), addon ou pas.
--                      Ne vaut que pour mes RELATIONS : le jeu ne dit rien d'un simple croisé.
-- Sans la seconde, un guildmate connecté SANS l'addon s'affichait « Hors ligne » — faux, et ça
-- ressemblait à une panne réseau. Dir:PresenceOf les fusionne en 3 états pour l'UI.
--
-- Satellite de Directory.lua (anti-monolithe) : y vivent le sweep des relations en ligne
-- (DiscoverFriendsAndGuild) et la requête d'affichage. Chargé APRÈS Directory.lua (.toc).

local COC = CraftingOrderClassic
local Dir = COC.Directory

Dir.onlineGame = {}   -- [playerShort] = true (éphémère, mémoire) — connecté selon le JEU, addon ou pas

local function shortName(n) return n and (n:match("^([^%-]+)") or n) or n end

-- Amis Battle.net (BattleTag) en plus des amis « classiques » : sans ça, un ami ajouté uniquement
-- via BattleTag n'entre jamais dans l'onglet Amis même croisé et en ligne. `fn` reçoit chaque perso.
-- BNGetFriendInfo ne liste QUE les connectés → tout perso rendu ici est en ligne.
function Dir:ForEachBNetWoWFriend(fn)
    if not (BNGetNumFriends and BNGetFriendInfo) then return end
    for i = 1, (BNGetNumFriends() or 0) do
        local _, _, _, _, characterName, _, client, isOnline = BNGetFriendInfo(i)
        if isOnline and characterName and client == (BNET_CLIENT_WOW or "WoW") then fn(characterName) end
    end
end

-- Découverte des amis + guildmates EN LIGNE par whisper (PING+HI) — fiable hors canal global et sans
-- ciblage mutuel. Au login (1er appel → prev vide) on ping TOUS les en-ligne ; ensuite, sur chaque
-- FRIENDLIST/GUILD_ROSTER_UPDATE, on ne ping QUE les nouveaux connectés (transition hors-ligne→en-ligne)
-- pour ne pas re-sonder en boucle les déjà-présents ni les non-porteurs. DiscoverPlayer reste throttlé
-- 60 s/nom en filet de sécurité. `_wasOnlineRel` = statut en-ligne (API jeu) du sweep précédent.
-- Effet de bord VOULU : le sweep publie aussi `onlineGame` (même table) — c'est le seul endroit où
-- l'on lit la vérité de présence du jeu, autant la garder au lieu de la jeter.
function Dir:DiscoverFriendsAndGuild()
    local prev, cur = self._wasOnlineRel or {}, {}
    local function consider(name, online)
        name = shortName(name)
        if not (name and online) then return end
        cur[name] = true
        if not prev[name] then self:DiscoverPlayer(name) end   -- vient de se connecter
    end
    if C_FriendList and C_FriendList.GetNumFriends then
        for i = 1, (C_FriendList.GetNumFriends() or 0) do
            local info = C_FriendList.GetFriendInfoByIndex(i)
            if info then consider(info.name, info.connected) end
        end
    end
    if IsInGuild and IsInGuild() and GetNumGuildMembers then
        for i = 1, (GetNumGuildMembers() or 0) do
            local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
            consider(name, online)
        end
    end
    self:ForEachBNetWoWFriend(function(n) consider(n, true) end)
    self._wasOnlineRel = cur
    self.onlineGame    = cur
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
end

-- Présence d'un joueur en 3 états — POINT DE VÉRITÉ UNIQUE de l'affichage :
--   "online"  = il répond en CraftLink → données fraîches, commande possible (pastille verte)
--   "game"    = le jeu le dit connecté mais il ne répond pas → il n'a pas (ou plus) l'addon,
--               ses données sont celles de sa dernière session (pastille jaune)
--   "offline" = déconnecté, OU hors de ma portée de sondage (un croisé n'est ni ami ni guildmate,
--               le jeu ne me dit rien de lui) → l'absence de preuve reste « hors ligne »
function Dir:PresenceOf(name)
    if not name then return "offline" end
    if self.online and self.online[name] then return "online" end
    if self.onlineGame and self.onlineGame[shortName(name)] then return "game" end
    return "offline"
end
