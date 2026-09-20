-- CraftingOrderClassic_Sources.lua — « où j'obtiens ce plan, et lesquels me manquent ».
--
-- CE MODULE REMPLACE LE PONT MTSL, et le remplace ENTIÈREMENT. Raisons, dans l'ordre :
--   1. MTSL n'est plus maintenu. Une fonctionnalité de COC ne doit pas mourir avec un addon tiers.
--   2. Sa base décrit Vanilla + TBC. Or WoW: Forever a profondément remanié la base d'objets :
--      894 objets-recette n'existent QUE sur Forever (la moitié des siens), 173 objets de Classic
--      en ont disparu, et 24 identifiants communs désignent un AUTRE objet (6342 passe de
--      « Minor Mana » à « Minor Intellect », 3831 de « Mighty Troll's Blood Potion » à
--      « Troll's Blood Elixir »). Ces derniers sont les pires : ils ne se taisent pas, ils
--      répondent à côté, avec assurance. Un annuaire périmé est pire qu'un annuaire absent.
--   3. La donnée dont on a besoin est déjà dans NOTRE catalogue CraftLink, généré depuis la même
--      source que les recettes elles-mêmes (tools/gen_sources.lua) — donc juste par construction
--      sur chaque saveur, et rafraîchie par le même geste que le reste des données.
--
-- CE QU'ON PERD EN ABANDONNANT MTSL, et qu'il faut assumer plutôt que masquer :
--   · le PRIX au formateur (aucune source ne le donne) → SourcePrice rend nil, et nil veut dire
--     INCONNU, jamais zéro. Un appelant qui confondrait les deux conseillerait d'acheter un plan
--     « gratuit » qui ne l'est pas ;
--   · les COORDONNÉES exactes du PNJ (on donne son nom et sa zone) ;
--   · le nom du PNJ dans la langue du client : il arrive en anglais. La ZONE, elle, reste
--     localisée — on ne stocke que son AreaID et `C_Map.GetAreaInfo` fait le reste ;
--   · la distinction RÉPUTATION : un quartier-maître est annoncé comme un vendeur.
--
-- Contrat identique à l'ancien pont (mêmes noms, mêmes retours) : les appelants n'ont eu qu'à
-- changer de table. « unknown » reste la réponse honnête quand on ne sait pas.

local COC = CraftingOrderClassic
local S   = {}
COC.Sources = S

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

-- Le catalogue est EMBARQUÉ : il est toujours là. On garde le prédicat parce que les appelants
-- l'interrogeaient, et parce qu'un métier hors catalogue (Poisons vanilla) reste possible.
function S:IsAvailable() return CL() ~= nil end

-- ------------------------------------------------------------------
-- Objet-recette (le parchemin/patron/plan qui enseigne)
-- ------------------------------------------------------------------

-- Reverse paresseux spellID -> itemID, depuis `taughtBy` (qui va dans l'autre sens). Par métier,
-- construit à la première demande : la table complète fait quelques centaines d'entrées.
local taughtRev = {}
local function recipeItemFor(profKey, spellID)
    if not (profKey and spellID) then return nil end
    local rev = taughtRev[profKey]
    if not rev then
        rev = {}
        local lib = CL()
        local def = lib and lib.GetProfession and lib:GetProfession(profKey)
        for itemID, sid in pairs(def and def.taughtBy or {}) do rev[sid] = itemID end
        taughtRev[profKey] = rev
    end
    return rev[spellID]
end

function S:RecipeItem(profKey, spellID) return recipeItemFor(profKey, spellID) end

-- ------------------------------------------------------------------
-- Nature de la source
-- ------------------------------------------------------------------

-- "trainer" | "vendor" | "drop" | "quest" | "unknown".
--
-- ⚠️ LE FORMATEUR EST UNE DÉDUCTION, PAS UNE DONNÉE. Aucune source ne l'affirme ; on l'infère de
-- l'absence d'objet-recette. C'est très fiable là où le catalogue est complet (449 des 450
-- recettes que MTSL donnait au formateur n'ont effectivement aucun objet) et ça l'est moins sur
-- une saveur jeune, où l'objet peut exister sans qu'on le sache encore. D'où l'ordre des tests :
-- un FAIT (la nature générée) l'emporte toujours sur la déduction.
function S:SourceKind(profKey, spellID)
    if not spellID then return "unknown" end
    local lib = CL(); if not lib then return "unknown" end
    local kind = lib.RecipeSource and lib:RecipeSource(profKey, spellID)
    if kind then return kind end
    if recipeItemFor(profKey, spellID) then return "unknown" end   -- objet connu, source inconnue
    -- Aucun objet-recette : la recette s'apprend en principe au formateur. On ne le dit que si la
    -- recette est bien de NOTRE catalogue — sinon on ne sait rien d'elle du tout.
    local learnedAt = lib.RecipeLearnedAt and lib:RecipeLearnedAt(profKey, spellID)
    return learnedAt and "trainer" or "unknown"
end

-- Cette nature a-t-elle été LUE, ou seulement déduite ? Les vues qui annoncent une source doivent
-- pouvoir nuancer (« probablement au formateur ») plutôt que d'affirmer ce qu'on ignore.
function S:IsInferred(profKey, spellID)
    local lib = CL()
    return not (lib and lib.RecipeSource and lib:RecipeSource(profKey, spellID))
end

-- Rang de compétence requis, ou nil.
function S:MinSkill(profKey, spellID)
    local lib = CL()
    return lib and lib.RecipeLearnedAt and lib:RecipeLearnedAt(profKey, spellID) or nil
end

-- PRIX du plan chez son vendeur. `nil` = INCONNU, et les appelants doivent le traiter comme tel :
-- on ne connaît ni les prix de formateur, ni les prix fixes des marchands. Seul Auctionator, s'il
-- a vu le marchand, sait répondre — et c'est déjà son rôle via COC.LazyGold, interrogé ici pour
-- que les appelants n'aient qu'UN endroit à demander.
function S:SourcePrice(profKey, spellID)
    local itemID = recipeItemFor(profKey, spellID)
    local LG = COC.LazyGold
    if not (itemID and LG and LG.IsVendorItem and LG:IsVendorItem(itemID)) then return nil end
    return LG:ItemValue(itemID)
end

-- LE TEXTE DE SOURCE DU CLIENT, quand il existe : autoritaire, localisé, et complet.
-- `C_TradeSkillUI.GetRecipeSourceText` n'est documentée nulle part mais le code de Blizzard
-- l'appelle lui-même (Blizzard_ProfessionsRecipeSchematicForm.lua) pour l'infobulle « Recette non
-- apprise » de la fenêtre native. Elle n'existe QUE sur mainline -- l'Era ne l'a pas du tout.
--
-- Elle prime sur notre catalogue partout où elle répond, et pour une raison de fond : elle vient
-- du JEU. Sur Forever, où la moitié des objets n'ont pas encore de source connue côté Wowhead et
-- où la base d'objets a été remaniée, c'est la seule référence qui ne peut pas être périmée.
-- Contrepartie : c'est du TEXTE libre, pas une nature -- on l'affiche, on ne le classe pas.
function S:SourceText(profKey, spellID)
    local get = C_TradeSkillUI and C_TradeSkillUI.GetRecipeSourceText
    if not (get and spellID) then return nil end
    local ok, txt = pcall(get, spellID)
    return (ok and type(txt) == "string" and txt ~= "") and txt or nil
end

-- ------------------------------------------------------------------
-- Le PNJ qui vend le plan
-- ------------------------------------------------------------------

-- « Nom — Zone », ou juste « Nom » si la zone est inconnue. nil si la recette ne s'achète pas chez
-- un PNJ ou si le marchand n'est pas nommé (un tiers des plans vendus). Le nom de zone est rendu
-- par le CLIENT, donc dans sa langue ; le nom du PNJ arrive en anglais, faute d'API pour le
-- résoudre depuis son identifiant.
function S:SourceNpcLine(profKey, spellID)
    local lib = CL(); if not lib or not lib.RecipeVendor then return nil end
    local npcID, areaID, name = lib:RecipeVendor(profKey, spellID)
    if not name then return nil end
    local zone = areaID and C_Map and C_Map.GetAreaInfo and C_Map.GetAreaInfo(areaID) or nil
    return zone and (name .. " — " .. zone) or name, npcID
end

-- ------------------------------------------------------------------
-- Recettes manquantes du perso courant
-- ------------------------------------------------------------------

-- Tout le catalogue du métier MOINS ce que ce personnage sait déjà faire. Deux témoins, et les
-- deux comptent : le registre de la lib (persisté, alimenté à chaque ouverture de la fenêtre de
-- métier) et `IsSpellKnown`, qui seul voit les capacités APPRISES MAIS ABSENTES de la liste de
-- recettes (Prospection, Broyage, Fonte, Désenchantement…). Sans le second, on annoncerait comme
-- manquant ce que le joueur utilise tous les jours.
--
-- Format IDENTIQUE à COC.Craft:ReadRecipes() + isMissing/level, pour que la vue métier et le
-- regroupement par catégories les traitent sans cas particulier.
function S:MissingRecipes(profKey)
    local lib = CL()
    if not (lib and profKey and lib.GetRecipes) then return {} end
    local known = (lib.MyKnownSet and lib:MyKnownSet(profKey)) or {}
    local out = {}
    for _, spellID in ipairs(lib:GetRecipes(profKey) or {}) do
        if not known[spellID] and not (IsSpellKnown and IsSpellKnown(spellID)) then
            local itemID = lib.RecipeProduct and lib:RecipeProduct(profKey, spellID) or nil
            out[#out + 1] = {
                isMissing = true, spellID = spellID, itemID = itemID,
                name = (lib.RecipeName and lib:RecipeName(spellID)) or COC.Api.GetSpellName(spellID)
                       or ("spell:" .. spellID),
                level = (lib.RecipeLearnedAt and lib:RecipeLearnedAt(profKey, spellID)) or 0,
                icon = (itemID and COC.Api.GetItemIcon and COC.Api.GetItemIcon(itemID))
                       or "Interface\\Icons\\INV_Scroll_03",
                difficulty = "trivial",   -- neutre : une recette non apprise n'a pas de couleur
            }
        end
    end
    return out
end

-- ------------------------------------------------------------------
-- Fiche détaillée
-- ------------------------------------------------------------------

-- Libellé + couleur d'une nature. Écrit en toutes lettres, une ligne par cas, ET PAS via une table
-- indexée dynamiquement : `check_locale` lit le SOURCE pour savoir quelles clés servent, et un
-- `L[variable]` lui est invisible -- les quatre clés passaient pour mortes, donc supprimables par
-- une future passe de ménage, qui aurait vidé ces libellés en silence.
local function kindLabel(kind)
    local L = COC.L
    if kind == "trainer" then return L["Formateur"], "|cFF88CCFF" end
    if kind == "vendor"  then return L["Vendeur"],   "|cFFEEDD88" end
    if kind == "drop"    then return L["Butin"],     "|cFFEE8833" end
    if kind == "quest"   then return L["Quête"],     "|cFFFFCC00" end
    return nil
end

-- { lines = { {label, value}, ... }, itemID = objet-recette }. Volontairement plus courte que la
-- fiche MTSL : on n'affiche que ce qu'on sait. Une ligne « Prix : ? » n'apprend rien à personne.
function S:SkillDetail(profKey, spellID)
    local L, lines = COC.L, {}
    local lib = CL()
    if not (lib and spellID) then return { lines = lines } end

    local lvl = self:MinSkill(profKey, spellID)
    if lvl then lines[#lines + 1] = { label = L["Niveau requis"], value = "|cFF33DD33" .. lvl .. "|r" } end

    local itemID = recipeItemFor(profKey, spellID)
    if itemID then
        local nm = (COC.Api.GetItemInfo and COC.Api.GetItemInfo(itemID))
                or (lib.ItemName and lib:ItemName(itemID)) or ("item:" .. itemID)
        lines[#lines + 1] = { label = L["Appris de"], value = nm }
    end

    -- Le texte du client d'abord : il sait ce que nos données ignorent, et il est déjà dans la
    -- langue du joueur. Pas de « ? » ici -- ce n'est pas une déduction, c'est le jeu qui parle.
    local fromGame = self:SourceText(profKey, spellID)
    local kind = self:SourceKind(profKey, spellID)
    local label, color = kindLabel(kind)
    if fromGame then
        lines[#lines + 1] = { label = L["Obtenu via"], value = fromGame }
    elseif label then
        -- Le suffixe « ? » dit au joueur que c'est une déduction, pas un relevé. Sans lui, la
        -- fiche affirmerait « Formateur » avec le même aplomb pour un fait et pour une hypothèse.
        local inferred = (kind == "trainer") and self:IsInferred(profKey, spellID)
        lines[#lines + 1] = { label = L["Obtenu via"],
            value = color .. label .. "|r" .. (inferred and " |cFF888888?|r" or "") }
    else
        lines[#lines + 1] = { label = L["Obtenu via"], value = "|cFF888888" .. L["Source inconnue"] .. "|r" }
    end

    local npcLine = self:SourceNpcLine(profKey, spellID)
    if npcLine then lines[#lines + 1] = { label = L["Vendu par"], value = npcLine } end

    local price = self:SourcePrice(profKey, spellID)
    if price then lines[#lines + 1] = { label = L["Prix"], value = COC.Api.Coin(price) } end

    return { lines = lines, itemID = itemID }
end
