-- Directory_Club.lua — source « cercle » (communautés WoW) de l'annuaire, DISPLAY-ONLY.
--
-- Un « cercle d'artisans » est une COMMUNAUTÉ que le joueur a marquée comme telle (`/co circle`).
-- Contrairement au canal global, elle est RESTREINTE : chacun crée la sienne, y invite qui il veut,
-- ou rejoint celle d'un autre. COC ne peut ni créer ni rejoindre à sa place (`CreateClub` et
-- `RedeemTicket` vivent dans un addon en environnement sécurisé) — il se contente d'exploiter les
-- cercles auxquels le joueur appartient déjà.
--
-- Ce que le cercle apporte, et que le canal n'aura jamais : une LISTE de membres persistante et leur
-- PRÉSENCE, sans un seul message réseau. Ce qu'il n'apporte PAS (mesuré le 2026-09-18, cf.
-- docs/COMMUNITIES-TRANSPORT.md) :
--   * aucun transport — le contenu d'un message de club est opaque (`|Kw1|k`) et un AddonMessage
--     envoyé sur son canal est accepté puis avalé. Les métiers continuent donc de passer par le
--     protocole SK/RK en whisper, comme avant ;
--   * aucun métier dans le roster — `profession1ID` & co sont vides sur une communauté de
--     personnage (ils viennent du roster de GUILDE). Vérité terrain : 5 métiers appris, 0 annoncés.
--
-- Même forme que Directory_Confed.lua : des méthodes greffées sur COC.Directory, zéro transport.

local COC = CraftingOrderClassic
local Dir = COC.Directory

-- shortName : dupliqué de Directory.lua (fonction file-locale ; on ne partage pas les locales).
local function shortName(n) return n and (n:match("^([^%-]+)") or n) or n end
local function me() return shortName(COC.Api.PlayerName()) end   -- nom RÉSEAU, repli si pas de GUID

local REFRESH_DEBOUNCE = 2   -- s : les événements club arrivent en rafale (un par membre)

-- Appelle C_Club.<name>(...) sans jamais lever : ce fichier doit rester inerte sur une saveur sans
-- communautés plutôt que de faire tomber le chargement de COC.
local function club(name, ...)
    local fn = C_Club and C_Club[name]
    if type(fn) ~= "function" then return nil end
    local res = { pcall(fn, ...) }
    if not res[1] then return nil end
    return res[2]
end

-- ------------------------------------------------------------------
-- Disponibilité — une seule garde, tout le reste s'y adosse
-- ------------------------------------------------------------------
-- Le verrou est SERVEUR : le code d'interface de Blizzard est identique entre Era et Forever (vérifié
-- sur les deux copies de source), donc seul `ShouldAllowClubType` peut répondre, et seulement à
-- l'exécution. Rendre `false` ici suffit à éteindre la feature entière — pas de fork, pas de .toc
-- divergent, un seul paquet pour les 4 saveurs.
-- ⚠️ Ce que rend réellement ce prédicat sur Era n'a PAS encore été mesuré en jeu (cf. la section
-- « Non mesuré » de docs/COMMUNITIES-TRANSPORT.md). L'inertie, elle, est garantie autrement : double
-- garde d'existence ci-dessous, et tous les appels club() passent par pcall.
function Dir:_ClubsAvailable()
    if not (C_Club and C_Club.GetSubscribedClubs and Enum and Enum.ClubType) then return false end
    return club("ShouldAllowClubType", Enum.ClubType.Character) == true
end

-- ------------------------------------------------------------------
-- Quels clubs sont des cercles — choix EXPLICITE du joueur
-- ------------------------------------------------------------------
-- Pas de détection par convention de nom : ça dépendrait du bon vouloir du propriétaire du club et
-- ça se casserait au premier renommage. Clés en CHAÎNE : un clubId est un grand entier, et les clés
-- numériques d'une SavedVariable ne reviennent pas toujours du même type.
function Dir:CircleIds()
    if not COC.db then return {} end
    COC.db.circles = COC.db.circles or {}
    return COC.db.circles
end

function Dir:IsCircle(clubId) return self:CircleIds()[tostring(clubId)] == true end

