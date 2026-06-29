# Changelog — Crafting Order — Classic

## v0.1.0 — first public build

The standalone, global, social craft-order network. Highlights of this first release:

**Order ledger & posting.** Post craft and gather requests from a tavern-skinned window (Ledger /
Order / Gather / Artisans tabs) or from chat (`/co post`). Browse, accept, deliver and cancel.
Reagent "I provide" ticks when posting a craft. Order **quality filter** (minimum rarity).

**Recipient routing.** Target an order to **Everyone**, your **Guild**, your **Friends**, or a
**specific player**. Scoped orders are only shown to / acceptable by eligible recipients; guild
orders also relay over the guild channel. Recipient values are language-neutral on the wire so FR
and EN clients agree.

**Persistence & retry.** Open orders re-broadcast every ~2 h, are pushed to a targeted crafter the
instant they come online, and expire after 6 h.

**Artisan directory & social.** Live presence over the hidden realm channel, skill levels, sources
(Guild / Friends / Added / Met), add-by-name and right-click "add crafter", social tooltip, and a
**toast** when a favourite crafter logs in.

**Chat capture.** `/trade` and `/guild` requests from players without the addon land in an *Incoming*
queue. WTS (selling) and LFW (crafters advertising) are excluded; word-boundary keyword matching
avoids false positives (e.g. "each" no longer matches "ACH").

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
