-- CraftingOrderClassic_ProfWindow_Trade.lua — le mode ÉCHANGE de la colonne de métier (T3).
-- Spec : docs/specs/enchant-echange-forever.md. Un échange est ouvert ET la fenêtre affiche
-- l'Enchantement : la colonne cache ses onglets (Commandes, Plan de route, Manquantes) et ne montre
-- plus que l'échange — la silhouette du partenaire, la pièce qu'il a posée, et la place de l'indice
-- « ses composants correspondent à » (T5). À la fin de l'échange, elle revient sur l'onglet d'avant.
--
-- C'est une VUE de plus de la colonne (dockView = "trade", cf. _ProfWindow_DockViews) : la bascule
-- existante masque déjà les pièces des autres vues, et tait les onglets tant qu'elle est active.
-- Ce fichier décide seulement QUAND y entrer et en sortir, et remplit la vue.
--
-- La silhouette vient de _Enchant_Trade_Ask (BuildSilhouette). Son clic fait DEUX choses : demander
-- la pièce au partenaire (chuchotement + ASKE) et filtrer la liste native sur cet emplacement (T4).
-- Le panneau flottant qui la portait a été supprimé au passage.
--
-- ⚠️ LE COMBAT. Greffée, la colonne est protégée comme la fenêtre native : changer de vue y est
-- refusé. On n'entre ni ne sort en combat ; tout se rejoue à PLAYER_REGEN_ENABLED, selon l'état
-- RÉEL de l'échange à ce moment-là.

local COC  = CraftingOrderClassic
local PW   = COC.ProfWindow
local Skin = COC.UI.Skin
local L    = COC.L
if not PW then return end

local EMPTY_ICON = "Interface\\PaperDoll\\UI-Backpack-EmptySlot"

local function lockedDown() return InCombatLockdown and InCombatLockdown() end

-- Un silence doit se NOMMER (même discipline que la trace `aske`) : sans ça, « la silhouette ne
-- s'affiche pas » et « elle a été refusée pour telle raison » se présentent pareil. Catégorie
-- `enchview`, et jamais deux fois la même raison d'affilée.
local function trace(msg)
    if not (COC.Trace and COC.Trace:IsOn()) then return end
    if PW._tradeSaid == msg then return end
    PW._tradeSaid = msg
    COC.Trace:Log("enchview", msg)
end

-- ------------------------------------------------------------------
-- Quand
-- ------------------------------------------------------------------

-- La colonne est affichée dans la fenêtre native, un échange est ouvert, et la fenêtre montre MON
-- Enchantement : ni un métier lié d'un autre joueur, ni celui de la guilde, ni un PNJ artisan.
local function wanted(self)
    if not (_G.TradeFrame and TradeFrame:IsShown()) then return false, nil end   -- pas d'échange : rien à dire
    if not (self.docked and self.frame and self.frame:IsShown()) then
        return false, "colonne pas affichée dans la fenêtre de métier"
    end
    local C = COC.Craft
    local key = C and C:OpenProfessionKey()
    if key ~= "Enchanting" then return false, "métier affiché = " .. tostring(key) end
    local ts = C_TradeSkillUI
    if ts and ((ts.IsTradeSkillLinked and ts.IsTradeSkillLinked())
            or (ts.IsTradeSkillGuild and ts.IsTradeSkillGuild())
            or (ts.IsNPCCrafting and ts.IsNPCCrafting())) then
        return false, "métier lié, de guilde ou de PNJ"
    end
    return true
end

