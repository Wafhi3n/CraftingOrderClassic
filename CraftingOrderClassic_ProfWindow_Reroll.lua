-- CraftingOrderClassic_ProfWindow_Reroll.lua — vue métier LECTURE SEULE d'un REROLL.
--
-- Ouvre la ProfWindow pour un métier d'un AUTRE perso du compte (hors ligne) : recettes connues +
-- commandes du métier, SANS bouton créer (on n'est pas sur ce perso). 100 % local : recettes lues
-- depuis le cache db.knownRecipes[rerollKey][prof] (feature rerolls v1.9.0), pas depuis la fenêtre
-- native. Réactifs depuis le catalogue CraftLink (quantités « à fournir », pas de have/need des sacs).
-- Renoncements assumés (indispo hors fenêtre native) : couleur par difficulté, nb craftable, have/need.
-- Greffe des méthodes sur COC.ProfWindow (créée par ProfWindow.lua, chargé AVANT).

local COC = CraftingOrderClassic
local PW  = COC.ProfWindow
local Skin = COC.UI and COC.UI.Skin
local L   = COC.L

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

-- Ouvre la vue lecture seule pour (métier, reroll). rerollKey = « Nom-Royaume », name = nom court.
function PW:OpenForReroll(prof, rerollKey, name)
    if not (prof and rerollKey) then return end
    self.rerollKey = rerollKey
    self.rerollName = name
    self.standaloneKey = prof
    self.selectedIndex = nil
    self:Build()
    -- Ferme une fenêtre native éventuellement ouverte (comme _OpenCompact) : sinon _DoRefresh la verrait
    -- et repasserait en mode PLEIN natif. OnProfessionClose voit rerollKey → reste sur notre vue.
    local craft = COC.Craft
    if craft and craft:GetOpenProfessionInfo() then
        if craft.IsCraftOpen and craft:IsCraftOpen() then if CloseCraft then CloseCraft() end
        elseif CloseTradeSkill then CloseTradeSkill() end
    else
        if not self.frame:IsShown() then self.frame:Show() end
        self:Refresh()
    end
end

-- Liste plate des recettes CONNUES du reroll pour ce métier → self.recipes (format vue métier :
-- {index=spellID, name, itemID, icon, link}). _RecipeDisplayList ajoute lui-même les en-têtes de
-- section et le tri (COC.SectionOf). Pas de difficulty/numAvailable (indispo hors fenêtre native).
function PW:_RerollRecipeList()
    local c = CL()
    local part = COC.db and COC.db.knownRecipes and COC.db.knownRecipes[self.rerollKey]
    local set = part and part[self.profKey]
    if not (set and c) then return {} end
    local out = {}
    for sid in pairs(set) do
        local itemID = c:RecipeProduct(self.profKey, sid)
        local nm = c:RecipeName(sid) or (itemID and c:ItemName(itemID)) or ("spell:" .. sid)
        out[#out + 1] = {
            index = sid, name = nm, itemID = itemID,
            icon = (Skin and Skin.Icon(itemID, sid)) or nil,
            link = itemID and ("item:" .. itemID) or nil,
        }
    end
    return out
end

-- Réactifs d'une recette depuis le CATALOGUE (mode reroll) — même forme que Craft:Reagents mais
-- « à fournir » seulement (need), sans have (on ne connaît pas les sacs d'un autre perso).
function PW:_RerollReagents(spellID)
    local c = CL()
    local reag = c and spellID and c:RecipeReagents(self.profKey, spellID)
    if not reag then return {} end
    local out = {}
    for _, rg in ipairs(reag) do
        local id, qty = rg[1], rg[2] or 1
        out[#out + 1] = {
            name = c:ItemName(id) or ("item:" .. id),
            texture = (GetItemIcon and GetItemIcon(id)) or nil,
            need = qty, readonly = true, link = "item:" .. id,
        }
    end
    return out
end

-- Un perso du compte (reroll) sait-il faire cette commande ? (marqueur ✓ colonne Commandes en mode
-- reroll) — lit la partition du reroll, patron Handoff:MyRerollCanCraft. Renvoie true/false/nil.
function PW:RerollKnows(o)
    local prof = o and o.profession; if not (prof and self.rerollKey) then return nil end
    local part = COC.db and COC.db.knownRecipes and COC.db.knownRecipes[self.rerollKey]
    local set = part and part[prof]
    if not set then return false end
    if o.spellID and set[o.spellID] then return true end
    if o.itemID then
        local c = CL(); local i2s = c and c:ItemToSpell(prof)
        local sid = i2s and i2s[o.itemID]
        if sid and set[sid] then return true end
    end
    return false
end

-- ------------------------------------------------------------------
-- Ouverture de la FONTE (facette CRAFT du Minage) — appelée par PW:OpenFor("Mining").
-- ------------------------------------------------------------------
-- Le Minage a deux facettes : la RÉCOLTE (minerais, pas de fenêtre en jeu) et la FONTE (minerai →
-- lingot), qui se lance par un SORT (2656) et affiche une fenêtre de CRAFT (CraftFrame, comme
-- l'Enchantement). Grâce aux alias (Libs/CraftLink-1.0/Data/Smelting.lua), cette fenêtre se résout
-- en « Mining » : la vue pleine 3 colonnes se monte via OnProfessionShow. Repli en vue compacte si la
-- fenêtre ne s'ouvre pas (Minage non appris, combat…). Vit ici (et non dans ProfWindow.lua) pour tenir
-- ce dernier sous le plafond anti-monolithe — avec les autres variantes d'ouverture (reroll).
function PW:_OpenSmelting()
    local craft = COC.Craft
    if craft and craft:GetOpenProfessionInfo() and craft:OpenProfessionKey() == "Mining" then
        self:OnProfessionShow(); return          -- déjà ouverte nativement → (ré)affiche la vue pleine
    end
    local spell = GetSpellInfo and GetSpellInfo(2656)   -- nom localisé du sort « Fonte »
    if spell and spell ~= "" and CastSpellByName then
        self.standaloneKey = nil
        CastSpellByName(spell)                    -- ouvre la fenêtre de fonte → OnProfessionShow
        if C_Timer and C_Timer.After then
            C_Timer.After(0.4, function()
                local c = COC.Craft
                if not (c and c:GetOpenProfessionInfo()) then PW:_OpenCompact("Mining") end
            end)
        end
        return
    end
    self:_OpenCompact("Mining")
end
