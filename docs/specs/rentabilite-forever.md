# Rentabilité des recettes sur Forever

> État : **implémentée** · Rédigée le 2026-09-21 · Codée le 2026-09-21 · Arbitrages 9 à 12 ajoutés
> le 2026-09-23 (user), **codés le 2026-09-29** (branche `feat/profit-arbitrages`, dépôts COC et
> outillage) · Cible : WoW: Forever / Camelot (16001) uniquement · Addon : Crafting Order - Classic
>
> Vu en jeu le 2026-09-26 (registre) : la languette s'affiche, la liste est triée par profit
> décroissant, la fenêtre native n'est ni fermée ni déplacée (critère 1, en partie). Les arbitrages
> 9 à 12 ont été **vus en partie le 2026-09-29** (captures, détail sous les critères 12 à 14) ; un
> défaut vu ce jour-là (noms longs sur deux lignes) est corrigé et pas revu. Vue livrée :
> `CraftingOrderClassic_ProfWindow_DockProfit.lua`, languette **« Profit »**.
>
> ⚠️ **Le clic sur une ligne est probablement inerte** (critère 2). Il passe par
> `C_TradeSkillUI.OpenRecipe`, qui ne sélectionne RIEN quand la fenêtre est déjà ouverte : elle
> attend une réponse serveur qui ne vient pas sur Forever (skill `coc-native-ui`, piège 22). Et
> l'autre voie, `RecipeList:SelectRecipe`, teinte la chaîne du craft — mesuré le 2026-09-22, cf. le
> commentaire de `_ProfWindow_Trade.lua`. Le relevé du 2026-09-26 a vu une recette sélectionnée
> sans pouvoir l'attribuer au clic. Non corrigé ici : hors des arbitrages 9 à 12, et le choix
> (retirer le clic, ou le garder pour une recette absente de la liste) revient au user.

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
- ~~**On ne liste pas les recettes NON apprises** dans cette v1.~~ **AMENDÉ le 2026-09-23 (décision
  9)** : le défaut reste les recettes apprises, mais une **bascule « tout le métier »** est ajoutée.
  « Manquantes » continue de dire *où* apprendre ; cette bascule dit *ce que ça rapporterait*.
- ~~**On ne traite pas les enchantements** : pas d'objet produit, donc pas de prix de vente, donc
  pas de profit.~~ **RENVERSÉ le 2026-09-23 (décision 12)** : ils sont traités, par le **coût**
  (`PR:CraftCost`, qui n'a pas besoin d'un prix de vente) et non par la marge. Sans ça, la page est
  vide pour un enchanteur — indiscernable d'une page cassée.
- **On ne décompose pas** les intermédiaires, la prospection ni la mouture. Le profit d'une recette
  se calcule sur SES réactifs, au prix du marché, point.

## Cas particuliers

| Situation | Comportement attendu |
|---|---|
| Aucun oracle de prix (Auctionator absent/désactivé) | La languette **n'existe pas du tout**. Pas d'onglet vide, pas d'erreur. Règle existante : `PR:IsAvailable()`. |
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
8. **`PR:CraftCost` n'a PAS été touchée.** Elle sert la montée de métier et la bourse d'artisan, deux
   chantiers clos et validés en jeu ; leur faire changer de source de données n'est pas dans cette
   spec. Elle lit donc toujours le catalogue seul. À rouvrir sciemment, pas par effet de bord.

### Arbitrages du 2026-09-23 (user) — postérieurs, ils l'emportent

9. **La liste s'ouvre sur ce que je peux crafter MAINTENANT**, et gagne une **bascule « tout le
   métier »** qui montre aussi ce que rapporterait une recette non apprise, visiblement distinguée.
   *Ça amende la décision « on ne liste pas les recettes NON apprises dans cette v1 »* : le défaut ne
   change pas, la bascule est un ajout. Le lien avec « Manquantes », qui dit où apprendre, reste
   entier.
10. **Le prix de VENTE garde « vendeur d'abord »**, tel que `ItemValue` le fait déjà des deux côtés
    du calcul. Raison : si un marchand vend l'objet, personne ne paiera plus cher à l'hôtel des
    ventes — le prix vendeur est un **plafond honnête**, et l'inverse gonflerait des marges qu'on ne
    réalisera jamais. **Conséquence obligatoire** : la ligne **nomme sa source** au survol (marchand
    ou HV), sinon le chiffre passe pour faux auprès de qui voit l'HV afficher autre chose.
