-- CraftingOrderClassic_MinimapIndicator.lua — icônes d'état dans la barre de la minicarte (Forever).
--
-- La barre en haut de la minicarte (`MinimapCluster.IndicatorFrame`, Blizzard_Minimap
-- Mainline/Minimap.xml) aligne des icônes qui n'apparaissent que quand quelque chose attend le
-- joueur : la lettre du courrier (rang 1), les commandes d'artisanat de Blizzard (rang 2). COC y pose
-- les siennes à partir du rang 3. Spec : docs/specs/icone-minicarte.md ; mode d'emploi : skill
-- coc-native-ui, section « Icônes d'état de la minicarte ».
--
-- API (deux appels) :
--   UI:DefineIndicator(key, def)   -- une fois, au chargement
--       def.texture | def.atlas    -- l'image (chemin de fichier, ou atlas VÉRIFIÉ sur le client)
--       def.order                  -- rang dans la barre, ≥ 3 (1 et 2 sont à Blizzard)
--       def.size                   -- côté en px (défaut 22, cf. ICON_SIZE)
--       def.width / def.height     -- facultatif, pour une icône qui n'est pas carrée (priment sur size)
--       def.useAtlasSize           -- l'atlas garde sa taille native, calé en haut à gauche (comme le
--                                  -- useAtlasSize="true" du XML de Blizzard) au lieu d'être étiré
--       def.tooltip(tt)            -- remplit GameTooltip (lignes après le titre « Crafting Order »)
--       def.onClick(button)        -- facultatif
--   UI:SetIndicator(key, shown)    -- l'allume ou l'éteint ; rend vrai si la barre existe
-- Le cadre n'est créé qu'au premier allumage. Sans la barre (hors Forever), SetIndicator ne fait rien.
--
-- ⚠️ `MinimapCluster` est un cadre du MODE ÉDITION. Méthode mesurée dans TaintLab le 2026-09-27
-- (`/tlab indica`, variante A choisie par le user) puis revue en jeu dans COC le 2026-09-28 (relevé
-- 14) : enfant de la barre, `layoutIndex`, `Layout()` à chaque bascule — aucune action refusée, 18
-- bascules en combat comprises. Ne pas changer de méthode (cadre à nous collé contre la barre, SetPoint
-- à la main dans la barre…) sans remesurer au labo.

local COC = CraftingOrderClassic
local UI  = COC.UI
local L   = COC.L

-- Taille : la lettre de Blizzard fait 20×15 (Minimap.xml). Notre logo, carré et détaillé, se lisait
-- mal à 16 (avis du user, 2026-09-28) ; à 22 il se lit, et la barre, accrochée en HAUT, descend vers
-- la minicarte sans la toucher (capture du user, même jour).
local ICON_SIZE = 22

UI._indicators = UI._indicators or {}   -- [key] = { def = def, frame = cadre ou nil }

local function bar()
    local mc = _G.MinimapCluster
    return mc and mc.IndicatorFrame
end

local function build(parent, def)
    local f = CreateFrame("Frame", nil, parent)
    local size = def.size or ICON_SIZE
    f:SetSize(def.width or size, def.height or size)
    f.layoutIndex = def.order
    f:EnableMouse(true)
    local tex = f:CreateTexture(nil, "ARTWORK")
    if def.atlas and def.useAtlasSize then
        tex:SetAtlas(def.atlas, true)
        tex:SetPoint("TOPLEFT")
    else
        if def.atlas then tex:SetAtlas(def.atlas) else tex:SetTexture(def.texture) end
        tex:SetAllPoints()
    end
    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:AddLine("Crafting Order")
        if def.tooltip then def.tooltip(GameTooltip) end
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)
    if def.onClick then f:SetScript("OnMouseUp", function(_, button) def.onClick(button) end) end
    f:Hide()
    return f
end

function UI:DefineIndicator(key, def)
    self._indicators[key] = { def = def }
end

function UI:SetIndicator(key, shown)
    local b, ind = bar(), self._indicators[key]
    if not (b and ind) then return false end
    if not ind.frame then
        if not shown then return false end   -- rien à éteindre : pas de cadre créé pour rien
        ind.frame = build(b, ind.def)
    end
    ind.frame:SetShown(shown and true or false)
    if b.Layout then b:Layout() end   -- la barre se recompose : l'icône prend ou rend sa place
    return true
end

-- ------------------------------------------------------------------
-- 1er usage : « une nouvelle version est disponible » (demande du user, 2026-09-28)
-- ------------------------------------------------------------------
-- Même état que la pastille du bouton de minicarte : UI:SetUpdateBadge (Minimap.lua) appelle
-- SetUpdateIndicator, donc tout ce qui allume ou éteint l'une allume ou éteint l'autre.
UI:DefineIndicator("update", {
    texture = "Interface\\AddOns\\CraftingOrderClassic\\Textures\\icon",   -- le logo « CO »
    order   = 3,
    tooltip = function(tt)
        if not UI._updateVer then return end
        tt:AddLine(string.format(L["Nouvelle version disponible : %s"], UI._updateVer), 1, 1, 1)
        local D = COC.Directory
        tt:AddLine(string.format(L["Tu as la %s. Mets l'addon à jour depuis CurseForge."],
            (D and D._myVerStr) or "?"), 0.8, 0.8, 0.8, true)
    end,
    onClick = function()   -- le détail, comme /co version
        if COC.Directory and COC.Directory.VersionCmd then COC.Directory:VersionCmd("") end
    end,
})

function UI:SetUpdateIndicator(shown) return self:SetIndicator("update", shown) end
