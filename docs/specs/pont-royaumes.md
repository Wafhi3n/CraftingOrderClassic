# Pont entre royaumes : présenter un arrivant aux autres salles

> État : **approuvée** (décisions D2 et D4 à D9 prises par le user le 2026-10-07) · Rédigée le
> 2026-10-07 · Idée du user (le pont par whisper), le 2026-10-07 · Palier 1 **publié en v1.45.0** ·
> Palier 2 codé, **vu en jeu le 2026-10-07** (registre, GO partiel), relu par l'agent protocole (D12) ·
> Palier 3 codé (`Directory_Bridge.lua`, `tests/test_pont_royaume_passeur.lua`), pas vu en jeu
> Cible : WoW: Forever / Camelot (16001) · Addon : Crafting Order - Classic (+ lib CraftLink, peu)
>
> Origine : mesures du 2026-10-07 avec trois comptes. Sous le méga-serveur de Forever, les royaumes
> existent toujours, et un canal s'arrête au royaume : notre salle `CraftLinkNet`, et aussi le canal
> Commerce du jeu. Faits datés dans le skill public `wow-addon-dev:wow-forever-api`,
> `references/chat-channels-and-communities.md`, section « A channel stops at your realm ».

## Le problème

Le joueur choisit PvE ou PvP à la création, et le jeu lui attribue un royaume qu'il ne voit pas
(« Classic Beta PvE », « Classic Beta PvE 2 »…). Le royaume suit le **compte**. Deux joueurs du même
type de royaume peuvent jouer côte à côte, dans la même ville, et ne jamais se rencontrer par COC :

- la **salle de découverte** (`CraftLinkNet`) n'existe qu'en une copie par royaume ;
- le canal **Commerce** du jeu aussi : une annonce `#CO` n'atteint que le royaume de son auteur ;
- les messages « à tous » partent en whisper vers les pairs **déjà connus**, et le whisper traverse
  les royaumes. Mais un inconnu d'un autre royaume ne devient jamais connu, sauf si on le survole,
  qu'on le cible ou qu'on groupe avec lui.

Vu le 2026-10-07 : Gnoma (royaume 4618) ne trouve dans sa salle que des joueurs de 4618 ; elle n'a
connu Gnomi (4620) qu'en la croisant à Dun Morogh.

## Ce qu'on veut

Quand un porteur de COC arrive dans la salle de son royaume, les porteurs des **autres** royaumes
du même camp finissent par le connaître, eux aussi, sans que personne ne fasse rien.

Le chemin, celui que le user a proposé :

