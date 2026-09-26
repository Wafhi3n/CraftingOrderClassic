# Crafting & Gathering Order — Classic — CurseForge description

> Source of truth for the CurseForge page. Copy it onto the addon page on each notable update.
> (Not packaged; see `.pkgmeta` ignore.)

---

Classic gives you no way to find out who can craft what. You can't inspect a stranger and see they're
a Jewelcrafter, there's no realm-wide list of professions, and the game forgets a friend's skills the
second they log off. So you spam /trade and hope someone answers.

Crafting & Gathering Order fills that hole. Every profession, skill level and recipe you know travels
with you over a hidden realm channel, and everyone else running the addon does the same. Look someone
up in the Artisans directory and you see what they can actually make, their skill level, whether
they're online, and how you know them, then order straight from them, whether it's a guildmate or a
stranger you've never spoken to.

It's also a work-order board for crafting and gathering. No shared guild, no auction house, no server.
Post what you want made or gathered and everyone on your realm running the addon sees it and can
answer, even people you've never met, as long as they've got the addon too.

## What it does

- See what anyone running the addon can craft, their skill level and their recipe list, in the Artisans directory. The game never shows you this; the addon carries it for you.
- Share your own professions, skills and known recipes the same way, automatically. No setup, no signup; playing is enough.
- Post craft and gather orders from the addon window, or straight from chat with `/co post`.
- Send an order to everyone, your guild, your friends, or one named player. A named order gets pushed to that person the moment they log in.
- Get a toast, a chat line and a sound when an order is meant for you. `/co notify` sets how much of that you want.
- Pick a crafter and the recipe list narrows to what they can actually make, so you never send someone a request they can't fill.
- Filter recipes down to what you can make right now with the reagents already in your bags.
- Order from your friends and guildmates without opening the board.
- See recipe cooldowns on other artisans, so you know whether their Transmute is ready or still ticking.
- Group your alts under one identity, so an order for your offline alchemist reaches whatever character you're playing.
- Check every profession on your whole account at once in the My Artisans tab.
- Enchant someone else's gear over the trade window. Click a slot to ask them for the piece, and Blizzard's recipe list narrows to what fits it (new in 1.35).
- Keep the board clean: mute a spammer (with a reason, or just for an hour), or trust a busy friend so they're never auto-muted.
- Recipes sorted into real categories instead of one flat "Consumable" pile, everywhere they show up.
- Orders carry what the goods sell for against what the reagents cost, so you can judge a commission before taking it.
- The Missing view lists the plans you haven't learned and says where each one comes from, the trainer or the vendor on your faction, with coordinates you can click.
- The window uses the game's own frame style, not a custom skin, so it reads as part of the interface.
- Click the bag icon on any artisan in the directory to see exactly what materials they need to keep leveling, worked out locally from what the addon already knows about them.
- Get a heads-up when you're running an old version, read off the versions other players around you are on, with a dot on the minimap that clears once you update (new in 1.27).
- Follow the orders you've accepted on screen, like tracked quests, with every reagent counted against your bags (new in 1.29).
- Give an order a title and a story, so it reads like a quest to whoever picks it up (new in 1.29).
- Read your orders and your real quests in one parchment journal with `/co journal` (new in 1.29).
- Cooking, First Aid and Fishing count as professions in the directory, so you can look them up and order from them like anything else (new in 1.30).
- Turn a WoW community into a crafting circle with `/co circle`, and its members show up in the Artisans directory with their presence, including the ones who are offline (new in 1.31).
- Built for WoW: Forever, the 1.60.1 client. Era, Season of Discovery and Hardcore stay on 1.30.0, the last build that shipped for them.

## Order straight from a name, friend or stranger

Mouse over any addon user in the world, a guildmate or a complete stranger you just ran past, and their
professions and skill levels show up under the game's own tooltip. Hold Shift and it lists their recipes
by name. Right-click them and you get an Order entry for each profession they craft, each one opening the
Order tab already set to it, so you can order from someone you've never spoken to without adding them to
anything first.

The Friends list and Guild panel get the same treatment as built-in shortcuts. Hover a friend and the
summary sits next to their tooltip, Battle.net friends included, not just friends added by character
name. Click a guildmate and it sits under their detail with an Order button right there, so it works even
when they're offline.

The directory fills itself in as you cross paths with other users. When it's looking empty, the Refresh
button calls out on the channel and everyone online answers.

## Sending an order where it belongs

