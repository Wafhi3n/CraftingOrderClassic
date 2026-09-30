-- CraftingOrderClassic_Notify.lua — la SORTIE d'une alerte : ligne de chat, bandeau, son.
--
-- Pourquoi (2026-09-30, demande d'un joueur relayée par le user) : chaque alerte (commande reçue,
-- demande lue dans le chat, commande remise, refusée…) écrivait sa ligne, posait son bandeau et
-- jouait son son elle-même, sans rien à régler. Les cases « Façon de prévenir » de l'onglet Artisans
-- (COC.Channels : notif_way_chat, notif_way_toast, notif_way_sound) choisissent ici ce qui sort,
-- pour toutes les alertes à la fois. QUELLES alertes sortent, lui, reste à l'appelant (les autres
-- cases du groupe NOTIFICATIONS).

local COC = CraftingOrderClassic
local N = {}
COC.Notify = N

local PREFIX = "|cFF33DD88Crafting Order|r "
local ALL = { chat = true, toast = true, sound = true }

-- Les trois façons, en TABLE (un multi-retour se tronque derrière un `and`).
function N.Ways()
    local Ch = COC.Channels
    if not Ch then return ALL end
    return { chat = Ch.IsWatched("notif_way_chat"), toast = Ch.IsWatched("notif_way_toast"),
             sound = Ch.IsWatched("notif_way_sound") }
end

-- a.chat  = la ligne du chat, sans le préfixe « Crafting Order » ; a.more = une ligne de plus, dessous.
-- a.toast = le texte du bandeau (défaut : a.chat ; false = pas de bandeau) ; a.icon = son icône.
-- a.sound = true pour jouer le son des messages privés.
function N.Emit(a)
    local w = N.Ways()
    if w.chat and a.chat then
        print(PREFIX .. a.chat)
        if a.more then print(a.more) end
    end
    local toast = a.toast == nil and a.chat or a.toast
    if w.toast and toast and COC.UI and COC.UI.Toast then COC.UI:Toast(toast, a.icon) end
    if w.sound and a.sound then
        pcall(function() PlaySound(SOUNDKIT and SOUNDKIT.TELL_MESSAGE or 3081, "Master") end)
    end
end
