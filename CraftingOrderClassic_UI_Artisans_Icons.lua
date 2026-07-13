-- CraftingOrderClassic_UI_Artisans_Icons.lua — onglet « Artisans » : tout ce qui est ICÔNE de métier.
--   1. les pills de filtre métier (icône seule, plus de texte : 10 métiers tiennent sur une rangée) ;
--   2. les icônes de métier d'une ligne artisan : contour de rentabilité (Lazy Gold), tooltip, et
--      CLIC → onglet Commande pré-ciblé sur CET artisan et CE métier (UI:OpenPostForArtisan).
-- Extrait de _UI_Artisans.lua (plafond anti-monolithe).

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local ARI  = 22                  -- pas horizontal entre icônes de métier

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

-- =========================================================================
-- Pills de filtre métier — icône seule
-- =========================================================================
-- Un bouton-icône carré (kit MakeIconButton : liseré 1 px, icône désaturable, SetSelected = liseré
-- doré) portant l'icône du métier. Le libellé passe en tooltip : on récupère la largeur des 10 pills
-- texte (« Blacksmithing », « Leatherworking »… débordaient sur 2 rangées). On CHAÎNE les scripts de
-- survol éventuels sous garde nil (le kit n'en pose pas : surbrillance = couche HIGHLIGHT auto).
local function makeProfPill(panel, key)
    local b = Skin.MakeIconButton(panel, 24, Skin.ProfIcon(key) or Skin.tex.unknown)
    local hoverIn, hoverOut = b:GetScript("OnEnter"), b:GetScript("OnLeave")
    b:SetScript("OnEnter", function(self)
        if hoverIn then hoverIn(self) end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(Skin.ProfLabel(key), 1, 1, 1)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function(self) if hoverOut then hoverOut(self) end; GameTooltip:Hide() end)
    return b
end

-- Pills dans la BANDE « profFilter » de la SPEC (ancres LEFT → centrées verticalement). La bande fait
-- UNE rangée : si les pills venaient à déborder (jamais vu : 10 icônes ≈ 300 px pour ~600 utiles), le
-- repli les enroule sur une 2ᵉ ligne qui dépasserait sous la bande — élargir la fenêtre plutôt.
function UI:_BuildArtPills()
    local band = self:ArtSec("profFilter")
    local c = CL(); local profs = c and c:Professions() or {}
    local defs = { "Tous" }
    for _, p in ipairs(profs) do   -- primaires seulement : pas de pill Cuisine/Secours/Pêche
        if not (COC.SECONDARY_PROF and COC.SECONDARY_PROF[p]) then defs[#defs + 1] = p end
    end
    local x, y, rowH = 72, 0, 28   -- x départ : dégage le libellé « Métier : » en entier
    local bw = band:GetWidth(); local maxW = (bw > 1 and bw or 600) - 4
    for _, key in ipairs(defs) do
        local b, w
        if key == "Tous" then       -- « Tous » = sentinelle (pas un métier) → reste en texte
            b = Skin.MakeGoldButton(band, 10, 24, L["Tous"])
            w = b.text:GetStringWidth() + 16
        else
            b = makeProfPill(band, key)
            w = 24
        end
        b:SetWidth(w)
        if x + w > maxW then x = 0; y = y + rowH end
        b:SetPoint("LEFT", x, -y)
        b:SetScript("OnClick", function()
            -- NB : surtout pas l'idiome `cond and nil or key` (Lua : `true and nil or key` == key).
            if key == "Tous" then UI.artProfFilter = nil else UI.artProfFilter = key end
            UI:_RefreshArtPills(); UI:RefreshArtisans()
        end)
        self.artPills[#self.artPills + 1] = { btn = b, key = key }
        x = x + w + 4
    end
    self:_RefreshArtPills()
end

function UI:_RefreshArtPills()
    for _, p in ipairs(self.artPills or {}) do
        local active = (p.key == "Tous" and self.artProfFilter == nil) or (p.key == self.artProfFilter)
        p.btn:SetSelected(active)
        if p.btn.icon then p.btn.icon:SetDesaturated(not active and self.artProfFilter ~= nil) end
    end
end

-- =========================================================================
-- Icônes de métier d'une ligne artisan
-- =========================================================================
-- Mise en avant du métier RENTABLE : contour doré (+ halo au palier du haut) et icône EN COULEUR,
-- pendant que les métiers non rentables sont DÉSATURÉS. C'est le contraste qui porte l'information :
-- un coup d'œil sur la colonne suffit à repérer chez qui il y a de l'or à faire.
-- Le palier vient du meilleur plan RÉELLEMENT connu de cet artisan (LazyGold:BestKnownPlanFor, décodé
-- depuis son bitmask exact de recettes) ; si ce bitmask n'est pas disponible pour ce métier (fiche
-- relayée, jamais croisé en direct), on retombe sur l'approximation par NIVEAU (BestPlanFor) — moins
-- fiable : elle peut désigner une recette que l'artisan n'a pas apprise (PNJ/butin/quête à part),
-- même si son niveau de métier suffirait. Seuils : doré ≥ 10 po, doré + halo ≥ 1000 po (seuil de
-- base configurable, db.lgMinProfit). Lazy Gold absent → aucune désaturation.
-- `r` = fiche roster de l'artisan (nil si indisponible → on saute direct à l'approximation).
function UI:_SetArtProfitBorder(ic, item, r)
    local LG = COC.LazyGold
    if not (LG and ic.border) then return end
    local on = LG:IsAvailable()
    local plan = on and (LG:BestKnownPlanFor(item.key, r) or LG:BestPlanFor(item.key, item.sv and item.sv[1])) or nil
    local best = plan and plan.profit
    local tier = LG:HighlightTier(best)
    ic.tex:SetDesaturated(on and tier == 0)
    ic.tex:SetAlpha((on and tier == 0) and 0.55 or 1)
    if tier == 0 then
        ic.border:Hide(); if ic.glow then ic.glow:Hide() end
        ic.tipProfit = nil
        return
    end
    local c = LG.TIER_COLOR[tier]
    ic.border:SetTexCoord(unpack(LG.ALERT_BORDER))
    ic.border:SetVertexColor(c[1], c[2], c[3])
    ic.border:Show()
    if ic.glow then
        ic.glow:SetTexCoord(unpack(LG.ALERT_GLOW))
        ic.glow:SetVertexColor(c[1], c[2], c[3])
        ic.glow:SetShown(tier >= 3)   -- halo réservé au palier du haut
    end
    -- On NOMME le plan quand on le peut : « 599 po » ne dit pas quoi commander, « Iron Buckle — 599 po » si.
    local nm = LG:PlanName(item.key, plan)
    ic.tipProfit = L["Meilleur plan"] .. " : " .. (nm and (nm .. " — ") or "") .. GetCoinTextureString(best)
end

local function iconTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self.tipLabel or "", 1, 1, 1)
    if self.tipSub then GameTooltip:AddLine(self.tipSub, 0.910, 0.722, 0.294) end
    if self.tipProfit then GameTooltip:AddLine(self.tipProfit, 0.3, 0.9, 0.4) end
    for _, ln in ipairs(self.tipCds or {}) do   -- cooldowns : vert = prête, orange = en recharge
        if ln.ready then GameTooltip:AddLine(ln.text, 0.3, 0.9, 0.4)
        else GameTooltip:AddLine(ln.text, 1.0, 0.65, 0.2) end
    end
    if self.owner then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Clic : commander ce métier"], 0.6, 0.6, 0.6)
    end
    GameTooltip:Show()
