# Annoncer une commande de guilde sur le salon Discord de la guilde

> État : **validée** le 2026-10-10 par le user (D1 à D6) · Demande du user, mise en forme par
> l'agent · Mesures M1 et M2 faites au banc le 2026-10-10 à 14:51-14:53 ; D3 revue le même jour sur
> leur résultat (flux séparé seulement). Contrat vérifié : `Announce.Parse` de `main` (`15bda9d`)
> relit une ligne avec `@Prénom Nom` avant `#CO27` comme la ligne de Commerce. **Implémenté** le
> 2026-10-10, branches `feat/annonce-discord` (COC : `Orders_Announce.lua` `BuildDiscordWTB`,
> `Orders_AnnounceSend.lua` `DiscordLineFor`, `Orders_AnnounceDiscord.lua`, appel dans `UI:DoPostOrder` ;
> outillage : `tests/test_announce.lua`, `tests/test_announce_discord.lua`). Critères 1 à 5 tenus en
> test ; **6 à 9 tenus au banc le 2026-10-10 16:23** (GO, registre de vérification, `main-dev@b4df661`) ;
> 10 relu à la main (seul `IsDiscordStreamSeparate` de C_GuildInfo,
> `C_Club.SendMessage` atteignable du seul `DoPostOrder`).

## Le problème

Depuis la bêta de WoW: Forever, une guilde peut relier son chat à **un** salon d'un serveur Discord
(mesuré le 2026-10-10, build 70338, guilde de test « Ost Ardent » reliée au salon
« canal-de-guide-ig »). Les guildiens qui lisent ce salon depuis Discord, sur leur téléphone ou hors
du jeu, voient le chat de guilde, mais **jamais une commande de COC**.

Une commande en portée « Guilde » part en messages d'addon (canal de guilde de CraftLink et
chuchotements). Ces messages sont invisibles des humains et ne passent pas le pont Discord. Le
guildien sur Discord ne sait pas qu'un membre cherche un artisan.

## Ce qu'on veut

Quand un joueur poste une commande **publique en portée « Guilde »**, et que sa guilde est reliée à
Discord **en flux séparé**, COC écrit **en plus**, dans le même clic, la ligne `WTB` de cette
commande dans le **fil « Discord »** de la guilde. C'est la ligne de Commerce, à laquelle s'ajoute le
nom du personnage. Le jeu la recopie dans le salon Discord.

- Le flux séparé, c'est la case « Separate Discord chat from Guild chat » du chef de guilde. La
  guilde a alors un fil « Discord » à elle, distinct du chat de guilde.
- En **flux mêlé**, ou si la guilde n'est pas reliée, COC n'écrit **rien** (D3, D4).
- La ligne ne passe jamais par le chat de guilde ordinaire. Les guildiens en jeu la voient dans le fil
  Discord, s'ils l'ont ouvert ou ajouté à un onglet. COC ne la lit pas : un guildien qui a COC
  reçoit déjà la commande par le réseau, sans doublon, même avec une version déjà publiée.

## Ce qu'on NE fait PAS

- **Le flux mêlé.** Un addon ne peut pas y savoir que la guilde est reliée : aucun fil « Discord »
  n'existe en flux mêlé (M2) et les fonctions de `C_Discord` qui le diraient sont protégées. Écrire à
  l'aveugle mettrait des lignes `WTB` dans le chat de guilde de guildes sans Discord (D3).
- **La dispo LFW et le suivi d'une commande** (prise, livrée, annulée) sur Discord : D1, seules les
  commandes y vont.
- **Lire Discord.** Le texte d'une ligne écrite sur Discord arrive dans le jeu en référence opaque
  (`|Kx1|k`, mesuré) : un addon ne peut pas le lire. Une demande tapée sur Discord ne deviendra
  jamais une Entrante. COC ne lit pas non plus le fil Discord (`CHAT_MSG_GUILD_DISCORD`).
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

- **Guilde en flux mêlé, ou pas reliée** : COC n'écrit rien, sans message (le joueur n'a rien
  demandé de particulier en postant en portée « Guilde »).
- **Plusieurs commandes de guilde coup sur coup** : une ligne par minute au plus (D5). Au-delà, la
  commande part quand même, sans sa ligne, et le joueur en est prévenu.
- **Objet pas encore connu du jeu** (lien non résolu) : pas de ligne, la commande part, message au
  joueur, comme sur Commerce.
