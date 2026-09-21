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

-- GARDE DE SAVEUR (cf. le backend métier) : elle date des QUATRE `.toc` — parité oblige, ce fichier
-- était CHARGÉ sur l'Era aussi, où il désactivait la vue custom. Depuis le 2026-09-20 il n'y a plus
-- qu'UN `.toc` (16001) : l'exposition a disparu, la garde reste (on ne greffe que sur du MAINLINE).
if not Api.IS_MAINLINE then return end

-- Trace de diagnostic (catégorie « graft ») : l'auto-trace est active d'office sur Forever, donc
-- ces lignes atterrissent dans la SavedVariable sans rien activer. Posées le 2026-09-19 parce que
-- la colonne ne s'affichait plus et que l'inférence tournait en rond.
local function tr(fmt, ...)
    if not (COC.Trace and COC.Trace:IsOn()) then return end
    COC.Trace:Log("graft", (select("#", ...) > 0) and string.format(fmt, ...) or fmt)
end

-- Réglages au pixel : ils vivent tous dans PW.TUNE (cf. _ProfWindow_Layout) pour qu'on puisse les
-- pinailler d'un seul endroit, relevé `/co geo` à l'appui. Lus à CHAQUE usage, jamais recopiés dans
-- un local : une valeur recopiée est une valeur qui ne suit plus la table.
local function T() return PW.TUNE end
local nativeBaseW      -- largeur d'origine du cadre natif, capturée UNE fois
local hostWidened      -- a-t-on REELLEMENT elargi le cadre natif ? (mode encastre seulement)

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
local function restoreChrome(f)
    if not (f and f._cocStripped) then return end
    for _, part in ipairs(f._cocChromeHidden or {}) do pcall(part.Show, part) end
    f._cocChromeHidden, f._cocStripped = nil, nil
end

-- Masque les pieces `keys` et les NOTE, pour que restoreChrome les rende. `mode` dit quel habillage
-- est pose ("full" encastre, "side" accole). Passer d'un mode a l'autre restaure d'abord : sinon le
-- portrait masque par l'accole n'etait jamais rendu (vue reroll sans portrait), et un cadre deja
-- marque « depouille » par l'accole sautait le vrai depouillement de l'encastre.
local function hideChrome(f, keys, mode)
    if not f or f._cocStripped == mode then return end
    restoreChrome(f)
    local hidden = {}
    for _, key in ipairs(keys) do
        local part = f[key]
        if part and part.Hide and (not part.IsShown or part:IsShown()) then
            hidden[#hidden + 1] = part
            pcall(part.Hide, part)
        end
    end
    f._cocChromeHidden, f._cocStripped = hidden, mode
end

local function stripChrome(f) hideChrome(f, CHROME, "full") end

-- ACCOLEE : chrome complet (bordure, titre, croix) SAUF le portrait. Notre disposition a ete
-- dessinee pour un cadre depouille : la rangee d'onglets commence en haut a gauche, la ou le
-- portrait vient se poser -- il recouvrait l'onglet « All » (releve en jeu le 2026-09-19).
local function sideChrome(f) hideChrome(f, { "PortraitContainer", "portrait" }, "side") end

-- ---------------------------------------------------------------- greffe

-- RIEN ne se greffe ni ne se degreffe EN COMBAT. Une fois notre colonne reparentee dans le panneau
-- natif, elle est PROTEGEE comme lui : SetWidth / SetPoint / SetParent / SetToplevel / Show y sont
-- tous refuses, et le cadre natif lui-meme ne peut plus etre redimensionne. Releve du 2026-09-19
-- (Logs\taint.log) : 15 blocages en une session, tous a l'attache, declenchee par l'ouverture de la
-- fenetre en plein combat -- y compris quand c'est le micro-bouton de Blizzard qui l'ouvre, donc
-- sans aucune action de l'addon. On repousse le travail a la sortie de combat et on le rejoue selon
-- l'etat REEL de la fenetre a ce moment-la (elle a pu se fermer entre-temps).
local function lockedDown()
    return InCombatLockdown and InCombatLockdown()
end

-- La greffe pilote, donc la greffe RAFRAICHIT. A la premiere ouverture d'un metier, le client n'a
-- pas encore la liste : notre colonne se dessine VIDE, et depouillee de son fond elle est alors
-- indiscernable d'une colonne absente (symptome vecu le 2026-09-19 : il fallait ouvrir-fermer une
-- fois pour la voir). Les donnees arrivent avec TRADE_SKILL_LIST_UPDATE, juste apres. ProfOrders
-- s'en chargeait ; depuis qu'il laisse la main a la greffe (pilote unique), plus personne ne le
-- faisait. On le reprend ici, la ou vit desormais la responsabilite.
local upd = CreateFrame("Frame")
Api.RegisterEventsSafe(upd, { "TRADE_SKILL_LIST_UPDATE" })
upd:SetScript("OnEvent", function()
    if PW.docked and PW.frame and PW.frame:IsShown() then PW:Refresh() end
end)

