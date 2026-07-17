-- CraftingOrderClassic_Enchant_Trade.lua — greffon ENCHANTEMENT sur la fenêtre d'ÉCHANGE.
-- Quand le partenaire pose un objet dans l'emplacement « ne sera pas échangé » (TRADE_ENCHANT_SLOT),
-- on liste MES enchants applicables à CET emplacement — plus besoin de chercher dans toute la liste.
-- La liste est CLASSÉE par pertinence (cf. offerRank) : ce que ses RÉACTIFS posés dans l'échange
-- désignent d'abord, puis ce que mes sacs permettent, et seulement ensuite l'ordre catalogue (rang de
-- métier décroissant). Le surplus se parcourt à la MOLETTE — le classement rapproche la bonne recette,
-- il ne la garantit pas : rien ne doit rester hors d'atteinte.
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

-- Réactifs posés par le partenaire dans les emplacements ÉCHANGEABLES (1..MAX_TRADABLE_ITEMS) —
-- l'emplacement d'enchantement porte l'OBJET, jamais les mats. Rend { [itemID] = quantité }.
-- ⚠️ PAS de `GetTradeTargetItemInfo and GetTradeTargetItemInfo(i)` en assignation multiple : `and`
-- TRONQUE le multi-retour à UNE valeur → la quantité serait perdue (même piège qu'en tête d'ET.Update).
local function partnerOffer()
    local offer = {}
    if not (_G.TradeFrame and TradeFrame:IsShown() and GetTradeTargetItemLink) then return offer end
    for i = 1, (_G.MAX_TRADABLE_ITEMS or 6) do
        local link = GetTradeTargetItemLink(i)
        local id = link and tonumber(link:match("|Hitem:(%d+)"))
        if id then
            local qty = 1
            if GetTradeTargetItemInfo then
                local _, _, n = GetTradeTargetItemInfo(i)   -- name, texture, numItems, …
                qty = n or 1
            end
            offer[id] = (offer[id] or 0) + qty
        end
    end
    return offer
end