Post to the whole realm, or keep it to your guild, your friends, or a single player. A realm-wide order
goes out over the shared channel, not just to people you've already crossed paths with, so it reaches
strangers running the addon too. Cancel it and the cancellation travels the same way, so it doesn't sit
open on a stranger's board for hours. You'll only get a toast for professions you actually have, so
someone else's Blacksmithing order won't ping your Enchanter. Scoped orders only reach people who qualify.
Open ones re-broadcast every couple of hours and expire on their own, so the board doesn't rot with dead
requests. Only the player who posted an order can put it on the realm channel under their name, so nobody
can post in your name.

Gather orders handle stacks properly. Ask by the unit or by the stack, and you always see the real
total, so it reads *3 stacks (60)* instead of a cryptic *3 st*.

## Delivery that counts

An order isn't done the second a crafter clicks Deliver. It goes to Delivered, and the buyer confirms
they got it, either automatically when the item lands in their bags or with a Received button. A
crafter's delivered-count only ticks up on that confirmation, so it tracks goods that actually changed
hands rather than clicks.

## On screen, and in a journal

The orders you've accepted sit on your screen the way tracked quests do. Under each one, every reagent
with what you've got against what you need, counted from your bags as you loot. When the last one lands
the order climbs to the top under Ready to deliver. It also names the cheapest recipe for your next
skill point in each profession you're still levelling, and where to buy the plan if the cheapest route
goes through one you don't own. Drag any line to move it, `/co track` to switch it off.

Orders can carry a title and a few lines of your own writing. Post as quest opens a parchment sheet
where you write them, and the crafters who see the order read your title instead of the item name, with
your text underneath. `/co journal` then puts your orders and your real quests in one parchment window,
grouped by section and by zone. It reads the game's quest log without writing to it, so your own quest
window keeps whatever you had selected.

## Hand off from the trade and mail windows

Open a trade or start a letter and a small panel shows the orders between you and that player. In the
mail composer, Fill from order sets the recipient, subject, body and cash-on-delivery, and attaches the
crafted item from your bags. You still read it over and hit Send yourself. At the trade window each side
sees their half: the crafter what to collect, the buyer what to pay and a button to confirm. The panel
sticks around after the trade closes so whoever's left can finish up.

## Shared recipe cooldowns

Cast a Transmute and everyone running the addon sees it on your artisan tooltip, either "Transmute:
ready" or "Transmute: in 14h". No more asking around the realm to find out whose Arcanite transmute is
up. It reads your own cooldowns straight from the game and shares them the way it already shares your
skill levels; a small built-in table knows which recipes actually sit on a timer.

## One player, all your characters

Turn on `/co alts` (or tick the box in the My Artisans tab) and pick a main. Your characters get linked
as one player, checked from both ends so nobody can pass themselves off as someone else's alt. Someone
orders from your alchemist while you're on your warrior, and the order still finds you, with a note that
it's for your alt. You can accept it from whichever character you're on, and the delivery follows once
you hop over.

The My Artisans tab gathers every profession on your account for the realm into one place, as if a
single character knew them all. Skill levels, known recipes grouped by category the way the profession
window does it, active cooldowns pinned at the top, and which of your characters holds each recipe.

Right-click a profession in My Artisans and pick one of your characters for a read-only look at that
alt: recipes it knows, the reagents each one needs, and its skill level. No craft button, since you're not logged in as that character, and
no bag counts, just what's needed.

## Partners, loot alerts and gifts

Loot a recipe, formula, schematic or pattern and the addon tells you what it teaches, whether you
already know it, and which of your partners don't. Mark someone a partner with a right-click, then offer
them a spare plan with `/co gift`. It drafts a friendly whisper; it never sends on its own.

## Catching requests from non-users

When someone without the addon posts a request in `/trade` or `/guild`, it lands in an Incoming tab in
the profession window so it doesn't slip past you, but only when you actually know the recipe, so a cut
you can't do won't ping you. Accept it, then reply to them in chat yourself. These captured requests
clear themselves after half an hour, the way a shout in /trade really works, so yesterday's leftovers
don't sit on your board pretending someone's still waiting. Sales (WTS) and crafters advertising their
services (LFW) get filtered out. `/co scan` turns the scanner on and off.

## Keeping the board clean

Mute anyone whose orders you'd rather not see: `/co mute <name>`, optionally with a reason and a
duration, so `/co mute Bob 1h spammer` mutes Bob for an hour and then forgets about it on its own. `/co
mute` on its own lists who you've muted, why, and how long is left. There's also automatic help — the
addon watches for the same player flooding orders and offers to mute them (or does it for you, your
call), and it can ignore very-low-level posters that look like bots. Someone legitimate who just posts a
lot? `/co trust <name>` and they're never auto-muted. It's all yours alone; muting never touches anyone
else's game.

