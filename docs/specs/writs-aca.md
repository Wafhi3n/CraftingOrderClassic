# Craftsman's Writ → une commande d'artisan

> État : **brouillon** du 2026-10-16 · Idée du user, mise en forme par l'agent · Critères 0 et 1
> **tenus** le 2026-10-16, critère 2 **tenu** le 2026-10-17 (captures du user, client anglais) : les
> quantités varient d'un writ à l'autre, ce qui a corrigé T2 · D2 à D6 à valider par le user · Plan
> en fin de fichier : **T1 et T2 faits** sur `feat/writs-aca` (COC et outillage), critères 3, 4 et 5
> tenus en test, rien de visible en jeu encore. Les Waylaid Crate, l'autre moitié du système, auront leur propre
> spec quand on saura ce qu'une caisse demande (voir « Ce qu'on ne fait pas »).
> **2026-11-09** : le user veut les writs dans la **vue Profit** (D7 à D9) : une marque tout de suite
> (T5), un relevé en jeu de la quantité et de l'or de chaque writ (T6), puis le coût de la réputation
> quand COC aura appris ces chiffres (T7). La branche porte désormais `feat/profit-arbitrages` : elle
> ne part dans `main` qu'après elle.
> **2026-11-11** : le user veut aussi voir, **dans l'infobulle de l'objet** demandé (sac, HdV, lien
> du chat), qu'un writ le demande (D10, T8). Branche `feat/writs-infobulle`, empilée sur
> `feat/writs-aca` dans les deux dépôts.

## Le problème

WoW: Forever a ajouté une réputation de métiers, l'**Azeroth Commerce Authority** (ACA). Un joueur
reçoit un **Craftsman's Writ** : un parchemin qui lance une quête journalière. La quête demande un
objet fabriqué par un artisan, à rapporter à un PNJ (dit par le user le 2026-10-16). L'objet est
pris parmi 150, sur cinq métiers : Alchimie, Forge, Ingénierie, Travail du cuir, Couture. Le tirage
**ignore les métiers du joueur** (critère 0, vu par le user : un enchanteur-forgeron a reçu un writ
d'Alchimie).

L'objet n'est donc la plupart du temps **pas de son métier**. Il peut l'acheter à l'hôtel des ventes
(une potion achetée là a été acceptée : critère 1) ; quand l'HdV n'en a pas ou le vend cher, il ne
lui reste qu'à trouver un artisan. Aujourd'hui il crie sur Commerce,
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
| Objets demandés | les 150 retrouvés par leur nom anglais dans les pages Forever des métiers : 147 à la casse près (« Pearl-Handled » / « Pearl-handled »), 3 à une orthographe près (« Ogre's » / « Ogre », « Demonslaying » / « Demon Slaying », « Adjuster » / « Adjustor ») ; un nom désigne deux objets (« Golden Scale Gauntlets », 9366 et 217273) |
| Quantités | l'objectif demande N objets, et N **varie** : 200 « Crafted Solid Shot » pour un writ d'ingénieur (capture du 2026-10-17). Aucune page lue ne donne N ; le journal le donne une fois la quête acceptée |
| Enveloppes | « Sealed Journeyman's Writ », « Sealed Expert's Writ » (identifiants inconnus ; un « Sealed Artisan's Writ » probable) : on déchire l'enveloppe, le writ est tiré au hasard dans ce palier (captures du 2026-10-17). Le « Sealed Craftsman's Writ » (248206) de Wowhead en est peut-être une autre |
| Échange | writs et enveloppes se vendent à l'HdV (vu par le user le 2026-10-17) ; le 2026-11-09, des dizaines de writs Journeyman à 6-20 pa (capture du user) |
| Récompense | la réputation du palier (Wowhead) ; **pas d'or direct mais une Coin Pouch** (capture du user + relevé en jeu le 2026-11-11 : writ de l'Iridescent Hammer, quête 94222, 0 d'or annoncé par le journal, « You will receive: Coin Pouch ») ; l'or « un peu » dont parlait le user le 2026-11-09 sort de la bourse, montant inconnu ; l'objet 284584 pour 12 quêtes, inconnu |
| Par jour | pas de plafond apparent (impression du user le 2026-11-09, à confirmer en jeu) : chaque writ est sa propre journalière |

## Ce qu'on veut

1. **Au survol d'un writ** (dans les sacs, avant de l'avoir ouvert), l'infobulle dit en une ou deux
   lignes **qui sait fabriquer l'objet demandé**, du plus proche au plus lointain : toi, un de tes
   rerolls, des artisans connus de COC (combien, dont combien en ligne), ou personne de connu. Le
   jeu nomme déjà l'objet dans le nom du writ (« Craftsman's Writ: Crafted Solid Shot ») : nos lignes
   ne le répètent pas.
2. **Dans l'onglet Commande**, l'objet d'un writ que tu portes (en sac, ou quête acceptée et pas
   encore remplie) est **marqué** et se choisit **en un clic**. Le formulaire s'ouvre alors sur le
   bon plan, avec **ce qui manque** pour remplir la quête (150 si l'objectif est à 50/200), et un
   titre déjà écrit qui dit que c'est pour un writ. Pour un writ pas encore ouvert, la quantité est
   inconnue (D6). Tu choisis le destinataire et la commission comme d'habitude, et rien ne part sans
   ton clic sur « Poster ».
3. **L'artisan qui reçoit la commande** voit ce titre et sait que c'est pour un writ. Rien d'autre ne
   change pour lui : c'est une commande comme les autres, avec son cycle habituel (acceptée,
   fabriquée, échangée).
