# Rentabilité des recettes sur Forever

> État : **implémentée, non validée en jeu** · Rédigée le 2026-09-21 · Codée le 2026-09-21
> Cible : WoW: Forever / Camelot (16001) uniquement · Addon : Crafting Order - Classic
>
> Les portes déterministes (critères 7 à 10) sont **passées** ; les critères `[humain]` et `[outil]`
> (1 à 6) attendent une session en jeu. Rien de ce qui suit n'a été vu à l'écran.
> Vue livrée : `CraftingOrderClassic_ProfWindow_DockProfit.lua`, languette **« Profit »**.

## Le problème

Sur Classic Era, la vue métier custom de COC affichait pour chaque recette son **profit net**
(vente à l'HV − coût des réactifs) et permettait de **trier la liste par rentabilité** : c'est comme
ça qu'on décidait quoi fabriquer pour gagner de l'or.

Depuis le portage Forever, **ça a disparu de l'écran**. Pas parce que le code a été retiré — il est
intact et fonctionne — mais parce que la surface qui l'affichait n'est plus montrée : sur Forever on
ne remplace **pas** la fenêtre de métier native (elle est meilleure que la nôtre : recherche,
filtres, catégories, détail), on lui accole seulement notre colonne Commandes. Notre liste de
recettes, et avec elle le tri par rentabilité, ne s'affiche donc plus.

Le travail n'est donc pas de réimplémenter le calcul. C'est de lui **rendre une surface**.

## Ce qu'on veut

Une **quatrième languette** dans la rangée des vues de la colonne accolée, à côté des trois
existantes — **Commandes · Plan de route · Manquantes · [Profit]** (libellé arbitré, cf. décision 5) — qui affiche :

- la liste des recettes **du métier ouvert**, **triée par profit net décroissant** ;
- une ligne = le nom de la recette + son profit ;
- un clic sur une ligne **sélectionne la recette dans la fenêtre native** (on reste dans le geste :
  je repère ce qui rapporte, je le fabrique sans le chercher à la main).

C'est la même mécanique que les trois autres vues : une entrée dans `VIEWS`, une vue construite par
son `_Build*`, affichée par `_SetDockView`. Quatre états exclusifs dont un est toujours vrai — des
languettes, jamais des interrupteurs (leçon relevée sur capture en jeu le 2026-09-19).

Rien ne change dans la fenêtre de Blizzard : on l'accompagne, on ne la touche pas.

## Ce qu'on NE fait PAS

- **On ne trie pas la liste native de Blizzard** et on n'écrit rien dans ses lignes. Elles sont
  recyclées, et écrire dans le cadre hôte le teinte — on a déjà payé ~800 actions de barres d'action
  refusées pour cette leçon. Notre colonne est ancrée **à côté** (parent `UIParent`, aucune écriture
  sur l'hôte) : c'est le seul montage mesuré sans teinte.
- **On ne réimplémente aucune collecte de prix.** Auctionator est le seul oracle sur Forever, on lit
  son API publique versionnée. Scanner l'HV nous-mêmes est un autre chantier, hors sujet ici.
- **On ne liste pas les recettes NON apprises** dans cette v1. « Est-ce que ça vaudrait le coup
  d'aller l'apprendre » est une question voisine mais différente (elle vit déjà dans le mode
  « Manquantes »).
- **On ne traite pas les enchantements** : pas d'objet produit, donc pas de prix de vente, donc pas
  de profit. Leur coût existe déjà par ailleurs (`LG:CraftCost`, utilisé par la montée de métier).
- **On ne décompose pas** les intermédiaires, la prospection ni la mouture. Le profit d'une recette
  se calcule sur SES réactifs, au prix du marché, point.

## Cas particuliers

| Situation | Comportement attendu |
|---|---|
| Aucun oracle de prix (Auctionator absent/désactivé) | La languette **n'existe pas du tout**. Pas d'onglet vide, pas d'erreur. Règle existante : `LG:IsAvailable()`. |
| Prix de vente du produit inconnu | La recette **n'apparaît pas** dans la liste. Sans prix de vente, le calcul n'a aucun sens. |
| Un réactif sans prix | La recette apparaît, le coût est **sous-estimé** → marquer la ligne (le drapeau `missing` existe déjà dans `CraftProfit`). |
| Profit négatif | **Tranché le 2026-09-21 (user) : la recette ne figure pas dans la liste.** Comme dans l'ancienne liste, cette vue ne sert qu'à repérer ce qui rapporte — et une ligne avec un nom et une colonne vide ne dit pas « à perte », elle dit « prix inconnu ». Le calcul, lui, rend bien la valeur négative (verrouillé par le test 906). |
| En combat | La colonne ne s'ouvre pas / ne se rafraîchit pas. Garde : `frame:IsProtected() and InCombatLockdown()`, jamais un test de saveur. |
| Auctionator lève sur un mauvais argument | Déjà couvert : tous les appels passent en `pcall`. Ne pas retirer cette protection. |
| Liste longue (centaines de recettes) | Le profit est calculé **une fois par remplissage** et emporté par la ligne — tenu. Pas de `_profitCache` pour autant : ce cache existe parce que la colonne Recettes est VIRTUALISÉE et repeint ses lignes à chaque défilement. Cette liste-ci ne l'est pas (même motif que « Manquantes » : une ligne par entrée, posée une fois), donc le défilement ne rappelle rien. Ajouter le cache y serait un mécanisme sans emploi. ❓ **Reste non mesuré** : le coût d'une ouverture sur un métier complet (~200 recettes). |
| Aucune recette rentable | La languette reste **présente** (elle existe tant qu'un oracle répond) avec un message d'état, pas une liste vide sans explication. |
| La rangée de languettes déborde | ⚠️ **C'est le risque n°1 de cette feature** : la rangée des vues est aujourd'hui *la seule* chose qui contraint la largeur de la colonne, et une languette de trop se fait rogner. Voir les critères 4 et 5. |

## Décisions

1. **Surface = une 4ᵉ languette dans la colonne accolée** (choix du user, 2026-09-21) : pas
   d'injection dans les lignes natives, pas de fenêtre séparée, pas une section de plus empilée dans
   la vue Commandes. Raison : c'est le seul montage sans teinte, il garde le geste, et il réutilise
   le vocabulaire déjà en place dans la colonne.
2. **Les données de recette viennent du CLIENT d'abord, de nos données ensuite.** `CraftProfit` lit
   aujourd'hui `lib:RecipeProduct` / `lib:RecipeReagents` (données statiques CraftLink). Or nos
   données Camelot ont **357 recettes sans objet produit**, et le client, lui, donne le schéma exact
   en direct (`C_TradeSkillUI.GetRecipeSchematic`, déjà normalisé par `Craft_Mainline`). Pour une
   recette **apprise**, le client fait foi ; nos données restent le repli.
   *Conséquence* : une partie des 357 trous se referme sans attendre Wowhead.
3. **Auctionator reste installé** malgré les erreurs qu'il provoque sur la fenêtre native (décision
   du user, 2026-09-21). Si une erreur `SelectRecipe` / `OrdersPage` remonte pendant les tests,
   **c'est lui, pas nous** — vérifier la liste des addons avant d'enquêter.
4. **Aucun changement de fil, aucun changement de schéma persisté.** Cette feature est locale et
   display-only. Pas de `protocolVersion`, pas de migration.
5. **Le libellé est « Profit », pas « Rentabilité »** (choix du user, 2026-09-21). La rangée des vues
   est la seule chose qui contraint encore la largeur de la colonne (`sizeColumn` prend le max), et
   en mode encastré la fenêtre NATIVE s'élargit d'autant : le mot long coûtait ~90 px de fenêtre
   pour la même information. Contrepartie assumée : « Rentabilité » reste le titre de la section du
   panneau d'info, donc deux mots pour une même chose.
6. **Une recette à perte ne figure pas dans la liste** (choix du user, 2026-09-21) — cf. la table
   ci-dessus. Le calcul continue de rendre la valeur négative ; c'est la VUE qui tranche.
7. **Le clic passe par `C_TradeSkillUI.OpenRecipe(recipeID)`**, la voie du jeu — le suivi
   d'objectifs de Blizzard l'emprunte telle quelle. Elle répond par l'événement
   `OPEN_RECIPE_RESPONSE`, que le code de Blizzard traite **dans son contexte** : rien n'est écrit
   chez lui depuis le nôtre. Sur la ligne de métier ouverte son traitement se borne à
   `CraftingPage:Init` (lu dans `Blizzard_ProfessionsFrame.lua`), donc la fenêtre n'est ni rouverte
   ni déplacée — ce que le critère 2 doit constater à l'écran.
8. **`LG:CraftCost` n'a PAS été touchée.** Elle sert la montée de métier et la bourse d'artisan, deux
   chantiers clos et validés en jeu ; leur faire changer de source de données n'est pas dans cette
   spec. Elle lit donc toujours le catalogue seul. À rouvrir sciemment, pas par effet de bord.

## Critères d'acceptation

1. `[humain]` ⏳ Fenêtre de métier ouverte sur Forever, Auctionator présent : la languette
   « Profit » est **visible et cliquable**, et sa première ligne est la recette au **plus gros
   profit**. *Témoin connu-bon :* recalculer à la main le profit de deux recettes depuis les prix
   qu'Auctionator affiche sur les objets.
2. `[humain]` ⏳ Un clic sur une ligne **sélectionne cette recette dans la fenêtre native**, sans la
   fermer ni la déplacer.
3. `[humain]` ⏳ Auctionator désactivé → la languette **n'apparaît pas**, les trois autres se
   repositionnent proprement, et rien d'autre ne change. Aucune erreur Lua.
4. `[outil]` ⏳ **Les QUATRE languettes tiennent dans la rangée**, sans rognage ni chevauchement, dans
   les deux modes (colonne accolée et vue custom). → `/co geo`, qui mesure exactement ça et qui
   existe depuis la série de correctifs de géométrie de la greffe. Le relever **avant/après**.
5. `[humain]` ⏳ Confirmation visuelle du point 4 sur capture : la 4ᵉ languette est entièrement lisible,
   la dernière n'est pas coupée par le bord de la colonne.
6. `[humain]` ⏳ Entrer en combat avec la colonne ouverte : **aucune action refusée** dans
   `Logs\taint.log`, et les barres d'action restent utilisables après le combat.
7. `[test]` ✅ Le calcul de profit reste identique à formule constante (vente × quantité × 0,95 −
   coût) : un test headless sur `CraftProfit` avec un oracle de prix bouchonné.
   → **`tests/test_profit.lua`** (28 vérifications, intégré à `run_all.lua` : 920 au total).
8. `[test]` ✅ Une recette sans produit connu, une recette avec un réactif sans prix, une recette au
   profit négatif : les trois cas rendent ce que la table « Cas particuliers » annonce.
9. `[porte]` ✅ Toute nouvelle chaîne d'interface est traduite dans les trois overlays
   (enUS/deDE/esES). → `scripts\check_locale.ps1`.
10. `[porte]` ✅ ≤ 500 lignes par fichier, ≤ 60 lignes par fonction. → hook `check_size`. La vue va
    dans **son propre fichier** (`_ProfWindow_DockProfit.lua` ou équivalent), pas dans
    `_DockViews.lua` qui est déjà chargé.
11. `[agent]` ✅ Aucune écriture dans le cadre hôte, aucun `SetParent` vers un cadre Blizzard, aucun
    global Classic mort utilisé en valeur de vérité. → agent `api-gotcha-reviewer`, passé le
    2026-09-21 : **aucune correction requise** sur les 6 points prioritaires. Trois remarques de
    faible gravité, toutes déjà tracées ici — coût de calcul non mesuré (table ci-dessus), valeur
    réelle de `Enum.CraftingReagentType.Basic` (tranchée depuis : elle est déclarée dans le source
    du client, cf. le commentaire de `BASIC_REAGENT`), et le fait que `VIEWS.profit.shown` ne teste
    pas la saveur — sans objet tant qu'il n'y a qu'un `.toc` 16001.

## Ce qui restait à vérifier — état au 2026-09-21

- **Quantité produite par craft.** ✅ *sur le papier, ❓ en jeu.* `CraftingRecipeSchematic` déclare
  `quantityMin` et `quantityMax` **non nilables** (`TradeSkillUITypesDocumentation.lua` du source
  Forever), et `Craft_Mainline.getNumMade` les lisait déjà. `MainlineRecipeCraft` retient
  **`quantityMin`** et non la moyenne : sur un lot variable, la borne basse est la seule qu'on soit
  sûr d'obtenir — un profit annoncé trop bas se corrige à la première fabrication, l'inverse fait
  fabriquer à perte. **Reste à constater en jeu** qu'une recette en lot (bandages, barres) annonce
  bien son lot : la déclaration dit que le champ existe, pas qu'il est juste sur cette saveur.
- **Coût de calcul sur un métier complet.** ❓ **Non mesuré.** Le calcul est fait une fois par
  remplissage (pas à chaque défilement) et chaque recette coûte un appel d'oracle par réactif, plus
  un pour le produit. Si l'ouverture de la languette marque un temps sur un métier complet, le
  prochain geste est le calcul par lots — pas une optimisation à l'aveugle avant d'avoir vu le temps.
- **Largeur de la rangée à quatre languettes.** ❓ **Non mesuré** — le libellé court a été choisi
  pour cette raison (décision 5). À relever avec `/co geo` avant/après (critère 4) : le relevé porte
  maintenant le panneau sous la clé `profit`, et la rangée `vues` sort déjà sa `marge` droite
  (négative = ça déborde).
- **Un `.lua` de plus = redémarrage complet du client**, pas un `/reload`. ⚠️ **S'applique :**
  `CraftingOrderClassic_ProfWindow_DockProfit.lua` est neuf dans le `.toc`.

## Renvois

- Code existant à réutiliser **tel quel** : `CraftingOrderClassic_LazyGold.lua`
  (`CraftProfit`, `EntryProfit`, `ProfitTier`, `ProfitText`, `IsAvailable`, `PriceSource`).
- Surface : `CraftingOrderClassic_ProfWindow_DockViews.lua` — la table `VIEWS`, `_BuildDockViewBtns`,
  `_SetDockView`, `_PlaceOrdTabs`, `_TabTop` (c'est là que la 4ᵉ languette s'ajoute) ;
  `CraftingOrderClassic_ProfWindow_Dock.lua` (`PW:OpenDock`) ;
  `CraftingOrderClassic_ProfWindow_Camelot.lua` (la greffe, ses règles et la contrainte de largeur) ;
  `CraftingOrderClassic_ProfWindow_Geo.lua` (`/co geo` — le juge de la géométrie).
- Référence de l'ancienne liste triée : `CraftingOrderClassic_ProfWindow_Recipes.lua`
  (`recipeSortProfit`, `_RowProfit`, `_FillRecipeRight`, `_SyncSortHeader`).
- Backend mainline : `CraftingOrderClassic_Craft_Mainline.lua` (`GetRecipeInfo`,
  `GetRecipeSchematic`, caches, `reagentItemID`).
- Skills : **wow-classic-addon-dev** (pièges Forever, taint, conventions), **coc-native-ui**
  (chrome natif), **human-verification** (les critères `[humain]` ci-dessus).
- Mémoires : `forever-auctionator-breaks-professions`, `coc-camelot-recipe-data`,
  `coc-leveling-cheapest-recipe-idea`, `lua-and-truncates-multireturn`.
