# Réseau sans canal : la communauté remplace CraftLinkNet

> **Remplacée pour la découverte des artisans** : la communauté officielle « Crafting Order PVE » a
> été détruite par le user le 2026-09-30 (`Dir.OFFICIAL_ON = false`). Chacun coche désormais ses
> propres communautés dans la liste « Canaux surveillés » de l'onglet Artisans (spec
> `canaux-surveilles.md`, publiée en v1.41.0). Le reste de cette spec (le réseau en chuchotement, le
> canal coupé comme transport) tient toujours.
>
> État : **implémentée** (branche `feat/communaute-sans-canal`, 3 dépôts) · Rédigée le 2026-09-28 ·
> Décisions de produit prises par le user le 2026-09-27 (canal coupé pour tous, lien cliquable à la
> connexion) · Critères [humain] 12 à 16 **jamais observés en jeu**
> Cible : WoW: Forever / Camelot (16001) · Addon : Crafting Order - Classic + lib CraftLink
>
> Origine : retour du user le 2026-09-27. Son cousin et lui, même camp, même ville, même couche,
> côte à côte, ne voient pas les mêmes membres dans `CraftLinkNet`. La trace SavedVariables le
> prouve : 0 message du cousin par le canal, 41 par whisper dans la même session.

## Le problème

Sur Forever, un canal custom est découpé en salles par une clé qu'on ne connaît pas. Deux joueurs
qui rejoignent `CraftLinkNet` peuvent atterrir dans deux salles différentes et ne jamais s'entendre.
Le whisper, lui, traverse ce découpage. Le canal ne garantit donc plus rien, et il coûte : il prend
parfois le n° 1 de la liste des canaux (le joueur tape /1 dans un canal caché), et il affiche une
popup à l'installation.

Le user a créé la communauté **« Crafting Order PVE »** (lien d'invitation illimité, Alliance) et
veut que les joueurs la rejoignent, puis que l'addon arrête d'utiliser le canal.

Ce que le canal portait et qui se tait sans lui :

- le **démarrage réseau** au login (annonce de mon profil, HI, renvoi de mes commandes) : il est
  accroché à l'acquisition du canal et ne part jamais sans elle ;
- les **mises à jour** de profil (plan appris, point de métier) : `Announce` sort tout de suite si
  le canal n'est pas là ;
- les **transitions de commande** vues par tous : l'annulation d'une commande publique n'atteint
  que l'accepteur et le destinataire nommé, les autres la gardent ouverte jusqu'au TTL (6 h) ;
- le **LFW** (« je cherche du travail »), qui ne part qu'en texte de canal ;
- la **présence** : quitter le canal éteignait le joueur dans l'annuaire des autres ;
- la **balise de découverte** (`CLNK1`), seul vecteur vers un inconnu total.

## Ce qu'on veut

1. **Plus aucun joueur de la nouvelle version dans `CraftLinkNet`.** L'addon ne le rejoint plus,
   et il le quitte s'il y est encore (après une mise à jour suivie d'un `/reload`). Plus de popup
   « Crafting Order rejoint un canal dédié ».
2. **À la connexion, un joueur sans cercle voit un lien cliquable** dans son chat :
   « Rejoins la communauté des artisans : [Rejoindre : Crafting Order PVE] ». Un clic ouvre la
   fenêtre Guilde & Communautés sur l'invitation ; il n'a plus qu'à cliquer « Rejoindre ». Une
   commande éteint ce rappel pour qui n'en veut pas.
3. **La communauté officielle se marque toute seule comme cercle** dès que le joueur en est membre,
   sans `/co circle`. Un joueur qui la démarque à la main n'est plus jamais re-marqué d'office.
4. **Tout ce que l'addon envoyait « à tout le monde » part en whisper vers les artisans qu'il sait
   en ligne** (ceux qui lui ont répondu dans la session). L'annuaire, les commandes, le LFW, les
   rerolls et les cooldowns marchent entre deux membres du cercle comme ils marchaient dans le
   canal quand il n'était pas morcelé.
5. **Un artisan qui se déconnecte sort de l'annuaire en ligne** sans le canal, et le message rouge
   « Aucun joueur nommé X n'est connecté » ne s'affiche pas quand c'est l'addon qui lui écrivait.