- **Ligne trop longue** : le nom du personnage entre dans les 255 octets. Les matériaux fournis
  cèdent la place d'abord, comme sur Commerce. Une ligne coupée par le jeu perdrait son `#CO` final.
- **Envoi refusé** (instance, verrou du chat en combat de boss, guilde quittée) : la commande part
  quand même, et la ligne est perdue sans popup d'erreur.
- **Le chef délie la guilde, ou décoche la case, pendant la session** : COC relit l'état à chaque
  clic « Poster » (D4), jamais une fois pour toutes.
- **Joueur sans compte Discord relié** dans une guilde reliée : sa ligne atteint-elle Discord, et
  sous quel nom ? Pas mesuré (il faut un autre compte Battle.net) ; COC écrit de toute façon, et le
  jeu décide.
- **Guilde sur deux royaumes** (Gnoma Short, PvE 4618, dans une guilde de PvE 2) : rien de
  particulier, la ligne part dans le fil de la guilde.
- **Commande annulée ou prise après l'annonce** : la ligne reste sur Discord. Pas de suivi (D1).

## Décisions

- 2026-10-10, **user** (D1) : seules les **commandes (WTB)** vont sur Discord. Ni la dispo LFW ni le
  suivi d'une commande.
- 2026-10-10, **user** (D2) : l'envoi est **automatique pour toute commande publique en portée
  « Guilde »**, dans le clic « Poster ». Pas de case à cocher.
- 2026-10-10, **user** (D3, revue le même jour après M2) : COC n'écrit **qu'en flux séparé**, dans le
  fil « Discord » de la guilde. En flux mêlé, rien. Remplace « suivre le réglage » (chat de guilde en
  flux mêlé), abandonné parce qu'un addon ne peut pas y savoir que la guilde est reliée.
