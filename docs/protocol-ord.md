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
/ `_OnNack`, **jamais** dans le codec :

| Transition | Qui a le droit |
|---|---|
| CANCEL → `cancelled` | `sender == o.buyer` (seul l'auteur annule) |
| DONE → `done` (+ crédit réputation) | `sender == o.buyer` (seul l'auteur confirme la réception) |
| ACK → `accepted` | l'accepteur = `sender` (le champ crafter n'est qu'un repli) |
| DLV → `delivered` | l'émetteur EST le crafteur (`sender`) |
| NACK → réouverture / refus | `who = sender` : `o.acceptedBy == who` réouvre ; ordre nommé (`o.recipient == who`) refusé |

## Cycle de vie

`open → accepted → delivered → done` ; `open → cancelled` ; un désistement (`NACK` d'un accepteur)
ramène `accepted → open` (`acceptedBy = nil`) ; un ordre **nommé** refusé passe `→ declined`.

*(Sections TTL / rétention / déduplication / relais mesh / transports : complétées en P5.)*
