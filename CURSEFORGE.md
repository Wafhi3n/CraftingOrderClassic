# Crafting & Gathering Order — Classic — CurseForge description

> Source of truth for the CurseForge page. Copy it onto the addon page on each notable update.
> (Not packaged; see `.pkgmeta` ignore.)

---

Crafting & Gathering Order is a work-order board for WoW Classic, for both crafting and gathering. No
shared guild, no auction house, no server. You post what you want made or gathered, and everyone
running the addon on your realm can see it and answer. It talks over a hidden realm channel, so it works
between total strangers as long as they've got the addon too.

## What it does

- Post craft and gather orders from a tavern-styled window, or straight from chat with `/co post`.
- Send an order to everyone, your guild, your friends, or one named player. A named order gets pushed to that person the moment they log in.
- Get a toast, a chat line and a sound when an order is meant for you. `/co notify` sets how much of that you want.
- Browse the Artisans directory: who can make what, who's online, their skill levels, and how you know them.
- Pick a crafter and the recipe list narrows to what they can actually make, so you never send someone a request they can't fill.
- Filter recipes down to what you can make right now with the reagents already in your bags.
- Order from your friends and guildmates without opening the board (new in 1.4).

## Order from your Friends and Guild list

Hover a friend in the Friends list and their professions and skill levels show up next to the game's own
tooltip. Battle.net friends count too, not just friends added by character name. Click a guildmate in the
Guild panel and the same summary sits under their detail, with an Order button right there, so it works
even when they're offline.

Right-click anyone who runs the addon, a friend, an online guildmate, or someone you bumped into in the
world, and you get an Order entry for each profession they craft, each one opening the Order tab already
set to it. Their summary also shows how many recipes they know, and holding Shift over their in-world
tooltip lists those recipes by name.

The directory fills itself in as you cross paths with other users. When it's looking empty, the Refresh
button calls out on the channel and everyone online answers.

## Sending an order where it belongs

Broadcast to the whole realm, or keep it to your guild, your friends, or a single player. Scoped orders
only reach people who qualify. Open ones re-broadcast every couple of hours and expire on their own, so
the board doesn't rot with dead requests.

Gather orders handle stacks properly. Ask by the unit or by the stack, and you always see the real
total, so it reads *3 stacks (60)* instead of a cryptic *3 st*.

## Delivery that counts

An order isn't done the second a crafter clicks Deliver. It goes to Delivered, and the buyer confirms
they got it, either automatically when the item lands in their bags or with a Received button. A
crafter's delivered-count only ticks up on that confirmation, so it tracks goods that actually changed
hands rather than clicks.

## Hand off from the trade and mail windows

Open a trade or start a letter and a small panel shows the orders between you and that player. In the
mail composer, Fill from order sets the recipient, subject, body and cash-on-delivery, and attaches the
crafted item from your bags. You still read it over and hit Send yourself. At the trade window each side
sees their half: the crafter what to collect, the buyer what to pay and a button to confirm. The panel
sticks around after the trade closes so whoever's left can finish up.

## Partners, loot alerts and gifts

Loot a recipe, formula, schematic or pattern and the addon tells you what it teaches, whether you
already know it, and which of your partners don't. Mark someone a partner with a right-click, then offer
them a spare plan with `/co gift`. It drafts a friendly whisper; it never sends on its own.

## Catching requests from non-users

When someone without the addon posts a request in `/trade` or `/guild`, it lands in an Incoming queue so
it doesn't slip past you. Accept it, then reply to them in chat yourself. Sales (WTS) and crafters
advertising their services (LFW) get filtered out. `/co scan` turns the scanner on and off.

## The profession window (optional)

There's an optional three-column profession window: a searchable, difficulty-colored recipe list,
reagents with have/need counts and Create / Create All, and the live orders for that profession right
alongside. One click swaps to the Blizzard window and back. Enchanting works too, which takes a little
doing in Classic since its craft function is protected.

## Confederations (GreenWall)

If you run GreenWall for a cross-guild confederation, the Artisans directory grows a Confederation
section listing addon users from your sister guilds, picked up passively from the guild-chat bridge with
no extra traffic. `/co gwroster` shows what it found.

## Bilingual and standalone

English, French, German and Spanish are all built in, and item and recipe names come out in your client's
language. The addon stands on its own (it embeds the shared CraftLink library) and runs happily next to
Guild Economy.

## Commands

`/co help` lists them all. The ones you'll reach for: `/co` opens the board, `/co profwindow` toggles the
custom profession window, `/co notify` sets notifications, `/co scan` toggles the chat scanner, `/co gift`
offers a looted plan to a partner, `/co refresh` re-polls the directory.

Made with Season of Discovery and Fresh realms in mind, guild-economy challenges, and servers where the
auction house isn't the answer.
