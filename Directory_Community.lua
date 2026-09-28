-- Directory_Community.lua — le réseau SANS canal : la communauté remplace CraftLinkNet (Forever).
--
-- Sur Forever, un canal custom est MORCELÉ en salles par une clé inconnue (prouvé le 2026-09-27 : deux
-- joueurs côte à côte ne s'entendaient pas dans CraftLinkNet, leurs whispers passaient). Le canal est
-- donc coupé pour tout le monde, et trois morceaux prennent le relais :
--   1. la glue réseau : la lib envoie « à tous » en whisper vers les pairs que DÉSIGNE l'annuaire
--      (Dir.online), et prévient quand l'un d'eux ne répond plus — la présence que donnait le canal ;
--   2. la communauté OFFICIELLE : reconnue par son clubId, marquée cercle d'office ;
--   3. le lien « Rejoindre » dans le chat, à la connexion, pour qui n'a aucun cercle.
-- Spec : docs/specs/communaute-sans-canal.md. Satellite de Directory.lua, chargé après Directory_Club.lua.

local COC = CraftingOrderClassic
local Dir = COC.Directory
local L = COC.L
local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)

local function p(m) print("|cFF33DD88Crafting Order|r " .. m) end

-- ------------------------------------------------------------------
-- 1. Glue réseau
-- ------------------------------------------------------------------
-- Les pairs EN LIGNE : ceux qui ont répondu en CraftLink dans la session, moi exclu. C'est l'audience
-- exacte du canal quand il marchait — les joueurs de l'addon qu'on entend.
function Dir:OnlinePeers()
    local out, m = {}, COC.Api.PlayerName()
    for name in pairs(self.online or {}) do
        if name ~= m then out[name] = true end
    end
    return out
end

-- Un pair ne répond plus (départ du canal, whisper refusé, jeu qui le dit déconnecté) : il sort de
-- l'annuaire EN LIGNE, et son statut « recherche de travail » s'éteint avec lui. Rend vrai s'il était en
-- ligne ; l'appelant rafraîchit l'interface (OnPresence le fait déjà, les autres non).
function Dir:MarkOffline(who)
    if not who then return false end
    local was = self.online and self.online[who] == true
    if self.online then self.online[who] = nil end
    if self.lfw and self.lfw[who] then
        self.lfw[who] = nil
        if COC.Nameplate and COC.Nameplate.Refresh then COC.Nameplate:Refresh(who) end
    end
    return was
end

local function refreshUI() if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end end

-- Branché par Dir:Start AVANT StartTransport : la lib doit connaître ses pairs dès son premier envoi.
function Dir:_WireNoChannel()
    if not (CraftLink and CraftLink.SetPeerSource) then return end
    CraftLink:SetPeerSource(function() return Dir:OnlinePeers() end)
    CraftLink:OnPeerOffline(function(who) if Dir:MarkOffline(who) then refreshUI() end end)
end

-- Libellé coloré de l'état du réseau, pour /co status, la barre d'état et /co ping.
function COC:NetworkLabel()
    local mode = CraftLink and CraftLink.NetworkMode and CraftLink:NetworkMode()
    if mode == "whisper" then return "|cFF33DD33" .. L["réseau par whisper"] .. "|r" end
    if mode == "channel" then return "|cFF33DD33" .. L["canal rejoint"] .. "|r" end
    return "|cFFFFCC00" .. L["connexion…"] .. "|r"
end

