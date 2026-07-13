-- CraftingOrderClassic_UI_Artisans_Muted.lua — panel « En sourdine » de l'onglet Artisans.
-- Vue de GESTION des joueurs mis en sourdine (COC.db.mutedPlayers, cf. CraftingOrderClassic_Moderation) :
-- liste triée nom + raison + durée restante (permanent / 42min / expiré), un bouton « Rétablir » par
-- ligne (démute → COC.Moderation:Unmute). La donnée vient de Mod:MutedList, PAS du roster : un muté
-- n'est pas forcément un artisan connu. Affiché quand la source de la sidebar Artisans = « muted » —
-- le basculement (montrer/cacher pills+scroll artisans ↔ ce panel) est piloté par RefreshArtisans via
-- _ShowMutedMode. Vit dans le MÊME panel que la liste d'artisans ; chargé après UI_Artisans.lua.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local MRH = 40               -- hauteur d'une ligne mutée

-- Construit l'en-tête + la liste défilable, cachés par défaut. Appelé depuis BuildArtisansTab (APRÈS
-- les sections) : l'en-tête vit dans la bande « profFilter », la liste dans « artisansList » — le mode
-- muted SUPERPOSE ses widgets aux mêmes zones que la liste d'artisans (bascule via _ShowMutedMode).
function UI:_BuildMutedList()
    local band = self:ArtSec("profFilter")
    local hdr = band:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr:SetPoint("LEFT", 4, 0); Skin.ApplyShadow(hdr)
    hdr:SetText("|cFF888888" .. L["Joueurs en sourdine — aucune notification de leur part."] .. "|r")
    hdr:Hide(); self.mutedHdr = hdr

    local lz = self:ArtSec("artisansList")
    self.mutedW = self.artListW or (lz:GetWidth() - 6)   -- même largeur que la liste d'artisans
    local scroll = CreateFrame("ScrollFrame", "COCMutedScroll", lz, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 0, 0); scroll:SetPoint("BOTTOMLEFT", 0, 0); scroll:SetWidth(self.mutedW)
    local c = CreateFrame("Frame", nil, scroll); c:SetSize(self.mutedW, 10); scroll:SetScrollChild(c)
    scroll:Hide()
    self.mutedScroll = scroll; self.mutedContent = c; self.mutedRows = {}
end

-- Bascule l'affichage : vue « En sourdine » (on=true) ↔ liste d'artisans normale. Cache/montre les
-- pills de filtre métier + le scroll d'artisans d'un côté, l'en-tête + le scroll des mutés de l'autre.
function UI:_ShowMutedMode(on)
    if self.artPillHdr then self.artPillHdr:SetShown(not on) end
    for _, p in ipairs(self.artPills or {}) do p.btn:SetShown(not on) end
    if self.artScroll   then self.artScroll:SetShown(not on) end
    if self.mutedHdr    then self.mutedHdr:SetShown(on) end
    if self.mutedScroll then self.mutedScroll:SetShown(on) end
end

function UI:_MutedRow(i)
    local r = self.mutedRows[i]; if r then return r end
    local rw = self.mutedW or 560   -- largeur de la zone artisansList (lue au build)
    r = CreateFrame("Frame", nil, self.mutedContent)
    r:SetSize(rw, MRH); r:SetPoint("TOPLEFT", 0, -(i - 1) * MRH)
    local hi = r:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints(); hi:SetColorTexture(Skin.unpack(Skin.color.rowHover))
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    r.name:SetPoint("TOPLEFT", 8, -5); r.name:SetWidth(260); r.name:SetJustifyH("LEFT"); Skin.ApplyShadow(r.name)
    r.sub = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.sub:SetPoint("TOPLEFT", 8, -22); r.sub:SetWidth(rw - 130); r.sub:SetJustifyH("LEFT"); Skin.ApplyShadow(r.sub)
    r.unmute = Skin.MakeGoldButton(r, 96, 22, L["Rétablir"]); r.unmute:SetPoint("RIGHT", -8, 0)
    self.mutedRows[i] = r; return r
end

-- Remplit la liste depuis Mod:MutedList (déjà triée). « Rétablir » → démute + rafraîchit.
function UI:RefreshMuted()
    local Mod = COC.Moderation
    local list = (Mod and Mod.MutedList and Mod:MutedList()) or {}
    local n = 0
    for _, it in ipairs(list) do
        n = n + 1
        local row = self:_MutedRow(n)
        row.name:SetText("|cFFFFFFFF" .. it.name .. "|r")
        local reason = it.reason and ("  |cFF888888· " .. it.reason .. "|r") or ""
        local dur = (it.expired and "|cFFAA5555" or "|cFFE8B84B") .. it.durLabel .. "|r"
        row.sub:SetText(dur .. reason)
        row.unmute:SetScript("OnClick", function()
            if Mod and Mod.Unmute then Mod:Unmute(it.name) end   -- Unmute rappelle UI:Refresh → RefreshMuted
        end)
        row.unmute:Show()
        row:Show()
    end
    for i = n + 1, #self.mutedRows do self.mutedRows[i]:Hide() end
    self.mutedContent:SetHeight(math.max(n * MRH, 10))
    Skin.AutoHideScroll("COCMutedScroll", self.mutedContent)
    if n == 0 and self.mutedRows[1] then
        local row = self:_MutedRow(1)
        row.name:SetText("|cFF888888" .. L["Personne en sourdine."] .. "|r")
        row.sub:SetText("|cFF666666" .. L["Mets un joueur en sourdine par clic-droit sur sa carte ou /co mute <nom>."] .. "|r")
        row.unmute:Hide(); row:Show()
    end
end
