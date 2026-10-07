# Relais de confiance : faire passer le LFW et les commandes publiques d'une salle à l'autre

> État : **approuvée** (décisions D-R2 à D-R10 prises par le user le 2026-10-07), codée, critères 8
> et 9 vus au banc le 2026-10-07 ; part en v1.47.0 · Rédigée le 2026-10-07 · Idée du user, le 2026-10-07 (« définir des nœuds de
> confiance qui répètent les commandes dans le canal CraftLink des différents royaumes », et la
> vérification au clic) · Rien de codé
> Cible : WoW: Forever / Camelot (16001) · Addon : Crafting Order - Classic
>
> Suite du pont entre royaumes (`pont-royaumes.md`, publié en v1.46.0). Faits mesurés : skill public
> `wow-addon-dev:wow-forever-api`, `references/chat-channels-and-communities.md`, « A channel stops at
> your realm » (salle CraftLinkNet et Commerce par royaume, royaume attribué au compte, whisper qui
> traverse, guildes qui semblent traverser).

## Le problème

Depuis la v1.46.0, un porteur qui arrive est présenté aux salles des autres royaumes. Ceux qui l'ont
salué reçoivent ensuite son LFW et ses commandes publiques par chuchotement, comme pour tout pair
connu. Deux trous restent :

- **Les retardataires.** Un joueur qui entre dans la salle d'en face APRÈS la présentation ne connaît
  pas l'arrivant : il ne reçoit ni son LFW ni ses commandes (l'arrivant n'est représenté qu'une fois
  toutes les 6 heures).
- **Le plafond.** « À tous » part en chuchotement vers chaque pair connu en ligne, au plus 40
  (`CraftLink_Fanout.lua`, `MAX_PEERS`). Au-delà, le message n'atteint pas tout le monde. Un message
  posté dans une salle, lui, atteint tous ses présents d'un coup.

## Ce qu'on veut

Quand un porteur A passe en LFW ou poste une commande publique (« Tous »), un **relais** de chaque
autre royaume la répète dans SA salle. Tous les présents de cette salle la voient, retardataires
compris, pour un message chuchoté et un message posté par royaume.

La source tranche quand quelqu'un agit (idée du user) : un joueur qui clique sur un LFW ou accepte une
commande vue par un relais s'adresse à A lui-même. Si A dément, le relais est écarté.

Rien ne parle de royaume dans l'interface (règle du user, 2026-10-07).

## Ce qu'on NE fait PAS

- **Relayer les fiches** (métiers, recettes) : le pont s'en charge (présentation, bonjour léger).
- **Relayer les commandes nommées, de guilde ou d'amis** : seules les commandes « Tous » ont un public
  dans une salle étrangère. Une commande de guilde passe déjà par le canal de guilde, une commande pour
  des amis par chuchotement direct (qui traverse les royaumes) : rien à relayer (confirmé par le user).
- **Relayer l'offre détaillée du LFW** (`LFO`, `LFR`) : la ligne LFW suffit pour qu'on contacte A ;
  l'offre arrive en direct au premier contact.
- **Un second saut** : un message reçu d'un relais n'est jamais relayé de nouveau.
- **Relayer les annulations** : seul l'acheteur annule. Une commande relayée qu'il a annulée disparaît
  au bout de son délai normal, ou plus tôt si quelqu'un l'accepte (A renvoie l'annulation, v1.45.0).

## Cas particuliers

- **Un relais qui ment** (invente un LFW ou une commande au nom de A) : rien n'est écrit dans la fiche
  de A ; l'entrée relayée est marquée « relayée par B ». Au premier geste vers A, A dément ; l'entrée
  disparaît, B est écarté comme relais chez le joueur qui a cliqué, et A est prévenu (il cesse de le
  choisir).
- **Un relais qui se tait** (ne poste pas) : invisible. Parade proposée : A choisit un nouveau relais
  au rafraîchissement suivant si le premier n'a pas répondu (voir D-R6).
- **Une copie qui survit à A** : A passe hors LFW ou se déconnecte. Le relais répète aussi `LFW off`.
  Sinon l'entrée relayée expire d'elle-même (durée plus courte qu'une entrée directe).
- **L'entrée directe gagne toujours** : si D reçoit le LFW de A en direct, l'entrée relayée est
  remplacée.
- **Ancien client** (avant cette version) : il ignore les verbes nouveaux ; A ne le choisit jamais
  comme relais (il ne déclare pas savoir relayer).
- **Message coupé à 255 octets** : l'enveloppe ajoute le nom complet de A et un numéro. Une commande
  publique fait environ 100 octets ; l'enveloppe la plus longue reste sous 200.
- **Instance** : rien n'est envoyé, ni relayé (le jeu y refuse les messages d'addon).

## Décisions

- **D-R1 (user, 2026-10-07)** : des relais répètent, dans la salle de leur royaume, ce qu'un porteur
  d'un autre royaume publie ; la source tranche au premier geste (vérification au clic).
- **D-R2 (user, 2026-10-07)** : ce qui passe : le LFW (on / off) et les commandes publiques « Tous ». Rien
  d'autre (voir « Ce qu'on NE fait PAS »).
