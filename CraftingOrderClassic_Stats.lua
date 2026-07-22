-- CraftingOrderClassic_Stats.lua — STATS d'un objet : identité canonique + libellé localisé.
--
-- Brique PARTAGÉE, pensée pour le filtrage par stat (« montre-moi ce qui donne de la force ») aussi
-- bien sur les gemmes que sur les ÉQUIPEMENTS fabriqués. D'où la séparation stricte :
--   * `token`  = clé ITEM_MOD_* rendue par le client → l'IDENTITÉ, insensible à la langue. C'est
--                elle que doit indexer tout filtre ou toute sauvegarde, JAMAIS le libellé ;
--   * `label`  = _G[token], déjà traduit par le client → l'AFFICHAGE. Zéro traduction à maintenir,
--                même discipline que les libellés d'emplacement de _Enchant.lua.
--
-- DEUX SOURCES, dans cet ordre :
--   1. GetItemStats — l'API. Elle couvre les objets dont les stats sont des stats d'OBJET (armures,
--      armes), et rend les tokens canoniques ;
--   2. le TOOLTIP, en repli. Le bonus d'une GEMME n'est pas un stat d'objet mais un enchantement
--      porté par elle : selon la version du client, l'API peut ne rien rendre alors que le tooltip
--      affiche « +10 Force » (vérifié en jeu sur « Bold Crimson Spinel », TBC 2026-07-22). Le token
--      y est RETROUVÉ quand le libellé correspond à une globale ITEM_MOD_* du client (cf. modIndex)
--      — donc les gemmes restent filtrables. Sinon on garde le libellé seul, sans inventer de token :
--      l'objet sort du filtre par stat, ce qui vaut mieux qu'un filtre qui ment.
--
-- API : Stats:Of (liste triée) · Stats:LabelFor (libellé court) · Stats:TokensOf (pour un filtre).

local COC   = CraftingOrderClassic
local Stats = {}
COC.Stats   = Stats

-- Résolu une fois par itemID. Valeur = LISTE (éventuellement vide = « objet lu, aucune stat ») ;
-- une entrée ABSENTE veut dire « pas encore lisible », jamais « sans stat » — la nuance évite de
-- figer un résultat vide pris avant que le client n'ait reçu l'objet.
local _cache = {}

