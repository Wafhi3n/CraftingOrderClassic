-- CraftingOrderClassic_UI_Skin_Inputs.lua — les CHAMPS DE SAISIE du formulaire de commande (palier 4
-- de la revue d'interface) : le montant et la quantité, avec les briques du formulaire des Commandes
-- d'artisanat de Forever (Blizzard_ProfessionsCustomerOrdersForm.xml, notre maquette) au lieu de nos
-- InputBoxTemplate nus. Les deux gabarits vivent dans des modules chargés en permanence
-- (Blizzard_MoneyFrame, Blizzard_SharedXML), et la sonde du labo les a vus présents (26/26).
-- Leurs mixins ne touchent aucun objet global (risque 3 de la revue, lu avant d'hériter).

local COC  = CraftingOrderClassic
local Skin = COC.UI.Skin

-- Le prix tel que le protocole d'ordres le transporte : « 12po 5pa 3pc », dénominations nulles
-- omises, nil pour zéro. Écrit une fois ici : Commande et Récolte le recopiaient chacune deux fois.
function Skin.PriceText(copper)
    copper = math.floor(tonumber(copper) or 0)
    if copper <= 0 then return nil end
    local g, s, c = math.floor(copper / 10000), math.floor((copper % 10000) / 100), copper % 100
    local parts = {}
    if g > 0 then parts[#parts + 1] = g .. "po" end
    if s > 0 then parts[#parts + 1] = s .. "pa" end
    if c > 0 then parts[#parts + 1] = c .. "pc" end
    return table.concat(parts, " ")
end

-- Repli du montant si le gabarit manquait : la rangée maison, sous le même contrat.
local function moneyFallback(parent, w)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(w or 200, 16)
    local g, s, c = Skin.MakeMoneyRow(f, 0, 0)
    function f:GetAmount()
        return (tonumber(g:GetText()) or 0) * 10000 + (tonumber(s:GetText()) or 0) * 100 + (tonumber(c:GetText()) or 0)
    end
    function f:SetAmount(v)
        v = math.floor(v or 0)
        g:SetText(math.floor(v / 10000)); s:SetText(math.floor((v % 10000) / 100)); c:SetText(v % 100)
    end
    function f:Clear() self:SetAmount(0) end
    return f
end

-- Le champ MONTANT : `LargeMoneyInputFrameTemplate`, celui du pourboire des Commandes d'artisanat
-- (200 × 33, trois cases or/argent/cuivre avec leur pièce). Rend le cadre, à ancrer par l'appelant :
-- :GetAmount() en cuivre, :SetAmount(cuivre), :Clear().
function Skin.MakeMoneyInput(parent, w)
    local ok, f = pcall(CreateFrame, "Frame", nil, parent, "LargeMoneyInputFrameTemplate")
    if not (ok and f and f.GetAmount) then return moneyFallback(parent, w) end
    f:SetSize(w or 200, 33)
    return f
end

-- Repli de la quantité : la case numérique d'avant, sous le contrat du compteur.
local function qtyFallback(parent, max)
    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetSize(40, 16); eb:SetAutoFocus(false); eb:SetNumeric(true); eb:SetText("1")
    eb:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)
    function eb:GetValue() return math.max(1, math.min(max, tonumber(self:GetText()) or 1)) end
    function eb:SetValue(v) self:SetText(tostring(v or 1)) end
    return eb
end

-- Le champ QUANTITÉ : `NumericInputSpinnerTemplate`, le compteur de « Créer tout » de la fenêtre des
-- métiers — [-] case [+], clic maintenu qui accélère, borné de 1 à `max` (999 par défaut : la case
-- tient trois chiffres). ⚠️ L'ancre de l'appelant porte sur la CASE : le [-] déborde de 29 px à sa
-- gauche, le [+] de 23 px à sa droite. :GetValue(), :SetValue(n).
function Skin.MakeQtySpinner(parent, max)
    max = max or 999
    local ok, sp = pcall(CreateFrame, "EditBox", nil, parent, "NumericInputSpinnerTemplate")
    if not (ok and sp and sp.SetMinMaxValues) then return qtyFallback(parent, max) end
    -- Réglages du mixin relus à chaque saisie (pas des KeyValues lues à la création) : on peut les
    -- poser ici. Mêmes valeurs que « Créer tout ».
    sp.clampIfInputExceedsRange, sp.highlightIfInputExceedsRange = true, true
    sp:SetMinMaxValues(1, max)
    sp:SetValue(1)
    sp:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)
    return sp
end
