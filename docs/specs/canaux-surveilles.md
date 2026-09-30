# Canaux surveillés : le joueur choisit où l'addon cherche les artisans

> État : **validée** le 2026-09-30 par le user · Idée et décisions du user, mise en forme par l'agent ·
> Maquette (artefact Design, 3 écrans) : https://claude.ai/artifact/BruefzxEXeUWnMExCvo3bv
> Implémentation : palier 1 (reconnaître un canal du jeu, `CraftingOrderClassic_Channels.lua`,
> `tests/test_channels.lua`) fait le 2026-09-30, critère 9 tenu en test ; palier 2 (une case par
> canal dans les lecteurs : demandes, annonces `#CO`, lignes LFW ; `tests/test_channel_watch.lua`,
> `tests/test_channel_readers.lua`) fait le 2026-09-30, critères 8, 10 et 11 tenus en test.
> En attendant l'onglet Artisans, les cases se lisent et se changent par `/co watch` (diagnostic,
> hors aide). **Critère 3 tenu en jeu le 2026-09-30** (registre, relevés 10:56 et 11:02 : Commerce
> décoché, la ligne `#CO` n'est plus lue ; recoché, elle entre) ; la salle coupée par `/co watch room
> off` vue aussi. Pas vus en jeu : les lignes LFW, la guilde, General, dire et crier. Le nom de
> Trade (Local) en français, allemand et espagnol reste à mesurer (reconnu à sa forme).
> Palier 3 (la section de l'onglet Artisans, `CraftingOrderClassic_UI_Artisans_Channels.lua`, lignes
> fabriquées par `Channels.BuildRows`, `tests/test_channel_rows.lua`) fait le 2026-09-30, **critères
> 1, 2 et 5 tenus en jeu le même jour** (registre, relevés 11:25 et 11:40 : capture hors capitale,
> communauté « eaze » cochée, Gnomi dans l'annuaire). Écarts avec la maquette, voir § Décisions du 2026-09-30
> (palier 3). Palier 5 (le panneau de première connexion, `CraftingOrderClassic_UI_Setup.lua`,
> `Channels.SetupState` / `MarkSetupSeen`) fait le 2026-09-30, **critères 6 et 7 tenus en jeu le
> même jour** (registre, relevé 12:06 : rapporté par le user, `setupSeen` relu dans les
> SavedVariables des deux comptes ; aucune capture de la mise en page). Il s'ouvre 10 s après la connexion (le jeu n'a pas encore rejoint ses canaux avant),
> jamais en combat ni en instance ; `/co watch setup` le rouvre. Restent les paliers 4 (canaux
> perso, reporté à une version suivante par le user) et 6 (aide, nouveautés, relectures).
> **En attente (user, 2026-09-30)** : la version sera la **v1.41.0**, mais la release attend une
> refonte de l'onglet Artisans, dessinée par le user dans une autre session. Le palier 6 (textes
> d'aide et de nouveautés, qui décrivent l'onglet) se fera une fois cette refonte connue.
> Cible : WoW: Forever / Camelot (16001) · Addon : Crafting Order - Classic
>
> Remplace, pour la découverte des artisans, la communauté officielle de
> `communaute-sans-canal.md` (détruite par le user le 2026-09-30, `Dir.OFFICIAL_ON = false`).

## Le problème

Depuis la v1.40.0, l'addon trouve les artisans sans communauté officielle : amis, guilde, cercles,
salle de découverte, lecture de Commerce. Mais ce qu'il surveille se règle par des interrupteurs
invisibles, chacun derrière une commande que personne ne connaît :

| Ce qu'il fait | Où c'est réglé aujourd'hui |
|---|---|
| lire les demandes (WTB) et les annonces `#CO` sur tout canal dont le nom contient « trade » (Trade, Trade (Services), Trade (Local)), et la discussion de guilde | `/co scan mine\|all\|off` |
| lire les lignes « LFW … » sur Trade, General, en dire et en crier | `/co lfwchat` |
| se présenter dans la salle `CraftLinkNet` | `/co channel room on\|off` |
| faire d'une communauté un cercle (ses membres dans l'annuaire) | `/co circle` |
| repérer ceux qu'on voit crafter en ville | une case en bas de l'onglet Artisans, `/co crafters` |

Un joueur ne sait donc ni où l'addon regarde, ni pourquoi il ne trouve personne. Vécu le
2026-09-30 : le user avait coupé la salle sur ses deux comptes pour un test, puis ne la voyait plus
dans sa liste de canaux et croyait qu'elle avait été retirée de l'addon. Et on ne peut pas choisir
un canal plutôt qu'un autre : les trois canaux « Trade » sont lus ensemble, ou pas du tout.

## Ce qu'on veut

