# Annoncer une commande de guilde sur le salon Discord de la guilde

> État : **brouillon** du 2026-10-10 · Demande du user, mise en forme par l'agent · Décisions D1 à D3
> prises par le user le 2026-10-10 ; D4 à D6 **proposées, à trancher** ; mesures M1 et M2 à faire
> avant tout code. Rien d'implémenté. Contrat vérifié le 2026-10-10 : `Announce.Parse` de `main`
> (`15bda9d`) relit une ligne avec `@Prénom Nom` avant `#CO27` comme la ligne de Commerce (même id,
> objet, quantité, matériaux, prix).

## Le problème

Depuis la bêta de WoW: Forever, une guilde peut relier son chat à **un** salon d'un serveur Discord
(mesuré le 2026-10-10, build 70338, guilde de test « Ost Ardent » reliée au salon
« canal-de-guide-ig »). Les guildiens qui lisent ce salon depuis Discord, sur leur téléphone ou hors
du jeu, voient le chat de guilde, mais **jamais une commande de COC**.

Une commande en portée « Guilde » part en messages d'addon (canal de guilde de CraftLink et
chuchotements). Ces messages sont invisibles des humains et ne passent pas le pont Discord. Le
guildien sur Discord, ou en jeu sans l'addon, ne sait pas qu'un membre cherche un artisan.

## Ce qu'on veut

Quand un joueur poste une commande **publique en portée « Guilde »**, COC écrit **en plus**, dans
le même clic, la ligne `WTB` de cette commande dans le canal Discord de sa guilde. C'est la ligne
de Commerce, à laquelle s'ajoute le nom du personnage.

- **Flux mêlé** (réglage par défaut de la guilde) : la ligne part dans le chat de guilde. Le jeu la
  recopie sur Discord, et les guildiens en jeu la voient aussi dans leur chat de guilde.
- **Flux séparé** (case « Separate Discord chat from Guild chat ») : la ligne part dans le fil
  « Discord » de la guilde, **si la mesure M1 montre qu'un addon peut y écrire**. Sinon, rien ne part
  en flux séparé, et ce n'est pas un défaut.
- Un guildien qui a COC et lit cette ligne dans son chat de guilde **ne reçoit pas la commande en
  double**. La ligne est reconnue comme une annonce (`#CO`) : une commande déjà reçue ne fait rien,
  une commande inconnue donne un aperçu et un bonjour, comme sur Commerce.

## Ce qu'on NE fait PAS

- **La dispo LFW et le suivi d'une commande** (prise, livrée, annulée) sur Discord : D1, seules les
  commandes y vont.
- **Lire Discord.** Le texte d'une ligne écrite sur Discord arrive dans le jeu en référence opaque
  (`|Kx1|k`, mesuré) : un addon ne peut pas le lire. Une demande tapée sur Discord ne deviendra
  jamais une Entrante.
- **Choisir le salon, en viser plusieurs, ou créer le lien.** Une guilde a **un seul** salon,
  choisi par son chef dans l'interface de Blizzard, et Discord n'accepte un salon que pour une
  guilde. Un addon ne peut même pas lire quel salon : `C_Discord.GetGuildLinkStatus` est protégée
  (bloquée 6 fois sur 6 le 2026-10-10).
- **Retraduire les liens côté Discord.** Un lien d'objet y devient du texte (`[Linen Bandage]`).
  Un bot pourrait en refaire des liens : idée du user, projet séparé.
- **Les autres portées.** « Tous » a déjà Commerce, « Amis » et une personne restent privées : pas
  de ligne Discord.
- **Le rappel et l'envoi automatique.** La ligne ne part qu'au clic « Poster ». Jamais au
  renouvellement (`TTL`), à une rediffusion ni au rejeu d'une commande.

## Cas particuliers

- **Guilde non reliée à Discord** : en flux mêlé, la ligne n'apporterait rien et encombrerait le
  chat de guilde du jeu. Ce que COC fait alors est la décision D4, à trancher.
- **Plusieurs commandes de guilde coup sur coup** : le serveur limite le chat, et chaque ligne s'affiche
  chez tous les guildiens. Le délai entre deux lignes est la décision D5, à trancher. Au-delà de ce
  délai, la commande part quand même, sans sa ligne, et le joueur en est prévenu.
- **Objet pas encore connu du jeu** (lien non résolu) : pas de ligne, la commande part, message au
  joueur, comme sur Commerce.
- **Ligne trop longue** : le nom du personnage entre dans les 255 octets. Les matériaux fournis
  cèdent la place d'abord, comme sur Commerce. Une ligne coupée par le jeu perdrait son `#CO` final.
