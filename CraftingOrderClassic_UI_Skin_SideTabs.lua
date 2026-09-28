-- CraftingOrderClassic_UI_Skin_SideTabs.lua — la rangée d'ONGLETS LATÉRAUX de la fenêtre principale
-- (palier 3 de la revue d'interface, décision D1 : « les onglets sur la droite, comme la vue métier »).
-- Montage copié de la fenêtre des métiers de Camelot (Blizzard_ProfessionsFrame.xml, dossier
-- Camelot) : le premier onglet au flanc DROIT du cadre, 60 px sous son haut, chacun 2 px sous le
-- précédent. Chaque onglet est un Skin.MakeSideTab (LargeSideTabButtonTemplate) : l'art, le survol,
-- la sélection et le son du clic sont ceux de Blizzard.
--
-- Même contrat que Skin.MakeTabs (les languettes du haut, qui restent pour la vue métier), pour que
-- l'appelant change à peine : bar.buttons[id], bar:Select(id), bar:SetText(id, texte). En plus :
--   bar:SetCount(id, n) — un compteur sur l'icône, puisqu'un onglet latéral n'affiche aucun texte ;
--   bar:Label(id)       — le libellé de base, pour le titre de la fenêtre.
-- Ici SetText change l'INFOBULLE : le nom d'un onglet ne se lit plus qu'au survol et dans le titre.

local COC  = CraftingOrderClassic
local Skin = COC.UI.Skin

local FIRST_Y, GAP = -60, -2

-- Icône : un fichier (`icon`), ou une paire d'atlas (`atlas = { actif, inactif }`) comme les onglets
-- du social de Forever, que SetChecked alterne. Un atlas absent du client retombe sur le fichier.
local function setIcon(b, d)
    local a = d.atlas
    if a and b.SetChecked and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(a[1]) then
        b.activeAtlas, b.inactiveAtlas = a[1], a[2] or a[1]
        b.fillToInterior = false   -- un atlas garde sa taille ; fillToInterior le forcerait à 50 px
        return
    end
    if d.icon and b.icon then b.icon:SetTexture(d.icon) end
end

local function showTip(b)
    GameTooltip:SetOwner(b, "ANCHOR_RIGHT", -4, -4)
    GameTooltip:SetText(b.cocTip or "", 1, 1, 1)
    GameTooltip:Show()
end

-- Le compteur : un chiffre en bas à droite de l'icône, comme le compte d'une pile d'objets.
local function addCount(b)
    local c = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    c:SetPoint("BOTTOMRIGHT", b.icon or b, "BOTTOMRIGHT", -4, 4)
    c:Hide(); b.cocCount = c
end

-- `defs` = { { id, label, icon, atlas? }, ... } dans l'ordre d'affichage ; `onSelect(id)` au clic.
function Skin.MakeSideTabs(f, defs, onSelect)
    local bar, prev = { buttons = {}, labels = {} }, nil
    for _, d in ipairs(defs) do
        local b = Skin.MakeSideTab(f, (not d.atlas) and d.icon or nil)
        setIcon(b, d)
        if prev then b:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, GAP)
        else b:SetPoint("TOPLEFT", f, "TOPRIGHT", 0, FIRST_Y) end
        -- On REMPLACE le survol du gabarit (cf. Skin.MakeSideTab) : l'infobulle suit `cocTip`.
        b.cocTip = d.label
        b:SetScript("OnEnter", showTip); b:SetScript("OnLeave", GameTooltip_Hide)
        b:SetScript("OnClick", function() onSelect(d.id) end)
        addCount(b)
        bar.buttons[d.id], bar.labels[d.id], prev = b, d.label, b
    end
    -- L'onglet actif reste cliquable (le gabarit ne le désactive pas) : re-cliquer ne fait rien de plus
    -- qu'un ShowTab sur l'onglet déjà ouvert.
    function bar:Select(id)
        for tid, b in pairs(self.buttons) do
            local on = (tid == id)
            if b.SetChecked then b:SetChecked(on) elseif b.SetSelected then b:SetSelected(on) end
        end
    end
    function bar:SetText(id, text)
        local b = self.buttons[id]; if b then b.cocTip = text end
    end
    function bar:SetCount(id, n)
        local b = self.buttons[id]; if not (b and b.cocCount) then return end
        b.cocCount:SetText((n and n > 0) and tostring(n) or "")
        b.cocCount:SetShown(n and n > 0 and true or false)
    end
    function bar:Label(id) return self.labels[id] end
    return bar
end
