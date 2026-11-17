-- CraftingOrderClassic_ProfWindow_DockTabs.lua — la RANGÉE DE LANGUETTES des vues de la colonne
-- (Commandes · Route · Manquantes · Profit) : sa construction, sa place, sa largeur, et la synchro
-- qui décide quand elle s'affiche. Extraite de _DockViews.lua (anti-monolithe, 2026-11-16) : la
-- bascule de vue et les panneaux restent là-bas. Ce bloc-ci a été choisi parce qu'AUCUNE branche en
-- cours ne le touche, alors que les branches du banc retouchent la vue « Manquantes » : déplacer le
-- code qu'elles éditent aurait rouvert un conflit à chaque refusion du banc.
--
-- ⚠️ LE COMBAT : mêmes règles que _DockViews (colonne greffée = protégée comme son hôte).

local COC  = CraftingOrderClassic
local PW   = COC.ProfWindow
local Skin = COC.UI.Skin
local L    = COC.L

local function lockedDown() return InCombatLockdown and InCombatLockdown() end

-- ------------------------------------------------------------------
-- Les deux boutons de l'en-tête
-- ------------------------------------------------------------------

-- Les vues, dans l'ordre de lecture. À languettes et pas à interrupteurs, et c'est le fond du
-- sujet : des états exclusifs dont un est TOUJOURS vrai ne se dessinent pas avec des bascules.
-- Deux icônes 16 px posées dans une bande vide se lisaient comme des boutons secondaires oubliés là,
-- et les désaturer pour dire « inactive » les faisait passer pour INDISPONIBLES (relevé sur capture
-- en jeu, 2026-09-19). Une languette sélectionnée dit la même chose sans ambiguïté, et c'est le
-- vocabulaire du jeu.
--
-- « Profit » est CONDITIONNELLE : sans oracle de prix il n'y a pas de rentabilité à trier, et une
-- languette qui n'ouvre qu'un message d'absence est un onglet vide. La règle vit déjà dans
-- PR:IsAvailable() — ici on ne fait que la consulter. Libellé court à dessein : la rangée est la
-- SEULE chose qui contraint encore la largeur de la colonne (sizeColumn prend le max), donc chaque
-- caractère de plus élargit la fenêtre native de Forever d'autant (arbitrage du user, 2026-09-21).
--
-- ⚠️ La languette « route » dit **Route**, pas « Plan de route » — et ce n'est pas une étourderie
-- à « corriger ». Un libellé de languette coûte de la LARGEUR À LA FENÊTRE, pas seulement de la
-- place dans la rangée : `sizeColumn` prend le max, et la fenêtre native s'élargit d'autant. Sur
-- le relevé du 2026-09-26 la rangée fait 213 px pour 8 px de marge, et un 5ᵉ onglet est spécifié
-- (Travail, cf. docs/specs/lfw-forever.md) — ce sont ces caractères-là qui lui font la place.
-- La VUE, elle, garde le mot entier dans son titre (`_ProfWindow_Route.lua`) : là il ne coûte rien.
local VIEWS = {
    { id = "orders", label = function() return L["Commandes"] end },
    { id = "route",  label = function() return L["Route"] end },
    { id = "learn",  label = function() return L["Manquantes"] end },
    { id = "profit", label = function() return L["Profit"] end,
      shown = function() return (COC.Profit and COC.Profit:IsAvailable()) and true or false end },
}

-- Construite par _BuildOrders (garde nil). Occupe la rangée du HAUT : les onglets de relation, eux,
-- descendent dans la vue Commandes à laquelle ils appartiennent (cf. _PlaceOrdTabs).
-- Une vue écartée ici n'est pas MASQUÉE, elle n'est pas CONSTRUITE : _ViewTabsWidth somme les
-- boutons qui existent, et un bouton caché lui ferait réserver une largeur que rien n'occupe.
function PW:_BuildDockViewBtns()
    if self.viewTabs then return end
    local defs = {}
    for _, v in ipairs(VIEWS) do
        if not v.shown or v.shown() then defs[#defs + 1] = { id = v.id, label = v.label() } end
    end
    self.viewTabs = Skin.MakeTabs(self.frame, defs, function(id)
        PW:_SetDockView(id ~= "orders" and id or nil)
    end, { tabX = self:_TabX(), tabY = self:_TabTop(),
           namePrefix = (self.frame:GetName() or "COCWin") .. "View" })
    self.viewTabs:Select("orders")
    self:_HideViewTabs()
end

-- Re-posée à chaque changement de mode (_ApplyMode, sizeColumn) : la bande d'en-tête se referme une
-- fois la colonne encastrée, et la rangée doit remonter avec elle. Seule la PREMIÈRE languette porte
-- une ancre — les suivantes s'enchaînent sur elle.
function PW:_PlaceViewTabs()
    local bar = self.viewTabs
    local first = bar and bar.buttons[VIEWS[1].id]
    if not first then return end
    first:ClearAllPoints()
    first:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self:_TabX(), self:_TabTop())
