-- CraftingOrderClassic_QuestSheet.lua — FICHE DE QUÊTE réutilisable : affiche (ou fait écrire) une
-- commande sous la forme d'une vraie quête du jeu. Deux modes, deux hôtes :
--   · ÉDITION — l'auteur tape titre et récit DANS LA TYPOGRAPHIE FINALE : ce qu'il voit est
--     littéralement ce que le destinataire verra ;
--   · LECTURE — l'affichage d'une quête reçue.
-- Le CONTENU se construit dans n'importe quel cadre hôte (`BuildContent`) : la popup autonome, ou le
-- volet de détail du journal. Rien n'est stocké sur l'hôte — plusieurs fiches coexistent sans se
-- marcher dessus.
--
-- ⚠️ Ce fichier est écrit pour être PORTABLE : il est destiné à resservir dans RPQuestMaster (module
-- Total RP 3). Il ne dépend de COC que par `COC.L` (locale) et `COC.OrdersCodec` (bornes +
-- assainissement du texte libre) — rien de l'onglet Commande, rien du kit Skin maison.
--
-- CONTRAT PUBLIC
--   local c = QuestSheet:BuildContent(host, { buttons = true, close = true })   -- une fois
--   QuestSheet:FillContent(c, {
--       title, text, giver,
--       objectives = { { text = "…", done = false }, … },   -- ou `objective` (chaîne unique)
--       reward, editable, acceptText, onAccept = function(title, text) end,
--   })
--   QuestSheet:Open(data)   -- raccourci : la popup autonome
--   QuestSheet:Close()
--
-- Chrome EMPRUNTÉ au client : polices `QuestTitleFont` / `QuestFont` / `QuestFontNormalSmall` (celles
-- de QuestInfo.xml) et filet `UI-HorizontalBreak`. ⚠️ Ces polices sont NOIRES (r=g=b=0, calibrées
-- pour le parchemin) : sans fond clair le texte serait invisible.
-- Aucun bouton sécurisé ici : la fiche écrit et affiche, elle ne crafte pas.

local COC   = CraftingOrderClassic
local L     = COC.L
local Sheet = {}
COC.QuestSheet = Sheet

local W, H, PAD = 380, 330, 22
local MAX_OBJ   = 6     -- lignes d'objectifs affichables (une vraie quête en a rarement plus)
local OBJ_H     = 18
local NAME = "CraftingOrderQuestSheet"

local function font(name, fallback) return _G[name] or _G[fallback] end
-- Libellés standards : ceux du CLIENT. `QUEST_OBJECTIVES` est le global que le VRAI cadre de quête
-- affiche (cf. QuestInfoObjectivesHeader dans QuestInfo.xml) — donc traduit dans toutes les langues
-- et formulé exactement comme le jeu. Notre locale ne sert plus que de filet.
local function gs(global, fallback) return _G[global] or fallback end

-- ⚠️ LE fond de quête « authentique » a été ESSAYÉ ET REJETÉ (deux captures user, 2026-07-28) :
-- l'atlas `QuestBG-Parchment` rendait une couture nette et des stries au tiers bas, à 430 px comme à
-- 330. Mesure au PIL sur l'export local, qui explique tout :
--     QuestFrame\QuestBG                       512×512, zone PEINTE 300×336 (le reste = remplissage
--                                              transparent de calage power-of-2)
--     ACHIEVEMENTFRAME\…Parchment-Horizontal   512×256, zone peinte 512×256 — PLEINE
-- Une zone peinte à ratio fixe ne se redimensionne pas librement : c'est le piège « un fichier d'art
-- ment sur son étendue peinte », déjà payé ailleurs dans cette codebase. Le parchemin des hauts faits
-- est peint bord à bord, donc sûr à n'importe quelle taille.
-- Pas de tuilage non plus : à 512×256 un `SetVertTile` remettrait une couture à 256 px de haut. Un
-- simple étirement d'une texture de bruit est imperceptible — zéro couture, c'est ce qu'on veut.
local PARCHMENT = "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal"

function Sheet.ApplyParchment(tex) tex:SetTexture(PARCHMENT) end

-- Bornes + assainissement : une seule autorité, celle du protocole (Orders_Codec, testée en headless).
local function caps()
    local C = COC.OrdersCodec
    return (C and C.TITLE_MAX) or 80, (C and C.TEXT_MAX) or 180
end

-- Filet de séparation, à sa TAILLE NATIVE 256×32 — celle que Blizzard lui donne dans QuestFrame.xml
-- (QuestGreetingFrameHorizontalBreak). Un art décoratif redimensionné hors de son ratio se voit.
local function divider(parent, anchorFrame, anchorPt, y)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetTexture("Interface\\QuestFrame\\UI-HorizontalBreak")
    t:SetSize(256, 32)
    t:SetPoint("TOP", anchorFrame or parent, anchorPt or "TOP", 0, y or 0)
    return t
