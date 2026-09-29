-- CraftingOrderClassic_ProfWindow_DockProfit.lua — la 4ᵉ vue de la colonne : « Profit ».
-- Spec : docs/specs/rentabilite-forever.md.
--
-- CE QU'ELLE RÉPARE. Sur Classic Era, la vue métier custom affichait le profit net de chaque
-- recette et savait TRIER la liste par rentabilité : c'est comme ça qu'on décidait quoi fabriquer
-- pour gagner de l'or. Le portage Forever n'a rien retiré de ce calcul — il a retiré sa SURFACE.
-- Là-bas on ne remplace pas la fenêtre de métier native (elle est meilleure que la nôtre), on lui
-- accole seulement la colonne Commandes : notre liste de recettes, et le tri avec elle, ne
-- s'affiche plus nulle part. Ce fichier ne réimplémente donc aucun calcul, il rend une surface.
--
-- CE QU'ELLE NE FAIT PAS, et c'est le fond du sujet. Elle ne TRIE PAS la liste de Blizzard et
-- n'écrit rien dans ses lignes — elles sont recyclées, et écrire dans le cadre hôte le teinte (on a
-- déjà payé ~800 actions de barres d'action refusées pour cette leçon). Elle liste à CÔTÉ, dans
-- notre colonne, et le clic repasse la main au jeu par sa propre voie (cf. openRecipe).
--
-- Elle s'ouvre sur les recettes APPRISES du métier ouvert, et seulement celles qui RAPPORTENT. La
-- case « Tout le métier » y ajoute, en gris, celles qu'on n'a pas apprises (arbitrage 9) : « que
-- rapporterait-elle » ; « où l'apprendre » reste la vue « Manquantes ». Une recette à perte n'affiche
-- rien — une ligne avec un nom et une colonne vide ne dit pas « à perte », elle dit « prix inconnu ».
--
-- L'ENCHANTEMENT se lit par le COÛT (arbitrage 12) : ses recettes sont des services sans objet
-- produit, donc sans prix de vente, et la liste des profits serait VIDE — indiscernable d'une vue
-- cassée. Elle y liste ce que coûte chaque enchantement à lancer, et le DIT dans son titre.
--
-- ⚠️ Elle n'existe PAS sans oracle de prix : la languette n'est même pas construite (cf. VIEWS dans
-- _DockViews). Un onglet qui ne sait ouvrir qu'un message d'absence est un onglet vide.

local COC  = CraftingOrderClassic
local PW   = COC.ProfWindow
local Skin = COC.UI.Skin
local L    = COC.L

local ROW_H  = 16
local NO_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

-- Métiers dont les recettes sont des SERVICES : pas d'objet produit, donc pas de prix de vente. La
-- vue y bascule en coût (arbitrage 12). Une table, pas un test de nom semé dans le code : le jour où
-- un autre métier s'y ajoute, c'est ici.
local COST_ONLY = { Enchanting = true }

-- Le mode de lecture d'un métier : vrai = le COÛT de chaque recette, faux = son PROFIT.
function PW:_ProfitCostMode(profKey)
    return COST_ONLY[profKey] == true
end

-- L'oracle de prix, ou nil. Rendu plutôt que testé : les appelants s'en servent ensuite, et deux
-- interrogations séparées du même oracle peuvent diverger entre-temps.
local function oracle()
    local PR = COC.Profit
    return (PR and PR:IsAvailable()) and PR or nil
end

-- ------------------------------------------------------------------
-- Construction (paresseuse, appelée par _BuildDockViews)
-- ------------------------------------------------------------------

-- « Tout le métier » : la case vit sur la ligne du titre, à DROITE, libellé à GAUCHE de la boîte
-- pour que la boîte tienne le bord. Le titre s'arrête contre le libellé et se tronque par « … »
-- plutôt que de passer dessous : la colonne est étroite, et sa largeur change d'un mode à l'autre.
-- État de SESSION, pas de préférence enregistrée : la liste s'ouvre sur ce qu'on sait fabriquer
-- (arbitrage 9) et la spec ne touche à aucun schéma persisté (décision 4).
local function buildAllToggle(pp)
    local chk = Skin.MakeCheckButton(pp, L["Tout le métier"], 16)
    chk.text:ClearAllPoints(); chk.text:SetPoint("RIGHT", chk, "LEFT", -2, 0)
    chk:SetHitRectInsets(-(chk.text:GetStringWidth() + 4), 0, 0, 0)   -- le libellé est cliquable aussi
    chk:SetPoint("RIGHT", pp, "TOPRIGHT", -6, -14)
    chk:SetScript("OnClick", function(cb)
        -- Spec, cas « En combat » : la colonne ne se rafraîchit pas. La case revient à l'état affiché.
        if InCombatLockdown and InCombatLockdown() and pp:IsProtected() then
            cb:SetChecked(PW._profitAll and true or false); return
        end
        PW._profitAll = cb:GetChecked() and true or false
        PW:_FillDockProfit()
    end)
    chk:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Ajoute, en gris, les recettes que tu n'as pas encore apprises."], 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    chk:SetScript("OnLeave", GameTooltip_Hide)
    pp.allChk = chk
