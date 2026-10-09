-- CraftingOrderClassic_Report.lua — « Signaler » : un bug ou une idée, en ticket sur le dépôt GitHub.
--
-- Un addon n'ouvre pas de navigateur : la fenêtre donne un LIEN, déjà sélectionné, que le joueur copie
-- (Ctrl+C) et colle dans son navigateur, où le formulaire du dépôt arrive pré-rempli. Même montage
-- que `/ley contribute` (LeyLines_Share.lua), vu en jeu le 2026-09-28.
-- Formulaires : .github/ISSUE_TEMPLATE/bug.yml et suggestion.yml. DEUX formulaires et pas un seul
-- avec une liste « type » : une liste déroulante passée dans le lien ne se pré-remplit pas (mesuré
-- le 2026-09-28) ; seules les zones de texte le font, d'où le champ `env`. Il porte la version de
-- l'addon et du jeu, la langue — JAMAIS le nom du personnage, son royaume ou sa guilde : le ticket
-- est public. Sans compte GitHub, le troisième choix donne la page CurseForge.
-- Spec : docs/specs/signaler.md (dépôt de l'outillage). Pur et testable : Env, URL (test_signaler).
local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local Report = {}
COC.Report = Report

local ADDON = "CraftingOrderClassic"
local NAME  = "Crafting Order"
local REPO  = "https://github.com/Wafhi3n/CraftingOrderClassic/issues/new?template="
Report.LINKS = {
    bug  = REPO .. "bug.yml",
    idea = REPO .. "suggestion.yml",
    site = "https://www.curseforge.com/wow/addons/crafting-and-gathering-order-classic",
}

-- RFC 3986 « non réservé » seulement, le reste en %XX octet par octet (comme LeyLines_Share.lua).
local function PercentEncode(s)
    return (s:gsub("[^%w%-%._~]", function(c) return string.format("%%%02X", c:byte()) end))
end

-- « Crafting Order 1.46.0 | WoW 1.60.1 (70245) | frFR », plus la signature d'une copie du banc
-- (## X-Build, posée par deploy.ps1 ; une release n'en a jamais).
function Report.Env()
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local version = meta and meta(ADDON, "Version")
    local build = meta and meta(ADDON, "X-Build")
    local wow, num
    if GetBuildInfo then wow, num = GetBuildInfo() end
    local env = string.format("%s %s | WoW %s (%s) | %s", NAME, version or "?", wow or "?", num or "?",
        GetLocale and GetLocale() or "?")
    if build and build ~= "" then env = env .. " | " .. build end
    return env
end

-- Le lien d'un choix : `bug` et `idea` portent l'environnement, `site` est la page CurseForge.
function Report.URL(kind)
    local base = Report.LINKS[kind]
    if not base or kind == "site" then return base end
    return base .. "&env=" .. PercentEncode(Report.Env())
end

local HINTS = {
    bug  = L["Copie ce lien (Ctrl+C) et ouvre-le dans ton navigateur : le formulaire arrive avec la version déjà remplie."],
    idea = L["Copie ce lien (Ctrl+C) et ouvre-le dans ton navigateur : le formulaire arrive avec la version déjà remplie."],
    site = L["Pas de compte GitHub ? Copie ce lien (Ctrl+C) et laisse un commentaire sur la page CurseForge."],
}

-- La zone du lien : en lecture seule (une frappe remet le lien), tout sélectionné au focus.
local function buildBox(f)
    local bg = f:CreateTexture(nil, "ARTWORK")
    bg:SetPoint("TOPLEFT", f.Inset, "TOPLEFT", 12, -96)
    bg:SetPoint("RIGHT", f.Inset, "RIGHT", -12, 0)
    bg:SetHeight(24); bg:SetColorTexture(0.05, 0.05, 0.06, 0.9)
    local box = CreateFrame("EditBox", nil, f)
    box:SetPoint("TOPLEFT", bg, "TOPLEFT", 6, -4); box:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -6, 4)
    box:SetFontObject("ChatFontNormal"); box:SetAutoFocus(false); box:SetMaxLetters(0)
    box:SetScript("OnEscapePressed", function(b) b:ClearFocus(); f:Hide() end)
    box:SetScript("OnEditFocusGained", function(b) b:HighlightText() end)
    box:SetScript("OnTextChanged", function(b, user)
        if user then b:SetText(b.link or ""); b:HighlightText() end
    end)
    return box
end

function Report:Build()
    local f = Skin.MakeWindow("CraftingOrderClassicReport", 470, 200, {
        title = L["Signaler un bug ou proposer une idée"], portrait = "Interface\\Icons\\INV_Letter_15",
    })
    f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.hint:SetPoint("TOPLEFT", f.Inset, "TOPLEFT", 12, -12)
    f.hint:SetPoint("RIGHT", f.Inset, "RIGHT", -12, 0)
    f.hint:SetJustifyH("LEFT")
    f.buttons = {}
    local x = 12
    for _, def in ipairs({ { "bug", L["Bug"], 110 }, { "idea", L["Idée"], 110 },
                           { "site", L["Sans compte GitHub"], 170 } }) do
        local b = Skin.MakeGoldButton(f, def[3], 22, def[2])
        b:SetPoint("TOPLEFT", f.Inset, "TOPLEFT", x, -60)
        b:SetScript("OnClick", function() Report:Show(def[1]) end)
        f.buttons[def[1]] = b
        x = x + def[3] + 8
    end
    f.box = buildBox(f)
    self.frame = f
    return f
end

-- Ouvre la fenêtre ; `kind` (facultatif) choisit tout de suite Bug, Idée ou la page CurseForge.
function Report:Open(kind)
    local f = self.frame or self:Build()
    f:Show()
    self:Show(kind)
end

function Report:Show(kind)
    local f = self.frame
    for k, b in pairs(f.buttons) do b:SetSelected(k == kind) end
    f.hint:SetText(HINTS[kind] or L["Un bug, ou une idée pour l'addon ? Choisis ci-dessous : l'addon te donne le lien du formulaire, déjà rempli."])
    f.box.link = kind and Report.URL(kind) or ""
    f.box:SetText(f.box.link)
    if kind then f.box:SetFocus(); f.box:HighlightText() else f.box:ClearFocus() end
end

-- L'icône « bug » de la barre de titre, juste à droite du « i » : visible depuis TOUS les onglets
-- (le user l'a cherchée sur le Carnet, 2026-10-09). Même strate et même niveau que le « i », que
-- Skin.MakeHelpButton pose au-dessus de la bordure du cadre ; sans eux, la bordure la couvrirait.
-- Le « i » est un bouton de 64 px dont le disque visible fait ~28 px, au centre : d'où CENTER + 16.
-- Texture : celle du rapport de bug de Blizzard (Blizzard_PTRFeedback), 64 x 64 avec sa marge.
local BUG_ICON = "Interface\\HelpFrame\\HelpIcon-Bug"
function Report:AttachTitleButton(f, anchor)
    local b = CreateFrame("Button", nil, f)
    b:SetSize(30, 30)
    b:SetPoint("LEFT", anchor, "CENTER", 16, 0)
    b:SetFrameStrata(anchor:GetFrameStrata()); b:SetFrameLevel(anchor:GetFrameLevel())
    b:SetNormalTexture(BUG_ICON); b:SetHighlightTexture(BUG_ICON, "ADD")
    b:SetScript("OnClick", function() Report:Open() end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Signaler un bug ou proposer une idée"], 1, 1, 1)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    return b
end

-- /co bug, /co idée et leur ligne dans /co help se greffent ICI sur COC:Slash et COC:Help :
-- CraftingOrderClassic.lua est au plafond de 500 lignes. Le /co relit COC.Slash à chaque frappe
-- (`function(msg) COC:Slash(msg) end`), la greffe y est donc vue.
local SLASH = { bug = "bug", idea = "idea", idee = "idea", ["idée"] = "idea" }
local baseSlash, baseHelp = COC.Slash, COC.Help
function COC:Slash(msg)
    local kind = SLASH[((msg or ""):match("^%s*(%S*)") or ""):lower()]
    if kind then return Report:Open(kind) end
    if baseSlash then return baseSlash(self, msg) end
end
function COC:Help()
    if baseHelp then baseHelp(self) end
    print("  |cFFFFFFFF/co bug|r — " .. L["signaler un bug ou proposer une idée (lien vers un ticket GitHub)"])
end
