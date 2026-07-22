# Changelog — Crafting & Gathering Order — Classic

## v1.27.0 — Tells you when a new version is out

The addon now notices when you're running behind. It reads the version off other players you cross
paths with on the network, and once it's seen a newer one from a few different people, it drops a
single line in chat and puts a red dot on the minimap button. The dot clears itself once you update.

That "few different people" part is on purpose. One player can't spoof you into thinking you're behind
by broadcasting a fake number, it takes separate players to corroborate it. And it only tells you once
per new version, not every login.

`/co version` shows what you're on and whether there's something newer.

## v1.26.0 — Filter any craft list by the stat it gives

Every recipe list, the Order tab, the profession window and My Artisans, gets a stat picker. Pick
Strength and you see only what gives Strength, gems, gear, elixirs, all of it. The list is built from
what the open profession actually makes, so Cooking won't offer you Spell Power and Jewelcrafting
won't offer you Defense.

None of those stats are typed out anywhere. They're read off your own client, so they show up in your
language and they'll keep working on items I've never looked at, including whatever Wrath brings. The
filter matches on the stat's real identity, not its name, so it behaves the same whether your game is
in English, French or German.

Alchemy sorts better too. Elixirs now group under the stat they give (Agility, Strength, Spell
Power), while healing and mana potions, flasks and transmutes keep their own headings, since "restores
health" was never a stat to begin with. On TBC that pulled 74 loose consumables out of the Misc pile.

An elixir that grants two stats only shows under one of them for now. If you spot one filed under the
wrong stat, tell me.

## v1.25.0 — Cut gems sort by color, then by what they give

Jewelcrafting dumped every cut gem under a single "Gem" heading. Hundreds of lines, no order to them.
Gems now sit under their socket color, and under that, under the stat they give, so you get
"Strength - Bold", "Stamina - Solid", "Healing / Spell Damage - Teardrop".

That stat isn't a list I typed out. It's read off your own client, which is why it shows up in your
language and why it'll keep working on gems I've never looked at. The cut name comes from the same
place, so a French client reads "Force - Audacieux" with no translation table anywhere.

Meta gems get a plain list instead. Every meta cut is a single gem, so a heading above each one just
repeated the line underneath it.

Rings, necklaces, statues and figurines keep sorting the way they always did.

Also fixed: when an enchanter asked you for a piece, the prompt sometimes never showed up. A first
request that arrived a moment too early, before you'd equipped the piece, still armed the five second
cooldown, so the real request that followed got swallowed. The cooldown now only starts once a
request has actually gone through.

## v1.24.2 — Enchant stat names read from your own client now

The subcategory names in the enchant view (Strength, Spirit, Crusader, and so on) were stuck in
English for everyone, French clients included: they came from an internal label the addon never
actually translated. They're now read straight from your game client, the same way spell names
already are, so they show up in your own language automatically, no translation table to keep in
sync as new enchants get added.

## v1.24.1 — Two more ores show up in gathering orders

Khorium and Eternium ore weren't showing up as orderable in the Gather tab. The mining list was built
from what's prospectable into gems, and neither one is, the same gap that used to hide Silver, Gold,
Truesilver and Dark Iron. Both join that list now.

## v1.24.0 — One click to hand your enchanter the right piece

The trade silhouette gets its second half. Since v1.21.0, an enchanter can click an equipment slot
in the empty trade panel and the addon whispers their partner to put that piece in the "will not be
traded" slot. If the partner runs the addon too, that same click now also shows them a prompt in
game: accept it and the equipped piece jumps into the safe slot by itself, unequipped and placed in
one go. Nothing changes hands, since that seventh slot can't be traded away, and the automation is
deliberately locked to it: it refuses to touch the six real trade slots, and it never moves anything
without that click on the prompt. No addon on the other side, or an older version? The whisper still
goes out exactly as before, so the request degrades to plain text.

The artisan pouch now recalculates while you watch. The window used to compute its shopping list
once, when opened, so a partner gaining skill points or learning a recipe mid-session kept showing
you yesterday's route. Skill and recipe broadcasts now repaint the open window within a second or
two, no reopening needed.

## v1.23.0 — A shopping list for what your guildmates need to level, plus two networking fixes

New feature: the Artisans tab gets a bag button next to each entry's profession icons. Click it and
a window lists exactly what materials that person needs to keep leveling their crafts, worked out
locally from the skill and recipe data they already broadcast, no new network traffic involved.
Reagents their own profession can make from something cheaper get broken down into base components
and credited against what the leveling route already produces, so nothing gets counted twice. Items
sold by a vendor get pulled into a plain note instead of cluttering the shopping grid.

Check "include recipes to buy" and plans behind a gold cost join the list too: purchasable plan items
as something to hand over, trainer plans as a note. The same supply block now shows up under the
existing "what to level next" route planner, with the vendor to visit (name, zone, coordinates) and a
clickable TomTom pin if you have it installed. A recipe with no priced reagent, Enchanting dust being
the usual offender, no longer knocks a whole stretch of the route out of the plan: it's now used as a
fallback when nothing better is available, marked with a "?" so the number reads as an estimate. A
curated disenchant table also backs the tooltip on any dust, essence or shard shown in these lists.

