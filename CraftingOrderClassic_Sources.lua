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
--   · le prix d'un plan de FORMATEUR : aucune source ne le donne, SourcePrice rend nil, et nil veut
--     dire INCONNU, jamais zéro -- un appelant qui confondrait les deux conseillerait d'acheter un
--     plan « gratuit » qui ne l'est pas. (Le prix chez un MARCHAND, lui, est revenu : les pages
--     d'objet de Wowhead le portent, cf. tools/gen_origins.lua) ;
--   · les COORDONNÉES d'un PNJ du catalogue : on donne son nom et sa zone, pas ses coordonnées.
--     Seul un formateur qu'on a VU en jeu en a (cf. COC.Trainers -- on y était) ;
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
-- A-t-on VU un formateur enseigner cette recette ? (cf. COC.Trainers, moisson sur TRAINER_SHOW.)
-- Soft-dep : sans le module, tout se comporte exactement comme avant.
local function observed(profKey, spellID)
    local T = COC.Trainers
    return (T and T.Teaches and T:Teaches(profKey, spellID)) == true
end

function S:SourceKind(profKey, spellID)
    if not spellID then return "unknown" end
    local lib = CL(); if not lib then return "unknown" end
    -- CE QU'ON A VU DE NOS PROPRES YEUX PASSE DEVANT, y compris devant une nature générée. Les deux
    -- peuvent être vraies -- un plan se vend ET s'apprend -- et de ces deux vérités, celle sur
    -- laquelle le joueur peut agir sans or et sans farm est la plus utile. Surtout, c'est la seule
    -- qui ne puisse pas être périmée : elle vient du serveur où il joue, pas d'une page écrite
    -- pour un autre. C'est la même règle que `SourceText` applique déjà au texte du client.
    if observed(profKey, spellID) then return "trainer" end
    local kind = lib.RecipeSource and lib:RecipeSource(profKey, spellID)
    if kind then return kind end
    -- La nature DEDUITE de la page de l'objet ou du sort, quand la page de metier se taisait. Sans
    -- cette ligne on affichait « Source inconnue » AVEC le nom du marchand juste en dessous -- une
    -- contradiction que le joueur voit tout de suite (releve en jeu le 2026-09-20).
    kind = lib.RecipeOriginKind and lib:RecipeOriginKind(profKey, spellID)
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
    -- Vu de nos yeux = ce n'est plus une déduction, et le « ? » n'a plus lieu d'être. C'est toute la
    -- récompense de la moisson : le doute disparaît là où l'on est allé voir.
    if observed(profKey, spellID) then return false end
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
-- a vu le marchand, sait répondre — et c'est déjà son rôle via COC.Profit, interrogé ici pour
-- que les appelants n'aient qu'UN endroit à demander.
function S:SourcePrice(profKey, spellID)
    -- Le prix RELEVÉ chez le marchand d'abord : c'est un fait, il ne dépend d'aucun addon tiers, et
    -- il vaut pour tout le monde. Ce qu'on avait perdu en abandonnant MTSL est revenu par les pages
    -- d'objet de Wowhead (`buyprice`), pour les plans vendus.
    local lib = CL()
    local fixed = lib and lib.RecipePrice and lib:RecipePrice(profKey, spellID)
    if fixed then return fixed end
    -- Repli : l'oracle de prix, s'il a vu le marchand. nil reste nil -- jamais zéro.
    local itemID = recipeItemFor(profKey, spellID)
    local PR = COC.Profit
    if not (itemID and PR and PR.IsVendorItem and PR:IsVendorItem(itemID)) then return nil end
    return PR:ItemValue(itemID)
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

-- « Nom — Zone », ou juste « Nom » si la zone est inconnue. Le nom de zone est rendu par le CLIENT,
-- donc dans sa langue ; le nom du PNJ arrive en anglais, faute d'API pour le résoudre par id.
local function line(name, areaID)
    if not name then return nil end
    local zone = areaID and C_Map and C_Map.GetAreaInfo and C_Map.GetAreaInfo(areaID) or nil
    return zone and (name .. " — " .. zone) or name
