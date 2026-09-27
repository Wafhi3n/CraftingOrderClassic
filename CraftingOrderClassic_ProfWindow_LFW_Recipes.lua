-- CraftingOrderClassic_ProfWindow_LFW_Recipes.lua — le SÉLECTEUR DE RECETTES de l'offre LFW.
--
-- Le panneau d'offre savait déjà choisir des RÉACTIFS (« je fournis ceci »). Il sait maintenant
-- choisir des RECETTES (« je propose ceci »), diffusées par le verbe LFR. Plutôt qu'un second
-- sélecteur — sa liste, sa recherche, son pool de lignes, son rendu — le picker existant gagne
-- DEUX MODES et une rangée pour en changer. Un seul chemin de code à corriger le jour où il aura
-- un défaut, et 100 lignes de duplication en moins.
--
-- Ce fichier ne porte que ce qui est PROPRE aux recettes : l'univers, la rangée de modes, la
-- bascule. Les branches dans `_LFWDisplayList` / `_RefreshLFWList` / `_RenderLFWList` restent chez
-- leur propriétaire (_ProfWindow_LFW.lua), minces et lisibles. Il vit à part parce que son hôte
-- frôlait les 500 lignes, pas parce qu'il est d'une autre nature.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L
local PW   = COC.ProfWindow

-- ------------------------------------------------------------------
-- Univers : ce que CE personnage sait faire dans le métier ouvert
-- ------------------------------------------------------------------
-- Lu sur le CLIENT (`Craft:ReadRecipes`), pas sur notre catalogue : on propose ce qu'on sait
-- faire, et le client seul le sait. `ReadRecipes` écarte déjà les non-apprises, y compris sur
-- MAINLINE où la fenêtre native les liste aussi.
--
-- MIS EN CACHE, et VIDÉ SUR ÉVÉNEMENT. `ReadRecipes` parcourt toute la liste du client en
-- appelant plusieurs API par ligne : le rappeler à chaque touche frappée dans la recherche du
-- picker serait cher pour rien. Mais on apprend des recettes en jouant, donc un cache « pour la
-- session » mentirait — celui qui vient d'acheter son plan doit pouvoir le proposer tout de suite.
-- `TRADE_SKILL_LIST_UPDATE` est exactement l'événement qui dit que cette liste a changé : il vide
-- les DEUX univers, celui des recettes et celui des réactifs, qui en dérive.
--
-- Une recette sans `spellID` est écartée : c'est l'identifiant que le fil transporte (LFR), donc
-- sans lui il n'y a rien à annoncer. Le backend le dit lui-même : il « peut rester nil si l'API
-- sous-jacente ne l'expose pas ».
function PW:_LFWRecipeUniverse()
    local key = self.profKey or "?"
    self._lfwRecUniv = self._lfwRecUniv or {}
    if self._lfwRecUniv[key] then return self._lfwRecUniv[key] end
    local craft = COC.Craft
    local list  = craft and craft.ReadRecipes and craft:ReadRecipes()
    local out, seen = {}, {}
    for _, r in ipairs(list or {}) do
        if not r.isHeader and r.spellID and not seen[r.spellID] then
            seen[r.spellID] = true
            out[#out + 1] = { id = r.spellID, name = r.name or ("spell:" .. r.spellID), icon = r.icon }
        end
    end
    -- Une lecture VIDE ne se met pas en cache : `ReadRecipes` rend nil quand aucune fenêtre de
    -- métier n'est ouverte, et figer ce vide condamnerait le picker pour toute la session.
    if #out > 0 then self._lfwRecUniv[key] = out end
    return out
end

-- Le client dit lui-même quand sa liste de recettes change — apprentissage, changement de métier,
-- premier remplissage après l'ouverture. On ne devine pas, on écoute.
local inval = CreateFrame("Frame")
inval:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
inval:SetScript("OnEvent", function()
    PW._lfwRecUniv, PW._lfwUniv = nil, nil
    if PW.lfwPanel and PW.lfwPanel:IsShown() and PW._RefreshLFWList then PW:_RefreshLFWList() end
end)

-- ------------------------------------------------------------------
-- La rangée de modes du picker
-- ------------------------------------------------------------------
-- Deux boutons étiquetés, pas deux icônes : même raison que le bouton « Offre » de la bande — une
-- icône de 16 px se lit comme un bouton oublié là, un mot dit ce qu'il fait (leçon du 2026-09-19,
-- payée sur capture dans cette colonne).
function PW:_BuildLFWModeTabs(p)
    if p.modeBtns then return end
    p.pickMode = "items"
    local defs = { { id = "items",   label = L["Réactifs"] },
                   { id = "recipes", label = L["Recettes"] } }
    p.modeBtns = {}
    local prev
    for _, d in ipairs(defs) do
        local b = Skin.MakeGoldButton(p, 74, 16, d.label)
        if prev then b:SetPoint("LEFT", prev, "RIGHT", 4, 0)
        else b:SetPoint("TOPLEFT", 12, -(PW.LFW_LIST_TOP - 46)) end
        b:SetScript("OnClick", function() PW:_SetLFWPickMode(d.id) end)
        p.modeBtns[d.id] = b
        prev = b
    end
    self:_SyncLFWModeTabs(p)