end

-- Même corps que la vue « Manquantes », au pixel près : liste simple, tout le détail en infobulle.
-- La colonne est étroite — la largeur se rattrape au survol, pas en serrant les colonnes.
function PW:_BuildDockProfit(host, anchor)
    if self.profitPanel or not host then return end
    local pp = CreateFrame("Frame", nil, host)
    if anchor then
        pp:SetAllPoints(anchor)
    else
        pp:SetPoint("TOPLEFT", host, "TOPLEFT", 0, -PW.TUNE.viewTop)
        pp:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, 0)
    end
    pp:Hide()
    buildAllToggle(pp)
    -- Deux points sur la MÊME ligne (y = -14, celle de la case) : le titre a une gauche et une
    -- droite, sans qu'aucun de ses points ne sur-détermine sa hauteur.
    local hdr = pp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr:SetPoint("LEFT", pp, "TOPLEFT", 8, -14)
    hdr:SetPoint("RIGHT", pp.allChk.text, "LEFT", -6, 0)
    hdr:SetJustifyH("LEFT"); hdr:SetWordWrap(false); pp.hdr = hdr
    local scroll = Skin.MakeScrollFrameIn(pp)   -- barre fine, se cache seule (palier 7c)
    scroll:SetPoint("TOPLEFT", 6, -24); scroll:SetPoint("BOTTOMRIGHT", -26, 6)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(10, 1); scroll:SetScrollChild(content)
    pp.scroll, pp.content, pp.rows = scroll, content, {}
    local msg = pp:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    msg:SetPoint("CENTER", 0, 10); msg:SetWidth(180); msg:Hide(); pp.msg = msg
    self.profitPanel = pp
end

-- ------------------------------------------------------------------
-- Une ligne
-- ------------------------------------------------------------------

local LBL_R, LBL_G, LBL_B = 0.6, 0.75, 0.91

-- Le calcul DÉTAILLÉ, pas seulement son résultat : un montant qu'on ne peut pas recouper est un
-- chiffre à croire sur parole. En PROFIT, le détail se recompte (vente − coupe − réactifs = net) et
-- nomme d'où vient le prix de vente. En COÛT, il dit que c'est un coût : un montant dont on ignore le
-- signe est pire que pas de montant.
local function addDetail(p, costMode)
    if costMode then
        GameTooltip:AddDoubleLine(L["Réactifs"], COC.Api.Coin(math.floor(p.cost + 0.5)), LBL_R, LBL_G, LBL_B, 1, 1, 1)
        GameTooltip:AddLine(L["Ce que coûte un lancer, pas un gain : ta commission vient en plus."], LBL_R, LBL_G, LBL_B, true)
        return
    end
    for _, ln in ipairs(COC.Profit:ProfitLines(p)) do
        GameTooltip:AddDoubleLine(ln.label, ln.value, LBL_R, LBL_G, LBL_B, 1, 1, 1)
    end
    -- Arbitrage 10 : le prix marchand est un PLAFOND, et l'HV peut afficher moins — ou plus, chez qui
    -- ne sait pas qu'un PNJ le vend. Sans cette ligne, le chiffre passe pour faux.
    if p.sellSrc == "vendor" then
        GameTooltip:AddLine(L["Un marchand vend cet objet : l'HV ne le paiera pas plus cher."], 0.7, 0.7, 0.7, true)
    end
end

