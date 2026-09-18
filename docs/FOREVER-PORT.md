# Portage vers WoW: Forever (Camelot) — état des lieux

> Relevé du **2026-09-18**, sur la beta. Ce document dit ce qu'on SAIT, comment on l'a su, et ce
> qui reste à mesurer. Il ne décrit pas un portage fait : aucune ligne de COC n'a encore bougé.

## 1. Ce qu'est Forever, en faits

Ce n'est **pas** une 1.15 modifiée. C'est le moteur d'UI **Retail** avec du contenu vanilla niveau 60.

| Point | Valeur | Source |
|---|---|---|
| Chemin client | `D:\Jeux\World of Warcraft\_classic_beta_` | disque |
| Version | **1.60.1.69913** | `.build.info` |
| Flavor | `wow_classic_beta` | `.flavor.info` |
| Interface `.toc` | **16001** | capture d'API + manifestes tiers |
| Suffixe `.toc` | **`_Camelot.toc`** | manifestes tiers — *à confirmer* |
| `WOW_PROJECT_ID` | **1 (MAINLINE)** | capture d'API |
| Base d'API | Mainline ~12.1.5 (Midnight), restrictions « addon disarmament » comprises | Blizzard / presse |
| Beta → sortie | 17 sept → 21 oct ; sortie **4 novembre 2026** | presse |

Conséquence directe : les `.toc` actuels (11509 / 20506 / 30405) ne couvrent pas Forever. Le `.toc`
nu sert de repli au loader, mais il pointe du code qui appelle des API supprimées.

## 2. Méthode

1. Extraction des appels d'API **réels** de COC (167 fichiers Lua), en distinguant les globaux des
   méthodes de frame — sans ce filtre on obtient 158 faux positifs (`:SetPoint`, `:Show`…).
2. Croisement avec une **capture de la surface d'API** du client beta (6 045 fonctions, 269 espaces
   `C_*`, build 69893) publiée par un tiers.
3. Filtre « est-ce vraiment une API Blizzard » via la source Era locale
   (`Documentation/wow-ui-source-classic_era/`).

Résultat : **44 API cassées**, pas 158.

✅ **Relevé fait le 2026-09-18 07:49 sur le client 1.60.1 build 69913** (`COCProbe` v0.1).
Tout ce qui suit est désormais **mesuré sur notre machine**, plus déduit d'une capture tierce.

Confirmations, sans écart :

- `WOW_PROJECT_ID == 1 == WOW_PROJECT_MAINLINE`, `.toc` **16001** — c'est bien du Retail.
- **5 964 globaux, 10 049 frames, 269 espaces `C_*`.**
- **44 API sur 44 confirmées mortes. Zéro surprise.** Le croisement était exact.
- **Tous les remplaçants pressentis existent** — le plan du §4 est exécutable tel quel.
- `Menu` est bien une table : `Menu.ModifyMenu` survit (l'absence vue dans la capture tierce était
  un trou de capture). `TooltipDataProcessor`, `UIPanelWindows`, `SlashCmdList` présents.
- `TradeFrame`, `SendMailFrame`, `MailFrame` sont de vraies frames → **les greffons survivent**.
- `C_Secrets.HasSecretRestrictions() == true` : les restrictions de combat sont actives (LootScan).

## 3. Ce qui survit

- **Le transport.** `CraftLink_Transport.lua` appelle déjà `C_ChatInfo.SendAddonMessage` avec sa
  garde `nil` — il passe tel quel. Le socle réseau de COC n'est pas à refaire.
- Codec, modèle d'ordres, migrations, locale, skin natif, annuaire/social, minimap, journal, suivi.
- Les greffons : `TradeFrame`, `SendMailFrame`, `MailFrame` existent toujours.
- `C_Secrets` ne couvre que le combat (auras, cooldowns, stats, menace). COC n'y touche pas —
  **sauf** le LootScan.

## 4. Ce qui casse

### Par fichier

