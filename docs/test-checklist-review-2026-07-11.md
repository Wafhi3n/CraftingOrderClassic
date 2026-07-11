# Checklist de test — revue anti-usurpation/spam du 2026-07-11 (10 findings)

> ## ✅ PASSE EFFECTUÉE LE 2026-07-11 — TOUT VERT (solo, SoD, déployé, NON commité)
>
> | Finding | Résultat |
> |---|---|
> | **#1** écrasement de commande | ✅ relais tiers **crée** ; `Mallory` tente d'écraser → **ignoré**, champs intacts, trace `NEW ignoré : Mallory ≠ acheteur en cache Frizga` ; la vraie acheteuse **peut** modifier |
> | **#4** DONE forgé | ✅ DONE sur une commande jamais acceptée → `done` mais **aucun crédit de rep** ; DONE légitime → **« crafts livrés au total : N+1 »** (crédit préservé) |
> | **#5** framing / faux positif | ✅ relais en rafale → **aucun** compteur sur l'acheteur ; post direct ×3 → `PROMPTED/MUTE` (la détection mord toujours) |
> | **#7** NACK rejouable | ✅ tiers → **muet** ; vrai destinataire → **1 seule** notif ; rejeu → **muet** |
> | **#10** fuite vue métier | ✅ commandes nommées à un TIERS **absentes** ; publique **affichée** |
> | **#2 #3 #6 #8 #9** | déployés ; couverts par les 355 tests headless — non rejouables en solo (voir §8) |
>
> **Deux pièges rencontrés, à ne pas refaire :**
> 1. **COCMonitor est hors `deploy.ps1`** → il faut le copier À LA MAIN. Une passe a été faite contre
>    l'**ancien** code de COC sans s'en rendre compte (COCMonitor était à jour, COC non) : l'attaque
>    « réussissait », ce qui a fait croire à un faux positif. Toujours vérifier qu'un correctif est bien
>    dans la copie DÉPLOYÉE avant de conclure.
> 2. **`INJ-N` est un placeholder**, pas un id. Tapé littéralement, le DONE tombe sur un id inexistant et
>    `_OnCycle` sort sans rien faire (test silencieusement nul).

Couvre les 10 correctifs de la revue (`#1`…`#10`). **Rien n'est commité ni sorti.**

**Ce qui est DÉJÀ prouvé en headless** (355 checks, `lua tools\elune\bin\lua.exe tests\run_all.lua .`) :
la logique pure des gardes `#1 #3 #4 #5 #7` + le round-trip `HI|SK` et le throttle de `#8`.
Cette checklist sert à vérifier **ce que le headless ne peut pas voir** : l'UI, les toasts, les
throttles, et surtout la **NON-RÉGRESSION** des flux légitimes (10 gardes ajoutées = 10 risques de
sur-bloquer).

Légende : ☐ à faire · **SOLO** = faisable maintenant (1 compte) · **2-CPT** = nécessite un 2ᵉ compte.

---

## 0. Pré-vol

- ☐ `.\deploy.ps1` (COC). **`/reload` suffit** — aucun `.lua` n'a été AJOUTÉ à un `.toc`
  (que des fichiers existants modifiés) → pas de redémarrage complet nécessaire.
- ☐ **COCMonitor** : il est hors `deploy.ps1` → **copier `COCMonitor\` à la main** dans `AddOns\`
  (l'injecteur a gagné `newas` et `sugg`, indispensables ci-dessous).
- ☐ `/co trace on` puis `/co trace clear` (on lira la trace à chaque étape).
- ☐ `/cocm` s'ouvre, bandeau `COC db:ok`, **aucune erreur Lua** au chargement.

> ⚠️ La lib a bougé : **`TRANSPORT_REV 9 → 10`** (confinement royaume). Si un autre addon embarquait
> une vieille CraftLink, c'est la nôtre qui gagne désormais. `CraftLink\sync-libs.ps1` a déjà été passé.

---

## 1. NON-RÉGRESSION (le plus important — à faire en premier)

Les 10 correctifs sont des **gardes**. Le vrai risque n'est pas qu'elles laissent passer, c'est
qu'elles **bloquent du légitime**. Si un seul de ces points casse → stop, on annule.

- ☐ **Poster** une commande (onglet Commande → Poster) → elle apparaît dans le **Carnet** ET dans la
  **vue métier**. La trace montre un `[send] global : ORD|NEW|…`.
- ☐ **Annuler** ma commande → passe `cancelled`.
- ☐ **Cycle complet** sur une commande injectée :
  1. `/cocm new Alice 2996 1 Tailoring` → note l'id (`INJ-1`).
  2. Carnet → **Accepter** → statut `accepted`, accepté par moi.
  3. **Livrer** → statut `delivered` (`remise`).
  4. `/cocm done INJ-1 Alice` (l'acheteuse confirme) → statut `done` **ET** le chat affiche
     « réception confirmée par Alice ! crafts livrés au total : **N+1** » → **la rep est bien créditée**
     (c'est le garde-fou de `#4` : il ne doit PAS avoir cassé le crédit légitime).
