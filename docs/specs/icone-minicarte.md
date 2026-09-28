# Icône d'état dans la barre de la minicarte

> État : **implémentée, vue en jeu** (relevés 14 et 15) · Rédigée le 2026-09-28 · Première utilisation
> décidée par le user le 2026-09-28 (« mettre une icône là si une mise à jour est dispo »), puis :
> « c'est bien mieux, crée bien la doc, on va l'utiliser » → l'outil sert désormais à plusieurs icônes.
> Mode d'emploi pour en ajouter une : skill **coc-native-ui**, section « Icônes d'état de la minicarte ».
> Cible : WoW: Forever / Camelot (16001) · Addon : Crafting Order - Classic

## Le problème

L'alerte « nouvelle version disponible » existe depuis la v1.27.0 : une ligne dans le chat (une fois
par version) et une pastille rouge sur le bouton de minicarte de COC. La ligne se noie dans la rafale
du login, et la pastille est petite, sur un bouton que beaucoup de joueurs rangent dans le
compartiment d'addons. Un joueur peut donc rester des semaines sur une vieille version, et c'est grave
depuis la v1.37.0 : un joueur en 1.36 n'entend presque plus le réseau.

Sur Forever, la minicarte a une barre d'icônes d'état en haut, celle de la lettre du courrier et des
commandes d'artisanat de Blizzard. Une icône n'y apparaît que quand quelque chose attend le joueur.

## Ce qu'on veut

Quand une nouvelle version de l'addon est signalée par le réseau, **le logo de Crafting Order
apparaît dans cette barre**, à côté de la lettre. Au survol, une infobulle dit quelle version est
disponible et laquelle on a. Un clic affiche le détail dans le chat (comme `/co version`). L'icône
disparaît quand on a mis à jour, ou quand l'alerte est oubliée (`/co version reset`, ou expiration).

## Ce qu'on NE fait PAS (pour l'instant)

- **Pas d'icône « commande reçue » ici.** Elle a sa propre spec, `icone-commande-recue.md` (rang 4,
  2026-09-28). D'autres types viendront chacun à son rang (idée du user : une icône par type).
- **Pas de nouvelle règle d'alerte.** Mêmes déclencheurs que la pastille (deux joueurs distincts,
  TTL de 7 jours) : l'icône n'est qu'un deuxième affichage du même état.
- **Pas d'icône hors Forever.** Sans `MinimapCluster.IndicatorFrame`, rien ; la pastille reste.

## Cas particuliers

- **Mode Édition, combat.** `MinimapCluster` est un cadre du mode Édition. Mesuré le 2026-09-27 dans
  TaintLab (`/tlab indica`) : une icône enfant de la barre, en `layoutIndex` 3, avec `Layout()` à
  chaque apparition, n'a donné AUCUNE action refusée, 18 bascules en combat comprises. C'est cette
  variante (A) que le user a choisie ; la variante B (cadre à nous collé contre la barre) « fait
  bizarre, décalé ».
- **Courrier qui arrive.** Blizzard relance lui-même `Layout()` de la barre : notre icône garde sa
  place (rang 3, après la lettre et les commandes de Blizzard).

## Critères d'acceptation

1. [test] `SetUpdateBadge(true, v)` pose l'icône dans la barre (rang 3), l'affiche et relance la
   disposition ; `SetUpdateBadge(false)` la masque et relance la disposition. Sans la barre : aucune
   erreur, rien. → `tests/test_minimap_indicator.lua`
2. [porte] Les quatre portes ; la chaîne neuve est dans les trois overlays.
3. [humain] Après `/run … NotePeerVersion(…)` × 2, le logo apparaît en haut de la minicarte, à côté
   de la lettre ; l'infobulle dit « Nouvelle version disponible : 9.9.9 » et la version installée ;
   un clic écrit le détail dans le chat ; `/co version reset` le fait disparaître. Témoin : l'icône
   des commandes du labo (`/tlab indica`), vue au même endroit le 2026-09-27.
4. [humain] `/console taintLog 1`, icône affichée, mode Édition ouvert puis fermé, un combat :
   aucune erreur, rien de COC dans `Logs\taint.log`.

## Décisions

- **2026-09-27, user** : variante A (icône ENFANT de la barre, `layoutIndex`, `Layout()`), mesurée sans
  taint dans TaintLab ; la variante B (cadre à nous collé contre la barre) « fait bizarre, décalé ».
- **2026-09-28, défaut de l'agent, accepté** : l'icône « mise à jour » est le LOGO de l'addon ; l'atlas
  des commandes d'artisanat de Blizzard est gardé pour une future icône « commande ». Un clic écrit le
  détail dans le chat, il n'éteint pas l'icône (elle reste tant que la mise à jour n'est pas faite).
- **2026-09-28, user** : 16 px trop petit → **22 px** (la lettre de Blizzard fait 20×15). Revu sur
  capture : lisible, ne touche pas la minicarte.
- **2026-09-28, user** (« on va l'utiliser ») : le module devient un OUTIL à plusieurs icônes.

## Contrat

`CraftingOrderClassic_MinimapIndicator.lua`, sur `COC.UI` :

- `UI:DefineIndicator(key, def)`, une fois au chargement. `def.texture` (chemin) ou `def.atlas` (atlas
  VÉRIFIÉ sur le client), `def.order` (rang dans la barre, **≥ 3** : 1 et 2 sont à Blizzard ; un rang
  par icône), `def.size` (défaut 22), `def.width` / `def.height` (icône non carrée, priment sur
  `size`), `def.useAtlasSize` (l'atlas garde sa taille native, calé en haut à gauche, comme le
  `useAtlasSize="true"` du XML de Blizzard), `def.tooltip(tt)` (lignes après le titre « Crafting
  Order », posé par l'outil), `def.onClick(button)` facultatif.
- `UI:SetIndicator(key, shown)` : allume ou éteint ; rend vrai si la barre existe. Le cadre n'est créé
  qu'au premier allumage ; sans la barre (hors Forever), rien.
- Rangs attribués : **3 = mise à jour** (`"update"`), **4 = une commande t'attend** (`"order"`,
  spec `icone-commande-recue.md`). Réserver le suivant ici avant de le coder.

## Renvois

- Mémoire `coc-minimap-indicator-idea` (mesure TaintLab, choix de la variante A).
- `Directory_Version.lua` (l'alerte), `CraftingOrderClassic_Minimap.lua` (`UI:SetUpdateBadge`).