11. **La coupe de 5 % reste en dur**, et s'affiche dans le détail du calcul plutôt que d'être
    réglable. Un réglage de plus pour une constante du jeu ne paie pas sa place ; l'afficher suffit
    à ce que personne ne cherche d'où vient l'écart.
12. ⚠️ **L'Enchantement EST traité — par le COÛT, pas par la marge.** *Ça RENVERSE la décision
    « on ne traite pas les enchantements » prise le 2026-09-21.* Motif : `CraftProfit` exige un prix
    de vente et rend `nil` sans objet produit, donc pour un enchanteur la page serait **vide** — et
    une page vide ne se distingue pas de « cette page ne sait pas parler de mon métier ».
    `CraftCost` fonctionne sans prix de vente : la vue bascule alors en « ce que coûte chaque
    enchantement à lancer », ce qu'un enchanteur a précisément besoin de savoir pour fixer sa
    commission — et qui rejoint l'offre LFW (cf. `docs/specs/lfw-forever.md`). La page **dit** qu'elle
    affiche un coût et pas un gain : un montant dont on ignore le signe est pire que pas de montant.

### Choix d'implémentation du 2026-09-29 — pris en codant, à confirmer par le user

Les arbitrages 9 à 12 laissaient ces points ouverts. Chacun est un réglage d'une ligne s'il ne
convient pas.

13. **Le mode COÛT se décide par MÉTIER, pas par recette** (`COST_ONLY = { Enchanting = true }`,
    `_ProfWindow_DockProfit.lua`). Une liste qui mêlerait les profits de ce qui a un objet produit
    (baguettes, huiles) et les coûts du reste alignerait des montants de sens opposés sous le même
    titre, et c'est justement ce que la décision 12 interdit.
14. **Mode coût : le plus cher en tête.** C'est là qu'une commission mal fixée coûte le plus. Même
    sens que la liste des profits, où le tri EST le montant.
15. **La case « Tout le métier » est un état de SESSION**, pas une préférence enregistrée : la liste
    s'ouvre sur ce qu'on sait fabriquer (décision 9), et aucun schéma persisté n'est touché
    (décision 4). Elle reste cochée d'un métier à l'autre jusqu'au `/reload`.
16. **Le détail montre la vente BRUTE du lot** (prix × quantité), plus la coupe, les réactifs et le
    net, de sorte que vente − coupe − réactifs retombe sur le net au cuivre près. Avant, il montrait
    le prix UNITAIRE suivi de « ×2 », et la colonne ne s'additionnait pas.
17. **Le coût de l'Enchantement se lit comme le profit : le client d'abord** (`PR:RecipeCost`,
    même schéma que `CraftProfit`, décision 2). `PR:CraftCost` reste au catalogue seul pour la
    montée de métier et la bourse d'artisan (décision 8). Les deux comptent les réactifs avec le
    même code (`reagentsCost`) : elles ne diffèrent que par la source, et ne peuvent pas diverger
    sur la façon de compter.

## Critères d'acceptation

1. `[humain]` ◐ Fenêtre de métier ouverte sur Forever, Auctionator présent : la languette
   « Profit » est **visible et cliquable**, et sa première ligne est la recette au **plus gros
   profit**. *Témoin connu-bon :* recalculer à la main le profit de deux recettes depuis les prix
   qu'Auctionator affiche sur les objets. → Languette et tri **vus le 2026-09-26** (registre) ; le
   recalcul à la main n'a pas été fait.
2. `[humain]` ⏳ Un clic sur une ligne **sélectionne cette recette dans la fenêtre native**, sans la
   fermer ni la déplacer. ⚠️ Probablement **faux** aujourd'hui, cf. l'avertissement en tête.
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
   → **`tests/test_profit.lua`** (découvert par `run_all.lua`).
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

Arbitrages 9 à 12 (codés le 2026-09-29) :

12. **Bascule « Tout le métier »** (arbitrage 9).
    `[test]` ✅ Case décochée : seules les recettes apprises ; cochée : les manquantes du métier
    OUVERT s'ajoutent, marquées non apprises. Tri, doublons, en-têtes, perte et zéro écartés. →
    `tests/test_profit_view.lua`.
    `[humain]` ◐ À l'ouverture de la fenêtre, la case est **décochée**. Cochée, des lignes au **nom
    gris et à l'icône éteinte** apparaissent parmi les autres, et leur infobulle renvoie à
    « Manquantes ». Le titre et la case tiennent sur une ligne, sans chevauchement avec le « i ».
    → **Vu le 2026-09-29** (captures, Travail du cuir 45/75 et Enchantement) : titre et case sur
    une ligne, le « i » à gauche de la rangée ; case cochée, une recette non apprise porte la phrase
    qui renvoie à « Manquantes ». **Pas vu** : la case décochée à l'ouverture, et le gris lui-même —
    toutes les lignes visibles étaient non apprises, rien à quoi comparer.
