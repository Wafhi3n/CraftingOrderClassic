-- CraftingOrderClassic_Moderation.lua — modération / anti-spam.
--
-- Alimente COC.db.mutedPlayers (lu par Orders:_ShouldAlert et Inbound:Alert : un joueur muté ne
-- déclenche AUCUNE notif — toast/chat/son — ni sur le réseau P2P ni sur la capture chat). Trois leviers :
--   * MUTE MANUEL : /co mute|unmute <nom>, shift-clic-droit sur une carte, menu contextuel joueur.
--   * MUTE AUTO BAS NIVEAU : COC.db.muteBelowLevel (défaut 5) — ignore les posts d'un perso dont le
--     niveau CONNU (via l'annuaire, verbe SK) est sous le seuil (anti bots/mules). Niveau inconnu = pas de mute.
--   * DÉTECTION DE SPAM : compte les posts par auteur sur une fenêtre glissante ; au-delà du seuil,
--     propose (popup) de le muter. Suivi RUNTIME (non persisté) : reset à chaque session.

local COC = CraftingOrderClassic
local Mod = {}
COC.Moderation = Mod
local L = COC.L

local function pmsg(m) print("|cFF33DD88Crafting Order|r " .. m) end

-- Nom canonique : sans suffixe de royaume (les auteurs d'ordres/entrantes sont stockés en nom court).
local function canon(name)
    if not name or name == "" then return nil end
    return name:match("^([^%-]+)") or name
end

-- ------------------------------------------------------------------
-- Mute manuel
-- ------------------------------------------------------------------
function Mod:IsMuted(name)
    name = canon(name)
    return (name and COC.db and COC.db.mutedPlayers and COC.db.mutedPlayers[name]) == true
end

function Mod:Mute(name)
    name = canon(name)
    if not (name and COC.db) then return end
    COC.db.mutedPlayers = COC.db.mutedPlayers or {}
    COC.db.mutedPlayers[name] = true
    pmsg(string.format(L["%s est mis en sourdine — plus aucune notification de sa part."], name))
    if COC.UI and COC.UI.Refresh then COC.UI:Refresh() end
end

function Mod:Unmute(name)
    name = canon(name)
    if not (name and COC.db and COC.db.mutedPlayers) then return end
    COC.db.mutedPlayers[name] = nil
    pmsg(string.format(L["%s n'est plus en sourdine."], name))
    if COC.UI and COC.UI.Refresh then COC.UI:Refresh() end
end

function Mod:PrintMuted()
    local names = {}
    for n in pairs(COC.db and COC.db.mutedPlayers or {}) do names[#names + 1] = n end
    table.sort(names)
    if #names == 0 then pmsg(L["aucun joueur en sourdine. /co mute <nom> pour en ajouter un."])
    else pmsg(string.format(L["en sourdine (%d) : %s"], #names, table.concat(names, ", "))) end
end

-- /co mute [nom] : sans argument, liste les joueurs mutés.
function Mod:MuteCmd(arg)
    arg = arg and arg:match("^%s*(.-)%s*$") or ""
    if arg == "" then self:PrintMuted() else self:Mute(arg) end
end

function Mod:UnmuteCmd(arg)
    arg = arg and arg:match("^%s*(.-)%s*$") or ""
    if arg == "" then pmsg(L["usage : /co unmute <nom>"]) else self:Unmute(arg) end
end

-- ------------------------------------------------------------------
-- Mute auto bas niveau
-- ------------------------------------------------------------------
-- Le post d'un auteur doit-il être ignoré parce que son niveau CONNU est sous le seuil ? Niveau lu
-- dans l'annuaire (roster[name].level, diffusé par le verbe SK). Inconnu → false : on ne suppose rien
-- (un poster chat sans addon n'a pas de niveau connu → il passe, cf. limite documentée).
function Mod:BelowThreshold(name)
    local thr = (COC.db and COC.db.muteBelowLevel) or 5
    if thr <= 0 then return false end
    name = canon(name); if not name then return false end
    local D = COC.Directory
    local r = D and D.roster and D.roster[name]
    local lvl = r and r.level
    return lvl ~= nil and lvl < thr
end

-- /co lowlevel [N|off] : seuil de mute auto des petits persos (0/off = désactivé).
function Mod:LowLevelCmd(arg)
    arg = (arg or ""):lower():match("^%s*(.-)%s*$")
    local n = tonumber(arg)
    if arg == "off" then COC.db.muteBelowLevel = 0
    elseif n then COC.db.muteBelowLevel = math.max(0, math.floor(n)) end
    local cur = (COC.db and COC.db.muteBelowLevel) or 5
    if cur <= 0 then pmsg(L["mute auto bas niveau : |cFFFFFFFFdésactivé|r — /co lowlevel <niveau>"])
    else pmsg(string.format(L["mute auto bas niveau : sous le niveau |cFFFFFFFF%d|r — /co lowlevel [N|off]"], cur)) end
end

-- ------------------------------------------------------------------
-- Détection de spam (suivi RUNTIME, non persisté)
-- ------------------------------------------------------------------
local SPAM_WINDOW = 60    -- secondes de la fenêtre glissante
local SPAM_MAX    = 5     -- posts dans la fenêtre → proposition de mute
Mod._posts    = {}        -- [name] = { horodatages récents }
Mod._prompted = {}        -- [name] = true : popup déjà proposé cette session

-- Un auteur vient de poster (ordre réseau NEW inédit, ou entrante captée). Enregistre l'horodatage
-- et, si le débit dépasse le seuil, propose de le muter (une fois par session, sauf déjà muté).
function Mod:NotePost(name)
    name = canon(name); if not name then return end
    if self:IsMuted(name) or self._prompted[name] then return end
    local now = time()
    local keep = {}
    for _, ts in ipairs(self._posts[name] or {}) do
        if now - ts <= SPAM_WINDOW then keep[#keep + 1] = ts end
    end
    keep[#keep + 1] = now
    self._posts[name] = keep
    if #keep >= SPAM_MAX then self._prompted[name] = true; self:_PromptMute(name, #keep) end
end

function Mod:_PromptMute(name, cnt)
    local msg = string.format(L["%s a posté %d fois en peu de temps. Le mettre en sourdine ?"], name, cnt)
    if StaticPopupDialogs and StaticPopup_Show then
        -- nom passé en `data` (pas via closure) → un 2e popup ne réécrit pas la cible du 1er.
        StaticPopupDialogs["COC_SPAM_MUTE"] = {
            text = "%s", button1 = L["Muter"], button2 = CANCEL or L["Annuler"],
            OnAccept = function(_, data) COC.Moderation:Mute(data) end,
            timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
        }
        StaticPopup_Show("COC_SPAM_MUTE", msg, nil, name)
    end
    local Skin = COC.UI and COC.UI.Skin
    pmsg((Skin and ("|T" .. Skin.tex.workorder .. ":0|t ") or "") .. msg
        .. "  |cFFFFFFFF/co mute " .. name .. "|r")
end
