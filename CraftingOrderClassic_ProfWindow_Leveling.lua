-- CraftingOrderClassic_ProfWindow_Leveling.lua — aide à la MONTÉE DE MÉTIER dans la liste de
-- recettes : coût de progression (réactifs au prix Lazy Gold ÷ chance de point selon la couleur),
-- badge « meilleur coût/point » sur la recette recommandée, icônes de SOURCE sur les manquantes
-- (formateur / vendeur PNJ / coté à l'HV / à farmer) et tri « progression » affiné par coût.
-- Les guides statiques se trompent quand l'économie du serveur diverge (vécu : shards à 10 pc alors
-- que le guide dit d'acheter de la dust) — ici tout est au prix RÉEL (Auctionator via Lazy Gold).
-- Tout est soft-dep : sans Lazy Gold le coût disparaît (les icônes de source restent, MTSL suffit) ;
-- sans MTSL, pas d'icônes (les manquantes n'existent pas). Appelé par _ProfWindow_Recipes sous garde
-- nil (`self._FillLevelingRight and …`) : l'absence de ce fichier ne casse rien.

local COC = CraftingOrderClassic
local PW  = COC.ProfWindow
local L   = COC.L

-- Chance ESTIMÉE de gagner un point par craft, par couleur (orange = garanti ; jaune/vert décroissent).
-- Les vrais seuils jaune/gris PAR recette n'existent dans aucune source locale → paliers assumés,
-- affichés comme « estimation ». Gris/inconnu : aucun point, exclu (pas d'entrée dans la table).
local CHANCE = { optimal = 1.0, medium = 0.75, easy = 0.25 }

-- Icônes NATIVES (gossip, déjà dans le client — aucun asset à livrer). Langage : où va ce plan ?
local ICON = {
    trainer = "Interface\\GossipFrame\\TrainerGossipIcon",       -- à apprendre au formateur
    vendor  = "Interface\\GossipFrame\\VendorGossipIcon",        -- à acheter chez un vendeur PNJ
    ah      = "Interface\\GossipFrame\\BankerGossipIcon",        -- l'objet-plan est coté à l'HV
    farm    = "Interface\\GossipFrame\\BattleMasterGossipIcon",  -- butin/quête absent de l'HV : à farmer
    best    = "Interface\\GossipFrame\\AuctioneerGossipIcon",    -- recommandation « moins cher au point »
}

-- Couleur d'une MANQUANTE au rang courant. D'abord les seuils RÉELS par recette (CraftLink
-- skillColors, source Wowhead — ex. Red Linen Vest {55,80,97,115} : gris dès 115) ; en repli
-- (recette hors base, ex. Poisons Vanilla) une ESTIMATION par distance rang − niveau requis
-- (patron vanilla typique jaune ≈ +20 / vert ≈ +30 / gris ≈ +40, bornes prudentes côté orange).
-- nil = pas encore apprenable OU grise — aucun point à en tirer, donc jamais recommandée
-- (bug 2026-07-17 : plan niv. 55 conseillé en tête à un rang 244).
local MISS_STEPS = { { 10, "optimal" }, { 25, "medium" }, { 40, "easy" } }
function PW:_MissingDifficulty(e)
    if not e.isMissing then return nil end
    local rank = COC.Craft and COC.Craft:OpenRank()
    if not (rank and (e.level or 0) <= rank) then return nil end
    local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    local c = lib and lib.RecipeColors and lib:RecipeColors(self.profKey, e.spellID)
    if c then
        if rank >= c[4] then return nil          -- gris : plus aucun point
        elseif rank >= c[3] then return "easy"   -- vert
        elseif rank >= c[2] then return "medium" -- jaune
        else return "optimal" end                -- orange (apprenable, donc rang >= requis)
    end
    local d = rank - (e.level or 0)
    for _, s in ipairs(MISS_STEPS) do
        if d <= s[1] then return s[2] end
    end
    return nil
end

-- Une MANQUANTE vaut le conseil « va acheter ce plan » si elle est apprenable MAINTENANT **et** pas
-- grise estimée. Garde le filtre skill-up ET l'injection du tri progression (cf. _RecipeDisplayList /
-- _ActiveRecipes — appels sous garde nil : ce fichier est soft-dep).
function PW:_MissingProgresses(e)
    return self:_MissingDifficulty(e) ~= nil
end

