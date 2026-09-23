# Registre de vérification en jeu — Crafting Order - Classic

Les portes automatiques du pipeline (Lua 5.1, anti-monolithe, localisation, tests headless) mesurent
du **texte**. Elles ne savent pas si l'addon *fonctionne* : une donnée correctement écrite prouve
qu'une chose est **déclarée**, jamais qu'elle **marche**. La seule porte qui mesure le produit, c'est
le **banc 2 comptes Forever** — et jusqu'au 2026-09-23 elle ne laissait aucune trace dans le dépôt.
L'état « éprouvé / pas éprouvé » ne vivait que dans une tête ou dans la mémoire d'un agent, et un
« je crois que c'était testé » ne vaut rien la semaine suivante.

Ce fichier est cette trace. Il répond à **une** question : *jusqu'où le produit a-t-il été vu
fonctionner ?* `scripts\untested.ps1` la pose au dépôt et rend la liste de ce qui est venu après.

## Comment on l'écrit

Après une séance au banc, on ajoute **en tête** de la section suivante une ligne de la forme :

```
- AAAA-MM-JJ — jusqu'a <sha> — <banc> — <verdict> — <ce qui a été observé>
```

Le `<sha>` est le dernier commit **réellement présent dans le client** pendant la séance (celui que
`deploy.ps1` a copié), pas le dernier commit du jour. Le reste est en clair, pour qu'un humain
relise un verdict sans le décoder.

Deux règles qui font la valeur du registre :

1. **On n'écrit un relevé qu'après avoir observé**, jamais en préparant la séance. Un relevé écrit
   d'avance est un mensonge daté.
2. **Ce qui n'a pas été observé se dit.** Un GO partiel s'écrit avec son périmètre (« NEW/ACK
   tracés des deux côtés ; NACK pas rejoué »), sinon le registre promet plus que la séance.

Pour un commit isolé éprouvé hors séance, on peut aussi porter le trailer `Verified-In-Game:
AAAA-MM-JJ` sur le commit lui-même — `untested.ps1` le reconnaît. Les commits de type `docs:`,
`test:`, `chore:`, `ci:`, `build:` et `style:` sont hors périmètre : ils ne changent rien dans le
client.

## Relevés

- 2026-09-23 (3) — jusqu'a c59ec45 — Forever, un client — **GO, la spec `prix-maison` est close** —
  la priorité du prix VENDEUR est enfin **observée**, et sur le cas qui discrimine : `/co pricedump`
  sur **Coal (id 3857)** rend `vendeur=4s75c  HV=3s97c  -> 4s75c`. Les deux prix existent, ils
  diffèrent, et c'est le vendeur qui l'emporte — la règle tire, elle n'est pas juste écrite.
  Chemin pour l'obtenir, à garder : Auctionator ne connaît le prix d'un vendeur qu'après avoir
  OUVERT sa fenêtre. Tant qu'on n'a visité personne, `vendeur=nil` partout et la règle est
  intestable. Il faut donc visiter un marchand, puis dumper un objet qu'il vend ET qui se trade.
  Constaté aussi : sur les réactifs non vendus (Rough Stone, Linen Cloth, Copper Bar…) le repli HV
  fonctionne, ce qui écarte la crainte qu'Auctionator rende un prix de REVENTE pour tout objet.
  ⚠️ Question de CONCEPTION ouverte (ce n'est pas un défaut) : ici le vendeur est PLUS CHER que le
  HV, donc la route surévalue Coal de 78c. La règle protège d'un HV gonflé sur un produit de
  vendeur ; elle coûte quand le HV est réellement moins cher. Voir la spec.

- 2026-09-23 (2) — jusqu'a 9d0be6e — Forever, un client, HV rescanné — **GO** — deux observations
  faites dans la foulée de la séance prix :
  **Gain de point de compétence** (`COC:OnSkillLines`, commit 20d93b8) : un point gagné fenêtre
  Ingénierie OUVERTE met le panneau de droite à jour tout seul, sans rien fermer ni rouvrir.
  C'était le but du correctif — la route suivait auparavant la liste d'AVANT le point.
  **Découpage de `_ProfWindow_Route_Supply`** (commit c206978) : le bloc « Supplies (aggregated) »
  et les « Recipe to buy » se peignent toujours, donc l'extraction n'a rien perdu en chemin.
  ⚠️ **NON observé, toujours** : la priorité du prix VENDEUR sur le prix HV pour un réactif
  achetable en ville. Ce qui a été vu n'est PAS ça — seulement qu'Auctionator n'ajoute une ligne
  « Vendor » à son infobulle que lorsqu'un prix vendeur existe (un objet sans valeur de revente
  n'affiche que « Auction »). C'est rassurant sur l'oracle, ce n'est pas la règle. Un seul
  `/co pricedump` la trancherait : il imprime `vendeur=` et `HV=` côte à côte avec ce que
  `ItemValue` a retenu.
  ⚠️ Séance toujours sous la **panne de SavedVariables** de Forever : rien de persistant éprouvé.

- 2026-09-23 — jusqu'a 32d994d — Forever, un client, HV rescanné en ouverture — **GO partiel** —
  **avec Auctionator** : le Plan de route se peint en entier (total estimé, 4 paliers chiffrés,
  « Supplies (aggregated) », plans à acheter), et la carte de recette affiche `To Craft` et
  `Profit: -1`. **Sans Auctionator** : aucune vue n'affiche `0`, et le bouton d'ouverture sort bien
  la popup « This feature needs the Auctionator addon ». C'est le cœur de la spec `prix-maison`
  (un seul oracle, et pas de zéro qui se lirait « ça ne rapporte rien »).
  ⚠️ **NON observé** : la priorité du prix VENDEUR sur le prix HV pour un réactif achetable en
  ville (point 5 de la spec). La route a changé entre deux scans d'HV — comportement attendu, les
  prix pilotent le choix — donc la comparaison avant/après ne prouve rien ici. À reprendre avec un
  réactif dont on connaît le prix vendeur.
  ⚠️ Séance menée pendant la **panne de SavedVariables** de Forever : rien de ce qui touche à la
  persistance n'a été éprouvé, et l'HV a dû être rescanné pour que les prix existent.

- 2026-09-22 — jusqu'a 0760259 — **reprise d'historique, pas un relevé de séance** — la v1.35.1 a
  été publiée sur CurseForge à ce commit, et la doctrine de release veut qu'on ne publie pas sans
  être passé au banc. On prend donc ce point comme départ du registre. ⚠️ Ce relevé n'a pas été
  écrit pendant une séance : il reconstitue un état à partir de la release. Les suivants seront
  écrits sur observation directe.
