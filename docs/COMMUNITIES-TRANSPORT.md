# Les communautés WoW (`C_Club`) comme voie pour COC — relevé et verdict

**État : mesuré en jeu le 2026-09-18, sur WoW: Forever (Camelot, interface 16001).**
Tout ce qui suit vient de `/cocprobe club`, `/cocprobe clubpost` et `/cocprobe clubhist`
(module `COCProbe/COCProbe_Club.lua` et `COCProbe_ClubPost.lua`), pas de la lecture de la source.

## La question

COC diffuse au royaume par un canal custom caché (`CraftLinkNet`). Ce canal a deux trous que rien
ne comblera : **pas de mémoire** (une commande postée pendant qu'on est déconnecté n'a jamais
existé) et **pas de liste de membres** (d'où toute la machinerie balise/HELLO/PING pour reconstruire
un annuaire à chaque session).

Forever expose les communautés. Trois usages étaient envisageables :

1. **transporter les données** (remplacer ou doubler le canal) ;
2. **mémoriser** le carnet (livraison différée par l'historique serveur) ;
3. **servir d'annuaire** (roster + présence, sans trafic).

## Verdict en une ligne

**Une communauté ne peut transporter aucune donnée, par aucune voie. Elle ne sert que d'annuaire —
et elle ne donne ni les métiers, ni le nom du personnage.** Les usages 1 et 2 sont morts ; le 3
tient, avec deux ajustements.

## Le relevé

| # | Question | Résultat |
|---|---|---|
| 1 | La fonctionnalité est-elle ouverte ? | ✅ `ShouldAllowClubType(Character)` = true, `IsEnabled` = true, capacité **1000**, `lockdown` = false |
| 2 | ClubFinder (découverte publique) ? | ❌ `IsEnabled` et `IsCommunityFinderEnabled` = **false** — invitation ou rien |
| 3 | Le nom des membres est-il exploitable ? | ⚠️ oui, mais **ce n'est pas le nom du personnage** (voir pièges) |
| 4 | Les métiers sont-ils dans le roster ? | ❌ **non** — 5 métiers appris, 0 annoncés |
| 5 | Peut-on chuchoter un membre depuis son GUID ? | ✅ `RequestCanLocalWhisperTarget` → `CanWhisper` |
| 6 | Un AddonMessage atteint-il un flux de club ? | ❌ **`Success` puis avalé** (voir pièges) |
| 7 | `C_Club.SendMessage` est-il appelable ? | ⚠️ **hardware event uniquement** |
| 8 | Le contenu d'un message est-il lisible ? | ❌ **non**, ni en direct ni en historique |

## Les pièges, avec la preuve

### Le contenu d'un message de club n'existe pas côté Lua

`GetMessageInfo(...).content` rend **`"|Kw1|k"`** — une référence opaque que le client résout au
rendu. Mesuré sur un message que la sonde venait elle-même d'envoyer, par les deux chemins :
`CLUB_MESSAGE_ADDED` en direct **et** `GetMessagesBefore` depuis l'historique. Identique.

Le piège est dans la détection : `type()` rend `"string"`, `issecretvalue()` rend **false**, et
`:match()` fonctionne. **Les trois vérifications naïves passent**, et la charge utile est absente.
Un `#probe(%d+)` posté puis relu rend `nil`.

### Un AddonMessage vers un flux de club est accepté, puis avalé

Un flux lié à une fenêtre de chat EST un canal (`Community:<clubId>:<streamId>`, ici l'index 7), et
`SendAddonMessage(..., "CHANNEL", 7)` rend **`Success` (0)**, pas `InvalidChannel`. Ça ne prouve
rien : le code de retour dit que le client a accepté l'appel.

C'est le **témoin** qui tranche. La même balise, tirée dans la même seconde sur `CraftLinkNet`
(canal custom ordinaire, index 1) et sur le canal de communauté (index 7) :

```
addonToControl = { index = 1, decoded = "Success" }   -> received: PROBE:control  ✅ revenu
addonToClub    = { index = 7, decoded = "Success" }   ->           (rien)         ❌ jamais revenu
```

Un canal ordinaire écho vers l'émetteur ; le canal de communauté, non. Sans ce témoin, « aucun
écho » ne distinguait pas « avalé » de « un canal n'écho pas vers soi-même ».

### Être membre ne donne pas le roster

Sans `C_Club.FocusMembers(clubId)`, `GetMemberInfo` rend **une table dont tous les champs sont
`nil`** — pas `nil`, une table vide. Un `if m then` passe sans broncher et on conclut « ce joueur
n'a pas de métier ». L'interface Blizzard fait `FocusMembers` puis affiche un spinner tant que
`AreMembersReady(clubId)` est faux (`CommunitiesMemberList:OnClubSelected`).

### `ClubMemberInfo.name` n'est pas le nom du personnage

Relevé : `name` = `"Rédemption Wafhien"` (nom d'affichage, compte BNet inclus) alors que le
personnage s'appelle `Rédemption`. Le nom utilisable vient de **`GetPlayerInfoByGUID(info.guid)`**,
qui rend `name` et `realmName` en `cstring` propre (`realmName` vide = même royaume).

### Les métiers ne sont pas dans `ClubMemberInfo`

Vérité terrain : le personnage de test avait **Enchantement, Herboristerie et les 3 métiers
secondaires**. Roster chargé (`readyBefore` et `readyAfter` = true), `name`, `level` (11), `zone`
(Stormwind City), `presence` (1 = Online) et `guid` tous peuplés — et
`profession1ID / profession1Name / profession2ID / profession2Name` tous à **`nil`**.

Ces champs viennent du roster de **guilde**, pas d'une communauté de personnage. Cohérent avec
l'interface, qui garde la colonne derrière `C_TradeSkillUI.IsGuildTradeSkillsEnabled()`.

### `C_Club.SendMessage` est hardware-event-only

Deux tirs, un sous la commande slash (événement matériel valable), un différé de 3 s par un timer.
Résultat : les deux `pcall` rendent `ok = true`, **un seul** `ADDON_ACTION_BLOCKED`, **un seul**
`CLUB_MESSAGE_ADDED`, et une seule ligne visible en jeu — celle du tir sous saisie.

Rappel : un `pcall` ne rattrape pas un blocage. Ce n'est pas une erreur Lua mais un ÉVÉNEMENT émis
après le retour normal de l'appel. Il faut écouter, pas tester le code de retour.

## Ce que ça change pour COC

- **Le canal `CraftLinkNet` n'est pas touché.** Il reste le chemin par défaut, et le relevé a au
  passage prouvé qu'il relaie bien l'AddonMessage sur Forever (le message revient à l'émetteur).
- **Pas de carnet persistant, pas de livraison différée, pas de bus cross-royaume.** Les trois
  reposaient sur la lecture d'un contenu qui n'existe pas.
- **L'annuaire de cercle reste la seule brique à construire**, avec deux ajustements par rapport au
  plan initial :
  - la clé de roster vient de `GetPlayerInfoByGUID(guid)`, jamais de `ClubMemberInfo.name` ;
  - le cercle donne la **liste** et la **présence**, pas les compétences : les métiers continuent de
    passer par le protocole `SK`/`RK` existant en whisper. C'est exactement la forme de
    `Directory_Confed.lua` — classer la source, puis laisser la découverte habituelle faire le
    reste.
- **Pas de « parcourir les cercles »** : ClubFinder est désactivé côté serveur. Créer, inviter,
  coller un code — rien d'autre.

## Non mesuré

- L'ouverture des communautés **sur Era** (`ShouldAllowClubType`) : le `.toc` de la sonde vise
  l'interface 16001, il faut cocher « charger les AddOns obsolètes » là-bas.
- Tout ce qui demande un **2e joueur** : réception réelle d'un AddonMessage de canal par un tiers,
  roster à plusieurs membres, présence d'autrui, chuchotement cross-royaume. Le relevé nº 5 dit que
  l'API répond, pas qu'un inconnu d'un autre royaume est joignable.