-- Coût de progression d'une entrée : { perPoint, cost, chance, missing } en cuivre, ou nil (gris —
-- réel ou estimé —, prix inconnus, Lazy Gold absent, manquante pas encore apprenable…). missing = un
-- réactif sans prix (coût sous-estimé). Cache par refresh (posé dans RefreshRecipes, le rendu se
-- rejoue à chaque scroll).
function PW:_LevelCost(e)
    if e.isHeader or not (COC.LazyGold and COC.LazyGold:IsAvailable()) then return nil end
    self._lvlCache = self._lvlCache or {}
    local k = e.spellID or e.itemID or 0
    local v = self._lvlCache[k]
    if v ~= nil then return v or nil end
    local chance
    if e.isMissing then
        local d = self:_MissingDifficulty(e)   -- couleur estimée ; nil = grise / pas apprenable
        chance = d and CHANCE[d] or nil
    else
        chance = CHANCE[e.difficulty]
    end
    local c = chance and COC.LazyGold:EntryCost(self.profKey, e)
    v = c and { perPoint = c.cost / chance, cost = c.cost, chance = chance, missing = c.missing } or false
    self._lvlCache[k] = v
    return v or nil
end

-- Recommandation « à crafter pour monter » : l'entrée au meilleur coût/point de la liste AFFICHÉE
-- (connues non grises + manquantes apprenables NON grises estimées = « va acheter ce plan »).
-- Recalculée à chaque refresh (RefreshRecipes) ; nil si rien de calculable.
function PW:_ComputeLevelBest()
    self._lvlBest = nil
    if not (COC.LazyGold and COC.LazyGold:IsAvailable()) then return end
    local best, bestPer
    for _, e in ipairs(self.recDisplay or {}) do
        if not e.isHeader then
            local c = self:_LevelCost(e)
            if c and (not bestPer or c.perPoint < bestPer) then best, bestPer = e, c.perPoint end
        end
    end
    self._lvlBest = best
end

-- Icône de source d'une MANQUANTE : où obtenir le plan, d'un coup d'œil (le détail PNJ vit dans le
-- panneau d'info au clic). « ah » = l'objet-plan est coté à l'HV en ce moment (dernier scan
-- Auctionator) ; butin/quête hors HV = « à farmer ». nil si source inconnue (pas de fausse icône).
function PW:_MissingSourceIcon(e)
    local M = COC.MTSL
    if not (M and M:IsAvailable() and e.spellID) then return nil end
    local kind = M:SourceKind(self.profKey, e.spellID)
    if kind == "trainer" then return ICON.trainer end
    if kind == "vendor" then return ICON.vendor end
    if kind == "unknown" then return nil end
    local LG = COC.LazyGold
    local recItemID = M:RecipeItem(self.profKey, e.spellID)
    if LG and LG:IsAvailable() and recItemID and LG:ItemValue(recItemID) then return ICON.ah end
    return ICON.farm
end

-- Zone droite d'une ligne : icône de source (manquantes) + badge « meilleur coût/point ». Textures
-- créées à la demande sur la ligne du pool. Renvoie la nouvelle ancre (chaîne droite→gauche de
-- _FillRecipeRight) — ou l'ancre reçue si rien d'affiché.
function PW:_FillLevelingRight(row, e, anchor)
    if not row.srcTex then
        row.srcTex = row:CreateTexture(nil, "ARTWORK"); row.srcTex:SetSize(14, 14)
        row.lvlTex = row:CreateTexture(nil, "ARTWORK"); row.lvlTex:SetSize(14, 14)
    end
    local function put(tex, icon)
        tex:SetTexture(icon); tex:ClearAllPoints()
        if anchor then tex:SetPoint("RIGHT", anchor, "LEFT", -4, 0) else tex:SetPoint("RIGHT", row, "RIGHT", -2, 0) end
        tex:Show(); anchor = tex
    end
    local icon = e.isMissing and self:_MissingSourceIcon(e) or nil
    if icon then put(row.srcTex, icon) else row.srcTex:Hide() end
    if self._lvlBest and self._lvlBest == e then put(row.lvlTex, ICON.best) else row.lvlTex:Hide() end
    return anchor
end

-- Lignes « progression » du tooltip de ligne (survol) : coût/point estimé, recommandation, et pour
-- une manquante la destination du plan. Silencieux quand rien n'est calculable.
function PW:_LevelingTooltip(e)
    local c = self:_LevelCost(e)
    if c then
        local per = GetCoinTextureString(math.max(1, math.floor(c.perPoint + 0.5)))
        local q = c.missing and " |cFF888888(?)|r" or ""
        GameTooltip:AddLine(string.format(L["Progression : ~%s par point (estimation)"], per) .. q, 0.60, 0.75, 0.91)
        if self._lvlBest == e then
            GameTooltip:AddLine("|T" .. ICON.best .. ":12:12:0:0|t " .. L["Meilleur coût/point pour monter le métier"], 1, 0.82, 0.25)
        end
    end
    if e.isMissing then self:_PlanTooltip(e) end
