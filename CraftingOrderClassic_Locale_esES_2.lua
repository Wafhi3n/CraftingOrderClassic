-- CraftingOrderClassic_Locale_esES_2.lua — overlay esES, 2/2. Clé FR → texte traduit.
-- Suite de _Locale_esES.lua, scindé pour rester sous le plafond anti-monolithe (500 l/fichier).
-- Même contrat : chargé APRÈS _Locale.lua, table à plat fusionnée dans COC.L — les deux moitiés
-- sont indépendantes (aucun ordre requis entre elles). Client d'une autre langue : early-return.

local COC = CraftingOrderClassic
local loc = GetLocale and GetLocale() or ""
if loc ~= "esES" and loc ~= "esMX" then return end
local L = COC.L

local es2 = {
    -- Búsqueda de trabajo (LFW) : /co lfw
    ["[Dispo]"] = "[Busca]",
    ["Chercher du travail"] = "Buscar trabajo", ["scan LFW du chat : |cFF33DD33activé|r"] = "escaneo LFW del chat: |cFF33DD33activado|r", ["scan LFW du chat : |cFFFFCC00désactivé|r"] = "escaneo LFW del chat: |cFFFFCC00desactivado|r", ["propose : %s"] = "ofrece: %s", ["Proposer cette recette (recherche de travail)"] = "Ofrecer esta receta (buscar trabajo)", ["Maximum %d recettes proposées."] = "Máximo %d recetas ofrecidas.",
    ["Tu cherches du travail — clic pour arrêter."] = "Estás buscando trabajo — clic para parar.",
    ["Signale au royaume que tu cherches du travail dans ce métier."] = "Avisa al reino que buscas trabajo en esta profesión.",
    ["recherche de travail : |cFF33DD33%s|r — /co lfw off pour arrêter"] = "buscando trabajo: |cFF33DD33%s|r — /co lfw off para parar",
    ["recherche de travail : |cFFFFCC00désactivée|r — /co lfw <métier>"] = "buscando trabajo: |cFFFFCC00desactivado|r — /co lfw <profesión>",
    ["recherche de travail arrêtée."] = "búsqueda de trabajo detenida.",
    ["tu n'as pas le métier %s — impossible de chercher du travail dessus."] = "no tienes %s — no puedes buscar trabajo en ella.",
    ["recherche de travail : |cFF33DD33%s|r — visible au royaume"] = "buscando trabajo: |cFF33DD33%s|r — visible en todo el reino",
    -- Offre LFW (panneau de config par métier + tooltips + tris progression)
    ["Configurer l'offre : composants fournis, commission…"] = "Configura tu oferta: componentes aportados, comisión…",
    ["Recherche de travail — %s"] = "Buscar trabajo — %s",
    ["Je fournis les composants de base"] = "Aporto los componentes básicos",
    ["(achetables chez un marchand)"] = "(los que venden los vendedores)",
    ["Seulement si le plan me fait progresser"] = "Solo si la receta me sube la habilidad",
    ["(restriction sur les composants fournis)"] = "(restricción sobre los componentes aportados)",
    ["Commission fixe par craft :"] = "Comisión fija por fabricación:",
    ["Composants fournis (%d/%d)"] = "Componentes aportados (%d/%d)",
    ["Maximum %d composants fournis."] = "Como máximo %d componentes aportados.",
    ["Cherche du travail : %s"] = "Busca trabajo: %s",
    ["fournit les composants de base (marchand)"] = "aporta los componentes básicos (vendedor)",
    ["fournit : %s"] = "aporta: %s",
    ["commission : %s par craft"] = "comisión: %s por fabricación",
    ["composants fournis seulement si le plan fait progresser"] = "componentes aportados solo si la receta sube la habilidad",
    ["Trier par montée de compétence (plans orange d'abord)."] = "Ordenar por subida de habilidad (recetas naranjas primero).",
    ["Tri par montée de compétence — clic pour A-Z."] = "Ordenado por subida de habilidad — clic para A-Z.",
    ["Par progression"] = "Por subida",
    ["Trier : les commandes qui me font progresser d'abord."] = "Ordenar: primero los pedidos que me suben la habilidad.",
    ["Progression d'abord — clic pour revenir aux récentes."] = "Subidas primero — clic para volver a las recientes.",
    ["|cFF66CCFFamis/partenaires intéressés :|r %s (|cFFFFFFFF/co gift <nom>|r)"] =
        "|cFF66CCFFamigos/socios interesados:|r %s (|cFFFFFFFF/co gift <nombre>|r)",
    ["proposer (chuchoter) le dernier plan looté à un ami/partenaire qui ne le connaît pas"] =
        "ofrecer (susurrar) la última receta saqueada a un amigo/socio que no la conoce",
    ["aucun plan looté en attente de don pour l'instant."] = "ninguna receta saqueada esperando un regalo por ahora.",
    ["don en attente pour |cFFFFFFFF%s|r — amis/partenaires : %s (|cFFFFFFFF/co gift <nom>|r)"] =
        "regalo pendiente para |cFFFFFFFF%s|r — amigos/socios: %s (|cFFFFFFFF/co gift <nombre>|r)",
    ["|cFFFFFFFF%s|r n'est pas dans la liste des amis/partenaires en attente pour ce plan."] =
        "|cFFFFFFFF%s|r no está en la lista de amigos/socios en espera para esta receta.",
    ["Salut ! J'ai looté %s (%s) — tu ne le connais pas encore, ça t'intéresse ?"] =
        "¡Hola! He saqueado %s (%s) — aún no la conoces, ¿te interesa?",
    ["don proposé à |cFFFFFFFF%s|r pour %s."] = "regalo ofrecido a |cFFFFFFFF%s|r por %s.",
    ["|cFF66CCFFtu sais le faire|r — demandé par |cFFFFFFFF%s|r : %s%s%s"] =
        "|cFF66CCFFsabes fabricarlo|r — solicitado por |cFFFFFFFF%s|r: %s%s%s",
    ["%s peut faire une commande captée — gardée pour son passage : %s"] =
        "%s puede fabricar un pedido capturado — guardado para su visita: %s",
    ["Confiées"] = "Confiados", ["Remis"] = "Enviado",
    ["Aucune commande confiée pour l'instant."] = "Ningún pedido confiado por ahora.",
    ["canal : |cFFFFFFFF%s|r"] = "canal: |cFFFFFFFF%s|r",
    ["canal : non rejoint — |cFFFFFFFF/co channel on|r pour réessayer"] =
        "canal: no unido — |cFFFFFFFF/co channel on|r para reintentar",
    ["auto-join du canal réseau désactivé — le carnet global ne fonctionnera plus (whisper/guilde restent actifs)."] =
        "auto-unión al canal de red desactivada — el libro global dejará de funcionar (susurro/hermandad siguen activos).",
    ["canal réseau (re)rejoint."] = "canal de red (re)unido.",
    ["canal global actuel : |cFFFFFFFF%s|r. |cFFFFFFFF/co channel off|r pour le quitter, |cFFFFFFFF/co channel on|r pour le rejoindre."] =
        "canal global actual: |cFFFFFFFF%s|r. |cFFFFFFFF/co channel off|r para salir, |cFFFFFFFF/co channel on|r para volver a unirte.",
    ["(dés)activer le canal réseau global"] = "(des)activar el canal de red global",
    ["balise TEXTE émise=%s (canal idx=%s) — lance |cFFFFFFFF/co trace dump|r sur l'AUTRE perso et cherche |cFFFFFFFF[recv] beacon|r."] =
        "baliza TEXTO enviada=%s (canal idx=%s) — ejecuta |cFFFFFFFF/co trace dump|r en el OTRO personaje y busca |cFFFFFFFF[recv] beacon|r.",
    ["annuaire local vidé (diag) — exécute aussi |cFFFFFFFF/co wipe|r sur l'autre compte pour un test de découverte propre."] =
        "directorio local vaciado (diag) — ejecuta también |cFFFFFFFF/co wipe|r en la otra cuenta para una prueba de descubrimiento limpia.",
    ["Crafting Order rejoint un canal dédié (|cFFFFD100%s|r) pour faire circuler le carnet de commandes entre joueurs de l'addon. Tu le verras dans ta liste de canaux ; aucun message lisible n'y est envoyé. Tu peux le quitter à tout moment — |cFFFFFFFF/co channel off|r."] =
        "Crafting Order se une a un canal dedicado (|cFFFFD100%s|r) para transmitir el libro de pedidos entre usuarios del addon. Lo verás en tu lista de canales; no se envía ningún mensaje legible. Puedes salir en cualquier momento — |cFFFFFFFF/co channel off|r.",
    ["Aide"] = "Ayuda",
    ["C'est quoi Crafting Order ?"] = "¿Qué es Crafting Order?",
    ["Réseau GLOBAL et SOCIAL de commandes de craft — fonctionne sans guilde, entre tous les joueurs de l'addon."] =
        "Red GLOBAL y SOCIAL de pedidos de fabricación — funciona sin hermandad, entre todos los usuarios del addon.",
    ["Poste ce dont tu as besoin, ou consulte les commandes que tu peux honorer avec tes métiers."] =
        "Publica lo que necesitas, o consulta los pedidos que puedes cumplir con tus profesiones.",
    ["Ouvrir la fenêtre et commandes utiles"] = "Abrir la ventana y comandos útiles",
    ["Clic gauche sur l'icône minimap (ou |cFFFFFFFF/co|r) : ouvre cette fenêtre."] =
        "Clic izquierdo en el icono del minimapa (o |cFFFFFFFF/co|r): abre esta ventana.",
    ["Clic droit sur l'icône minimap (ou |cFFFFFFFF/co métier|r) : ouvre la Vue Métier d'un de tes métiers."] =
        "Clic derecho en el icono del minimapa (o |cFFFFFFFF/co métier|r): abre la Vista de Profesión de una de tus profesiones.",
    ["|cFFFFFFFF/co help|r dans le chat : liste complète des commandes slash."] =
        "|cFFFFFFFF/co help|r en el chat: lista completa de comandos slash.",
    ["|cFFFFFFFF/co channel off|r / |cFFFFFFFF/co channel on|r : quitter/rejoindre le canal réseau."] =
        "|cFFFFFFFF/co channel off|r / |cFFFFFFFF/co channel on|r: salir/unirse al canal de red.",
    ["Les 4 onglets de cette fenêtre"] = "Las 4 pestañas de esta ventana",
    ["|cFFE8B84BCarnet|r : tes commandes à toi (postées), en cours ou archivées."] =
        "|cFFE8B84BLibro|r: tus propios pedidos (publicados), activos o archivados.",
    ["|cFFE8B84BCommande|r : poster une demande de craft à faire réaliser par un artisan."] =
        "|cFFE8B84BPedir|r: publicar una solicitud de fabricación para que la cumpla un artesano.",
    ["|cFFE8B84BRécolte|r : poster une demande de matières à un récolteur (mine, herbe, peau, pêche)."] =
        "|cFFE8B84BRecolectar|r: publicar una solicitud de materiales a un recolector (minería, hierbas, cuero, pesca).",
    ["|cFFE8B84BArtisans|r : l'annuaire — qui sait crafter quoi, en ligne ou non."] =
        "|cFFE8B84BArtesanos|r: el directorio — quién sabe fabricar qué, en línea o no.",
    ["Poster une commande de craft"] = "Publicar un pedido de fabricación",
    ["Onglet |cFFE8B84BCommande|r → choisis un métier puis un plan dans la liste."] =
        "Pestaña |cFFE8B84BPedir|r → elige una profesión y luego una receta de la lista.",
    ["Shift-clic un objet dans un sac ou un lien de chat pour le présélectionner s'il correspond à un plan."] =
        "Mayús-clic en un objeto de una bolsa o un enlace de chat para preseleccionarlo si corresponde a una receta.",
    ["Coche les réactifs que TU fournis toi-même (le reste reste à la charge de l'artisan)."] =
        "Marca los reactivos que TÚ aportas (el resto queda a cargo del artesano).",
    ["Choisis la quantité, la commission proposée, puis le destinataire (guilde, amis, un artisan précis, ou diffuser à tous)."] =
        "Elige la cantidad, la comisión ofrecida, y luego el destinatario (hermandad, amigos, un artesano concreto, o difundir a todos).",
    ["Clique |cFFE8B84BPoster|r : la commande apparaît dans ton Carnet et chez les artisans concernés."] =
        "Haz clic en |cFFE8B84BPublicar|r: el pedido aparece en tu Libro y en los artesanos correspondientes.",
    ["Poster une commande de récolte"] = "Publicar un pedido de recolección",
    ["Onglet |cFFE8B84BRécolte|r → choisis un métier de récolte puis une ressource."] =
        "Pestaña |cFFE8B84BRecolectar|r → elige una profesión de recolección y luego un recurso.",
    ["Choisis à l'unité ou par pile, la quantité voulue et le prix proposé, puis le destinataire."] =
        "Elige por unidad o por montón, la cantidad deseada y el precio ofrecido, y luego el destinatario.",
    ["Fonctionne comme une commande de craft, mais ciblée sur les joueurs qui ont le métier de récolte, pas de recette à connaître."] =
        "Funciona como un pedido de fabricación, pero dirigido a jugadores con la profesión de recolección — sin receta necesaria.",
    ["Accepter / livrer une commande — la Vue Métier"] = "Aceptar / entregar un pedido — la Vista de Profesión",
    ["L'acceptation et la livraison ne se font PAS dans le Carnet : ouvre la |cFFE8B84BVue Métier|r du métier concerné (clic droit minimap, ou |cFFFFFFFF/co métier <nom>|r)."] =
        "Aceptar y entregar NO se hacen en el Libro: abre la |cFFE8B84BVista de Profesión|r de la profesión correspondiente (clic derecho minimapa, o |cFFFFFFFF/co métier <nombre>|r).",
    ["La 3ᵉ colonne de la Vue Métier liste toutes les commandes de ce métier : accepte, crafte, puis livre."] =
        "La 3.ª columna de la Vista de Profesión lista todos los pedidos de esa profesión: acepta, fabrica, luego entrega.",
    ["Les demandes captées dans |cFFE8B84B/commerce|r et |cFFE8B84B/guilde|r de joueurs sans l'addon apparaissent aussi ici, marquées « entrante »."] =
        "Las solicitudes capturadas en |cFFE8B84B/comercio|r y |cFFE8B84B/hermandad|r de jugadores sin el addon también aparecen aquí, marcadas como « entrante ».",
    ["Un artisan connu qui sait honorer une commande captée est notifié à sa prochaine connexion (voir « Confiées » dans le Carnet)."] =
        "Un artesano conocido capaz de cumplir un pedido capturado recibe aviso en su próxima conexión (ver « Confiados » en el Libro).",
    ["Le Carnet en détail"] = "El Libro en detalle",
    ["|cFFE8B84BEn cours|r : tes commandes ouvertes ou acceptées par un artisan."] =
        "|cFFE8B84BActivos|r: tus pedidos abiertos o aceptados por un artesano.",
    ["|cFFE8B84BArchivées|r : tes commandes livrées ou annulées."] =
        "|cFFE8B84BArchivados|r: tus pedidos entregados o cancelados.",
    ["|cFFE8B84BConfiées|r : commandes gardées pour un artisan connu capable de les honorer, en attendant qu'il se reconnecte."] =
        "|cFFE8B84BConfiados|r: pedidos guardados para un artesano conocido capaz de cumplirlos, esperando a que vuelva a conectarse.",
    ["Depuis le Carnet, tu peux annuler une commande tant qu'elle n'est pas livrée."] =
        "Desde el Libro, puedes cancelar un pedido mientras no esté entregado.",
    ["Annuaire & social"] = "Directorio y social",
    ["L'onglet Artisans liste les joueurs connus par source : guilde, amis, ajoutés manuellement, croisés récemment."] =
        "La pestaña Artesanos lista los jugadores conocidos por fuente: hermandad, amigos, añadidos manualmente, vistos recientemente.",
    ["Survole un joueur (tooltip) pour voir ses métiers et son niveau de compétence."] =
        "Pasa el cursor sobre un jugador (tooltip) para ver sus profesiones y su nivel de habilidad.",
    ["Clic droit sur un joueur (chat, groupe...) pour l'ajouter à ton annuaire — utile pour le retrouver même hors ligne."] =
        "Clic derecho en un jugador (chat, grupo...) para añadirlo a tu directorio — útil para reencontrarlo incluso desconectado.",
    ["Pastille verte : il a l'addon et répond. Jaune : en ligne sans l'addon. Grise : hors ligne."] =
        "Punto verde: tiene el addon y responde. Amarillo: en línea sin el addon. Gris: desconectado.",
    ["Réseau, confidentialité & statuts"] = "Red, privacidad y estados",
    ["L'addon rejoint un canal dédié pour faire circuler le carnet entre joueurs de l'addon — aucun message lisible n'y est envoyé."] =
        "El addon se une a un canal dedicado para transmitir el libro entre usuarios del addon — no se envía ningún mensaje legible.",
    ["|cFFFFFFFF/co channel off|r le quitte à tout moment (whisper et guilde restent actifs) ; |cFFFFFFFF/co channel on|r le rejoint."] =
        "|cFFFFFFFF/co channel off|r sale en cualquier momento (susurro y hermandad siguen activos); |cFFFFFFFF/co channel on|r vuelve a unirse.",
    ["Statuts d'une commande : "] = "Estados de un pedido: ",

    -- Aide contextuelle « bouton i » (Vue Métier) — cf. _ProfWindow_HelpPlate.lua (bulles courtes)
    ["Aide : survole les zones surlignées pour comprendre chaque fonction."] =
        "Ayuda: pasa el ratón por las zonas resaltadas para entender cada función.",
    ["Barre de filtres. À gauche (avec Lazy Gold) : pièce = trier par rentabilité, « 123 » = prix exacts au lieu de l'indicateur compact, flèche verte = trier par montée de compétence, carte = plan de route (quoi crafter jusqu'au plafond, au moins cher). Au centre : la recherche. À droite : sac = seulement les recettes dont tu as les matériaux, flèche orange = masquer les recettes grises (aucun gain de compétence)."] =
        "Barra de filtros. A la izquierda (con Lazy Gold): moneda = ordenar por rentabilidad, «123» = precios exactos en vez del indicador compacto, flecha verde = ordenar por subida de habilidad, mapa = ruta de subida (qué fabricar hasta el tope, al menor coste). En el centro: la búsqueda. A la derecha: bolsa = solo las recetas de las que tienes los materiales, flecha naranja = ocultar las recetas grises (sin ganancia de habilidad).",
    ["Tes recettes, groupées par famille (clique un en-tête pour replier). À droite de chaque ligne : %s = rentabilité à l'HV (survole pour le profit net exact), %s = plan conseillé pour monter le métier (meilleur coût par point), « ×N » doré = commandes en attente pour cet objet. En mode Manquantes, une icône dit où obtenir le plan : formateur, vendeur, HV ou à farmer."] =
        "Tus recetas, agrupadas por familia (haz clic en una cabecera para plegar). A la derecha de cada línea: %s = rentabilidad en la CdS (pasa el ratón para el beneficio neto exacto), %s = receta recomendada para subir de nivel (mejor coste por punto), «×N» dorado = pedidos pendientes de ese objeto. En modo Faltantes, un icono indica dónde conseguir el plano: entrenador, vendedor, CdS o farmear.",
    ["Le plan sélectionné : ses réactifs et le bouton pour le fabriquer."] =
        "La receta seleccionada: sus componentes y el botón para fabricarla.",
    ["Les commandes reçues pour ce métier — accepte, crafte, livre. Les onglets filtrent la source (tous / guilde / amis / annuaire)."] =
        "Los pedidos recibidos para esta profesión: acepta, fabrica, entrega. Las pestañas filtran la fuente (todos / hermandad / amigos / directorio).",
    ["Chercher du travail : signale au royaume que tu proposes ce métier. L'engrenage voisin règle ton offre (composants fournis, commission)."] =
        "Buscar trabajo: anuncia al reino que ofreces esta profesión. El engranaje contiguo configura tu oferta (componentes aportados, comisión).",
    ["Vue Blizzard : rebascule sur la fenêtre de métier native de Blizzard."] =
        "Vista Blizzard: vuelve a la ventana de profesión nativa de Blizzard.",
    ["Filtre les commandes par source : tous, ta guilde, tes amis, ou ton annuaire d'artisans."] =
        "Filtra los pedidos por fuente: todos, tu hermandad, tus amigos o tu directorio de artesanos.",

    -- Aide contextuelle « bouton i » — onglet Commande (cf. _UI_HelpPlate.lua)
    ["Filtre les plans : recherche par nom, filtre par qualité, filtre par réactif, et l'outil %s « 123 » de Lazy Gold (prix/rentabilité)."] =
        "Filtra las recetas: búsqueda por nombre, filtro por calidad, filtro por componente y la herramienta %s «123» de Lazy Gold (precio/rentabilidad).",
    ["La liste des plans. Choisis celui que tu veux faire réaliser par un artisan."] =
        "La lista de recetas. Elige la que quieres que fabrique un artesano.",
    ["L'objet choisi. La pastille « Je fournis » indique que tu apportes tous les composants toi-même."] =
        "El objeto elegido. La insignia «Yo aporto» indica que llevas todos los componentes tú mismo.",
    ["La commission que tu proposes à l'artisan pour ce craft."] =
        "La comisión que ofreces al artesano por esta fabricación.",
    ["La portée : diffuser à tous, ou restreindre (guilde / amis)."] =
        "El alcance: difundir a todos o restringir (hermandad / amigos).",
    ["Le destinataire : toute la source sélectionnée, ou un artisan précis."] =
        "El destinatario: toda la fuente seleccionada o un artesano concreto.",
    ["Poster : envoie la commande au(x) destinataire(s) choisi(s)."] =
        "Publicar: envía el pedido a los destinatarios elegidos.",

    -- Aide contextuelle « bouton i » — onglet Récolte (cf. _UI_HelpPlate.lua)
    ["Recherche une ressource par nom."] = "Busca un recurso por nombre.",
    ["Extensions : filtre les ressources d'une extension (ex. Élémentaire)."] =
        "Expansiones: filtra los recursos de una expansión (p. ej. Elemental).",
    ["La liste des ressources. Choisis celle que tu veux faire récolter."] =
        "La lista de recursos. Elige el que quieres que recolecten.",
    ["La ressource choisie."] = "El recurso elegido.",
    ["À l'unité ou par pile, et la quantité voulue."] = "Por unidad o por montón, y la cantidad deseada.",
    ["Le prix que tu proposes au récolteur."] = "El precio que ofreces al recolector.",
    ["Le destinataire : toute la source, ou un récolteur précis."] =
        "El destinatario: toda la fuente o un recolector concreto.",

    -- Aide contextuelle « bouton i » — onglet Artisans (cf. _UI_HelpPlate.lua)
    ["Filtre l'annuaire par source : guilde, amis, ajoutés manuellement, croisés, ou les joueurs en sourdine."] =
        "Filtra el directorio por fuente: hermandad, amigos, añadidos manualmente, encontrados recientemente, o jugadores silenciados.",
    ["Ajoute un joueur manuellement (+), rafraîchis l'annuaire, ou active le repérage."] =
        "Añade un jugador manualmente (+), actualiza el directorio o activa el rastreo.",
    ["Filtre les artisans par métier."] = "Filtra los artesanos por profesión.",
    ["La liste des artisans connus. Survole un nom pour ses métiers ; pastille verte = a l'addon et répond, jaune = en ligne sans l'addon, grise = hors ligne."] =
        "La lista de artesanos conocidos. Pasa el ratón por un nombre para ver sus profesiones; punto verde = tiene el addon y responde, amarillo = en línea sin el addon, gris = desconectado.",

    -- Aide contextuelle « bouton i » — onglet Mes artisans (cf. _UI_HelpPlate.lua)
    ["Partage tes rerolls sur le réseau (les autres voient tes métiers), et choisis le perso mis en « vitrine »."] =
        "Comparte tus alters en la red (los demás ven tus profesiones) y elige el personaje en «escaparate».",
    ["Tous les plans du royaume : la liste agrégée de toutes tes recettes, au lieu du découpage par métier (Lazy Gold requis)."] =
        "Todos los planos del reino: la lista agregada de todas tus recetas, en vez de la división por profesión (requiere Lazy Gold).",
    ["Tes métiers (tous les persos du compte). Choisis-en un pour voir ses recettes à droite."] =
        "Tus profesiones (todos los personajes de la cuenta). Elige una para ver sus recetas a la derecha.",
    ["En-tête des recettes du métier choisi : bouton « Manquantes » et outils de prix (Lazy Gold)."] =
        "Cabecera de las recetas de la profesión elegida: botón «Faltantes» y herramientas de precio (Lazy Gold).",
    ["Les recettes du métier sélectionné (ou tous les plans du royaume)."] =
        "Las recetas de la profesión seleccionada (o todos los planos del reino).",

    -- Aide contextuelle « bouton i » — onglet Carnet (cf. _UI_HelpPlate.lua)
    ["Filtre ton carnet : commandes En cours, Archivées, ou Confiées (gardées pour un artisan)."] =
        "Filtra tu libro: pedidos Activos, Archivados o Confiados (guardados para un artesano).",
    ["Le Carnet = TES commandes postées. Accepter/livrer se fait dans la Vue Métier, pas ici ; quand une commande t'est remise, le bouton « J'ai reçu » confirme la réception."] =
        "El Libro = TUS pedidos publicados. Aceptar/entregar se hace en la Vista de Profesión, no aquí; cuando te entregan un pedido, el botón «Recibido» confirma la recepción.",

    -- Popup dépendance optionnelle manquante (boutons Lazy Gold / MTSL toujours visibles)
    ["Cette fonction nécessite l'addon |cFFFFD100%s|r (non installé ou désactivé). Installe-le pour en profiter."] =
        "Esta función necesita el addon |cFFFFD100%s|r (no instalado o desactivado). Instálalo para usarla.",

    -- Sous-catégories de recettes (vue métier) — voir _RecipeCats_*.lua
    ["Divers"] = "Varios",
    ["Potions de soin"] = "Pociones de curación",
    ["Potions de mana"] = "Pociones de maná",
    ["Flacons"] = "Frascos",
    ["Élixirs de force"] = "Elixires de fuerza",
    ["Élixirs d'agilité"] = "Elixires de agilidad",
    ["Élixirs d'endurance"] = "Elixires de aguante",
    ["Élixirs de défense"] = "Elixires de defensa",
    ["Élixirs d'esprit"] = "Elixires de intelecto y espíritu",
    ["Élixirs de puissance des sorts"] = "Elixires de poder de hechizos",
    ["Élixirs de puissance d'attaque"] = "Elixires de poder de ataque",
    ["Élixirs de vision"] = "Elixires de visión",
    ["Potions de protection"] = "Pociones de protección",
    ["Potions de combat"] = "Pociones de combate",
    ["Potions de régénération"] = "Pociones de regeneración",
    ["Potions utilitaires"] = "Pociones utilitarias",
    ["Huiles"] = "Aceites",
    ["Transmutations"] = "Transmutaciones",
    ["Minerais"] = "Minerales",
    ["Lingots"] = "Lingotes",
    ["Cuirs"] = "Cuero",
    ["Éclats"] = "Esquirlas",
    ["Essences"] = "Esencias",
    ["Poussières"] = "Polvo",
    -- ⚠️ Clés DYNAMIQUES (L[group.name] dans RecipeCats) : le checker ne les voit pas — tenir cette
    -- liste alignée sur les `name =` des _RecipeCats_*.lua à chaque régénération (bug live sosh13).
    ["Peaux"] = "Pieles",
    ["Écailles"] = "Escamas",
    ["Herbes"] = "Hierbas",
    ["Poissons"] = "Peces",

    -- Sous-catégories d'ENCHANTEMENT (clés DYNAMIQUES : STAT_L dans _Enchant.lua). Ce sont les seules
    -- stats de base dont le libellé ne se lit pas sur le client — toutes les autres viennent de
    -- GetSpellInfo, donc déjà traduites par Blizzard. Ne pas allonger cette liste sans raison.
    ["Absorption"] = "Absorción",
    ["Résistance aux Arcanes"] = "Resistencia a lo Arcano",
    ["Armure"] = "Armadura",
    ["Tueur de bêtes"] = "Matabestias",
    ["Soins"] = "Sanación",
    ["Résistance à la Nature"] = "Resistencia a la Naturaleza",
    ["Protection"] = "Protección",
    ["Résistance à l'Ombre"] = "Resistencia a las Sombras",

    -- Pont MissingTradeSkillsList (recettes manquantes + source)
    ["Manquantes"] = "Faltantes",
    ["Manquantes (%d)"] = "Faltantes (%d)",
    ["‹ Apprises seules"] = "‹ Solo aprendidas",
    ["Masque les recettes non apprises — clic pour revenir."] = "Oculta las recetas no aprendidas — clic para volver.",
    ["Affiche AUSSI les recettes non apprises (en rouge) et où les obtenir."] = "Muestra también las recetas no aprendidas (en rojo) y dónde conseguirlas.",
    ["niveau"] = "nivel",
    ["niv."] = "niv.",
    ["Non apprise"] = "No aprendida",
    ["Où l'obtenir"] = "Dónde conseguirla",
    ["Niveau requis"] = "Nivel requerido",
    ["Obtenu via"] = "Obtenida vía",
    ["Prix"] = "Precio",
    ["Appris de"] = "Aprendida de",
    ["Vendeur"] = "Vendedor",
    ["Vendu par"] = "Vendida por",
    ["Butin sur"] = "Botín de",
    ["Formateurs"] = "Instructores",
    ["Formateur"] = "Instructor",
    ["Réputation"] = "Reputación",
    ["Quête"] = "Misión",
    ["Butin"] = "Botín",
    ["Source inconnue"] = "Fuente desconocida",

    -- Pont Lazy Gold (rentabilité)
    ["Rentabilité"] = "Rentabilidad",
    ["Vente HV"] = "Venta CS",
    ["Profit net"] = "Beneficio neto",
    ["Valeur HV"] = "Valor CS",
    ["Par rentabilité"] = "Por beneficio",
    ["Meilleur plan"] = "Mejor plan",
    ["Tous les plans du royaume"] = "Todos los planos del reino",
    ["%d métiers"] = "%d profesiones",
    ["À ma charge"] = "A mi cargo",
    ["Valeurs exactes — clic pour l'affichage compact."] = "Valores exactos — clic para vista compacta.",
    ["Afficher les valeurs exactes (po/pa/pc)."] = "Mostrar valores exactos (o/p/c).",
    ["Clic : commander ce métier"] = "Clic: encargar esta profesión",
    ["Trier par rentabilité (Lazy Gold)."] = "Ordenar por rentabilidad (Lazy Gold).",
    ["Tri par rentabilité — clic pour A-Z."] = "Ordenado por beneficio — clic para A-Z.",
    ["N'afficher que les recettes dont j'ai les matériaux."] = "Mostrar solo las recetas para las que tienes materiales.",
    ["Filtre matériaux actif — clic pour tout afficher."] = "Filtro de materiales activo — clic para mostrar todo.",
    ["N'afficher que les recettes qui font monter la compétence (masque le gris)."] = "Mostrar solo las recetas que suben la habilidad (oculta el gris).",
    ["Filtre progression actif — clic pour tout afficher."] = "Filtro de progreso activo — clic para mostrar todo.",
    ["N'afficher que les recettes acquérables (formateur, vendeur ou HV)."] = "Mostrar solo las recetas obtenibles (entrenador, vendedor o casa de subastas).",
    ["Filtre acquérables actif — clic pour tout afficher."] = "Filtro de obtenibles activo — clic para mostrar todo.",
    ["Acheter à l'HV"] = "Comprar en la casa de subastas",
    -- Diffuser les réactifs (liste de courses)
    ["Diffuser les réactifs"] = "Difundir los reactivos",
    ["Diffuser les réactifs dans un canal"] = "Difundir los reactivos en un canal",
    ["Canal : "] = "Canal: ",
    ["Dire"] = "Decir", ["Groupe"] = "Grupo", ["Raid"] = "Banda", ["Envoyer"] = "Enviar",
    ["Réactifs pour %s :"] = "Reactivos para %s:",
    ["Réactifs pour %s (%d) :"] = "Reactivos para %s (%d):",
    ["choisis un canal valide."] = "elige un canal válido.",
    ["aucun réactif à diffuser."] = "no hay reactivos que difundir.", ["Diffuser"] = "Difundir",
    -- Aide à la montée de métier (Leveling)
    ["Progression : ~%s par point (estimation)"] = "Progresión: ~%s por punto (estimación)",
    ["Meilleur coût/point pour monter le métier"] = "Mejor coste por punto para subir el oficio",
    ["Plan : au formateur%s"] = "Receta: en el instructor%s",
    ["Plan : chez un vendeur PNJ%s"] = "Receta: en un vendedor PNJ%s",
    ["Plan : coté à l'HV — %s"] = "Receta: en la casa de subastas — %s",
    ["Plan : à farmer (butin/quête — absent de l'HV)"] = "Receta: a farmear (botín/misión — no está en la subasta)",
    -- Plan de route (montée de métier)
    ["Plan de route"] = "Ruta de subida",
    ["Plan de route : quoi crafter pour monter au moins cher."] = "Ruta de subida: qué fabricar para subir al menor coste.",
    ["Rang %s"] = "Rango %s",
    ["En tête : rang actuel, plafond entraînable, et coût total estimé (« > » = des rangs sans recette calculable, total incomplet)."] =
        "Arriba: rango actual, tope entrenable y el coste total estimado («>» = algunos rangos no tienen receta calculable, el total está incompleto).",
    ["Un segment par ligne : plage de rangs, recette au meilleur coût par point espéré, « ×~N » = crafts attendus, et le coût du segment (parchemin = plan à acheter d'abord, compté dedans). Survole une ligne pour le détail. La route se recalcule à chaque point gagné."] =
        "Un tramo por línea: rango, la receta con el mejor coste esperado por punto, «×~N» = fabricaciones esperadas, y el coste del tramo (pergamino = receta a comprar primero, incluida). Pasa el ratón por una línea para el detalle. La ruta se recalcula con cada punto ganado.",
    ["Total estimé : %s"] = "Total estimado: %s",
    ["Rang au plafond — vois le formateur pour débloquer la suite."] = "Rango al máximo — visita a tu instructor para desbloquear más.",
    ["aucune recette calculable"] = "ninguna receta calculable",
    ["Estimation : chance de point par couleur, prix du dernier scan HV (Lazy Gold)."] = "Estimación: probabilidad de punto por color, precios del último escaneo de la subasta (Lazy Gold).",
    ["Rien à calculer — scanne l'HV (Auctionator) puis rouvre ce panneau."] = "Nada que calcular — escanea la casa de subastas (Auctionator) y vuelve a abrir este panel.",
    ["Crafts attendus : ~%d"] = "Fabricaciones esperadas: ~%d",
    ["Réactifs (espéré)"] = "Componentes (esperado)",
    ["Plan à acheter"] = "Receta a comprar",
    ["Aucune recette calculable sur ce segment (prix HV manquants, ou plans introuvables)."] = "Ninguna receta calculable en este tramo (faltan precios de la subasta o recetas inaccesibles).",
    ["Monter son métier au meilleur prix"] = "Sube tu oficio al menor coste",
    ["Dans la Vue Métier, la flèche verte trie par montée de compétence : les plans qui rapportent un point d'abord, les moins chers en tête (prix Lazy Gold)."] =
        "En la Vista de oficio, la flecha verde ordena por subida de habilidad: primero las recetas que dan un punto, las más baratas arriba (precios de Lazy Gold).",
    ["Le badge doré marque le meilleur coût par point ; les plans utiles non appris s'affichent aussi, avec où les obtenir (formateur, vendeur, HV, à farmer)."] =
        "La insignia dorada marca el mejor coste por punto; las recetas útiles no aprendidas también aparecen, con dónde conseguirlas (instructor, vendedor, subasta, farmeo).",
    ["Le bouton carte ouvre le |cFFE8B84BPlan de route|r : du rang actuel au plafond, quoi crafter, combien de fois, pour quel coût total estimé — recalculé à chaque point gagné."] =
        "El botón mapa abre la |cFFE8B84BRuta de subida|r: de tu rango actual al tope, qué fabricar, cuántas veces y por qué coste total estimado — recalculado con cada punto ganado.",
    ["Tout repose sur les prix du dernier scan Auctionator (addons Lazy Gold + Auctionator conseillés) : sans eux, ces aides s'effacent."] =
        "Todo se basa en los precios del último escaneo de Auctionator (addons Lazy Gold + Auctionator recomendados): sin ellos, estas ayudas se ocultan.",

    -- Bourse d'artisan (onglet Artisans)
    ["Bourse d'artisan"] = "Bolsa del artesano",
    ["Clic : les fournitures qu'il lui faut pour monter ses métiers (prix Lazy Gold)."] =
        "Clic: los suministros que necesita para subir sus oficios (precios de Lazy Gold).",
    ["Bourse — %s"] = "Bolsa — %s",
    ["Rien à fournir — métiers au plafond, ou données trop anciennes."] = "Nada que suministrar — oficios al tope, o datos demasiado antiguos.",
    ["Inclure les plans à acheter"] = "Incluir las recetas por comprar",
    ["Les plans-objets s'ajoutent aux fournitures ; les plans « au formateur » restent à apprendre chez le PNJ."] =
        "Los objetos-receta se suman a los suministros; las recetas de instructor deberá aprenderlas con el PNJ.",
    ["Requis : ×%d"] = "Necesario: ×%d",
    ["Plan à fournir (il ne le connaît pas encore)"] = "Receta por suministrar (aún no la conoce)",
    ["Au formateur : %s"] = "Con el instructor: %s",
    ["Chez un PNJ (inutile de fournir) : %s"] = "En un vendedor PNJ (no hace falta suministrar): %s",
    ["Fournitures (agrégées)"] = "Suministros (agregados)",
    ["Clic : poser un repère sur ce PNJ (TomTom ou épingle de carte)."] = "Clic: coloca un punto de ruta en este PNJ (TomTom o marcador del mapa).",
    ["zone introuvable sur la carte : %s"] = "zona no encontrada en el mapa: %s",
    ["repère posé : %s — %s (%.0f, %.0f)"] = "punto de ruta colocado: %s — %s (%.0f, %.0f)",
    ["Route incomplète : %d rang(s) sans recette calculable (prix HV manquants)."] =
        "Ruta incompleta: %d rango(s) sin receta calculable (faltan precios de subasta).",
    ["Coche « Inclure les plans à acheter » pour en combler une partie."] =
        "Marca «Incluir las recetas por comprar» para cubrir una parte.",
    ["Coût partiel : au moins un réactif sans prix HV."] = "Coste parcial: al menos un componente sin precio de subasta.",
    ["Désenchanter : objets %s, niv. d'objet %d-%d (estimation)"] = "Desencantar: objetos %s, nivel de objeto %d-%d (estimación)",
    -- Échange enchanteur, étage 2 : invite un-clic côté client
    ["%s propose d'enchanter : %s. Poser la pièce dans l'emplacement « ne sera pas échangé » ? Rien n'est donné — tu la récupères enchantée."] =
        "%s ofrece encantar: %s. ¿Poner la pieza en la casilla «No se intercambiará»? No entregas nada — la recuperas encantada.",
    ["Poser la pièce"] = "Poner la pieza",
    ["Ignorer"] = "Ignorar",
}

for k, v in pairs(es2) do L[k] = v end
