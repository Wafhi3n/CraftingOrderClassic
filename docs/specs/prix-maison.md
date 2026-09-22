# Les prix, chez nous — sortir de Lazy Gold et d'Auctionator

> État : **brouillon** · Rédigée le 2026-09-22 · Décision de cap du user le 2026-09-22
> Cible : WoW: Forever / Camelot · Addon : Crafting Order - Classic

## Le problème

Tout ce que COC dit d'argent repose sur **un seul appel** : `LG:ItemValue(itemID)`, qui interroge
Lazy Gold sur l'Era et Auctionator sur Forever. Au-dessus, la couche est à nous — coût d'une
fabrication, profit, coût par point de métier, meilleur plan à ton rang, bourse d'artisan, ce que
rapporte une commande face à ce que coûtent ses réactifs. En dessous, rien ne nous appartient.

Ça se paie de trois façons :

- **la fonctionnalité dépend d'une installation** que le joueur n'a pas forcément, et qu'on lui
  demande d'ajouter pour que la moitié de nos vues s'allument ;
- **la source ment parfois** : sur la bêta, les prix relus depuis Auctionator sont faux, ce qui a
  fait ranger le chantier Profit sur une branche plutôt que de le publier ;
- **un addon tiers décide** de la langue, de la survie à un patch et de la disponibilité d'une partie
  de COC. On a déjà payé ça avec MTSL pour les sources de recettes.

Décision du user du 2026-09-22 : **Lazy Gold est décommissionné**, comme MTSL avant lui. Le prix doit
devenir une donnée à nous.

## Ce qu'on veut

1. **COC connaît un prix sans rien installer d'autre.** Au minimum le prix VENDEUR, qui est un fait
   stable et vérifiable, pas une estimation de marché.
2. **Un prix dit d'où il vient** — vendeur, hôtel des ventes, ou notre propre relevé — et **quand il
   a été vu**. Un prix sans date est une opinion.
3. **Une valeur inconnue se tait.** Pas de zéro, pas de « gratuit », pas d'estimation inventée : la
   règle qui vient de coûter un correctif sur les niveaux de recette vaut ici mot pour mot.
4. **Tout ce qui est bâti au-dessus continue de marcher** sans réécriture : profit, coût par point,
   meilleur plan, bourse d'artisan, ligne de prix d'une commande. On remplace la source, pas la
   couche.
5. **Si un addon de prix est là et qu'il répond mieux, on peut s'en servir** — mais comme d'un bonus,
   jamais comme d'une condition.

## Ce qu'on NE fait PAS

- **Pas de requête vers l'extérieur.** Un addon ne sort pas du jeu. Tout vient du client ou du paquet.
- **Pas de prix reçus des autres joueurs.** Même question de confiance que pour la base de données
  (voir la spec voisine) : un prix forgé fausserait un achat réel. À trancher là-bas, pas ici.
- **Pas de nouvel addon d'hôtel des ventes.** On ne refait ni l'interface d'enchères, ni l'historique
  de marché, ni les graphiques. On veut une valeur par objet, pas un outil de trading.
- **Pas de prix « moyens serveur » calculés à partir de rien.** Ce qu'on n'a pas vu, on ne l'invente
  pas.

## Cas particuliers

- **Objet jamais vu** : aucune valeur. Les vues qui en dépendent disent qu'elles ne savent pas, au
  lieu d'afficher un profit de 0 qui se lirait comme « ça ne rapporte rien ».
- **Vendeur et hôtel des ventes se contredisent** : le vendeur l'emporte pour un réactif achetable en
  ville à prix fixe. Règle déjà en place, à conserver — sans elle, la route de progression choisit la
  mauvaise recette.
- **Prix vieux** : un relevé d'hôtel des ventes se périme, un prix vendeur non. L'âge s'affiche là où
  il compte.
- **Changement de royaume ou de faction** : un relevé de marché appartient à un royaume et à une
  faction. Les mélanger produirait des chiffres faux sans le dire.
