-- CraftingOrderClassic_Locale_esES_3.lua — overlay esES, 3/3. Clé FR » texte traduit.
-- Troisième part, ouverte le 2026-09-26 : _2 avait atteint le plafond anti-monolithe
-- (500 l/fichier) en accueillant les clés de la bande LFW. Même contrat que les deux
-- autres — table à plat fusionnée dans COC.L, aucun ordre requis entre les parts.

local COC = CraftingOrderClassic
local loc = GetLocale and GetLocale() or ""
if loc ~= "esES" and loc ~= "esMX" then return end
local L = COC.L

local es3 = {
    -- Bande « chercher du travail » + sélecteur d'offre (2026-09-26)
    ["Route"] = "Ruta",               -- languette courte (la vue garde « Ruta de subida »)
    ["Dispo — %s"] = "Disponible — %s",
    ["Offre"] = "Oferta",
    ["Réactifs"] = "Reactivos",
    ["Recettes"] = "Recetas",
    ["Aucun résultat pour cette recherche."] = "Ningun resultado para esa busqueda.",
    ["Rien à afficher pour ce métier."] = "Nada que mostrar para esta profesion.",
    ["Recettes proposées (%d/%d)"] = "Recetas ofrecidas (%d/%d)",
    -- Réseau sans canal + communauté officielle (2026-09-28)
    ["réseau par whisper"] = "red por susurros",
    ["canal : aucun — le réseau passe en whisper (cercles, amis, guilde)"] =
        "canal: ninguno — la red funciona por susurros (círculos, amigos, hermandad)",
    ["communauté officielle marquée comme cercle d'artisans : %s"] =
        "comunidad oficial marcada como círculo de artesanos: %s",
    ["Rejoins la communauté des artisans : %s — c'est là que Crafting Order trouve les autres joueurs."] =
        "Únete a la comunidad de artesanos: %s — ahí es donde Crafting Order encuentra a los demás jugadores.",
    ["(/co circle nolink : ne plus afficher ce rappel)"] = "(/co circle nolink: no volver a mostrar este aviso)",
    ["rappel de la communauté éteint — /co circle link pour le rallumer."] =
        "aviso de la comunidad desactivado — /co circle link para reactivarlo.",
    ["rappel de la communauté rallumé."] = "aviso de la comunidad reactivado.",
    -- Icône « nouvelle version » de la barre de la minicarte (2026-09-28)
    ["Tu as la %s. Mets l'addon à jour depuis CurseForge."] = "Tienes la %s. Actualiza el addon desde CurseForge.",
    ["Crafting Order n'utilise plus de canal de discussion : sur WoW Forever, il est découpé en salles et les joueurs ne s'y voient pas tous.\n\nLes artisans se retrouvent maintenant dans la communauté |cFFFFD100%s|r. Clique sur le lien dans ton chat pour y entrer."] =
        "Crafting Order ya no usa un canal de chat: en WoW Forever se divide en salas separadas y no todos los jugadores se ven.\n\nLos artesanos se reúnen ahora en la comunidad |cFFFFD100%s|r. Haz clic en el enlace de tu chat para unirte.",
    -- Signature du build de test, /co version (2026-09-28)
    ["Build : %s"] = "Build: %s",
    ["Branches en test : %s"] = "Ramas en prueba: %s",
    -- Aide remise à jour : onglets latéraux, cercles (2026-09-28)
    ["Ils se rangent sur le bord droit, comme ceux de la fenêtre de métier. Survole une icône pour lire son nom ; le chiffre sur le Carnet compte tes commandes en cours."] =
        "Están en el borde derecho, como los de la ventana de profesión. Pasa el ratón sobre un icono para leer su nombre; el número sobre el Libro cuenta tus pedidos activos.",
    ["|cFFE8B84BMes artisans|r : les métiers de tous les personnages de ton compte, et leurs recettes."] =
        "|cFFE8B84BMis artesanos|r: las profesiones de todos los personajes de tu cuenta, y sus recetas.",
    ["|cFFE8B84BAide|r et |cFFE8B84BNouveautés|r : cette page, et ce qui a changé à chaque version."] =
        "|cFFE8B84BAyuda|r y |cFFE8B84BNovedades|r: esta página, y lo que cambió en cada versión.",
    ["cercles d'artisans (communautés) et rappel de la communauté"] =
        "círculos de artesanos (comunidades) y el aviso de la comunidad",
    ["ou"] = "o",   -- statuts d'une commande, Aide : « (ou Annulée / Refusée) »
}

for k, v in pairs(es3) do L[k] = v end
