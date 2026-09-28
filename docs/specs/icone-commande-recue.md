# Icône « une commande t'attend » dans la barre de la minicarte

> État : **vue en jeu à deux comptes** (registre, relevé 2026-09-28 13:16 ; critère 7, le taint, non
> prouvé) · Rédigée le 2026-09-28 · Idée du user le 2026-09-27, périmètre
> tranché par lui le 2026-09-28 (quatre questions, cf. Décisions).
> Cible : WoW: Forever / Camelot (16001) · Addon : Crafting Order - Classic
> Deuxième usage de l'outil d'icônes de la minicarte (spec `icone-minicarte.md`, rang 4).

## Le problème

Quand quelqu'un passe une commande **à ton nom**, COC sonne une fois : une ligne dans le chat, un
toast, un son. Si tu étais en combat, dans une conversation ou loin du clavier, tu as raté l'alerte,
et plus rien ne te le rappelle tant que tu n'ouvres pas la fenêtre du métier. La commande attend
pourtant ta réponse, et l'acheteur attend avec elle.

L'icône des commandes personnelles de Blizzard, en haut de la minicarte, règle ce problème pour leur
système : elle reste là tant qu'une commande personnelle est disponible.

## Ce qu'on veut

Tant qu'au moins une commande **nommée pour toi** (ou pour un de tes rerolls) attend ta réponse,
l'icône des commandes d'artisanat apparaît dans la barre de la minicarte, après la lettre du courrier.
Elle **s'éteint seule** quand plus aucune n'attend : tu l'as acceptée ou refusée, l'acheteur l'a
annulée, tu l'as masquée, tu as mis l'acheteur en sourdine, ou elle a expiré (6 h).

- **Survol** : « Commandes à ton nom : N », puis une ligne par commande (acheteur, objet, quantité ;
  « pour <reroll> » si elle vise un autre de tes persos), cinq au plus, puis « +N de plus » ; en bas,
  « Clic : ouvrir le métier de la plus récente ».
- **Clic** : ouvre la fenêtre du métier de la commande la plus récente à ton nom (le même chemin que
  le clic du suivi, `ProfWindow:OpenFor`). Si seules des commandes pour un reroll attendent, ou si le
  métier est inconnu, la liste s'écrit dans le chat.

## Ce qu'on NE fait PAS (pour l'instant)

- **Pas les commandes publiques, de guilde ou d'amis**, même celles de ton métier qui déclenchent un
  toast : elles vivent 6 h et sont visibles de tous, l'icône serait allumée presque en permanence.
- **Pas les demandes captées dans le chat** (Entrantes) : éphémères, et très bavardes.
- **Pas d'icône « commande livrée »** côté acheteur. Ce sera une autre icône, à un autre rang, dans
  un chantier à part (idée du user : une icône par type de notification).
- **Pas de « non lu »** : regarder la commande sans y répondre ne l'éteint pas.

## Cas particuliers

- **Mêmes règles que l'alerte.** Une commande qui ne sonnerait pas n'allume pas l'icône :
  `/co notify off`, acheteur en sourdine, commande masquée (clic droit dans la vue métier). Un filtre
  d'alerte sans son jumeau côté affichage finit toujours par se contredire (vécu avec les Entrantes).
- **Ta propre commande** nommée pour un de tes rerolls ne compte pas : elle ne t'attend pas.
- **Expiration** : aucun événement ne dit qu'une commande a expiré. Un minuteur unique est armé sur
  la plus proche échéance et rappelle le recalcul ; pas de ticker.
- **Rerolls** : une commande nommée pour un autre perso du compte compte (elle sonne déjà), mais le
  clic n'ouvre que le métier du perso connecté : la fenêtre native ne connaît que lui.
- **Taille** : 20 × 15, l'atlas à sa taille native, exactement l'icône de Blizzard et celle que le user
  a vue au labo le 2026-09-27 (`/tlab indica`). Le logo « CO » de la mise à jour reste à 22.
- **Même image que l'icône de Blizzard (rang 2).** Sur Forever, le système de commandes de Blizzard
  n'a pas été vu actif ; si les deux apparaissaient ensemble, l'infobulle les distingue (la nôtre
  commence par « Crafting Order »).

