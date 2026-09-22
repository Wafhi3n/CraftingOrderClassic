-- CraftingOrderClassic_Enchant_Filter_Pilot.lua — pose et rend le filtre natif « Slots » (T2).
-- Spec : docs/specs/enchant-echange-forever.md. Pendant un échange, la liste native de l'Enchantement
-- suit la pièce que le partenaire a RÉELLEMENT posée dans l'emplacement 7 ; à la fin, elle retrouve
-- ses filtres d'avant. Les cases viennent de _Enchant_Filter.lua (T1).
--
-- Trois pièces, les deux premières sans aucun accès au jeu (testées hors jeu) :
--   · le PILOTE écrit le filtre et se souvient de l'état d'avant, case par case ;
--   · le SUIVEUR décide QUAND écrire : quand la pièce change, ou quand l'Enchantement réapparaît ;
--   · le branchement (Filter:Start) relie le suiveur aux événements du jeu.
--
-- Sens de l'API, lu dans Blizzard_Professions.lua (InitSlotsFilter, ApplyfilterSet) :
-- `IsInventorySlotFiltered(i)` vrai = case DÉCOCHÉE (recettes cachées) ; le 2ᵉ argument de
-- `SetInventorySlotFilter(i, coche)` = case COCHÉE. On écrit case par case, comme ApplyfilterSet, et
-- seulement les cases qui changent. « Have Materials » n'est jamais touché : les composants du
-- partenaire ne sont pas dans nos sacs, ce filtre cacherait précisément le bon enchant.
--
-- Le filtre est propre au métier affiché : on n'écrit QUE si l'Enchantement est affiché. Ailleurs
-- (fenêtre fermée, autre métier), on attend qu'il revienne.

local COC    = CraftingOrderClassic
local Filter = COC.EnchantFilter

-- ---------------------------------------------------------------- le pilote

local Pilot = {}
Pilot.__index = Pilot

-- `ts` = C_TradeSkillUI, ou un faux pour les tests.
function Filter.NewPilot(ts) return setmetatable({ ts = ts }, Pilot) end

-- État des cases : { n = nombre, [i] = vrai si la case est décochée }.
local function snapshot(ts)
    local s = { n = ts.GetAllFilterableInventorySlotsCount() or 0 }
    for i = 1, s.n do s[i] = ts.IsInventorySlotFiltered(i) == true end
    return s
end

-- COC tient-il un filtre (posé, et pas encore rendu) ?
function Pilot:Holding() return self.saved ~= nil end

-- Ne garde cochées QUE les cases `cases`. L'état d'avant n'est mémorisé qu'au PREMIER passage : une
-- pièce qui en remplace une autre ne doit pas faire oublier le filtre du joueur. Rend vrai si le
-- client tient exactement ce filtre à la relecture.
function Pilot:Apply(cases)
    if #cases == 0 then return self:Release() end
    local ts = self.ts
    local cur = snapshot(ts)
    if not self.saved or self.saved.n ~= cur.n then self.saved = cur end
    local keep = {}
    for _, i in ipairs(cases) do keep[i] = true end
    for i = 1, cur.n do
        if cur[i] == (keep[i] == true) then ts.SetInventorySlotFilter(i, keep[i] == true) end
    end
    self.applied = snapshot(ts)
    for i = 1, cur.n do
        if self.applied[i] == (keep[i] == true) then return false end
    end
    return true
end

-- Rend le filtre d'avant. Seulement les cases que COC tient encore : une case que le joueur a
-- changée lui-même depuis notre pose garde SON choix.
function Pilot:Release()
    local saved, applied = self.saved, self.applied
    self.saved, self.applied = nil, nil
    if not (saved and applied) then return true end
    local ts = self.ts
    local cur = snapshot(ts)
    if cur.n ~= saved.n then return false end
    for i = 1, cur.n do
        if cur[i] == applied[i] and cur[i] ~= saved[i] then ts.SetInventorySlotFilter(i, not saved[i]) end
    end
    return true
end

-- ---------------------------------------------------------------- le suiveur

local Follower = {}
Follower.__index = Follower

-- deps = { pilot =, shown = fn() → Enchantement affiché ?,
--          item = fn() → clé, equipLoc, subclassID de la pièce posée (nil si rien),
--          cases = fn() → cases lues sur le client (Filter.ReadCases),
--          trading = fn() → un échange est-il ouvert ? (facultatif) }
function Filter.NewFollower(deps) return setmetatable({ d = deps, dirty = true }, Follower) end

-- L'enchanteur a cliqué un emplacement de la silhouette : filtrer là-dessus tant qu'aucune pièce
-- n'est posée. Une pièce posée l'emporte toujours — le filtre suit ce qui est RÉELLEMENT sur la
-- table, pas ce qu'on a demandé (spec). nil = plus de demande.
function Follower:SetRequest(slot)
    if self.request == slot then return end
    self.request, self.dirty = slot, true
end

