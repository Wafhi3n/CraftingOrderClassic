-- CraftingOrderClassic_Companion.lua — socle des GREFFONS : panneaux compagnons accrochés aux
-- fenêtres natives (échange, courrier) pour livrer une commande sans quitter le geste en cours.
-- Réf. design : Documentation/greffon_integration (« Crafting Order Hooks », scènes A/B).
-- Règles : on AJOUTE un panneau à côté de la frame Blizzard (jamais de Hide/neutralisation) ;
-- l'UI lit UNIQUEMENT le cache COC.db.orders (réseau → cache → UI) ; le panneau ne s'affiche
-- que s'il y a au moins une commande à livrer au partenaire courant (zéro bruit sinon).

local COC  = CraftingOrderClassic
local Comp = {}
COC.Companion = Comp
local L    = COC.L
local Skin = COC.UI.Skin

local function me() return (UnitName and UnitName("player")) or "?" end
local function shortName(n) return n and (n:match("^([^%-]+)") or n) or n end
Comp.shortName = shortName

-- Prix texte libre → cuivre (pour pré-remplir un contre-remboursement). Le format canonique de
-- l'écosystème est FR « 12po 50pa 3pc » (cf. DoPostOrder) ; on tolère l'anglais g/s/c pour les
-- prix saisis à la main via /co post. Illisible → nil (le joueur saisira le C.O.D. lui-même).
function Comp.PriceToCopper(price)
    if type(price) ~= "string" or price == "" then return nil end
    local s = price:lower()
    local g  = tonumber(s:match("(%d+)%s*po")) or tonumber(s:match("(%d+)%s*g"))
    local si = tonumber(s:match("(%d+)%s*pa")) or tonumber(s:match("(%d+)%s*s"))
    local c  = tonumber(s:match("(%d+)%s*pc")) or tonumber(s:match("(%d+)%s*c"))
    local total = (g or 0) * 10000 + (si or 0) * 100 + (c or 0)
    return total > 0 and total or nil
end

-- Prix (texte) → chaîne avec ICÔNES de pièces natives (or/argent/cuivre inline). Repli sur le texte
-- doré si le prix n'est pas convertible en cuivre (ex. « Don / gratuit »).
function Comp.PriceLabel(o)
    if not (o and o.price) then return "" end
    local copper = Comp.PriceToCopper(o.price)
    if copper and GetCoinTextureString then return GetCoinTextureString(copper) end
    return "|c" .. Skin.hex.price .. tostring(o.price) .. "|r"
end

-- Mon RÔLE dans la commande `o` vis-à-vis de `partner` (comparaison nom court, insensible à la casse),
-- pour une commande encore active (`accepted`/`delivered`) :
--   "sell" = JE la crafte pour lui (acceptedBy==moi, buyer==partenaire) → je livre, il me paie.
--   "buy"  = il la crafte pour MOI (buyer==moi, acceptedBy==partenaire) → je reçois, je paie.
-- nil si la commande ne nous concerne pas tous les deux (ou statut clos).
function Comp.RoleWith(o, partner)
    local m, p = me(), partner and shortName(partner):lower()
    if not (o and p and p ~= "") then return nil end
    if o.status ~= "accepted" and o.status ~= "delivered" then return nil end
    if o.acceptedBy == m and o.buyer and shortName(o.buyer):lower() == p then return "sell" end
    if o.buyer == m and o.acceptedBy and shortName(o.acceptedBy):lower() == p then return "buy" end
    return nil
end

local function sortOrders(out)
    table.sort(out, function(a, b)
        if a.status ~= b.status then return a.status == "accepted" end
        return tostring(a.id) < tostring(b.id)
    end)
    return out
end

