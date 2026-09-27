# Test — voir le métier d'un autre joueur (lien, lien fabriqué, guilde)

**Durée estimée : 25 minutes**, plus 5 pour la partie guilde (facultative).
**Banc :** les 2 comptes Forever, jamais deux clients du même compte.
**État :** jouée le 2026-09-27, étapes 1 à 6 et 8. Résultats dans le Relevé, en fin de fiche.

- **A** = `101576982#1`, celui qui **regarde** (« Gnomi Short », sans métier au 2026-09-19).
- **B** = `101576982#4`, celui qu'on **regarde** (« Rédemption Wafhien » : Enchantement, Cuisine…).

Si B n'a plus l'Enchantement, remplacer partout `Enchanting` par la clé anglaise du métier lié
(`Cooking`, `Tailoring`…) et « Enchantement » par ce métier.

## La question

On peut lier son métier pour le montrer. Est-ce qu'un addon peut voir le métier de **n'importe
qui**, ou seulement celui des joueurs qui l'ont partagé ? Et en passant : **COC prend-il le métier
d'un autre pour le sien** quand on ouvre un lien ?

## Déjà vérifié dans les sources Forever 1.60.1 — ne pas revérifier

| Fait | Où |
|---|---|
| `GetTradeSkillListLink()` ne prend aucun argument : on ne peut lier que le métier qu'on a **soi-même** ouvert | `Blizzard_ProfessionsCrafting.lua:101` |
| Le bouton « lien » ne s'affiche que si `CanTradeSkillListLink()` répond vrai, et seulement pour son propre métier, en jeu souris-clavier | `Blizzard_ProfessionsCrafting.lua:1053` |
| Aucun code Lua ne traite le clic sur un lien `trade:` : c'est le client qui ouvre la fenêtre | `ItemRef.lua` (`SetItemRef` → `ItemRefTooltip`) |
| Aucune fonction « ouvrir le métier du joueur X » ; `OpenTradeSkill(skillLineID)` ouvre le sien | `TradeSkillUIDocumentation.lua:1098` |
| Guilde : `C_GuildInfo.QueryGuildMemberRecipes(guid, ligne)` et `QueryGuildMembersForRecipe(ligne, recette)`, réservées à la guilde | `GuildInfoDocumentation.lua:261, 272` |
| **COC capte la fenêtre de métier ouverte sans vérifier à qui elle est** : `TRADE_SKILL_SHOW` / `LIST_UPDATE` → `COC:ScanSoon` → `CraftLink:ScanOpenKnown`, qui ajoute les recettes affichées à MES recettes connues et ne les retire jamais. Aucune garde `IsTradeSkillLinked`, guilde ou PNJ | `CraftingOrderClassic.lua:436`, `CraftLink_Recipes.lua:132` |
| En réseau, un receveur refuse les recettes annoncées pour un métier que l'émetteur ne déclare pas | `Directory_Recipes.lua`, `Dir:OnRI` |

Ce que la lecture du code prédit (**une prédiction, pas une observation**) : un enchanteur qui
clique dans le canal Commerce le lien d'un autre enchanteur **s'attribue ses recettes et les
diffuse**. Sans le métier (le cas de A), la pollution reste locale, car les autres la refusent. Mais
elle est sauvegardée, et elle ressortira le jour où A apprendra l'Enchantement.

## Ce que ce test ne prouvera pas

- A et B sont sous **le même Battle.net**. Si le lien fabriqué de l'étape 5 marche, le serveur
  autorise peut-être seulement les persos de son propre compte. Pour conclure « n'importe qui », il
  faudra refaire l'étape 5 sur un 3e joueur, avec son accord.
- Le cas où les deux joueurs sont de camps différents.

## Préparation (3 min)

- A et B **du même camp** (on chuchote), **dans la même zone, hors combat, hors instance**. En
  instance, le nom et le GUID d'un autre joueur peuvent devenir des valeurs secrètes.
- **Copier-coller** les lignes depuis ce fichier, **une ligne par collage** : Ctrl+V marche dans la
  boîte de chat. Chaque `/run` fait moins de 255 caractères et passe la syntaxe Lua 5.1 (vérifié
  avec Elune).
- ⚠️ **La boîte de chat double les `|`** tapés ou collés dans un `/run` : un motif `"|H"` y devient
  `"||H"` et ne trouve plus rien, un `print("|cff…")` n'affiche plus de lien (vécu le 2026-09-27).
  Les lignes de cette fiche écrivent donc `\124` (le code du caractère `|`) : ne pas le « corriger ».
