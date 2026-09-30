# Registre de vérification en jeu — Crafting Order - Classic

Les portes automatiques du pipeline (Lua 5.1, anti-monolithe, localisation, tests headless) mesurent
du **texte**. Elles ne savent pas si l'addon *fonctionne* : une donnée correctement écrite prouve
qu'une chose est **déclarée**, jamais qu'elle **marche**. La seule porte qui mesure le produit, c'est
le **banc 2 comptes Forever** — et jusqu'au 2026-09-23 elle ne laissait aucune trace dans le dépôt.
L'état « éprouvé / pas éprouvé » ne vivait que dans une tête ou dans la mémoire d'un agent, et un
« je crois que c'était testé » ne vaut rien la semaine suivante.

Ce fichier est cette trace. Il répond à **une** question : *jusqu'où le produit a-t-il été vu
fonctionner ?* `scripts\untested.ps1` la pose au dépôt et rend la liste de ce qui est venu après.

## Comment on l'écrit

Après une séance au banc, on ajoute **en tête** de la section suivante une ligne de la forme :

```
- AAAA-MM-JJ HH:MM — jusqu'a <sha> — <build> — <verdict> — <ce qui a été observé>
```

Le `<sha>` est le dernier commit **réellement présent dans le client** pendant la séance (celui que
`deploy.ps1` a copié), pas le dernier commit du jour. Le `<build>` est ce que `/co version` affiche
dans le jeu (`main-dev@<sha>` et les branches en test) : on le recopie, on ne le déduit pas. Le
reste est en clair, pour qu'un humain relise un verdict sans le décoder.

**Au banc, le repère est le dernier commit de la BRANCHE éprouvée, pas la fusion `main-dev@…`.** La
fusion embarque les branches des autres sessions, pas forcément vues ; et `main-dev` est refaite
à chaque release, sa fusion ne reste atteignable que par une sauvegarde.

**Plusieurs sessions écrivent ici en parallèle** (depuis le 2026-09-28), chacune sur sa branche.
D'où l'heure plutôt qu'un numéro du jour : deux sessions prenaient le même « (14) ». Le fichier
fusionne en `merge=union` (`.gitattributes`), les deux relevés se retrouvent l'un sous l'autre sans
conflit, et `untested.ps1` fait l'union de tous les repères : l'ordre des lignes n'importe plus.

Deux règles qui font la valeur du registre :

1. **On n'écrit un relevé qu'après avoir observé**, jamais en préparant la séance. Un relevé écrit
   d'avance est un mensonge daté.
2. **Ce qui n'a pas été observé se dit.** Un GO partiel s'écrit avec son périmètre (« NEW/ACK
   tracés des deux côtés ; NACK pas rejoué »), sinon le registre promet plus que la séance.

Pour un commit isolé éprouvé hors séance, on peut aussi porter le trailer `Verified-In-Game:
AAAA-MM-JJ` sur le commit lui-même — `untested.ps1` le reconnaît. Les commits de type `docs:`,
`test:`, `chore:`, `ci:`, `build:` et `style:` sont hors périmètre : ils ne changent rien dans le
client.

## Relevés

- 2026-09-30 17:25 — jusqu'a e09e4f0 — Forever, 2 comptes, build `main-dev@dea9e9d 2026-09-30 16:37`
  avec icone-commande-recue, liste-destinataires, profit-arbitrages, valeurs-secretes-canal (copie
  déployée du `.toc`, `Directory_Club` gardé relu dedans), Rédemption en donjon — **le déclencheur est
  le COMBAT DE BOSS** ; **GO à nouveau sur les lignes secrètes ; présence et cercles sans erreur mais
  SANS témoin** — relu par l'agent dans `DevMacroDB.log`, `!BugGrabber.lua` et les traces : sonde
  (`/dm 1`) à 16:41:02 en combat de trash : combat=2, carte=2, boss=0, chat=0, verrou false ; à
  17:21:15 sur un boss : combat=2, **boss=2, chat=2**, carte=2, `InChatMessagingLockdown()` = **true**.
  17:21:21 Gnomi envoie `CLNK1 x` ; 17:21:22 COCMonitor lève dessus (`author` secret) chez Rédemption,
  rien de `CraftLink_*` ni de COC. 17:21:34 Gnomi se déconnecte (sauvegarde) pendant que Rédemption
  est encore verrouillé (ses envois refusés 17:21:35-46, `verrouillage d'instance`) : aucune erreur
  de présence, et aucune `Directory_Club.lua:163` alors que Gnomi est membre du cercle `23004771`,
  celui qui levait ; Gnomi garde `source="circle"`, `circle="23004771"` dans la sauvegarde de
  17:21:57. **Pas prouvé** : que `CHAT_MSG_CHANNEL_LEAVE` et l'événement de club sont bien arrivés
  pendant le verrou (aucun lecteur témoin sur ces chemins, rien de tracé) ; le retour de Gnomi
  (`_JOIN`) ; `17 1` en jeu. Hors sujet vus au passage : `SelectRecipe` (Auctionator, ×260) et
  `AceBucket` de Questie sur une clé secrète.

