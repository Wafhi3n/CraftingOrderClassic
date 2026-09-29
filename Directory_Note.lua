-- Directory_Note.lua — la note de membre de la communauté : lue dans l'annuaire, préparée pour le joueur.
--
-- Pourquoi (banc des constats, 2026-09-29, build 70058) : dans une communauté, un addon ne LIT pas les
-- messages (C3, C10 : référence opaque, même dans l'événement de chat) et n'ÉCRIT rien (C11 : écrire sa
-- propre note = ADDON_ACTION_FORBIDDEN). Mais une note posée À LA MAIN par le joueur se lit en clair
-- (C14) : c'est la seule information d'un membre lisible même quand il est HORS LIGNE. Deux usages :
--   * l'annuaire garde la note de chaque membre de cercle (Directory_Club, noteMember) et l'onglet
--     Artisans l'affiche sous son nom, connecté ou pas ;
--   * /co note prépare le texte de MES métiers, à copier puis coller dans ma note — l'addon ne peut pas
--     l'y mettre lui-même.

local COC = CraftingOrderClassic
local Dir = COC.Directory
local L = COC.L

local NOTE_MAX = 120   -- une note fait 200 caractères au plus ; l'annuaire n'en garde que 120

-- Coupe à `max` octets sans laisser un caractère UTF-8 à moitié : seul un dernier caractère INCOMPLET
-- tombe. (Retirer tous les octets non ASCII de la fin viderait une note entièrement accentuée.)
local function cutUtf8(s, max)
    if #s <= max then return s end
    s = s:sub(1, max)
    local p = #s
    while p > 0 do
        local b = s:byte(p)
        if b < 0x80 then return s end                          -- ASCII : la coupe est propre
        if b >= 0xC0 then                                      -- octet de tête : caractère complet ?
            local need = (b >= 0xF0 and 4) or (b >= 0xE0 and 3) or 2
            if #s - p + 1 < need then return s:sub(1, p - 1) end
            return s
        end
        p = p - 1                                              -- octet de suite : on remonte
    end
    return ""
end

-- Texte seul : sans séquence d'échappement (|c couleur, |H lien…), espaces resserrés, coupé sans
-- casser un caractère accentué. Une valeur secrète, absente ou vide rend nil.
function Dir:_CleanNote(v)
    if type(v) ~= "string" then return nil end
    if _G.issecretvalue then
        local ok, secret = pcall(_G.issecretvalue, v)
        if not ok or secret then return nil end
    end
    -- Séquences entières d'abord (couleur, lien, texture, référence opaque), puis toute barre restante :
    -- ôter la barre seule laisserait « cFFFF0000rouger » à la place de « rouge ».
    local s = v:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", "")
    s = s:gsub("|T.-|t", ""):gsub("|K.-|k", ""):gsub("|", ""):gsub("%s+", " ")
    s = s:match("^%s*(.-)%s*$")
    if s == "" then return nil end
    return cutUtf8(s, NOTE_MAX)
end

-- Le texte de MES métiers, pour ma note : « Enchantement 70 · Herboristerie 70 », du plus haut niveau
-- au plus bas. Libellés dans la langue du joueur : ce sont lui et ses voisins qui la lisent.
function Dir:MyNoteText()
    local skills = self.mySkills or (COC.db and COC.db.mySkills) or {}
    local list = {}
    for key, sk in pairs(skills) do list[#list + 1] = { key = key, rank = tonumber(sk[1]) or 0 } end
    table.sort(list, function(a, b)
        if a.rank ~= b.rank then return a.rank > b.rank end
        return a.key < b.key
    end)
    local Skin = COC.UI and COC.UI.Skin
    local parts = {}
    for _, it in ipairs(list) do
        local label = (Skin and Skin.ProfLabel and Skin.ProfLabel(it.key)) or it.key
        parts[#parts + 1] = label .. " " .. it.rank
    end
    return table.concat(parts, " · ")
end

-- Fenêtre « copie ce texte » : le champ arrive sélectionné, Ctrl+C suffit. Même moule que la fenêtre
-- de note de Blizzard (SET_COMMUNITY_MEMBER_NOTE, GameDialogDefs) — sans son OnAccept, qui écrit la
-- note : ce chemin-là est interdit à un addon. On AJOUTE une entrée à la table de Blizzard, jamais on
-- ne réaffecte la globale (`StaticPopupDialogs = …` la contaminerait pour le code sécurisé).
StaticPopupDialogs["COC_MEMBER_NOTE"] = {
    text = "%s",
    button1 = _G.CLOSE or "OK",
    hasEditBox = 1,
    maxLetters = 200,
    editBoxWidth = 350,
    OnShow = function(dialog, data)
        local eb = (dialog.GetEditBox and dialog:GetEditBox()) or dialog.editBox
        if eb then eb:SetText(data or ""); eb:HighlightText(); eb:SetFocus() end
    end,
    EditBoxOnEnterPressed = function(editBox) editBox:GetParent():Hide() end,
    EditBoxOnEscapePressed = function(editBox) editBox:GetParent():Hide() end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

-- /co note : la fenêtre, ou un mot d'explication si l'addon ne connaît encore aucun de mes métiers.
function Dir:ShowNoteText()
    if self.CaptureSkills then self:CaptureSkills() end
    local text = self:MyNoteText()
    if text == "" then
        print("|cFF33DD88Crafting Order|r " .. L["aucun métier connu pour ce personnage : ouvre une fois ta fenêtre de métier, puis recommence."])
        return
    end
    if StaticPopup_Show then
        StaticPopup_Show("COC_MEMBER_NOTE", L["Copie ce texte (Ctrl+C), puis colle-le dans ta note de membre : Communautés, clic droit sur ton nom, « Note ». Les autres joueurs de Crafting Order verront tes métiers, même quand tu es hors ligne."], nil, text)
    end
end
