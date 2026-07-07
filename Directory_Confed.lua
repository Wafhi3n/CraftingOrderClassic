-- Directory_Confed.lua — source « confédération » (GreenWall) de l'annuaire, DISPLAY-ONLY.
--
-- Extrait de Directory.lua (anti-monolithe) : ajoute des méthodes sur la table partagée COC.Directory
-- (créée par Directory.lua, chargé AVANT dans le .toc). Voir [[coc-confederation-display]].

local COC = CraftingOrderClassic
local Dir = COC.Directory

-- shortName : dupliqué de Directory.lua (fonction file-locale ; on ne partage pas les locales entre modules).
local function shortName(n) return n and (n:match("^([^%-]+)") or n) or n end

-- ------------------------------------------------------------------
-- Confédération GreenWall — DISPLAY-ONLY (cf. [[wow-greenwall-hardware-event]]). GreenWall relaie le chat
-- des sœurs via gw.ReplicateMessage('GUILD', …) : tout `sender` est un CONFÉDÉRÉ (seul signal — WoW
-- n'expose pas la guilde d'autrui). On CLASSE juste un contact connu de CraftLink en source « confed »,
-- AUCUN transport. _confedSet en MÉMOIRE. Limite : ne capte que les confédérés actifs en /g.
local function gwTable() return _G and rawget(_G, "gw") end
function Dir:_GreenWallActive()
    local gwt = gwTable()
    return type(gwt) == "table" and type(gwt.ReplicateMessage) == "function"
end

function Dir:_NoteConfederate(name, guild_id)   -- guild_id = guilde d'origine (info, '-' = inconnu)
    local sn = shortName(name)
    if not sn or sn == "" or sn == shortName(UnitName and UnitName("player") or "") then return end
    self._confedSet = self._confedSet or {}
    local gid = (guild_id and guild_id ~= "-" and guild_id ~= "") and guild_id or nil
    local prev = self._confedSet[sn]
    if prev == nil or gid then self._confedSet[sn] = gid or prev or true end
    local r = self.roster and self.roster[sn]   -- reclasse maintenant si déjà connu, sinon à sa découverte
    if r then self:_ApplySource(sn, r); if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end end
end

-- Greffe PASSIVE (hooksecurefunc = observe, ne remplace rien). API pas prête au login → retry ~1 min.
function Dir:_WireGreenWall(attempt)
    if self._gwHooked then return end
    attempt = attempt or 1
    local gwt = gwTable()
    if type(gwt) == "table" and type(gwt.ReplicateMessage) == "function" then
        self._gwHooked = true
        self._confedSet = self._confedSet or {}
        hooksecurefunc(gwt, "ReplicateMessage", function(event, _, guild_id, arglist)
            if event == "GUILD" then
                local sender = arglist and arglist[2]
                if sender and sender ~= "" then Dir:_NoteConfederate(sender, guild_id) end
            end
        end)
    elseif attempt < 12 and C_Timer then
        C_Timer.After(5, function() Dir:_WireGreenWall(attempt + 1) end)
    end
end
