-- CraftingOrderClassic_UI_Skin_Dropdown.lua — menu deroulant (selecteur) du kit natif.
-- Extrait de _UI_Skin_Native.lua le 2026-09-19 (anti-monolithe) en meme temps que sa reecriture
-- SANS UIDropDownMenu : c'est lui qui teintait l'interface de Blizzard (cf. l'en-tete ci-dessous).
-- Charge APRES _UI_Skin_Native.lua (il s'appuie sur Skin.MakeFlyout et Skin.SkinWell).

local COC  = CraftingOrderClassic
local Skin = COC.UI.Skin

-- =========================================================================
-- Menu deroulant (selecteur) -- MAISON depuis le 2026-09-19, et c'est une EXCEPTION ASSUMEE.
-- =========================================================================
-- La regle du kit (skill, piege n°9) est d'HERITER le template natif plutot que d'en peindre un
-- faux. UIDropDownMenuTemplate est le seul widget natif qu'on NE DOIT PAS heriter : il teint des
-- variables globales partagees (detail sous ce bandeau). NE PAS « corriger » vers le template.
-- Contrat (inchange pour la dizaine d'appelants) : `dd:SetValue(v)` (libelle) · `dd.value` ·
-- `dd:SetText(t)` · `items` = liste `{ {value=…, text=…}, … }` ou FONCTION qui la rend
-- (re-evaluee a chaque ouverture : libelles localises/dynamiques) · `opts.onSelect(v)` ·
-- `opts.label` (prefixe colle devant le libelle, ex. « Qualite : ») · `:SetPointVisual(...)`.
-- MENU DEROULANT MAISON, SANS UIDropDownMenu. L'ancien systeme de Blizzard garde son etat dans des
-- variables GLOBALES partagees (UIDROPDOWNMENU_MENU_LEVEL & co) : les ecrire depuis un addon -- ce que
-- font UIDropDownMenu_Initialize / _SetSelectedValue / _SetText -- les teint, et toute l'interface de
-- Blizzard qui les relit ensuite tourne contaminee. Resultat mesure le 2026-09-19 sur Forever
-- (/console taintLog 2) : « tainted by CraftingOrderClassic while reading global
-- UIDROPDOWNMENU_MENU_LEVEL », puis des centaines de deplacements de barres d'action refuses au
-- combat suivant -- sans une ligne de COC dans la pile. C'etait la VRAIE cause des blocages de
-- l'apres-midi, attribues a tort a la greffe dans la fenetre de metier.
-- Remplace par un selecteur a nous + le menu maison Skin.MakeFlyout (deja utilise par le menu
-- minimap) : nos propres cadres, aucune globale de Blizzard touchee. MEME CONTRAT pour les appelants
-- (SetValue, .value, SetPointVisual, opts.label / opts.onSelect) + dd:SetText pour ceux qui
-- appelaient UIDropDownMenu_SetText en direct.
-- La liste s'elargit a l'entree la plus longue (UIDropDownMenu le faisait ; sans ca un long nom de
-- canal ou de stat debordait de la boite), et passe au-dessus de la fenetre qui porte le menu : strate
-- FULLSCREEN_DIALOG, niveau pris sur le menu lui-meme.
local function openDropdownList(dd)
    local fly = dd._fly
    if not fly then
        fly = Skin.MakeFlyout(nil, dd:GetWidth(), { rowStep = 18, rowH = 18, strata = "FULLSCREEN_DIALOG" })
        dd._fly = fly
    end
    local items, widest = dd._list(), 0
    for idx, it in ipairs(items) do
        local r = fly:Row(idx)
        r:SetText(it.text or "")
        r:SetSelected(it.value == dd.value)
        r:SetScript("OnClick", function()
            fly:Hide()
            dd:SetValue(it.value)
            if dd._onSelect then dd._onSelect(it.value) end
        end)
        widest = math.max(widest, r.text:GetStringWidth() or 0)
    end
    local w = math.max(dd:GetWidth(), widest + 24)            -- 6 px de retrait du texte + marge
    fly:SetWidth(w)
    for idx = 1, #items do fly.rows[idx]:SetWidth(w - 4) end   -- 2 px de marge de chaque cote
    fly:SetCount(#items)
    local lv = dd:GetFrameLevel() + 20
    fly.closer:SetFrameLevel(lv); fly:SetFrameLevel(lv + 1)
    fly:ToggleAt("TOPLEFT", dd, "BOTTOMLEFT", 0, -2)
end

function Skin.MakeDropdown(name, parent, w, items, opts)
    opts = opts or {}
    local dd = CreateFrame("Button", name, parent, "BackdropTemplate")
    dd:SetSize(w + 16, 22)
    Skin.SkinWell(dd)
    local fs = dd:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("LEFT", 8, 0); fs:SetPoint("RIGHT", -20, 0)
    fs:SetJustifyH("LEFT"); fs:SetWordWrap(false)
    local arrow = dd:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(16, 16); arrow:SetPoint("RIGHT", -3, 0)
    arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    dd._list = function() return (type(items) == "function") and items() or items end
    dd._onSelect = opts.onSelect
    -- Valeur absente de la liste (liste pas encore peuplee : rerolls pas encore scannes au 1er affichage)
    -- -> on affiche la valeur brute plutot qu'un libelle VIDE, qui ferait croire a un selecteur casse.
    local function textFor(v)
        for _, it in ipairs(dd._list()) do if it.value == v then return it.text or "" end end
        return (type(v) == "string") and v or ""
    end
    function dd:SetText(t) fs:SetText(t or "") end
    function dd:SetValue(v)
        self.value = v
        self:SetText((opts.label or "") .. textFor(v))
    end
    -- L'art de UIDropDownMenuTemplate avait une marge transparente a compenser ; notre selecteur n'en
    -- a pas. Garde pour le contrat : les appelants ancrent le bord visible, c'est maintenant le cadre.
    function dd:SetPointVisual(point, rel, relPoint, x, y)
        self:SetPoint(point, rel, relPoint, x or 0, y or 0)
    end
    dd:SetScript("OnClick", openDropdownList)
    dd:SetScript("OnHide", function(self) if self._fly then self._fly:Hide() end end)
    return dd
end
