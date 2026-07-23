-- CraftingOrderClassic_UI_News.lua — onglet « Nouveautés » : notes de version (changelog) affichées
-- EN JEU, version par version, la plus récente en tête. Contenu figé et localisé, peint UNE fois à la
-- construction (même structure que l'onglet Aide). Source humaine : CHANGELOG.md — garder les deux en
-- phase à chaque release (ici : les points forts localisés, pas la prose complète du .md).

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local BODY_W = 780

-- Une entrée par version. Les lignes v1.4.0 REUTILISENT les clés déjà traduites de l'ancienne section
-- « Nouveautés » de l'Aide (overlay enUS existant) → pas de doublon de traduction. Scindé en deux
-- blocs (récent / plus ancien) concaténés par versions() : chaque bloc reste sous le seuil anti-monolithe.
-- Bloc de TÊTE : les versions les plus récentes. Une 9ᵉ version dans versionsRecent la poussait à
-- 66 lignes, au-dessus du plafond anti-monolithe (60 l./fonction) — d'où ce bloc de plus.
-- ⚠️ À la release suivante, AJOUTER l'entrée en tête de CE bloc ; ne PAS reverser dans versionsRecent,
-- qui repasserait aussitôt au-dessus du plafond. Quand ce bloc-ci s'en approchera à son tour, en créer
-- un nouveau devant lui (versions() n'a qu'à le concaténer en premier).
local function versionsLatest()
    return {
        {
            v = "v1.27.1", title = L["Prêt pour le patch 1.15.9"],
            lines = {
                L["Classic Era, SoD et Hardcore passent à la 1.15.9 et à sa nouvelle interface. L'addon a été vérifié contre elle et se déclare compatible : le badge [Dispo] au-dessus des plaques fonctionne comme avant. Seule limite, décidée par Blizzard : en instance, les plaques amies sont réservées au jeu lui-même, donc pas de badge en donjon."],
                L["Corrigé : la liste des PNJ sous une recette manquante (formateurs, vendeurs) mélangeait les deux factions, au point d'envoyer un personnage Alliance à Fossoyeuse. Les PNJ du camp d'en face sont maintenant masqués ; les monstres à butin et les PNJ neutres restent, eux servent tout le monde."],
            },
        },
        {
            v = "v1.27.0", title = L["Prévenu quand une nouvelle version sort"],
            lines = {
                L["L'addon repère maintenant qu'il tourne en retard. Il lit la version des joueurs que tu croises sur le réseau, et dès qu'il en voit une plus récente chez plusieurs personnes différentes, il te le dit d'une ligne dans le chat et pose un point rouge sur le bouton minimap. Le point s'efface tout seul une fois que tu as mis à jour."],
                L["Ce « plusieurs personnes différentes » est voulu : un joueur isolé ne peut pas te faire croire que tu es en retard en annonçant un faux numéro, il faut que des joueurs distincts le confirment. Et ça ne te prévient qu'une fois par version, jamais à chaque connexion. Tape /co version pour voir ta version et s'il en existe une plus récente."],
            },
        },
        {
            v = "v1.26.0", title = L["Filtre n'importe quelle liste par la stat qu'elle donne"],
            lines = {
                L["Chaque liste de recettes — l'onglet Commande, la fenêtre métier, Mes artisans — reçoit un sélecteur de stat. Tu choisis Force, tu ne vois que ce qui donne de la Force : gemmes, équipements, élixirs. Le menu se remplit avec ce que le métier ouvert fabrique vraiment, donc la Cuisine ne te propose pas Puissance des sorts. Ces stats ne sont écrites nulle part, elles sont lues sur ton propre jeu — dans ta langue, et valables pour des objets que je n'ai jamais regardés, Wrath compris."],
                L["L'alchimie se range mieux aussi : les élixirs se regroupent sous la stat qu'ils donnent, pendant que les potions de soin et de mana, les flacons et les transmutations gardent leurs propres en-têtes — « rend de la vie » n'a jamais été une stat. Sur TBC, ça sort 74 consommables du fourre-tout Divers."],
            },
        },
        {
            v = "v1.25.0", title = L["Les gemmes se rangent par couleur, puis par ce qu'elles donnent"],
            lines = {
                L["La joaillerie versait toutes les gemmes taillées sous un seul en-tête « Gemme ». Elles se rangent maintenant par couleur de châsse, et sous chaque couleur par la stat qu'elles donnent : « Force - Audacieux », « Endurance - Solide ». Cette stat n'est pas une table écrite à la main, elle est lue sur ton propre jeu — donc dans ta langue, et valable pour des gemmes que je n'ai jamais regardées."],
                L["Les gemmes méta, elles, reviennent à une simple liste : chaque taille de méta n'existe qu'en un seul exemplaire, un en-tête au-dessus n'aurait fait que répéter la ligne. Bagues, colliers, statues et figurines gardent le classement qu'ils avaient."],
                L["Corrigé aussi : quand un enchanteur te demandait une pièce, l'invite ne s'affichait parfois jamais. Une première demande arrivée trop tôt, avant que tu aies équipé la pièce, armait quand même le délai de cinq secondes — et la vraie demande qui suivait passait à la trappe. Le délai ne démarre plus que sur une demande réellement affichée."],
            },
        },
        {
            v = "v1.24.2", title = L["Les stats d'enchant parlent enfin ta langue"],
            lines = {
                L["Les sous-catégories de la vue enchant (Force, Esprit, Croisé…) venaient d'un libellé interne jamais traduit : tout le monde les voyait en anglais, client français compris. Elles sont maintenant lues directement sur ton jeu, comme les noms de sorts, donc dans ta langue sans rien à traduire à la main à chaque nouvelle recette."],
            },
        },
    }
end

local function versionsRecent()
    return {
        {
            v = "v1.24.1", title = L["Deux minerais de plus dans les commandes de récolte"],
            lines = {
                L["Le khorium et l'éternium n'apparaissaient pas comme commandables dans l'onglet Récolte. La liste des minerais était dérivée de ceux qu'on peut prospecter en gemmes, et ni l'un ni l'autre ne l'est — le même trou qui cachait déjà l'argent, l'or, le vrai-argent et le sombrefer. Les deux rejoignent la liste."],
            },
        },
        {
            v = "v1.24.0", title = L["La pièce à enchanter se pose d'un clic, et une bourse qui suit la progression"],
            lines = {
                L["Depuis la v1.21.0, un enchanteur peut cliquer un emplacement de la silhouette d'échange pour te demander la pièce à enchanter. Si tu as l'addon toi aussi, ce clic affiche maintenant une invite chez toi : accepte, et ta pièce équipée se pose toute seule dans l'emplacement « ne sera pas échangé ». Rien n'est donné (cet emplacement ne peut pas changer de mains), la pose est verrouillée sur lui, et rien ne bouge sans ton clic. Sans l'addon en face, le chuchotement explicatif part comme avant."],
                L["La bourse d'artisan se met à jour en direct : fenêtre ouverte, chaque point de métier gagné par le personnage suivi (et chaque recette apprise) recalcule la liste de courses — plus besoin de la rouvrir pour voir la route changer."],
            },
        },
        {
            v = "v1.23.0", title = L["La bourse d'artisan : la liste de courses de tes guildeux, et deux corrections réseau"],
            lines = {
                L["L'onglet Artisans gagne un bouton sac après les icônes de métier de chaque fiche : un clic ouvre la liste de courses des matériaux qu'il te faut pour monter tes métiers, calculée en local à partir de ce que le jeu diffuse déjà (aucun nouveau trafic réseau). Les réactifs que ton propre métier sait fabriquer sont décomposés en composants de base, et les objets vendus par un PNJ sont mis de côté dans une note plutôt que d'encombrer la grille."],
                L["Coche « inclure les plans à acheter » et les recettes derrière un coût rejoignent la liste : les plans-objets comme fourniture à apporter, les plans de formateur comme simple note. Le même bloc de fournitures s'affiche maintenant sous le plan de route « quoi monter ensuite », avec le PNJ où aller (nom, zone, coordonnées) et une épingle TomTom cliquable si tu l'as installé."],
                L["Une recette sans réactif au prix connu (la poussière d'enchantement, par exemple) ne fait plus sauter tout un tronçon du plan de route : elle sert maintenant de repli marqué « ? » quand rien de mieux n'est disponible. Une table de désenchantement maison alimente aussi l'infobulle des poussières, essences et éclats affichés dans ces listes."],
                L["Deux corrections : un compte à plusieurs personnages se voyait parfois lister lui-même comme « joignable via » son autre perso dans son propre onglet Artisans, corrigé. Et le plan de route pouvait s'arrêter avant le vrai plafond de compétence après une formation chez le maître, à cause d'une assignation Lua qui perdait silencieusement sa seconde valeur."],
            },
        },
        {
            v = "v1.22.1", title = L["Les alertes de commande vérifient enfin le métier, et un plan de route qui suit son propre badge"],
            lines = {
                L["Une commande à portée large (guilde, amis, tous) déclenchait un toast même chez un joueur sans le métier, du moment qu'elle arrivait par le relais de connexion (chuchotement) plutôt que par le canal : le filtre par métier ne couvrait que le canal. Il s'applique maintenant quel que soit le chemin réseau. Le toast gagne aussi un troisième texte : une commande à portée large n'affiche plus « pour TOI », ce qui donnait l'impression fausse d'une demande personnelle."],
                L["Le plan de route « quoi monter ensuite » pouvait suggérer une recette différente du badge de coût de la liste, les deux lisant des données légèrement différentes. Le plan utilise maintenant la difficulté réelle de la fenêtre métier à ton rang actuel plutôt qu'une projection, et se rafraîchit au même rythme que le badge. La commande |cFFFFFFFF/co lvldump|r affiche le détail en cas de nouveau désaccord."],
            },
        },
        {
            v = "v1.22.0", title = L["L'aide contextuelle, des dépendances qu'on ne peut plus rater, et une touche Échap qui obéit"],
            lines = {
                L["Un nouveau bouton « i » ouvre l'aide contextuelle du jeu, le même système que Blizzard utilise pour ses propres fenêtres : le fond s'assombrit et une bulle pointe directement sur ce dont il est question. Chaque onglet (Vue Métier, Commande, Récolte, Artisans, Mes artisans, Carnet) a sa propre visite guidée, donc le bouton explique ce qui est réellement affiché plutôt qu'une infobulle générique."],
                L["Lazy Gold et MTSL restent optionnels, mais rien ne signalait qu'ils manquaient. Les boutons qui en dépendent restent visibles et colorés même sans l'addon installé, et cliquer dessus sans l'avoir ouvre désormais une explication de ce qu'il fait et où le trouver, plutôt que de ne rien faire du tout."],
                L["L'alerte « peut faire cette commande » se déclenchait même quand tu ne connaissais pas la recette, souvent des gemmes ou enchants dont tu avais les réactifs sans le plan. Elle vérifie maintenant tes recettes connues avant de te notifier sur tes propres commandes. Un ami en ligne sans l'addon ne s'affiche plus « Hors ligne » par erreur."],
                L["Échap laissait souvent les fenêtres de métier ouvertes, et trois rapports différents pointaient la même cause : cacher ou désactiver la souris d'une fenêtre protégée en plein combat déclenche une erreur du jeu. Les fenêtres passent maintenant par un petit relais dédié, donc Échap les ferme proprement, en combat ou non."],
                L["L'aide « quoi monter ensuite » affiche maintenant le coût par point de compétence, une pastille de prix Auctioneer, et une icône vers le PNJ qui vend une recette que tu ne connais pas encore, en plus d'un tri affiné."],
                L["Cette même aide gagne un plan de route : clique le bouton carte et il déroule toute ta montée rang par rang, en choisissant à chaque étape la recette la moins chère (apprise ou achetable, plans compris) et en additionnant le coût total. Les recettes à cooldown ou avec un réactif sans prix connu sont exclues exprès, elles fausseraient le total. Demande Lazy Gold ; MTSL ajoute les prix de plans formateur et vendeur au calcul."],
            },
        },
        {
            v = "v1.21.0", title = L["L'enchant par emplacement, et un panneau d'échange qui ne cache plus rien"],
            lines = {
                L["Choisir un enchant demandait de fouiller des centaines de plans aux noms presque identiques. L'onglet Commande a maintenant une vue silhouette : clique l'emplacement à enchanter, tu obtiens ses stats, puis ses variantes de la plus forte à la plus faible. La bascule est dans la bande de filtres ; la liste reste pour tout ce qui n'a pas d'emplacement (huiles, baguettes, produits de désenchantement)."],
                L["Le panneau d'enchant de l'échange n'affichait que 8 lignes, et le « +N autre(s) » du bas n'était pas cliquable : au-delà de la 8ᵉ place, un enchant était tout bonnement inatteignable — c'est ainsi qu'un enchanteur à qui on avait passé les réactifs ne se voyait jamais proposer la bonne recette, noyée sous les variantes de haut rang. La liste défile à la molette, et elle est classée par ce qu'on te demande : d'abord les enchants dont ton partenaire vient de poser les réactifs, puis ce que tes sacs permettent, puis le reste."],
                L["Tant que la case « ne sera pas échangé » est vide, le panneau ne disparaît plus : il montre la même silhouette, avec le modèle de ton partenaire, et cliquer un emplacement lui chuchote d'y poser cette pièce. La plupart des gens qui te tendent un objet ignorent que cette case existe."],
                L["Deux correctifs : les enchants de poignets et de bâton de Wrath n'apparaissaient jamais dans le panneau d'échange (le jeu les écrit « Bracers » et « Staff » là où les autres extensions disent « Bracer »), et un enchant de bâton ne se propose plus que sur un vrai bâton. Le panneau ne touche plus non plus à ses boutons pendant un combat, ce que le jeu interdit."],
                L["Plus discret : les lignes de chat « X sait faire cette commande captée » sont désactivées par défaut — la commande est poussée aux amis capables dans tous les cas, le message n'était que du bruit. |cFFFFFFFF/co verbose|r les remet."],
            },
        },
    }
end

local function versionsOlder()
    return {
        {
            v = "v1.20.0", title = L["Enchante en un clic, trié par emplacement, et depuis l'échange"],
            lines = {
                L["Le bouton « Créer » de l'Enchantement avait un vieux bug intermittent : parfois rien ne se passait, et resélectionner la recette finissait par le faire marcher. Cause trouvée : sélectionner une recette n'arme pas le bouton natif de Blizzard, notre clic sécurisé tombait donc sur un bouton désactivé. Corrigé — ça devrait marcher du premier coup, à chaque fois."],
                L["Les recettes d'enchantement ne s'entassent plus dans un fourre-tout « Autres/Divers » : elles se rangent par emplacement (Poignets, Torse, Main gauche…) puis par stat de base (Force, Esprit, Déviation), le nom raccourci à la stat seule puisque l'emplacement est déjà dans l'en-tête."],
                L["Sélectionner un enchant d'équipement affiche un bouton « Enchanter équipé » à côté de Créer : un clic l'applique directement sur la pièce que tu portes, sans avoir à cibler."],
                L["Et quand quelqu'un te tend un objet à enchanter en échange, le poser dans la case « ne sera pas échangé » ouvre un petit panneau listant tes enchants pour cet emplacement, prêts à lancer sans fouiller ta fenêtre de métier (qui doit rester ouverte : le jeu ne renseigne tes recettes connues que pendant qu'elle l'est)."],
            },
        },
        {
            v = "v1.19.1", title = L["Correctif : l'icône « dispo » remarche sur la nouvelle UI des plaques"],
            lines = {
                L["Sur le client TBC (et bientôt Era/Saison de la Découverte à la 1.15.9), l'icône « recherche de travail » au-dessus de la plaque d'un artisan cessait de s'afficher quand son statut changeait : la nouvelle interface de plaques a renommé un champ interne que l'addon lisait. Corrigé. Elle reste invisible en instance (donjon, raid) : le jeu verrouille les plaques amies aux addons là-bas, rien à faire de notre côté."],
            },
        },
        {
            v = "v1.19.0", title = L["Propose des recettes précises, diffuse tes réactifs, et le LFW marche même sans l'addon"],
            lines = {
                L["« Chercher du travail » propose maintenant des recettes précises, pas seulement des réactifs : coche des plans dans la liste et qui te consulte voit « propose : Bouclier de fer, Gilet de mailles de cuivre » à côté de ce que tu fournis déjà."],
                L["Un bouton « Diffuser » envoie la liste de réactifs d'une recette ou d'une commande dans un canal au choix (guilde, dire, groupe/raid, un canal numéroté), avec le lien de chaque objet — une liste de courses en un clic, depuis la vue métier, la carte de commande ou le panneau de publication."],
                L["Le LFW marche même sans l'addon : tape « LFW enchantement » en Commerce ou Général et tu apparais comme dispo, avec la même icône de plaque qu'un joueur qui a Crafting Order. Plus une correction : une recette déjà apprise ne s'affichait plus en double avec MissingTradeSkillsList."],
            },
        },
        {
            v = "v1.18.0", title = L["Chercher du travail : dis ce que tu offres, et trie par progression"],
            lines = {
                L["« Chercher du travail » ne se contente plus de te signaler dispo. Clique l'engrenage à côté du bouton et dis ce que tu proposes : tu fournis les composants de base, tu fournis tel réactif précis, une commission fixe par craft, ou seulement les plans qui te font gagner un point de compétence. Ça s'affiche sur ta ligne [Dispo] et dans l'infobulle au-dessus de ta tête, avec une pièce s'il y a une commission et un sac si tu fournis des compos."],
                L["L'icône « dispo » au-dessus de la plaque d'un artisan marche maintenant sur Era et Saison de la Découverte, plus seulement sur le client TBC. Active les plaques des amis (nameplateShowFriends) et l'icône du métier flotte au-dessus de qui cherche du travail à côté de toi."],
                L["Les recettes se trient par ce qui te fait encore progresser : un troisième bouton outil remonte en tête les plans qui donnent un point, d'orange à gris. Les commandes ont le même « ce qui me fait monter d'abord », avec un liseré de difficulté sur le côté de chaque ligne. Plus quelques corrections au passage."],
            },
        },
        {
            v = "v1.17.1", title = L["Correctif : erreur au login en « Chercher du travail »"],
            lines = {
                L["Si tu avais activé « Chercher du travail », te connecter ou faire /reload pouvait déclencher une erreur rouge : l'addon annonçait ta disponibilité avant que le jeu n'autorise un addon à parler sur le canal. L'annonce attend maintenant ton prochain clic ou ta prochaine touche — plus d'erreur, et les autres te voient toujours dispo."],
            },
        },
        {
            v = "v1.17.0", title = L["L'interface passe au style natif de WoW"],
            lines = {
                L["La fenêtre n'a plus son habillage doré maison : elle emprunte le cadre du jeu (barre de titre, portrait rond, onglets, boutons). Elle se fond dans l'interface au lieu de ressembler à un addon posé par-dessus, et rien n'a bougé de ce que tu connais."],
                L["La vue métier est refaite, avec une colonne Commandes en liste : une ligne par commande (demandeur, objet voulu, prix), et le clic ouvre la carte complète (composants fournis, coût des réactifs, Accepter / Refuser / Chuchoter) avec une croix pour revenir à la liste. Et les sous-catégories de récolte (Peaux, Écailles, Herbes, Poissons) sont enfin traduites hors client français."],
            },
        },
        {
            v = "v1.16.0", title = L["Recettes triées, et où est l'or"],
            lines = {
                L["Fini le fourre-tout « Consommable » : les recettes sont regroupées par type (potions de soin, de mana, élixirs, flacons, transmutations…) et triées du plus haut niveau au plus bas. Une potion qui rend vie ET mana apparaît sous les deux. Le même classement s'applique partout — Commande, Mes artisans, et les métiers de récolte (minerais, herbes, cuirs, poissons)."],
                L["Si tu as Lazy Gold, chaque recette affiche sa rentabilité (pièces, étoiles au-delà de mille pièces d'or ; rien pour une perte). La pièce d'or au-dessus de la liste trie par profit, le bouton « 123 » bascule en valeurs exactes. L'onglet Commande a les deux boutons, plus la valeur HV et le coût des réactifs sur chaque commande entrante."],
                L["Dans l'annuaire, les métiers passent en icônes : un artisan avec un plan vraiment rentable a un contour doré, le survol nomme le plan, le clic ouvre la Commande déjà ciblée. « Mes artisans » gagne « Tous les plans du royaume » : tous tes persos (même faction) fusionnés et triés par profit — d'un coup d'œil, quel reroll fait des sous. Et si tu as MissingTradeSkillsList, un bouton montre tes recettes non apprises en rouge, avec leur source au clic."],
            },
        },
    }
end

local function versionsOldest()
    return {
        {
            v = "v1.15.1", title = L["Tes commandes n'appartiennent qu'à toi"],
            lines = {
                L["Les identifiants de commande étaient devinables : n'importe qui pouvait réécrire la tienne (acheteur, prix, quantité). C'est fermé : seul son auteur peut la modifier. Le relais entre joueurs, lui, continue de fonctionner — c'est comme ça qu'une commande atteint quelqu'un que le canal n'a jamais touché."],
                L["On ne peut plus te faire mettre en sourdine en postant de fausses commandes en ton nom, et un acheteur dont les commandes sont relayées en rafale n'est plus muté par erreur. « X a refusé ta commande » et le rappel « tu sais le faire » ne se rejouent plus en boucle, et rien ne passe d'un joueur que tu as mis en sourdine."],
                L["La vue métier n'affiche plus les commandes privées destinées à quelqu'un d'autre, ni les expirées. Ton compteur de crafts livrés ne peut plus être gonflé par un tiers. Et croiser un artisan coûte deux fois moins de messages : le bonjour porte maintenant tes métiers, ce qui règle aussi les artisans qui s'affichaient sans aucun métier."],
            },
        },
        {
            v = "v1.15.0", title = L["Recherche de travail : signale que tu es dispo"],
            lines = {
                L["Ouvre un métier et clique « Chercher du travail » : tout le royaume sait que tu es dispo, une icône d'artisan s'affiche au-dessus de ta tête pour ceux qui passent, et tu apparais « [Dispo] » dans leur annuaire. Ça s'éteint tout seul au bout d'un moment si tu oublies."],
                L["Au passage : les deux fenêtres ne s'emmêlent plus (un clic la ramène au premier plan), l'annuaire a un bouton partenaire et se limite à ta faction (pas d'échange cross-faction sur Classic), et un artisan ne s'affiche plus avec un métier qui n'est pas le sien."],
            },
        },
        {
            v = "v1.14.0", title = L["Un panneau pour gérer les mis en sourdine"],
            lines = {
                L["L'onglet Artisans a maintenant une section « En sourdine » : chaque joueur muté y apparaît avec sa raison et le temps restant (ou « permanent »), avec un bouton pour le rétablir directement — plus besoin de deviner qui est encore muté."],
            },
        },
        {
            v = "v1.13.0", title = L["Modération : mutes avec raison, temporaires, liste de confiance"],
            lines = {
                L["Un mute porte désormais une raison et une date, et peut être temporaire : |cFFFFFFFF/co mute Bob 1h spammeur|r se lève tout seul au bout d'une heure (|cFFFFFFFF/co mute|r seul liste les mutés avec raison et temps restant). Et |cFFFFFFFF/co trust <nom>|r marque un joueur de confiance, jamais mis en sourdine automatiquement — le mute manuel restant toujours possible."],
            },
        },
        {
            v = "v1.11.0", title = L["Annuler une commande publique atteint tout le royaume"],
            lines = {
                L["Une commande publique voyage sur le canal du royaume depuis la v1.10.0, mais pas son annulation : un artisan que tu n'as jamais croisé la voyait « ouverte » pendant six heures, l'acceptait, et farmait les réactifs pour rien. L'annulation part désormais sur le même canal."],
                L["Poster et annuler ne perdent plus de messages. Le canal exige un clic ou une touche et n'accepte qu'une ligne par seconde : un |cFFFFFFFF/co post|r tapé au chat, ou deux commandes postées dans la même seconde, disparaissaient sans trace. Ces lignes patientent maintenant dans une file et partent à ton prochain clic."],
                L["Seules les commandes NOUVELLES et les ANNULATIONS voyagent sur le canal, et seulement les publiques. Guilde, amis et commandes nommées restent privées ; les acceptations restent entre les deux joueurs concernés."],
            },
        },
        {
            v = "v1.10.2", title = L["Correctif : erreur en combat dans la vue métier"],
            lines = {
                L["Sélectionner une recette pendant un combat ne provoque plus d'erreur bloquée : le bouton « Créer » est un bouton sécurisé, que le jeu interdit de masquer en plein combat. L'addon attend maintenant la fin du combat pour l'afficher ou le masquer."],
            },
        },
        {
            v = "v1.12.0", title = L["Les recettes de la Saison de la Découverte"],
            lines = {
                L["304 recettes de la Saison de la Découverte entrent au catalogue : 80 en Travail du cuir, 65 en Forge, 57 en Couture, 48 en Enchantement, 29 en Ingénierie, 16 en Alchimie, plus la Cuisine, le Secourisme et le Minage. Elles apparaissent dans l'onglet Commande, avec leurs réactifs et leur palier d'apprentissage."],
                L["Elles ne se chargent que sur un royaume Saison de la Découverte. Sur un royaume Era classique, rien ne change : l'addon voit exactement le même jeu de recettes qu'avant, et les recettes que tes amis t'ont déjà partagées restent lisibles."],
            },
        },
        -- v1.10.1 / v1.9.0 / v1.8.0 / v1.7.0 / v1.7.1 / v1.6.0 / v1.5.0 / v1.4.0 retirées de l'onglet (l'historique
        -- complet vit dans CHANGELOG.md). Cet onglet ne garde qu'une fenêtre glissante de versions :
        -- sinon il croît sans fin, et avec lui les 3 overlays de locale, qui butent sur le plafond
        -- anti-monolithe. Retirer ici = retirer les clés correspondantes des overlays (sinon
        -- check_locale les signale comme traductions MORTES).
    }