## Critères d'acceptation

1. [test] `UI:OrdersWaitingForMe()` retient une commande ouverte nommée pour moi ou pour un de mes
   rerolls, et écarte : une commande publique, la mienne, une expirée, une masquée, un acheteur en
   sourdine, `notify off`, une commande acceptée, annulée ou refusée. Plus récente d'abord.
   → `tests/test_order_indicator.lua`
2. [test] Une commande qui arrive allume l'icône (enfant de la barre, rang 4, 20 × 15, atlas à sa
   taille) ; la dernière qui part l'éteint ; la barre n'est recomposée que quand l'état change ; un
   minuteur est armé sur la plus proche expiration. → même fichier
3. [test] L'infobulle compte, liste, plafonne à cinq ; le clic ouvre le métier de la plus récente
   commande à mon nom ; sans elle, la liste part dans le chat. → même fichier
4. [porte] Les quatre portes ; les trois chaînes neuves sont dans les trois overlays.
5. [humain] Un client : la commande de test ci-dessous fait apparaître l'icône à côté de la lettre ;
   l'infobulle dit « Commandes à ton nom : 1 » et « Test Un : Bolt of Linen Cloth » ; le clic ouvre la
   Couture ; la ligne d'effacement la fait disparaître. Témoin : l'icône du labo (`/tlab indica`),
   même image, même place, vue le 2026-09-27.
6. [humain] Deux comptes : A passe une commande nommée pour B → l'icône apparaît chez B ; B accepte →
   elle disparaît. Une seconde commande, qu'A annule → elle disparaît aussi.
7. [humain] `/console taintLog 1`, icône affichée, mode Édition ouvert puis fermé, un combat : aucune
   erreur, rien de COC dans `Logs\taint.log`.

Commande de test (un client, métier Couture requis pour le clic) :

```
/run local C=CraftingOrderClassic; C.db.orders["T-1"]={id="T-1",buyer="Test Un",recipient=C.Api.PlayerName(),status="open",ts=time(),itemID=2996,profession="Tailoring",qty=1}; C.UI:RefreshOrderIndicator()
/run local C=CraftingOrderClassic; C.db.orders["T-1"]=nil; C.UI:RefreshOrderIndicator()
```

## Décisions

- **2026-09-28, user** : l'icône suit les commandes **nommées pour moi** (pas les publiques ni les
  Entrantes) ; c'est un **état** qui s'éteint quand plus rien n'attend (pas un « non lu ») ; le
  **clic ouvre le métier** ; « commande livrée » viendra **plus tard**, dans un autre chantier.
- **2026-09-28, défaut de l'agent** : l'atlas `UI-HUD-Minimap-CraftingOrder-Up` à sa taille native
  (20 × 15), comme au labo et comme Blizzard. L'outil apprend pour cela `width`/`height` et
  `useAtlasSize`.
- **2026-09-28, défaut de l'agent** : les règles de l'alerte s'appliquent (`notify off`, sourdines,
  commande masquée).

## Contrat

`CraftingOrderClassic_MinimapIndicator_Orders.lua`, sur `COC.UI` :

- `UI:OrdersWaitingForMe()` → liste des commandes qui attendent ma réponse, plus récente d'abord.
  Seule source de vérité de l'icône.
- `UI:RefreshOrderIndicator()` → recalcule (différé de 0,2 s, les rafales réseau arrivent groupées)
  et allume ou éteint l'icône `"order"`. À appeler partout où cet état change : réception réseau
  (`Orders:OnNetwork`), `Orders:Accept`, `Orders:Decline`, masquer ou réafficher une commande (vue
  métier), `Moderation:Mute` / `Unmute`, `/co notify`. L'entrée en jeu et l'expiration l'appellent
  d'elles-mêmes.

## Renvois

- `icone-minicarte.md` (l'outil, la méthode mesurée sans taint, les rangs).
- `Orders.lua` (`_ShouldAlert`, `AlertTargeted`) : l'alerte dont l'icône est le rappel.
- Blizzard : `MiniMapCraftingOrderFrameMixin`, `Blizzard_Minimap/Mainline/Minimap.lua`.
