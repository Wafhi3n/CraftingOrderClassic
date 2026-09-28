# Icônes « une commande t'attend » dans la barre de la minicarte

> État : **2e version codée, pas vue en jeu** (une icône par métier, avec le nombre). La 1re version
> (une seule icône, le marteau des commandes) a été vue à deux comptes : registre, relevés 2026-09-28
> 13:16 et 13:20 ; critère 7 (taint) partiel. · Rédigée le 2026-09-28 · Idée du user le 2026-09-27,
> périmètre tranché par lui le 2026-09-28 en deux tours de questions (cf. Décisions).
> Cible : WoW: Forever / Camelot (16001) · Addon : Crafting Order - Classic
> Deuxième usage de l'outil d'icônes de la minicarte (spec `icone-minicarte.md`, rangs 4.xx).

## Le problème

Quand quelqu'un passe une commande **à ton nom**, COC sonne une fois : une ligne dans le chat, un
toast, un son. Si tu étais en combat, dans une conversation ou loin du clavier, tu as raté l'alerte,
et plus rien ne te le rappelle tant que tu n'ouvres pas la fenêtre du métier. La commande attend
pourtant ta réponse, et l'acheteur attend avec elle.

L'icône des commandes personnelles de Blizzard, en haut de la minicarte, règle ce problème pour leur
système : elle reste là tant qu'une commande personnelle est disponible.

## Ce qu'on veut

Tant qu'au moins une commande **nommée pour toi** (ou pour un de tes rerolls) attend ta réponse dans
un métier, **l'icône de ce métier** apparaît dans la barre de la minicarte, après la lettre du
courrier, avec **le nombre de commandes** dans le coin bas droit. Deux métiers, deux icônes. Chacune
**s'éteint seule** quand plus aucune commande n'attend dans son métier : acceptée ou refusée, annulée
par l'acheteur, masquée, acheteur en sourdine, ou expirée (6 h).

- **Survol** : le nom du métier, « Commandes à ton nom : N », puis une ligne par commande (acheteur,
  objet, quantité ; « pour <reroll> » si elle vise un autre de tes persos), cinq au plus, puis
  « +N de plus » ; en bas, « Clic : ouvrir cette fenêtre de métier » quand le clic peut l'ouvrir.
- **Clic** : ouvre la fenêtre de CE métier (le même chemin que le clic du suivi,
  `ProfWindow:OpenFor`). Si seules des commandes pour un reroll y attendent, ou si le métier est
  inconnu, la liste s'écrit dans le chat.

## Ce qu'on NE fait PAS (pour l'instant)

- **Pas les commandes publiques, de guilde ou d'amis**, même celles de ton métier qui déclenchent un
  toast : elles vivent 6 h et sont visibles de tous, l'icône serait allumée presque en permanence.
- **Pas les demandes captées dans le chat** (Entrantes) : éphémères, et très bavardes.
- **Pas d'icône « commande livrée »** côté acheteur. Ce sera une autre icône, au rang 5, dans un
  chantier à part (idée du user : une icône par type de notification).
- **Pas de « non lu »** : regarder la commande sans y répondre ne l'éteint pas.

## Cas particuliers

- **Mêmes règles que l'alerte.** Une commande qui ne sonnerait pas n'allume pas d'icône :
  `/co notify off`, acheteur en sourdine, commande masquée (clic droit dans la vue métier). Un filtre
  d'alerte sans son jumeau côté affichage finit toujours par se contredire (vécu avec les Entrantes).
- **Ta propre commande** nommée pour un de tes rerolls ne compte pas : elle ne t'attend pas.
- **Ordre des icônes** : fixe par métier (Alchimie, Forge, Enchantement, Ingénierie, …, Couture,
  Cuisine, Secourisme…), rangs 4.01 à 4.16. Une commande qui arrive dans un nouveau métier ne fait pas
  sauter les icônes déjà là. Tout reste sous 5.
- **Métier inconnu** (objet hors catalogue) ou **sans icône connue** : l'icône des commandes de
  Blizzard, à sa taille native (20 × 15), au rang 4.99 ; celle de la 1re version, vue en jeu.
- **Expiration** : aucun événement ne dit qu'une commande a expiré. Un minuteur unique est armé sur
  la plus proche échéance et rappelle le recalcul ; pas de ticker.
- **Rerolls** : une commande nommée pour un autre perso du compte compte (elle sonne déjà), mais le
  clic n'ouvre que le métier du perso connecté : la fenêtre native ne connaît que lui.
- **Taille et nombre** : icône carrée de 22 px (celle du logo « CO »), nombre en `NumberFontNormal`
  dans le coin bas droit, comme un objet des sacs. À valider sur capture.
- **Barre** : elle n'est recomposée que quand une icône apparaît ou disparaît. Un nombre qui change ne
  touche qu'au texte.

## Critères d'acceptation

1. [test] `UI:OrdersWaitingForMe()` retient une commande ouverte nommée pour moi ou pour un de mes
   rerolls, et écarte : une commande publique, la mienne, une expirée, une masquée, un acheteur en
   sourdine, `notify off`, une commande acceptée, annulée ou refusée. Plus récente d'abord.
   → `tests/test_order_indicator.lua`
