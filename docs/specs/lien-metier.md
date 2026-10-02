# Un lien de métier posté dans le chat ajoute son auteur à l'annuaire

> État : **brouillon** · Rédigée le 2026-10-02 · Idée du user (« si un joueur link son métier, ça
> l'ajoute aussi »), décisions D1 à D6 proposées par l'agent et acceptées par le user le 2026-10-02 ·
> Pas encore implémentée
> Cible : WoW: Forever / Camelot (16001) uniquement · Addon : Crafting Order - Classic
>
> Deux phases. **Phase 1** (lire le lien sans cliquer) est prête à coder dès que la mesure du
> palier 0 est faite. **Phase 2** (garder ses recettes quand on clique) est **bloquée** : elle passe
> par la garde du métier lié du 2026-09-27, fusionnée mais jamais vue en jeu (aucun relevé dans
> `docs/verif-registre.md` au 2026-10-02).

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

## Ce qu'on veut

### Phase 1 — le lien suffit

Quand un joueur poste **son propre** lien de métier dans un canal que je surveille, il apparaît
dans mon onglet Artisans avec ce métier, comme un artisan connu sans l'addon (étiquette « VU »).
La sous-ligne dit que le métier vient d'un lien, pour qu'on ne le confonde pas avec un artisan
« vu crafter ».

- Le niveau reste **inconnu** : le lien n'en porte pas.
- S'il a l'addon, ses vraies données remplacent cette estimation dès qu'elles arrivent, comme pour
  un artisan vu crafter.
- Si la ligne est une ligne « LFW » et que le métier est donné par un lien, il passe aussi
  **[Dispo]**, exactement comme s'il avait tapé « LFW Enchanting ».
- Le métier est reconnu quelle que soit la langue du joueur qui l'a posté (`[Enchanting]`,
  `[Enchantement]`, `[Verzauberkunst]`…).

### Phase 2 — quand je clique son lien (bloquée)

Quand **je** clique le lien de métier d'un autre joueur, le jeu m'envoie sa liste de recettes. COC
la range **dans sa fiche à lui**, jamais dans la mienne. L'onglet Artisans peut alors dire ce qu'il
sait faire, et il peut apparaître parmi les artisans d'une recette, avec la mention « sans l'addon »
(on le joint en chuchotant, pas par une commande).

C'est l'inverse du bug du 2026-09-27, quand COC s'appropriait les recettes du lien cliqué. La
garde qui a corrigé ce bug (`IsOwnProfessionOpen` dans CraftLink, drapeau `PW._foreign` dans la
colonne) est exactement le point où la phase 2 se branche. Tant qu'elle n'a pas été vue en jeu, on
ne construit rien dessus.

## Ce qu'on NE fait PAS

- **Ouvrir un lien tout seul pour lire les recettes.** Ce n'est plus passif : ça ouvre une
  fenêtre, ça interroge le serveur, et ça refermerait le métier que le joueur a ouvert. Les
  recettes ne viennent que d'un clic du joueur (phase 2).
- **Déduire un niveau du sort de rang** contenu dans le lien (Compagnon, Expert…). Un seul id est
  mesuré sur Camelot (7412, Enchantement à 102/150). Une table copiée de Vanilla mentirait peut-être.
  Le métier entre avec un niveau inconnu.
- **Attribuer un lien relayé.** « Demande à X [Enchantement] » : le lien appartient à X, pas à
  celui qui parle. On l'ignore (D3).
- **Lire les liens postés dans une communauté** : leur texte arrive opaque (`|Kw1|k`, cf.
  constats C_Club). Rien à lire.
- **Partager ces artisans sur le réseau.** Ils restent dans MON annuaire, comme les artisans vus
  crafter. Le relais de fiches ne sert jamais une liste lue sur un lien (phase 2 comprise).
- **Les métiers secondaires** : Cuisine, Secourisme, Pêche (D2).
- **Un bouton « voir son métier »** qui rejouerait plus tard un lien gardé. Le rejeu n'est pas
  mesuré : celui du 2026-09-27 (joueur déconnecté) a pu sortir du cache du client. À rouvrir
  après une mesure.
