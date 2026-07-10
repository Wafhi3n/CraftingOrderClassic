-- CraftingOrderClassic_UI_Artisans_Groups.lua — fusion « une ligne par JOUEUR » (rerolls).
--
-- Couche d'AGRÉGATION D'AFFICHAGE au-dessus du roster : les persos d'un même joueur (liens ALT
-- VÉRIFIÉS par réciprocité — Dir:GroupLeader/PlayerChars, jamais une claim unilatérale) sont pliés
-- en une ligne, perso principal en vitrine. Le ROUTAGE ne change pas : la cible postée reste un
-- PERSO (résolue par _ResolvePostChar via Skin.KnowsProf STRICT sur ses données directes), et
-- Skin.KnowsProf/KnowsProfOrSeen restent intacts (règle verrouillée par le SelfTest).
-- Partage le namespace UI ; chargé APRÈS CraftingOrderClassic_UI_Artisans.lua (.toc) qui exporte
-- UI._ProfsList / UI._SrcTag.

local COC  = CraftingOrderClassic
local UI   = COC.UI
local Skin = UI.Skin
local L    = COC.L

-- ------------------------------------------------------------------
-- Regroupement
-- ------------------------------------------------------------------
-- Plie le roster en groupes par joueur vérifié. `memberOk(r)` = prédicat de filtre par ENTRÉE
-- (source + métier, fourni par l'appelant) : le groupe passe si N'IMPORTE QUEL perso passe (union).
-- Champs d'un groupe : leader, lead (membre vitrine), members (triés vitrine→en ligne→nom),
-- onlineChar (préférence au leader), anyPartner, repMax.
function UI:_ArtisanGroups(memberOk)
    local D = COC.Directory
    if not (D and D.roster) then return {} end
    local groups, order = {}, {}
    for name, r in pairs(D.roster) do
      if not D._SameFaction or D:_SameFaction(r) then   -- confinement faction (Classic : pas d'échange cross-faction)
        local leader = (D.GroupLeader and D:GroupLeader(name)) or name
        local g = groups[leader]
        if not g then
            g = { leader = leader, members = {}, repMax = 0 }
            groups[leader] = g; order[#order + 1] = g
        end
        local online = (D.online and D.online[name]) and true or false
        local m = { name = name, r = r, online = online }
        g.members[#g.members + 1] = m
        if name == leader then g.lead = m end
        if memberOk == nil or memberOk(r) then g.ok = true end
        if r.isPartner then g.anyPartner = true end
        if D.LFWOf and D:LFWOf(name) then g.anyLFW = true end   -- un perso du set cherche du travail (LFW)
        if (r.rep or 0) > g.repMax then g.repMax = r.rep end
        if online and (not g.onlineChar or name == leader) then g.onlineChar = name end
      end
    end
    local list = {}
    for _, g in ipairs(order) do
        if g.ok then
            if not g.lead then g.lead = g.members[1]; g.leader = g.lead.name end   -- garde-fou
            table.sort(g.members, function(a, b)
                if (a.name == g.leader) ~= (b.name == g.leader) then return a.name == g.leader end
                if a.online ~= b.online then return a.online end
                return a.name < b.name
            end)
            list[#list + 1] = g
        end
    end
    return list
end

-- Union des métiers du groupe : une icône par métier, portée par le perso le MIEUX renseigné
-- (SK direct prioritaire) ; item.who/item.r → tooltip « Alchimie 300 — Luletta » + CD du PORTEUR.
function UI:_GroupProfs(g)
    if #g.members == 1 then return UI._ProfsList(g.lead.r) end
    local by, out = {}, {}
    for _, m in ipairs(g.members) do
        for _, it in ipairs(UI._ProfsList(m.r)) do
            local cur = by[it.key]
            if not cur or (it.sv and not cur.sv) then
                it.who, it.r = m.name, m.r
                by[it.key] = it
            end
        end
    end
    for _, it in pairs(by) do out[#out + 1] = it end
    table.sort(out, function(a, b) return Skin.ProfLabel(a.key) < Skin.ProfLabel(b.key) end)
    return out
end

-- ------------------------------------------------------------------
-- Rendu (onglet Artisans)
-- ------------------------------------------------------------------
-- Ligne FUSIONNÉE (≥ 2 persos) : vitrine = main, « +N », présence du joueur (« En ligne via X »),
-- rep max du set, icônes métier par porteur, tooltip de ligne listant les rerolls.
function UI:_FillArtGroupRow(row, g)
    local lead = g.lead
    row.dot:SetOnline(g.onlineChar ~= nil)
    local pTag = g.anyPartner and ("|cFFFFD100" .. L["[Partenaire]"] .. "|r ") or ""
    local lfwTag = g.anyLFW and ("|cFF4CDB6E" .. L["[Dispo]"] .. "|r ") or ""   -- cherche du travail
    row.name:SetText(lfwTag .. pTag .. "|cFFFFFFFF" .. g.leader .. "|r |cFF888888+" .. (#g.members - 1) .. "|r")
    local sub
    if g.onlineChar and g.onlineChar ~= g.leader then
        sub = string.format(L["En ligne via %s"], g.onlineChar)
    else
        sub = (g.onlineChar and L["En ligne"] or L["Hors ligne"])
            .. " · " .. (lead.r.level and (L["niv "] .. lead.r.level) or L["niv ?"])
    end
    if g.repMax > 0 then sub = sub .. " · " .. string.format(L["%d livrés"], g.repMax) end
    row.sub:SetText("|cFF888888" .. sub .. "|r")
    UI:_SetArtProfIcons(row, UI:_GroupProfs(g), lead.r)
    row.src:SetText("|cFF888888" .. (UI._SrcTag[lead.r.source or "recent"] or "") .. "|r")
    self:_ArtRowButtons(row, { name = g.onlineChar or g.leader, online = g.onlineChar ~= nil, r = lead.r }, false, g.anyPartner)
    row:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(g.leader, 1, 1, 1)
        for _, m in ipairs(g.members) do
            if m.name ~= g.leader then
                GameTooltip:AddLine(string.format(L["reroll : %s (%s)"], m.name,
                    m.online and L["En ligne"] or L["Hors ligne"]), 0.7, 0.7, 0.7)
            end
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:Show()
end

-- ------------------------------------------------------------------
-- Rendu (onglet Commande — liste de ciblage) + résolution de cible
-- ------------------------------------------------------------------
-- Perso du groupe à CIBLER pour un métier : données directes STRICTES (Skin.KnowsProf), perso en
-- ligne de préférence. La valeur réseau (recipient) reste donc un PERSO précis, comme avant.
function UI:_ResolvePostChar(g, prof)
    if not prof then return g.onlineChar or g.leader end
    local offline
    for _, m in ipairs(g.members) do
        if Skin.KnowsProf(m.r, prof) then
            if m.online then return m.name end
            offline = offline or m.name
        end
    end
    return offline or g.onlineChar or g.leader
end

-- Ligne de la liste de ciblage : vitrine + « +N », skill du perso RÉSOLU pour le métier choisi,
-- métiers (RK) en union ; le clic cible le perso résolu (postTarget = "@Perso").
function UI:_FillPostArtGroupRow(row, g, prof)
    local D = COC.Directory
    local target = self:_ResolvePostChar(g, prof)
    local tr = (D and D.roster and D.roster[target]) or g.lead.r
    local sk = prof and tr.skill and tr.skill[prof]
    local skTxt = sk and ("|cFF888888" .. (sk[1] or "?") .. "/" .. (sk[2] or "?") .. "|r  ") or ""
    local profs2, seen2 = {}, {}
    for _, m in ipairs(g.members) do
        for p2 in pairs(m.r.recipes or {}) do
            if not seen2[p2] then seen2[p2] = true; profs2[#profs2 + 1] = Skin.ProfLabel(p2) end
        end
    end
    local plus = #g.members > 1 and (" |cFF888888+" .. (#g.members - 1) .. "|r") or ""
    row.dot:SetOnline(g.onlineChar ~= nil)
    row.name:SetText("|cFFFFFFFF" .. g.leader .. "|r" .. plus .. "  " .. skTxt
        .. "|cFF888888" .. table.concat(profs2, " · ") .. "|r")
    row.src:SetText("|cFF888888" .. ((g.lead.r.source or "recent"):upper()) .. "|r")
    row.artEntry = { name = target, r = tr, online = (D and D.online and D.online[target]) and true or false }
    local selected = false   -- le groupe est « sélectionné » si la cible courante est UN de ses persos
    for _, m in ipairs(g.members) do if UI.postTarget == "@" .. m.name then selected = true end end
    row.selTex:SetShown(selected)
    row:SetScript("OnClick", function()
        UI.postTarget = "@" .. target
        -- Sollicite le registre FRAIS du perso ciblé s'il est en ligne (RK+SK à jour) — throttlé 60 s/nom.
        if D and D.online and D.online[target] and D.DiscoverPlayer then D:DiscoverPlayer(target) end
        UI:RefreshPostArtisans(); UI:RefreshPostPlans()
    end)
    row:Show()
end

-- ------------------------------------------------------------------
-- Actions « de set » (le clic-droit joueur agit sur TOUT le set vérifié)
-- ------------------------------------------------------------------
-- Bascule PARTENAIRE pour tous les persos vérifiés du joueur (un seul état de groupe : cible =
-- inverse de « au moins un partenaire »). Singleton/inconnu → bascule simple existante.
function UI:_TogglePartnerSet(name)
    local D = COC.Directory
    local order = D and D.PlayerChars and select(2, D:PlayerChars(name))
    if not order or #order <= 1 then return UI:_TogglePartner(name) end
    local any = false
    for _, n in ipairs(order) do
        local r = D.roster and D.roster[n]
        if r and r.isPartner then any = true end
    end
    for _, n in ipairs(order) do
        local r = D.roster and D.roster[n]
        if r then r.isPartner = not any end
    end
    UI:RefreshArtisans()
    print("|cFF33DD88Crafting Order|r " .. (not any
        and string.format(L["|cFFFFFFFF%s|r marqué comme partenaire — priorité sur les alertes de don."], name)
        or string.format(L["|cFFFFFFFF%s|r n'est plus marqué comme partenaire."], name)))
end

-- Mute tous les persos vérifiés du joueur (muter le main sans les rerolls serait contournable).
function UI:_MuteSet(name)
    local D, M = COC.Directory, COC.Moderation
    if not M then return end
    local order = D and D.PlayerChars and select(2, D:PlayerChars(name))
    if not order or #order <= 1 then return M:Mute(name) end
    for _, n in ipairs(order) do M:Mute(n) end
end
