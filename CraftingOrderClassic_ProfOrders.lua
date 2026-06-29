-- CraftingOrderClassic_ProfOrders.lua — panneau compagnon de la fenêtre métier.
-- Quand une fenêtre de métier (TradeSkill ou Craft) s'ouvre, on accroste à sa droite la liste des
-- COMMANDES liées à ce métier (carnet global + entrantes captées), avec un marqueur ✓/✗ selon que
-- l'on sait crafter/récolter l'objet. Bouton bascule pour masquer l'overlay (revenir au « vanilla »).
--
-- NB : la MIGRATION complète de la fenêtre métier custom (navigateur 3 colonnes de TradeScanner)
-- reste un chantier dédié (Étape C/E). Ici on livre la tranche « commandes du métier + marqueur ».

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L
local ProfOrders = {}
COC.ProfOrders = ProfOrders

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

local GATHER = { Mining = true, Herbalism = true, Skinning = true, Fishing = true }
local RH = 30   -- hauteur de ligne

-- Sais-je honorer cette commande ? Récolte = j'ai le skill ; craft = je connais la recette.
local function canFulfill(o)
    local prof = o.profession; if not prof then return nil end
    local c, D = CL(), COC.Directory
    if GATHER[prof] then
        return (D and D.mySkills and D.mySkills[prof]) ~= nil
    end
    if not c then return nil end
    if o.itemID  and c:IKnowRecipeForItem(prof, o.itemID)  then return true end
    if o.spellID and c:IKnowRecipeBySpell(prof, o.spellID) then return true end
    return false
end

-- Profession actuellement ouverte (clé interne), ou nil.
local function openProf()
    local c = CL(); if not c then return nil end
    return (c:OpenProfession())
end

-- =========================================================================
-- Construction (paresseuse)
-- =========================================================================
function ProfOrders:Build()
    if self.panel then return self.panel end
    local p = CreateFrame("Frame", "CraftingOrderProfOrders", UIParent, "BackdropTemplate")
    p:SetSize(250, 360); p:SetFrameStrata("HIGH"); Skin.SkinFrameBackdrop(p); p:Hide()
    self.panel = p

    local title = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 16, -14); Skin.ApplyShadow(title)
    title:SetText("|cFFE8B84B" .. L["Commandes"] .. "|r"); self.title = title

    local sub = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sub:SetPoint("TOPLEFT", 16, -32); self.sub = sub

    -- Bascule : masque l'overlay (laisse la fenêtre métier vanilla seule). Persistant.
    local toggle = Skin.MakeGoldButton(p, 78, 18, L["Masquer"])
    toggle:SetPoint("TOPRIGHT", -12, -12)
    toggle:SetScript("OnClick", function()
        COC.db.profCompanion = false; p:Hide()
        print("|cFF33DD88Crafting Order|r " .. L["overlay métier masqué — |cFFFFFFFF/co prof|r pour le réafficher."])
    end)

    -- Passe à la fenêtre CUSTOM complète (3 colonnes) — l'inverse du bouton « Vue Blizzard ».
    local toCustom = Skin.MakeGoldButton(p, 168, 18, L["» Vue Crafting Order"])
    toCustom:SetPoint("TOPLEFT", 14, -50)
    toCustom:SetScript("OnClick", function() if COC.ProfWindow then COC.ProfWindow:SetEnabled(true) end end)

    local scroll = CreateFrame("ScrollFrame", "CraftingOrderProfOrdersScroll", p, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -74); scroll:SetPoint("BOTTOMRIGHT", -30, 12)
    local content = CreateFrame("Frame", nil, scroll); content:SetSize(200, 10); scroll:SetScrollChild(content)
    self.content = content; self.rows = {}
    return p
end