-- Pertinence d'un enchant face à ce que le partenaire pose sur la table :
--   3 = il fournit des mats ET la recette est couverte (sacs + offre) → c'est CE qu'il demande ;
--   2 = il fournit des mats, mais il en manque encore ;
--   1 = faisable avec MES sacs seuls ;  0 = le reste.
-- ⚠️ Les mats posés dans l'échange ne sont PAS encore dans mes sacs → `numAvailable` vaut 0 tant que
-- l'échange n'est pas validé : trier sur lui SEUL ne peut donc pas remonter la bonne recette (retour
-- terrain : mats de Fiery Weapon échangés, l'enchant n'était même pas suggéré — il tombait hors des
-- 8 lignes visibles, noyé sous les variantes de haut rang d'un enchanteur maxé).
local function offerRank(e, offer)
    local reags = COC.Craft:Reagents(e.index)
    if #reags == 0 then return ((e.numAvailable or 0) > 0) and 1 or 0 end
    local hit, covered = false, true
    for _, r in ipairs(reags) do
        local id = r.link and tonumber(r.link:match("|Hitem:(%d+)"))
        local given = (id and offer[id]) or 0
        if given > 0 then hit = true end
        if (r.have or 0) + given < (r.need or 0) then covered = false end
    end
    if hit then return covered and 3 or 2 end
    return covered and 1 or 0
end

-- Tri : pertinence d'abord, puis rang de métier décroissant (meilleure variante), puis nom — les deux
-- derniers reprennent l'ordre de CraftsForEquipLoc, qui a déjà posé `_lvl`.
local function rankCrafts(crafts)
    local offer = partnerOffer()
    for _, e in ipairs(crafts) do e._rank = offerRank(e, offer) end
    table.sort(crafts, function(a, b)
        if a._rank ~= b._rank then return a._rank > b._rank end
        if (a._lvl or 0) ~= (b._lvl or 0) then return (a._lvl or 0) > (b._lvl or 0) end
        return (a.name or "") < (b.name or "")
    end)
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

-- ⚠️ COMBAT — les lignes du puits héritent de SecureActionButtonTemplate : Show / Hide / SetAttribute
-- dessus lèvent ADDON_ACTION_BLOCKED en combat (constaté EN JEU, cf. l'en-tête de _ProfWindow_Detail
-- vers _SetCreateShown). On ne peint donc RIEN en combat, pas seulement les attributs : la fenêtre
-- d'échange survit au combat (TradeFrame n'a aucune garde de régénération), et nos déclencheurs y
-- tombent pour de vrai — CRAFT_UPDATE, TRADE_TARGET_ITEM_CHANGED, et surtout la MOLETTE, qui est
-- actionnable à tout moment. ET.Update est idempotent et ET:Start le rejoue à PLAYER_REGEN_ENABLED →
-- l'affichage se répare tout seul à la sortie de combat.
--
-- Remplit le puits à partir de `panel.offset` (fenêtre glissante — cf. la molette dans build()).
-- Grise la ligne dont les réactifs manquent DANS MES SACS (le bouton natif sera désactivé → le clic
-- sécurisé serait un no-op silencieux ; on le montre plutôt que de laisser croire à une panne).
-- ⚠️ Le gris se lit sur `numAvailable`, JAMAIS sur `_rank` : un enchant de rang 3 (mats posés dans
-- l'échange, pas encore reçus) n'est PAS craftable tant que l'échange n'est pas validé — le teindre en
-- disponible rendrait le no-op silencieux au lieu de l'expliquer. Il est en tête de liste, en gris :
-- « c'est bien celui-là, valide l'échange et il s'allume ».
local function fillRows(crafts)
    if InCombatLockdown and InCombatLockdown() then return end
    panel.rows = panel.rows or {}
    local total = #crafts
    local maxOff = math.max(0, total - MAXROWS)
    panel.offset = math.min(math.max(panel.offset or 0, 0), maxOff)
    local off = panel.offset
    local n = math.min(total - off, MAXROWS)
    for i = 1, n do
        local r = panel.rows[i] or makeRow(i); panel.rows[i] = r
        local e = crafts[i + off]
        r.craftIndex, r.tipIndex = e.index, e.index
        local short = (COC.Enchant and COC.Enchant:ShortName(e.name, e.spellID)) or e.name or "?"
        local avail = (e.numAvailable or 0) > 0
        r:SetText(short)
        r.text:SetTextColor(avail and 0.941 or 0.45, avail and 0.776 or 0.45, avail and 0.455 or 0.45)
        r:SetAttribute("type", "click")
        r:SetAttribute("clickbutton", _G.CraftCreateButton)
        r:Show()
    end
    for i = n + 1, #panel.rows do panel.rows[i]:Hide() end
    if total > MAXROWS then
        panel.moreFS:SetText(string.format(L["Molette : %d/%d"], off + n, total)); panel.moreFS:Show()
    else
        panel.moreFS:Hide()
    end
end

local function hideRows()
    if InCombatLockdown and InCombatLockdown() then return end   -- lignes sécurisées, cf. fillRows
    for _, r in ipairs(panel.rows or {}) do r:Hide() end
    panel.moreFS:Hide()
end

-- Masquer le panneau qui HÉBERGE des lignes sécurisées AFFICHÉES lève aussi ADDON_ACTION_BLOCKED en
-- combat (même constat en jeu que _ProfWindow_Detail, qui escamote alors PW via SetAlpha). L'alpha,
-- lui, n'est pas protégé → on escamote, et le vrai Hide se rejoue à la sortie de combat (ET.Update
-- est rappelé sur PLAYER_REGEN_ENABLED et repasse par ici).
local function hidePanel()
    if not panel then return end
    if InCombatLockdown and InCombatLockdown() then
        panel:SetAlpha(0); panel:EnableMouse(false); return
    end
    panel:SetAlpha(1); panel:EnableMouse(true); panel:Hide()
end

local function showPanel()
    panel:SetAlpha(1); panel:EnableMouse(true); panel:Show()
end