end

-- Champ de saisie posé SUR le parchemin, sans art de champ : la surface de saisie et la surface
-- d'aperçu sont la même. `SetMaxBytes` borne en OCTETS côté client (gère l'UTF-8 tout seul) ; le
-- filtre OnTextChanged retire les caractères interdits À LA FRAPPE — on ne peut littéralement pas
-- taper un `|`, donc pas de faux lien ni de couleur. `Codec.CleanText` reste l'autorité à l'envoi
-- (lui seul rogne aussi les blancs de bord, ce qui serait hostile pendant la frappe).
local function makeInput(parent, fontName, multi, maxBytes, onChanged)
    local b = CreateFrame("EditBox", nil, parent)
    b:SetFontObject(font(fontName, "GameFontNormal"))
    b:SetAutoFocus(false)
    b:SetMultiLine(multi and true or false)
    b:SetMaxBytes(maxBytes)
    b:SetTextInsets(0, 0, 0, 0)
    b:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
    b:SetScript("OnTextChanged", function(s)
        if s._guard then return end
        local raw = s:GetText() or ""
        local clean = raw:gsub("[|~]", ""):gsub("%c", " ")
        if clean ~= raw then s._guard = true; s:SetText(clean); s._guard = nil end
        if onChanged then onChanged() end
    end)
    return b
end

local function black(host, fontName)
    local fs = host:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(font(fontName, "GameFontBlackSmall"))
    fs:SetJustifyH("LEFT")
    return fs
end

-- ------------------------------------------------------------------
-- Construction du contenu
-- ------------------------------------------------------------------
local function buildHeader(c, host)
    c.title = black(host, "QuestTitleFont")
    c.title:SetPoint("TOPLEFT", PAD, -20)
    c.title:SetPoint("RIGHT", host, "RIGHT", -PAD - 20, 0)
    c.title:SetJustifyV("TOP")

    c.titleBox = makeInput(host, "QuestTitleFont", false, c.maxes[1],
        function() Sheet:_UpdateCounter(c) end)
    c.titleBox:SetPoint("TOPLEFT", PAD, -20)
    c.titleBox:SetPoint("RIGHT", host, "RIGHT", -PAD - 20, 0)
    c.titleBox:SetHeight(26)

    c.giver = black(host, "QuestFontNormalSmall")
    c.giver:SetPoint("TOPLEFT", PAD, -50)
    divider(host, host, "TOP", -64)
end

-- Pied : boutons (optionnels), récompense, pool d'objectifs, en-tête « Objectifs », filet.
-- `base` = hauteur réservée au bas ; sans boutons le bloc descend jusqu'au bord.
local function buildFooter(c, host, withButtons)
    local base = withButtons and 44 or 10
    if withButtons then
        c.accept = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
        c.accept:SetSize(120, 22); c.accept:SetPoint("BOTTOMRIGHT", -PAD, 14)
        -- UIPanelButtonTemplate ancre son texte BOTTOM,0,12 (calibré pour h=32) : recentrer sous 32 px.
        local at = c.accept:GetFontString(); if at then at:ClearAllPoints(); at:SetPoint("CENTER") end
        c.accept:SetScript("OnClick", function() Sheet:_Accept(c) end)

        c.cancel = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
        c.cancel:SetSize(90, 22); c.cancel:SetPoint("RIGHT", c.accept, "LEFT", -8, 0)
        local ct = c.cancel:GetFontString(); if ct then ct:ClearAllPoints(); ct:SetPoint("CENTER") end
        c.cancel:SetScript("OnClick", function() Sheet:Close() end)
    end

    c.reward = black(host, "QuestFontNormalSmall")
    c.reward:SetPoint("BOTTOMLEFT", PAD, base)

    c.objLines = {}
    for i = 1, MAX_OBJ do
        local fs = black(host, "QuestFontNormalSmall")
        fs:SetPoint("BOTTOMLEFT", PAD, base + 20 + (i - 1) * OBJ_H)
        fs:SetPoint("RIGHT", host, "RIGHT", -PAD, 0)
        fs:Hide()
        c.objLines[i] = fs
    end
    c.objBase = base

    c.objHeader = black(host, "QuestTitleFont")
    c.objHeader:SetText(gs("QUEST_OBJECTIVES", L["Objectifs"]))
    c.objHeader:SetPoint("BOTTOMLEFT", PAD, base + 20 + OBJ_H)
    c.div2 = divider(host, c.objHeader, "TOP", 26)
end

