# Craftsman's Writ → une commande d'artisan

> État : **brouillon** du 2026-10-16 · Idée du user, mise en forme par l'agent · Rien de codé.
> Mesures préalables à faire (critères 1 et 2) avant tout code. Les Waylaid Crate, l'autre moitié du
> système, auront leur propre spec quand on saura ce qu'une caisse demande (voir « Ce qu'on ne fait
> pas »).

## Le problème

WoW: Forever a ajouté une réputation de métiers, l'**Azeroth Commerce Authority** (ACA). Un joueur
reçoit un **Craftsman's Writ** : un parchemin qui lance une quête journalière. La quête demande un
objet fabriqué par un artisan, à rapporter à un PNJ (dit par le user le 2026-10-16). L'objet est
tiré **au hasard** parmi 150, sur cinq métiers : Alchimie, Forge, Ingénierie, Travail du cuir,
Couture.

La plupart du temps, l'objet n'est donc **pas de son métier**. Aujourd'hui il crie sur Commerce,
explique ce qu'il veut, cherche quelqu'un qui sait le faire, ou jette le writ. C'est exactement une
commande d'artisan, passée par un PNJ, et COC sait déjà dire qui connaît quelle recette et porter une
commande jusqu'à lui.

De l'autre côté, un artisan ne sait pas quels objets les porteurs de writ cherchent.

Ce qu'on sait du système, lu le 2026-10-16 dans deux pages Wowhead enregistrées (recherche
« Craftsman's writ », objet 248549) :

| | |
|---|---|
| Writs | objets 264011 à 264160, chacun lance une quête journalière (94004 à 94360) |
| Paliers | Journeyman : 45 writs, 75 de réputation · Expert : 60, 125 · Artisan : 45, 200 |
| Réputation | deux factions (2586, 2587), qui montent ensemble ; leurs noms ne sont pas connus |
| Objets demandés | 149 sur 150 retrouvés par leur nom anglais dans les données CraftLink ; reste « Potion of Demonslaying » (sans doute l'Elixir of Demonslaying, 9224, renommé) |
| Autres | « Sealed Craftsman's Writ » (248206), sans doute le contenant qui donne un writ ; objet 284584 en récompense de certains writs, inconnu |

## Ce qu'on veut

1. **Au survol d'un writ** (dans les sacs, avant de l'avoir ouvert), l'infobulle dit en une ou deux
   lignes **qui sait fabriquer l'objet demandé**, du plus proche au plus lointain : toi, un de tes
   rerolls, des artisans connus de COC (combien, dont combien en ligne), ou personne de connu. Si le
   jeu ne nomme pas l'objet dans l'infobulle, notre ligne le nomme.
2. **Dans l'onglet Commande**, l'objet d'un writ que tu portes (en sac, ou quête acceptée et pas
   encore remplie) est **marqué** et se choisit **en un clic**. Le formulaire s'ouvre alors sur le
   bon plan, quantité 1, avec un titre déjà écrit qui dit que c'est pour un writ. Tu choisis le
   destinataire et la commission comme d'habitude, et rien ne part sans ton clic sur « Poster ».
3. **L'artisan qui reçoit la commande** voit ce titre et sait que c'est pour un writ. Rien d'autre ne
   change pour lui : c'est une commande comme les autres, avec son cycle habituel (acceptée,
   fabriquée, échangée).
4. Si **tu sais déjà le faire**, la ligne de l'infobulle le dit, et la commande n'est pas proposée en
   premier.

## Ce qu'on ne fait PAS

