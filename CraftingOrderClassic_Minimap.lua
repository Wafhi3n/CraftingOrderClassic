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
    r = Skin.MakeFlatRow(m, 164, 20)   -- ligne de menu plate (fillMenuRow ré-ancre .text selon le cas)
    r.text:SetPoint("LEFT", 26, 0)
    r.ic = r:CreateTexture(nil, "OVERLAY"); r.ic:SetSize(16, 16); r.ic:SetPoint("LEFT", 5, 0)
    m.rows[i] = r; return r
end

-- Configure une ligne du pool : header de section (doré, sans icône, non cliquable) ou entrée
-- cliquable (icône + libellé + OnClick). Recycle proprement l'état entre ouvertures.
local function fillMenuRow(r, y, opts)
    r:ClearAllPoints(); r:SetPoint("TOPLEFT", 10, y)
    if opts.header then
        r.ic:Hide(); r.text:ClearAllPoints(); r.text:SetPoint("LEFT", 10, 0)
        r:SetText("|cFF888888" .. opts.label .. "|r"); r:SetScript("OnClick", nil); r:Disable()
    else
        r.ic:Show(); r.ic:SetTexture(opts.icon); r.text:ClearAllPoints(); r.text:SetPoint("LEFT", 26, 0)
        r:SetText(opts.label); r:SetScript("OnClick", opts.onClick); r:Enable()
    end
    r:Show()
end

function UI:ToggleProfMenu()
    local m = self.profMenu or self:_BuildProfMenu()
    if m:IsShown() then m:Hide(); return end
    local D = COC.Directory
    local keys = {}
    for k in pairs((D and D.mySkills) or {}) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return Skin.ProfLabel(a) < Skin.ProfLabel(b) end)
    local rerolls = (D and D.RerollProfEntries and D:RerollProfEntries()) or {}
    local any = #keys > 0 or #rerolls > 0
    m.title:SetText(any and ("|cFFE8B84B" .. L["Mes métiers"] .. "|r") or ("|cFF888888" .. L["Aucun métier connu."] .. "|r"))
    local y, i = -26, 0
    for _, key in ipairs(keys) do
        i = i + 1
        fillMenuRow(self:_ProfMenuRow(m, i), y, { icon = Skin.ProfIcon(key) or Skin.tex.unknown, label = Skin.ProfLabel(key),
            onClick = function() m:Hide(); if COC.ProfWindow then COC.ProfWindow:OpenFor(key) end end })
        y = y - 22
    end
    if #rerolls > 0 then
        i = i + 1; fillMenuRow(self:_ProfMenuRow(m, i), y, { header = true, label = L["Rerolls"] }); y = y - 22
        for _, e in ipairs(rerolls) do
            i = i + 1
            fillMenuRow(self:_ProfMenuRow(m, i), y, { icon = Skin.ProfIcon(e.prof) or Skin.tex.unknown,
                label = Skin.ProfLabel(e.prof) .. " |cFF888888— " .. e.name .. "|r",
                onClick = function() m:Hide(); if COC.ProfWindow then COC.ProfWindow:OpenForReroll(e.prof, e.key, e.name) end end })
            y = y - 22
        end
    end
    for j = i + 1, #m.rows do m.rows[j]:Hide() end
    m:SetWidth(rerolls[1] and 220 or 184)             -- élargi pour « Métier — Nom »
    m:SetHeight(math.max(-y + 6, 40))
    m:ClearAllPoints(); m:SetPoint("TOPRIGHT", self.minimapBtn or Minimap, "BOTTOMLEFT", 0, 0); m:Show()
end
