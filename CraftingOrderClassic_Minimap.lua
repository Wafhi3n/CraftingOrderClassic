-- CraftingOrderClassic_Minimap.lua — bouton minimap (toggle du carnet). Icône native WorkOrder.
-- Position persistée en angle (COC.db.minimapAngle). Glisser = repositionner autour de la minimap.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

-- Rayon de la couronne où se pose le bouton. Le 80 d'origine était la minimap de Classic Era
-- (140 px de large, donc 70 de rayon) plus 10 px de marge. Sur WoW: Forever la minimap est plus
-- grande : un rayon FIXE de 80 repose le bouton À L'INTÉRIEUR du disque, sous l'habillage de la
-- minimap — c'est le « bouton passé derrière » observé le 2026-09-19. On le MESURE donc au lieu de
-- le supposer ; sur Era le calcul redonne exactement 80, rien n'y bouge.
local RADIUS_FALLBACK = 80
local function ringRadius()
    local w = Minimap and Minimap.GetWidth and Minimap:GetWidth()
    if not w or w <= 0 then return RADIUS_FALLBACK end   -- minimap pas encore dimensionnée
    return w / 2 + 10
end

-- Sur WoW: Forever la fenêtre de métier NATIVE a déjà un onglet par métier et une page d'ensemble
-- (« Professions ») : notre menu « Mes métiers » y faisait doublon. Le clic droit y devient donc un
-- RACCOURCI vers cette page, par un appel DIRECT à `ToggleProfessionsBook()`.
--
-- On est passé par deux impasses avant, les deux consignées ici pour ne pas y revenir :
--   1. `CastSpellByName` sur le sort de métier — PROTÉGÉ, bloqué en jeu le 2026-09-19.
--   2. Un bouton SÉCURISÉ transférant le clic au micro-bouton « Métiers » de Blizzard
--      (`type2="click"` + `clickbutton2`) — le clic droit ne faisait RIEN, sans erreur.
-- La 2e était inutile depuis le début : `ToggleProfessionsBook` (Blizzard_ProfessionsBook_Bootstrap.lua)
-- n'est pas protégée. Elle charge l'addon de la fenêtre puis appelle `ToggleFrame` — rien d'autre.
-- Le micro-bouton de Blizzard ne fait littéralement QUE l'appeler (`ProfessionMicroButtonMixin:OnClick`),
-- donc lui transférer un clic était un détour pour arriver au même endroit — et un détour fragile :
-- sur Camelot ce micro-bouton peut être DÉSACTIVÉ par règle de jeu (`ProfessionsPanelDisabled`), et
-- un bouton désactivé ne reçoit pas le clic transféré.
-- Ce que l'appel direct nous rend au passage : le bouton minimap n'est plus PROTÉGÉ — donc plus de
-- restriction de déplacement en combat, et plus de frame protégée greffée sous Minimap (dont la
-- seule présence gênerait un Hide de la minimap en combat, cf. wow-protected-frame-hide-combat).
-- Ce qui reste vrai et protégé : les sorts des onglets latéraux DANS la fenêtre (CastProfessionSpell).

-- Scripts du bouton : glisser (repositionner autour de la minimap), clics, infobulle.
-- Séparé de la construction pour tenir sous le plafond anti-monolithe (60 l/fonction).
local function wireScripts(b, place)
    b:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local scale  = Minimap:GetEffectiveScale()
            local px, py = GetCursorPosition()
            local angle  = atan2(py / scale - my, px / scale - mx)
            place(angle); if COC.db then COC.db.minimapAngle = angle end
        end)
    end)
    b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    b:SetScript("OnClick", function(_, btn)
        if btn ~= "RightButton" then UI:Toggle("post"); return end   -- clic gauche = toujours l'onglet Commande
        if COC.Api.IS_MAINLINE then
            if _G.ToggleProfessionsBook then _G.ToggleProfessionsBook() end   -- non protégée, cf. en-tête
        else
            UI:ToggleProfMenu()
        end
    end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cFF33DD88Crafting Order|r — Classic")
        GameTooltip:AddLine(L["Clic : ouvrir les commandes"], 1, 1, 1)
        GameTooltip:AddLine(COC.Api.IS_MAINLINE and L["Clic droit : fenêtre des métiers"]
            or L["Clic droit : mes métiers"], 0.6, 1, 0.6)
        if UI._updateVer then
            GameTooltip:AddLine(string.format(L["Nouvelle version disponible : %s"], UI._updateVer), 1, 0.82, 0)
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function UI:BuildMinimapButton()
    if self.minimapBtn or not Minimap then return end
    local b = CreateFrame("Button", "CraftingOrderMinimapButton", Minimap)
    b:SetSize(31, 31); b:SetFrameStrata("MEDIUM"); b:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")

    local icon = b:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20); icon:SetPoint("CENTER", 0, 1); icon:SetTexture(Skin.tex.workorder)

    local overlay = b:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53); overlay:SetPoint("TOPLEFT")
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    -- Pastille « nouvelle version dispo » (masquée par défaut ; pilotée par Directory_Version via SetUpdateBadge).
    local badge = b:CreateTexture(nil, "OVERLAY")
    badge:SetSize(12, 12); badge:SetPoint("TOPRIGHT", -2, -2); badge:SetTexture(Skin.tex.dotRed)
    badge:Hide()
    self.updateBadge = badge

    local function place(angle)
        local r = ringRadius()   -- relu à chaque pose : la minimap peut être redimensionnée (Edit Mode)
        b:SetPoint("CENTER", Minimap, "CENTER", r * cos(angle), r * sin(angle))
    end
    place((COC.db and COC.db.minimapAngle) or 210)

    wireScripts(b, place)
    self.minimapBtn = b
    if self._updateVer then self:SetUpdateBadge(true, self._updateVer) end   -- état demandé avant la création du bouton
