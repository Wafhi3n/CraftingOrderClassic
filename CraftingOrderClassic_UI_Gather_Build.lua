-- CraftingOrderClassic_UI_Gather_Build.lua — onglet « Récolte », moitié CONSTRUCTION.
--
-- Extrait de _UI_Gather.lua (plafond anti-monolithe de 500 lignes). La coupe suit une frontière
-- réelle et pas un simple compte de lignes : ici on POSE les cadres une fois, en face _UI_Gather.lua
-- les RAFRAÎCHIT à chaque changement d'état. Preuve que la frontière est la bonne — aucune des
-- locales de données (GLH, ARH, GATHER_PROFS, CL, knowsProf, inSource) n'était utilisée de ce côté.
--
-- GÉOMÉTRIE : SPEC déclarative dans _UI_Gather_Layout.lua (chargé avant) — zones via UI:GatherSec(id),
-- contenu en offsets RELATIFS à sa zone, largeurs LUES sur les zones.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L   -- localisation du chrome
local G    = UI.GATHER   -- métriques dérivées de la SPEC — cf. _UI_Gather_Layout.lua

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
        -- Même résolution que l'onglet Commande (cf. UI_Post:_ToggleProfFlyout).
        local p = COC.Api.PortraitTexture(self.frame)
        if p then self.gatherProfFlyout:ToggleAt("TOPLEFT", p, "BOTTOMLEFT", -6, -6) end
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
