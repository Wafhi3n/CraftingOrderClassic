-- CraftingOrderClassic_JournalWin.lua — LE JOURNAL : une fenêtre parchemin où les commandes et les
-- vraies quêtes du joueur cohabitent par sections. C'est l'aboutissement du modèle `COC.Journal` :
-- la même liste d'entrées qui alimente le suivi à l'écran, présentée ici pour l'immersion.
--
-- Fenêtre SÉPARÉE (choix user) : le Carnet garde sa vue fonctionnelle — colonnes, tris, statuts —
-- et le journal apporte la vue immersive. Aucune régression possible sur l'existant.
--
-- Deux volets : la liste à gauche (sections repliables), le détail à droite. Le détail n'est PAS
-- réécrit ici : c'est le contenu de `COC.QuestSheet` encastré dans un volet (`BuildContent`), le
-- même code que la popup « Poster en quête ». Une seule fiche de quête dans tout l'addon.
--
-- Les vraies quêtes sont LUES par `COC.JournalQuests` (jamais écrites) — voir ce fichier pour
-- pourquoi le journal natif n'est pas extensible et quels pièges d'état partagé il pose.

local COC  = CraftingOrderClassic
local L    = COC.L
local Skin = COC.UI and COC.UI.Skin
local Win  = {}
COC.JournalWin = Win

local W, H     = 700, 460
local LEFT_W   = 296
local ROW_H    = 18   -- QuestFont fait ~13 px : 16 rognait les jambages
local NAME     = "CraftingOrderJournal"

local function font(name, fallback) return _G[name] or _G[fallback] end

-- Sections des COMMANDES : leurs clés servent aussi de clé de repli persistée. Les zones de quêtes,
-- elles, sont identifiées par leur libellé (« Hellfire Peninsula ») — le jeu ne donne pas d'id.
local function collapsed(key)
    local db = COC.db
    return (db and db.journalCollapsed and db.journalCollapsed[key]) and true or false
end

local function toggle(key)
    local db = COC.db; if not db then return end
    db.journalCollapsed = db.journalCollapsed or {}
    db.journalCollapsed[key] = (not db.journalCollapsed[key]) or nil
    Win:Refresh()
end

-- ------------------------------------------------------------------
-- Lignes
-- ------------------------------------------------------------------
function Win:_Row(i)
    self.rows = self.rows or {}
    local r = self.rows[i]
    if r then return r end
    r = CreateFrame("Button", nil, self.content)
    r:SetHeight(ROW_H)
    r:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -(i - 1) * ROW_H)
    r:SetPoint("RIGHT", self.content, "RIGHT", 0, 0)

    r.icon = r:CreateTexture(nil, "OVERLAY")
    r.icon:SetSize(ROW_H, ROW_H); r.icon:SetPoint("LEFT", 0, 0); r.icon:Hide()

    r.text = r:CreateFontString(nil, "OVERLAY")
    r.text:SetFontObject(font("QuestFontNormalSmall", "GameFontBlackSmall"))
    r.text:SetJustifyH("LEFT")
    -- Deux ancres horizontales + hauteur fixe : sans ceci un titre long s'enroulerait par-dessus la
    -- ligne suivante au lieu d'être simplement tronque.
    r.text:SetWordWrap(false)

    -- Tag de quête, ALIGNÉ À DROITE comme le `$parentTag` de QuestLogTitleButtonTemplate. Le titre
    -- vient buter contre lui : c'est le titre qui se tronque, jamais le tag qui disparaît.
    r.tag = r:CreateFontString(nil, "OVERLAY")
    r.tag:SetFontObject(font("QuestFontNormalSmall", "GameFontBlackSmall"))
    r.tag:SetJustifyH("RIGHT"); r.tag:SetWordWrap(false)
    r.tag:SetPoint("RIGHT", r, "RIGHT", -4, 0)
    r.tag:Hide()

    local hl = r:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(); hl:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
    hl:SetBlendMode("ADD"); hl:SetAlpha(0.35)

    r.sel = r:CreateTexture(nil, "BACKGROUND")
    r.sel:SetAllPoints(); r.sel:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
    r.sel:SetBlendMode("ADD"); r.sel:SetVertexColor(0.7, 0.55, 0.2); r.sel:Hide()

    r:SetScript("OnClick", function(row) if row.onClick then row.onClick() end end)
    self.rows[i] = r
    return r
end

-- Le bord DROIT du titre est posé par chaque peintre, pas ici : avec un tag il vient buter contre
-- lui, sans tag il va jusqu'au bord. Deux SetPoint concurrents sur le même point seraient ambigus.
local function resetRow(r, indent)
    r.text:ClearAllPoints()
    r.text:SetPoint("LEFT", r, "LEFT", indent, 0)
    r.icon:Hide(); r.tag:Hide(); r.onClick = nil; r.sel:Hide()
    r:Show()
