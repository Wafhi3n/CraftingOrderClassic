# Les prix : une seule source, Auctionator

> État : **implémentée** (retrait du pont + renommage, 2026-09-22 ; reste à voir en jeu) · Rédigée le 2026-09-22 · Arbitrages du user le 2026-09-22
> Cible : WoW: Forever / Camelot · Addon : Crafting Order - Classic

## Le problème

Tout ce que COC dit d'argent passe par **un seul appel**, `LG:ItemValue(itemID)`, qui interroge deux
oracles : Lazy Gold d'abord, Auctionator ensuite. Au-dessus, la couche est à nous — coût d'une
fabrication, profit, coût par point de métier, meilleur plan à ton rang, bourse d'artisan, ce que
rapporte une commande face à ce que coûtent ses réactifs.

Deux oracles pour une seule donnée, c'est un de trop : **Lazy Gold ne calcule rien, il relit
Auctionator**. On entretient donc un pont, ses gardes et ses libellés pour une source qui n'en est
pas une, et un pied de fenêtre peut nommer « Lazy Gold » là où le chiffre vient d'ailleurs.

## Ce qu'on veut

1. **Une seule source de prix : Auctionator.** C'est lui qui scanne l'hôtel des ventes, c'est son
   métier, et c'est de lui que Lazy Gold tirait déjà ses chiffres.
2. **Le pont Lazy Gold disparaît**, avec ses gardes, sa table de vendeurs et ses libellés.
3. **Sans Auctionator, COC ne prétend pas connaître un prix.** Les vues qui en dépendent disent
   qu'elles ne savent pas, au lieu d'afficher un zéro qui se lirait comme « ça ne rapporte rien ».
4. **Ce qui est bâti au-dessus ne bouge pas** : profit, coût par point, meilleur plan, bourse
   d'artisan, ligne de prix d'une commande. On retire une source, on ne change aucun calcul.
5. **Le prix VENDEUR garde sa priorité** sur le prix de marché pour un réactif achetable en ville.
   Règle existante : sans elle, la route de progression choisit la mauvaise recette.

## Ce qu'on NE fait PAS

- **On ne scanne pas l'hôtel des ventes nous-mêmes.** Auctionator le fait déjà, et refaire un
  scanner d'enchères n'est pas notre métier (décision du user, 2026-09-22).
- **Aucun prix ne vient des autres joueurs.** Rien de ce que COC affiche comme un fait ne provient du
  réseau : un prix forgé fausserait un achat réel (décision du user, 2026-09-22 — elle vaut aussi
  pour la base de recettes, voir la spec voisine).
- **Pas de requête vers l'extérieur** : un addon ne sort pas du jeu.
- **Pas de prix inventé** : ni moyenne calculée à partir de rien, ni valeur par défaut.

## Cas particuliers

- **Auctionator absent** : aucun prix de marché. Ce qui reste connu sans lui — le prix d'un plan chez
  un vendeur, déjà dans nos données générées — continue de s'afficher ; le reste se tait.
- **Auctionator présent mais jamais scanné** : il répond qu'il ne sait pas, et c'est une réponse
  valable qu'on affiche telle quelle.
- **Objet jamais vu** : aucune valeur, et les vues le disent.
- **La bêta rend des prix faux** : constaté, c'est ce qui a fait ranger le chantier Profit sur sa
  branche. Nommer la source et l'âge d'un chiffre permet au moins de savoir d'où vient le doute.
- **Vendeur et marché se contredisent** : le vendeur l'emporte pour un réactif de ville.

## Décisions

- 2026-09-22, user — **les prix d'hôtel des ventes viennent d'Auctionator, et de lui seul.** C'est un
  scan, et ce scan est le sien.
- 2026-09-22, user — **Lazy Gold est décommissionné** : il ne faisait que relire Auctionator.
- 2026-09-22, user — **rien ne vient des autres joueurs.** Les sources sont Auctionator pour les
  prix, Wowhead et notre propre addon pour le reste.
- 2026-09-22, user — la couche s'appelle **`COC.Profit`** (`_Profit.lua`, `_UI_Post_Profit.lua`,
  `_UI_MyArtisans_Profit.lua`). « Rentabilité » reste le mot côté joueur, `Profit` le mot côté code.
  La clé persistée `lgExactProfit` garde son nom : la renommer demanderait une migration de schéma
  pour un confort d'écriture.

### Décisions ouvertes

Aucune : les deux dernières (le nom de la couche, l'affichage d'un prix absent) ont été tranchées par
le user le 2026-09-22 et sont implémentées.

## Critères d'acceptation

1. `[humain]` Avec Auctionator installé et scanné, les vues qui affichent de l'argent montrent les
   mêmes chiffres qu'avant le retrait du pont. Témoin connu-bon : la v1.35.1.
2. `[humain]` Sans Auctionator, aucune vue n'affiche « 0 » ni un profit calculé : elles disent
   qu'elles ne savent pas. Témoin : la vue Manquantes, qui affiche « ? » depuis le 2026-09-22.
3. `[test]` Un prix absent reste `nil` de bout en bout : aucun repli à 0 ne se glisse dans la chaîne
   (profit, coût par point, meilleur plan).
4. `[test]` La couche de calcul rend les mêmes résultats qu'aujourd'hui pour les mêmes valeurs
   d'entrée : retirer une source ne change aucun calcul.
5. `[porte]` Aucune clé de locale morte ne subsiste après le retrait des libellés « Lazy Gold ».

## Contrat

`COC.Profit:ItemValue(itemID)` reste la **seule** porte d'entrée et rend des cuivres ou `nil`. Le reste de COC
n'a pas à savoir d'où vient un prix. Rien n'est persisté : COC ne tient pas de relevé, il demande au
moment où il affiche.

## Renvois

- Spec voisine : `CraftLink/docs/specs/donnees-cycle-de-vie.md` — la base de recettes, même
  discipline de sources.
- Mémoires `coc-optional-deps-decommissioned` (la décision), `coc-artisan-pouch-feature` et
  `coc-leveling-cheapest-recipe-idea` (gros consommateurs de prix), `coc-era-purge-api-review`
  (chantier Profit sur `feat/profit-forever`).
- Skill `wow-classic-addon-dev`.
