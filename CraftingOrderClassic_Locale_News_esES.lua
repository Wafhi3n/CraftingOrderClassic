-- CraftingOrderClassic_Locale_News_esES.lua — traductions de l'onglet « Nouveautés » (esES).
-- Extrait de _Locale_esES.lua (plafond anti-monolithe). Clé FR → texte ES, chargé APRÈS _Locale.lua.

local COC = CraftingOrderClassic
if (GetLocale and GetLocale() or "") ~= "esES" then return end
local L = COC.L

local news = {
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
    -- (clés v1.7.0/v1.7.1 retirées : ces versions ne sont plus listées dans l'onglet Nouveautés)
    ["Allemand et espagnol + onglet Nouveautés"] = "Alemán y español + pestaña Novedades",
    ["L'interface se traduit en allemand et en espagnol selon la langue de ton client WoW."] =
        "La interfaz se traduce al alemán y al español según el idioma de tu cliente de WoW.",
    ["Ce nouvel onglet « Nouveautés » affiche les notes de version directement en jeu."] =
        "Esta nueva pestaña « Novedades » muestra las notas de versión directamente en el juego.",
    -- Onglet Nouveautés — v1.13.0
    ["Modération : mutes avec raison, temporaires, liste de confiance"] = "Moderación: silencios con motivo, temporales, lista de confianza",
    ["Un mute porte désormais une raison et une date, et peut être temporaire : |cFFFFFFFF/co mute Bob 1h spammeur|r se lève tout seul au bout d'une heure (|cFFFFFFFF/co mute|r seul liste les mutés avec raison et temps restant). Et |cFFFFFFFF/co trust <nom>|r marque un joueur de confiance, jamais mis en sourdine automatiquement — le mute manuel restant toujours possible."] =
        "Un silencio ahora lleva un motivo y una fecha, y puede ser temporal: |cFFFFFFFF/co mute Bob 1h spammer|r se levanta solo tras una hora (|cFFFFFFFF/co mute|r solo lista a los silenciados con motivo y tiempo restante). Y |cFFFFFFFF/co trust <nombre>|r marca a un jugador como de confianza, nunca silenciado automáticamente — el silencio manual sigue disponible.",
    -- Onglet Nouveautés — v1.12.1
    ["Personne ne peut poster une commande en ton nom"] = "Nadie puede publicar un pedido en tu nombre",
    ["Une commande arrivant par le canal du royaume était crue sur parole quant à son acheteur : un joueur pouvait publier de fausses commandes au nom d'autrui, et nourrir la détection de spam contre sa victime jusqu'à ce que tout le monde la mette en sourdine. Elles doivent désormais venir du joueur qui les a postées."] =
        "A un pedido que llegaba por el canal del reino se le creía su comprador sin más: un jugador podía publicar pedidos falsos en nombre de otro, y alimentar la detección de spam contra su víctima hasta que todos la silenciaran. Ahora deben venir del jugador que los publicó.",
    ["|cFFFFFFFF/co channel off|r quitte maintenant vraiment le canal. Il se contentait d'empêcher de le rejoindre au login suivant : tes commandes continuaient de partir au royaume pendant toute la session."] =
        "|cFFFFFFFF/co channel off|r ahora abandona de verdad el canal. Antes solo impedía volver a unirse en el siguiente inicio de sesión: tus pedidos seguían saliendo al reino durante toda la sesión.",
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
}

for k, v in pairs(news) do L[k] = v end
