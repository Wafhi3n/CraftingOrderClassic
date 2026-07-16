-- CraftingOrderClassic_Enchant_Trade.lua — greffon ENCHANTEMENT sur la fenêtre d'ÉCHANGE.
-- Quand le partenaire pose un objet dans l'emplacement « ne sera pas échangé » (TRADE_ENCHANT_SLOT),
-- on liste MES enchants applicables à CET emplacement — plus besoin de chercher dans toute la liste.
-- Chaque ligne est un bouton SÉCURISÉ qui crafte l'enchant directement :
--   PreClick → CraftFrame_SetSelection(index) : sélectionne ET ARME le bouton natif, de façon SYNCHRONE
--   (⚠️ SelectCraft ne l'arme PAS : il n'émet aucun CRAFT_UPDATE — cf. _ProfWindow_Detail) ;
--   puis le clic sécurisé est redirigé vers CraftCreateButton → DoCraft de CET enchant.
-- L'enchant se pose alors sur le curseur : le joueur clique l'objet dans l'échange (l'appliquer nous-mêmes
-- n'est pas possible — l'API de ciblage sécurisée ne couvre que sacs/équipement, pas la fenêtre d'échange).
-- CONTRAINTE : l'API Craft ne répond que si la fenêtre d'Enchantement est OUVERTE → sinon on l'indique.
-- On AJOUTE un panneau à côté du natif (jamais de Hide/neutralisation), à DROITE pour ne pas heurter le
-- greffon Commandes (_Companion_Trade) qui vit SOUS la fenêtre d'échange.

local COC  = CraftingOrderClassic
local Comp = COC.Companion
local Skin = COC.UI.Skin
local L    = COC.L

local ET = {}
COC.EnchantTrade = ET

local panel
local MAXROWS, ROW_H = 8, 22

local function enchantSlot() return _G.TRADE_ENCHANT_SLOT or 7 end

-- Objet posé par le PARTENAIRE dans l'emplacement d'enchantement (c'est lui qui demande l'enchant).
local function targetEnchantLink()
    if not (_G.TradeFrame and TradeFrame:IsShown()) then return nil end
    return GetTradeTargetItemLink and GetTradeTargetItemLink(enchantSlot()) or nil
end