4. Si **tu sais déjà le faire**, la ligne de l'infobulle le dit, et la commande n'est pas proposée en
   premier.
5. **Dans la vue Profit** (colonne accolée à la fenêtre de métier), une recette dont l'objet est
   demandé par un writ porte une **petite icône de writ**. Son infobulle dit le palier et la
   réputation (« +75 de réputation »), le prix du writ à l'HdV quand Auctionator le connaît, et ce que
   COC a vu en jeu de ce writ (quantité, or). Si **tu portes** ce writ, l'icône est pleine et
   l'infobulle dit ce qu'il te manque ; sinon elle est éteinte : ce sont les autres porteurs qui
   cherchent l'objet. (D7)
6. **COC apprend chaque writ en jeu** : quand une quête de writ est dans ton journal, il retient la
   quantité demandée et l'or de la récompense, avec le niveau du personnage. Rien dans le chat. (D8)
7. **Plus tard, le coût de la réputation** : pour chaque writ dont tu sais faire l'objet, prix du writ
   à l'HdV + coût de fabrication × quantité − or rendu, ramené par point de réputation, le moins cher
   en tête. Seulement pour les writs dont COC a vu la quantité. (D9)
8. **Au survol d'un objet qu'un writ demande**, où que le jeu montre son infobulle (sac, hôtel des
   ventes, lien du chat), UNE ligne sous celles du jeu : « Craftsman's Writ: +75 » (la réputation du
   writ ; celle du writ que tu portes si deux writs demandent l'objet). Le détail reste dans la vue
   Profit. (D10, D11)

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
- **Pas de marché des writs** (donner ou vendre son writ à un artisan). Writs et enveloppes se vendent
  déjà à l'HdV : COC n'y touche pas.
- **Pas d'aide sur les enveloppes** (« Sealed Journeyman's Writ »…) dans ce premier tour. Piste pour
  plus tard : « tu sais faire 12 des 45 writs de ce palier » dans leur infobulle, pour décider s'il
  vaut la peine de l'acheter. Il faudra leurs identifiants.
- **La marque côté artisan vit dans la vue Profit** (D7, 2026-11-09) **et dans l'infobulle de
  l'objet** (D10, 2026-11-11) : rien dans la liste de recettes de Blizzard (y écrire la teinte), ni
  dans l'onglet Commande pour l'instant, ni dans les infobulles de comparaison.
- **Pas de partage réseau de ce que COC a vu des writs** (quantité, or) : chacun apprend sur son
  compte. À reprendre si le relevé reste trop maigre pour le coût de la réputation.
- **Pas de clic modifié sur l'objet dans les sacs** : toucher aux boutons du sac expose au taint, et
  l'onglet Commande suffit.
