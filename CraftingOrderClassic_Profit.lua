-- CraftingOrderClassic_Profit.lua — pont LECTURE SEULE vers l'oracle de prix, AUCTIONATOR.
-- Spec : docs/specs/prix-maison.md.
--
-- BUT : afficher la RENTABILITÉ d'une recette dans la vue métier — prix de vente à l'HV, coût des
-- réactifs, profit net. On ne collecte PAS de prix nous-mêmes : le scan de l'hôtel des ventes est le
-- métier d'Auctionator, on lit son API publique.
--
-- DÉPENDANCE MOLLE : COC reste autonome. Sans oracle, `IsAvailable()` est faux, les sections d'argent
-- ne s'affichent pas et un clic sur un bouton de prix dit QUOI installer — aucun plantage, et jamais
-- un « 0 » qui se lirait comme « ça ne rapporte rien ».
--
-- UN SEUL ORACLE depuis le 2026-09-22 (décision du user). Le pont vers **Auctionator Classic** a été
-- retiré : il ne calculait rien, il relisait Auctionator. Deux ponts pour la même donnée, c'était un
-- de trop — et le pied de fenêtre pouvait nommer « Auctionator » un chiffre venu d'ailleurs. Auctionator
-- n'existait de toute façon que sur Classic Era, purgée de `main` depuis le 2026-09-21.
--
-- PRIMITIVES LUES :
--   Auctionator.API.v1.GetVendorPriceByItemID(id, itemID) -> prix d'ACHAT chez le PNJ, par unité,
--       relevé à la visite d'un marchand à stock illimité (Source/CraftingInfo/Main.lua) — donc bien
--       un coût d'approvisionnement, pas le prix de rachat. nil tant qu'aucun marchand n'a été vu.
--   Auctionator.API.v1.GetAuctionPriceByItemID(id, itemID) -> prix HV scanné, nil si jamais scanné.
-- L'API d'Auctionator LÈVE (error) sur un callerID vide ou un argument mal typé : tout passe en pcall.
--
-- Le COÛT des réactifs et l'objet produit viennent de NOS données CraftLink (RecipeReagents/RecipeProduct),
-- pas des tables de PR : on reste maître de la recette, PR ne sert QUE d'oracle de prix.

local COC = CraftingOrderClassic
local PR  = {}
COC.Profit = PR

-- Coupe de l'hôtel des ventes (5 %). EN DUR, et c'est un choix (arbitrage 11 de la spec
-- rentabilite-forever) : c'est une constante du jeu, pas une préférence — un réglage de plus ne
-- paierait pas sa place. On l'EXPOSE en revanche, pour que le détail du calcul l'affiche : sans elle,
-- vente − réactifs ne retombe pas sur le net, et le joueur cherche d'où vient l'écart.
local AH_CUT = 0.05
PR.AH_CUT = AH_CUT

-- Nom d'appelant exigé par l'API d'Auctionator (elle lève sur une chaîne vide).
local CALLER = "CraftingOrderClassic"

local function auctionator()
    local a = _G.Auctionator
    local v1 = a and a.API and a.API.v1
    return (type(v1) == "table" and type(v1.GetAuctionPriceByItemID) == "function") and v1 or nil
end

-- L'oracle de prix répond-il ?
function PR:IsAvailable()
    return auctionator() ~= nil
end

-- Le NOM D'AFFICHAGE de l'oracle, ou nil s'il n'est pas là. Un pied de fenêtre qui nomme la source
-- envoie chercher au bon endroit le jour où un prix semble faux.
function PR:PriceSource()
    return auctionator() and "Auctionator" or nil
end

-- Ce qu'on DIT au joueur quand une vue d'argent reste vide. Deux causes, deux phrases : un panneau
-- vide a longtemps conseille « scanne l'HV » a quelqu'un qui n'avait meme pas Auctionator installe,
-- donc on l'envoyait faire une chose impossible (vu au banc le 2026-09-23). La vue n'a pas a
-- refaire ce diagnostic : elle demande la phrase, c'est tout.
function PR:NoPriceMessage()
    local L = COC.L
    if not self:IsAvailable() then return L["Auctionator n'est pas là — sans lui, COC n'estime aucun prix."] end
    return L["Rien à calculer — scanne l'HV (Auctionator) puis rouvre ce panneau."]
