-- CraftingOrderClassic_Writs_Seen.lua — QUAND COC relève ce qu'il voit des writs en jeu : une quête
-- de writ qu'on accepte, et celles déjà au journal à la connexion. Spec : docs/specs/writs-aca.md, D8.
--
-- La logique (quoi lire, quoi retenir) est dans CraftingOrderClassic_Writs.lua, `W:Learn`, testée
-- sans client. Ici, seulement les deux moments. Aucun cadre visible, aucune ligne de chat.

local COC = CraftingOrderClassic
local W = COC.Writs
if not (W and CreateFrame) then return end
local A = COC.Api

-- `QUEST_ACCEPTED` est SYNCHRONE (doc de l'interface de Forever) : l'objectif de la quête peut être
-- encore vide à cet instant. On relit un peu plus tard ; `Learn` ne retient rien d'un objectif vide.
local AFTER_ACCEPT = 1
-- À la connexion, le journal se remplit après l'écran de chargement.
local AFTER_LOGIN = 5

local function later(delay, fn)
    if C_Timer and C_Timer.After then C_Timer.After(delay, fn) else fn() end
end

local f = CreateFrame("Frame")
A.RegisterEventSafe(f, "QUEST_ACCEPTED")
A.RegisterEventSafe(f, "PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(self, event, a1, a2)
    if event == "QUEST_ACCEPTED" then
        -- Forever (Mainline) passe (questID) ; Classic passait (index, questID).
        local q = a2 or a1
        if W:ForQuest(q) then later(AFTER_ACCEPT, function() W:Learn(q) end) end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Une fois par session : les écrans de chargement suivants ne changent pas le journal.
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        later(AFTER_LOGIN, function() W:LearnHeld() end)
    end
end)
