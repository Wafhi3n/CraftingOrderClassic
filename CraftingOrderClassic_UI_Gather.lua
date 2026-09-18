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
