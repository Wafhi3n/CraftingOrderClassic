# Changelog — Crafting & Gathering Order — Classic

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