| Fichier | API mortes |
|---|---|
| `CraftingOrderClassic_Craft.lua` | 23 |
| `Libs\CraftLink-1.0\CraftLink_Recipes.lua` | 10 |
| `Libs\CraftLink-1.0\CraftLink_Cooldowns.lua` | 9 |
| `CraftingOrderClassic_UI_Skin.lua` | 5 |
| `CraftingOrderClassic_ProfWindow_Reroll.lua` | 4 |
| `CraftingOrderClassic_JournalQuests.lua` | 4 |
| `CraftingOrderClassic_ProfWindow_Route.lua` | 3 |
| `CraftingOrderClassic_UI_Artisans_Needs.lua` | 3 |
| `CraftingOrderClassic_ProfOrders.lua` | 2 |
| `CraftingOrderClassic_ProfWindow.lua` | 2 |
| `CraftingOrderClassic_Journal.lua` | 2 |
| `CraftingOrderClassic_UI_Post.lua` | 2 |
| `CraftingOrderClassic_MTSL.lua` | 2 |
| `CraftingOrderClassic_Tracker_Next.lua` | 2 |
| `Libs\CraftLink-1.0\CraftLink-1.0.lua` | 2 |
| `Directory_Skills.lua` | 2 |
| `Directory_Presence.lua` | 1 |
| `CraftingOrderClassic_ProfWindow_Detail.lua` | 1 |
| `CraftingOrderClassic_Companion_Mail.lua` | 1 |
| `CraftingOrderClassic_Gem.lua` | 1 |
| `CraftingOrderClassic_Handoff.lua` | 1 |
| `CraftingOrderClassic_Inbound.lua` | 1 |
| `CraftingOrderClassic_JournalWin.lua` | 1 |
| `CraftingOrderClassic_ShareReagents.lua` | 1 |
| `CraftingOrderClassic_Stats.lua` | 1 |
| `CraftingOrderClassic_Tracker_Rows.lua` | 1 |
| `Orders.lua` | 1 |
| `CraftingOrderClassic_Enchant_Trade.lua` | 1 |
| `CraftingOrderClassic_RecipeCats_Group.lua` | 1 |
| `Directory_LootScan.lua` | 1 |
| `Libs\CraftLink-1.0\Data\Smelting.lua` | 1 |
| `Directory.lua` | 1 |
| `CraftingOrderClassic_ProfWindow_Orders_Card.lua` | 1 |
| `CraftingOrderClassic_Social_Roster.lua` | 1 |

### Détail, avec le remplaçant pressenti

