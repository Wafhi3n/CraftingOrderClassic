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
        self:Announce()                 -- un nouveau arrive → je (re)publie mes recettes
    else
        self.online[who] = nil
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
    r.lastSeen = time()
    self.online[sender] = true          -- présence passive : un message prouve la présence
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
-- Publie MES recettes (un RK par métier) sur le canal global.
function Dir:Announce()
    if not (CraftLink and CraftLink:IsNetworkReady()) then return end
    for _, prof in ipairs(CraftLink:MyProfessions()) do
        local msg = CraftLink:BuildRK(prof)
        if msg then CraftLink:Send(msg, "global") end
    end
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
    self.roster = (COC.db and COC.db.roster) or {}   -- cache persistant
    if COC.db then COC.db.roster = self.roster end

    if math.randomseed then math.randomseed((time and time() or 0) + Dir:CountOnline()) end

    CraftLink:RegisterHandler("RK",   function(s, m)    Dir:OnRK(s, m) end)
    CraftLink:RegisterHandler("HI",   function(s)       Dir:OnHello(s) end)
    CraftLink:RegisterHandler("PING", function(s, m, d) Dir:OnPing(s) end)
    CraftLink:RegisterHandler("PONG", function(s)       if s then Dir.online[s] = true end end)
    CraftLink:OnPresence(function(kind, who) Dir:OnPresence(kind, who) end)

    CraftLink:StartTransport()

    -- Au démarrage, une fois le canal prêt (join async) : je publie mes recettes (Announce) ET
    -- je sollicite les présents (HI) — sinon je n'apprends que ceux qui arrivent APRÈS moi (les
    -- events JOIN ne listent pas les déjà-présents). Les réponses RK sont jittées (anti-burst).
    if C_Timer then
        C_Timer.After(3, function()
            Dir:Announce()
            if CraftLink:IsNetworkReady() then CraftLink:Send("HI", "global") end
        end)
    end
end