Two fixes: an account with more than one character sometimes saw itself listed as reachable "via"
its own alt in its own Artisans tab, the login relay from a partner was correctly relaying your
offline alt back to you, and the directory stored it as if it were someone else's contact. And the
"what to level next" route planner could stop short of a profession's real skill cap right after a
trainer promotion, because a Lua multi-assignment quietly dropped its second return value and kept
targeting the old tier.

## v1.22.1 — Order alerts that actually check what you can craft

A broad order (guild, friends, everyone) could toast a player who doesn't even have the profession,
as long as it arrived through the login relay (a whisper) instead of the channel. The channel
broadcast already filtered by profession; the relay didn't. Now the same check applies no matter
which path the order took. While in there, the toast text got a third variant: a broad order no
longer reads "order for YOU," since that's not true and read like a suggestion to craft it yourself.

The "what to level next" route planner could suggest a different recipe than the list's own cost
badge, because the two were reading slightly different data. The route now uses the profession
window's real difficulty at your current rank instead of projecting it from static thresholds, and
refreshes on the same clock as the badge so neither one goes stale. A new `/co lvldump` command
prints the numbers behind a disagreement, if you ever spot one again.

## v1.22.0 — Contextual help, unmissable dependencies, and an Escape key that behaves

New players kept missing the same handful of buttons, so profession windows now have a small "i"
button that opens the game's own contextual help widget, the one Blizzard uses for its own windows:
the background dims and a callout points straight at whatever's in question. Every tab (Profession
view, Order, Gather, Artisans, My Artisans, Ledger) has its own tour, so the button explains what's
actually on screen instead of a generic tooltip.

CraftingOrderClassic leans on two optional addons, Lazy Gold and MTSL, but there was no sign either
one was missing. The buttons that need them stay visible and colored whether or not you have the
addon installed, and clicking one without it now pops a short explanation of what it does and where
to get it, instead of doing nothing.

The "can craft that" alert for incoming trade requests fired even when you didn't actually know the
recipe, usually gems or enchants you had the reagents for but not the plan. It now checks your known
recipes before nagging you about your own orders. A friend who's online without the addon no longer
shows up as offline by mistake.

Escape used to leave profession windows open more often than not, and three separate bug reports
pointed at the same cause: hiding or disabling mouse input on a protected window mid-combat throws an
ADDON_ACTION_BLOCKED error. Windows now route through a small proxy frame instead, so Escape closes
them cleanly whether or not you're in combat.

One more: the "what to level next" helper now shows cost per skill point, an Auctioneer price badge,
and an icon pointing at the vendor who sells a recipe you don't know yet, on top of a slightly
smarter sort.

That leveling helper also gets a route planner now: click the map button and it walks your whole
climb rank by rank, picking the cheapest recipe at each step (learned or buyable, plans included) and
totaling the gold. Recipes with a cooldown or a reagent with no known price are left out on purpose,
they'd throw the total off. Needs Lazy Gold; MTSL adds trainer and vendor plan prices to the mix.

## v1.21.0 — Enchants by slot, and a trade panel that stops hiding things

Picking an enchant meant scrolling some 300 plans with near-identical names. The Order tab has a
character-silhouette view now: click the slot you want enchanted, get that slot's stats, pick a
variant. Toggle it from the filter bar. The plan list stays for everything that has no slot, like
oils, wands and disenchant products.

The trade enchant panel had a worse problem than bad sorting. It only ever drew 8 rows, and the
"+N more" line at the bottom wasn't clickable, so anything past the eighth entry was unreachable.
Someone handed an enchanter the reagents for Fiery Weapon and the panel never offered it: at skill
265 it sat below eight higher-rank variants and simply wasn't drawn. The list scrolls now, and it's
ordered by what you're being asked for. Enchants whose reagents your partner just put on the table
come first, then what your bags can already make, then everything else. Rows you can't craft yet stay
greyed out, including the suggested one, because the game's create button is genuinely disabled until
the trade goes through.

When nothing's in the "will not be traded" slot yet, the panel no longer just vanishes. It shows the
same silhouette with your trade partner's model in it, and clicking a slot whispers them to drop that
piece in. Most people who hand you gear have no idea that slot exists.

Two fixes while in there. Wrath's wrist and staff enchants never showed up in the trade panel, because
the game spells them "Bracers" and "Staff" where every other expansion says "Bracer". Staff enchants
only offer themselves on an actual staff now, not on any two-hander. And the panel no longer touches
its buttons while you're in combat, which the game blocks outright: trade windows stay open when a mob
jumps you, and the new scroll wheel made that easy to hit.

One quieter thing: "X can craft that captured order" chat lines are off by default. The order still
gets pushed to capable friends either way, so the message was noise. /co verbose brings it back.

## v1.20.0 — One-click enchants, sorted by slot, right from the trade window

The enchanting "Create" button had a long-standing intermittent bug: sometimes it just wouldn't fire,
and re-selecting the recipe a few times eventually got it working. Root cause found: selecting a recipe
doesn't actually arm Blizzard's native create button, so our secure click was landing on a disabled
button. Fixed by arming the recipe the same way the native window does. Should just work now, every time.

