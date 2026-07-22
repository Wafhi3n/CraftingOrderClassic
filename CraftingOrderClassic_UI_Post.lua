-- CraftingOrderClassic_UI_Post.lua — onglet « Commande » : sélection de plan (gauche) +
-- réactifs « je fournis » / commission g-s-c / ciblage artisan (droite). Chargé après _UI.lua.
-- GÉOMÉTRIE : les blocs de section et les métriques vivent dans _UI_Post_Layout.lua (chargé avant).
-- Ici, chaque zone se parente à SON bloc (`UI:PostSec(id)`) et s'ancre en coordonnées RELATIVES au
-- bloc — plus aucun offset absolu de panneau (cf. l'en-tête du fichier Layout pour le pourquoi).

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L   -- localisation du chrome (clé = FR ; overlay enUS). NB : les VALEURS canoniques
                     -- de destinataire restent en FR (clé) pour rester identiques sur le réseau.

local PLH = 20    -- hauteur ligne plan (en-tête de section INCLUS : pool virtualisé homogène)
-- (hauteur de ligne réactif RRH : déplacée dans _UI_Post_Detail.lua avec la liste des réactifs.)
-- Liste des plans VIRTUALISÉE : pool FIXE de lignes physiques réutilisées au scroll (ne dépend plus
-- du nb de plans → ~28 frames au lieu de ~300 en Couture). INVARIANT (cf. ProfWindow_Recipes) : VISIBLE
-- doit être ≥ au nb de lignes que le viewport peut afficher, sinon la queue de liste est inatteignable.
-- Viewport re-mesuré après le passage des filtres sur UNE ligne (2026-07-12, la liste a regagné cette
-- hauteur) : ≈ 452 px / 20 ≈ 23 lignes → 28 avec marge.
local VISIBLE = 28

-- Filtre qualité MINIMALE (cycle) : false = Toutes, sinon seuil WoW (2=Inhabituel, 3=Rare, 4=Épique).
-- Les NOMS de qualité sont localisés par le client via _G["ITEM_QUALITY<n>_DESC"] (zéro clé à baker).
local QUALITY_STEPS = { false, 2, 3, 4 }

local P = UI.POST   -- métriques partagées de l'onglet (PAD, largeurs de listes) — cf. _UI_Post_Layout.lua

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end
local function isSoulbound(id) return id and GetItemInfo and select(14, GetItemInfo(id)) == 1 end

local function entryName(e)
    local c = CL(); if not c then return "?" end
    return e.itemID and c:ItemName(e.itemID) or c:RecipeName(e.spellID)
end

-- P2 : ai-je déjà TOUS les réactifs de cette recette dans mes sacs (GetItemCount, sacs seuls) ?
-- false si la recette n'a pas de données `reagents` (CraftLink v6, cf. tools/gen_metadata.lua) —
-- on ne peut alors ni confirmer ni infirmer, donc on ne la propose pas comme « prête ».
-- `countCache` (optionnel) mémoïse GetItemCount par itemID le temps d'UN refresh : un même réactif
-- (ex. Bolt of Cloth) apparaît dans des dizaines de plans → sans cache on rappelait GetItemCount
-- des centaines de fois par rafraîchissement de la liste.
local function bagCount(id, cache)
    if not cache then return GetItemCount(id, false) or 0 end
    local v = cache[id]
    if v == nil then v = GetItemCount(id, false) or 0; cache[id] = v end
    return v
end
local function hasReagentsInBags(c, prof, spellID, countCache)
    local reag = spellID and c:RecipeReagents(prof, spellID)
    if not reag or #reag == 0 then return false end
    for _, rg in ipairs(reag) do
        if bagCount(rg[1], countCache) < rg[2] then return false end
    end
    return true
end
-- =========================================================================
-- Construction principale
-- =========================================================================
function UI:BuildPostTab(f)
    local panel = CreateFrame("Frame", nil, f); self.insetPanel(panel, f); panel:Hide()
    self.postPanel   = panel
    self.postProvide = {}
    self.postTarget  = "all"
    self.postSource  = "guild"

    self:_BuildPostSections(panel)   -- les zones (Layout) : elles deviennent les PARENTS du contenu
    self:_BuildPostLeft()
    self:_BuildPostRight(panel)      -- `panel` : seule la bande basse (Poster/statut) reste hors blocs
    -- (résolution des noms async : handler central dans _UI.lua)
end

-- Professions de récolte pure (aucune recette) → exclues de l'onglet Commande, elles vivent
-- dans l'onglet Récolte. Mining reste ici (fonte = recettes) ET dans Récolte (minerais).
local GATHER_ONLY = COC.GATHER_ONLY   -- source partagée (cf. CraftingOrderClassic.lua)

-- =========================================================================
-- Panneau gauche : dropdown métier + liste des plans
-- =========================================================================
-- Le CHOIX du métier se fait au clic sur le PORTRAIT de la fenêtre (Skin.SetPortraitClickable, câblé
-- dans UI.lua ; flèche d'affordance sur cet onglet). Le NOM du métier s'affiche dans la barre de titre
-- à droite du portrait (UI:_SyncMainPortrait) — plus de label dans le panneau : la liste des plans
-- démarre tout en haut.
function UI:_BuildPostLeft()
    local sec = self:PostSec("plans")   -- bloc « liste des plans » = parent de tout ce qui suit
    -- Flyout du choix de métier (kit) — ancré sous le PORTRAIT (cf. _ToggleProfFlyout), plus sous
    -- un bouton du panneau qui n'existe plus.
    self.postProfFlyout = Skin.MakeFlyout("COCProfFlyout", P.LEFT_W)

    self:_BuildPostPlanFilters()   -- les contrôles vont dans leurs SLOTS de la SPEC (srch, quality…)

    -- (PAS de titre « LISTE DES PLANS », et plus d'annotation de filtrage ici : « connu / à portée »
    -- vit dans la JAUGE du header avec le nom de l'artisan — l'ancien FontString flottait SUR la
    -- première ligne de la liste depuis le passage des filtres sur une ligne, vu sur capture user.)

    -- Le scroll remplit le bloc : ancré HAUT ET BAS (marge PAD) → il suit la hauteur sans recalcul.
    -- Largeur LUE sur la zone (SPEC pilote pad/gouttière ; −6 = la scrollbar déborde dans la gouttière).
    -- INVARIANT (cf. en-tête) : VISIBLE ≥ lignes du viewport.
    local plansW = sec:GetWidth(); if plansW <= 1 then plansW = P.LIST_W + 6 end
    self.postPlanW = plansW - 6
    local pscroll = CreateFrame("ScrollFrame", "COCPostPlanScroll", sec, "UIPanelScrollFrameTemplate")
    pscroll:SetPoint("TOPLEFT", P.PAD, 0); pscroll:SetPoint("BOTTOMLEFT", P.PAD, P.PAD)
    pscroll:SetWidth(self.postPlanW)
    local pc = CreateFrame("Frame", nil, pscroll); pc:SetSize(self.postPlanW, 10); pscroll:SetScrollChild(pc)
    pscroll:HookScript("OnVerticalScroll", function() UI:_RenderPostPlanWindow() end)
    self.postPlanScroll = pscroll; self.postPlanContent = pc
    Skin.ScrollTrack("COCPostPlanScroll")   -- rail sombre derrière la scrollbar (fond qui manquait)
    -- Pool FIXE de lignes réutilisées au scroll (virtualisation ; cf. VISIBLE + _RenderPostPlanWindow).
    self.postPlanRows = {}
    for i = 1, VISIBLE do self.postPlanRows[i] = self:_PostPlanRow(i) end
    -- Outils Lazy Gold (tri rentabilité + « 123 » valeurs exactes) : dans LEUR slot de la bande de
    -- filtres (id "AH_Filter" dans la SPEC) — ce sont des réglages d'affichage, avec les filtres.
    self:_BuildPostLGBar(self:PostSec("AH_Filter"))
    -- Vue silhouette (Enchantement) : elle occupe LA MÊME zone que le scroll, montrée en alternance
    -- (cf. _UI_Post_Paperdoll.lua). Construite ici, jamais affichée tant que le métier n'est pas
    -- l'Enchantement ET que l'utilisateur ne l'a pas demandée.
    self:_BuildPostDoll()
end

-- La rangée de filtres = des SLOTS de la SPEC (idée user : filters porte ses composants en colonnes).
-- Chaque contrôle est parenté à SON slot et ancré en LEFT → CENTRÉ VERTICALEMENT par construction
-- (le centrage « impossible » avec les offsets TOPLEFT à l'œil). Ajouter un filtre = déclarer son
-- slot dans la SPEC (Layout) + le câbler ici. Les légendes au-dessus des champs ont cédé la place :
-- hint de recherche, valeur du sélecteur et tooltip de la case portent le sens.
function UI:_BuildPostPlanFilters()
    -- Recherche : slot FLEX — ancrée gauche ET droite, elle absorbe la largeur restante de la bande
    -- (élargir `w` de la colonne dans la SPEC = la recherche respire).
    local sSlot = self:PostSec("srch")
    local srch = CreateFrame("EditBox", nil, sSlot, "InputBoxTemplate")
    srch:SetHeight(16); srch:SetPoint("LEFT", 10, 0); srch:SetPoint("RIGHT", -2, 0)
    srch:SetAutoFocus(false)
    local hint = Skin.SearchHint(sSlot, srch, L["Rechercher"])
    srch:SetScript("OnTextChanged", function(b)
        hint:SetShown(b:GetText() == "")
        UI.postSearch = b:GetText():lower(); UI:RefreshPostPlans()
    end)
    srch:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)
    -- Bascule liste ↔ silhouette : elle se pose DANS ce slot, à droite (cf. _BuildPostDollToggle) —
    -- d'où le passage de `srch`, dont le bord droit recule quand le bouton est visible.
    self:_BuildPostDollToggle(sSlot, srch)

    -- Qualité : le sélecteur gris natif de l'HdV, dans son slot. Les valeurs sont les INDEX de
    -- QUALITY_STEPS, jamais `false` (UIDropDownMenu lit `false` comme « pas de sélection », cf.
    -- contrat de Skin.MakeDropdown) — QUALITY_STEPS[1] = false = « Toutes ».
    self.postQualityIdx = 1
    local dd = Skin.MakeDropdown("COCPostQualityDD", self:PostSec("qualityDropDown"), 64, function()
        local out = {}
        for i, q in ipairs(QUALITY_STEPS) do
            local name = q and ((_G["ITEM_QUALITY" .. q .. "_DESC"] or "?") .. "+") or L["Toutes"]
            out[i] = { value = i, text = name }
        end
        return out
    end, { onSelect = function(i) UI.postQualityIdx = i; UI:RefreshPostPlans() end })
    dd:SetPointVisual("LEFT", self:PostSec("qualityDropDown"), "LEFT", 5, -4)
    self.postQualityDD = dd
    self:_RefreshQualityBtn()

    -- Filtre réactifs : case à cocher native (le pendant d'« Objets utilisables » du browse de l'HdV).
    self.postReagFilter = false
    local rChk = Skin.MakeCheckButton(self:PostSec("reagents"), L["Réactifs en main"])
    rChk:SetPoint("LEFT", 2, 0); self.postReagFilterBtn = rChk
    rChk:SetScript("OnClick", function(b)
        UI.postReagFilter = b:GetChecked() and true or false
        UI:RefreshPostPlans()
    end)
    rChk:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText(L["Ne montrer que les plans dont j'ai déjà tous les réactifs."], 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    rChk:SetScript("OnLeave", GameTooltip_Hide)
    self:_RefreshReagFilterBtn()

    self:_BuildPostStatFilter()
end

-- Sélecteur de stat, sur sa propre rangée (cf. SPEC `statFilter` dans _UI_Post_Layout).
-- Le menu se peuple sur le CATALOGUE ENTIER du métier, pas sur la liste affichée : sinon il
-- rétrécirait avec la recherche et le filtre en cours, et on ne pourrait plus changer de stat sans
-- repasser par « Toutes ». C'est aussi ce qui rend honnête la clé de cache (le métier).
function UI:_BuildPostStatFilter()
    local SF = COC.StatFilter
    if not SF then return end
    local slot = self:PostSec("statDropDown")
    local dd = SF:MakeDropdown("COCPostStatDD", slot, 300, "post", {
        key      = function() return UI.postProf end,
        entries  = function()
            local c = CL()
            return (UI.postProf and c and c:ProfessionCatalogue(UI.postProf)) or {}
        end,
        itemID   = function(e) return e.itemID end,
        onChange = function() UI:RefreshPostPlans() end,
    })
    dd:SetPointVisual("LEFT", slot, "LEFT", 5, -2)
    self.postStatDD = dd
end

function UI:_ToggleProfFlyout()
    -- Ancré sous le PORTRAIT (déclencheur du choix de métier), pas sous un bouton du panneau.
    if self.postProfFlyout then
        self.postProfFlyout:ToggleAt("TOPLEFT", self.frame.portrait, "BOTTOMLEFT", -6, -6)
    end
end

-- Reflète le seuil courant dans le sélecteur (libellé + coche). Nom conservé : appelé aussi au build.
function UI:_RefreshQualityBtn()
    if self.postQualityDD then self.postQualityDD:SetValue(self.postQualityIdx or 1) end
end

-- Case à cocher native : l'état EST la coche (plus de liseré doré à décoder). Le tooltip, posé une
-- fois à la construction (cf. _BuildPostPlanFilters), ne porte plus que l'explication du filtre.
function UI:_RefreshReagFilterBtn()
    if not self.postReagFilterBtn then return end
    self.postReagFilterBtn:SetChecked(self.postReagFilter and true or false)
end

-- =========================================================================
-- Panneau droit : titre plan + réactifs + commission + ciblage artisan
-- =========================================================================
function UI:_BuildPostRight(panel)
    self:_BuildPostDetail()   -- se parente aux sous-zones ItemSelected / reagentsList (SPEC)
    self:_BuildPostPrice(self:PostSec("price"))
    self:_BuildPostArtisanSection(panel)   -- bloc « artisans » + bande basse (hors blocs)
end

-- (Détail du plan + réactifs + rangée commission : CraftingOrderClassic_UI_Post_Detail.lua —
--  _BuildPostDetail / _BuildPostPrice / RefreshPostPlanDetail / RefreshPostReagents.)
-- (Section artisan/destinataire/Poster : voir CraftingOrderClassic_UI_Post_Artisans.lua)

-- =========================================================================
-- Refresh
-- =========================================================================
function UI:RefreshPost()
    self:_RefreshProfDropdown()
    self:RefreshPostPlans()
    self:RefreshPostPlanDetail()
    self:RefreshPostArtisans()
end

function UI:_RefreshProfDropdown()
    local c = CL(); local all = c and c:Professions() or {}
    local profs = {}
    for _, p in ipairs(all) do if not GATHER_ONLY[p] then profs[#profs + 1] = p end end
    if (not self.postProf or GATHER_ONLY[self.postProf]) and profs[1] then self.postProf = profs[1] end
    -- Nom + icône du métier : portés par l'en-tête/portrait (UI:_SyncMainPortrait), plus par le panneau.
    UI:_SyncMainPortrait()
    -- Peuplement du flyout (pool du kit)
    local fly = self.postProfFlyout
    for i, prof in ipairs(profs) do
        local r = fly:Row(i)
        r:SetText(Skin.ProfLabel(prof)); r:SetSelected(prof == self.postProf)
        r:SetScript("OnClick", function()
            UI.postProf = prof; UI.postEntry = nil; UI:_RefreshProfDropdown()
            -- Le filtre par stat ne SURVIT PAS au changement de métier : un « Force » hérité de la
            -- Forge viderait la Cuisine sans que rien ne l'explique. C'est ici, et pas dans le
            -- rafraîchissement de liste, que le sélecteur se relit (SetValue relit la liste = balayage).
            if COC.StatFilter then
                COC.StatFilter:Reset("post")
                COC.StatFilter:RefreshDropdown(UI.postStatDD)
            end
            UI:_SyncMainPortrait()   -- le médaillon suit le métier IMMÉDIATEMENT (plus au prochain refresh)
            UI:RefreshPostPlans(); UI:RefreshPostPlanDetail(); UI:RefreshPostArtisans()
            fly:Hide()
        end)
    end
    fly:SetCount(#profs)
end

function UI:RefreshPostPlans()
    local c = CL(); if not (c and self.postPlanContent) then return end
    self._postProfitCache = {}   -- invalidé à chaque refresh (les prix Auctionator ont pu changer)
    self:_SyncPostLGBar()
    local list = self.postProf and c:ProfessionCatalogue(self.postProf) or {}
    local s = self.postSearch
    local qmin = QUALITY_STEPS[self.postQualityIdx or 1]   -- seuil qualité minimal (ou false = Toutes)
    -- Filtre artisan ciblé (P5) : si postTarget = "@Nom", ne montrer que ce que CET artisan peut
    -- fabriquer (recettes connues via RK, ou à défaut plans à sa portée via son niveau + learnedAt ;
    -- cf. _TargetArtisanFilter). L'inverse du flux plan→artisans. artMode = libellé du mode (en-tête).
    local artFilter, artMode = nil, nil
    if self.postProf then artFilter, artMode = self:_TargetArtisanFilter(self.postProf) end
    local countCache = {}   -- mémo GetItemCount par itemID, valable le temps de CE refresh (cf. hasReagentsInBags)
    -- Produits de DÉSENCHANTEMENT (essences, poussières, éclats) : ils n'ont PAS de spellID — on ne les
    -- fabrique pas, on les obtient en détruisant un objet. Ils sont pourtant parfaitement commandables
    -- à un enchanteur, donc ils ne doivent pas tomber dans le filtre « craftable uniquement ».
    local def = c.GetProfession and c:GetProfession(self.postProf)
    local disen = def and def.disenchant
    local out = {}
    for _, e in ipairs(list) do
        -- Commande = objets CRAFTABLES (recette/sort) + produits de désenchantement. Les récoltes pures
        -- vivent dans l'onglet Récolte. On masque les objets liés (non échangeables) et ceux absents du
        -- client (autre extension).
        local isDisen = (not e.spellID) and disen and e.itemID and disen[e.itemID] ~= nil
        -- Minage fusionné : ses MINERAIS bruts (récolte, sans spellID) sont commandables ici en plus de
        -- ses lingots de fonte — l'onglet Commande et l'onglet Récolte montrent tous deux l'ensemble.
        local isOre = (not e.spellID) and (not isDisen) and e.itemID and self.postProf == "Mining"
        if (e.spellID or isDisen or isOre) and Skin.ItemExists(e.itemID) and not (e.itemID and isSoulbound(e.itemID))
            and (not artFilter or not e.spellID or artFilter(e.spellID)) then
            local okq = true
            if qmin and e.itemID then local q = select(3, GetItemInfo(e.itemID)); okq = q ~= nil and q >= qmin end
            local nm = entryName(e)
            if okq and (not s or s == "" or nm:lower():find(s, 1, true)) then
                -- Sans recette, pas de réactifs à avoir en poche : « prêt » n'a pas de sens (false).
                local ready = e.spellID and hasReagentsInBags(c, self.postProf, e.spellID, countCache) or false
                if not self.postReagFilter or ready then
                    out[#out + 1] = {e = e, name = nm, ready = ready}
                end
            end
        end
    end
    -- Le repère de filtrage artisan (« connu / à portée ») vit dans la JAUGE du header, à la suite du
    -- niveau (cf. UI:_SyncHeaderSkill) — l'ancien FontString local chevauchait la 1ʳᵉ ligne de liste.
    self.postArtMode = artFilter and artMode or nil
    self:_SyncHeaderSkill()
    -- Filtre par STAT (rangée dédiée) : appliqué APRÈS recherche/qualité/réactifs, juste avant le
    -- rendu. Rend la même table quand aucune stat n'est choisie → le cas courant ne paie rien.
    if COC.StatFilter then
        out = COC.StatFilter:Apply("post", out, function(it) return it.e and it.e.itemID end)
    end
    -- Tri par section (emplacement/type) + rendu en-têtes+lignes : cf. _UI_Post_Categories.lua.
    -- Le « prêt » (P2) remonte en tête de SA section (plus en tête globale) : le regroupement prime.
    self:_RenderPostPlanRows(out)
    -- Vue silhouette (Enchantement) : montre/cache le bon panneau et le déclencheur. La liste est
    -- construite dans TOUS les cas — elle doit être à jour dès qu'on rebascule dessus.
    self:_SyncPostDollView()
end

-- Ligne UNIFIÉE du pool virtualisé : rend soit un PLAN (badge + nom, cliquable) soit un EN-TÊTE de
-- section (libellé doré + filet, non interactif). Le remplissage/bascule se fait dans _FillPostPlanRow
-- (_UI_Post_Categories) ; le clic lit self.item (pas de closure recréée au scroll).
function UI:_PostPlanRow(i)
    local r = self.postPlanRows[i]; if r then return r end
    local lw = self.postPlanW or P.LIST_W   -- largeur de la zone plans (lue au build, cf. _BuildPostLeft)
    r = CreateFrame("Button", nil, self.postPlanContent); r:SetSize(lw, PLH); r:SetPoint("TOPLEFT", 0, -(i-1)*PLH)
    local hi = r:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints(); hi:SetColorTexture(Skin.unpack(Skin.color.rowHover))
    r.badge = Skin.MakeBadge(r, 14); r.badge:SetPoint("LEFT", 2, 0)
    r.name  = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.name:SetPoint("LEFT", 20, 0); r.name:SetJustifyH("LEFT"); r.name:SetWidth(lw - 24); Skin.ApplyShadow(r.name)
    -- Variante EN-TÊTE (même ligne physique) : libellé + filet, masqués quand la ligne rend un plan.
    r.hdr = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.hdr:SetPoint("BOTTOMLEFT", 4, 5); r.hdr:SetJustifyH("LEFT")
    r.hdr:SetTextColor(Skin.unpack(Skin.color.gold)); Skin.ApplyShadow(r.hdr); r.hdr:Hide()
    r.hdrLine = r:CreateTexture(nil, "ARTWORK"); r.hdrLine:SetHeight(1)
    r.hdrLine:SetColorTexture(Skin.color.gold[1], Skin.color.gold[2], Skin.color.gold[3], 0.25)
    r.hdrLine:SetPoint("BOTTOMLEFT", 2, 3); r.hdrLine:SetPoint("BOTTOMRIGHT", -2, 3); r.hdrLine:Hide()
    -- Chevron +/- des en-têtes : TEXTURE native (la police rend « ▾ » en tofu).
    r.expand = r:CreateTexture(nil, "ARTWORK"); r.expand:SetSize(14, 14); r.expand:Hide()
    -- Indicateur de rentabilité Lazy Gold (cf. _UI_Post_LazyGold.lua) : le plus à droite, masqué
    -- si Lazy Gold est absent ou si le plan n'est pas rentable.
    r.profit = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.profit:SetPoint("RIGHT", -4, 0); r.profit:SetJustifyH("RIGHT"); Skin.ApplyShadow(r.profit); r.profit:Hide()
    r:SetScript("OnClick", function(self2)
        local it = self2.item; if not it then return end
        if it.isHeader then UI:TogglePostSection(it.ckey)
        elseif it.e then UI:SelectPostPlan(it.e) end
    end)
    self.postPlanRows[i] = r; Skin.WireItemTooltip(r); Skin.WireItemLink(r); return r
end

-- (RefreshPostPlanDetail / RefreshPostReagents / _PostReagRow / _UpdateProvidedCount :
--  CraftingOrderClassic_UI_Post_Detail.lua — le sous-système « détail du plan sélectionné ».)

function UI:SelectPostPlan(entry)
    self.postEntry = entry; self.postProvide = {}
    -- Plus d'écho « Sélection : X » en bas (demande user) : le plan choisi est déjà en évidence dans
    -- l'en-tête du détail (icône + nom). Le label du bas ne sert plus qu'aux RETOURS D'ÉTAT (poster,
    -- erreurs) → on l'efface ici.
    self.postSelLbl:SetText("")
    self:RefreshPostPlans(); self:RefreshPostPlanDetail(); self:RefreshPostArtisans()
end

-- =========================================================================
-- Poster
-- =========================================================================
function UI:DoPostOrder()
    local e = self.postEntry
    if not e then self.postSelLbl:SetText("|cFFFF4444" .. L["Choisis d'abord un plan."] .. "|r"); return end
    local qty = tonumber(self.postQty:GetText()) or 1
    local g   = tonumber(self.postGold:GetText()) or 0
    local s   = tonumber(self.postSilver:GetText()) or 0
    local cu  = tonumber(self.postCopper:GetText()) or 0
    local price = nil
    if g > 0 or s > 0 or cu > 0 then
        local parts = {}
        if g  > 0 then parts[#parts+1] = g.."po"  end
        if s  > 0 then parts[#parts+1] = s.."pa"  end
        if cu > 0 then parts[#parts+1] = cu.."pc" end
        price = table.concat(parts, " ")
    end
    local provided = {}
    for iid, v in pairs(self.postProvide) do if v then provided[#provided+1] = iid end end
    COC.Orders:PostEntry(e, qty, price, {
        profession = self.postProf, provided = provided,
        recipient  = self:_PostTargetLabel(),
    })
    if COC.Beacon then COC:Beacon() end   -- balise TEXTE de découverte (clic = hardware event)
    self.postGold:SetText("0"); self.postSilver:SetText("0"); self.postCopper:SetText("0")
    self.postQty:SetText("1"); self.postEntry = nil; self.postProvide = {}
    self.postSelLbl:SetText("|cFF33DD33" .. L["Commande postée !"] .. "|r")
    self:ShowTab("orders")
end

-- Réactifs en poche (P2) : les sacs changent (loot, craft, échange...) → la liste de plans « prêts »
-- doit suivre. Rafraîchi UNIQUEMENT si l'onglet Commande est visible (coût nul le reste du temps).
-- BAG_UPDATE_DELAYED regroupe les BAG_UPDATE d'un même lot en un seul événement (pas de spam).
local bagWatcher = CreateFrame("Frame")
bagWatcher:RegisterEvent("BAG_UPDATE_DELAYED")
bagWatcher:SetScript("OnEvent", function()
    if UI.postPanel and UI.postPanel:IsShown() then UI:RefreshPostPlans() end
end)
