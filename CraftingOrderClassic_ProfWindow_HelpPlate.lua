-- CraftingOrderClassic_ProfWindow_HelpPlate.lua — AIDE CONTEXTUELLE de la Vue Métier (« bouton i »).
-- Glue entre le kit générique (_UI_Skin_HelpPlate.lua) et cette fenêtre : le bouton `i` hors-cadre + le
-- TEXTE des bulles (contenu localisé, court — le détail vit dans l'onglet Aide, cf. _UI_Help.lua).
-- Les ZONES et leur direction de bulle sont déclarées dans la SPEC (_ProfWindow_Layout.lua : champs
-- help/helpDir) → exposées en PW.helpNodes ; ici on ne fait que MAPPER id → texte.

local COC  = CraftingOrderClassic
local Skin = COC.UI.Skin
local PW   = COC.ProfWindow
local L    = COC.L

-- Icônes INLINE : les MÊMES textures que dans la liste (demande user → la bulle montre l'icône exacte).
--   COIN = indicateur de rentabilité (LazyGold GOLD_ICON) ;
--   BEST = badge « meilleur coût/point » posé sur le plan conseillé pour monter (Leveling ICON.best).
-- Injectées via %s pour garder les clés de locale sans texture (les traducteurs voient une phrase propre).
local COIN = "|TInterface\\MoneyFrame\\UI-GoldIcon:13:13:0:0|t"
local BEST = "|TInterface\\GossipFrame\\AuctioneerGossipIcon:14:14:0:0|t"

-- Texte par id de section SPEC. Court exprès : une bulle contextuelle, pas la doc complète.
local function helpTexts()
    return {
        recFilters = L["Barre de filtres. À gauche (avec Lazy Gold) : pièce = trier par rentabilité, « 123 » = prix exacts au lieu de l'indicateur compact, flèche verte = trier par montée de compétence, carte = plan de route (quoi crafter jusqu'au plafond, au moins cher). Au centre : la recherche. À droite : sac = seulement les recettes dont tu as les matériaux, flèche orange = masquer les recettes grises (aucun gain de compétence)."],
        recList    = string.format(L["Tes recettes, groupées par famille (clique un en-tête pour replier). À droite de chaque ligne : %s = rentabilité à l'HV (survole pour le profit net exact), %s = plan conseillé pour monter le métier (meilleur coût par point), « ×N » doré = commandes en attente pour cet objet. En mode Manquantes, une icône dit où obtenir le plan : formateur, vendeur, HV ou à farmer."], COIN, BEST),
        detail     = L["Le plan sélectionné : ses réactifs et le bouton pour le fabriquer."],
        orders     = L["Les commandes reçues pour ce métier — accepte, crafte, livre. Les onglets filtrent la source (tous / guilde / amis / annuaire)."],
    }
end

-- Bouton d'aide, posé un peu hors cadre en haut à gauche (au-dessus du portrait). Appelé depuis
-- _BuildHeader (dépendance molle : si Blizzard_HelpPlate manque, pas de bouton, pas de crash).
function PW:_BuildHelp(f)
    if not HelpPlate then return end
    self.helpBtn = Skin.MakeHelpButton(f, function() PW:_ToggleHelp() end, {
        point   = { "CENTER", f, "TOPLEFT", 8, 6 },
        tooltip = L["Aide : survole les zones surlignées pour comprendre chaque fonction."],
    })
    -- Tutoriel one-shot : au TOUT PREMIER affichage de la fenêtre (jamais vu → l'aide s'ouvre seule).
    -- Flag persistant compte db.profHelpSeen. Différé (positions valides seulement APRÈS le Show) et
    -- jamais en vue réduite (compact/dock) ; marqué « vu » uniquement quand on l'affiche réellement.
    f:HookScript("OnShow", function()
        if not COC.db or COC.db.profHelpSeen or PW.docked or PW._compact or PW._helpAutoQueued then return end
        PW._helpAutoQueued = true
        local run = function()
            PW._helpAutoQueued = nil
            if COC.db and not COC.db.profHelpSeen and PW.frame and PW.frame:IsShown()
               and not PW.docked and not PW._compact then
                COC.db.profHelpSeen = true
                PW:_ShowHelp()
            end
        end
        if C_Timer and C_Timer.After then C_Timer.After(0.4, run) else run() end
    end)
end

-- Assemble les entrées (frame + texte + direction) et ouvre le voile natif. Deux sources :
--   1) les ZONES SPEC auto-collectées (PW.helpNodes) — colonnes Recettes/Détail/Commandes ;
--   2) les CONTRÔLES d'en-tête, qui ne sont PAS des sections SPEC → entrée manuelle. ShowHelp accepte
--      n'importe quelle frame, donc aucune extension du kit : on pointe self.lfwBtn, self.missingBtn…
-- Garde IsShown : un bouton masqué (mode compact/dock, MTSL absent) ne doit pas porter de bulle
-- orpheline flottant dans le vide.
function PW:_ShowHelp()
    if not self.frame then return end
    local texts, entries = helpTexts(), {}
    local function add(fr, txt, dir)
        if fr and txt and fr:IsShown() then entries[#entries + 1] = { frame = fr, text = txt, dir = dir } end
    end
    for _, n in ipairs(PW.helpNodes or {}) do add(self:Sec(n.id), texts[n.id], n.dir) end

    add(self.lfwBtn,
        L["Chercher du travail : signale au royaume que tu proposes ce métier. L'engrenage voisin règle ton offre (composants fournis, commission)."],
        "DOWN")
    add(self.missingBtn, L["Affiche AUSSI les recettes non apprises (en rouge) et où les obtenir."], "DOWN")
    add(self.vanillaBtn, L["Vue Blizzard : rebascule sur la fenêtre de métier native de Blizzard."], "DOWN")
    add(self.ordRelTabs and self.ordRelTabs.buttons and self.ordRelTabs.buttons.all,
        L["Filtre les commandes par source : tous, ta guilde, tes amis, ou ton annuaire d'artisans."], "DOWN")

    Skin.ShowHelp(self.frame, entries, self.helpBtn)
end

function PW:_ToggleHelp()
    if Skin.HelpIsOpen() then Skin.HideHelp() else self:_ShowHelp() end
end
