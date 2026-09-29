-- CraftingOrderClassic_ProfWindow_LFW.lua — config de l'OFFRE « recherche de travail » par métier.
-- Engrenage à droite du bouton « Chercher du travail » (en-tête fenêtre métier) → panneau flyout :
-- compos de base, restriction « si progression », commission fixe (or/argent/cuivre), et picker
-- cherchable des composants fournis (univers = UNION des réactifs des recettes CraftLink du métier,
-- filtré par version client via Skin.ItemExists). Save-on-change → Dir:SetLFWOffer (persiste +
-- re-diffusion LFO débouncée). Éditable même LFW éteint : la config part au prochain SetLFW.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L
local PW   = COC.ProfWindow

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

local PANEL_W, PANEL_H = 330, 430
-- Pool ≥ viewport (invariant liste virtualisée) : zone liste ≈ 236 px / 20 ≈ 12 lignes → 16 = marge.
-- 15 et non 16 : la rangee de modes (Reactifs / Recettes) a pris 20 px sur la zone de liste.
-- Puis la case « Annoncer en Commerce » (2026-09-30) en a pris 22 de plus : viewport ~174 px / 20
-- = ~9 lignes, le pool en couvre toujours 15.
local ROW_H, VISIBLE   = 20, 15
local LIST_TOP         = 226     -- y du haut de la liste (sous annonce + modes + en-tête picker + recherche)
PW.LFW_LIST_TOP        = LIST_TOP   -- lu par _ProfWindow_LFW_Recipes pour poser la rangee de modes

local function maxItems() return (COC.Directory and COC.Directory.OFFER_MAX_ITEMS) or 15 end

local function profLabel(key) return (Skin.ProfLabel and Skin.ProfLabel(key)) or key end