end

-- Prix d'un objet ET sa provenance ("vendor" | "ah"), ou nil. Ordre VENDEUR puis HV dans les deux
-- chemins : un réactif vendu à prix fixe en ville ne doit jamais être valorisé au cours de l'HV,
-- sinon toute la route se trompe de recette. Côté VENTE, le même ordre fait du prix marchand un
-- PLAFOND honnête : si un PNJ vend l'objet, personne ne le paiera plus cher à l'HV (arbitrage 10).
-- Locale et à deux retours : seul CraftProfit a besoin de la provenance, et un second retour qui
-- fuirait d'ItemValue dans la liste d'arguments d'un appelant (`Coin(PR:ItemValue(id))`) y
-- deviendrait un paramètre de trop.
local function priceOf(itemID)
    if not itemID then return nil end
    local v1 = auctionator()
    if not v1 then return nil end
    local ok, price = pcall(v1.GetVendorPriceByItemID, CALLER, itemID)
    if ok and type(price) == "number" and price > 0 then return price, "vendor" end
    ok, price = pcall(v1.GetAuctionPriceByItemID, CALLER, itemID)
    if ok and type(price) == "number" and price > 0 then return price, "ah" end
    return nil
end

-- Prix d'un objet en cuivre (vendeur ou HV), ou nil si aucun oracle ne le connaît. UN seul retour.
function PR:ItemValue(itemID)
    return (priceOf(itemID))
end

-- Objet vendu par un PNJ (prix fixe) ? Sert à la bourse d'artisan : un composant vendeur ne vaut pas
-- d'être fourni, l'artisan l'achètera en ville (retour user 2026-07-19 : Coarse Thread / Red Dye
-- encombraient la grille).
-- Auctionator ne répond que pour les marchands DÉJÀ VISITÉS : sa réponse est sûre quand elle est
-- positive, muette sinon. On ne comble pas ce trou par une devinette — au pire un composant vendeur
-- reste dans la grille, ce qui est l'état d'avant la feature.
function PR:IsVendorItem(itemID)
    if not itemID then return false end
    local v1 = auctionator()
    if not v1 then return false end
    local ok, price = pcall(v1.GetVendorPriceByItemID, CALLER, itemID)
    return (ok and type(price) == "number" and price > 0) and true or false
end

-- ---------------------------------------------------------------------------
-- Diagnostic « /co pricedump »
-- ---------------------------------------------------------------------------
-- Pourquoi ça existe. Une route dont tous les coûts valent 0 et qui s'affiche « partielle » a
-- DEUX causes indiscernables à l'œil : l'oracle ne répond pas (mauvais addon, base non initialisée,
-- API renommée), ou il répond honnêtement que l'hôtel des ventes ne connaît pas ces objets (serveur
-- jeune, rien en vente). La première est un bug chez nous, la seconde n'en est pas un — et rien à
-- l'écran ne les sépare. Cette sortie console les sépare en une ligne. Texte technique non
-- localisé, comme /co lvldump.
local function dumpItem(itemID)
    local nm = COC.Api and COC.Api.GetItemInfo and COC.Api.GetItemInfo(itemID)
    local v1 = auctionator()
    local vend, ah
    if v1 then
        local ok, p2 = pcall(v1.GetVendorPriceByItemID, CALLER, itemID); vend = ok and p2 or nil
        local ok2, p3 = pcall(v1.GetAuctionPriceByItemID, CALLER, itemID); ah = ok2 and p3 or nil
    end
    print(string.format("  %-28s id=%-7d vendeur=%-12s HV=%-12s -> %s",
        tostring(nm or "?"), itemID,
        vend and COC.Api.Coin(vend) or "nil", ah and COC.Api.Coin(ah) or "nil",
        PR:ItemValue(itemID) and COC.Api.Coin(PR:ItemValue(itemID)) or "AUCUN PRIX"))
end

