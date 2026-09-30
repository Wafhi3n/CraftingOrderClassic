# Annoncer une commande en clair sur Commerce

> État : **validée** le 2026-09-29 par le user · Idée du user, mise en forme par l'agent · Mesures
> préalables faites le 2026-09-29 (Critères 1 à 4 : tenus) · Implémentation : palier 1 (le format,
> `Orders_Announce.lua`, `tests/test_announce.lua`) et palier 2 (l'envoi, `Orders_AnnounceSend.lua` :
> case du formulaire, clic droit du Carnet ; `tests/test_announce_send.lua`) faits le 2026-09-29 ;
> palier 3 (la lecture, `Orders_AnnounceRecv.lua`, lignes WTB **et** LFW ; `tests/test_announce_recv.lua`)
> fait le 2026-09-29. Critères 5 à 10 et la lecture du 12 tenus en test ; **11 tenu en jeu le
> 2026-09-30 00:19** (registre de vérification : témoin sans la case invisible pour Gnomi, `#CO6` lu,
> bonjour, commande complète à la place de l'aperçu, une seule alerte). Palier 4 (l'envoi de la ligne
> LFW, `AnnounceSend:PostLFW`, case dans le panneau « Offre ») fait le 2026-09-30, tenu en test ; **13
> tenu en jeu le 2026-09-30 00:31**. Reste le palier 5 (relectures, critère 15).

## Le problème

Sur WoW: Forever, Crafting Order n'a plus de canal général : CraftLinkNet est découpé en salles
(2026-09-27), et depuis la v1.37.0 une commande part en chuchotement vers les porteurs **connus** —
membres de la communauté, amis, guilde, et depuis `feat/salle-decouverte` ceux de la même salle.
Un porteur de l'addon qui n'est dans aucun de ces cercles ne voit jamais la commande. Un joueur SANS
l'addon non plus, alors qu'il pourrait très bien la faire.

Le banc des constats (`docs/constats-api.md` de l'outillage, 2026-09-29) a fermé toutes les autres
voies globales : un message d'addon est avalé sur un fil de communauté (C1) comme sur les canaux du
jeu (C13), crier est refusé (C9), le texte d'une communauté est opaque (C3, C10). Reste Commerce, qui
se **lit en clair** : le scanner de COC (`CraftingOrderClassic_Inbound.lua`) y repère déjà les
« WTB [objet] » des joueurs sans l'addon, et c'est prouvé sur Forever (faux positif du 2026-09-27).

## Ce qu'on veut

Au moment de poster une commande **publique**, le joueur peut cocher « Annoncer en Commerce ». L'addon
écrit alors UNE ligne sur Commerce, celle qu'un joueur taperait lui-même, avec des jetons que l'addon
sait relire :

```
WTB [Enchant Cloak - Minor Protection] x1 PROVIDE [Lesser Magic Essence]x1 [Strange Dust]x2 2g50s #CO27
```

- **Un joueur sans l'addon** lit une demande ordinaire, clique les liens, et chuchote l'auteur.
- **Un porteur de l'addon** la voit arriver dans ses Entrantes, avec le métier et la commission, comme
  une demande relevée par le scanner. L'étiquette `#CO27` lui dit que c'est une commande du réseau :
  son addon dit bonjour à l'auteur (chuchotement), l'auteur le découvre, et la commande complète lui
  arrive par le relais qui existe déjà (`Orders:OnArtisanOnline`). À partir de là c'est une commande
  COC ordinaire : accepter, remettre, confirmer passent en chuchotement, comme aujourd'hui.

Commerce sert donc à **deux choses à la fois** : une annonce lisible par tous, et une balise de
découverte pour les porteurs. Les données, elles, ne quittent pas le chuchotement.

**L'artisan s'annonce de la même façon, en plus court** (idée du user) :

```
LFW Enchanting/Tailoring #CO
```

- Un joueur sans l'addon lit « je cherche du travail en Enchantement et Couture » et chuchote l'auteur.
- Un porteur de l'addon lui dit bonjour (chuchotement) ; en réponse, l'addon de l'auteur renvoie
  déjà son profil et sa dispo (`Dir:OnHello` → `LFWRiposte`). La suite se fait au chuchotement : ses
  métiers et niveaux, et les commandes qui le concernent (relais `Orders:OnArtisanOnline`).

Conséquence voulue : la communauté devient **recommandée, plus indispensable**. Elle garde ce que
Commerce ne donne pas (l'annuaire hors ligne et les notes de membre, la présence, les destinataires
des commandes nommées), mais un joueur hors communauté voit et est vu dès qu'il est en ville.

## Ce qu'on NE fait PAS

- **Aucun envoi automatique sur Commerce.** Chaque ligne part d'un clic du joueur (le jeu l'exige :
  un événement matériel), jamais d'une minuterie, d'un relais ou d'une reprise. Pas de re-diffusion
  périodique : au mieux un bouton « Rappeler » (voir Décisions).
