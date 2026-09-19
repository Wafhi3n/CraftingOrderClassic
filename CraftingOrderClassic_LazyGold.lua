-- CraftingOrderClassic_LazyGold.lua — pont LECTURE SEULE vers l'addon « Lazy Gold Classic » (LG).
--
-- BUT : afficher la RENTABILITÉ d'une recette dans la vue métier — prix de vente à l'HV, coût des
-- réactifs, profit net — en réutilisant les prix que Lazy Gold calcule (via Auctionator + prix
-- vendeur). On ne réimplémente PAS la collecte de prix : on lit sa primitive publique.
--
-- DÉPENDANCE MOLLE : COC reste autonome. Si aucun oracle de prix n'est là, IsAvailable() est faux et
-- la section « Rentabilité » ne s'affiche pas — aucun plantage. On lit UNE fonction publique, jamais
-- l'UI ni les tables internes des addons lus.
--
-- DEUX ORACLES, une seule façade. Lazy Gold Classic n'existe que sur Classic Era ; sur WoW: Forever
-- (Camelot, API mainline) il n'y a qu'AUCTIONATOR, que Lazy Gold interroge d'ailleurs lui-même. On
-- lit donc directement l'API publique versionnée d'Auctionator quand Lazy Gold manque — ce qui rend
-- au portage Forever la rentabilité, le coût/point et le PLAN DE ROUTE, qui tous en dépendent.
-- Lazy Gold garde la priorité là où il est : il connaît en plus une table de prix VENDEUR curée.
--
-- PRIMITIVES LUES :
--   LazyGold:GetItemCost(itemID)                          -> cuivre (vendeur, sinon HV), nil si inconnu.
--   Auctionator.API.v1.GetVendorPriceByItemID(id, itemID) -> prix d'ACHAT chez le PNJ, par unité,
--       relevé à la visite d'un marchand à stock illimité (Source/CraftingInfo/Main.lua) — donc bien
--       un coût d'approvisionnement, pas le prix de rachat. nil tant qu'aucun marchand n'a été vu.
--   Auctionator.API.v1.GetAuctionPriceByItemID(id, itemID) -> prix HV scanné, nil si jamais scanné.
-- L'API d'Auctionator LÈVE (error) sur un callerID vide ou un argument mal typé : tout passe en pcall.
--
-- Le COÛT des réactifs et l'objet produit viennent de NOS données CraftLink (RecipeReagents/RecipeProduct),
-- pas des tables de LG : on reste maître de la recette, LG ne sert QUE d'oracle de prix.

local COC = CraftingOrderClassic
local LG  = {}
COC.LazyGold = LG

local AH_CUT = 0.05   -- coupe de l'hôtel des ventes, comme Lazy Gold (5 %)

-- Nom d'appelant exigé par l'API d'Auctionator (elle lève sur une chaîne vide).
local CALLER = "CraftingOrderClassic"

local function lazyGold()
    local lg = _G.LazyGold
    return (type(lg) == "table" and type(lg.GetItemCost) == "function") and lg or nil
end

local function auctionator()
    local a = _G.Auctionator
    local v1 = a and a.API and a.API.v1
    return (type(v1) == "table" and type(v1.GetAuctionPriceByItemID) == "function") and v1 or nil
end

-- Un oracle de prix, quel qu'il soit, répond-il ?
function LG:IsAvailable()
    return (lazyGold() or auctionator()) and true or false
end

-- Quel oracle sert ? Rend le NOM D'AFFICHAGE de l'addon, parce que c'est à ça que ça sert : les
-- libellés qui citaient « Lazy Gold » en dur mentaient sur Forever, où les prix viennent
-- d'Auctionator. Un pied de fenêtre qui nomme la mauvaise source envoie chercher le problème au
-- mauvais endroit le jour où un prix semble faux.
function LG:PriceSource()
    if lazyGold() then return "Lazy Gold" end
    if auctionator() then return "Auctionator" end
    return nil
end

