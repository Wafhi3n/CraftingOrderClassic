# Plan : sortir COC de la couche de compatibilité de Blizzard

> État : **plan, rien de codé** · Rédigé le 2026-10-12 · Demande du user le 2026-10-12, après la revue
> de l'addon tiers SmokeSignal (qui dépend des mêmes alias)
> Cible : WoW: Forever / Camelot (16001) · Source Blizzard lue : 1.60.1 build 70338
> (`Documentation\wow-ui-source-forever`) · Inventaire fait sur `main@c307d34` (COC) et `main` (CraftLink)
> Dépôts : CraftingOrderClassic (7 endroits) + CraftLink (1 retouche)

## Pourquoi

Une partie des fonctions globales que COC appelle n'existe plus dans le client que comme **alias de
compatibilité**. Blizzard les pose dans des modules `Blizzard_Deprecated*`, et chaque fichier commence par :

```lua
if not GetCVarBool("loadDeprecationFallbacks") then
	return;
end
```

Le `.toc` de ces modules dit : « They will be removed at the next expansion. Upgrade your code to the new
APIs as soon as possible. »

Fichiers concernés pour COC :
- `Blizzard_DeprecatedChatInfo/Deprecated_ChatInfo.lua` : `SendChatMessage` (une enveloppe autour de
  `C_ChatInfo.SendChatMessage`) ;
- `Blizzard_DeprecatedChatInfo/Deprecated_ChatFrame.lua` : `ChatEdit_InsertLink`, `ChatFrame_SendTell`,
  `ChatFrame_AddMessageEventFilter`, `ChatFrame_RemoveChannel`, `NUM_CHAT_WINDOWS`… (114 alias vers
  `ChatFrameUtil.*` et `ChatFrameMixin.*`) ;
- `Blizzard_DeprecatedSpellBook/Deprecated_SpellBook.lua` : `IsSpellKnown`, `IsPlayerSpell` ;
- `Blizzard_DeprecatedAutoComplete/Deprecated_AutoComplete.lua` : `GetAutoCompleteRealms` ;
- `Deprecated_PaperDoll/Deprecated_PaperDoll.lua` : `GetInventorySlotInfo`.

**Aujourd'hui, rien n'est cassé.** Le réglage est actif sur les clients du banc : `Config.wtf` ne le
fixe pas (valeur par défaut), et l'ASKE de COC, qui passe par le `SendChatMessage` global, est validé à
deux comptes. Le risque est pour demain, à un patch ou à l'extension, ou chez un joueur qui coupe le
réglage. Selon l'endroit, COC lèverait alors une erreur au clic ou perdrait une fonction **en silence**
(détail dans le tableau).

À corriger au passage : le commentaire de `CraftingOrderClassic_Compat.lua` (au-dessus de
`A.GetInventorySlotInfo`) dit la globale « VIVANTE ». Elle l'est, mais seulement par
`Deprecated_PaperDoll`. Le skill public dit la même chose de `SendChatMessage` et
`GetInventorySlotInfo` : c'est à rectifier là-bas (voir « Hors périmètre »).

## Inventaire

Méthode : les 462 noms que définissent les modules `*eprecat*` de la source Forever, cherchés dans
COC et dans CraftLink (`*.lua`, appel nu ou par `_G.X` / `_G["X"]`, plus `*.xml` et `*.toc`),
commentaires et `Data/` exclus. Une recherche ne prouve pas qu'il n'en reste aucun : l'étape 5 le
prouve en jeu.

### À migrer : 7 endroits qui n'appellent QUE l'alias

