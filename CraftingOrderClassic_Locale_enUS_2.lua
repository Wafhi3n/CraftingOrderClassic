-- CraftingOrderClassic_Locale_enUS_2.lua — overlay enUS, 2/2. Clé FR → texte traduit.
-- Suite de _Locale_enUS.lua, scindé pour rester sous le plafond anti-monolithe (500 l/fichier).
-- Même contrat : chargé APRÈS _Locale.lua, table à plat fusionnée dans COC.L — les deux moitiés
-- sont indépendantes (aucun ordre requis entre elles). Client d'une autre langue : early-return.

local COC = CraftingOrderClassic
local loc = GetLocale and GetLocale() or "enUS"
if loc ~= "enUS" and loc ~= "enGB" then return end
local L = COC.L

local en2 = {
    -- Minimap + menu métiers
    ["Clic : ouvrir les commandes"] = "Click: open orders",
    ["Clic droit : mes métiers"] = "Right click: my professions",
    ["Mes métiers"] = "My professions", ["Aucun métier connu."] = "No known profession.",
    ["Don / gratuit"] = "Free / gift",
    -- Entrantes (alertes chat)
    ["|cFFFF8800entrante|r |cFFFFFFFF%s|r (%s) : %s%s%s"] = "|cFFFF8800incoming|r |cFFFFFFFF%s|r (%s): %s%s%s",
    ["   |cFF33DD33→ tu sais la crafter|r — Carnet › Entrantes"] = "   |cFF33DD33→ you can craft it|r — Ledger › Incoming",
    ["|cFFFFCC00commande pour TOI|r de |cFFFFFFFF%s|r : %s%s%s"] = "|cFFFFCC00order for YOU|r from |cFFFFFFFF%s|r: %s%s%s",
    ["|cFFFFCC00nouvelle commande|r de |cFFFFFFFF%s|r : %s%s%s"] = "|cFFFFCC00new order|r from |cFFFFFFFF%s|r: %s%s%s",
    ["ton artisan |cFFFFFFFF%s|r est en ligne."] = "your crafter |cFFFFFFFF%s|r is online.",
    -- Alerte plan looté (CHAT_MSG_LOOT → CraftLink:RecipeFromPlanItem)
    ["plan looté : |cFFFFFFFF%s|r — enseigne |cFFFFFFFF%s|r (%s) %s"] =
        "recipe looted: |cFFFFFFFF%s|r — teaches |cFFFFFFFF%s|r (%s) %s",
    ["|cFF888888(tu la connais déjà)|r"] = "|cFF888888(you already know it)|r",
    ["|cFF33DD33(tu ne la connais pas encore !)|r"] = "|cFF33DD33(you don't know it yet!)|r",
    ["alerte plan looté : |cFFFFFFFF%s|r — /co lootalert [on|off]"] =
        "loot alert: |cFFFFFFFF%s|r — /co lootalert [on|off]",
    ["alerte quand tu loots un plan connu de CraftLink (défaut : on)"] =
        "alert when you loot a recipe known to CraftLink (default: on)",
    -- Partenaires (P1) + proposer un don (/co gift)
    ["Partenaire (basculer)"] = "Partner (toggle)",
    ["[Partenaire]"] = "[Partner]",
    ["|cFFFFFFFF%s|r marqué comme partenaire — priorité sur les alertes de don."] =
        "|cFFFFFFFF%s|r marked as partner — prioritized in gift alerts.",
    ["|cFFFFFFFF%s|r n'est plus marqué comme partenaire."] = "|cFFFFFFFF%s|r is no longer marked as partner.",
    ["Marquer comme partenaire"] = "Mark as partner", ["Retirer des partenaires"] = "Remove from partners",
    -- Recherche de travail (LFW) : /co lfw
    ["[Dispo]"] = "[LFW]",
    ["Chercher du travail"] = "Look for work", ["scan LFW du chat : |cFF33DD33activé|r"] = "chat LFW scan: |cFF33DD33on|r", ["scan LFW du chat : |cFFFFCC00désactivé|r"] = "chat LFW scan: |cFFFFCC00off|r", ["propose : %s"] = "offers: %s", ["Proposer cette recette (recherche de travail)"] = "Offer this recipe (looking for work)", ["Maximum %d recettes proposées."] = "Up to %d offered recipes.",
    ["Tu cherches du travail — clic pour arrêter."] = "You're looking for work — click to stop.",
    ["Signale au royaume que tu cherches du travail dans ce métier."] = "Tell the realm you're looking for work in this profession.",
    ["recherche de travail : |cFF33DD33%s|r — /co lfw off pour arrêter"] = "looking for work: |cFF33DD33%s|r — /co lfw off to stop",
    ["recherche de travail : |cFFFFCC00désactivée|r — /co lfw <métier>"] = "looking for work: |cFFFFCC00off|r — /co lfw <profession>",
    ["recherche de travail arrêtée."] = "looking for work stopped.",
    ["tu n'as pas le métier %s — impossible de chercher du travail dessus."] = "you don't have %s — can't look for work in it.",
    ["recherche de travail : |cFF33DD33%s|r — visible au royaume"] = "looking for work: |cFF33DD33%s|r — visible across the realm",
    -- Offre LFW (panneau de config par métier + tooltips + tris progression)
    ["Configurer l'offre : composants fournis, commission…"] = "Set up your offer: provided reagents, fee…",
    ["Recherche de travail — %s"] = "Looking for work — %s",
    ["Je fournis les composants de base"] = "I provide the basic reagents",
    ["(achetables chez un marchand)"] = "(the ones sold by vendors)",
    ["Seulement si le plan me fait progresser"] = "Only if the recipe skills me up",
    ["(restriction sur les composants fournis)"] = "(restricts the provided reagents)",
    ["Commission fixe par craft :"] = "Flat fee per craft:",
    ["Composants fournis (%d/%d)"] = "Provided reagents (%d/%d)",
    ["Maximum %d composants fournis."] = "At most %d provided reagents.",
    ["Cherche du travail : %s"] = "Looking for work: %s",
    ["fournit les composants de base (marchand)"] = "provides the basic reagents (vendor)",
    ["fournit : %s"] = "provides: %s",
    ["commission : %s par craft"] = "fee: %s per craft",
    ["composants fournis seulement si le plan fait progresser"] = "reagents provided only if the recipe skills them up",
    ["Trier par montée de compétence (plans orange d'abord)."] = "Sort by skill-up (orange recipes first).",
    ["Tri par montée de compétence — clic pour A-Z."] = "Sorted by skill-up — click for A-Z.",
    ["Par progression"] = "By skill-up",
    ["Trier : les commandes qui me font progresser d'abord."] = "Sort: orders that skill me up first.",
    ["Progression d'abord — clic pour revenir aux récentes."] = "Skill-ups first — click to go back to most recent.",
    ["|cFF66CCFFamis/partenaires intéressés :|r %s (|cFFFFFFFF/co gift <nom>|r)"] =
        "|cFF66CCFFinterested friends/partners:|r %s (|cFFFFFFFF/co gift <name>|r)",
    ["proposer (chuchoter) le dernier plan looté à un ami/partenaire qui ne le connaît pas"] =
        "propose (whisper) the last looted recipe to a friend/partner who doesn't know it",
    ["aucun plan looté en attente de don pour l'instant."] = "no looted recipe pending a gift right now.",
    ["don en attente pour |cFFFFFFFF%s|r — amis/partenaires : %s (|cFFFFFFFF/co gift <nom>|r)"] =
        "gift pending for |cFFFFFFFF%s|r — friends/partners: %s (|cFFFFFFFF/co gift <name>|r)",
    ["|cFFFFFFFF%s|r n'est pas dans la liste des amis/partenaires en attente pour ce plan."] =
        "|cFFFFFFFF%s|r isn't in the list of friends/partners waiting for this recipe.",
    ["Salut ! J'ai looté %s (%s) — tu ne le connais pas encore, ça t'intéresse ?"] =
        "Hey! I looted %s (%s) — you don't know it yet, are you interested?",
    ["don proposé à |cFFFFFFFF%s|r pour %s."] = "gift proposed to |cFFFFFFFF%s|r for %s.",
    -- Garder pour un ami capable (Handoff) : nudge crafteur + info posteur + file « Confiées »
    ["|cFF66CCFFtu sais le faire|r — demandé par |cFFFFFFFF%s|r : %s%s%s"] =
        "|cFF66CCFFyou can craft this|r — requested by |cFFFFFFFF%s|r: %s%s%s",
    ["%s peut faire une commande captée — gardée pour son passage : %s"] =
        "%s can craft a captured order — kept for their next login: %s",
    ["Confiées"] = "Entrusted", ["Remis"] = "Sent",
    ["Aucune commande confiée pour l'instant."] = "No entrusted orders yet.",
    -- Canal global (custom CraftLinkNet) : statut, /co channel, popup d'info
    ["canal : |cFFFFFFFF%s|r"] = "channel: |cFFFFFFFF%s|r",
    ["canal : non rejoint — |cFFFFFFFF/co channel on|r pour réessayer"] =
        "channel: not joined — |cFFFFFFFF/co channel on|r to retry",
    ["auto-join du canal réseau désactivé — le carnet global ne fonctionnera plus (whisper/guilde restent actifs)."] =
        "network channel auto-join disabled — the global ledger will stop working (whisper/guild stay active).",
    ["canal réseau (re)rejoint."] = "network channel (re)joined.",
    ["canal global actuel : |cFFFFFFFF%s|r. |cFFFFFFFF/co channel off|r pour le quitter, |cFFFFFFFF/co channel on|r pour le rejoindre."] =
        "current global channel: |cFFFFFFFF%s|r. |cFFFFFFFF/co channel off|r to leave it, |cFFFFFFFF/co channel on|r to rejoin.",
    ["(dés)activer le canal réseau global"] = "(de)activate the global network channel",
    ["balise TEXTE émise=%s (canal idx=%s) — lance |cFFFFFFFF/co trace dump|r sur l'AUTRE perso et cherche |cFFFFFFFF[recv] beacon|r."] =
        "TEXT beacon sent=%s (channel idx=%s) — run |cFFFFFFFF/co trace dump|r on the OTHER char and look for |cFFFFFFFF[recv] beacon|r.",
    ["annuaire local vidé (diag) — exécute aussi |cFFFFFFFF/co wipe|r sur l'autre compte pour un test de découverte propre."] =
        "local directory wiped (diag) — also run |cFFFFFFFF/co wipe|r on the other account for a clean discovery test.",
    ["Crafting Order rejoint un canal dédié (|cFFFFD100%s|r) pour faire circuler le carnet de commandes entre joueurs de l'addon. Tu le verras dans ta liste de canaux ; aucun message lisible n'y est envoyé. Tu peux le quitter à tout moment — |cFFFFFFFF/co channel off|r."] =
        "Crafting Order joins a dedicated channel (|cFFFFD100%s|r) to relay the order ledger between addon users. You'll see it in your channel list; no readable text is ever sent there. You can leave it anytime — |cFFFFFFFF/co channel off|r.",
    -- Onglet Aide
    ["Aide"] = "Help",
    ["C'est quoi Crafting Order ?"] = "What is Crafting Order?",
    ["Réseau GLOBAL et SOCIAL de commandes de craft — fonctionne sans guilde, entre tous les joueurs de l'addon."] =
        "GLOBAL and SOCIAL crafting order network — works without a guild, across all addon users.",
    ["Poste ce dont tu as besoin, ou consulte les commandes que tu peux honorer avec tes métiers."] =
        "Post what you need, or check the orders you can fulfill with your professions.",
    ["Ouvrir la fenêtre et commandes utiles"] = "Opening the window and useful commands",
    ["Clic gauche sur l'icône minimap (ou |cFFFFFFFF/co|r) : ouvre cette fenêtre."] =
        "Left click the minimap icon (or |cFFFFFFFF/co|r): opens this window.",
    ["Clic droit sur l'icône minimap (ou |cFFFFFFFF/co métier|r) : ouvre la Vue Métier d'un de tes métiers."] =
        "Right click the minimap icon (or |cFFFFFFFF/co métier|r): opens the Profession View for one of your professions.",
    ["|cFFFFFFFF/co help|r dans le chat : liste complète des commandes slash."] =
        "|cFFFFFFFF/co help|r in chat: full list of slash commands.",
    ["|cFFFFFFFF/co channel off|r / |cFFFFFFFF/co channel on|r : quitter/rejoindre le canal réseau."] =
        "|cFFFFFFFF/co channel off|r / |cFFFFFFFF/co channel on|r: leave/rejoin the network channel.",
    ["Les 4 onglets de cette fenêtre"] = "The 4 tabs of this window",
    ["|cFFE8B84BCarnet|r : tes commandes à toi (postées), en cours ou archivées."] =
        "|cFFE8B84BLedger|r: your own posted orders, active or archived.",
    ["|cFFE8B84BCommande|r : poster une demande de craft à faire réaliser par un artisan."] =
        "|cFFE8B84BOrder|r: post a crafting request for a crafter to fulfill.",
    ["|cFFE8B84BRécolte|r : poster une demande de matières à un récolteur (mine, herbe, peau, pêche)."] =
        "|cFFE8B84BGather|r: post a materials request to a gatherer (mining, herbalism, skinning, fishing).",
    ["|cFFE8B84BArtisans|r : l'annuaire — qui sait crafter quoi, en ligne ou non."] =
        "|cFFE8B84BArtisans|r: the directory — who can craft what, online or not.",
    ["Poster une commande de craft"] = "Posting a crafting order",
    ["Onglet |cFFE8B84BCommande|r → choisis un métier puis un plan dans la liste."] =
        "|cFFE8B84BOrder|r tab → pick a profession then a recipe from the list.",
    ["Shift-clic un objet dans un sac ou un lien de chat pour le présélectionner s'il correspond à un plan."] =
        "Shift-click an item in a bag or a chat link to preselect it if it matches a recipe.",
    ["Coche les réactifs que TU fournis toi-même (le reste reste à la charge de l'artisan)."] =
        "Check the reagents YOU provide yourself (the rest stays the crafter's responsibility).",
    ["Choisis la quantité, la commission proposée, puis le destinataire (guilde, amis, un artisan précis, ou diffuser à tous)."] =
        "Pick the quantity, the offered commission, then the recipient (guild, friends, a specific crafter, or broadcast to all).",
    ["Clique |cFFE8B84BPoster|r : la commande apparaît dans ton Carnet et chez les artisans concernés."] =
        "Click |cFFE8B84BPost|r: the order appears in your Ledger and for the relevant crafters.",
    ["Poster une commande de récolte"] = "Posting a gathering order",
    ["Onglet |cFFE8B84BRécolte|r → choisis un métier de récolte puis une ressource."] =
        "|cFFE8B84BGather|r tab → pick a gathering profession then a resource.",
    ["Choisis à l'unité ou par pile, la quantité voulue et le prix proposé, puis le destinataire."] =
        "Pick per unit or per stack, the wanted quantity and the offered price, then the recipient.",
    ["Fonctionne comme une commande de craft, mais ciblée sur les joueurs qui ont le métier de récolte, pas de recette à connaître."] =
        "Works like a crafting order, but targets players with the gathering profession — no recipe required.",
    ["Accepter / livrer une commande — la Vue Métier"] = "Accepting / delivering an order — the Profession View",
    ["L'acceptation et la livraison ne se font PAS dans le Carnet : ouvre la |cFFE8B84BVue Métier|r du métier concerné (clic droit minimap, ou |cFFFFFFFF/co métier <nom>|r)."] =
        "Accepting and delivering do NOT happen in the Ledger: open the |cFFE8B84BProfession View|r for the relevant profession (right click minimap, or |cFFFFFFFF/co métier <name>|r).",
    ["La 3ᵉ colonne de la Vue Métier liste toutes les commandes de ce métier : accepte, crafte, puis livre."] =
        "The 3rd column of the Profession View lists all orders for that profession: accept, craft, then deliver.",
    ["Les demandes captées dans |cFFE8B84B/commerce|r et |cFFE8B84B/guilde|r de joueurs sans l'addon apparaissent aussi ici, marquées « entrante »."] =
        "Requests captured from |cFFE8B84B/trade|r and |cFFE8B84B/guild|r chat of players without the addon also appear here, marked \"incoming\".",
    ["Un artisan connu qui sait honorer une commande captée est notifié à sa prochaine connexion (voir « Confiées » dans le Carnet)."] =
        "A known crafter able to fulfill a captured order is notified next time they log in (see \"Entrusted\" in the Ledger).",
    ["Le Carnet en détail"] = "The Ledger in detail",
    ["|cFFE8B84BEn cours|r : tes commandes ouvertes ou acceptées par un artisan."] =
        "|cFFE8B84BActive|r: your orders that are open or accepted by a crafter.",
    ["|cFFE8B84BArchivées|r : tes commandes livrées ou annulées."] =
        "|cFFE8B84BArchived|r: your orders that are delivered or cancelled.",
    ["|cFFE8B84BConfiées|r : commandes gardées pour un artisan connu capable de les honorer, en attendant qu'il se reconnecte."] =
        "|cFFE8B84BEntrusted|r: orders kept for a known crafter able to fulfill them, waiting for them to log back in.",
    ["Depuis le Carnet, tu peux annuler une commande tant qu'elle n'est pas livrée."] =
        "From the Ledger, you can cancel an order as long as it isn't delivered.",
    ["Annuaire & social"] = "Directory & social",
    ["L'onglet Artisans liste les joueurs connus par source : guilde, amis, ajoutés manuellement, croisés récemment."] =
        "The Artisans tab lists known players by source: guild, friends, manually added, recently met.",
    ["Survole un joueur (tooltip) pour voir ses métiers et son niveau de compétence."] =
        "Hover a player (tooltip) to see their professions and skill level.",
    ["Clic droit sur un joueur (chat, groupe...) pour l'ajouter à ton annuaire — utile pour le retrouver même hors ligne."] =
        "Right click a player (chat, party...) to add them to your directory — useful to find them again even offline.",
    ["Pastille verte : il a l'addon et répond. Jaune : en ligne sans l'addon. Grise : hors ligne."] = "Green dot: has the addon and answers. Yellow: online without the addon. Gray: offline.",
    ["Réseau, confidentialité & statuts"] = "Network, privacy & statuses",
    ["L'addon rejoint un canal dédié pour faire circuler le carnet entre joueurs de l'addon — aucun message lisible n'y est envoyé."] =
        "The addon joins a dedicated channel to relay the ledger between addon users — no readable text is ever sent there.",
    ["|cFFFFFFFF/co channel off|r le quitte à tout moment (whisper et guilde restent actifs) ; |cFFFFFFFF/co channel on|r le rejoint."] =
        "|cFFFFFFFF/co channel off|r leaves it anytime (whisper and guild stay active); |cFFFFFFFF/co channel on|r rejoins it.",
    ["Statuts d'une commande : "] = "Order statuses: ",

    -- Aide contextuelle « bouton i » (Vue Métier) — cf. _ProfWindow_HelpPlate.lua (bulles courtes)
    ["Aide : survole les zones surlignées pour comprendre chaque fonction."] =
        "Help: hover the highlighted areas to understand each feature.",
    ["Barre de filtres. À gauche (avec Lazy Gold) : pièce = trier par rentabilité, « 123 » = prix exacts au lieu de l'indicateur compact, flèche verte = trier par montée de compétence, carte = plan de route (quoi crafter jusqu'au plafond, au moins cher). Au centre : la recherche. À droite : sac = seulement les recettes dont tu as les matériaux, flèche orange = masquer les recettes grises (aucun gain de compétence)."] =
        "Filter bar. On the left (with Lazy Gold): coin = sort by profit, \"123\" = exact prices instead of the compact indicator, green arrow = sort by skill-up, map = leveling route (what to craft up to the cap, at the lowest cost). In the middle: the search. On the right: bag = only recipes you have the materials for, orange arrow = hide gray recipes (no skill gain).",
    ["Tes recettes, groupées par famille (clique un en-tête pour replier). À droite de chaque ligne : %s = rentabilité à l'HV (survole pour le profit net exact), %s = plan conseillé pour monter le métier (meilleur coût par point), « ×N » doré = commandes en attente pour cet objet. En mode Manquantes, une icône dit où obtenir le plan : formateur, vendeur, HV ou à farmer."] =
        "Your recipes, grouped by family (click a header to collapse). On the right of each line: %s = profit at the AH (hover for the exact net profit), %s = recommended recipe to level up (best cost per point), gold \"×N\" = pending orders for that item. In Missing mode, an icon shows where to get the recipe: trainer, vendor, AH, or to farm.",
    ["Le plan sélectionné : ses réactifs et le bouton pour le fabriquer."] =
        "The selected recipe: its reagents and the button to craft it.",
    ["Les commandes reçues pour ce métier — accepte, crafte, livre. Les onglets filtrent la source (tous / guilde / amis / annuaire)."] =
        "Orders received for this profession — accept, craft, deliver. The tabs filter the source (all / guild / friends / directory).",
    ["Chercher du travail : signale au royaume que tu proposes ce métier. L'engrenage voisin règle ton offre (composants fournis, commission)."] =
        "Look for work: tell the realm you offer this profession. The gear next to it sets up your offer (provided reagents, fee).",
    ["Vue Blizzard : rebascule sur la fenêtre de métier native de Blizzard."] =
        "Blizzard view: switch back to Blizzard's native profession window.",
    ["Filtre les commandes par source : tous, ta guilde, tes amis, ou ton annuaire d'artisans."] =
        "Filter orders by source: all, your guild, your friends, or your artisan directory.",

    -- Aide contextuelle « bouton i » — onglet Commande (cf. _UI_HelpPlate.lua)
    ["Filtre les plans : recherche par nom, filtre par qualité, filtre par réactif, et l'outil %s « 123 » de Lazy Gold (prix/rentabilité)."] =
        "Filter the recipes: search by name, filter by quality, filter by reagent, and Lazy Gold's %s \"123\" tool (price/profit).",
    ["La liste des plans. Choisis celui que tu veux faire réaliser par un artisan."] =
        "The recipe list. Pick the one you want a crafter to make.",
    ["L'objet choisi. La pastille « Je fournis » indique que tu apportes tous les composants toi-même."] =
        "The chosen item. The \"I provide\" pill means you bring all the reagents yourself.",
    ["La commission que tu proposes à l'artisan pour ce craft."] =
        "The commission you offer the crafter for this craft.",
    ["La portée : diffuser à tous, ou restreindre (guilde / amis)."] =
        "The reach: broadcast to everyone, or restrict (guild / friends).",
    ["Le destinataire : toute la source sélectionnée, ou un artisan précis."] =
        "The recipient: the whole selected source, or a specific crafter.",
    ["Poster : envoie la commande au(x) destinataire(s) choisi(s)."] =
        "Post: send the order to the chosen recipient(s).",

    -- Aide contextuelle « bouton i » — onglet Récolte (cf. _UI_HelpPlate.lua)
    ["Recherche une ressource par nom."] = "Search a resource by name.",
    ["Extensions : filtre les ressources d'une extension (ex. Élémentaire)."] =
        "Expansions: filter resources from an expansion (e.g. Elemental).",
    ["La liste des ressources. Choisis celle que tu veux faire récolter."] =
        "The resource list. Pick the one you want gathered.",
    ["La ressource choisie."] = "The chosen resource.",
    ["À l'unité ou par pile, et la quantité voulue."] = "Per unit or per stack, and the wanted quantity.",
    ["Le prix que tu proposes au récolteur."] = "The price you offer the gatherer.",
    ["Le destinataire : toute la source, ou un récolteur précis."] =
        "The recipient: the whole source, or a specific gatherer.",

    -- Aide contextuelle « bouton i » — onglet Artisans (cf. _UI_HelpPlate.lua)
    ["Filtre l'annuaire par source : guilde, amis, ajoutés manuellement, croisés, ou les joueurs en sourdine."] =
        "Filter the directory by source: guild, friends, manually added, recently met, or muted players.",
    ["Ajoute un joueur manuellement (+), rafraîchis l'annuaire, ou active le repérage."] =
        "Add a player manually (+), refresh the directory, or turn on tracking.",
    ["Filtre les artisans par métier."] = "Filter artisans by profession.",
    ["La liste des artisans connus. Survole un nom pour ses métiers ; pastille verte = a l'addon et répond, jaune = en ligne sans l'addon, grise = hors ligne."] =
        "The list of known artisans. Hover a name for their professions; green dot = has the addon and answers, yellow = online without the addon, gray = offline.",

    -- Aide contextuelle « bouton i » — onglet Mes artisans (cf. _UI_HelpPlate.lua)
    ["Partage tes rerolls sur le réseau (les autres voient tes métiers), et choisis le perso mis en « vitrine »."] =
        "Share your rerolls on the network (others see your professions), and pick the character on \"display\".",
    ["Tous les plans du royaume : la liste agrégée de toutes tes recettes, au lieu du découpage par métier (Lazy Gold requis)."] =
        "All realm recipes: the aggregated list of all your recipes, instead of the per-profession split (Lazy Gold required).",
    ["Tes métiers (tous les persos du compte). Choisis-en un pour voir ses recettes à droite."] =
        "Your professions (all account characters). Pick one to see its recipes on the right.",
    ["En-tête des recettes du métier choisi : bouton « Manquantes » et outils de prix (Lazy Gold)."] =
        "Header of the chosen profession's recipes: \"Missing\" button and price tools (Lazy Gold).",
    ["Les recettes du métier sélectionné (ou tous les plans du royaume)."] =
        "The recipes of the selected profession (or all realm recipes).",

    -- Aide contextuelle « bouton i » — onglet Carnet (cf. _UI_HelpPlate.lua)
    ["Filtre ton carnet : commandes En cours, Archivées, ou Confiées (gardées pour un artisan)."] =
        "Filter your ledger: Active, Archived, or Entrusted orders (kept for a crafter).",
    ["Le Carnet = TES commandes postées. Accepter/livrer se fait dans la Vue Métier, pas ici ; quand une commande t'est remise, le bouton « J'ai reçu » confirme la réception."] =
        "The Ledger = YOUR posted orders. Accepting/delivering happens in the Profession View, not here; when an order is handed to you, the \"Received\" button confirms receipt.",

    -- Popup dépendance optionnelle manquante (boutons Lazy Gold / MTSL toujours visibles)
    ["Cette fonction nécessite l'addon |cFFFFD100%s|r (non installé ou désactivé). Installe-le pour en profiter."] =
        "This feature needs the |cFFFFD100%s|r addon (not installed or disabled). Install it to use it.",

    -- Sous-catégories de recettes (vue métier) — voir _RecipeCats_*.lua
    ["Divers"] = "Misc",
    ["Potions de soin"] = "Healing Potions",
    ["Potions de mana"] = "Mana Potions",
    ["Flacons"] = "Flasks",
    ["Élixirs de force"] = "Strength Elixirs",
    ["Élixirs d'agilité"] = "Agility Elixirs",
    ["Élixirs d'endurance"] = "Stamina Elixirs",
    ["Élixirs de défense"] = "Defense Elixirs",
    ["Élixirs d'esprit"] = "Intellect & Spirit Elixirs",
    ["Élixirs de puissance des sorts"] = "Spell Power Elixirs",
    ["Élixirs de puissance d'attaque"] = "Attack Power Elixirs",
    ["Élixirs de vision"] = "Vision Elixirs",
    ["Potions de protection"] = "Protection Potions",
    ["Potions de combat"] = "Combat Potions",
    ["Potions de régénération"] = "Regeneration Potions",
    ["Potions utilitaires"] = "Utility Potions",
    ["Huiles"] = "Oils",
    ["Transmutations"] = "Transmutes",
    ["Minerais"] = "Ores",
    ["Lingots"] = "Bars",
    ["Cuirs"] = "Leather",
    -- ⚠️ Clés DYNAMIQUES (L[group.name] dans RecipeCats) : le checker ne les voit pas — tenir cette
    -- liste alignée sur les `name =` des _RecipeCats_*.lua à chaque régénération (bug live sosh13).
    ["Peaux"] = "Hides",
    ["Écailles"] = "Scales",
    ["Herbes"] = "Herbs",
    ["Poissons"] = "Fish",
    ["Éclats"] = "Shards",
    ["Essences"] = "Essences",
    ["Poussières"] = "Dusts",

    -- Pont MissingTradeSkillsList (recettes manquantes + source)
    ["Manquantes"] = "Missing",
    ["Manquantes (%d)"] = "Missing (%d)",
    ["‹ Apprises seules"] = "‹ Learned only",
    ["Masque les recettes non apprises — clic pour revenir."] = "Hide unlearned recipes — click to go back.",
    ["Affiche AUSSI les recettes non apprises (en rouge) et où les obtenir."] = "Also show unlearned recipes (in red) and where to get them.",
    ["niveau"] = "level",
    ["niv."] = "lv.",
    ["Non apprise"] = "Not learned",
    ["Où l'obtenir"] = "Where to get it",
    ["Niveau requis"] = "Required skill",
    ["Obtenu via"] = "Obtained via",
    ["Prix"] = "Price", ["Appris de"] = "Learned from",
    ["Vendeur"] = "Vendor", ["Vendu par"] = "Sold by",
    ["Butin sur"] = "Drops from", ["Formateurs"] = "Trainers",
    ["Formateur"] = "Trainer", ["Réputation"] = "Reputation",
    ["Quête"] = "Quest", ["Butin"] = "Drop",
    ["Source inconnue"] = "Unknown source",
    ["Acheter à l'HV"] = "Buy at AH",
    ["N'afficher que les recettes acquérables (formateur, vendeur ou HV)."] = "Show only obtainable recipes (trainer, vendor or AH).",
    ["Filtre acquérables actif — clic pour tout afficher."] = "Obtainable filter active — click to show all.",

    -- Pont Lazy Gold (rentabilité)
    ["Rentabilité"] = "Profitability",
    ["Vente HV"] = "AH sale",
    ["Profit net"] = "Net profit",
    ["Valeur HV"] = "AH value",
    ["Par rentabilité"] = "By profit",
    ["Meilleur plan"] = "Best plan",
    ["Tous les plans du royaume"] = "All realm crafts",
    ["%d métiers"] = "%d professions",
    ["À ma charge"] = "My share",
    ["Valeurs exactes — clic pour l'affichage compact."] = "Exact values — click for compact display.",
    ["Afficher les valeurs exactes (po/pa/pc)."] = "Show exact values (g/s/c).",
    ["Clic : commander ce métier"] = "Click: order this profession",
    ["Trier par rentabilité (Lazy Gold)."] = "Sort by profitability (Lazy Gold).",
    ["Tri par rentabilité — clic pour A-Z."] = "Sorted by profit — click for A-Z.",
    ["N'afficher que les recettes dont j'ai les matériaux."] = "Show only recipes you have the materials for.", ["Filtre matériaux actif — clic pour tout afficher."] = "Materials filter on — click to show all.",
    ["N'afficher que les recettes qui font monter la compétence (masque le gris)."] = "Show only recipes that raise your skill (hides grey).", ["Filtre progression actif — clic pour tout afficher."] = "Skill-up filter on — click to show all.",
    ["Diffuser les réactifs"] = "Broadcast reagents", ["Diffuser les réactifs dans un canal"] = "Broadcast the reagents to a channel", ["Canal : "] = "Channel: ",  -- liste de courses
    ["Dire"] = "Say", ["Groupe"] = "Party", ["Raid"] = "Raid", ["Envoyer"] = "Send", ["Réactifs pour %s :"] = "Reagents for %s:", ["Réactifs pour %s (%d) :"] = "Reagents for %s (%d):",
    ["choisis un canal valide."] = "pick a valid channel.", ["aucun réactif à diffuser."] = "no reagents to broadcast.", ["Diffuser"] = "Broadcast",
    -- Aide à la montée de métier (Leveling)
    ["Progression : ~%s par point (estimation)"] = "Leveling: ~%s per point (estimate)",
    ["Meilleur coût/point pour monter le métier"] = "Best cost per point to level the profession",
    ["Plan : au formateur%s"] = "Recipe: from the trainer%s",
    ["Plan : chez un vendeur PNJ%s"] = "Recipe: from an NPC vendor%s",
    ["Plan : coté à l'HV — %s"] = "Recipe: listed on the AH — %s",
    ["Plan : à farmer (butin/quête — absent de l'HV)"] = "Recipe: farm it (drop/quest — not on the AH)",

    -- Plan de route (montée de métier)
    ["Plan de route"] = "Leveling route",
    ["Plan de route : quoi crafter pour monter au moins cher."] = "Leveling route: what to craft to level up at the lowest cost.",
    ["Rang %s"] = "Rank %s",
    ["En tête : rang actuel, plafond entraînable, et coût total estimé (« > » = des rangs sans recette calculable, total incomplet)."] =
        "At the top: current rank, trainable cap, and the estimated total cost (\">\" = some ranks have no computable recipe, the total is incomplete).",
    ["Un segment par ligne : plage de rangs, recette au meilleur coût par point espéré, « ×~N » = crafts attendus, et le coût du segment (parchemin = plan à acheter d'abord, compté dedans). Survole une ligne pour le détail. La route se recalcule à chaque point gagné."] =
        "One segment per line: rank range, the recipe with the best expected cost per point, \"×~N\" = expected crafts, and the segment cost (scroll = recipe to buy first, included). Hover a line for details. The route recomputes with every point you gain.",
    ["Total estimé : %s"] = "Estimated total: %s",
    ["Rang au plafond — vois le formateur pour débloquer la suite."] = "Rank at cap — visit your trainer to unlock more.",
    ["aucune recette calculable"] = "no computable recipe",
    ["Estimation : chance de point par couleur, prix du dernier scan HV (Lazy Gold)."] = "Estimate: skill-up chance per color, prices from the last AH scan (Lazy Gold).",
    ["Rien à calculer — scanne l'HV (Auctionator) puis rouvre ce panneau."] = "Nothing to compute — scan the AH (Auctionator) then reopen this panel.",
    ["Crafts attendus : ~%d"] = "Expected crafts: ~%d",
    ["Réactifs (espéré)"] = "Reagents (expected)",
    ["Plan à acheter"] = "Recipe to buy",
    ["Aucune recette calculable sur ce segment (prix HV manquants, ou plans introuvables)."] = "No computable recipe over this segment (missing AH prices, or unobtainable recipes).",
    ["Monter son métier au meilleur prix"] = "Level your profession at the lowest cost",
    ["Dans la Vue Métier, la flèche verte trie par montée de compétence : les plans qui rapportent un point d'abord, les moins chers en tête (prix Lazy Gold)."] =
        "In the Profession View, the green arrow sorts by skill-up: recipes that grant a point first, cheapest on top (Lazy Gold prices).",
    ["Le badge doré marque le meilleur coût par point ; les plans utiles non appris s'affichent aussi, avec où les obtenir (formateur, vendeur, HV, à farmer)."] =
        "The gold badge marks the best cost per point; useful unlearned recipes show up too, with where to get them (trainer, vendor, AH, farm).",
    ["Le bouton carte ouvre le |cFFE8B84BPlan de route|r : du rang actuel au plafond, quoi crafter, combien de fois, pour quel coût total estimé — recalculé à chaque point gagné."] =
        "The map button opens the |cFFE8B84BLeveling route|r: from your current rank to the cap, what to craft, how many times, for what estimated total cost — recomputed with every point you gain.",
    ["Tout repose sur les prix du dernier scan Auctionator (addons Lazy Gold + Auctionator conseillés) : sans eux, ces aides s'effacent."] =
        "Everything relies on prices from the last Auctionator scan (Lazy Gold + Auctionator addons recommended): without them, these helpers step aside.",

    -- Bourse d'artisan (onglet Artisans)
    ["Bourse d'artisan"] = "Artisan pouch",
    ["Clic : les fournitures qu'il lui faut pour monter ses métiers (prix Lazy Gold)."] =
        "Click: the supplies they need to level their professions (Lazy Gold prices).",
    ["Bourse — %s"] = "Pouch — %s",
    ["Rien à fournir — métiers au plafond, ou données trop anciennes."] = "Nothing to supply — professions at cap, or data too old.",
    ["Inclure les plans à acheter"] = "Include recipes to buy",
    ["Les plans-objets s'ajoutent aux fournitures ; les plans « au formateur » restent à apprendre chez le PNJ."] =
        "Recipe items join the supplies; trainer-taught recipes must still be learned at the NPC.",
    ["Requis : ×%d"] = "Needed: ×%d",
    ["Plan à fournir (il ne le connaît pas encore)"] = "Recipe to supply (they don't know it yet)",
    ["Au formateur : %s"] = "At the trainer: %s",
    ["Chez un PNJ (inutile de fournir) : %s"] = "From an NPC vendor (no need to supply): %s",
    ["Fournitures (agrégées)"] = "Supplies (aggregated)",
    ["Clic : poser un repère sur ce PNJ (TomTom ou épingle de carte)."] = "Click: drop a waypoint on this NPC (TomTom or map pin).",
    ["zone introuvable sur la carte : %s"] = "zone not found on the map: %s",
    ["repère posé : %s — %s (%.0f, %.0f)"] = "waypoint set: %s — %s (%.0f, %.0f)",
    ["Route incomplète : %d rang(s) sans recette calculable (prix HV manquants)."] =
        "Incomplete route: %d rank(s) with no computable recipe (missing AH prices).",
    ["Coche « Inclure les plans à acheter » pour en combler une partie."] =
        "Check \"Include recipes to buy\" to fill some of them.",
    ["Coût partiel : au moins un réactif sans prix HV."] = "Partial cost: at least one reagent has no AH price.",
    ["Désenchanter : objets %s, niv. d'objet %d-%d (estimation)"] = "Disenchant: %s items, item level %d-%d (estimate)",
}

for k, v in pairs(en2) do L[k] = v end
