-- CraftingOrderClassic_Locale.lua — localisation du CHROME de l'UI.
-- Convention : la CLÉ est le texte FRANÇAIS (langue de référence du code) ; `COC.L[clé]` renvoie la
-- clé par défaut (donc un client FR voit le texte tel quel, zéro régression) ; un overlay par langue
-- (ici enUS) remplace les clés. Pour ajouter une langue : copier le bloc `en` et traduire.
-- NB : les NOMS d'objets/recettes restent multilingues via GetItemInfo/GetSpellInfo (côté données).

local COC = CraftingOrderClassic
local L = setmetatable({}, { __index = function(_, k) return k end })
COC.L = L

local loc = GetLocale and GetLocale() or "enUS"

-- ------------------------------------------------------------------
-- Anglais (enUS/enGB) — overlay. Clé FR → texte EN.
-- ------------------------------------------------------------------
if loc == "enUS" or loc == "enGB" then
    local en = {
        -- Onglets / fenêtre
        ["Carnet"] = "Ledger", ["Commande"] = "Order", ["Récolte"] = "Gather", ["Artisans"] = "Artisans",
        ["Classic · canal global"] = "Classic · global channel",
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
        ["Survole un ami dans la liste d'amis, ou sélectionne un membre dans le panneau de guilde : ses métiers primaires s'affichent sans ouvrir cette fenêtre."] =
            "Hover a friend in the Friends list, or select a guildmate in the Guild panel, to see their primary professions without opening this window.",
        ["Clic droit sur un joueur qui a l'addon (ami, guilde, croisé) : « Passer commande à… » ouvre l'onglet Commande déjà ciblé sur lui."] =
            "Right-click a player who runs the addon (friend, guild, met): \"Order from…\" opens the Order tab already aimed at them.",
        ["« Met » devient « Annuaire ». Le bouton « Rafraîchir l'annuaire » appelle le canal : tous les porteurs en ligne répondent et s'y ajoutent."] =
            "\"Met\" is now \"Directory\". The \"Refresh directory\" button calls the channel: every online addon user answers and joins it.",
        -- Onglet Nouveautés (changelog en jeu)
        ["Nouveautés"] = "What's New",
        ["Repérer les crafteurs sans l'addon + passe de performance"] = "Spot crafters without the addon + a performance pass",
        ["Repérage passif des crafteurs autour de toi, même sans l'addon (onglet Artisans → « Repérer les crafteurs autour », ou |cFFFFFFFF/co crafters on|r). Désactivé par défaut, en ville seulement."] =
            "Passive detection of crafters around you, even without the addon (Artisans tab, or |cFFFFFFFF/co crafters on|r). Off by default, towns only.",
        ["Liste de plans de l'onglet Commande réécrite : plus fluide sur les métiers à centaines de recettes (Couture)."] =
            "The Order tab's plan list was rewritten: smoother on professions with hundreds of recipes (Tailoring).",
        ["La fenêtre ne se redessine plus à chaque message réseau : les rafales sont regroupées en un seul rendu."] =
            "The window no longer redraws on every network message: bursts are batched into a single redraw.",
        ["Protocole de commande durci : un autre client ne peut plus annuler ta commande, usurper une acceptation, ni s'attribuer une livraison."] =
            "Hardened order protocol: another client can no longer cancel your order, fake an acceptance, or claim a delivery.",
        ["Commander depuis les panneaux Amis & Guilde"] = "Order from the Friends & Guild panels",
        ["Greffons échange & courrier, dock en vue Blizzard"] = "Trade & mail companions, Blizzard-view dock",
        ["Panneaux compagnons sur la fenêtre d'échange et de courrier pour livrer une commande sans ouvrir le carnet."] =
            "Companion panels on the trade and mail windows to deliver an order without opening the board.",
        ["La colonne Commandes peut s'ancrer à droite de la fenêtre métier native (vue Blizzard)."] =
            "The Orders column can dock to the right of the native profession window (Blizzard view).",
        ["Sous le capot : mises à jour plus sûres"] = "Under the hood: safer upgrades",
        ["Tes données sauvegardées portent désormais une version : une mise à jour qui doit les réorganiser ne tourne qu'une fois, tes recettes et commandes restent intactes."] =
            "Your saved data now carries a version, so an upgrade that needs to reshape it runs once and your recipes and orders stay intact.",
        ["Protocole de commandes consolidé (mêmes échanges réseau) : ce build reste compatible avec les joueurs encore en 1.7.x."] =
            "The order protocol was consolidated (same network exchanges); this build still talks to players still on 1.7.x.",
        ["Alertes de plan looté qui te concernent"] = "Looted-recipe alerts that concern you",
        ["L'alerte de plan looté ne se déclenche plus que s'il te concerne : tu as le métier et peux l'apprendre, ou un ami/partenaire de ton annuaire ne le connaît pas encore."] =
            "The looted-recipe alert now fires only when it concerns you: you have the profession and can learn it, or a friend/partner in your directory doesn't know it yet.",
        ["Les candidats au don incluent désormais tes amis, pas seulement les partenaires marqués — l'alerte « intéressés » et |cFFFFFFFF/co gift|r touchent tout ton annuaire."] =
            "Gift candidates now include your friends, not just flagged partners — the \"interested\" alert and |cFFFFFFFF/co gift|r reach your whole directory.",
        ["Amis Battle.net + commande par métier"] = "Battle.net friends + order by profession",
        ["Les métiers et le menu Crafting Order fonctionnent maintenant sur les amis Battle.net, pas seulement les amis ajoutés par personnage."] =
            "Professions and the Crafting Order menu now work on Battle.net friends, not just character friends.",
        ["Clic droit sur un artisan : une entrée « Passer commande » par métier, qui ouvre l'onglet Commande déjà réglé sur ce métier."] =
            "Right-click a crafter: one \"Order\" entry per profession, opening the Order tab already set to that profession.",
        ["Le résumé d'un artisan indique la profondeur de son carnet (« · N plans ») ; maintiens Maj sur son infobulle en jeu pour lister ses recettes connues."] =
            "A crafter's summary shows how deep their book is (\"· N recipes\"); hold Shift over their in-world tooltip to list the recipes they know.",
        ["Correctif : un personnage n'affiche plus par erreur les métiers de ses rerolls dans ton annuaire."] =
            "Fix: a character no longer shows their alts' professions by mistake in your directory.",
        ["Allemand et espagnol + onglet Nouveautés"] = "German and Spanish + a What's New tab",
        ["L'interface se traduit en allemand et en espagnol selon la langue de ton client WoW."] =
            "The interface is translated into German and Spanish depending on your WoW client language.",
        ["Ce nouvel onglet « Nouveautés » affiche les notes de version directement en jeu."] =
            "This new What's New tab shows the release notes right in the game.",
        -- Onglet Nouveautés — v1.9.0
        ["Tes rerolls réunis : cooldowns partagés, une identité, l'onglet Mes artisans"] =
            "Your alts, together: shared cooldowns, one identity, a My Artisans tab",
        ["Cooldowns de recettes partagés : les autres voient « Transmutation : prête » ou « dans 14h » sur ton infobulle d'artisan — fini de demander en canal si ton Arcanite est dispo."] =
            "Shared recipe cooldowns: others see \"Transmute: ready\" or \"in 14h\" on your artisan tooltip — no more asking in chat whether your Arcanite is up.",
        ["Regroupe tes persos sous une identité (|cFFFFFFFF/co alts on|r) : une commande nommée pour ton alchimiste hors ligne arrive sur le perso où tu es connecté, et tu peux l'accepter depuis n'importe lequel. Vérifié des deux côtés (personne ne peut se faire passer pour le reroll d'autrui). Désactivé par défaut."] =
            "Group your characters under one identity (|cFFFFFFFF/co alts on|r): an order named for your offline alchemist reaches whichever character you're on, and you can accept it from any of them. Verified both ways (nobody can pose as someone else's alt). Off by default.",
        ["Nouvel onglet « Mes artisans » : tous les métiers de ton compte sur le royaume en une vue, comme un seul perso — niveau, recettes connues par catégorie, cooldowns en tête, et quel perso porte chaque recette."] =
            "New \"My Artisans\" tab: all your account's professions on the realm in one view, as a single character — level, known recipes by category, cooldowns at the top, and which character carries each recipe.",
        ["VU"] = "SEEN",
        ["vu crafter (sans l'addon)"] = "seen crafting (no addon)",
        ["vu crafter"] = "seen crafting",
        ["%d+ · vu crafter"] = "%d+ · seen crafting",
        -- Cooldowns de recettes (transmutations & co)
        ["%s : prête"] = "%s: ready",
        ["%s : dans %s"] = "%s: in %s",
        ["(estimé)"] = "(estimated)",
        ["Transmutation"] = "Transmute",
        ["%dj"] = "%dd", ["%dh"] = "%dh", ["%dmin"] = "%dmin",
        -- Relais partenaire (fiche d'un artisan hors ligne servie par un contact de confiance)
        ["via %s · il y a %s"] = "via %s · %s ago",
        ["RELAIS"] = "RELAYED",
        -- Rerolls (identité joueur multi-persos, /co alts — opt-in)
        ["rerolls : ACTIVÉS — ta liste de persos est annoncée au réseau."] =
            "alts: ENABLED — your character list is announced to the network.",
        ["rerolls : désactivés — rien n'est annoncé (opt-in : /co alts on)."] =
            "alts: disabled — nothing is announced (opt-in: /co alts on).",
        ["perso principal (vitrine) : %s"] = "main character (front): %s",
        ["persos du compte (%s) : %s"] = "account characters (%s): %s",
        ["le lien n'est vérifié chez les autres qu'après une connexion de CHAQUE perso (addon actif)."] =
            "others only verify the link after EACH character has logged in once (addon running).",
        ["rerolls activés — perso principal : %s (changer : /co alts main <nom>)"] =
            "alts enabled — main character: %s (change: /co alts main <name>)",
        ["rerolls désactivés — dissolution annoncée au réseau."] =
            "alts disabled — dissolution announced to the network.",
        ["perso inconnu sur ce compte : %s (connecte-le une fois avec l'addon)"] =
            "unknown character on this account: %s (log it in once with the addon)",
        ["regrouper tes rerolls (opt-in) : liste annoncée, commandes routées vers ton perso connecté"] =
            "group your alts (opt-in): list announced, orders routed to your online character",
        ["commande nommée pour %s : connecte ce perso, ou active /co alts on pour accepter d'ici."] =
            "order named for %s: log that character in, or enable /co alts on to accept from here.",
        ["|cFFFFCC00commande pour ton reroll %s|r de |cFFFFFFFF%s|r : %s%s%s"] =
            "|cFFFFCC00order for your alt %s|r from |cFFFFFFFF%s|r: %s%s%s",
        ["En ligne via %s"] = "Online via %s",
        ["reroll : %s (%s)"] = "alt: %s (%s)",
        -- Onglet « Mes artisans » (vue agrégée des métiers du compte — 100 % local)
        ["Mes artisans"] = "My Artisans",
        ["MÉTIERS DU COMPTE"] = "ACCOUNT PROFESSIONS",
        ["%d recettes"] = "%d recipes",
        ["Aucun métier. Ouvre ta fenêtre métier sur chaque perso une fois."] =
            "No professions. Open your profession window on each character once.",
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
        ["%s n'est plus en sourdine."] = "%s is no longer muted.",
        ["usage : /co unmute <nom>"] = "usage: /co unmute <name>",
        ["aucun joueur en sourdine. /co mute <nom> pour en ajouter un."] = "no muted players. /co mute <name> to add one.",
        ["en sourdine (%d) : %s"] = "muted (%d): %s",
        ["mute auto bas niveau : |cFFFFFFFFdésactivé|r — /co lowlevel <niveau>"] = "low-level auto-mute: |cFFFFFFFFoff|r — /co lowlevel <level>",
        ["mute auto bas niveau : sous le niveau |cFFFFFFFF%d|r — /co lowlevel [N|off]"] = "low-level auto-mute: below level |cFFFFFFFF%d|r — /co lowlevel [N|off]",
        ["%s a posté %d fois en peu de temps. Le mettre en sourdine ?"] = "%s posted %d times in a short while. Mute them?",
        ["muter/démuter un joueur (aucune notif de sa part)"] = "mute/unmute a player (no notifications from them)",
        ["seuil de mute auto des persos bas niveau (défaut 5)"] = "auto-mute threshold for low-level characters (default 5)",
        -- Réputation sociale (crafts livrés, diffusée via SK)
        ["%d livrés"] = "%d delivered",
        -- Profondeur du carnet + dépliage des plans connus (tooltip social)
        ["· %d plans"] = "· %d recipes",
        ["+%d de plus"] = "+%d more",
        ["Maj : plans connus"] = "Shift: known recipes",
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
        -- /co debug (mode solo) + /co trace (diag)
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
        ["LISTE DES PLANS"] = "RECIPE LIST", ["JE FOURNIS"] = "I PROVIDE", ["Réactifs"] = "Reagents",
        ["(cocher = je fournis)"] = "(check = I provide)", ["Commission"] = "Commission", ["Qté"] = "Qty",
        ["Destinataire :"] = "Recipient:", ["Diffuser à tous"] = "Broadcast to all", ["Poster"] = "Post",
        ["Choisis un métier puis un plan."] = "Pick a profession then a recipe.",
        ["Rechercher un plan"] = "Search a recipe", ["Qualité : "] = "Quality: ",
        ["Sélection : "] = "Selection: ", ["Commande postée !"] = "Order posted!",
        -- Filtre réactifs en poche (P2)
        ["Réactifs : j'ai tout"] = "Reagents: I have it all", ["Réactifs : "] = "Reagents: ",
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
        ["MÉTIER DE RÉCOLTE"] = "GATHERING PROFESSION", ["Rechercher une ressource"] = "Search a resource",
        ["LISTE DES RESSOURCES"] = "RESOURCE LIST", ["Demande de récolte — quantité voulue"] = "Gather request — wanted quantity",
        ["stacks"] = "stacks", ["pile"] = "stack", ["piles"] = "stacks",
        ["Récolteur :"] = "Gatherer:", ["Prix proposé"] = "Price offered",
        ["Choisis un métier de récolte puis une ressource."] = "Pick a gathering profession then a resource.",
        ["Aucune ressource sélectionnée."] = "No resource selected.", ["par stack"] = "per stack", ["à l'unité"] = "per unit",
        ["Commande de récolte postée !"] = "Gather order posted!", ["Choisis d'abord une ressource."] = "Pick a resource first.",
        ["Toutes"] = "All",
        ["Objet |cFFE8B84Bélémentaire|r (farmé sur les mobs, pas de métier). Diffusé à tous. Quantité et prix |cFFE8B84B%s.|r"] =
            "|cFFE8B84BElemental|r item (farmed off mobs, no profession). Broadcast to all. Quantity and price |cFFE8B84B%s.|r",
        ["Diffusée aux récolteurs ayant |cFFE8B84B%s.|r Quantité et prix proposé |cFFE8B84B%s.|r"] =
            "Broadcast to gatherers with |cFFE8B84B%s.|r Quantity and offered price |cFFE8B84B%s.|r",
        -- Artisans
        ["SOURCE"] = "SOURCE", ["AJOUTER UN JOUEUR"] = "ADD A PLAYER", ["Nom du personnage"] = "Character name",
        ["Métier :"] = "Profession:", ["Chuchoter"] = "Whisper", ["Aucun artisan dans cette source."] = "No crafter in this source.",
        ["En ligne"] = "Online", ["Hors ligne"] = "Offline", ["niv "] = "lvl ", ["niv ?"] = "lvl ?",
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
        ["fenêtre métier custom |cFF33DD33activée|r — ouvre un métier. (Guild Economy laisse la main.)"] =
            "custom profession window |cFF33DD33enabled|r — open a profession. (Guild Economy stands down.)",
        ["fenêtre métier custom |cFFFFCC00désactivée|r (vue Blizzard)."] =
            "custom profession window |cFFFFCC00disabled|r (Blizzard view).",
        ["» Vue Crafting Order"] = "» Crafting Order view",
        ["Module Commandes non chargé — redémarre complètement WoW (quitter/relancer), pas un simple /reload."] =
            "Orders module not loaded — fully restart WoW (quit/relaunch), not just /reload.",
        -- Minimap + menu métiers
        ["Clic : ouvrir le carnet d'ordres"] = "Click: open the order ledger",
        ["Clic droit : mes métiers"] = "Right click: my professions",
        ["Mes métiers"] = "My professions", ["Aucun métier connu."] = "No known profession.",
        ["Don / gratuit"] = "Free / gift",
        -- Entrantes (alertes chat)
        ["|cFFFF8800entrante|r |cFFFFFFFF%s|r (%s) : %s%s%s"] = "|cFFFF8800incoming|r |cFFFFFFFF%s|r (%s): %s%s%s",
        ["   |cFF33DD33→ tu sais la crafter|r — Carnet › Entrantes"] = "   |cFF33DD33→ you can craft it|r — Ledger › Incoming",
        ["|cFFFFCC00commande pour TOI|r de |cFFFFFFFF%s|r : %s%s%s"] = "|cFFFFCC00order for YOU|r from |cFFFFFFFF%s|r: %s%s%s",
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
        ["La pastille verte/grise indique s'il est en ligne."] = "The green/gray dot shows whether they're online.",
        ["Réseau, confidentialité & statuts"] = "Network, privacy & statuses",
        ["L'addon rejoint un canal dédié pour faire circuler le carnet entre joueurs de l'addon — aucun message lisible n'y est envoyé."] =
            "The addon joins a dedicated channel to relay the ledger between addon users — no readable text is ever sent there.",
        ["|cFFFFFFFF/co channel off|r le quitte à tout moment (whisper et guilde restent actifs) ; |cFFFFFFFF/co channel on|r le rejoint."] =
            "|cFFFFFFFF/co channel off|r leaves it anytime (whisper and guild stay active); |cFFFFFFFF/co channel on|r rejoins it.",
        ["Statuts d'une commande : "] = "Order statuses: ",
    }
    for k, v in pairs(en) do L[k] = v end
end
