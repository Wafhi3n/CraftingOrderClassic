-- Directory_TradeLink.lua — un lien de métier posté dans le chat ajoute son AUTEUR à l'annuaire, et
-- l'annuaire ne garde que les artisans sans l'addon UTILES (spec docs/specs/lien-metier.md).
--
-- Le lien sur Forever (mesuré le 2026-09-27, docs/test-lien-metier.md) :
--   |Htrade:<GUID du propriétaire>:<sort de rang>:<ligne de métier>|h[Enchanting]|h
-- Ni niveau ni recettes : le serveur ne les envoie qu'au CLIC. Le métier entre donc « connu, niveau
-- inconnu » (craftSeen = 0, D4) ; le sort de rang est gardé BRUT (linkSpell), jamais interprété.
-- Rien n'est envoyé à l'auteur (D7) : ni DiscoverPlayer, ni réponse. La lecture du chat elle-même
-- vit dans CraftingOrderClassic_LFWChat.lua ; ici, le décodage, la fiche et la purge.
-- Méthodes sur COC.Directory (créé par Directory.lua, chargé avant dans le .toc).

local COC = CraftingOrderClassic
local Dir = COC.Directory

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

-- Lignes de métier du client : mêmes identifiants de Vanilla à Retail (333 et 185 mesurés sur
-- Camelot). Repli quand le libellé du lien ne se résout pas (langue sans alias dans CraftLink).
local SKILL_LINE = {
    [171] = "Alchemy", [164] = "Blacksmithing", [333] = "Enchanting", [202] = "Engineering",
    [165] = "Leatherworking", [197] = "Tailoring", [186] = "Mining", [185] = "Cooking",
    [129] = "First Aid", [356] = "Fishing", [755] = "Jewelcrafting", [773] = "Inscription",
}

-- Libellé d'abord (le résolveur d'alias FR/DE/ES déjà éprouvé), ligne de métier ensuite. Une clé
-- que CraftLink ne connaît pas ne vaut rien : ResolveProfession rend le mot brut quand il échoue.
local function resolveProf(c, label, line)
    if not c then return nil end
    local key = label ~= "" and c:ResolveProfession(label)
    if key and c:GetProfession(key) then return key end
    key = SKILL_LINE[line]
    if key and c:GetProfession(key) then return key end
    return nil
end