function Dir:SetCircle(clubId, on)
    local ids = self:CircleIds()
    ids[tostring(clubId)] = on and true or nil
    self:FocusCircles()   -- AUSSI au retrait : la souscription de présence doit être ré-attribuée
    self:RefreshCircles()
end

-- Les clubs auxquels j'appartiens, chacun accompagné de son état « cercle ». Rend (n, lisible) :
-- en verrouillage de messagerie (instance), GetSubscribedClubs rend une valeur SECRÈTE
-- (ClubDocumentation : SecretInChatMessagingLockdown) qu'on ne peut ni parcourir ni comparer.
-- « Illisible » (false) ne doit jamais se lire « aucun club ». Le parcours est sous pcall : un club
-- secret ailleurs que dans la liste lèverait en plein /co circle, erreur rouge pour le joueur.
function Dir:EachClub(fn)
    if not self:_ClubsAvailable() then return 0, true end
    local list = club("GetSubscribedClubs")
    if COC.Api.IsSecret and COC.Api.IsSecret(list) then return 0, false end
    local n = 0
    local ok = pcall(function()
        for _, info in ipairs(list or {}) do
            n = n + 1
            fn(info, self:IsCircle(info.clubId))
        end
    end)
    return n, ok
end

-- ------------------------------------------------------------------
-- Lecture du roster
-- ------------------------------------------------------------------
-- Le nom vient de GetPlayerInfoByGUID, qui rend le nom + le royaume en chaînes ordinaires. Sur Forever
-- c'est le nom COMPLET (« Rédemption Wafhien » : prénom + NOM DE FAMILLE, pas un nom Battle.net comme on
-- l'a cru d'abord) — celui que le serveur attend pour un whisper (cf. COC.Api.PlayerName).
local function memberName(guid)
    if not (guid and _G.GetPlayerInfoByGUID) then return nil end
    local res = { pcall(_G.GetPlayerInfoByGUID, guid) }
    if not res[1] then return nil end
    local name, realm = res[7], res[8]
    if type(name) ~= "string" or name == "" then return nil end
    -- Royaume vide = le mien. Un membre d'un AUTRE royaume reste affichable, mais il n'est pas
    -- joignable en whisper ordinaire : on ne le pousse pas à la découverte.
    return shortName(name), (type(realm) == "string" and realm ~= "") and realm or nil
end

-- Présence selon le CLUB (vérité du jeu, pas du réseau COC). Absent/mobile ne comptent pas : un
-- joueur sur l'appli mobile ne fait pas tourner d'addon et ne recevra jamais de commande.
local function isOnline(presence)
    local P = Enum and Enum.ClubMemberPresence
    if not P then return false end
    return presence == P.Online or presence == P.Away or presence == P.Busy
end

