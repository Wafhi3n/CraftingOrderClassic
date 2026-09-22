-- CraftingOrderClassic_Enchant_Filter.lua — le filtre natif « Filter → Slots » de l'Enchantement (Forever).
-- Spec : docs/specs/enchant-echange-forever.md. Pendant un échange, COC coche dans ce filtre la case de
-- la pièce du partenaire. Ce fichier relie une CASE du filtre à ce qu'elle représente (T1) ; le pilote
-- qui pose et rend le filtre vit dans _Enchant_Filter_Pilot.lua (T2).
--
-- Le problème : les noms de case sont LOCALISÉS (« Wrist » sur un client anglais) et le jeu ne dit pas
-- quel emplacement porte chaque case. Mais le client fabrique ces noms à partir de ses propres chaînes
-- globales : relevé T1 (2026-09-21, build 69913, enUS), chacune des 14 cases de l'Enchantement porte
-- EXACTEMENT le texte d'une clé d'emplacement (`WRISTSLOT`, `ENCHSLOT_WEAPON`, `NONEQUIPSLOT`…). Une clé
-- ne dépend pas de la langue : on compare `_G[clé]` au nom de la case, sur le client, dans sa langue.
--
-- Deux familles de clés :
--   · les emplacements de la SILHOUETTE : clé = jeton en majuscules (« WristSlot » → `WRISTSLOT`),
--     comme le libellé que la silhouette affiche déjà (`_G[strupper(slot)]`, _UI_Post_Paperdoll) ;
--   · les catégories d'enchant, qui ne sont pas des emplacements : « Weapon », « 2H Weapon »,
--     « Shield », et « Created Items » (objets produits, aucun emplacement).
-- Le chemin d'une pièce vers ses cases passe par les MOTS d'enchant (« Bracer », « 2H Weapon »…) : une
-- arme à deux mains coche « 2H Weapon » ET « Weapon », une arme à une main « Weapon » seulement.
-- Les cases d'objets produits (« Main Hand », « Ranged »… : baguettes, etc.) ne sont jamais cochées :
-- aucun mot d'enchant n'y mène.
--
-- Chargé après _Enchant.lua et _UI_Post_Paperdoll.lua ; ne lit COC.Enchant et COC.UI.DOLL qu'à l'appel.
-- API : Filter.Resolve(names) · Filter.ReadCases() · Filter.CasesForWords · Filter.CasesForItem ·
-- Filter.CasesForSlot.

local COC    = CraftingOrderClassic
local Filter = {}
COC.EnchantFilter = Filter

-- Catégories d'enchant → emplacement de la silhouette (false = aucun). « Staff » (Wrath) n'a pas de case
-- mesurée : un bâton est une arme à deux mains, il rejoint donc « 2H Weapon ».
local CATEGORY_SLOT = {
    ENCHSLOT_WEAPON = "MainHandSlot", ENCHSLOT_2HWEAPON = "MainHandSlot",
    SHIELDSLOT = "SecondaryHandSlot", NONEQUIPSLOT = false,
}
local WORD_KEY = {
    ["Weapon"] = "ENCHSLOT_WEAPON", ["2H Weapon"] = "ENCHSLOT_2HWEAPON", ["Staff"] = "ENCHSLOT_2HWEAPON",
    ["Shield"] = "SHIELDSLOT",
}
local CATEGORY_ORDER = { "ENCHSLOT_WEAPON", "ENCHSLOT_2HWEAPON", "SHIELDSLOT", "NONEQUIPSLOT" }

