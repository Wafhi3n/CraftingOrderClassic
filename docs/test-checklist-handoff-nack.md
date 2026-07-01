# Checklist de test — Handoff + refus/désistement (NACK)

PTR `_classic_era_ptr_`, 2 comptes distincts (cf. mémoire `coc-ptr-account-testing` : les
SavedVariables sont PAR COMPTE, jamais 2 persos sur le même compte — faux positif réseau garanti).

- Compte #1 : Balragar/Luletta
- Compte #4 : Sheadra

Avant de commencer sur les deux comptes : `/co trace clear` puis `/co trace on` (journalise dans la
SavedVariable, lisible après `/reload` ou `/co trace dump`). Un fichier `.lua` ajouté au `.toc`
(ici `CraftingOrderClassic_Handoff.lua`) exige un **redémarrage complet** du client, pas un `/reload`
— à faire une fois avant de démarrer la checklist sur les deux comptes.

## 1. Relation « proche » (pré-requis Handoff)

- [ ] Sur #1, ajouter #4 comme ami (ami classique ou BattleTag) OU être en guilde ensemble.
- [ ] `/co status` sur les deux comptes → vérifier `dataVersion` identique (sinon la capacité précise
      par bitfield RK ne matche pas, seule la capacité grossière par métier fonctionnera).
- [ ] Les deux personnages doivent avoir le métier concerné ouvert au moins une fois (pour amorcer
      leurs recettes captées — cf. `mes recettes captées :`).

## 2. Palier 1 — Suggest sur MES commandes ouvertes

1. Sur #1 : poster une commande ouverte (`Tous`/`Guilde`/`Amis`, pas nommée) pour un objet que #4
   sait crafter.
2. #4 est hors ligne au moment du post.
3. Connecter #4 → attendu :
   - [ ] `/co trace dump` sur #4 montre la réception d'un `ORD|SUGG|<id>` en whisper de #1 (après le
     relais mesh normal `Orders:OnArtisanOnline`).
   - [ ] Toast + message chat « tu sais le faire — demandé par Balragar » côté #4 (`Handoff:AlertCapable`).
   - [ ] Pas de doublon si #4 se déco/reco plusieurs fois dans la même session (dédup `Handoff._sent`).
4. Répéter avec #4 déjà EN LIGNE au moment du post → doit aussi recevoir le nudge (via le relais mesh
   direct, pas Handoff:OnArtisanOnline).

## 3. Palier 2 — Entrante captée (/commerce, /guilde)

1. Sur #1, taper dans `/2` ou `/g` un message qui matche le pattern de capture (« WTB <item> ») —
   PAS un WTS/LFW (exclus exprès).
2. Attendu côté #1 (le capteur) :
   - [ ] L'entrée apparaît dans son onglet *Entrantes*.
   - [ ] `Handoff:NoteInbound` annonce en chat/toast « <artisan connu> peut faire une commande captée » si
     #4 (déjà en ligne et capable) est détecté — sinon, silence.
3. Si #4 était hors ligne au moment de la capture, connecter #4 → attendu :
   - [ ] #4 reçoit en whisper l'ordre de synthèse `CAP-<id>` (`_NewPayload`) PUIS le nudge
     `ORD|SUGG|<id>|1`.
   - [ ] Chez #4, la commande apparaît avec `viaAddon=false`, `captured=true` (visible via `/co trace`).
   - [ ] #4 accepte la commande captée → le demandeur original (`o.buyer`, un joueur SANS l'addon) est
     prévenu via **WhisperPub** (pas juste en interne), car `viaAddon=false`.

## 4. Chaînage d'une commande captée (régression du fix B1)

Avant le fix, `o.captured` était mort dans `Handoff:OnArtisanOnline` (bloqué par `_RelayMatch`, qui
exclut EXPRÈS les commandes captées du mesh). Ce scénario vérifie que le chaînage fonctionne
maintenant :

1. #4 reçoit une commande captée de #1 (scénario §3) mais ne peut PAS la crafter elle-même à 100 % de
   certitude — simuler plutôt : #4 connaît un 3ᵉ artisan (compte additionnel ou `/co debug` mode solo)
   capable, encore hors ligne au moment de la réception.
