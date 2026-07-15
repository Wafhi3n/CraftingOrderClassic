-- CraftingOrderClassic_ProfWindow.lua — fenêtre métier custom 3 colonnes (migration depuis
-- Guild Economy) : Recettes | Détail+Craft | Commandes du métier. Remplace la fenêtre Blizzard
-- (neutralisée, jamais Hide() pour garder la session lisible). Colonnes dans _Recipes / _Detail ;
-- la colonne Commandes vit ici (réutilise le carnet/entrantes du métier ouvert).
--
-- Vue métier par DÉFAUT (maquette designer) : PW:IsEnabled() vrai sauf COC.db.profWindow == false.
-- `/co profwindow` bascule custom ↔ « Vue Blizzard » (opt-out). Quand la vue custom est active, désactive
-- le takeover de Guild Economy (TradeScannerDB.replaceProfWindow=false) → jamais deux fenêtres à la fois.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L
local PW   = {}
COC.ProfWindow = PW

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

PW.FRAME_W, PW.FRAME_H = 792, 500   -- FRAME_W = repli : SURCHARGÉ par la SPEC (x2 + 10, cf. _Layout)
PW.HEADER_H = 56
PW.PAD = 14
-- (Colonnes : SPEC déclarative dans _ProfWindow_Layout.lua — zones via PW:Sec(id), frontières
--  verticales posées par le générateur. Les ex-COL_W/GAP vivent dans la SPEC.)

local GATHER = { Mining = true, Herbalism = true, Skinning = true, Fishing = true }

