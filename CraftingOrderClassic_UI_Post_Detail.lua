-- CraftingOrderClassic_UI_Post_Detail.lua — onglet « Commande », PANNEAU DROIT : en-tête du plan
-- sélectionné (icône + cadre doré + nom + niveau), liste des réactifs « je fournis », et la rangée
-- commission. Sorti de _UI_Post.lua (anti-monolithe : le fichier hôte butait sur les 500 lignes).
-- Chargé APRÈS _UI_Post_Layout.lua (lit UI.POST) ; ses méthodes sont appelées par _BuildPostRight
-- (_UI_Post.lua) et par les refresh de l'onglet — tout est méthode de COC.UI, donc inter-fichiers.
--
-- GÉOMÉTRIE : chaque morceau se parente à SA sous-zone SPEC (cf. _UI_Post_Layout.lua, nœud "detail") :
--   ItemSelected = cols{ craftIcon, craftText, providePill } · reagentsList = rows{ reagHeader, reagBody }.
-- Ajouter du padding à l'un = éditer la SPEC, rien ici. Le CONTENU (textes, widgets) vit ici.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L
local P    = UI.POST

local RRH = 21    -- hauteur d'une ligne de réactif

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end
local function entryName(e)
    local c = CL(); if not c then return "?" end
    return e.itemID and c:ItemName(e.itemID) or c:RecipeName(e.spellID)
end