- **D-R3 (user, 2026-10-07)** : **A choisit ses relais**, un par royaume étranger : un ami ou un membre de sa
  guilde d'abord, sinon le porteur à jour le plus récemment vu, en ligne. (L'option stricte, amis et
  guilde seulement, n'est pas retenue.)
- **D-R4 (user, 2026-10-07)** : **une enveloppe** `RLY2|<A>|<n>|<message>` (verbe à nommer) : A la chuchote au
  relais, le relais la poste telle quelle dans sa salle. À la réception sur la salle : le message
  intérieur est traité comme venant de A **par un tiers** (une commande est créée, jamais modifiée,
  comme un relais par chuchotement aujourd'hui ; un LFW entre dans une entrée « relayée par B »,
  jamais dans l'entrée directe de A). Nécessaire aussi pour les commandes : une commande postée dans
  la salle par un autre que l'acheteur y est aujourd'hui rejetée comme usurpation
  (`Orders_Net.lua`, `_OnNew`).
- **D-R5 (user, 2026-10-07)** : **la vérification au clic**. Quand D agit sur une entrée relayée (chuchoter,
  commander à A, ouvrir son offre), COC chuchote d'abord à A « tu es bien en LFW ? » ; A répond oui ou
  non. Sur un non : l'entrée disparaît chez D, D écarte B comme relais (24 h), et A note que B a menti
  (il ne le choisit plus). Pour une commande, rien de neuf : l'acceptation part à l'acheteur, qui
  renvoie une annulation s'il ne la connaît pas (v1.45.0).
- **D-R6 (user, 2026-10-07)** : **le rythme**. Une commande : relayée une fois à sa publication (et à la
  republication de A toutes les 2 h). Un LFW : relayé à l'activation, puis toutes les 15 min tant
  qu'il est actif (l'entrée relayée expire après 25 min sans rafraîchissement). Si un relais n'a rien
  posté (aucun membre de sa salle ne l'a vu), A en choisit un autre au rafraîchissement suivant.
- **D-R7 (user, 2026-10-07)** : **plafonds**. Chez le relais : au plus 6 enveloppes par source et par 10 min,
  30 en tout. Chez un membre de la salle : au plus ~~10~~ 30 entrées relayées par relais et par 10 min
  (D-R12 : à 10, le membre tronquait en silence ce que le relais avait posté).
- **D-R8 (user, 2026-10-07)** : **ce que voit le joueur**. Une entrée relayée s'affiche comme les autres (plaque
  LFW, liste des commandes), avec dans son infobulle « via <relais> », sans le mot royaume.
- **D-R9 (user, 2026-10-07)** : **savoir relayer**. Un porteur à jour l'annonce dans sa fiche de métiers par
  un petit morceau (par exemple `rl=1`, placé avant les métiers comme `rm=`), ignoré par les clients
  d'avant. Pas la version (`cv=`) : les builds du banc la taisent depuis la v1.46.0.
- **D-R10 (user, 2026-10-07)** : pas de réglage à part ; suit la salle de découverte (`/co channel room off`).
- **D-R11 (relecture avant le code, 2026-10-07)** :
  - **la taille se mesure chez A** : le jeu coupe un chuchotement à 255 octets sans prévenir, le relais
    ne recevrait qu'un morceau (une liste de réactifs coupée donnerait un faux objet). A mesure
    l'enveloppe entière et ne l'envoie pas au-delà de 255 octets (prix en texte libre, réactifs fournis
    sans plafond : une grosse commande n'est pas relayée, elle garde ses autres chemins) ;
  - **une commande n'est relayée qu'une fois par 2 h**, retenu dans les SavedVariables : la
    republication de A part aussi à chaque bonjour reçu, pas seulement toutes les 2 h ;
  - **une commande relayée est traitée comme reçue d'un tiers** (l'émetteur réel est le relais) :
    créée, jamais modifiée, jamais comptée contre A par l'anti-spam. Jamais réenveloppée ni reposée ;
    la poussée existante des commandes connues à un pair qui passe en ligne reste ce qu'elle est. Sans
    titre : seul l'acheteur peut en donner un, et le titre n'est pas relayé ;
  - **un inconnu en LFW relayé** entre dans l'annuaire comme une fiche relayée (`RLY`) : sans présence,
    sans « vu le », marquée « via <relais> », oubliée après 7 jours sans contact direct ;
  - **périmé n'est pas mensonge** : A se souvient de ce qu'il a confié à chaque relais. S'il lui a bien
    envoyé ce LFW il y a moins de 35 min (une copie pas encore effacée), il répond « périmé » :
    l'entrée disparaît chez D, personne n'est blâmé. Il ne blâme le relais que s'il ne lui a jamais
    rien confié de tel.