13. **Source du prix et coupe HV dans le détail** (arbitrages 10 et 11).
    `[test]` ✅ Prix marchand prioritaire et nommé ; vente brute − coupe − réactifs = net au cuivre
    près ; un seul retour pour `ItemValue`. → `tests/test_profit.lua`, sections 10 et 11.
    `[humain]` ⏳ Au survol d'une ligne : quatre lignes (vente, « Coupe HV (5 %) », réactifs, net)
    qui s'additionnent à l'œil. Pour un objet qu'un PNJ vend, la première ligne dit « Vente (prix
    marchand) », et une phrase dit que l'HV ne paiera pas plus. *Témoin :* un objet vendu en ville et
    fabricable (fil, teinture, flacon), dont Auctionator connaît le prix marchand.
    → **Vu le 2026-09-29** pour l'HV : « Mystic Heavy Armor Kit », vente 2g 95s, coupe −14s 75c,
    réactifs −1g 25s 88c, net +1g 54s 37c — 29500 − 1475 − 12588 = 15437, le compte tombe juste.
    **Pas vu** : la ligne « prix marchand ».
14. **Enchantement par le coût** (arbitrage 12).
    `[test]` ✅ En mode coût, la liste lit `RecipeCost` (client d'abord) et jamais `CraftProfit` ;
    `CraftCost` reste au catalogue. → `tests/test_profit.lua` §12, `tests/test_profit_view.lua` §3.
    `[humain]` ◐ Fenêtre d'Enchantement ouverte : la languette Profit s'intitule **« Coût à lancer
    (N) »**, liste des enchantements, le plus cher en tête, et l'infobulle dit que c'est un coût et
    pas un gain. Revenir sur un autre métier rend « Rentables (N) ». Un nom long tient sur UNE ligne,
    tronqué par « … ». *Témoin :* le coût d'un enchant recalculé à la main depuis les prix de ses
    composants.
    → **Vu le 2026-09-29** : « Cost to cast (176) », trié de 81g 24s à 10g 70s. **Défaut vu** : les
    noms longs (« Enchant Necklace - Deflection ») passaient à la ligne et mordaient sur la suivante
    — corrigé par `SetWordWrap(false)`, pas revu. Les montants s'affichent en blanc dans les DEUX
    modes : la couleur par mode prévue d'abord n'a aucun effet et a été retirée, le titre porte
    seul le « c'est un coût ». **Pas vu** : l'infobulle d'un enchant, le témoin. Constat : la liste
    comprend aussi les recettes d'Enchantement qui produisent un OBJET (Twisting Essence Jar, bâtons,
    Truesilver Conduit), lues par le coût comme le reste — c'est le choix 13.

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
- **Largeur de la rangée à quatre languettes.** ✅ **Mesurée le 2026-09-26** (`/co geo`, client
  anglais) : colonne 227 px, rangée 212 px, marge droite 9 px — elle tient. Le même relevé a vu le
  « i » recouvrir le coin de la languette Profit (11 × 17 px) : c'est ce chevauchement que le
  critère 4 doit voir disparu, pas la largeur.
- **Un `.lua` de plus = redémarrage complet du client**, pas un `/reload`. ⚠️ **S'applique :**
  `CraftingOrderClassic_ProfWindow_DockProfit.lua` est neuf dans le `.toc`.

## Renvois

- Code existant à réutiliser **tel quel** : `CraftingOrderClassic_Profit.lua` (ex-`_LazyGold.lua`)
  (`CraftProfit`, `EntryProfit`, `ProfitTier`, `ProfitText`, `IsAvailable`, `PriceSource`).
  Ajouts du 2026-09-29 : `RecipeCost`, `ProfitLines`, `PR.AH_CUT`, et `sellSrc`/`gross`/`cut` dans
  le résultat de `CraftProfit`. Le « meilleur plan » (`BestPlanFor`, `BestKnownPlanFor`…) est
  passé dans `CraftingOrderClassic_Profit_Best.lua`, pour que `_Profit.lua` tienne sous 500 lignes.
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
