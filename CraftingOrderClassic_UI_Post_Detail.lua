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

    -- NOM (1ʳᵉ ligne) + sous-ligne niveau : slot texte flex, ancres LEFT+RIGHT → largeur = celle du
    -- slot (paddable dans la SPEC, pas de largeur codée), paire centrée verticalement (y = +8/en-dessous).
    local tz = self:PostSec("craftText")
    self.postPlanName = tz:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.postPlanName:SetPoint("LEFT", 2, 8); self.postPlanName:SetPoint("RIGHT", -2, 8)
    self.postPlanName:SetJustifyH("LEFT"); self.postPlanName:SetWordWrap(false); Skin.ApplyShadow(self.postPlanName)
    self.postPlanSub = tz:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.postPlanSub:SetPoint("TOPLEFT", self.postPlanName, "BOTTOMLEFT", 0, -3)
    self.postPlanSub:SetTextColor(Skin.unpack(Skin.color.textMuted)); Skin.ApplyShadow(self.postPlanSub)

    -- « JE FOURNIS » : slot dédié, aligné à droite.
    local pz = self:PostSec("providePill")
    local jeLabel = pz:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    jeLabel:SetPoint("RIGHT", -2, 0); jeLabel:SetText(L["JE FOURNIS"])
    jeLabel:SetTextColor(Skin.unpack(Skin.color.gold)); Skin.ApplyShadow(jeLabel)

    -- EN-TÊTE réactifs (slot dédié) : libellé doré à gauche + compteur « je fournis » à droite.
    local hz = self:PostSec("reagHeader")
    self.postReagHdr = hz:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.postReagHdr:SetPoint("LEFT", P.PAD, 0)
    self.postReagHdr:SetText("|cFFE8B84B" .. L["Réactifs"] .. "|r |cFF888888" .. L["(cocher = je fournis)"] .. "|r")
    Skin.ApplyShadow(self.postReagHdr)
    self.postBQCount = hz:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.postBQCount:SetPoint("RIGHT", -P.PAD - 2, 0)
    self.postBQCount:SetTextColor(Skin.unpack(Skin.color.textMuted)); Skin.ApplyShadow(self.postBQCount)

    -- LISTE des réactifs (slot corps flex) : largeur LUE sur la zone (tu pilotes pad/gouttière depuis
    -- la SPEC) ; −6 = le scroll s'arrête avant la gouttière, la scrollbar y atterrit (iso liste de plans).
    local body = self:PostSec("reagBody")
    local reagW = body:GetWidth(); if reagW <= 1 then reagW = P.WIDE_W end; self.postReagW = reagW - 6
    local rscroll = CreateFrame("ScrollFrame", "COCPostReagScroll", body, "UIPanelScrollFrameTemplate")
    rscroll:SetPoint("TOPLEFT", P.PAD, -P.PAD); rscroll:SetPoint("BOTTOMLEFT", P.PAD, P.PAD); rscroll:SetWidth(self.postReagW)
    local rc = CreateFrame("Frame", nil, rscroll); rc:SetSize(self.postReagW, 10); rscroll:SetScrollChild(rc)
    self.postReagContent = rc; self.postReagRows = {}
end

-- =========================================================================
-- Rangée commission (montant g/s/c + quantité) — zone "price"
-- =========================================================================
function UI:_BuildPostPrice(sec)
    -- Rangée CENTRÉE VERTICALEMENT : libellés en LEFT (centrés par construction), champs de saisie
    -- (16 px, ancrés TOPLEFT via MakeMoneyRow) au y qui les centre : -(H−16)/2. Le repère de prix
    -- Lazy Gold (2ᵉ ligne, souvent vide) se pose juste sous les champs. (g/s/c : Skin.MakeMoneyRow,
    -- partagé avec l'onglet Récolte.)
    local ROW_Y = -((P.PRICE_H or 54) - 16) / 2
    local comLbl = sec:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    comLbl:SetPoint("LEFT", P.PAD, 0); comLbl:SetText("|cFFE8B84B" .. L["Commission"] .. "|r")
    Skin.ApplyShadow(comLbl)
    self.postGold, self.postSilver, self.postCopper = Skin.MakeMoneyRow(sec, P.PAD + 92, ROW_Y)
    local qLbl = sec:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    qLbl:SetPoint("LEFT", P.PAD + 330, 0); qLbl:SetText(L["Qté"]); Skin.ApplyShadow(qLbl)
    self.postQty = CreateFrame("EditBox", nil, sec, "InputBoxTemplate")
    self.postQty:SetSize(40, 16); self.postQty:SetPoint("TOPLEFT", P.PAD + 366, ROW_Y)
    self.postQty:SetAutoFocus(false); self.postQty:SetNumeric(true); self.postQty:SetText("1")
    self.postQty:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)

    self.postPriceHint = sec:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.postPriceHint:SetPoint("TOPLEFT", self.postGold, "BOTTOMLEFT", -92, -4)
    self.postPriceHint:SetJustifyH("LEFT")
    self.postPriceHint:SetTextColor(Skin.unpack(Skin.color.textMuted)); Skin.ApplyShadow(self.postPriceHint)