-- =========================================================================
-- En-tête du plan + liste des réactifs (sous-zones de "detail" dans la SPEC)
-- =========================================================================
-- NOM (1ʳᵉ ligne) + sous-ligne niveau : slot texte flex, ancres LEFT+RIGHT → largeur = celle du slot
-- (paddable dans la SPEC, pas de largeur codée), paire centrée verticalement (y = +8/en-dessous).
function UI:_BuildPostPlanText(tz)
    self.postPlanName = tz:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.postPlanName:SetPoint("LEFT", 2, 8); self.postPlanName:SetPoint("RIGHT", -2, 8)
    self.postPlanName:SetJustifyH("LEFT"); self.postPlanName:SetWordWrap(false); Skin.ApplyShadow(self.postPlanName)
    self.postPlanSub = tz:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.postPlanSub:SetPoint("TOPLEFT", self.postPlanName, "BOTTOMLEFT", 0, -3)
    self.postPlanSub:SetTextColor(Skin.unpack(Skin.color.textMuted)); Skin.ApplyShadow(self.postPlanSub)
    -- Retours du formulaire (« Choisis d'abord un plan. », « Commande postée ! ») : sous le nom, à la
    -- place de la sous-ligne, vide quand un plan est choisi. Ils vivaient en bas de la liste des
    -- artisans et y redisaient l'invite du détail, à l'autre bout de la colonne (maquette du 2026-09-30).
    self.postSelLbl = tz:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.postSelLbl:SetPoint("TOPLEFT", self.postPlanName, "BOTTOMLEFT", 0, -3)
    self.postSelLbl:SetPoint("TOPRIGHT", self.postPlanName, "BOTTOMRIGHT", 0, -3)
    self.postSelLbl:SetJustifyH("LEFT"); self.postSelLbl:SetWordWrap(false)
end

function UI:_BuildPostDetail()
    -- ICÔNE DU CRAFT + CADRE DORÉ natif (slot d'objet, l'eye-candy de la vue métier — demande user).
    -- Le cadre `UI-Quickslot2` est le bord doré des boutons d'action : posé ~1,5× l'icône, centré, il
    -- l'encadre sans la masquer (centre transparent). Tooltip d'objet au survol de l'icône.
    local iz = self:PostSec("craftIcon")
    self.postPlanBadge = Skin.MakeBadge(iz, 34); self.postPlanBadge:SetPoint("CENTER", 0, 0)
    self.postPlanBadge:EnableMouse(true); Skin.WireItemTooltip(self.postPlanBadge); Skin.WireItemLink(self.postPlanBadge)
    local ring = iz:CreateTexture(nil, "OVERLAY")
    ring:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    ring:SetPoint("CENTER", self.postPlanBadge, "CENTER", 0, -0.5); ring:SetSize(52, 52)
    self:_BuildPostPlanText(self:PostSec("craftText"))

    -- « JE FOURNIS » : slot dédié, aligné à droite. Seulement avec un plan (il en qualifie les réactifs).
    local pz = self:PostSec("providePill")
    local jeLabel = pz:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    jeLabel:SetPoint("RIGHT", -2, 0); jeLabel:SetText(L["JE FOURNIS"])
    jeLabel:SetTextColor(Skin.unpack(Skin.color.gold)); Skin.ApplyShadow(jeLabel)
    self.postProvideLbl = jeLabel

    -- EN-TÊTE réactifs (slot dédié) : libellé doré à gauche + compteur « je fournis » à droite.
    local hz = self:PostSec("reagHeader")
    self.postReagHdr = hz:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.postReagHdr:SetPoint("LEFT", P.PAD, 0)
    self.postReagHdr:SetText("|cFFE8B84B" .. L["Réactifs"] .. "|r |cFF888888" .. L["(cocher = je fournis)"] .. "|r")
    Skin.ApplyShadow(self.postReagHdr)
    -- Bouton « Diffuser » (liste de courses) : envoie les réactifs du plan dans un canal, avec leurs liens.
    self.postShareBtn = Skin.MakeGoldButton(hz, 82, 18, L["Diffuser"])
    self.postShareBtn:SetPoint("RIGHT", -P.PAD - 2, 0)
    self.postShareBtn:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_LEFT"); GameTooltip:SetText(L["Diffuser les réactifs dans un canal"], 1, 1, 1); GameTooltip:Show()
    end)
    self.postShareBtn:SetScript("OnLeave", GameTooltip_Hide); self.postShareBtn:Hide()
    self.postBQCount = hz:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.postBQCount:SetPoint("RIGHT", self.postShareBtn, "LEFT", -8, 0)
    self.postBQCount:SetTextColor(Skin.unpack(Skin.color.textMuted)); Skin.ApplyShadow(self.postBQCount)

    -- LISTE des réactifs (slot corps flex) : la liste défilante du kit (palier 2 de la revue d'UI),
    -- ancrée aux quatre coins de la zone (la SPEC pilote le pad), sa barre logée dans son bord droit.
    local body = self:PostSec("reagBody")
    local host = CreateFrame("Frame", nil, body)
    host:SetPoint("TOPLEFT", P.PAD, -P.PAD)
    host:SetPoint("BOTTOMRIGHT", self:PostSec("reagentsGutter"), "BOTTOMRIGHT", -Skin.LIST_EDGE, P.PAD)
    self.postReagList = Skin.MakeScrollList(host, {
        extent = RRH,
        build  = function(row) UI:_BuildPostReagRow(row) end,
        fill   = function(row, rg) UI:_FillPostReagRow(row, rg) end,
    })
end

-- =========================================================================
-- Rangée commission (montant g/s/c + quantité) — zone "price"
-- =========================================================================
function UI:_BuildPostPrice(sec)
    -- Les champs du formulaire des Commandes d'artisanat de Forever (palier 4) : le montant en
    -- LargeMoneyInputFrameTemplate (200 × 33), à 10 px de son libellé comme le pourboire de Blizzard,
    -- et la quantité au compteur de « Créer tout ». La rangée est centrée sur les 44 px du haut de la
    -- zone (66 px, cf. _UI_Post_Layout) ; le repère de prix Auctionator, souvent vide, loge dessous.
    local ROW_CY = -22
    local comLbl = sec:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    comLbl:SetPoint("LEFT", sec, "TOPLEFT", P.PAD, ROW_CY); comLbl:SetText("|cFFE8B84B" .. L["Commission"] .. "|r")
    Skin.ApplyShadow(comLbl)
    self.postMoney = Skin.MakeMoneyInput(sec, 200)
    self.postMoney:SetPoint("LEFT", comLbl, "RIGHT", 10, 0)
    local qLbl = sec:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    qLbl:SetPoint("LEFT", self.postMoney, "RIGHT", 16, 0); qLbl:SetText(L["Qté"]); Skin.ApplyShadow(qLbl)
    self.postQty = Skin.MakeQtySpinner(sec)
    self.postQty:SetPoint("LEFT", qLbl, "RIGHT", 36, 0)   -- 36 = le [-] (29 px) qui déborde à gauche, + 7

    self.postPriceHint = sec:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.postPriceHint:SetPoint("TOPLEFT", comLbl, "LEFT", 0, -22)
    self.postPriceHint:SetJustifyH("LEFT")
    self.postPriceHint:SetTextColor(Skin.unpack(Skin.color.textMuted)); Skin.ApplyShadow(self.postPriceHint)
end

-- =========================================================================
-- Refresh du détail + des réactifs
-- =========================================================================
function UI:RefreshPostPlanDetail()
    local e = self.postEntry
    if self.postProvideLbl then self.postProvideLbl:SetShown(e ~= nil) end
    if not e then
        -- L'invite prend la place du nom (elle disait « aucun plan » ici et « choisis un plan » en bas).
        self.postPlanBadge:Hide(); self.postPlanName:SetText("|cFF888888" .. L["Choisis un métier puis un plan."] .. "|r")
        if self.postPlanSub then self.postPlanSub:SetText("") end
        self.postReagHdr:SetShown(false); self.postBQCount:SetText("")
        if self.postShareBtn then self.postShareBtn:Hide() end
        self.postCurrentReag = {}
        self.postReagList:SetData({})
        if self.postPriceHint then self.postPriceHint:SetText("") end
        if self.postSelLbl then self.postSelLbl:SetText("") end
        return
    end
    local nm = entryName(e); local r, g, b = Skin.RarityColor(e.itemID)
    self.postPlanBadge:Paint(r, g, b, Skin.FirstChar(nm), Skin.Icon(e.itemID, e.spellID)); self.postPlanBadge:Show()
    self.postPlanBadge.tipItemID  = e.itemID       -- tooltip d'objet (WireItemTooltip) : produit, ou
    self.postPlanBadge.tipSpellID = (not e.itemID) and e.spellID or nil   -- le SORT si service sans objet
    self.postPlanName:SetText(nm); self.postPlanName:SetTextColor(r, g, b)
    local c = CL()   -- sous-ligne : niveau d'apprentissage (learnedAt) ; vide si inconnu (matières, désench.)
    local lvl = c and e.spellID and c:RecipeLearnedAt(self.postProf, e.spellID)
    self.postPlanSub:SetText(lvl and (L["niveau"] .. " " .. lvl) or "")
    self:_RefreshPostPriceHint(e)
    self:RefreshPostReagents()
end

function UI:RefreshPostReagents()
    local c = CL()
    local reag = (c and self.postEntry and self.postEntry.spellID)
        and c:RecipeReagents(self.postProf, self.postEntry.spellID) or {}
    self.postCurrentReag = reag
    -- Même plan qu'au dernier rafraîchissement : on garde la position ; nouveau plan : on repart du haut.
    local samePlan = (self._postReagFor == self.postEntry)
    self._postReagFor = self.postEntry
    self.postReagList:SetData(reag, samePlan)
    self.postReagHdr:SetShown(self.postEntry ~= nil)
    if self.postShareBtn then
        self.postShareBtn:SetShown(#reag > 0)
        self.postShareBtn:SetScript("OnClick", function()
            local items = {}
            for _, rg in ipairs(reag) do items[#items + 1] = { id = rg[1], qty = rg[2] } end
            if COC.ShareReagents then COC.ShareReagents:Open(entryName(self.postEntry), items) end
        end)
    end
    self:_UpdateProvidedCount()
end

-- Construit une ligne de réactif, la première fois que la liste défilante crée ce cadre. Le clic
-- coche « je fournis » pour le réactif que la ligne porte À CE MOMENT (`row.iid`, posé au
-- remplissage) : la même ligne sert à d'autres réactifs quand on change de plan.
function UI:_BuildPostReagRow(r)
    -- FOND de « boîte » par réactif (demande user : encadrer les objets comme la vue métier) : bande
    -- discrète derrière la ligne ; le survol est celui des recettes des métiers (Skin.ListRowArt).
    local bg = r:CreateTexture(nil, "BACKGROUND"); bg:SetPoint("TOPLEFT", 0, -1); bg:SetPoint("BOTTOMRIGHT", 0, 1)
    bg:SetColorTexture(1, 1, 1, 0.05)
    Skin.ListRowArt(r); Skin.ListRowKind(r, "item")
    r.badge = Skin.MakeBadge(r, 16); r.badge:SetPoint("LEFT", 2, 0)   -- icône réactif iso vue métier
    r.check = Skin.MakeCheck(r, 18); r.check:SetPoint("RIGHT", -4, 0)
    r.qty   = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); r.qty:SetPoint("RIGHT", -22, 0); Skin.ApplyShadow(r.qty)
    r.name  = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.name:SetPoint("LEFT", 24, 0); r.name:SetPoint("RIGHT", r.qty, "LEFT", -8, 0)
    r.name:SetJustifyH("LEFT"); r.name:SetWordWrap(false); Skin.ApplyShadow(r.name)
    r:SetScript("OnClick", function(self2)
        local iid = self2.iid; if not iid then return end
        UI.postProvide[iid] = not UI.postProvide[iid]
        self2.check:SetChecked(UI.postProvide[iid])
        UI:_UpdateProvidedCount()
    end)
    Skin.WireItemTooltip(r); Skin.WireItemLink(r)
end

-- Remplit une ligne pour le réactif `rg` = { itemID, quantité } (format CraftLink:RecipeReagents).
function UI:_FillPostReagRow(row, rg)
    local c = CL()
    local iid, qty = rg[1], rg[2]
    row.iid, row.tipItemID = iid, iid
    local cr, cg, cb = Skin.RarityColor(iid)
    local nm2 = c and c:ItemName(iid) or ("item:"..iid)
    local disp = nm2:match("^item:") and "|cFF777777" .. L["Chargement…"] .. "|r" or nm2
    row.badge:Paint(cr, cg, cb, Skin.FirstChar(nm2), Skin.Icon(iid))
    row.name:SetText(disp); row.name:SetTextColor(cr, cg, cb)
    row.qty:SetText("|cFFFFCC00×"..qty.."|r")
    row.check:SetChecked(UI.postProvide[iid])
end

function UI:_UpdateProvidedCount()
    local reag = self.postCurrentReag or {}; local n = 0
    for _, rg in ipairs(reag) do if UI.postProvide[rg[1]] then n = n + 1 end end
    if self.postBQCount then self.postBQCount:SetText(n.." / "..#reag.." "..L["fournis"]) end
end
