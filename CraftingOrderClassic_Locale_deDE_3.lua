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
}

for k, v in pairs(de3) do L[k] = v end
