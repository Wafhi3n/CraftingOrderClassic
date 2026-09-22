-- CraftingOrderClassic_Enchant_Trade_Open.lua — le bouton « Enchantement » sur la fenêtre d'échange (T6).
-- Spec : docs/specs/enchant-echange-forever.md. Un échange s'ouvre alors que la fenêtre de métier est
-- FERMÉE : l'enchanteur ne voit plus rien depuis que le panneau flottant a disparu (T4). Ce bouton
-- comble ce trou — il ouvre la fenêtre, et le mode Échange de la colonne prend le relais.
--
-- BOUTON SÉCURISÉ de type « sort », c'est-à-dire ce que fait une macro `/cast Enchantement`. Mesure
-- M2 (2026-09-21) : fenêtre FERMÉE, aucun appelant ne choisit le métier d'arrivée — ni
-- `C_TradeSkillUI.OpenTradeSkill`, ni `OpenProfessionUIToSkillLine`, parce qu'à l'affichage CHAQUE
-- onglet latéral relance son propre sort de métier et que la fenêtre atterrit sur le dernier traité.
-- Seul le sort lancé par un vrai clic passe. M2b : fenêtre DÉJÀ ouverte sur un autre métier, le même
-- sort bascule directement sur l'Enchantement, sans cascade — d'où un bouton qui RESTE affiché tant
-- que l'Enchantement n'est pas à l'écran : le second clic finit le travail.
--
-- ⚠️ COMBAT. Un bouton sécurisé ne se configure ni ne s'affiche/masque en combat. On le prépare donc
-- à froid, et s'il n'a jamais pu l'être (métier appris en plein combat), un rappel écrit le remplace.
-- Rien de tout ça ne s'improvise en combat : tout se rejoue à PLAYER_REGEN_ENABLED.

local COC  = CraftingOrderClassic
local Api  = COC.Api
local Skin = COC.UI.Skin
local L    = COC.L
if not (Api and Api.IS_MAINLINE) then return end   -- la fenêtre de métier de Forever, pas celle de l'Era

local Open = {}
COC.EnchantOpen = Open

local btn, hint

local function lockedDown() return InCombatLockdown and InCombatLockdown() end

-- Le NOM du sort de métier de l'Enchantement (tel que le client l'écrit), ou nil si ce perso ne l'a
-- pas appris. Le métier est reconnu par `ResolveProfession` (alias FR/DE/ES de CraftLink), jamais
-- par un libellé écrit à la main — même résolveur que Directory_Skills et l'ouvreur natif.
--
-- Le NOM, et pas l'identifiant : `SECURE_ACTIONS.spell` (SecureTemplates.lua) fait `CastSpellByID`
-- quand l'attribut est un NOMBRE, et `CastSpellByName` quand c'est du texte. Ce qui a été prouvé en
-- jeu (M2b, user), c'est `/cast Enchantement`, donc le chemin par NOM. Posé en identifiant le
-- 2026-09-22, le bouton s'affichait et ne faisait RIEN au clic : l'identifiant du grimoire n'est pas
-- castable tel quel pour un métier.
-- Rend aussi la TEXTURE du métier : c'est l'icône que porte son onglet latéral dans la fenêtre de
-- métier, donc notre bouton se lit comme cet onglet-là (demande du user, 2026-09-22).
local function enchantingSpell()
    local lib = LibStub and LibStub:GetLibrary("CraftLink-1.0", true)
    if not (lib and _G.GetProfessions and _G.GetProfessionInfo) then return nil end
    local p1, p2, faid, fish, cook = GetProfessions()
    for _, idx in pairs({ p1, p2, faid, fish, cook }) do   -- pairs : sauter les trous sans s'arrêter
        local name, texture = GetProfessionInfo(idx)
        if name and lib:ResolveProfession(name) == "Enchanting" then return name, texture end
    end
    return nil
end

local function enchantingShown()
    local pf = _G.ProfessionsFrame
    return (pf and pf:IsShown() and COC.Craft and COC.Craft:OpenProfessionKey() == "Enchanting") and true or false
end

