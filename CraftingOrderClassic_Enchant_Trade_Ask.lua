-- CraftingOrderClassic_Enchant_Trade_Ask.lua — greffon ÉCHANGE : « demande-lui la pièce ».
-- L'ÉTAT VIDE de _Enchant_Trade : tant que le partenaire n'a rien posé dans l'emplacement « ne sera pas
-- échangé », l'enchanteur ne voyait RIEN (panel:Hide()) — or c'est précisément le moment où le client
-- débutant ignore que cet emplacement existe. On y met la silhouette : clic sur un emplacement → on lui
-- chuchote de poser CETTE pièce-là. C'est un bouton « explique l'emplacement d'enchant au débutant »,
-- pas de l'automatisation.
--
-- CHUCHOTEMENT, jamais /s : le destinataire est en face et il est le SEUL concerné — écrire en public
-- spammerait tout le district des enchanteurs à chaque clic, à rebours de la discipline anti-spam de COC
-- (_Moderation, /co mutes). ⚠️ Le message part dans NOTRE langue : on ne peut pas connaître la locale du
-- partenaire. Inévitable pour tout message inter-joueurs — ne pas « corriger ».
--
-- La silhouette (disposition + dérivation catalogue + désaturation des emplacements morts) est celle de
-- l'onglet Commande, réutilisée via COC.UI.DOLL — zéro clé de locale pour le chrome d'emplacement, et un
-- seul endroit à corriger quand une couche saisonnière bouge les emplacements enchantables.
--
-- ÉTAGE 2 (livré 2026-07-19, après validation en jeu de l'étage 1 à 2 joueurs) : le clic envoie AUSSI
-- le verbe ASKE|<slot> en whisper addon. Si le partenaire porte COC, une invite s'affiche chez lui :
-- UN clic (= hardware event + consentement) et la pièce se pose (PickupInventoryItem puis
-- ClickTradeButton). Un client sans COC / trop vieux ignore le verbe (dispatch « verbe inconnu ») et
-- garde le chuchotement texte — les deux partent toujours, dégradation propre sans négocier de version.
-- Invariants de SÉCURITÉ (ne pas défaire) : la pose vise l'emplacement 7 EN DUR (TRADE_SAFE_SLOT,
-- jamais lu du payload — viser 1..6 en ferait un vecteur de VOL ; le 7 est « ne sera pas échangé »,
-- rien n'y est volable) ; le clic sur l'invite est EXIGÉ (déplacer l'arme équipée de quelqu'un sans
-- son accord serait hostile) ; le verbe n'est accepté QUE d'un émetteur = partenaire d'échange OUVERT.
-- ClickTradeButton et PickupInventoryItem sont NON protégées (preuve : boutons ItemButtonTemplate
-- ordinaires dans TradeFrame.xml:148 et PaperDollFrame.lua:804 du source Blizzard Era).
-- Pas d'étape de déséquipement à prévoir : une pièce PORTÉE se glisse directement dans l'emplacement 7
-- (retour user 2026-07-17), et `PickupInventoryItem` fait ce déséquipement implicitement. ⚠️ À ne pas
-- confondre avec « Enchanter équipé » (_ProfWindow_Detail), qui passe par l'attribut sécurisé
-- `target-slot` : là, l'objet ne bouge JAMAIS — mais c'est MON objet, pas celui d'en face.
-- ⚠️ Conséquence à assumer : l'objet quitte réellement le personnage du partenaire pendant l'échange
-- (il est sans arme le temps de l'enchant). Normal — c'est déjà le flux manuel — mais ça reste une
-- raison de plus d'EXIGER son clic : l'addon ne déséquipe personne tout seul.

local COC  = CraftingOrderClassic
local Comp = COC.Companion
local Skin = COC.UI.Skin
local L    = COC.L

local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)

local Ask = {}
COC.EnchantTradeAsk = Ask

local panel

-- COC.UI.DOLL est posé au CHARGEMENT de _UI_Post_Paperdoll ; on ne le lit qu'au RUNTIME pour rester
-- insensible à l'ordre exact des .toc (même précaution que le paperdoll vis-à-vis de COC.Enchant).
local function doll() return COC.UI and COC.UI.DOLL end

local function isEnchanter()
    local D = COC.Directory
    return (D and D.mySkills and D.mySkills["Enchanting"]) ~= nil
end

-- ------------------------------------------------------------------
-- Le message
-- ------------------------------------------------------------------
-- Garde anti-rafale : un double-clic ne doit pas partir deux fois. 3 s suffisent — le clic EST un
-- hardware event, il n'y a pas de throttle Blizzard à contourner, juste nous à discipliner.
local lastAsk = 0

function Ask:Request(label, token)
    local target = GetUnitName and GetUnitName("NPC")
    if not (target and target ~= "" and SendChatMessage) then return end
    local now = GetTime and GetTime() or 0
    if now - lastAsk < 3 then return end
    lastAsk = now
    SendChatMessage(string.format(
        L["Mets ton objet « %s » dans l'emplacement du bas de la fenêtre d'échange (« ne sera pas échangé ») — je l'enchante, tu le gardes."],
        label), "WHISPER", nil, target)
    -- Étage 2 : le même clic porte le verbe ASKE (invite un-clic si le partenaire a COC). Toujours
    -- émis — un client sans COC l'ignore, et le chuchotement ci-dessus reste l'explication humaine.
    if CraftLink and CraftLink.Send and token then
        CraftLink:Send("ASKE|" .. token, "whisper", target)
    end
    if COC.UI and COC.UI.Toast then
        COC.UI:Toast(string.format(L["Demande envoyée à %s."], Comp.shortName(target)))
    end
end

-- ------------------------------------------------------------------
-- La silhouette
-- ------------------------------------------------------------------
local function makeSlot(root, def, D)
    local tex, label = D.SlotArt(def.slot)
    local b = Skin.MakeIconButton(root, D.ICON, tex)
    b:SetFrameLevel(root:GetFrameLevel() + 4)   -- au-dessus du modèle 3D (frame sœur, cf. build)
    b.def, b.label = def, label
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.label, 1, 1, 1)
        if self.live then GameTooltip:AddLine(L["Clic : lui demander cette pièce."], 0.6, 0.6, 0.6) end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    b:SetScript("OnClick", function(self)
        if self.live then Ask:Request(self.label, self.def and self.def.slot) end
    end)
    return b
