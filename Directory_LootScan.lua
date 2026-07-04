-- Directory_LootScan.lua — découverte PASSIVE des artisans NON-porteurs de l'addon qui craftent à
-- proximité. Deux chemins :
--   1. COMBAT_LOG_EVENT_UNFILTERED / SPELL_CAST_SUCCESS (PRINCIPAL) : le journal de combat voit les
--      casts des joueurs alentour avec le spellID de la recette → identification directe (recettes
--      CraftLink indexées par spellID), indépendante de la LANGUE et du cache objets.
--   2. CHAT_MSG_TRADESKILLS « X creates Y. » (repli) : nom d'objet BRUT (TRADESKILL_LOG_THIRDPERSON,
--      SANS deux-points ni lien) → itemID seulement si l'objet est déjà en cache client.
-- Plancher de skill = RecipeLearnedAt (il sait le faire → skill ≥ niveau d'apprentissage de la recette).
-- OPT-IN : désactivé par défaut, activable par case à cocher (onglet Artisans) ou « /co crafters on » ;
-- n'écoute le journal de combat qu'EN VILLE (IsResting) — voir bloc « Activation » en bas de fichier.
--
-- Estimation stockée À PART : r.craftSeen[prof] = plancher + r.nonAddon = true. JAMAIS dans
-- r.skill/r.recipes (réservés aux vraies données réseau SK/RK, prioritaires). On pingue aussi le crafteur
-- (DiscoverPlayer, throttlé) : s'il a l'addon, ses vraies données remplaceront l'estimation.
-- Méthodes sur COC.Directory (créé par Directory.lua, chargé avant dans le .toc).

local COC = CraftingOrderClassic
local Dir = COC.Directory

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

-- Maps inverses depuis les catalogues CraftLink : bySpell[spellID]=prof (chemin CLEU) ;
-- byItem[itemID]={prof,spellID} (chemin chat). Construites une fois.
local byItem, bySpell
local function ensureReverse()
    if byItem then return byItem, bySpell end
    local c = CL(); if not c then return nil end          -- lib pas prête → réessai au prochain event
    byItem, bySpell = {}, {}
    for _, prof in ipairs(c:Professions()) do
        for _, e in ipairs(c:ProfessionCatalogue(prof)) do
            if e.spellID then
                if not bySpell[e.spellID] then bySpell[e.spellID] = prof end
                if e.itemID and not byItem[e.itemID] then byItem[e.itemID] = { prof = prof, spellID = e.spellID } end
            end
        end
    end
    return byItem, bySpell
end

-- Cœur : `who` (joueur ≠ moi) a crafté une recette de `prof` (spellID → plancher learnedAt).
function Dir:_NoteSeen(who, prof, spellID)
    who = who and (who:match("^([^%-]+)") or who)
    if not (who and who ~= "" and prof) then return end
    if COC.SECONDARY_PROF and COC.SECONDARY_PROF[prof] then return end   -- Cuisine/Secours/Pêche : pas de commande
    if who == (UnitName and UnitName("player")) then return end
    self.roster = self.roster or {}
    local r = self.roster[who]; if not r then r = {}; self.roster[who] = r end
    if (r.skill and r.skill[prof]) or (r.recipes and r.recipes[prof]) then return end   -- vraies données prioritaires
    local c = CL(); local floor = (c and spellID and c:RecipeLearnedAt(prof, spellID)) or 0
    r.craftSeen = r.craftSeen or {}
    if floor > (r.craftSeen[prof] or 0) then r.craftSeen[prof] = floor end
    if not (r.skill or r.recipes) then r.nonAddon = true end
    r.lastSeen = time and time() or 0
    self:_ApplySource(who, r)          -- guilde/ami si relation, sinon « recent » (Annuaire)
    self:DiscoverPlayer(who)           -- s'il a l'addon → vraies données (ping throttlé 60 s, invisible sinon)
    if COC.UI and COC.UI.artisansPanel and COC.UI.artisansPanel:IsShown() and COC.UI.RefreshArtisans then
        COC.UI:RefreshArtisans()
    end
end

-- Repli chat : `item` = itemID, lien, ou nom brut (résolu seulement si l'objet est en cache client).
function Dir:NoteCraftSeen(who, item)
    if not (who and item) then return end
    local itemID = tonumber(item)
    if not itemID and GetItemInfoInstant then itemID = select(1, GetItemInfoInstant(item)) end
    local bi = itemID and ensureReverse(); local hit = bi and bi[itemID]
    if hit then self:_NoteSeen(who, hit.prof, hit.spellID) end
end

-- Motif Lua depuis une globale localisée : échappe les magic chars, %s -> capture.
local function toPattern(fmt)
    if not fmt then return nil end
    local p = fmt:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    return (p:gsub("%%%%s", "(.+)"):gsub("%%%%d", "%%d+"))
end

local patterns
local function ensurePatterns()
    if patterns then return patterns end
    patterns = {}
    local seen = {}
    local function add(fmt) local p = toPattern(fmt); if p and not seen[p] then seen[p] = true; patterns[#patterns + 1] = p end end
    add(_G["TRADESKILL_LOG_THIRDPERSON"])   -- « %s creates %s. » (confirmé PTR : sans deux-points ni lien)
    add(_G["CREATED_ITEM"])                 -- variante butin « %s creates: %s. »
    add(_G["CREATED_ITEM_MULTIPLE"])
    return patterns
end

local function onChat(msg)
    if not msg then return end
    for _, pat in ipairs(ensurePatterns()) do
        local a, b = msg:match(pat)
        if a and b then
            local link = (a:find("item:", 1, true) and a) or (b:find("item:", 1, true) and b)
            local who  = (link == a) and b or a
            Dir:NoteCraftSeen(who, link and tonumber(link:match("item:(%d+)")) or b)
            return
        end
    end
end

-- Chemin principal : SPELL_CAST_SUCCESS d'un JOUEUR alentour dont le spellID est une recette connue.
local function onCLEU()
    local _, sub, _, srcGUID, srcName, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
    if sub ~= "SPELL_CAST_SUCCESS" or not (srcGUID and srcGUID:find("^Player")) then return end
    local _, bs = ensureReverse(); local prof = bs and spellID and bs[spellID]
    if prof then Dir:_NoteSeen(srcName, prof, spellID) end
end

-- ------------------------------------------------------------------
-- Activation : CONFIGURABLE (défaut OFF) + limitée à la VILLE. Le journal de combat fire en rafale
-- pour tous les joueurs alentour → on ne l'écoute QUE si (a) l'utilisateur l'a activée (case à cocher
-- de l'onglet Artisans / « /co crafters on ») ET (b) on est en zone de repos (IsResting = auberge ou
-- ville, là où l'on croise les crafteurs) — jamais en plein combat ni en pleine nature, pour ne pas
-- cramer de CPU inutilement. CHAT_MSG_TRADESKILLS (repli) suit la même règle.
-- ------------------------------------------------------------------
local scanFrame = CreateFrame("Frame")
local registered = false

local function shouldScan()
    return (COC.db and COC.db.crafterScan) and IsResting and IsResting() and true or false
end

local function applyReg()
    local want = shouldScan()
    if want == registered then return end
    registered = want
    if want then
        scanFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        scanFrame:RegisterEvent("CHAT_MSG_TRADESKILLS")
    else
        scanFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        scanFrame:UnregisterEvent("CHAT_MSG_TRADESKILLS")
    end
end

scanFrame:RegisterEvent("PLAYER_ENTERING_WORLD")    -- changement de zone → réévalue « suis-je en ville ? »
scanFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
scanFrame:SetScript("OnEvent", function(_, event, msg)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then onCLEU()
    elseif event == "CHAT_MSG_TRADESKILLS" then onChat(msg)
    else applyReg() end                             -- PLAYER_ENTERING_WORLD / PLAYER_UPDATE_RESTING
end)

-- Toggle runtime (case à cocher onglet Artisans / /co crafters). Persistant : COC.db.crafterScan.
function Dir:SetCrafterScan(on)
    if COC.db then COC.db.crafterScan = on and true or nil end
    applyReg()
end

function Dir:CrafterScanEnabled() return (COC.db and COC.db.crafterScan) and true or false end
