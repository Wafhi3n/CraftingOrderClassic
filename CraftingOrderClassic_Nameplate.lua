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

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end

-- Historique du gate : on a longtemps cru que ce module exigeait l'UI moderne des plaques (1.15.9,
-- build 11509) et il s'auto-désactivait sous ce seuil. Test manuel en jeu sur SoD live (Era 1.15.8,
-- tocversion 11508) le 2026-07-14 : il fonctionne SANS erreur → gate de build RETIRÉ. Seule garde
-- restante : C_NamePlate présent (no-op sinon). ⚠️ À re-vérifier quand même sur la vraie UI 1.15.9.
local function secure() return (issecure and issecure()) or false end
local function plateFor(unit)
    return (unit and C_NamePlate and C_NamePlate.GetNamePlateForUnit
        and C_NamePlate.GetNamePlateForUnit(unit, secure())) or nil
end

-- Icône attachée à une plaque (créée à la demande, mémorisée SUR la plaque → réutilisée d'un unit à l'autre).
-- Mini-marqueurs d'OFFRE accrochés au cadre 22 px : pièce (commission demandée) et sac (fournit des
-- composants — de base ou listés). Display-only, textures VÉRIFIÉES dans l'export Classic ; détails
-- au survol du JOUEUR (tooltip monde) — la plaque reste sans souris (ne pas gêner le clic-cible).
local function ensureIcon(plate)
    if plate.cocLFW then return plate.cocLFW end
    local f = CreateFrame("Frame", nil, plate)
    f:SetSize(22, 22); f:SetFrameStrata("HIGH")
    f:SetPoint("BOTTOM", plate, "TOP", 0, 2)
    local bg = f:CreateTexture(nil, "BACKGROUND"); bg:SetPoint("CENTER"); bg:SetSize(26, 26)
    bg:SetColorTexture(0, 0, 0, 0.55)
    local tex = f:CreateTexture(nil, "OVERLAY"); tex:SetAllPoints(); tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.tex = tex
    local coin = f:CreateTexture(nil, "OVERLAY", nil, 1)
    coin:SetSize(10, 10); coin:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 4, -3)
    coin:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon"); coin:Hide()
    f.coin = coin
    local bag = f:CreateTexture(nil, "OVERLAY", nil, 1)
    bag:SetSize(10, 10); bag:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", -4, -3)
    bag:SetTexture("Interface\\Icons\\INV_Misc_Bag_08"); bag:SetTexCoord(0.08, 0.92, 0.08, 0.92); bag:Hide()
    f.bag = bag
    -- Nom de la 1re recette PROPOSÉE (+N si plusieurs), à DROITE du cadre. Fond translucide pour rester
    -- lisible sur tout décor. Display-only ; la liste complète est dans le tooltip au survol du JOUEUR.
    local rbg = f:CreateTexture(nil, "BACKGROUND")
    rbg:SetColorTexture(0, 0, 0, 0.55); rbg:Hide()
    local rfs = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rfs:SetPoint("LEFT", f, "RIGHT", 4, 0); rfs:SetJustifyH("LEFT"); rfs:SetWordWrap(false); rfs:Hide()
    rbg:SetPoint("TOPLEFT", rfs, "TOPLEFT", -3, 2); rbg:SetPoint("BOTTOMRIGHT", rfs, "BOTTOMRIGHT", 3, -2)
    f.recipeFS, f.recipeBg = rfs, rbg
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
        local o = e.offer
        ic.coin:SetShown((o and o.fee and o.fee > 0) and true or false)
        ic.bag:SetShown((o and (o.basics or (o.items and #o.items > 0))) and true or false)
        -- Recettes proposées (verbe LFR) : 1re en clair + « +N » si d'autres. Nom résolu par GetSpellInfo
        -- (via CraftLink) → lisible même si CE joueur n'a pas la recette apprise.
        local recs = e.recipes
        if recs and #recs > 0 then
            local c = CL()
            local label = (c and c.RecipeName and c:RecipeName(recs[1])) or ("spell:" .. recs[1])
            if #recs > 1 then label = label .. "  |cFFAAAAAA+" .. (#recs - 1) .. "|r" end
            ic.recipeFS:SetText(label); ic.recipeFS:Show(); ic.recipeBg:Show()
        else
            ic.recipeFS:Hide(); ic.recipeBg:Hide()
        end
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