-- Une SESSION par échange : elle retient l'onglet d'avant, et ne finit qu'avec l'ÉCHANGE. Un autre
-- métier affiché, ou la fenêtre refermée, ne font que sortir de la vue : revenu sur l'Enchantement
-- pendant le même échange, on y rentre sans oublier d'où l'on venait.
function PW:_SyncTradeView()
    if lockedDown() then return trace("combat : on attend la fin") end
    local ok, why = wanted(self)
    if ok then
        if not self._tradeSession then self._tradeSession = { prev = self.dockView } end
        if self.dockView ~= "trade" then
            trace("entrée en mode Échange (onglet d'avant : " .. tostring(self._tradeSession.prev or "Commandes") .. ")")
            self:_SetDockView("trade")
        else
            self:_FillTradeView()
        end
        return
    end
    if why then trace("pas de mode Échange — " .. why) end
    local session = self._tradeSession
    if not session then return end
    local trading = _G.TradeFrame and TradeFrame:IsShown()
    if not trading then self._tradeSession = nil end
    if self.dockView ~= "trade" then return end    -- déjà sortie (remise aux Commandes entre-temps)
    if self.docked and self.frame and self.frame:IsShown() then
        trace("sortie du mode Échange → " .. tostring(session.prev or "Commandes"))
        self:_SetDockView(session.prev)            -- fin d'échange, ou autre métier : l'onglet d'avant
    elseif not trading then
        -- Fenêtre fermée ET échange fini : simple remise aux Commandes. Remplir une route ou des
        -- manquantes sans métier ouvert n'aurait rien à lire.
        self:_ResetDockView()
    end
    -- Fenêtre fermée, échange en cours : rien. La vue revient avec la fenêtre.
end

-- ------------------------------------------------------------------
-- Quoi
-- ------------------------------------------------------------------

-- Pièce posée par le PARTENAIRE dans l'emplacement « ne sera pas échangé ».
-- ⚠️ Pas de `GetItemInfoInstant and GetItemInfoInstant(link)` : `and` tronque le multi-retour.
local function tradeItem()
    local link = GetTradeTargetItemLink and GetTradeTargetItemLink(_G.TRADE_ENCHANT_SLOT or 7)
    if not link then return nil end
    local loc, icon, sub
    if COC.Api.GetItemInfoInstant then
        local _, _, _, l, ic, _, s = COC.Api.GetItemInfoInstant(link)
        loc, icon, sub = l, ic, s
    end
    return link, loc, sub, icon
end

-- La couche courante a-t-elle au moins un enchant pour cette pièce ?
local function hasEnchant(loc, sub)
    local E = COC.Enchant
    for _, w in ipairs((E and E:WordsForEquipLoc(loc, sub)) or {}) do
        if E:HasCatalogFor(w) then return true end
    end
    return false
end

local function fillItem(tp)
    local link, loc, sub, icon = tradeItem()
    tp.itemLink = link
    tp.itemBtn.icon:SetTexture(icon or EMPTY_ICON)
    if not link then
        tp.itemFS:SetText("|cFF888888—|r")
        tp.noteFS:SetText(L["Rien de posé. Clique un emplacement pour lui demander sa pièce."])
    else
        tp.itemFS:SetText(link)
        tp.noteFS:SetText(hasEnchant(loc, sub) and "" or L["Aucun enchantement connu pour cet emplacement."])
    end
end

function PW:_FillTradeView()
    local tp = self.tradePanel
    if not tp then return end
    local name = COC.Api.UnitNameSafe("NPC")
    local short = name and COC.Companion.shortName(name) or "?"
    tp.title:SetText(string.format(L["Échange avec %s"], "|cFFFFFFFF" .. short .. "|r"))
    local Ask = COC.EnchantTradeAsk
    if Ask then
        -- Le modèle ne se recharge qu'au changement de partenaire : chaque pièce posée relance un
        -- remplissage, et un SetUnit à chaque fois ferait clignoter la silhouette.
        if tp.modelFor ~= short then tp.modelFor = short; Ask:ShowPartnerModel(tp.model) end
        Ask:RefreshSlots(tp.btns)
    end
    fillItem(tp)
end

-- ------------------------------------------------------------------
-- Construction (paresseuse, au premier échange)
-- ------------------------------------------------------------------

