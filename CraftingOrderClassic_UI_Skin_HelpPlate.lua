-- CraftingOrderClassic_UI_Skin_HelpPlate.lua — kit d'AIDE CONTEXTUELLE (le « bouton i » de retail).
-- À NE PAS confondre avec _UI_Help.lua (l'onglet « Aide », une PAGE de doc défilante qu'on lit). Ici
-- c'est l'overlay EN PLACE : un clic fige la fenêtre et pose des bulles sur ses vrais contrôles. Le jeu
-- retail a les deux ; complémentaires (bulles courtes ici, détail dans l'onglet Aide).
--
-- Même table `Skin` que les autres _UI_Skin*. On EMPRUNTE le système natif `Blizzard_HelpPlate` (chargé
-- sur Era : dépendance dure de Blizzard_UIPanels_Game) : un voile plein écran `HelpPlateCanvas` capte
-- TOUS les clics de la fenêtre, et chaque « tuile » surligne un rectangle avec une bulle fléchée au
-- survol. Zéro asset (l'icône est `Interface\common\help-i`, celle de retail).
--
-- LE PARI « aide sur les objets SPEC » (idée user) : `Skin.MakeSections` rend `{ [id] = frame }`, donc
-- chaque section EST une vraie frame positionnée. Au lieu de coder les coordonnées à la main (ce que
-- fait Blizzard), on TAGUE le nœud SPEC (`help = "<id>"`, `helpDir = "LEFT|RIGHT|UP|DOWN"`) et on dérive
-- la `HighLightBox` du rectangle RÉEL de la frame, à l'ouverture. Le TEXTE reste du contenu (locale),
-- déclaré côté consommateur — la SPEC ne porte que le point d'accroche (cf. discipline SPEC=structure).
--
-- ⚠️ ÉCHELLES : le voile est reparenté sur UIParent (donc à l'échelle UIParent) mais ANCRÉ sur la
-- fenêtre. On normalise chaque rectangle en PIXELS ÉCRAN puis on divise par l'échelle du voile
-- (`HelpPlate.GetEffectiveScale`) → robuste quelle que soit l'échelle d'UI, sans supposer scale=1.

local COC  = CraftingOrderClassic
local Skin = COC.UI.Skin

-- Parcourt un arbre de SPEC (cf. MakeSections) et collecte les nœuds tagués `help`, en profondeur.
-- Rend { { id=, key=, dir= }, ... } dans l'ordre de déclaration. `key` = valeur brute de `help` (un id
-- de texte, résolu en locale par le consommateur — pas ici : la SPEC ne connaît pas COC.L).
function Skin.CollectHelp(spec)
    local out = {}
    local function walk(node)
        if node.help and node.id then
            out[#out + 1] = { id = node.id, key = node.help, dir = node.helpDir }
        end
        for _, child in ipairs(node) do walk(child) end
    end
    for _, col in ipairs(spec) do walk(col) end
    return out
end

-- Bouton rond « i », posé un peu HORS CADRE (retail). Template natif RinglessHelpPlateButtonTemplate
-- (help-i + surbrillance) ; repli défensif si absent. `onToggle` au clic. opts : size · point (ancre
-- {p, rel, relP, x, y}) · tooltip.
function Skin.MakeHelpButton(parent, onToggle, opts)
    opts = opts or {}
    local b
    local ok = pcall(function()
        b = CreateFrame("Button", nil, parent, "RinglessHelpPlateButtonTemplate")
    end)
    if not ok or not b then
        b = CreateFrame("Button", nil, parent)
        b:SetNormalTexture("Interface\\common\\help-i")
        b:SetHighlightTexture("Interface\\common\\help-i", "ADD")
    end
    b:SetSize(opts.size or 28, opts.size or 28)
    local a = opts.point or { "CENTER", parent, "TOPLEFT", 8, 6 }
    b:ClearAllPoints(); b:SetPoint(a[1], a[2], a[3], a[4], a[5])
    b:SetFrameStrata("HIGH"); b:SetFrameLevel(parent:GetFrameLevel() + 20)
    b:SetScript("OnClick", function() if onToggle then onToggle() end end)
    if opts.tooltip then
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(opts.tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", GameTooltip_Hide)
    end
    return b
end

local BTN = 46   -- côté de la pastille « i » d'une tuile (HelpPlateTile.Button, cf. Blizzard_HelpPlate.xml)

-- Ouvre le voile d'aide natif sur `win`, avec une tuile par entrée.
-- entries : { { frame = <Region>, text = <string>, dir = "UP|DOWN|LEFT|RIGHT" }, ... }.
-- La géométrie est LUE À CHAUD (positions réelles), donc appelable à chaque ouverture. Rend true si posé.
function Skin.ShowHelp(win, entries, mainButton)
    if not (win and HelpPlate and HelpPlateCanvas) then return false end
    local wl, wt = win:GetLeft(), win:GetTop()
    if not (wl and wt) then return false end
    local scale = HelpPlate.GetEffectiveScale()
    if not scale or scale == 0 then scale = 1 end
    local ws = win:GetEffectiveScale()
    wl, wt = wl * ws, wt * ws   -- coin haut-gauche de la fenêtre, en pixels écran

    local info = {
        FramePos  = { x = 0, y = 0 },
        FrameSize = { width = win:GetWidth() * ws / scale, height = win:GetHeight() * ws / scale },
    }
    for _, e in ipairs(entries) do
        local fr = e.frame
        if fr and fr:GetLeft() then
            local fs = fr:GetEffectiveScale()
            local x = (fr:GetLeft() * fs - wl) / scale
            local y = (fr:GetTop()  * fs - wt) / scale   -- ≤ 0 (section sous le haut de la fenêtre)
            local w = fr:GetWidth()  * fs / scale
            local h = fr:GetHeight() * fs / scale
            info[#info + 1] = {
                HighLightBox = { x = x, y = y, width = w, height = h },
                ButtonPos    = { x = x + w / 2 - BTN / 2, y = y - h / 2 + BTN / 2 },
                ToolTipText  = e.text,
                ToolTipDir   = e.dir or "RIGHT",
            }
        end
    end
    if #info == 0 then return false end
    HelpPlate.Show(info, win, mainButton)
    -- Le voile natif n'a pas de closer par défaut → un clic sur la partie sombre le referme.
    HelpPlateCanvas:SetScript("OnClick", function() Skin.HideHelp() end)
    -- Échap ferme l'AIDE, pas la fenêtre : le voile (toplevel, clavier activé) intercepte la touche et
    -- la CONSOMME (SetPropagateKeyboardInput false) → l'Échap ne redescend pas jusqu'à l'EscProxy de la
    -- fenêtre. Les autres touches sont laissées passer (propagate true). Idempotent (re-Show OK).
    HelpPlateCanvas:EnableKeyboard(true)
    HelpPlateCanvas:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" and Skin._helpOpen then
            self:SetPropagateKeyboardInput(false)
            Skin.HideHelp()
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)
    Skin._helpOpen = true
    return true
end

function Skin.HideHelp()
    if HelpPlate and Skin._helpOpen then HelpPlate.Hide(true) end
    Skin._helpOpen = nil
end

function Skin.HelpIsOpen()
    return Skin._helpOpen == true
end