-- À appeler sur chaque événement utile. N'écrit que si quelque chose a VRAIMENT changé : la pièce, ou
-- le retour de l'Enchantement à l'écran. Jamais sur un simple rafraîchissement de la liste : ce serait
-- se battre avec le joueur qui décoche une case pendant l'échange (et nos propres écritures en
-- provoquent un). Rend l'action faite ("apply", "release"), ou nil, puis d'où vient le filtre —
-- la pièce posée ou l'emplacement demandé au clic. La trace le dit : les deux mènent souvent à la
-- MÊME case, et « c'est parti de mon clic » ou « ça suit sa pièce » ne se relisent plus autrement.
function Follower:Refresh()
    local d = self.d
    local shown = d.shown() and true or false
    if self.wasShown and not shown then self.dirty = true end   -- au retour, Blizzard a pu tout remettre
    self.wasShown = shown
    -- L'échange fermé emporte la demande : sans ça, le filtre resterait accroché à l'emplacement
    -- cliqué bien après le départ du partenaire.
    if d.trading and not d.trading() and self.request then self.request, self.dirty = nil, true end
    local key, equipLoc, subclassID = d.item()
    if key ~= self.key then self.key, self.dirty = key, true end
    if not (shown and self.dirty) then return nil end
    self.dirty = false
    local cases, from
    if key then cases, from = Filter.CasesForItem(d.cases(), equipLoc, subclassID), "pièce posée"
    elseif self.request then cases, from = Filter.CasesForSlot(d.cases(), self.request), "emplacement demandé" end
    if cases and #cases > 0 then return "apply", d.pilot:Apply(cases), cases, from end
    if not d.pilot:Holding() then return nil end
    return "release", d.pilot:Release()
end

-- ---------------------------------------------------------------- branchement

local function trace(msg) if COC.Trace then COC.Trace:Log("enchfilter", msg) end end

local function enchantingShown()
    local pf = _G.ProfessionsFrame
    return pf and pf:IsShown() and COC.Craft and COC.Craft:OpenProfessionKey() == "Enchanting"
end

-- Pièce posée par le PARTENAIRE dans l'emplacement « ne sera pas échangé ». Clé = son lien.
-- ⚠️ Pas de `GetItemInfoInstant and GetItemInfoInstant(link)` : `and` tronque le multi-retour.
local function tradeItem()
    if not (_G.TradeFrame and TradeFrame:IsShown() and GetTradeTargetItemLink) then return nil end
    local link = GetTradeTargetItemLink(_G.TRADE_ENCHANT_SLOT or 7)
    if not link then return nil end
    local equipLoc, subclassID
    if COC.Api.GetItemInfoInstant then
        local _, _, _, loc, _, _, sub = COC.Api.GetItemInfoInstant(link)
        equipLoc, subclassID = loc, sub
    end
    return link, equipLoc, subclassID
end

function Filter:Start()
    if not (C_TradeSkillUI and C_TradeSkillUI.SetInventorySlotFilter) then return end
    local follower = Filter.NewFollower({
        pilot = Filter.NewPilot(C_TradeSkillUI), shown = enchantingShown,
        item = tradeItem, cases = Filter.ReadCases,
        trading = function() return (_G.TradeFrame and TradeFrame:IsShown()) and true or false end,
    })
    Filter.follower = follower
    local pending
    local function refresh()
        pending = nil
        -- RIEN NE S'ÉCRIT EN COMBAT. Le filtre appartient à la fenêtre de métier, un cadre protégé,
        -- et l'écriture partirait de NOTRE pile : c'est la famille de bug prouvée le 2026-09-22 avec
        -- `OpenTradeSkill` (bloquée, imputée à COC, et le pcall n'attrape rien). Un échange n'est pas
        -- fermé par le combat, donc le cas arrive pour de vrai. L'intention reste marquée « à
        -- refaire » dans le suiveur : la sortie de combat la rejoue. Même discipline que la colonne.
        if InCombatLockdown and InCombatLockdown() then
            return trace("combat : écriture du filtre différée")
        end
        local ok, what, done, cases, from = pcall(follower.Refresh, follower)
        if not ok then return trace("erreur : " .. tostring(what)) end
        if what == "apply" then
            trace(string.format("filtre posé sur les cases %s — %s (%s)", table.concat(cases, ","),
                  tostring(from), done and "relu OK" or "relu DIFFÉRENT"))
        elseif what == "release" then
            trace("filtre rendu" .. (done and "" or " (métier différent : rien touché)"))
        end
    end
    Filter._refresh = refresh
    local f = CreateFrame("Frame")
    COC.Api.RegisterEventsSafe(f, { "TRADE_SHOW", "TRADE_CLOSED", "TRADE_TARGET_ITEM_CHANGED",
                                    "TRADE_SKILL_SHOW", "TRADE_SKILL_CLOSE", "TRADE_SKILL_LIST_UPDATE",
                                    "PLAYER_REGEN_ENABLED" })
    -- Coalescé : l'ouverture de la fenêtre enchaîne plusieurs événements, et la pièce n'est lisible
    -- qu'un instant après TRADE_TARGET_ITEM_CHANGED. La sortie de combat, elle, se rejoue TOUT DE
    -- SUITE : le filtre est resté figé pendant le combat, il doit rattraper la pièce réelle au plus tôt.
    f:SetScript("OnEvent", function(_, ev)
        if ev == "PLAYER_REGEN_ENABLED" then return refresh() end
        if pending then return end
        pending = true
        C_Timer.After(0.1, refresh)
    end)
end

-- Clic sur un emplacement de la silhouette (colonne en mode Échange, _ProfWindow_Trade) : le filtre
-- passe par le MÊME pilote que la pièce posée. Deux écrivains sur le filtre en feraient deux qui se
-- battent, et l'état d'avant l'échange serait perdu par l'un des deux.
function Filter.Request(slot)
    local fw = Filter.follower
    if not fw then return end
    fw:SetRequest(slot)
    if Filter._refresh then Filter._refresh() end
end
