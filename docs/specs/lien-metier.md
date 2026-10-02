# Un lien de métier posté dans le chat ajoute son auteur à l'annuaire

> État : **validée** le 2026-10-02 · Idée du user (« si un joueur link son métier, ça l'ajoute
> aussi ») · D1 à D7 proposées par l'agent, acceptées par le user ; D8 et D9 décidées par le user le
> 2026-10-02 (sa réponse, mise en forme par l'agent) ; D10 à D12 proposées par l'agent le même jour
> · Cible : WoW: Forever / Camelot (16001) uniquement · Addon : Crafting Order - Classic
>
> **Phase 1 implémentée et vue en jeu** le 2026-10-02 (registre, relevés 11:12 à 11:24, build
> `main-dev@2bf827b`) : critères 1, 11, 12, 18 tenus, plus la garde du métier lié (D6). Reste non vu :
> Trade (Services), l'infobulle de l'icône, la purge (tests seulement).
> **Phase 2** (garder ses recettes quand on clique) **débloquée** par le relevé D6 de 11:21 ; codée
> sur `feat/lien-metier`, pas encore vue en jeu.

## Le problème

Un enchanteur à Orgrimmar ouvre son métier, clique la chaîne et poste `[Enchantement]` dans
Commerce. C'est la façon la plus directe de dire « je fais ça » : le lien vient du jeu, il ne peut
pas être mal orthographié, et l'artisan s'annonce lui-même.

COC n'en fait rien aujourd'hui :

- la lecture des lignes « LFW » (`CraftingOrderClassic_LFWChat.lua`) **jette toute ligne qui
  contient `|`**, pour écarter les messages du protocole (`LFW|on|…`). Un lien de jeu en contient
  forcément. « LFW [Enchantement] », avec un vrai lien, est donc ignoré ;
- le repérage des artisans alentour (`Directory_LootScan.lua`, case « nearby ») ne lit que le
  message « X crée Y » : il faut que l'artisan fabrique quelque chose sous nos yeux.

Résultat : un joueur sans l'addon qui fait sa pub par un lien n'entre jamais dans l'annuaire, alors
qu'un joueur qui tape « LFW Enchanting » à la main y entre.

Et à l'inverse, l'annuaire garde **tous** les artisans sans l'addon qu'il a croisés pendant 7 jours
(jusqu'à 500 fiches). En capitale, un métier courant y accumule des dizaines de débutants qui ne
servent à personne : « inutile de garder 50 travailleurs du cuir niveau 20 » (le user).

## Ce qu'on veut

### Phase 1 — le lien suffit

Quand un joueur poste **son propre** lien de métier là où je lis le chat, il apparaît dans mon
onglet Artisans avec ce métier, comme un artisan connu sans l'addon (étiquette « VU »). La
sous-ligne dit que le métier vient d'un lien, pour qu'on ne le confonde pas avec un artisan
« vu crafter ».

Où on lit les liens :

- les canaux du jeu cochés dans « Canaux surveillés », et « dire et crier » s'il est coché (les
  mêmes sources que les lignes LFW) ;
- **la guilde** (et le canal des officiers), si la case « guilde » est cochée (D8) ;
- **les chuchotements** qu'on me fait (D8).

Ce qu'on en tire :

- Le niveau reste **inconnu** : le lien n'en porte pas (D4).
- S'il a l'addon, ses vraies données remplacent cette estimation quand elles arrivent par les
  voies habituelles (salle de découverte, annonces). Le lien seul ne lui envoie **rien** (D7).
- Si la ligne est une ligne « LFW » et que le métier est donné par un lien, il passe aussi
  **[Dispo]**, exactement comme s'il avait tapé « LFW Enchanting ».
- Le métier est reconnu quelle que soit la langue du joueur qui l'a posté (`[Enchanting]`,
  `[Enchantement]`, `[Verzauberkunst]`…).

### Phase 1 — l'annuaire ne garde que les artisans utiles

