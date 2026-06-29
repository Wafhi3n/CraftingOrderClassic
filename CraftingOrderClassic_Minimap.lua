-- CraftingOrderClassic_Minimap.lua — bouton minimap (toggle du carnet). Icône native WorkOrder.
-- Position persistée en angle (COC.db.minimapAngle). Glisser = repositionner autour de la minimap.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local RADIUS = 80

function UI:BuildMinimapButton()
    if self.minimapBtn or not Minimap then return end
    local b = CreateFrame("Button", "CraftingOrderMinimapButton", Minimap)
    b:SetSize(31, 31); b:SetFrameStrata("MEDIUM"); b:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")

    local icon = b:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20); icon:SetPoint("CENTER", 0, 1); icon:SetTexture(Skin.tex.workorder)

    local overlay = b:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53); overlay:SetPoint("TOPLEFT")
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    local function place(angle)
        b:SetPoint("CENTER", Minimap, "CENTER", RADIUS * cos(angle), RADIUS * sin(angle))
    end
    place((COC.db and COC.db.minimapAngle) or 210)

    b:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local scale  = Minimap:GetEffectiveScale()
            local px, py = GetCursorPosition()
            local angle  = atan2(py / scale - my, px / scale - mx)
            place(angle); if COC.db then COC.db.minimapAngle = angle end
        end)
    end)
    b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    b:SetScript("OnClick", function(_, btn)
        if btn == "RightButton" then UI:ToggleProfMenu() else UI:Toggle() end
    end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cFF33DD88Crafting Order|r — Classic")
        GameTooltip:AddLine(L["Clic : ouvrir le carnet d'ordres"], 1, 1, 1)
        GameTooltip:AddLine(L["Clic droit : mes métiers"], 0.6, 1, 0.6)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.minimapBtn = b
end

-- ------------------------------------------------------------------
-- Menu « mes métiers » (clic droit minimap) : ouvre la vue commandes d'un métier (craft OU récolte,
-- qui n'a pas de fenêtre en jeu). Liste MES métiers depuis l'annuaire (Directory.mySkills).
-- ------------------------------------------------------------------
function UI:_BuildProfMenu()
    local m = CreateFrame("Frame", "CraftingOrderProfMenu", UIParent, "BackdropTemplate")
    m:SetSize(184, 40); m:SetFrameStrata("DIALOG"); Skin.SkinWell(m); m:Hide(); m.rows = {}
    m.title = m:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    m.title:SetPoint("TOPLEFT", 10, -8); Skin.ApplyShadow(m.title)
    local closer = CreateFrame("Button", nil, UIParent)
    closer:SetAllPoints(); closer:SetFrameStrata("DIALOG"); closer:Hide()
    m:SetFrameLevel(closer:GetFrameLevel() + 1)
    closer:SetScript("OnClick", function() m:Hide() end)
    m:SetScript("OnShow", function() closer:Show() end); m:SetScript("OnHide", function() closer:Hide() end)
    self.profMenu = m
    return m
end

function UI:_ProfMenuRow(m, i)
    local r = m.rows[i]; if r then return r end
    r = Skin.MakeGoldButton(m, 164, 20, "")
    r.text:SetJustifyH("LEFT"); r.text:ClearAllPoints(); r.text:SetPoint("LEFT", 26, 0)
    r.ic = r:CreateTexture(nil, "OVERLAY"); r.ic:SetSize(16, 16); r.ic:SetPoint("LEFT", 5, 0)
    m.rows[i] = r; return r
end

function UI:ToggleProfMenu()
    local m = self.profMenu or self:_BuildProfMenu()
    if m:IsShown() then m:Hide(); return end
    local D = COC.Directory
    local keys = {}
    for k in pairs((D and D.mySkills) or {}) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return Skin.ProfLabel(a) < Skin.ProfLabel(b) end)
    m.title:SetText((#keys > 0) and ("|cFFE8B84B" .. L["Mes métiers"] .. "|r") or ("|cFF888888" .. L["Aucun métier connu."] .. "|r"))
    local y = -26
    for i, key in ipairs(keys) do
        local r = self:_ProfMenuRow(m, i)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 10, y)
        r.ic:SetTexture(Skin.ProfIcon(key) or Skin.tex.unknown); r:SetText(Skin.ProfLabel(key))
        r:SetScript("OnClick", function() m:Hide(); if COC.ProfWindow then COC.ProfWindow:OpenFor(key) end end)
        r:Show(); y = y - 22
    end
    for i = #keys + 1, #m.rows do m.rows[i]:Hide() end
    m:SetHeight(math.max(-y + 6, 40))
    m:ClearAllPoints(); m:SetPoint("TOPRIGHT", self.minimapBtn or Minimap, "BOTTOMLEFT", 0, 0); m:Show()
end
