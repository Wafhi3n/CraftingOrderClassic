-- CraftingOrderClassic_MinimapIndicator_Who.lua — QUI, sur mon compte, sait faire une commande, et
-- d'où elle vient. Sert les icônes de la minicarte (MinimapIndicator_Orders), 3e tour de la spec
-- docs/specs/icone-commande-recue.md (décisions du user du 2026-09-30) :
--   * le clic va vers le perso qui sait faire (native / vue reroll / popup) ;
--   * une commande non nommée n'allume l'icône que si un de mes persos sait la faire ;
--   * la couleur du nombre dit d'où vient la commande, avec la palette daltonienne du jeu.
--
-- « Sait faire » = CONNAÎT LA RECETTE d'après les partitions persistées db.knownRecipes["Prénom-Royaume"]
-- [métier] = { [spellID] = true } (patron Handoff:MyRerollCanCraft). Un perso dont le métier n'a jamais
-- été ouvert n'a pas de partition : il ne compte pas, on ne devine pas.

local COC = CraftingOrderClassic
local UI  = COC.UI
local L   = COC.L

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end
local function realm() return (GetRealmName and GetRealmName()) or "" end
local function meKey() return ((UnitName and UnitName("player")) or "?") .. "-" .. realm() end

-- Le sort de la commande : le sien, sinon celui que le catalogue associe à l'objet.
local function spellOf(o)
    if o.spellID then return o.spellID end
    local c, prof = CL(), o.profession
    local i2s = c and prof and o.itemID and c:ItemToSpell(prof)
    return i2s and i2s[o.itemID] or nil
end

-- Prénom d'une clé « Prénom-Royaume » du royaume courant, sinon nil (autre royaume).
local function shortOfRealm(key, r)
    local short, kr = key:match("^([^%-]+)%-(.*)$")
    if short and kr == r then return short end
    return nil
end

-- Mes persos qui connaissent la recette de `o`, même royaume, même camp que le perso connecté :
-- { { key, short, isMe, rank }, … }. Un reroll d'en face n'est pas quelqu'un sur qui aller (Mes artisans).
function UI:_OrderKnowers(o)
    local out, db = {}, COC.db
    local prof, sid = o and o.profession, o and spellOf(o)
    if not (db and db.knownRecipes and prof and sid) then return out end
    local r, mine = realm(), meKey()
    local myFaction = UnitFactionGroup and UnitFactionGroup("player")
    local factions, skills = db.myCharFaction or {}, db.mySkillsByChar or {}
    for key, part in pairs(db.knownRecipes) do
        local short, set = shortOfRealm(key, r), part[prof]
        local f = factions[key]
        if short and set and set[sid] and not (myFaction and f and f ~= myFaction) then
            local sk = skills[key] and skills[key][prof]
            out[#out + 1] = { key = key, short = short, isMe = (key == mine), rank = sk and sk[1] or 0 }
        end
    end
    return out
end

-- Où va le clic pour `o` : { kind = "native" } si le perso connecté connaît la recette ; sinon
-- { kind = "reroll", key, short } — celui à qui la commande est nommée, sinon le plus haut niveau ;
-- sinon { kind = "popup" }. Décisions du user, 2026-09-30 ; le 2026-10-02, il a tranché que le perso
-- connecté qui connaît la recette prend la main, même sur une commande nommée pour un reroll qui la sait.
function UI:_OrderClickTarget(o)
    if not o then return { kind = "popup" } end
    -- Le destinataire nommé, ramené au prénom (clé locale des persos) : « Rédemption Wafhien » → « Rédemption ».
    local named = self:_OrderKind(o) == "named" and o.recipient:match("^(%S+)") or nil
    local best, meKnows = nil, false
    for _, k in ipairs(self:_OrderKnowers(o)) do
        if k.isMe then meKnows = true
        else
            local kNamed, bNamed = k.short == named, best ~= nil and best.short == named
            if not best or (kNamed and not bNamed) or (kNamed == bNamed and k.rank > best.rank) then best = k end
        end
    end
    if meKnows then return { kind = "native" } end
    if best then return { kind = "reroll", key = best.key, short = best.short } end
    return { kind = "popup" }
end

-- D'où vient une commande : "named" (moi ou un reroll), "group" (guilde, amis), "all" (tous).
function UI:_OrderKind(o)
    local r = o.recipient
    if not r or r == "" or r == "Tous" then return "all" end
    if r == "Guilde" or r == "Amis" then return "group" end
    return "named"
end

UI.ORDER_KIND_RANK = { named = 1, group = 2, all = 3 }   -- le plus personnel d'abord

-- ------------------------------------------------------------------
-- Couleur du nombre (choix du user, 2026-09-30) et mode daltonien du jeu
-- ------------------------------------------------------------------
-- Normale : bleu de la liste d'amis, vert de la discussion de guilde, jaune. Daltonien : Okabe-Ito
-- (vermillon, bleu ciel, jaune), qui diffèrent aussi en luminosité sur le fond sombre de la barre.
local PALETTE = {
    normal = { named = { 0.51, 0.77, 1.0 }, group = { 0.25, 1.0, 0.25 }, all = { 1.0, 0.9, 0.1 } },
    cvd    = { named = { 0.84, 0.37, 0.0 }, group = { 0.34, 0.71, 0.91 }, all = { 0.94, 0.89, 0.26 } },
}

function UI:_ColorblindOn()
    if C_CVar and C_CVar.GetCVarBool then return C_CVar.GetCVarBool("colorblindMode") == true end
    return GetCVar and GetCVar("colorblindMode") == "1" or false
end

function UI:_OrderKindColor(kind)
    local p = self:_ColorblindOn() and PALETTE.cvd or PALETTE.normal
    return p[kind] or p.named
end

-- ------------------------------------------------------------------
-- Popup « personne ne sait faire » (même mécanique que COC:MissingAddon, vue en jeu)
-- ------------------------------------------------------------------
local function sourceLine(o)
    local S, sid = COC.Sources, spellOf(o)
    local txt = S and S.SourceText and sid and S:SourceText(o.profession, sid)
    return (txt and txt ~= "") and ("\n|cFF888888" .. string.format(L["Où l'apprendre : %s"], txt) .. "|r") or ""
end

function UI:ShowNobodyKnows(o, count)
    if not (o and StaticPopupDialogs and StaticPopup_Show) then return end
    local O = COC.Orders
    local name = (O and O.OrderName) and O:OrderName(o) or "?"
    local text = string.format(L["Aucun de tes persos ne sait faire %s."], "|cFFFFD100" .. name .. "|r")
    if (count or 1) > 1 then text = text .. "\n" .. string.format(L["%d commandes attendent dans ce métier."], count) end
    local D, prof = COC.Directory, o.profession
    local canOpen = prof and D and D.mySkills and D.mySkills[prof] and COC.ProfWindow and COC.ProfWindow.OpenFor
    StaticPopupDialogs["COC_NOBODY_KNOWS"] = {
        text = text .. sourceLine(o),
        button1 = canOpen and L["Ouvrir la fenêtre de métier"] or (OKAY or "OK"),
        button2 = canOpen and (CLOSE or "Close") or nil,
        OnAccept = canOpen and function() COC.ProfWindow:OpenFor(prof) end or nil,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopup_Show("COC_NOBODY_KNOWS")
end