- Chaque relevé s'affiche dans le chat (`LP clé = valeur`) **et** est rangé dans la sauvegarde de
  COC (`CraftingOrderClassicDB._lp`). Rien à recopier : je lirai les deux fichiers après le
  `/reload` final.
- **Pas de `/reload` avant l'étape 8** : il effacerait les outils. Si ça arrive quand même, recoller
  les lignes de préparation ; les relevés déjà pris sont conservés.

**Sur B**, coller ces deux lignes :

```
/run LPD=CraftingOrderClassicDB LPD._lp=LPD._lp or {} function LP(k,v) LPD._lp[k]=v print("LP "..k.." = "..(tostring(v):gsub("\124","\124\124"))) end
/run function LC(k) local t={} for _,id in ipairs(C_TradeSkillUI.GetAllRecipeIDs()) do local r=C_TradeSkillUI.GetRecipeInfo(id) if r and r.learned then t[#t+1]=id end end LP(k,#t..":"..table.concat(t,",")) end
```

**Sur A**, les deux mêmes, puis ces quatre :

```
/run function LV(k) local T=C_TradeSkillUI local a,b=T.IsTradeSkillLinked() local p=T.GetBaseProfessionInfo() LP(k,tostring(a).."/"..tostring(b).."/"..tostring(T.IsTradeSkillGuildMember()).."/"..tostring(p and p.professionName)) LC(k.."_n") end
/run function LK(k) local s=LibStub("CraftLink-1.0"):MyKnownSet("Enchanting") local n=0 for _ in pairs(s or {}) do n=n+1 end LP(k,n) end
/run function LF(g,s,l) print("\124cffffd000\124Htrade:"..g..":"..s..":"..l.."\124h[forge "..l.."]\124h\124r") end
/run local f=CreateFrame("Frame") f:RegisterEvent("CHAT_MSG_WHISPER") f:SetScript("OnEvent",function(_,_,m) local l=m:match("\124H(trade:.-)\124h") if l then LP("recu",l) end end)
```

Ce que chacune fait : `LP` note une valeur ; `LC` compte les recettes **apprises** dans la fenêtre
ouverte et note leur liste ; `LV` dit à qui est la fenêtre ouverte (liée ? de qui ? guilde ?
quel métier ?) puis appelle `LC` ; `LK` compte ce que **COC croit que A connaît** en Enchantement ;
`LF` affiche un lien de métier fabriqué, cliquable ; la dernière ligne capte tout lien de métier
reçu par chuchotement.

Puis **A cible B** :

```
/run LP("guidB",UnitGUID("target"))
```

Attendu : `LP guidB = Player-…`. Si c'est `nil`, la cible n'est pas prise : recommencer.

## Étapes

Dans l'ordre : chacune s'appuie sur les précédentes.

### 1 — B : le jeu autorise-t-il à lier ?

B ouvre l'Enchantement et cherche le bouton en forme de chaîne en haut de la liste des recettes.
Puis :

```
/run LP("peutLier",C_TradeSkillUI.CanTradeSkillListLink())
```

| Ce qui s'affiche | Ce que ça prouve |
|---|---|
| `true`, bouton chaîne visible | Cas normal → étape 2 |
| `true`, pas de bouton | Le bouton est masqué pour une raison d'affichage (mode manette, fenêtre réduite). Le lien existe → étape 2 |
| `false` | Le serveur refuse de lier ce métier. Essayer la Cuisine. `false` partout : les liens sont fermés sur Camelot → **aller à 7** |
| Erreur `attempt to call a nil value` | Fonction absente de ce client : tenter quand même l'étape 2 |

### 2 — B : le lien brut, ses métiers, le compte témoin

Toujours avec l'Enchantement ouvert :

```
/run LP("lienB",C_TradeSkillUI.GetTradeSkillListLink())
/run LC("enchB")
/run for _,i in pairs({GetProfessions()}) do local n,_,_,_,_,o,sl=GetProfessionInfo(i) local s=C_SpellBook.GetSpellBookItemInfo((o or 0)+1,Enum.SpellBookSpellBank.Player) LP("metier_"..tostring(sl),n.." sort="..tostring(s and s.spellID)) end
```