- **Pas le protocole.** Accepter, remettre, confirmer, annuler, relayer, échanger les profils restent
  en chuchotement : ils visent une personne, ils partent sans clic, et Commerce n'est pas à nous.
- **Pas de commande privée.** Une commande nommée, de guilde ou d'amis ne s'annonce jamais sur
  Commerce.
- **Pas d'annulation sur Commerce.** L'annulation part en chuchotement vers ceux qui connaissent la
  commande ; chez les autres, l'entrée tirée de la ligne expire seule (EXPIRY du scanner, 30 min).
- **Pas de code illisible.** Pas d'identifiant d'objet nu, pas de base64 : si un humain ne comprend
  pas la ligne, elle n'a rien à faire sur un canal public.
- **Pas de commande « par pile »** dans la ligne : la quantité s'écrit en unités.

## Cas particuliers

- **Hors d'une ville** : pas de canal Commerce, la case est grisée (et dit pourquoi).
- **Ligne trop longue** (le chat coupe à 255 octets, liens compris) : les matériaux en trop tombent,
  remplacés par `+N` (« et N autres ») ; la commande complète arrive de toute façon par chuchotement.
- **Débit** : le serveur bloque vite (3ᵉ message en 10 s sur un canal = refus, relevé du 2026-09-29).
  Un refus s'affiche au joueur ; l'addon ne réessaie pas tout seul.