- **Envoi refusé** (instance, verrou du chat en combat de boss, guilde quittée) : la commande part
  quand même, et la ligne est perdue sans popup d'erreur.
- **Joueur sans compte Discord relié** dans une guilde reliée : sa ligne atteint-elle Discord, et
  sous quel nom ? Pas mesuré (il faut un autre compte Battle.net) ; COC écrit dans le chat de guilde
  de toute façon, et le jeu décide.
- **Guildiens avec une version de COC déjà publiée** : ils lisent la ligne de guilde comme une
  demande humaine (`Inbound`) et en font une Entrante en plus de la commande. C'est **mesuré** le
  2026-10-10 (Gnomi : Entrante `Rédemption Wafhien_1251`). C'est le prix de la transition, jusqu'à
  leur mise à jour.
- **Guilde sur deux royaumes** (Gnoma Short, PvE 4618, dans une guilde de PvE 2) : les noms de
  Forever n'ont pas de suffixe de royaume, donc la lecture de la ligne reste la même.
- **Commande annulée ou prise après l'annonce** : la ligne reste sur Discord. Pas de suivi (D1).

## Décisions

- 2026-10-10, **user** (D1) : seules les **commandes (WTB)** vont sur Discord. Ni la dispo LFW ni le
  suivi d'une commande.
- 2026-10-10, **user** (D2) : l'envoi est **automatique pour toute commande publique en portée
  « Guilde »**, dans le clic « Poster ». Pas de case à cocher.
- 2026-10-10, **user** (D3) : COC **suit le réglage de la guilde**. En flux mêlé, il écrit dans le chat
  de guilde ; en flux séparé, dans le fil Discord si M1 montre que c'est possible, et sinon rien.
- **Proposé, à trancher** (D4) : n'écrire **que si la guilde est reliée à Discord**. Pour le savoir,
  COC regarde la liste des fils de la guilde (`C_Club.GetGuildClubId`, `C_Club.GetStreams`, toutes
  deux libres) : un fil de type `Discord` doit y être, si la mesure M2 le confirme en flux mêlé.
  Sans M2, l'indice de secours est d'avoir vu passer, pendant la session, une ligne de guilde
  marquée « venue de Discord » (argument 18, `fromDiscord`). Recommandation de l'agent : D4 avec
  M2, pour ne jamais rien écrire dans une guilde qui n'est pas reliée.
- **Proposé, à trancher** (D5) : **une ligne Discord par minute au plus**, compteur à part de celui de
  Commerce. Au-delà, la commande part sans ligne et le joueur lit pourquoi.
- **Proposé, à trancher** (D6) : la ligne **nomme le personnage**, parce que Discord affiche le
  **compte Discord** de l'auteur et jamais son personnage (mesuré : « Wafhien » pour Rédemption
  comme pour Gnomi). Forme proposée : `@Prénom Nom`, juste avant `#CO<n>`.
- 2026-10-10, mesuré : un salon par guilde, choisi par le chef ; un addon ne peut ni le lire ni le
  changer (fonctions de `C_Discord` protégées, même depuis une commande tapée).

## Mesures avant le code

- **M1, écrire dans le fil Discord.** Un addon peut-il écrire dans le fil « Discord » de la guilde
  (flux séparé) depuis un clic, par `C_Club.SendMessage(guilde, fil Discord, texte)` ? Le constat C8
  (2026-09-18) montre qu'écrire dans une communauté marche depuis un clic. En revanche,
  `SendChatMessage(…, "GUILD_DISCORD")` tapé dans la boîte de chat n'a rien envoyé le 2026-10-10. Il
  faut le mesurer sur la sonde (COCProbe) avant de coder le flux séparé.
- **M2, voir le lien sans appel protégé.** Le fil de type `Discord` existe-t-il dans
  `C_Club.GetStreams` en flux mêlé, et disparaît-il quand le chef délie la guilde ? Si oui, D4 se fait
  sans attendre une ligne Discord.

## Critères d'acceptation

1. [test] La ligne de guilde est la ligne `WTB` de Commerce **inchangée**, plus le nom du personnage
   avant `#CO<n>`. Elle fait 255 octets au plus, nom compris. `Announce.Parse` actuel la relit avec
   le même id, objet, quantité, matériaux et prix. → `tests/test_announce.lua`
2. [test] La ligne de **Commerce** ne change pas : les tests actuels d'`annonce-commerce` passent tels
   quels. → `tests/test_announce.lua`, `tests/test_announce_send.lua`
3. [test] Une commande en portée « Tous », « Amis » ou à une personne n'écrit aucune ligne de guilde.
   Un `TTL`, une rediffusion ou un rejeu non plus. Seul le clic « Poster » d'une commande « Guilde »
   en écrit une.
