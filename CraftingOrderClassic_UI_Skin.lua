-- CraftingOrderClassic_UI_Skin.lua — tokens + helpers SÉMANTIQUES du skin (métiers, statuts, rareté,
-- quantités, icônes natives) et petits widgets d'affichage. Les CONSTRUCTEURS de chrome Blizzard
-- natif vivent dans CraftingOrderClassic_UI_Skin_Native.lua (même table `Skin`) — voir la skill
-- projet `coc-native-ui`. La palette « tavern » résiduelle ne sert plus qu'aux ACCENTS texte/lignes
-- (or des libellés, hover, sélection) ; le chrome (cadre, onglets, boutons) est natif.
-- INTOUCHABLE : le langage couleur des statuts d'ordre et la rareté d'objet ne sont jamais recolorés.

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
-- NB : clé canonique du Secourisme = "First Aid" (avec espace) sur TOUTES les saveurs depuis le
-- 2026-07-02 (TBC/Wrath enregistraient "FirstAid") ; on garde le double mapping par sécurité
-- (copie de lib pas encore resynchronisée).
Skin.profFR = {
    Alchemy="Alchimie", Blacksmithing="Forge", Cooking="Cuisine", Enchanting="Enchantement",
    Engineering="Ingénierie", ["First Aid"]="Secourisme", FirstAid="Secourisme", Fishing="Pêche", Herbalism="Herboristerie",
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
    Tailoring      = 3908,  Cooking        = 2550,  ["First Aid"] = 3273,  FirstAid = 3273,
    Fishing        = 7620,  Inscription    = 45357,
}
function Skin.ProfIcon(key)
    if not key then return nil end
    local sid = Skin.profSpellID[key]
    if sid and GetSpellTexture then local t = GetSpellTexture(sid); if t then return t end end
    if key == "Elemental" then return "Interface\\Icons\\Spell_Fire_FlameBolt" end
    if key == "Poisons"   then return "Interface\\Icons\\Trade_BrewPoison" end   -- pas de spell d'apprenti
    return nil
end

-- Statut d'ordre → libellé FR + couleur hex.
Skin.statusFR = {
    open      = { "En attente", "FFFFCC00" },
    accepted  = { "Acceptée",   "FF33CCFF" },
    delivered = { "Remise",     "FF88CCFF" },   -- remise par le crafteur, en attente de confirmation acheteur
    done      = { "Livrée",     "FF33DD33" },
    cancelled = { "Annulée",    "FF888888" },
    declined  = { "Refusée",    "FFFF4444" },
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

-- Libellé de quantité UNIQUE et cohérent d'un ordre (Carnet, carte vue métier, Confiées, toasts).
-- Deux modes selon o.byStack :
--   • à l'unité → « ×N »
--   • par pile  → « N piles (total) » où total = N × taille de pile (8ᵉ retour de GetItemInfo ;
--     20 pour Heavy Hide) → on donne le nombre concret d'objets voulus. Taille inconnue (objet pas
--     encore en cache / enchant sans itemID) → repli « N piles » sans le total.
-- Accepte toute table portant {qty, byStack, itemID} (ordre OU ligne Handoff:_Row).
function Skin.QtyText(o)
    local n = o.qty or 1
    if not o.byStack then return "×" .. n end
    local word = (n > 1) and L["piles"] or L["pile"]
    local stackSize = o.itemID and GetItemInfo and select(8, GetItemInfo(o.itemID))
    if stackSize and stackSize > 1 then return n .. " " .. word .. " (" .. (n * stackSize) .. ")" end
    return n .. " " .. word
end

-- Variante pour les alertes chat/toast : préfixe un espace et masque le « ×1 » trivial (mais garde
-- « 1 pile (20) », qui porte une info réelle). Renvoie "" quand il n'y a rien d'utile à afficher.
function Skin.QtySuffix(o)
    if not o.byStack and (o.qty or 1) <= 1 then return "" end
    return " " .. Skin.QtyText(o)
end

-- Durée compacte pour les cooldowns : « 2j 3h » / « 14h 5min » / « 12min » (2 unités max,
-- jamais 0 : un restant < 60 s s'affiche « 1min » — l'échelle des CD se compte en heures/jours).
function Skin.FormatDuration(sec)
    sec = math.max(0, math.floor(tonumber(sec) or 0))
    local d = math.floor(sec / 86400)
    local h = math.floor((sec % 86400) / 3600)
    local m = math.floor((sec % 3600) / 60)
    if d > 0 then
        return string.format(L["%dj"], d) .. ((h > 0) and (" " .. string.format(L["%dh"], h)) or "")
    elseif h > 0 then
        return string.format(L["%dh"], h) .. ((m > 0) and (" " .. string.format(L["%dmin"], m)) or "")
    end
    return string.format(L["%dmin"], math.max(1, m))
