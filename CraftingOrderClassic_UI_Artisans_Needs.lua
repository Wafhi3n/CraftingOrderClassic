-- CraftingOrderClassic_UI_Artisans_Needs.lua — la « BOURSE d'artisan » de l'onglet Artisans :
-- pour un artisan du roster (partenaire, guildie, ami…), la LISTE DE COURSES des fournitures qu'il
-- lui faut pour monter ses métiers — mats agrégés de SA route de progression (COC.Route, calculée
-- 100 % en LOCAL depuis son rang SK diffusé + ses recettes décodées du bitfield RK ; prix Lazy
-- Gold locaux, valables serveur entier). Aucune donnée réseau nouvelle : display-only.
-- Case « inclure les plans à acheter » (db.needsPlans) : la route peut alors passer par des plans
-- qu'il n'a pas — les plans-OBJETS rejoignent la grille comme fournitures à lui apporter, les
-- plans de FORMATEUR restent une note (pas d'objet à donner, il devra l'apprendre au PNJ).
-- Bouton d'entrée : sac posé après les icônes de métier d'une ligne (hook sous garde nil dans
-- _UI_Artisans_Icons — l'absence de ce fichier avant restart ne casse rien). Sans Lazy Gold, le
-- bouton reste visible et le clic ouvre la popup NeedLazyGold (pattern découvrabilité).

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local SLOT, STEP = 30, 34            -- case de la grille + pas (marge comprise)
local CONTENT_W  = 400               -- largeur utile du contenu scrollé
-- Flèche « vers » en TEXTURE native (la police rend « → » en tofu, cf. wow-ui-tofu-textures).
local ARROW = "|TInterface\\ChatFrame\\ChatFrameExpandArrow:12:12|t"

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

-- Nom affichable d'une recette (plans de formateur : pas d'objet) : sort, sinon nom canonique lib.
local function recipeName(sid)
    local nm = GetSpellInfo and GetSpellInfo(sid)
    if not nm then
        local lib = CL()
        nm = lib and lib.RecipeName and lib:RecipeName(sid)
    end
    return nm or ("spell:" .. sid)
end

-- Nom affichable d'un objet : cache client, sinon nom canonique lib (jamais « item:123 » nu).
local function itemName(id)
    local nm = GetItemInfo and GetItemInfo(id)
    if not nm then
        local lib = CL()
        nm = lib and lib.ItemName and lib:ItemName(id)
    end
    if nm and nm:match("^item:") then nm = nil end
    return nm or ("#" .. tostring(id))
end

