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
        -- Filtres Carnet
        ["Tous"] = "All", ["Guilde"] = "Guild", ["Amis"] = "Friends", ["Croisés"] = "Met", ["Entrantes"] = "Incoming",
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
        ["Rechercher un plan"] = "Search a recipe", ["Qualité : Toutes"] = "Quality: All",
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
        -- Artisans
        ["SOURCE"] = "SOURCE", ["AJOUTER UN JOUEUR"] = "ADD A PLAYER", ["Nom du personnage"] = "Character name",
        ["Métier :"] = "Profession:", ["Chuchoter"] = "Whisper", ["Aucun artisan dans cette source."] = "No crafter in this source.",
        ["En ligne"] = "Online", ["Hors ligne"] = "Offline", ["niv "] = "lvl ", ["niv ?"] = "lvl ?",
        ["GUILDE"] = "GUILD", ["AMIS"] = "FRIEND", ["AJOUTÉ"] = "ADDED", ["CROISÉ"] = "MET",
        -- Fenêtre métier (ProfWindow)
        ["Recettes"] = "Recipes", ["Commandes"] = "Orders", ["Réactifs :"] = "Reagents:",
        ["Créer"] = "Create", ["Créer tout"] = "Create All", ["Vue Blizzard"] = "Blizzard view",
        ["Sélectionne une recette."] = "Select a recipe.", ["Produit "] = "Makes ",
        ["entrante · "] = "incoming · ", ["réactifs insuffisants."] = "not enough reagents.",
        -- Minimap
        ["Clic : ouvrir le carnet d'ordres"] = "Click: open the order ledger",
    }
    for k, v in pairs(en) do L[k] = v end
end
