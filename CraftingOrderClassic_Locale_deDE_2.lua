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
}

for k, v in pairs(de2) do L[k] = v end