| API morte | Remplaçant | Appelée dans |
|---|---|---|
| `BNGetFriendInfo` | `C_BattleNet.GetFriendAccountInfo` | `Directory_Presence.lua` |
| `CloseCraft` | `C_TradeSkillUI.CloseTradeSkill` | `CraftingOrderClassic_ProfOrders.lua`, `CraftingOrderClassic_ProfWindow.lua` +1 |
| `CloseTradeSkill` | `C_TradeSkillUI.CloseTradeSkill` | `CraftingOrderClassic_ProfOrders.lua`, `CraftingOrderClassic_ProfWindow.lua` +1 |
| `DoTradeSkill` | `C_TradeSkillUI.CraftRecipe` | `CraftingOrderClassic_Craft.lua` |
| `GetCraftCooldown` | `C_TradeSkillUI.GetRecipeCooldown` | `Libs\CraftLink-1.0\CraftLink_Cooldowns.lua` |
| `GetCraftDisplaySkillLine` | `C_TradeSkillUI.GetTradeSkillDisplayName` | `CraftingOrderClassic_Craft.lua`, `Libs\CraftLink-1.0\CraftLink_Recipes.lua` |
| `GetCraftIcon` | `C_TradeSkillUI.GetRecipeInfo(.icon)` | `CraftingOrderClassic_Craft.lua` |
| `GetCraftInfo` | `C_TradeSkillUI.GetRecipeInfo` | `CraftingOrderClassic_Craft.lua`, `Libs\CraftLink-1.0\CraftLink_Cooldowns.lua` +1 |
| `GetCraftItemLink` | `C_TradeSkillUI.GetRecipeItemLink` | `CraftingOrderClassic_Craft.lua`, `Libs\CraftLink-1.0\CraftLink_Cooldowns.lua` +1 |
| `GetCraftName` | `C_TradeSkillUI.GetRecipeInfo(.name)` | `CraftingOrderClassic_Craft.lua`, `Libs\CraftLink-1.0\CraftLink_Recipes.lua` |
| `GetCraftNumReagents` | `C_TradeSkillUI.GetRecipeNumReagents` | `CraftingOrderClassic_Craft.lua` |
| `GetCraftReagentInfo` | `C_TradeSkillUI.GetRecipeReagentInfo` | `CraftingOrderClassic_Craft.lua` |
| `GetCraftReagentItemLink` | `C_TradeSkillUI.GetRecipeReagentItemLink` | `CraftingOrderClassic_Craft.lua` |
| `GetCraftSelectionIndex` | `C_TradeSkillUI.GetSelectedRecipeID` | `CraftingOrderClassic_Craft.lua`, `CraftingOrderClassic_ProfWindow_Detail.lua` |
| `GetItemCount` | `C_Item.GetItemCount` | `CraftingOrderClassic_Journal.lua`, `CraftingOrderClassic_UI_Post.lua` |
| `GetItemIcon` | `C_Item.GetItemIconByID` | `CraftingOrderClassic_MTSL.lua`, `CraftingOrderClassic_ProfWindow_Reroll.lua` +3 |
| `GetItemInfo` | `C_Item.GetItemInfo` | `CraftingOrderClassic_Companion_Mail.lua`, `CraftingOrderClassic_Gem.lua` +15 |
| `GetItemInfoInstant` | `C_Item.GetItemInfoInstant` | `CraftingOrderClassic_Enchant_Trade.lua`, `CraftingOrderClassic_RecipeCats_Group.lua` +2 |
| `GetNumCrafts` | `C_TradeSkillUI.GetFilteredRecipeIDs (#)` | `CraftingOrderClassic_Craft.lua`, `Libs\CraftLink-1.0\CraftLink_Cooldowns.lua` +1 |
| `GetNumQuestLogEntries` | `C_QuestLog.GetNumQuestLogEntries` | `CraftingOrderClassic_JournalQuests.lua` |
| `GetNumSkillLines` | `GetProfessions` | `Directory_Skills.lua` |
| `GetNumTradeSkills` | `C_TradeSkillUI.GetFilteredRecipeIDs (#)` | `CraftingOrderClassic_Craft.lua`, `Libs\CraftLink-1.0\CraftLink_Cooldowns.lua` +1 |
| `GetQuestLogSelection` | `C_QuestLog.GetSelectedQuest` | `CraftingOrderClassic_JournalQuests.lua` |
| `GetQuestLogTitle` | `C_QuestLog.GetInfo` | `CraftingOrderClassic_JournalQuests.lua` |
| `GetSkillLineInfo` | `C_TradeSkillUI.GetBaseProfessionInfo` | `Directory_Skills.lua` |
| `GetSpellInfo` | `C_Spell.GetSpellInfo` | `CraftingOrderClassic_ProfWindow_Reroll.lua`, `CraftingOrderClassic_ProfWindow_Route.lua` +4 |
| `GetSpellLink` | `C_Spell.GetSpellLink` | `CraftingOrderClassic_UI_Skin.lua` |
| `GetSpellTexture` | `C_Spell.GetSpellTexture` | `CraftingOrderClassic_UI_Skin.lua` |
| `GetTradeSkillCooldown` | `C_TradeSkillUI.GetRecipeCooldown` | `Libs\CraftLink-1.0\CraftLink_Cooldowns.lua` |
| `GetTradeSkillIcon` | `C_TradeSkillUI.GetRecipeInfo(.icon)` | `CraftingOrderClassic_Craft.lua` |
| `GetTradeSkillInfo` | `C_TradeSkillUI.GetRecipeInfo` | `CraftingOrderClassic_Craft.lua`, `Libs\CraftLink-1.0\CraftLink_Cooldowns.lua` +1 |
| `GetTradeSkillItemLink` | `C_TradeSkillUI.GetRecipeItemLink` | `CraftingOrderClassic_Craft.lua`, `Libs\CraftLink-1.0\CraftLink_Cooldowns.lua` +1 |
| `GetTradeSkillLine` | `C_TradeSkillUI.GetTradeSkillDisplayName` | `CraftingOrderClassic_Craft.lua`, `Libs\CraftLink-1.0\CraftLink_Recipes.lua` |
| `GetTradeSkillNumMade` | `C_TradeSkillUI.GetRecipeNumItemsProduced` | `CraftingOrderClassic_Craft.lua` |
| `GetTradeSkillNumReagents` | `C_TradeSkillUI.GetRecipeNumReagents` | `CraftingOrderClassic_Craft.lua` |
| `GetTradeSkillReagentInfo` | `C_TradeSkillUI.GetRecipeReagentInfo` | `CraftingOrderClassic_Craft.lua` |
| `GetTradeSkillReagentItemLink` | `C_TradeSkillUI.GetRecipeReagentItemLink` | `CraftingOrderClassic_Craft.lua` |
| `GetTradeSkillRecipeLink` | `C_TradeSkillUI.GetRecipeLink` | `CraftingOrderClassic_Craft.lua`, `Libs\CraftLink-1.0\CraftLink_Cooldowns.lua` +1 |
| `GetTradeSkillSelectionIndex` | `C_TradeSkillUI.GetSelectedRecipeID` | `CraftingOrderClassic_Craft.lua` |
| `GuildRoster` | `C_GuildInfo.GuildRoster` | `Directory.lua` |
| `InviteUnit` | `C_PartyInfo.InviteUnit` | `CraftingOrderClassic_ProfWindow_Orders_Card.lua` |
| `IsAddOnLoaded` | `C_AddOns.IsAddOnLoaded` | `CraftingOrderClassic_Social_Roster.lua` |
| `SelectCraft` | `C_TradeSkillUI.OpenRecipe` | `CraftingOrderClassic_Craft.lua` |
| `SelectQuestLogEntry` | `C_QuestLog.SetSelectedQuest` | `CraftingOrderClassic_JournalQuests.lua` |

