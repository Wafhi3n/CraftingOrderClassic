-- CraftingOrderClassic_UI_Skin_Backgrounds.lua — les FONDS de la fenêtre des métiers de Forever
-- (palier 6 de la revue d'interface ; le user : « ça doit être le même que les métiers »).
--
-- Relevé dans la source Forever (Blizzard_ProfessionsFrame.xml, dossier Camelot, et
-- Blizzard_ProfessionsRecipeList.xml) : la page des métiers pose l'atlas PEINT
-- `Profession-Background-Template2` à sa taille sous le titre (TOPLEFT 3,-21), puis deux ENCARTS
-- séparés : la liste de recettes (fond `Professions-background-summarylist` + bordure NineSlice
-- `InsetFrameTemplate`) et la fiche (la même bordure, fond caché : la pierre de la page se voit).
-- Plus de marbre ni de barres sculptées entre blocs : c'étaient les briques de l'Era.

local COC  = CraftingOrderClassic
local Skin = COC.UI.Skin

local PAGE_ATLAS = "Profession-Background-Template2"
local LIST_ATLAS = "Professions-background-summarylist"

local function atlasInfo(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name)
end

-- L'art de page couvre `area` (un cadre SANS texture, qui ne sert qu'à donner le rectangle), peint
-- sur `owner` en BACKGROUND : les enfants de owner restent au-dessus. L'atlas est posé à sa LARGEUR
-- native puis prolongé par sa portion droite EN MIROIR — la méthode de la vue métier
-- (_ProfWindow_Camelot_PageArt.lua, validée en jeu) : un art peint à taille fixe s'écrase si on
-- l'étire, en miroir la couture est continue et l'échelle du motif conservée. Rend vrai si peint.
function Skin.PageArt(owner, area)
    local info = atlasInfo(PAGE_ATLAS)
    if not (info and info.width and info.width > 0) then return false end
    local file = info.file or info.fileID or info.filename
    local uL, uR = info.leftTexCoord or 0, info.rightTexCoord or 1
    local vT, vB = info.topTexCoord or 0, info.bottomTexCoord or 1
    local main = owner:CreateTexture(nil, "BACKGROUND", nil, -5)
    local fill = owner:CreateTexture(nil, "BACKGROUND", nil, -5)
    main:SetPoint("TOPLEFT", area, "TOPLEFT"); main:SetPoint("BOTTOMLEFT", area, "BOTTOMLEFT")
    fill:SetPoint("TOPLEFT", main, "TOPRIGHT"); fill:SetPoint("BOTTOMRIGHT", area, "BOTTOMRIGHT")
    if not file then                       -- atlas sans fichier lisible : l'art étiré, jamais vide
        main:SetAtlas(PAGE_ATLAS, false); main:SetWidth(info.width); fill:SetAtlas(PAGE_ATLAS, false)
        return true
    end
    main:SetTexture(file); fill:SetTexture(file)
    local function layout()
        local w = area:GetWidth() or 0
        if w <= 0 then return end
        local artW = math.min(info.width, w)
        main:SetWidth(artW)
        main:SetTexCoord(uL, uL + (uR - uL) * (artW / info.width), vT, vB)
        local band = w - artW
        if band > 0 then
            local frac = math.min(1, band / info.width)
            fill:SetTexCoord(uR, uR - (uR - uL) * frac, vT, vB); fill:Show()
        else
            fill:Hide()
        end
    end
    area:HookScript("OnSizeChanged", layout)
    layout()
    return true
end

-- Le fond de page d'une fenêtre `ButtonFrameTemplate` (Skin.MakeWindow, opts.pageArt) : de sous le
-- titre (3,-21, l'ancre de Blizzard) jusqu'au bas de `f.Inset`, la bande grise comprise. Le marbre de
-- l'Inset, sa bordure d'ensemble et les stries de la bande sont masqués : chez Blizzard, ce sont les
-- ENCARTS de chaque bloc qui portent une bordure (Skin.WrapInset), pas la page entière.
function Skin.WindowPageArt(f)
    local area = CreateFrame("Frame", nil, f)
    area:SetPoint("TOPLEFT", f, "TOPLEFT", 3, -21)
    area:SetPoint("BOTTOMRIGHT", f.Inset or f, "BOTTOMRIGHT", 0, 0)
    if not Skin.PageArt(f, area) then return false end
    local inset = f.Inset
    if inset and inset.Bg then inset.Bg:Hide() end
    if inset and inset.NineSlice then inset.NineSlice:Hide() end
    if f.TopTileStreaks then f.TopTileStreaks:Hide() end
    return true
end

-- Encadre `frame` d'un ENCART de la page des métiers. kind = "list" (fond de la liste de recettes)
-- ou "page" (fond caché : la pierre de la page se voit à travers, comme la fiche de recette).
-- `dl`/`dr` : retrait des bords gauche/droit (1 px de chaque côté d'une jointure = l'écart de 2 px
-- que Blizzard laisse entre la liste et la fiche). Le gabarit a `useParentLevel` : l'encart reste au
-- niveau de `frame`, son contenu passe au-dessus.
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
