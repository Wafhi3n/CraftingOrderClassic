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
-- Elle liste les recettes du métier ouvert qui RAPPORTENT : celles qu'on a apprises, et, EN GRIS,
-- celles qu'on n'a pas mais que son rang permet déjà d'apprendre (décision 19 du user, 2026-11-16,
-- qui amende l'arbitrage 9). La case « Tout le métier » y ajoute les autres, hors de portée ou de
-- niveau inconnu, plus sombres. Une ligne grise dit OÙ aller chercher la recette, au survol, et le
-- clic pose le repère sur le PNJ (ou l'écrit dans le chat quand on n'a pas sa position). Une recette
-- à perte n'affiche rien — une ligne avec un nom et une colonne vide ne dit pas « à perte », elle dit
-- « prix inconnu ».
--
-- L'ENCHANTEMENT se lit comme les autres métiers, par le PROFIT (décision 18 du user, 2026-11-10,
-- qui renverse les arbitrages 12 et 13) : un enchantement n'est pas un objet, il ne se vend pas à
-- l'HV, il n'a donc pas de ligne ; les baguettes, huiles et bâtonnets en ont une s'ils rapportent.
--
-- LES WRITS (D7 de docs/specs/writs-aca.md, 2026-11-09) : une recette dont l'objet est demandé par un
-- Craftsman's Writ porte une petite icône de writ, pleine si JE porte ce writ, éteinte sinon (ce sont
-- les autres porteurs qui cherchent l'objet). La marque n'ajoute ni ne retire de ligne : la vue reste
-- triée par l'or. Le détail (réputation, prix du writ, ce que COC en a vu en jeu) est dans l'infobulle.
--
-- ⚠️ Elle n'existe PAS sans oracle de prix : la languette n'est même pas construite (cf. VIEWS dans
-- _DockViews). Un onglet qui ne sait ouvrir qu'un message d'absence est un onglet vide.

local COC  = CraftingOrderClassic
local PW   = COC.ProfWindow
local Skin = COC.UI.Skin
local L    = COC.L

local ROW_H  = 16
local NO_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
-- Repli si le client ne rend pas l'icône du writ lui-même (lue par son identifiant d'abord).
local WRIT_ICON = "Interface\\Icons\\INV_Scroll_03"

-- Métiers lus par le COÛT de chaque recette plutôt que par son profit (arbitrage 12). VIDE depuis la
-- décision 18 (2026-11-10) : l'Enchantement en est sorti, ses enchantements n'ont plus de ligne.
-- ⚠️ Le mode coût dort ici, il n'est PAS retiré : feat/writs-aca le traverse (fillRow, markWrit), et
-- l'arracher avant qu'elle soit fusionnée garantissait des conflits au banc. Son retrait est noté
-- dans la spec, sous la décision 18.
local COST_ONLY = {}

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
-- État de SESSION, pas de préférence enregistrée : la liste s'ouvre sur ce qu'on peut fabriquer ou
-- apprendre à son rang (décision 19) et la spec ne touche à aucun schéma persisté (décision 4).
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
        GameTooltip:SetText(L["Ajoute aussi, en gris, les recettes que ton rang ne permet pas encore d'apprendre."],
            1, 1, 1, 1, true)
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

