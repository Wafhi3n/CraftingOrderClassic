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

function ProfOrders:Start()
    if not COC.db then return end
    local f = CreateFrame("Frame")
    for _, ev in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_UPDATE", "TRADE_SKILL_CLOSE",
                          "CRAFT_SHOW", "CRAFT_UPDATE", "CRAFT_CLOSE" }) do f:RegisterEvent(ev) end
    f:SetScript("OnEvent", function(_, event)
        local PW = COC.ProfWindow
        local windowOn = PW and PW:IsEnabled()
        if event:find("UPDATE$") then
            -- Skill-up / plan appris : recapture mon niveau + ré-annonce (les autres voient mon skill).
            if COC.Directory then COC.Directory:CaptureSkills(); COC.Directory:AnnounceThrottled() end
            if windowOn and PW.frame and PW.frame:IsShown() then PW:Refresh()
            elseif windowOn then PW:OnProfessionShow() end
        elseif not windowOn then
            if PW and event:find("SHOW$") then       -- « Vue Blizzard » : pose le bouton de retour
                if event:find("^CRAFT") then PW:EnsureNativeToggle(_G.CraftFrame, "craft")
                else PW:EnsureNativeToggle(_G.TradeSkillFrame, "trade") end
            end
            return                                  -- on laisse la fenêtre native pour le reste
        elseif event:find("SHOW$") then
            ProfOrders:_OnShow(PW, event)
        else                                        -- *_CLOSE
            if COC.Craft and COC.Craft:GetOpenProfessionInfo() then PW:OnProfessionShow()  -- un autre métier reste ouvert
            else PW:OnProfessionClose() end
        end
    end)
end
