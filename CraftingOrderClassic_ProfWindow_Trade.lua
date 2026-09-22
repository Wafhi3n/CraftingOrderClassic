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

-- Bande du BAS réservée aux boutons de Blizzard. En élargissant le cadre natif (cf. _Camelot), ses
-- boutons « Créer »/« Créer tout » — ancrés au coin bas DROIT — se sont décalés SOUS notre colonne.
-- Rien de cliquable à nous ne doit les couvrir : c'est avec eux que l'enchanteur lance l'enchant.
-- Vécu le 2026-09-22 : l'indice posé là ne réagissait pas au clic, et masquait « Créer ».
local BOTTOM_BAND = 46

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

-- L'indice se recalcule seulement si l'offre ou la pièce a changé : la déduction relit TOUTES mes
-- recettes, et la vue se remplit à chaque rafraîchissement de la colonne.
-- Il occupe la 2ᵉ ligne de la rangée du bas — celle qui porte déjà la pièce posée. Une ligne de plus
-- ne rentrerait pas : la silhouette prend 400 px et la colonne n'en offre que ~440 une fois la bande
-- des boutons de Blizzard réservée.
local function fillHint(tp, loc, sub)
    local E, ET = COC.Enchant, COC.EnchantTrade
    local row = tp.row
    if not (row and E and ET) then return end
    local offer = ET.PartnerOffer()
    local key = tostring(loc) .. "|" .. ET.OfferKey(offer)
    if tp.hintKey == key then return end
    tp.hintKey = key
    if not loc then
        row.sub:SetText("|cFF888888" .. L["Rien de posé. Clique un emplacement pour lui demander sa pièce."] .. "|r")
        return
    end
    local guess = ET.GuessFromOffer(E:CraftsForEquipLoc(loc, sub), offer)
    if #guess == 1 then
        local e = guess[1]
        row.sub:SetText("|cFFE8B84B" .. string.format(L["Ses composants désignent : %s"],
                        E:ShortName(e.name, e.spellID) or e.name or "?") .. "|r")
    elseif #guess > 1 then
        row.sub:SetText("|cFF888888" .. string.format(
            L["Ses composants vont à %d enchantements — à toi de choisir."], #guess) .. "|r")
    elseif not hasEnchant(loc, sub) then
        row.sub:SetText("|cFF888888" .. L["Aucun enchantement connu pour cet emplacement."] .. "|r")
    else
        row.sub:SetText("")
    end
end

local function fillItem(tp)
    local link, loc, sub, icon = tradeItem()
    tp.itemLink = link
    tp.row.icon:SetTexture(icon or EMPTY_ICON)
    tp.row.icon:SetDesaturated(link == nil)
    tp.row.top:SetText(link or ("|cFF888888" .. L["Pièce à enchanter"] .. "|r"))
    fillHint(tp, link and loc or nil, sub)
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

-- ⚠️ ON N'OUVRE PLUS LA RECETTE D'UN CLIC, ET ON NE LE REFERA PAS. Livré à T5, ce clic appelait
-- `ProfessionsFrame.CraftingPage.RecipeList:SelectRecipe(info, true)` — le chemin d'un clic du
-- joueur. Mesuré le 2026-09-22 : la sélection porte alors NOTRE teinte, et le craft lancé ensuite
-- par le bouton de Blizzard la traîne jusqu'à `HandleEnchantSpellSelected` →
-- `OpenAndFilterCharacterFrame` → la fiche de personnage, qui compare une valeur SECRÈTE (la vie du
-- joueur) et LÈVE, nommément imputée à COC. Le même parcours sans notre clic passe de bout en bout.
-- `C_TradeSkillUI.OpenRecipe`, l'autre chemin, ne fait rien fenêtre déjà ouverte (elle attend une
-- réponse serveur qui ne vient pas). Il ne reste donc RIEN de sûr pour sélectionner une recette
-- depuis notre code : l'indice NOMME l'enchant, et le joueur clique la ligne dans la liste de
-- Blizzard — elle est déjà filtrée sur le bon emplacement, la bonne recette est à deux lignes.

-- La rangée du bas : l'icône de la pièce posée, son nom, et dessous l'indice. Cliquable quand
-- l'indice nomme UN enchant — le clic l'ouvre dans la fenêtre native (`OpenRecipe`, ordinaire).
local function buildRow(tp, well)
    -- Un CADRE, pas un bouton : plus rien à cliquer ici (voir ci-dessus), et une surbrillance de
    -- survol sur une ligne inerte ferait croire le contraire. Le survol sert l'infobulle de la pièce.
    local row = CreateFrame("Frame", nil, tp)
    row:SetHeight(44)
    row:EnableMouse(true)
    row:SetPoint("TOPLEFT", well, "BOTTOMLEFT", 0, -4)
    row:SetPoint("RIGHT", tp, "RIGHT", -6, 0)
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32); icon:SetPoint("TOPLEFT", 4, -4); icon:SetTexture(EMPTY_ICON)
    local top = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    top:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -1); top:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    top:SetJustifyH("LEFT"); top:SetWordWrap(false)
    local sub = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sub:SetPoint("TOPLEFT", top, "BOTTOMLEFT", 0, -3); sub:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    sub:SetJustifyH("LEFT"); sub:SetJustifyV("TOP")
    row.icon, row.top, row.sub = icon, top, sub
    row:SetScript("OnEnter", function(b)
        if not tp.itemLink then return end
        GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
        if pcall(GameTooltip.SetHyperlink, GameTooltip, tp.itemLink) then GameTooltip:Show() end
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    tp.row = row
end

-- Même emprise que les vues Plan de route et Manquantes (cf. PW:_BuildDockViews), moins la bande du
-- bas. Le titre, lui, monte dans l'EN-TÊTE, à la place laissée libre par les onglets : c'est de la
-- hauteur gagnée pour la silhouette, et ça se lit comme un titre de vue.
function PW:_BuildTradeView()
    if self.tradePanel or not self.ordScroll then return end
    local Ask = COC.EnchantTradeAsk
    if not (Ask and Ask.BuildSilhouette) then return end
    local host = self.ordScroll:GetParent()
    local tp = CreateFrame("Frame", nil, host)
    tp:SetPoint("TOPLEFT", host, "TOPLEFT", 0, -PW.TUNE.viewTop)
    tp:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, BOTTOM_BAND)
    tp:Hide()
    local title = tp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, self:_TabTop() - 3)
    title:SetJustifyH("LEFT"); title:SetWordWrap(false)
    tp.title = title
    -- Puits SANS fond : la silhouette se pose sur l'art natif de la page, comme le reste de la
    -- colonne. Un aplat gris clair ici faisait une boîte dans la fenêtre (retour user 2026-09-22).
    local well = CreateFrame("Frame", nil, tp)
    well:SetPoint("TOPLEFT", 6, -2); well:SetPoint("TOPRIGHT", -6, -2)
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
    buildRow(tp, well)
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
