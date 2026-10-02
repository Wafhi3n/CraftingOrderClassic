# Plan de route au coût NET : ce que tu as en sac a un prix, ce que tu fabriques aussi

> État : **brouillon validé sur le principe** — décisions 1 à 5 tranchées par le user le 2026-10-02,
> questions ouvertes en fin de document. Rien de codé. · Rédigée le 2026-10-02
> Cible : WoW: Forever / Camelot (16001) · Addon : Crafting Order - Classic
> Prolonge `rentabilite-forever.md` (dont la décision 8 laissait le coût de montée hors champ, « à
> rouvrir sciemment ») et le Plan de route (mémoire `coc-leveling-cheapest-recipe-idea`).

## Le problème

Capture du user le 2026-10-02, Forge 80/150 : la route annonce 17 po 61 pa jusqu'à 150, prend des
barres de cuivre dans les sacs comme si elles ne valaient rien, et ne dit jamais ce que valent les
objets qu'elle fait fabriquer. Trois défauts, un seul calcul :

- **Le sac compte pour zéro.** Depuis le 2026-09-26, la route puise d'abord dans les sacs, et ce
  qu'elle y prend ne coûte rien. Or une Copper Bar en sac vaut ce qu'elle se vend : 1 pa 40 à l'HV
  (vente du user du 2026-09-26). La brûler pour un point, c'est renoncer à cet argent. La route
  préfère donc toujours la recette qui mange le sac, même quand vendre le sac et acheter autre
  chose reviendrait moins cher.
- **Le produit ne vaut rien.** Une recette dont l'objet se revend bien n'est jamais avantagée sur
  une recette dont l'objet ne vaut rien. Le joueur, lui, fait la différence : il revendra.
- **Rien n'est dit.** Quand les matières valent plus que l'objet qu'elles donnent, l'écran ne le
  signale nulle part, alors que c'est exactement ce que le joueur veut savoir avant de crafter.

Le même manque vaut d'un métier à l'autre : ses ventes de la même semaine donnent le Copper Ore à
1 pa 21–1 pa 33 et la Copper Bar à 1 pa 40. Fondre ne rapporte presque rien, et un forgeron qui fond
son propre minerai n'en sait rien (traité à part, décision 5).

## Ce qu'on veut

La route choisit, à chaque point, la recette qui coûte le moins **en valeur**, pas en pièces
sorties de la bourse :

**coût net d'un point = (valeur de ce qu'il consomme − valeur de revente de ce qu'il produit) ÷ chance de point**

- Ce qu'on **achète** vaut son prix d'achat (comme aujourd'hui).
- Ce qu'on prend **dans les sacs** vaut ce qu'on en tirerait en le vendant.
- Ce qu'on **fabrique** est crédité de ce qu'on en tirerait en le vendant ; s'il est consommé plus
  loin par la route, il y est débité au même prix (le crédit et le débit s'annulent : une étape de
  conversion n'est ni gratuite ni comptée deux fois).

Le joueur voit :

- **deux totaux** sous le titre : **« À débourser »**, l'argent qui sort vraiment (achats et plans,
  le chiffre d'aujourd'hui), et **« Coût net »**, revente déduite. Le coût net peut être un **gain** ;
  il s'écrit alors comme tel, en vert ;
- dans l'infobulle de **chaque étape** : réactifs (achetés / pris au sac), revente du produit, net
  de l'étape, et **combien d'objets** l'étape suppose de revendre ;
- sur l'étape elle-même, une marque quand **les matières valent plus que ce qu'elles produisent**
  (l'étape fait perdre de la valeur : c'est le prix du point, et le joueur le sait) ;
- sous les fournitures, la **valeur du sac consommé** : « Ce que la route prend dans tes sacs
  vaudrait ~X à l'HV » ;
- une **case « Compter la revente »**, cochée par défaut, à côté de « Inclure les plans à acheter ».
  Décochée, la route redevient celle d'aujourd'hui pour le produit (revente nulle) ; le sac garde sa
  valeur.

Le **suivi à l'écran** (prochain point) choisit la même recette que la fenêtre : c'est déjà une règle
du module (`Route:NextStep`, « le suivi et la fenêtre doivent choisir la même recette »), elle
s'applique telle quelle.

## Ce qu'on NE fait PAS (pour l'instant)

- **Pas de plafond de revente** (décision 4). Auctionator donne le prix le plus bas du dernier scan,
  pas le nombre d'acheteurs : vendre 40 Ironforge Breastplate à ce prix est une illusion. On le
  **montre** (combien d'objets à revendre, quelle part du coût net repose sur la revente) avant de
  le corriger ; on plafonnera si les routes en jeu le réclament.
- **Pas de conseil d'un métier à l'autre** dans cette version (décision 5) : « vends ton minerai,
  achète les barres » compare le Minage et la Forge. Deuxième étape, section dédiée plus bas.
- **Pas de changement de la bourse d'artisan** (onglet Artisans, route d'un TIERS) tant que la
  question ouverte 1 n'est pas tranchée.
- **Pas de nouvel oracle de prix.** Auctionator reste le seul (`prix-maison.md`) ; le prix de
  rachat par un marchand vient du client (cf. Contrat).
- **Pas de prise en compte du temps ni de l'effort de farm.** Déjà assumé par la route (mémoire du
  2026-07-25, « 127 wolf meat ») et inchangé.

