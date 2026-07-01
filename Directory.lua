-- Crafting Order - Classic — Directory : l'annuaire des GENS (présence + qui peut crafter quoi).
--
-- Côté PRODUIT (pas dans la lib) : la relecture sépare le registre des recettes (CraftLink) de
-- l'annuaire des gens (ici). Construit à partir du transport CraftLink :
--   * présence : events JOIN/LEAVE du canal caché (pas de heartbeat) → Dir.online.
--   * recettes des autres : verbe RK reçu sur le canal global → Dir.roster (cache persistant).
--   * proximité : PING/PONG en YELL → porteurs de l'addon autour de soi.
--
-- Discipline cache : réseau → Dir.roster (mémoire = COC.db.roster, persistant) → UI. L'UI ne lit
-- QUE le cache, jamais le réseau.

local COC = CraftingOrderClassic
local Dir = {}
COC.Directory = Dir
local L = COC.L

local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)

Dir.online = {}   -- [playerShort] = true (éphémère, mémoire)

local function now() return (GetTime and GetTime()) or 0 end

-- ------------------------------------------------------------------
-- Réception
-- ------------------------------------------------------------------
function Dir:OnPresence(kind, who)
    if not who then return end
    -- Canal CUSTOM dédié (CraftLinkNet) : tout joiner EST un porteur (pas de bruit de joueurs lambda),
    -- donc on réagit à tous les JOIN/LEAVE, connus ou pas — un nouveau porteur s'annonce aussi via HI
    -- au bringup, mais réagir ici accélère sa découverte sans risque de spam.
    if kind == "join" then
        self.online[who] = true
        local r = self.roster and self.roster[who]
        if r and r.source == "added" then
            local msg = string.format(L["ton artisan |cFFFFFFFF%s|r est en ligne."], who)
            print("|cFF33DD88Crafting Order|r " .. msg)
            if COC.UI and COC.UI.Toast then COC.UI:Toast(msg) end
        end
        if COC.Orders and COC.Orders.OnArtisanOnline then COC.Orders:OnArtisanOnline(who) end  -- push commande ciblée
        self:Announce()                 -- un nouveau arrive → je (re)publie mes recettes
    else
        self.online[who] = nil
    end
    if COC.UI and COC.UI.Refresh then COC.UI:Refresh() end
end