-- Ce que la marque d'un writ veut dire, à la suite du calcul. Les quantités et l'or sont des RELEVÉS
-- (ce que COC a vu en jeu), et le disent : rien ne prouve qu'une quête demande toujours autant.
local function addWritLines(m)
    local e, PR, A = m.entry, COC.Profit, COC.Api
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(string.format(L["Demandé par un writ d'artisan (+%d de réputation)."], e.rep or 0),
        1, 0.82, 0, true)
    if m.held then
        GameTooltip:AddLine(m.need and string.format(L["Tu portes ce writ : il t'en manque %d."], m.need)
            or L["Tu portes ce writ : ouvre-le pour savoir combien il en faut."], 1, 1, 1, true)
    else
        GameTooltip:AddLine(L["Les porteurs de ce writ cherchent cet objet."], 0.7, 0.7, 0.7, true)
    end
    local price = PR and PR:ItemValue(e.writ)
    if price then
        GameTooltip:AddDoubleLine(L["Le writ à l'HdV"], A.Coin(math.floor(price + 0.5)), LBL_R, LBL_G, LBL_B, 1, 1, 1)
    end
    local s = m.seen
    if s and s.n then
        local q = (s.nMin and s.nMax and s.nMin ~= s.nMax) and string.format(L["%d à %d"], s.nMin, s.nMax)
            or tostring(s.n)
        GameTooltip:AddDoubleLine(L["Demandés (vu en jeu)"], q, LBL_R, LBL_G, LBL_B, 1, 1, 1)
    end
    -- L'or VERSÉ au rendu fait foi ; à défaut, celui que le journal annonce. Un ZÉRO ne s'affiche pas :
    -- un writ paie en Coin Pouch, pas en or (relevé du 2026-11-11, quête 94222 : 0 annoncé), et
    -- « 0c » se lirait « ce writ ne rapporte rien ». C'est l'objet qui le dit, ligne suivante.
    if s and (s.paid or 0) > 0 then
        GameTooltip:AddDoubleLine(string.format(L["Or reçu au rendu (niveau %s)"], tostring(s.paidLevel or "?")),
            A.Coin(s.paid), LBL_R, LBL_G, LBL_B, 1, 1, 1)
    elseif s and (s.money or 0) > 0 then
        GameTooltip:AddDoubleLine(string.format(L["Or annoncé (vu au niveau %s)"], tostring(s.level or "?")),
            A.Coin(s.money), LBL_R, LBL_G, LBL_B, 1, 1, 1)
    end
    if s and s.rewardItem then
        local nm = (A.GetItemInfo and A.GetItemInfo(s.rewardItem)) or ("item:" .. s.rewardItem)
        if (s.rewardCount or 1) > 1 then nm = nm .. " ×" .. s.rewardCount end
        GameTooltip:AddDoubleLine(L["Récompense :"], nm, LBL_R, LBL_G, LBL_B, 1, 1, 1)
    end
end
PW._AddWritLines = addWritLines   -- la même rédaction dans l'infobulle d'une étape de route (_Route_Writs)

-- Une recette PAS ENCORE APPRISE : le rang qu'elle demande, et où aller la chercher (décision 19).
-- Le « où » est celui de la vue « Manquantes », mot pour mot (PW._MissWhere) : deux vues qui disent
-- deux choses sur la même recette en disent une de trop. Le repère éventuel est retenu pour le clic.
local function addWhere(row)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["Pas encore apprise."], 0.7, 0.7, 0.7)
    local lvl = row.rlevel
    local rank = (COC.Craft and COC.Craft.OpenRank) and COC.Craft:OpenRank() or nil
    if lvl then
        local miss = (rank and lvl > rank) and (lvl - rank) or nil
        GameTooltip:AddLine(string.format(L["Niveau requis : %d"], lvl)
            .. (miss and (" |cFFFF6666" .. string.format(L["il t'en manque %d"], miss) .. "|r") or ""),
            LBL_R, LBL_G, LBL_B)
    end
    local S = COC.Sources
    if not (S and PW._MissWhere) then return end
    row.pin = PW._MissWhere(row.prof, row.sid)
    local price = S.SourcePrice and S:SourcePrice(row.prof, row.sid)
    if price then GameTooltip:AddLine(string.format(L["Prix : %s"], COC.Api.Coin(price)), 1, 1, 1) end
end

-- Ce que fait le clic, dit seulement s'il fait quelque chose (même règle que « Manquantes »).
local function clickHint(row)
    if not row.unlearned then return L["Clic : ouvrir cette recette."] end
    if row.pin then return L["Clic : poser un repère sur ce PNJ."] end
    if COC.Sources and PW._MissWhereText then return L["Clic : dire dans le chat où trouver cette recette."] end
    return nil
end

