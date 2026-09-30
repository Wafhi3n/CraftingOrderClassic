-- CraftingOrderClassic_UI_Artisans_Channels.lua — la section « Canaux surveillés » de l'onglet Artisans
-- (spec docs/specs/canaux-surveilles.md, palier 3).
--
-- Pourquoi (2026-09-30) : ce que l'addon surveille se réglait par cinq commandes que personne ne
-- connaît (/co scan, /co lfwchat, /co channel room, /co circle, /co crafters). Le joueur voit ici,
-- sous les filtres SOURCE, tous les canaux dont l'addon sait tirer quelque chose, et coche ceux où il
-- doit chercher des artisans.
--
-- Ce fichier ne fait QUE l'affichage : les lignes viennent de COC.Channels.BuildRows (pur, testé sans
-- le jeu), une case cochée passe par COC.Channels.SetWatched. Lui seul interroge le jeu : les canaux
-- où le joueur se trouve (GetChannelName rend le nom LONG, « Trade (Services) - English » ; mesuré
-- le 2026-09-30), sa guilde, ses communautés.
--
-- Hauteur : la liste prend ce qui reste entre le dernier bouton SOURCE et le bloc du bas, et DÉFILE
-- quand elle dépasse. Une zone de hauteur fixe aurait été recouverte par les bandes de cercles.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local ROW_H = 18

-- Les canaux du jeu où le joueur se trouve : { [clé] = nom nu tel que le jeu l'écrit }.
local function joinedChannels()
    local out, Ch = {}, COC.Channels
    if type(GetChannelName) ~= "function" then return out end
    for i = 1, 20 do
        local _, name = GetChannelName(i)
        if type(name) == "string" and not COC.Api.IsSecret(name) then
            local key = Ch.KeyOf(name)
            if key then out[key] = Ch.BaseName(name) end
        end
    end
    return out
end

-- Les communautés du joueur. En instance la liste est une valeur SECRÈTE, illisible : on garde la
-- dernière lue plutôt que de vider la section (« illisible » ne veut pas dire « aucune »).
local lastClubs = {}
local function myClubs()
    local D, out = COC.Directory, {}
    if not (D and D.EachClub) then return lastClubs end
    local _, readable = D:EachClub(function(info)
        out[#out + 1] = { id = tostring(info.clubId), name = tostring(info.name) }
    end)
    if readable == false then return lastClubs end
    lastClubs = out
    return out
end

local function showTip(row)
    local d = row.item
    local tip = d and (d.tip or (d.kind == "item" and not d.there
        and L["Tu n'es pas dans ce canal en ce moment. Ton choix est gardé pour ton retour."]))
    if not tip then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:AddLine(d.text or d.label, 1, 1, 1)
    GameTooltip:AddLine(tip, nil, nil, nil, true)
    GameTooltip:Show()
end

local function buildRow(row)
    row.check = Skin.MakeCheck(row, 14); row.check:SetPoint("LEFT", 2, 0)
    row.note = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.note:SetPoint("RIGHT", -2, 0)
    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.label:SetJustifyH("LEFT"); row.label:SetWordWrap(false)   -- un nom de communauté peut être long
    local hl = row:CreateTexture(nil, "HIGHLIGHT")               -- couche HIGHLIGHT : visible au survol seulement
    hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.06)
    row:SetScript("OnClick", function(self)
        local d = self.item
        if not (d and d.kind == "item") then return end
        COC.Channels.SetWatched(d.key, not COC.Channels.IsWatched(d.key))
        UI:RefreshArtisans()   -- une communauté cochée fait aussi naître sa bande SOURCE
    end)
    row:SetScript("OnEnter", showTip)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Une ligne du pool sert tour à tour à un en-tête, une case ou une note : tout est reposé ici.
local function fillRow(row, d)
    row.item = d
    local isItem = d.kind == "item"
    row.check:SetShown(isItem); row.check:SetChecked(isItem and d.on)
    row.note:SetText(d.note or "")
    row.label:ClearAllPoints()
    row.label:SetPoint("LEFT", (d.kind == "header") and 2 or 20, 0)   -- une note s'aligne sous les cases
    row.label:SetPoint("RIGHT", row.note, "LEFT", -4, 0)
    row.label:SetText(d.text or d.label or "")
    local c = (isItem and d.there) and Skin.color.text or Skin.color.textMuted
    row.label:SetTextColor(Skin.unpack(c))
end

function UI:_BuildArtChannels(sec)
    local hdr = sec:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hdr:SetText(L["CANAUX SURVEILLÉS"]); hdr:SetTextColor(Skin.unpack(Skin.color.textMuted))
    local host = CreateFrame("Frame", nil, sec)
    host:SetPoint("BOTTOMRIGHT", sec, "BOTTOMRIGHT", -10, 4)
    self.artChanHdr, self.artChanHost = hdr, host
    self.artChanList = Skin.MakeScrollList(host, { extent = ROW_H, build = buildRow, fill = fillRow })
end

-- Pose la section sous le dernier bouton SOURCE visible (`y` = le bas de la bande, relatif à la zone).
function UI:_PlaceArtChannels(y)
    if not self.artChanHost then return end
    self.artChanHdr:ClearAllPoints()
    self.artChanHdr:SetPoint("TOPLEFT", 14, y - 8)
    self.artChanHost:SetPoint("TOPLEFT", self:ArtSec("sources"), "TOPLEFT", 12, y - 24)
end

-- Les lignes, avec ce que le jeu dit à l'instant : canaux rejoints, guilde, communautés. Servi aussi
-- au panneau de première connexion (_UI_Setup.lua), qui montre les mêmes cases.
function UI:_ChannelRows()
    local inGuild = (IsInGuild and IsInGuild()) and true or false
    return COC.Channels.BuildRows(joinedChannels(), myClubs(), inGuild)
end

function UI:_RefreshArtChannels()
    if not self.artChanList then return end
    self.artChanList:SetData(self:_ChannelRows(), true)
end

-- `/co crafters on|off` recale sa case : elle vit désormais dans cette liste.
UI._SyncCrafterScanChk = UI._RefreshArtChannels

-- Le joueur entre dans une ville, rejoint un canal, une guilde ou une communauté : la liste suit.
local watcher = CreateFrame("Frame")
for _, ev in ipairs({ "CHANNEL_UI_UPDATE", "PLAYER_GUILD_UPDATE", "CLUB_ADDED", "CLUB_REMOVED" }) do
    pcall(watcher.RegisterEvent, watcher, ev)
end
watcher:SetScript("OnEvent", function()
    if UI.artisansPanel and UI.artisansPanel:IsShown() then UI:_RefreshArtChannels() end
end)
