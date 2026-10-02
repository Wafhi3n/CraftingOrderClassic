-- CraftingOrderClassic_LFWChat.lua — détection « recherche de travail » dans le CHAT VISIBLE.
--
-- Écoute les canaux du jeu COCHÉS et dire/crier (COC.Channels) : un message « LFW <métier> » enregistre son AUTEUR comme cherchant du
-- travail dans l'annuaire — même s'il N'A PAS l'addon (prospect display-only). Mon propre message = simple
-- raccourci de /co lfw <métier>. L'auteur d'un message de chat est authentifié par le jeu → aucune
-- usurpation possible (contrairement à un payload réseau, ici le nom = celui qui a réellement parlé).
-- Verbe protocole (`LFW|on|prof`) exclu par construction : on ignore toute ligne contenant « | »,
-- sauf un LIEN DE MÉTIER (`|Htrade:`) : l'auteur qui lie SON métier entre à l'annuaire, et « LFW [lien] »
-- vaut « LFW <métier> » (spec lien-metier ; décodage et fiche dans Directory_TradeLink.lua). Les liens
-- se lisent aussi en guilde (case « guilde ») et en chuchotement (D8) ; une ligne LFW tapée, non.
-- Toggle `COC.db.lfwChatScan` (défaut ON) via /co lfwchat ; throttlé par auteur ; respecte les mutes.

local COC = CraftingOrderClassic
local LC  = {}
COC.LFWChat = LC
local L = COC.L

local function me() return COC.Api.PlayerName() end   -- nom RÉSEAU (« Prénom Nom » sur Forever)
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

-- « LFW |cff…|Htrade:…|h[Enchanting]|h|r » → « LFW [Enchanting] » : on cherche le jeton LFW hors du
-- balisage, où un GUID ou un libellé pourrait le contenir par hasard.
local function stripLinks(text)
    return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1"))
end

-- Ligne qui porte au moins un lien de métier. `lfwOK` = false en guilde et en chuchotement : seuls
-- les liens y comptent (D8). Retenue par auteur ET métier : un 2e lien d'un autre métier, juste
-- après, n'est pas avalé. Rien n'est jamais envoyé à l'auteur (D7).
function LC:_OnLinks(text, author, guid, lfwOK)
    local D = COC.Directory
    local links = D and D.ParseTradeLinks and D.ParseTradeLinks(text, guid)
    if not (links and links[1]) then return end
    local isLFW = lfwOK and stripLinks(text):find("%f[%a][Ll][Ff][Ww]%f[%A]") ~= nil
    if author == short(me()) then
        if isLFW and D.LFWCmd then D:LFWCmd(links[1].prof) end   -- comme une ligne LFW tapée par moi
        return
    end
    if COC.Moderation and COC.Moderation.IsMuted and COC.Moderation:IsMuted(author) then return end
    local t = (GetTime and GetTime()) or 0
    for i, l in ipairs(links) do
        local k = author .. "\1" .. l.prof
        if (self._last[k] or 0) + THROTTLE <= t then
            self._last[k] = t
            D:NoteLinkSeen(author, l.prof, l.spell)
            -- LFW = UN métier : le premier lien reconnu ; les autres entrent seulement à l'annuaire.
            if isLFW and i == 1 and D.NoteChatLFW then D:NoteChatLFW(author, l.prof) end
        end
    end
end

-- Message reçu. `author` = nom court, authentifié par le jeu ; `guid` = son GUID (le lien doit
-- être le sien, D3) ; `linksOnly` = guilde ou chuchotement, où une ligne LFW tapée n'est pas lue.
function LC:_OnChat(text, author, guid, linksOnly)
    if COC.db and COC.db.lfwChatScan == false then return end   -- toggle (défaut ON tant que non désactivé)
    author = short(author)
    if type(text) ~= "string" or not author or author == "" then return end
    if text:find("|Htrade:", 1, true) then return self:_OnLinks(text, author, guid, not linksOnly) end
    if linksOnly then return end
    local key = self:_Parse(text); if not key then return end
    if author == short(me()) then
        -- L'écho de MA ligne « LFW … #CO », postée par l'addon à l'activation de ma dispo : déjà fait.
        if text:find("#[Cc][Oo]%s*$") then return end
        -- MOI → raccourci /co lfw, SANS annonce sur Commerce : on est dans un événement de chat.
        if COC.Directory and COC.Directory.LFWCmd then COC.Directory:LFWCmd(key) end
        return
    end
    if COC.Moderation and COC.Moderation.IsMuted and COC.Moderation:IsMuted(author) then return end
    local t = (GetTime and GetTime()) or 0
    if (self._last[author] or 0) + THROTTLE > t then return end
    self._last[author] = t
    if COC.Directory and COC.Directory.NoteChatLFW then COC.Directory:NoteChatLFW(author, key) end
end

function LC:Start()
    if self._started then return end
    self._started = true
    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_CHANNEL")
    f:RegisterEvent("CHAT_MSG_SAY")
    f:RegisterEvent("CHAT_MSG_YELL")
    f:RegisterEvent("CHAT_MSG_GUILD")      -- liens seulement (D8)
    f:RegisterEvent("CHAT_MSG_OFFICER")
    f:RegisterEvent("CHAT_MSG_WHISPER")
    f:SetScript("OnEvent", function(_, ev, text, author, _, chanName, ...)
        local guid = select(8, ...)   -- 12e argument : GUID de l'émetteur
        local Api = COC.Api   -- texte secret (verrou du chat) : ni :match, ni :lower, ni comparaison
        if Api.IsSecret(text) or Api.IsSecret(author) or Api.IsSecret(chanName) or Api.IsSecret(guid) then return end
        -- OÙ lire : un canal du jeu reconnu et coché, « dire et crier » coché, la guilde si sa case
        -- est cochée (COC.Channels, spec canaux-surveilles), les chuchotements toujours (pas de case).
        -- `/co lfwchat`, lui, coupe tout (lignes LFW et liens) partout.
        local Ch, linksOnly = COC.Channels, false
        if ev == "CHAT_MSG_CHANNEL" then
            local key = Ch.KeyOf(chanName)
            if not (key and Ch.IsWatched(key)) then return end
        elseif ev == "CHAT_MSG_GUILD" or ev == "CHAT_MSG_OFFICER" then
            if not Ch.IsWatched("guild") then return end
            linksOnly = true
        elseif ev == "CHAT_MSG_WHISPER" then
            linksOnly = true
        elseif not Ch.IsWatched("sayyell") then return end
        LC:_OnChat(text, author, guid, linksOnly)
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
    print("|cFF33DD88Crafting Order|r " .. (on and L["lecture du chat (LFW, liens de métier) : |cFF33DD33activé|r"]
        or L["lecture du chat (LFW, liens de métier) : |cFFFFCC00désactivé|r"]))
end

-- Auto-démarrage au login (self-contained : ne dépend pas de Directory:Start).
local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function() LC:Start() end)
