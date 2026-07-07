-- CraftingOrderClassic_LootAlert.lua — alerte quand TU loots un objet-PLAN (recette/formule/
-- schéma/patron) catalogué par CraftLink, MAIS seulement s'il te CONCERNE : soit tu as le métier
-- (candidat à l'apprendre), soit un AMI/PARTENAIRE de ton annuaire ne le connaît pas encore
-- (candidat à un don — cf. request/FEATURE_friend.md). Sinon : silence — un Joaillier/Mineur qui
-- loote un patron de Couture sans ami couturier intéressé n'est PAS notifié. Débloqué par les
-- métadonnées `taughtBy` (P4, CraftLink v6) : sans elles, RecipeFromPlanItem ne résout aucun plan.

local COC = CraftingOrderClassic
local Loot = {}
COC.LootAlert = Loot
local L = COC.L

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end
local function pmsg(m) print("|cFF33DD88Crafting Order|r " .. m) end

-- Convertit un format Blizzard ("Vous recevez le lien de butin : %s.") en pattern Lua, SANS
-- dépendre de la langue du client (les globales LOOT_ITEM_* sont déjà localisées par Blizzard).
-- Ne matche QUE les messages « MOI » (LOOT_ITEM_SELF*) — jamais le loot des autres joueurs du
-- groupe (LOOT_ITEM, sans SELF), qui n'a rien à voir avec MES recettes connues.
local function fmtToPattern(fmt)
    if not fmt or fmt == "" then return nil end
    local s = fmt:gsub("%%s", "\1"):gsub("%%d", "\2")
    s = s:gsub("([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
    s = s:gsub("\1", "(.-)"):gsub("\2", "(%%d+)")
    return "^" .. s .. "$"
end

local SELF_PATTERNS = {}
for _, g in ipairs({ "LOOT_ITEM_SELF", "LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_PUSHED_SELF", "LOOT_ITEM_PUSHED_SELF_MULTIPLE" }) do
    local pat = fmtToPattern(_G[g])
    if pat then SELF_PATTERNS[#SELF_PATTERNS + 1] = pat end
end

-- Extrait le lien d'objet (|Hitem:...|h...|h) d'un message de loot "MOI", ou nil si le message ne
-- matche aucun patron self (loot d'un autre joueur du groupe, argent, etc.).
local function selfLootLink(msg)
    for _, pat in ipairs(SELF_PATTERNS) do
        local link = msg:match(pat)
        if link then return link end
    end
    return nil
end

local seen = {}   -- dédup anti-doublon par session (itemID déjà alerté)

function Loot:IsEnabled() return not (COC.db and COC.db.lootAlertOff) end

function Loot:Cmd(arg)
    arg = (arg or ""):lower()
    if     arg == "off" then COC.db.lootAlertOff = true
    elseif arg == "on"  then COC.db.lootAlertOff = nil end
    pmsg(string.format(L["alerte plan looté : |cFFFFFFFF%s|r — /co lootalert [on|off]"],
        self:IsEnabled() and "on" or "off"))
end

-- Amis (drapeau automatique isFriend, liste d'amis WoW) OU partenaires (drapeau EXPLICITE isPartner
-- — cf. UI:_TogglePartner, menu contextuel joueur) de l'annuaire qui NE connaissent PAS cette recette
-- (bitfield RK reçu et bit absent). Une relation dont on n'a encore aucun RK n'est ni incluse ni
-- exclue — donnée insuffisante pour trancher. Candidats à un don (/co gift).
local function relationsMissing(c, prof, spellID)
    local D = COC.Directory; if not D then return {} end
    local out = {}
    for name, r in pairs(D.roster or {}) do
        if r.isPartner or r.isFriend then
            local hex = r.recipes and r.recipes[prof]
            if hex and not c:HasBit(prof, hex, spellID) then out[#out + 1] = name end
        end
    end
    table.sort(out)
    return out
end

-- Dernier plan looté proposable en don (cf. GiftCmd / « /co gift <nom> ») : { itemLink, itemName,
-- recipeName, prof, missing={nom,...} }. Écrasé à chaque nouveau plan looté (pas d'historique).
Loot.lastGiftable = nil

-- /co gift [nom] : propose (whisper LISIBLE, pas addon-message) le dernier plan looté à un
-- partenaire qui ne le connaît pas encore. Sans argument : liste les candidats en attente.
-- Action VOLONTAIRE déclenchée par le joueur (jamais automatique) — on ne chuchote personne
-- sans que ce soit explicitement demandé.
function Loot:GiftCmd(arg)
    local g = self.lastGiftable
    if not g or #g.missing == 0 then
        pmsg(L["aucun plan looté en attente de don pour l'instant."]); return
    end
    local name = (arg or ""):match("^%s*(.-)%s*$")
    if name == "" then
        pmsg(string.format(L["don en attente pour |cFFFFFFFF%s|r — amis/partenaires : %s (|cFFFFFFFF/co gift <nom>|r)"],
            g.itemName, table.concat(g.missing, ", ")))
        return
    end
    local target
    for _, n in ipairs(g.missing) do if n:lower() == name:lower() then target = n end end
    if not target then
        pmsg(string.format(L["|cFFFFFFFF%s|r n'est pas dans la liste des amis/partenaires en attente pour ce plan."], name))
        return
    end
    SendChatMessage(string.format(L["Salut ! J'ai looté %s (%s) — tu ne le connais pas encore, ça t'intéresse ?"],
        g.itemLink, g.recipeName), "WHISPER", nil, target)
    pmsg(string.format(L["don proposé à |cFFFFFFFF%s|r pour %s."], target, g.itemName))
end

local function onSelfLoot(itemLink)
    local c = CL(); if not c then return end
    local itemID = tonumber(itemLink:match("item:(%d+)"))
    if not itemID or seen[itemID] then return end
    local prof, spellID = c:RecipeFromPlanItem(itemID)
    if not prof then return end   -- pas un objet-plan catalogué

    -- Filtre de PERTINENCE (cf. en-tête) : n'alerte que si ce plan te concerne — soit tu as le métier
    -- (mySkills, lisible sans fenêtre), soit un ami/partenaire de l'annuaire ne le connaît pas encore.
    -- Sinon : silence, et on NE marque PAS `seen` (un RK d'ami reçu plus tard pourra encore déclencher).
    local D = COC.Directory
    local iHaveProf = (D and D.mySkills and D.mySkills[prof]) ~= nil
    local missing = relationsMissing(c, prof, spellID)
    if not iHaveProf and #missing == 0 then return end
    seen[itemID] = true

    local profLbl  = (COC.UI and COC.UI.Skin and COC.UI.Skin.ProfLabel(prof)) or prof
    local itemName = c:ItemName(itemID) or ("item:" .. itemID)
    local recipeNm = c:RecipeName(spellID) or ("spell:" .. spellID)
    -- « tu connais / tu ne connais pas » n'a de sens que si TU as le métier ; pour un plan destiné à
    -- un ami on l'omet (tu n'es pas le crafteur, savoir que tu ne le connais pas est du bruit).
    local status = iHaveProf and (c:IKnowRecipeBySpell(prof, spellID)
        and L["|cFF888888(tu la connais déjà)|r"]
        or  L["|cFF33DD33(tu ne la connais pas encore !)|r"]) or ""

    local msg = string.format(L["plan looté : |cFFFFFFFF%s|r — enseigne |cFFFFFFFF%s|r (%s) %s"],
        itemName, recipeNm, profLbl, status)
    msg = (msg:gsub("%s+$", ""))   -- parenthèses : ne garder que la chaîne (gsub renvoie aussi un compteur)

    Loot.lastGiftable = { itemLink = itemLink, itemName = itemName, recipeName = recipeNm, prof = prof, missing = missing }
    if #missing > 0 then
        msg = msg .. " " .. string.format(L["|cFF66CCFFamis/partenaires intéressés :|r %s (|cFFFFFFFF/co gift <nom>|r)"], table.concat(missing, ", "))
    end

    pmsg(msg)
    if COC.UI and COC.UI.Toast then
        local Skin = COC.UI.Skin
        COC.UI:Toast(msg, Skin and Skin.tex.workorder)
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_LOOT")
f:SetScript("OnEvent", function(_, _, msg)
    local link = selfLootLink(msg)
    if not link then return end
    -- Auto-confirmation d'une commande REÇUE (objet ramassé = la commande est honorée). Indépendant de
    -- l'alerte plan (peut être off). Point de branchement futur pour l'échange et le courrier.
    local itemID = tonumber(link:match("item:(%d+)"))
    if itemID and COC.Orders and COC.Orders.TryAutoComplete then COC.Orders:TryAutoComplete(itemID, "loot") end
    -- Alerte « plan looté » (si activée).
    if Loot:IsEnabled() then onSelfLoot(link) end
end)