local function profitTooltip(row)
    local p = row.p
    if not (p and COC.Profit) then return end
    -- Une recette pas apprise arrive sans lien (le lecteur des manquantes n'en a pas) : on le
    -- demande au client au survol, comme la vue « Manquantes » (il le rend même non apprise). Il
    -- sert aussi au Maj-clic.
    local C = COC.Craft
    if row.unlearned and not row.rlink and C and C.RecipeFacts then
        local f = C:RecipeFacts(row.sid)
        row.rlink = f and f.link or nil
    end
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
    if row.writ then addWritLines(row.writ) end
    if row.unlearned then addWhere(row) end
    local hint = clickHint(row)
    if hint then GameTooltip:AddLine(hint, 0.55, 0.75, 0.55) end
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

-- Le clic sur une recette PAS ENCORE APPRISE (décision 19) : l'ouvrir dans la fenêtre native ne dit
-- pas où l'apprendre. On pose le repère sur le PNJ quand on a sa position (le poseur écrit lui-même
-- « repère posé : … »), sinon UNE ligne de chat dit où la chercher — une réponse au clic du joueur,
-- jamais un message spontané. Le repère est celui que le SURVOL a résolu (cf. addWhere).
local function tellWhere(row)
    if row.pin and PW._SetNpcPin then PW:_SetNpcPin(row.pin); return end
    local txt = COC.Sources and PW._MissWhereText and PW._MissWhereText(row.prof, row.sid)
    if not txt then return end
    print("|cFF33DD88Crafting Order|r " .. string.format(L["%s : %s"], row.rname or "?", txt))
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
    -- UNE ligne, tronquée par « … » : sans `SetWordWrap(false)`, un nom long passe à la ligne et
    -- mord sur la ligne suivante (vu le 2026-09-29 sur les enchantements, « Enchant Necklace -
    -- Deflection » ; skill coc-native-ui, piège 28). Le nom entier reste dans l'infobulle.
    local nm = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nm:SetPoint("LEFT", ic, "RIGHT", 4, 0); nm:SetJustifyH("LEFT"); nm:SetWordWrap(false); row.nm = nm
    local val = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    val:SetPoint("RIGHT", -4, 0); val:SetJustifyH("RIGHT"); row.val = val
    -- La marque d'un writ, entre le nom et le montant ; cachée tant qu'aucun writ ne demande l'objet.
    local wr = row:CreateTexture(nil, "ARTWORK"); wr:SetSize(12, 12)
    wr:SetPoint("RIGHT", val, "LEFT", -3, 0); wr:Hide(); row.wr = wr
    nm:SetPoint("RIGHT", val, "LEFT", -4, 0)
    row:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight", "ADD")
    row:SetScript("OnEnter", profitTooltip)
    row:SetScript("OnLeave", GameTooltip_Hide)
    -- Cette ligne écrit ses propres lignes de writ : l'accroche d'infobulle d'objet (_Writs_Tooltip)
    -- se tait sur elle, sinon elles sortiraient deux fois.
    row.cocWritTip = true
    -- Deux gestes, les mêmes que sur toute ligne de recette du jeu : Maj pour lier l'objet en chat,
    -- clic simple pour aller le voir dans la fenêtre native — ou, recette pas apprise, savoir où
    -- aller l'apprendre.
    row:RegisterForClicks("LeftButtonUp")
    row:SetScript("OnClick", function(r)
        if IsShiftKeyDown() then
            if r.rlink and ChatEdit_InsertLink then ChatEdit_InsertLink(r.rlink) end
        else
            if r.unlearned then tellWhere(r) else openRecipe(r.sid) end
        end
    end)
    pp.rows[i] = row
    return row
end

-- ------------------------------------------------------------------
-- La liste (pure : aucun cadre, testée par tests/test_profit_view.lua)
-- ------------------------------------------------------------------

