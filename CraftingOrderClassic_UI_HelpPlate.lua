-- CraftingOrderClassic_UI_HelpPlate.lua — AIDE CONTEXTUELLE de la FENÊTRE PRINCIPALE (« bouton i »).
-- Même système natif que la Vue Métier (kit _UI_Skin_HelpPlate.lua : voile qui fige les clics + bulles),
-- mais la fenêtre principale a 7 ONGLETS partageant le cadre → l'aide est DISPATCHÉE selon l'onglet
-- actif (`UI.activeTab`). Un seul bouton `i`, un registre `_HelpConfigFor(tab)` : chaque onglet fournit
-- ses zones SPEC (nodes), l'accès à ses sections (sec), ses textes et ses contrôles hors-SPEC. Palier
-- courant : l'onglet Commande (post) ; Récolte/Artisans/… s'ajouteront comme de nouvelles branches.
-- Échap-ferme-l'aide + icônes inline sont dans le kit → gratuits ici. NE PAS confondre avec l'onglet
-- « Aide » (_UI_Help.lua, page de doc défilante).

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = COC.UI.Skin
local L    = COC.L

-- Pièce d'or INLINE : la MÊME texture que l'outil de prix Lazy Gold, injectée via %s (clé sans texture).
local COIN = "|TInterface\\MoneyFrame\\UI-GoldIcon:13:13:0:0|t"

-- Textes des bulles de l'onglet Commande (id de section SPEC → texte court localisé). reagentsList et
-- le portrait réutilisent des clés existantes déjà traduites (pas de doublon).
local function postTexts()
    return {
        filters      = string.format(L["Filtre les plans : recherche par nom, filtre par qualité, filtre par réactif, et l'outil %s « 123 » de Lazy Gold (prix/rentabilité)."], COIN),
        plans        = L["La liste des plans. Choisis celui que tu veux faire réaliser par un artisan."],
        ItemSelected = L["L'objet choisi. La pastille « Je fournis » indique que tu apportes tous les composants toi-même."],
        reagentsList = L["Coche les réactifs que TU fournis toi-même (le reste reste à la charge de l'artisan)."],
        price        = L["La commission que tu proposes à l'artisan pour ce craft."],
        scope        = L["La portée : diffuser à tous, ou restreindre (guilde / amis)."],
        artisans     = L["Le destinataire : toute la source sélectionnée, ou un artisan précis."],
    }
end

-- Textes de l'onglet Récolte (miroir de Commande). scope réutilise la clé de Commande (même sens).
local function gatherTexts()
    return {
        filters      = L["Recherche une ressource par nom."],
        verPills     = L["Extensions : filtre les ressources d'une extension (ex. Élémentaire)."],
        resources    = L["La liste des ressources. Choisis celle que tu veux faire récolter."],
        ItemSelected = L["La ressource choisie."],
        qtyRow       = L["À l'unité ou par pile, et la quantité voulue."],
        price        = L["Le prix que tu proposes au récolteur."],
        scope        = L["La portée : diffuser à tous, ou restreindre (guilde / amis)."],
        gatherers    = L["Le destinataire : toute la source, ou un récolteur précis."],
    }
end

-- Textes de l'onglet Artisans (annuaire social). Pas de contrôle hors-SPEC (ni portrait ni Poster).
local function artisansTexts()
    return {
        sources      = L["Filtre l'annuaire par source : guilde, amis, ajoutés manuellement, croisés, ou les joueurs en sourdine."],
        addPlayer    = L["Ajoute un joueur manuellement (+), rafraîchis l'annuaire, ou active le repérage."],
        profFilter   = L["Filtre les artisans par métier."],
        artisansList = L["La liste des artisans connus. Survole un nom pour ses métiers ; pastille verte = a l'addon et répond, jaune = en ligne sans l'addon, grise = hors ligne."],
    }
end

-- Textes de l'onglet Mes artisans (vue agrégée des métiers du compte).
local function myArtisansTexts()
    return {
        shareBar  = L["Partage tes rerolls sur le réseau (les autres voient tes métiers), et choisis le perso mis en « vitrine »."],
        allRealm  = L["Tous les plans du royaume : la liste agrégée de toutes tes recettes, au lieu du découpage par métier (Lazy Gold requis)."],
        profsList = L["Tes métiers (tous les persos du compte). Choisis-en un pour voir ses recettes à droite."],
        recTools  = L["En-tête des recettes du métier choisi : bouton « Manquantes » et outils de prix (Lazy Gold)."],
        recList   = L["Les recettes du métier sélectionné (ou tous les plans du royaume)."],
    }
end

