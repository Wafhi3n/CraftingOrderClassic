# Vue reroll à l'allure de la fenêtre de métier du jeu

> État : **validée, pas codée** · Demandée par le user le 2026-09-30 ; forme tranchée par lui le
> 2026-10-03 (une fenêtre, notre colonne à droite, partout, affichage des réactifs du jeu) après deux
> labos DevMacro vus en jeu.
> Cible : WoW: Forever / Camelot (16001) · Addon : Crafting Order - Classic

## Le problème

Sur Forever, quand on ouvre le métier du perso connecté, on a la fenêtre de métier du jeu (liste à
catégories, panneau recette avec icône et réactifs, fond du métier) et notre colonne Commandes greffée
à droite. Quand on ouvre celui d'un **reroll**, par le clic de l'icône de la minicarte ou depuis
« Mes artisans », on tombe sur une tout autre fenêtre : l'ancienne vue de Crafting Order, détachée et
flottante, avec son propre habillage. Le joueur passe d'une interface à une autre pour la même chose,
voir ce qu'un perso sait faire. Le user : « changer l'ui de la vue reroll par la vue ui native si
possible ».

La fenêtre de métier du jeu ne peut pas servir telle quelle : elle ne lit que le perso connecté
(`C_TradeSkillUI`), et les recettes d'un reroll n'existent que dans notre SavedVariable.

## Ce qu'on veut

Une **seule fenêtre**, qui ressemble à la fenêtre de métier du jeu, pour le métier d'un reroll :

- le **cadre du jeu** (portrait rond avec l'icône du métier, barre de titre, croix) ; le titre dit de
  qui il s'agit et que c'est en lecture seule : « Anatarion — Couture (lecture seule) » ;
- à gauche, **la liste de recettes du jeu** (en-têtes de catégories repliables, fond, barre de défilement,
  recherche) remplie avec les recettes que ce reroll connaît, rangées par nos catégories
  (« Chest · Cloth », « Shirt »…) ;
- à droite, **le panneau recette du jeu** : un clic sur une recette l'affiche (icône, nom, réactifs) ;
- collée à droite, **notre colonne** en mode reroll, comme sur la fenêtre de métier du jeu : la liste
  des commandes du métier, avec la marque de celles que le reroll sait faire. Les vues Route, Missing
  et Profit restent cachées en mode reroll, comme avant : elles lisent la fenêtre du perso connecté.
  Un clic sur une commande affiche sa recette dans le panneau ;
- **aucun bouton Créer** : on n'est pas sur ce perso.

Elle **remplace l'ancienne vue reroll partout** sur Forever : clic de l'icône de la minicarte et
« Mes artisans ».

## Ce qu'on NE fait PAS

- **Pas la fenêtre de métier du jeu elle-même** : impossible, elle ne connaît que le perso connecté.
- **Pas de création, pas de file de craft** : lecture seule.
- **Pas les catégories de Blizzard** : le jeu rend `categoryID = 0` pour une recette que le perso
  connecté ne connaît pas. Nos catégories (`COC.SectionOf`) les remplacent.
- **Pas le menu de filtres** de la liste (il ne vaut que pour le perso connecté), **pas de clic droit**
  (il ouvre un menu `MenuUtil`, interdit depuis un addon), **pas de favoris ni de suivi**, **pas de
  nombre « fabricable »** (il compterait les sacs du perso connecté).
- **Pas les sacs du reroll** : l'addon ne les connaît pas (voir Décisions, réactifs).
- **Pas l'Era** : cible gelée, la vue n'existe que sur Forever.

## Cas particuliers

- **Recette du reroll que le jeu ne décrit pas** (`C_TradeSkillUI.GetRecipeInfo` rend nil, recette du
  catalogue absente du client) : la ligne existe quand même, au nom du catalogue ; le panneau affiche
  ce que le catalogue sait (nom, icône, réactifs) au lieu de rester vide.
- **Reroll dont le métier n'a jamais été ouvert** (pas de recettes lues) : pas de fenêtre vide muette ;
  un message dans la liste dit d'ouvrir ce métier une fois sur ce perso.
- **Ouverture en combat** : comme aujourd'hui, refusée avec « Hors combat seulement. » tant que la
  colonne peut être greffée dans la fenêtre du jeu (elle est alors protégée). La fenêtre reroll, elle,
  est à nous et ne l'est pas.
- **La fenêtre du jeu est déjà ouverte** : on la ferme et on reprend la colonne (geste actuel).
- **Réactifs au survol, avec Auctionator** : Auctionator lève une erreur (`Hooks.lua:73`,
  `OrdersPage` nil) au survol d'un réactif dans n'importe quel panneau recette quand la fenêtre de
  métier du jeu est fermée, y compris depuis un lien de recette Blizzard. Ce n'est pas notre défaut.
  Contournement à mesurer (notre infobulle sur les cases) ; sinon documenté.
- **Recette sélectionnée qui disparaît** (la commande est acceptée ailleurs, le reroll oublié) : le
  panneau revient à vide, pas d'erreur.

## Décisions

- 2026-10-03, **le user** : une seule fenêtre (liste + panneau recette), pas deux fenêtres côte à côte.
- 2026-10-03, **le user** : les commandes du reroll vivent dans notre colonne, collée à droite.
- 2026-10-03, **le user** : la nouvelle vue remplace l'ancienne partout (icône et « Mes artisans »).
- 2026-10-03, **le user** : les réactifs gardent **l'affichage du jeu**, qui compte les sacs du perso
  CONNECTÉ (« 0/2 Bolt of Linen Cloth » chez Rédemption). Utile pour préparer les matériaux à envoyer ;
  l'ancienne vue n'affichait que la quantité à fournir.
- 2026-10-03, l'agent, d'après les labos : le panneau recette est **le nôtre**
  (`ProfessionsRecipeSchematicFormTemplate` créé dans notre fenêtre, `isInspection = true` posé avant
  `Init`), pas `InspectRecipeFrame` de Blizzard : on ne pilote aucun cadre global.
- 2026-10-03, l'agent : les lignes de la liste sont créées par **notre fabrique** (le modèle de ligne du
  jeu, nos scripts) ; la fabrique de Blizzard appelle `GetCraftableCount` et ouvre un menu au clic droit.