1. C arrive dans la salle de son royaume R1 et y dit bonjour (c'est déjà le cas).
2. Un membre A de R1, qui connaît un porteur B en ligne dans un autre royaume R2, chuchote à B :
   « présente C dans ta salle ».
3. B poste dans la salle de R2 une **présentation** : le nom de C et son royaume, rien d'autre.
4. Chaque membre D de R2 qui ne connaît pas C échange avec lui un **bonjour léger**, en direct, par
   whisper. D et C se connaissent ; la suite (commandes, LFW, cooldowns) passe par les chemins
   existants, qui chuchotent déjà aux pairs connus, quel que soit leur royaume.

Pour savoir qui est dans quel royaume, chaque porteur ajoute à son bonjour le numéro de son
royaume (`GetRealmID()`).

## Ce qu'on NE fait PAS

- **Relayer des données.** Le pont présente des gens, il ne transporte ni commandes (`ORD|`), ni
  LFW, ni fiches de métiers. Elles passent ensuite en direct, comme aujourd'hui. **Piste du user
  pour plus tard (2026-10-07)** : des **nœuds de confiance** qui répéteraient les commandes dans la
  salle `CraftLinkNet` de chaque royaume, pour qu'une commande publique atteigne aussi les inconnus
  des autres royaumes. Hors de cette spec : il faudra décider qui est de confiance et comment, ce
  qu'on fait d'une commande répétée par un nœud qui ment, et combien de messages ça coûte. Une spec
  à part le jour où on s'y met.
- **Relayer les annonces Commerce `#CO`** d'un royaume à l'autre. Une ligne de texte est l'affaire
  du joueur qui l'écrit.
- **Plusieurs sauts.** Une présentation reçue ne déclenche jamais une autre présentation.
- **Représenter les présents.** Seule une arrivée déclenche le pont ; les membres déjà là sont
  présentés au fil de leurs propres connexions.
- **Traverser les camps.** Le whisper ne passe pas d'un camp à l'autre ; A ne choisit qu'un B de
  son camp.
- **Fixer le nombre de royaumes.** Aucune API ne les liste, et il y en aura peut-être d'autres à la
  sortie (le 4 novembre). Les royaumes se découvrent au fil des bonjours.
- **Atteindre un royaume dont on ne connaît personne.** Tant qu'aucun porteur du réseau n'y a
  jamais croisé quelqu'un, il reste hors d'atteinte. C'est la limite honnête du système.

## Cas particuliers

- **Ancien client** (bonjour sans royaume) : il n'a pas de royaume connu. Il n'est jamais choisi
  comme passeur, et son arrivée ne déclenche pas de pont. Il ignore les verbes nouveaux (le
  dispatch d'un verbe inconnu ne fait que tracer, vérifié dans `CraftLink_Transport.lua`).
- **Salle coupée** (`/co channel room off`) : pas de pont depuis lui (il ne voit pas les arrivées),
  et s'il reçoit une présentation à poster, il ne la poste pas.
- **B est hors ligne** ou ne répond plus : la présentation est perdue pour cette arrivée. Pas de
  file, pas de nouvel essai : la prochaine connexion de C refera un pont.
- **Plusieurs A** dans R1 voient la même arrivée : ils ne doivent pas tous chuchoter (voir
  décision D6). Côté R2, un B qui voit déjà dans sa salle la présentation de C, postée par un
  autre, ne la reposte pas.
- **Présentation forgée** (un client malveillant présente des noms inventés) : chaque membre de R2
  chuchoterait à des noms qui n'existent pas. Garde-fous : nom complet obligatoire
  (`COC.Api.IsFullPlayerName`), plafond de présentations par émetteur et par fenêtre de temps,
  et jamais de présentation pour un joueur déjà connu. Une présentation n'écrit **rien** dans la
  fiche du joueur présenté : elle ne fait que déclencher un bonjour.
- **Message coupé à 255 octets** : le jeu coupe sans prévenir. La présentation est courte (un nom,
  un nombre). Le numéro de royaume se place au **début** de la fiche de métiers, jamais à la fin,
  où une coupure le rendrait faux (`rm=4618` → `rm=46`).
- **Un royaume qui contiendrait plusieurs salles** : jamais vu (chaque cas mesuré colle avec « une
  salle par royaume »), mais pas exclu. Le pont ne s'en sert pas comme vérité absolue : une
  présentation qui arrive à quelqu'un qui connaît déjà C ne fait rien.

## Décisions

- **D1 (user, 2026-10-07)** : relier les salles par whisper, en faisant répéter une information
  dans la salle d'un autre royaume. Idée du user.
- **D2 (user, 2026-10-07)** : ce qui traverse est une **présentation** (un nom, un royaume),
  pas les données. Raison : les données passent déjà en whisper entre pairs connus, quel que soit
  leur royaume ; le seul trou est l'inconnu. Et une présentation forgée ne peut rien écrire de faux.
- **D3 (mesure, 2026-10-07)** : le royaume d'un joueur = `GetRealmID()` (la partie serveur de son
  GUID), envoyé par lui-même dans son bonjour. Le nom d'un joueur ne porte pas son royaume sur
  Forever, et `CHAT_MSG_ADDON` ne donne pas de GUID.
- **D4 (user, 2026-10-07)** : le pont vit dans **COC** (l'annuaire, `Directory_*.lua`), à côté
  du relais `RLY`. Raison : le bonjour, l'annuaire (qui est connu, en ligne, de quel royaume) et
  le côté produit de la salle y sont déjà. CraftLink transporte et rejoint la salle ; elle n'a
  rien à apprendre. Autre choix possible : mettre le pont dans CraftLink pour qu'un futur addon
  l'ait aussi ; COC est aujourd'hui le seul à embarquer la lib.
- **D5 (user, 2026-10-07)** : après une présentation, D et C échangent un **bonjour léger**
  (un message chacun, la fiche de métiers seule), pas le bonjour complet d'aujourd'hui. Raison :
  un bonjour complet fait répondre C par toute sa fiche (métiers, recettes, cooldowns) et les
  fiches de ses partenaires, soit 10 à 35 whispers par membre de R2. Avec 30 membres, C enverrait
  des centaines de messages en quelques secondes. Les recettes viennent plus tard, à la demande
  (sélectionner un artisan en ligne le relance déjà) ou avec la prochaine annonce de C.
- **D6 (user, 2026-10-07)** : **un seul passeur par arrivée et par royaume étranger**, en visée.
  **L'arrivant se présente lui-même** quand il connaît déjà un porteur en ligne dans l'autre
  royaume : il chuchote « présente-moi » à un seul d'entre eux par royaume. C'est le cas le plus
  simple, et le seul que le banc peut voir de bout en bout (critère 12). **Déclencheur** : à la
  connexion, l'arrivant ne sait pas encore qui est en ligne ailleurs ; il l'apprend par les réponses
  à ses bonjours de connexion. La **première réponse directe** qui porte un `rm=` différent du sien,
  dans les 2 minutes qui suivent le **chargement de l'addon** (connexion ou `/reload` ; corrigé au
  codage : les réponses aux bonjours de connexion arrivent souvent AVANT la salle, qui attend jusqu'à
  10 s que le /1 soit pris), déclenche la demande vers ce pair-là, une seule par royaume étranger et
  par session (et pas avant 6 heures, D7). Ce pair porte forcément la nouvelle version : seule elle
  envoie `rm=`. Pour un arrivant qui ne
  connaît personne ailleurs, un membre de sa salle le fait : A agit seulement s'il est élu dans sa
  salle, le **plus petit nom** parmi les membres en ligne de son royaume qui portent la nouvelle
  version. Un double passage reste possible si deux membres n'ont pas la même vue ; le
  dédoublonnage côté R2 l'absorbe. Écartés : l'arrivant seul (un tout nouveau joueur ne serait
  jamais présenté) et le tirage au sort entre tous (plus de messages).
- **D7 (user, 2026-10-07) — le budget** : pour une arrivée, au plus 1 présentation chuchotée et
  1 présentation postée par royaume étranger, puis au plus 2 messages par paire (D, C). C envoie au
  plus un message par membre de R2 qui ne le connaissait pas, étalés par la file d'envoi. Aucun
  autre message ne part à cause du pont, **sauf** la pousse des commandes (D9). Contre les abus : **au plus 10 présentations acceptées par
  émetteur par tranche de 10 minutes**, le reste est ignoré. Et **une même personne n'est pas
  représentée plus d'une fois toutes les 6 heures** : un joueur qui se connecte cinq fois dans la
  journée ne coûte pas cinq présentations. Cette date-là est **gardée dans les SavedVariables**
  (heure réelle, `time()`), chez l'arrivant (par royaume visé) comme chez le passeur (par personne
  postée) : une minuterie de session (`GetTime()`) repartirait de zéro à chaque connexion, et le test
  headless passerait quand même.
