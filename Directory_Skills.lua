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

-- Fil SK : "SK|lvl=<n>|key,cur,max;...[;rep=<n>][;cv=<ver>]". rep (crafts livrés) et cv (ma version, cf.
-- Directory_Version) = pseudo-chunks FINAUX, ignorés par un vieux client (parse par préfixe) → rétro-
-- compatibles ; JAMAIS dans l'en-tête (corromprait leur 1er métier).
function Dir:_SkillPayload()
    local parts = {}
    for key, sk in pairs(self.mySkills or {}) do parts[#parts + 1] = key .. "," .. sk[1] .. "," .. sk[2] end
    if #parts == 0 then return nil end
    local lvl, rep = (UnitLevel and UnitLevel("player")) or 0, (COC.db and COC.db.delivered) or 0
    local tail = (rep > 0) and (";rep=" .. rep) or ""
    if self._MyVersion then self:_MyVersion(); if self._myVerStr then tail = tail .. ";cv=" .. self._myVerStr end end
    return "SK|lvl=" .. lvl .. "|" .. table.concat(parts, ";") .. tail
end

function Dir:AnnounceSkills()
    if not (CraftLink and CraftLink:IsNetworkReady()) then return end
    local sk = self:_SkillPayload()
    if sk then CraftLink:Send(sk, "global") end
end

-- Parse le message SK → (skills, level, rep, ver) ou nil. PUR (aucun effet sur le roster) : réutilisé
-- par OnSkill (données directes) ET Directory_Relay (fiche relayée). Formats : "SK|lvl=N|..."
-- (avec niveau) ou ancien "SK|...". rep + cv (version) = pseudo-chunks finaux (cf. _SkillPayload).
function Dir:_ParseSKBody(message)
    local lvl, body = (message or ""):match("^SK|lvl=(%d+)|(.+)$")
    if not body then body = (message or ""):match("^SK|(.+)$") end
    if not body then return nil end
    local skills, rep, ver = {}, nil, nil
    for chunk in body:gmatch("[^;]+") do
        local rp = chunk:match("^rep=(%d+)$")
        local cv = (not rp) and chunk:match("^cv=(.+)$") or nil
        if rp then rep = tonumber(rp)
        elseif cv then ver = cv
        else
            local key, cur, max = chunk:match("^([^,]+),(%d+),(%d+)$")
            if key then skills[key] = { tonumber(cur), tonumber(max) } end
        end
    end
    return skills, lvl and tonumber(lvl) or nil, rep, ver
end

-- SK reçu (niveaux d'un autre) → cache roster.
function Dir:OnSkill(sender, message)
    if not sender then return end
    local skills, lvl, rep, ver = self:_ParseSKBody(message)
    if not skills then return end
    if ver and self.NotePeerVersion then self:NotePeerVersion(sender, ver) end   -- version = 1re main (jamais relais)
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

-- « Bonjour » DIRIGÉ, niveaux de métier COLLÉS ("HI|SK|…" si j'ai des métiers, sinon "HI" nu) : l'autre
-- apprend mes métiers DÈS le hello, sans round-trip AnnounceTo séparé → moins de transactions, et plus
-- de « Croisé en ligne, 0 métier ». Un client v≤1.15 ignore le corps du HI → rétro-compatible.
function Dir:_HelloPayload()
    local sk = self:_SkillPayload()
    return sk and ("HI|" .. sk) or "HI"
end

-- Réponse d'annuaire throttlée PAR CIBLE (60 s, comme DiscoverPlayer) : un pair qui me spamme de HI/PING ne
-- peut plus me faire rediffuser tout mon profil (SK+RK×métiers+CD+ALT) à chaque message ; un PING+HI groupé
-- (vieux client) ne déclenche qu'UNE annonce (throttle partagé OnPing/OnHello). 1re sollicitation = plein.
function Dir:_AnnounceToThrottled(target)
    if not target then return end
    self._lastAnnTo = self._lastAnnTo or {}
    local t = (GetTime and GetTime()) or 0
    if (self._lastAnnTo[target] or 0) + 60 > t then return end
    self._lastAnnTo[target] = t
    self:AnnounceTo(target)
end