-- ------------------------------------------------------------------
-- Bande « Chercher du travail » en PIED de colonne
-- ------------------------------------------------------------------
-- POURQUOI UNE BANDE ET PAS UNE 5e LANGUETTE. Le portage Forever a tue l'entree LFW : le bouton
-- d'en-tete et son engrenage vivaient dans la vue custom, que la colonne greffee n'affiche plus.
-- La reponse evidente etait une languette de plus. Elle a ete mesuree le 2026-09-26 et elle coute
-- cher : ~41 px de CADRE par languette (le texte, lui, ne pese que 1,9 px/caractere), et la rangee
-- pilote la largeur de la colonne, qui elargit la FENETRE NATIVE d'autant. ~35 px de fenetre pour
-- un interrupteur. Ici on paie 20 px de HAUTEUR sur une liste qui en fait 301, et rien ne bouge.
--
-- Deux avantages tombent avec ce choix, et ils ne sont pas cosmetiques :
--   * la bande est visible dans TOUTES les vues -- or c'est un ETAT qu'on oublie d'eteindre, et
--     tout le mecanisme de TTL anti-leurre existe precisement pour ca ;
--   * elle peut ECRIRE son etat. Une languette ne le pouvait pas : changer son libelle change sa
--     largeur (bar:SetText rappelle PanelTemplates_TabResize), donc la rangee, donc la colonne --
--     pour 9 px de marge. La bande ne pilote aucune mise en page : elle dit le metier en toutes
--     lettres.
-- Sa hauteur est reservee INCONDITIONNELLEMENT par _ApplyMode : voir PW.TUNE.lfwStrip.
function PW:_BuildLFWStrip(f)
    if self.lfwStrip then return end
    local s = Skin.MakeFlatRow(f, 100, PW.TUNE.lfwStrip)
    s:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",   PW.PAD, 4)
    s:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PW.PAD, 4)
    s:SetHeight(PW.TUNE.lfwStrip)
    s:SetScript("OnClick", function() PW:_ToggleLFW() end)
    s:SetScript("OnEnter", function(b)
        local D = COC.Directory
        local on = D and D.MyLFW and D:MyLFW() == PW.profKey
        GameTooltip:SetOwner(b, "ANCHOR_TOPLEFT")
        GameTooltip:SetText(on and L["Tu cherches du travail — clic pour arrêter."]
            or L["Signale au royaume que tu cherches du travail dans ce métier."], 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    s:SetScript("OnLeave", GameTooltip_Hide)
    s:Hide()
    self.lfwStrip = s
    if self._BuildLFWOfferBtn then self:_BuildLFWOfferBtn(s) end
end

-- Etat de la bande : visible sur un metier A MOI en colonne, et elle DIT lequel quand elle est
-- allumee. L'engrenage suit la meme portee -- regler une offre pour un metier qu'on n'a pas ouvert
-- n'aurait pas de sens.
function PW:_SyncLFWStrip()
    local s = self.lfwStrip; if not s then return end
    local D = COC.Directory
    local show = self.profKey and not self.rerollKey and (self._compact or self.docked)
                 and D and D.SetLFW and true or false
    s:SetShown(show)
    if show then
        local on = D.MyLFW and D:MyLFW() == self.profKey
        s:SetSelected(on and true or false)
        s:SetText(on and ("|cFF4CDB6E" .. string.format(L["Dispo — %s"], profLabel(self.profKey)) .. "|r")
            or L["Chercher du travail"])
    end
    if self._SyncLFWConfig then self:_SyncLFWConfig(show) end
end

-- ------------------------------------------------------------------
-- Bouton « Offre » à droite de la bande (visibilité gérée par PW:_SyncLFWStrip)
-- ------------------------------------------------------------------
-- C'ÉTAIT UN ENGRENAGE (`Interface\WorldMap\Gear_64`, 18 px) ET LE USER NE L'A PAS RECONNU : à
-- l'écran, le 2026-09-26, deux petits carrés sans forme lisible.
--
-- Pourquoi on ne cherche pas plus loin la cause. L'asset EXISTE — `WorldMap/Gear_64.PNG` est dans
-- `Documentation/wow-ui-textures-classic/`. Reste qu'il n'est référencé nulle part dans l'export
-- Forever 1.60.1 (il a pu disparaître sur MAINLINE), ou qu'un dessin conçu en 64 px ne survit pas
-- à une réduction en 16. Départager coûterait un aller-retour en jeu pour un bouton, alors qu'un
-- MOT est lisible à toute taille et ne peut pas manquer. Et ça rejoint la leçon du 2026-09-19,
-- payée sur capture dans cette colonne même : une icône de 16 px posée dans une bande se lit comme
-- un bouton secondaire oublié là, quand un libellé dit ce qu'il fait.
-- Pas de glyphe ⚙ non plus : la police du jeu les rend en tofu.
--
-- ⚠️ MÉTHODE, apprise en se trompant ce jour-là : pour savoir si une texture existe, l'oracle est
-- `Documentation/wow-ui-textures-classic/`, PAS l'export Lua/XML. L'export ne contient aucun asset
-- et donne des faux négatifs — `MoneyFrame\UI-GoldIcon` n'y figure pas davantage, et elle s'affiche
-- très bien dans la vue Profit.
function PW:_BuildLFWOfferBtn(strip)
    if self.lfwCfgBtn then return end
    -- ENFANT de la bande, pas frère. Il était créé sur le cadre de la colonne et seulement ANCRÉ
    -- sur la bande : deux frères au même niveau, donc un ordre de dessin qui ne se décide pas — le
    -- user l'a vu « en arrière » le 2026-09-26. Enfant, il passe devant par construction, il se
    -- montre et se cache avec elle, et le niveau explicite ne laisse plus la question ouverte.
    local b = Skin.MakeGoldButton(strip, 56, 16, L["Offre"])
    b:SetPoint("RIGHT", strip, "RIGHT", -2, 0)
    b:SetFrameLevel((strip:GetFrameLevel() or 0) + 2)
    -- Et le texte d'état s'arrête AVANT le bouton : « Dispo — Leatherworking » est déjà long, et
    -- un libellé sans bord droit passerait dessous au lieu d'être tronqué.
    if strip.text then
        strip.text:SetPoint("RIGHT", b, "LEFT", -4, 0)
        strip.text:SetWordWrap(false)
    end
    b:SetScript("OnClick", function() PW:ToggleLFWConfig() end)
    b:SetScript("OnEnter", function(s)
        GameTooltip:SetOwner(s, "ANCHOR_TOPLEFT")
        GameTooltip:SetText(L["Configurer l'offre : composants fournis, commission…"], 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    b:Hide()
    self.lfwCfgBtn = b
end

-- Suit l'état du bouton LFW (même portée : vue pleine d'un métier À MOI). Panneau ouvert : il se
-- ferme si la portée disparaît, il se REPEINT si on a changé de métier (la config est par métier).
function PW:_SyncLFWConfig(show)
    local b = self.lfwCfgBtn; if not b then return end
    b:SetShown(show and true or false)
    local p = self.lfwPanel
    if p and p:IsShown() then
        if show then self:_RefreshLFWPanel() else p:Hide() end
    end
end

-- Ouvre/ferme le panneau pour le métier OUVERT (mien). Liseré doré de l'engrenage = panneau ouvert.
function PW:ToggleLFWConfig()
    if not self.profKey or self.rerollKey then return end
    local p = self:_BuildLFWPanel()
    if p:IsShown() then p:Hide() else self:_RefreshLFWPanel(); p:Show() end
    if self.lfwCfgBtn then self.lfwCfgBtn:SetSelected(p:IsShown()) end
end

-- ------------------------------------------------------------------
-- Panneau (construit à la demande, un seul exemplaire)
-- ------------------------------------------------------------------
function PW:_BuildLFWPanel()
    if self.lfwPanel then return self.lfwPanel end
    local p = CreateFrame("Frame", "CraftingOrderLFWConfig", self.frame, "BackdropTemplate")
    p:SetSize(PANEL_W, PANEL_H)
    -- Il s'ouvre à GAUCHE de la colonne, centré sur sa hauteur. Il s'ouvrait à DROITE
    -- (`frame TOPRIGHT`), ce qui valait quand la fenêtre custom flottait au milieu de l'écran :
    -- greffée, la colonne est collée au bord droit du cadre natif, et 330 px partant de là sortent
    -- de l'écran. À gauche il se pose sur le contenu natif, ce qui est la bonne place pour un
    -- panneau de réglage modal — et vertical centré, il tient presque exactement dans la hauteur
    -- du cadre hôte (relevé du 2026-09-26 : colonne 287..667, panneau 430 de haut).
    p:SetPoint("RIGHT", self.frame, "LEFT", -4, 0)
    p:SetFrameStrata("HIGH"); p:SetToplevel(true)
    Skin.SkinWell(p)
    p.title = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    p.title:SetPoint("TOPLEFT", 12, -10); p.title:SetPoint("RIGHT", -30, 0)
    p.title:SetJustifyH("LEFT"); p.title:SetWordWrap(false)
    local x = CreateFrame("Button", nil, p, "UIPanelCloseButton")
    x:SetSize(24, 24); x:SetPoint("TOPRIGHT", -2, -2)
    p:SetScript("OnHide", function() if PW.lfwCfgBtn then PW.lfwCfgBtn:SetSelected(false) end end)
    self:_BuildLFWChecks(p)
    self:_BuildLFWPicker(p)
    -- Noms d'objets ASYNC (GetItemInfo nil au 1er passage) → re-rendu débouncé quand le client les reçoit.
    p:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    p:SetScript("OnEvent", function()
        if p:IsShown() and not p._nameTick and C_Timer then
            p._nameTick = true
            C_Timer.After(0.3, function() p._nameTick = nil; if p:IsShown() then PW:_RefreshLFWList() end end)
        end
    end)
    -- NAÎTRE CACHÉ, et ce n'est pas une precaution : un CreateFrame est AFFICHE par defaut. Le
    -- panneau etant construit PARESSEUSEMENT au premier clic, la bascule le trouvait deja visible
    -- et le refermait dans la foulee -- il fallait cliquer DEUX fois pour l'ouvrir (vu en jeu le
    -- 2026-09-26). Un constructeur paresseux doit rendre l'objet dans l'etat que l'appelant
    -- suppose, sinon le premier appel ne se comporte pas comme les suivants.
    p:Hide()
    self.lfwPanel = p
    return p
end

-- Moitié haute : les deux déclarations + la commission. Chaque contrôle SAUVE immédiatement
-- (_EditLFWOffer) ; _filling coupe les handlers pendant que _RefreshLFWPanel repose les valeurs.
function PW:_BuildLFWChecks(p)
    local basics = Skin.MakeCheckButton(p, L["Je fournis les composants de base"])
    basics:SetPoint("TOPLEFT", 8, -30)
    basics:SetScript("OnClick", function(b)
        if not p._filling then PW:_EditLFWOffer(function(o) o.basics = b:GetChecked() and true or nil end) end
    end)
    p.basics = basics
    local h1 = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    h1:SetPoint("TOPLEFT", 34, -52); h1:SetText(L["(achetables chez un marchand)"])

    local sup = Skin.MakeCheckButton(p, L["Seulement si le plan me fait progresser"])
    sup:SetPoint("TOPLEFT", 8, -68)
    sup:SetScript("OnClick", function(b)
        if not p._filling then PW:_EditLFWOffer(function(o) o.skillUpOnly = b:GetChecked() and true or nil end) end
    end)
    p.skillUp = sup
    local h2 = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    h2:SetPoint("TOPLEFT", 34, -90); h2:SetText(L["(restriction sur les composants fournis)"])

    local lab = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lab:SetPoint("TOPLEFT", 12, -112); lab:SetText(L["Commission fixe par craft :"])
    local g, s, c = Skin.MakeMoneyRow(p, 20, -130)
    p.gold, p.silver, p.copper = g, s, c
    local function onFee()
        if p._filling then return end
        local fee = (tonumber(p.gold:GetText()) or 0) * 10000
                  + (tonumber(p.silver:GetText()) or 0) * 100
                  + (tonumber(p.copper:GetText()) or 0)
        PW:_EditLFWOffer(function(o) o.fee = (fee > 0) and fee or nil end)
    end
    for _, eb in ipairs({ g, s, c }) do eb:SetScript("OnTextChanged", onFee) end
    if self._BuildLFWAnnounceCheck then self:_BuildLFWAnnounceCheck(p, -152) end   -- sous la commission
end

-- Moitié basse : le picker des composants fournis (en-tête compteur, recherche, liste virtualisée).
function PW:_BuildLFWPicker(p)
    Skin.MakeSeparator(p, -(LIST_TOP - 50))   -- sous la case « Annoncer en Commerce »
    p.pickHdr = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    p.pickHdr:SetPoint("TOPLEFT", 12, -(LIST_TOP - 24))
    local search = CreateFrame("EditBox", nil, p, "InputBoxTemplate")
    search:SetHeight(16); search:SetPoint("TOPLEFT", 16, -(LIST_TOP - 2)); search:SetPoint("RIGHT", -12, 0)
    search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", function() if not p._filling then PW:_RefreshLFWList() end end)
    search:SetScript("OnEscapePressed", function(b) b:SetText(""); b:ClearFocus() end)
    p.search = search

    -- Barre fine (palier 7c). Le hook OnVerticalScroll s'ajoute APRÈS celui que pose la barre
    -- (ScrollUtil, par SetScript) : les deux tournent.
    local scroll = Skin.MakeScrollFrameIn(p)
    scroll:SetPoint("TOPLEFT", 8, -(LIST_TOP + 20)); scroll:SetPoint("BOTTOMRIGHT", -28, 10)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(PANEL_W - 36, VISIBLE * ROW_H); scroll:SetScrollChild(content)
    scroll:HookScript("OnVerticalScroll", function() PW:_RenderLFWList() end)
    p.scroll, p.content = scroll, content
    p.rows = {}
    for i = 1, VISIBLE do p.rows[i] = self:_BuildLFWRow(content, i) end
    if self._BuildLFWEmptyMsg then self:_BuildLFWEmptyMsg(p) end
    if self._BuildLFWModeTabs then self:_BuildLFWModeTabs(p) end
end

function PW:_BuildLFWRow(parent, i)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(PANEL_W - 36, ROW_H); row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
    local hi = row:CreateTexture(nil, "HIGHLIGHT"); hi:SetAllPoints(); hi:SetColorTexture(0.25, 0.45, 0.85, 0.25)
    row.check = Skin.MakeCheck(row, 14); row.check:SetPoint("LEFT", 2, 0)
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ROW_H - 4, ROW_H - 4); icon:SetPoint("LEFT", 20, 0); icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.icon = icon
    local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    name:SetPoint("LEFT", icon, "RIGHT", 4, 0); name:SetPoint("RIGHT", -2, 0)
    name:SetJustifyH("LEFT"); name:SetWordWrap(false); row.name = name
    row:SetScript("OnClick", function(r)
        -- Une recette se coche par son spellID : _ToggleLFWRecipe gere deja le cap, le retrait et
        -- la rediffusion. Il attend une ENTREE de liste de recettes, d'ou la table minimale.
        if r.spellID then PW:_ToggleLFWRecipe({ spellID = r.spellID }); return end
        if not r.itemID then return end
        -- Shift-clic → lien chat, SANS cocher (cet OnClick MUTE l'offre : ne pas déclencher les deux).
        if IsModifiedClick("CHATLINK") then HandleModifiedItemClick(Skin.ChatLinkFor(nil, r.itemID, nil)); return end
        PW:_ToggleLFWItem(r.itemID)
    end)
    row:SetScript("OnEnter", function(r)
        if r.spellID then
            GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
            if not pcall(GameTooltip.SetSpellByID, GameTooltip, r.spellID) then
                GameTooltip:SetText(r.name:GetText() or "?", 1, 1, 1)
            end
            GameTooltip:Show()
            return
        end
        if not r.itemID then return end
        GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
        if not pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. r.itemID) then
            GameTooltip:SetText(r.name:GetText() or "?", 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:Hide(); return row
end

-- ------------------------------------------------------------------
-- Données du picker
-- ------------------------------------------------------------------
-- Univers d'un métier : les réactifs des recettes que CE personnage SAIT FAIRE, filtrés par
-- existence côté client (données multi-flavor : un réactif TBC n'apparaît pas sur un client Era).
--
-- ⚠️ C'ÉTAIT l'union des réactifs de TOUTES les recettes du catalogue, et c'était trop large. Vu
-- sur capture le 2026-09-26 : un artisan du cuir à 82/150 se voyait proposer « Bloodvine » et
-- « Azerothian Diamond » — du contenu qu'il ne touchera pas avant longtemps, ou jamais. On fournit
-- des composants pour ce qu'on va CRAFTER : la liste se restreint donc à ce qu'on sait faire, et
-- elle rétrécit d'autant. Décision du user, 2026-09-26.
--
-- REPLI ASSUMÉ : si le client ne sait pas dire ce qu'on connaît — `ReadRecipes` rend nil quand
-- aucune fenêtre de métier n'est ouverte, ce qui est le cas de la vue compacte d'un métier de
-- RÉCOLTE — on retombe sur le catalogue entier. Une liste trop large reste utilisable ; une liste
-- vide, non, et elle se lirait comme une panne.
--
-- Le cache ne peut plus être « par métier pour la session » : on apprend des recettes en jouant.
-- Il est vidé sur `TRADE_SKILL_LIST_UPDATE` (cf. _ProfWindow_LFW_Recipes), l'événement que le
-- client envoie justement quand cette liste change. Première idée écartée : une empreinte tirée du
-- NOMBRE de recettes connues — la calculer obligeait à relire toute la liste, donc à chaque touche
-- frappée dans la recherche. Un cache dont la clé coûte le prix du calcul n'est pas un cache.
function PW:_LFWUniverse(profKey)
    self._lfwUniv = self._lfwUniv or {}
    if self._lfwUniv[profKey] then return self._lfwUniv[profKey] end
    local known = self._LFWRecipeUniverse and self:_LFWRecipeUniverse() or nil
    local c = CL()
    local seen, out = {}, {}
    local function take(list)
        for _, rg in ipairs(list or {}) do
            local id = rg[1]
            if id and not seen[id] and Skin.ItemExists(id) then seen[id] = true; out[#out + 1] = id end
        end
    end
    if known and #known > 0 and c and c.RecipeReagents then
        for _, e in ipairs(known) do take(c:RecipeReagents(profKey, e.id)) end
    end
    -- Le repli se declenche sur un RESULTAT vide, pas sur une entree vide. Vu sur Herbalism le
    -- 2026-09-26 : le client connaissait bien une recette (« Incense Candle »), donc `known`
    -- n'etait pas vide et l'ancienne garde ne repliait pas -- mais notre catalogue n'a pas ses
    -- reactifs, et la liste sortait vide. Ce qui compte n'est pas d'avoir eu de quoi filtrer,
    -- c'est d'avoir obtenu quelque chose.
    if #out == 0 then
        local def = c and c.GetProfession and c:GetProfession(profKey)
        for _, list in pairs((def and def.reagents) or {}) do take(list) end
    end
    -- Un univers vide ne se met pas en cache : il vient peut-etre d'une fenetre pas encore prete.
    if #out > 0 then self._lfwUniv[profKey] = out end
    return out
end

-- Liste d'affichage : filtre de recherche + tri par nom localisé (résolution paresseuse → l'ordre
-- s'affine au fil des GET_ITEM_INFO_RECEIVED, re-rendu débouncé par le panneau).
function PW:_LFWDisplayList()
    local p, c = self.lfwPanel, CL()
    local search = (p.search:GetText() or ""):lower()
    local out = {}
    if p.pickMode == "recipes" then
        -- L'univers des recettes porte deja son nom (lu sur le client) : rien a resoudre.
        for _, e in ipairs(self:_LFWRecipeUniverse()) do
            if search == "" or e.name:lower():find(search, 1, true) then out[#out + 1] = e end
        end
    else
        for _, id in ipairs(self:_LFWUniverse(self.profKey)) do
            local name = (c and c:ItemName(id)) or ("item:" .. id)
            if search == "" or name:lower():find(search, 1, true) then
                out[#out + 1] = { id = id, name = name }
            end
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

-- ------------------------------------------------------------------
-- Édition (save-on-change)
-- ------------------------------------------------------------------
-- Lit MA config du métier ouvert, applique fn(o), normalise (offre vide → nil) et sauve :
-- Dir:SetLFWOffer persiste ET re-diffuse (débouncé) si le LFW de ce métier est actif.
function PW:_EditLFWOffer(fn)
    local D = COC.Directory
    if not (D and D.SetLFWOffer and self.profKey) then return end
    local o = D:MyLFWOffer(self.profKey) or {}
    fn(o)
    if not (o.basics or o.skillUpOnly or (o.fee and o.fee > 0)
            or (o.items and #o.items > 0) or (o.recipes and #o.recipes > 0)) then o = nil end
    D:SetLFWOffer(self.profKey, o)
    self:_RefreshLFWList()
end

-- Coche/décoche un composant fourni. Au-delà du cap (limite de la ligne réseau), on refuse avec un toast.
function PW:_ToggleLFWItem(itemID)
    local D = COC.Directory
    local o = (D and D:MyLFWOffer(self.profKey)) or {}
    for i, v in ipairs(o.items or {}) do
        if v == itemID then
            self:_EditLFWOffer(function(oo) table.remove(oo.items, i); if #oo.items == 0 then oo.items = nil end end)
            return
        end
    end
    if #(o.items or {}) >= maxItems() then
        if UI.Toast then UI:Toast(string.format(L["Maximum %d composants fournis."], maxItems())) end
        return
    end
    self:_EditLFWOffer(function(oo) oo.items = oo.items or {}; oo.items[#oo.items + 1] = itemID end)
end

-- Coche/décoche une RECETTE proposée (colonne de cases de la liste, cf. ProfWindow_Recipes). Clé = spellID
-- de la recette (résolu en nom par GetSpellInfo chez le récepteur). Au-delà du cap (ligne réseau LFR), on
-- refuse avec un toast. Repeint la liste de recettes pour refléter la case. No-op hors mon métier / en reroll.
function PW:_ToggleLFWRecipe(entry)
    local sid = entry and entry.spellID
    if not (sid and self.profKey) or self.rerollKey then return end
    local D = COC.Directory
    local cap = (D and D.OFFER_MAX_RECIPES) or 12
    local o = (D and D:MyLFWOffer(self.profKey)) or {}
    for i, v in ipairs(o.recipes or {}) do
        if v == sid then
            self:_EditLFWOffer(function(oo) table.remove(oo.recipes, i); if #oo.recipes == 0 then oo.recipes = nil end end)
            if self.RefreshRecipes then self:RefreshRecipes() end
            return
        end
    end
    if #(o.recipes or {}) >= cap then
        if UI.Toast then UI:Toast(string.format(L["Maximum %d recettes proposées."], cap)) end
        return
    end
    self:_EditLFWOffer(function(oo) oo.recipes = oo.recipes or {}; oo.recipes[#oo.recipes + 1] = sid end)
    if self.RefreshRecipes then self:RefreshRecipes() end
end

-- ------------------------------------------------------------------
-- Rendu
-- ------------------------------------------------------------------
-- Repose TOUTES les valeurs (titre du métier, coches, commission) puis la liste. _filling coupe les
-- handlers OnClick/OnTextChanged le temps du remplissage (sinon SetText re-déclencherait une sauvegarde).
function PW:_RefreshLFWPanel()
    local p = self.lfwPanel; if not (p and self.profKey) then return end
    local D = COC.Directory
    local o = (D and D:MyLFWOffer(self.profKey)) or {}
    p._filling = true
    -- Le mode courant se remarque a CHAQUE ouverture : le panneau est reutilise d'un metier a
    -- l'autre, et un bouton laisse dans l'etat d'une session precedente mentirait.
    if self._SyncLFWModeTabs then self:_SyncLFWModeTabs(p) end
    p.title:SetText(string.format(L["Recherche de travail — %s"], Skin.ProfLabel(self.profKey) or self.profKey))
    p.basics:SetChecked(o.basics and true or false)
    p.skillUp:SetChecked(o.skillUpOnly and true or false)
    local fee = o.fee or 0
    p.gold:SetText(tostring(math.floor(fee / 10000)))
    p.silver:SetText(tostring(math.floor((fee % 10000) / 100)))
    p.copper:SetText(tostring(fee % 100))
    if p.announce then p.announce:SetChecked(COC.db and COC.db.announceTrade == true) end   -- partagé avec le formulaire
    p._filling = nil
    self:_RefreshLFWList()
end

function PW:_RefreshLFWList()
    local p = self.lfwPanel; if not (p and p.scroll and self.profKey) then return end
    local D = COC.Directory
    local o = (D and D:MyLFWOffer(self.profKey)) or {}
    -- Un seul ensemble « coche » a la fois : celui du mode courant. Les deux listes de l'offre
    -- (items et recipes) sont DISJOINTES sur le fil comme en base -- on ne les melange pas ici.
    local recipes = (p.pickMode == "recipes")
    local sel = (recipes and o.recipes) or (not recipes and o.items) or {}
    local cap = recipes and ((D and D.OFFER_MAX_RECIPES) or 12) or maxItems()
    self._lfwProvided = {}
    for _, id in ipairs(sel) do self._lfwProvided[id] = true end
    p.pickHdr:SetText("|cFFE8B84B" .. string.format(
        recipes and L["Recettes proposées (%d/%d)"] or L["Composants fournis (%d/%d)"],
        #sel, cap) .. "|r")
    self._lfwDisplay = self:_LFWDisplayList()
    local n = #self._lfwDisplay
    if self._SyncLFWEmptyMsg then self:_SyncLFWEmptyMsg(n) end
    p.content:SetHeight(math.max(n * ROW_H, VISIBLE * ROW_H))
    local maxScroll = math.max(0, n * ROW_H - (p.scroll:GetHeight() or 0))
    if (p.scroll:GetVerticalScroll() or 0) > maxScroll then p.scroll:SetVerticalScroll(maxScroll) end
    self:_RenderLFWList()
end

function PW:_RenderLFWList()
    local p = self.lfwPanel
    local list = self._lfwDisplay or {}
    local off = math.floor((p.scroll:GetVerticalScroll() or 0) / ROW_H)
    for i = 1, #p.rows do
        local row, e = p.rows[i], list[off + i]
        if e then
            local recipes = (p.pickMode == "recipes")
            row.itemID  = (not recipes) and e.id or nil
            row.spellID = recipes and e.id or nil
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, -(off + i - 1) * ROW_H)
            row.check:SetChecked(self._lfwProvided and self._lfwProvided[e.id] or false)
            -- L'icone d'une recette est lue avec elle par le backend ; celle d'un objet se demande.
            local tex = (recipes and e.icon)
                or (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(e.id))
            row.icon:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.name:SetText(e.name)
            row:Show()
        else
            row.itemID, row.spellID = nil, nil; row:Hide()
        end
    end
end