-- Clés que GetItemStats peut rendre et qu'on RETIENT : les stats (ITEM_MOD_*) et les résistances
-- (RESISTANCEn_NAME — l'équipement anti-feu de TBC est un usage réel du filtre).
-- Écartées : EMPTY_SOCKET_* (« Châsse rouge »). Une châsse n'est pas une stat — elle dit ce que
-- l'objet peut RECEVOIR, pas ce qu'il DONNE ; elle polluait le menu (vu en jeu 2026-07-22).
local function isStatKey(k)
    return k:find("^ITEM_MOD_") ~= nil or k:find("^RESISTANCE%d+_NAME$") ~= nil
end

-- Token CANONIQUE = le nom de base, sans le suffixe `_SHORT`.
-- ⚠️ Le client expose la même stat sous DEUX globales : `ITEM_MOD_CRIT_RATING` (« Improves critical
-- strike rating by %s. » — un GABARIT) et `ITEM_MOD_CRIT_RATING_SHORT` (« Critical Strike »).
-- GetItemStats rend la forme LONGUE, la reconnaissance au tooltip trouve la COURTE : sans cette
-- normalisation, une épée et une gemme donnant la même stat porteraient deux clés différentes et le
-- filtre en raterait une — panne SILENCIEUSE, la liste aurait juste l'air incomplète.
local function canon(token) return (token:gsub("_SHORT$", "")) end

-- Libellé d'affichage : la forme COURTE d'abord, et JAMAIS un gabarit (reconnaissable à son « % »).
-- nil si le client n'a pas de nom présentable pour cette stat → elle est ignorée plutôt qu'affichée
-- en phrase à trous (« Improves haste rating by %s. » en tête de menu, vu en jeu 2026-07-22).
local function labelOf(token)
    local base = canon(token)
    for _, k in ipairs({ base .. "_SHORT", base }) do
        local v = _G[k]
        if type(v) == "string" and v ~= "" and not v:find("%%") then return v end
    end
    return nil
end

-- =========================================================================
-- Cache PERSISTANT — les stats d'un objet ne changent pas
-- =========================================================================
-- Lire les stats coûte (scan de tooltip pour les gemmes), et c'est un coût qu'on payait à CHAQUE
-- session. Or la donnée est statique : autant la garder. Ce qu'on persiste est volontairement
-- MAIGRE — le libellé n'est stocké QUE pour les stats sans token, puisque partout ailleurs il se
-- redonne par `_G[token]`, donc toujours dans la langue COURANTE du client (changer la langue du jeu
-- n'invalide rien).
-- ⚠️ Verrouillé sur le BUILD du client : un patch peut rééquilibrer un objet, et un cache persistant
-- qui survivrait à ça servirait des stats fausses indéfiniment. Build différent = table repartie de
-- zéro. Création PARESSEUSE → aucune migration de schéma (cf. _Migrations.lua).
-- Version du FORMAT d'extraction. À incrémenter dès qu'on change ce qu'on met dans le cache : sans
-- ça, un joueur garderait les anciennes entrées jusqu'au prochain patch Blizzard.
-- v2 : tokens canoniques (sans `_SHORT`), libellés jamais issus d'un gabarit, châsses écartées.
-- v3 : lignes d'EFFET lues (consommables — les élixirs n'ont pas de stat d'objet).
local CACHE_VER = 3

local function store()
    local db = COC.db
    if not db then return nil end
    local build = (GetBuildInfo and select(2, GetBuildInfo())) or "?"
    local sc = db.statCache
    if type(sc) ~= "table" or sc.build ~= build or sc.ver ~= CACHE_VER then
        sc = { build = build, ver = CACHE_VER, items = {} }
        db.statCache = sc
    end
    sc.items = sc.items or {}
    return sc.items
end

-- Persisté -> forme de travail. Le libellé se redonne par la globale du client quand il y a un token.
local function thaw(rows)
    local out = {}
    for _, r in ipairs(rows or {}) do
        -- `labelOf` et PAS `_G[token]` : la globale nue est souvent le GABARIT (« Augmente
        -- l'endurance de %s. »). C'est le même piège que côté API, et il se rejouait ici à chaque
        -- relecture du cache — attrapé par le test de 2ᵉ session.
        local label = r.l or (r.t and labelOf(r.t))
        if type(label) == "string" and label ~= "" then
            out[#out + 1] = { token = r.t, label = label, value = r.v or 0 }
        end
    end
    return out
end

local function freeze(list)
    local out = {}
    for _, s in ipairs(list) do
        -- `l` seulement quand il n'y a PAS de token : sinon on figerait une traduction.
        out[#out + 1] = { t = s.token, v = s.value, l = (not s.token) and s.label or nil }
    end
    return out
end

local API = GetItemStats or (C_Item and C_Item.GetItemStats)

local TIP_NAME = "COCStatScanTip"
local scanTip
local function tip()
    if not scanTip then
        scanTip = CreateFrame("GameTooltip", TIP_NAME, UIParent, "GameTooltipTemplate")
        scanTip:SetOwner(UIParent, "ANCHOR_NONE")   -- ancré nulle part : il ne s'affiche jamais
    end
    return scanTip
end

local function byValueDesc(a, b)
    if a.value ~= b.value then return a.value > b.value end
    return (a.label or "") < (b.label or "")   -- départage STABLE (deux stats de même valeur)
end

-- Stats vues par l'API, avec leur token canonique. nil si l'API n'existe pas ou ne répond pas.
local function fromAPI(itemID)
    if not API then return nil end
    local ok, t = pcall(API, "item:" .. itemID)
    if not (ok and type(t) == "table") then return nil end
    local out = {}
    for token, value in pairs(t) do
        local label = isStatKey(token) and labelOf(token) or nil
        if label then
            out[#out + 1] = { token = canon(token), label = label, value = tonumber(value) or 0 }
        end
    end
    table.sort(out, byValueDesc)
    return out
end

-- Index { libellé localisé -> token } construit UNE fois depuis les globales ITEM_MOD_* du client.
-- Il sert à RETROUVER le token canonique d'une stat lue au tooltip : sans lui une gemme n'aurait
-- qu'un libellé traduit, donc rien d'indexable par un filtre. Les globales de FORMAT (celles qui
-- contiennent un « % ») sont écartées : ce sont des gabarits, pas des noms de stat.
local _modIndex
local function modIndex()
    if _modIndex then return _modIndex end
    _modIndex = {}
    for k, v in pairs(_G) do
        -- Même filtre que côté API (isStatKey), et le token stocké est CANONIQUE : c'est ce qui fait
        -- qu'une stat lue au tooltip et la même stat lue par GetItemStats portent la MÊME clé.
        if type(k) == "string" and type(v) == "string" and v ~= ""
           and isStatKey(k) and not v:find("%%") then
            local base = canon(k)
            local prev = _modIndex[v]
            if not prev or #base < #prev then _modIndex[v] = base end
        end
    end
    return _modIndex
end

-- Plus long libellé de stat connu qui PRÉFIXE `text` → label, token (nil si aucun ne colle).
-- « Le plus long » parce que plusieurs stats peuvent commencer pareil (« Spell Damage » vs
-- « Spell Damage and Healing ») : le préfixe court gagnerait à tort.
local function matchStat(text)
    local best, bestToken
    for label, token in pairs(modIndex()) do
        if #label > #(best or "") and text:find(label, 1, true) == 1 then
            best, bestToken = label, token
        end
    end
    return best, bestToken
end

-- Retire le LIANT en fin de segment (« Healing and » → « Healing »). Uniquement pour un segment
-- SUIVI d'un autre : le dernier n'a jamais de liant, donc on n'y risque pas d'amputer une stat.
local function stripJoiner(s)
    s = s:gsub("%s*[&,;]%s*$", "")
    s = s:gsub("%s+%a%a?%a?%a?$", "")   -- « and », « et », « und », « y » : un petit mot de liaison
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Découpe une ligne de bonus en stats. « +4 Healing and +5 Spell Damage » → DEUX entrées.
-- ⚠️ On découpe sur les « +N », JAMAIS sur le liant : Blizzard écrit tantôt « and », tantôt « & »
-- (vu en jeu : « Balanced Nightseye » vs « Infused Shadow Draenite », TBC 2026-07-22), et le liant
-- est TRADUIT. En coupant sur les nombres, le liant se retrouve en queue de segment et disparaît
-- avec la reconnaissance du nom de stat — sans qu'on ait à connaître un seul mot de liaison.
local function splitBonusLine(txt, out)
    local marks, pos = {}, 1
    while true do
        local s, e, num = txt:find("%+(%d+)", pos)
        if not s then break end
        marks[#marks + 1] = { s = s, e = e, value = tonumber(num) or 0 }
        pos = e + 1
    end
    for i, m in ipairs(marks) do
        local stop = marks[i + 1] and (marks[i + 1].s - 1) or #txt
        local body = txt:sub(m.e + 1, stop):match("^%s*(.-)%s*$") or ""
        local label, token = matchStat(body)
        if not label and body ~= "" then label = (i < #marks) and stripJoiner(body) or body end
        if label and label ~= "" then
            out[#out + 1] = { token = token, label = label, value = m.value }
        end
    end
end

-- Dernier repli — les CONSOMMABLES. Un élixir n'a aucune stat d'objet : il APPLIQUE un effet
-- (« Utiliser : augmente l'Agilité de 25 pendant 1 heure »). Aucune ligne ne commence par « +N »,
-- et pourtant c'est exactement ce que l'objet apporte — et ce qu'un alchimiste veut filtrer.
-- Sans ça, le menu de l'Alchimie n'offrait que les stats de ses rares bijoux (les Pierres
-- d'alchimiste), et choisir « Agilité » ne rendait PAS l'Élixir d'agilité (vu en jeu 2026-07-22).
-- Méthode : repérer le NOM d'une stat connue DU CLIENT n'importe où dans la ligne, et prendre le
-- premier nombre de cette ligne comme valeur. Aucune formulation n'est codée en dur, donc ça vaut
-- dans toutes les langues — c'est le même principe que la reconnaissance des liants.
-- On saute la ligne 1 (le NOM de l'objet) : « Élixir d'agilité » contient le mot, mais un nom n'est
-- pas un effet — s'y fier marcherait par accident et raterait tout ce qui ne se nomme pas ainsi.
local function fromEffectLines(lines, out)
    local seen = {}
    for i = 2, #lines do
        local txt = lines[i]
        local best, bestToken
        for label, token in pairs(modIndex()) do
            -- Le PLUS LONG libellé qui apparaît : « Puissance des sorts » doit gagner sur « sorts ».
            if #label > #(best or "") and txt:find(label, 1, true) then best, bestToken = label, token end
        end
        if best and not seen[bestToken] then
            seen[bestToken] = true
            out[#out + 1] = { token = bestToken, label = best, value = tonumber(txt:match("%d+")) or 0 }
        end
    end
    table.sort(out, byValueDesc)
end

-- Repli : les lignes du tooltip qui COMMENCENT par « +N ». Cette contrainte écarte d'elle-même les
-- lignes d'effet (« Équipé : … ») et la mention de châsse, qui est entre guillemets.
-- L'ordre du client est CONSERVÉ (pas de tri) : c'est lui qui met la stat principale en tête, et
-- l'en-tête doit se lire comme le tooltip que le joueur a sous les yeux.
-- nil = tooltip PAS PRÊT (voir plus bas), à distinguer d'une liste vide = objet lu mais sans stat.
local function fromTooltip(itemID)
    local tp = tip()
    tp:ClearLines()
    if not pcall(tp.SetHyperlink, tp, "item:" .. itemID) then return nil end
    -- ⚠️ 0 ligne = l'objet n'est PAS chargé (un objet chargé a toujours au moins sa ligne de nom).
    -- On rend nil, PAS `{}` : sans ça, une course rare (GetItemInfo chaud mais tooltip encore vide)
    -- ferait figer un résultat vide — en mémoire ET dans le cache persistant, qui ne s'invalide qu'au
    -- prochain patch. L'appelant réessaiera à l'arrivée des infos (cf. Stats:Of).
    local n = tp:NumLines()
    if n == 0 then return nil end
    local lines, out = {}, {}
    for i = 1, n do
        local fs = _G[TIP_NAME .. "TextLeft" .. i]
        lines[i] = fs and fs:GetText() or nil
        if lines[i] and lines[i]:find("^%s*%+%d") then splitBonusLine(lines[i], out) end
    end
    if #out == 0 then fromEffectLines(lines, out) end
    return out
end

-- Stats d'un objet, de la plus forte à la plus faible. Rend :
--   * une LISTE (éventuellement vide) quand l'objet a pu être lu ;
--   * nil tant qu'il ne l'a pas été — l'appelant doit alors réessayer plus tard, sans rien mettre en
--     cache. GetItemInfo sert de sonde : tant qu'il est froid, le tooltip serait vide lui aussi.
function Stats:Of(itemID)
    if not itemID then return nil end
    local hit = _cache[itemID]
    if hit then return hit end
    -- Déjà lu lors d'une session précédente : on ne retouche NI l'API NI le tooltip. C'est ce qui
    -- rend le balayage gratuit dès la 2ᵉ session, y compris pour les gemmes.
    local persisted = store()
    if persisted and persisted[itemID] then
        local list = thaw(persisted[itemID])
        _cache[itemID] = list
        return list
    end
    if not GetItemInfo(itemID) then return nil end
    local list = fromAPI(itemID)
    if not list or #list == 0 then
        -- L'API n'a rien vu : la vérité est peut-être au tooltip (gemme, consommable). Mais s'il n'est
        -- PAS PRÊT (nil), on abandonne SANS rien figer — mieux vaut réessayer qu'un vide définitif.
        local fromTip = fromTooltip(itemID)
        if not fromTip then return nil end
        list = fromTip
    end
    _cache[itemID] = list
    if persisted then persisted[itemID] = freeze(list) end
    return list
end

-- Libellé court : les `maxCount` stats les plus fortes (2 par défaut), jointes par « / ».
-- nil si l'objet n'est pas encore lisible OU s'il n'a aucune stat — dans les deux cas l'appelant
-- n'a rien à afficher, et c'est à lui de distinguer via Stats:Of s'il doit réessayer.
function Stats:LabelFor(itemID, maxCount)
    local list = self:Of(itemID)
    if not (list and #list > 0) then return nil end
    local parts = {}
    for i = 1, math.min(maxCount or 2, #list) do parts[#parts + 1] = list[i].label end
    return table.concat(parts, " / ")
end

-- Libellé COURT d'un token canonique, ou nil. Même résolution que la lecture (forme courte, jamais un
-- gabarit) → à utiliser partout où l'on a un token et veut l'afficher, plutôt qu'un `_G[token]` brut
-- qui rendrait souvent la phrase à trous « Améliore … de %s. ».
function Stats:TokenLabel(token) return token and labelOf(token) or nil end

-- Tokens canoniques d'un objet, en SET { [ITEM_MOD_x] = valeur }. C'est LA porte d'entrée d'un futur
-- filtre par stat : il compare des tokens, jamais du texte traduit. Vide quand les stats n'ont pu
-- être lues qu'au tooltip (cf. l'en-tête du fichier).
function Stats:TokensOf(itemID)
    local out = {}
    for _, s in ipairs(self:Of(itemID) or {}) do
        if s.token then out[s.token] = s.value end
    end
    return out
end

-- =========================================================================
-- Support du FILTRE PAR STAT
-- =========================================================================

-- Stats REELLEMENT presentes dans une liste d'entrees, pour peupler un selecteur. Jamais une liste
-- ecrite en dur : ce que produit la Forge n'a rien a voir avec la Joaillerie, et une extension de
-- plus n'a alors rien a mettre a jour. Un metier sans stat rend une liste vide.
-- ⚠️ Le balayage exige que chaque objet soit dans le cache du CLIENT. Tant qu'il en manque un, le
-- resultat n'est PAS mis en cache — il serait fige incomplet. Les objets manquants arrivent ensuite
-- (GET_ITEM_INFO_RECEIVED, deja ecoute par l'UI) et le balayage suivant les verra.
-- Couteux : a n'appeler QUE sur une action rare (ouverture du menu), jamais sur le chemin de rendu.
local _availCache = {}

function Stats:AvailableFor(key, entries, getItemID)
    local hit = key and _availCache[key]
    if hit then return hit end
    local seen, complete = {}, true
    for _, e in ipairs(entries or {}) do
        local itemID = getItemID(e)
        if itemID then
            local list = self:Of(itemID)
            if not list then complete = false end
            for _, s in ipairs(list or {}) do
                if s.token and not seen[s.token] then seen[s.token] = s.label end
            end
        end
    end
    local out = {}
    for token, label in pairs(seen) do out[#out + 1] = { token = token, label = label } end
    table.sort(out, function(a, b) return a.label < b.label end)
    if key and complete then _availCache[key] = out end
    return out
end

-- L'objet porte-t-il cette stat ? Compare des TOKENS, jamais du texte traduit — le meme filtre vaut
-- donc sur un client anglais et sur un client francais.
-- Un objet pas encore lisible rend false : il sort du filtre le temps que son info arrive, plutot
-- que d'entrer dans un resultat qu'on ne peut pas justifier. Le rendu se refait a l'arrivee des infos.
function Stats:Matches(itemID, token)
    if not token then return true end          -- aucune stat choisie = tout passe
    if not itemID then return false end
    for _, s in ipairs(self:Of(itemID) or {}) do
        if s.token == token then return true end
    end
    return false
end
