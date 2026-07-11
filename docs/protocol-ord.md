# Protocole ORD — carnet de commandes P2P (Crafting Order - Classic)

Référence normative du format filaire des commandes. Le codec est `Orders_Codec.lua` (table `SPEC`,
`Codec.Encode` / `Codec.Decode`) ; ce document et ce fichier doivent rester en phase. Le transport
(canal `CraftLinkNet`, whisper, guilde) est fourni par CraftLink-1.0 ; ici on décrit uniquement la
charge utile `ORD|...`.

> ⚠️ **Non-régression.** Tout client publié parle cette grammaire. Un changement de champ = un
> `protocolVersion` bumpé et une compat rétro explicite. Le refactor codec de la v1.8.0 est
> **iso-fil** : mêmes octets qu'avant, à la virgule près.
>
> Le **durcissement du 2026-07-11** (revue usurpation/spam, 10 findings) ne touche **QUE les règles
> d'AUTORITÉ et de NOTIFICATION** — le **format filaire est inchangé**, donc **pas de bump** : un vieux
> client reste interopérable, il est juste plus permissif chez lui. Côté transport, `TRANSPORT_REV`
> passe à **10** (confinement royaume) — c'est un gate d'anti-clobber, pas un format.

## Grammaire filaire (état v1.7.1, gelé avant refactor)

Tous les messages commencent par `ORD|<VERBE>|`. Le verbe est extrait par `^ORD|([A-Z]+)|`.
Séparateur de champ = `|`. Les champs sont positionnels.