-- Réactifs DISTINCTS du métier ouvert, dans l'ordre des recettes, plafonnés (la console n'est pas
-- un rapport) — ce sont exactement les objets dont dépend le coût de la route.
local function openProfReagents(limit)
    local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    local prof = COC.Craft and COC.Craft:OpenProfessionKey()
    if not (lib and prof and lib.GetRecipes) then return nil, prof end
    local seen, out = {}, {}
    for _, sid in ipairs(lib:GetRecipes(prof) or {}) do
        for _, r in ipairs((lib.RecipeReagents and lib:RecipeReagents(prof, sid)) or {}) do
            if r[1] and not seen[r[1]] then
                seen[r[1]] = true; out[#out + 1] = r[1]
                if #out >= limit then return out, prof end
            end
        end
    end
    return out, prof
end

function PR:PriceDump(arg)
    local src = self:PriceSource()
    local v1 = auctionator()
    print("|cFF33DD88COC|r pricedump — oracle=" .. tostring(src or "AUCUN")
        .. " | Auctionator.API=" .. tostring(v1 ~= nil)
        .. " | base de prix=" .. tostring(v1 ~= nil and _G.Auctionator.Database ~= nil))
    local id = tonumber(arg) or (type(arg) == "string" and tonumber(arg:match("|Hitem:(%d+)"))) or nil
    if id then return dumpItem(id) end
    local ids, prof = openProfReagents(12)
    if not ids then print("  aucun métier ouvert (prof=" .. tostring(prof) .. ") — donne un itemID ou un lien d'objet") return end
    print("  réactifs de " .. tostring(prof) .. " :")
    for _, itemID in ipairs(ids) do dumpItem(itemID) end
end

-- Icônes NATIVES (textures du jeu, pas de fichier à embarquer). L'étoile « toast-star » marque les
-- gros profits (≥ 1000 po). Étoiles un peu plus grandes que les pièces pour ressortir.
local GOLD_ICON   = "|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:0:0|t"
local SILVER_ICON = "|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:0:0|t"
-- toast-star fait 32×32 mais l'étoile ne remplit que le coin HAUT-GAUCHE (contenu réel : x 0→21,
-- y 1→20). Sans découpe, on affiche surtout du vide et l'étoile part se coller en haut à gauche de sa
-- case. D'où la forme longue du escape : |T…:h:w:offX:offY:dimX:dimY:x1:x2:y1:y2|t (coords en TEXELS).
local STAR_ICON   = "|TInterface\\LootFrame\\toast-star:14:14:0:0:32:32:0:21:1:20|t"

-- Indicateur COMPACT de montant (pour les listes denses), par PALIER de magnitude :
--   0/nil → rien ; < 1 po → 1 pièce d'argent ; 1-10 po → 1 or ; 10-100 po → 2 or ; 100-1000 po → 3 or ;
--   1000-2000 → 1 ★ ; 2000-3000 → 2 ★ ; 3000-4000 → 3 ★ (max, pour ne pas surcharger) ;
--   ≥ 4000 po → valeur compacte « NK » (4K, 10K, 100K…). Valeur EXACTE au clic (détail) et au survol.
function PR:CoinTier(copper)
    local v = math.abs(math.floor((copper or 0) + 0.5))
    if v == 0 then return "" end
    local gold = v / 10000
    if gold < 1    then return SILVER_ICON end
    if gold < 10   then return GOLD_ICON end
    if gold < 100  then return GOLD_ICON .. GOLD_ICON end
    if gold < 1000 then return GOLD_ICON .. GOLD_ICON .. GOLD_ICON end
    if gold < 2000 then return STAR_ICON end
    if gold < 3000 then return STAR_ICON .. STAR_ICON end
    if gold < 4000 then return STAR_ICON .. STAR_ICON .. STAR_ICON end
    return "|cFFFFD100" .. math.floor(gold / 1000) .. "K|r"
end

-- Palier compact d'un PROFIT. Les PERTES ne s'affichent PAS (rien), et aucun signe +/- : seul un gain
-- positif est indiqué, par ses pièces/étoiles/valeur.
function PR:ProfitTier(copper)
    if not copper or copper <= 0 then return "" end
    return self:CoinTier(copper)
end

