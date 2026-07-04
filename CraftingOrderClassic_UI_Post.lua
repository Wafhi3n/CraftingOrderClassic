-- CraftingOrderClassic_UI_Post.lua — onglet « Commande » : sélection de plan (gauche) +
-- réactifs « je fournis » / commission g-s-c / ciblage artisan (droite). Chargé après _UI.lua.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L   -- localisation du chrome (clé = FR ; overlay enUS). NB : les VALEURS canoniques
                     -- de destinataire restent en FR (clé) pour rester identiques sur le réseau.

local PLH = 20    -- hauteur ligne plan (en-tête de section INCLUS : pool virtualisé homogène)
local RRH = 21    -- hauteur ligne réactif
-- Liste des plans VIRTUALISÉE : pool FIXE de lignes physiques réutilisées au scroll (ne dépend plus
-- du nb de plans → ~24 frames au lieu de ~300 en Couture). INVARIANT (cf. ProfWindow_Recipes) : VISIBLE
-- doit être ≥ au nb de lignes que le viewport peut afficher, sinon la queue de liste est inatteignable.
-- Viewport ≈ 366 px (frame 600 − en-têtes/pieds) / 20 ≈ 18 lignes → 24 avec marge.
local VISIBLE = 24

-- Filtre qualité MINIMALE (cycle) : false = Toutes, sinon seuil WoW (2=Inhabituel, 3=Rare, 4=Épique).
-- Les NOMS de qualité sont localisés par le client via _G["ITEM_QUALITY<n>_DESC"] (zéro clé à baker).
local QUALITY_STEPS = { false, 2, 3, 4 }

local SEP  = 308   -- x séparateur gauche/droite
local LW   = SEP - 14          -- largeur panneau gauche (zone visible)
local LSW  = LW - 22           -- largeur scroll gauche (laisse la place à la scrollbar avant le séparateur)
local RX   = SEP + 8           -- x départ panneau droit
local REDGE = 846              -- bord droit utile (sous la bordure dorée)
local RW   = 818 - RX          -- largeur scroll droit (scrollbar finit avant REDGE)

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end
local function isSoulbound(id) return id and GetItemInfo and select(14, GetItemInfo(id)) == 1 end

local function entryName(e)
    local c = CL(); if not c then return "?" end
    return e.itemID and c:ItemName(e.itemID) or c:RecipeName(e.spellID)
end

-- P2 : ai-je déjà TOUS les réactifs de cette recette dans mes sacs (GetItemCount, sacs seuls) ?
-- false si la recette n'a pas de données `reagents` (CraftLink v6, cf. tools/gen_metadata.lua) —
-- on ne peut alors ni confirmer ni infirmer, donc on ne la propose pas comme « prête ».
-- `countCache` (optionnel) mémoïse GetItemCount par itemID le temps d'UN refresh : un même réactif
-- (ex. Bolt of Cloth) apparaît dans des dizaines de plans → sans cache on rappelait GetItemCount
-- des centaines de fois par rafraîchissement de la liste.
local function bagCount(id, cache)
    if not cache then return GetItemCount(id, false) or 0 end
    local v = cache[id]
    if v == nil then v = GetItemCount(id, false) or 0; cache[id] = v end
    return v
end
local function hasReagentsInBags(c, prof, spellID, countCache)
    local reag = spellID and c:RecipeReagents(prof, spellID)
    if not reag or #reag == 0 then return false end
    for _, rg in ipairs(reag) do
        if bagCount(rg[1], countCache) < rg[2] then return false end
    end
    return true
end
local function sep1px(parent, x1, x2, y)
    local s = parent:CreateTexture(nil, "ARTWORK"); s:SetHeight(1)
    s:SetColorTexture(Skin.color.separator[1], Skin.color.separator[2], Skin.color.separator[3], 0.5)
    s:SetSize(x2 - x1, 1); s:SetPoint("TOPLEFT", x1, y); return s
end

-- =========================================================================
-- Construction principale
-- =========================================================================
function UI:BuildPostTab(f)
    local panel = CreateFrame("Frame", nil, f); self.insetPanel(panel, f); panel:Hide()
    self.postPanel   = panel
    self.postProvide = {}
    self.postTarget  = "all"
    self.postSource  = "guild"

    sep1px(panel, SEP, SEP + 1, -82):SetSize(1, 494)    -- ligne verticale gauche/droite

    self:_BuildPostLeft(panel)
    self:_BuildPostRight(panel)
    -- (résolution des noms async : handler central dans _UI.lua)
