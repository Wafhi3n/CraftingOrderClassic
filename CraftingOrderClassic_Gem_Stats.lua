-- CraftingOrderClassic_Gem_Stats.lua — correspondance TAILLE DE GEMME → STAT (données, éditées à la
-- main). Voir _Gem.lua pour le moteur ; en résumé :
--
--   * on déclare des groupes { stat = <clé de locale>, cuts = { <mots anglais>, … } } — donc dans le
--     sens STAT → TAILLES, parce qu'une même stat change de nom de taille d'une extension à l'autre
--     et qu'un futur FILTRE se pose exactement dans ce sens (« montre-moi les gemmes de pénétration
--     des sorts » = Gem:CutsForStat) ;
--   * les `cuts` sont les mots ANGLAIS canoniques, tels qu'ils ouvrent le nom de la gemme
--     (« Stormy Azure Moonstone » → "Stormy"). JAMAIS le mot français : il s'accorde en genre selon
--     la gemme, il éclaterait le groupe (cf. l'avertissement en tête de _Gem.lua) ;
--   * l'ORDRE des groupes EST l'ordre d'affichage des sous-en-têtes ;
--   * deux tailles sous la même stat partagent le RANG : leurs en-têtes sortent côte à côte, chacun
--     préfixé par la stat (« Endurance - Solide », puis « Endurance - Audacieux ») ;
--   * une taille ABSENTE d'ici n'est pas perdue — au contraire, c'est le cas NORMAL : voir ci-dessous.
--
-- ÉTAT : table VOLONTAIREMENT VIDE, et elle a vocation à le rester en grande partie.
-- La stat n'est PAS saisie ici : elle est LUE SUR L'OBJET par COC.Stats (GetItemStats, sinon le
-- tooltip), donc exacte, traduite par le client, et valable pour toutes les extensions — y compris
-- celles qui n'existent pas encore. L'en-tête sort déjà en « Force - Audacieux » sans rien déclarer.
--
-- Ce fichier ne sert donc qu'à CORRIGER les cas où la lecture automatique déçoit :
--   * une gemme dont le client ne dit rien d'exploitable (effet en texte libre, méta compliquée) ;
--   * un wording qu'on veut raccourcir ou uniformiser entre deux extensions ;
--   * un ordre d'affichage voulu (les stats déclarées passent avant les autres).
--
-- POUR EN AJOUTER UNE :
--   1. ajouter le groupe ci-dessous (l'ordre compte) ;
--   2. ajouter la clé `stat` dans les 3 overlays de locale, comme pour _RecipeCats_Alchemy — et si
--      le client possède déjà une globale au wording EXACT, la passer résolue plutôt qu'inventer une
--      traduction (c'est justement ce que fait la lecture automatique) ;
--   3. ces clés sont dynamiques → les déclarer dans scripts\check_locale_whitelist.lua, sinon le
--      contrôle de locale les croit mortes.
--
-- Forme attendue :
--   { stat = "Pénétration des sorts", cuts = { "Stormy" } },

local COC = CraftingOrderClassic
if not (COC and COC.Gem) then return end

COC.Gem:RegisterStats({
})
