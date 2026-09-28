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
- AAAA-MM-JJ — jusqu'a <sha> — <banc> — <verdict> — <ce qui a été observé>
```

Le `<sha>` est le dernier commit **réellement présent dans le client** pendant la séance (celui que
`deploy.ps1` a copié), pas le dernier commit du jour. Le reste est en clair, pour qu'un humain
relise un verdict sans le décoder.

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
