-- CraftingOrderClassic_Moderation.lua — modération / anti-spam.
--
-- Alimente COC.db.mutedPlayers (lu par Orders:_ShouldAlert et Inbound:Alert : un joueur muté ne
-- déclenche AUCUNE notif — toast/chat/son — ni sur le réseau P2P ni sur la capture chat). Trois leviers :
--   * MUTE MANUEL : /co mute|unmute <nom>, shift-clic-droit sur une carte, menu contextuel joueur.
--   * MUTE AUTO BAS NIVEAU : COC.db.muteBelowLevel (défaut 5) — ignore les posts d'un perso dont le
--     niveau CONNU (via l'annuaire, verbe SK) est sous le seuil (anti bots/mules). Niveau inconnu = pas de mute.
--   * DÉTECTION DE SPAM : compte les posts par auteur sur une fenêtre glissante ; au seuil, mute
--     directement (mode auto) ou propose un popup (défaut). Seuils RÉGLABLES et persistés via
--     /co spam (max, fenêtre, auto). Suivi RUNTIME (compteurs/popups) non persisté : reset par session.

local COC = CraftingOrderClassic
local Mod = {}
COC.Moderation = Mod
local L = COC.L

local function pmsg(m) print("|cFF33DD88Crafting Order|r " .. m) end

-- Trace DIAGNOSTIC (catégorie « mod ») pour les sessions de test anti-spam : lisible hors-jeu dans
-- SavedVariables (clé trace) après /co trace on. OFF en prod (Trace:Log garde sur IsOn). Strings FR
-- dev (comme les autres lignes de trace), pas de clé de locale.
local function tr(fmt, ...)
    if not COC.Trace then return end
    COC.Trace:Log("mod", (select("#", ...) > 0) and string.format(fmt, ...) or fmt)
end

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
    tr("muté : %s", name)
    pmsg(string.format(L["%s est mis en sourdine — plus aucune notification de sa part."], name))
    if COC.UI and COC.UI.Refresh then COC.UI:Refresh() end
end

function Mod:Unmute(name)
    name = canon(name)
    if not (name and COC.db and COC.db.mutedPlayers) then return end
    COC.db.mutedPlayers[name] = nil
    tr("démuté : %s", name)
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
    local below = lvl ~= nil and lvl < thr
    if below then tr("post de %s ignoré (niveau %d < seuil %d)", name, lvl, thr) end
    return below
end

-- /co lowlevel [N|off] : seuil de mute auto des petits persos (0/off = désactivé).
function Mod:LowLevelCmd(arg)
    arg = (arg or ""):lower():match("^%s*(.-)%s*$")
    local n = tonumber(arg)
    if arg == "off" then COC.db.muteBelowLevel = 0
    elseif n then COC.db.muteBelowLevel = math.max(0, math.floor(n)) end
    local cur = (COC.db and COC.db.muteBelowLevel) or 5
    tr("seuil bas-niveau -> %d", cur)
    if cur <= 0 then pmsg(L["mute auto bas niveau : |cFFFFFFFFdésactivé|r — /co lowlevel <niveau>"])
    else pmsg(string.format(L["mute auto bas niveau : sous le niveau |cFFFFFFFF%d|r — /co lowlevel [N|off]"], cur)) end
end

-- ------------------------------------------------------------------
-- Détection de spam — seuils PERSISTÉS (réglables /co spam), suivi RUNTIME non persisté.
-- ------------------------------------------------------------------
local DEF_WINDOW = 60     -- fenêtre glissante (s) par défaut
local DEF_MAX    = 5      -- posts dans la fenêtre → mute (défaut) ; 0 = détection désactivée
Mod._posts    = {}        -- [name] = { horodatages récents }
Mod._prompted = {}        -- [name] = true : mute déjà proposé/appliqué cette session

local function spamMax()    return (COC.db and COC.db.spamMax) or DEF_MAX end
local function spamWindow() local w = COC.db and COC.db.spamWindow; return (w and w > 0) and w or DEF_WINDOW end
local function spamAuto()   return (COC.db and COC.db.spamAuto) == true end

-- Un auteur vient de poster (ordre réseau NEW inédit, ou entrante captée). Enregistre l'horodatage
-- et, au seuil, mute directement (auto) ou propose un popup. Une fois par session/auteur.
function Mod:NotePost(name)
    name = canon(name); if not name then return end
    local maxN = spamMax()
    if maxN <= 0 then return end                                     -- détection désactivée (/co spam off)
    if self:IsMuted(name) then tr("post de %s ignoré (déjà muté)", name); return end
    if self._prompted[name] then return end
    local now, win = time(), spamWindow()
    local keep = {}
    for _, ts in ipairs(self._posts[name] or {}) do
        if now - ts <= win then keep[#keep + 1] = ts end
    end
    keep[#keep + 1] = now
    self._posts[name] = keep
    tr("post de %s : %d/%d en %ds", name, #keep, maxN, win)
    if #keep >= maxN then self:_TripSpam(name, #keep) end
end

-- Seuil franchi : mute direct (mode auto) ou popup. `_prompted` évite la répétition en mode popup.
function Mod:_TripSpam(name, cnt)
    self._prompted[name] = true
    if spamAuto() then
        tr("SEUIL spam atteint pour %s (%d posts) -> mute auto", name, cnt)
        self:Mute(name)
    else
        tr("SEUIL spam atteint pour %s (%d posts) -> popup", name, cnt)
        self:_PromptMute(name, cnt)
    end
end

function Mod:_PromptMute(name, cnt)
    tr("popup mute proposé : %s (%d posts)", name, cnt)
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

-- /co spam [off|auto|<max> [fenêtre]] : configure la détection de spam. Sans argument → état courant.
-- Tout changement RÉINITIALISE le suivi de session (compteurs + auteurs déjà proposés) → pratique pour
-- re-déclencher en test (ex. /co spam 2 = mute/popup au 2e post).
function Mod:SpamCmd(arg)
    local a, b = (arg or ""):lower():match("^%s*(%S*)%s*(%S*)")
    if a == "auto" then
        COC.db.spamAuto = not spamAuto(); self:_ResetSpam()
    elseif a == "off" then
        COC.db.spamMax = 0; self:_ResetSpam()
    elseif tonumber(a) then
        COC.db.spamMax = math.max(0, math.floor(tonumber(a)))
        local w = tonumber(b); if w then COC.db.spamWindow = math.max(1, math.floor(w)) end
        self:_ResetSpam()
    end
    self:_PrintSpam()
end

function Mod:_ResetSpam()
    self._posts, self._prompted = {}, {}
    tr("réglages spam : max=%d fenêtre=%ds auto=%s (suivi réinitialisé)",
        spamMax(), spamWindow(), tostring(spamAuto()))
end

function Mod:_PrintSpam()
    if spamMax() <= 0 then
        pmsg(L["détection de spam : |cFFFFFFFFdésactivée|r — /co spam <max> [fenêtre] pour l'activer"])
    else
        pmsg(string.format(L["détection de spam : |cFFFFFFFF%d|r posts / |cFFFFFFFF%ds|r → %s"],
            spamMax(), spamWindow(), spamAuto() and L["mute auto"] or L["popup"]))
        pmsg(L["  /co spam <max> [fenêtre] · /co spam auto · /co spam off"])
    end
end