end

-- Allume/éteint la pastille « nouvelle version » du bouton minimap (appelée par Directory_Version).
-- Sûre AVANT la création du bouton : on mémorise l'état voulu, réappliqué en fin de BuildMinimapButton.
function UI:SetUpdateBadge(shown, ver)
    self._updateVer = shown and ver or nil
    if self.updateBadge then self.updateBadge:SetShown(shown and true or false) end
end

-- ------------------------------------------------------------------
-- Menu « mes métiers » (clic droit minimap) : ouvre la vue commandes d'un métier (craft OU récolte,
-- qui n'a pas de fenêtre en jeu). Liste MES métiers depuis l'annuaire (Directory.mySkills).
-- ------------------------------------------------------------------
function UI:_BuildProfMenu()
    local m = Skin.MakeFlyout("CraftingOrderProfMenu", 184, { rowW = 164 })
    m.title = m:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    m.title:SetPoint("TOPLEFT", 10, -8); Skin.ApplyShadow(m.title)
    self.profMenu = m
    return m
end

-- Ligne du pool du kit + icône de métier (fillMenuRow ré-ancre .text et repositionne selon le cas).
function UI:_ProfMenuRow(m, i)
    local r = m:Row(i)
    if not r.ic then
        r.ic = r:CreateTexture(nil, "OVERLAY"); r.ic:SetSize(16, 16); r.ic:SetPoint("LEFT", 5, 0)
    end
    return r
end

-- Configure une ligne du pool : header de section (doré, sans icône, non cliquable) ou entrée
-- cliquable (icône + libellé + OnClick). Recycle proprement l'état entre ouvertures.
local function fillMenuRow(r, y, opts)
    r:ClearAllPoints(); r:SetPoint("TOPLEFT", 10, y)
    if opts.header then
        r.ic:Hide(); r.text:ClearAllPoints(); r.text:SetPoint("LEFT", 10, 0)
        r:SetText("|cFF888888" .. opts.label .. "|r"); r:SetScript("OnClick", nil); r:Disable()
    else
        r.ic:Show(); r.ic:SetTexture(opts.icon); r.text:ClearAllPoints(); r.text:SetPoint("LEFT", 26, 0)
        r:SetText(opts.label); r:SetScript("OnClick", opts.onClick); r:Enable()
    end
    r:Show()
end

function UI:ToggleProfMenu()
    local m = self.profMenu or self:_BuildProfMenu()
    if m:IsShown() then m:Hide(); return end
    local D = COC.Directory
    local keys = {}
    for k in pairs((D and D.mySkills) or {}) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return Skin.ProfLabel(a) < Skin.ProfLabel(b) end)
    local any = #keys > 0
    m.title:SetText(any and ("|cFFE8B84B" .. L["Mes métiers"] .. "|r") or ("|cFF888888" .. L["Aucun métier connu."] .. "|r"))
    local y, i = -26, 0
    for _, key in ipairs(keys) do
        i = i + 1
        fillMenuRow(self:_ProfMenuRow(m, i), y, { icon = Skin.ProfIcon(key) or Skin.tex.unknown, label = Skin.ProfLabel(key),
            onClick = function() m:Hide(); if COC.ProfWindow then COC.ProfWindow:OpenFor(key) end end })
        y = y - 22
    end
    -- Les REROLLS (métiers des autres persos du compte) ne sont plus listés ici : leur vue vit
    -- maintenant dans l'onglet « Mes artisans », qui agrège déjà les métiers du compte et sait QUI
    -- les porte (clic droit sur un métier). Ce menu ne parle plus que du perso connecté.
    m:SetCount(i)
    m:SetWidth(184)
    m:SetHeight(math.max(-y + 6, 40))                 -- hauteur custom (titre + sections) : écrase SetCount
    -- Le menu s'ouvre DU CÔTÉ OÙ IL Y A LA PLACE. Il était ancré en dur « TOPRIGHT sur BOTTOMLEFT »,
    -- c'est-à-dire toujours vers la GAUCHE et vers le BAS du bouton : parfait pour une minimap en
    -- haut à droite (le cas par défaut), mais elle sort entièrement de l'écran dès que la minimap
    -- est déplacée à gauche ou en bas. Le menu s'ouvrait alors POUR DE VRAI, hors champ, et le clic
    -- suivant le refermait — vu de l'utilisateur, « le clic droit ne fait rien ».
    -- Repère WoW : origine en BAS à gauche, donc un bouton HAUT d'écran a un y GRAND.
    -- En haut à droite, le calcul redonne exactement l'ancrage d'avant.
    local anchor = self.minimapBtn or Minimap
    local cx, cy = anchor:GetCenter()
    local toLeft = (cx or 0) < (UIParent:GetWidth() / 2)    -- bouton à gauche  → dérouler vers la DROITE
    local toDown = (cy or 0) > (UIParent:GetHeight() / 2)   -- bouton en haut   → dérouler vers le BAS
    m:ToggleAt((toDown and "TOP" or "BOTTOM") .. (toLeft and "LEFT" or "RIGHT"), anchor,
               (toDown and "BOTTOM" or "TOP") .. (toLeft and "RIGHT" or "LEFT"), 0, 0)
end
