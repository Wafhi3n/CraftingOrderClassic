-- CraftingOrderClassic_ShareReagents.lua — « liste de courses » : diffuser en un clic les réactifs
-- d'une recette (vue métier) ou d'une commande (carte) dans un canal de discussion, avec le LIEN objet
-- de chaque réactif. Un bouton-icône dans la zone réactifs ouvre cette popup : dropdown de canal
-- (Guilde / Dire / Groupe-Raid / canaux num.) + Envoyer. Le texte envoyé est HUMAIN (lisible en chat),
-- donc localisé dans la langue de l'émetteur — à ne pas confondre avec les verbes réseau neutres.
--
-- ⚠️ SendChatMessage est PROTÉGÉ (hardware-event only) : l'envoi ne part QUE depuis le clic « Envoyer »
-- (vrai événement matériel). Les liens objets sont longs (~60 car.) → on DÉCOUPE en plusieurs lignes
-- sous la limite de 255 octets du chat (buildLines). Le dernier canal choisi est mémorisé (db.shareChannel).

local COC  = CraftingOrderClassic
local Skin = COC.UI.Skin
local L    = COC.L

COC.ShareReagents = COC.ShareReagents or {}
local SR = COC.ShareReagents

local LINE_MAX = 250   -- marge sous la limite serveur de 255 octets par message de chat

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end
local function pmsg(m) print("|cFF33DD88Crafting Order|r " .. m) end

