-- CraftingOrderClassic_Writs.lua — les Craftsman's Writ de WoW: Forever (réputation Azeroth
-- Commerce Authority) : quel writ lance quelle quête, et quel objet elle demande.
--
-- Un writ est une commande d'artisan passée par un PNJ : la quête demande un objet fabriqué, tiré
-- parmi 150 sur cinq métiers SANS tenir compte des métiers du joueur, et un objet acheté ou fabriqué
-- par un autre est accepté (vu en jeu le 2026-10-16). D'où l'idée de COC : faire de ce writ une vraie
-- commande. Spec : docs/specs/writs-aca.md.
--
-- Tout passe par les IDENTIFIANTS (writ, quête, objet), jamais par les noms : ils sont traduits.
-- La table vit dans CraftingOrderClassic_Writs_Data.lua, générée par tools/gen_writs.lua.
--
-- CONTRAT : les entrées rendues sont PARTAGÉES — à lire, jamais à modifier.
--   W:Info(writItemID)  → { writ, quest, tier, rep, items = { objet [, homonyme] } } | nil
--   W:ForQuest(questID) → la même entrée, retrouvée par sa quête | nil
--   W:All()             → writItemID → entrée, pour parcourir
-- `items` a deux objets pour un nom qui en désigne deux (« Golden Scale Gauntlets ») : la quête
-- acceptée dit lequel. Le métier n'est pas stocké (Gordok Ogre Suit en a deux) : Orders:ProfForItem.
--
-- Aucune UI ici, aucun événement : ce module rend des données.

local COC = CraftingOrderClassic
local W = {}
COC.Writs = W

-- Réputation de la quête selon le palier (1 Journeyman, 2 Expert, 3 Artisan), lue sur Wowhead : les
-- 150 quêtes la respectent, le générateur échoue si l'une s'en écarte.
W.REP = { 75, 125, 200 }

local byWrit, byQuest = {}, {}

function W:Load(data)
    for writ, row in pairs(data) do
        local items = {}
        for i = 3, #row do items[#items + 1] = row[i] end
        local e = { writ = writ, quest = row[1], tier = row[2], rep = self.REP[row[2]], items = items }
        byWrit[writ], byQuest[row[1]] = e, e
    end
end

function W:Info(writItemID) return byWrit[tonumber(writItemID) or -1] end
function W:ForQuest(questID) return byQuest[tonumber(questID) or -1] end
function W:All() return byWrit end