-- ⚠️ Ne JAMAIS ancrer un bord sur le point « TOP » du filet : ce point est au MILIEU de sa largeur,
-- un BOTTOMRIGHT posé dessus donnerait un corps de texte à demi-largeur. On compose : TOPLEFT pour
-- le coin haut, RIGHT sur l'hôte pour le bord droit, BOTTOM pour la limite basse.
local function buildBody(c, host)
    c.counter = black(host, "QuestFontNormalSmall")
    c.counter:SetPoint("RIGHT", host, "RIGHT", -PAD, 0)
    c.counter:SetPoint("BOTTOM", c.div2, "TOP", 0, 2)
    c.counter:SetJustifyH("RIGHT")

    -- Le récit d'une VRAIE quête fait vingt lignes : le volet doit DÉFILER, sinon le texte est coupé
    -- en pleine phrase (« south of Dustqu… », capture user). Molette seule, sans barre : sur un
    -- parchemin une scrollbar métal jurerait, et le geste est celui du journal de quêtes natif.
    -- La SAISIE, elle, est plafonnée à 180 octets par le protocole — elle ne déborde jamais.
    local sc = CreateFrame("ScrollFrame", nil, host)
    sc:SetPoint("TOPLEFT", PAD, -84)
    sc:SetPoint("RIGHT", host, "RIGHT", -PAD, 0)
    sc:SetPoint("BOTTOM", c.div2, "TOP", 0, 4)
    sc:EnableMouseWheel(true)
    sc:SetScript("OnMouseWheel", function(s, d)
        local span = math.max((s.child:GetHeight() or 0) - s:GetHeight(), 0)
        s:SetVerticalScroll(math.min(math.max(s:GetVerticalScroll() - d * 24, 0), span))
    end)
    local child = CreateFrame("Frame", nil, sc)
    child:SetSize(10, 10); sc:SetScrollChild(child); sc.child = child
    c.bodyScroll = sc

    c.body = child:CreateFontString(nil, "OVERLAY")
    c.body:SetFontObject(font("QuestFont", "GameFontHighlight"))
    c.body:SetPoint("TOPLEFT")
    c.body:SetJustifyH("LEFT"); c.body:SetJustifyV("TOP")

    c.bodyBox = makeInput(host, "QuestFont", true, c.maxes[2], function() Sheet:_UpdateCounter(c) end)
    c.bodyBox:SetPoint("TOPLEFT", PAD, -84)
    c.bodyBox:SetPoint("RIGHT", host, "RIGHT", -PAD, 0)
    c.bodyBox:SetPoint("BOTTOM", c.counter, "TOP", 0, 4)
end

