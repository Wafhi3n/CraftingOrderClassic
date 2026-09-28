# Icône d'état dans la barre de la minicarte

> État : **validée** · Rédigée le 2026-09-28 · Première utilisation décidée par le user le 2026-09-28
> (« mettre une icône là si une mise à jour est dispo ») · Pas encore implémentée
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

- **Pas d'icône « commande reçue ».** L'idée du 2026-09-27 reste à spécifier ; cette barre et ce
  module l'accueilleront, avec une icône par type ou un atlas qui change (idée du user).
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

## Renvois

- Mémoire `coc-minimap-indicator-idea` (mesure TaintLab, choix de la variante A).
- `Directory_Version.lua` (l'alerte), `CraftingOrderClassic_Minimap.lua` (`UI:SetUpdateBadge`).
