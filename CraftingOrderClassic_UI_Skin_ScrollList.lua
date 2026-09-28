-- CraftingOrderClassic_UI_Skin_ScrollList.lua — la LISTE DÉFILANTE moderne du kit, palier 1 de la
-- revue d'interface (docs/revue-ui-mainline.md). Mêmes briques que la liste de recettes des métiers
-- de Forever : `WowScrollBoxList` + `MinimalScrollBar`, à la place de `UIPanelScrollFrameTemplate`
-- et de son pool de lignes tenu à la main. Depuis le palier 2d, aussi le cadre défilant d'une PAGE
-- (Skin.MakeScrollFrame : l'Aide, les Nouveautés, la bourse d'un artisan).
--
-- Ce que la primitive retire à l'appelant, et qui a chacun coûté une session :
--   · le pool de lignes et son invariant « pool ≥ lignes visibles », sans quoi la fin de la liste est
--     inatteignable (mémoire coc-virtualized-list-pool-invariant) ;
--   · le fenêtrage au défilement et le bornage quand la liste rétrécit sous un filtre ;
--   · `Skin.AutoHideScroll` : la barre ne se montre que si la liste déborde.
--
-- Pas de XML maison : la vue accepte un TYPE de cadre nu (`"Button"`) du moment que la hauteur des
-- lignes est donnée (ScrollBoxListView.lua, l. 36-55). Ici par `opts.extent`, nombre ou fonction.
--
-- ⚠️ PAS DANS LA COLONNE GREFFÉE, pour l'instant. Elle est protégée comme la fenêtre des métiers qui
-- l'héberge, et une ScrollBox repositionne ses lignes à chaque défilement : refusé en combat
-- (risque 4 de la revue). Fenêtre principale seulement, jusqu'à un relevé en combat.

local COC  = CraftingOrderClassic
local Skin = COC.UI.Skin

local BAR_GAP = 4   -- entre la liste et sa barre (MinimalScrollBar fait 8 px de large)

-- Marge entre le bord droit d'une liste et le séparateur de sa colonne. Les SPEC réservent à côté de
-- chaque liste une gouttière de 22 px (`plansGutter`, `resGutter`…) : elle logeait la barre de
-- l'ancien cadre, qui DÉBORDAIT de la liste. La barre moderne est logée dedans, et la gouttière
-- restait vide, un « jeu » entre la barre et le séparateur (vu en jeu le 2026-09-28). Une liste
-- s'ancre donc sur le bas-droit de SA GOUTTIÈRE, à LIST_EDGE px du bord.
Skin.LIST_EDGE = 4

