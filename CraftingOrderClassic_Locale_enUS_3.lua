-- CraftingOrderClassic_Locale_enUS_3.lua — overlay enUS, 3/3. Clé FR → texte traduit.
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
}

for k, v in pairs(en3) do L[k] = v end