- **Purger l'annuaire.** `db.roster` n'est jamais élagué ; cette fonctionnalité le remplit un peu
  plus vite (voir Questions ouvertes). Pas traité ici.

## Cas particuliers

- **Mon propre lien** : je ne m'ajoute pas à mon annuaire. « LFW [mon Enchantement] » garde la
  règle actuelle d'une ligne LFW tapée par moi : raccourci de `/co lfw`, sans annonce sur Commerce.
  L'écho de ma ligne `LFW … #CO` postée par l'addon reste ignoré.
- **Plusieurs liens dans une ligne** : chaque lien qui appartient à l'auteur compte. Une ligne LFW
  ne donne qu'**un** statut [Dispo] (LFW = un seul métier) : le premier métier reconnu ; les autres
  entrent seulement à l'annuaire.
- **Le même joueur reposte son lien toutes les minutes** (Commerce) : sa fiche est rafraîchie,
  rien ne se duplique, et on ne refait pas le travail à chaque ligne.
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
- **Canal décoché** dans « Canaux surveillés », ou `/co lfwchat off` : ignoré.
- **Commerce relie toutes les capitales** (constat C15) : un lien posté à Hurlevent arrive à
  Forgefer. Ce n'est pas un repérage « alentour » comme le message « X crée Y ».
- **Lien fabriqué à la main** : avec D3, on ne peut s'attribuer un métier qu'à soi-même, ce qui ne
  vaut pas plus que de taper « LFW Enchanting ». Le serveur accepte-t-il seulement un lien
  fabriqué dans le chat ? Pas mesuré, et sans conséquence grâce à D3.

## Décisions

Toutes proposées par l'agent le 2026-10-02, acceptées par le user le même jour.

- **D1 — L'interrupteur est celui des lignes LFW.** La lecture suit `/co lfwchat` (actif par
  défaut) et les cases « Canaux surveillés », pas la case « nearby » (repérage alentour, opt-in,
  en ville). Raison : même coût qu'une ligne LFW (une recherche de texte par ligne lue), mêmes
  canaux, alors que la case « nearby » existe pour un événement qui coûtait cher.
- **D2 — Métiers principaux seulement**, comme le repérage alentour (`COC.SECONDARY_PROF`).
- **D3 — Le lien compte seulement si son GUID est celui de l'émetteur** (12e argument de
  l'événement de chat). Sinon, il est ignoré. Raison : le jeu authentifie l'émetteur, pas ce dont
  il parle.
- **D4 — Niveau inconnu.** Le métier entre « connu, niveau inconnu », comme une ligne LFW lue dans
  le chat. Pas de tranche tirée du sort de rang tant qu'elle n'est pas mesurée.
- **D5 — LFW + lien = [Dispo].** Combler le trou de `_Parse` fait partie de la fonctionnalité, pas
  d'un chantier à part.
- **D6 — La phase 2 attend le banc.** Pas une ligne de code de phase 2 avant un relevé, au
  registre, de la garde du métier lié (B lie, A clique : pas de colonne COC, `knownRecipes` d'A
  inchangé).

## Questions ouvertes

- **Chuchotements et guilde.** Le jeu les authentifie aussi. Un lien reçu en chuchotement est la
  réponse typique à une demande (« je peux, [Enchantement] »). La lecture LFW n'écoute aujourd'hui
  ni l'un ni l'autre ; la case « guilde » existe déjà dans « Canaux surveillés ». **À trancher par
  le user.** En attendant, la phase 1 lit les mêmes sources que les lignes LFW : canaux du jeu
  cochés, dire et crier.
- **Un artisan connu par un seul lien doit-il s'effacer ?** Un état déduit du réseau doit expirer
  (leçon de la notification de version). Aujourd'hui, rien n'expire dans l'annuaire, lignes LFW et
  « vu crafter » compris. À mesurer : combien d'entrées une soirée en Commerce ajoute.
