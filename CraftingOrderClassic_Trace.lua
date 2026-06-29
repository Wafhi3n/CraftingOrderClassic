-- CraftingOrderClassic_Trace.lua — trace réseau PERSISTÉE, lisible hors-jeu.
--
-- But : diagnostiquer le social à 2 comptes sans guilde. WoW ne laisse pas un addon écrire un
-- fichier arbitraire → on écrit dans la SavedVariable (COC.db.trace, ring buffer) qui est sérialisée
-- sur disque au /reload ou /logout. On lit ensuite, hors-jeu :
--   D:\Jeux\World of Warcraft\_classic_era_ptr_\WTF\Account\<COMPTE>\SavedVariables\CraftingOrderClassic.lua
-- → table CraftingOrderClassicDB.trace = { "HH:MM:SS [cat] message", ... } pour CHAQUE compte.
--
-- Activation : /co trace (on) · /co trace off · /co trace clear · /co trace dump (30 dernières en chat).
-- La trace reste OFF par défaut (zéro coût en prod) ; on l'allume le temps d'une session de test.

local COC   = CraftingOrderClassic
local Trace = {}
COC.Trace   = Trace

local CAP  = 600         -- lignes max gardées (ring buffer)
local _mem = {}          -- repli si COC.db pas encore prêt (ne devrait pas arriver au runtime)

local function buf()
    if COC.db then
        COC.db.trace = COC.db.trace or _mem
        return COC.db.trace
    end
    return _mem
end

function Trace:IsOn() return COC.db and COC.db.traceOn == true end

function Trace:Log(cat, msg)
    if not self:IsOn() then return end
    local b = buf()
    local t = (date and date("%H:%M:%S")) or tostring((time and time()) or 0)
    b[#b + 1] = string.format("%s [%s] %s", t, tostring(cat or "?"), tostring(msg or ""))
    if #b > CAP then table.remove(b, 1) end
end

function Trace:Clear()
    if COC.db then COC.db.trace = {} end
    _mem = {}
end

-- Auto-active la trace sur PTR / beta (IsTestBuild) → on capture les logs SANS /co trace manuel.
-- `traceOn == nil` = jamais réglé : on respecte un `/co trace off` explicite (traceOn=false) ensuite.
function Trace:AutoEnablePTR()
    if not COC.db then return end
    local isTest = (IsTestBuild and IsTestBuild()) or false
    if isTest and COC.db.traceOn == nil then
        COC.db.traceOn = true
        self:Log("meta", "=== auto-trace ON (PTR/test détecté) par " ..
            ((UnitName and UnitName("player")) or "?") .. " ===")
    end
end

local function p(m) print("|cFF33DD88Crafting Order|r |cFFFF8800[trace]|r " .. m) end

-- /co trace [on|off|clear|dump]
function Trace:Cmd(rest)
    local arg = (rest or ""):lower():gsub("%s+", "")
    if arg == "off" then
        if COC.db then COC.db.traceOn = false end
        p("OFF.")
    elseif arg == "clear" then
        self:Clear(); p("vidée.")
    elseif arg == "dump" then
        local b = buf()
        p(#b .. " lignes (30 dernières) :")
        for i = math.max(1, #b - 29), #b do print(b[i]) end
    else
        if COC.db then COC.db.traceOn = true end
        self:Log("meta", "=== trace ON par " .. ((UnitName and UnitName("player")) or "?") .. " ===")
        p("ON. Fais tes tests, puis |cFFFFFFFF/reload|r, puis lis SavedVariables\\CraftingOrderClassic.lua (clé trace).")
    end
end
