-- CraftingOrderClassic_Minimap.lua — bouton minimap (toggle du carnet). Icône native WorkOrder.
-- Position persistée en angle (COC.db.minimapAngle). Glisser = repositionner autour de la minimap.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin

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
    b:SetScript("OnClick", function() UI:Toggle() end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cFF33DD88Crafting Order|r — Classic")
        GameTooltip:AddLine("Clic : ouvrir le carnet d'ordres", 1, 1, 1)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.minimapBtn = b
end