local regen = CreateFrame("Frame")
regen:RegisterEvent("PLAYER_REGEN_ENABLED")
regen:SetScript("OnEvent", function()
    local native = _G.ProfessionsFrame
    if not native then return end
    if native:IsShown() then PW:CamelotAttach(native) else PW:CamelotDetach(native) end
end)

-- La colonne n'a de sens que sur la PAGE DE METIER. Sur la page d'ENSEMBLE (les vignettes des
-- metiers) il n'y a pas de metier courant : la colonne s'y dessine vide et, comme on elargissait le
-- cadre quand meme, on obtenait une bande vide a droite. Diagnostic du 2026-09-19 : ce n'etait pas
-- « la 1re ouverture echoue » mais « la page d'ensemble n'a rien a afficher » - au 2e clic on
-- atterrit sur un metier, d'ou l'illusion. `CraftingPage` est le signal sur : Blizzard la masque sur
-- l'ensemble (Blizzard_ProfessionsFrame.lua declare l'onglet recettes AddNamedTab(.., CraftingPage)).
local function onRecipesPage(native)
    return not native.CraftingPage or native.CraftingPage:IsShown()
end

-- Largeur de la colonne : au moins celle de sa barre d'onglets, sinon « Incoming » sort du cadre.
local function sizeColumn(self)
    self.docked = true
    self.standaloneKey, self.rerollKey, self._compact = nil, nil, nil
    self:_ApplyMode(true)
    if self.vanillaBtn then self.vanillaBtn:Hide() end
    -- Seule la rangée des VUES contraint encore la largeur. Les languettes de relation, elles, ont
    -- cédé la place à un sélecteur qui s'adapte à la colonne au lieu de la forcer à s'élargir : on
    -- ne mesure plus une rangée qui ne s'affiche pas ici (elle réclamait ~40 px pour rien).
    local colW = math.max(self.frame:GetWidth() or 310,
        (self._ViewTabsWidth and self:_ViewTabsWidth()) or 0)
    self.frame:SetWidth(colW)
    -- Dans CET ordre : la largeur du cadre est definitive, on recale les zones dessus, ET SEULEMENT
    -- APRES on pose la rangee -- elle se mesure sur `ordBody`, qui vient d'etre recale.
    if self._SyncOrdWidth then self:_SyncOrdWidth() end
    if self._PlaceOrdTabs then self:_PlaceOrdTabs(true) end   -- re-poser a la largeur definitive
    return colW
end