end

-- =========================================================================
-- Filtres d'annuaire PARTAGÉS (Commande / Récolte / Artisans) — anciennement dupliqués (knowsProf/
-- inSource) dans chaque onglet, avec une divergence SUBTILE (Artisans incluait craftSeen, pas les
-- autres). On expose ici DEUX variantes NOMMÉES pour rendre la divergence EXPLICITE et voulue.
-- =========================================================================
-- Un artisan (entrée roster) connaît-il ce métier via de VRAIES données réseau (niveau SK ou recette
-- RK) ? À utiliser pour CIBLER une commande : seul un porteur de l'addon peut la recevoir → on exclut
-- les non-porteurs « vu crafter » (craftSeen). Onglets Commande & Récolte.
function Skin.KnowsProf(r, p)
    return (r.skill and r.skill[p]) or (r.recipes and r.recipes[p]) or false
end

-- + craftSeen (non-porteur repéré à proximité, sans l'addon) + relayed (fiche servie par un
-- partenaire pendant que l'artisan est hors ligne — estimation display-only). À utiliser pour
-- l'ANNUAIRE D'AFFICHAGE (onglet Artisans) UNIQUEMENT : KnowsProf (routage) reste INTACT —
-- on n'adresse jamais une commande sur la foi d'un relais.
function Skin.KnowsProfOrSeen(r, p)
    return Skin.KnowsProf(r, p) or (r.craftSeen and r.craftSeen[p])
        or (r.relayed and (r.relayed.skill and r.relayed.skill[p]
            or r.relayed.recipes and r.relayed.recipes[p])) or false
end

-- Un artisan entre-t-il dans la SOURCE (Guilde/Amis via drapeaux de relation, sinon catégorie
-- d'affichage) ? « confed » (display-only) traité comme « recent » : un confédéré reste sélectionnable
-- sous « Croisés ». Partagé par les listes d'artisans de Commande et Récolte.
function Skin.InSource(r, src)
    return (src == "friend" and r.isFriend) or (src == "guild" and r.isGuild)
        or (r.source == "confed" and "recent" or r.source or "recent") == src
end

-- Trois champs de saisie or/argent/cuivre alignés (icônes de monnaie) → (goldEB, silverEB, copperEB).
-- Partagé par la commission (Commande) et le prix par pile (Récolte) — jadis _MakeGSC / _MakeGSCGather.
function Skin.MakeMoneyRow(parent, x, y)
    local cfg = { {40, "gold"}, {34, "silver"}, {34, "copper"} }
    local fields, cx = {}, x
    for i, c in ipairs(cfg) do
        local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
        eb:SetSize(c[1], 16); eb:SetPoint("TOPLEFT", cx, y)
        eb:SetAutoFocus(false); eb:SetNumeric(true); eb:SetText("0")
        eb:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)
        Skin.MoneyIcon(parent, c[2], eb)
        fields[i] = eb; cx = cx + c[1] + 20
    end
    return fields[1], fields[2], fields[3]
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
    scroll    = "Interface\\Icons\\INV_Scroll_03",           -- parchemin 64×64 : portrait par défaut de la fenêtre
                                                             -- (workorder = gossip ~16 px : flou + refusé par SetPortraitToTexture)
    crate     = "Interface\\Icons\\INV_Crate_03",   -- récolte « par stack »
    partner   = "Interface\\Icons\\INV_Misc_Gift_01",   -- drapeau « partenaire » (priorité alertes de don)
    unknown   = "Interface\\Icons\\INV_Misc_QuestionMark",   -- repli « rien de sélectionné »
    checkBox  = "Interface\\Buttons\\UI-CheckBox-Up",        -- case vide (texture native, pas de glyphe tofu)
    checkMark = "Interface\\Buttons\\UI-CheckBox-Check",     -- coche verte
    arrowDown = "Interface\\Buttons\\Arrow-Down-Up",         -- flèche dropdown (le « ▾ » s'affichait en tofu)
    search    = "Interface\\Common\\UI-Searchbox-Icon",      -- loupe (le « ○ » s'affichait en tofu)
    ok        = "Interface\\Scenarios\\ScenarioIcon-Check",  -- ✓ « je sais faire » (inline |T|t)
    fail      = "Interface\\Scenarios\\ScenarioIcon-Fail",   -- ✗ « hors de ma portée »
    gear      = "Interface\\Scenarios\\ScenarioIcon-Interact", -- engrenage (config, futur)
    dotYellow = "Interface\\COMMON\\Indicator-Yellow",       -- pastille (« ◆ » entrante)
    dotRed    = "Interface\\COMMON\\Indicator-Red",
    dotGreen  = "Interface\\COMMON\\Indicator-Green",
    dotGray   = "Interface\\COMMON\\Indicator-Gray",
}

-- Icône loupe + texte d'invite (placeholder) pour un champ de recherche. Renvoie le FontString
-- placeholder (à masquer quand le champ est rempli, via :SetShown(text=="")). Plus de glyphe « ○ ».
function Skin.SearchHint(parent, editbox, text)
    local ic = parent:CreateTexture(nil, "OVERLAY")
    ic:SetSize(12, 12); ic:SetPoint("LEFT", editbox, "LEFT", 2, 0); ic:SetTexture(Skin.tex.search)
    local hint = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("LEFT", ic, "RIGHT", 3, 0); hint:SetText(text)
    return hint
end

-- Case à cocher carrée en TEXTURE native (les glyphes ✓/□ s'affichent en tofu dans la police WoW).
-- Renvoie la texture « boîte » avec :SetChecked(bool) qui montre/masque la coche superposée.
function Skin.MakeCheck(parent, size)
    size = size or 16
    local box = parent:CreateTexture(nil, "ARTWORK")
    box:SetSize(size, size); box:SetTexture(Skin.tex.checkBox)
    local mark = parent:CreateTexture(nil, "OVERLAY")
    mark:SetPoint("CENTER", box, "CENTER"); mark:SetSize(size, size)
    mark:SetTexture(Skin.tex.checkMark); mark:Hide()
    box.mark = mark
    box.SetChecked = function(self, on) self.mark:SetShown(on and true or false) end
    return box
end

-- Câble le tooltip d'objet/sort au survol d'une ligne (à appeler UNE fois dans le constructeur de
-- ligne). Lit `row.tipItemID` / `row.tipSpellID` posés au refresh → priorité à l'objet (le produit).
function Skin.WireItemTooltip(row)
    row:SetScript("OnEnter", function(self)
        local link = (self.tipItemID and ("item:" .. self.tipItemID))
                  or (self.tipSpellID and ("spell:" .. self.tipSpellID))
        if not link then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if pcall(GameTooltip.SetHyperlink, GameTooltip, link) then GameTooltip:Show() else GameTooltip:Hide() end
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
end

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

-- Cadre doré sur fond ROCHE natif (la tuile 256² des fenêtres Blizzard) — utilisé par le Toast et le
-- socle des panneaux compagnons (Trade/Mail). Bordure UI-DialogBox-Gold-Border = art natif de dialogue.
function Skin.SkinFrameBackdrop(f)
    if not f.SetBackdrop then Mixin(f, BackdropTemplateMixin) end
    f:SetBackdrop({
        bgFile   = "Interface\\FrameGeneral\\UI-Background-Rock",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 256, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:SetBackdropColor(1, 1, 1, 1)   -- la teinte MULTIPLIE la texture : blanc = roche telle quelle
    f:SetBackdropBorderColor(1, 1, 1, 1)
end

-- Puits encastré, look NATIF (équivalent backdrop d'InsetFrameTemplate — on ne peut pas ré-hériter un
-- template sur une frame déjà créée, SkinWell recevant la frame de l'appelant). Bordure NEUTRE : le
-- liseré doré « tavern » est retiré au profit du gris Blizzard, pour s'accorder au cadre natif.
-- ⚠️ bgFile = ChatFrameBackground (PAS UI-Tooltip-Background, testé et rendu quasi TRANSPARENT sur les
-- flyouts malgré l'alpha 0.90 demandé — vécu sur le dropdown métier de l'onglet Commande, cause exacte
-- non identifiée mais reproductible). ChatFrameBackground est le bg solide déjà éprouvé par MakeBadge/
-- l'ancien SkinFrameBackdrop dans cette codebase : s'en tenir à des textures dont l'opacité est vérifiée.
function Skin.SkinWell(f)
    if not f.SetBackdrop then Mixin(f, BackdropTemplateMixin) end
    f:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(0.05, 0.05, 0.06, 0.95)
    f:SetBackdropBorderColor(0.50, 0.50, 0.50, 0.90)
end

function Skin.MakeSeparator(parent, offsetY)
    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetColorTexture(Skin.color.separator[1], Skin.color.separator[2], Skin.color.separator[3], 0.7)
    sep:SetPoint("TOPLEFT", 4, offsetY); sep:SetPoint("TOPRIGHT", -4, offsetY)
    return sep
end

-- (Les CONSTRUCTEURS de chrome natif — MakeGoldButton, MakeWindow, MakeTabs, MakeFlatRow,
-- MakeIconButton — vivent dans CraftingOrderClassic_UI_Skin_Native.lua, même table `Skin`.)