| Verbe | Encodage (champs, dans l'ordre) | Décodage (motif Lua) |
|---|---|---|
| **NEW** | `id`, `buyer`, `kind`, `itemID\|spellID\|0`, `qty\|1`, `profession\|""`, `price\|""`, `recipient\|"Tous"`, `byStack`(1/0), `provided`(CSV itemID) | `^ORD\|NEW\|([^\|]*)\|([^\|]*)\|([^\|]*)\|([^\|]*)\|([^\|]*)\|([^\|]*)\|([^\|]*)\|([^\|]*)\|(%d*)\|?([%d,]*)$` |
| **CANCEL** | `id` | `^ORD\|CANCEL\|(.+)$` |
| **ACK** | `id`, `acceptedBy\|""` | `^ORD\|ACK\|([^\|]*)\|(.*)$` |
| **DLV** | `id`, `acceptedBy\|""` | `^ORD\|DLV\|([^\|]*)\|(.*)$` |
| **DONE** | `id`, `acceptedBy\|""` | `^ORD\|DONE\|([^\|]*)\|(.*)$` |
| **NACK** | `id`, `who` (émetteur) | `^ORD\|NACK\|([^\|]*)\|(.*)$` |
| **SUGG** | `id`, `[captured]`(=`1` si entrante captée, sinon absent) | `^ORD\|SUGG\|([^\|]*)\|?(%d*)$` |

### Tolérances de rétro-compatibilité (à préserver telles quelles)

- **NEW** : le dernier séparateur et le champ `provided` sont **optionnels** (`|?([%d,]*)$`), et
  `byStack` tolère la valeur vide (`(%d*)`). Un émetteur antérieur à `provided` (`…|Tous|`, voire
  `…|Tous|0|`) reste parsable. Un champ `provided` ajouté en fin par une version future doit rester ce
  dernier champ optionnel.
- **CANCEL** : `id` est capturé en `(.+)` **gourmand** — un id contenant un `|` reste entier.
- **ACK / DLV / DONE / NACK** : le 2ᵉ champ est `(.*)` → **vide toléré** (l'émetteur envoie
  `acceptedBy or ""`).
- **SUGG** : le suffixe `|1` est optionnel (`|?(%d*)`).

### Normalisations à la réception (appliquées par le consommateur, pas par le codec)

Le codec **parse** (extrait les champs bruts) ; il n'applique ni défaut ni autorisation. Les
normalisations restent dans `Orders:_OnNew` / `_OnCycle` :
`kind ""→"item"`, `recipient ""→"Tous"`, `qty ""→1`, `profession ""→nil`, `price ""→nil`,
`byStack "1"→true`, `provided` CSV → liste d'itemID.

## Autorité de l'émetteur (anti-spoof) — invariant de sécurité

Le nom de l'émetteur (`sender`) est posé par le **transport** (nom court, non falsifiable) ; le champ
identité du **payload** n'est qu'un repli informatif. Les autorisations vivent dans `Orders:_OnCycle`
/ `_OnNack`, **jamais** dans le codec.

**Identité « joueur » (rerolls, verbe ALT).** Depuis v1.9.0, `sender == X` est élargi à
`Dir:SamePlayer(sender, X)` : vrai ssi les deux persos sont liés par des annonces ALT **réciproques**
(chacun cite l'autre — les deux annonces sortent de la même SavedVariable de compte, donc un tiers ne
peut pas usurper le lien). Un perso de MON compte se teste localement via `COC:IsMyChar` (lecture de ma
SV, jamais pilotable par le réseau). Sans opt-in `/co alts` et sans claim reçue, `SamePlayer` ≡ `==`.

| Transition | Qui a le droit | Précondition de statut |
|---|---|---|
| CANCEL → `cancelled` | `sender == o.buyer` **ou `SamePlayer`** (l'auteur ou son reroll) | — |
| DONE → `done` (+ crédit réputation) | `sender == o.buyer` **ou `SamePlayer`** ; **crédit ssi CE perso avait DÉJÀ accepté** : `IsMyChar(o.acceptedBy)` évalué **AVANT** l'écrasement par le `crafter` du payload, ET `status ∈ {accepted, delivered}` | `status ≠ done` |
| ACK → `accepted` | **nommé** : destinataire ou reroll lié (`SamePlayer(sender, recipient)`) ; **large** : n'importe qui (1er arrivé) | **`status == open`** (ferme le re-ACK/vol d'attribution) |
| DLV → `delivered` | **nommé** : destinataire OU accepteur (ou rerolls liés), sans précondition de statut (préserve « acheteur a raté l'ACK ») ; **large** : l'accepteur (ou reroll lié) uniquement | **large : `status == accepted`** ; entrée exclut `delivered` (idempotence) |
| NACK → réouverture / refus | `SamePlayer(who, o.acceptedBy)` réouvre ; ordre nommé (`who == recipient` ou lié, si `IsMyChar(buyer)`) refusé | refus : **`status ≠ declined`** (rejeu idempotent) |
| **NEW — CRÉATION d'un id INCONNU** | **n'importe qui** — `sender ≠ buyer` est LÉGITIME (relais mesh) | `not existed` |
| **NEW — MUTATION d'un id CONNU** | **`SamePlayer(sender, o.buyer` EN CACHE`)` EXIGÉ** — sinon message **ignoré**, champs intacts | `existed` |
| **NEW reçu en `CHANNEL`** | **`SamePlayer(sender, f.buyer)` EXIGÉ** — le canal n'est alimenté que par `Post`/`PostEntry`/`Cancel` sur ses PROPRES commandes (un reroll VÉRIFIÉ passe) | — |

> ### ⚠️ NEW : on garde la MUTATION, jamais la CRÉATION
>
> **Le piège central du protocole.** L'acheteur d'un `NEW` est un champ du **payload**, pas l'émetteur —
> et ça doit le rester : le **relais mesh** (`OnArtisanOnline`) pousse volontairement les commandes
> **d'AUTRUI** à un pair qui se connecte (`sender ≠ buyer`), c'est ce qui fait la propagation P2P quand le
> canal est muet. **Exiger `sender == buyer` sur `NEW` tuerait le relais.**
>
> La garde porte donc sur l'**écrasement** (durcissement 2026-07-11, `_OnNew`) : si l'`id` est **déjà en
> cache**, les champs (`buyer`, `price`, `qty`, `recipient`…) ne sont réécrits que si
> `SamePlayer(sender, o.buyer` **EN CACHE**`)`. C'est le buyer **mémorisé** qui fait autorité, jamais celui
> du payload (falsifiable). Sans ça, les `id` étant devinables (`Nom-seq`), n'importe qui réécrivait la
> commande d'autrui — y compris via le canal (poser `f.buyer = soi` passait l'ancienne garde canal).
>
> L'alerte reste **hors** de cette garde (idempotente via `o.alerted`) : un relais whisper doit pouvoir
> alerter une commande que le gate métier du canal avait refusée.

> **Anti-spam (`NotePost`) : seul un post DIRECT et NOUVEAU compte** — `not existed AND SamePlayer(sender,
> o.buyer)`. Un **relais** (`sender ≠ buyer`) ne compte pas la commande d'autrui contre son acheteur (sinon
> 25 relais en rafale mutaient un acheteur légitime), et un `buyer` **forgé** ne peut plus « framer » une
> victime jusqu'au mute automatique chez tous les porteurs.