- **D9 (user, 2026-10-07)** : le bonjour léger **garde** la pousse des commandes. Le premier message
  d'un pair qui n'était pas « en ligne » chez moi lui envoie mes commandes ouvertes qui le concernent
  (`Orders:OnArtisanOnline`, via `Dir:_Touch`, au plus une fois par minute et par pair). Après une
  présentation, ça joue chez C comme chez chaque D. On le garde : faire connaître ses commandes aux
  autres royaumes, c'est l'intérêt du pont, et peu de joueurs ont des commandes ouvertes. Le budget
  D7 le compte à part (critère 10).
- **D10 (codage du palier 2, 2026-10-07)** : tant que le passeur élu (palier 3) n'existe pas, une
  demande « présente-moi » n'est acceptée **que de l'arrivant lui-même** (l'émetteur du whisper EST le
  nom présenté). Un tiers ne peut donc pas faire poster le nom de quelqu'un d'autre. **Palier 3
  (codé le 2026-10-07)** : une demande pour un AUTRE est acceptée d'un pair que le passeur connaît en
  direct (`lastSeen`) et dont le royaume (lu dans SA fiche) est celui du présenté. Un menteur de ce
  royaume peut encore faire présenter un nom inventé : borné par le plafond de 10 par émetteur, et par
  la garde « un bonjour par nom et par 10 min » de la salle d'en face (D12).