end

-- En-tête de section : le [-]/[+] de `QuestLogTitleButtonTemplate` et le libellé, comme le journal natif.
function Win:_PaintHeader(r, key, label, count)
    resetRow(r, ROW_H + 2)
    local col = collapsed(key)
    r.icon:SetTexture(col and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-UP")
    r.icon:Show()
    -- QuestFont (medium) et non QuestTitleFont : ce dernier est le « Huge » du cadre de quête, il
    -- déborde d'une ligne de liste. La distinction avec les entrées se fait par la graisse et le [-].
    r.text:SetFontObject(font("QuestFont", "GameFontNormal"))
    r.text:SetPoint("RIGHT", r, "RIGHT", -4, 0)
    r.text:SetText(label .. " (" .. count .. ")")
    r.text:SetTextColor(0, 0, 0)
    r.onClick = function() toggle(key) end
end

function Win:_PaintEntry(r, label, done, onClick, selected, tag)
    resetRow(r, ROW_H + 10)
    r.text:SetFontObject(font("QuestFontNormalSmall", "GameFontBlackSmall"))
    if tag and tag ~= "" then
        r.tag:SetText("(" .. tag .. ")")
        r.tag:SetTextColor(0.42, 0.33, 0.16)
        r.tag:Show()
        r.text:SetPoint("RIGHT", r.tag, "LEFT", -6, 0)
    else
        r.text:SetPoint("RIGHT", r, "RIGHT", -4, 0)
    end
    r.text:SetText(label)
    if done then r.text:SetTextColor(0.15, 0.42, 0.15) else r.text:SetTextColor(0, 0, 0) end
    r.onClick = onClick
    r.sel:SetShown(selected and true or false)
end

-- ------------------------------------------------------------------
-- Remplissage de la liste
-- ------------------------------------------------------------------
-- Les COMMANDES d'abord (c'est notre journal), puis les quêtes du jeu — l'ordre de priorité de
-- COC.Journal est conservé tel quel : une seule définition de ce qui passe avant quoi.
function Win:_FillOrders(n)
    local groups = (COC.Journal and COC.Journal:Grouped()) or {}
    for _, g in ipairs(groups) do
        local key = "ord:" .. g.section
        self:_PaintHeader(self:_Row(n), key, g.title, #g.entries); n = n + 1
        if not collapsed(key) then
            for _, e in ipairs(g.entries) do
                local sel = self.sel and self.sel.kind == "order" and self.sel.key == e.key
                self:_PaintEntry(self:_Row(n), e.title, e.complete,
                    function() Win:Select("order", e.key) end, sel)
                n = n + 1
            end
        end
    end
    return n
end

function Win:_FillQuests(n)
    local groups = (COC.JournalQuests and COC.JournalQuests:Groups()) or {}
    for _, g in ipairs(groups) do
        local key = "qst:" .. (g.header or "?")
        self:_PaintHeader(self:_Row(n), key, g.header or "?", #g.quests); n = n + 1
        -- `g.collapsed` = replié DANS LE JOURNAL DU JEU : ses quêtes ne sont même pas énumérées. On
        -- n'y touche pas (cf. JournalQuests, piège 2) ; notre propre repli s'ajoute par-dessus.
        if not collapsed(key) then
            for _, q in ipairs(g.quests) do
                local sel = self.sel and self.sel.kind == "quest" and self.sel.key == q.index
                self:_PaintEntry(self:_Row(n), q.title, q.complete,
                    function() Win:Select("quest", q.index, q) end, sel, q.tag)
                n = n + 1
            end
        end
    end
    return n
end

function Win:Refresh()
    if not (self.frame and self.frame:IsShown()) then return end
    local n = self:_FillOrders(1)
    n = self:_FillQuests(n)
    for i = n, #(self.rows or {}) do self.rows[i]:Hide() end
    self.content:SetHeight(math.max((n - 1) * ROW_H, 1))
    self:_FillDetail()
end

-- ------------------------------------------------------------------
-- Volet de détail — le contenu de QuestSheet, encastré
-- ------------------------------------------------------------------
function Win:Select(kind, key, extra)
    self.sel = { kind = kind, key = key, extra = extra }
    if kind == "order" and COC.Orders and COC.Orders.RequestText then
        local id = tostring(key):match("^%a+:(.+)$")
        if id then COC.Orders:RequestText(id) end   -- la description arrive peut-être après
    end
    self:Refresh()
end

-- Détail d'une entrée du modèle. On part de l'ENTRÉE (pas de la commande) : le journal liste aussi
-- des choses qui n'ont pas de commande derrière — l'étape de montée de métier, par exemple — et
-- elles doivent s'ouvrir comme les autres, pas afficher un volet vide.
local function entryData(key)
    local found
    for _, e in ipairs((COC.Journal and COC.Journal:Entries()) or {}) do
        if e.key == key then found = e; break end
    end
    if not found then return nil end
    local o = found.order
    local objs = {}
    for _, ob in ipairs(found.objectives or {}) do
        local nm = (ob.itemID and GetItemInfo and GetItemInfo(ob.itemID)) or ("item:" .. tostring(ob.itemID))
        objs[#objs + 1] = { text = nm .. ": " .. ob.have .. "/" .. ob.need, done = ob.done }
    end
    if #objs == 0 then objs[1] = { text = found.title, done = found.complete } end
    -- Une entrée sans narratif garde son libellé de liste comme titre : mieux qu'un « Sans titre ».
    return {
        title = (o and o.title) or found.title,
        text  = (o and o.text) or (found.notes and table.concat(found.notes, "\n")) or nil,
        objectives = objs,
        reward = o and o.price or nil,
        giver  = (o and o.buyer) or found.sub,
    }
end

local function questData(index, entry)
    local Q = COC.JournalQuests
    local d = Q and Q:Detail(index)
    if not d then return nil end
    return { title = entry and entry.title, text = d.description,
             objectives = d.lines, giver = Q:GiverLine(entry) }
end

function Win:_FillDetail()
    local c = self.detail
    if not c then return end
    local data
    if self.sel and self.sel.kind == "order" then data = entryData(self.sel.key)
    elseif self.sel and self.sel.kind == "quest" then data = questData(self.sel.key, self.sel.extra) end
    COC.QuestSheet:FillContent(c, data or { title = L["Sans titre"], text = L["Choisis une entrée à gauche."] })
end

-- ------------------------------------------------------------------
-- Fenêtre
-- ------------------------------------------------------------------
function Win:Frame()
    if self.frame then return self.frame end
    local f = CreateFrame("Frame", NAME, UIParent, "BackdropTemplate")
    f:SetSize(W, H); f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH"); f:SetToplevel(true)
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    if f.SetBackdrop then
        f:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
                        insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    end
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 5, -5); bg:SetPoint("BOTTOMRIGHT", -5, 5)
    COC.QuestSheet.ApplyParchment(bg)   -- même parchemin que la fiche : une seule surface visuelle

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 0, 0)
    close:SetScript("OnClick", function() Win:Hide() end)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFontObject(font("QuestTitleFont", "GameFontNormalLarge"))
    title:SetPoint("TOP", 0, -16); title:SetText(L["Journal"])
    title:SetTextColor(0, 0, 0)

    self.frame = f
    self:_BuildPanes(f)
    -- Les seuls événements qui changent VRAIMENT le contenu : le journal de quêtes du jeu, et les
    -- sacs (les compteurs de réactifs). Enregistrés seulement pendant que la fenêtre est ouverte —
    -- un journal fermé n'a aucune raison de recalculer une route de métier.
    f:SetScript("OnEvent", function() Win:Refresh() end)
    f:SetScript("OnShow", function(fr)
        fr:RegisterEvent("QUEST_LOG_UPDATE"); fr:RegisterEvent("BAG_UPDATE_DELAYED")
    end)
    f:SetScript("OnHide", function(fr) fr:UnregisterAllEvents() end)
    if UISpecialFrames then tinsert(UISpecialFrames, NAME) end
    f:Hide()
    return f
end

function Win:_BuildPanes(f)
    local scroll = CreateFrame("ScrollFrame", "COCJournalScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 18, -50)
    scroll:SetSize(LEFT_W, H - 74)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(LEFT_W - 4, 10)
    scroll:SetScrollChild(content)
    self.scroll, self.content = scroll, content

    -- Réglure verticale : une simple ligne brune, PAS `UI-HorizontalBreak` retourné. Cet art est
    -- peint horizontalement (volutes aux extrémités) ; étiré sur 370 px de haut il rendrait une
    -- traînée, pas un séparateur. Sur du parchemin, une réglure fine est de toute façon le bon geste.
    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetWidth(2)
    if sep.SetColorTexture then sep:SetColorTexture(0.28, 0.20, 0.11, 0.45)
    else sep:SetTexture(0.28, 0.20, 0.11, 0.45) end
    sep:SetPoint("TOP", scroll, "TOPRIGHT", 30, 0)
    sep:SetPoint("BOTTOM", scroll, "BOTTOMRIGHT", 30, 0)

    local pane = CreateFrame("Frame", nil, f)
    pane:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 46, 6)
    pane:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 16)
    self.detailPane = pane
    self.detail = COC.QuestSheet:BuildContent(pane, { buttons = false, close = false })
end

function Win:Show()
    self:Frame():Show()
    self:Refresh()
end

function Win:Hide() if self.frame then self.frame:Hide() end end

function Win:Toggle()
    local f = self:Frame()
    if f:IsShown() then self:Hide() else self:Show() end
end