end

-- Clic = raccourci « je veux lui commander ÇA » : bascule sur l'onglet Commande avec l'artisan
-- (owner = le PORTEUR du métier sur une ligne fusionnée, pas la vitrine) et le métier pré-ciblés.
local function iconClick(self)
    if self.owner and UI.OpenPostForArtisan then UI:OpenPostForArtisan(self.owner, self.profKey) end
end

local function newProfIcon(row)
    local ic = CreateFrame("Button", nil, row.profsFrame); ic:SetSize(18, 18)
    -- Halo (palier 3) DERRIÈRE l'icône, en additif : c'est un glow, pas un aplat.
    local glow = ic:CreateTexture(nil, "BACKGROUND")
    glow:SetTexture(COC.LazyGold and COC.LazyGold.ALERT_TEX)
    glow:SetPoint("CENTER"); glow:SetSize(30, 30); glow:SetBlendMode("ADD"); glow:Hide()
    ic.glow = glow
    local tex = ic:CreateTexture(nil, "ARTWORK"); tex:SetAllPoints()
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92); ic.tex = tex
    local hi = ic:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints()
    hi:SetColorTexture(1, 1, 1, 0.25)
    -- Contour de RENTABILITÉ par-dessus l'icône (teinté selon le palier).
    local bd = ic:CreateTexture(nil, "OVERLAY")
    bd:SetTexture(COC.LazyGold and COC.LazyGold.ALERT_TEX)
    bd:SetPoint("CENTER"); bd:SetSize(24, 24); bd:Hide()
    ic.border = bd
    ic:SetScript("OnEnter", iconTooltip)
    ic:SetScript("OnLeave", GameTooltip_Hide)
    ic:SetScript("OnClick", iconClick)
    return ic
end

-- `name` = artisan de la ligne (fallback) ; sur une ligne fusionnée, item.who nomme le vrai porteur.
function UI:_SetArtProfIcons(row, list, r, name)
    local pool = row.profIconPool
    for i, item in ipairs(list) do
        local ic = pool[i] or newProfIcon(row); pool[i] = ic
        ic:ClearAllPoints(); ic:SetPoint("LEFT", (i - 1) * ARI, 0)
        ic.tex:SetTexture(Skin.ProfIcon(item.key) or Skin.tex.unknown)
        ic.tipLabel = Skin.ProfLabel(item.key)
        ic.profKey  = item.key
        ic.owner    = item.who or name
        local rr = item.r or r                       -- fusion : rentabilité/CD viennent du PORTEUR, pas de la vitrine
        self:_SetArtProfitBorder(ic, item, rr)
        local sub = item.sv and ((item.sv[1] or "?") .. "/" .. (item.sv[2] or "?"))
            or (item.est ~= nil and ((item.est > 0) and string.format(L["%d+ · vu crafter"], item.est) or L["vu crafter (sans l'addon)"]))
            or nil
        if item.who then sub = (sub and (sub .. " — ") or "") .. item.who end   -- ligne fusionnée : PORTEUR du métier
        ic.tipSub = sub
        local So = COC.Social
        ic.tipCds = (rr and So and So.CooldownLines) and So:CooldownLines(rr, 3, item.key) or nil
        ic:Show()
    end
    for i = #list + 1, #pool do pool[i]:Hide() end
end
