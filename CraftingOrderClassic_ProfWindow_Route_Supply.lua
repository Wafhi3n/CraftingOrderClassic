-- CraftingOrderClassic_ProfWindow_Route_Supply.lua — ce qui se peint SOUS les segments du plan de
-- route : le bloc « FOURNITURES » (composants agrégés de toute la route, plans à acheter) et, quand
-- le rang est AU PLAFOND, le bloc « débloquer le palier suivant » (livre de rang curaté, ou renvoi
-- vers le formateur de métier).
--
-- Séparé de _ProfWindow_Route.lua le 2026-09-23 : le fichier atteignait 500 lignes pile, le plafond
-- anti-monolithe de la maison, et la porte de deploy.ps1 refusait la ligne suivante. La couture
-- n'est pas arbitraire — au-dessus on décrit UN CHEMIN (quoi crafter, combien de fois, pour
-- combien), ici on décrit CE QU'IL FAUT RÉUNIR pour l'emprunter, et ça s'appuie sur les helpers
-- PARTAGÉS de la bourse d'artisan (_UI_Artisans_Needs), pas sur la mécanique de route.
--
-- Ce qui est soft-dep et ce qui ne l'est PAS : _UI_Artisans_Needs l'est (sans lui la fenêtre garde
-- ses segments seuls, garde nil en place), et _ProfWindow_Learn aussi. CE fichier ne l'est pas :
-- _FillRoute l'appelle SANS garde (_ProfWindow_Route.lua:337), donc le retirer du .toc casse le
-- panneau au lieu de le dégrader. C'est assumé — le .toc est le contrat, et une erreur franche
-- vaut mieux qu'un bloc FOURNITURES qui disparaît sans rien dire.

local COC  = CraftingOrderClassic
local PW   = COC.ProfWindow
local Skin = COC.UI.Skin
local L    = COC.L