-- Meilleur lien objet possible : lien fourni > lien du client (GetItemInfo) > lien minimal reconstruit.
-- Un lien minimal `|Hitem:ID|h[nom]|h` reste cliquable en jeu (le serveur complète l'objet).
local function resolveLink(it)
    if it.link then return it.link end
    local id = it.id
    if id and GetItemInfo then
        local _, lnk = GetItemInfo(id)
        if lnk then return lnk end
    end
    if id then
        local nm = it.name or (CL() and CL():ItemName(id)) or ("item:" .. id)
        return string.format("|cffffffff|Hitem:%d|h[%s]|h|r", id, nm)
    end
    return it.name
end

-- Normalise la liste brute des deux vues ({link|id|name, qty|need}) en { link, qty } prêts à diffuser.
local function normalize(raw)
    local out = {}
    for _, it in ipairs(raw or {}) do
        local link = resolveLink(it)
        if link then out[#out + 1] = { link = link, qty = it.qty or it.need or 1 } end
    end
    return out
end

-- Découpe les réactifs en lignes de chat ≤ LINE_MAX : la 1re porte le préfixe « Réactifs pour X : »,
-- les suivantes enchaînent les liens. Un lien seul ne se coupe jamais (toujours placé même s'il déborde).
local function buildLines(title, items)
    local prefix = string.format(L["Réactifs pour %s :"], title or "?") .. " "
    local lines, cur = {}, prefix
    for _, it in ipairs(items) do
        local piece = it.link .. ((it.qty and it.qty > 1) and (" ×" .. it.qty) or "")
        local sep = (cur == prefix) and "" or "  "
        if cur ~= prefix and #cur + #sep + #piece > LINE_MAX then
            lines[#lines + 1] = cur; cur = piece
        else
            cur = cur .. sep .. piece
        end
    end
    lines[#lines + 1] = cur
    return lines
end

-- Liste des canaux disponibles pour le dropdown (recalculée à chaque ouverture : rejoindre/quitter un
-- canal ou un groupe la change). GetChannelList() rend des triplets (id, nom, désactivé).
local function channelItems()
    local out = {}
    if IsInGuild and IsInGuild() then out[#out + 1] = { value = "GUILD", text = L["Guilde"] } end
    out[#out + 1] = { value = "SAY", text = L["Dire"] }
    if IsInRaid and IsInRaid() then out[#out + 1] = { value = "RAID", text = L["Raid"] }
    elseif IsInGroup and IsInGroup() then out[#out + 1] = { value = "PARTY", text = L["Groupe"] } end
    if GetChannelList then
        local list = { GetChannelList() }
        for i = 1, #list, 3 do
            local id, nm = list[i], list[i + 1]
            if type(id) == "number" and type(nm) == "string" and nm ~= "" then
                out[#out + 1] = { value = "CH" .. id, text = id .. ". " .. nm }
            end
        end
    end
    return out
end

-- Canal par défaut : le dernier utilisé s'il est encore joint, sinon Guilde, sinon 1er canal num., sinon Dire.
local function defaultChannel(items)
    local saved, firstCH, hasGuild = COC.db and COC.db.shareChannel, nil, false
    for _, it in ipairs(items) do
        if it.value == saved then return saved end
        if it.value == "GUILD" then hasGuild = true end
        if not firstCH and it.value:match("^CH%d") then firstCH = it.value end
    end
    return (hasGuild and "GUILD") or firstCH or "SAY"
end

-- Traduit la valeur du dropdown en couple (chatType, index-canal) pour SendChatMessage.
local function chatTarget(value)
    if value == "GUILD" or value == "SAY" or value == "PARTY" or value == "RAID" then return value end
    local idx = value and value:match("^CH(%d+)$")
    if idx then return "CHANNEL", tonumber(idx) end
end

-- ------------------------------------------------------------------
-- Fenêtre (singleton, native)
-- ------------------------------------------------------------------
function SR:_Build()
    if self.frame then return self.frame end
    local f = Skin.MakeWindow("COC_ShareReagentsWindow", 340, 176, {
        title = L["Diffuser les réactifs"],
        portrait = "Interface\\Icons\\INV_Scroll_03",
        strata = "FULLSCREEN_DIALOG",
    })
    local inset = f.Inset or f
    local summary = inset:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    summary:SetPoint("TOPLEFT", 14, -14); summary:SetPoint("RIGHT", -14, 0)
    summary:SetJustifyH("LEFT"); summary:SetWordWrap(true); f.summary = summary

    local dd = Skin.MakeDropdown("COC_ShareReagentsChannel", inset, 176,
        function() return SR._chanItems or {} end,
        { label = L["Canal : "], onSelect = function(v) if COC.db then COC.db.shareChannel = v end end })
    dd:SetPointVisual("TOPLEFT", inset, "TOPLEFT", 12, -54); f.dd = dd

    local send = Skin.MakeGoldButton(f, 96, 22, L["Envoyer"])
    send:SetPoint("BOTTOMRIGHT", -12, 12)
    send:SetScript("OnClick", function() SR:_DoSend() end)
    local cancel = Skin.MakeGoldButton(f, 84, 22, L["Annuler"])
    cancel:SetPoint("RIGHT", send, "LEFT", -8, 0)
    cancel:SetScript("OnClick", function() f:Hide() end)
    self.frame = f
    return f
end

-- Envoi (sous hardware event du clic « Envoyer ») : construit les lignes et les pousse dans le canal choisi.
function SR:_DoSend()
    local items, title = self._items, self._title
    if not (items and #items > 0) then self.frame:Hide(); return end
    local chatType, chanIdx = chatTarget(self.frame.dd and self.frame.dd.value)
    if not chatType then pmsg(L["choisis un canal valide."]); return end
    for _, line in ipairs(buildLines(title, items)) do
        SendChatMessage(line, chatType, nil, chanIdx)
    end
    self.frame:Hide()
end

-- Point d'entrée public (appelé par les deux vues). `raw` = liste { link|id|name, qty|need }.
function SR:Open(title, raw)
    local items = normalize(raw)
    if #items == 0 then pmsg(L["aucun réactif à diffuser."]); return end
    local f = self:_Build()
    self._title, self._items = title or "?", items
    self._chanItems = channelItems()
    f.summary:SetText(string.format(L["Réactifs pour %s (%d) :"], title or "?", #items))
    f.dd:SetValue(defaultChannel(self._chanItems))
    f:Show()
end