- **D13 (codage du palier 3, 2026-10-07)** : l'élection. Candidats : moi, et les porteurs de mon
  royaume que je vois en ligne (royaume connu dans leur fiche = ils sont à jour), sauf l'arrivant ; le
  plus petit nom (comparaison d'octets, la même chez tous) est élu. Déclencheur : le bonjour de SALLE
  d'un arrivant qui porte mon royaume (un arrivant d'avant, sans `rm=`, ne répondrait pas aux bonjours
  légers : pas présenté). L'élu le présente à un passeur en ligne par royaume étranger, un ami ou un
  membre de sa guilde d'abord, sinon le plus récemment vu ; au plus 5 royaumes. Une fois par arrivant
  et par 6 h (SavedVariables, posé seulement si une demande est partie).
- **D11 (codage du palier 2, 2026-10-07)** : un membre D qui reçoit un bonjour léger dans ses propres
  2 minutes de chargement peut, lui aussi, se présenter dans le royaume de C. C'est une
  auto-présentation légitime (D connaît maintenant quelqu'un là-bas), bornée par les mêmes règles :
  une par royaume et par session, une par 6 h.
- **D12 (relecture protocole du palier 2, 2026-10-07)** :
  - le verrou de 6 h de l'arrivant ne se pose qu'à la **confirmation** (un bonjour léger reçu de ce
    royaume) ; à l'envoi de la demande, 10 min seulement. Sans confirmation après 30 s, un second
    passeur du même royaume est essayé, jamais un troisième. Sinon un pair qui ment sur son royaume,
    ou un passeur qui part, faisait perdre la présentation pour 6 h ;
  - un membre ne dit bonjour qu'une fois par nom et par 10 min, quel que soit le nombre de
    présentations postées, et jamais à un nom présenté comme de son propre royaume ; au plus 20
    bonjours légers spontanés par minute, tous noms confondus (les réponses ne comptent pas : elles
    sont bornées à une par pair et par 10 min). Sinon un menteur faisait chuchoter toute la salle vers
    une victime à chaque repost ;
  - une présentation n'est lue que par whisper (demande) ou sur la salle, jamais par groupe ou
    guilde, et un numéro de royaume démesuré est ignoré.
  - le verrou de l'arrivant est rangé **par personnage** (`<nom>@<royaume>`) : la SavedVariable est
    commune au compte, et un perso présenté bloquait les autres persos du compte (vu au banc le
    2026-10-07, corrigé le même jour).
  Accepté : un bonjour léger d'un inconnu entre dans l'annuaire et reçoit une réponse (comme un HI
  chuchoté), et un bonjour léger forgé avec le bon royaume peut confirmer trop tôt une présentation.
- **D8 (user, 2026-10-07)** : **pas de réglage à part.** Le pont suit la salle de découverte :
  `/co channel room off` le coupe aussi. Raison : moins de réglages, et sans salle le pont n'a ni
  arrivées à voir ni salle où poster.

## Critères d'acceptation

1. [test] La fiche de métiers porte `rm=<id>` comme premier élément après `lvl=`, et un client
   d'avant la lit sans erreur, avec les mêmes métiers (le parseur actuel ignore ce morceau).
2. [test] Un bonjour sans métiers porte `HI|rm=<id>` ; un client d'avant l'accepte comme un `HI` nu.
3. [test] La plus grande fiche de métiers possible (deux métiers principaux aux noms les plus
   longs, Cuisine, Secourisme, Pêche, Poisons, `rep=`, `cv=`, `rm=`) tient sous 255 octets, bonjour
   et enveloppe de relais `RLY` compris. → `tests/test_pont_royaume_bonjour.lua` (critères 1 à 3 ;
   pire bonjour mesuré : 157 octets).
4. [test] Une arrivée dans la salle (bonjour reçu par le canal, royaume connu) déclenche une
   présentation vers un seul pair en ligne par royaume étranger, du même camp ; aucune vers le
   royaume de l'arrivant. Un arrivant qui connaît déjà un porteur en ligne d'un autre royaume se
   présente lui-même à un seul d'entre eux par royaume. Les membres de sa salle ne savent pas qu'il
   l'a fait : s'ils le présentent aussi, la salle étrangère n'en poste qu'une (critère 6).
5. [test] Une présentation reçue (chuchotée ou postée) ne déclenche jamais une autre présentation
   chuchotée. Un bonjour reçu en whisper non plus.
6. [test] Une présentation chuchotée est postée dans la salle seulement si la salle est rejointe,
   après un court délai aléatoire, et pas si la même présentation y a été vue entre-temps ou dans
   les 10 dernières minutes : deux passeurs pour le même arrivant donnent un seul message posté.
7. [test] Une présentation postée fait partir un bonjour léger vers C chez un membre qui ne connaît
   pas C, après un délai aléatoire ; rien chez un membre qui le connaît déjà.
8. [test] Un bonjour léger reçu reçoit au plus un bonjour léger en retour, jamais l'annonce
   complète ni les fiches des partenaires, et ne déclenche aucune découverte.
9. [test] Une présentation d'un nom incomplet (prénom seul, « Unknown ») est ignorée ; au-delà du
   plafond par émetteur, les présentations sont ignorées et tracées une fois.
10. [test] Budget D7 : une arrivée simulée dans une salle de 30 membres étrangers produit au plus
    1 + 1 + 2 × 30 messages du pont (présentations et bonjours légers), et C en émet 1 demande et au
    plus 30 bonjours légers. La pousse des commandes (D9) se compte à part : sans commande ouverte,
    elle n'envoie rien. → critères 4 (part « lui-même ») à 10ter : `tests/test_pont_royaume_presentation.lua`.
10bis. [test] D7 : une même personne n'est pas représentée moins de 6 heures après sa dernière
    présentation, quel que soit le nombre de ses connexions (le test recharge l'addon entre deux
    connexions, SavedVariables gardées, horloge `time()` avancée) ; au-delà de 10 présentations d'un
    même émetteur en 10 minutes, les suivantes sont ignorées.
10ter. [test] D8 : salle coupée (`/co channel room off`), aucune présentation ne part et aucune
    présentation reçue n'est postée.
11. [humain] Rédemption (4620) en ligne, qui connaît Gnoma (4618). Gnoma se connecte. **Observé** :
    la trace de Gnoma dit « présentation demandée à Rédemption Wafhien (royaume 4620) », celle de
    Rédemption dit « présentation de Gnoma Short (royaume 4618) postée dans la salle » avec
    `[send] room : INT|Gnoma Short|4618`. Témoin : sans le pont (v1.45.0), aucune de ces lignes.
    Observateur : le user, au banc, traces relues dans les SavedVariables.
12. [humain] Un membre de la salle étrangère découvre l'arrivant. Le banc a de quoi le voir depuis
    le 2026-10-07 : le 4e compte (Sfdfs Sdfdsfd) est tombé en 4620, comme Rédemption et Gnomi ; seule
    Gnoma est en 4618. Scénario : Rédemption et Sfdfs en ligne, Sfdfs n'a jamais croisé Gnoma (vérifier
    qu'elle n'est pas dans son annuaire) ; Gnoma se connecte et **se présente elle-même** (D6) à
    Rédemption, qui poste la présentation dans la salle 4620. **Observé attendu** chez Sfdfs : la ligne
    « bonjour léger → Gnoma Short (présenté par Rédemption Wafhien) », puis Gnoma dans son onglet
    Artisans, avec son royaume dans sa fiche (et ses métiers si elle en a) ; chez Gnoma, « bonjour
    léger de Sfdfs Sdfdsfd : un bonjour léger en retour ». Témoin :
    le même scénario sur le build d'avant le pont, **à mesurer avant de coder** (le relais `RLY` ou la
    propagation des commandes pourraient déjà lui faire connaître Gnoma). Au 2026-10-07 13:30, Gnoma
    est absente de l'annuaire de Sfdfs. Observateur : le user, au banc, traces des trois comptes
    relues dans les SavedVariables.
