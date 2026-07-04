-- CraftingOrderClassic_Social.lua — couche sociale passive (socle).
-- * Social:ProfSummary(nom) : résumé métiers+niveaux d'un joueur présent dans Directory.roster
--   (icônes + « 250/300 » via SK, repli bitfield RK). Réutilisé par le tooltip MONDE (ci-dessous),
--   le tooltip d'AMI et le panneau de GUILDE (_Social_Roster.lua), et le menu (_Social_Menu.lua).
-- * Découverte au croisement : survol / cible / groupe → whisper PING+HI throttlé (Dir:DiscoverPlayer).

local COC    = CraftingOrderClassic
local Social = {}
COC.Social   = Social

local function GetSkin() return COC.UI and COC.UI.Skin end

-- Métiers SECONDAIRES : jamais affichés dans le résumé social (seuls les PRIMAIRES intéressent la
-- prise de commande). Table PARTAGÉE définie dans CraftingOrderClassic.lua (source unique).
local SECONDARY_PROF = COC.SECONDARY_PROF

-- =========================================================================
-- Résumé métiers d'un joueur connu (roster CraftLink) — icônes INLINE + niveaux. Métiers PRIMAIRES
-- uniquement (cf. SECONDARY_PROF). Renvoie nil si le joueur n'a pas l'addon / aucun métier primaire connu.
-- =========================================================================
function Social:ProfSummary(name)
    if not (name and COC.Directory) then return nil end
    local r = COC.Directory.roster[name]
    if not r then return nil end
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
        if not SECONDARY_PROF[key] then parts[#parts + 1] = profMark(key) .. " " .. sv[1] .. "/" .. sv[2] end
    end
    -- Fallback : métiers connus via bitfield RK, sans niveau → icône seule.
    if #parts == 0 then
        for key in pairs(r.recipes or {}) do
            if not SECONDARY_PROF[key] then parts[#parts + 1] = profMark(key) end
        end
    end
    -- Dernier recours : non-porteur d'addon VU crafter (CHAT_MSG_LOOT) → plancher de skill « N+ ».
    if #parts == 0 then
        for key, floor in pairs(r.craftSeen or {}) do
            if not SECONDARY_PROF[key] then
                parts[#parts + 1] = profMark(key) .. ((floor and floor > 0) and (" " .. floor .. "+") or "")
            end
        end
    end
    if #parts == 0 then return nil end
    table.sort(parts)
    local rep = (r.rep and r.rep > 0) and ("  |cFFE8B84B" .. string.format(COC.L["%d livrés"], r.rep) .. "|r") or ""
    return table.concat(parts, "   ") .. rep
end

-- =========================================================================
-- Tooltip MONDE (unité). Migré de OnTooltipSetUnit (mort depuis le refactor tooltip de Classic Era)
-- vers TooltipDataProcessor.AddTooltipPostCall ; repli sur l'ancien script hook pour un vieux client.
-- =========================================================================
local function OnUnitTooltip(tooltip)
    if tooltip ~= GameTooltip or tooltip._cocProfAdded then return end   -- _cocProfAdded : anti-doublon (2 chemins)
    local _, unit = tooltip:GetUnit()
    if not unit then return end
    local name = UnitName(unit)
    local summary = name and Social:ProfSummary(name)
    if not summary then return end
    local sk = GetSkin()
    -- Marque addon = icône WorkOrder (le glyphe « ✓ » s'affichait en tofu dans la police WoW).
    local mark = sk and ("  |T" .. sk.tex.workorder .. ":14:14:0:0|t") or ""
    tooltip:AddLine("|cFF33DD88CO-Classic|r" .. mark .. "  " .. summary, 1, 1, 1)
    tooltip._cocProfAdded = true
    tooltip:Show()
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
    -- pcall : un pépin dans un hook social ne doit JAMAIS avorter la chaîne PLAYER_LOGIN qui suit
    -- (BuildMinimapButton, Inbound, slash…). L'erreur est mémorisée (/co socialdiag) et remontée.
    local ok, err = pcall(function()
        -- Tooltip MONDE : OnTooltipSetUnit fonctionne en Classic Era (l'API tooltip n'a PAS été
        -- neutralisée comme le menu) → chemin ÉPROUVÉ, on le garde en primaire. On enregistre AUSSI
        -- l'API moderne en repli ; _cocProfAdded (remis à zéro sur OnTooltipCleared) évite le doublon.
        if GameTooltip and GameTooltip.HookScript then
            GameTooltip:HookScript("OnTooltipSetUnit", OnUnitTooltip)
            GameTooltip:HookScript("OnTooltipCleared", function(tt) tt._cocProfAdded = nil end)
        end
        if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
            and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnUnitTooltip)
        end
        if Social.InstallMenus  then Social:InstallMenus()  end   -- _Social_Menu.lua (menu clic-droit)
        if Social.WireRosterUI  then Social:WireRosterUI()  end   -- _Social_Roster.lua (tooltip ami + guilde)
        Social:_WireDiscovery()
    end)
    if not ok then
        self._startError = err
        if geterrorhandler then geterrorhandler()(err) end
    end
end

-- Diagnostic (/co socialdiag [nom]) : état des hooks + données roster de la cible → pour comprendre
-- pourquoi un tooltip reste vide (souvent : le joueur n'a pas de métier PRIMAIRE, ou pas encore découvert).
function Social:Diag(name)
    local out = function(s) DEFAULT_CHAT_FRAME:AddMessage("|cFF33DD88[CO diag]|r " .. s) end
    if not (name and name ~= "") then
        if UnitIsPlayer and UnitIsPlayer("target") then name = UnitName("target")
        elseif UnitIsPlayer and UnitIsPlayer("mouseover") then name = UnitName("mouseover") end
    end
    out("Start: " .. (self._startError and ("|cFFFF4444ERREUR|r " .. tostring(self._startError)) or "|cFF33DD33ok|r"))
    out(("UIPanels_Game=%s · FriendsFrameTooltip_Show=%s · GuildStatus_Update=%s"):format(
        tostring(C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Blizzard_UIPanels_Game")),
        type(FriendsFrameTooltip_Show), type(GuildStatus_Update)))
    out(("hooks: ami=%s guilde=%s menu=%s"):format(
        tostring(self._friendHooked), tostring(self._guildHooked), tostring(self._menuHooked)))
    if not (name and name ~= "") then out("aucune cible — cible un joueur ou /co socialdiag <nom>"); return end
    local r = COC.Directory and COC.Directory.roster and COC.Directory.roster[name]
    out("cible=|cFFFFFFFF" .. name .. "|r roster=" .. (r and "|cFF33DD33oui|r" or "|cFFFF4444non|r"))
    if r then
        local sk = {}; for k, v in pairs(r.skill or {}) do sk[#sk+1] = k .. " " .. tostring(v[1]) .. "/" .. tostring(v[2]) end
        local rk = {}; for k in pairs(r.recipes or {}) do rk[#rk+1] = k end
        out("  skill: " .. (next(sk) and table.concat(sk, ", ") or "(vide)"))
        out("  recipes: " .. (next(rk) and table.concat(rk, ", ") or "(vide)"))
    end
    out("  ProfSummary=" .. (self:ProfSummary(name) or "|cFFFF4444nil|r (rien à afficher)"))
end
