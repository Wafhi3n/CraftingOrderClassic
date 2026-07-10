-- CraftingOrderClassic_Locale_News_enUS.lua — traductions de l'onglet « Nouveautés » (enUS/enGB).
-- Extrait de _Locale_enUS.lua : l'onglet Nouveautés grossit à chaque release et faisait déborder le
-- plafond anti-monolithe. Isolé ici, il a de la marge (fenêtre glissante côté UI_News). Même contrat :
-- clé FR → texte EN, chargé APRÈS _Locale.lua, early-return hors locale.

local COC = CraftingOrderClassic
local loc = GetLocale and GetLocale() or "enUS"
if loc ~= "enUS" and loc ~= "enGB" then return end
local L = COC.L

local news = {
    -- Onglet Nouveautés (changelog en jeu)
    ["Nouveautés"] = "What's New",
    -- v1.15.0
    ["Recherche de travail : signale que tu es dispo"] = "Looking for work: flag yourself as available",
    ["Ouvre un métier et clique « Chercher du travail » : tout le royaume sait que tu es dispo, une icône d'artisan s'affiche au-dessus de ta tête pour ceux qui passent, et tu apparais « [Dispo] » dans leur annuaire. Ça s'éteint tout seul au bout d'un moment si tu oublies."] =
        "Open a profession and click \"Look for work\": the whole realm knows you're available, an artisan icon shows over your head for anyone passing by, and you appear as \"[LFW]\" in their directory. It lapses on its own after a while if you forget.",
    ["Au passage : les deux fenêtres ne s'emmêlent plus (un clic la ramène au premier plan), l'annuaire a un bouton partenaire et se limite à ta faction (pas d'échange cross-faction sur Classic), et un artisan ne s'affiche plus avec un métier qui n'est pas le sien."] =
        "Along the way: the two windows no longer tangle (a click brings one to the front), the directory has a partner button and sticks to your faction (no cross-faction trading on Classic), and an artisan no longer shows a profession that isn't theirs.",
    ["Repérer les crafteurs sans l'addon + passe de performance"] = "Spot crafters without the addon + a performance pass",
    ["Repérage passif des crafteurs autour de toi, même sans l'addon (onglet Artisans → « Repérer les crafteurs autour », ou |cFFFFFFFF/co crafters on|r). Désactivé par défaut, en ville seulement."] =
        "Passive detection of crafters around you, even without the addon (Artisans tab, or |cFFFFFFFF/co crafters on|r). Off by default, towns only.",
    ["Liste de plans de l'onglet Commande réécrite : plus fluide sur les métiers à centaines de recettes (Couture)."] =
        "The Order tab's plan list was rewritten: smoother on professions with hundreds of recipes (Tailoring).",
    ["La fenêtre ne se redessine plus à chaque message réseau : les rafales sont regroupées en un seul rendu."] =
        "The window no longer redraws on every network message: bursts are batched into a single redraw.",
    ["Protocole de commande durci : un autre client ne peut plus annuler ta commande, usurper une acceptation, ni s'attribuer une livraison."] =
        "Hardened order protocol: another client can no longer cancel your order, fake an acceptance, or claim a delivery.",
    ["Commander depuis les panneaux Amis & Guilde"] = "Order from the Friends & Guild panels",
    ["Greffons échange & courrier, dock en vue Blizzard"] = "Trade & mail companions, Blizzard-view dock",
    ["Panneaux compagnons sur la fenêtre d'échange et de courrier pour livrer une commande sans ouvrir le carnet."] =
        "Companion panels on the trade and mail windows to deliver an order without opening the board.",
    ["La colonne Commandes peut s'ancrer à droite de la fenêtre métier native (vue Blizzard)."] =
        "The Orders column can dock to the right of the native profession window (Blizzard view).",
    ["Sous le capot : mises à jour plus sûres"] = "Under the hood: safer upgrades",
    ["Tes données sauvegardées portent désormais une version : une mise à jour qui doit les réorganiser ne tourne qu'une fois, tes recettes et commandes restent intactes."] =
        "Your saved data now carries a version, so an upgrade that needs to reshape it runs once and your recipes and orders stay intact.",
    ["Protocole de commandes consolidé (mêmes échanges réseau) : ce build reste compatible avec les joueurs encore en 1.7.x."] =
        "The order protocol was consolidated (same network exchanges); this build still talks to players still on 1.7.x.",
    -- (clés v1.7.0/v1.7.1 retirées : ces versions ne sont plus listées dans l'onglet Nouveautés)
    ["Allemand et espagnol + onglet Nouveautés"] = "German and Spanish + a What's New tab",
    ["L'interface se traduit en allemand et en espagnol selon la langue de ton client WoW."] =
        "The interface is translated into German and Spanish depending on your WoW client language.",
    ["Ce nouvel onglet « Nouveautés » affiche les notes de version directement en jeu."] =
        "This new What's New tab shows the release notes right in the game.",
    -- Onglet Nouveautés — v1.13.0
    ["Modération : mutes avec raison, temporaires, liste de confiance"] = "Moderation: mutes with a reason, temporary mutes, a trust list",
    ["Un mute porte désormais une raison et une date, et peut être temporaire : |cFFFFFFFF/co mute Bob 1h spammeur|r se lève tout seul au bout d'une heure (|cFFFFFFFF/co mute|r seul liste les mutés avec raison et temps restant). Et |cFFFFFFFF/co trust <nom>|r marque un joueur de confiance, jamais mis en sourdine automatiquement — le mute manuel restant toujours possible."] =
        "A mute now carries a reason and a date, and can be temporary: |cFFFFFFFF/co mute Bob 1h spammer|r lifts itself after an hour (|cFFFFFFFF/co mute|r alone lists muted players with reason and time left). And |cFFFFFFFF/co trust <name>|r marks a player as trusted, never auto-muted — manual muting still available.",
    -- Onglet Nouveautés — v1.12.1
    ["Personne ne peut poster une commande en ton nom"] = "Nobody can post an order in your name",
    ["Une commande arrivant par le canal du royaume était crue sur parole quant à son acheteur : un joueur pouvait publier de fausses commandes au nom d'autrui, et nourrir la détection de spam contre sa victime jusqu'à ce que tout le monde la mette en sourdine. Elles doivent désormais venir du joueur qui les a postées."] =
        "An order arriving on the realm channel was trusted to name its own buyer: one player could publish fake orders under someone else's name, and feed the spam detector against that person until everyone muted them. Such orders must now come from the player who posted them.",
    ["|cFFFFFFFF/co channel off|r quitte maintenant vraiment le canal. Il se contentait d'empêcher de le rejoindre au login suivant : tes commandes continuaient de partir au royaume pendant toute la session."] =
        "|cFFFFFFFF/co channel off|r now really leaves the channel. It used to only stop rejoining at the next login: your orders kept going out to the realm for the rest of the session.",
    -- Onglet Nouveautés — v1.12.0
    ["Les recettes de la Saison de la Découverte"] = "Season of Discovery recipes",
    ["304 recettes de la Saison de la Découverte entrent au catalogue : 80 en Travail du cuir, 65 en Forge, 57 en Couture, 48 en Enchantement, 29 en Ingénierie, 16 en Alchimie, plus la Cuisine, le Secourisme et le Minage. Elles apparaissent dans l'onglet Commande, avec leurs réactifs et leur palier d'apprentissage."] =
        "304 Season of Discovery recipes join the catalogue: 80 for Leatherworking, 65 for Blacksmithing, 57 for Tailoring, 48 for Enchanting, 29 for Engineering, 16 for Alchemy, plus Cooking, First Aid and Mining. They show up in the Order tab, with their reagents and skill levels.",
    ["Elles ne se chargent que sur un royaume Saison de la Découverte. Sur un royaume Era classique, rien ne change : l'addon voit exactement le même jeu de recettes qu'avant, et les recettes que tes amis t'ont déjà partagées restent lisibles."] =
        "They load only on a Season of Discovery realm. On a regular Era realm nothing changes: the addon sees exactly the recipe set it saw before, and the recipes your friends already shared with you stay readable.",
    -- Onglet Nouveautés — v1.11.0
    ["Annuler une commande publique atteint tout le royaume"] = "Cancelling a public order now reaches the whole realm",
    ["Une commande publique voyage sur le canal du royaume depuis la v1.10.0, mais pas son annulation : un artisan que tu n'as jamais croisé la voyait « ouverte » pendant six heures, l'acceptait, et farmait les réactifs pour rien. L'annulation part désormais sur le même canal."] =
        "A public order has travelled the realm channel since v1.10.0, but its cancellation did not. A crafter you have never met kept seeing it as open for up to six hours, could accept it, and gathered the reagents for nothing. Cancelling now goes out on the same channel.",
    ["Poster et annuler ne perdent plus de messages. Le canal exige un clic ou une touche et n'accepte qu'une ligne par seconde : un |cFFFFFFFF/co post|r tapé au chat, ou deux commandes postées dans la même seconde, disparaissaient sans trace. Ces lignes patientent maintenant dans une file et partent à ton prochain clic."] =
        "Posting and cancelling no longer lose messages. The channel needs a click or a keypress to carry a line, and takes one line per second: a |cFFFFFFFF/co post|r typed in chat, or two orders posted in the same second, used to vanish without a trace. Those lines now wait in a queue and go out on your next click.",
    ["Seules les commandes NOUVELLES et les ANNULATIONS voyagent sur le canal, et seulement les publiques. Guilde, amis et commandes nommées restent privées ; les acceptations restent entre les deux joueurs concernés."] =
        "Only new orders and cancellations ever travel the channel, and only public ones. Guild, friends and named orders stay private; acceptances stay between the two players involved.",
    -- Onglet Nouveautés — v1.10.2
    ["Correctif : erreur en combat dans la vue métier"] = "Fix: an in-combat error in the profession view",
    ["Sélectionner une recette pendant un combat ne provoque plus d'erreur bloquée : le bouton « Créer » est un bouton sécurisé, que le jeu interdit de masquer en plein combat. L'addon attend maintenant la fin du combat pour l'afficher ou le masquer."] =
        "Picking a recipe during combat no longer throws a blocked-action error. The Create button is a secure button, and the game forbids hiding one mid-combat. The addon now waits until combat ends to show or hide it.",
    -- Onglet Nouveautés — v1.10.1
    ["Corrections : qui reçoit les alertes de commandes"] = "Fixes to who gets notified",
    ["Les alertes de commandes ne dépendent plus du réglage |cFFFFFFFF/co scan|r : le scanner de chat et le carnet partageaient une option par erreur. Une commande publique te prévient désormais dès que tu as le métier."] =
        "Order alerts no longer depend on your |cFFFFFFFF/co scan|r setting. The chat scanner and the order book shared one option by accident. A public order now toasts you as soon as you have the profession for it.",
    ["Une commande publique portant un objet absent du catalogue arrivait en silence : elle te prévient maintenant, au lieu de dormir dans le carnet."] =
        "A public order carrying an item missing from the catalogue used to arrive silently. It notifies you now, instead of sitting unseen on the board.",
    ["Démuter un joueur réarme la détection de spam le concernant ; revenir de la vue métier d'un reroll ne laisse plus les boutons Créer masqués ; et l'addon travaille nettement moins à chaque ligne de chat sur un royaume chargé."] =
        "Unmuting a player re-arms spam detection for them; coming back from an alt's profession view no longer leaves the Create buttons hidden; and the addon does noticeably less work per chat line on a busy realm.",
    -- Onglet Nouveautés — v1.14.0
    ["Un panneau pour gérer les mis en sourdine"] = "A panel to manage who you've muted",
    ["L'onglet Artisans a maintenant une section « En sourdine » : chaque joueur muté y apparaît avec sa raison et le temps restant (ou « permanent »), avec un bouton pour le rétablir directement — plus besoin de deviner qui est encore muté."] =
        "The Artisans tab now has a Muted section: every muted player shows up with their reason and time left (or \"permanent\"), with a button to unmute them right there — no more guessing who's still muted.",
    -- Onglet Nouveautés — v1.9.0
    ["Tes rerolls réunis : cooldowns partagés, une identité, l'onglet Mes artisans"] =
        "Your alts, together: shared cooldowns, one identity, a My Artisans tab",
    ["Cooldowns de recettes partagés : les autres voient « Transmutation : prête » ou « dans 14h » sur ton infobulle d'artisan — fini de demander en canal si ton Arcanite est dispo."] =
        "Shared recipe cooldowns: others see \"Transmute: ready\" or \"in 14h\" on your artisan tooltip — no more asking in chat whether your Arcanite is up.",
    ["Regroupe tes persos sous une identité (|cFFFFFFFF/co alts on|r) : une commande nommée pour ton alchimiste hors ligne arrive sur le perso où tu es connecté, et tu peux l'accepter depuis n'importe lequel. Vérifié des deux côtés (personne ne peut se faire passer pour le reroll d'autrui). Désactivé par défaut."] =
        "Group your characters under one identity (|cFFFFFFFF/co alts on|r): an order named for your offline alchemist reaches whichever character you're on, and you can accept it from any of them. Verified both ways (nobody can pose as someone else's alt). Off by default.",
    ["Nouvel onglet « Mes artisans » : tous les métiers de ton compte sur le royaume en une vue, comme un seul perso — niveau, recettes connues par catégorie, cooldowns en tête, et quel perso porte chaque recette."] =
        "New \"My Artisans\" tab: all your account's professions on the realm in one view, as a single character — level, known recipes by category, cooldowns at the top, and which character carries each recipe.",
    ["VU"] = "SEEN",
    ["vu crafter (sans l'addon)"] = "seen crafting (no addon)",
    ["vu crafter"] = "seen crafting",
    ["%d+ · vu crafter"] = "%d+ · seen crafting",
    -- Cooldowns de recettes (transmutations & co)
    ["%s : prête"] = "%s: ready",
    ["%s : dans %s"] = "%s: in %s",
    ["(estimé)"] = "(estimated)",
    ["Transmutation"] = "Transmute",
    ["%dj"] = "%dd", ["%dh"] = "%dh", ["%dmin"] = "%dmin",
    -- Relais partenaire (fiche d'un artisan hors ligne servie par un contact de confiance)
    ["via %s · il y a %s"] = "via %s · %s ago",
    ["RELAIS"] = "RELAYED",
    -- Rerolls (identité joueur multi-persos, /co alts — opt-in)
    ["rerolls : ACTIVÉS — ta liste de persos est annoncée au réseau."] =
        "alts: ENABLED — your character list is announced to the network.",
    ["rerolls : désactivés — rien n'est annoncé (opt-in : /co alts on)."] =
        "alts: disabled — nothing is announced (opt-in: /co alts on).",
    ["perso principal (vitrine) : %s"] = "main character (front): %s",
    ["persos du compte (%s) : %s"] = "account characters (%s): %s",
    ["le lien n'est vérifié chez les autres qu'après une connexion de CHAQUE perso (addon actif)."] =
        "others only verify the link after EACH character has logged in once (addon running).",
    ["rerolls activés — perso principal : %s (changer : /co alts main <nom>)"] =
        "alts enabled — main character: %s (change: /co alts main <name>)",
    ["rerolls désactivés — dissolution annoncée au réseau."] =
        "alts disabled — dissolution announced to the network.",
    ["perso inconnu sur ce compte : %s (connecte-le une fois avec l'addon)"] =
        "unknown character on this account: %s (log it in once with the addon)",
    ["regrouper tes rerolls (opt-in) : liste annoncée, commandes routées vers ton perso connecté"] =
        "group your alts (opt-in): list announced, orders routed to your online character",
    ["commande nommée pour %s : connecte ce perso, ou active /co alts on pour accepter d'ici."] =
        "order named for %s: log that character in, or enable /co alts on to accept from here.",
    ["|cFFFFCC00commande pour ton reroll %s|r de |cFFFFFFFF%s|r : %s%s%s"] =
        "|cFFFFCC00order for your alt %s|r from |cFFFFFFFF%s|r: %s%s%s",
    ["En ligne via %s"] = "Online via %s",
    ["reroll : %s (%s)"] = "alt: %s (%s)",
}

for k, v in pairs(news) do L[k] = v end