-- Métiers que l'auteur a LUI-MÊME liés dans `text` : liste de { prof, spell }, vide sinon. Pur.
-- `guid` = GUID de l'émetteur (12e argument de l'événement de chat) : le jeu authentifie l'émetteur,
-- pas ce dont il parle, donc le lien d'un autre (« demande à X [Enchantement] ») est ignoré (D3).
-- Secondaires écartés (D2). L'appelant a déjà écarté les valeurs SECRÈTES : on n'en teste aucune ici.
function Dir.ParseTradeLinks(text, guid)
    local out = {}
    if type(text) ~= "string" or type(guid) ~= "string" or guid == "" then return out end
    if not text:find("|Htrade:", 1, true) then return out end
    local c, seen = CL(), {}
    local SEC = COC.SECONDARY_PROF or {}
    for owner, spell, line, label in text:gmatch("|Htrade:([^:|]+):(%d+):(%d+)[^|]*|h%[([^%]]*)%]|h") do
        if owner == guid then
            local key = resolveProf(c, label, tonumber(line))
            if key and not SEC[key] and not seen[key] then
                seen[key] = true
                out[#out + 1] = { prof = key, spell = tonumber(spell) }
            end
        end
    end
    return out
end

-- `name` (nom réseau, authentifié par le jeu) a lié son métier `prof`. Display-only, comme une ligne
-- LFW lue dans le chat : fiche « connu sans l'addon », et ses vraies données, s'il a l'addon,
-- restent prioritaires (on n'écrit jamais dans r.skill / r.recipes, ni ne baisse un plancher).
function Dir:NoteLinkSeen(name, prof, spell)
    if not (name and prof) or name == COC.Api.PlayerName() then return end
    self.roster = self.roster or {}
    local r = self.roster[name]; if not r then r = {}; self.roster[name] = r end
    if self._ApplySource then self:_ApplySource(name, r) end
    r.faction = self._MyFaction and self:_MyFaction() or r.faction
    local t = time()
    r.lastSeen = t
    r.linkSeen = r.linkSeen or {};   r.linkSeen[prof] = t
    r.linkSpell = r.linkSpell or {}; r.linkSpell[prof] = spell
    if not ((r.skill and r.skill[prof]) or (r.recipes and r.recipes[prof])) then
        r.craftSeen = r.craftSeen or {}
        if r.craftSeen[prof] == nil then r.craftSeen[prof] = 0 end   -- 0 = connu sans l'addon, niveau inconnu
    end
    if not (r.skill or r.recipes) then r.nonAddon = true end
    self:CapSeen(prof)
    if COC.UI and COC.UI.RefreshSoon then COC.UI:RefreshSoon() end
end

-- ------------------------------------------------------------------
-- Purge par métier (D9) : au plus SEEN_CAP artisans connus SEULEMENT sans l'addon par métier.
-- S'ajoute à Dir:PruneRoster (7 jours, 500 fiches), ne la remplace pas.
-- ------------------------------------------------------------------
local SEEN_CAP = 10   -- nombre PROPOSÉ par l'agent le 2026-10-02, à confirmer par le user (spec, D9)
Dir.SEEN_CAP = SEEN_CAP
-- Mêmes relations que celles que garde PruneRoster : on ne les oublie jamais.
local KEEP_SOURCE = { guild = true, friend = true, added = true, circle = true }
local SEEN_FIELDS = { "craftSeen", "linkSeen", "linkSpell", "cdSeen" }

-- Fiche qui ne porte RIEN d'autre que des métiers vus sans l'addon : seule candidate à l'oubli.
-- Un [Dispo] en cours en est exclu, sinon un « LFW [lien] » frais serait oublié à son arrivée.
function Dir:_SeenOnly(name, r)
    if r.manual or KEEP_SOURCE[r.source or ""] or r.isPartner or r.relayed then return false end
    if r.skill or r.recipes or r.cooldowns then return false end
    if self.LFWOf and self:LFWOf(name) then return false end
    return true
end

local function forgetProf(r, prof)
    for _, f in ipairs(SEEN_FIELDS) do
        local t = r[f]
        if t then t[prof] = nil; if next(t) == nil then r[f] = nil end end
    end
end

-- Garde les `cap` mieux renseignés pour `prof` (niveau connu le plus haut, puis le plus récent) ;
-- les autres oublient ce métier, et une fiche sans plus aucun métier disparaît. Rend le nombre oublié.
function Dir:CapSeen(prof, cap)
    cap = cap or SEEN_CAP
    local list = {}
    for name, r in pairs(self.roster or {}) do
        if r.craftSeen and r.craftSeen[prof] ~= nil and self:_SeenOnly(name, r) then
            list[#list + 1] = { name = name, r = r, lvl = r.craftSeen[prof] or 0,
                                t = (r.linkSeen and r.linkSeen[prof]) or r.lastSeen or 0 }
        end
    end
    if #list <= cap then return 0 end
    table.sort(list, function(a, b)
        if a.lvl ~= b.lvl then return a.lvl > b.lvl end
        if a.t ~= b.t then return a.t > b.t end
        return a.name < b.name                   -- départage stable : même résultat à chaque passe
    end)
    for i = cap + 1, #list do
        local e = list[i]
        forgetProf(e.r, prof)
        if not e.r.craftSeen then self.roster[e.name] = nil end
    end
    return #list - cap
end

function Dir:CapSeenAll(cap)
    local profs = {}
    for _, r in pairs(self.roster or {}) do
        for p in pairs(r.craftSeen or {}) do profs[p] = true end
    end
    for p in pairs(profs) do self:CapSeen(p, cap) end
end

-- Passe complète à la connexion, juste après la purge existante. Directory.lua est à 499 lignes
-- (plafond anti-monolithe) : on s'accroche à PruneRoster plutôt que d'y ajouter un appel.
if hooksecurefunc and Dir.PruneRoster then
    hooksecurefunc(Dir, "PruneRoster", function(self) self:CapSeenAll() end)
end
