-- CraftingOrderClassic_Craft.lua — socle de lecture LIVE de la fenêtre métier.
-- Aucune UI ici : juste la lecture (recettes, réactifs, rang) + le déclenchement du craft.
--
-- ⚠️ CIBLE UNIQUE depuis le 2026-09-21 : WoW: Forever / Camelot, API MAINLINE. Ce socle portait
-- historiquement DEUX backends Classic — TradeSkill (métiers normaux, lecture par index) et Craft
-- (Enchantement / Dressage, `CraftFrame`) — plus un troisième, MAINLINE. Les deux premiers ont été
-- RETIRÉS : l'Era est gelé (branche `era`, v1.30.0), COC n'a plus qu'un `.toc` 16001. Le socle n'a
-- donc plus rien à départager, et la dichotomie Craft/TradeSkill — avec tout ce qu'elle traînait
-- (`DoCraft` protégé, bouton sécurisé redirigé, réactifs natifs à museler) — n'existe plus.
-- Y revenir un jour = rajouter un BACKEND (patron : _Craft_Mainline.lua), pas rouvrir ces branches.

local COC = CraftingOrderClassic
local Craft = {}
COC.Craft = Craft

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

-- Nom localisé du métier ouvert (ou nil). Le 2ᵉ retour `isCraft` a disparu avec l'API Craft :
-- les appelants qui s'en servaient pour choisir un comportement n'ont plus qu'un cas.
function Craft:GetOpenProfessionInfo()
    if not self.MAINLINE_API then return nil end
    local name = self.MAINLINE_API.getSkillName()
    if name and name ~= "" then return name end
    return nil
end

-- Table d'API du métier ACTUELLEMENT ouvert, ou nil. Il n'y a plus qu'un backend : le socle ne
-- choisit plus rien, il constate. Les deux tables Classic (TRADESKILL_API / CRAFT_API) vivaient
-- ici ; elles ont été retirées avec l'Era (cf. l'en-tête).
function Craft:GetActiveAPI()
    if not self:GetOpenProfessionInfo() then return nil end
    return self.MAINLINE_API
end

-- Clé interne (EN) du métier ouvert via CraftLink, ou nil.
function Craft:OpenProfessionKey()
    local name = self:GetOpenProfessionInfo()
    local c = CL()
    return (name and c and c:ResolveProfession(name)) or nil
end

local DIFF_COLOR = {
    optimal = { r = 1.00, g = 0.50, b = 0.25 }, medium = { r = 1.00, g = 1.00, b = 0.00 },
    easy    = { r = 0.25, g = 0.75, b = 0.25 }, trivial = { r = 0.50, g = 0.50, b = 0.50 },
}
-- `TradeSkillTypeColor` / `CraftTypeColor` (les tables natives de l'Era) n'existent pas sur la
-- cible : nos couleurs SONT la référence, plus un repli.
function Craft:DifficultyColor(difficulty)
    local c = DIFF_COLOR[difficulty]
    if c then return c.r, c.g, c.b end
    return 0.9, 0.9, 0.9
end

-- Rang du métier ouvert (skill, max). La fiche de métier MAINLINE le porte ; l'annuaire sert de
-- repli (Directory tient mySkills à jour via l'API skill, lisible sans ouvrir la fenêtre) —
-- notamment quand aucune fenêtre n'est ouverte.
function Craft:OpenRank()
    if self.MainlineRank then
        local r, m = self:MainlineRank()
        if r then return r, m end
    end
    local key = self:OpenProfessionKey()
    local D = COC.Directory
    if key and D and D.mySkills and D.mySkills[key] then
        return D.mySkills[key][1], D.mySkills[key][2]
    end
    return nil
end

-- Ce que le CLIENT sait d'une recette désignée par son SORT, apprise ou NON :
-- { name, link, icon, difficulty, learned, skillUps, trivialAt } ou nil.
-- Seul le backend MAINLINE sait répondre — les deux API Classic ne lisent que par INDEX, et leur
-- liste ne contient que les recettes apprises. nil veut donc dire « pas d'avis », jamais « non ».
function Craft:RecipeFacts(spellID)
    if self.MainlineRecipeFacts then return self:MainlineRecipeFacts(spellID) end
    return nil
end

-- Toute la liste de recettes APPRISES (en-têtes inclus, isHeader=true), ou nil si fermé.
-- « Apprises » n'allait de soi que sur les deux backends Classic, où la fenêtre native ne connaît
-- que ça. Sur MAINLINE le client rend aussi les NON apprises (cf. `getLearned` de Craft_Mainline) :
-- un backend qui sait le dire les écarte ici, en amont, pour que tous les appelants gardent le sens
-- qu'ils ont toujours eu — ce que CE perso sait faire. L'union avec les manquantes, elle, se
-- construit dans la VUE (cf. _ProfWindow_Recipes), jamais dans la lecture.
function Craft:ReadRecipes()
    local api = self:GetActiveAPI()
    if not api then return nil end
    local out, num = {}, api.getNum()
    for i = 1, num do
        local name, skillType, numAvailable = api.norm(i)
        if name and (not api.getLearned or api.getLearned(i)) then
            if api.isHeader(skillType) then
                out[#out + 1] = { index = i, name = name, isHeader = true }
            else
                local link   = api.getLink(i)
                local itemID = link and tonumber(link:match("|Hitem:(%d+)")) or nil
                -- spellID de la RECETTE (pas de l'objet produit) : sert au rang requis MTSL
                -- (« niv. X ») et au linkage chat de la recette. Chaque backend sait le fournir —
                -- déduit d'un lien |Henchant: en Classic, rendu tel quel sur Mainline où la recette
                -- EST le sort. Peut rester nil si l'API sous-jacente ne l'expose pas.
                local spellID = api.getSpellID and api.getSpellID(i) or nil
                local mn, mx = api.getNumMade(i)
                out[#out + 1] = {
                    index = i, name = name, link = link, itemID = itemID, spellID = spellID,
                    icon = api.getIcon(i), difficulty = skillType,
                    numAvailable = numAvailable or 0, numMade = mn or 1, numMadeMax = mx or mn or 1,
                }
            end
        end
    end
    return out
end

-- Réactifs d'une recette : { {name, texture, need, have, link}, ... }.
function Craft:Reagents(index)
    local api = self:GetActiveAPI()
    if not api or not index then return {} end
    local out, n = {}, api.getNumReag(index)
    for j = 1, n do
        local rName, texture, need, have = api.getReagInfo(index, j)
        out[#out + 1] = { name = rName, texture = texture, need = need or 0, have = have or 0,
                          link = api.getReagLink(index, j) }
    end
    return out
end

-- Déclenche le craft. `DoCraft` était PROTÉGÉ sur l'Era et imposait un bouton sécurisé redirigé
-- vers `CraftCreateButton` ; `C_TradeSkillUI.CraftRecipe` ne l'est pas. Tout ce montage a disparu.
function Craft:Do(index, count)
    local api = self:GetActiveAPI()
    if not api or not index then return end
    api.craft(index, count or 1)
end
