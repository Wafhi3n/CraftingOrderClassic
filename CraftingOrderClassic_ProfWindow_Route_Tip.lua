-- CraftingOrderClassic_ProfWindow_Route_Tip.lua — l'INFOBULLE d'une étape du Plan de route : crafts
-- attendus, réactifs, ce qui vient des sacs ou des étapes d'avant, plan à acheter, raison d'un
-- « (?) », et -- en coût NET (spec docs/specs/route-cout-net.md) -- la revente, le net de l'étape et
-- l'aveu « les matières valent plus que ce que l'étape produit ».
--
-- Sortie de _ProfWindow_Route.lua le 2026-10-02 : le coût net y ajoutait une douzaine de lignes à un
-- fichier déjà proche des 500. La couture suit le contenu : là-bas on PEINT la route, ici on
-- l'EXPLIQUE ligne à ligne. Chargé après lui (.toc) ; il pose PW:_RouteSegTip, qu'une ligne appelle
-- au survol -- donc au moment du survol, jamais au chargement.

local COC  = CraftingOrderClassic
local PW   = COC.ProfWindow
local Skin = COC.UI.Skin
local L    = COC.L

local GREY, BLUE, GREEN = { 0.8, 0.8, 0.8 }, { 0.60, 0.75, 0.91 }, { 0.55, 0.85, 0.55 }
local function add(txt, col, wrap) GameTooltip:AddLine(txt, col[1], col[2], col[3], wrap) end
local function coin(c) return COC.Api.Coin(math.floor(math.abs(c) + 0.5)) end

-- « Ruined Leather Scraps ×43, Light Leather ×19 » — ce qu'une étape prend au stock (seg.bag /
-- seg.made, posés par COC.Route). nil si rien : pas de ligne vide dans l'infobulle.
local function stockText(map)
    local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    local parts = {}
    for id, q in pairs(map or {}) do
        local n = math.floor(q + 0.5)
        if n > 0 then
            local nm = COC.Api.GetItemInfo and COC.Api.GetItemInfo(id)
            if not nm and lib and lib.ItemName then nm = lib:ItemName(id) end
            parts[#parts + 1] = (nm or ("item:" .. id)) .. " ×" .. n
        end
    end
    table.sort(parts)
    return parts[1] and table.concat(parts, ", ") or nil
end

-- Le bloc NET : revente (avec le nombre d'objets -- la profondeur du marché n'est pas plafonnée,
-- décision 4 de la spec : on la MONTRE), net de l'étape, et l'aveu quand les matières valent plus
-- que les objets produits. `resaleOn` = case « Compter la revente ».
local function netLines(s, resaleOn)
    if (s.bagValue or 0) > 0.5 then add(string.format(L["Pris dans tes sacs : ~%s"], coin(s.bagValue)), GREEN) end
    if (s.resale or 0) > 0 then
        add(string.format(L["Revente : ~%s (%d objet(s) à vendre)"], coin(s.resale),
            math.ceil(s.resaleQty - 0.001)), GREEN)
    elseif resaleOn and s.prod then
        add(L["Revente inconnue : comptée nulle."], GREY)
    end
    local net = (s.net or 0) + (s.plan or 0)
    if net < -0.5 then add(string.format(L["Gain net de l'étape : %s"], coin(net)), { 0.2, 0.87, 0.2 })
    else add(string.format(L["Coût net de l'étape : %s"], coin(net)), BLUE) end
    if (s.resale or 0) > 0 and (s.net or 0) > 0.5 then
        add(string.format(L["Les matières valent ~%s de plus que ce que l'étape produit."], coin(s.net)),
            { 1, 0.6, 0.2 }, true)
    end
end

function PW:_RouteSegTip(row)
    local s = row.seg; if not s then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT"); GameTooltip:ClearLines()
    -- Fiche COMPLÈTE de l'objet produit en tête (repli nom : enchants sans objet, item hors cache
    -- — retour user 2026-07-19, le survol des segments ne montrait pas l'objet).
    if not s.gap and s.prod then Skin.TipItem(GameTooltip, s.prod, PW._RouteSegName(s.sid, s.prod))
    else GameTooltip:SetText(row.name:GetText() or "", 1, 1, 1) end
    if s.gap then
        add(L["Aucune recette calculable sur ce segment (prix HV manquants, ou plans introuvables)."], GREY, true)
        GameTooltip:Show(); return
    end
    add(string.format(L["Crafts attendus : ~%d"], math.ceil(s.crafts - 0.001)), BLUE)
    add(L["Réactifs (espéré)"] .. " : " .. COC.Api.Coin(math.floor(s.cost + 0.5)), BLUE)
    local bag, made = stockText(s.bag), stockText(s.made)
    if bag then add(string.format(L["Déjà dans tes sacs : %s"], bag), GREEN, true) end
    if made then add(string.format(L["Fabriqué aux étapes d'avant : %s"], made), GREEN, true) end
    if (s.plan or 0) > 0 then add(L["Plan à acheter"] .. " : " .. COC.Api.Coin(s.plan), { 0.91, 0.72, 0.29 }) end
    if row.valued then netLines(s, row.resaleOn) end
    -- Deux raisons au « (?) », et le joueur n'y peut pas la même chose : un réactif sans prix
    -- attend un scan de l'HV, un plan de formateur sans prix attend une visite chez lui.
    if s.missing or (s.partial and not s.planUnknown) then
        add(L["Coût partiel : au moins un réactif sans prix HV."], GREY, true)
    end
    if s.planUnknown then
        add(L["Prix du plan inconnu : COC le relèvera à ton prochain passage chez le formateur."], GREY, true)
    end
    GameTooltip:Show()
end