- ☐ **Annuaire** : les artisans connus s'affichent toujours **avec leurs métiers** (pas de « 0 métier »).
- ☐ **Canal** : `/cocm` → `Chan diag` → canal joint, index résolu.
- ☐ `/cocm clear` pour nettoyer les injections.

---

## 2. #1 — Un tiers ne peut plus ÉCRASER une commande existante  · **SOLO**

Le piège : le **relais mesh est légitime** (`OnArtisanOnline` pousse les commandes d'AUTRUI,
sender≠buyer). On doit donc autoriser la **création** par un tiers et interdire la **mutation**.

- ☐ **Relais légitime (doit CRÉER)** :
  `/cocm newas Relayeur Alice INJ-v1 2996 2 10g`
  → la commande `INJ-v1` apparaît, **acheteur = Alice**, qté 2, prix 10g. ✅ le mesh marche toujours.
- ☐ **Tiers qui tente d'écraser (doit être IGNORÉ)** :
  `/cocm newas Mallory Mallory INJ-v1 4306 99 1c`
  → dans `/cocm`, `INJ-v1` doit être **INCHANGÉE** : toujours acheteur **Alice**, qté **2**, prix **10g**.
  → la trace doit contenir : `NEW ignoré : Mallory ≠ acheteur en cache Alice (id=INJ-v1)`.
