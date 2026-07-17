-- CraftingOrderClassic_Locale_deDE.lua — overlay ALLEMAND (deDE). Clé FR → texte DE.
-- Chargé APRÈS CraftingOrderClassic_Locale.lua (qui crée COC.L via setmetatable). Repli sur la clé FR
-- pour toute chaîne non traduite. Guillemets « » dans les valeurs → évite l'échappement Lua des ".
-- Sur un client non-deDE : early-return, coût nul.

local COC = CraftingOrderClassic
if (GetLocale and GetLocale() or "") ~= "deDE" then return end
local L = COC.L

local de = {
    ["Enchanter équipé"] = "Ausgerüstetes verzaubern", ["Enchante directement la pièce équipée — sans cibler."] = "Verzaubert direkt das ausgerüstete Teil — ohne Zielauswahl.",
    ["Enchanter cet objet"] = "Diesen Gegenstand verzaubern", ["Ouvre ta fenêtre d'Enchantement."] = "Öffne dein Verzauberkunst-Fenster.", ["Aucun enchantement connu pour cet emplacement."] = "Keine bekannte Verzauberung für diesen Platz.",
    ["Choisir par emplacement"] = "Nach Platz auswählen", ["Retour"] = "Zurück",   -- vue silhouette (onglet Commande)
    -- Onglets / fenêtre
    ["Carnet"] = "Auftragsbuch", ["Commande"] = "Bestellen", ["Récolte"] = "Sammeln", ["Artisans"] = "Handwerker",
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
    -- Onglet « Mes artisans » (vue agrégée des métiers du compte — 100 % local)
    ["Mes artisans"] = "Meine Handwerker",
    ["%d recettes"] = "%d Rezepte",
    ["Aucun métier. Ouvre ta fenêtre métier sur chaque perso une fois."] =
        "Keine Berufe. Öffne das Berufsfenster auf jedem Charakter einmal.",
    ["Partager mes rerolls sur le réseau"] = "Meine Twinks im Netzwerk teilen",
    ["Vitrine"] = "Aushängeschild",
    ["Rerolls"] = "Twinks",
    ["%s — lecture seule"] = "%s — schreibgeschützt",
    ["Pas de recettes connues (métier de récolte ?)."] = "Keine bekannten Rezepte (Sammelberuf?).",
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
    ["en sourdine (%d) :"] = "stumm (%d):",
    ["permanent"] = "dauerhaft", ["expiré"] = "abgelaufen", ["spam détecté"] = "Spam erkannt",
    -- Verwaltungsbereich für Stummgeschaltete (Reiter Handwerker › Stummgeschaltet)
    ["En sourdine"] = "Stummgeschaltet", ["Rétablir"] = "Aufheben",
    ["Joueurs en sourdine — aucune notification de leur part."] = "Stummgeschaltete Spieler — keine Benachrichtigungen von ihnen.",
    ["Personne en sourdine."] = "Niemand ist stummgeschaltet.",
    ["Mets un joueur en sourdine par clic-droit sur sa carte ou /co mute <nom>."] = "Schalte einen Spieler per Rechtsklick auf seine Karte oder /co mute <Name> stumm.",
    ["%s est de confiance — jamais muté automatiquement."] = "%s ist vertrauenswürdig — nie automatisch stummgeschaltet.",
    ["%s n'est plus de confiance."] = "%s ist nicht mehr vertrauenswürdig.",
    ["aucun joueur de confiance. /co trust <nom> pour en ajouter un."] = "keine vertrauenswürdigen Spieler. /co trust <Name>, um einen hinzuzufügen.",
    ["de confiance (%d) : %s"] = "vertrauenswürdig (%d): %s",
    ["usage : /co untrust <nom>"] = "Verwendung: /co untrust <Name>",
    ["mute auto bas niveau : |cFFFFFFFFdésactivé|r — /co lowlevel <niveau>"] = "Auto-Stumm für niedrige Stufen: |cFFFFFFFFaus|r — /co lowlevel <Stufe>",
    ["mute auto bas niveau : sous le niveau |cFFFFFFFF%d|r — /co lowlevel [N|off]"] = "Auto-Stumm für niedrige Stufen: unter Stufe |cFFFFFFFF%d|r — /co lowlevel [N|off]",
    ["%s a posté %d fois en peu de temps. Le mettre en sourdine ?"] = "%s hat %d Mal in kurzer Zeit gepostet. Stummschalten?",
    ["muter/démuter un joueur (aucune notif ; durée ex. 1h/30m/2d)"] = "einen Spieler stumm-/entstummschalten (keine Benachrichtigungen; Dauer z. B. 1h/30m/2d)",
    ["marquer un joueur de confiance (jamais muté automatiquement)"] = "einen Spieler als vertrauenswürdig markieren (nie automatisch stummgeschaltet)",
    ["seuil de mute auto des persos bas niveau (défaut 5)"] = "Schwelle für Auto-Stumm niedrigstufiger Charaktere (Standard 5)",
    ["mute auto"] = "Auto-Stumm", ["popup"] = "Popup",
    -- /co verbose (diagnostic)
    ["messages verbeux : activés"] = "Ausführliche Meldungen: an", ["messages verbeux : désactivés"] = "Ausführliche Meldungen: aus",
    ["affiche les messages d'info en coulisse (ex. « X peut faire une captée ») ; auto si COCMonitor est chargé"] =
        "Hintergrund-Infomeldungen anzeigen (z. B. « X kann eine erfasste Anfrage herstellen »); automatisch, wenn COCMonitor geladen ist",
    ["détection de spam : |cFFFFFFFFdésactivée|r — /co spam <max> [fenêtre] pour l'activer"] = "Spam-Erkennung: |cFFFFFFFFaus|r — /co spam <max> [Fenster] zum Aktivieren",
    ["détection de spam : |cFFFFFFFF%d|r posts / |cFFFFFFFF%ds|r → %s"] = "Spam-Erkennung: |cFFFFFFFF%d|r Posts / |cFFFFFFFF%ds|r → %s",
    ["  /co spam <max> [fenêtre] · /co spam auto · /co spam off"] = "  /co spam <max> [Fenster] · /co spam auto · /co spam off",
    ["réglage anti-spam : seuil, fenêtre, mute auto vs popup"] = "Anti-Spam-Einstellung: Schwelle, Fenster, Auto-Stumm vs. Popup",
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
    ["JE FOURNIS"] = "ICH STELLE", ["Réactifs"] = "Materialien",
    ["(cocher = je fournis)"] = "(anhaken = ich stelle bereit)", ["Commission"] = "Provision", ["Qté"] = "Anz.",
    ["Destinataire :"] = "Empfänger:", ["Diffuser à tous"] = "An alle senden", ["Poster"] = "Erstellen",
    ["La commande sera visible par tout le monde (cible « Tous »)."] = "Der Auftrag wird an alle gesendet (Ziel: \"Alle\").",
    ["Choisis un métier puis un plan."] = "Wähle einen Beruf, dann ein Rezept.",
    ["Cliquer pour changer de métier"] = "Klicken, um den Beruf zu wechseln",
    ["Rechercher"] = "Rezept suchen",
    ["Commande postée !"] = "Auftrag erstellt!",
    ["Réactifs en main"] = "Materialien vorhanden",
    ["Ne montrer que les plans dont j'ai déjà tous les réactifs."] = "Nur Rezepte anzeigen, für die ich bereits alle Materialien habe.",
    ["[Prêt]"] = "[Bereit]",
    ["Autres"] = "Sonstige",
    ["connus"] = "bekannt", ["niv. %d"] = "Stufe %d",
    ["Choisis d'abord un plan."] = "Wähle zuerst ein Rezept.", ["Aucun plan sélectionné."] = "Kein Rezept ausgewählt.",
    ["Ajoutés"] = "Hinzugefügt", ["fournis"] = "bereitgestellt", ["Chargement…"] = "Lädt…",
    ["Toute la guilde"] = "Ganze Gilde", ["Tous les amis"] = "Alle Freunde",
    ["Tous les ajoutés"] = "Alle Hinzugefügten", ["Tous les croisés"] = "Alle Getroffenen",
    ["Rechercher une ressource"] = "Ressource suchen",
    ["Demande de récolte — quantité voulue"] = "Sammelanfrage — gewünschte Menge",
    ["stacks"] = "Stapel", ["pile"] = "Stapel", ["piles"] = "Stapel",
    ["Récolteur :"] = "Sammler:", ["Prix proposé"] = "Gebotener Preis",
    ["Choisis un métier de récolte puis une ressource."] = "Wähle einen Sammelberuf, dann eine Ressource.",
    ["Aucune ressource sélectionnée."] = "Keine Ressource ausgewählt.", ["par stack"] = "pro Stapel", ["à l'unité"] = "pro Stück",
    ["Commande de récolte postée !"] = "Sammelauftrag erstellt!", ["Choisis d'abord une ressource."] = "Wähle zuerst eine Ressource.",
    ["Toutes"] = "Alle",
    -- Légendes de la rangée de filtres style HdV (onglet Commande) : mots courts, au-dessus du champ.
    ["Objet |cFFE8B84Bélémentaire|r (farmé sur les mobs, pas de métier). Diffusé à tous. Quantité et prix |cFFE8B84B%s.|r"] =
        "|cFFE8B84BElementar|r-Gegenstand (von Gegnern gefarmt, kein Beruf). An alle gesendet. Menge und Preis |cFFE8B84B%s.|r",
    ["Diffusée aux récolteurs ayant |cFFE8B84B%s.|r Quantité et prix proposé |cFFE8B84B%s.|r"] =
        "An Sammler mit |cFFE8B84B%s|r gesendet. Menge und gebotener Preis |cFFE8B84B%s.|r",
    ["SOURCE"] = "QUELLE", ["AJOUTER UN JOUEUR"] = "SPIELER HINZUFÜGEN", ["Nom du personnage"] = "Charaktername",
    ["Métier :"] = "Beruf:", ["Chuchoter"] = "Flüstern", ["Aucun artisan dans cette source."] = "Kein Handwerker in dieser Quelle.",
    ["En ligne"] = "Online", ["En ligne · sans addon"] = "Online · ohne Addon", ["Hors ligne"] = "Offline", ["niv "] = "Stufe ", ["niv ?"] = "Stufe ?",
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
    ["Molette : %d/%d"] = "Mausrad: %d/%d",
    ["Demande-lui une pièce"] = "Gegenstand anfragen",
    ["Clic : lui demander cette pièce."] = "Klick: diesen Gegenstand anfragen.",
    ["Demande envoyée à %s."] = "Anfrage an %s gesendet.",
    ["Mets ton objet « %s » dans l'emplacement du bas de la fenêtre d'échange (« ne sera pas échangé ») — je l'enchante, tu le gardes."] = "Leg deinen Gegenstand (%s) in den unteren Platz des Handelsfensters (\"Wird nicht gehandelt\") — ich verzaubere ihn, du behältst ihn.",
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
    ["Sélection changée en combat — réessaie après le combat."] = "Auswahl im Kampf geändert — versuche es nach dem Kampf erneut.",
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
    ["Marquer comme partenaire"] = "Als Partner markieren", ["Retirer des partenaires"] = "Aus Partnern entfernen",
}

for k, v in pairs(de) do L[k] = v end
