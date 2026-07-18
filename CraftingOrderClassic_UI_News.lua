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
-- Bloc de TÊTE : la version courante, seule. Une 9ᵉ version dans versionsRecent la poussait à 66 lignes,
-- au-dessus du plafond anti-monolithe (60 l./fonction) — d'où un bloc de plus, comme les 3 existants.
-- À la prochaine release, verser cette entrée dans versionsRecent et repartir d'un bloc de tête vide.
local function versionsLatest()
    return {
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
    }
end

local function versionsRecent()
    return {
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
    }
end

local function versionsOlder()
    return {
        {
            v = "v1.16.0", title = L["Recettes triées, et où est l'or"],
            lines = {
                L["Fini le fourre-tout « Consommable » : les recettes sont regroupées par type (potions de soin, de mana, élixirs, flacons, transmutations…) et triées du plus haut niveau au plus bas. Une potion qui rend vie ET mana apparaît sous les deux. Le même classement s'applique partout — Commande, Mes artisans, et les métiers de récolte (minerais, herbes, cuirs, poissons)."],
                L["Si tu as Lazy Gold, chaque recette affiche sa rentabilité (pièces, étoiles au-delà de mille pièces d'or ; rien pour une perte). La pièce d'or au-dessus de la liste trie par profit, le bouton « 123 » bascule en valeurs exactes. L'onglet Commande a les deux boutons, plus la valeur HV et le coût des réactifs sur chaque commande entrante."],
                L["Dans l'annuaire, les métiers passent en icônes : un artisan avec un plan vraiment rentable a un contour doré, le survol nomme le plan, le clic ouvre la Commande déjà ciblée. « Mes artisans » gagne « Tous les plans du royaume » : tous tes persos (même faction) fusionnés et triés par profit — d'un coup d'œil, quel reroll fait des sous. Et si tu as MissingTradeSkillsList, un bouton montre tes recettes non apprises en rouge, avec leur source au clic."],
            },
        },
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
    }
end

local function versionsOldest()
    return {
        {
            v = "v1.10.1", title = L["Corrections : qui reçoit les alertes de commandes"],
            lines = {
                L["Les alertes de commandes ne dépendent plus du réglage |cFFFFFFFF/co scan|r : le scanner de chat et le carnet partageaient une option par erreur. Une commande publique te prévient désormais dès que tu as le métier."],
                L["Une commande publique portant un objet absent du catalogue arrivait en silence : elle te prévient maintenant, au lieu de dormir dans le carnet."],
                L["Démuter un joueur réarme la détection de spam le concernant ; revenir de la vue métier d'un reroll ne laisse plus les boutons Créer masqués ; et l'addon travaille nettement moins à chaque ligne de chat sur un royaume chargé."],
            },
        },
        {
            v = "v1.9.0", title = L["Tes rerolls réunis : cooldowns partagés, une identité, l'onglet Mes artisans"],
            lines = {
                L["Cooldowns de recettes partagés : les autres voient « Transmutation : prête » ou « dans 14h » sur ton infobulle d'artisan — fini de demander en canal si ton Arcanite est dispo."],
                L["Regroupe tes persos sous une identité (|cFFFFFFFF/co alts on|r) : une commande nommée pour ton alchimiste hors ligne arrive sur le perso où tu es connecté, et tu peux l'accepter depuis n'importe lequel. Vérifié des deux côtés (personne ne peut se faire passer pour le reroll d'autrui). Désactivé par défaut."],
                L["Nouvel onglet « Mes artisans » : tous les métiers de ton compte sur le royaume en une vue, comme un seul perso — niveau, recettes connues par catégorie, cooldowns en tête, et quel perso porte chaque recette."],
            },
        },
        {
            v = "v1.8.0", title = L["Sous le capot : mises à jour plus sûres"],
            lines = {
                L["Tes données sauvegardées portent désormais une version : une mise à jour qui doit les réorganiser ne tourne qu'une fois, tes recettes et commandes restent intactes."],
                L["Protocole de commandes consolidé (mêmes échanges réseau) : ce build reste compatible avec les joueurs encore en 1.7.x."],
            },
        },
        -- v1.7.0 / v1.7.1 retirées de l'onglet (l'historique complet vit dans CHANGELOG.md). Cet onglet
        -- ne garde qu'une fenêtre glissante de versions : sinon il croît sans fin, et avec lui les 3
        -- overlays de locale, qui butent sur le plafond anti-monolithe. Retirer ici = retirer les clés
        -- correspondantes des overlays (sinon check_locale les signale comme traductions MORTES).
        {
            v = "v1.6.0", title = L["Allemand et espagnol + onglet Nouveautés"],
            lines = {
                L["L'interface se traduit en allemand et en espagnol selon la langue de ton client WoW."],
                L["Ce nouvel onglet « Nouveautés » affiche les notes de version directement en jeu."],
            },
        },
        {
            v = "v1.5.0", title = L["Repérer les crafteurs sans l'addon + passe de performance"],
            lines = {
                L["Repérage passif des crafteurs autour de toi, même sans l'addon (onglet Artisans → « Repérer les crafteurs autour », ou |cFFFFFFFF/co crafters on|r). Désactivé par défaut, en ville seulement."],
                L["Liste de plans de l'onglet Commande réécrite : plus fluide sur les métiers à centaines de recettes (Couture)."],
                L["La fenêtre ne se redessine plus à chaque message réseau : les rafales sont regroupées en un seul rendu."],
                L["Protocole de commande durci : un autre client ne peut plus annuler ta commande, usurper une acceptation, ni s'attribuer une livraison."],
            },
        },
        {
            v = "v1.4.0", title = L["Commander depuis les panneaux Amis & Guilde"],
            lines = {
                L["Survole un ami dans la liste d'amis, ou sélectionne un membre dans le panneau de guilde : ses métiers primaires s'affichent sans ouvrir cette fenêtre."],
                L["Clic droit sur un joueur qui a l'addon (ami, guilde, croisé) : « Passer commande à… » ouvre l'onglet Commande déjà ciblé sur lui."],
                L["« Met » devient « Annuaire ». Le bouton « Rafraîchir l'annuaire » appelle le canal : tous les porteurs en ligne répondent et s'y ajoutent."],
            },
        },
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
