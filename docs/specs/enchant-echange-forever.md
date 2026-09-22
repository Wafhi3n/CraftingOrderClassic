# Atelier d'enchantement sur l'échange (Forever)

> État : **brouillon** · Rédigée le 2026-09-21 · Arbitrages du user le 2026-09-21 (voir Décisions)
> Cible : WoW: Forever / Camelot (16001) uniquement · Addon : Crafting Order - Classic
>
> Les cinq mesures préalables sont faites (2026-09-21) ; `ASKE` a enfin été vu fonctionner de bout en
> bout. T1 à T4 sont faites et validées en jeu à deux comptes le 2026-09-22 : la liste native suit la
> pièce posée, la colonne passe en mode Échange, le clic sur la silhouette demande la pièce ET filtre,
> et le panneau flottant a disparu. Reste T5 à T7, en fin de document.

## Le problème

Un enchanteur enchante la pièce d'un autre joueur par la fenêtre d'échange. Pour ça, le client doit
poser sa pièce dans l'emplacement « ne sera pas échangé » (le 7), que beaucoup de joueurs ne
connaissent pas ; puis l'enchanteur cherche la bonne recette parmi des dizaines et lance l'enchant.

COC l'aide aujourd'hui (v1.34.1) avec un panneau accroché à droite de la fenêtre d'échange : une
silhouette du partenaire pour lui demander sa pièce, puis la liste classée des enchants de cet
emplacement. Sur Forever, ce panneau ne rend plus le service :

- **il est caché.** Le jeu place l'échange à gauche (non poussable) et pousse la fenêtre de métier
  juste à sa droite, exactement où le panneau est accroché ; elle est dessinée par-dessus. Or
  l'Enchantement doit être ouvert pour enchanter ;
