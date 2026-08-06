-- CraftingOrderClassic_Tracker_Next.lua — section « Progression » du suivi à l'écran : pour chaque
-- métier encore en montée, LA recette à crafter maintenant pour gagner le prochain point, ses
-- réactifs en objectifs, et le plan à acheter quand la route en achète un.
--
-- Montage HYBRIDE, imposé par l'API : hors fenêtre de métier, le rang est lisible à tout moment
-- (GetSkillLineInfo, via db.mySkills que Dir:CaptureSkills tient à jour) mais les RECETTES ne le sont
-- pas — d'où rang LIVE + recettes du CACHE (db.knownRecipes, partition du perso courant). C'est le
-- chemin déjà éprouvé par la bourse d'artisan. Conséquence assumée : un plan appris depuis la
-- dernière ouverture de la fenêtre manque au calcul jusqu'à la prochaine.
--
-- Le calcul lui-même est COC.Route:NextStep — un seul pickBest au rang courant, pas la marche
-- jusqu'au plafond de Route:Compute : ce fournisseur tourne à chaque BAG_UPDATE.
-- Un fournisseur de plus dans COC.Journal, rien d'autre : aucune UI ici.

local COC  = CraftingOrderClassic
local Skin = COC.UI and COC.UI.Skin
local L    = COC.L

-- Flèche « vers » en TEXTURE : la police rend « → » en tofu.
local ARROW = "|TInterface\\ChatFrame\\ChatFrameExpandArrow:12:12|t"

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