end

-- Professions de récolte pure (aucune recette) → exclues de l'onglet Commande, elles vivent
-- dans l'onglet Récolte. Mining reste ici (fonte = recettes) ET dans Récolte (minerais).
local GATHER_ONLY = { Fishing = true, Herbalism = true, Skinning = true }

-- =========================================================================
-- Panneau gauche : dropdown métier + liste des plans
-- =========================================================================
function UI:_BuildPostLeft(panel)
    local hdrLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hdrLbl:SetPoint("TOPLEFT", 14, -80); hdrLbl:SetText(L["MÉTIER"])
    hdrLbl:SetTextColor(Skin.unpack(Skin.color.textMuted))

    local pBtn = Skin.MakeGoldButton(panel, LW, 22, "—"); pBtn:SetPoint("TOPLEFT", 12, -98)
    -- L'icône du métier est DANS le dropdown, collée au nom du métier sélectionné.
    self.postProfBadge = Skin.MakeBadge(pBtn, 16); self.postProfBadge:SetPoint("LEFT", 5, 0)
    pBtn.text:SetJustifyH("LEFT"); pBtn.text:ClearAllPoints(); pBtn.text:SetPoint("LEFT", 26, 0)
    local arrow = pBtn:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(16, 16); arrow:SetPoint("RIGHT", -3, 0); arrow:SetTexture(Skin.tex.arrowDown)
    self.postProfBtn = pBtn
    pBtn:SetScript("OnClick", function() UI:_ToggleProfFlyout() end)

    -- Flyout (hors hiérarchie du panel pour passer au-dessus)
    local fly = CreateFrame("Frame", "COCProfFlyout", UIParent, "BackdropTemplate")
    fly:SetSize(LW, 10); fly:SetFrameStrata("DIALOG"); fly:Hide(); Skin.SkinWell(fly)
    self.postProfFlyout = fly; self.postProfFlyRows = {}

    -- Fermer flyout sur clic ailleurs
    local closer = CreateFrame("Button", nil, UIParent)
    closer:SetAllPoints(); closer:SetFrameStrata("DIALOG"); closer:Hide()
    fly:SetFrameLevel(closer:GetFrameLevel() + 1)
    closer:SetScript("OnClick", function() fly:Hide(); closer:Hide() end)
    fly:SetScript("OnShow",     function() closer:Show() end)
    fly:SetScript("OnHide",     function() closer:Hide() end)

    self:_BuildPostPlanFilters(panel)

    sep1px(panel, 12, SEP - 2, -172)

    local lhdr = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    lhdr:SetPoint("TOPLEFT", 14, -178); lhdr:SetText(L["LISTE DES PLANS"])
    lhdr:SetTextColor(Skin.unpack(Skin.color.textMuted))
    self.postPlanHdr = lhdr   -- annoté dynamiquement quand un artisan filtre la liste (cf. RefreshPostPlans)

    local pscroll = CreateFrame("ScrollFrame", "COCPostPlanScroll", panel, "UIPanelScrollFrameTemplate")
    pscroll:SetPoint("TOPLEFT", 12, -192); pscroll:SetPoint("BOTTOMLEFT", 12, 22); pscroll:SetWidth(LSW)
    local pc = CreateFrame("Frame", nil, pscroll); pc:SetSize(LW - 22, 10); pscroll:SetScrollChild(pc)
    pscroll:HookScript("OnVerticalScroll", function() UI:_RenderPostPlanWindow() end)
    self.postPlanScroll = pscroll; self.postPlanContent = pc
    -- Pool FIXE de lignes réutilisées au scroll (virtualisation ; cf. VISIBLE + _RenderPostPlanWindow).
    self.postPlanRows = {}
    for i = 1, VISIBLE do self.postPlanRows[i] = self:_PostPlanRow(i) end
end

