-- CraftingOrderClassic_UI_Skin.lua — Thème « tavern doré » (design system Guild Economy / CraftLink).
-- Palette mappée 1:1 depuis tokens/colors.css (direction warm tavern). Skin PROPRE à cet addon
-- (pas de dépendance à Guild Economy). INTOUCHABLE : le langage couleur des offres et la rareté
-- d'objet ne sont jamais recolorés ; ce module ne touche que le chrome (surfaces, cadre, onglets).

CraftingOrderClassic.UI = CraftingOrderClassic.UI or {}
local Skin = {}
CraftingOrderClassic.UI.Skin = Skin
local L = CraftingOrderClassic.L

Skin.color = {
    panel     = { 0.082, 0.063, 0.043 },        -- #15100b fond fenêtre
    panel2    = { 0.114, 0.086, 0.063 },        -- #1d1610 panneau encastré
    stone     = { 0.141, 0.110, 0.078 },        -- #241c14 tablette d'onglet
    stoneHi   = { 0.204, 0.157, 0.110 },        -- #34281c hover onglet
    void      = { 0.039, 0.031, 0.024 },        -- #0a0806 puits profond
    gold      = { 0.910, 0.722, 0.294 },        -- #e8b84b or primaire
    goldHi    = { 0.941, 0.776, 0.455 },        -- #f0c674 or vif
    goldOre   = { 0.541, 0.392, 0.125 },        -- #8a6420 métal sombre
    price     = { 1.000, 0.867, 0.000 },        -- #ffdd00 prix
    border    = { 0.353, 0.290, 0.180 },        -- #5a4a2e cadre
    separator = { 0.353, 0.290, 0.180 },
    text      = { 0.910, 0.863, 0.784 },        -- #e8dcc8 crème
    textMuted = { 0.550, 0.550, 0.550 },
    tabActive = { 0.149, 0.349, 0.651 },        -- #2659A6 onglet actif (bleu)
    wts       = { 0.20,  0.87,  0.20 },         -- vert (statut open)
    rowHover  = { 0.25,  0.45,  0.85,  0.25 },
}

Skin.hex = { gold="FFE8B84B", goldHi="FFF0C674", price="FFFFDD00", muted="FF8C8C8C", green="FF33DD33" }

local function unpackc(c) return c[1], c[2], c[3], c[4] or 1 end
Skin.unpack = unpackc

-- Localisation des métiers (clé interne EN du catalogue → libellé FR). Fallback = la clé.
-- TODO multilingue : dériver du nom de ligne de compétence localisé selon le client.
Skin.profFR = {
    Alchemy="Alchimie", Blacksmithing="Forge", Cooking="Cuisine", Enchanting="Enchantement",
    Engineering="Ingénierie", ["First Aid"]="Secourisme", Fishing="Pêche", Herbalism="Herboristerie",
    Leatherworking="Travail du cuir", Mining="Minage", Poisons="Poisons", Skinning="Dépeçage",
    Tailoring="Couture", Jewelcrafting="Joaillerie", Inscription="Calligraphie",
    Elemental="Élémentaire",
}
function Skin.ProfLabel(p) return p and L[Skin.profFR[p] or p] or "—" end

-- Spell IDs d'apprenti pour récupérer l'icône de métier via GetSpellTexture (cache client stable).
Skin.profSpellID = {
    Alchemy        = 2259,  Blacksmithing  = 2018,  Enchanting    = 7411,
    Engineering    = 4036,  Herbalism      = 2383,  Jewelcrafting = 25229,
    Leatherworking = 2108,  Mining         = 2575,  Skinning      = 8613,
    Tailoring      = 3908,  Cooking        = 2550,  ["First Aid"] = 3273,
    Fishing        = 7620,  Inscription    = 45357,
}
function Skin.ProfIcon(key)
    if not key then return nil end
    local sid = Skin.profSpellID[key]
    if sid and GetSpellTexture then local t = GetSpellTexture(sid); if t then return t end end
    if key == "Elemental" then return "Interface\\Icons\\Spell_Fire_FlameBolt" end
    return nil
end

-- Statut d'ordre → libellé FR + couleur hex.
Skin.statusFR = {
    open      = { "En attente", "FFFFCC00" },
    accepted  = { "Acceptée",   "FF33CCFF" },
    done      = { "Livrée",     "FF33DD33" },
    cancelled = { "Annulée",    "FF888888" },
}
function Skin.StatusInfo(s) local t = Skin.statusFR[s or "open"] or Skin.statusFR.open; return L[t[1]], t[2] end

