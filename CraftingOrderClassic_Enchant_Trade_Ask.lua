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
-- ÉTAGE 2 (NON livré, délibérément) : si le partenaire porte COC, remplacer le chuchotement par une
-- invite chez lui + pose en un clic (PickupInventoryItem puis ClickTradeButton(TRADE_ENCHANT_SLOT)).
-- Contraintes à tenir le jour où on le fera : verrouiller en DUR sur l'emplacement 7 (viser 1..6 en
-- ferait un vecteur de VOL — le 7 est « ne sera pas échangé », donc rien n'y est volable), et EXIGER un
-- clic sur l'invite (déplacer l'arme équipée de quelqu'un sans son accord serait hostile). Ça demande un
-- verbe réseau + TRANSPORT_REV, donc un test 2 comptes — impossible aujourd'hui (cf. mémoire
-- coc-ptr-account-testing).
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

function Ask:Request(label)
    local target = GetUnitName and GetUnitName("NPC")
    if not (target and target ~= "" and SendChatMessage) then return end
    local now = GetTime and GetTime() or 0
    if now - lastAsk < 3 then return end
    lastAsk = now
    SendChatMessage(string.format(
        L["Mets ton objet « %s » dans l'emplacement du bas de la fenêtre d'échange (« ne sera pas échangé ») — je l'enchante, tu le gardes."],
        label), "WHISPER", nil, target)
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
    b:SetScript("OnClick", function(self) if self.live then Ask:Request(self.label) end end)
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
