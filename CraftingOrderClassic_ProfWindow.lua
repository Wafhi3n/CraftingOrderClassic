-- CraftingOrderClassic_ProfWindow.lua — fenêtre métier custom 3 colonnes (migration depuis
-- Guild Economy) : Recettes | Détail+Craft | Commandes du métier. Remplace la fenêtre Blizzard
-- (neutralisée, jamais Hide() pour garder la session lisible). Colonnes dans _Recipes / _Detail ;
-- la colonne Commandes vit ici (réutilise le carnet/entrantes du métier ouvert).
--
-- Vue métier par DÉFAUT (maquette designer) : PW:IsEnabled() vrai sauf COC.db.profWindow == false.
-- `/co profwindow` bascule custom ↔ « Vue Blizzard » (opt-out). Quand la vue custom est active, désactive
-- le takeover de Guild Economy (TradeScannerDB.replaceProfWindow=false) → jamais deux fenêtres à la fois.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L
local PW   = {}
COC.ProfWindow = PW

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

PW.FRAME_W, PW.FRAME_H = 792, 500
PW.HEADER_H = 56
PW.COL_W = { 236, 252, 252 }
PW.GAP, PW.PAD = 10, 14

local GATHER = { Mining = true, Herbalism = true, Skinning = true, Fishing = true }

-- Sais-je honorer cette commande ? (récolte = j'ai le skill ; craft = je connais la recette)
function PW.CanFulfill(o)
    local prof = o.profession; if not prof then return nil end
    local c, D = CL(), COC.Directory
    if GATHER[prof] then return (D and D.mySkills and D.mySkills[prof]) ~= nil end
    if not c then return nil end
    if o.itemID  and c:IKnowRecipeForItem(prof, o.itemID)  then return true end
    if o.spellID and c:IKnowRecipeBySpell(prof, o.spellID) then return true end
    return false
end

-- ------------------------------------------------------------------
-- Neutralisation de la frame native (garde la session vivante)
-- ------------------------------------------------------------------
local NATIVE = {}
local uiPanelDetached = false
local function detachUIPanels()
    if uiPanelDetached then return end
    uiPanelDetached = true
    if _G.UIPanelWindows then UIPanelWindows["TradeSkillFrame"] = nil; UIPanelWindows["CraftFrame"] = nil end
end
local function neutralize(frame, key)
    if not frame then return end
    if not NATIVE[key] then NATIVE[key] = { alpha = frame:GetAlpha(), mouse = frame:IsMouseEnabled() } end
    frame:SetAlpha(0); frame:EnableMouse(false)
end
local function restore(frame, key)
    if not frame or not NATIVE[key] then return end
    frame:SetAlpha(NATIVE[key].alpha or 1); frame:EnableMouse(NATIVE[key].mouse ~= false); NATIVE[key] = nil
end
function PW:NeutralizeNative()
    detachUIPanels(); neutralize(_G.TradeSkillFrame, "trade"); neutralize(_G.CraftFrame, "craft")
end
function PW:RestoreNative() restore(_G.TradeSkillFrame, "trade"); restore(_G.CraftFrame, "craft") end

-- ------------------------------------------------------------------
-- Construction du shell
-- ------------------------------------------------------------------
function PW:_BuildHeader(f)
    local mark = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mark:SetPoint("TOPLEFT", 14, -12); mark:SetText("Crafting Order")
    mark:SetTextColor(Skin.unpack(Skin.color.goldOre)); Skin.ApplyShadow(mark)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12); title:SetTextColor(Skin.unpack(Skin.color.goldHi)); Skin.ApplyShadow(title)
    self.titleFS = title

    local rank = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rank:SetPoint("TOP", title, "BOTTOM", 0, -2); rank:SetTextColor(Skin.unpack(Skin.color.text))
    Skin.ApplyShadow(rank); self.rankFS = rank

    local vanilla = Skin.MakeGoldButton(f, 96, 20, L["Vue Blizzard"])
    vanilla:SetPoint("TOPRIGHT", -36, -12)
    vanilla:SetScript("OnClick", function() PW:SetEnabled(false) end)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)
    close:SetScript("OnClick", function()
        if COC.Craft and COC.Craft:IsCraftOpen() then if CloseCraft then CloseCraft() end
        elseif CloseTradeSkill then CloseTradeSkill() end
        PW:Hide()
    end)
    Skin.MakeSeparator(f, -(self.HEADER_H - 2))
