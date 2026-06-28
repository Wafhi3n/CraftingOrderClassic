-- Crafting Order - Classic — Directory : l'annuaire des GENS (présence + qui peut crafter quoi).
--
-- Côté PRODUIT (pas dans la lib) : la relecture sépare le registre des recettes (CraftLink) de
-- l'annuaire des gens (ici). Construit à partir du transport CraftLink :
--   * présence : events JOIN/LEAVE du canal caché (pas de heartbeat) → Dir.online.
--   * recettes des autres : verbe RK reçu sur le canal global → Dir.roster (cache persistant).
--   * proximité : PING/PONG en YELL → porteurs de l'addon autour de soi.
--
-- Discipline cache : réseau → Dir.roster (mémoire = COC.db.roster, persistant) → UI. L'UI ne lit
-- QUE le cache, jamais le réseau.

local COC = CraftingOrderClassic
local Dir = {}
COC.Directory = Dir

local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)

Dir.online = {}   -- [playerShort] = true (éphémère, mémoire)

local function now() return (GetTime and GetTime()) or 0 end

-- ------------------------------------------------------------------
-- Réception
-- ------------------------------------------------------------------
function Dir:OnPresence(kind, who)
    if not who then return end
    if kind == "join" then
        self.online[who] = true
        local r = self.roster and self.roster[who]
        if r and r.source == "added" then
            print("|cFF33DD88Crafting Order|r ton artisan |cFFFFFFFF" .. who .. "|r est en ligne.")
        end
        self:Announce()                 -- un nouveau arrive → je (re)publie mes recettes
    else
        self.online[who] = nil
    end
    if COC.UI and COC.UI.Refresh then COC.UI:Refresh() end
end