Enchant recipes were dumped in a single "Other/Misc" bucket in the recipe list, a wall of identical
"Enchant Bracer - ..." names. They're grouped by slot now (Wrist, Chest, Off-Hand...) and then by base
stat (Strength, Spirit, Deflection), with the name trimmed to just the stat since the slot's already in
the header. Grand Crusader, Superior Strength, that kind of naming spread across expansions all fold into
their base stat correctly, Season of Discovery included.

Selecting an equip-slot enchant now shows an "Enchant equipped" button next to Create: one click casts
the enchant on the item you're wearing in that slot, no manual targeting.

And when someone hands you gear to enchant over trade, dropping it in the "will not be traded" slot
now pops a small panel listing every enchant you know for that slot, ready to cast without hunting
through your profession window. That window still needs to be open, though: the game only reports your
known recipes while it's up, addon or not.

## v1.19.1 — Nameplate badge fix for the modern nameplate UI

The "looking for work" badge over a crafter's nameplate stopped refreshing on the TBC 2.5.6 client:
the new nameplate driver renamed the field the addon read to find the unit behind a plate, so the
badge never repainted when someone's status changed. Fixed. Era and Season of Discovery get the same
driver with patch 1.15.9, so this was heading their way too.

One thing that's still true on the new UI and won't change: friendly nameplates inside an instance
(dungeon, raid) are locked out for addons. No badge there, nothing we can do about it.

## v1.19.0 — Recipes in your offer, a share button, and LFW without the addon

Looking for work now lets you name exact recipes, not just reagents. Check off plans in the recipe
list and whoever's browsing your offer sees "offers: Iron Buckler, Copper Chain Vest" next to whatever
mats you're already listing.

Reagents get a "Share" button in the profession window, the order card, and the posting panel. Pick a
channel (guild, say, party/raid, a numbered channel) and it drops the reagent list with item links, a
shopping list in one click.

LFW works even without the addon: type "LFW enchanting" in Trade or General and you show up as
available, same nameplate icon and directory line as anyone running Crafting Order.

Fixed a MissingTradeSkillsList integration bug where a recipe you'd already learned could get listed
twice, once as learned and once as missing.

## v1.18.0 — Look for work, now with an offer, and sort by what levels you

"Look for work" used to just flag you as available. Now it carries an offer. Open a profession, click
the gear next to the button, and say what you're putting on the table: you'll bring the basic reagents,
you'll supply a specific component, a flat tip per craft, or you only want jobs that give you a skill
point. Whoever's browsing sees it on your line in the directory and in the tooltip over your head, with
a coin when there's a tip and a bag when you're providing mats.

The availability icon over a crafter's nameplate works on Era and Season of Discovery now, not only the
Burning Crusade client. Turn on friend nameplates and the profession icon floats over anyone near you
who's looking for work.

Recipes can sort by what still levels you. A third tool button lifts the plans that give a skill point
to the top of the list, orange down to grey, and orders get the same "levels me first" toggle with a
difficulty tint down the side of each line.

Plus a batch of smaller fixes across the profession window, orders, and gathering categories.

## v1.17.1 — Fixed a login error while looking for work

If you had "Look for work" turned on, connecting or reloading could throw a red error. The addon was
announcing your availability the instant the hidden channel came up — before the game lets an addon talk
on a channel — so the game blocked the call and your error display caught it. The announcement now waits
for your next click or keypress, the way the rest of the channel traffic already does. No more error, and
other players still see you're available.

## v1.17.0 — The window looks like WoW now

The addon window used to wear its own gold-and-wood skin. It now borrows the game's own frame instead:
the title bar, the round portrait, the tabs across the top, the buttons. It reads as part of the interface
rather than something bolted on top, and nothing moved that you'd have to relearn.

The profession window got the same treatment and a rebuilt orders column. Orders show as one line each
now, the requester, the item they want and the price, so a busy profession fits on screen. Click a line
and its full card fills the column, with the components they've supplied, what the reagents would cost you,
and Accept / Decline / Whisper. The close button at the top takes you back to the list. The middle and
right columns picked up proper footers, and the whole layout is driven by one description you can nudge.

Fixed: the gathering sub-headings (Hides, Scales, Herbs, Fish) were stuck in French on a non-French client.
They translate now, in English, German and Spanish.

## v1.16.0 — Sorted recipes, and where the gold is

Vanilla's profession window puts every potion you know under one heading called "Consumable", in whatever
order it feels like. Recipes are now grouped properly: healing potions, mana potions, elixirs of strength,
flasks, transmutes, and so on, each sorted from the highest rank down to the lowest. A potion that restores
both health and mana appears under both headings, because that's where you'd look for it. The same grouping
shows up everywhere the same recipes do — the Order tab, My Artisans, and the gathering professions, where
ores, herbs, leathers and fish get the same treatment.

If you run Lazy Gold, the addon now reads it. Every recipe carries a small coin indicator showing what it
would earn you: a silver coin for pocket change, one to three gold coins as the numbers climb, stars past a
thousand gold. Losses show nothing at all — this is here to point at what pays. Click the gold coin above
the recipe list to sort by profit instead of by name, and the categories drop away so you get one flat
ranking. The "123" button next to it switches from the coin indicator to exact amounts in gold, silver and
copper. The Order tab gets the same two buttons, plus a line on every incoming order telling you what the
goods are worth at auction and what the reagents you'd have to supply will cost you.

