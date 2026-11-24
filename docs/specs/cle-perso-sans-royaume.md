# Clé de perso sans royaume

> Statut : approuvée · Décidée le 2026-11-24 par le user (format à fixer, règle de reprise), format exact proposé par l'agent

## Le problème

Depuis le build 71037 du client Forever (bascule entre le 2026-11-20 et le 2026-11-23, lue dans les dates de
connexion d'une sauvegarde), `GetRealmName()` rend `""` et `GetRealmID()` rend `0` (mesuré en jeu le 2026-11-24,
fait public dans `wow-forever-api`, `chat-channels-and-communities.md`). Selon le user, Blizzard l'a fait pour
empêcher les joueurs de changer de calque à volonté. Le code d'interface de Blizzard du même build ne compare
plus les royaumes qu'à travers une fonction opaque, `C_BattleNet.IsGameAccountOnSameRealm`.

COC range tout ce qui appartient à un perso sous la clé « Prénom-Royaume » : `knownRecipes`, `myCooldowns`,
`mySkillsByChar`, `myChars`, `myCharNames`, `myCharFaction`. Depuis 71037, chaque perso qui se connecte écrit sous
« Prénom- » ; ce qu'il avait avant reste sous « Prénom-CAMWOW EU5 Realm 6 PvP » et n'est plus lu. Conséquences,
lues dans le code et dans la sauvegarde du user le 2026-11-24 :

- à la connexion, COC charge les recettes du perso depuis la clé neuve, vide : il n'annonce **aucune recette**
  tant que le joueur n'a pas rouvert chacun de ses métiers ;
- un reroll qui ne s'est pas reconnecté depuis disparaît de « Mes artisans », du menu « Mes métiers » et de la
  liste annoncée des rerolls ;
- `Handoff:MyRerollCanCraft` ne filtre pas par royaume : il prend l'ancienne partition du perso connecté pour
  celle d'un reroll, et peut annoncer « ton reroll <toi-même> sait le faire ».

## Ce qu'on veut

- La clé locale d'un perso ne dépend plus d'aucune API de royaume : « Prénom- », toujours. Si Blizzard rend un
  jour le royaume, la sauvegarde ne se recoupe pas.
- Ce qu'un perso avait avant 71037 lui revient sans rouvrir ses métiers.
- Plus aucun royaume écrit dans le chat (`/co alts`).

## Ce qu'on ne fait pas

- **Le pont entre royaumes** (`rm=`, spec `pont-royaumes.md`) reste aveugle dans ce chantier. Le GUID porte encore
  le royaume (`Player-6948-…`, mesuré le 2026-11-24), mais le relire pour l'annoncer à la salle redonnerait à
  tous ce que Blizzard vient de cacher. Décision du user (2026-11-24) : on ne le fait pas ; Blizzard a annoncé
  que le royaume partira aussi du GUID (dit par le user, source pas donnée), on attend cette mise à jour.
- **On n'efface pas les anciennes clés.** Une migration ne tourne qu'une fois et l'effacement ne se rattrape pas ;
  elles restent orphelines, filtrées par tous les lecteurs.
- **Pas de clé au nom complet** (« Prénom Nom ») : il faudrait changer chaque lecteur de clé, pour un gain qui ne
  concerne que deux persos du même compte au même prénom.

## Cas limites

- **Deux anciennes clés pour un même prénom** (deux persos du compte au même prénom sur deux royaumes, ou un
  perso transféré) : on ne reprend rien pour ce prénom, dans aucune table. Ils restent comme aujourd'hui.
- **Clé neuve déjà remplie** (le joueur a rouvert ses métiers après 71037) : on n'y touche pas, elle est plus
  fraîche que l'ancienne.
- **Clé neuve présente mais vide** (`_MyKnownStore` la crée vide à la connexion) : traitée comme absente.
- **Deux persos du compte au même prénom** : ils partagent désormais la clé « Prénom- ». Avant 71037 c'était
  déjà vrai sur un même royaume ; ça l'est maintenant entre royaumes. Accepté.
