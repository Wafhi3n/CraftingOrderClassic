# Crafting Order — Classic

A **global, social craft-order network** for World of Warcraft **Classic Era** (also packaged for
TBC and WotLK Classic). Post a craft or gather request once and any addon user on your realm can see
it and answer — **no shared guild required**. Built around a shared, embeddable library
(**CraftLink-1.0**) so it runs **standalone** (it does not need Guild Economy / TradeScanner).

> **What "global" really means:** everyone running the addon **and** joined to its hidden realm
> channel — not the whole server. There is no central server; it is peer-to-peer over WoW's own
> addon messaging.

---

## Features

- **Order ledger** (`/co`) — post, browse, accept, deliver and cancel craft/gather orders. Columns:
  item (rarity-colored) · qty · offered price · profession · recipient · status.
- **Recipient routing** — broadcast to **everyone**, or scope an order to your **Guild**, your
  **Friends**, or a **specific player**. Scoped orders are only shown to / acceptable by the right
  people; guild-scoped orders also go out over the guild channel.
- **Gather requests** — a dedicated tab for raw materials (ore, herbs, leather, fish) by the stack
  or by the unit, including a pseudo-profession for mob-farmed "elemental" mats.
- **Reagent supply** — when posting a craft, tick the reagents **you provide** (retail-style).
- **Artisan directory** — who can craft what, with live **presence** (online/offline), skill levels
  (e.g. *Blacksmithing 250/300*), and sources (Guild / Friends / Added / Met). Add anyone by name or
  right-click. Get a **toast** when a favourite crafter comes online.
- **Social tooltip** — hover a player to see *CO-Classic ✓ — their professions & skill levels*.
- **Chat capture** — requests posted in `/trade` and `/guild` by players **without** the addon are
  captured into an *Incoming* queue; accepting whispers them back (and advertises the addon). WTS
  (selling) and LFW (crafters offering service) are correctly excluded.
- **Custom profession window** (`/co profwindow`, experimental) — a 3-column browser (recipes ·
  reagents with **Create / Create All** · related orders) that replaces the Blizzard window, with a
  one-click round-trip to **Blizzard view** and back. Works for the **Craft API** (Enchanting) too.
- **Bilingual** — full FR + EN chrome; item/recipe names resolve to the client's own language.
- **Persistence & retry** — your open orders re-broadcast periodically, are pushed to a targeted
  crafter the moment they log in, and expire after 6 h so the ledger stays clean.
- **Minimap button** + toast notifications, all in the warm "tavern" art direction.

## Commands

| Command | Effect |
|---|---|
| `/co` | open the order ledger window |
| `/co orders` | print the order list to chat |
| `/co post [shift-click item] [xN] [price]` | quick-post an order from chat |
| `/co accept <id>` / `/co done <id>` / `/co cancel <id>` | order lifecycle |
| `/co refresh` | re-poll the directory (presence + proximity) |
| `/co prof` | re-show the "profession orders" overlay on the native window |
| `/co profwindow` | toggle the experimental custom profession window |
| `/co debug` | solo mode: inject/remove a fake network (artisans + orders) for testing |
| `/co help` | command reference |

## Install

Drop the `CraftingOrderClassic` folder into `World of Warcraft\_classic_era_\Interface\AddOns\`
(or `_classic_` for TBC/WotLK). The shared **CraftLink-1.0** library is embedded — nothing else to
install. If you also run **Guild Economy (TradeScanner)**, both share the same CraftLink instance at
runtime (LibStub de-duplicates); Crafting Order takes over craft orders.

## Architecture (for contributors)

```
CraftLink-1.0   (embedded, shared infra)   recipe catalogue + registry + transports + versions
Crafting Order — Classic   (this addon, the product)
  Directory.lua     people directory: presence (channel JOIN/LEAVE) + profiles/skills
  Orders.lua        global order model + lifecycle + ORD.* protocol + routing/retry
  Social.lua        player tooltip + right-click "add crafter"
  Inbound.lua       /trade + /guild capture of non-addon requests
  *_UI*.lua         tavern-skinned window (Ledger / Order / Gather / Artisans)
  *_ProfWindow*.lua custom 3-column profession window (recipes / detail+craft / orders)
```

**Discipline:** network → cache (`CraftingOrderClassicDB`) → UI. The UI only ever reads the cache.
Anti-monolith rules apply (≤500 lines/file, ≤60 lines/function). Localize **all** chrome via
`COC.L` (key = French, enUS overlay) — never hard-code a single-language string.

See [CHANGELOG.md](CHANGELOG.md) for version history and [CURSEFORGE.md](CURSEFORGE.md) for the
store description.
