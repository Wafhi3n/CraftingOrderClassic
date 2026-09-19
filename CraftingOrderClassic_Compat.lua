-- CraftingOrderClassic_Compat.lua — couche d'adaptation d'API entre les SAVEURS de client.
--
-- Pourquoi : depuis WoW: Forever (Camelot, interface 16001) l'écosystème vise un client dont
-- l'API est MAINLINE/Retail, pas Classic. Une quarantaine de globaux que COC appelait depuis
-- toujours n'y existent plus — ils ont migré dans des espaces de noms `C_*`.
--
-- Le parti pris : **un seul code pour toutes les saveurs**, pas de fork. La plupart des formes
-- modernes existent AUSSI sur l'Era ; on prend la moderne quand elle est là, l'ancienne sinon.
-- L'Era y gagne au passage (moins de globaux dépréciés).
--
-- Règle de ce fichier : ce qu'on expose garde TOUJOURS la signature historique, celle que le
-- reste de COC connaît déjà. Quand les deux backends divergent (tuple contre table), c'est ICI
-- que ça se normalise, en un seul endroit, pas dans 30 fichiers.
--
-- Chargé juste après CraftingOrderClassic.lua : tout le reste de COC peut compter sur COC.Api.
-- NB : la lib CraftLink charge AVANT COC et ne peut donc pas s'appuyer là-dessus — elle résout
-- ses propres appels chez elle.

local COC = CraftingOrderClassic
COC.Api = COC.Api or {}
local A = COC.Api

-- ---------------------------------------------------------------- renommages purs
-- Même signature des deux côtés : on prend simplement celui qui existe.

local function pick(modern, legacy) return modern or legacy end

A.GetItemInfo        = pick(C_Item and C_Item.GetItemInfo,         _G.GetItemInfo)
A.GetItemInfoInstant = pick(C_Item and C_Item.GetItemInfoInstant,  _G.GetItemInfoInstant)
A.GetItemCount       = pick(C_Item and C_Item.GetItemCount,        _G.GetItemCount)
A.GetItemIcon        = pick(C_Item and C_Item.GetItemIconByID,     _G.GetItemIcon)
A.IsAddOnLoaded      = pick(C_AddOns and C_AddOns.IsAddOnLoaded,   _G.IsAddOnLoaded)
A.GuildRoster        = pick(C_GuildInfo and C_GuildInfo.GuildRoster, _G.GuildRoster)
A.InviteUnit         = pick(C_PartyInfo and C_PartyInfo.InviteUnit, _G.InviteUnit)
A.GetSpellLink       = pick(C_Spell and C_Spell.GetSpellLink,      _G.GetSpellLink)
A.GetSpellTexture    = pick(C_Spell and C_Spell.GetSpellTexture,   _G.GetSpellTexture)

-- ---------------------------------------------------------------- signatures divergentes

-- `GetSpellInfo` rend un TUPLE en Classic et une TABLE en Retail. Partout dans COC on ne se sert
-- que du NOM du sort → on n'expose que ça, et ça rend une chaîne des deux côtés.
function A.GetSpellName(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(spellID) end
    if _G.GetSpellInfo then return (_G.GetSpellInfo(spellID)) end
    return nil
end

-- `BNGetFriendInfo` (tuple de 8) devient `C_BattleNet.GetFriendAccountInfo` (table imbriquée).
-- On ne rend que ce que COC utilise vraiment : nom du perso, client, en ligne.
function A.GetBNetFriend(index)
    if _G.BNGetFriendInfo then
        local _, _, _, _, characterName, _, client, isOnline = _G.BNGetFriendInfo(index)
        return characterName, client, isOnline
    end
    local get = C_BattleNet and C_BattleNet.GetFriendAccountInfo
    local acc = get and get(index)
    local game = acc and acc.gameAccountInfo
    if not game then return nil end
    return game.characterName, game.clientProgram, game.isOnline
end

-- ---------------------------------------------------------------- argent

-- `GetCoinTextureString` était une GLOBALE partout... sauf sur Forever, où elle a migré dans
-- `C_CurrencyInfo` — même signature (montant, hauteur de police). COC l'appelait à 31 endroits :
-- tout l'affichage d'argent de l'addon (rentabilité, coût/point, plan de route, bourse, cartes de
-- commande, suivi…). Les appels gardés (`GetCoinTextureString and …`) rendaient le montant en
-- cuivre BRUT, les autres levaient — vu en jeu le 2026-09-19 en ouvrant le Plan de route.
-- Repli ultime volontairement NUMÉRIQUE plutôt que vide : un montant illisible vaut mieux qu'une
-- ligne muette qui laisserait croire à un prix inconnu.
function A.Coin(copper, fontHeight)
    local n = tonumber(copper) or 0
    local f = _G.GetCoinTextureString
        or (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString)
    if f then
        local ok, txt = pcall(f, n, fontHeight)
        if ok and txt then return txt end
    end
    return tostring(math.floor(n + 0.5))