function Sheet:BuildContent(host, opts)
    opts = opts or {}
    local tMax, xMax = caps()
    local c = { host = host, maxes = { tMax, xMax } }
    if opts.close ~= false then
        local close = CreateFrame("Button", nil, host, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", 0, 0)
        close:SetScript("OnClick", function() Sheet:Close() end)
    end
    buildHeader(c, host)
    buildFooter(c, host, opts.buttons ~= false)   -- avant le corps : il s'ancre sur le filet du pied
    buildBody(c, host)
    return c
end

-- ------------------------------------------------------------------
-- Remplissage
-- ------------------------------------------------------------------
function Sheet:_UpdateCounter(c)
    if not (c and c.counter) then return end
    local t, x = #(c.titleBox:GetText() or ""), #(c.bodyBox:GetText() or "")
    local warn = (t >= c.maxes[1] or x >= c.maxes[2])
    c.counter:SetText(string.format("%s%d/%d  ·  %d/%d|r",
        warn and "|cFFAA3311" or "|cFF555555", t, c.maxes[1], x, c.maxes[2]))
end

-- Les objectifs poussent le reste VERS LE HAUT : l'en-tête se ré-ancre au-dessus de la dernière ligne
-- visible, le filet suit l'en-tête, et le corps du récit s'arrête au filet — toute la cascade tient
-- par les ancres, aucune hauteur recalculée à la main.
-- ⚠️ Un objectif N'EST PAS une ligne. « Look for Gremni Longbeard northwest of the Den of Haal'esh,
-- to the far west of Honor Hold » s'enroule sur trois lignes. Avec un pas FIXE de 18 px, il grandit
-- vers le haut depuis son ancre basse et passe PAR-DESSUS l'en-tête « Objectifs » (capture user
-- 2026-07-28). On empile donc du bas vers le haut en MESURANT chaque ligne après l'avoir remplie.
-- La 1re de la liste se lit en premier, donc en haut : on parcourt à l'envers plutôt que d'inverser
-- la liste (l'appelant garde son ordre naturel).
local function fillObjectives(c, data)
    local list = data.objectives
    if not list and data.objective then list = { { text = data.objective } } end
    list = list or {}
    local n = math.min(#list, MAX_OBJ)
    local w = math.max((c.host:GetWidth() or 0) - 2 * PAD, 60)
    for i = 1, MAX_OBJ do c.objLines[i]:SetShown(i <= n) end
    local y = c.objBase + 20
    for i = n, 1, -1 do
        local fs, o = c.objLines[i], list[i]
        fs:ClearAllPoints()
        fs:SetWidth(w)                    -- largeur EXPLICITE : sans elle, pas d'enroulement mesurable
        fs:SetPoint("BOTTOMLEFT", c.host, "BOTTOMLEFT", PAD, y)
        fs:SetText(o.text or "")
        -- Objectif rempli : grisé, comme une ligne accomplie du journal natif.
        if o.done then fs:SetTextColor(0.35, 0.35, 0.35) else fs:SetTextColor(0, 0, 0) end
        y = y + math.max(fs:GetStringHeight() or 0, OBJ_H) + 2
    end
    c.objHeader:ClearAllPoints()
    c.objHeader:SetPoint("BOTTOMLEFT", c.host, "BOTTOMLEFT", PAD, y + 4)
    c.objHeader:SetShown(n > 0)
    c.div2:SetShown(n > 0)
end

function Sheet:FillContent(c, data)
    data = data or {}
    local edit = data.editable and true or false
    c._onAccept = data.onAccept

    c.title:SetText(data.title or (edit and "" or L["Sans titre"]))
    c.titleBox:SetText(data.title or "")
    c.bodyBox:SetText(data.text or "")
    -- Le récit défile : sa largeur et la hauteur de l'enfant se recalculent à chaque remplissage,
    -- et on remonte en haut (sinon on hérite du défilement de l'entrée précédente).
    local bw = math.max((c.bodyScroll:GetWidth() or 0) - 2, 60)
    c.body:SetWidth(bw)
    c.body:SetText(data.text or "")
    c.bodyScroll.child:SetSize(bw, math.max((c.body:GetStringHeight() or 0) + 4, 10))
    c.bodyScroll:SetVerticalScroll(0)
    c.giver:SetText(data.giver or "")
    c.reward:SetText(data.reward and (gs("REWARD", L["Récompense :"]) .. " " .. data.reward) or "")
    fillObjectives(c, data)

    c.title:SetShown(not edit); c.titleBox:SetShown(edit)
    c.bodyScroll:SetShown(not edit); c.bodyBox:SetShown(edit)
    c.counter:SetShown(edit)
    if c.accept then
        c.accept:SetShown(data.onAccept ~= nil)
        if data.onAccept then c.accept:SetText(data.acceptText or gs("ACCEPT", L["Accepter"])) end
        c.cancel:SetText(data.onAccept and gs("CANCEL", L["Annuler"]) or gs("CLOSE", L["Fermer"]))
    end
    if edit then self:_UpdateCounter(c) end
end

-- Le texte remis à l'appelant est celui que le PROTOCOLE laissera passer : on repasse par
-- Codec.CleanText plutôt que de rendre la saisie brute. Ainsi ce qui est posté est exactement ce que
-- l'auteur a vu, sans divergence possible entre l'aperçu et le fil.
function Sheet:_Accept(c)
    local cb = c and c._onAccept
    if not cb then return self:Close() end
    local C = COC.OrdersCodec
    local t, x = c.titleBox:GetText() or "", c.bodyBox:GetText() or ""
    if C and C.CleanText then
        t = C.CleanText(t, c.maxes[1])
        x = C.CleanText(x, c.maxes[2])
    end
    self:Close()
    cb(t ~= "" and t or nil, x ~= "" and x or nil)
end

-- ------------------------------------------------------------------
-- La popup autonome
-- ------------------------------------------------------------------
function Sheet:Frame()
    if self.frame then return self.frame end
    local f = CreateFrame("Frame", NAME, UIParent, "BackdropTemplate")
    f:SetSize(W, H); f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG"); f:SetToplevel(true)
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    if f.SetBackdrop then
        f:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
                        insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    end
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 5, -5); bg:SetPoint("BOTTOMRIGHT", -5, 5)
    Sheet.ApplyParchment(bg)
    self.frame = f
    self.content = self:BuildContent(f, { buttons = true, close = true })
    if UISpecialFrames then tinsert(UISpecialFrames, NAME) end   -- Échap ferme
    f:Hide()
    return f
end

function Sheet:Open(data)
    local f = self:Frame()
    self:FillContent(self.content, data)
    f:Show(); f:Raise()
    if data and data.editable then self.content.titleBox:SetFocus() end
end

function Sheet:Close()
    if self.frame then self.frame:Hide() end
    if self.content then self.content._onAccept = nil end
end
