-- Directory_Skills.lua — niveaux de compétence + réputation (couche « profil » de l'annuaire).
--
-- Extrait de Directory.lua (anti-monolithe) : capture MES niveaux de métier (API skill, lisibles sans
-- ouvrir la fenêtre), les diffuse (verbe SK, avec la réputation = crafts livrés en pseudo-chunk final),
-- et reçoit ceux des autres → Dir.roster[name].skill/.level/.rep. Les méthodes restent sur la table
-- COC.Directory (créée par Directory.lua, chargé AVANT) → self:_Touch etc. résolus sur la table partagée.

local COC = CraftingOrderClassic
local Dir = COC.Directory

local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)

local function me() return (UnitName and UnitName("player")) or "?" end
local function myRealm() return (GetRealmName and GetRealmName()) or "" end

-- Miroir de mySkills (perso COURANT) vers une partition PAR PERSO (clé « Nom-Royaume », comme
-- knownRecipes/myChars) → l'onglet « Mes artisans » lit les niveaux de TOUS mes rerolls hors ligne.
-- COPIE des {rank,max} : self.mySkills est réassigné {} à chaque CaptureSkills, une référence
-- pointerait vers une table qui sera remplacée.
local function mirrorMySkills(skills)
    if not COC.db then return end
    COC.db.mySkillsByChar = COC.db.mySkillsByChar or {}
    local part = {}
    for key, sk in pairs(skills) do part[key] = { sk[1], sk[2] } end
    COC.db.mySkillsByChar[me() .. "-" .. myRealm()] = part
end

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
    if COC.db then COC.db.mySkills = self.mySkills; mirrorMySkills(self.mySkills) end
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

-- Parse le message SK → (skills, level, rep) ou nil. PUR (aucun effet sur le roster) : réutilisé
-- par OnSkill (données directes) ET Directory_Relay (fiche relayée). Formats : "SK|lvl=N|..."
-- (avec niveau) ou ancien "SK|...". rep = pseudo-chunk final.
function Dir:_ParseSKBody(message)
    local lvl, body = (message or ""):match("^SK|lvl=(%d+)|(.+)$")
    if not body then body = (message or ""):match("^SK|(.+)$") end
    if not body then return nil end
    local skills, rep = {}, nil
    for chunk in body:gmatch("[^;]+") do
        local rp = chunk:match("^rep=(%d+)$")
        if rp then rep = tonumber(rp) else
            local key, cur, max = chunk:match("^([^,]+),(%d+),(%d+)$")
            if key then skills[key] = { tonumber(cur), tonumber(max) } end
        end
    end
    return skills, lvl and tonumber(lvl) or nil, rep
end

-- SK reçu (niveaux d'un autre) → cache roster.
function Dir:OnSkill(sender, message)
    if not sender then return end
    local skills, lvl, rep = self:_ParseSKBody(message)
    if not skills then return end
    local r = self:_Touch(sender)
    if lvl then r.level = lvl end
    if rep then r.rep = rep end
    -- SK = énumération COMPLÈTE des métiers RÉELS du perso courant de l'émetteur (GetNumSkillLines,
    -- jamais bleedée par les alts contrairement au RK). On reconstruit à neuf (un métier abandonné
    -- disparaît) puis on s'en sert comme vérité terrain pour purger les RK périmés.
    if next(skills) then
        r.skill = skills
        -- Purge la fuite d'alts : un RK pour un métier que le perso n'a pas réellement (absent du SK)
        -- est périmé/bleedé par un vieux client (ex. « Poisons » diffusé par un non-voleur) → on l'enlève.
        if r.recipes then
            for prof in pairs(r.recipes) do
                if not skills[prof] then r.recipes[prof] = nil end
            end
        end
    end
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
end