4. [test] Une ligne `WTB … #CO<n>` lue dans le chat de guilde passe par le lecteur d'annonces :
   commande déjà reçue = rien ; commande inconnue = aperçu et bonjour. Elle ne passe **jamais** par le
   scanner des demandes humaines. → `tests/test_announce_recv.lua`
5. [test] Selon D4 tranché : guilde non reliée = aucune ligne écrite.
6. [test] Selon D5 tranché : une 2ᵉ commande de guilde dans le délai part sans ligne, avec un message
   au joueur.
7. [human] Flux mêlé : Rédemption poste une commande de guilde. Sur Discord apparaît, sous
   « Wafhien » avec le badge manette, `WTB [objet] x1 … @Rédemption Wafhien #CO<n>`.
   Témoin connu bon : la ligne `WTB [Linen Bandage] x1 2g50s #CO0` écrite le 2026-10-10 par la sonde.
   Observateur : le user, sur Discord.
8. [human] Chez Gnomi (COC à jour), la commande arrive **une seule fois** : une alerte, pas d'Entrante
   « WTB » en plus. Témoin : une commande « Tous » du même joueur donne une seule alerte.
   Observateur : le user, compte de Gnomi.
9. [human] Selon M1 : en flux séparé, la ligne apparaît dans le fil « Discord » de la guilde et sur
   Discord ; ou bien rien n'est écrit, sans erreur. Témoin : une ligne tapée à la main dans le fil
   Discord des Communautés, qui marche (vu le 2026-10-10).
10. [human] Le chef délie la guilde, puis poste une commande de guilde : rien n'apparaît dans le chat
    de guilde. Témoin : la même commande, guilde reliée, écrit sa ligne.
11. [agent] Pas d'appel à une fonction protégée de `C_Discord`, pas de `SendChatMessage` hors du clic.
    → `api-gotcha-reviewer`

## Contrat

- **La ligne de guilde** : `WTB <lien de l'objet> x<qté>[ PROVIDE <lien>x<n> …][ +N][ <prix>] @<Prénom
  Nom> #CO<n>`. C'est le format de `Orders_Announce.lua`, plus le jeton `@<nom>` **avant** l'étiquette,
  qui reste en fin de ligne : `Announce.Parse` ancre `#CO<n>` en fin de ligne, et l'analyseur tel
  qu'il est publié relit donc cette ligne sans changement. Le nom n'est ni un lien, ni un prix (un
  nom ne contient pas de chiffre), ni un matériau : `parseWTB` l'ignore.
- **La ligne de Commerce ne change pas.** Le jeton `@<nom>` n'existe que sur la ligne de guilde.
- Une ligne de guilde **lue** suit les règles de lecture d'`annonce-commerce` (id `<auteur>-<n>`,
  l'auteur étant celui du chat), plus une : elle vient de `CHAT_MSG_GUILD` (flux mêlé).

## Plan (2026-10-10) — volatile, meurt quand c'est fait

1. Mesures M1 et M2 sur COCProbe, au banc (le user, Rédemption chef de guilde). Puis trancher D4 à D6.
2. Format : la ligne de guilde dans `Orders_Announce.lua` et ses tests (critères 1, 2).
   ⚠️ `BuildWTB` et `AnnounceSend:WhyNot` refusent aujourd'hui `recipient == "Guilde"` (leur garde
   `isPublic`) : la ligne de guilde a son propre chemin, la règle de Commerce ne change pas.
3. Envoi au clic « Poster », garde D4, délai D5, flux mêlé puis, selon M1, séparé (critères 3, 5, 6).
4. Lecture : `CHAT_MSG_GUILD` qui finit par `#CO` passe d'abord par `Orders_AnnounceRecv` (critère 4).
5. Banc à deux comptes (critères 7 à 10), revue (critère 11).

## Renvois

- `docs/specs/annonce-commerce.md` : le format `#CO`, la lecture, le confinement.
- `docs/specs/canaux-surveilles.md` : la case « Guilde » des canaux surveillés.
- Skill public `wow-addon-dev:wow-forever-api`, `references/chat-channels-and-communities.md`, section
  « Guild chat bridged to a Discord channel ». Les faits du 2026-10-10 y sont sur la branche
  `docs/forever-discord-guild-bridge` de `wow-addon-workspace`, **pas encore fusionnée**.
- Constats C3 et C8 (`docs/constats-api.md` de l'outillage) : contenu opaque des communautés, écriture
  dans une communauté depuis un clic.
- Sonde : `/cocprobe discord [protege|wtb|lfw]` (COCProbe, `COCProbe_Discord.lua`).