local function build(spellName, texture)
    if btn or not _G.TradeFrame then return end
    -- Un vrai ONGLET LATÉRAL, au bord DROIT de la fenêtre d'échange : même art et même ancrage que
    -- les onglets de métier (demande du user, 2026-09-22). Il se lit comme un onglet du jeu, et la
    -- fenêtre de métier qui s'ouvrira à sa droite ne le recouvre pas — elle se pose plus loin.
    btn = Skin.MakeSideTab(TradeFrame, texture, "SecureActionButtonTemplate")
    btn:SetPoint("TOPLEFT", TradeFrame, "TOPRIGHT", 0, -60)
    btn:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
        GameTooltip:SetText(spellName, 1, 1, 1)
        GameTooltip:AddLine(L["Clic : ouvrir cette fenêtre de métier."], 0.6, 0.6, 0.6)
        GameTooltip:AddLine(L["Si elle s'ouvre sur un autre métier, clique à nouveau."], 0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", GameTooltip_Hide)
    btn:RegisterForClicks("AnyUp", "AnyDown")   -- comme la sonde : le client peut caster au DOWN
    btn:SetScript("PreClick", function(b)
        b.clickedAt = GetTime and GetTime() or 0
        if COC.Trace then COC.Trace:Log("enchopen", "clic sur le bouton Enchantement") end
    end)
    btn:Hide()
    hint = TradeFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", TradeFrame, "TOPRIGHT", 4, -60)
    hint:SetWidth(120); hint:SetJustifyH("LEFT")
    hint:SetText(L["Ouvre ta fenêtre d'Enchantement."])
    hint:Hide()
end

-- Configuration À FROID, une seule fois. Rend vrai quand le bouton sait lancer le sort.
local function configure(spellName)
    if not btn or lockedDown() then return btn and btn.armed or false end
    if btn.armed then return true end
    if not spellName then return false end
    btn:SetAttribute("type", "spell")
    btn:SetAttribute("spell", spellName)
    btn.armed = true
    if COC.Trace then COC.Trace:Log("enchopen", "bouton armé sur le sort « " .. spellName .. " »") end
    return true
end

-- LA CASCADE NE SE RATTRAPE PAS PAR CODE. Fenêtre FERMÉE, le métier d'arrivée n'est pas
-- maîtrisable (M2) : à l'affichage, chaque onglet latéral relance son propre sort et la fenêtre
-- atterrit sur le dernier traité. Essayé le 2026-09-22, fenêtre DÉJÀ ouverte, de basculer par
-- `C_TradeSkillUI.OpenTradeSkill(skillLine)` : **PROTÉGÉE**, blocage `ADDON_ACTION_BLOCKED` imputé
-- nommément à COC (journal du user). Un `pcall` n'attrape pas ce blocage — ce n'est pas une erreur
-- Lua. La note de M2 (« ouvre la fenêtre sans blocage ») ne valait donc que fenêtre FERMÉE.
-- Il reste le geste du JOUEUR : un second clic sur l'onglet, qui bascule sans cascade (M2b). Pour ne
-- pas le laisser deviner, l'onglet PULSE tant que la fenêtre est ouverte sur un autre métier —
-- la lueur est celle des onglets natifs (`TabGlowAnimation` du template).
local function setNudge(on)
    if not (btn and btn.TabGlowAnimation) then return end     -- repli MakeIconButton : pas d'animation
    if on then
        if not btn.TabGlowAnimation:IsPlaying() then btn.TabGlowAnimation:Play() end
    else
        btn.TabGlowAnimation:Stop()
        if btn.TabGlow then btn.TabGlow:SetAlpha(0) end
    end
end

function Open:Hide()
    if lockedDown() then return end      -- masquer un bouton sécurisé en combat est refusé
    if btn then btn:Hide() end
    if hint then hint:Hide() end
end

-- Visible SEULEMENT si : échange ouvert, je suis enchanteur, et l'Enchantement n'est PAS affiché.
-- Un autre métier à l'écran le laisse donc visible, à dessein (M2b : le second clic bascule).
function Open:Update()
    if not (_G.TradeFrame and TradeFrame:IsShown()) then return self:Hide() end
    if enchantingShown() then return self:Hide() end
    local spellName, texture = enchantingSpell()
    if not spellName then return self:Hide() end   -- pas enchanteur : ni bouton ni rappel
    build(spellName, texture)
    if not btn then return end
    if lockedDown() then return end                -- rien ne bouge en combat ; rejoué à la sortie
    local armed = configure(spellName)
    btn:SetShown(armed)
    hint:SetShown(not armed)
    -- Fenêtre ouverte sur un AUTRE métier : l'onglet pulse pour appeler le second clic (M2b).
    setNudge(armed and _G.ProfessionsFrame and ProfessionsFrame:IsShown() and true or false)
end

function Open:Start()
    local f = CreateFrame("Frame")
    Api.RegisterEventsSafe(f, { "TRADE_SHOW", "TRADE_CLOSED", "TRADE_SKILL_SHOW", "TRADE_SKILL_CLOSE",
                                "TRADE_SKILL_LIST_UPDATE", "SKILL_LINES_CHANGED", "PLAYER_REGEN_ENABLED" })
    local pending
    f:SetScript("OnEvent", function(_, ev)
        -- Sortie de combat : tout de suite, sans coalescence. Pendant le combat l'affichage est resté
        -- figé (bouton peut-être visible sur un échange déjà clos), et il doit se réparer au plus tôt.
        if ev == "PLAYER_REGEN_ENABLED" then Open:Update(); return end
        if pending then return end
        pending = true
        C_Timer.After(0.1, function() pending = nil; Open:Update() end)
    end)
end
