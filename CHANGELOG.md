# Changelog — Crafting & Gathering Order — Classic

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
