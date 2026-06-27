-- CraftingOrderClassic_UI_Post.lua — onglet « Poster » : recherche d'objet à fabriquer/récolter
-- par métier → réactifs (cases « je fournis ») → poster une commande. Remplace le shift-clic.
-- Lit CraftLink (ProfessionCatalogue / RecipeReagents / ItemName). Chargé après _UI.lua.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local RH   = 16

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end
local function itemName(id) local c=CL(); return c and c:ItemName(id) or ("item:"..tostring(id)) end

-- Nom d'une entrée de catalogue : objet (GetItemInfo) ou service/enchant (GetSpellInfo).
local function entryName(e)
    local c = CL(); if not c then return "?" end
    if e.itemID then return c:ItemName(e.itemID) end
    return c:RecipeName(e.spellID)
end

-- Objet lié-quand-ramassé (non échangeable) → à masquer. nil si pas encore en cache (on montre).
local function isSoulbound(itemID)
    if not (itemID and GetItemInfo) then return false end
    local bind = select(14, GetItemInfo(itemID))   -- 1 = Bind on Pickup
    return bind == 1
end

-- ------------------------------------------------------------------
-- Construction
-- ------------------------------------------------------------------
function UI:BuildPostTab(f)
    local panel = CreateFrame("Frame", nil, f); panel:SetAllPoints(f); panel:Hide()
    self.postPanel = panel
    self.postProvide = {}

    -- Colonne gauche : métiers
    local profHdr = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    profHdr:SetPoint("TOPLEFT", 14, -76); profHdr:SetText("|cFFE8B84BMétier|r")
    local pscroll = CreateFrame("ScrollFrame", "COCPostProfScroll", panel, "UIPanelScrollFrameTemplate")
    pscroll:SetPoint("TOPLEFT", 12, -92); pscroll:SetPoint("BOTTOMLEFT", 12, 92); pscroll:SetWidth(120)
    local pcontent = CreateFrame("Frame", nil, pscroll); pcontent:SetSize(110, 10); pscroll:SetScrollChild(pcontent)
    self.postProfContent = pcontent; self.postProfRows = {}

    -- Recherche + catalogue (droite)
    local search = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    search:SetSize(220, 18); search:SetPoint("TOPLEFT", 150, -78); search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", function(b) UI.postSearch = b:GetText():lower(); UI:RefreshPostCatalogue() end)
    search:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)
    local sLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sLbl:SetPoint("BOTTOMLEFT", search, "TOPLEFT", 2, 1); sLbl:SetText("Rechercher un objet")

    local cscroll = CreateFrame("ScrollFrame", "COCPostCatScroll", panel, "UIPanelScrollFrameTemplate")
    cscroll:SetPoint("TOPLEFT", 150, -100); cscroll:SetPoint("TOPRIGHT", -30, -100); cscroll:SetHeight(8 * RH)
    local ccontent = CreateFrame("Frame", nil, cscroll); ccontent:SetSize(330, 10); cscroll:SetScrollChild(ccontent)
    self.postCatScroll = cscroll; self.postCatContent = ccontent; self.postCatRows = {}

    -- Réactifs « je fournis »
    local rHdr = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rHdr:SetPoint("TOPLEFT", 150, -100 - 8 * RH - 8); rHdr:SetText("|cFFE8B84BRéactifs|r |cFF888888(cocher = je fournis)|r")
    self.postReagHdr = rHdr
    local rscroll = CreateFrame("ScrollFrame", "COCPostReagScroll", panel, "UIPanelScrollFrameTemplate")
    rscroll:SetPoint("TOPLEFT", 150, -100 - 8 * RH - 24); rscroll:SetPoint("BOTTOMRIGHT", -30, 64)
    local rcontent = CreateFrame("Frame", nil, rscroll); rcontent:SetSize(330, 10); rscroll:SetScrollChild(rcontent)
    self.postReagContent = rcontent; self.postReagRows = {}

    self:_BuildPostBottom(panel)

    -- Noms d'objets chargés en différé par Blizzard → on rafraîchit le catalogue quand ils arrivent.
    local ev = CreateFrame("Frame")
    ev:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    ev:SetScript("OnEvent", function() UI:_PostNameDirty() end)