Pour chaque métier, l'annuaire garde au plus **10** artisans connus seulement sans l'addon (D9).
Au-delà, il oublie ce métier chez ceux qui en savent le moins (le niveau connu le plus bas, puis le
signe de vie le plus ancien). Une fiche qui n'a plus rien à dire disparaît. Mes relations, mes
partenaires, les porteurs de l'addon et les artisans qui sont [Dispo] en ce moment ne sont jamais
touchés.

### Phase 2 — quand je clique son lien

Quand **je** clique le lien de métier d'un autre joueur, le jeu m'envoie sa liste de recettes et
son niveau. COC les range **dans sa fiche à lui**, jamais dans la mienne : l'infobulle du métier,
dans l'onglet Artisans, dit son niveau et combien de recettes il connaît. Le niveau sert aussi à
la purge (D9), qui garde alors les mieux placés au lieu des plus récents. Le user le veut
(2026-10-02 : « si on clique sur le lien d'une personne, on enregistre »).

C'est l'inverse du bug du 2026-09-27, quand COC s'appropriait les recettes du lien cliqué. La
garde qui a corrigé ce bug (`IsOwnProfessionOpen` dans CraftLink) tient en jeu (relevé du
2026-10-02 11:21) : la phase 2 se branche à côté d'elle, sur la même définition de « vue d'un
autre ».

Où montrer « il sait faire **cette** recette, sans l'addon » : voir Questions ouvertes. Pas encore
construit (D10).

## Ce qu'on NE fait PAS

- **Ouvrir un lien tout seul pour lire les recettes.** Ce n'est plus passif : ça ouvre une
  fenêtre, ça interroge le serveur, et ça refermerait le métier que le joueur a ouvert. Les
  recettes ne viennent que d'un clic du joueur (phase 2).
- **Interpréter le sort de rang** contenu dans le lien (Apprenti, Compagnon…) : voir D4 et la
  question D4bis. On le garde brut dans la fiche, sans rien en déduire.
- **Attribuer un lien relayé.** « Demande à X [Enchantement] » : le lien appartient à X, pas à
  celui qui parle. On l'ignore (D3).
- **Étendre les lignes LFW tapées à la guilde et aux chuchotements.** Seuls les liens y sont lus ;
  « LFW Enchanting » tapé en guilde garde son comportement d'aujourd'hui (pas lu).
- **Lire les liens postés dans une communauté** : leur texte arrive opaque (`|Kw1|k`, cf.
  constats C_Club). Rien à lire. Idem pour les chuchotements Battle.net (aucun GUID de personnage).
- **Partager ces artisans sur le réseau.** Ils restent dans MON annuaire, comme les artisans vus
  crafter. Le relais de fiches ne sert jamais une liste lue sur un lien (phase 2 comprise).
- **Les métiers secondaires** : Cuisine, Secourisme, Pêche (D2).
- **Un bouton « voir son métier »** qui rejouerait plus tard un lien gardé. Le rejeu n'est pas
  mesuré : celui du 2026-09-27 (joueur déconnecté) a pu sortir du cache du client. À rouvrir
  après une mesure.
- **Changer la purge existante** (`Dir:PruneRoster` : un joueur croisé non revu depuis 7 jours sort
  de l'annuaire, 500 fiches au plus). La purge par métier s'y ajoute, elle ne la remplace pas.

## Cas particuliers

- **Mon propre lien** : je ne m'ajoute pas à mon annuaire. « LFW [mon Enchantement] » garde la
  règle actuelle d'une ligne LFW tapée par moi : raccourci de `/co lfw`, sans annonce sur Commerce.
  L'écho de ma ligne `LFW … #CO` postée par l'addon reste ignoré.
- **Plusieurs liens dans une ligne** : chaque lien qui appartient à l'auteur compte. Une ligne LFW
  ne donne qu'**un** statut [Dispo] (LFW = un seul métier) : le premier métier reconnu ; les autres
  entrent seulement à l'annuaire.
- **Le même joueur reposte son lien toutes les minutes** (Commerce) : sa fiche est rafraîchie,
  rien ne se duplique, et on ne refait pas le travail à chaque ligne. Un 2e lien d'un AUTRE métier
  posté juste après n'est pas avalé par cette retenue.
- **Il a déjà l'addon et ses vraies données sont là** : elles ne bougent pas. Le lien ne fait
  qu'actualiser « vu le … ».
- **Il est déjà connu « vu crafter »** avec un plancher de niveau : le lien ne baisse jamais ce
  plancher.
- **Lien illisible, ou métier que CraftLink ne connaît pas** : ignoré, sans erreur.
- **Combat de boss** : le texte, l'émetteur et son GUID arrivent en valeurs secrètes. Tout est
  ignoré, sans erreur, et le test du secret vient avant toute recherche dans le texte.
- **GUID de l'émetteur absent** de l'événement : on ne peut pas vérifier à qui est le lien, donc on
  l'ignore.
- **Auteur en sourdine** (`/co mute`) : ignoré.
- **Canal décoché** dans « Canaux surveillés », ou `/co lfwchat off` : ignoré. Couper `/co lfwchat`
  coupe donc aussi les liens (chuchotements compris) : son message de retour et l'aide le disent.
- **Commerce relie toutes les capitales** (constat C15) : un lien posté à Hurlevent arrive à
  Forgefer. Ce n'est pas un repérage « alentour » comme le message « X crée Y ».
- **Lien fabriqué à la main** : avec D3, on ne peut s'attribuer un métier qu'à soi-même, ce qui ne
  vaut pas plus que de taper « LFW Enchanting ». Le serveur accepte-t-il seulement un lien
  fabriqué dans le chat ? Pas mesuré, et sans conséquence grâce à D3.
- **Purge, artisan qui vient d'arriver** : s'il entre au-delà de la limite et qu'il est le moins
  renseigné, il est oublié aussitôt. C'est voulu : un 11e travailleur du cuir de niveau inconnu
  n'apprend rien. Sauf s'il est [Dispo] : celui-là reste tant que son statut dure.
- **Purge, artisan à plusieurs métiers** : on oublie seulement le métier en trop ; la fiche reste
  pour ses autres métiers.

## Décisions

- **D1 — L'interrupteur est celui des lignes LFW.** La lecture suit `/co lfwchat` (actif par
  défaut) et les cases « Canaux surveillés », pas la case « nearby » (repérage alentour, opt-in,
  en ville). Raison : même coût qu'une ligne LFW (une recherche de texte par ligne lue), mêmes
  canaux, alors que la case « nearby » existe pour un événement qui coûtait cher.
- **D2 — Métiers principaux seulement**, comme le repérage alentour (`COC.SECONDARY_PROF`).
- **D3 — Le lien compte seulement si son GUID est celui de l'émetteur** (12e argument de
  l'événement de chat). Sinon, il est ignoré. Raison : le jeu authentifie l'émetteur, pas ce dont
  il parle.
- **D4 — Niveau inconnu.** Le métier entre « connu, niveau inconnu », comme une ligne LFW lue dans
  le chat. Pas de tranche tirée du sort de rang tant qu'elle n'est pas mesurée (voir D4bis).
- **D5 — LFW + lien = [Dispo].** Combler le trou de `_Parse` fait partie de la fonctionnalité, pas
  d'un chantier à part.
- **D6 — La phase 2 attend le banc.** Pas une ligne de code de phase 2 avant un relevé, au
  registre, de la garde du métier lié (B lie, A clique : pas de colonne COC, `knownRecipes` d'A
  inchangé). Ce relevé peut se faire dans la même séance que les critères 11 et 12.
- **D7 — Lire un lien n'envoie rien.** Confirmée par le user le 2026-10-02 (« on reste discret,
  pas de whisp aux auteurs »). Le repérage « vu crafter » salue l'artisan (`DiscoverPlayer` : mon
  profil HI+SK en chuchotement d'addon) ; une ligne LFW lue dans le chat, non ; le lien suit la
  ligne LFW. Raison : Commerce relie toutes les capitales, saluer chaque auteur enverrait mon profil
  à des inconnus partout.
