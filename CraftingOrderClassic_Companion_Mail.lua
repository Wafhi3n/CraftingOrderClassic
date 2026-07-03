-- CraftingOrderClassic_Companion_Mail.lua — greffon COURRIER (scène B de la maquette) : panneau
-- accroché à droite du compositeur d'envoi. Liste MES commandes à livrer ; « Remplir depuis commande »
-- renseigne le destinataire (« À: ») + objet / corps / contre-remboursement, puis marque « remise »
-- (Orders:Deliver) quand l'envoi ABOUTIT (MAIL_SEND_SUCCESS + destinataire vérifié) — jamais d'auto-envoi.
-- Si un destinataire est déjà saisi, on filtre sur ses commandes ; sinon on affiche TOUTES mes livraisons.
-- Côté acheteur, la réception (pièce jointe prise) est couverte par le détecteur CHAT_MSG_LOOT existant.

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

-- 1er slot d'attache libre du courrier (1..12), ou nil si plein.
local function freeAttachSlot()
    for i = 1, (ATTACHMENTS_MAX_SEND or 12) do
        if not HasSendMailItem(i) then return i end
    end
    return nil
end

-- L'objet est-il DÉJÀ joint ? (évite un doublon si on reclique « Remplir »).
local function alreadyAttached(itemID)
    for i = 1, (ATTACHMENTS_MAX_SEND or 12) do
        if HasSendMailItem(i) then
            local _, id = GetSendMailItem(i)
            if id == itemID then return true end
        end
    end
    return false
end

-- Joint l'objet crafté (itemID) au courrier jusqu'à `qty` exemplaires, depuis les sacs. N'ENVOIE RIEN
-- (le joueur relit puis clique Envoyer). Piles entières via C_Container.UseContainerItem ; pile
-- partielle finale via SplitContainerItem + ClickSendMailItemButton (attache exactement le reste).
-- Best-effort : objet absent des sacs ou 12 slots pleins → on s'arrête sans erreur.
local function attachItem(itemID, qty)
    if not (itemID and _G.SendMailFrame and _G.SendMailFrame:IsShown()) then return end
    local C = C_Container
    if not (C and C.GetContainerNumSlots and C.GetContainerItemID and C.UseContainerItem) then return end
    local remaining = math.max(qty or 1, 1)
    for bag = 0, (NUM_BAG_SLOTS or 4) do
        for slot = 1, (C.GetContainerNumSlots(bag) or 0) do
            if remaining <= 0 then return end
            if C.GetContainerItemID(bag, slot) == itemID and freeAttachSlot() then
                local info = C.GetContainerItemInfo and C.GetContainerItemInfo(bag, slot)
                local count = (info and info.stackCount) or 1
                if count <= remaining or not C.SplitContainerItem then
                    C.UseContainerItem(bag, slot)                 -- pile entière
                    remaining = remaining - count
                else
                    local dest = freeAttachSlot()
                    C.SplitContainerItem(bag, slot, remaining)    -- exactement le reste sur le curseur
                    if dest and ClickSendMailItemButton then ClickSendMailItemButton(dest) end
                    remaining = 0
                end
            end
        end
    end
end

-- Pré-remplit le compositeur depuis la commande sélectionnée : destinataire + objet + corps + C.O.D.
-- N'ENVOIE PAS (le joueur clique Envoyer). Prix illisible → C.O.D. laissé tel quel.
local function fill()
    local o = panel and panel.selected
    if not (o and o.status == "accepted") then return end
    pending = { id = o.id, buyer = Comp.shortName(o.buyer or ""):lower() }
    if _G.SendMailNameEditBox and o.buyer then _G.SendMailNameEditBox:SetText(o.buyer) end
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
    -- Joint l'objet crafté depuis les sacs (best-effort ; enchant sans itemID → rien à joindre).
    if o.itemID and not alreadyAttached(o.itemID) then
        local wantN = o.qty or 1
        if o.byStack and GetItemInfo then
            local stackSize = select(8, GetItemInfo(o.itemID))
            if stackSize and stackSize > 1 then wantN = wantN * stackSize end
        end
        attachItem(o.itemID, wantN)
    end
    if SendMailFrame_CanSend then SendMailFrame_CanSend() end
end

-- Marque « remise » sans passer par l'envoi (l'objet a déjà été remis autrement).
local function markDelivered()
    local o = panel and panel.selected
    if o and o.status == "accepted" then COC.Orders:Deliver(o.id); Mail.Update() end
end

function Mail.Update()
    if not panel then return end
    if not (panel:GetParent() and panel:GetParent():IsShown()) then panel:Hide(); return end
    local typed = currentRecipient()
    local orders = (typed ~= "") and Comp:OrdersFor(typed) or Comp:MyDeliverables()
    if #orders == 0 then panel:Hide(); return end
    panel.selected = Comp.FillRows(panel, orders)
    local o = panel.selected
    panel.partnerFS:SetText(o and o.buyer and ("|cFFFFFFFF" .. Comp.shortName(o.buyer) .. "|r") or "—")
    local ok = o and o.status == "accepted"
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
    if panel.subFS then panel.subFS:SetText("|c" .. Skin.hex.gold .. L["Commandes à livrer"] .. "|r") end

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

    -- Hook PASSIF de l'API d'envoi : mémorise le destinataire réel (anti-mismatch si le « À: » change).
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
