# Revue : passer l'interface de COC sur les briques Mainline de Forever

> Rédigée le 2026-09-27 · Cible : WoW: Forever / Camelot (16001) · Statut : **proposition, rien de
> décidé** · Portée : la fenêtre principale d'abord (Carnet, Commande, Récolte, Artisans, Mes
> artisans, Aide, Nouveautés), puis les fenêtres annexes. La colonne greffée dans la fenêtre des
> métiers est déjà faite.
>
> Origine : une journée passée sur le bouton « i » (caché derrière le portrait, puis trop petit, puis
> en conflit avec nos onglets). Le user : « au lieu de s'acharner, on va revoir l'UI ».

## Le constat

**Le cadre de notre fenêtre est déjà moderne. Tout ce qu'il contient date de l'Era.**

Sur Forever, `ButtonFrameTemplate` est le cadre métal de retail, à quelques pixels près : la couche
Camelot (`Blizzard_SharedXML\Camelot\NineSliceLayoutOverrides.lua`) ne fait que décaler quatre coins.
En revanche, le kit maison (`_UI_Skin_Native.lua`) a été monté le 2026-07-11 en vérifiant chaque
brique sur la source **Era** (la skill `coc-native-ui` le dit en toutes lettres) : languettes grises
du volet Amis, barres de défilement à flèches, fonds rocher et marbre, boutons « – » rouges, menu
déroulant maison.

Ces briques marchent encore, mais chacune a été calibrée pour un client qui n'est plus notre cible.
La journée du « i » en est l'illustration :

- le portrait retail vit dans un cadre à un niveau absolu de 400 ;
- Blizzard y pose un bouton d'aide de 64 px, à un endroit précis ;
- et c'est précisément là que nous avons mis nos onglets.

Un correctif en appelle un autre, parce que nos briques ne sont pas celles que le cadre attend.

Trois choses rendent la migration raisonnable maintenant :

1. **L'Era est gelée** (branche `era`, v1.30.0) et COC n'a plus qu'un `.toc`. Rester sur le plus
   petit dénominateur commun ne protège plus personne.
