-- CraftingOrderClassic_ProfWindow_Camelot_PageArt.lua — prolonger le FOND de la page native dans
-- la bande que notre greffe ajoute à droite de la fenêtre de métier de WoW: Forever.
--
-- Extrait de _ProfWindow_Camelot.lua le 2026-09-20 (anti-monolithe : le fichier repassait à 508
-- lignes — même motif qu'au 2026-09-19 pour _Camelot_Open). Ici, une seule chose : de l'art.
--
-- Appelé en dépendance MOLLE depuis la greffe : sans ce fichier la bande reste nue, rien ne casse.

local COC = CraftingOrderClassic
local PW  = COC.ProfWindow
local Api = COC.Api
if not (PW and Api) then return end
-- Même garde de saveur que la greffe : listé dans les QUATRE .toc (parité), donc chargé sur l'Era
-- aussi, où il n'y a ni fenêtre native de métier moderne ni bande à remplir.
if not Api.IS_MAINLINE then return end

-- ---------------------------------------------------------------- fond de page

-- Le fond de la page native (atlas `Profession-Background-Template2`) est posé en TAILLE D'ATLAS :
-- il ne s'étire pas. Élargir le cadre laisse donc une bande nue à droite, qui s'arrête net là où la
-- fenêtre d'origine finissait — mesuré le 2026-09-20 : l'art s'arrête à x=511 pour un cadre qui va
-- à 737. On le prolonge dans cette bande avec le MÊME atlas, mais sans sa taille : il est donc
-- ÉTIRÉ, et un art dessiné en taille fixe ne s'étire jamais parfaitement. D'où `PW.TUNE.pageFill`,
-- qui coupe le prolongement d'un mot si le rendu ne convient pas.
-- Les 2 px de marge ne sont pas choisis : ce sont ceux que Blizzard s'accorde à lui-même à gauche
-- et en bas (relevé : art 38..511 / 265, cadre 36..737 / 263).
local function pageArtTexture(page)
    if not (page and page.GetRegions) then return nil end
    for _, r in ipairs({ page:GetRegions() }) do
        if r.GetObjectType and r:GetObjectType() == "Texture"
           and r.GetDrawLayer and r:GetDrawLayer() == "BACKGROUND"
           and r.GetAtlas and r:GetAtlas() then
            return r
        end
    end
end

-- Remplit la bande avec la portion DROITE de l'art, EN MIROIR. Étirer l'atlas entier serait plus
-- simple mais l'écraserait : la bande fait ~224 px pour un art de 473 (relevé 2026-09-20), soit une
-- compression de moitié — un motif de pierre écrasé se voit tout de suite. En miroir, la couture au
-- bord est continue et l'échelle du motif est conservée. `SetTexCoord` avec gauche > droite retourne
-- l'image ; on prend la fraction de l'atlas qui correspond EXACTEMENT à la largeur à couvrir.
-- Repli si l'atlas n'est pas lisible : l'étirement, moins beau mais jamais vide.
local function mirrorFill(fill, src, native)
    local atlas = src:GetAtlas()
    local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
    local file = info and (info.file or info.fileID or info.filename)
    local artW = src:GetWidth() or 0
    local bandW = (native:GetRight() or 0) - (src:GetRight() or 0)
    if not (file and artW > 0 and bandW > 0) then
        fill:SetAtlas(atlas, false)       -- repli : l'art étiré plutôt qu'une bande nue
        return
    end
    local uL, uR = info.leftTexCoord or 0, info.rightTexCoord or 1
    local vT, vB = info.topTexCoord or 0, info.bottomTexCoord or 1
    local frac = math.min(1, bandW / artW)
    fill:SetTexture(file)
    fill:SetTexCoord(uR, uR - (uR - uL) * frac, vT, vB)
end

function PW:_FillPageArt(native, on)
    local page = native and native.CraftingPage
    if not page then return end
    local fill = page._cocPageFill
    if not on then
        if fill then fill:Hide() end
        return
    end
    local src = pageArtTexture(page)
    if not src then return end
    if not fill then
        fill = page:CreateTexture(nil, "BACKGROUND", nil, -3)
        page._cocPageFill = fill
    end
    fill:ClearAllPoints()
    fill:SetPoint("TOPLEFT", src, "TOPRIGHT", 0, 0)
    fill:SetPoint("BOTTOMRIGHT", native, "BOTTOMRIGHT", -2, 2)
    mirrorFill(fill, src, native)
    fill:Show()
end