-- Elargir SANS toucher aux enfants de Blizzard : eux sont ancres TOPLEFT, ils ne bougent pas.
-- NE JAMAIS ecrire dans le SYSTEME DE PANNEAUX depuis du code addon. On a tente
-- `SetUIPanelAttribute(native, "width", fullW)` pour que le gestionnaire reserve notre largeur reelle
-- (sinon la fiche de personnage s'ouvre par-dessus notre colonne). Le jeu nous a nommes : « attempt
-- to compare local 'oldR' (a secret number value, while execution tainted by CraftingOrderClassic) »,
-- pile Menu -> ShowUIPanel -> EnterEditMode -> RefreshPartyFrames. Mecanisme, lisible dans
-- Blizzard_UIParentPanelManager : `RegisterUIPanel` remplit `UIPanelWindows`, donc
-- `SetUIPanelAttribute` va jusqu'a `SetFrameAttributes` -> `SetAttributeNoHandler` DEPUIS NOTRE CODE
-- -> les attributs securises du cadre sont teintes -> le dispatch `FramePositionDelegate:SetAttribute`
-- execute toute la chaine securisee en teinte -> la 1re lecture d'une valeur SECRETE leve. Sur l'Era
-- une taint donnait au pire un ADDON_ACTION_BLOCKED ; ici elle fait planter le code de Blizzard, et
-- le blame nous est impute nommement. Le chevauchement de panneaux est COSMETIQUE. On le garde.
local function widenHost(native, colW)
    native:SetWidth(nativeBaseW + colW + T().graftGap * 2)
end

-- DEUX MODES, un seul drapeau (`COC.db.camelotAccole`, bascule : /co accole).
--  * ENCASTRE (DEFAUT) : on elargit `ProfessionsFrame` et on reparente la colonne dedans. La colonne
--    devient alors protegee comme son hote : en combat on ne l'attache ni ne la detache (cf. regen).
--  * ACCOLE (option) : la colonne reste sur UIParent et s'ancre au bord droit du cadre, AU-DELA de la
--    bande d'onglets verticale (ancree dehors). Aucune ecriture chez Blizzard, et la colonne n'est
--    pas protegee : posee, elle reste utilisable en combat, et elle se cache si l'hote se ferme en
--    combat. Comme la greffe, elle ne se POSE qu'hors combat. Contrepartie : l'ensemble est plus large.
-- HISTOIRE, pour ne pas refaire l'erreur. Le 2026-09-19 l'accole est devenu le defaut parce qu'on
-- accusait l'elargissement d'etre la cause des centaines de refus des barres d'action en combat.
-- C'etait FAUX : les deux vraies causes, prouvees au journal puis au labo (TaintLab, COC desactive),
-- etaient nos menus UIDropDownMenu et notre emprunt de HelpPlate.Show (cf. _UI_Skin_Dropdown.lua et
-- _UI_Skin_HelpPlate.lua). Les deux corriges, l'encastre a repris sa place de defaut. Le drapeau a
-- change de nom a cette occasion : l'ancien (`camelotSide`) portait les essais de ce jour-la.
local function sideMode()
    return COC.db ~= nil and COC.db.camelotAccole == true
end

-- Accolee, la colonne est COLLEE a une fenetre qui affiche deja « Cuisine 31/75 » : repeter metier et
-- rang dans son titre ne dit rien de neuf. On nomme ce que la colonne EST, a CHAQUE ecriture du titre
-- (chaque Refresh reecrivait « Cuisine 31/75 », signale en jeu le 2026-09-19). Encastree, elle n'a
-- pas de titre du tout (chrome depouille). Surcharge posee ICI, comme les autres regles de Forever.
local baseSetTitle = PW._SetTitle
if baseSetTitle then
    function PW:_SetTitle(label, suffix)
        if self.docked and sideMode() then label, suffix = COC.L["Commandes"], nil end
        return baseSetTitle(self, label, suffix)
    end
end

-- De combien les onglets lateraux depassent A DROITE du cadre. Mesure, pas devinee : le nombre
-- d'onglets depend des metiers du joueur.
local function sideTabOverhang(native)
    local right = native:GetRight()
    if not right then return 0 end
    local out = 0
    local tabs = { native.ProfessionsOverviewTab }
    for i = 1, 7 do tabs[#tabs + 1] = native["Professions" .. i .. "Tab"] end
    for _, t in ipairs(tabs) do
        if t and t.IsShown and t:IsShown() and t.GetRight and t:GetRight() then
            local over = t:GetRight() - right
            if over > out then out = over end
        end
    end
    return out
end

-- Mode ACCOLE : on ne touche a rien chez Blizzard. Parent UIParent (donc jamais protegee), ancree au
-- bord droit du cadre, au-dela des onglets. Non deplacable quand meme : elle doit suivre son hote,
-- et la tirer romprait l'ancrage.
local function sideColumn(self, native)
    local f = self.frame
    f:SetMovable(false)
    f:RegisterForDrag()
    f:SetParent(UIParent)
    f:ClearAllPoints()
    -- Colle a la bande d'onglets (2 px, pas le GAP de 6 : accolee, la colonne doit lire comme le
    -- prolongement de la fenetre, pas comme un panneau qui flotte a cote). Et elle epouse la hauteur
    -- EXACTE de l'hote : TOP_INSET / BOT_INSET servaient a tenir DANS le chrome natif, ils n'ont plus
    -- de sens dehors -- ils laissaient la colonne plus courte en haut comme en bas.
    -- L'ecart des onglets est mesure dans les unites du cadre natif, que le gestionnaire de panneaux
    -- peut reduire (checkFit) ; l'ancre, elle, s'exprime dans celles de la colonne.
    local x = 2 + sideTabOverhang(native) * native:GetEffectiveScale() / f:GetEffectiveScale()
    f:SetPoint("TOPLEFT", native, "TOPRIGHT", x, 0)
    f:SetPoint("BOTTOMLEFT", native, "BOTTOMRIGHT", x, 0)
    if f.SetToplevel then f:SetToplevel(false) end
    f:SetFrameStrata(native:GetFrameStrata() or "MEDIUM")
    f:SetFrameLevel((native:GetFrameLevel() or 0) + 10)
    f:Show()
end

-- GREFFEE, ELLE N'EST PLUS UNE FENETRE.
--  * Plus deplacable : le kit rend toute fenetre draggable, et la tirer la sortait du cadre natif en
--    laissant une bande vide derriere elle (releve du 2026-09-19). Sa place appartient a son hote.
--    Rendu au detachement, ou elle redevient flottante (vue reroll, dock).
--  * Ancree HAUT **et** BAS : elle epouse la hauteur du cadre au lieu de garder la sienne (sinon
--    ~140 px de vide sous le pied de colonne, vu au 1er essai du POC).
--  * `SetToplevel(true)` et la strata « HIGH » ont du sens pour un cadre flottant ; pour l'enfant
--    d'un panneau GERE ils le decrochent de l'ordre d'affichage de son hote. Rang d'enfant ordinaire.
--  * Les ONGLETS LATERAUX de Blizzard semblaient recouvrir le dernier onglet de la colonne. Ce
--    n'etait pas geometrique mais un ordre d'AFFICHAGE : ils sont ancres HORS du cadre, et c'est
--    le niveau qui reglait tout. Une marge de retrait a bien ete ecrite le 2026-09-19, mesuree a
--    zero en jeu, donc sans effet : retiree plutot que laissee a faire illusion.
--  * Niveau MESURE sur les enfants du cadre, pas suppose : releve du 2026-09-19, cadre=1 mais
--    BookPage=100. Le +5 d'origine laissait la colonne 94 crans SOUS un fond opaque : affichee,
--    complete, bien placee... et invisible. Ce qui ressemblait a une colonne absente etait une
--    colonne enterree. Mesurer nous fait suivre un changement de numerotation Blizzard.
local function dockColumn(self, native)
    local f = self.frame
    f:SetMovable(false)
    f:RegisterForDrag()                   -- plus aucun bouton ne declenche le glisser
    f:SetParent(native)                   -- suit l'ouverture/fermeture et le deplacement du natif
    f:ClearAllPoints()
    f:SetPoint("TOPRIGHT", native, "TOPRIGHT", -T().graftGap, -T().graftTopInset)
    f:SetPoint("BOTTOMRIGHT", native, "BOTTOMRIGHT", -T().graftGap, T().graftBotInset)
    if f.SetToplevel then f:SetToplevel(false) end
    f:SetFrameStrata(native:GetFrameStrata() or "MEDIUM")
    local top = native:GetFrameLevel() or 0
    for _, child in ipairs({ native:GetChildren() }) do
        local lv = (child.GetFrameLevel and child:GetFrameLevel()) or 0
        if lv > top then top = lv end
    end
    f:SetFrameLevel(top + 10)
    f:Show()
end

-- Une colonne affichee mais DERRIERE le contenu natif, et depouillee de son fond, est indiscernable
-- d'une colonne absente : la geometrie et les niveaux sont donc les seuls temoins utiles.
-- `ordRelTabs` est une TABLE de boutons, pas un cadre - une ligne de diagnostic qui l'a pris pour un
-- cadre a casse l'attache le 2026-09-19. Une trace ne doit jamais faire tomber ce qu'elle observe.
local function traceAttach(self, native)
    if not (COC.Trace and COC.Trace:IsOn()) then return end
    local f, page = self.frame, native.BookPage or native
    tr("attach fini : shown=%s alpha=%s parent=%s protege=%s", tostring(f:IsShown()),
       tostring(f:GetAlpha()), tostring(f:GetParent() and f:GetParent():GetName()),
       tostring(f:IsProtected()))
    tr("attach geo : col %dx%d a x=%d | niveaux col=%d natif=%d page=%d",
       (f:GetWidth() or 0), (f:GetHeight() or 0), (f:GetLeft() or -1),
       (f:GetFrameLevel() or 0), (native:GetFrameLevel() or 0),
       (page.GetFrameLevel and page:GetFrameLevel() or -1))
    -- La rangée qui compte ICI est celle des VUES : c'est elle qui dimensionne la colonne depuis que
    -- la relation est passée au sélecteur. Tracer l'autre rapporterait la largeur d'une rangée qui
    -- ne s'affiche même pas en greffe — une mesure vraie, au sujet de la mauvaise chose.
    local tabs, nb = self.viewTabs, 0
    if type(tabs) == "table" then for _ in pairs(tabs.buttons or tabs) do nb = nb + 1 end end
    tr("attach contenu : %d onglets de vue, largeur rangee=%d", nb, tabRowWidth(tabs))
end

function PW:CamelotAttach(native)
    tr("attach appele : native=%s combat=%s baseW=%s", tostring(native ~= nil),
       tostring(lockedDown() and true or false), tostring(nativeBaseW))
    if not native or lockedDown() then return end
    if not onRecipesPage(native) then
        tr("attach refuse : page d'ensemble affichee, pas de metier courant")
        return self:CamelotDetach(native)
    end
    self:Build()
    -- Le depouillement n'a de sens qu'ENCASTREE : il sert a fondre la colonne dans le fond natif.
    -- ACCOLEE, elle est un panneau a part entiere et doit porter sa bordure, son titre et sa croix,
    -- sinon on obtient un cadre a moitie nu pose dans le vide (vu en jeu le 2026-09-19).
    local side = sideMode()
    if side then sideChrome(self.frame) else stripChrome(self.frame) end
    local colW = sizeColumn(self)
    if side then
        sideColumn(self, native)          -- accole : aucune ecriture chez Blizzard (titre : cf. _SetTitle)
    else
        widenHost(native, colW)           -- encastre : on elargit le cadre natif (cf. en-tete)
        hostWidened = true
        dockColumn(self, native)
    end
    -- Le prolongement du fond n'a de sens qu'ENCASTRÉ : accolée, la bande n'existe pas.
    if PW._FillPageArt then PW:_FillPageArt(native, not side and T().pageFill ~= false) end
    traceAttach(self, native)
    self:Refresh()
end

function PW:CamelotDetach(native)
    tr("detach appele : combat=%s baseW=%s", tostring(lockedDown() and true or false), tostring(nativeBaseW))
    if lockedDown() then
        -- Rejoue a PLAYER_REGEN_ENABLED (cf. regen). Une exception : ACCOLEE et jamais greffee, la
        -- colonne n'est pas protegee, donc on la cache tout de suite ; sinon elle restait seule a
        -- l'ecran quand l'hote se fermait en plein combat. Parent, ancres et chrome attendent la fin.
        if self.frame and not hostWidened and not self.frame:IsProtected() then self.frame:Hide() end
        return
    end
    if PW._FillPageArt then PW:_FillPageArt(native, false) end   -- la bande part avec l'elargissement
    if native and nativeBaseW and hostWidened then
        native:SetWidth(nativeBaseW)      -- seulement si c'est NOUS qui l'avons elargi
        hostWidened = nil
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
        self.frame:SetMovable(true)
        self.frame:RegisterForDrag("LeftButton")
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
    -- Largeur d'origine capturée ICI, à la première vue du cadre, et PLUS dans l'attache. Quand elle
    -- vivait dans l'attache, un combat qui faisait sauter celle-ci laissait la valeur vide : le
    -- détachement suivant ne restaurait alors JAMAIS la largeur, et on se retrouvait avec un cadre
    -- natif resté large et notre colonne repartie sur UIParent (relevé en jeu le 2026-09-19).
    nativeBaseW = nativeBaseW or native:GetWidth()
    tr("cablage : largeur d'origine=%s, deja ouverte=%s", tostring(nativeBaseW), tostring(native:IsShown()))
    -- Appel DIRECT, sans report. On a cru un temps (2026-09-19) que ces hooks teintaient la pile du
    -- clic d'onglet ; faux : ce clic cache le livre des metiers AVANT d'afficher la page de recettes,
    -- et la ligne refusee venait avant nos hooks (la contamination venait de HelpPlate.Show).
    Api.HookScriptSafe(native, "OnShow", function(f) PW:CamelotAttach(f) end)
    Api.HookScriptSafe(native, "OnHide", function(f) PW:CamelotDetach(f) end)
    -- On suit aussi la PAGE : passer de l'ensemble a un metier (et l'inverse) ne rouvre pas la
    -- fenetre, donc son OnShow ne suffit pas a nous prevenir.
    local page = native.CraftingPage
    if page then
        Api.HookScriptSafe(page, "OnShow", function() PW:CamelotAttach(native) end)
        Api.HookScriptSafe(page, "OnHide", function() PW:CamelotDetach(native) end)
    end
    tr("cablage page recettes : %s", tostring(page ~= nil))
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

-- /co accole : bascule entre colonne ENCASTREE et colonne ACCOLEE (cf. l'en-tete de sideMode).
-- Re-greffe tout de suite si la fenetre est ouverte, pour voir le resultat sans /reload.
function PW:CamelotSideCmd()
    if not COC.db then return end
    local L = COC.L
    -- En combat ni l'attache ni le detachement ne passent : basculer quand meme laissait l'ancien
    -- mode en place (cadre natif encore elargi) sous le nouveau a la sortie du combat.
    if lockedDown() then
        print("|cFF33DD88Crafting Order|r " .. L["Impossible en combat — réessaie après le combat."])
        return
    end
    COC.db.camelotAccole = not sideMode()
    local native = _G.ProfessionsFrame
    if native and native:IsShown() then
        self:CamelotDetach(native)
        self:CamelotAttach(native)
    end
    print("|cFF33DD88Crafting Order|r " ..
        (COC.db.camelotAccole and L["colonne ACCOLÉE à la fenêtre de métier"]
                              or L["colonne ENCASTRÉE dans la fenêtre de métier"]))
end
