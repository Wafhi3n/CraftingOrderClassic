-- CraftingOrderClassic_ProfWindow_Dock.lua — mode DOCK de la vue métier (« Vue Blizzard ») :
-- la fenêtre native reste VISIBLE (non neutralisée) et NOTRE colonne Commandes s'épingle à sa
-- droite. S'exclut de la vue custom 3 colonnes (custom = native neutralisée + 3 colonnes ; dock =
-- native intacte + colonne seule) → jamais les deux à la fois. Extrait de _ProfWindow.lua
-- (anti-monolithe) ; chargé APRÈS lui (PW existe).

local COC  = CraftingOrderClassic
local PW   = COC.ProfWindow
local Skin = COC.UI.Skin
local L    = COC.L

-- Bouton de retour sur la fenêtre NATIVE (vue Blizzard) : pose un petit bouton doré sur
-- TradeSkillFrame / CraftFrame pour rebasculer vers la vue custom sans passer par /co profwindow.
function PW:EnsureNativeToggle(frame, key)
    if not frame then return end
    self._nativeToggle = self._nativeToggle or {}
    if self._nativeToggle[key] then return end
    local btn = Skin.MakeGoldButton(frame, 150, 20, L["» Vue Crafting Order"])
    btn:SetPoint("TOPRIGHT", -66, -8)
    btn:SetScript("OnClick", function() PW:SetEnabled(true) end)
    self._nativeToggle[key] = btn
end

-- Épingle la colonne Commandes (layout compact de _ProfWindow_Orders, réutilisé tel quel) à droite
-- de la fenêtre native — le « panneau de commande » demandé.
function PW:OpenDock(nativeFrame)
    if not nativeFrame then return end
    self:Build()
    self.docked = true
    self.standaloneKey = nil
    self.rerollKey = nil                -- défense en profondeur : docké natif ≠ vue reroll
    self._compact = nil                 -- force _ApplyMode à recalculer au retour en vue custom
    self:_ApplyMode(true)               -- colonne Commandes seule (réutilise le layout compact)
    if self.vanillaBtn then self.vanillaBtn:Hide() end   -- « Vue Blizzard » redondant : on Y est déjà
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", nativeFrame, "TOPRIGHT", 6, 0)
    self.frame:Show()
    self:Refresh()
end

function PW:CloseDock()
    if not self.docked then return end
    self.docked = false
    if self.vanillaBtn then self.vanillaBtn:Show() end
    self:Hide()
end

-- Replace la fenêtre custom à sa position mémorisée (drag) ou au centre après un passage en dock
-- (qui l'avait épinglée à la native).
function PW:_RestorePlacement()
    if not self.frame then return end
    self.frame:ClearAllPoints()
    local pos = COC.db and COC.db.profWinPos
    if pos then self.frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else self.frame:SetPoint("CENTER") end
end

-- Refresh en mode dock : on ne touche NI aux recettes NI au détail (la native s'en charge), juste le
-- titre/rang + la colonne Commandes. Native fermée entre-temps → on retire le dock.
function PW:_RefreshDock()
    local craft = COC.Craft
    local name = craft and craft:GetOpenProfessionInfo()
    if not name then self:CloseDock(); return end
    self.profKey = craft:OpenProfessionKey()
    local rank, maxRank = craft:OpenRank()
    self:_SetTitle(name, (rank and maxRank) and string.format("|cFFE8B84B%d|r / %d", rank, maxRank) or nil)
    self:_SyncPortrait()
    self:_SyncLFWBtn()
    self:_SyncMissingBtn()
    if self.RefreshOrders then self:RefreshOrders() end
end