end

-- CE QUI est derrière le plan, quelle que soit sa nature : le marchand qui le vend, la créature qui
-- le lâche, ou la quête qui le donne. nil quand la donnée ne le nomme pas (plus d'un plan sur deux).
--
-- ⚠️ LA NATURE N'EST PAS DANS LA CHAÎNE, et c'est volontaire : « Wastewander Bandit — Tanaris » ne
-- dit pas s'il faut l'acheter ou le tuer. Tout appelant DOIT afficher la nature (`SourceKind`) à
-- côté, sans quoi il enverra le joueur acheter son plan à un bandit.
-- Le camp du joueur, pour savoir si l'entrée rendue par la lib est la sienne. Les libellés de
-- faction viennent des globales du jeu : déjà traduits, et identiques à ce qu'il lit partout.
local function myFaction()
    local f = UnitFactionGroup and UnitFactionGroup("player")
    return (f == "Alliance" and "A") or (f == "Horde" and "H") or nil
end

-- ⚠️ REND UNE TABLE, PAS TROIS VALEURS, et c'est délibéré. Un multi-retour invite à écrire
-- `local a, b, c = X and X:f()` — qui TRONQUE à une seule valeur en Lua. Ce piège maison est tombé
-- TROIS fois dans la même journée, la dernière sur la ligne qui portait justement le repère : le
-- clic ne pouvait pas marcher, et rien ne le signalait. Une table ne se tronque pas.
--
-- { text = <libellé>, id = <npcID/questID>, pin = { name, mapID, x, y } } ou nil.
function S:SourceOrigin(profKey, spellID)
    -- Le formateur observé ne vit pas dans le catalogue mais dans ce qu'on a vu : il passe devant,
    -- et c'est le seul cas où la ligne porte des COORDONNÉES — on y était.
    if observed(profKey, spellID) then
        local T = COC.Trainers
        -- ⚠️ La garde SORT de l'assignation : `X and X:f()` ne rend qu'UNE valeur en assignation
        -- multiple (piège maison, vécu deux fois) — on y perdrait le PNJ, donc le repère de carte.
        if T and T.Line then
            local ln, npc = T:Line(profKey)
            if ln then return { text = ln, pin = npc } end
        end
    end
    local lib = CL(); if not lib or not lib.RecipeOrigin then return nil end
    local id, areaID, name, faction = lib:RecipeOrigin(profKey, spellID)
    local txt = line(name, areaID)
    -- LES COORDONNEES quand on les a : elles rendent la ligne CLIQUABLE (repere TomTom ou epingle
    -- native), ce que le panneau d'info sait faire depuis toujours mais que plus personne ne lui
    -- fournissait depuis le retrait de MTSL.
    local pin
    if txt and id and lib.NpcSpot then
        local mapID, x, y = lib:NpcSpot(profKey, id)
        if mapID and x then
            txt = txt .. string.format(" |cFF888888(%.0f, %.0f)|r", x, y)
            pin = { name = name, mapID = mapID, x = x, y = y }
        end
    end
    -- ⚠️ LE CAMP D'EN FACE SE DIT. La lib rend le meilleur PNJ qu'elle a, et parfois le seul connu
    -- est chez l'adversaire : « Wulmort Jinglepocket — Forgefer » à un joueur de la Horde n'est pas
    -- une imprécision, c'est un aller simple en territoire ennemi. On ne le cache pas et on ne
    -- l'efface pas non plus -- l'information reste utile, elle doit juste être étiquetée.
    if txt and faction and faction ~= myFaction() then
        -- ⚠️ LE CAMP EN PREMIER, ET TOUT EN GRIS. La marque etait en fin de ligne, apres le nom et la
        -- zone : ca se lisait comme une destination assortie d'une note, alors que c'est une IMPASSE
        -- -- le joueur ne peut pas parler a ce PNJ. Releve en jeu le 2026-09-20 (« j'ai ca dans ma
        -- liste alors que je suis humain »). On ne l'EFFACE pas pour autant : c'est tout ce qu'on
        -- sait, ca vaut pour un reroll du camp d'en face, et le masquer ramenerait le « Vendeur »
        -- suivi de rien qu'on vient justement de faire disparaitre.
        -- On ne NOMME plus le PNJ du camp d'en face : le joueur ne peut pas lui parler, et le lire
        -- sur sa ligne le faisait chercher un marchand inaccessible (relevé en jeu le 2026-09-20,
        -- « j'ai ça dans ma liste alors que je suis humain »). On dit l'ABSENCE plutôt que de
        -- laisser « Vendeur » suivi de rien, qui était l'état qu'on vient de corriger.
        --
        -- La donnée reste en place et reste lisible par `RecipeOrigins` : elle vaut pour un reroll
        -- du camp adverse, que l'addon sait déjà suivre. C'est l'AFFICHAGE qui se tait, pas nous.
        txt = "|cFF888888" .. COC.L["Aucune source connue de ton camp."] .. "|r"
        pin = nil   -- aucun repère vers un PNJ à qui on ne peut pas parler
    end
    if not txt then return nil end
    return { text = txt, id = id, pin = pin }
end

-- Le marchand, et lui seul : ce que demandent les vues qui parlent d'un ACHAT (liste de courses,
-- fournitures du Plan de route). La lib filtre déjà sur la nature — on ne refait pas le tri ici.
function S:SourceNpcLine(profKey, spellID)
    local lib = CL(); if not lib or not lib.RecipeVendor then return nil end
    local npcID, areaID, name = lib:RecipeVendor(profKey, spellID)
    return line(name, areaID), npcID
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
-- Niveau d'apprentissage, ou nil quand on ne le sait pas. 0 n'est pas un niveau : les données ne
-- s'en servent jamais (le plus bas est 1), il ne peut donc venir que d'une absence.
local function levelOf(lib, profKey, spellID)
    local at = lib.RecipeLearnedAt and lib:RecipeLearnedAt(profKey, spellID)
    return (at and at > 0) and at or nil
end

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
                -- ⚠️ PAS de `or 0` : 29 recettes du set Camelot n'ont AUCUN niveau (trou de
                -- génération, 8 rien qu'en Couture). Rendu 0, l'inconnu devenait un niveau REQUIS
                -- de 0 : la vue les classait en tête et les déclarait à portée (0 <= ton rang),
                -- c'est-à-dire qu'elle affirmait ce qu'elle ignore. Un repli doit se taire.
                level = levelOf(lib, profKey, spellID),
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

    -- OÙ aller le chercher, quelle que soit la nature : le marchand, la créature qui lâche le plan,
    -- la quête, ou le formateur qu'on a rencontré. Le libellé « Vendu par » ne survit que sur un
    -- ACHAT — il serait un contresens sur une créature — et les autres natures s'écrivent en ligne
    -- de CONTINUATION, dont la nature est déjà donnée juste au-dessus.
    --
    -- `pin` n'est rempli que pour un formateur observé (on y était, donc on a les coordonnées) : il
    -- rallume le repère de carte de la fiche d'info, resté sans fournisseur depuis MTSL.
    local origin = self:SourceOrigin(profKey, spellID)
    if origin then
        lines[#lines + 1] = { label = (kind == "vendor") and L["Vendu par"] or "",
                              value = origin.text, npc = origin.pin }
    end

    local price = self:SourcePrice(profKey, spellID)
    if price then lines[#lines + 1] = { label = L["Prix"], value = COC.Api.Coin(price) } end

    return { lines = lines, itemID = itemID }
end