In the Artisans directory, professions are now icons rather than names, and a crafter with a genuinely
profitable plan gets a gold border on that profession's icon. Hover it and it names the plan and the money.
Click it and you land in the Order tab, aimed at that crafter, that profession, with their plans filtered to
what they can actually make.

My Artisans got the same treatment, and one addition of its own: "All realm crafts" merges every profession
of every character on your account into a single list ranked by profit, so you can see at a glance which of
your alts is sitting on money. Cooking and Fishing are in there now — they sell. So are the essences, dusts
and shards an enchanter gets from disenchanting, which aren't recipes and were being left out. The list only
shows characters on your faction: you can't mail a plan to the other side, so listing them was never useful.

If you run MissingTradeSkillsList, a button above the recipe list shows the recipes you haven't learned yet,
in red, alongside the ones you have. Click one and the middle panel tells you where it comes from — vendor,
drop, quest, with the NPC and the coordinates.

## v1.15.1 — Your orders are yours

Order ids were guessable. If someone worked out the id of an order you'd posted, they could rewrite it:
change the buyer, the price, the quantity, who it was addressed to. That's closed. Only the person who
posted an order can change it now. Orders still get passed along between players the way they always have,
which is how they reach people when the hidden channel is quiet, but relaying an order no longer lets you
rewrite it.

Someone could also post junk orders under your name and trip everyone else's spam detector until you got
muted across the realm. The spam counter now only counts orders a player actually posted themselves, not
ones another player relayed for them. That fixes the mirror image of the same bug, where a busy buyer whose
open orders got relayed in one burst was getting muted for it through no fault of their own.

"X declined your order" could be replayed as many times as someone felt like sending it. It fires once now,
on an actual refusal, and never from someone you've muted. The "you can craft this" nudge had the same hole
and got the same treatment.

The profession window was showing orders it had no business showing. An order addressed to one specific
person was visible to everyone who had that profession. It isn't anymore. Expired orders, and orders from
people you've muted, are out of that list too.

Your delivered count could be padded by someone else. A buyer confirming a delivery gets to name the
crafter, and nothing checked that the crafter had ever taken the order. You only get credit for orders you
actually accepted.

Saying hello to another artisan now carries your professions with it, instead of kicking off a round of
back-and-forth. Crossing paths with someone costs about half the messages it used to, and it clears up
artisans who turned up in your directory with no professions listed.

Last one, under the hood. Addon traffic is limited to your realm and the realms connected to it. A character
with the same name as one of your contacts, sitting on a far-off realm you can't even trade with, can't act
as them.

Unrelated, but it ships with this. Flag yourself as looking for work, then go AFK, and you stop showing as
available. No point in someone whispering you when you're not at the keyboard.

## v1.15.0 — Looking for work, and a few fixes

You can now flag yourself as looking for work. Open a profession and hit "Look for work": the whole realm
knows you're available for it, an artisan icon shows over your head for anyone passing by, and you appear as
"[LFW]" in their directory. Turn it off the same way, and it lapses on its own after a while if you forget.

Two windows no longer tangle into each other. The main window and the profession window used to stack at the
same spot; now clicking either one brings it cleanly to the front.

The directory got a partner button (a click, instead of digging through the right-click menu), and it now
drops people you crossed once and haven't seen in a week.

Same-faction only. You can't trade across factions on Classic, so the directory no longer mixes in contacts
from your other-faction characters.

Fixed a case where an artisan showed a profession that wasn't theirs. A recipe leaking from an old client
could briefly mislabel someone (a blacksmith showing up as an enchanter); their real professions are what
shows now.

## v1.14.0 — A panel to manage who you've muted

`/co mute` could list names, but there was no way to browse mutes or lift one without already knowing
the name. The Artisans tab now has a Muted section: every muted player shows up with their reason and
time left (or "permanent"), and an Unmute button right on the row.

## v1.13.0 — Moderation: reasons, temporary mutes, a trust list

Muting someone now records a reason and a date, and can be temporary. `/co mute Bob 1h spammer` mutes Bob
for an hour, then lifts itself. Duration accepts `30m`, `2h`, `2d`, or a plain number of minutes; anything
that isn't a duration is taken as the reason. `/co mute` with no argument lists everyone you've muted, with
their reason and the time left.

`/co trust <name>` marks a player as trusted: they are never auto-muted, neither by the low-level
threshold nor by spam detection. Manual muting still works if you ever need it. `/co untrust <name>`
removes the mark; `/co trust` alone lists your trusted players.

Existing mutes keep working unchanged — no data migration, and older clients that only understand plain
mutes still interoperate.

## v1.12.1 — Nobody can post an order in your name

A code review of the realm channel found that an order arriving on it was trusted to name its own buyer.
One player could publish fake orders across the whole realm under someone else's name — and, worse, feed
the spam detector against that person until every addon user muted them. Orders arriving on the channel
must now come from the player who posted them. Nothing changes for orders relayed between friends, where
a third party legitimately forwards someone else's order.