- **il ne crafte plus** depuis la purge Era (le craft passait par un bouton sécurisé propre à l'Era) ;
- **la demande de pièce** n'avait jamais marché de bout en bout (test terrain du 2026-07-21 :
  chuchotement reçu, pas d'alerte). Elle marche sur Forever depuis le correctif de la v1.25.0 :
  vérifié à deux comptes le 2026-09-21 (M1).

## Ce qu'on veut

Du point de vue de l'**enchanteur** :

1. Un échange est ouvert et sa fenêtre d'Enchantement aussi : la colonne de COC, dans la fenêtre de
   métier, passe en **mode Échange**. Ses onglets (Commandes, Plan de route, Manquantes, Profit)
   disparaissent et elle n'affiche plus que ce qui sert à l'échange : la silhouette du partenaire
   (emplacements enchantables en couleur, les autres grisés, son modèle 3D), puis la pièce posée et
   l'indice. En échange, l'enchanteur n'a pas besoin du reste.
   À la fin de l'échange, les onglets reviennent, sur celui qui était actif avant.
2. Il clique un emplacement :
   - le partenaire reçoit la demande de poser **cette** pièce (chuchotement, plus une alerte s'il a
     COC) ;
   - la **liste native** de la fenêtre de métier est filtrée sur cet emplacement (le filtre
     « Filter → Slots » de Blizzard, coché comme si le joueur l'avait fait lui-même).
3. La pièce est posée : le filtre suit la pièce **réellement posée**, même si ce n'est pas celle
   demandée. Si les composants que le partenaire a posés dans l'échange correspondent à un enchant
   précis, la colonne l'indique (« ses composants correspondent à : Arme de feu ») ; un clic ouvre
   cette recette dans la fenêtre native.
4. Il enchante avec le **bouton de Blizzard**, qui sait déjà cibler l'objet de l'échange.
5. L'échange se ferme ou la pièce est retirée : la liste native retrouve ses filtres d'avant.
6. Un échange s'ouvre alors que son Enchantement est fermé : un petit bouton **« Enchantement »**
   apparaît sur la fenêtre d'échange et ouvre la fenêtre de métier.

Du point de vue du **partenaire** : avec COC, une alerte « X te demande de poser tes poignets » ; un
clic et la pièce se pose dans l'emplacement 7. Sans COC, il ne reçoit que le chuchotement.

## Ce qu'on NE fait PAS

- **Pas de pose automatique chez le partenaire** en v1 : le clic reste obligatoire (décision). Si on y
  revient un jour, ce sera à ces conditions minimales : opt-in du partenaire (liste de confiance, cf.
  `/co trust`), hors combat, emplacement 7 seulement, après mesure de la protection des fonctions de
  pose sur Forever (M5).
- **Pas de bouton de craft COC** : le bouton natif fait le travail (décision). On ne touche pas à
  `C_TradeSkillUI.CraftEnchant`.
- **Pas d'inspection** du partenaire (son vrai équipement, ses enchants déjà posés) : la silhouette
  reste celle d'aujourd'hui (décision). Piste pour une version suivante.
- **Jamais « Have Materials »** : les composants du partenaire n'arrivent dans les sacs qu'à la
  validation de l'échange ; ce filtre cacherait précisément le bon enchant.
- **Plus de panneau flottant** sur l'échange (décision) : il disparaît, remplacé par le mode Échange
  de la colonne et le bouton.
- **Rien écrit dans le système de fenêtres de Blizzard** pour réserver de la place : interdit, ça
  rend l'interface de Blizzard « tachée » par COC (cf. skill `wow-classic-addon-dev`, piège 8).
- La silhouette côté **client** (onglet Commande, `_UI_Post_Paperdoll`) est hors périmètre.
- **Pas de réponse du partenaire** en v1 (« je n'ai rien à cet emplacement », « refusé ») : ce serait
  un nouveau verbe, donc un changement de contrat. Candidat pour une version suivante.

## Cas particuliers

- **Partenaire sans COC** : seul le chuchotement part ; filtre et indice fonctionnent quand même côté
  enchanteur, dès que la pièce est posée à la main.
- **Pièce posée ≠ pièce demandée** : on suit la pièce posée.
- **Emplacement sans enchant** (tête, épaules : aucun enchant dans aucun catalogue) : grisé, non
  cliquable. Posé quand même : « aucun enchant pour cet emplacement ».
- **Filtre déjà posé par le joueur** avant l'échange : on ne restaure que ce que COC a changé, jamais
  on n'écrase son choix.
- **Enchantement fermé puis rouvert** pendant l'échange : Blizzard remet ses filtres par défaut à
  chaque ouverture ; on ré-applique celui de la pièce posée.
- **Combat** : la colonne greffée est un cadre protégé ; rien ne se repeint en combat, tout se rejoue
  à la sortie (règle existante de la colonne).
- **Pas enchanteur** : ni mode Échange ni bouton.
- **Demandes en rafale** : une seule alerte à la fois chez le partenaire, et le délai de 5 s par
  émetteur déjà en place.
- **Rien d'équipé à cet emplacement chez le partenaire** : son client refuse la demande et le trace,
  mais **l'enchanteur n'en sait rien** — il voit juste qu'il ne se passe rien (vécu à M1 : demande de
  cape à un personnage sans cape). Le lui dire exigerait une réponse du partenaire, donc un nouveau
  verbe réseau : hors v1 (voir « Ce qu'on NE fait PAS »).
- **La fenêtre s'ouvre sur un autre métier** (cascade de Blizzard, voir M2) : le mode Échange ne
  s'active que lorsque l'Enchantement est affiché ; le bouton reste visible tant que ce n'est pas le
  cas, pour permettre un second clic, qui bascule sans cascade (M2b, confirmé).
- **Le bouton « Enchantement » est un bouton sécurisé** (voir M2) : il est configuré hors combat. Si
  un échange s'ouvre en combat, le bouton garde sa configuration posée à froid ; s'il n'a jamais pu
  l'être, il reste masqué et un rappel « ouvre ta fenêtre d'Enchantement » le remplace.
- **Mains** : la main droite regroupe arme, arme à deux mains et bâton ; la main gauche porte bouclier
  et objet tenu (décision existante de la silhouette).
- **Une commande en cours avec ce partenaire** : la vue Commandes est cachée pendant l'échange, mais
  rien ne se perd ; le greffon Commandes sous la fenêtre d'échange (`_Companion_Trade`) montre déjà
  les commandes qui vous lient et permet de les marquer livrées.
- **Un autre métier ouvert** pendant l'échange (Couture, etc.) : pas de mode Échange, la colonne reste
  normale. Seul l'Enchantement le déclenche.
- **Enchantement ouvert en cours d'échange** : la colonne bascule en mode Échange à ce moment-là ;
  fermé en cours d'échange, elle disparaît avec la fenêtre, et retrouve ses onglets à la prochaine
  ouverture hors échange.

## Décisions

- 2026-09-21, user — l'outil vit dans la **colonne** de métier, plus un petit bouton sur l'échange
  quand l'Enchantement est fermé ; le panneau flottant disparaît.
- 2026-09-21, user — pendant l'échange, la colonne **cache tous ses onglets** et n'affiche que
  l'échange (pas de 5ᵉ onglet) : « en échange, il ne veut pas vérifier tout ça ». Retour à l'onglet
  d'avant à la fin : hypothèse de l'agent, **à confirmer par le user**.
- 2026-09-21, user — l'enchant est lancé par le **bouton natif** ; COC filtre et ouvre la recette.
- 2026-09-21, user — la pose chez le partenaire reste **au clic** en v1.
- 2026-09-21, user — la silhouette reste **comme aujourd'hui**, sans inspection.
- 2026-09-21, user (son idée) — **piloter le filtre natif** « Filter → Slots » plutôt qu'une liste
  maison.
- 2026-09-22, user (choix proposés par l'agent, approuvés) — une pièce **sans enchant** (anneau, cou)
  rend le filtre : liste complète, pas une liste vide. Une case que le joueur change **pendant**
  l'échange garde son choix au rendu ; une nouvelle pièce la réécrit.
- Invariants hérités, à ne pas défaire : pose dans l'emplacement **7 en dur** côté receveur, jamais lu
  du message (anti-vol) ; demande acceptée **seulement du partenaire d'échange ouvert** ; chaque refus
  de garde **tracé** (catégorie `aske`).

## Mesures préalables (avant tout plan)

- **M1** `[humain, 2 comptes]` `ASKE` de bout en bout sur la v1.34.1 : clic sur un emplacement →
  alerte chez le partenaire → pose. Témoin connu-bon : le chuchotement texte, qui arrive. Trace
  `aske` des deux côtés.
- **M2** `[sonde]` Un addon peut-il ouvrir la fenêtre d'Enchantement
  (`C_TradeSkillUI.OpenTradeSkill`) sans blocage ?
- **M3** `[sonde]` Correspondance pièce → case du filtre Slots, fenêtre d'Enchantement ouverte :
  `GetAllFilterableInventorySlotsCount`, `GetFilterableInventorySlotName(i)`, face aux `equipLoc`.
- **M4** `[humain]` Un filtre posé par l'API rafraîchit-il la liste native et coche-t-il la case du
  menu ? `taint.log` reste-t-il sans ligne COC ?
- **M5** `PickupInventoryItem` et `ClickTradeButton` sont-elles protégées sur Forever ? (Non
  protégées sur l'Era.) **Couvert par M1**, pas par la sonde : la mesurer seule obligerait à déplacer
  l'équipement du joueur. La pose au clic de M1 appelle ces deux fonctions chez le partenaire, et la
  trace `aske` nomme un blocage (« PickupInventoryItem n'a rien pris »). La sonde relève seulement
  qu'elles existent.

Outil : `/cocprobe enchant` (COCProbe, local) mesure M2, M3 et la moitié automatique de M4 — il pose
le filtre sur Poignets, compte la liste, le laisse 6 s pour qu'on regarde, puis rend les filtres et
vérifie case par case. Résultats dans `COCProbeDB.enchantTest` après `/reload`.

### Résultats (2026-09-21, client 1.60.1 build 69913, compte de test, locale enUS)

- **M1 — validé à deux comptes, 17:06.** Côté partenaire : `ASKE|ChestSlot` reçu en whisper →
  « invite AFFICHÉE » → clic → « pose effectuée : ChestSlot → emplacement 7 ». Une demande de cape
  juste avant a été refusée proprement (« rien d'équipé en BackSlot »). Première validation de bout
  en bout depuis la livraison en v1.24.0.
- **M5 — réglé par M1** : la pose a réussi, `PickupInventoryItem` et `ClickTradeButton` ne sont pas
  protégées sur Forever (appelées depuis le clic sur l'alerte).
- **M2 — le moyen est trouvé, l'atterrissage n'est pas maîtrisable fenêtre fermée.**
  `C_TradeSkillUI.OpenTradeSkill(333)` ouvre la fenêtre sans blocage, mais pas sur le métier demandé.
  La cause est chez Blizzard (Forever) : **à l'affichage de la fenêtre, chaque onglet latéral dont le
  métier n'est pas le métier courant relance son propre sort de métier**
  (`ProfessionsLargeRightTabMixin`, rappel « ProfessionsFrame.Show » → `CastProfessionSpell`). Les
  sorts partent en cascade et la fenêtre atterrit sur le dernier traité — vu : Cuisine → Herboristerie
  → Secourisme → Pêche → Enchantement. Donc, fenêtre FERMÉE, **aucun appelant ne choisit le métier
  d'arrivée** : ni `OpenTradeSkill`, ni un bouton sécurisé, ni `OpenProfessionUIToSkillLine` de
  Blizzard (qui fait `OpenTradeSkill` puis affiche la fenêtre). Le moyen d'ouvrir reste un **bouton
  sécurisé de type « sort »** (comme `/cast`, qui marche, confirmé par le user).
  **M2b — confirmé par le user** : fenêtre DÉJÀ ouverte sur un autre métier, `/cast Enchanting`
  bascule **directement** sur l'Enchantement, sans cascade (la fenêtre ne se réaffiche pas).
  D'où le comportement du bouton : un premier clic ouvre la fenêtre (où la cascade la pose) ; si ce
  n'est pas l'Enchantement, le bouton reste affiché et un second clic bascule proprement.
  Effet de bord hors spec : les ouvertures de métier de COC (`/co métier`, bouton minimap) subissent
  la même cascade.
- **M3 — tranché.** Le filtre Slots de l'Enchantement a **14 cases** : Neck, Chest, Feet, Wrist,
  Hands, Trinket, Back, Main Hand, Off Hand, Ranged, Weapon, 2H Weapon, Shield, Created Items. Les
  cases sont **propres au métier** (l'Herboristerie n'en a qu'une). Les cases d'armure portent le nom
  de l'`INVTYPE_*` du jeu (Wrist, Hands, Back, Feet, Chest) ; **les armes non** : « Weapon »,
  « 2H Weapon » et « Shield » sont des catégories d'enchant, pas des libellés d'emplacement. Les noms
  sont localisés. Conséquence pour le plan : la correspondance pièce → case ne peut pas reposer sur
  les noms seuls.
- **M4 — validé à l'œil, sauf la taint.** Le user a vu la liste native filtrée pendant la mesure. Filtre posé par l'API sur Wrist : la liste passe de **14 à 3** recettes, les
  trois enchants de bracelet appris, puis les filtres sont rendus **à l'identique**. Aucun
  `ADDON_ACTION_*`. Reste `taint.log` : pas réécrit pendant les mesures, donc non concluant.
- **Écart tranché** : interrupteurs « appris » et « non appris » tous deux à VRAI, et pourtant la
  liste native ne compte que 14 recettes (les apprises) contre 261 pour `GetAllRecipeIDs`. Sur ce
  client, la liste native n'affiche donc pas le non-appris, contrairement à une note du 2026-09-19.
  Sans incidence sur la sûreté : le registre exige `learned` dans tous les cas.
- **T1 — mesure, 17:51.** Chacune des 14 cases porte **exactement** le texte d'une clé de chaîne
  globale du jeu : `NECKSLOT`, `CHESTSLOT`, `FEETSLOT`, `WRISTSLOT`, `HANDSSLOT`, `TRINKET0SLOT`,
  `BACKSLOT`, `MAINHANDSLOT`, `SECONDARYHANDSLOT`, `RANGEDSLOT`, `ENCHSLOT_WEAPON`,
  `ENCHSLOT_2HWEAPON`, `SHIELDSLOT`, et `NONEQUIPSLOT` pour « Created Items ». Pour les armures,
  c'est le libellé que la silhouette affiche déjà (`_G[strupper(slot)]`). **Piège** : `INVTYPE_SHIELD`
  vaut « Off Hand » sur le client anglais. Relier les cases par les `INVTYPE_*` enverrait un bouclier
  dans la mauvaise case.
  Contrôle croisé (chaque case posée seule, recettes apprises, compétence 89) : Chest 4, Wrist 3,
  Back 1 (les enchants de ces emplacements) ; Ranged 2 (des **baguettes**, donc des objets produits) ;
  Created Items 4 (bâtonnet runique, huile…) ; les 9 autres vides. Filtres rendus à l'identique,
  aucun `ADDON_ACTION_*`. **Non vu** : ce que contiennent « Weapon », « 2H Weapon » et « Shield »,
  faute d'enchant d'arme ou de bouclier appris. À relever dès qu'un tel enchant est appris.
  Le fichier `COCProbeDB` a été vidé depuis (perte déjà vécue sur cette sonde) : ce paragraphe est
  la seule trace du relevé.
- **Hors sujet mais vécu pendant M2** : Auctionator, installé sur le client de test, casse la
  fenêtre de métier de Forever (`SelectRecipe`, pile 100 % Blizzard). Désactivé, plus d'erreur.
  Mesurer sans lui.

## Critères d'acceptation

1. `[humain, 2 comptes]` Échange et Enchantement ouverts : les onglets de la colonne disparaissent et
   la silhouette s'affiche à leur place ; plus aucun panneau à droite de l'échange. Témoin
   connu-bon : la v1.34.1, où le panneau est caché derrière la fenêtre de métier. À la fermeture de
   l'échange, les onglets reviennent sur celui d'avant.
2. `[humain, 2 comptes]` Clic sur Poignets : chez le partenaire, l'alerte nomme les poignets ; un clic
   dessus pose ses brassards dans l'emplacement 7. Témoin : le chuchotement texte, qui arrive aussi.
3. `[humain]` Après ce clic, la liste native ne montre que des enchants de bracelet, et
   Filter → Slots n'a que la case Poignets de cochée.
4. `[humain]` Le partenaire pose ses gants à la place : la liste passe aux enchants de gants.
5. `[humain]` Le partenaire pose les composants d'un enchant précis : l'indice le nomme ; un clic
   sélectionne cette recette dans la fenêtre native.
6. `[humain]` L'enchant lancé au bouton natif s'applique à la pièce du partenaire.
7. `[humain]` Fin de l'échange : la liste retrouve tous ses filtres d'avant, y compris un filtre posé
   par le joueur lui-même avant l'échange.
8. `[humain]` Enchantement fermé à l'ouverture de l'échange : le bouton « Enchantement » est visible
   et ouvre la fenêtre (ou affiche le rappel si M2 dit non).
9. `[humain]` Tout le parcours, entrée en combat comprise, sans erreur BugSack ni ligne COC dans
   `taint.log`.
10. `[test]` Correspondance pièce → emplacement de la silhouette → case du filtre, tests headless.
11. `[test]` Invariants `ASKE` : emplacement 7 en dur, émetteur = partenaire, délai après les gardes.
12. `[porte]` Lua 5.1, localisation (trois overlays), anti-monolithe.
13. `[agent]` `api-gotcha-reviewer` : aucune écriture dans le système de fenêtres, aucun cadre
    protégé manipulé en combat.

## Contrat

Fil `ASKE` **inchangé** : `ASKE|<slotToken>` en whisper addon, `slotToken` pris dans les jetons de
`COC.UI.DOLL` (liste blanche côté receveur). Aucun nouveau verbe en v1, donc aucun changement de
protocole ni de révision de transport.

## Renvois

- Skills : `wow-classic-addon-dev` (pièges Forever : système de fenêtres, cadres protégés, taint,
  événements restreints), `coc-native-ui` (chrome), `human-verification` (fiches de test).
- Mémoires : `coc-enchant-trade-ask`, `coc-enchant-paperdoll-feature`, `coc-enchant-trade-ranking`,
  `coc-enchant-forever-chantier`.
- Code actuel : `_Enchant_Trade.lua` (panneau et classement), `_Enchant_Trade_Ask.lua` (silhouette et
  `ASKE`), `_UI_Post_Paperdoll.lua` (`COC.UI.DOLL`), `_Enchant.lua` (emplacement d'un enchant),
  `_ProfWindow_DockViews.lua` (onglets de la colonne), `_Enchant_Filter.lua` (cases du filtre natif,
  T1), `_Enchant_Filter_Pilot.lua` (pose et rendu du filtre, T2).
- Spec voisine : `rentabilite-forever.md` (même rangée d'onglets).

## Plan (provisoire, 2026-09-21)

> Le COMMENT, pas le QUOI : ce plan meurt quand c'est fait. Chaque tâche tient dans une session et
> porte son critère.

**Préalable — le chantier Profit.** Il est déployé mais non commité, et touche la même rangée
d'onglets de la colonne (`_ProfWindow_DockViews.lua`) que le mode Échange. Il faut le trancher
(committer après validation, ou le mettre de côté) **avant T3**, sinon deux chantiers non commités
se mélangent dans les mêmes fichiers.

1. **T1 — Correspondance pièce → case du filtre.** M3 a montré que les noms ne suffisent pas (armes)
   et qu'ils sont localisés. Piste : à l'ouverture de l'Enchantement, chercher pour chaque nom de
   case la **clé de chaîne globale** du jeu qui porte ce texte (clé indépendante de la langue), puis
   relier clé → emplacement de la silhouette. Mini-mesure par la sonde d'abord, puis logique pure.
   Critère : critère 10 (tests headless) ; les 14 cases trouvent leur emplacement ou « aucun ».
   **Fait le 2026-09-22, non branché** : `_Enchant_Filter.lua` (`COC.EnchantFilter`) ;
   `tests/test_enchant_filter.lua` (25 vérifications, relevé T1 en entrée, plus un client français
   simulé). Une pièce passe par ses **mots d'enchant** (`Enchant:WordsForEquipLoc`), jamais par son
   `INVTYPE` : une arme à deux mains coche « Weapon » et « 2H Weapon », un bouclier « Shield ». Seuls
   les mots servis par le catalogue comptent : les cases d'objets produits ne sont jamais cochées. Deux
   cases au même nom restent inconnues, pour ne jamais cocher la mauvaise.
2. **T2 — Pilote du filtre natif.** Poser un filtre exclusif, mémoriser l'état d'avant case par
   case, le rendre à l'identique, ré-appliquer après réouverture de l'Enchantement, ne jamais toucher
   « Have Materials ». Logique testable hors jeu (le banc de la sonde modélise déjà le filtre).
   Critères 3, 4, 7.
   **Validée en jeu à deux comptes le 2026-09-22** (10:43-10:45, trace `enchfilter` du compte
   enchanteur) : Chest posé → rendu à la pièce retirée → Feet (bottes) → Wrist (brassards) → Wrist
   reposé après réouverture de la fenêtre → rendu à la fin de l'échange ; chaque pose relue identique
   au filtre voulu, et le user a vu la liste suivre puis retrouver son filtre d'avant, sans erreur.
   Critères 4 et 7 vus ; le 3 vu par la pièce posée, le clic sur la silhouette viendra avec T4.
   Détail de la tâche :
   `_Enchant_Filter_Pilot.lua` (pilote, suiveur, branchement sur les événements d'échange et de
   métier), +20 vérifications dans `tests/test_enchant_filter.lua`. Branchée sur la pièce posée
   seulement : le clic sur la silhouette viendra avec T4. Choix de l'agent, **confirmés par le user
   le 2026-09-22** (voir Décisions) : une pièce sans enchant (anneau, cou) rend le filtre au lieu de vider la liste ; une case
   que le joueur change pendant l'échange garde son choix au rendu, mais une nouvelle pièce la
   réécrit. Limite connue : un `/reload` pendant l'échange fait oublier à COC le filtre d'avant, et la
   liste reste filtrée jusqu'à ce que le joueur la remette à zéro (menu Filter).
   Sens de l'API lu chez Blizzard (`InitSlotsFilter`, `ApplyfilterSet`) : `IsInventorySlotFiltered`
   vrai = case décochée ; le 2ᵉ argument de `SetInventorySlotFilter` = cochée. Que Blizzard remette ses
   défauts à chaque ouverture n'est **pas établi** par la source : le suiveur compare l'état trouvé à
   celui qu'il a posé, et ne réécrit que ce qui diffère.
3. **T3 — Mode Échange de la colonne** (après le préalable). Masquer les onglets, afficher la
   silhouette (réutilise `COC.UI.DOLL`), la pièce posée et la place de l'indice ; rendre l'onglet
   d'avant à la fin. Critère 1.
   **Validée en jeu le 2026-09-22** (capture du user : onglets remplacés par « Trade with Gnomi
   Short », silhouette et modèle 3D du partenaire, « Item to enchant [Frayed Bracers] », et la liste
   native réduite aux trois enchants de bracelet — T2 et T3 ensemble). Reste visible derrière la
   fenêtre de métier : l'ancien panneau flottant, que T4 supprime. `_ProfWindow_Trade.lua`. Le mode
   est une vue de plus de la colonne (`dockView = "trade"`) : la bascule existante masque les autres
   vues et tait les onglets. Une session par échange retient l'onglet d'avant ; un autre métier ou
   la fenêtre refermée ne font que sortir de la vue, seule la fin de l'échange clôt la session.
   Échange fini pendant que la fenêtre est fermée : retour sur Commandes, pas sur l'onglet d'avant
   (rien à remplir sans métier ouvert). La silhouette est sortie de `_Enchant_Trade_Ask`
   (`Ask:BuildSilhouette`), donc son clic demande déjà la pièce (chuchotement + `ASKE`) : de T4, il
   reste le filtre au clic et la suppression du panneau flottant. `tests/test_trade_view.lua`
   (17 vérifications) verrouille l'entrée, la sortie, l'aller-retour de métier, la fenêtre refermée
   et le combat.
4. **T4 — Demande de pièce depuis la colonne**, puis suppression du panneau flottant
   (`_Enchant_Trade`) et de l'état vide de `_Enchant_Trade_Ask` ; le chemin réseau et les gardes de
   réception ne bougent pas. Critère 2.
   **Validée en jeu le 2026-09-22** (trace : clic → cases 4, plastron posé → case 2, pièce retirée →
   case 4, main droite → cases 11+12, fin d'échange → filtre rendu). Le clic passe par le MÊME
   suiveur que la pièce posée (`Filter.Request`) : deux écrivains sur le filtre en feraient deux qui
   se battent, et l'état d'avant l'échange serait perdu. Une pièce posée l'emporte toujours sur la
   demande ; la fin de l'échange l'oublie. De `_Enchant_Trade` il ne reste que ce que la liste native
   ne sait pas faire — lire l'offre du partenaire et classer (`ET.Rank`), pour l'indice de T5.
   **Deux leçons du terrain, payées ici** :
   · une vue pilotée par ÉVÉNEMENTS doit aussi se redécider à chaque rafraîchissement de son hôte —
     la silhouette n'apparaissait qu'après un aller-retour sur un autre onglet, faute d'événement
     retombé APRÈS que la colonne fut prête (corrigé dans `_SyncDockViewBtns`) ;
   · le garde-fou anti-rafale de 3 s d'`Ask:Request` avalait des demandes EN SILENCE depuis que le
     clic sert aussi à filtrer (on clique bien plus souvent). Il reste, mais il se nomme dans la
     trace, comme les refus de réception.
   Le refus « rien d'équipé en WristSlot » a été vu tracé des DEUX côtés (envoi à 11:25:05, refus à
   11:25:06) : le mécanisme est sain, c'est le trou connu de la v1 — l'enchanteur ne peut pas savoir
   que le partenaire n'a rien à cet emplacement, faute de réponse du partenaire.
5. **T5 — Indice « ses composants correspondent à »** (réutilise `offerRank`) et clic → la recette
   s'ouvre dans la fenêtre native (`C_TradeSkillUI.OpenRecipe`, vivante, jamais appelée par nous :
   à éprouver). Critère 5.
6. **T6 — Bouton « Enchantement » sur l'échange** : bouton sécurisé de type « sort », configuré hors
   combat, visible tant que l'Enchantement n'est pas affiché (second clic = bascule, M2b).
   Indépendante des autres : peut passer tôt. Critère 8.
7. **T7 — Clôture** : portes, `api-gotcha-reviewer`, parcours complet à deux comptes avec
   `taint.log` actif (critères 6 et 9), agent `spec-updater` sur le diff, release.
