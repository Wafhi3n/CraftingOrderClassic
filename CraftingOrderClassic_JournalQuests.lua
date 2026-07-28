-- CraftingOrderClassic_JournalQuests.lua — lecture EN SEULE LECTURE du journal de quêtes du JEU,
-- pour que le journal COC affiche les vraies quêtes à côté des commandes.
--
-- POURQUOI ON LIT AU LIEU D'INJECTER — décision structurante, ne pas la rouvrir : le journal natif
-- n'est PAS extensible. `QuestLog_Update` lit `GetNumQuestLogEntries()` / `GetQuestLogTitle(i)`, des
-- fonctions C sans API d'ajout, et sa liste est figée à `QUESTS_DISPLAYED = 6`. Y glisser nos
-- commandes voudrait dire réécrire la fonction de Blizzard et confisquer ses boutons de ligne — avec
-- un conflit frontal garanti avec Questie. On lit par l'API publique, on n'écrit jamais.
--
-- ⚠️ DEUX PIÈGES D'API, tous deux liés au fait que ce journal est un ÉTAT PARTAGÉ :
--
--  1. `GetQuestLogQuestText` et `GetQuestLogLeaderBoard` lisent la SÉLECTION COURANTE du journal du
--     jeu. La changer perturbe la fenêtre native et tout addon qui s'y fie. On sauvegarde donc
--     `GetQuestLogSelection()`, on sélectionne, on lit, ON RESTAURE — sans exception.
--
--  2. Un en-tête de zone REPLIÉ dans le journal natif masque ses quêtes à l'énumération : elles ne
--     sortent tout simplement pas de `GetQuestLogTitle`. On pourrait tout déplier
--     (`ExpandQuestHeader(0)`) — on ne le fait PAS : ce serait modifier l'affichage du joueur pour
--     notre confort, et l'état replié n'est pas restaurable proprement. On affiche donc ce qui est
--     visible, et on marque la section repliée telle quelle. Honnête et sans effet de bord.
--
-- Aucune UI ici : ce module rend des données.

local COC = CraftingOrderClassic
local Q = {}
COC.JournalQuests = Q

local function api()
    return GetNumQuestLogEntries and GetQuestLogTitle and true or false
end

-- Le TAG affiché par le journal natif — « (Complete) », « (Daily) », « (Failed) », « (Daily PvP) » —
-- n'est PAS rendu tel quel par l'API : Blizzard le compose (QuestLogFrame.lua:193-204). On reproduit
-- sa logique EXACTE, sinon nos libellés divergeraient des siens sous les yeux du joueur — et les
-- chaînes viennent de ses globales, donc traduites partout sans passer par notre locale.
-- `isComplete` est un NOMBRE signé (négatif = échouée), pas un booléen : `tonumber` avant de comparer.
local function questTag(rawTag, isComplete, frequency)
    local ic = tonumber(isComplete) or 0
    if ic < 0 then return _G.FAILED end
    if ic > 0 then return _G.COMPLETE end
    if frequency and _G.LE_QUEST_FREQUENCY_DAILY and frequency == _G.LE_QUEST_FREQUENCY_DAILY then
        if rawTag and _G.DAILY_QUEST_TAG_TEMPLATE then
            return string.format(_G.DAILY_QUEST_TAG_TEMPLATE, rawTag)
        end
        return rawTag or _G.DAILY
    end
    return rawTag
end

-- Les quêtes du joueur, groupées par en-tête de zone, dans l'ordre du journal natif.
-- -> { { header = "Hellfire Peninsula", collapsed = bool, quests = { {index, title, level, tag, complete} } } }
function Q:Groups()
    if not api() then return {} end
    local groups, current = {}, nil
    for i = 1, (GetNumQuestLogEntries() or 0) do
        local title, level, rawTag, isHeader, isCollapsed, isComplete, frequency = GetQuestLogTitle(i)
        if title and isHeader then
            current = { header = title, collapsed = isCollapsed and true or false, quests = {} }
            groups[#groups + 1] = current
        elseif title then
            if not current then                       -- quête sans en-tête (ne devrait pas arriver)
                current = { header = "", collapsed = false, quests = {} }
                groups[#groups + 1] = current
            end
            current.quests[#current.quests + 1] = {
                index = i, title = title, level = level,
                tag = questTag(rawTag, isComplete, frequency),
                complete = (tonumber(isComplete) or 0) > 0,
            }
        end
    end
    return groups
end

-- Détail d'une quête : description, texte d'objectif, et lignes d'objectifs avec leur état.
-- La sélection du journal du jeu est sauvegardée puis RESTAURÉE (cf. piège 1 en tête de fichier).
function Q:Detail(index)
    if not (index and SelectQuestLogEntry and GetQuestLogQuestText) then return nil end
    local prev = GetQuestLogSelection and GetQuestLogSelection()
    SelectQuestLogEntry(index)
    local desc, objText = GetQuestLogQuestText()
    local lines = {}
    for j = 1, (GetNumQuestLeaderBoards and GetNumQuestLeaderBoards() or 0) do
        local text, _, finished = GetQuestLogLeaderBoard(j)
        if text and text ~= "" then
            lines[#lines + 1] = { text = text, done = finished and true or false }
        end
    end
    if prev and prev > 0 then SelectQuestLogEntry(prev) end
    -- Sans aucune ligne d'objectif (quête « parle à X »), le texte d'objectif fait office de ligne
    -- unique — sinon la fiche s'afficherait sans aucun objectif, ce qui est faux.
    if #lines == 0 and objText and objText ~= "" then lines[1] = { text = objText, done = false } end
    return { description = desc, objectiveText = objText, lines = lines }
end

-- Le donneur n'est pas exposé par l'API du journal (il n'est connu qu'à l'acceptation) : on rend le
-- niveau de la quête, seule information de contexte disponible côté journal.
function Q:GiverLine(entry)
    if not (entry and entry.level) then return "" end
    local fmt = _G.QUEST_LOG_ITEM_LEVEL or _G.LEVEL or "%d"
    if fmt:find("%%d") then return string.format(fmt, entry.level) end
    return fmt .. " " .. entry.level
end