-- Clés candidates, dans l'ordre de la silhouette puis des catégories : { { key =, slot = }, … }.
-- L'ORDRE départage deux clés au même texte : « Trinket » répond à TRINKET0SLOT et TRINKET1SLOT, la
-- case prend le premier bijou.
local function candidates()
    local out, D = {}, COC.UI and COC.UI.DOLL
    for _, col in ipairs(D and { D.LEFT, D.RIGHT, D.BOTTOM } or {}) do
        for _, def in ipairs(col) do out[#out + 1] = { key = strupper(def.slot), slot = def.slot } end
    end
    for _, key in ipairs(CATEGORY_ORDER) do out[#out + 1] = { key = key, slot = CATEGORY_SLOT[key] } end
    return out
end

-- Noms de case (dans l'ordre du jeu) → { cases = { [i] = { name =, key =, slot = } }, byKey = { [clé] = i } }.
-- Par case : `slot` = jeton de la silhouette, false = « aucun » (objets produits), nil = case inconnue.
-- Deux cases au même nom sont indiscernables : les deux restent inconnues (`ambiguous`), pour que COC
-- ne coche jamais la mauvaise. Mieux vaut pas de filtre qu'un filtre faux.
function Filter.Resolve(names)
    local seen = {}
    for _, name in ipairs(names) do seen[name] = (seen[name] or 0) + 1 end
    local cand, res = candidates(), { cases = {}, byKey = {} }
    for i, name in ipairs(names) do
        local c = { name = name }
        if seen[name] > 1 then
            c.ambiguous = true
        else
            for _, k in ipairs(cand) do
                if _G[k.key] == name then c.key, c.slot = k.key, k.slot; break end
            end
            if c.key then res.byKey[c.key] = i end
        end
        res.cases[i] = c
    end
    return res
end

-- Les cases du métier OUVERT, lues sur le client. Le filtre est propre au métier (l'Herboristerie n'a
-- qu'une case) : ne vaut que si l'Enchantement est affiché, à l'appelant de s'en assurer.
function Filter.ReadCases()
    local ts = C_TradeSkillUI
    if not (ts and ts.GetAllFilterableInventorySlotsCount and ts.GetFilterableInventorySlotName) then
        return nil
    end
    local names = {}
    for i = 1, ts.GetAllFilterableInventorySlotsCount() or 0 do
        local name = ts.GetFilterableInventorySlotName(i)
        names[i] = type(name) == "string" and name or ("?" .. i)
    end
    return Filter.Resolve(names)
end

-- Clé de case d'un mot d'enchant : catégorie d'arme ou de bouclier, sinon l'emplacement du mot
-- (« Bracer » → WristSlot → WRISTSLOT).
local function keyOfWord(word)
    if WORD_KEY[word] then return WORD_KEY[word] end
    local slot = COC.Enchant and COC.Enchant:SlotNameOf(word)
    return slot and strupper(slot) or nil
end

-- Index des cases à cocher pour une liste de mots d'enchant, triés et sans doublon. Seuls comptent les
-- mots que le catalogue de la couche sert vraiment : un mot sans enchant (« Off-Hand » hors SoD)
-- mènerait à une case d'objets produits, pas d'enchants.
function Filter.CasesForWords(res, words)
    local out, took = {}, {}
    local E = COC.Enchant
    for _, w in ipairs(words or {}) do
        local i = res and res.byKey[keyOfWord(w) or ""]
        if i and not took[i] and E and E:HasCatalogFor(w) then took[i] = true; out[#out + 1] = i end
    end
    table.sort(out)
    return out
end

-- Cases d'une pièce posée, d'après son emplacement d'équipement. {} = aucun enchant pour cette pièce.
function Filter.CasesForItem(res, equipLoc, subclassID)
    local E = COC.Enchant
    return Filter.CasesForWords(res, E and E:WordsForEquipLoc(equipLoc, subclassID))
end

-- Cases d'un emplacement de la silhouette (clic de l'enchanteur, pièce pas encore posée) : la main
-- droite coche toutes les familles d'arme, puisqu'on ne sait pas encore ce que le partenaire tient.
function Filter.CasesForSlot(res, slot)
    local D = COC.UI and COC.UI.DOLL
    for _, col in ipairs(D and { D.LEFT, D.RIGHT, D.BOTTOM } or {}) do
        for _, def in ipairs(col) do
            if def.slot == slot then return Filter.CasesForWords(res, def.words) end
        end
    end
    return {}
end
