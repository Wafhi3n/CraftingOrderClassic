-- CraftingOrderClassic_ProfWindow_DockMissing_Filter.lua — le FILTRE et la marque des WRITS de la
-- vue « Manquantes » de la colonne (la vue elle-même vit dans _DockViews.lua).
--
-- LE FILTRE (demande du user, 2026-11-16) : un menu dans l'en-tête, avec les CATÉGORIES de la liste
-- des plans de l'onglet Commande (« Poignets · Mailles », « Hache à une main »…) et « Writs ».
-- Un menu et pas des sections repliables (choix du user, même jour) : la liste garde son ordre de
-- progression, le filtre ne fait que la resserrer. La catégorie est celle de la liste des plans,
-- calculée par le MÊME code (RecipeCats.SectionForSpell, puis COC.SectionOf) : les deux listes ne
-- peuvent pas se contredire sur ce qu'est une pièce. Le choix vit le temps de la session, par
-- métier : « Mailles » choisi en Forge ne vide pas la Couture.
--
-- LES WRITS (D13 de docs/specs/writs-aca.md) : la ligne d'un plan dont l'objet est demandé par un
-- Craftsman's Writ porte l'icône du writ, pleine si JE le porte, éteinte sinon — la même marque que
-- la vue Profit (D7), et le même détail au survol (PW._AddWritLines, appelé par la vue).
--
-- POURQUOI UN FICHIER À PART : les branches du banc retouchent le code de la vue dans _DockViews.lua ;
-- ce qui est neuf vit ici, et la vue n'y gagne que quelques appels, loin de leurs lignes.
-- Le cœur (catégories, menu, filtre, choix, « où » en une ligne) est PUR : testé sans client par
-- tests/test_missing_filter.lua.

local COC  = CraftingOrderClassic
local PW   = COC.ProfWindow
local Skin = COC.UI.Skin
local L    = COC.L

-- Repli si le client ne rend pas l'icône du writ lui-même (lue par son identifiant d'abord).
local WRIT_ICON = "Interface\\Icons\\INV_Scroll_03"
-- Les deux valeurs du menu qui ne sont pas une catégorie. Des jetons, pas `nil` : « aucun filtre »
-- doit pouvoir être COCHÉ dans le menu (même raison que Stats_Filter).
local ALL, WRITS = "*", "\1writs"
PW.MISS_ALL, PW.MISS_WRITS = ALL, WRITS

-- ------------------------------------------------------------------
-- Catégories et filtre (purs)
-- ------------------------------------------------------------------

-- La catégorie d'une recette, celle de la liste des plans de l'onglet Commande : le classement du
-- SORT d'abord (un enchantement n'a pas d'objet, il se range par emplacement), puis celui de l'OBJET
-- produit. Lecture statique (GetItemInfoInstant) : sans cache d'objets, sûre au remplissage.
local function facetOf(e)
    local RC, sec, order = COC.RecipeCats, nil, nil
    if RC and RC.SectionForSpell then sec, order = RC.SectionForSpell(e.spellID) end
    if not sec and COC.SectionOf then sec, order = COC.SectionOf(e.itemID) end
    return sec or L["Autres"], order or 900
end

local function wantedByWrit(e)
    local W = COC.Writs
    return (W and e.itemID and W:ForItem(e.itemID)) ~= nil
end