### Les trois chantiers réels

1. **`CraftingOrderClassic_Craft.lua` (23)** — la couture Craft vs TradeSkill qu'on avait écrite
   pour absorber les différences d'API. Elle gagne un **troisième backend** : `C_TradeSkillUI`.
   L'architecture tient, c'est exactement le point d'entrée prévu.
2. **`CraftLink_Recipes.lua` (10) + `CraftLink_Cooldowns.lua` (9)** — lecture du catalogue et des
   cooldowns côté lib.
3. **Le reste (≈ 20 appels sur 30 fichiers)** — renommages mécaniques : `GetItemInfo` → `C_Item.*`,
   `GetSpellInfo` → `C_Spell.*`, `IsAddOnLoaded` → `C_AddOns.*`, journal de quêtes → `C_QuestLog.*`.

### Bonnes nouvelles

- **`DoCraft` protégé : problème disparu.** `C_TradeSkillUI.CraftEnchant` existe. Le montage
  `SecureActionButton` + `clickbutton=CraftCreateButton` devient inutile.
- **Plus de dichotomie Craft/TradeSkill.** L'enchantement passe par la même API que le reste.

## 5. Les données

Forever annonce 600+ recettes nouvelles, une refonte de la cuisine, le Secourisme qui fabrique des
potions, des plans/blueprints. **Le dataset Vanilla figé de CraftLink est faux pour Camelot.**

L'outillage l'avait anticipé : `CraftLink/tools/gen_season.lua` et son README nomment déjà Camelot
comme prochaine couche saisonnière. Reste la vraie question de modèle : le registre RK est un
**bitfield indexé par position** dans un catalogue figé, alors que `C_TradeSkillUI` raisonne en
**`recipeID`**. `/cocprobe prof` capture la forme réelle d'une recette pour trancher.

## 6. Les inconnues — état au 2026-09-18

### ✅ Tranché : les commandes de craft natives sont DÉSACTIVÉES

`C_CraftingOrders.ShouldShowCraftingOrderTab()` rend **`false`**. L'espace de noms existe (36
fonctions, héritage Retail) mais la fonctionnalité n'est pas exposée. **La niche de COC est intacte.**

⚠️ Nuance à lever : le relevé a été fait au **niveau 4, sans aucun métier**. Le prédicat porte en
principe sur l'activation globale de la fonctionnalité, pas sur le métier du joueur — mais il faut
le reconfirmer une fois un métier appris. À refaire : `/cocprobe orders`.

### ✅ Tranché le 2026-09-18 07:58 : le transport VIT

`/cocprobe net` a envoyé pour de vrai et **le chuchotement à soi est revenu** :

```
register -> 0 (succes)
envois   : whisper_self / say / yell  -> tous partis sans erreur
RECU     : 1  ->  [WHISPER] de Gangrelame Wafhien : PROBE:whisper_self
```

**`AreOutgoingAddonChatMessagesRestricted() == true` ne veut donc PAS dire « envois bloqués ».**
Le prédicat signale que des restrictions existent (les règles d'instance), pas qu'elles nous
frappent en monde ouvert. Le chemin 1:1 dirigé — **celui dont dépend tout le transport de COC** —
est opérationnel. Contexte du test : niveau 4, hors instance, hors guilde, compte ni d'essai ni
restreint.

Détail utile : dans l'instantané pris avant l'envoi, `IsAddonMessagePrefixRegistered("CLNK1")`
rendait `false` — **les enregistrements de préfixe ne survivent pas à une session**. Il faut
(ré)enregistrer à chaque connexion, ce que fait déjà `CraftLink_Transport.lua`.

⚠️ Ce qui reste NON prouvé côté réseau :
- **SAY / YELL** (découverte de proximité) : partis sans erreur, mais **rien n'est revenu**. On ne
  peut pas distinguer « pas d'écho vers soi-même » de « bloqué » avec un seul client. À départager
  à deux personnages, ou en observant un autre joueur.
- **GUILD** : non testé (pas de guilde).
- **CHANNEL** (canal custom `CraftLinkNet`) : ✅ **PROUVÉ le 2026-09-18** — `SendAddonMessage` sur
  l'index de `CraftLinkNet` rend `Success` **et le message revient à l'émetteur**. Un canal custom
  ordinaire relaie donc bien l'AddonMessage sur Forever. (Reste non prouvé : la réception par un
  AUTRE joueur, qui demande un 2e compte.)