-- Config d'aide d'un onglet, ou nil (onglet sans aide). controls = frames hors-SPEC (portrait, Poster).
function UI:_HelpConfigFor(tab)
    if tab == "post" then
        return {
            nodes = UI.POST and UI.POST.helpNodes,
            sec   = function(id) return UI:PostSec(id) end,
            texts = postTexts(),
            controls = {
                { frame = UI.frame and UI.frame._portraitBtn, text = L["Cliquer pour changer de métier"], dir = "DOWN" },
                { frame = UI.postBtn, text = L["Poster : envoie la commande au(x) destinataire(s) choisi(s)."], dir = "UP" },
            },
        }
    end
    if tab == "gather" then
        return {
            nodes = UI.GATHER and UI.GATHER.helpNodes,
            sec   = function(id) return UI:GatherSec(id) end,
            texts = gatherTexts(),
            controls = {
                { frame = UI.frame and UI.frame._portraitBtn, text = L["Cliquer pour changer de métier"], dir = "DOWN" },
                { frame = UI.gatherBtn, text = L["Poster : envoie la commande au(x) destinataire(s) choisi(s)."], dir = "UP" },
            },
        }
    end
    if tab == "artisans" then
        return {
            nodes = UI.ART and UI.ART.helpNodes,
            sec   = function(id) return UI:ArtSec(id) end,
            texts = artisansTexts(),
        }
    end
    if tab == "myartisans" then
        return {
            nodes = UI.MYART and UI.MYART.helpNodes,
            sec   = function(id) return UI:MyArtSec(id) end,
            texts = myArtisansTexts(),
        }
    end
    -- Carnet : onglet AD-HOC (pas de SPEC) → uniquement des contrôles pointés à la main.
    if tab == "orders" then
        return {
            controls = {
                { frame = UI.orderFilterDD, dir = "DOWN",
                  text = L["Filtre ton carnet : commandes En cours, Archivées, ou Confiées (gardées pour un artisan)."] },
                { frame = _G.CraftingOrderOrdersScroll, dir = "LEFT",
                  text = L["Le Carnet = TES commandes postées. Accepter/livrer se fait dans la Vue Métier, pas ici ; quand une commande t'est remise, le bouton « J'ai reçu » confirme la réception."] },
            },
        }
    end
    return nil
end

-- Assemble les entrées de l'onglet actif (zones SPEC + contrôles) et ouvre le voile natif.
function UI:_ShowHelp()
    if not self.frame then return end
    local cfg = self:_HelpConfigFor(self.activeTab)
    if not cfg then return end
    local entries = {}
    local function add(fr, txt, dir)
        if fr and txt and fr:IsShown() then entries[#entries + 1] = { frame = fr, text = txt, dir = dir } end
    end
    for _, n in ipairs(cfg.nodes or {}) do add(cfg.sec(n.id), cfg.texts[n.id], n.dir) end
    for _, c in ipairs(cfg.controls or {}) do add(c.frame, c.text, c.dir) end
    Skin.ShowHelp(self.frame, entries, self.helpBtn)
end

function UI:_ToggleHelp()
    if Skin.HelpIsOpen() then Skin.HideHelp() else self:_ShowHelp() end
end

-- Bouton `i` hors-cadre en haut à gauche (dépendance molle : sans Blizzard_HelpPlate, pas de bouton).
function UI:_BuildHelp(f)
    if not HelpPlate then return end
    self.helpBtn = Skin.MakeHelpButton(f, function() UI:_ToggleHelp() end, {
        point   = { "CENTER", f, "TOPLEFT", 8, 6 },
        tooltip = L["Aide : survole les zones surlignées pour comprendre chaque fonction."],
    })
end

-- Tutoriel one-shot : la 1re fois qu'on arrive sur un onglet AIDÉ (aujourd'hui Commande — et la minimap
-- ouvre justement toujours sur Commande). Flag persistant compte PAR onglet (db.helpSeen[tab]). Différé
-- (positions valides seulement après le Show) ; marqué « vu » uniquement quand on l'affiche vraiment.
function UI:_MaybeAutoHelp(tab)
    -- Garde frame:IsShown() : le ShowTab("orders") de Build (fenêtre CACHÉE) ne doit PAS armer la file —
    -- sinon il bloquerait le tuto de l'onglet réellement ouvert ensuite (Commande). Seul un ShowTab
    -- sur fenêtre VISIBLE arme le tutoriel.
    if not (HelpPlate and COC.db and UI.frame and UI.frame:IsShown() and self:_HelpConfigFor(tab)) then return end
    COC.db.helpSeen = COC.db.helpSeen or {}
    if COC.db.helpSeen[tab] or UI._helpAutoQueued then return end
    UI._helpAutoQueued = true
    local run = function()
        UI._helpAutoQueued = nil
        if COC.db.helpSeen and not COC.db.helpSeen[tab]
           and UI.frame and UI.frame:IsShown() and UI.activeTab == tab then
            COC.db.helpSeen[tab] = true
            UI:_ShowHelp()
        end
    end
    if C_Timer and C_Timer.After then C_Timer.After(0.4, run) else run() end
end
