-- CraftingOrderClassic_ProfWindow_Camelot.lua — POC : notre colonne Commandes À L'INTÉRIEUR de la
-- fenêtre de métier NATIVE de WoW: Forever (Camelot).
--
-- Pourquoi ce mode existe. La vue custom 3 colonnes a été écrite parce que la fenêtre native de
-- Classic Era est rudimentaire (pas de recherche, pas de catégories, détail minimal). Celle de
-- Forever est la fenêtre RETAIL moderne : recherche, filtres, catégories sémantiques, panneau de
-- détail complet, favoris, suivi, Create All. Elle est meilleure que la nôtre. Sur cette cible on
-- ne la remplace donc pas — on lui ajoute ce qu'elle n'a pas : le carnet de commandes.
--
-- Ce qui rend la greffe propre, vérifié sur le source Blizzard (1.60.1) :
--   * `ProfessionsFrame` n'est nulle part `SetForbidden` → on a le droit d'y parenter des frames.
--   * `CraftingPage` est ancrée TOPLEFT SEULEMENT (x=3, y=-21) → elle ne s'étire PAS. Élargir le
--     cadre ouvre une bande vide à droite SANS déplacer quoi que ce soit de Blizzard.
--   * Les onglets verticaux sont ancrés à `$parent TOPRIGHT`, donc DEHORS : ils suivent le nouveau
--     bord droit, rien ne casse.
-- Ce qu'on ne fait PAS : ajouter un onglet à `rightProfessionTabs`. `RefreshRightTabs` itère ce
-- tableau et CACHE tout ce qui dépasse les métiers connus — notre onglet serait masqué à chaque
-- rafraîchissement. La bande élargie n'a pas besoin d'onglet.

local COC  = CraftingOrderClassic
local PW   = COC.ProfWindow
local Api  = COC.Api
if not (PW and Api) then return end

-- GARDE DE SAVEUR (cf. le backend métier) : ce fichier est listé dans les QUATRE `.toc` — parité
-- oblige — donc CHARGÉ sur l'Era aussi. Sans cette garde, il y désactiverait la vue custom.
if not Api.IS_MAINLINE then return end

local GAP = 6          -- respiration entre le contenu natif et notre bande
local TOP_INSET = 26   -- sous la barre de titre native
local BOT_INSET = 34   -- au-dessus de la rangée « Create All / Create »
local nativeBaseW      -- largeur d'origine du cadre natif, capturée UNE fois

-- Largeur RÉELLE de la barre d'onglets (All / Guild / Friends / Directory / Incoming). À 5
-- languettes elle est plus large que la colonne Commandes : sans cette mesure, « Incoming » sort
-- du cadre et se fait rogner par la bordure native (vécu au 1er essai du POC).
-- Le −4 reproduit le chevauchement natif des languettes, cf. PW:_PlaceOrdTabs.
local function tabRowWidth(bar)
    if not (bar and bar.buttons) then return 0 end
    local total, n = 0, 0
    for _, b in pairs(bar.buttons) do
        total = total + ((b.GetWidth and b:GetWidth()) or 0)
        n = n + 1
    end
    if n == 0 then return 0 end
    return total - 4 * (n - 1) + 20      -- +20 : marges gauche/droite
end

-- ---------------------------------------------------------------- chrome

-- Notre fenêtre est un PortraitFrameTemplate complet. Posée DANS un autre cadre, elle ferait une
-- fenêtre dans une fenêtre. On la dépouille : seule la colonne doit se voir, sur le fond natif.
-- Chaque pièce est optionnelle et gardée — leur nom varie déjà entre saveurs (cf. Compat).
local function stripChrome(f)
    if not f or f._cocStripped then return end
    for _, key in ipairs({ "NineSlice", "Bg", "TopTileStreaks", "PortraitContainer",
                           "TitleContainer", "CloseButton", "Inset", "FrameGlow" }) do
        local part = f[key]
        if part and part.Hide then pcall(part.Hide, part) end
    end
    if f.portrait and f.portrait.Hide then pcall(f.portrait.Hide, f.portrait) end
    f._cocStripped = true
end

-- ---------------------------------------------------------------- greffe

