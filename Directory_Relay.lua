-- Directory_Relay.lua — « contacts de confiance » : les données d'un joueur DÉCONNECTÉ restent
-- servies par ses partenaires (r.isPartner). Émission = riposte de découverte (OnHello/OnPing
-- whisper → RelayPartnersTo) ; réception = OnRelay → stockage EXCLUSIF dans roster[origin].relayed
-- (estimation, JAMAIS autoritaire : pas d'écriture dans skill/recipes/cooldowns/lastSeen/online,
-- pas de routage d'ordre — display-only). Le direct écrase toujours : Dir:_Touch fait relayed=nil.
-- L'origin d'un RLY est falsifiable → c'est POURQUOI ce grade existe (cf. plan, décision user).
-- Codec pur dans Directory_RelayCodec.lua ; méthodes sur COC.Directory (chargé avant, .toc).

local COC = CraftingOrderClassic
local Dir = COC.Directory
local Codec = COC.RelayCodec

local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)

local function now() return (GetTime and GetTime()) or 0 end   -- uptime : throttles/rate-caps

local RELAY_MAX_ORIGINS     = 5             -- partenaires max relayés par riposte
local RELAY_THROTTLE        = 120           -- s entre deux relais du même origin vers la même cible
local RELAY_MAX_AGE         = 30 * 86400    -- au-delà : fiche trop vieille, rejetée
local RELAY_KEEP            = 7 * 86400     -- rétention d'un r.relayed sans rafraîchissement
local RATE_WINDOW, RATE_MAX = 300, 150      -- réception : 150 msgs RLY max / 5 min / émetteur (60 avant
                                            -- le registre par palier : un artisan relayé tient en ~20 messages)

