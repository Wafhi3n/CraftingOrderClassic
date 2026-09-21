-- CraftingOrderClassic_ProfOrders.lua — COORDINATEUR d'événements de la fenêtre métier.
-- La vue métier custom (3 colonnes, _ProfWindow*) est désormais la vue PAR DÉFAUT (maquette
-- designer) : ce module ne rend plus d'overlay flottant. Il route les events TRADE_SKILL_*
-- vers COC.ProfWindow (neutralise le natif, ouvre / rafraîchit / ferme notre fenêtre).
-- Les CRAFT_* (API Craft de l'Era) ont disparu avec elle.
-- « Vue Blizzard » (PW:IsEnabled()==false) → on laisse la fenêtre native, on ne fait rien.

local COC = CraftingOrderClassic
local ProfOrders = {}
COC.ProfOrders = ProfOrders

-- SHOW : neutralise le natif (zéro flash), ouvre notre fenêtre custom. Le mutex métier qui vivait
-- ici (une fenêtre TradeSkill et une fenêtre Craft pouvaient coexister une fois détachées de
-- UIPanelWindows) n'a plus d'objet : il n'y a plus qu'une fenêtre de métier.
-- REPLI COMBAT : la fenêtre custom est protégée (interdite d'ouverture en combat, OnProfessionShow
-- return alors sans rien afficher). Si on neutralisait quand même le natif, on finirait sur un écran
-- VIDE (native masquée + custom non ouverte). En combat on laisse donc la fenêtre Blizzard native
-- s'afficher telle quelle — repli natif. Sortie de combat → la prochaine ouverture rendra la custom.
function ProfOrders:_OnShow(PW, event)
    if InCombatLockdown and InCombatLockdown() then return end   -- repli natif : ne pas museler la fenêtre Blizzard
    PW:NeutralizeNative()
    PW:OnProfessionShow()
end

-- Combat : la fenêtre métier custom ne se ferme pas au clic en combat (le natif est protégé) → on la
-- referme AUTOMATIQUEMENT à l'entrée en combat. PW:Hide escamote notre frame (Hide direct bloqué en
-- combat par le bouton « Créer » sécurisé affiché) et on tente de fermer la session native. La garde
-- InCombatLockdown de OnProfessionShow empêche toute ré-ouverture intempestive tant que le combat dure.
-- Sur FOREVER, la fenêtre de métier est pilotée par la GREFFE (OnShow/OnHide de ProfessionsFrame,
-- cf. _ProfWindow_Camelot) : ce pilote-ci est celui de l'Era, et deux pilotes pour une même fenêtre
-- se marchent dessus. Concrètement, `TRADE_SKILL_CLOSE` — émis AUSSI quand on change d'onglet dans
-- la fenêtre native — appelait CloseDock() et refermait la colonne que la greffe venait d'ouvrir :
-- cadre élargi, colonne absente, sur les trois onglets (relevé en jeu le 2026-09-19). La greffe est
-- seule maîtresse à bord dès qu'elle est là.
local function graftOwnsWindow() return COC.ProfWindow and COC.ProfWindow.CamelotAttach ~= nil end

function ProfOrders:_OnCombat()
    if graftOwnsWindow() then return end   -- greffée, la colonne est PROTÉGÉE : on n'y touche pas en combat
    local PW = COC.ProfWindow
    if not (PW and PW.frame and PW.frame:IsShown()) then return end
    if PW.docked then PW:CloseDock(); return end   -- Vue Blizzard : on masque NOTRE colonne, la native reste intacte
    PW:Hide()                                      -- Vue custom : on ferme aussi la session native (fenêtre neutralisée)
    COC.Api.CloseProfession()                      -- la disjonction Craft/TradeSkill/C_TradeSkillUI vit dans le Compat
end

function ProfOrders:Start()
    if not COC.db then return end
    local f = CreateFrame("Frame")
    -- Les événements de métier Classic n'existent pas sur un client MAINLINE (Forever) et
    -- RegisterEvent lève sur un inconnu → enregistrement gardé (cf. COC.Api.RegisterEventsSafe).
    COC.Api.RegisterEventsSafe(f, { "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_CLOSE",
                                    "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" })
    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then ProfOrders:_OnCombat(); return end
        -- Fin de combat : on rejoue tout masquage de fenêtre différé (Hide protégé pendant le combat).
        if event == "PLAYER_REGEN_ENABLED" then
            local PW = COC.ProfWindow; if PW and PW._hidePending then PW:Hide() end; return
        end
        local PW = COC.ProfWindow; if not PW then return end
        local nativeFrame = _G.TradeSkillFrame
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
        elseif graftOwnsWindow() then return             -- FOREVER : la greffe pilote, cf. en-tête
        else                                            -- VUE BLIZZARD (native intacte + dock Commandes à droite)
            if event:find("SHOW$") then
                PW:EnsureNativeToggle(nativeFrame, "trade")
                if not (InCombatLockdown and InCombatLockdown()) then PW:OpenDock(nativeFrame) end
            elseif event:find("UPDATE$") then
                if PW.docked then PW:Refresh() end
            else                                        -- *_CLOSE
                if PW.CloseDock then PW:CloseDock() end
            end
        end
    end)
end
