-- CraftingOrderClassic_Stats_Filter.lua — sélecteur « ne montrer que ce qui donne <stat> ».
--
-- Écrit UNE fois pour les TROIS listes qui en ont besoin (onglet Commande, vue métier, Mes artisans) :
-- elles n'ont pas la même structure de ligne, mais elles posent la même question. Chacune fournit deux
-- accesseurs (sa liste, l'itemID d'une entrée) et garde son propre choix — filtrer sur la Force dans
-- l'onglet Commande ne doit pas filtrer la vue métier.
--
-- Le filtre compare des TOKENS ITEM_MOD_* (cf. COC.Stats), jamais le libellé affiché : deux joueurs
-- de langues différentes filtrent la même chose, et changer la langue du client ne casse rien.
--
-- COÛT — le point à ne pas rater : peupler le menu exige de LIRE les stats de toute la liste, ce qui
-- peut déclencher des scans de tooltip. C'est fait à l'OUVERTURE DU MENU seulement, jamais sur le
-- chemin de rendu : `RefreshPostPlans` part à chaque frappe dans la recherche, un balayage là-dedans
-- se paierait à chaque lettre tapée.
-- ⚠️ `dd:SetValue()` compte AUSSI comme un balayage : le contrat de Skin.MakeDropdown relit la liste
-- pour retrouver le libellé d'une valeur. Donc SetValue/RefreshDropdown se rappellent au changement
-- de métier ou à la reconstruction d'une vue — JAMAIS depuis un rafraîchissement de liste.
-- `COC.Stats:AvailableFor` met son résultat en cache dès qu'un balayage est COMPLET, donc le coût
-- s'éteint de lui-même une fois le cache d'objets du client rempli.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local SF = {}
COC.StatFilter = SF

-- Valeur « aucun filtre ». PAS `nil` ni `false` : UIDropDownMenu lit `false` comme « pas de
-- sélection » et afficherait un sélecteur vide (même piège que QUALITY_STEPS, cf. _UI_Post.lua).
local ALL = "*"

-- Choix courant PAR VUE : [viewKey] = token, ou nil pour « toutes ».
local _sel = {}

function SF:Selected(viewKey) return _sel[viewKey] end

-- Choisit la stat d'une vue. `token` nil = « toutes ». Passe par ici plutôt que d'écrire `_sel` en
-- direct : c'est le point d'entrée d'un futur appelant non-UI (raccourci, commande slash).
function SF:Select(viewKey, token) _sel[viewKey] = token end

-- Remet la vue sur « toutes les stats ». À appeler quand la liste change de NATURE (changement de
-- métier) : un filtre « Force » hérité d'une vue de Forge viderait la Cuisine sans rien expliquer.
-- Rend true si le choix a bougé, pour que l'appelant rafraîchisse son sélecteur.
function SF:Reset(viewKey)
    if _sel[viewKey] == nil then return false end
    _sel[viewKey] = nil
    return true
end

-- Filtre une liste sur la stat choisie. Rend la liste D'ORIGINE (même table) si aucune stat n'est
-- choisie : le cas courant ne paie donc aucune copie.
function SF:Apply(viewKey, entries, getItemID)
    local token = _sel[viewKey]
    if not token then return entries end
    local out = {}
    for _, e in ipairs(entries or {}) do
        if COC.Stats:Matches(getItemID(e), token) then out[#out + 1] = e end
    end
    return out
end

-- Sélecteur natif partagé. `ctx` porte ce que la vue seule connaît :
--   ctx.key()     -> clé de cache du balayage (typiquement le métier ouvert) ; nil = pas de cache
--   ctx.entries() -> la liste AVANT filtrage (sinon le menu rétrécirait à chaque choix, et on ne
--                    pourrait plus revenir en arrière : un filtre doit toujours proposer ses voisins)
--   ctx.itemID(e) -> itemID d'une entrée
--   ctx.onChange()-> rafraîchir la liste
function SF:MakeDropdown(name, parent, width, viewKey, ctx)
    local dd = Skin.MakeDropdown(name, parent, width, function()
        local out = { { value = ALL, text = L["Toutes les stats"] } }
        for _, s in ipairs(COC.Stats:AvailableFor(ctx.key and ctx.key() or nil,
                                                  ctx.entries(), ctx.itemID)) do
            out[#out + 1] = { value = s.token, text = s.label }
        end
        return out
    end, {
        label = L["Stat"] .. " : ",
        onSelect = function(v)
            SF:Select(viewKey, (v ~= ALL) and v or nil)
            if ctx.onChange then ctx.onChange() end
        end,
    })
    dd:SetValue(_sel[viewKey] or ALL)
    dd.statViewKey = viewKey
    return dd
end

-- Réaligne le texte du sélecteur sur l'état réel (après un Reset, ou une reconstruction de vue).
-- Le libellé passe par `Stats:TokenLabel` (forme COURTE, jamais un gabarit) et JAMAIS par un `_G[token]`
-- brut : le token est canonique (forme longue), dont la globale nue rend souvent la phrase à trous
-- « Améliore … de %s. ». C'est le même piège que côté lecture, et il se rejouait ici.
function SF:RefreshDropdown(dd)
    if not (dd and dd.statViewKey) then return end
    local token = _sel[dd.statViewKey]
    dd:SetValue(token or ALL)
    if token then
        local label = COC.Stats and COC.Stats:TokenLabel(token)
        if type(label) == "string" and label ~= "" then
            UIDropDownMenu_SetText(dd, L["Stat"] .. " : " .. label)
        end
    end
end
