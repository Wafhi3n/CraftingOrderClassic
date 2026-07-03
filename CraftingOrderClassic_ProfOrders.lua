-- CraftingOrderClassic_ProfOrders.lua — COORDINATEUR d'événements de la fenêtre métier.
-- La vue métier custom (3 colonnes, _ProfWindow*) est désormais la vue PAR DÉFAUT (maquette
-- designer) : ce module ne rend plus d'overlay flottant. Il route les events TRADE_SKILL_* /
-- CRAFT_* vers COC.ProfWindow (neutralise le natif, ouvre / rafraîchit / ferme notre fenêtre).
-- « Vue Blizzard » (PW:IsEnabled()==false) → on laisse la fenêtre native, on ne fait rien.

local COC = CraftingOrderClassic
local ProfOrders = {}
COC.ProfOrders = ProfOrders

-- Mutex métier : on a détaché les frames natives de UIPanelWindows → on refait la fermeture mutuelle
-- à la main (un seul métier ouvert à la fois). Renvoie true si on a fermé l'AUTRE métier.
local function closeOtherProfession(event)
    if event:find("^CRAFT") then
        if _G.TradeSkillFrame and TradeSkillFrame:IsShown() and CloseTradeSkill then CloseTradeSkill(); return true end
    elseif _G.CraftFrame and CraftFrame:IsShown() and CloseCraft then CloseCraft(); return true end
    return false
end

-- SHOW : neutralise le natif (zéro flash), ferme l'autre métier, ouvre notre fenêtre custom.
function ProfOrders:_OnShow(PW, event)
    local switched = closeOtherProfession(event)
    PW:NeutralizeNative()
    if switched and C_Timer then C_Timer.After(0.1, function() PW:OnProfessionShow() end)
    else PW:OnProfessionShow() end
end

-- Combat : la fenêtre métier custom ne se ferme pas au clic en combat (le natif est protégé) → on la
-- referme AUTOMATIQUEMENT à l'entrée en combat. On masque notre frame (toujours autorisé) et on tente
-- de fermer la session native. La garde InCombatLockdown de OnProfessionShow empêche toute
-- ré-ouverture intempestive tant que le combat dure.
function ProfOrders:_OnCombat()
    local PW = COC.ProfWindow
    if not (PW and PW.frame and PW.frame:IsShown()) then return end
    if PW.docked then PW:CloseDock(); return end   -- Vue Blizzard : on masque NOTRE colonne, la native reste intacte
    PW:Hide()                                      -- Vue custom : on ferme aussi la session native (fenêtre neutralisée)
    if COC.Craft and COC.Craft:IsCraftOpen() then if CloseCraft then CloseCraft() end
    elseif CloseTradeSkill then CloseTradeSkill() end
end

function ProfOrders:Start()
    if not COC.db then return end
    local f = CreateFrame("Frame")
    for _, ev in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_UPDATE", "TRADE_SKILL_CLOSE",
                          "CRAFT_SHOW", "CRAFT_UPDATE", "CRAFT_CLOSE", "PLAYER_REGEN_DISABLED" }) do f:RegisterEvent(ev) end
    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then ProfOrders:_OnCombat(); return end
        local PW = COC.ProfWindow; if not PW then return end
        local craftEv = event:find("^CRAFT")
        local nativeFrame = craftEv and _G.CraftFrame or _G.TradeSkillFrame
        -- Skill-up / plan appris : recapture mon niveau + ré-annonce (les autres voient mon skill).
        if event:find("UPDATE$") and COC.Directory then
            COC.Directory:CaptureSkills(); COC.Directory:AnnounceThrottled()
        end
        if PW:IsEnabled() then                          -- VUE CUSTOM (3 colonnes, native neutralisée)
            if event:find("UPDATE$") then
                if PW.frame and PW.frame:IsShown() then PW:Refresh() else PW:OnProfessionShow() end
            elseif event:find("SHOW$") then ProfOrders:_OnShow(PW, event)
            elseif COC.Craft and COC.Craft:GetOpenProfessionInfo() then PW:OnProfessionShow()  -- autre métier ouvert
            else PW:OnProfessionClose() end
        else                                            -- VUE BLIZZARD (native intacte + dock Commandes à droite)
            if event:find("SHOW$") then
                PW:EnsureNativeToggle(nativeFrame, craftEv and "craft" or "trade")
                if not (InCombatLockdown and InCombatLockdown()) then PW:OpenDock(nativeFrame) end
            elseif event:find("UPDATE$") then
                if PW.docked then PW:Refresh() end
            else                                        -- *_CLOSE
                if PW.CloseDock then PW:CloseDock() end
            end
        end
    end)
end