2. **Blizzard a déjà dessiné notre écran.** `Blizzard_ProfessionsCustomerOrders` (les Commandes
   d'artisanat de retail, présent dans la source Forever) fait ce que fait l'onglet Commande :
   parcourir des recettes par catégorie, choisir un destinataire Public / Guilde / Personnel, fixer
   une commission, poster. Sa page « Mes commandes » est notre Carnet. On a une maquette officielle.
3. **Les briques modernes sont chargées en permanence.** Liste défilante, onglets, champs de
   saisie, tableaux : tout vit dans `Blizzard_SharedXML`, `Blizzard_Menu` et `Blizzard_MoneyFrame`,
   qui ne sont pas chargés à la demande.

## Inventaire : ce que COC utilise, et ce qui le remplace

Relevé sur `main` le 2026-09-27 : 30 fichiers `_UI_*`, 24 fichiers `_ProfWindow_*`, 13 600 lignes.

| Brique actuelle | Usages | Équivalent Forever | Verdict |
|---|---|---|---|
| `ButtonFrameTemplate` (via `Skin.MakeWindow`) | 3 fenêtres | le même : sur Forever c'est déjà le cadre retail | **garder** |
| `UIPanelScrollFrameTemplate` + pools de lignes manuels + `Skin.AutoHideScroll` | 19 listes, 18 appels | `WowScrollBoxList` + `MinimalScrollBar` + `CreateDataProvider` / `CreateTreeDataProvider` | **migrer**, le plus gros gain |
| `TabButtonTemplate` en haut (`Skin.MakeTabs`) | 3 rangées | `PanelTabButtonTemplate` en bas (Commandes d'artisanat) ou `TabSystemTemplate` | **décision D1** |
| `Skin.MakeDropdown` / `Skin.MakeFlyout` (maison, anti-taint `UIDropDownMenu`) | 8 + 6 | `WowStyle1DropdownTemplate`, `WowStyle1FilterDropdownTemplate` (système Menu) | **bloqué** par le risque 1 |
| `Skin.MakeMoneyRow` (3 `InputBoxTemplate` or/argent/cuivre) | 3 | `LargeMoneyInputFrameTemplate` (le champ pourboire de retail) | **migrer** |
| Qté (`InputBoxTemplate` nu) | — | `NumericInputSpinnerTemplate` (le compteur de « Créer tout ») | **migrer** |
| Recherche : `InputBoxTemplate` + loupe et texte d'invite posés à la main (`Skin.SearchHint`) | 2 | `SearchBoxTemplate` (loupe, invite et croix d'effacement fournies) | **migrer** |
| `UIPanelButtonTemplate` (`Skin.MakeGoldButton`) | 33 | le même : retail l'utilise toujours, rouge (« Créer », « Mettre en vente ») | **garder** |
| `UICheckButtonTemplate` (`Skin.MakeCheck`) | 5 | le même | **garder** |
| En-têtes de catégorie « – » rouges | liste Commande, Récolte | `ListHeaderVisualTemplate` (en-têtes de la liste des métiers) | **migrer** avec les listes |
| Survol / sélection de ligne (`MakeFlatRow`) | 3 | atlas `Professions_Recipe_Hover` / `Professions_Recipe_Active` | **migrer** pour les recettes |
| Lueur bleue « ligne d'ami » (`Skin.PersonHighlight`) | listes de personnes | inchangée : c'est encore la ligne d'ami de retail | **garder** |
| Tableau du Carnet (colonnes posées à la main) | 1 | `TableBuilder` (la page « Mes commandes ») | **migrer**, à confirmer (risque 5) |
| Fonds rocher / marbre, `BackdropTemplate` (`Skin.SkinWell`) | 15 + 7 | `NineSlicePanelTemplate`, `InsetFrameTemplate`, atlas `Professions-background-summarylist` | **migrer** en dernier |
| `RinglessHelpPlateButtonTemplate` | 3 fenêtres | l'aspect de `MainHelpPlateButton`, **recopié** (déjà fait sur `fix/manquantes-faction-et-bouton-aide`, `55320c2`) | **garder** la copie |
| `GameTooltipTemplate`, `GlowBoxTemplate`, `SecureActionButtonTemplate` | — | les mêmes | **garder** |

### Ce qui ne bouge pas

- **La SPEC (`Skin.MakeSections`)** : c'est la structure, et elle reste. On change les briques posées
  dans les zones, pas le découpage.
- **Le langage couleur** (statuts d'ordre, rareté) : invariant absolu du kit.
- **Pas de XML maison.** Vérifié : une liste ScrollBox accepte un type de cadre nu (`"Button"`) du
  moment qu'on fixe la hauteur des lignes (`ScrollBoxListView.lua`, l. 36-55). Tout reste en Lua.
- **La colonne greffée** dans la fenêtre des métiers : elle vit déjà dans l'interface moderne.

## Les risques

**1. Le taint du système Menu (menus déroulants).** Un blocage `ADDON_ACTION_BLOCKED` sur la
recherche de groupe reste ouvert depuis juillet (mémoire `coc-lfg-taint-open`). Le suspect restant
est la machinerie partagée du nouveau système Menu. Rien n'est prouvé, mais le soupçon n'a jamais été
mesuré sur Forever. Passer nos 8 menus déroulants sur `WowStyle1DropdownTemplate` sans mesure, c'est
parier là-dessus. **Parade** : un palier 0 au labo (`TaintLab`, Forever, `/console taintLog 1`) avant
de toucher un seul menu. D'ici là, le flyout maison reste.

**2. Les gabarits chargés à la demande.** `Blizzard_ProfessionsTemplates` et
`Blizzard_ProfessionsCustomerOrders` sont `LoadOnDemand`. Les charger nous-mêmes exécuterait du code
Blizzard sous notre nom, et leurs `OnLoad` appellent `C_CraftingOrders`. **Parade** : ne jamais en
hériter. On les lit comme des maquettes, et on n'en reprend que les atlas et les mesures (« emprunter
par référence », règle de la skill).

**3. Les mixins qui touchent un singleton.** Hériter un gabarit, c'est hériter ses scripts.
`MainHelpPlateButton` écrit dans `HelpPlateTooltip` au survol : c'est un singleton, et on a déjà
prouvé que `HelpPlate.Show` teinte les barres d'action. **Parade** : lire le mixin avant d'hériter.
S'il touche un objet global, recopier les textures au lieu d'hériter.

**4. Le combat dans la colonne greffée.** La colonne est protégée comme son hôte : `Show`, `Hide`,
`SetPoint` y sont refusés en combat. Or une ScrollBox repositionne ses lignes à chaque défilement.
**Parade** : migrer d'abord la fenêtre principale, qui n'est pas protégée, et ne toucher aux listes de
la colonne qu'en dernier, après un relevé en combat.

**5. Deux briques déduites présentes, pas encore vues.** `TableBuilder.lua` et `TabSystemTemplates`
sont exclus des types de jeu « vanilla tbc ». Les `.toc` de Forever écrivent
`[AllowLoadGameType vanilla, camelot]` quand un fichier vaut pour les deux : Camelot est donc un type
distinct, et ces exclusions ne le touchent pas. **Parade** : confirmer par la sonde (`TableBuilderMixin`
et `TabSystemMixin` dans les `globals` de COCProbeDB) avant d'en dépendre.

**6. Les onglets en bas peuvent être recouverts.** Déjà payé en juillet avec
`CharacterFrameTabButtonTemplate` : un onglet qui pend sous la fenêtre passe sous toute fenêtre
Blizzard ouverte en dessous. `PanelTabButtonTemplate` a la même géométrie. **Parade** : voir D1.

## Plan par paliers

Même discipline que la conversion de juillet : un palier = une couche visible, **validée en jeu**
avant la suivante. Chaque palier démarre par une primitive du kit (`Skin.Make*`), puis la déploie.

| Palier | Contenu | Pourquoi dans cet ordre |
|---|---|---|
| **P0** | Labo taint du système Menu sur Forever, et sonde `TableBuilderMixin` / `TabSystemMixin` | lève les risques 1 et 5 avant d'écrire une ligne qui en dépend |
| **P1** | Liste de recettes de l'onglet Commande : ScrollBox + arbre de catégories + atlas des métiers | la zone la plus vue, la plus proche de la maquette ; elle fonde la primitive `Skin.MakeScrollList` |
| **P2** | Les 18 autres listes sur cette primitive ; fin de `AutoHideScroll` et des pools manuels | gain mécanique une fois la primitive éprouvée |
| **P3** | Onglets (D1) et bouton « i » à sa place native | règle le conflit qui a déclenché cette revue |
| **P4** | Formulaire Commande : commission `LargeMoneyInputFrameTemplate`, Qté en compteur, destinataire en menu (si P0 le permet) | calqué sur le formulaire des Commandes d'artisanat |
| **P5** | Carnet en `TableBuilder`, colonnes triables | calqué sur « Mes commandes » |
| **P6** | Fonds : rocher, marbre et puits vers NineSlice et atlas | le plus visible mais le moins risqué ; en dernier pour ne pas repeindre deux fois |
| **P7** | Fenêtres annexes (Route, Journal, panneaux Échange/Courrier), puis listes de la colonne greffée | après le relevé en combat (risque 4) |

## Décisions à prendre

**D1 — Où vont les onglets ?**
- **En bas**, `PanelTabButtonTemplate`, comme les Commandes d'artisanat. C'est la convention de la
  fenêtre qui fait la même chose que nous, et elle libère le haut pour le titre et le « i ». Contre :
  le recouvrement (risque 6).
- **En haut**, `TabSystemTemplate`, dans le style des onglets de retail.
- **Garder** les languettes actuelles et ne moderniser que l'intérieur.

Recommandation : **en bas**, en mesurant le recouvrement dès P3. L'incident de juillet venait d'un
art dessiné pour pendre sous le cadre de la fiche de personnage. Il faut vérifier s'il se reproduit
avec la brique retail avant de l'exclure.

**D2 — Menus déroulants.** Attendre le labo P0 (recommandé), ou migrer directement et surveiller.

**D3 — Portée.** Fenêtre principale seulement pour commencer (recommandé), ou tout d'un coup.

**D4 — Le grand « i » à anneau** (`55320c2`, jamais vu en jeu) : le garder en attendant P3, où il
trouvera sa place, ou le retirer de la branche de correctifs pour ne livrer que le correctif de
niveau déjà vérifié (`5480223`).

## Sources vérifiées

Toutes dans `Documentation\wow-ui-source-forever\Interface\AddOns\` :

- cadre : `Blizzard_SharedXML\Mainline\SharedUIPanelTemplates.xml` (`PortraitFrameBaseTemplate`,
  `PortraitContainer` à 400) ; couche Camelot : `Blizzard_SharedXML\Camelot\` ;
- maquette : `Blizzard_ProfessionsCustomerOrders\` (`…Form.xml` : destinataire, pourboire, durée,
  « Mettre en vente » ; `Blizzard_ProfessionsCustomerOrders.xml` : onglets `PanelTabButtonTemplate`
  en bas, BOTTOMLEFT +20,−28) ;
- liste de recettes : `Blizzard_ProfessionsTemplates\Blizzard_ProfessionsRecipeList.xml` ;
- briques : `Blizzard_SharedXML\Shared\Scroll\` (ScrollBox, `MinimalScrollBar`),
  `…\Shared\TabSystem\`, `…\Shared\InputBox\InputBoxTemplates.xml`, `…\ListTemplates.xml`,
  `…\TableBuilder.lua`, `Blizzard_Menu\` (dropdowns), `Blizzard_MoneyFrame\Shared\MoneyInputFrame.xml` ;
- bouton d'aide : `Blizzard_HelpPlate\Blizzard_HelpPlate.xml` (`MainHelpPlateButton`, posé à
  TOPLEFT +39,+20 par l'Archéologie, les Mascottes, les liaisons de clics) ;
- chargement : `Blizzard_SharedXML.toc` (l. 60, 121-134), `Blizzard_Professions*.toc` (`LoadOnDemand`).
