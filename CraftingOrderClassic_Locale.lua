-- CraftingOrderClassic_Locale.lua — socle de localisation du CHROME de l'UI.
-- Convention : la CLÉ est le texte FRANÇAIS (langue de référence du code) ; `COC.L[clé]` renvoie la
-- clé par défaut, donc un client FR voit le texte tel quel — zéro régression, aucun overlay à écrire.
-- Chaque AUTRE langue est un overlay chargé APRÈS ce fichier : _Locale_enUS / _deDE / _esES, tous de
-- même forme (early-return hors de leur locale). L'anglais vivait ici jusqu'à la v1.12.0 ; il en a été
-- extrait pour tenir sous le plafond anti-monolithe, et il est désormais un overlay comme les autres.
-- Ajouter une langue = copier un overlay, le lister dans les 3 .toc ET dans scripts\check_locale.ps1.
-- NB : les NOMS d'objets/recettes restent multilingues via GetItemInfo/GetSpellInfo (côté données).

local COC = CraftingOrderClassic
local L = setmetatable({}, { __index = function(_, k) return k end })
COC.L = L