end

function PW:_HideViewTabs()
    for _, b in pairs((self.viewTabs and self.viewTabs.buttons) or {}) do b:Hide() end
end

-- Largeur RÉELLE de la rangée de vues, pour que la greffe dimensionne la colonne sur la PLUS LARGE
-- des deux rangées (cf. _ProfWindow_Camelot) : sinon la dernière languette se fait rogner par la
-- bordure, comme « Incoming » au premier essai du POC.
-- ⚠️ La marge GAUCHE n'est pas une constante : c'est `_TabX()`, donc elle grandit de la gouttière
-- du « i » une fois la colonne encastrée. Elle était forfaitisée dans un « + 20 » qui ne bougeait
-- pas — la colonne se dimensionnait alors sans savoir où la rangée commençait vraiment, et le
-- surplus qui restait à droite n'était pas une marge voulue mais un reste. On somme donc ce qu'on
-- pose réellement : gouttière + rangée + une marge droite explicite.
function PW:_ViewTabsWidth()
    local bar = self.viewTabs
    if not (bar and bar.buttons) then return 0 end
    local total, n = 0, 0
    for _, b in pairs(bar.buttons) do total = total + ((b.GetWidth and b:GetWidth()) or 0); n = n + 1 end
    if n == 0 then return 0 end
    return self:_TabX() + (total - 4 * (n - 1)) + 12
end

-- La rangée de vues n'existe que là où la colonne est SEULE et qu'un métier est ouvert : sans rang
-- courant il n'y a ni route à calculer ni manquantes à lister. Appelé par RefreshOrders, qui tourne
-- dans tous les modes.
function PW:_SyncDockViewBtns()
    local bar = self.viewTabs
    if not bar then return end
    -- Le mode Échange se redécide ICI, à chaque rafraîchissement de la colonne — et pas seulement
    -- sur les événements d'échange écoutés par _ProfWindow_Trade. Vécu en jeu le 2026-09-22 : la
    -- silhouette n'apparaissait qu'après un aller-retour sur un autre onglet, parce qu'aucun
    -- événement n'était retombé APRÈS que la colonne fut prête. Garde de ré-entrance : la bascule
    -- de vue repasse par RefreshOrders, donc par ici.
    if self._SyncTradeView and not self._inTradeSync then
        self._inTradeSync = true
        self:_SyncTradeView()
        self._inTradeSync = nil
    end
    -- ⚠️ LE MÉTIER PEUT CHANGER SOUS LA VUE. L'onglet natif passe de la Cuisine à l'Herboristerie,
    -- `_RefreshDock` met `profKey` à jour, et la vue affichée continue d'afficher la liste de
    -- l'ANCIEN métier -- que les infobulles interrogent alors avec la clé du NOUVEAU. On repeint sur
    -- le CHANGEMENT seulement : `RefreshOrders` tourne à chaque mouvement de commande, et refaire
    -- 128 lignes à chaque fois pour rien serait payer cher une bascule qui arrive une fois par heure.
    -- ⚠️ ET PAS EN COMBAT. Repeindre veut dire CRÉER et AFFICHER des lignes, et greffée la colonne
    -- est protégée comme son hôte : Show/SetPoint y sont refusés (cf. l'en-tête). Le témoin de
    -- métier reste donc EN RETARD exprès — c'est lui qui déclenchera le repaint à la première
    -- synchro hors combat. L'avancer sans repeindre figerait la vue sur l'ancien métier pour de bon.
    if self._dockViewProf ~= self.profKey and not lockedDown() then
        self._dockViewProf = self.profKey
        if self.dockView == "learn" then self:_FillDockMissing()
        elseif self.dockView == "route" then self:_FillRoute()
        elseif self.dockView == "profit" then self:_FillDockProfit() end
    end
    local craft = COC.Craft
    local show = (self._compact or self.docked) and self.profKey and not self.rerollKey
        and craft and craft:GetOpenProfessionInfo() ~= nil
    -- En mode Échange, la colonne ne montre QUE l'échange : ses onglets se taisent (spec
    -- enchant-echange-forever, décision du 2026-09-21).
    local trade = self.dockView == "trade"
    for _, b in pairs(bar.buttons) do b:SetShown((show and not trade) and true or false) end
    if not show then
        if self.dockView then self:_ResetDockView() end
        return
    end
    if trade then return end
    bar:Select(self.dockView or "orders")
    if self.dockView == "route" then self:_SyncRouteBtn() end
end