- **D8 — Les liens se lisent aussi en guilde et en chuchotement.** Décidé par le user le
  2026-10-02 (« oui, on lit les liens en guilde, ceux qui n'ont pas l'addon »). La guilde et le
  canal des officiers suivent la case « guilde » de « Canaux surveillés » ; les chuchotements n'ont
  pas de case et suivent `/co lfwchat` seul. ⚠️ Les chuchotements viennent du « oui » du user à la
  question « chuchotements et guilde ? », sa phrase ne nommant que la guilde : **à rayer s'il ne
  les voulait pas.**
- **D9 — Au plus 10 artisans sans l'addon par métier.** Décidé par le user le 2026-10-02 (« on
  pourrait purger les inutiles, inutile de garder 50 travailleurs du cuir niveau 20 ») ; la règle
  et le nombre **10** sont une proposition de l'agent, le nombre est à confirmer.
  - *Candidats* : les fiches qui ne sont ni une relation (guilde, ami, ajout à la main, cercle —
    la liste que garde déjà `PruneRoster`), ni un partenaire, ni une fiche relayée, ni porteuses de
    vraies données réseau (`skill`, `recipes`), ni [Dispo] en ce moment.
  - *Classement* : le niveau connu le plus haut d'abord (`craftSeen[prof]`), puis le signe de vie le
    plus récent pour ce métier.
  - *Au-delà de 10* : la fiche oublie ce métier (`craftSeen`, `linkSeen`, `linkSpell`, `cdSeen` de
    ce métier). Si elle n'a plus aucun métier, elle disparaît.
  - *Quand* : à chaque nouvelle entrée d'un métier (lien, ou « vu crafter » du repérage alentour),
    pour ce métier ; et une fois à la connexion, pour tous.
  - *Limite connue* : un lien ne donne pas de niveau (D4). Entre artisans connus seulement par un
    lien, la purge garde donc les plus récents, pas les meilleurs ; elle ne sait distinguer « niveau
    20 » de « niveau 280 » que si un niveau est connu (« vu crafter », clic sur son lien (D11), ou
    D4bis).
