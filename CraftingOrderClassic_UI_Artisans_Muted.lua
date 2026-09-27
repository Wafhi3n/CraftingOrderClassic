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

    -- La liste défilante du kit (palier 2b), SUPERPOSÉE à celle des artisans dans la même zone et
    -- cachée par défaut (bascule : _ShowMutedMode). Elle dit « personne en sourdine » d'elle-même.
    local lz = self:ArtSec("artisansList")
    local host = CreateFrame("Frame", nil, lz)
    host:SetPoint("TOPLEFT", 0, 0); host:SetPoint("BOTTOMRIGHT", 0, 0); host:Hide()
    self.mutedScroll = host
    self.mutedList = Skin.MakeScrollList(host, {
        extent = MRH,
        build  = function(row) UI:_BuildMutedRow(row) end,
        fill   = function(row, it) UI:_FillMutedRow(row, it) end,
        -- Saut de ligne par string.char(10) : un antislash écrit dans le source peut arriver
        -- transformé en VRAI retour à la ligne, qui coupe la chaîne (vécu en écrivant ces lignes).
        empty  = "|cFF888888" .. L["Personne en sourdine."] .. "|r" .. string.char(10) .. "|cFF666666"
                 .. L["Mets un joueur en sourdine par clic-droit sur sa carte ou /co mute <nom>."] .. "|r",
    })
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

-- Construit une ligne de sourdine, la première fois que la liste défilante crée ce cadre. La
-- sous-ligne (durée + raison) s'ancre contre « Rétablir » au lieu d'une largeur tirée de la zone.
function UI:_BuildMutedRow(r)
    Skin.ListRowArt(r); Skin.ListRowKind(r, "item")   -- survol des listes des métiers
    r.unmute = Skin.MakeGoldButton(r, 96, 22, L["Rétablir"]); r.unmute:SetPoint("RIGHT", -8, 0)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    r.name:SetPoint("TOPLEFT", 8, -5); r.name:SetWidth(260); r.name:SetJustifyH("LEFT"); Skin.ApplyShadow(r.name)
    r.sub = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.sub:SetPoint("TOPLEFT", 8, -22); r.sub:SetPoint("RIGHT", r.unmute, "LEFT", -8, 0)
    r.sub:SetJustifyH("LEFT"); r.sub:SetWordWrap(false); Skin.ApplyShadow(r.sub)
    -- « Rétablir » démute le joueur que la ligne porte À CE MOMENT (la même ligne en sert d'autres).
    r.unmute:SetScript("OnClick", function(b)
        local Mod, name = COC.Moderation, b:GetParent().mutedName
        if name and Mod and Mod.Unmute then Mod:Unmute(name) end   -- Unmute rappelle UI:Refresh → RefreshMuted
    end)
end

-- Une ligne pour `it` = { name, reason, durLabel, expired } (format Mod:MutedList).
function UI:_FillMutedRow(row, it)
    row.mutedName = it.name
    row.name:SetText("|cFFFFFFFF" .. it.name .. "|r")
    local reason = it.reason and ("  |cFF888888· " .. it.reason .. "|r") or ""
    local dur = (it.expired and "|cFFAA5555" or "|cFFE8B84B") .. it.durLabel .. "|r"
    row.sub:SetText(dur .. reason)
end

-- Remplit la liste depuis Mod:MutedList (déjà triée).
function UI:RefreshMuted()
    local Mod = COC.Moderation
    local list = (Mod and Mod.MutedList and Mod:MutedList()) or {}
    if self.mutedList then self.mutedList:SetData(list, true) end
end