-- Filtre qualité (pill) + recherche + filtre « réactifs en poche » (P2). Extrait de _BuildPostLeft
-- pour rester sous le seuil anti-monolithe.
function UI:_BuildPostPlanFilters(panel)
    self.postQualityIdx = 1
    local qBtn = Skin.MakeGoldButton(panel, 104, 18, "")
    qBtn:SetPoint("TOPLEFT", 12, -128); self.postQualityBtn = qBtn
    qBtn:SetScript("OnClick", function()
        UI.postQualityIdx = (UI.postQualityIdx % #QUALITY_STEPS) + 1
        UI:_RefreshQualityBtn(); UI:RefreshPostPlans()
    end)
    self:_RefreshQualityBtn()

    local srch = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    srch:SetSize(LW - 110, 16); srch:SetPoint("TOPLEFT", 116, -129); srch:SetAutoFocus(false)
    local hint = Skin.SearchHint(panel, srch, L["Rechercher un plan"])
    srch:SetScript("OnTextChanged", function(b)
        hint:SetShown(b:GetText() == "")
        UI.postSearch = b:GetText():lower(); UI:RefreshPostPlans()
    end)
    srch:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)

    -- Filtre RÉACTIFS EN POCHE (P2) : ne montrer que les plans dont je porte déjà tous les
    -- composants (cf. _HasReagentsInBags). Les plans prêts remontent toujours en tête de liste,
    -- que le filtre soit actif ou non (cf. RefreshPostPlans).
    self.postReagFilter = false
    local rBtn = Skin.MakeGoldButton(panel, LW, 18, "")
    rBtn:SetPoint("TOPLEFT", 12, -150); self.postReagFilterBtn = rBtn
    rBtn:SetScript("OnClick", function()
        UI.postReagFilter = not UI.postReagFilter
        UI:_RefreshReagFilterBtn(); UI:RefreshPostPlans()
    end)
    self:_RefreshReagFilterBtn()
end

function UI:_ToggleProfFlyout()
    local fly = self.postProfFlyout; if not fly then return end
    if fly:IsShown() then fly:Hide(); return end
    fly:ClearAllPoints(); fly:SetPoint("TOPLEFT", self.postProfBtn, "BOTTOMLEFT", 0, -2); fly:Show()
end

function UI:_RefreshQualityBtn()
    if not self.postQualityBtn then return end
    local q = QUALITY_STEPS[self.postQualityIdx or 1]
    local name = q and ((_G["ITEM_QUALITY" .. q .. "_DESC"] or "?") .. "+") or L["Toutes"]
    self.postQualityBtn:SetText(L["Qualité : "] .. name)
end

function UI:_RefreshReagFilterBtn()
    if not self.postReagFilterBtn then return end
    self.postReagFilterBtn:SetText(self.postReagFilter
        and ("|cFF33DD33" .. L["Réactifs : j'ai tout"] .. "|r")
        or  (L["Réactifs : "] .. L["Toutes"]))
end

-- =========================================================================
-- Panneau droit : titre plan + réactifs + commission + ciblage artisan
-- =========================================================================
function UI:_BuildPostRight(panel)
    -- Titre du plan
    self.postPlanBadge = Skin.MakeBadge(panel, 20); self.postPlanBadge:SetPoint("TOPLEFT", RX, -83)
    self.postPlanName  = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.postPlanName:SetPoint("LEFT", self.postPlanBadge, "RIGHT", 6, 0)
    self.postPlanName:SetWidth(RW - 100); self.postPlanName:SetJustifyH("LEFT"); Skin.ApplyShadow(self.postPlanName)
    local jeLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    jeLabel:SetPoint("TOPRIGHT", -22, -85); jeLabel:SetText(L["JE FOURNIS"])
    jeLabel:SetTextColor(Skin.unpack(Skin.color.gold)); Skin.ApplyShadow(jeLabel)

    sep1px(panel, RX, REDGE, -106)

    local rhdr = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rhdr:SetPoint("TOPLEFT", RX, -112)
    rhdr:SetText("|cFFE8B84B" .. L["Réactifs"] .. "|r |cFF888888" .. L["(cocher = je fournis)"] .. "|r"); Skin.ApplyShadow(rhdr)
    self.postReagHdr = rhdr

    -- Compteur « je fournis » à droite de l'en-tête réactifs.
    self.postBQCount = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.postBQCount:SetPoint("TOPRIGHT", -22, -112); self.postBQCount:SetTextColor(Skin.unpack(Skin.color.textMuted))
    Skin.ApplyShadow(self.postBQCount)

    local rscroll = CreateFrame("ScrollFrame", "COCPostReagScroll", panel, "UIPanelScrollFrameTemplate")
    rscroll:SetPoint("TOPLEFT", RX, -127); rscroll:SetSize(RW, 8 * RRH)
    local rc = CreateFrame("Frame", nil, rscroll); rc:SetSize(RW - 22, 10); rscroll:SetScrollChild(rc)
    self.postReagContent = rc; self.postReagRows = {}

    sep1px(panel, RX, REDGE, -300)

    -- Commission g/s/c + Qté
    local comLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    comLbl:SetPoint("TOPLEFT", RX, -308); comLbl:SetText("|cFFE8B84B" .. L["Commission"] .. "|r"); Skin.ApplyShadow(comLbl)
    self.postGold, self.postSilver, self.postCopper = Skin.MakeMoneyRow(panel, RX + 92, -306)
    local qLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    qLbl:SetPoint("TOPLEFT", RX + 330, -308); qLbl:SetText(L["Qté"]); Skin.ApplyShadow(qLbl)
    self.postQty = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    self.postQty:SetSize(40, 16); self.postQty:SetPoint("TOPLEFT", RX + 366, -306)
    self.postQty:SetAutoFocus(false); self.postQty:SetNumeric(true); self.postQty:SetText("1")
    self.postQty:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)

    sep1px(panel, RX, REDGE, -328)

    self:_BuildPostArtisanSection(panel)