local function profitTooltip(row)
    local p = row.p
    if not (p and COC.Profit) then return end
    GameTooltip:SetOwner(row, "ANCHOR_LEFT")
    -- ⚠️ `SetHyperlink` SOUS pcall, comme les autres appels du dépôt : un lien que le client refuse
    -- lève, et ici l'erreur emporterait tout ce qui suit — jusqu'au `Show()` final. Le joueur
    -- verrait une infobulle vide sans savoir pourquoi.
    if row.rlink and pcall(GameTooltip.SetHyperlink, GameTooltip, row.rlink) then
        GameTooltip:AddLine(" ")
    else
        GameTooltip:SetText(row.rname or "?", 1, 1, 1, 1, true)
    end
    addDetail(p, row.costMode)
    -- Un réactif sans prix ne rend pas le calcul faux, il le rend OPTIMISTE — et c'est exactement
    -- le sens qu'il faut donner, sinon on fabrique à perte en croyant gagner.
    if p.missing then
        GameTooltip:AddLine(L["Un réactif sans prix : coût sous-estimé."], 0.91, 0.72, 0.29, true)
    end
    if row.unlearned then
        GameTooltip:AddLine(L["Pas encore apprise : la vue « Manquantes » dit où l'apprendre."], 0.7, 0.7, 0.7, true)
    end
    GameTooltip:AddLine(L["Clic : ouvrir cette recette."], 0.55, 0.75, 0.55)
    GameTooltip:Show()
end

-- LE CLIC. `C_TradeSkillUI.OpenRecipe` est la voie du JEU pour « montre-moi cette recette » — le
-- suivi d'objectifs de Blizzard l'emprunte telle quelle. Elle répond par l'événement
-- OPEN_RECIPE_RESPONSE, que le code de Blizzard traite dans SON contexte : rien n'est écrit chez
-- lui depuis le nôtre, et la chaîne sécurisée ne part pas teintée. Sur la ligne de métier ouverte,
-- son traitement se borne à `CraftingPage:Init` — la fenêtre n'est ni rouverte ni déplacée.
local function openRecipe(spellID)
    local open = C_TradeSkillUI and C_TradeSkillUI.OpenRecipe
    if not (spellID and open) then return end
    pcall(open, spellID)
end

local function profitRow(i)
    local pp = PW.profitPanel
    local row = pp.rows[i]
    if row then return row end
    row = CreateFrame("Button", nil, pp.content)
    row:SetHeight(ROW_H)
    row:SetPoint("LEFT", pp.content, "LEFT", 0, 0)
    row:SetPoint("RIGHT", pp.content, "RIGHT", 0, 0)
    row:SetPoint("TOP", pp.content, "TOP", 0, -(i - 1) * ROW_H)
    local ic = row:CreateTexture(nil, "ARTWORK"); ic:SetSize(12, 12); ic:SetPoint("LEFT", 2, 0); row.ic = ic
    local nm = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nm:SetPoint("LEFT", ic, "RIGHT", 4, 0); nm:SetJustifyH("LEFT"); row.nm = nm
    local val = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    val:SetPoint("RIGHT", -4, 0); val:SetJustifyH("RIGHT"); row.val = val
    nm:SetPoint("RIGHT", val, "LEFT", -4, 0)
    row:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight", "ADD")
    row:SetScript("OnEnter", profitTooltip)
    row:SetScript("OnLeave", GameTooltip_Hide)
    -- Deux gestes, les mêmes que sur toute ligne de recette du jeu : Maj pour lier l'objet en chat,
    -- clic simple pour aller le voir dans la fenêtre native.
    row:RegisterForClicks("LeftButtonUp")
    row:SetScript("OnClick", function(r)
        if IsShiftKeyDown() then
            if r.rlink and ChatEdit_InsertLink then ChatEdit_InsertLink(r.rlink) end
        else
            openRecipe(r.sid)
        end
    end)
    pp.rows[i] = row
    return row
end

-- ------------------------------------------------------------------
-- La liste (pure : aucun cadre, testée par tests/test_profit_view.lua)
-- ------------------------------------------------------------------

