-- CraftingOrderClassic_Locale_News_deDE.lua — traductions de l'onglet « Nouveautés » (deDE).
-- Extrait de _Locale_deDE.lua (plafond anti-monolithe). Clé FR → texte DE, chargé APRÈS _Locale.lua.

local COC = CraftingOrderClassic
if (GetLocale and GetLocale() or "") ~= "deDE" then return end
local L = COC.L

local news = {
    -- Onglet Nouveautés (changelog en jeu)
    ["Nouveautés"] = "Neues",
    -- v1.15.0
    ["Recherche de travail : signale que tu es dispo"] = "Arbeitssuche: zeig, dass du verfügbar bist",
    ["Ouvre un métier et clique « Chercher du travail » : tout le royaume sait que tu es dispo, une icône d'artisan s'affiche au-dessus de ta tête pour ceux qui passent, et tu apparais « [Dispo] » dans leur annuaire. Ça s'éteint tout seul au bout d'un moment si tu oublies."] =
        "Öffne einen Beruf und klick „Arbeit suchen“: der ganze Realm weiß, dass du verfügbar bist, ein Handwerker-Symbol erscheint über deinem Kopf für Vorbeikommende, und du erscheinst als „[Sucht]“ in ihrem Verzeichnis. Es erlischt von selbst, wenn du es vergisst.",
    ["Au passage : les deux fenêtres ne s'emmêlent plus (un clic la ramène au premier plan), l'annuaire a un bouton partenaire et se limite à ta faction (pas d'échange cross-faction sur Classic), et un artisan ne s'affiche plus avec un métier qui n'est pas le sien."] =
        "Nebenbei: die zwei Fenster überlagern sich nicht mehr (ein Klick bringt eins nach vorne), das Verzeichnis hat einen Partner-Knopf und bleibt bei deiner Fraktion (kein fraktionsübergreifender Handel auf Classic), und ein Handwerker zeigt keinen Beruf mehr, der nicht seiner ist.",
    ["Repérer les crafteurs sans l'addon + passe de performance"] = "Handwerker ohne Addon erkennen + Leistungsverbesserungen",
    ["Repérage passif des crafteurs autour de toi, même sans l'addon (onglet Artisans → « Repérer les crafteurs autour », ou |cFFFFFFFF/co crafters on|r). Désactivé par défaut, en ville seulement."] =
        "Passives Erkennen von Handwerkern in deiner Nähe, auch ohne Addon (Tab Handwerker, oder |cFFFFFFFF/co crafters on|r). Standardmäßig aus, nur in Städten.",
    ["Liste de plans de l'onglet Commande réécrite : plus fluide sur les métiers à centaines de recettes (Couture)."] =
        "Rezeptliste im Tab Bestellen überarbeitet: flüssiger bei Berufen mit Hunderten Rezepten (Schneiderei).",
    ["La fenêtre ne se redessine plus à chaque message réseau : les rafales sont regroupées en un seul rendu."] =
        "Das Fenster wird nicht mehr bei jeder Netzwerknachricht neu gezeichnet: Schübe werden zu einem Rendern zusammengefasst.",
    ["Protocole de commande durci : un autre client ne peut plus annuler ta commande, usurper une acceptation, ni s'attribuer une livraison."] =
        "Auftragsprotokoll gehärtet: ein anderer Client kann deinen Auftrag nicht mehr stornieren, eine Annahme vortäuschen oder eine Lieferung beanspruchen.",
    ["Commander depuis les panneaux Amis & Guilde"] = "Bestellen aus den Fenstern Freunde & Gilde",
    ["Greffons échange & courrier, dock en vue Blizzard"] = "Handels- & Post-Zusätze, Andocken in Blizzard-Ansicht",
    ["Panneaux compagnons sur la fenêtre d'échange et de courrier pour livrer une commande sans ouvrir le carnet."] =
        "Begleitfenster am Handels- und Postfenster, um einen Auftrag zu liefern, ohne das Auftragsbuch zu öffnen.",
    ["La colonne Commandes peut s'ancrer à droite de la fenêtre métier native (vue Blizzard)."] =
        "Die Auftragsspalte kann rechts am nativen Berufsfenster andocken (Blizzard-Ansicht).",
    ["Sous le capot : mises à jour plus sûres"] = "Unter der Haube: sicherere Updates",
    ["Tes données sauvegardées portent désormais une version : une mise à jour qui doit les réorganiser ne tourne qu'une fois, tes recettes et commandes restent intactes."] =
        "Deine gespeicherten Daten tragen jetzt eine Version, sodass ein Update, das sie umbauen muss, nur einmal läuft und deine Rezepte und Aufträge unversehrt bleiben.",
    ["Protocole de commandes consolidé (mêmes échanges réseau) : ce build reste compatible avec les joueurs encore en 1.7.x."] =
        "Das Auftragsprotokoll wurde konsolidiert (gleiche Netzwerk-Kommunikation); dieser Build versteht sich weiterhin mit Spielern auf 1.7.x.",
    -- (clés v1.7.0/v1.7.1 retirées : ces versions ne sont plus listées dans l'onglet Nouveautés)
    ["Allemand et espagnol + onglet Nouveautés"] = "Deutsch und Spanisch + Tab Neues",
    ["L'interface se traduit en allemand et en espagnol selon la langue de ton client WoW."] =
        "Die Oberfläche wird je nach Sprache deines WoW-Clients ins Deutsche und Spanische übersetzt.",
    ["Ce nouvel onglet « Nouveautés » affiche les notes de version directement en jeu."] =
        "Dieser neue Tab « Neues » zeigt die Versionshinweise direkt im Spiel.",
    -- Onglet Nouveautés — v1.13.0
    ["Modération : mutes avec raison, temporaires, liste de confiance"] = "Moderation: Stummschaltungen mit Grund, temporär, Vertrauensliste",
    ["Un mute porte désormais une raison et une date, et peut être temporaire : |cFFFFFFFF/co mute Bob 1h spammeur|r se lève tout seul au bout d'une heure (|cFFFFFFFF/co mute|r seul liste les mutés avec raison et temps restant). Et |cFFFFFFFF/co trust <nom>|r marque un joueur de confiance, jamais mis en sourdine automatiquement — le mute manuel restant toujours possible."] =
        "Eine Stummschaltung trägt jetzt einen Grund und ein Datum und kann temporär sein: |cFFFFFFFF/co mute Bob 1h Spammer|r hebt sich nach einer Stunde selbst auf (|cFFFFFFFF/co mute|r allein listet die Stummgeschalteten mit Grund und Restzeit). Und |cFFFFFFFF/co trust <Name>|r markiert einen Spieler als vertrauenswürdig, nie automatisch stummgeschaltet — manuelles Stummschalten bleibt möglich.",
    -- Onglet Nouveautés — v1.12.1
    ["Personne ne peut poster une commande en ton nom"] = "Niemand kann einen Auftrag in deinem Namen aufgeben",
    ["Une commande arrivant par le canal du royaume était crue sur parole quant à son acheteur : un joueur pouvait publier de fausses commandes au nom d'autrui, et nourrir la détection de spam contre sa victime jusqu'à ce que tout le monde la mette en sourdine. Elles doivent désormais venir du joueur qui les a postées."] =
        "Einem über den Realm-Kanal eintreffenden Auftrag wurde sein Käufer aufs Wort geglaubt: ein Spieler konnte falsche Aufträge im Namen anderer veröffentlichen und die Spam-Erkennung gegen sein Opfer füttern, bis alle es stummschalteten. Solche Aufträge müssen nun vom Spieler kommen, der sie aufgegeben hat.",
    ["|cFFFFFFFF/co channel off|r quitte maintenant vraiment le canal. Il se contentait d'empêcher de le rejoindre au login suivant : tes commandes continuaient de partir au royaume pendant toute la session."] =
        "|cFFFFFFFF/co channel off|r verlässt den Kanal jetzt wirklich. Zuvor verhinderte es nur das erneute Beitreten beim nächsten Login: deine Aufträge gingen den Rest der Sitzung weiter an den Realm.",
    -- Onglet Nouveautés — v1.12.0
    ["Les recettes de la Saison de la Découverte"] = "Rezepte der Saison der Entdeckungen",
    ["304 recettes de la Saison de la Découverte entrent au catalogue : 80 en Travail du cuir, 65 en Forge, 57 en Couture, 48 en Enchantement, 29 en Ingénierie, 16 en Alchimie, plus la Cuisine, le Secourisme et le Minage. Elles apparaissent dans l'onglet Commande, avec leurs réactifs et leur palier d'apprentissage."] =
        "304 Rezepte der Saison der Entdeckungen kommen in den Katalog: 80 für Lederverarbeitung, 65 für Schmiedekunst, 57 für Schneiderei, 48 für Verzauberkunst, 29 für Ingenieurskunst, 16 für Alchemie, dazu Kochkunst, Erste Hilfe und Bergbau. Sie erscheinen im Auftrags-Tab, mit ihren Reagenzien und Fertigkeitsstufen.",
    ["Elles ne se chargent que sur un royaume Saison de la Découverte. Sur un royaume Era classique, rien ne change : l'addon voit exactement le même jeu de recettes qu'avant, et les recettes que tes amis t'ont déjà partagées restent lisibles."] =
        "Sie werden nur auf einem Realm der Saison der Entdeckungen geladen. Auf einem normalen Era-Realm ändert sich nichts: das Addon sieht genau denselben Rezeptsatz wie zuvor, und die von deinen Freunden geteilten Rezepte bleiben lesbar.",
    -- Onglet Nouveautés — v1.11.0
    ["Annuler une commande publique atteint tout le royaume"] = "Das Abbrechen eines öffentlichen Auftrags erreicht jetzt den ganzen Realm",
    ["Une commande publique voyage sur le canal du royaume depuis la v1.10.0, mais pas son annulation : un artisan que tu n'as jamais croisé la voyait « ouverte » pendant six heures, l'acceptait, et farmait les réactifs pour rien. L'annulation part désormais sur le même canal."] =
        "Ein öffentlicher Auftrag reist seit v1.10.0 über den Realm-Kanal, sein Abbruch jedoch nicht. Ein Handwerker, dem du nie begegnet bist, sah ihn bis zu sechs Stunden lang als offen, konnte ihn annehmen und sammelte die Reagenzien umsonst. Der Abbruch geht jetzt über denselben Kanal.",
    ["Poster et annuler ne perdent plus de messages. Le canal exige un clic ou une touche et n'accepte qu'une ligne par seconde : un |cFFFFFFFF/co post|r tapé au chat, ou deux commandes postées dans la même seconde, disparaissaient sans trace. Ces lignes patientent maintenant dans une file et partent à ton prochain clic."] =
        "Aufgeben und Abbrechen verlieren keine Nachrichten mehr. Der Kanal braucht einen Klick oder Tastendruck und nimmt eine Zeile pro Sekunde: ein im Chat getipptes |cFFFFFFFF/co post|r oder zwei Aufträge in derselben Sekunde verschwanden spurlos. Diese Zeilen warten nun in einer Warteschlange und gehen beim nächsten Klick raus.",
    ["Seules les commandes NOUVELLES et les ANNULATIONS voyagent sur le canal, et seulement les publiques. Guilde, amis et commandes nommées restent privées ; les acceptations restent entre les deux joueurs concernés."] =
        "Nur neue Aufträge und Abbrüche reisen über den Kanal, und nur öffentliche. Gilden-, Freundes- und benannte Aufträge bleiben privat; Annahmen bleiben zwischen den beiden beteiligten Spielern.",
    -- Onglet Nouveautés — v1.10.2
    ["Correctif : erreur en combat dans la vue métier"] = "Behoben: Fehler im Kampf in der Berufsansicht",
    ["Sélectionner une recette pendant un combat ne provoque plus d'erreur bloquée : le bouton « Créer » est un bouton sécurisé, que le jeu interdit de masquer en plein combat. L'addon attend maintenant la fin du combat pour l'afficher ou le masquer."] =
        "Ein Rezept während des Kampfes auszuwählen löst keinen blockierten Fehler mehr aus. Der Erstellen-Knopf ist ein geschützter Knopf, den das Spiel mitten im Kampf nicht verbergen lässt. Das Addon wartet nun das Kampfende ab, um ihn ein- oder auszublenden.",
    -- Onglet Nouveautés — v1.10.1
    ["Corrections : qui reçoit les alertes de commandes"] = "Korrekturen: wer Auftragsbenachrichtigungen erhält",
    ["Les alertes de commandes ne dépendent plus du réglage |cFFFFFFFF/co scan|r : le scanner de chat et le carnet partageaient une option par erreur. Une commande publique te prévient désormais dès que tu as le métier."] =
        "Auftragsbenachrichtigungen hängen nicht mehr von deiner |cFFFFFFFF/co scan|r-Einstellung ab. Der Chat-Scanner und das Auftragsbuch teilten sich versehentlich eine Option. Ein öffentlicher Auftrag benachrichtigt dich jetzt, sobald du den Beruf dafür hast.",
    ["Une commande publique portant un objet absent du catalogue arrivait en silence : elle te prévient maintenant, au lieu de dormir dans le carnet."] =
        "Ein öffentlicher Auftrag mit einem Gegenstand, der nicht im Katalog steht, kam bisher lautlos an. Jetzt benachrichtigt er dich, statt unbemerkt im Auftragsbuch zu liegen.",
    ["Démuter un joueur réarme la détection de spam le concernant ; revenir de la vue métier d'un reroll ne laisse plus les boutons Créer masqués ; et l'addon travaille nettement moins à chaque ligne de chat sur un royaume chargé."] =
        "Das Entstummschalten eines Spielers aktiviert die Spam-Erkennung für ihn wieder; die Rückkehr aus der Berufsansicht eines Twinks lässt die Erstellen-Knöpfe nicht mehr verborgen; und das Addon leistet pro Chat-Zeile auf einem stark besuchten Realm deutlich weniger Arbeit.",
    -- Onglet Nouveautés — v1.14.0
    ["Un panneau pour gérer les mis en sourdine"] = "Ein Panel zur Verwaltung von Stummgeschalteten",
    ["L'onglet Artisans a maintenant une section « En sourdine » : chaque joueur muté y apparaît avec sa raison et le temps restant (ou « permanent »), avec un bouton pour le rétablir directement — plus besoin de deviner qui est encore muté."] =
        "Der Handwerker-Reiter hat jetzt einen Bereich „Stummgeschaltet“: jeder stummgeschaltete Spieler erscheint dort mit Grund und verbleibender Zeit (oder „dauerhaft“), mit einem Knopf, um ihn direkt wieder freizuschalten — kein Rätselraten mehr, wer noch stummgeschaltet ist.",
    -- Onglet Nouveautés — v1.9.0
    ["Tes rerolls réunis : cooldowns partagés, une identité, l'onglet Mes artisans"] =
        "Deine Twinks vereint: geteilte Abklingzeiten, eine Identität, ein Tab „Meine Handwerker“",
    ["Cooldowns de recettes partagés : les autres voient « Transmutation : prête » ou « dans 14h » sur ton infobulle d'artisan — fini de demander en canal si ton Arcanite est dispo."] =
        "Geteilte Rezept-Abklingzeiten: andere sehen „Transmutation: bereit“ oder „in 14h“ in deinem Handwerker-Tooltip — kein Nachfragen im Chat mehr, ob dein Arkanit bereit ist.",
    ["Regroupe tes persos sous une identité (|cFFFFFFFF/co alts on|r) : une commande nommée pour ton alchimiste hors ligne arrive sur le perso où tu es connecté, et tu peux l'accepter depuis n'importe lequel. Vérifié des deux côtés (personne ne peut se faire passer pour le reroll d'autrui). Désactivé par défaut."] =
        "Gruppiere deine Charaktere unter einer Identität (|cFFFFFFFF/co alts on|r): ein Auftrag für deinen offline Alchemisten erreicht den Charakter, auf dem du eingeloggt bist, und du kannst ihn von jedem annehmen. Beidseitig bestätigt (niemand kann sich als fremder Twink ausgeben). Standardmäßig aus.",
    ["Nouvel onglet « Mes artisans » : tous les métiers de ton compte sur le royaume en une vue, comme un seul perso — niveau, recettes connues par catégorie, cooldowns en tête, et quel perso porte chaque recette."] =
        "Neuer Tab „Meine Handwerker“: alle Berufe deines Accounts auf dem Realm in einer Ansicht, wie ein einziger Charakter — Stufe, bekannte Rezepte nach Kategorie, Abklingzeiten oben, und welcher Charakter jedes Rezept kennt.",
    ["VU"] = "GESEHEN",
    ["vu crafter (sans l'addon)"] = "beim Herstellen gesehen (ohne Addon)",
    ["vu crafter"] = "beim Herstellen gesehen",
    ["%d+ · vu crafter"] = "%d+ · beim Herstellen gesehen",
    -- Cooldowns de recettes (transmutations & co)
    ["%s : prête"] = "%s: bereit",
    ["%s : dans %s"] = "%s: in %s",
    ["(estimé)"] = "(geschätzt)",
    ["Transmutation"] = "Transmutation",
    ["%dj"] = "%dT", ["%dh"] = "%dh", ["%dmin"] = "%dMin",
    -- Relais partenaire
    ["via %s · il y a %s"] = "via %s · vor %s",
    ["RELAIS"] = "RELAIS",
    -- Rerolls (identité joueur multi-persos, /co alts — opt-in)
    ["rerolls : ACTIVÉS — ta liste de persos est annoncée au réseau."] =
        "Twinks: AKTIVIERT — deine Charakterliste wird im Netzwerk angekündigt.",
    ["rerolls : désactivés — rien n'est annoncé (opt-in : /co alts on)."] =
        "Twinks: deaktiviert — nichts wird angekündigt (Opt-in: /co alts on).",
    ["perso principal (vitrine) : %s"] = "Hauptcharakter (Aushängeschild): %s",
    ["persos du compte (%s) : %s"] = "Charaktere des Accounts (%s): %s",
    ["le lien n'est vérifié chez les autres qu'après une connexion de CHAQUE perso (addon actif)."] =
        "Andere bestätigen die Verknüpfung erst, wenn sich JEDER Charakter einmal eingeloggt hat (Addon aktiv).",
    ["rerolls activés — perso principal : %s (changer : /co alts main <nom>)"] =
        "Twinks aktiviert — Hauptcharakter: %s (ändern: /co alts main <Name>)",
    ["rerolls désactivés — dissolution annoncée au réseau."] =
        "Twinks deaktiviert — Auflösung im Netzwerk angekündigt.",
    ["perso inconnu sur ce compte : %s (connecte-le une fois avec l'addon)"] =
        "Unbekannter Charakter auf diesem Account: %s (einmal mit dem Addon einloggen)",
    ["regrouper tes rerolls (opt-in) : liste annoncée, commandes routées vers ton perso connecté"] =
        "Twinks gruppieren (Opt-in): Liste angekündigt, Aufträge zu deinem Online-Charakter geleitet",
    ["commande nommée pour %s : connecte ce perso, ou active /co alts on pour accepter d'ici."] =
        "Auftrag benannt für %s: logge diesen Charakter ein oder aktiviere /co alts on, um von hier anzunehmen.",
    ["|cFFFFCC00commande pour ton reroll %s|r de |cFFFFFFFF%s|r : %s%s%s"] =
        "|cFFFFCC00Auftrag für deinen Twink %s|r von |cFFFFFFFF%s|r: %s%s%s",
    ["En ligne via %s"] = "Online über %s",
    ["reroll : %s (%s)"] = "Twink: %s (%s)",
}

for k, v in pairs(news) do L[k] = v end
