-- CraftingOrderClassic_UI_Post_Artisans.lua — onglet « Commande », section droite basse : bande
-- « Envoyer à » + menu de la liste, lignes de destinataire (Tous / groupe / artisan), case Commerce,
-- rappel du destinataire, boutons Poster.
-- Extrait de _UI_Post.lua (2026-07-02, anti-monolithe) : partage le même namespace UI.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

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
--     artisan niv. 40, cf. données learnedAt de CraftLink v6). Un plan SANS learnedAt connu est
--     ÉCARTÉ : c'est une ESTIMATION, et elle ne doit jamais affirmer « il sait le faire » sans
--     preuve. L'ancienne règle (« seuil inconnu = atteignable ») était inoffensive tant que la
--     base vanilla était presque complète ; sur Forever elle proposait les six pièces Stormcloth
--     (niveau 40) à un couturier 13/75 (relevé du 2026-09-19). Les 29 recettes Camelot sans seuil
--     sont des PATRONS de butin/marchand — vanilla ne les a pas non plus, on ne peut pas hériter.
--     Un artisan à jour envoie sa vraie liste (RI/RK) : ses patrons connus réapparaissent alors par
--     le 1er niveau, qui n'a pas besoin de seuil.
-- Retourne aussi un libellé de mode ("connus" | "niv. N") pour l'en-tête de la liste.
function UI:_TargetArtisanFilter(prof)
    local t = self.postTarget
    if not t or t:sub(1, 1) ~= "@" then return nil end
    local c = CL(); if not c then return nil end
    local D = COC.Directory
    local r = D and D.roster and D.roster[t:sub(2)]
    if not r then return nil end
    local D = COC.Directory
    local test = D and D.RecipeTester and D:RecipeTester(r, prof)
    if test then return test, L["connus"] end
    local sk = r.skill and r.skill[prof]
    if sk and sk[1] then
        local cap = sk[1]
        return function(spellID)
            local at = c:RecipeLearnedAt(prof, spellID)
            return at ~= nil and at <= cap   -- seuil inconnu = PAS de preuve = écarté (cf. en-tête)
        end, string.format(L["niv. %d"], cap)
    end
    return nil
end

function UI:_BuildPostArtisanSection(panel)
    -- LE DESTINATAIRE (piste 2 de la maquette, choisie par le user le 2026-09-30) : la bande
    -- « Envoyer à » + le menu de la liste affichée (UI:_BuildRecipientBand), puis la liste où chaque
    -- destinataire est une ligne (UI:_BuildAllRowAndScroll) : « Tous », toute la guilde / tous les
    -- amis, un artisan. Changer de liste ne change pas le destinataire (Skin.TargetAfterListChange).
    self.postSource = "guild"; self.postTarget = "all"
    self.postSrcDD = self:_BuildRecipientBand(self:PostSec("scope"), "COCPostSrcDD", P.PAD, function(v)
        UI.postSource = v; UI.postTarget = Skin.TargetAfterListChange(UI.postTarget, v)
        UI:RefreshPostArtisans(); UI:RefreshPostPlans()
    end)
    self:_RefreshPostSrcTabs()

    -- Lignes épinglées + liste, DANS la zone artisans, à la largeur LUE sur la zone (la SPEC pilote
    -- le pad). La liste descend jusqu'en bas : le statut vit désormais dans le détail du plan.
    local az = self:PostSec("artisans")
    local aw = az:GetWidth(); if aw <= 1 then aw = P.WIDE_W end
    self.postArtW = aw
    self:_BuildAllRowAndScroll(az, "post", -P.PAD, P.PAD, aw, {
        fill    = function(row, it) UI:_FillPostArtGroupRow(row, it.g, it.prof) end,
        bottom  = 4,
        caption = L["ou un artisan"],
    })
    self:_BuildAnnounceCheck(self.postPinned.all)

    self:_BuildPostActionBar(panel)
end

