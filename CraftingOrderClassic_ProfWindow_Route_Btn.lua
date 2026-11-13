-- CraftingOrderClassic_ProfWindow_Route_Btn.lua — l'ENTRÉE du Plan de route : le bouton « carte » de
-- la barre d'outils Recettes, l'ouverture de la fenêtre flottante, et le suivi live (la route se
-- re-remplit à chaque refresh de la liste, et tout de suite quand le métier ou le rang change).
--
-- Sorti de _ProfWindow_Route.lua le 2026-11-13, tel quel : le fichier touchait les 500 lignes, le
-- plafond anti-monolithe, et la marque des writs (_Route_Writs) y ajoutait encore. La couture suit
-- le contenu : là-bas on CALCULE et PEINT la route, ici on l'ouvre et on la tient à jour. Chargé après
-- lui (.toc) ; appelé par _ProfWindow_Toolbar (sous garde nil) et _ProfWindow_DockViews.

local COC = CraftingOrderClassic
local PW  = COC.ProfWindow
local L   = COC.L

-- Ouvre/ferme le panneau (bouton carte de la barre d'outils Recettes). Sans Auctionator : popup
-- d'incitation (même pattern que les toggles de tri).
function PW:ToggleRoute()
    local PR = COC.Profit
    if not (PR and PR:IsAvailable()) then COC:NeedPriceAddon(); return end
    local f = self.routeWin or self:_BuildRouteWin()
    if f:IsShown() then f:Hide() else self:_FillRoute(); f:Show() end
    self:_SyncRouteBtn()
end

-- Bouton « carte » dans le slot recTools (construit par _BuildRecipeTools sous garde nil).
function PW:_BuildRouteBtn(tz)
    local b = self:_MakeToolBtn(tz, function()
        return L["Plan de route : quoi crafter pour monter au moins cher."]
    end, function() PW:ToggleRoute() end)
    b:SetPoint("LEFT", 68, 0)
    local map = b:CreateTexture(nil, "ARTWORK")
    map:SetTexture("Interface\\Icons\\INV_Misc_Map_01"); map:SetSize(15, 15)
    map:SetTexCoord(0.07, 0.93, 0.07, 0.93); map:SetPoint("CENTER"); b.map = map
    self.recRouteBtn = b
end

-- État du bouton (appelé par _SyncSortHeader à chaque refresh) : masqué en reroll ; coloré si Lazy
-- Gold absent (incite au clic → popup) ou panneau ouvert, grisé sinon. Fenêtre ouverte : re-remplit
-- à chaque refresh de la liste (throttle 1 s) — même cadence que le badge « meilleur coût/point »,
-- pour que la route suive AUSSI les prix Auctionator (vécu 2026-07-18 : route figée sur d'anciens prix
-- ≠ badge recalculé → les deux guides se contredisaient) ; immédiat si métier ou rang a changé.
function PW:_SyncRouteBtn()
    local b = self.recRouteBtn
    if b then
        local show = not self.rerollKey
        b:SetShown(show and true or false)
        local ok = COC.Profit and COC.Profit:IsAvailable()
        local active = (self.routeWin and self.routeWin:IsShown()) and true or false
        if b.onBG then b.onBG:SetShown(active) end
        if b.map then b.map:SetDesaturated((ok and not active) and true or false) end
    end
    -- Suivi live : la FENÊTRE si elle est ouverte, sinon le PANNEAU de colonne s'il porte la route.
    local f = self:_RouteTarget()
    if f and f:IsShown() then
        local rank = COC.Craft and COC.Craft:OpenRank()
        local fresh = ((GetTime and GetTime() or 0) - (self._routeAt or 0)) < 1
        if self._routeProf ~= self.profKey or (rank and rank ~= self._routeRank) or not fresh then
            self:_FillRoute()
        end
    end
end
