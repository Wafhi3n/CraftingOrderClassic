# Changelog — Crafting & Gathering Order — Classic

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