## Ce qu'on NE fait PAS

- **Pas de transport par la communauté.** Mesuré le 2026-09-18 : le contenu d'un message de club
  est opaque et un AddonMessage envoyé sur son canal est avalé. La communauté sert d'annuaire, les
  données passent en whisper.
- **Pas de découverte d'inconnus hors cercle.** Sans canal, un joueur qui n'est ni ami, ni en
  guilde, ni dans un cercle, ni croisé, ne peut plus être découvert. C'est le prix de la décision,
  et le lien de connexion est là pour qu'il n'y ait plus d'inconnus.
- **Pas d'encart dans l'interface, pas de `/co circle join`.** Décision du user : le lien dans le
  chat suffit. COC ne peut de toute façon pas adhérer à la place du joueur (`RedeemTicket` est
  sécurisé).
- ~~Pas de communauté Horde~~ — créée par le user le 2026-09-28, même nom « Crafting Order PVE »,
  invitation `XGvoAXHvxd`, clubId 22973181 (relevé sur Orcaa). Chaque camp ne voit que la sienne. Un
  camp sans communauté officielle (aucun aujourd'hui) ne verrait aucun lien.
- **Pas de nouveau verbe ni de changement de format de fil.** Les messages restent identiques, seule
  la distribution change (WHISPER au lieu de CHANNEL).
- **Pas de rétro-compatibilité avec le canal.** Un joueur resté en v1.36 n'entend plus que ce qui
  lui arrive déjà en whisper (amis, guilde, cercle, commandes qui le visent). Accepté.

## Cas particuliers

- **Beaucoup de pairs en ligne.** Chaque message « à tout le monde » devient N whispers dans une file
  à 0,15 s par message. Plafond : **40 pairs par message**. Au-delà, la communauté a dépassé ce que
  ce transport sait porter et il faudra le revoir (file à priorités, ou sous-ensemble tournant).
  Le dépassement se trace.
- **Doublons.** `Orders:Broadcast` whispe déjà les artisans concernés, puis envoie « à tous », puis
  en texte : trois chemins vers le même joueur. Un même message pour la même cible dans une fenêtre
  de 2 s ne part qu'une fois.
- **Débit du serveur.** `SendAddonMessage` rend un code sur Forever. Sur `AddonMessageThrottle`, le
  message n'est pas perdu : il repasse en tête de file et la file attend 1 s. Sur `TargetOffline`,
  le pair est éteint dans l'annuaire.
- **Login.** Personne n'est « en ligne » au login : les envois « à tous » du démarrage ne partent
  vers personne, et c'est normal. Le contact s'établit par le balayage amis/guilde/cercle, qui
  existe déjà (HI|SK en whisper, chacun répond son profil, mes commandes sont poussées à chaque
  artisan qui répond).
- **Mode d'instance.** `GetSubscribedClubs` rend une valeur SECRÈTE en verrouillage de messagerie :
  tout accès aux clubs reste sous `pcall`, et le lien comme le marquage auto ne se jouent qu'au login
  et sur les événements club.
- **`/reload`.** Le lien ne s'affiche qu'à la connexion initiale, pas à chaque rechargement.
- **Communauté quittée.** Si le joueur quitte la communauté officielle, il n'a plus de cercle : le lien
  revient au login suivant. Son marquage manuel « démarqué » reste respecté s'il y revient.

## Décisions

- **2026-09-27, user** : canal coupé pour **tout le monde** (pas seulement pour les membres d'un
  cercle). Invitation = **lien cliquable dans le chat à la connexion**, seulement si le joueur n'a
  aucun cercle.
- **2026-09-28** : le reroutage vit **dans la lib** (portée « global » sans canal = whisper vers les
  pairs que le produit désigne), pas dans chaque appel de COC. Une douzaine d'appels émettent
  « global » ; les changer un par un en aurait oublié un, et la sémantique « à tous ceux que je
  connais » est exactement celle du canal quand il marchait.
- **2026-09-28** : la communauté officielle est reconnue par son **clubId** (22961321, le même vu sur
  les deux comptes du banc), jamais par son nom, qu'un propriétaire peut changer.
- **2026-09-28** : `/co channel on` reste, comme **opt-in de diagnostic** (rejoindre le canal pour
  comparer), désactivé par défaut. L'ancien opt-out `channelOptOut` n'a plus d'effet.
- **2026-09-28** : `/co circle nolink` éteint le rappel de connexion. Ajout de l'agent, non demandé
  par le user : un rappel à chaque connexion sans moyen de le couper devient une nuisance.
- **2026-09-28, user** (après le 1er test du lien, qui marche) : une **popup d'explication, une fois par
  compte**, au même moment que le 1er rappel. D'abord avec un seul « OK » (crainte de taint), puis, à la
  demande du user (« les gens risquent de ne pas voir le lien dans le chat »), avec **« Rejoindre » /
  « Plus tard »**, passé par la même porte qu'un clic de lien (`SetItemRef` clubTicket). **DÉMENTI EN
  JEU le 2026-09-28** : le clic a donné `ADDON_ACTION_FORBIDDEN … GetLastTicketResponse()`. Lancé depuis
  le code de l'addon, le récepteur CLUB_TICKET_RECEIVED de Blizzard est créé « touché par l'addon », et
  la fonction RESTREINTE qu'il appelle est refusée — pour toute la session, lien du chat compris
  (`/reload` pour s'en remettre). « HasRestrictions » dans la doc générée VAUT protection contre un
  appel venu d'un addon. **Retour à un seul « OK »**, verrouillé par test ; un lien dans le texte de la
  popup n'y échapperait pas (son clic passe par un OnHyperlinkClick fourni par l'addon).
- **2026-09-28, user** : le rappel de connexion part en **whisper à soi-même** (idée du user, pour qu'il
  ne se noie pas). Mesuré avant de coder, par un `/run` différé de 2 s (donc hors action du joueur) : le
  serveur accepte qu'on se whispe, et le lien clubTicket arrive intact, sur deux lignes (« [Gnomi
  Short] whispers » + « To [Gnomi Short] »). Son clic passe par la fenêtre de chat de Blizzard, le chemin
  propre. Si l'envoi lève : repli sur une ligne d'addon. `/co circle` garde une simple ligne.
