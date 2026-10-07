-- Directory_Room.lua — la salle de découverte : CraftLinkNet rejoint pour SE PRÉSENTER, pas pour transporter.
--
-- Pourquoi (2026-09-29) : sans canal général, COC chuchote aux joueurs qu'il connaît (communauté, amis,
-- guilde) ; un porteur de l'addon qui n'est dans aucun de ces cercles n'est jamais atteint. Le banc des
-- constats a fermé toutes les voies globales (messages d'addon par la communauté, canaux du jeu, crier)
-- et prouvé qu'un message d'addon passe DANS une salle de canal custom. Sur Forever, CraftLinkNet est
-- découpé en salles (2026-09-27) : on n'y fait plus passer de données, mais on peut y dire bonjour.
--
-- Mécanique (CraftLink, FANOUT_REV 3) : le canal est rejoint (garde anti-/1, caché des fenêtres) ; à
-- chaque arrivée, un HI avec mes métiers part sur la salle (portée « room ») ; les présents me répondent
-- en whisper (Dir:OnHello, branche canal : à moi seul), et je les connais. « À tous » reste en whisper.
-- Les porteurs d'avant la v1.37, restés sur CraftLinkNet, deviennent joignables du même coup.
-- Coupable : /co channel room off (COC.db.roomOff).

local COC = CraftingOrderClassic
local Dir = COC.Directory
local L = COC.L

local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)

local function p(msg) print("|cFF33DD88Crafting Order|r " .. msg) end
local function label() return (CraftLink and CraftLink.GlobalChannelLabel and CraftLink:GlobalChannelLabel()) or "CraftLinkNet" end

function Dir:RoomEnabled() return not (COC.db and COC.db.roomOff) end

-- Arrivée dans la salle : bonjour, métiers compris, à tous les présents. Une explication, une seule
-- fois par compte : le joueur voit le canal dans sa liste, il doit savoir pourquoi.
function Dir:OnRoomJoined()
    if not CraftLink then return end
    CraftLink:Send((self._HelloPayload and self:_HelloPayload()) or "HI", "room")
    self._roomHelloAt = (GetTime and GetTime()) or 0
    if COC.db and not COC.db.roomNoticeShown then
        COC.db.roomNoticeShown = true
        p(string.format(L["l'addon rejoint le canal |cFFFFFFFF%s|r pour se présenter aux autres joueurs de Crafting Order ; tes commandes, elles, restent en whisper. |cFFFFFFFF/co channel room off|r pour ne plus le rejoindre."], label()))
    end
end

-- Un nouveau bonjour sur la salle, sur un geste du joueur (« Poster », /co refresh). Il remplace la
-- balise TEXTE `CLNK1` que ces gestes y écrivaient jusqu'à CraftLink REV 16 : une ligne de texte arrivait
-- SECRÈTE chez un porteur en donjon, un message d'addon non. Sans lui, un bonjour d'arrivée perdu (débit
-- du canal) laissait le joueur invisible des inconnus de la salle jusqu'à sa prochaine arrivée. Même
-- plancher que l'ancienne balise ; le bonjour d'arrivée compte. Rend vrai s'il est parti.
local ROOM_HELLO_MIN = 30   -- s

function Dir:RoomHello()
    if not (CraftLink and CraftLink.RoomJoined and CraftLink:RoomJoined()) then return false end
    local t = (GetTime and GetTime()) or 0
    if self._roomHelloAt and t - self._roomHelloAt < ROOM_HELLO_MIN then return false end
    self._roomHelloAt = t
    CraftLink:Send((self._HelloPayload and self:_HelloPayload()) or "HI", "room")
    return true
end

-- Ouvre ou coupe la salle, sans rien dire : la porte commune à la commande et à la case « surveiller »
-- (COC.Channels, clé `room`).
function Dir:SetRoom(on)
    if not COC.db then return end
    COC.db.roomOff = (not on) and true or nil
    if CraftLink and CraftLink.SetDiscovery then CraftLink:SetDiscovery(on and true or false) end
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end   -- la case de l'onglet Artisans suit
end

-- /co channel room [on|off]
function Dir:RoomCmd(arg)
    arg = (arg or ""):lower()
    if arg == "off" then
        self:SetRoom(false)
        p(string.format(L["salle de découverte coupée : l'addon quitte |cFFFFFFFF%s|r et ne le rejoindra plus."], label()))
    elseif arg == "on" then
        self:SetRoom(true)
        p(string.format(L["salle de découverte rouverte : l'addon rejoint |cFFFFFFFF%s|r pour se présenter."], label()))
    else
        p(self:RoomStatusLine() or L["salle de découverte : en attente du canal (quelques secondes après la connexion)"])
    end
end

-- Ligne de /co status (nil = rien à dire de la salle : le statut garde sa ligne « aucun canal »).
function Dir:RoomStatusLine()
    if not self:RoomEnabled() then
        return L["salle de découverte : coupée — |cFFFFFFFF/co channel room on|r pour la rouvrir"]
    end
    if CraftLink and CraftLink.RoomJoined and CraftLink:RoomJoined() then
        return string.format(L["salle de découverte : |cFFFFFFFF%s|r — on s'y présente, les données restent en whisper"], label())
    end
    if CraftLink and CraftLink.RoomWaitingSlot1 and CraftLink:RoomWaitingSlot1() then   -- personnage neuf
        return L["salle de découverte : en attente d'un canal du jeu sur le /1 (elle ne le prend jamais)"]
    end
    return nil
end

if CraftLink and CraftLink.OnRoomJoined then CraftLink:OnRoomJoined(function() Dir:OnRoomJoined() end) end