-- Un artisan AJOUTÉ À LA MAIN qu'on voit enfin en ligne avec l'addon → liaison confirmée (#6).
function Dir:_NoteLinked(name, r)
    if r and r.manual and not r.linked then
        r.linked = true
        print("|cFF33DD88Crafting Order|r |cFFFFFFFF" .. name ..
            "|r est en ligne avec l'addon — artisan lié.")
    end
end

-- ------------------------------------------------------------------
-- Classement guilde / amis : on croise les porteurs DÉCOUVERTS (canal/proximité) avec le roster
-- de guilde (GetGuildRosterInfo) et la liste d'amis (C_FriendList) pour leur donner la bonne source.
-- Détecter « a l'addon » reste le rôle du canal (RK/SK) ; ici on ne fait que CLASSER.
-- ------------------------------------------------------------------
local function shortName(n) return n and (n:match("^([^%-]+)") or n) or n end

function Dir:ScanRelations()
    self._guildSet, self._friendSet = {}, {}
    if IsInGuild and IsInGuild() and GetNumGuildMembers then
        for i = 1, (GetNumGuildMembers() or 0) do
            local name = GetGuildRosterInfo(i)
            if name then self._guildSet[shortName(name)] = true end
        end
    end
    if C_FriendList and C_FriendList.GetNumFriends then
        for i = 1, (C_FriendList.GetNumFriends() or 0) do
            local info = C_FriendList.GetFriendInfoByIndex(i)
            if info and info.name then self._friendSet[shortName(info.name)] = true end
        end
    end
    self:ReclassifyAll()
end

-- Source naturelle d'un joueur (guilde prioritaire sur amis), ou nil si ni l'un ni l'autre.
function Dir:ClassifySource(name)
    name = shortName(name)
    if self._guildSet  and self._guildSet[name]  then return "guild"  end
    if self._friendSet and self._friendSet[name] then return "friend" end
    return nil
end

-- Applique la source à une entrée roster (sans écraser un ajout manuel « added »).
function Dir:_ApplySource(name, r)
    if not r or r.manual then return end
    r.source = self:ClassifySource(name) or r.source or "recent"
end

function Dir:ReclassifyAll()
    for name, r in pairs(self.roster or {}) do self:_ApplySource(name, r) end
    if COC.UI and COC.UI.Refresh then COC.UI:Refresh() end
end

-- Entretien de la « mini BDD » des métiers : on GARDE à vie guilde/amis/ajoutés (relations) ;
-- on purge les simples « croisés » trop vieux + on plafonne leur nombre (anti-explosion serveur actif).
function Dir:PruneRoster(maxAgeDays, maxRecent)
    if not self.roster then return end
    local cutoff = time() - (maxAgeDays or 30) * 86400
    local recents = {}
    for name, r in pairs(self.roster) do
        local keep = r.manual or r.source == "guild" or r.source == "friend" or r.source == "added"
        if not keep then
            if (r.lastSeen or 0) < cutoff then self.roster[name] = nil
            else recents[#recents + 1] = { name = name, t = r.lastSeen or 0 } end
        end
    end
    maxRecent = maxRecent or 500
    if #recents > maxRecent then
        table.sort(recents, function(a, b) return a.t > b.t end)   -- garde les plus récents
        for i = maxRecent + 1, #recents do self.roster[recents[i].name] = nil end
    end
end

-- RK reçu (recettes d'un autre) → cache roster persistant.
function Dir:OnRK(sender, message)
    if not (sender and CraftLink) then return end
    local prof, hex, dv = CraftLink:ParseRK(message)
    if not prof then return end
    local r = self.roster[sender]; if not r then r = {}; self.roster[sender] = r end
    r.recipes = r.recipes or {}
    r.recipes[prof] = hex
    r.recipeDV = dv
    self:_ApplySource(sender, r)          -- guilde/ami si reconnu, sinon « recent »
    r.lastSeen = time()
    self.online[sender] = true          -- présence passive : un message prouve la présence
    self:_NoteLinked(sender, r)
end

-- HI reçu (un client sollicite l'annuaire) → je réponds mes recettes, jitté (anti-burst).
function Dir:OnHello(sender)
    if not (CraftLink and C_Timer) then return end
    C_Timer.After(math.random() * 3, function() Dir:Announce() end)
end

-- PING de proximité (YELL) → je réponds PONG en YELL (découverte des porteurs autour de moi).
function Dir:OnPing(sender)
    if CraftLink then CraftLink:Send("PONG", "yell") end
    if sender then self.online[sender] = true end
end

-- ------------------------------------------------------------------
-- Émission
-- ------------------------------------------------------------------
-- Publie MES recettes (un RK par métier) + MES niveaux de skill sur le canal global.
function Dir:Announce()
    if not (CraftLink and CraftLink:IsNetworkReady()) then return end
    for _, prof in ipairs(CraftLink:MyProfessions()) do
        local msg = CraftLink:BuildRK(prof)
        if msg then CraftLink:Send(msg, "global") end
    end
    self:AnnounceSkills()
end

-- Re-publication throttlée (3 s) — appelée quand mes recettes changent (plan appris) ou skill gagné,
-- pour que les autres reçoivent mes RK/SK à jour sans spammer le réseau.
function Dir:AnnounceThrottled()
    if not C_Timer then return self:Announce() end
    if self._annTimer then return end
    self._annTimer = true
    C_Timer.After(3, function() self._annTimer = nil; Dir:Announce() end)
end

-- ------------------------------------------------------------------
-- Niveaux de compétence (Étape D) — profil « Forge 250/300 », lisible SANS ouvrir la fenêtre.
-- ------------------------------------------------------------------
-- Capture MES niveaux de métier via l'API skill. Le nom de ligne est localisé → ResolveProfession
-- le ramène à la clé interne EN (les aliases de CraftLink contiennent les noms FR/DE/ES).
function Dir:CaptureSkills()
    if not (CraftLink and GetNumSkillLines) then return end
    self.mySkills = {}
    for i = 1, GetNumSkillLines() do
        local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(i)
        if name and not isHeader and rank and rank > 0 then
            local key = CraftLink:ResolveProfession(name)
            if key and CraftLink.professions[key] then self.mySkills[key] = { rank, maxRank } end
        end
    end
    if COC.db then COC.db.mySkills = self.mySkills end
end

function Dir:AnnounceSkills()
    if not (CraftLink and CraftLink:IsNetworkReady()) then return end
    local parts = {}
    for key, sk in pairs(self.mySkills or {}) do parts[#parts + 1] = key .. "," .. sk[1] .. "," .. sk[2] end
    if #parts > 0 then CraftLink:Send("SK|" .. table.concat(parts, ";"), "global") end
end

-- SK reçu (niveaux d'un autre) → cache roster.
function Dir:OnSkill(sender, message)
    if not sender then return end
    local body = message:match("^SK|(.+)$"); if not body then return end
    local r = self.roster[sender]; if not r then r = {}; self.roster[sender] = r end
    r.skill = r.skill or {}
    for chunk in body:gmatch("[^;]+") do
        local key, cur, max = chunk:match("^([^,]+),(%d+),(%d+)$")
        if key then r.skill[key] = { tonumber(cur), tonumber(max) } end
    end
    self:_ApplySource(sender, r)
    r.lastSeen = time()
    self.online[sender] = true
    self:_NoteLinked(sender, r)
    if COC.UI and COC.UI.Refresh then COC.UI:Refresh() end
end

-- Sollicite l'annuaire (sur action utilisateur) : HI global + un PING de proximité.
function Dir:Refresh()
    if not CraftLink then return end
    CraftLink:Send("HI", "global")
    CraftLink:Send("PING", "yell")
end

-- ------------------------------------------------------------------
-- Requêtes (lisent le CACHE, jamais le réseau)
-- ------------------------------------------------------------------
function Dir:CountOnline()
    local n = 0; for _ in pairs(self.online) do n = n + 1 end; return n
end

function Dir:CountKnownCrafters()
    local n = 0; for _ in pairs(self.roster) do n = n + 1 end; return n
end

-- Joueurs (du cache) qui CONNAISSENT la recette spellID d'un métier, en ligne d'abord.
function Dir:WhoCanCraft(prof, spellID)
    if not CraftLink then return {} end
    local myDV, out = CraftLink:DataVersion(), {}
    for player, r in pairs(self.roster) do
        local hex = r.recipes and r.recipes[prof]
        if hex and r.recipeDV == myDV and CraftLink:HasBit(prof, hex, spellID) then
            out[#out + 1] = { player = player, online = self.online[player] == true }
        end
    end
    table.sort(out, function(a, b)
        if a.online ~= b.online then return a.online end
        return a.player < b.player
    end)
    return out
end

-- ------------------------------------------------------------------
-- Démarrage
-- ------------------------------------------------------------------
function Dir:Start()
    if not CraftLink then return end
    self.roster = (COC.db and COC.db.roster) or {}   -- cache persistant = mini BDD des métiers
    if COC.db then COC.db.roster = self.roster end
    self.mySkills = (COC.db and COC.db.mySkills) or {}
    self:PruneRoster()                               -- entretien au démarrage

    if math.randomseed then math.randomseed((time and time() or 0) + Dir:CountOnline()) end

    CraftLink:RegisterHandler("RK",   function(s, m)    Dir:OnRK(s, m) end)
    CraftLink:RegisterHandler("SK",   function(s, m)    Dir:OnSkill(s, m) end)
    CraftLink:RegisterHandler("HI",   function(s)       Dir:OnHello(s) end)
    CraftLink:RegisterHandler("PING", function(s, m, d) Dir:OnPing(s) end)
    CraftLink:RegisterHandler("PONG", function(s)       if s then Dir.online[s] = true end end)
    CraftLink:OnPresence(function(kind, who) Dir:OnPresence(kind, who) end)

    CraftLink:StartTransport()

    -- Classement guilde/amis : à chaque maj du roster de guilde / liste d'amis → reclasse les
    -- porteurs découverts. On sollicite les deux rosters maintenant pour amorcer.
    local rel = CreateFrame("Frame")
    rel:RegisterEvent("GUILD_ROSTER_UPDATE")
    rel:RegisterEvent("FRIENDLIST_UPDATE")
    rel:SetScript("OnEvent", function()
        if not C_Timer then Dir:ScanRelations(); return end
        if Dir._relTimer then return end
        Dir._relTimer = true
        C_Timer.After(2, function() Dir._relTimer = nil; Dir:ScanRelations() end)
    end)
    if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster()
    elseif GuildRoster then GuildRoster() end
    if C_FriendList and C_FriendList.ShowFriends then C_FriendList.ShowFriends() end

    -- Au démarrage, une fois le canal prêt (join async) : je publie mes recettes (Announce) ET
    -- je sollicite les présents (HI) — sinon je n'apprends que ceux qui arrivent APRÈS moi (les
    -- events JOIN ne listent pas les déjà-présents). Les réponses RK sont jittées (anti-burst).
    if C_Timer then
        C_Timer.After(3, function()
            Dir:CaptureSkills()
            Dir:ScanRelations()
            Dir:Announce()
            if CraftLink:IsNetworkReady() then CraftLink:Send("HI", "global") end
        end)
    end
end