- 2026-09-30 16:30 — jusqu'a f677875 — Forever, 2 comptes, même build `main-dev@7a5139d 2026-09-30
  15:38` que le relevé de 16:15, Rédemption en donjon (le déclencheur exact du verrou, boss ou non,
  n'a pas été relevé) — **GO sur les lignes de canal SECRÈTES (chemin texte), avec témoin dans le même
  événement** — `!BugGrabber.lua` et traces relus par l'agent après `/reload` des deux comptes : à
  16:27:42 un chuchotement d'addon de Rédemption est refusé (`verrouillage d'instance : message
  perdu`, AddOnMessageLockdown) ; à 16:27:49 Gnomi envoie `CLNK1 x` sur CraftLinkNet (canal 6,
  DevMacro) ; la même seconde, chez Rédemption, **COCMonitor** (outil local, non corrigé) lève
  `COCMonitor_Channel.lua:36: attempt to compare local 'author' (a secret string value…)` avec
  `chan="CraftLinkNet"`, `author=<secret string>`, `text=<secret string>` : la ligne est donc bien
  arrivée secrète à tous les lecteurs de `CHAT_MSG_CHANNEL`. Rien de `CraftLink_*` ni de
  `CraftingOrderClassic*` dans BugGrabber (l'ancien code levait en `Transport.lua:160`/`:396`, cf.
  2026-09-25), et la trace de Rédemption ne note aucune balise reçue : la ligne est écartée sans
  bruit. Vu en passant : à 16:21:37, `C_ChatInfo.SendChatMessage` vers le canal lancé par un addon
  sur le compte verrouillé est BLOQUÉ (`ADDON_ACTION_BLOCKED`, `*** ForceTaint_Strong ***`).
  **Pas vu** : le chemin présence (`CHAT_MSG_CHANNEL_JOIN`/`_LEAVE` sous verrou, déconnexion de Gnomi
  pendant que Rédemption est verrouillé), ni `17 1` affiché en jeu, ni la sonde sous verrou.

- 2026-09-30 16:15 — jusqu'a f677875 — Forever, 2 comptes (Gnomi = #1, Rédemption = #4), build
  `main-dev@7a5139d 2026-09-30 15:38` avec icone-commande-recue, liste-destinataires,
  profit-arbitrages, valeurs-secretes-canal (copie déployée du `.toc` ; `TRANSPORT_REV = 17` et
  `CraftLink_Sender.lua` relus dans la copie déployée, `17 1` PAS relu en jeu) — **GO sur la salle
  hors donjon, NO-GO faute de chemin sur les valeurs secrètes** — traces des deux comptes relues par
  l'agent après `/reload` : salle rejointe (Rédemption idx 7 à 15:53:35, Gnomi idx 6 à 15:54:20) ;
  le bonjour de Gnomi part sur la salle en message d'addon et arrive chez Rédemption
  (`[recv] CHANNEL Gnomi Short : HI|SK…` à 15:54:25, puis 15:58:37 au « Poster »/refresh) ; aucune
  balise texte émise par les deux comptes (zéro `[send]` de balise), aucune ligne `CLNK1` dans le
  chat (vu par le user). La ligne témoin tapée à la main par Gnomi (`CLNK1 x`) arrive chez
  Rédemption à 16:00:17, lisible. **En donjon, le verrou du chat ne s'est pas levé** (sonde
  `C_RestrictedActions.GetAddOnRestrictionState(0..5)`, Rédemption) : hors combat carte=2, le reste 0,
  `InChatMessagingLockdown()` = false ; en combat contre des monstres, combat=2 et carte=2, chat=0,
  false. BugGrabber vide des deux côtés pour la séance (dernière erreur : 09:27 sur #4). Ce vide ne
  prouve donc RIEN sur le correctif : le texte n'est jamais arrivé secret. Le crash du 2026-09-25
  venait du Général des Cavernes des lamentations ; reste à lever le verrou (boss = restriction 1,
  ou JcJ = 3), puis le témoin REV 16.

- 2026-09-30 14:35 — jusqu'a 2ee1c10 — Forever, un client, en ANGLAIS, rechargé après le déploiement
  de 14:00 : build `main-dev@bb269de 2026-09-30 14:00` (copie déployée du `.toc` ; la phrase neuve
  n'existe que dans ce build) — **GO sur l'Aide en jeu de `feat/canaux-aide` (`2ee1c10`)** — capture
  du user, relue par l'agent : section « Network, privacy & statuses », deuxième ligne : « Crafters
  find each other through your friends and your guild, and through the channels you tick in the
  Artisans tab, under "Watched channels": Trade, the discovery room, your communities, the players
  around you. The "Setup" button there reopens the first-launch panel. » Plus aucune mention de
  `/co channel room`. Avec le relevé de 14:10 (groupe « COMMUNITIES »), les deux changements de la
  branche sont vus.

- 2026-09-30 14:25 — jusqu'a 95eeb93 — Forever, client de Rédemption, en ANGLAIS, en ville, toujours
  PAS rechargé depuis 14:00 (groupe « DIRECTORY », et l'Aide montre encore l'ancienne phrase « …
  through the discovery room (/co channel room) … ») : build `main-dev@8098928 2026-09-30 13:27`,
  déduit, non relu par `/co version` — **GO sur le bouton « Setup » de la refonte (`95eeb93`) et,
  enfin sur capture, sur la mise en page du panneau de première connexion (`3e973ea`)** — capture du
  user, relue par l'agent : le clic sur « Setup » ouvre « Where to look for crafters? » par-dessus
  l'onglet ; la phrase d'introduction ; les quatre groupes, chacun avec son explication et ses cases
  sur deux colonnes (« Trade (Services) », « Trade », « Trade (Local) », « Guild » cochées,
  « General » décochée ; « CraftLinkNet » cochée, « room » ; « eaze » cochée ; « Say and yell » et
  « Crafters nearby » cochées, « in town ») ; le filet, la case « Also announce my orders and my
  availability in Trade (Services) » cochée et sa ligne d'explication ; « Confirm » en bas à
  droite. La fenêtre a la hauteur de son contenu, rien n'est coupé.
  Non vu : les deux changements de `feat/canaux-aide` SUR CE CLIENT (il faut un `/reload`) ; la
  phrase neuve de l'Aide n'est donc toujours vue nulle part.

- 2026-09-30 14:15 — jusqu'a 95eeb93 — Forever, client de Rédemption, en ANGLAIS, en ville ; build
  NON relu par `/co version` : ce client n'a pas été rechargé depuis le déploiement de 14:00 (ses
  SavedVariables datent de 12:36, et le groupe des communautés s'y intitule encore « DIRECTORY »),
  il tourne donc sur `main-dev@8098928 2026-09-30 13:27`, la refonte sans `feat/canaux-aide` — **GO
  sur ce qui manquait à la refonte de l'onglet Artisans (`95eeb93`) : un joueur EN LIGNE** — capture
  du user, relue par l'agent : « Gnomi Short », pastille verte, nom BLANC, « Whisper » ROUGE, et
  l'étiquette « eaze » (le nom de sa communauté, plus « CIRCLE ») ; les onze autres hors ligne, nom
  gris, « Whisper » gris ; « Syrine Lythaniel » sans préfixe « [Partner] », icône partenaire
  allumée, étiquette « FRIEND » ; bandes « All 29 », « Guild 0 », « Friends 2 », « Met 26 »,
  « eaze 1 » ; la liste des canaux tient entière sous cinq bandes. Pied : « 1 online · 40
  crafter(s) » contre « All 29 » (constat 5 de la revue, toujours là).
  Non vu : le clic sur « Setup », la phrase neuve de l'Aide.

- 2026-09-30 14:10 — jusqu'a 2ee1c10 — Forever, un client, client en ANGLAIS, en ville (un autre
  personnage du user : Rédemption figure dans sa liste) ; build déployé `main-dev@bb269de 2026-09-30
  14:00`, branches en test `feat/canaux-aide`, `feat/refonte-artisans`, `feat/icone-commande-recue`,
  `feat/liste-destinataires`, `feat/profit-arbitrages` (relu dans la copie déployée du `.toc`) —
  **GO partiel sur la refonte de l'onglet Artisans (`95eeb93`) et sur le groupe « COMMUNAUTÉS »
  (`2ee1c10`)** — deux captures du user, relues par l'agent. Onglet Artisans : bandes SOURCE « All
  23 », « Guild 0 », « Friends 1 », « Met 22 » (plus de « Directory », « Added » absent à 0) ;
  « Muted 0 » descendu au-dessus de « ADD A PLAYER » ; « Refresh directory » dans la barre du bas ;
  en-tête « WATCHED CHANNELS » avec le bouton rouge « Setup » ; la liste des canaux tient ENTIÈRE
  sans défiler (13 lignes), groupes « ANNOUNCEMENTS READ », « ADDON NETWORK », « COMMUNITIES » (le
  nouveau nom), « AROUND ME » ; les trois canaux de Commerce actifs et cochés (en ville), « Guild »
  grisée, « eaze » décochée, « Crafters nearby » cochée avec « in town ». Liste : douze joueurs
  tous hors ligne, « Whisper » GRIS sur chacun, icônes de métier en couleur, sous-ligne « Offline »
  ou « lvl N · N delivered », aucune étiquette « MET ».
  Non vu : la phrase neuve de l'Aide (la capture de l'Aide s'arrête avant la section « Network,
  privacy & statuses ») ; un joueur EN LIGNE (« Whisper » rouge, nom blanc) ; un partenaire sans
  préfixe ; l'étiquette au nom de la communauté ; le clic sur « Setup ». Vu en passant : le pied dit
  « 24 crafter(s) », la bande « All » 23 (constat 5 de la revue de design, toujours là).

- 2026-09-30 12:06 — jusqu'a 3e973ea — Forever, deux clients (Rédemption, Gnomi), client en ANGLAIS ;
  build déployé `main-dev@837aa32 2026-09-30 12:02` (relu dans la copie déployée du `.toc`) — **GO
  sur le panneau de première connexion (spec canaux-surveilles, palier 5, critères 6 et 7)** —
  rapporté par le user SANS capture (« tout fonctionne comme tu as décrit », sur la fiche donnée :
  ouverture seule ~10 s après le `/reload`, quatre groupes et leurs cases, la case « Annoncer », les
  clics qui agissent, fermeture par « Confirm » sur un compte et par la croix ou Échap sur l'autre,
  pas de retour après un second `/reload`). Relu par l'agent dans les SavedVariables des deux comptes
  (écrites à 12:06) : `setupSeen = "1.40.0"` des deux côtés ; chez Gnomi `watch = { trade_services =
  true, general = true }`, donc une case cochée DANS le panneau s'est bien écrite ; `roomOff` absent
  des deux côtés (la salle a été rallumée).
  Non vu par l'agent : la mise en page du panneau (aucune capture), un client français, allemand ou
  espagnol, l'ouverture différée par un combat ou une instance.

- 2026-09-30 11:40 — jusqu'a 15c7a02 — Forever, client en ANGLAIS, même build `main-dev@5e90b86
  2026-09-30 11:17` — **GO sur une communauté cochée dont les membres entrent dans l'annuaire (spec
  canaux-surveilles, critère 5)** — capture du user, après avoir fait entrer Gnomi dans sa communauté
  de test « eaze » et coché sa ligne : une bande « eaze », compteur 1, est née dans SOURCE ;
  sélectionnée, elle liste « Gnomi Short — Online · lvl 2 », étiquette « CIRCLE ». La liste des
  canaux commence sous cette septième bande, plus courte, et défile toujours (« Trade (Services) »,
  « Trade », « Trade (Local) » grisés « in town », « Guild » cochée, « CraftLinkNet » décochée,
  « eaze » cochée). Non vu : plusieurs communautés cochées (une seule suivie en présence).

- 2026-09-30 11:25 — jusqu'a 15c7a02 — Forever, un client (Rédemption), client en ANGLAIS ; build
  déployé `main-dev@5e90b86 2026-09-30 11:17`, branches en test `feat/canaux-surveilles`,
  `feat/icone-commande-recue`, `feat/liste-destinataires`, `feat/profit-arbitrages` (relu dans la
  copie déployée du `.toc`) — **GO sur la section « Canaux surveillés » de l'onglet Artisans (spec
  canaux-surveilles, palier 3, critères 1 et 2)** — capture du user, prise HORS capitale (le chat
  montre « Left Channel: Trade (Services) ») : la section « WATCHED CHANNELS » sous la bande
  « Muted » ; « Trade » et « Trade (Local) » grisés, cochés, avec « in town » ; « General » actif,
  décoché ; « Guild » cochée ; « ADDON NETWORK » : « CraftLinkNet », décochée (la salle est coupée),
  « room » ; « DIRECTORY » : « eaze », la communauté que le user vient de créer, décochée ; « AROUND
  ME » : « Say and yell » cochée, « Crafters nearby » décochée, « in town ». La barre fine est là
  et la liste a défilé (le premier en-tête et « Trade (Services) » sont au-dessus). Le bloc du bas
  (« Refresh directory », « ADD A PLAYER », le champ) sans chevauchement. Un canal perso rejoint
  pendant l'essai (« 6. azeaz ») n'a pas de ligne, comme prévu avant le palier 4.
  Rapporté par le user (« tout est ok », sur la fiche donnée) sans capture : la vue en capitale, les
  clics, `/co watch general on` et `/co crafters on` onglet ouvert, les infobulles.
  Non vu : une communauté COCHÉE dont les membres entrent dans l'annuaire (critère 5 : « eaze » n'a
  qu'un membre), la liste avec des bandes de cercles, un client français, allemand ou espagnol.

- 2026-09-30 11:02 — jusqu'a 86c6f16 — Forever, deux clients, même build `main-dev@507b82e 2026-09-30
  10:35`, salle toujours coupée, comptes « oubliés » — **GO sur la seconde moitié du critère 3 de la
  spec canaux-surveilles : la case recochée laisse de nouveau entrer la ligne** — traces des deux
  comptes relues par l'agent : `watch = { trade_services = true }` chez Gnomi ; Rédemption annonce
  `#12` à 11:02:15 et ne la chuchote qu'à Frostrobb Robb ; chez Gnomi, « post de Rédemption Wafhien :
  1/5 en 60s » et « annonce …-12 : bonjour » à 11:02:16, `HI` chuchoté dans la même seconde,
  `ORD|NEW|…-12` reçu de Rédemption à 11:02:17. L'alerte à l'écran n'est pas rapportée par le user.
  Non vu, inchangé : les lignes LFW, la guilde, General, dire et crier.

