-- CraftingOrderClassic_ProfWindow_Route_Writs.lua — les Craftsman's Writ dans le Plan de route
-- (demande du user, 2026-11-13 : « tout comme Profit, il faudrait que dans Route on voie si un des
-- plans a un writ, et une option pour privilégier les writs car ça se revend vite à l'HV ») :
--   · la MARQUE d'une étape dont l'objet est demandé par un writ, la même que dans la vue Profit ;
--   · la case « Privilégier les writs », qui biaise le choix de la route (COC.Route, preferWrit).
-- Spec : docs/specs/writs-aca.md (D12) et docs/specs/route-cout-net.md (décision 13).
--
-- Fichier À PART : _ProfWindow_Route.lua frôle les 500 lignes. Il n'appelle ici que des points
-- d'entrée sous garde nil : sans ce fichier, la route reste celle d'avant, sans marque ni case.
-- Chargé après _ProfWindow_Route_Tip.lua (.toc) ; tout s'appelle au remplissage ou au survol.

local COC  = CraftingOrderClassic
local PW   = COC.ProfWindow
local Skin = COC.UI.Skin
local L    = COC.L

-- Repli si le client ne rend pas l'icône du writ lui-même (lue par son identifiant d'abord).
local WRIT_ICON = "Interface\\Icons\\INV_Scroll_03"

-- La case, à droite de « Suivi à l'écran », sur sa ligne : le pied garde sa hauteur (ROUTE_FOOT).
-- Décochée par défaut (db.routeWrits nil) : elle change des routes que le joueur a déjà suivies.
function PW:_BuildRouteWritCheck(f, inset)
    local chk = Skin.MakeCheckButton(inset, L["Privilégier les writs"], 18)
    if f.trackChk and f.trackChk.text then chk:SetPoint("LEFT", f.trackChk.text, "RIGHT", 12, 0)
    else chk:SetPoint("BOTTOMLEFT", 8, 24) end
    chk:SetScript("OnClick", function(cb)
        if COC.db then COC.db.routeWrits = cb:GetChecked() and true or nil end
        PW:_FillRoute()
    end)
    chk:SetScript("OnEnter", function(b)
        local tol = math.floor(((COC.Route and COC.Route.WRIT_TOL) or 0) * 100 + 0.5)
        GameTooltip:SetOwner(b, "ANCHOR_TOP")
        GameTooltip:SetText(L["Privilégier les writs"], 1, 1, 1)
        GameTooltip:AddLine(string.format(L["Cochée : une recette dont l'objet est demandé par un writ d'artisan passe devant, si son point coûte au plus %d %% de plus. Ces objets se revendent vite à l'HV."], tol),
            0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    chk:SetScript("OnLeave", GameTooltip_Hide)
    f.chkWrits = chk
end

-- État de la case au remplissage (les deux contenants : fenêtre flottante et languette).
function PW:_SyncRouteWritCheck(f)
    if f.chkWrits then f.chkWrits:SetChecked(COC.db and COC.db.routeWrits == true or false) end
end

-- La marque d'une étape : l'icône du writ entre le nom et le montant, pleine si je PORTE ce writ,
-- éteinte sinon (ce sont les autres porteurs qui cherchent l'objet). `ItemMark` ne lit que les writs
-- de CET objet : la route se repeint chaque seconde, `WantedItems()` y relirait les 150 à chaque fois.
-- Une ligne est RECYCLÉE : sans writ, la marque disparaît et le nom reprend sa place. À appeler AVANT
-- fitSegName, qui mesure la place du nom. La ligne écrit ses propres lignes de writ dans son
-- infobulle (_Route_Tip) : `cocWritTip` fait taire l'accroche d'infobulle d'objet (_Writs_Tooltip).
function PW:_RouteWritMark(row, s)
    local W = COC.Writs
    local m = (W and not s.gap and s.prod) and W:ItemMark(s.prod) or nil
    row.writ, row.cocWritTip = m, true
    if m and not row.wr then
        row.wr = row:CreateTexture(nil, "ARTWORK"); row.wr:SetSize(12, 12)
        row.wr:SetPoint("RIGHT", row.cost, "LEFT", -3, 0)
    end
    if row.wr then
        if m then
            local gi = COC.Api.GetItemIcon
            row.wr:SetTexture((gi and gi(m.entry.writ)) or WRIT_ICON)
            row.wr:SetDesaturated(not m.held)
        end
        row.wr:SetShown(m ~= nil)
    end
    if m then row.name:SetPoint("RIGHT", row.wr, "LEFT", -4, 0)
    else row.name:SetPoint("RIGHT", row.cost, "LEFT", -6, 0) end
end

-- Dans l'infobulle d'une étape : les lignes de writ de la vue Profit (une seule rédaction, exposée
-- par _ProfWindow_DockProfit), puis ce que la case a coûté quand c'est elle qui a choisi l'étape.
-- Sans cet aveu, une route qui ne prend plus la recette la moins chère passe pour un bug (vécu le
-- 2026-11-10 avec la décision 12).
function PW:_RouteWritTip(row)
    local s = row.seg
    if row.writ and PW._AddWritLines then PW._AddWritLines(row.writ) end
    if s and (s.writExtra or 0) > 0.5 then
        GameTooltip:AddLine(string.format(L["Choisie pour le writ : ~%s de plus que la recette la moins chère."],
            COC.Api.Coin(math.floor(s.writExtra + 0.5))), 1, 0.82, 0, true)
    end
end