-- Métiers du perso courant encore en montée, RANG DÉCROISSANT (décision user : le plus haut d'abord).
-- Seuls les métiers CACHÉS sont écartés, comme dans la bourse : la Cuisine et le Secourisme se
-- montent aussi, et le tri par rang les pose naturellement en bas de section (rang faible).
local function levelingProfs()
    local out, SEC = {}, COC.HIDDEN_PROF or {}
    for key, v in pairs((COC.db and COC.db.mySkills) or {}) do
        local rank, max = v[1] or 0, v[2] or 0
        if not SEC[key] and rank > 0 and rank < max then
            out[#out + 1] = { key = key, rank = rank, max = max }
        end
    end
    table.sort(out, function(a, b)
        if a.rank ~= b.rank then return a.rank > b.rank end
        return a.key < b.key                      -- départage stable : pas de clignotement
    end)
    return out
end

-- Recettes connues de CE perso, au format attendu par COC.Route. Le magasin local
-- (COC:_MyKnownStore) tient un SET de spellID par métier — pas un bitfield hexa comme le roster :
-- aucun DecodeKnown ici.
local function knownSet(profKey)
    local store = COC._MyKnownStore and COC:_MyKnownStore()
    local set = store and store[profKey]
    if not set then return nil end
    local out = {}
    for sid in pairs(set) do out["s" .. sid] = true end
    return next(out) and out or nil
end

local function recipeName(sid, prod)
    local lib = CL()
    local nm = prod and GetItemInfo and GetItemInfo(prod)
    if not nm and prod and lib and lib.ItemName then nm = lib:ItemName(prod) end
    if not nm and GetSpellInfo then nm = GetSpellInfo(sid) end
    if not nm and lib and lib.RecipeName then nm = lib:RecipeName(sid) end
    return nm or ("spell:" .. tostring(sid))
end

-- Objectifs = les réactifs d'UN craft. On n'affiche pas les ~2,3 crafts espérés en quantité : ce que
-- le joueur veut savoir, c'est ce qu'il lui faut pour lancer le prochain. Le coût par point, lui,
-- intègre bien l'espérance (Route:NextStep).
local function stepObjectives(profKey, sid, ctx)
    local lib = CL()
    if not (lib and lib.RecipeReagents) then return nil end
    local reag = lib:RecipeReagents(profKey, sid)
    if not (reag and #reag > 0) then return nil end
    local out, done = {}, 0
    for _, rg in ipairs(reag) do
        local need = rg[2] or 1
        local have = ctx.bagCount(rg[1])
        local ok = have >= need
        if ok then done = done + 1 end
        out[#out + 1] = { itemID = rg[1], have = have, need = need, done = ok }
    end
    return out, done
end

-- Ligne « plan à acheter » — même formulation et mêmes clés de locale que la bourse d'artisan, pour
-- que les deux vues parlent d'une seule voix. Un plan de FORMATEUR n'a pas d'objet : on envoie au PNJ.
local function planNote(profKey, step)
    if not step.plan then return nil end
    local M = COC.MTSL
    local kind = (M and M.IsAvailable and M:IsAvailable()) and M:SourceKind(profKey, step.sid) or "unknown"
    local price = (step.plan.price or 0) > 0 and GetCoinTextureString
        and (" — " .. GetCoinTextureString(step.plan.price)) or ""
    local name = recipeName(step.sid, step.prod)
    local txt
    if kind == "trainer" then
        txt = "|cFF88CCFF" .. string.format(L["Au formateur : %s"], name) .. price .. "|r"
    else
        txt = "|TInterface\\Icons\\INV_Scroll_03:12:12|t |cFFEEDD88"
            .. L["Plan à acheter"] .. " : " .. name .. price .. "|r"
    end
    local npc = (M and M.SourceNpcLine) and M:SourceNpcLine(profKey, step.sid) or nil
    if npc then txt = txt .. "   " .. npc end
    return txt
end

-- Montant ARRONDI À L'ARGENT : GetCoinTextureString rend trois icônes (or/argent/cuivre) et une ligne
-- de HUD n'a pas cette place — le cuivre ne change jamais la décision « quelle recette pour ce point ».
-- Sous 1 pa on garde la valeur exacte, sinon un coût réel s'afficherait « 0 ».
local function costText(copper)
    local c = math.floor((copper or 0) + 0.5)
    if c >= 100 then c = math.floor(c / 100) * 100 end
    return GetCoinTextureString and GetCoinTextureString(c) or tostring(c)
end

-- Sous-titre : « 317 → 380 · ~41po/point ». Un coût PARTIEL (réactif sans prix coté) se dit « > »,
-- jamais « ~ » : la route le sous-estime et ne doit pas le faire passer pour une estimation sûre.
local function subtitle(p, step)
    local sub = p.rank .. " " .. ARROW .. " " .. step.target
    if step.perPoint then
        sub = sub .. "  " .. string.format(step.partial and L[">%s/point"] or L["~%s/point"],
                                           costText(step.perPoint))
    end
    return sub
end

-- Le fournisseur. Silencieux si les briques manquent (Lazy Gold absent, seuils non générés, métier
-- jamais ouvert) : une section vide vaut mieux qu'un conseil inventé.
local function progressProvider(entries, ctx)
    local Route = COC.Route
    if not (Route and Route.NextStep) then return end
    local withPlans = not (COC.db and COC.db.routePlans == false)
    for _, p in ipairs(levelingProfs()) do
        local known = knownSet(p.key)
        local step = known and Route:NextStep(p.key, p.rank, p.max, { known = known, plans = withPlans })
        if step then
            local objs, done = stepObjectives(p.key, step.sid, ctx)
            local icon = Skin and Skin.ProfIcon and Skin.ProfIcon(p.key)
            local note = planNote(p.key, step)
            entries[#entries + 1] = {
                key      = "next:" .. p.key,
                section  = "progress",
                title    = (icon and ("|T" .. icon .. ":12:12|t ") or "") .. recipeName(step.sid, step.prod),
                sub      = subtitle(p, step),
                complete = (objs ~= nil) and (done == #objs),
                objectives = objs,
                notes    = note and { note } or nil,
                itemID   = step.prod, spellID = step.sid,
                prof     = p.key,
                sort     = -p.rank,   -- tri croissant sur `sort` ⇒ rang décroissant à l'écran
            }
        end
    end
end

if COC.Journal then COC.Journal:AddProvider(progressProvider) end
