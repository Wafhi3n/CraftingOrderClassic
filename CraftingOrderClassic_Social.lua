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
    -- Icône de métier INLINE (|T…|t) plutôt que le nom long → ligne compacte. Repli sur le libellé
    -- si le client n'a pas l'icône en cache.
    local function profMark(key)
        local t = sk and sk.ProfIcon(key)
        return t and ("|T" .. t .. ":14:14:0:0|t") or (sk and sk.ProfLabel(key) or key)
    end
    local parts = {}
    -- Priorité : niveaux SK reçus (plus précis — icône + « 250/300 »).
    for key, sv in pairs(r.skill or {}) do
        parts[#parts + 1] = profMark(key) .. " " .. sv[1] .. "/" .. sv[2]
    end
    -- Fallback : métiers connus via bitfield RK, sans niveau → icône seule.
    if #parts == 0 then
        for key in pairs(r.recipes or {}) do parts[#parts + 1] = profMark(key) end
    end

    if #parts == 0 then return end
    table.sort(parts)
    -- Marque addon = icône WorkOrder (le glyphe « ✓ » s'affichait en tofu dans la police WoW).
    local mark = sk and ("  |T" .. sk.tex.workorder .. ":14:14:0:0|t") or ""
    local rep = (r.rep and r.rep > 0) and ("  |cFFE8B84B" .. string.format(COC.L["%d livrés"], r.rep) .. "|r") or ""
    tooltip:AddLine("|cFF33DD88CO-Classic|r" .. mark .. "  " .. table.concat(parts, "   ") .. rep, 1, 1, 1)
    tooltip:Show()
end

-- =========================================================================
-- Clic-droit : « Ajouter aux artisans »
-- =========================================================================
local COC_MENU_KEY    = "COC_ADD_TO_CRAFTERS"
local COC_MUTE_KEY    = "COC_MUTE_PLAYER"
local COC_PARTNER_KEY = "COC_TOGGLE_PARTNER"

-- Nom du joueur ciblé par le menu contextuel ouvert (convention variable selon la version Classic).
local function menuTargetName()
    local name
    local menu = UIDROPDOWNMENU_OPEN_MENU
    if menu then
        name = menu.name
        if not name and menu.unit then name = UnitName(menu.unit) end
    end
    if not (name and name ~= "") then name = UnitName("mouseover") end   -- dernier recours : sous la souris
    return name
end

local function InjectContextMenu()
    if not (UnitPopupMenus and UnitPopupButtons) then return end
    local L = COC.L
    local targets = { "PLAYER", "PARTY", "RAID_PLAYER", "FRIEND", "GUILD" }
    for _, t in ipairs(targets) do
        local menu = UnitPopupMenus[t]
        if menu then
            for _, key in ipairs({ COC_MENU_KEY, COC_PARTNER_KEY, COC_MUTE_KEY }) do
                local already = false
                for _, k in ipairs(menu) do if k == key then already = true; break end end
                if not already then
                    -- Insère avant « CANCEL » (dernier item) pour respecter l'ordre visuel.
                    local n = #menu
                    if menu[n] == "CANCEL" then table.insert(menu, n, key)
                    else menu[#menu + 1] = key end
                end
            end
        end
    end

    UnitPopupButtons[COC_MENU_KEY] = {
        text = L["Ajouter aux artisans"], dist = 0,
        func = function()
            local name = menuTargetName()
            if name and name ~= "" and COC.UI and COC.UI._AddArtisan then COC.UI:_AddArtisan(name) end
        end,
    }
    UnitPopupButtons[COC_PARTNER_KEY] = {
        text = L["Partenaire (basculer)"], dist = 0,
        func = function()
            local name = menuTargetName()
            if name and name ~= "" and COC.UI and COC.UI._TogglePartner then COC.UI:_TogglePartner(name) end
        end,
    }
    UnitPopupButtons[COC_MUTE_KEY] = {
        text = L["Muter"], dist = 0,
        func = function()
            local name = menuTargetName()
            if name and name ~= "" and COC.Moderation then COC.Moderation:Mute(name) end
        end,
    }
end

-- =========================================================================
-- Découverte au CROISEMENT : survoler / cibler / grouper un joueur → on lui chuchote un PING+HI
-- (Dir:DiscoverPlayer, throttlé 60 s/nom). S'il a l'addon, il répond → il entre dans Croisés/Met
-- avec ses métiers. S'il ne l'a pas, rien (addon-messages whisper invisibles côté receveur).
-- =========================================================================
local function discover(unit)
    if not (unit and COC.Directory and UnitIsPlayer and UnitIsPlayer(unit)) then return end
    if UnitIsUnit and UnitIsUnit(unit, "player") then return end
    -- Whisper addon-message ne traverse pas la faction adverse → on ne ping que les alliés potentiels.
    if UnitCanCooperate and not UnitCanCooperate("player", unit) then return end
    local name = UnitName(unit)
    if name and name ~= "" then COC.Directory:DiscoverPlayer(name) end
end

function Social:_WireDiscovery()
    local f = CreateFrame("Frame")
    f:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")
    f:SetScript("OnEvent", function(_, event)
        if event == "UPDATE_MOUSEOVER_UNIT" then discover("mouseover")
        elseif event == "PLAYER_TARGET_CHANGED" then discover("target")
        else
            local prefix = IsInRaid and IsInRaid() and "raid" or "party"
            for i = 1, (GetNumGroupMembers and GetNumGroupMembers() or 0) do discover(prefix .. i) end
        end
    end)
end

-- =========================================================================
-- Activation (appelé depuis PLAYER_LOGIN dans CraftingOrderClassic.lua)
-- =========================================================================
function Social:Start()
    if GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipUnit)
    end
    InjectContextMenu()
    self:_WireDiscovery()
end