-- Commandes que JE dois livrer à `partner` (rôle vendeur uniquement) — utilisé par le greffon courrier
-- (on ne « reçoit » pas via un courrier qu'on compose). `accepted` d'abord, puis `delivered`.
function Comp:OrdersFor(partner)
    local out = {}
    if not (COC.db and COC.db.orders) then return out end
    for _, o in pairs(COC.db.orders) do
        if Comp.RoleWith(o, partner) == "sell" then out[#out + 1] = o end
    end
    return sortOrders(out)
end

-- Commandes nous liant à `partner` DANS LES DEUX SENS (je crafte pour lui OU il crafte pour moi) —
-- utilisé par le greffon échange, où les deux joueurs sont face à face.
function Comp:OrdersWith(partner)
    local out = {}
    if not (COC.db and COC.db.orders) then return out end
    for _, o in pairs(COC.db.orders) do
        if Comp.RoleWith(o, partner) then out[#out + 1] = o end
    end
    return sortOrders(out)
end

-- ------------------------------------------------------------------
-- Panneau compagnon skinné : en-tête (icône work-order + titre + partenaire) + puits de lignes.
-- Le pied (boutons, ligne prix) est ajouté par chaque greffon. `maxRows` lignes visibles + « +N ».
-- ------------------------------------------------------------------
function Comp.MakePanel(name, parent, width, maxRows)
    local f = CreateFrame("Frame", name, parent, "BackdropTemplate")
    f.maxRows = maxRows or 4
    f:SetSize(width, 92 + f.maxRows * 30)
    Skin.SkinFrameBackdrop(f)
    f:SetFrameStrata("MEDIUM")

    local ic = f:CreateTexture(nil, "ARTWORK")
    ic:SetSize(18, 18); ic:SetPoint("TOPLEFT", 14, -14); ic:SetTexture(Skin.tex.workorder)
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", ic, "RIGHT", 6, 0); Skin.ApplyShadow(title)
    title:SetText("|c" .. Skin.hex.gold .. "Crafting Order|r")
    f.partnerFS = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.partnerFS:SetPoint("TOPRIGHT", -16, -17); Skin.ApplyShadow(f.partnerFS)

    local sub = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sub:SetPoint("TOPLEFT", 15, -36); Skin.ApplyShadow(sub)
    sub:SetText("|c" .. Skin.hex.gold .. L["Commandes pour ce joueur"] .. "|r")

    local well = CreateFrame("Frame", nil, f, "BackdropTemplate")
    well:SetPoint("TOPLEFT", 12, -50); well:SetPoint("TOPRIGHT", -12, -50)
    well:SetHeight(f.maxRows * 30 + 8)
    Skin.SkinWell(well)
    f.well = well

    f.moreFS = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.moreFS:SetPoint("BOTTOMRIGHT", well, "BOTTOMRIGHT", -8, 4); f.moreFS:Hide()

    f.rows = {}
    return f
end

-- Ligne du pool (2 lignes de texte) : L1 = nom (gauche) + qté ×N (droite) ; L2 = prix en pièces
-- (gauche) + statut (droite). Séparer qté et prix sur deux lignes évite le télescopage. Clic = sélection.
local function makeRow(panel, i)
    local well = panel.well
    local r = CreateFrame("Button", nil, well, "BackdropTemplate")
    r:SetHeight(30)
    r:SetPoint("TOPLEFT", 5, -(4 + (i - 1) * 30)); r:SetPoint("TOPRIGHT", -5, -(4 + (i - 1) * 30))
    r:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
    r.badge = Skin.MakeBadge(r, 22); r.badge:SetPoint("LEFT", 3, 0)
    -- Ligne 1 : nom + quantité
    r.qtyFS = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.qtyFS:SetPoint("TOPRIGHT", -6, -3); r.qtyFS:SetJustifyH("RIGHT"); Skin.ApplyShadow(r.qtyFS)
    r.nameFS = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.nameFS:SetPoint("TOPLEFT", 32, -3); r.nameFS:SetPoint("RIGHT", r.qtyFS, "LEFT", -4, 0)
    r.nameFS:SetJustifyH("LEFT"); r.nameFS:SetWordWrap(false); Skin.ApplyShadow(r.nameFS)
    -- Ligne 2 : prix (pièces) + statut
    r.stFS = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.stFS:SetPoint("BOTTOMRIGHT", -6, 3); r.stFS:SetJustifyH("RIGHT"); Skin.ApplyShadow(r.stFS)
    r.subFS = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.subFS:SetPoint("BOTTOMLEFT", 32, 3); r.subFS:SetPoint("RIGHT", r.stFS, "LEFT", -6, 0)
    r.subFS:SetJustifyH("LEFT"); Skin.ApplyShadow(r.subFS)
    r:SetScript("OnClick", function(self)
        panel.selectedId = self.orderId
        if panel.Update then panel:Update() end
    end)
    r:SetScript("OnEnter", function(self)
        if self.orderId ~= panel.selectedId then self:SetBackdropColor(Skin.unpack(Skin.color.rowHover)) end
    end)
    r:SetScript("OnLeave", function(self)
        if panel.PaintRowBg then panel.PaintRowBg(self) end
    end)
    return r
end

local function paintRowBg(r)
    if r.isSelected then r:SetBackdropColor(0.78, 0.57, 0.18, 0.25) else r:SetBackdropColor(0, 0, 0, 0) end
end

-- Remplit le pool avec `orders` ; entretient la sélection (retombe sur la 1re ligne si l'ordre
-- sélectionné a disparu du lot). Renvoie l'ordre sélectionné (ou nil si liste vide).
function Comp.FillRows(panel, orders)
    panel.PaintRowBg = paintRowBg
    local n = math.min(#orders, panel.maxRows)
    local selOk = false
    for _, o in ipairs(orders) do if o.id == panel.selectedId then selOk = true end end
    if not selOk then panel.selectedId = orders[1] and orders[1].id or nil end
    for i = 1, n do
        local o = orders[i]
        local r = panel.rows[i] or makeRow(panel, i); panel.rows[i] = r
        r.orderId = o.id
        r.isSelected = (o.id == panel.selectedId)
        local nm = COC.Orders:OrderName(o)
        local cr, cg, cb = Skin.RarityColor(o.itemID)
        r.badge:Paint(cr, cg, cb, Skin.FirstChar(nm), Skin.Icon(o.itemID, o.spellID))
        r.nameFS:SetText(nm); r.nameFS:SetTextColor(cr, cg, cb)
        r.qtyFS:SetText("|cFFCCCCCC" .. Skin.QtyText(o) .. "|r")
        r.subFS:SetText(Comp.PriceLabel(o))
        local stTxt, stHex = Skin.StatusInfo(o.status)
        r.stFS:SetText("|c" .. stHex .. stTxt .. "|r")
        paintRowBg(r)
        r:Show()
    end
    for i = n + 1, #panel.rows do panel.rows[i]:Hide() end
    if #orders > panel.maxRows then
        panel.moreFS:SetText(string.format(L["+%d autre(s)"], #orders - panel.maxRows)); panel.moreFS:Show()
    else
        panel.moreFS:Hide()
    end
    for _, o in ipairs(orders) do if o.id == panel.selectedId then return o end end
    return nil
end

-- Se re-peindre quand le cache d'ordres bouge : UI:Refresh est déjà appelé par tout le réseau
-- (ACK/NACK/DONE...) → greffe passive, le panneau suit sans écouter le réseau lui-même.
function Comp.OnCacheRefresh(fn)
    if COC.UI and COC.UI.Refresh then hooksecurefunc(COC.UI, "Refresh", fn) end
end
