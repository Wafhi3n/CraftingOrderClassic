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
        local label = _G[token]
        if type(label) == "string" and label ~= "" then
            out[#out + 1] = { token = token, label = label, value = tonumber(value) or 0 }
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
        if type(k) == "string" and type(v) == "string" and v ~= ""
           and k:find("^ITEM_MOD_") and not v:find("%%") then
            local prev = _modIndex[v]
            -- Deux globales au MÊME libellé : garder la plus courte, pour une clé de filtre stable.
            if not prev or #k < #prev then _modIndex[v] = k end
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

-- Repli : les lignes du tooltip qui COMMENCENT par « +N ». Cette contrainte écarte d'elle-même les
-- lignes d'effet (« Équipé : … ») et la mention de châsse, qui est entre guillemets.
-- L'ordre du client est CONSERVÉ (pas de tri) : c'est lui qui met la stat principale en tête, et
-- l'en-tête doit se lire comme le tooltip que le joueur a sous les yeux.
local function fromTooltip(itemID)
    local tp = tip()
    tp:ClearLines()
    if not pcall(tp.SetHyperlink, tp, "item:" .. itemID) then return nil end
    local out = {}
    for i = 1, tp:NumLines() do
        local fs = _G[TIP_NAME .. "TextLeft" .. i]
        local txt = fs and fs:GetText()
        if txt and txt:find("^%s*%+%d") then splitBonusLine(txt, out) end
    end
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
    if not GetItemInfo(itemID) then return nil end
    local list = fromAPI(itemID)
    if not list or #list == 0 then list = fromTooltip(itemID) or list or {} end
    _cache[itemID] = list
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
