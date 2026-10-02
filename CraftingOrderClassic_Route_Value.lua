-- CraftingOrderClassic_Route_Value.lua — ce que VAUT un objet pour le Plan de route au coût NET :
-- le prix qu'on en tirerait en le revendant. Spec : docs/specs/route-cout-net.md.
--
-- UNE seule valeur sert aux deux bouts du calcul (décision 6 de la spec) : un objet pris dans les
-- sacs coûte ce qu'on en aurait tiré, un objet fabriqué rapporte ce qu'on en tirera. Ce sont le même
-- objet vu à deux moments ; deux règles finiraient par se contredire, et une conversion (retailles →
-- cuir) se retrouverait gratuite ou comptée deux fois.
--
-- Fichier À PART, et c'est voulu : `feat/profit-arbitrages` (autre session) réécrit
-- CraftingOrderClassic_Profit.lua. On n'y touche pas ; on n'en lit que ce qui se comporte pareil des
-- deux côtés (IsAvailable, ItemValue, AH_CUT s'il existe). Chargé APRÈS Route.lua (.toc).

local COC   = CraftingOrderClassic
local Route = COC.Route
if not Route then return end

local AH_CUT = 0.05   -- repli : `feat/profit-arbitrages` expose PR.AH_CUT, `main` pas encore

-- Ce qu'un MARCHAND rachète l'objet, en cuivre, ou nil. 11e retour de GetItemInfo (`sellPrice`).
-- ⚠️ Pris par `select` sous pcall, jamais derrière un `X and X:f()` : la garde ne garderait qu'UN
-- retour (piège maison n° 10). Un objet pas encore en cache client rend nil : revente INCONNUE, donc
-- nulle pour la route -- l'hypothèse pessimiste, qui ne fabrique jamais de gain imaginaire.
-- Gardé une fois connu : ce prix est FIXE, et la fenêtre Route se recalcule chaque seconde sur des
-- centaines de produits. Une réponse vide n'est pas gardée : l'objet peut entrer en cache plus tard.
local BUYBACK = {}
local function merchantBuyback(itemID)
    if BUYBACK[itemID] then return BUYBACK[itemID] end
    local get = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo
    if not get then return nil end
    local ok, sell = pcall(function() return (select(11, get(itemID))) end)
    if not (ok and type(sell) == "number" and sell > 0) then return nil end
    BUYBACK[itemID] = sell
    return sell
end

-- Valeur de REVENTE d'un objet, en cuivre, ou nil si on ne sait pas.
--   · coté (HV ou marchand qui le VEND) : ce prix moins la coupe de l'HV. `ItemValue` lit le
--     marchand d'abord : son prix PLAFONNE la revente (arbitrage 10 de rentabilite-forever.md --
--     personne ne paiera plus cher à l'HV ce qu'un PNJ vend en ville) ;
--   · sinon, ce qu'un marchand le rachète. C'est aussi le cas d'un objet LIÉ quand ramassé : il
--     ne passe pas à l'HV, Auctionator n'a donc jamais pu le coter -- pas besoin de lire le lien.
function Route:ResaleValue(itemID)
    local PR = COC.Profit
    if not (itemID and PR and PR:IsAvailable()) then return nil end
    local p = PR:ItemValue(itemID)
    if p then return p * (1 - (PR.AH_CUT or AH_CUT)) end
    return merchantBuyback(itemID)
end

-- Réglage de valorisation de MON perso, le même pour la fenêtre et le suivi à l'écran (critère 7 :
-- les deux choisissent la même recette). `resale` = case « Compter la revente » (db.routeResale,
-- nil = cochée, même convention que db.routePlans).
function Route:MyValuation()
    return { resale = not (COC.db and COC.db.routeResale == false) }
end
