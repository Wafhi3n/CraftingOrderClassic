-- CraftingOrderClassic_Enchant.lua — spécifique à l'Enchantement (API Craft).
-- Résout l'EMPLACEMENT équipé ciblé par un enchant (pour le bouton « Enchanter équipé » qui applique
-- l'enchant DIRECTEMENT sur la pièce portée via l'attribut sécurisé `target-slot` — cf. SecureTemplates
-- OnActionButtonClick : après le DoCraft, si SpellCanTargetItem(), UseInventoryItem(target-slot)).
-- Parse le nom ANGLAIS canonique du catalogue CraftLink (« Enchant <Slot> - <Effet> ») → slot + effet,
-- indépendamment de la langue du client. Sert AUSSI au classement de la liste de recettes :
-- Emplacement (section) › Stat de base (sous-catégorie) › variantes triées par niveau.
-- API publique : Enchant:Parse · Enchant:SlotFor · Enchant:SectionFor · Enchant:StatFor · Enchant:ShortName.

local COC     = CraftingOrderClassic
local Enchant = {}
COC.Enchant   = Enchant
local L       = COC.L

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

-- Mot d'emplacement (anglais, tel qu'écrit dans « Enchant <Slot> - <Effet> ») → emplacement d'inventaire
-- (résolu en id par GetInventorySlotInfo). Enchant d'arme → main droite par défaut ; bouclier → main gauche.
local SLOT_NAME = {
    ["Bracer"]    = "WristSlot",   ["Boots"]  = "FeetSlot",  ["Chest"]    = "ChestSlot",
    ["Cloak"]     = "BackSlot",    ["Gloves"] = "HandsSlot", ["Shield"]   = "SecondaryHandSlot",
    ["Weapon"]    = "MainHandSlot", ["2H Weapon"] = "MainHandSlot", ["Off-Hand"] = "SecondaryHandSlot",
    ["Ring"]      = "Finger0Slot", ["Shoulder"] = "ShoulderSlot", ["Head"] = "HeadSlot",
}

