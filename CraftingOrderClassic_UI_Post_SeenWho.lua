-- CraftingOrderClassic_UI_Post_SeenWho.lua — POC (spec lien-metier, D16) : sous le nom du plan
-- choisi dans l'onglet Commande, « · sans l'addon : N » quand des artisans SANS l'addon savent le
-- faire (recettes lues au clic sur leur lien, ou vues crafter). Survol : qui, et d'où on le sait ;
-- clic : chuchoter au plus récent. Ne touche pas au ciblage de la commande (D10).
-- Retirable d'un geste : ce fichier, sa ligne du .toc, et l'appel dans RefreshPostPlanDetail.

local COC = CraftingOrderClassic
local UI  = COC.UI
local L   = COC.L

local MAX_NAMES = 8   -- lignes de noms dans l'infobulle

-- Zone de survol posée SUR la sous-ligne du plan (un texte ne reçoit pas la souris). Créée au
-- premier besoin, réutilisée ensuite.
local function hoverButton(self)
    local b = self._postSeenBtn
    if b then return b end
    b = CreateFrame("Button", nil, self.postPlanSub:GetParent())
    b:SetAllPoints(self.postPlanSub)
    b:SetScript("OnEnter", function(btn)
        local who = btn.who or {}
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Savent la faire, sans l'addon :"])
        for i = 1, math.min(#who, MAX_NAMES) do
            local w = who[i]
            GameTooltip:AddDoubleLine(w.name, w.via == "link" and L["par lien"] or L["vu crafter"],
                1, 1, 1, 0.6, 0.6, 0.6)
        end
        if who[1] then GameTooltip:AddLine(string.format(L["Clic : chuchoter à %s"], who[1].name), 0.3, 0.86, 0.43) end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    b:SetScript("OnClick", function(btn)
        local w = btn.who and btn.who[1]
        if w and ChatFrame_SendTell then ChatFrame_SendTell(w.name) end
    end)
    self._postSeenBtn = b
    return b
end

-- Appelé par RefreshPostPlanDetail, APRÈS qu'il a posé la sous-ligne du plan `e` (nil = aucun plan).
function UI:_RefreshPostSeenWho(e)
    local D = COC.Directory
    local who = (e and e.spellID and D and D.SeenWhoKnows) and D:SeenWhoKnows(self.postProf, e.spellID) or {}
    if #who == 0 then
        if self._postSeenBtn then self._postSeenBtn:Hide() end
        return
    end
    local sub = self.postPlanSub:GetText() or ""
    local add = "|cFF4CDB6E" .. string.format(L["sans l'addon : %d"], #who) .. "|r"
    self.postPlanSub:SetText(sub ~= "" and (sub .. " · " .. add) or add)
    local b = hoverButton(self)
    b.who = who
    b:Show()
end
