# CraftingOrderClassic — carte du code

> **GÉNÉRÉ** le 2026-07-18 (v1.22.0) par `scripts\gen_docs.ps1` — ne pas éditer à la main :
> relancer le script (deploy.ps1 le fait) après un changement de structure. Source de chaque
> rubrique : le `.toc` (ordre de chargement) et les commentaires d'en-tête des fichiers eux-mêmes.

98 modules + 4 entrée(s) Libs (CraftLink embarquée, documentée dans son repo).

## Modules (ordre de chargement)

| Fichier | Rôle | Lignes |
|---|---|---|
| `CraftingOrderClassic.lua` | Crafting Order - Classic — réseau GLOBAL et SOCIAL de commandes de craft. | 406 |
| `CraftingOrderClassic_Trace.lua` | trace réseau PERSISTÉE, lisible hors-jeu. | 79 |
| `CraftingOrderClassic_Migrations.lua` | versionnage du schéma SavedVariables. | 40 |
| `CraftingOrderClassic_Locale.lua` | socle de localisation du CHROME de l'UI. | 12 |
| `CraftingOrderClassic_Locale_enUS.lua` | overlay ANGLAIS (enUS/enGB). | 263 |
| `CraftingOrderClassic_Locale_enUS_2.lua` | overlay enUS, 2/2. | 366 |
| `CraftingOrderClassic_Locale_deDE.lua` | overlay ALLEMAND (deDE). | 264 |
| `CraftingOrderClassic_Locale_deDE_2.lua` | overlay deDE, 2/2. | 349 |
| `CraftingOrderClassic_Locale_esES.lua` | overlay ESPAGNOL (esES/esMX). | 265 |
| `CraftingOrderClassic_Locale_esES_2.lua` | overlay esES, 2/2. | 350 |
| `CraftingOrderClassic_Locale_News_enUS.lua` | traductions de l'onglet « Nouveautés » (enUS/enGB). | 201 |
| `CraftingOrderClassic_Locale_News_deDE.lua` | traductions de l'onglet « Nouveautés » (deDE). | 198 |
| `CraftingOrderClassic_Locale_News_esES.lua` | traductions de l'onglet « Nouveautés » (esES). | 198 |
| `CraftingOrderClassic_Elemental.lua` | pseudo-« métier » de récolte « Élémentaire ». | 61 |
| `CraftingOrderClassic_UI_Skin.lua` | tokens + helpers SÉMANTIQUES du skin (métiers, statuts, rareté, quantités, icônes natives) et petits widgets d'affichage. | 416 |
| `CraftingOrderClassic_UI_Skin_Native.lua` | kit de chrome Blizzard NATIF (le « framework » UI de COC). | 485 |
| `CraftingOrderClassic_UI_Skin_Sections.lua` | kit de chrome natif, volet SECTIONS : comment on découpe l'intérieur d'une fenêtre en blocs et en zones. | 247 |
| `CraftingOrderClassic_UI_Skin_HelpPlate.lua` | kit d'AIDE CONTEXTUELLE (le « bouton i » de retail). | 130 |
| `CraftingOrderClassic_ShareReagents.lua` | « liste de courses » : diffuser en un clic les réactifs d'une recette (vue métier) ou d'une commande (carte) dans un canal de discussion, avec le LIEN objet de chaque réactif. | 157 |
| `CraftingOrderClassic_UI.lua` | fenêtre principale (chrome Blizzard natif, kit UI_Skin_Native). | 485 |
| `CraftingOrderClassic_UI_HelpPlate.lua` | AIDE CONTEXTUELLE de la FENÊTRE PRINCIPALE (« bouton i »). | 166 |
| `CraftingOrderClassic_UI_Post_Layout.lua` | GÉOMÉTRIE de l'onglet « Commande » : colonnes, zones, séparateurs. | 127 |
| `CraftingOrderClassic_UI_Post.lua` | onglet « Commande » : sélection de plan (gauche) + réactifs « je fournis » / commission g-s-c / ciblage artisan (droite). | 373 |
| `CraftingOrderClassic_UI_Post_Detail.lua` | onglet « Commande », PANNEAU DROIT : en-tête du plan sélectionné (icône + cadre doré + nom + niveau), liste des réactifs « je fournis », et la rangée commission. | 194 |
| `CraftingOrderClassic_UI_Post_Artisans.lua` | onglet « Commande », section droite basse : boutons source, liste des artisans, ciblage (@Nom), libellé destinataire, bouton Poster. | 220 |
| `CraftingOrderClassic_UI_Post_Categories.lua` | onglet « Commande », panneau gauche : regroupe la LISTE DES PLANS en sections type fenêtre native (emplacement puis type pour les équipements, type pour les armes, catégorie pour le reste). | 182 |
| `CraftingOrderClassic_UI_Post_Paperdoll.lua` | onglet « Commande », vue SILHOUETTE de l'Enchantement. | 330 |
| `CraftingOrderClassic_UI_Post_LazyGold.lua` | onglet « Commande » : couche Lazy Gold (lecture seule). | 151 |
| `CraftingOrderClassic_UI_Gather_Layout.lua` | GÉOMÉTRIE de l'onglet « Récolte » : la SPEC (structure éditable, cf. | 66 |
| `CraftingOrderClassic_UI_Gather.lua` | onglet « Récolte » : ressources de récolte (minéraux, herbes, cuirs, poissons) + demande de quantité + prix par pile + ciblage récolteur. | 499 |
| `CraftingOrderClassic_UI_Gather_Categories.lua` | onglet « Récolte », panneau gauche : repliage des en-têtes et remplissage des lignes (en-tête de section/sous-catégorie, ou ressource). | 65 |
| `CraftingOrderClassic_UI_Artisans_Layout.lua` | GÉOMÉTRIE de l'onglet « Artisans » (annuaire social). | 44 |
| `CraftingOrderClassic_UI_Artisans.lua` | onglet « Artisans » : annuaire social. | 410 |
| `CraftingOrderClassic_UI_Artisans_Groups.lua` | fusion « une ligne par JOUEUR » (rerolls). | 207 |
| `CraftingOrderClassic_UI_Artisans_Icons.lua` | onglet « Artisans » : tout ce qui est ICÔNE de métier. | 186 |
| `CraftingOrderClassic_UI_Artisans_Muted.lua` | panel « En sourdine » de l'onglet Artisans. | 86 |
| `CraftingOrderClassic_UI_MyArtisans_Layout.lua` | GÉOMÉTRIE de l'onglet « Mes artisans ». | 53 |
| `CraftingOrderClassic_UI_MyArtisans.lua` | onglet « Mes artisans » : vue agrégée des métiers du COMPTE (tous mes rerolls du royaume), en mode « connu ». | 433 |
| `CraftingOrderClassic_UI_MyArtisans_LazyGold.lua` | onglet « Mes artisans » : couche Lazy Gold. | 135 |
| `CraftingOrderClassic_UI_Help.lua` | onglet Aide : page unique défilante qui explique les autres onglets (Carnet/Commande/Récolte/Artisans), la Vue Métier et le réseau. | 178 |
| `CraftingOrderClassic_UI_News.lua` | onglet « Nouveautés » : notes de version (changelog) affichées EN JEU, version par version, la plus récente en tête. | 252 |
| `CraftingOrderClassic_Social.lua` | couche sociale passive (socle). | 380 |
| `CraftingOrderClassic_Social_Menu.lua` | entrées « Crafting Order » du menu contextuel joueur. | 101 |
| `CraftingOrderClassic_Social_Roster.lua` | affichage des métiers sur les fenêtres NATIVES. | 130 |
| `CraftingOrderClassic_Minimap.lua` | bouton minimap (toggle du carnet). | 120 |
| `CraftingOrderClassic_Nameplate.lua` | icône « recherche de travail » (LFW) sur les plaques. | 121 |
| `CraftingOrderClassic_ProfOrders.lua` | COORDINATEUR d'événements de la fenêtre métier. | 82 |
| `CraftingOrderClassic_RecipeCats.lua` | SOUS-CATÉGORIES de recettes (moteur + registre). | 113 |
| `CraftingOrderClassic_RecipeCats_Group.lua` | REGROUPEMENT partagé : transforme une liste plate d'entrées (recettes, plans, ressources…) en liste d'AFFICHAGE à deux niveaux :      Section (COC.SectionOf)  >  Sous-catégorie (COC.RecipeCats)  >  les objets, triés  Écrit une fois ici parce que QUATRE listes en ont besoin et qu'elles n'ont pas la même structure de ligne : vue métier (recettes de l'API), onglet Commande (plans du catalogue), Mes artisans (recettes connues), onglet Récolte (ressources). | 121 |
| `CraftingOrderClassic_RecipeCats_Alchemy.lua` | sous-catégories de l'ALCHIMIE (données, éditées à la main). | 77 |
| `CraftingOrderClassic_RecipeCats_Gathering.lua` | sous-catégories des métiers de RÉCOLTE. | 179 |
| `CraftingOrderClassic_RecipeCats_Smelting.lua` | sous-catégorie « Lingots » du Minage (facette FONTE). | 39 |
| `CraftingOrderClassic_RecipeCats_Enchanting.lua` | sous-catégories de l'ENCHANTEMENT. | 52 |
| `CraftingOrderClassic_Craft.lua` | socle de lecture LIVE de la fenêtre métier (migration de la fenêtre custom depuis Guild Economy / TradeScanner_Craft.lua). | 206 |
| `CraftingOrderClassic_Enchant.lua` | spécifique à l'Enchantement (API Craft). | 326 |
| `CraftingOrderClassic_MTSL.lua` | pont LECTURE SEULE vers l'addon « Missing TradeSkills List » (MTSL). | 273 |
| `CraftingOrderClassic_ProfWindow.lua` | fenêtre métier custom 3 colonnes (migration depuis Guild Economy) : Recettes \| Détail+Craft \| Commandes du métier. | 460 |
| `CraftingOrderClassic_ProfWindow_Layout.lua` | GÉOMÉTRIE de la vue métier (fenêtre 3 colonnes). | 76 |
| `CraftingOrderClassic_ProfWindow_HelpPlate.lua` | AIDE CONTEXTUELLE de la Vue Métier (« bouton i »). | 82 |
| `CraftingOrderClassic_ProfWindow_Dock.lua` | mode DOCK de la vue métier (« Vue Blizzard ») : la fenêtre native reste VISIBLE (non neutralisée) et NOTRE colonne Commandes s'épingle à sa droite. | 70 |
| `CraftingOrderClassic_ProfWindow_Toolbar.lua` | barre d'outils de la colonne Recettes (vue métier) : les toggles de TRI (slot recTools, à gauche : rentabilité / valeurs exactes / progression — Lazy Gold) et de FILTRE (slot recFilterToggles, à droite : « j'ai les matériaux » / « montée de compétence »). | 228 |
| `CraftingOrderClassic_ProfWindow_Recipes.lua` | colonne GAUCHE : liste de recettes virtualisée (scroll), recherche, couleur par difficulté, sélection, badge « demandé » (nb de commandes ouvertes pour l'objet). | 477 |
| `CraftingOrderClassic_ProfWindow_Leveling.lua` | aide à la MONTÉE DE MÉTIER dans la liste de recettes : coût de progression (réactifs au prix Lazy Gold ÷ chance de point selon la couleur), badge « meilleur coût/point » sur la recette recommandée, icônes de SOURCE sur les manquantes (formateur / vendeur PNJ / coté à l'HV / à farmer) et tri « progression » affiné par coût. | 196 |
| `CraftingOrderClassic_ProfWindow_Route.lua` | PLAN DE ROUTE de montée de métier (étage ③ de l'aide à la progression) : « du rang actuel au plafond, quoi crafter, combien de fois, pour combien ». | 319 |
| `CraftingOrderClassic_ProfWindow_Detail.lua` | colonne CENTRE : détail de la recette sélectionnée (icône, réactifs have/need) + boutons Créer / Créer tout. | 411 |
| `CraftingOrderClassic_ProfWindow_Info.lua` | PANNEAU D'INFO en SECTIONS pour la colonne centrale de la vue métier. | 144 |
| `CraftingOrderClassic_LazyGold.lua` | pont LECTURE SEULE vers l'addon « Lazy Gold Classic » (LG). | 337 |
| `CraftingOrderClassic_ProfWindow_Orders.lua` | colonne « Commandes » de la vue métier (cabine de l'artisan) : construction (onglets de relation, en-tête, scroll), vue LISTE (une ligne par commande : demandeur + prix + âge ; une ligne sourdine cliquée se réaffiche), collecte/tri et rafraîchissement. | 343 |
| `CraftingOrderClassic_ProfWindow_Orders_Card.lua` | vue SÉLECTIONNÉE de la colonne « Commandes » : la carte complète d'une commande (composants fournis, repères Lazy Gold, ACCEPTER / REFUSER / CHUCHOTER ; croix en haut à droite = retour liste). | 255 |
| `CraftingOrderClassic_ProfWindow_LFW.lua` | config de l'OFFRE « recherche de travail » par métier. | 327 |
| `CraftingOrderClassic_ProfWindow_Reroll.lua` | vue métier LECTURE SEULE d'un REROLL. | 119 |
| `Directory.lua` | Crafting Order - Classic — Directory : l'annuaire des GENS (présence + qui peut crafter quoi). | 468 |
| `Directory_Presence.lua` | présence : la vérité JEU (amis/guilde) et sa fusion avec la vérité ADDON. | 76 |
| `Directory_Confed.lua` | source « confédération » (GreenWall) de l'annuaire, DISPLAY-ONLY. | 51 |
| `Directory_Skills.lua` | niveaux de compétence + réputation (couche « profil » de l'annuaire). | 119 |
| `Directory_Cooldowns.lua` | cooldowns de recettes (couche « profil » de l'annuaire). | 82 |
| `Directory_RelayCodec.lua` | codec du fil RLY : relais de la fiche d'un artisan HORS LIGNE par un de ses partenaires. | 63 |
| `Directory_Relay.lua` | « contacts de confiance » : les données d'un joueur DÉCONNECTÉ restent servies par ses partenaires (r.isPartner). | 150 |
| `Directory_AltCodec.lua` | codec du fil ALT (liste des persos d'un même joueur) + vérification par réciprocité. | 115 |
| `Directory_Alts.lua` | regroupement des rerolls : identité « joueur » multi-persos (verbe ALT). | 270 |
| `Directory_LFW.lua` | statut « recherche de travail » (Looking For Work) + OFFRE par métier. | 314 |
| `CraftingOrderClassic_LFWChat.lua` | détection « recherche de travail » dans le CHAT VISIBLE. | 88 |
| `Directory_MyArtisans.lua` | agrégation des métiers du COMPTE (onglet « Mes artisans »). | 168 |
| `Directory_LootScan.lua` | découverte PASSIVE des artisans NON-porteurs de l'addon qui craftent à proximité. | 170 |
| `Orders_Codec.lua` | codec du protocole filaire ORD\| (sérialisation ⇄ parsing, SOURCE DE VÉRITÉ). | 95 |
| `Orders.lua` | Crafting Order - Classic — Orders : carnet d'ordres GLOBAL (modèle + cycle + protocole). | 476 |
| `Orders_Net.lua` | couche « fil réseau » du carnet d'ordres (protocole ORD\|). | 315 |
| `CraftingOrderClassic_Inbound.lua` | couche réseau « passive » : capte les demandes de craft postées dans /commerce (Trade) et /guilde par des joueurs SANS l'addon, alerte le joueur, et les range dans une file « Entrantes » (acceptable / ignorable). | 247 |
| `CraftingOrderClassic_Handoff.lua` | « garder une commande pour un ami capable ». | 281 |
| `CraftingOrderClassic_Moderation.lua` | modération / anti-spam. | 333 |
| `CraftingOrderClassic_LootAlert.lua` | alerte quand TU loots un objet-PLAN (recette/formule/ schéma/patron) catalogué par CraftLink, MAIS seulement s'il te CONCERNE : soit tu as le métier (candidat à l'apprendre), soit un AMI/PARTENAIRE de ton annuaire ne le connaît pas encore (candidat à un don — cf. | 155 |
| `CraftingOrderClassic_Companion.lua` | socle des GREFFONS : panneaux compagnons accrochés aux fenêtres natives (échange, courrier) pour livrer une commande sans quitter le geste en cours. | 211 |
| `CraftingOrderClassic_Companion_Mail.lua` | greffon COURRIER (scène B de la maquette) : panneau accroché à droite du compositeur d'envoi. | 177 |
| `CraftingOrderClassic_Companion_Trade.lua` | greffon ÉCHANGE (scène A de la maquette) : panneau accroché SOUS la fenêtre d'échange native quand une commande nous lie au partenaire (dans les DEUX sens : je crafte pour lui = « vendeur », ou il crafte pour moi = « acheteur »). | 114 |
| `CraftingOrderClassic_Enchant_Trade.lua` | greffon ENCHANTEMENT sur la fenêtre d'ÉCHANGE. | 289 |
| `CraftingOrderClassic_Enchant_Trade_Ask.lua` | greffon ÉCHANGE : « demande-lui la pièce ». | 159 |
| `Debug.lua` | Crafting Order - Classic — Debug : mode solo pour "jouer" un réseau fictif. | 136 |
| `CraftingOrderClassic_SelfTest.lua` | suite de tests IN-GAME (/cotest). | 180 |

## Kit UI — référence `Skin.*` (extraite des fichiers *Skin*)

### `CraftingOrderClassic_UI_Skin.lua`

**`Skin.ProfLabel(p)`**


**`Skin.ProfIcon(key)`**


**`Skin.StatusInfo(s)`**


**`Skin.RarityColor(itemID)`**

> Couleur de rareté d'un objet {r,g,b} (or par défaut : services/enchants, ou nom non encore en cache).

**`Skin.QtyText(o)`**

> Libellé de quantité UNIQUE et cohérent d'un ordre (Carnet, carte vue métier, Confiées, toasts).
> Deux modes selon o.byStack :
>   • à l'unité → « ×N »
>   • par pile  → « N piles (total) » où total = N × taille de pile (8ᵉ retour de GetItemInfo ;
>     20 pour Heavy Hide) → on donne le nombre concret d'objets voulus. Taille inconnue (objet pas
>     encore en cache / enchant sans itemID) → repli « N piles » sans le total.
> Accepte toute table portant {qty, byStack, itemID} (ordre OU ligne Handoff:_Row).

**`Skin.QtySuffix(o)`**

> Variante pour les alertes chat/toast : préfixe un espace et masque le « ×1 » trivial (mais garde
> « 1 pile (20) », qui porte une info réelle). Renvoie "" quand il n'y a rien d'utile à afficher.

**`Skin.FormatDuration(sec)`**

> Durée compacte pour les cooldowns : « 2j 3h » / « 14h 5min » / « 12min » (2 unités max,
> jamais 0 : un restant < 60 s s'affiche « 1min » — l'échelle des CD se compte en heures/jours).

**`Skin.KnowsProf(r, p)`**

> Filtres d'annuaire PARTAGÉS (Commande / Récolte / Artisans) — anciennement dupliqués (knowsProf/
> inSource) dans chaque onglet, avec une divergence SUBTILE (Artisans incluait craftSeen, pas les
> autres). On expose ici DEUX variantes NOMMÉES pour rendre la divergence EXPLICITE et voulue.
> Un artisan (entrée roster) connaît-il ce métier via de VRAIES données réseau (niveau SK ou recette
> RK) ? À utiliser pour CIBLER une commande : seul un porteur de l'addon peut la recevoir → on exclut
> les non-porteurs « vu crafter » (craftSeen). Onglets Commande & Récolte.

**`Skin.KnowsProfOrSeen(r, p)`**

> + craftSeen (non-porteur repéré à proximité, sans l'addon) + relayed (fiche servie par un
> partenaire pendant que l'artisan est hors ligne — estimation display-only). À utiliser pour
> l'ANNUAIRE D'AFFICHAGE (onglet Artisans) UNIQUEMENT : KnowsProf (routage) reste INTACT —
> on n'adresse jamais une commande sur la foi d'un relais.

**`Skin.InSource(r, src)`**

> Un artisan entre-t-il dans la SOURCE (Guilde/Amis via drapeaux de relation, sinon catégorie
> d'affichage) ? « confed » (display-only) traité comme « recent » : un confédéré reste sélectionnable
> sous « Croisés ». Partagé par les listes d'artisans de Commande et Récolte.

**`Skin.MakeMoneyRow(parent, x, y)`**

> Trois champs de saisie or/argent/cuivre alignés (icônes de monnaie) → (goldEB, silverEB, copperEB).
> Partagé par la commission (Commande) et le prix par pile (Récolte) — jadis _MakeGSC / _MakeGSCGather.

**`Skin.FirstChar(s)`**

> Premier caractère (UTF-8) en capitale — pour le badge de rareté.

**`Skin.ItemExists(itemID)`**

> L'objet existe-t-il dans la base du CLIENT courant ? GetItemInfoInstant lit la DB statique et
> renvoie nil pour un objet d'une autre extension (ex. minerai TBC sur un client Era) → filtrage
> propre par version, sans re-générer les données (sur un client TBC, l'objet apparaîtra).

**`Skin.Icon(itemID, spellID)`**

> Icône native d'un objet/sort (texture du client — aucun asset à fournir). nil si introuvable.

**`Skin.MakeBadge(parent, size)`**

> Badge carré : icône native de l'objet (bordure colorée par rareté), avec repli sur une lettre.
> Paint(r, g, b, char, tex) — tex = texture d'icône (Skin.Icon), ou nil → lettre.

**`Skin.SearchHint(parent, editbox, text)`**

> Icône loupe + texte d'invite (placeholder) pour un champ de recherche. Renvoie le FontString
> placeholder (à masquer quand le champ est rempli, via :SetShown(text=="")). Plus de glyphe « ○ ».

**`Skin.MakeCheck(parent, size)`**

> Case à cocher carrée en TEXTURE native (les glyphes ✓/□ s'affichent en tofu dans la police WoW).
> Renvoie la texture « boîte » avec :SetChecked(bool) qui montre/masque la coche superposée.

**`Skin.WireItemTooltip(row)`**

> Câble le tooltip d'objet/sort au survol d'une ligne (à appeler UNE fois dans le constructeur de
> ligne). Lit `row.tipItemID` / `row.tipSpellID` posés au refresh → priorité à l'objet (le produit).

**`Skin.ChatLinkFor(link, itemID, spellID)`**

> Résout un HYPERLIEN de chat COMPLET (|H…|h, insérable) depuis ce qu'une ligne porte déjà : un lien
> EXACT (recette/réactif/enchant) d'abord, sinon l'objet par itemID, sinon le sort par spellID. Le lien
> d'objet reconstruit reste valide même si GetItemInfo n'a pas encore le nom en cache (le client résout
> l'objet par son id ; le texte entre crochets n'est que cosmétique) — mais en pratique l'objet est déjà
> en cache puisque la ligne l'affiche (icône + nom).

**`Skin.WireItemLink(row)`**

> Shift-clic (CHATLINK) sur une ligne → insère le lien dans le chat, comme un objet d'un sac ou de l'HdV.
> À appeler UNE fois dans le constructeur de ligne, en COMPLÉMENT de WireItemTooltip : lit les mêmes
> champs (tipItemID/tipSpellID) + un tipLink optionnel (lien exact déjà connu, ex. enchant). HookScript
> sur OnMouseUp → coexiste avec un OnClick de sélection (le clic SANS shift n'est pas intercepté) ;
> HandleModifiedItemClick vérifie lui-même le modificateur et ne fait rien si aucun chat n'est ouvert
> (comportement natif). La frame doit recevoir la souris (EnableMouse(true) ; les Button l'ont déjà).

**`Skin.MakeStatusIcon(parent, size)`**


**`Skin.MoneyIcon(parent, kind, anchorTo)`**

> Icône de monnaie (kind = "gold"/"silver"/"copper"), placée à droite d'un champ de saisie.

**`Skin.AutoHideScroll(scrollName, content)`**

> Masque la scrollbar (et ses boutons haut/bas) d'un UIPanelScrollFrameTemplate quand le contenu
> tient sans défilement → évite les « carrés » flottants qui débordaient sur la bordure dorée.

**`Skin.ApplyShadow(fs)`**


**`Skin.SkinFrameBackdrop(f)`**

> Cadre doré sur fond ROCHE natif (la tuile 256² des fenêtres Blizzard) — utilisé par le Toast et le
> socle des panneaux compagnons (Trade/Mail). Bordure UI-DialogBox-Gold-Border = art natif de dialogue.

**`Skin.SkinWell(f)`**

> Puits encastré, look NATIF (équivalent backdrop d'InsetFrameTemplate — on ne peut pas ré-hériter un
> template sur une frame déjà créée, SkinWell recevant la frame de l'appelant). Bordure NEUTRE : le
> liseré doré « tavern » est retiré au profit du gris Blizzard, pour s'accorder au cadre natif.
> ⚠️ bgFile = ChatFrameBackground (PAS UI-Tooltip-Background, testé et rendu quasi TRANSPARENT sur les
> flyouts malgré l'alpha 0.90 demandé — vécu sur le dropdown métier de l'onglet Commande, cause exacte
> non identifiée mais reproductible). ChatFrameBackground est le bg solide déjà éprouvé par MakeBadge/
> l'ancien SkinFrameBackdrop dans cette codebase : s'en tenir à des textures dont l'opacité est vérifiée.

**`Skin.MakeSeparator(parent, offsetY)`**


### `CraftingOrderClassic_UI_Skin_Native.lua`

**`Skin.MakeGoldButton(parent, w, h, text, template)`**

> Bouton : hérite du template NATIF `UIPanelButtonTemplate`.
> On a d'abord tenté de REPEINDRE le 3-tranches à la main (croyant devoir « échapper » à un addon de
> re-skin qui peignait les boutons en ROUGE). MESURE À L'APPUI (PIL) : l'art natif `UI-DialogBox-
> goldbutton-*` EST rouge (up-middle ≈ RGB (104,23,8), le « gold » du nom = le liseré), et le
> « Quitter » de la fenêtre de métier Blizzard est rouge pour la MÊME raison → aucun skinner, la
> théorie était fausse. Le repaint manuel, lui, cassait le rendu : caps latéraux de largeur FIXE en
> natif (Left 64 / Right 32, SEUL le middle s'étire — cf. UIPanelGoldButtonTemplate), que je
> redimensionnais à w/3 → bords « plats/écrasés ». D'où le RETOUR au template natif, qui gère caps,
> états (up/down/disabled) et survol tout seul, correctement à toute largeur.
> Le SEUL correctif nécessaire : le template ancre son texte `BOTTOM, 0, 12` (calibré pour h=32) → sur
> nos boutons de 16–24 px il monte trop haut. On le RE-ANCRE au CENTRE.
> Contrat conservé (≈35 appelants) : `b.text` (FontString natif, ré-ancrable/mesurable/recolorable),
> `b:SetText`/`b:GetFontString` (natifs), `b:SetSelected(on)` (enfoncé natif, reste CLIQUABLE),
> `template` = variante SÉCURISÉE ("SecureActionButtonTemplate", DoCraft protégé) — NE JAMAIS RETIRER.
> Doré plus tard (si le user tranche) : SetDesaturated(true)+SetVertexColor(or) sur b.Left/Middle/Right.

**`Skin.MakeWindow(name, w, h, opts)`**

> Fournit d'un coup : barre de titre + portrait rond + bouton fermer + panneau encastré marbre
> (`f.Inset`) + fond rocher. opts :
>   title     : texte de la barre de titre (SetTitle du PortraitFrameTemplateMixin)
>   portrait  : texture du médaillon (cf. SetWindowPortrait)
>   pos       : {point, relPoint, x, y} persisté, sinon CENTER
>   onMoved   : function(point, relPoint, x, y) à la fin d'un drag (pour persister)
>   onClose   : remplace le comportement du bouton fermer natif (ex. dock de la vue métier)
>   strata    : défaut "HIGH"
> SetToplevel : les fenêtres COC partagent la strata → un clic remonte la fenêtre entière d'un bloc
> (fini l'interclassement des éléments) ; Raise à l'ouverture = la dernière ouverte devant.

**`Skin.SetWindowPortrait(f, tex)`**

> Médaillon de la fenêtre (rond, haut-gauche). ⚠️ SetPortraitToTexture EXIGE une texture 64×64 —
> le format des icônes standard (Interface\Icons\*, retours de GetSpellTexture) — et LÈVE UNE ERREUR
> pour toute autre taille (vécu : WorkOrderGossipIcon, petite icône de gossip). D'où pcall + repli :
> SetTexture brut + masque alpha rond (SetMask), l'anneau du cadre recouvrant les bords.
> Sert aussi de feedback dynamique (ex. onglet Commande : le portrait devient l'icône du métier choisi
> — icônes de sort 64×64, donc chemin heureux).

**`Skin.SetPortraitClickable(f, onClick, tooltipText)`**

> Rend le médaillon CLIQUABLE, avec une petite flèche d'affordance (sinon un rond ne se devine pas
> cliquable). Idempotent : un 2ᵉ appel ne recrée rien, il re-câble juste le handler/tooltip — utile
> pour un déclencheur dont le comportement dépend de l'onglet actif. `f.portrait` fait l'objet exact
> du clic (SetAllPoints) : couvre le médaillon sans mordre sur le reste de la barre de titre.
> Renvoie (bouton, flèche) — la flèche s'expose pour que l'appelant la masque hors contexte (ex. un
> onglet où le clic ne fait rien) via `arrow:SetShown(bool)`.

**`Skin.MakeTabs(f, defs, onSelect, opts)`**

> Onglets EN HAUT, dans le marbre — vraies LANGUETTES natives (style « Amis/Ignorés » du volet Social).
> Deux itérations à NE PAS refaire :
>   (1) EN BAS via `CharacterFrameTabButtonTemplate` (art « fiche de perso ») — dessiné pour PENDRE
>       SOUS le cadre : posé en `BOTTOMLEFT` il dépassait de la FENÊTRE, recouvert par toute fenêtre
>       Blizzard ancrée plus bas (vécu : le volet Amis).
>   (2) EN HAUT mais en `MakeGoldButton` (3-tranches) → ça faisait des BOUTONS ROUGES, pas des
>       onglets : « ça fait pas du tout comme la liste d'Amis » (user, capture à l'appui).
> Le volet Amis utilise `TabButtonTemplate` (les onglets Amis/Ignorés) : art GRIS `HelpFrameTab-*`
> (Inactive/Active), forme de languette dont le corps est DANS la zone de contenu et le bas ouvert se
> fond dans le marbre — EXACTEMENT le rendu demandé. On HÉRITE ce template natif (pas de re-peinture,
> pas de XML maison : `CreateFrame(..., "TabButtonTemplate")` réutilise le template XML de Blizzard
> tel quel — cf. note « pourquoi pas de XML » dans la skill). Contraintes du template : sélection via
> `PanelTemplates_SelectTab/DeselectTab` (montre l'art Actif + désactive le clic sur l'onglet ACTIF,
> comportement d'onglet voulu) → EXIGE un NOM GLOBAL (les helpers résolvent `_G[name.."Left"]`…), et
> re-`TabResize` après chaque SetText (aucun reflow).
> PLACEMENT (mesuré sur PortraitFrameTemplate) : la barre de titre GRISE occupe f0..f−21, puis la tuile
> ROCK va de f−21 à l'inset (f−60) ; le PORTRAIT (61×61 en −6,8) déborde jusqu'à x≈55 / y≈−53. Le volet
> Amis pose ses languettes SUR cette bande grise → on fait pareil : à DROITE du portrait (défaut tabX=62,
> il dégage le bord droit du portrait x≈54) et dans le rock SOUS le titre (défaut tabY=−34, sous la tuile
> de titre −21 et le nom de métier de l'en-tête −14). Le corps de la languette vit donc DANS le gris,
> son bas ouvert plonge vers le contenu — le rendu « onglets sur la barre grise » demandé. La fenêtre
> réserve la bande dessous (PAD_TOP, UI.lua). Contrat `bar` inchangé : .buttons[id], :Select, :SetText.

**`Skin.MakeFlatRow(parent, w, h)`**

> Ligne plate de liste / flyout (PAS un bouton 3-tranches).
> Pour les rangées cliquables : lignes de dropdown maison, « toute la liste », rerolls, menu minimap…
> Le bouton doré n'est PAS fait pour ça (l'ancien MakeGoldButton servait aussi de ligne, faute de
> mieux). Contrat : .text (ré-ancrable), .selTex, :SetSelected(on). Surbrillance auto (HIGHLIGHT).

**`Skin.PersonHighlight(row)`**

> Ligne « personne » des listes d'artisans/récolteurs (pastille + nom + source).
> Constructeur partagé Commande/Récolte (il était dupliqué dans les deux) : pastille de présence à
> gauche, nom extensible, étiquette source alignée à droite, surbrillance au survol + texture de
> sélection. Contrat : .dot (MakeStatusIcon), .name, .src (FontStrings), .selTex (:SetShown(on)).
> L'appelant garde le peuplement (grouping rerolls, filtre métier…) — ici que la GÉOMÉTRIE.
> Surbrillance de ligne « façon liste d'Amis » (réutilise le chrome natif du volet Social). La ligne
> d'ami (FriendsFrameButtonTemplate) n'utilise PAS un aplat gris mais la BARRE `UI-QuestLogTitleHighlight`
> en mode ADD, teintée en BLEU (SetVertexColor 0.243/0.570/1 — valeur exacte du OnLoad Blizzard) →
> lueur bleue au survol, le marqueur visuel emblématique des listes de personnes du jeu. Ajoute la
> couche HIGHLIGHT (auto au survol) + rend une texture de SÉLECTION (bleu léger, masquée) pour
> :SetSelected. À utiliser partout où on liste des PERSONNES (artisans, récolteurs) pour l'homogénéité.

**`Skin.MakeArtisanRow(parent, w, h)`**


**`Skin.MakeFlyout(name, w, opts)`**

> Flyout : dropdown/menu léger maison (puits + closer + pool de lignes).
> Le pattern « puits DIALOG + bouton plein écran qui ferme au clic ailleurs » était dupliqué 4×
> (métier Commande, métier Récolte, vitrine Mes artisans, menu minimap) → UNE primitive. Le closer
> est UN NIVEAU SOUS le flyout dans la même strate : un clic dans le flyout agit, un clic n'importe
> où ailleurs ferme. Il vit sur UIParent (hors hiérarchie du panneau appelant) pour passer au-dessus.
> Contrat : fly.rows (pool) · fly:Row(i) (ligne MakeFlatRow poolée, empilée, :Show()-ée) ·
> fly:SetCount(n) (masque le surplus + hauteur au contenu) · fly:ToggleAt(point, rel, relPoint, x, y)
> (ferme si ouvert, sinon ancre + ouvre — renvoie true si désormais visible).
> opts : rowStep (défaut 20) · rowH (= rowStep) · rowW (= w − 2·pad) · pad (2).
> Un menu à géométrie libre (titres de section, hauteur custom) peut ré-ancrer les lignes du pool et
> écraser la hauteur APRÈS SetCount — cf. le menu minimap.

**`Skin.MakeIconButton(parent, size, tex)`**

> Bouton-icône carré (filtres par métier, pills).
> Icône native encadrée d'un liseré 1 px — même famille visuelle que Skin.MakeBadge. Contrat :
> .icon (texture, désaturable par l'appelant), :SetSelected(on) = liseré doré vif.

**`Skin.MakeDropdown(name, parent, w, items, opts)`**


**`Skin.MakeCheckButton(parent, text, size)`**

> Case à cocher NATIVE (`UICheckButtonTemplate`, SharedUIPanelTemplates.xml:413) — le widget des
> filtres « Objets utilisables » / « Afficher sur le personnage » du browse de l'HdV.
> À ne pas confondre avec `Skin.MakeCheck` (Skin.lua) : celle-ci est une simple TEXTURE d'affichage
> (état non cliquable, posée dans une ligne de liste) ; ici c'est un vrai bouton cliquable avec
> survol/pressé/coche natifs. Le template fait 32×32 (calibré pour les panneaux Blizzard) → on le
> réduit, et le libellé natif (parentKey `Text`) est ré-ancré à droite de la boîte.
> Contrat : `c.text` (FontString) · `c:SetChecked/GetChecked` (natifs) · `c.Text` (alias natif).

**`Skin.FieldLabel(parent, text, x, y)`**

> Légende de champ style HdV (« NOM », « RARETÉ » au-dessus de leur champ). Police EXACTE de l'HdV :
> `GameFontHighlightSmall` (cf. BrowseNameText, Blizzard_AuctionUI.xml:126).

**`Skin.MakeFilterButton(parent, w, h, text)`**

> Bande de filtre verticale, style « catégories » de l'hôtel des ventes.
> Réplique fidèle de `AuctionClassButtonTemplate` (Blizzard_AuctionUITemplates.xml, HdV classique) :
> fond plat `UI-AuctionFrame-FilterBg` (bande sombre étirable) + survol/sélection par le highlight
> doré natif de l'onglet perso (`UI-Character-Tab-Highlight`, ADD). La SÉLECTION = `LockHighlight`,
> exactement comme l'HdV (AuctionFrameFilter_OnClick verrouille le highlight du bouton actif) — donc
> AUCUN bleu : l'effet bleu vu ailleurs venait d'une texture de highlight étrangère, pas de l'HdV.
> Contrat aligné sur MakeGoldButton pour drop-in dans une sidebar : `b.text` (libellé gauche,
> ré-ancrable/mesurable), `b:SetText`, `b:SetSelected(on)` (verrou doré, reste CLIQUABLE).
> ⚠️ `UI-AuctionFrame-FilterBg` est de l'art PEINT figé (ancien monde), pas une tuile native : à
> réserver aux listes de filtres facettés type HdV — ne pas en faire le chrome général (cf. skill).

### `CraftingOrderClassic_UI_Skin_Sections.lua`

**`Skin.MakeInset(parent, x1, y1, x2, y2, opts)`**

> Bloc de section encastré (« InsetFrameTemplate ») — le puits marbré des fenêtres Blizzard.
> MÊME template que le panneau de contenu de MakeWindow (`f.Inset`) : fond marbre tuilé + bordure
> NineSlice, qui s'adapte à toute taille. Blizzard l'IMBRIQUE dans une même fenêtre pour délimiter des
> blocs distincts — la fenêtre des Canaux crée `LeftInset` (liste) et `RightInset` (roster) côte à côte
> (ChannelFrame.xml:58 et :72). Aucun art à produire.
> PARENTER LE CONTENU AU BLOC est le bon réflexe (et ce que fait Blizzard) : le template porte
> `useParentLevel="true"`, le bloc reste donc au NIVEAU de son parent → ses enfants gardent exactement
> le niveau qu'ils auraient eu en enfants directs du panneau, et le marbre (couche BACKGROUND) passe
> sous eux. Bénéfice : les offsets du contenu deviennent RELATIFS au bloc, donc le contenu ne peut plus
> dériver de sa bordure, et déplacer une section ne demande plus de re-piquer chaque coordonnée.
> Cf. _UI_Post_Layout.lua (la géométrie déclarative de l'onglet Commande).
> Rect en coordonnées du PANNEAU (comme tout le layout COC) : (x1,y1) coin haut-gauche, (x2,y2) coin
> bas-droit, y négatifs. `y2 = nil` → le bloc descend jusqu'au BAS du panneau (marge `opts.bottom`).
> `opts.thin` = variante `InsetFrameTemplate3` (bordure fine « champ de saisie », fond sombre) pour un
> bloc discret plutôt qu'un vrai puits marbré.

**`Skin.MakeDivider(parent, x1, x2, y, heavy, opts)`**

> opts (art lourd seulement) : `capL = false` / `capR = false` = couper le pommeau de ce bout
> (le TexCoord démarre/finit dans le fût) — pour un bout qui BUTE dans une barre croisée.

**`Skin.MakeDividerV(parent, x, top, bottom, heavy)`**

> Variante VERTICALE (séparation de deux colonnes). Il n'existe pas d'art natif vertical → on PIVOTE
> l'art horizontal de 90° via la forme à 8 arguments de SetTexCoord (UL, LL, UR, LR : le bord gauche
> de l'art devient le haut ; même recadrage sur la zone peinte). Centré sur `x` ; `top` s'ancre au
> bord HAUT du parent (y négatif), `bottom` à son bord BAS (y positif).

**`Skin.ScrollTrack(scrollName)`**

> Fond « groove » derrière la scrollbar d'un ScrollFrame (`UIPanelScrollFrameTemplate`) : sans lui, le
> rail de la barre laisse voir le marbre nu (le fond « manque », demande user). Texture sombre parentée
> à la BARRE elle-même, couche BACKGROUND → le curseur et les flèches (niveau supérieur) restent
> au-dessus. Les 14 px rognés en haut/bas dégagent les boutons ▲▼. `scrollName` = le nom GLOBAL du
> ScrollFrame (la barre est `<nom>ScrollBar`, convention du template). Réutilisable (toute liste COC).

**`Skin.MakeSections(panel, spec)`**


### `CraftingOrderClassic_UI_Skin_HelpPlate.lua`

**`Skin.CollectHelp(spec)`**

> Parcourt un arbre de SPEC (cf. MakeSections) et collecte les nœuds tagués `help`, en profondeur.
> Rend { { id=, key=, dir= }, ... } dans l'ordre de déclaration. `key` = valeur brute de `help` (un id
> de texte, résolu en locale par le consommateur — pas ici : la SPEC ne connaît pas COC.L).

**`Skin.MakeHelpButton(parent, onToggle, opts)`**

> Bouton rond « i », posé un peu HORS CADRE (retail). Template natif RinglessHelpPlateButtonTemplate
> (help-i + surbrillance) ; repli défensif si absent. `onToggle` au clic. opts : size · point (ancre
> {p, rel, relP, x, y}) · tooltip.

**`Skin.ShowHelp(win, entries, mainButton)`**

> Ouvre le voile d'aide natif sur `win`, avec une tuile par entrée.
> entries : { { frame = <Region>, text = <string>, dir = "UP|DOWN|LEFT|RIGHT" }, ... }.
> La géométrie est LUE À CHAUD (positions réelles), donc appelable à chaque ouverture. Rend true si posé.

**`Skin.HideHelp()`**


**`Skin.HelpIsOpen()`**


## Détail par module (en-tête + API publique)

### `CraftingOrderClassic.lua`
> Crafting Order - Classic — réseau GLOBAL et SOCIAL de commandes de craft.
> 
> Addon AUTONOME : fonctionne SANS Guild Economy. Il consomme l'infra partagée CraftLink-1.0
> (catalogue de recettes + registre « mes recettes » + — à venir — transports global/guilde/
> proximité), embarquée via LibStub. À terme : carnet d'ordres global, annuaire « qui peut
> crafter quoi », profils, réputation (compteur de crafts livrés), favoris/suivi, présence.
> 
> État actuel : capture AUTONOME des recettes (scan des fenêtres métier via CraftLink) +
> persistance propre (CraftingOrderClassicDB). Le carnet d'ordres et le social arrivent (C/D).

**API** : `COC:Scan()` · `COC:ScanSoon()` · `COC:Status()` · `COC:ChannelCmd(arg)` · `COC:NotifyCmd(arg)` · `COC:ScanCmd(arg)` · `COC:CrafterScanCmd(arg)` · `COC:ChannelNotice()` · `COC:MissingAddon(displayName)` · `COC:NeedLazyGold()` · `COC:NeedMTSL()` · `COC:Beacon()` · `COC:BeaconDiag()` · `COC:WipeRoster()` · `COC:GreenWallDiag()` · `COC:Help()` · `COC:Slash(msg)`

### `CraftingOrderClassic_Trace.lua`
> CraftingOrderClassic_Trace.lua — trace réseau PERSISTÉE, lisible hors-jeu.
> 
> But : diagnostiquer le social à 2 comptes sans guilde. WoW ne laisse pas un addon écrire un
> fichier arbitraire → on écrit dans la SavedVariable (COC.db.trace, ring buffer) qui est sérialisée
> sur disque au /reload ou /logout. On lit ensuite, hors-jeu :
>   D:\Jeux\World of Warcraft\_classic_era_ptr_\WTF\Account\<COMPTE>\SavedVariables\CraftingOrderClassic.lua
> → table CraftingOrderClassicDB.trace = { "HH:MM:SS [cat] message", ... } pour CHAQUE compte.
> 
> Activation : /co trace (on) · /co trace off · /co trace clear · /co trace dump (30 dernières en chat).
> La trace reste OFF par défaut (zéro coût en prod) ; on l'allume le temps d'une session de test.

**API** : `Trace:IsOn()` · `Trace:Log(cat, msg)` · `Trace:Clear()` · `Trace:AutoEnablePTR()` · `Trace:Cmd(rest)`

### `CraftingOrderClassic_Migrations.lua`
> CraftingOrderClassic_Migrations.lua — versionnage du schéma SavedVariables.
> 
> Les SavedVariables sont PAR COMPTE et les utilisateurs sautent des versions (v1.2 → v1.8 direct).
> Une échelle ORDONNÉE de migrations, bornée par `db.schemaVer`, garantit qu'un palier ne tourne
> NI deux fois NI jamais. Remplace l'ancienne migration ad hoc « knownRecipes v2 » (ex-inline dans
> CraftingOrderClassic.lua). Les défauts PARESSEUX (COC.db.orders = … or {}, etc.) restent posés à
> leur point d'usage — ce module ne gère QUE les transformations de format entre versions.
> 
> PUR : aucune dépendance à l'API WoW ni à LibStub → testable hors client (tests headless Elune).

**API** : `Migrations.Apply(db)`

### `CraftingOrderClassic_Locale.lua`
> CraftingOrderClassic_Locale.lua — socle de localisation du CHROME de l'UI.
> Convention : la CLÉ est le texte FRANÇAIS (langue de référence du code) ; `COC.L[clé]` renvoie la
> clé par défaut, donc un client FR voit le texte tel quel — zéro régression, aucun overlay à écrire.
> Chaque AUTRE langue est un overlay chargé APRÈS ce fichier : _Locale_enUS / _deDE / _esES, tous de
> même forme (early-return hors de leur locale). L'anglais vivait ici jusqu'à la v1.12.0 ; il en a été
> extrait pour tenir sous le plafond anti-monolithe, et il est désormais un overlay comme les autres.
> Ajouter une langue = copier un overlay, le lister dans les 3 .toc ET dans scripts\check_locale.ps1.
> NB : les NOMS d'objets/recettes restent multilingues via GetItemInfo/GetSpellInfo (côté données).

### `CraftingOrderClassic_Locale_enUS.lua`
> CraftingOrderClassic_Locale_enUS.lua — overlay ANGLAIS (enUS/enGB). Clé FR → texte EN.
> Chargé APRÈS CraftingOrderClassic_Locale.lua (qui crée COC.L via setmetatable). Repli sur la clé FR
> pour toute chaîne non traduite. Extrait du fichier de base (plafond anti-monolithe de 500 lignes) :
> il vit maintenant à côté de _Locale_deDE.lua / _Locale_esES.lua, même forme, même contrat.
> Sur un client non-anglais : early-return, coût nul.

### `CraftingOrderClassic_Locale_enUS_2.lua`
> CraftingOrderClassic_Locale_enUS_2.lua — overlay enUS, 2/2. Clé FR → texte traduit.
> Suite de _Locale_enUS.lua, scindé pour rester sous le plafond anti-monolithe (500 l/fichier).
> Même contrat : chargé APRÈS _Locale.lua, table à plat fusionnée dans COC.L — les deux moitiés
> sont indépendantes (aucun ordre requis entre elles). Client d'une autre langue : early-return.

### `CraftingOrderClassic_Locale_deDE.lua`
> CraftingOrderClassic_Locale_deDE.lua — overlay ALLEMAND (deDE). Clé FR → texte DE.
> Chargé APRÈS CraftingOrderClassic_Locale.lua (qui crée COC.L via setmetatable). Repli sur la clé FR
> pour toute chaîne non traduite. Guillemets « » dans les valeurs → évite l'échappement Lua des ".
> Sur un client non-deDE : early-return, coût nul.

### `CraftingOrderClassic_Locale_deDE_2.lua`
> CraftingOrderClassic_Locale_deDE_2.lua — overlay deDE, 2/2. Clé FR → texte traduit.
> Suite de _Locale_deDE.lua, scindé pour rester sous le plafond anti-monolithe (500 l/fichier).
> Même contrat : chargé APRÈS _Locale.lua, table à plat fusionnée dans COC.L — les deux moitiés
> sont indépendantes (aucun ordre requis entre elles). Client d'une autre langue : early-return.

### `CraftingOrderClassic_Locale_esES.lua`
> CraftingOrderClassic_Locale_esES.lua — overlay ESPAGNOL (esES/esMX). Clé FR → texte ES.
> Chargé APRÈS CraftingOrderClassic_Locale.lua (qui crée COC.L via setmetatable). Repli sur la clé FR
> pour toute chaîne non traduite. Guillemets « » dans les valeurs → évite l'échappement Lua des ".
> Sur un client non-hispanophone : early-return, coût nul.

### `CraftingOrderClassic_Locale_esES_2.lua`
> CraftingOrderClassic_Locale_esES_2.lua — overlay esES, 2/2. Clé FR → texte traduit.
> Suite de _Locale_esES.lua, scindé pour rester sous le plafond anti-monolithe (500 l/fichier).
> Même contrat : chargé APRÈS _Locale.lua, table à plat fusionnée dans COC.L — les deux moitiés
> sont indépendantes (aucun ordre requis entre elles). Client d'une autre langue : early-return.

### `CraftingOrderClassic_Locale_News_enUS.lua`
> CraftingOrderClassic_Locale_News_enUS.lua — traductions de l'onglet « Nouveautés » (enUS/enGB).
> Extrait de _Locale_enUS.lua : l'onglet Nouveautés grossit à chaque release et faisait déborder le
> plafond anti-monolithe. Isolé ici, il a de la marge (fenêtre glissante côté UI_News). Même contrat :
> clé FR → texte EN, chargé APRÈS _Locale.lua, early-return hors locale.

### `CraftingOrderClassic_Locale_News_deDE.lua`
> CraftingOrderClassic_Locale_News_deDE.lua — traductions de l'onglet « Nouveautés » (deDE).
> Extrait de _Locale_deDE.lua (plafond anti-monolithe). Clé FR → texte DE, chargé APRÈS _Locale.lua.

### `CraftingOrderClassic_Locale_News_esES.lua`
> CraftingOrderClassic_Locale_News_esES.lua — traductions de l'onglet « Nouveautés » (esES).
> Extrait de _Locale_esES.lua (plafond anti-monolithe). Clé FR → texte ES, chargé APRÈS _Locale.lua.

### `CraftingOrderClassic_Elemental.lua`
> CraftingOrderClassic_Elemental.lua — pseudo-« métier » de récolte « Élémentaire ».
> 
> Les marchandises élémentaires (eau/feu/terre/air : essences, motes, primals, cristallisés,
> éternels) ne sont PAS récoltées par un métier : elles tombent des mobs élémentaires / sont
> farmées. On les expose quand même dans l'onglet Récolte comme un faux métier pour pouvoir
> en commander. Données côté ADDON (pas dans CraftLink) car ce n'est pas une vraie profession.
> 
> exp : extension qui introduit l'objet — 1 = Classic, 2 = TBC, 3 = WotLK. Combiné au filtre
> d'existence client (GetItemInfoInstant), un client n'affiche QUE ce qu'il connaît ; le sélecteur
> de version permet en plus de restreindre à une extension précise (utile sur TBC/WotLK).

### `CraftingOrderClassic_UI_Skin.lua`
> CraftingOrderClassic_UI_Skin.lua — tokens + helpers SÉMANTIQUES du skin (métiers, statuts, rareté,
> quantités, icônes natives) et petits widgets d'affichage. Les CONSTRUCTEURS de chrome Blizzard
> natif vivent dans CraftingOrderClassic_UI_Skin_Native.lua (même table `Skin`) — voir la skill
> projet `coc-native-ui`. La palette « tavern » résiduelle ne sert plus qu'aux ACCENTS texte/lignes
> (or des libellés, hover, sélection) ; le chrome (cadre, onglets, boutons) est natif.
> INTOUCHABLE : le langage couleur des statuts d'ordre et la rareté d'objet ne sont jamais recolorés.

**API** : `Skin.ProfLabel(p)` · `Skin.ProfIcon(key)` · `Skin.StatusInfo(s)` · `Skin.RarityColor(itemID)` · `Skin.QtyText(o)` · `Skin.QtySuffix(o)` · `Skin.FormatDuration(sec)` · `Skin.KnowsProf(r, p)` · `Skin.KnowsProfOrSeen(r, p)` · `Skin.InSource(r, src)` · `Skin.MakeMoneyRow(parent, x, y)` · `Skin.FirstChar(s)` · `Skin.ItemExists(itemID)` · `Skin.Icon(itemID, spellID)` · `Skin.MakeBadge(parent, size)` · `Skin.SearchHint(parent, editbox, text)` · `Skin.MakeCheck(parent, size)` · `Skin.WireItemTooltip(row)` · `Skin.ChatLinkFor(link, itemID, spellID)` · `Skin.WireItemLink(row)` · `Skin.MakeStatusIcon(parent, size)` · `Skin.MoneyIcon(parent, kind, anchorTo)` · `Skin.AutoHideScroll(scrollName, content)` · `Skin.ApplyShadow(fs)` · `Skin.SkinFrameBackdrop(f)` · `Skin.SkinWell(f)` · `Skin.MakeSeparator(parent, offsetY)`

### `CraftingOrderClassic_UI_Skin_Native.lua`
> CraftingOrderClassic_UI_Skin_Native.lua — kit de chrome Blizzard NATIF (le « framework » UI de COC).
> Complète CraftingOrderClassic_UI_Skin.lua : Skin.lua garde les TOKENS (couleurs, hex) et les helpers
> SÉMANTIQUES (métiers, statuts, rareté, quantités) ; ce fichier porte les CONSTRUCTEURS de chrome.
> Kit INTERNE à COC, pas une lib LibStub : un seul consommateur (TradeScanner garde son skin tavern,
> décision « COC seulement » 2026-07-11) — on promouvra en lib partagée si un 2ᵉ client apparaît.
> Tout vit dans la même table `Skin` : les appelants ne savent pas quel fichier définit quoi.
> 
> API : MakeWindow (fenêtre ButtonFrameTemplate complète) · SetWindowPortrait · SetPortraitClickable
> (médaillon-déclencheur + flèche) · MakeTabs (languettes natives TabButtonTemplate, en haut) · MakeGoldButton (bouton 3-tranches
> natif, anti-reskin, variante sécurisée) · MakeFlatRow (ligne de liste/flyout plate) · MakeIconButton
> (carré à icône, filtres/pills) · MakeFilterButton (bande de filtre style hôtel des ventes) · MakeFlyout
> (dropdown maison : puits + closer + pool de lignes) · MakeDropdown (dropdown NATIF UIDropDownMenu,
> le sélecteur gris de l'HdV) · MakeCheckButton (case à cocher NATIVE, style « Objets utilisables »
> de l'HdV) · FieldLabel (légende de champ style HdV). Les primitives de SECTIONS (MakeInset,
> MakeDivider, MakeDividerV) vivent dans _UI_Skin_Sections.lua (même table Skin, anti-monolithe).
> MakeFlyout vs MakeDropdown : le premier est un MENU maison (géométrie libre, lignes riches : métiers,
> menu minimap) ; le second est le SÉLECTEUR natif (une valeur parmi N, coche, look HdV) — préférer
> MakeDropdown dès qu'il s'agit de choisir UNE valeur dans une liste courte.
> INTOUCHABLE ici aussi : le langage couleur (statuts d'ordre, rareté) n'est jamais recoloré.

**API** : `Skin.MakeGoldButton(parent, w, h, text, template)` · `Skin.MakeWindow(name, w, h, opts)` · `Skin.SetWindowPortrait(f, tex)` · `Skin.SetPortraitClickable(f, onClick, tooltipText)` · `Skin.MakeTabs(f, defs, onSelect, opts)` · `Skin.MakeFlatRow(parent, w, h)` · `Skin.PersonHighlight(row)` · `Skin.MakeArtisanRow(parent, w, h)` · `Skin.MakeFlyout(name, w, opts)` · `Skin.MakeIconButton(parent, size, tex)` · `Skin.MakeDropdown(name, parent, w, items, opts)` · `Skin.MakeCheckButton(parent, text, size)` · `Skin.FieldLabel(parent, text, x, y)` · `Skin.MakeFilterButton(parent, w, h, text)`

### `CraftingOrderClassic_UI_Skin_Sections.lua`
> CraftingOrderClassic_UI_Skin_Sections.lua — kit de chrome natif, volet SECTIONS : comment on
> découpe l'intérieur d'une fenêtre en blocs et en zones. Même table `Skin` que _UI_Skin.lua /
> _UI_Skin_Native.lua (découpé de Native pour l'anti-monolithe : les appelants ne voient pas la
> frontière entre fichiers).
> 
> LE MODÈLE BLIZZARD, en deux échelles (les deux observées dans la source, cf. commentaires) :
>   · BLOCS FRANCHEMENT SÉPARÉS → un `MakeInset` chacun (fenêtre des Canaux : deux insets, un gap).
>     La bordure NineSlice d'un inset a une ÉPAISSEUR : deux insets accolés = deux bordures dos à dos,
>     un jeu inévitable — ne JAMAIS coller deux insets (payé sur l'onglet Commande, 1ʳᵉ passe).
>   · SECTIONS SOLIDAIRES d'un même bloc → UNE surface, et des FILETS fins à l'intérieur
>     (`MakeDivider`/`MakeDividerV`) — le modèle de la liste d'Amis, pointé par le user.

**API** : `Skin.MakeInset(parent, x1, y1, x2, y2, opts)` · `Skin.MakeDivider(parent, x1, x2, y, heavy, opts)` · `Skin.MakeDividerV(parent, x, top, bottom, heavy)` · `Skin.ScrollTrack(scrollName)` · `Skin.MakeSections(panel, spec)`

### `CraftingOrderClassic_UI_Skin_HelpPlate.lua`
> CraftingOrderClassic_UI_Skin_HelpPlate.lua — kit d'AIDE CONTEXTUELLE (le « bouton i » de retail).
> À NE PAS confondre avec _UI_Help.lua (l'onglet « Aide », une PAGE de doc défilante qu'on lit). Ici
> c'est l'overlay EN PLACE : un clic fige la fenêtre et pose des bulles sur ses vrais contrôles. Le jeu
> retail a les deux ; complémentaires (bulles courtes ici, détail dans l'onglet Aide).
> 
> Même table `Skin` que les autres _UI_Skin*. On EMPRUNTE le système natif `Blizzard_HelpPlate` (chargé
> sur Era : dépendance dure de Blizzard_UIPanels_Game) : un voile plein écran `HelpPlateCanvas` capte
> TOUS les clics de la fenêtre, et chaque « tuile » surligne un rectangle avec une bulle fléchée au
> survol. Zéro asset (l'icône est `Interface\common\help-i`, celle de retail).
> 
> LE PARI « aide sur les objets SPEC » (idée user) : `Skin.MakeSections` rend `{ [id] = frame }`, donc
> chaque section EST une vraie frame positionnée. Au lieu de coder les coordonnées à la main (ce que
> fait Blizzard), on TAGUE le nœud SPEC (`help = "<id>"`, `helpDir = "LEFT|RIGHT|UP|DOWN"`) et on dérive
> la `HighLightBox` du rectangle RÉEL de la frame, à l'ouverture. Le TEXTE reste du contenu (locale),
> déclaré côté consommateur — la SPEC ne porte que le point d'accroche (cf. discipline SPEC=structure).
> 
> ⚠️ ÉCHELLES : le voile est reparenté sur UIParent (donc à l'échelle UIParent) mais ANCRÉ sur la
> fenêtre. On normalise chaque rectangle en PIXELS ÉCRAN puis on divise par l'échelle du voile
> (`HelpPlate.GetEffectiveScale`) → robuste quelle que soit l'échelle d'UI, sans supposer scale=1.

**API** : `Skin.CollectHelp(spec)` · `Skin.MakeHelpButton(parent, onToggle, opts)` · `Skin.ShowHelp(win, entries, mainButton)` · `Skin.HideHelp()` · `Skin.HelpIsOpen()`

### `CraftingOrderClassic_ShareReagents.lua`
> CraftingOrderClassic_ShareReagents.lua — « liste de courses » : diffuser en un clic les réactifs
> d'une recette (vue métier) ou d'une commande (carte) dans un canal de discussion, avec le LIEN objet
> de chaque réactif. Un bouton-icône dans la zone réactifs ouvre cette popup : dropdown de canal
> (Guilde / Dire / Groupe-Raid / canaux num.) + Envoyer. Le texte envoyé est HUMAIN (lisible en chat),
> donc localisé dans la langue de l'émetteur — à ne pas confondre avec les verbes réseau neutres.
> 
> ⚠️ SendChatMessage est PROTÉGÉ (hardware-event only) : l'envoi ne part QUE depuis le clic « Envoyer »
> (vrai événement matériel). Les liens objets sont longs (~60 car.) → on DÉCOUPE en plusieurs lignes
> sous la limite de 255 octets du chat (buildLines). Le dernier canal choisi est mémorisé (db.shareChannel).

**API** : `SR:Open(title, raw)`

### `CraftingOrderClassic_UI.lua`
> CraftingOrderClassic_UI.lua — fenêtre principale (chrome Blizzard natif, kit UI_Skin_Native).
> Onglets : Carnet / Commande / Récolte / Artisans / Mes artisans / Aide / Nouveautés.
> Lit le cache (COC.db.orders + Directory), jamais le réseau directement.

**API** : `UI:Build()` · `UI:BuildTabs(f)` · `UI:ShowTab(id)` · `UI:BuildOrdersTab(f)` · `UI:Toast(text, icon)` · `UI:RefreshOrders()` · `UI:RefreshHandoff()` · `UI:RefreshSoon()` · `UI:Refresh()` · `UI:Toggle(tab)`

### `CraftingOrderClassic_UI_HelpPlate.lua`
> CraftingOrderClassic_UI_HelpPlate.lua — AIDE CONTEXTUELLE de la FENÊTRE PRINCIPALE (« bouton i »).
> Même système natif que la Vue Métier (kit _UI_Skin_HelpPlate.lua : voile qui fige les clics + bulles),
> mais la fenêtre principale a 7 ONGLETS partageant le cadre → l'aide est DISPATCHÉE selon l'onglet
> actif (`UI.activeTab`). Un seul bouton `i`, un registre `_HelpConfigFor(tab)` : chaque onglet fournit
> ses zones SPEC (nodes), l'accès à ses sections (sec), ses textes et ses contrôles hors-SPEC. Palier
> courant : l'onglet Commande (post) ; Récolte/Artisans/… s'ajouteront comme de nouvelles branches.
> Échap-ferme-l'aide + icônes inline sont dans le kit → gratuits ici. NE PAS confondre avec l'onglet
> « Aide » (_UI_Help.lua, page de doc défilante).

### `CraftingOrderClassic_UI_Post_Layout.lua`
> CraftingOrderClassic_UI_Post_Layout.lua — GÉOMÉTRIE de l'onglet « Commande » : colonnes, zones,
> séparateurs. Chargé AVANT _UI_Post.lua (cf. les 3 .toc) : les autres fichiers de l'onglet lisent
> `UI.POST` au chargement et se parentent aux zones via `UI:PostSec(id)`.
> 
> PRINCIPE (refactor 2026-07-12) : le contenu d'une zone est ENFANT de sa zone, en offsets RELATIFS
> (« PAD sous le bord ») — plus de coordonnées absolues de panneau recopiées entre fichiers. Déplacer /
> redimensionner une section = éditer UNE hauteur dans COLUMNS ci-dessous, rien d'autre.
> 
> MODÈLE VISUEL (3ᵉ passe, la bonne — cf. liste d'Amis, pointée par le user) : UNE SEULE SURFACE, le
> marbre `f.Inset` que MakeWindow fournit déjà, et des FILETS fins gravés aux jointures — PAS un puits
> par section. Historique payé :
>   · 1ʳᵉ passe, un inset par section accolés → les bordures NineSlice ont une épaisseur, deux blocs
>     voisins = deux bordures dos à dos, du jeu partout ;
>   · 2ᵉ passe, deux puits (un par colonne) → mieux, mais encore des doubles bordures aux frontières
>     et l'ornement DialogBox-Divider trop massif en interne ;
>   · 3ᵉ passe : zéro inset ajouté, filets `Skin.MakeDivider`/`MakeDividerV` (l'art de la liste
>     d'Amis) sur les jointures CALCULÉES. Le jeu est impossible par construction : une jointure n'est
>     pas un espace entre deux cadres, c'est une ligne posée sur un bord partagé.
> `Skin.MakeInset` reste la bonne brique pour des blocs FRANCHEMENT séparés (modèle « Canaux ») —
> simplement pas pour des sections jointives.

**API** : `UI:PostSec(id)`

### `CraftingOrderClassic_UI_Post.lua`
> CraftingOrderClassic_UI_Post.lua — onglet « Commande » : sélection de plan (gauche) +
> réactifs « je fournis » / commission g-s-c / ciblage artisan (droite). Chargé après _UI.lua.
> GÉOMÉTRIE : les blocs de section et les métriques vivent dans _UI_Post_Layout.lua (chargé avant).
> Ici, chaque zone se parente à SON bloc (`UI:PostSec(id)`) et s'ancre en coordonnées RELATIVES au
> bloc — plus aucun offset absolu de panneau (cf. l'en-tête du fichier Layout pour le pourquoi).

**API** : `UI:BuildPostTab(f)` · `UI:RefreshPost()` · `UI:RefreshPostPlans()` · `UI:SelectPostPlan(entry)` · `UI:DoPostOrder()`

### `CraftingOrderClassic_UI_Post_Detail.lua`
> CraftingOrderClassic_UI_Post_Detail.lua — onglet « Commande », PANNEAU DROIT : en-tête du plan
> sélectionné (icône + cadre doré + nom + niveau), liste des réactifs « je fournis », et la rangée
> commission. Sorti de _UI_Post.lua (anti-monolithe : le fichier hôte butait sur les 500 lignes).
> Chargé APRÈS _UI_Post_Layout.lua (lit UI.POST) ; ses méthodes sont appelées par _BuildPostRight
> (_UI_Post.lua) et par les refresh de l'onglet — tout est méthode de COC.UI, donc inter-fichiers.
> 
> GÉOMÉTRIE : chaque morceau se parente à SA sous-zone SPEC (cf. _UI_Post_Layout.lua, nœud "detail") :
>   ItemSelected = cols{ craftIcon, craftText, providePill } · reagentsList = rows{ reagHeader, reagBody }.
> Ajouter du padding à l'un = éditer la SPEC, rien ici. Le CONTENU (textes, widgets) vit ici.

**API** : `UI:RefreshPostPlanDetail()` · `UI:RefreshPostReagents()`

### `CraftingOrderClassic_UI_Post_Artisans.lua`
> CraftingOrderClassic_UI_Post_Artisans.lua — onglet « Commande », section droite basse :
> boutons source, liste des artisans, ciblage (@Nom), libellé destinataire, bouton Poster.
> Extrait de _UI_Post.lua (2026-07-02, anti-monolithe) : partage le même namespace UI.

**API** : `UI:RefreshPostArtisans()` · `UI:OpenPostForArtisan(name, prof)`

### `CraftingOrderClassic_UI_Post_Categories.lua`
> CraftingOrderClassic_UI_Post_Categories.lua — onglet « Commande », panneau gauche :
> regroupe la LISTE DES PLANS en sections type fenêtre native (emplacement puis type pour les
> équipements, type pour les armes, catégorie pour le reste). Extrait de _UI_Post.lua
> (anti-monolithe) : partage le même namespace UI. Chargé après _UI_Post_Artisans.lua.
> 
> La catégorie est dérivée de GetItemInfoInstant, qui lit la DB STATIQUE du client → disponible
> SANS cache (contrairement à GetItemInfo pour le nom), donc le classement est fiable au 1er rendu.

**API** : `UI:TogglePostSection(ckey)`

### `CraftingOrderClassic_UI_Post_Paperdoll.lua`
> CraftingOrderClassic_UI_Post_Paperdoll.lua — onglet « Commande », vue SILHOUETTE de l'Enchantement.
> Choisir un enchant en cliquant l'EMPLACEMENT (comme sur son personnage) au lieu de fouiller ~300
> plans : clic sur l'icône → menu des stats de cet emplacement → clic sur une stat → ses variantes,
> de la plus forte à la plus faible. La sélection rejoint le flux NORMAL de l'onglet (SelectPostPlan
> avec l'entrée du CATALOGUE) : réactifs, commission, ciblage d'artisan et Poster restent inchangés.
> Chargé après _UI_Post_Categories.lua ; partage le namespace UI. NB : _Enchant.lua est chargé APRÈS
> nous (cf. les 3 .toc) → ne toucher à COC.Enchant qu'au RUNTIME, jamais au chargement.
> 
> ALTERNATIVE à la liste, jamais un remplacement (d'où la bascule dans la bande de filtres) : les
> produits de désenchantement (essences, poussières, éclats) et les huiles/baguettes n'ont pas
> d'emplacement — ils n'existent pas ici et resteraient introuvables sans la liste.
> 
> Deux appuis natifs, donc zéro asset à livrer et zéro clé de locale pour le chrome d'emplacement :
>   · `GetInventorySlotInfo(slotName)` rend le chemin de la TEXTURE en 2ᵉ retour (PaperDollFrame.lua:711) ;
>   · `_G[strupper(slotName)]` rend son LIBELLÉ déjà localisé (PaperDollFrame.lua:873).
> Ce que le métier sait enchanter se DÉRIVE du catalogue (Enchant:HasCatalogFor), jamais d'une liste
> en dur : ça change d'une couche à l'autre, et ni la tête ni les épaules n'ont d'enchant nulle part
> (arcanums/inscriptions = des OBJETS). Ces emplacements-là s'affichent DÉSATURÉS : la silhouette
> reste lisible, et un emplacement mort se voit au lieu de manquer.

### `CraftingOrderClassic_UI_Post_LazyGold.lua`
> CraftingOrderClassic_UI_Post_LazyGold.lua — onglet « Commande » : couche Lazy Gold (lecture seule).
>   * barre d'outils (pièce = tri par rentabilité, « 123 » = valeurs exactes) — mêmes codes que la
>     vue métier, et le mode exact est le MÊME réglage partagé (db.lgExactProfit) ;
>   * indicateur de profit sur chaque ligne de la LISTE DES PLANS ;
>   * tri par rentabilité : liste à PLAT (les sections disparaissent), du plus rentable au moins.
> Tout est masqué/inerte si Lazy Gold n'est pas installé — COC reste autonome.

### `CraftingOrderClassic_UI_Gather_Layout.lua`
> CraftingOrderClassic_UI_Gather_Layout.lua — GÉOMÉTRIE de l'onglet « Récolte » : la SPEC (structure
> éditable, cf. l'onglet Commande qui a VALIDÉ le modèle 2026-07-12) + les métriques dérivées.
> Chargé AVANT _UI_Gather.lua (cf. les 3 .toc). Même contrat que _UI_Post_Layout.lua :
>   · la SPEC déclare la STRUCTURE (zones, tailles, pads) — le CONTENU vit dans les builders ;
>   · pad/padL/padR/padT/padB réglables par nœud ; un écart = spacer explicite `{ h = n, sep = false }` ;
>   · les listes LISENT la largeur de leur zone (GetWidth au build) → régler la SPEC suffit.
> Miroir de l'onglet Commande : mêmes colonnes (gauche 333 / droite), mêmes ids quand la zone joue le
> même rôle (filters/srch, detail/ItemSelected, price, scope) — on apprend UNE grammaire, pas deux.

**API** : `UI:GatherSec(id)`

### `CraftingOrderClassic_UI_Gather.lua`
> CraftingOrderClassic_UI_Gather.lua — onglet « Récolte » : ressources de récolte (minéraux,
> herbes, cuirs, poissons) + demande de quantité + prix par pile + ciblage récolteur.
> GÉOMÉTRIE : SPEC déclarative dans _UI_Gather_Layout.lua (chargé avant) — zones via UI:GatherSec(id),
> contenu en offsets RELATIFS à sa zone, largeurs LUES sur les zones. Même modèle que l'onglet
> Commande (validé 2026-07-12) : éditer la SPEC suffit pour bouger/padder les blocs.

**API** : `UI:BuildGatherTab(f)` · `UI:RefreshGather()` · `UI:RefreshGatherList()` · `UI:SelectGatherItem(entry)` · `UI:DoGatherOrder()`

### `CraftingOrderClassic_UI_Gather_Categories.lua`
> CraftingOrderClassic_UI_Gather_Categories.lua — onglet « Récolte », panneau gauche : repliage des
> en-têtes et remplissage des lignes (en-tête de section/sous-catégorie, ou ressource). Extrait de
> _UI_Gather.lua (anti-monolithe) ; même namespace UI, même patron que _UI_Post_Categories.lua.
> 
> Le REGROUPEMENT lui-même (sections, sous-catégories, tri) est délégué à COC.RecipeCats:BuildDisplay,
> appelé par RefreshGatherList — un métier de récolte sans table de catégories déclarée garde la
> liste plate d'avant. Particularité de la récolte : une peau ou un minerai n'est PAS une recette,
> donc il n'a pas de niveau `learnedAt` ; c'est l'ordre déclaré dans _RecipeCats_Gathering.lua qui
> fait foi (voir le contrat dans _RecipeCats.lua).

**API** : `UI:ToggleGatherSection(ckey)`

### `CraftingOrderClassic_UI_Artisans_Layout.lua`
> CraftingOrderClassic_UI_Artisans_Layout.lua — GÉOMÉTRIE de l'onglet « Artisans » (annuaire social).
> Chargé AVANT _UI_Artisans.lua (cf. les 3 .toc). Même contrat que les Layouts Commande/Récolte :
> SPEC = structure éditable (zones, tailles, pads), contenu dans les builders, largeurs LUES sur les
> zones. Deux colonnes : SIDEBAR (sources + ajout de joueur) · zone principale (bande de filtre
> métier + liste des artisans avec sa gouttière de scrollbar).
> Le panneau « En sourdine » (UI_Artisans_Muted) est un MODE de la zone liste : il se superpose aux
> mêmes zones (profFilter/artisansList), le basculement reste piloté par _ShowMutedMode.

**API** : `UI:ArtSec(id)`

### `CraftingOrderClassic_UI_Artisans.lua`
> CraftingOrderClassic_UI_Artisans.lua — onglet « Artisans » : annuaire social.
> Sidebar SOURCE (Guilde/Amis/Ajoutés + compteurs) + ajout manuel ; à droite, pills de filtre
> métier + lignes artisan (présence, niveau, métiers, source, Chuchoter). Lit Directory (cache).

**API** : `UI:BuildArtisansTab(f)` · `UI:RefreshArtisans()`

### `CraftingOrderClassic_UI_Artisans_Groups.lua`
> CraftingOrderClassic_UI_Artisans_Groups.lua — fusion « une ligne par JOUEUR » (rerolls).
> 
> Couche d'AGRÉGATION D'AFFICHAGE au-dessus du roster : les persos d'un même joueur (liens ALT
> VÉRIFIÉS par réciprocité — Dir:GroupLeader/PlayerChars, jamais une claim unilatérale) sont pliés
> en une ligne, perso principal en vitrine. Le ROUTAGE ne change pas : la cible postée reste un
> PERSO (résolue par _ResolvePostChar via Skin.KnowsProf STRICT sur ses données directes), et
> Skin.KnowsProf/KnowsProfOrSeen restent intacts (règle verrouillée par le SelfTest).
> Partage le namespace UI ; chargé APRÈS CraftingOrderClassic_UI_Artisans.lua (.toc) qui exporte
> UI._ProfsList / UI._SrcTag.

### `CraftingOrderClassic_UI_Artisans_Icons.lua`
> CraftingOrderClassic_UI_Artisans_Icons.lua — onglet « Artisans » : tout ce qui est ICÔNE de métier.
>   1. les pills de filtre métier (icône seule, plus de texte : 10 métiers tiennent sur une rangée) ;
>   2. les icônes de métier d'une ligne artisan : contour de rentabilité (Lazy Gold), tooltip, et
>      CLIC → onglet Commande pré-ciblé sur CET artisan et CE métier (UI:OpenPostForArtisan).
> Extrait de _UI_Artisans.lua (plafond anti-monolithe).

### `CraftingOrderClassic_UI_Artisans_Muted.lua`
> CraftingOrderClassic_UI_Artisans_Muted.lua — panel « En sourdine » de l'onglet Artisans.
> Vue de GESTION des joueurs mis en sourdine (COC.db.mutedPlayers, cf. CraftingOrderClassic_Moderation) :
> liste triée nom + raison + durée restante (permanent / 42min / expiré), un bouton « Rétablir » par
> ligne (démute → COC.Moderation:Unmute). La donnée vient de Mod:MutedList, PAS du roster : un muté
> n'est pas forcément un artisan connu. Affiché quand la source de la sidebar Artisans = « muted » —
> le basculement (montrer/cacher pills+scroll artisans ↔ ce panel) est piloté par RefreshArtisans via
> _ShowMutedMode. Vit dans le MÊME panel que la liste d'artisans ; chargé après UI_Artisans.lua.

**API** : `UI:RefreshMuted()`

### `CraftingOrderClassic_UI_MyArtisans_Layout.lua`
> CraftingOrderClassic_UI_MyArtisans_Layout.lua — GÉOMÉTRIE de l'onglet « Mes artisans ».
> Chargé AVANT _UI_MyArtisans.lua (cf. les 3 .toc). Même contrat que les autres Layouts : SPEC =
> structure éditable, contenu dans les builders, largeurs LUES sur les zones.
> Particularité : un BANDEAU pleine largeur (opt-in de partage + vitrine) au-dessus des deux
> colonnes → la racine est UNE colonne, et le découpage gauche│droite est un nœud `cols` interne
> (`major = true` sur la colonne recettes = jointure verticale LOURDE, l'équivalent de la frontière).

**API** : `UI:MyArtSec(id)`

### `CraftingOrderClassic_UI_MyArtisans.lua`
> CraftingOrderClassic_UI_MyArtisans.lua — onglet « Mes artisans » : vue agrégée des métiers du
> COMPTE (tous mes rerolls du royaume), en mode « connu ». 100 % LOCAL (lit ma SavedVariable via
> Dir:AggregateMyProfs, aucun réseau, marche même avec /co alts off). Deux zones (patron Récolte) :
> à gauche le sélecteur de métiers du compte, à droite les recettes connues du métier choisi + les
> persos qui les portent. Chargé après UI_Artisans_Groups.lua (réutilise Skin/CraftLink).

**API** : `UI:BuildMyArtisansTab(f)` · `UI:RefreshMyArtisans()`

### `CraftingOrderClassic_UI_MyArtisans_LazyGold.lua`
> CraftingOrderClassic_UI_MyArtisans_LazyGold.lua — onglet « Mes artisans » : couche Lazy Gold.
>   * barre d'outils : pièce (tri rentabilité), « 123 » (valeurs exactes, réglage PARTAGÉ avec la
>     vue métier), et « Tout le royaume » ;
>   * « Tout le royaume » = TOUS les métiers du compte fusionnés en une seule liste à plat triée par
>     profit : la réponse d'un coup d'œil à « lequel de mes rerolls a des sous à se faire ? ».
> Lecture seule, inerte si Lazy Gold est absent.

### `CraftingOrderClassic_UI_Help.lua`
> CraftingOrderClassic_UI_Help.lua — onglet Aide : page unique défilante qui explique les autres
> onglets (Carnet/Commande/Récolte/Artisans), la Vue Métier et le réseau. Contenu data-driven
> (table HELP) rendu par un renderer générique → ajouter une section = ajouter une entrée localisée.

**API** : `UI:BuildHelpTab(f)` · `UI:RefreshHelp()`

### `CraftingOrderClassic_UI_News.lua`
> CraftingOrderClassic_UI_News.lua — onglet « Nouveautés » : notes de version (changelog) affichées
> EN JEU, version par version, la plus récente en tête. Contenu figé et localisé, peint UNE fois à la
> construction (même structure que l'onglet Aide). Source humaine : CHANGELOG.md — garder les deux en
> phase à chaque release (ici : les points forts localisés, pas la prose complète du .md).

**API** : `UI:BuildNewsTab(f)` · `UI:RefreshNews()`

### `CraftingOrderClassic_Social.lua`
> CraftingOrderClassic_Social.lua — couche sociale passive (socle).
> * Social:ProfSummary(nom) : résumé métiers+niveaux d'un joueur présent dans Directory.roster
>   (icônes + « 250/300 » via SK, repli bitfield RK). Réutilisé par le tooltip MONDE (ci-dessous),
>   le tooltip d'AMI et le panneau de GUILDE (_Social_Roster.lua), et le menu (_Social_Menu.lua).
> * Découverte au croisement : survol / cible / groupe → whisper PING+HI throttlé (Dir:DiscoverPlayer).

**API** : `Social:MaybeDiscover(name)` · `Social:BNetCharFromAccount(acc)` · `Social:ProfSummary(name)` · `Social:CooldownLines(r, cap, profFilter)` · `Social:HasRecipeDetail(name)` · `Social:RecipeDetail(name, perProfCap)` · `Social:OrderableProfs(name)` · `Social:Start()` · `Social:Diag(name)`

### `CraftingOrderClassic_Social_Menu.lua`
> CraftingOrderClassic_Social_Menu.lua — entrées « Crafting Order » du menu contextuel joueur.
> Utilise la NOUVELLE API Menu (Menu.ModifyMenu / rootDescription), sans taint. Remplace l'ancienne
> injection UnitPopupMenus/UnitPopupButtons, MORTE depuis le refactor menu de Classic Era
> (table UnitPopupButtons absente du client → l'ancien code était un no-op silencieux ; cf. mémoire
> coc-classic-menu-api). Les entrées n'apparaissent QUE pour un PORTEUR de l'addon présent dans le
> roster (amis, guildies EN LIGNE, joueurs croisés) — PAS pour un simple non-porteur vu crafter au
> scan (nonAddon) : les actions supposent l'addon en face. Un guildie HORS-LIGNE n'ouvre aucun menu
> (garde Blizzard) → il est couvert par le panneau de guilde (_Social_Roster.lua).

**API** : `Social:InstallMenus()`

### `CraftingOrderClassic_Social_Roster.lua`
> CraftingOrderClassic_Social_Roster.lua — affichage des métiers sur les fenêtres NATIVES.
> * Liste d'AMIS : petit tooltip collé à droite du tooltip natif (post-hook FriendsFrameTooltip_Show).
> * GUILDE : « sidecar » sous le panneau détail natif (post-hook GuildStatus_Update). Enfant de
>   GuildMemberDetailFrame → se masque tout seul avec lui ; couvre AUSSI les guildies hors-ligne
>   (que le clic-droit ne peut pas atteindre — cf. _Social_Menu.lua).
> Source unique : Social:ProfSummary(nom) → nil si le joueur n'a pas l'addon (rien ne s'affiche).

**API** : `Social:WireRosterUI()`

### `CraftingOrderClassic_Minimap.lua`
> CraftingOrderClassic_Minimap.lua — bouton minimap (toggle du carnet). Icône native WorkOrder.
> Position persistée en angle (COC.db.minimapAngle). Glisser = repositionner autour de la minimap.

**API** : `UI:BuildMinimapButton()` · `UI:ToggleProfMenu()`

### `CraftingOrderClassic_Nameplate.lua`
> CraftingOrderClassic_Nameplate.lua — icône « recherche de travail » (LFW) sur les plaques.
> 
> Quand un joueur marqué LFW (cf. Directory_LFW : Dir:LFWOf) a une plaque visible, on accroche l'icône
> de SON métier au-dessus. Events NAME_PLATE_UNIT_ADDED/_REMOVED + C_NamePlate.GetNamePlateForUnit /
> GetNamePlates / frame.namePlateUnitToken (API vérifiée dans la source Classic Era). Purement DÉCORATIF
> (aucune frame protégée touchée), no-op si les plaques sont désactivées (C_NamePlate absent).
> ⚠️ Les artisans LFW sont en général AMIS/même faction → visible seulement si les plaques AMIES sont
> activées (CVar nameplateShowFriends). ⚠️ Sur l'UI MODERNE (TBC 2.5.6, Era 1.15.9+), les plaques amies
> en INSTANCE (donjon/raid) sont « forbidden » côté C++ : invisibles pour le code addon insécure (ni
> GetNamePlates ni NAME_PLATE_UNIT_ADDED) → pas de badge en instance, par design Blizzard, aucune parade.
> Vérifié en jeu 2026-07-15 (Monastère : rien en instance, badge OK dans le hall monde-ouvert).

**API** : `NP:Refresh(name)` · `NP:Start()`

### `CraftingOrderClassic_ProfOrders.lua`
> CraftingOrderClassic_ProfOrders.lua — COORDINATEUR d'événements de la fenêtre métier.
> La vue métier custom (3 colonnes, _ProfWindow*) est désormais la vue PAR DÉFAUT (maquette
> designer) : ce module ne rend plus d'overlay flottant. Il route les events TRADE_SKILL_* /
> CRAFT_* vers COC.ProfWindow (neutralise le natif, ouvre / rafraîchit / ferme notre fenêtre).
> « Vue Blizzard » (PW:IsEnabled()==false) → on laisse la fenêtre native, on ne fait rien.

**API** : `ProfOrders:Start()`

### `CraftingOrderClassic_RecipeCats.lua`
> CraftingOrderClassic_RecipeCats.lua — SOUS-CATÉGORIES de recettes (moteur + registre).
> 
> POURQUOI : le client Classic Era ne distingue pas les types de consommables — toutes les potions,
> élixirs et flacons d'alchimie ont la MÊME classe d'objet (« Consommable »). GetItemInfoInstant ne
> peut donc pas répondre « ceci est une potion de mana » : l'information n'existe pas côté jeu, il
> faut l'apporter. C'est ce que fait ce module : un niveau de regroupement EN PLUS de la section
> dérivée de l'objet (COC.SectionOf), déclaré à la main par métier.
> 
> ARBRE OBTENU dans la vue métier :   Consommable  >  Potions de mana  >  les recettes
>                                     (COC.SectionOf)   (ce module)        (tri par niveau ↓)
> 
> CONTRAT DES DONNÉES (voir _RecipeCats_Alchemy.lua pour l'exemple) :
>   * on déclare des groupes de itemID — JAMAIS des noms. Les noms d'objets sont localisés par le
>     client, donc toute règle textuelle (« ça contient Mana ») casserait hors anglais ;
>   * l'ORDRE des itemID dans un groupe n'a aucune importance : le tri interne est fait par le
>     niveau de métier de la recette (learnedAt, donnée statique CraftLink), du plus haut au plus
>     bas. Aucune dépendance au cache d'objets du client → classement correct dès le 1er rendu ;
>   * la SECTION parente n'est pas déclarée : chaque objet garde celle que COC.SectionOf lui donne.
>     Un groupe peut donc s'afficher sous deux sections (les huiles d'alchimie sont pour partie des
>     consommables, pour partie des composants) — c'est voulu, chaque en-tête est unique par couple
>     (section, sous-catégorie) ;
>   * APPARTENANCE MULTIPLE assumée : un même itemID peut être listé dans PLUSIEURS groupes, et la
>     recette apparaîtra alors sous chacun. C'est nécessaire, pas un effet de bord : la potion de
>     rajeunissement rend vie ET mana, donc un artisan la cherchera aussi bien sous « soin » que
>     sous « mana ». Le classement est un système d'étiquettes, pas une partition ;
>   * tout itemID non déclaré retombe dans « Divers » de sa section : rien ne disparaît jamais de la
>     liste si la table est incomplète.
> 
> Un métier SANS table déclarée garde exactement l'affichage d'avant (sections à plat, pas de
> sous-niveau) : ce module est purement additif.

**API** : `RC:Register(profKey, groups)` · `RC:HasCategories(profKey)` · `RC:SubsOf(profKey, itemID)` · `RC:Tier(profKey, itemID)`

### `CraftingOrderClassic_RecipeCats_Group.lua`
> CraftingOrderClassic_RecipeCats_Group.lua — REGROUPEMENT partagé : transforme une liste plate
> d'entrées (recettes, plans, ressources…) en liste d'AFFICHAGE à deux niveaux :
> 
>     Section (COC.SectionOf)  >  Sous-catégorie (COC.RecipeCats)  >  les objets, triés
> 
> Écrit une fois ici parce que QUATRE listes en ont besoin et qu'elles n'ont pas la même structure
> de ligne : vue métier (recettes de l'API), onglet Commande (plans du catalogue), Mes artisans
> (recettes connues), onglet Récolte (ressources). Chacune passe juste un accesseur d'itemID ; le
> rendu des lignes reste chez elle.
> 
> DEUX POINTS NON ÉVIDENTS :
>  * un objet peut appartenir à PLUSIEURS sous-catégories (une potion de rajeunissement rend vie ET
>    mana). On émet donc une VUE par appartenance — la même entrée apparaît sous deux en-têtes. Les
>    vues héritent de l'entrée d'origine (__index), donc le code de rendu existant continue de lire
>    ses champs habituels (`e`, `name`, `index`, `ready`…) sans rien changer ;
>  * un en-tête REPLIÉ reste affiché mais masque son contenu. L'état de repliage est fourni par
>    l'appelant (nil = tout déplié — c'est ce qu'on veut pendant une recherche, sinon un résultat
>    pourrait rester invisible sous un en-tête fermé).

**API** : `RC.KeySection(sec)` · `RC.KeySub(sec, sub)` · `RC:BuildDisplay(profKey, entries, opts)`

### `CraftingOrderClassic_RecipeCats_Alchemy.lua`
> CraftingOrderClassic_RecipeCats_Alchemy.lua — sous-catégories de l'ALCHIMIE (données, éditées à la
> main). Voir _RecipeCats.lua pour le contrat ; en résumé :
>   * on liste des itemID (l'objet PRODUIT par la recette), jamais des noms — les noms sont localisés ;
>   * l'ordre des itemID dans un groupe est LIBRE : le tri se fait tout seul par niveau de métier
>     (learnedAt), du plus haut au plus bas — la potion de mana majeure passe devant la mineure ;
>   * l'ordre des GROUPES ci-dessous EST l'ordre d'affichage des sous-en-têtes ;
>   * un objet peut être listé dans PLUSIEURS groupes — c'est même le cas courant : une potion de
>     rajeunissement rend vie ET mana, un élixir de force brute donne force ET endurance. La recette
>     apparaît alors sous chaque en-tête concerné (système d'étiquettes, pas de partition) ;
>   * un objet absent de ces listes n'est pas perdu : il tombe dans « Divers » de sa section. C'est
>     le cas des recettes saisonnières (SoD), volontairement non classées ici.
> Ajouter une sous-catégorie = ajouter un groupe + sa clé dans les 3 overlays de locale.

### `CraftingOrderClassic_RecipeCats_Gathering.lua`
> CraftingOrderClassic_RecipeCats_Gathering.lua — sous-catégories des métiers de RÉCOLTE.
> GÉNÉRÉ par tools/gen_gathercats.lua (source : Wowhead) — NE PAS ÉDITER À LA MAIN.
> 
> Une peau ou un minerai n'est PAS une recette : aucun `learnedAt` à lire, le tri automatique « du
> plus haut au plus bas » n'a rien sur quoi s'appuyer. C'est donc l'ORDRE DÉCLARÉ ci-dessous qui fait
> foi (cf. le contrat dans _RecipeCats.lua) : chaque groupe est rangé du plus haut niveau au plus bas,
> d'après le niveau d'objet Wowhead. Les noms en commentaire ne servent QU'À LA RELECTURE — seuls les
> itemID comptent, le client localise tout seul.
> 
> Un itemID absent de ces listes n'est pas perdu : il tombe dans « Divers » de sa section.

### `CraftingOrderClassic_RecipeCats_Smelting.lua`
> CraftingOrderClassic_RecipeCats_Smelting.lua — sous-catégorie « Lingots » du Minage (facette FONTE).
> 
> Le Minage fusionne ses deux facettes dans les listes de commande : les MINERAIS bruts (récolte,
> déclarés en « Minerais » par RecipeCats_Gathering) ET les LINGOTS de fonte (craft). Ce fichier
> déclare le second groupe ; RC:Register APPEND (cf. _RecipeCats.lua) → le Minage porte les deux.
> 
> Contrairement aux minerais, un lingot EST une recette (learnedAt connu via itemToSpell) : le moteur
> le trie automatiquement du plus haut palier au plus bas, donc l'ordre de la liste ci-dessous est
> indifférent. Superset toutes saveurs (Vanilla/TBC/Wrath) : un lingot absent du client courant est
> simplement filtré à l'affichage (Skin.ItemExists). Chargé APRÈS RecipeCats_Gathering (parité .toc).

### `CraftingOrderClassic_RecipeCats_Enchanting.lua`
> CraftingOrderClassic_RecipeCats_Enchanting.lua — sous-catégories de l'ENCHANTEMENT.
> 
> PARTICULARITÉ : les essences, poussières et éclats ne sont PAS des recettes — on ne les fabrique
> pas, on les obtient en DÉSENCHANTANT un objet. Ils n'ont donc pas de spellID ni de `learnedAt`.
> Conséquences (cf. le contrat dans _RecipeCats.lua) :
>   * ils sont commandables (on demande à un enchanteur de désenchanter pour nous), donc l'onglet
>     Commande les laisse passer malgré l'absence de spellID (cf. RefreshPostPlans) ;
>   * sans learnedAt, le tri automatique n'a rien à lire → c'est l'ORDRE DÉCLARÉ ci-dessous qui fait
>     foi. Ils sont donc rangés à la main, du plus haut niveau au plus bas.
> Les noms en commentaire viennent de la table `disenchant` de CraftLink (Data/Vanilla/Enchanting.lua)
> et ne servent QU'À LA RELECTURE : seuls les itemID comptent, le client localise.

### `CraftingOrderClassic_Craft.lua`
> CraftingOrderClassic_Craft.lua — socle de lecture LIVE de la fenêtre métier (migration de la
> fenêtre custom depuis Guild Economy / TradeScanner_Craft.lua). Lit indifféremment l'API
> TradeSkill (métiers normaux) et l'API Craft (Enchantement / Dressage en Classic Era).
> Aucune UI ici : juste la lecture (recettes, réactifs, rang) + le déclenchement du craft.
> Reste lisible tant que la SESSION de métier est ouverte, même si la frame Blizzard est masquée.

**API** : `Craft:IsCraftOpen()` · `Craft:GetSelectedRecipe()` · `Craft:GetOpenProfessionInfo()` · `Craft:GetActiveAPI()` · `Craft:OpenProfessionKey()` · `Craft:DifficultyColor(difficulty)` · `Craft:OpenRank()` · `Craft:ReadRecipes()` · `Craft:Reagents(index)` · `Craft:MuteNativeReagents(mute)` · `Craft:Do(index, count)` · `Craft:ArmNativeSelection(index)`

### `CraftingOrderClassic_Enchant.lua`
> CraftingOrderClassic_Enchant.lua — spécifique à l'Enchantement (API Craft).
> Résout l'EMPLACEMENT équipé ciblé par un enchant (pour le bouton « Enchanter équipé » qui applique
> l'enchant DIRECTEMENT sur la pièce portée via l'attribut sécurisé `target-slot` — cf. SecureTemplates
> OnActionButtonClick : après le DoCraft, si SpellCanTargetItem(), UseInventoryItem(target-slot)).
> Parse le nom ANGLAIS canonique du catalogue CraftLink (« Enchant <Slot> - <Effet> ») → slot + effet,
> indépendamment de la langue du client. Sert AUSSI au classement de la liste de recettes :
> Emplacement (section) › Stat de base (sous-catégorie) › variantes triées par niveau.
> API publique : Enchant:Parse · Enchant:SlotFor · Enchant:SectionFor · Enchant:StatFor · Enchant:ShortName.

**API** : `Enchant:Parse(name)` · `Enchant:SlotFor(spellID)` · `Enchant:SectionFor(spellID)` · `Enchant:StatFor(spellID)` · `Enchant:CraftsForEquipLoc(equipLoc, subclassID)` · `Enchant:HasCatalogFor(word)` · `Enchant:CatalogGroups(words)` · `Enchant:ShortName(name, spellID)`

### `CraftingOrderClassic_MTSL.lua`
> CraftingOrderClassic_MTSL.lua — pont LECTURE SEULE vers l'addon « Missing TradeSkills List » (MTSL).
> 
> BUT : afficher, dans la vue métier, les recettes que le personnage courant N'A PAS encore apprises,
> et d'où elles viennent (formateur/prix, butin, quête, réputation…). Ces recettes sont par définition
> ABSENTES de la fenêtre de métier native, donc invisibles pour COC.Craft:ReadRecipes() — seule une
> base de données externe les connaît. MTSL en fournit une, complète et localisée.
> 
> DÉPENDANCE MOLLE, JAMAIS DURE : COC reste autonome. Si MTSL n'est pas installé (ou pas encore
> chargé), IsAvailable() renvoie false et la fonctionnalité s'efface — aucun plantage, aucun toc à
> modifier. On lit ses globales, on n'appelle JAMAIS son UI ni sa logique interne.
> 
> CE QU'ON LIT (globales publiques de MTSL) :
>   MTSL_DATA.skills[prof]                          toutes les recettes : { id=spellID, min_skill,
>                                                    name={langue=…}, phase, trainers/reputation/… }
>   MTSL_CURRENT_PLAYER.TRADESKILLS[prof].MISSING_SKILLS   spellID manquants pour CE perso (calculé
>                                                    par MTSL au login à partir des skills appris)
>   MTSL_DATA.npcs / zones / factions / reputation_levels   pour résoudre les sources en texte lisible.
> 
> CE QU'ON NE BAKE JAMAIS : les noms restent puisés dans MTSL au runtime selon la langue du client —
> rien n'est figé en anglais, cohérent avec le reste de l'écosystème.

**API** : `MTSL:IsAvailable()` · `MTSL:SkillDetail(profKey, spellID)` · `MTSL:MissingRecipes(profKey)` · `MTSL:MinSkill(profKey, spellID)` · `MTSL:RecipeItem(profKey, spellID)` · `MTSL:SourceKind(profKey, spellID)` · `MTSL:SourcePrice(profKey, spellID)`

### `CraftingOrderClassic_ProfWindow.lua`
> CraftingOrderClassic_ProfWindow.lua — fenêtre métier custom 3 colonnes (migration depuis
> Guild Economy) : Recettes | Détail+Craft | Commandes du métier. Remplace la fenêtre Blizzard
> (neutralisée, jamais Hide() pour garder la session lisible). Colonnes dans _Recipes / _Detail ;
> la colonne Commandes vit ici (réutilise le carnet/entrantes du métier ouvert).
> 
> Vue métier par DÉFAUT (maquette designer) : PW:IsEnabled() vrai sauf COC.db.profWindow == false.
> `/co profwindow` bascule custom ↔ « Vue Blizzard » (opt-out). Quand la vue custom est active, désactive
> le takeover de Guild Economy (TradeScannerDB.replaceProfWindow=false) → jamais deux fenêtres à la fois.

**API** : `PW.CanFulfill(o)` · `PW:NeutralizeNative()` · `PW:RestoreNative()` · `PW:Build()` · `PW:Hide()` · `PW:OpenFor(profKey)` · `PW:Refresh()` · `PW:IsEnabled()` · `PW:SetEnabled(on)` · `PW:OnProfessionShow()` · `PW:OnProfessionClose()`

### `CraftingOrderClassic_ProfWindow_Layout.lua`
> CraftingOrderClassic_ProfWindow_Layout.lua — GÉOMÉTRIE de la vue métier (fenêtre 3 colonnes).
> Chargé APRÈS ProfWindow.lua (la table PW doit exister), AVANT les modules de colonnes. Même contrat
> que les Layouts d'onglets : SPEC = structure éditable, contenu dans _Recipes/_Detail/_Orders.
> Les 3 anciens « puits » (SkinWell par colonne) deviennent le modèle UNE SURFACE + frontières
> verticales lourdes calculées — le même langage que la fenêtre principale.
> 
> MODES : la SPEC décrit la vue PLEINE (3 colonnes). Le mode COMPACT/DOCK (colonne Commandes seule,
> fenêtre 300 px) masque le panneau de sections et RE-PARENTE la zone « orders » sur la fenêtre ;
> le retour en vue pleine la re-parente au panneau avec les constantes ORD_* dérivées d'ici
> (cf. PW:_ApplyMode). Éditer la SPEC suffit : ORD_* suivent.

**API** : `PW:Sec(id)`

### `CraftingOrderClassic_ProfWindow_HelpPlate.lua`
> CraftingOrderClassic_ProfWindow_HelpPlate.lua — AIDE CONTEXTUELLE de la Vue Métier (« bouton i »).
> Glue entre le kit générique (_UI_Skin_HelpPlate.lua) et cette fenêtre : le bouton `i` hors-cadre + le
> TEXTE des bulles (contenu localisé, court — le détail vit dans l'onglet Aide, cf. _UI_Help.lua).
> Les ZONES et leur direction de bulle sont déclarées dans la SPEC (_ProfWindow_Layout.lua : champs
> help/helpDir) → exposées en PW.helpNodes ; ici on ne fait que MAPPER id → texte.

### `CraftingOrderClassic_ProfWindow_Dock.lua`
> CraftingOrderClassic_ProfWindow_Dock.lua — mode DOCK de la vue métier (« Vue Blizzard ») :
> la fenêtre native reste VISIBLE (non neutralisée) et NOTRE colonne Commandes s'épingle à sa
> droite. S'exclut de la vue custom 3 colonnes (custom = native neutralisée + 3 colonnes ; dock =
> native intacte + colonne seule) → jamais les deux à la fois. Extrait de _ProfWindow.lua
> (anti-monolithe) ; chargé APRÈS lui (PW existe).

**API** : `PW:EnsureNativeToggle(frame, key)` · `PW:OpenDock(nativeFrame)` · `PW:CloseDock()`

### `CraftingOrderClassic_ProfWindow_Toolbar.lua`
> CraftingOrderClassic_ProfWindow_Toolbar.lua — barre d'outils de la colonne Recettes (vue métier) :
> les toggles de TRI (slot recTools, à gauche : rentabilité / valeurs exactes / progression — Lazy Gold)
> et de FILTRE (slot recFilterToggles, à droite : « j'ai les matériaux » / « montée de compétence »).
> Extrait de _ProfWindow_Recipes.lua (plafond anti-monolithe) : même table PW, les build sont appelés
> par _BuildRecipes, les _Sync* par RefreshRecipes. Tri = RÉORDONNE la liste ; filtre = la RÉDUIT.

### `CraftingOrderClassic_ProfWindow_Recipes.lua`
> CraftingOrderClassic_ProfWindow_Recipes.lua — colonne GAUCHE : liste de recettes virtualisée
> (scroll), recherche, couleur par difficulté, sélection, badge « demandé » (nb de commandes
> ouvertes pour l'objet). Port de TradeScanner_ProfWindow_Recipes.lua adapté à COC.Craft.

**API** : `PW:ToggleRecipeSection(ckey)` · `PW:MissingCount()` · `PW:RefreshRecipes()` · `PW:RenderRecipes()` · `PW:SelectRecipe(e)` · `PW:GetSelectedRecipe()`

### `CraftingOrderClassic_ProfWindow_Leveling.lua`
> CraftingOrderClassic_ProfWindow_Leveling.lua — aide à la MONTÉE DE MÉTIER dans la liste de
> recettes : coût de progression (réactifs au prix Lazy Gold ÷ chance de point selon la couleur),
> badge « meilleur coût/point » sur la recette recommandée, icônes de SOURCE sur les manquantes
> (formateur / vendeur PNJ / coté à l'HV / à farmer) et tri « progression » affiné par coût.
> Les guides statiques se trompent quand l'économie du serveur diverge (vécu : shards à 10 pc alors
> que le guide dit d'acheter de la dust) — ici tout est au prix RÉEL (Auctionator via Lazy Gold).
> Tout est soft-dep : sans Lazy Gold le coût disparaît (les icônes de source restent, MTSL suffit) ;
> sans MTSL, pas d'icônes (les manquantes n'existent pas). Appelé par _ProfWindow_Recipes sous garde
> nil (`self._FillLevelingRight and …`) : l'absence de ce fichier ne casse rien.

### `CraftingOrderClassic_ProfWindow_Route.lua`
> CraftingOrderClassic_ProfWindow_Route.lua — PLAN DE ROUTE de montée de métier (étage ③ de l'aide
> à la progression) : « du rang actuel au plafond, quoi crafter, combien de fois, pour combien ».
> Marche gloutonne rang par rang : à chaque rang, la recette au meilleur coût/point ESPÉRÉ parmi
> les candidates (apprises + manquantes ACHETABLES — formateur/vendeur prix MTSL, sinon objet-plan
> coté à l'HV) ; la couleur à un rang FUTUR vient des seuils réels CraftLink `skillColors`
> (lib v11, source Wowhead). Le prix d'un plan à acheter est AMORTI sur les points qu'il peut
> encore servir (comparaison équitable avec les recettes déjà connues) puis compté UNE fois.
> Exclues : recettes à cooldown (1/jour ≠ route) et recettes au coût partiel (réactif sans prix —
> un coût sous-estimé détournerait toute la route). Les rangs sans candidate = segment « ? ».
> Tout est soft-dep : sans Lazy Gold, le bouton ouvre la popup NeedLazyGold ; sans ce fichier,
> rien ne change (hooks sous garde nil dans _ProfWindow_Toolbar).

**API** : `PW:ToggleRoute()`

### `CraftingOrderClassic_ProfWindow_Detail.lua`
> CraftingOrderClassic_ProfWindow_Detail.lua — colonne CENTRE : détail de la recette sélectionnée
> (icône, réactifs have/need) + boutons Créer / Créer tout. Craft via COC.Craft:Do (DoTradeSkill /
> DoCraft). Port de TradeScanner_ProfWindow_Detail.lua adapté à COC.

**API** : `PW:RefreshDetail()`

### `CraftingOrderClassic_ProfWindow_Info.lua`
> CraftingOrderClassic_ProfWindow_Info.lua — PANNEAU D'INFO en SECTIONS pour la colonne centrale de la
> vue métier. Affiché à la place des réactifs quand la recette sélectionnée n'est pas apprise (mode
> « manquantes »). Conçu comme un CADRE EXTENSIBLE : chaque bloc d'info est une SECTION fournie par une
> fonction enregistrée, pour brancher facilement d'autres addons plus tard (une idée = une section).
> 
> ENREGISTRER UNE SECTION :
>   COC.ProfWindow:RegisterInfoSection(function(ctx)
>       -- ctx = { profKey = <clé métier>, entry = <recette sélectionnée> }
>       -- retourne { title = <libellé>, lines = { { label = , value = }, ... } }  ou nil pour rien afficher
>   end)
> Les sections sont rendues dans l'ordre d'enregistrement ; celles qui renvoient nil sont sautées.
> `label` peut être "" (ligne de continuation, ex. PNJ supplémentaires sous « Vendu par »).

**API** : `PW:RegisterInfoSection(fn)`

### `CraftingOrderClassic_LazyGold.lua`
> CraftingOrderClassic_LazyGold.lua — pont LECTURE SEULE vers l'addon « Lazy Gold Classic » (LG).
> 
> BUT : afficher la RENTABILITÉ d'une recette dans la vue métier — prix de vente à l'HV, coût des
> réactifs, profit net — en réutilisant les prix que Lazy Gold calcule (via Auctionator + prix
> vendeur). On ne réimplémente PAS la collecte de prix : on lit sa primitive publique.
> 
> DÉPENDANCE MOLLE : COC reste autonome. Si Lazy Gold (ou Auctionator) n'est pas là, IsAvailable()
> est faux et la section « Rentabilité » ne s'affiche pas — aucun plantage. On lit UNE fonction
> publique (LazyGold:GetItemCost), jamais l'UI ni les tables internes de LG.
> 
> PRIMITIVE LUE :
>   LazyGold:GetItemCost(itemID) -> cuivre (prix vendeur, sinon prix HV Auctionator), ou nil si inconnu.
> 
> Le COÛT des réactifs et l'objet produit viennent de NOS données CraftLink (RecipeReagents/RecipeProduct),
> pas des tables de LG : on reste maître de la recette, LG ne sert QUE d'oracle de prix.

**API** : `LG:IsAvailable()` · `LG:ItemValue(itemID)` · `LG:CoinTier(copper)` · `LG:ProfitTier(copper)` · `LG:ExactMode()` · `LG:SetExactMode(on)` · `LG:ProfitText(copper)` · `LG:Money(copper, colored)` · `LG:CraftProfit(profKey, spellID, numMade)` · `LG:EntryProfit(profKey, entry)` · `LG:CraftCost(profKey, spellID)` · `LG:EntryCost(profKey, entry)` · `LG:BestPlanFor(profKey, rank)` · `LG:BestProfitFor(profKey, rank)` · `LG:PlanName(profKey, plan)` · `LG:BestPlanName(profKey, rank)` · `LG:BestKnownPlanFor(profKey, r)` · `LG:MinProfit()` · `LG:HighlightTier(profit)`

### `CraftingOrderClassic_ProfWindow_Orders.lua`
> CraftingOrderClassic_ProfWindow_Orders.lua — colonne « Commandes » de la vue métier (cabine de
> l'artisan) : construction (onglets de relation, en-tête, scroll), vue LISTE (une ligne par
> commande : demandeur + prix + âge ; une ligne sourdine cliquée se réaffiche), collecte/tri et
> rafraîchissement. La vue SÉLECTIONNÉE (carte complète : composants, Lazy Gold, ACCEPTER/REFUSER/
> CHUCHOTER) vit dans _ProfWindow_Orders_Card.lua (anti-monolithe). Onglets de relation (Tous /
> Guilde / Amis / Annuaire) au header. Inclut les demandes captées (/commerce, /guilde).

**API** : `PW:RefreshOrders()`

### `CraftingOrderClassic_ProfWindow_Orders_Card.lua`
> CraftingOrderClassic_ProfWindow_Orders_Card.lua — vue SÉLECTIONNÉE de la colonne « Commandes » :
> la carte complète d'une commande (composants fournis, repères Lazy Gold, ACCEPTER / REFUSER /
> CHUCHOTER ; croix en haut à droite = retour liste). Sorti de _ProfWindow_Orders.lua
> (anti-monolithe) — la LISTE, la collecte et les helpers partagés (_OrderReagents, _OrderItemName,
> _OrdRelation, PW.ORD_REL_COL, PW.ORD_CARD_W) restent là-bas.

### `CraftingOrderClassic_ProfWindow_LFW.lua`
> CraftingOrderClassic_ProfWindow_LFW.lua — config de l'OFFRE « recherche de travail » par métier.
> Engrenage à droite du bouton « Chercher du travail » (en-tête fenêtre métier) → panneau flyout :
> compos de base, restriction « si progression », commission fixe (or/argent/cuivre), et picker
> cherchable des composants fournis (univers = UNION des réactifs des recettes CraftLink du métier,
> filtré par version client via Skin.ItemExists). Save-on-change → Dir:SetLFWOffer (persiste +
> re-diffusion LFO débouncée). Éditable même LFW éteint : la config part au prochain SetLFW.

**API** : `PW:ToggleLFWConfig()`

### `CraftingOrderClassic_ProfWindow_Reroll.lua`
> CraftingOrderClassic_ProfWindow_Reroll.lua — vue métier LECTURE SEULE d'un REROLL.
> 
> Ouvre la ProfWindow pour un métier d'un AUTRE perso du compte (hors ligne) : recettes connues +
> commandes du métier, SANS bouton créer (on n'est pas sur ce perso). 100 % local : recettes lues
> depuis le cache db.knownRecipes[rerollKey][prof] (feature rerolls v1.9.0), pas depuis la fenêtre
> native. Réactifs depuis le catalogue CraftLink (quantités « à fournir », pas de have/need des sacs).
> Renoncements assumés (indispo hors fenêtre native) : couleur par difficulté, nb craftable, have/need.
> Greffe des méthodes sur COC.ProfWindow (créée par ProfWindow.lua, chargé AVANT).

**API** : `PW:OpenForReroll(prof, rerollKey, name)` · `PW:RerollKnows(o)`

### `Directory.lua`
> Crafting Order - Classic — Directory : l'annuaire des GENS (présence + qui peut crafter quoi).
> Côté PRODUIT (pas dans la lib), séparé du registre de recettes (CraftLink). Présence via JOIN/LEAVE
> du canal caché (Dir.online) ; recettes via RK sur le canal global (Dir.roster, persistant) ; PING/PONG
> YELL en proximité. Discipline cache : réseau → Dir.roster (COC.db.roster) → UI (jamais le réseau direct).

**API** : `Dir:OnPresence(kind, who)` · `Dir:ScanRelations()` · `Dir:ClassifySource(name)` · `Dir:ReclassifyAll()` · `Dir:PruneRoster(maxAgeDays, maxRecent)` · `Dir:OnRK(sender, message)` · `Dir:OnHello(sender, message, distribution)` · `Dir:OnPing(sender, _, distribution)` · `Dir:OnPong(sender)` · `Dir:Announce()` · `Dir:AnnounceTo(target)` · `Dir:DiscoverPlayer(name)` · `Dir:OnBeacon(who)` · `Dir:AnnounceThrottled()` · `Dir:Refresh()` · `Dir:RediscoverKnown(includeRecent)` · `Dir:CountOnline()` · `Dir:CountKnownCrafters()` · `Dir:WhoCanCraft(prof, spellID)` · `Dir:Start()`

### `Directory_Presence.lua`
> Directory_Presence.lua — présence : la vérité JEU (amis/guilde) et sa fusion avec la vérité ADDON.
> 
> Deux sources, à ne JAMAIS confondre :
>   * Dir.online     — il RÉPOND en CraftLink (JOIN/LEAVE du canal, ou tout message reçu → _Touch).
>                      C'est la seule qui autorise une commande : ses données sont fraîches.
>   * Dir.onlineGame — le JEU le dit connecté (roster de guilde / liste d'amis / BNet), addon ou pas.
>                      Ne vaut que pour mes RELATIONS : le jeu ne dit rien d'un simple croisé.
> Sans la seconde, un guildmate connecté SANS l'addon s'affichait « Hors ligne » — faux, et ça
> ressemblait à une panne réseau. Dir:PresenceOf les fusionne en 3 états pour l'UI.
> 
> Satellite de Directory.lua (anti-monolithe) : y vivent le sweep des relations en ligne
> (DiscoverFriendsAndGuild) et la requête d'affichage. Chargé APRÈS Directory.lua (.toc).

**API** : `Dir:ForEachBNetWoWFriend(fn)` · `Dir:DiscoverFriendsAndGuild()` · `Dir:PresenceOf(name)`

### `Directory_Confed.lua`
> Directory_Confed.lua — source « confédération » (GreenWall) de l'annuaire, DISPLAY-ONLY.
> 
> Extrait de Directory.lua (anti-monolithe) : ajoute des méthodes sur la table partagée COC.Directory
> (créée par Directory.lua, chargé AVANT dans le .toc). Voir [[coc-confederation-display]].

### `Directory_Skills.lua`
> Directory_Skills.lua — niveaux de compétence + réputation (couche « profil » de l'annuaire).
> 
> Extrait de Directory.lua (anti-monolithe) : capture MES niveaux de métier (API skill, lisibles sans
> ouvrir la fenêtre), les diffuse (verbe SK, avec la réputation = crafts livrés en pseudo-chunk final),
> et reçoit ceux des autres → Dir.roster[name].skill/.level/.rep. Les méthodes restent sur la table
> COC.Directory (créée par Directory.lua, chargé AVANT) → self:_Touch etc. résolus sur la table partagée.

**API** : `Dir:CaptureSkills()` · `Dir:AnnounceSkills()` · `Dir:OnSkill(sender, message)`

### `Directory_Cooldowns.lua`
> Directory_Cooldowns.lua — cooldowns de recettes (couche « profil » de l'annuaire).
> 
> Réception du verbe CD (cooldowns d'un autre porteur) → Dir.roster[name].cooldowns[prof] =
> { [spellID] = readyAt epoch } + cdStamp[prof] (fraîcheur de l'info) ; émission des MIENS
> (CraftLink.myCooldowns) dans le sillage des annonces SK/RK. Le fil transporte du RELATIF
> (secondes restantes, cf. CraftLink_Cooldowns) ; le roster stocke de l'ABSOLU (survit aux
> relogs, l'UI recalcule le restant à l'affichage). Les méthodes restent sur COC.Directory
> (créée par Directory.lua, chargé AVANT) → self:_Touch etc. résolus sur la table partagée.

**API** : `Dir:OnCD(sender, message)` · `Dir:AnnounceCooldowns(scope, target)` · `Dir:PruneCooldowns()` · `Dir:StartCooldowns()`

### `Directory_RelayCodec.lua`
> Directory_RelayCodec.lua — codec du fil RLY : relais de la fiche d'un artisan HORS LIGNE par
> un de ses partenaires. PUR (aucune API WoW, aucun LibStub) : testable headless
> (tests/test_relay_codec.lua), même discipline que Orders_Codec.lua.
> 
> Enveloppe : "RLY|<origin>|<age>|<payload interne SK/RK/CD>". `age` = secondes écoulées depuis
> le dernier contact DIRECT relayeur↔origin (qualifie la fraîcheur du SK/RK ; le CD, lui, est
> RECALCULÉ au moment du relais → son restant est courant). AUCUNE règle d'acceptation ici :
> whisper-only, origin≠sender, caps et rate-limit vivent dans Directory_Relay.OnRelay.

**API** : `RelayCodec.Wrap(origin, age, inner)` · `RelayCodec.Parse(message)` · `RelayCodec.BuildSK(entry)` · `RelayCodec.BuildRK(prof, hex, dv)` · `RelayCodec.BuildCD(prof, cds, now)`

### `Directory_Relay.lua`
> Directory_Relay.lua — « contacts de confiance » : les données d'un joueur DÉCONNECTÉ restent
> servies par ses partenaires (r.isPartner). Émission = riposte de découverte (OnHello/OnPing
> whisper → RelayPartnersTo) ; réception = OnRelay → stockage EXCLUSIF dans roster[origin].relayed
> (estimation, JAMAIS autoritaire : pas d'écriture dans skill/recipes/cooldowns/lastSeen/online,
> pas de routage d'ordre — display-only). Le direct écrase toujours : Dir:_Touch fait relayed=nil.
> L'origin d'un RLY est falsifiable → c'est POURQUOI ce grade existe (cf. plan, décision user).
> Codec pur dans Directory_RelayCodec.lua ; méthodes sur COC.Directory (chargé avant, .toc).

**API** : `Dir:RelayPartnersTo(target)` · `Dir:OnRelay(sender, message, distribution)` · `Dir:PruneRelays()` · `Dir:StartRelay()`

### `Directory_AltCodec.lua`
> Directory_AltCodec.lua — codec du fil ALT (liste des persos d'un même joueur) + vérification
> par réciprocité. PUR (aucune API WoW, aucun LibStub) : testable headless (tests/test_alt_codec.lua),
> même discipline que Directory_RelayCodec.lua.
> 
> Fil : "ALT|<main>|<nom1>,<nom2>,..." (noms courts triés, le set INCLUT le main et l'émetteur) ;
> "ALT|-|" = dissolution (opt-out). AUCUNE règle de confiance ici : le stockage sous le sender,
> le rate-cap et la garde « sender ∈ set » vivent dans Directory_Alts.OnAlt. La SÉCURITÉ du
> regroupement repose sur la réciprocité (Component) : un lien A↔B n'existe que si A a annoncé B
> ET B a annoncé A — les deux annonces sortant de la même SavedVariable de compte, un imposteur
> ne peut pas produire la moitié « victime » de la paire.

**API** : `AltCodec.Encode(main, names)` · `AltCodec.Decode(message)` · `AltCodec.Component(claims, start, cap)`

### `Directory_Alts.lua`
> Directory_Alts.lua — regroupement des rerolls : identité « joueur » multi-persos (verbe ALT).
> 
> OPT-IN (/co alts on, désactivé par défaut) : le joueur choisit un perso PRINCIPAL et annonce la
> liste de ses persos au réseau (dans le sillage de Announce/AnnounceTo — aucun nouveau déclencheur).
> Réception → roster[sender].altClaim (1 déclaration par perso, sous le SENDER transport, donc
> infalsifiable). Un lien A↔B n'est VÉRIFIÉ que par réciprocité (AltCodec.Component) : les deux
> annonces sortent de la même SavedVariable de compte — un imposteur ne peut pas faire mentir sa
> victime, donc jamais de routage/fusion sur claim unilatérale. Mes PROPRES persos (IsMyChar) se
> lisent localement dans MA SV : aucune confiance réseau côté réception.
> Codec pur dans Directory_AltCodec.lua ; méthodes sur COC.Directory (chargé avant, .toc).

**API** : `COC:StampMyChar()` · `COC:IsMyChar(short)` · `Dir:AnnounceAlts(scope, target)` · `Dir:OnAlt(sender, message)` · `Dir:PlayerChars(name)` · `Dir:SamePlayer(a, b)` · `Dir:OnlineCharOf(name)` · `Dir:GroupLeader(name)` · `Dir:PruneAlts()` · `Dir:AltsCmd(rest)` · `Dir:StartAlts()`

### `Directory_LFW.lua`
> Directory_LFW.lua — statut « recherche de travail » (Looking For Work) + OFFRE par métier.
> 
> Un artisan se déclare dispo pour UN métier → diffusé au ROYAUME via le canal-texte (verbe LFW, réutilise
> l'infra canal v1.11.0, cf. balise/texte canal CraftLink). Les autres stockent { prof, expiry } EN RUNTIME
> (statut transitoire, non persisté) et l'affichent (nameplate + annuaire, couches à part). SÛR par
> construction : le stockage est clé par SENDER (émetteur réel, non falsifiable par le transport) → on ne
> peut déclarer QUE soi-même LFW. MON propre choix (COC.db.lfw.prof) PERSISTE et se ré-affirme au login +
> périodiquement (le récepteur applique un TTL, donc sans ré-émission je disparais de son radar).
> 
> OFFRE (v1.18) : détails par MÉTIER attachés au LFW — « je fournis les compos de base », liste de
> composants fournis, commission fixe par craft, restriction « seulement si le plan me fait progresser ».
> Config persistée dans COC.db.lfwOffer[profKey] (éditable même LFW éteint), diffusée par un verbe SÉPARÉ
> `LFO|<prof>|<flags>|<feeCopper>|<id1,id2,…>` : étendre LFW|on casserait les vieux clients (leur pattern
> avalerait les champs dans la clé métier), alors qu'un verbe inconnu est ignoré proprement par _Dispatch.
> Wire 100 % neutre en langue (IDs, cuivre, lettres). Un LFO seul VAUT LFW-on (robuste à la perte d'une
> ligne) ; l'offre reçue vit sur l'entrée Dir.lfw[sender].offer et meurt avec elle (même TTL).

**API** : `Dir:LFWOf(name)` · `Dir:OnLFW(sender, message)` · `Dir:OnLFO(sender, message)` · `Dir:OnLFR(sender, message)` · `Dir:NoteChatLFW(name, prof)` · `Dir:MyLFW()` · `Dir:MyLFWOffer(profKey)` · `Dir:SetLFWOffer(profKey, offer)` · `Dir:LFWOfferLines(name)` · `Dir:SetLFW(profKey)` · `Dir:LFWCmd(arg)` · `Dir:StartLFW()`

### `CraftingOrderClassic_LFWChat.lua`
> CraftingOrderClassic_LFWChat.lua — détection « recherche de travail » dans le CHAT VISIBLE.
> 
> Écoute Trade/Général/say/yell : un message « LFW <métier> » enregistre son AUTEUR comme cherchant du
> travail dans l'annuaire — même s'il N'A PAS l'addon (prospect display-only). Mon propre message = simple
> raccourci de /co lfw <métier>. L'auteur d'un message de chat est authentifié par le jeu → aucune
> usurpation possible (contrairement à un payload réseau, ici le nom = celui qui a réellement parlé).
> Verbe protocole (`LFW|on|prof`) exclu par construction : on ignore toute ligne contenant « | ».
> Toggle `COC.db.lfwChatScan` (défaut ON) via /co lfwchat ; throttlé par auteur ; respecte les mutes.

**API** : `LC:Start()` · `LC:Cmd(arg)`

### `Directory_MyArtisans.lua`
> Directory_MyArtisans.lua — agrégation des métiers du COMPTE (onglet « Mes artisans »).
> 
> Feature 100 % LOCALE : lit MES SavedVariables partitionnées par perso (db.myChars,
> db.knownRecipes, db.mySkillsByChar) et produit une vue « métiers du compte » — tous mes rerolls
> du royaume confondus, perso principal (db.altMain) en tête, chaque métier affiché en mode
> « connu » (niveau + recettes) comme s'il n'y avait qu'un personnage. AUCUN message réseau, aucun
> verbe, aucune dépendance à l'opt-in /co alts : marche même désactivé. Le cœur `aggregate` est PUR
> (SV + royaume injectés) → testable headless (tests/test_myartisans.lua). Méthodes sur
> COC.Directory (créée par Directory.lua, chargé AVANT).

**API** : `Dir:AggregateMyProfs()` · `Dir:RerollProfEntries()` · `Dir:PruneMySkills()`

### `Directory_LootScan.lua`
> Directory_LootScan.lua — découverte PASSIVE des artisans NON-porteurs de l'addon qui craftent à
> proximité. Deux chemins :
>   1. COMBAT_LOG_EVENT_UNFILTERED / SPELL_CAST_SUCCESS (PRINCIPAL) : le journal de combat voit les
>      casts des joueurs alentour avec le spellID de la recette → identification directe (recettes
>      CraftLink indexées par spellID), indépendante de la LANGUE et du cache objets.
>   2. CHAT_MSG_TRADESKILLS « X creates Y. » (repli) : nom d'objet BRUT (TRADESKILL_LOG_THIRDPERSON,
>      SANS deux-points ni lien) → itemID seulement si l'objet est déjà en cache client.
> Plancher de skill = RecipeLearnedAt (il sait le faire → skill ≥ niveau d'apprentissage de la recette).
> OPT-IN : désactivé par défaut, activable par case à cocher (onglet Artisans) ou « /co crafters on » ;
> n'écoute le journal de combat qu'EN VILLE (IsResting) — voir bloc « Activation » en bas de fichier.
> 
> Estimation stockée À PART : r.craftSeen[prof] = plancher + r.nonAddon = true. JAMAIS dans
> r.skill/r.recipes (réservés aux vraies données réseau SK/RK, prioritaires). On pingue aussi le crafteur
> (DiscoverPlayer, throttlé) : s'il a l'addon, ses vraies données remplaceront l'estimation.
> Méthodes sur COC.Directory (créé par Directory.lua, chargé avant dans le .toc).

**API** : `Dir:NoteCraftSeen(who, item)` · `Dir:SetCrafterScan(on)` · `Dir:CrafterScanEnabled()`

### `Orders_Codec.lua`
> Orders_Codec.lua — codec du protocole filaire ORD| (sérialisation ⇄ parsing, SOURCE DE VÉRITÉ).
> 
> Centralise le format des commandes P2P, jusqu'ici éparpillé (Orders_Net:_NewPayload/Broadcast,
> Orders:Decline pour NACK, Handoff pour SUGG). Table `ENCODERS`/`DECODERS` indexée par verbe :
>   * Codec.Encode(verb, o)   -> chaine filaire "ORD|VERBE|..."  (ou nil si verbe inconnu)
>   * Codec.Decode(message)   -> table plate { verb=, id=, ... } de champs BRUTS (ou nil si non parsable)
> 
> Contrat (docs\protocol-ord.md) : le codec PARSE et SÉRIALISE, un point c'est tout. Il n'applique NI
> défaut/normalisation (kind ""->"item", recipient ""->"Tous"... restent dans Orders:_OnNew/_OnCycle),
> NI autorisation (l'anti-spoof sender==buyer reste dans Orders:_OnCycle). Les octets produits sont
> STRICTEMENT identiques au code d'origine (refactor iso-fil, pas de bump protocolVersion).
> 
> PUR : aucune dépendance à l'API WoW ni à LibStub → chargeable hors client (tests headless Elune).
> Ne référence que la table globale CraftingOrderClassic (pour publier COC.OrdersCodec).

**API** : `Codec.Encode(verb, o)` · `Codec.Decode(message)`

### `Orders.lua`
> Crafting Order - Classic — Orders : carnet d'ordres GLOBAL (modèle + cycle + protocole).
> 
> Un ordre = une demande de craft postée par un acheteur, visible/acceptable par n'importe quel
> porteur de l'addon sur le royaume (canal global), sans guilde commune. Cycle :
>   poster (NEW) → accepter (ACK) → livrer (DONE) ; annuler (CANCEL) à tout moment par l'auteur.
> 
> Discipline cache : tout passe par COC.db.orders (persistant) ; l'UI (à venir) lira CE cache.
> Protocole sur le transport CraftLink (portée "global" par défaut) : 7 verbes
>   NEW / CANCEL / ACK / DLV / DONE / NACK / SUGG, sérialisés/parsés par Orders_Codec.lua.
>   Grammaire filaire complète + règles d'autorité (anti-spoof sender==buyer) : docs\protocol-ord.md.

**API** : `Orders:ProfForItem(itemID)` · `Orders:VisibleTo(o, who)` · `Orders:Post(itemID, qty, price, opts)` · `Orders:PostEntry(entry, qty, price, opts)` · `Orders:OrderName(o)` · `Orders:Cancel(id)` · `Orders:Accept(id)` · `Orders:Deliver(id)` · `Orders:Confirm(id, auto)` · `Orders:TryAutoComplete(itemID, source)` · `Orders:AlertDelivered(o)` · `Orders:Decline(o)` · `Orders:ProfRowAction(o)` · `Orders:AlertTargeted(o, tries)` · `Orders:RebroadcastMine()` · `Orders:OnHello()` · `Orders:All()` · `Orders:PruneExpired()` · `Orders:OnArtisanOnline(who)` · `Orders:PrintList()` · `Orders:PostFromInput(rest)` · `Orders:Ping()` · `Orders:OnPing(sender)` · `Orders:Start()`

### `Orders_Net.lua`
> Orders_Net.lua — couche « fil réseau » du carnet d'ordres (protocole ORD|).
> 
> Extrait de Orders.lua (anti-monolithe) : ENCODAGE (Broadcast / _NewPayload + fanout par portée) et
> DÉCODAGE (OnNetwork : NEW/CANCEL/ACK/DONE/NACK/SUGG → cache COC.db.orders). Les méthodes restent sur
> la table COC.Orders (créée par Orders.lua, chargé AVANT) → appelées via self: depuis les deux fichiers.
> Le cycle local (Post/Accept/Deliver/Cancel/Decline), l'alerting et les helpers restent dans Orders.lua.

**API** : `Orders:Broadcast(action, o, opts)` · `Orders:OnNetwork(sender, message, distribution)`

### `CraftingOrderClassic_Inbound.lua`
> CraftingOrderClassic_Inbound.lua — couche réseau « passive » : capte les demandes de craft
> postées dans /commerce (Trade) et /guilde par des joueurs SANS l'addon, alerte le joueur, et
> les range dans une file « Entrantes » (acceptable / ignorable). Calqué sur le scanner de Guild
> Economy (TradeScanner). Ces commandes portent viaAddon=false ; l'acceptation ne prévient plus
> automatiquement le demandeur (WhisperPub retiré, v1.2.0) — à faire manuellement dans le chat.

**API** : `Inbound:OnChat(msg, player, source)` · `Inbound:Add(e)` · `Inbound:Alert(e)` · `Inbound:All()` · `Inbound:Count()` · `Inbound:Accept(id)` · `Inbound:Dismiss(id)` · `Inbound:Start()`

### `CraftingOrderClassic_Handoff.lua`
> CraftingOrderClassic_Handoff.lua — « garder une commande pour un ami capable ».
> 
> Le CERVEAU qui manquait : croiser une commande avec les métiers des artisans CONNUS (amis /
> guilde / ajoutés), la conserver, et la leur passer à leur connexion — sans dépendre du canal
> caché (tout en whisper, fiable). Trois usages :
>   * Palier 1 — commandes RÉSEAU : quand un ami connu se connecte, en plus du relais par portée
>     (Orders:OnArtisanOnline), on lui envoie un nudge « ORD|SUGG|id » pour MES commandes ouvertes
>     qu'il sait crafter → alerte « tu sais le faire » chez lui (dédup runtime).
>   * Palier 2 — ENTRANTES (/commerce, /guilde de joueurs sans l'addon) : si un ami connu sait la
>     faire, on me le signale et on la lui pousse comme ordre de synthèse « CAP-… » (recipient=Tous,
>     marqué captured=1 → chez lui viaAddon=false pour que l'acceptation prévienne le demandeur).
>   * Palier 3 — lecture pour l'UI : Pending() liste les commandes confiées (item · artisan · état).
> 
> Capacité = précise (bitfield RK si même dataVersion) OU grossière (connaît le métier via SK/RK).
> Le RÉCEPTEUR revérifie sa VRAIE capacité (ICanCraft) avant d'alerter → pas de fausse alerte.

**API** : `Handoff:CanCraft(who, o)` · `Handoff:ICanCraft(o)` · `Handoff:CapableKnownList(o)` · `Handoff:Suggest(o, who)` · `Handoff:ForwardInboundTo(who)` · `Handoff:OnArtisanOnline(who)` · `Handoff:NoteInbound(e)` · `Handoff:AlertCapable(o, tries)` · `Handoff:MyRerollCanCraft(o)` · `Handoff:AlertReroll(o, alt, tries)` · `Handoff:Pending()`

### `CraftingOrderClassic_Moderation.lua`
> CraftingOrderClassic_Moderation.lua — modération / anti-spam.
> 
> Alimente COC.db.mutedPlayers (lu par Orders:_ShouldAlert et Inbound:Alert : un joueur muté ne
> déclenche AUCUNE notif — toast/chat/son — ni sur le réseau P2P ni sur la capture chat). Leviers :
>   * MUTE MANUEL : /co mute|unmute <nom>, shift-clic-droit sur une carte, menu contextuel joueur.
>     Un mute porte une RAISON (texte libre) + un HORODATAGE, et peut être TEMPORAIRE (/co mute <nom>
>     1h raison → levé tout seul à l'expiration). Cf. la forme d'entrée ci-dessous.
>   * MUTE AUTO BAS NIVEAU : COC.db.muteBelowLevel (défaut 5) — ignore les posts d'un perso dont le
>     niveau CONNU (via l'annuaire, verbe SK) est sous le seuil (anti bots/mules). Niveau inconnu = pas de mute.
>   * DÉTECTION DE SPAM : compte les posts par auteur sur une fenêtre glissante ; au seuil, mute
>     directement (mode auto) ou propose un popup (défaut). Seuils RÉGLABLES et persistés via
>     /co spam (max, fenêtre, auto). Suivi RUNTIME (compteurs/popups) non persisté : reset par session.
>   * LISTE DE CONFIANCE : /co trust <nom> exempte un joueur des mutes AUTO (bas niveau + spam). Le mute
>     MANUEL reste possible (une décision explicite prime). COC.db.trusted = { [nom] = true }.
> 
> Forme d'une entrée COC.db.mutedPlayers[nom] (rétrocompatible) :
>   * `true`  = mute PERMANENT hérité (clients < v1.13) — toujours honoré.
>   * table   = { reason = texte|nil, ts = époque de pose, expiry = époque de levée|nil (nil=permanent) }.
> IsMuted absorbe les deux formes et lève paresseusement un mute temporaire expiré → pas de migration.

**API** : `Mod:IsMuted(name)` · `Mod:Mute(name, reason, durationSec)` · `Mod:Unmute(name)` · `Mod:PrintMuted()` · `Mod:MutedList()` · `Mod:MuteCmd(arg)` · `Mod:UnmuteCmd(arg)` · `Mod:IsTrusted(name)` · `Mod:Trust(name)` · `Mod:Untrust(name)` · `Mod:PrintTrusted()` · `Mod:TrustCmd(arg)` · `Mod:UntrustCmd(arg)` · `Mod:BelowThreshold(name)` · `Mod:LowLevelCmd(arg)` · `Mod:NotePost(name)` · `Mod:SpamCmd(arg)`

### `CraftingOrderClassic_LootAlert.lua`
> CraftingOrderClassic_LootAlert.lua — alerte quand TU loots un objet-PLAN (recette/formule/
> schéma/patron) catalogué par CraftLink, MAIS seulement s'il te CONCERNE : soit tu as le métier
> (candidat à l'apprendre), soit un AMI/PARTENAIRE de ton annuaire ne le connaît pas encore
> (candidat à un don — cf. request/FEATURE_friend.md). Sinon : silence — un Joaillier/Mineur qui
> loote un patron de Couture sans ami couturier intéressé n'est PAS notifié. Débloqué par les
> métadonnées `taughtBy` (P4, CraftLink v6) : sans elles, RecipeFromPlanItem ne résout aucun plan.

**API** : `Loot:IsEnabled()` · `Loot:Cmd(arg)` · `Loot:GiftCmd(arg)`

### `CraftingOrderClassic_Companion.lua`
> CraftingOrderClassic_Companion.lua — socle des GREFFONS : panneaux compagnons accrochés aux
> fenêtres natives (échange, courrier) pour livrer une commande sans quitter le geste en cours.
> Réf. design : Documentation/greffon_integration (« Crafting Order Hooks », scènes A/B).
> Règles : on AJOUTE un panneau à côté de la frame Blizzard (jamais de Hide/neutralisation) ;
> l'UI lit UNIQUEMENT le cache COC.db.orders (réseau → cache → UI) ; le panneau ne s'affiche
> que s'il y a au moins une commande à livrer au partenaire courant (zéro bruit sinon).

**API** : `Comp.PriceToCopper(price)` · `Comp.PriceLabel(o)` · `Comp.RoleWith(o, partner)` · `Comp:OrdersFor(partner)` · `Comp:OrdersWith(partner)` · `Comp:MyDeliverables()` · `Comp.MakePanel(name, parent, width, maxRows)` · `Comp.FillRows(panel, orders)` · `Comp.OnCacheRefresh(fn)`

### `CraftingOrderClassic_Companion_Mail.lua`
> CraftingOrderClassic_Companion_Mail.lua — greffon COURRIER (scène B de la maquette) : panneau
> accroché à droite du compositeur d'envoi. Liste MES commandes à livrer ; « Remplir depuis commande »
> renseigne le destinataire (« À: ») + objet / corps / contre-remboursement, puis marque « remise »
> (Orders:Deliver) quand l'envoi ABOUTIT (MAIL_SEND_SUCCESS + destinataire vérifié) — jamais d'auto-envoi.
> Si un destinataire est déjà saisi, on filtre sur ses commandes ; sinon on affiche TOUTES mes livraisons.
> Côté acheteur, la réception (pièce jointe prise) est couverte par le détecteur CHAT_MSG_LOOT existant.

**API** : `Mail.Update()`

### `CraftingOrderClassic_Companion_Trade.lua`
> CraftingOrderClassic_Companion_Trade.lua — greffon ÉCHANGE (scène A de la maquette) : panneau
> accroché SOUS la fenêtre d'échange native quand une commande nous lie au partenaire (dans les DEUX
> sens : je crafte pour lui = « vendeur », ou il crafte pour moi = « acheteur »).
> ⚠️ L'or de l'échange (TradePlayerInputMoneyFrame) est :SetForbidden() par Blizzard : ni lisible ni
> écrivable par un addon → le montant est AFFICHÉ (« À réclamer » / « À payer »), jamais pré-rempli.
> PERSISTANCE : le panneau reste affiché APRÈS la fermeture de l'échange (re-parenté à l'écran) tant
> qu'il reste des commandes actives, pour que chacun finalise sur place — vendeur « Marquer livrée »,
> acheteur « J'ai reçu » (Orders:Confirm) — sans passer par le Carnet. Fermeture manuelle par la croix.

**API** : `Trade.Update()`

### `CraftingOrderClassic_Enchant_Trade.lua`
> CraftingOrderClassic_Enchant_Trade.lua — greffon ENCHANTEMENT sur la fenêtre d'ÉCHANGE.
> Quand le partenaire pose un objet dans l'emplacement « ne sera pas échangé » (TRADE_ENCHANT_SLOT),
> on liste MES enchants applicables à CET emplacement — plus besoin de chercher dans toute la liste.
> La liste est CLASSÉE par pertinence (cf. offerRank) : ce que ses RÉACTIFS posés dans l'échange
> désignent d'abord, puis ce que mes sacs permettent, et seulement ensuite l'ordre catalogue (rang de
> métier décroissant). Le surplus se parcourt à la MOLETTE — le classement rapproche la bonne recette,
> il ne la garantit pas : rien ne doit rester hors d'atteinte.
> Chaque ligne est un bouton SÉCURISÉ qui crafte l'enchant directement :
>   PreClick → CraftFrame_SetSelection(index) : sélectionne ET ARME le bouton natif, de façon SYNCHRONE
>   (⚠️ SelectCraft ne l'arme PAS : il n'émet aucun CRAFT_UPDATE — cf. _ProfWindow_Detail) ;
>   puis le clic sécurisé est redirigé vers CraftCreateButton → DoCraft de CET enchant.
> L'enchant se pose alors sur le curseur : le joueur clique l'objet dans l'échange (l'appliquer nous-mêmes
> n'est pas possible — l'API de ciblage sécurisée ne couvre que sacs/équipement, pas la fenêtre d'échange).
> CONTRAINTE : l'API Craft ne répond que si la fenêtre d'Enchantement est OUVERTE → sinon on l'indique.
> On AJOUTE un panneau à côté du natif (jamais de Hide/neutralisation), à DROITE pour ne pas heurter le
> greffon Commandes (_Companion_Trade) qui vit SOUS la fenêtre d'échange.

**API** : `ET.Update()` · `ET:Start()`

### `CraftingOrderClassic_Enchant_Trade_Ask.lua`
> CraftingOrderClassic_Enchant_Trade_Ask.lua — greffon ÉCHANGE : « demande-lui la pièce ».
> L'ÉTAT VIDE de _Enchant_Trade : tant que le partenaire n'a rien posé dans l'emplacement « ne sera pas
> échangé », l'enchanteur ne voyait RIEN (panel:Hide()) — or c'est précisément le moment où le client
> débutant ignore que cet emplacement existe. On y met la silhouette : clic sur un emplacement → on lui
> chuchote de poser CETTE pièce-là. C'est un bouton « explique l'emplacement d'enchant au débutant »,
> pas de l'automatisation.
> 
> CHUCHOTEMENT, jamais /s : le destinataire est en face et il est le SEUL concerné — écrire en public
> spammerait tout le district des enchanteurs à chaque clic, à rebours de la discipline anti-spam de COC
> (_Moderation, /co mutes). ⚠️ Le message part dans NOTRE langue : on ne peut pas connaître la locale du
> partenaire. Inévitable pour tout message inter-joueurs — ne pas « corriger ».
> 
> La silhouette (disposition + dérivation catalogue + désaturation des emplacements morts) est celle de
> l'onglet Commande, réutilisée via COC.UI.DOLL — zéro clé de locale pour le chrome d'emplacement, et un
> seul endroit à corriger quand une couche saisonnière bouge les emplacements enchantables.
> 
> ÉTAGE 2 (NON livré, délibérément) : si le partenaire porte COC, remplacer le chuchotement par une
> invite chez lui + pose en un clic (PickupInventoryItem puis ClickTradeButton(TRADE_ENCHANT_SLOT)).
> Contraintes à tenir le jour où on le fera : verrouiller en DUR sur l'emplacement 7 (viser 1..6 en
> ferait un vecteur de VOL — le 7 est « ne sera pas échangé », donc rien n'y est volable), et EXIGER un
> clic sur l'invite (déplacer l'arme équipée de quelqu'un sans son accord serait hostile). Ça demande un
> verbe réseau + TRANSPORT_REV, donc un test 2 comptes — impossible aujourd'hui (cf. mémoire
> coc-ptr-account-testing).
> Pas d'étape de déséquipement à prévoir : une pièce PORTÉE se glisse directement dans l'emplacement 7
> (retour user 2026-07-17), et `PickupInventoryItem` fait ce déséquipement implicitement. ⚠️ À ne pas
> confondre avec « Enchanter équipé » (_ProfWindow_Detail), qui passe par l'attribut sécurisé
> `target-slot` : là, l'objet ne bouge JAMAIS — mais c'est MON objet, pas celui d'en face.
> ⚠️ Conséquence à assumer : l'objet quitte réellement le personnage du partenaire pendant l'échange
> (il est sans arme le temps de l'enchant). Normal — c'est déjà le flux manuel — mais ça reste une
> raison de plus d'EXIGER son clic : l'addon ne déséquipe personne tout seul.

**API** : `Ask:Request(label)` · `Ask:Refresh()` · `Ask:Hide()` · `Ask:Update()`

### `Debug.lua`
> Crafting Order - Classic — Debug : mode solo pour "jouer" un réseau fictif.
> 
> Sans 2e client, on ne peut pas voir d'artisans ni d'ordres venant des autres. Ce module injecte
> un faux roster (artisans avec métiers + niveaux de skill + recettes connues réelles encodées) et
> de fausses commandes, dans le MÊME cache que le réseau (Directory.roster / online, COC.db.orders),
> pour tester visuellement les onglets Carnet / Commande / Récolte / Artisans en solo.
> 
> Tout est marqué `fake=true` → `/co debug` (toggle) purge proprement les faux sans toucher au réel.

**API** : `Debug:Enable()` · `Debug:Disable()` · `Debug:Toggle()` · `Debug:Reapply()`

### `CraftingOrderClassic_SelfTest.lua`
> CraftingOrderClassic_SelfTest.lua — suite de tests IN-GAME (/cotest). QA/dev.
> 
> Couvre la LOGIQUE risquée touchée par la passe de revue de code (2026-07-04) :
>   * codec bitfield CraftLink (Encode/Decode/HasBit/CountKnown, roundtrip) ;
>   * cache ProfessionCatalogue (identité de table = mémoïsation active) ;
>   * helpers d'annuaire partagés + divergence craftSeen (KnowsProf vs KnowsProfOrSeen, InSource) ;
>   * durcissement du protocole ORD (validation de l'émetteur : CANCEL/DONE ⇐ acheteur, ACK ⇐ émetteur) ;
>   * rétention du cache d'ordres (PruneExpired : ouverte d'autrui expirée / terminée > 7 j / muted orphelin).
> 
> SÛR sur un perso LIVE : command-gated (zéro coût au load) et les tests d'état SNAPSHOT+RESTAURENT
> COC.db.orders/muted/delivered (restauration inconditionnelle après pcall). Ne fait AUCUN envoi réseau.
> La virtualisation de la liste de plans se vérifie à l'œil (rappel imprimé en fin de suite).
> 
> DEV-ONLY : tout le corps est encadré par les marqueurs --@debug@ / --@end-debug@ que le packager
> CurseForge RETIRE du build public (le zip livré n'a donc pas /cotest). En local, deploy.ps1 ne les
> retire PAS → la commande reste disponible pour la QA. Le fichier reste listé dans les .toc (parité).

**API** : `T:Run()`