- **Ma propre ligne** me revient (écho) : ignorée.
- **Auteur muté** (modération de COC) : ligne ignorée, comme ses commandes.
- **Auteur d'un autre royaume non connecté** : ignoré (même confinement que le réseau).
- **Ligne au format imité par un joueur** : sans importance. L'acheteur est l'AUTEUR de la ligne, que
  le serveur authentifie ; personne ne peut annoncer au nom d'un autre, ni fabriquer l'identifiant
  d'une commande qui n'est pas la sienne (l'id se reconstruit : `<auteur>-<n>`).
- **Ligne sans `#CO`** : c'est une demande humaine ; le scanner la traite comme aujourd'hui.
- **La même commande vue deux fois** (ligne + chuchotement) : une seule entrée, l'id fait foi ; la
  commande complète remplace l'aperçu tiré de la ligne.
- **Combat, instance** : le texte du chat peut être masqué par le jeu ; rien n'est lu, rien ne casse.

## Décisions

- 2026-09-29, **user** : un format à jetons en clair sur Commerce comme voie globale (« WTB XXX
  PROVIDE YYY:1 ZZZ:2 2PO50 »).
- 2026-09-29, **user** : l'artisan s'annonce d'une ligne « LFW Enchanting/Tailoring », la suite se fait
  au chuchotement.
- 2026-09-29, **user** : la ligne LFW porte l'étiquette **`#CO`** (sans elle, l'addon dirait bonjour à
  tout « LFW » de Commerce, pour rien chez ceux qui ne l'ont pas).
- 2026-09-29, agent : l'annonce LFW part de la même case « Annoncer en Commerce », au moment où
  l'artisan active sa dispo — jamais au renouvellement automatique de la dispo.
- 2026-09-29, agent, accepté par le user avec la validation : Commerce porte les annonces publiques
  et sert de balise ; le protocole reste en chuchotement (clic obligatoire, espace public, ville
  seulement, rien de persistant).
- 2026-09-29, **user** : le canal est **Trade (Services)**, celui des services d'artisans. Mesuré le
  même soir : il relie toutes les capitales (Stormwind, Ironforge, Darnassus), comme Trade.
- 2026-09-29, **user** : la case « Annoncer en Commerce » est **décochée au départ, et le dernier
  choix du joueur est retenu**.
- 2026-09-29, **user** : un bouton **« Rappeler »** ré-annonce une commande encore ouverte, **au plus
  une fois par 15 minutes** et par commande. Jamais de rappel automatique.
- 2026-09-29, agent (non contesté à la validation) : jetons fixes en anglais (`WTB`, `PROVIDE`, `LFW`,
  prix en `g`/`s`/`c`), quel que soit le client — le jargon commun de Commerce. Le lecteur accepte
  aussi `po`/`pa`/`pc`, `:N` et `×N` (le scanner lit déjà « 2g50s » en 2 po 50 pa).
- 2026-09-29, agent (palier 3) : une annonce `WTB` n'est lue que si le scanner l'aurait gardée —
  portée `/co scan` (« mine » = un métier que j'ai, « all » = tout, « off » = rien). Sinon ni aperçu
  ni bonjour : chaque porteur en ville qui lit la ligne chuchote l'auteur, inutile d'y ajouter ceux
  que la commande ne concerne pas. La ligne `LFW … #CO`, elle, reçoit toujours son bonjour (hors
  « off ») : un artisan disponible intéresse tout acheteur.
- 2026-09-29, agent (palier 3) : une commande d'**enchantement** annoncée ne pose **pas d'aperçu**
  dans les Entrantes (elles montrent un objet, un enchantement n'en a pas) ; le bonjour part, et la
  commande complète arrive par chuchotement. L'aperçu d'un objet, lui, sonne comme une entrante ; la
  commande complète qui le remplace ne sonne pas une seconde fois. Un aperçu n'est jamais « gardé
  pour un ami capable » (Handoff) : l'auteur a l'addon, la vraie commande suit par le relais.
- 2026-09-30, agent (relectures du palier 5) :
  - la ligne LFW ne part QUE du clic ou de `/co lfw` tapé : `LFWCmd` était aussi appelée par le
    scanner du chat sur ma propre ligne « LFW … », donc depuis un événement (défaut corrigé, test
    `test_announce_lfw_echo.lua`) ; l'écho de ma ligne `#CO` est ignoré par ce scanner ;
  - une commande annoncée compte UNE fois pour l'anti-spam (l'aperçu ; la commande complète qui le
    remplace ne recompte pas) ; un aperçu écarté par le joueur ne fait pas sonner la commande complète ;
  - le bonjour se tait si l'auteur est déjà en contact, et s'étale sur 0 à 5 s (chaque porteur en
    ville lit la même ligne) ; `#CO0005` vaut `#CO5` ; les lecteurs du chat public écartent une
    valeur secrète ;
  - limites connues, laissées : un aperçu dont l'auteur me croit déjà en ligne (commande manquée)
    n'est pas complété et expire en 30 min ; une annulation ne touche pas un aperçu jamais complété
    (l'auteur ne sait pas que je l'ai vu) ; « Accepter » sur un aperçu reste local et se perd quand la
    commande complète arrive ; un « Rappeler » ré-alerte tant que l'aperçu vit ; royaumes connectés :
    le bonjour vise le nom sans royaume, comme tout le réseau.
- 2026-09-30, **user** : les matériaux de `PROVIDE` restent des **liens** (cliquables), en sachant
  qu'un client d'avant cette fonctionnalité (≤ v1.39.1) lit la ligne comme une demande humaine et prend
  chaque lien pour un objet demandé : s'il a le métier d'un matériau fourni, il voit une fausse
  entrante pour ce matériau (et peut la « garder pour un ami capable »), jusqu'à sa mise à jour.
  Écartés : les noms en texte (pas cliquables, dans la langue de l'auteur) et la ligne sans `PROVIDE`.

- 2026-09-30, **user** (maquette « destinataire », piste 2) : la case du formulaire vit **dans la
  ligne « Tous »** de la liste des destinataires, plus en bas de la fenêtre. Elle est grisée pour
  tout autre destinataire et hors d'une capitale (libellé « (en capitale) »), sans effacer le choix
  retenu ; « Poster » n'annonce que pour « Tous ». Le rappel du bas dit « Tous + Commerce ». La case
  de l'offre « Chercher du travail » ne change pas.

## Critères d'acceptation

Mesures préalables (sonde `/cocprobe annonce [services|local]`, avant tout code) — **tenues le
2026-09-29 (22:16-22:19, build 70058)** :

1. [humain] L'addon peut écrire sur Commerce depuis une commande tapée : la ligne s'affiche dans le
   chat des deux comptes. Témoin connu-bon : la même ligne tapée à la main. Observateur : le user.
   → **Tenu** : vu par le user sur Trade et Trade (Services) ; aucun blocage relevé.
2. [agent] Une ligne à trois liens tient sous 255 octets (`COCProbeDB.tradePost.bytes`).
   → **Tenu** : 218 octets (les liens de Forever sont courts : `|cnIQ1:|Hitem:…`). Un 4ᵉ lien dépasse.
3. [humain] Portée : une ligne postée à Ironforge est lue à Stormwind (Trade, puis Services).
   → **Tenu** : les deux canaux relient toutes les capitales (Stormwind, Ironforge, Darnassus).
4. [humain] Le scanner de Gnomi (`/co scan all`) range la ligne de Rédemption dans ses Entrantes.
   → **Tenu** (relevé dans la SavedVariable de Gnomi) : Entrante « Linen Bandage », métier First Aid
   déduit, x1, commission lue « 2po 50pa ».

Fonctionnalité :

5. [test] La ligne produite pour une commande suit exactement la grammaire du § Contrat, et relue
   elle rend le même objet, la même quantité, les mêmes matériaux, la même commission et l'id.
6. [test] Trop longue, elle coupe les matériaux en trop et finit par `+N` ; jamais au-delà de 255 octets.
7. [test] Une commande nommée, de guilde ou d'amis ne produit aucune ligne.
8. [test] Une ligne `#CO` reçue : entrée unique, auteur = acheteur, id = `<auteur>-<n>`, et un bonjour
   chuchoté à l'auteur ; la commande complète reçue ensuite remplace l'entrée, sans doublon.
9. [test] Écho de soi, auteur muté, auteur d'un royaume non connecté : rien.
10. [test] Deux annonces en moins d'une minute : la seconde est refusée par l'addon, avec un message.
11. [humain] Rédemption poste une commande publique en cochant la case : la ligne apparaît sur
    Commerce, lisible ; Gnomi (hors communauté, `/co circle 1` pour la démarquer) voit la commande
    dans ses Entrantes, puis, quelques secondes après, comme une vraie commande qu'il peut accepter.
    Témoin connu-bon : la même commande sans la case, que Gnomi ne voit pas hors communauté.
    → **Tenu** le 2026-09-30 00:19. Sur ce banc, « hors communauté » ne suffit pas : à la connexion,
    chaque compte chuchote aux 30 pairs vus le plus récemment, l'autre compris ; il faut d'abord les
    rendre étrangers (`Directory.roster[n]` et `.online[n]` à nil, de chaque côté, sans relog).
12. [test] « LFW Enchanting/Tailoring #CO » reçu : un bonjour chuchoté à l'auteur, aucune commande
    créée ; les noms de métier se lisent aussi en français, allemand, espagnol. Sans `#CO` : rien.
13. [humain] Rédemption active sa dispo en cochant la case : la ligne LFW apparaît sur Commerce ;
    Gnomi (hors communauté) voit Rédemption passer « [Dispo] » dans l'onglet Artisans, avec ses
    métiers, quelques secondes après. Témoin connu-bon : la dispo sans la case, invisible pour Gnomi.
    → **Tenu** le 2026-09-30 00:31 (mêmes précautions d'isolement que le 11).
14. [porte] Toute chaîne d'interface nouvelle est traduite (`check_locale.ps1`).
15. [agent] Aucun envoi sur Commerce hors d'un clic (`api-gotcha-reviewer`), et relecture du
    protocole (`craftlink-protocol-reviewer`) avant fusion.

## Contrat

La ligne est un **format public** : une fois publiée, des clients déployés la liront. Toute évolution
reste lisible par l'ancien lecteur (on ajoute en fin de ligne, on ne réordonne pas).

```
annonce  := "WTB " cible [" x" qté] [" PROVIDE " mat {" " mat} [" +" N]] [" " prix] " #CO" n
cible    := lien d'objet | lien d'enchantement          (|Hitem:… ou |Henchant:…)
mat      := lien d'objet [("x" | ":" | "×") qté]           (qté inconnue : le lien seul)
prix     := [N "g"] [N "s"] [N "c"]                       lecteur : aussi « po » « pa » « pc »
n        := entier ; id de la commande = <nom réseau de l'auteur> "-" n

dispo    := "LFW " métier {"/" métier} " #CO"
métier   := nom anglais du métier (Enchanting, Tailoring…)  lecteur : aussi FR/DE/ES (ResolveProfession)
```

- Écrit toujours dans cet ordre ; le lecteur tolère les espaces multiples et la casse des mots-clés.
- `#CO` sans `n` : balise de découverte seule, sans commande (la ligne « LFW »).
- Maximum 255 octets, liens compris.

## Plan (2026-09-29) — volatile, meurt quand c'est fait

Branches homonymes `feat/annonce-commerce` (COC + outillage pour les tests). S'appuie sur la salle
de découverte (`feat/salle-decouverte`) seulement pour le bonjour ; le reste est indépendant.

1. **Le format**, pur et testé sans jeu : fabriquer la ligne d'une commande (ordre des jetons, prix
   en g/s/c, coupe à 255 octets avec `+N`, rien pour une commande privée) et relire une ligne `WTB …
   #CO<n>` ou `LFW … #CO`. Critères 5, 6, 7, et la lecture de 12.
2. **L'envoi** : la case dans le formulaire de commande (choix retenu), la ligne sur Trade (Services)
   au clic « Poster », le délai d'une minute entre deux annonces, « Rappeler » (15 min par commande),
   les messages hors ville ou sur refus du jeu. Critères 10, 14, et l'envoi de 11.
3. **La réception** : une ligne `#CO` devient une Entrante d'id `<auteur>-<n>`, l'addon dit bonjour à
   l'auteur, la commande complète la remplace sans doublon ; écho, muté, autre royaume : rien.
   Critères 8, 9, 11.
   → **Fait** (avec la lecture de la ligne LFW, avancée depuis le palier 4).
4. **La dispo LFW** : la case dans l'onglet de dispo, la ligne `LFW … #CO`. Critère 13 (le 12 est
   tenu en test depuis le palier 3).
   → **Fait** : la case vit dans le panneau « Offre » de la bande « Chercher du travail » (même
   réglage que celle du formulaire, qui se relit à chaque affichage) ; la ligne part du clic qui
   active la dispo (bande, bouton de la vue pleine, `/co lfw <métier>`), avec le métier activé —
   la dispo n'en porte qu'un. Même délai d'une minute que les commandes, un seul compteur.
5. **Relectures** avant fusion : `api-gotcha-reviewer`, `craftlink-protocol-reviewer` (critère 15),
   puis `spec-updater` sur le diff.

## Renvois

- `docs/specs/communaute-sans-canal.md` (le réseau en chuchotement, la communauté comme annuaire).
- Outillage : `docs/constats-api.md` (C1, C3, C9, C10, C13 : pourquoi Commerce), banc des constats.
- `CraftingOrderClassic_Inbound.lua` (le scanner de Commerce, sa grammaire « WTB » et son EXPIRY).
- Skills `wow-classic-addon-dev` (événement matériel, taint), `coc-native-ui` (la case du formulaire).