-- Mode d'affichage du profit dans les listes : compact (paliers de pièces) ou VALEUR EXACTE en
-- po/pa/pc. Préférence de lecture persistée (bouton « 123 » de la barre d'outils Recettes).
-- ⚠️ `lgExactProfit` garde son nom : c'est une clé PERSISTÉE dans la SavedVariable du joueur. La
-- renommer demanderait une migration de schéma pour un confort d'écriture, et perdrait le réglage de
-- ceux qui ne migreraient pas. Le nom d'une donnée sur disque n'est pas un détail de style.
function PR:ExactMode() return (COC.db and COC.db.lgExactProfit) and true or false end
function PR:SetExactMode(on) if COC.db then COC.db.lgExactProfit = on and true or false end end

-- Texte de profit d'une LIGNE de liste, selon le mode courant. Une perte n'affiche RIEN dans les
-- deux modes (cf. ProfitTier) : la liste ne sert qu'à repérer ce qui rapporte.
function PR:ProfitText(copper)
    if not copper or copper <= 0 then return "" end
    if self:ExactMode() then return COC.Api.Coin(copper) end
    return self:CoinTier(copper)
end

-- Montant formaté avec signe : « +3g 50s », « -1g », « 0 ». GetCoinTextureString n'accepte pas le
-- négatif → on formate la valeur absolue et on préfixe le signe et une couleur (vert/rouge).
function PR:Money(copper, colored)
    copper = math.floor((copper or 0) + 0.5)
    local sign = copper < 0 and "-" or "+"
    local body = COC.Api.Coin and COC.Api.Coin(math.abs(copper)) or tostring(math.abs(copper))
    local txt = sign .. body
    if not colored then return txt end
    local c = copper < 0 and "|cFFFF5555" or (copper > 0 and "|cFF33DD33" or "|cFF888888")
    return c .. txt .. "|r"
end

-- ---------------------------------------------------------------------------
-- SCHÉMA d'une recette : le CLIENT d'abord, NOS données ensuite
-- ---------------------------------------------------------------------------
-- Le calcul n'a jamais su faire que ce que la donnée lui permettait, et sur Camelot 357 recettes
-- n'ont AUCUN objet produit dans notre catalogue : pour elles la rentabilité ne pouvait pas exister,
-- quel que soit l'oracle de prix. Le client, lui, donne le schéma exact en direct (cf.
-- Craft:RecipeCraft). Pour une recette qu'il connaît, il fait donc FOI ; le catalogue reste le repli.
--
-- Arbitré CHAMP PAR CHAMP, jamais en bloc. Une réponse partielle du client (l'objet produit connu,
-- la liste de réactifs vide parce que la recette n'est pas dans la ligne ouverte) effacerait sinon
-- ce que le catalogue sait encore dire. Et une liste de réactifs VIDE n'est pas une réponse : c'est
-- une absence de réponse — un coût de zéro rendrait toute recette « rentable ».
local function recipeSchema(profKey, spellID)
    local lib  = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    local game = (COC.Craft and COC.Craft.RecipeCraft) and COC.Craft:RecipeCraft(spellID) or nil
    local reagents = (game and game.reagents and #game.reagents > 0) and game.reagents
        or (lib and lib.RecipeReagents and lib:RecipeReagents(profKey, spellID)) or {}
    return {
        productID = (game and game.productID)
            or (lib and lib.RecipeProduct and lib:RecipeProduct(profKey, spellID)) or nil,
        reagents = reagents,
        numMade  = game and game.numMade or nil,
    }
end

-- Coût d'une liste de réactifs { {itemID, qté}, … } : coût, `missing` (au moins un sans prix, donc
-- coût SOUS-estimé) et `priced` (au moins un avec prix). Un seul compteur pour les trois lectures
-- (profit, coût catalogue, coût client) : elles ne peuvent pas diverger sur la façon de compter.
local function reagentsCost(reagents)
    local cost, missing, priced = 0, false, false
    for _, reag in ipairs(reagents) do
        local p = PR:ItemValue(reag[1])
        if p then cost = cost + p * (reag[2] or 1); priced = true else missing = true end
    end
    return cost, missing, priced
end

-- Rentabilité d'une recette, en cuivre, ou nil si le prix de VENTE du produit est inconnu (sans lui,
-- aucun calcul n'a de sens) :
--   sell (unitaire) · sellSrc ("vendor" | "ah") · gross (= sell × lot) · cut (coupe HV sur gross)
--   cost · missing (au moins un réactif sans prix : coût sous-estimé) · profit · numMade
-- Formule, inchangée depuis l'origine : vente × quantité × (1 − coupe HV) − coût des réactifs.
function PR:CraftProfit(profKey, spellID, numMade)
    if not (self:IsAvailable() and profKey and spellID) then return nil end
    local sch = recipeSchema(profKey, spellID)
    local sell, sellSrc = priceOf(sch.productID)
    if not sell then return nil end
    local cost, missing = reagentsCost(sch.reagents)

    -- Quantité produite : ce que l'APPELANT sait prime (une ligne de liste la porte déjà, lue sur
    -- la même session de métier), puis ce que le client dit du lot, puis 1.
    local n = numMade or sch.numMade
    n = (n and n > 0) and n or 1
    local gross = sell * n
    local profit = gross * (1 - AH_CUT) - cost
    return { sell = sell, sellSrc = sellSrc, gross = gross, cut = gross * AH_CUT,
             cost = cost, profit = profit, missing = missing, numMade = n }