13. [test] Palier 3 : un arrivant à jour dans ma salle est présenté par l'élu seul, à un passeur par
    royaume étranger (l'ami d'abord), une fois par 6 h même après un `/reload` ; un non-élu, un arrivant
    sans royaume, un bonjour chuchoté ou un autre royaume ne déclenchent rien ; au plus 5 royaumes ; la
    salle d'en face n'accepte la demande pour un autre que d'un pair connu du même royaume.
    → `tests/test_pont_royaume_passeur.lua`.
14. [humain] Palier 3 au banc : un perso NEUF sur le 4e compte (royaume 4620, ne connaît personne en
    4618), Gnomi et Rédemption en ligne (4620 ; « Gnomi Short » est le plus petit nom, donc l'élue),
    Gnoma en ligne (4618, connue de Gnomi). Le perso neuf se connecte. **Observé attendu** : chez Gnomi,
    « présentation de <perso neuf> demandée à Gnoma Short (royaume 4618) : passeur élu » ; chez
    Rédemption, aucune ligne de ce genre ; chez Gnoma, « présentation de <perso neuf> (royaume 4620)
    postée dans la salle ». Pas observable avec nos comptes : un membre de 4618 qui salue l'arrivant
    (le 3e compte est le seul en 4618). Observateur : le user, au banc, traces des quatre comptes.

## Contrat

Tout ce qui suit atteint des clients déjà installés : figé une fois publié.

- **Royaume dans la fiche de métiers** : `SK|lvl=<n>|rm=<id>;<métier>,<cur>,<max>;…[;rep=<n>][;cv=<v>]`.
  `rm=` est le **premier** morceau. Un client d'avant l'ignore (son parseur ne garde que les
  morceaux `clé,cur,max`, `rep=` et `cv=` : vérifié de la v1.30 à la v1.44.2). Un `SK` relayé par
  `RLY` n'en porte **pas** (décidé au codage du palier 1, 2026-10-07) : le royaume ne vaut que pour
  celui qui l'annonce, et le relais ne sert qu'aux partenaires hors ligne, dont le pont n'a pas
  besoin. Un royaume reçu n'est gardé que d'une fiche directe.
- **Bonjour sans métiers** : `HI|rm=<id>` (aujourd'hui `HI` nu).
- **Présentation** : `INT|<Prénom Nom>|<id>`, dans un whisper de A vers B (« poste-la ») ou sur la
  salle, postée par B (« un nouveau d'un autre royaume »). Le même verbe, distingué par la portée.
  Le nom est complet ; `<id>` est le royaume du présenté.
- **Bonjour léger** : verbe nouveau, à nommer au moment du code (par exemple `HL`), corps = une
  fiche de métiers (`SK|…`, avec `rm=`). N'appelle pas de réponse complète.
- Aucun champ ne fait foi pour une **autre** personne que l'émetteur : la présentation n'écrit rien
  dans la fiche du présenté.

## Renvois

- Skill `wow-addon-dev:wow-forever-api`, `references/chat-channels-and-communities.md` : royaumes,
  canaux par royaume, numéros de canaux gardés, coupure à 255 octets, « No player named » 110 s plus
  tard.
- Spec `communaute-sans-canal.md` : le réseau en whisper et la salle de découverte.
- `Directory_Relay.lua` : le précédent du relais (`RLY`), « pas de relais de relais ».
- `Directory_Room.lua` : la salle de découverte côté produit.
- Mémoire du user sur le bruit réseau : envoyer dirigé, regrouper, jamais « à tous » sur un
  événement local.

## Plan (2026-10-07, à jeter une fois livré)

Trois paliers, chacun tient en une séance et se teste seul. Branche `feat/pont-royaumes` dans COC
et l'outillage (les tests), même nom ; CraftLink n'est touchée que si un palier en a besoin.

1. **Le royaume dans le bonjour.** `rm=<id>` en tête de la fiche de métiers, `HI|rm=<id>` sans
   métiers, lu et gardé dans l'annuaire (le royaume de chaque pair). Rien d'autre ne change :
   publiable seul, et chaque client à jour se met à annoncer son royaume avant que le pont existe.
   Critères 1 à 3.
2. **L'arrivant se présente lui-même, et la salle étrangère le découvre.** Verbe `INT` (chuchoté
   puis posté, dédoublonné), bonjour léger, plafonds D7, coupure D8. Critères 5 à 9, 10bis, 10ter,
   la part « lui-même » du 4 ; au banc, 11 et 12.
3. **Le passeur élu** pour l'arrivant qui ne connaît personne ailleurs (plus petit nom de la salle).
   Critères 4 (complet) et 10.