end

function PW:_BuildColumn(f, width, leftAnchor)
    local col = CreateFrame("Frame", nil, f)
    col:SetWidth(width)
    -- y = -HEADER_H UNIQUEMENT pour la 1re colonne (ancrée à la frame, sous l'en-tête). Les colonnes
    -- suivantes s'ancrent au bord droit de la précédente (déjà sous l'en-tête) avec y = 0 : sinon
    -- chaque colonne descend d'un cran (effet « escalier » → la colonne Commandes finissait 2×HEADER_H
    -- trop bas, d'où l'impression de tailles différentes).
    col:SetPoint("TOPLEFT", leftAnchor.frame, leftAnchor.point, leftAnchor.x, leftAnchor.y or 0)
    col:SetPoint("BOTTOM", f, "BOTTOM", 0, self.PAD)
    if Skin.SkinWell then Skin.SkinWell(col) end
    return col
end

function PW:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", "CraftingOrderProfWindow", UIParent, "BackdropTemplate")
    f:SetSize(self.FRAME_W, self.FRAME_H)
    local pos = COC.db and COC.db.profWinPos               -- position persistée (drag) ou centre par défaut
    if pos then f:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else f:SetPoint("CENTER") end
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(fr)
        fr:StopMovingOrSizing()
        local p, _, rp, x, y = fr:GetPoint()
        if COC.db then COC.db.profWinPos = { p, rp, x, y } end
    end)
    f:SetClampedToScreen(true); f:SetFrameStrata("HIGH"); Skin.SkinFrameBackdrop(f); f:Hide()
    self.frame = f
    self:_BuildHeader(f)

    local recCol = self:_BuildColumn(f, self.COL_W[1], { frame = f,      point = "TOPLEFT",  x = self.PAD, y = -self.HEADER_H })
    local detCol = self:_BuildColumn(f, self.COL_W[2], { frame = recCol, point = "TOPRIGHT", x = self.GAP })
    local ordCol = self:_BuildColumn(f, self.COL_W[3], { frame = detCol, point = "TOPRIGHT", x = self.GAP })
    self.recCol, self.detCol, self.ordCol = recCol, detCol, ordCol

    if self._BuildRecipes then self:_BuildRecipes(recCol) end
    if self._BuildDetail  then self:_BuildDetail(detCol)  end
    if self._BuildOrders then self:_BuildOrders(ordCol) else self:_OrdersModuleMissing(ordCol) end
end

-- ------------------------------------------------------------------
-- Colonne DROITE : commandes du métier (cartes par demandeur + actions).
-- PW:_BuildOrders / _OrdCard / _FillCard / _CardActions / RefreshOrders sont définis dans
-- CraftingOrderClassic_ProfWindow_Orders.lua (chargé APRÈS ce fichier).
-- ------------------------------------------------------------------

-- Garde-fou : si ce fichier compagnon n'est pas chargé (cas typique = .lua ajouté au .toc et pas encore
-- pris en compte — WoW ne charge un fichier nouvellement listé qu'au prochain DÉMARRAGE COMPLET, pas sur
-- un simple /reload), on affiche un message dans la colonne et on prévient une fois, sans planter.
function PW:_OrdersModuleMissing(col)
    local fs = col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", 12, -12); fs:SetPoint("TOPRIGHT", -12, -12); fs:SetJustifyH("LEFT")
    fs:SetText("|cFFE8B84B" .. L["Commandes"] .. "|r\n\n|cFFFF7777"
        .. L["Module Commandes non chargé — redémarre complètement WoW (quitter/relancer), pas un simple /reload."] .. "|r")
    if not COC._ordersWarned then
        COC._ordersWarned = true
        print("|cFF33DD88Crafting Order|r |cFFFF7777"
            .. L["Module Commandes non chargé — redémarre complètement WoW (quitter/relancer), pas un simple /reload."] .. "|r")
    end
end

