-- CraftingOrderClassic_Trainers.lua — « le formateur, vu de nos propres yeux ».
--
-- POURQUOI CE MODULE EXISTE. « Formateur » est la seule nature de source que PERSONNE ne publie :
-- aucune page Wowhead ne l'affirme, et notre catalogue ne la DÉDUIT que d'une absence (aucun
-- objet-recette connu). Or une absence a deux causes indiscernables — la recette s'apprend bien au
-- formateur, ou la source n'est pas encore connue de la source de données. D'où le « ? » affiché
-- partout, et l'aveu d'impuissance qu'il représente : 788 des 2512 recettes du set Camelot.
--
-- Une source, pourtant, le sait sans hésiter : LE FORMATEUR LUI-MÊME. Quand le joueur lui parle, le
-- client énumère tout ce qu'il enseigne — rangs supérieurs compris, dans la langue du joueur. C'est
-- un FAIT, daté, observé sur le serveur où l'on joue, et il vaut mieux que n'importe quel annuaire.
--
-- CE QU'ON MOISSONNE, ET RIEN DE PLUS : le PNJ (nom, carte, position du joueur pendant qu'il lui
-- parle) et la liste de ce qu'il enseigne. Aucun achat, aucun clic, aucune modification de ses
-- filtres d'affichage — on lit ce qui est là, on note, on se tait.
--
-- ⚠️ ON NE VOIT QUE CE QUE LE JOUEUR A VISITÉ. Cette table est donc TOUJOURS partielle, et tout le
-- reste doit continuer à marcher sans elle : l'observation ENRICHIT la déduction, elle ne la
-- remplace pas. Tant qu'aucun formateur n'a été vu, rien ne change nulle part.

local COC = CraftingOrderClassic
local T   = {}
COC.Trainers = T

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

-- ------------------------------------------------------------------
-- Persistance
-- ------------------------------------------------------------------

-- db.trainers[profKey] = { npc = { id, name, mapID, x, y, at }, teaches = { [spellID] = true } }
--
-- UN SEUL PNJ retenu par métier, le DERNIER VU. La question à laquelle on répond est « où
-- j'apprends ça », pas « donne-moi l'annuaire complet des formateurs » ; et le dernier vu est le
-- plus proche de là où le joueur passe son temps, donc le meilleur conseil qu'on puisse donner.
-- `teaches`, lui, s'ACCUMULE : deux formateurs d'un même métier n'enseignent pas forcément la même
-- chose, et oublier la visite précédente ferait clignoter les sources d'une ville à l'autre.
local function store(profKey, create)
    local db = COC.db
    if not (db and profKey) then return nil end
    if create then
        db.trainers = db.trainers or {}
        db.trainers[profKey] = db.trainers[profKey] or { teaches = {} }
    end
    return db.trainers and db.trainers[profKey] or nil
end

-- ------------------------------------------------------------------
-- Jonction service -> recette
-- ------------------------------------------------------------------

-- Nom LOCALISÉ -> { profKey, spellID }, sur tout le catalogue.
--
-- Le formateur n'annonce que des NOMS : aucune API ne donne le sort d'un service (`GetTrainerServiceInfo`
-- rend un libellé, un type et une icône, jamais un identifiant). Le nom est donc notre seul point de
-- jonction — et il tient, parce qu'il vient du CLIENT des deux côtés : `GetSpellName` ici, le service
-- là-bas. Un nom stocké en anglais n'aurait matché que sur un client anglais.
--
-- Construit UNE fois, à la première visite d'un formateur : quelques milliers d'appels C payés une
-- seule fois dans la session, et jamais au login.
local byName
local function nameIndex()
    if byName then return byName end
    byName = {}
    local lib = CL()
    for _, prof in ipairs((lib and lib.Professions and lib:Professions()) or {}) do
        for _, sid in ipairs((lib.GetRecipes and lib:GetRecipes(prof)) or {}) do
            local nm = COC.Api and COC.Api.GetSpellName and COC.Api.GetSpellName(sid)
            -- Premier arrivé, premier servi : deux métiers peuvent produire le même nom (Fonte,
            -- Prospection), et le vote par métier ci-dessous rattrape le mauvais aiguillage.
            if nm and nm ~= "" and not byName[nm] then byName[nm] = { prof, sid } end
        end
    end
    return byName
end

-- ------------------------------------------------------------------
-- La moisson
-- ------------------------------------------------------------------

