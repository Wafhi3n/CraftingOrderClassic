# Onglet Artisans : une ligne ne dit que ce qui compte

> État : **implémentée** le 2026-09-30 sur `feat/refonte-artisans`, **pas vue en jeu** · Décidé le
> 2026-09-30 par le user, sur maquette
> Maquette (artefact Design, deux planches : la capture annotée, la proposition) :
> https://claude.ai/artifact/D6dz2g5zmd8ohH48zoaFj2
> Cible : WoW: Forever / Camelot (16001) · Addon : Crafting Order - Classic

## Le problème

Une capture du user (2026-09-30, client anglais, Ironforge, douze artisans dont trois en ligne)
montre un annuaire où tout se ressemble :

1. douze boutons rouges « Whisper », dont neuf sur des joueurs hors ligne. Le rouge domine la liste
   et ne dit plus qui est joignable ;
2. toutes les icônes de métier sont grises, et la bourse à côté est en or plein. On ne lit plus qui
   fait quoi, et l'action secondaire est ce qui brille le plus ;
3. « [Partner] Syrine Lytha… » est coupé : le préfixe mange le nom, alors que l'icône partenaire, à
   droite, dit déjà la même chose ;
4. « Offline · lvl ? » sur chaque ligne répète la pastille, et « lvl ? » n'apprend rien ;
5. « MET » sur dix lignes sur douze : une étiquette que tout le monde porte n'informe pas ;
6. la liste des canaux surveillés a 176 px pour 13 lignes (234 px) : un groupe sur quatre est sous
   le pli, un autre est coupé. Au-dessus, sept bandes SOURCE, dont « Added 0 » et « Muted 0 » ;
7. « Directory » porte trois sens : la bande des joueurs croisés, le groupe des communautés dans
   les canaux, et le bouton qui rafraîchit tout l'annuaire ;
8. le panneau de première connexion ne se rouvre que par une commande (`/co watch setup`).

## Ce qu'on veut

**Une ligne ne dit que ce que sa pastille et la bande SOURCE choisie ne disent pas déjà.**

- **Chuchoter** reste rouge pour un joueur joignable (pastille verte ou jaune). Pour un joueur hors
  ligne, le bouton s'éteint (gris), mais il reste cliquable.
- **Les icônes de métier sont en couleur.** Un métier rentable se reconnaît à son liseré doré, plus
  à ce que les autres sont éteints.
- **Le nom** est blanc quand on peut parler au joueur, gris quand il est hors ligne, comme dans la
  liste d'Amis. Plus de préfixe « [Partenaire] » : l'icône partenaire allumée et la place en tête de
  liste le disent. Le préfixe « [Dispo] » reste, lui ne se lit nulle part ailleurs.
- **La sous-ligne** donne le niveau (« niv 14 »), puis les commandes livrées. L'état n'y est écrit
  que s'il apprend quelque chose : « En ligne · sans addon » toujours (il explique des métiers
  périmés), « En ligne » ou « Hors ligne » seulement quand le niveau est inconnu. Plus de « niv ? ».
- **L'étiquette de source** ne s'affiche pas pour un joueur croisé, ni quand une bande SOURCE est
  choisie. Pour un membre d'un cercle, elle porte le nom de la communauté. « RELAIS » et « VU »
  restent toujours : ce sont des états de la fiche, pas une source.
