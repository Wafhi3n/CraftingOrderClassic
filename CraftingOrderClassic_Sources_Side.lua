-- CraftingOrderClassic_Sources_Side.lua — le plan que seul l'AUTRE camp vend.
--
-- « Recipe: Crispy Bat Wing » n'a qu'un marchand, Abigail Shiel (Brill, Horde) : un joueur de
-- l'Alliance ne lui parlera jamais, et la vue Manquantes la lui proposait comme n'importe quel plan de
-- sa ville (relevé en jeu le 2026-10-03). Mais le plan est un OBJET : il se revend, à l'hôtel des
-- ventes NEUTRE. On ne le cache donc pas, on le MARQUE (arbitrage du user, même jour), et les vues
-- qui parlent d'un achat l'envoient à l'HV, pas chez ce marchand.
--
-- À part de CraftingOrderClassic_Sources.lua pour le seul plafond de 500 lignes : c'est la même
-- table `COC.Sources`, chargée juste après elle par le .toc.

local COC = CraftingOrderClassic
local S   = COC.Sources

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

-- ⚠️ TOUS les marchands connus doivent porter le camp d'en face. Un seul SANS camp suffit à se taire :
-- `nil` n'est pas « neutre », c'est « les deux, ou on ne sait pas », et marquer sur un doute enverrait
-- à l'HV quelqu'un qui pouvait l'acheter en ville. Même prudence que pour les jumeaux de camp.
-- Rend le camp qui vend ("A"|"H"), ou nil. Camp du joueur inconnu : nil, on ne tranche pas.
function S:OtherSideVendor(profKey, spellID)
    local me = self._MyFaction()
    if not (me and profKey and spellID) or self:SourceKind(profKey, spellID) ~= "vendor" then return nil end
    local lib = CL()
    local list = lib and lib.RecipeOrigins and lib:RecipeOrigins(profKey, spellID)
    if not (list and list[1]) then return nil end
    for _, e in ipairs(list) do
        if e[4] == nil or e[4] == me then return nil end
    end
    return list[1][4]
end

-- LE PLAN LIÉ QUAND RAMASSÉ ne se revend pas : vendu seulement chez l'autre camp, il est hors d'atteinte
-- pour ce joueur, et la piste de l'HV neutre serait un mensonge. La règle du user (2026-10-03) ne
-- marque que la recette NON liée ; la liée sort de la liste, comme un jumeau de camp. Mesuré le même
-- jour : les 72 plans d'Aisarra Nightmeadow (Hyjal, Alliance) sont tous liés quand ramassés.
-- La liaison est LUE sur le client (14e retour de GetItemInfo, 1 = liée quand ramassée), comme le
-- fait déjà UI_Post. Objet pas encore en cache : on ne sait pas, donc FAUX -- un doute ne masque rien.
function S:PlanIsBound(profKey, spellID)
    local itemID = self:RecipeItem(profKey, spellID)
    if not (itemID and COC.Api and COC.Api.GetItemInfo) then return false end
    return select(14, COC.Api.GetItemInfo(itemID)) == 1
end

-- Vrai si seul l'autre camp vend ce plan ET qu'il est lié : personne de ce camp ne peut l'obtenir.
function S:OtherSideUnreachable(profKey, spellID)
    return self:OtherSideVendor(profKey, spellID) ~= nil and self:PlanIsBound(profKey, spellID)
end

-- La phrase qui le dit. Le nom du camp vient des globales du jeu : déjà traduit, et c'est celui que le
-- joueur lit partout ailleurs.
function S:OtherSideNote(side)
    local camp = (side == "H" and FACTION_HORDE) or (side == "A" and FACTION_ALLIANCE) or nil
    if not camp then return nil end
    return string.format(COC.L["Vendu seulement côté %s : cherche-le à l'hôtel des ventes neutre."], camp)
end

-- Le blason du camp qui vend : l'atlas que le journal de quêtes de Forever pose sur une quête de
-- faction (Blizzard_FrameXMLBase/Constants.lua). En atlas pour une texture, en balise pour un texte.
local CREST = { A = "questlog-questtypeicon-alliance", H = "questlog-questtypeicon-horde" }
function S:OtherSideAtlas(side) return CREST[side] end
function S:OtherSideCrest(side, size)
    if not CREST[side] then return "" end
    size = size or 12
    return "|A:" .. CREST[side] .. ":" .. size .. ":" .. size .. "|a"
end

-- La cote HV de l'OBJET-plan (Auctionator), ou nil : le seul prix qui vaille pour un plan qu'aucun
-- marchand de notre camp ne vend.
function S:AuctionPrice(profKey, spellID)
    local itemID = self:RecipeItem(profKey, spellID)
    local PR = COC.Profit
    if not (itemID and PR and PR.IsAvailable and PR:IsAvailable()) then return nil end
    return PR:ItemValue(itemID)
end
