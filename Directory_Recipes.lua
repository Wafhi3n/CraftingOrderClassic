-- Directory_Recipes.lua — COUTURE de lecture du registre « qui sait crafter quoi » d'un artisan.
--
-- Pourquoi. Le registre reçu peut prendre DEUX formes selon la saveur de l'émetteur :
--   * BITFIELD (verbe RK) — positions de bits dans le catalogue partagé. N'a de sens que si les
--     deux bouts ont EXACTEMENT le même catalogue, d'où le `dataVersion` sur le fil.
--   * IDENTIFIANTS (verbe RI, Camelot / WoW: Forever) — les recipeID eux-mêmes. Auto-descriptif,
--     aucune version à faire concorder (cf. CraftLink_RegistryIDs.lua).
--
-- Avant cette couture, la garde `r.recipeDV == lib:DataVersion()` était RECOPIÉE dans quatre
-- modules (Handoff, LazyGold, UI_Artisans_Needs, UI_Post_Artisans), chacun appelant `HasBit`
-- directement. Ajouter une seconde forme y aurait ajouté quatre branchements — et la prochaine
-- forme, quatre de plus. Ici les appelants posent une QUESTION (« connaît-il cette recette ? ») et
-- ignorent la réponse à « sous quelle forme est-ce stocké ».
--
-- Même philosophie que la table d'API du socle métier (`*_Craft.lua`) : un seul endroit sait que
-- les saveurs divergent.
--
-- NB : les deux jeux étant séparés (un client Camelot ne parle qu'à des clients Camelot), un même
-- roster ne mélange pas les formes en pratique. La couture reste écrite pour les deux — c'est ce
-- qui la rend indépendante de cette hypothèse.

local COC = CraftingOrderClassic
local Dir = COC.Directory
if not Dir then return end

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

-- Quelle forme exploitable porte cette fiche pour ce métier ?
-- Rend (forme, donnée) : "ids"+payload, "bits"+hex, ou nil si rien n'est utilisable.
--
-- Les IDs passent EN PREMIER : ils ne dépendent d'aucun catalogue, donc ils sont toujours lisibles.
-- Le bitfield, lui, n'est rendu QUE si les catalogues concordent — sinon les positions désignent
-- d'autres recettes et on afficherait du faux. C'est la garde historique, désormais à un seul
-- endroit : un écart de version donne « pas de données », jamais une mauvaise réponse.
function Dir:RecipeForm(r, prof)
    if not (r and prof) then return nil end
    local payload = r.recipeIDs and r.recipeIDs[prof]
    if payload and payload ~= "" then return "ids", payload end
    local hex = r.recipes and r.recipes[prof]
    if not (hex and hex ~= "") then return nil end
    local c = CL()
    if c and c.DataVersion and r.recipeDV == c:DataVersion() then return "bits", hex end
    return nil
end

-- Prédicat « ce joueur connaît-il cette recette ? », ou nil si aucune donnée exploitable.
-- Rendre nil PLUTÔT qu'un prédicat toujours faux est délibéré : l'appelant doit pouvoir
-- distinguer « il ne la connaît pas » de « je n'en sais rien » — les deux ne s'affichent pas pareil.
function Dir:RecipeTester(r, prof)
    local form, data = self:RecipeForm(r, prof)
    local c = CL()
    if not (form and c) then return nil end
    if form == "ids" then
        if not c.HasRecipeID then return nil end
        return function(spellID) return c:HasRecipeID(data, spellID) end
    end
    if not c.HasBit then return nil end
    return function(spellID) return c:HasBit(prof, data, spellID) end
end

-- Le set des recettes connues { [spellID] = true }, ou nil si rien d'exploitable.
-- Pour ÉNUMÉRER (bourse, plan de route), pas pour tester une recette — dans ce cas utiliser
-- RecipeTester, qui ne décode rien quand la réponse tient en un bit.
-- Les deux codecs rendent déjà la même forme, l'unification est donc gratuite.
function Dir:RecipeKnownSet(r, prof)
    local form, data = self:RecipeForm(r, prof)
    local c = CL()
    if not (form and c) then return nil end
    if form == "ids" then
        return c.DecodeKnownIDs and c:DecodeKnownIDs(data) or nil
    end
    return c.DecodeKnown and c:DecodeKnown(prof, data) or nil
end

-- Y a-t-il de quoi répondre pour ce métier ? (gardes de validité, avant un travail coûteux)
function Dir:HasRecipeData(r, prof)
    return (self:RecipeForm(r, prof)) ~= nil
end

-- Clé de cache : change dès que la donnée change, quelle que soit la forme. La forme est dans la
-- clé — deux registres de formes différentes ne doivent jamais se répondre l'un pour l'autre.
function Dir:RecipeFingerprint(r, prof)
    local form, data = self:RecipeForm(r, prof)
    if not form then return nil end
    return form .. "|" .. tostring(prof) .. "|" .. data
end

-- ------------------------------------------------------------------
-- Le FIL : quelle forme j'émets, et comment je reçois l'autre
-- ------------------------------------------------------------------

-- Le message de registre à diffuser pour ce métier, ou nil si je n'ai rien à dire.
-- Sur Camelot on émet des IDENTIFIANTS (RI) : il n'y a pas de catalogue partagé à faire concorder,
-- et le contenu du jeu bouge encore. Ailleurs, le bitfield (RK) reste plus compact et le catalogue
-- est stable. Les deux jeux étant séparés, un client ne rencontre jamais l'autre forme en pratique.
function Dir:RecipeMessage(prof)
    local c = CL()
    if not (c and prof) then return nil end
    if COC.Api and COC.Api.IS_MAINLINE and c.BuildRI then return c:BuildRI(prof) end
    return c.BuildRK and c:BuildRK(prof) or nil
end

-- RI reçu (recettes d'un autre, forme identifiants) → cache roster persistant.
-- Miroir exact de Dir:OnRK, garde comprise : SK fait foi sur les métiers, donc un registre annoncé
-- pour un métier que l'émetteur ne déclare PAS est refusé. Sans ça, un perso pourrait faire passer
-- les recettes d'un de ses alts pour les siennes — trou déjà fermé une fois côté RK, à ne pas
-- rouvrir en ajoutant un second verbe.
function Dir:OnRI(sender, message)
    local c = CL()
    if not (sender and c and c.ParseRI) then return end
    local prof, payload = c:ParseRI(message)
    if not prof then return end
    local r = self.roster[sender]; if not r then r = {}; self.roster[sender] = r end
    if r.skill and next(r.skill) and not r.skill[prof] then return end  -- anti fuite d'alts
    r.recipeIDs = r.recipeIDs or {}
    r.recipeIDs[prof] = payload
    self:_ApplySource(sender, r)          -- guilde/ami si reconnu, sinon « recent »
    r.lastSeen = time()
    self.online[sender] = true            -- présence passive : un message prouve la présence
    self:_NoteLinked(sender, r)
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
end

-- Ce joueur a-t-il UN registre quelconque pour ce métier, même illisible ? Sert aux replis qui se
-- contentent de savoir qu'il exerce ce métier (sans prétendre connaître ses recettes).
function Dir:HasAnyRecipeRecord(r, prof)
    if not (r and prof) then return false end
    return ((r.recipes and r.recipes[prof]) or (r.recipeIDs and r.recipeIDs[prof])) ~= nil
end
