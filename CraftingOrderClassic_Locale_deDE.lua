-- CraftingOrderClassic_Locale_deDE.lua — overlay ALLEMAND (deDE). Clé FR → texte DE.
-- Chargé APRÈS CraftingOrderClassic_Locale.lua (qui crée COC.L via setmetatable). Repli sur la clé FR
-- pour toute chaîne non traduite. Guillemets « » dans les valeurs → évite l'échappement Lua des ".
-- Sur un client non-deDE : early-return, coût nul.

local COC = CraftingOrderClassic
if (GetLocale and GetLocale() or "") ~= "deDE" then return end
local L = COC.L

local de = {
    -- Onglets / fenêtre
    ["Carnet"] = "Auftragsbuch", ["Commande"] = "Bestellen", ["Récolte"] = "Sammeln", ["Artisans"] = "Handwerker",
    ["Classic · canal global"] = "Classic · globaler Kanal",
    -- En-têtes de colonnes (Carnet)
    ["COMMANDE"] = "AUFTRAG", ["QTÉ"] = "ANZ.", ["PRIX PROPOSÉ"] = "GEBOTENER PREIS",
    ["MÉTIER"] = "BERUF", ["STATUT"] = "STATUS",
    ["ARTISAN"] = "HANDWERKER",
    -- Filtres Carnet
    ["Tous"] = "Alle", ["Guilde"] = "Gilde", ["Amis"] = "Freunde",
    ["Annuaire"] = "Verzeichnis",
    ["Rafraîchir l'annuaire"] = "Verzeichnis aktualisieren",
    ["annuaire : appel lancé sur le canal — les porteurs en ligne vont répondre."] =
        "Verzeichnis: Aufruf im Kanal gesendet — Online-Nutzer antworten.",
    ["Survole un ami dans la liste d'amis, ou sélectionne un membre dans le panneau de guilde : ses métiers primaires s'affichent sans ouvrir cette fenêtre."] =
        "Fahre über einen Freund in der Freundesliste oder wähle ein Gildenmitglied im Gildenfenster: seine Hauptberufe werden angezeigt, ohne dieses Fenster zu öffnen.",
    ["Clic droit sur un joueur qui a l'addon (ami, guilde, croisé) : « Passer commande à… » ouvre l'onglet Commande déjà ciblé sur lui."] =
        "Rechtsklick auf einen Spieler mit dem Addon (Freund, Gilde, getroffen): « Auftrag an… » öffnet den Tab Bestellen, bereits auf ihn ausgerichtet.",
    ["« Met » devient « Annuaire ». Le bouton « Rafraîchir l'annuaire » appelle le canal : tous les porteurs en ligne répondent et s'y ajoutent."] =
        "« Getroffen » heißt jetzt « Verzeichnis ». Die Schaltfläche « Verzeichnis aktualisieren » ruft den Kanal auf: alle Online-Nutzer antworten und werden hinzugefügt.",
    -- Onglet Nouveautés (changelog en jeu)
    ["Nouveautés"] = "Neues",
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
    ["Alertes de plan looté qui te concernent"] = "Beute-Rezept-Warnungen, die dich betreffen",
    ["L'alerte de plan looté ne se déclenche plus que s'il te concerne : tu as le métier et peux l'apprendre, ou un ami/partenaire de ton annuaire ne le connaît pas encore."] =
        "Die Beute-Rezept-Warnung erscheint nur noch, wenn sie dich betrifft: du hast den Beruf und kannst es lernen, oder ein Freund/Partner in deinem Verzeichnis kennt es noch nicht.",
    ["Les candidats au don incluent désormais tes amis, pas seulement les partenaires marqués — l'alerte « intéressés » et |cFFFFFFFF/co gift|r touchent tout ton annuaire."] =
        "Geschenk-Kandidaten umfassen jetzt deine Freunde, nicht nur markierte Partner — die « Interessiert »-Warnung und |cFFFFFFFF/co gift|r erreichen dein ganzes Verzeichnis.",
    ["Amis Battle.net + commande par métier"] = "Battle.net-Freunde + Auftrag nach Beruf",
    ["Les métiers et le menu Crafting Order fonctionnent maintenant sur les amis Battle.net, pas seulement les amis ajoutés par personnage."] =
        "Berufe und das Crafting-Order-Menü funktionieren jetzt bei Battle.net-Freunden, nicht nur bei über den Charakter hinzugefügten Freunden.",
    ["Clic droit sur un artisan : une entrée « Passer commande » par métier, qui ouvre l'onglet Commande déjà réglé sur ce métier."] =
        "Rechtsklick auf einen Handwerker: ein « Auftrag »-Eintrag pro Beruf, der den Tab Bestellen bereits auf diesen Beruf eingestellt öffnet.",
    ["Le résumé d'un artisan indique la profondeur de son carnet (« · N plans ») ; maintiens Maj sur son infobulle en jeu pour lister ses recettes connues."] =
        "Die Zusammenfassung eines Handwerkers zeigt den Umfang seines Rezeptbuchs (« · N Rezepte »); halte Umschalt über seiner Tooltip in der Welt, um seine bekannten Rezepte aufzulisten.",
    ["Correctif : un personnage n'affiche plus par erreur les métiers de ses rerolls dans ton annuaire."] =
        "Fehlerbehebung: Ein Charakter zeigt in deinem Verzeichnis nicht mehr fälschlich die Berufe seiner Twinks.",
    ["Allemand et espagnol + onglet Nouveautés"] = "Deutsch und Spanisch + Tab Neues",
    ["L'interface se traduit en allemand et en espagnol selon la langue de ton client WoW."] =
        "Die Oberfläche wird je nach Sprache deines WoW-Clients ins Deutsche und Spanische übersetzt.",
    ["Ce nouvel onglet « Nouveautés » affiche les notes de version directement en jeu."] =
        "Dieser neue Tab « Neues » zeigt die Versionshinweise direkt im Spiel.",
    ["VU"] = "GESEHEN",
    ["vu crafter (sans l'addon)"] = "beim Herstellen gesehen (ohne Addon)",
    ["vu crafter"] = "beim Herstellen gesehen",
    ["%d+ · vu crafter"] = "%d+ · beim Herstellen gesehen",
    ["Repérer les crafteurs autour (en ville)"] = "Handwerker in der Nähe erkennen (in Stadt)",
    ["Ajouter ami"] = "Freund hinzufügen",
    ["|cFFFFFFFF%s|r ajouté à tes amis."] = "|cFFFFFFFF%s|r zu deinen Freunden hinzugefügt.",
    ["repérage des crafteurs autour : |cFFFFFFFF%s|r (en ville) — /co crafters [on|off]"] =
        "Erkennen von Handwerkern in der Nähe: |cFFFFFFFF%s|r (in Stadt) — /co crafters [on|off]",
    ["repérer les crafteurs sans l'addon qui craftent autour (en ville ; défaut : off)"] =
        "Spieler ohne Addon erkennen, die in der Nähe herstellen (in Stadt; Standard: aus)",
    ["Archivées"] = "Archiviert", ["En cours"] = "Aktiv",
    ["Aucune commande. Onglet « Commande » pour en poster une."] = "Keine Aufträge. Tab « Bestellen », um einen zu erstellen.",
    ["Clic : "] = "Klick: ", ["Accepter"] = "Annehmen", ["Annuler"] = "Abbrechen", ["Livrer"] = "Liefern",
    ["J'ai reçu"] = "Erhalten", ["Remise"] = "Geliefert",
    ["remise — en attente de confirmation de %s : %s"] = "geliefert — Bestätigung von %s ausstehend: %s",
    ["réception confirmée : %s"] = "Empfang bestätigt: %s",
    ["réception confirmée par %s ! crafts livrés au total : %d"] = "Empfang von %s bestätigt! Insgesamt gelieferte Aufträge: %d",
    ["%s a remis ta commande : %s — clique « J'ai reçu » pour confirmer"] =
        "%s hat deinen Auftrag geliefert: %s — klicke « Erhalten » zum Bestätigen",
    ["Refuser"] = "Ablehnen", ["%s a refusé ta commande : %s"] = "%s hat deinen Auftrag abgelehnt: %s",
    ["guilde"] = "Gilde", ["commerce"] = "Handel",
    ["Inviter en groupe"] = "In Gruppe einladen", ["en attente"] = "ausstehend", ["acceptées"] = "angenommen", ["en sourdine"] = "stumm",
    ["diag"] = "Diag", ["Sourdine"] = "Stumm", ["Réafficher"] = "Einblenden",
    ["Muter"] = "Stummschalten", ["Ajouter aux artisans"] = "Zu Handwerkern hinzufügen",
    ["Passer commande à %s"] = "Auftrag an %s", ["Passer commande"] = "Auftrag erteilen",
    ["Passer commande à %s (%s)"] = "Auftrag an %s (%s)",
    ["%s est mis en sourdine — plus aucune notification de sa part."] = "%s wurde stummgeschaltet — keine Benachrichtigungen mehr von ihm.",
    ["%s n'est plus en sourdine."] = "%s ist nicht mehr stummgeschaltet.",
    ["usage : /co unmute <nom>"] = "Verwendung: /co unmute <Name>",
    ["aucun joueur en sourdine. /co mute <nom> pour en ajouter un."] = "keine stummgeschalteten Spieler. /co mute <Name>, um einen hinzuzufügen.",
    ["en sourdine (%d) : %s"] = "stumm (%d): %s",
    ["mute auto bas niveau : |cFFFFFFFFdésactivé|r — /co lowlevel <niveau>"] = "Auto-Stumm für niedrige Stufen: |cFFFFFFFFaus|r — /co lowlevel <Stufe>",
    ["mute auto bas niveau : sous le niveau |cFFFFFFFF%d|r — /co lowlevel [N|off]"] = "Auto-Stumm für niedrige Stufen: unter Stufe |cFFFFFFFF%d|r — /co lowlevel [N|off]",
    ["%s a posté %d fois en peu de temps. Le mettre en sourdine ?"] = "%s hat %d Mal in kurzer Zeit gepostet. Stummschalten?",
    ["muter/démuter un joueur (aucune notif de sa part)"] = "einen Spieler stumm-/entstummschalten (keine Benachrichtigungen von ihm)",
    ["seuil de mute auto des persos bas niveau (défaut 5)"] = "Schwelle für Auto-Stumm niedrigstufiger Charaktere (Standard 5)",
    ["%d livrés"] = "%d geliefert",
    ["· %d plans"] = "· %d Rezepte",
    ["+%d de plus"] = "+%d weitere",
    ["Maj : plans connus"] = "Umschalt: bekannte Rezepte",
    ["ton reroll |cFFFFFFFF%s|r sait le faire : %s"] = "dein Twink |cFFFFFFFF%s|r kann das herstellen: %s",
    ["COMPOSANTS FOURNIS"] = "BEREITGESTELLTE MATERIALIEN", ["À FOURNIR"] = "BEREITSTELLEN", ["complet"] = "vollständig",
    ["chargé — |cFFFFFFFF/co help|r pour les commandes. (Réseau global de craft — autonome.)"] =
        "geladen — |cFFFFFFFF/co help|r für Befehle. (Globales Handwerksnetzwerk — eigenständig.)",
    ["CraftLink introuvable — l'infra partagée n'est pas chargée."] =
        "CraftLink nicht gefunden — die gemeinsame Infrastruktur ist nicht geladen.",
    ["infra CraftLink — dataVersion=|cFFE8B84B%d|r, protocole=v%d, catalogue=%d métier(s) %s"] =
        "CraftLink-Infra — dataVersion=|cFFE8B84B%d|r, Protokoll=v%d, Katalog=%d Beruf(e) %s",
    ["prêt"] = "bereit", ["vide"] = "leer",
    ["mes recettes captées : "] = "meine erfassten Rezepte: ",
    ["aucune recette captée — ouvre une fenêtre de métier une fois pour l'amorcer."] =
        "keine Rezepte erfasst — öffne einmal ein Berufsfenster, um sie zu erfassen.",
    ["réseau global : %s — |cFFFFFFFF%d|r en ligne, |cFFFFFFFF%d|r crafteur(s) connus"] =
        "globales Netzwerk: %s — |cFFFFFFFF%d|r online, |cFFFFFFFF%d|r bekannte(r) Handwerker",
    ["connexion…"] = "Verbinde…",
    ["réseau : sollicitation envoyée (HI global + PING proximité)."] =
        "Netzwerk: Aufruf gesendet (globales HI + Nähe-PING).",
    ["métier inconnu : "] = "unbekannter Beruf: ",
    ["commandes :"] = "Befehle:",
    ["statut (infra, mes recettes, réseau)"] = "Status (Infra, meine Rezepte, Netzwerk)",
    ["carnet d'ordres"] = "Auftragsbuch", ["poster une commande"] = "einen Auftrag erstellen",
    ["solliciter l'annuaire (présence + proximité)"] = "Verzeichnis abfragen (Präsenz + Nähe)",
    ["teste l'aller-retour réseau (PING global → PONG des autres porteurs)"] =
        "testet die Netzwerk-Rundreise (globales PING → PONG anderer Nutzer)",
    ["vue commandes d'un métier (ou menu des métiers si vide)"] =
        "Auftragsansicht eines Berufs (oder Berufsmenü, wenn leer)",
    ["basculer fenêtre métier custom / vue Blizzard"] = "eigenes Berufsfenster / Blizzard-Ansicht umschalten",
    ["portée des notifications de commande"] = "Reichweite der Auftragsbenachrichtigungen",
    ["notifications : |cFFFFFFFF%s|r — /co notify [all|directed|named|off]"] =
        "Benachrichtigungen: |cFFFFFFFF%s|r — /co notify [all|directed|named|off]",
    ["portée du scan des demandes de craft en chat (défaut : mes métiers)"] =
        "Reichweite des Chat-Scans nach Handwerksanfragen (Standard: meine Berufe)",
    ["scan chat commerce/guilde : |cFFFFFFFF%s|r — /co scan [mine|all|off]"] =
        "Handels-/Gildenchat-Scan: |cFFFFFFFF%s|r — /co scan [mine|all|off]",
    ["mode solo"] = "Solomodus",
    ["injecte/retire un réseau fictif (artisans + commandes)"] = "fügt ein fiktives Netzwerk ein/entfernt es (Handwerker + Aufträge)",
    ["journalise le réseau dans la SavedVariable (off | clear | dump)"] =
        "protokolliert das Netzwerk in die SavedVariable (off | clear | dump)",
    ["commande introuvable : "] = "Auftrag nicht gefunden: ", ["ce n'est pas ta commande."] = "das ist nicht dein Auftrag.",
    ["commande annulée : "] = "Auftrag abgebrochen: ", ["commande non disponible : "] = "Auftrag nicht verfügbar: ",
    ["c'est ta propre commande."] = "das ist dein eigener Auftrag.",
    ["cette commande ne t'est pas destinée."] = "dieser Auftrag ist nicht für dich bestimmt.",
    ["commande acceptée : %s (%s)"] = "Auftrag angenommen: %s (%s)",
    ["tu n'as pas accepté cette commande."] = "du hast diesen Auftrag nicht angenommen.",
    ["commande relâchée : "] = "Auftrag freigegeben: ", ["carnet d'ordres :"] = "Auftragsbuch:",
    [" par "] = " von ", ["  (aucune commande active)"] = "  (kein aktiver Auftrag)",
    ["usage : /co post [shift-clic objet] [xN] [prix]"] = "Verwendung: /co post [Umschalt-Klick Gegenstand] [xN] [Preis]",
    ["commande postée |cFFFFFFFF%s|r : %s x%d %s[%s]"] = "Auftrag erstellt |cFFFFFFFF%s|r: %s x%d %s[%s]",
    ["CraftLink absent — l'infra réseau n'est pas chargée."] = "CraftLink fehlt — die Netzwerk-Infrastruktur ist nicht geladen.",
    ["PING envoyé (canal %s%s). En attente des PONG…"] = "PING gesendet (Kanal %s%s). Warte auf PONGs…",
    ["rejoint"] = "beigetreten", ["PAS rejoint"] = "NICHT beigetreten",
    [", +|cFFFFFFFF%d|r whisper(s)"] = ", +|cFFFFFFFF%d|r Flüstern",
    ["entrante acceptée : |cFFFFFFFF%s|r"] = "eingehend angenommen: |cFFFFFFFF%s|r",
    ["infra non prête."] = "Infra nicht bereit.",
    ["activé — %d artisans + %d commandes + %d entrantes injectés."] =
        "aktiviert — %d Handwerker + %d Aufträge + %d eingehende eingefügt.",
    ["désactivé — faux artisans et commandes purgés."] = "deaktiviert — falsche Handwerker und Aufträge entfernt.",
    ["vidée."] = "geleert.", ["%d lignes (30 dernières) :"] = "%d Zeilen (letzte 30):",
    ["ON. Fais tes tests, puis |cFFFFFFFF/reload|r, puis lis SavedVariables\\CraftingOrderClassic.lua (clé trace)."] =
        "AN. Führe deine Tests aus, dann |cFFFFFFFF/reload|r, dann lies SavedVariables\\CraftingOrderClassic.lua (Schlüssel trace).",
    ["réseau"] = "Netzwerk", ["canal rejoint"] = "Kanal beigetreten",
    ["en ligne"] = "online", ["artisan(s)"] = "Handwerker",
    ["Alchimie"] = "Alchimie", ["Forge"] = "Schmiedekunst", ["Cuisine"] = "Kochkunst",
    ["Enchantement"] = "Verzauberkunst", ["Ingénierie"] = "Ingenieurskunst", ["Secourisme"] = "Erste Hilfe",
    ["Pêche"] = "Angeln", ["Herboristerie"] = "Kräuterkunde", ["Travail du cuir"] = "Lederverarbeitung",
    ["Minage"] = "Bergbau", ["Dépeçage"] = "Kürschnerei", ["Couture"] = "Schneiderei",
    ["Joaillerie"] = "Juwelenschleifen", ["Calligraphie"] = "Inschriftenkunde", ["Élémentaire"] = "Elementar",
    ["En attente"] = "Ausstehend", ["Acceptée"] = "Angenommen", ["Livrée"] = "Geliefert", ["Annulée"] = "Abgebrochen", ["Refusée"] = "Abgelehnt",
    ["LISTE DES PLANS"] = "REZEPTLISTE", ["JE FOURNIS"] = "ICH STELLE", ["Réactifs"] = "Materialien",
    ["(cocher = je fournis)"] = "(anhaken = ich stelle bereit)", ["Commission"] = "Provision", ["Qté"] = "Anz.",
    ["Destinataire :"] = "Empfänger:", ["Diffuser à tous"] = "An alle senden", ["Poster"] = "Erstellen",
    ["Choisis un métier puis un plan."] = "Wähle einen Beruf, dann ein Rezept.",
    ["Rechercher un plan"] = "Rezept suchen", ["Qualité : "] = "Qualität: ",
    ["Sélection : "] = "Auswahl: ", ["Commande postée !"] = "Auftrag erstellt!",
    ["Réactifs : j'ai tout"] = "Materialien: alles vorhanden", ["Réactifs : "] = "Materialien: ",
    ["[Prêt]"] = "[Bereit]",
    ["Autres"] = "Sonstige",
    ["connus"] = "bekannt", ["niv. %d"] = "Stufe %d",
    ["Choisis d'abord un plan."] = "Wähle zuerst ein Rezept.", ["Aucun plan sélectionné."] = "Kein Rezept ausgewählt.",
    ["Ajoutés"] = "Hinzugefügt", ["fournis"] = "bereitgestellt", ["Chargement…"] = "Lädt…",
    ["Toute la guilde"] = "Ganze Gilde", ["Tous les amis"] = "Alle Freunde",
    ["Tous les ajoutés"] = "Alle Hinzugefügten", ["Tous les croisés"] = "Alle Getroffenen",
    ["MÉTIER DE RÉCOLTE"] = "SAMMELBERUF", ["Rechercher une ressource"] = "Ressource suchen",
    ["LISTE DES RESSOURCES"] = "RESSOURCENLISTE", ["Demande de récolte — quantité voulue"] = "Sammelanfrage — gewünschte Menge",
    ["stacks"] = "Stapel", ["pile"] = "Stapel", ["piles"] = "Stapel",
    ["Récolteur :"] = "Sammler:", ["Prix proposé"] = "Gebotener Preis",
    ["Choisis un métier de récolte puis une ressource."] = "Wähle einen Sammelberuf, dann eine Ressource.",
    ["Aucune ressource sélectionnée."] = "Keine Ressource ausgewählt.", ["par stack"] = "pro Stapel", ["à l'unité"] = "pro Stück",
    ["Commande de récolte postée !"] = "Sammelauftrag erstellt!", ["Choisis d'abord une ressource."] = "Wähle zuerst eine Ressource.",
    ["Toutes"] = "Alle",
    ["Objet |cFFE8B84Bélémentaire|r (farmé sur les mobs, pas de métier). Diffusé à tous. Quantité et prix |cFFE8B84B%s.|r"] =
        "|cFFE8B84BElementar|r-Gegenstand (von Gegnern gefarmt, kein Beruf). An alle gesendet. Menge und Preis |cFFE8B84B%s.|r",
    ["Diffusée aux récolteurs ayant |cFFE8B84B%s.|r Quantité et prix proposé |cFFE8B84B%s.|r"] =
        "An Sammler mit |cFFE8B84B%s|r gesendet. Menge und gebotener Preis |cFFE8B84B%s.|r",
    ["SOURCE"] = "QUELLE", ["AJOUTER UN JOUEUR"] = "SPIELER HINZUFÜGEN", ["Nom du personnage"] = "Charaktername",
    ["Métier :"] = "Beruf:", ["Chuchoter"] = "Flüstern", ["Aucun artisan dans cette source."] = "Kein Handwerker in dieser Quelle.",
    ["En ligne"] = "Online", ["Hors ligne"] = "Offline", ["niv "] = "Stufe ", ["niv ?"] = "Stufe ?",
    ["GUILDE"] = "GILDE", ["AMIS"] = "FREUND", ["AJOUTÉ"] = "HINZUGEFÜGT", ["CROISÉ"] = "GETROFFEN", ["CONFÉDÉRÉ"] = "KONFÖD.",
    ["Confédération"] = "Konföderation",
    ["artisan ajouté : "] = "Handwerker hinzugefügt: ",
    ["(lié quand il sera en ligne avec l'addon)"] = "(verknüpft, sobald er mit dem Addon online ist)",
    ["GreenWall non détecté — section « Confédération » masquée."] = "GreenWall nicht erkannt — Bereich « Konföderation » ausgeblendet.",
    ["GreenWall actif, aucun confédéré repéré (il faut qu'ils parlent en /g)."] = "GreenWall aktiv, kein Konföderierter erkannt (sie müssen in /g sprechen).",
    ["confédérés repérés (%d) :"] = "erkannte Konföderierte (%d):",
    ["en ligne · annuaire"] = "online · Verzeichnis", ["annuaire"] = "Verzeichnis",
    ["pas encore dans l'annuaire (sans COC ?)"] = "noch nicht im Verzeichnis (ohne COC?)",
    ["confédérés GreenWall repérés (SoD live only)"] = "erkannte GreenWall-Konföderierte (nur SoD live)",
    ["Commandes pour ce joueur"] = "Aufträge für diesen Spieler",
    ["Commandes à livrer"] = "Zu liefernde Aufträge",
    ["+%d autre(s)"] = "+%d weitere",
    ["Remplir depuis commande"] = "Aus Auftrag füllen",
    ["Marquer livrée"] = "Als geliefert markieren",
    ["À réclamer : %s"] = "Einzufordern: %s",
    ["À payer : %s"] = "Zu zahlen: %s",
    ["Pas de prix convenu."] = "Kein vereinbarter Preis.",
    ["Gratuit."] = "Kostenlos.",
    ["Commande : %s"] = "Auftrag: %s",
    ["Voici ta commande. Prix convenu : %s."] = "Hier ist dein Auftrag. Vereinbarter Preis: %s.",
    ["Voici ta commande."] = "Hier ist dein Auftrag.",
    ["Recettes"] = "Rezepte", ["Commandes"] = "Aufträge", ["Réactifs :"] = "Materialien:",
    ["Créer"] = "Herstellen", ["Créer tout"] = "Alle herstellen", ["Vue Blizzard"] = "Blizzard-Ansicht",
    ["Sélectionne une recette."] = "Wähle ein Rezept.", ["Produit "] = "Ergibt ",
    ["réactifs insuffisants."] = "nicht genug Materialien.",
    ["fenêtre métier custom |cFF33DD33activée|r — ouvre un métier. (Guild Economy laisse la main.)"] =
        "eigenes Berufsfenster |cFF33DD33aktiviert|r — öffne einen Beruf. (Guild Economy tritt zurück.)",
    ["fenêtre métier custom |cFFFFCC00désactivée|r (vue Blizzard)."] =
        "eigenes Berufsfenster |cFFFFCC00deaktiviert|r (Blizzard-Ansicht).",
    ["» Vue Crafting Order"] = "» Crafting-Order-Ansicht",
    ["Module Commandes non chargé — redémarre complètement WoW (quitter/relancer), pas un simple /reload."] =
        "Auftragsmodul nicht geladen — starte WoW komplett neu (beenden/neu starten), nicht nur /reload.",
    ["Clic : ouvrir le carnet d'ordres"] = "Klick: Auftragsbuch öffnen",
    ["Clic droit : mes métiers"] = "Rechtsklick: meine Berufe",
    ["Mes métiers"] = "Meine Berufe", ["Aucun métier connu."] = "Kein bekannter Beruf.",
    ["Don / gratuit"] = "Geschenk / gratis",
    ["|cFFFF8800entrante|r |cFFFFFFFF%s|r (%s) : %s%s%s"] = "|cFFFF8800eingehend|r |cFFFFFFFF%s|r (%s): %s%s%s",
    ["   |cFF33DD33→ tu sais la crafter|r — Carnet › Entrantes"] = "   |cFF33DD33→ du kannst es herstellen|r — Auftragsbuch › Eingehend",
    ["|cFFFFCC00commande pour TOI|r de |cFFFFFFFF%s|r : %s%s%s"] = "|cFFFFCC00Auftrag für DICH|r von |cFFFFFFFF%s|r: %s%s%s",
    ["ton artisan |cFFFFFFFF%s|r est en ligne."] = "dein Handwerker |cFFFFFFFF%s|r ist online.",
    ["plan looté : |cFFFFFFFF%s|r — enseigne |cFFFFFFFF%s|r (%s) %s"] =
        "Rezept erbeutet: |cFFFFFFFF%s|r — lehrt |cFFFFFFFF%s|r (%s) %s",
    ["|cFF888888(tu la connais déjà)|r"] = "|cFF888888(du kennst es bereits)|r",
    ["|cFF33DD33(tu ne la connais pas encore !)|r"] = "|cFF33DD33(du kennst es noch nicht!)|r",
    ["alerte plan looté : |cFFFFFFFF%s|r — /co lootalert [on|off]"] =
        "Beute-Rezept-Warnung: |cFFFFFFFF%s|r — /co lootalert [on|off]",
    ["alerte quand tu loots un plan connu de CraftLink (défaut : on)"] =
        "Warnung, wenn du ein CraftLink bekanntes Rezept erbeutest (Standard: an)",
    ["Partenaire (basculer)"] = "Partner (umschalten)",
    ["[Partenaire]"] = "[Partner]",
    ["|cFFFFFFFF%s|r marqué comme partenaire — priorité sur les alertes de don."] =
        "|cFFFFFFFF%s|r als Partner markiert — Vorrang bei Geschenk-Warnungen.",
    ["|cFFFFFFFF%s|r n'est plus marqué comme partenaire."] = "|cFFFFFFFF%s|r ist nicht mehr als Partner markiert.",
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
    ["La pastille verte/grise indique s'il est en ligne."] = "Der grüne/graue Punkt zeigt, ob er online ist.",
    ["Réseau, confidentialité & statuts"] = "Netzwerk, Privatsphäre & Status",
    ["L'addon rejoint un canal dédié pour faire circuler le carnet entre joueurs de l'addon — aucun message lisible n'y est envoyé."] =
        "Das Addon tritt einem eigenen Kanal bei, um das Auftragsbuch zwischen Addon-Nutzern zu übertragen — es wird kein lesbarer Text gesendet.",
    ["|cFFFFFFFF/co channel off|r le quitte à tout moment (whisper et guilde restent actifs) ; |cFFFFFFFF/co channel on|r le rejoint."] =
        "|cFFFFFFFF/co channel off|r verlässt ihn jederzeit (Flüstern und Gilde bleiben aktiv); |cFFFFFFFF/co channel on|r tritt wieder bei.",
    ["Statuts d'une commande : "] = "Auftragsstatus: ",
}
for k, v in pairs(de) do L[k] = v end
