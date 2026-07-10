-- CraftingOrderClassic_Nameplate.lua — icône « recherche de travail » (LFW) sur les plaques.
--
-- Quand un joueur marqué LFW (cf. Directory_LFW : Dir:LFWOf) a une plaque visible, on accroche l'icône
-- de SON métier au-dessus. Events NAME_PLATE_UNIT_ADDED/_REMOVED + C_NamePlate.GetNamePlateForUnit /
-- GetNamePlates / frame.namePlateUnitToken (API vérifiée dans la source Classic Era). Purement DÉCORATIF
-- (aucune frame protégée touchée), no-op si les plaques sont désactivées (C_NamePlate absent).
-- ⚠️ Les artisans LFW sont en général AMIS/même faction → visible seulement si les plaques AMIES sont
-- activées (CVar nameplateShowFriends).

local COC = CraftingOrderClassic
local NP  = {}
COC.Nameplate = NP

local function secure() return (issecure and issecure()) or false end
local function plateFor(unit)
    return (unit and C_NamePlate and C_NamePlate.GetNamePlateForUnit
        and C_NamePlate.GetNamePlateForUnit(unit, secure())) or nil
end

-- Icône attachée à une plaque (créée à la demande, mémorisée SUR la plaque → réutilisée d'un unit à l'autre).
local function ensureIcon(plate)
    if plate.cocLFW then return plate.cocLFW end
    local f = CreateFrame("Frame", nil, plate)
    f:SetSize(22, 22); f:SetFrameStrata("HIGH")
    f:SetPoint("BOTTOM", plate, "TOP", 0, 2)
    local bg = f:CreateTexture(nil, "BACKGROUND"); bg:SetPoint("CENTER"); bg:SetSize(26, 26)
    bg:SetColorTexture(0, 0, 0, 0.55)
    local tex = f:CreateTexture(nil, "OVERLAY"); tex:SetAllPoints(); tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.tex = tex
    plate.cocLFW = f
    return f
end

-- Nom court du joueur d'un unit (nil si PNJ) → clé du roster / de la table LFW.
local function playerName(unit)
    if not (UnitIsPlayer and UnitIsPlayer(unit)) then return nil end
    return (GetUnitName and GetUnitName(unit, false)) or (UnitName and UnitName(unit)) or nil
end

-- (Re)peint la plaque d'un unit selon le statut LFW du joueur.
function NP:_Apply(unit)
    local plate = plateFor(unit); if not plate then return end
    local name = playerName(unit)
    local D = COC.Directory
    local e = name and D and D.LFWOf and D:LFWOf(name)
    if e then
        local S = COC.UI and COC.UI.Skin
        local ic = ensureIcon(plate)
        ic.tex:SetTexture((S and S.ProfIcon and S.ProfIcon(e.prof)) or "Interface\\Icons\\INV_Misc_QuestionMark")
        ic:Show()
    elseif plate.cocLFW then
        plate.cocLFW:Hide()
    end
end

-- Le statut LFW d'un NOM a changé (OnLFW) → repeint la plaque visible de ce joueur. Le nom n'étant pas
-- résolu en unit ici, on balaie les plaques présentes (peu nombreuses à l'écran).
function NP:Refresh(name)
    if not (C_NamePlate and C_NamePlate.GetNamePlates) then return end
    for _, p in ipairs(C_NamePlate.GetNamePlates(secure()) or {}) do
        if p.namePlateUnitToken then self:_Apply(p.namePlateUnitToken) end
    end
end

function NP:Start()
    if not C_NamePlate then return end   -- plaques indispo → no-op
    local f = CreateFrame("Frame")
    f:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    f:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    f:SetScript("OnEvent", function(_, ev, unit)
        if ev == "NAME_PLATE_UNIT_ADDED" then NP:_Apply(unit)
        else local plate = plateFor(unit); if plate and plate.cocLFW then plate.cocLFW:Hide() end end
    end)
end