| # | Où (fonction) | Appel | Si l'alias disparaît | Remplaçant |
|---|---|---|---|---|
| 1 | `CraftingOrderClassic_ShareReagents.lua`, `SR:_DoSend` (l. 142) | `SendChatMessage(line, chatType, nil, chanIdx)` | erreur Lua au clic « Envoyer » | `C_ChatInfo.SendChatMessage` |
| 2 | `CraftingOrderClassic_LootAlert.lua`, `Loot:GiftCmd` (l. 101) | `SendChatMessage(…, "WHISPER", nil, target)` | erreur Lua au clic | `C_ChatInfo.SendChatMessage` |
| 3 | `CraftingOrderClassic_Enchant_Trade_Ask.lua`, `Ask:Request` (l. 70 et 81) | garde `SendChatMessage` puis appel | annulation muette, et la trace ment : « aucun partenaire d'échange lisible » | `C_ChatInfo.SendChatMessage`, et séparer les deux causes dans la garde |
| 4 | `Directory_Community.lua`, `whisperSelf` (l. 211 et 214) | `_G.SendChatMessage` sous garde | rend `false` sans rien dire : le lien d'invitation ne part pas | `C_ChatInfo.SendChatMessage` |
| 5 | `CraftingOrderClassic_ProfWindow_DockProfit.lua`, `profitRow` (l. 133) ; `…_DockViews.lua`, `missRow` (l. 287) ; `CraftingOrderClassic_Tracker_Rows.lua`, `r.onClick` (l. 158) | `ChatEdit_InsertLink(link)` sous garde | maj-clic n'insère plus le lien, en silence | `ChatFrameUtil.InsertLink(link)` |
| 6 | `CraftingOrderClassic_ProfWindow_Orders_Card.lua`, `PW:_CardActions` (l. 195) ; `CraftingOrderClassic_UI_Artisans.lua`, `UI:_ArtRowButtons` (l. 407) | `ChatFrame_SendTell(name)` sous garde | bouton « Chuchoter » inerte | `ChatFrameUtil.SendTell(name)` |
| 7 | `CraftingOrderClassic_Sources.lua`, `S:MissingRecipes` (l. 340) | `IsSpellKnown(spellID)` sous garde | la liste des recettes manquantes ne repose plus que sur `known[]` de CraftLink | `C_SpellBook.IsSpellInSpellBook(spellID, Enum.SpellBookSpellBank.Player, false)` |

⚠️ Ligne 7 : l'alias passe `includeOverrides = false`, alors que la doc générée donne à ce paramètre une
valeur par défaut **`true`** (`SpellBookDocumentation.lua`, `IsSpellInSpellBook`). Il faut le passer
explicitement, sinon le comportement change sans bruit. Autre question, **ouverte et à mesurer** : une
recette apprise compte-t-elle comme « dans le grimoire » ? Si non, cette ligne ne sert à rien
aujourd'hui non plus, et `C_SpellBook.IsSpellKnown` serait peut-être le bon appel. On garde
l'équivalent exact tant que ce n'est pas mesuré.

### Déjà migrés : la moderne d'abord, l'alias en secours (rien à faire)