- **Persos PvE et PvP d'un même compte** : le royaume suit le compte par type de règles, donc un tel compte a
  deux royaumes. Sous « Prénom- », ils apparaissent ensemble dans « Mes artisans », « Mes métiers » et « ton
  reroll sait le faire » (le filtre de camp reste, celui de royaume n'existe plus). Vrai depuis 71037, pas à
  cause de ce chantier, mais le format le rend durable. Le courrier entre deux royaumes n'est pas mesuré : un
  reroll PvP proposé pour une commande reçue sur un perso PvE pourrait ne pas recevoir l'objet par courrier.

## Décisions

- 2026-11-24, **le user** (« 2 oui ») : fixer le format de clé avant l'étape 6 de CraftLink (`CraftLink` écrit
  ses recettes sous la même clé). Format exact proposé par l'agent : « Prénom- », qu'écrivent déjà tous les
  persos connectés depuis 71037 et CraftLink 0.1.0. Une seule source : `COC.Api.CharKey()` et
  `COC.Api.LOCAL_REALM` (`CraftingOrderClassic_Compat.lua`).
- 2026-11-24, **le user** (« 1 oui ») : reprise des anciennes données quand la clé neuve est vide et qu'il existe
  une seule ancienne clé pour ce prénom ; s'il y en a deux, on ne touche à rien.
- 2026-11-24, agent : la reprise est le palier 3 de `CraftingOrderClassic_Migrations.lua` (une fois par
  sauvegarde, pure, testable). L'ambiguïté se juge sur l'union des six tables. Copie profonde (deux clés ne
  partagent jamais une table). Anciennes clés gardées.
- 2026-11-24, agent : `Handoff:MyRerollCanCraft` ne lit plus que les clés du royaume local, comme les autres
  lecteurs. Ça couvre aussi le cas des deux anciennes clés, que la reprise laisse en place.
- 2026-11-24, agent : `/co alts` n'écrit plus le royaume (règle « pas de royaume dans l'interface »).

## Critères d'acceptation

1. [test] Une sauvegarde d'avant 71037 (« A-R » rempli, pas de « A- ») donne « A- » égal à « A-R », table par
   table, et « A-R » toujours là. → `tests/test_cle_perso_sans_royaume.lua`
2. [test] « A- » déjà rempli n'est pas touché ; « A- » vide est rempli. → même fichier
3. [test] « A-R1 » et « A-R2 » : rien n'est repris pour A ; B, seul, est repris. → même fichier
4. [test] La copie est profonde : modifier « A- » ne change pas « A-R ». → même fichier
5. [test] `MyRerollCanCraft` ne rend pas le perso connecté depuis son ancienne partition. → même fichier
6. [test] `COC.Api.CharKey()` (que `_MyKnownStore` et `_MyCooldownStore` appellent), `StampMyChar` et le miroir
   des niveaux écrivent « Prénom- » même si `GetRealmName()` rend un royaume ; CraftLink aussi
   (`test_craftlink_demarrage.lua`). → même fichier
7. [agent] Sur la sauvegarde du user après une connexion au banc, comparée table par table à la copie d'avant
   (`F:\sauvegardes-wow\coc-sv-avant-palier3-2026-11-24\`) : `schemaVer` passe à 3 ; les anciennes clés sont
   toutes là ; les clés neuves déjà remplies ne bougent pas (les trois persos ont rouvert leurs métiers après
   71037). Seule une partition neuve vide (`{}`, par exemple dans `myCooldowns`) peut recevoir la copie de
   l'ancienne. Lecture de la SV par `tools/elune`.
8. [human] Au banc : « Mes artisans » montre les mêmes persos et métiers qu'avant le déploiement ; `/co alts`
   écrit « persos du compte : … » sans parenthèses. Témoin : la même vue avant le déploiement.

## Liens

- Skill publique `wow-forever-api`, `chat-channels-and-communities.md` (royaume vide, GUID).
- `pont-royaumes.md` (le pont, aveugle depuis 71037), `CraftLink/docs/specs/addon-partage.md` (étape 6).
