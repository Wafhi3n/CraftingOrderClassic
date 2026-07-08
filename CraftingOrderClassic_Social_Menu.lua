-- CraftingOrderClassic_Social_Menu.lua — entrées « Crafting Order » du menu contextuel joueur.
-- Utilise la NOUVELLE API Menu (Menu.ModifyMenu / rootDescription), sans taint. Remplace l'ancienne
-- injection UnitPopupMenus/UnitPopupButtons, MORTE depuis le refactor menu de Classic Era
-- (table UnitPopupButtons absente du client → l'ancien code était un no-op silencieux ; cf. mémoire
-- coc-classic-menu-api). Les entrées n'apparaissent QUE pour un PORTEUR de l'addon présent dans le
-- roster (amis, guildies EN LIGNE, joueurs croisés) — PAS pour un simple non-porteur vu crafter au
-- scan (nonAddon) : les actions supposent l'addon en face. Un guildie HORS-LIGNE n'ouvre aucun menu
-- (garde Blizzard) → il est couvert par le panneau de guilde (_Social_Roster.lua).

local COC    = CraftingOrderClassic
local Social = COC.Social

-- Tags de menu-unité à enrichir. Le root d'un UnitPopup est taggé « MENU_UNIT_<WHICH> ».
-- FRIEND/_OFFLINE = liste d'amis (on/off) ET clic-droit d'un membre de guilde EN LIGNE ;
-- PLAYER/TARGET/PARTY/RAID_PLAYER = joueurs croisés (monde, cadre d'unité, groupe).
local MENU_TAGS = {
    "MENU_UNIT_FRIEND", "MENU_UNIT_FRIEND_OFFLINE",
    "MENU_UNIT_BN_FRIEND",                          -- ami Battle.net EN LIGNE (perso résolu ci-dessous)
    "MENU_UNIT_PLAYER", "MENU_UNIT_TARGET",
    "MENU_UNIT_PARTY",  "MENU_UNIT_RAID_PLAYER",
}

-- Ami Battle.net : le menu ne passe que le nom de COMPTE (contextData.name = « Volkdieb »), jamais le
-- nom du PERSONNAGE joué → notre roster (indexé par perso) ne le trouve pas et la section n'apparaît
-- pas. On résout le perso WoW via bnetIDAccount (Social:BNetCharFromAccount gate client + version).
local function bnetCharacterName(contextData)
    local id = contextData and contextData.bnetIDAccount
    if not (id and C_BattleNet and C_BattleNet.GetAccountInfoByID) then return nil end
    return Social:BNetCharFromAccount(C_BattleNet.GetAccountInfoByID(id))
end

local function targetName(contextData)
    if not contextData then return nil end
    -- BNet d'abord : contextData.name est le compte, pas le perso.
    if contextData.bnetIDAccount then return bnetCharacterName(contextData) end
    if contextData.name and contextData.name ~= "" then return contextData.name end
    if contextData.unit and UnitName then return UnitName(contextData.unit) end
    return nil
end

-- Callback Menu.ModifyMenu : append de la section (owner, rootDescription, contextData).
local function addEntries(_, rootDescription, contextData)
    if not (rootDescription and rootDescription.CreateButton) then return end
    local name = targetName(contextData)
    if not (name and name ~= "") then return end
    if contextData.unit and UnitIsUnit and UnitIsUnit(contextData.unit, "player") then return end  -- pas soi-même
    -- Découverte proactive MODÉRÉE (cf. Social:MaybeDiscover — ne ping que si métiers manquants,
    -- anti-rafale + throttle 60 s/nom) : rafraîchit skill/recipes pour que le PROCHAIN clic-droit ait
    -- ses métiers (SK/RK arrivent en whisper, async). Sans ça, un ami capté tard n'affichait la section
    -- qu'« au hasard » d'un message reçu (cf. clic-droit répété).
    Social:MaybeDiscover(name)
    -- Uniquement un porteur d'addon découvert (roster). Exclut de fait les non-porteurs et l'ennemi
    -- (jamais découvert : DiscoverPlayer ne ping que les alliés coopérables).
    local D = COC.Directory
    local r = D and D.roster and D.roster[name]
    if not r then return end
    -- Non-porteur (seulement VU crafter via le scan, aucune donnée réseau) : « Passer commande »,
    -- « Partenaire », « Muter »… supposent l'addon EN FACE → inutiles. On n'ajoute rien (menu propre).
    if r.nonAddon and not (r.skill or r.recipes) then return end

    local L = COC.L
    rootDescription:CreateDivider()
    rootDescription:CreateTitle("Crafting Order")
    -- Une entrée « Commander <métier> » par métier PRIMAIRE craftable connu (pré-cible le joueur ET le
    -- métier) ; repli sur l'entrée générique si on ne connaît aucun métier craftable de sa part.
    local orderable = Social.OrderableProfs and Social:OrderableProfs(name) or {}
    local Skin = COC.UI and COC.UI.Skin
    if #orderable > 0 then
        for _, prof in ipairs(orderable) do
            local lbl = (Skin and Skin.ProfLabel(prof)) or prof
            rootDescription:CreateButton(string.format(L["Passer commande à %s (%s)"], name, lbl), function()
                if COC.UI and COC.UI.OpenPostForArtisan then COC.UI:OpenPostForArtisan(name, prof) end
            end)
        end
    else
        rootDescription:CreateButton(string.format(L["Passer commande à %s"], name), function()
            if COC.UI and COC.UI.OpenPostForArtisan then COC.UI:OpenPostForArtisan(name) end
        end)
    end
    rootDescription:CreateButton(L["Ajouter aux artisans"], function()
        if COC.UI and COC.UI._AddArtisan then COC.UI:_AddArtisan(name) end
    end)
    -- Actions « de set » : sur un joueur aux rerolls VÉRIFIÉS, partenaire/mute s'appliquent à tous
    -- ses persos (muter le main sans les rerolls serait contournable). Repli = action mono-perso.
    rootDescription:CreateButton(L["Partenaire (basculer)"], function()
        if COC.UI and COC.UI._TogglePartnerSet then COC.UI:_TogglePartnerSet(name)
        elseif COC.UI and COC.UI._TogglePartner then COC.UI:_TogglePartner(name) end
    end)
    rootDescription:CreateButton(L["Muter"], function()
        if COC.UI and COC.UI._MuteSet then COC.UI:_MuteSet(name)
        elseif COC.Moderation then COC.Moderation:Mute(name) end
    end)
end

function Social:InstallMenus()
    if not (Menu and Menu.ModifyMenu) then return end   -- client pré-refactor (sans nouvelle API) : rien
    for _, tag in ipairs(MENU_TAGS) do
        Menu.ModifyMenu(tag, addEntries)
    end
    self._menuHooked = true
end