-- Bloc « FOURNITURES » sous les segments (demande user 2026-07-19, après la bourse) : composants
-- AGRÉGÉS de toute la route (décomposition/crédit, vendeur en note) + plans à acheter avec le PNJ
-- où aller. Helpers PARTAGÉS de la bourse (_UI_Artisans_Needs — garde nil : soft-dep, sans ce
-- fichier la fenêtre garde ses segments seuls). Fixe la hauteur finale du contenu scrollé.
function PW:_FillRouteSupply(f, route, startY)
    local segs = route and route.segments or {}
    -- ROW_H appartenait a _ProfWindow_Route.lua : on lit la valeur EXPOSEE (PW.ROUTE_ROW_H)
    -- plutot que d'en recopier une ici. Le repli 18 ne sert que si ce fichier etait charge
    -- sans l'autre, ce que le .toc interdit.
    local y = startY or (#segs * (PW.ROUTE_ROW_H or 18))
    local used = { head = 0, slot = 0, line = 0 }
    local U = COC.UI
    if route and route.done then
        y = self:_FillRouteGateway(f, used, y, route)   -- au plafond : comment débloquer la suite
    elseif route and not route.done and U and U._FillSupplyBlock and COC.Route then
        local m = COC.Route:Materials(self.profKey, route)
        if m and (#m.mats > 0 or #m.plans > 0) then
            y = U:_NeedsTextLine(f, used, y + 8, "|cFFE8B84B" .. L["Fournitures (agrégées)"] .. "|r")
            y = U:_FillSupplyBlock(f, used, y, self.profKey, m)
        end
    end
    -- « À apprendre maintenant » (soft-dep _ProfWindow_Learn) : ce que la route ne montre pas, parce
    -- qu'elle ne retient qu'UNE recette par rang -- le champ des possibles au rang courant.
    if self._FillRouteLearn then y = self:_FillRouteLearn(f, used, y) end
    for i = used.slot + 1, #(f.slots or {}) do f.slots[i]:Hide() end
    for i = used.line + 1, #(f.lines or {}) do f.lines[i]:Hide() end
    -- Le contenu suit la largeur du VIEWPORT. Il était figé à 370 au build : juste pour la fenêtre
    -- flottante, deux fois trop large pour la colonne greffée — les lignes débordaient et se
    -- faisaient couper à droite. Et l'ascenseur se masque quand il n'y a rien à faire défiler :
    -- deux flèches au-dessus d'une route de deux étapes n'indiquent rien (constat 2026-09-20).
    local sw = (f.scroll and f.scroll:GetWidth()) or 0
    if sw > 0 then f.content:SetWidth(sw) end
    f.content:SetHeight(math.max(y, 1))
    local nm = f.scroll and f.scroll.GetName and f.scroll:GetName()
    if nm then Skin.AutoHideScroll(nm, f.content) end
end

-- PNJ formateur du PALIER SUIVANT : première recette apprise plus haut que `rank` ET enseignée au
-- FORMATEUR (SourceKind), résolue en ligne PNJ « Nom — Zone ». C'est le même PNJ qui débloque le rang
-- supérieur (ex. Artisan Joaillerie). nil si rien n'est résolu -- et c'est le cas le plus fréquent
-- depuis l'abandon de MTSL : notre catalogue ne nomme que les VENDEURS, jamais les formateurs.
local function nextTrainerLine(profKey, rank)
    local M = COC.Sources
    local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    if not (M and M.SourceNpcLine and M.SourceKind and lib and lib.GetRecipes and lib.RecipeLearnedAt) then return nil end
    local cands = {}
    for _, sid in ipairs(lib:GetRecipes(profKey) or {}) do
        local at = lib:RecipeLearnedAt(profKey, sid)
        if at and at > rank then cands[#cands + 1] = { sid = sid, at = at } end
    end
    table.sort(cands, function(a, b) return a.at < b.at end)
    for _, c in ipairs(cands) do
        if M:SourceKind(profKey, c.sid) == "trainer" then
            local ln = M:SourceNpcLine(profKey, c.sid)
            if ln then return ln end
        end
    end
    return nil
end

-- Bloc « débloquer le palier suivant » (fenêtre AU plafond) : DEUX voies. (1) Passerelle curatée
-- (COC.Route:Gateway) = un LIVRE de rang acheté chez un PNJ (Premiers soins) → icône + nom + prix +
-- vendeur. (2) Sinon, palier supérieur présent dans les données (HasHigherTier) mais entraîné au
-- FORMATEUR (Joaillerie & co) → « entraîne le rang supérieur » + le PNJ formateur (MTSL). Rien si ni
-- l'un ni l'autre (vrai maximum). PNJ/faction résolus par MTSL, repli texte sans lui. Renvoie le y.
function PW:_FillRouteGateway(f, used, y, route)
    local U, R = COC.UI, COC.Route
    if not (route and U and U._NeedsTextLine and R) then return y end
    local g = R.Gateway and R:Gateway(self.profKey, route.rank)
    local higher = R.HasHigherTier and R:HasHigherTier(self.profKey, route.rank)
    if not (g or higher) then return y end
    y = U:_NeedsTextLine(f, used, y + 8, "|cFFE8B84B" .. L["Débloquer le palier suivant"] .. "|r")
    if g then
        local nm = (g.item and COC.Api.GetItemInfo and COC.Api.GetItemInfo(g.item)) or g.name or L["Livre de rang"]
        local price = (g.price and g.price > 0) and (" — " .. COC.Api.Coin(g.price)) or ""
        y = U:_NeedsTextLine(f, used, y, "|TInterface\\Icons\\INV_Scroll_03:12:12|t |cFFEEDD88"
            .. string.format(L["À apprendre : %s"], nm) .. price .. "|r")
        -- La passerelle ne porte que des IDENTIFIANTS de PNJ, et aucune API ne rend le nom d'un PNJ
        -- depuis son id. On ne dit donc plus rien ici plutôt que de renvoyer vers un annuaire
        -- externe : la ligne « installe tel addon pour voir où » désignait MTSL, qui n'est plus
        -- maintenu et dont la base décrit un autre jeu que Forever.
    else
        y = U:_NeedsTextLine(f, used, y, "|cFF88CCFF"
            .. L["Entraîne le rang supérieur chez ton formateur de métier."] .. "|r")
        local ln = nextTrainerLine(self.profKey, route.rank)
        if ln then y = U:_NeedsTextLine(f, used, y, "|cFF888888" .. string.format(L["Formateur : %s"], ln) .. "|r") end
    end
    return y
end
