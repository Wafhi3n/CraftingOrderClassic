-- CraftingOrderClassic_Craft.lua — socle de lecture LIVE de la fenêtre métier (migration de la
-- fenêtre custom depuis Guild Economy / TradeScanner_Craft.lua). Lit indifféremment l'API
-- TradeSkill (métiers normaux) et l'API Craft (Enchantement / Dressage en Classic Era).
-- Aucune UI ici : juste la lecture (recettes, réactifs, rang) + le déclenchement du craft.
-- Reste lisible tant que la SESSION de métier est ouverte, même si la frame Blizzard est masquée.

local COC = CraftingOrderClassic
local Craft = {}
COC.Craft = Craft

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

function Craft:IsCraftOpen()
    return CraftFrame and CraftFrame:IsShown()
end

-- itemID, link de la recette sélectionnée (les deux API).
function Craft:GetSelectedRecipe()
    if self:IsCraftOpen() then
        local idx = GetCraftSelectionIndex and GetCraftSelectionIndex()
        if idx and idx > 0 and GetCraftItemLink then
            local link = GetCraftItemLink(idx)
            if link then return tonumber(link:match("|Hitem:(%d+)")), link end
        end
        return nil
    end
    local idx = GetTradeSkillSelectionIndex and GetTradeSkillSelectionIndex()
    if not idx or idx < 1 then return nil end
    local link = GetTradeSkillItemLink and GetTradeSkillItemLink(idx)
    if not link then return nil end
    return tonumber(link:match("|Hitem:(%d+)")), link
end

-- Nom localisé + isCraft du métier ouvert (ou nil).
function Craft:GetOpenProfessionInfo()
    if CraftFrame and CraftFrame:IsShown() then
        local name = (GetCraftDisplaySkillLine and GetCraftDisplaySkillLine())
                  or (GetCraftName and GetCraftName())
        if name and name ~= "" and name ~= "UNKNOWN" then return name, true end
    end
    if GetTradeSkillLine then
        local name = GetTradeSkillLine()
        if name and name ~= "" and name ~= "UNKNOWN" then return name, false end
    end
    return nil, nil
end

local TRADESKILL_API = {
    getNum      = function() return (GetNumTradeSkills and GetNumTradeSkills()) or 0 end,
    getInfo     = function(i) return GetTradeSkillInfo(i) end,
    getLink     = function(i) return GetTradeSkillItemLink(i) end,
    getSkillName= function() return GetTradeSkillLine and GetTradeSkillLine() end,
    isHeader    = function(t) return t == "header" or t == "subheader" end,
    norm        = function(i) local n, t, avail = GetTradeSkillInfo(i); return n, t, avail end,
    getIcon     = function(i) return GetTradeSkillIcon and GetTradeSkillIcon(i) end,
    getNumMade  = function(i) return GetTradeSkillNumMade and GetTradeSkillNumMade(i) end,
    getNumReag  = function(i) return (GetTradeSkillNumReagents and GetTradeSkillNumReagents(i)) or 0 end,
    getReagInfo = function(i, j) return GetTradeSkillReagentInfo(i, j) end,
    getReagLink = function(i, j) return GetTradeSkillReagentItemLink and GetTradeSkillReagentItemLink(i, j) end,
    craft       = function(i, n) if DoTradeSkill then DoTradeSkill(i, n or 1) end end,
}
local CRAFT_API = {
    getNum      = function() return (GetNumCrafts and GetNumCrafts()) or 0 end,
    getInfo     = function(i) return GetCraftInfo(i) end,
    getLink     = function(i) return GetCraftItemLink and GetCraftItemLink(i) end,
    getSkillName= function() return (GetCraftDisplaySkillLine and GetCraftDisplaySkillLine())
                                  or (GetCraftName and GetCraftName()) end,
    isHeader    = function(t) return t == "header" end,
    norm        = function(i) local n, _, t, avail = GetCraftInfo(i); return n, t, avail end,
    getIcon     = function(i) return GetCraftIcon and GetCraftIcon(i) end,
    getNumMade  = function() return 1, 1 end,
    getNumReag  = function(i) return (GetCraftNumReagents and GetCraftNumReagents(i)) or 0 end,
    getReagInfo = function(i, j) return GetCraftReagentInfo(i, j) end,
    getReagLink = function(i, j) return GetCraftReagentItemLink and GetCraftReagentItemLink(i, j) end,
    craft       = function(_)
        -- DoCraft est une fonction PROTÉGÉE en Classic Era : un addon ne peut PAS l'appeler (même
        -- depuis un clic) après avoir neutralisé l'UI native. Le craft d'enchantement passe donc par
        -- un bouton SÉCURISÉ qui redirige le clic vers le bouton natif Blizzard (cf.
        -- ProfWindow_Detail : detCreateBtn → CraftCreateButton). Ici : no-op volontaire.
    end,
}

