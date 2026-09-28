-- CraftingOrderClassic_Locale_enUS_3.lua — overlay enUS, 3/3. Clé FR » texte traduit.
-- Troisième part, ouverte le 2026-09-26 : _2 avait atteint le plafond anti-monolithe
-- (500 l/fichier) en accueillant les clés de la bande LFW. Même contrat que les deux
-- autres — table à plat fusionnée dans COC.L, aucun ordre requis entre les parts.

local COC = CraftingOrderClassic
local loc = GetLocale and GetLocale() or "enUS"
if loc ~= "enUS" and loc ~= "enGB" then return end
local L = COC.L

local en3 = {
    -- Bande « chercher du travail » + sélecteur d'offre (2026-09-26)
    ["Route"] = "Route",              -- languette courte (la vue garde « Leveling route »)
    ["Dispo — %s"] = "Available — %s",
    ["Offre"] = "Offer",
    ["Réactifs"] = "Reagents",
    ["Recettes"] = "Recipes",
    ["Aucun résultat pour cette recherche."] = "Nothing matches that search.",
    ["Rien à afficher pour ce métier."] = "Nothing to show for this profession.",
    ["Recettes proposées (%d/%d)"] = "Offered recipes (%d/%d)",
    -- Réseau sans canal + communauté officielle (2026-09-28)
    ["réseau par whisper"] = "whisper network",
    ["canal : aucun — le réseau passe en whisper (cercles, amis, guilde)"] =
        "channel: none — the network runs on whispers (circles, friends, guild)",
    ["communauté officielle marquée comme cercle d'artisans : %s"] =
        "official community marked as your crafters' circle: %s",
    ["Rejoins la communauté des artisans : %s — c'est là que Crafting Order trouve les autres joueurs."] =
        "Join the crafters' community: %s — that's where Crafting Order finds other players.",
    ["(/co circle nolink : ne plus afficher ce rappel)"] = "(/co circle nolink: stop showing this reminder)",
    ["rappel de la communauté éteint — /co circle link pour le rallumer."] =
        "community reminder off — /co circle link turns it back on.",
    ["rappel de la communauté rallumé."] = "community reminder back on.",
    -- Icône « nouvelle version » de la barre de la minicarte (2026-09-28)
    ["Tu as la %s. Mets l'addon à jour depuis CurseForge."] = "You have %s. Update the addon from CurseForge.",
    ["Crafting Order n'utilise plus de canal de discussion : sur WoW Forever, il est découpé en salles et les joueurs ne s'y voient pas tous.\n\nLes artisans se retrouvent maintenant dans la communauté |cFFFFD100%s|r. Clique sur le lien dans ton chat pour y entrer."] =
        "Crafting Order no longer uses a chat channel: on WoW Forever it gets split into separate rooms, so players can't all see each other.\n\nCrafters now meet in the |cFFFFD100%s|r community. Click the link in your chat to join it.",
    -- Signature du build de test, /co version (2026-09-28)
    ["Build : %s"] = "Build: %s",
    ["Branches en test : %s"] = "Branches under test: %s",
    -- Aide remise à jour : onglets latéraux, cercles (2026-09-28)
    ["Ils se rangent sur le bord droit, comme ceux de la fenêtre de métier. Survole une icône pour lire son nom ; le chiffre sur le Carnet compte tes commandes en cours."] =
        "They sit along the right edge, like the ones on the profession window. Hover an icon to read its name; the number on the Ledger counts your active orders.",
    ["|cFFE8B84BMes artisans|r : les métiers de tous les personnages de ton compte, et leurs recettes."] =
        "|cFFE8B84BMy Artisans|r: the professions of every character on your account, and their recipes.",
    ["|cFFE8B84BAide|r et |cFFE8B84BNouveautés|r : cette page, et ce qui a changé à chaque version."] =
        "|cFFE8B84BHelp|r and |cFFE8B84BWhat's New|r: this page, and what changed in each version.",
    ["cercles d'artisans (communautés) et rappel de la communauté"] =
        "crafters' circles (communities) and the community reminder",
}

for k, v in pairs(en3) do L[k] = v end