end

-- Destination du plan d'une manquante (tooltip) : formateur / vendeur PNJ (prix fixe MTSL), coté à
-- l'HV (cote Lazy Gold), ou à farmer. Même logique que l'icône de source — les deux doivent raconter
-- la même histoire.
function PW:_PlanTooltip(e)
    local M = COC.MTSL
    if not (M and M:IsAvailable() and e.spellID) then return end
    local kind = M:SourceKind(self.profKey, e.spellID)
    if kind == "unknown" then return end
    local price = M:SourcePrice(self.profKey, e.spellID)
    local ptxt = price and (" — " .. GetCoinTextureString(price)) or ""
    local txt
    if kind == "trainer" then txt = string.format(L["Plan : au formateur%s"], ptxt)
    elseif kind == "vendor" then txt = string.format(L["Plan : chez un vendeur PNJ%s"], ptxt)
    else
        local LG = COC.LazyGold
        local recItemID = M:RecipeItem(self.profKey, e.spellID)
        local ah = LG and LG:IsAvailable() and recItemID and LG:ItemValue(recItemID)
        if ah then txt = string.format(L["Plan : coté à l'HV — %s"], GetCoinTextureString(ah))
        else txt = L["Plan : à farmer (butin/quête — absent de l'HV)"] end
    end
    GameTooltip:AddLine(txt, 0.91, 0.72, 0.29)
end

-- Diagnostic « /co lvldump » : imprime, pour chaque recette AFFICHÉE, les valeurs exactes que le
-- badge « meilleur coût/point » vient de comparer (difficulté live, chance, coût catalogue, coût/pt).
-- Sert à élucider un désaccord badge ↔ Plan de route sans deviner l'état live (vécu 2026-07-18 :
-- badge sur Simple Pearl Ring, route sur Ring of Twilight Shadows). Sortie console technique.
function PW:_LevelDump()
    print("|cFF33DD88COC|r lvldump — " .. tostring(self.profKey)
        .. " | rank=" .. tostring(COC.Craft and COC.Craft:OpenRank())
        .. " | best=" .. ((self._lvlBest and self._lvlBest.name) or "nil"))
    for _, e in ipairs(self.recDisplay or {}) do
        if not e.isHeader then
            local diff = e.isMissing and ("miss:" .. tostring(self:_MissingDifficulty(e))) or tostring(e.difficulty)
            local c = self:_LevelCost(e)
            print(string.format("  %s | %s | sid=%s it=%s | %s",
                e.name or "?", diff, tostring(e.spellID), tostring(e.itemID),
                c and string.format("cost=%d chance=%.2f perPt=%d%s",
                        c.cost, c.chance, c.perPoint, c.missing and " PRIX-PARTIEL" or "")
                  or "exclu (coût ou chance nil)"))
        end
    end
end

-- Tri « progression » affiné : orange < jaune < vert < gris < inconnu < manquantes grises, puis
-- coût/point CROISSANT dans un même rang (coût inconnu en fin de rang), puis A-Z. Une manquante
-- apprenable est classée à sa COULEUR ESTIMÉE (retour user 2026-07-17 : le conseil « va acheter ce
-- plan » doit remonter — mais à sa vraie place : un plan niv. 55 à rang 244 est GRIS, pas orange) ;
-- les autres manquantes ferment la marche. LA réponse à « quoi crafter là, tout de suite, au moins cher ».
local DIFF_RANK = { optimal = 1, medium = 2, easy = 3, trivial = 4 }
local function levelRank(pw, e)
    if e.isMissing then
        local d = pw:_MissingDifficulty(e)
        return d and DIFF_RANK[d] or 6
    end
    return DIFF_RANK[e.difficulty] or 5
end

function PW:_ProgressionLess(a, b)
    local ra, rb = levelRank(self, a), levelRank(self, b)
    if ra ~= rb then return ra < rb end
    local ca, cb = self:_LevelCost(a), self:_LevelCost(b)
    local pa = ca and ca.perPoint or math.huge
    local pb = cb and cb.perPoint or math.huge
    if pa ~= pb then return pa < pb end
    return (a.name or "") < (b.name or "")
end