- **D-R12 (revue protocole après le code, 2026-10-07)** :
  - **le numéro d'enveloppe part de l'heure réelle** de A : il repartait de 0 à chaque `/reload`, et un
    relais resté en ligne jetait alors la nouvelle enveloppe comme déjà vue, sans accusé ; A le
    croyait muet. Une enveloppe vue est oubliée après 1 h ;
  - **« Tous » exigé chez le relais ET chez le membre**, et le métier d'un LFW doit être une clé de la
    lib : une commande nommée relayée alertait sa cible au nom d'un A que personne n'avait vérifié ;
  - **une source de mon royaume n'est jamais relayée** chez moi : elle poste elle-même dans ma salle,
    une enveloppe à son nom ne peut venir que d'un faussaire. (Un pair d'un autre royaume que je
    connais reste relayable : son LFW ne part que dans sa salle.) ;
  - **seules MES commandes sont confiées**, pas celles d'un reroll : l'enveloppe porte mon nom, le
    relais la jetterait (acheteur ≠ source) ;
  - **A ne blâme un relais que s'il lui a confié quelque chose** dans les 24 h, et pour 24 h : la
    question vient d'un tiers que rien n'authentifie, sinon n'importe qui ferait écarter un relais
    sain. « Périmé » se juge métier par métier : un LFW changé depuis moins de 35 min n'est pas un
    mensonge ;
  - **le relais voit lui-même le LFW** qu'on lui confie (A le lui a chuchoté : c'est une annonce
    directe), sinon il était le seul de sa salle à ne pas le voir ;
  - **limites acceptées** : une commande forgée peut prendre l'id de la vraie (ids `Nom-<n>`
    devinables) ; elle tombe au premier geste (l'acheteur renvoie une annulation, D-R5). Le « via »
    n'est montré que pour un LFW : une ligne de commande n'a pas d'infobulle d'origine, la trace le
    dit (écart à D-R8, à confirmer par le user). La vérification ne part que du bouton Chuchoter de
    l'onglet Artisans, pas de « commander à A » ni de son offre (écart à D-R5, idem). Un faussaire
    crée jusqu'à 30 fausses fiches d'annuaire par 10 min (plafond du membre ; le métier est validé,
    rien ne plafonne les fiches purement relayées, oubliées après 7 jours). Le numéro d'enveloppe
    (heure réelle) prend ~9 octets de plus : une grosse commande passe un peu plus tôt en « trop
    long » et garde ses autres chemins.
- **D-R13 (user, 2026-10-07, après le banc)** : les deux écarts sont acceptés pour ce palier, publié
  tel que vu au banc. Le « via » sur une commande relayée et les autres déclencheurs de la
  vérification (commander à A, ouvrir son offre) viennent dans un palier suivant.

## Critères d'acceptation

1. [test] La fiche de métiers d'un client à jour porte `rl=1` juste après `rm=` ; un client d'avant la
   lit sans erreur, avec les mêmes métiers. Un bonjour sans métier reste `HI|rm=<id>` (inchangé).
2. [test] A passe en LFW : une enveloppe part vers un seul relais par royaume étranger connu qui sait
   relayer, un ami ou un membre de guilde d'abord ; aucune vers son propre royaume, aucune vers un
   client d'avant ; au plus 5 royaumes. Rien en instance, rien salle coupée.
3. [test] Rythme : le LFW est relayé à l'activation puis au plus toutes les 15 min ; `LFW off` part tout
   de suite s'il avait été relayé ; une commande « Tous » à sa publication, puis au plus toutes les 2 h ;
   jamais une commande nommée, de guilde ou d'amis.
4. [test] A n'envoie pas une enveloppe de plus de 255 octets. Le relais poste l'enveloppe dans sa
   salle telle quelle, une fois, et répond à A ; il refuse une enveloppe dont la source n'est pas
   l'émetteur, un message intérieur hors liste (LFW on/off d'un métier de la lib, commande « Tous »
   dont l'acheteur est la source), et au-delà de 6 par source ou 30 en tout par 10 min. Il voit
   lui-même le LFW confié. Après un `/reload` de A, l'enveloppe suivante porte un numéro neuf, et le
   relais resté en ligne la poste. La commande d'un reroll de A n'est pas confiée.
5. [test] Dans la salle : une commande relayée est créée (jamais modifiée) et tracée « via B » ; un LFW
   relayé entre dans une entrée « via B » qui expire en 25 min, sans jamais remplacer une entrée
   directe ; un LFW direct remplace l'entrée relayée ; `LFW off` relayé n'efface qu'une entrée relayée.
   Au-delà de 30 entrées par relais par 10 min, le reste est ignoré. Une commande nommée relayée et
   une enveloppe au nom d'une source de mon royaume sont ignorées. Rien n'est relayé de nouveau.
6. [test] Un relais qui n'a pas répondu n'est plus choisi au rafraîchissement suivant (30 min).
7. [test] Vérification : agir sur un LFW relayé (bouton Chuchoter) envoie `VRF` à A, une fois par
   entrée ; A répond oui si son LFW est actif sur ce métier, non sinon ; sur un non, l'entrée disparaît,
   B est ignoré comme relais pendant 24 h chez D, et A ne choisit plus B pendant 24 h s'il lui avait
   confié quelque chose (sinon, pas de blâme côté A). Si A avait bien confié ce LFW à B il y a moins de
   35 min, même s'il a changé de métier depuis, il répond « périmé » : l'entrée disparaît, personne
   n'est blâmé.
8. [humain] Au banc, trois comptes : Gnoma (4618) passe en LFW ; Rédemption (4620) est son relais ;
   Toao (4620) ne la connaît pas. **Observé** : Toao voit Gnoma en LFW (onglet Artisans, « via
   Rédemption Wafhien ») ; traces : `RL|Gnoma Short|…` chuchoté par Gnoma, posté par Rédemption, reçu
   par Toao. Témoin : la v1.46.0, où Toao ne voit pas le LFW de Gnoma. ⚠️ Les SavedVariables sont par
   compte et le 4e compte connaît Gnoma depuis 15:42 : il faut d'abord que Gnoma et Toao s'oublient
   (après le `/reload` et 30 s, des deux côtés :
   `/run local D=CraftingOrderClassic.Directory n="<l'autre>" D.roster[n]=nil D.online[n]=nil`, astuce
   du 2026-09-30), sinon le LFW arrive en direct et le test ne prouve rien.
9. [humain] Un faux relais : Gnoma n'est PAS en LFW, et Gnomi (4620, à qui Gnoma n'a rien confié) poste
   en `/run` un `RL|Gnoma Short|…|LFW|on|…` dans sa salle. Toao clique sur Chuchoter : l'entrée
   disparaît, la trace de Toao dit « VRF : Gnoma Short dément, relais Gnomi Short écarté ».