2. [test] Une icône par métier, enfant de la barre, à son rang fixe (4.xx) ; l'icône du métier,
   22 px ; le nombre du métier dans le coin ; un nombre qui baisse ne recompose pas la barre ; le
   dernier départ d'un métier retire son icône ; repli sur l'icône des commandes pour un métier
   inconnu ; minuteur sur la plus proche expiration. → même fichier
3. [test] L'infobulle nomme le métier, compte, liste, plafonne à cinq ; le clic ouvre ce métier ;
   reroll seul : pas de ligne « Clic », la liste part dans le chat. → même fichier
4. [porte] Les quatre portes ; les chaînes neuves sont dans les trois overlays.
5. [humain] Un client, les deux commandes de test ci-dessous : deux icônes (Couture avec « 2 »,
   Alchimie avec « 1 ») à côté de la lettre, dans cet ordre (Alchimie d'abord) ; l'infobulle de la
   Couture dit « Tailoring », « Orders in your name: 2 » ; le clic ouvre la Couture ; les lignes
   d'effacement les font disparaître. Témoin : le marteau de la 1re version, vu au même endroit le
   2026-09-28 (relevé 13:16).
6. [humain] Deux comptes : A passe une commande nommée pour B → l'icône du métier apparaît chez B avec
   « 1 » ; une deuxième → « 2 » ; B en accepte une → « 1 » ; A annule l'autre → l'icône disparaît.
7. [humain] `/console taintLog 1`, icônes affichées, mode Édition ouvert puis fermé, un combat : aucune
   erreur, rien de COC dans `Logs\taint.log`.

Commandes de test (un client ; Couture requise pour le clic), une ligne à la fois. ⚠️ La saisie du
chat s'arrête à **255 caractères** : une ligne plus longue est coupée et lève « unfinished string »
(vécu le 2026-09-28). D'où la fonction posée d'abord :

```
/run COCm=CraftingOrderClassic.Api.PlayerName() function COCT(k,p,i,q) CraftingOrderClassic.db.orders[k]={id=k,buyer="Test Un",recipient=COCm,status="open",ts=time(),itemID=i,profession=p,qty=q} end
/run COCT("T-1","Tailoring",2996,1) COCT("T-2","Tailoring",2996,2) COCT("T-3","Alchemy",118,1) CraftingOrderClassic.UI:RefreshOrderIndicator()
/run for _,k in ipairs({"T-1","T-2","T-3"}) do CraftingOrderClassic.db.orders[k]=nil end CraftingOrderClassic.UI:RefreshOrderIndicator()
```

## Décisions

- **2026-09-28, user (1er tour)** : les commandes **nommées pour moi** (pas les publiques ni les
  Entrantes) ; un **état** qui s'éteint quand plus rien n'attend (pas un « non lu ») ; le **clic ouvre
  le métier** ; « commande livrée » viendra **plus tard**, dans un autre chantier.
- **2026-09-28, défaut de l'agent** : les règles de l'alerte s'appliquent (`notify off`, sourdines,
  commande masquée).
- **2026-09-28, user (2e tour, après la 1re version vue en jeu)** : « une icône du métier où on a
  reçu la commande, avec le nombre de commandes dessus » → **une icône par métier** (plutôt qu'une
  seule au total), **carrée, nombre en bas à droite** (plutôt que ronde).
- **2026-09-28, défaut de l'agent** : rangs fixes par métier sous 5 ; repli sur l'atlas des commandes
  de Blizzard (20 × 15, taille native) pour un métier inconnu ; l'outil apprend `count`, `width` /
  `height`, `useAtlasSize`, et ne recompose la barre qu'à une apparition ou une disparition.

## Contrat

`CraftingOrderClassic_MinimapIndicator_Orders.lua`, sur `COC.UI` :

- `UI:OrdersWaitingForMe()` → liste des commandes qui attendent ma réponse, plus récente d'abord.
  Seule source de vérité des icônes.
- `UI:RefreshOrderIndicator()` → recalcule (différé de 0,2 s, les rafales réseau arrivent groupées)
  et pose chaque icône `"order:<métier>"` avec son nombre. À appeler partout où cet état change :
  réception réseau (`Orders:OnNetwork`), `Orders:Accept`, `Orders:Decline`, masquer ou réafficher une
  commande (vue métier), `Moderation:Mute` / `Unmute`, `/co notify`. L'entrée en jeu et l'expiration
  l'appellent d'elles-mêmes.

## Renvois

- `icone-minicarte.md` (l'outil, la méthode mesurée sans taint, les rangs).
- `Orders.lua` (`_ShouldAlert`, `AlertTargeted`) : l'alerte dont l'icône est le rappel.
- Blizzard : `MiniMapCraftingOrderFrameMixin`, `Blizzard_Minimap/Mainline/Minimap.lua` ;
  `LayoutFrame.lua` (tri numérique des `layoutIndex`).
