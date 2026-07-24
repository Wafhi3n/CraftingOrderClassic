-- CraftingOrderClassic_Handoff.lua — « garder une commande pour un ami capable ».
--
-- Le CERVEAU qui manquait : croiser une commande avec les métiers des artisans CONNUS (amis /
-- guilde / ajoutés), la conserver, et la leur passer à leur connexion — sans dépendre du canal
-- caché (tout en whisper, fiable). Trois usages :
--   * Palier 1 — commandes RÉSEAU : quand un ami connu se connecte, en plus du relais par portée
--     (Orders:OnArtisanOnline), on lui envoie un nudge « ORD|SUGG|id » pour MES commandes ouvertes
--     qu'il sait crafter → alerte « tu sais le faire » chez lui (dédup runtime).
--   * Palier 2 — ENTRANTES (/commerce, /guilde de joueurs sans l'addon) : si un ami connu sait la
--     faire, on me le signale et on la lui pousse comme ordre de synthèse « CAP-… » (recipient=Tous,
--     marqué captured=1 → chez lui viaAddon=false pour que l'acceptation prévienne le demandeur).
--   * Palier 3 — lecture pour l'UI : Pending() liste les commandes confiées (item · artisan · état).
--
-- Capacité = précise (bitfield RK si même dataVersion) OU grossière (connaît le métier via SK/RK).
-- Le RÉCEPTEUR revérifie sa VRAIE capacité (ICanCraft) avant d'alerter → pas de fausse alerte.

local COC     = CraftingOrderClassic
local Handoff = {}
COC.Handoff   = Handoff
local L       = COC.L

local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
local Codec     = COC.OrdersCodec   -- sérialisation ORD|SUGG (Orders_Codec.lua, chargé avant)

-- Dédup RUNTIME (non persisté) : on re-signale à chaque session tant que la commande reste ouverte,
-- mais une seule fois par (commande, artisan) et par session → pas de spam sur relog/transition.
Handoff._sent  = {}   -- [orderId.."@"..name] = true : nudge/forward déjà envoyé
Handoff._noted = {}   -- [inboundId] = true : « X peut la faire » déjà annoncé à MOI

local function me()  return (UnitName and UnitName("player")) or "?" end
local function pmsg(m) print("|cFF33DD88Crafting Order|r " .. m) end

-- L'annonce chat « X peut faire une captée » est du bruit en jeu normal (l'ordre est de toute façon
-- poussé/gardé en coulisse). On ne l'affiche donc qu'en mode verbeux (/co verbose) ou quand l'addon
-- de dev COCMonitor est chargé (contexte test/diag).
local function verbose()
    if COC.db and COC.db.verbose then return true end
    local ial = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    return (ial and ial("COCMonitor")) and true or false
end

-- Relation « proche » : ami / guildmate / artisan ajouté à la main. Seuls ceux-là reçoivent un
-- nudge personnel (les simples croisés voient l'ordre en silence via le maillage existant).
function Handoff:_Related(r)
    return r ~= nil and (r.isFriend or r.isGuild or r.source == "added" or r.manual) == true
end

-- Un ordre de synthèse (recipient=Tous) à partir d'une entrante captée, pour le pousser en whisper.
function Handoff:_SynthFromInbound(e)
    return { id = "CAP-" .. e.id, buyer = e.buyer, kind = "item", itemID = e.itemID, itemName = e.itemName,
             qty = e.qty or 1, price = e.price, profession = e.profession, recipient = "Tous" }
end

-- ------------------------------------------------------------------
-- Capacité
-- ------------------------------------------------------------------
-- `who` (de mon annuaire) sait-il crafter l'ordre `o` ? Précis (bitfield RK, même dataVersion) sinon
-- grossier (connaît le métier). La RELATION est vérifiée par les appelants, pas ici.
function Handoff:CanCraft(who, o)
    local D, c = COC.Directory, CraftLink
    if not (D and c and who) then return false end
    local r = D.roster and D.roster[who]; if not r then return false end
    local prof = o.profession or (o.itemID and COC.Orders and COC.Orders:ProfForItem(o.itemID))
    if not prof then return false end
    local spellID = o.spellID
    if not spellID and o.itemID then local i2s = c:ItemToSpell(prof); spellID = i2s and i2s[o.itemID] end
    local hex = r.recipes and r.recipes[prof]
    if hex and r.recipeDV == c:DataVersion() and spellID and c:HasBit(prof, hex, spellID) then return true end
    return ((r.skill and r.skill[prof]) or (r.recipes and r.recipes[prof])) ~= nil
end

-- MOI, est-ce que je sais VRAIMENT crafter cet ordre ? (revérif côté récepteur avant d'alerter)
function Handoff:ICanCraft(o)
    local c = CraftLink; if not c then return false end
    local prof = o.profession or (o.itemID and COC.Orders and COC.Orders:ProfForItem(o.itemID))
    if not prof then return false end
    if o.spellID then return c:IKnowRecipeBySpell(prof, o.spellID) end
    if o.itemID  then return c:IKnowRecipeForItem(prof, o.itemID) end
    return false
end

-- Artisans CONNUS (relation proche) qui savent faire `o`, en ligne d'abord. Exclut moi et l'auteur.
function Handoff:CapableKnownList(o)
    local D, m, out = COC.Directory, me(), {}
    if not (D and D.roster) then return out end
    for name, r in pairs(D.roster) do
        if name ~= m and name ~= o.buyer and self:_Related(r) and self:CanCraft(name, o) then
            out[#out + 1] = { name = name, online = D.online[name] == true }
        end
    end
    table.sort(out, function(a, b)
        if a.online ~= b.online then return a.online end
        return a.name < b.name
    end)
    return out
end

-- ------------------------------------------------------------------
-- Émission (nudge / forward)
-- ------------------------------------------------------------------
-- Palier 1 : nudge « tu sais le faire » pour une commande réseau déjà relayée à `who` (dédup session).
function Handoff:Suggest(o, who)
    if not CraftLink then return end
    local key = o.id .. "@" .. who
    if self._sent[key] then return end
    self._sent[key] = true
    CraftLink:Send(Codec.Encode("SUGG", { id = o.id }), "whisper", who)
end

-- Palier 2 : pousse à `who` les ENTRANTES qu'il sait faire (ordre de synthèse + nudge captured).
function Handoff:ForwardInboundTo(who)
    local O, m = COC.Orders, me()
    if not (O and CraftLink and COC.db and COC.db.inbound and who and who ~= m) then return end
    local r = COC.Directory and COC.Directory.roster and COC.Directory.roster[who]
    if not self:_Related(r) then return end
    if COC.Inbound then COC.Inbound:Prune() end   -- jamais pousser une entrante périmée (demandeur déjà servi)
    for _, e in pairs(COC.db.inbound) do
        if e.status ~= "dismissed" and e.buyer ~= who then
            local o = self:_SynthFromInbound(e)
            local key = o.id .. "@" .. who
            if not self._sent[key] and self:CanCraft(who, o) then
                self._sent[key] = true
                CraftLink:Send(O:_NewPayload(o), "whisper", who)          -- l'ordre lui-même
                CraftLink:Send(Codec.Encode("SUGG", { id = o.id, captured = true }), "whisper", who) -- nudge + captured
            end
        end
    end
end

-- Un artisan connu apparaît en ligne → nudges (mes commandes) + forward des entrantes qu'il sait faire.
-- Appelé APRÈS le relais par portée d'Orders:OnArtisanOnline (l'ordre a déjà été envoyé à `who`).
function Handoff:OnArtisanOnline(who)
    local O, m = COC.Orders, me()
    if not (O and CraftLink and who and who ~= m and COC.db) then return end
    local D = COC.Directory
    local r = D and D.roster and D.roster[who]
    if self:_Related(r) then
        for _, o in pairs(COC.db.orders or {}) do
            -- Mes commandes : filtrées par le relais mesh (_RelayMatch). Une commande captée n'est
            -- JAMAIS mesh-relayée (Orders:_RelayMatch l'exclut exprès) → elle suit son propre chemin,
            -- suggérée directement à un ami capable, sans repasser par ce filtre.
            if o.status == "open" and o.recipient ~= who and self:CanCraft(who, o) then
                if o.buyer == m then
                    if O:_RelayMatch(o, who) then self:Suggest(o, who) end
                elseif o.captured then
                    self:Suggest(o, who)
                end
            end
        end
    end
    self:ForwardInboundTo(who)
end

-- Une entrante vient d'être captée : la pousser aux capables DÉJÀ en ligne (les hors-ligne l'auront à
-- leur connexion via OnArtisanOnline). L'annonce chat « X peut la faire » n'est QUE du confort de diag
-- (verbose()) : le push ci-dessous a lieu dans tous les cas, qu'on l'affiche ou non.
function Handoff:NoteInbound(e)
    if not (e and CraftLink and COC.Directory) then return end
    local o = self:_SynthFromInbound(e)
    local list = self:CapableKnownList(o)
    if #list == 0 then return end
    if verbose() and not self._noted[e.id] then
        self._noted[e.id] = true
        local names = {}
        for _, a in ipairs(list) do names[#names + 1] = a.name end
        local nm  = (CraftLink:ItemName(e.itemID, e.itemName)) or e.itemName or ("item:" .. e.itemID)
        local msg = string.format(L["%s peut faire une commande captée — gardée pour son passage : %s"],
            table.concat(names, ", "), nm)
        local Skin = COC.UI and COC.UI.Skin
        pmsg((Skin and ("|T" .. Skin.tex.workorder .. ":0|t ") or "") .. msg)
        if COC.UI and COC.UI.Toast then COC.UI:Toast(msg, Skin and Skin.tex.workorder) end
    end
    for _, a in ipairs(list) do
        if a.online then self:ForwardInboundTo(a.name) end
    end
end

-- ------------------------------------------------------------------
-- Réception (côté artisan capable) : alerte « tu sais le faire »
-- ------------------------------------------------------------------
-- Nom d'objet async (GetItemInfo différé) → on retente ~3 s avant d'alerter, sinon « item:2459 ».
function Handoff:AlertCapable(o, tries)
    local O = COC.Orders; if not O then return end
    -- 1er appel SEULEMENT (`tries` nil ; les retries internes passent tries>=1) → garde anti-boucle : un SUGG
    -- est REJOUABLE (rien n'empêche un pair d'en renvoyer 50), sans dédup chaque copie refait toast+son. Même
    -- patron que o._rerollAlertDone. Et aucune alerte de la part d'un acheteur mis en sourdine.
    if not tries then
        if o._capableAlerted then return end
        if COC.Moderation and COC.Moderation.IsMuted and COC.Moderation:IsMuted(o.buyer) then return end
        o._capableAlerted = true
    end
    local nm = O:OrderName(o)
    if (nm:match("^item:") or nm:match("^spell:")) and (tries or 0) < 10 then
        if o.itemID and GetItemInfo then GetItemInfo(o.itemID) end
        if C_Timer then C_Timer.After(0.3, function() Handoff:AlertCapable(o, (tries or 0) + 1) end); return end
    end
    local Skin = COC.UI and COC.UI.Skin
    local qty = (Skin and Skin.QtySuffix(o)) or ""
    local pr  = o.price and (" — |cFFFFDD00" .. o.price .. "|r") or ""
    local msg = string.format(L["|cFF66CCFFtu sais le faire|r — demandé par |cFFFFFFFF%s|r : %s%s%s"],
        o.buyer or "?", nm, qty, pr)
    pmsg((Skin and ("|T" .. Skin.tex.workorder .. ":0|t ") or "") .. msg)
    if COC.UI and COC.UI.Toast then COC.UI:Toast(msg, Skin and Skin.tex.workorder) end
    pcall(function() PlaySound(SOUNDKIT and SOUNDKIT.TELL_MESSAGE or 3081, "Master") end)
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
end

-- ------------------------------------------------------------------
-- Rerolls / alts (même compte) : « ton reroll X sait le faire »
-- ------------------------------------------------------------------
-- Un de MES rerolls sait-il crafter `o` ? Lit les partitions persistées COC.db.knownRecipes[nom-royaume]
-- (set spellID par métier, cf. COC:_MyKnownStore) SANS que l'alt soit connecté. Renvoie le nom (court)
-- du 1er reroll capable, ou nil. Surface « ton reroll » quand le perso COURANT, lui, ne sait pas faire.
function Handoff:MyRerollCanCraft(o)
    local c = CraftLink
    if not (c and COC.db and COC.db.knownRecipes) then return nil end
    local prof = o.profession or (o.itemID and COC.Orders and COC.Orders:ProfForItem(o.itemID))
    if not prof then return nil end
    local spellID = o.spellID
    if not spellID and o.itemID then local i2s = c:ItemToSpell(prof); spellID = i2s and i2s[o.itemID] end
    if not spellID then return nil end
    local meKey = ((UnitName and UnitName("player")) or "?") .. "-" .. ((GetRealmName and GetRealmName()) or "")
    for who, partition in pairs(COC.db.knownRecipes) do
        local set = who ~= meKey and partition[prof]
        if set and set[spellID] then return who:match("^([^%-]+)") or who end
    end
    return nil
end

-- Alerte « ton reroll sait le faire » (chat + toast). Nom d'objet async → retente ~3 s (cf. AlertCapable).
-- Chemin unique pour cette alerte (appelé depuis AlertTargeted ordre nommé ET _OnSuggest) : o._rerollAlertDone
-- dédup côté ordre pour ne jamais l'afficher deux fois si les deux chemins se déclenchent pour le même id.
function Handoff:AlertReroll(o, alt, tries)
    if o._rerollAlertDone then return end
    local O = COC.Orders; if not O then return end
    local nm = O:OrderName(o)
    if (nm:match("^item:") or nm:match("^spell:")) and (tries or 0) < 10 then
        if o.itemID and GetItemInfo then GetItemInfo(o.itemID) end
        if C_Timer then C_Timer.After(0.3, function() Handoff:AlertReroll(o, alt, (tries or 0) + 1) end); return end
    end
    o._rerollAlertDone = true
    local Skin = COC.UI and COC.UI.Skin
    local what = nm .. ((Skin and Skin.QtySuffix(o)) or "")
    local msg  = string.format(L["ton reroll |cFFFFFFFF%s|r sait le faire : %s"], alt, what)
    pmsg((Skin and ("|T" .. Skin.tex.workorder .. ":0|t ") or "") .. msg)
    if COC.UI and COC.UI.Toast then COC.UI:Toast(msg, Skin and Skin.tex.workorder) end
end

-- ------------------------------------------------------------------
-- Lecture (Palier 3) — file « Confiées » pour l'UI
-- ------------------------------------------------------------------
function Handoff:_Row(o, a, id)
    return {
        name = COC.Orders:OrderName(o), qty = o.qty, byStack = o.byStack, price = o.price, profession = o.profession,
        itemID = o.itemID, spellID = o.spellID, target = a.name, online = a.online,
        delivered = self._sent[id .. "@" .. a.name] == true,
    }
end

-- Commandes confiées à des artisans connus : MES commandes ouvertes + les entrantes captées, une
-- ligne par (commande, artisan capable). delivered = déjà poussée cette session ; sinon « en attente ».
function Handoff:Pending()
    local m, out = me(), {}
    if not (COC.Orders and COC.db) then return out end
    if COC.Inbound then COC.Inbound:Prune() end   -- « Confiées » sans entrantes périmées
    for _, o in pairs(COC.db.orders or {}) do
        if o.buyer == m and o.status == "open" then
            for _, a in ipairs(self:CapableKnownList(o)) do out[#out + 1] = self:_Row(o, a, o.id) end
        end
    end
    for _, e in pairs(COC.db.inbound or {}) do
        if e.status ~= "dismissed" then
            local o = self:_SynthFromInbound(e)
            for _, a in ipairs(self:CapableKnownList(o)) do out[#out + 1] = self:_Row(o, a, o.id) end
        end
    end
    table.sort(out, function(x, y)
        if x.delivered ~= y.delivered then return not x.delivered end
        if x.online ~= y.online then return x.online end
        return (x.name or "") < (y.name or "")
    end)
    return out
end
