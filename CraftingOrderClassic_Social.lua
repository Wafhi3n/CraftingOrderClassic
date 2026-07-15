-- CraftingOrderClassic_Social.lua — couche sociale passive (socle).
-- * Social:ProfSummary(nom) : résumé métiers+niveaux d'un joueur présent dans Directory.roster
--   (icônes + « 250/300 » via SK, repli bitfield RK). Réutilisé par le tooltip MONDE (ci-dessous),
--   le tooltip d'AMI et le panneau de GUILDE (_Social_Roster.lua), et le menu (_Social_Menu.lua).
-- * Découverte au croisement : survol / cible / groupe → whisper PING+HI throttlé (Dir:DiscoverPlayer).

local COC    = CraftingOrderClassic
local Social = {}
COC.Social   = Social

local CraftLink = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)

local function GetSkin() return COC.UI and COC.UI.Skin end

-- Découverte MODÉRÉE depuis une interaction UI (survol d'ami, ouverture de menu, sélection guilde).
-- Trois garde-fous CUMULÉS pour ne jamais spammer le réseau :
--   1) on ne ping QUE si ses métiers manquent (ni skill ni recipes en roster) → un crafteur déjà connu
--      n'est jamais re-pingé au survol ;
--   2) throttle GLOBAL 1,5 s → une rafale (balayage souris sur la liste d'amis) ne lance qu'UN ping ;
--   3) DiscoverPlayer reste throttlé 60 s/nom en dernier rempart.
local _lastInteractDiscover = 0
function Social:MaybeDiscover(name)
    local D = COC.Directory
    if not (name and name ~= "" and D and D.DiscoverPlayer) then return end
    local r = D.roster and D.roster[name]
    if r and (r.skill or r.recipes) then return end                 -- déjà connu → inutile
    local t = (GetTime and GetTime()) or 0
    if t - _lastInteractDiscover < 1.5 then return end              -- anti-rafale (sweep souris)
    _lastInteractDiscover = t
    D:DiscoverPlayer(name)
end

-- Métiers SECONDAIRES : jamais affichés dans le résumé social (seuls les PRIMAIRES intéressent la
-- prise de commande). Table PARTAGÉE définie dans CraftingOrderClassic.lua (source unique).
local SECONDARY_PROF = COC.SECONDARY_PROF

-- =========================================================================
-- Résolution Battle.net → nom de PERSONNAGE WoW. Les surfaces natives d'amis BNet (menu, tooltip)
-- exposent le nom de COMPTE, pas le perso joué ; notre roster est indexé par perso. On extrait le
-- perso d'un BNetAccountInfo (C_BattleNet.*), SEULEMENT s'il joue à CETTE version de WoW (même
-- client + wowProjectID). nil sinon : Retail, autre jeu Blizzard, ou hors ligne → rien à cibler.
-- =========================================================================
function Social:BNetCharFromAccount(acc)
    local g = acc and acc.gameAccountInfo
    if not g or g.clientProgram ~= BNET_CLIENT_WOW then return nil end
    if WOW_PROJECT_ID and g.wowProjectID and g.wowProjectID ~= WOW_PROJECT_ID then return nil end
    return (g.characterName and g.characterName ~= "") and g.characterName or nil
end