- **La barre latérale** : les bandes SOURCE ne sont plus que des sources (Tous, Guilde, Amis, Croisés,
  les cercles, et Ajoutés à partir d'un joueur ajouté). « En sourdine » descend avec l'ajout de
  joueur. « Rafraîchir l'annuaire » passe dans la barre du bas de la fenêtre, à côté du compte
  d'artisans. La liste des canaux récupère la place.
- **La bande « Annuaire » s'appelle « Croisés »**, le mot de l'étiquette de ses lignes.
- **Un bouton « Configurer »**, à droite de l'en-tête des canaux, rouvre le panneau de première
  connexion.

## Ce qu'on NE fait PAS

- **On ne touche pas aux compteurs.** Le pied dit 39 artisans, la bande « Tous » 28 : le pied compte
  tout l'annuaire, la bande seulement le camp du joueur. Le user veut l'analyser plus tard ; le pied
  est celui de la fenêtre, le changer change tous les onglets.
- **Le contenu de la liste des canaux ne change pas** (groupes, cases, défauts) : spec
  `canaux-surveilles.md`. Seules sa hauteur et son en-tête bougent.
- **Pas de filtre de la liste par canal** (décision de `canaux-surveilles.md`).
- **On ne change pas le calcul du profit**, ni ses seuils : seulement ce que devient une icône sans
  plan rentable.
- **« Annuaire » reste dans les menus de Commande, de Récolte et de la colonne des métiers.** La
  branche `feat/liste-destinataires` (autre session) réécrit ces menus ; les renommer ici lui ferait
  un conflit. À faire après sa fusion, voir § Reste à faire.
- **Le bouton gris n'est pas désactivé.** Une présence peut se tromper, et un chuchotement à un
  joueur qui vient de revenir doit partir.

## Cas particuliers

- **Ligne fusionnée (rerolls)** : mêmes règles. Le joueur est « en ligne » si un de ses persos l'est ;
  la sous-ligne dit alors « En ligne via <perso> », comme avant.
- **Fiche relayée, non-porteur vu crafter** : leur sous-ligne (« via X · il y a 2 h », « vu
  crafter : Couture ») ne change pas.
- **Communauté au nom long** : l'étiquette est tronquée par « … » (84 px), elle ne passe pas sur les
  icônes de métier.
- **Plus de quatre cercles** : seules quatre bandes existent, mais l'étiquette d'une ligne connaît le
  nom de tous les cercles.
- **« Ajoutés » choisie quand son dernier joueur disparaît** : on retombe sur « Tous », comme pour
  une bande de cercle quitté.
- **Une communauté de plus, ou un premier joueur ajouté** : la pile SOURCE grandit de 26 px et la
  liste des canaux défile de nouveau. C'est voulu (décision de `canaux-surveilles.md`).
- **Le panneau de première connexion rouvert par « Configurer »** se comporte comme à la première
  fois : le fermer vaut acceptation de ce qui est affiché.

## Décisions

- 2026-09-30, **user**, sur la maquette : d'accord pour les icônes en couleur (« pour B je suis
  d'accord avec toi »). La désaturation portait le palier de profit ; le liseré le porte seul. À
  faire savoir à la session de `feat/profit-arbitrages`.
- 2026-09-30, **user** : d'accord pour la barre latérale et pour le bouton qui rouvre le panneau
  (« d'accord pour E et G »). Le bouton est sa demande : « rajouter une section ou un bouton pour
  relancer le setup ».
- 2026-09-30, **user** : l'écart des compteurs « doit être un souci de comptage », à analyser par
  la suite. Hors de cette spec.
- 2026-09-30, agent, propositions de la même maquette que le user n'a pas contestées : bouton
  Chuchoter éteint hors ligne, nom gris et sans préfixe, sous-ligne réduite, étiquette de source
  muette pour un croisé, bande « Croisés ».
- 2026-09-30, agent : « Croisés » seulement sur la bande de l'onglet Artisans, pour ne pas entrer
  en conflit avec `feat/liste-destinataires`. Conséquence assumée : jusqu'à la suite, Commande dit
  encore « Annuaire » pour la même source.
- 2026-09-30, agent : la session des canaux a fusionné dans `main` (`194f19f`) et rendu la section
  « Canaux surveillés » redessinable sans toucher à sa logique (`COC.Channels.BuildRows`).

## Critères d'acceptation

Témoin connu-bon pour tous les critères `[humain]` : la capture du 2026-09-30, planche de gauche de
la maquette. Observateur : le user, en jeu.

1. [humain] « Chuchoter » est rouge sur une ligne à pastille verte ou jaune, gris sur une ligne à
   pastille grise. Un clic sur le bouton gris ouvre quand même la saisie de chuchotement, et le
   bouton reste gris après le clic.
2. [humain] Les icônes de métier sont en couleur sur toutes les lignes.
3. [humain] Le nom du partenaire s'affiche en entier, sans préfixe ; son icône partenaire est
   allumée et il reste en tête de liste. Les noms hors ligne sont gris, les autres blancs.
4. [humain] Sous-ligne : le niveau seul pour un hors-ligne de niveau connu, « Hors ligne » seul
   quand le niveau est inconnu, « En ligne · sans addon · niv N » pour une pastille jaune.
5. [humain] Étiquette : rien sur un joueur croisé, « AMIS » sur un ami, le nom de la communauté sur
   un membre de cercle ; plus d'étiquette de source dès qu'une bande autre que « Tous » est choisie.
6. [humain] Pas de bande « Ajoutés » sans joueur ajouté ; en ajouter un la fait apparaître,
   sélectionnée. « En sourdine » est au-dessus de l'ajout de joueur, ouvre le panneau de sourdine,
   et « Tous » en revient.
7. [humain] Dans la configuration du banc (en ville, une communauté), la liste des canaux montre
   ses quatre groupes sans défiler.
8. [humain] « Configurer » rouvre « Où chercher les artisans ? » ; « Valider » le referme.
9. [humain] « Rafraîchir l'annuaire » est en bas à droite de la fenêtre sur l'onglet Artisans, et
   absent des autres onglets. Un clic écrit « annuaire : appel lancé… » dans le chat.
10. [humain] Le « i » : les deux bulles de la barre latérale décrivent ce qui s'y trouve.
11. [test] Sous-ligne, étiquette, couleur du nom et compte par source suivent les règles ci-dessus
    → `tests/test_artisans_text.lua` (dépôt d'outillage, même branche).
12. [porte] Toute chaîne nouvelle est traduite → `check_locale.ps1`.

## Reste à faire

- Après la fusion de `feat/liste-destinataires` : remplacer « Annuaire » par « Croisés » dans les
  menus de Commande et de Récolte (que cette branche déplace dans `CraftingOrderClassic_UI.lua`) et
  dans la colonne des métiers (`CraftingOrderClassic_ProfWindow_Orders.lua`).
- À la release qui l'embarque : Nouveautés, `CURSEFORGE.md`, puis les relectures
  (`api-gotcha-reviewer`, `locale-auditor`).
- Les compteurs (voir « Ce qu'on NE fait PAS »).

## Renvois

- `docs/specs/canaux-surveilles.md` : la section « Canaux surveillés » et le panneau de première
  connexion.
- `docs/specs/rentabilite-forever.md` : le palier de profit que le liseré doré affiche.
- Code : `CraftingOrderClassic_UI_Artisans.lua`, `_UI_Artisans_Text.lua` (les textes, purs),
  `_UI_Artisans_Groups.lua`, `_UI_Artisans_Icons.lua`, `_UI_Artisans_Channels.lua`,
  `_UI_Artisans_Layout.lua`, `Skin.MakeGoldButton` (`SetQuiet`).
- Skill `coc-native-ui` : le kit d'interface, les ancres, les pièges de largeur.