end

-- Coût de LANCER une recette, lu comme CraftProfit (le client d'abord, le catalogue ensuite) :
-- { cost, missing }, ou nil si aucun réactif n'a de prix. Pas besoin d'un prix de vente : c'est la
-- lecture de l'Enchantement, dont les recettes sont des services sans objet produit (arbitrage 12).
-- Distincte de CraftCost, qui lit le catalogue SEUL pour la montée de métier et la bourse d'artisan,
-- deux chantiers clos et validés en jeu : leur changer de source n'est pas une retouche en passant
-- (décision 8 de la spec).
function PR:RecipeCost(profKey, spellID)
    if not (self:IsAvailable() and profKey and spellID) then return nil end
    local cost, missing, priced = reagentsCost(recipeSchema(profKey, spellID).reagents)
    if not priced then return nil end
    return { cost = cost, missing = missing }
end

-- Résout le spellID d'une entrée de recette : direct (recettes manquantes) ou via l'objet produit
-- (recettes apprises, indexées par index d'API — on retrouve le sort par itemToSpell CraftLink).
local function entrySpell(profKey, entry)
    if not entry then return nil end
    if entry.spellID then return entry.spellID end
    if not entry.itemID then return nil end
    local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    local i2s = lib and lib.ItemToSpell and lib:ItemToSpell(profKey)
    return i2s and i2s[entry.itemID]
end

-- Profit d'une ENTRÉE de recette (résout le spellID toute seule), ou nil. Pour la liste de gauche et
-- le tri par rentabilité — même calcul que CraftProfit. numMade lu sur l'entrée si connu.
function PR:EntryProfit(profKey, entry)
    local spellID = entrySpell(profKey, entry)
    if not spellID then return nil end
    local p = self:CraftProfit(profKey, spellID, entry and entry.numMade)
    return p and p.profit or nil
end

-- Coût des seuls RÉACTIFS d'une recette : { cost, missing } en cuivre, ou nil si aucun réactif n'est
-- pricé / recette hors catalogue. Contrairement à CraftProfit, PAS besoin du prix de vente du produit
-- — les enchants (services sans objet produit) ont donc aussi un coût. Sert au coût de PROGRESSION
-- (montée de métier, cf. _ProfWindow_Leveling), pas à la rentabilité.
function PR:CraftCost(profKey, spellID)
    if not (self:IsAvailable() and profKey and spellID) then return nil end
    local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    local reags = lib and (lib.RecipeReagents and lib:RecipeReagents(profKey, spellID)) or {}
    local cost, missing, priced = reagentsCost(reags)
    if not priced then return nil end
    return { cost = cost, missing = missing }
end

-- Coût réactifs d'une ENTRÉE de liste (résout le spellID comme EntryProfit), ou nil.
function PR:EntryCost(profKey, entry)
    local spellID = entrySpell(profKey, entry)
    if not spellID then return nil end
    return self:CraftCost(profKey, spellID)
end

-- Seuil de mise en avant (configurable) : par défaut 10 po. Les paliers en découlent (×10, ×100).
function PR:MinProfit()
    local db = COC.db
    return (db and tonumber(db.lgMinProfit)) or (10 * 10000)
end

-- Palier de mise en avant d'un profit : 0 = rien, 2 = or (≥ seuil), 3 = or + halo (≥ seuil ×100).
-- Avec le défaut (seuil 10 po) : doré dès 10 po, doré + halo à 1000 po.
-- On allume dès qu'il y a un plan LUCRATIF (≥ seuil), pas seulement l'élite : un métier avec un plan à
-- 30 po est utile à voir, même s'il n'est pas le plus rentable du roster. Le seuil de base (db.lgMinProfit)
-- filtre le bruit — le monter éteint les petits profits. La COULEUR reste toujours dorée (pas d'argent).
-- (Les numéros 2/3 sont conservés — TIER_COLOR et les vues sont indexées dessus.)
function PR:HighlightTier(profit)
    if not profit or profit <= 0 then return 0 end
    local m = self:MinProfit()
    if profit >= m * 100 then return 3 end
    if profit >= m       then return 2 end
    return 0
end

-- Habillage du CONTOUR de mise en avant (données, pas d'UI — plusieurs vues le réutilisent).
-- La planche IconAlert (128×256) contient 3 sprites empilés : un HALO large (haut), un contour DORÉ
-- (milieu) et un contour BLANC (bas). On n'utilise que le BLANC — il se teinte à volonté (argent/or) —
-- plus le HALO en additif pour le palier du haut. Coords en fractions de la planche.
PR.ALERT_TEX    = "Interface\\SpellActivationOverlay\\IconAlert"
PR.ALERT_BORDER = { 0.078125, 0.4375, 0.5703125, 0.75 }        -- contour blanc, teintable
PR.ALERT_GLOW   = { 0.015625, 0.609375, 0.0078125, 0.265625 }  -- halo (palier 3)
PR.TIER_COLOR   = {                                            -- teinte du contour par palier
    [1] = { 0.78, 0.82, 0.90 },   -- argent
    [2] = { 1.00, 0.82, 0.25 },   -- or
    [3] = { 1.00, 0.82, 0.25 },   -- or + halo
}

-- Le DÉTAIL d'un résultat de CraftProfit, ligne par ligne { label, value }, de sorte qu'il se
-- RECOMPTE à l'œil : vente − coupe − réactifs = net. Deux choses qu'il doit dire (arbitrages 10 et
-- 11 de la spec rentabilite-forever) : d'où vient le prix de vente — un prix MARCHAND affiché sous
-- « Vente HV » passerait pour faux auprès de qui voit l'HV afficher autre chose — et la coupe de
-- l'HV, sans laquelle le compte ne tombe pas juste. La vente est le BRUT du lot : un prix unitaire
-- suivi de « ×2 » se lirait comme un total, et le compte ne tomberait plus juste non plus.
function PR:ProfitLines(p)
    local L = COC.L
    local sellLbl = (p.sellSrc == "vendor") and L["Vente (prix marchand)"] or L["Vente HV"]
    if (p.numMade or 1) > 1 then sellLbl = sellLbl .. " ×" .. p.numMade end
    local costVal = self:Money(-p.cost, true)
    if p.missing then costVal = costVal .. " |cFF888888(?)|r" end   -- un réactif sans prix : coût partiel
    local pct = math.floor(AH_CUT * 100 + 0.5)
    return {
        { label = sellLbl, value = COC.Api.Coin(math.floor((p.gross or p.sell) + 0.5)) },
        { label = string.format(L["Coupe HV (%d %%)"], pct), value = self:Money(-(p.cut or 0), true) },
        { label = L["Réactifs"],   value = costVal },
        { label = L["Profit net"], value = self:Money(p.profit, true) },
    }
end

-- Section « Rentabilité » du panneau d'info (cf. _ProfWindow_Info.lua). S'affiche pour toute recette
-- — apprise ou manquante — dont on connaît le prix de vente. Nil sinon (oracle absent, prix inconnu…).
if COC.ProfWindow and COC.ProfWindow.RegisterInfoSection then
    COC.ProfWindow:RegisterInfoSection(function(ctx)
        if not PR:IsAvailable() then return nil end
        local spellID = entrySpell(ctx.profKey, ctx.entry)
        local numMade = ctx.entry and ctx.entry.numMade
        local p = spellID and PR:CraftProfit(ctx.profKey, spellID, numMade)
        if not p then return nil end
        return { title = COC.L["Rentabilité"], lines = PR:ProfitLines(p) }
    end)
end
