-- CraftingOrderClassic_UI_Setup.lua — le panneau de PREMIÈRE CONNEXION : où chercher les artisans ?
-- (spec docs/specs/canaux-surveilles.md, palier 5).
--
-- Pourquoi (2026-09-30) : les cases des canaux surveillés vivent dans l'onglet Artisans, où un
-- joueur ne va pas de lui-même. Ce panneau les lui montre UNE fois, avec une phrase par groupe, à
-- tout le monde : le nouvel installé comme celui qui a déjà l'addon, à la mise à jour qui l'apporte
-- (décision du user).
--
-- Les cases sont VIVANTES : les mêmes lignes que l'onglet (UI:_ChannelRows), chaque clic passe par
-- COC.Channels.SetWatched. « Valider », la croix et Échap font donc la même chose : noter que le
-- panneau a été vu. Fermer vaut accepter ce qui est affiché, par construction.
--
-- Il ne s'ouvre PAS au login même : le jeu ne rejoint ses canaux que quelques secondes plus tard, et
-- les communautés plus tard encore. Ouvert trop tôt, il montrerait Commerce grisé « en ville » en
-- pleine capitale. Il attend donc OPEN_DELAY, la fin d'un combat, la sortie d'une instance, et se
-- redessine tant qu'il est ouvert quand un canal, une guilde ou une communauté arrive.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local NAME = "CraftingOrderClassicSetup"
local W, PAD, ITEM_H, COL_GAP = 470, 14, 20, 12
local CW   = W - 10 - 2 * PAD                 -- largeur utile : le marbre moins ses marges
local COLW = math.floor((CW - COL_GAP) / 2)   -- les cases vont sur deux colonnes
local OPEN_DELAY = 10                         -- s après le login

local S = { heads = {}, descs = {}, lines = {} }

local function myVersion()
    local D = COC.Directory
    if not (D and D._MyVersion) then return nil end
    D:_MyVersion()
    return D._myVerStr
end

local function onLineClick(self)
    if self.key == "announce" then
        if COC.db then COC.db.announceTrade = (not COC.db.announceTrade) and true or nil end
    elseif self.key then
        COC.Channels.SetWatched(self.key, not COC.Channels.IsWatched(self.key))
    end
    S.Render()
end

-- Une ligne à case : la coche, le libellé, une mention à droite (« en ville »).
local function makeLine(host)
    local b = CreateFrame("Button", nil, host)
    b.check = Skin.MakeCheck(b, 14); b.check:SetPoint("LEFT", 0, 0)
    b.note = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); b.note:SetPoint("RIGHT", -2, 0)
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.label:SetPoint("LEFT", 20, 0); b.label:SetPoint("RIGHT", b.note, "LEFT", -4, 0)
    b.label:SetJustifyH("LEFT"); b.label:SetWordWrap(false)
    local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.06)
    b:SetScript("OnClick", onLineClick)
    return b
end

-- Le i-ième texte d'une réserve (en-têtes, explications), créé au besoin.
local function text(pool, i, host, font)
    local fs = pool[i]
    if not fs then
        fs = host:CreateFontString(nil, "OVERLAY", font)
        fs:SetJustifyH("LEFT"); fs:SetWidth(CW)
        pool[i] = fs
    end
    fs:ClearAllPoints(); fs:Show()
    return fs
end

-- Pose les lignes à partir de `y` (négatif, vers le bas) ; rend le `y` sous la dernière.
local function placeRows(host, rows, y)
    local nh, nd, nl, col = 0, 0, 0, 0
    local function endRow() if col == 1 then y = y - ITEM_H; col = 0 end end
    for _, d in ipairs(rows) do
        if d.kind == "header" then
            endRow(); y = y - 8
            nh = nh + 1
            local h = text(S.heads, nh, host, "GameFontNormalSmall")
            h:SetPoint("TOPLEFT", 0, y); h:SetText(d.text); y = y - 14
            nd = nd + 1
            local t = text(S.descs, nd, host, "GameFontDisableSmall")
            t:SetPoint("TOPLEFT", 0, y); t:SetText(d.tip or ""); y = y - t:GetStringHeight() - 4
        elseif d.kind == "item" then
            nl = nl + 1
            local b = S.lines[nl]
            if not b then b = makeLine(host); S.lines[nl] = b end
            b:Show(); b:SetSize(COLW, ITEM_H); b:ClearAllPoints()
            b:SetPoint("TOPLEFT", col * (COLW + COL_GAP), y)
            b.key = d.key
            b.check:SetChecked(d.on); b.label:SetText(d.label); b.note:SetText(d.note or "")
            b.label:SetTextColor(Skin.unpack(d.there and Skin.color.text or Skin.color.textMuted))
            col = col + 1
            if col == 2 then col = 0; y = y - ITEM_H end
        else
            endRow(); nd = nd + 1
            local t = text(S.descs, nd, host, "GameFontDisableSmall")
            t:SetPoint("TOPLEFT", 20, y); t:SetText(d.text or ""); y = y - ITEM_H
        end
    end
    endRow()
    return y
