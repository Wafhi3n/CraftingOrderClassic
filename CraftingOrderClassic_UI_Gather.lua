-- CraftingOrderClassic_UI_Gather.lua — onglet « Récolte » : ressources de récolte (minéraux,
-- herbes, cuirs, poissons) + demande de quantité + prix par pile + ciblage récolteur.
-- GÉOMÉTRIE : SPEC déclarative dans _UI_Gather_Layout.lua (chargé avant) — zones via UI:GatherSec(id),
-- contenu en offsets RELATIFS à sa zone, largeurs LUES sur les zones. Même modèle que l'onglet
-- Commande (validé 2026-07-12) : éditer la SPEC suffit pour bouger/padder les blocs.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L   -- localisation du chrome (valeurs recipient canoniques en FR — cf. _GatherTargetLabel)

local GLH = 20    -- hauteur ligne ressource
local ARH = 26    -- hauteur ligne artisan

local G = UI.GATHER   -- métriques dérivées de la SPEC (PAD, replis de largeur) — cf. _UI_Gather_Layout.lua

-- Professions de récolte reconnues (clés internes CraftLink). On affiche UNIQUEMENT celles
-- qui existent dans le catalogue CraftLink côté client.
local GATHER_PROFS = { "Mining", "Herbalism", "Skinning", "Fishing" }

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end
-- Helpers d'annuaire PARTAGÉS (cf. Skin). knowsProf = niveau SK OU recette RK (crucial en récolte :
-- Skinning/Herbalism/Fishing n'émettent AUCUN RK → seul r.skill les porte) ; SANS craftSeen (on ne
-- cible que des porteurs). inSource = source Guilde/Amis (drapeaux) ou catégorie d'affichage.
local knowsProf, inSource = Skin.KnowsProf, Skin.InSource

-- =========================================================================
-- Construction
-- =========================================================================
function UI:BuildGatherTab(f)
    local panel = CreateFrame("Frame", nil, f); self.insetPanel(panel, f); panel:Hide()
    self.gatherPanel     = panel
    self.gatherTarget    = "all"
    self.gatherSrc       = "guild"

    self:_BuildGatherSections(panel)   -- blocs + filets + frontières : tout vient de la SPEC (Layout)
    self:_BuildGatherLeft()
    self:_BuildGatherRight(panel)
end

