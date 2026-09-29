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
    -- Vue Profit : bascule « tout le métier », source du prix, coupe HV, Enchantement par le coût (2026-09-29)
    ["Tout le métier"] = "Ganzer Beruf",
    ["Ajoute, en gris, les recettes que tu n'as pas encore apprises."] =
        "Fügt die Rezepte, die du noch nicht gelernt hast, in Grau hinzu.",
    ["Pas encore apprise : la vue « Manquantes » dit où l'apprendre."] =
        "Noch nicht gelernt: Die Ansicht „Fehlend“ zeigt, wo du es lernst.",
    ["Vente (prix marchand)"] = "Verkauf (Händlerpreis)",
    ["Coupe HV (%d %%)"] = "AH-Gebühr (%d %%)",
    ["Un marchand vend cet objet : l'HV ne le paiera pas plus cher."] =
        "Ein Händler verkauft diesen Gegenstand: Im AH zahlt niemand mehr dafür.",
    ["Coût à lancer (%d)"] = "Kosten pro Wirken (%d)",
    ["Ce que coûte un lancer, pas un gain : ta commission vient en plus."] =
        "Was dich ein Wirken kostet, kein Gewinn: Deine Provision kommt obendrauf.",
    ["Aucun coût connu (prix : %s)."] = "Keine Kosten bekannt (Preise: %s).",
}

for k, v in pairs(de3) do L[k] = v end
