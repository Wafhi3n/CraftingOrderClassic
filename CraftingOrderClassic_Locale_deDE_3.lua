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
    ["réseau par whisper"] = "Netzwerk über Flüstern",
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
}

for k, v in pairs(de3) do L[k] = v end
