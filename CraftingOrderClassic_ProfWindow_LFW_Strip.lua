-- CraftingOrderClassic_ProfWindow_LFW_Strip.lua — la bande « Chercher du travail » en PIED de colonne.
--
-- POURQUOI UNE BANDE ET PAS UNE 5e LANGUETTE. Le portage Forever a tue l'entree LFW : le bouton
-- d'en-tete et son engrenage vivaient dans la vue custom, que la colonne greffee n'affiche plus.
-- La reponse evidente etait une languette de plus. Elle a ete mesuree le 2026-09-26 et elle coute
-- cher : ~41 px de CADRE par languette (le texte, lui, ne pese que 1,9 px/caractere), et la rangee
-- pilote la largeur de la colonne, qui elargit la FENETRE NATIVE d'autant. ~35 px de fenetre pour
-- un interrupteur. Ici on paie 20 px de HAUTEUR sur une liste qui en fait 301, et rien ne bouge.
-- La bande est visible dans TOUTES les vues -- or c'est un ETAT qu'on oublie d'eteindre, et tout le
-- mecanisme de TTL anti-leurre existe precisement pour ca. Sa hauteur est reservee
-- INCONDITIONNELLEMENT par _ApplyMode : voir PW.TUNE.lfwStrip.
--
-- UN VRAI BOUTON, ET SON LIBELLE DIT L'ACTION (decision du user, 2026-10-03). La bande etait une
-- ligne plate cliquable dont le texte dore alternait entre l'invitation (« Chercher du travail ») et
-- l'etat (« Dispo — Forge ») : a l'ecran, rien ne disait qu'on pouvait cliquer, et allumee elle ne
-- disait pas qu'un clic l'eteignait. Desormais :
--   eteinte : [ Chercher du travail ]                 [ Offre ]
--   allumee : (o) Dispo — Enchantement     [ Arreter ] [ Offre ]
-- L'etat s'ecrit en TEXTE, a part ; un bouton ne porte qu'un verbe. Le vide de la bande ne bascule
-- plus rien : deux surfaces cliquables pour le meme geste, c'etait une de trop.
-- Fichier a part : l'hote (_ProfWindow_LFW.lua) touchait les 500 lignes.

local COC  = CraftingOrderClassic
local Skin = COC.UI.Skin
local L    = COC.L
local PW   = COC.ProfWindow

local BTN_H   = 16   -- <= 16 : police small du kit, la meme que « Offre »
local BTN_MIN = 56   -- largeur de « Offre » : « Arreter » et lui font une paire

local function profLabel(key) return (Skin.ProfLabel and Skin.ProfLabel(key)) or key end

function PW:_BuildLFWStrip(f)
    if self.lfwStrip then return end
    local s = CreateFrame("Frame", nil, f)
    s:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",   PW.PAD, 4)
    s:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PW.PAD, 4)
    s:SetHeight(PW.TUNE.lfwStrip)
    local fs = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetJustifyH("LEFT"); fs:SetWordWrap(false); Skin.ApplyShadow(fs)
    s.text = fs
    s:Hide()
    self.lfwStrip = s
    self:_BuildLFWToggleBtn(s)
    self:_BuildLFWOfferBtn(s)
end

-- Les boutons sont ENFANTS de la bande, pas freres. Le bouton d'offre etait cree sur le cadre de la
-- colonne et seulement ANCRE sur la bande : deux freres au meme niveau, donc un ordre de dessin qui
-- ne se decide pas -- le user l'a vu « en arriere » le 2026-09-26. Enfant, il passe devant par
-- construction, il se montre et se cache avec elle, et le niveau explicite ne laisse plus la
-- question ouverte.
local function stripButton(strip, text)
    local b = Skin.MakeGoldButton(strip, BTN_MIN, BTN_H, text)
    b:SetFrameLevel((strip:GetFrameLevel() or 0) + 2)
    b:SetScript("OnLeave", GameTooltip_Hide)
    return b
end

