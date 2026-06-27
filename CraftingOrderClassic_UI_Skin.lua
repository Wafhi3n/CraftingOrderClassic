-- CraftingOrderClassic_UI_Skin.lua — Thème « tavern doré » (design system Guild Economy / CraftLink).
-- Palette mappée 1:1 depuis tokens/colors.css (direction warm tavern). Skin PROPRE à cet addon
-- (pas de dépendance à Guild Economy). INTOUCHABLE : le langage couleur des offres et la rareté
-- d'objet ne sont jamais recolorés ; ce module ne touche que le chrome (surfaces, cadre, onglets).

CraftingOrderClassic.UI = CraftingOrderClassic.UI or {}
local Skin = {}
CraftingOrderClassic.UI.Skin = Skin

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
