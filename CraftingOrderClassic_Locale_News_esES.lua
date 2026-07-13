-- CraftingOrderClassic_Locale_News_esES.lua — traductions de l'onglet « Nouveautés » (esES).
-- Extrait de _Locale_esES.lua (plafond anti-monolithe). Clé FR → texte ES, chargé APRÈS _Locale.lua.

local COC = CraftingOrderClassic
if (GetLocale and GetLocale() or "") ~= "esES" then return end
local L = COC.L

local news = {
    -- Onglet Nouveautés (changelog en jeu)
    ["Nouveautés"] = "Novedades",
    -- v1.17.0
    ["L'interface passe au style natif de WoW"] = "La ventana ahora combina con el juego",
    ["La fenêtre n'a plus son habillage doré maison : elle emprunte le cadre du jeu (barre de titre, portrait rond, onglets, boutons). Elle se fond dans l'interface au lieu de ressembler à un addon posé par-dessus, et rien n'a bougé de ce que tu connais."] = "La ventana ha cambiado su aspecto dorado propio por el marco del juego (barra de título, retrato redondo, pestañas arriba, botones). Ahora se integra en la interfaz en vez de parecer un addon añadido por encima, y nada se ha movido de lo que ya conoces.",
    ["La vue métier est refaite, avec une colonne Commandes en liste : une ligne par commande (demandeur, objet voulu, prix), et le clic ouvre la carte complète (composants fournis, coût des réactifs, Accepter / Refuser / Chuchoter) avec une croix pour revenir à la liste. Et les sous-catégories de récolte (Peaux, Écailles, Herbes, Poissons) sont enfin traduites hors client français."] = "La ventana de profesión se ha rehecho, con la columna de pedidos como lista: una línea por pedido (solicitante, objeto deseado, precio), y al hacer clic se abre la ficha completa (componentes aportados, coste de reactivos, Aceptar / Rechazar / Susurrar) con una cruz para volver a la lista. Y las subcategorías de recolección (Pieles, Escamas, Hierbas, Peces) por fin están traducidas fuera de un cliente francés.",
    -- v1.15.1
    ["Tes commandes n'appartiennent qu'à toi"] = "Tus pedidos son solo tuyos",
    ["Recettes triées, et où est l'or"] = "Recetas ordenadas, y dónde está el oro",
    ["Fini le fourre-tout « Consommable » : les recettes sont regroupées par type (potions de soin, de mana, élixirs, flacons, transmutations…) et triées du plus haut niveau au plus bas. Une potion qui rend vie ET mana apparaît sous les deux. Le même classement s'applique partout — Commande, Mes artisans, et les métiers de récolte (minerais, herbes, cuirs, poissons)."] = "Se acabó el cajón de sastre \"Consumible\": las recetas se agrupan por tipo (pociones de curación, de maná, elixires, frascos, transmutaciones…) y se ordenan del nivel más alto al más bajo. Una poción que restaura vida Y maná aparece en ambas. La misma agrupación se aplica en todas partes — Pedir, Mis artesanos y las profesiones de recolección (minerales, hierbas, cueros, peces).",
    ["Si tu as Lazy Gold, chaque recette affiche sa rentabilité (pièces, étoiles au-delà de mille pièces d'or ; rien pour une perte). La pièce d'or au-dessus de la liste trie par profit, le bouton « 123 » bascule en valeurs exactes. L'onglet Commande a les deux boutons, plus la valeur HV et le coût des réactifs sur chaque commande entrante."] = "Si usas Lazy Gold, cada receta muestra su rentabilidad (monedas, estrellas más allá de mil de oro; nada si hay pérdida). La moneda de oro sobre la lista ordena por beneficio, el botón \"123\" cambia a valores exactos. La pestaña Pedir tiene ambos botones, más el valor de subasta y el coste de los reactivos en cada pedido entrante.",
    ["Dans l'annuaire, les métiers passent en icônes : un artisan avec un plan vraiment rentable a un contour doré, le survol nomme le plan, le clic ouvre la Commande déjà ciblée. « Mes artisans » gagne « Tous les plans du royaume » : tous tes persos (même faction) fusionnés et triés par profit — d'un coup d'œil, quel reroll fait des sous. Et si tu as MissingTradeSkillsList, un bouton montre tes recettes non apprises en rouge, avec leur source au clic."] = "En el directorio, las profesiones pasan a iconos: un artesano con un plan realmente rentable tiene un borde dorado, al pasar el cursor se nombra el plan, al hacer clic se abre Pedir ya dirigido a él. Mis artesanos gana \"Todos los planos del reino\": todos tus personajes (misma facción) fusionados y ordenados por beneficio — de un vistazo, qué alter gana dinero. Y si usas MissingTradeSkillsList, un botón muestra tus recetas no aprendidas en rojo, con su origen al hacer clic.",
    ["Les identifiants de commande étaient devinables : n'importe qui pouvait réécrire la tienne (acheteur, prix, quantité). C'est fermé : seul son auteur peut la modifier. Le relais entre joueurs, lui, continue de fonctionner — c'est comme ça qu'une commande atteint quelqu'un que le canal n'a jamais touché."] =
        "Los identificadores de pedido se podían adivinar, y cualquiera podía reescribir el tuyo (comprador, precio, cantidad). Eso está cerrado: solo quien publicó un pedido puede modificarlo. El relevo entre jugadores sigue funcionando, que es como un pedido llega a alguien a quien el canal nunca alcanzó.",
    ["On ne peut plus te faire mettre en sourdine en postant de fausses commandes en ton nom, et un acheteur dont les commandes sont relayées en rafale n'est plus muté par erreur. « X a refusé ta commande » et le rappel « tu sais le faire » ne se rejouent plus en boucle, et rien ne passe d'un joueur que tu as mis en sourdine."] =
        "Nadie puede conseguir que te silencien publicando pedidos falsos en tu nombre, y un comprador cuyos pedidos se retransmiten en ráfaga ya no se silencia por error. «X ha rechazado tu pedido» y el aviso «sabes hacerlo» ya no se repiten en bucle, y no pasa nada de alguien a quien has silenciado.",
    ["La vue métier n'affiche plus les commandes privées destinées à quelqu'un d'autre, ni les expirées. Ton compteur de crafts livrés ne peut plus être gonflé par un tiers. Et croiser un artisan coûte deux fois moins de messages : le bonjour porte maintenant tes métiers, ce qui règle aussi les artisans qui s'affichaient sans aucun métier."] =
        "La ventana de profesión ya no muestra pedidos privados destinados a otra persona, ni los caducados. Tu contador de encargos entregados no puede inflarlo un tercero. Y cruzarte con un artesano cuesta la mitad de mensajes: el saludo ahora lleva tus profesiones, lo que también arregla los artesanos que aparecían sin ninguna profesión.",
    -- v1.15.0
    ["Recherche de travail : signale que tu es dispo"] = "Buscar trabajo: avisa que estás disponible",
    ["Ouvre un métier et clique « Chercher du travail » : tout le royaume sait que tu es dispo, une icône d'artisan s'affiche au-dessus de ta tête pour ceux qui passent, et tu apparais « [Dispo] » dans leur annuaire. Ça s'éteint tout seul au bout d'un moment si tu oublies."] =
        "Abre una profesión y haz clic en «Buscar trabajo»: todo el reino sabe que estás disponible, un icono de artesano aparece sobre tu cabeza para quien pase, y sales como «[Busca]» en su directorio. Se apaga solo al cabo de un rato si lo olvidas.",
    ["Au passage : les deux fenêtres ne s'emmêlent plus (un clic la ramène au premier plan), l'annuaire a un bouton partenaire et se limite à ta faction (pas d'échange cross-faction sur Classic), et un artisan ne s'affiche plus avec un métier qui n'est pas le sien."] =
        "De paso: las dos ventanas ya no se enredan (un clic la trae al frente), el directorio tiene un botón de socio y se limita a tu facción (sin comercio entre facciones en Classic), y un artesano ya no muestra una profesión que no es suya.",
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
    -- Onglet Nouveautés — v1.14.0
    ["Un panneau pour gérer les mis en sourdine"] = "Un panel para gestionar a los silenciados",
    ["L'onglet Artisans a maintenant une section « En sourdine » : chaque joueur muté y apparaît avec sa raison et le temps restant (ou « permanent »), avec un bouton pour le rétablir directement — plus besoin de deviner qui est encore muté."] =
        "La pestaña Artesanos ahora tiene una sección «Silenciados»: cada jugador silenciado aparece con su motivo y el tiempo restante (o «permanente»), con un botón para reactivarlo directamente — sin adivinar quién sigue silenciado.",
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
