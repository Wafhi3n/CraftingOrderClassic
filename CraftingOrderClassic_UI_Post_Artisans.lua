-- CraftingOrderClassic_UI_Post_Artisans.lua — onglet « Commande », section droite basse :
-- boutons source, liste des artisans, ciblage (@Nom), libellé destinataire, bouton Poster.
-- Extrait de _UI_Post.lua (2026-07-02, anti-monolithe) : partage le même namespace UI.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local ARH = 26    -- hauteur ligne artisan (= locale de _UI_Post.lua, layout identique)
local SEP = 308
local RX  = SEP + 8
local REDGE = 846
local RW  = 818 - RX

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

-- knowsProf : métier connu via SK (sans fenêtre) OU RK. inSource : liste source (Amis/Guilde via
-- drapeaux de relation → un ajouté aussi ami compte dans Amis), sinon catégorie d'affichage.
local function knowsProf(r, p) return (r.skill and r.skill[p]) or (r.recipes and r.recipes[p]) or false end
local function inSource(r, src)
    -- « confed » (display-only, onglet Artisans) n'est pas une portée de post → on le traite comme « recent »
    -- ici pour que les confédérés restent sélectionnables sous « Croisés ».
    return (src == "friend" and r.isFriend) or (src == "guild" and r.isGuild)
        or (r.source == "confed" and "recent" or r.source or "recent") == src
end

-- Prédicat de filtrage des plans par l'artisan ciblé (postTarget = "@Nom") pour ce métier, ou nil
-- si aucune donnée exploitable (on ne filtre alors pas). Deux niveaux de précision, du plus fiable
-- au repli :
--   * RK reçu (bitfield des recettes CONNUES) → filtre EXACT : seulement ce qu'il sait déjà faire.
--     UNIQUEMENT si sa dataVersion == la nôtre (r.recipeDV) : sinon les positions de bits sont
--     décalées et HasBit renverrait n'importe quoi (typiquement une liste VIDE). Même discipline
--     que Directory:WhoCanCraft. En cas de mismatch on ne jette pas la cible : on retombe sur le SK.
--   * sinon SK reçu (niveau de métier, sk[1]=rang courant) → filtre par learnedAt <= rang : ce qu'il
--     PEUT apprendre/faire à son niveau (masque les plans hors de portée — ex. plan 300 pour un
--     artisan niv. 40, cf. données learnedAt de CraftLink v6). Un plan sans learnedAt connu passe.
-- Retourne aussi un libellé de mode ("connus" | "niv. N") pour l'en-tête de la liste.
function UI:_TargetArtisanFilter(prof)
    local t = self.postTarget
    if not t or t:sub(1, 1) ~= "@" then return nil end
    local c = CL(); if not c then return nil end
    local D = COC.Directory
    local r = D and D.roster and D.roster[t:sub(2)]
    if not r then return nil end
    local hex = r.recipes and r.recipes[prof]
    if hex and hex ~= "" and r.recipeDV == c:DataVersion() then
        return function(spellID) return c:HasBit(prof, hex, spellID) end, L["connus"]
    end
    local sk = r.skill and r.skill[prof]
    if sk and sk[1] then
        local cap = sk[1]
        return function(spellID)
            local at = c:RecipeLearnedAt(prof, spellID)
            return (not at) or at <= cap
        end, string.format(L["niv. %d"], cap)
    end
    return nil
end

function UI:_BuildPostArtisanSection(panel)
    local srcDefs = { {id="guild", label=L["Guilde"]}, {id="friend", label=L["Amis"]}, {id="added", label=L["Ajoutés"]}, {id="recent", label=L["Croisés"]} }
    self.postSrcBtns = {}
    for i, d in ipairs(srcDefs) do
        local b = Skin.MakeGoldButton(panel, 58, 20, d.label); b:SetPoint("TOPLEFT", RX + (i-1)*62, -337)
        b:SetScript("OnClick", function()
            UI.postSource = d.id; UI.postTarget = d.id   -- cibler TOUTE cette liste
            UI:_RefreshPostSrcTabs(); UI:RefreshPostArtisans(); UI:RefreshPostPlans()
        end)
        self.postSrcBtns[d.id] = b
    end
    self.postSource = "guild"; self.postTarget = "all"; self:_RefreshPostSrcTabs()

    local diffBtn = Skin.MakeGoldButton(panel, 124, 20, L["Diffuser à tous"]); diffBtn:SetPoint("TOPRIGHT", -22, -337)
    local diffIc = diffBtn:CreateTexture(nil, "OVERLAY"); diffIc:SetSize(14, 14)
    diffIc:SetPoint("LEFT", 5, 0); diffIc:SetTexture(Skin.tex.broadcast)
    diffBtn.text:ClearAllPoints(); diffBtn.text:SetPoint("LEFT", 22, 0); self.postDiffBtn = diffBtn
    -- Sélectionne la cible « Tous » (diffusion globale) ; on poste ensuite via « Poster » (iso Récolte).
    diffBtn:SetScript("OnClick", function()
        UI.postTarget = "all"; UI:RefreshPostArtisans(); UI:RefreshPostPlans()
    end)

    -- Ligne « Toute la guilde / Tous les amis » épinglée en tête + liste (cf. UI:_BuildAllRowAndScroll).
    self:_BuildAllRowAndScroll(panel, "COCPostArtScroll", "post", -360)

    local artLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    artLbl:SetPoint("TOPLEFT", RX, -495); artLbl:SetText("|cFFE8B84B" .. L["Destinataire :"] .. "|r"); Skin.ApplyShadow(artLbl)
    self.postArtisanName = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.postArtisanName:SetPoint("LEFT", artLbl, "RIGHT", 6, 0); Skin.ApplyShadow(self.postArtisanName)
    self:_UpdateArtisanLabel()

    local posterBtn = Skin.MakeGoldButton(panel, 82, 24, L["Poster"]); posterBtn:SetPoint("BOTTOMRIGHT", -22, 36)
    posterBtn:SetScript("OnClick", function() UI:DoPostOrder() end)

    self.postSelLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.postSelLbl:SetPoint("BOTTOMLEFT", RX, 40); self.postSelLbl:SetWidth(RW - 100); self.postSelLbl:SetJustifyH("LEFT")
    self.postSelLbl:SetText("|cFF888888" .. L["Choisis un métier puis un plan."] .. "|r")
