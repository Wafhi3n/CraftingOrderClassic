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
-- Le verrou est SERVEUR (`ShouldAllowClubType`), pas client : le code d'interface est identique
-- entre Era et Forever. On interroge donc, on ne suppose pas. Rendre `false` ici suffit à éteindre
-- la feature entière — pas de fork, pas de .toc divergent, un seul paquet pour les 4 saveurs.
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
    if on then self:FocusCircles() end
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
    local first = true
    for clubId in pairs(self:CircleIds()) do
        local raw = tonumber(clubId) or clubId
        club("FocusMembers", raw)
        -- « You can only be subscribed to 0 or 1 clubs for presence » : un seul, le premier venu.
        if first then club("SetClubPresenceSubscription", raw); first = false end
    end
end

-- Parcourt les membres d'un cercle prêt. Rend le nombre de membres vus (0 = pas encore streamé).
function Dir:_EachCircleMember(raw, fn)
    if club("AreMembersReady", raw) ~= true then return 0 end
    local ids, seen = club("GetClubMembers", raw) or {}, 0
    local mine = me()
    for _, memberId in ipairs(ids) do
        local info = club("GetMemberInfo", raw, memberId)
        -- La garde sort du `if`, PAS dans l'assignation : `info and memberName(...)` ne rendrait
        -- qu'UNE valeur (Lua tronque le multi-retour derrière un `and`) et `realm` serait toujours
        -- nil — donc tout membre cross-royaume passerait pour joignable.
        if info then
            local name, realm = memberName(info.guid)
            if name and name ~= mine then
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
            set[name] = raw
            noteMember(name)
            if not realm and isOnline(info.presence) then online[name] = true end
        end)
    end
    -- Quitter un cercle doit RETIRER le classement : sans ça, `_ApplySource` retombe sur
    -- `r.source or "recent"` et l'ancien « circle » survivrait indéfiniment.
    for name in pairs(self._circleSet) do
        local r = not set[name] and self.roster and self.roster[name]
        if r and r.source == "circle" and not r.manual then r.source = nil end
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
function Dir:ForEachCircleMemberOnline(fn)
    for name in pairs(self._circleOnline or {}) do fn(name) end
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