**Une section « Canaux surveillés » dans l'onglet Artisans**, sous les filtres SOURCE : tous les
canaux dont l'addon sait tirer quelque chose, chacun avec une case. Coché, l'addon s'en sert ;
décoché, il l'ignore. Les canaux sont rangés par ce que l'addon en fait, parce qu'une case n'y veut
pas dire la même chose :

- **Annonces lues** (canaux du jeu : Trade (Services), Trade, Trade (Local), General, et la
  discussion de guilde). L'addon y lit les demandes, les dispos et les annonces des autres porteurs.
  Il n'écrit que sur Trade (Services), et seulement par « Annoncer en Commerce », sur un clic. Les
  trois canaux de Commerce n'existent qu'en ville.
- **Réseau de l'addon** (canaux perso : `CraftLinkNet`, la salle de découverte, et tout canal perso
  que le joueur a rejoint). L'addon s'y présente par un message invisible ; ensuite, tout passe en
  chuchotement. Un canal perso est découpé en salles : on n'y croise que les joueurs de sa salle.
- **Annuaire** (les communautés dont le joueur est membre). Leurs membres rejoignent l'annuaire,
  même hors ligne, avec la note que chacun y pose à la main. Aucune donnée ne passe par elles.
- **Autour de moi**. Ce que les joueurs disent ou crient près de soi (les lignes LFW), et, en ville,
  ceux qu'on voit crafter, même sans l'addon.

Un bouton « ? » explique chaque groupe en une phrase.

**Les défauts** reprennent ce que l'addon fait aujourd'hui, sauf General :

| Coché | Décoché |
|---|---|
| Trade (Services), Trade, Trade (Local), Guilde, `CraftLinkNet`, Dire et crier | General, les autres canaux perso, les communautés, Repérer les crafteurs |

**Un panneau à la première connexion** présente les mêmes groupes, avec une phrase chacun, plus la
case « Annoncer aussi mes commandes et ma dispo sur Trade (Services) ». Un bouton « Valider ».
Ensuite, tout se change dans l'onglet Artisans. Il s'affiche une fois pour chaque joueur, y compris
pour ceux qui ont déjà l'addon, à la mise à jour qui l'apporte.

Les commandes existantes restent, et agissent sur les mêmes cases que l'interface.

## Ce qu'on NE fait PAS

- **Pas de communauté officielle recréée.** Chacun coche celles dont il est membre.
- **Pas de filtre de la liste par canal** (décision du user). On n'a donc pas à retenir par quel
  canal chaque artisan a été trouvé.
- **Pas de nouveau transport.** Aucun message d'addon sur les canaux du jeu (ils y sont avalés,
  constat C13), aucune donnée par une communauté (C1, C3, C10). Le protocole reste en chuchotement.
- **Aucune écriture automatique sur un canal.** La seule ligne visible des humains reste celle
  d'« Annoncer en Commerce », sur un clic.
- **Pas de canal que l'addon ne sait pas exploiter** : LocalDefense et consorts ne sont pas listés.
- **Pas de canal perso créé par l'addon**, hormis `CraftLinkNet`, qui existe déjà.

## Cas particuliers

