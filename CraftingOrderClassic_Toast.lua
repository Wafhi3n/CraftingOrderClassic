-- CraftingOrderClassic_Toast.lua — UI:Toast, dans la pile de toasts du JEU.
--
-- Règle du user du 2026-10-11 (skill publique `chat-output`) : le chat ne répond qu'à un geste du
-- joueur ; ce qui arrive sans lui (commande reçue, demande lue dans le chat, suivi, nouvelle version,
-- plan ramassé) passe en toast. Et « si Blizzard a sa propre API pour les toasts, on doit
-- l'utiliser » : c'est la pile des hauts faits et du butin (AlertFrame), en bas de l'écran. Jusqu'à
-- la v1.49.0, UI:Toast posait son propre cadre en haut au centre, qui se remplaçait lui-même.
--
-- Mesures : TaintLab le 2026-10-11 (nos toasts en combat, un toast de Blizzard après le nôtre, aucun
-- blocage), puis LeyLines le même jour (vu en combat, deux toasts empilés l'un au-dessus de l'autre).
-- L'inscription se fait UNE fois, au PLAYER_LOGIN, hors combat comme aux deux mesures. Sans
-- AlertFrame (tests, autre client), un toast ne fait rien : pas de repli dans le chat.
local COC = CraftingOrderClassic
local UI = COC.UI

local Toast = {}
COC.Toast = Toast

local TITLE         = "Crafting Order"   -- le nom de l'addon, comme le préfixe du chat : pas traduit
local ICON          = "Interface\\AddOns\\CraftingOrderClassic\\Textures\\icon"
local SHOWN, QUEUED = 2, 6               -- toasts visibles à la fois, en attente derrière
-- La file de Blizzard EMPILE là où l'ancien cadre se remplaçait : cinq clics sur « Maximum 5
-- composants » donnaient cinq toasts. Le même texte dans ce délai ne se rempile pas.
local REPEAT = 5

local function SetUp(frame, text, icon)
    frame.Title:SetText(TITLE)
    frame.Text:SetText(text)
    frame.Icon:SetTexture(icon or ICON)
end

function Toast:Init()
    if self.system or not (AlertFrame and AlertFrame.AddQueuedAlertFrameSubSystem) then return end
    self.system = AlertFrame:AddQueuedAlertFrameSubSystem("CraftingOrderToastTemplate", SetUp, SHOWN, QUEUED)
end

-- Rend vrai si le toast s'affiche, attend son tour, ou vient d'être montré tel quel.
-- L'icône du gossip « commande » (Skin.tex.workorder, ~16 px) servait de marque de l'addon à
-- l'ancien cadre : à 40 px elle est floue, le logo de l'addon la remplace.
function UI:Toast(text, icon)
    local sys = Toast.system
    if not (sys and text) then return false end
    local now = (GetTime and GetTime()) or 0
    if Toast.last == text and now - (Toast.lastAt or 0) < REPEAT then return true end
    Toast.last, Toast.lastAt = text, now
    local Skin = self.Skin
    if Skin and Skin.tex and icon == Skin.tex.workorder then icon = nil end
    return sys:AddAlert(text, icon) and true or false
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function() Toast:Init() end)
