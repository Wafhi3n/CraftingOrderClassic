-- CraftingOrderClassic_ProfWindow_DockProfit.lua — la 4ᵉ vue de la colonne : « Profit ».
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
-- Elle ne liste que les recettes APPRISES du métier ouvert, et seulement celles qui RAPPORTENT :
-- « est-ce que ça vaudrait le coup d'aller l'apprendre » est une question voisine mais différente,
-- et elle vit déjà dans la vue « Manquantes ». Une recette à perte n'affiche rien — c'était déjà la
-- règle de l'ancienne liste (PR:ProfitText rend une chaîne vide sous zéro), et une ligne avec un nom
-- et une colonne vide ne dit pas « à perte », elle dit « prix inconnu ».
--
-- ⚠️ Elle n'existe PAS sans oracle de prix : la languette n'est même pas construite (cf. VIEWS dans
-- _DockViews). Un onglet qui ne sait ouvrir qu'un message d'absence est un onglet vide.

local COC  = CraftingOrderClassic
local PW   = COC.ProfWindow
local Skin = COC.UI.Skin
local L    = COC.L

local ROW_H  = 16
local SCROLL = "CraftingOrderDockProfitScroll"
local NO_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

-- L'oracle de prix, ou nil. Rendu plutôt que testé : les appelants s'en servent ensuite, et deux
-- interrogations séparées du même oracle peuvent diverger entre-temps.
local function oracle()
    local PR = COC.Profit
    return (PR and PR:IsAvailable()) and PR or nil
end

-- ------------------------------------------------------------------
-- Construction (paresseuse, appelée par _BuildDockViews)
-- ------------------------------------------------------------------

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
    local hdr = pp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr:SetPoint("TOPLEFT", 8, -8); pp.hdr = hdr
    local scroll = CreateFrame("ScrollFrame", SCROLL, pp, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 6, -24); scroll:SetPoint("BOTTOMRIGHT", -26, 6)
    Skin.ScrollTrack(SCROLL)
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

-- L'infobulle porte le DÉTAIL du calcul, pas seulement son résultat. Un profit qu'on ne peut pas
-- recouper est un chiffre à croire sur parole : en montrant vente, réactifs et net côte à côte, une
-- valeur fausse se repère sans avoir à ouvrir l'hôtel des ventes.
local function profitTooltip(row)
    local p, PR = row.p, COC.Profit
    if not (p and PR) then return end
    GameTooltip:SetOwner(row, "ANCHOR_LEFT")
    -- ⚠️ `SetHyperlink` SOUS pcall, comme les autres appels du dépôt : un lien que le client refuse
    -- lève, et ici l'erreur emporterait tout ce qui suit — jusqu'au `Show()` final. Le joueur
    -- verrait une infobulle vide sans savoir pourquoi.
    if row.rlink and pcall(GameTooltip.SetHyperlink, GameTooltip, row.rlink) then
        GameTooltip:AddLine(" ")
    else
        GameTooltip:SetText(row.rname or "?", 1, 1, 1, 1, true)
    end
    local sellLbl = L["Vente HV"] .. ((p.numMade or 1) > 1 and (" ×" .. p.numMade) or "")
    GameTooltip:AddDoubleLine(sellLbl, COC.Api.Coin(p.sell), 0.6, 0.75, 0.91, 1, 1, 1)
    GameTooltip:AddDoubleLine(L["Réactifs"], PR:Money(-p.cost, true), 0.6, 0.75, 0.91, 1, 1, 1)
    GameTooltip:AddDoubleLine(L["Profit net"], PR:Money(p.profit, true), 0.6, 0.75, 0.91, 1, 1, 1)
    -- Un réactif sans prix ne rend pas le calcul faux, il le rend OPTIMISTE — et c'est exactement
    -- le sens qu'il faut donner, sinon on fabrique à perte en croyant gagner.
    if p.missing then
        GameTooltip:AddLine(L["Un réactif sans prix : coût sous-estimé."], 0.91, 0.72, 0.29, true)
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
-- Le remplissage
-- ------------------------------------------------------------------

