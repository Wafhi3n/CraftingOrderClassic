-- CraftingOrderClassic_UI_Skin_Backgrounds.lua — les FONDS façon fenêtre des métiers de Forever
-- (palier 6 de la revue d'interface ; le user : « ça doit être le même que les métiers »).
--
-- Relevé dans la source Forever : le cadre des métiers hérite PortraitFrameTemplate, donc le MÊME
-- fond rocher tuilé et les mêmes stries sous le titre que notre ButtonFrameTemplate. Ce qui fait son
-- allure, ce sont ses ENCARTS : la liste de recettes (fond `Professions-background-summarylist` +
-- bordure NineSlice `InsetFrameTemplate`, Blizzard_ProfessionsRecipeList.xml) et la fiche (même
-- bordure). Plus de marbre d'un seul tenant ni de barres sculptées entre blocs.
--
-- ⚠️ PAS l'atlas `Profession-Background-Template2` en fond de fenêtre (essayé le 2026-09-28, retiré) :
-- c'est l'image COMPOSÉE de la page des métiers, avec des ombres peintes là où SA liste (274 de large)
-- et SON bord droit tombent. Posée sous nos colonnes (liste de 333, autres onglets), elle traçait de
-- gros traits noirs au milieu du contenu, le miroir en recopiait un second, et son haut dessiné pour la
-- barre de rang gâchait notre bande de titre. La vue métier peut l'employer parce qu'elle prolonge la
-- page de Blizzard à l'identique ; une fenêtre à nous, non.

local COC  = CraftingOrderClassic
local Skin = COC.UI.Skin

local LIST_ATLAS = "Professions-background-summarylist"

local function atlasInfo(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name)
end

-- Une fenêtre ButtonFrameTemplate dont chaque bloc est un encart (Skin.MakeWindow, opts.insets) : le
-- marbre de `f.Inset` et sa bordure d'ensemble sont masqués — chez Blizzard, ce sont les ENCARTS qui
-- portent une bordure, pas la page entière ; le rocher du cadre se voit entre eux.
function Skin.WindowInsetLook(f)
    local inset = f and f.Inset
    if inset and inset.Bg then inset.Bg:Hide() end
    if inset and inset.NineSlice then inset.NineSlice:Hide() end
end

-- Encadre `frame` d'un ENCART de la fenêtre des métiers. kind = "list" (le fond sombre de la liste de
-- recettes) ou "page" (fond caché : le rocher du cadre se voit à travers). `dl`/`dr` : retrait des
-- bords gauche/droit (1 px de chaque côté d'une jointure = l'écart de 2 px que Blizzard laisse entre
-- la liste et la fiche). Le gabarit a `useParentLevel` : l'encart reste au niveau de `frame`, son
-- contenu (les enfants de `frame`) passe au-dessus.
function Skin.WrapInset(frame, kind, dl, dr)
    local ok, ins = pcall(CreateFrame, "Frame", nil, frame, "InsetFrameTemplate")
    if not (ok and ins) then return nil end
    ins:SetPoint("TOPLEFT", dl or 0, 0); ins:SetPoint("BOTTOMRIGHT", -(dr or 0), 0)
    local bg = ins.Bg
    if bg then
        if kind == "list" and atlasInfo(LIST_ATLAS) then
            bg:SetHorizTile(false); bg:SetVertTile(false); bg:SetAtlas(LIST_ATLAS)
        elseif kind == "list" then
            bg:SetColorTexture(0, 0, 0, 0.5)
        else
            bg:Hide()
        end
    end
    return ins
end

-- Un encart posé sur un RECTANGLE d'un panneau (les onglets sans SPEC : Carnet, Aide, Nouveautés).
-- Le cadre porteur est au niveau du panneau : le contenu déjà posé dans le panneau (niveau + 1) reste
-- au-dessus de la bordure. Rect en coordonnées du panneau : (x1, y1) haut-gauche, (x2, y2) bas-droit
-- mesurés depuis le bord BAS-DROIT (x2 ≤ 0, y2 ≥ 0).
function Skin.PanelInset(panel, kind, x1, y1, x2, y2)
    local box = CreateFrame("Frame", nil, panel)
    box:SetFrameLevel(panel:GetFrameLevel())
    box:SetPoint("TOPLEFT", panel, "TOPLEFT", x1, y1)
    box:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", x2, y2)
    Skin.WrapInset(box, kind)
    return box
end
