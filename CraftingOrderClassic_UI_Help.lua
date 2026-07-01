-- CraftingOrderClassic_UI_Help.lua — onglet Aide : page unique défilante qui explique les autres
-- onglets (Carnet/Commande/Récolte/Artisans), la Vue Métier et le réseau. Contenu data-driven
-- (table HELP) rendu par un renderer générique → ajouter une section = ajouter une entrée localisée.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local BODY_W = 780

-- Table de contenu, découpée en petites fonctions thématiques (anti-monolithe) et concaténée par
-- content(). {icon=Skin.tex.xxx, title=L[...], lines={L[...], ...}} ; un bullet natif (texture
-- broadcast, réutilisée partout ailleurs dans l'addon) préfixe chaque ligne — pas de glyphe "•" tofu.
local function contentIntro()
    return {
        {
            icon = Skin.tex.workorder, title = L["C'est quoi Crafting Order ?"],
            lines = {
                L["Réseau GLOBAL et SOCIAL de commandes de craft — fonctionne sans guilde, entre tous les joueurs de l'addon."],
                L["Poste ce dont tu as besoin, ou consulte les commandes que tu peux honorer avec tes métiers."],
            },
        },
        {
            icon = Skin.tex.gear, title = L["Ouvrir la fenêtre et commandes utiles"],
            lines = {
                L["Clic gauche sur l'icône minimap (ou |cFFFFFFFF/co|r) : ouvre cette fenêtre."],
                L["Clic droit sur l'icône minimap (ou |cFFFFFFFF/co métier|r) : ouvre la Vue Métier d'un de tes métiers."],
                L["|cFFFFFFFF/co help|r dans le chat : liste complète des commandes slash."],
                L["|cFFFFFFFF/co channel off|r / |cFFFFFFFF/co channel on|r : quitter/rejoindre le canal réseau."],
            },
        },
        {
            icon = Skin.tex.broadcast, title = L["Les 4 onglets de cette fenêtre"],
            lines = {
                L["|cFFE8B84BCarnet|r : tes commandes à toi (postées), en cours ou archivées."],
                L["|cFFE8B84BCommande|r : poster une demande de craft à faire réaliser par un artisan."],
                L["|cFFE8B84BRécolte|r : poster une demande de matières à un récolteur (mine, herbe, peau, pêche)."],
                L["|cFFE8B84BArtisans|r : l'annuaire — qui sait crafter quoi, en ligne ou non."],
            },
        },
    }
end

local function contentPosting()
    return {
        {
            icon = Skin.tex.workorder, title = L["Poster une commande de craft"],
            lines = {
                L["Onglet |cFFE8B84BCommande|r → choisis un métier puis un plan dans la liste."],
                L["Shift-clic un objet dans un sac ou un lien de chat pour le présélectionner s'il correspond à un plan."],
                L["Coche les réactifs que TU fournis toi-même (le reste reste à la charge de l'artisan)."],
                L["Choisis la quantité, la commission proposée, puis le destinataire (guilde, amis, un artisan précis, ou diffuser à tous)."],
                L["Clique |cFFE8B84BPoster|r : la commande apparaît dans ton Carnet et chez les artisans concernés."],
            },
        },
        {
            icon = Skin.tex.crate, title = L["Poster une commande de récolte"],
            lines = {
                L["Onglet |cFFE8B84BRécolte|r → choisis un métier de récolte puis une ressource."],
                L["Choisis à l'unité ou par pile, la quantité voulue et le prix proposé, puis le destinataire."],
                L["Fonctionne comme une commande de craft, mais ciblée sur les joueurs qui ont le métier de récolte, pas de recette à connaître."],
            },
        },
    }
end

local function contentFulfill()
    return {
        {
            icon = Skin.tex.ok, title = L["Accepter / livrer une commande — la Vue Métier"],
            lines = {
                L["L'acceptation et la livraison ne se font PAS dans le Carnet : ouvre la |cFFE8B84BVue Métier|r du métier concerné (clic droit minimap, ou |cFFFFFFFF/co métier <nom>|r)."],
                L["La 3ᵉ colonne de la Vue Métier liste toutes les commandes de ce métier : accepte, crafte, puis livre."],
                L["Les demandes captées dans |cFFE8B84B/commerce|r et |cFFE8B84B/guilde|r de joueurs sans l'addon apparaissent aussi ici, marquées « entrante »."],
                L["Un artisan connu qui sait honorer une commande captée est notifié à sa prochaine connexion (voir « Confiées » dans le Carnet)."],
            },
        },
        {
            icon = Skin.tex.broadcast, title = L["Le Carnet en détail"],
            lines = {
                L["|cFFE8B84BEn cours|r : tes commandes ouvertes ou acceptées par un artisan."],
                L["|cFFE8B84BArchivées|r : tes commandes livrées ou annulées."],
                L["|cFFE8B84BConfiées|r : commandes gardées pour un artisan connu capable de les honorer, en attendant qu'il se reconnecte."],
                L["Depuis le Carnet, tu peux annuler une commande tant qu'elle n'est pas livrée."],
            },
        },
    }
end

local function contentSocial()
    return {
        {
            icon = Skin.tex.online, title = L["Annuaire & social"],
            lines = {
                L["L'onglet Artisans liste les joueurs connus par source : guilde, amis, ajoutés manuellement, croisés récemment."],
                L["Survole un joueur (tooltip) pour voir ses métiers et son niveau de compétence."],
                L["Clic droit sur un joueur (chat, groupe...) pour l'ajouter à ton annuaire — utile pour le retrouver même hors ligne."],
                L["La pastille verte/grise indique s'il est en ligne."],
            },
        },
        {
            icon = Skin.tex.gear, title = L["Réseau, confidentialité & statuts"],
            lines = {
                L["L'addon rejoint un canal dédié pour faire circuler le carnet entre joueurs de l'addon — aucun message lisible n'y est envoyé."],
                L["|cFFFFFFFF/co channel off|r le quitte à tout moment (whisper et guilde restent actifs) ; |cFFFFFFFF/co channel on|r le rejoint."],
                L["Statuts d'une commande : "] .. "|cFFFFCC00" .. L["En attente"] .. "|r → |cFF33CCFF" .. L["Acceptée"]
                    .. "|r → |cFF33DD33" .. L["Livrée"] .. "|r (ou |cFF888888" .. L["Annulée"] .. "|r / |cFFFF4444" .. L["Refusée"] .. "|r).",
            },
        },
    }
end

local function content()
    local out = {}
    for _, part in ipairs({ contentIntro(), contentPosting(), contentFulfill(), contentSocial() }) do
        for _, sec in ipairs(part) do out[#out + 1] = sec end
    end
    return out
end

-- Une section : icône + titre en tête, puis une ligne par item (bullet broadcast + texte wrap).
local function paintSection(body, sec, y)
    local ic = body:CreateTexture(nil, "OVERLAY")
    ic:SetSize(18, 18); ic:SetPoint("TOPLEFT", 0, y); ic:SetTexture(sec.icon or Skin.tex.unknown)

    local title = body:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", ic, "RIGHT", 6, 0); title:SetText(sec.title)
    title:SetTextColor(Skin.unpack(Skin.color.goldHi)); Skin.ApplyShadow(title)
    y = y - 22

    for _, line in ipairs(sec.lines) do
        local dot = body:CreateTexture(nil, "OVERLAY")
        dot:SetSize(10, 10); dot:SetPoint("TOPLEFT", 6, y - 3); dot:SetTexture(Skin.tex.broadcast)
        local fs = body:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("TOPLEFT", 22, y); fs:SetWidth(BODY_W - 22); fs:SetJustifyH("LEFT")
        fs:SetTextColor(Skin.unpack(Skin.color.text)); Skin.ApplyShadow(fs)
        fs:SetText(line)
        y = y - fs:GetStringHeight() - 8
    end
    return y - 10
end

-- Contenu figé (aucune dépendance à l'état de jeu) : peint UNE fois à la construction, pas de
-- pool de lignes ni de re-render à chaque Refresh() comme les autres onglets (données vivantes).
function UI:BuildHelpTab(f)
    local panel = CreateFrame("Frame", nil, f); self.insetPanel(panel, f); self.helpPanel = panel

    local scroll = CreateFrame("ScrollFrame", "CraftingOrderHelpScroll", panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -74); scroll:SetPoint("BOTTOMRIGHT", -32, 22)
    local body = CreateFrame("Frame", nil, scroll); body:SetSize(BODY_W, 10); scroll:SetScrollChild(body)
    self.helpBody = body

    local y = -2
    for _, sec in ipairs(content()) do y = paintSection(body, sec, y) end
    body:SetHeight(math.max(-y, 10))
end

function UI:RefreshHelp()
    Skin.AutoHideScroll("CraftingOrderHelpScroll", self.helpBody)
end