-- Texte de la note « chez un PNJ » : composants vendeur (nom ×qté), séparés par des virgules.
local function vendorText(list)
    local parts = {}
    for _, mt in ipairs(list) do parts[#parts + 1] = itemName(mt.itemID) .. " ×" .. mt.qty end
    return table.concat(parts, ", ")
end

-- Gate PAS CHER du bouton de ligne (appelé à chaque refresh de l'onglet) : au moins un métier avec
-- rang SK sous le plafond entraîné ET bitfield RK décodable (même DataVersion — une fiche relayée
-- ou périmée n'a pas de liste de courses honnête, on CACHE le bouton). Pas de décodage ici.
function UI:_NeedsEligible(r)
    local lib = CL()
    if not (r and r.skill and r.recipes and lib and lib.DataVersion
            and r.recipeDV == lib:DataVersion()) then return false end
    local SEC = COC.SECONDARY_PROF or {}
    for key, sv in pairs(r.skill) do
        if not SEC[key] and r.recipes[key] and (sv[1] or 0) < (sv[2] or 0) then return true end
    end
    return false
end

-- Métiers ÉLIGIBLES avec recettes DÉCODÉES (chemin froid : à l'ouverture de la fenêtre seulement).
-- -> liste triée { key, rank, max, set } ; set = clé "s<spellID>" (format attendu par COC.Route).
function UI:_NeedsProfs(r)
    local lib, out = CL(), {}
    if not (r and lib and lib.DecodeKnown and lib.DataVersion
            and r.recipeDV == lib:DataVersion()) then return out end
    local SEC = COC.SECONDARY_PROF or {}
    for key, sv in pairs(r.skill or {}) do
        local hex = r.recipes and r.recipes[key]
        if hex and not SEC[key] and (sv[1] or 0) < (sv[2] or 0) then
            local known, set = lib:DecodeKnown(key, hex), {}
            for sid in pairs(known or {}) do set["s" .. sid] = true end
            if next(set) then out[#out + 1] = { key = key, rank = sv[1] or 0, max = sv[2] or 0, set = set } end
        end
    end
    table.sort(out, function(a, b) return Skin.ProfLabel(a.key) < Skin.ProfLabel(b.key) end)
    return out
end

-- Bouton « bourse » d'une ligne artisan (pool par ligne), posé APRÈS la dernière icône de métier
-- (x fourni par _SetArtProfIcons). `name` = perso vitrine de la ligne ; sa fiche EXACTE est relue
-- au roster (sur une ligne fusionnée, r est celle du leader, pas forcément du perso nommé).
function UI:_SetArtNeedsBtn(row, x, r, name)
    local D = COC.Directory
    local rr = (name and D and D.roster and D.roster[name]) or r
    local b = row.needsBtn
    if not (rr and name and self:_NeedsEligible(rr)) then
        if b then b:Hide() end
        return
    end
    if not b then
        b = CreateFrame("Button", nil, row.profsFrame); b:SetSize(20, 20)
        b.tex = b:CreateTexture(nil, "ARTWORK"); b.tex:SetAllPoints()
        b.tex:SetTexture("Interface\\Buttons\\Button-Backpack-Up")
        b.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        local hi = b:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints(); hi:SetColorTexture(1, 1, 1, 0.25)
        b:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText(L["Bourse d'artisan"], 1, 1, 1)
            GameTooltip:AddLine(L["Clic : les fournitures qu'il lui faut pour monter ses métiers (prix Lazy Gold)."], 0.60, 0.75, 0.91, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", GameTooltip_Hide)
        b:SetScript("OnClick", function(btn) UI:OpenNeeds(btn._name) end)
        row.needsBtn = b
    end
    b._name = name
    b:ClearAllPoints(); b:SetPoint("LEFT", x, 0)
    b:Show()
end

-- Ouvre la bourse d'un artisan. Sans Lazy Gold : popup d'incitation (le bouton reste visible pour
-- inciter au clic — même pattern que les toggles de tri, cf. coc-optional-dep-discoverability).
function UI:OpenNeeds(name)
    local LG = COC.LazyGold
    if not (LG and LG:IsAvailable()) then
        if COC.NeedLazyGold then COC:NeedLazyGold() end
        return
    end
    if not (COC.Route and name) then return end
    local f = self.needsWin or self:_BuildNeedsWin()
    self._needsName = name
    self:_FillNeeds()
    f:Show()
end

-- Fenêtre (construction paresseuse) : liste scrollée (sections par métier : en-tête + grille de
-- cases + notes), case « plans » et note d'estimation en pied. Position persistée (db.needsWinPos).
function UI:_BuildNeedsWin()
    local f = Skin.MakeWindow("CraftingOrderNeedsWindow", 460, 440, {
        title = L["Bourse d'artisan"], portrait = "Interface\\Icons\\INV_Misc_Bag_08",
        strata = "FULLSCREEN_DIALOG",
        pos = COC.db and COC.db.needsWinPos,
        onMoved = function(p, rp, x, y) if COC.db then COC.db.needsWinPos = { p, rp, x, y } end end,
    })
    local inset = f.Inset or f
    local scroll = CreateFrame("ScrollFrame", "CraftingOrderNeedsScroll", inset, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 6, -6); scroll:SetPoint("BOTTOMRIGHT", -26, 44)
    Skin.ScrollTrack("CraftingOrderNeedsScroll")
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(CONTENT_W, 1); scroll:SetScrollChild(content)
    f.scroll, f.content = scroll, content
    f.heads, f.slots, f.lines = {}, {}, {}
    local msg = inset:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    msg:SetPoint("CENTER", 0, 10); msg:SetWidth(360)
    msg:SetText(L["Rien à fournir — métiers au plafond, ou données trop anciennes."]); msg:Hide()
    f.msg = msg
    local chk = Skin.MakeCheckButton(inset, L["Inclure les plans à acheter"], 20)
    chk:SetPoint("BOTTOMLEFT", 8, 22)
    chk:SetScript("OnClick", function(cb)
        if COC.db then COC.db.needsPlans = cb:GetChecked() and true or false end
        UI:_FillNeeds()
    end)
    f.chk = chk
    local cav = inset:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    cav:SetPoint("BOTTOMLEFT", 10, 7); cav:SetPoint("BOTTOMRIGHT", -10, 7); cav:SetJustifyH("LEFT")
    cav:SetText(L["Estimation : chance de point par couleur, prix du dernier scan HV (Lazy Gold)."])
    self.needsWin = f
    return f
end

-- Largeur utile du contenu d'une fenêtre à bloc fournitures (la bourse ET la fenêtre Plan de
-- route partagent ces pools — leurs contenus n'ont pas la même largeur).
local function contentW(f)
    local w = f.content and f.content:GetWidth()
    return (w and w > 40) and w or CONTENT_W
end

-- Ligne de TEXTE poolée (notes : plans de formateur, route incomplète, remarque des plans).
-- Renvoie le nouveau y (hauteur réelle du texte enveloppé).
function UI:_NeedsTextLine(f, used, y, text)
    used.line = used.line + 1
    local fs = f.lines[used.line]
    if not fs then
        fs = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetWidth(contentW(f) - 10); fs:SetJustifyH("LEFT"); fs:SetWordWrap(true)
        f.lines[used.line] = fs
    end
    fs:ClearAllPoints(); fs:SetPoint("TOPLEFT", 4, -y)
    fs:SetText(text); fs:Show()
    return y + math.max(fs:GetStringHeight() or 12, 12) + 4
end

-- Tooltip d'une case : l'objet (tooltip natif), la quantité requise et son coût estimé ; mention
-- « plan à fournir » sur un plan-objet inclus par la case des plans.
local function slotTooltip(s)
    GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
    -- Repli nom via Skin.TipItem : un objet pas encore en cache rendait un tooltip vide.
    Skin.TipItem(GameTooltip, s.tipItemID, s.tipItemID and itemName(s.tipItemID) or "?")
    local total = s.tipCost and (s.tipCost * (s.tipPlan and 1 or (s.tipQty or 1)))
    local cost = total and (" — ~" .. GetCoinTextureString(math.floor(total + 0.5))) or ""
    GameTooltip:AddLine(string.format(L["Requis : ×%d"], s.tipQty or 1) .. cost, 0.60, 0.75, 0.91)
    if s.tipPlan then GameTooltip:AddLine(L["Plan à fournir (il ne le connaît pas encore)"], 0.91, 0.72, 0.29) end
    -- Composant de DÉSENCHANTEMENT : dire QUELS objets détruire pour l'obtenir (table curatée lib
    -- v12 — c'est souvent LA vraie fourniture : des verts pas chers de la tranche, pas la poussière).
    local lib = CL()
    local de = lib and lib.DisenchantSource and lib:DisenchantSource(s.tipItemID)
    if de then
        local qn = _G["ITEM_QUALITY" .. de.q .. "_DESC"] or "?"
        local qc = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[de.q]
        if qc and qc.hex then qn = qc.hex .. qn .. "|r" end
        GameTooltip:AddLine(string.format(L["Désenchanter : objets %s, niv. d'objet %d-%d (estimation)"],
            qn, de.lo, de.hi), 0.91, 0.72, 0.29, true)
    end
    GameTooltip:Show()
end

-- Case de grille poolée : icône (kit MakeIconButton), compteur façon sac, marqueur parchemin pour
-- un plan-objet. Shift-clic → lien chat (tipItemID, cf. Skin.WireItemLink).
function UI:_NeedsSlot(f, i)
    local s = f.slots[i]
    if s then return s end
    s = Skin.MakeIconButton(f.content, SLOT, nil)
    s.count = s:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    s.count:SetPoint("BOTTOMRIGHT", -2, 2)
    s.tag = s:CreateTexture(nil, "OVERLAY")
    s.tag:SetSize(13, 13); s.tag:SetPoint("TOPLEFT", -3, 3)
    s.tag:SetTexture("Interface\\Icons\\INV_Scroll_03"); s.tag:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    s:SetScript("OnEnter", slotTooltip)
    s:SetScript("OnLeave", GameTooltip_Hide)
    Skin.WireItemLink(s)
    f.slots[i] = s
    return s
end

-- Grille d'items d'une section (plans-objets d'abord, puis mats) : cases en rangées de perRow.
function UI:_NeedsGrid(f, used, y, items)
    if #items == 0 then return y end
    local perRow = math.max(1, math.floor((contentW(f) - 8) / STEP))
    for i, it in ipairs(items) do
        used.slot = used.slot + 1
        local s = self:_NeedsSlot(f, used.slot)
        local c = (i - 1) % perRow
        if i > 1 and c == 0 then y = y + STEP end
        s:ClearAllPoints(); s:SetPoint("TOPLEFT", 4 + c * STEP, -y)
        s.icon:SetTexture((GetItemIcon and GetItemIcon(it.itemID)) or "Interface\\Icons\\INV_Misc_QuestionMark")
        s.count:SetText((it.qty or 1) > 1 and it.qty or "")
        s.tag:SetShown(it.plan and true or false)
        s.tipItemID, s.tipQty, s.tipCost, s.tipPlan = it.itemID, it.qty or 1, it.cost, it.plan
        s:Show()
    end
    return y + STEP + 4
end

-- Lignes « plan à acheter » : une par plan de la route — au formateur ou en objet (vendeur/HV),
-- prix, et le PNJ À ALLER VOIR quand MTSL le résout (« [niv] Nom — Zone (x, y) », compact).
function UI:_NeedsPlanLines(f, used, y, profKey, plans)
    local M = COC.MTSL
    for _, pl in ipairs(plans) do
        local price = (pl.price or 0) > 0 and (" — " .. GetCoinTextureString(pl.price)) or ""
        local txt
        if pl.trainer then
            txt = "|cFF88CCFF" .. string.format(L["Au formateur : %s"], recipeName(pl.sid)) .. price .. "|r"
        else
            txt = "|TInterface\\Icons\\INV_Scroll_03:12:12|t |cFFEEDD88"
                .. L["Plan à acheter"] .. " : " .. recipeName(pl.sid) .. price .. "|r"
        end
        local npc = (M and M.SourceNpcLine) and M:SourceNpcLine(profKey, pl.sid) or nil
        if npc then txt = txt .. "   " .. npc end
        y = self:_NeedsTextLine(f, used, y, txt)
    end
    return y
end

-- Bloc « fournitures » PARTAGÉ (bourse d'artisan ET fenêtre Plan de route) : grille (plans-objets
-- + mats hors vendeur), note « chez un PNJ », lignes plans avec le PNJ où aller, note des trous
-- CHIFFRÉE (opts.plansHint : rappelle la case « plans » de la bourse). Renvoie le nouveau y.
function UI:_FillSupplyBlock(f, used, y, profKey, m, opts)
    local items, vend = {}, {}
    for _, pl in ipairs(m.plans) do
        if pl.itemID then items[#items + 1] = { itemID = pl.itemID, qty = 1, cost = pl.price, plan = true } end
    end
    -- Les composants VENDEUR sortent de la grille (il les achètera en ville) → simple note dessous.
    for _, mt in ipairs(m.mats) do
        if mt.vendor then vend[#vend + 1] = mt else items[#items + 1] = mt end
    end
    y = self:_NeedsGrid(f, used, y, items)
    if #vend > 0 then
        y = self:_NeedsTextLine(f, used, y, "|cFF888888"
            .. string.format(L["Chez un PNJ (inutile de fournir) : %s"], vendorText(vend)) .. "|r")
    end
    y = self:_NeedsPlanLines(f, used, y, profKey, m.plans)
    if m.gaps then
        local txt = string.format(L["Route incomplète : %d rang(s) sans recette calculable (prix HV manquants)."], m.gapPts or 0)
        if opts and opts.plansHint then
            txt = txt .. " " .. L["Coche « Inclure les plans à acheter » pour en combler une partie."]
        end
        y = self:_NeedsTextLine(f, used, y, "|cFF888888" .. txt .. "|r")
    end
    return y
end

-- Section d'un métier : route de CET artisan (recettes connues seules, ou + plans si coché) →
-- en-tête « métier rang→cible — total », puis le bloc fournitures partagé.
-- Renvoie le nouveau y, ou nil si rien à montrer (au plafond / incalculable).
function UI:_FillNeedsProf(f, used, y, p)
    local withPlans = (COC.db and COC.db.needsPlans) and true or false
    local route = COC.Route:Compute(p.key, p.rank, p.max, { known = p.set, plans = withPlans })
    local m = route and COC.Route:Materials(p.key, route)
    if not (m and (#m.mats > 0 or #m.plans > 0)) then return nil end
    used.head = used.head + 1
    local h = f.heads[used.head]
    if not h then h = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal"); f.heads[used.head] = h end
    local total = GetCoinTextureString(math.floor((route.mats or 0) + (route.plans or 0) + 0.5))
    h:SetText(string.format("|T%s:14:14|t |cFFE8B84B%s|r  |cFF9AC0E8%d|r%s|cFF9AC0E8%d|r  %s",
        Skin.ProfIcon(p.key) or "Interface\\Icons\\INV_Misc_QuestionMark", Skin.ProfLabel(p.key),
        route.rank, ARROW, route.target,
        string.format(L["Total estimé : %s"], ((m.gaps or m.partial) and "> " or "") .. total)))
    h:ClearAllPoints(); h:SetPoint("TOPLEFT", 4, -y); h:Show()
    y = self:_FillSupplyBlock(f, used, y + 22, p.key, m, { plansHint = not withPlans })
    return y + 8
end

-- La bourse est une fenêtre SÉPARÉE : UI:RefreshSoon est gaté sur la fenêtre PRINCIPALE et ne la
-- repeint jamais. Post-hook : tout refresh demandé (SK/RK frais au roster — le partenaire vient de
-- monter son métier ou d'apprendre une recette) recalcule AUSSI la bourse ouverte, débouncé (les
-- annonces SK+RK arrivent en rafale).
local origRefreshSoon = UI.RefreshSoon
function UI:RefreshSoon()
    origRefreshSoon(self)
    local f = self.needsWin
    if not (f and f:IsShown()) then return end
    if not (C_Timer and C_Timer.After) then return self:_FillNeeds() end
    if self._needsPending then return end
    self._needsPending = true
    C_Timer.After(0.3, function()
        UI._needsPending = nil
        if UI.needsWin and UI.needsWin:IsShown() then UI:_FillNeeds() end
    end)
end

-- (Re)calcule et peint la bourse du perso mémorisé (titre, remarque des plans, sections métier).
function UI:_FillNeeds()
    local f = self.needsWin
    if not f then return end
    local name = self._needsName or "?"
    local D = COC.Directory
    local r = D and D.roster and D.roster[name]
    if f.SetTitle then f:SetTitle(string.format(L["Bourse — %s"], name)) end
    f.chk:SetChecked((COC.db and COC.db.needsPlans) and true or false)
    local used, y, shown = { head = 0, slot = 0, line = 0 }, 6, 0
    if COC.db and COC.db.needsPlans then
        y = self:_NeedsTextLine(f, used, y, "|cFF888888"
            .. L["Les plans-objets s'ajoutent aux fournitures ; les plans « au formateur » restent à apprendre chez le PNJ."] .. "|r")
    end
    for _, p in ipairs(self:_NeedsProfs(r)) do
        local ny = self:_FillNeedsProf(f, used, y, p)
        if ny then y, shown = ny, shown + 1 end
    end
    for i = used.head + 1, #f.heads do f.heads[i]:Hide() end
    for i = used.slot + 1, #f.slots do f.slots[i]:Hide() end
    for i = used.line + 1, #f.lines do f.lines[i]:Hide() end
    f.content:SetHeight(math.max(y, 1))
    f.msg:SetShown(shown == 0)
end