> Durcissement v1.9.0 (revue protocole) : ACK exige un ordre **ouvert**, et un DLV en portée **large**
> exige que l'émetteur soit **l'accepteur** — fermant le vol d'attribution/réputation par un tiers. Le
> `captured=1` d'un `SUGG` n'est honoré que d'un émetteur **connu du roster** (`_OnSuggest`).

### Notifications : jamais rejouables (durcissement 2026-07-11)

Un message réseau est **rejouable** par nature (rien n'empêche un pair d'en renvoyer 50). Toute
notification (chat/toast/son) doit donc être gardée par une **transition réelle** + une **dédup** +
`Moderation:IsMuted` :

- **NACK** : notifie l'acheteur **uniquement** si le NACK a produit une transition (`moved`) — un NACK
  d'un tiers non lié, ou rejoué sur une commande déjà `declined`, est **muet**. Rien d'un joueur muté.
- **SUGG** (`Handoff:AlertCapable`) : dédup `o._capableAlerted` posée au **1er appel seulement** (les
  retries internes de résolution de nom passent `tries >= 1` et doivent **traverser** la garde) +
  `IsMuted(o.buyer)`.
- **Ordre nommé sur un reroll** : dédup `o._rerollAlertDone` (chemin unique `Handoff:AlertReroll`).

## Cycle de vie

