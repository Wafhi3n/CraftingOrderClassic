# Protocole ORD — carnet de commandes P2P (Crafting Order - Classic)

Référence normative du format filaire des commandes. Le codec est `Orders_Codec.lua` (table `SPEC`,
`Codec.Encode` / `Codec.Decode`) ; ce document et ce fichier doivent rester en phase. Le transport
(canal `CraftLinkNet`, whisper, guilde) est fourni par CraftLink-1.0 ; ici on décrit uniquement la
charge utile `ORD|...`.

> ⚠️ **Non-régression.** Tout client publié parle cette grammaire. Un changement de champ = un
> `protocolVersion` bumpé et une compat rétro explicite. Le refactor codec de la v1.8.0 est
> **iso-fil** : mêmes octets qu'avant, à la virgule près.

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
| DONE → `done` (+ crédit réputation) | `sender == o.buyer` **ou `SamePlayer`** ; crédit si `IsMyChar(acceptedBy)` (rep par compte) | `status ≠ done` |
| ACK → `accepted` | **nommé** : destinataire ou reroll lié (`SamePlayer(sender, recipient)`) ; **large** : n'importe qui (1er arrivé) | **`status == open`** (ferme le re-ACK/vol d'attribution) |
| DLV → `delivered` | **nommé** : destinataire OU accepteur (ou rerolls liés), sans précondition de statut (préserve « acheteur a raté l'ACK ») ; **large** : l'accepteur (ou reroll lié) uniquement | **large : `status == accepted`** ; entrée exclut `delivered` (idempotence) |
| NACK → réouverture / refus | `SamePlayer(who, o.acceptedBy)` réouvre ; ordre nommé (`who == recipient` ou lié, si `IsMyChar(buyer)`) refusé | — |

> Durcissement v1.9.0 (revue protocole) : ACK exige désormais un ordre **ouvert**, et un DLV en portée
> **large** exige que l'émetteur soit **l'accepteur** — fermant le vol d'attribution/réputation par un
> tiers (DLV direct sur un ordre nommé jamais accepté, ou re-ACK d'un ordre déjà pris). Le `captured=1`
> d'un `SUGG` n'est honoré que d'un émetteur **connu du roster** (`_OnSuggest`).

## Cycle de vie

`open → accepted → delivered → done` ; `open → cancelled` ; un désistement (`NACK` d'un accepteur)
ramène `accepted → open` (`acceptedBy = nil`) ; un ordre **nommé** refusé passe `→ declined`.

## Portée, déduplication, TTL et rétention

- **Portée / visibilité** (`Orders:VisibleTo`, `_ScopeMatch`) : `Tous` = tout le monde ; `Guilde` /
  `Amis` = drapeaux de relation `isGuild`/`isFriend` (marche aussi pour un artisan « ajouté » qui est
  guildmate/ami en jeu) ; sinon **nommé** = `name == recipient`. Un récepteur **affiche** selon
  `VisibleTo` mais garde le cache complet (il peut re-relayer, cf. mesh).
- **Déduplication par `id`.** Les re-broadcasts (RebroadcastMine, ticker, arrivée d'un pair) sont
  **idempotents** côté récepteur : `_OnNew` fusionne sur `COC.db.orders[id]` (flag `existed` → pas de
  double toast/anti-spam). L'`id` est la clé unique de l'ordre.
- **TTL** `ORDER_TTL = 6 h` : au-delà, une commande **ouverte** est tenue pour expirée — masquée de
  l'affichage ET élaguée (`PruneExpired`), **sauf les miennes** (jamais élaguées tant qu'ouvertes).
- **Rétention** `DONE_RETENTION = 7 j` (depuis création) : une commande **terminale** (done/cancelled/
  declined) est purgée au-delà. `PruneExpired` nettoie aussi les `id` de `COC.db.muted` orphelins.
- **Ré-émission** `REBROADCAST = 2 h` : ticker qui ré-émet MES commandes ouvertes/acceptées (un pair
  qui rejoint le canal sans HI finit par les voir).

## Relais mesh (propagation entre pairs)

`OnArtisanOnline(who)` → pour chaque commande, `_RelayMatch(o, who)` décide d'un push dirigé (whisper).
Garde-fous : **plafond** ~25 envois par événement, ordre **non expiré** (`ORDER_TTL`), et la portée est
respectée. `RebroadcastMine` est jitté (fenêtre 3–6 s) pour éviter les rafales. Un ordre **capté**
(`captured`) n'est pas re-répandu comme un ordre réseau normal.

## Sémantique `captured` / `viaAddon`

- `viaAddon = true` par défaut (l'ordre est arrivé par le canal addon → l'auteur a l'addon).
- Une **entrante** captée dans `/commerce`·`/guilde` d'un joueur **sans** l'addon est poussée à un ami
  capable avec `SUGG|…|1` → chez lui `viaAddon = false` + `captured = true`, pour que l'acceptation
  prévienne l'auteur par **whisper** (il n'a pas l'addon pour recevoir l'ACK réseau).
- `SUGG` n'alerte que si le récepteur sait **vraiment** faire (`Handoff:ICanCraft`), jamais sur la
  simple supposition de l'émetteur.

## Transports (fournis par CraftLink-1.0)

- **whisper 1:1** = canal FIABLE : ordres ciblés, transitions de cycle dirigées, forward. Zéro race au
  login, pas de dépendance guilde/canal.
- **canal custom `CraftLinkNet`** (`JoinTemporaryChannel`) = portée « global », **best-effort** : la
  distribution `CHAT_MSG_ADDON` sur CHANNEL est muette entre deux comptes d'un même Battle.net (PTR
  2026-06-30). D'où le fanout whisper qui **double** chaque `NEW` vers les artisans connus en ligne.
- **balise TEXTE `CLNK1`** (throttlée, hardware-event only) : découverte d'inconnus, puis tout le
  trafic de données bascule en whisper.
- **guilde** (`GUILD`) : distribution intra-guilde (+ relais GreenWall, hardware-event only).

> Voir `Libs\CraftLink-1.0\CraftLink_Transport.lua` (`TRANSPORT_REV`) et la mémoire
> `craftlink-addonmessage-system-channels` pour le détail des contraintes de transport.
