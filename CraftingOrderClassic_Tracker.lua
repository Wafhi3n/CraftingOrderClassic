-- CraftingOrderClassic_Tracker.lua — SUIVI À L'ÉCRAN des commandes, façon suivi de quête : un cadre
-- léger, déplaçable, hors de toute fenêtre, qui liste ce sur quoi le joueur peut agir MAINTENANT.
-- Il ne décide de rien : le modèle et l'ordre de priorité vivent dans COC.Journal, les lignes dans
-- _Tracker_Rows.lua. À terme, le même modèle alimentera le journal COC en parchemin.
--
-- Deux invariants, chacun payé ailleurs dans cette codebase :
--   · AUCUN bouton sécurisé ici. Un SecureActionButton interdirait de masquer le cadre — et tous ses
--     ancêtres — en combat (wow-protected-frame-hide-combat). Le suivi NAVIGUE, il ne crafte pas.
--   · Le rafraîchissement n'est PAS gaté sur la fenêtre principale. UI:RefreshSoon l'est, et c'est
--     exactement ce qui empêchait la bourse d'artisan de se repeindre : on post-hooke APRÈS la garde.

local COC = CraftingOrderClassic
COC.Tracker = COC.Tracker or {}
local Tracker = COC.Tracker
local L = COC.L

local TICK       = 30    -- filet de sécurité : expiration TTL, dérive d'horloge. Les vraies mises à
                         -- jour arrivent par événement (sacs) et par post-hook (cycle des commandes).
local MAX_ENTRIES = 8    -- entrées affichées au maximum ; au-delà, une ligne « +N de plus »
local DEFAULT_POS = { "TOPRIGHT", "TOPRIGHT", -220, -330 }   -- sous la minimap, déplaçable

local function pmsg(m) print("|cFF33DD88Crafting Order|r " .. m) end

-- Config persistée, défauts posés paresseusement (comme le reste de la DB).
function Tracker:Cfg()
    if not COC.db then return nil end
    local c = COC.db.tracker
    if not c then c = {}; COC.db.tracker = c end
    if c.on == nil then c.on = true end
    c.collapsed = c.collapsed or {}
    c.pos = c.pos or { DEFAULT_POS[1], DEFAULT_POS[2], DEFAULT_POS[3], DEFAULT_POS[4] }
    return c
end

-- ------------------------------------------------------------------
-- Cadre
-- ------------------------------------------------------------------
-- Cadre NU : ni fond ni bordure (le suivi natif n'en a pas non plus), et surtout EnableMouse(false)
-- — la souris n'est active que sur les lignes elles-mêmes, sinon on masquerait le monde derrière.
function Tracker:Frame()
    if self.frame then return self.frame end
    local c = self:Cfg()
    local f = CreateFrame("Frame", "CraftingOrderTracker", UIParent)
    f:SetSize(200, 20)
    local p = (c and c.pos) or DEFAULT_POS
    f:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(false)
    f:SetFrameStrata("LOW")   -- un HUD passe DERRIÈRE les fenêtres, il ne leur dispute pas le dessus
    f:Hide()
    self.frame = f
    return f
end

function Tracker:BeginDrag()
    local f = self:Frame()
    f:StartMoving()
end

function Tracker:EndDrag()
    local f = self:Frame()
    f:StopMovingOrSizing()
    local c = self:Cfg()
    if not c then return end
    local pt, _, rp, x, y = f:GetPoint()
    c.pos = { pt, rp, x, y }
end

-- ------------------------------------------------------------------
-- Interactions
-- ------------------------------------------------------------------
function Tracker:ToggleSection(section)
    local c = self:Cfg()
    if not (c and section) then return end
    c.collapsed[section] = (not c.collapsed[section]) or nil
    self:Refresh()
end

-- Clic sur une entrée. Gauche = ouvrir la vue du métier concerné (PW:OpenFor lance le sort de métier
-- depuis le clic = événement matériel valable) ; droite = ouvrir le Carnet. Aucun craft d'ici.
function Tracker:OnEntryClick(e, button)
    if button == "RightButton" then
        if COC.UI and COC.UI.Toggle then COC.UI:Toggle("orders") end
        return
    end
    -- Le clic est la seule demande de description qu'on émette : un chuchotement par commande titrée
    -- et par client, à la réception, serait une rafale vers l'auteur. Ici c'est le joueur qui demande.
    local O = COC.Orders
    if e and e.order and O and O.RequestText then O:RequestText(e.order.id) end
    local PW = COC.ProfWindow
    if e and e.prof and PW and PW.OpenFor then return PW:OpenFor(e.prof) end
    if COC.UI and COC.UI.Toggle then COC.UI:Toggle("orders") end
end

-- ------------------------------------------------------------------
-- Rafraîchissement
-- ------------------------------------------------------------------
-- Visible seulement s'il y a quelque chose à suivre (comportement du suivi natif : zéro ligne = le
-- cadre disparaît), et jamais en combat si l'option est posée.
function Tracker:Refresh()
    local c = self:Cfg()
    if not (c and COC.Journal) then return end
    if not c.on then if self.frame then self.frame:Hide() end; return end
    if c.hideInCombat and InCombatLockdown and InCombatLockdown() then
        if self.frame then self.frame:Hide() end
        return
    end
    self:Frame()
    local groups, overflow = COC.Journal:Grouped(c.maxEntries or MAX_ENTRIES)
    local lines = self:Paint(groups, overflow)
    self.frame:SetShown(lines > 0)