-- Les entrées à évaluer : les recettes APPRISES de la session ouverte, puis celles qu'on n'a pas
-- apprises (le même lecteur que la vue « Manquantes », pour qu'elles ne se contredisent pas sur ce
-- qui manque). Décision 19 : par défaut, seulement celles que le rang `rank` permet d'apprendre ; la
-- case (`all`) ajoute les autres. Un niveau INCONNU ne passe qu'avec la case : on ne promet pas
-- qu'une recette est à portée sans le savoir. `rank` est lu sur le métier ouvert s'il n'est pas donné.
function PW:_ProfitEntries(all, rank)
    if self._EnsureRecipesForRoute then self:_EnsureRecipesForRoute() end
    local out = {}
    for _, e in ipairs(self.recipes or {}) do
        if not e.isMissing then out[#out + 1] = e end
    end
    local S = COC.Sources
    if not S then return out end
    if rank == nil and COC.Craft and COC.Craft.OpenRank then rank = COC.Craft:OpenRank() end
    for _, m in ipairs(S:MissingRecipes(self.profKey) or {}) do
        if all or (rank and m.level and m.level <= rank) then out[#out + 1] = m end
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
                                  amount = amount, unlearned = e.isMissing and true or false,
                                  level = e.isMissing and e.level or nil }
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

-- La marque d'un writ (D7) sur une ligne. L'objet est celui que le calcul a lu (`p.productID`) : la
-- marque et le prix parlent du même. Une ligne est RECYCLÉE : sans writ, tout est remis à zéro, sinon
-- elle garderait l'icône et l'infobulle de la recette d'avant.
local function markWrit(row, e, costMode, wanted)
    local W, pid = COC.Writs, e.p and e.p.productID
    local m = (W and pid and not costMode) and W:ProfitMark(pid, wanted) or nil
    row.writ = m
    if m then
        local gi = COC.Api.GetItemIcon
        row.wr:SetTexture((gi and gi(m.entry.writ)) or WRIT_ICON)
        row.wr:SetDesaturated(not m.held)
        row.wr:Show()
    else
        row.wr:Hide()
    end
    row.nm:SetPoint("RIGHT", m and row.wr or row.val, "LEFT", -4, 0)
end

-- `ctx` = ce qui vaut pour toute la liste : { costMode, wanted, rank, prof }.
local function fillRow(row, e, ctx)
    row.sid, row.rname, row.rlink, row.p = e.sid, e.name, e.link, e.p
    markWrit(row, e, ctx.costMode, ctx.wanted)
    row.costMode, row.unlearned, row.rlevel = ctx.costMode, e.unlearned, e.level
    row.prof, row.pin = ctx.prof, nil   -- le métier part avec la ligne ; le repère se résout au survol
    row.ic:SetTexture(e.icon or NO_ICON)
    row.ic:SetDesaturated(e.unlearned)
    row.nm:SetText(e.name or "?")
    -- Une recette NON apprise se voit au premier coup d'œil (arbitrage 9) : nom gris, icône éteinte.
    -- Plus sombre encore hors de portée de son rang (elle n'est là que par la case, décision 19).
    local far = e.unlearned and not (e.level and ctx.rank and e.level <= ctx.rank)
    if far then row.nm:SetTextColor(0.45, 0.45, 0.45)
    elseif e.unlearned then row.nm:SetTextColor(0.6, 0.6, 0.6)
    else row.nm:SetTextColor(1, 1, 1) end
    -- VALEUR EXACTE, pas le palier compact des pièces/étoiles : dans une liste dont le tri EST le
    -- montant, deux lignes qui affichent la même icône en se suivant font passer le classement pour
    -- arbitraire. ARRONDI À L'ENTIER : la coupe de l'HV (×0,95) rend un cuivre FRACTIONNAIRE, et le
    -- formateur de pièces du jeu attend un entier. Pas de couleur par mode : le formateur de pièces
    -- de Forever écrit ses chiffres en blanc et `SetTextColor` n'y change rien (vu le 2026-09-29,
    -- profit et coût identiques). Le TITRE dit que c'est un coût, et l'infobulle le répète.
    local v = math.floor(e.amount + 0.5)
    row.val:SetText(COC.Api.Coin(v, 10) .. (e.p.missing and " |cFF888888(?)|r" or ""))
    row:Show()
end

function PW:_FillDockProfit()
    local pp = self.profitPanel; if not pp then return end
    local PR = oracle()
    local costMode = self:_ProfitCostMode(self.profKey)
    local rank = (COC.Craft and COC.Craft.OpenRank) and COC.Craft:OpenRank() or nil
    local list = PR and self:_ProfitList(PR, self.profKey, self:_ProfitEntries(self._profitAll, rank), costMode) or {}
    pp.allChk:SetChecked(self._profitAll and true or false)
    local title = costMode and L["Coût à lancer (%d)"] or L["Rentables (%d)"]
    pp.hdr:SetText("|cFFE8B84B" .. string.format(title, #list) .. "|r")
    -- Une liste vide SANS un mot est indiscernable d'une vue cassée. Le message part donc même si
    -- l'oracle s'est tu entre-temps : « ? » à la place de son nom est une réponse, le vide n'en est pas.
    pp.msg:SetShown(#list == 0)
    if #list == 0 then pp.msg:SetText(emptyText(PR, costMode)) end
    local w = pp.scroll:GetWidth() or 0
    if w > 0 then pp.content:SetWidth(w) end
    -- Les writs que je porte, lus UNE fois pour toute la liste (D7) : chaque ligne y cherche son objet.
    local W = COC.Writs
    local wanted = (W and not costMode and #list > 0) and W:WantedItems() or nil
    local ctx = { costMode = costMode, wanted = wanted, rank = rank, prof = self.profKey }
    for i, e in ipairs(list) do fillRow(profitRow(i), e, ctx) end
    for i = #list + 1, #pp.rows do
        pp.rows[i]:Hide(); pp.rows[i].sid, pp.rows[i].p, pp.rows[i].writ = nil, nil, nil
    end
    pp.content:SetHeight(math.max(#list * ROW_H, 1))
end
