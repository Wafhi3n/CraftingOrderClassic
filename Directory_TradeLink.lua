-- Directory_TradeLink.lua — un lien de métier posté dans le chat ajoute son AUTEUR à l'annuaire, et
-- l'annuaire ne garde que les artisans sans l'addon UTILES (spec docs/specs/lien-metier.md).
--
-- Le lien sur Forever (mesuré le 2026-09-27, docs/test-lien-metier.md) :
--   |Htrade:<GUID du propriétaire>:<sort de rang>:<ligne de métier>|h[Enchanting]|h
-- Ni niveau ni recettes : le serveur ne les envoie qu'au CLIC. Le métier entre avec le plancher 0,
-- et le sort de rang, gardé brut (linkSpell), donne une TRANCHE à la lecture (D14).
-- Rien n'est envoyé à l'auteur (D7) : ni DiscoverPlayer, ni réponse. La lecture du chat elle-même
-- vit dans CraftingOrderClassic_LFWChat.lua, la purge dans Directory_Seen.lua ; ici, le décodage,
-- la fiche, la tranche, et (phase 2) la vue liée qu'ouvre MON clic sur son lien : ses recettes et
-- son niveau, rangés dans SA fiche.
-- Méthodes sur COC.Directory (créé par Directory.lua, chargé avant dans le .toc).

local COC = CraftingOrderClassic
local Dir = COC.Directory

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

-- Vraies données réseau (SK, RK, RI) : elles priment toujours sur ce qu'un lien dit.
-- Définis par Directory_Seen.lua, chargé avant (.toc), avec la purge qui les partage.
local hasNetData, isCarrier = Dir._HasNetData, Dir._IsCarrier

-- Lignes de métier du client : mêmes identifiants de Vanilla à Retail (333 et 185 mesurés sur
-- Camelot). Repli quand le libellé du lien ne se résout pas (langue sans alias dans CraftLink).
local SKILL_LINE = {
    [171] = "Alchemy", [164] = "Blacksmithing", [333] = "Enchanting", [202] = "Engineering",
    [165] = "Leatherworking", [197] = "Tailoring", [186] = "Mining", [185] = "Cooking",
    [129] = "First Aid", [356] = "Fishing", [755] = "Jewelcrafting", [773] = "Inscription",
}

-- Libellé d'abord (le résolveur d'alias FR/DE/ES déjà éprouvé), ligne de métier ensuite. Une clé
-- que CraftLink ne connaît pas ne vaut rien : ResolveProfession rend le mot brut quand il échoue.
local function resolveProf(c, label, line)
    if not c then return nil end
    local key = label ~= "" and c:ResolveProfession(label)
    if key and c:GetProfession(key) then return key end
    key = SKILL_LINE[line]
    if key and c:GetProfession(key) then return key end
    return nil
end