`open → accepted → delivered → done` ; `open → cancelled` ; un désistement (`NACK` d'un accepteur)
ramène `accepted → open` (`acceptedBy = nil`) ; un ordre **nommé** refusé passe `→ declined`.

## Portée, déduplication, TTL et rétention

- **Portée / visibilité** (`Orders:VisibleTo`, `_ScopeMatch`) : `Tous` = tout le monde ; `Guilde` /
  `Amis` = drapeaux de relation `isGuild`/`isFriend` (marche aussi pour un artisan « ajouté » qui est
  guildmate/ami en jeu) ; sinon **nommé** = `name == recipient`. Un récepteur **affiche** selon
  `VisibleTo` mais garde le cache complet (il peut re-relayer, cf. mesh).
  > ⚠️ **Toute vue** doit appliquer `VisibleTo` + TTL + `IsMuted`, pas seulement le Carnet. La vue métier
  > (`ProfWindow_Orders:RefreshOrders`) ne filtrait que par relation → elle affichait les commandes
  > **nommées pour un TIERS** (fuite d'info sur une commande privée) et les ouvertes **expirées**.
  > Corrigé 2026-07-11 : helpers `shown(o)` (VisibleTo + TTL, mêmes règles qu'`Orders:All`) et `isMuted(o)`
  > (par **id** `db.muted` **ou** par **joueur** `Moderation:IsMuted`). `ORDER_TTL` est exposé via
  > `Orders.ORDER_TTL` pour que les deux vues partagent la même constante.
- **Déduplication par `id`.** Les re-broadcasts (RebroadcastMine, ticker, arrivée d'un pair) sont
  **idempotents** côté récepteur : `_OnNew` fusionne sur `COC.db.orders[id]` (flag `existed` → pas de
  double toast/anti-spam), et une commande connue n'est **mutable que par son acheteur en cache**
  (cf. autorité NEW). L'`id` est la clé unique de l'ordre — **et il est DEVINABLE** (`Nom-seq`) : ne
  jamais traiter la connaissance d'un `id` comme une preuve d'identité.
- **TTL** `ORDER_TTL = 6 h` : au-delà, une commande **ouverte** est tenue pour expirée — masquée de
  l'affichage ET élaguée (`PruneExpired`), **sauf les miennes** (jamais élaguées tant qu'ouvertes).
- **Rétention** `DONE_RETENTION = 7 j` (depuis création) : une commande **terminale** (done/cancelled/
  declined) est purgée au-delà. `PruneExpired` nettoie aussi les `id` de `COC.db.muted` orphelins.
- **Ré-émission** `REBROADCAST = 2 h` : ticker qui ré-émet MES commandes ouvertes/acceptées (un pair
  qui rejoint le canal sans HI finit par les voir).

## Relais mesh (propagation entre pairs)

`OnArtisanOnline(who)` → pour chaque commande, `_RelayMatch(o, who)` décide d'un push dirigé (whisper).
Garde-fous : **plafond** ~25 envois par événement, **cooldown 60 s PAR CIBLE** (`_lastPush[who]`, ajouté
2026-07-11 : un flapping join/leave du canal rejouait les 25 whispers **à chaque** JOIN), ordre **non
expiré** (`ORDER_TTL`), et la portée est respectée. `RebroadcastMine` est jitté (fenêtre 3–6 s) pour
éviter les rafales. Un ordre **capté** (`captured`) n'est pas re-répandu comme un ordre réseau normal.

> Rappel : ce relais est la raison pour laquelle `NEW` accepte `sender ≠ buyer` (cf. autorité NEW).

## Sémantique `captured` / `viaAddon`

- `viaAddon = true` par défaut (l'ordre est arrivé par le canal addon → l'auteur a l'addon).
- Une **entrante** captée dans `/commerce`·`/guilde` d'un joueur **sans** l'addon est poussée à un ami
  capable avec `SUGG|…|1` → chez lui `viaAddon = false` + `captured = true`, pour que l'acceptation
  prévienne l'auteur par **whisper** (il n'a pas l'addon pour recevoir l'ACK réseau).
- `SUGG` n'alerte que si le récepteur sait **vraiment** faire (`Handoff:ICanCraft`), jamais sur la
  simple supposition de l'émetteur.

## Transports (fournis par CraftLink-1.0)

> ### Confinement ROYAUME de TOUT le trafic addon (TRANSPORT_REV 10, 2026-07-11)
>
> `_Dispatch` **strippe** le suffixe `-Royaume` du `sender` (`playerShort`) avant de le passer aux
> handlers : l'identité manipulée par le protocole est donc un **nom court**. Sans garde, un joueur d'un
> royaume **NON connecté** (croisé en zone cross-royaume) portant le **même nom** qu'un de nos
> interlocuteurs devenait **indiscernable de lui** (`sender == buyer`) et pouvait ACK/CANCEL en son nom.
>
> `sameRealmGroup(sender)` est désormais appliqué au chemin **AddonMessage** (`onAddonMsg`), comme le
> canal-texte le faisait déjà. Raisonnement : les royaumes **CONNECTÉS partagent un espace de noms
> UNIQUE** → aucun homonyme n'est possible à l'intérieur ; hors du cluster on ne peut de toute façon ni
> échanger ni s'envoyer de courrier. On accepte donc royaume courant + connectés, on rejette le reste.

- **whisper 1:1** = canal FIABLE : ordres ciblés, transitions de cycle dirigées, forward. Zéro race au
  login, pas de dépendance guilde/canal.
- **canal custom `CraftLinkNet`** (`JoinTemporaryChannel`) = portée « global », **best-effort** : la
  distribution `CHAT_MSG_ADDON` sur CHANNEL est muette entre deux comptes d'un même Battle.net (PTR
  2026-06-30). D'où le fanout whisper qui **double** chaque `NEW` vers les artisans connus en ligne.
- **balise TEXTE `CLNK1`** (throttlée, hardware-event only) : découverte d'inconnus, puis tout le
  trafic de données bascule en whisper.
- **canal-texte `CLD1`** (`BroadcastText`, confiné au royaume courant + royaumes connectés) : diffuse en
  TEXTE de canal (swap `|`↔`~`, le `|` casse le chat) pour une portée royaume réelle, au-delà du roster
  whisperable. **Liste blanche de verbes : `NEW` et `CANCEL` seulement** (`CHANNEL_VERBS`, `Orders_Net`),
  et **commandes PUBLIQUES seulement** (`recipient == "Tous"`) — Guilde/Amis/nommé restent whisper-only
  (portée = vie privée), et ACK/DLV/DONE/NACK/SUGG restent dirigés (ils nomment un accepteur : les
  publier serait une fuite). La diffusion doit être **voulue** (`opts.channel`, posé par `Post`/
  `PostEntry`/`Cancel`) : ni le ticker de ré-émission ni les transitions dirigées ne touchent le canal.
  - **File d'envoi (REV 8)** : `SendChatMessage` est hardware-event-only et throttlé. Un envoi qui échoue
    (canal pas encore joint, throttle d'1 s, appel hors input) n'est plus perdu : la ligne part en FILE
    FIFO (max 24, TTL 120 s) drainée **une par événement d'input** (`WorldFrame:OnMouseDown` + frame caché
    `OnKeyDown`, pattern Deathlog). L'appelant n'a donc plus à garantir le contexte d'input. FIFO garantit
    qu'un `NEW` part avant son `CANCEL`. La **balise `CLNK1` n'est PAS mise en file** : throttlée, elle
    doit être perdue (la rejouer plus tard ne vaut rien et floode).
  - **Reste best-effort** : `ACK`/`DLV`/`DONE` ne transitent pas par ce chemin. Un joueur atteint
    SEULEMENT par le canal peut donc voir un ordre « open » qu'un autre a accepté ailleurs, jusqu'au
    **TTL** (6 h). Depuis la diffusion de `CANCEL`, ce n'est plus le cas d'une commande **annulée** — sauf
    si le `CANCEL` lui-même est manqué (une seule tentative), auquel cas le TTL borne la fenêtre. Pas de
    duplication ni de corruption : juste un affichage best-effort borné dans le temps.
  - **Sécurité** : le `sender` d'un texte de canal est posé par le transport (`playerShort(author)`), non
    falsifiable → l'anti-spoof `samePlayer(sender, o.buyer)` de `_OnCycle` couvre le `CANCEL` reçu par
    canal exactement comme celui reçu par whisper. Un récepteur qui n'a jamais vu le `NEW` n'a pas l'ordre
    en cache et `_OnCycle` sort immédiatement.
  - **Contrat `~`** : « aucun champ ne contient `~` » est **imposé par le codec** (`ENCODERS.NEW` strippe
    `[|~]` de `price` et `recipient`), pas seulement documenté : sans ça, le swap inverse à la réception
    décalerait silencieusement les champs suivants du décodeur NEW. Tout futur champ libre doit l'être aussi.
- **guilde** (`GUILD`) : distribution intra-guilde (+ relais GreenWall, hardware-event only).

> Voir `Libs\CraftLink-1.0\CraftLink_Transport.lua` (`TRANSPORT_REV`) et la mémoire
> `craftlink-addonmessage-system-channels` pour le détail des contraintes de transport.
