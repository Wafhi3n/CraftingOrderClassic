-- CraftingOrderClassic_LFWChat.lua — détection « recherche de travail » dans le CHAT VISIBLE.
--
-- Écoute Trade/Général/say/yell : un message « LFW <métier> » enregistre son AUTEUR comme cherchant du
-- travail dans l'annuaire — même s'il N'A PAS l'addon (prospect display-only). Mon propre message = simple
-- raccourci de /co lfw <métier>. L'auteur d'un message de chat est authentifié par le jeu → aucune
-- usurpation possible (contrairement à un payload réseau, ici le nom = celui qui a réellement parlé).
-- Verbe protocole (`LFW|on|prof`) exclu par construction : on ignore toute ligne contenant « | ».
-- Toggle `COC.db.lfwChatScan` (défaut ON) via /co lfwchat ; throttlé par auteur ; respecte les mutes.

local COC = CraftingOrderClassic
local LC  = {}
COC.LFWChat = LC
local L = COC.L

local function me() return (UnitName and UnitName("player")) or "?" end
local function short(n) return n and (n:match("^([^%-]+)") or n) or n end
local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

local THROTTLE = 30            -- s : un même auteur n'est retraité qu'après ce délai (anti-répétition Trade)
LC._last = {}

-- Extrait la clé de métier canonique d'un message « … LFW <mot> … » (nil sinon). « LFW » doit être un
-- TOKEN (bornes de mot, pas « LFWands ») ; le 1er mot alpha qui suit est le métier écrit par le joueur.
-- On n'accepte QUE s'il résout vers un vrai métier connu (ResolveProfession renvoie le mot brut sinon).
function LC:_Parse(text)
    if not text or text:find("|", 1, true) then return nil end
    local word = text:match("%f[%a][Ll][Ff][Ww]%f[%A][%s:%-]*([%a]+)")
    if not word then return nil end
    local c = CL()
    local key = c and c.ResolveProfession and c:ResolveProfession(word)
    if not (key and c.GetProfession and c:GetProfession(key)) then return nil end
    return key
end

-- Message reçu (canal public, say ou yell). `author` = nom court, authentifié par le jeu.
function LC:_OnChat(text, author)
    if COC.db and COC.db.lfwChatScan == false then return end   -- toggle (défaut ON tant que non désactivé)
    author = short(author)
    if not author or author == "" then return end
    local key = self:_Parse(text); if not key then return end
    if author == short(me()) then
        if COC.Directory and COC.Directory.LFWCmd then COC.Directory:LFWCmd(key) end   -- MOI → raccourci /co lfw
        return
    end
    if COC.Moderation and COC.Moderation.IsMuted and COC.Moderation:IsMuted(author) then return end
    local t = (GetTime and GetTime()) or 0
    if (self._last[author] or 0) + THROTTLE > t then return end
    self._last[author] = t
    if COC.Directory and COC.Directory.NoteChatLFW then COC.Directory:NoteChatLFW(author, key) end
end

-- Canal Trade/Général uniquement (pas les canaux custom/PvP/monde). Nom localisé → on teste les bases connues.
function LC:_IsPublicChannel(chanName)
    if not chanName then return false end
    local n = chanName:lower()
    return (n:find("trade") or n:find("general") or n:find("commerce") or n:find("général")
        or n:find("handel") or n:find("allgemein") or n:find("comercio")) and true or false
end

function LC:Start()
    if self._started then return end
    self._started = true
    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_CHANNEL")
    f:RegisterEvent("CHAT_MSG_SAY")
    f:RegisterEvent("CHAT_MSG_YELL")
    f:SetScript("OnEvent", function(_, ev, text, author, _, chanName)
        if ev == "CHAT_MSG_CHANNEL" and not LC:_IsPublicChannel(chanName) then return end
        LC:_OnChat(text, author)
    end)
end

-- /co lfwchat [on|off] : active/coupe le scan (sans arg = bascule).
function LC:Cmd(arg)
    COC.db = COC.db or {}
    arg = ((arg or ""):match("^%s*(.-)%s*$")):lower()
    if arg == "on" then COC.db.lfwChatScan = true
    elseif arg == "off" then COC.db.lfwChatScan = false
    else COC.db.lfwChatScan = (COC.db.lfwChatScan == false) end
    local on = COC.db.lfwChatScan ~= false
    print("|cFF33DD88Crafting Order|r " .. (on and L["scan LFW du chat : |cFF33DD33activé|r"]
        or L["scan LFW du chat : |cFFFFCC00désactivé|r"]))
end

-- Auto-démarrage au login (self-contained : ne dépend pas de Directory:Start).
local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function() LC:Start() end)