- La **balise TEXTE `CLNK1`** via `SendChatMessage` sous hardware event : non testée.

Voir `COMMUNITIES-TRANSPORT.md` pour le relevé complet des communautés (`C_Club`) : elles ne peuvent
transporter **aucune** donnée, et servent uniquement d'annuaire.

### ⬜ Toujours à confirmer

Le suffixe **`_Camelot.toc`** : poser les deux `.toc` et regarder lequel charge.

## 7. Invariants à ne pas casser

Le portage ne renomme **ni le dossier, ni le `.toc`, ni la SavedVariable, ni `/co`**. Forever est
une **cible de plus** du même addon, pas un nouvel addon. Les WTF sont séparés par flavor
(`_classic_beta_`), donc la DB Forever est distincte de celle d'Era sans effort.

## 8. Protocole de relevé

```
1. Lancer la beta, activer COCProbe
2. /cocprobe            -> scan complet
3. /cocprobe orders     -> commandes natives actives ?
4. Ouvrir un metier, puis /cocprobe prof
5. /reload              -> ecrit les SavedVariables
```

Fichier produit :
`_classic_beta_/WTF/Account/<compte>/SavedVariables/COCProbe.lua`

## 9. Avancement du portage

### ✅ Étape 0 — la cible existe (2026-09-18)

- `CraftingOrderClassic_Camelot.toc` créé, **Interface 16001**, dataset Vanilla, sans la couche SoD
  (une saison n'est pas l'autre). Le `.toc` nu reste le repli si le loader ignore le suffixe.
- Cible `camelot` / `forever` ajoutée à `deploy.ps1` — **explicite seulement**, jamais dans le
  défaut, tant que le portage n'est pas fini.
- Parité des `.toc` vérifiée : **4 `.toc` en parité**, 169 `.lua` valides en Lua 5.1.

### ✅ Étape 1 — la couche de compatibilité (2026-09-18)

`CraftingOrderClassic_Compat.lua` (122 l.) expose `COC.Api`, chargé juste après le fichier racine.
Principe : **on garde toujours la signature historique**, et la divergence se normalise à un seul
endroit. **87 points d'appel** portés sur 25 fichiers.

