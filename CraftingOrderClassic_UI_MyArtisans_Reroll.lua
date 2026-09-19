-- CraftingOrderClassic_UI_MyArtisans_Reroll.lua — accès à la vue REROLL (métiers d'un AUTRE perso
-- du compte) depuis l'onglet « Mes artisans ».
--
-- Pourquoi ici, et plus dans le menu minimap. Le menu minimap listait une ligne « Métier — Perso »
-- par couple ; il faisait doublon avec cet onglet, qui agrège déjà les métiers du compte ET sait
-- QUI les porte (`e.chars`, cf. Directory_MyArtisans). Sur WoW: Forever ce menu disparaît tout à
-- fait (la fenêtre native a son propre sélecteur de métier) — la feature devait donc déménager
-- pour ne pas disparaître avec lui.
--
-- Geste : clic GAUCHE sur un métier = le sélectionner (comportement historique) ; clic DROIT =
-- volet des persos qui le portent → vue reroll en lecture seule (PW:OpenForReroll).
-- Vit dans son propre fichier : _UI_MyArtisans.lua est à 15 lignes du plafond anti-monolithe.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local function me() return (UnitName and UnitName("player")) or "?" end

-- Porteurs du métier HORS perso connecté : lui, sa vue « reroll » n'a aucun sens (ses recettes se
-- lisent en direct dans la fenêtre de métier).
local function otherBearers(e)
    local out = {}
    local cur = me()
    for _, c in ipairs((e and e.chars) or {}) do
        if c.name ~= cur then out[#out + 1] = c end
    end
    return out
end

function UI:_BuildMyArtRerollMenu()
    local m = Skin.MakeFlyout("COCMyArtRerollMenu", 200, { rowW = 180 })
    m.title = m:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    m.title:SetPoint("TOPLEFT", 10, -8); Skin.ApplyShadow(m.title)
    self.myArtRerollMenu = m
    return m
end

-- Volet des porteurs d'un métier. Ancré à droite de la ligne cliquée (la colonne de gauche est
-- étroite : à gauche, le volet sortirait de l'écran sur une fenêtre posée au bord).
function UI:MyArtRerollMenu(row, e)
    local list = otherBearers(e)
    if #list == 0 then
        UI:Toast(string.format(L["Aucun autre perso avec ce métier : %s"], Skin.ProfLabel(e.profKey)))
        return
    end
    local m = self.myArtRerollMenu or self:_BuildMyArtRerollMenu()
    if m:IsShown() then m:Hide() end
    m.title:SetText("|cFFE8B84B" .. L["Voir chez un autre perso"] .. "|r")
    local y = -26
    for i, c in ipairs(list) do
        local r = m:Row(i)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 10, y)
        local lvl = (c.rank and c.max) and ("  |cFF888888" .. c.rank .. "/" .. c.max .. "|r") or ""
        r:SetText(c.name .. lvl)
        r:SetScript("OnClick", function()
            m:Hide()
            if COC.ProfWindow then COC.ProfWindow:OpenForReroll(e.profKey, c.key, c.name) end
        end)
        r:Show()
        y = y - 22
    end
    m:SetCount(#list)
    m:SetHeight(math.max(-y + 6, 40))                 -- hauteur custom (titre + lignes) : écrase SetCount
    m:ToggleAt("TOPLEFT", row, "TOPRIGHT", 4, 0)
end

-- Câblage d'une ligne « métier » de la colonne de gauche. Appelé par UI:_FillMyArtProfRow à chaque
-- remplissage : la closure capture l'entrée `e` du rafraîchissement courant, jamais une périmée.
function UI:_WireMyArtRerollRow(row, e)
    row:SetScript("OnClick", function(_, btn)
        if btn == "RightButton" then UI:MyArtRerollMenu(row, e); return end
        UI.myArtSelProf = e.profKey; UI:RefreshMyArtisans()
    end)
    row:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(Skin.ProfLabel(e.profKey))
        GameTooltip:AddLine(L["Clic : voir les recettes connues"], 1, 1, 1)
        if #otherBearers(e) > 0 then
            GameTooltip:AddLine(L["Clic droit : voir chez un autre perso"], 0.6, 1, 0.6)
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