local function makeRow(i)
    local b = Skin.MakeGoldButton(panel.well, 10, 20, "", "SecureActionButtonTemplate")
    b:SetPoint("TOPLEFT", 5, -(4 + (i - 1) * ROW_H))
    b:SetPoint("TOPRIGHT", -5, -(4 + (i - 1) * ROW_H))
    b:RegisterForClicks("AnyUp")
    b:SetScript("PreClick", function(self)
        -- Sélectionne + ARME le bouton natif, de façon synchrone — helper PARTAGÉ avec la vue métier
        -- (toute la mécanique et son historique vivent dans COC.Craft:ArmNativeSelection).
        if self.craftIndex then COC.Craft:ArmNativeSelection(self.craftIndex) end
    end)
    b:SetScript("OnEnter", function(self)
        if not self.tipIndex then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if not pcall(GameTooltip.SetCraftSpell, GameTooltip, self.tipIndex) then GameTooltip:Hide(); return end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    b:Hide()
    return b
end

-- Remplit le puits. Grise la ligne dont les réactifs manquent (le bouton natif sera désactivé → le clic
-- sécurisé serait un no-op silencieux ; on le montre plutôt que de laisser croire à une panne).
local function fillRows(crafts)
    panel.rows = panel.rows or {}
    local n = math.min(#crafts, MAXROWS)
    local combat = InCombatLockdown and InCombatLockdown()
    for i = 1, n do
        local r = panel.rows[i] or makeRow(i); panel.rows[i] = r
        local e = crafts[i]
        r.craftIndex, r.tipIndex = e.index, e.index
        local short = (COC.Enchant and COC.Enchant:ShortName(e.name, e.spellID)) or e.name or "?"
        local avail = (e.numAvailable or 0) > 0
        r:SetText(short)
        r.text:SetTextColor(avail and 0.941 or 0.45, avail and 0.776 or 0.45, avail and 0.455 or 0.45)
        if not combat then
            r:SetAttribute("type", "click")
            r:SetAttribute("clickbutton", _G.CraftCreateButton)
        end
        r:Show()
    end
    for i = n + 1, #panel.rows do panel.rows[i]:Hide() end
    if #crafts > MAXROWS then
        panel.moreFS:SetText(string.format(L["+%d autre(s)"], #crafts - MAXROWS)); panel.moreFS:Show()
    else
        panel.moreFS:Hide()
    end
end

local function hideRows()
    for _, r in ipairs(panel.rows or {}) do r:Hide() end
    panel.moreFS:Hide()
end

function ET.Update()
    if not panel then return end
    local link = targetEnchantLink()
    if not link then panel:Hide(); return end
    -- ⚠️ PAS de `GetItemInfoInstant and GetItemInfoInstant(link)` en assignation multiple : `and` TRONQUE
    -- le multi-retour à UNE valeur → equipLoc devenait nil (« aucun enchant pour cet emplacement »).
    local equipLoc
    if GetItemInfoInstant then
        local _, _, _, loc = GetItemInfoInstant(link)
        equipLoc = loc
    end
    local crafts = COC.Enchant and COC.Enchant:CraftsForEquipLoc(equipLoc)
    panel.partnerFS:SetText("|cFFFFFFFF" .. Comp.shortName((GetUnitName and GetUnitName("NPC")) or "?") .. "|r")
    panel.itemFS:SetText(link)
    if not (COC.Craft and COC.Craft:IsCraftOpen()) then      -- session de craft fermée : on ne peut rien lire
        hideRows(); panel.hintFS:SetText("|cFFFF8855" .. L["Ouvre ta fenêtre d'Enchantement."] .. "|r")
        panel.hintFS:Show(); panel:Show(); return
    end
    if not (crafts and #crafts > 0) then
        hideRows(); panel.hintFS:SetText("|cFF888888" .. L["Aucun enchantement connu pour cet emplacement."] .. "|r")
        panel.hintFS:Show(); panel:Show(); return
    end
    panel.hintFS:Hide()
    fillRows(crafts)
    panel:Show()
end

local function build()
    if panel then return end
    panel = Comp.MakePanel("COCEnchantTradePanel", UIParent, 240, MAXROWS)
    panel:SetHeight(96 + MAXROWS * ROW_H)
    panel.well:SetHeight(MAXROWS * ROW_H + 8)
    panel.subFS:SetText("|c" .. Skin.hex.gold .. L["Enchanter cet objet"] .. "|r")
    panel.itemFS = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    panel.itemFS:SetPoint("TOPLEFT", 15, -50); panel.itemFS:SetPoint("RIGHT", -12, 0)
    panel.itemFS:SetJustifyH("LEFT"); panel.itemFS:SetWordWrap(false)
    panel.well:ClearAllPoints()
    panel.well:SetPoint("TOPLEFT", 12, -66); panel.well:SetPoint("TOPRIGHT", -12, -66)
    -- ⚠️ Parenté au PUITS, pas au panneau : le puits est un Frame ENFANT, il se dessine donc PAR-DESSUS
    -- les FontStrings du parent → le message restait noyé derrière son fond (vu en jeu 2026-07-15).
    panel.hintFS = panel.well:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    panel.hintFS:SetPoint("TOPLEFT", 8, -8); panel.hintFS:SetPoint("RIGHT", -8, 0)
    panel.hintFS:SetJustifyH("LEFT"); panel.hintFS:SetWordWrap(true); panel.hintFS:Hide()
    panel:Hide()
end

-- COALESCE les rafales d'événements (CRAFT_UPDATE spamme pendant les crafts en série — cf. le même
-- pattern pending-flag dans PW:Refresh) : un seul ET.Update() par fenêtre de 0,1 s. Sans ça, chaque
-- pulse refaisait un ReadRecipes() complet (boucle GetNumCrafts + tables neuves + tri) + repaint.
local pendingUpdate
local function updateSoon()
    if pendingUpdate then return end
    pendingUpdate = true
    C_Timer.After(0.1, function() pendingUpdate = nil; ET.Update() end)
end

function ET:Start()
    build()
    local f = CreateFrame("Frame")
    for _, ev in ipairs({ "TRADE_SHOW", "TRADE_CLOSED", "TRADE_TARGET_ITEM_CHANGED",
                          "CRAFT_SHOW", "CRAFT_CLOSE", "CRAFT_UPDATE",
                          "PLAYER_REGEN_ENABLED" }) do f:RegisterEvent(ev) end
    f:SetScript("OnEvent", function(_, ev)
        if ev == "TRADE_CLOSED" then if panel then panel:Hide() end; return end
        if ev == "TRADE_SHOW" and panel and _G.TradeFrame then    -- ancré à DROITE du natif (le greffon
            panel:ClearAllPoints()                                -- Commandes occupe le dessous)
            panel:SetPoint("TOPLEFT", TradeFrame, "TOPRIGHT", 4, 0)
        end
        -- ⚠️ Sortie de combat : fillRows saute SetAttribute en combat (verrouillé), laissant d'éventuelles
        -- lignes affichées mais NON câblées (clic = no-op silencieux, cf. revue api-gotcha-reviewer
        -- 2026-07-16). ET.Update() est idempotent → un rejeu IMMÉDIAT ici les câble (pas de coalescence :
        -- 0,1 s plus tard on pourrait être RE-rentré en combat et rater la fenêtre de câblage).
        if ev == "PLAYER_REGEN_ENABLED" then ET.Update() else updateSoon() end
    end)
end