- **2026-09-28, banc à 2 comptes (relevé 12)** :
  - **présence** : Rédemption quitte le jeu à 10:39:24, Gnomi le sonde à 10:39:27 — AUCUN retour (ni
    « aucun joueur nommé », ni `TargetOffline`, pour un whisper d'addon sur Forever) : il reste « en
    ligne » jusqu'à sa reconnexion. Sur l'idée du user, **la présence du jeu (communauté, amis,
    guilde) fait foi** : un départ l'éteint tout de suite, et le sondage reste en filet (sa réponse le
    rallume si le jeu s'est trompé). Revient sur l'arbitrage « sondage, jamais effacement » de la revue ;
  - **double message** : un whisper à soi-même s'affiche deux fois ; la copie « To [moi] » du rappel est
    masquée (filtre `CHAT_MSG_WHISPER_INFORM`, lien de cette invitation, 10 s) ;
  - **une bande par cercle** dans l'onglet Artisans, au nom de la communauté, à la place de « Cercle »
    (demandé par le user) ; plafond 4 bandes ;
  - **Confédération** visible sans GreenWall et hors `/co debug` (cause non trouvée : aucun fichier
    installé ne définit `gw.ReplicateMessage`) → exige désormais que l'addon GreenWall soit CHARGÉ ;
  - le filtre du chat passe par `ChatFrameUtil.AddMessageEventFilter` : `ChatFrame_AddMessageEventFilter`
    n'est qu'un alias de Blizzard_DeprecatedChatInfo.
- **2026-09-28, user** : communauté **Horde** au même nom, invitation `XGvoAXHvxd`. Son clubId 22973181
  vient de `chat-cache.txt` d'Orcaa (« Community:22973181:1 », seule communauté du perso, numéro plus
  récent que celui de l'Alliance) : c'est une déduction, que confirmera le message de marquage auto
  (il affiche le nom du club marqué).
- **2026-09-28, revues** (api-gotcha + protocole) :
  - un ACK/DLV reçu sur **ma commande annulée** me fait renvoyer le CANCEL à cet artisan : sans canal,
    un pair qui tient la commande d'un relais de proche en proche ne reçoit pas l'annulation ;
  - le jeu (amis, guilde, club) qui dit un pair parti déclenche un **sondage**, pas un effacement : la
    vérité JEU n'écrit pas la vérité ADDON ;
  - la **souscription de présence** (un seul club) va d'abord à la communauté officielle ;
  - « ton artisan X est en ligne » part aussi à la première réponse, plus seulement à l'entrée dans le canal ;
  - accès aux clubs illisibles (valeur secrète en instance) → on s'abstient, jamais « aucun club » ;
  - envoi refusé pour **verrouillage d'instance** : tracé, pas rejoué (un message rejoué tard ment) ;
  - ~~pas de repli si `INITIAL_CLUBS_LOADED` n'arrive jamais~~ — **démenti en jeu le 2026-09-28** :
    Gnomi quitte la communauté, se déconnecte, se reconnecte, et aucun lien. L'événement ne revient pas
    quand le client reste ouvert. Le lien part désormais **15 s après l'entrée en jeu**, sans attendre
    d'événement (roster du club lisible 4 s après l'entrée en jeu au banc). Chaque décision laisse sa
    raison dans `/co trace` (« lien de la communauté proposé / non proposé : … »).