`/co channel off` now really leaves the channel. It used to only stop rejoining at the next login, so
your orders kept going out to the realm for the rest of the session, despite the message saying otherwise.

## v1.12.0 — Season of Discovery recipes

304 Season of Discovery recipes now live in the catalogue: 80 for Leatherworking, 65 for Blacksmithing,
57 for Tailoring, 48 for Enchanting, 29 for Engineering, 16 for Alchemy, plus Cooking, First Aid and
Mining. They show up in the Order tab, their reagents and skill levels are known, and looting a seasonal
plan is recognised like any other.

They load only on a Season of Discovery realm. On a regular Era realm nothing changes at all — the addon
sees exactly the recipe set it saw before, and the recipes your friends have already shared with you stay
readable. Seasonal recipes are appended to the base set rather than mixed into it, so no position shifts.

## v1.11.0 — Cancelling a public order now reaches the whole realm

Since v1.10.0 a public order travels the realm channel, so crafters you have never met can see it. Its
cancellation did not. Anyone reached only through the channel kept seeing the order as open for up to six
hours, could accept it, and gather the reagents for nothing — their acceptance was silently discarded by
your client, which already knew the order was cancelled. Cancelling now goes out on the same channel.

Posting and cancelling also stopped losing messages. The realm channel needs a mouse click or a key press
to carry a line, and it accepts one line per second. Anything sent outside those windows — a `/co post`
typed in chat, two orders posted in the same second, a post made before the channel finished connecting —
used to vanish without a trace. Those lines now wait in a queue and go out on your next click or keypress.

Only new orders and cancellations ever travel the channel, and only public ones. Guild, friends and named
orders stay private, and acceptances stay between the two players involved.

## v1.10.2 — Fix: an in-combat error in the profession view

Picking a recipe while in combat threw a blocked-action error. The Create button inherits from a secure
template, and WoW forbids hiding a secure button mid-combat — the read-only view of an alt's profession
tried to do exactly that on every recipe click.

The addon now remembers the state it wants and applies it when combat ends. Nothing is lost: the button
simply stays greyed out until you leave combat, and it refuses to craft in the meantime.

## v1.10.1 — Fixes to who gets notified

Order alerts no longer depend on your `/co scan` setting. The chat scanner and the order book shared one
option by accident, so turning the scanner off, or opening it wide, quietly changed which realm-wide
orders pinged you. They're separate now. A public order toasts you when you have the profession for it.

Public orders carrying an item the addon doesn't have in its catalogue used to arrive silently. They
notify now, instead of sitting unseen on the board.

Unmuting someone re-arms spam detection for them, so a mistaken mute doesn't switch the check off for the
rest of your session. Coming back from an alt's read-only profession view no longer leaves the Create
buttons hidden until you click a recipe. And on a busy realm the addon does noticeably less work per chat
line, which shows on Hardcore where the death channel never stops.

## v1.10.0 — Orders reach the whole realm, plus a read-only peek at your alts

Posting to "Everyone" now also broadcasts on the realm channel, not just to people you or your friends
have already crossed paths with. Before this, a public order only reached players you'd whispered
before, or friends and guildmates who could relay it along; a total stranger running the addon had no
way to see it until you happened to find each other. Now it goes out over the shared channel too,
confined to your own realm, so anyone can pick it up. You'll still only get a toast for professions you
actually have, a Blacksmithing order won't bother an Enchanter, it just sits quietly on the board for
whoever's looking.

Click a reroll's profession from the minimap menu and you get a read-only window showing what that
character knows: recipes, required reagents, skill level. No craft button (you're not logged in as
them), no bag counts, just a quick check before you log over.

