-- Crafting Order - Classic — Directory : l'annuaire des GENS (présence + qui peut crafter quoi).
-- Côté PRODUIT (pas dans la lib), séparé du registre de recettes (CraftLink). Présence via JOIN/LEAVE
-- du canal caché (Dir.online) ; recettes via RK sur le canal global (Dir.roster, persistant) ; PING/PONG
-- YELL en proximité. Discipline cache : réseau → Dir.roster (COC.db.roster) → UI (jamais le réseau direct).

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
        self:AnnounceThrottled()        -- un nouveau arrive → je (re)publie mes recettes (throttlé : anti-burst login en masse)
    else
        self.online[who] = nil
        if self.lfw and self.lfw[who] then          -- quitte le canal → son statut « recherche de travail » s'éteint
            self.lfw[who] = nil
            if COC.Nameplate and COC.Nameplate.Refresh then COC.Nameplate:Refresh(who) end
        end
    end
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
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

-- Amis BNet, sweep des relations en ligne (DiscoverFriendsAndGuild) et requête de présence 3 états
-- (Dir:PresenceOf, + la table Dir.onlineGame) → Directory_Presence.lua.

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
    self:ForEachBNetWoWFriend(function(n) self._friendSet[shortName(n)] = true end)
    self:ReclassifyAll()
end

-- Source naturelle d'un joueur, ou nil si aucune relation connue. Ordre de priorité : ma guilde >
-- ami (relation explicite du client) > confédéré (relation automatique, plus faible → ne débarque
-- pas un ami de son onglet). Un confédéré n'étant JAMAIS dans ma guilde, le test guilde ne le capte pas.
function Dir:ClassifySource(name)
    name = shortName(name)
    if self._guildSet  and self._guildSet[name]  then return "guild"  end
    if self._friendSet and self._friendSet[name] then return "friend" end
    if self._confedSet and self._confedSet[name] then return "confed" end
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
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
end

-- Confédération GreenWall (display-only) déplacée dans Directory_Confed.lua : _GreenWallActive /
-- _NoteConfederate / _WireGreenWall (méthodes sur COC.Directory). L'appel self:_WireGreenWall() reste
-- dans Dir:Start ci-dessous, et la lecture self._confedSet dans ClassifySource.

