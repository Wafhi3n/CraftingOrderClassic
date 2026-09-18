# Fiche de test réseau — COC sur WoW: Forever

Première occasion de valider le réseau de COC **pour de vrai**. Jusqu'ici : un seul compte, pas de
PTR, pas de guilde — tout le social a été écrit et corrigé à l'aveugle, par simulation. Plusieurs
features portent encore la mention « jamais validé à 2 comptes » ; le relais en mesh, lui, n'a
jamais tourné du tout (il faut trois clients).

Une heure empruntée à quinze personnes, ça se prépare. Cette fiche existe pour qu'on ne passe pas
la session à se demander quoi essayer.

---

## Avant de commencer

**Distribution.** Un zip du dossier `CraftingOrderClassic` vers
`_classic_beta_\Interface\AddOns\`. Pas de CurseForge : le groupe est connu, et une alpha publique
exposerait aussi les utilisateurs Era à du code non testé.

**Trace ON chez tout le monde**, avant la première manip :

```
/co trace          -- active (OFF par défaut, zéro coût en prod)
/co trace clear    -- repart d'un journal vide
```

Sans elle, un échec dit « ça marche pas » et rien d'autre. Avec elle, on sait **où** ça s'arrête.
En fin de session : `/reload` (la trace n'est écrite sur disque qu'au reload ou au logout), puis
récupérer `WTF\Account\<COMPTE>\SavedVariables\CraftingOrderClassic.lua` de chaque testeur.

**Rôles.** Nommer **A**, **B** et **C** une fois pour toutes, et s'y tenir dans les retours — « on
voyait pas » ne se diagnostique pas.

**Le piège qui invalide un test.** COC **persiste son roster**. Si A connaît déjà B d'une session
précédente, voir B ne prouve **rien** — ça peut venir du cache. Pour qu'une observation prouve
quelque chose, il faut soit un personnage **neuf**, soit un **changement** observable (un niveau de
métier qui monte, un ordre qui apparaît).

---

## Palier 1 — le transport

**Rien d'autre n'a de sens si ce palier échoue.** À faire en premier, à deux, en ville.

| # | Geste | Ce qu'on doit voir | Si ça rate |
|---|---|---|---|
| 1.1 | `/co` chacun de son côté | « canal rejoint » et non « connexion… » | le canal custom ne prend pas |
| 1.2 | A et B en ville, attendre ~30 s | le compteur « N en ligne » de `/co` monte chez les deux | annonce ou réception KO |
| 1.3 | **guilde** : A et B dans la guilde, `/co` | se voient même éloignés, hors portée de /say | **jamais testé** : on n'avait pas de guilde |
| 1.4 | **proximité** : A et B côte à côte, hors guilde si possible | se découvrent | SAY/YELL : en solo l'écho à soi-même était indistinguable d'un blocage |

Le 1.3 et le 1.4 sont les deux vraies inconnues. Le canal, lui, est déjà prouvé.

---

## Palier 2 — l'annuaire et le registre

C'est le portage du jour : sur Forever, le registre passe par le verbe **`RI`** (identifiants) et
non plus `RK` (bitfield). Personne ne l'a jamais vu tourner.

| # | Geste | Ce qu'on doit voir |
|---|---|---|
| 2.1 | B ouvre un métier une fois, A regarde l'onglet **Artisans** | B apparaît avec son métier et son niveau |
| 2.2 | A survole B | tooltip : métiers + « · N plans » |
| 2.3 | **B apprend une recette**, A re-regarde | le compte de plans **augmente** |

Le 2.3 est le seul qui prouve vraiment le réseau : c'est un **changement**, pas une lecture de
cache. Les deux premiers peuvent être servis par le roster persisté.

---

## Palier 3 — le cycle d'ordre

Le cœur du produit. Jamais joué entre deux clients réels.

| # | Geste | Ce qu'on doit voir |
|---|---|---|
| 3.1 | A poste un ordre sur un plan que B connaît | l'ordre apparaît chez B, dans sa vue métier |
| 3.2 | B accepte | A voit « accepté », le suivi à l'écran s'allume |
| 3.3 | B livre par **échange** | le greffon s'ouvre sur la fenêtre d'échange |
| 3.4 | B livre par **courrier** | le greffon pré-remplit (⚠️ **jamais `SendMail()` nous-mêmes** — c'est le joueur qui clique) |
| 3.5 | B **refuse** un ordre | A voit le refus, pas un silence |
| 3.6 | A **annule** après acceptation | B voit l'annulation |

---

## Palier 4 — le mesh (⚠️ la première fois, il faut **trois** clients)

Le relais rediffuse la fiche d'un artisan **hors ligne** à travers ses partenaires. Impossible à
tester jusqu'à aujourd'hui.

| # | Geste | Ce qu'on doit voir |
|---|---|---|
| 4.1 | A et B se connaissent ; A se déconnecte | — |
| 4.2 | C, qui n'a jamais croisé A, croise B | C voit la fiche de A, marquée **« via B »** |
| 4.3 | C survole A dans la liste | les métiers de A, en **estimation** (pas en vérité terrain) |

La mention « via B » est ce qui distingue une fiche relayée d'une fiche directe. Si elle manque,
c'est que la provenance n'est pas qualifiée — et une estimation présentée comme un fait est pire
qu'une absence.

---

## Palier 5 — le social

À faire seulement si les paliers 1 à 3 passent : sans transport, ces surfaces ne diront rien.

| # | Geste | Ce qu'on doit voir |
|---|---|---|
| 5.1 | B active **LFW** (« recherche de travail ») | badge **[Dispo]** chez A, sur la plaque et dans les listes |
| 5.2 | A fait clic-droit sur B | entrées « Commander … » dans le menu |
| 5.3 | A ouvre `/co journal` | les ordres de la session, en lecture seule |

Le 5.1 est le smoke test qui traîne depuis le patch 1.15.9 sur Era — l'occasion de le solder.

---

## Après la session

1. Chacun : `/co trace dump` (les 30 dernières lignes en chat, utile à chaud) puis **`/reload`**.
2. Récupérer le `CraftingOrderClassic.lua` des SavedVariables de **chaque** testeur.
3. Extraction hors-jeu : `scripts\dump_trace.ps1`.

Et pour chaque palier, noter **ce qui a été vu**, pas l'interprétation. « B n'apparaît pas chez A
après 2 min » vaut mille fois « la synchro marche pas » : le premier se diagnostique, le second se
discute.

Un échec net et reproductible est un bon résultat de session. Un « ça a l'air d'aller » sans trace
n'en est pas un.