end

function UI:_BuildPostBottom(panel)
    local sel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sel:SetPoint("BOTTOMLEFT", 14, 40); sel:SetWidth(300); sel:SetJustifyH("LEFT"); Skin.ApplyShadow(sel)
    sel:SetText("|cFF888888Choisis un métier puis un objet.|r"); self.postSelLbl = sel

    local btn = Skin.MakeGoldButton(panel, 70, 22, "Poster")
    btn:SetPoint("BOTTOMRIGHT", -14, 36)
    btn:SetScript("OnClick", function() UI:DoPostOrder() end)
    local price = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    price:SetSize(64, 18); price:SetPoint("RIGHT", btn, "LEFT", -10, 0); price:SetAutoFocus(false)
    price:SetScript("OnEscapePressed", function(b) b:ClearFocus() end); self.postPrice = price
    local pl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); pl:SetPoint("RIGHT", price, "LEFT", -3, 0); pl:SetText("Prix")
    local qty = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    qty:SetSize(36, 18); qty:SetPoint("RIGHT", pl, "LEFT", -8, 0); qty:SetAutoFocus(false); qty:SetNumeric(true); qty:SetText("1")
    qty:SetScript("OnEscapePressed", function(b) b:ClearFocus() end); self.postQty = qty
    local ql = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); ql:SetPoint("RIGHT", qty, "LEFT", -3, 0); ql:SetText("Qté")
end

-- ------------------------------------------------------------------
-- Métiers (gauche)
-- ------------------------------------------------------------------
function UI:_PostProfRow(i)
    local r = self.postProfRows[i]; if r then return r end
    r = Skin.MakeGoldButton(self.postProfContent, 106, RH)
    r:SetPoint("TOPLEFT", 0, -(i - 1) * RH); r.text:SetJustifyH("LEFT"); r.text:ClearAllPoints(); r.text:SetPoint("LEFT", 4, 0)
    self.postProfRows[i] = r; return r
end

