-- CraftingOrderClassic_SelfTest.lua — suite de tests IN-GAME (/cotest). QA/dev.
--
-- Couvre la LOGIQUE risquée touchée par la passe de revue de code (2026-07-04) :
--   * codec bitfield CraftLink (Encode/Decode/HasBit/CountKnown, roundtrip) ;
--   * cache ProfessionCatalogue (identité de table = mémoïsation active) ;
--   * helpers d'annuaire partagés + divergence craftSeen (KnowsProf vs KnowsProfOrSeen, InSource) ;
--   * durcissement du protocole ORD (validation de l'émetteur : CANCEL/DONE ⇐ acheteur, ACK ⇐ émetteur) ;
--   * rétention du cache d'ordres (PruneExpired : ouverte d'autrui expirée / terminée > 7 j / muted orphelin).
--
-- SÛR sur un perso LIVE : command-gated (zéro coût au load) et les tests d'état SNAPSHOT+RESTAURENT
-- COC.db.orders/muted/delivered (restauration inconditionnelle après pcall). Ne fait AUCUN envoi réseau.
-- La virtualisation de la liste de plans se vérifie à l'œil (rappel imprimé en fin de suite).
--
-- NB : fichier de QA. Pour l'exclure d'une release, retire cette ligne des 3 .toc + supprime le fichier.

local COC = CraftingOrderClassic
local T = { pass = 0, fail = 0, log = {} }
COC.SelfTest = T

local function CL() return LibStub and LibStub:GetLibrary("CraftLink-1.0", true) end
local function out(s) print("|cFF33DD88[CO selftest]|r " .. s) end

