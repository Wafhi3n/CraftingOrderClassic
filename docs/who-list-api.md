# API Who List (Classic Era) — référence

Source de vérité : le dump FrameXML local `Documentation\wow-ui-source-classic_era\`
(plus fiable que le wiki fandom, qui plafonne l'accès). Chemins cités ci-dessous relatifs
à ce dossier.

Motivation projet : brique **« Dead Faction »** de COC — cartographier la population en ligne
d'une faction quasi vide pour découvrir les porteurs de l'addon. Voir la mémoire
`coc-dead-faction-who-scan`.

---

## 1. Envoyer une requête — `C_FriendList.SendWho`

```lua
C_FriendList.SendWho(filter, origin)   -- origin = Enum.SocialWhoOrigin.*
```

- Déclarée `HasRestrictions = true` dans
  `Interface\AddOns\Blizzard_APIDocumentationGenerated\FriendListDocumentation.lua:293`.
  → **Appelable seulement dans une pile de hardware event** (clic/touche). Un timer =
  `ADDON_ACTION_FORBIDDEN`. Même contrainte que la balise CLNK1 / GreenWall.
- `origin` (`Enum.SocialWhoOrigin`) : `Chat`, `Social`, `Item`. Purement informatif côté
  serveur ; passer `Enum.SocialWhoOrigin.Chat` par défaut.
- Throttle serveur entre deux `/who` (non documenté précisément — **à mesurer sur PTR**).

Router la sortie du /who :
```lua
C_FriendList.SetWhoToUi(true)    -- résultats vers la fenêtre UI (elle S'OUVRE)
C_FriendList.SetWhoToUi(false)   -- résultats vers le CHAT (l'ancien dump "N joueurs")
```
⚠️ **CORRIGÉ (testé PTR 2026-07-03)** : contrairement à ce qui était écrit ici, `SetWhoToUi(true)`
n'empêche PAS l'ouverture de la fenêtre — il route vers l'UI, donc la fenêtre Qui **s'ouvre**.
Et `WHO_LIST_UPDATE` est **couplé à l'affichage** de la fenêtre (cf. `FriendsFrame.lua:893`) : c'est
justement parce que la fenêtre s'ouvre que l'event part et que `GetWhoInfo` est lisible.
→ **Technique du scan silencieux** : `SetWhoToUi(true)`, laisser la fenêtre s'ouvrir, lire sur
`WHO_LIST_UPDATE`, PUIS la refermer (`HideUIPanel(FriendsFrame)`) si le joueur ne l'avait pas ouverte
lui-même. Un léger flash est possible ; empêcher l'ouverture (hook OnShow → Hide) risque de tuer l'event.

---

## 2. Le filtre `filter` — c'est une requête, pas juste un nom

La chaîne accepte des **tags** combinables + une **plage de niveaux**. Blizzard le fait
elle-même à `FriendsFrame.lua:1279` :

```lua
local command = WHO_TAG_ZONE.."\""..GetRealZoneText().."\" "..minLevel.."-"..maxLevel;
```

et l'exact-match à `ItemRefHandlers.lua:50` :

```lua
C_FriendList.SendWho(WHO_TAG_EXACT..name, Enum.SocialWhoOrigin.Item);
```

### Tags disponibles (constantes globales — **localisées**, ne pas coder en dur)

| Constante        | Rôle              | Valeur enUS (indicative) |
|------------------|-------------------|--------------------------|
| `WHO_TAG_EXACT`  | nom exact         | `n-"..."`                |
| `WHO_TAG_GUILD`  | guilde            | `g-"..."`                |
| `WHO_TAG_ZONE`   | zone              | `z-"..."`                |
| `WHO_TAG_CLASS`  | classe            | `c-"..."`                |
| `WHO_TAG_RACE`   | race              | `r-"..."`                |

**Toujours** concaténer la constante globale (elle est traduite par client), jamais la
valeur enUS en dur. Les valeurs sont définies dans `GlobalStrings.lua` (absent du dump,
mais présent à l'exécution).

### Plage de niveaux

Texte brut `min-max` (ou un seul niveau) dans la chaîne : `"1-9"`, `"60"`. Combinable avec
les tags : `WHO_TAG_ZONE.."\"Orgrimmar\" 20-29"`.

### Exemples

```lua
SendWho("1-9")                                    -- tous les niv 1-9 en ligne (les 50 premiers)
SendWho("10-19")
SendWho(WHO_TAG_GUILD.."\"Les Forgerons\"")       -- membres d'une guilde en ligne
SendWho(WHO_TAG_ZONE.."\"Durotar\" 1-9")          -- zone + niveau
SendWho(WHO_TAG_EXACT.."Balragar")                -- match exact
```

---

## 3. Lire les résultats

Sur l'event **`WHO_LIST_UPDATE`** :

```lua
local numWhos, totalCount = C_FriendList.GetNumWhoResults()
-- numWhos    : nb de lignes retournées (≤ 50)
-- totalCount : nb réel côté serveur (peut dépasser 50 → requête trop large)

for i = 1, numWhos do
    local info = C_FriendList.GetWhoInfo(i)   -- WhoInfo (peut être nil)
    -- info.fullName        string
    -- info.fullGuildName   string
    -- info.level           number
    -- info.raceStr         string
    -- info.classStr        string  (nom localisé)
    -- info.area            string  (zone)
    -- info.filename        string?  (token de classe non localisé, ex "WARRIOR" — nilable)
    -- info.gender          number
    -- info.timerunningSeasonID number?  (MoP Remix, ignorer en Era)
end
```

Structure `WhoInfo` : `FriendListDocumentation.lua:567-580`.
`filename` = **token de classe non localisé** (`WARRIOR`, `MAGE`…) → utile pour couleur de
classe / logique ; `classStr` = libellé traduit pour affichage.

Tri optionnel : `C_FriendList.SortWho(sortType)`.

---

## 4. Limites dures

- **Plafond 50** : `MAX_WHOS_FROM_SERVER = 50` (`FriendsFrame.lua:11`). Le serveur ne renvoie
  jamais plus de 50 lignes. Si `totalCount > 50`, la requête est trop large → **découper**.
- **Hors ligne = invisible** : `/who` ne voit que les joueurs **connectés**. Aucun moyen
  d'énumérer les persos hors ligne (limite de principe, aucun addon ne le peut).
- **Hardware event** obligatoire pour `SendWho` (cf. §1).
- **Throttle** serveur entre requêtes (cadence à mesurer).

---

## 5. Contourner le plafond de 50 (technique de recensement)

Balayer par tranches qui ramènent chacune < 50 résultats, puis fusionner :

1. **Par niveau** : `1-9`, `10-19`, `20-29`, `30-39`, `40-49`, `50-59`, `60`
   (~7 requêtes couvrent toute la faction en ligne). Adapter les bornes au niveau max du
   client (SoD/Era = 60 ; ajuster si palier différent).
2. Si une tranche renvoie encore `totalCount > 50` (zone-hub bondée), **re-subdiviser** par
   zone (`WHO_TAG_ZONE`) ou par tranche de niveau plus fine.
3. File **séquentielle** : une requête, attendre `WHO_LIST_UPDATE`, lire, requête suivante,
   en respectant le throttle.

C'est la méthode des addons de recensement Classic (CensusPlus). Sur une **faction morte**,
le volume est faible → balayage rapide et complet.

### Piège d'implémentation à valider sur PTR
Enchaîner `SendWho` depuis un handler `WHO_LIST_UPDATE` (donc **hors** de la pile de clic
initiale) risque de retomber sous la restriction hardware event. Deux options selon le test :
- si l'enchaînement passe → file automatique après un seul clic ;
- s'il bloque → **une tranche par clic** (bouton « Scanner (suite) » ou piggyback sur le
  refresh de l'annuaire).

Autre point : filtrer brièvement le message système « Joueur introuvable » si on enchaîne
avec un ping HELLO sur un nom déconnecté entre-temps.

---

## 6. Récap des symboles

| Symbole | Type | Emplacement doc |
|---|---|---|
| `C_FriendList.SendWho(filter, origin)` | fonction, restreinte | FriendListDocumentation.lua:293 |
| `C_FriendList.SetWhoToUi(bool)` | fonction | FriendListDocumentation.lua:352 |
| `C_FriendList.GetNumWhoResults()` → numWhos, totalCount | fonction | FriendsFrame.lua:890 |
| `C_FriendList.GetWhoInfo(index)` → WhoInfo | fonction | FriendListDocumentation.lua:192 |
| `C_FriendList.SortWho(sortType)` | fonction | FriendsFrame.lua:1023 |
| `WHO_LIST_UPDATE` | event | FriendListDocumentation.lua:543 |
| `WhoInfo` (fullName, fullGuildName, level, raceStr, classStr, area, filename, gender) | structure | FriendListDocumentation.lua:567 |
| `MAX_WHOS_FROM_SERVER = 50` | constante | FriendsFrame.lua:11 |
| `WHO_TAG_EXACT/GUILD/ZONE/CLASS/RACE` | global strings (localisés) | GlobalStrings.lua (runtime) |
| `Enum.SocialWhoOrigin` | enum | Chat / Social / Item |