2. Ce 3ᵉ artisan se connecte pendant que #4 est en ligne et détient la commande captée
   (`o.captured == true`, `o.buyer ~= me()`).
3. Attendu :
   - [ ] `Handoff:OnArtisanOnline` chez #4 déclenche `self:Suggest(o, who)` pour le 3ᵉ artisan SANS
     passer par `_RelayMatch` (vérifiable via `/co trace` : un `ORD|SUGG` sortant malgré
     `_RelayMatch` qui aurait renvoyé `false` pour cet ordre).
   - [ ] Si ce scénario est irréalisable sur PTR à 2 comptes seulement, valider a minima par lecture de
     trace que `CanCraft` + `self:Suggest` sont bien appelés pour une entrée `o.captured == true` dans
     la boucle `OnArtisanOnline` (poser un `/co trace` verbeux autour de ce chemin si besoin).

## 5. Refus / désistement (NACK)

1. Sur #1 : poster une commande NOMMÉE (`recipient = #4`).
2. Sur #4 : cliquer **Refuser** sans avoir accepté → attendu :
   - [ ] Whisper `ORD|NACK|<id>|Sheadra` reçu par #1 (`/co trace dump`).
   - [ ] Statut chez #1 passe à **Refusée** (`o.status == "declined"`), toast + message chat
     « Sheadra a refusé ta commande : ... ».
   - [ ] Chez d'autres artisans à portée large, la commande reste visible/acceptable (refus nommé =
     silencieux pour les autres, seul l'auteur est notifié).
3. Sur #4 : accepter une commande OUVERTE (large, pas nommée) puis **Refuser** après acceptation
   (désistement) → attendu :
   - [ ] Broadcast global `ORD|NACK|<id>|Sheadra` (pas juste whisper).
   - [ ] La commande redevient `status = "open"`, `acceptedBy = nil` chez tout le monde (y compris #1
     et un 3ᵉ témoin éventuel).
   - [ ] Message chat « commande relâchée : <id> » côté #4.

## 6. Vue Métier — sourdine / réaffichage (fix B2)

1. Ouvrir la vue métier (`/co métier <profession>`) sur #1 ou #4 avec au moins une commande visible
   dans la colonne Commandes.
2. Clic droit sur une carte de commande (pas une entrante) → attendu :
   - [ ] La carte disparaît de la liste normale, le pied de colonne affiche `N en sourdine`.
3. Faire défiler jusqu'en bas de la colonne → attendu :
   - [ ] La commande en sourdine apparaît en ligne repliée (`Sourdine · <demandeur> — <objet>` +
     bouton **Réafficher**), APRÈS toutes les cartes normales.
4. Cliquer **Réafficher** → attendu :
   - [ ] La commande revient dans la liste normale (carte complète, boutons Accepter/Refuser/Chuchoter),
     le compteur « en sourdine » diminue, le pied de colonne se met à jour immédiatement.
5. `/reload` puis rouvrir la vue métier → la sourdine doit persister pour les commandes non réaffichées
   (stockée dans `COC.db.muted`, une SavedVariable).

## 7. Trace attendue (`/co trace dump`)

Pour chaque scénario ci-dessus, la trace doit montrer dans l'ordre :
1. L'émission (`[send]`) côté émetteur avec le bon canal (`whisper` pour SUGG/NACK ciblé, `global`
   pour NACK de désistement).
2. La réception (`[recv]`) côté destinataire, avec le message brut `ORD|...` non tronqué.
3. Aucune émission de balise `CLNK1` ou d'AddonMessage sur canal CHANNEL déclenchée par un timer
   (rappel : seuls les clics/actions joueur — CO/CC/CA — passent le hardware-event gate ; un envoi
   automatique en dehors d'un clic déclencherait `ADDON_ACTION_BLOCKED`, à surveiller dans les logs
   Blizzard si un scénario échoue silencieusement).

Si un scénario échoue : joindre les deux dumps `/co trace` (un par compte) avant de creuser plus loin.