end

-- Redessine le panneau ouvert : les lignes, puis la case « Annoncer », puis la hauteur de la fenêtre.
function S.Render()
    local f, host = S.frame, S.host
    if not (f and f:IsShown()) then return end
    for _, pool in ipairs({ S.heads, S.descs, S.lines }) do
        for _, o in ipairs(pool) do o:Hide() end
    end
    local y = placeRows(host, UI:_ChannelRows(), -(S.intro:GetStringHeight() + 4)) - 10
    S.rule:ClearAllPoints(); S.rule:SetPoint("TOPLEFT", 0, y); S.rule:SetPoint("TOPRIGHT", 0, y)
    y = y - 8
    S.announce:ClearAllPoints(); S.announce:SetPoint("TOPLEFT", 0, y)
    S.announce.check:SetChecked(COC.db and COC.db.announceTrade == true)
    y = y - ITEM_H
    S.announceSub:ClearAllPoints(); S.announceSub:SetPoint("TOPLEFT", 20, y)
    y = y - S.announceSub:GetStringHeight() - 12
    -- Le cadre autour du contenu (titre, bordures, marges) : mesuré une fois, quand l'hôte a une taille.
    if not S.chrome and host:GetHeight() > 0 then S.chrome = f:GetHeight() - host:GetHeight() end
    f:SetHeight((S.chrome or 94) - y + 24)   -- 24 = le bouton « Valider », au bas de l'hôte
end

local function close()
    COC.Channels.MarkSetupSeen(COC.db, myVersion())
    if S.frame then S.frame:Hide() end
end

local function build()
    -- onClose : la croix ET le proxy d'Échap passent par `close`, comme « Valider ». Pas de OnHide :
    -- un masquage d'interface (Alt+Z, cinématique) ne vaut pas « vu ».
    local f = Skin.MakeWindow(NAME, W, 480, { title = L["Où chercher les artisans ?"], portrait = Skin.tex.scroll, onClose = close })
    local host = CreateFrame("Frame", nil, f)
    host:SetPoint("TOPLEFT", f.Inset, "TOPLEFT", PAD, -PAD)
    host:SetPoint("BOTTOMRIGHT", f.Inset, "BOTTOMRIGHT", -PAD, PAD)
    host:SetFrameLevel(f.Inset:GetFrameLevel() + 1)
    S.frame, S.host = f, host
    S.intro = host:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    S.intro:SetPoint("TOPLEFT", 0, 0); S.intro:SetWidth(CW); S.intro:SetJustifyH("LEFT")
    S.intro:SetText(L["L'addon trouve les artisans par les canaux que tu coches ici. Tu pourras tout changer plus tard, dans l'onglet Artisans."])
    S.rule = host:CreateTexture(nil, "ARTWORK"); S.rule:SetHeight(1); S.rule:SetColorTexture(1, 1, 1, 0.12)
    S.announce = makeLine(host); S.announce.key = "announce"; S.announce:SetSize(CW, ITEM_H)
    S.announce.label:SetText(L["Annoncer aussi mes commandes et ma dispo sur Trade (Services)"])
    S.announceSub = host:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    S.announceSub:SetWidth(CW - 20); S.announceSub:SetJustifyH("LEFT")
    S.announceSub:SetText(L["Une ligne lisible par tous, seulement quand tu cliques."])
    local ok = Skin.MakeGoldButton(host, 110, 24, L["Valider"])
    ok:SetPoint("BOTTOMRIGHT", 0, 0); ok:SetScript("OnClick", close)
    f:Hide()
end

-- Ouvre le panneau (aussi par /co watch setup, pour le revoir).
function UI:ShowSetup()
    if not S.frame then build() end
    S.frame:Show()
    S.Render()
end

local function tryOpen()
    local inCombat = InCombatLockdown and InCombatLockdown()
    local inInstance = IsInInstance and IsInInstance()
    if COC.Channels.SetupState(COC.db, inCombat, inInstance) == "show" then UI:ShowSetup() end
end

local boot = CreateFrame("Frame")
for _, ev in ipairs({ "PLAYER_LOGIN", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD",
                      "CHANNEL_UI_UPDATE", "PLAYER_GUILD_UPDATE", "CLUB_ADDED", "CLUB_REMOVED" }) do
    pcall(boot.RegisterEvent, boot, ev)
end
boot:SetScript("OnEvent", function(_, ev)
    if ev == "PLAYER_LOGIN" then
        if C_Timer and C_Timer.After then C_Timer.After(OPEN_DELAY, function() S.armed = true; tryOpen() end) end
    elseif ev == "PLAYER_REGEN_ENABLED" or ev == "PLAYER_ENTERING_WORLD" then
        if S.armed then tryOpen() end   -- fin d'un combat, sortie d'une instance
    else
        S.Render()                      -- un canal, une guilde, une communauté : le panneau ouvert suit
    end
end)