## Cas particuliers

| Situation | Comportement |
|---|---|
| Produit sans prix connu (jamais scanné, pas de marchand) | Revente **nulle** pour le choix. C'est l'hypothèse pessimiste : le coût net ne peut qu'être surestimé, jamais présenté comme un gain imaginaire. L'infobulle dit « revente inconnue ». Pas de « (?) » : l'erreur va dans le sens sûr. |
| Produit LIÉ quand ramassé | Il ne passe pas à l'HV : ne vaut que son prix de rachat par un marchand. |
| Produit que vend aussi un marchand | Le prix du marchand **plafonne** la revente (arbitrage 10 de `rentabilite-forever.md` : personne ne paiera plus cher à l'HV). |
| Objet en sac sans aucun prix | Vaut zéro, comme aujourd'hui. |
| Recette sans objet produit (Enchantement) | Revente nulle : rien ne change pour l'enchanteur. |
| Le produit est le réactif d'une étape suivante | Crédité à la production, débité à la consommation, au même prix : ça s'annule. Les conversions réciproques (essences A→B→A) restent bornées par la garde anti-cycle existante. |
| Coût net négatif sur toute la route | Affiché comme un gain (« Gain net »), en vert. |
| Revente qui porte l'essentiel du coût net | L'infobulle le dit ; c'est le cas que la décision 4 surveille. |
| Auctionator absent | Aucune route chiffrée, comme aujourd'hui (`PR:IsAvailable`). |

## Décisions

1. **La route choisit sur le coût NET**, et affiche aussi « À débourser ». — user, 2026-10-02.
2. **Le stock en sac vaut son prix de revente** : prix HV moins la coupe de 5 %, ce que le joueur en
   tirerait. — user, 2026-10-02.
3. **La revente du produit est comptée par défaut**, avec une case pour la couper ; l'infobulle dit
   quelle part du coût repose sur une revente. — user, 2026-10-02.
4. **Pas de plafond de revente dans un premier temps** : on le montre, on plafonnera si des routes
   absurdes apparaissent en jeu. — user, 2026-10-02.
5. **L'arbitrage entre métiers** (vendre le minerai plutôt que le fondre) vient **en deuxième
   étape**, après le coût net. — user, 2026-10-02.
6. *(conséquence, pas un nouvel arbitrage)* **Une seule fonction « valeur de revente »** sert au sac
   et au produit : les deux sont le même objet vu à deux moments, et deux règles divergeraient. Elle
   hérite de l'arbitrage 10 de `rentabilite-forever.md` : le prix d'un marchand qui VEND l'objet
   plafonne sa revente ; et d'un fait du jeu : un objet lié ou sans prix HV ne vaut que son prix de
   rachat par un marchand.
7. *(conséquence)* **On construit sur `feat/profit-arbitrages`** (COC, autre session, au banc) : elle
   réécrit `CraftingOrderClassic_Profit.lua`, ajoute la provenance du prix et expose la coupe HV.
   Travailler sur `main` en parallèle garantit un conflit dans le fichier même où vit la valeur de
   revente.

## Critères d'acceptation

Tests (Elune, sur les vrais `CraftingOrderClassic_Route.lua` et `_Profit.lua`, oracle factice) :

1. `[test]` Deux recettes, même coût d'achat ; l'une produit un objet qui se revend : avec la case
   cochée, la route prend celle-là ; décochée, l'ordre d'aujourd'hui revient.
2. `[test]` Une recette qui mange un réactif en sac de grande valeur contre une recette à acheter
   moins chère en valeur : la route prend la seconde (le sac n'est plus gratuit).
3. `[test]` Le cas des retailles (capture 2026-09-26, `test_route_stock.lua`) donne toujours
   retailles → cuir léger puis kit : le choix tient, pour la bonne raison.
4. `[test]` Conversion puis consommation de son produit : le total net n'est ni le double ni zéro
   (crédit et débit s'annulent).
5. `[test]` Sans sacs et case décochée (rien à valoriser), la route et son total sont ceux
   d'aujourd'hui au cuivre près : le bloc « sans sacs » de `test_route_stock` (Light Armor Kit de 7 à
   45, 50 pa 74 pc) et `test_route_trainer` passent sans changement.
6. `[test]` Produit sans prix : revente nulle, aucun « (?) » ajouté. Produit lié : prix marchand
   seul. Produit vendu par un marchand : revente plafonnée.
7. `[test]` `Route:NextStep` choisit la même recette que le premier segment de `Route:Compute`, case
   cochée et décochée.
8. `[porte]` Libellés traduits dans les trois overlays (`check_locale.ps1`).

En jeu (le user, Forge sur le banc) :

9. `[humain]` Fenêtre Plan de route, Forge du même perso. **Témoin** : la capture du 2026-10-02
   (Forge 80, une seule ligne « Estimated total : 17 po 61 pa 91 pc »). Attendu : deux lignes sous le
   titre, « À débourser » et « Coût net » ; elles diffèrent dès que la route prend dans les sacs ou
   fabrique un objet coté à l'HV ; un coût net négatif s'écrit « Gain net », en vert.
10. `[humain]` Survol d'une étape : réactifs achetés / pris au sac, revente (avec le nombre
    d'objets), net de l'étape. Une étape dont les matières valent plus que le produit porte sa
    marque.
11. `[humain]` Décocher « Compter la revente » : la route se recalcule sur-le-champ ; recocher la
    rend.
12. `[agent]` Le prix de rachat marchand et le lien de l'objet se lisent sur Forever avec l'appel
    retenu (cf. Contrat) : **mesure** sur le client vivant (`/cocprobe` ou un `/dump`) avant de
    coder la branche « produit lié » — la doc générée ne prouve pas qu'un champ répond.

## Contrat

- **Préférence persistée** : `COC.db.routeResale` — `nil` = cochée (même convention que
  `db.routePlans`, rien à migrer), `false` = décochée. Par compte, comme `routePlans`.
- **Valeur de revente** (Profit) : une fonction, un retour en cuivre ou `nil`, de la forme
  `PR:ResaleValue(itemID)` — HV × (1 − coupe), plafonné par le prix d'achat marchand s'il existe ;
  objet lié ou sans prix HV : prix de rachat marchand. Le prix de rachat et le type de lien viennent
  du client (`C_Item.GetItemInfo`, retours `sellPrice` et `bindType`) — **à mesurer** (critère 12).
- **Segment de route** : gagne des champs (`resale`, `resaleQty`, `bagValue`), n'en perd aucun.
  Les lecteurs actuels (fenêtre, colonne greffée, suivi, bourse) les ignorent sans casser.
- Rien sur le fil réseau : la route est locale.

## Deuxième étape — l'arbitrage entre métiers (décision 5)

À spécifier quand le coût net aura été vu en jeu. Ce qu'on en sait déjà :

- La question est « mon minerai vaut-il plus vendu que fondu, compte tenu de ce que les barres
  coûtent à l'HV ? ». Elle croise deux métiers du **même perso** (Minage + Forge, Minage +
  Ingénierie) ou de deux persos du compte.
- Les données y sont : la fonte est un métier du catalogue (`Data/Camelot/Mining.lua`,
  `reagents`), la route sait décomposer un intermédiaire en ses composants (`addReagent`, garde de
  profondeur).
- La sortie attendue est un **conseil**, pas un changement de route : « Tes 449 Copper Ore valent
  ~X à l'HV ; les barres que la route consomme coûtent ~Y à l'achat. »

## Questions ouvertes (pour le user)

1. **La bourse d'artisan** (route d'un autre joueur, onglet Artisans) : elle dit ce qu'il faut
   FOURNIR à cet artisan. Garder le coût d'achat (proposé : c'est ce que le client paie), ou passer
   au coût net comme la fenêtre ?
