-- CraftingOrderClassic_Locale_deDE_3.lua — overlay deDE, 3/3. Clé FR » texte traduit.
-- Troisième part, ouverte le 2026-09-26 : _2 avait atteint le plafond anti-monolithe
-- (500 l/fichier) en accueillant les clés de la bande LFW. Même contrat que les deux
-- autres — table à plat fusionnée dans COC.L, aucun ordre requis entre les parts.

local COC = CraftingOrderClassic
if (GetLocale and GetLocale() or "") ~= "deDE" then return end
local L = COC.L

local de3 = {
    -- Bande « chercher du travail » + sélecteur d'offre (2026-09-26)
    ["Route"] = "Route",              -- languette courte (la vue garde « Levelroute »)
    ["Dispo — %s"] = "Verfuegbar — %s",
    ["Offre"] = "Angebot",
    ["Réactifs"] = "Reagenzien",
    ["Recettes"] = "Rezepte",
    ["Aucun résultat pour cette recherche."] = "Keine Treffer fuer diese Suche.",
    ["Rien à afficher pour ce métier."] = "Fuer diesen Beruf gibt es nichts anzuzeigen.",
    ["Recettes proposées (%d/%d)"] = "Angebotene Rezepte (%d/%d)",
    -- Réseau sans canal + communauté officielle (2026-09-28)
    ["par whisper"] = "über Flüstern",   -- suit « réseau » (barre du bas, /co status)
    ["canal : aucun — le réseau passe en whisper (cercles, amis, guilde)"] =
        "Kanal: keiner — das Netzwerk läuft über Flüstern (Kreise, Freunde, Gilde)",
    ["communauté officielle marquée comme cercle d'artisans : %s"] =
        "offizielle Gemeinschaft als Handwerkerkreis markiert: %s",
    ["Rejoins la communauté des artisans : %s — c'est là que Crafting Order trouve les autres joueurs."] =
        "Tritt der Handwerker-Gemeinschaft bei: %s — dort findet Crafting Order die anderen Spieler.",
    ["(/co circle nolink : ne plus afficher ce rappel)"] = "(/co circle nolink: diese Erinnerung nicht mehr anzeigen)",
    ["rappel de la communauté éteint — /co circle link pour le rallumer."] =
        "Gemeinschafts-Erinnerung aus — /co circle link schaltet sie wieder ein.",
    ["rappel de la communauté rallumé."] = "Gemeinschafts-Erinnerung wieder an.",
    -- Icône « nouvelle version » de la barre de la minicarte (2026-09-28)
    ["Tu as la %s. Mets l'addon à jour depuis CurseForge."] = "Du hast %s. Aktualisiere das Addon über CurseForge.",
    ["Crafting Order n'utilise plus de canal de discussion : sur WoW Forever, il est découpé en salles et les joueurs ne s'y voient pas tous.\n\nLes artisans se retrouvent maintenant dans la communauté |cFFFFD100%s|r. Clique sur le lien dans ton chat pour y entrer."] =
        "Crafting Order nutzt keinen Chatkanal mehr: Auf WoW Forever wird er in getrennte Räume aufgeteilt, und nicht alle Spieler sehen sich.\n\nHandwerker treffen sich jetzt in der Gemeinschaft |cFFFFD100%s|r. Klicke auf den Link in deinem Chat, um beizutreten.",
    -- Signature du build de test, /co version (2026-09-28)
    ["Build : %s"] = "Build: %s",
    ["Branches en test : %s"] = "Branches im Test: %s",
    -- Salle de découverte, Directory_Room (2026-09-29)
    ["l'addon rejoint le canal |cFFFFFFFF%s|r pour se présenter aux autres joueurs de Crafting Order ; tes commandes, elles, restent en whisper. |cFFFFFFFF/co channel room off|r pour ne plus le rejoindre."] =
        "das Addon betritt den Kanal |cFFFFFFFF%s|r, um sich anderen Crafting-Order-Spielern vorzustellen; deine Aufträge laufen weiter per Flüstern. |cFFFFFFFF/co channel room off|r, um ihn nicht mehr zu betreten.",
    ["salle de découverte coupée : l'addon quitte |cFFFFFFFF%s|r et ne le rejoindra plus."] =
        "Entdeckungsraum aus: das Addon verlässt |cFFFFFFFF%s|r und betritt ihn nicht mehr.",
    ["salle de découverte rouverte : l'addon rejoint |cFFFFFFFF%s|r pour se présenter."] =
        "Entdeckungsraum wieder an: das Addon betritt |cFFFFFFFF%s|r, um sich vorzustellen.",
    ["salle de découverte : en attente du canal (quelques secondes après la connexion)"] =
        "Entdeckungsraum: warte auf den Kanal (einige Sekunden nach dem Einloggen)",
    ["salle de découverte : coupée — |cFFFFFFFF/co channel room on|r pour la rouvrir"] =
        "Entdeckungsraum: aus — |cFFFFFFFF/co channel room on|r, um ihn wieder einzuschalten",
    ["salle de découverte : |cFFFFFFFF%s|r — on s'y présente, les données restent en whisper"] =
        "Entdeckungsraum: |cFFFFFFFF%s|r — dient zum Vorstellen, Daten laufen weiter per Flüstern",
    -- Annonce sur Trade (Services), Orders_AnnounceSend (2026-09-29)
    ["Annoncer en Commerce"] = "Im Handelskanal ankündigen",
    ["Poste aussi une ligne sur Trade (Services), lisible par tous : les joueurs avec ou sans l'addon voient ta commande. Une ligne par clic, jamais de répétition automatique ; seulement pour une commande à tous, dans une capitale."] =
        "Schreibt zusätzlich eine für alle lesbare Zeile in Handel (Dienstleistungen): Spieler mit und ohne Addon sehen deinen Auftrag. Eine Zeile pro Klick, nie automatisch wiederholt; nur für einen Auftrag an alle, in einer Hauptstadt.",
    ["seule une commande ouverte, à toi, s'annonce."] = "nur ein offener Auftrag von dir kann angekündigt werden.",
    ["commande privée : elle ne s'annonce pas sur Commerce."] = "privater Auftrag: er wird nie im Handelskanal angekündigt.",
    ["déjà annoncée : tu pourras la rappeler dans %d min."] = "schon angekündigt: du kannst ihn in %d Min. wiederholen.",
    ["une annonce par minute au plus : attends encore %d s."] = "höchstens eine Ankündigung pro Minute: warte noch %d s.",
    ["pas de canal Trade (Services) ici : il faut être dans une capitale."] =
        "hier gibt es keinen Kanal Handel (Dienstleistungen): du musst in einer Hauptstadt sein.",
    ["annonce impossible : un objet n'est pas encore connu du jeu, réessaie dans un instant."] =
        "Ankündigung noch nicht möglich: ein Gegenstand ist noch nicht geladen, versuche es gleich noch einmal.",
    ["annonce refusée par le jeu."] = "das Spiel hat die Ankündigung abgelehnt.",
    ["commande annoncée sur %s."] = "Auftrag in %s angekündigt.",
    ["Clic droit : annoncer en Commerce"] = "Rechtsklick: im Handelskanal ankündigen",
    ["Clic droit : rappeler en Commerce"] = "Rechtsklick: im Handelskanal wiederholen",
    -- Annonce de la dispo LFW (2026-09-30)
    ["dispo annoncée sur %s."] = "Verfügbarkeit in %s angekündigt.",
    ["Quand tu actives ta dispo, poste aussi une ligne sur Trade (Services) : les joueurs avec ou sans l'addon voient que tu cherches du travail. Une ligne par activation, jamais au renouvellement automatique ; dans une capitale. Même réglage que la case du formulaire de commande."] =
        "Wenn du die Arbeitssuche einschaltest, wird zusätzlich eine Zeile in Handel (Dienstleistungen) gepostet: Spieler mit oder ohne das Addon sehen, dass du Arbeit suchst. Eine Zeile pro Einschalten, nie bei der automatischen Erneuerung; nur in einer Hauptstadt. Dieselbe Einstellung wie das Kästchen im Auftragsformular.",
    -- Aide sans communauté officielle (2026-09-30)
    ["|cFFFFFFFF/co circle|r : tes cercles d'artisans (les communautés du jeu que tu as marquées)."] =
        "|cFFFFFFFF/co circle|r: deine Handwerkerkreise (die Spielgemeinschaften, die du markiert hast).",
    ["Les artisans se trouvent par tes amis et ta guilde, et par les canaux que tu coches dans l'onglet Artisans, liste « Canaux surveillés » : Commerce, la salle de découverte, tes communautés, les joueurs autour de toi. Le bouton « Configurer » y rouvre le panneau du premier lancement."] =
        "Handwerker finden sich über deine Freunde und deine Gilde sowie über die Kanäle, die du im Reiter „Handwerker“ unter „Beobachtete Kanäle“ anhakst: Handel, der Entdeckungsraum, deine Gemeinschaften, die Spieler um dich herum. Der Knopf „Einrichten“ öffnet dort das Fenster des ersten Starts erneut.",
    -- Aide remise à jour : onglets latéraux, cercles (2026-09-28)
    ["Ils se rangent sur le bord droit, comme ceux de la fenêtre de métier. Survole une icône pour lire son nom ; le chiffre sur le Carnet compte tes commandes en cours."] =
        "Sie sitzen am rechten Rand, wie im Berufsfenster. Fahre über ein Symbol, um seinen Namen zu lesen; die Zahl am Auftragsbuch zählt deine aktiven Aufträge.",
    ["|cFFE8B84BMes artisans|r : les métiers de tous les personnages de ton compte, et leurs recettes."] =
        "|cFFE8B84BMeine Handwerker|r: die Berufe aller Charaktere deines Kontos und ihre Rezepte.",
    ["|cFFE8B84BAide|r et |cFFE8B84BNouveautés|r : cette page, et ce qui a changé à chaque version."] =
        "|cFFE8B84BHilfe|r und |cFFE8B84BNeues|r: diese Seite und was sich in jeder Version geändert hat.",
    ["cercles d'artisans (communautés) et rappel de la communauté"] =
        "Handwerkerkreise (Gemeinschaften) und die Gemeinschafts-Erinnerung",
    ["ou"] = "oder",   -- statuts d'une commande, Aide : « (ou Annulée / Refusée) »
    -- Courrier : l'addon ne coupe plus une pile lui-même (2026-09-28)
    ["Il en manque %d au courrier : sépare-les d'une pile toi-même (Maj-clic sur la pile), puis dépose-les."] =
        "Es fehlen noch %d in der Post: Trenne sie selbst von einem Stapel ab (Umschalt-Klick auf den Stapel) und lege sie hinein.",
    ["La pile de %d est prête dans ton sac : dépose-la toi-même dans le courrier."] =
        "Der Stapel mit %d liegt bereit in deiner Tasche: Lege ihn selbst in die Post.",
    -- Note de membre de la communauté, /co note (2026-09-29)
    ["le texte de tes métiers, à coller dans ta note de communauté (visible même hors ligne)"] =
        "der Text deiner Berufe, zum Einfügen in deine Gemeinschaftsnotiz (auch offline sichtbar)",
    ["aucun métier connu pour ce personnage : ouvre une fois ta fenêtre de métier, puis recommence."] =
        "für diesen Charakter ist noch kein Beruf bekannt: öffne einmal dein Berufsfenster und versuche es dann erneut.",
    ["Copie ce texte (Ctrl+C), puis colle-le dans ta note de membre : Communautés, clic droit sur ton nom, « Note ». Les autres joueurs de Crafting Order verront tes métiers, même quand tu es hors ligne."] =
        "Kopiere diesen Text (Strg+C) und füge ihn in deine Mitgliedsnotiz ein: Gemeinschaften, Rechtsklick auf deinen Namen, „Notiz“. Andere Crafting-Order-Spieler sehen dann deine Berufe, auch wenn du offline bist.",
    -- Lib absente au chargement (2026-09-30)
    ["la bibliothèque CraftLink n'a pas pu se charger : le réseau de l'addon est coupé (annuaire, commandes). Fais |cFFFFFFFF/reload|r ; si ça continue, réinstalle l'addon."] =
        "die Bibliothek CraftLink konnte nicht geladen werden: das Netzwerk des Addons ist aus (Verzeichnis, Aufträge). Gib |cFFFFFFFF/reload|r ein; wenn es wieder passiert, installiere das Addon neu.",
    -- Canaux surveillés : l'origine d'une entrante lue sur le canal Général (2026-09-30)
    ["général"] = "Allgemein",
    -- Canaux surveillés : la section de l'onglet Artisans (2026-09-30)
    ["CANAUX SURVEILLÉS"] = "BEOBACHTETE KANÄLE",
    ["ANNONCES LUES"] = "GELESENE ANKÜNDIGUNGEN",
    ["L'addon y lit les demandes, les dispos et les annonces des autres joueurs de l'addon. Il n'écrit que sur Trade (Services), et seulement si tu coches « Annoncer en Commerce »."] =
        "Das Addon liest dort Gesuche, Verfügbarkeiten und die Ankündigungen anderer Addon-Nutzer. Es schreibt nur in Handel (Dienstleistungen), und nur, wenn du „Im Handelskanal ankündigen“ anhakst.",
    ["Commerce (Services)"] = "Handel (Dienstleistungen)",
    ["Commerce"] = "Handel",
    ["Commerce (local)"] = "Handel (Lokal)",
    ["Général"] = "Allgemein",
    ["en ville"] = "in der Stadt",
    ["RÉSEAU DE L'ADDON"] = "ADDON-NETZWERK",
    ["L'addon s'y présente par un message invisible aux joueurs de ta salle ; ensuite, tout passe en chuchotement."] =
        "Das Addon stellt sich dort mit einer unsichtbaren Nachricht den Spielern in deinem Raum vor; danach läuft alles per Flüstern.",
    ["salle"] = "Raum",
    ["COMMUNAUTÉS"] = "GEMEINSCHAFTEN",
    ["Les membres d'une communauté cochée rejoignent ton annuaire, même hors ligne. Aucune donnée de l'addon n'y passe."] =
        "Die Mitglieder einer angehakten Gemeinschaft kommen in dein Verzeichnis, auch offline. Es laufen keine Addon-Daten darüber.",
    ["aucune communauté"] = "keine Gemeinschaft",
    ["AUTOUR DE MOI"] = "UM MICH HERUM",
    ["Ce que les joueurs disent ou crient près de toi (les lignes LFW), et, en ville, ceux que tu vois crafter."] =
        "Was Spieler in deiner Nähe sagen oder schreien (LFW-Zeilen) und, in der Stadt, wen du beim Herstellen siehst.",
    ["Dire et crier"] = "Sagen und Schreien",
    ["Crafteurs autour"] = "Handwerker in der Nähe",
    ["NOTIFICATIONS"] = "BENACHRICHTIGUNGEN",
    ["Ce qui te prévient : une ligne dans le chat, un bandeau et un son. Décochée, une case ne retire aucune commande : tout reste dans le Carnet et la vue métier."] =
        "Was dich benachrichtigt: eine Chatzeile, ein Banner und ein Ton. Ein abgewähltes Kästchen entfernt keinen Auftrag: alles bleibt im Auftragsbuch und in der Berufsansicht.",
    ["Commandes de l'addon"] = "Aufträge des Addons",
    ["Les commandes que les autres joueurs de l'addon t'envoient ou publient."] =
        "Aufträge, die andere Addon-Nutzer dir schicken oder veröffentlichen.",
    ["Demandes lues dans le chat"] = "Im Chat gelesene Anfragen",
    ["Les demandes (« WTB [objet] ») lues dans les canaux cochés plus haut, pour ce que tu sais crafter."] =
        "Anfragen („WTB [Gegenstand]“) aus den oben angehakten Kanälen, für das, was du herstellen kannst.",
    ["Guilde, amis et pour moi"] = "Gilde, Freunde und ich",
    ["Pas les commandes publiques ouvertes à tous."] = "Nicht die öffentlichen Aufträge für alle.",
    ["Seulement pour moi"] = "Nur für mich",
    ["Les commandes à ton nom ou à celui d'un de tes persos."] = "Aufträge auf deinen Namen oder den eines deiner Charaktere.",
    ["Aussi les commandes publiques, pour un métier que tu as."] = "Auch öffentliche Aufträge, für einen Beruf, den du hast.",
    ["Suivi de mes commandes"] = "Verlauf meiner Aufträge",
    ["Une commande qu'on t'a remise, dont on a confirmé la réception, ou qu'on a refusée."] = "Ein Auftrag, der dir übergeben, als erhalten bestätigt oder abgelehnt wurde.",
    ["Message à la connexion"] = "Nachricht beim Einloggen",
    ["La ligne « chargé — /co help » quand tu te connectes."] = "Die Zeile „geladen — /co help“ beim Einloggen.",
    ["FAÇON DE PRÉVENIR"] = "ART DER BENACHRICHTIGUNG",
    ["Pour toutes les alertes cochées au-dessus."] = "Für alle oben angehakten Hinweise.",
    ["Ligne dans le chat"] = "Zeile im Chat",
    ["Bandeau à l'écran"] = "Banner auf dem Bildschirm",
    ["Son"] = "Ton",
    ["Tu n'es pas dans ce canal en ce moment. Ton choix est gardé pour ton retour."] =
        "Du bist gerade nicht in diesem Kanal. Deine Wahl bleibt für deine Rückkehr erhalten.",
    -- Refonte de l'onglet Artisans (2026-09-30) : la bande des joueurs croisés, le bouton qui rouvre le panneau
    ["Croisés"] = "Getroffen",
    ["Configurer"] = "Einrichten",
    ["Rouvre le panneau de première connexion."] = "Öffnet das Fenster der ersten Anmeldung erneut.",
    -- Canaux surveillés : le panneau de première connexion (2026-09-30)
    ["Où chercher les artisans ?"] = "Wo nach Handwerkern suchen?",
    ["L'addon trouve les artisans par les canaux que tu coches ici. Tu pourras tout changer plus tard, dans l'onglet Artisans."] =
        "Das Addon findet Handwerker über die Kanäle, die du hier anhakst. Du kannst später alles im Reiter „Handwerker“ ändern.",
    ["Annoncer aussi mes commandes et ma dispo sur Trade (Services)"] =
        "Meine Aufträge und meine Verfügbarkeit auch in Handel (Dienstleistungen) ankündigen",
    ["Une ligne lisible par tous, seulement quand tu cliques."] = "Eine Zeile, die alle lesen können, nur wenn du klickst.",
    ["Valider"] = "Bestätigen",
    -- Icône « une commande t'attend » de la barre de la minicarte (2026-09-28)
    ["Commandes à ton nom : %d"] = "Aufträge auf deinen Namen: %d",
    ["pour %s"] = "für %s",
    -- 3e tour : le clic vers le perso qui sait faire, les commandes non nommées (2026-09-30)
    ["Pour ta guilde ou tes amis : %d"] = "Für deine Gilde oder Freunde: %d",
    ["Pour tous : %d"] = "Für alle: %d",
    ["Clic : ouvrir %s de %s."] = "Klick: %s von %s öffnen.",
    ["Clic : voir pourquoi."] = "Klick: Grund anzeigen.",
    ["Hors combat seulement."] = "Nur außerhalb des Kampfes.",
    ["Où l'apprendre : %s"] = "Wo man es lernt: %s",
    ["Aucun de tes persos ne sait faire %s."] = "Keiner deiner Charaktere kann %s herstellen.",
    ["%d commandes attendent dans ce métier."] = "%d Aufträge warten in diesem Beruf.",
    ["Ouvrir la fenêtre de métier"] = "Berufsfenster öffnen",

    -- Signaler un bug ou une idée (CraftingOrderClassic_Report.lua, 2026-10-07)
    ["Signaler un bug ou proposer une idée"] = "Fehler melden oder Idee vorschlagen",
    ["Bug"] = "Fehler",
    ["Idée"] = "Idee",
    ["Sans compte GitHub"] = "Kein GitHub-Konto",
    ["Lien copié : colle-le (Ctrl+V) dans ton navigateur."] = "Link kopiert: Füge ihn (Strg+V) in deinen Browser ein.",
    ["Copie ce lien (Ctrl+C) et ouvre-le dans ton navigateur : le formulaire arrive avec la version déjà remplie."] = "Kopiere diesen Link (Strg+C) und öffne ihn in deinem Browser: Das Formular erscheint mit bereits ausgefüllter Version.",
    ["Pas de compte GitHub ? Copie ce lien (Ctrl+C) et laisse un commentaire sur la page CurseForge."] = "Kein GitHub-Konto? Kopiere diesen Link (Strg+C) und hinterlasse einen Kommentar auf der CurseForge-Seite.",
    ["Un bug, ou une idée pour l'addon ? Choisis ci-dessous : l'addon te donne le lien du formulaire, déjà rempli."] = "Ein Fehler oder eine Idee für das Addon? Wähle unten: Das Addon gibt dir den Link zum bereits ausgefüllten Formular.",
    ["signaler un bug ou proposer une idée (lien vers un ticket GitHub)"] = "Fehler melden oder Idee vorschlagen (Link zu einem GitHub-Issue)",
    -- Le destinataire en une liste, Commande et Récolte (2026-09-30)
    ["Envoyer à"] = "Senden an",
    ["Liste"] = "Liste",
    ["Tous (avec l'addon)"] = "Alle mit dem Addon",
    ["ou un artisan"] = "oder ein Handwerker",
    ["ou un récolteur"] = "oder ein Sammler",
    ["Annoncer en Commerce (en capitale)"] = "Im Handelskanal ankündigen (nur in Hauptstädten)",
}

for k, v in pairs(de3) do L[k] = v end
