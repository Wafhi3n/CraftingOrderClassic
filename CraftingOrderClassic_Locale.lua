-- CraftingOrderClassic_Locale.lua — localisation du CHROME de l'UI.
-- Convention : la CLÉ est le texte FRANÇAIS (langue de référence du code) ; `COC.L[clé]` renvoie la
-- clé par défaut (donc un client FR voit le texte tel quel, zéro régression) ; un overlay par langue
-- (ici enUS) remplace les clés. Pour ajouter une langue : copier le bloc `en` et traduire.
-- NB : les NOMS d'objets/recettes restent multilingues via GetItemInfo/GetSpellInfo (côté données).

local COC = CraftingOrderClassic
local L = setmetatable({}, { __index = function(_, k) return k end })
COC.L = L

local loc = GetLocale and GetLocale() or "enUS"

-- ------------------------------------------------------------------
-- Anglais (enUS/enGB) — overlay. Clé FR → texte EN.
-- ------------------------------------------------------------------
if loc == "enUS" or loc == "enGB" then
    local en = {
        -- Onglets / fenêtre
        ["Carnet"] = "Ledger", ["Commande"] = "Order", ["Récolte"] = "Gather", ["Artisans"] = "Artisans",
        ["Classic · canal global"] = "Classic · global channel",
        -- En-têtes de colonnes (Carnet)
        ["COMMANDE"] = "ORDER", ["QTÉ"] = "QTY", ["PRIX PROPOSÉ"] = "PRICE OFFERED",
        ["MÉTIER"] = "PROFESSION", ["DESTINATAIRE"] = "RECIPIENT", ["STATUT"] = "STATUS", ["DEMANDEUR"] = "REQUESTER",
        ["ARTISAN"] = "CRAFTER",
        -- Filtres Carnet
        ["Tous"] = "All", ["Guilde"] = "Guild", ["Amis"] = "Friends", ["Croisés"] = "Met", ["Entrantes"] = "Incoming",
        ["Archivées"] = "Archived", ["En cours"] = "Active", ["libre"] = "open",
        ["Aucune commande. Onglet « Commande » pour en poster une."] = "No orders. Use the « Order » tab to post one.",
        ["Aucune commande entrante. (Capture /commerce et /guilde des joueurs sans l'addon.)"] =
            "No incoming orders. (Captured from /trade and /guild of players without the addon.)",
        ["Demande captée dans /"] = "Request captured in /",
        ["Clic gauche : accepter (whisper au demandeur)"] = "Left click: accept (whisper the requester)",
        ["Clic droit : ignorer"] = "Right click: dismiss",
        ["Clic : "] = "Click: ", ["Accepter"] = "Accept", ["Annuler"] = "Cancel", ["Livrer"] = "Deliver",
        ["guilde"] = "guild", ["commerce"] = "trade", ["acceptée"] = "accepted",
        -- Statut bar
        ["réseau"] = "network", ["canal rejoint"] = "channel joined",
        ["en ligne"] = "online", ["artisan(s)"] = "crafter(s)",
        -- Professions
        ["Alchimie"] = "Alchemy", ["Forge"] = "Blacksmithing", ["Cuisine"] = "Cooking",
        ["Enchantement"] = "Enchanting", ["Ingénierie"] = "Engineering", ["Secourisme"] = "First Aid",
        ["Pêche"] = "Fishing", ["Herboristerie"] = "Herbalism", ["Travail du cuir"] = "Leatherworking",
        ["Minage"] = "Mining", ["Dépeçage"] = "Skinning", ["Couture"] = "Tailoring",
        ["Joaillerie"] = "Jewelcrafting", ["Calligraphie"] = "Inscription", ["Élémentaire"] = "Elemental",
        -- Statuts d'ordre
        ["En attente"] = "Pending", ["Acceptée"] = "Accepted", ["Livrée"] = "Delivered", ["Annulée"] = "Cancelled",
        -- Commande (Post)
        ["LISTE DES PLANS"] = "RECIPE LIST", ["JE FOURNIS"] = "I PROVIDE", ["Réactifs"] = "Reagents",
        ["(cocher = je fournis)"] = "(check = I provide)", ["Commission"] = "Commission", ["Qté"] = "Qty",
        ["Destinataire :"] = "Recipient:", ["Diffuser à tous"] = "Broadcast to all", ["Poster"] = "Post",
        ["Choisis un métier puis un plan."] = "Pick a profession then a recipe.",
        ["Rechercher un plan"] = "Search a recipe", ["Qualité : Toutes"] = "Quality: All", ["Qualité : "] = "Quality: ",
        ["Sélection : "] = "Selection: ", ["Commande postée !"] = "Order posted!",
        ["Choisis d'abord un plan."] = "Pick a recipe first.", ["Aucun plan sélectionné."] = "No recipe selected.",
        ["Ajoutés"] = "Added", ["fournis"] = "provided", ["Chargement…"] = "Loading…",
        -- Récolte (Gather)
        ["MÉTIER DE RÉCOLTE"] = "GATHERING PROFESSION", ["Rechercher une ressource"] = "Search a resource",
        ["LISTE DES RESSOURCES"] = "RESOURCE LIST", ["Demande de récolte — quantité voulue"] = "Gather request — wanted quantity",
        ["stacks"] = "stacks", ["Récolteur :"] = "Gatherer:", ["Prix proposé"] = "Price offered",
        ["Choisis un métier de récolte puis une ressource."] = "Pick a gathering profession then a resource.",
        ["Aucune ressource sélectionnée."] = "No resource selected.", ["par stack"] = "per stack", ["à l'unité"] = "per unit",
        ["Commande de récolte postée !"] = "Gather order posted!", ["Choisis d'abord une ressource."] = "Pick a resource first.",
        ["Toutes"] = "All",
        ["Objet |cFFE8B84Bélémentaire|r (farmé sur les mobs, pas de métier). Diffusé à tous. Quantité et prix |cFFE8B84B%s.|r"] =
            "|cFFE8B84BElemental|r item (farmed off mobs, no profession). Broadcast to all. Quantity and price |cFFE8B84B%s.|r",
        ["Diffusée aux récolteurs ayant |cFFE8B84B%s.|r Quantité et prix proposé |cFFE8B84B%s.|r"] =
            "Broadcast to gatherers with |cFFE8B84B%s.|r Quantity and offered price |cFFE8B84B%s.|r",
        -- Artisans
        ["SOURCE"] = "SOURCE", ["AJOUTER UN JOUEUR"] = "ADD A PLAYER", ["Nom du personnage"] = "Character name",
        ["Métier :"] = "Profession:", ["Chuchoter"] = "Whisper", ["Aucun artisan dans cette source."] = "No crafter in this source.",
        ["En ligne"] = "Online", ["Hors ligne"] = "Offline", ["niv "] = "lvl ", ["niv ?"] = "lvl ?",
        ["GUILDE"] = "GUILD", ["AMIS"] = "FRIEND", ["AJOUTÉ"] = "ADDED", ["CROISÉ"] = "MET",
        ["artisan ajouté : "] = "crafter added: ",
        ["(lié quand il sera en ligne avec l'addon)"] = "(linked when seen online with the addon)",
        -- Fenêtre métier (ProfWindow)
        ["Recettes"] = "Recipes", ["Commandes"] = "Orders", ["Réactifs :"] = "Reagents:",
        ["Créer"] = "Create", ["Créer tout"] = "Create All", ["Vue Blizzard"] = "Blizzard view",
        ["Sélectionne une recette."] = "Select a recipe.", ["Produit "] = "Makes ",
        ["entrante · "] = "incoming · ", ["réactifs insuffisants."] = "not enough reagents.",
        ["fenêtre métier custom |cFF33DD33activée|r — ouvre un métier. (Guild Economy laisse la main.)"] =
            "custom profession window |cFF33DD33enabled|r — open a profession. (Guild Economy stands down.)",
        ["fenêtre métier custom |cFFFFCC00désactivée|r (vue Blizzard)."] =
            "custom profession window |cFFFFCC00disabled|r (Blizzard view).",
        ["» Vue Crafting Order"] = "» Crafting Order view", ["Masquer"] = "Hide",
        ["overlay métier masqué — |cFFFFFFFF/co prof|r pour le réafficher."] =
            "profession overlay hidden — |cFFFFFFFF/co prof|r to show it again.",
        ["Module Commandes non chargé — redémarre complètement WoW (quitter/relancer), pas un simple /reload."] =
            "Orders module not loaded — fully restart WoW (quit/relaunch), not just /reload.",
        -- Minimap + menu métiers
        ["Clic : ouvrir le carnet d'ordres"] = "Click: open the order ledger",
        ["Clic droit : mes métiers"] = "Right click: my professions",
        ["Mes métiers"] = "My professions", ["Aucun métier connu."] = "No known profession.",
        ["Don / gratuit"] = "Free / gift",
        -- Entrantes (alertes chat)
        ["|cFFFF8800◆ entrante|r |cFFFFFFFF%s|r (%s) : %s%s%s"] = "|cFFFF8800◆ incoming|r |cFFFFFFFF%s|r (%s): %s%s%s",
        ["   |cFF33DD33→ tu sais la crafter|r — Carnet › Entrantes"] = "   |cFF33DD33→ you can craft it|r — Ledger › Incoming",
        ["|cFFFFCC00◆ commande pour TOI|r de |cFFFFFFFF%s|r : %s%s%s"] = "|cFFFFCC00◆ order for YOU|r from |cFFFFFFFF%s|r: %s%s%s",
        ["ton artisan |cFFFFFFFF%s|r est en ligne."] = "your crafter |cFFFFFFFF%s|r is online.",
    }
    for k, v in pairs(en) do L[k] = v end
end