function ET.Update()
    if not panel then return end
    local link = targetEnchantLink()
    -- Rien de posé : au lieu de disparaître, on passe la main à la silhouette « demande-lui une pièce »
    -- (_Enchant_Trade_Ask) — les deux panneaux partagent l'ancrage, un SEUL est visible à la fois.
    if not link then
        panel.crafts = nil; hidePanel()
        if COC.EnchantTradeAsk then COC.EnchantTradeAsk:Update() end
        return
    end
    if COC.EnchantTradeAsk then COC.EnchantTradeAsk:Hide() end
    -- ⚠️ PAS de `GetItemInfoInstant and GetItemInfoInstant(link)` en assignation multiple : `and` TRONQUE
    -- le multi-retour à UNE valeur → equipLoc devenait nil (« aucun enchant pour cet emplacement »).
    -- `subclass` (7ᵉ retour) sert à reconnaître un BÂTON parmi les armes à 2 mains (cf. CraftsForEquipLoc).
    local equipLoc, subclass
    if GetItemInfoInstant then
        local _, _, _, loc, _, _, sub = GetItemInfoInstant(link)
        equipLoc, subclass = loc, sub
    end
    local crafts = COC.Enchant and COC.Enchant:CraftsForEquipLoc(equipLoc, subclass)
    panel.partnerFS:SetText("|cFFFFFFFF" .. Comp.shortName((GetUnitName and GetUnitName("NPC")) or "?") .. "|r")
    panel.itemFS:SetText(link)
    if not (COC.Craft and COC.Craft:IsCraftOpen()) then      -- session de craft fermée : on ne peut rien lire
        panel.crafts = nil
        hideRows(); panel.hintFS:SetText("|cFFFF8855" .. L["Ouvre ta fenêtre d'Enchantement."] .. "|r")
        panel.hintFS:Show(); showPanel(); return
    end
    if not (crafts and #crafts > 0) then
        panel.crafts = nil
        hideRows(); panel.hintFS:SetText("|cFF888888" .. L["Aucun enchantement connu pour cet emplacement."] .. "|r")
        panel.hintFS:Show(); showPanel(); return
    end
    -- Objet ciblé changé → on repart en haut : l'offset d'un AUTRE objet ne veut plus rien dire.
    if link ~= panel.lastLink then panel.offset = 0; panel.lastLink = link end
    rankCrafts(crafts)
    panel.crafts = crafts       -- mémorisé pour la molette (qui re-remplit sans tout relire)
    panel.hintFS:Hide()
    fillRows(crafts)
    showPanel()
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
    -- Le surplus DOIT rester atteignable : « +N autre(s) » n'était qu'un texte MORT → au-delà de la 8e
    -- ligne, un enchant était littéralement impossible à choisir (retour terrain : Fiery Weapon). Molette
    -- plutôt qu'une barre : le pool de lignes existe déjà, on ne fait que décaler la fenêtre dedans.
    -- Les lignes ne captent PAS la molette (EnableMouseWheel absent sur les boutons) → l'event tombe ici.
    -- Le compteur sort SOUS le puits : ancré dedans (défaut MakePanel), il chevauchait la dernière
    -- ligne — invisible tant qu'il était rare, gênant maintenant qu'il s'affiche dès 9 enchants.
    panel.moreFS:ClearAllPoints()
    panel.moreFS:SetPoint("TOPRIGHT", panel.well, "BOTTOMRIGHT", -2, -3)
    panel.well:EnableMouseWheel(true)
    panel.well:SetScript("OnMouseWheel", function(_, delta)
        local crafts = panel.crafts
        if not crafts then return end
        local maxOff = math.max(0, #crafts - MAXROWS)
        local off = math.min(math.max((panel.offset or 0) - delta, 0), maxOff)
        if off ~= panel.offset then panel.offset = off; fillRows(crafts) end
    end)
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
        if ev == "TRADE_CLOSED" then
            hidePanel()   -- escamotage à l'alpha si on est en combat, vrai Hide au rejeu de sortie
            if COC.EnchantTradeAsk then COC.EnchantTradeAsk:Hide() end
            return
        end
        if ev == "TRADE_SHOW" and panel and _G.TradeFrame then    -- ancré à DROITE du natif (le greffon
            panel:ClearAllPoints()                                -- Commandes occupe le dessous)
            panel:SetPoint("TOPLEFT", TradeFrame, "TOPRIGHT", 4, 0)
        end
        -- ⚠️ Sortie de combat : en combat, fillRows/hideRows/hidePanel ne peignent RIEN (lignes
        -- sécurisées → Show/Hide/SetAttribute verrouillés, cf. l'en-tête de fillRows), ce qui laisse
        -- l'affichage périmé : lignes non câblées (clic = no-op silencieux), ou panneau simplement
        -- escamoté à l'alpha alors que l'échange est clos. ET.Update() est idempotent → un rejeu
        -- IMMÉDIAT ici répare tout (pas de coalescence : 0,1 s plus tard on pourrait être RE-rentré en
        -- combat et rater la fenêtre).
        if ev == "PLAYER_REGEN_ENABLED" then ET.Update() else updateSoon() end
    end)
end
