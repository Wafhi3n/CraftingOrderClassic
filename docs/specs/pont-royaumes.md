# Pont entre royaumes : présenter un arrivant aux autres salles

> État : **brouillon** · Rédigé le 2026-10-07 · Idée du user (le pont par whisper), le 2026-10-07 ·
> Les décisions marquées « proposée » attendent le user
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
  LFW, ni fiches de métiers. Elles passent ensuite en direct, comme aujourd'hui.
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
- **D2 (proposée, 2026-10-07)** : ce qui traverse est une **présentation** (un nom, un royaume),
  pas les données. Raison : les données passent déjà en whisper entre pairs connus, quel que soit
  leur royaume ; le seul trou est l'inconnu. Et une présentation forgée ne peut rien écrire de faux.
- **D3 (mesure, 2026-10-07)** : le royaume d'un joueur = `GetRealmID()` (la partie serveur de son
  GUID), envoyé par lui-même dans son bonjour. Le nom d'un joueur ne porte pas son royaume sur
  Forever, et `CHAT_MSG_ADDON` ne donne pas de GUID.
- **D4 (proposée, 2026-10-07)** : le pont vit dans **COC** (l'annuaire, `Directory_*.lua`), à côté
  du relais `RLY`. Raison : le bonjour, l'annuaire (qui est connu, en ligne, de quel royaume) et
  le côté produit de la salle y sont déjà. CraftLink transporte et rejoint la salle ; elle n'a
  rien à apprendre. Autre choix possible : mettre le pont dans CraftLink pour qu'un futur addon
  l'ait aussi ; COC est aujourd'hui le seul à embarquer la lib.
- **D5 (proposée, 2026-10-07)** : après une présentation, D et C échangent un **bonjour léger**
  (un message chacun, la fiche de métiers seule), pas le bonjour complet d'aujourd'hui. Raison :
  un bonjour complet fait répondre C par toute sa fiche (métiers, recettes, cooldowns) et les
  fiches de ses partenaires, soit 10 à 35 whispers par membre de R2. Avec 30 membres, C enverrait
  des centaines de messages en quelques secondes. Les recettes viennent plus tard, à la demande
  (sélectionner un artisan en ligne le relance déjà) ou avec la prochaine annonce de C.
- **D6 (proposée, 2026-10-07)** : **un seul passeur par arrivée et par royaume étranger**, en
  visée. A agit seulement s'il est élu dans sa salle (par exemple le plus petit nom parmi les
  membres en ligne de son royaume qui portent la nouvelle version). Un double passage reste
  possible si deux membres n'ont pas la même vue ; le dédoublonnage côté R2 l'absorbe. Variante :
  un tirage au hasard (chacun agit avec une probabilité qui vise deux passeurs en moyenne), plus
  tolérant aux vues différentes.
- **D7 (proposée, 2026-10-07) — le budget** : pour une arrivée, au plus 1 présentation chuchotée
  et 1 présentation postée par royaume étranger, puis au plus 2 messages par paire (D, C). C
  envoie au plus un message par membre de R2 qui ne le connaissait pas, étalés par la file
  d'envoi. Aucun autre message ne part à cause du pont.

## Critères d'acceptation

1. [test] La fiche de métiers porte `rm=<id>` comme premier élément après `lvl=`, et un client
   d'avant la lit sans erreur, avec les mêmes métiers (le parseur actuel ignore ce morceau).
2. [test] Un bonjour sans métiers porte `HI|rm=<id>` ; un client d'avant l'accepte comme un `HI` nu.
3. [test] La plus grande fiche de métiers possible (deux métiers principaux aux noms les plus
   longs, Cuisine, Secourisme, Pêche, Poisons, `rep=`, `cv=`, `rm=`) tient sous 255 octets, bonjour
   et enveloppe de relais `RLY` compris.
4. [test] Une arrivée dans la salle (bonjour reçu par le canal, royaume connu) déclenche une
   présentation vers un seul pair en ligne par royaume étranger, du même camp ; aucune vers le
   royaume de l'arrivant.
5. [test] Une présentation reçue (chuchotée ou postée) ne déclenche jamais une autre présentation
   chuchotée. Un bonjour reçu en whisper non plus.
6. [test] Une présentation chuchotée est postée dans la salle seulement si la salle est rejointe,
   et pas si la même présentation y a été vue dans les 10 dernières minutes.
7. [test] Une présentation postée fait partir un bonjour léger vers C chez un membre qui ne connaît
   pas C, après un délai aléatoire ; rien chez un membre qui le connaît déjà.
8. [test] Un bonjour léger reçu reçoit au plus un bonjour léger en retour, jamais l'annonce
   complète ni les fiches des partenaires, et ne déclenche aucune découverte.
9. [test] Une présentation d'un nom incomplet (prénom seul, « Unknown ») est ignorée ; au-delà du
   plafond par émetteur, les présentations sont ignorées et tracées une fois.
10. [test] Budget D7 : une arrivée simulée dans une salle de 30 membres étrangers produit au plus
    1 + 1 + 2 × 30 messages, tous types confondus, et C en émet au plus 30.
11. [humain] Rédemption (4620) dans sa salle, Gnoma (4618) en ligne et connue de Rédemption. Gnomi
    (4620) se connecte. **Observé** : la trace de Rédemption dit « présentation de Gnomi Short →
    Gnoma Short », celle de Gnoma dit « présentation postée dans la salle » et `[send] room :
    INT|Gnomi Short|4620`. Témoin : sans le pont (build d'avant), aucune de ces lignes. Observateur :
    le user, au banc, traces relues dans les SavedVariables.
12. [humain] **Pas observable avec nos comptes seuls** : un membre de la salle étrangère qui
    découvre l'arrivant. Il faut deux clients à jour dans le même royaume étranger, donc un 4e
    compte (de l'autre royaume PvE) ou un testeur du Discord. Observé attendu : chez ce membre, la
    ligne « bonjour léger → Gnomi Short » puis Gnomi dans son onglet Artisans avec ses métiers.

## Contrat

Tout ce qui suit atteint des clients déjà installés : figé une fois publié.

- **Royaume dans la fiche de métiers** : `SK|lvl=<n>|rm=<id>;<métier>,<cur>,<max>;…[;rep=<n>][;cv=<v>]`.
  `rm=` est le **premier** morceau. Un client d'avant l'ignore (son parseur ne garde que les
  morceaux `clé,cur,max`, `rep=` et `cv=`). Même place dans un `SK` relayé par `RLY`.
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
