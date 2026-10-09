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

- 2026-10-08 00:06 — jusqu'a 68545b1 — Forever build client 70245, Rédemption Wafhien (1er compte,
  `#4`) ; build `main-dev@779eb27 2026-10-08 00:02`, `## Version: 1.47.0` (lu dans le `.toc` déployé et
  par l'appli du banc, fiche `CraftingOrderClassic--release-v1.47.0`, trois gestes cochés OK) — **GO**
  sur le candidat v1.47.0 (`release/v1.47.0`, qui porte la fusion `1305fe9` du relais de confiance et
  des formulaires de tickets) : `/co version` affiche 1.47.0 et la ligne Build ; onglet Nouveautés,
  la v1.47.0 en tête, lisible, sans clé brute ni le mot « royaume », puis la v1.46.0 ; aucune erreur
  (BugGrabber du compte : rien depuis la session 405, la séance est la 426).

- 2026-10-07 23:53 — jusqu'a ce5b42c — Forever build client 70245, trois comptes : Gnoma Short (3e,
  `#5`, 4618, pas en LFW), Toao Rosa (4e, `#6`, 4620), Gnomi Short (2e, `#1`, 4620, le faux relais),
  Rédemption Wafhien (1er, `#4`) restée connectée ; build `main-dev@f4ec367 2026-10-07 23:47` (lu par
  l'appli du banc, fiche `CraftingOrderClassic--feat-relais-confiance-2`, cinq gestes cochés OK) —
  **GO sur le critère 9** (`feat/relais-confiance`) : avec le relevé de 23:43 (critère 8), les deux
  critères humains de la spec sont vus. Relu dans les traces : 23:52:44 Toao reçoit le LFW forgé « via
  Gnomi Short » ([Dispo]) ; clic sur Chuchoter → 23:53:08 Toao « VRF|Cooking|Gnomi Short » à Gnoma ;
  23:53:09 Gnoma répond « VRF|no|Cooking » (sans se noter de menteur : elle n'avait rien confié à
  Gnomi, D-R12) ; 23:53:10 Toao « VRF : Gnoma Short dément, relais Gnomi Short écarté », le LFW
  disparaît (remarque du user). 2e envoi forgé à 23:53:30 : rien chez Toao, Gnoma ne redevient pas
  [Dispo] ; la sonde de nettoyage lit `true`. Vu au passage : Rédemption, membre de la même salle,
  reçoit aussi les envois forgés et garde Gnoma [Dispo] « via Gnomi » jusqu'à expiration (25 min) ou
  son propre clic : l'écartement est local à qui a vérifié (attendu, D-R5). Pas d'erreur Lua.

- 2026-10-07 23:43 — jusqu'a 9baf899 — Forever build client 70245, quatre comptes : Gnoma Short (3e,
  `#5`, 4618, la source, Cuisine apprise pour l'occasion), Rédemption Wafhien (1er, `#4`, 4620, le
  relais), Toao Rosa (4e, `#6`, 4620), Gnomi Short (2e, `#1`, 4620, le faux relais) ; build
  `main-dev@31fe6c7 2026-10-07 23:34` (lu par l'appli du banc, fiche
  `CraftingOrderClassic--feat-relais-confiance` ; il porte 9baf899, déployé par une autre session
  après le `33f5e3f` de la fiche) — **GO sur le critère 8, KO sur le critère 9** (`feat/relais-confiance`).
  Relu dans les traces des quatre SV. Critère 8 : pré-vol OK (Gnoma voit Rédemption relais, 4620,
  en ligne) ; après l'oubli mutuel, 23:39:33 Gnoma « LFW|on|Cooking confié à Rédemption Wafhien »,
  Rédemption « posté dans la salle » à la même seconde, Toao « reçu via Rédemption Wafhien » à
  23:39:34 ; la ligne de Gnoma réapparaît chez Toao, [Dispo], « via » dans l'infobulle (remarque du
  user : « j'ai bien le relayed ») ; l'arrêt suit le même chemin (23:40:15 → 23:40:16), [Dispo]
  disparaît. Critère 9 : l'enveloppe forgée par Gnomi arrive chez Toao (et chez Rédemption) à
  23:41:38, « via Gnomi Short » ; **le clic sur Chuchoter n'ouvre que le chuchotement**, Gnoma reste
  [Dispo], aucune trace `VRF` chez Toao ni chez Gnoma ; le nettoyage lit `false` (Gnomi jamais
  écartée). Cause : `D0` n'est local qu'à `_FillArtRow`, le bouton (`_ArtRowButtons`) lisait un
  global vide. Corrigé par `ce5b42c` (test qui clique, échoue sur l'ancien code), à revoir au banc.
- 2026-10-09 12:19 — jusqu'a dbda765 — Forever build client 70291 (lu par `deploy.ps1`) ; comptes de
  la fiche : Rédemption (`#4`, client anglais) et Gnomi Short (`#1`, client FR) ; build
  `main-dev@a64cf0f 2026-10-09 11:59`, et `main-dev@1246ca1 2026-10-09 11:49` pour l'icône de la barre
  de titre (lus par l'appli du banc, fiche `CraftingOrderClassic--feat-bouton-ticket`, neuf gestes
  cochés OK, sans remarque, sur la parole du user) — **GO** sur `feat/bouton-ticket` (spec
  `docs/specs/signaler.md` de l'outillage, critères 7 à 9) : icône bug dans la barre de titre à droite
  du « i », entière, sur le Carnet et d'autres onglets, infobulle et clic (capture du user) ; la
  fenêtre Signaler reste devant la fenêtre principale (elle passait derrière en `@8df13bc`, capture du
  user, corrigé par `568dafe`) ; bouton de l'onglet Aide (capture) ; zone du lien montrée par son
  début, « Link copied » en vert après Ctrl+C ; Bug et Idea ouvrent les formulaires du dépôt avec la
  zone Version remplie, No GitHub account la page CurseForge ; `/co bug`, `/co idée` et la ligne de
  `/co help` ; Échap ferme la fenêtre en combat, aucune action bloquée signalée. Pas de capture du
  formulaire GitHub : le contenu exact de la zone Version est celui qu'attendait la fiche, coché OK.
  Pas de vrai bouton Copier : `CopyToClipboard` porte `HasRestrictions` (pas mesuré sur Forever).

- 2026-10-07 19:01 — jusqu'a e96fe97 — Forever build client 70245, Rédemption Wafhien (1er compte) ;
  build `main-dev@845a9e1 2026-10-07 18:53`, `## Version: 1.46.0` (lu par l'appli du banc, fiche
  `CraftingOrderClassic--release-v1.46.0`, trois gestes cochés OK) — **GO** sur `fix/version-banc` et
  `fix/artisans-metiers-principaux`, dans la release. Sonde `_SkillPayload()` affichée dans le chat
  (capture du user) : `SK|lvl=21|rm=4620;Cooking,31,75;Blacksmithing,109,150;Fishing,22,75;First
  Aid,49,75;Enchanting,162,225;rep=13` — **aucun `cv=`** : le banc ne dit plus sa version aux autres
  joueurs. (Le chat montre `lvl=21m=4620` : il avale `|r`, code de fin de couleur ; la chaîne est
  entière, les royaumes reçus par ce chemin sont notés dans les annuaires depuis 14:22.) `/co version`
  affiche 1.46.0 et la ligne Build. Onglet Artisans : métiers principaux avant Cuisine, Pêche et
  Secourisme sur les lignes de la capture d'avant (remarque du user : « c'est tout good »).

- 2026-10-07 18:44 — jusqu'a ed10579 — Forever build client 70245, quatre comptes : Toao Rosa (4e,
  4620, l'arrivante), Gnomi Short (2e, 4620), Rédemption Wafhien (1er, 4620), Gnoma Short (3e, 4618) ;
  build `main-dev@0f7dd3f 2026-10-07 18:40`, `## Version: 1.46.0` (lu dans le `.toc` déployé et par
  l'appli du banc, fiche `CraftingOrderClassic--release-v1.46.0`, deux gestes cochés OK) — **GO** sur
  le candidat v1.46.0 (relecture D14 comprise) — relevé relu dans les traces et les verrous des quatre
  SV. Toao entre à 18:44:13 ; 18:44:17 Rédemption « présentation de Toao Rosa demandée à Gnoma Short
  (royaume 4618) : passeur élu » ; Gnoma la reçoit et ne la reposte pas (déjà postée à 16:15, 6 h) ;
  18:44:49 Toao se présente aussi elle-même à Gnoma. **Pourquoi Rédemption et pas Gnomi** (la fiche
  annonçait Gnomi) : Gnomi gardait un verrou « Toao présentée » posé à 16:15 par le build d'avant la
  relecture (6 h à l'envoi, lu dans la SV du 2e compte) ; Rédemption, entrée dans la salle APRÈS Gnomi
  (18:43:13 contre 18:42:50), ne l'y avait pas vue et s'est crue élue — le cas « deux élus » accepté
  (D14), ici sans doublon puisque Gnomi s'est tue. Gnomi, elle, a bien vu Rédemption entrer (`[pres]
  join` à 18:43:17, bonjour de salle à 18:43:24). Pas d'erreur Lua. Au passage : Rédemption s'est
  présentée à Lina Licht (4618), un joueur extérieur déjà en v1.45.0.

- 2026-10-07 16:21 — jusqu'a df1d18f — Forever build client 70245, Toao Rosa (4e compte, 4620) et
  Gnoma Short (3e compte, 4618) ; build `main-dev@f0c30b7 2026-10-07 16:18` (lu par l'appli du banc,
  geste « toao-se-presente » coché OK à 16:21) — **GO** sur le verrou par personnage — relevé relu dans
  la trace de la SV du 4e compte. Toao se reconnecte à 16:20:38 ; 16:20:43 « présentation demandée à
  Gnoma Short (royaume 4618) » et `INT|Toao Rosa|4620` en whisper à Gnoma : le défaut de 16:15 (verrou
  commun au compte) est levé. ⚠️ **NON observé** : le côté de Gnoma (pas de `/reload` après 16:16, sa
  trace n'est pas sur le disque), donc pas vu qu'elle ne reposte pas une présentation faite à 16:15.

- 2026-10-07 16:16 — jusqu'a f2b8a9c — Forever build client 70245, quatre comptes : Toao Rosa (perso
  NEUF du 4e compte, royaume 4620, l'arrivant), Gnomi Short (2e, 4620, élue attendue), Rédemption
  Wafhien (1er, 4620), Gnoma Short (3e, 4618) ; build `main-dev@8e33709 2026-10-07 16:06` (lu dans le
  `.toc` de la copie déployée, et par l'appli du banc, fiche `CraftingOrderClassic--feat-pont-royaumes`,
  trois gestes cochés OK) — **GO partiel** sur le palier 3 (spec `pont-royaumes.md`, critère 14) —
  relevé relu dans les traces des quatre SV. Toao entre à 16:15:07 ; 16:15:14 Gnomi lit son bonjour de
  salle `HI|rm=4620`, 16:15:15 « présentation de Toao Rosa demandée à Gnoma Short (royaume 4618) :
  passeur élu » ; Rédemption n'a aucune ligne de ce genre (pas élue) ; 16:15:16 Gnoma reçoit la demande
  de Gnomi, 16:15:18 « présentation de Toao Rosa (royaume 4620) postée dans la salle », une seule fois.
  Au passage, Gnomi s'est présentée elle-même à son `/reload` de 16:14 (Gnoma l'a postée à 16:14:26) :
  palier 2 revu. **Défaut trouvé** : Toao ne s'est PAS présentée elle-même alors que Gnoma lui a répondu
  avec `rm=4618` (16:15:13) — le verrou de 6 h était rangé par royaume dans la SavedVariable, commune
  au compte, et Sfdfs (même compte) s'était présentée en 4618 à 15:44. Corrigé après la séance (verrou
  par personnage), PAS revu en jeu. ⚠️ **NON observé** : un membre de 4618 qui salue Toao (Gnoma est
  seule en 4618 sur nos comptes), la règle des 6 h de l'élu en jeu.

- 2026-10-07 15:44 — jusqu'a ebe242b — Forever build client 70245, trois comptes : Gnoma Short (3e,
  royaume 4618, l'arrivante), Rédemption Wafhien (1er, 4620, la connaît), Sfdfs Sdfdsfd (4e, 4620, ne
  la connaissait pas : absente de son annuaire avant le test, vérifié dans sa SV) ; build
  `main-dev@3abe28f 2026-10-07 15:27` (lu dans le `.toc` de la copie déployée, `feat/pont-royaumes`
  dans les branches ; `/co version` pas relevé) — **GO partiel** sur le palier 2 du pont (spec
  `pont-royaumes.md`, critères 11 et 12) — relevé relu dans les traces et les annuaires des trois SV.
  Gnoma recharge à ~15:41 : 15:42:00 « présentation demandée à Rédemption Wafhien (royaume 4620) »,
  `INT|Gnoma Short|4618` en whisper ; 15:42:04 Rédemption `[send] room : INT|Gnoma Short|4618`
  « postée dans la salle » (délai aléatoire de 3 s) ; 15:42:05 Sfdfs la reçoit sur la salle, 15:42:07
  « bonjour léger → Gnoma Short (présenté par Rédemption Wafhien) », `HL|rm=4620` ; 15:42:08 Gnoma
  répond un seul `HL|rm=4618` ; 15:42:09 Sfdfs le reçoit et ne répond pas. Annuaires : Sfdfs a
  `Gnoma Short` (realm 4618, lastSeen 15:42), Gnoma a `Sfdfs Sdfdsfd` (realm 4620). Première
  découverte d'un inconnu d'un autre royaume sans croisement en jeu. D9 vu : au passage en ligne,
  chacune a poussé à l'autre la commande `Gnomi Short-56` qu'elle tenait (un `ORD|NEW` chacune).
  ⚠️ **NON observé** : Gnoma dans l'onglet Artisans de Sfdfs (pas regardé), un second passeur qui se
  tait, le plafond par émetteur, la règle des 6 h en jeu, la coupure par `/co channel room off`.

- 2026-10-07 15:00 — jusqu'a 79803de — Forever build client 70245, Gnoma Short (3e compte, royaume
  4618, acheteuse) et Gnomi Short (2e compte, royaume 4620, forgeronne), Ironforge ; build
  `main-dev@0f4f0db 2026-10-07 14:53`, `## Version: 1.45.0` (lu dans le `.toc` de la copie déployée ;
  `/co version` pas relevé) — **GO** sur la commande inconnue (candidat v1.45.0, avec la revue
  `fix/revue-1.45`) — relevé relu dans les traces et les commandes des deux SV.
  Gnoma poste `Gnoma Short-2` (14:59:45, reçue par Gnomi), l'efface chez elle seule par `/run`, puis
  Gnomi l'accepte : 15:00:06 chez Gnoma « ACK sur une commande inconnue (Gnoma Short-2) : annulation
  renvoyée à Gnomi Short » et `ORD|CANCEL|Gnoma Short-2` en whisper à Gnomi seule ; 15:00:06 Gnomi le
  reçoit, sa commande passe `cancelled` (`acceptedBy = Gnomi Short`). Trois inconnus qui ont reçu le
  même ACK par le « à tous » n'ont rien renvoyé. Avant, au premier essai (14:56), le bouton « Annuler »
  de Gnoma : CANCEL reçu par Gnomi, commande masquée, l'annulation ordinaire marche d'un royaume à
  l'autre. ⚠️ **NON observé** : le plafond de 5 réponses par minute, la sourdine, la garde du `/1`
  sous le verrou du chat (combat de boss), et les couleurs de canaux après l'échange.

- 2026-10-07 14:24 — jusqu'a 8562a3a — Forever build client 70245, Gnomi Short (2e compte, royaume
  4620) et Gnoma Short (3e compte, royaume 4618) connectées ensemble, Ironforge ; build
  `main-dev@67296b9 2026-10-07 13:51` (inchangé depuis le relevé de 14:12) — **GO** sur le palier 1
  du pont, entre deux royaumes — relevé relu dans les traces et l'annuaire des deux SV.
  14:22:44 Gnomi → Gnoma `HI|SK|lvl=3|rm=4620;Blacksmithing,1,75` ; 14:22:45 Gnoma → Gnomi
  `HI|rm=4618` (elle n'a pas de métier). Annuaire : Gnomi note `realm = 4618` pour Gnoma, Gnoma note
  `realm = 4620` pour Gnomi (fiche avec métier, chemin `SK`) ; Gnomi a aussi `realm = 4620` pour
  Rédemption Wafhien. Les deux formes du contrat (avec et sans métier) sont donc vues dans les deux
  sens. Quatre bonjours de Gnomi vers Gnoma en 70 s : un par `/reload` (14:22:40, 14:23:08,
  14:23:39, 14:23:48), le délai de 60 s par joueur repart à chaque chargement, comme avant.

- 2026-10-07 14:12 — jusqu'a 8562a3a — Forever build client 70245, 2e compte (`#1`), Gnomi Short
  (royaume 4620), connexion à 14:11 ; build `main-dev@67296b9 2026-10-07 13:51` (lu dans le `.toc`
  de la copie déployée, `feat/pont-royaumes` dans les branches ; `/co version` pas relevé) — **GO
  partiel** sur le palier 1 du pont (spec `pont-royaumes.md`) — relevé relu dans la trace de la SV.
  `GetRealmID` répond depuis le code de l'addon dès la connexion : chaque bonjour part en
  `HI|SK|lvl=3|rm=4620;Blacksmithing,1,75`. `HI|rm=4620` reçu de Sfdfs Sdfdsfd (4e compte, sans
  métier), en whisper puis sur la salle, et noté dans sa fiche (`realm = 4620` dans la SV).
  **Compatibilité réelle** : trois porteurs de versions d'avant ont répondu normalement au nouveau
  bonjour dans la même seconde (Goldar Ksionc et Adelbert Immerspross par leur fiche complète ;
  Lorber Drillmaven, client v1.44.2 d'après son `cv=` de 13:29, par un HI).
  ⚠️ **NON observé** : un pair d'un AUTRE royaume (Gnoma, 4618, pas connectée) ; la réception d'une
  fiche `SK` portant `rm=` (Sfdfs n'a pas de métier).

- 2026-10-07 13:30 — jusqu'a 55339ea — Forever build client 70245, 4e compte de test (`#6`, créé à
  l'instant), Sfdfs Sdfdsfd (Alliance, Classic Beta PvE 2), première connexion, Elwynn ; build
  `main-dev@7707888 2026-10-07 13:04` (aucun déploiement depuis le relevé de 13:07 ; `/co version`
  pas relevé) — **GO** sur le cas « perso neuf » du /1 — relevé relu dans la trace de la SV de COC.
  13:28:52 → 13:29:02 : onze « attente d'un canal par défaut sur le slot 1 », puis salle rejointe en
  idx=1 (aucun canal du jeu au bout de 10 s) ; 13:29:16 « canal déplacé du /1 au /2 : le /1 rendu à
  General - Elwynn Forest », par le chien de garde, 14 s plus tard. C'est le cas qui manquait au relevé
  de 13:07. Dans la même trace : la salle répond (Gnomi Short, royaume 4620, et deux inconnus).

- 2026-10-07 13:07 — jusqu'a 55339ea — Forever build client 70245, 3e compte (`#5`), Gnoma Short
  (royaume 4618), Ironforge, groupée avec Gnomi Short ; build `main-dev@7707888 2026-10-07 13:04`
  (lu dans le `.toc` de la copie déployée, `fix/bonjour-et-slot1` dans les branches ; `/co version`
  pas relevé en jeu) — **GO partiel** — relevé relu dans la trace de la SV de COC.
  **Le /1 rendu (lib `_FixSlot1`)** : CraftLinkNet remis en /1 à la main
  (`SwapChatChannelsByChannelIndex(1,2)` en `/run`), puis 13:05:59 « canal déplacé du /1 au /2 : le
  /1 rendu à General - Ironforge », venu du chien de garde (minuterie, sans geste du joueur) ; au
  `/reload` de 13:06:07, salle rejointe en idx=2 : l'ordre corrigé tient.
  **Noms complets** : de 13:04 à 13:07, aucun chuchotement vers un prénom seul ni « Unknown » (tous
  les HI en « Prénom Nom », un nom cyrillique compris).
  ⚠️ **NON observé** : le clic droit sur Gnomi (un joueur déjà connu n'est pas relancé : un succès ne
  laisse aucune ligne ; la section « Crafting Order » du menu, qui cherche le joueur dans l'annuaire,
  n'a pas été regardée) ; la reprise du groupe 3 s plus tard (aucun groupe formé pendant la séance) ;
  la ligne « bonjour écarté » ; la première connexion d'un perso neuf (rejoindre en /1 puis rendre).

- 2026-10-07 10:02 — jusqu'a ac7c0ce — Forever build client 70245, un compte (#4, perso non noté),
  capitale, AFK ; build `main-dev@159d2e6 2026-10-07 09:54` (lu par la sonde dans le `.toc` déployé,
  `fix/route-cache-memoire` dans les branches) — **GO sur la mémoire du suivi** — mesuré par
  `/cocprobe mem` (COCProbe `feat/sonde-memoire`), 300 s, relevé relu dans la SV de COCProbe.
  **Avant** (09:29-09:34, `main-dev@8b3354e`, même compte) : `Route.Candidates` 8 passes, au moins
  2,9 Mo, environ 40 fois la fonction suivante, via `Tracker.Refresh` → `Route.NextStep` ×4 métiers ;
  COC +1106 Ko nets. **Après** : `Route.Candidates` **0 appel** dans la fenêtre (le cache tient) ;
  COC +221 Ko nets ; ce qui reste du suivi : `Tracker.Refresh` 14 repeints, 544 Ko inclusifs.
  Ramasse-miettes reparti dans les deux fenêtres : chiffres nets, bornes basses ; le classement vaut.
  Aucune table ne grossit au-delà de quelques dizaines d'entrées : pas de fuite.
  ⚠️ **NON observé** : la purge à la fermeture de l'hôtel des ventes (pas de passage à l'HV), le
  rafraîchissement après 15 min, et que le suivi conseille toujours la même recette qu'avant.
  Reste visible, à juger : `Directory.CapSeen` 164 Ko (49 appels) sur 95 `CHAT_MSG_TRADESKILLS`,
  détection des crafteurs activée (`feat/lien-metier`, au banc).

- 2026-10-05 21:11 — jusqu'a b4fcac0 — Forever build client 70205, deux comptes (Gnomi #1, Rédemption
  #4), build `main-dev@cbd9c25 2026-10-05 21:08` avec feat/ri-paliers (copie déployée du `.toc` ;
  `/co version` pas montré) — **GO partiel sur `feat/ri-paliers`** — relevé dans DevMacroDB.log et
  la SavedVariable de COC des deux comptes : Gnomi envoie un FAUX registre de Forge entier (506
  recettes, 10 messages, 198 octets au plus) → Rédemption en stocke 506 sur 506, par palier
  (0=10, 1=52, 2=91, 3=107, 4=246) ; dans l'autre sens, Cuisine entière (133 recettes, 4 messages)
  → Gnomi en stocke 133 sur 133 (1=35, 2=31, 3=35, 4=32). Puis la vraie fiche de Gnomi (`/dm 3`) :
  Rédemption ne garde que ses 5 vraies recettes de Forge, à l'ancienne forme, paliers oubliés.
  **Pas vu** : un vrai artisan au-delà de 255 octets (aucun sur la bêta), le relais d'un gros
  registre, l'annonce des seuls paliers changés, un morceau perdu, une v1.44.1 qui reçoit des
  paliers. Rédemption n'a pas encore remis sa vraie fiche chez Gnomi (faux registre de Cuisine).
- 2026-10-05 19:57 — jusqu'a 0548533 — Forever, compte #4 (Rédemption), build
  `main-dev@0e3eaed 2026-10-05 19:44` avec fix/cd-non-appris (copie déployée du `.toc` ; `/co version`
  pas montré) — **GO partiel sur `fix/cd-non-appris`** — SavedVariable écrite à 19:57 par ce build,
  relue au terminal : `schemaVer` = 2, la migration 2 est passée ; Anatarion (Couture 56) n'a plus
  aucun CD de Couture, l'Étoffe lunaire (18560, apprise à 250) relevée à tort est retirée sans qu'il
  ait rouvert sa fenêtre ; dans l'annuaire, un seul bloc de cooldowns reste, celui d'Avseneth
  Everglade (Étoffe lunaire, aucun rang de Couture connu : la garde ne tranche pas, c'est attendu ;
  l'essai à blanc sur la même SV avant le correctif en retirait 98 chez 21 joueurs). Le user, en jeu :
  « ça a l'air d'être bon », sans détail. **Pas vu** : un CD qui sort ou qui entre depuis le
  déploiement (aucune ligne `CD|` dans la trace après 19:44), donc ni le filtre d'émission ni la
  garde à la réception sur un message réel ; « Mes artisans » à l'écran ; le compte #1 (pas relancé,
  SV du 2026-10-04).
- 2026-10-03 23:38 — jusqu'a 03a9fbc — Forever build client 70205, un compte (Sheadra), réseau sans
  canal, 4 pairs en ligne (Osrik Stonefist, Ellowyn Snowveil, Crux Pal, Lirolia Clouddancer) ; build
  `main-dev@896f711 2026-10-03 23:34` avec fix/rafales-sans-canal et fix/erreur-chuchotement-retard
  (copie déployée du `.toc` ; `/co version` pas montré) — **GO partiel sur `fix/rafales-sans-canal`**
  — `/co trace` des sessions ouvertes à 23:36:43 et 23:38:15, relu dans la SavedVariable : chaque HI
  reçu ne fait partir `ORD|NEW` (mes 2 commandes) que vers son auteur (Osrik à 23:38:17, puis
  Ellowyn, Crux, Lirolia à 23:38:24-32, Osrik exclu de cette 2e vague), et aucune rediffusion de
  tout le carnet à tous. Aucune fiche complète (SK + RI) envoyée à tous : seules les réponses
  dirigées aux HI. Témoin : la session ouverte à 23:34:09, rechargée PENDANT la copie du
  déploiement, montre encore l'ancien comportement (deux fiches complètes à tous à 7 s d'écart,
  carnet à tous 4 s après le HI de Crux) ; et Osrik, en v1.44.0, envoie sa fiche à chaque point de
  Minage (toutes les 11 à 26 s). **Pas observé** : le regroupement de 60 s sur un vrai point de
  métier (aucun gain de compétence de Sheadra dans ces sessions) ; un doublon dirigé sans
  conséquence (Lirolia reçoit `-16` à 23:38:29 et 23:38:31, push au retour en ligne puis push du HI,
  2 s d'écart). Le correctif de `fix/erreur-chuchotement-retard` n'a pas été mis à l'épreuve (aucun
  pair parti pendant ces sessions).
- 2026-10-03 16:43 (réception de la capture) — jusqu'a 6d33ccf — Forever build client 70205, un
  compte, Deadmines, en combat contre Edwin VanCleef ; build `main-dev@4aeb800 2026-10-03 16:42`
  avec fix/lfw-afk-secret (copie déployée du `.toc` ; `/co version` pas montré sur la capture) —
  **GO sur `fix/lfw-afk-secret`** — capture du user, deux `/run` tapés pendant le boss :
  `print(issecretvalue(UnitIsAFK("player")))` → `true` (témoin : le verrou du boss est actif, l'état
  AFK est secret), puis `CraftingOrderClassic.Directory:LFWRiposte() print("riposte OK")` →
  `riposte OK`, sans erreur. L'ancien code levait sur ce même chemin (`not` sur la secrète, ligne
  305) et la commande se serait arrêtée avant le `print` : c'est donc le correctif qui a tourné. LFW
  actif : établi par l'erreur du ticker dans la même session (même persistance `COC.db.lfw`).
  **Pas observé** : un tick du ticker (toutes les 8 min) tombé pendant le boss ; BugGrabber après le
  combat pas relu.
- 2026-10-03 14:40 — jusqu'a 904e238 — même séance et même build que le relevé de 14:33 — **GO sur
  `feat/lfw-lien-metier` : critères 19 et 20 de `annonce-commerce.md`** — parole du user : « la
  fenêtre blacksmith […] avec le /co lfw fonctionnait au clic avec ses recettes ». Lu par l'agent dans
  la SavedVariable de Rédemption (écrite à 14:34:53) : `14:21:47` et `14:32:01` « dispo Blacksmithing
  annoncée sur Trade (Services) - English avec le lien frais » ; redémarrage de l'addon entre
  `14:33:05` et `14:33:15` (canal quitté, réseau prêt à 14:33:18, bonjours de connexion) ; puis
  `14:33:24` « … avec le lien **gardé** » ; `tradeLinks` garde
  `|Htrade:Player-4620-0099DCCF:3100:164|h[Blacksmithing]|h` (3100 = Forge Compagnon, à 96/150).
  Gnomi avait COC désactivé : sa SavedVariable de COC n'a pas été réécrite depuis 11:08 quand
  COCProbe a écrit la sienne à 14:34, et aucun chuchotement de Gnomi dans la trace de Rédemption.
  **Pas établi** : un `/reload` et un relog ne se distinguent pas dans la trace ; un lien gardé d'un
  autre jour n'a pas été essayé. Le lien gardé reste (décision du 2026-10-03 : il ne partait que s'il
  s'ouvrait vide).
- 2026-10-03 14:33 — jusqu'a 904e238 — Forever build client 70205, client de Rédemption en ANGLAIS ;
  build `main-dev@79ab669 2026-10-03 14:14` avec docs/spec-lien-metier, docs/spec-route-cout-net,
  feat/lfw-lien-metier, feat/lien-metier, feat/liste-destinataires, feat/profit-arbitrages,
  feat/route-cout-net, feat/vue-reroll-native, fix/clic-recette-connue, fix/connues-perimees,
  fix/route-formateur, release/v1.43.1 (copie déployée du `.toc`) — **GO partiel sur
  `feat/lfw-lien-metier` : critère 18 de `annonce-commerce.md`** — capture du user après le clic
  « Looking for work » : « availability announced in Trade (Services) - English. », puis la ligne
  `[5. Trade (Services) - English] [Rédemption Wafhien]: LFW Blacksmithing/[Blacksmithing] #CO`, le
  second « Blacksmithing » dans la couleur d'un lien, puis « looking for work: Blacksmithing — visible
  across the realm » ; le user : « Tout fonctionne normalement ». **Trade (Services) accepte donc un
  lien de métier** (jamais mesuré avant). **Pas observé** : la trace « avec le lien frais », le clic
  de Gnomi sans COC (critère 19), le lien gardé après un relog (critère 20). (Les trois sont relevés
  à 14:40, ci-dessus.)
- 2026-10-02 10:36 — jusqu'a 191a238 — Forever, client de Rédemption, en ANGLAIS, Forgefer ; build
  `main-dev@6936b40 2026-10-02 10:26` avec feat/liste-destinataires, feat/profit-arbitrages,
  fix/clic-recette-connue (copie déployée du `.toc`) — **GO sur `fix/clic-recette-connue`** — deux
  commandes de test DevMacro nommées pour le reroll Anatarion, `/co alts` coupé : (a) Secourisme,
  recette 1244431 que Rédemption connaît aussi → le clic ouvre la fenêtre de métier de Rédemption ;
  (b) Couture, qu'Anatarion seul connaît → le clic ouvre la vue d'Anatarion (témoin). Vu par le user
  (« ça fonctionne comme décrit », capture des deux icônes) et relu par l'agent dans `DevMacroDB.log`
  (10:35:37 : `T-a clic=native`, `T-b clic=reroll Anatarion`). **Pas observé** : le refus
  d'acceptation depuis Rédemption d'une commande nommée pour Anatarion (règle inchangée).
- 2026-10-02 10:20 — jusqu'a 8e7c062 — Forever, client de Rédemption, en ANGLAIS, Forgefer ; build
  `main-dev@ce68ef3 2026-10-02 10:16` avec icone-commande-recue, liste-destinataires,
  profit-arbitrages, release/v1.43.0 (copie déployée du `.toc`) — **GO sur `fix/manquantes-nom-long`**
  — capture du user, Enchantement 102/150, vue Missing (239) : « Enchant Cloak - Lesser Shadow
  Resista… » tient sur UNE ligne, tronqué par « … », et « Arcane Salvager » en dessous n'est plus
  recouvert (le constat du matin le montrait sur deux lignes). **Pas observé** : l'infobulle qui
  donne le nom entier au survol.
- 2026-10-02 09:37 — jusqu'a a1560ee — Forever build client 70170, même build addon `main-dev@2709aa5`
  — **GO** — fin de la liste de la v1.42.1 : `/dump CraftingOrderClassic.Api.IS_MAINLINE` → `[1]=true`
  (capture du user) ; le clic droit sur le bouton COC de la minimap ouvre la fenêtre des métiers
  (parole du user). Avec les relevés de 08:55, 09:20 et 09:30, tout ce que touchait le correctif
  `WOW_PROJECT_ID` = 18 a été vu.

- 2026-10-02 09:30 — jusqu'a a1560ee — Forever build client 70170, même build addon `main-dev@2709aa5`
  — **GO, sur la parole du user** — suite du relevé de 09:20 sur la v1.42.1 : l'onglet Nouveautés
  montre la v1.42.1 ; la relance du dernier métier à l'ouverture de la fenêtre (nouveauté du 70170)
  « fonctionne » ; le bouton Enchantement de la fenêtre d'échange « fonctionne ». Le détail (sur quel
  métier la fenêtre s'est ouverte, quel compte, une erreur ou non) n'a pas été dit.
  ⚠️ **Toujours non observé** : `/dump … IS_MAINLINE` (la capture de Rédemption montre `/dump` parti
  SANS expression : « empty result » ne dit rien de COC), et le clic droit sur le BOUTON minimap de COC
  (le user cliquait sur la minimap elle-même : un ping).

- 2026-10-02 09:20 — jusqu'a 321029b — Forever build client 70170, build addon `main-dev@2709aa5
  2026-10-02 09:11` d'après `deploy.ps1` (`/co version` pas relu), Enchantement 102/150, client en
  ANGLAIS — **GO partiel**, deux captures du user.
  **v1.42.1** : la colonne COC (onglets Orders / Route / Missing / Profit) est greffée à droite de la
  fenêtre de métier native. Ce que le relevé de 08:55 ne détaillait pas.
  **`feat/profit-arbitrages` (`321029b`)** : vue Profit en mode « Cost to cast (22) » ; les noms longs
  tiennent sur une ligne, coupés par « … » (« Enchant 2H Weapon - Lesser Intel… », « Enchant Weapon -
  Minor Beastsla… ») ; tous les montants en blanc ; infobulle « What one cast costs you, not a gain:
  your fee comes on top. » puis « Click: open this recipe. ». ⚠️ Non vu : l'infobulle d'une ligne
  TRONQUÉE (celle survolée, « Enchant Chest - Lesser Stamina », tient en entier).
  **Constat, vue Missing (239)** : « Enchant Cloak - Lesser Shadow Resistance » passe sur deux lignes
  et mord sur « Arcane Salvager » (entouré par le user). Même piège que la vue Profit, corrigé sur
  `fix/manquantes-nom-long`, pas encore vu en jeu.
  ⚠️ **Non observé** : `/dump … IS_MAINLINE`, le clic droit minimap, l'onglet Nouveautés v1.42.1, la
  relance du dernier métier à l'ouverture (70170), le bouton Enchantement de l'échange.

- 2026-10-02 08:55 — jusqu'a 154cd1c — Forever build client **70170** (jour de patch), build addon
  `main-dev@ce5e9fc 2026-10-02 08:50` d'après `deploy.ps1` (`/co version` pas relu en séance) —
  **GO, sur la parole du user** — `fix/wow-project-camelot`.
  **Avant le correctif** (v1.42.0, capture du user) : `/dump WOW_PROJECT_ID, WOW_PROJECT_CAMELOT,
  CraftingOrderClassic.Api.IS_MAINLINE` → `18, 18, false` : le 70170 a changé l'identifiant de
  Forever, et la garde de saveur éteignait le backend métier.
  **Après** : le user rapporte « COC fonctionne correctement ». ⚠️ Le détail de ce qu'il a regardé
  n'a pas été dit : le `/dump` de `IS_MAINLINE` à `true`, la colonne à côté de la fenêtre de
  métier et `/co métier` étaient proposés, aucun n'est cité un par un.

- 2026-09-30 22:20 — jusqu'a 598372c — Forever, 2 comptes (Gnomi / Sheadra), build `main-dev@7e165ee
  2026-09-30 19:41` d'après `deploy.ps1` (`/co version` pas relu en séance) — **GO** sur les
  cases NOTIFICATIONS (`feat/options-notifs`) — relu par l'agent dans `DevMacroDB.log`, grâce à un
  espion DevMacro qui note chaque ligne « Crafting Order », chaque bandeau et chaque son ; les
  étapes A, H et la disposition de la liste sont vues à l'œil par le user.
  **Disposition** (capture) : groupe NOTIFICATIONS puis HOW TO ALERT en bas des canaux surveillés,
  les trois portées en retrait sous « Addon orders », une seule cochée.
  **Commandes** : témoin 21:54:47 et 21:55:05 = LIGNE + BANDEAU + SON 3081 ; « Chat line » décochée
  (21:44:59) = BANDEAU + SON, sans LIGNE ; « Addon orders » décochée = la commande `-43` arrive
  (`open`, `should=false`) et 0 entrée, puis elle sonne à sa réception suivante une fois recochée.
  **Demande lue dans le chat** : témoin 21:48:28 et 21:52:22 = LIGNE « incoming … (trade) » +
  « you can craft it » + BANDEAU + SON ; « Requests read in chat » décochée = WTB envoyé à 21:50:47,
  0 entrée à 21:50:53.
  **Suivi** : 21:55:10 chez Gnomi LIGNE + BANDEAU « Sheadra Wafhien delivered your order », sans son ;
  21:55:26 chez Sheadra LIGNE « receipt confirmed by Gnomi Short! », sans bandeau ; « Tracking my
  orders » décochée = la commande `-46` remise et confirmée, 0 alerte chez Gnomi.
  **Connexion** : « Login message » décochée, pas de ligne « loaded » au `/reload` (capture).
  **Portée et façons** (Gnomi de confiance, bandeau et son décochés) : portée « Guild, friends and
  me », commande `-51` postée à 22:19:11, 0 entrée à 22:19:16 ; portée « All », commande `-52` à
  22:19:46 = une LIGNE seule à 22:19:47, sans BANDEAU ni SON 3081 — elle sert aussi de témoin : c'est
  bien la portée qui taisait `-51`, pas le filtre de niveau. (Un premier essai, à 22:16-22:17, ne
  prouvait rien : Gnomi n'était plus de confiance et « All » pas recochée.)
  ⚠️ **NON observé** : l'onglet Incoming après une demande silencée.
  Constat au passage : une commande publique d'un perso sous le niveau 5 (Gnomi, niveau 2) n'alerte
  pas (`muteBelowLevel`, filtre anti-bot existant) ; `/co trust` a levé le filtre pour la séance.

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
- 2026-10-02 10:06 — jusqu'a 92c52a1 — Forever, DEUX comptes (Gnomi poste, Rédemption reçoit), en
  ville ; build `main-dev@2709aa5 2026-10-02 09:11` avec icone-commande-recue, liste-destinataires,
  profit-arbitrages (copie déployée du `.toc`) — **GO sur le critère 12 et le vert (11 d) de l'icône,
  avec une amitié SIMULÉE** — Gnomi poste deux vraies commandes par DevMacro (`PostEntry`) :
  Gnomi Short-53 « Amis », Cape en lin (Couture, seul Anatarion sait) ; Gnomi Short-54 « Tous », Kit
  d'armure léger (Cuir, seule Sheadra sait). Les deux arrivent chez Rédemption sans numéro de recette,
  avec leur métier ; l'addon retrouve la recette par l'objet (2387, 2152) et le reroll qui sait faire.
  **1er essai (2026-10-01 18:15) : rien ne s'allume**, et c'est la règle : Gnomi est niveau 2, sous le
  seuil anti-robots (5) que l'alerte applique aussi (`sousSeuil=true niveau=2` relevé par `/dm 4`).
  Après `/co trust Gnomi Short` et `/reload` : **icône Cuir au « 1 » jaune, pas d'icône Couture** (vu
  par le user) ; `/dm 1` met Gnomi dans les amis de l'addon → **icône Couture au « 1 » vert** (vu) ;
  Gnomi annule (`/dm 5`) → **les deux s'éteignent** (vu ; relu par l'agent : statut `cancelled`,
  icônes `cachée` à 10:05:50). Mode daltonien coupé. BugGrabber : rien de COC ce jour. **Pas
  observé** : la vraie liste d'amis (le système d'amis du jeu est COUPÉ sur la bêta, « This system is
  currently disabled ») ; une vraie guilde ; le taint (critère 7) ; le clic depuis une commande reçue
  par le réseau (vu le 2026-09-30 sur les commandes posées localement).
- 2026-09-30 19:06 — jusqu'a 92c52a1 — Forever, client de Rédemption, en ANGLAIS, en ville ; build
  `main-dev@48bcc3f 2026-09-30 19:02` avec icone-commande-recue, liste-destinataires, options-notifs,
  profit-arbitrages (copie déployée du `.toc`) — **GO sur le 3e tour de l'icône (critère 11 a, b, c, e,
  f)** — commandes de test DevMacro relues par l'agent dans `DevMacroDB.log` : (a) Couture nommée pour
  Anatarion, (b) Forge que personne ne sait, (c) Cuir « à tous » que Sheadra sait. Premier essai
  (`main-dev@52894f9`, 18:57) : couleurs vues par le user (Couture et Forge bleues, Cuir jaune, puis
  bleu après (e), la nommée pour Sheadra) ; **défaut trouvé** : après une fenêtre de métier native, le
  2e clic n'ouvrait plus la vue reroll (ancres effacées au détachement) → `92c52a1`. Second essai : vue
  d'Anatarion ouverte (détache 19:04:02), fenêtre native ouverte puis fermée (19:04:20-25), vue rouverte
  (19:04:27) et vue par le user ; popup de la Forge « aucun problème » ; mode daltonien coché : `/dm 3`
  (19:05:47) rend `daltonien : true`, nommées en vermillon `0.84,0.37,0.00`, « à tous » en jaune
  `0.94,0.89,0.26`, clic Couture → `reroll Anatarion`, Forge → `popup`, Cuir → `reroll Sheadra`.
  BugGrabber vide depuis 19:01. **Pas vu** : (d) le vert guilde/amis (l'addon ne connaît ni guilde ni
  ami sur Rédemption), le critère 12 à deux comptes, le taint (critère 7), la popup mot pour mot.

- 2026-09-30 18:25 — jusqu'a 8350171 — Forever, 2 comptes, client en ANGLAIS, en ville ; build
  `main-dev@5ead49b 2026-09-30 18:06` avec icone-commande-recue, liste-destinataires,
  profit-arbitrages (copie déployée du `.toc` ; chargé : les commandes DevMacro déployées à 18:07 ont
  tourné à 18:15) — **GO sur l'icône par métier (critères 5 et 6), sauf le clic d'un métier que le
  perso n'a pas** — `DevMacroDB.log` de Rédemption : 3 commandes de test posées à 18:15:28, effacées
  à 18:16:24 ; le user rapporte les icônes, leurs nombres et leur disparition « ok ». Deux comptes :
  Gnomi passe `Gnomi Short-28` puis `-29` (enchant, nommées pour Rédemption, 18:16:52 et 18:17:10),
  Rédemption accepte `-29` puis `-28` (18:18:39, 18:18:48), relâche `-28` (NACK 18:19:01), Gnomi
  l'annule (18:19:08) : traces des deux comptes relues par l'agent, compteurs à l'écran jugés « ok »
  par le user. **Écart** : sur Rédemption (sans Couture), le clic sur l'icône Couture ouvre le LIVRE DES
  MÉTIERS de Blizzard (« Professions » : Herbalism, Enchanting, Cooking, Fishing, First Aid ; capture
  du user) au lieu d'écrire la liste dans le chat ; l'icône
  reste (attendu, c'est un état). La spec ne tranche pas le cas « métier que le perso n'a pas »
  (elle ne parle que du métier inconnu). **Pas vu** : l'infobulle mot pour mot, le taint (critère 7).

- 2026-09-28 13:20 — jusqu'a bd78702 — Forever, même build `main-dev@1ec0ce0` — **complément au relevé
  de 13:16** — rapporté par le user : mode Édition testé, aucune erreur (que l'icône ait été affichée
  à ce moment n'est pas précisé). Combat et `taintLog 1` non mentionnés : le critère 7 reste partiel.

- 2026-09-28 13:16 — jusqu'a bd78702 — Forever, **DEUX COMPTES**, client en ANGLAIS ; build
  `main-dev@1ec0ce0 2026-09-28 13:09`, branches en test `feat/icone-commande-recue` (capture de
  `/co version`) — **GO sur l'icône « une commande t'attend »** (spec `icone-commande-recue.md`) —
  deux captures du user après la commande de test `/run` (« Test Un », Bolt of Linen Cloth) : le
  marteau des commandes dans la barre, sous le nom de la zone ; infobulle « Crafting Order / Orders
  in your name: 1 / Test Un : Bolt of Linen Cloth / Click: open the profession of the newest one. ».
  Rapporté par le user, sans capture (« tout s'est bien passé jusqu'au bout ») : le clic, l'extinction
  par la 2e ligne `/run`, et le test à deux comptes (commande nommée → icône chez B, acceptée → partie ;
  annulée par A → partie). Bruit : 3× `SelectRecipe:466` à l'acceptation = Auctionator, rallumé par
  le user pour d'autres tests (4e épisode connu, pas COC). `taint.log` inchangé depuis le 22/09 : le
  critère 7 (mode Édition, combat, `taintLog 1`) n'est PAS prouvé par ce relevé.

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
