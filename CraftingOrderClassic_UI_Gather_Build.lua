-- CraftingOrderClassic_UI_Gather_Build.lua — onglet « Récolte », moitié CONSTRUCTION.
--
-- Extrait de _UI_Gather.lua (plafond anti-monolithe de 500 lignes). La coupe suit une frontière
-- réelle et pas un simple compte de lignes : ici on POSE les cadres une fois, en face _UI_Gather.lua
-- les RAFRAÎCHIT à chaque changement d'état. Preuve que la frontière est la bonne — aucune des
-- locales de données (ARH, GATHER_PROFS, CL, knowsProf, inSource) n'était utilisée de ce côté.
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

    -- Liste des ressources : la liste défilante du kit (palier 2c), aux coins de la zone, comme la
    -- liste des plans de l'onglet Commande (palier 1) dont elle reprend les lignes et les en-têtes.
    local sec = self:GatherSec("resources")
    self.gatherResHost = CreateFrame("Frame", nil, sec)
    self:_AnchorGatherResHost(false)
    self.gatherResList = Skin.MakeScrollList(self.gatherResHost, {
        extent = function(item) return UI:_GatherResExtent(item) end,
        build  = function(row) UI:_BuildGatherResRow(row) end,
        fill   = function(row, item) row.item = item; UI:_FillGatherRow(row, item) end,
    })
end

-- La liste couvre sa gouttière (cf. Skin.LIST_EDGE) et, quand les pills d'extension sont cachées
-- (tout métier sauf « Élémentaire »), leur bande aussi : sinon deux vides encadraient la liste, sous
-- la recherche et à droite de la barre (vus en jeu le 2026-09-28). Rappelé par _RefreshGatherVerPills.
function UI:_AnchorGatherResHost(pills)
    local host = self.gatherResHost; if not host then return end
    host:ClearAllPoints()
    host:SetPoint("TOPLEFT", self:GatherSec(pills and "resources" or "verPills"), "TOPLEFT", G.PAD, 0)
    host:SetPoint("BOTTOMRIGHT", self:GatherSec("resGutter"), "BOTTOMRIGHT", -Skin.LIST_EDGE, G.PAD)
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

    -- Prix proposé : le champ montant du formulaire des Commandes d'artisanat (palier 4, comme la
    -- commission de l'onglet Commande), à 10 px de son libellé, centré dans sa zone.
    local psec = self:GatherSec("price")
    local pLbl = psec:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pLbl:SetPoint("LEFT", G.PAD, 0); pLbl:SetText("|cFFE8B84B" .. L["Prix proposé"] .. "|r"); Skin.ApplyShadow(pLbl)
    self.gatherMoney = Skin.MakeMoneyInput(psec, 200)
    self.gatherMoney:SetPoint("LEFT", pLbl, "RIGHT", 10, 0)

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
    -- Le compteur de « Créer tout » (palier 4) : l'ancre porte sur sa CASE, dont le [+] déborde de
    -- 23 px à droite — d'où -31 (23 + 8) contre la case « stacks ».
    self.gatherQty = Skin.MakeQtySpinner(qc)
    self.gatherQty:SetPoint("RIGHT", stChk, "LEFT", -31, 0)
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
    -- Jusqu'au-dessus du statut (posé à 6 du bas, cf. _BuildGatherActionBar), comme dans Commande :
    -- 4 lignes laissaient un grand vide sous une liste qui défilait (relevé en jeu le 2026-09-27).
    self:_BuildAllRowAndScroll(az, "gather", -G.PAD, G.PAD, aw, {
        fill   = function(row, a) UI:_FillGatherArtRow(row, a) end,
        bottom = 22,
    })

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