-- Un artisan AJOUTÉ À LA MAIN qu'on voit enfin en ligne avec l'addon → liaison confirmée (#6).
function Dir:_NoteLinked(name, r)
    if r and r.manual and not r.linked then
        r.linked = true
        print("|cFF33DD88Crafting Order|r |cFFFFFFFF" .. name ..
            "|r est en ligne avec l'addon — artisan lié.")
    end
end

-- ------------------------------------------------------------------
-- Classement guilde / amis : on croise les porteurs DÉCOUVERTS (canal/proximité) avec le roster
-- de guilde (GetGuildRosterInfo) et la liste d'amis (C_FriendList) pour leur donner la bonne source.
-- Détecter « a l'addon » reste le rôle du canal (RK/SK) ; ici on ne fait que CLASSER.
-- ------------------------------------------------------------------
local function shortName(n) return n and (n:match("^([^%-]+)") or n) or n end

-- Amis Battle.net (BattleTag) en plus des amis « classiques » : sans ça, un ami ajouté uniquement
-- via BattleTag n'entre jamais dans l'onglet Amis même croisé et en ligne. `fn` reçoit chaque perso.
local function forEachBNetWoWFriend(fn)
    if not (BNGetNumFriends and BNGetFriendInfo) then return end
    for i = 1, (BNGetNumFriends() or 0) do
        local _, _, _, _, characterName, _, client, isOnline = BNGetFriendInfo(i)
        if isOnline and characterName and client == (BNET_CLIENT_WOW or "WoW") then fn(characterName) end
    end
end

function Dir:ScanRelations()
    self._guildSet, self._friendSet = {}, {}
    if IsInGuild and IsInGuild() and GetNumGuildMembers then
        for i = 1, (GetNumGuildMembers() or 0) do
            local name = GetGuildRosterInfo(i)
            if name then self._guildSet[shortName(name)] = true end
        end
    end
    if C_FriendList and C_FriendList.GetNumFriends then
        for i = 1, (C_FriendList.GetNumFriends() or 0) do
            local info = C_FriendList.GetFriendInfoByIndex(i)
            if info and info.name then self._friendSet[shortName(info.name)] = true end
        end
    end
    forEachBNetWoWFriend(function(n) self._friendSet[shortName(n)] = true end)
    self:ReclassifyAll()
end

-- Source naturelle d'un joueur (guilde prioritaire sur amis), ou nil si ni l'un ni l'autre.
function Dir:ClassifySource(name)
    name = shortName(name)
    if self._guildSet  and self._guildSet[name]  then return "guild"  end
    if self._friendSet and self._friendSet[name] then return "friend" end
    return nil
end

-- Applique la source à une entrée roster. On stampe TOUJOURS les drapeaux de relation
-- (isGuild/isFriend) — même sur un ajout manuel « added » — pour que le routage « Amis »/« Guilde »
-- (Orders:_ScopeMatch) reconnaisse un artisan ajouté qui est AUSSI ami/guildmate en jeu. Le `source`
-- d'affichage, lui, reste figé sur « added » pour un ajout manuel (catégorie de la sidebar).
function Dir:_ApplySource(name, r)
    if not r then return end
    local sn = shortName(name)
    r.isGuild  = (self._guildSet  and self._guildSet[sn])  == true
    r.isFriend = (self._friendSet and self._friendSet[sn]) == true
    if r.manual then return end
    r.source = self:ClassifySource(name) or r.source or "recent"
end

function Dir:ReclassifyAll()
    for name, r in pairs(self.roster or {}) do self:_ApplySource(name, r) end
    if COC.UI and COC.UI.Refresh then COC.UI:Refresh() end
end

-- Entretien de la « mini BDD » des métiers : on GARDE à vie guilde/amis/ajoutés (relations) ;
-- on purge les simples « croisés » trop vieux + on plafonne leur nombre (anti-explosion serveur actif).
function Dir:PruneRoster(maxAgeDays, maxRecent)
    if not self.roster then return end
    local cutoff = time() - (maxAgeDays or 30) * 86400
    local recents = {}
    for name, r in pairs(self.roster) do
        local keep = r.manual or r.source == "guild" or r.source == "friend" or r.source == "added"
        if not keep then
            if (r.lastSeen or 0) < cutoff then self.roster[name] = nil
            else recents[#recents + 1] = { name = name, t = r.lastSeen or 0 } end
        end
    end
    maxRecent = maxRecent or 500
    if #recents > maxRecent then
        table.sort(recents, function(a, b) return a.t > b.t end)   -- garde les plus récents
        for i = maxRecent + 1, #recents do self.roster[recents[i].name] = nil end
    end
end

-- RK reçu (recettes d'un autre) → cache roster persistant.
function Dir:OnRK(sender, message)
    if not (sender and CraftLink) then return end
    local prof, hex, dv = CraftLink:ParseRK(message)
    if not prof then return end
    local r = self.roster[sender]; if not r then r = {}; self.roster[sender] = r end
    r.recipes = r.recipes or {}
    r.recipes[prof] = hex
    r.recipeDV = dv
    self:_ApplySource(sender, r)          -- guilde/ami si reconnu, sinon « recent »
    r.lastSeen = time()
    self.online[sender] = true          -- présence passive : un message prouve la présence
    self:_NoteLinked(sender, r)
end

-- Garantit une entrée roster pour un joueur QUI A RÉPONDU (a donc l'addon) : classe la source
-- (guilde/ami/ajouté sinon « recent » = Croisé/Met), marque en ligne, horodate. Idempotent.
function Dir:_Touch(name)
    if not name then return end
    local r = self.roster and self.roster[name]
    if not r then r = {}; self.roster = self.roster or {}; self.roster[name] = r end
    self:_ApplySource(name, r)
    r.lastSeen = time()
    local wasOnline = self.online[name]
    self.online[name] = true
    self:_NoteLinked(name, r)
    -- Transition hors-ligne → en ligne : pousse-lui mes commandes ouvertes qui le concernent (whisper).
    if not wasOnline and COC.Orders and COC.Orders.OnArtisanOnline then COC.Orders:OnArtisanOnline(name) end
    return r
end

-- HI reçu (un client sollicite l'annuaire). DIRIGÉ (whisper) → je réponds DIRECTEMENT à l'émetteur
-- (fiable sans canal). GLOBAL → réponse jittée en broadcast (anti-burst).
function Dir:OnHello(sender, _, distribution)
    if not CraftLink then return end
    self:_Touch(sender)
    if distribution == "WHISPER" then
        self:AnnounceTo(sender)
    elseif C_Timer then
        C_Timer.After(math.random() * 3, function() Dir:Announce() end)
    end
end

-- PING reçu → PONG sur la MÊME portée (whisper si dirigé, sinon yell). Dirigé → j'envoie aussi mes
-- métiers à l'émetteur (le « croiseur » voit mes métiers tout de suite, sans attendre un scan).
function Dir:OnPing(sender, _, distribution)
    if not CraftLink then return end
    self:_Touch(sender)
    if distribution == "WHISPER" and sender then
        CraftLink:Send("PONG", "whisper", sender)
        self:AnnounceTo(sender)
    else
        CraftLink:Send("PONG", "yell")
    end
end

-- PONG reçu (l'autre A l'addon) → on le connaît : entrée roster (Croisé) + en ligne.
function Dir:OnPong(sender)
    self:_Touch(sender)
    if COC.UI and COC.UI.Refresh then COC.UI:Refresh() end
end

-- ------------------------------------------------------------------
-- Émission
-- ------------------------------------------------------------------
-- Publie MES recettes (un RK par métier) + MES niveaux de skill sur le canal global.
function Dir:Announce()
    if not (CraftLink and CraftLink:IsNetworkReady()) then return end
    for _, prof in ipairs(CraftLink:MyProfessions()) do
        local msg = CraftLink:BuildRK(prof)
        if msg then CraftLink:Send(msg, "global") end
    end
    self:AnnounceSkills()
end

-- Publie MON profil DIRECTEMENT à un joueur (whisper) — fiable hors canal/guilde. Sert aux réponses
-- de découverte dirigée (HI/PING whisper) : l'autre reçoit mes métiers + niveaux immédiatement.
function Dir:AnnounceTo(target)
    if not (CraftLink and target) then return end
    for _, prof in ipairs(CraftLink:MyProfessions()) do
        local msg = CraftLink:BuildRK(prof)
        if msg then CraftLink:Send(msg, "whisper", target) end
    end
    local sk = self:_SkillPayload()
    if sk then CraftLink:Send(sk, "whisper", target) end
end

-- Découverte DIRIGÉE d'un joueur (croisement / ajout manuel) : on lui chuchote PING + HI. S'il a
-- l'addon, il répond (PONG + son profil) → il atterrit dans Croisés/Met avec ses métiers. S'il ne
-- l'a pas, rien (les addon-messages whisper sont invisibles pour lui). Throttlé par nom (anti-spam).
function Dir:DiscoverPlayer(name)
    name = shortName(name)
    if not (CraftLink and name and name ~= "") then return end
    if name == shortName(UnitName and UnitName("player") or "") then return end
    self._lastPing = self._lastPing or {}
    local t = now()
    if (self._lastPing[name] or 0) + 60 > t then return end   -- 1 ping / 60 s / joueur
    self._lastPing[name] = t
    CraftLink:Send("PING", "whisper", name)
    CraftLink:Send("HI",   "whisper", name)
end

-- Balise TEXTE reçue sur le canal : un porteur (peut-être INCONNU) annonce sa présence. C'est le SEUL
-- rôle du canal — la distribution CHANNEL des AddonMessages est muette entre comptes d'un même
-- Battle.net (testé) → on bascule aussitôt en découverte dirigée whisper (auto-throttlée 60 s/nom),
-- après quoi tout le trafic de données passe en whisper (fiable). Voir CraftLink_Transport:SendBeacon.
function Dir:OnBeacon(who)
    self:DiscoverPlayer(who)
end

-- Re-publication throttlée (3 s) — appelée quand mes recettes changent (plan appris) ou skill gagné,
-- pour que les autres reçoivent mes RK/SK à jour sans spammer le réseau.
function Dir:AnnounceThrottled()
    if not C_Timer then return self:Announce() end
    if self._annTimer then return end
    self._annTimer = true
    C_Timer.After(3, function() self._annTimer = nil; Dir:Announce() end)
end

-- ------------------------------------------------------------------
-- Niveaux de compétence (SK) + réputation → déplacés dans Directory_Skills.lua (couche « profil »,
-- anti-monolithe). CaptureSkills / _SkillPayload / AnnounceSkills / OnSkill restent sur COC.Directory.
-- ------------------------------------------------------------------

-- Découverte des amis + guildmates EN LIGNE par whisper (PING+HI) — fiable hors canal global et sans
-- ciblage mutuel. Au login (1er appel → prev vide) on ping TOUS les en-ligne ; ensuite, sur chaque
-- FRIENDLIST/GUILD_ROSTER_UPDATE, on ne ping QUE les nouveaux connectés (transition hors-ligne→en-ligne)
-- pour ne pas re-sonder en boucle les déjà-présents ni les non-porteurs. DiscoverPlayer reste throttlé
-- 60 s/nom en filet de sécurité. `_wasOnlineRel` = statut en-ligne (API jeu) du sweep précédent.
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
    forEachBNetWoWFriend(function(n) consider(n, true) end)
    self._wasOnlineRel = cur
end

-- Sollicite l'annuaire (sur action utilisateur) : HI global + PING proximité + re-ping des connus.
function Dir:Refresh()
    if not CraftLink then return end
    CraftLink:Send("HI", "global")
    CraftLink:Send("PING", "yell")
    -- /co refresh = action JOUEUR (hardware event) → on peut émettre la balise TEXTE de découverte
    -- (annonce ma présence aux INCONNUS du canal ; eux me découvriront ensuite en whisper).
    if CraftLink.SendBeacon then CraftLink:SendBeacon() end
    self:RediscoverKnown(true)   -- refresh manuel : re-ping aussi les croisés récents
end

-- Re-ping (whisper dirigé) mes artisans connus → ils se rallument tout seuls quand ils sont en ligne,
-- SANS dépendre du canal caché (peu fiable). DiscoverPlayer s'auto-throttle (60 s/nom) ; les erreurs
-- « joueur hors-ligne » sont filtrées (cf. _InstallWhisperErrorFilter).
--   * Ajoutés/manuels : toujours (petite liste de favoris → maintien de présence périodique).
--   * Croisés (recent) : seulement si `includeRecent` (au login / refresh), plafonné aux plus récents
--     pour ne pas spammer le réseau — sinon ils ne se rallument qu'en re-survolant après un relog.
function Dir:RediscoverKnown(includeRecent)
    local recents = {}
    for name, r in pairs(self.roster or {}) do
        if r.manual or r.source == "added" then self:DiscoverPlayer(name)
        elseif includeRecent and (r.source or "recent") == "recent" then
            recents[#recents + 1] = { name = name, t = r.lastSeen or 0 }
        end
    end
    if #recents > 0 then
        table.sort(recents, function(a, b) return a.t > b.t end)
        for i = 1, math.min(30, #recents) do self:DiscoverPlayer(recents[i].name) end
    end
end

-- Supprime le message système « No player named "X" is currently online. » quand X est un nom qu'on
-- vient de ping (découverte whisper) → pas de spam rouge en sondant des artisans hors-ligne.
function Dir:_InstallWhisperErrorFilter()
    if self._errFilter or not ChatFrame_AddMessageEventFilter then return end
    self._errFilter = true
    local raw = ERR_CHAT_PLAYER_NOT_FOUND_S or "No player named \"%s\" is currently online."
    local pat = "^" .. raw:gsub("[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%0"):gsub("%%%%s", "(.-)") .. "$"
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(_, _, msg)
        local who = msg and msg:match(pat)
        if who then
            who = shortName(who)
            if Dir._lastPing and Dir._lastPing[who] and (now() - Dir._lastPing[who]) < 15 then
                return true   -- avale l'erreur : c'était notre sondage de découverte
            end
        end
        return false
    end)
end

-- ------------------------------------------------------------------
-- Requêtes (lisent le CACHE, jamais le réseau)
-- ------------------------------------------------------------------
function Dir:CountOnline()
    local n = 0; for _ in pairs(self.online) do n = n + 1 end; return n
end

function Dir:CountKnownCrafters()
    local n = 0; for _ in pairs(self.roster) do n = n + 1 end; return n
end

-- Joueurs (du cache) qui CONNAISSENT la recette spellID d'un métier, en ligne d'abord.
function Dir:WhoCanCraft(prof, spellID)
    if not CraftLink then return {} end
    local myDV, out = CraftLink:DataVersion(), {}
    for player, r in pairs(self.roster) do
        local hex = r.recipes and r.recipes[prof]
        if hex and r.recipeDV == myDV and CraftLink:HasBit(prof, hex, spellID) then
            out[#out + 1] = { player = player, online = self.online[player] == true }
        end
    end
    table.sort(out, function(a, b)
        if a.online ~= b.online then return a.online end
        return a.player < b.player
    end)
    return out
end

-- ------------------------------------------------------------------
-- Démarrage
-- ------------------------------------------------------------------
function Dir:Start()
    if not CraftLink then return end
    self.roster = (COC.db and COC.db.roster) or {}   -- cache persistant = mini BDD des métiers
    if COC.db then COC.db.roster = self.roster end
    self.mySkills = (COC.db and COC.db.mySkills) or {}
    self:PruneRoster()                               -- entretien au démarrage

    if math.randomseed then math.randomseed((time and time() or 0) + Dir:CountOnline()) end

    CraftLink:RegisterHandler("RK",   function(s, m)    Dir:OnRK(s, m) end)
    CraftLink:RegisterHandler("SK",   function(s, m)    Dir:OnSkill(s, m) end)
    CraftLink:RegisterHandler("HI",   function(s, m, d) Dir:OnHello(s, m, d) end)
    CraftLink:RegisterHandler("PING", function(s, m, d) Dir:OnPing(s, m, d) end)
    CraftLink:RegisterHandler("PONG", function(s)       Dir:OnPong(s) end)
    CraftLink:OnPresence(function(kind, who) Dir:OnPresence(kind, who) end)
    if CraftLink.OnBeacon then CraftLink:OnBeacon(function(who) Dir:OnBeacon(who) end) end

    CraftLink:StartTransport()
    self:_WireEvents()
    self:_WireBringup()
    self:_InstallWhisperErrorFilter()

    -- Capture mes niveaux + relations dès que possible (n'a pas besoin du canal).
    if C_Timer then
        C_Timer.After(2, function() Dir:CaptureSkills(); Dir:ScanRelations() end)
        -- Au login : re-ping ajoutés ET croisés récents (capé) → ils se rallument sans re-survoler.
        C_Timer.After(4, function() Dir:RediscoverKnown(true) end)
        -- Au login : ping whisper des AMIS et GUILDMATES en ligne → présence immédiate sans ciblage.
        C_Timer.After(6, function() Dir:DiscoverFriendsAndGuild() end)
        -- Maintien périodique : seulement les favoris ajoutés (petite liste, pas de spam réseau).
        if C_Timer.NewTicker then C_Timer.NewTicker(45, function() Dir:RediscoverKnown() end) end
        -- NB : pas de balise sur timer (ADDON_ACTION_BLOCKED hors action joueur). La découverte
        -- d'INCONNUS passe par la balise émise au clic Poster / /co refresh (cf Dir:Refresh, DoPostOrder).
    end
end

-- Events de classement (guilde/amis) + gain de compétence (re-capture/ré-annonce). Amorce les rosters.
function Dir:_WireEvents()
    local rel = CreateFrame("Frame")
    rel:RegisterEvent("GUILD_ROSTER_UPDATE")
    rel:RegisterEvent("FRIENDLIST_UPDATE")
    rel:SetScript("OnEvent", function()
        if not C_Timer then Dir:ScanRelations(); return end
        if Dir._relTimer then return end
        Dir._relTimer = true
        -- Debounce 2 s : (re)classer guilde/amis PUIS découvrir les NOUVEAUX connectés. Un ami/guildmate
        -- qui se connecte déclenche FRIENDLIST/GUILD_ROSTER_UPDATE → on le ping en whisper sous 2 s
        -- (présence quasi immédiate, sans ciblage ni dépendre du canal global ni d'un re-survol).
        C_Timer.After(2, function() Dir._relTimer = nil; Dir:ScanRelations(); Dir:DiscoverFriendsAndGuild() end)
    end)
    if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster()
    elseif GuildRoster then GuildRoster() end
    if C_FriendList and C_FriendList.ShowFriends then C_FriendList.ShowFriends() end

    local sk = CreateFrame("Frame")
    sk:RegisterEvent("CHAT_MSG_SKILL")
    sk:SetScript("OnEvent", function()
        Dir:CaptureSkills(); Dir:AnnounceThrottled()
        local PW = COC.ProfWindow
        if PW and PW.frame and PW.frame:IsShown() and PW.Refresh then PW:Refresh() end
        if COC.UI and COC.UI.Refresh then COC.UI:Refresh() end
    end)
end

-- Bring-up FIABLE : au lieu d'un « After(3s) » qui abandonne si le canal n'est pas prêt, on s'abonne
-- à OnNetworkReady → à CHAQUE (re)acquisition du canal, je (re)publie mon profil ET sollicite les
-- présents (HI global) — les events JOIN ne listent pas les déjà-présents. Jitté (anti-burst).
function Dir:_WireBringup()
    CraftLink:OnNetworkReady(function()
        Dir:CaptureSkills()
        local function bringup()
            Dir:Announce(); CraftLink:Send("HI", "global")
            -- NB : PAS de balise texte ici — SendChatMessage hors action joueur = ADDON_ACTION_BLOCKED
            -- (testé). La balise n'est émise que sous hardware event (clic Poster, /co refresh, /co beacon).
            -- D : à chaque (re)acquisition du canal, repousser MES commandes ouvertes/acceptées (resync
            -- léger) → un pair qui vient de (re)joindre les reçoit sans attendre le ticker de 2 h.
            if COC.Orders and COC.Orders.RebroadcastMine then COC.Orders:RebroadcastMine() end
        end
        if C_Timer then C_Timer.After(math.random() * 2, bringup) else bringup() end
    end)
end