- **Les Waylaid Crate.** Une caisse verte qui devient une des 30 caisses typées (herbes, minerai,
  tissus, curiosités, et des rouleaux, lingots, pièces d'ingénieur). On ne sait pas encore ce qu'il
  faut y mettre. Elles feront une spec à part (liste de courses, commandes de rouleaux et lingots)
  quand les pages des caisses typées seront lues.
- **Rien dans le chat.** Ni quand un writ tombe, ni quand la quête est acceptée ou rendue (règle du
  chat sobre). Ni commande automatique, ni appel « à tous » : le joueur décide, puis clique.
- **Pas de nouveau champ sur le réseau.** L'origine « writ » voyage dans le titre de la commande, qui
  existe déjà (fiche de quête). Un client COC plus ancien affiche donc la commande normalement.
- **Pas de suivi de la réputation ACA** ni du nombre de journalières faites : c'est le métier du jeu,
  pas de COC.
- **Pas de marché des writs** (donner ou vendre son writ à un artisan), même si le writ s'échangeait.
- **Pas de marque sur les recettes côté artisan** (« cette recette est demandée par des writs, 125 de
  réputation ») dans ce premier tour. C'est la piste suivante si le premier tour sert.
- **Pas de clic modifié sur l'objet dans les sacs** : toucher aux boutons du sac expose au taint, et
  l'onglet Commande suffit.
- **Les 27 writs d'Era** (Aube d'argent, niveau 55, quêtes 9142-9206) : un autre système, absent de
  Forever.

## Cas particuliers