local function buildItemRow(tp, well)
    local ib = Skin.MakeIconButton(tp, 32, EMPTY_ICON)
    ib:SetPoint("TOPLEFT", well, "BOTTOMLEFT", 4, -10)
    ib:SetScript("OnEnter", function(b)
        if not tp.itemLink then return end
        GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
        if pcall(GameTooltip.SetHyperlink, GameTooltip, tp.itemLink) then GameTooltip:Show() end
    end)
    ib:SetScript("OnLeave", GameTooltip_Hide)
    tp.itemBtn = ib
    local hdr = tp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr:SetPoint("TOPLEFT", ib, "TOPRIGHT", 8, -1); hdr:SetPoint("RIGHT", tp, "RIGHT", -8, 0)
    hdr:SetJustifyH("LEFT"); hdr:SetText(L["Pièce à enchanter"])
    local fs = tp:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", hdr, "BOTTOMLEFT", 0, -3); fs:SetPoint("RIGHT", tp, "RIGHT", -8, 0)
    fs:SetJustifyH("LEFT"); fs:SetWordWrap(false)
    tp.itemFS = fs
    local note = tp:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", ib, "BOTTOMLEFT", 0, -8); note:SetPoint("RIGHT", tp, "RIGHT", -8, 0)
    note:SetJustifyH("LEFT")
    tp.noteFS = note
    -- La place de l'indice « ses composants correspondent à » (T5) : réservée, vide pour l'instant.
    local hint = tp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -8); hint:SetPoint("RIGHT", tp, "RIGHT", -8, 0)
    hint:SetJustifyH("LEFT"); hint:Hide()
    tp.hintFS = hint
end

-- Même emprise que les vues Plan de route et Manquantes (cf. PW:_BuildDockViews).
function PW:_BuildTradeView()
    if self.tradePanel or not self.ordScroll then return end
    local Ask = COC.EnchantTradeAsk
    if not (Ask and Ask.BuildSilhouette) then return end
    local host = self.ordScroll:GetParent()
    local tp = CreateFrame("Frame", nil, host)
    tp:SetPoint("TOPLEFT", host, "TOPLEFT", 0, -PW.TUNE.viewTop)
    tp:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, 0)
    tp:Hide()
    local title = tp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 8, 0); title:SetPoint("RIGHT", tp, "RIGHT", -8, 0)
    title:SetJustifyH("LEFT"); title:SetWordWrap(false)
    tp.title = title
    local well = CreateFrame("Frame", nil, tp, "BackdropTemplate")
    well:SetPoint("TOPLEFT", 6, -20); well:SetPoint("TOPRIGHT", -6, -20)
    Skin.SkinWell(well)
    -- Le clic demande la pièce au partenaire (Ask:Request) ET filtre la liste native sur cet
    -- emplacement : la main droite coche « Weapon » et « 2H Weapon », puisqu'on ne sait pas encore
    -- ce qu'il tient. Dès qu'une pièce est posée, c'est ELLE qui commande (cf. _Enchant_Filter_Pilot).
    local sil = Ask:BuildSilhouette(well, function(def)
        local F = COC.EnchantFilter
        if F and F.Request and def then F.Request(def.slot) end
    end)
    if not sil then return end
    well:SetHeight(sil.height)
    tp.model, tp.btns = sil.model, sil.btns
    buildItemRow(tp, well)
    self.tradePanel = tp
end

-- ------------------------------------------------------------------
-- Branchement
-- ------------------------------------------------------------------

-- Coalescé : ouvrir la fenêtre ou poser une pièce enchaîne plusieurs événements, et la pièce n'est
-- lisible qu'un instant après TRADE_TARGET_ITEM_CHANGED. La sortie de combat rejoue tout de suite.
local pending
local f = CreateFrame("Frame")
COC.Api.RegisterEventsSafe(f, { "TRADE_SHOW", "TRADE_CLOSED", "TRADE_TARGET_ITEM_CHANGED",
                                "TRADE_SKILL_SHOW", "TRADE_SKILL_CLOSE", "TRADE_SKILL_LIST_UPDATE",
                                "PLAYER_REGEN_ENABLED" })
f:SetScript("OnEvent", function(_, ev)
    if ev == "PLAYER_REGEN_ENABLED" then PW:_SyncTradeView(); return end
    if pending then return end
    pending = true
    C_Timer.After(0.1, function() pending = nil; PW:_SyncTradeView() end)
end)
