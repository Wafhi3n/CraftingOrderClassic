-- CraftingOrderClassic_Locale_enUS.lua — overlay ANGLAIS (enUS/enGB). Clé FR → texte EN.
-- Chargé APRÈS CraftingOrderClassic_Locale.lua (qui crée COC.L via setmetatable). Repli sur la clé FR
-- pour toute chaîne non traduite. Extrait du fichier de base (plafond anti-monolithe de 500 lignes) :
-- il vit maintenant à côté de _Locale_deDE.lua / _Locale_esES.lua, même forme, même contrat.
-- Sur un client non-anglais : early-return, coût nul.

local COC = CraftingOrderClassic
local loc = GetLocale and GetLocale() or "enUS"
if loc ~= "enUS" and loc ~= "enGB" then return end
local L = COC.L

local en = {
    -- Notification « nouvelle version disponible » (Directory_Version / minimap / /co version)
    ["Une nouvelle version est disponible : |cFFFFD100%s|r (vous avez la %s). Pensez à mettre à jour."] =
        "A new version is available: |cFFFFD100%s|r (you have %s). Time to update.",
    ["Nouvelle version disponible : %s"] = "New version available: %s",
    ["alerte de version oubliée — elle reviendra si le réseau la re-confirme."] = "version alert forgotten. It'll come back if the network confirms it again.",
    ["(/co version reset si cette alerte est erronée)"] = "(/co version reset if this alert is wrong)",
    ["Crafting Order — version %s"] = "Crafting Order — version %s",
    ["Enchanter équipé"] = "Enchant equipped", ["Enchante directement la pièce équipée — sans cibler."] = "Enchants the equipped item directly — no targeting.",
    ["Enchanter cet objet"] = "Enchant this item", ["Ouvre ta fenêtre d'Enchantement."] = "Open your Enchanting window.", ["Aucun enchantement connu pour cet emplacement."] = "No known enchant for that slot.",
    ["Choisir par emplacement"] = "Pick by slot", ["Retour"] = "Back",   -- vue silhouette (onglet Commande)
    -- Onglets / fenêtre
    ["Carnet"] = "Ledger", ["Commande"] = "Order", ["Récolte"] = "Gather", ["Artisans"] = "Artisans",
    -- En-têtes de colonnes (Carnet)
    ["COMMANDE"] = "ORDER", ["QTÉ"] = "QTY", ["PRIX PROPOSÉ"] = "PRICE OFFERED",
    ["MÉTIER"] = "PROFESSION", ["STATUT"] = "STATUS",
    ["ARTISAN"] = "CRAFTER",
    -- Filtres Carnet
    ["Tous"] = "All", ["Guilde"] = "Guild", ["Amis"] = "Friends",
    ["Annuaire"] = "Directory",
    ["Rafraîchir l'annuaire"] = "Refresh directory",
    ["annuaire : appel lancé sur le canal — les porteurs en ligne vont répondre."] =
        "directory: call sent on the channel — online holders will respond.",
    -- Onglet « Mes artisans » (vue agrégée des métiers du compte — 100 % local)
    ["Mes artisans"] = "My Artisans",
    ["%d recettes"] = "%d recipes",
    ["Aucun métier. Ouvre ta fenêtre métier sur chaque perso une fois."] =
        "No professions. Open your profession window on each character once.",
    ["Partager mes rerolls sur le réseau"] = "Share my alts on the network",
    ["Vitrine"] = "Front",
    ["Rerolls"] = "Alts",
    ["%s — lecture seule"] = "%s — read-only",
    ["Pas de recettes connues (métier de récolte ?)."] = "No known recipes (gathering profession?).",
    -- Repérage des crafteurs à proximité (opt-in, en ville) + bouton « Ajouter ami »
    ["Repérer les crafteurs autour (en ville)"] = "Detect crafters nearby (in town)",
    ["Ajouter ami"] = "Add friend",
    ["|cFFFFFFFF%s|r ajouté à tes amis."] = "|cFFFFFFFF%s|r added to your friends.",
    ["repérage des crafteurs autour : |cFFFFFFFF%s|r (en ville) — /co crafters [on|off]"] =
        "nearby crafter detection: |cFFFFFFFF%s|r (in town) — /co crafters [on|off]",
    ["repérer les crafteurs sans l'addon qui craftent autour (en ville ; défaut : off)"] =
        "detect players without the addon crafting nearby (in town; default: off)",
    ["Archivées"] = "Archived", ["En cours"] = "Active",
    ["Aucune commande. Onglet « Commande » pour en poster une."] = "No orders. Use the « Order » tab to post one.",
    ["Clic : "] = "Click: ", ["Accepter"] = "Accept", ["Annuler"] = "Cancel", ["Livrer"] = "Deliver",
    ["J'ai reçu"] = "Received", ["Remise"] = "Delivered",
    ["remise — en attente de confirmation de %s : %s"] = "delivered — awaiting %s's confirmation: %s",
    ["réception confirmée : %s"] = "receipt confirmed: %s",
    ["réception confirmée par %s ! crafts livrés au total : %d"] = "receipt confirmed by %s! total crafts delivered: %d",
    ["%s a remis ta commande : %s — clique « J'ai reçu » pour confirmer"] =
        "%s delivered your order: %s — click \"Received\" to confirm",
    ["Refuser"] = "Decline", ["%s a refusé ta commande : %s"] = "%s declined your order: %s",
    ["guilde"] = "guild", ["commerce"] = "trade",
    -- Vue métier (cabine) : pied de colonne Commandes + action carte
    ["Inviter en groupe"] = "Invite to group", ["en attente"] = "pending", ["acceptées"] = "accepted", ["en sourdine"] = "muted",
    ["diag"] = "diag", ["Sourdine"] = "Muted", ["Réafficher"] = "Unmute",
    -- Modération / anti-spam (/co mute|unmute|lowlevel, popup spam, menu contextuel joueur)
    ["Muter"] = "Mute", ["Ajouter aux artisans"] = "Add to artisans",
    ["Passer commande à %s"] = "Order from %s", ["Passer commande"] = "Place order",
    ["Passer commande à %s (%s)"] = "Order from %s (%s)",
    ["%s est mis en sourdine — plus aucune notification de sa part."] = "%s is now muted — no more notifications from them.",
    ["%s n'est plus en sourdine."] = "%s is no longer muted.", ["usage : /co unmute <nom>"] = "usage: /co unmute <name>",
    ["aucun joueur en sourdine. /co mute <nom> pour en ajouter un."] = "no muted players. /co mute <name> to add one.",
    ["en sourdine (%d) :"] = "muted (%d):", ["%s n'est plus de confiance."] = "%s is no longer trusted.",
    ["permanent"] = "permanent", ["expiré"] = "expired", ["spam détecté"] = "spam detected",
    -- Panel de gestion des mis en sourdine (onglet Artisans › En sourdine)
    ["En sourdine"] = "Muted", ["Rétablir"] = "Unmute",
    ["Joueurs en sourdine — aucune notification de leur part."] = "Muted players — no notifications from them.",
    ["Personne en sourdine."] = "No one is muted.",
    ["Mets un joueur en sourdine par clic-droit sur sa carte ou /co mute <nom>."] = "Mute a player by right-clicking their card or /co mute <name>.",
    ["%s est de confiance — jamais muté automatiquement."] = "%s is trusted — never auto-muted.",
    ["aucun joueur de confiance. /co trust <nom> pour en ajouter un."] = "no trusted players. /co trust <name> to add one.",
    ["de confiance (%d) : %s"] = "trusted (%d): %s", ["usage : /co untrust <nom>"] = "usage: /co untrust <name>",
    ["mute auto bas niveau : |cFFFFFFFFdésactivé|r — /co lowlevel <niveau>"] = "low-level auto-mute: |cFFFFFFFFoff|r — /co lowlevel <level>",
    ["mute auto bas niveau : sous le niveau |cFFFFFFFF%d|r — /co lowlevel [N|off]"] = "low-level auto-mute: below level |cFFFFFFFF%d|r — /co lowlevel [N|off]",
    ["%s a posté %d fois en peu de temps. Le mettre en sourdine ?"] = "%s posted %d times in a short while. Mute them?",
    ["muter/démuter un joueur (aucune notif ; durée ex. 1h/30m/2d)"] = "mute/unmute a player (no notifications; duration e.g. 1h/30m/2d)",
    ["marquer un joueur de confiance (jamais muté automatiquement)"] = "mark a player as trusted (never auto-muted)",
    ["seuil de mute auto des persos bas niveau (défaut 5)"] = "auto-mute threshold for low-level characters (default 5)",
    -- Détection de spam configurable (/co spam)
    ["mute auto"] = "auto-mute", ["popup"] = "popup",
    ["détection de spam : |cFFFFFFFFdésactivée|r — /co spam <max> [fenêtre] pour l'activer"] = "spam detection: |cFFFFFFFFoff|r — /co spam <max> [window] to enable",
    ["détection de spam : |cFFFFFFFF%d|r posts / |cFFFFFFFF%ds|r → %s"] = "spam detection: |cFFFFFFFF%d|r posts / |cFFFFFFFF%ds|r → %s",
    ["  /co spam <max> [fenêtre] · /co spam auto · /co spam off"] = "  /co spam <max> [window] · /co spam auto · /co spam off",
    ["réglage anti-spam : seuil, fenêtre, mute auto vs popup"] = "anti-spam tuning: threshold, window, auto-mute vs popup",
    -- Réputation sociale (crafts livrés, diffusée via SK)
    ["%d livrés"] = "%d delivered",
    -- Profondeur du carnet + dépliage des plans connus (tooltip social)
    ["· %d plans"] = "· %d recipes", ["+%d de plus"] = "+%d more", ["Maj : plans connus"] = "Shift: known recipes",
    -- Rerolls / alts du compte
    ["ton reroll |cFFFFFFFF%s|r sait le faire : %s"] = "your alt |cFFFFFFFF%s|r can make this: %s",
    -- Panneau « composants » des cartes de commande
    ["COMPOSANTS FOURNIS"] = "PROVIDED COMPONENTS", ["À FOURNIR"] = "TO PROVIDE", ["complet"] = "complete",
    -- Ligne de chargement + /co status + /co help (sorties chat des commandes slash)
    ["chargé — |cFFFFFFFF/co help|r pour les commandes. (Réseau global de craft — autonome.)"] =
        "loaded — |cFFFFFFFF/co help|r for commands. (Global craft network — standalone.)",
    ["CraftLink introuvable — l'infra partagée n'est pas chargée."] =
        "CraftLink not found — the shared infrastructure isn't loaded.",
    ["infra CraftLink — dataVersion=|cFFE8B84B%d|r, protocole=v%d, catalogue=%d métier(s) %s"] =
        "CraftLink infra — dataVersion=|cFFE8B84B%d|r, protocol=v%d, catalogue=%d profession(s) %s",
    ["prêt"] = "ready", ["vide"] = "empty",
    ["mes recettes captées : "] = "my captured recipes: ",
    ["aucune recette captée — ouvre une fenêtre de métier une fois pour l'amorcer."] =
        "no recipes captured — open a profession window once to seed them.",
    ["réseau global : %s — |cFFFFFFFF%d|r en ligne, |cFFFFFFFF%d|r crafteur(s) connus"] =
        "global network: %s — |cFFFFFFFF%d|r online, |cFFFFFFFF%d|r known crafter(s)",
    ["connexion…"] = "connecting…",
    ["réseau : sollicitation envoyée (HI global + PING proximité)."] =
        "network: poll sent (global HI + proximity PING).",
    ["métier inconnu : "] = "unknown profession: ",
    ["commandes :"] = "commands:",
    ["statut (infra, mes recettes, réseau)"] = "status (infra, my recipes, network)",
    ["carnet d'ordres"] = "order ledger", ["poster une commande"] = "post an order",
    ["solliciter l'annuaire (présence + proximité)"] = "poll the directory (presence + proximity)",
    ["teste l'aller-retour réseau (PING global → PONG des autres porteurs)"] =
        "test the network round-trip (global PING → PONG from other holders)",
    ["vue commandes d'un métier (ou menu des métiers si vide)"] =
        "a profession's orders view (or profession menu if empty)",
    ["basculer fenêtre métier custom / vue Blizzard"] = "toggle custom profession window / Blizzard view",
    ["portée des notifications de commande"] = "order notification scope",
    ["notifications : |cFFFFFFFF%s|r — /co notify [all|directed|named|off]"] =
        "notifications: |cFFFFFFFF%s|r — /co notify [all|directed|named|off]",
    ["portée du scan des demandes de craft en chat (défaut : mes métiers)"] =
        "scope of the in-chat craft-request scan (default: my professions)",
    ["scan chat commerce/guilde : |cFFFFFFFF%s|r — /co scan [mine|all|off]"] =
        "trade/guild chat scan: |cFFFFFFFF%s|r — /co scan [mine|all|off]",
    ["mode solo"] = "solo mode",
    ["injecte/retire un réseau fictif (artisans + commandes)"] = "inject/remove a fake network (crafters + orders)",
    ["journalise le réseau dans la SavedVariable (off | clear | dump)"] =
        "log the network to the SavedVariable (off | clear | dump)",
    -- Résultats des commandes texte (/co post|accept|done|cancel|orders|ping)
    ["commande introuvable : "] = "order not found: ", ["ce n'est pas ta commande."] = "this isn't your order.",
    ["commande annulée : "] = "order cancelled: ", ["commande non disponible : "] = "order not available: ",
    ["c'est ta propre commande."] = "this is your own order.",
    ["cette commande ne t'est pas destinée."] = "this order isn't meant for you.",
    ["commande acceptée : %s (%s)"] = "order accepted: %s (%s)",
    ["tu n'as pas accepté cette commande."] = "you didn't accept this order.",
    ["commande relâchée : "] = "order released: ", ["carnet d'ordres :"] = "order ledger:",
    [" par "] = " by ", ["  (aucune commande active)"] = "  (no active order)",
    ["usage : /co post [shift-clic objet] [xN] [prix]"] = "usage: /co post [shift-click item] [xN] [price]",
    ["commande postée |cFFFFFFFF%s|r : %s x%d %s[%s]"] = "order posted |cFFFFFFFF%s|r: %s x%d %s[%s]",
    ["CraftLink absent — l'infra réseau n'est pas chargée."] = "CraftLink missing — the network infrastructure isn't loaded.",
    ["PING envoyé (canal %s%s). En attente des PONG…"] = "PING sent (channel %s%s). Waiting for PONGs…",
    ["rejoint"] = "joined", ["PAS rejoint"] = "NOT joined",
    [", +|cFFFFFFFF%d|r whisper(s)"] = ", +|cFFFFFFFF%d|r whisper(s)",
    ["entrante acceptée : |cFFFFFFFF%s|r"] = "incoming accepted: |cFFFFFFFF%s|r",
    -- /co debug (mode solo) + /co verbose + /co trace (diag)
    ["messages verbeux : activés"] = "verbose messages: on", ["messages verbeux : désactivés"] = "verbose messages: off",
    ["affiche les messages d'info en coulisse (ex. « X peut faire une captée ») ; auto si COCMonitor est chargé"] =
        "show behind-the-scenes info messages (e.g. \"X can make a captured request\"); automatic if COCMonitor is loaded",
    ["infra non prête."] = "infrastructure not ready.",
    ["activé — %d artisans + %d commandes + %d entrantes injectés."] =
        "enabled — %d crafters + %d orders + %d incoming injected.",
    ["désactivé — faux artisans et commandes purgés."] = "disabled — fake crafters and orders purged.",
    ["vidée."] = "cleared.", ["%d lignes (30 dernières) :"] = "%d lines (last 30):",
    ["ON. Fais tes tests, puis |cFFFFFFFF/reload|r, puis lis SavedVariables\\CraftingOrderClassic.lua (clé trace)."] =
        "ON. Run your tests, then |cFFFFFFFF/reload|r, then read SavedVariables\\CraftingOrderClassic.lua (trace key).",
    -- Statut bar
    ["réseau"] = "network", ["canal rejoint"] = "channel joined",
    ["en ligne"] = "online", ["artisan(s)"] = "crafter(s)",
    -- Professions
    ["Alchimie"] = "Alchemy", ["Forge"] = "Blacksmithing", ["Cuisine"] = "Cooking",
    ["Enchantement"] = "Enchanting", ["Ingénierie"] = "Engineering", ["Secourisme"] = "First Aid",
    ["Pêche"] = "Fishing", ["Herboristerie"] = "Herbalism", ["Travail du cuir"] = "Leatherworking",
    ["Minage"] = "Mining", ["Dépeçage"] = "Skinning", ["Couture"] = "Tailoring",
    ["Joaillerie"] = "Jewelcrafting", ["Calligraphie"] = "Inscription", ["Élémentaire"] = "Elemental",
    -- Statuts d'ordre
    ["En attente"] = "Pending", ["Acceptée"] = "Accepted", ["Livrée"] = "Delivered", ["Annulée"] = "Cancelled", ["Refusée"] = "Declined",
    -- Commande (Post)
    ["JE FOURNIS"] = "I PROVIDE", ["Réactifs"] = "Reagents",
    ["(cocher = je fournis)"] = "(check = I provide)", ["Commission"] = "Commission", ["Qté"] = "Qty",
    ["Destinataire :"] = "Recipient:", ["Diffuser à tous"] = "Broadcast to all", ["Poster"] = "Post",
    ["La commande sera visible par tout le monde (cible « Tous »)."] = "The order will be broadcast to everyone (target: \"All\").",
    ["Choisis un métier puis un plan."] = "Pick a profession then a recipe.",
    ["Cliquer pour changer de métier"] = "Click to change profession",
    ["Rechercher"] = "Search",
    ["Commande postée !"] = "Order posted!",
    -- Filtre réactifs en poche (P2) — icône + tooltip
    ["Réactifs en main"] = "Reagents in hand",
    ["Ne montrer que les plans dont j'ai déjà tous les réactifs."] = "Only show recipes I already have all the reagents for.",
    ["[Prêt]"] = "[Ready]",
    -- Sections de la liste des plans (en-têtes) : les noms d'emplacement/type/catégorie viennent
    -- des globales client (déjà localisées) ; seule cette catégorie de repli a besoin d'une clé.
    ["Autres"] = "Other",
    -- Filtre artisan ciblé (P5) : mode d'en-tête de la liste des plans
    ["connus"] = "known", ["niv. %d"] = "lvl %d",
    ["Choisis d'abord un plan."] = "Pick a recipe first.", ["Aucun plan sélectionné."] = "No recipe selected.",
    ["Ajoutés"] = "Added", ["fournis"] = "provided", ["Chargement…"] = "Loading…",
    -- Ligne « toute la liste » épinglée (destinataire groupé) — Commande + Récolte
    ["Toute la guilde"] = "Whole guild", ["Tous les amis"] = "All friends",
    ["Tous les ajoutés"] = "All added", ["Tous les croisés"] = "All met",
    -- Récolte (Gather)
    ["Rechercher une ressource"] = "Search a resource",
    ["Demande de récolte — quantité voulue"] = "Gather request — wanted quantity",
    ["stacks"] = "stacks", ["pile"] = "stack", ["piles"] = "stacks",
    ["Récolteur :"] = "Gatherer:", ["Prix proposé"] = "Price offered",
    ["Choisis un métier de récolte puis une ressource."] = "Pick a gathering profession then a resource.",
    ["Aucune ressource sélectionnée."] = "No resource selected.", ["par stack"] = "per stack", ["à l'unité"] = "per unit",
    ["Commande de récolte postée !"] = "Gather order posted!", ["Choisis d'abord une ressource."] = "Pick a resource first.",
    ["Toutes"] = "All",
    ["Stat"] = "Stat",
    ["Toutes les stats"] = "All stats",
    -- Légendes de la rangée de filtres style HdV (onglet Commande) : mots courts, au-dessus du champ.
    ["Objet |cFFE8B84Bélémentaire|r (farmé sur les mobs, pas de métier). Diffusé à tous. Quantité et prix |cFFE8B84B%s.|r"] =
        "|cFFE8B84BElemental|r item (farmed off mobs, no profession). Broadcast to all. Quantity and price |cFFE8B84B%s.|r",
    ["Diffusée aux récolteurs ayant |cFFE8B84B%s.|r Quantité et prix proposé |cFFE8B84B%s.|r"] =
        "Broadcast to gatherers with |cFFE8B84B%s.|r Quantity and offered price |cFFE8B84B%s.|r",
    -- Artisans
    ["SOURCE"] = "SOURCE", ["AJOUTER UN JOUEUR"] = "ADD A PLAYER", ["Nom du personnage"] = "Character name",
    ["Métier :"] = "Profession:", ["Chuchoter"] = "Whisper", ["Aucun artisan dans cette source."] = "No crafter in this source.",
    ["En ligne"] = "Online", ["En ligne · sans addon"] = "Online · no addon", ["Hors ligne"] = "Offline", ["niv "] = "lvl ", ["niv ?"] = "lvl ?",
    ["GUILDE"] = "GUILD", ["AMIS"] = "FRIEND", ["AJOUTÉ"] = "ADDED", ["CROISÉ"] = "MET", ["CONFÉDÉRÉ"] = "CONFED",
    ["Confédération"] = "Confederation",
    ["artisan ajouté : "] = "crafter added: ",
    ["(lié quand il sera en ligne avec l'addon)"] = "(linked when seen online with the addon)",
    -- Confédération GreenWall (display-only, /co gwroster)
    ["GreenWall non détecté — section « Confédération » masquée."] = "GreenWall not detected — « Confederation » section hidden.",
    ["GreenWall actif, aucun confédéré repéré (il faut qu'ils parlent en /g)."] = "GreenWall active, no confederate seen yet (they must talk in /g).",
    ["confédérés repérés (%d) :"] = "confederates seen (%d):",
    ["en ligne · annuaire"] = "online · directory", ["annuaire"] = "directory",
    ["pas encore dans l'annuaire (sans COC ?)"] = "not in directory yet (no COC?)",
    ["confédérés GreenWall repérés (SoD live only)"] = "GreenWall confederates seen (SoD live only)",
    -- Greffons échange / courrier (panneaux compagnons)
    ["Commandes pour ce joueur"] = "Orders for this player",
    ["Commandes à livrer"] = "Orders to deliver",
    ["+%d autre(s)"] = "+%d more",
    ["Molette : %d/%d"] = "Scroll: %d/%d",
    ["Demande-lui une pièce"] = "Ask them for an item",
    ["Clic : lui demander cette pièce."] = "Click: ask them for this item.",
    ["Demande envoyée à %s."] = "Request sent to %s.",
    ["Mets ton objet « %s » dans l'emplacement du bas de la fenêtre d'échange (« ne sera pas échangé ») — je l'enchante, tu le gardes."] = "Put your %s in the bottom slot of the trade window (\"will not be traded\") — I'll enchant it and you keep it.",
    ["Remplir depuis commande"] = "Fill from order",
    ["Marquer livrée"] = "Mark delivered",
    ["À réclamer : %s"] = "Collect: %s",
    ["À payer : %s"] = "To pay: %s",
    ["Pas de prix convenu."] = "No agreed price.",
    ["Gratuit."] = "Free.",
    ["Commande : %s"] = "Order: %s",
    ["Voici ta commande. Prix convenu : %s."] = "Here is your order. Agreed price: %s.",
    ["Voici ta commande."] = "Here is your order.",
    -- Fenêtre métier (ProfWindow)
    ["Recettes"] = "Recipes", ["Commandes"] = "Orders", ["Réactifs :"] = "Reagents:",
    ["Créer"] = "Create", ["Créer tout"] = "Create All", ["Vue Blizzard"] = "Blizzard view",
    ["Sélectionne une recette."] = "Select a recipe.", ["Produit "] = "Makes ",
    ["réactifs insuffisants."] = "not enough reagents.",
    ["Sélection changée en combat — réessaie après le combat."] = "Selection changed in combat — try again after combat.",
    ["fenêtre métier custom |cFF33DD33activée|r — ouvre un métier. (Guild Economy laisse la main.)"] =
        "custom profession window |cFF33DD33enabled|r — open a profession. (Guild Economy stands down.)",
    ["fenêtre métier custom |cFFFFCC00désactivée|r (vue Blizzard)."] =
        "custom profession window |cFFFFCC00disabled|r (Blizzard view).",
    ["» Vue Crafting Order"] = "» Crafting Order view",
    ["Module Commandes non chargé — redémarre complètement WoW (quitter/relancer), pas un simple /reload."] =
        "Orders module not loaded — fully restart WoW (quit/relaunch), not just /reload.",
}

for k, v in pairs(en) do L[k] = v end