-- Métiers que l'auteur a LUI-MÊME liés dans `text` : liste de { prof, spell }, vide sinon. Pur.
-- `guid` = GUID de l'émetteur (12e argument de l'événement de chat) : le jeu authentifie l'émetteur,
-- pas ce dont il parle, donc le lien d'un autre (« demande à X [Enchantement] ») est ignoré (D3).
-- Secondaires écartés (D2). L'appelant a déjà écarté les valeurs SECRÈTES : on n'en teste aucune ici.
function Dir.ParseTradeLinks(text, guid)
    local out = {}
    if type(text) ~= "string" or type(guid) ~= "string" or guid == "" then return out end
    if not text:find("|Htrade:", 1, true) then return out end
    local c, seen = CL(), {}
    local SEC = COC.SECONDARY_PROF or {}
    for owner, spell, line, label in text:gmatch("|Htrade:([^:|]+):(%d+):(%d+)[^|]*|h%[([^%]]*)%]|h") do
        if owner == guid then
            local key = resolveProf(c, label, tonumber(line))
            if key and not SEC[key] and not seen[key] then
                seen[key] = true
                out[#out + 1] = { prof = key, spell = tonumber(spell) }
            end
        end
    end
    return out
end

-- `name` (nom réseau, authentifié par le jeu) a lié son métier `prof`. Display-only, comme une ligne
-- LFW lue dans le chat : fiche « connu sans l'addon », et ses vraies données, s'il a l'addon,
-- restent prioritaires (on n'écrit jamais dans r.skill / r.recipes, ni ne baisse un plancher).
function Dir:NoteLinkSeen(name, prof, spell)
    if not (name and prof) or name == COC.Api.PlayerName() then return end
    self.roster = self.roster or {}
    local r = self.roster[name]; if not r then r = {}; self.roster[name] = r end
    if self._ApplySource then self:_ApplySource(name, r) end
    r.faction = self._MyFaction and self:_MyFaction() or r.faction
    local t = time()
    r.lastSeen = t
    r.linkSeen = r.linkSeen or {};   r.linkSeen[prof] = t
    r.linkSpell = r.linkSpell or {}; r.linkSpell[prof] = spell
    if not hasNetData(r, prof) then
        r.craftSeen = r.craftSeen or {}
        if r.craftSeen[prof] == nil then r.craftSeen[prof] = 0 end   -- 0 = connu sans l'addon, niveau inconnu
    end
    if not isCarrier(r) then r.nonAddon = true end
    self:CapSeen(prof)
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
end

-- ------------------------------------------------------------------
-- Tranche d'un lien (D14) : le lien porte le sort de RANG du métier, pas le niveau. Identifiants
-- Vanilla ; trois mesurés sur Camelot le 2026-10-02 (7412 Enchantement Compagnon vu à 102/150,
-- 2550 Cuisine Apprenti, 2018 Forge Apprenti vu à 1/75). Un sort absent = tranche INCONNUE, jamais
-- devinée. La tranche se déduit à la lecture : jamais copiée dans le plancher craftSeen (D11).
-- ------------------------------------------------------------------
local TIERS = { { 1, 75 }, { 50, 150 }, { 125, 225 }, { 200, 300 } }   -- niveau requis, plafond
local RANK_SPELLS = {
    [2259] = 1, [3101] = 2, [3464] = 3, [11611] = 4,   -- Alchimie
    [2018] = 1, [3100] = 2, [3538] = 3, [9785]  = 4,   -- Forge
    [7411] = 1, [7412] = 2, [7413] = 3, [13920] = 4,   -- Enchantement
    [4036] = 1, [4037] = 2, [4038] = 3, [12656] = 4,   -- Ingénierie
    [2108] = 1, [3104] = 2, [3811] = 3, [10662] = 4,   -- Travail du cuir
    [3908] = 1, [3909] = 2, [3910] = 3, [12180] = 4,   -- Couture
    [2575] = 1, [2576] = 2, [3564] = 3, [10248] = 4,   -- Minage
}

-- Sort de rang → (niveau requis pour la tranche, plafond de la tranche), ou nil.
function Dir.LinkTier(spell)
    local t = spell and RANK_SPELLS[spell]
    if not t then return nil end
    return TIERS[t][1], TIERS[t][2]
end

-- ------------------------------------------------------------------
-- Phase 2 : quand JE clique le lien d'un autre, le jeu m'envoie sa liste et son niveau. Ils vont
-- dans SA fiche, à part (linkRecipes) : jamais dans mes recettes (CraftLink les garde,
-- IsOwnProfessionOpen), jamais dans r.recipes, et RecipeTester n'en voit rien — aucune commande
-- ne vise quelqu'un qui ne peut pas la recevoir (D10).
-- ------------------------------------------------------------------
local LINK_MAX_IDS = 400   -- borne de la SavedVariable, par métier
local LV_QUIET = 1         -- s sans nouvel événement de la fenêtre avant de lire (D12)
Dir._linkView = { key = nil, fresh = false, gen = 0 }

-- Propriétaire (nom réseau, sans -Royaume, comme la lecture du chat) et métier de la vue liée
-- ouverte ; nil pour ma vue, celle de la guilde ou d'un PNJ, ou un métier illisible.
local function linkedViewKey()
    local T = C_TradeSkillUI
    if not (T and T.IsTradeSkillLinked) then return nil end
    local ok, linked, owner = pcall(T.IsTradeSkillLinked)
    if not (ok and linked) or COC.Api.IsSecret(owner) or type(owner) ~= "string" or owner == "" then return nil end
    owner = owner:match("^([^%-]+)") or owner
    local c = CL()
    local prof = c and c.OpenProfession and c:OpenProfession()   -- nom lu dans la FENÊTRE, vide = nil
    if not (prof and c:GetProfession(prof)) then return nil end
    return owner, prof
end

local catCache = {}
local function catalogueSet(c, prof)
    local set = catCache[prof]
    if set then return set end
    set = {}
    for _, e in ipairs(c:ProfessionCatalogue(prof)) do if e.spellID then set[e.spellID] = true end end
    catCache[prof] = set
    return set
end

-- Recettes APPRISES de la vue ouverte (`learned == true` exigé), et combien sont au catalogue de `prof`.
local function readLearned(c, prof)
    local T = C_TradeSkillUI
    local enum = T.GetAllRecipeIDs or T.GetFilteredRecipeIDs   -- la 1re ignore les filtres de la fenêtre
    if not (enum and T.GetRecipeInfo) then return nil end
    local ok, list = pcall(enum)
    if not (ok and type(list) == "table") then return nil end
    local cat, ids, inCat = catalogueSet(c, prof), {}, 0
    for _, id in ipairs(list) do
        local ok2, info = pcall(T.GetRecipeInfo, id)
        if ok2 and type(info) == "table" and info.learned == true then
            ids[#ids + 1] = id
            if cat[id] then inCat = inCat + 1 end
            if #ids >= LINK_MAX_IDS then break end
        end
    end
    return ids, inCat
end

-- Niveau affiché par la fenêtre (même source que la barre de Blizzard, Professions.GetProfessionInfo).
local function readLevel()
    local T, info = C_TradeSkillUI, nil
    if T.GetChildProfessionInfo then local ok, i = pcall(T.GetChildProfessionInfo); if ok then info = i end end
    if not (type(info) == "table" and (info.professionID or 0) ~= 0) and T.GetBaseProfessionInfo then
        local ok, i = pcall(T.GetBaseProfessionInfo); info = ok and i or nil
    end
    local lvl = type(info) == "table" and tonumber(info.skillLevel)
    if lvl and lvl > 0 then return lvl, tonumber(info.maxSkillLevel) end
    return nil
end

-- Un événement de la fenêtre de métier (D12). Changement de propriétaire ou de métier : le client
-- sert encore un moment l'ANCIENNE liste sous le nouveau nom, donc on attend une mise à jour de la
-- liste survenue APRÈS le changement ; puis on lit au calme (LV_QUIET sans nouvel événement).
function Dir:_OnTradeSkillEvent(event)
    local view = self._linkView
    local owner, prof = linkedViewKey()
    local key = owner and (owner .. "\1" .. prof) or nil
    if key ~= view.key then view.key, view.fresh = key, false
    elseif event == "TRADE_SKILL_LIST_UPDATE" then view.fresh = true end
    if not (key and view.fresh) then return end
    view.gen = view.gen + 1
    local gen = view.gen
    local function run() if view.gen == gen then Dir:CaptureLinkedView() end end
    if C_Timer and C_Timer.After then C_Timer.After(LV_QUIET, run) else run() end
end

-- Lit la vue liée, si elle est toujours celle qu'on suit et que sa liste est arrivée. Rend true si
-- une fiche a été écrite.
function Dir:CaptureLinkedView()
    local view = self._linkView
    local owner, prof = linkedViewKey()
    if not (owner and view.fresh and (owner .. "\1" .. prof) == view.key) then return false end
    if owner == COC.Api.PlayerName() or (COC.SECONDARY_PROF and COC.SECONDARY_PROF[prof]) then return false end
    local ids, inCat = readLearned(CL(), prof)
    if not ids or #ids == 0 or inCat * 2 < #ids then return false end   -- vide, ou liste d'un autre métier
    self:NoteLinkedView(owner, prof, ids, readLevel())
    return true
end

-- Range ce qu'on a lu dans SA fiche. Chaque lecture REMPLACE la précédente (jamais d'union, qui
-- garderait une mauvaise lecture pour toujours). Le niveau aussi : il vit dans linkRecipes, pas
-- dans le plancher craftSeen qui ne redescend jamais — une lecture périmée (mon niveau servi le
-- temps que la liste de l'autre arrive) s'y collerait pour de bon (D11).
function Dir:NoteLinkedView(owner, prof, ids, lvl, maxLvl)
    self.roster = self.roster or {}
    local r = self.roster[owner]; if not r then r = {}; self.roster[owner] = r end
    if self._ApplySource then self:_ApplySource(owner, r) end
    r.faction = self._MyFaction and self:_MyFaction() or r.faction
    local t = time()
    r.lastSeen = t
    r.linkSeen = r.linkSeen or {}; r.linkSeen[prof] = t
    if not hasNetData(r, prof) then
        r.linkRecipes = r.linkRecipes or {}
        r.linkRecipes[prof] = { ids = ids, at = t, lvl = lvl, max = maxLvl }
        r.craftSeen = r.craftSeen or {}
        if r.craftSeen[prof] == nil then r.craftSeen[prof] = 0 end   -- le métier compte et s'affiche
    end
    if not isCarrier(r) then r.nonAddon = true end
    self:CapSeen(prof)
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
end

if CreateFrame and COC.Api and COC.Api.RegisterEventsSafe then
    local f = CreateFrame("Frame")
    COC.Api.RegisterEventsSafe(f, { "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_DATA_SOURCE_CHANGED" })
    f:SetScript("OnEvent", function(_, event) Dir:_OnTradeSkillEvent(event) end)
end