-- ------------------------------------------------------------------
-- 2. La communauté officielle
-- ------------------------------------------------------------------
-- Par camp : une communauté de personnage n'accueille qu'un camp, d'où deux communautés au même nom.
-- Reconnue par son clubId, jamais par son nom, qu'un propriétaire peut changer (et que les deux camps
-- partagent). `ticket` = code du lien d'invitation ILLIMITÉ créé par le user. clubIds relevés dans
-- chat-cache.txt (« Community:<clubId>:1 ») : Alliance le 2026-09-27 sur les deux comptes du banc,
-- Horde le 2026-09-28 sur Orcaa (seule communauté de ce perso, créée après celle de l'Alliance).
local OFFICIAL = {
    Alliance = { clubId = 22961321, ticket = "XGvzjrikY",  name = "Crafting Order PVE" },
    Horde    = { clubId = 22973181, ticket = "XGvoAXHvxd", name = "Crafting Order PVE" },
}

local function officialForMe()
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    return faction and OFFICIAL[faction] or nil
end

local function isOfficialId(clubId)
    for _, c in pairs(OFFICIAL) do
        if tostring(c.clubId) == tostring(clubId) then return true end
    end
    return false
end

-- La communauté officielle, si elle est marquée cercle : elle prend la souscription de présence
-- (Dir:FocusCircles — un seul club peut l'avoir).
function Dir:OfficialCircleId()
    for _, c in pairs(OFFICIAL) do
        if self:IsCircle(c.clubId) then return c.clubId end
    end
    return nil
end

-- Démarquages VOLONTAIRES (/co circle <n>) : une communauté officielle démarquée à la main n'est plus
-- jamais re-marquée d'office. Clés en chaîne, comme Dir:CircleIds.
function Dir:CirclesOff()
    if not COC.db then return {} end
    COC.db.circlesOff = COC.db.circlesOff or {}
    return COC.db.circlesOff
end

-- Rend false si les clubs sont illisibles (valeur secrète en instance, cf. Dir:EachClub) : « illisible »
-- ne doit JAMAIS se lire « aucun club » — un membre recevrait le lien.
local function eachClub(fn)
    local ok, _, readable = pcall(Dir.EachClub, Dir, fn)
    return ok and readable == true
end

-- true / false, ou nil si les clubs sont illisibles.
function Dir:IsMemberOf(clubId)
    local found = false
    if not eachClub(function(info) if tostring(info.clubId) == tostring(clubId) then found = true end end) then
        return nil
    end
    return found
end

-- Ai-je au moins un cercle ? Un clubId marqué dont je ne suis plus membre ne compte pas. nil = illisible.
function Dir:HasCircle()
    local has = false
    if not eachClub(function(_, isCircle) if isCircle then has = true end end) then return nil end
    return has
end

-- Rejoindre par le lien suffit : pas de /co circle à taper ensuite. Appelé sur les événements club
-- (Directory_Club : INITIAL_CLUBS_LOADED, CLUB_ADDED) et au branchement des clubs.
function Dir:AutoMarkOfficial()
    local off = self:CirclesOff()
    eachClub(function(info, isCircle)
        if not isCircle and isOfficialId(info.clubId) and not off[tostring(info.clubId)] then
            self:SetCircle(info.clubId, true)
            p(string.format(L["communauté officielle marquée comme cercle d'artisans : %s"], tostring(info.name)))
        end
    end)
end

-- ------------------------------------------------------------------
-- 3. Le lien « Rejoindre »
-- ------------------------------------------------------------------
-- Lien natif `|HclubTicket:<code>|h` : un clic ouvre Guilde & Communautés sur l'invitation
-- (ItemRefHandlersShared → CommunitiesHyperlink.OnClickLink → RequestTicket → AddTicket). COC ne peut
-- pas adhérer à la place du joueur (RedeemTicket est sécurisé) : le clic « Rejoindre » reste le sien.
local function joinLink(c)
    if _G.GetClubTicketLink and Enum and Enum.ClubType then
        local ok, link = pcall(_G.GetClubTicketLink, c.ticket, c.name, Enum.ClubType.Character)
        if ok and type(link) == "string" then return link end
    end
    return "|cFFFFD100|HclubTicket:" .. c.ticket .. "|h[" .. c.name .. "]|h|r"
end

-- Une fois par COMPTE (la SavedVariable l'est) : celui qui met l'addon à jour doit comprendre POURQUOI
-- rejoindre, et une ligne de chat au login se noie dans la rafale.
--
-- ⚠️ UN SEUL « OK », JAMAIS DE BOUTON « REJOINDRE ». Mesuré en jeu le 2026-09-28 : un bouton de la popup
-- qui ouvrait l'invitation (SetItemRef clubTicket, la porte d'un clic de lien) a donné
-- `ADDON_ACTION_FORBIDDEN … GetLastTicketResponse()`. Lancé depuis NOTRE code, le récepteur
-- CLUB_TICKET_RECEIVED de Blizzard (CommunitiesHyperlink.lua) est créé « touché par l'addon », et la
-- fonction RESTREINTE qu'il appelle est refusée — pour le reste de la session, lien du chat compris.
-- Un lien dans le texte de la popup n'y échappe pas : son clic passe par un OnHyperlinkClick fourni par
-- l'addon. Seul le chat, dont le gestionnaire de clic est à Blizzard, reste propre.
local function firstTimePopup(c)
    if not (COC.db and not COC.db.communityPopupShown and StaticPopupDialogs and StaticPopup_Show) then return end
    StaticPopupDialogs["COC_COMMUNITY_NOTICE"] = {
        text = string.format(L["Crafting Order n'utilise plus de canal de discussion : sur WoW Forever, il est découpé en salles et les joueurs ne s'y voient pas tous.\n\nLes artisans se retrouvent maintenant dans la communauté |cFFFFD100%s|r. Clique sur le lien dans ton chat pour y entrer."], c.name),
        button1 = OKAY or "OK",
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
    COC.db.communityPopupShown = true
    StaticPopup_Show("COC_COMMUNITY_NOTICE")
end

-- Jamais pour un membre de la communauté officielle (même s'il l'a démarquée). Hors `force` (demande
-- explicite, /co circle) : jamais si le joueur a un cercle, ni s'il a éteint le rappel. Clubs illisibles
-- (nil) : on s'abstient.

-- Chaque décision du rappel de connexion laisse sa raison dans /co trace : le 2026-09-28, un lien
-- attendu n'est jamais venu, et rien ne disait pourquoi.
local function skip(force, why)
    if not force and COC.Trace then COC.Trace:Log("net", "lien de la communauté non proposé : " .. why) end
    return false
end

function Dir:ShowJoinLink(force)
    local c = officialForMe()
    if not c then return skip(force, "aucune communauté officielle pour ce camp") end
    if not self:_ClubsAvailable() then return skip(force, "communautés indisponibles") end
    local member = self:IsMemberOf(c.clubId)
    if member == nil then return skip(force, "clubs illisibles") end
    if member then return skip(force, "déjà membre") end
    if not force then
        if COC.db and COC.db.circleLinkOff then return skip(force, "rappel éteint (/co circle nolink)") end
        local has = self:HasCircle()
        if has ~= false then return skip(force, has and "a déjà un cercle" or "clubs illisibles") end
    end
    p(string.format(L["Rejoins la communauté des artisans : %s — c'est là que Crafting Order trouve les autres joueurs."],
        joinLink(c)))
    if not force then
        p("|cFF888888" .. L["(/co circle nolink : ne plus afficher ce rappel)"] .. "|r")
        if COC.Trace then COC.Trace:Log("net", "lien de la communauté proposé") end
        firstTimePopup(c)
    end
    return true
end

function Dir:SetJoinLinkOff(off)
    if not COC.db then return end
    COC.db.circleLinkOff = off and true or nil
    p(off and L["rappel de la communauté éteint — /co circle link pour le rallumer."]
          or L["rappel de la communauté rallumé."])
end

-- À la connexion INITIALE seulement (pas au /reload), après un délai FIXE. La 1re version attendait
-- INITIAL_CLUBS_LOADED : relevé le 2026-09-28, Gnomi a quitté la communauté, s'est déconnecté puis
-- reconnecté, et aucun lien n'est venu — l'événement ne revient pas quand le client reste ouvert (les
-- communautés sont déjà chargées). Au banc, le roster du club était lisible 4 s après l'entrée en jeu ;
-- 15 s laissent aussi passer la rafale de messages du login, où le lien se noierait. Si les clubs d'un
-- membre traînaient au-delà, il verrait le lien : un clic ouvre alors… sa propre communauté.
local LINK_DELAY = 15

local function onLogin(_, _, isInitialLogin)
    if not isInitialLogin then return end
    if C_Timer and C_Timer.After then C_Timer.After(LINK_DELAY, function() Dir:ShowJoinLink() end)
    else Dir:ShowJoinLink() end
end

if CreateFrame then
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", onLogin)
end