- 2026-09-30 10:56 — jusqu'a 86c6f16 — Forever, deux clients (Rédemption, Gnomi), client en ANGLAIS,
  Ironforge ; build déployé `main-dev@507b82e 2026-09-30 10:35`, branches en test
  `feat/canaux-surveilles`, `feat/icone-commande-recue`, `feat/liste-destinataires`,
  `feat/profit-arbitrages` (relu dans la copie déployée du `.toc`) — **GO partiel sur les canaux
  surveillés, paliers 1 et 2 (spec canaux-surveilles, critère 3, première moitié)** — traces des
  deux comptes relues par l'agent, captures du user. `/co watch` liste les cases (user). Sur Gnomi,
  `/co watch trade_services off` : `watch = { trade_services = false }` dans sa SavedVariable. Premier
  essai (10:53, salle restée ouverte) : aucune ligne « annonce …-10 » chez Gnomi, mais la balise
  `CLNK1` de Rédemption reçue par la salle (10:53:14), un bonjour, et la commande `#10` par
  chuchotement (alerte « new order ») — la case ne ferme qu'UN canal. Second essai, salle coupée par
  `/co watch room off` sur les deux comptes (Gnomi : « canal quitté (opt-out) » à 10:55:16, `roomOff`
  posé des deux côtés) et comptes « oubliés » : `#11` annoncée à 10:56:44, chuchotée au seul Frostrobb
  Robb ; chez Gnomi, **rien** jusqu'à son `/reload` (ni « annonce …-11 », ni `ORD|NEW`, ni bonjour ;
  « rien » confirmé par le user). Après ce `/reload`, `#11` lui arrive RELAYÉE par Frostrobb Robb
  (10:57:20, alerte « new order ») : le relais du réseau, pas la case. Au login de 10:57, Rédemption
  salue tout son annuaire sans Gnomi : l'oubli par `/run` tient après un `/reload`.
  Vu au passage : **`PROVIDE` enfin sur une ligne** — `WTB [Copper Bracers] x1 PROVIDE [Copper Bar]x2
  1s #CO11` (capture), le dernier « non vu » de l'annonce sur Commerce ; et **le bonjour différé de
  la salle (`52633c3`)** : salle rejointe à 09:24:17 (Gnomi) et 09:24:24 (Rédemption), `HI` sur la
  salle 2 s plus tard, reçu par l'autre compte par le canal (09:24:26), aucun « InvalidChannel ».
  Non vu : la case recochée qui laisse de nouveau entrer la ligne (seconde moitié du critère 3), les
  lignes LFW (canal décoché, dire et crier), la guilde, General coché, `CraftLinkNet` qui quitte la
  fenêtre Chat Channels (pas rapporté). Le prix s'affiche toujours « 1pa » / « 50po » sur le client
  anglais. Le repère couvre aussi `7089beb` (l'addon sans sa lib CraftLink) : l'addon se charge et
  tourne normalement avec ce commit, mais sa ligne d'avertissement n'a JAMAIS été vue (il faudrait
  casser la lib exprès) ; ce cas ne repose que sur `tests/test_craftlink_absent.lua`.

- 2026-09-30 08:48 — jusqu'a 8fd4cb9 — Forever, deux clients (Rédemption, Gnomi), client en ANGLAIS ;
  même build `main-dev@e61e34d 2026-09-30 00:58` (v1.40.0) — **GO sur la relecture du protocole côté
  réception (`352c1b7`) et sur l'Aide (`97ab48b`), GO partiel sur l'annonce** — traces des deux
  comptes relues par l'agent, captures du user. (A) comptes « oubliés » par `/run`, Rédemption poste
  `#7` à tous, case cochée : `WTB [Rough Sharpening Stone] x1 2g50s #CO7` sur Trade (Services) (08:34:03,
  capture) ; chez Gnomi, « post de Rédemption Wafhien : 1/5 en 60s » et « annonce …-7 : bonjour »
  (08:34:03), le bonjour chuchoté à +2 s (08:34:05, dans la fenêtre 0-5 s), `ORD|NEW|…-7` reçu à
  08:34:05 puis 08:34:10 sans second décompte anti-spam, une seule alerte (user). (B) juste après,
  clic droit sur `#7` dans le Carnet : désactivé, rien ne s'affiche (user) — conforme au code
  (`CanRemind` faux pendant 15 min), le texte « already announced … N min » n'est JAMAIS atteint
  depuis le Carnet. Le rappel lui-même marche : `#6` (de la veille) ré-annoncée au clic droit à
  08:26:30 (trace). (C) hors ville, plus d'une minute après : « no Trade (Services) channel here: you
  need to be in a capital city. » (capture), `#8` arrivée chez Gnomi par chuchotement (08:39:50) ; la
  case n'est pas grisée (la spec le prévoyait). (D) comptes en contact, `#9` à tous en ville : ligne à
  08:48:02, `ORD|NEW` reçu par Gnomi dans la même seconde, **aucun `HI` renvoyé** (le bonjour se tait),
  un seul décompte anti-spam. Non vu : `PROVIDE` (les commandes `#7` et `#9` portent `provided = {}`),
  l'aperçu écarté qui ne sonne plus (pas rejoué), `#CO0005` = `#CO5` (couvert par test).
  En marge : Gnomi renvoie un profil `SK`+`RI` inchangé à tous ses pairs toutes les 5 à 40 s ; le
  prix s'affiche « 2po 50pa » dans l'alerte d'un client anglais (antérieur à la v1.40.0).

- 2026-09-30 08:14 — jusqu'a 7e8057e — Forever, un client (Rédemption), client en ANGLAIS, en ville ;
  build déployé `main-dev@e61e34d 2026-09-30 00:58`, branches en test `feat/icone-commande-recue`,
  `feat/profit-arbitrages` (relu dans la copie déployée du `.toc`), = v1.40.0 — **GO sur la dispo
  qui ne part plus d'un événement de chat (`7e8057e`) et sur l'Aide sans communauté (`97ab48b`,
  `22bb22e`)** — trace de Rédemption relue par l'agent : fenêtre de métier ouverte (08:14:38), bouton
  de dispo, UN seul envoi à 08:14:57 (`LFW|on|Cooking` + « dispo Cooking annoncée sur Trade
  (Services) - English ») ; capture du user : « availability announced… », l'écho `LFW Cooking #CO`,
  et aucun « wait » après ce premier geste. Le user a tapé `/co lfw Cooking` ~2 s plus tard
  (confirmé par lui) : « looking for work » puis « one announcement per minute at most: wait 58
  more s. », le refus attendu du délai commun. Capture de l'Aide, section « Network, privacy &
  statuses » : pas de canal, amis/guilde/cercles, salle de découverte, annonces sur Trade ; aucune
  mention de la communauté. Trace, 08:11:20 : « lien de la communauté non proposé : aucune
  communauté officielle pour ce camp ». Le repère s'arrête à `7e8057e` : l'Aide (`97ab48b`) vient
  après `352c1b7` (relecture du protocole, côté réception), qui n'est PAS vu.

- 2026-09-30 00:31 — jusqu'a c126c37 — Forever, deux clients, client en ANGLAIS, en ville ; build
  déployé `main-dev@ed6a410 2026-09-30 00:26` (relu dans la copie déployée du `.toc`), les deux comptes
  à nouveau « oubliés » l'un de l'autre après le /reload (00:28) — **GO sur l'annonce de la dispo LFW
  (spec annonce-commerce, critère 13) et sur trois points du palier 2** — le user rapporte que chaque
  étape du protocole s'est passée comme attendu ; traces des deux comptes relues par l'agent : témoin
  case décochée, `LFW|on|Cooking` parti vers Osrik Stonefist seul, aucune ligne sur Commerce, rien chez
  Gnomi (00:30:22) ; case cochée, `/co lfw off` puis `/co lfw Cooking` : « dispo Cooking annoncée sur
  Trade (Services) - English » (00:31:06) ; chez Gnomi, « LFW de Rédemption Wafhien (Cooking) :
  bonjour » et son bonjour chuchoté (00:31:07), profil de Rédemption en retour puis
  `LFW|on|Cooking` reçu (00:31:10) — Rédemption vu en « [Dispo] » dans l'onglet Artisans (user).
  Rapportés par le user, sans trace possible (messages de chat) : la case du panneau « Offre » déjà
  cochée après le `/reload` (choix retenu, partagé avec le formulaire), et une commande postée dans la
  minute refusée avec « attends encore … s » (délai commun commande/dispo).
  Non vu : le texte du clic droit du Carnet, la case hors d'une capitale, une ligne à matériaux et prix.

- 2026-09-30 00:19 — jusqu'a a52c52b — Forever, deux clients, client en ANGLAIS, en ville ; build
  déployé `main-dev@325fc89 2026-09-30 00:13` (relu dans la copie déployée du `.toc`), salle coupée,
  les deux comptes « oubliés » l'un de l'autre par `/run` (`Directory.roster/online`) — **GO sur
  l'annonce en clair sur Commerce, envoi ET lecture (spec annonce-commerce, critère 11)** — captures
  du user et traces des deux comptes relues par l'agent : témoin `#5` posté SANS la case, parti vers
  deux inconnus seulement (Prudence Gylwynn, Osrik Stonefist), jamais vers Gnomi, puis annulé ;
  `#6` posté AVEC la case : `WTB [Rough Sharpening Stone] x1 #CO6` sur « 4. Trade (Services) -
  English » (capture), trace « annonce Rédemption Wafhien-6 sur Trade (Services) - English » (00:19:05) ;
  chez Gnomi, dans la même seconde, « annonce Rédemption Wafhien-6 : bonjour à Rédemption Wafhien » et
  l'alerte « incoming Rédemption Wafhien (trade): Rough Sharpening Stone » (capture) ; le bonjour de
  Gnomi reçu par Rédemption, qui lui pousse aussitôt `ORD|NEW|…-6` (00:19:05), reçu à 00:19:06 ; dans
  la SavedVariable de Gnomi, plus aucune entrante pour `-6` et la commande marquée `alerted` (une seule
  alerte, aucune « new order » à l'écran) ; vue métier Forge : `-6` acceptable, à côté de `-4` (un
  essai antérieur), pas de doublon. Avant l'oubli, le clic droit du Carnet a annoncé `-4` (00:16:38)
  et Gnomi, qui l'avait déjà, a tracé « commande déjà reçue, rien à faire ».
  Non vu (pas rapporté) : le refus d'une 2e annonce dans la minute, le texte du clic droit « déjà
  annoncée … », la case retenue après `/reload`, la case grisée hors ville, une ligne à matériaux
  (`PROVIDE`) et à prix. Piège du banc : sans l'oubli, la reconnexion relie les deux comptes
  (`RediscoverKnown`) et la commande arrive par chuchotement avant la ligne (premier essai, 00:05).

- 2026-09-29 22:46 — jusqu'a 52633c3 — Forever, client en ANGLAIS ; build déployé `main-dev@aaeb644
  2026-09-29 22:37` — **GO sur le bonjour différé et sur l'addon sans communauté** — trace de Gnomi
  relue par l'agent : connexion complète, garde anti-/1 qui attend un canal par défaut (22:44:41-44),
  « lien de la communauté non proposé : aucune communauté officielle pour ce camp » (22:44:56 ; le user
  confirme : aucun chuchotement de communauté), salle rejointe puis bonjour 2 à 3 s après, sans refus,
  y compris aux re-joins (22:45:53, 22:46:02, 22:46:12).

- 2026-09-29 22:35 — jusqu'a 3d4c113 — Forever, deux clients, client en ANGLAIS, Ironforge ; build
  déployé `main-dev@084954c 2026-09-29 22:30` (relu dans la copie déployée du `.toc`), communauté
  officielle coupée (`fix/sans-communaute`) — **GO sur la salle de découverte et le PING retiré** —
  traces des deux comptes relues par l'agent : salle rejointe (idx 6 et 7), `HI|SK…` de Rédemption sur
  la salle reçu par Gnomi, bonjour de Gnomi reçu par Rédemption qui répond à Gnomi SEUL
  (`whisper→Gnomi Short : HI|SK…`). **Un inconnu découvert par la salle** : Prudence Gylwynn (client
  d'avant la v1.37, qui porte encore ses données sur CraftLinkNet), profils échangés en whisper avec
  les deux comptes, commande Silverleaf de Rédemption poussée vers elle, puis relayée par elle à Gnomi.
  Aucune ligne « yell » dans les deux traces.
  NO-GO : après `/co channel room off` puis `on`, le bonjour parti dans la seconde du re-join est
  refusé (« refusé par le jeu (InvalidChannel) », la trace neuve de `fix/ping-crie`) → corrigé en
  `52633c3` (bonjour différé de 2 s), pas revu.
  Non vu (pas rapporté par le user) : la ligne d'explication unique, la ligne de `/co status`, /1 resté
  Général, l'absence du lien de communauté à une connexion complète, le message de `/co refresh`.
  Vu en passant : une balise texte `CLNK1` part sur la salle au `/co refresh` (le canal a de nouveau un
  index) — utile aux clients d'avant la v1.37, masquée du chat de ceux qui ont l'addon ; laissée.

- 2026-09-29 16:10 — jusqu'a a3ba24b — Forever, deux clients, client en ANGLAIS ; build déployé
  `main-dev@f2e653a 2026-09-29 15:35` (`/co version` pas relu par l'agent ; la ligne de trace
  « butin à la boîte aux lettres » n'existe que dans ce build) — **GO sur le témoin inverse de
  l'hôtel des ventes** — traces et SavedVariables des deux comptes relues par l'agent (écrites à
  16:10:37 et 16:10:40) : commande Silverleaf `Gnomi Short-27`, ACK puis DLV de Rédemption à
  16:10:07 et 16:10:09 (« Mark delivered », rien d'envoyé). À 16:10:27, Gnomi prend un Silverleaf
  acheté à l'HdV : le crochet lit l'expéditeur « Alliance Auction House » et ne confirme rien. À
  16:10:28, le message de butin arrive et il est écarté (« laissé au crochet du courrier ») : c'est
  maintenant VU, plus seulement déduit. Aucun `ORD|DONE` ne part, et la -27 reste `delivered` chez
  les deux comptes.
  Relevé en passant : à 15:47:01, Gnomi n'avait pas été rechargé depuis 15:28 et tournait sur
  l'ancien build. Le défaut s'y est reproduit à l'identique (commande -26 confirmée dans la seconde
  de la prise).
  Non vu : la confirmation par un courrier de l'artisan (le courrier entre les deux comptes ne livre
  toujours rien) ; le délai de 5 s après la fermeture de la boîte.
- 2026-09-29 15:28 — jusqu'a 66505eb — Forever, deux clients, client en ANGLAIS ; build déployé
  `main-dev@d17eba1 2026-09-29 15:14` (`/co version` pas relu) — **NO-GO sur le témoin inverse de
  l'hôtel des ventes** — trace de Gnomi relue par l'agent (SavedVariable écrite à 15:28:25) : commande
  Silverleaf `Gnomi Short-25`, ACK puis DLV de Rédemption à 15:28:03 et 15:28:04 (« Mark delivered »,
  rien d'envoyé). À 15:28:11, Gnomi prend un Silverleaf acheté à l'HdV : le crochet du courrier est
  appelé, l'expéditeur est lu « Alliance Auction House », l'objet 765 est lu en direct, et le crochet
  répond « aucune commande remise par cet expéditeur » : le filtre par expéditeur tient. À 15:28:12,
  `ORD|DONE` de la -25 part quand même (le user rapporte « commande completed »). Le seul autre chemin
  automatique vers `TryAutoComplete` est le message de butin (`_LootAlert`, sans expéditeur) : c'est
  DÉDUIT, pas tracé, car ce chemin n'avait pas de trace. Corrigé après ce relevé : le chat se tait à
  la boîte aux lettres, et une trace est posée. Pas revu en jeu.
  Non vu : le courrier entre les deux comptes, toujours.
- 2026-09-28 17:45 — jusqu'a f6e9826 — Forever, deux clients, client en ANGLAIS ; build déployé
  après la release : `main-dev@239fad7 2026-09-28 16:29` = v1.39.0 + `feat/icone-commande-recue`
  (`/co version` pas relu) — **GO sur les restes « non vus » de la v1.39.0** — rapporté par le user,
  deux captures : le bas de l'Aide « Order statuses: Pending » Accepted » Delivered (or Cancelled /
  Declined). » (le « ou » traduit) ; le Carnet de Gnomi, colonnes triables, sept commandes. Rapporté
  sans capture : la lueur de l'onglet Enchantement « fonctionne bien » ; « J'ai reçu » côté
  acheteur fonctionne ; barre fine de Profit, du réglage LFW et de la Route flottante, et fenêtre
  de métier fermée/rouverte en combat : « ça bug pas » ; Journal (Échap, détail, fiche en
  lecture) : OK.
  ÉCART : la commande envoyée par courrier reste « Delivered » chez l'acheteur. Lu dans le code : la
  confirmation automatique n'écoute que `CHAT_MSG_LOOT` (`_LootAlert.lua`), rien n'écoute la prise
  d'une pièce jointe — le courrier y est noté « point de branchement futur » ; l'en-tête de
  `_Companion_Mail.lua` promettait le contraire. Pas vu : si la pièce jointe avait été prise.
- 2026-09-28 21:20 — jusqu'a 4721828 — Forever, deux clients, client en ANGLAIS ; build déployé
  `main-dev@4864ed4 2026-09-28 21:03` (`/co version` pas relu) — **GO sur « Fill from order » qui ne
  joint plus que la quantité voulue** — Rédemption, commande ×1 de Lesser Magic Essence, une pile de 8
  au sac : la quantité est coupée DANS LE SAC vers une case vide, puis cette pile de 1 est jointe
  (rapporté par le user, capture du sac : la case coupée grisée, en pièce jointe). Trace « mail »
  relue par l'agent, essais d'AVANT : l'ancienne coupe directe joignait la pile ENTIÈRE (20:51 : 9
  pour 1 ; 20:55 : 8 pour 1, même avec un dépôt différé) ; la coupe dans le sac avec un délai FIXE de
  0,3 s trouvait la case encore vide (21:01 : « nil×nil »), rien de joint — d'où la relecture toutes
  les 0,1 s jusqu'à une pile exacte et déverrouillée.
  Non vu : la trace de cet essai-ci (pas encore écrite sur le disque) ; les replis « pas de case
  libre » et « case jamais prête » ; l'envoi et la réception de ce courrier.

- 2026-09-28 16:05 — jusqu'a eaa4ba7 — Forever, deux clients, client en ANGLAIS ; build déployé
  `main-dev@c43f9f9 2026-09-28 15:43` (`/co version` pas relu) — **GO sur le palier 7c : la colonne
  greffée à la barre fine, ÉPROUVÉE EN COMBAT** (risque 4 de la revue) — capture du user en combat
  (épées croisées, mob frappé) : la liste Commandes se met à jour pendant le combat (cinq commandes
  de Gnomi, la plus récente à 0 s), et le changement de vue refusé par la garde EXISTANTE de
  `_SetDockView` (« Not possible in combat », ×4 — voulu, antérieur au palier). Rapporté par le
  user : en combat, la vue Manquantes (choisie avant) défile normalement ; dans la Route, la case
  « inclure les plans à acheter » se coche et se décoche (la route se recalcule). Second passage
  en combat refait APRÈS `/console taintLog 1` et un `/reload` (rapporté par le user ; la config du
  client ne l'écrit qu'à la déconnexion, donc pas vérifiable sur disque) : `Logs\taint.log`, relu par
  l'agent à 16:05 et 16:15, reste daté du 2026-09-22 — au niveau 1 il n'écrit qu'à une action
  bloquée : aucune. Aucun « Interface action failed » rapporté. Seule erreur : `SelectRecipe`
  d'Auctionator à l'ouverture (connue, pas COC).
  Non vu : la barre fine elle-même sur capture, Profit et le réglage du LFW, la fenêtre Route
  flottante, fermer/rouvrir la fenêtre de métier en combat.

- 2026-09-28 15:40 — jusqu'a 2335752 — Forever, deux clients, client en ANGLAIS ; build déployé
  `main-dev@99fbb57 2026-09-28 15:33` (`/co version` pas relu ; au build précédent `0f9e9f2`, lu en
  jeu, les branches en test étaient `feat/echange-onglet-pulse, feat/icone-commande-recue`) — **GO
  sur la lueur de l'onglet Enchantement à l'échange** — rapporté par le user (« j'ai bien la
  lueur »), sans capture : une commande d'enchant de Gnomi acceptée par Rédemption, fenêtre de métier
  fermée, l'onglet collé à l'échange pulse. Au build précédent, sans commande acceptée : pas de
  lueur (voulu) et l'onglet au cadre doré « sélectionné » en permanence — corrigé par `2335752`.
  Non vu : l'onglet au repos sans son cadre doré (pas de capture après le correctif), le clic qui
  ouvre l'Enchantement, une commande acceptée PENDANT l'échange qui allume la lueur aussitôt.
- 2026-09-28 15:25 — jusqu'a 641c512 — Forever, deux clients, client en ANGLAIS ; build déployé
  `main-dev@373e8ef 2026-09-28 15:01` (`/co version` pas relu) — **GO sur l'envoi par le courrier,
  côté artisan** — rapporté par le user : la commande Silverleaf de Gnomi Short envoyée depuis le
  panneau du courrier (« Fill from order » puis Send), et sur le client de Gnomi l'annonce que la
  commande est en cours d'envoi — donc la remise posée à `MAIL_SEND_SUCCESS` et partie sur le
  réseau. Complète le relevé de 15:10.
  Non vu : la réception chez Gnomi (courrier entre deux comptes : une heure d'attente), la
  confirmation qui doit suivre quand il prend la pièce jointe ; le « ou » traduit de l'Aide (ligne des
  statuts hors de la capture).

- 2026-09-28 14:45 — jusqu'a ff52e07 — Forever, deux clients, client en ANGLAIS ; build déployé
  `main-dev@48e937c 2026-09-28 14:35` (sortie de `deploy.ps1` ; `/co version` pas relu sur ces
  captures), branches en test `fix/aide-a-jour, feat/ui-p7a-journal, feat/ui-p7b-greffons` et
  celles de l'autre session — **GO sur l'Aide remise à jour** — deux captures de l'onglet Aide : la
  flèche « » » rendue (« Order tab » pick… », statuts « Pending » Accepted » Delivered »), les onglets
  décrits sur le bord droit avec My Artisans, Help et What's New, la ligne `/co circle … nolink /
  link`, la section réseau en chuchotements + communauté « Crafting Order PVE », les cercles dans les
  sources de l'annuaire. Rapporté par le user : `/co help` fonctionne (seule la fin de la sortie est
  sur la capture). Voile « i » de Récolte : la bulle isolée sur la 1re ressource a disparu, la bulle
  de la liste couvre la liste. Vu en passant, ANTÉRIEUR : « (ou Cancelled / Declined) », le « ou »
  était écrit en dur en français — corrigé après ce relevé, pas vu.
  Non vu : les traductions allemande et espagnole ; les lignes `/co circle` et `/co channel` de
  `/co help` elles-mêmes.
- 2026-09-28 14:45 — jusqu'a 867c3f5 — Forever, un client, client en ANGLAIS ; build déployé
  `main-dev@acaf664 2026-09-28 14:24` (sortie de `deploy.ps1` ; `/co version` pas relu sur ces
  captures, mais le nouveau cadre n'existe qu'à partir de ce build), branches en test
  `fix/aide-a-jour, feat/ui-p7a-journal` et celles de l'autre session — **GO sur le palier 7a : le
  Journal et la fiche de quête dans le cadre de retail** — verdict du user (« c'est très bien pour le
  7a ») sur deux captures : le Journal (`/co journal`) en ButtonFrameTemplate, livre en médaillon,
  parchemin dans l'encart, liste par zone avec « (Complete) » à droite, barre de défilement cachée
  car tout tient ; la fiche « Poster en quête » avec le donneur en titre (« Anatarion Gifter »),
  le parchemin, le compteur 5/80 · 0/180, les objectifs, et Cancel / Post sur la barre du bas.
  Non vu : Échap sur le Journal, le détail d'une entrée sélectionnée, la fiche en lecture
  (`/co quest`), l'envoi par Post depuis la fiche.
- 2026-09-28 15:10 — jusqu'a 641c512 — Forever, deux clients, client en ANGLAIS ; build déployé
  `main-dev@373e8ef 2026-09-28 15:01` (`/co version` pas relu) — **GO sur le filtre du courrier** —
  capture du user (« tout est bon ») : avec une commande d'enchant ET une de Silverleaf acceptées pour
  Gnomi Short, le panneau du courrier ne liste plus que Silverleaf ; « Fill from order » a posé
  « To: Gnomi Short » et « Order: Silverleaf ×1 ».
  Non vu : la pièce jointe et l'envoi jusqu'à la remise (MAIL_SEND_SUCCESS).

- 2026-09-28 15:05 — jusqu'a c459c05 — Forever, deux clients (Rédemption enchanteur/herboriste,
  Gnomi acheteur), client en ANGLAIS ; build déployé `main-dev@712b91c 2026-09-28 14:54` ou
  `main-dev@48e937c 14:35` (`/co version` pas relu ; les deux portent `c459c05`) — **GO sur le
  palier 7b : les panneaux Échange et Courrier** — deux captures du user :
  ÉCHANGE, une fois la commande ACCEPTÉE (avant, aucun panneau : voulu, il ne liste que l'accepté
  ou le remis) : panneau sous la fenêtre d'échange, cadre DefaultPanelTemplate titré « Crafting
  Order », croix dans la barre de titre, « Orders for this player · Gnomi Short », la ligne Enchant
  Chest sélectionnée à l'atlas des recettes, « Accepted », « No agreed price. » et « Mark
  delivered ». Rapporté par le user : « j'ai été jusqu'au bout, ça fonctionne ».
  COURRIER : panneau à droite de Send Mail, « Orders to deliver · Gnomi Short », Silverleaf et
  Enchant Chest, « Fill from order » / « Mark delivered ».
  DÉFAUT vu, ANTÉRIEUR au palier : l'enchant listé au courrier, qui ne peut pas partir par la poste
  — corrigé après ce relevé, pas vu. Vu aussi : le panneau d'échange reste affiché après l'échange
  (persistance voulue, il y a encore des commandes à finir) et côtoie celui du courrier.
  Non vu : « J'ai reçu » côté acheteur sur le panneau d'échange ; « Fill from order » sur un objet
  jusqu'à l'envoi (pièce jointe, contre-remboursement, remise à MAIL_SEND_SUCCESS).

- 2026-09-28 13:51 — jusqu'a bd537da — Forever, un client, client en ANGLAIS ; build
  `main-dev@1371803 2026-09-28 13:45`, branches en test `feat/icone-commande-recue,
  feat/ui-p5-carnet-tri, feat/ui-p6-fonds` (lu dans la signature du `.toc` déployé) — **GO sur le
  palier 6 : les encarts de la fenêtre des métiers** — verdict du user (« oui ») sur cinq captures :
  Commande (liste en encart sombre, détail en encart sur le rocher, 2 px entre eux, filets fins),
  Artisans (sources et annuaire en encarts de liste, plus de barre sculptée), Carnet (le tableau et
  ses en-têtes dans un encart), Aide (la page dans un encart, barre fine). Premier essai du même
  palier REFUSÉ sur capture (`e1bf752`, l'atlas composé `Profession-Background-Template2` en fond de
  fenêtre : traits noirs, en-tête mal dessiné) et retiré par `bd537da`.
  Non vu : Mes artisans, Récolte, Nouveautés. Vu en passant, ANTÉRIEUR au palier : la flèche « → »
  de l'Aide rendue en carré (police sans ce glyphe), et un texte d'Aide périmé (« 4 onglets »,
  `/co channel`).

- 2026-09-28 13:22 — jusqu'a 5ef0cab — Forever, un client, client en ANGLAIS ; build
  `main-dev@c760357 2026-09-28 13:15`, branches en test `feat/icone-commande-recue,
  feat/ui-p5-carnet-tri` (lu dans la signature du `.toc` déployé) — **GO sur le palier 5 : le Carnet
  trie ses colonnes** — capture du user : les six en-têtes au gabarit `ColumnDisplayButtonShortTemplate`
  (ORDER, QTY, PRICE OFFERED, PROFESSION, CRAFTER, STATUS), la flèche `auctionhouse-ui-sortarrow` sur
  PRICE OFFERED en décroissant, trois commandes rangées 12po › 1po › sans prix ; survol d'une ligne
  avec « Click: Cancel » ; chiffre « 3 » sur l'onglet du Carnet. Rapporté par le user : l'annulation
  fonctionne (le Carnet sorti dans `_UI_Ledger.lua` garde ses actions).
  Non vu : le tri des autres colonnes, les filtres Archivées et Confiées depuis le déménagement.

- 2026-09-28 13:06 — jusqu'a 64bf8c3 — Forever, un client, client en ANGLAIS ; build
  `main-dev@12f3479 2026-09-28 12:51`, branches en test `feat/icone-commande-recue,
  feat/ui-p4-formulaire` (lu dans la signature du `.toc` déployé) — **GO sur le palier 4 : montant et
  quantité aux champs de Blizzard** — quatre captures du user (« j'ai tout testé ») : Commande, la
  commission en `LargeMoneyInputFrameTemplate` (trois cases à pièce, « 1 » or, « 50 » argent), la
  quantité au compteur `[-] 5 [+]`, le repère « AH value… Reagents… » lisible sous le champ ;
  Récolte, le prix au même champ et le compteur « 6 » à côté de « stacks » ; le Carnet reçoit les
  deux commandes, « Tasty Raptor Bites ×5 1po 50pa » et « Blindweed ×6 1po 50pa » : le format du
  prix envoyé (`Skin.PriceText`) est intact. Vu aussi, resté ouvert au relevé du palier 3 : le
  chiffre du Carnet sur l'icône de son onglet (« 1 »).
  Non vu : la tabulation or → argent → cuivre (rapportée testée, sans capture), le repli maison des
  deux champs (les gabarits existent, il n'a pas servi).

- 2026-09-28 12:40 — jusqu'a e7fc574 — Forever, un client, client en ANGLAIS ; même build que le
  relevé du palier 3 (`main-dev@bb4efc8`, `feat/ui-p2d-pages` parmi les branches en test) — **GO sur
  le lot 2d du palier 2** — capture du user (« tout est ok ») : la bourse d'un artisan (« Pouch —
  Syrine Lythaniel ») défile avec la `MinimalScrollBar`, fine et logée à droite, sur une page
  composée (en-têtes de métier, grilles de cases, notes). Le reste rapporté par le user, sans
  capture : l'Aide et les Nouveautés.
  Non vu : une bourse qui tient sans défiler (barre cachée d'elle-même).
- 2026-09-28 12:40 — jusqu'a a02815e — Forever, un client, client en ANGLAIS ; build
  `main-dev@bb4efc8 2026-09-28 12:35`, branches en test `feat/icone-commande-recue, feat/ui-p2d-pages,
  feat/ui-p3-onglets-lateraux` (lu dans la signature du `.toc` déployé) — **GO sur le palier 3 : les
  onglets latéraux** — capture du user (« tout est ok ») : les sept onglets au flanc droit, sous le
  coin haut-droit du cadre, toutes les icônes présentes (livre, parchemin, pioche, l'atlas
  `friends-icon-tab-friends` pour Artisans — l'atlas existe, le repli n'a pas servi —, l'icône
  `INV_SideTab_Professions_c60` pour Mes artisans, point d'interrogation, lettre) ; Artisans surligné
  (art de sélection de Blizzard) ; titre « Crafting & Gathering Order — Artisans » ; le grand « i »
  libre à côté du portrait.
  Non vu : le chiffre du Carnet sur son icône (aucune commande active), l'infobulle d'un onglet.

- 2026-09-28 12:12 — jusqu'a 6ef2e8b — Forever, un client, client en ANGLAIS ; build
  `main-dev@6ef2e8b 2026-09-28 12:10`, branches en test `feat/ui-p2c-listes` (lu en jeu par
  `/co version`, capture ; même commit que le déploiement de 12:09, redéployé tel quel à 12:10:24
  par une autre session) — **GO sur le lot 2c du palier 2 et ses retouches** — première capture
  (`984ae25`) : liste de Récolte sur la liste moderne (barre d'en-tête « Trade Goods », sous-catégorie
  « Herbs », +/- à droite, `MinimalScrollBar`), mais trois défauts : le « i » sous la bordure du cadre,
  une bande vide sous la recherche, une gouttière vide à droite de la barre → `6ef2e8b`. Seconde
  capture : le « i » entier par-dessus la bordure ; le Carnet (« Active ») vide dès l'ouverture
  affiche « No orders. Use the « Order » tab to post one. » (il restait muet avant) ; `/co version`
  affiche la version, le build et les branches en test (couvre `d206e2e`). Le reste rapporté par le
  user (« c'est tout good »), sans capture : Récolte sans bande ni gouttière, listes de Commande,
  Artisans et Mes artisans jusqu'au séparateur.
  Non vu : un Carnet avec des commandes (clic, survol), les filtres Archivées et Confiées, les
  pastilles d'extension d'« Élémentaire ».

- 2026-09-28 11:46 — jusqu'a d708cb1 — Forever, un client, client en ANGLAIS ; build
  `main-dev@98b333c 2026-09-28 11:36`, branches en test `feat/banc-main-dev, fix/ui-p2b-debordements`
  (lu dans la signature du `.toc` déployé ; `/co version` pas montré) — **GO sur les deux
  débordements du lot 2b**, premier build servi par le banc — deux captures du user : dans
  l'annuaire, « [Partner] Syrine Lytha… » tient sur une ligne, tronqué, sa sous-ligne intacte ; dans
  Mes artisans (Pêche), les porteurs « Rédemption, Sheadra… » tiennent sur une ligne, tronqués.
  Vu aussi : annuaire de 13 lignes avec sa barre, bande de cercle « CraftLinkNet » (v1.37).
  Non vu : l'affichage du build par `/co version`, le message de liste vide des sourdines.

- 2026-09-28 (15) — jusqu'a 5f7da55 — Forever, un client — **GO sur l'icône à 22 px** — capture du user
  (« c'est bien mieux ») : le logo « CO » lisible sous le nom de la zone, sans toucher la minicarte.
  PÉRIMÈTRE : la refonte en outil à plusieurs icônes qui suit (même méthode, même rendu) n'est pas revue.

- 2026-09-28 (14) — jusqu'a 530aa48 — Forever, un client, branche `feat/icone-minicarte-maj` — **GO sur
  l'icône « nouvelle version » de la barre de la minicarte** — capture + « oui c'est bon » du user après
  `NotePeerVersion` × 2 (9.9.9) : le logo « CO » sous le nom de la zone, à la place de la lettre, à
  côté du compartiment d'addons ; infobulle, clic, mode Édition et combat rapportés bons. `taint.log`
  inchangé depuis le 22/09 (ne prouve rien si `taintLog 1` n'était pas actif). Seul retour : l'icône
  est trop petite (16 px) → passée à 22 px après la séance, PAS revue.

- 2026-09-28 (13) — jusqu'a 6908c48 — Forever, **DEUX COMPTES** + un perso Horde, branche
  `feat/communaute-sans-canal` — **GO sur les corrections du relevé 12** — rapporté par le user
  (« c'est tout bon, j'ai fait tous les tests ») + capture d'Orcaa + trace de Gnomi (SV 10:54) :
  une bande de cercle au NOM de la communauté à la place de « Cercle », plus de « Confédération »
  (capture) ; Rédemption quitte le jeu → hors ligne chez Gnomi (rapporté) ; `/join CraftLinkNet` puis
  /reload → « canal CraftLinkNet encore présent → quitté » à 10:53:46 (12bis) ; Orcaa (Horde) a sa bande
  de cercle : sa seule communauté, 22973181, a donc bien été marquée d'office (clubId Horde confirmé).
  Défaut VU sur la capture d'Orcaa, corrigé après : Syrine (Alliance, relayée par Rédemption) visible
  sur ce perso Horde — la fiche relayée n'avait pas de camp. À noter : la communauté Horde s'appelle
  « CraftLinkNet » en jeu (bande d'Orcaa), le code annonce « Crafting Order PVE » dans le lien.
  PÉRIMÈTRE : le tampon de camp d'une fiche relayée n'est PAS vu en jeu (Syrine restera visible sur
  Orcaa jusqu'au prochain relais reçu par un perso Alliance) ; la copie « To » masquée PAS confirmée.

- 2026-09-28 (12) — jusqu'a 3c4470c — Forever, **DEUX COMPTES**, branche `feat/communaute-sans-canal`,
  canal coupé — **GO sur les commandes et le LFW sans canal, NO-GO sur la déconnexion** — rapporté par
  le user (« good pour la prise et annulation de commande + publique », « lfw c'est bon aussi », 3
  captures) et corroboré par la trace de Gnomi (SV écrite à 10:45) : `Gnomi Short-4` et `-5` postées
  puis annulées, NEW et CANCEL partis en whisper vers Rédemption ET Sorcerer Supremes (fanout) ; alerte
  « commande pour TOI » (nommée) et « nouvelle commande » (publique) chez Rédemption ; LFW Enchanting de
  Rédemption reçu (`LFW|on|Enchanting`) et badge vu au-dessus de lui chez Gnomi. **Déconnexion** :
  Rédemption quitte le jeu à 10:39:24, Gnomi le sonde à 10:39:27 (la présence du club a bien déclenché
  le balayage), AUCUN retour → il reste « en ligne » jusqu'à sa reconnexion à 10:42:26 ; corrigé après
  la séance (la présence du jeu fait foi). Vus aussi : whisper de rappel affiché en double (reçu +
  « To »), ligne « Confédération » visible sans GreenWall ni /co debug — corrigés après la séance.
  PÉRIMÈTRE : la correction de la déconnexion n'est PAS encore vue ; départ auto d'un CraftLinkNet resté
  (12bis) et clubId Horde toujours pas éprouvés.

- 2026-09-28 (11) — jusqu'a 3c4470c — Forever, **DEUX COMPTES**, branche `feat/communaute-sans-canal`
  (COC + CraftLink + outillage) — **GO sur le réseau sans canal et le rappel de la communauté** — tests
  menés par le user (captures + « ça passe »), corroborés par la trace de Gnomi (SV écrite à 10:29) :
  canal coupé, réseau déclaré prêt sans canal (« réseau SANS canal », 10:28:22) ; découverte par
  whisper des membres de la communauté, **Sorcerer Supremes (joueur extérieur) répond** SK/RI/CD, et
  Rédemption avec ses métiers + le relais de Syrine ; rappel de connexion (« lien de la communauté
  proposé », 10:28:34) reçu en **whisper à soi-même**, lien cliquable, invitation ouverte, adhésion
  faite ; perso Horde sans communauté connue → « non proposé : aucune communauté officielle pour ce
  camp » (10:15, avant l'ajout de la communauté Horde) ; popup d'info vue une fois par compte. Défauts
  VUS et corrigés en séance : lien jamais proposé à une reconnexion (attendait `INITIAL_CLUBS_LOADED`,
  `9d2cc7e`) ; bouton « Rejoindre » dans la popup → `ADDON_ACTION_FORBIDDEN GetLastTicketResponse()`
  (retiré, `5713feb`). Le chat de la communauté ajouté à la fenêtre (« [6. CLinkN] ») est Blizzard.
  PÉRIMÈTRE : message « marquée comme cercle » PAS vu (Gnomi gardait sa marque de la session d'avant,
  quitter par l'interface Blizzard ne la retire pas) ; clubId Horde 22973181 PAS confirmé (déduit du
  chat-cache d'Orcaa) ; commandes, annulation relayée, LFW, extinction d'un pair déconnecté (critères
  14 à 16) et départ auto d'un CraftLinkNet resté après /reload (12bis) PAS rejoués.

- 2026-09-28 09:57 — jusqu'a 4299dce (marqueur INCHANGÉ) — Forever, deux clients, client en ANGLAIS ;
  build = celui d'une AUTRE session (`feat/communaute-sans-canal` : `03176db` + travail non commité,
  repéré à `Directory_Community.lua` dans le dossier de l'addon), qui a écrasé le déploiement de
  `e784779` : le correctif des débordements n'était PAS dans le client — **GO sur « Unmute »** —
  rapporté par le user (« c'est bon pour unmute »). Captures : annuaire de 13 lignes, la
  `MinimalScrollBar` apparaît dès que la liste déborde ; icônes de métiers grisées sauf une par ligne
  (mise en avant de rentabilité, `_SetArtProfitBorder`, qui ne grise que si Auctionator répond) ;
  porteurs de Mes artisans encore sur deux lignes, attendu dans ce build.
  Non vu : le message de liste vide des sourdines, les deux débordements corrigés.

- 2026-09-28 09:50 — jusqu'a 4299dce (marqueur INCHANGÉ : `e784779`, rejoué depuis en `d708cb1`
  sur la v1.38.0, est dans le client, mais les lignes qu'il corrige ne sont pas à l'écran) — Forever, un client, client en ANGLAIS (build =
  `main` + `fix/ui-p2b-debordements`) — **GO sur la source « En sourdine » du lot 2b** — deux
  captures du user : en-tête « Muted players — no notifications from them. », une ligne sur la liste
  moderne (« Crux Vejovis », durée « permanent » en or, bouton « Unmute » à droite), compteur
  « Muted 1 » juste. À côté, l'infobulle de joueur (`_Social`, code inchangé par le lot) : ligne
  « CO-Classic », marque de l'addon, cinq métiers avec leurs rangs.
  Non vu : le clic sur « Unmute », le message de liste vide, les deux débordements corrigés.

- 2026-09-28 09:43 — jusqu'a 4299dce — Forever, un client, client en ANGLAIS (branche d'essai
  `test/ui-p2-essai` : `feat/ui-p2-listes` + `fix/manquantes-faction-et-bouton-aide` ; fichiers du
  client comparés à `4299dce`, identiques aux fins de ligne près) — **GO partiel sur le lot 2b du
  palier 2** — deux captures du user :
  onglet Artisans, source « All » (12) : 12 lignes sur la liste moderne (pastille, nom, sous-ligne
  état · niveau, icônes de métiers, source FRIEND / MET / CIRCLE, étoile de partenaire, Whisper),
  sans barre puisque tout tient ; Mes artisans : 8 métiers à gauche (porteurs tronqués par « … »),
  Pêche sélectionnée, et à droite ses recettes : en-tête de section, sous-catégorie, 19 lignes,
  `MinimalScrollBar` présente puisque la liste déborde.
  Deux défauts vus, ANTÉRIEURS au lot (même largeur fixe, retour à la ligne permis, dès `4299dce^`) :
  « [Partner] Syrine Lyrhaniel » passe sur deux lignes et recouvre sa sous-ligne ; les trois porteurs
  d'une recette passent sur deux lignes et mordent sur la recette suivante. Corrigés sur
  `fix/ui-p2b-debordements`, pas encore revus.
  Non vu : la source « En sourdine » et « Rétablir », les messages de liste vide, les infobulles, les
  clics (métier → Commande, Whisper, partenaire, clic droit sur un métier), le bas d'une liste qui
  déborde.

- 2026-09-27 (10) — jusqu'a c50f401 — Forever, un client (branche d'essai `test/ui-p2-essai` :
  `feat/ui-p2-listes` + `fix/manquantes-faction-et-bouton-aide`) — **GO sur le lot 2a du palier 2
  et sur la présélection d'artisan** — tests menés par le user, deux captures :
  réactifs du plan choisi (cocher, décocher, compteur « N / M fournis », remise à zéro au changement
  de plan) ; artisans de Commande sur la liste moderne, descendue jusqu'au statut (3 lignes vues en
  portée Annuaire, clic = surbrillance + destinataire) ; depuis l'onglet Artisans, un clic sur le
  métier de quelqu'un ouvre Commande sur sa ligne, surlignée (`a5c7467`) ; récolteurs de Récolte :
  d'abord figés à 4 lignes au-dessus d'un vide (défaut vu), puis, après `c50f401`, 6 lignes jusqu'au
  statut, sans barre puisque tout tient.
  Non vu : le repli des membres de CERCLE sous Annuaire (`a5c7467`, cas pas testé), le clic sur un
  récolteur, le défilement d'une liste d'artisans qui déborde.
- 2026-09-27 (9) — jusqu'a 2712afd — Forever, **DEUX COMPTES**, build = `main` candidat v1.36.2 —
  **GO sur la reprise des commandes d'avant le nom complet** (`AdoptFullNames`) — rapporté par le
  user (« c'est bon pour Gnomi, j'avais ses commandes d'avant ») et corroboré par la SavedVariable
  de Gnomi écrite à 20:23 : `Gnomi-1`, postée avant le correctif avec l'acheteur « Gnomi », porte
  désormais « Gnomi Short », et son statut est `cancelled` (le bouton Annuler a fonctionné dessus).
  Au `/reload`, une erreur Blizzard `SelectRecipe:466` (`SchematicForm:Init` nil) : c'est
  **Auctionator** (3e fois, cf. mémoire), disparue quand le user l'a coupé ; COC ne touche jamais
  `SchematicForm`. PÉRIMÈTRE : l'annonce ALT des rerolls (codec corrigé) n'est pas observée — la
  feature est opt-in et n'a jamais été éprouvée à 2 comptes ; chez Rédemption, `Gnomi-1` reste
  ouverte (limite de transition assumée : un pair garde l'acheteur au prénom jusqu'au TTL).

- 2026-09-27 (8) — jusqu'a 1a1347b — Forever, un client (build déployé : branche d'essai
  `test/ui-p1-essai`, soit `main` + palier 1 + les deux branches `fix/` du jour) — **GO sur le
  palier 1 de la revue d'UI** : la liste des plans de l'onglet Commande sur la liste défilante
  moderne (`Skin.MakeScrollList`). Vu sur capture du user : en-têtes de section sur la barre sombre
  des métiers, sous-catégories en bronze sans barre, « – » en atlas à droite (les deux atlas que la
  sonde n'avait pas vérifiés existent, le repli n'a pas servi), `MinimalScrollBar`, recherche
  « minor » qui filtre, comptes justes. Confirmé ensuite par le user (« tout fonctionne bien ») :
  repli et dépli sans remonter en haut, surbrillance de sélection, survol avec infobulle, dernière
  ligne atteignable à la molette.
  Non vu : la colonne de rentabilité (Auctionator), la silhouette d'enchantement qui masque la liste.

- 2026-09-27 (7) — jusqu'a ee4a2e2 — Forever, un client (Rédemption, enchanteur) — **GO sur les
  demandes niées du canal Commerce** — le parseur RÉEL (`Inbound:OnChat`) appelé par `/run` avec un
  lien de l'objet 11287, sans rien poster sur Commerce : « need [Lesser Magic Wand] pls » (Testeur)
  → popup d'alerte ; « dont need fire wand: [Lesser Magic Wand] » (Testeur Deux) → le user ne
  rapporte de popup que pour le 1er. Le client tournait la branche d'essai `b5ac0a0`, qui porte les
  deux correctifs avec le même code que `main` ; le marqueur pointe la fusion `ee4a2e2`, qui les
  réunit sur `main`. PÉRIMÈTRE : la ligne entre par l'injection, pas par un vrai `CHAT_MSG_CHANNEL`
  (le filtre de nom de canal trade/commerce n'est pas exercé) ; les autres négations (don't, no
  need, pas besoin) ne sont couvertes que par le banc headless.

- 2026-09-27 (6) — jusqu'a 361c409 — Forever, **DEUX COMPTES** (Gnomi Short ↔ Rédemption Wafhien),
  canal coupé des deux côtés (`/co channel off`), communauté « Crafting Order PVE » marquée par
  `/co circle` — **GO sur une commande nommée passée par la communauté** — rapporté par le user
  (« j'ai bien reçu ») : la commande nommée de Gnomi Short pour Rédemption Wafhien arrive chez
  Rédemption. Même séance, AVANT ce commit : la commande arrivait 2× par whisper puis tombait en
  « NEW ignoré : Gnomi Short ≠ acheteur en cache Gnomi » (noms de famille), et Gnomi voyait déjà
  Rédemption Wafhien sous *Circle*, en ligne, avec ses métiers (capture).
  PÉRIMÈTRE : seule la RÉCEPTION d'un NEW nommé est rapportée. Pas observé : ACK/DLV/DONE sur
  cette commande, un client resté en v1.36.1 (complétion de l'acheteur au prénom), le retrait de
  soi de l'annuaire, les rerolls (IsMyChar, ALT), le filtre d'écho du canal (canal coupé pendant
  la séance). Le client tournait la branche d'essai `b5ac0a0`, qui porte aussi
  `fix/commerce-negation` : non observé, et hors de l'ascendance de ce marqueur.

- 2026-09-27 (5) — jusqu'a a04c3a2 — Forever, client redémarré — **GO sur l'icône de la liste des
  addons** — confirmé par le user (« c'est bon pour les logos ») : le logo « CO » remplace le point
  d'interrogation devant « Crafting & Gathering Order - Classic ». Ce commit ne touche AUCUN code
  Lua : seulement `## IconTexture` dans le `.toc` et `Textures/icon.tga`.

- 2026-09-27 (4) — jusqu'a 1cb8e6a (marqueur INCHANGÉ) — Forever — **GO partiel sur le COMBAT** —
  rapporté par le user : testé en combat la veille (2026-09-26), aucun souci. La colonne greffée
  est PROTÉGÉE comme son hôte, et c'est le scénario qui inquiétait : `Show`, `Hide`, `SetPoint`,
  `SetWidth` y sont refusés en combat, et la bande LFW comme la page Profit s'affichent et se
  masquent selon le métier ouvert.
  ⚠️ **PÉRIMÈTRE, et il n'est pas cosmétique : « aucune erreur visible » n'est pas « aucune action
  refusée ».** Un `ADDON_ACTION_BLOCKED` peut passer SANS rien afficher ; seul `/console taintLog 1`
  puis la lecture de `Logs/taint.log` le prouve, et ce log n'a pas été relu. Le critère 4 de la spec
  reste donc à moitié ouvert : on sait que rien ne CASSE à l'écran en combat, on ne sait pas que
  rien n'est refusé en silence. À faire un jour de calme, pas avant une release.

- 2026-09-27 (3) — jusqu'a 1cb8e6a (marqueur INCHANGÉ) — Forever, un client — **GO sur le mode
  « Recettes » du sélecteur** — capture, métier Cooking 31/75. Ce relevé n'avance pas le marqueur :
  il **ferme un trou de périmètre nommé dans le relevé précédent**, il n'ajoute pas de couverture.

  Le bouton « Recettes » affiche la liste, et elle est juste sur les trois points qui comptent :
  l'en-tête dit « Offered recipes (0/12) » — donc le libellé **et** le plafond ont basculé, 12 étant
  celui des recettes et non les 15 des réactifs ; les six lignes (Basic Campfire, Brilliant
  Smallfish, Charred Wolf Meat, Herb Baked Egg, Roasted Boar Meat, Spiced Wolf Meat) sont
  **exactement** les six recettes de la liste native à gauche, ce qui confirme que l'univers est lu
  sur le CLIENT (`Craft:ReadRecipes`) et non dans notre catalogue ; chaque ligne porte son icône et
  sa case.

  PÉRIMÈTRE : c'est l'AFFICHAGE qui est vu. Cocher une recette, la voir persister après un
  `/reload` et arriver chez un autre joueur par le verbe `LFR` n'a pas été observé — la partie
  transport est couverte par le banc headless, pas par l'œil.

- 2026-09-27 (2) — jusqu'a 1cb8e6a — Forever, **DEUX COMPTES** — **GO sur la riposte LFW** —
  rapporté par le user : « ça fonctionne, je vois le LFW après le reload ». Le récepteur recharge
  pendant que l'autre compte est LFW, et le badge `[LFW]` revient **en quelques secondes** au lieu
  des 8 minutes du ticker. L'asymétrie est fermée : `Dir.lfw` est toujours RUNTIME et toujours vidé
  par un `/reload`, mais quelqu'un se ré-annonce désormais quand on arrive.
  **Conséquence pour le banc, à retenir** : un « pas de badge » juste après un `/reload` était
  jusqu'ici un faux négatif garanti. Il redevient une observation exploitable.

  ⚠️ **PÉRIMÈTRE — ce relevé porte le marqueur à `1cb8e6a`, donc il couvre aussi `57e7553` (le
  picker qui ne reste plus vide, cas Herbalism) qui N'A PAS été ré-observé.** Il était déployé
  pendant la séance, il n'a rien cassé de visible, mais personne n'a rouvert le sélecteur de
  réactifs d'un métier de récolte pour vérifier que le repli marche et que le message d'état
  s'affiche. À faire au prochain passage : ouvrir Herbalism → « Offre » → onglet Réactifs.

  Toujours jamais observé, indépendamment de ce relevé : le **détail d'OFFRE sur la plaque**
  (pièce / sac / nom de la 1re recette — il faut d'abord régler une offre), l'**anti-leurre AFK**
  (20 min d'attente réelle, sinon on ne l'écrit pas), et le **combat**.

- 2026-09-27 — jusqu'a 760119c — Forever, **DEUX COMPTES**, client en ANGLAIS — **GO sur l'étage
  RÉCEPTION de LFW et sur le métier de RÉCOLTE** — quatre captures du user. Premier relevé à deux
  comptes de LFW sur Forever : cette moitié n'avait **jamais** été vue fonctionner.

  ✅ **La plaque de nom.** Compte A (« Rédemption Wafhien », LFW actif) vu depuis le compte B
  (« Gnomi Short ») à Forgefer : une icône est posée au-dessus de sa plaque.
  ✅ **Le badge `[LFW]`** apparaît en vert devant son nom dans l'onglet Artisans du compte B,
  avec ses icônes de métier. Pied de fenêtre : « network channel joined · 3 online · 5 crafter(s) ».
  ✅ **Métier de RÉCOLTE** (Herbalism 70/75, arbitrage C) : la bande « Look for work » est bien là,
  avec son bouton « Offer », et le panneau d'offre s'ouvre. La bande n'est donc pas conditionnelle
  au type de métier.
  ✅ Le panneau s'ouvre **à gauche**, entièrement visible, au PREMIER clic, et la rangée de modes
  « Reagents / Recipes » y est — les trois correctifs faits au calcul sont confirmés d'un coup.

  ⚠️ **DÉFAUT VU, corrigé depuis** : sur Herbalism la liste des réactifs était **vide**, sans un
  mot. Le filtre « recettes connues » posé le 2026-09-26 ne repliait que si l'on n'avait RIEN pour
  filtrer ; là le client connaissait bien une recette (« Incense Candle ») mais notre catalogue
  n'a pas ses réactifs, donc le résultat sortait vide sans jamais replier. Le repli se déclenche
  désormais sur un RÉSULTAT vide, et le picker DIT quand il n'a rien à montrer.

  ❓ **L'infobulle monde sans bloc LFW — EXPLIQUÉ le 2026-09-27, ce n'est pas un défaut de code.**
  Sur la capture, le survol de « Rédemption Wafhien » affiche « CO-Classic » et ses cinq métiers,
  mais pas la ligne « Cherche du travail ». J'avais d'abord soupçonné une **clé de nom** qui
  diffère : **c'est faux**, l'infobulle et la plaque appellent le MÊME `Api.UnitNameSafe(unit)`.
  La vraie raison est que les deux données n'ont pas la même durée de vie :

  | | source | survit à un `/reload` ? |
  |---|---|---|
  | les métiers (`summary`) | `roster`, dans `COC.db` | **oui**, persisté |
  | le bloc LFW (`lfwE`) | `Dir.lfw` | **non**, RUNTIME par conception |

  Après un rechargement, le spectateur garde donc les métiers et perd les LFW — jusqu'à ce que
  l'émetteur ré-émette. Et **il n'existe aucune riposte** : `_BroadcastLFW` ne part qu'au
  changement d'offre, à `SetLFW`, sur le ticker de **8 minutes**, et sur le `OnNetworkReady` de
  l'ÉMETTEUR. D'où une asymétrie — celui qui recharge se ré-annonce tout de suite aux autres, mais
  reste aveugle aux leurs jusqu'à 8 min.

  C'est la même forme que le bug de découverte à sens unique déjà corrigé par une riposte throttlée
  dans `OnHello`/`OnPing`. À décider : appliquer le même remède à LFW (coût = du trafic canal, sur
  lequel ce projet a déjà payé une revue anti-spam), ou l'assumer et le documenter.

  PÉRIMÈTRE, toujours pas observé : le détail d'OFFRE dans la plaque (pièce / sac / nom de recette)
  et dans l'annuaire — aucune offre n'était réglée ; l'**anti-leurre AFK** (TTL 20 min, il faut
  l'attendre vraiment) ; le **combat** ; et le sélecteur de recettes, déployé après ces captures.

- 2026-09-26 (6) — jusqu'a 70a15c8 — Forever, un client, client en ANGLAIS — **GO sur la bascule
  LFW, croisée avec la commande** — rapporté par le user : *« co lfw fait la même chose que quand
  je clique dessus »*. **C'est LE critère de la bande** : elle affiche un état, donc il faut
  prouver qu'elle ne ment pas. Deux chemins indépendants (la commande et le clic) donnent le même
  résultat, sur Leatherworking comme sur Engineering.
  Le bouton **« Offre »** est lisible là où l'engrenage ne l'était pas — mais le user l'a vu
  « en arrière ». Cause : il était créé sur le cadre de la colonne et seulement ANCRÉ sur la bande,
  donc **frère** et non enfant, deux frames au même niveau et un ordre de dessin indécis. Corrigé
  (enfant + niveau explicite) — **à revoir à l'écran**.
  PÉRIMÈTRE, toujours pas observé : le **panneau d'offre** lui-même (l'« Offre » n'a pas encore été
  cliqué, et son ancrage a été corrigé par le calcul, jamais vu) ; la vue compacte d'un métier de
  **récolte** ; le **combat** ; et tout l'étage réception, qui demande le banc 2 comptes.

- 2026-09-26 (5) — jusqu'a dc086d5 — Forever, un client, client en ANGLAIS — **GO partiel sur la
  bande LFW** — capture d'écran, métier Engineering 130/150, après `/reload` (aucun redémarrage).
  La bande est **présente en pied de colonne**, sous le récapitulatif `0 pending · 0 accepted ·
  0 muted`, sans chevauchement. Elle affiche **« Available — Engineering » en vert**, avec
  l'engrenage calé à droite. La liste au-dessus n'est pas rognée : les 20 px réservés
  inconditionnellement se tiennent.
  **Effet immédiat, et c'est la raison d'être de la bande** : elle a révélé que le personnage était
  **annoncé comme disponible** en Ingénierie sans que ce soit visible nulle part ailleurs. L'état
  qu'on oublie d'éteindre se voit maintenant depuis toutes les vues.
  PÉRIMÈTRE, non observé à ce stade : le **clic sur la bande** (allumer/éteindre) ; le **clic sur
  l'engrenage** et l'endroit où le panneau d'offre s'ouvre — il s'ancre encore sur
  `frame TOPRIGHT`, hérité de la fenêtre custom, et la colonne étant collée au bord droit du cadre
  natif il peut sortir de l'écran ; le recoupement avec `/co lfw` sans argument ; la vue compacte
  d'un métier de récolte ; le comportement en combat.

- 2026-09-26 (4) — jusqu'a a5a678e — Forever, un client, client en ANGLAIS — **GO mesuré sur la
  languette « Route »** — `/co geo` avant/après, vue `route` (les deux autres vues n'ont pas été
  rouvertes et gardent le relevé de 11:28 ; la rangée est identique dans les trois).

  | | avant | après | delta |
  |---|---|---|---|
  | rangée vues | 213 px | **196 px** | −17 |
  | colonne | 241 px | **225 px** | −16 |
  | fenêtre hôte | 728 px | **712 px** | −16 |
  | marge droite | 8 px | 9 px | +1 |

  Le mécanisme est confirmé en conditions réelles : **la rangée pilote la colonne, et la fenêtre
  native suit**. Aucun chevauchement.

  **⚠️ CE RELEVÉ CALIBRE LA RANGÉE, ET IL DÉMENT L'ESTIMATION QUI L'A PRÉCÉDÉ.** J'avais annoncé
  ~31 px de gain ; la mesure en donne 17. Avec deux points (33 caractères → 213 px, 24 → 196) le
  modèle se pose :

  ```
  largeur d'une languette ≈ 40,6 px + 1,9 px × (nb de caractères)   [− 4 px de chevauchement]
  ```

  Recoupé sur l'état d'avant : 4 × 40,6 + 33 × 1,9 = 225 px contre 225 mesurés.

  **Ce que ça change pour le 5ᵉ onglet : c'est le CADRE qui coûte, pas le texte.** Une languette
  pèse ~41 px rien que pour exister, ses caractères 1,9 px pièce. Un 5ᵉ onglet `Work` (4 car.)
  ≈ 48 px, soit **+44 px** sur la rangée dont 9 de marge → **la colonne grandirait de ~35 px**
  (225 → ~260, fenêtre 712 → ~747). Raccourcir encore des libellés ne rendrait presque rien.
  Le renommage était donc le bon geste, mais il **ne rend pas le 5ᵉ onglet gratuit** : il en paie
  17 px sur 44. À décider en connaissance de cause avant d'écrire la vue Travail.
  PÉRIMÈTRE : chiffres relevés sur un client ANGLAIS. Le français rallonge les libellés, mais le
  cadre dominant, l'écart attendu reste faible.

- 2026-09-26 (3) — jusqu'a fe922f2 — Forever, un client, client en ANGLAIS — **GO mesuré sur la
  géométrie** — `/co geo`, **3 vues relevées sur 3** (orders, route, learn), métier Engineering.
  Le correctif du bouton d'aide est confirmé par l'outil, pas seulement à l'œil :

  ```
  aide           x 521..538   (avant : 726..743)
  rangee vues    x 539..752   213 px, 4 onglets, marge droite 8 px
  colonne        x 519..760   241 px   (avant : 227 px)
  ok  aucune des 6 paires surveillees ne se chevauche
  ```

  Le `!! aide x vues : 11 x 17 px` du matin a **disparu** dans les trois vues. La colonne a grandi
  de **14 px** (et la fenêtre hôte d'autant, 714 → 728) — c'est le prix voulu de la gouttière ;
  j'avais estimé +20, la mesure dit +14.
  **Ce que ce relevé apprend pour la rangée à cinq** : la rangée fait 213 px pour quatre libellés
  anglais (33 caractères) et il reste 8 px de marge. Le 5ᵉ onglet ne tient donc pas dans cette
  marge — mais `Leveling route` → `Route` (décidé dans `docs/specs/lfw-forever.md`) libère
  ~9 caractères, de quoi l'absorber. À confirmer par un relevé après coup, pas par ce calcul.
  ⚠️ **Défaut de conception trouvé par ces chiffres, et corrigé dans la spec avant d'être codé** :
  la languette Travail devait changer de texte selon l'état (`Travail` / `● Dispo`). Or
  `bar:SetText` rappelle `PanelTemplates_TabResize` — la languette aurait changé de LARGEUR au clic,
  pour 8 px de marge disponible. L'état se portera par la couleur.
  PÉRIMÈTRE : rien de neuf sur le fond de la page Profit ici, c'est un relevé de géométrie.

- 2026-09-26 (2) — jusqu'a f2af930 — Forever, un client, client en ANGLAIS — **GO sur le
  déplacement du bouton d'aide** — capture d'écran après `/reload`. Le « i » est passé au bout
  GAUCHE de la rangée, juste avant `Orders`, et le coin haut-droit de la languette `Profit` est
  **dégagé** : le chevauchement de 11 × 17 px relevé le matin même a disparu à l'œil. La fenêtre
  native s'est élargie d'une vingtaine de pixels, ce qui est le comportement VOULU — depuis ce
  correctif `_ViewTabsWidth` compte la gouttière au lieu de la forfaitiser, donc la colonne se
  dimensionne enfin sur ce qu'on pose réellement.
  **Deux faits de plateforme observés au passage, qui contredisent une règle du projet :**
  le déploiement a été fait **pendant que le client tournait** (copie sans verrou), et un simple
  **`/reload` a suffi** à charger les fichiers MODIFIÉS — la ligne « Crafting Order loaded » est
  visible dans le chat de la capture. Aucun redémarrage complet.
  PÉRIMÈTRE : ceci ne dit RIEN du cas qui fonde la règle `wow-toc-newfile-restart-and-parity`, à
  savoir un fichier **NEUF ajouté au `.toc`**. Ce correctif ne touche que des fichiers existants.
  Non mesuré non plus : le relevé `/co geo` d'après correctif (l'absence de `!! aide x vues` et les
  nouvelles marges) — il reste à prendre, et c'est lui qui chiffrera la rangée à cinq.

- 2026-09-26 — jusqu'a 45e6f02 — Forever, un client, **client en ANGLAIS** — **GO sur la page
  Profit (affichage)** — capture d'écran à l'appui, métier Engineering 130/150, Auctionator présent
  et scanné. La languette **Profit** existe dans la rangée et s'ouvre ; la liste affiche
  « Profitable (14) » et elle est **triée par marge décroissante** — vérifié en relisant les
  montants : `1po 62pa 49pc`, puis `12pa 40pc`, `10pa 88pc`, `8pa 67pc` … jusqu'à `4pc`. Les
  montants sont formatés en or/argent/cuivre. La fenêtre native n'est **ni fermée ni déplacée**, une
  recette y est sélectionnée et son panneau de détail porte « To Craft » et « Profit ».
  ⚠️ **DÉFAUT VU** : le bouton d'aide « i » **recouvre le coin haut-droit de la languette Profit**.
  Mesuré par `/co geo` (`!! aide x vues : 11 x 17 px`) ET visible sur la capture. Cliquer ce coin
  ouvre l'aide au lieu de changer de vue. Cause : le « i » est ancré à 16 px du bord DROIT de la
  colonne, sur la ligne de la rangée — une place qui était vide à trois languettes.
  PÉRIMÈTRE, ce qui n'a PAS été observé : que **le clic sur une ligne de Profit** soit bien ce qui
  a sélectionné la recette dans la fenêtre native (plausible sur la capture, pas rapporté) ; le cas
  **Auctionator absent**, où la languette ne doit pas apparaître du tout ; la disparition des textes
  « Lazy Gold » ; le comportement en combat. Les deux commits `f353468` et `925f981` restent donc
  non éprouvés malgré ce relevé.
  Relevé de géométrie du même jour : colonne 227 px, rangée de vues 212 px à **4 languettes**, marge
  droite **9 px**. Les libellés mesurés sont les ANGLAIS (`Orders`, `Leveling route`, `Missing`,
  `Profit`).

- 2026-09-23 (4) — jusqu'a b50f724 — Forever, un client — **GO** — la capture du RANG chez le
  formateur, vue fonctionner : visite d'un formateur d'Enchantement, `/reload`, et la SavedVariable
  porte `ranks = { [7420]=15, [7426]=40, [7454]=45, [7457]=50, [7748]=60, [7771]=70, [14293]=10,
  [14807]=70, [1230643]=20 }` — neuf rangs, de 10 a 70. Preuve au passage que
  `GetTrainerServiceSkillReq` existe bien sur Forever.
  ⚠️ **NON observé** : le rattrapage par infobulle (aucun service de ce formateur n'avait un nom
  inconnu de notre catalogue, donc ce chemin n'a pas été emprunté) et le comportement chez un
  formateur de CLASSE (où le rang doit rester absent, pas valoir zéro).

- 2026-09-23 (3) — jusqu'a c59ec45 — Forever, un client — **GO, la spec `prix-maison` est close** —
  la priorité du prix VENDEUR est enfin **observée**, et sur le cas qui discrimine : `/co pricedump`
  sur **Coal (id 3857)** rend `vendeur=4s75c  HV=3s97c  -> 4s75c`. Les deux prix existent, ils
  diffèrent, et c'est le vendeur qui l'emporte — la règle tire, elle n'est pas juste écrite.
  Chemin pour l'obtenir, à garder : Auctionator ne connaît le prix d'un vendeur qu'après avoir
  OUVERT sa fenêtre. Tant qu'on n'a visité personne, `vendeur=nil` partout et la règle est
  intestable. Il faut donc visiter un marchand, puis dumper un objet qu'il vend ET qui se trade.
  Constaté aussi : sur les réactifs non vendus (Rough Stone, Linen Cloth, Copper Bar…) le repli HV
  fonctionne, ce qui écarte la crainte qu'Auctionator rende un prix de REVENTE pour tout objet.
  ⚠️ Question de CONCEPTION ouverte (ce n'est pas un défaut) : ici le vendeur est PLUS CHER que le
  HV, donc la route surévalue Coal de 78c. La règle protège d'un HV gonflé sur un produit de
  vendeur ; elle coûte quand le HV est réellement moins cher. Voir la spec.

- 2026-09-23 (2) — jusqu'a 9d0be6e — Forever, un client, HV rescanné — **GO** — deux observations
  faites dans la foulée de la séance prix :
  **Gain de point de compétence** (`COC:OnSkillLines`, commit 20d93b8) : un point gagné fenêtre
  Ingénierie OUVERTE met le panneau de droite à jour tout seul, sans rien fermer ni rouvrir.
  C'était le but du correctif — la route suivait auparavant la liste d'AVANT le point.
  **Découpage de `_ProfWindow_Route_Supply`** (commit c206978) : le bloc « Supplies (aggregated) »
  et les « Recipe to buy » se peignent toujours, donc l'extraction n'a rien perdu en chemin.
  ⚠️ **NON observé, toujours** : la priorité du prix VENDEUR sur le prix HV pour un réactif
  achetable en ville. Ce qui a été vu n'est PAS ça — seulement qu'Auctionator n'ajoute une ligne
  « Vendor » à son infobulle que lorsqu'un prix vendeur existe (un objet sans valeur de revente
  n'affiche que « Auction »). C'est rassurant sur l'oracle, ce n'est pas la règle. Un seul
  `/co pricedump` la trancherait : il imprime `vendeur=` et `HV=` côte à côte avec ce que
  `ItemValue` a retenu.
  ⚠️ Séance toujours sous la **panne de SavedVariables** de Forever : rien de persistant éprouvé.

- 2026-09-23 — jusqu'a 32d994d — Forever, un client, HV rescanné en ouverture — **GO partiel** —
  **avec Auctionator** : le Plan de route se peint en entier (total estimé, 4 paliers chiffrés,
  « Supplies (aggregated) », plans à acheter), et la carte de recette affiche `To Craft` et
  `Profit: -1`. **Sans Auctionator** : aucune vue n'affiche `0`, et le bouton d'ouverture sort bien
  la popup « This feature needs the Auctionator addon ». C'est le cœur de la spec `prix-maison`
  (un seul oracle, et pas de zéro qui se lirait « ça ne rapporte rien »).
  ⚠️ **NON observé** : la priorité du prix VENDEUR sur le prix HV pour un réactif achetable en
  ville (point 5 de la spec). La route a changé entre deux scans d'HV — comportement attendu, les
  prix pilotent le choix — donc la comparaison avant/après ne prouve rien ici. À reprendre avec un
  réactif dont on connaît le prix vendeur.
  ⚠️ Séance menée pendant la **panne de SavedVariables** de Forever : rien de ce qui touche à la
  persistance n'a été éprouvé, et l'HV a dû être rescanné pour que les prix existent.

- 2026-09-22 — jusqu'a 0760259 — **reprise d'historique, pas un relevé de séance** — la v1.35.1 a
  été publiée sur CurseForge à ce commit, et la doctrine de release veut qu'on ne publie pas sans
  être passé au banc. On prend donc ce point comme départ du registre. ⚠️ Ce relevé n'a pas été
  écrit pendant une séance : il reconstitue un état à partir de la release. Les suivants seront
  écrits sur observation directe.
