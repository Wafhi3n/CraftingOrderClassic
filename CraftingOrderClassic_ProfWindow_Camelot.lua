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
local CHROME = { "NineSlice", "Bg", "TopTileStreaks", "PortraitContainer",
                 "TitleContainer", "CloseButton", "Inset", "FrameGlow", "portrait" }

-- Le dépouillement est RÉVERSIBLE, et il doit l'être : le même cadre sert encore de fenêtre
-- FLOTTANTE pour la vue reroll (métiers d'un autre perso du compte, que le client ne connaît pas).
-- Tant que strip était définitif, une vue reroll ouverte après un passage dans la fenêtre native
-- sortait sans bordure, sans titre et sans croix. On mémorise donc ce qu'on a réellement masqué —
-- et rien d'autre : une pièce déjà cachée par Blizzard ne doit pas réapparaître à cause de nous.
local function stripChrome(f)
    if not f or f._cocStripped then return end
    local hidden = {}
    for _, key in ipairs(CHROME) do
        local part = f[key]
        if part and part.Hide and (not part.IsShown or part:IsShown()) then
            hidden[#hidden + 1] = part
            pcall(part.Hide, part)
        end
    end
    f._cocChromeHidden, f._cocStripped = hidden, true
end

local function restoreChrome(f)
    if not (f and f._cocStripped) then return end
    for _, part in ipairs(f._cocChromeHidden or {}) do pcall(part.Show, part) end
    f._cocChromeHidden, f._cocStripped = nil, nil
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
        restoreChrome(self.frame)   -- le cadre redevient une vraie fenêtre (vue reroll, cf. stripChrome)
        -- Rendre le parent ET les ancres : sans ça la colonne resterait liée au cadre natif (et
        -- étirée à SA hauteur) si on rebascule un jour sur la vue custom.
        self.frame:ClearAllPoints()
        self.frame:SetParent(UIParent)
        -- Redevenue flottante, elle retrouve son comportement de fenêtre (cf. CamelotAttach).
        if self.frame.SetToplevel then self.frame:SetToplevel(true) end
        self.frame:SetFrameStrata("HIGH")
    end
end

-- ---------------------------------------------------------------- ouverture d'un métier

-- Clé de métier COC → `skillLineID` du client, ce qu'attend l'ouvreur natif. Les valeurs rendues
-- par `GetProfessions` sont des index de LIVRE DE SORTS, pas des métiers : seul
-- `GetProfessionInfo` donne le nom localisé et la ligne de compétence. On repasse par
-- `ResolveProfession` (alias FR/DE/ES de CraftLink), le même résolveur que Directory_Skills —
-- jamais une comparaison de libellés écrite à la main.
local function skillLineFor(profKey)
    if not (profKey and _G.GetProfessions and _G.GetProfessionInfo and _G.CraftLink) then return nil end
    local p1, p2, arch, fish, cook = GetProfessions()
    for _, idx in pairs({ p1, p2, arch, fish, cook }) do    -- pairs : sauter les trous sans s'arrêter
        local name, _, _, _, _, _, skillLine = GetProfessionInfo(idx)
        if name and skillLine and CraftLink:ResolveProfession(name) == profKey then return skillLine end
    end
    return nil
end

-- Ouvre la fenêtre de métier NATIVE. **Aucun sort lancé depuis notre code** : `CastSpellByName`
-- est PROTÉGÉE sur cette cible — vécu le 2026-09-19 au clic « Cuisine » du menu minimap
-- (ADDON_ACTION_BLOCKED). Blizzard ouvre ses propres onglets latéraux avec
-- `C_SpellBook.CastSpellBookItem`, protégée elle aussi : il n'existe aucun équivalent appelable
-- depuis un addon. On passe donc par les globales FrameXML, qui ne font que charger le module et
-- montrer le panneau.
-- ⚠️ À ÉPROUVER EN JEU. `ProfessionsMixin:OnShow` déclenche `ProfessionsFrame.Show`, sur lequel
-- CHAQUE onglet latéral rappelle `CastProfessionSpell()`. Si notre appel teinte cette chaîne, le
-- blocage revient — déplacé, pas supprimé. Le chemin PROUVÉ est `ToggleProfessionsBook()` : c'est mot
-- pour mot ce qu'appelle le micro-bouton « Métiers » de Blizzard, et c'est celui du bouton minimap
-- (cf. _Minimap.lua, validé en jeu le 2026-09-19). Il ouvre la page d'ensemble au lieu du métier
-- visé, d'où l'essai d'`OpenProfessionUIToSkillLine` d'abord. Cette fonction ne sert qu'aux entrées
-- qui n'ont pas de bouton à elles : `/co métier`, clic du suivi.
-- Repli si le 1er chemin ÉCHOUE (revue API v1.32.0 : avant, on rendait `false` sans rien ouvrir, en
-- silence). Limite à connaître : `pcall` n'attrape PAS un ADDON_ACTION_BLOCKED, qui n'est pas une
-- erreur Lua ; ce repli couvre une erreur (module qui ne charge pas, ligne de métier inconnue),
-- pas un blocage de taint.
function PW:CamelotOpenNative(profKey)
    local native = _G.ProfessionsFrame
    if native and native:IsShown() then return true end     -- déjà ouverte : surtout ne pas la refermer
    local line = skillLineFor(profKey)
    if line and _G.OpenProfessionUIToSkillLine then
        if pcall(_G.OpenProfessionUIToSkillLine, line) then return true end
        native = _G.ProfessionsFrame                          -- module chargé entre-temps : relire
        if native and native:IsShown() then return true end   -- ouverte à mi-chemin : ne pas empiler
    end
    if _G.ToggleProfessionsBook then return (pcall(_G.ToggleProfessionsBook)) end
    return false
end

-- Les surcharges ci-dessous visent des méthodes définies dans DEUX fichiers : `_ProfWindow.lua`
-- (chargé avant celui-ci) et `_ProfWindow_Reroll.lua` (chargé APRÈS, cf. l'ordre des `.toc`). À la
-- portée du fichier, la seconde serait réécrite au chargement. On les pose donc à PLAYER_LOGIN,
-- comme `disarmCombatHide` : l'ordre des modules ne doit pas décider qui gagne.
local function installOpeners()
    if PW._cocCamelotOpeners then return end
    PW._cocCamelotOpeners = true

    -- Toutes les entrées « ouvre-moi ce métier » (bouton minimap, `/co métier`, clic du suivi)
    -- mènent à la fenêtre native : elle a un onglet par métier, RÉCOLTES COMPRISES (l'Herboristerie
    -- a de vraies recettes sur Forever) et FONTE comprise (elle vit dans l'onglet Minage, plus
    -- besoin du détour par le sort 2656 de `PW:_OpenSmelting`).
    function PW:OpenFor(profKey)
        self.rerollKey, self.standaloneKey = nil, nil
        return self:CamelotOpenNative(profKey)
    end

    -- Vue COMPACTE neutralisée. Elle n'existait que pour les métiers sans fenêtre en jeu (les
    -- récoltes de l'Era) ; ici ils en ont une. Et notre cadre est GREFFÉ dans la native : l'ouvrir
    -- en flottant le sortirait dépouillé de son chrome (cf. stripChrome).
    function PW:_OpenCompact(profKey) return self:CamelotOpenNative(profKey) end

    -- La vue REROLL, elle, reste la nôtre : le client ne sait rien des métiers d'un perso hors
    -- ligne. Elle demande l'inverse de la greffe — une vraie fenêtre flottante, avec son chrome.
    local baseReroll = PW.OpenForReroll
    function PW:OpenForReroll(prof, rerollKey, name)
        if not (prof and rerollKey and baseReroll) then return end
        local native = _G.ProfessionsFrame
        if native and native:IsShown() then
            if _G.HideUIPanel then pcall(_G.HideUIPanel, native) else pcall(native.Hide, native) end
        end
        self:CamelotDetach(native)          -- rend parent, ancres ET chrome
        Api.CloseProfession()               -- sinon `_DoRefresh` voit une session ouverte et la préfère au reroll
        baseReroll(self, prof, rerollKey, name)
        -- Sur l'Era le socle ferme la native et attend l'événement CLOSE pour rouvrir en reroll.
        -- Ici les événements TRADE_SKILL_*/CRAFT_* n'existent pas (aucun ne s'enregistre, cf.
        -- ProfOrders:Start) : personne ne rouvrirait. On montre donc nous-mêmes — idempotent.
        if self.frame and not self.frame:IsShown() then self.frame:Show() end
        self:Refresh()
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
    if event == "PLAYER_LOGIN" then disarmCombatHide(); installOpeners(); wire(); return end
    if addon == "Blizzard_Professions" then wire() end
end)
wire()   -- le module peut déjà être chargé (rechargement d'UI fenêtre ouverte)

-- Sur cette cible la fenêtre NATIVE est l'UI de recettes : notre vue custom 3 colonnes ne doit pas
-- s'ouvrir par-dessus (c'est ce qui donnait DEUX fenêtres). On force donc le mode « Vue Blizzard »,
-- dont la greffe ci-dessus est la version « dedans » plutôt que « collée dehors ».
function PW:IsEnabled() return false end
