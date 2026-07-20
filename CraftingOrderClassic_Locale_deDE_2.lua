-- CraftingOrderClassic_Locale_deDE_2.lua — overlay deDE, 2/2. Clé FR → texte traduit.
-- Suite de _Locale_deDE.lua, scindé pour rester sous le plafond anti-monolithe (500 l/fichier).
-- Même contrat : chargé APRÈS _Locale.lua, table à plat fusionnée dans COC.L — les deux moitiés
-- sont indépendantes (aucun ordre requis entre elles). Client d'une autre langue : early-return.

local COC = CraftingOrderClassic
if (GetLocale and GetLocale() or "") ~= "deDE" then return end
local L = COC.L

local de2 = {
    -- Arbeitssuche (LFW) : /co lfw
    ["[Dispo]"] = "[Sucht]",
    ["Chercher du travail"] = "Arbeit suchen", ["scan LFW du chat : |cFF33DD33activé|r"] = "Chat-LFW-Scan: |cFF33DD33an|r", ["scan LFW du chat : |cFFFFCC00désactivé|r"] = "Chat-LFW-Scan: |cFFFFCC00aus|r", ["propose : %s"] = "bietet an: %s", ["Proposer cette recette (recherche de travail)"] = "Dieses Rezept anbieten (Arbeit suchen)", ["Maximum %d recettes proposées."] = "Höchstens %d angebotene Rezepte.",
    ["Tu cherches du travail — clic pour arrêter."] = "Du suchst Arbeit — Klick zum Beenden.",
    ["Signale au royaume que tu cherches du travail dans ce métier."] = "Sag dem Realm, dass du in diesem Beruf Arbeit suchst.",
    ["recherche de travail : |cFF33DD33%s|r — /co lfw off pour arrêter"] = "Arbeit gesucht: |cFF33DD33%s|r — /co lfw off zum Beenden",
    ["recherche de travail : |cFFFFCC00désactivée|r — /co lfw <métier>"] = "Arbeit gesucht: |cFFFFCC00aus|r — /co lfw <Beruf>",
    ["recherche de travail arrêtée."] = "Arbeitssuche beendet.",
    ["tu n'as pas le métier %s — impossible de chercher du travail dessus."] = "du hast %s nicht — kannst darin keine Arbeit suchen.",
    ["recherche de travail : |cFF33DD33%s|r — visible au royaume"] = "Arbeit gesucht: |cFF33DD33%s|r — realmweit sichtbar",
    -- Offre LFW (panneau de config par métier + tooltips + tris progression)
    ["Configurer l'offre : composants fournis, commission…"] = "Angebot einstellen: gestellte Materialien, Gebühr…",
    ["Recherche de travail — %s"] = "Arbeitssuche — %s",
    ["Je fournis les composants de base"] = "Ich stelle die Grundmaterialien",
    ["(achetables chez un marchand)"] = "(die beim Händler erhältlichen)",
    ["Seulement si le plan me fait progresser"] = "Nur wenn das Rezept mich skillt",
    ["(restriction sur les composants fournis)"] = "(Einschränkung der gestellten Materialien)",
    ["Commission fixe par craft :"] = "Feste Gebühr pro Herstellung:",
    ["Composants fournis (%d/%d)"] = "Gestellte Materialien (%d/%d)",
    ["Maximum %d composants fournis."] = "Höchstens %d gestellte Materialien.",
    ["Cherche du travail : %s"] = "Sucht Arbeit: %s",
    ["fournit les composants de base (marchand)"] = "stellt die Grundmaterialien (Händler)",
    ["fournit : %s"] = "stellt: %s",
    ["commission : %s par craft"] = "Gebühr: %s pro Herstellung",
    ["composants fournis seulement si le plan fait progresser"] = "Materialien nur gestellt, wenn das Rezept skillt",
    ["Trier par montée de compétence (plans orange d'abord)."] = "Nach Skillpunkten sortieren (orange Rezepte zuerst).",
    ["Tri par montée de compétence — clic pour A-Z."] = "Nach Skillpunkten sortiert — Klick für A-Z.",
    ["Par progression"] = "Nach Skillpunkten",
    ["Trier : les commandes qui me font progresser d'abord."] = "Sortieren: Aufträge, die mich skillen, zuerst.",
    ["Progression d'abord — clic pour revenir aux récentes."] = "Skillpunkte zuerst — Klick für die neuesten zuerst.",
    ["|cFF66CCFFamis/partenaires intéressés :|r %s (|cFFFFFFFF/co gift <nom>|r)"] =
        "|cFF66CCFFinteressierte Freunde/Partner:|r %s (|cFFFFFFFF/co gift <Name>|r)",
    ["proposer (chuchoter) le dernier plan looté à un ami/partenaire qui ne le connaît pas"] =
        "das zuletzt erbeutete Rezept einem Freund/Partner anbieten (flüstern), der es nicht kennt",
    ["aucun plan looté en attente de don pour l'instant."] = "derzeit kein erbeutetes Rezept, das auf ein Geschenk wartet.",
    ["don en attente pour |cFFFFFFFF%s|r — amis/partenaires : %s (|cFFFFFFFF/co gift <nom>|r)"] =
        "Geschenk ausstehend für |cFFFFFFFF%s|r — Freunde/Partner: %s (|cFFFFFFFF/co gift <Name>|r)",
    ["|cFFFFFFFF%s|r n'est pas dans la liste des amis/partenaires en attente pour ce plan."] =
        "|cFFFFFFFF%s|r ist nicht in der Freunde-/Partnerliste für dieses Rezept.",
    ["Salut ! J'ai looté %s (%s) — tu ne le connais pas encore, ça t'intéresse ?"] =
        "Hallo! Ich habe %s (%s) erbeutet — du kennst es noch nicht, hast du Interesse?",
    ["don proposé à |cFFFFFFFF%s|r pour %s."] = "Geschenk an |cFFFFFFFF%s|r für %s angeboten.",
    ["|cFF66CCFFtu sais le faire|r — demandé par |cFFFFFFFF%s|r : %s%s%s"] =
        "|cFF66CCFFdu kannst das herstellen|r — angefragt von |cFFFFFFFF%s|r: %s%s%s",
    ["%s peut faire une commande captée — gardée pour son passage : %s"] =
        "%s kann einen erfassten Auftrag herstellen — für seinen Besuch aufbewahrt: %s",
    ["Confiées"] = "Anvertraut", ["Remis"] = "Gesendet",
    ["Aucune commande confiée pour l'instant."] = "Noch keine anvertrauten Aufträge.",
    ["canal : |cFFFFFFFF%s|r"] = "Kanal: |cFFFFFFFF%s|r",
    ["canal : non rejoint — |cFFFFFFFF/co channel on|r pour réessayer"] =
        "Kanal: nicht beigetreten — |cFFFFFFFF/co channel on|r zum Wiederholen",
    ["auto-join du canal réseau désactivé — le carnet global ne fonctionnera plus (whisper/guilde restent actifs)."] =
        "Auto-Beitritt zum Netzwerkkanal deaktiviert — das globale Auftragsbuch funktioniert nicht mehr (Flüstern/Gilde bleiben aktiv).",
    ["canal réseau (re)rejoint."] = "Netzwerkkanal (wieder) beigetreten.",
    ["canal global actuel : |cFFFFFFFF%s|r. |cFFFFFFFF/co channel off|r pour le quitter, |cFFFFFFFF/co channel on|r pour le rejoindre."] =
        "aktueller globaler Kanal: |cFFFFFFFF%s|r. |cFFFFFFFF/co channel off|r zum Verlassen, |cFFFFFFFF/co channel on|r zum Beitreten.",
    ["(dés)activer le canal réseau global"] = "den globalen Netzwerkkanal (de)aktivieren",
    ["balise TEXTE émise=%s (canal idx=%s) — lance |cFFFFFFFF/co trace dump|r sur l'AUTRE perso et cherche |cFFFFFFFF[recv] beacon|r."] =
        "TEXT-Bake gesendet=%s (Kanal idx=%s) — führe |cFFFFFFFF/co trace dump|r auf dem ANDEREN Char aus und suche |cFFFFFFFF[recv] beacon|r.",
    ["annuaire local vidé (diag) — exécute aussi |cFFFFFFFF/co wipe|r sur l'autre compte pour un test de découverte propre."] =
        "lokales Verzeichnis geleert (Diag) — führe auch |cFFFFFFFF/co wipe|r auf dem anderen Konto aus für einen sauberen Entdeckungstest.",
    ["Crafting Order rejoint un canal dédié (|cFFFFD100%s|r) pour faire circuler le carnet de commandes entre joueurs de l'addon. Tu le verras dans ta liste de canaux ; aucun message lisible n'y est envoyé. Tu peux le quitter à tout moment — |cFFFFFFFF/co channel off|r."] =
        "Crafting Order tritt einem eigenen Kanal bei (|cFFFFD100%s|r), um das Auftragsbuch zwischen Addon-Nutzern zu übertragen. Du siehst ihn in deiner Kanalliste; es wird kein lesbarer Text gesendet. Du kannst ihn jederzeit verlassen — |cFFFFFFFF/co channel off|r.",
    ["Aide"] = "Hilfe",
    ["C'est quoi Crafting Order ?"] = "Was ist Crafting Order?",
    ["Réseau GLOBAL et SOCIAL de commandes de craft — fonctionne sans guilde, entre tous les joueurs de l'addon."] =
        "GLOBALES und SOZIALES Netzwerk für Handwerksaufträge — funktioniert ohne Gilde, zwischen allen Addon-Nutzern.",
    ["Poste ce dont tu as besoin, ou consulte les commandes que tu peux honorer avec tes métiers."] =
        "Erstelle, was du brauchst, oder sieh dir die Aufträge an, die du mit deinen Berufen erfüllen kannst.",
    ["Ouvrir la fenêtre et commandes utiles"] = "Fenster öffnen und nützliche Befehle",
    ["Clic gauche sur l'icône minimap (ou |cFFFFFFFF/co|r) : ouvre cette fenêtre."] =
        "Linksklick auf das Minikarten-Symbol (oder |cFFFFFFFF/co|r): öffnet dieses Fenster.",
    ["Clic droit sur l'icône minimap (ou |cFFFFFFFF/co métier|r) : ouvre la Vue Métier d'un de tes métiers."] =
        "Rechtsklick auf das Minikarten-Symbol (oder |cFFFFFFFF/co métier|r): öffnet die Berufsansicht eines deiner Berufe.",
    ["|cFFFFFFFF/co help|r dans le chat : liste complète des commandes slash."] =
        "|cFFFFFFFF/co help|r im Chat: vollständige Liste der Slash-Befehle.",
    ["|cFFFFFFFF/co channel off|r / |cFFFFFFFF/co channel on|r : quitter/rejoindre le canal réseau."] =
        "|cFFFFFFFF/co channel off|r / |cFFFFFFFF/co channel on|r: Netzwerkkanal verlassen/beitreten.",
    ["Les 4 onglets de cette fenêtre"] = "Die 4 Tabs dieses Fensters",
    ["|cFFE8B84BCarnet|r : tes commandes à toi (postées), en cours ou archivées."] =
        "|cFFE8B84BAuftragsbuch|r: deine eigenen (erstellten) Aufträge, aktiv oder archiviert.",
    ["|cFFE8B84BCommande|r : poster une demande de craft à faire réaliser par un artisan."] =
        "|cFFE8B84BBestellen|r: eine Handwerksanfrage erstellen, die ein Handwerker erfüllt.",
    ["|cFFE8B84BRécolte|r : poster une demande de matières à un récolteur (mine, herbe, peau, pêche)."] =
        "|cFFE8B84BSammeln|r: eine Materialanfrage an einen Sammler stellen (Bergbau, Kräuter, Leder, Angeln).",
    ["|cFFE8B84BArtisans|r : l'annuaire — qui sait crafter quoi, en ligne ou non."] =
        "|cFFE8B84BHandwerker|r: das Verzeichnis — wer was herstellen kann, online oder nicht.",
    ["Poster une commande de craft"] = "Einen Handwerksauftrag erstellen",
    ["Onglet |cFFE8B84BCommande|r → choisis un métier puis un plan dans la liste."] =
        "Tab |cFFE8B84BBestellen|r → wähle einen Beruf, dann ein Rezept aus der Liste.",
    ["Shift-clic un objet dans un sac ou un lien de chat pour le présélectionner s'il correspond à un plan."] =
        "Umschalt-Klick auf einen Gegenstand im Beutel oder einen Chatlink, um ihn vorzuwählen, wenn er einem Rezept entspricht.",
    ["Coche les réactifs que TU fournis toi-même (le reste reste à la charge de l'artisan)."] =
        "Hake die Materialien an, die DU selbst bereitstellst (der Rest bleibt Sache des Handwerkers).",
    ["Choisis la quantité, la commission proposée, puis le destinataire (guilde, amis, un artisan précis, ou diffuser à tous)."] =
        "Wähle die Menge, die gebotene Provision, dann den Empfänger (Gilde, Freunde, einen bestimmten Handwerker oder an alle senden).",
    ["Clique |cFFE8B84BPoster|r : la commande apparaît dans ton Carnet et chez les artisans concernés."] =
        "Klicke |cFFE8B84BErstellen|r: der Auftrag erscheint in deinem Auftragsbuch und bei den betreffenden Handwerkern.",
    ["Poster une commande de récolte"] = "Einen Sammelauftrag erstellen",
    ["Onglet |cFFE8B84BRécolte|r → choisis un métier de récolte puis une ressource."] =
        "Tab |cFFE8B84BSammeln|r → wähle einen Sammelberuf, dann eine Ressource.",
    ["Choisis à l'unité ou par pile, la quantité voulue et le prix proposé, puis le destinataire."] =
        "Wähle pro Stück oder pro Stapel, die gewünschte Menge und den gebotenen Preis, dann den Empfänger.",
    ["Fonctionne comme une commande de craft, mais ciblée sur les joueurs qui ont le métier de récolte, pas de recette à connaître."] =
        "Funktioniert wie ein Handwerksauftrag, richtet sich aber an Spieler mit dem Sammelberuf — kein Rezept nötig.",
    ["Accepter / livrer une commande — la Vue Métier"] = "Einen Auftrag annehmen / liefern — die Berufsansicht",
    ["L'acceptation et la livraison ne se font PAS dans le Carnet : ouvre la |cFFE8B84BVue Métier|r du métier concerné (clic droit minimap, ou |cFFFFFFFF/co métier <nom>|r)."] =
        "Annehmen und Liefern geschehen NICHT im Auftragsbuch: öffne die |cFFE8B84BBerufsansicht|r des betreffenden Berufs (Rechtsklick Minikarte, oder |cFFFFFFFF/co métier <Name>|r).",
    ["La 3ᵉ colonne de la Vue Métier liste toutes les commandes de ce métier : accepte, crafte, puis livre."] =
        "Die 3. Spalte der Berufsansicht listet alle Aufträge dieses Berufs: annehmen, herstellen, dann liefern.",
    ["Les demandes captées dans |cFFE8B84B/commerce|r et |cFFE8B84B/guilde|r de joueurs sans l'addon apparaissent aussi ici, marquées « entrante »."] =
        "Anfragen aus |cFFE8B84B/Handel|r und |cFFE8B84B/Gilde|r von Spielern ohne Addon erscheinen ebenfalls hier, als « eingehend » markiert.",
    ["Un artisan connu qui sait honorer une commande captée est notifié à sa prochaine connexion (voir « Confiées » dans le Carnet)."] =
        "Ein bekannter Handwerker, der einen erfassten Auftrag erfüllen kann, wird bei seiner nächsten Anmeldung benachrichtigt (siehe « Anvertraut » im Auftragsbuch).",
    ["Le Carnet en détail"] = "Das Auftragsbuch im Detail",
    ["|cFFE8B84BEn cours|r : tes commandes ouvertes ou acceptées par un artisan."] =
        "|cFFE8B84BAktiv|r: deine offenen oder von einem Handwerker angenommenen Aufträge.",
    ["|cFFE8B84BArchivées|r : tes commandes livrées ou annulées."] =
        "|cFFE8B84BArchiviert|r: deine gelieferten oder abgebrochenen Aufträge.",
    ["|cFFE8B84BConfiées|r : commandes gardées pour un artisan connu capable de les honorer, en attendant qu'il se reconnecte."] =
        "|cFFE8B84BAnvertraut|r: Aufträge, die für einen bekannten fähigen Handwerker aufbewahrt werden, bis er sich wieder anmeldet.",
    ["Depuis le Carnet, tu peux annuler une commande tant qu'elle n'est pas livrée."] =
        "Im Auftragsbuch kannst du einen Auftrag abbrechen, solange er nicht geliefert ist.",
    ["Annuaire & social"] = "Verzeichnis & Soziales",
    ["L'onglet Artisans liste les joueurs connus par source : guilde, amis, ajoutés manuellement, croisés récemment."] =
        "Der Tab Handwerker listet bekannte Spieler nach Quelle: Gilde, Freunde, manuell hinzugefügt, kürzlich getroffen.",
    ["Survole un joueur (tooltip) pour voir ses métiers et son niveau de compétence."] =
        "Fahre über einen Spieler (Tooltip), um seine Berufe und seine Fertigkeitsstufe zu sehen.",
    ["Clic droit sur un joueur (chat, groupe...) pour l'ajouter à ton annuaire — utile pour le retrouver même hors ligne."] =
        "Rechtsklick auf einen Spieler (Chat, Gruppe...), um ihn deinem Verzeichnis hinzuzufügen — nützlich, um ihn auch offline wiederzufinden.",
    ["Pastille verte : il a l'addon et répond. Jaune : en ligne sans l'addon. Grise : hors ligne."] =
        "Grüner Punkt: hat das Addon und antwortet. Gelb: online ohne Addon. Grau: offline.",
    ["Réseau, confidentialité & statuts"] = "Netzwerk, Privatsphäre & Status",
    ["L'addon rejoint un canal dédié pour faire circuler le carnet entre joueurs de l'addon — aucun message lisible n'y est envoyé."] =
        "Das Addon tritt einem eigenen Kanal bei, um das Auftragsbuch zwischen Addon-Nutzern zu übertragen — es wird kein lesbarer Text gesendet.",
    ["|cFFFFFFFF/co channel off|r le quitte à tout moment (whisper et guilde restent actifs) ; |cFFFFFFFF/co channel on|r le rejoint."] =
        "|cFFFFFFFF/co channel off|r verlässt ihn jederzeit (Flüstern und Gilde bleiben aktiv); |cFFFFFFFF/co channel on|r tritt wieder bei.",
    ["Statuts d'une commande : "] = "Auftragsstatus: ",

    -- Aide contextuelle « bouton i » (Vue Métier) — cf. _ProfWindow_HelpPlate.lua (bulles courtes)
    ["Aide : survole les zones surlignées pour comprendre chaque fonction."] =
        "Hilfe: Bewege den Mauszeiger über die hervorgehobenen Bereiche, um jede Funktion zu verstehen.",
    ["Barre de filtres. À gauche (avec Lazy Gold) : pièce = trier par rentabilité, « 123 » = prix exacts au lieu de l'indicateur compact, flèche verte = trier par montée de compétence, carte = plan de route (quoi crafter jusqu'au plafond, au moins cher). Au centre : la recherche. À droite : sac = seulement les recettes dont tu as les matériaux, flèche orange = masquer les recettes grises (aucun gain de compétence)."] =
        "Filterleiste. Links (mit Lazy Gold): Münze = nach Gewinn sortieren, „123“ = exakte Preise statt der kompakten Anzeige, grüner Pfeil = nach Fertigkeitsanstieg sortieren, Karte = Levelroute (was du bis zum Maximum am günstigsten craften solltest). Mitte: die Suche. Rechts: Beutel = nur Rezepte, für die du das Material hast, oranger Pfeil = graue Rezepte ausblenden (kein Fertigkeitsgewinn).",
    ["Tes recettes, groupées par famille (clique un en-tête pour replier). À droite de chaque ligne : %s = rentabilité à l'HV (survole pour le profit net exact), %s = plan conseillé pour monter le métier (meilleur coût par point), « ×N » doré = commandes en attente pour cet objet. En mode Manquantes, une icône dit où obtenir le plan : formateur, vendeur, HV ou à farmer."] =
        "Deine Rezepte, nach Familie gruppiert (Kopfzeile anklicken zum Einklappen). Rechts an jeder Zeile: %s = Gewinn im AH (für den genauen Nettogewinn mit der Maus darüberfahren), %s = empfohlenes Rezept zum Hochleveln (bestes Preis-Leistungs-Verhältnis pro Punkt), goldenes „×N“ = ausstehende Aufträge für diesen Gegenstand. Im Modus Fehlende zeigt ein Symbol, wo du das Rezept bekommst: Lehrer, Händler, AH oder zu farmen.",
    ["Le plan sélectionné : ses réactifs et le bouton pour le fabriquer."] =
        "Das ausgewählte Rezept: seine Reagenzien und die Schaltfläche zum Herstellen.",
    ["Les commandes reçues pour ce métier — accepte, crafte, livre. Les onglets filtrent la source (tous / guilde / amis / annuaire)."] =
        "Für diesen Beruf erhaltene Aufträge – annehmen, herstellen, liefern. Die Reiter filtern die Quelle (alle / Gilde / Freunde / Verzeichnis).",
    ["Chercher du travail : signale au royaume que tu proposes ce métier. L'engrenage voisin règle ton offre (composants fournis, commission)."] =
        "Arbeit suchen: Teile dem Realm mit, dass du diesen Beruf anbietest. Das Zahnrad daneben stellt dein Angebot ein (bereitgestellte Reagenzien, Gebühr).",
    ["Vue Blizzard : rebascule sur la fenêtre de métier native de Blizzard."] =
        "Blizzard-Ansicht: zurück zum nativen Berufsfenster von Blizzard wechseln.",
    ["Filtre les commandes par source : tous, ta guilde, tes amis, ou ton annuaire d'artisans."] =
        "Aufträge nach Quelle filtern: alle, deine Gilde, deine Freunde oder dein Handwerker-Verzeichnis.",

    -- Aide contextuelle « bouton i » — onglet Commande (cf. _UI_HelpPlate.lua)
    ["Filtre les plans : recherche par nom, filtre par qualité, filtre par réactif, et l'outil %s « 123 » de Lazy Gold (prix/rentabilité)."] =
        "Filtert die Rezepte: Suche nach Name, Filter nach Qualität, Filter nach Reagenz und Lazy Golds Werkzeug %s „123“ (Preis/Gewinn).",
    ["La liste des plans. Choisis celui que tu veux faire réaliser par un artisan."] =
        "Die Rezeptliste. Wähle das, das ein Handwerker herstellen soll.",
    ["L'objet choisi. La pastille « Je fournis » indique que tu apportes tous les composants toi-même."] =
        "Der gewählte Gegenstand. Die Plakette „Ich liefere“ bedeutet, dass du alle Reagenzien selbst mitbringst.",
    ["La commission que tu proposes à l'artisan pour ce craft."] =
        "Die Provision, die du dem Handwerker für diese Herstellung anbietest.",
    ["La portée : diffuser à tous, ou restreindre (guilde / amis)."] =
        "Die Reichweite: an alle senden oder einschränken (Gilde / Freunde).",
    ["Le destinataire : toute la source sélectionnée, ou un artisan précis."] =
        "Der Empfänger: die gesamte gewählte Quelle oder ein bestimmter Handwerker.",
    ["Poster : envoie la commande au(x) destinataire(s) choisi(s)."] =
        "Aufgeben: Sende den Auftrag an die gewählten Empfänger.",

    -- Aide contextuelle « bouton i » — onglet Récolte (cf. _UI_HelpPlate.lua)
    ["Recherche une ressource par nom."] = "Suche eine Ressource nach Namen.",
    ["Extensions : filtre les ressources d'une extension (ex. Élémentaire)."] =
        "Erweiterungen: filtert Ressourcen einer Erweiterung (z. B. Elementar).",
    ["La liste des ressources. Choisis celle que tu veux faire récolter."] =
        "Die Ressourcenliste. Wähle die, die gesammelt werden soll.",
    ["La ressource choisie."] = "Die gewählte Ressource.",
    ["À l'unité ou par pile, et la quantité voulue."] = "Pro Einheit oder pro Stapel und die gewünschte Menge.",
    ["Le prix que tu proposes au récolteur."] = "Der Preis, den du dem Sammler anbietest.",
    ["Le destinataire : toute la source, ou un récolteur précis."] =
        "Der Empfänger: die gesamte Quelle oder ein bestimmter Sammler.",

    -- Aide contextuelle « bouton i » — onglet Artisans (cf. _UI_HelpPlate.lua)
    ["Filtre l'annuaire par source : guilde, amis, ajoutés manuellement, croisés, ou les joueurs en sourdine."] =
        "Filtert das Verzeichnis nach Quelle: Gilde, Freunde, manuell hinzugefügt, kürzlich getroffen oder stummgeschaltete Spieler.",
    ["Ajoute un joueur manuellement (+), rafraîchis l'annuaire, ou active le repérage."] =
        "Füge einen Spieler manuell hinzu (+), aktualisiere das Verzeichnis oder aktiviere die Erfassung.",
    ["Filtre les artisans par métier."] = "Filtert Handwerker nach Beruf.",
    ["La liste des artisans connus. Survole un nom pour ses métiers ; pastille verte = a l'addon et répond, jaune = en ligne sans l'addon, grise = hors ligne."] =
        "Die Liste bekannter Handwerker. Fahre über einen Namen für seine Berufe; grüner Punkt = hat das Addon und antwortet, gelb = online ohne Addon, grau = offline.",

    -- Aide contextuelle « bouton i » — onglet Mes artisans (cf. _UI_HelpPlate.lua)
    ["Partage tes rerolls sur le réseau (les autres voient tes métiers), et choisis le perso mis en « vitrine »."] =
        "Teile deine Twinks im Netzwerk (andere sehen deine Berufe) und wähle den Charakter für die „Auslage“.",
    ["Tous les plans du royaume : la liste agrégée de toutes tes recettes, au lieu du découpage par métier (Lazy Gold requis)."] =
        "Alle Rezepte des Realms: die zusammengeführte Liste all deiner Rezepte statt der Aufteilung nach Beruf (Lazy Gold erforderlich).",
    ["Tes métiers (tous les persos du compte). Choisis-en un pour voir ses recettes à droite."] =
        "Deine Berufe (alle Charaktere des Kontos). Wähle einen, um rechts seine Rezepte zu sehen.",
    ["En-tête des recettes du métier choisi : bouton « Manquantes » et outils de prix (Lazy Gold)."] =
        "Kopfzeile der Rezepte des gewählten Berufs: Schaltfläche „Fehlende“ und Preiswerkzeuge (Lazy Gold).",
    ["Les recettes du métier sélectionné (ou tous les plans du royaume)."] =
        "Die Rezepte des ausgewählten Berufs (oder alle Rezepte des Realms).",

    -- Aide contextuelle « bouton i » — onglet Carnet (cf. _UI_HelpPlate.lua)
    ["Filtre ton carnet : commandes En cours, Archivées, ou Confiées (gardées pour un artisan)."] =
        "Filtere dein Auftragsbuch: Aktive, Archivierte oder Anvertraute Aufträge (für einen Handwerker aufbewahrt).",
    ["Le Carnet = TES commandes postées. Accepter/livrer se fait dans la Vue Métier, pas ici ; quand une commande t'est remise, le bouton « J'ai reçu » confirme la réception."] =
        "Das Auftragsbuch = DEINE aufgegebenen Aufträge. Annehmen/Liefern passiert in der Berufsansicht, nicht hier; wenn dir ein Auftrag übergeben wird, bestätigt die Schaltfläche „Erhalten“ den Empfang.",

    -- Popup dépendance optionnelle manquante (boutons Lazy Gold / MTSL toujours visibles)
    ["Cette fonction nécessite l'addon |cFFFFD100%s|r (non installé ou désactivé). Installe-le pour en profiter."] =
        "Diese Funktion benötigt das Addon |cFFFFD100%s|r (nicht installiert oder deaktiviert). Installiere es, um sie zu nutzen.",

    -- Sous-catégories de recettes (vue métier) — voir _RecipeCats_*.lua
    ["Divers"] = "Sonstiges",
    ["Potions de soin"] = "Heiltränke",
    ["Potions de mana"] = "Manatränke",
    ["Flacons"] = "Fläschchen",
    ["Élixirs de force"] = "Stärke-Elixiere",
    ["Élixirs d'agilité"] = "Beweglichkeits-Elixiere",
    ["Élixirs d'endurance"] = "Ausdauer-Elixiere",
    ["Élixirs de défense"] = "Verteidigungs-Elixiere",
    ["Élixirs d'esprit"] = "Intelligenz- & Willenskraft-Elixiere",
    ["Élixirs de puissance des sorts"] = "Zaubermacht-Elixiere",
    ["Élixirs de puissance d'attaque"] = "Angriffskraft-Elixiere",
    ["Élixirs de vision"] = "Sicht-Elixiere",
    ["Potions de protection"] = "Schutztränke",
    ["Potions de combat"] = "Kampftränke",
    ["Potions de régénération"] = "Regenerationstränke",
    ["Potions utilitaires"] = "Nutztränke",
    ["Huiles"] = "Öle",
    ["Transmutations"] = "Transmutationen",
    ["Minerais"] = "Erze",
    ["Lingots"] = "Barren",
    ["Cuirs"] = "Leder",
    ["Éclats"] = "Splitter",
    ["Essences"] = "Essenzen",
    ["Poussières"] = "Staub",
    -- ⚠️ Clés DYNAMIQUES (L[group.name] dans RecipeCats) : le checker ne les voit pas — tenir cette
    -- liste alignée sur les `name =` des _RecipeCats_*.lua à chaque régénération (bug live sosh13).
    ["Peaux"] = "Felle",
    ["Écailles"] = "Schuppen",
    ["Herbes"] = "Kräuter",
    ["Poissons"] = "Fische",

    -- Sous-catégories d'ENCHANTEMENT (clés DYNAMIQUES : STAT_L dans _Enchant.lua). Ce sont les seules
    -- stats de base dont le libellé ne se lit pas sur le client — toutes les autres viennent de
    -- GetSpellInfo, donc déjà traduites par Blizzard. Ne pas allonger cette liste sans raison.
    ["Absorption"] = "Absorption",
    ["Résistance aux Arcanes"] = "Arkanwiderstand",
    ["Armure"] = "Rüstung",
    ["Tueur de bêtes"] = "Bestientöter",
    ["Soins"] = "Heilung",
    ["Résistance à la Nature"] = "Naturwiderstand",
    ["Protection"] = "Schutz",
    ["Résistance à l'Ombre"] = "Schattenwiderstand",

    -- Pont MissingTradeSkillsList (recettes manquantes + source)
    ["Manquantes"] = "Fehlend",
    ["Manquantes (%d)"] = "Fehlend (%d)",
    ["‹ Apprises seules"] = "‹ Nur gelernte",
    ["Masque les recettes non apprises — clic pour revenir."] = "Nicht gelernte Rezepte ausblenden — Klick zum Zurück.",
    ["Affiche AUSSI les recettes non apprises (en rouge) et où les obtenir."] = "Zeigt auch nicht gelernte Rezepte (in Rot) und wo du sie bekommst.",
    ["niveau"] = "Stufe",
    ["niv."] = "St.",
    ["Non apprise"] = "Nicht gelernt",
    ["Où l'obtenir"] = "Wo zu bekommen",
    ["Niveau requis"] = "Benötigte Stufe",
    ["Obtenu via"] = "Erhalten über",
    ["Prix"] = "Preis",
    ["Appris de"] = "Gelernt von",
    ["Vendeur"] = "Händler",
    ["Vendu par"] = "Verkauft von",
    ["Butin sur"] = "Beute von",
    ["Formateurs"] = "Lehrer",
    ["Formateur"] = "Lehrer",
    ["Réputation"] = "Ruf",
    ["Quête"] = "Quest",
    ["Butin"] = "Beute",
    ["Source inconnue"] = "Unbekannte Quelle",

    -- Pont Lazy Gold (rentabilité)
    ["Rentabilité"] = "Rentabilität",
    ["Vente HV"] = "AH-Verkauf",
    ["Profit net"] = "Nettogewinn",
    ["Valeur HV"] = "AH-Wert",
    ["Par rentabilité"] = "Nach Gewinn",
    ["Meilleur plan"] = "Bester Plan",
    ["Tous les plans du royaume"] = "Alle Realm-Pläne",
    ["%d métiers"] = "%d Berufe",
    ["À ma charge"] = "Mein Anteil",
    ["Valeurs exactes — clic pour l'affichage compact."] = "Exakte Werte — Klick für kompakte Anzeige.",
    ["Afficher les valeurs exactes (po/pa/pc)."] = "Exakte Werte anzeigen (G/S/K).",
    ["Clic : commander ce métier"] = "Klick: diesen Beruf beauftragen",
    ["Trier par rentabilité (Lazy Gold)."] = "Nach Rentabilität sortieren (Lazy Gold).",
    ["Tri par rentabilité — clic pour A-Z."] = "Nach Gewinn sortiert — Klick für A-Z.",
    ["N'afficher que les recettes dont j'ai les matériaux."] = "Nur Rezepte anzeigen, für die du das Material hast.",
    ["Filtre matériaux actif — clic pour tout afficher."] = "Materialfilter aktiv — Klick zeigt alle.",
    ["N'afficher que les recettes qui font monter la compétence (masque le gris)."] = "Nur Rezepte anzeigen, die den Beruf steigern (blendet Grau aus).",
    ["Filtre progression actif — clic pour tout afficher."] = "Fortschrittsfilter aktiv — Klick zeigt alle.",
    ["N'afficher que les recettes acquérables (formateur, vendeur ou HV)."] = "Nur beschaffbare Rezepte anzeigen (Lehrer, Händler oder AH).",
    ["Filtre acquérables actif — clic pour tout afficher."] = "Beschaffbar-Filter aktiv — Klick zeigt alle.",
    ["Acheter à l'HV"] = "Im AH kaufen",
    -- Diffuser les réactifs (liste de courses)
    ["Diffuser les réactifs"] = "Reagenzien ansagen",
    ["Diffuser les réactifs dans un canal"] = "Die Reagenzien in einem Kanal ansagen",
    ["Canal : "] = "Kanal: ",
    ["Dire"] = "Sagen", ["Groupe"] = "Gruppe", ["Raid"] = "Schlachtzug", ["Envoyer"] = "Senden",
    ["Réactifs pour %s :"] = "Reagenzien für %s:",
    ["Réactifs pour %s (%d) :"] = "Reagenzien für %s (%d):",
    ["choisis un canal valide."] = "wähle einen gültigen Kanal.",
    ["aucun réactif à diffuser."] = "keine Reagenzien zum Ansagen.", ["Diffuser"] = "Ansagen",
    -- Aide à la montée de métier (Leveling)
    ["Progression : ~%s par point (estimation)"] = "Skillen: ~%s pro Punkt (Schätzung)",
    ["Meilleur coût/point pour monter le métier"] = "Bestes Kosten-pro-Punkt-Verhältnis zum Skillen",
    ["Plan : au formateur%s"] = "Rezept: beim Lehrer%s",
    ["Plan : chez un vendeur PNJ%s"] = "Rezept: bei einem NSC-Händler%s",
    ["Plan : coté à l'HV — %s"] = "Rezept: im AH gelistet — %s",
    ["Plan : à farmer (butin/quête — absent de l'HV)"] = "Rezept: farmen (Beute/Quest — nicht im AH)",
    -- Plan de route (montée de métier)
    ["Plan de route"] = "Levelroute",
    ["Plan de route : quoi crafter pour monter au moins cher."] = "Levelroute: was du craften solltest, um am günstigsten zu skillen.",
    ["Rang %s"] = "Rang %s",
    ["En tête : rang actuel, plafond entraînable, et coût total estimé (« > » = des rangs sans recette calculable, total incomplet)."] =
        "Oben: aktueller Rang, trainierbares Maximum und die geschätzten Gesamtkosten („>“ = einige Ränge haben kein berechenbares Rezept, die Summe ist unvollständig).",
    ["Un segment par ligne : plage de rangs, recette au meilleur coût par point espéré, « ×~N » = crafts attendus, et le coût du segment (parchemin = plan à acheter d'abord, compté dedans). Survole une ligne pour le détail. La route se recalcule à chaque point gagné."] =
        "Ein Abschnitt pro Zeile: Rangbereich, das Rezept mit den besten erwarteten Kosten pro Punkt, „×~N“ = erwartete Crafts, und die Kosten des Abschnitts (Schriftrolle = zuerst zu kaufendes Rezept, eingerechnet). Für Details mit der Maus über eine Zeile fahren. Die Route wird bei jedem Punkt neu berechnet.",
    ["Total estimé : %s"] = "Geschätzte Summe: %s",
    ["Rang au plafond — vois le formateur pour débloquer la suite."] = "Maximaler Rang — besuche deinen Lehrer, um weiterzukommen.",
    ["aucune recette calculable"] = "kein berechenbares Rezept",
    ["Estimation : chance de point par couleur, prix du dernier scan HV (Lazy Gold)."] = "Schätzung: Skill-Chance je Farbe, Preise vom letzten AH-Scan (Lazy Gold).",
    ["Rien à calculer — scanne l'HV (Auctionator) puis rouvre ce panneau."] = "Nichts zu berechnen — scanne das AH (Auctionator) und öffne dieses Fenster erneut.",
    ["Crafts attendus : ~%d"] = "Erwartete Crafts: ~%d",
    ["Réactifs (espéré)"] = "Materialien (erwartet)",
    ["Plan à acheter"] = "Zu kaufendes Rezept",
    ["Aucune recette calculable sur ce segment (prix HV manquants, ou plans introuvables)."] = "Kein berechenbares Rezept in diesem Abschnitt (fehlende AH-Preise oder nicht beschaffbare Rezepte).",
    ["Monter son métier au meilleur prix"] = "Skille deinen Beruf zum günstigsten Preis",
    ["Dans la Vue Métier, la flèche verte trie par montée de compétence : les plans qui rapportent un point d'abord, les moins chers en tête (prix Lazy Gold)."] =
        "In der Berufsansicht sortiert der grüne Pfeil nach Fertigkeitsanstieg: Rezepte, die einen Punkt bringen, zuerst — die günstigsten oben (Lazy-Gold-Preise).",
    ["Le badge doré marque le meilleur coût par point ; les plans utiles non appris s'affichent aussi, avec où les obtenir (formateur, vendeur, HV, à farmer)."] =
        "Das goldene Abzeichen markiert die besten Kosten pro Punkt; nützliche ungelernte Rezepte erscheinen ebenfalls, samt Bezugsquelle (Lehrer, Händler, AH, farmen).",
    ["Le bouton carte ouvre le |cFFE8B84BPlan de route|r : du rang actuel au plafond, quoi crafter, combien de fois, pour quel coût total estimé — recalculé à chaque point gagné."] =
        "Der Karten-Button öffnet die |cFFE8B84BLevelroute|r: vom aktuellen Rang bis zum Maximum — was du wie oft craften solltest und zu welchen geschätzten Gesamtkosten, neu berechnet bei jedem Punkt.",
    ["Tout repose sur les prix du dernier scan Auctionator (addons Lazy Gold + Auctionator conseillés) : sans eux, ces aides s'effacent."] =
        "Alles beruht auf den Preisen des letzten Auctionator-Scans (Addons Lazy Gold + Auctionator empfohlen): ohne sie blenden sich diese Hilfen aus.",

    -- Bourse d'artisan (onglet Artisans)
    ["Bourse d'artisan"] = "Handwerker-Beutel",
    ["Clic : les fournitures qu'il lui faut pour monter ses métiers (prix Lazy Gold)."] =
        "Klick: die Materialien, die er zum Skillen seiner Berufe braucht (Lazy-Gold-Preise).",
    ["Bourse — %s"] = "Beutel — %s",
    ["Rien à fournir — métiers au plafond, ou données trop anciennes."] = "Nichts zu liefern — Berufe am Maximum oder Daten zu alt.",
    ["Inclure les plans à acheter"] = "Kaufbare Rezepte einbeziehen",
    ["Les plans-objets s'ajoutent aux fournitures ; les plans « au formateur » restent à apprendre chez le PNJ."] =
        "Rezept-Gegenstände zählen zu den Materialien; Lehrer-Rezepte muss er weiterhin beim NPC lernen.",
    ["Requis : ×%d"] = "Benötigt: ×%d",
    ["Plan à fournir (il ne le connaît pas encore)"] = "Rezept zum Mitbringen (er kennt es noch nicht)",
    ["Au formateur : %s"] = "Beim Lehrer: %s",
    ["Chez un PNJ (inutile de fournir) : %s"] = "Beim NPC-Händler (nicht nötig mitzubringen): %s",
    ["Fournitures (agrégées)"] = "Materialien (gesamt)",
    ["Clic : poser un repère sur ce PNJ (TomTom ou épingle de carte)."] = "Klick: setzt eine Wegmarke auf diesen NPC (TomTom oder Kartenstecknadel).",
    ["zone introuvable sur la carte : %s"] = "Zone auf der Karte nicht gefunden: %s",
    ["repère posé : %s — %s (%.0f, %.0f)"] = "Wegmarke gesetzt: %s — %s (%.0f, %.0f)",
    ["Route incomplète : %d rang(s) sans recette calculable (prix HV manquants)."] =
        "Unvollständige Route: %d Rang/Ränge ohne berechenbares Rezept (fehlende AH-Preise).",
    ["Coche « Inclure les plans à acheter » pour en combler une partie."] =
        "Aktiviere „Kaufbare Rezepte einbeziehen“, um einen Teil zu füllen.",
    ["Coût partiel : au moins un réactif sans prix HV."] = "Teilkosten: mindestens ein Material ohne AH-Preis.",
    ["Désenchanter : objets %s, niv. d'objet %d-%d (estimation)"] = "Entzaubern: %s Gegenstände, Gegenstandsstufe %d-%d (Schätzung)",
    -- Échange enchanteur, étage 2 : invite un-clic côté client
    ["%s propose d'enchanter : %s. Poser la pièce dans l'emplacement « ne sera pas échangé » ? Rien n'est donné — tu la récupères enchantée."] =
        "%s bietet dir eine Verzauberung an: %s. In den Platz „Wird nicht gehandelt“ legen? Du gibst nichts her — du bekommst es verzaubert zurück.",
    ["Poser la pièce"] = "Hineinlegen",
    ["Ignorer"] = "Ignorieren",
}

for k, v in pairs(de2) do L[k] = v end