- **Canal où l'on n'est pas** (Commerce hors d'une ville, canal perso quitté) : la ligne est grisée,
  et le choix est gardé. De retour dans le canal, l'addon reprend sans rien demander.
- **Canal perso de quelqu'un d'autre** (une alliance de guildes, un canal d'amis) : décoché au départ.
  Coché, l'addon y envoie un bonjour invisible à l'arrivée ; les humains du canal ne voient rien.
- **Plusieurs communautés cochées** : leurs membres rejoignent tous l'annuaire, mais le jeu ne suit
  la présence en direct que d'**une seule** à la fois (« 0 or 1 clubs for presence »). L'addon choisit
  déjà la même à chaque session ; le « ? » le dit.
- **En instance**, la liste des communautés est une valeur secrète, illisible : la section ne se vide
  pas, elle garde la dernière liste lue.
- **Un joueur qui avait déjà coupé quelque chose par commande** (salle coupée, scan des LFW coupé,
  cercles choisis, repérage des crafteurs) : le panneau de première connexion part de SES choix, pas
  des défauts. Rien de ce qu'il a réglé n'est perdu ni inversé.
- **Panneau fermé sans « Valider »** (croix, Échap) : il vaut acceptation de ce qui est affiché, et
  il ne revient pas.
- **Combat au moment du login** : le panneau attend la fin du combat.
- **Client en français, allemand ou espagnol** : les canaux du jeu portent des noms traduits
  (« Commerce (Services) », « Handel (Dienstleistungen) », « Comercio (Servicios) »). Chaque canal est
  reconnu dans les quatre langues, et Trade n'est jamais confondu avec Trade (Services) ni Trade (Local).
- **Un canal rejoint en cours de session** apparaît dans la liste sans `/reload`.
- **`CraftLinkNet` ne prend jamais le n° 1** de la liste des canaux (garde existante, à conserver).
- **« Où » et « quoi » restent séparés** : les cases disent OÙ l'addon lit. `/co scan mine|all|off`
  (quels métiers) et `/co lfwchat` (lire ou non les lignes LFW) disent QUOI il en garde, partout.

## Décisions

- 2026-09-30, **user** : on ne recrée pas la communauté officielle ; « on rework le principe » : une
  liste des canaux exploitables par l'addon dans l'onglet Artisans, avec une case pour les surveiller.
- 2026-09-30, **user** : surveiller le canal perso de quelqu'un d'autre est un choix explicite, et un
  panneau de configuration à la première connexion fait choisir les options.
- 2026-09-30, **user** : ce panneau s'affiche une fois pour tout le monde, joueurs existants compris.
- 2026-09-30, **user** : pas de filtre de la liste par canal.
- 2026-09-30, **user** : « Repérer les crafteurs autour (en ville) » rejoint la liste, groupe « Autour
  de moi ».
- 2026-09-30, agent (maquette, non contestée) : rangement par type, avec un « ? » ; hors ville, ligne
  grisée et choix gardé. Ce dernier point tranche l'écart de `annonce-commerce.md` (« la case est
  grisée ») avec le code (refus au moment de poster), vu au test C du 2026-09-30 : les DEUX restent,
  la ligne grisée ici, le refus qui dit pourquoi au moment de poster.
- 2026-09-30, **user** (propositions de l'agent acceptées en bloc, « go pour la spec ») :
  - Trade (Local) coché par défaut : l'addon le lit déjà, même public que Trade ; General décoché :
    le bruit d'une zone entière pour peu d'annonces (aujourd'hui il n'y lit que les lignes LFW) ;
  - une ligne « Guilde » dans « Annonces lues », cochée : la discussion de guilde est déjà lue ;
  - une ligne « Dire et crier » dans « Autour de moi », cochée : déjà lus pour les lignes LFW ;
  - panneau fermé sans « Valider » = accepté tel qu'affiché, il ne revient pas (un panneau qui
    revient à chaque connexion se fait détester).
- 2026-09-30 (palier 3), **user** : la section reste dans la barre latérale (« option A »), et la
  liste DÉFILE quand elle dépasse. La vraie fenêtre (606 px de haut) est plus basse que la maquette :
  SOURCE prend 178 à 308 px selon les bandes de cercles, le bloc du bas 108.
- 2026-09-30 (palier 3), agent, écarts avec la maquette :
  - la liste n'a pas de hauteur fixe : elle commence sous la dernière bande SOURCE et prend ce qui
    reste, sinon une bande de cercle de plus l'aurait recouverte ;
  - une ligne grisée reste CLIQUABLE : le choix est une préférence, on peut la régler hors ville ;
  - pas de bouton « ? » à part : chaque en-tête de groupe explique son groupe au survol, et le « i »
    de la fenêtre dit à quoi sert la liste ;
  - pas de ligne « canal perso rejoint » avant le palier 4 : aucun lecteur ne s'en sert encore, et
    une case qui ne fait rien est pire que pas de case. Seul `CraftLinkNet` figure dans « Réseau de
    l'addon » ;
  - sans communauté, le groupe « Annuaire » dit « aucune communauté » plutôt que de rester vide.
- 2026-09-30, mesure en jeu (client anglais, Ironforge) : `GetChannelName` rend le nom LONG
  (« Trade (Services) - English », « Trade (Local) - Ironforge ») ; `GetChannelDisplayInfo`, celui
  de la fenêtre Chat Channels, rend un nom COURT (« Services », « TradeLocal ») et la catégorie
  (`CHANNEL_CATEGORY_WORLD` / `_CUSTOM`). La liste lit les noms longs ; les deux noms courts sont
  reconnus aussi.

## Critères d'acceptation

1. [humain] En ville, onglet Artisans : la section liste les canaux du jeu où l'on est, les canaux
   perso rejoints et les communautés, avec les défauts retenus. Témoin : la maquette, écran 1.
   Observateur : le user, en jeu.
2. [humain] Hors ville, les lignes de Commerce sont grisées, avec « en ville », et gardent leur case ;
   de retour en ville, elles redeviennent actives. Témoin : maquette, écran 2.
3. [humain, 2 comptes] Trade (Services) décoché chez Gnomi : une annonce `#CO` de Rédemption n'entre
   pas dans ses Entrantes, et sa trace ne montre ni « annonce … bonjour » ni `HI` renvoyé. Recoché :
   elle entre. Témoin connu-bon : le test A du 2026-09-30 (bonjour à +2 s, registre 08:48).
4. [humain, 2 comptes] `CraftLinkNet` coché chez les deux : il apparaît dans Chat Channels, sous
   Custom, et les deux traces montrent le bonjour de salle échangé. Décoché : il quitte la liste.
   Témoin connu-bon : le relevé du 2026-09-29 22:35 (salle rejointe, Prudence découverte).
5. [humain] Une communauté cochée : ses membres apparaissent dans l'annuaire, source Cercle.
6. [humain] Première connexion : le panneau s'ouvre une seule fois ; après « Valider » et un
   `/reload`, il ne revient pas, et les cases de l'onglet Artisans reflètent le choix fait.
7. [humain] Sur un compte qui avait `roomOff = true` (les deux comptes du banc au 2026-09-30), le
   panneau présente `CraftLinkNet` décoché.
8. [test] Les anciens réglages (`roomOff`, `lfwChatScan = false`, `crafterScan`, `circles`,
   `inboundScope = "off"`) se lisent dans les cases sans perte ni inversion.
9. [test] Les canaux Trade (Services), Trade, Trade (Local) et General sont reconnus dans les quatre
   langues, sans confusion entre eux.
10. [test] Un canal décoché : aucune de ses lignes n'est lue (demandes, lignes LFW, annonces `#CO`).
11. [test] Les commandes `/co channel room`, `/co circle` et `/co crafters` changent la case
    correspondante, et la case passe par la même porte que la commande. (`/co lfwchat` et `/co scan`
    n'ont pas de case : ils disent QUOI lire, pas où. Corrigé le 2026-09-30, à l'implémentation.)
12. [porte] Toute chaîne nouvelle est traduite (`check_locale.ps1`).
13. [agent] Aucun envoi sur un canal hors d'un clic, et le panneau ne touche pas au système de
    panneaux protégés (`api-gotcha-reviewer`).

## Contrat

Ce qui se persiste (SavedVariable `CraftingOrderClassicDB`) et qu'une version suivante devra relire.
**Proposé ; se gèle au premier tag qui l'embarque.**

- Les réglages existants **restent la vérité de leur case**, sous leur nom actuel : `roomOff`
  (`CraftLinkNet`), `circles` / `circlesOff` (communautés), `crafterScan` (autour de moi),
  `announceTrade` (Annoncer en Commerce). Pas de migration, donc rien à perdre.
- Nouveau : `watch` = table `{ [clé] = true | false }` pour les canaux du jeu et les canaux perso
  autres que `CraftLinkNet`. Absence de clé = le défaut ; `false` explicite = décoché par le joueur.
  Clés indépendantes de la langue du client : `trade_services`, `trade`, `trade_local`, `general`,
  `guild`, `sayyell`, et `custom:<nom du canal>` pour un canal perso.
- Nouveau : `setupSeen` = la version de l'addon où le joueur a validé (ou fermé) le panneau de
  première connexion. Absent = le panneau s'affiche.

## Renvois

- `docs/specs/communaute-sans-canal.md` : la communauté officielle, que celle-ci remplace pour la
  découverte.
- `docs/specs/annonce-commerce.md` : les annonces `#CO` et la case « Annoncer en Commerce ».
- `docs/constats-api.md` (dépôt d'outillage) : C1, C3, C10 (communautés), C13 (canaux du jeu), C14
  (note de membre), C15 (Commerce en clair).
- Code concerné : `CraftingOrderClassic_Inbound.lua`, `CraftingOrderClassic_LFWChat.lua`,
  `Orders_AnnounceRecv.lua`, `Directory_Room.lua`, `Directory_Club.lua`, `Directory_LootScan.lua`,
  `CraftingOrderClassic_UI_Artisans.lua`.
- Skills : `coc-native-ui` (kit d'interface, cases, panneaux), `wow-classic-addon-dev`.

## Plan (2026-09-30) — volatile, meurt quand c'est fait

1. **La reconnaissance des canaux du jeu**, pure et testée : un nom de canal → sa clé, dans les
   quatre langues. Critère 9.
2. **Une case par canal** dans les lecteurs (demandes, LFW, annonces `#CO`), avec les défauts et la
   lecture des anciens réglages. Critères 8, 10, 11.
3. **La section de l'onglet Artisans**, branchée sur les réglages ; la case « Repérer les crafteurs »
   y déménage. Critères 1, 2, 5.
4. **Les canaux perso autres que `CraftLinkNet`** : le bonjour de salle généralisé. Touche sans doute
   la lib CraftLink (dépôt à part), qui ne connaît qu'un canal. Critère 4, variante.
5. **Le panneau de première connexion** et sa marque. Critères 6, 7.
6. **Aide, Nouveautés, `CURSEFORGE.md`**, puis relectures (`api-gotcha-reviewer`, `locale-auditor`),
   puis banc à deux comptes. Critères 3, 4, 12, 13.
