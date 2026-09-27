-- CraftingOrderClassic_Locale_esES_3.lua — overlay esES, 3/3. Clé FR → texte traduit.
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
}

for k, v in pairs(es3) do L[k] = v end
