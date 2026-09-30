-- CraftingOrderClassic_UI_Artisans_Text.lua — onglet « Artisans » : ce qu'une ligne de l'annuaire DIT.
-- Les textes d'une ligne (couleur du nom, sous-ligne, étiquette de source) et le compte par source,
-- fabriqués sans toucher à un cadre : l'interface ne fait que les peindre, et
-- tests/test_artisans_text.lua les vérifie sans le jeu. Chargé AVANT _UI_Artisans.lua (.toc).
--
-- Pourquoi (refonte du 2026-09-30, docs/specs/refonte-artisans.md) : sur une capture du user, dix
-- lignes sur douze disaient « Offline · lvl ? » et « MET ». Un texte répété sur toutes les lignes
-- n'apprend rien, et il noie celui qui compte. Règle : une ligne ne dit que ce que sa pastille et la
-- bande SOURCE choisie ne disent pas déjà.

local COC = CraftingOrderClassic
local UI  = COC.UI
local L   = COC.L

local SRC_TAG = { guild = L["GUILDE"], friend = L["AMIS"], added = L["AJOUTÉ"], recent = L["CROISÉ"], confed = L["CONFÉDÉRÉ"], circle = L["CERCLE"] }

-- Libellés des 3 états de présence (cf. Dir:PresenceOf). « sans addon » n'est pas cosmétique : il dit
-- pourquoi ses métiers/niveaux peuvent être périmés et pourquoi une commande ne lui parviendra pas.
local PRES_LABEL = { online = L["En ligne"], game = L["En ligne · sans addon"], offline = L["Hors ligne"] }

UI._SrcTag    = SRC_TAG      -- partagés avec _UI_Artisans.lua et la couche de fusion (_Groups.lua)
UI._PresLabel = PRES_LABEL

-- Couleur du nom : blanc quand on peut lui parler (avec ou sans l'addon), gris hors ligne. Le gris est
-- celui d'un ami hors ligne dans la liste d'Amis de Blizzard (FRIENDS_GRAY_COLOR : 0.486, 0.518, 0.541).
function UI._ArtNameHex(pres)
    return pres == "offline" and "|cFF7C848A" or "|cFFFFFFFF"
end

-- Sous-ligne d'un artisan. La pastille dit déjà « en ligne » ou « hors ligne » : on ne le répète que
-- s'il n'y a rien d'autre à écrire (niveau inconnu). « sans addon » reste écrit, lui explique des
-- métiers périmés. `via` = le reroll par lequel le joueur est en ligne (ligne fusionnée).
function UI._ArtSubLine(pres, level, rep, via)
    local parts = {}
    if via then
        parts[1] = string.format(L["En ligne via %s"], via)
    else
        if pres == "game" or not level then parts[1] = PRES_LABEL[pres] or PRES_LABEL.offline end
        if level then parts[#parts + 1] = L["niv "] .. level end
    end
    if rep and rep > 0 then parts[#parts + 1] = string.format(L["%d livrés"], rep) end
    return table.concat(parts, " · ")
end

-- Étiquette de droite. RELAIS et VU sont des états de la fiche : toujours dits. La source, elle, ne se
-- dit que si elle apprend quelque chose : rien pour un joueur croisé (le cas général), rien quand une
-- bande SOURCE est choisie (toutes les lignes porteraient la même), et le NOM de la communauté plutôt
-- que « CERCLE ». `src` = la bande choisie ; `circleNames` = { [id] = nom } des cercles marqués.
function UI._ArtSrcTag(r, src, circleNames, relayed, nonAddon)
    if relayed then return L["RELAIS"] end
    if nonAddon then return L["VU"] end
    if src and src ~= "all" then return "" end
    local s = r.source or "recent"
    if s == "recent" then return "" end
    if s == "circle" then
        return (circleNames and r.circle and circleNames[tostring(r.circle)]) or SRC_TAG.circle
    end
    return SRC_TAG[s] or ""
end

-- Combien d'artisans par source : « all », chaque source, et « circle:<id> » par cercle. Même
-- confinement de camp que la liste (Dir:_SameFaction), pour que les bandes et la liste s'accordent.
function UI._ArtCounts(D)
    local counts = { all = 0, guild = 0, friend = 0, added = 0, recent = 0, confed = 0, circle = 0 }
    for _, r in pairs((D and D.roster) or {}) do
        if not (D and D._SameFaction) or D:_SameFaction(r) then
            local s = r.source or "recent"
            counts[s] = (counts[s] or 0) + 1; counts.all = counts.all + 1
            if s == "circle" and r.circle then
                local k = "circle:" .. r.circle; counts[k] = (counts[k] or 0) + 1
            end
        end
    end
    return counts
end
