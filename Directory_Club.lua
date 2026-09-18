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
local function me() return shortName(UnitName and UnitName("player") or "") end

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

-- Les clubs auxquels j'appartiens, chacun accompagné de son état « cercle ».
function Dir:EachClub(fn)
    if not self:_ClubsAvailable() then return 0 end
    local n = 0
    for _, info in ipairs(club("GetSubscribedClubs") or {}) do
        n = n + 1
        fn(info, self:IsCircle(info.clubId))
    end
    return n
end

-- ------------------------------------------------------------------
-- Lecture du roster
-- ------------------------------------------------------------------
-- Le nom ne vient JAMAIS de ClubMemberInfo.name : celui-là porte le nom d'AFFICHAGE BattleNet
-- (« Rédemption Wafhien ») alors que le personnage s'appelle « Rédemption ». Bâtir l'annuaire
-- dessus aurait rempli le roster de noms qui n'existent pas en jeu, et aucun whisper n'aurait
-- jamais abouti. GetPlayerInfoByGUID rend le vrai nom + le royaume en chaîne ordinaire.
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
local function noteMember(name)
    Dir.roster = Dir.roster or {}
    local r = Dir.roster[name]
    if not r then r = {}; Dir.roster[name] = r end
    if not r.manual then r.source = "circle" end
    return r
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
            noteMember(name)
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
        if r.source == "circle" and not set[name] and not r.manual then r.source = nil end
    end
    self._circleSet, self._circleOnline = set, online
    self:ReclassifyAll()   -- reclasse tout le roster + rafraîchit l'UI
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
        if event == "INITIAL_CLUBS_LOADED" or event == "CLUB_ADDED" then Dir:FocusCircles() end
        Dir:RefreshCirclesSoon()
    end)
    self:FocusCircles()
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
        return
    end
    local want = tonumber(rest)
    local i, done = 0, false
    self:EachClub(function(info, isCircle)
        i = i + 1
        if i == want then
            self:SetCircle(info.clubId, not isCircle)
            p(string.format(isCircle and L["cercle retiré : %s"] or L["cercle ajouté : %s"], tostring(info.name)))
            done = true
        end
    end)
    if not done then p(string.format(L["aucune communauté n° %s."], rest)) end
end