Puis B ouvre la **Cuisine** (ou tout autre 2e métier) et :

```
/run LC("cuisB")
```

⚠️ **Ne jamais lier la Cuisine ni l'envoyer à qui que ce soit** : c'est le métier « jamais partagé »
de l'étape 5.

Forme du lien (`LP lienB`) :

| Ce qui s'affiche | Ce que ça prouve |
|---|---|
| `…Htrade:Player-…:<nombre>:<nombre>…` | Forme actuelle de Retail : le lien ne contient qu'une adresse, et le serveur envoie les recettes au clic → étape 3 |
| Un long champ de lettres et de chiffres | Forme de l'époque Wrath : la liste voyage **dans** le lien, c'est une copie figée déclarée par B. L'étape 3 reste valable ; les étapes 4 à 6 supposent l'autre forme → **s'arrêter après 3** (sauter à 7) |
| `nil` | Pas de lien → **aller à 7** |

Étalonnage : comparer le `sort=` de la ligne `metier_…` de l'Enchantement au **premier nombre**
après le `Player-…` du lien.

| Ce qui s'affiche | Ce que ça prouve |
|---|---|
| Identiques | Le lien porte le sort du métier, qu'on lit dans le grimoire : l'étape 5 peut viser un métier jamais lié |
| Différents | L'étape 5 fera aussi sa variante (voir 5) |

### 3 — A reçoit le lien et l'ouvre (le cœur du test)

A, **avant de cliquer quoi que ce soit** :

```
/run LK("connusA_avant")
```

A chuchote « test » à B. Le bouton chaîne de B est un **menu de canaux** (Guilde, Groupe, canaux) :
il n'offre pas le chuchotement. B, avec **son** Enchantement affiché (ouvrir les Communautés referme
la fenêtre de métier, et le lien devient `nil`), colle :

```
/run local l=C_TradeSkillUI.GetTradeSkillListLink() if l then ChatFrameUtil.OpenChat("/r "..l,DEFAULT_CHAT_FRAME) else print("PAS DE LIEN : ouvre ton Enchantement") end
```