end

local function versions()
    local out = versionsLatest()
    for _, e in ipairs(versionsRecent()) do out[#out + 1] = e end
    for _, e in ipairs(versionsOlder()) do out[#out + 1] = e end
    for _, e in ipairs(versionsOldest()) do out[#out + 1] = e end
    return out
end

-- Peint une version (titre doré « vX.Y.Z + résumé », puis une puce par ligne). Renvoie le Y suivant.
local function paintVersion(body, ver, y)
    local title = body:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 0, y); title:SetWidth(BODY_W); title:SetJustifyH("LEFT")
    title:SetText("|cFFE8B84B" .. ver.v .. "|r  " .. ver.title)
    title:SetTextColor(Skin.unpack(Skin.color.goldHi)); Skin.ApplyShadow(title)
    y = y - 22
    for _, line in ipairs(ver.lines) do
        local dot = body:CreateTexture(nil, "OVERLAY")
        dot:SetSize(10, 10); dot:SetPoint("TOPLEFT", 6, y - 3); dot:SetTexture(Skin.tex.broadcast)
        local fs = body:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("TOPLEFT", 22, y); fs:SetWidth(BODY_W - 22); fs:SetJustifyH("LEFT")
        fs:SetTextColor(Skin.unpack(Skin.color.text)); Skin.ApplyShadow(fs); fs:SetText(line)
        y = y - fs:GetStringHeight() - 8
    end
    return y - 14
end

function UI:BuildNewsTab(f)
    local panel = CreateFrame("Frame", nil, f); self.insetPanel(panel, f); self.newsPanel = panel

    local scroll = CreateFrame("ScrollFrame", "CraftingOrderNewsScroll", panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -74); scroll:SetPoint("BOTTOMRIGHT", -32, 22)
    local body = CreateFrame("Frame", nil, scroll); body:SetSize(BODY_W, 10); scroll:SetScrollChild(body)
    self.newsBody = body

    local y = -2
    for _, ver in ipairs(versions()) do y = paintVersion(body, ver, y) end
    body:SetHeight(math.max(-y, 10))
end

function UI:RefreshNews()
    Skin.AutoHideScroll("CraftingOrderNewsScroll", self.newsBody)
end
