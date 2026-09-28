-- CraftingOrderClassic_MinimapIndicator.lua — icône d'état dans la barre de la minicarte (Forever).
--
-- La barre en haut de la minicarte (`MinimapCluster.IndicatorFrame`, Blizzard_Minimap
-- Mainline/Minimap.xml) aligne des icônes qui n'apparaissent que quand quelque chose attend le
-- joueur : la lettre du courrier (rang 1), les commandes d'artisanat de Blizzard (rang 2). On y pose
-- la nôtre au rang 3. Premier usage : « une nouvelle version est disponible », en plus de la pastille
-- du bouton de minicarte — même état, deux affichages. Spec : docs/specs/icone-minicarte.md.
--
-- ⚠️ `MinimapCluster` est un cadre du MODE ÉDITION. Méthode mesurée dans TaintLab le 2026-09-27
-- (`/tlab indica`, variante A choisie par le user) : enfant de la barre, `layoutIndex` 3, `Layout()`
-- à chaque bascule — aucune action refusée, 18 bascules en combat comprises. Ne pas changer de méthode
-- (cadre à nous collé contre la barre, SetPoint dans la barre…) sans remesurer au labo.

local COC = CraftingOrderClassic
local UI  = COC.UI
local L   = COC.L

local ICON         = "Interface\\AddOns\\CraftingOrderClassic\\Textures\\icon"   -- le logo « CO »
local LAYOUT_INDEX = 3   -- après la lettre (1) et les commandes de Blizzard (2)

local function bar()
    local mc = _G.MinimapCluster
    return mc and mc.IndicatorFrame
end

local function onEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
    GameTooltip:AddLine("Crafting Order")
    if UI._updateVer then
        GameTooltip:AddLine(string.format(L["Nouvelle version disponible : %s"], UI._updateVer), 1, 1, 1)
        local D = COC.Directory
        GameTooltip:AddLine(string.format(L["Tu as la %s. Mets l'addon à jour depuis CurseForge."],
            (D and D._myVerStr) or "?"), 0.8, 0.8, 0.8, true)
    end
    GameTooltip:Show()
end

local function build(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(18, 16)
    f.layoutIndex = LAYOUT_INDEX
    f:EnableMouse(true)
    local tex = f:CreateTexture(nil, "ARTWORK")
    tex:SetTexture(ICON)
    tex:SetSize(16, 16)
    tex:SetPoint("CENTER")
    f:SetScript("OnEnter", onEnter)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f:SetScript("OnMouseUp", function()   -- le détail, comme /co version
        if COC.Directory and COC.Directory.VersionCmd then COC.Directory:VersionCmd("") end
    end)
    f:Hide()
    return f
end

-- Allume/éteint l'icône « nouvelle version ». Appelée par UI:SetUpdateBadge (Minimap.lua). Sans la
-- barre (hors Forever), rien : la pastille du bouton reste le seul affichage. Rend vrai si l'icône
-- a été touchée.
function UI:SetUpdateIndicator(shown)
    local b = bar()
    if not b then return false end
    if not self.updateIndicator then
        if not shown then return false end   -- rien à éteindre : pas de cadre créé pour rien
        self.updateIndicator = build(b)
    end
    self.updateIndicator:SetShown(shown and true or false)
    if b.Layout then b:Layout() end   -- la barre se recompose : notre icône prend ou rend sa place
    return true
end