- **D10 — Les recettes d'un lien ne servent jamais à commander.** Proposée par l'agent le
  2026-10-02. Elles vivent à part (`linkRecipes`) et `RecipeTester`, `Handoff:CanCraft`, l'alerte
  de butin et le ciblage d'une commande n'en voient rien. Raison : dans COC, le seul endroit qui
  liste les artisans d'une recette est le ciblage d'une commande, réservé aux porteurs de l'addon
  à dessein ; un artisan sans l'addon ne peut pas recevoir une commande.
- **D11 — Le niveau lu au clic suit la DERNIÈRE lecture.** Proposée par l'agent le 2026-10-02,
  corrigée le même jour. Il vit dans `linkRecipes[prof].lvl`, remplacé à chaque lecture, et la
  purge (D9) comme l'infobulle le lisent là ; il ne monte JAMAIS dans le plancher `craftSeen`, qui
  ne redescend pas : une lecture périmée (mon propre niveau servi le temps que la liste de l'autre
  arrive) s'y collerait pour de bon. ⚠️ Que `GetChildProfessionInfo()` rende dans une vue liée le
  niveau du PROPRIÉTAIRE et pas le mien n'est pas encore mesuré (la barre 1/75 du relevé de 11:21
  est cohérente, sans trancher) : sonde au début de la prochaine séance.
