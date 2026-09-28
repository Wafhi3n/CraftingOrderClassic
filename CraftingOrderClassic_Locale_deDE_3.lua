-- CraftingOrderClassic_Locale_deDE_3.lua — overlay deDE, 3/3. Clé FR → texte traduit.
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
    ["Crafting Order n'utilise plus de canal de discussion : sur WoW Forever, il est découpé en salles et les joueurs ne s'y voient pas tous.\n\nLes artisans se retrouvent maintenant dans la communauté |cFFFFD100%s|r. Rejoins-la ici, ou plus tard par le lien dans ton chat."] =
        "Crafting Order nutzt keinen Chatkanal mehr: Auf WoW Forever wird er in getrennte Räume aufgeteilt, und nicht alle Spieler sehen sich.\n\nHandwerker treffen sich jetzt in der Gemeinschaft |cFFFFD100%s|r. Tritt hier bei, oder später über den Link in deinem Chat.",
    ["Rejoindre"] = "Beitreten",
    ["Plus tard"] = "Später",
}

for k, v in pairs(de3) do L[k] = v end