La ligne de chat s'ouvre avec le lien : vérifier qu'elle chuchote à A, puis **Entrée** (la commande
ne fait que préparer la ligne, c'est le joueur qui envoie). Poster dans une communauté fait passer le
lien, mais un addon n'y lit qu'une référence opaque : le capteur de A resterait vide.

Chez A, la ligne `LP recu = trade:…` doit s'afficher d'elle-même. A clique le lien dans le chat,
attend que la liste soit remplie, puis :

```
/run LV("vueA_lien")
/run LK("connusA_apres")
```

Ce que A voit :

| Ce qui s'affiche | Ce que ça prouve |
|---|---|
| Fenêtre titrée « Enchantement [nom de B] » ; `vueA_lien = true/<B>/…/Enchantement` ; `vueA_lien_n` a le même nombre que `enchB` | Un addon lit exactement les recettes de B à travers un lien. Une piste pour COC : lire le métier d'un joueur **sans l'addon** qui colle son lien |
| Pareil, mais `vueA_lien_n` = 0 | La liste arrive plus tard : refaire `/run LV("vueA_lien2")` 3 s après. Toujours 0 : l'API ne donne pas la liste d'un métier lié |
| `vueA_lien_n` ≠ `enchB` | Je comparerai les deux listes, elles sont dans les fichiers |
| Rien ne s'ouvre, ou un message rouge | Les liens de métier ne marchent pas sur Camelot → recopier le message, **aller à 7** |
| Pas de `LP recu`, mais le lien est bien dans le chat | Le capteur a raté le message. Finir l'étape 3, **sauter 4 et 6** (elles en ont besoin) |

Pollution de COC :

| Ce qui s'affiche | Ce que ça prouve |
|---|---|
| `connusA_apres` = `connusA_avant` | COC ne s'est pas approprié les recettes de B : la lecture du code se trompait |
| `connusA_apres` > `connusA_avant` | **Bug confirmé** : COC a rangé les recettes de B dans celles de A. Correctif à faire (ne capter que son propre métier) ; nettoyage à l'étape 8 |

### 4 — Témoin : le même lien, reconstruit à la main

A ferme la fenêtre de métier, puis :

```
/run LF(LPD._lp.recu:match("^trade:([^:]+):(%d+):(%d+)"))
```

Une ligne `[forge <nombre>]` apparaît dans le chat : la cliquer.

| Ce qui s'affiche | Ce que ça prouve |
|---|---|
| L'Enchantement de B s'ouvre comme à l'étape 3 | Fabriquer un lien marche : l'étape 5 est interprétable |
| Message rouge `attempt to concatenate` | Le lien reçu n'a pas la forme supposée → **sauter 5** |
| Rien ne s'ouvre | Le lien contient autre chose que ces trois champs, ou une ligne affichée par un addon n'est pas cliquable → **sauter 5** |

### 5 — Le vrai test : le métier que B n'a jamais partagé

Sur l'écran de B, relire `LP metier_<LIGNE> = Cuisine sort=<SORT>`. A remplace `SORT` et `LIGNE`
par ces deux nombres :

```
/run LF(LPD._lp.guidB,SORT,LIGNE)
```

Cliquer `[forge LIGNE]`, puis :

```
/run LV("vueA_forge")
```

Si l'étalonnage de l'étape 2 donnait deux nombres **différents**, essayer aussi cette variante, qui
garde le sort de l'Enchantement (remplacer seulement `LIGNE`) :

```
/run LF(LPD._lp.guidB,LPD._lp.recu:match(":(%d+):%d+$"),LIGNE)
```

| Ce qui s'affiche | Ce que ça prouve |
|---|---|
| La Cuisine de B s'ouvre ; `vueA_forge_n` = `cuisB` | Le serveur envoie n'importe quel métier d'un GUID, sans partage. **Oui**, sous réserve du même Battle.net (voir plus haut) |
| Rien, ou un message rouge | Le serveur ne sert que ce qui a été lié. **Non** |
| La fenêtre s'ouvre vide (`vueA_forge_n` = 0) | Le serveur accepte le lien mais ne livre pas les recettes : **non**, en pratique |
| Seule la variante ouvre la Cuisine | Le serveur ignore le numéro de sort, seule la ligne de métier compte |

### 6 — B se déconnecte

B revient à l'**écran de sélection des personnages** (pas seulement AFK). A :

```
/run print("\124cffffd000\124H"..LPD._lp.recu.."\124h[rejouer]\124h\124r")
```

Cliquer `[rejouer]`, puis `/run LV("vueA_horsligne")`. Si l'étape 5 a ouvert la Cuisine, recliquer
aussi `[forge LIGNE]` (toujours dans le chat), puis `/run LV("vueA_forge_horsligne")`.

| Ce qui s'affiche | Ce que ça prouve |
|---|---|
| S'ouvre, même nombre de recettes | Le serveur sert un joueur hors ligne : COC pourrait lire le métier d'un artisan déconnecté |
| Message rouge (joueur introuvable…) ou rien | Le propriétaire doit être en ligne |

### 7 — Guilde (seulement si A et B sont dans la même guilde)

B se reconnecte. D'abord remettre à zéro ce que COC croit que A connaît, pour que la pollution
soit mesurable :

```
/run LibStub("CraftLink-1.0").myKnown.Enchanting=nil CraftingOrderClassic:_MyKnownStore().Enchanting=nil
/run LK("connusA_avant_guilde")
```

`LIGNE` = le numéro de ligne de l'**Enchantement** (lu à l'étape 2) :

```
/run C_GuildInfo.QueryGuildMemberRecipes(LPD._lp.guidB,LIGNE)
```

La fenêtre s'ouvre ? Alors :

```
/run LV("vueA_guilde")
/run LK("connusA_guilde")
```

Puis « qui, dans la guilde, sait faire cette recette ? ». `RECETTE` = le premier nombre après
`enchB = <n>:` sur l'écran de B :

```
/run local f=CreateFrame("Frame") f:RegisterEvent("GUILD_RECIPE_KNOWN_BY_MEMBERS") f:SetScript("OnEvent",function() local l,r,n=GetGuildRecipeInfoPostQuery() LP("quiConnait",l.." "..r.." n="..n.." "..tostring(GetGuildRecipeMember(1))) end)
/run C_GuildInfo.QueryGuildMembersForRecipe(LIGNE,RECETTE)
```

| Ce qui s'affiche | Ce que ça prouve |
|---|---|
| Fenêtre du métier de B ; `vueA_guilde_n` = `enchB` | La guilde montre tout, sans lien |
| `connusA_guilde` > `connusA_avant_guilde` | Même bug de pollution, par la vue guilde |
| `LP quiConnait = … n=1 <nom de B>` | La guilde répond à « qui sait faire X » sans que l'autre ait COC |
| Rien au bout de 5 s | Pas de réponse du serveur à cette question sur Camelot |