-- Le roster n'est PAS disponible du seul fait qu'on est membre : le client ne le streame qu'après
-- un FocusMembers, et tant que AreMembersReady est faux, GetMemberInfo rend une table dont TOUS les
-- champs sont nil — pas nil, une table VIDE, qu'un `if info then` laisse passer sans broncher. On
-- demande donc le stream ici, et on relit sur événement (cf. _WireClubs).
function Dir:FocusCircles()
    if not self:_ClubsAvailable() then return end
    -- Un SEUL club peut porter la souscription de présence (« You can only be subscribed to 0 or 1
    -- clubs for presence », dixit l'API). Deux exigences en découlent :
    --   * le choix doit être DÉTERMINISTE. `pairs` sur des clés chaîne rend un ordre qui change
    --     d'une session à l'autre : le cercle suivi en temps réel n'aurait pas été le même deux
    --     fois de suite, sans que rien ne l'explique côté joueur. On prend le plus petit clubId ;
    --   * il doit être RÉ-ATTRIBUÉ à chaque appel, retrait compris. Sinon, démarquer le cercle qui
    --     portait la souscription la laissait orpheline jusqu'au prochain login.
    local chosen
    for clubId in pairs(self:CircleIds()) do
        local raw = tonumber(clubId) or clubId
        club("FocusMembers", raw)
        if type(raw) == "number" and (chosen == nil or raw < chosen) then chosen = raw end
    end
    -- La communauté officielle passe devant : sans canal, c'est la voie de découverte principale, et sans
    -- souscription sa présence ne bouge plus (revue protocole 2026-09-28). Choix toujours déterministe.
    local official = self.OfficialCircleId and self:OfficialCircleId()
    if official then chosen = official end
    if chosen then club("SetClubPresenceSubscription", chosen)
    else club("ClearClubPresenceSubscription") end
    self._presenceClub = chosen
end

-- Parcourt les membres d'un cercle prêt. Rend le nombre de membres vus (0 = pas encore streamé).
-- Est-ce MOI ? On tranche sur le GUID, jamais sur le nom. Un GUID est exact et unique ; comparer des
-- noms dépend de l'accentuation, de la casse et du suffixe de royaume que chaque API rend à sa façon
-- — et ça s'est vu en jeu le 2026-09-18, le joueur apparaissait dans son propre cercle. `isSelf` est
-- lu en premier : c'est le client qui l'affirme, autant le croire. Le nom reste en dernier recours,
-- pour le cas d'un membre sans GUID exploitable.
local function isMe(info, name)
    if info and info.isSelf ~= nil then return info.isSelf == true end
    local myGuid = UnitGUID and UnitGUID("player")
    if myGuid and info and info.guid then return info.guid == myGuid end
    return name ~= nil and name == me()
end

function Dir:_EachCircleMember(raw, fn)
    if club("AreMembersReady", raw) ~= true then return 0 end
    local ids, seen = club("GetClubMembers", raw) or {}, 0
    for _, memberId in ipairs(ids) do
        local info = club("GetMemberInfo", raw, memberId)
        -- La garde sort du `if`, PAS dans l'assignation : `info and memberName(...)` ne rendrait
        -- qu'UNE valeur (Lua tronque le multi-retour derrière un `and`) et `realm` serait toujours
        -- nil — donc tout membre cross-royaume passerait pour joignable.
        if info then
            local name, realm = memberName(info.guid)
            if name and not isMe(info, name) then
                seen = seen + 1
                fn(name, realm, info)
            end
        end
    end
    return seen
end

-- ------------------------------------------------------------------
-- Rafraîchissement de la source
-- ------------------------------------------------------------------
Dir._circleSet    = Dir._circleSet    or {}   -- [nom court] = clubId (mémoire)
Dir._circleOnline = Dir._circleOnline or {}   -- [nom court] = true — en ligne SELON LE CLUB

-- Entrée d'annuaire pour un membre de cercle. Volontairement PAS Dir:_Touch : celui-là est réservé
-- à un joueur qui a RÉPONDU (donc qui a l'addon) et il le marque en ligne. Un membre de cercle peut
-- très bien ne pas avoir COC — le marquer en ligne le rendrait faussement ciblable.
-- `r.circle` = le cercle d'où il vient (clubId en chaîne) : une ligne par cercle dans l'onglet Artisans.
-- Membre de deux cercles : le dernier parcouru l'emporte (une fiche, un seul classement).
local function noteMember(name, clubId, info)
    Dir.roster = Dir.roster or {}
    local r = Dir.roster[name]
    if not r then r = {}; Dir.roster[name] = r end
    if not r.manual then r.source = "circle" end
    r.circle = tostring(clubId)
    -- Sa note de membre, posée à la main : lisible même hors ligne (constat C14, cf. Directory_Note).
    -- Relue à chaque passage : une note effacée disparaît aussi de la fiche.
    if Dir._CleanNote then r.memberNote = Dir:_CleanNote(info and info.memberNote) end
    -- Une communauté de personnage n'a qu'un camp, le mien : sans tampon, la fiche passerait le filtre
    -- de camp des persos d'en face du même compte (SV partagée).
    if not r.faction and Dir._MyFaction then r.faction = Dir:_MyFaction() end
    return r
end

-- Les cercles marqués dont je suis membre, dans l'ordre du client : { { id = "<clubId>", name }, … }.
-- Une ligne par cercle dans l'onglet Artisans (demandé par le user le 2026-09-28).
function Dir:CircleList()
    local out = {}
    self:EachClub(function(info, isCircle)
        if isCircle then out[#out + 1] = { id = tostring(info.clubId), name = tostring(info.name) } end
    end)
    return out
end

function Dir:RefreshCircles()
    if not self:_ClubsAvailable() then return end
    local set, online = {}, {}
    for clubId in pairs(self:CircleIds()) do
        local raw = tonumber(clubId) or clubId
        self:_EachCircleMember(raw, function(name, realm, info)
            -- MÊME ROYAUME uniquement. L'annuaire de COC est indexé par nom COURT : y faire entrer
            -- un « Bob » d'un autre royaume le fusionnerait silencieusement avec le Bob d'ici —
            -- mêmes recettes, mêmes niveaux, une seule fiche pour deux personnes. La limite existe
            -- déjà pour les amis BNet, mais un cercle dépasse structurellement le royaume, donc il
            -- la rendrait courante au lieu de théorique. Et on ne perd rien d'exploitable : un
            -- cross-royaume n'est de toute façon pas joignable en whisper, donc pas commandable.
            if realm then return end
            set[name] = raw
            noteMember(name, raw, info)
            if isOnline(info.presence) then online[name] = true end
        end)
    end
    -- Quitter un cercle doit RETIRER le classement : sans ça, `_ApplySource` retombe sur
    -- `r.source or "recent"` et l'ancien « circle » survivrait indéfiniment.
    --
    -- Le balayage porte sur TOUT le roster, pas sur l'ancien `_circleSet` : celui-là vit en mémoire
    -- et repart vide à chaque /reload, alors que `source = "circle"` est PERSISTÉ dans la
    -- SavedVariable. Un membre sorti du cercle — ou classé à tort avant un correctif — gardait donc
    -- son étiquette pour toujours, et aucune session suivante ne pouvait la lui retirer.
    for name, r in pairs(self.roster or {}) do
        if not set[name] then
            if r.source == "circle" and not r.manual then r.source = nil end
            r.circle, r.memberNote = nil, nil
        end
    end
    self._circleSet, self._circleOnline = set, online
    self:ReclassifyAll()   -- reclasse tout le roster + rafraîchit l'UI
    -- Sans canal, la présence du CLUB est le seul signal qu'un membre vient d'arriver ou de partir. Le
    -- balayage ne sonde que les transitions (et éteint les partis) : l'appeler ici ne coûte rien, et sans
    -- lui un membre connecté après nous n'était découvert qu'au prochain événement amis/guilde.
    if self.DiscoverFriendsAndGuild then self:DiscoverFriendsAndGuild() end
end

-- Débounce : les événements club arrivent par rafales (un par membre au chargement du roster).
function Dir:RefreshCirclesSoon()
    if self._circleTimer or not C_Timer then return self:RefreshCircles() end
    self._circleTimer = true
    C_Timer.After(REFRESH_DEBOUNCE, function() Dir._circleTimer = nil; Dir:RefreshCircles() end)
end

-- Consommé par Dir:DiscoverFriendsAndGuild (Directory_Presence.lua), au même titre que les amis, la
-- guilde et les amis BNet : le sweep publie `onlineGame` et ne sonde QUE les nouveaux connectés.
-- On hérite ainsi de tous ses garde-fous au lieu d'écrire une deuxième machinerie de découverte.
--
-- PLAFOND par balayage. Au tout premier sweep d'une session, `prev` est vide : TOUS les connectés
-- partent en découverte d'un coup. Une guilde est bornée par nature, un cercle non — la capacité
-- mesurée d'une communauté est de 1000. À 0,15 s par message dans la file partagée de CraftLink,
-- un gros cercle repousserait de plusieurs dizaines de secondes les SK/RK et les commandes qui
-- attendent derrière. Ce n'est pas un flood serveur, c'est une famine pour le reste du trafic.
-- Le plafond ne porte QUE sur la découverte, jamais sur la présence : tous les membres sont rendus
-- (leur pastille doit être juste), mais seuls les premiers sont marqués « sondable ». Plafonner
-- l'affichage aurait échangé une vérité contre une économie de trafic, ce qui n'est pas un échange.
-- L'ordre de `pairs` varie d'un balayage à l'autre : au fil des sweeps, tout le monde finit sondé.
local DISCOVER_PER_SWEEP = 20

function Dir:ForEachCircleMemberOnline(fn)
    local n = 0
    for name in pairs(self._circleOnline or {}) do
        n = n + 1
        fn(name, n <= DISCOVER_PER_SWEEP)
    end
end

-- ------------------------------------------------------------------
-- Greffe
-- ------------------------------------------------------------------
local CLUB_EVENTS = {
    "CLUB_MEMBERS_UPDATED", "CLUB_MEMBER_UPDATED", "CLUB_MEMBER_ADDED", "CLUB_MEMBER_REMOVED",
    "CLUB_MEMBER_PRESENCE_UPDATED", "CLUB_ADDED", "CLUB_REMOVED", "INITIAL_CLUBS_LOADED",
}

function Dir:_WireClubs()
    if self._clubsHooked or not self:_ClubsAvailable() then return end
    self._clubsHooked = true
    local f = CreateFrame("Frame")
    for _, ev in ipairs(CLUB_EVENTS) do pcall(f.RegisterEvent, f, ev) end
    f:SetScript("OnEvent", function(_, event)
        if event == "INITIAL_CLUBS_LOADED" or event == "CLUB_ADDED" then
            Dir:FocusCircles()
            if Dir.AutoMarkOfficial then Dir:AutoMarkOfficial() end   -- rejoint par le lien → cercle d'office
        end
        Dir:RefreshCirclesSoon()
    end)
    self:FocusCircles()
    if self.AutoMarkOfficial then self:AutoMarkOfficial() end   -- /reload : les clubs sont déjà là
    self:RefreshCirclesSoon()
end

-- ------------------------------------------------------------------
-- /co circle — liste les communautés, bascule le marquage, diagnostique
-- ------------------------------------------------------------------
local function p(m) print("|cFF33DD88Crafting Order|r " .. m) end

-- Liste numérotée : le joueur bascule ensuite par « /co circle <n> ». On numérote dans l'ordre rendu
-- par le client, stable au sein d'une session.
function Dir:_ListCircles()
    local L, i = COC.L, 0
    local n = self:EachClub(function(info, isCircle)
        i = i + 1
        local mark = isCircle and "|cFF55FF55[*]|r" or "|cFF888888[ ]|r"
        local count = 0
        if isCircle then
            for name in pairs(self._circleSet or {}) do
                if self._circleSet[name] == info.clubId then count = count + 1 end
            end
        end
        p(("  %s %d. |cFFFFFFFF%s|r%s"):format(mark, i, tostring(info.name),
            isCircle and (" |cFF888888" .. string.format(L["%d membre(s) dans l'annuaire"], count) .. "|r") or ""))
    end)
    if n == 0 then p(COC.L["aucune communauté — crée ou rejoins un cercle dans Guilde & Communautés."]) end
    return n
end

function Dir:CircleCmd(rest)
    local L = COC.L
    if not self:_ClubsAvailable() then
        p(L["les communautés ne sont pas disponibles sur ce client."]); return
    end
    rest = (rest or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if rest == "" then
        self:_ListCircles()
        p("|cFF888888" .. L["« /co circle <n°> » marque ou démarque un cercle d'artisans."] .. "|r")
        if self.ShowJoinLink then self:ShowJoinLink(true) end   -- pas membre de l'officielle → son lien
        return
    end
    if rest == "nolink" or rest == "link" then
        if self.SetJoinLinkOff then self:SetJoinLinkOff(rest == "nolink") end
        return
    end
    local want = tonumber(rest)
    local i, done = 0, false
    self:EachClub(function(info, isCircle)
        i = i + 1
        if i == want then
            -- Démarquage VOLONTAIRE noté : le marquage d'office ne le défera pas (Directory_Community).
            if self.CirclesOff then self:CirclesOff()[tostring(info.clubId)] = isCircle or nil end
            self:SetCircle(info.clubId, not isCircle)
            p(string.format(isCircle and L["cercle retiré : %s"] or L["cercle ajouté : %s"], tostring(info.name)))
            done = true
        end
    end)
    if not done then p(string.format(L["aucune communauté n° %s."], rest)) end
end
