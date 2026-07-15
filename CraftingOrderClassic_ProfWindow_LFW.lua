-- CraftingOrderClassic_ProfWindow_LFW.lua — config de l'OFFRE « recherche de travail » par métier.
-- Engrenage à droite du bouton « Chercher du travail » (en-tête fenêtre métier) → panneau flyout :
-- compos de base, restriction « si progression », commission fixe (or/argent/cuivre), et picker
-- cherchable des composants fournis (univers = UNION des réactifs des recettes CraftLink du métier,
-- filtré par version client via Skin.ItemExists). Save-on-change → Dir:SetLFWOffer (persiste +
-- re-diffusion LFO débouncée). Éditable même LFW éteint : la config part au prochain SetLFW.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L
local PW   = COC.ProfWindow

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

local PANEL_W, PANEL_H = 330, 430
-- Pool ≥ viewport (invariant liste virtualisée) : zone liste ≈ 236 px / 20 ≈ 12 lignes → 16 = marge.
local ROW_H, VISIBLE   = 20, 16
local LIST_TOP         = 184     -- y du haut de la liste (sous en-tête picker + recherche)

local function maxItems() return (COC.Directory and COC.Directory.OFFER_MAX_ITEMS) or 15 end

-- ------------------------------------------------------------------
-- Engrenage d'en-tête (appelé par PW:_BuildHeader ; visibilité gérée par PW:_SyncLFWBtn)
-- ------------------------------------------------------------------
-- Gear_64 : texture VÉRIFIÉE en Era (le bouton d'options de prix de l'HdV Classic l'utilise).
function PW:_BuildLFWGear(f, lfwBtn)
    local b = Skin.MakeIconButton(f, 18, "Interface\\WorldMap\\Gear_64")
    b:SetPoint("LEFT", lfwBtn, "RIGHT", 4, 0)
    b:SetScript("OnClick", function() PW:ToggleLFWConfig() end)
    b:SetScript("OnEnter", function(s)
        GameTooltip:SetOwner(s, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText(L["Configurer l'offre : composants fournis, commission…"], 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    b:Hide()
    self.lfwCfgBtn = b
end

-- Suit l'état du bouton LFW (même portée : vue pleine d'un métier À MOI). Panneau ouvert : il se
-- ferme si la portée disparaît, il se REPEINT si on a changé de métier (la config est par métier).
function PW:_SyncLFWConfig(show)
    local b = self.lfwCfgBtn; if not b then return end
    b:SetShown(show and true or false)
    local p = self.lfwPanel
    if p and p:IsShown() then
        if show then self:_RefreshLFWPanel() else p:Hide() end
    end
end

-- Ouvre/ferme le panneau pour le métier OUVERT (mien). Liseré doré de l'engrenage = panneau ouvert.
function PW:ToggleLFWConfig()
    if not self.profKey or self.rerollKey then return end
    local p = self:_BuildLFWPanel()
    if p:IsShown() then p:Hide() else self:_RefreshLFWPanel(); p:Show() end
    if self.lfwCfgBtn then self.lfwCfgBtn:SetSelected(p:IsShown()) end
end

-- ------------------------------------------------------------------
-- Panneau (construit à la demande, un seul exemplaire)
-- ------------------------------------------------------------------
function PW:_BuildLFWPanel()
    if self.lfwPanel then return self.lfwPanel end
    local p = CreateFrame("Frame", "CraftingOrderLFWConfig", self.frame, "BackdropTemplate")
    p:SetSize(PANEL_W, PANEL_H)
    p:SetPoint("TOPLEFT", self.frame, "TOPRIGHT", -4, -28)
    p:SetFrameStrata("HIGH"); p:SetToplevel(true)
    Skin.SkinWell(p)
    p.title = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    p.title:SetPoint("TOPLEFT", 12, -10); p.title:SetPoint("RIGHT", -30, 0)
    p.title:SetJustifyH("LEFT"); p.title:SetWordWrap(false)
    local x = CreateFrame("Button", nil, p, "UIPanelCloseButton")
    x:SetSize(24, 24); x:SetPoint("TOPRIGHT", -2, -2)
    p:SetScript("OnHide", function() if PW.lfwCfgBtn then PW.lfwCfgBtn:SetSelected(false) end end)
    self:_BuildLFWChecks(p)
    self:_BuildLFWPicker(p)
    -- Noms d'objets ASYNC (GetItemInfo nil au 1er passage) → re-rendu débouncé quand le client les reçoit.
    p:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    p:SetScript("OnEvent", function()
        if p:IsShown() and not p._nameTick and C_Timer then
            p._nameTick = true
            C_Timer.After(0.3, function() p._nameTick = nil; if p:IsShown() then PW:_RefreshLFWList() end end)
        end
    end)
    self.lfwPanel = p
    return p
end

-- Moitié haute : les deux déclarations + la commission. Chaque contrôle SAUVE immédiatement
-- (_EditLFWOffer) ; _filling coupe les handlers pendant que _RefreshLFWPanel repose les valeurs.
function PW:_BuildLFWChecks(p)
    local basics = Skin.MakeCheckButton(p, L["Je fournis les composants de base"])
    basics:SetPoint("TOPLEFT", 8, -30)
    basics:SetScript("OnClick", function(b)
        if not p._filling then PW:_EditLFWOffer(function(o) o.basics = b:GetChecked() and true or nil end) end
    end)
    p.basics = basics
    local h1 = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    h1:SetPoint("TOPLEFT", 34, -52); h1:SetText(L["(achetables chez un marchand)"])

    local sup = Skin.MakeCheckButton(p, L["Seulement si le plan me fait progresser"])
    sup:SetPoint("TOPLEFT", 8, -68)
    sup:SetScript("OnClick", function(b)
        if not p._filling then PW:_EditLFWOffer(function(o) o.skillUpOnly = b:GetChecked() and true or nil end) end
    end)
    p.skillUp = sup
    local h2 = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    h2:SetPoint("TOPLEFT", 34, -90); h2:SetText(L["(restriction sur les composants fournis)"])

    local lab = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lab:SetPoint("TOPLEFT", 12, -112); lab:SetText(L["Commission fixe par craft :"])
    local g, s, c = Skin.MakeMoneyRow(p, 20, -130)
    p.gold, p.silver, p.copper = g, s, c
    local function onFee()
        if p._filling then return end
        local fee = (tonumber(p.gold:GetText()) or 0) * 10000
                  + (tonumber(p.silver:GetText()) or 0) * 100
                  + (tonumber(p.copper:GetText()) or 0)
        PW:_EditLFWOffer(function(o) o.fee = (fee > 0) and fee or nil end)
    end
    for _, eb in ipairs({ g, s, c }) do eb:SetScript("OnTextChanged", onFee) end
end

-- Moitié basse : le picker des composants fournis (en-tête compteur, recherche, liste virtualisée).
function PW:_BuildLFWPicker(p)
    Skin.MakeSeparator(p, -(LIST_TOP - 30))
    p.pickHdr = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    p.pickHdr:SetPoint("TOPLEFT", 12, -(LIST_TOP - 24))
    local search = CreateFrame("EditBox", nil, p, "InputBoxTemplate")
    search:SetHeight(16); search:SetPoint("TOPLEFT", 16, -(LIST_TOP - 2)); search:SetPoint("RIGHT", -12, 0)
    search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", function() if not p._filling then PW:_RefreshLFWList() end end)
    search:SetScript("OnEscapePressed", function(b) b:SetText(""); b:ClearFocus() end)
    p.search = search

    local scroll = CreateFrame("ScrollFrame", "CraftingOrderLFWCfgScroll", p, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -(LIST_TOP + 20)); scroll:SetPoint("BOTTOMRIGHT", -28, 10)
    Skin.ScrollTrack("CraftingOrderLFWCfgScroll")
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(PANEL_W - 36, VISIBLE * ROW_H); scroll:SetScrollChild(content)
    scroll:HookScript("OnVerticalScroll", function() PW:_RenderLFWList() end)
    p.scroll, p.content = scroll, content
    p.rows = {}
    for i = 1, VISIBLE do p.rows[i] = self:_BuildLFWRow(content, i) end
end

function PW:_BuildLFWRow(parent, i)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(PANEL_W - 36, ROW_H); row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
    local hi = row:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints(); hi:SetColorTexture(0.25, 0.45, 0.85, 0.25)
    row.check = Skin.MakeCheck(row, 14); row.check:SetPoint("LEFT", 2, 0)
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ROW_H - 4, ROW_H - 4); icon:SetPoint("LEFT", 20, 0); icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.icon = icon
    local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    name:SetPoint("LEFT", icon, "RIGHT", 4, 0); name:SetPoint("RIGHT", -2, 0)
    name:SetJustifyH("LEFT"); name:SetWordWrap(false); row.name = name
    row:SetScript("OnClick", function(r)
        if not r.itemID then return end
        -- Shift-clic → lien chat, SANS cocher (cet OnClick MUTE l'offre : ne pas déclencher les deux).
        if IsModifiedClick("CHATLINK") then HandleModifiedItemClick(Skin.ChatLinkFor(nil, r.itemID, nil)); return end
        PW:_ToggleLFWItem(r.itemID)
    end)
    row:SetScript("OnEnter", function(r)
        if not r.itemID then return end
        GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
        if not pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. r.itemID) then
            GameTooltip:SetText(r.name:GetText() or "?", 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:Hide(); return row
end

-- ------------------------------------------------------------------
-- Données du picker
-- ------------------------------------------------------------------
-- Univers d'un métier : UNION des réactifs de toutes ses recettes (catalogue CraftLink), filtrée par
-- existence côté client (données multi-flavor : un réactif TBC n'apparaît pas sur un client Era).
-- Mémorisé par métier (session) — les IDs ne bougent pas, seuls les NOMS se résolvent async.
function PW:_LFWUniverse(profKey)
    self._lfwUniv = self._lfwUniv or {}
    if self._lfwUniv[profKey] then return self._lfwUniv[profKey] end
    local c = CL()
    local def = c and c.GetProfession and c:GetProfession(profKey)
    local seen, out = {}, {}
    for _, list in pairs((def and def.reagents) or {}) do
        for _, rg in ipairs(list) do
            local id = rg[1]
            if id and not seen[id] and Skin.ItemExists(id) then seen[id] = true; out[#out + 1] = id end
        end
    end
    self._lfwUniv[profKey] = out
    return out
end

-- Liste d'affichage : filtre de recherche + tri par nom localisé (résolution paresseuse → l'ordre
-- s'affine au fil des GET_ITEM_INFO_RECEIVED, re-rendu débouncé par le panneau).
function PW:_LFWDisplayList()
    local p, c = self.lfwPanel, CL()
    local search = (p.search:GetText() or ""):lower()
    local out = {}
    for _, id in ipairs(self:_LFWUniverse(self.profKey)) do
        local name = (c and c:ItemName(id)) or ("item:" .. id)
        if search == "" or name:lower():find(search, 1, true) then
            out[#out + 1] = { id = id, name = name }
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

-- ------------------------------------------------------------------
-- Édition (save-on-change)
-- ------------------------------------------------------------------
-- Lit MA config du métier ouvert, applique fn(o), normalise (offre vide → nil) et sauve :
-- Dir:SetLFWOffer persiste ET re-diffuse (débouncé) si le LFW de ce métier est actif.
function PW:_EditLFWOffer(fn)
    local D = COC.Directory
    if not (D and D.SetLFWOffer and self.profKey) then return end
    local o = D:MyLFWOffer(self.profKey) or {}
    fn(o)
    if not (o.basics or o.skillUpOnly or (o.fee and o.fee > 0)
            or (o.items and #o.items > 0) or (o.recipes and #o.recipes > 0)) then o = nil end
    D:SetLFWOffer(self.profKey, o)
    self:_RefreshLFWList()
end

-- Coche/décoche un composant fourni. Au-delà du cap (limite de la ligne réseau), on refuse avec un toast.
function PW:_ToggleLFWItem(itemID)
    local D = COC.Directory
    local o = (D and D:MyLFWOffer(self.profKey)) or {}
    for i, v in ipairs(o.items or {}) do
        if v == itemID then
            self:_EditLFWOffer(function(oo) table.remove(oo.items, i); if #oo.items == 0 then oo.items = nil end end)
            return
        end
    end
    if #(o.items or {}) >= maxItems() then
        if UI.Toast then UI:Toast(string.format(L["Maximum %d composants fournis."], maxItems())) end
        return
    end
    self:_EditLFWOffer(function(oo) oo.items = oo.items or {}; oo.items[#oo.items + 1] = itemID end)
end

-- Coche/décoche une RECETTE proposée (colonne de cases de la liste, cf. ProfWindow_Recipes). Clé = spellID
-- de la recette (résolu en nom par GetSpellInfo chez le récepteur). Au-delà du cap (ligne réseau LFR), on
-- refuse avec un toast. Repeint la liste de recettes pour refléter la case. No-op hors mon métier / en reroll.
function PW:_ToggleLFWRecipe(entry)
    local sid = entry and entry.spellID
    if not (sid and self.profKey) or self.rerollKey then return end
    local D = COC.Directory
    local cap = (D and D.OFFER_MAX_RECIPES) or 12
    local o = (D and D:MyLFWOffer(self.profKey)) or {}
    for i, v in ipairs(o.recipes or {}) do
        if v == sid then
            self:_EditLFWOffer(function(oo) table.remove(oo.recipes, i); if #oo.recipes == 0 then oo.recipes = nil end end)
            if self.RefreshRecipes then self:RefreshRecipes() end
            return
        end
    end
    if #(o.recipes or {}) >= cap then
        if UI.Toast then UI:Toast(string.format(L["Maximum %d recettes proposées."], cap)) end
        return
    end
    self:_EditLFWOffer(function(oo) oo.recipes = oo.recipes or {}; oo.recipes[#oo.recipes + 1] = sid end)
    if self.RefreshRecipes then self:RefreshRecipes() end
end

-- ------------------------------------------------------------------
-- Rendu
-- ------------------------------------------------------------------
-- Repose TOUTES les valeurs (titre du métier, coches, commission) puis la liste. _filling coupe les
-- handlers OnClick/OnTextChanged le temps du remplissage (sinon SetText re-déclencherait une sauvegarde).
function PW:_RefreshLFWPanel()
    local p = self.lfwPanel; if not (p and self.profKey) then return end
    local D = COC.Directory
    local o = (D and D:MyLFWOffer(self.profKey)) or {}
    p._filling = true
    p.title:SetText(string.format(L["Recherche de travail — %s"], Skin.ProfLabel(self.profKey) or self.profKey))
    p.basics:SetChecked(o.basics and true or false)
    p.skillUp:SetChecked(o.skillUpOnly and true or false)
    local fee = o.fee or 0
    p.gold:SetText(tostring(math.floor(fee / 10000)))
    p.silver:SetText(tostring(math.floor((fee % 10000) / 100)))
    p.copper:SetText(tostring(fee % 100))
    p._filling = nil
    self:_RefreshLFWList()
end

function PW:_RefreshLFWList()
    local p = self.lfwPanel; if not (p and p.scroll and self.profKey) then return end
    local D = COC.Directory
    local o = (D and D:MyLFWOffer(self.profKey)) or {}
    self._lfwProvided = {}
    for _, id in ipairs(o.items or {}) do self._lfwProvided[id] = true end
    p.pickHdr:SetText("|cFFE8B84B" .. string.format(L["Composants fournis (%d/%d)"], #(o.items or {}), maxItems()) .. "|r")
    self._lfwDisplay = self:_LFWDisplayList()
    local n = #self._lfwDisplay
    p.content:SetHeight(math.max(n * ROW_H, VISIBLE * ROW_H))
    local maxScroll = math.max(0, n * ROW_H - (p.scroll:GetHeight() or 0))
    if (p.scroll:GetVerticalScroll() or 0) > maxScroll then p.scroll:SetVerticalScroll(maxScroll) end
    self:_RenderLFWList()
end

function PW:_RenderLFWList()
    local p = self.lfwPanel
    local list = self._lfwDisplay or {}
    local off = math.floor((p.scroll:GetVerticalScroll() or 0) / ROW_H)
    for i = 1, #p.rows do
        local row, e = p.rows[i], list[off + i]
        if e then
            row.itemID = e.id
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, -(off + i - 1) * ROW_H)
            row.check:SetChecked(self._lfwProvided and self._lfwProvided[e.id] or false)
            local tex = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(e.id)
            row.icon:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.name:SetText(e.name)
            row:Show()
        else
            row.itemID = nil; row:Hide()
        end
    end
end
