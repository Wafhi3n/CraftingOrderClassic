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
-- « Nouveautés » de l'Aide (overlay enUS existant) → pas de doublon de traduction.
local function versions()
    return {
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