function PW:_BuildLFWToggleBtn(strip)
    if self.lfwStripBtn then return end
    local b = stripButton(strip, L["Chercher du travail"])
    b:SetScript("OnClick", function() PW:_ToggleLFW() end)
    b:SetScript("OnEnter", function(btn)
        local D = COC.Directory
        local on = D and D.MyLFW and D:MyLFW() == PW.profKey
        GameTooltip:SetOwner(btn, "ANCHOR_TOPLEFT")
        GameTooltip:SetText(on and L["Tu cherches du travail — clic pour arrêter."]
            or L["Signale au royaume que tu cherches du travail dans ce métier."], 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    self.lfwStripBtn = b
end

-- C'ÉTAIT UN ENGRENAGE (`Interface\WorldMap\Gear_64`, 18 px) ET LE USER NE L'A PAS RECONNU : à
-- l'écran, le 2026-09-26, deux petits carrés sans forme lisible. Un MOT est lisible à toute taille
-- et ne peut pas manquer ; et ça rejoint la leçon du 2026-09-19, payée sur capture dans cette
-- colonne même : une icône de 16 px posée dans une bande se lit comme un bouton secondaire oublié
-- là, quand un libellé dit ce qu'il fait. Pas de glyphe ⚙ non plus : la police du jeu les rend en
-- tofu.
-- ⚠️ MÉTHODE, apprise en se trompant ce jour-là : pour savoir si une texture existe, l'oracle est
-- `Documentation/wow-ui-textures-classic/`, PAS l'export Lua/XML, qui ne contient aucun asset et
-- donne des faux négatifs (`MoneyFrame\UI-GoldIcon` n'y figure pas, et elle s'affiche très bien).
function PW:_BuildLFWOfferBtn(strip)
    if self.lfwCfgBtn then return end
    local b = stripButton(strip, L["Offre"])
    b:SetPoint("RIGHT", strip, "RIGHT", -2, 0)
    b:SetScript("OnClick", function() PW:ToggleLFWConfig() end)
    b:SetScript("OnEnter", function(s)
        GameTooltip:SetOwner(s, "ANCHOR_TOPLEFT")
        GameTooltip:SetText(L["Configurer l'offre : composants fournis, commission…"], 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    b:Hide()
    self.lfwCfgBtn = b
end

-- Etat de la bande : visible sur un metier A MOI en colonne. Le bouton d'offre suit la meme
-- portee -- regler une offre pour un metier qu'on n'a pas ouvert n'aurait pas de sens.
function PW:_SyncLFWStrip()
    local s = self.lfwStrip; if not s then return end
    local D = COC.Directory
    local show = self.profKey and not self.rerollKey and (self._compact or self.docked)
                 and D and D.SetLFW and true or false
    s:SetShown(show)
    if show then self:_LayoutLFWStrip(D.MyLFW and D:MyLFW() == self.profKey) end
    if self._SyncLFWConfig then self:_SyncLFWConfig(show) end
end

-- Eteinte : le bouton a gauche, seul. Allumee : l'etat a gauche, « Arreter » colle a « Offre ». Le
-- texte d'etat s'arrete AVANT les boutons : « Dispo — Travail du cuir » est long, et un libelle
-- sans bord droit passerait dessous au lieu d'etre tronque.
function PW:_LayoutLFWStrip(on)
    local s, b, cfg = self.lfwStrip, self.lfwStripBtn, self.lfwCfgBtn
    b:SetText(on and L["Arrêter"] or L["Chercher du travail"])
    b:SetWidth(math.max(BTN_MIN, math.ceil(b.text:GetStringWidth()) + 24))
    b:ClearAllPoints(); s.text:ClearAllPoints()
    if on then
        b:SetPoint("RIGHT", cfg, "LEFT", -4, 0)
        s.text:SetPoint("LEFT", s, "LEFT", 2, 0)
        s.text:SetPoint("RIGHT", b, "LEFT", -4, 0)
        s.text:SetText("|T" .. Skin.tex.dotGreen .. ":12:12|t |cFF4CDB6E"
            .. string.format(L["Dispo — %s"], profLabel(self.profKey)) .. "|r")
    else
        b:SetPoint("LEFT", s, "LEFT", 0, 0)
        s.text:SetText("")
    end
end