## The profession window

Forever's own profession window is the modern one, with search, categories and a real detail panel,
so the addon doesn't replace it. It adds a column inside it. That column holds the live orders for
the profession you're looking at, a route for levelling it at the lowest cost per point, and the
plans you're still missing with a line on where each comes from.

The recipe list is sorted the way you'd actually look for things. Vanilla dumps every potion you know
under one "Consumable" heading in no particular order; here they're split into healing potions, mana
potions, elixirs of strength, flasks, transmutes and so on, each run from the highest rank down. A
potion that restores both health and mana sits under both headings. The same grouping carries over to
the Order tab, the My Artisans tab, and the gathering professions, where ores, herbs, leathers and fish
get the same treatment.

Prices come from Auctionator's last auction house scan, so an incoming order tells you what the goods
sell for against what the reagents you'd supply would cost, and you can see whether the commission is
worth taking. Without Auctionator the addon says it doesn't know, instead of showing you a zero that
would read as "this earns nothing".

In the Artisans directory each profession shows as its icon rather than its name. A crafter sitting on a
genuinely profitable plan gets a gold border on that profession, and hovering it names the plan and the
gold. Click the icon and you land in the Order tab aimed at that crafter and that profession, their
recipe list already narrowed to what they can make. My Artisans works the same way for your own
characters and adds an "All realm crafts" view that merges every profession on the account into one
profit-ranked list, so a glance tells you which alt is sitting on money. Cooking and Fishing are in
there too, along with the essences, dusts and shards an enchanter pulls from disenchanting.

The Missing view lists the plans you haven't learned yet, with a line on where each one comes from:
the trainer who teaches it, the vendor who sells it and what they charge, or the creature it drops
from. It only ever points you at NPCs your own faction can talk to, and when the only one we know
about is on the other side, it says so rather than walking you into their capital. Click a line and
it drops a waypoint.

## Enchanting over the trade window

Someone hands you a piece to enchant. They have to drop it in the slot at the bottom of the trade
window, the one that isn't traded, which plenty of people have never noticed, and then you go hunting
through your enchants for the right one.

Open a trade with Enchanting up and the addon's column switches to the trade. You get your partner,
the piece they put down, and what their reagents point to. Click a slot on the silhouette and they're
asked for that piece, by whisper and, if they run the addon, by a prompt they can click to place it.
Blizzard's recipe list narrows to that slot at the same time, exactly as if you'd ticked the box
yourself, and once something is on the table the list follows the item rather than what you asked
for. End the trade and your own filters come back, including one you'd set before.

If they put reagents down too, the column names the enchant those reagents point to. It reads what
they place, never what's in your bags, and it stays quiet when their pile fits more than one. You
craft with Blizzard's own button, and you pick their piece as the target.

If the trade opens while Enchanting is closed, the trade window grows a tab on its right edge that
opens it.

## Which client this is for

This build is for WoW: Forever, the 1.60.1 client, and it's the only one it loads on. Era, Season of
Discovery and Hardcore stopped at 1.30.0, which stays available and still carries the 304 seasonal
recipes for SoD realms.

## Crafting circles (WoW communities)

The realm channel has no memory and no member list. Someone who wasn't logged in when you posted
never saw it, and every session starts by working out again who's around.

If your realm has WoW communities, you can point the addon at one. Mark it with `/co circle` and its
members appear under a Circle bucket in the Artisans tab, with their presence, including the ones who
are offline right now. You create the community and you invite who you want, which is rather the
point: a circle is a small group you picked, not the whole realm.

Nothing is posted to the community and nothing is read out of it. Orders and skill levels keep
travelling the way they always have; the circle only tells the addon who belongs to it and who's
around.

## Confederations (GreenWall)

If you run GreenWall for a cross-guild confederation, the Artisans directory grows a Confederation
section listing addon users from your sister guilds, picked up passively from the guild-chat bridge with
no extra traffic. `/co gwroster` shows what it found.

## Bilingual and standalone

English, French, German and Spanish are all built in, and item and recipe names come out in your client's
language. The addon stands on its own (it embeds the shared CraftLink library) and runs happily next to
Guild Economy.

## Commands

`/co help` lists them all. The ones you'll reach for: `/co` opens the board, `/co prof <profession>`
opens that profession's window, `/co notify` sets notifications, `/co scan` toggles the chat scanner, `/co gift`
offers a looted plan to a partner, `/co refresh` re-polls the directory, `/co alts` groups your
characters (off by default), `/co mute` and `/co trust` handle noisy or trusted players.

Made for fresh realms and guild-economy challenges, and for servers where the auction house isn't the
answer.