-- Les entrées à évaluer : les recettes APPRISES de la session ouverte, puis, case cochée, celles
-- qu'on n'a pas apprises (le même lecteur que la vue « Manquantes », pour qu'elles ne se contredisent
-- pas sur ce qui manque).
function PW:_ProfitEntries(all)
    if self._EnsureRecipesForRoute then self:_EnsureRecipesForRoute() end
    local out = {}
    for _, e in ipairs(self.recipes or {}) do
        if not e.isMissing then out[#out + 1] = e end
    end
    local S = all and COC.Sources
    if S then
        for _, m in ipairs(S:MissingRecipes(self.profKey) or {}) do out[#out + 1] = m end
    end
    return out
end

-- Une ligne par recette, du plus gros MONTANT au plus petit : le profit, ou le coût en mode coût. Le
-- calcul est fait UNE fois ici et emporté par la ligne : le rendu, l'infobulle et le tri lisent le
-- même nombre, et l'oracle n'est interrogé qu'une fois par recette et par remplissage.
function PW:_ProfitList(PR, profKey, entries, costMode)
    local seen, out = {}, {}
    for _, e in ipairs(entries) do
        local sid = e.spellID
        if sid and not e.isHeader and not seen[sid] then
            seen[sid] = true
            local p, amount
            if costMode then p = PR:RecipeCost(profKey, sid) else p = PR:CraftProfit(profKey, sid, e.numMade) end
            if p then amount = costMode and p.cost or p.profit end
            -- Montant nul ou négatif : rien. Le zéro d'une recette sans prix ressemblerait trait pour
            -- trait à celui d'une recette qui ne rapporte rien (choix du user, 2026-09-21).
            if amount and amount > 0 then
                out[#out + 1] = { sid = sid, name = e.name, link = e.link, icon = e.icon, p = p,
                                  amount = amount, unlearned = e.isMissing and true or false }
            end
        end
    end
    table.sort(out, function(a, b)
        if a.amount ~= b.amount then return a.amount > b.amount end
        return (a.name or "") < (b.name or "")
    end)
    return out
end

-- ------------------------------------------------------------------
-- Le remplissage
-- ------------------------------------------------------------------

-- Le message d'absence NOMME l'oracle qui n'a rien trouvé. « Aucune recette rentable » a deux causes
-- indiscernables à l'œil : l'hôtel des ventes ne connaît honnêtement aucun de ces objets (serveur
-- jeune), ou l'oracle ne répond pas du tout. Dire d'où viennent les prix envoie chercher au bon
-- endroit — c'est la leçon de `/co pricedump`, appliquée là où le joueur la lit.
local function emptyText(PR, costMode)
    local src = (PR and PR:PriceSource()) or "?"
    if costMode then return string.format(L["Aucun coût connu (prix : %s)."], src) end
    return string.format(L["Aucune recette rentable (prix : %s)."], src)
end

local function fillRow(row, e, costMode)
    row.sid, row.rname, row.rlink, row.p = e.sid, e.name, e.link, e.p
    row.costMode, row.unlearned = costMode, e.unlearned
    row.ic:SetTexture(e.icon or NO_ICON)
    row.ic:SetDesaturated(e.unlearned)
    row.nm:SetText(e.name or "?")
    -- Une recette NON apprise se voit au premier coup d'œil (arbitrage 9) : nom gris, icône éteinte.
    if e.unlearned then row.nm:SetTextColor(0.6, 0.6, 0.6) else row.nm:SetTextColor(1, 1, 1) end
    -- VALEUR EXACTE, pas le palier compact des pièces/étoiles : dans une liste dont le tri EST le
    -- montant, deux lignes qui affichent la même icône en se suivant font passer le classement pour
    -- arbitraire. ARRONDI À L'ENTIER : la coupe de l'HV (×0,95) rend un cuivre FRACTIONNAIRE, et le
    -- formateur de pièces du jeu attend un entier. Un coût s'écrit en blanc, un gain en or.
    local v = math.floor(e.amount + 0.5)
    row.val:SetText(COC.Api.Coin(v, 10) .. (e.p.missing and " |cFF888888(?)|r" or ""))
    if costMode then row.val:SetTextColor(1, 1, 1) else row.val:SetTextColor(1, 0.82, 0) end
    row:Show()
end

function PW:_FillDockProfit()
    local pp = self.profitPanel; if not pp then return end
    local PR = oracle()
    local costMode = self:_ProfitCostMode(self.profKey)
    local list = PR and self:_ProfitList(PR, self.profKey, self:_ProfitEntries(self._profitAll), costMode) or {}
    pp.allChk:SetChecked(self._profitAll and true or false)
    local title = costMode and L["Coût à lancer (%d)"] or L["Rentables (%d)"]
    pp.hdr:SetText("|cFFE8B84B" .. string.format(title, #list) .. "|r")
    -- Une liste vide SANS un mot est indiscernable d'une vue cassée. Le message part donc même si
    -- l'oracle s'est tu entre-temps : « ? » à la place de son nom est une réponse, le vide n'en est pas.
    pp.msg:SetShown(#list == 0)
    if #list == 0 then pp.msg:SetText(emptyText(PR, costMode)) end
    local w = pp.scroll:GetWidth() or 0
    if w > 0 then pp.content:SetWidth(w) end
    for i, e in ipairs(list) do fillRow(profitRow(i), e, costMode) end
    for i = #list + 1, #pp.rows do
        pp.rows[i]:Hide(); pp.rows[i].sid, pp.rows[i].p = nil, nil
    end
    pp.content:SetHeight(math.max(#list * ROW_H, 1))
end