-- La liste défilante. `host` = le cadre qu'elle remplit ; la barre se loge dans son bord droit.
-- opts :
--   extent = hauteur d'une ligne : nombre, ou fonction(donnée) -> nombre (en-têtes plus hauts) ;
--   build  = fonction(ligne), appelée UNE fois par cadre du pool : y créer textes et textures ;
--   fill   = fonction(ligne, donnée), appelée à chaque affichage d'une donnée ;
--   empty  = texte (facultatif) affiché en haut de la liste quand elle n'a AUCUNE donnée. Une liste
--            défilante ne crée pas de ligne sans donnée : l'ancien geste « écrire le message dans la
--            ligne 1 du pool » n'y a plus de ligne où écrire.
-- Rend { box, bar, SetData(liste, garderLaPosition, quiet), SetEmpty(texte) } ; SetEmpty change ce
-- texte pour une liste à plusieurs vues, qui n'a pas une seule raison d'être vide (Carnet).
-- ⚠️ Une ligne du pool sert tour à tour à n'importe quelle donnée : `fill` doit TOUT reposer, jamais
-- supposer ce qu'affichait la ligne avant.
function Skin.MakeScrollList(host, opts)
    local box = CreateFrame("Frame", nil, host, "WowScrollBoxList")
    local bar = CreateFrame("EventFrame", nil, host, "MinimalScrollBar")
    bar:SetPoint("TOPRIGHT", host, "TOPRIGHT", 0, 0)
    bar:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, 0)

    local view = CreateScrollBoxListLinearView()
    if type(opts.extent) == "function" then
        view:SetElementExtentCalculator(function(_, data) return opts.extent(data) end)
    else
        view:SetElementExtent(opts.extent or 20)
    end
    view:SetElementInitializer("Button", function(row, data)
        if not row.cocBuilt then
            row.cocBuilt = true
            opts.build(row)
        end
        opts.fill(row, data)
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(box, bar, view)

    -- Avec la barre, la liste s'arrête avant elle ; sans, elle prend toute la largeur.
    local withBar = { CreateAnchor("TOPLEFT", host, "TOPLEFT", 0, 0),
                      CreateAnchor("BOTTOMRIGHT", bar, "BOTTOMLEFT", -BAR_GAP, 0) }
    local without = { CreateAnchor("TOPLEFT", host, "TOPLEFT", 0, 0),
                      CreateAnchor("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, 0) }
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(box, bar, withBar, without)

    local emptyText
    local function emptyFS()
        if not emptyText then
            emptyText = host:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            emptyText:SetPoint("TOPLEFT", 8, -8); emptyText:SetPoint("RIGHT", -8, 0)
            emptyText:SetJustifyH("LEFT"); emptyText:Hide()
        end
        return emptyText
    end
    if opts.empty then emptyFS():SetText(opts.empty) end

    -- `quiet` : vider la liste SANS son message d'absence, quand c'est un autre texte qui explique
    -- déjà pourquoi il n'y a rien (ex. Mes artisans sans aucun métier : l'en-tête le dit).
    local list = { box = box, bar = bar }
    function list:SetData(items, keepScroll, quiet)
        box:SetDataProvider(CreateDataProvider(items),
            keepScroll and ScrollBoxConstants.RetainScrollPosition or nil)
        if emptyText then emptyText:SetShown(#items == 0 and not quiet) end
    end
    function list:SetEmpty(text) emptyFS():SetText(text or "") end
    return list
end

-- ------------------------------------------------------------------ le cadre défilant d'une PAGE

-- Pour une PAGE, pas une liste (palier 2d) : l'Aide, les Nouveautés, la bourse d'un artisan — des
-- blocs composés, peints une fois dans un enfant qu'on fait défiler. Même montage que le gabarit
-- `ScrollFrameTemplate` de Forever (ScrollFrame_OnLoad, SecureUIPanelTemplates.lua) : un ScrollFrame
-- nu, une MinimalScrollBar, ScrollUtil.InitScrollFrameWithScrollBar. Le gabarit lui-même ne convient
-- pas : ses réglages sont des KeyValues XML lues à la CRÉATION, qu'un addon en Lua ne pose pas avant.
-- `host` = le cadre à remplir ; la barre se loge dans son bord droit et se cache quand la page tient
-- (plus de Skin.AutoHideScroll). Rend le ScrollFrame (`sf.ScrollBar` = la barre) : l'appelant pose
-- son contenu par sf:SetScrollChild(enfant), comme avec l'ancien cadre.
function Skin.MakeScrollFrame(host)
    local bar = CreateFrame("EventFrame", nil, host, "MinimalScrollBar")
    bar:SetPoint("TOPRIGHT", host, "TOPRIGHT", 0, 0)
    bar:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, 0)
    local sf = CreateFrame("ScrollFrame", nil, host)
    sf:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0)
    sf:SetPoint("BOTTOMRIGHT", bar, "BOTTOMLEFT", -BAR_GAP, 0)
    sf:EnableMouseWheel(true)
    bar:SetHideIfUnscrollable(true)
    ScrollUtil.InitScrollFrameWithScrollBar(sf, bar)
    bar:Update()
    sf.ScrollBar = bar
    return sf
end

-- Variante SUR PLACE (palier 7c, la colonne greffée) : rend un ScrollFrame que l'APPELANT ancre,
-- en gardant à droite la marge que prenait l'ancien `UIPanelScrollFrameTemplate` ; la barre fine
-- devient l'ENFANT du cadre, logée dans cette marge comme l'était l'ancienne. La colonne masque son
-- cadre défilant (la barre suit), le re-cale (idem) et lit son parent pour y poser d'autres vues :
-- avec l'hôte de MakeScrollFrame, la barre, sœur du cadre, restait affichée et le parent changeait.
-- Ici rien de cela ne bouge, seul l'art de la barre change.
function Skin.MakeScrollFrameIn(parent)
    local sf = CreateFrame("ScrollFrame", nil, parent)
    local bar = CreateFrame("EventFrame", nil, sf, "MinimalScrollBar")
    bar:SetPoint("TOPLEFT", sf, "TOPRIGHT", 6, 0)
    bar:SetPoint("BOTTOMLEFT", sf, "BOTTOMRIGHT", 6, 0)
    sf:EnableMouseWheel(true)
    bar:SetHideIfUnscrollable(true)
    ScrollUtil.InitScrollFrameWithScrollBar(sf, bar)
    sf.ScrollBar = bar
    return sf
end

-- ------------------------------------------------------------------ l'habillage d'une ligne

-- Emprunté à la liste de recettes des métiers (Blizzard_ProfessionsRecipeList.xml) PAR RÉFÉRENCE :
-- les atlas et les mesures, pas les gabarits, qui ne se chargent qu'avec la fenêtre des métiers
-- (risque 2 de la revue). En-tête = `ListHeaderVisualTemplate` (barre sombre, +/- à DROITE) ;
-- élément = `ProfessionsRecipeListRecipeTemplate` (survol et sélection en atlas).

-- Un atlas absent du client rendrait une texture VIDE, sans erreur : on vérifie, et on retombe sur
-- l'ancien fichier. Les atlas des métiers sont passés par la sonde du labo (26/26) ; ceux de la
-- barre d'en-tête et du +/-, pas encore.
local function atlasOr(tex, atlas, useSize, fallback)
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
        tex:SetAtlas(atlas, useSize)
        return true
    end
    if fallback then tex:SetTexture(fallback) end
    return false
end

-- Crée, une fois par cadre du pool, les deux habillages. `Skin.ListRowKind` montre le bon.
function Skin.ListRowArt(row)
    row.hdrBg = row:CreateTexture(nil, "BACKGROUND")
    atlasOr(row.hdrBg, "common-button-list-collapseExpand", false)
    row.hdrBg:SetAllPoints()
    row.hdrHi = row:CreateTexture(nil, "HIGHLIGHT")
    atlasOr(row.hdrHi, "common-button-list-collapseExpand", false)
    row.hdrHi:SetAllPoints(); row.hdrHi:SetBlendMode("ADD"); row.hdrHi:SetAlpha(0.4)
    row.collapse = row:CreateTexture(nil, "ARTWORK")
    row.collapse:SetPoint("RIGHT", -6, 0)
    -- Survol et sélection : l'atlas garde sa HAUTEUR native et s'étire en largeur (une liste plus
    -- étroite ou plus large que celle des métiers ne doit ni rogner ni déborder).
    row.hover = row:CreateTexture(nil, "HIGHLIGHT")
    atlasOr(row.hover, "Professions_Recipe_Hover", true)
    row.hover:SetAlpha(0.5)
    row.hover:ClearAllPoints(); row.hover:SetPoint("LEFT", 0, -1); row.hover:SetPoint("RIGHT", 0, -1)
    row.selected = row:CreateTexture(nil, "OVERLAY", nil, 2)
    atlasOr(row.selected, "Professions_Recipe_Active", true)
    row.selected:ClearAllPoints(); row.selected:SetPoint("LEFT", 0, -1); row.selected:SetPoint("RIGHT", 0, -1)
    row.selected:Hide()
end

-- kind : "header" (section : barre + libellé doré), "subheader" (sous-catégorie : libellé seul, sans
-- barre, sinon la liste est zébrée) ou "item". `collapsed` choisit le + ou le -.
function Skin.ListRowKind(row, kind, collapsed)
    local isHeader = kind ~= "item"
    row.hdrBg:SetShown(kind == "header")
    row.hdrHi:SetShown(kind == "header")
    row.collapse:SetShown(isHeader)
    if isHeader then
        local native = atlasOr(row.collapse, collapsed and "common-button-list-plus" or "common-button-list-minus", true,
            collapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
        if not native then row.collapse:SetSize(14, 14) end   -- un fichier n'a pas de taille d'atlas
        row.selected:Hide()
    end
    row.hover:SetShown(not isHeader)
end

-- Ligne « personne » (artisan, récolteur) : pastille de présence, nom, source à droite, surbrillance
-- bleue de la liste d'Amis (Skin.PersonHighlight). Posée sur une ligne de liste défilante par `build`.
-- Le nom est ANCRÉ contre la source au lieu d'être dimensionné : la liste fixe la largeur de ses
-- lignes elle-même (même raison que le nom d'un plan, cf. _UI_Post_Profit).
function Skin.ArtisanRowArt(r)
    r.selTex = Skin.PersonHighlight(r)
    r.dot = Skin.MakeStatusIcon(r, 14); r.dot:SetPoint("LEFT", 4, 0)
    r.src = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.src:SetPoint("RIGHT", -4, 0); Skin.ApplyShadow(r.src)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.name:SetPoint("LEFT", 18, 0); r.name:SetPoint("RIGHT", r.src, "LEFT", -6, 0)
    r.name:SetJustifyH("LEFT"); r.name:SetWordWrap(false); Skin.ApplyShadow(r.name)
end