-- =========================================================================
-- Panneau gauche : recherche (bande de filtres) + pills d'extension + liste des ressources
-- =========================================================================
-- Même modèle que l'onglet Commande : le CHOIX du métier se fait au clic sur le PORTRAIT (flèche
-- d'affordance, câblé dans UI.lua), le nom vit dans la JAUGE du header. Chaque contrôle se parente à
-- SA zone de la SPEC, ancres LEFT/RIGHT = centrage vertical par construction. Pas de titre de liste.
function UI:_BuildGatherLeft()
    self.gatherProfFlyout = Skin.MakeFlyout("COCGatherFlyout", G.LEFT_W)

    local sSlot = self:GatherSec("srch")
    local srch = CreateFrame("EditBox", nil, sSlot, "InputBoxTemplate")
    srch:SetHeight(16); srch:SetPoint("LEFT", 10, 0); srch:SetPoint("RIGHT", -6, 0)
    srch:SetAutoFocus(false)
    local hint = Skin.SearchHint(sSlot, srch, L["Rechercher une ressource"])
    srch:SetScript("OnTextChanged", function(b)
        hint:SetShown(b:GetText() == "")
        UI.gatherSearch = b:GetText():lower(); UI:RefreshGatherList()
    end)
    srch:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)

    -- Sélecteur d'extension (affiché seulement pour le pseudo-métier « Élémentaire ») : la bande
    -- `verPills` de la SPEC lui est dédiée — vide pour les autres métiers, comme l'ancienne rangée.
    self.gatherExp = 0   -- 0 = Toutes, 1 = Classic, 2 = TBC, 3 = WotLK
    self.gatherVerPills = {}
    local pSlot = self:GatherSec("verPills")
    local verDefs = { {0,L["Toutes"]}, {1,"Classic"}, {2,"TBC"}, {3,"WotLK"} }
    local vx = 2
    for _, d in ipairs(verDefs) do
        local b = Skin.MakeGoldButton(pSlot, 10, 16, d[2])
        b:SetWidth(b.text:GetStringWidth() + 14)
        b:SetPoint("LEFT", vx, 0)
        b:SetScript("OnClick", function() UI.gatherExp = d[1]; UI:_RefreshGatherVerPills(); UI:RefreshGatherList() end)
        self.gatherVerPills[#self.gatherVerPills + 1] = { btn = b, exp = d[1] }
        vx = vx + b:GetWidth() + 4
    end

    -- Liste des ressources : largeur LUE sur la zone (SPEC pilote pad/gouttière ; −6 = la scrollbar
    -- déborde dans la gouttière voisine, iso liste de plans de l'onglet Commande).
    local sec = self:GatherSec("resources")
    local w = sec:GetWidth(); if w <= 1 then w = G.LIST_W + 6 end
    self.gatherListW = w - 6
    local gscroll = CreateFrame("ScrollFrame", "COCGatherListScroll", sec, "UIPanelScrollFrameTemplate")
    gscroll:SetPoint("TOPLEFT", G.PAD, 0); gscroll:SetPoint("BOTTOMLEFT", G.PAD, G.PAD)
    gscroll:SetWidth(self.gatherListW)
    local gc = CreateFrame("Frame", nil, gscroll); gc:SetSize(self.gatherListW, 10); gscroll:SetScrollChild(gc)
    self.gatherListContent = gc; self.gatherListRows = {}
    Skin.ScrollTrack("COCGatherListScroll")   -- rail sombre derrière la scrollbar (iso Commande)
end

function UI:_ToggleGatherFlyout()
    -- Ancré sous le PORTRAIT (déclencheur du choix de métier), comme l'onglet Commande.
    if self.gatherProfFlyout then
        self.gatherProfFlyout:ToggleAt("TOPLEFT", self.frame.portrait, "BOTTOMLEFT", -6, -6)
    end
end

-- =========================================================================
-- Panneau droit : détail ressource + quantité + prix + récolteur
-- =========================================================================
function UI:_BuildGatherRight(panel)
    self:_BuildGatherHeader()
    self:_BuildGatherQtyRow()

    -- Texte d'info (zone flex sous la rangée quantité) : ancré gauche ET droite → suit la SPEC.
    local info = self:GatherSec("info")
    self.gatherInfoTxt = info:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.gatherInfoTxt:SetPoint("TOPLEFT", G.PAD, -4); self.gatherInfoTxt:SetPoint("RIGHT", -G.PAD, 0)
    self.gatherInfoTxt:SetJustifyH("LEFT")
    self.gatherInfoTxt:SetTextColor(Skin.unpack(Skin.color.textMuted)); Skin.ApplyShadow(self.gatherInfoTxt)

    -- Prix proposé : rangée CENTRÉE dans sa zone (même formule que la commission de l'onglet Commande).
    local psec = self:GatherSec("price")
    local ROW_Y = -((G.PRICE_H or 54) - 16) / 2
    local pLbl = psec:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pLbl:SetPoint("LEFT", G.PAD, 0); pLbl:SetText("|cFFE8B84B" .. L["Prix proposé"] .. "|r"); Skin.ApplyShadow(pLbl)
    self.gatherGold, self.gatherSilver, self.gatherCopper = Skin.MakeMoneyRow(psec, G.PAD + 96, ROW_Y)

    self:_BuildGatherArtisanSection(panel)
end

-- En-tête façon PANNEAU DE MÉTIER (iso onglet Commande) : icône 34 + cadre doré natif (UI-Quickslot2)
-- + tooltip d'objet ; nom + sous-ligne métier dans le slot texte flex (ancres LEFT/RIGHT).
function UI:_BuildGatherHeader()
    local iz = self:GatherSec("resIcon")
    self.gatherResBadge = Skin.MakeBadge(iz, 34); self.gatherResBadge:SetPoint("CENTER", 0, 0)
    self.gatherResBadge:EnableMouse(true); Skin.WireItemTooltip(self.gatherResBadge); Skin.WireItemLink(self.gatherResBadge)
    local ring = iz:CreateTexture(nil, "OVERLAY")
    ring:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    ring:SetPoint("CENTER", self.gatherResBadge, "CENTER", 0, -0.5); ring:SetSize(52, 52)
    local tz = self:GatherSec("resText")
    self.gatherResName = tz:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.gatherResName:SetPoint("LEFT", 2, 8); self.gatherResName:SetPoint("RIGHT", -2, 8)
    self.gatherResName:SetJustifyH("LEFT"); self.gatherResName:SetWordWrap(false); Skin.ApplyShadow(self.gatherResName)
    self.gatherResInfo = tz:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.gatherResInfo:SetPoint("TOPLEFT", self.gatherResName, "BOTTOMLEFT", 0, -3); Skin.ApplyShadow(self.gatherResInfo)
end

-- Rangée quantité : libellé dans son slot (LEFT), contrôles dans le leur (RIGHT) — centrés.
function UI:_BuildGatherQtyRow()
    local qh = self:GatherSec("qtyHdr")
    local qhdr = qh:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    qhdr:SetPoint("LEFT", G.PAD, 0); qhdr:SetText("|cFFE8B84B" .. L["Demande de récolte — quantité voulue"] .. "|r"); Skin.ApplyShadow(qhdr); self.gatherQHdr = qhdr

    -- Case « stacks » : si cochée, la quantité est un nombre de PILES, pas d'unités.
    self.gatherByStack = false
    local qc = self:GatherSec("qtyCtl")
    local stLbl = qc:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    stLbl:SetPoint("RIGHT", -4, 0); stLbl:SetText(L["stacks"]); Skin.ApplyShadow(stLbl); self.gatherStLbl = stLbl
    local stChk = Skin.MakeGoldButton(qc, 20, 20, ""); stChk:SetPoint("RIGHT", stLbl, "LEFT", -4, 0)
    -- Icône caisse affichée SUR la case quand « stacks » est coché (sinon □).
    local crateTex = stChk:CreateTexture(nil, "ARTWORK")
    crateTex:SetPoint("CENTER"); crateTex:SetSize(16, 16)
    crateTex:SetTexture(Skin.tex.crate); crateTex:SetTexCoord(0.08, 0.92, 0.08, 0.92); crateTex:Hide()
    stChk.crate = crateTex
    -- Coché = caisse (commande par pile) ; décoché = icône de l'objet voulu (commande à l'unité).
    stChk.Update = function()
        -- Toujours une TEXTURE (le glyphe « □ » s'affichait en tofu) : caisse si « par pile »,
        -- sinon l'icône de l'objet voulu, sinon une case à cocher vide native.
        local tex = (UI.gatherByStack and Skin.tex.crate)
                 or (UI.gatherEntry and Skin.Icon(UI.gatherEntry.itemID))
                 or Skin.tex.checkBox
        crateTex:SetTexture(tex); crateTex:Show(); stChk:SetText("")
    end
    stChk:SetScript("OnClick", function()
        UI.gatherByStack = not UI.gatherByStack
        stChk.Update(); UI:_RefreshGatherDetail()
    end)
    self.gatherStackChk = stChk; stChk.Update()
    self.gatherQty = CreateFrame("EditBox", nil, qc, "InputBoxTemplate")
    self.gatherQty:SetSize(46, 16); self.gatherQty:SetPoint("RIGHT", stChk, "LEFT", -8, 0)
    self.gatherQty:SetAutoFocus(false); self.gatherQty:SetNumeric(true); self.gatherQty:SetText("1")
    self.gatherQty:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)
end

function UI:_BuildGatherArtisanSection(panel)
    -- Portée dans SA zone (« scope », bande grise de la SPEC) : le MÊME dropdown natif que l'onglet
    -- Commande (demande user, capture 2026-07-12 — les 4 boutons rouges dépareillaient) ; bouton-icône
    -- « Diffuser à tous » (bulle sociale + tooltip) à droite. Choisir une portée cible AUSSI toute la liste.
    local scope = self:GatherSec("scope")
    local srcDefs = {
        { value = "guild",  text = L["Guilde"] },
        { value = "friend", text = L["Amis"] },
        { value = "added",  text = L["Ajoutés"] },
        { value = "recent", text = L["Annuaire"] },
    }
    local srcDD = Skin.MakeDropdown("COCGatherSrcDD", scope, 96, srcDefs, {
        onSelect = function(v)
            UI.gatherSrc = v; UI.gatherTarget = v   -- cibler TOUTE cette liste
            UI:_RefreshGatherArtisans()
        end,
    })
    srcDD:SetPointVisual("TOPLEFT", scope, "TOPLEFT", G.PAD, -4)
    self.gatherSrcDD = srcDD
    self.gatherSrc = "guild"; self.gatherTarget = "all"; self:_RefreshGatherSrcTabs()

    local diffBtn = Skin.MakeIconButton(scope, 22, Skin.tex.broadcast)
    diffBtn.icon:SetTexCoord(0, 1, 0, 1)   -- icône sociale sans bordure cuite → pas de rognage 8 %
    diffBtn:SetPoint("RIGHT", -G.PAD - 4, 0)
    self.gatherDiffBtn = diffBtn   -- _RefreshAllRow("gather") synchronise son liseré doré (cible = Tous)
    diffBtn:SetScript("OnClick", function()
        UI.gatherTarget = "all"; UI:_RefreshGatherArtisans()
    end)
    diffBtn:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText(L["Diffuser à tous"], 1, 1, 1)
        GameTooltip:AddLine(L["La commande sera visible par tout le monde (cible « Tous »)."], nil, nil, nil, true)
        GameTooltip:Show()
    end)
    diffBtn:SetScript("OnLeave", GameTooltip_Hide)

    -- Liste des récolteurs (ligne « toute la liste » épinglée + scroll) : largeur LUE sur la zone.
    local az = self:GatherSec("gatherers")
    local aw = az:GetWidth(); if aw <= 1 then aw = G.WIDE_W end
    self.gatherArtW = aw
    self:_BuildAllRowAndScroll(az, "COCGatherArtScroll", "gather", -G.PAD, G.PAD, aw)

    self:_BuildGatherActionBar(panel)
end

-- BARRE D'ACTIONS (iso Commande) : [Récolteur : X] [Poster] sur la bande native du bas (f.ActionBar),
-- conteneur parenté au PANNEAU (il se masque avec l'onglet). Le statut/aide vit en bas de la zone
-- récolteurs — c'est un message de l'onglet, pas une action de la fenêtre.
function UI:_BuildGatherActionBar(panel)
    local bar = CreateFrame("Frame", nil, panel)
    bar:SetAllPoints(self.frame.ActionBar)
    local posterBtn = Skin.MakeGoldButton(bar, 82, 20, L["Poster"]); posterBtn:SetPoint("RIGHT", -8, 0)
    posterBtn:SetScript("OnClick", function() UI:DoGatherOrder() end); self.gatherBtn = posterBtn   -- exposé pour l'aide
    self.gatherArtisanName = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.gatherArtisanName:SetPoint("RIGHT", posterBtn, "LEFT", -14, 0); Skin.ApplyShadow(self.gatherArtisanName)
    local artLbl = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    artLbl:SetPoint("RIGHT", self.gatherArtisanName, "LEFT", -6, 0)
    artLbl:SetText("|cFFE8B84B" .. L["Récolteur :"] .. "|r"); Skin.ApplyShadow(artLbl)
    self:_UpdateGatherArtisanLabel()

    self.gatherSelLbl = self:GatherSec("gatherers"):CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.gatherSelLbl:SetPoint("BOTTOMLEFT", G.PAD, 6); self.gatherSelLbl:SetWidth((self.gatherArtW or G.WIDE_W) - 20)
    self.gatherSelLbl:SetJustifyH("LEFT")
    self.gatherSelLbl:SetText("|cFF888888" .. L["Choisis un métier de récolte puis une ressource."] .. "|r")
end

-- Reflète la portée courante dans le dropdown (libellé + coche). Nom conservé : plusieurs appelants.
function UI:_RefreshGatherSrcTabs()
    if self.gatherSrcDD then self.gatherSrcDD:SetValue(self.gatherSrc or "guild") end
end

-- =========================================================================
-- Refresh
-- =========================================================================
function UI:RefreshGather()
    self:_RefreshGatherDropdown()
    self:RefreshGatherList()
    self:_RefreshGatherDetail()
    self:_RefreshGatherArtisans()
end

function UI:_RefreshGatherVerPills()
    local show = (self.gatherProf == "Elemental")
    -- Quelles extensions ont au moins un objet présent sur CE client ?
    local has = {}
    if show then
        for _, it in ipairs(COC.Elemental or {}) do
            if Skin.ItemExists(it.id) then has[it.exp] = true end
        end
    end
    -- Si l'extension choisie est vide ici, on retombe sur « Toutes ».
    if self.gatherExp ~= 0 and not has[self.gatherExp] then self.gatherExp = 0 end
    for _, p in ipairs(self.gatherVerPills or {}) do
        p.btn:SetShown(show)
        local enabled = (p.exp == 0) or has[p.exp]
        p.btn:SetSelected(p.exp == (self.gatherExp or 0))
        p.btn:SetAlpha(enabled and 1 or 0.35)
        p.btn:EnableMouse(enabled and true or false)
    end
end

function UI:_RefreshGatherDropdown()
    local c = CL()
    -- Métiers de récolte présents dans le catalogue + le pseudo-métier « Élémentaire » (données addon).
    local avail = {}
    for _, prof in ipairs(GATHER_PROFS) do
        if c and c.professions and c.professions[prof] then avail[#avail+1] = prof end
    end
    avail[#avail + 1] = "Elemental"
    if not self.gatherProf and avail[1] then self.gatherProf = avail[1] end
    self:_RefreshGatherVerPills()
    -- Nom + icône du métier : portés par l'en-tête/portrait (UI:_SyncMainPortrait), plus par le panneau.
    self:_SyncMainPortrait()
    local fly = self.gatherProfFlyout
    for i, prof in ipairs(avail) do
        local r = fly:Row(i)
        r:SetText(Skin.ProfLabel(prof)); r:SetSelected(prof == self.gatherProf)
        r:SetScript("OnClick", function()
            UI.gatherProf = prof; UI.gatherEntry = nil
            UI:_RefreshGatherDropdown(); UI:RefreshGatherList()
            UI:_RefreshGatherDetail(); UI:_RefreshGatherArtisans(); fly:Hide()
        end)
    end
    fly:SetCount(#avail)
end

function UI:RefreshGatherList()
    local c = CL(); if not (c and self.gatherListContent) then return end
    local s = self.gatherSearch
    local out = {}
    if self.gatherProf == "Elemental" then
        -- Pseudo-métier élémentaire : données addon, filtrées par extension + existence client.
        for _, it in ipairs(COC.Elemental or {}) do
            if (self.gatherExp == 0 or it.exp == self.gatherExp) and Skin.ItemExists(it.id) then
                local nm = c:ItemName(it.id)
                if not s or s == "" or nm:lower():find(s, 1, true) then
                    out[#out + 1] = { e = { itemID = it.id }, name = nm }
                end
            end
        end
    else
        -- Matières du client courant. Minage fusionné → on garde AUSSI ses lingots de fonte (à spellID).
        local list = self.gatherProf and c:ProfessionCatalogue(self.gatherProf) or {}
        for _, e in ipairs(list) do
            if e.itemID and not e.service and Skin.ItemExists(e.itemID) then
                local nm = c:ItemName(e.itemID)
                if not s or s == "" or nm:lower():find(s, 1, true) then
                    out[#out + 1] = { e = e, name = nm }
                end
            end
        end
    end
    -- Regroupement SECTION > SOUS-CATÉGORIE (cuirs / écailles / minerais…) par le moteur partagé —
    -- même mécanique que la vue métier et l'onglet Commande. Un métier de récolte sans table déclarée
    -- garde la liste plate d'avant. Pendant une recherche, le repliage est ignoré.
    self.gatherOutList = out
    local disp = COC.RecipeCats:BuildDisplay(self.gatherProf, out, {
        itemID    = function(it) return it.e and it.e.itemID end,
        name      = function(it) return it.name or "" end,
        collapsed = ((s or "") ~= "") and nil or self:_GatherCollapseTable(),
    })
    self.gatherDisplay = disp
    for i, item in ipairs(disp) do
        local row = self:_GatherListRow(i)
        if item.isHeader then self:_FillGatherHeader(row, item) else self:_FillGatherRow(row, item) end
        row:Show()
    end
    for i = #disp + 1, #self.gatherListRows do self.gatherListRows[i]:Hide() end
    self.gatherListContent:SetHeight(math.max(#disp * GLH, 10))
    Skin.AutoHideScroll("COCGatherListScroll", self.gatherListContent)
end

-- Repliage + remplissage des lignes (en-tête / ressource) : cf. _UI_Gather_Categories.lua
-- (extrait pour rester sous le plafond anti-monolithe).

function UI:_GatherListRow(i)
    local r = self.gatherListRows[i]; if r then return r end
    local lw = self.gatherListW or G.LIST_W   -- largeur de la zone resources (lue au build)
    r = CreateFrame("Button", nil, self.gatherListContent); r:SetSize(lw, GLH); r:SetPoint("TOPLEFT", 0, -(i-1)*GLH)
    local hi = r:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints(); hi:SetColorTexture(Skin.unpack(Skin.color.rowHover))
    r.badge = Skin.MakeBadge(r, 14); r.badge:SetPoint("LEFT", 2, 0)
    r.name  = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.name:SetPoint("LEFT", 20, 0); r.name:SetJustifyH("LEFT"); r.name:SetWidth(lw - 58); Skin.ApplyShadow(r.name)
    r.stack = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.stack:SetPoint("RIGHT", -4, 0); Skin.ApplyShadow(r.stack)
    -- Chevron des en-têtes de section/sous-catégorie (cf. _UI_Gather_Categories.lua).
    r.expand = r:CreateTexture(nil, "ARTWORK"); r.expand:SetSize(14, 14); r.expand:Hide()
    self.gatherListRows[i] = r; Skin.WireItemTooltip(r); Skin.WireItemLink(r); return r
end

function UI:SelectGatherItem(entry)
    self.gatherEntry = entry
    self:RefreshGatherList(); self:_RefreshGatherDetail(); self:_RefreshGatherArtisans()
end

function UI:_RefreshGatherDetail()
    local e = self.gatherEntry; local c = CL()
    if self.gatherStackChk then self.gatherStackChk.Update() end   -- icône case = objet / caisse
    if not e then
        -- Rien de sélectionné → on MASQUE le badge + la ligne quantité/stacks (contrôles orphelins) ;
        -- on ne garde que le libellé d'invite.
        self.gatherResBadge:Hide()
        for _, w in ipairs({ self.gatherQHdr, self.gatherStLbl, self.gatherStackChk, self.gatherQty }) do if w then w:Hide() end end
        self.gatherResName:SetText("|cFF888888" .. L["Aucune ressource sélectionnée."] .. "|r")
        self.gatherResInfo:SetText(""); self.gatherInfoTxt:SetText("")
        if self.gatherSelLbl then self.gatherSelLbl:SetText("|cFF888888" .. L["Choisis un métier de récolte puis une ressource."] .. "|r") end
        return
    end
    for _, w in ipairs({ self.gatherQHdr, self.gatherStLbl, self.gatherStackChk, self.gatherQty }) do if w then w:Show() end end
    local nm = c and c:ItemName(e.itemID) or ("item:"..e.itemID)
    local r, g, b = Skin.RarityColor(e.itemID)
    -- « stacks » coché → icône caisse ; sinon l'icône de l'objet à récolter.
    local icon = self.gatherByStack and Skin.tex.crate or Skin.Icon(e.itemID)
    self.gatherResBadge:Paint(r, g, b, Skin.FirstChar(nm), icon); self.gatherResBadge:Show()
    self.gatherResBadge.tipItemID = e.itemID   -- tooltip d'objet de la grosse icône (WireItemTooltip)
    self.gatherResName:SetText(nm); self.gatherResName:SetTextColor(r, g, b)
    local profLbl = Skin.ProfLabel(self.gatherProf or "")
    self.gatherResInfo:SetText("|cFF888888" .. profLbl .. "|r")
    local unit = self.gatherByStack and L["par stack"] or L["à l'unité"]
    if self.gatherProf == "Elemental" then
        self.gatherInfoTxt:SetText(string.format(L["Objet |cFFE8B84Bélémentaire|r (farmé sur les mobs, pas de métier). Diffusé à tous. Quantité et prix |cFFE8B84B%s.|r"], unit))
    else
        self.gatherInfoTxt:SetText(string.format(L["Diffusée aux récolteurs ayant |cFFE8B84B%s.|r Quantité et prix proposé |cFFE8B84B%s.|r"], profLbl, unit))
    end
    -- Plus d'écho « Sélection : X » (iso Commande) : la ressource est en évidence dans l'en-tête.
    -- Le label ne sert plus qu'aux retours d'état (posté, erreurs).
    self.gatherSelLbl:SetText("")
end

function UI:_RefreshGatherArtisans()
    local D = COC.Directory; if not (D and self.gatherArtContent) then return end
    local src = self.gatherSrc or "guild"
    -- Élémentaire = farmé par n'importe qui → pas de filtre par métier.
    local prof = (self.gatherProf == "Elemental") and nil or self.gatherProf
    local list = {}
    for name, rd in pairs(D.roster or {}) do
        if inSource(rd, src) and (not prof or knowsProf(rd, prof)) then
            list[#list+1] = {name=name, r=rd, online=D.online[name]}
        end
    end
    table.sort(list, function(a, b)
        if (a.online and true) ~= (b.online and true) then return a.online end
        return a.name < b.name
    end)
    local n = 0
    for _, a in ipairs(list) do
        n = n + 1; local row = self:_GatherArtRow(n)
        row.dot:SetOnline(a.online and true or false)
        -- Métiers affichés = skill ∪ recipes (les récoltes ne vivent que dans skill).
        local profset = {}
        for p2 in pairs(a.r.recipes or {}) do profset[p2] = true end
        for p2 in pairs(a.r.skill   or {}) do profset[p2] = true end
        local profs2 = {}
        for p2 in pairs(profset) do profs2[#profs2+1] = Skin.ProfLabel(p2) end
        table.sort(profs2)
        -- Niveau du métier de récolte ciblé (ex. « Skinning 320/375 »), lisible sans ouvrir la fenêtre.
        local sk = a.r.skill and prof and a.r.skill[prof]
        local skTxt = sk and ("|cFF888888"..sk[1].."/"..sk[2].."|r  ") or ""
        row.name:SetText("|cFFFFFFFF"..a.name.."|r  "..skTxt.."|cFF888888"..table.concat(profs2, " · ").."|r")
        row.src:SetText("|cFF888888"..(a.r.source or ""):upper().."|r")
        row.artEntry = a; row.selTex:SetShown(UI.gatherTarget == "@" .. a.name)
        row:SetScript("OnClick", function()
            UI.gatherTarget = "@" .. a.name; UI:_RefreshGatherArtisans()
        end)
        row:Show()
    end
    for i = n+1, #self.gatherArtRows do self.gatherArtRows[i]:Hide() end
    self.gatherArtContent:SetHeight(math.max(n * ARH, 10))
    Skin.AutoHideScroll("COCGatherArtScroll", self.gatherArtContent)
    self:_RefreshAllRow("gather"); self:_UpdateGatherArtisanLabel()
end

function UI:_GatherArtRow(i)
    local r = self.gatherArtRows[i]; if r then return r end
    r = Skin.MakeArtisanRow(self.gatherArtContent, (self.gatherArtW or G.WIDE_W) - 22, ARH)   -- pastille + nom + source (kit)
    r:SetPoint("TOPLEFT", 0, -(i-1)*ARH)
    self.gatherArtRows[i] = r; return r
end

-- Valeur CANONIQUE du destinataire (cf. _PostTargetLabel / Orders:VisibleTo).
function UI:_GatherTargetLabel()
    local t = self.gatherTarget or "all"
    if t == "all"        then return "Tous" end
    if t:sub(1, 1) == "@" then return t:sub(2) end
    if t == "guild"      then return "Guilde" end
    if t == "friend"     then return "Amis" end
    return "Tous"
end

function UI:_UpdateGatherArtisanLabel()
    if self.gatherArtisanName then
        local t = self.gatherTarget or "all"
        local col = (t == "all") and "FFAAAAAA" or "FFFFFFFF"
        self.gatherArtisanName:SetText("|c" .. col .. L[self:_GatherTargetLabel()] .. "|r")
    end
    self:_SyncHeaderSkill()   -- la jauge du header suit le récolteur ciblé (niveau du métier de récolte)
end

-- =========================================================================
-- Poster une commande de récolte
-- =========================================================================
function UI:DoGatherOrder()
    local e = self.gatherEntry
    if not e then self.gatherSelLbl:SetText("|cFFFF4444" .. L["Choisis d'abord une ressource."] .. "|r"); return end
    local qty  = tonumber(self.gatherQty:GetText()) or 1
    local g    = tonumber(self.gatherGold:GetText()) or 0
    local s    = tonumber(self.gatherSilver:GetText()) or 0
    local cu   = tonumber(self.gatherCopper:GetText()) or 0
    local price = nil
    if g > 0 or s > 0 or cu > 0 then
        local parts = {}
        if g  > 0 then parts[#parts+1] = g.."po"  end
        if s  > 0 then parts[#parts+1] = s.."pa"  end
        if cu > 0 then parts[#parts+1] = cu.."pc" end
        price = table.concat(parts, " ")
    end
    COC.Orders:PostEntry(e, qty, price, {
        profession = self.gatherProf, recipient = self:_GatherTargetLabel(), byStack = self.gatherByStack,
    })
    self.gatherGold:SetText("0"); self.gatherSilver:SetText("0"); self.gatherCopper:SetText("0")
    self.gatherQty:SetText("1"); self.gatherEntry = nil
    self.gatherByStack = false; if self.gatherStackChk then self.gatherStackChk.Update() end
    self.gatherSelLbl:SetText("|cFF33DD33" .. L["Commande de récolte postée !"] .. "|r")
    self:ShowTab("orders")
end