- **2026-10-03, mesuré en jeu (DevMacro n°5 et n°6)** : le « aucun retour » du relevé 12 était un
  retour **en retard**. Le serveur rend « No player named 'X' is currently playing. » pour un whisper
  d'addon vers un absent (ou un nom inexistant) **108 à 112 s après l'envoi**, en paquet, dans l'ordre
  d'envoi, sans changement de zone. Le filtre le reçoit bien (aucune valeur secrète). La fenêtre de 15 s
  ne reconnaissait donc plus notre whisper : l'erreur s'affichait, et le pair parti restait « en ligne »,
  avec annonces et renvois de commande en boucle (spam vu par le user à Ironforge et Stormwind). Fenêtre
  portée à **5 min**. Le pair qui m'a parlé dans la dernière minute n'est pas éteint (revenu après l'envoi
  refusé). Prix, choix de l'agent **à confirmer par le user** : un whisper À LA MAIN vers un absent que
  l'addon a écrit dans ces 5 min perd son erreur. Le filtre passe dans `Directory_Presence.lua`.

## Critères d'acceptation

1. [test] Canal coupé : un `Send(…, "global")` produit un whisper par pair en ligne, aucun vers
   moi, aucun AddonMessage CHANNEL, au plus 40. → `tests/test_channel_fanout.lua`
2. [test] Le même message vers la même cible, émis deux fois en moins de 2 s, ne part qu'une fois.
3. [test] `QueueText` / `BroadcastText` (LFW, ordres en texte) partent en whisper vers les pairs ;
   la balise `CLNK1` ne part plus.
4. [test] Canal coupé, `IsNetworkReady()` est vrai et les rappels `OnNetworkReady` se déclenchent
   une fois au démarrage.
5. [test] Un `CraftLinkNet` encore présent est quitté par le chien de garde.
6. [test] Un envoi refusé pour débit repasse en tête de file au lieu d'être perdu.
7. [test] Membre de la communauté officielle → marquée cercle ; démarquée à la main → reste
   démarquée.
8. [test] Le lien s'affiche à la connexion initiale si aucun cercle et que le camp a une communauté
   officielle ; pas au `/reload`, pas pour la Horde, pas après `/co circle nolink`, pas si un cercle
   existe.
9. [test] Un « Aucun joueur nommé X » pour un pair que l'addon a chuchoté il y a moins de 5 min est
   avalé et éteint X (sauf s'il m'a parlé dans la dernière minute) ; au-delà, ou pour un nom que
   l'addon n'a pas écrit, il reste affiché. → `tests/test_community.lua`.
   En jeu [humain] : un pair qui se déconnecte ne fait plus pleuvoir « No player named », et
   `/co trace` ne montre plus d'envoi vers lui au-delà de ~2 min.
10. [porte] Les quatre portes passent ; toute chaîne neuve est dans les trois overlays.
11. [agent] Revue `api-gotcha-reviewer` (transport, clubs, valeurs secrètes) et
    `craftlink-protocol-reviewer` (fanout, doublons, présence) sans bloquant. → faites le 2026-09-28,
    aucun bloquant, corrections appliquées (Décisions). Renvoi du CANCEL : `tests/test_orders_cancel_reply.lua`.