-- Entretien de la « mini BDD » des métiers : on GARDE à vie guilde/amis/ajoutés (relations) ;
-- on purge les simples « croisés » (Annuaire) pas revus depuis RECENT_TTL_DAYS + on plafonne leur
-- nombre (anti-explosion serveur actif). Tourne au login (Dir:Start), pas en continu.
local RECENT_TTL_DAYS = 7   -- un croisé non revu depuis 1 semaine sort de l'annuaire
function Dir:PruneRoster(maxAgeDays, maxRecent)
    if not self.roster then return end
    local cutoff = time() - (maxAgeDays or RECENT_TTL_DAYS) * 86400
    local recents = {}
    for name, r in pairs(self.roster) do
        local keep = r.manual or r.source == "guild" or r.source == "friend" or r.source == "added"
        if not keep then
            -- Rétention = dernier signe de vie DIRECT ou RELAYÉ : une entrée créée par pur relais
            -- n'a pas de lastSeen (pas de fausse présence) — sans ce max elle serait purgée aussitôt.
            local seen = math.max(r.lastSeen or 0, r.relayed and r.relayed.ts or 0)
            if seen < cutoff then self.roster[name] = nil
            else recents[#recents + 1] = { name = name, t = seen } end
        end
    end
    maxRecent = maxRecent or 500
    if #recents > maxRecent then
        table.sort(recents, function(a, b) return a.t > b.t end)   -- garde les plus récents
        for i = maxRecent + 1, #recents do self.roster[recents[i].name] = nil end
    end
    -- Prune du throttle de découverte (_lastPing, runtime) : > 5× la fenêtre de 60 s → inutile (borne mémoire).
    local t = now()
    for name, ts in pairs(self._lastPing or {}) do if t - ts > 300 then self._lastPing[name] = nil end end
    if self.PruneCooldowns then self:PruneCooldowns() end   -- readyAt trop vieux (Directory_Cooldowns.lua)
    if self.PruneRelays then self:PruneRelays() end         -- relais périmés (Directory_Relay.lua)
    if self.PruneAlts then self:PruneAlts() end             -- claims de rerolls périmées (Directory_Alts.lua)
    if self.PruneMySkills then self:PruneMySkills() end     -- partitions skill orphelines (Directory_MyArtisans.lua)
end

-- RK reçu (recettes d'un autre) → cache roster persistant.
function Dir:OnRK(sender, message)
    if not (sender and CraftLink) then return end
    local prof, hex, dv = CraftLink:ParseRK(message)
    if not prof then return end
    local r = self.roster[sender]; if not r then r = {}; self.roster[sender] = r end
    if r.skill and next(r.skill) and not r.skill[prof] then return end  -- anti fuite d'alts : SK = vérité terrain
    r.recipes = r.recipes or {}; r.recipes[prof] = hex
    r.recipeDV = dv
    self:_ApplySource(sender, r)          -- guilde/ami si reconnu, sinon « recent »
    r.lastSeen = time()
    self.online[sender] = true          -- présence passive : un message prouve la présence
    self:_NoteLinked(sender, r)
    -- Un RK frais peut changer le filtre « plans de cet artisan » (onglet Commande) ou l'annuaire :
    -- on rafraîchit la vue courante (no-op si la fenêtre est fermée). Idem OnSkill.
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
end

-- Confinement FACTION (Classic Era : aucun échange cross-faction, rerolls compris). La SavedVariable
-- est PAR COMPTE → un compte bi-faction mélange les deux rosters. Le transport (canal/whisper) est déjà
-- segmenté par faction, donc toute donnée REÇUE est de MA faction : on la stampe. Les entrées héritées
-- (faction nil) passent le filtre (pas de régression) et se re-stampent au prochain contact.
function Dir:_MyFaction() return (UnitFactionGroup and UnitFactionGroup("player")) or nil end
function Dir:_SameFaction(r) local f = r and r.faction; return f == nil or f == self:_MyFaction() end

-- Garantit une entrée roster pour un joueur QUI A RÉPONDU (a donc l'addon) : classe la source
-- (guilde/ami/ajouté sinon « recent » = Croisé/Met), marque en ligne, horodate. Idempotent.
function Dir:_Touch(name)
    if not name then return end
    local r = self.roster and self.roster[name]
    if not r then r = {}; self.roster = self.roster or {}; self.roster[name] = r end
    self:_ApplySource(name, r)
    r.faction = self:_MyFaction()   -- donnée reçue = ma faction (transport segmenté) → stampe
    r.lastSeen = time()
    r.relayed = nil   -- il répond LUI-MÊME : ses données directes invalident tout relais de partenaire
    local wasOnline = self.online[name]
    self.online[name] = true
    self:_NoteLinked(name, r)
    -- Transition hors-ligne → en ligne : pousse-lui mes commandes ouvertes qui le concernent (whisper).
    if not wasOnline and COC.Orders and COC.Orders.OnArtisanOnline then COC.Orders:OnArtisanOnline(name) end
    return r
end

-- HI reçu → j'ingère les métiers EMBARQUÉS (SK collé : "HI|SK|…", cf. _HelloPayload) puis, si DIRIGÉ,
-- je réponds mon profil (throttlé par cible) ET le pingue en retour pour SES recettes (DiscoverPlayer).
-- Sinon l'échange serait à SENS UNIQUE (symptôme : « Croisé » en ligne sans métiers). GLOBAL → Announce jittée.
function Dir:OnHello(sender, message, distribution)
    if not CraftLink then return end
    self:_Touch(sender)
    local body = message and message:match("^HI|(.+)$")               -- métiers embarqués dans le hello ?
    if body and body:find("^SK") then self:OnSkill(sender, body) end
    if distribution == "WHISPER" then
        self:_AnnounceToThrottled(sender)
        self:DiscoverPlayer(sender)
        if self.RelayPartnersTo then self:RelayPartnersTo(sender) end   -- fiches de mes partenaires hors ligne
    elseif C_Timer then
        C_Timer.After(math.random() * 3, function() Dir:Announce() end)
    end
end

-- PING reçu → PONG sur la MÊME portée (whisper si dirigé, sinon yell). Dirigé → profil (throttlé par
-- cible : un PING+HI groupé ne déclenche qu'UNE annonce, cf. _AnnounceToThrottled) + ping retour.
function Dir:OnPing(sender, _, distribution)
    if not CraftLink then return end
    self:_Touch(sender)
    if distribution == "WHISPER" and sender then
        CraftLink:Send("PONG", "whisper", sender)
        self:_AnnounceToThrottled(sender)
        self:DiscoverPlayer(sender)
        if self.RelayPartnersTo then self:RelayPartnersTo(sender) end   -- fiches de mes partenaires hors ligne
    else
        CraftLink:Send("PONG", "yell")
    end
end

-- PONG reçu (l'autre A l'addon) → on le connaît : entrée roster (Croisé) + en ligne.
function Dir:OnPong(sender)
    self:_Touch(sender)
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
end

-- ------------------------------------------------------------------
-- Émission
-- ------------------------------------------------------------------
-- SK PUIS RK (ordre voulu : le receveur établit la vérité terrain des métiers avant les recettes → garde anti-fuite OnRK).
function Dir:Announce()
    if not (CraftLink and CraftLink:IsNetworkReady()) then return end
    self:AnnounceSkills()
    for _, prof in ipairs(CraftLink:MyProfessions()) do
        local msg = CraftLink:BuildRK(prof)
        if msg then CraftLink:Send(msg, "global") end
    end
    if self.AnnounceCooldowns then self:AnnounceCooldowns("global") end
    if self.AnnounceAlts then self:AnnounceAlts("global") end   -- opt-in : no-op sans /co alts on
end

-- Publie MON profil DIRECTEMENT à un joueur (whisper) — fiable hors canal/guilde. Sert aux réponses
-- de découverte dirigée (HI/PING whisper) : l'autre reçoit mes métiers + niveaux immédiatement.
function Dir:AnnounceTo(target)
    if not (CraftLink and target) then return end
    local sk = self:_SkillPayload()
    if sk then CraftLink:Send(sk, "whisper", target) end     -- SK d'abord (vérité terrain avant les RK)
    for _, prof in ipairs(CraftLink:MyProfessions()) do
        local msg = CraftLink:BuildRK(prof)
        if msg then CraftLink:Send(msg, "whisper", target) end
    end
    if self.AnnounceCooldowns then self:AnnounceCooldowns("whisper", target) end
    if self.AnnounceAlts then self:AnnounceAlts("whisper", target) end   -- opt-in : no-op sinon
end

-- Découverte DIRIGÉE d'un joueur (croisement / ajout manuel) : on lui chuchote UN hello porteur de mes
-- métiers (HI|SK, cf. _HelloPayload). S'il a l'addon, il répond (son profil) → il atterrit dans Croisés/Met
-- avec ses métiers. S'il ne l'a pas, rien (whisper addon invisible). Throttlé par nom (anti-spam).
function Dir:DiscoverPlayer(name)
    name = shortName(name)
    if not (CraftLink and name and name ~= "") then return end
    if name == shortName(UnitName and UnitName("player") or "") then return end
    self._lastPing = self._lastPing or {}
    local t = now()
    if (self._lastPing[name] or 0) + 60 > t then return end   -- 1 hello / 60 s / joueur
    self._lastPing[name] = t
    CraftLink:Send(self:_HelloPayload(), "whisper", name)   -- HI + SK : 1 message (au lieu de PING+HI)
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
    if self.StartCooldowns then self:StartCooldowns() end   -- verbe CD (Directory_Cooldowns.lua)
    if self.StartRelay then self:StartRelay() end           -- verbe RLY (Directory_Relay.lua)
    if self.StartAlts then self:StartAlts() end             -- verbe ALT (Directory_Alts.lua)
    if self.StartLFW then self:StartLFW() end               -- verbe LFW (Directory_LFW.lua)
    CraftLink:OnPresence(function(kind, who) Dir:OnPresence(kind, who) end)
    if CraftLink.OnBeacon then CraftLink:OnBeacon(function(who) Dir:OnBeacon(who) end) end

    CraftLink:StartTransport()
    self:_WireEvents()
    self:_WireBringup()
    self:_InstallWhisperErrorFilter()
    self:_WireGreenWall()   -- greffe passive confédération (no-op sans GreenWall) — display-only

    -- Capture mes niveaux + relations dès que possible (n'a pas besoin du canal).
    if C_Timer then
        C_Timer.After(2, function() Dir:CaptureSkills(); Dir:ScanRelations() end)
        -- Au login : re-ping ajoutés ET croisés récents (capé) → ils se rallument sans re-survoler.
        C_Timer.After(4, function() Dir:RediscoverKnown(true) end)
        -- Au login : ping whisper des AMIS et GUILDMATES en ligne → présence immédiate sans ciblage.
        C_Timer.After(6, function() Dir:DiscoverFriendsAndGuild() end)
        -- Maintien périodique : seulement les favoris ajoutés (petite liste, pas de spam réseau).
        -- On redemande AUSSI le roster de guilde : sur Era il n'est interrogé qu'au login, et sans ça
        -- Dir.onlineGame (pastille « en ligne sans addon ») garderait un guildmate déjà déconnecté.
        -- Le GUILD_ROSTER_UPDATE qui suit relance ScanRelations + le sweep (débouncé 2 s) → pas de coût UI.
        if C_Timer.NewTicker then
            C_Timer.NewTicker(45, function()
                Dir:RediscoverKnown()
                if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster()
                elseif GuildRoster then GuildRoster() end
            end)
        end
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
        if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
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