-- Les services affichés, en paires { profKey, spellID }. Les en-têtes de catégorie sont des lignes
-- comme les autres dans cette API (`serviceType == "header"`) : les compter ferait entrer des noms
-- de rubrique dans le catalogue.
local function readServices()
    local out = {}
    local num  = _G.GetNumTrainerServices and _G.GetNumTrainerServices() or 0
    local info = _G.GetTrainerServiceInfo
    if not info or num == 0 then return out end
    local idx = nameIndex()
    for i = 1, num do
        local ok, name, sType = pcall(info, i)
        if ok and name and sType ~= "header" then
            local hit = idx[name]
            if hit then out[#out + 1] = hit end
        end
    end
    return out
end

-- Le métier du formateur : celui que DÉSIGNENT le plus de ses services. On ne le demande pas au
-- client — `GetTrainerServiceSkillLine` existe mais n'est documentée nulle part et ne répond pas la
-- même chose chez un formateur de classe. Compter est robuste et se raconte : un formateur de
-- Cuisine enseigne des recettes de Cuisine, et deux homonymes ne renversent pas un vote.
local function winningProf(list)
    local tally, best, bestN = {}, nil, 0
    for _, p in ipairs(list) do
        tally[p[1]] = (tally[p[1]] or 0) + 1
        if tally[p[1]] > bestN then best, bestN = p[1], tally[p[1]] end
    end
    return best, bestN
end

-- Où se tient le joueur, en 0-100 — le format qu'attend le poseur de repère de la fiche d'info.
local function herePosition()
    local map = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if not map then return nil end
    local pos = C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(map, "player")
    if not (pos and pos.x) then return map end
    return map, pos.x * 100, pos.y * 100
end

-- Identifiant de créature du PNJ en face. Le GUID est la seule voie : `UnitName` rend un nom
-- localisé, qui ne fait pas une clé.
local function npcIdentity()
    -- Un nom secret PERSISTERAIT dans la SavedVariable : on préfère un formateur sans nom à une
    -- base empoisonnée, que plus rien ne pourrait relire (cf. Api.UnitNameSafe).
    local name = COC.Api.UnitNameSafe("npc")
    local guid = UnitGUID and UnitGUID("npc")
    local id   = guid and tonumber(guid:match("Creature%-0%-%d+%-%d+%-%d+%-(%d+)")) or nil
    return id, name
end

-- Appelé sur TRAINER_SHOW. Ne fait rien chez un formateur de classe, rien si aucun service ne
-- correspond au catalogue, rien si la base n'est pas encore montée (login en cours).
function T:Harvest()
    if not COC.db then return nil end
    if _G.IsTradeskillTrainer and not _G.IsTradeskillTrainer() then return nil end
    local list = readServices()
    local prof, n = winningProf(list)
    if not prof then return nil end
    local st = store(prof, true)
    for _, p in ipairs(list) do
        if p[1] == prof then st.teaches[p[2]] = true end
    end
    local id, name = npcIdentity()
    if name then
        local map, x, y = herePosition()
        st.npc = { id = id, name = name, mapID = map, x = x, y = y, at = time() }
    end
    if COC.Trace then COC.Trace:Log("trainer", (name or "?") .. " / " .. prof .. " : " .. n .. " services") end
    return prof, n
end

-- ------------------------------------------------------------------
-- Lecture
-- ------------------------------------------------------------------

-- Ce métier a-t-il un formateur qui enseigne CETTE recette ? true = FAIT observé. false ne veut PAS
-- dire « non » : il veut dire « jamais vu », qui est l'état de départ de tout le monde. Les
-- appelants doivent le traiter comme une absence de réponse, jamais comme une négation.
function T:Teaches(profKey, spellID)
    local st = store(profKey)
    return (st and st.teaches and st.teaches[spellID]) == true
end

-- Le PNJ à qui aller parler, tel qu'on l'a rencontré : { name, mapID, x, y, zone }, ou nil tant
-- qu'on n'en a vu aucun pour ce métier. La ZONE est résolue ici, par le client, donc localisée : on
-- n'en stocke jamais le nom (même discipline que le catalogue).
function T:Npc(profKey)
    local st  = store(profKey)
    local npc = st and st.npc
    if not (npc and npc.name) then return nil end
    local info = npc.mapID and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(npc.mapID)
    return { name = npc.name, mapID = npc.mapID, x = npc.x, y = npc.y,
             zone = info and info.name or nil }
end

-- « Nom — Zone (x, y) » du formateur connu, ou nil. Les coordonnées ne s'affichent que si on les a :
-- une position inventée vaut moins qu'une position absente.
function T:Line(profKey)
    local npc = self:Npc(profKey)
    if not npc then return nil end
    local s = npc.zone and (npc.name .. " — " .. npc.zone) or npc.name
    if npc.x and npc.y then s = s .. string.format(" (%.0f, %.0f)", npc.x, npc.y) end
    return s, npc
end

-- Sortie de DIAGNOSTIC (`/co trainers`), non localisée comme les autres dumps. Elle répond à la
-- seule question qu'on se pose en jeu après une visite — « est-ce que la moisson a pris ? » — sans
-- avoir à la deviner depuis une infobulle dont on ne sait pas si elle a changé.
function T:Dump()
    local db = COC.db and COC.db.trainers
    if not (db and next(db)) then
        print("|cFF33DD88COC|r trainers: rien de moissonne (parle a un formateur de METIER)")
        return
    end
    for prof, st in pairs(db) do
        local n = 0
        for _ in pairs(st.teaches or {}) do n = n + 1 end
        print(string.format("|cFF33DD88COC|r %s : %d recette(s) confirmee(s) -- %s",
            prof, n, self:Line(prof) or "PNJ inconnu"))
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("TRAINER_SHOW")
f:SetScript("OnEvent", function() T:Harvest() end)
