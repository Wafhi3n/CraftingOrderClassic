-- CraftingOrderClassic_Social.lua — Étape D : couche sociale passive.
-- * Tooltip joueur : survol → métiers + niveaux depuis Directory.roster (verbe SK).
-- * Clic-droit : « Ajouter aux artisans » dans le menu contextuel joueur.

local COC    = CraftingOrderClassic
local Social = {}
COC.Social   = Social

local function GetSkin() return COC.UI and COC.UI.Skin end

-- =========================================================================
-- Tooltip social
-- =========================================================================
local function OnTooltipUnit(tooltip)
    local _, unit = tooltip:GetUnit()
    if not unit then return end
    local name = UnitName(unit)
    if not (name and COC.Directory) then return end
    local r = COC.Directory.roster[name]
    if not r then return end

    local sk = GetSkin()
    local parts = {}

    -- Priorité : niveaux SK reçus (plus précis — « Forge 250/300 »).
    for key, sv in pairs(r.skill or {}) do
        parts[#parts + 1] = (sk and sk.ProfLabel(key) or key) .. " " .. sv[1] .. "/" .. sv[2]
    end
    -- Fallback : métiers connus via bitfield RK, sans niveau.
    if #parts == 0 then
        for key in pairs(r.recipes or {}) do
            parts[#parts + 1] = sk and sk.ProfLabel(key) or key
        end
    end

    if #parts == 0 then return end
    table.sort(parts)
    tooltip:AddLine("|cFF33DD88CO-Classic ✓|r  " .. table.concat(parts, " · "), 1, 1, 1)
    tooltip:Show()
end

-- =========================================================================
-- Clic-droit : « Ajouter aux artisans »
-- =========================================================================
local COC_MENU_KEY = "COC_ADD_TO_CRAFTERS"

local function InjectContextMenu()
    if not (UnitPopupMenus and UnitPopupButtons) then return end
    local targets = { "PLAYER", "PARTY", "RAID_PLAYER", "FRIEND", "GUILD" }
    for _, t in ipairs(targets) do
        local menu = UnitPopupMenus[t]
        if menu then
            local already = false
            for _, k in ipairs(menu) do if k == COC_MENU_KEY then already = true; break end end
            if not already then
                -- Insère avant « CANCEL » (dernier item) pour respecter l'ordre visuel.
                local n = #menu
                if menu[n] == "CANCEL" then table.insert(menu, n, COC_MENU_KEY)
                else menu[#menu + 1] = COC_MENU_KEY end
            end
        end
    end

    UnitPopupButtons[COC_MENU_KEY] = {
        text = "Ajouter aux artisans",
        dist = 0,
        func = function()
            -- Récupère le nom depuis le menu ouvert (convention variable selon la version Classic).
            local name
            local menu = UIDROPDOWNMENU_OPEN_MENU
            if menu then
                name = menu.name
                if not name and menu.unit then name = UnitName(menu.unit) end
            end
            -- Dernier recours : unité sous la souris.
            if not (name and name ~= "") then name = UnitName("mouseover") end
            if name and name ~= "" and COC.UI and COC.UI._AddArtisan then
                COC.UI:_AddArtisan(name)
            end
        end,
    }
end

-- =========================================================================
-- Activation (appelé depuis PLAYER_LOGIN dans CraftingOrderClassic.lua)
-- =========================================================================
function Social:Start()
    if GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipUnit)
    end
    InjectContextMenu()
end