end

-- =========================================================================
-- Refresh du détail + des réactifs
-- =========================================================================
function UI:RefreshPostPlanDetail()
    local e = self.postEntry
    if not e then
        self.postPlanBadge:Hide(); self.postPlanName:SetText("|cFF888888" .. L["Aucun plan sélectionné."] .. "|r")
        if self.postPlanSub then self.postPlanSub:SetText("") end
        self.postReagHdr:SetShown(false); self.postBQCount:SetText("")
        for i = 1, #self.postReagRows do self.postReagRows[i]:Hide() end
        self.postReagContent:SetHeight(10)
        Skin.AutoHideScroll("COCPostReagScroll", self.postReagContent)   -- sinon scrollbar fantôme
        if self.postPriceHint then self.postPriceHint:SetText("") end
        if self.postSelLbl then self.postSelLbl:SetText("|cFF888888" .. L["Choisis un métier puis un plan."] .. "|r") end
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
    for i = 1, #self.postReagRows do self.postReagRows[i]:Hide() end
    for i, rg in ipairs(reag) do
        local row = self:_PostReagRow(i); local iid, qty = rg[1], rg[2]; row.tipItemID = iid
        local cr, cg, cb = Skin.RarityColor(iid)
        local nm2 = c and c:ItemName(iid) or ("item:"..iid)
        local disp = nm2:match("^item:") and "|cFF777777" .. L["Chargement…"] .. "|r" or nm2
        row.badge:Paint(cr, cg, cb, Skin.FirstChar(nm2), Skin.Icon(iid))
        row.name:SetText(disp); row.name:SetTextColor(cr, cg, cb)
        row.qty:SetText("|cFFFFCC00×"..qty.."|r")
        row.check:SetChecked(UI.postProvide[iid])
        row:SetScript("OnClick", function()
            UI.postProvide[iid] = not UI.postProvide[iid]
            row.check:SetChecked(UI.postProvide[iid])
            UI:_UpdateProvidedCount()
        end)
        row:Show()
    end
    self.postReagContent:SetHeight(math.max(#reag * RRH, 10))
    Skin.AutoHideScroll("COCPostReagScroll", self.postReagContent)
    self.postReagHdr:SetShown(self.postEntry ~= nil)
    self:_UpdateProvidedCount()
end

function UI:_PostReagRow(i)
    local r = self.postReagRows[i]; if r then return r end
    local w = self.postReagW or P.WIDE_W   -- largeur de la zone reagBody (lue au build, cf. _BuildPostDetail)
    r = CreateFrame("Button", nil, self.postReagContent); r:SetSize(w, RRH); r:SetPoint("TOPLEFT", 0, -(i-1)*RRH)
    -- FOND de « boîte » par réactif (demande user : encadrer les objets comme la vue métier) : bande
    -- discrète derrière la ligne + le survol par-dessus.
    local bg = r:CreateTexture(nil, "BACKGROUND"); bg:SetPoint("TOPLEFT", 0, -1); bg:SetPoint("BOTTOMRIGHT", 0, 1)
    bg:SetColorTexture(1, 1, 1, 0.05)
    local hi = r:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints(); hi:SetColorTexture(Skin.unpack(Skin.color.rowHover))
    r.badge = Skin.MakeBadge(r, 16); r.badge:SetPoint("LEFT", 2, 0)   -- icône réactif iso vue métier
    r.name  = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.name:SetPoint("LEFT", 24, 0); r.name:SetWidth(w - 114); r.name:SetJustifyH("LEFT"); Skin.ApplyShadow(r.name)
    r.qty   = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); r.qty:SetPoint("RIGHT", -22, 0); Skin.ApplyShadow(r.qty)
    r.check = Skin.MakeCheck(r, 18); r.check:SetPoint("RIGHT", -4, 0)
    self.postReagRows[i] = r; Skin.WireItemTooltip(r); Skin.WireItemLink(r); return r
end

function UI:_UpdateProvidedCount()
    local reag = self.postCurrentReag or {}; local n = 0
    for _, rg in ipairs(reag) do if UI.postProvide[rg[1]] then n = n + 1 end end
    if self.postBQCount then self.postBQCount:SetText(n.." / "..#reag.." "..L["fournis"]) end
end