- 2026-10-10, **user** (D4, sur proposition de l'agent) : n'écrire **que si la guilde est reliée**.
  Reliée en flux séparé = `C_GuildInfo.IsDiscordStreamSeparate()` vrai **et** un fil de type
  `Discord` dans `C_Club.GetStreams(C_Club.GetGuildClubId())` (fonctions libres), relus à chaque clic.
- 2026-10-10, **user** (D5, sur proposition de l'agent) : **une ligne Discord par minute au plus**,
  compteur à part de celui de Commerce. Au-delà, la commande part sans ligne et le joueur lit pourquoi.
- 2026-10-10, **user** (D6, sur proposition de l'agent) : la ligne **nomme le personnage**, parce que
  Discord affiche le **compte Discord** de l'auteur et jamais son personnage (mesuré : « Wafhien »
  pour Rédemption comme pour Gnomi). Forme : `@Prénom Nom`, juste avant `#CO<n>`.
- 2026-10-10, mesuré : un salon par guilde, choisi par le chef ; un addon ne peut ni le lire ni le
  changer (fonctions de `C_Discord` protégées, même depuis une commande tapée).
- 2026-10-10, agent, **confirmé par le user** le même jour : les **commandes de récolte** (onglet
  Récolte) n'ont pas de ligne Discord, comme elles n'ont pas d'annonce sur Commerce. Le joueur est prévenu à chaque ligne
  envoyée (« commande annoncée sur le Discord de la guilde. »), comme sur Commerce.

## Mesures (faites le 2026-10-10, Rédemption chef de guilde, sonde COCProbe)

- **M1, écrire dans le fil Discord : OUI.** Depuis une commande tapée, `C_Club.SendMessage(guilde, fil
  Discord, texte)` à 14:52:02 et `SendChatMessage(texte, "GUILD_DISCORD")` à 14:52:36 sont tous deux
  arrivés sur Discord (sous « Wafhien », badge manette), sans aucun `ADDON_ACTION_*`. Dans le jeu, la
  ligne revient en `CHAT_MSG_GUILD_DISCORD`, avec le nom du personnage et son GUID. Pas encore vu :
  le même envoi depuis un clic de bouton (critère 7).
- **M2, voir le lien : SEULEMENT en flux séparé.** Flux séparé : fils `Guild`, `Discord`, `Officer`.
  Flux mêlé, guilde toujours reliée : `Guild`, `Officer`, plus de fil `Discord`. Pas vu : ce que
  rendent `IsDiscordStreamSeparate()` et les fils après un délien en flux séparé (critère 9).

## Critères d'acceptation

1. [test] La ligne Discord est la ligne `WTB` de Commerce **inchangée**, plus le nom du personnage
   avant `#CO<n>`. Elle fait 255 octets au plus, nom compris. `Announce.Parse` actuel la relit avec
   le même id, objet, quantité, matériaux et prix. → `tests/test_announce.lua`
2. [test] La ligne de **Commerce** ne change pas : les tests actuels d'`annonce-commerce` passent tels
   quels. → `tests/test_announce.lua`, `tests/test_announce_send.lua`
3. [test] Une commande en portée « Tous », « Amis » ou à une personne n'écrit aucune ligne Discord.
   Un `TTL`, une rediffusion ou un rejeu non plus. Seul le clic « Poster » d'une commande « Guilde »
   en écrit une.
4. [test] Garde D4 : sans flux séparé, ou sans fil `Discord` dans la guilde, aucune ligne. Rien n'est
   jamais écrit dans le chat de guilde ordinaire.
5. [test] Une 2ᵉ commande de guilde moins d'une minute après la 1ʳᵉ part sans ligne, avec un message
   au joueur (D5).
6. [human] Flux séparé : Rédemption poste une commande de guilde. Sur Discord apparaît, sous
   « Wafhien » avec le badge manette, `WTB [objet] x1 … @Rédemption Wafhien #CO<n>`.
   Témoin connu bon : la ligne `COCProbe M1 14:52:02 (C_Club.SendMessage)` du 2026-10-10.
   Observateur : le user, sur Discord.
7. [human] Le même envoi part bien d'un CLIC (« Poster »), pas seulement d'une commande tapée. Même
   observation que 6.
8. [human] Chez Gnomi (COC à jour), la commande arrive **une seule fois** : une alerte, pas
   d'Entrante « WTB » en plus. Témoin : une commande « Tous » du même joueur donne une seule alerte.
   Observateur : le user, compte de Gnomi.
9. [human] Flux mêlé (case décochée), puis guilde déliée : la même commande de guilde n'écrit rien,
   ni dans le chat de guilde ni sur Discord. Témoin : la même commande en flux séparé écrit sa ligne.
10. [agent] Pas d'appel à une fonction protégée de `C_Discord`, pas d'envoi hors du clic.
    → `api-gotcha-reviewer`

## Contrat

- **La ligne Discord** : `WTB <lien de l'objet> x<qté>[ PROVIDE <lien>x<n> …][ +N][ <prix>] @<Prénom
  Nom> #CO<n>`. C'est le format de `Orders_Announce.lua`, plus le jeton `@<nom>` **avant** l'étiquette,
  qui reste en fin de ligne : `Announce.Parse` ancre `#CO<n>` en fin de ligne, et l'analyseur tel
  qu'il est publié relit donc cette ligne sans changement. Le nom n'est ni un lien, ni un prix (un
  nom ne contient pas de chiffre), ni un matériau : `parseWTB` l'ignore.
- **La ligne de Commerce ne change pas.** Le jeton `@<nom>` n'existe que sur la ligne Discord.
- La ligne part dans le fil `Discord` de la guilde, jamais dans `CHAT_MSG_GUILD`. COC ne la relit pas.

## Plan (2026-10-10) — volatile, meurt quand c'est fait

1. ~~Mesures M1 et M2~~ : faites (fiche `mesure--discord-m1-m2`, archivée).
2. ~~Format~~ : fait (critères 1, 2).
3. ~~Envoi au clic « Poster », garde D4, délai D5~~ : fait (critères 3 à 5).
4. ~~Banc à deux comptes (critères 6 à 9)~~ : GO le 2026-10-10 16:23. Reste : la fusion dans `main`
   (COC) et `master` (outillage, tests) le même jour.

## Renvois

- `docs/specs/annonce-commerce.md` : le format `#CO`, la lecture, le confinement.
- Skill public `wow-addon-dev:wow-forever-api`, `references/chat-channels-and-communities.md`, section
  « Guild chat bridged to a Discord channel ». Les faits du 2026-10-10 y sont sur la branche
  `docs/forever-discord-guild-bridge` de `wow-addon-workspace`, **pas encore fusionnée**.
- Constats C3 et C8 (`docs/constats-api.md` de l'outillage) : contenu opaque des communautés, écriture
  dans une communauté depuis un clic.
- Sonde : `/cocprobe discord [protege|wtb|lfw|fils|ecrire]` (COCProbe, `COCProbe_Discord.lua`).