function UI:RefreshPostProfs()
    local c = CL(); local profs = c and c:Professions() or {}
    if not self.postProf and profs[1] then self.postProf = profs[1] end
    for i, prof in ipairs(profs) do
        local r = self:_PostProfRow(i)
        r:SetText(prof); r:SetSelected(prof == self.postProf)
        r:SetScript("OnClick", function() UI.postProf = prof; UI.postEntry = nil; UI:RefreshPost() end)
        r:Show()
    end
    for i = #profs + 1, #self.postProfRows do self.postProfRows[i]:Hide() end
    self.postProfContent:SetHeight(math.max(#profs * RH, 10))
end

-- ------------------------------------------------------------------
-- Catalogue (droite)
-- ------------------------------------------------------------------
function UI:_PostCatRow(i)
    local r = self.postCatRows[i]; if r then return r end
    r = CreateFrame("Button", nil, self.postCatContent); r:SetSize(326, RH); r:SetPoint("TOPLEFT", 0, -(i - 1) * RH)
    local hi = r:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints(); hi:SetColorTexture(Skin.unpack(Skin.color.rowHover))
    r.fs = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); r.fs:SetPoint("LEFT", 4, 0); r.fs:SetJustifyH("LEFT"); Skin.ApplyShadow(r.fs)
    self.postCatRows[i] = r; return r
end

function UI:RefreshPostCatalogue()
    local c = CL(); if not (c and self.postCatScroll) then return end
    local list = self.postProf and c:ProfessionCatalogue(self.postProf) or {}
    local s = self.postSearch
    local out = {}
    for _, e in ipairs(list) do
        if not (e.itemID and isSoulbound(e.itemID)) then   -- masque les objets liés (non échangeables)
            local nm = entryName(e)
            if not s or s == "" or nm:lower():find(s, 1, true) or (e.itemID and tostring(e.itemID):find(s, 1, true)) then
                out[#out + 1] = { e = e, name = nm }
            end
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    local off = math.floor(self.postCatScroll:GetVerticalScroll() / RH)
    for i = 1, 8 do
        local row = self:_PostCatRow(i); local item = out[off + i]
        if item then
            local e = item.e
            row.entry = e
            local tag = e.service and " |cFFCC88FF(ench.)|r"
                or ((e.itemID and not e.spellID) and " |cFF66CC66(matière)|r" or "")
            -- placeholder tant que le nom d'objet n'est pas résolu (cache async Blizzard)
            local disp = item.name:match("^item:") and "|cFF777777Chargement…|r" or item.name
            row.fs:SetText(disp .. tag)
            row.fs:SetTextColor(e == self.postEntry and 1 or 0.91, e == self.postEntry and 0.85 or 0.86, e == self.postEntry and 0.27 or 0.78)
            row:SetScript("OnClick", function() UI:SelectPostItem(e) end)
            row:Show()
        else row:Hide() end
    end
    self.postCatContent:SetHeight(math.max(#out * RH, 8 * RH))
    self.postCatList = out
end

-- Rafraîchissement throttlé quand Blizzard renvoie un nom d'objet (GET_ITEM_INFO_RECEIVED).
function UI:_PostNameDirty()
    if self._postNameTimer or not C_Timer then return end
    self._postNameTimer = true
    C_Timer.After(0.3, function()
        UI._postNameTimer = nil
        if UI.postPanel and UI.postPanel:IsShown() then UI:RefreshPostCatalogue() end
    end)
end

function UI:SelectPostItem(entry)
    self.postEntry = entry; self.postProvide = {}
    self.postSelLbl:SetText("Sélection : |cFFFFFFFF" .. entryName(entry) .. "|r")
    self:RefreshPostCatalogue(); self:RefreshPostReagents()
end

-- ------------------------------------------------------------------
-- Réactifs (cases « je fournis »)
-- ------------------------------------------------------------------
function UI:_PostReagRow(i)
    local r = self.postReagRows[i]; if r then return r end
    r = CreateFrame("Button", nil, self.postReagContent); r:SetSize(326, RH); r:SetPoint("TOPLEFT", 0, -(i - 1) * RH)
    r.fs = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); r.fs:SetPoint("LEFT", 4, 0); r.fs:SetJustifyH("LEFT"); Skin.ApplyShadow(r.fs)
    self.postReagRows[i] = r; return r
end

function UI:RefreshPostReagents()
    local c = CL()
    local reag = (c and self.postEntry and self.postEntry.spellID) and c:RecipeReagents(self.postProf, self.postEntry.spellID) or {}
    for i = 1, #self.postReagRows do self.postReagRows[i]:Hide() end
    for i, rg in ipairs(reag) do
        local row = self:_PostReagRow(i); local iid, qty = rg[1], rg[2]
        local function paint()
            local box = UI.postProvide[iid] and "|cFF33DD33[x]|r" or "|cFF888888[ ]|r"
            row.fs:SetText(string.format("%s %s |cFFFFCC00x%d|r", box, itemName(iid), qty))
        end
        row:SetScript("OnClick", function() UI.postProvide[iid] = not UI.postProvide[iid]; paint() end)
        paint(); row:Show()
    end
    self.postReagContent:SetHeight(math.max(#reag * RH, 10))
    self.postReagHdr:SetShown(self.postEntry ~= nil)
end

-- ------------------------------------------------------------------
-- Poster
-- ------------------------------------------------------------------
function UI:DoPostOrder()
    local e = self.postEntry
    if not e then self.postSelLbl:SetText("|cFFFF4444Choisis d'abord un objet.|r"); return end
    local qty = tonumber(self.postQty:GetText()) or 1
    local price = self.postPrice:GetText(); if price == "" then price = nil end
    local provided = {}
    for iid, v in pairs(self.postProvide) do if v then provided[#provided + 1] = iid end end
    COC.Orders:PostEntry(e, qty, price, { profession = self.postProf, provided = provided })
    self.postPrice:SetText(""); self.postEntry = nil; self.postProvide = {}
    self:ShowTab("orders")   -- retour au carnet pour voir la commande
end

-- Refresh global de l'onglet
function UI:RefreshPost()
    self:RefreshPostProfs(); self:RefreshPostCatalogue(); self:RefreshPostReagents()
end