end

-- ⚠️ Le panneau se passe en ARGUMENT, et ce n'est pas un raffinement. `_BuildLFWPanel` n'assigne
-- `self.lfwPanel` qu'APRES avoir construit le picker : appelee sans argument depuis la
-- construction, cette fonction lisait nil et sortait en silence. Resultat vu en jeu le 2026-09-26 :
-- les deux boutons de mode rendus a l'identique, aucun marque, impossible de savoir lequel est
-- actif. Un etat qui ne se voit pas vaut un etat faux.
function PW:_SyncLFWModeTabs(panel)
    local p = panel or self.lfwPanel
    if not (p and p.modeBtns) then return end
    for id, b in pairs(p.modeBtns) do b:SetSelected(p.pickMode == id) end
end

-- Changer de mode remet la recherche et le défilement À ZÉRO. Garder le texte tapé pour les
-- réactifs en passant aux recettes donnerait une liste filtrée sans qu'on voie pourquoi — et une
-- liste vide qu'on ne s'explique pas se lit comme un bug.
function PW:_SetLFWPickMode(mode)
    local p = self.lfwPanel
    if not p or p.pickMode == mode then return end
    p.pickMode = mode
    p._filling = true
    if p.search then p.search:SetText(""); p.search:ClearFocus() end
    p._filling = nil
    if p.scroll then p.scroll:SetVerticalScroll(0) end
    self:_SyncLFWModeTabs()
    self:_RefreshLFWList()
end

-- ------------------------------------------------------------------
-- L'état VIDE du picker
-- ------------------------------------------------------------------
-- Une liste vide sans un mot se lit comme une panne — c'est exactement ce qu'a donné Herbalism sur
-- la capture du 2026-09-26 : le panneau ouvert, « Provided reagents (0/15) », et rien en dessous.
-- Le joueur ne peut pas savoir si l'addon n'a rien trouvé, si sa recherche ne matche pas, ou si
-- c'est cassé. On le dit, et on distingue les deux cas : une recherche qui ne rend rien n'est pas
-- un métier qui n'a rien.
function PW:_BuildLFWEmptyMsg(p)
    if p.emptyMsg then return end
    local fs = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    fs:SetPoint("TOPLEFT", p.scroll, "TOPLEFT", 10, -14)
    fs:SetPoint("RIGHT", p.scroll, "RIGHT", -10, 0)
    fs:SetJustifyH("LEFT"); fs:SetWordWrap(true); fs:Hide()
    p.emptyMsg = fs
end

function PW:_SyncLFWEmptyMsg(n)
    local p = self.lfwPanel
    if not (p and p.emptyMsg) then return end
    if n > 0 then p.emptyMsg:Hide(); return end
    local searching = (p.search and (p.search:GetText() or "") ~= "")
    p.emptyMsg:SetText(searching and L["Aucun résultat pour cette recherche."]
        or L["Rien à afficher pour ce métier."])
    p.emptyMsg:Show()
end