-- Sais-je honorer cette commande ? (récolte = j'ai le skill ; craft = je connais la recette)
function PW.CanFulfill(o)
    local prof = o.profession; if not prof then return nil end
    if PW.rerollKey then return PW:RerollKnows(o) end   -- vue reroll : lit la partition du reroll, pas le perso courant
    local c, D = CL(), COC.Directory
    if GATHER[prof] then return (D and D.mySkills and D.mySkills[prof]) ~= nil end
    if not c then return nil end
    if o.itemID  and c:IKnowRecipeForItem(prof, o.itemID)  then return true end
    if o.spellID and c:IKnowRecipeBySpell(prof, o.spellID) then return true end
    return false
end

-- ------------------------------------------------------------------
-- Neutralisation de la frame native (garde la session vivante)
-- ------------------------------------------------------------------
local NATIVE = {}
local uiPanelDetached = false
local function detachUIPanels()
    if uiPanelDetached then return end
    uiPanelDetached = true
    if _G.UIPanelWindows then UIPanelWindows["TradeSkillFrame"] = nil; UIPanelWindows["CraftFrame"] = nil end
end
local function neutralize(frame, key)
    if not frame then return end
    if not NATIVE[key] then NATIVE[key] = { alpha = frame:GetAlpha(), mouse = frame:IsMouseEnabled() } end
    frame:SetAlpha(0); frame:EnableMouse(false)
end
local function restore(frame, key)
    if not frame or not NATIVE[key] then return end
    frame:SetAlpha(NATIVE[key].alpha or 1); frame:EnableMouse(NATIVE[key].mouse ~= false); NATIVE[key] = nil
end
function PW:NeutralizeNative()
    detachUIPanels(); neutralize(_G.TradeSkillFrame, "trade"); neutralize(_G.CraftFrame, "craft"); if COC.Craft then COC.Craft:MuteNativeReagents(true) end
end
function PW:RestoreNative() restore(_G.TradeSkillFrame, "trade"); restore(_G.CraftFrame, "craft"); if COC.Craft then COC.Craft:MuteNativeReagents(false) end end

-- ------------------------------------------------------------------
-- Construction du shell
-- ------------------------------------------------------------------
function PW:_BuildHeader(f)
    -- Titre = la barre native (f.TitleText, alimentée via self.titleFS). L'ancien wordmark « Crafting
    -- Order » du coin est retiré (portrait + titre portent l'identité).
    self.titleFS = f.TitleText

    -- Rangée de contrôles SOUS la barre de titre (y −28..−48, HEADER_H = 56 inchangé). À gauche, x = 64 :
    -- le médaillon du portrait déborde dans le cadre (~58 px de large jusqu'à y ≈ −53) → on le contourne.
    local vanilla = Skin.MakeGoldButton(f, 96, 20, L["Vue Blizzard"])
    vanilla:SetPoint("TOPRIGHT", -24, -1 )
    vanilla:SetScript("OnClick", function() PW:SetEnabled(false) end)
    self.vanillaBtn = vanilla

    -- Toggle « Manquantes » : bascule la liste de gauche entre les recettes APPRISES (défaut) et celles
    -- qui MANQUENT au perso, avec leur source (formateur/butin/quête…). Alimenté par le pont MTSL ;
    -- masqué si l'addon n'est pas là (dépendance molle) et hors mode plein (n'a de sens que sur ton métier).
    local missing = Skin.MakeGoldButton(f, 110, 20, L["Manquantes"])
    missing:SetPoint("RIGHT", vanilla, "LEFT", 0, 0)
    missing:SetScript("OnClick", function() PW:_ToggleMissing() end)
    missing:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText(PW.missingMode and L["Masque les recettes non apprises — clic pour revenir."]
            or L["Affiche AUSSI les recettes non apprises (en rouge) et où les obtenir."], 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    missing:SetScript("OnLeave", GameTooltip_Hide)
    missing:Hide()
    self.missingBtn = missing

    -- Toggle « Chercher du travail » (LFW) : signale au royaume que tu cherches du travail dans le métier
    -- OUVERT (donc forcément le tien). Masqué hors vue pleine (reroll/compact = pas ton perso courant).
    local lfw = Skin.MakeGoldButton(f, 150, 18, L["Chercher du travail"])
    lfw:SetPoint("TOPLEFT", 56, -1)
    lfw:SetScript("OnClick", function() PW:_ToggleLFW() end)
    lfw:SetScript("OnEnter", function(b)
        local D = COC.Directory; local on = D and D.MyLFW and D:MyLFW() == PW.profKey
        GameTooltip:SetOwner(b, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText(on and L["Tu cherches du travail — clic pour arrêter."]
            or L["Signale au royaume que tu cherches du travail dans ce métier."], 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    lfw:SetScript("OnLeave", GameTooltip_Hide)
    lfw:Hide()   -- caché jusqu'au 1er _SyncLFWBtn (évite un flash en vue reroll/compact)
    self.lfwBtn = lfw

    -- Engrenage de config de l'OFFRE LFW (composants fournis, commission) — cf. _ProfWindow_LFW.lua.
    if self._BuildLFWGear then self:_BuildLFWGear(f, lfw) end

    -- (Bouton fermer : le natif de MakeWindow porte la logique dock/CloseCraft via opts.onClose.)
    Skin.MakeSeparator(f, -(self.HEADER_H - 2))
end

-- Le médaillon suit le métier affiché (icônes de sort 64×64 → chemin heureux de SetWindowPortrait).
function PW:_SyncPortrait()
    Skin.SetWindowPortrait(self.frame, Skin.ProfIcon(self.profKey) or Skin.tex.scroll)
end

-- ⚠️ Titre + rang dans UNE SEULE chaîne (jamais deux FontStrings séparées). `f.TitleText` natif a ses
-- ancres LEFT/RIGHT FIXÉES sur le CADRE (PortraitFrameTemplate : x=60 / x=-60), pas sur l'étendue
-- réelle du texte affiché — ancrer un 2ᵉ FontString sur son bord RIGHT le colle donc TOUJOURS près du
-- bouton fermer, quelle que soit la longueur du titre (vécu : « 250 » collé au X). En les fusionnant,
-- le rang hérite du centrage natif du titre et suit son étendue réelle.
function PW:_SetTitle(label, suffix)
    self.titleFS:SetText(suffix and (label .. "  " .. suffix) or label)
end

-- Bascule mon statut LFW pour le métier OUVERT (mien). Ignoré hors vue pleine (reroll = pas mon perso).
function PW:_ToggleLFW()
    local D = COC.Directory
    if not (D and D.SetLFW and self.profKey) or self.rerollKey then return end
    if D.MyLFW and D:MyLFW() == self.profKey then D:SetLFW(nil) else D:SetLFW(self.profKey) end
    self:_SyncLFWBtn(); if self.RefreshRecipes then self:RefreshRecipes() end   -- + colonne de cases « proposer »
end

-- Bascule liste apprises <-> manquantes. Réinitialise la sélection (une recette d'un mode n'existe pas
-- dans l'autre) puis rafraîchit liste + détail. Sans effet si MTSL absent.
function PW:_ToggleMissing()
    if not (COC.MTSL and COC.MTSL:IsAvailable()) or self.rerollKey then return end
    self.missingMode = not self.missingMode
    self.selectedKey, self.selectedIndex = nil, nil
    self:_SyncMissingBtn()
    if self.RefreshRecipes then self:RefreshRecipes() end
    if self.RefreshDetail  then self:RefreshDetail()  end
end

-- Le bouton « Manquantes » n'apparaît qu'en VUE PLEINE d'un métier À MOI et si MTSL est chargé. Libellé
-- enrichi du nombre de recettes manquantes. Désarme le mode si le contexte ne s'y prête plus (reroll…).
function PW:_SyncMissingBtn()
    local b = self.missingBtn; if not b then return end
    local ok = COC.MTSL and COC.MTSL:IsAvailable()
    local show = ok and self.profKey and not self.rerollKey and not self._compact and not self.docked
    b:SetShown(show and true or false)
    if not show then self.missingMode = false; return end
    local n = self:MissingCount()   -- compte DÉDUPÉ (écarte les faux manquants MTSL déjà appris)
    b:SetText(self.missingMode and L["‹ Apprises seules"] or string.format(L["Manquantes (%d)"], n))
    if b.SetSelected then b:SetSelected(self.missingMode and true or false) end
end

-- Le bouton LFW n'a de sens qu'en VUE PLEINE d'un métier À MOI (pas reroll, pas compact/dock). État
-- sélectionné = je cherche déjà du travail dans CE métier.
function PW:_SyncLFWBtn()
    local b = self.lfwBtn; if not b then return end
    local D = COC.Directory
    local show = self.profKey and not self.rerollKey and not self._compact and D and D.SetLFW
    b:SetShown(show and true or false)
    if show then b:SetSelected(D.MyLFW and D:MyLFW() == self.profKey and true or false) end
    -- L'engrenage + le panneau de config suivent la même portée (et se repeignent au changement de métier).
    if self._SyncLFWConfig then self:_SyncLFWConfig(show and true or false) end
end

function PW:Build()
    if self.frame then return end
    -- Chrome Blizzard natif via le kit (drag + clamp + strata + SetToplevel/Raise gérés là-bas).
    -- Le bouton fermer natif porte NOTRE logique : dock → on referme juste le panneau (la native reste
    -- ouverte) ; sinon on ferme la session de craft native avec la fenêtre.
    local f = Skin.MakeWindow("CraftingOrderProfWindow", self.FRAME_W, self.FRAME_H, {
        pos = COC.db and COC.db.profWinPos,                -- position persistée (drag) ou centre par défaut
        onMoved = function(p, rp, x, y) if COC.db then COC.db.profWinPos = { p, rp, x, y } end end,
        onClose = function()
            if PW.docked then PW:CloseDock(); return end
            if COC.Craft and COC.Craft:IsCraftOpen() then if CloseCraft then CloseCraft() end
            elseif CloseTradeSkill then CloseTradeSkill() end
            PW:Hide()
        end,
    })
    self.frame = f
    self:_BuildHeader(f)

    -- Colonnes = zones de la SPEC (cf. _ProfWindow_Layout.lua) : une surface, frontières calculées —
    -- plus de puits par colonne ni d'ancrages en chaîne (l'« escalier » est impossible par construction).
    self:_BuildSections(f)
    local recCol, detCol, ordCol = self:Sec("recipes"), self:Sec("detail"), self:Sec("orders")
    self.recCol, self.detCol, self.ordCol = recCol, detCol, ordCol

    if self._BuildRecipes then self:_BuildRecipes(recCol) end
    if self._BuildDetail  then self:_BuildDetail(detCol)  end
    if self._BuildOrders then self:_BuildOrders(ordCol) else self:_OrdersModuleMissing(ordCol) end
end

-- ------------------------------------------------------------------
-- Colonne DROITE : commandes du métier (cartes par demandeur + actions).
-- PW:_BuildOrders / _OrdCard / _FillCard / _CardActions / RefreshOrders sont définis dans
-- CraftingOrderClassic_ProfWindow_Orders.lua (chargé APRÈS ce fichier).
-- ------------------------------------------------------------------

-- Garde-fou : si ce fichier compagnon n'est pas chargé (cas typique = .lua ajouté au .toc et pas encore
-- pris en compte — WoW ne charge un fichier nouvellement listé qu'au prochain DÉMARRAGE COMPLET, pas sur
-- un simple /reload), on affiche un message dans la colonne et on prévient une fois, sans planter.
function PW:_OrdersModuleMissing(col)
    local fs = col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", 12, -12); fs:SetPoint("TOPRIGHT", -12, -12); fs:SetJustifyH("LEFT")
    fs:SetText("|cFFE8B84B" .. L["Commandes"] .. "|r\n\n|cFFFF7777"
        .. L["Module Commandes non chargé — redémarre complètement WoW (quitter/relancer), pas un simple /reload."] .. "|r")
    if not COC._ordersWarned then
        COC._ordersWarned = true
        print("|cFF33DD88Crafting Order|r |cFFFF7777"
            .. L["Module Commandes non chargé — redémarre complètement WoW (quitter/relancer), pas un simple /reload."] .. "|r")
    end
end

-- ------------------------------------------------------------------
-- Bouton de retour sur la fenêtre NATIVE (vue Blizzard) : pose un petit bouton doré sur
-- TradeSkillFrame / CraftFrame pour rebasculer vers la vue custom sans passer par /co profwindow.
-- ------------------------------------------------------------------
function PW:EnsureNativeToggle(frame, key)
    if not frame then return end
    self._nativeToggle = self._nativeToggle or {}
    if self._nativeToggle[key] then return end
    local btn = Skin.MakeGoldButton(frame, 150, 20, L["» Vue Crafting Order"])
    btn:SetPoint("TOPRIGHT", -66, -8)
    btn:SetScript("OnClick", function() PW:SetEnabled(true) end)
    self._nativeToggle[key] = btn
end

-- ------------------------------------------------------------------
-- Dock « Commandes » en VUE BLIZZARD : la fenêtre native reste VISIBLE (non neutralisée) et on épingle
-- NOTRE colonne Commandes à sa droite (le « panneau de commande » demandé). Réutilise tel quel le rendu
-- de _ProfWindow_Orders via le layout compact. S'EXCLUT de la vue custom 3 colonnes (custom = frame
-- neutralisée + 3 colonnes ; dock = native intacte + colonne seule) → jamais les deux à la fois.
-- ------------------------------------------------------------------
function PW:OpenDock(nativeFrame)
    if not nativeFrame then return end
    self:Build()
    self.docked = true
    self.standaloneKey = nil
    self.rerollKey = nil                -- défense en profondeur : docké natif ≠ vue reroll
    self._compact = nil                 -- force _ApplyMode à recalculer au retour en vue custom
    self:_ApplyMode(true)               -- colonne Commandes seule (réutilise le layout compact)
    if self.vanillaBtn then self.vanillaBtn:Hide() end   -- « Vue Blizzard » redondant : on Y est déjà
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", nativeFrame, "TOPRIGHT", 6, 0)
    self.frame:Show()
    self:Refresh()
end

function PW:CloseDock()
    if not self.docked then return end
    self.docked = false
    if self.vanillaBtn then self.vanillaBtn:Show() end
    self:Hide()
end

-- Replace la fenêtre custom à sa position mémorisée (drag) ou au centre après un passage en dock
-- (qui l'avait épinglée à la native).
function PW:_RestorePlacement()
    if not self.frame then return end
    self.frame:ClearAllPoints()
    local pos = COC.db and COC.db.profWinPos
    if pos then self.frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else self.frame:SetPoint("CENTER") end
end

-- Refresh en mode dock : on ne touche NI aux recettes NI au détail (la native s'en charge), juste le
-- titre/rang + la colonne Commandes. Native fermée entre-temps → on retire le dock.
function PW:_RefreshDock()
    local craft = COC.Craft
    local name = craft and craft:GetOpenProfessionInfo()
    if not name then self:CloseDock(); return end
    self.profKey = craft:OpenProfessionKey()
    local rank, maxRank = craft:OpenRank()
    self:_SetTitle(name, (rank and maxRank) and string.format("|cFFE8B84B%d|r / %d", rank, maxRank) or nil)
    self:_SyncPortrait()
    self:_SyncLFWBtn()
    self:_SyncMissingBtn()
    if self.RefreshOrders then self:RefreshOrders() end
end

-- ------------------------------------------------------------------
-- Refresh global (coalescé)
-- ------------------------------------------------------------------
-- Bouton « Créer » sécurisé affiché → Hide() de la fenêtre lève ADDON_ACTION_BLOCKED en combat (vu en
-- jeu). SetAlpha/EnableMouse non protégés : on escamote en combat, vrai Hide à la sortie (_hidePending).
function PW:Hide()
    if not self.frame then return end
    local c = InCombatLockdown and InCombatLockdown(); self._hidePending = c or nil
    self.frame:SetAlpha(c and 0 or 1); self.frame:EnableMouse(not c); if not c then self.frame:Hide() end
end

function PW:_DoRefresh()
    self._pending = false
    if not self.frame or not self.frame:IsShown() then return end
    if self.docked then self:_RefreshDock(); return end
    local craft = COC.Craft
    local name = craft and craft:GetOpenProfessionInfo()
    if not name then self.missingMode = false end   -- « manquantes » n'existe qu'en vue pleine de MON métier
    if name then                                   -- mode PLEIN : fenêtre métier native ouverte
        self.rerollKey = nil                        -- la native prime sur une vue reroll résiduelle
        self.profKey = craft:OpenProfessionKey()
        local rank, maxRank = craft:OpenRank()
        self:_SetTitle(name, (rank and maxRank) and string.format("|cFFE8B84B%d|r / %d", rank, maxRank) or nil)
        self.recipes = craft:ReadRecipes() or {}
        self:_ApplyMode(false)
        if self.RefreshRecipes then self:RefreshRecipes() end
        if self.RefreshDetail  then self:RefreshDetail()  end
    elseif self.rerollKey then                     -- mode REROLL : lecture seule, recettes depuis le cache
        self.profKey = self.standaloneKey
        local label = Skin.ProfLabel(self.profKey) .. "  |cFF888888"
            .. string.format(L["%s — lecture seule"], self.rerollName or "?") .. "|r"
        local mc = COC.db and COC.db.mySkillsByChar and COC.db.mySkillsByChar[self.rerollKey]
        local sk = mc and mc[self.profKey]
        self:_SetTitle(label, sk and string.format("|cFFE8B84B%d|r / %d", sk[1], sk[2]) or "|cFF888888?|r")
        self.recipes = self:_RerollRecipeList()
        self:_ApplyMode(false)
        if self.RefreshRecipes then self:RefreshRecipes() end
        if self.RefreshDetail  then self:RefreshDetail()  end
    elseif self.standaloneKey then                 -- mode COMPACT : ouvert par clé (récolte / menu minimap)
        self.profKey = self.standaloneKey
        local D = COC.Directory; local sk = D and D.mySkills and D.mySkills[self.profKey]
        self:_SetTitle(Skin.ProfLabel(self.profKey),
            sk and string.format("|cFFE8B84B%d|r / %d", sk[1], sk[2]) or nil)
        self:_ApplyMode(true)
    else
        return
    end
    self:_SyncPortrait()
    self:_SyncLFWBtn()
    self:_SyncMissingBtn()
    if self.RefreshOrders then self:RefreshOrders() end
end

-- Bascule PLEIN (3 colonnes, fenêtre native) ↔ COMPACT (colonne Commandes seule, ouvert par clé).
-- Compact : on masque le PANNEAU de sections (colonnes + frontières dessinées) et on RE-PARENTE la
-- zone Commandes sur la fenêtre rétrécie — une zone est une frame ordinaire, son contenu la suit.
-- Retour plein : la zone regagne sa place SPEC via les constantes ORD_* dérivées (Layout).
function PW:_ApplyMode(compact)
    if self._compact == compact then return end
    self._compact = compact
    if self._PlaceOrdTabs then self:_PlaceOrdTabs(compact) end   -- onglets de relation : suivent le mode
    self.ordCol:ClearAllPoints()
    if compact then
        self.frame:SetWidth(300)
        if self.secPanel then self.secPanel:Hide() end
        self.ordCol:SetParent(self.frame)
        -- Même bande d'onglets qu'en vue pleine : 60 = sommet du marbre, ORD_TOP (négatif) = la bande.
        self.ordCol:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.PAD, -(60 - PW.ORD_TOP))
        self.ordCol:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, self.PAD)
        self.ordCol:SetWidth(300 - 2 * self.PAD)
    else
        self.frame:SetWidth(self.FRAME_W)
        if self.secPanel then self.secPanel:Show() end
        self.ordCol:SetParent(self.secPanel)
        self.ordCol:SetPoint("TOPLEFT", self.secPanel, "TOPLEFT", PW.ORD_X, PW.ORD_TOP)
        self.ordCol:SetPoint("BOTTOMLEFT", self.secPanel, "BOTTOMLEFT", PW.ORD_X, PW.ORD_BOTTOM)
        self.ordCol:SetWidth(PW.ORD_W)
    end
end

-- Ouvre la vue métier pour une CLÉ de métier (menu minimap / récolte / /co métier).
--  * Métier CRAFTABLE (a une vraie fenêtre en jeu) → on OUVRE la fenêtre native (cast du sort de
--    métier) : la vue PLEINE 3 colonnes se monte via OnProfessionShow, recettes lues en live. Repli
--    compact si la fenêtre ne s'ouvre pas (Secourisme, combat…).
--  * Métier de RÉCOLTE (pas de fenêtre) → vue COMPACTE autonome (colonne Commandes seule).
function PW:OpenFor(profKey)
    if not profKey then return end
    self.rerollKey = nil                              -- ouverture normale (perso courant) : sort du mode reroll
    -- Minage : contrairement aux autres récoltes, il a une facette CRAFT (la FONTE : minerai → lingot).
    -- On ouvre donc la vraie fenêtre de fonte (vue pleine 3 colonnes) plutôt que la vue compacte.
    if profKey == "Mining" then return self:_OpenSmelting() end
    if not GATHER[profKey] then
        local craft = COC.Craft
        if craft and craft:GetOpenProfessionInfo() and craft:OpenProfessionKey() == profKey then
            self:OnProfessionShow(); return          -- déjà ouvert nativement → (ré)affiche la vue pleine
        end
        local spell = Skin.ProfLabel(profKey)
        if spell and spell ~= "" and spell ~= "—" and CastSpellByName then
            self.standaloneKey = nil
            CastSpellByName(spell)                    -- ouvre la fenêtre native → OnProfessionShow
            if C_Timer and C_Timer.After then
                C_Timer.After(0.4, function()
                    local c = COC.Craft
                    if not (c and c:GetOpenProfessionInfo()) then PW:_OpenCompact(profKey) end
                end)
            end
            return
        end
    end
    self:_OpenCompact(profKey)
end

-- (PW:_OpenSmelting — ouverture de la FONTE, facette craft du Minage — vit dans _ProfWindow_Reroll.lua,
--  avec les autres variantes d'ouverture, pour tenir ce fichier sous le plafond anti-monolithe.)

-- Vue compacte autonome (colonne Commandes seule) : récolte, ou repli si la fenêtre native n'a pas pu
-- s'ouvrir pour un métier craftable. Si une AUTRE fenêtre native est déjà ouverte (ex. : Travail du
-- cuir ouvert pendant qu'on demande Dépeçage), on la ferme d'abord : TRADE_SKILL_CLOSE déclenche
-- OnProfessionClose, qui voit standaloneKey posé et RESTE VISIBLE en mode compact (au lieu de masquer).
function PW:_OpenCompact(profKey)
    self.standaloneKey = profKey
    self.rerollKey = nil                              -- compact récolte ≠ vue reroll
    self:Build()
    local craft = COC.Craft
    if craft and craft:GetOpenProfessionInfo() then
        if craft.IsCraftOpen and craft:IsCraftOpen() then
            if CloseCraft then CloseCraft() end
        else
            if CloseTradeSkill then CloseTradeSkill() end
        end
        -- OnProfessionClose prend le relais (voit standaloneKey → reste en compact)
    else
        if not self.frame:IsShown() then self.frame:Show() end
        self:Refresh()
    end
end

function PW:Refresh()
    if not (C_Timer and C_Timer.After) then return self:_DoRefresh() end
    if self._pending then return end
    self._pending = true
    C_Timer.After(0.1, function() PW:_DoRefresh() end)
end

-- ------------------------------------------------------------------
-- Entrées (depuis le coordinateur d'événements ProfOrders) + bascule
-- ------------------------------------------------------------------
-- Custom = vue métier par DÉFAUT (la maquette designer). « Vue Blizzard » pose profWindow=false.
function PW:IsEnabled() return not (COC.db and COC.db.profWindow == false) end

-- Active/désactive la fenêtre custom. ON → coupe le takeover de Guild Economy (anti-conflit).
function PW:SetEnabled(on)
    if COC.db then COC.db.profWindow = on and true or false end
    if on then
        if _G.TradeScannerDB then TradeScannerDB.replaceProfWindow = false end   -- GE laisse la main
        print("|cFF33DD88Crafting Order|r " .. L["fenêtre métier custom |cFF33DD33activée|r — ouvre un métier. (Guild Economy laisse la main.)"])
        self:OnProfessionShow()
    else
        self.docked = false
        self:Hide(); self:RestoreNative()
        print("|cFF33DD88Crafting Order|r " .. L["fenêtre métier custom |cFFFFCC00désactivée|r (vue Blizzard)."])
        -- Vue Blizzard : si un métier est ouvert, épingle tout de suite le dock Commandes à sa droite.
        local craft = COC.Craft
        if craft and craft:GetOpenProfessionInfo() then
            local isCraft = craft.IsCraftOpen and craft:IsCraftOpen()
            local nf = (isCraft and _G.CraftFrame) or _G.TradeSkillFrame
            self:EnsureNativeToggle(nf, isCraft and "craft" or "trade")
            self:OpenDock(nf)
        end
    end
end

local function silenceGE()
    if _G.TradeScannerDB then TradeScannerDB.replaceProfWindow = false end
    if _G.TradeScanner and TradeScanner.ProfWindow and TradeScanner.ProfWindow.Hide then
        TradeScanner.ProfWindow:Hide()
    end
end

function PW:OnProfessionShow()
    if not self:IsEnabled() then return end
    if InCombatLockdown and InCombatLockdown() then return end   -- pas de (re)neutralisation du natif en combat
    local craft = COC.Craft
    if not (craft and craft:GetOpenProfessionInfo()) then return end
    silenceGE()                         -- coexistence : pas de double panneau si GE est chargé
    self.standaloneKey = nil            -- la fenêtre native prend le dessus sur une ouverture par clé
    self.rerollKey = nil                -- …et sur une vue reroll lecture seule
    self:Build()
    if self.docked then self.docked = false; self:_RestorePlacement(); if self.vanillaBtn then self.vanillaBtn:Show() end end
    self:NeutralizeNative()
    if not self.frame:IsShown() then self.frame:Show() end
    self:Refresh()
    -- L'ordre de dispatch des events entre addons n'est pas garanti : si GE traite SHOW APRÈS nous
    -- (et restaure la frame native / réaffiche sa fenêtre), on re-museler juste après.
    if C_Timer then C_Timer.After(0.05, function() silenceGE(); PW:NeutralizeNative() end) end
end

function PW:OnProfessionClose()
    self.selectedIndex = nil
    if self.standaloneKey then
        -- Une vue compacte a été demandée (ex. : Dépeçage pendant que la Forge était ouverte).
        -- On restaure la native fermée mais on RESTE VISIBLE en mode compact pour le bon métier.
        self:RestoreNative()
        if not self.frame:IsShown() then self.frame:Show() end
        self:Refresh()
    else
        self:Hide(); self:RestoreNative()
    end
end
