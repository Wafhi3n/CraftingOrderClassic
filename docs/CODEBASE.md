# CraftingOrderClassic — carte du code

> **GÉNÉRÉ** le 2026-07-12 (v1.16.0) par `scripts\gen_docs.ps1` — ne pas éditer à la main :
> relancer le script (deploy.ps1 le fait) après un changement de structure. Source de chaque
> rubrique : le `.toc` (ordre de chargement) et les commentaires d'en-tête des fichiers eux-mêmes.

71 modules + 4 entrée(s) Libs (CraftLink embarquée, documentée dans son repo).

## Modules (ordre de chargement)

| Fichier | Rôle | Lignes |
|---|---|---|
| `CraftingOrderClassic.lua` | Crafting Order - Classic — réseau GLOBAL et SOCIAL de commandes de craft. | 382 |
| `CraftingOrderClassic_Trace.lua` | trace réseau PERSISTÉE, lisible hors-jeu. | 79 |
| `CraftingOrderClassic_Migrations.lua` | versionnage du schéma SavedVariables. | 40 |
| `CraftingOrderClassic_Locale.lua` | socle de localisation du CHROME de l'UI. | 12 |
| `CraftingOrderClassic_Locale_enUS.lua` | overlay ANGLAIS (enUS/enGB). | 466 |
| `CraftingOrderClassic_Locale_deDE.lua` | overlay ALLEMAND (deDE). | 434 |
| `CraftingOrderClassic_Locale_esES.lua` | overlay ESPAGNOL (esES/esMX). | 435 |
| `CraftingOrderClassic_Locale_News_enUS.lua` | traductions de l'onglet « Nouveautés » (enUS/enGB). | 140 |
| `CraftingOrderClassic_Locale_News_deDE.lua` | traductions de l'onglet « Nouveautés » (deDE). | 137 |
| `CraftingOrderClassic_Locale_News_esES.lua` | traductions de l'onglet « Nouveautés » (esES). | 137 |
| `CraftingOrderClassic_Elemental.lua` | pseudo-« métier » de récolte « Élémentaire ». | 61 |
| `CraftingOrderClassic_UI_Skin.lua` | tokens + helpers SÉMANTIQUES du skin (métiers, statuts, rareté, quantités, icônes natives) et petits widgets d'affichage. | 379 |
| `CraftingOrderClassic_UI_Skin_Native.lua` | kit de chrome Blizzard NATIF (le « framework » UI de COC). | 340 |
| `CraftingOrderClassic_UI.lua` | fenêtre principale (chrome Blizzard natif, kit UI_Skin_Native). | 428 |
| `CraftingOrderClassic_UI_Post.lua` | onglet « Commande » : sélection de plan (gauche) + réactifs « je fournis » / commission g-s-c / ciblage artisan (droite). | 474 |
| `CraftingOrderClassic_UI_Post_Artisans.lua` | onglet « Commande », section droite basse : boutons source, liste des artisans, ciblage (@Nom), libellé destinataire, bouton Poster. | 178 |
| `CraftingOrderClassic_UI_Post_Categories.lua` | onglet « Commande », panneau gauche : regroupe la LISTE DES PLANS en sections type fenêtre native (emplacement puis type pour les équipements, type pour les armes, catégorie pour le reste). | 165 |
| `CraftingOrderClassic_UI_Post_LazyGold.lua` | onglet « Commande » : couche Lazy Gold (lecture seule). | 128 |
| `CraftingOrderClassic_UI_Gather.lua` | onglet « Récolte » : ressources de récolte (minéraux, herbes, cuirs, poissons) + demande de quantité + prix par pile + ciblage récolteur. | 454 |
| `CraftingOrderClassic_UI_Gather_Categories.lua` | onglet « Récolte », panneau gauche : repliage des en-têtes et remplissage des lignes (en-tête de section/sous-catégorie, ou ressource). | 65 |
| `CraftingOrderClassic_UI_Artisans.lua` | onglet « Artisans » : annuaire social. | 384 |
| `CraftingOrderClassic_UI_Artisans_Groups.lua` | fusion « une ligne par JOUEUR » (rerolls). | 199 |
| `CraftingOrderClassic_UI_Artisans_Icons.lua` | onglet « Artisans » : tout ce qui est ICÔNE de métier. | 188 |
| `CraftingOrderClassic_UI_Artisans_Muted.lua` | panel « En sourdine » de l'onglet Artisans. | 82 |
| `CraftingOrderClassic_UI_MyArtisans.lua` | onglet « Mes artisans » : vue agrégée des métiers du COMPTE (tous mes rerolls du royaume), en mode « connu ». | 426 |
| `CraftingOrderClassic_UI_MyArtisans_LazyGold.lua` | onglet « Mes artisans » : couche Lazy Gold. | 134 |
| `CraftingOrderClassic_UI_Help.lua` | onglet Aide : page unique défilante qui explique les autres onglets (Carnet/Commande/Récolte/Artisans), la Vue Métier et le réseau. | 163 |
| `CraftingOrderClassic_UI_News.lua` | onglet « Nouveautés » : notes de version (changelog) affichées EN JEU, version par version, la plus récente en tête. | 185 |
| `CraftingOrderClassic_Social.lua` | couche sociale passive (socle). | 368 |
| `CraftingOrderClassic_Social_Menu.lua` | entrées « Crafting Order » du menu contextuel joueur. | 101 |
| `CraftingOrderClassic_Social_Roster.lua` | affichage des métiers sur les fenêtres NATIVES. | 130 |
| `CraftingOrderClassic_Minimap.lua` | bouton minimap (toggle du carnet). | 120 |
| `CraftingOrderClassic_Nameplate.lua` | icône « recherche de travail » (LFW) sur les plaques. | 74 |
| `CraftingOrderClassic_ProfOrders.lua` | COORDINATEUR d'événements de la fenêtre métier. | 72 |
| `CraftingOrderClassic_RecipeCats.lua` | SOUS-CATÉGORIES de recettes (moteur + registre). | 103 |
| `CraftingOrderClassic_RecipeCats_Group.lua` | REGROUPEMENT partagé : transforme une liste plate d'entrées (recettes, plans, ressources…) en liste d'AFFICHAGE à deux niveaux :      Section (COC.SectionOf)  >  Sous-catégorie (COC.RecipeCats)  >  les objets, triés  Écrit une fois ici parce que QUATRE listes en ont besoin et qu'elles n'ont pas la même structure de ligne : vue métier (recettes de l'API), onglet Commande (plans du catalogue), Mes artisans (recettes connues), onglet Récolte (ressources). | 104 |
| `CraftingOrderClassic_RecipeCats_Alchemy.lua` | sous-catégories de l'ALCHIMIE (données, éditées à la main). | 77 |
| `CraftingOrderClassic_RecipeCats_Gathering.lua` | sous-catégories des métiers de RÉCOLTE. | 175 |
| `CraftingOrderClassic_RecipeCats_Enchanting.lua` | sous-catégories de l'ENCHANTEMENT. | 52 |
| `CraftingOrderClassic_Craft.lua` | socle de lecture LIVE de la fenêtre métier (migration de la fenêtre custom depuis Guild Economy / TradeScanner_Craft.lua). | 168 |
| `CraftingOrderClassic_MTSL.lua` | pont LECTURE SEULE vers l'addon « Missing TradeSkills List » (MTSL). | 227 |
| `CraftingOrderClassic_ProfWindow.lua` | fenêtre métier custom 3 colonnes (migration depuis Guild Economy) : Recettes \| Détail+Craft \| Commandes du métier. | 488 |
| `CraftingOrderClassic_ProfWindow_Recipes.lua` | colonne GAUCHE : liste de recettes virtualisée (scroll), recherche, couleur par difficulté, sélection, badge « demandé » (nb de commandes ouvertes pour l'objet). | 376 |
| `CraftingOrderClassic_ProfWindow_Detail.lua` | colonne CENTRE : détail de la recette sélectionnée (icône, réactifs have/need) + boutons Créer / Créer tout. | 283 |
| `CraftingOrderClassic_ProfWindow_Info.lua` | PANNEAU D'INFO en SECTIONS pour la colonne centrale de la vue métier. | 132 |
| `CraftingOrderClassic_LazyGold.lua` | pont LECTURE SEULE vers l'addon « Lazy Gold Classic » (LG). | 312 |
| `CraftingOrderClassic_ProfWindow_Orders.lua` | colonne « Commandes » de la vue métier (cabine de l'artisan). | 364 |
| `CraftingOrderClassic_ProfWindow_Reroll.lua` | vue métier LECTURE SEULE d'un REROLL. | 90 |
| `Directory.lua` | Crafting Order - Classic — Directory : l'annuaire des GENS (présence + qui peut crafter quoi). | 495 |
| `Directory_Confed.lua` | source « confédération » (GreenWall) de l'annuaire, DISPLAY-ONLY. | 51 |
| `Directory_Skills.lua` | niveaux de compétence + réputation (couche « profil » de l'annuaire). | 119 |
| `Directory_Cooldowns.lua` | cooldowns de recettes (couche « profil » de l'annuaire). | 82 |
| `Directory_RelayCodec.lua` | codec du fil RLY : relais de la fiche d'un artisan HORS LIGNE par un de ses partenaires. | 63 |
| `Directory_Relay.lua` | « contacts de confiance » : les données d'un joueur DÉCONNECTÉ restent servies par ses partenaires (r.isPartner). | 150 |
| `Directory_AltCodec.lua` | codec du fil ALT (liste des persos d'un même joueur) + vérification par réciprocité. | 115 |
| `Directory_Alts.lua` | regroupement des rerolls : identité « joueur » multi-persos (verbe ALT). | 270 |
| `Directory_LFW.lua` | statut « recherche de travail » (Looking For Work). | 122 |
| `Directory_MyArtisans.lua` | agrégation des métiers du COMPTE (onglet « Mes artisans »). | 168 |
| `Directory_LootScan.lua` | découverte PASSIVE des artisans NON-porteurs de l'addon qui craftent à proximité. | 170 |
| `Orders_Codec.lua` | codec du protocole filaire ORD\| (sérialisation ⇄ parsing, SOURCE DE VÉRITÉ). | 95 |
| `Orders.lua` | Crafting Order - Classic — Orders : carnet d'ordres GLOBAL (modèle + cycle + protocole). | 476 |
| `Orders_Net.lua` | couche « fil réseau » du carnet d'ordres (protocole ORD\|). | 315 |
| `CraftingOrderClassic_Inbound.lua` | couche réseau « passive » : capte les demandes de craft postées dans /commerce (Trade) et /guilde par des joueurs SANS l'addon, alerte le joueur, et les range dans une file « Entrantes » (acceptable / ignorable). | 237 |
| `CraftingOrderClassic_Handoff.lua` | « garder une commande pour un ami capable ». | 271 |
| `CraftingOrderClassic_Moderation.lua` | modération / anti-spam. | 333 |
| `CraftingOrderClassic_LootAlert.lua` | alerte quand TU loots un objet-PLAN (recette/formule/ schéma/patron) catalogué par CraftLink, MAIS seulement s'il te CONCERNE : soit tu as le métier (candidat à l'apprendre), soit un AMI/PARTENAIRE de ton annuaire ne le connaît pas encore (candidat à un don — cf. | 155 |
| `CraftingOrderClassic_Companion.lua` | socle des GREFFONS : panneaux compagnons accrochés aux fenêtres natives (échange, courrier) pour livrer une commande sans quitter le geste en cours. | 211 |
| `CraftingOrderClassic_Companion_Mail.lua` | greffon COURRIER (scène B de la maquette) : panneau accroché à droite du compositeur d'envoi. | 177 |
| `CraftingOrderClassic_Companion_Trade.lua` | greffon ÉCHANGE (scène A de la maquette) : panneau accroché SOUS la fenêtre d'échange native quand une commande nous lie au partenaire (dans les DEUX sens : je crafte pour lui = « vendeur », ou il crafte pour moi = « acheteur »). | 114 |
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

**`Skin.MakeStatusIcon(parent, size)`**

> Pastille de présence : texture statut du jeu, avec méthode SetOnline(bool/nil). nil = masquée.

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

> Fenêtre native complète (ButtonFrameTemplate).
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
> re-`TabResize` après chaque SetText (aucun reflow). Placé à f-62 (2 px sous le sommet de l'inset
> f-60) : le corps de la languette vit dans le marbre. La fenêtre appelante réserve la bande sous les
> onglets (cf. PAD_TOP dans UI.lua). Contrat `bar` inchangé : .buttons[id], :Select(id), :SetText(id,txt).

**`Skin.MakeFlatRow(parent, w, h)`**

> Ligne plate de liste / flyout (PAS un bouton 3-tranches).
> Pour les rangées cliquables : lignes de dropdown maison, « toute la liste », rerolls, menu minimap…
> Le bouton doré n'est PAS fait pour ça (l'ancien MakeGoldButton servait aussi de ligne, faute de
> mieux). Contrat : .text (ré-ancrable), .selTex, :SetSelected(on). Surbrillance auto (HIGHLIGHT).

**`Skin.MakeArtisanRow(parent, w, h)`**

> Ligne « personne » des listes d'artisans/récolteurs (pastille + nom + source).
> Constructeur partagé Commande/Récolte (il était dupliqué dans les deux) : pastille de présence à
> gauche, nom extensible, étiquette source alignée à droite, surbrillance au survol + texture de
> sélection. Contrat : .dot (MakeStatusIcon), .name, .src (FontStrings), .selTex (:SetShown(on)).
> L'appelant garde le peuplement (grouping rerolls, filtre métier…) — ici que la GÉOMÉTRIE.

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

**API** : `COC:Scan()` · `COC:ScanSoon()` · `COC:Status()` · `COC:ChannelCmd(arg)` · `COC:NotifyCmd(arg)` · `COC:ScanCmd(arg)` · `COC:CrafterScanCmd(arg)` · `COC:ChannelNotice()` · `COC:Beacon()` · `COC:BeaconDiag()` · `COC:WipeRoster()` · `COC:GreenWallDiag()` · `COC:Help()` · `COC:Slash(msg)`

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

### `CraftingOrderClassic_Locale_deDE.lua`
> CraftingOrderClassic_Locale_deDE.lua — overlay ALLEMAND (deDE). Clé FR → texte DE.
> Chargé APRÈS CraftingOrderClassic_Locale.lua (qui crée COC.L via setmetatable). Repli sur la clé FR
> pour toute chaîne non traduite. Guillemets « » dans les valeurs → évite l'échappement Lua des ".
> Sur un client non-deDE : early-return, coût nul.

### `CraftingOrderClassic_Locale_esES.lua`
> CraftingOrderClassic_Locale_esES.lua — overlay ESPAGNOL (esES/esMX). Clé FR → texte ES.
> Chargé APRÈS CraftingOrderClassic_Locale.lua (qui crée COC.L via setmetatable). Repli sur la clé FR
> pour toute chaîne non traduite. Guillemets « » dans les valeurs → évite l'échappement Lua des ".
> Sur un client non-hispanophone : early-return, coût nul.

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

**API** : `Skin.ProfLabel(p)` · `Skin.ProfIcon(key)` · `Skin.StatusInfo(s)` · `Skin.RarityColor(itemID)` · `Skin.QtyText(o)` · `Skin.QtySuffix(o)` · `Skin.FormatDuration(sec)` · `Skin.KnowsProf(r, p)` · `Skin.KnowsProfOrSeen(r, p)` · `Skin.InSource(r, src)` · `Skin.MakeMoneyRow(parent, x, y)` · `Skin.FirstChar(s)` · `Skin.ItemExists(itemID)` · `Skin.Icon(itemID, spellID)` · `Skin.MakeBadge(parent, size)` · `Skin.SearchHint(parent, editbox, text)` · `Skin.MakeCheck(parent, size)` · `Skin.WireItemTooltip(row)` · `Skin.MakeStatusIcon(parent, size)` · `Skin.MoneyIcon(parent, kind, anchorTo)` · `Skin.AutoHideScroll(scrollName, content)` · `Skin.ApplyShadow(fs)` · `Skin.SkinFrameBackdrop(f)` · `Skin.SkinWell(f)` · `Skin.MakeSeparator(parent, offsetY)`

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
> (dropdown maison : puits + closer + pool de lignes).
> INTOUCHABLE ici aussi : le langage couleur (statuts d'ordre, rareté) n'est jamais recoloré.

**API** : `Skin.MakeGoldButton(parent, w, h, text, template)` · `Skin.MakeWindow(name, w, h, opts)` · `Skin.SetWindowPortrait(f, tex)` · `Skin.SetPortraitClickable(f, onClick, tooltipText)` · `Skin.MakeTabs(f, defs, onSelect, opts)` · `Skin.MakeFlatRow(parent, w, h)` · `Skin.MakeArtisanRow(parent, w, h)` · `Skin.MakeFlyout(name, w, opts)` · `Skin.MakeIconButton(parent, size, tex)` · `Skin.MakeFilterButton(parent, w, h, text)`

### `CraftingOrderClassic_UI.lua`
> CraftingOrderClassic_UI.lua — fenêtre principale (chrome Blizzard natif, kit UI_Skin_Native).
> Onglets : Carnet / Commande / Récolte / Artisans / Mes artisans / Aide / Nouveautés.
> Lit le cache (COC.db.orders + Directory), jamais le réseau directement.

**API** : `UI:Build()` · `UI:BuildTabs(f)` · `UI:ShowTab(id)` · `UI:BuildOrdersTab(f)` · `UI:Toast(text, icon)` · `UI:RefreshOrders()` · `UI:RefreshHandoff()` · `UI:RefreshSoon()` · `UI:Refresh()` · `UI:Toggle()`

### `CraftingOrderClassic_UI_Post.lua`
> CraftingOrderClassic_UI_Post.lua — onglet « Commande » : sélection de plan (gauche) +
> réactifs « je fournis » / commission g-s-c / ciblage artisan (droite). Chargé après _UI.lua.

**API** : `UI:BuildPostTab(f)` · `UI:RefreshPost()` · `UI:RefreshPostPlans()` · `UI:RefreshPostPlanDetail()` · `UI:RefreshPostReagents()` · `UI:SelectPostPlan(entry)` · `UI:DoPostOrder()`

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

### `CraftingOrderClassic_UI_Post_LazyGold.lua`
> CraftingOrderClassic_UI_Post_LazyGold.lua — onglet « Commande » : couche Lazy Gold (lecture seule).
>   * barre d'outils (pièce = tri par rentabilité, « 123 » = valeurs exactes) — mêmes codes que la
>     vue métier, et le mode exact est le MÊME réglage partagé (db.lgExactProfit) ;
>   * indicateur de profit sur chaque ligne de la LISTE DES PLANS ;
>   * tri par rentabilité : liste à PLAT (les sections disparaissent), du plus rentable au moins.
> Tout est masqué/inerte si Lazy Gold n'est pas installé — COC reste autonome.

### `CraftingOrderClassic_UI_Gather.lua`
> CraftingOrderClassic_UI_Gather.lua — onglet « Récolte » : ressources de récolte (minéraux,
> herbes, cuirs, poissons) + demande de quantité + prix par pile + ciblage récolteur.
> Structure calquée sur _UI_Post.lua (même layout gauche/droite). Chargé après _UI_Post.lua.

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
> activées (CVar nameplateShowFriends).

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

**API** : `Craft:IsCraftOpen()` · `Craft:GetSelectedRecipe()` · `Craft:GetOpenProfessionInfo()` · `Craft:GetActiveAPI()` · `Craft:OpenProfessionKey()` · `Craft:DifficultyColor(difficulty)` · `Craft:OpenRank()` · `Craft:ReadRecipes()` · `Craft:Reagents(index)` · `Craft:Do(index, count)`

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

**API** : `MTSL:IsAvailable()` · `MTSL:SkillDetail(profKey, spellID)` · `MTSL:MissingRecipes(profKey)` · `MTSL:MissingCount(profKey)`

### `CraftingOrderClassic_ProfWindow.lua`
> CraftingOrderClassic_ProfWindow.lua — fenêtre métier custom 3 colonnes (migration depuis
> Guild Economy) : Recettes | Détail+Craft | Commandes du métier. Remplace la fenêtre Blizzard
> (neutralisée, jamais Hide() pour garder la session lisible). Colonnes dans _Recipes / _Detail ;
> la colonne Commandes vit ici (réutilise le carnet/entrantes du métier ouvert).
> 
> Vue métier par DÉFAUT (maquette designer) : PW:IsEnabled() vrai sauf COC.db.profWindow == false.
> `/co profwindow` bascule custom ↔ « Vue Blizzard » (opt-out). Quand la vue custom est active, désactive
> le takeover de Guild Economy (TradeScannerDB.replaceProfWindow=false) → jamais deux fenêtres à la fois.

**API** : `PW.CanFulfill(o)` · `PW:NeutralizeNative()` · `PW:RestoreNative()` · `PW:Build()` · `PW:EnsureNativeToggle(frame, key)` · `PW:OpenDock(nativeFrame)` · `PW:CloseDock()` · `PW:Hide()` · `PW:OpenFor(profKey)` · `PW:Refresh()` · `PW:IsEnabled()` · `PW:SetEnabled(on)` · `PW:OnProfessionShow()` · `PW:OnProfessionClose()`

### `CraftingOrderClassic_ProfWindow_Recipes.lua`
> CraftingOrderClassic_ProfWindow_Recipes.lua — colonne GAUCHE : liste de recettes virtualisée
> (scroll), recherche, couleur par difficulté, sélection, badge « demandé » (nb de commandes
> ouvertes pour l'objet). Port de TradeScanner_ProfWindow_Recipes.lua adapté à COC.Craft.

**API** : `PW:ToggleRecipeSection(ckey)` · `PW:RefreshRecipes()` · `PW:RenderRecipes()` · `PW:SelectRecipe(e)` · `PW:GetSelectedRecipe()`

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

**API** : `LG:IsAvailable()` · `LG:ItemValue(itemID)` · `LG:CoinTier(copper)` · `LG:ProfitTier(copper)` · `LG:ExactMode()` · `LG:SetExactMode(on)` · `LG:ProfitText(copper)` · `LG:Money(copper, colored)` · `LG:CraftProfit(profKey, spellID, numMade)` · `LG:EntryProfit(profKey, entry)` · `LG:BestPlanFor(profKey, rank)` · `LG:BestProfitFor(profKey, rank)` · `LG:PlanName(profKey, plan)` · `LG:BestPlanName(profKey, rank)` · `LG:BestKnownPlanFor(profKey, r)` · `LG:MinProfit()` · `LG:HighlightTier(profit)`

### `CraftingOrderClassic_ProfWindow_Orders.lua`
> CraftingOrderClassic_ProfWindow_Orders.lua — colonne « Commandes » de la vue métier (cabine de
> l'artisan). Cartes par demandeur avec onglets de relation (Guilde / Amis / Croisés / Tous),
> marqueur « je sais faire » (✓/✗ en TEXTURE), prix, résumé des composants fournis, et actions
> ACCEPTER / LIVRER + CHUCHOTER ; clic droit = sourdine (ordre) / ignorer (entrante). Inclut les
> demandes captées (/commerce, /guilde). Sorti de _ProfWindow.lua (anti-monolithe).

**API** : `PW:RefreshOrders()`

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

**API** : `Dir:OnPresence(kind, who)` · `Dir:ScanRelations()` · `Dir:ClassifySource(name)` · `Dir:ReclassifyAll()` · `Dir:PruneRoster(maxAgeDays, maxRecent)` · `Dir:OnRK(sender, message)` · `Dir:OnHello(sender, message, distribution)` · `Dir:OnPing(sender, _, distribution)` · `Dir:OnPong(sender)` · `Dir:Announce()` · `Dir:AnnounceTo(target)` · `Dir:DiscoverPlayer(name)` · `Dir:OnBeacon(who)` · `Dir:AnnounceThrottled()` · `Dir:DiscoverFriendsAndGuild()` · `Dir:Refresh()` · `Dir:RediscoverKnown(includeRecent)` · `Dir:CountOnline()` · `Dir:CountKnownCrafters()` · `Dir:WhoCanCraft(prof, spellID)` · `Dir:Start()`

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
> Directory_LFW.lua — statut « recherche de travail » (Looking For Work).
> 
> Un artisan se déclare dispo pour UN métier → diffusé au ROYAUME via le canal-texte (verbe LFW, réutilise
> l'infra canal v1.11.0, cf. balise/texte canal CraftLink). Les autres stockent { prof, expiry } EN RUNTIME
> (statut transitoire, non persisté) et l'affichent (nameplate + annuaire, couches à part). SÛR par
> construction : le stockage est clé par SENDER (émetteur réel, non falsifiable par le transport) → on ne
> peut déclarer QUE soi-même LFW. MON propre choix (COC.db.lfw.prof) PERSISTE et se ré-affirme au login +
> périodiquement (le récepteur applique un TTL, donc sans ré-émission je disparais de son radar).

**API** : `Dir:LFWOf(name)` · `Dir:OnLFW(sender, message)` · `Dir:MyLFW()` · `Dir:SetLFW(profKey)` · `Dir:LFWCmd(arg)` · `Dir:StartLFW()`

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