-- Les entrées que laisse passer le choix `sel` : nil ou ALL = toutes, WRITS = celles qu'un writ
-- demande, sinon une catégorie. Rend une NOUVELLE table dès qu'un filtre s'applique.
function PW:_MissingFilter(list, sel)
    if not sel or sel == ALL then return list end
    local out = {}
    for _, e in ipairs(list) do
        local keep
        if sel == WRITS then keep = wantedByWrit(e) else keep = (facetOf(e) == sel) end
        if keep then out[#out + 1] = e end
    end
    return out
end

local function writsText(n)
    return "|T" .. WRIT_ICON .. ":12|t " .. L["Writs"] .. (n and (" |cFF888888(" .. n .. ")|r") or "")
end

-- Ce que le menu affiche pour un choix (sans compte : il bougerait sous les yeux du joueur).
local function selText(sel)
    if sel == WRITS then return writsText() end
    return sel or L["Toutes"]
end

-- Le menu : « Toutes », « Writs » s'il y en a, puis chaque catégorie PRÉSENTE, dans l'ordre de la
-- liste des plans, avec son compte. Une catégorie vide n'a pas d'entrée : elle n'ouvrirait qu'une
-- liste vide.
function PW:_MissingFacetItems(list)
    local byLabel, facets, nWrit = {}, {}, 0
    for _, e in ipairs(list) do
        local sec, order = facetOf(e)
        local f = byLabel[sec]
        if not f then
            f = { label = sec, order = order, n = 0 }
            byLabel[sec] = f; facets[#facets + 1] = f
        end
        f.n = f.n + 1
        if wantedByWrit(e) then nWrit = nWrit + 1 end
    end
    table.sort(facets, function(a, b)
        if a.order ~= b.order then return a.order < b.order end
        return a.label < b.label
    end)
    local items = { { value = ALL, text = L["Toutes"] .. " |cFF888888(" .. #list .. ")|r" } }
    if nWrit > 0 then items[#items + 1] = { value = WRITS, text = writsText(nWrit) } end
    for _, f in ipairs(facets) do
        items[#items + 1] = { value = f.label, text = f.label .. " |cFF888888(" .. f.n .. ")|r" }
    end
    return items
end

-- Le choix courant, PAR MÉTIER, le temps de la session.
function PW:_MissSel() return self._missSel and self._missSel[self.profKey or "?"] or nil end
function PW:_SetMissSel(v)
    self._missSel = self._missSel or {}
    self._missSel[self.profKey or "?"] = (v ~= ALL) and v or nil
end

-- La liste à afficher, appelée par _FillDockMissing avec TOUTES les manquantes. Retient la liste
-- entière pour le menu (peuplé à son ouverture seulement), et cale le menu sur le choix appliqué.
-- Une catégorie vidée (tout appris, writ rendu) retombe sur « Toutes » : un filtre qui ne montre plus
-- rien ressemble à une vue cassée.
function PW:_MissFilterApply(mp, all)
    mp.all = all
    local sel = self:_MissSel()
    local list = self:_MissingFilter(all, sel)
    if sel and #list == 0 then self:_SetMissSel(nil); sel, list = nil, all end
    if mp.dd then mp.dd.value = sel or ALL; mp.dd:SetText(selText(sel)) end
    return list
end

-- ------------------------------------------------------------------
-- Le menu (cadres)
-- ------------------------------------------------------------------

-- Sur la ligne du titre, à DROITE (là où la vue Profit pose sa case). Largeur FIXE : la colonne se
-- dimensionne sur ses languettes, et un menu qui s'élargirait à son libellé pousserait la fenêtre
-- native de Forever. Le titre s'arrête contre lui et se tronque par « … » (cf. _BuildDockViews).
-- Sa liste est une FONCTION, évaluée à l'ouverture seulement : jamais de balayage au remplissage.
function PW:_BuildMissFilter(mp)
    local dd = Skin.MakeDropdown(nil, mp, 92, function() return PW:_MissingFacetItems(mp.all or {}) end,
        { onSelect = function(v) PW:_OnMissFilter(v) end })
    dd:SetPoint("RIGHT", mp, "TOPRIGHT", -6, -13)
    dd.value = ALL
    dd:SetText(selText(nil))
    mp.dd = dd
end

-- Greffée, la colonne est protégée comme son hôte : en combat, repeindre la liste est refusé (cf.
-- l'en-tête de _DockViews). On le dit, et le menu revient à ce qui est réellement affiché.
function PW:_OnMissFilter(v)
    local mp = self.missPanel
    if InCombatLockdown and InCombatLockdown() and mp and mp:IsProtected() then
        print("|cFF33DD88Crafting Order|r " .. L["Impossible en combat — réessaie après le combat."])
        local cur = self:_MissSel()
        mp.dd.value = cur or ALL
        mp.dd:SetText(selText(cur))
        return
    end
    self:_SetMissSel(v)
    self:_FillDockMissing()
end

-- ------------------------------------------------------------------
-- La marque d'un writ sur une ligne
-- ------------------------------------------------------------------

-- Même règle que la vue Profit. `wanted` = W:WantedItems(), lu UNE fois par remplissage. Ligne
-- RECYCLÉE : sans writ, tout est remis à zéro, sinon elle garderait l'icône et l'infobulle de la
-- recette d'avant. Le nom s'arrête contre la marque quand elle est là, contre le rang sinon.
function PW._MissMarkWrit(row, itemID, wanted)
    local W = COC.Writs
    local m = (W and itemID) and W:ProfitMark(itemID, wanted) or nil
    row.writ = m
    if m then
        local gi = COC.Api.GetItemIcon
        row.wr:SetTexture((gi and gi(m.entry.writ)) or WRIT_ICON)
        row.wr:SetDesaturated(not m.held)
        row.wr:Show()
    else
        row.wr:Hide()
    end
    row.nm:SetPoint("RIGHT", m and row.wr or row.lv, "LEFT", -4, 0)
end

-- ------------------------------------------------------------------
-- Le « où » en une ligne (vue Profit)
-- ------------------------------------------------------------------

-- Ce que dit le clic sur une recette pas apprise de la vue Profit (décision 19 de
-- docs/specs/rentabilite-forever.md) quand aucun PNJ n'a de position à épingler : la même réponse
-- que l'infobulle de « Manquantes », en UNE ligne pour le chat. Le texte du jeu tient sur plusieurs
-- lignes ; le chat n'en veut qu'une.
function PW._MissWhereText(prof, sid)
    local S = COC.Sources
    if not (S and sid) then return nil end
    local fromGame = S.SourceText and S:SourceText(prof, sid)
    if fromGame then
        local one = fromGame:gsub("|n", " · "):gsub("\r?\n", " · ")
        return one
    end
    local kind = S:SourceKind(prof, sid)
    local K = PW._MissKindText
    local txt = (K and K[kind]) and K[kind]() or L["Source inconnue"]
    local origin = S.SourceOrigin and S:SourceOrigin(prof, sid)
    if origin then txt = txt .. " — " .. origin.text end
    return txt
end