local function check(cond, label)
    if cond then T.pass = T.pass + 1
    else T.fail = T.fail + 1; T.log[#T.log + 1] = label end
    return cond
end

-- === Groupe 1 : codec bitfield CraftLink (roundtrip) ===
function T:_TestBitfield()
    local c = CL(); if not c then return check(false, "CraftLink absent") end
    local prof
    for _, p in ipairs(c:Professions()) do if c:Count(p) >= 3 then prof = p; break end end
    if not prof then return check(false, "aucun métier avec >=3 recettes (catalogue vide ?)") end
    local recipes = c:GetRecipes(prof)
    local set = { [recipes[1]] = true, [recipes[2]] = true, [recipes[3]] = true }
    local hex, n = c:EncodeKnown(prof, set)
    check(n == 3, "EncodeKnown : 3 bits posés (" .. prof .. ")")
    check(c:CountKnown(prof, hex) == 3, "CountKnown == 3")
    local dec = c:DecodeKnown(prof, hex)
    check(dec and dec[recipes[1]] and dec[recipes[2]] and dec[recipes[3]], "DecodeKnown : roundtrip complet")
    check(c:HasBit(prof, hex, recipes[1]) == true, "HasBit : bit posé == true")
    local unset = recipes[#recipes]
    if unset ~= recipes[1] and unset ~= recipes[2] and unset ~= recipes[3] then
        check(c:HasBit(prof, hex, unset) == false, "HasBit : bit non posé == false")
    end
end

-- === Groupe 2 : cache ProfessionCatalogue (identité de table) ===
function T:_TestCatalogCache()
    local c = CL(); if not c then return end
    local p = c:Professions()[1]; if not p then return check(false, "aucun métier catalogué") end
    check(c:ProfessionCatalogue(p) == c:ProfessionCatalogue(p), "ProfessionCatalogue mémoïsé (même table)")
end

-- === Groupe 3 : helpers d'annuaire partagés (divergence craftSeen voulue) ===
function T:_TestHelpers()
    local Skin = COC.UI and COC.UI.Skin; if not Skin then return check(false, "Skin absent") end
    local rSkill  = { skill = { Tailoring = { 100, 150 } } }
    local rSeen   = { craftSeen = { Tailoring = 100 } }
    local rGuild  = { isGuild = true }
    local rConfed = { source = "confed" }
    check(Skin.KnowsProf(rSkill, "Tailoring"), "KnowsProf(skill) : vrai")
    check(not Skin.KnowsProf(rSeen, "Tailoring"), "KnowsProf(craftSeen) : FAUX (non ciblable pour commande)")
    check(Skin.KnowsProfOrSeen(rSeen, "Tailoring"), "KnowsProfOrSeen(craftSeen) : vrai (annuaire)")
    check(Skin.InSource(rGuild, "guild") == true, "InSource : guilde")
    check(not Skin.InSource(rGuild, "friend"), "InSource : guilde n'est pas ami")
    check(Skin.InSource(rConfed, "recent") == true, "InSource : confed traité comme recent")
end

-- === Groupe 4 : durcissement ORD (validation de l'émetteur) ===
function T:_TestOrderSecurity()
    local O = COC.Orders; if not (O and COC.db) then return check(false, "Orders/db absent") end
    local savedO, savedDeliv = COC.db.orders, COC.db.delivered
    COC.db.orders = {
        C1 = { id = "C1", buyer = "Alice", status = "open" },
        A1 = { id = "A1", buyer = "Alice", status = "open" },
        D1 = { id = "D1", buyer = "Alice", status = "delivered", acceptedBy = "Bob_notme_9137" },
    }
    local ok = pcall(function()
        O:_OnCycle("CANCEL", "ORD|CANCEL|C1", "Mallory")
        check(COC.db.orders.C1.status == "open", "CANCEL par un tiers : IGNORÉ")
        O:_OnCycle("CANCEL", "ORD|CANCEL|C1", "Alice")
        check(COC.db.orders.C1.status == "cancelled", "CANCEL par l'auteur : accepté")
        O:_OnCycle("ACK", "ORD|ACK|A1|Faker", "RealCrafter")
        check(COC.db.orders.A1.acceptedBy == "RealCrafter", "ACK : accepteur = émetteur réel (anti-spoof)")
        O:_OnCycle("DONE", "ORD|DONE|D1|Bob_notme_9137", "Mallory")
        check(COC.db.orders.D1.status ~= "done", "DONE par un tiers : IGNORÉ")
        O:_OnCycle("DONE", "ORD|DONE|D1|Bob_notme_9137", "Alice")
        check(COC.db.orders.D1.status == "done", "DONE par l'acheteur : accepté")
    end)
    COC.db.orders, COC.db.delivered = savedO, savedDeliv   -- restauration inconditionnelle
    if not ok then check(false, "exception pendant le test ORD") end
end

-- === Groupe 5 : rétention du cache d'ordres (PruneExpired) ===
function T:_TestPrune()
    local O = COC.Orders; if not (O and COC.db) then return check(false, "Orders/db absent") end
    local me = (UnitName and UnitName("player")) or "Me"
    local now = time()
    local savedO, savedM = COC.db.orders, COC.db.muted
    COC.db.orders = {
        OPEN_OTHER_OLD = { id = "OPEN_OTHER_OLD", status = "open", buyer = "Zed", ts = now - 7 * 3600 },
        OPEN_MINE_OLD  = { id = "OPEN_MINE_OLD",  status = "open", buyer = me,    ts = now - 7 * 3600 },
        DONE_OLD       = { id = "DONE_OLD",  status = "done", buyer = "Zed", ts = now - 8 * 86400, acceptedBy = "X" },
        DONE_RECENT    = { id = "DONE_RECENT", status = "done", buyer = "Zed", ts = now - 86400, acceptedBy = "X" },
    }
    COC.db.muted = { GHOST = true, DONE_RECENT = true }
    local ok = pcall(function() O:PruneExpired() end)
    check(COC.db.orders.OPEN_OTHER_OLD == nil, "prune : ouverte d'autrui expirée retirée")
    check(COC.db.orders.OPEN_MINE_OLD ~= nil, "prune : MA commande ouverte conservée")
    check(COC.db.orders.DONE_OLD == nil, "prune : terminée > 7 j retirée")
    check(COC.db.orders.DONE_RECENT ~= nil, "prune : terminée récente conservée")
    check(COC.db.muted.GHOST == nil, "prune : id muté orphelin retiré")
    check(COC.db.muted.DONE_RECENT == true, "prune : id muté encore valide conservé")
    COC.db.orders, COC.db.muted = savedO, savedM   -- restauration inconditionnelle
    if not ok then check(false, "exception pendant le test prune") end
end

-- === Groupe 6 : découpage en sections (SectionOf) ===
function T:_TestSection()
    if not (COC.SectionOf and GetItemInfoInstant) then return end
    local label, order = COC.SectionOf(2589)   -- Linen Cloth (Classic Era)
    check(type(label) == "string" and type(order) == "number", "SectionOf : renvoie (string, number)")
end

function T:Run()
    self.pass, self.fail, self.log = 0, 0, {}
    self:_TestBitfield()
    self:_TestCatalogCache()
    self:_TestHelpers()
    self:_TestOrderSecurity()
    self:_TestPrune()
    self:_TestSection()
    out(string.format("terminé : |cFF33DD33%d OK|r · %s%d échec(s)|r",
        self.pass, self.fail > 0 and "|cFFFF4444" or "|cFF888888", self.fail))
    for _, l in ipairs(self.log) do print("   |cFFFF4444x|r " .. l) end
    out("Rappel : la VIRTUALISATION se vérifie à l'œil — ouvre |cFFFFFFFFCommande|r, choisis |cFFFFFFFFCouture|r,")
    out("descends tout en bas et vérifie que les DERNIERS plans (Bolt of Woolen/Linen Cloth) sont atteignables.")
end

SLASH_COCTEST1 = "/cotest"
SlashCmdList["COCTEST"] = function() if COC.SelfTest then COC.SelfTest:Run() end end