-- BARRE D'ACTIONS (croquis + maquette GIMP user : « Destinataire » et « Poster » = UN objet, la
-- barre à boutons native du bas de fenêtre). Conteneur parenté au PANNEAU (il se masque avec
-- l'onglet) mais ANCRÉ sur la bande native `f.ActionBar` (MakeWindow, opts.buttonBar). Contenu
-- aligné à droite : [Destinataire : X] [Poster] — la gauche de la bande reste à la ligne réseau.
-- Le destinataire n'y est plus qu'un RAPPEL, lu avant « Poster » : il se choisit dans la liste.
function UI:_BuildPostActionBar(panel)
    local bar = CreateFrame("Frame", nil, panel)
    bar:SetAllPoints(self.frame.ActionBar)
    local posterBtn = Skin.MakeGoldButton(bar, 82, 20, L["Poster"]); posterBtn:SetPoint("RIGHT", -8, 0)
    posterBtn:SetScript("OnClick", function() UI:DoPostOrder() end)
    self.postBtn = posterBtn   -- exposé pour l'aide contextuelle (bulle « Poster »)
    -- Seconde voie de post : la commande devient une QUÊTE (titre + récit), écrite dans la fiche
    -- parchemin. Bouton séparé plutôt que des champs dans la colonne : le narratif est optionnel et
    -- ne doit pas rogner la liste d'artisans de ceux qui ne s'en servent pas.
    -- 140 et non 124 : l'espagnol dit « Publicar como misión », le plus long des trois overlays.
    local questBtn = Skin.MakeGoldButton(bar, 140, 20, L["Poster en quête"])
    questBtn:SetPoint("RIGHT", posterBtn, "LEFT", -6, 0)
    questBtn:SetScript("OnClick", function() UI:DoPostAsQuest() end)
    self.postQuestBtn = questBtn
    self.postArtisanName = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.postArtisanName:SetPoint("RIGHT", questBtn, "LEFT", -14, 0); Skin.ApplyShadow(self.postArtisanName)
    local artLbl = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    artLbl:SetPoint("RIGHT", self.postArtisanName, "LEFT", -6, 0)
    artLbl:SetText("|cFFE8B84B" .. L["Destinataire :"] .. "|r"); Skin.ApplyShadow(artLbl)
    self:_UpdateArtisanLabel()
end

-- Case « Annoncer en Commerce » (spec annonce-commerce) : DANS la ligne « Tous » (piste 2 de la
-- maquette, 2026-09-30) — elle ne sert qu'à une commande à tous, elle le montre par sa place. Elle
-- vivait en bas, loin de la bulle, et restait cochable pour une commande privée que « Poster »
-- refusait ensuite d'annoncer. Décochée au départ, le dernier choix est retenu (COC.db.announceTrade,
-- décision du user, 2026-09-29) ; grisée ailleurs que « Tous » et hors d'une capitale (_SyncAnnounceCheck).
function UI:_BuildAnnounceCheck(row)
    local chk = Skin.MakeCheckButton(row, L["Annoncer en Commerce"], 18)
    chk:SetScript("OnClick", function(b)
        if COC.db then COC.db.announceTrade = b:GetChecked() and true or nil end
        UI:_UpdateArtisanLabel()   -- le rappel du bas dit « + Commerce »
    end)
    -- Le même réglage se coche aussi dans l'offre de dispo (PW:_BuildLFWChecks) : relu à chaque affichage.
    chk:SetScript("OnShow", function() UI:_UpdateArtisanLabel() end)
    chk:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_TOP")
        GameTooltip:SetText(L["Annoncer en Commerce"], 1, 1, 1)
        GameTooltip:AddLine(L["Poste aussi une ligne sur Trade (Services), lisible par tous : les joueurs avec ou sans l'addon voient ta commande. Une ligne par clic, jamais de répétition automatique ; seulement pour une commande à tous, dans une capitale."], nil, nil, nil, true)
        GameTooltip:Show()
    end)
    chk:SetScript("OnLeave", GameTooltip_Hide)
    self.postAnnChk = chk
    -- Entrer dans une capitale, ou en sortir, change la case sans autre geste du joueur : la liste des
    -- canaux du client bouge (CHANNEL_UI_UPDATE, celui qu'écoute la fenêtre des canaux de Blizzard).
    -- Relu seulement quand le formulaire est à l'écran ; sinon l'OnShow de la case s'en charge.
    local watch = CreateFrame("Frame", nil, row)
    pcall(watch.RegisterEvent, watch, "CHANNEL_UI_UPDATE")
    watch:SetScript("OnEvent", function() if chk:IsVisible() then UI:_UpdateArtisanLabel() end end)
end

-- La case suit le destinataire et la ville (Skin.AnnounceState). Hors d'une capitale, son libellé
-- le dit. Ancrée depuis le bord droit de la ligne à la largeur de son texte (le libellé est À DROITE
-- de la case, et il change). Rend true si la commande partira aussi sur Commerce.
function UI:_SyncAnnounceCheck()
    local chk = self.postAnnChk; if not chk then return false end
    local S = COC.AnnounceSend
    local inTown = (S and S.ChannelIndex and S.ChannelIndex()) ~= nil
    local on, checked = Skin.AnnounceState(COC.db and COC.db.announceTrade, self.postTarget, inTown)
    chk.text:SetText(inTown and L["Annoncer en Commerce"] or L["Annoncer en Commerce (en capitale)"])
    chk:ClearAllPoints(); chk:SetPoint("RIGHT", chk:GetParent(), "RIGHT", -(chk.text:GetStringWidth() + 8), 0)
    chk:SetEnabled(on); chk:SetChecked(checked)
    if on then chk.text:SetTextColor(1, 1, 1) else chk.text:SetTextColor(Skin.unpack(Skin.color.textMuted)) end
    return checked
end

-- Reflète la portée courante dans le dropdown (libellé + coche). Nom conservé : plusieurs appelants.
function UI:_RefreshPostSrcTabs()
    if self.postSrcDD then self.postSrcDD:SetValue(self.postSource or "guild") end
end

function UI:RefreshPostArtisans()
    local D = COC.Directory; if not (D and self.postArtList) then return end
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
    -- Rang du groupe ciblé, pour que OpenPostForArtisan le fasse défiler à l'écran. Calculé ICI, sur
    -- les données : la liste défilante ne remplit que les lignes visibles, une ligne hors champ n'a
    -- jamais été remplie et ne peut donc pas dire si elle est sélectionnée. Même règle que
    -- _FillPostArtGroupRow : le groupe est ciblé si UN de ses persos l'est.
    local items = {}
    self._postSelIdx = nil
    for i, g in ipairs(list) do
        items[i] = { g = g, prof = prof }
        for _, m in ipairs(g.members) do
            if self.postTarget == "@" .. m.name then self._postSelIdx = i end
        end
    end
    self.postArtList:SetData(items, true)
    self:_RefreshAllRow("post"); self:_UpdateArtisanLabel()
end

-- Amène la ligne ciblée dans la fenêtre de la liste : triée en ligne d'abord puis par nom, elle peut
-- tomber bien plus bas, et une sélection hors champ ne se voit pas. La liste défilante sait viser
-- une donnée par son rang et borner elle-même ; « au plus près » ne bouge rien si elle est déjà visible.
function UI:_ScrollPostArtToTarget()
    local list, idx = self.postArtList, self._postSelIdx
    if not list then return end
    if idx then
        list.box:ScrollToElementDataIndex(idx, ScrollBoxConstants.AlignNearest)
    else
        list.box:ScrollToBegin()
    end
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
    local trade = self:_SyncAnnounceCheck()   -- la case suit le destinataire
    if self.postArtisanName then
        local t = self.postTarget or "all"
        local col = (t == "all") and "FFAAAAAA" or "FFFFFFFF"
        -- Affichage localisé ; la VALEUR canonique (FR) sert au réseau (cf. _PostTargetLabel / DoPostOrder).
        -- Le rappel dit aussi la ligne sur Commerce : c'est la dernière chose lue avant « Poster ».
        local txt = "|c" .. col .. L[self:_PostTargetLabel()] .. "|r"
        if trade then txt = txt .. "|cFFAAAAAA + |r|cFFFFFFFF" .. L["Commerce"] .. "|r" end
        self.postArtisanName:SetText(txt)
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
    -- La portée suit l'artisan : restée sur « Guilde », la liste excluait quelqu'un de l'annuaire, et
    -- la cible était posée sans que sa ligne existe (cf. Skin.PostSourceFor).
    self.postSource = Skin.PostSourceFor(r, self.postSource or "guild")
    self:_RefreshPostSrcTabs()
    if not self.frame:IsShown() then self.frame:Show() end
    self:ShowTab("post")
    self:RefreshPost()
    self:_ScrollPostArtToTarget()
    -- Sollicite le registre FRAIS (RK+SK à jour) si l'artisan est en ligne — throttlé 60 s/nom.
    if r and D.online and D.online[name] and D.DiscoverPlayer then D:DiscoverPlayer(name) end
end