-- Prix d'un objet en cuivre (vendeur ou HV), ou nil si aucun oracle ne le connaît.
-- Ordre VENDEUR puis HV dans les deux chemins : un réactif vendu à prix fixe en ville ne doit
-- jamais être valorisé au cours de l'HV, sinon toute la route se trompe de recette.
function LG:ItemValue(itemID)
    if not itemID then return nil end
    local lg = lazyGold()
    if lg then
        local ok, price = pcall(lg.GetItemCost, lg, itemID)
        if ok and type(price) == "number" and price > 0 then return price end
        return nil
    end
    local v1 = auctionator()
    if not v1 then return nil end
    local ok, price = pcall(v1.GetVendorPriceByItemID, CALLER, itemID)
    if ok and type(price) == "number" and price > 0 then return price end
    ok, price = pcall(v1.GetAuctionPriceByItemID, CALLER, itemID)
    if ok and type(price) == "number" and price > 0 then return price end
    return nil
end

-- Objet vendu par un PNJ (prix fixe) ? Lit la table publique de Lazy Gold (VENDOR_ITEMS, prix
-- vendeur par unité — celle que GetItemCost consulte en premier). Sert à la bourse d'artisan : un
-- composant vendeur ne vaut pas d'être fourni, l'artisan l'achètera en ville (retour user
-- 2026-07-19 : Coarse Thread / Red Dye encombraient la grille).
-- Auctionator répond à la même question, mais seulement pour les marchands DÉJÀ VISITÉS : sa réponse
-- est donc sûre quand elle est positive, muette sinon. On ne comble pas ce trou par une devinette —
-- au pire un composant vendeur reste dans la grille, ce qui est l'état d'avant la feature.
function LG:IsVendorItem(itemID)
    if not itemID then return false end
    local lg = lazyGold()
    if lg then
        local t = lg.VENDOR_ITEMS
        return (type(t) == "table" and t[itemID]) and true or false
    end
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
        LG:ItemValue(itemID) and COC.Api.Coin(LG:ItemValue(itemID)) or "AUCUN PRIX"))
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

function LG:PriceDump(arg)
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
function LG:CoinTier(copper)
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
function LG:ProfitTier(copper)
    if not copper or copper <= 0 then return "" end
    return self:CoinTier(copper)
end

