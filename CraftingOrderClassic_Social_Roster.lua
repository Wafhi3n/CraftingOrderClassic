-- CraftingOrderClassic_Social_Roster.lua — affichage des métiers sur les fenêtres NATIVES.
-- * Liste d'AMIS : petit tooltip collé à droite du tooltip natif (post-hook FriendsFrameTooltip_Show).
-- * GUILDE : « sidecar » sous le panneau détail natif (post-hook GuildStatus_Update). Enfant de
--   GuildMemberDetailFrame → se masque tout seul avec lui ; couvre AUSSI les guildies hors-ligne
--   (que le clic-droit ne peut pas atteindre — cf. _Social_Menu.lua).
-- Source unique : Social:ProfSummary(nom) → nil si le joueur n'a pas l'addon (rien ne s'affiche).

local COC    = CraftingOrderClassic
local Social = COC.Social

-- ==========================================================================================
-- Liste d'amis : tooltip « à côté »
-- ==========================================================================================
local friendTip
local function ensureFriendTip()
    if not friendTip then
        friendTip = CreateFrame("GameTooltip", "COCFriendProfTip", UIParent, "GameTooltipTemplate")
    end
    return friendTip
end

-- Résout le nom de perso ciblé par une ligne d'amis : ami-perso (type WOW) → nom direct ;
-- ami Battle.net → perso WoW joué (Social:BNetCharFromAccount gate client + version, nil sinon).
local function friendLineName(button)
    if not (button and button.id) then return nil end
    if button.buttonType == FRIENDS_BUTTON_TYPE_WOW then
        local info = C_FriendList and C_FriendList.GetFriendInfoByIndex(button.id)
        return info and info.name
    elseif button.buttonType == FRIENDS_BUTTON_TYPE_BNET then
        if not (C_BattleNet and C_BattleNet.GetFriendAccountInfo) then return nil end
        return Social:BNetCharFromAccount(C_BattleNet.GetFriendAccountInfo(button.id))
    end
    return nil
end

local function onFriendTooltip(button)
    local tip = ensureFriendTip()
    tip:Hide()
    local name = friendLineName(button)
    -- Survol = découverte proactive MODÉRÉE (anti-rafale contre le balayage souris + throttle 60 s/nom ;
    -- ne ping que si métiers inconnus) → skill/recipes se remplissent avant le clic-droit.
    if name then Social:MaybeDiscover(name) end
    local summary = name and Social:ProfSummary(name)
    if not (summary and FriendsTooltip) then return end
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    tip:ClearAllPoints()
    tip:SetPoint("TOPLEFT", FriendsTooltip, "TOPRIGHT", 4, 0)
    tip:AddLine("|cFF33DD88Crafting Order|r", 1, 1, 1)
    tip:AddLine(summary, 1, 1, 1)
    tip:Show()
end

function Social:_WireFriendTooltip()
    -- IMPORTANT : PAS de hooksecurefunc("FriendsFrameTooltip_Show"). Le OnEnter des lignes capture une
    -- RÉFÉRENCE directe à cette fonction au chargement du FrameXML → enrober _G[...] n'est vu qu'aux
    -- appels PAR NOM (sélection), pas au survol. On se greffe donc sur le OnShow du tooltip natif, qui
    -- se déclenche à TOUS les cas (survol inclus) ; FriendsTooltip.button = la ligne (posé avant :Show()).
    if not (FriendsTooltip and FriendsTooltip.HookScript) then return end
    FriendsTooltip:HookScript("OnShow", function(tt) onFriendTooltip(tt.button) end)
    FriendsTooltip:HookScript("OnHide", function() if friendTip then friendTip:Hide() end end)
    self._friendHooked = true
end

-- ==========================================================================================
-- Guilde : sidecar sous le panneau détail
-- ==========================================================================================
local guildBox
local function ensureGuildBox()
    if guildBox or not GuildMemberDetailFrame then return guildBox end
    local Skin = COC.UI and COC.UI.Skin
    local box = CreateFrame("Frame", nil, GuildMemberDetailFrame, "BackdropTemplate")
    box:SetPoint("TOPLEFT",  GuildMemberDetailFrame, "BOTTOMLEFT",  0, -2)
    box:SetPoint("TOPRIGHT", GuildMemberDetailFrame, "BOTTOMRIGHT", 0, -2)
    box:SetHeight(56)
    box:SetFrameLevel(GuildMemberDetailFrame:GetFrameLevel() + 5)
    if Skin and Skin.SkinWell then Skin.SkinWell(box) end
    box.text = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    box.text:SetPoint("TOPLEFT", 12, -10); box.text:SetPoint("RIGHT", -12, 0)
    box.text:SetJustifyH("LEFT"); box.text:SetWordWrap(true)
    box.btn = (Skin and Skin.MakeGoldButton) and Skin.MakeGoldButton(box, 160, 20, COC.L["Passer commande"])
        or CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    box.btn:SetPoint("BOTTOMLEFT", 12, 8)
    guildBox = box
    return box
end

local function updateGuildBox()
    local box = ensureGuildBox()
    if not box then return end
    local name = GuildFrame and GuildFrame.selectedName
    if name and Ambiguate then name = Ambiguate(name, "short") end
    -- Sélection d'un guildie = découverte proactive MODÉRÉE (anti-rafale + throttle 60 s/nom, seulement
    -- si métiers inconnus) → métiers à jour dans l'encart.
    if name then Social:MaybeDiscover(name) end
    local summary = name and Social:ProfSummary(name)
    if not (summary and GuildMemberDetailFrame:IsShown()) then box:Hide(); return end
    box.text:SetText("|cFF33DD88Crafting Order|r   " .. summary)
    box.btn:SetScript("OnClick", function()
        if COC.UI and COC.UI.OpenPostForArtisan then COC.UI:OpenPostForArtisan(name) end
    end)
    box:Show()
end

function Social:_WireGuildPanel()
    if type(GuildStatus_Update) == "function" then
        hooksecurefunc("GuildStatus_Update", updateGuildBox)
        self._guildHooked = true
    end
end

-- Amis/Guilde vivent dans Blizzard_UIPanels_Game, un module chargé À LA DEMANDE (première ouverture
-- du panneau social) — PAS encore chargé à PLAYER_LOGIN. hooksecurefunc sur un nom absent de _G est
-- un no-op silencieux : accrocher tout de suite s'il est déjà là, sinon attendre ADDON_LOADED.
local function isUIPanelsLoaded()
    if C_AddOns and C_AddOns.IsAddOnLoaded then return C_AddOns.IsAddOnLoaded("Blizzard_UIPanels_Game") end
    return IsAddOnLoaded and IsAddOnLoaded("Blizzard_UIPanels_Game")
end

-- Orchestrateur (appelé par Social:Start)
function Social:WireRosterUI()
    if isUIPanelsLoaded() then self:_WireFriendTooltip(); self:_WireGuildPanel(); return end
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(_, _, addonName)
        if addonName == "Blizzard_UIPanels_Game" then
            Social:_WireFriendTooltip(); Social:_WireGuildPanel()
            f:UnregisterEvent("ADDON_LOADED")
        end
    end)
end
