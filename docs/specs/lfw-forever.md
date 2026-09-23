# « Chercher du travail » (LFW) sur Forever

> État : **validée** · Rédigée le 2026-09-23 · Arbitrages A, B, C tranchés par le user le
> 2026-09-23 · Pas encore implémentée
> Cible : WoW: Forever / Camelot (16001) uniquement · Addon : Crafting Order - Classic
>
> Origine : constat du user, 2026-09-23 — « le bouton n'existe plus ». Vérifié : il ne s'agit pas
> d'une régression diffuse mais d'une ligne précise, citée plus bas. Le transport et l'affichage,
> eux, sont intacts dans le code et chargés par le `.toc` — mais **jamais éprouvés sur Forever**
> (aucun relevé LFW dans `docs/verif-registre.md`).

## Le problème

Un enchanteur poireaute à Orgrimmar et veut faire savoir qu'il prend du travail. C'est la
fonctionnalité LFW : sortie en v1.15.0 (se déclarer dispo dans UN métier), enrichie en v1.18.0
(dire ce qu'on offre : composants, commission) puis v1.19.0 (proposer des recettes précises).

Au passage Era vers Forever, **l'entrée a disparu.** Pas le moteur : l'entrée.

Sur Camelot on ne remplace plus la fenêtre de métier, on s'y greffe. `PW:IsEnabled()` rend `false`
en dur (`_ProfWindow_Camelot.lua`), notre fenêtre devient une **colonne encastrée** dans la fenêtre
native, et `sizeColumn` la fait tourner en mode compact (`self:_ApplyMode(true)`). Or le bouton est
masqué exactement sur ce mode, dans `PW:_SyncLFWBtn` (`_ProfWindow.lua`) :

```lua
local show = self.profKey and not self.rerollKey and not self._compact and D and D.SetLFW
```

Trois choses tombent ensemble, parce que toutes les trois étaient construites dans la vue custom :

1. **le bouton « Chercher du travail »**, posé dans l'en-tête de la fenêtre custom (`_BuildHeader`) —
   en-tête que la greffe dépouille de toute façon ;
2. **l'engrenage et son panneau d'offre** : `_BuildLFWGear` s'ancre *sur ce bouton*, et
   `_SyncLFWConfig` suit la même portée. Plus de bouton, plus d'engrenage, plus de panneau ;
3. **la colonne de cases « proposer cette recette »** (`row.lfwChk`), qui vit sur les lignes de la
   liste de recettes CUSTOM — liste qui ne s'affiche plus du tout, la native l'ayant remplacée.

Ce qu'il reste aujourd'hui sur Forever : `/co lfw <métier>` pour s'allumer et s'éteindre. Et **rien
du tout** pour régler son offre. La conséquence n'est pas seulement une gêne : `db.lfwOffer`
persiste et continue d'être diffusée telle quelle, donc **un joueur qui avait réglé une commission
sur Era la diffuse encore sur Forever sans pouvoir la changer**.

Enfin, tout l'étage réception — plaque, badge `[Dispo]`, infobulle monde — n'a jamais été vu
fonctionner sur cette cible. Il est plausible qu'il marche ; ce n'est pas un fait.

## Ce qu'on veut

Côté **artisan** (celui qui émet) :

1. J'ouvre un de mes métiers. Dans la colonne COC de la fenêtre native, je trouve « Chercher du
   travail » : un clic me déclare dispo pour CE métier, un second m'éteint, et le contrôle dit son
   état sans que j'aie à le survoler.
2. Au même endroit, je règle mon **offre** pour ce métier : je fournis les composants de base, je
   fournis tel réactif précis, je demande telle commission par craft, je ne fournis que si le plan
   me fait progresser. Réglable **même LFW éteint** — on prépare son offre avant de s'allumer.
3. Je peux désigner les **recettes précises** que je propose, choisies parmi celles que je connais.
4. Si je pars en AFK complet, je disparais du radar des autres tout seul. Personne ne doit se
   déplacer pour un artisan absent.
5. Mon choix survit à la déconnexion et se ré-annonce au login.

Côté **passant** (celui qui reçoit) :

6. Un artisan dispo qui passe devant moi porte **l'icône de son métier au-dessus de sa plaque**,
   avec une pièce s'il demande une commission, un sac s'il fournit des composants, et le nom de la
   première recette qu'il propose (`+N` s'il y en a d'autres). Rendu identique à celui d'avant —
   arbitrage du user du 2026-09-23.
7. Il porte un `[Dispo]` vert dans l'annuaire, et le survol de sa ligne donne le détail de l'offre.
8. Le survol du joueur **dans le monde** donne les mêmes lignes que l'annuaire.
9. Un joueur qui écrit « LFW forge » dans le canal Commerce **sans avoir l'addon** apparaît lui
   aussi comme dispo, marqué comme vu sans l'addon.

## Ce qu'on NE fait PAS

- **On ne rouvre pas la vue custom 3 colonnes sur Camelot.** Elle a été écrite contre la fenêtre
  rudimentaire de l'Era ; celle de Forever est la fenêtre retail moderne, elle est meilleure que la
  nôtre. Faire revenir le bouton en ressuscitant la vue custom serait rendre deux fenêtres pour un
  bouton.
- **On ne touche pas au fil.** Les verbes `LFW` / `LFO` / `LFR` sont déployés chez des clients qu'on
  ne met pas à jour ; leur format est gelé (section Contrat). Ce chantier est une affaire d'UI et de
  vérification, pas de protocole.
- **On ne greffe pas de case à cocher sur les lignes de recettes de Blizzard.** Le gain (choisir une
  recette là où on la lit) ne paie pas le risque : lignes recyclées par un pool qu'on ne contrôle
  pas, et écriture dans un cadre natif à chaque rafraîchissement. Les recettes proposées se
  choisissent dans NOTRE surface (voir arbitrage B).
- **On ne change pas `LFWChat`** (scan du chat visible) : il ne dépend d'aucune fenêtre et marche
  déjà. Il est dans le périmètre de VÉRIFICATION, pas de réécriture.
- **Pas de nouvelle portée.** LFW reste royaume, un seul métier à la fois. Pas de portée zone, pas
  de portée groupe, pas de relais.
- **On ne touche pas à la vue Profit ici.** Elle a sa spec ET son code, sur la branche
  `feat/profit-forever` : **`docs/specs/rentabilite-forever.md`** (2026-09-21, « implémentée, non
  validée en jeu ») et `_ProfWindow_DockProfit.lua`. Livrer LFW n'en dépend pas ; en revanche
  **les deux ajoutent une entrée à `VIEWS`**, et la branche Profit le fait déjà. Ordre imposé :
  **la branche Profit revient en premier** (elle a 28 commits de retard et précède le renommage
  `COC.LazyGold` → `COC.Profit`), LFW s'insère ensuite dans une rangée déjà passée à quatre. Ne
  jamais modifier `VIEWS` des deux côtés en parallèle.
- **Pas d'Era.** La branche `era` est gelée en v1.30.0 ; rien de ce chantier ne la vise.

## Cas particuliers

**Combat.** Greffée dans le panneau natif, la colonne est PROTÉGÉE comme lui : `Show`, `Hide`,
`SetPoint`, `SetWidth` y sont refusés en combat (relevé du 2026-09-19, 15 blocages en une session).
Un contrôle LFW qui apparaît ou disparaît selon le métier ouvert doit donc suivre la discipline
maison : mémoriser l'état voulu, ne rien appeler en combat, rejouer à `PLAYER_REGEN_ENABLED`.
La bascule LFW elle-même (émission réseau) n'est pas concernée — elle n'écrit dans aucune frame.

**Page d'ensemble des métiers.** Pas de métier courant, donc rien à proposer : la colonne ne s'y
greffe pas (`onRecipesPage`). Le contrôle LFW n'existe pas sur cette page.

**Métier de récolte** (Herboristerie, Dépeçage, Secourisme) : aucune fenêtre native ne s'ouvre, donc
aucune greffe — COC ouvre sa vue compacte autonome, qui est le **même cadre** dans un autre mode. Par
l'arbitrage C, la vue LFW y est présente à l'identique : même surface, même code, aucun cas à part.

**Vue reroll** (métiers d'un autre perso du compte) : pas mon personnage connecté, donc pas de
bouton — comportement actuel, à conserver (`self.rerollKey`).

**Plaques amies en instance.** Blizzard les réserve au jeu lui-même : elles sont *forbidden* et
invisibles au code addon insécure. Pas de badge en donjon, aucune parade, par design. À dire dans
l'aide plutôt qu'à corriger.

**CVar `nameplateShowFriends`.** Les artisans LFW sont des amis / même faction : plaque amie
éteinte, pas de badge. Ce n'est pas une panne — et c'est exactement le genre de chose qu'un testeur
prend pour une panne. Tout relevé de vérification doit nommer l'état de ce CVar.

**Nom secret.** Une plaque d'unité est précisément le contexte où `UnitName` peut rendre une valeur
SECRÈTE. Le nom sert ensuite de clé dans le roster et dans la table LFW : il passe par
`COC.Api.UnitNameSafe`, qui traite la secrète comme une ABSENCE de nom. Pas de badge sur cette
plaque, et rien ne fuit plus loin.

**Offre héritée de l'Era.** Une `db.lfwOffer` réglée avant le portage est diffusée aujourd'hui sans
qu'on puisse la relire. Au retour de l'UI, elle doit s'afficher telle qu'elle est — pas être écrasée
par des valeurs par défaut au premier affichage du panneau.

**Réseau muet au login.** L'émission n'est jamais sous *hardware event* : elle passe par la file
(`QueueText`), drainée au prochain clic ou à la prochaine touche. Un envoi direct lèverait
`ADDON_ACTION_BLOCKED` au login (corrigé en v1.17.1 — ne pas le refaire).

## Décisions

- **2026-09-23 — user :** le rendu au-dessus de la plaque est reconstitué **à l'identique** : icône
  de métier 22 px, pièce si commission, sac si composants fournis, nom de la 1re recette proposée
  à droite avec `+N`. Pas de refonte visuelle dans ce chantier.
- **2026-09-23 :** le fil est **gelé**. Aucun verbe, aucun champ, aucun cap ne bouge (section
  Contrat). Ça vaut aussi pour les caps de décodage, qui protègent le récepteur.
- **2026-09-23 :** le chantier commence par une **mesure**, pas par du code. Le moteur est
  peut-être intact sur Forever ; réécrire ce qui marche déjà coûte et casse. Voir Plan, T0.

- **2026-09-23 — user (arbitrage B) :** les recettes proposées se choisissent dans un **sélecteur
  cherchable à l'intérieur de la vue LFW**, jumeau de celui des réactifs qui existe déjà
  (`_BuildLFWPicker`), alimenté par les recettes apprises du métier ouvert. Pas de case greffée sur
  les lignes de Blizzard.
- **2026-09-23 — user (arbitrage C) :** **oui, tous les métiers ont la même UI.** La vue LFW est la
  même surface et le même code, que le métier ouvre une fenêtre native ou non. Pas de traitement
  particulier pour la récolte.

- **2026-09-23 — user (arbitrage A) :** la rangée passera à **cinq onglets** — les trois actuels,
  plus **Profit** (à réécrire) et plus **Travail** (LFW). Profit n'est pas un ornement : c'est le
  **remplaçant de LazyGold**, décommissionné, donc la page où l'on vient chercher ce qui rapporte.
  Il mérite sa propre spec et ne sera pas traité ici (voir « Ce qu'on NE fait PAS »).

Inventaire réel, relevé le 2026-09-23 sur `master` *et* sur la copie déployée (identiques) :

| | Onglet | État |
|---|---|---|
| 1 | Commandes | vivant |
| 2 | Plan de route | vivant |
| 3 | Manquantes | vivant |
| — | Échange (`dockView = "trade"`) | vivant mais **transitoire** : il prend toute la colonne pendant un échange et **tait la rangée** — ce n'est pas une languette |
| — | Profit | **codé, pas sur `main`** — branche `feat/profit-forever` |

Sur `main`, la rentabilité n'est **pas** un onglet : c'est une couche de prix diffusée *dans* les
autres vues (prix dans la liste de recettes, coût dans Manquantes, coût par point dans Plan de route,
marge sur la carte de commande) plus deux boutons d'outils. L'**oracle** qui l'alimente a sa spec,
`docs/specs/prix-maison.md`, **close et éprouvée en jeu le 2026-09-23**.

La **page** Profit, elle, existe bel et bien — mais sur la branche `feat/profit-forever` du dépôt
COC, jamais fusionnée : un commit `2691987`, `_ProfWindow_DockProfit.lua` (214 lignes), l'entrée
`VIEWS`, un backend `Craft_Mainline` qui lit le schéma de recette sur le CLIENT plutôt que dans nos
données (ce qui referme une partie des 357 recettes sans objet produit), et sa propre spec
`docs/specs/rentabilite-forever.md` (2026-09-21, portes déterministes passées, critères en jeu en
attente). La branche a **28 commits de retard** et précède le renommage `COC.LazyGold` →
`COC.Profit` : elle demande une remise à niveau avant de revenir, pas une fusion telle quelle.

## La rangée à cinq — design

**D'abord une idée fausse à écarter : une rangée trop large ne se fait PAS rogner.** `sizeColumn`
calcule `colW = max(largeur du cadre, _ViewTabsWidth())` puis élargit le cadre natif d'autant. Une
languette de plus ne coupe rien : **elle élargit la colonne, et la fenêtre de métier avec elle.** Le
coût n'est donc pas un affichage cassé, c'est de la largeur d'écran prise et un chevauchement de
panneaux plus probable (cosmétique, déjà accepté au 2026-09-19). La question n'est pas « ça rentre
ou pas » mais « combien de largeur accepte-t-on ».

**Ensuite, ce que la rangée mélange.** Quatre de ces cinq choses sont des **pages qu'on lit** :
Commandes, Rentabilité, Plan de route, Manquantes. La cinquième, Travail, est d'une autre nature :
c'est un **état qu'on tient** (je suis dispo, ou non) plus un **formulaire qu'on remplit rarement**.
Cette asymétrie n'est pas théorique, elle a une conséquence directe : **l'état LFW doit rester
visible quand on ne regarde pas sa page.** Tout le mécanisme de TTL et d'anti-leurre AFK existe
précisément parce qu'on oublie qu'on est annoncé. Un état qui ne se voit que sur son propre onglet
est un état qu'on oublie.

**Ce qui écarte deux solutions d'emblée**, sur des relevés déjà payés :

- **Pas d'onglets en icônes seules.** Déjà tenté dans cette colonne, déjà rejeté : « deux icônes
  16 px posées dans une bande vide se lisaient comme des boutons secondaires oubliés là, et les
  désaturer pour dire *inactive* les faisait passer pour INDISPONIBLES » (relevé sur capture,
  2026-09-19). Une languette sélectionnée dit la même chose sans ambiguïté.
- **Pas de menu déroulant à la place de la rangée.** `UIDropDownMenu` est l'une des deux causes
  PROUVÉES du taint des barres d'action sur Forever. Elle est corrigée, mais on n'ajoute pas un
  déroulant là où une rangée suffit.

**Pas non plus de rangée sur deux lignes** : `_TabTop()` et `_BodyTop()` dérivent tous les deux de la
hauteur d'UNE rangée ; une seconde ligne oblige à retoucher cette dérivation et mange de la hauteur
de liste dans une colonne qui n'en a pas de trop, pour un gain de largeur qu'on n'a pas besoin de
chercher.

### Retenu : cinq languettes, dont une qui porte son état

```
[ Commandes ][ Profit ][ Route ][ Manquantes ][ ● Dispo ]
```

- **Ordre par nature** : le carnet, l'argent, les deux pages de progression, puis moi. Travail en
  bout de rangée, là où l'œil le retrouve sans le chercher.
- **Le libellé est « Profit », pas « Rentabilité »** — arbitrage du user du **2026-09-21**, pris pour
  exactement la raison de largeur redécrite ici : le mot long coûtait ~90 px de fenêtre native pour
  la même information. « Rentabilité » reste le titre de la section du panneau d'info.
  (`prix-maison.md` dit « Rentabilité » côté joueur ; sur la **languette**, la décision plus récente
  et plus précise l'emporte.)
- **La languette Travail porte l'état.** Une languette non sélectionnée reste affichée : elle est
  donc le bon support pour un état persistant. Éteint elle dit `Travail` ; allumé elle dit
  `● Dispo` en vert, quelle que soit la vue affichée. On résout la visibilité **sans** dépenser une
  surface de plus, et sans icône nue.
- **`Plan de route` devient `Route`** dans la languette. C'est le libellé qui coûte le plus cher
  pour ce qu'il ajoute, et le titre de la vue continue de dire le mot entier.
- **Le contenu de la vue Travail** : l'interrupteur en tête, puis le réglage d'offre existant
  (`_ProfWindow_LFW.lua` quasi tel quel — il a perdu son hôte, pas sa logique), puis les deux
  sélecteurs cherchables, réactifs et recettes.

**Seul point laissé à la mesure (ce n'est pas un arbitrage ouvert) :** la largeur réelle de la rangée
à cinq. `/co geo` la relève, et la rangée `vues` sort déjà sa `marge` droite (négative = ça déborde).
Le relever **avant/après**. Le design ne change pas selon le résultat ; seul un éventuel
raccourcissement de libellé en dépendrait.

**Une seule chose se mesure à T0**, et elle est cheap : `_ViewTabsWidth()` à cinq languettes, contre
la largeur actuelle de la colonne. Elle dit combien de pixels la fenêtre de métier gagne réellement.
Le design ci-dessus ne change pas selon le résultat ; seul le repli de libellé en dépend.

## Critères d'acceptation

Émission et réglage :

1. `[humain]` Un métier à moi ouvert dans la fenêtre native, la colonne COC affiche le contrôle
   « Chercher du travail ». Un clic l'allume, le contrôle change d'état visible, un second clic
   l'éteint. *Témoin connu-bon : `/co lfw <métier>` doit produire exactement le même état.*
   Observateur : le user, en jeu.
2. `[humain]` Le réglage de l'offre est atteignable et modifiable **LFW éteint**, et il rouvre sur
   les valeurs réellement enregistrées (témoin : régler une commission, `/reload`, rouvrir).
2 bis. `[humain]` LFW allumé, je bascule sur Commandes : **la languette Travail continue d'afficher
   `● Dispo`**. Je l'éteins, elle redit `Travail`. *Témoin connu-bon : `/co lfw` sans argument
   annonce le même état.* C'est le critère qui justifie le design de la rangée — sans lui, on a
   dépensé une languette pour rien.
3. `[humain]` En Secourisme (aucune fenêtre native), la vue compacte autonome offre le même
   contrôle. Observateur : le user, en jeu.
4. `[humain]` Ouvrir la fenêtre de métier **en plein combat** ne produit aucune erreur rouge et
   aucun `ADDON_ACTION_BLOCKED` imputé à COC ; à la sortie du combat la colonne est complète et le
   contrôle LFW à sa place. *Témoin : `Logs/taint.log` avec `/console taintLog 1`.*
5. `[test]` Encodage et décodage `LFO` et `LFR` inchangés, caps compris. → `tests/test_lfw.lua`
6. `[porte]` Toute chaîne ajoutée est traduite dans les trois overlays. → `check_locale.ps1`

Réception — c'est la moitié qui n'a jamais été vue :

7. `[humain, 2 comptes]` Compte A s'allume LFW dans un métier. Compte B, **plaques amies activées**
   (`nameplateShowFriends`), en zone monde-ouvert, voit l'icône du métier de A au-dessus de sa
   plaque. *Témoin connu-bon : la plaque de A est visible et porte son nom.* Le relevé doit citer
   l'état du CVar.
8. `[humain, 2 comptes]` A règle une commission et coche « composants de base » : B voit la
   **pièce** et le **sac** sur la plaque, et le survol de A dans le monde donne les lignes d'offre.
9. `[humain, 2 comptes]` A propose deux recettes : la plaque de A montre le nom de la première et
   `+1`. *Témoin : les mêmes noms dans l'infobulle de survol.*
10. `[humain, 2 comptes]` A apparaît `[Dispo]` dans l'annuaire de B, et le survol de la ligne donne
    les mêmes lignes d'offre que l'infobulle monde.
11. `[humain, 2 comptes]` A passe en AFK complet et le reste : au bout du TTL, A n'est plus ni
    `[Dispo]` ni badgé chez B. *Périmètre à dire dans le relevé : 20 min d'attente réelle, ou bien
    on ne l'écrit pas.*
12. `[humain]` Un joueur SANS l'addon écrit « LFW forge » dans Commerce : il apparaît dispo chez
    moi, marqué comme vu sans l'addon.
13. `[agent]` Aucune écriture dans le système de panneaux, aucun appel à une API Classic morte,
    aucun global Classic supposé vivant. → `api-gotcha-reviewer`

Ce qui **ne compte pas** comme critère : une `SavedVariable` correctement remplie, une ligne
correctement mise en file, un test headless au vert. Ça prouve qu'une chose est *déclarée*.

## Contrat (gelé — déjà déployé chez des clients qu'on ne met pas à jour)

Trois verbes séparés sur le canal-texte, portée royaume. Séparés **à dessein** : étendre `LFW|on`
aurait cassé le pattern ancré des vieux clients, alors qu'un verbe inconnu est ignoré proprement par
`_Dispatch`. Chacun est clé par **SENDER** (l'émetteur réel, non falsifiable par le transport) :
on ne peut déclarer QUE soi-même.

```
LFW|on|<profKey>          se déclarer dispo dans un métier
LFW|off                   couper (purge tout : offre et recettes comprises)
LFO|<profKey>|<flags>|<feeCopper>|<id1,id2,...>     offre — flags dans {B, S}, « - » si aucun
LFR|<profKey>|<sid1,sid2,...>                       recettes proposées (spellID de recette)
```

- `profKey` = clé canonique, **lettres ET espaces** (« First Aid » est valide). Un `%a+` seul casse
  silencieusement toute offre Secourisme — bug attrapé en revue avant la v1.18.0, à ne pas refaire.
- `flags` : `B` = fournit les composants de base, `S` = seulement si le plan fait progresser.
- Caps, appliqués à l'encodage **et** au décodage (un émetteur trafiqué ne gonfle rien) :
  15 objets, 12 recettes, commission ≤ 9 999 999 cuivre.
- Wire 100 % neutre en langue : identifiants, cuivre, lettres. Jamais un nom traduit.
- **Un `LFO` seul, ou un `LFR` seul, VAUT `LFW|on`** : les lignes partent en file FIFO et une perte
  est possible. `e.offer` et `e.recipes` sont des champs DISJOINTS de l'entrée → ni l'ordre
  d'arrivée ni la perte d'une des deux ne s'écrasent l'un l'autre.
- Côté récepteur, `Dir.lfw[nom] = { prof, expiry, offer, recipes, viaChat }` est **RUNTIME** (statut
  transitoire, non persisté), purgé paresseusement à la lecture.
- TTL 20 min, ré-émission toutes les 8 min, **stoppée si `UnitIsAFK("player")`** : c'est tout le
  mécanisme anti-leurre. Une première tentative de « liveness par présence » a été REVERT — elle
  gardait justement l'AFK visible.
- Diffusion débouncée 5 s côté config (le panneau sauve à chaque coche).

Persisté chez l'émetteur : `COC.db.lfw = { prof }` et `COC.db.lfwOffer[profKey] =
{ basics, skillUpOnly, fee, items, recipes }`. Ce schéma non plus ne bouge pas : une offre réglée
avant le portage doit se relire après.

## Plan (daté du 2026-09-23 — meurt quand c'est fait)

**T0 — mesurer avant d'écrire.** Un client, Forever. `/co lfw <métier>` pour s'allumer, puis
injecter un LFW d'un tiers (`COCMonitor`, `/cocm lfw <nom> <métier> [fee] [ids]` — chemin réel
`Directory:OnLFW` / `OnLFO`) et regarder une plaque. On cherche trois faits, pas une impression :
la plaque porte-t-elle l'icône ; `plate:IsProtected()` rend quoi ; `GetNamePlates()` rend-il bien
les plaques amies. Issue : soit le moteur d'affichage est intact et T2 se réduit à un relevé, soit
il est cassé et on sait **où**. Aucune ligne de code avant ça.

Même séance, une mesure de plus, qui ne coûte rien : `_ViewTabsWidth()` à cinq languettes contre la
largeur actuelle de la colonne (`/co geo` la rapporte). Elle ne change pas le design retenu, elle
décide seulement du repli de libellé « Rentabilité » → « Gains ».

**T1 — rendre l'entrée.** Une vue LFW dans la rangée d'onglets, contenant la bascule, le réglage de
l'offre et le sélecteur de recettes (arbitrages B et C tranchés ; A conditionne seulement la forme de
la rangée). Réutiliser `_ProfWindow_LFW.lua` (checks, commission, sélecteur cherchable) plutôt que de
le réécrire : ce fichier n'a pas de dette, il a perdu son hôte. Critères 1, 2, 3, 6.

**T2 — la discipline de combat.** Critère 4, avec le `taintLog` à l'appui.

**T3 — le banc 2 comptes.** Critères 7 à 12, d'une traite, avec le CVar noté. Relevé dans
`docs/verif-registre.md`, et **seulement ce qui a été observé** : si le TTL AFK n'a pas été attendu
20 minutes, le relevé le dit.

**T4 — clôture.** Revues `api-gotcha-reviewer` et `locale-auditor`, entrée News / CHANGELOG, bump,
puis cette spec passe en **implémentée** avec sa date.

## Renvois

- Skill **coc-native-ui** — le kit de chrome natif et les pièges de greffe.
- Skill **wow-classic-addon-dev** — architecture, pièges d'API Forever.
- Skill **human-verification** — pourquoi les critères 7 à 12 demandent un témoin connu-bon.
- Skill **coc-release-check** — le pré-vol avant de sortir ça.
- `docs/specs/rentabilite-forever.md` (sur `feat/profit-forever`) — l'autre chantier de la même
  rangée, déjà codé. Il passe en premier sur `VIEWS`.
- `docs/specs/prix-maison.md` — l'oracle de prix (close). Elle fixe « Rentabilité » comme mot côté
  joueur, et c'est elle qu'il faudrait amender si la languette devait s'appeler autrement.
- `docs/verif-registre.md` — où atterrissent les relevés de T0 et T3.
- `docs/specs/enchant-echange-forever.md` — même forme de chantier (une fonctionnalité Era remise
  debout sur Forever), utile comme précédent.
- Agent **craftlink-protocol-reviewer** — si jamais le fil devait bouger, ce qu'on a exclu.