- **Les 27 writs d'Era** (Aube d'argent, niveau 55, quêtes 9142-9206) : un autre système, absent de
  Forever.

## Cas particuliers

- **Objet demandé inconnu de CraftLink** (aucun aujourd'hui, mais les données de recettes bougent
  pendant la bêta) : l'infobulle nomme l'objet sans ligne « qui sait le faire », et l'onglet
  Commande ne le propose pas. Pas d'erreur.
- **Deux objets du même nom** (« Golden Scale Gauntlets », deux recettes de forge) : la table garde
  les deux. Quête acceptée, son objectif dit lequel est demandé ; writ pas encore ouvert, « qui sait
  le faire » compte les deux recettes.
- **Un writ que la table ne connaît pas** (Blizzard en ajoute un) : ignoré, sans erreur ni ligne.
- **Le writ disparaît du sac à l'ouverture** et la quête prend le relais : un même writ ne doit
  jamais compter deux fois (sac + journal).
- **Une partie des objets est déjà là** (objectif à 50/200 : le jeu compte ceux des sacs) : on ne
  propose que ce qui manque. Objectif atteint (200/200), même avant que le jeu ne dise la quête
  « remplie » : plus de commande.
- **Writ pas encore ouvert, objet déjà en sac** : on ignore combien il en faut, donc on ne conclut
  rien ; le writ reste marqué.
- **Plusieurs writs à la fois** : chacun est marqué ; deux writs pour le même objet donnent une seule
  marque.
- **Quête abandonnée, ou remise à zéro des journalières** : la marque disparaît avec elle.
- **Client en français, allemand ou espagnol** : on reconnaît le writ et l'objet par leurs
  identifiants, jamais par leur nom. Le titre de la commande est écrit dans la langue de l'acheteur,
  comme tout récit de commande.
- **Un reroll sait le faire** : on le dit, mais on propose quand même la commande (le reroll n'est
  pas connecté).
- **En combat** : seule l'infobulle bouge, aucun cadre protégé n'est touché.
- **Vue Profit, recette de writ à perte** : pas de ligne, comme toute recette à perte (règle de la
  vue). La marque dit « on te l'achète », pas « fabrique-le à perte » ; le coût de la réputation (T7)
  saura lister ces recettes-là.
- **Deux relevés qui ne s'accordent pas** (une même quête qui demande 20 puis 40) : on garde le
  dernier vu, le plus petit et le plus grand, et l'infobulle dit l'écart au lieu d'une moyenne.
- **L'or dépend du niveau** : sur un contenu vanilla, un personnage au niveau maximum reçoit souvent de
  l'or à la place de l'expérience. Chaque relevé d'or garde le niveau du personnage qui l'a vu.