-- ------------------------------------------------------------------
-- Émission (riposte de découverte)
-- ------------------------------------------------------------------
-- Sers à `target` les fiches de MES partenaires HORS LIGNE (whisper dirigé uniquement).
-- Source = champs DIRECTS du roster, jamais r.relayed → « pas de relais de relais » garanti
-- structurellement. Cap aux RELAY_MAX_ORIGINS plus récemment vus + throttle par (cible, origin).
function Dir:RelayPartnersTo(target)
    if not (CraftLink and Codec and target) then return end
    local cands = {}
    for name, r in pairs(self.roster or {}) do
        -- SamePlayer : ne pas servir à `target` la fiche d'un de SES rerolls vérifiés (verbe ALT) —
        -- il détient déjà ses propres données en local (SV par compte), ce serait un miroir inutile.
        if r.isPartner and not self.online[name] and name ~= target
            and not (self.SamePlayer and self:SamePlayer(name, target))
            and (r.skill or r.recipes or r.cooldowns) then
            cands[#cands + 1] = { name = name, r = r, t = r.lastSeen or 0 }
        end
    end
    if #cands == 0 then return end
    table.sort(cands, function(a, b) return a.t > b.t end)
    self._lastRelay = self._lastRelay or {}
    local t, sent = now(), 0
    for i = 1, #cands do
        if sent >= RELAY_MAX_ORIGINS then break end
        local key = target .. "|" .. cands[i].name
        if (self._lastRelay[key] or 0) + RELAY_THROTTLE <= t then
            self._lastRelay[key] = t
            self:_SendRelay(target, cands[i].name, cands[i].r)
            sent = sent + 1
        end
    end
end

-- Enveloppe et envoie la fiche d'UN partenaire : SK d'abord (vérité terrain, comme AnnounceTo),
-- puis RK et CD par métier. Le CD est recalculé depuis les readyAt stockés (restant courant).
function Dir:_SendRelay(target, name, r)
    local ts = time()
    local age = math.max(0, ts - (r.lastSeen or ts))
    local function send(inner)
        local msg = inner and Codec.Wrap(name, age, inner)
        if msg then CraftLink:Send(msg, "whisper", target) end
    end
    send(Codec.BuildSK(r))
    for prof, hex in pairs(r.recipes or {}) do send(Codec.BuildRK(prof, hex, r.recipeDV)) end
    -- Registre par identifiants (Camelot) : redécoupé par palier sous 255 octets ENVELOPPE COMPRISE —
    -- un message plus long arrive coupé, en silence (mesuré le 2026-10-05). Les paliers sont relus
    -- dans NOS données : le récepteur n'a besoin que d'un découpage cohérent au sein du lot.
    local cap = 250 - #("RLY|" .. name .. "|" .. age .. "|")
    for prof, pay in pairs(r.recipeIDs or {}) do
        local msgs = CraftLink.BuildRIMessages and CraftLink:BuildRIMessages(prof, CraftLink:DecodeKnownIDs(pay), cap)
        for _, m in ipairs(msgs or { Codec.BuildRI(prof, pay) }) do send(m) end
    end
    for prof, cds in pairs(r.cooldowns or {}) do send(Codec.BuildCD(prof, cds, ts)) end
end

-- ------------------------------------------------------------------
-- Réception
-- ------------------------------------------------------------------
-- Fenêtre glissante par émetteur : un client hostile ne peut pas nous inonder de fiches.
function Dir:_RelayRateOk(sender)
    local t = now()
    self._relayRate = self._relayRate or {}
    local e = self._relayRate[sender]
    if not e or t - e.t0 > RATE_WINDOW then e = { t0 = t, n = 0 }; self._relayRate[sender] = e end
    e.n = e.n + 1
    return e.n <= RATE_MAX
end

-- RLY reçu. Rejets silencieux : hors whisper, malformé, trop vieux, origin absurde (moi-même ou
-- l'émetteur — un joueur EN LIGNE parle pour lui-même), verbe interne inconnu, rate-cap dépassé.
-- « Moi-même » = TOUT perso de MON compte (IsMyChar) : la SV roster est PAR COMPTE, donc un relais
-- reçu sur un reroll (légitime vu du partenaire, qui ignore le lien) referait surface en rejouant
-- ce perso — on se verrait « soi-même via X » dans l'annuaire.
-- On ne garde que le lot le plus FRAIS (ts = time() - age) ; un lot plus frais remplace tout.
function Dir:OnRelay(sender, message, distribution)
    if distribution ~= "WHISPER" or not sender then return end
    if not self:_RelayRateOk(sender) then return end
    local f = Codec and Codec.Parse(message)
    if not f or f.age > RELAY_MAX_AGE then return end
    if f.verb ~= "SK" and f.verb ~= "RK" and f.verb ~= "RI" and f.verb ~= "CD" then return end
    local me = COC.Api.PlayerName()
    if f.origin == me or f.origin == sender then return end
    if COC.IsMyChar and COC:IsMyChar(f.origin) then return end
    local ts = time() - f.age
    self.roster = self.roster or {}
    local r = self.roster[f.origin]
    if not r then r = {}; self.roster[f.origin] = r end   -- SANS lastSeen/online : pas de fausse présence
    -- Camp : le relayeur m'a chuchoté, il est donc de MON camp, et son partenaire aussi. Sans ce tampon,
    -- la fiche passait le filtre de camp de TOUS les persos du compte — relevé le 2026-09-28 : Syrine
    -- (Alliance, relayée par Rédemption) visible sur Orcaa (Horde), la SV étant partagée par compte.
    if not r.faction and self._MyFaction then r.faction = self:_MyFaction() end
    local rel = r.relayed
    if rel and (rel.ts or 0) > ts then return end          -- on détient déjà plus frais
    if not rel or rel.via ~= sender or ts > (rel.ts or 0) + 60 then
        rel = { via = sender, ts = ts }; r.relayed = rel   -- nouveau lot → table neuve (pas de mélange)
    end
    if f.verb == "SK" then self:_StoreRelayedSK(rel, f.inner)
    elseif f.verb == "RK" then self:_StoreRelayedRK(rel, f.inner)
    elseif f.verb == "RI" then self:_StoreRelayedRI(rel, f.inner, sender .. ">" .. f.origin)
    else self:_StoreRelayedCD(rel, f.inner) end
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
end

function Dir:_StoreRelayedSK(rel, inner)
    local skills, lvl, rep = self:_ParseSKBody(inner)   -- extrait de OnSkill (Directory_Skills.lua)
    if not skills or not next(skills) then return end
    rel.skill = skills
    if lvl then rel.level = lvl end
    if rep then rel.rep = rep end
end

function Dir:_StoreRelayedRK(rel, inner)
    if not CraftLink then return end
    local prof, hex, dv = CraftLink:ParseRK(inner)
    if not prof then return end
    rel.recipes = rel.recipes or {}
    rel.recipes[prof] = hex
    rel.recipeDV = dv
end

-- Pendant identifiants de _StoreRelayedRK. ParseRI revalide la forme du message : un relayeur
-- véreux ne peut pas injecter plus de junk qu'un émetteur direct. Par palier comme en direct
-- (Dir:_ApplyRI) ; `key` (relayeur > origine) sépare l'assemblage des morceaux de chaque source.
function Dir:_StoreRelayedRI(rel, inner, key)
    local c = CraftLink
    if not (c and c.ParseRI) then return end
    local prof, payload, tier, k, n, mask = c:ParseRI(inner)
    if not prof then return end
    self:_ApplyRI(rel, "relais\0" .. tostring(key), prof, payload, tier, k, n, mask)
end

-- ParseCD (lib) revalide tout (métier catalogué à CD, spellID, bornes) : un relayeur véreux ne
-- peut pas injecter plus de junk qu'un émetteur direct. Même garde de vraisemblance qu'OnCD, jugée
-- sur le SK du même lot (relayé avant le CD, cf. _SendRelay).
function Dir:_StoreRelayedCD(rel, inner)
    if not (CraftLink and CraftLink.ParseCD) then return end
    local prof, list = CraftLink:ParseCD(inner)
    if not prof then return end
    local ts = time()
    local set = {}
    for _, e in ipairs(list) do
        if not self.CooldownPlausible or self:CooldownPlausible(rel.skill, prof, e.sid) then
            set[e.sid] = ts + e.remain
        end
    end
    rel.cooldowns = rel.cooldowns or {}
    rel.cooldowns[prof] = next(set) and set or nil
end

-- ------------------------------------------------------------------
-- Entretien + câblage
-- ------------------------------------------------------------------
-- Un relais jamais rafraîchi depuis 7 j est périmé (appelé par PruneRoster au démarrage).
-- Purge aussi les relais portant sur un perso de MON compte (garde OnRelay ajoutée après coup :
-- guérit les fiches déjà persistées) ; une entrée créée par PUR relais et vidée ici n'a plus rien
-- à montrer → on la retire, sinon elle traînerait en ligne fantôme jusqu'au TTL de PruneRoster.
function Dir:PruneRelays()
    local cutoff = time() - RELAY_KEEP
    for name, r in pairs(self.roster or {}) do
        if r.relayed and ((r.relayed.ts or 0) < cutoff
                or (COC.IsMyChar and COC:IsMyChar(name))) then
            r.relayed = nil
            if not (r.lastSeen or r.skill or r.recipes or r.manual or r.isPartner) then
                self.roster[name] = nil
            end
        end
    end
end

function Dir:StartRelay()
    if not (CraftLink and Codec) then return end
    CraftLink:RegisterHandler("RLY", function(s, m, d) Dir:OnRelay(s, m, d) end)
end
