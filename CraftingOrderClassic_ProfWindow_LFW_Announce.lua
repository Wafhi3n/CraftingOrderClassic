-- CraftingOrderClassic_ProfWindow_LFW_Announce.lua — la case « Annoncer en Commerce » de l'offre LFW.
--
-- Spec annonce-commerce, palier 4 : un artisan qui ACTIVE sa dispo peut poster « LFW <métier> #CO »
-- sur Trade (Services), lisible par tous, et que l'addon des autres relit (bonjour chuchoté, puis son
-- profil par le réseau). La case est le MÊME réglage que celle du formulaire de commande
-- (COC.db.announceTrade, décochée au départ, dernier choix retenu — décision du user, 2026-09-29).
-- Cocher ne poste rien : la ligne part au clic qui active la dispo (PW:_ToggleLFW, /co lfw), jamais
-- au renouvellement automatique. Fichier à part : l'hôte (_ProfWindow_LFW.lua) touche les 500 lignes.

local COC  = CraftingOrderClassic
local Skin = COC.UI.Skin
local L    = COC.L
local PW   = COC.ProfWindow

function PW:_BuildLFWAnnounceCheck(p, y)
    if p.announce then return end
    local ann = Skin.MakeCheckButton(p, L["Annoncer en Commerce"])
    ann:SetPoint("TOPLEFT", 8, y)
    ann:SetScript("OnClick", function(b) if COC.db then COC.db.announceTrade = b:GetChecked() and true or nil end end)
    ann:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_TOP")
        GameTooltip:SetText(L["Annoncer en Commerce"], 1, 1, 1)
        GameTooltip:AddLine(L["Quand tu actives ta dispo, poste aussi une ligne sur Trade (Services) : les joueurs avec ou sans l'addon voient que tu cherches du travail. Une ligne par activation, jamais au renouvellement automatique ; dans une capitale. Même réglage que la case du formulaire de commande."], nil, nil, nil, true)
        GameTooltip:Show()
    end)
    ann:SetScript("OnLeave", GameTooltip_Hide)
    p.announce = ann
end
