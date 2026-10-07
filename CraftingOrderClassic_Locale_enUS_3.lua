-- CraftingOrderClassic_Locale_enUS_3.lua — overlay enUS, 3/3. Clé FR » texte traduit.
-- Troisième part, ouverte le 2026-09-26 : _2 avait atteint le plafond anti-monolithe
-- (500 l/fichier) en accueillant les clés de la bande LFW. Même contrat que les deux
-- autres — table à plat fusionnée dans COC.L, aucun ordre requis entre les parts.

local COC = CraftingOrderClassic
local loc = GetLocale and GetLocale() or "enUS"
if loc ~= "enUS" and loc ~= "enGB" then return end
local L = COC.L

local en3 = {
    -- Bande « chercher du travail » + sélecteur d'offre (2026-09-26)
    ["Route"] = "Route",              -- languette courte (la vue garde « Leveling route »)
    ["Dispo — %s"] = "Available — %s",
    ["Offre"] = "Offer",
    ["Réactifs"] = "Reagents",
    ["Recettes"] = "Recipes",
    ["Aucun résultat pour cette recherche."] = "Nothing matches that search.",
    ["Rien à afficher pour ce métier."] = "Nothing to show for this profession.",
    ["Recettes proposées (%d/%d)"] = "Offered recipes (%d/%d)",
    -- Réseau sans canal + communauté officielle (2026-09-28)
    ["réseau par whisper"] = "whisper network",
    ["canal : aucun — le réseau passe en whisper (cercles, amis, guilde)"] =
        "channel: none — the network runs on whispers (circles, friends, guild)",
    ["communauté officielle marquée comme cercle d'artisans : %s"] =
        "official community marked as your crafters' circle: %s",
    ["Rejoins la communauté des artisans : %s — c'est là que Crafting Order trouve les autres joueurs."] =
        "Join the crafters' community: %s — that's where Crafting Order finds other players.",
    ["(/co circle nolink : ne plus afficher ce rappel)"] = "(/co circle nolink: stop showing this reminder)",
    ["rappel de la communauté éteint — /co circle link pour le rallumer."] =
        "community reminder off — /co circle link turns it back on.",
    ["rappel de la communauté rallumé."] = "community reminder back on.",
    -- Icône « nouvelle version » de la barre de la minicarte (2026-09-28)
    ["Tu as la %s. Mets l'addon à jour depuis CurseForge."] = "You have %s. Update the addon from CurseForge.",
    ["Crafting Order n'utilise plus de canal de discussion : sur WoW Forever, il est découpé en salles et les joueurs ne s'y voient pas tous.\n\nLes artisans se retrouvent maintenant dans la communauté |cFFFFD100%s|r. Clique sur le lien dans ton chat pour y entrer."] =
        "Crafting Order no longer uses a chat channel: on WoW Forever it gets split into separate rooms, so players can't all see each other.\n\nCrafters now meet in the |cFFFFD100%s|r community. Click the link in your chat to join it.",
    -- Signature du build de test, /co version (2026-09-28)
    ["Build : %s"] = "Build: %s",
    ["Branches en test : %s"] = "Branches under test: %s",
    -- Salle de découverte, Directory_Room (2026-09-29)
    ["l'addon rejoint le canal |cFFFFFFFF%s|r pour se présenter aux autres joueurs de Crafting Order ; tes commandes, elles, restent en whisper. |cFFFFFFFF/co channel room off|r pour ne plus le rejoindre."] =
        "the addon joins the |cFFFFFFFF%s|r channel to introduce itself to other Crafting Order players; your orders still travel by whisper. |cFFFFFFFF/co channel room off|r to stop joining it.",
    ["salle de découverte coupée : l'addon quitte |cFFFFFFFF%s|r et ne le rejoindra plus."] =
        "discovery room off: the addon leaves |cFFFFFFFF%s|r and won't join it again.",
    ["salle de découverte rouverte : l'addon rejoint |cFFFFFFFF%s|r pour se présenter."] =
        "discovery room back on: the addon joins |cFFFFFFFF%s|r to introduce itself.",
    ["salle de découverte : en attente du canal (quelques secondes après la connexion)"] =
        "discovery room: waiting for the channel (a few seconds after login)",
    ["salle de découverte : coupée — |cFFFFFFFF/co channel room on|r pour la rouvrir"] =
        "discovery room: off — |cFFFFFFFF/co channel room on|r to turn it back on",
    ["salle de découverte : |cFFFFFFFF%s|r — on s'y présente, les données restent en whisper"] =
        "discovery room: |cFFFFFFFF%s|r — used to say hello, data still goes by whisper",
    -- Annonce sur Trade (Services), Orders_AnnounceSend (2026-09-29)
    ["Annoncer en Commerce"] = "Announce in Trade",
    ["Poste aussi une ligne sur Trade (Services), lisible par tous : les joueurs avec ou sans l'addon voient ta commande. Une ligne par clic, jamais de répétition automatique ; seulement pour une commande à tous, dans une capitale."] =
        "Also posts one line in Trade (Services) that everyone can read: players with or without the addon see your order. One line per click, never repeated automatically; only for an order to everyone, in a capital city.",
    ["seule une commande ouverte, à toi, s'annonce."] = "only an open order of yours can be announced.",
    ["commande privée : elle ne s'annonce pas sur Commerce."] = "private order: it is never announced in Trade.",
    ["déjà annoncée : tu pourras la rappeler dans %d min."] = "already announced: you can repeat it in %d min.",
    ["une annonce par minute au plus : attends encore %d s."] = "one announcement per minute at most: wait %d more s.",
    ["pas de canal Trade (Services) ici : il faut être dans une capitale."] =
        "no Trade (Services) channel here: you need to be in a capital city.",
    ["annonce impossible : un objet n'est pas encore connu du jeu, réessaie dans un instant."] =
        "can't announce yet: an item isn't loaded by the game, try again in a moment.",
    ["annonce refusée par le jeu."] = "the game refused the announcement.",
    ["commande annoncée sur %s."] = "order announced in %s.",
    ["Clic droit : annoncer en Commerce"] = "Right-click: announce in Trade",
    ["Clic droit : rappeler en Commerce"] = "Right-click: repeat in Trade",
    -- Annonce de la dispo LFW (2026-09-30)
    ["dispo annoncée sur %s."] = "availability announced in %s.",
    ["Quand tu actives ta dispo, poste aussi une ligne sur Trade (Services) : les joueurs avec ou sans l'addon voient que tu cherches du travail. Une ligne par activation, jamais au renouvellement automatique ; dans une capitale. Même réglage que la case du formulaire de commande."] =
        "When you turn on looking for work, also posts one line in Trade (Services): players with or without the addon see that you are looking for work. One line each time you turn it on, never on the automatic refresh; in a capital city. Same setting as the box on the order form.",
    -- Aide sans communauté officielle (2026-09-30)
    ["|cFFFFFFFF/co circle|r : tes cercles d'artisans (les communautés du jeu que tu as marquées)."] =
        "|cFFFFFFFF/co circle|r: your crafters' circles (the in-game communities you have marked).",
    ["Les artisans se trouvent par tes amis et ta guilde, et par les canaux que tu coches dans l'onglet Artisans, liste « Canaux surveillés » : Commerce, la salle de découverte, tes communautés, les joueurs autour de toi. Le bouton « Configurer » y rouvre le panneau du premier lancement."] =
        "Crafters find each other through your friends and your guild, and through the channels you tick in the Artisans tab, under \"Watched channels\": Trade, the discovery room, your communities, the players around you. The \"Setup\" button there reopens the first-launch panel.",
    -- Aide remise à jour : onglets latéraux, cercles (2026-09-28)
    ["Ils se rangent sur le bord droit, comme ceux de la fenêtre de métier. Survole une icône pour lire son nom ; le chiffre sur le Carnet compte tes commandes en cours."] =
        "They sit along the right edge, like the ones on the profession window. Hover an icon to read its name; the number on the Ledger counts your active orders.",
    ["|cFFE8B84BMes artisans|r : les métiers de tous les personnages de ton compte, et leurs recettes."] =
        "|cFFE8B84BMy Artisans|r: the professions of every character on your account, and their recipes.",
    ["|cFFE8B84BAide|r et |cFFE8B84BNouveautés|r : cette page, et ce qui a changé à chaque version."] =
        "|cFFE8B84BHelp|r and |cFFE8B84BWhat's New|r: this page, and what changed in each version.",
    ["cercles d'artisans (communautés) et rappel de la communauté"] =
        "crafters' circles (communities) and the community reminder",
    ["ou"] = "or",   -- statuts d'une commande, Aide : « (ou Annulée / Refusée) »
    -- Courrier : l'addon ne coupe plus une pile lui-même (2026-09-28)
    ["Il en manque %d au courrier : sépare-les d'une pile toi-même (Maj-clic sur la pile), puis dépose-les."] =
        "%d still missing from the mail: split them off a stack yourself (Shift-click the stack), then drop them in.",
    ["La pile de %d est prête dans ton sac : dépose-la toi-même dans le courrier."] =
        "The stack of %d is ready in your bag: drop it into the mail yourself.",
    -- Note de membre de la communauté, /co note (2026-09-29)
    ["le texte de tes métiers, à coller dans ta note de communauté (visible même hors ligne)"] =
        "the text of your professions, to paste into your community note (visible even offline)",
    ["aucun métier connu pour ce personnage : ouvre une fois ta fenêtre de métier, puis recommence."] =
        "no profession known for this character yet: open your profession window once, then try again.",
    ["Copie ce texte (Ctrl+C), puis colle-le dans ta note de membre : Communautés, clic droit sur ton nom, « Note ». Les autres joueurs de Crafting Order verront tes métiers, même quand tu es hors ligne."] =
        "Copy this text (Ctrl+C), then paste it into your member note: Communities, right-click your name, \"Note\". Other Crafting Order players will see your professions, even when you're offline.",
    -- Lib absente au chargement (2026-09-30)
    ["la bibliothèque CraftLink n'a pas pu se charger : le réseau de l'addon est coupé (annuaire, commandes). Fais |cFFFFFFFF/reload|r ; si ça continue, réinstalle l'addon."] =
        "the CraftLink library failed to load: the addon's network is off (directory, orders). Type |cFFFFFFFF/reload|r; if it keeps happening, reinstall the addon.",
    -- Canaux surveillés : l'origine d'une entrante lue sur le canal Général (2026-09-30)
    ["général"] = "general",
    -- Canaux surveillés : la section de l'onglet Artisans (2026-09-30)
    ["CANAUX SURVEILLÉS"] = "WATCHED CHANNELS",
    ["ANNONCES LUES"] = "ANNOUNCEMENTS READ",
    ["L'addon y lit les demandes, les dispos et les annonces des autres joueurs de l'addon. Il n'écrit que sur Trade (Services), et seulement si tu coches « Annoncer en Commerce »."] =
        "The addon reads requests, availability lines and other addon users' announcements there. It only writes in Trade (Services), and only if you tick \"Announce in Trade\".",
    ["Commerce (Services)"] = "Trade (Services)",
    ["Commerce"] = "Trade",
    ["Commerce (local)"] = "Trade (Local)",
    ["Général"] = "General",
    ["en ville"] = "in town",
    ["RÉSEAU DE L'ADDON"] = "ADDON NETWORK",
    ["L'addon s'y présente par un message invisible aux joueurs de ta salle ; ensuite, tout passe en chuchotement."] =
        "The addon introduces itself there with an invisible message to the players in your room; after that, everything goes by whisper.",
    ["salle"] = "room",
    ["COMMUNAUTÉS"] = "COMMUNITIES",
    ["Les membres d'une communauté cochée rejoignent ton annuaire, même hors ligne. Aucune donnée de l'addon n'y passe."] =
        "Members of a ticked community join your directory, even offline. No addon data travels through it.",
    ["aucune communauté"] = "no community",
    ["AUTOUR DE MOI"] = "AROUND ME",
    ["Ce que les joueurs disent ou crient près de toi (les lignes LFW), et, en ville, ceux que tu vois crafter."] =
        "What players say or yell near you (LFW lines) and, in town, the ones you see crafting.",
    ["Dire et crier"] = "Say and yell",
    ["Crafteurs autour"] = "Crafters nearby",
    ["NOTIFICATIONS"] = "NOTIFICATIONS",
    ["Ce qui te prévient : une ligne dans le chat, un bandeau et un son. Décochée, une case ne retire aucune commande : tout reste dans le Carnet et la vue métier."] =
        "What alerts you: a chat line, a banner and a sound. Unticking a box removes no order: everything stays in the Ledger and the profession view.",
    ["Commandes de l'addon"] = "Addon orders",
    ["Les commandes que les autres joueurs de l'addon t'envoient ou publient."] =
        "Orders that other addon users send you or post.",
    ["Demandes lues dans le chat"] = "Requests read in chat",
    ["Les demandes (« WTB [objet] ») lues dans les canaux cochés plus haut, pour ce que tu sais crafter."] =
        "Requests (\"WTB [item]\") read in the channels ticked above, for what you can craft.",
    ["Guilde, amis et pour moi"] = "Guild, friends and me",
    ["Pas les commandes publiques ouvertes à tous."] = "Not the public orders open to everyone.",
    ["Seulement pour moi"] = "Only for me",
    ["Les commandes à ton nom ou à celui d'un de tes persos."] = "Orders in your name or one of your characters'.",
    ["Aussi les commandes publiques, pour un métier que tu as."] = "Also public orders, for a profession you have.",
    ["Suivi de mes commandes"] = "Tracking my orders",
    ["Une commande qu'on t'a remise, dont on a confirmé la réception, ou qu'on a refusée."] = "An order handed to you, confirmed as received, or declined.",
    ["Message à la connexion"] = "Login message",
    ["La ligne « chargé — /co help » quand tu te connectes."] = "The \"loaded — /co help\" line when you log in.",
    ["FAÇON DE PRÉVENIR"] = "HOW TO ALERT",
    ["Pour toutes les alertes cochées au-dessus."] = "For every alert ticked above.",
    ["Ligne dans le chat"] = "Chat line",
    ["Bandeau à l'écran"] = "On-screen banner",
    ["Son"] = "Sound",
    ["Tu n'es pas dans ce canal en ce moment. Ton choix est gardé pour ton retour."] =
        "You're not in this channel right now. Your choice is kept for when you're back.",
    -- Refonte de l'onglet Artisans (2026-09-30) : la bande des joueurs croisés, le bouton qui rouvre le panneau
    ["Croisés"] = "Met",
    ["Configurer"] = "Setup",
    ["Rouvre le panneau de première connexion."] = "Reopens the first-login panel.",
    -- Canaux surveillés : le panneau de première connexion (2026-09-30)
    ["Où chercher les artisans ?"] = "Where to look for crafters?",
    ["L'addon trouve les artisans par les canaux que tu coches ici. Tu pourras tout changer plus tard, dans l'onglet Artisans."] =
        "The addon finds crafters through the channels you tick here. You can change everything later, in the Artisans tab.",
    ["Annoncer aussi mes commandes et ma dispo sur Trade (Services)"] =
        "Also announce my orders and my availability in Trade (Services)",
    ["Une ligne lisible par tous, seulement quand tu cliques."] = "One line everyone can read, only when you click.",
    ["Valider"] = "Confirm",
    -- Icône « une commande t'attend » de la barre de la minicarte (2026-09-28)
    ["Commandes à ton nom : %d"] = "Orders in your name: %d",
    ["pour %s"] = "for %s",
    -- 3e tour : le clic vers le perso qui sait faire, les commandes non nommées (2026-09-30)
    ["Pour ta guilde ou tes amis : %d"] = "For your guild or friends: %d",
    ["Pour tous : %d"] = "For everyone: %d",
    ["Clic : ouvrir %s de %s."] = "Click: open %s (%s).",
    ["Clic : voir pourquoi."] = "Click: see why.",
    ["Hors combat seulement."] = "Out of combat only.",
    ["Où l'apprendre : %s"] = "Where to learn it: %s",
    ["Aucun de tes persos ne sait faire %s."] = "None of your characters can make %s.",
    ["%d commandes attendent dans ce métier."] = "%d orders are waiting in this profession.",
    ["Ouvrir la fenêtre de métier"] = "Open the profession window",

    -- Signaler un bug ou une idée (CraftingOrderClassic_Report.lua, 2026-10-07)
    ["Signaler un bug ou proposer une idée"] = "Report a bug or suggest an idea",
    ["Bug"] = "Bug",
    ["Idée"] = "Idea",
    ["Sans compte GitHub"] = "No GitHub account",
    ["Copie ce lien (Ctrl+C) et ouvre-le dans ton navigateur : le formulaire arrive avec la version déjà remplie."] = "Copy this link (Ctrl+C) and open it in your browser: the form comes up with the version already filled in.",
    ["Pas de compte GitHub ? Copie ce lien (Ctrl+C) et laisse un commentaire sur la page CurseForge."] = "No GitHub account? Copy this link (Ctrl+C) and leave a comment on the CurseForge page.",
    ["Un bug, ou une idée pour l'addon ? Choisis ci-dessous : l'addon te donne le lien du formulaire, déjà rempli."] = "A bug, or an idea for the addon? Pick below: the addon gives you the link to the form, already filled in.",
    ["signaler un bug ou proposer une idée (lien vers un ticket GitHub)"] = "report a bug or suggest an idea (link to a GitHub issue)",
}

for k, v in pairs(en3) do L[k] = v end