-- ------------------------------------------------------------------
-- Bouton de retour sur la fenêtre NATIVE (vue Blizzard) : pose un petit bouton doré sur
-- TradeSkillFrame / CraftFrame pour rebasculer vers la vue custom sans passer par /co profwindow.
-- ------------------------------------------------------------------
function PW:EnsureNativeToggle(frame, key)
    if not frame then return end
    self._nativeToggle = self._nativeToggle or {}
    if self._nativeToggle[key] then return end
    local btn = Skin.MakeGoldButton(frame, 150, 20, L["» Vue Crafting Order"])
    btn:SetPoint("TOPRIGHT", -66, -8)
    btn:SetScript("OnClick", function() PW:SetEnabled(true) end)
    self._nativeToggle[key] = btn
end

-- ------------------------------------------------------------------
-- Refresh global (coalescé)
-- ------------------------------------------------------------------
function PW:Hide() if self.frame then self.frame:Hide() end end

function PW:_DoRefresh()
    self._pending = false
    if not self.frame or not self.frame:IsShown() then return end
    local craft = COC.Craft
    local name = craft and craft:GetOpenProfessionInfo()
    if name then                                   -- mode PLEIN : fenêtre métier native ouverte
        self.profKey = craft:OpenProfessionKey()
        self.titleFS:SetText(name)
        local rank, maxRank = craft:OpenRank()
        self.rankFS:SetText((rank and maxRank) and string.format("|cFFE8B84B%d|r / %d", rank, maxRank) or "")
        self.recipes = craft:ReadRecipes() or {}
        self:_ApplyMode(false)
        if self.RefreshRecipes then self:RefreshRecipes() end
        if self.RefreshDetail  then self:RefreshDetail()  end
    elseif self.standaloneKey then                 -- mode COMPACT : ouvert par clé (récolte / menu minimap)
        self.profKey = self.standaloneKey
        self.titleFS:SetText(Skin.ProfLabel(self.profKey))
        local D = COC.Directory; local sk = D and D.mySkills and D.mySkills[self.profKey]
        self.rankFS:SetText(sk and string.format("|cFFE8B84B%d|r / %d", sk[1], sk[2]) or "")
        self:_ApplyMode(true)
    else
        return
    end
    if self.RefreshOrders then self:RefreshOrders() end
end

-- Bascule PLEIN (3 colonnes, fenêtre native) ↔ COMPACT (colonne Commandes seule, ouvert par clé).
function PW:_ApplyMode(compact)
    if self._compact == compact then return end
    self._compact = compact
    if self.recCol then self.recCol:SetShown(not compact) end
    if self.detCol then self.detCol:SetShown(not compact) end
    self.ordCol:ClearAllPoints()
    if compact then
        self.frame:SetWidth(300)
        self.ordCol:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.PAD, -self.HEADER_H)
        self.ordCol:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, self.PAD)
        self.ordCol:SetWidth(300 - 2 * self.PAD)
    else
        -- Même ancrage que _BuildColumn pour la colonne Commandes : sous l'en-tête, au bord droit de
        -- la colonne Détail (y = 0, PAS de double offset d'en-tête → fini l'escalier).
        self.frame:SetWidth(self.FRAME_W)
        self.ordCol:SetPoint("TOPLEFT", self.detCol, "TOPRIGHT", self.GAP, 0)
        self.ordCol:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, self.PAD)
        self.ordCol:SetWidth(self.COL_W[3])
    end
end

-- Ouvre la vue métier pour une CLÉ de métier (menu minimap / récolte / /co métier).
--  * Métier CRAFTABLE (a une vraie fenêtre en jeu) → on OUVRE la fenêtre native (cast du sort de
--    métier) : la vue PLEINE 3 colonnes se monte via OnProfessionShow, recettes lues en live. Repli
--    compact si la fenêtre ne s'ouvre pas (Secourisme, combat…).
--  * Métier de RÉCOLTE (pas de fenêtre) → vue COMPACTE autonome (colonne Commandes seule).
function PW:OpenFor(profKey)
    if not profKey then return end
    if not GATHER[profKey] then
        local craft = COC.Craft
        if craft and craft:GetOpenProfessionInfo() and craft:OpenProfessionKey() == profKey then
            self:OnProfessionShow(); return          -- déjà ouvert nativement → (ré)affiche la vue pleine
        end
        local spell = Skin.ProfLabel(profKey)
        if spell and spell ~= "" and spell ~= "—" and CastSpellByName then
            self.standaloneKey = nil
            CastSpellByName(spell)                    -- ouvre la fenêtre native → OnProfessionShow
            if C_Timer and C_Timer.After then
                C_Timer.After(0.4, function()
                    local c = COC.Craft
                    if not (c and c:GetOpenProfessionInfo()) then PW:_OpenCompact(profKey) end
                end)
            end
            return
        end
    end
    self:_OpenCompact(profKey)