- **Le joueur a Auctionator ou Lazy Gold** : on peut préférer notre relevé, le sien, ou le plus
  récent des deux. **À trancher.**
- **La bêta rend des prix faux** : c'est le cas constaté. Un relevé à nous, daté et vérifiable,
  permet au moins de voir QUE c'est faux.

## Décisions

- 2026-09-22, user — Lazy Gold est décommissionné ; le prix devient une fonctionnalité de COC.
- 2026-09-22, agent (à confirmer) — on garde la couche existante (`COC.LazyGold`, à renommer) et on
  ne remplace que sa source de valeur. Le reste du code n'a pas à savoir d'où vient un prix.
- 2026-09-22, user — **le prix de marché vient d'un SCAN de l'hôtel des ventes, fait par nous.**
  Constat qui tranche la question : Lazy Gold ne calcule rien, il relit Auctionator. Les deux ponts
  d'aujourd'hui mènent donc à la même donnée, produite par un scan qu'un autre addon a fait. Autant
  le faire, le dater et le posséder. Le prix VENDEUR reste prioritaire sur le marché pour un réactif
  achetable en ville (règle existante, elle ne change pas).

### Décisions ouvertes, à trancher par le user

1. **Qui gagne** quand le joueur a aussi Auctionator : notre relevé, le sien, ou le plus frais ?
2. **Où vivent les relevés** : dans la SavedVariable du compte, partagés entre tous les personnages
   d'un même royaume, ou par personnage ?
3. **Combien de temps on garde** un prix de marché avant de le déclarer périmé plutôt que de
   l'afficher tel quel.
4. **Qui déclenche le scan** : le joueur devant l'hôtel des ventes, ou l'addon dès que la fenêtre
   s'ouvre ?

## Critères d'acceptation

1. `[humain]` Sans aucun addon de prix installé, ouvrir un marchand puis rouvrir la fenêtre de métier
   affiche un coût de fabrication pour les recettes dont tous les réactifs sont vendus en ville.
   Témoin connu-bon : aujourd'hui, sans Auctionator, ces mêmes recettes n'affichent rien.
2. `[humain]` Un objet dont on n'a aucun prix ne montre ni « 0 », ni profit calculé : la vue dit
   qu'elle ne sait pas. Témoin : la vue Manquantes, qui affiche « ? » depuis le 2026-09-22.
3. `[humain]` L'infobulle d'un prix nomme sa source et son âge (« vendeur, vu aujourd'hui »).
4. `[test]` La couche de calcul (profit, coût par point, meilleur plan) rend les mêmes résultats
   qu'aujourd'hui quand on lui donne les mêmes valeurs d'entrée — le remplacement de source ne change
   aucun calcul.
5. `[test]` Un prix absent reste `nil` de bout en bout : aucun repli à 0 ne se glisse dans la chaîne.
6. `[porte]` Localisation, tailles, Lua 5.1 comme d'habitude.

## Contrat

`COC.<couche de prix>:ItemValue(itemID)` reste la **seule** porte d'entrée : elle rend des cuivres ou
`nil`. Tout le reste de COC continue de passer par elle et n'a pas à connaître la provenance. Ce qui
s'ajoute, c'est la question « d'où et de quand », qui se demande à part.

Les relevés persistés forment un nouveau schéma de SavedVariable : il faudra une migration (voir
`_Migrations.lua`) et une version, comme pour tout ce qu'on écrit sur disque.

## Renvois

- Spec voisine : `CraftLink/docs/specs/donnees-cycle-de-vie.md` — même question de fond, côté base
  de recettes, et c'est là que se tranche « accepte-t-on des faits venus des autres joueurs ».
- Mémoires `coc-optional-deps-decommissioned` (la décision), `coc-artisan-pouch-feature` et
  `coc-leveling-cheapest-recipe-idea` (deux gros consommateurs de prix),
  `coc-era-purge-api-review` (le chantier Profit rangé sur `feat/profit-forever`).
- Skills `wow-classic-addon-dev` (API, SavedVariables, migrations), `feature-spec`.
