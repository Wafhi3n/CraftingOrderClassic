# Annoncer une commande en clair sur Commerce

> État : **brouillon** · Idée du user le 2026-09-29, mise en forme par l'agent · Décisions ouvertes
> signalées « À TRANCHER ». Mesures préalables en cours (`/cocprobe annonce`, § Critères 1 à 4).

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
- **À TRANCHER — l'étiquette `#CO` sur la ligne LFW** : elle dit aux porteurs « celui-là a l'addon » ;
  sans elle, l'addon dirait bonjour à tout « LFW » de Commerce, pour rien chez ceux qui ne l'ont pas
  (le bonjour est invisible, mais il coûte). Recommandation : la garder, trois caractères.
- **À TRANCHER — ce qui déclenche l'annonce LFW** : la case « Annoncer en Commerce » au moment où
  l'artisan active sa dispo (onglet LFW), jamais le renouvellement automatique de la dispo.
- 2026-09-29, agent, **à valider par le user** : Commerce porte les annonces publiques et sert de
  balise ; le protocole reste en chuchotement (raisons : clic obligatoire, espace public, ville
  seulement, rien de persistant).
- **À TRANCHER — le canal** : Trade (Services), fait pour les services d'artisans, ou Trade (le
  principal, plus fréquenté) ? Recommandation de l'agent : Services si la mesure montre qu'il porte
  aussi loin (Critère 3).
- **À TRANCHER — la langue des jetons** : jetons fixes en anglais (`WTB`, `PROVIDE`, `LFW`, prix en
  `g`/`s`/`c`), quel que soit le client. Recommandation : oui, c'est le jargon commun de Commerce ; le
  lecteur accepte aussi `po`/`pa`/`pc`, `:N` et `×N`.
- **À TRANCHER — la case « Annoncer en Commerce »** : décochée par défaut, et le dernier choix est
  retenu ? Recommandation : oui, c'est un espace public, le joueur choisit.
- **À TRANCHER — « Rappeler »** : un bouton pour ré-annoncer une commande encore ouverte, au plus une
  fois par 15 minutes ? Recommandation : oui, jamais plus.

## Critères d'acceptation

Mesures préalables (sonde `/cocprobe annonce [services|local]`, avant tout code) :

1. [humain] L'addon peut écrire sur Commerce depuis une commande tapée : la ligne s'affiche dans le
   chat des deux comptes. Témoin connu-bon : la même ligne tapée à la main. Observateur : le user.
2. [agent] Une ligne à trois liens tient sous 255 octets (`COCProbeDB.tradePost.bytes`).
3. [humain] Portée : une ligne postée à Ironforge est lue à Stormwind (Trade, puis Services).
4. [humain] Le scanner de Gnomi (`/co scan all`) range la ligne de Rédemption dans ses Entrantes.

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
12. [test] « LFW Enchanting/Tailoring #CO » reçu : un bonjour chuchoté à l'auteur, aucune commande
    créée ; les noms de métier se lisent aussi en français, allemand, espagnol. Sans `#CO` : rien.
13. [humain] Rédemption active sa dispo en cochant la case : la ligne LFW apparaît sur Commerce ;
    Gnomi (hors communauté) voit Rédemption passer « [Dispo] » dans l'onglet Artisans, avec ses
    métiers, quelques secondes après. Témoin connu-bon : la dispo sans la case, invisible pour Gnomi.
14. [porte] Toute chaîne d'interface nouvelle est traduite (`check_locale.ps1`).
15. [agent] Aucun envoi sur Commerce hors d'un clic (`api-gotcha-reviewer`), et relecture du
    protocole (`craftlink-protocol-reviewer`) avant fusion.

## Contrat

La ligne est un **format public** : une fois publiée, des clients déployés la liront. Toute évolution
reste lisible par l'ancien lecteur (on ajoute en fin de ligne, on ne réordonne pas).

```
annonce  := "WTB " cible [" x" qté] [" PROVIDE " mat {" " mat} [" +" N]] [" " prix] " #CO" n
cible    := lien d'objet | lien d'enchantement          (|Hitem:… ou |Henchant:…)
mat      := lien d'objet ("x" | ":" | "×") qté
prix     := [N "g"] [N "s"] [N "c"]                       lecteur : aussi « po » « pa » « pc »
n        := entier ; id de la commande = <nom réseau de l'auteur> "-" n

dispo    := "LFW " métier {"/" métier} " #CO"
métier   := nom anglais du métier (Enchanting, Tailoring…)  lecteur : aussi FR/DE/ES (ResolveProfession)
```

- Écrit toujours dans cet ordre ; le lecteur tolère les espaces multiples et la casse des mots-clés.
- `#CO` sans `n` : balise de découverte seule, sans commande (la ligne « LFW »).
- Maximum 255 octets, liens compris.

## Renvois

- `docs/specs/communaute-sans-canal.md` (le réseau en chuchotement, la communauté comme annuaire).
- Outillage : `docs/constats-api.md` (C1, C3, C9, C10, C13 : pourquoi Commerce), banc des constats.
- `CraftingOrderClassic_Inbound.lua` (le scanner de Commerce, sa grammaire « WTB » et son EXPIRY).
- Skills `wow-classic-addon-dev` (événement matériel, taint), `coc-native-ui` (la case du formulaire).
