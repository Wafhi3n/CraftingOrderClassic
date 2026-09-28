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

local function me() return COC.Api.PlayerName() end   -- nom RÉSEAU (« Prénom Nom » sur Forever)

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

-- Trace « mail » (/co trace, actif d'office sur Forever). Posée le 2026-09-28 quand « Remplir » a
-- joint 2 exemplaires pour une commande ×1 : chaque pile lue se nomme ici, et ce qui est réellement
-- joint se relit une demi-seconde plus tard. C'est elle qui a montré que la coupe joignait tout.
local function traceMail(msg) if COC.Trace then COC.Trace:Log("mail", msg) end end

local function traceAttached()
    local parts = {}
    for i = 1, (ATTACHMENTS_MAX_SEND or 12) do
        if HasSendMailItem(i) then
            local _, id, _, count = GetSendMailItem(i)
            parts[#parts + 1] = string.format("%d:%s×%s", i, tostring(id), tostring(count))
        end
    end
    traceMail("pièces jointes : " .. (#parts > 0 and table.concat(parts, " ") or "aucune"))
end

-- Une case VIDE d'un sac ORDINAIRE (famille 0) : un sac à herbes ou à minerai refuserait l'objet.
local function freeBagSlot(C)
    for bag = 0, (NUM_BAG_SLOTS or 4) do
        local free, family = C.GetContainerNumFreeSlots(bag)
        if (free or 0) > 0 and (family or 0) == 0 then
            for slot = 1, (C.GetContainerNumSlots(bag) or 0) do
                if not C.GetContainerItemID(bag, slot) then return bag, slot end
            end
        end
    end
    return nil
end

-- La coupe à la façon d'Auctionator sur Era (idée du user, 2026-09-28) : couper DANS LE SAC, vers une
-- case vide, puis joindre cette petite pile ENTIÈRE. Couper puis déposer directement dans le courrier
-- joignait la pile entière (cf. attachItem). On ne joint qu'après avoir RELU la case : l'objet et le
-- compte exacts, sinon rien. Si la case refuse l'objet, ClearCursor le rend à sa pile. Rend false si
-- la coupe n'a pas pu être tentée (pas d'API, pas de case libre) : l'appelant passe la main au joueur.
local function splitIntoBag(C, bag, slot, n, itemID)
    if not (C.SplitContainerItem and C.PickupContainerItem and C.GetContainerNumFreeSlots
            and C_Timer and C_Timer.After) then return false end
    local fb, fs = freeBagSlot(C)
    if not fb then traceMail("-> pas de case libre dans un sac ordinaire"); return false end
    C.SplitContainerItem(bag, slot, n)
    C.PickupContainerItem(fb, fs)
    if CursorHasItem and CursorHasItem() then ClearCursor() end
    traceMail(string.format("-> coupe %d de %d/%d vers la case vide %d/%d", n, bag, slot, fb, fs))
    C_Timer.After(0.3, function()
        local info = C.GetContainerItemInfo(fb, fs)
        local id, cnt = info and info.itemID, info and info.stackCount
        traceMail(string.format("case %d/%d après coupe : %s×%s", fb, fs, tostring(id), tostring(cnt)))
        if id == itemID and cnt == n and _G.SendMailFrame and _G.SendMailFrame:IsShown()
           and not (InCombatLockdown and InCombatLockdown()) then
            C.UseContainerItem(fb, fs)                    -- la petite pile, entière
        end
        C_Timer.After(0.3, traceAttached)
    end)
    return true
end

-- Joint l'objet crafté (itemID) au courrier jusqu'à `qty` exemplaires, depuis les sacs. N'ENVOIE RIEN
-- (le joueur relit puis clique Envoyer). Best-effort : objet absent des sacs ou 12 slots pleins → on
-- s'arrête sans erreur.
-- ⚠️ JAMAIS PLUS QUE DEMANDÉ : on joint les piles ENTIÈRES qui tiennent dans le reste. L'ancienne
-- coupe (SplitContainerItem puis ClickSendMailItemButton) a été RETIRÉE : relevé au banc le
-- 2026-09-28 (trace « mail »), elle joignait la pile ENTIÈRE, 9 puis 8 pour 1 voulu, que le dépôt
-- parte dans la même image ou 0,1 s plus tard. Un objet de trop part chez un autre joueur et ne
-- revient pas. Le reste passe par splitIntoBag ; à défaut, la coupe revient au joueur (Maj-clic) et
-- le chat lui dit combien. Une pile au compte illisible n'est pas jointe.
local function attachItem(itemID, qty)
    if not (itemID and _G.SendMailFrame and _G.SendMailFrame:IsShown()) then return end
    if InCombatLockdown and InCombatLockdown() then return end   -- UseContainerItem protégé en combat

    local C = C_Container
    if not (C and C.GetContainerNumSlots and C.GetContainerItemID and C.UseContainerItem) then return end
    local remaining, big = math.max(qty or 1, 1), nil
    for bag = 0, (NUM_BAG_SLOTS or 4) do
        for slot = 1, (C.GetContainerNumSlots(bag) or 0) do
            if remaining <= 0 then return end
            if C.GetContainerItemID(bag, slot) == itemID and freeAttachSlot() then
                local info = C.GetContainerItemInfo and C.GetContainerItemInfo(bag, slot)
                local count = info and info.stackCount
                traceMail(string.format("sac %d/%d : objet %d, pile lue %s, voulu %d",
                    bag, slot, itemID, tostring(count), remaining))
                if count and count <= remaining then
                    C.UseContainerItem(bag, slot)                 -- pile entière
                    remaining = remaining - count
                elseif count and not big then
                    big = { bag = bag, slot = slot }              -- une pile à couper, en dernier
                end
            end
        end
    end
    if remaining > 0 and big and splitIntoBag(C, big.bag, big.slot, remaining, itemID) then return end
    if remaining > 0 and big then
        traceMail(string.format("-> reste %d, coupe impossible : au joueur de couper", remaining))
        print("|cFF33DD88Crafting Order|r " .. string.format(
            L["Il en manque %d au courrier : sépare-les d'une pile toi-même (Maj-clic sur la pile), puis dépose-les."], remaining))
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
        if o.byStack and COC.Api.GetItemInfo then
            local stackSize = select(8, COC.Api.GetItemInfo(o.itemID))
            if stackSize and stackSize > 1 then wantN = wantN * stackSize end
        end
        traceMail(string.format("Remplir : commande %s, objet %s, qty %s, par pile %s -> %d voulu(s)",
            tostring(o.id), tostring(o.itemID), tostring(o.qty), tostring(o.byStack), wantN))
        attachItem(o.itemID, wantN)
        if C_Timer and C_Timer.After then C_Timer.After(0.5, traceAttached) end
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