- **Phase 2, à mesurer avant de coder** : le format du nom rendu par `IsTradeSkillLinked()` sur
  Forever (prénom seul ou « Prénom Nom » ? un prénom seul est ambigu, il faudrait alors partir du
  GUID du lien) ; le niveau du propriétaire lisible dans la vue liée.

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
9. **[test]** Canal décoché, `/co lfwchat off`, ou auteur en sourdine → rien.
10. **[porte]** Toute chaîne nouvelle est localisée (`check_locale.ps1`) ; Lua 5.1 valide, tailles
    de fichier et de fonction tenues (`check_lua.ps1`, `check_size.ps1`).
11. **[humain]** Au banc, B **sans COC activé** lie son Enchantement dans Commerce (Services). Chez
    A, B apparaît dans l'onglet Artisans, étiquette « VU », et la sous-ligne nomme l'Enchantement en
    disant qu'il vient d'un lien. Témoin : juste avant, B est absent de la liste d'A (A l'a oublié),
    et la sonde du palier 0 affiche la ligne reçue. Observateur : le user, compte A.
12. **[humain]** B tape « LFW » puis lie son Enchantement dans la même ligne : chez A, B passe
    [Dispo]. Même témoin que le 11.
13. **[agent]** `api-gotcha-reviewer` sur le diff : aucune valeur du chat utilisée avant le test
    du secret, aucun abonnement à un événement restreint.

### Phase 2 (après D6)

14. **[humain]** A clique le lien d'Enchantement de B : la fiche de B chez A annonce ses recettes ;
    le nombre de recettes d'Enchantement **d'A** (`knownRecipes`) est le même avant et après ;
    rien de neuf ne part sur le réseau. Témoin : le relevé de la garde du métier lié (D6).
15. **[test]** Des recettes lues dans une vue liée ne vont jamais dans mes recettes connues ni dans
    les recettes réseau d'une fiche (`r.recipes`).

## Contrat

Rien ne change sur le fil : rien n'est envoyé. Le contrat est la fiche persistée
(`db.roster[<nom réseau>]`), en ajouts seulement, qu'un client plus ancien ignore :

| Champ | Sens | Existe déjà ? |
|---|---|---|
| `craftSeen[prof]` | plancher de niveau ; `0` = connu sans l'addon, niveau inconnu. Jamais baissé | oui |
| `nonAddon` | connu seulement sans l'addon ; l'affichage le recalcule si des vraies données arrivent | oui |
| `linkSeen[prof]` | horodatage du dernier lien vu pour ce métier (sert à la sous-ligne) | **nouveau** (nom proposé) |
| `linkRecipes[prof]` | phase 2 : `{ ids = {…}, at = <horodatage> }`, recettes lues en cliquant son lien | **nouveau** (nom proposé) |

Invariant : `skill` et `recipes` d'une fiche restent réservés aux données réseau ; un lien n'y
écrit jamais.

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

- **Palier 0 — mesurer** (critère 1). A et B dans une capitale ; A colle la sonde, B lie son
  métier dans Commerce (Services) :

  ```
  /run local f=CreateFrame("Frame") f:RegisterEvent("CHAT_MSG_CHANNEL") f:SetScript("OnEvent",function(_,_,m,a,_,c,_,_,_,_,_,_,_,g) local l=m:match("\124H(trade:.-)\124h") if l then print(a,c,l,l:find(g,1,true) and "GUID=OK" or g) end end)
  ```

  Attendu : `<B> <canal> trade:Player-…:<sort>:<ligne> GUID=OK`. Rien = le lien n'arrive pas par
  ce canal ; un GUID à la place de `GUID=OK` = le lien n'est pas à l'émetteur. Noter aussi le
  sort de rang lu (une 2e valeur pour la question du niveau). (237 caractères, sous la limite de
  `/run` ; `\124` parce que le chat double les `|`.)
- **Palier 1 — lire le lien** : fonction pure (texte, émetteur, GUID → métiers), tests 2 à 9 dans
  `tests/test_lien_metier.lua`.
- **Palier 2 — brancher** : la lecture LFW, l'annuaire, la sous-ligne et ses chaînes localisées.
- **Palier 3 — banc** : `.\deploy.ps1 -Banc feat/lien-metier`, critères 11 et 12, relevés au
  registre.
- **Phase 2** : après le relevé de D6 ; mesures de la question ouverte d'abord.