end

-- ---------------------------------------------------------------- journal de quêtes

function A.GetNumQuestLogEntries()
    if _G.GetNumQuestLogEntries then return (_G.GetNumQuestLogEntries()) end
    local f = C_QuestLog and C_QuestLog.GetNumQuestLogEntries
    return (f and f()) or 0
end

-- Rend le tuple Classic. Seule perte côté Retail : `rawTag`, qui n'a pas d'équivalent — les
-- appelants le traitent déjà comme facultatif (l'étiquette devient simplement absente).
function A.GetQuestLogTitle(index)
    if _G.GetQuestLogTitle then return _G.GetQuestLogTitle(index) end
    local f = C_QuestLog and C_QuestLog.GetInfo
    local q = f and f(index)
    if not q then return nil end
    local complete = q.isComplete
    if complete == nil and q.questID and C_QuestLog.IsComplete then
        complete = C_QuestLog.IsComplete(q.questID) or nil
    end
    return q.title, q.level, nil, q.isHeader, q.isCollapsed, complete and 1 or nil, q.frequency
end

-- ATTENTION : la sélection du journal se fait par INDEX en Classic et par questID en Retail.
-- Un index passé tel quel à l'API Retail viserait la mauvaise quête. D'où ce couple : le jeton
-- rendu par GetQuestSelection est OPAQUE et ne se relit que via RestoreQuestSelection.
function A.GetQuestSelection()
    if _G.GetQuestLogSelection then return _G.GetQuestLogSelection() end
    local f = C_QuestLog and C_QuestLog.GetSelectedQuest
    return f and f() or nil
end

function A.RestoreQuestSelection(token)
    if not token or token == 0 then return end
    if _G.SelectQuestLogEntry then return _G.SelectQuestLogEntry(token) end
    local f = C_QuestLog and C_QuestLog.SetSelectedQuest
    if f then return f(token) end
end

-- Sélectionne par index de journal, des deux côtés.
function A.SelectQuestLogEntry(index)
    if _G.SelectQuestLogEntry then return _G.SelectQuestLogEntry(index) end
    local info = C_QuestLog and C_QuestLog.GetInfo and C_QuestLog.GetInfo(index)
    local f = C_QuestLog and C_QuestLog.SetSelectedQuest
    if info and info.questID and f then return f(info.questID) end
end

-- ---------------------------------------------------------------- événements

-- `RegisterEvent` LÈVE une erreur sur un événement que le client ne connaît pas, au lieu de
-- l'ignorer. Les événements de métier Classic (TRADE_SKILL_*, CRAFT_*) n'existent pas sur
-- Forever : une seule ligne non gardée fait tomber tout le chargement du module.
-- Vécu le 2026-09-18 à l'apprentissage du Minage : « Attempt to register unknown event
-- TRADE_SKILL_UPDATE ». On enregistre donc en pcall, et on RAPPORTE ce qui n'a pas pris — un
-- événement absent n'est pas une erreur, mais le taire rendrait la fonctionnalité muette
-- sans explication.
function A.RegisterEventSafe(frame, event)
    if not (frame and event) then return false end
    return (pcall(frame.RegisterEvent, frame, event)) and true or false
end

-- Même piège pour les SCRIPTS : `HookScript` lève sur un type de script que le widget ne connaît
-- pas. `OnTooltipSetUnit` est vivant en Classic Era mais mort sur Retail/Forever (refonte tooltip
-- → TooltipDataProcessor). Un hook raté ne doit pas emporter la suite de l'initialisation :
-- vécu le 2026-09-18, une seule ligne a tué menus + roster + découverte du module Social.
function A.HookScriptSafe(frame, script, handler)
    if not (frame and frame.HookScript and script and handler) then return false end
    return (pcall(frame.HookScript, frame, script, handler)) and true or false
end

-- Enregistre une liste, rend celle des événements REFUSÉS par le client.
function A.RegisterEventsSafe(frame, events)
    local skipped = {}
    for _, ev in ipairs(events or {}) do
        if not A.RegisterEventSafe(frame, ev) then skipped[#skipped + 1] = ev end
    end
    return skipped
end

-- ---------------------------------------------------------------- gabarits XML

-- Le gabarit d'onglet natif n'a pas le même nom partout : `TabButtonTemplate` en Classic Era
-- (Blizzard_SharedXML\Classic\SharedUIPanelTemplates.xml), `PanelTabButtonTemplate` sur
-- Retail/Forever (…\Mainline\). Les deux se pilotent à l'IDENTIQUE — `SetText` (chacun a son
-- ButtonText) et les helpers `PanelTemplates_TabResize` / `SelectTab` / `DeselectTab`, présents
-- des deux côtés. Seul le nom change.
--
-- `CreateFrame` LÈVE sur un gabarit inconnu (« Couldn't find inherited node », vécu le 2026-09-18
-- sur Forever) : on INTERROGE donc le client via C_XMLUtil plutôt que de tenter puis rattraper.
local function resolveTemplate(names, fallback)
    if C_XMLUtil and C_XMLUtil.GetTemplateInfo then
        for _, name in ipairs(names) do
            if C_XMLUtil.GetTemplateInfo(name) then return name end
        end
    end
    return fallback
end
-- Le FontString du titre d'un PortraitFrameTemplate ne vit pas au même endroit selon la saveur :
-- `frame.TitleText` en Classic Era, `frame.TitleContainer.TitleText` sur Retail/Forever.
-- Pour ÉCRIRE le titre, préférer TOUJOURS `frame:SetTitle(texte)` : la méthode du mixin existe des
-- deux côtés et vise le bon FontString. Ce résolveur ne sert qu'aux rares cas où on a besoin du
-- FontString lui-même (mesure, ré-ancrage).
function A.TitleFontString(frame)
    if not frame then return nil end
    return frame.TitleText
        or (frame.TitleContainer and frame.TitleContainer.TitleText)
        or nil
end

-- Le médaillon d'un PortraitFrameTemplate : `frame.portrait` en Classic Era,
-- `frame.PortraitContainer.portrait` sur Retail/Forever. Rend aussi si le gabarit applique DÉJÀ
-- son masque circulaire (c'est le cas sur Retail) — en reposer un l'écraserait.
-- Sans ce résolveur, la garde `if not f.portrait` sortait EN SILENCE : médaillon vide sur Forever,
-- aucune erreur, personne n'en sait rien. C'est la signature du piège de ce portage.
function A.PortraitTexture(frame)
    if not frame then return nil end
    if frame.portrait then return frame.portrait, false end
    local c = frame.PortraitContainer
    if c and c.portrait then return c.portrait, true end
    return nil
end

A.ResolveTemplate = resolveTemplate
A.TabTemplate = resolveTemplate({ "TabButtonTemplate", "PanelTabButtonTemplate" }, "TabButtonTemplate")

-- ---------------------------------------------------------------- saveur courante

-- `WOW_PROJECT_ID == 1` (MAINLINE) sur Forever, valeurs Classic ailleurs. Sert à borner les
-- comportements qui ne peuvent PAS être normalisés (ex. métiers), pas à dupliquer du code.
A.IS_MAINLINE = (_G.WOW_PROJECT_ID ~= nil and _G.WOW_PROJECT_MAINLINE ~= nil
    and _G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE) or false

-- Les comms addon peuvent être bridées (instances sur Retail). Mesuré en jeu le 2026-09-18 :
-- le prédicat rend `true` en monde ouvert sans pour autant bloquer — un envoi réel passe. On ne
-- s'en sert donc PAS pour se censurer, seulement pour diagnostiquer.
function A.ChatMessagingBlocked()
    local f = C_ChatInfo and C_ChatInfo.InChatMessagingLockdown
    return (f and f()) or false
end

-- ---------------------------------------------------------------- métiers

-- Fermer la session de métier ouverte. Trois API selon la saveur : `CloseCraft` (Craft, Era),
-- `CloseTradeSkill` (TradeSkill, Era) et `C_TradeSkillUI.CloseTradeSkill` (MAINLINE, la seule qui
-- reste sur Forever). Les appelants Era écrivaient la disjonction à la main derrière une garde
-- `if CloseCraft then` — garde qui, sur Forever, sort EN SILENCE : la fenêtre n'était jamais
-- fermée et la vue qui attendait cette fermeture ne s'ouvrait pas.
function A.CloseProfession()
    local craft = COC.Craft
    if craft and craft.IsCraftOpen and craft:IsCraftOpen() and _G.CloseCraft then return _G.CloseCraft() end
    if _G.CloseTradeSkill then return _G.CloseTradeSkill() end
    local f = C_TradeSkillUI and C_TradeSkillUI.CloseTradeSkill
    if f then return (pcall(f)) end
end
