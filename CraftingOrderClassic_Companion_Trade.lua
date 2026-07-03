-- CraftingOrderClassic_Companion_Trade.lua — greffon ÉCHANGE (scène A de la maquette) : panneau
-- accroché SOUS la fenêtre d'échange native quand une commande nous lie au partenaire (dans les DEUX
-- sens : je crafte pour lui = « vendeur », ou il crafte pour moi = « acheteur »).
-- ⚠️ L'or de l'échange (TradePlayerInputMoneyFrame) est :SetForbidden() par Blizzard : ni lisible ni
-- écrivable par un addon → le montant est AFFICHÉ (« À réclamer » / « À payer »), jamais pré-rempli.
-- PERSISTANCE : le panneau reste affiché APRÈS la fermeture de l'échange (re-parenté à l'écran) tant
-- qu'il reste des commandes actives, pour que chacun finalise sur place — vendeur « Marquer livrée »,
-- acheteur « J'ai reçu » (Orders:Confirm) — sans passer par le Carnet. Fermeture manuelle par la croix.

local COC  = CraftingOrderClassic
local Comp = COC.Companion
local Skin = COC.UI.Skin
local L    = COC.L

local Trade = {}
COC.TradePanel = Trade

local panel

local function partnerName()
    return (GetUnitName and GetUnitName("NPC")) or nil
end

-- VENDEUR : marque « remise » (Orders:Deliver, statut delivered). Déclenché à la main — c'est le
-- crafteur qui constate que l'objet est bien donné (l'échange est annulable jusqu'au bout).
local function markDelivered()
    local o = panel and panel.selected
    if o and o.status == "accepted" then COC.Orders:Deliver(o.id); Trade.Update() end
end

-- ACHETEUR : confirme la réception (Orders:Confirm → done, crédite le crafteur). Remplace l'aller-
-- retour au Carnet « J'ai reçu ».
local function confirmReceived()
    local o = panel and panel.selected
    if o and (o.status == "accepted" or o.status == "delivered") then
        COC.Orders:Confirm(o.id); Trade.Update()
    end
end

local function closePanel()
    Trade.persist = false
    if panel then panel:Hide() end
end

function Trade.Update()
    if not panel then return end
    local tradeOpen = _G.TradeFrame and _G.TradeFrame:IsShown()
    if not tradeOpen and not Trade.persist then panel:Hide(); return end
    local partner = (tradeOpen and partnerName()) or Trade.partner   -- NPC nil après fermeture → mémorisé
    local orders = partner and Comp:OrdersWith(partner) or {}
    if #orders == 0 then panel:Hide(); Trade.persist = false; return end
    panel.partnerFS:SetText("|cFFFFFFFF" .. Comp.shortName(partner or "?") .. "|r")
    panel.selected = Comp.FillRows(panel, orders)
    local o = panel.selected
    local role = o and Comp.RoleWith(o, partner)
    if role == "buy" then                        -- ACHETEUR : ce que je paie / reçois + « J'ai reçu »
        panel.collectFS:SetText(o.price
            and string.format(L["À payer : %s"], Comp.PriceLabel(o)) or L["Gratuit."])
        panel.dlvBtn:Hide()
        panel.confBtn:Show()
    else                                         -- VENDEUR : montant à encaisser + « Marquer livrée »
        panel.collectFS:SetText(o and o.price
            and string.format(L["À réclamer : %s"], Comp.PriceLabel(o)) or L["Pas de prix convenu."])
        panel.confBtn:Hide()
        panel.dlvBtn:Show()
        panel.dlvBtn:SetAlpha((o and o.status == "accepted") and 1 or 0.45)
    end
    panel:Show()
end

local function build()
    if panel or not _G.TradeFrame then return end
    -- Parenté à UIParent (PAS à TradeFrame) pour survivre à la fermeture de l'échange.
    panel = Comp.MakePanel("CraftingOrderTradePanel", UIParent, 280, 3)
    panel:SetHeight(panel:GetHeight() + 34)
    panel.Update = Trade.Update

    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2); close:SetScript("OnClick", closePanel)
    panel.partnerFS:ClearAllPoints()
    panel.partnerFS:SetPoint("TOPRIGHT", close, "TOPLEFT", -2, -4)

    -- Montant à réclamer / à payer — AFFICHAGE SEUL (champ d'or natif interdit aux addons, cf. en-tête).
    panel.collectFS = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    panel.collectFS:SetPoint("BOTTOMLEFT", 15, 18); Skin.ApplyShadow(panel.collectFS)
    panel.dlvBtn = Skin.MakeGoldButton(panel, 110, 22, L["Marquer livrée"])
    panel.dlvBtn:SetPoint("BOTTOMRIGHT", -12, 12)
    panel.dlvBtn:SetScript("OnClick", markDelivered)
    panel.confBtn = Skin.MakeGoldButton(panel, 110, 22, L["J'ai reçu"])
    panel.confBtn:SetPoint("BOTTOMRIGHT", -12, 12)
    panel.confBtn:SetScript("OnClick", confirmReceived)
    panel.confBtn:Hide()

    Comp.OnCacheRefresh(Trade.Update)
end

local f = CreateFrame("Frame")
f:RegisterEvent("TRADE_SHOW")
f:RegisterEvent("TRADE_CLOSED")
f:SetScript("OnEvent", function(_, event)
    build()
    if not panel then return end
    if event == "TRADE_SHOW" then
        Trade.persist = false
        Trade.partner = partnerName()
        panel:ClearAllPoints()
        panel:SetPoint("TOPLEFT", _G.TradeFrame, "BOTTOMLEFT", 0, -4)
    elseif event == "TRADE_CLOSED" then
        -- Échange fermé (succès ou annulation) : on PERSISTE s'il reste des commandes à finaliser,
        -- ancré à la dernière position de la fenêtre (TradeFrame masquée conserve son placement).
        Trade.persist = (Trade.partner and #Comp:OrdersWith(Trade.partner) > 0) and true or false
    end
    Trade.Update()
end)
