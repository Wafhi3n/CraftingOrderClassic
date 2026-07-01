-- Directory_Skills.lua — niveaux de compétence + réputation (couche « profil » de l'annuaire).
--
-- Extrait de Directory.lua (anti-monolithe) : capture MES niveaux de métier (API skill, lisibles sans
-- ouvrir la fenêtre), les diffuse (verbe SK, avec la réputation = crafts livrés en pseudo-chunk final),
-- et reçoit ceux des autres → Dir.roster[name].skill/.level/.rep. Les méthodes restent sur la table
-- COC.Directory (créée par Directory.lua, chargé AVANT) → self:_Touch etc. résolus sur la table partagée.

local COC = CraftingOrderClassic
local Dir = COC.Directory

local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)

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

-- Fil SK : "SK|lvl=<n>|key,cur,max;...[;rep=<n>]". rep (crafts livrés) = pseudo-chunk FINAL, ignoré par un
-- client v1.0.0 → rétro-compatible ; JAMAIS dans l'en-tête (corromprait leur 1er métier).
function Dir:_SkillPayload()
    local parts = {}
    for key, sk in pairs(self.mySkills or {}) do parts[#parts + 1] = key .. "," .. sk[1] .. "," .. sk[2] end
    if #parts == 0 then return nil end
    local lvl, rep = (UnitLevel and UnitLevel("player")) or 0, (COC.db and COC.db.delivered) or 0
    return "SK|lvl=" .. lvl .. "|" .. table.concat(parts, ";") .. (rep > 0 and (";rep=" .. rep) or "")
end

function Dir:AnnounceSkills()
    if not (CraftLink and CraftLink:IsNetworkReady()) then return end
    local sk = self:_SkillPayload()
    if sk then CraftLink:Send(sk, "global") end
end

-- SK reçu (niveaux d'un autre) → cache roster. Formats : "SK|lvl=N|..." (avec niveau) ou ancien "SK|...".
function Dir:OnSkill(sender, message)
    if not sender then return end
    local lvl, body = message:match("^SK|lvl=(%d+)|(.+)$")
    if not body then body = message:match("^SK|(.+)$") end
    if not body then return end
    local r = self:_Touch(sender)
    r.skill = r.skill or {}
    if lvl then r.level = tonumber(lvl) end
    for chunk in body:gmatch("[^;]+") do
        local rep = chunk:match("^rep=(%d+)$")           -- réputation = pseudo-chunk final
        if rep then r.rep = tonumber(rep) else
            local key, cur, max = chunk:match("^([^,]+),(%d+),(%d+)$")
            if key then r.skill[key] = { tonumber(cur), tonumber(max) } end
        end
    end
    if COC.UI and COC.UI.Refresh then COC.UI:Refresh() end
end