end

-- (g/s/c : Skin.MakeMoneyRow, partagé avec l'onglet Récolte.)
-- (Section artisan/destinataire/Poster : voir CraftingOrderClassic_UI_Post_Artisans.lua)

-- =========================================================================
-- Refresh
-- =========================================================================
function UI:RefreshPost()
    self:_RefreshProfDropdown()
    self:RefreshPostPlans()
    self:RefreshPostPlanDetail()
    self:RefreshPostArtisans()
end

function UI:_RefreshProfDropdown()
    local c = CL(); local all = c and c:Professions() or {}
    local profs = {}
    for _, p in ipairs(all) do if not GATHER_ONLY[p] then profs[#profs + 1] = p end end
    if (not self.postProf or GATHER_ONLY[self.postProf]) and profs[1] then self.postProf = profs[1] end
    local p = self.postProf or "—"; local lbl = Skin.ProfLabel(p)
    self.postProfBtn:SetText(lbl)
    self.postProfBadge:Paint(Skin.color.gold[1], Skin.color.gold[2], Skin.color.gold[3], Skin.FirstChar(lbl), Skin.ProfIcon(p))
    -- Peuplement du flyout
    local fly, frows = self.postProfFlyout, self.postProfFlyRows
    local h = 0
    for i, prof in ipairs(profs) do
        local r = frows[i]
        if not r then
            r = Skin.MakeGoldButton(fly, LW - 4, 20, ""); r:SetPoint("TOPLEFT", 2, -2 - (i-1)*20)
            r.text:SetJustifyH("LEFT"); r.text:ClearAllPoints(); r.text:SetPoint("LEFT", 6, 0)
            frows[i] = r
        end
        r:SetText(Skin.ProfLabel(prof)); r:SetSelected(prof == self.postProf)
        r:SetScript("OnClick", function()
            UI.postProf = prof; UI.postEntry = nil; UI:_RefreshProfDropdown()
            UI:RefreshPostPlans(); UI:RefreshPostPlanDetail(); UI:RefreshPostArtisans()
            fly:Hide()
        end)
        r:Show(); h = h + 20
    end
    for i = #profs + 1, #frows do frows[i]:Hide() end
    fly:SetHeight(h + 4)
end

function UI:RefreshPostPlans()
    local c = CL(); if not (c and self.postPlanContent) then return end
    local list = self.postProf and c:ProfessionCatalogue(self.postProf) or {}
    local s = self.postSearch
    local qmin = QUALITY_STEPS[self.postQualityIdx or 1]   -- seuil qualité minimal (ou false = Toutes)
    -- Filtre artisan ciblé (P5) : si postTarget = "@Nom", ne montrer que ce que CET artisan peut
    -- fabriquer (recettes connues via RK, ou à défaut plans à sa portée via son niveau + learnedAt ;
    -- cf. _TargetArtisanFilter). L'inverse du flux plan→artisans. artMode = libellé du mode (en-tête).
    local artFilter, artMode = nil, nil
    if self.postProf then artFilter, artMode = self:_TargetArtisanFilter(self.postProf) end
    local countCache = {}   -- mémo GetItemCount par itemID, valable le temps de CE refresh (cf. hasReagentsInBags)
    local out = {}
    for _, e in ipairs(list) do
        -- Commande = objets CRAFTABLES uniquement (recette/sort) ; les récoltes pures (sans spellID)
        -- vivent dans l'onglet Récolte. On masque les objets liés (non échangeables) et ceux absents
        -- du client (autre extension).
        if e.spellID and Skin.ItemExists(e.itemID) and not (e.itemID and isSoulbound(e.itemID))
            and (not artFilter or artFilter(e.spellID)) then
            local okq = true
            if qmin and e.itemID then local q = select(3, GetItemInfo(e.itemID)); okq = q ~= nil and q >= qmin end
            local nm = entryName(e)
            if okq and (not s or s == "" or nm:lower():find(s, 1, true)) then
                local ready = hasReagentsInBags(c, self.postProf, e.spellID, countCache)
                if not self.postReagFilter or ready then
                    out[#out + 1] = {e = e, name = nm, ready = ready}
                end
            end
        end
    end
    if self.postPlanHdr then
        self.postPlanHdr:SetText(artFilter
            and L["LISTE DES PLANS"] .. " |cFF33DD33(" .. self:_PostTargetLabel() .. " · " .. (artMode or "") .. ")|r"
            or L["LISTE DES PLANS"])
    end
    -- Tri par section (emplacement/type) + rendu en-têtes+lignes : cf. _UI_Post_Categories.lua.
    -- Le « prêt » (P2) remonte en tête de SA section (plus en tête globale) : le regroupement prime.
    self:_RenderPostPlanRows(out)
end

-- Ligne UNIFIÉE du pool virtualisé : rend soit un PLAN (badge + nom, cliquable) soit un EN-TÊTE de
-- section (libellé doré + filet, non interactif). Le remplissage/bascule se fait dans _FillPostPlanRow
-- (_UI_Post_Categories) ; le clic lit self.item (pas de closure recréée au scroll).
function UI:_PostPlanRow(i)
    local r = self.postPlanRows[i]; if r then return r end
    r = CreateFrame("Button", nil, self.postPlanContent); r:SetSize(LW - 22, PLH); r:SetPoint("TOPLEFT", 0, -(i-1)*PLH)
    local hi = r:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints(); hi:SetColorTexture(Skin.unpack(Skin.color.rowHover))
    r.badge = Skin.MakeBadge(r, 14); r.badge:SetPoint("LEFT", 2, 0)
    r.name  = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.name:SetPoint("LEFT", 20, 0); r.name:SetJustifyH("LEFT"); r.name:SetWidth(LW - 46); Skin.ApplyShadow(r.name)
    -- Variante EN-TÊTE (même ligne physique) : libellé + filet, masqués quand la ligne rend un plan.
    r.hdr = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.hdr:SetPoint("BOTTOMLEFT", 4, 5); r.hdr:SetJustifyH("LEFT")
    r.hdr:SetTextColor(Skin.unpack(Skin.color.gold)); Skin.ApplyShadow(r.hdr); r.hdr:Hide()
    r.hdrLine = r:CreateTexture(nil, "ARTWORK"); r.hdrLine:SetHeight(1)
    r.hdrLine:SetColorTexture(Skin.color.gold[1], Skin.color.gold[2], Skin.color.gold[3], 0.25)
    r.hdrLine:SetPoint("BOTTOMLEFT", 2, 3); r.hdrLine:SetPoint("BOTTOMRIGHT", -2, 3); r.hdrLine:Hide()
    r:SetScript("OnClick", function(self2)
        local it = self2.item
        if it and not it.isHeader and it.e then UI:SelectPostPlan(it.e) end
    end)
    self.postPlanRows[i] = r; Skin.WireItemTooltip(r); return r
end

function UI:RefreshPostPlanDetail()
    local e = self.postEntry
    if not e then
        self.postPlanBadge:Hide(); self.postPlanName:SetText("|cFF888888" .. L["Aucun plan sélectionné."] .. "|r")
        self.postReagHdr:SetShown(false); self.postBQCount:SetText("")
        for i = 1, #self.postReagRows do self.postReagRows[i]:Hide() end
        self.postReagContent:SetHeight(10)
        if self.postSelLbl then self.postSelLbl:SetText("|cFF888888" .. L["Choisis un métier puis un plan."] .. "|r") end
        return
    end
    local nm = entryName(e); local r, g, b = Skin.RarityColor(e.itemID)
    self.postPlanBadge:Paint(r, g, b, Skin.FirstChar(nm), Skin.Icon(e.itemID, e.spellID)); self.postPlanBadge:Show()
    self.postPlanName:SetText(nm); self.postPlanName:SetTextColor(r, g, b)
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
    r = CreateFrame("Button", nil, self.postReagContent); r:SetSize(RW - 22, RRH); r:SetPoint("TOPLEFT", 0, -(i-1)*RRH)
    local hi = r:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints(); hi:SetColorTexture(Skin.unpack(Skin.color.rowHover))
    r.badge = Skin.MakeBadge(r, 14); r.badge:SetPoint("LEFT", 2, 0)
    r.name  = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.name:SetPoint("LEFT", 20, 0); r.name:SetWidth(RW - 110); r.name:SetJustifyH("LEFT"); Skin.ApplyShadow(r.name)
    r.qty   = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); r.qty:SetPoint("RIGHT", -22, 0); Skin.ApplyShadow(r.qty)
    r.check = Skin.MakeCheck(r, 18); r.check:SetPoint("RIGHT", -4, 0)
    self.postReagRows[i] = r; Skin.WireItemTooltip(r); return r
end

function UI:_UpdateProvidedCount()
    local reag = self.postCurrentReag or {}; local n = 0
    for _, rg in ipairs(reag) do if UI.postProvide[rg[1]] then n = n + 1 end end
    if self.postBQCount then self.postBQCount:SetText(n.." / "..#reag.." "..L["fournis"]) end
end

function UI:SelectPostPlan(entry)
    self.postEntry = entry; self.postProvide = {}
    self.postSelLbl:SetText(L["Sélection : "].."|cFFFFFFFF"..entryName(entry).."|r")
    self:RefreshPostPlans(); self:RefreshPostPlanDetail(); self:RefreshPostArtisans()
end

-- =========================================================================
-- Poster
-- =========================================================================
function UI:DoPostOrder()
    local e = self.postEntry
    if not e then self.postSelLbl:SetText("|cFFFF4444" .. L["Choisis d'abord un plan."] .. "|r"); return end
    local qty = tonumber(self.postQty:GetText()) or 1
    local g   = tonumber(self.postGold:GetText()) or 0
    local s   = tonumber(self.postSilver:GetText()) or 0
    local cu  = tonumber(self.postCopper:GetText()) or 0
    local price = nil
    if g > 0 or s > 0 or cu > 0 then
        local parts = {}
        if g  > 0 then parts[#parts+1] = g.."po"  end
        if s  > 0 then parts[#parts+1] = s.."pa"  end
        if cu > 0 then parts[#parts+1] = cu.."pc" end
        price = table.concat(parts, " ")
    end
    local provided = {}
    for iid, v in pairs(self.postProvide) do if v then provided[#provided+1] = iid end end
    COC.Orders:PostEntry(e, qty, price, {
        profession = self.postProf, provided = provided,
        recipient  = self:_PostTargetLabel(),
    })
    if COC.Beacon then COC:Beacon() end   -- balise TEXTE de découverte (clic = hardware event)
    self.postGold:SetText("0"); self.postSilver:SetText("0"); self.postCopper:SetText("0")
    self.postQty:SetText("1"); self.postEntry = nil; self.postProvide = {}
    self.postSelLbl:SetText("|cFF33DD33" .. L["Commande postée !"] .. "|r")
    self:ShowTab("orders")
end

-- Réactifs en poche (P2) : les sacs changent (loot, craft, échange...) → la liste de plans « prêts »
-- doit suivre. Rafraîchi UNIQUEMENT si l'onglet Commande est visible (coût nul le reste du temps).
-- BAG_UPDATE_DELAYED regroupe les BAG_UPDATE d'un même lot en un seul événement (pas de spam).
local bagWatcher = CreateFrame("Frame")
bagWatcher:RegisterEvent("BAG_UPDATE_DELAYED")
bagWatcher:SetScript("OnEvent", function()
    if UI.postPanel and UI.postPanel:IsShown() then UI:RefreshPostPlans() end
end)