12bis. [humain] Juste après un `/reload` avec `CraftLinkNet` encore rejoint : aucune erreur
    `ADDON_ACTION_BLOCKED` (le départ du canal se fait hors action du joueur). Pas de témoin connu-bon :
    `/co channel off` quittait le canal depuis une commande tapée, donc SOUS action du joueur ; c'est la
    première fois que l'addon le quitte seul. La source Blizzard ne le range pas parmi les protégés.
12. [humain] Au login, `CraftLinkNet` n'est plus dans la liste des canaux (clic droit sur l'onglet de
    chat › Canaux, ou `/chatlist`). Témoin connu-bon : en v1.36.2 il y est, souvent en n° 1.
13. [humain] Gnomi quitte la communauté, se reconnecte : le lien apparaît une fois dans le chat. Un
    clic ouvre Guilde & Communautés sur l'invitation. Après « Rejoindre », le chat dit que la
    communauté est marquée comme cercle, et Rédemption Wafhien apparaît sous « Cercle » avec ses
    métiers en moins d'une minute. Témoin : la liste Cercle vue le 2026-09-27 vers 19 h 28.
13bis. [humain] Au tout premier rappel sur un compte, une popup explique pourquoi rejoindre, avec un seul
    « OK » ; le lien est dans le chat au même moment, et c'est LUI qu'on clique. Au rappel suivant, plus
    de popup. Témoin : le clic sur le lien du chat, qui a fonctionné le 2026-09-28 (la version à bouton
    « Rejoindre » a donné ADDON_ACTION_FORBIDDEN, cf. Décisions).
    Note : rejoindre la communauté ajoute son chat à la fenêtre (« [6. CLinkN] has been added… », le nom
    court de la communauté) — c'est Blizzard (`ChatFrameUtil.AddCommunitiesChannel`), pas CraftLinkNet.
14. [humain] Commande de Gnomi vers Rédemption (nommée, puis publique) : reçue, acceptée, livrée,
    confirmée des deux côtés. Une commande publique annulée disparaît chez l'autre. Témoin : le cycle
    du relevé 9 de `verif-registre.md`.
15. [humain] Rédemption se déclare en recherche de travail (`/co lfw`) : Gnomi voit le badge. Témoin :
    le relevé LFW du 2026-09-27.
16. [humain] Rédemption se déconnecte : chez Gnomi il passe hors ligne (pastille), et aucun message
    rouge « Aucun joueur nommé » ne s'affiche.

## Contrat

- **Format de fil : inchangé.** Aucun verbe nouveau. Les verbes qui venaient par le canal (HI, SK, RI,
  CD, ALT, LFW, LFO, LFR, PING, ORD) arrivent désormais en WHISPER. Tous leurs gestionnaires
  l'acceptent déjà (vérifié le 2026-09-28 : seule la garde anti-usurpation de `_OnNew` distingue
  CHANNEL, et elle ne fait que s'effacer).
- **Lib CraftLink** (`TRANSPORT_REV` 15, nouveau fichier `CraftLink_Fanout.lua`) :
  - `lib:SetPeerSource(fn)` : `fn()` rend une table `{ [nom] = true }` des pairs en ligne ;
  - portée `"global"` sans canal = un whisper par pair (plafond, anti-doublon) ;
  - `lib:WhisperedRecently(nom, fenêtre)` : l'addon a-t-il écrit à ce joueur récemment ;
  - `lib:OnPeerOffline(fn)` : un envoi a répondu « cible hors ligne ».
- **SavedVariables COC** : `db.channelOptIn` (remplace `channelOptOut`, ignoré), `db.circlesOff`
  (`[clubId] = true`, démarquage volontaire), `db.circleLinkOff` (rappel éteint).

## Renvois

- Mémoires `coc-channel-split-community-migration`, `wow-club-api-gotchas`, `wow-forever-surnames-identity`.
- `docs/COMMUNITIES-TRANSPORT.md` (mesure du 2026-09-18 : pas de données par la communauté).
- `Directory_Club.lua` (source « cercle »), `Directory_Presence.lua` (balayage whisper).
- Skill `wow-classic-addon-dev` (transport CraftLink, pièges API).