-- Mode d'affichage du profit dans les listes : compact (paliers de pièces) ou VALEUR EXACTE en
-- po/pa/pc. Préférence de lecture persistée (bouton « 123 » de la barre d'outils Recettes).
function LG:ExactMode() return (COC.db and COC.db.lgExactProfit) and true or false end
function LG:SetExactMode(on) if COC.db then COC.db.lgExactProfit = on and true or false end end

-- Texte de profit d'une LIGNE de liste, selon le mode courant. Une perte n'affiche RIEN dans les
-- deux modes (cf. ProfitTier) : la liste ne sert qu'à repérer ce qui rapporte.
function LG:ProfitText(copper)
    if not copper or copper <= 0 then return "" end
    if self:ExactMode() then return COC.Api.Coin(copper) end
    return self:CoinTier(copper)
end

-- Montant formaté avec signe : « +3g 50s », « -1g », « 0 ». GetCoinTextureString n'accepte pas le
-- négatif → on formate la valeur absolue et on préfixe le signe et une couleur (vert/rouge).
function LG:Money(copper, colored)
    copper = math.floor((copper or 0) + 0.5)
    local sign = copper < 0 and "-" or "+"
    local body = COC.Api.Coin and COC.Api.Coin(math.abs(copper)) or tostring(math.abs(copper))
    local txt = sign .. body
    if not colored then return txt end
    local c = copper < 0 and "|cFFFF5555" or (copper > 0 and "|cFF33DD33" or "|cFF888888")
    return c .. txt .. "|r"
end

-- Rentabilité d'une recette : { sell, cost, profit, missing } en cuivre, ou nil si le prix de VENTE
-- du produit est inconnu (sans lui, aucun calcul n'a de sens). `missing` = au moins un réactif sans
-- prix (coût sous-estimé). numMade = nb d'objets produits par craft (défaut 1). Formule identique à
-- Lazy Gold : vente × quantité × (1 − coupe HV) − coût des réactifs.
function LG:CraftProfit(profKey, spellID, numMade)
    if not (self:IsAvailable() and profKey and spellID) then return nil end
    local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    if not lib then return nil end
    local productID = lib.RecipeProduct and lib:RecipeProduct(profKey, spellID)
    local sell = productID and self:ItemValue(productID)
    if not sell then return nil end

    local cost, missing = 0, false
    for _, reag in ipairs((lib.RecipeReagents and lib:RecipeReagents(profKey, spellID)) or {}) do
        local id, qty = reag[1], reag[2] or 1
        local p = self:ItemValue(id)
        if p then cost = cost + p * qty else missing = true end
    end

    local n = numMade and numMade > 0 and numMade or 1
    local profit = sell * n * (1 - AH_CUT) - cost
    return { sell = sell, cost = cost, profit = profit, missing = missing, numMade = n }
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
function LG:EntryProfit(profKey, entry)
    local spellID = entrySpell(profKey, entry)
    if not spellID then return nil end
    local p = self:CraftProfit(profKey, spellID, entry and entry.numMade)
    return p and p.profit or nil
end

-- Coût des seuls RÉACTIFS d'une recette : { cost, missing } en cuivre, ou nil si aucun réactif n'est
-- pricé / recette hors catalogue. Contrairement à CraftProfit, PAS besoin du prix de vente du produit
-- — les enchants (services sans objet produit) ont donc aussi un coût. Sert au coût de PROGRESSION
-- (montée de métier, cf. _ProfWindow_Leveling), pas à la rentabilité.
function LG:CraftCost(profKey, spellID)
    if not (self:IsAvailable() and profKey and spellID) then return nil end
    local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    local reags = lib and (lib.RecipeReagents and lib:RecipeReagents(profKey, spellID)) or {}
    if #reags == 0 then return nil end
    local cost, missing, priced = 0, false, false
    for _, reag in ipairs(reags) do
        local p = self:ItemValue(reag[1])
        if p then cost = cost + p * (reag[2] or 1); priced = true else missing = true end
    end
    if not priced then return nil end
    return { cost = cost, missing = missing }
end

-- Coût réactifs d'une ENTRÉE de liste (résout le spellID comme EntryProfit), ou nil.
function LG:EntryCost(profKey, entry)
    local spellID = entrySpell(profKey, entry)
    if not spellID then return nil end
    return self:CraftCost(profKey, spellID)
end

-- ---------------------------------------------------------------------------
-- Meilleur profit ATTEIGNABLE dans un métier, par niveau de compétence
-- ---------------------------------------------------------------------------
-- Sert à mettre en avant l'artisan dont le métier a un plan rentable. Calculer ça naïvement voudrait
-- dire, à chaque rendu et pour chaque artisan, évaluer les centaines de recettes du métier (donc des
-- milliers de lookups de prix). On construit donc UNE FOIS par métier une table indexée par niveau :
--   best[r] = meilleur profit parmi les recettes apprenables à un niveau <= r.
-- Lookup ensuite en O(1). Cache avec TTL : les prix Auctionator bougent, mais pas à la seconde.
local MAX_RANK, CACHE_TTL = 450, 120
local bestCache = {}   -- [profKey] = { at = <horodatage>, best = { [rank] = profit } }

-- best[r] = { profit, sid } du MEILLEUR plan atteignable à un niveau ≤ r (on garde le spellID, pas
-- seulement le montant : le tooltip d'artisan NOMME le plan — « le meilleur plan » sans son nom ne
-- dit pas quoi commander).
local function buildBest(profKey)
    local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    local best = {}
    -- Meilleur plan par niveau d'apprentissage EXACT, puis propagation en max cumulé.
    local atRank = {}
    for _, spellID in ipairs((lib and lib.GetRecipes and lib:GetRecipes(profKey)) or {}) do
        local p = LG:CraftProfit(profKey, spellID, nil)
        if p and p.profit and p.profit > 0 then
            local at = (lib.RecipeLearnedAt and lib:RecipeLearnedAt(profKey, spellID)) or 1
            if at < 0 then at = 0 elseif at > MAX_RANK then at = MAX_RANK end
            local cur = atRank[at]
            if not cur or p.profit > cur.profit then atRank[at] = { profit = p.profit, sid = spellID } end
        end
    end
    local running = nil
    for r = 0, MAX_RANK do
        local v = atRank[r]
        if v and (not running or v.profit > running.profit) then running = v end
        best[r] = running
    end
    return best
end

-- Entrée { profit, sid } du meilleur plan d'un métier pour un artisan de niveau `rank`, ou nil.
-- rank nil → on suppose le niveau max (on ne sait pas, autant ne pas sous-estimer).
function LG:BestPlanFor(profKey, rank)
    if not (self:IsAvailable() and profKey) then return nil end
    local now = GetTime and GetTime() or 0
    local c = bestCache[profKey]
    if not c or (now - c.at) > CACHE_TTL then
        c = { at = now, best = buildBest(profKey) }
        bestCache[profKey] = c
    end
    local r = tonumber(rank) or MAX_RANK
    if r < 0 then r = 0 elseif r > MAX_RANK then r = MAX_RANK end
    return c.best[r]
end

-- Montant seul (nil si aucun plan rentable / pas de prix).
function LG:BestProfitFor(profKey, rank)
    local e = self:BestPlanFor(profKey, rank)
    return e and e.profit or nil
end

-- Nom de l'objet produit par un plan { profit, sid } (« Iron Buckle »), ou nil.
function LG:PlanName(profKey, plan)
    local lib = plan and LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    if not lib then return nil end
    local itemID = lib.RecipeProduct and lib:RecipeProduct(profKey, plan.sid)
    local nm = itemID and lib:ItemName(itemID) or lib:RecipeName(plan.sid)
    if not nm or nm:match("^item:") or nm:match("^spell:") then return nil end
    return nm
end

-- Nom du meilleur plan ATTEIGNABLE à un rang (approximation, cf. BestPlanFor). Conservé pour les
-- appelants qui n'ont pas de fiche artisan (rang seul) — préférer BestKnownPlanFor + PlanName quand
-- une fiche `r` est disponible : plus honnête (ne nomme que ce que l'artisan a RÉELLEMENT appris).
function LG:BestPlanName(profKey, rank)
    return self:PlanName(profKey, self:BestPlanFor(profKey, rank))
end

-- ---------------------------------------------------------------------------
-- Meilleur plan RÉELLEMENT connu d'un artisan (pas seulement « atteignable à son niveau »). En
-- Classic, une recette dépasse un palier de compétence ne veut pas dire qu'on l'a apprise : elle
-- peut nécessiter un PNJ, un butin ou une quête à part. BestPlanFor (rang seul) peut donc nommer un
-- plan que l'artisan ne sait PAS fabriquer. Ici on décode le bitmask EXACT de ses recettes connues
-- (mêmes données que le filtre « connus » de l'onglet Commande, cf. _TargetArtisanFilter) et on ne
-- regarde que celles-là. Cache par (métier, bitmask) — pas par rang — car deux artisans de même
-- niveau peuvent avoir appris des recettes différentes.
local knownBestCache = {}   -- [profKey.."|"..hex] = { at, best = {profit, sid} | nil }

-- `known` = set { [spellID] = true } fourni par la couture (Directory_Recipes) : ce module n'a
-- pas a savoir si le registre est arrive en bitfield ou en identifiants.
local function buildBestKnown(profKey, known)
    if not known then return nil end
    local best
    for sid in pairs(known) do
        local p = LG:CraftProfit(profKey, sid, nil)
        if p and p.profit and p.profit > 0 and (not best or p.profit > best.profit) then
            best = { profit = p.profit, sid = sid }
        end
    end
    return best
end

-- `r` = fiche roster de l'artisan. Renvoie nil si son registre n'est pas EXPLOITABLE pour ce
-- métier (jamais croisé en direct, ou bitfield d'une autre version du catalogue) — dans ce cas
-- l'appelant retombe sur BestPlanFor(profKey, rank), une approximation moins fiable mais
-- toujours disponible. La forme du registre est l'affaire de la couture, pas la nôtre.
function LG:BestKnownPlanFor(profKey, r)
    if not (self:IsAvailable() and profKey and r) then return nil end
    local D = COC.Directory
    -- La clé de cache vient de la couture : elle intègre la FORME du registre, donc deux
    -- registres de formes différentes ne peuvent pas se répondre l'un pour l'autre.
    local k = D and D.RecipeFingerprint and D:RecipeFingerprint(r, profKey)
    if not k then return nil end
    local now = GetTime and GetTime() or 0
    local c = knownBestCache[k]
    if not c or (now - c.at) > CACHE_TTL then
        c = { at = now, best = buildBestKnown(profKey, D:RecipeKnownSet(r, profKey)) }
        knownBestCache[k] = c
    end
    return c.best
end

-- Seuil de mise en avant (configurable) : par défaut 10 po. Les paliers en découlent (×10, ×100).
function LG:MinProfit()
    local db = COC.db
    return (db and tonumber(db.lgMinProfit)) or (10 * 10000)
end

-- Palier de mise en avant d'un profit : 0 = rien, 2 = or (≥ seuil), 3 = or + halo (≥ seuil ×100).
-- Avec le défaut (seuil 10 po) : doré dès 10 po, doré + halo à 1000 po.
-- On allume dès qu'il y a un plan LUCRATIF (≥ seuil), pas seulement l'élite : un métier avec un plan à
-- 30 po est utile à voir, même s'il n'est pas le plus rentable du roster. Le seuil de base (db.lgMinProfit)
-- filtre le bruit — le monter éteint les petits profits. La COULEUR reste toujours dorée (pas d'argent).
-- (Les numéros 2/3 sont conservés — TIER_COLOR et les vues sont indexées dessus.)
function LG:HighlightTier(profit)
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
LG.ALERT_TEX    = "Interface\\SpellActivationOverlay\\IconAlert"
LG.ALERT_BORDER = { 0.078125, 0.4375, 0.5703125, 0.75 }        -- contour blanc, teintable
LG.ALERT_GLOW   = { 0.015625, 0.609375, 0.0078125, 0.265625 }  -- halo (palier 3)
LG.TIER_COLOR   = {                                            -- teinte du contour par palier
    [1] = { 0.78, 0.82, 0.90 },   -- argent
    [2] = { 1.00, 0.82, 0.25 },   -- or
    [3] = { 1.00, 0.82, 0.25 },   -- or + halo
}

-- Section « Rentabilité » du panneau d'info (cf. _ProfWindow_Info.lua). S'affiche pour toute recette
-- — apprise ou manquante — dont on connaît le prix de vente. Nil sinon (Lazy Gold absent, prix inconnu…).
if COC.ProfWindow and COC.ProfWindow.RegisterInfoSection then
    COC.ProfWindow:RegisterInfoSection(function(ctx)
        if not LG:IsAvailable() then return nil end
        local spellID = entrySpell(ctx.profKey, ctx.entry)
        local numMade = ctx.entry and ctx.entry.numMade
        local p = spellID and LG:CraftProfit(ctx.profKey, spellID, numMade)
        if not p then return nil end
        local L = COC.L
        local sellLbl = L["Vente HV"] .. (p.numMade > 1 and (" ×" .. p.numMade) or "")
        local costVal = LG:Money(-p.cost, true)
        if p.missing then costVal = costVal .. " |cFF888888(?)|r" end   -- un réactif sans prix : coût partiel
        return {
            title = L["Rentabilité"],
            lines = {
                { label = sellLbl,        value = COC.Api.Coin(p.sell) },
                { label = L["Réactifs"],  value = costVal },
                { label = L["Profit net"], value = LG:Money(p.profit, true) },
            },
        }
    end)
end
