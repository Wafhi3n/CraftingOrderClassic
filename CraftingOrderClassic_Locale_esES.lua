-- CraftingOrderClassic_Locale_esES.lua — overlay ESPAGNOL (esES/esMX). Clé FR → texte ES.
-- Chargé APRÈS CraftingOrderClassic_Locale.lua (qui crée COC.L via setmetatable). Repli sur la clé FR
-- pour toute chaîne non traduite. Guillemets « » dans les valeurs → évite l'échappement Lua des ".
-- Sur un client non-hispanophone : early-return, coût nul.

local COC = CraftingOrderClassic
local loc = GetLocale and GetLocale() or ""
if loc ~= "esES" and loc ~= "esMX" then return end
local L = COC.L

local es = {
    -- Onglets / fenêtre
    ["Carnet"] = "Libro", ["Commande"] = "Pedir", ["Récolte"] = "Recolectar", ["Artisans"] = "Artesanos",
    ["Classic · canal global"] = "Classic · canal global",
    -- En-têtes de colonnes (Carnet)
    ["COMMANDE"] = "PEDIDO", ["QTÉ"] = "CANT.", ["PRIX PROPOSÉ"] = "PRECIO OFRECIDO",
    ["MÉTIER"] = "PROFESIÓN", ["STATUT"] = "ESTADO",
    ["ARTISAN"] = "ARTESANO",
    -- Filtres Carnet
    ["Tous"] = "Todos", ["Guilde"] = "Hermandad", ["Amis"] = "Amigos",
    ["Annuaire"] = "Directorio",
    ["Rafraîchir l'annuaire"] = "Actualizar directorio",
    ["annuaire : appel lancé sur le canal — les porteurs en ligne vont répondre."] =
        "directorio: llamada enviada al canal — los usuarios en línea responderán.",
    ["Survole un ami dans la liste d'amis, ou sélectionne un membre dans le panneau de guilde : ses métiers primaires s'affichent sans ouvrir cette fenêtre."] =
        "Pasa el cursor sobre un amigo en la lista de amigos, o selecciona un miembro en el panel de hermandad: sus profesiones principales se muestran sin abrir esta ventana.",
    ["Clic droit sur un joueur qui a l'addon (ami, guilde, croisé) : « Passer commande à… » ouvre l'onglet Commande déjà ciblé sur lui."] =
        "Clic derecho sobre un jugador que tiene el addon (amigo, hermandad, visto): « Pedir a… » abre la pestaña Pedir ya dirigida a él.",
    ["« Met » devient « Annuaire ». Le bouton « Rafraîchir l'annuaire » appelle le canal : tous les porteurs en ligne répondent et s'y ajoutent."] =
        "« Vistos » pasa a « Directorio ». El botón « Actualizar directorio » llama al canal: todos los usuarios en línea responden y se añaden.",
    -- Onglet Nouveautés (changelog en jeu)
    ["Nouveautés"] = "Novedades",
    ["Repérer les crafteurs sans l'addon + passe de performance"] = "Detectar artesanos sin el addon + mejoras de rendimiento",
    ["Repérage passif des crafteurs autour de toi, même sans l'addon (onglet Artisans → « Repérer les crafteurs autour », ou |cFFFFFFFF/co crafters on|r). Désactivé par défaut, en ville seulement."] =
        "Detección pasiva de artesanos a tu alrededor, incluso sin el addon (pestaña Artesanos, o |cFFFFFFFF/co crafters on|r). Desactivado por defecto, solo en ciudad.",
    ["Liste de plans de l'onglet Commande réécrite : plus fluide sur les métiers à centaines de recettes (Couture)."] =
        "Lista de recetas de la pestaña Pedir reescrita: más fluida en profesiones con cientos de recetas (Sastrería).",
    ["La fenêtre ne se redessine plus à chaque message réseau : les rafales sont regroupées en un seul rendu."] =
        "La ventana ya no se redibuja con cada mensaje de red: las ráfagas se agrupan en un solo dibujado.",
    ["Protocole de commande durci : un autre client ne peut plus annuler ta commande, usurper une acceptation, ni s'attribuer une livraison."] =
        "Protocolo de pedidos reforzado: otro cliente ya no puede cancelar tu pedido, falsear una aceptación ni atribuirse una entrega.",
    ["Commander depuis les panneaux Amis & Guilde"] = "Pedir desde los paneles Amigos y Hermandad",
    ["Greffons échange & courrier, dock en vue Blizzard"] = "Complementos de intercambio y correo, anclaje en vista Blizzard",
    ["Panneaux compagnons sur la fenêtre d'échange et de courrier pour livrer une commande sans ouvrir le carnet."] =
        "Paneles complementarios en la ventana de intercambio y correo para entregar un pedido sin abrir el libro.",
    ["La colonne Commandes peut s'ancrer à droite de la fenêtre métier native (vue Blizzard)."] =
        "La columna Pedidos puede anclarse a la derecha de la ventana de profesión nativa (vista Blizzard).",
    ["Sous le capot : mises à jour plus sûres"] = "Bajo el capó: actualizaciones más seguras",
    ["Tes données sauvegardées portent désormais une version : une mise à jour qui doit les réorganiser ne tourne qu'une fois, tes recettes et commandes restent intactes."] =
        "Tus datos guardados ahora llevan una versión, así que una actualización que deba reorganizarlos se ejecuta una sola vez y tus recetas y pedidos quedan intactos.",
    ["Protocole de commandes consolidé (mêmes échanges réseau) : ce build reste compatible avec les joueurs encore en 1.7.x."] =
        "El protocolo de pedidos se consolidó (mismos intercambios de red); esta versión sigue entendiéndose con jugadores en 1.7.x.",
    ["Alertes de plan looté qui te concernent"] = "Alertas de receta saqueada que te conciernen",
    ["L'alerte de plan looté ne se déclenche plus que s'il te concerne : tu as le métier et peux l'apprendre, ou un ami/partenaire de ton annuaire ne le connaît pas encore."] =
        "La alerta de receta saqueada ya solo salta cuando te concierne: tienes la profesión y puedes aprenderla, o un amigo/socio de tu directorio aún no la conoce.",
    ["Les candidats au don incluent désormais tes amis, pas seulement les partenaires marqués — l'alerte « intéressés » et |cFFFFFFFF/co gift|r touchent tout ton annuaire."] =
        "Los candidatos a regalo ahora incluyen a tus amigos, no solo a los socios marcados — la alerta « interesados » y |cFFFFFFFF/co gift|r llegan a todo tu directorio.",
    ["Amis Battle.net + commande par métier"] = "Amigos de Battle.net + pedido por profesión",
    ["Les métiers et le menu Crafting Order fonctionnent maintenant sur les amis Battle.net, pas seulement les amis ajoutés par personnage."] =
        "Las profesiones y el menú de Crafting Order ahora funcionan con amigos de Battle.net, no solo con amigos añadidos por personaje.",
    ["Clic droit sur un artisan : une entrée « Passer commande » par métier, qui ouvre l'onglet Commande déjà réglé sur ce métier."] =
        "Clic derecho en un artesano: una entrada « Pedir » por profesión, que abre la pestaña Pedido ya ajustada a esa profesión.",
    ["Le résumé d'un artisan indique la profondeur de son carnet (« · N plans ») ; maintiens Maj sur son infobulle en jeu pour lister ses recettes connues."] =
        "El resumen de un artesano indica la amplitud de su recetario (« · N recetas »); mantén Mayús sobre su información en el mundo para listar las recetas que conoce.",
    ["Correctif : un personnage n'affiche plus par erreur les métiers de ses rerolls dans ton annuaire."] =
        "Corrección: un personaje ya no muestra por error las profesiones de sus alts en tu directorio.",
    ["Allemand et espagnol + onglet Nouveautés"] = "Alemán y español + pestaña Novedades",
    ["L'interface se traduit en allemand et en espagnol selon la langue de ton client WoW."] =
        "La interfaz se traduce al alemán y al español según el idioma de tu cliente de WoW.",
    ["Ce nouvel onglet « Nouveautés » affiche les notes de version directement en jeu."] =
        "Esta nueva pestaña « Novedades » muestra las notas de versión directamente en el juego.",
    -- Onglet Nouveautés — v1.12.0
    ["Les recettes de la Saison de la Découverte"] = "Recetas de la Temporada de Descubrimientos",
    ["304 recettes de la Saison de la Découverte entrent au catalogue : 80 en Travail du cuir, 65 en Forge, 57 en Couture, 48 en Enchantement, 29 en Ingénierie, 16 en Alchimie, plus la Cuisine, le Secourisme et le Minage. Elles apparaissent dans l'onglet Commande, avec leurs réactifs et leur palier d'apprentissage."] =
        "304 recetas de la Temporada de Descubrimientos entran en el catálogo: 80 de Peletería, 65 de Herrería, 57 de Sastrería, 48 de Encantamiento, 29 de Ingeniería, 16 de Alquimia, más Cocina, Primeros auxilios y Minería. Aparecen en la pestaña Pedido, con sus reactivos y su nivel de aprendizaje.",
    ["Elles ne se chargent que sur un royaume Saison de la Découverte. Sur un royaume Era classique, rien ne change : l'addon voit exactement le même jeu de recettes qu'avant, et les recettes que tes amis t'ont déjà partagées restent lisibles."] =
        "Solo se cargan en un reino de la Temporada de Descubrimientos. En un reino Era normal no cambia nada: el addon ve exactamente el mismo conjunto de recetas que antes, y las recetas que tus amigos ya te compartieron siguen siendo legibles.",
    -- Onglet Nouveautés — v1.11.0
    ["Annuler une commande publique atteint tout le royaume"] = "Cancelar un pedido público ahora llega a todo el reino",
    ["Une commande publique voyage sur le canal du royaume depuis la v1.10.0, mais pas son annulation : un artisan que tu n'as jamais croisé la voyait « ouverte » pendant six heures, l'acceptait, et farmait les réactifs pour rien. L'annulation part désormais sur le même canal."] =
        "Un pedido público viaja por el canal del reino desde la v1.10.0, pero su cancelación no. Un artesano que nunca has cruzado lo veía « abierto » durante seis horas, lo aceptaba y reunía los reactivos para nada. La cancelación sale ahora por el mismo canal.",
    ["Poster et annuler ne perdent plus de messages. Le canal exige un clic ou une touche et n'accepte qu'une ligne par seconde : un |cFFFFFFFF/co post|r tapé au chat, ou deux commandes postées dans la même seconde, disparaissaient sans trace. Ces lignes patientent maintenant dans une file et partent à ton prochain clic."] =
        "Publicar y cancelar ya no pierden mensajes. El canal necesita un clic o una tecla para llevar una línea, y acepta una línea por segundo: un |cFFFFFFFF/co post|r escrito en el chat, o dos pedidos publicados en el mismo segundo, desaparecían sin rastro. Esas líneas ahora esperan en una cola y salen en tu siguiente clic.",
    ["Seules les commandes NOUVELLES et les ANNULATIONS voyagent sur le canal, et seulement les publiques. Guilde, amis et commandes nommées restent privées ; les acceptations restent entre les deux joueurs concernés."] =
        "Solo los pedidos NUEVOS y las CANCELACIONES viajan por el canal, y solo los públicos. Los pedidos de hermandad, de amigos y con destinatario siguen siendo privados; las aceptaciones quedan entre los dos jugadores implicados.",
    -- Onglet Nouveautés — v1.10.2
    ["Correctif : erreur en combat dans la vue métier"] = "Corrección: un error en combate en la vista de profesión",
    ["Sélectionner une recette pendant un combat ne provoque plus d'erreur bloquée : le bouton « Créer » est un bouton sécurisé, que le jeu interdit de masquer en plein combat. L'addon attend maintenant la fin du combat pour l'afficher ou le masquer."] =
        "Seleccionar una receta durante el combate ya no provoca un error bloqueado. El botón Crear es un botón seguro, y el juego prohíbe ocultarlo en pleno combate. El addon espera ahora al final del combate para mostrarlo u ocultarlo.",
    -- Onglet Nouveautés — v1.10.1
    ["Corrections : qui reçoit les alertes de commandes"] = "Correcciones: quién recibe los avisos de pedidos",
    ["Les alertes de commandes ne dépendent plus du réglage |cFFFFFFFF/co scan|r : le scanner de chat et le carnet partageaient une option par erreur. Une commande publique te prévient désormais dès que tu as le métier."] =
        "Los avisos de pedidos ya no dependen de tu ajuste |cFFFFFFFF/co scan|r. El escáner de chat y el libro de pedidos compartían una opción por error. Un pedido público te avisa ahora en cuanto tienes la profesión.",
    ["Une commande publique portant un objet absent du catalogue arrivait en silence : elle te prévient maintenant, au lieu de dormir dans le carnet."] =
        "Un pedido público con un objeto ausente del catálogo llegaba en silencio. Ahora te avisa, en lugar de quedarse sin ver en el libro.",
    ["Démuter un joueur réarme la détection de spam le concernant ; revenir de la vue métier d'un reroll ne laisse plus les boutons Créer masqués ; et l'addon travaille nettement moins à chaque ligne de chat sur un royaume chargé."] =
        "Reactivar a un jugador silenciado rearma la detección de spam para él; volver de la vista de profesión de un alter ya no deja ocultos los botones Crear; y el addon trabaja notablemente menos por cada línea de chat en un reino concurrido.",
    -- Onglet Nouveautés — v1.10.0
    ["Les commandes touchent tout le royaume + un coup d'œil sur les recettes de tes rerolls"] =
        "Los pedidos llegan a todo el reino, más un vistazo de solo lectura a las recetas de tus alters",
    ["Une commande postée à « Tous » part maintenant aussi sur le canal du royaume, pas seulement vers les joueurs déjà croisés ou tes amis/guilde — un inconnu qui n'a jamais croisé ton chemin peut désormais la voir. Tu ne reçois un toast que pour un métier que tu as : une commande de Forge ne dérange pas un Enchanteur."] =
        "Un pedido publicado a «Todos» ahora también se difunde por el canal del reino, no solo a jugadores ya conocidos o a tus amigos/hermandad — un desconocido con el que nunca te has cruzado puede verlo ahora. Solo recibes un aviso para una profesión que realmente tienes: un pedido de Herrería no molesta a un Encantador.",
    ["Clique sur le métier d'un reroll depuis le menu minimap : fenêtre en lecture seule avec ses recettes connues, réactifs requis et niveau de compétence. Pas de bouton créer (tu n'es pas connecté sur ce perso), pas de comptage de sacs."] =
        "Haz clic en la profesión de un alter desde el menú del minimapa: una ventana de solo lectura muestra sus recetas conocidas, reactivos necesarios y nivel de habilidad. Sin botón de crear (no estás conectado con ese personaje), sin conteo de bolsas.",
    ["Le menu reroll de la minimap ne liste plus que les vrais métiers (Cuisine, Premiers soins, Pêche et Poisons n'encombrent plus la liste) ; le seuil de détection de spam est réglable via |cFFFFFFFF/co spam|r, avec un mode mute automatique en plus du popup habituel."] =
        "El menú de alters del minimapa ahora solo lista profesiones reales (Cocina, Primeros auxilios, Pesca y Venenos ya no lo saturan); el umbral de detección de spam es ajustable con |cFFFFFFFF/co spam|r, incluyendo un modo de silencio automático además de la ventana emergente habitual.",
    -- Onglet Nouveautés — v1.9.0
    ["Tes rerolls réunis : cooldowns partagés, une identité, l'onglet Mes artisans"] =
        "Tus alters reunidos: enfriamientos compartidos, una identidad, la pestaña Mis artesanos",
    ["Cooldowns de recettes partagés : les autres voient « Transmutation : prête » ou « dans 14h » sur ton infobulle d'artisan — fini de demander en canal si ton Arcanite est dispo."] =
        "Enfriamientos de recetas compartidos: los demás ven «Transmutación: lista» o «en 14h» en tu información de artesano — se acabó preguntar por el canal si tu Arcanita está lista.",
    ["Regroupe tes persos sous une identité (|cFFFFFFFF/co alts on|r) : une commande nommée pour ton alchimiste hors ligne arrive sur le perso où tu es connecté, et tu peux l'accepter depuis n'importe lequel. Vérifié des deux côtés (personne ne peut se faire passer pour le reroll d'autrui). Désactivé par défaut."] =
        "Agrupa tus personajes bajo una identidad (|cFFFFFFFF/co alts on|r): un pedido dirigido a tu alquimista desconectado llega al personaje en el que estás conectado, y puedes aceptarlo desde cualquiera. Verificado en ambos sentidos (nadie puede hacerse pasar por el alter de otro). Desactivado por defecto.",
    ["Nouvel onglet « Mes artisans » : tous les métiers de ton compte sur le royaume en une vue, comme un seul perso — niveau, recettes connues par catégorie, cooldowns en tête, et quel perso porte chaque recette."] =
        "Nueva pestaña «Mis artesanos»: todas las profesiones de tu cuenta en el reino en una vista, como un solo personaje — nivel, recetas conocidas por categoría, enfriamientos arriba, y qué personaje tiene cada receta.",
    ["VU"] = "VISTO",
    ["vu crafter (sans l'addon)"] = "visto fabricando (sin el addon)",
    ["vu crafter"] = "visto fabricando",
    ["%d+ · vu crafter"] = "%d+ · visto fabricando",
    -- Cooldowns de recettes (transmutations & co)
    ["%s : prête"] = "%s: lista",
    ["%s : dans %s"] = "%s: en %s",
    ["(estimé)"] = "(estimado)",
    ["Transmutation"] = "Transmutación",
    ["%dj"] = "%dd", ["%dh"] = "%dh", ["%dmin"] = "%dmin",
    -- Relais partenaire
    ["via %s · il y a %s"] = "vía %s · hace %s",
    ["RELAIS"] = "RELEVO",
    -- Rerolls (identité joueur multi-persos, /co alts — opt-in)
    ["rerolls : ACTIVÉS — ta liste de persos est annoncée au réseau."] =
        "alters: ACTIVADOS — tu lista de personajes se anuncia a la red.",
    ["rerolls : désactivés — rien n'est annoncé (opt-in : /co alts on)."] =
        "alters: desactivados — no se anuncia nada (opt-in: /co alts on).",
    ["perso principal (vitrine) : %s"] = "personaje principal (escaparate): %s",
    ["persos du compte (%s) : %s"] = "personajes de la cuenta (%s): %s",
    ["le lien n'est vérifié chez les autres qu'après une connexion de CHAQUE perso (addon actif)."] =
        "los demás solo verifican el vínculo cuando CADA personaje se ha conectado una vez (addon activo).",
    ["rerolls activés — perso principal : %s (changer : /co alts main <nom>)"] =
        "alters activados — personaje principal: %s (cambiar: /co alts main <nombre>)",
    ["rerolls désactivés — dissolution annoncée au réseau."] =
        "alters desactivados — disolución anunciada a la red.",
    ["perso inconnu sur ce compte : %s (connecte-le une fois avec l'addon)"] =
        "personaje desconocido en esta cuenta: %s (conéctalo una vez con el addon)",
    ["regrouper tes rerolls (opt-in) : liste annoncée, commandes routées vers ton perso connecté"] =
        "agrupar tus alters (opt-in): lista anunciada, pedidos dirigidos a tu personaje conectado",
    ["commande nommée pour %s : connecte ce perso, ou active /co alts on pour accepter d'ici."] =
        "pedido dirigido a %s: conecta ese personaje, o activa /co alts on para aceptar desde aquí.",
    ["|cFFFFCC00commande pour ton reroll %s|r de |cFFFFFFFF%s|r : %s%s%s"] =
        "|cFFFFCC00pedido para tu alter %s|r de |cFFFFFFFF%s|r: %s%s%s",
    ["En ligne via %s"] = "En línea vía %s",
    ["reroll : %s (%s)"] = "alter: %s (%s)",
    -- Onglet « Mes artisans » (vue agrégée des métiers du compte — 100 % local)
    ["Mes artisans"] = "Mis artesanos",
    ["MÉTIERS DU COMPTE"] = "PROFESIONES DE LA CUENTA",
    ["%d recettes"] = "%d recetas",
    ["Aucun métier. Ouvre ta fenêtre métier sur chaque perso une fois."] =
        "Sin profesiones. Abre la ventana de profesión en cada personaje una vez.",
    ["Partager mes rerolls sur le réseau"] = "Compartir mis alters en la red",
    ["Vitrine : %s"] = "Escaparate: %s",
    ["Rerolls"] = "Alters",
    ["%s — lecture seule"] = "%s — solo lectura",
    ["Pas de recettes connues (métier de récolte ?)."] = "Sin recetas conocidas (¿profesión de recolección?).",
    ["Repérer les crafteurs autour (en ville)"] = "Detectar artesanos cercanos (en ciudad)",
    ["Ajouter ami"] = "Añadir amigo",
    ["|cFFFFFFFF%s|r ajouté à tes amis."] = "|cFFFFFFFF%s|r añadido a tus amigos.",
    ["repérage des crafteurs autour : |cFFFFFFFF%s|r (en ville) — /co crafters [on|off]"] =
        "detección de artesanos cercanos: |cFFFFFFFF%s|r (en ciudad) — /co crafters [on|off]",
    ["repérer les crafteurs sans l'addon qui craftent autour (en ville ; défaut : off)"] =
        "detectar a jugadores sin el addon que fabrican cerca (en ciudad; por defecto: off)",
    ["Archivées"] = "Archivados", ["En cours"] = "Activos",
    ["Aucune commande. Onglet « Commande » pour en poster une."] = "Sin pedidos. Pestaña « Pedir » para crear uno.",
    ["Clic : "] = "Clic: ", ["Accepter"] = "Aceptar", ["Annuler"] = "Cancelar", ["Livrer"] = "Entregar",
    ["J'ai reçu"] = "Recibido", ["Remise"] = "Entregado",
    ["remise — en attente de confirmation de %s : %s"] = "entregado — esperando confirmación de %s: %s",
    ["réception confirmée : %s"] = "recepción confirmada: %s",
    ["réception confirmée par %s ! crafts livrés au total : %d"] = "¡recepción confirmada por %s! total de fabricaciones entregadas: %d",
    ["%s a remis ta commande : %s — clique « J'ai reçu » pour confirmer"] =
        "%s ha entregado tu pedido: %s — haz clic en « Recibido » para confirmar",
    ["Refuser"] = "Rechazar", ["%s a refusé ta commande : %s"] = "%s ha rechazado tu pedido: %s",
    ["guilde"] = "hermandad", ["commerce"] = "comercio",
    ["Inviter en groupe"] = "Invitar al grupo", ["en attente"] = "pendiente", ["acceptées"] = "aceptados", ["en sourdine"] = "silenciados",
    ["diag"] = "diag", ["Sourdine"] = "Silencio", ["Réafficher"] = "Mostrar",
    ["Muter"] = "Silenciar", ["Ajouter aux artisans"] = "Añadir a artesanos",
    ["Passer commande à %s"] = "Pedir a %s", ["Passer commande"] = "Hacer pedido",
    ["Passer commande à %s (%s)"] = "Pedir a %s (%s)",
    ["%s est mis en sourdine — plus aucune notification de sa part."] = "%s ha sido silenciado — no más notificaciones suyas.",
    ["%s n'est plus en sourdine."] = "%s ya no está silenciado.",
    ["usage : /co unmute <nom>"] = "uso: /co unmute <nombre>",
    ["aucun joueur en sourdine. /co mute <nom> pour en ajouter un."] = "ningún jugador silenciado. /co mute <nombre> para añadir uno.",
    ["en sourdine (%d) : %s"] = "silenciados (%d): %s",
    ["mute auto bas niveau : |cFFFFFFFFdésactivé|r — /co lowlevel <niveau>"] = "silencio auto de nivel bajo: |cFFFFFFFFdesactivado|r — /co lowlevel <nivel>",
    ["mute auto bas niveau : sous le niveau |cFFFFFFFF%d|r — /co lowlevel [N|off]"] = "silencio auto de nivel bajo: por debajo de nivel |cFFFFFFFF%d|r — /co lowlevel [N|off]",
    ["%s a posté %d fois en peu de temps. Le mettre en sourdine ?"] = "%s ha publicado %d veces en poco tiempo. ¿Silenciarlo?",
    ["muter/démuter un joueur (aucune notif de sa part)"] = "silenciar/reactivar a un jugador (ninguna notificación suya)",
    ["seuil de mute auto des persos bas niveau (défaut 5)"] = "umbral de silencio auto para personajes de nivel bajo (por defecto 5)",
    ["mute auto"] = "silencio auto", ["popup"] = "ventana",
    ["détection de spam : |cFFFFFFFFdésactivée|r — /co spam <max> [fenêtre] pour l'activer"] = "detección de spam: |cFFFFFFFFdesactivada|r — /co spam <max> [ventana] para activar",
    ["détection de spam : |cFFFFFFFF%d|r posts / |cFFFFFFFF%ds|r → %s"] = "detección de spam: |cFFFFFFFF%d|r mensajes / |cFFFFFFFF%ds|r → %s",
    ["  /co spam <max> [fenêtre] · /co spam auto · /co spam off"] = "  /co spam <max> [ventana] · /co spam auto · /co spam off",
    ["réglage anti-spam : seuil, fenêtre, mute auto vs popup"] = "ajuste anti-spam: umbral, ventana, silencio auto vs ventana",
    ["%d livrés"] = "%d entregados",
    ["· %d plans"] = "· %d recetas",
    ["+%d de plus"] = "+%d más",
    ["Maj : plans connus"] = "Mayús: recetas conocidas",
    ["ton reroll |cFFFFFFFF%s|r sait le faire : %s"] = "tu alt |cFFFFFFFF%s|r sabe hacerlo: %s",
    ["COMPOSANTS FOURNIS"] = "COMPONENTES APORTADOS", ["À FOURNIR"] = "APORTAR", ["complet"] = "completo",
    ["chargé — |cFFFFFFFF/co help|r pour les commandes. (Réseau global de craft — autonome.)"] =
        "cargado — |cFFFFFFFF/co help|r para los comandos. (Red global de fabricación — autónoma.)",
    ["CraftLink introuvable — l'infra partagée n'est pas chargée."] =
        "CraftLink no encontrado — la infraestructura compartida no está cargada.",
    ["infra CraftLink — dataVersion=|cFFE8B84B%d|r, protocole=v%d, catalogue=%d métier(s) %s"] =
        "infra CraftLink — dataVersion=|cFFE8B84B%d|r, protocolo=v%d, catálogo=%d profesión(es) %s",
    ["prêt"] = "listo", ["vide"] = "vacío",
    ["mes recettes captées : "] = "mis recetas capturadas: ",
    ["aucune recette captée — ouvre une fenêtre de métier une fois pour l'amorcer."] =
        "ninguna receta capturada — abre una ventana de profesión una vez para iniciarlas.",
    ["réseau global : %s — |cFFFFFFFF%d|r en ligne, |cFFFFFFFF%d|r crafteur(s) connus"] =
        "red global: %s — |cFFFFFFFF%d|r en línea, |cFFFFFFFF%d|r artesano(s) conocido(s)",
    ["connexion…"] = "conectando…",
    ["réseau : sollicitation envoyée (HI global + PING proximité)."] =
        "red: solicitud enviada (HI global + PING de proximidad).",
    ["métier inconnu : "] = "profesión desconocida: ",
    ["commandes :"] = "comandos:",
    ["statut (infra, mes recettes, réseau)"] = "estado (infra, mis recetas, red)",
    ["carnet d'ordres"] = "libro de pedidos", ["poster une commande"] = "crear un pedido",
    ["solliciter l'annuaire (présence + proximité)"] = "consultar el directorio (presencia + proximidad)",
    ["teste l'aller-retour réseau (PING global → PONG des autres porteurs)"] =
        "prueba el ida y vuelta de red (PING global → PONG de otros usuarios)",
    ["vue commandes d'un métier (ou menu des métiers si vide)"] =
        "vista de pedidos de una profesión (o menú de profesiones si vacío)",
    ["basculer fenêtre métier custom / vue Blizzard"] = "alternar ventana de profesión propia / vista Blizzard",
    ["portée des notifications de commande"] = "alcance de las notificaciones de pedido",
    ["notifications : |cFFFFFFFF%s|r — /co notify [all|directed|named|off]"] =
        "notificaciones: |cFFFFFFFF%s|r — /co notify [all|directed|named|off]",
    ["portée du scan des demandes de craft en chat (défaut : mes métiers)"] =
        "alcance del escaneo de solicitudes de fabricación en el chat (por defecto: mis profesiones)",
    ["scan chat commerce/guilde : |cFFFFFFFF%s|r — /co scan [mine|all|off]"] =
        "escaneo de chat comercio/hermandad: |cFFFFFFFF%s|r — /co scan [mine|all|off]",
    ["mode solo"] = "modo solo",
    ["injecte/retire un réseau fictif (artisans + commandes)"] = "inyecta/quita una red ficticia (artesanos + pedidos)",
    ["journalise le réseau dans la SavedVariable (off | clear | dump)"] =
        "registra la red en la SavedVariable (off | clear | dump)",
    ["commande introuvable : "] = "pedido no encontrado: ", ["ce n'est pas ta commande."] = "este no es tu pedido.",
    ["commande annulée : "] = "pedido cancelado: ", ["commande non disponible : "] = "pedido no disponible: ",
    ["c'est ta propre commande."] = "es tu propio pedido.",
    ["cette commande ne t'est pas destinée."] = "este pedido no es para ti.",
    ["commande acceptée : %s (%s)"] = "pedido aceptado: %s (%s)",
    ["tu n'as pas accepté cette commande."] = "no has aceptado este pedido.",
    ["commande relâchée : "] = "pedido liberado: ", ["carnet d'ordres :"] = "libro de pedidos:",
    [" par "] = " por ", ["  (aucune commande active)"] = "  (ningún pedido activo)",
    ["usage : /co post [shift-clic objet] [xN] [prix]"] = "uso: /co post [mayús-clic objeto] [xN] [precio]",
    ["commande postée |cFFFFFFFF%s|r : %s x%d %s[%s]"] = "pedido creado |cFFFFFFFF%s|r: %s x%d %s[%s]",
    ["CraftLink absent — l'infra réseau n'est pas chargée."] = "CraftLink ausente — la infraestructura de red no está cargada.",
    ["PING envoyé (canal %s%s). En attente des PONG…"] = "PING enviado (canal %s%s). Esperando los PONG…",
    ["rejoint"] = "unido", ["PAS rejoint"] = "NO unido",
    [", +|cFFFFFFFF%d|r whisper(s)"] = ", +|cFFFFFFFF%d|r susurro(s)",
    ["entrante acceptée : |cFFFFFFFF%s|r"] = "entrante aceptada: |cFFFFFFFF%s|r",
    ["infra non prête."] = "infra no lista.",
    ["activé — %d artisans + %d commandes + %d entrantes injectés."] =
        "activado — %d artesanos + %d pedidos + %d entrantes inyectados.",
    ["désactivé — faux artisans et commandes purgés."] = "desactivado — artesanos y pedidos ficticios eliminados.",
    ["vidée."] = "vaciado.", ["%d lignes (30 dernières) :"] = "%d líneas (últimas 30):",
    ["ON. Fais tes tests, puis |cFFFFFFFF/reload|r, puis lis SavedVariables\\CraftingOrderClassic.lua (clé trace)."] =
        "ON. Haz tus pruebas, luego |cFFFFFFFF/reload|r, luego lee SavedVariables\\CraftingOrderClassic.lua (clave trace).",
    ["réseau"] = "red", ["canal rejoint"] = "canal unido",
    ["en ligne"] = "en línea", ["artisan(s)"] = "artesano(s)",
    ["Alchimie"] = "Alquimia", ["Forge"] = "Herrería", ["Cuisine"] = "Cocina",
    ["Enchantement"] = "Encantamiento", ["Ingénierie"] = "Ingeniería", ["Secourisme"] = "Primeros auxilios",
    ["Pêche"] = "Pesca", ["Herboristerie"] = "Herboristería", ["Travail du cuir"] = "Peletería",
    ["Minage"] = "Minería", ["Dépeçage"] = "Desuello", ["Couture"] = "Sastrería",
    ["Joaillerie"] = "Joyería", ["Calligraphie"] = "Inscripción", ["Élémentaire"] = "Elemental",
    ["En attente"] = "Pendiente", ["Acceptée"] = "Aceptado", ["Livrée"] = "Entregado", ["Annulée"] = "Cancelado", ["Refusée"] = "Rechazado",
    ["LISTE DES PLANS"] = "LISTA DE RECETAS", ["JE FOURNIS"] = "YO APORTO", ["Réactifs"] = "Reactivos",
    ["(cocher = je fournis)"] = "(marcar = yo aporto)", ["Commission"] = "Comisión", ["Qté"] = "Cant.",
    ["Destinataire :"] = "Destinatario:", ["Diffuser à tous"] = "Difundir a todos", ["Poster"] = "Publicar",
    ["Choisis un métier puis un plan."] = "Elige una profesión y luego una receta.",
    ["Rechercher un plan"] = "Buscar una receta", ["Qualité : "] = "Calidad: ",
    ["Sélection : "] = "Selección: ", ["Commande postée !"] = "¡Pedido publicado!",
    ["Réactifs : j'ai tout"] = "Reactivos: lo tengo todo", ["Réactifs : "] = "Reactivos: ",
    ["[Prêt]"] = "[Listo]",
    ["Autres"] = "Otros",
    ["connus"] = "conocidas", ["niv. %d"] = "niv. %d",
    ["Choisis d'abord un plan."] = "Elige primero una receta.", ["Aucun plan sélectionné."] = "Ninguna receta seleccionada.",
    ["Ajoutés"] = "Añadidos", ["fournis"] = "aportados", ["Chargement…"] = "Cargando…",
    ["Toute la guilde"] = "Toda la hermandad", ["Tous les amis"] = "Todos los amigos",
    ["Tous les ajoutés"] = "Todos los añadidos", ["Tous les croisés"] = "Todos los vistos",
    ["MÉTIER DE RÉCOLTE"] = "PROFESIÓN DE RECOLECCIÓN", ["Rechercher une ressource"] = "Buscar un recurso",
    ["LISTE DES RESSOURCES"] = "LISTA DE RECURSOS", ["Demande de récolte — quantité voulue"] = "Solicitud de recolección — cantidad deseada",
    ["stacks"] = "montones", ["pile"] = "montón", ["piles"] = "montones",
    ["Récolteur :"] = "Recolector:", ["Prix proposé"] = "Precio ofrecido",
    ["Choisis un métier de récolte puis une ressource."] = "Elige una profesión de recolección y luego un recurso.",
    ["Aucune ressource sélectionnée."] = "Ningún recurso seleccionado.", ["par stack"] = "por montón", ["à l'unité"] = "por unidad",
    ["Commande de récolte postée !"] = "¡Pedido de recolección publicado!", ["Choisis d'abord une ressource."] = "Elige primero un recurso.",
    ["Toutes"] = "Todas",
    ["Objet |cFFE8B84Bélémentaire|r (farmé sur les mobs, pas de métier). Diffusé à tous. Quantité et prix |cFFE8B84B%s.|r"] =
        "Objeto |cFFE8B84Belemental|r (obtenido de las criaturas, sin profesión). Difundido a todos. Cantidad y precio |cFFE8B84B%s.|r",
    ["Diffusée aux récolteurs ayant |cFFE8B84B%s.|r Quantité et prix proposé |cFFE8B84B%s.|r"] =
        "Difundido a recolectores con |cFFE8B84B%s|r. Cantidad y precio ofrecido |cFFE8B84B%s.|r",
    ["SOURCE"] = "FUENTE", ["AJOUTER UN JOUEUR"] = "AÑADIR UN JUGADOR", ["Nom du personnage"] = "Nombre del personaje",
    ["Métier :"] = "Profesión:", ["Chuchoter"] = "Susurrar", ["Aucun artisan dans cette source."] = "Ningún artesano en esta fuente.",
    ["En ligne"] = "En línea", ["Hors ligne"] = "Desconectado", ["niv "] = "niv ", ["niv ?"] = "niv ?",
    ["GUILDE"] = "HERMANDAD", ["AMIS"] = "AMIGO", ["AJOUTÉ"] = "AÑADIDO", ["CROISÉ"] = "VISTO", ["CONFÉDÉRÉ"] = "CONFED.",
    ["Confédération"] = "Confederación",
    ["artisan ajouté : "] = "artesano añadido: ",
    ["(lié quand il sera en ligne avec l'addon)"] = "(vinculado cuando esté en línea con el addon)",
    ["GreenWall non détecté — section « Confédération » masquée."] = "GreenWall no detectado — sección « Confederación » oculta.",
    ["GreenWall actif, aucun confédéré repéré (il faut qu'ils parlent en /g)."] = "GreenWall activo, ningún confederado detectado (deben hablar en /g).",
    ["confédérés repérés (%d) :"] = "confederados detectados (%d):",
    ["en ligne · annuaire"] = "en línea · directorio", ["annuaire"] = "directorio",
    ["pas encore dans l'annuaire (sans COC ?)"] = "aún no en el directorio (¿sin COC?)",
    ["confédérés GreenWall repérés (SoD live only)"] = "confederados GreenWall detectados (solo SoD en vivo)",
    ["Commandes pour ce joueur"] = "Pedidos para este jugador",
    ["Commandes à livrer"] = "Pedidos por entregar",
    ["+%d autre(s)"] = "+%d más",
    ["Remplir depuis commande"] = "Rellenar desde pedido",
    ["Marquer livrée"] = "Marcar como entregado",
    ["À réclamer : %s"] = "A cobrar: %s",
    ["À payer : %s"] = "A pagar: %s",
    ["Pas de prix convenu."] = "Sin precio acordado.",
    ["Gratuit."] = "Gratis.",
    ["Commande : %s"] = "Pedido: %s",
    ["Voici ta commande. Prix convenu : %s."] = "Aquí está tu pedido. Precio acordado: %s.",
    ["Voici ta commande."] = "Aquí está tu pedido.",
    ["Recettes"] = "Recetas", ["Commandes"] = "Pedidos", ["Réactifs :"] = "Reactivos:",
    ["Créer"] = "Crear", ["Créer tout"] = "Crear todo", ["Vue Blizzard"] = "Vista Blizzard",
    ["Sélectionne une recette."] = "Selecciona una receta.", ["Produit "] = "Produce ",
    ["réactifs insuffisants."] = "reactivos insuficientes.",
    ["fenêtre métier custom |cFF33DD33activée|r — ouvre un métier. (Guild Economy laisse la main.)"] =
        "ventana de profesión propia |cFF33DD33activada|r — abre una profesión. (Guild Economy cede el paso.)",
    ["fenêtre métier custom |cFFFFCC00désactivée|r (vue Blizzard)."] =
        "ventana de profesión propia |cFFFFCC00desactivada|r (vista Blizzard).",
    ["» Vue Crafting Order"] = "» Vista Crafting Order",
    ["Module Commandes non chargé — redémarre complètement WoW (quitter/relancer), pas un simple /reload."] =
        "Módulo de Pedidos no cargado — reinicia WoW por completo (salir/relanzar), no solo /reload.",
    ["Clic : ouvrir le carnet d'ordres"] = "Clic: abrir el libro de pedidos",
    ["Clic droit : mes métiers"] = "Clic derecho: mis profesiones",
    ["Mes métiers"] = "Mis profesiones", ["Aucun métier connu."] = "Ninguna profesión conocida.",
    ["Don / gratuit"] = "Regalo / gratis",
    ["|cFFFF8800entrante|r |cFFFFFFFF%s|r (%s) : %s%s%s"] = "|cFFFF8800entrante|r |cFFFFFFFF%s|r (%s): %s%s%s",
    ["   |cFF33DD33→ tu sais la crafter|r — Carnet › Entrantes"] = "   |cFF33DD33→ sabes fabricarlo|r — Libro › Entrantes",
    ["|cFFFFCC00commande pour TOI|r de |cFFFFFFFF%s|r : %s%s%s"] = "|cFFFFCC00pedido para TI|r de |cFFFFFFFF%s|r: %s%s%s",
    ["ton artisan |cFFFFFFFF%s|r est en ligne."] = "tu artesano |cFFFFFFFF%s|r está en línea.",
    ["plan looté : |cFFFFFFFF%s|r — enseigne |cFFFFFFFF%s|r (%s) %s"] =
        "receta saqueada: |cFFFFFFFF%s|r — enseña |cFFFFFFFF%s|r (%s) %s",
    ["|cFF888888(tu la connais déjà)|r"] = "|cFF888888(ya la conoces)|r",
    ["|cFF33DD33(tu ne la connais pas encore !)|r"] = "|cFF33DD33(¡aún no la conoces!)|r",
    ["alerte plan looté : |cFFFFFFFF%s|r — /co lootalert [on|off]"] =
        "alerta de receta saqueada: |cFFFFFFFF%s|r — /co lootalert [on|off]",
    ["alerte quand tu loots un plan connu de CraftLink (défaut : on)"] =
        "avisa cuando saqueas una receta conocida por CraftLink (por defecto: on)",
    ["Partenaire (basculer)"] = "Socio (alternar)",
    ["[Partenaire]"] = "[Socio]",
    ["|cFFFFFFFF%s|r marqué comme partenaire — priorité sur les alertes de don."] =
        "|cFFFFFFFF%s|r marcado como socio — prioridad en las alertas de regalo.",
    ["|cFFFFFFFF%s|r n'est plus marqué comme partenaire."] = "|cFFFFFFFF%s|r ya no está marcado como socio.",
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
    ["La pastille verte/grise indique s'il est en ligne."] = "El punto verde/gris indica si está en línea.",
    ["Réseau, confidentialité & statuts"] = "Red, privacidad y estados",
    ["L'addon rejoint un canal dédié pour faire circuler le carnet entre joueurs de l'addon — aucun message lisible n'y est envoyé."] =
        "El addon se une a un canal dedicado para transmitir el libro entre usuarios del addon — no se envía ningún mensaje legible.",
    ["|cFFFFFFFF/co channel off|r le quitte à tout moment (whisper et guilde restent actifs) ; |cFFFFFFFF/co channel on|r le rejoint."] =
        "|cFFFFFFFF/co channel off|r sale en cualquier momento (susurro y hermandad siguen activos); |cFFFFFFFF/co channel on|r vuelve a unirse.",
    ["Statuts d'une commande : "] = "Estados de un pedido: ",
}
for k, v in pairs(es) do L[k] = v end