-- =========================================================================
-- Résumé métiers d'un joueur connu (roster CraftLink) — icônes INLINE + niveaux. Métiers PRIMAIRES
-- uniquement (cf. SECONDARY_PROF). Renvoie nil si le joueur n'a pas l'addon / aucun métier primaire connu.
-- =========================================================================
function Social:ProfSummary(name)
    if not (name and COC.Directory) then return nil end
    local r = COC.Directory.roster[name]
    if not r then return nil end
    local sk = GetSkin()
    -- Icône de métier INLINE (|T…|t) plutôt que le nom long → ligne compacte. Repli sur le libellé
    -- si le client n'a pas l'icône en cache.
    local function profMark(key)
        local t = sk and sk.ProfIcon(key)
        return t and ("|T" .. t .. ":14:14:0:0|t") or (sk and sk.ProfLabel(key) or key)
    end
    -- Suffixe « · N plans » : profondeur du carnet connu de ce joueur pour CE métier (bitfield RK
    -- décompté sans matérialiser le set). nil/0 → rien (SK sans RK, ou catalogue absent).
    local function recipeCount(key)
        local hex = r.recipes and r.recipes[key]
        local n = (CraftLink and hex) and CraftLink:CountKnown(key, hex) or 0
        return (n > 0) and ("  |cFF8FbFa0" .. string.format(COC.L["· %d plans"], n) .. "|r") or ""
    end
    local parts = {}
    -- Priorité : niveaux SK reçus (plus précis — icône + « 250/300 »).
    for key, sv in pairs(r.skill or {}) do
        if not SECONDARY_PROF[key] then parts[#parts + 1] = profMark(key) .. " " .. sv[1] .. "/" .. sv[2] .. recipeCount(key) end
    end
    -- Fallback : métiers connus via bitfield RK, sans niveau → icône seule.
    if #parts == 0 then
        for key in pairs(r.recipes or {}) do
            if not SECONDARY_PROF[key] then parts[#parts + 1] = profMark(key) .. recipeCount(key) end
        end
    end
    -- Repli : fiche RELAYÉE par un partenaire (artisan hors ligne) — plus riche qu'un « vu crafter »,
    -- mais grade estimation (la ligne « via X » d'OnUnitTooltip qualifie la provenance).
    if #parts == 0 and r.relayed then
        for key, sv in pairs(r.relayed.skill or {}) do
            if not SECONDARY_PROF[key] then parts[#parts + 1] = profMark(key) .. " " .. sv[1] .. "/" .. sv[2] end
        end
        if #parts == 0 then
            for key in pairs(r.relayed.recipes or {}) do
                if not SECONDARY_PROF[key] then parts[#parts + 1] = profMark(key) end
            end
        end
    end
    -- Dernier recours : non-porteur d'addon VU crafter (CHAT_MSG_LOOT) → plancher de skill « N+ ».
    if #parts == 0 then
        for key, floor in pairs(r.craftSeen or {}) do
            if not SECONDARY_PROF[key] then
                parts[#parts + 1] = profMark(key) .. ((floor and floor > 0) and (" " .. floor .. "+") or "")
            end
        end
    end
    if #parts == 0 then return nil end
    table.sort(parts)
    local rep = (r.rep and r.rep > 0) and ("  |cFFE8B84B" .. string.format(COC.L["%d livrés"], r.rep) .. "|r") or ""
    return table.concat(parts, "   ") .. rep
end

-- =========================================================================
-- Cooldowns de recettes (transmutations & co) — lignes prêtes à afficher.
-- =========================================================================
-- Libellé d'un groupe de CD partagé : UNE ligne pour tout le groupe (12 transmutations = 1 ligne,
-- même readyAt puisque la catégorie est partagée). Un littéral L[clé] par groupe (porte check_locale).
local function groupLabel(grp)
    if grp == "transmute" then return COC.L["Transmutation"] end
    return nil
end

-- Lignes cooldown d'un artisan (ENTRÉE ROSTER, pas un nom) : { { text=, ready= } } triées prêtes
-- d'abord puis par échéance, ou nil. Sources par priorité : r.cooldowns (réseau direct) >
-- r.relayed.cooldowns (relais partenaire) > r.cdSeen (estimation CLEU) — les deux dernières avec
-- suffixe « (estimé) ». `profFilter` limite à un métier (tooltips d'icône de l'annuaire).
function Social:CooldownLines(r, cap, profFilter)
    if not (r and CraftLink and CraftLink.RecipeCdGroup) then return nil end
    local src, est = r.cooldowns, false
    if not (src and next(src)) then src, est = (r.relayed and r.relayed.cooldowns), true end
    if not (src and next(src)) then src, est = r.cdSeen, true end
    if not (src and next(src)) then return nil end
    local now, agg = time(), {}
    for prof, set in pairs(src) do
        if (not profFilter or prof == profFilter) and not SECONDARY_PROF[prof] then
            for sid, readyAt in pairs(set) do
                local grp = CraftLink:RecipeCdGroup(prof, sid)
                local key = grp and (prof .. "|" .. grp) or (prof .. "#" .. sid)
                local a = agg[key]
                if not a then
                    local label = (grp and groupLabel(grp))
                        or CraftLink:RecipeName(sid) or tostring(sid)
                    agg[key] = { label = label, readyAt = readyAt }
                elseif readyAt > a.readyAt then a.readyAt = readyAt end   -- fusion groupe : le plus tardif
            end
        end
    end
    local rows = {}
    for _, a in pairs(agg) do rows[#rows + 1] = a end
    if #rows == 0 then return nil end
    table.sort(rows, function(x, y)
        if (x.readyAt <= now) ~= (y.readyAt <= now) then return x.readyAt <= now end   -- prêtes d'abord
        if x.readyAt ~= y.readyAt then return x.readyAt < y.readyAt end
        return x.label < y.label
    end)
    local sk, out = GetSkin(), {}
    local sfx = est and (" |cFF808080" .. COC.L["(estimé)"] .. "|r") or ""
    for i = 1, math.min(#rows, cap or #rows) do
        local a = rows[i]
        if a.readyAt <= now then
            out[#out + 1] = { ready = true, text = string.format(COC.L["%s : prête"], a.label) .. sfx }
        else
            local dur = (sk and sk.FormatDuration) and sk.FormatDuration(a.readyAt - now)
                or (tostring(a.readyAt - now) .. "s")
            out[#out + 1] = { text = string.format(COC.L["%s : dans %s"], a.label, dur) .. sfx }
        end
    end
    return out
end

-- =========================================================================
-- Détail des recettes connues d'un joueur (déplié sur Maj), groupé par métier PRIMAIRE. Décode le
-- bitfield RK en spellID → nom localisé (GetSpellInfo). Plafonné par métier (perProfCap) pour ne pas
-- déborder l'écran : au-delà, une ligne « +N de plus ». Renvoie une liste { {text=, header=} } ou nil.
-- =========================================================================
-- Check LÉGER (pas de décodage) : ce joueur a-t-il au moins un métier PRIMAIRE avec un bitfield RK
-- non vide ? Sert à n'afficher le rappel « Maj » que quand il y a réellement des plans à déplier.
function Social:HasRecipeDetail(name)
    if not (name and COC.Directory) then return false end
    local r = COC.Directory.roster[name]
    if not (r and r.recipes) then return false end
    for key, hex in pairs(r.recipes) do
        if not SECONDARY_PROF[key] and hex and hex ~= "" then return true end
    end
    return false
end

function Social:RecipeDetail(name, perProfCap)
    if not (name and CraftLink and COC.Directory) then return nil end
    local r = COC.Directory.roster[name]
    if not (r and r.recipes) then return nil end
    perProfCap = perProfCap or 20
    local sk = GetSkin()
    local lines = {}
    for key, hex in pairs(r.recipes) do
        if not SECONDARY_PROF[key] then
            local set = CraftLink:DecodeKnown(key, hex)
            local names = {}
            for spellID in pairs(set or {}) do names[#names + 1] = CraftLink:RecipeName(spellID) end
            if #names > 0 then
                table.sort(names)
                lines[#lines + 1] = { header = true, text = (sk and sk.ProfLabel(key)) or key }
                for i = 1, math.min(#names, perProfCap) do lines[#lines + 1] = { text = names[i] } end
                if #names > perProfCap then
                    lines[#lines + 1] = { dim = true, text = string.format(COC.L["+%d de plus"], #names - perProfCap) }
                end
            end
        end
    end
    return (#lines > 0) and lines or nil
end

-- =========================================================================
-- Métiers CRAFTABLES connus d'un joueur, pour les entrées « Commander <métier> » du menu clic-droit.
-- skill ∪ recipes, moins les SECONDAIRES (pas de commande — cf. COC.SECONDARY_PROF) et les récoltes
-- pures (COC.GATHER_ONLY) que la fenêtre Commande n'accepte pas. Trié par libellé localisé (ordre
-- stable pour l'UI). Renvoie un tableau de clés métier (typiquement 0..2 métiers primaires).
-- =========================================================================
function Social:OrderableProfs(name)
    if not (name and COC.Directory) then return {} end
    local r = COC.Directory.roster[name]
    if not r then return {} end
    local gather = COC.GATHER_ONLY or {}
    local seen, out = {}, {}
    local function add(t)
        for k in pairs(t or {}) do
            if not SECONDARY_PROF[k] and not gather[k] and not seen[k] then
                seen[k] = true; out[#out + 1] = k
            end
        end
    end
    add(r.skill); add(r.recipes)
    local sk = GetSkin()
    table.sort(out, function(a, b) return ((sk and sk.ProfLabel(a)) or a) < ((sk and sk.ProfLabel(b)) or b) end)
    return out
end

-- =========================================================================
-- Tooltip MONDE (unité). Migré de OnTooltipSetUnit (mort depuis le refactor tooltip de Classic Era)
-- vers TooltipDataProcessor.AddTooltipPostCall ; repli sur l'ancien script hook pour un vieux client.
-- =========================================================================
local function OnUnitTooltip(tooltip)
    if tooltip ~= GameTooltip or tooltip._cocProfAdded then return end   -- _cocProfAdded : anti-doublon (2 chemins)
    local _, unit = tooltip:GetUnit()
    if not unit then return end
    local name = UnitName(unit)
    local summary = name and Social:ProfSummary(name)
    local D = COC.Directory
    local lfwE = name and D and D.LFWOf and D:LFWOf(name)
    -- Un joueur LFW sans métiers connus (verbe canal reçu avant tout SK/RK) mérite quand même son bloc.
    if not (summary or lfwE) then return end
    local sk = GetSkin()
    -- Marque addon = icône WorkOrder (le glyphe « ✓ » s'affichait en tofu dans la police WoW).
    local mark = sk and ("  |T" .. sk.tex.workorder .. ":14:14:0:0|t") or ""
    tooltip:AddLine("|cFF33DD88CO-Classic|r" .. mark .. (summary and ("  " .. summary) or ""), 1, 1, 1)
    -- « Cherche du travail » + détails d'OFFRE (compos de base, composants fournis, commission,
    -- restriction progression) — mêmes lignes que l'annuaire (source unique : Dir:LFWOfferLines).
    if lfwE then
        local profTxt = (sk and sk.ProfLabel and sk.ProfLabel(lfwE.prof)) or lfwE.prof
        tooltip:AddLine("|cFF4CDB6E" .. string.format(COC.L["Cherche du travail : %s"], profTxt) .. "|r")
        for _, ln in ipairs((D.LFWOfferLines and D:LFWOfferLines(name)) or {}) do
            tooltip:AddLine("   " .. ln, 0.72, 0.90, 0.78)
        end
    end
    -- Cooldowns de recettes : 3 lignes max — vert = prête, orange = en cours de recharge.
    local rr = COC.Directory and COC.Directory.roster and COC.Directory.roster[name]
    for _, ln in ipairs((rr and Social:CooldownLines(rr, 3)) or {}) do
        if ln.ready then tooltip:AddLine("   " .. ln.text, 0.3, 0.9, 0.4)
        else tooltip:AddLine("   " .. ln.text, 1.0, 0.65, 0.2) end
    end
    -- Résumé issu d'un RELAIS de partenaire (aucune donnée directe) → provenance + fraîcheur.
    if rr and rr.relayed and not (rr.skill or rr.recipes) then
        local dur = (sk and sk.FormatDuration) and sk.FormatDuration(math.max(0, time() - (rr.relayed.ts or time()))) or "?"
        tooltip:AddLine("   |cFF808080" .. string.format(COC.L["via %s · il y a %s"], rr.relayed.via or "?", dur) .. "|r")
    end
    -- Maj déplie la liste des plans connus ; sinon un rappel discret. RecipeDetail = nil si aucun RK reçu.
    local detail = (IsShiftKeyDown and IsShiftKeyDown()) and Social:RecipeDetail(name)
    if detail then
        for _, ln in ipairs(detail) do
            if ln.header then tooltip:AddLine(ln.text, 0.6, 0.85, 1.0)
            elseif ln.dim then tooltip:AddLine("   " .. ln.text, 0.5, 0.5, 0.5)
            else tooltip:AddLine("   " .. ln.text, 0.9, 0.9, 0.9) end
        end
    elseif Social:HasRecipeDetail(name) then
        tooltip:AddLine("|cFF808080" .. COC.L["Maj : plans connus"] .. "|r")
    end
    tooltip._cocProfAdded = true
    tooltip:Show()
end

-- Presser/relâcher Maj sur un joueur survolé → reconstruire le tooltip pour (dé)plier les plans.
-- SetUnit force un rebuild complet → le post-call ci-dessus re-tourne avec le nouvel état de Maj.
local function OnShiftToggle(_, key)
    if key ~= "LSHIFT" and key ~= "RSHIFT" then return end
    if UnitExists and UnitExists("mouseover") and GameTooltip and GameTooltip:IsShown() then
        GameTooltip:SetUnit("mouseover")
    end
end

-- =========================================================================
-- Découverte au CROISEMENT : survoler / cibler / grouper un joueur → on lui chuchote un PING+HI
-- (Dir:DiscoverPlayer, throttlé 60 s/nom). S'il a l'addon, il répond → il entre dans Croisés/Met
-- avec ses métiers. S'il ne l'a pas, rien (addon-messages whisper invisibles côté receveur).
-- =========================================================================
local function discover(unit)
    if not (unit and COC.Directory and UnitIsPlayer and UnitIsPlayer(unit)) then return end
    if UnitIsUnit and UnitIsUnit(unit, "player") then return end
    -- Whisper addon-message ne traverse pas la faction adverse → on ne ping que les alliés potentiels.
    if UnitCanCooperate and not UnitCanCooperate("player", unit) then return end
    local name = UnitName(unit)
    if name and name ~= "" then COC.Directory:DiscoverPlayer(name) end
end

function Social:_WireDiscovery()
    local f = CreateFrame("Frame")
    f:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")
    f:SetScript("OnEvent", function(_, event)
        if event == "UPDATE_MOUSEOVER_UNIT" then discover("mouseover")
        elseif event == "PLAYER_TARGET_CHANGED" then discover("target")
        else
            local prefix = IsInRaid and IsInRaid() and "raid" or "party"
            for i = 1, (GetNumGroupMembers and GetNumGroupMembers() or 0) do discover(prefix .. i) end
        end
    end)
end

-- =========================================================================
-- Activation (appelé depuis PLAYER_LOGIN dans CraftingOrderClassic.lua)
-- =========================================================================
function Social:Start()
    -- pcall : un pépin dans un hook social ne doit JAMAIS avorter la chaîne PLAYER_LOGIN qui suit
    -- (BuildMinimapButton, Inbound, slash…). L'erreur est mémorisée (/co socialdiag) et remontée.
    local ok, err = pcall(function()
        -- Tooltip MONDE : OnTooltipSetUnit fonctionne en Classic Era (l'API tooltip n'a PAS été
        -- neutralisée comme le menu) → chemin ÉPROUVÉ, on le garde en primaire. On enregistre AUSSI
        -- l'API moderne en repli ; _cocProfAdded (remis à zéro sur OnTooltipCleared) évite le doublon.
        if GameTooltip and GameTooltip.HookScript then
            GameTooltip:HookScript("OnTooltipSetUnit", OnUnitTooltip)
            GameTooltip:HookScript("OnTooltipCleared", function(tt) tt._cocProfAdded = nil end)
        end
        if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
            and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnUnitTooltip)
        end
        if Social.InstallMenus  then Social:InstallMenus()  end   -- _Social_Menu.lua (menu clic-droit)
        if Social.WireRosterUI  then Social:WireRosterUI()  end   -- _Social_Roster.lua (tooltip ami + guilde)
        Social:_WireDiscovery()
        local sf = CreateFrame("Frame")     -- Maj (dé)plie les plans dans le tooltip monde
        sf:RegisterEvent("MODIFIER_STATE_CHANGED")
        sf:SetScript("OnEvent", function(_, _, key) OnShiftToggle(nil, key) end)
    end)
    if not ok then
        self._startError = err
        if geterrorhandler then geterrorhandler()(err) end
    end
end

-- Diagnostic (/co socialdiag [nom]) : état des hooks + données roster de la cible → pour comprendre
-- pourquoi un tooltip reste vide (souvent : le joueur n'a pas de métier PRIMAIRE, ou pas encore découvert).
function Social:Diag(name)
    local out = function(s) DEFAULT_CHAT_FRAME:AddMessage("|cFF33DD88[CO diag]|r " .. s) end
    if not (name and name ~= "") then
        if UnitIsPlayer and UnitIsPlayer("target") then name = UnitName("target")
        elseif UnitIsPlayer and UnitIsPlayer("mouseover") then name = UnitName("mouseover") end
    end
    out("Start: " .. (self._startError and ("|cFFFF4444ERREUR|r " .. tostring(self._startError)) or "|cFF33DD33ok|r"))
    out(("UIPanels_Game=%s · FriendsFrameTooltip_Show=%s · GuildStatus_Update=%s"):format(
        tostring(C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Blizzard_UIPanels_Game")),
        type(FriendsFrameTooltip_Show), type(GuildStatus_Update)))
    out(("hooks: ami=%s guilde=%s menu=%s"):format(
        tostring(self._friendHooked), tostring(self._guildHooked), tostring(self._menuHooked)))
    if not (name and name ~= "") then out("aucune cible — cible un joueur ou /co socialdiag <nom>"); return end
    local r = COC.Directory and COC.Directory.roster and COC.Directory.roster[name]
    out("cible=|cFFFFFFFF" .. name .. "|r roster=" .. (r and "|cFF33DD33oui|r" or "|cFFFF4444non|r"))
    if r then
        local sk = {}; for k, v in pairs(r.skill or {}) do sk[#sk+1] = k .. " " .. tostring(v[1]) .. "/" .. tostring(v[2]) end
        local rk = {}; for k in pairs(r.recipes or {}) do rk[#rk+1] = k end
        out("  skill: " .. (next(sk) and table.concat(sk, ", ") or "(vide)"))
        out("  recipes: " .. (next(rk) and table.concat(rk, ", ") or "(vide)"))
    end
    out("  ProfSummary=" .. (self:ProfSummary(name) or "|cFFFF4444nil|r (rien à afficher)"))
end