- **D12 — Une liste n'est retenue qu'une fois arrivée.** Proposée par l'agent le 2026-10-02.
  Quand on passe d'une vue liée à une autre, le client garde un moment l'ancienne liste sous le
  nouveau nom (vu le 2026-09-27 avec un lien fabriqué : nom de B, liste de l'Enchantement). On ne
  lit donc qu'après une mise à jour de la liste (`TRADE_SKILL_LIST_UPDATE`) survenue APRÈS le
  changement de propriétaire ou de métier, au calme (1 s sans nouvel événement) ; on écarte une
  liste dont moins de la moitié des recettes appartient au métier lu ; et chaque lecture REMPLACE
  la précédente (jamais d'union, qui garderait une mauvaise lecture pour toujours).

## Questions ouvertes

- **Où montrer « sait faire cette recette, sans l'addon » ?** (D10) Par exemple une ligne sous la
  liste d'artisans de l'onglet Commande (« sans l'addon, la connaissent : X, Y — chuchoter »), ou
  dans l'infobulle d'une recette. **Au user de choisir** ; rien n'est construit en attendant.

- **D4bis — lire la tranche du sort de rang ?** Le lien porte le sort de rang du métier. Sur
  Camelot, deux valeurs mesurées correspondent aux identifiants Vanilla : 7412 = Enchantement
  Compagnon (vu à 102/150), 2550 = Cuisine Apprenti. Une table Vanilla (Apprenti / Compagnon /
  Expert / Artisan, planchers 0 / 50 / 125 / 200) permettrait à la purge d'oublier d'abord les
  Apprentis, ce qui est exactement le « niveau 20 » du user. **Revient sur D4 : au user de
  trancher.** En attendant, le sort est gardé brut (`linkSpell`).
- **D9 : 10 par métier, le bon nombre ?** Proposé par l'agent.
- ~~Phase 2, à mesurer avant de coder~~ — **mesuré le 2026-10-02 11:21** : `IsTradeSkillLinked()`
  rend le nom COMPLET (le titre « Blacksmithing [Gnomi Short] » en vient,
  Blizzard_ProfessionsFrame.lua:255) ; le niveau du propriétaire s'affiche dans la vue liée (1/75).
  Reste à mesurer, voir D11 : que l'API rende bien SON niveau.

## Critères d'acceptation

### Phase 1

1. **[humain]** Palier 0 : chez A, une ligne de B qui porte son lien de métier arrive par
   `CHAT_MSG_CHANNEL` sur Commerce (Services) avec le lien intact (`|Htrade:…`), et le GUID du lien
   est celui de l'émetteur. Observateur : le user, compte A, avec la sonde du plan. Si Commerce
   (Services) refuse le lien, refaire la mesure sur Commerce.
2. **[test]** Une ligne qui porte le lien de métier de son auteur rend ce métier, quelle que soit la
   langue du libellé (au moins anglais, français, allemand).
3. **[test]** Un lien dont le GUID n'est pas celui de l'émetteur ne rend rien, et l'émetteur
   n'entre pas dans l'annuaire.
4. **[test]** Un lien de Cuisine, de Secourisme ou de Pêche ne rend rien ; un lien illisible ou d'un
   métier inconnu non plus, sans erreur.
5. **[test]** Un texte, un émetteur ou un GUID secret : rien, sans erreur, et aucune opération
   sur le texte avant le test.
6. **[test]** Un message du protocole (`LFW|on|Enchanting`) reste ignoré ; une ligne « LFW
   Enchanting » sans lien se comporte exactement comme avant.
7. **[test]** « LFW » suivi du lien de son Enchantement → statut [Dispo] Enchantement, même durée
   qu'une ligne LFW tapée.
8. **[test]** Un joueur dont on a les vraies données réseau garde ses données ; un plancher « vu
   crafter » ne baisse pas.
9. **[test]** Canal décoché, `/co lfwchat off`, ou auteur en sourdine → rien. Et lire un lien,
   retenu ou non, n'envoie aucun message (D7).
10. **[porte]** Toute chaîne nouvelle est localisée (`check_locale.ps1`) ; Lua 5.1 valide, tailles
    de fichier et de fonction tenues (`check_lua.ps1`, `check_size.ps1`).
11. **[humain]** Au banc, B **sans COC activé** lie son Enchantement dans Commerce (Services). Chez
    A, B apparaît dans l'onglet Artisans, étiquette « VU », et la sous-ligne dit qu'il a lié son
    métier en nommant l'Enchantement. Témoin : juste avant, B est absent de la liste d'A (A l'a
    oublié), et la sonde du palier 0 affiche la ligne reçue. Observateur : le user, compte A.
12. **[humain]** B tape « LFW » puis lie son Enchantement dans la même ligne : chez A, B passe
    [Dispo]. Même témoin que le 11.
13. **[agent]** `api-gotcha-reviewer` sur le diff : aucune valeur du chat utilisée avant le test
    du secret, aucun abonnement à un événement restreint.
16. **[test]** Un lien en guilde est lu si la case « guilde » est cochée, pas si elle est décochée,
    et « dire et crier » décoché ne l'empêche pas ; un lien en chuchotement est lu, sauf
    `/co lfwchat off` ; « LFW Enchanting » tapé en guilde ou en chuchotement n'est pas lu (D8).
17. **[test]** Purge (D9) : sur 12 travailleurs du cuir connus seulement par un lien, les 10 plus
    récents restent ; un « vu crafter » à plancher 150 passe devant un lien plus récent ; une
    relation, un partenaire, un porteur de l'addon ou un [Dispo] n'est jamais oublié ; une fiche à
    deux métiers garde l'autre ; le repérage alentour (« vu crafter ») est plafonné de la même façon.
18. **[humain]** Au banc, B lie son métier **en guilde** (case « guilde » cochée chez A) : même
    résultat que le 11. Même témoin.

### Phase 2 (après D6)

14. **[humain]** A clique le lien d'Enchantement de B : la fiche de B chez A annonce ses recettes ;
    le nombre de recettes d'Enchantement **d'A** (`knownRecipes`) est le même avant et après ;
    `/co trace`, armé avant le clic, ne montre aucun envoi provoqué par lui. Témoin : le relevé
    de la garde du métier lié (D6).
15. **[test]** Des recettes lues dans une vue liée ne vont jamais dans mes recettes connues ni dans
    les recettes réseau d'une fiche (`r.recipes`), et `RecipeTester` n'en voit rien (D10).
19. **[test]** Vue liée de B : sa fiche reçoit ses recettes apprises, son niveau et son métier ;
    rien si la vue est la mienne, celle de la guilde ou d'un PNJ, si le métier est secondaire ou
    illisible, si le nom est secret, ou si c'est mon propre lien. Changement de propriétaire avec
    l'ancienne liste encore servie : rien n'est attribué tant que la liste n'a pas été mise à jour
    (D12) ; une liste d'un autre métier est écartée ; une 2e lecture remplace la 1re.
20. **[humain]** Au banc, A clique le lien de B : l'infobulle du métier de B, dans l'onglet
    Artisans d'A, dit son niveau et son nombre de recettes (« 1/75 · lien de métier, 5 recettes »
    pour la Forge de Gnomi vue le 2026-10-02). Avant : sonde `/dump C_TradeSkillUI.GetChildProfessionInfo()`
    dans la vue liée, `skillLevel` = celui du titre de la fenêtre (D11). Témoin : la barre de la
    fenêtre native.

## Contrat

Rien ne change sur le fil : rien n'est envoyé. Le contrat est la fiche persistée
(`db.roster[<nom réseau>]`), en ajouts seulement, qu'un client plus ancien ignore :

| Champ | Sens | Existe déjà ? |
|---|---|---|
| `craftSeen[prof]` | plancher de niveau ; `0` = connu sans l'addon, niveau inconnu. Jamais baissé | oui |
| `nonAddon` | connu seulement sans l'addon ; l'affichage le recalcule si des vraies données arrivent | oui |
| `linkSeen[prof]` | horodatage du dernier lien vu pour ce métier (sous-ligne, classement de la purge) | **nouveau** |
| `linkSpell[prof]` | sort de rang lu dans le dernier lien, brut, jamais interprété (D4bis) | **nouveau** |
| `linkRecipes[prof]` | phase 2 : `{ ids = {…}, at, lvl, max }`, recettes apprises et niveau lus en cliquant son lien ; remplacé à chaque lecture, oublié par la purge | **nouveau** |

Invariants : `skill` et `recipes` d'une fiche restent réservés aux données réseau ; un lien n'y
écrit jamais. La purge D9 n'efface jamais une fiche qui a autre chose que des métiers vus sans
l'addon.

## Renvois

- Spec voisine : `docs/specs/canaux-surveilles.md` (où lire), `docs/specs/lfw-forever.md` (statut
  [Dispo]), `docs/specs/annonce-commerce.md` (Commerce relie les capitales, C15).
- Fiche jouée le 2026-09-27 : `docs/test-lien-metier.md` — format du lien, lien fabriqué, bug
  d'appropriation.
- Constats du jeu (dépôt d'outillage) : `docs/constats-api.md`, C15 (Commerce porte du texte en
  clair, d'une capitale à l'autre).
- Skill `wow-classic-addon-dev` (valeurs secrètes, noms de famille : clés au nom réseau
  « Prénom Nom », jamais réduites au prénom).
- Skill `human-verification` pour les critères [humain] ; relevés au registre
  `docs/verif-registre.md`.

## Plan (2026-10-02, volatile)

Une branche par dépôt, même nom : `feat/lien-metier` dans COC et dans l'outillage (le test va sur
`master` le jour où la fonctionnalité va sur `main`, pas avant).

- **Palier 1 — lire le lien** : fonction pure (texte, émetteur, GUID → métiers), tests 2 à 9.
- **Palier 2 — brancher** : la lecture LFW (guilde, chuchotements), l'annuaire, la purge, la
  sous-ligne et ses chaînes localisées ; tests 16 et 17.
- **Palier 3 — banc** : `.\deploy.ps1 -Banc feat/lien-metier`. La séance commence par le
  palier 0 (critère 1). A et B dans une capitale ; A colle la sonde, B lie son métier dans
  Commerce (Services) :

  ```
  /run local f=CreateFrame("Frame") f:RegisterEvent("CHAT_MSG_CHANNEL") f:SetScript("OnEvent",function(_,_,m,a,_,c,_,_,_,_,_,_,_,g) local l=m:match("\124H(trade:.-)\124h") if l then print(a,c,l,l:find(g,1,true) and "GUID=OK" or g) end end)
  ```

  Attendu : `<B> <canal> trade:Player-…:<sort>:<ligne> GUID=OK`. Rien = le lien n'arrive pas par
  ce canal ; un GUID à la place de `GUID=OK` = le lien n'est pas à l'émetteur. Noter aussi le
  sort de rang lu (une 3e valeur pour D4bis). (237 caractères, sous la limite de `/run` ; `\124`
  parce que le chat double les `|`.) Puis critères 11, 12 et 18, et le relevé de la garde du métier
  lié (D6) ; relevés au registre.
- **Phase 2** (D6 tenu à 11:21) : lecture de la vue liée dans `Directory_TradeLink.lua`, infobulle,
  test 19 (`tests/test_lien_metier_vue.lua`) ; puis banc. Sur A, vue liée de B ouverte :
  1. sonde D11 : `/dump C_TradeSkillUI.GetChildProfessionInfo()` → `skillLevel` = celui du titre ;
  2. si l'infobulle ne montre rien (critère 20), deux `/run` départagent les causes :
     `/run local v=CraftingOrderClassic.Directory._linkView print(v.key~=nil, v.fresh)` —
     `false` = la vue n'est pas reconnue (nom ou métier illisible) ; `true false` = aucune mise à
     jour de la liste n'est venue APRÈS l'ouverture (l'ordre des événements contredit D12) ;
     `/run local l=CraftingOrderClassic.Directory.roster["<B>"] l=l and l.linkRecipes and l.linkRecipes.<Métier> print(l and #l.ids, l and l.lvl, l and l.max)`
     — `5 1 75` pour la Forge de Gnomi = ça marche ;
  3. critères 14 et 20.