2. **Le badge « meilleur coût/point »** de la liste pleine vue : le passer au net aussi, pour que
   badge et route racontent la même histoire (règle d'origine de la fonctionnalité), ou le laisser
   au coût d'achat ?

## Renvois

- `docs/specs/rentabilite-forever.md` — la page Profit, la coupe HV, « vendeur d'abord » (arbitrage
  10), la décision 8 que cette spec rouvre.
- `docs/specs/prix-maison.md` — Auctionator, seul oracle.
- `CraftingOrderClassic_Route.lua` — en-têtes « Stock » et « Départage » : le stock en sac et la
  garde anti-cycle que cette spec prolonge.
- Mémoire `coc-leveling-cheapest-recipe-idea` — l'historique de la route et ses angles morts
  assumés.
- Skill `wow-forever-api`, référence `metiers-et-objets.md` — ce que valent les prix d'Auctionator.

## Plan (2026-10-02 — volatil, à barrer au fil de l'eau)

Base : `feat/profit-arbitrages` fusionnée dans `main` ; sinon une branche partie d'elle, et le dire.

1. Mesurer `sellPrice` et `bindType` sur le client (critère 12). Une séance courte, un `/dump`.
2. `PR:ResaleValue` + tests (critère 6). Une session.
3. Route : valeur du sac, crédit/débit du produit, deux totaux, case ; tests 1 à 5 et 7. Une session.
4. Affichage : deux totaux, infobulle d'étape, marque « matières > produit », valeur du sac
   consommé ; locale. Puis banc (critères 9 à 11).