Two smaller fixes: the reroll menu on the minimap now only lists real professions (Cooking, First Aid,
Fishing, and Poisons don't clutter it up anymore), and the spam-detection threshold is adjustable with
`/co spam`, including an auto-mute mode instead of the usual pop-up.

## v1.9.0 — Your alts, together: shared cooldowns, one identity, a "My Artisans" tab

Three things arrive together.

**Recipe cooldowns are now shared.** When you cast a Transmute (or any recipe on a cooldown), other
addon users see "Transmute: ready" or "Transmute: in 14h" on your artisan tooltip — no more asking in
chat whether your Arcanite is off cooldown. It reads your own cooldowns from the game and broadcasts
them; a small curated table knows which recipes actually have a cooldown.

**Your alts can be grouped under one identity.** Opt in with `/co alts on` and pick a main character.
The network then knows your characters belong to the same player — verified both ways, so nobody can
claim to be someone else's alt. A crafting order named for your offline alchemist now reaches whichever
character you're logged in on ("order for your alt Luletta"), and you can accept it from any of your
characters. In the Artisans tab, a player's alts collapse into one line. This is off by default and
changes nothing on the wire until you enable it.

**A new "My Artisans" tab.** It shows all your account's professions on the realm at once, as if they
were one character: level, known recipes grouped by category like the profession window, active
cooldowns pinned at the top, and which of your characters carries each recipe. Fully local — it works
whether or not `/co alts` is on.

Offline partners can also relay each other's profiles now, shown as an estimate ("via Bob") that direct
data always overrides.

## v1.8.0 — Under the hood: safer upgrades, tidier order protocol

Nothing changes on screen. Two things got sturdier underneath.

Saved data now carries a schema version, so an upgrade that needs to reshape it runs once, in order, and
skips itself if it already ran. Your known recipes and posted orders survive a version jump untouched
(checked against a real save file before shipping).

The order message format now lives in one place instead of being spelled out across five files. The
bytes on the wire are identical, so this build still talks to anyone on 1.7.x. A headless test suite
checks that every message round-trips before a build goes out.

The What's New tab was also missing its 1.7.1 note. It's back.

## v1.7.1 — Looted-recipe alerts that actually concern you

The looted-recipe alert used to pop for every catalogued recipe you picked up — including a Tailoring
pattern when you're a miner-jeweler who'll never craft it. Now it stays quiet unless the recipe is
yours to act on: either you have the profession and could learn it, or a friend or partner in your
directory doesn't know it yet and you could hand it over.

Gift candidates now include your friends, not just people you'd explicitly flagged as partners — so the
"interested" list and `/co gift` reach anyone on your list who's missing the recipe.

## v1.7.0 — Battle.net friends, and ordering by profession

Friends-list professions and the right-click Crafting Order menu used to work only on friends you'd
added by character name. Add someone by their Battle.net account and they got skipped. Now the addon
resolves the character they're actually playing, so a Battle.net friend on your realm shows their
professions on hover and gets the full menu, the same as a character friend.

Right-clicking a crafter gave you a single "Order from ___". Now you get one entry per profession they
craft, and each opens the Order tab already set to it. A miner-blacksmith shows Mining and
Blacksmithing; an alchemist who also gathers herbs just shows Alchemy, since you can't place a craft
order against a gathering skill.

A crafter's summary now shows how deep their book is, like "· 142 recipes", beside their skill. Hold
Shift over their tooltip out in the world and it lists the recipes by name, grouped by profession.

Fixed characters showing professions they don't have. If someone's addon was broadcasting recipes from
their other characters, a warrior could turn up in your directory with a rogue's Poisons. Skill levels
are the truth about which professions a character really has, so the directory now uses them to drop
anything that doesn't belong, even when the sender keeps pushing the stale data from an older build.

Hovering a friend, opening their menu, or selecting a guildmate now nudges a discovery ping so their
professions fill in before you act instead of after. It's throttled and skips anyone already known, so
running your mouse down the Friends list won't spam the channel.

## v1.6.0 — German and Spanish, plus an in-game What's New tab

Crafting Order now speaks German and Spanish. The whole interface switches with your client language:
tabs, buttons, tooltips, chat messages. Item and recipe names were already localized by the game; now
the addon's own text follows. French and English are unchanged.

There's also a new What's New tab, next to Help, that shows the recent release notes right in the
window, so you can see what changed without alt-tabbing to a website.

What travels over the network stays language-neutral, so a German and a French player still read each
other's orders fine on the channel. Only the display is translated.

## v1.5.0 — spot crafters without the addon, plus a performance pass

**Passive crafter detection.** Turn on "Repérer les crafteurs autour" in the Artisans tab (or
`/co crafters on`) and Crafting Order quietly watches for players near you casting recipes it
recognizes, even without the addon. They land in your directory tagged as "seen crafting," with an
estimated skill floor, and get a discovery ping in case they turn out to be a silent addon user after
all. Off by default, and it only watches while you're resting in a town or inn, so it won't touch the
combat log while you're out farming.

**Performance pass.** This release is mostly about making the board lighter, especially on
professions with a lot of recipes:

- The Order tab's plan list got rewritten to reuse a small pool of rows instead of spawning one per
  recipe, so opening a profession with a few hundred plans (Tailoring, looking at you) doesn't bog
  down the frame.
- The bag check on the Order tab stopped re-scanning your inventory item by item for every single
  plan on screen.
- The window no longer redraws itself on every single network message during a busy moment (someone
  posting an order, a wave of directory replies). It now batches those into one redraw.
- Login bursts after a server restart no longer make everyone re-announce their whole recipe list to
  every new arrival at once.

This release also hardens the order protocol: it now checks who actually sent a message before
acting on it, so a stray or malicious client can't cancel someone else's order, fake an acceptance,
or take credit for a delivery that isn't theirs.

## v1.4.1 — fix: directory discovery only taught the other side about you

A directed whisper ping, whether from crossing paths or from someone hitting **Refresh directory**,
only ever taught the *other* side your professions. You'd see them online in your Directory with no
professions listed, and they'd see yours just fine. Discovery is now mutual: receiving a directed
ping or hello also pings back, so both sides learn each other in one exchange.

## v1.4.0 — order a crafter straight from the Friends & Guild panels

**Professions on the native Friends & Guild windows.** Hover a character friend in the **Friends list**
and a small Crafting Order tooltip now shows their **primary professions and skill levels** beside the
game's own tooltip. Select a guildmate in the **Guild** panel and the same summary docks under the
member detail — with an **Order** button right there — so you can size up (and order from) a crafter
without opening the board, even while they're offline.

**"Order from…" in the right-click menu.** Right-click a player who runs the addon — in the Friends
list, an online guildmate, or anyone you cross in the world — and a **Crafting Order** section offers
**Order from _name_** (opens the Order tab pre-targeted at them), alongside Add to artisans / Partner /
Mute. _This also revives those entries: Classic moved to a new context-menu system and the old ones had
silently stopped appearing — they're back, on the modern API._

**Primary professions only** in the social tooltips now — Cooking, First Aid and Fishing are hidden, so
you see the craftable trades that matter.

**"Met" is now the "Directory", with a Refresh button.** The met-on-the-channel source is renamed
**Directory**, and a one-click **Refresh directory** button calls out on the hidden channel so every
addon user currently online answers and lands in your directory — no more waiting to cross paths.

_Fix: the world tooltip's profession line (hovering a player in the world) is back after a regression._

## v1.3.0 — companion panels: deliver orders straight from the trade & mail windows

**Trade & mail companion panels.** When you open a **trade** with someone, or the **mail** composer, a
small Crafting Order panel now appears alongside the native window, listing the orders that tie you to
that player — so you can hand a craft off without ever opening the board.

- **Mail.** On the Send tab it lists every order you owe (all buyers). **Fill from order** sets the
  recipient, subject, body and **C.O.D.** (= the agreed price), and **attaches the crafted item from
  your bags** (exact quantity, whole stacks or a split for the remainder). It never sends for you — you
  review and click Send; the order flips to *Delivered* on a successful send. Anti-duplicate if you
  click Fill twice.
- **Trade.** The panel is two-sided: the **crafter** sees the amount to **collect** and a **Mark
  delivered** button; the **buyer** sees what to **pay** and what they'll receive, with a **Received**
  button to confirm on the spot. It **persists after the trade closes** (with a close button) so either
  side can still finalize without going back to the Ledger. Prices show real gold/silver/copper coin
  icons.
- Panels only appear when there's actually a relevant order — no clutter otherwise. The trade money
  field is display-only (Blizzard forbids addons from touching it); gold is settled the normal way.

**Orders dock in Blizzard profession view.** In the Blizzard (non-custom) profession view, the Crafting
Order **orders column now docks to the right** of the native window, so you keep your order list whether
you use the custom window or Blizzard's. Toggle either way with the on-frame buttons.

**Profession window closes on entering combat.** The custom profession window (or the orders dock) now
auto-closes when combat starts, fixing the case where it couldn't be dismissed mid-fight.

## v1.2.0 — confederation directory, sectioned recipe lists & quieter incoming requests

**Confederation directory (GreenWall).** If you run [GreenWall](https://legacy.curseforge.com/wow/addons/greenwall)
for a cross-guild confederation, the Artisans tab now surfaces a **Confederation** section listing
crafters from your sister guilds who also run this addon — spotted passively from the guild-chat
bridge, display-only (no extra network traffic). Diagnose with **/co gwroster**. Confederation is
below Guild/Friends in priority, so it never bumps someone already classified there. Works on SoD live
only (no confederation on PTR).

**Recipe & plan lists grouped by section.** The Order tab's recipe list and the profession window's
plan list are now grouped under section headers (e.g. weapons, armor, consumables) instead of one long
alphabetical list — easier to scan a large profession. Hovering the produced item in the profession
window's detail pane now shows its full tooltip.

**Quieter incoming requests.** Accepting a request captured from **/trade** or **/guild** (posted by a
player without the addon) no longer sends them an automatic whisper announcing the acceptance — it was
unsolicited and read as spam. The request is still marked accepted in your Incoming queue; reply to the
player yourself in chat if you want them to know.

## v1.1.0 — artisan matching, loot alerts, partners & buyer-confirmed delivery

**Buyer-confirmed completion.** An order no longer flips to *done* the instant the crafter clicks
**Deliver** — it now becomes **Delivered** (awaiting confirmation). The buyer confirms receipt, either
automatically when the crafted item lands in their bags or via a **Received** button in their Ledger,
and only then is the order *done* and the crafter's delivered-count (reputation) credited. This ties
reputation to the buyer actually getting the goods. (Auto-detection currently covers looted items; the
same hook is wired for a future trade/mail step.)

**Recipe filtering by crafter.** In the Order tab, clicking a specific crafter now filters the recipe
list down to what *they* actually know (via their broadcast recipe registry), instead of only setting
the recipient — the reverse of the old recipe-then-crafter flow.

**Loot alert for recipe items.** Looting a recognized recipe/formula/pattern now surfaces a toast/chat
line naming the profession and teachable recipe, flags whether you already know it, and — if you've
tagged a **partner** who doesn't — lists them (`/co lootalert [on|off]` to toggle).

**Partners & gifting.** Right-click a player to mark them as a **partner** (separate from your WoW
friends list) — they're pinned to the top of the Artisans tab. `/co gift [name]` whispers a partner
who's missing your last looted recipe, offering it to them.

**"Reagents on hand" filter.** The Order tab can now filter (or just sort to the top) recipes you can
craft *right now* with what's in your bags, refreshed live as your bags change.

_Under the hood: CraftLink bumped to v6 — recipe data now carries `learnedAt` (skill level required)
and `taughtBy` (recipe-item → spell mapping) for Vanilla/TBC/Wrath, regenerated from Wowhead via a new
`tools/gen_metadata.lua` (idempotent) with a `tools/check_dataversion.lua` guard protecting the frozen
Vanilla dataVersion. Fixed an inconsistent "First Aid"/"FirstAid" profession key between flavors._

**Moderation & anti-spam.** Mute a spammer with `/co mute <name>` / `/co unmute <name>`, shift-right-click
on an order card, or the right-click player menu — a muted player triggers no toast, chat line or sound
(P2P orders **and** chat-captured requests). Low-level posters are auto-muted below a threshold
(`/co lowlevel [N|off]`, default 5) when their level is known, to cut bot/mule noise. A burst of orders
from one author raises a one-click **"mute them?"** prompt.

**Social reputation.** Your delivered-craft count now rides on the profile broadcast and shows in the
social tooltip and the Artisans list (*· N delivered*), which sorts crafters by it. Reputation is
self-reported (same trust model as skill levels) and backward-compatible on the wire — older clients
simply ignore it.

**Reroll awareness.** When an order your current character can't craft is routed to you (a capable-friend
nudge, or an order named to you), the addon tells you which of your **other characters on the account**
can make it — so you know which alt to log.

**Custom profession window is now the default.** The 3-column browser (recipes · reagents · related
orders) is the standard view; *Blizzard view* is the opt-out (`/co profwindow`).

_Under the hood: the orders and directory modules were split along their network / domain seams
(`Orders_Net.lua`, `Directory_Skills.lua`) to keep each file focused._

## v1.0.0 — first stable release

_Since the `0.0.1` beta:_ renamed to **Crafting & Gathering Order — Classic** (full gathering-order
support); inbound scanner treats **OFFER / PROPOSE** as crafter ads so they're no longer misfiled as
requests; inbound alerts now honor the `/co notify` scope and per-player mutes; a **"» Crafting Order
view"** button on the native profession/craft window returns you to the custom view; and the recipe
list pool was widened (23 → 26 rows) so the bottom of long lists is reachable again (e.g. *Bolt of
Woolen / Linen Cloth* in Tailoring).

The standalone, global, social craft-order network. Highlights of this first release:

**Order ledger & posting.** Post craft and gather requests from a tavern-skinned window (Ledger /
Order / Gather / Artisans tabs) or from chat (`/co post`). Browse, accept, deliver and cancel.
Reagent "I provide" ticks when posting a craft. Order **quality filter** (minimum rarity). Gather
requests can be sized **by the unit or by the stack**, and always render with the real total so
there's no guessing — *3 stacks (60)* rather than a cryptic *3 st*.

**Recipient routing.** Target an order to **Everyone**, your **Guild**, your **Friends**, or a
**specific player**. Scoped orders are only shown to / acceptable by eligible recipients; guild
orders also relay over the guild channel. Recipient values are language-neutral on the wire so FR
and EN clients agree.

**Order notifications.** When an order meant for you arrives — broadcast, guild, friends, or you by
name — you get a toast, a chat line and a sound. Tune it with `/co notify`: *all* (default),
*directed* (named + guild + friends), *named* (only orders that name you), or *off*.

**Persistence & retry.** Open orders re-broadcast every ~2 h, are pushed to a targeted crafter the
instant they come online, and expire after 6 h.

**Keep it for a capable friend.** Orders (and captured `/trade`·`/guild` requests) are cross-matched
against the professions of the artisans you know (friends / guild / added). When one who can craft it
comes online, they get a "you can make this" nudge — no shared channel required, all over whisper.
The receiver re-checks their *real* recipe knowledge before alerting, so no false pings.

**Decline & release.** A crafter can **refuse** an order or **release** one they had accepted: it
reopens for others and the buyer is notified (a name-targeted order shows as *Declined*).

**Artisan directory & social.** Live presence over the hidden realm channel, skill levels, sources
(Guild / Friends / Added / Met), add-by-name and right-click "add crafter", social tooltip, and a
**toast** when a favourite crafter logs in.

**Chat capture.** `/trade` and `/guild` requests from players without the addon land in an *Incoming*
queue. WTS (selling) and LFW (crafters advertising) are excluded; word-boundary keyword matching
avoids false positives (e.g. "each" no longer matches "ACH"). Toggle the scanner with `/co scan`.

**Custom profession window** (`/co profwindow`, experimental). 3-column browser (recipes · reagents
with Create / Create All · related orders) replacing the Blizzard window, with a round-trip to
**Blizzard view**. Skill rank stays live; the window remembers its position.

- **Enchanting works.** `DoCraft` is a protected function in Classic Era, so the **Create** button is
  a secure button that forwards the click to Blizzard's native craft button — enchants fire without
  taint errors (equipment enchants then prompt you to target the item, as usual).

**Bilingual.** Full FR + EN chrome via a single locale table; item and recipe names resolve to the
client's own language.

**Built on CraftLink-1.0**, an embeddable shared library (recipe catalogue + registry + transports +
versions), so the addon is fully standalone and coexists cleanly with Guild Economy.