- **Objet demandé inconnu de CraftLink** (aujourd'hui un seul, peut-être zéro) : l'infobulle nomme
  l'objet sans ligne « qui sait le faire », et l'onglet Commande ne le propose pas. Pas d'erreur.
- **Un writ que la table ne connaît pas** (Blizzard en ajoute un) : ignoré, sans erreur ni ligne.
- **Le writ disparaît du sac à l'ouverture** et la quête prend le relais : un même writ ne doit
  jamais compter deux fois (sac + journal).
- **L'objet est déjà dans tes sacs**, ou l'objectif est déjà à 1/1 : on ne propose plus de commande.
- **Plusieurs writs à la fois** : chacun est marqué ; deux writs pour le même objet donnent une seule
  marque.
- **Quête abandonnée, ou remise à zéro des journalières** : la marque disparaît avec elle.
- **Client en français, allemand ou espagnol** : on reconnaît le writ et l'objet par leurs
  identifiants, jamais par leur nom. Le titre de la commande est écrit dans la langue de l'acheteur,
  comme tout récit de commande.
- **Un reroll sait le faire** : on le dit, mais on propose quand même la commande (le reroll n'est
  pas connecté).
- **En combat** : seule l'infobulle bouge, aucun cadre protégé n'est touché.

## Décisions

- **D1 (user, 2026-10-16)** : on commence par les writs, en partant de « writ → commande ». La quête
  demande un objet fabriqué par un artisan, à rapporter à un PNJ. Qu'un objet fabriqué par **un autre
  joueur** soit accepté reste à voir en jeu (critère 1) : si ce n'est pas le cas, cette spec tombe et
  on revient à « aider le porteur à le fabriquer lui-même ».
- **D2 (proposée par l'agent)** : writ, quête, objet demandé et palier viennent d'une **table
  générée** (150 lignes, identifiants seulement), tirée des pages Wowhead et des noms anglais de
  CraftLink, rangée dans COC. Pourquoi : les noms sont traduits, et rien ne dit encore que
  l'infobulle du writ porte un lien vers l'objet (critère 2). Si le journal de quêtes rend l'objet
  demandé par son identifiant, on le lit en jeu et la table ne sert plus qu'au writ pas encore ouvert.
- **D3 (proposée par l'agent)** : la table reste dans COC, pas dans CraftLink. Un seul dépôt touché,
  pas de lib embarquée à resynchroniser, et les writs sont un usage de COC, pas une donnée de métier.
- **D4 (proposée par l'agent)** : deux surfaces seulement, l'infobulle (lecture) et l'onglet Commande
  (le geste). Le journal COC et le suivi à l'écran pourront suivre si le user le demande.
- **D5 (proposée par l'agent)** : un module neuf, branché sur l'onglet Commande par un point
  d'entrée, plutôt qu'un ajout dans `UI_Post` (déjà 429 lignes sur 500).

## Critères d'acceptation

**Mesures préalables, avant tout code :**

1. [humain] Deux comptes. A ouvre un writ (quête acceptée, objectif à 0/1 : c'est le témoin). B
   fabrique l'objet demandé et le donne à A par l'échange. L'objectif de A passe à 1/1, et A rend la
   quête au PNJ. Noter le PNJ et l'endroit. **Si ça échoue, la spec s'arrête (D1).**
2. [humain] Sur un client en français, l'infobulle d'un writ pas encore ouvert : quelles lignes,
   l'objet est-il nommé, est-ce un lien ? Et la même chose pour la quête acceptée, dans le journal du
   jeu.

**Une fois codé :**

3. [test] Chacun des 150 writs donne sa quête, son objet demandé et son palier ; un identifiant
   inconnu donne `nil` sans erreur. → `tests/test_writs.lua`
4. [test] « Qui sait le faire » pour un writ : moi, puis un reroll, puis l'annuaire (en ligne
   d'abord), avec les comptes ; aucune recette connue donne « personne de connu » ; un objet absent de
   CraftLink ne donne aucune ligne. → même fichier
5. [test] Un writ en sac puis la même quête acceptée comptent pour un seul ; l'objectif à 1/1, ou
   l'objet déjà en sac, retire la marque. → même fichier
6. [test] Choisir l'objet d'un writ dans l'onglet Commande sélectionne le bon plan, quantité 1, titre
   pré-rempli, et **ne poste rien** tant que « Poster » n'est pas cliqué. → même fichier
7. [test] Aucune ligne de chat quand un writ entre au sac, quand la quête est acceptée, quand elle
   est rendue (skill `chat-output`). → même fichier
8. [porte] Les quatre portes ; chaque chaîne neuve est dans les trois overlays.
9. [humain] Survol d'un writ en sac : les lignes COC sont là, lisibles, sous celles du jeu. Témoin :
   l'infobulle d'un objet ordinaire, sans ligne COC.
10. [humain] Deux comptes. A choisit l'objet de son writ dans l'onglet Commande et poste une commande
    nommée pour B. B la reçoit avec le titre du writ, l'accepte, la fabrique, l'échange. A rend la
    quête. Témoin : une commande ordinaire passée entre les mêmes comptes, sans titre.
11. [agent] `api-gotcha-reviewer` sur le diff (accroche de l'infobulle, lecture du journal) ; et en
    jeu, `/console taintLog 1`, une infobulle de writ survolée pendant un combat : rien de COC dans
    `Logs\taint.log`.

## Contrat

Rien sur le réseau (voir « Ce qu'on ne fait pas »), rien de neuf dans les SavedVariables. La table
générée est interne à COC : `itemID du writ → { quête, objet demandé, palier }`. Elle porte en tête
la page source et la date de sa génération, pour qu'on sache quand la refaire.

## Questions ouvertes

- **Pour le user** : faut-il aussi la quête du writ dans le **journal COC** (bouton « Commander » sur
  sa fiche), dès ce premier tour ? (D4)
- **Pages Wowhead à enregistrer** (en anglais, extension `tools\wowhead-page`) : le guide
  « Azeroth Commerce Authority Reputation Guide » (PNJ, remise, d'où viennent les writs, noms des deux
  factions) ; la quête 94004 et le writ 264011 (ce que la quête demande exactement) ; le
  « Sealed Craftsman's Writ » 248206 ; l'objet 284584.
- Le writ lui-même s'échange-t-il ? Sans effet sur ce tour, utile pour la suite.

## Liens

- Mémoire de l'analyse : `coc-writs-caisses-aca` (mémoire de session, `.claude\memoire`).
- `CraftingOrderClassic_JournalQuests.lua` : la lecture du journal de quêtes du jeu, et ses deux
  pièges (sélection partagée, en-têtes repliés).
- `CraftingOrderClassic_QuestSheet.lua` : le titre et le récit d'une commande.
- Skills : `wow-addon-dev:wow-forever-api` (infobulles et journal de quêtes sur Forever),
  `wow-addon-dev:chat-output`, `coc-native-ui` (onglet Commande), `craftlink-data-pipeline` (noms
  anglais canoniques).