## Contrat

Tout ce qui suit atteint des clients installés : figé une fois publié.

- **Savoir relayer** : morceau `rl=1` dans la fiche de métiers, juste après `rm=<id>;` :
  `SK|lvl=<n>|rm=<id>;rl=1;<métier>,<cur>,<max>;…`. Ignoré par un client d'avant (pas de virgule).
  Absent d'un `HI` sans métier (le lecteur v1.46.0 de `HI|rm=` est strict) : un porteur sans métier
  n'est pas choisi comme relais.
- **Enveloppe** : `RL|<A>|<n>|<message>`, où `<A>` est le nom complet de la source, `<n>` un numéro
  propre à A (dédoublonnage ; croissant, parti de l'heure réelle de A pour survivre à un `/reload`),
  `<message>` = `LFW|on|<métier>` (clé de la lib), `LFW|off` ou `ORD|NEW|…` (acheteur = A, « Tous »).
  Chuchotée par A au relais, puis postée telle quelle par le relais dans sa salle.
- **Accusé** : `RLA|<n>`, chuchoté par le relais à A après avoir posté.
- **Vérification** : `VRF|<métier>|<relais>` de D à A ; réponse `VRF|ok|<métier>`, `VRF|no|<métier>|old`
  (copie périmée, personne n'est blâmé) ou `VRF|no|<métier>` (le relais a menti).

## Plan (2026-10-07, à jeter une fois livré)

Un seul palier, branche `feat/relais-confiance` (COC + outillage) : module `Directory_TrustRelay.lua`
(source, relais, salle, vérification), `rl=1` dans `Directory_Skills.lua`, branchements dans
`Directory_LFW.lua` (`_BroadcastLFW`), `Orders_Net.lua` (`Broadcast` NEW « Tous »), `UI_Artisans.lua`
(bouton Chuchoter) et les infobulles (« via »). Test `tests/test_relais_confiance.lua`. Banc : critères 8
et 9 par l'appli du banc.

## Renvois

- Spec `pont-royaumes.md` (publiée en v1.46.0) : présentation, bonjour léger, élection, plafonds.
- Spec `lfw-forever.md` : LFW, offre `LFO` / `LFR`, durée de vie côté récepteur (20 min).
- `Orders_Net.lua` : `_OnNew` (création par un tiers, rejet d'une commande usurpée sur la salle),
  `_OnUnknownCycle` (annulation renvoyée, v1.45.0).
- `Directory_Relay.lua` : le précédent du relais des fiches (`RLY`), « pas de relais de relais ».