- **Une quête dont l'objectif n'est pas encore rempli par le jeu** (journal pas prêt à l'acceptation) :
  rien n'est retenu, on relira au prochain passage.

## Décisions

- **D1 (proposée par l'agent, conditions tenues le 2026-10-16)** : on commence par les writs, en
  partant de « writ → commande ». Elle repose sur ce que le user a dit le 2026-10-16 : « le writ
  demande un objet, sous forme de quête, qu'un artisan doit fabriquer et à rapporter à un PNJ », puis
  sur ses deux observations en jeu : le tirage ignore les métiers du joueur, et un objet acheté à
  l'HdV est accepté (critères 0 et 1).
- **D2 (proposée par l'agent)** : writ, quête, objet demandé et palier viennent d'une **table
  générée** (150 lignes, identifiants seulement), tirée des pages Wowhead et des noms anglais de
  CraftLink, rangée dans COC. Pourquoi : les noms sont traduits, l'infobulle du writ ne nomme l'objet
  que dans le nom du writ, sans lien, et l'objectif de la quête ne le nomme qu'en texte
  (« 0/200 Crafted Solid Shot ») : aucun identifiant à lire en jeu (critère 2, 2026-10-17). La table
  est donc la seule source de l'objet ; le journal ne sert qu'aux quantités. Les identifiants viennent
  des pages **Forever** des métiers, jamais des noms de Classic : Forever a réattribué des
  identifiants d'objets (voir l'en-tête de `CraftingOrderClassic_Sources.lua`).
- **D3 (proposée par l'agent)** : la table reste dans COC, pas dans CraftLink. Un seul dépôt touché,
  pas de lib embarquée à resynchroniser, et les writs sont un usage de COC, pas une donnée de métier.
- **D4 (proposée par l'agent)** : deux surfaces seulement, l'infobulle (lecture) et l'onglet Commande
  (le geste). Le journal COC et le suivi à l'écran pourront suivre si le user le demande.
- **D5 (proposée par l'agent)** : un module neuf, branché sur l'onglet Commande par un point
  d'entrée, plutôt qu'un ajout dans `UI_Post` (déjà 429 lignes sur 500).
- **D6 (proposée par l'agent, 2026-10-17)** : la quantité d'un writ pas encore ouvert est
  **inconnue**, et COC ne la devine pas. L'onglet Commande marque quand même son objet ; la commande
  se pré-remplit avec ce qui manque pour une quête acceptée, et sinon laisse la quantité au joueur
  avec une ligne « ouvre le writ pour savoir combien il en faut ». ~~Autre voie écartée pour
  l'instant : retenir la quantité vue une fois par quête.~~ **Reprise le 2026-11-09 par D8** : COC
  retient ce qu'il a vu, et l'affiche comme un relevé (« vu en jeu : 200 »), jamais comme une
  certitude : rien ne prouve que la quantité d'une quête soit fixe.
- **D7 (choix du user, 2026-11-09)** : les writs entrent dans la **vue Profit** par une **marque** sur
  les recettes dont ils demandent l'objet. La vue reste triée par l'or ; la marque n'ajoute ni ne
  retire de ligne. L'objet d'une ligne se lit à la même source que son prix (le schéma de la recette
  du client, puis CraftLink), pour que marque et prix parlent du même objet.
- **D8 (choix du user, 2026-11-09)** : COC **relève en jeu** la quantité et l'or de chaque writ dont
  la quête passe dans le journal (`db.writsSeen`, par compte, créé à l'usage). Le user dit que la
  quête donne « un peu d'or » ; personne n'en connaît le montant. L'or du journal n'est qu'une
  **annonce** : COC relève aussi l'or **versé** au rendu (`QUEST_TURNED_IN`, champ `moneyReward` dans
  la doc de l'interface de Forever), qui fait foi pour T7 ; l'infobulle montre celui-là d'abord.
- **D9 (choix du user, 2026-11-09)** : le **coût de la réputation** vient ensuite (T7), une fois que
  le relevé a des chiffres. Pas de plafond par jour apparent (impression du user, à confirmer) : en
  enchaîner plusieurs a donc du sens, et la liste les classe tous.
- **D10 (choix du user, 2026-11-11)** : la marque passe aussi dans **l'infobulle de l'objet**
  demandé, partout où le jeu la montre (« c'est possible de rajouter sur le tooltip si l'item est
  demandé par un writ », capture de l'Iridescent Hammer). Accroche du jeu
  (`TooltipDataProcessor.AddTooltipPostCall`, type Item), filtrée comme le fait Blizzard :
  `GameTooltip` et `ItemRefTooltip` seulement. Comme l'infobulle se refait à chaque survol, on ne lit
  que les writs de CET objet (`ItemMark`), jamais les 150. La vue Profit garde ses propres lignes (prix
  du writ, relevé) : ses lignes portent un drapeau, et l'accroche se tait sur elles. Ce n'est pas T3,
  qui reste l'infobulle du **writ** lui-même.
- **D11 (choix du user, 2026-11-11, après l'avoir vue au banc)** : dans l'infobulle de l'objet, **une
  seule ligne**, « Craftsman's Writ: +75 » (la réputation du writ), « pas plus, on flood pas le
  tooltip ». Les phrases de D10 (« Demandé par un writ d'artisan… », ce qui manque, « les porteurs
  cherchent… ») restent dans l'infobulle de la vue Profit, dans la fenêtre de COC. Clé neuve
  `Writ d'artisan : +%d` (en/de/es).

## Critères d'acceptation

**Mesures préalables, avant tout code :**

0. [humain] Sur un personnage qui a deux métiers de fabrication, les writs reçus (ou ce que donne un
   « Sealed Craftsman's Writ ») viennent-ils des cinq métiers, ou seulement des siens ? Le guide ACA
   le dit peut-être, sans se connecter. **Seulement des siens : la spec s'arrête (D1).**
   → **Tenu le 2026-10-16** (vu par le user) : un personnage enchanteur et forgeron a reçu un writ
   d'Alchimie.
1. [humain] Deux comptes. A ouvre un writ (quête acceptée, objectif à 0/N : c'est le témoin). B
   fabrique l'objet demandé et le donne à A par l'échange. L'objectif de A passe à N/N, et A rend la
   quête au PNJ. Noter le PNJ et l'endroit. **Si ça échoue, la spec s'arrête (D1).**
   → **Tenu le 2026-10-16** (vu par le user), sous une autre forme : la potion du writ achetée à
   l'hôtel des ventes a été acceptée. L'objet n'a donc pas à être fabriqué par le porteur. L'essai à
   deux comptes reviendra avec le critère 10 ; le PNJ et l'endroit restent à noter.
2. [humain] Sur un client en français, l'infobulle d'un writ pas encore ouvert : quelles lignes,
   l'objet est-il nommé, est-ce un lien ? Et la même chose pour la quête acceptée, dans le journal du
   jeu.
   → **Tenu le 2026-10-17** (captures du user, client **anglais**) : l'infobulle du writ dit
   « Craftsman's Writ: Crafted Solid Shot », « Journeyman », « This Item Begins a Quest »,
   « Requires Level 10 » et un texte d'ambiance ; l'objet n'est nommé que dans le nom du writ, sans
   lien. La quête acceptée se range sous l'en-tête « Crafting », niveau 60, objectif
   « 0/200 Crafted Solid Shot ». Le client français n'a pas été vu : sans effet, tout passe par les
   identifiants.

**Une fois codé :**

3. [test] Chacun des 150 writs donne sa quête, son objet demandé et son palier ; un identifiant
   inconnu donne `nil` sans erreur. → `tests/test_writs.lua`
4. [test] « Qui sait le faire » pour un writ : moi, puis un reroll, puis l'annuaire (en ligne
   d'abord), avec les comptes ; aucune recette connue donne « personne de connu » ; un objet absent de
   CraftLink ne donne aucune ligne. → même fichier
5. [test] Un writ en sac puis la même quête acceptée comptent pour un seul ; une quête acceptée dit
   ce qui manque (50/200 → 150) et ne marque plus rien à 200/200 ; un writ pas encore ouvert garde
   une quantité inconnue, même avec l'objet en sac. → même fichier
6. [test] Choisir l'objet d'un writ dans l'onglet Commande sélectionne le bon plan, la quantité qui
   manque (ou rien de pré-rempli pour un writ pas ouvert, D6), le titre pré-rempli, et **ne poste
   rien** tant que « Poster » n'est pas cliqué. → même fichier
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

**La vue Profit (2026-11-09) :**

12. [test] La marque d'un objet : aucun writ → rien ; un writ que je ne porte pas → son entrée, `held`
    faux ; un writ porté → `held` vrai et ce qui manque ; les deux objets d'un homonyme portent la
    même marque ; un identifiant inconnu → rien, sans erreur. → `tests/test_writs.lua`
13. [test] Le relevé : une quête de writ acceptée retient quantité, or et niveau ; un deuxième relevé
    différent garde le dernier, le plus petit et le plus grand ; un objectif vide ou une
    quête qui n'est pas un writ ne retient rien ; l'or versé au rendu est gardé à part, avec son
    niveau, sans inventer de quantité ; un 0 relu n'efface pas l'or vu ; aucune ligne de chat.
    → même fichier
14. [humain] Fenêtre d'Ingénierie (ou un des cinq métiers), vue Profit : une recette demandée par un
    writ porte l'icône ; son infobulle dit le palier, la réputation et, Auctionator ayant scanné les
    writs, le prix du writ. Témoin : une recette de la même vue que personne ne demande, sans icône.
15. [humain] Ouvrir un writ (quête acceptée), puis revoir la même recette : l'icône est pleine,
    l'infobulle dit ce qu'il manque et « vu en jeu : N ». Après `/reload`, le relevé est toujours là.
    Rendre la quête, or du personnage noté avant et après : l'écart = « Or reçu au rendu ».
16. [agent] `api-gotcha-reviewer` sur l'enregistreur (`QUEST_ACCEPTED`, `QUEST_TURNED_IN`,
    `GetQuestLogRewardMoney`) ;
    `/console taintLog 1` et une infobulle de la vue Profit survolée : rien de COC dans `taint.log`.

**L'infobulle de l'objet (2026-11-11, D10) :**

17. [test] L'accroche : un objet qu'aucun writ ne demande → aucune ligne, et aucune lecture du sac ;
    tout objet de writ (porté ou non, quête remplie, homonyme) → UNE ligne, « Writ d'artisan : +75 »
    (+125 pour un Expert), rien de plus (D11) ; le lien du chat reçoit la ligne, une infobulle de
    comparaison reste nue ; une ligne de la vue Profit ne
    reçoit pas de doublon ; un identifiant secret (vraie secrète d'Elune) → rien, sans lever ; un
    survol ne lit que le writ de l'objet ; `ItemMark` dit la même chose que la marque de la vue Profit,
    pour chacun des objets. → `tests/test_writs.lua`
18. [humain] Survol de l'Iridescent Hammer (writ 264022, Journeyman) dans un sac : sous les lignes du
    jeu, une seule ligne, « Craftsman's Writ: +75 » ; le même objet en lien dans le chat, cliqué : la
    même ligne. Témoin : un objet ordinaire du même sac, sans ligne COC. Vue Profit d'un métier qui
    fait un objet de writ : ses lignes de writ (avec ce qui manque) n'y sont qu'**une** fois.
19. [agent] `api-gotcha-reviewer` sur l'accroche ; en jeu, `/console taintLog 1` et un objet de writ
    survolé en combat : rien de COC dans `Logs\taint.log`.

## Contrat

Rien sur le réseau (voir « Ce qu'on ne fait pas »). Une table neuve dans les SavedVariables :
`db.writsSeen` (par compte, créée à l'usage, sans palier de migration) :
`[quête] = { n = dernière quantité, nMin, nMax, money = or annoncé par le journal (cuivre), level =
niveau du perso qui l'a vu, paid = or versé au rendu, paidLevel, rewardItem = premier objet de
récompense (la Coin Pouch), rewardCount, at = time() }`. Pas de compteur de
relevés : la même quête est relue à chaque connexion tant qu'elle reste au journal, il compterait
des lectures, pas des writs. Un `money` à 0 relu plus tard n'efface pas un montant déjà vu, ni une
relecture sans objet l'objet déjà vu. **L'infobulle de la vue Profit n'affiche pas un or à 0** (un writ
paie en Coin Pouch : « 0c » se lirait « ne rapporte rien ») ; elle affiche « Reward: Coin Pouch ».
T7 (coût de la réputation) aura besoin de l'or qui SORT de la bourse à l'ouverture : pas encore relevé.

- **La table générée** (`CraftingOrderClassic_Writs_Data.lua`, par `tools/gen_writs.lua`), interne à
  COC : `[writ] = { quête, palier, objet demandé [, autre objet du même nom] }`, palier 1 Journeyman,
  2 Expert, 3 Artisan. Elle porte en tête la page source et la date de sa génération, pour qu'on
  sache quand la refaire. Le métier n'y est pas : un objet peut en avoir deux (Gordok Ogre Suit), il
  se déduit en jeu (`Orders:ProfForItem`).
- **La lecture** (`COC.Writs`, entrées partagées, à lire seulement) : `Info(writ)` et
  `ForQuest(quête)` rendent `{ writ, quest, tier, rep, items }` ou `nil` ; `All()` pour parcourir.
  `WhoCanMake(entrée)` rend `{ recipes, me, alts, crafters, online }` (moi, mes rerolls par leur
  nom, les autres artisans de l'annuaire en ligne d'abord), ou `nil` si aucun objet de l'entrée
  n'est connu de CraftLink. `Held()` rend les writs portés, un par writ
  (`{ entry, inBag, onQuest, done, required, have, need }`, les trois quantités seulement pour une
  quête acceptée), et `WantedItems()` les objets encore à commander (objet → son writ porté).
  `ForItem(objet)` rend les entrées dont la quête demande cet objet (liste, souvent une seule) ;
  `ProfitMark(objet, wanted)` rend `{ entry, held, need, seen }` ou `nil` (`wanted` = le résultat de
  `WantedItems()`, lu une fois par remplissage de la vue) ; `ItemMark(objet)` rend la même marque
  sans `wanted`, en ne lisant que les writs de cet objet (l'infobulle, D10) ; `Seen(quête)` rend le
  relevé ou `nil`.
- **Le relevé** (`CraftingOrderClassic_Writs_Seen.lua`) : `Learn(quête)` lit l'objectif et l'or dans
  le journal et écrit `db.writsSeen` ; il ne touche ni à `Held()` ni à `WantedItems()`, qui restent
  sans effet de bord.

## Questions ouvertes

- **Pour le user** : faut-il aussi la quête du writ dans le **journal COC** (bouton « Commander » sur
  sa fiche), dès ce premier tour ? (D4)
- **À voir en jeu** : le montant de l'or, s'il change avec le niveau ; une même quête demande-t-elle
  toujours la même quantité ; y a-t-il un plafond de writs par jour.
- **Pages Wowhead à enregistrer** (en anglais, extension `tools\wowhead-page`), plus urgentes : le
  guide « Azeroth Commerce Authority Reputation Guide » (PNJ, remise, d'où viennent les enveloppes,
  noms des deux factions) ; l'objet 284584.

## Liens

- Mémoire de l'analyse : `coc-writs-caisses-aca` (mémoire de session, `.claude\memoire`).
- `CraftingOrderClassic_JournalQuests.lua` : la lecture du journal de quêtes du jeu, et ses deux
  pièges (sélection partagée, en-têtes repliés).
- `CraftingOrderClassic_QuestSheet.lua` : le titre et le récit d'une commande.
- Skills : `wow-addon-dev:wow-forever-api` (infobulles et journal de quêtes sur Forever),
  `wow-addon-dev:chat-output`, `coc-native-ui` (onglet Commande), `craftlink-data-pipeline` (noms
  anglais canoniques).

## Plan (2026-10-16)

Une tâche par séance, chacune avec ses critères. Les deux branches `feat/writs-aca` (COC et
outillage, pour `tests/test_writs.lua`) atterrissent le même jour.

- **T1 — la table et sa lecture** : le générateur (`tools/gen_writs.lua`, page de recherche Wowhead
  en argument), le fichier de données généré, le module qui le lit (writ → quête, objet, palier ;
  quête → writ). Critère 3. **Fait le 2026-10-16.**
- **T2 — « qui sait le faire »**, et un writ compté une seule fois entre le sac et le journal.
  Critères 4 et 5. **Fait le 2026-10-16** : la quête se lit par son identifiant
  (`C_QuestLog.IsOnQuest` / `IsComplete`, présentes dans la doc de l'interface de Forever ; jamais
  appelées en jeu par COC jusqu'ici, à voir au premier test en jeu). **Corrigé le 2026-10-17** : les
  quantités viennent de l'objectif (`C_QuestLog.GetQuestObjectives`, même statut), « l'objet en sac »
  ne vaut plus « rempli ».
- **T3 — l'infobulle**, après le critère 2. Critères 9 et 11.
- **T4 — l'onglet Commande**, après validation de D4 par le user. Critères 6, 7 et 10.
- **T5 — la marque dans la vue Profit** (2026-11-09). Critères 12, 14 et 16.
- **T6 — le relevé en jeu** de la quantité et de l'or (2026-11-09). Critères 13, 15 et 16.
- **T7 — le coût de la réputation**, quand le relevé aura des chiffres. Critères à écrire alors.
- **T8 — la marque dans l'infobulle de l'objet** (2026-11-11, D10). Critères 17, 18 et 19. **Codé
  le 2026-11-11** sur `feat/writs-infobulle` (`CraftingOrderClassic_Writs_Tooltip.lua`,
  `W:ItemMark`) : critère 17 tenu en test, jamais vu en jeu.
