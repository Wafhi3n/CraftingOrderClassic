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
}

for k, v in pairs(es2) do L[k] = v end