- `CraftingOrderClassic_Compat.lua` : `A.GetInventorySlotInfo` (`pick`) et `A.AddChatFilter` ;
- `Orders_AnnounceSend.lua`, `write` : `C_ChatInfo.SendChatMessage` d'abord ;
- `Orders_AnnounceRecv.lua`, `sameRealmGroup`, et `CraftLink_Sender.lua` : `C_AutoComplete` d'abord ;
- `CraftLink_Transport.lua` : l'envoi (`C_ChatInfo` d'abord), le filtre (`ChatFrameUtil` d'abord), et
  `hideChannelFromFrames`, qui prend `cf.RemoveChannel` avant `ChatFrame_RemoveChannel`.

Le secours ne coûte rien et garde le style de `pick`. On pourra le retirer un jour, sans urgence.

### Une retouche dans CraftLink

`CraftLink_Transport.lua`, `hideChannelFromFrames` : `for i = 1, (NUM_CHAT_WINDOWS or 10)` sur
`_G["ChatFrame" .. i]`. `NUM_CHAT_WINDOWS` n'est qu'un alias. Le `or 10` empêche toute casse, mais la
boucle rate les fenêtres de chuchotement temporaires (au-delà de `ChatFrame10`).
Remplaçant : `ChatFrameUtil.ForEachChatFrame(fn)` (`Blizzard_ChatFrameBase/Shared/ChatFrameUtil.lua`),
qui parcourt `CHAT_FRAMES`, temporaires comprises.

C'est le dépôt **CraftLink**, pas COC. Il faut une branche de même nom dans les deux dépôts. Ensuite on
resynchronise la copie embarquée (`Libs/CraftLink-1.0`) et on vérifie par
`diff -r --strip-trailing-cr` entre `CraftLink\CraftLink-1.0` et la copie embarquée.

### Vérifié propre (inutile de re-chercher)

Ce sont les pièges trouvés dans SmokeSignal, cherchés aussi dans COC et CraftLink :
- aucun nom déprécié dans les `.xml` ni les `.toc` ;
- le filtre « No player named » (`Directory_Presence.lua`, `Dir:_InstallWhisperErrorFilter`) teste
  `COC.Api.IsSecret(msg)` avant toute lecture ;
- aucun `GetChannelRosterInfo` ni `GetChannelDisplayInfo` (SmokeSignal y passe le numéro de canal au
  lieu de l'index d'affichage) ;
- aucun type de lien maison et aucun crochet `SetItemRef` (la leçon du `clubTicket`, rappelée dans
  `Directory_Community.lua`) ;
- une seule prise du clavier : `CraftLink_TextQueue.lua`, `_InstallInputDrain`. Le cadre est créé une
  fois, au démarrage de la lib (`CraftLink_Transport.lua`), et la propagation est réglée à `true` une
  fois pour toutes. Rien n'est donc rappelé en combat ;
- aucune épingle de carte (`AcquirePin` appelle `SetPassThroughButtons`, fonction protégée).

Autres addons actifs : LeyLines n'utilise aucun alias. `SerialBuffer_Buffs.lua` appelle
`IsPlayerSpell` seulement en secours de `C_SpellBook.IsSpellKnown`. L'alias fait exactement le même
appel, donc ce secours est du code mort, à retirer quand on y repasse.

## Étapes

1. **Branche de code** `fix/sortie-depreciees` dans COC (et la même dans CraftLink pour l'étape 3).
   Cette branche-ci (`docs/plan-migration-depreciees`) ne porte que le plan.
2. **Les aides dans `CraftingOrderClassic_Compat.lua`**, dans le style du fichier :
   - `A.SendChatMessage` : `pick(C_ChatInfo and C_ChatInfo.SendChatMessage, _G.SendChatMessage)` ;
   - `A.InsertChatLink(link)` et `A.SendTell(name)` : chercher `ChatFrameUtil.InsertLink` /
     `ChatFrameUtil.SendTell` **à l'appel**, pas au chargement. Une capture par `pick` figerait la
     fonction d'origine et contournerait les crochets qu'un autre addon pose plus tard sur
     `ChatFrameUtil` ;
   - `A.IsSpellInSpellBook(spellID)` : `includeOverrides = false` écrit en dur, `IsSpellKnown` en secours ;
   - rectifier le commentaire « VIVANTE » de `A.GetInventorySlotInfo`.
   Puis faire passer les 7 endroits par ces aides. Pour la ligne 3, la garde dit laquelle des deux
   causes l'arrête.
3. **CraftLink** : `ChatFrameUtil.ForEachChatFrame` dans `hideChannelFromFrames`, puis synchroniser la
   copie embarquée et vérifier le diff.
4. **Les quatre portes** (`.\deploy.ps1 -Check`), plus un test sans client : un faux client **sans**
   les alias (`SendChatMessage`, `ChatEdit_InsertLink`, `ChatFrame_SendTell`, `IsSpellKnown` à `nil`).
   Il vérifie que chaque aide atteint la fonction moderne. Rappel de la règle de `tests\` : ce test
   n'arrive sur `master` que le jour où la branche de COC est fusionnée.
5. **La preuve en jeu**, au banc (`.\deploy.ps1 -Banc fix/sortie-depreciees`) :
   1. n'activer que nos addons, plus `!BugGrabber` et `BugSack` pour lire les erreurs : Questie,
      Auctionator et les autres peuvent dépendre des alias, et ce test n'est pas le leur ;
   2. `/console loadDeprecationFallbacks 0`, puis `/reload`. Les modules lisent le réglage à leur
      chargement. Que `/reload` suffise est **à confirmer** : `/dump SendChatMessage` doit rendre `nil` ;
   3. refaire chaque geste touché : envoi des réactifs, don de LootAlert, ASKE, chuchotement à soi du
      lien d'invitation, maj-clic d'un lien dans les deux docks et dans le suivi, les deux boutons
      « Chuchoter », la liste des recettes manquantes ; puis `!BugGrabber` doit être vide de COC et de
      CraftLink ;
   4. remettre `/console loadDeprecationFallbacks 1`, puis `/reload`. Le réglage est gardé dans
      `WTF\Config.wtf`, et ce dossier sert aux deux comptes du banc : vérifier qu'il n'y contient plus
      `loadDeprecationFallbacks "0"`, sinon l'autre compte démarre sans les alias ;
   5. n'écrire dans `docs/verif-registre.md` que ce qui a été vu.
6. **Facultatif, un garde-fou** : un test de `tests\` qui cherche les noms dépréciés nus dans COC.
   La liste peut se générer depuis `Documentation\` à chaque maj du client. Même règle de date
   d'arrivée sur `master` qu'à l'étape 4.

## Des API récentes qui peuvent nous servir

Toutes **lues dans la source 70338, jamais vues en jeu**. Chacune passe par une sonde avant toute spec.

### 1. Savoir tout de suite si un pair est joignable : `C_ChatInfo.RequestCanLocalWhisperTarget`

- **Ce que dit la source** : `RequestCanLocalWhisperTarget(guid)` déclenche
  `CAN_LOCAL_WHISPER_TARGET_RESPONSE(guid, status)`, avec `Enum.ChatWhisperTargetStatus` =
  `CanWhisper` (0), `CanWhisperGuild` (1), `Offline` (2), `WrongFaction` (3). Blizzard s'en sert dans
  ses commandes d'artisanat pour griser « Chuchoter au client »
  (`Blizzard_Professions/Blizzard_ProfessionsCrafterOrderView.lua`, `SetWhisperCustomerStatus`).
- **Ce que ça apporterait** : aujourd'hui, un pair parti ne se découvre qu'au « No player named »,
  ~110 s après l'envoi (`Directory_Presence.lua`). Une réponse immédiate servirait la pastille à trois
  états, éviterait d'écrire « à tous » à un absent, et permettrait de griser nos boutons « Chuchoter ».
- **Préalables** :
  - la fonction prend un **GUID**, or `CHAT_MSG_ADDON` n'en porte pas et COC ne garde aujourd'hui aucun
    GUID de pair ;
  - les sources possibles : membres d'un cercle (`ClubMemberInfo.guid`), guilde, amis, argument 12 des
    lignes de Commerce (LFW, `#CO`), cible et survol ;
  - mettre son propre GUID dans le bonjour réseau est un **changement de protocole**, donc relu par
    `craftlink-protocol-reviewer`.
- **La sonde** :
  - `/dump C_ChatInfo.RequestCanLocalWhisperTarget` existe-t-il sur Forever ?
  - Répond-elle pour un inconnu, pour un perso d'un autre royaume (4618 ↔ 4620), pour un perso
    déconnecté ?
  - Quel délai ? Que deviennent deux demandes de suite ? L'événement est marqué `UniqueEvent`, et des
    réponses pourraient se fondre.

### 2. Rendre cliquables nos lignes de chat : liens `addon:`

- **Ce que dit la source** : un lien `|Haddon:CraftingOrderClassic:<action>|h[texte]|h` est traité par le
  gestionnaire `LinkTypes.AddOn` (`Blizzard_UIPanels_Game/Shared/ItemRefHandlersShared.lua`). Celui-ci
  émet `EventRegistry` « SetItemRef », et `CallbackRegistryMixin:TriggerEvent` appelle chaque rappel
  sous `securecallfunction` / `secureexecuterange` (`Blizzard_SharedXMLBase/CallbackRegistry.lua`).
  Notre code s'abonne par `EventRegistry:RegisterCallback("SetItemRef", fn)`.
- **Ce que ça apporterait** : les rares lignes que COC écrit déjà (la ligne après une mise à jour,
  par exemple) pourraient ouvrir l'onglet visé d'un clic. Pas une ligne de plus, donc compatible avec
  la règle du chat sobre.
- **Prudence** : la leçon du `clubTicket` concernait du code d'addon qui **appelait** `SetItemRef`.
  Ici c'est le joueur qui clique, et Blizzard qui nous rappelle. La sonde le confirme : `taintLog 2`,
  un clic sur le lien, puis la fenêtre de métier et un combat. Rien ne doit être imputé à COC.

### 3. Trouver Trade (Services) sans liste de mots traduits

- **Aujourd'hui** : `Orders_AnnounceSend.lua` cherche le canal dans `GetChannelName(i)` avec deux
  listes de mots (`TRADE` = trade, commerce, handel, comercio ; `SERVICE` = servic, dienst).
- **Ce que dit la source** : `C_ChatInfo.GetChannelShortcut(index)` et
  `C_ChatInfo.GetChannelInfoFromIdentifier(nom)` rendent une structure `ChatChannelInfo` (`shortcut`,
  `zoneChannelID`, `channelType`…). `CHAT_MSG_CHANNEL` porte aussi `zoneChannelID` en argument 7,
  marqué **jamais secret**.
- **Ce que ça apporterait** : reconnaître le canal sans dépendre de la langue. Et lire les lignes de
  Commerce sous verrou de chat sans comparer de nom.
- **Ce qu'on sait** : le nom court « Services » a été vu par `GetChannelDisplayInfo`, sur un client
  **anglais** (2026-09-30). Le client du user est `enUS`. Savoir si le raccourci est traduit demande un
  client frFR ou deDE, donc un testeur.
- **La sonde** : `/dump C_ChatInfo.GetChannelInfoFromIdentifier("Trade (Services) - English")` en
  capitale, noter `shortcut` et `zoneChannelID`, puis la même chose sur un autre client de langue.

### 4. Pré-remplir un chuchotement au lieu de l'envoyer : `ChatFrameUtil.SendTellWithMessage`

`ChatFrameUtil.SendTellWithMessage(name, text)` ouvre la barre de chuchotement **déjà remplie**, sans
rien envoyer (`ChatFrameUtil.lua`). C'est un choix pour le user, pas une recommandation :
- le don de LootAlert envoie aujourd'hui le chuchotement d'un clic. Il pourrait seulement le
  préparer, et le joueur l'enverrait lui-même : cohérent avec la règle « pas de spam des joueurs » ;
- le bouton « Chuchoter » d'une commande pourrait préparer « à propos de ta commande [lien] ».

### 5. `ChatFrameUtil.ForEachChatFrame`

C'est l'étape 3 : un simple nettoyage dans CraftLink.

## Hors périmètre

- **Le skill public** (`wow-addon-dev:wow-forever-api`, en anglais, sur une branche de
  `F:\wow-addon-workspace`) dit `SendChatMessage` et `GetInventorySlotInfo` « vivants ». Ils ne le sont
  que par la couche de compatibilité, et c'est à préciser là-bas, avec la référence du fichier
  `Blizzard_Deprecated*`. **Pas fait.**
- La revue de SmokeSignal elle-même : `docs/revue-smokesignal.md` du dépôt d'outillage.
