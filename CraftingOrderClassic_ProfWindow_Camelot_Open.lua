-- CraftingOrderClassic_ProfWindow_Camelot_Open.lua — OUVRIR un metier dans la fenetre NATIVE de
-- WoW: Forever, et rediriger vers elle toutes nos entrees (bouton minimap, /co prof, clic du suivi).
-- Extrait de _ProfWindow_Camelot.lua le 2026-09-19 (anti-monolithe : le fichier passait a 514 lignes).
-- La greffe (cette colonne cote a cote avec la fenetre) reste la-bas ; ici on ne fait qu'OUVRIR.

local COC = CraftingOrderClassic
local PW  = COC.ProfWindow
local Api = COC.Api
if not (PW and Api) then return end
-- Meme garde de saveur que la greffe : liste dans les QUATRE .toc (parite), donc charge aussi sur
-- l'Era, ou il ne doit surtout rien remplacer.
if not Api.IS_MAINLINE then return end

-- ---------------------------------------------------------------- ouverture d'un métier

-- Clé de métier COC → `skillLineID` du client, ce qu'attend l'ouvreur natif. Les valeurs rendues
-- par `GetProfessions` sont des index de LIVRE DE SORTS, pas des métiers : seul
-- `GetProfessionInfo` donne le nom localisé et la ligne de compétence. On repasse par
-- `ResolveProfession` (alias FR/DE/ES de CraftLink), le même résolveur que Directory_Skills —
-- jamais une comparaison de libellés écrite à la main.
-- CraftLink est une bibliothèque LibStub, JAMAIS une globale : la garde d'origine testait
-- `_G.CraftLink`, toujours nil, et la fonction rendait nil dès sa 1re ligne — l'ouverture directe
-- d'un métier n'a donc jamais été tentée, on tombait à chaque fois sur la page d'ensemble.
-- Relevé le 2026-09-19 : `/co métier cuisine` ouvrait « Professions » alors que GetProfessions()
-- rendait bien 6, 8, 5, 9, 7. Ordre sur Forever, lu dans le livre des métiers de Blizzard :
-- prof1, prof2, SECOURISME (pas d'archéologie), pêche, cuisine ; 7e retour de GetProfessionInfo
-- = identifiant de la ligne de métier.
local function skillLineFor(profKey)
    local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    if not (profKey and lib and _G.GetProfessions and _G.GetProfessionInfo) then return nil end
    local p1, p2, faid, fish, cook = GetProfessions()
    for _, idx in pairs({ p1, p2, faid, fish, cook }) do    -- pairs : sauter les trous sans s'arrêter
        local name, _, _, _, _, _, skillLine = GetProfessionInfo(idx)
        if name and skillLine and lib:ResolveProfession(name) == profKey then return skillLine end
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

-- Pose au login : les methodes qu'on remplace (OpenFor, _OpenCompact, OpenForReroll) sont definies
-- par des fichiers charges avant ET apres celui-ci ; seul le login garantit qu'elles existent toutes.
local boot = CreateFrame("Frame")
Api.RegisterEventSafe(boot, "PLAYER_LOGIN")
boot:SetScript("OnEvent", function() installOpeners() end)