- ☐ **La vraie acheteuse met à jour (doit S'APPLIQUER)** :
  `/cocm newas Alice Alice INJ-v1 2996 5 20g` → qté passe à **5**, prix **20g**.

---

## 3. #5 — L'anti-spam ne peut plus être retourné contre une victime · **SOLO**

- ☐ Abaisser le seuil : `/co spam 2 60` (2 posts / 60 s → popup).
- ☐ **Relais en rafale ≠ spam de la victime** :
  `/cocm newas Relayeur Victime INJ-r1 2996` · `… INJ-r2 2996` · `… INJ-r3 2996`
  → **Victime ne doit PAS être signalée ni mutée** (panneau ANTI-SPAM de `/cocm` : aucun compteur sur
  Victime). C'était le faux positif « 25 relais → mute d'un acheteur légitime ».
- ☐ **Buyer forgé ≠ framing** : idem avec un id neuf et un `sender` ≠ buyer → toujours **aucun**
  compteur anti-spam sur la victime nommée dans le payload.
- ☐ **Post direct = toujours détecté** : `/cocm spam Spammeur 3` (là, sender == buyer)
  → l'anti-spam **DOIT** réagir (popup / compteur sur `Spammeur`). ✅ la détection n'est pas cassée.
- ☐ Remettre le seuil : `/co spam 5 60`.

---

## 4. #7 — Plus de « X a refusé ta commande » en boucle · **SOLO**

- ☐ Poster une commande **nommée** à `Sheadra` → note son id (`<MonPerso>-N`).
- ☐ **NACK d'un tiers non lié (doit être MUET)** : `/cocm nack <id> Mallory`
  → **aucun message**, statut inchangé (`open`). *Avant : ça imprimait « Mallory a refusé ta commande ».*
- ☐ **NACK du vrai destinataire (doit notifier UNE fois)** : `/cocm nack <id> Sheadra`
  → statut `declined` (Refusée), **1** message + **1** toast.
- ☐ **Rejeu du même NACK (doit être MUET)** : `/cocm nack <id> Sheadra` (2ᵉ fois)
  → **aucun nouveau message/toast**. *Avant : ça re-spammait à chaque rejeu.*
- ☐ **Joueur muté** : `/co mute Sheadra`, poster une 2ᵉ commande nommée à Sheadra,
  `/cocm nack <id2> Sheadra` → **aucune notification**. Puis `/co unmute Sheadra`.

---

## 5. #6 — Le nudge SUGG ne boucle plus · **SOLO**

- ☐ Injecter une commande d'un tiers pour un objet **que je sais crafter**
  (Couture 244 → ex. `2996` Bolt of Linen Cloth) : `/cocm new Alice 2996 1 Tailoring` → id `INJ-x`.
- ☐ `/cocm sugg INJ-x Pair` → **1 toast + son** « tu sais le faire ».
- ☐ `/cocm sugg INJ-x Pair` **×5** → **aucun nouveau toast/son**. *Avant : 5 toasts + 5 sons.*
- ☐ `/co mute Alice` puis `/cocm new Alice 2996 1 Tailoring` + `/cocm sugg <nouvel id> Pair`
  → **aucun toast** (acheteur muté).

---

## 6. #10 — La vue métier ne fuite plus / respecte les mutes · **SOLO**

- ☐ **Fuite d'une commande privée d'un TIERS (doit être INVISIBLE)** :
  `/cocm new Alice 2996 1 Tailoring Bob` (commande d'Alice **nommée à Bob**, ni moi ni mon reroll)
  → ouvrir la **vue métier** Couture → la commande **ne doit PAS apparaître**.
  *Avant : elle s'affichait (fuite d'info sur une commande privée).*
- ☐ **Commande publique = toujours visible** : `/cocm new Alice 2996 1 Tailoring`
  → elle **apparaît** bien dans la vue métier. ✅ pas de sur-blocage.
- ☐ **Commande nommée à MOI = visible** : `/cocm new Alice 2996 1 Tailoring <MonPerso>` → visible.
- ☐ **Acheteur muté** : `/co mute Alice` → ses commandes basculent dans la section **repliée en bas**
  (sourdine), plus dans la liste active. `/co unmute Alice` → elles remontent.

---

## 7. #8 — Découverte : 1 seul `HI|SK` au lieu de `PING`+`HI` · **SOLO (partiel)**

- ☐ `/co trace clear`, puis **survoler** un vrai joueur porteur de l'addon (ou `/co refresh`).
- ☐ Dans `/cocm` → TRACE, chercher l'envoi dirigé : on doit voir **UNE seule ligne**
  `[send] whisper→<Nom> : HI|SK|lvl=…` — **et plus** la paire `PING` puis `HI`.
- ☐ Le joueur croisé entre dans l'annuaire **avec ses métiers** (le SK est dans le hello).
- ☐ **2-CPT** — non vérifiable maintenant : que les DEUX comptes se voient mutuellement avec métiers,
  et qu'un `PING`+`HI` groupé (vieux client) ne déclenche qu'**une** annonce.

---

## 8. Reste — non vérifiable en solo

- ☐ **2-CPT** `#3` : rebroadcast canal d'un **reroll vérifié** du buyer accepté
  *(logique prouvée en headless : 2 checks)*.
- ☐ **2-CPT** `#4` : l'attaque exacte (acheteur malveillant nommant `crafter=victime` dans le DONE)
  n'est pas rejouable avec l'injecteur actuel *(prouvée en headless : 2 checks)*. Le **crédit légitime**
  est lui vérifié en §1.
- ☐ **2-CPT** `#9` : cooldown 60 s/cible d'`OnArtisanOnline` — se voit dans la trace quand un artisan
  passe en ligne (un flapping ne doit plus rejouer 25 whispers).
- ☐ **CROSS-ROYAUME** `#2` : le confinement royaume du trafic AddonMessage n'est pas testable sans un
  perso d'un royaume non connecté. **À surveiller** : que le trafic **même-royaume** marche toujours
  (c'est implicitement couvert par tout le reste de cette checklist — si §1 passe, le confinement ne
  sur-bloque pas).

---

## 9. Après la passe

- ☐ `/cocm clear` + `/co trace off`.
- ☐ Remettre les réglages touchés (`/co spam 5 60`, `/co unmute …`).
- ☐ Si tout est vert → commit, puis `coc-release-check` avant toute release.
