-- CraftingOrderClassic_UI_News.lua — onglet « Nouveautés » : notes de version (changelog) affichées
-- EN JEU, version par version, la plus récente en tête. Contenu figé et localisé, peint UNE fois à la
-- construction (même structure que l'onglet Aide). Source humaine : CHANGELOG.md — garder les deux en
-- phase à chaque release (ici : les points forts localisés, pas la prose complète du .md).

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local BODY_W = 780

-- Une entrée par version. Les lignes v1.4.0 REUTILISENT les clés déjà traduites de l'ancienne section
-- « Nouveautés » de l'Aide (overlay enUS existant) → pas de doublon de traduction. Scindé en deux
-- blocs (récent / plus ancien) concaténés par versions() : chaque bloc reste sous le seuil anti-monolithe.
local function versionsRecent()
    return {
        {
            v = "v1.11.0", title = L["Annuler une commande publique atteint tout le royaume"],
            lines = {
                L["Une commande publique voyage sur le canal du royaume depuis la v1.10.0, mais pas son annulation : un artisan que tu n'as jamais croisé la voyait « ouverte » pendant six heures, l'acceptait, et farmait les réactifs pour rien. L'annulation part désormais sur le même canal."],
                L["Poster et annuler ne perdent plus de messages. Le canal exige un clic ou une touche et n'accepte qu'une ligne par seconde : un |cFFFFFFFF/co post|r tapé au chat, ou deux commandes postées dans la même seconde, disparaissaient sans trace. Ces lignes patientent maintenant dans une file et partent à ton prochain clic."],
                L["Seules les commandes NOUVELLES et les ANNULATIONS voyagent sur le canal, et seulement les publiques. Guilde, amis et commandes nommées restent privées ; les acceptations restent entre les deux joueurs concernés."],
            },
        },
        {
            v = "v1.10.2", title = L["Correctif : erreur en combat dans la vue métier"],
            lines = {
                L["Sélectionner une recette pendant un combat ne provoque plus d'erreur bloquée : le bouton « Créer » est un bouton sécurisé, que le jeu interdit de masquer en plein combat. L'addon attend maintenant la fin du combat pour l'afficher ou le masquer."],
            },
        },
        {
            v = "v1.10.1", title = L["Corrections : qui reçoit les alertes de commandes"],
            lines = {
                L["Les alertes de commandes ne dépendent plus du réglage |cFFFFFFFF/co scan|r : le scanner de chat et le carnet partageaient une option par erreur. Une commande publique te prévient désormais dès que tu as le métier."],
                L["Une commande publique portant un objet absent du catalogue arrivait en silence : elle te prévient maintenant, au lieu de dormir dans le carnet."],
                L["Démuter un joueur réarme la détection de spam le concernant ; revenir de la vue métier d'un reroll ne laisse plus les boutons Créer masqués ; et l'addon travaille nettement moins à chaque ligne de chat sur un royaume chargé."],
            },
        },
        {
            v = "v1.10.0", title = L["Les commandes touchent tout le royaume + un coup d'œil sur les recettes de tes rerolls"],
            lines = {
                L["Une commande postée à « Tous » part maintenant aussi sur le canal du royaume, pas seulement vers les joueurs déjà croisés ou tes amis/guilde — un inconnu qui n'a jamais croisé ton chemin peut désormais la voir. Tu ne reçois un toast que pour un métier que tu as : une commande de Forge ne dérange pas un Enchanteur."],
                L["Clique sur le métier d'un reroll depuis le menu minimap : fenêtre en lecture seule avec ses recettes connues, réactifs requis et niveau de compétence. Pas de bouton créer (tu n'es pas connecté sur ce perso), pas de comptage de sacs."],
                L["Le menu reroll de la minimap ne liste plus que les vrais métiers (Cuisine, Premiers soins, Pêche et Poisons n'encombrent plus la liste) ; le seuil de détection de spam est réglable via |cFFFFFFFF/co spam|r, avec un mode mute automatique en plus du popup habituel."],
            },
        },
        {
            v = "v1.9.0", title = L["Tes rerolls réunis : cooldowns partagés, une identité, l'onglet Mes artisans"],
            lines = {
                L["Cooldowns de recettes partagés : les autres voient « Transmutation : prête » ou « dans 14h » sur ton infobulle d'artisan — fini de demander en canal si ton Arcanite est dispo."],
                L["Regroupe tes persos sous une identité (|cFFFFFFFF/co alts on|r) : une commande nommée pour ton alchimiste hors ligne arrive sur le perso où tu es connecté, et tu peux l'accepter depuis n'importe lequel. Vérifié des deux côtés (personne ne peut se faire passer pour le reroll d'autrui). Désactivé par défaut."],
                L["Nouvel onglet « Mes artisans » : tous les métiers de ton compte sur le royaume en une vue, comme un seul perso — niveau, recettes connues par catégorie, cooldowns en tête, et quel perso porte chaque recette."],
            },
        },
        {
            v = "v1.8.0", title = L["Sous le capot : mises à jour plus sûres"],
            lines = {
                L["Tes données sauvegardées portent désormais une version : une mise à jour qui doit les réorganiser ne tourne qu'une fois, tes recettes et commandes restent intactes."],
                L["Protocole de commandes consolidé (mêmes échanges réseau) : ce build reste compatible avec les joueurs encore en 1.7.x."],
            },
        },
        {
            v = "v1.7.1", title = L["Alertes de plan looté qui te concernent"],
            lines = {
                L["L'alerte de plan looté ne se déclenche plus que s'il te concerne : tu as le métier et peux l'apprendre, ou un ami/partenaire de ton annuaire ne le connaît pas encore."],
                L["Les candidats au don incluent désormais tes amis, pas seulement les partenaires marqués — l'alerte « intéressés » et |cFFFFFFFF/co gift|r touchent tout ton annuaire."],
            },
        },
    }
end

local function versionsOlder()
    return {
        {
            v = "v1.7.0", title = L["Amis Battle.net + commande par métier"],
            lines = {
                L["Les métiers et le menu Crafting Order fonctionnent maintenant sur les amis Battle.net, pas seulement les amis ajoutés par personnage."],
                L["Clic droit sur un artisan : une entrée « Passer commande » par métier, qui ouvre l'onglet Commande déjà réglé sur ce métier."],
                L["Le résumé d'un artisan indique la profondeur de son carnet (« · N plans ») ; maintiens Maj sur son infobulle en jeu pour lister ses recettes connues."],
                L["Correctif : un personnage n'affiche plus par erreur les métiers de ses rerolls dans ton annuaire."],
            },
        },
        {
            v = "v1.6.0", title = L["Allemand et espagnol + onglet Nouveautés"],
            lines = {
                L["L'interface se traduit en allemand et en espagnol selon la langue de ton client WoW."],
                L["Ce nouvel onglet « Nouveautés » affiche les notes de version directement en jeu."],
            },
        },
        {
            v = "v1.5.0", title = L["Repérer les crafteurs sans l'addon + passe de performance"],
            lines = {
                L["Repérage passif des crafteurs autour de toi, même sans l'addon (onglet Artisans → « Repérer les crafteurs autour », ou |cFFFFFFFF/co crafters on|r). Désactivé par défaut, en ville seulement."],
                L["Liste de plans de l'onglet Commande réécrite : plus fluide sur les métiers à centaines de recettes (Couture)."],
                L["La fenêtre ne se redessine plus à chaque message réseau : les rafales sont regroupées en un seul rendu."],
                L["Protocole de commande durci : un autre client ne peut plus annuler ta commande, usurper une acceptation, ni s'attribuer une livraison."],
            },
        },
        {
            v = "v1.4.0", title = L["Commander depuis les panneaux Amis & Guilde"],
            lines = {
                L["Survole un ami dans la liste d'amis, ou sélectionne un membre dans le panneau de guilde : ses métiers primaires s'affichent sans ouvrir cette fenêtre."],
                L["Clic droit sur un joueur qui a l'addon (ami, guilde, croisé) : « Passer commande à… » ouvre l'onglet Commande déjà ciblé sur lui."],
                L["« Met » devient « Annuaire ». Le bouton « Rafraîchir l'annuaire » appelle le canal : tous les porteurs en ligne répondent et s'y ajoutent."],
            },
        },
        {
            v = "v1.3.0", title = L["Greffons échange & courrier, dock en vue Blizzard"],
            lines = {
                L["Panneaux compagnons sur la fenêtre d'échange et de courrier pour livrer une commande sans ouvrir le carnet."],
                L["La colonne Commandes peut s'ancrer à droite de la fenêtre métier native (vue Blizzard)."],
            },
        },
    }
end

local function versions()
    local out = versionsRecent()
    for _, e in ipairs(versionsOlder()) do out[#out + 1] = e end
    return out
end

-- Peint une version (titre doré « vX.Y.Z + résumé », puis une puce par ligne). Renvoie le Y suivant.
local function paintVersion(body, ver, y)
    local title = body:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 0, y); title:SetWidth(BODY_W); title:SetJustifyH("LEFT")
    title:SetText("|cFFE8B84B" .. ver.v .. "|r  " .. ver.title)
    title:SetTextColor(Skin.unpack(Skin.color.goldHi)); Skin.ApplyShadow(title)
    y = y - 22
    for _, line in ipairs(ver.lines) do
        local dot = body:CreateTexture(nil, "OVERLAY")
        dot:SetSize(10, 10); dot:SetPoint("TOPLEFT", 6, y - 3); dot:SetTexture(Skin.tex.broadcast)
        local fs = body:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("TOPLEFT", 22, y); fs:SetWidth(BODY_W - 22); fs:SetJustifyH("LEFT")
        fs:SetTextColor(Skin.unpack(Skin.color.text)); Skin.ApplyShadow(fs); fs:SetText(line)
        y = y - fs:GetStringHeight() - 8
    end
    return y - 14
end

function UI:BuildNewsTab(f)
    local panel = CreateFrame("Frame", nil, f); self.insetPanel(panel, f); self.newsPanel = panel

    local scroll = CreateFrame("ScrollFrame", "CraftingOrderNewsScroll", panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -74); scroll:SetPoint("BOTTOMRIGHT", -32, 22)
    local body = CreateFrame("Frame", nil, scroll); body:SetSize(BODY_W, 10); scroll:SetScrollChild(body)
    self.newsBody = body

    local y = -2
    for _, ver in ipairs(versions()) do y = paintVersion(body, ver, y) end
    body:SetHeight(math.max(-y, 10))
end

function UI:RefreshNews()
    Skin.AutoHideScroll("CraftingOrderNewsScroll", self.newsBody)
end