end

-- Vue compacte autonome (colonne Commandes seule) : récolte, ou repli si la fenêtre native n'a pas pu
-- s'ouvrir pour un métier craftable. Si une AUTRE fenêtre native est déjà ouverte (ex. : Travail du
-- cuir ouvert pendant qu'on demande Dépeçage), on la ferme d'abord : TRADE_SKILL_CLOSE déclenche
-- OnProfessionClose, qui voit standaloneKey posé et RESTE VISIBLE en mode compact (au lieu de masquer).
function PW:_OpenCompact(profKey)
    self.standaloneKey = profKey
    self:Build()
    local craft = COC.Craft
    if craft and craft:GetOpenProfessionInfo() then
        if craft.IsCraftOpen and craft:IsCraftOpen() then
            if CloseCraft then CloseCraft() end
        else
            if CloseTradeSkill then CloseTradeSkill() end
        end
        -- OnProfessionClose prend le relais (voit standaloneKey → reste en compact)
    else
        if not self.frame:IsShown() then self.frame:Show() end
        self:Refresh()
    end
end

function PW:Refresh()
    if not (C_Timer and C_Timer.After) then return self:_DoRefresh() end
    if self._pending then return end
    self._pending = true
    C_Timer.After(0.1, function() PW:_DoRefresh() end)
end

-- ------------------------------------------------------------------
-- Entrées (depuis le coordinateur d'événements ProfOrders) + bascule
-- ------------------------------------------------------------------
-- Custom = vue métier par DÉFAUT (la maquette designer). « Vue Blizzard » pose profWindow=false.
function PW:IsEnabled() return not (COC.db and COC.db.profWindow == false) end

-- Active/désactive la fenêtre custom. ON → coupe le takeover de Guild Economy (anti-conflit).
function PW:SetEnabled(on)
    if COC.db then COC.db.profWindow = on and true or false end
    if on then
        if _G.TradeScannerDB then TradeScannerDB.replaceProfWindow = false end   -- GE laisse la main
        print("|cFF33DD88Crafting Order|r " .. L["fenêtre métier custom |cFF33DD33activée|r — ouvre un métier. (Guild Economy laisse la main.)"])
        self:OnProfessionShow()
    else
        self:Hide(); self:RestoreNative()
        print("|cFF33DD88Crafting Order|r " .. L["fenêtre métier custom |cFFFFCC00désactivée|r (vue Blizzard)."])
    end
end

local function silenceGE()
    if _G.TradeScannerDB then TradeScannerDB.replaceProfWindow = false end
    if _G.TradeScanner and TradeScanner.ProfWindow and TradeScanner.ProfWindow.Hide then
        TradeScanner.ProfWindow:Hide()
    end
end

function PW:OnProfessionShow()
    if not self:IsEnabled() then return end
    local craft = COC.Craft
    if not (craft and craft:GetOpenProfessionInfo()) then return end
    silenceGE()                         -- coexistence : pas de double panneau si GE est chargé
    self.standaloneKey = nil            -- la fenêtre native prend le dessus sur une ouverture par clé
    self:Build(); self:NeutralizeNative()
    if not self.frame:IsShown() then self.frame:Show() end
    self:Refresh()
    -- L'ordre de dispatch des events entre addons n'est pas garanti : si GE traite SHOW APRÈS nous
    -- (et restaure la frame native / réaffiche sa fenêtre), on re-museler juste après.
    if C_Timer then C_Timer.After(0.05, function() silenceGE(); PW:NeutralizeNative() end) end
end

function PW:OnProfessionClose()
    self.selectedIndex = nil
    if self.standaloneKey then
        -- Une vue compacte a été demandée (ex. : Dépeçage pendant que la Forge était ouverte).
        -- On restaure la native fermée mais on RESTE VISIBLE en mode compact pour le bon métier.
        self:RestoreNative()
        if not self.frame:IsShown() then self.frame:Show() end
        self:Refresh()
    else
        self:Hide(); self:RestoreNative()
    end
end
