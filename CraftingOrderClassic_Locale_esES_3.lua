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
    ["par whisper"] = "por susurros",   -- suit « réseau » (barre du bas, /co status)
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
    ["Les artisans se trouvent par tes amis et ta guilde, et par les canaux que tu coches dans l'onglet Artisans, liste « Canaux surveillés » : Commerce, la salle de découverte, tes communautés, les joueurs autour de toi. Le bouton « Configurer » y rouvre le panneau du premier lancement."] =
        "Los artesanos se encuentran a través de tus amigos y tu hermandad, y de los canales que marcas en la pestaña Artesanos, en «Canales vigilados»: Comercio, la sala de descubrimiento, tus comunidades, los jugadores a tu alrededor. El botón «Configurar» reabre ahí el panel del primer inicio.",
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
    -- Canaux surveillés : la section de l'onglet Artisans (2026-09-30)
    ["CANAUX SURVEILLÉS"] = "CANALES VIGILADOS",
    ["ANNONCES LUES"] = "ANUNCIOS LEÍDOS",
    ["L'addon y lit les demandes, les dispos et les annonces des autres joueurs de l'addon. Il n'écrit que sur Trade (Services), et seulement si tu coches « Annoncer en Commerce »."] =
        "El addon lee ahí las peticiones, las disponibilidades y los anuncios de otros usuarios del addon. Solo escribe en Comercio (Servicios), y solo si marcas «Anunciar en Comercio».",
    ["Commerce (Services)"] = "Comercio (Servicios)",
    ["Commerce"] = "Comercio",
    ["Commerce (local)"] = "Comercio (local)",
    ["Général"] = "General",
    ["en ville"] = "en ciudad",
    ["RÉSEAU DE L'ADDON"] = "RED DEL ADDON",
    ["L'addon s'y présente par un message invisible aux joueurs de ta salle ; ensuite, tout passe en chuchotement."] =
        "El addon se presenta ahí con un mensaje invisible a los jugadores de tu sala; después, todo va por susurro.",
    ["salle"] = "sala",
    ["COMMUNAUTÉS"] = "COMUNIDADES",
    ["Les membres d'une communauté cochée rejoignent ton annuaire, même hors ligne. Aucune donnée de l'addon n'y passe."] =
        "Los miembros de una comunidad marcada entran en tu directorio, incluso desconectados. Ningún dato del addon pasa por ella.",
    ["aucune communauté"] = "ninguna comunidad",
    ["AUTOUR DE MOI"] = "A MI ALREDEDOR",
    ["Ce que les joueurs disent ou crient près de toi (les lignes LFW), et, en ville, ceux que tu vois crafter."] =
        "Lo que los jugadores dicen o gritan cerca de ti (líneas LFW) y, en ciudad, a quienes ves fabricar.",
    ["Dire et crier"] = "Decir y gritar",
    ["Crafteurs autour"] = "Artesanos cercanos",
    ["NOTIFICATIONS"] = "NOTIFICACIONES",
    ["Ce qui te prévient : une ligne dans le chat, un bandeau et un son. Décochée, une case ne retire aucune commande : tout reste dans le Carnet et la vue métier."] =
        "Lo que te avisa: una línea en el chat, un aviso y un sonido. Desmarcar una casilla no quita ningún pedido: todo sigue en el Libro y en la vista de profesión.",
    ["Commandes de l'addon"] = "Pedidos del addon",
    ["Les commandes que les autres joueurs de l'addon t'envoient ou publient."] =
        "Los pedidos que otros jugadores del addon te envían o publican.",
    ["Demandes lues dans le chat"] = "Solicitudes leídas en el chat",
    ["Les demandes (« WTB [objet] ») lues dans les canaux cochés plus haut, pour ce que tu sais crafter."] =
        "Las solicitudes (« WTB [objeto] ») leídas en los canales marcados arriba, para lo que sabes fabricar.",
    ["Guilde, amis et pour moi"] = "Hermandad, amigos y yo",
    ["Pas les commandes publiques ouvertes à tous."] = "No los pedidos públicos abiertos a todos.",
    ["Seulement pour moi"] = "Solo para mí",
    ["Les commandes à ton nom ou à celui d'un de tes persos."] = "Los pedidos a tu nombre o al de uno de tus personajes.",
    ["Aussi les commandes publiques, pour un métier que tu as."] = "También los pedidos públicos, para una profesión que tienes.",
    ["Suivi de mes commandes"] = "Seguimiento de mis pedidos",
    ["Une commande qu'on t'a remise, dont on a confirmé la réception, ou qu'on a refusée."] = "Un pedido que te han entregado, cuya recepción se ha confirmado, o que se ha rechazado.",
    ["Message à la connexion"] = "Mensaje al conectar",
    ["La ligne « chargé — /co help » quand tu te connectes."] = "La línea « cargado — /co help » al conectarte.",
    ["FAÇON DE PRÉVENIR"] = "CÓMO AVISAR",
    ["Pour toutes les alertes cochées au-dessus."] = "Para todos los avisos marcados arriba.",
    ["Ligne dans le chat"] = "Línea en el chat",
    ["Bandeau à l'écran"] = "Aviso en pantalla",
    ["Son"] = "Sonido",
    ["Tu n'es pas dans ce canal en ce moment. Ton choix est gardé pour ton retour."] =
        "No estás en este canal ahora mismo. Tu elección se guarda para cuando vuelvas.",
    -- Refonte de l'onglet Artisans (2026-09-30) : la bande des joueurs croisés, le bouton qui rouvre le panneau
    ["Croisés"] = "Vistos",
    ["Configurer"] = "Configurar",
    ["Rouvre le panneau de première connexion."] = "Vuelve a abrir el panel de la primera conexión.",
    -- Canaux surveillés : le panneau de première connexion (2026-09-30)
    ["Où chercher les artisans ?"] = "¿Dónde buscar artesanos?",
    ["L'addon trouve les artisans par les canaux que tu coches ici. Tu pourras tout changer plus tard, dans l'onglet Artisans."] =
        "El addon encuentra artesanos a través de los canales que marcas aquí. Podrás cambiarlo todo más tarde, en la pestaña Artesanos.",
    ["Annoncer aussi mes commandes et ma dispo sur Trade (Services)"] =
        "Anunciar también mis pedidos y mi disponibilidad en Comercio (Servicios)",
    ["Une ligne lisible par tous, seulement quand tu cliques."] = "Una línea que todos pueden leer, solo cuando haces clic.",
    ["Valider"] = "Confirmar",
    -- Icône « une commande t'attend » de la barre de la minicarte (2026-09-28)
    ["Commandes à ton nom : %d"] = "Pedidos a tu nombre: %d",
    ["pour %s"] = "para %s",
    -- 3e tour : le clic vers le perso qui sait faire, les commandes non nommées (2026-09-30)
    ["Pour ta guilde ou tes amis : %d"] = "Para tu hermandad o tus amigos: %d",
    ["Pour tous : %d"] = "Para todos: %d",
    ["Clic : ouvrir %s de %s."] = "Clic: abrir %s de %s.",
    ["Clic : voir pourquoi."] = "Clic: ver por qué.",
    ["Hors combat seulement."] = "Solo fuera de combate.",
    ["Où l'apprendre : %s"] = "Dónde aprenderla: %s",
    ["Aucun de tes persos ne sait faire %s."] = "Ninguno de tus personajes sabe hacer %s.",
    ["%d commandes attendent dans ce métier."] = "%d pedidos esperan en esta profesión.",
    ["Ouvrir la fenêtre de métier"] = "Abrir la ventana de profesión",

    -- Signaler un bug ou une idée (CraftingOrderClassic_Report.lua, 2026-10-07)
    ["Signaler un bug ou proposer une idée"] = "Informar de un error o proponer una idea",
    ["Bug"] = "Error",
    ["Idée"] = "Idea",
    ["Sans compte GitHub"] = "Sin cuenta de GitHub",
    ["Lien copié : colle-le (Ctrl+V) dans ton navigateur."] = "Enlace copiado: pégalo (Ctrl+V) en tu navegador.",
    ["Copie ce lien (Ctrl+C) et ouvre-le dans ton navigateur : le formulaire arrive avec la version déjà remplie."] = "Copia este enlace (Ctrl+C) y ábrelo en tu navegador: el formulario aparece con la versión ya rellenada.",
    ["Pas de compte GitHub ? Copie ce lien (Ctrl+C) et laisse un commentaire sur la page CurseForge."] = "¿Sin cuenta de GitHub? Copia este enlace (Ctrl+C) y deja un comentario en la página de CurseForge.",
    ["Un bug, ou une idée pour l'addon ? Choisis ci-dessous : l'addon te donne le lien du formulaire, déjà rempli."] = "¿Un error o una idea para el addon? Elige abajo: el addon te da el enlace al formulario, ya rellenado.",
    ["signaler un bug ou proposer une idée (lien vers un ticket GitHub)"] = "informar de un error o proponer una idea (enlace a una incidencia de GitHub)",
    -- Le destinataire en une liste, Commande et Récolte (2026-09-30)
    ["Envoyer à"] = "Enviar a",
    ["Liste"] = "Lista",
    ["Tous (avec l'addon)"] = "Todos con el addon",
    ["ou un artisan"] = "o un artesano",
    ["ou un récolteur"] = "o un recolector",
    ["Annoncer en Commerce (en capitale)"] = "Anunciar en Comercio (solo en capitales)",
}

for k, v in pairs(es3) do L[k] = v end