end

local function buildRun(root, list, point, x, y, dx, dy, D, store)
    for i, def in ipairs(list) do
        local b = makeSlot(root, def, D)
        b:SetPoint(point, root, point, x + (i - 1) * dx, y - (i - 1) * dy)
        store[#store + 1] = b
    end
end

-- Désature ce que le catalogue de la couche courante ne sert pas — idempotent, rejoué à chaque
-- affichage (le catalogue de la lib peut n'être pas prêt au build).
function Ask:Refresh()
    local D = doll(); if not D then return end
    for _, b in ipairs(self.btns or {}) do
        local live = #D.LiveWords(b.def) > 0
        b.live = live
        b.icon:SetDesaturated(not live)
        b.icon:SetAlpha(live and 1 or 0.45)
    end
end

local function build()
    if panel then return end
    local D = doll(); if not D then return end
    local wellH = 10 + 8 * D.STEP + 8 + D.ICON + 10
    panel = Comp.MakePanel("COCEnchantAskPanel", UIParent, 240, 0)
    panel:SetHeight(66 + wellH + 12)
    panel.subFS:SetText("|c" .. Skin.hex.gold .. L["Demande-lui une pièce"] .. "|r")
    panel.well:ClearAllPoints()
    panel.well:SetPoint("TOPLEFT", 12, -66); panel.well:SetPoint("TOPRIGHT", -12, -66)
    panel.well:SetHeight(wellH)

    -- Modèle 3D au centre, DERRIÈRE les icônes : c'est lui qui fait la silhouette. Ici c'est le
    -- PARTENAIRE (unité « NPC » pendant un échange), pas moi — on demande SON équipement, montrer mon
    -- perso serait un contresens. Purement décoratif : sous pcall, la vue reste utilisable s'il ne rend rien.
    local m = CreateFrame("PlayerModel", nil, panel.well)
    m:SetPoint("TOPLEFT", 50, -10); m:SetPoint("BOTTOMRIGHT", -50, 46)
    m:SetFrameLevel(panel.well:GetFrameLevel())
    panel.model = m

    Ask.btns = {}
    buildRun(panel.well, D.LEFT,  "TOPLEFT",  10, -10, 0, D.STEP, D, Ask.btns)
    buildRun(panel.well, D.RIGHT, "TOPRIGHT", -10, -10, 0, D.STEP, D, Ask.btns)
    local w3 = 3 * D.ICON + 2 * 6
    buildRun(panel.well, D.BOTTOM, "TOPLEFT", (240 - 24 - w3) / 2, -(10 + 8 * D.STEP + 8),
             D.ICON + 6, 0, D, Ask.btns)
    panel:Hide()
end

-- ------------------------------------------------------------------
-- Étage 2, côté RECEVEUR : un enchanteur me demande une pièce (verbe ASKE)
-- ------------------------------------------------------------------
-- ⚠️ EN DUR, jamais lu du payload (anti-vol, cf. en-tête) : 7 = TRADE_ENCHANT_SLOT Blizzard,
-- l'emplacement « ne sera pas échangé ».
local TRADE_SAFE_SLOT = 7

-- Jeton d'emplacement du payload → def de la silhouette. Whitelist DOLL au runtime : un payload
-- forgé avec un jeton hors silhouette est jeté ici.
local function slotDef(token)
    local D = doll()
    if not (D and token) then return nil end
    for _, list in ipairs({ D.LEFT, D.RIGHT, D.BOTTOM }) do
        for _, def in ipairs(list) do if def.slot == token then return def end end
    end
end

-- Nom court du partenaire d'échange COURANT, ou nil hors échange ouvert.
local function tradePartner()
    if not (_G.TradeFrame and TradeFrame:IsShown()) then return nil end
    local n = GetUnitName and GetUnitName("NPC")
    return (n and n ~= "") and Comp.shortName(n) or nil
end

-- Pose effective (OnAccept du popup : le clic EST le hardware event ET le consentement). TOUT est
-- re-vérifié — l'état a pu changer entre l'invite et le clic (échange fermé, pièce déséquipée,
-- curseur occupé, emplacement pris) : dans le doute, ne rien poser du tout.
local function placeItem(data)
    if not (data and tradePartner() == data.from) then return end
    if GetCursorInfo and GetCursorInfo() then return end     -- jamais écraser un curseur plein
    if GetTradePlayerItemInfo and GetTradePlayerItemInfo(TRADE_SAFE_SLOT) then return end
    local inv = GetInventorySlotInfo and GetInventorySlotInfo(data.token)
    if not (inv and GetInventoryItemLink and GetInventoryItemLink("player", inv)) then return end
    PickupInventoryItem(inv)                                 -- déséquipe implicitement (pièce portée)
    if CursorHasItem and not CursorHasItem() then return end
    ClickTradeButton(TRADE_SAFE_SLOT)
end

-- ASKE reçu → invite. Silencieux dans TOUS les cas dégradés (pas d'échange avec l'émetteur, rien
-- d'équipé à cet emplacement, emplacement 7 déjà pris) : le chuchotement texte de l'étage 1 arrive
-- de toute façon et reste l'explication humaine.
local lastAskFrom = {}
function Ask:OnAsk(sender, message)
    -- %w et pas %a : Finger0Slot/Finger1Slot (anneaux) portent un CHIFFRE — %a les jetterait en
    -- silence le jour où une couche de données active l'enchant d'anneau.
    local def = slotDef((message or ""):match("^ASKE|(%w+)$"))
    local from = sender and Comp.shortName(sender)
    if not (def and from and tradePartner() == from) then return end
    local now = GetTime and GetTime() or 0
    if now - (lastAskFrom[from] or 0) < 5 then return end    -- anti-spam d'invites par émetteur
    lastAskFrom[from] = now
    local inv = GetInventorySlotInfo and GetInventorySlotInfo(def.slot)
    local link = inv and GetInventoryItemLink and GetInventoryItemLink("player", inv)
    if not link then return end
    if GetTradePlayerItemInfo and GetTradePlayerItemInfo(TRADE_SAFE_SLOT) then return end
    if not (StaticPopupDialogs and StaticPopup_Show) then return end
    -- Une invite à la fois : re-recevoir ASKE pendant qu'une invite est affichée ne doit pas empiler
    -- de popups (le throttle par émetteur ne protège pas de la republication toutes les 5 s).
    if StaticPopup_Visible and StaticPopup_Visible("COC_ENCHANT_ASK") then return end
    StaticPopupDialogs["COC_ENCHANT_ASK"] = StaticPopupDialogs["COC_ENCHANT_ASK"] or {
        text = "%s", button1 = L["Poser la pièce"], button2 = L["Ignorer"],
        OnAccept = function(_, data) placeItem(data) end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopup_Show("COC_ENCHANT_ASK", string.format(
        L["%s propose d'enchanter : %s. Poser la pièce dans l'emplacement « ne sera pas échangé » ? Rien n'est donné — tu la récupères enchantée."],
        from, link), nil, { from = from, token = def.slot })
end

if CraftLink and CraftLink.RegisterHandler then
    CraftLink:RegisterHandler("ASKE", function(sender, message) Ask:OnAsk(sender, message) end)
end

-- ------------------------------------------------------------------
-- Pilotage (appelé par _Enchant_Trade, qui possède les events d'échange)
-- ------------------------------------------------------------------
function Ask:Hide() if panel then panel:Hide() end end

-- Visible SEULEMENT si : échange ouvert, je suis enchanteur, et il n'a encore rien posé. Pas besoin de
-- la fenêtre d'Enchantement ici : demander une pièce ne lit aucune recette (le niveau de métier, lui,
-- est lisible à tout moment — cf. Directory_Skills).
function Ask:Update()
    if not (_G.TradeFrame and TradeFrame:IsShown() and isEnchanter()) then self:Hide(); return end
    build()
    if not panel then return end
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", TradeFrame, "TOPRIGHT", 4, 0)
    panel.partnerFS:SetText("|cFFFFFFFF" .. Comp.shortName((GetUnitName and GetUnitName("NPC")) or "?") .. "|r")
    if panel.model then
        if not pcall(function() panel.model:SetUnit("NPC") end) then panel.model:Hide() else panel.model:Show() end
    end
    self:Refresh()
    panel:Show()
end