-- Les recettes APPRISES du métier ouvert, celles qui rapportent, de la plus lucrative à la moins.
-- Le profit est calculé UNE fois ici et emporté par la ligne : le rendu, les infobulles et le tri
-- lisent tous le même nombre, et l'oracle n'est interrogé qu'une fois par recette et par
-- remplissage (il l'est déjà une fois par réactif — le multiplier par le défilement coûterait cher
-- pour rien).
local function collect(self, PR)
    if self._EnsureRecipesForRoute then self:_EnsureRecipesForRoute() end
    local seen, out = {}, {}
    for _, e in ipairs(self.recipes or {}) do
        local sid = e.spellID
        if sid and not e.isHeader and not e.isMissing and not seen[sid] then
            seen[sid] = true
            local p = PR:CraftProfit(self.profKey, sid, e.numMade)
            -- Profit nul ou négatif : rien. Cette vue sert à repérer ce qui rapporte, et le zéro
            -- d'une recette sans prix de vente ressemblerait trait pour trait à celui d'une recette
            -- qui ne rapporte rien (choix du user, 2026-09-21).
            if p and p.profit > 0 then
                out[#out + 1] = { sid = sid, name = e.name, link = e.link, icon = e.icon, p = p }
            end
        end
    end
    table.sort(out, function(a, b)
        if a.p.profit ~= b.p.profit then return a.p.profit > b.p.profit end
        return (a.name or "") < (b.name or "")
    end)
    return out
end

-- Le message d'absence NOMME l'oracle qui n'a rien trouvé. « Aucune recette rentable » a deux causes
-- indiscernables à l'œil : l'hôtel des ventes ne connaît honnêtement aucun de ces objets (serveur
-- jeune), ou l'oracle ne répond pas du tout. Dire d'où viennent les prix envoie chercher au bon
-- endroit — c'est la leçon de `/co pricedump`, appliquée là où le joueur la lit.
local function emptyText(PR)
    return string.format(L["Aucune recette rentable (prix : %s)."], (PR and PR:PriceSource()) or "?")
end

function PW:_FillDockProfit()
    local pp = self.profitPanel; if not pp then return end
    local PR = oracle()
    local list = PR and collect(self, PR) or {}
    pp.hdr:SetText("|cFFE8B84B" .. string.format(L["Rentables (%d)"], #list) .. "|r")
    -- Une liste vide SANS un mot est indiscernable d'une vue cassée. Le message part donc même si
    -- l'oracle s'est tu entre-temps : « ? » à la place de son nom est une réponse, le vide n'en est pas.
    pp.msg:SetShown(#list == 0)
    if #list == 0 then pp.msg:SetText(emptyText(PR)) end
    local w = pp.scroll:GetWidth() or 0
    if w > 0 then pp.content:SetWidth(w) end
    for i, e in ipairs(list) do
        local row = profitRow(i)
        row.sid, row.rname, row.rlink, row.p = e.sid, e.name, e.link, e.p
        row.ic:SetTexture(e.icon or NO_ICON)
        row.nm:SetText(e.name or "?")
        -- VALEUR EXACTE, pas le palier compact des pièces/étoiles : dans une liste dont le tri EST
        -- le montant, deux lignes qui affichent la même icône en se suivant font passer le classement
        -- pour arbitraire. Le « (?) » gris reprend la marque du coût partiel employée ailleurs.
        -- ARRONDI À L'ENTIER : la coupe de l'HV (×0,95) rend un cuivre FRACTIONNAIRE, et le
        -- formateur de pièces du jeu attend un entier. PR:Money arrondit déjà pour cette raison.
        local net = math.floor(e.p.profit + 0.5)
        row.val:SetText(COC.Api.Coin(net, 10) .. (e.p.missing and " |cFF888888(?)|r" or ""))
        row:Show()
    end
    for i = #list + 1, #pp.rows do
        pp.rows[i]:Hide(); pp.rows[i].sid, pp.rows[i].p = nil, nil
    end
    pp.content:SetHeight(math.max(#list * ROW_H, 1))
    Skin.AutoHideScroll(SCROLL, pp.content)
end
