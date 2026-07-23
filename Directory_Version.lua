-- Directory_Version.lua — détection « nouvelle version disponible » (100 % P2P, aucun serveur).
--
-- Ma version est estampée dans le fil SK (pseudo-chunk `cv=`, cf. Directory_Skills._SkillPayload) et
-- voyage donc avec chaque annonce de métiers. À la réception d'un SK DIRECT (JAMAIS un relais — cf.
-- OnSkill vs Directory_Relay : anti-leurre), on note la version de l'émetteur. Dès qu'une version
-- STRICTEMENT supérieure à la mienne est corroborée par ≥ CONFIRM joueurs DISTINCTS, on prévient UNE
-- fois (chat) et on allume une pastille sur le bouton minimap jusqu'à la mise à jour. Un pair isolé
-- qui annonce « 9.9.9 » ne déclenche donc rien (seuil de corroboration = même posture anti-usurpation
-- que le reste de l'annuaire). Méthodes posées sur COC.Directory (créée par Directory.lua, chargé avant).

local COC = CraftingOrderClassic
local Dir = COC.Directory

local CONFIRM = 2   -- nb de joueurs DISTINCTS annonçant la version supérieure avant d'alerter (anti-leurre)
-- Une alerte PERSISTÉE (SV) qui n'est jamais re-corroborée pendant ce délai s'oublie toute seule : une
-- vraie version se re-confirme en continu au fil des SK ; un numéro fantaisiste (test d'injection, deux
-- farceurs de mèche) ne reviendra jamais — sans ce TTL, la pastille resterait allumée à VIE.
local ALERT_TTL = 7 * 86400

local function p(msg) print("|cFF33DD88Crafting Order|r " .. msg) end

COC.Version = COC.Version or {}
local V = COC.Version

-- "1.26.0" / "1.26.0-beta" / "v1.26" → { 1, 26, 0 }. Ignore un suffixe de pré-release (-beta, +build) :
-- pour « une version plus récente existe » seul le cœur numérique compte. nil si aucun chiffre.
function V.Parse(s)
    if type(s) ~= "string" then return nil end
    s = (s:match("^%s*v?(.-)%s*$")) or s
    s = s:gsub("[-+].*$", "")
    local out = {}
    for n in s:gmatch("(%d+)") do out[#out + 1] = tonumber(n) end
    return out[1] and out or nil
end

-- a > b ? compare composant par composant (longueurs inégales → 0 en butée).
function V.Greater(a, b)
    if not a then return false end
    if not b then return true end
    for i = 1, math.max(#a, #b) do
        local x, y = a[i] or 0, b[i] or 0
        if x ~= y then return x > y end
    end
    return false
end

-- Vecteur → clé/affichage canonique 3 champs "a.b.c" : deux annonces « 1.27 » et « 1.27.0 » comptent
-- pour LA MÊME version (sinon la corroboration par joueurs distincts serait cassée par la mise en forme).
function V.Canon(t) return string.format("%d.%d.%d", t[1] or 0, t[2] or 0, t[3] or 0) end

-- Ma version (métadonnée du .toc), calculée une fois. Positionne aussi self._myVerStr (canonique).
function Dir:_MyVersion()
    if not self._myVer then
        local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
        local s = meta and meta("CraftingOrderClassic", "Version") or nil
        self._myVer = V.Parse(s) or { 0 }
        self._myVerStr = V.Canon(self._myVer)
    end
    return self._myVer
end

-- SK reçu d'un pair DIRECT → note sa version (verStr = pseudo-chunk `cv=`). N'est appelée QUE depuis
-- OnSkill (données de 1re main) : un relais (Directory_Relay) ne compte jamais → une version relayée
-- de 3e main ne peut pas déclencher d'alerte. Corrobore par joueurs distincts avant d'agir.
function Dir:NotePeerVersion(sender, verStr)
    if not (sender and verStr) then return end
    local pv = V.Parse(verStr); if not pv then return end
    if not V.Greater(pv, self:_MyVersion()) then return end   -- pas plus récent que moi → rien à faire
    local key = V.Canon(pv)
    self._verSeen = self._verSeen or {}
    local slot = self._verSeen[key]
    if not slot then slot = { n = 0, who = {} }; self._verSeen[key] = slot end
    local who = (sender:match("^[^-]+")) or sender             -- sans royaume : compte des joueurs distincts
    if not slot.who[who] then slot.who[who] = true; slot.n = slot.n + 1 end
    self:_EvalUpdate()
end

-- Plus HAUTE version corroborée (≥ CONFIRM joueurs distincts) strictement > la mienne. Allume la
-- pastille minimap (reflet courant) et, si elle dépasse ce qu'on a déjà signalé, un mot dans le chat
-- (une seule fois par version — mémorisé dans la SavedVariable, pas de re-nag au prochain login).
function Dir:_EvalUpdate()
    local best
    for key, slot in pairs(self._verSeen or {}) do
        if slot.n >= CONFIRM and V.Greater(V.Parse(key), self:_MyVersion())
           and (not best or V.Greater(V.Parse(key), V.Parse(best))) then
            best = key
        end
    end
    if not best then return end
    self._updateVer = best
    if COC.db then COC.db.updateAlertedAt = time() end   -- re-corroborée aujourd'hui → le TTL repart
    if COC.UI and COC.UI.SetUpdateBadge then COC.UI:SetUpdateBadge(true, best) end
    if (COC.db and COC.db.updateAlerted) ~= best then
        if COC.db then COC.db.updateAlerted = best end
        p(string.format(COC.L["Une nouvelle version est disponible : |cFFFFD100%s|r (vous avez la %s). Pensez à mettre à jour."],
            best, self._myVerStr or "?"))
    end
end

-- Bringup (appelé par Directory:Start). Repart d'un comptage vierge à chaque session (les « qui »
-- distincts sont du runtime). Si une version signalée la session passée est TOUJOURS devant la mienne
-- ET récemment re-corroborée (ALERT_TTL), on rallume la pastille en SILENCE (pas de re-nag chat) ;
-- si j'ai mis à jour depuis, ou si plus personne ne la confirme depuis le TTL, on oublie.
function Dir:StartVersion()
    self._verSeen = {}
    self:_MyVersion()
    local db = COC.db
    local last = db and db.updateAlerted
    if not last then return end
    if not V.Greater(V.Parse(last), self:_MyVersion()) then
        db.updateAlerted, db.updateAlertedAt = nil, nil   -- mise à jour effectuée → on efface la mémoire d'alerte
    elseif db.updateAlertedAt and (time() - db.updateAlertedAt) > ALERT_TTL then
        db.updateAlerted, db.updateAlertedAt = nil, nil   -- jamais re-corroborée depuis le TTL → leurre probable
    else
        db.updateAlertedAt = db.updateAlertedAt or time() -- alerte d'avant le TTL (v1.27.0) : l'horloge démarre ici
        self._updateVer = last
        if COC.UI and COC.UI.SetUpdateBadge then COC.UI:SetUpdateBadge(true, last) end
    end
end

-- /co version [reset] — affiche ma version + l'éventuelle version signalée. `reset` oublie l'alerte
-- (pastille + mémoire SV + comptage runtime) : l'effaceur du test d'injection, et la seule sortie
-- manuelle si un numéro fantaisiste a été corroboré par des farceurs avant d'expirer par TTL.
function Dir:VersionCmd(rest)
    if (rest or ""):lower() == "reset" then
        self._verSeen = {}
        self._updateVer = nil
        if COC.db then COC.db.updateAlerted, COC.db.updateAlertedAt = nil, nil end
        if COC.UI and COC.UI.SetUpdateBadge then COC.UI:SetUpdateBadge(false) end
        p(COC.L["alerte de version oubliée — elle reviendra si le réseau la re-confirme."])
        return
    end
    p(string.format(COC.L["Crafting Order — version %s"], (self:_MyVersion() and self._myVerStr) or "?"))
    if self._updateVer then
        p(string.format(COC.L["Nouvelle version disponible : %s"], self._updateVer))
        p(COC.L["(/co version reset si cette alerte est erronée)"])
    end
end