end

-- Débouncé : les salves réseau (fanout NEW) et les BAG_UPDATE_DELAYED arrivent groupés.
function Tracker:RefreshSoon()
    if not (C_Timer and C_Timer.After) then return self:Refresh() end
    if self._pending then return end
    self._pending = true
    C_Timer.After(0.2, function()
        Tracker._pending = nil
        Tracker:Refresh()
    end)
end

-- ------------------------------------------------------------------
-- Commandes
-- ------------------------------------------------------------------
function Tracker:Toggle()
    local c = self:Cfg()
    if not c then return end
    c.on = not c.on
    pmsg(c.on and L["suivi des commandes affiché."] or L["suivi des commandes masqué."])
    self:Refresh()
end

-- `/co track` — bascule ; `on`/`off` explicites ; `reset` remet la position par défaut. Un cadre
-- déplaçable SANS effaceur est irrécupérable dès qu'on l'a traîné hors de l'écran.
function Tracker:Cmd(rest)
    local arg = (rest or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local c = self:Cfg()
    if not c then return end
    local word, num = arg:match("^(%a+)%s+(%d+)$")
    if word == "lines" or word == "lignes" then
        c.maxEntries = math.max(1, math.min(20, tonumber(num) or MAX_ENTRIES))
        pmsg(string.format(L["suivi : %d entrées au maximum."], c.maxEntries))
    elseif arg == "on" or arg == "off" then
        c.on = (arg == "on")
        pmsg(c.on and L["suivi des commandes affiché."] or L["suivi des commandes masqué."])
    elseif arg == "reset" then
        c.pos = { DEFAULT_POS[1], DEFAULT_POS[2], DEFAULT_POS[3], DEFAULT_POS[4] }
        c.collapsed = {}
        if self.frame then
            self.frame:ClearAllPoints()
            self.frame:SetPoint(c.pos[1], UIParent, c.pos[2], c.pos[3], c.pos[4])
        end
        pmsg(L["position du suivi réinitialisée."])
    elseif arg == "combat" then
        c.hideInCombat = not c.hideInCombat
        pmsg(c.hideInCombat and L["suivi masqué en combat."] or L["suivi visible en combat."])
    else
        return self:Toggle()
    end
    self:Refresh()
end

-- ------------------------------------------------------------------
-- Branchements
-- ------------------------------------------------------------------
-- Post-hook des mutations LOCALES du cycle de commande. Le chemin RÉSEAU passe déjà par
-- UI:RefreshSoon (hooké plus bas), mais un accept/livre déclenché ici même (bouton de la vue métier,
-- /co accept) ne le traverse pas. Aucune de ces méthodes ne rend plus d'UNE valeur.
local HOOKED = { "Accept", "Deliver", "Confirm", "Cancel", "Decline", "Post", "PostEntry" }
local function hookOrders()
    local O = COC.Orders
    if not O then return end
    for _, name in ipairs(HOOKED) do
        local orig = O[name]
        if type(orig) == "function" then
            O[name] = function(...)
                local ret = orig(...)
                Tracker:RefreshSoon()
                return ret
            end
        end
    end
end

-- UI:RefreshSoon est gaté sur la fenêtre principale ; on se branche APRÈS la garde pour que le suivi
-- se repeigne même fenêtre fermée — c'est tout l'intérêt d'un HUD.
local function hookUI()
    local UI = COC.UI
    if not (UI and UI.RefreshSoon) then return end
    local orig = UI.RefreshSoon
    UI.RefreshSoon = function(self, ...)
        orig(self, ...)
        Tracker:RefreshSoon()
    end
end

function Tracker:Start()
    if self._started then return end
    self._started = true
    hookOrders(); hookUI()
    local ev = CreateFrame("Frame")
    ev:RegisterEvent("BAG_UPDATE_DELAYED")      -- jamais BAG_UPDATE : il arrive par dizaines
    ev:RegisterEvent("PLAYER_REGEN_DISABLED")
    ev:RegisterEvent("PLAYER_REGEN_ENABLED")
    ev:SetScript("OnEvent", function() Tracker:RefreshSoon() end)
    self.events = ev
    if C_Timer and C_Timer.NewTicker then
        self.ticker = C_Timer.NewTicker(TICK, function() Tracker:Refresh() end)
    end
    self:Refresh()
end