function PW:CamelotAttach(native)
    if not native then return end
    self:Build()
    stripChrome(self.frame)

    -- Mode dock : colonne Commandes seule (réutilise le layout compact, comme le dock extérieur).
    self.docked = true
    self.standaloneKey, self.rerollKey, self._compact = nil, nil, nil
    self:_ApplyMode(true)
    if self.vanillaBtn then self.vanillaBtn:Hide() end

    -- La colonne doit être au moins aussi large que sa barre d'onglets, sinon « Incoming » sort.
    local colW = math.max(self.frame:GetWidth() or 310, tabRowWidth(self.ordRelTabs))
    self.frame:SetWidth(colW)
    if self._PlaceOrdTabs then self:_PlaceOrdTabs(true) end   -- re-poser à la largeur définitive

    nativeBaseW = nativeBaseW or native:GetWidth()
    local fullW = nativeBaseW + colW + GAP * 2
    -- Élargir SANS toucher aux enfants de Blizzard : eux sont ancrés TOPLEFT, ils ne bougent pas.
    native:SetWidth(fullW)
    -- ⚠️ NE JAMAIS écrire dans le système de panneaux depuis du code addon.
    -- On a tenté `SetUIPanelAttribute(native, "width", fullW)` pour que le gestionnaire réserve
    -- notre largeur réelle (sinon la fiche de personnage s'ouvre par-dessus notre colonne).
    -- Le jeu nous a nommés : « attempt to compare local 'oldR' (a secret number value, while
    -- execution tainted by 'CraftingOrderClassic') », pile Menu → ShowUIPanel → EnterEditMode →
    -- RefreshPartyFrames → CompactUnitFrame_UpdateHealthColor.
    -- Mécanisme, lisible dans Blizzard_UIParentPanelManager : `RegisterUIPanel` remplit
    -- `UIPanelWindows`, donc `SetUIPanelAttribute` va jusqu'à `SetFrameAttributes` →
    -- `frame:SetAttributeNoHandler(...)` DEPUIS NOTRE CODE → les attributs sécurisés du cadre sont
    -- teintés → le dispatch `FramePositionDelegate:SetAttribute(...)` exécute toute la chaîne
    -- sécurisée en teinté → la première lecture d'une valeur SECRÈTE lève.
    -- Sur l'Era une taint donnait au pire un ADDON_ACTION_BLOCKED ; sur Midnight elle fait planter
    -- le code de Blizzard, et le blâme nous est imputé nommément.
    -- Le chevauchement de panneaux est COSMÉTIQUE. On le garde.

    self.frame:SetParent(native)          -- suit l'ouverture/fermeture et le déplacement du natif
    self.frame:ClearAllPoints()
    -- Ancrer HAUT **et** BAS : la colonne épouse la hauteur du cadre natif au lieu de garder la
    -- sienne (sinon ~140 px de vide sous le pied de colonne — vu au 1er essai du POC).
    self.frame:SetPoint("TOPRIGHT", native, "TOPRIGHT", -GAP, -TOP_INSET)
    self.frame:SetPoint("BOTTOMRIGHT", native, "BOTTOMRIGHT", -GAP, BOT_INSET)
    -- Greffée, notre fenêtre ne doit plus se comporter en FENÊTRE. `SetToplevel(true)` et une strata
    -- « HIGH » ont du sens pour un cadre flottant sur UIParent — ils la font remonter au clic et la
    -- placent au-dessus du reste. Pour l'enfant d'un panneau GÉRÉ, ils la décrochent de l'ordre
    -- d'affichage de son hôte. On la remet au rang d'enfant ordinaire.
    if self.frame.SetToplevel then self.frame:SetToplevel(false) end
    self.frame:SetFrameStrata(native:GetFrameStrata() or "MEDIUM")
    self.frame:SetFrameLevel((native:GetFrameLevel() or 0) + 5)
    self.frame:Show()
    self:Refresh()
end

function PW:CamelotDetach(native)
    if native and nativeBaseW then
        native:SetWidth(nativeBaseW)
    end
    self.docked = false
    if self.frame then
        self.frame:Hide()
        -- Rendre le parent ET les ancres : sans ça la colonne resterait liée au cadre natif (et
        -- étirée à SA hauteur) si on rebascule un jour sur la vue custom.
        self.frame:ClearAllPoints()
        self.frame:SetParent(UIParent)
        -- Redevenue flottante, elle retrouve son comportement de fenêtre (cf. CamelotAttach).
        if self.frame.SetToplevel then self.frame:SetToplevel(true) end
        self.frame:SetFrameStrata("HIGH")
    end
end

-- ---------------------------------------------------------------- branchement

-- `Blizzard_Professions` est un module LoadOnDemand : `ProfessionsFrame` n'existe PAS au login.
-- On attend son chargement, puis on se greffe sur son OnShow/OnHide. Même piège que
-- `Blizzard_UIPanels_Game` lors de la migration des menus clic-droit.
local function wire()
    local native = _G.ProfessionsFrame
    if not native or native._cocWired then return end
    native._cocWired = true
    Api.HookScriptSafe(native, "OnShow", function(f) PW:CamelotAttach(f) end)
    Api.HookScriptSafe(native, "OnHide", function(f) PW:CamelotDetach(f) end)
    if native:IsShown() then PW:CamelotAttach(native) end
end

-- L'Era escamote notre fenêtre à l'entrée en combat (`ProfOrders:_OnCombat` → `PW:CloseDock`) parce
-- qu'elle porte un **SecureActionButton** — le bouton « Créer » — qu'on ne peut ni masquer ni
-- désactiver en combat (cf. wow-protected-frame-hide-combat). Ici ce bouton est celui de BLIZZARD,
-- dans SA fenêtre : notre colonne n'est qu'un enfant ordinaire, rien n'est protégé chez nous.
-- Rejouer le chemin Era sur un cadre natif touchait des choses qu'on ne maîtrise pas — et faisait
-- disparaître l'interface (signalé en jeu le 2026-09-18). On neutralise donc ce chemin ici.
-- Posé à PLAYER_LOGIN : l'ordre de chargement des modules ne doit pas décider qui gagne.
local function disarmCombatHide()
    local PO = COC.ProfOrders
    if not PO or PO._cocCamelotCombat then return end
    PO._cocCamelotCombat = true
    function PO:_OnCombat() end
end

local watcher = CreateFrame("Frame")
Api.RegisterEventSafe(watcher, "ADDON_LOADED")
Api.RegisterEventSafe(watcher, "PLAYER_LOGIN")
watcher:SetScript("OnEvent", function(_, event, addon)
    if event == "PLAYER_LOGIN" then disarmCombatHide(); wire(); return end
    if addon == "Blizzard_Professions" then wire() end
end)
wire()   -- le module peut déjà être chargé (rechargement d'UI fenêtre ouverte)

-- Sur cette cible la fenêtre NATIVE est l'UI de recettes : notre vue custom 3 colonnes ne doit pas
-- s'ouvrir par-dessus (c'est ce qui donnait DEUX fenêtres). On force donc le mode « Vue Blizzard »,
-- dont la greffe ci-dessus est la version « dedans » plutôt que « collée dehors ».
function PW:IsEnabled() return false end