| Ce qui a été fait | Détail |
|---|---|
| Renommages purs | 45 appels (`C_Item`, `C_Spell`, `C_AddOns`, `C_GuildInfo`, `C_PartyInfo`) |
| **Gardes corrigées** | **42** — le piège : `if GetItemInfo then COC.Api.GetItemInfo(x) end` teste encore le global mort, donc l'appel ne part JAMAIS sur Forever, en silence |
| Tuple ↔ table | `GetSpellInfo` → `A.GetSpellName` (chaîne des deux côtés) ; `BNGetFriendInfo` → `A.GetBNetFriend` |
| Sélection de quête | Index (Classic) vs questID (Retail) : couple `GetQuestSelection` / `RestoreQuestSelection`, jeton **opaque** — un index passé à l'API Retail viserait la mauvaise quête |
| Lib CraftLink | Résout chez elle (elle charge avant l'addon hôte) → **MINOR 13 → 14**, `sync-libs.ps1` passé |
| Tests headless | `Compat` ajouté aux 2 tests qui chargent des modules le consommant |

Gates : `check_lua` OK (4 `.toc` en parité) · `check_locale` OK · `run_tests` **551/551** ·
`check_size` OK. Déployé vers `camelot` (183 fichiers).

### 🟡 Étape 2 — le cœur métier : DÉBLOQUÉE (2026-09-18)

**On a le source Blizzard.** `Documentation\wow-ui-source-forever\` est un worktree git de
Gethe/wow-ui-source sur la branche `forever`, épinglé sur **1.60.1 (69913)** — le build exact du
client. Ça remplace définitivement la capture tierce comme source de vérité.

**DÉCISION (2026-09-18) : sur Camelot, le registre passe les `recipeID` sur le fil. L'Era garde
son bitfield.** Raison : le catalogue de Forever n'est pas « Vanilla + une couche » — des recettes
**changent de métier** (le Secourisme fabrique des potions), donc l'append-only des couches
saisonnières ne s'applique pas ; et aucune source complète n'existe tant que le contenu bouge.
Sans catalogue, le bitfield ne peut pas démarrer. Or `recipeID` **est** un spell ID :
`C_Spell.GetSpellName(id)` résout nom et icône sans catalogue, même pour un métier qu'on n'a pas —
le fil devient auto-descriptif. Coût mesuré (Forge, 610 rec., pire cas) : **154 c** en bitfield
contre **1296 c** en IDs delta-base36, ~6 messages addon au lieu d'un.

Deux faits qui ont cadré le choix : le registre est **déjà clefé par spellID en interne**
(`knownSet = { [spellID] = true }` — le catalogue ne sert qu'à compresser), et l'existant **refuse
déjà de décoder** sur divergence de `dataVersion` (garde `r.recipeDV == lib:DataVersion()` chez
tous les consommateurs). Une divergence donne donc un écran noir, jamais du faux — c'est ce
blackout à chaque patch de contenu qu'on refuse, pas un risque d'erreur.

**Le modèle du client, lui, est clair : les recettes sont clefées par `recipeSpellID`.**
`GetRecipeInfo(recipeSpellID, recipeLevel)`. Notre registre RK — bitfield **indexé par position**
dans un catalogue figé — ne correspond plus au modèle du client. Reste à décider si on garde le
bitfield (en générant un catalogue Camelot ordonné, donc une position par recipeID) ou si on passe
à des recipeID sur le fil ; le premier préserve le format réseau, le second supprime une
indirection. **Décision à prendre avant d'écrire le backend.**

Chaîne de lecture complète, vérifiée sur le source :

| Besoin | API Forever |
|---|---|
| Énumérer les recettes | `C_TradeSkillUI.GetFilteredRecipeIDs()` → liste de recipeID (utilisé par Blizzard, `Blizzard_Professions.lua:847`) |
| Fiche d'une recette | `GetRecipeInfo(recipeID)` → `TradeSkillRecipeInfo` (41 champs) |
| **Le joueur la connaît-il** | champ **`learned`** — l'entrée du registre « qui sait crafter quoi » |
| Seuil de couleur | champ **`relativeDifficulty`** — remplace nos `skillColors` maison (lib v11) |
| Récolte vs craft | champs `isGatheringRecipe`, `isEnchantingRecipe`, `isSalvageRecipe` |
| Réactifs + produit | `GetRecipeSchematic(recipeID, false)` → `outputItemID`, `quantityMin/Max`, `reagentSlotSchematics` |
| Lancer le craft | `CraftRecipe(recipeSpellID, numCasts, craftingReagents, recipeLevel, orderID, applyConcentration)` |
| Métiers du perso | `GetBaseProfessionInfo()`, `GetAllProfessionTradeSkillLines()` |

À noter : `supportsQualities` / `maxQuality` / `qualityIDs` existent dans la structure (héritage
Retail). Si Forever ne les utilise pas, notre modèle d'ordre est épargné — **à vérifier en jeu sur
une vraie recette**, c'est ce que capture `/cocprobe prof`.

Fichiers à porter : `*_Craft.lua` (23), `CraftLink_Recipes` (10), `CraftLink_Cooldowns` (9),
`Directory_Skills` (4).

### Ce qu'on attend en jeu à ce stade

COC doit **charger et répondre à `/co`**, fenêtre principale ouvrable, réseau opérationnel. Tout ce
qui lit un métier est **encore cassé** — c'est l'étape 2, pas une régression.

### 🟢 Étape 2a — le backend métier (2026-09-18)

`CraftingOrderClassic_Craft_Mainline.lua` : **3ᵉ backend** derrière la couture `*_Craft.lua`, qui
savait déjà lire deux API indexées (TradeSkill, Craft). Il tient une liste ORDONNÉE de `recipeID`
et expose la MÊME table d'API indexée — le socle et tous ses appelants (ProfWindow, ProfOrders,
Enchant_Trade) continuent de raisonner en index sans le savoir.

Un accesseur ajouté aux trois backends : **`getSpellID(i)`**. En Classic il se déduit d'un lien
`|Henchant:` ; sur Mainline la recette EST le sort, on le rend tel quel. `ReadRecipes` ne parse
donc plus de lien à la main.

**Le piège évité, et testé.** Le fichier est listé dans les QUATRE `.toc` (la parité l'impose) donc
il est **chargé sur l'Era aussi**. Or le socle teste `Craft.MAINLINE_API` en PREMIER : posé sur un
client Classic, tout le produit live basculait sur une API absente. D'où une **garde de saveur**
(`Api.IS_MAINLINE` **et** présence de l'énumérateur moderne — `C_TradeSkillUI` existe aussi en Era,
ce n'est pas un discriminant). `tests/test_craft_flavor.lua` verrouille les deux sens : refus
d'enregistrement sur Classic, backend complet sur Mainline.

Autre correction : **`TRADE_SKILL_LIST_UPDATE`** ajouté aux listes d'événements. Il existe des
DEUX côtés et remplace `TRADE_SKILL_UPDATE`, absent sur Mainline — sans lui la liste ne se serait
jamais rafraîchie sur Forever.

Gates : 170 `.lua`, 4 `.toc` en parité, locale OK, **570/570 tests**, taille OK. Déployé (184 f.).

**Reste sur l'étape 2** : le codec Camelot (recipeID delta-base36) et le dock sur `ProfessionsFrame`
(module LoadOnDemand, variante `Camelot/` à lire avant d'écrire).

## 10. Feuille de route (au 2026-09-18, sortie le 4 novembre)

### ✅ Fait

| | |
|---|---|
| **0 — la cible** | `.toc` Camelot 16001, cible `deploy.ps1`, parité 4 `.toc` |
| **1 — la compat** | `COC.Api` : 87 sites, 44 API, gardes incluses |
| **2a — le métier** | 3ᵉ backend `C_TradeSkillUI`, garde de saveur testée |
| **2b — l'UI** | Colonne Commandes DANS la fenêtre native ; validé en jeu |

### 🔵 CAP — Forever est la cible du projet (décision 2026-09-18)

L'addon Era n'est plus mis à jour ; le pari est que Classic Era ne bougera plus et que Forever est
là où seront les joueurs. **Mais un tag = un paquet valable pour les quatre saveurs** (le packager
déduit les saveurs des `.toc`). Donc : tant qu'on ne tague pas, les utilisateurs Era restent sur
v1.30.0 et ne risquent rien ; le jour où on publie, ils reçoivent le même code.

Ce qui rend ça tenable, et qu'il ne faut pas relâcher : **la garde de saveur en tête de tout fichier
propre à une cible**, plus la suite headless. La non-régression Era passe de « avant chaque étape »
à **« avant publication »** — pas à « jamais ».

### ⚪ P0 (reporté) — la non-régression Era

**32 fichiers partagés modifiés, jamais exécutés sur un client Era.** Les tests headless et les
gardes de saveur couvrent la logique, pas le rendu. À faire AVANT d'ajouter quoi que ce soit :
déployer sur `era`, ouvrir un métier, la fenêtre `/co`, poster un ordre. C'est le produit LIVE.

### 🟠 P1 — la revue des surfaces Forever

On n'a éprouvé QUE la fenêtre métier. **Non testés** : poster un ordre, les greffons échange et
courrier, les tooltips sociaux, le menu clic-droit, le suivi à l'écran, le journal, la minimap,
l'annuaire. Chacun peut cacher un piège de la famille des six déjà trouvés.
C'est du **repérage, pas du développement** — meilleur rapport information/effort, et le résultat
peut réordonner tout le reste. Un `/cocprobe` complet au passage (39 événements) coûte 30 secondes.

### ✅ FAIT — le registre réseau (codec Camelot)

Codec `RI` (identifiants, delta-base36), couture `Directory_Recipes` (les lecteurs posent une
question, ils ignorent la forme), émission/réception/**relais** branchés, garde anti-fuite d'alts
répliquée. 635 vérifications headless.

### 🟡 P3 — les données Camelot

Le catalogue n'est plus nécessaire au REGISTRE, mais il l'est encore à la route, à la bourse et aux
catégories. Deux pistes : générer une couche Camelot (`gen_season.lua`), **ou** lire les catégories
du client (`categoryID` + noms sémantiques — « Camping », « Stamina Food »), qui sont meilleures que
les nôtres. `relativeDifficulty` rend déjà nos `skillColors` inutiles sur cette cible.

### 🟡 P4 — la barre d'outils dans la bande

Route, bourse d'artisan, LFW, filtres par stat : aujourd'hui seule la colonne Commandes vit dans la
bande élargie. À décider — petite barre en haut de la bande, ou boutons ouvrant leurs propres
fenêtres (le Plan de route a déjà la sienne).

### ⬜ P5 — le reste

LootScan sous `C_Secrets` (le CLEU est restreint), et les voies réseau non prouvées : SAY/YELL
(demande deux personnages), guilde, balise TEXTE sous hardware event.

### ⬜ P6 — la release

CHANGELOG, `CURSEFORGE.md`, tag. **À vérifier tôt** : est-ce que CurseForge expose « WoW Forever »
comme version de jeu, et comment le `.pkgmeta` doit la déclarer ? Ça gate la sortie et ça ne dépend
pas de nous — autant le découvrir maintenant qu'en novembre.

## 10 bis. Deux réflexes appris à la dure

**Quand un résolveur ou une forme de donnée apparaît, chercher TOUS ses lecteurs.** Pas seulement
celui qui a révélé le bug. Trois fois dans la même journée : le titre puis le portrait puis
l'ancrage du menu de métier ; le registre `recipes` puis `relayed.recipes` puis `MaybeDiscover`.
À chaque fois la correction ciblée a laissé des jumeaux silencieux derrière elle.

**La beta plante toute seule — lire `_classic_beta_\Errors\` AVANT de suspecter notre code.**
Assertions graphiques chroniques (`CAS_LOCALITY_ERROR`, `texture->GetSize() == texturePool…`,
`GxResourceStateTracker`) et bugs Lua dans les fichiers Camelot de Blizzard, présents dès le premier
soir, avant tout déploiement de COC. Symptôme typique : barres d'action et cadres d'unité qui
« disparaissent » — en fait **présents mais vides** (liaison de texture en échec, pas un `Hide()`),
et réparés par un `/reload`. Un bug d'addon, lui, se reproduit à l'identique.
Coût de ne pas l'avoir fait : une matinée, et un correctif réel (`SetUIPanelAttribute`) retiré pour
rien sur une attribution post hoc.

## 11. Plan du branchement réseau (codec `RI`)

Le codec existe et est testé (`CraftLink_RegistryIDs.lua`, lib MINOR 15, 28 vérifications). Rien ne
transite encore : `Directory` ne connaît que `RK`, et quatre consommateurs appellent `HasBit`
derrière une garde `recipeDV`.

**Ce qui simplifie tout** : Forever et l'Era sont deux JEUX séparés. Un client Camelot ne parle
qu'à des clients Camelot — pas de population mixte sur un royaume, donc **aucune négociation de
format**, et jamais deux formes dans un même roster. On garde `RK` fonctionnel par robustesse, pas
par nécessité.

### Phase 1 — la couture (neutre en comportement)

Nouveau `Directory_Recipes.lua` (`Directory.lua` est à 469 l., pas de place) :

| Fonction | Rôle |
|---|---|
| `Dir:RecipeForm(r, prof)` | rend `("ids", payload)` \| `("bits", hex)` \| `nil` — **encapsule la garde `recipeDV`**, qui n'a plus à être écrite ailleurs |
| `Dir:RecipeTester(r, prof)` | rend un prédicat `function(spellID) -> bool`, ou `nil` si aucune donnée exploitable |
| `Dir:HasRecipeData(r, prof)` | pour les gardes de validité |
| `Dir:RecipeFingerprint(r, prof)` | clé de cache (LazyGold la construit aujourd'hui avec `hex`) |

Migration des quatre appelants : `Handoff:68`, `LazyGold:280+284`, `UI_Artisans_Needs:59+72`,
`UI_Post_Artisans:38`. Aucun ne connaît plus la forme du payload.

**À ce stade rien n'émet `RI`**, donc `RecipeForm` rend toujours `"bits"` : comportement
strictement identique, et les tests headless le prouvent. C'est le point de contrôle du chantier.
Nouveau `tests/test_recipe_seam.lua` : les deux formes, l'écart de `dataVersion` → `nil`, l'absence
de données → `nil`.

### Phase 2 — la bascule du fil

- **Émission** : `Dir:_RecipeMessage(prof)` → `BuildRI` sur Camelot, `BuildRK` ailleurs. Deux sites
  seulement (`Directory.lua:236` dans `Announce`, `:250` dans `AnnounceTo`).
- **Réception** : `Dir:OnRI` + `CraftLink:RegisterHandler("RI", …)` (cf. `:383`), stocke
  `r.recipeIDs[prof] = payload`. `OnRK` reste tel quel.
- ⚠️ **Répliquer la garde anti-fuite d'alts** de `OnRK` : `if r.skill and next(r.skill) and not
  r.skill[prof] then return end` — SK fait foi sur les métiers. L'oublier dans `OnRI` rouvrirait un
  trou déjà fermé une fois.
- **SavedVariables** : `r.recipeIDs` est un champ neuf et optionnel (absent = `nil`), a priori
  aucune migration. À confirmer contre `COC.Migrations`.

### Phase 3 — le relais (à cadrer, pas encore lu en détail)

`Directory_Relay.lua` rediffuse le roster : filtre de verbes (`:94`, aujourd'hui `SK`/`RK`/`CD`),
stockage (`:108`), reconstruction (`:66` via `RelayCodec.BuildRK`). Il faut décider si `RI` entre
dans le mesh. **Probablement oui**, mais c'est le morceau le moins connu — à lire avant de chiffrer.

### Ordre recommandé

Phase 1 en entier (sûre, testable, réversible), vérifier l'Era, **puis** phase 2. La phase 3 peut
attendre : sans relais, le réseau fonctionne en direct et en canal, seule la propagation de
proche en proche manque.