-- Mot d'emplacement → token INVTYPE. Le LIBELLÉ vient de `_G[token]` : globale du client, DÉJÀ
-- localisée (même source que COC.SectionOf pour l'armure) → aucune clé de locale à maintenir. Le rang
-- d'ARMURE est LU dans COC.SLOT_ORDER (table canonique de _UI_Post_Categories, chargée avant nous) :
-- une seule source de vérité, plus de copie à resynchroniser à l'œil. Les armes passent après (rangs
-- fixes 20/21 — elles n'ont pas d'emplacement d'armure).
local SLOT_INVTYPE = {
    ["Head"]   = "INVTYPE_HEAD",  ["Shoulder"] = "INVTYPE_SHOULDER",
    ["Cloak"]  = "INVTYPE_CLOAK", ["Chest"]    = "INVTYPE_CHEST",
    ["Bracer"] = "INVTYPE_WRIST", ["Gloves"]   = "INVTYPE_HAND",
    ["Boots"]  = "INVTYPE_FEET",  ["Ring"]     = "INVTYPE_FINGER",
    ["Shield"] = "INVTYPE_SHIELD", ["Off-Hand"] = "INVTYPE_HOLDABLE",
}
local WEAPON_SECTION = { ["Weapon"] = { "INVTYPE_WEAPON", 20 }, ["2H Weapon"] = { "INVTYPE_2HWEAPON", 21 } }

-- { token, rang } d'un mot d'emplacement — construit UNE fois, paresseusement (COC.SLOT_ORDER est
-- posé par _UI_Post_Categories au chargement ; lazy = insensible à l'ordre exact du .toc).
local SLOT_SECTION
local function slotSection(w)
    if not SLOT_SECTION then
        SLOT_SECTION = {}
        local ord = COC.SLOT_ORDER or {}
        for word, token in pairs(SLOT_INVTYPE) do SLOT_SECTION[word] = { token, ord[token] or 50 } end
        for word, s in pairs(WEAPON_SECTION) do SLOT_SECTION[word] = s end
    end
    return SLOT_SECTION[w]
end

-- Parse « Enchant <Slot> - <Effet> » (anglais) → slotWord, effect (nil, nil si la forme ne colle pas —
-- ex. huiles/baguettes, qui n'ont pas de séparateur).
-- ⚠️ Le séparateur est « espace TIRET espace » : un `%-` nu couperait DANS un mot d'emplacement qui
-- contient un tiret (« Enchant Off-Hand - Wisdom » → slot « Off », effet « Hand - Wisdom »).
function Enchant:Parse(name)
    if type(name) ~= "string" then return nil end
    return name:match("^%s*[Ee]nchant%s+(.-)%s+%-%s+(.-)%s*$")
end

-- Qualificatifs de PUISSANCE (anglais) : « Major Spirit » et « Lesser Spirit » sont deux variantes de la
-- MÊME stat de base (Spirit). On les retire pour obtenir le regroupement voulu.
local MAGNITUDE = {
    Minor = true, Lesser = true, Greater = true, Major = true,
    Superior = true, Mighty = true, Advanced = true,
    -- SoD : « Excellent Spirit », « Grand Crusader » (qui rejoint ainsi le « Crusader » de Vanilla).
    Excellent = true, Grand = true,
}

-- Blizzard nomme parfois la MÊME stat de deux façons : « Minor Deflect » vs « Lesser Deflection »
-- (Vanilla), « Greater Spellpower » vs « Spell Power » (SoD). Alias de normalisation pour qu'elles
-- tombent dans le même groupe. Ce sont les SEULES anomalies relevées (Vanilla vérifié exhaustivement
-- 2026-07-15, SoD 2026-07-16) — attention : Fire/Frost/Nature/Shadow Resistance sont des stats
-- DISTINCTES de « Resistance » générique, elles doivent rester séparées (ne pas « corriger »).
local STAT_ALIAS = { Deflect = "Deflection", Spellpower = "Spell Power" }

-- Effet (anglais) → stat de BASE : « Major Spirit » → « Spirit » ; « Crusader » → « Crusader ».
local function baseStat(effect)
    if not effect or effect == "" then return nil end
    local first, rest = effect:match("^(%S+)%s+(.+)$")
    local b = (first and MAGNITUDE[first]) and rest or effect
    return STAT_ALIAS[b] or b
end

-- Maps dérivées UNE fois du catalogue CraftLink (noms anglais canoniques → indépendant de la langue du
-- client) : spellID → mot d'emplacement, spellID → stat de base, stat de base → rang (alphabétique, pour
-- que les sous-catégories soient ordonnées de façon stable — le moteur trie sur un NOMBRE).
-- Les huiles/baguettes n'y figurent pas → nil partout (elles gardent le classement par objet produit).
local _wordBySpell, _statBySpell, _statOrder
local function buildMaps()
    _wordBySpell, _statBySpell, _statOrder = {}, {}, {}
    local c = CL()
    local def = c and c.GetProfession and c:GetProfession("Enchanting")
    if not def then return end
    local named, seen = {}, {}
    -- 1) Noms ANGLAIS canoniques du catalogue : la source ROBUSTE (indépendante de la langue du client).
    --    Vanilla (gen_professions.lua) ET, depuis lib v10, TBC/Wrath/SoD (gen_enchant_names.lua —
    --    ExtendProfession fusionne la table `enchants` des couches).
    for _, en in ipairs(def.enchants or {}) do
        if en.id and en.name then named[en.id] = en.name end
    end
    -- 2) REPLI de sécurité : un spellID encore sans nom canonique (trou de génération, future couche)
    --    est lu au nom RUNTIME. ⚠️ Ce nom est LOCALISÉ : hors client anglais, ces recettes-là
    --    retombent en « Autres/Divers » (c'était le sort de TOUS les enchants TBC/SoD avant v10 —
    --    vu en jeu 2026-07-16 : 21 enchants SoD en vrac sur client FR).
    for _, id in ipairs(def.recipes or {}) do
        if not named[id] and c.RecipeName then
            local nm = c:RecipeName(id, "")
            if nm and nm ~= "" then named[id] = nm end
        end
    end
    for id, nm in pairs(named) do
        local w, eff = Enchant:Parse(nm)
        if w and SLOT_NAME[w] then
            _wordBySpell[id] = w
            local b = baseStat(eff)
            if b then _statBySpell[id] = b; seen[b] = true end
        end
    end
    local list = {}
    for b in pairs(seen) do list[#list + 1] = b end
    table.sort(list)
    for i, b in ipairs(list) do _statOrder[b] = i end
end

local function slotWordOf(spellID)
    if not spellID then return nil end
    if not _wordBySpell then buildMaps() end
    return _wordBySpell[spellID]
end

-- Id d'emplacement d'inventaire ciblé par l'enchant `spellID`, ou nil si ce n'est pas un enchant
-- d'équipement (huile/baguette, ou emplacement non répertorié).
-- Anneau : DEUX emplacements possibles et pas d'UI de choix → doigt 1 par défaut ; s'il est VIDE et que
-- le doigt 2 porte un anneau, on cible le doigt 2 (sinon le clic échouerait sur un slot vide). Deux
-- anneaux portés = doigt 1, limitation assumée (pour le doigt 2 : bouton natif + clic sur l'anneau).
function Enchant:SlotFor(spellID)
    local w = slotWordOf(spellID)
    local slotName = w and SLOT_NAME[w]
    if not slotName then return nil end
    local slot = GetInventorySlotInfo and GetInventorySlotInfo(slotName) or nil
    if w == "Ring" and slot and GetInventoryItemLink and not GetInventoryItemLink("player", slot) then
        local s1 = GetInventorySlotInfo("Finger1Slot")
        if s1 and GetInventoryItemLink("player", s1) then return s1 end
    end
    return slot
end

-- Section d'affichage d'un enchant d'équipement : libellé d'emplacement LOCALISÉ + rang de tri, ou nil
-- (pas un enchant d'équipement → l'appelant retombe sur COC.SectionOf).
function Enchant:SectionFor(spellID)
    local w = slotWordOf(spellID)
    local s = w and slotSection(w)
    if not s then return nil end
    return (_G[s[1]] or w), 100 + s[2]
end

-- Sous-catégorie d'un enchant d'équipement : la STAT DE BASE (« Major Spirit » → « Spirit »), pour
-- regrouper les variantes sous une seule tête dans la colonne. Rend `libellé, rang, niveau` :
--   * libellé : `L[stat]` — la clé ANGLAISE est le repli (COC.L rend la clé si aucun overlay), donc c'est
--     lisible tout de suite et traduisible plus tard en ajoutant les clés (clé DYNAMIQUE : le checker de
--     locale ne la voit pas, cf. la note dans les overlays) ;
--   * rang : index alphabétique stable (le moteur ordonne les sous-catégories par NOMBRE) ;
--   * niveau : rang de métier de la recette → les variantes se trient du plus fort au plus faible
--     (Superior Impact avant Lesser Impact), comme partout ailleurs dans l'addon.
-- nil pour tout ce qui n'est pas un enchant d'équipement (huiles, baguettes) → classement par objet.
function Enchant:StatFor(spellID)
    if not _statBySpell then buildMaps() end
    local b = spellID and _statBySpell[spellID]
    if not b then return nil end
    local c = CL()
    local tier = (c and c.RecipeLearnedAt and c:RecipeLearnedAt("Enchanting", spellID)) or 0
    return (L[b] or b), (_statOrder[b] or 500), tier
end

-- INVTYPE de l'objet (GetItemInfoInstant) → mots d'emplacement dont les enchants lui sont applicables.
-- C'est une LISTE car une arme à DEUX MAINS accepte AUSSI les enchants « Weapon » génériques (mais une
-- arme à 1 main n'accepte PAS les « 2H Weapon »). Emplacement absent = rien d'enchantable (Era n'a pas
-- d'enchant d'arme à distance, de ceinture, de jambières…).
local EQUIP_WORDS = {
    INVTYPE_WRIST    = { "Bracer" },  INVTYPE_HAND  = { "Gloves" }, INVTYPE_FEET  = { "Boots" },
    INVTYPE_CHEST    = { "Chest" },   INVTYPE_ROBE  = { "Chest" },  INVTYPE_CLOAK = { "Cloak" },
    INVTYPE_SHIELD   = { "Shield" },  INVTYPE_FINGER = { "Ring" },  INVTYPE_HEAD  = { "Head" },
    INVTYPE_SHOULDER = { "Shoulder" },
    INVTYPE_WEAPON   = { "Weapon" },  INVTYPE_WEAPONMAINHAND = { "Weapon" },
    -- Tenu en main gauche (SoD « Enchant Off-Hand ») ; une arme de main gauche accepte les deux.
    INVTYPE_HOLDABLE = { "Off-Hand" },
    INVTYPE_WEAPONOFFHAND = { "Weapon", "Off-Hand" },
    INVTYPE_2HWEAPON = { "2H Weapon", "Weapon" },
}

-- Mes enchants APPLICABLES à un objet d'emplacement `equipLoc`, lus dans la fenêtre de craft OUVERTE
-- (l'API Craft ne répond que fenêtre ouverte → nil si elle est fermée, l'appelant le signale).
-- Triés du plus haut niveau au plus bas (la meilleure version d'abord), puis par nom.
function Enchant:CraftsForEquipLoc(equipLoc)
    local words = EQUIP_WORDS[equipLoc or ""]
    if not (words and COC.Craft and COC.Craft:IsCraftOpen()) then return nil end
    local ok = {}
    for _, w in ipairs(words) do ok[w] = true end
    local c, out = CL(), {}
    for _, r in ipairs(COC.Craft:ReadRecipes() or {}) do
        if not r.isHeader and r.spellID and ok[slotWordOf(r.spellID) or ""] then
            r._lvl = (c and c.RecipeLearnedAt and c:RecipeLearnedAt("Enchanting", r.spellID)) or 0
            out[#out + 1] = r
        end
    end
    table.sort(out, function(a, b)
        if a._lvl ~= b._lvl then return a._lvl > b._lvl end
        return (a.name or "") < (b.name or "")
    end)
    return out
end

-- Libellé COURT d'un enchant : la STAT seule (« Greater Strength »), le nom complet répétant l'emplacement
-- déjà porté par l'en-tête de section (« Enchant Bracer - … » ×20, tronqué dans la colonne). On coupe sur
-- le 1er « espace TIRET espace » du nom LOCALISÉ du client (même structure dans toutes les langues) ;
-- repli = nom entier. Même garde que Parse : un tiret NU couperait DANS un mot d'emplacement qui en
-- contient un (« Enchant Off-Hand - Wisdom » → « Hand - Wisdom »).
-- Ne s'applique QU'AUX enchants d'équipement : huiles/baguettes gardent leur nom complet.
function Enchant:ShortName(name, spellID)
    if not (name and slotWordOf(spellID)) then return name end
    return name:match("^.-%s+%-%s+(.-)%s*$") or name
end

-- NOTE — Popup « Remplacer l'enchantement » (objet DÉJÀ enchanté) : PAS d'auto-accept possible.
-- `ReplaceEnchant()` (OnAccept de la popup) est une fonction PROTÉGÉE — la déclencher par un clic
-- PROGRAMMATIQUE lève `ADDON_ACTION_FORBIDDEN` (vérifié en jeu 2026-07-15) ; Blizzard EXIGE un clic
-- MATÉRIEL sur « Oui ». On laisse donc la popup native s'afficher normalement : l'utilisateur confirme
-- lui-même (1 clic de plus sur un objet déjà enchanté ; zéro sur un objet vierge).
