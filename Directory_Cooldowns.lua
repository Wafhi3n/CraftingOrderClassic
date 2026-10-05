-- Directory_Cooldowns.lua — cooldowns de recettes (couche « profil » de l'annuaire).
--
-- Réception du verbe CD (cooldowns d'un autre porteur) → Dir.roster[name].cooldowns[prof] =
-- { [spellID] = readyAt epoch } + cdStamp[prof] (fraîcheur de l'info) ; émission des MIENS
-- (CraftLink.myCooldowns) dans le sillage des annonces SK/RK. Le fil transporte du RELATIF
-- (secondes restantes, cf. CraftLink_Cooldowns) ; le roster stocke de l'ABSOLU (survit aux
-- relogs, l'UI recalcule le restant à l'affichage). Les méthodes restent sur COC.Directory
-- (créée par Directory.lua, chargé AVANT) → self:_Touch etc. résolus sur la table partagée.

local COC = CraftingOrderClassic
local Dir = COC.Directory

local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)

local CD_KEEP = 14 * 86400   -- rétention d'un readyAt DÉPASSÉ : 14 j (readyAt passé = « prête », utile)

-- Un CD annoncé est-il VRAISEMBLABLE ? Non quand la recette s'apprend à un rang que l'émetteur n'a
-- pas atteint (`skill` = sa table SK { [prof] = { rang, max } }, directe ou relayée). Les copies de
-- CraftLink d'avant COOLDOWNS_REV 7 relevaient « prête » des recettes non apprises : relevé le
-- 2026-10-05, des inconnus diffusaient l'Étoffe lunaire (apprise à 250) sur la bêta plafonnée au
-- niveau 30. Elles restent en circulation : on les écarte à la réception. Sans rang annoncé ou sans
-- niveau d'apprentissage connu, pas d'avis : on garde.
function Dir:CooldownPlausible(skill, prof, sid)
    local sk = type(skill) == "table" and skill[prof]
    local rank = type(sk) == "table" and tonumber(sk[1]) or nil
    local need = CraftLink and CraftLink.RecipeLearnedAt and CraftLink:RecipeLearnedAt(prof, sid)
    return not (rank and need and need > rank)
end

-- CD reçu (cooldowns d'un autre) → cache roster persistant. MERGE par métier (un état arrive
-- éventuellement en plusieurs chunks) ; chaque annonce couvrant TOUTES les recettes suivies de
-- l'émetteur, les entrées se réécrivent d'elles-mêmes — PruneCooldowns balaie le reliquat.
-- Un CD invraisemblable (cf. CooldownPlausible) n'entre pas, et efface celui qu'on gardait.
function Dir:OnCD(sender, message)
    if not (sender and CraftLink and CraftLink.ParseCD) then return end
    local prof, list = CraftLink:ParseCD(message)
    if not prof then return end
    local r = self.roster[sender]; if not r then r = {}; self.roster[sender] = r end
    if r.skill and next(r.skill) and not r.skill[prof] then return end  -- anti fuite d'alts : SK = vérité terrain
    local ts = time()
    r.cooldowns = r.cooldowns or {}
    local cds = r.cooldowns[prof]; if not cds then cds = {}; r.cooldowns[prof] = cds end
    for _, e in ipairs(list) do
        cds[e.sid] = self:CooldownPlausible(r.skill, prof, e.sid) and (ts + e.remain) or nil
    end
    if not next(cds) then r.cooldowns[prof] = nil end   -- vide : CooldownLines retombe sur le relais
    r.cdStamp = r.cdStamp or {}; r.cdStamp[prof] = ts
    self:_ApplySource(sender, r)
    r.lastSeen = ts
    self.online[sender] = true          -- présence passive : un message prouve la présence
    self:_NoteLinked(sender, r)
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
end

-- Émet MES cooldowns — appelé par Announce ("global", nil) et AnnounceTo ("whisper", target)
-- APRÈS SK/RK (la garde anti-alts d'OnCD s'appuie sur le SK déjà reçu en face).
function Dir:AnnounceCooldowns(scope, target)
    if not (CraftLink and CraftLink.BuildCD) then return end
    for _, prof in ipairs(CraftLink:MyCooldownProfessions()) do
        for _, msg in ipairs(CraftLink:BuildCD(prof) or {}) do
            CraftLink:Send(msg, scope, target)
        end
    end
end

-- `skill` (optionnel) : la table SK qui juge la vraisemblance des entrées (cf. CooldownPlausible).
-- cdSeen n'en passe pas : il vient d'un craft VU, la preuve que la recette est connue.
local function pruneCdTable(byProf, cutoff, skill)
    if type(byProf) ~= "table" then return nil end
    for prof, set in pairs(byProf) do
        for sid, readyAt in pairs(set) do
            if type(readyAt) ~= "number" or readyAt < cutoff
               or (skill and not Dir:CooldownPlausible(skill, prof, sid)) then
                set[sid] = nil
            end
        end
        if not next(set) then byProf[prof] = nil end
    end
    if not next(byProf) then return nil end
    return byProf
end

-- Entretien (appelé par PruneRoster au démarrage) : purge les readyAt dépassés depuis > 14 j
-- dans les trois magasins (direct, estimé cdSeen, relayé), les CD invraisemblables reçus avant la
-- garde d'OnCD, et les cdStamp orphelins.
function Dir:PruneCooldowns()
    local cutoff = time() - CD_KEEP
    for _, r in pairs(self.roster or {}) do
        r.cooldowns = pruneCdTable(r.cooldowns, cutoff, r.skill)
        r.cdSeen    = pruneCdTable(r.cdSeen, cutoff)
        if r.relayed then r.relayed.cooldowns = pruneCdTable(r.relayed.cooldowns, cutoff, r.relayed.skill) end
        if r.cdStamp then
            for prof in pairs(r.cdStamp) do
                if not (r.cooldowns and r.cooldowns[prof]) then r.cdStamp[prof] = nil end
            end
            if not next(r.cdStamp) then r.cdStamp = nil end
        end
    end
end

-- Câblage réseau — appelé par Dir:Start (Directory.lua) après les handlers RK/SK.
function Dir:StartCooldowns()
    if not CraftLink then return end
    CraftLink:RegisterHandler("CD", function(s, m) Dir:OnCD(s, m) end)
end