function ProfOrders:_Row(i)
    local r = self.rows[i]; if r then return r end
    r = CreateFrame("Frame", nil, self.content); r:SetSize(206, RH); r:SetPoint("TOPLEFT", 0, -(i - 1) * RH)
    r.badge = Skin.MakeBadge(r, 16); r.badge:SetPoint("TOPLEFT", 2, -1)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.name:SetPoint("TOPLEFT", 22, -2); r.name:SetWidth(150); r.name:SetJustifyH("LEFT"); Skin.ApplyShadow(r.name)
    r.sub = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.sub:SetPoint("TOPLEFT", 22, -16); r.sub:SetWidth(184); r.sub:SetJustifyH("LEFT"); Skin.ApplyShadow(r.sub)
    r:EnableMouse(true)
    r:SetScript("OnEnter", function(self)
        if not self.tipItemID then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. self.tipItemID) then GameTooltip:Show() else GameTooltip:Hide() end
    end)
    r:SetScript("OnLeave", GameTooltip_Hide)
    self.rows[i] = r; return r
end

-- =========================================================================
-- Affichage
-- =========================================================================
function ProfOrders:Refresh()
    if not (self.panel and self.panel:IsShown()) then return end
    local prof = self.prof; local c = CL()
    self.sub:SetText("|cFF888888" .. (prof and Skin.ProfLabel(prof) or "—") .. "|r")

    -- Collecte : carnet (open/accepted) + entrantes, pour CE métier.
    local list = {}
    for _, o in pairs((COC.db and COC.db.orders) or {}) do
        if o.profession == prof and o.status ~= "cancelled" and o.status ~= "done" then
            list[#list + 1] = { o = o, kind = "order" }
        end
    end
    for _, e in pairs((COC.db and COC.db.inbound) or {}) do
        if e.profession == prof and e.status ~= "dismissed" then
            list[#list + 1] = { o = e, kind = "inbound" }
        end
    end
    table.sort(list, function(a, b) return (a.o.ts or 0) > (b.o.ts or 0) end)

    local n = 0
    for _, it in ipairs(list) do
        n = n + 1; local row = self:_Row(n); local o = it.o
        local nm = (c and c:ItemName(o.itemID)) or (o.spellID and c and c:RecipeName(o.spellID)) or ("item:" .. (o.itemID or 0))
        local r, g, b = Skin.RarityColor(o.itemID)
        row.tipItemID = o.itemID
        row.badge:Paint(r, g, b, Skin.FirstChar(nm), Skin.Icon(o.itemID, o.spellID) or Skin.tex.unknown)
        local able = canFulfill(o)
        -- Marqueur devant le nom : ✓ je sais faire, ✗ hors de ma portée, rien si indéterminé.
        local tag = (able == true) and "|cFF33DD33✓|r " or (able == false) and "|cFFFF5555✗|r " or ""
        row.name:SetText(tag .. ((nm:match("^item:") and L["Chargement…"]) or nm)); row.name:SetTextColor(r, g, b)
        local who = (it.kind == "inbound") and (L["entrante · "] .. o.buyer) or (o.buyer or "?")
        local qty = o.byStack and ((o.qty or 1) .. " st") or ("×" .. (o.qty or 1))
        local pr  = o.price and ("  |cFFFFDD00" .. o.price .. "|r") or ""
        row.sub:SetText("|cFF999999" .. qty .. " · " .. who .. "|r" .. pr)
        row:Show()
    end
    for i = n + 1, #self.rows do self.rows[i]:Hide() end
    self.content:SetHeight(math.max(n * RH, 10))
    Skin.AutoHideScroll("CraftingOrderProfOrdersScroll", self.content)
    self.title:SetText("|cFFE8B84B" .. L["Commandes"] .. "|r |cFF888888(" .. n .. ")|r")
end

function ProfOrders:OnProfShow()
    if COC.db and COC.db.profCompanion == false then return end
    local prof = openProf(); if not prof then return end
    self.prof = prof
    local p = self:Build()
    local host = (CraftFrame and CraftFrame:IsShown() and CraftFrame)
              or (TradeSkillFrame and TradeSkillFrame:IsShown() and TradeSkillFrame)
    p:ClearAllPoints()
    if host then p:SetPoint("TOPLEFT", host, "TOPRIGHT", 2, 0)
    else p:SetPoint("CENTER", UIParent, "CENTER", 320, 40) end
    p:Show(); self:Refresh()
end

function ProfOrders:OnProfHide()
    if self.panel then self.panel:Hide() end
end

-- /co prof → réafficher l'overlay après l'avoir masqué.
function ProfOrders:Reenable()
    if COC.db then COC.db.profCompanion = true end
    self:OnProfShow()
end

-- Mutex métier : on a détaché les frames natives de UIPanelWindows (pour les neutraliser sans Hide),
-- ce qui débraye la fermeture mutuelle native. On la refait à la main → un seul métier à la fois.
-- Renvoie true si on a effectivement fermé l'AUTRE métier (cas bascule Enchantement↔Couture).
local function closeOtherProfession(event)
    if event:find("^CRAFT") then
        if _G.TradeSkillFrame and TradeSkillFrame:IsShown() and CloseTradeSkill then CloseTradeSkill(); return true end
    elseif _G.CraftFrame and CraftFrame:IsShown() and CloseCraft then CloseCraft(); return true end
    return false
end

-- SHOW d'un métier : neutralise INSTANTANÉMENT le natif (zéro flash Blizzard avant notre fenêtre),
-- ferme l'autre métier éventuellement ouvert, puis affiche notre fenêtre custom (ou l'overlay).
function ProfOrders:_OnShow(PW, windowOn, event)
    if not windowOn then
        local fn = function() ProfOrders:OnProfShow() end
        if C_Timer then C_Timer.After(0.2, fn) else fn() end
        return
    end
    local switched = closeOtherProfession(event)
    PW:NeutralizeNative()                          -- instantané → le natif ne clignote jamais
    if switched and C_Timer then
        C_Timer.After(0.1, function() PW:OnProfessionShow() end)   -- laisse le *_CLOSE de l'autre passer
    else
        PW:OnProfessionShow()
    end
end

-- Coordinateur unique des events fenêtre métier : route vers la fenêtre CUSTOM (si activée via
-- `/co profwindow`) ou vers l'overlay « commandes du métier » sinon.
function ProfOrders:Start()
    if not COC.db then return end
    if COC.db.profCompanion == nil then COC.db.profCompanion = true end
    local f = CreateFrame("Frame")
    for _, ev in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_UPDATE", "TRADE_SKILL_CLOSE",
                          "CRAFT_SHOW", "CRAFT_UPDATE", "CRAFT_CLOSE" }) do f:RegisterEvent(ev) end
    f:SetScript("OnEvent", function(_, event)
        local PW = COC.ProfWindow
        local windowOn = PW and PW:IsEnabled()
        if event:find("SHOW$") then
            ProfOrders:_OnShow(PW, windowOn, event)
        elseif event:find("UPDATE$") then
            -- Skill-up / plan appris pendant la session : re-capture mon niveau (rang à jour en en-tête)
            -- et ré-annonce throttlé (les autres voient mon nouveau skill). [[craftingorder-social-vision]]
            if COC.Directory then COC.Directory:CaptureSkills(); COC.Directory:AnnounceThrottled() end
            if windowOn then
                if PW.frame and PW.frame:IsShown() then PW:Refresh() else PW:OnProfessionShow() end
            elseif ProfOrders.panel and ProfOrders.panel:IsShown() then ProfOrders:Refresh() end
        else   -- *_CLOSE
            if windowOn and COC.Craft and COC.Craft:GetOpenProfessionInfo() then
                PW:OnProfessionShow()          -- bascule : un autre métier reste encore ouvert
            else
                if PW then PW:OnProfessionClose() end
                ProfOrders:OnProfHide()
            end
        end
    end)
end
