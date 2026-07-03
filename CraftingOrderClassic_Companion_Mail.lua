-- CraftingOrderClassic_Companion_Mail.lua — greffon COURRIER (scène B de la maquette) : panneau
-- accroché à droite du compositeur d'envoi. Pré-remplit objet / corps / contre-remboursement depuis
-- la commande sélectionnée, puis marque « remise » (Orders:Deliver) quand l'envoi ABOUTIT
-- (MAIL_SEND_SUCCESS + destinataire vérifié via hook passif de SendMail) — jamais d'auto-envoi.
-- Côté acheteur, la réception (pièce jointe prise) est déjà couverte par le détecteur CHAT_MSG_LOOT
-- (« Vous recevez un objet ») → Orders:TryAutoComplete, cf. CraftingOrderClassic_LootAlert.lua.

local COC  = CraftingOrderClassic
local Comp = COC.Companion
local Skin = COC.UI.Skin
local L    = COC.L

local Mail = {}
COC.MailPanel = Mail

local panel
local pending          -- { id, buyer } posé par « Remplir » — consommé à MAIL_SEND_SUCCESS
local lastSendTarget   -- destinataire RÉEL du dernier SendMail (hook passif, anti-mismatch)

local function me() return (UnitName and UnitName("player")) or "?" end

local function currentRecipient()
    local eb = _G.SendMailNameEditBox
    local t = eb and eb:GetText() or ""
    return (t:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Pré-remplit le compositeur depuis la commande sélectionnée. N'ENVOIE PAS (le joueur clique
-- Envoyer lui-même) ; prix illisible → C.O.D. laissé tel quel (à saisir à la main).
local function fill()
    local o = panel and panel.selected
    if not (o and o.status == "accepted") then return end
    local nm = COC.Orders:OrderName(o)
    if _G.SendMailSubjectEditBox then
        _G.SendMailSubjectEditBox:SetText(string.format(L["Commande : %s"], nm .. " " .. Skin.QtyText(o)))
    end
    if _G.MailEditBox and _G.MailEditBox.SetText then
        _G.MailEditBox:SetText(o.price and string.format(L["Voici ta commande. Prix convenu : %s."], o.price)
            or L["Voici ta commande."])
    end
    local copper = Comp.PriceToCopper(o.price)
    if copper and _G.SendMailCODButton and MoneyInputFrame_SetCopper and _G.SendMailMoney then
        _G.SendMailCODButton:SetChecked(true)
        if _G.SendMailSendMoneyButton then _G.SendMailSendMoneyButton:SetChecked(false) end
        MoneyInputFrame_SetCopper(_G.SendMailMoney, copper)
    end
    if SendMailFrame_CanSend then SendMailFrame_CanSend() end
    pending = { id = o.id, buyer = Comp.shortName(o.buyer or ""):lower() }
end

-- Marque « remise » sans passer par l'envoi (le joueur a déjà posté/donné l'objet autrement).
local function markDelivered()
    local o = panel and panel.selected
    if o and o.status == "accepted" then COC.Orders:Deliver(o.id); Mail.Update() end
end

function Mail.Update()
    if not (panel and panel:GetParent() and panel:GetParent():IsShown()) then return end
    local partner = currentRecipient()
    local orders = Comp:OrdersFor(partner)
    if #orders == 0 then panel:Hide(); return end
    panel.partnerFS:SetText("|cFFFFFFFF" .. Comp.shortName(partner) .. "|r")
    panel.selected = Comp.FillRows(panel, orders)
    local ok = panel.selected and panel.selected.status == "accepted"
    panel.fillBtn:SetAlpha(ok and 1 or 0.45)
    panel.dlvBtn:SetAlpha(ok and 1 or 0.45)
    panel:Show()
end

local function build()
    if panel or not _G.SendMailFrame then return end
    panel = Comp.MakePanel("CraftingOrderMailPanel", _G.SendMailFrame, 280, 4)
    panel:SetPoint("TOPLEFT", _G.MailFrame or _G.SendMailFrame, "TOPRIGHT", 4, -12)
    panel:SetHeight(panel:GetHeight() + 34)
    panel.Update = Mail.Update

    panel.fillBtn = Skin.MakeGoldButton(panel, 160, 22, L["Remplir depuis commande"])
    panel.fillBtn:SetPoint("BOTTOMLEFT", 12, 12)
    panel.fillBtn:SetScript("OnClick", fill)
    panel.dlvBtn = Skin.MakeGoldButton(panel, 90, 22, L["Marquer livrée"])
    panel.dlvBtn:SetPoint("BOTTOMRIGHT", -12, 12)
    panel.dlvBtn:SetScript("OnClick", markDelivered)

    -- Destinataire retapé → re-filtrer ; panneau suit l'onglet Envoyer via son parent.
    if _G.SendMailNameEditBox then
        _G.SendMailNameEditBox:HookScript("OnTextChanged", Mail.Update)
    end
    _G.SendMailFrame:HookScript("OnShow", Mail.Update)
    Comp.OnCacheRefresh(Mail.Update)

    -- Hook PASSIF de l'API d'envoi : mémorise le destinataire réel (si le joueur a changé le champ
    -- « À : » après « Remplir », on ne marquera PAS la mauvaise commande).
    hooksecurefunc("SendMail", function(target) lastSendTarget = Comp.shortName(target or ""):lower() end)
end

local f = CreateFrame("Frame")
f:RegisterEvent("MAIL_SHOW")
f:RegisterEvent("MAIL_CLOSED")
f:RegisterEvent("MAIL_SEND_SUCCESS")
f:SetScript("OnEvent", function(_, event)
    if event == "MAIL_SHOW" then
        build()
        if panel then Mail.Update() end
    elseif event == "MAIL_CLOSED" then
        pending = nil
    elseif event == "MAIL_SEND_SUCCESS" and pending then
        local o = COC.db and COC.db.orders and COC.db.orders[pending.id]
        if o and o.status == "accepted" and o.acceptedBy == me()
           and lastSendTarget == pending.buyer then
            COC.Orders:Deliver(pending.id)
        end
        pending = nil
        if panel then Mail.Update() end
    end
end)