end

function UI:_RefreshPostSrcTabs()
    for id, b in pairs(self.postSrcBtns or {}) do b:SetSelected(id == self.postSource) end
end

function UI:RefreshPostArtisans()
    local D = COC.Directory; if not (D and self.postArtContent) then return end
    local src, prof = self.postSource or "guild", self.postProf
    local list = {}
    for name, r in pairs(D.roster or {}) do
        if inSource(r, src) and (not prof or knowsProf(r, prof)) then
            list[#list+1] = {name=name, r=r, online=D.online[name]}
        end
    end
    table.sort(list, function(a, b)
        if (a.online and true) ~= (b.online and true) then return a.online end
        return a.name < b.name
    end)
    local n = 0
    for _, a in ipairs(list) do
        n = n + 1; local row = self:_PostArtRow(n)
        local sk = a.r.skill and prof and a.r.skill[prof]
        local skTxt = sk and ("|cFF888888"..sk[1].."/"..sk[2].."|r  ") or ""
        local profs2 = {}
        for p2 in pairs(a.r.recipes or {}) do profs2[#profs2+1] = Skin.ProfLabel(p2) end
        row.dot:SetOnline(a.online and true or false)
        row.name:SetText("|cFFFFFFFF"..a.name.."|r  "..skTxt.."|cFF888888"..table.concat(profs2, " · ").."|r")
        row.src:SetText("|cFF888888"..(a.r.source or "recent"):upper().."|r")
        row.artEntry = a
        row.selTex:SetShown(UI.postTarget == "@" .. a.name)
        row:SetScript("OnClick", function()
            UI.postTarget = "@" .. a.name
            -- Sollicite le registre FRAIS de l'artisan (RK+SK à jour, bonne dataVersion) au lieu de se
            -- fier au cache éventuellement périmé : HI/PING dirigés → il répond via AnnounceTo, OnRK
            -- rafraîchit la liste. Throttlé 60 s/nom. Seulement s'il est en ligne (offline = pas de réponse).
            if a.online and COC.Directory and COC.Directory.DiscoverPlayer then
                COC.Directory:DiscoverPlayer(a.name)
            end
            UI:RefreshPostArtisans(); UI:RefreshPostPlans()
        end)
        row:Show()
    end
    for i = n+1, #self.postArtRows do self.postArtRows[i]:Hide() end
    self.postArtContent:SetHeight(math.max(n * ARH, 10))
    Skin.AutoHideScroll("COCPostArtScroll", self.postArtContent)
    self:_RefreshAllRow("post"); self:_UpdateArtisanLabel()
end

function UI:_PostArtRow(i)
    local r = self.postArtRows[i]; if r then return r end
    r = CreateFrame("Button", nil, self.postArtContent); r:SetSize(RW - 22, ARH); r:SetPoint("TOPLEFT", 0, -(i-1)*ARH)
    local hi = r:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints(); hi:SetColorTexture(Skin.unpack(Skin.color.rowHover))
    local st = r:CreateTexture(nil, "BACKGROUND"); st:SetAllPoints()
    st:SetColorTexture(Skin.color.tabActive[1], Skin.color.tabActive[2], Skin.color.tabActive[3], 0.30)
    st:Hide(); r.selTex = st
    r.dot  = Skin.MakeStatusIcon(r, 14); r.dot:SetPoint("LEFT", 4, 0)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.name:SetPoint("LEFT", 18, 0); r.name:SetWidth(RW - 100); r.name:SetJustifyH("LEFT"); Skin.ApplyShadow(r.name)
    r.src  = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); r.src:SetPoint("RIGHT", -4, 0); Skin.ApplyShadow(r.src)
    self.postArtRows[i] = r; return r
end

-- Valeur CANONIQUE du destinataire (FR, identique sur le réseau ; cf. Orders:VisibleTo). Seuls
-- « Guilde » / « Amis » / @Nom sont routables ; « Ajoutés »/« Croisés » (listes perso, non évaluables
-- par un récepteur) retombent sur « Tous » (diffusion globale).
function UI:_PostTargetLabel()
    local t = self.postTarget or "all"
    if t == "all"        then return "Tous" end
    if t:sub(1, 1) == "@" then return t:sub(2) end
    if t == "guild"      then return "Guilde" end
    if t == "friend"     then return "Amis" end
    return "Tous"
end

function UI:_UpdateArtisanLabel()
    if self.postArtisanName then
        local t = self.postTarget or "all"
        local col = (t == "all") and "FFAAAAAA" or "FFFFFFFF"
        -- Affichage localisé ; la VALEUR canonique (FR) sert au réseau (cf. _PostTargetLabel / DoPostOrder).
        self.postArtisanName:SetText("|c" .. col .. L[self:_PostTargetLabel()] .. "|r")
    end
end
