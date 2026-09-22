-- CraftingOrderClassic_ProfWindow_Learn.lua — section « À apprendre maintenant » du Plan de route :
-- les recettes NON APPRISES que ton rang permet déjà d'apprendre ET qui rapportent encore un point,
-- classées par coût espéré par point, avec l'icône de leur source.
--
-- POURQUOI CETTE VUE ET PAS UN MODE « MANQUANTES » COMPLET. Sur WoW: Forever la fenêtre native
-- affiche DÉJÀ les recettes non apprises (séparateur « Unlearned », filtre actif par défaut) et
-- donne leur source en toutes lettres dans la langue du client (`GetRecipeSourceText`). Refaire la
-- liste par-dessus, dans une colonne trois fois plus étroite, donnerait une version moins bonne de
-- ce que le joueur a sous les yeux. Ce que la native ne fait PAS, c'est répondre à la seule
-- question qui compte quand on monte un métier : « parmi tout ça, qu'est-ce que je peux apprendre
-- MAINTENANT, qui me fera encore progresser, et au meilleur prix ? » C'est cette question-là qu'on
-- traite — le reste, on le laisse à Blizzard.
--
-- La route ne retient qu'UNE recette par rang (la meilleure) : elle dit quoi faire, pas ce qu'il y
-- avait à choisir. Cette section montre le champ des possibles, au rang courant seulement.
--
-- Soft-dep dans les deux sens : appelée sous garde nil par _FillRouteSupply (sans ce fichier, la
-- fenêtre garde ses segments), et sans oracle de prix elle s'affiche quand même — le classement
-- retombe sur le rang requis, la liste reste utile.

local COC  = CraftingOrderClassic
local PW   = COC.ProfWindow
local L    = COC.L

-- Chance ESTIMÉE de gagner un point par craft, par couleur. MÊMES paliers que _ProfWindow_Leveling
-- et COC.Route : les trois doivent raconter la même histoire, sinon le joueur voit trois conseils
-- qui se contredisent sans comprendre pourquoi.
local CHANCE = { optimal = 1.0, medium = 0.75, easy = 0.25 }

-- Icônes NATIVES de gossip (aucun asset à livrer), mêmes que la liste de recettes.
local ICON = {
    trainer = "Interface\\GossipFrame\\TrainerGossipIcon",
    vendor  = "Interface\\GossipFrame\\VendorGossipIcon",
    drop    = "Interface\\GossipFrame\\BattleMasterGossipIcon",
    quest   = "Interface\\GossipFrame\\ActiveQuestIcon",
    unknown = "Interface\\GossipFrame\\IncompleteQuestIcon",
}

local MAX_ROWS = 6   -- la fenêtre est petite : au-delà, ce n'est plus un conseil mais une liste

-- Couleur d'une recette à un rang donné, d'après ses seuils réels { orange, jaune, vert, gris }.
-- nil = grise (aucun point) OU pas encore apprenable : dans les deux cas elle n'a rien à faire ici.
local function colorAt(colors, rank)
    if not colors then return nil end
    if rank >= colors[4] then return nil end
    if rank >= colors[3] then return "easy" end
    if rank >= colors[2] then return "medium" end
    if rank >= colors[1] then return "optimal" end
    return nil
end

-- Les manquantes apprenables au rang courant, triées par coût/point croissant (coût inconnu en
-- fin de liste, jamais écarté : une recette sans prix reste une recette à apprendre).
function PW:_LearnableNow()
    local S, lib = COC.Sources, LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    if not (S and lib and self.profKey) then return {} end
    local rank = COC.Craft and COC.Craft:OpenRank()
    if not rank then return {} end
    local PR, out = COC.Profit, {}
    for _, m in ipairs(S:MissingRecipes(self.profKey) or {}) do
        local lvl = m.level or 0
        -- Le rang requis est un préalable DUR : conseiller un plan qu'on ne peut pas apprendre est
        -- le bug de 2026-07-17 (un plan niv. 55 recommandé à un rang 244), dans l'autre sens.
        if lvl > 0 and lvl <= rank then
            local diff = colorAt(lib.RecipeColors and lib:RecipeColors(self.profKey, m.spellID), rank)
            if diff then
                local c = PR and PR.CraftCost and PR:CraftCost(self.profKey, m.spellID)
                out[#out + 1] = {
                    sid = m.spellID, name = m.name, level = lvl, diff = diff,
                    kind = S:SourceKind(self.profKey, m.spellID),
                    perPoint = c and c.cost and math.floor(c.cost / CHANCE[diff] + 0.5) or nil,
                    partial = c and c.missing or nil,
                }
            end
        end
    end
    table.sort(out, function(a, b)
        if (a.perPoint ~= nil) ~= (b.perPoint ~= nil) then return a.perPoint ~= nil end
        if a.perPoint and b.perPoint and a.perPoint ~= b.perPoint then return a.perPoint < b.perPoint end
        if a.level ~= b.level then return a.level > b.level end    -- à prix égal, le plus haut palier
        return (a.name or "") < (b.name or "")
    end)
    return out
end

-- Une ligne : icône de source + nom + rang requis, et le coût/point à droite quand on le connaît.
local function learnLine(e)
    local icon = ICON[e.kind] or ICON.unknown
    local cost = e.perPoint
        and ("  |cFF888888" .. COC.Api.Coin(math.max(1, e.perPoint)) .. (e.partial and " (?)" or "") .. "|r")
        or ""
    return "|T" .. icon .. ":12:12|t " .. (e.name or "?")
        .. " |cFF666666(" .. e.level .. ")|r" .. cost
end

-- Peint la section. Rend le nouveau `y`. Rien du tout s'il n'y a rien à apprendre : une section
-- vide dans une petite fenêtre coûte de la place à tout le monde pour n'apprendre rien à personne.
function PW:_FillRouteLearn(f, used, y)
    local U = COC.UI
    if not (U and U._NeedsTextLine) then return y end
    local list = self:_LearnableNow()
    if #list == 0 then return y end
    y = U:_NeedsTextLine(f, used, y + 8,
        "|cFFE8B84B" .. string.format(L["À apprendre maintenant (%d)"], #list) .. "|r")
    for i = 1, math.min(#list, MAX_ROWS) do
        y = U:_NeedsTextLine(f, used, y, learnLine(list[i]))
    end
    if #list > MAX_ROWS then
        y = U:_NeedsTextLine(f, used, y, "|cFF666666"
            .. string.format(L["… et %d autres"], #list - MAX_ROWS) .. "|r")
    end
    return y
end