-- Table d'API du métier ACTUELLEMENT ouvert (ou nil), + isCraft.
function Craft:GetActiveAPI()
    local name, isCraft = self:GetOpenProfessionInfo()
    if not name then return nil end
    return (isCraft and CRAFT_API or TRADESKILL_API), isCraft
end

-- Clé interne (EN) du métier ouvert via CraftLink, ou nil.
function Craft:OpenProfessionKey()
    local name = self:GetOpenProfessionInfo()
    local c = CL()
    return (name and c and c:ResolveProfession(name)) or nil
end

local DIFF_COLOR = {
    optimal = { r = 1.00, g = 0.50, b = 0.25 }, medium = { r = 1.00, g = 1.00, b = 0.00 },
    easy    = { r = 0.25, g = 0.75, b = 0.25 }, trivial = { r = 0.50, g = 0.50, b = 0.50 },
}
function Craft:DifficultyColor(difficulty)
    local c = (_G.TradeSkillTypeColor and _G.TradeSkillTypeColor[difficulty])
           or (_G.CraftTypeColor and _G.CraftTypeColor[difficulty])
           or DIFF_COLOR[difficulty]
    if c then return c.r, c.g, c.b end
    return 0.9, 0.9, 0.9
end

-- Rang du métier ouvert (skill, max). Côté TradeSkill : GetTradeSkillLine. Côté Craft (Enchantement)
-- l'API n'expose pas le rang → on le lit via l'annuaire (Directory tient mySkills à jour via l'API
-- skill, lisible sans ouvrir la fenêtre).
function Craft:OpenRank()
    if not self:IsCraftOpen() and GetTradeSkillLine then
        local _, rank, maxRank = GetTradeSkillLine()
        if rank and rank > 0 then return rank, maxRank end
    end
    local key = self:OpenProfessionKey()
    local D = COC.Directory
    if key and D and D.mySkills and D.mySkills[key] then
        return D.mySkills[key][1], D.mySkills[key][2]
    end
    return nil
end

-- Toute la liste de recettes (en-têtes inclus, isHeader=true), ou nil si fermé.
function Craft:ReadRecipes()
    local api = self:GetActiveAPI()
    if not api then return nil end
    local out, num = {}, api.getNum()
    for i = 1, num do
        local name, skillType, numAvailable = api.norm(i)
        if name then
            if api.isHeader(skillType) then
                out[#out + 1] = { index = i, name = name, isHeader = true }
            else
                local link   = api.getLink(i)
                local itemID = link and tonumber(link:match("|Hitem:(%d+)")) or nil
                local mn, mx = api.getNumMade(i)
                out[#out + 1] = {
                    index = i, name = name, link = link, itemID = itemID,
                    icon = api.getIcon(i), difficulty = skillType,
                    numAvailable = numAvailable or 0, numMade = mn or 1, numMadeMax = mx or mn or 1,
                }
            end
        end
    end
    return out
end

-- Réactifs d'une recette : { {name, texture, need, have, link}, ... }.
function Craft:Reagents(index)
    local api = self:GetActiveAPI()
    if not api or not index then return {} end
    local out, n = {}, api.getNumReag(index)
    for j = 1, n do
        local rName, texture, need, have = api.getReagInfo(index, j)
        out[#out + 1] = { name = rName, texture = texture, need = need or 0, have = have or 0,
                          link = api.getReagLink(index, j) }
    end
    return out
end

-- Déclenche le craft (DoTradeSkill répété, ou DoCraft simple).
function Craft:Do(index, count)
    local api = self:GetActiveAPI()
    if not api or not index then return end
    api.craft(index, count or 1)
end
