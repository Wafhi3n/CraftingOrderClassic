# Relais de confiance : faire passer le LFW et les commandes publiques d'une salle à l'autre

> État : **brouillon** · Rédigé le 2026-10-07 · Idée du user, le 2026-10-07 (« définir des nœuds de
> confiance qui répètent les commandes dans le canal CraftLink des différents royaumes », et la
> vérification au clic) · Les décisions marquées « proposée » attendent le user
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
  dans une salle étrangère.
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
- **D-R2 (proposée)** : ce qui passe : le LFW (on / off) et les commandes publiques « Tous ». Rien
  d'autre (voir « Ce qu'on NE fait PAS »).
- **D-R3 (proposée)** : **A choisit ses relais**, un par royaume étranger : un ami ou un membre de sa
  guilde d'abord, sinon le porteur à jour le plus récemment vu, en ligne. Option plus stricte :
  seulement des amis ou des membres de guilde (moins de portée, plus de confiance).
- **D-R4 (proposée)** : **une enveloppe** `RLY2|<A>|<n>|<message>` (verbe à nommer) : A la chuchote au
  relais, le relais la poste telle quelle dans sa salle. À la réception sur la salle : le message
  intérieur est traité comme venant de A **par un tiers** (une commande est créée, jamais modifiée,
  comme un relais par chuchotement aujourd'hui ; un LFW entre dans une entrée « relayée par B »,
  jamais dans l'entrée directe de A). Nécessaire aussi pour les commandes : une commande postée dans
  la salle par un autre que l'acheteur y est aujourd'hui rejetée comme usurpation
  (`Orders_Net.lua`, `_OnNew`).
- **D-R5 (proposée)** : **la vérification au clic**. Quand D agit sur une entrée relayée (chuchoter,
  commander à A, ouvrir son offre), COC chuchote d'abord à A « tu es bien en LFW ? » ; A répond oui ou
  non. Sur un non : l'entrée disparaît chez D, D écarte B comme relais (24 h), et A note que B a menti
  (il ne le choisit plus). Pour une commande, rien de neuf : l'acceptation part à l'acheteur, qui
  renvoie une annulation s'il ne la connaît pas (v1.45.0).
- **D-R6 (proposée)** : **le rythme**. Une commande : relayée une fois à sa publication (et à la
  republication de A toutes les 2 h). Un LFW : relayé à l'activation, puis toutes les 15 min tant
  qu'il est actif (l'entrée relayée expire après 25 min sans rafraîchissement). Si un relais n'a rien
  posté (aucun membre de sa salle ne l'a vu), A en choisit un autre au rafraîchissement suivant.
- **D-R7 (proposée)** : **plafonds**. Chez le relais : au plus 6 enveloppes par source et par 10 min,
  30 en tout. Chez un membre de la salle : au plus 10 entrées relayées par relais et par 10 min.
- **D-R8 (proposée)** : **ce que voit le joueur**. Une entrée relayée s'affiche comme les autres (plaque
  LFW, liste des commandes), avec dans son infobulle « via <relais> », sans le mot royaume.
- **D-R9 (proposée)** : **savoir relayer**. Un porteur à jour l'annonce dans sa fiche de métiers par
  un petit morceau (par exemple `rl=1`, placé avant les métiers comme `rm=`), ignoré par les clients
  d'avant. Pas la version (`cv=`) : les builds du banc la taisent depuis la v1.46.0.
- **D-R10 (proposée)** : pas de réglage à part ; suit la salle de découverte (`/co channel room off`).

## Critères d'acceptation

À écrire une fois les décisions prises.

## Contrat

À écrire une fois les décisions prises (l'enveloppe, la vérification, le morceau `rl=`).

## Renvois

- Spec `pont-royaumes.md` (publiée en v1.46.0) : présentation, bonjour léger, élection, plafonds.
- Spec `lfw-forever.md` : LFW, offre `LFO` / `LFR`, durée de vie côté récepteur (20 min).
- `Orders_Net.lua` : `_OnNew` (création par un tiers, rejet d'une commande usurpée sur la salle),
  `_OnUnknownCycle` (annulation renvoyée, v1.45.0).
- `Directory_Relay.lua` : le précédent du relais des fiches (`RLY`), « pas de relais de relais ».