-- Couleur de rareté d'un objet {r,g,b} (or par défaut : services/enchants, ou nom non encore en cache).
function Skin.RarityColor(itemID)
    if itemID and GetItemInfo then
        local q = select(3, GetItemInfo(itemID))
        if q and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q] then
            local c = ITEM_QUALITY_COLORS[q]; return c.r, c.g, c.b
        end
    end
    return unpackc(Skin.color.gold)
end

-- Premier caractère (UTF-8) en capitale — pour le badge de rareté.
function Skin.FirstChar(s)
    if not s or s == "" then return "?" end
    local b = s:byte(1)
    local len = (b < 0x80 and 1) or (b < 0xE0 and 2) or (b < 0xF0 and 3) or 4
    return s:sub(1, len):upper()
end

-- L'objet existe-t-il dans la base du CLIENT courant ? GetItemInfoInstant lit la DB statique et
-- renvoie nil pour un objet d'une autre extension (ex. minerai TBC sur un client Era) → filtrage
-- propre par version, sans re-générer les données (sur un client TBC, l'objet apparaîtra).
function Skin.ItemExists(itemID)
    if not itemID then return true end
    if GetItemInfoInstant then return GetItemInfoInstant(itemID) ~= nil end
    return true   -- API absente : on ne filtre pas
end

-- Icône native d'un objet/sort (texture du client — aucun asset à fournir). nil si introuvable.
function Skin.Icon(itemID, spellID)
    if itemID and GetItemIcon then local t = GetItemIcon(itemID); if t then return t end end
    if itemID and GetItemInfo then local t = select(10, GetItemInfo(itemID)); if t then return t end end
    if spellID and GetSpellTexture then local t = GetSpellTexture(spellID); if t then return t end end
    return nil
end

-- Badge carré : icône native de l'objet (bordure colorée par rareté), avec repli sur une lettre.
-- Paint(r, g, b, char, tex) — tex = texture d'icône (Skin.Icon), ou nil → lettre.
function Skin.MakeBadge(parent, size)
    size = size or 18
    local b = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    b:SetSize(size, size)
    b:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 1, -1); icon:SetPoint("BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)   -- rogne la bordure native de l'icône
    icon:Hide(); b.icon = icon
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("CENTER"); Skin.ApplyShadow(fs); b.letter = fs
    b.Paint = function(self, r, g, bl, ch, tex)
        self:SetBackdropBorderColor(r, g, bl, 1)
        if tex then
            self.icon:SetTexture(tex); self.icon:Show()
            self.letter:SetText(""); self:SetBackdropColor(0, 0, 0, 1)
        else
            self.icon:Hide()
            self:SetBackdropColor(r * 0.30, g * 0.30, bl * 0.30, 1)
            self.letter:SetTextColor(r, g, bl); self.letter:SetText(ch)
        end
        self:Show()
    end
    return b
end

-- =========================================================================
-- Icônes natives Blizzard (chemins in-game — AUCUN asset à livrer, le client les a déjà).
-- =========================================================================
Skin.tex = {
    gold    = "Interface\\MoneyFrame\\UI-GoldIcon",
    silver  = "Interface\\MoneyFrame\\UI-SilverIcon",
    copper  = "Interface\\MoneyFrame\\UI-CopperIcon",
    online  = "Interface\\FriendsFrame\\StatusIcon-Online",
    offline = "Interface\\FriendsFrame\\StatusIcon-Offline",
    away    = "Interface\\FriendsFrame\\StatusIcon-Away",
    dnd     = "Interface\\FriendsFrame\\StatusIcon-DnD",
    broadcast = "Interface\\FriendsFrame\\BroadcastIcon",
    workorder = "Interface\\GossipFrame\\WorkOrderGossipIcon",
    crate     = "Interface\\Icons\\INV_Crate_03",   -- récolte « par stack »
}

-- Pastille de présence : texture statut du jeu, avec méthode SetOnline(bool/nil). nil = masquée.
function Skin.MakeStatusIcon(parent, size)
    size = size or 14
    local t = parent:CreateTexture(nil, "OVERLAY")
    t:SetSize(size, size)
    t.SetOnline = function(self, state)
        if state == nil then self:Hide(); return end
        self:SetTexture(state and Skin.tex.online or Skin.tex.offline)
        self:Show()
    end
    return t
end

-- Icône de monnaie (kind = "gold"/"silver"/"copper"), placée à droite d'un champ de saisie.
function Skin.MoneyIcon(parent, kind, anchorTo)
    local t = parent:CreateTexture(nil, "OVERLAY")
    t:SetSize(13, 13); t:SetTexture(Skin.tex[kind])
    if anchorTo then t:SetPoint("LEFT", anchorTo, "RIGHT", 2, 0) end
    return t
end

-- Masque la scrollbar (et ses boutons haut/bas) d'un UIPanelScrollFrameTemplate quand le contenu
-- tient sans défilement → évite les « carrés » flottants qui débordaient sur la bordure dorée.
function Skin.AutoHideScroll(scrollName, content)
    local scroll, sb = _G[scrollName], _G[scrollName .. "ScrollBar"]
    if not (scroll and content) then return end
    local show = (content:GetHeight() or 0) > (scroll:GetHeight() or 0) + 1
    if sb then sb:SetShown(show) end
    -- Certains templates WoW placent les boutons haut/bas en dehors du ScrollBar (frères, pas enfants).
    for _, sfx in ipairs({ "ScrollBarScrollUpButton", "ScrollBarScrollDownButton",
                            "ScrollUpButton",          "ScrollDownButton" }) do
        local btn = _G[scrollName .. sfx]
        if btn then btn:SetShown(show) end
    end
end

function Skin.ApplyShadow(fs)
    if fs and fs.SetShadowColor then fs:SetShadowColor(0, 0, 0, 0.95); fs:SetShadowOffset(1, -1) end
    return fs
end

local wordmarkFont
function Skin.WordmarkFont()
    if not wordmarkFont then
        wordmarkFont = CreateFont("CraftingOrderWordmarkFont")
        if not wordmarkFont:SetFont("Fonts\\MORPHEUS.ttf", 22, "") then
            wordmarkFont:SetFontObject("GameFontNormalLarge")
        end
        wordmarkFont:SetTextColor(unpackc(Skin.color.goldHi))
        wordmarkFont:SetShadowColor(0, 0, 0, 1); wordmarkFont:SetShadowOffset(1, -1)
    end
    return wordmarkFont
end

function Skin.SkinFrameBackdrop(f)
    if not f.SetBackdrop then Mixin(f, BackdropTemplateMixin) end
    f:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 16, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:SetBackdropColor(Skin.color.panel[1], Skin.color.panel[2], Skin.color.panel[3], 1)
    f:SetBackdropBorderColor(1, 1, 1, 1)
end

function Skin.SkinWell(f)
    if not f.SetBackdrop then Mixin(f, BackdropTemplateMixin) end
    f:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(Skin.color.void[1], Skin.color.void[2], Skin.color.void[3], 0.85)
    f:SetBackdropBorderColor(Skin.color.goldOre[1], Skin.color.goldOre[2], Skin.color.goldOre[3], 0.7)
end

function Skin.MakeSeparator(parent, offsetY)
    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetColorTexture(Skin.color.separator[1], Skin.color.separator[2], Skin.color.separator[3], 0.7)
    sep:SetPoint("TOPLEFT", 4, offsetY); sep:SetPoint("TOPRIGHT", -4, offsetY)
    return sep
end

-- Bouton or « maison » (échappe aux re-skins externes rouges). Expose SetText/SetSelected.
function Skin.MakeGoldButton(parent, w, h, text)
    local small = (h <= 16)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(w, h)
    b:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    local fs = b:CreateFontString(nil, "OVERLAY", small and "GameFontNormalSmall" or "GameFontNormal")
    fs:SetPoint("CENTER"); Skin.ApplyShadow(fs)
    if text then fs:SetText(text) end
    b.text = fs
    b.selected = false
    b.SetText = function(self, t) self.text:SetText(t) end
    b.GetFontString = function(self) return self.text end
    local function rest(self)
        if self.selected then
            self:SetBackdropColor(unpackc(Skin.color.stoneHi))
            self:SetBackdropBorderColor(unpackc(Skin.color.goldHi))
            self.text:SetTextColor(unpackc(Skin.color.goldHi))
        else
            self:SetBackdropColor(unpackc(Skin.color.stone))
            self:SetBackdropBorderColor(unpackc(Skin.color.border))
            self.text:SetTextColor(unpackc(Skin.color.gold))
        end
    end
    b.SetSelected = function(self, on) self.selected = on; rest(self) end
    b:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpackc(Skin.color.stoneHi))
        self:SetBackdropBorderColor(unpackc(Skin.color.goldHi))
        self.text:SetTextColor(unpackc(Skin.color.goldHi))
    end)
    b:SetScript("OnLeave", rest)
    b:SetScript("OnMouseDown", function(self) self:SetBackdropColor(unpackc(Skin.color.void)) end)
    b:SetScript("OnMouseUp", rest)
    rest(b)
    return b
end
