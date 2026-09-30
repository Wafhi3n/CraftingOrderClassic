-- CraftingOrderClassic_Locale_esES_3.lua — overlay esES, 3/3. Clé FR » texte traduit.
-- Troisième part, ouverte le 2026-09-26 : _2 avait atteint le plafond anti-monolithe
-- (500 l/fichier) en accueillant les clés de la bande LFW. Même contrat que les deux
-- autres — table à plat fusionnée dans COC.L, aucun ordre requis entre les parts.

local COC = CraftingOrderClassic
local loc = GetLocale and GetLocale() or ""
if loc ~= "esES" and loc ~= "esMX" then return end
local L = COC.L

local es3 = {
    -- Bande « chercher du travail » + sélecteur d'offre (2026-09-26)
    ["Route"] = "Ruta",               -- languette courte (la vue garde « Ruta de subida »)
    ["Dispo — %s"] = "Disponible — %s",
    ["Offre"] = "Oferta",
    ["Réactifs"] = "Reactivos",
    ["Recettes"] = "Recetas",
    ["Aucun résultat pour cette recherche."] = "Ningun resultado para esa busqueda.",
    ["Rien à afficher pour ce métier."] = "Nada que mostrar para esta profesion.",
    ["Recettes proposées (%d/%d)"] = "Recetas ofrecidas (%d/%d)",
    -- Réseau sans canal + communauté officielle (2026-09-28)
    ["réseau par whisper"] = "red por susurros",
    ["canal : aucun — le réseau passe en whisper (cercles, amis, guilde)"] =
        "canal: ninguno — la red funciona por susurros (círculos, amigos, hermandad)",
    ["communauté officielle marquée comme cercle d'artisans : %s"] =
        "comunidad oficial marcada como círculo de artesanos: %s",
    ["Rejoins la communauté des artisans : %s — c'est là que Crafting Order trouve les autres joueurs."] =
        "Únete a la comunidad de artesanos: %s — ahí es donde Crafting Order encuentra a los demás jugadores.",
    ["(/co circle nolink : ne plus afficher ce rappel)"] = "(/co circle nolink: no volver a mostrar este aviso)",
    ["rappel de la communauté éteint — /co circle link pour le rallumer."] =
        "aviso de la comunidad desactivado — /co circle link para reactivarlo.",
    ["rappel de la communauté rallumé."] = "aviso de la comunidad reactivado.",
    -- Icône « nouvelle version » de la barre de la minicarte (2026-09-28)
    ["Tu as la %s. Mets l'addon à jour depuis CurseForge."] = "Tienes la %s. Actualiza el addon desde CurseForge.",
    ["Crafting Order n'utilise plus de canal de discussion : sur WoW Forever, il est découpé en salles et les joueurs ne s'y voient pas tous.\n\nLes artisans se retrouvent maintenant dans la communauté |cFFFFD100%s|r. Clique sur le lien dans ton chat pour y entrer."] =
        "Crafting Order ya no usa un canal de chat: en WoW Forever se divide en salas separadas y no todos los jugadores se ven.\n\nLos artesanos se reúnen ahora en la comunidad |cFFFFD100%s|r. Haz clic en el enlace de tu chat para unirte.",
    -- Signature du build de test, /co version (2026-09-28)
    ["Build : %s"] = "Build: %s",
    ["Branches en test : %s"] = "Ramas en prueba: %s",
    -- Salle de découverte, Directory_Room (2026-09-29)
    ["l'addon rejoint le canal |cFFFFFFFF%s|r pour se présenter aux autres joueurs de Crafting Order ; tes commandes, elles, restent en whisper. |cFFFFFFFF/co channel room off|r pour ne plus le rejoindre."] =
        "el addon entra en el canal |cFFFFFFFF%s|r para presentarse a otros jugadores de Crafting Order; tus pedidos siguen yendo por susurro. |cFFFFFFFF/co channel room off|r para no volver a entrar.",
    ["salle de découverte coupée : l'addon quitte |cFFFFFFFF%s|r et ne le rejoindra plus."] =
        "sala de descubrimiento desactivada: el addon sale de |cFFFFFFFF%s|r y no volverá a entrar.",
    ["salle de découverte rouverte : l'addon rejoint |cFFFFFFFF%s|r pour se présenter."] =
        "sala de descubrimiento reactivada: el addon entra en |cFFFFFFFF%s|r para presentarse.",
    ["salle de découverte : en attente du canal (quelques secondes après la connexion)"] =
        "sala de descubrimiento: esperando el canal (unos segundos tras conectarse)",
    ["salle de découverte : coupée — |cFFFFFFFF/co channel room on|r pour la rouvrir"] =
        "sala de descubrimiento: desactivada — |cFFFFFFFF/co channel room on|r para reactivarla",
    ["salle de découverte : |cFFFFFFFF%s|r — on s'y présente, les données restent en whisper"] =
        "sala de descubrimiento: |cFFFFFFFF%s|r — sirve para presentarse, los datos siguen yendo por susurro",
    -- Annonce sur Trade (Services), Orders_AnnounceSend (2026-09-29)
    ["Annoncer en Commerce"] = "Anunciar en Comercio",
    ["Poste aussi une ligne sur Trade (Services), lisible par tous : les joueurs avec ou sans l'addon voient ta commande. Une ligne par clic, jamais de répétition automatique ; seulement pour une commande à tous, dans une capitale."] =
        "Publica también una línea en Comercio (Servicios), legible por todos: los jugadores con o sin el addon ven tu pedido. Una línea por clic, nunca repetida automáticamente; solo para un pedido a todos, en una capital.",
    ["seule une commande ouverte, à toi, s'annonce."] = "solo se puede anunciar un pedido abierto tuyo.",
    ["commande privée : elle ne s'annonce pas sur Commerce."] = "pedido privado: nunca se anuncia en Comercio.",
    ["déjà annoncée : tu pourras la rappeler dans %d min."] = "ya anunciado: podrás repetirlo en %d min.",
    ["une annonce par minute au plus : attends encore %d s."] = "un anuncio por minuto como máximo: espera %d s más.",
    ["pas de canal Trade (Services) ici : il faut être dans une capitale."] =
        "aquí no hay canal Comercio (Servicios): tienes que estar en una capital.",
    ["annonce impossible : un objet n'est pas encore connu du jeu, réessaie dans un instant."] =
        "aún no se puede anunciar: un objeto no está cargado, inténtalo de nuevo en un momento.",
    ["annonce refusée par le jeu."] = "el juego rechazó el anuncio.",
    ["commande annoncée sur %s."] = "pedido anunciado en %s.",
    ["Clic droit : annoncer en Commerce"] = "Clic derecho: anunciar en Comercio",
    ["Clic droit : rappeler en Commerce"] = "Clic derecho: repetir en Comercio",
    -- Annonce de la dispo LFW (2026-09-30)
    ["dispo annoncée sur %s."] = "disponibilidad anunciada en %s.",
    ["Quand tu actives ta dispo, poste aussi une ligne sur Trade (Services) : les joueurs avec ou sans l'addon voient que tu cherches du travail. Une ligne par activation, jamais au renouvellement automatique ; dans une capitale. Même réglage que la case du formulaire de commande."] =
        "Al activar tu búsqueda de trabajo, publica también una línea en Comercio (Servicios): los jugadores con o sin el addon ven que buscas trabajo. Una línea por activación, nunca en la renovación automática; solo en una capital. El mismo ajuste que la casilla del formulario de pedido.",
    -- Aide sans communauté officielle (2026-09-30)
    ["|cFFFFFFFF/co circle|r : tes cercles d'artisans (les communautés du jeu que tu as marquées)."] =
        "|cFFFFFFFF/co circle|r: tus círculos de artesanos (las comunidades del juego que has marcado).",
    ["Les artisans se trouvent par tes amis, ta guilde et tes cercles, par la salle de découverte (|cFFFFFFFF/co channel room|r) où les porteurs de l'addon se disent bonjour, et par les annonces sur Trade (Services) que l'addon relit."] =
        "Los artesanos se encuentran a través de tus amigos, tu hermandad y tus círculos, de la sala de descubrimiento (|cFFFFFFFF/co channel room|r) donde los usuarios del addon se saludan, y de los anuncios en Comercio (Servicios) que el addon lee.",
    -- Aide remise à jour : onglets latéraux, cercles (2026-09-28)
    ["Ils se rangent sur le bord droit, comme ceux de la fenêtre de métier. Survole une icône pour lire son nom ; le chiffre sur le Carnet compte tes commandes en cours."] =
        "Están en el borde derecho, como los de la ventana de profesión. Pasa el ratón sobre un icono para leer su nombre; el número sobre el Libro cuenta tus pedidos activos.",
    ["|cFFE8B84BMes artisans|r : les métiers de tous les personnages de ton compte, et leurs recettes."] =
        "|cFFE8B84BMis artesanos|r: las profesiones de todos los personajes de tu cuenta, y sus recetas.",
    ["|cFFE8B84BAide|r et |cFFE8B84BNouveautés|r : cette page, et ce qui a changé à chaque version."] =
        "|cFFE8B84BAyuda|r y |cFFE8B84BNovedades|r: esta página, y lo que cambió en cada versión.",
    ["cercles d'artisans (communautés) et rappel de la communauté"] =
        "círculos de artesanos (comunidades) y el aviso de la comunidad",
    ["ou"] = "o",   -- statuts d'une commande, Aide : « (ou Annulée / Refusée) »
    -- Courrier : l'addon ne coupe plus une pile lui-même (2026-09-28)
    ["Il en manque %d au courrier : sépare-les d'une pile toi-même (Maj-clic sur la pile), puis dépose-les."] =
        "Faltan %d en el correo: sepáralos tú mismo de una pila (Mayús-clic en la pila) y luego colócalos.",
    ["La pile de %d est prête dans ton sac : dépose-la toi-même dans le courrier."] =
        "La pila de %d está lista en tu bolsa: colócala tú mismo en el correo.",
    -- Note de membre de la communauté, /co note (2026-09-29)
    ["le texte de tes métiers, à coller dans ta note de communauté (visible même hors ligne)"] =
        "el texto de tus profesiones, para pegarlo en tu nota de comunidad (visible incluso desconectado)",
    ["aucun métier connu pour ce personnage : ouvre une fois ta fenêtre de métier, puis recommence."] =
        "aún no se conoce ninguna profesión de este personaje: abre una vez tu ventana de profesión y vuelve a intentarlo.",
    ["Copie ce texte (Ctrl+C), puis colle-le dans ta note de membre : Communautés, clic droit sur ton nom, « Note ». Les autres joueurs de Crafting Order verront tes métiers, même quand tu es hors ligne."] =
        "Copia este texto (Ctrl+C) y pégalo en tu nota de miembro: Comunidades, clic derecho en tu nombre, «Nota». Los demás jugadores de Crafting Order verán tus profesiones, incluso cuando estés desconectado.",
    -- Lib absente au chargement (2026-09-30)
    ["la bibliothèque CraftLink n'a pas pu se charger : le réseau de l'addon est coupé (annuaire, commandes). Fais |cFFFFFFFF/reload|r ; si ça continue, réinstalle l'addon."] =
        "la biblioteca CraftLink no se pudo cargar: la red del addon está desactivada (directorio, pedidos). Escribe |cFFFFFFFF/reload|r; si vuelve a pasar, reinstala el addon.",
    -- Canaux surveillés : l'origine d'une entrante lue sur le canal Général (2026-09-30)
    ["général"] = "general",
}

for k, v in pairs(es3) do L[k] = v end