### 8 — Nettoyage

Sur A (sans risque même si A a vraiment l'Enchantement : ses vraies recettes reviennent à la
prochaine ouverture de sa propre fenêtre) :

```
/run LibStub("CraftLink-1.0").myKnown.Enchanting=nil CraftingOrderClassic:_MyKnownStore().Enchanting=nil
```

Puis **`/reload` sur les deux comptes** : c'est lui qui écrit les relevés sur le disque. Il remet
aussi l'interface au propre après les `/run`, à faire avant de crafter.

## À rapporter

- « C'est fait », et jusqu'à quelle étape.
- Une **capture d'écran** de la fenêtre aux étapes 3 et 5 : le titre dit à qui est le métier.
- Tout **message rouge**, en entier.
- « Je n'ai pas su faire l'étape N » est une réponse utile : l'étape reste non testée, sans plus.

Je lis moi-même la clé `_lp` dans
`D:\Jeux\World of Warcraft\_classic_beta_\WTF\Account\101576982#1\SavedVariables\CraftingOrderClassic.lua`
et dans son jumeau `#4`, et je compare les listes de recettes. Ensuite, sur chaque compte :
`/run CraftingOrderClassicDB._lp=nil` puis `/reload`.

## Relevé — joué le 2026-09-27

**Réponse à la question : non.** Un addon ne voit que le métier qu'on lui a lié (la guilde n'a pas
été essayée). Un lien fabriqué avec le bon GUID ne livre rien pour un métier jamais partagé. Comme
les deux comptes sont sous le même Battle.net, ce « non » vaut *a fortiori* pour un inconnu. Mais
un lien partagé se rejoue plus tard, et quiconque l'a reçu peut le partager à son tour.

| Étape | Date | Résultat |
|---|---|---|
| 1 | 2026-09-27 | ✅ `CanTradeSkillListLink()` = `true`. Le bouton chaîne est un menu de canaux, sans chuchotement |
| 2 | 2026-09-27 | ✅ Lien `\|cffffd000\|Htrade:Player-4620-0099DCCF:7412:333\|h[Enchanting]\|h\|r` : forme Retail (GUID : sort de **rang** : ligne), rien d'encodé. Grimoire : Enchantement `sort=7412`, égal au lien ; Cuisine `sort=2550`, ligne 185. `enchB` = 21 recettes, `cuisB` = 6 |
| 3 | 2026-09-27 | ✅ Chez A, fenêtre « Enchanting [Rédemption Wafhien] », liste identique à `enchB` (21/21). **Bug confirmé** : `knownRecipes["Gnomi-…"].Enchanting` contenait ces 21 recettes, pour un perso **sans aucun métier** (`connusA_avant` = 0). La colonne COC se greffe sur la vue liée, avec « Look for work » et **Offer** |
| 4 | 2026-09-27 | ✅ Témoin : le lien reconstruit rend `true/Rédemption Wafhien/false/Enchanting` et 21 recettes |
| 5 | 2026-09-27 | ❌ Lien fabriqué pour la Cuisine (bon GUID, sort 2550, ligne 185) : mode lié au nom de B, **nom de métier vide**, et la liste reste les 21 de l'Enchantement, jamais les 6 de la Cuisine. Le serveur ne livre pas un métier jamais partagé |
| 6 | 2026-09-27 | ⚠️ B déconnecté : le vrai lien rejoué rouvre l'Enchantement (21) ; le lien fabriqué ne livre toujours rien. Portée : A avait déjà ouvert ce métier dans la même session, donc un cache du client n'est pas exclu |
| 7 | — | Non joué : A et B ne sont pas dans la même guilde |
| 8 | 2026-09-27 | ✅ Recettes de B retirées de la sauvegarde de A (vérifié dans le fichier) |

Vu en dehors des étapes :

- **Celui qui regarde peut re-lier** : sur A, avec la vue liée ouverte, `GetTradeSkillListLink()` rend
  un lien, et A l'a renvoyé à B.
- `GetTradeSkillListLink()` rend `nil` dès que la fenêtre de métier s'est refermée.
- Le premier capteur n'a rien capté à cause des `|` doublés par le chat (voir Préparation).