- 2026-10-03, l'agent : la recette passée au panneau vient du jeu (`GetRecipeInfo`), mais la ligne de la
  liste est construite par nous avec `learned = true` : le jeu rend `learned = false` pour une recette
  du reroll et la liste grise tout ce qui n'est pas appris.

## Mesures (labos DevMacro, build 70205, 2026-10-03, Rédemption, aucune fenêtre de métier ouverte)

- `C_TradeSkillUI.GetRecipeInfo(2387)` (Cape en lin, connue d'Anatarion seul) → table, nom,
  `learned=false`, `categoryID=0`. `GetRecipeSchematic(2387, false)` → 2 réactifs, objet 2570.
  `GetProfessionInfoByRecipeID` → Tailoring, 2948. Pareil pour 2152 (Sheadra). La recette du perso
  connecté (7745) : `learned=true`, `cat=2501`.
- `InspectRecipeFrame:Open(2387)` : le cadre du jeu s'ouvre sur la recette d'Anatarion (capture).
- `ProfessionsRecipeListTemplate` rempli de nos données, notre fabrique de lignes : liste du jeu, nos
  catégories, repli et recherche visibles (capture 09:51).
- `ProfessionsRecipeSchematicFormTemplate` créé dans notre fenêtre, `isInspection` posé avant `Init` :
  la Blue Linen Shirt d'Anatarion s'affiche avec ses trois réactifs (capture ~09:56).
- `SetPortraitToTexture` n'existe pas sur ce client : `frame:SetPortraitToAsset(
  C_TradeSkillUI.GetTradeSkillTexture(professionID))`.

## Critères d'acceptation

1. [test] Les recettes d'un reroll (`db.knownRecipes[clé][métier]`) donnent un arbre catégories →
   recettes : chaque recette une fois, sous sa catégorie COC, `learned = true`, triée ; une recette sans
   produit connu reste listée au nom du catalogue. → `tests/test_reroll_native.lua`
2. [test] La recherche ne garde que les recettes dont le nom contient le texte (sans tenir compte de la
   casse), et les catégories qui en ont encore. → même fichier
3. [test] Le clic d'une commande dans la colonne en mode reroll choisit sa recette (par `spellID`, ou par
   l'objet via `itemToSpell`). → même fichier
4. [porte] Les quatre portes ; toute chaîne neuve dans les trois overlays.
5. [humain] Clic de l'icône de la minicarte sur une commande qu'Anatarion seul sait faire : la fenêtre
   s'ouvre au cadre du jeu, titre « Anatarion — Couture (lecture seule) », portrait de la Couture, la
   liste rangée par catégories, la colonne collée à droite. Témoin : la fenêtre de métier du jeu de
   Rédemption ouverte juste avant, et la maquette du 2026-10-03. Observateur : le user, sur capture.
6. [humain] Un clic sur une recette l'affiche dans le panneau ; un clic sur une commande de la colonne
   affiche la sienne. Même témoin.
7. [humain] « Mes artisans » ouvre la même fenêtre ; l'ancienne vue n'apparaît plus nulle part.
8. [humain] **Taint**, avec témoin : `/console taintLog 1`. Témoin : ouvrir la fenêtre de métier du jeu
   de Rédemption, la fermer, un combat ; relever `Logs\taint.log`. Puis mêmes gestes après avoir ouvert
   et fermé la vue reroll. Passe : aucune ligne nouvelle qui accuse CraftingOrderClassic, aucun
   `ADDON_ACTION_BLOCKED` de COC dans BugGrabber.
9. [humain] Rien de COC dans BugGrabber après une séance (ouverture, défilement, recherche, clics,
   fermeture, ouverture de la fenêtre du jeu juste après).

## Contrat

- `PW:OpenForReroll(prof, rerollKey, short)` garde sa signature : c'est l'entrée de l'icône de la
  minicarte (`MinimapIndicator_Orders`) et de « Mes artisans » (`UI_MyArtisans_Reroll`).
- La fenêtre reroll est un cadre à nous, jamais un cadre de Blizzard réutilisé ; on ne touche ni à
  `ProfessionsFrame` ni à `InspectRecipeFrame`.

## Renvois

- `docs/specs/icone-commande-recue.md` (le clic qui y mène ; « Ce qu'on NE fait PAS » notait cette
  demande).
- Skill `coc-native-ui` (la greffe de la colonne, le kit natif) ; skill `wow-forever-api` (taint,
  cadres protégés, menus interdits).
- Source Blizzard relue : `Blizzard_ProfessionsTemplates/Blizzard_ProfessionsRecipeList.lua|.xml`,
  `Blizzard_ProfessionsRecipeSchematicForm.lua`, `Blizzard_Professions/Blizzard_ProfessionsInspectRecipe.lua`.

## Plan (2026-10-03, volatil)

1. Données pures : arbre catégories → recettes depuis `knownRecipes`, filtre de recherche, recette d'une
   commande (critères 1-3) ; tests.
2. La fenêtre : cadre du jeu, liste du jeu avec notre fabrique, panneau recette, chargement du module
   `Blizzard_Professions` à la demande ; ouverture par `PW:OpenForReroll` à la place de l'ancienne vue.
3. La colonne collée à droite en mode reroll, clic d'une commande → panneau.
4. Cas particuliers (recette inconnue du jeu, reroll sans recettes, combat), Auctionator à mesurer.
5. Banc : critères 5-9 en jeu, taint avec témoin.
