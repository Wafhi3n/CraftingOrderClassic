-- CraftingOrderClassic_UI_Post_Artisans.lua — onglet « Commande », section droite basse :
-- boutons source, liste des artisans, ciblage (@Nom), libellé destinataire, bouton Poster.
-- Extrait de _UI_Post.lua (2026-07-02, anti-monolithe) : partage le même namespace UI.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

local ARH = 26    -- hauteur ligne artisan (= ALL_ARH de _UI.lua : même pool de lignes)
local P   = UI.POST   -- métriques/blocs de l'onglet — cf. _UI_Post_Layout.lua

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

-- Helpers d'annuaire PARTAGÉS (cf. Skin). knowsProf = VRAIES données réseau (SK/RK) SANS craftSeen :
-- on ne cible une commande que sur un porteur de l'addon. inSource = source Guilde/Amis (drapeaux) ou catégorie.
local knowsProf, inSource = Skin.KnowsProf, Skin.InSource

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
    -- PORTÉE : quatre boutons rouges côte à côte AVANT → un DROPDOWN natif (demande user 2026-07-12).
    -- Même raisonnement que le Carnet : ce sont 4 valeurs EXCLUSIVES (où je cherche l'artisan), pas
    -- 4 actions. La rangée libérée rend sa largeur au bouton « Diffuser à tous », qui RESTE un bouton :
    -- lui n'est pas une portée mais une CIBLE (postTarget = "all") — deux verbes différents, deux widgets.
    -- Comportement inchangé : choisir une portée cible AUSSI toute cette liste (postTarget = source).
    local srcDefs = {
        { value = "guild",  text = L["Guilde"] },
        { value = "friend", text = L["Amis"] },
        { value = "added",  text = L["Ajoutés"] },
        { value = "recent", text = L["Annuaire"] },
    }
    -- Portée + « Diffuser à tous » : leur PROPRE zone (« scope »), juste au-dessus de la liste qu'elles
    -- pilotent — la rangée de commandes d'une liste, comme les filtres au-dessus du browse de l'HdV.
    local scope = self:PostSec("scope")
    local srcDD = Skin.MakeDropdown("COCPostSrcDD", scope, 96, srcDefs, {
        onSelect = function(v)
            UI.postSource = v; UI.postTarget = v   -- cibler TOUTE cette liste
            UI:RefreshPostArtisans(); UI:RefreshPostPlans()
        end,
    })
    srcDD:SetPointVisual("TOPLEFT", scope, "TOPLEFT", P.PAD, -4)
    self.postSrcDD = srcDD
    self.postSource = "guild"; self.postTarget = "all"; self:_RefreshPostSrcTabs()

    -- « Diffuser à tous » = BOUTON-ICÔNE (la bulle bleue du volet Social, pointée par le user) + un
    -- vrai tooltip d'explication — le libellé long vivait mal dans la bande. Le liseré doré
    -- (SetSelected) reflète « cible = Tous » (synchro dans RefreshPostArtisans). L'icône sociale n'a
    -- pas de bordure cuite dedans → on annule le rognage 8 % du kit (pensé pour les icônes d'objets).
    local diffBtn = Skin.MakeIconButton(scope, 22, Skin.tex.broadcast)
    diffBtn.icon:SetTexCoord(0, 1, 0, 1)
    diffBtn:SetPoint("RIGHT", -P.PAD - 4, 0)
    self.postDiffBtn = diffBtn
    -- Sélectionne la cible « Tous » (diffusion globale) ; on poste ensuite via « Poster » (iso Récolte).
    diffBtn:SetScript("OnClick", function()
        UI.postTarget = "all"; UI:RefreshPostArtisans(); UI:RefreshPostPlans()
    end)
    diffBtn:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText(L["Diffuser à tous"], 1, 1, 1)
        GameTooltip:AddLine(L["La commande sera visible par tout le monde (cible « Tous »)."],
            nil, nil, nil, true)
        GameTooltip:Show()
    end)
    diffBtn:SetScript("OnLeave", GameTooltip_Hide)

    -- Ligne « Toute la guilde / Tous les amis » épinglée en tête + liste, DANS la zone artisans (parent =
    -- la zone, offsets relatifs à son bord — cf. _BuildAllRowAndScroll, dont le x est paramétrable).
    -- Largeur LUE sur la zone (SPEC pilote le pad) : la ligne épinglée, le scroll et les rangées
    -- suivent tes réglages de « artisans » dans la SPEC — plus de constante WIDE_W recopiée.
    local az = self:PostSec("artisans")
    local aw = az:GetWidth(); if aw <= 1 then aw = P.WIDE_W end
    self.postArtW = aw
    self:_BuildAllRowAndScroll(az, "COCPostArtScroll", "post", -P.PAD, P.PAD, aw)

    self:_BuildPostActionBar(panel, self:PostSec("artisans"))
end

-- BARRE D'ACTIONS (croquis + maquette GIMP user : « Destinataire » et « Poster » = UN objet, la
-- barre à boutons native du bas de fenêtre). Conteneur parenté au PANNEAU (il se masque avec
-- l'onglet) mais ANCRÉ sur la bande native `f.ActionBar` (MakeWindow, opts.buttonBar). Contenu
-- aligné à droite : [Destinataire : X] [Poster] — la gauche de la bande reste à la ligne réseau.
function UI:_BuildPostActionBar(panel, sec)
    local bar = CreateFrame("Frame", nil, panel)
    bar:SetAllPoints(self.frame.ActionBar)
    local posterBtn = Skin.MakeGoldButton(bar, 82, 20, L["Poster"]); posterBtn:SetPoint("RIGHT", -8, 0)
    posterBtn:SetScript("OnClick", function() UI:DoPostOrder() end)
    self.postBtn = posterBtn   -- exposé pour l'aide contextuelle (bulle « Poster »)
    self.postArtisanName = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.postArtisanName:SetPoint("RIGHT", posterBtn, "LEFT", -14, 0); Skin.ApplyShadow(self.postArtisanName)
    local artLbl = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    artLbl:SetPoint("RIGHT", self.postArtisanName, "LEFT", -6, 0)
    artLbl:SetText("|cFFE8B84B" .. L["Destinataire :"] .. "|r"); Skin.ApplyShadow(artLbl)
    self:_UpdateArtisanLabel()

    -- Statut/aide (« Choisis un métier puis un plan. ») : en bas de la SECTION artisans, plus dans la
    -- barre — c'est un message de l'onglet, pas une action de la fenêtre.
    self.postSelLbl = sec:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.postSelLbl:SetPoint("BOTTOMLEFT", P.PAD, 6); self.postSelLbl:SetWidth((self.postArtW or P.WIDE_W) - 20)
    self.postSelLbl:SetJustifyH("LEFT")
    self.postSelLbl:SetText("|cFF888888" .. L["Choisis un métier puis un plan."] .. "|r")
end

-- Reflète la portée courante dans le dropdown (libellé + coche). Nom conservé : plusieurs appelants.
function UI:_RefreshPostSrcTabs()
    if self.postSrcDD then self.postSrcDD:SetValue(self.postSource or "guild") end
end

function UI:RefreshPostArtisans()
    local D = COC.Directory; if not (D and self.postArtContent) then return end
    local src, prof = self.postSource or "guild", self.postProf
    -- Fusion par joueur vérifié (rerolls → une ligne) ; le CLIC re-résout la cible vers le PERSO
    -- du set qui connaît le métier (cf. UI:_FillPostArtGroupRow / _ResolvePostChar). Le groupe passe
    -- le filtre si n'importe quel perso le passe (union) — KnowsProf STRICT par perso, inchangé.
    local list = self:_ArtisanGroups(function(r)
        return inSource(r, src) and (not prof or knowsProf(r, prof))
    end)
    table.sort(list, function(a, b)
        if (a.onlineChar ~= nil) ~= (b.onlineChar ~= nil) then return a.onlineChar ~= nil end
        return a.leader < b.leader
    end)
    local n = 0
    for _, g in ipairs(list) do
        n = n + 1
        self:_FillPostArtGroupRow(self:_PostArtRow(n), g, prof)
    end
    for i = n+1, #self.postArtRows do self.postArtRows[i]:Hide() end
    self.postArtContent:SetHeight(math.max(n * ARH, 10))
    Skin.AutoHideScroll("COCPostArtScroll", self.postArtContent)
    self:_RefreshAllRow("post"); self:_UpdateArtisanLabel()
    if self.postDiffBtn then self.postDiffBtn:SetSelected((self.postTarget or "all") == "all") end
end

function UI:_PostArtRow(i)
    local r = self.postArtRows[i]; if r then return r end
    r = Skin.MakeArtisanRow(self.postArtContent, (self.postArtW or P.WIDE_W) - 22, ARH)   -- pastille + nom + source (kit)
    r:SetPoint("TOPLEFT", 0, -(i-1)*ARH)
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
    self:_SyncHeaderSkill()   -- la cible a pu changer → la jauge du header suit (niveau de l'artisan visé)
end

-- =========================================================================
-- Ouverture directe sur l'onglet Commande avec un artisan pré-ciblé (menu clic-droit joueur /
-- bouton du panneau de guilde — cf. _Social_Menu.lua / _Social_Roster.lua). Pré-sélectionne un métier
-- CRAFTABLE connu de l'artisan ; le dropdown se corrige de lui-même si c'est une récolte pure
-- (cf. _RefreshProfDropdown). postTarget = "@Nom" → la liste de plans se filtre à ce que l'artisan sait.
-- =========================================================================
function UI:OpenPostForArtisan(name, prof)
    if not (name and name ~= "" and self.frame) then return end
    local D = COC.Directory
    local r = D and D.roster and D.roster[name]
    if prof then
        -- Métier explicite (entrée « Commander <métier> » du menu) : pré-sélection directe. Le dropdown
        -- se corrige seul si ce n'est pas craftable (récolte pure) — cf. _RefreshProfDropdown.
        self.postProf = prof
    elseif r then
        local pick
        for p in pairs(r.skill or {})   do pick = p; break end
        if not pick then for p in pairs(r.recipes or {}) do pick = p; break end end
        if pick then self.postProf = pick end
    end
    self.postTarget = "@" .. name
    if not self.frame:IsShown() then self.frame:Show() end
    self:ShowTab("post")
    self:RefreshPost()
    -- Sollicite le registre FRAIS (RK+SK à jour) si l'artisan est en ligne — throttlé 60 s/nom.
    if r and D.online and D.online[name] and D.DiscoverPlayer then D:DiscoverPlayer(name) end
end
