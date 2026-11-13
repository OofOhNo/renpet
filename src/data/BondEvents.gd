extends RefCounted
class_name BondEvents

## Escenas de Historia de los 6 candidatos (Fase 6.3), una por Acto/etapa (1, 2 y 3).
## Cada elección tiene un "kind":
##   "friend"  -> ruta de Amistad (siempre disponible)
##   "rival"   -> ruta de Rivalidad / Némesis (siempre disponible)
##   "romance" -> ruta romántica: SOLO se ofrece cuando Renpet tiene 18 años o más (ver RelationshipManager)
## Los textos de la ruta romántica son deliberadamente sobrios: gestos y confesiones, nada más.

const EVENTS: Dictionary = {
	"soren": {
		1: {
			"title": "El Mapa Prohibido de la Madre de Soren",
			"narrative": "A medianoche en la Torre de Cristal, Soren te muestra temblando el papiro sellado por el que desterraron a su madre: las ecuaciones demuestran que la estrella que cayó hace doce años no figura en ningún atlas antiguo y alguien borró su órbita de los registros del Santuario.\n\n«Si el Archimago descubre que conservo este mapa me expulsarán, Renpet... pero tenía que mostrarte que nos ocultan la verdad sobre tu origen.»",
			"choices": [
				{"kind": "friend", "label": "Prometer alianza: «Gracias por confiar en mí, amigo mío. Limpiaremos el nombre de tu madre.»",
					"affection": 24, "respect": 24, "spark": 0, "stat_effects": {"erudicion": 20, "human_anchor": 8},
					"outcome": "Soren sonríe con profundo alivio y sella contigo un pacto de hermandad académica inquebrantable."},
				{"kind": "rival", "label": "Confiscar el mapa con frialdad: «Mi naturaleza no es un acertijo para tu familia, Soren.»",
					"affection": -28, "respect": 16, "spark": 0, "stat_effects": {"gravedad": 20, "entropia": 8},
					"outcome": "Los ojos de Soren se endurecen tras sus lentes. Guarda silencio, pero jura superarte en el Gran Astrolabio."},
				{"kind": "romance", "label": "Tomar sus manos: «Descifraremos juntos el cielo, Soren. Mi vida está en tus manos.»",
					"affection": 22, "respect": 15, "spark": 28, "stat_effects": {"erudicion": 18, "seal_investigation": 10},
					"outcome": "Soren entrelaza sus dedos con los tuyos bajo la cúpula estrellada, jurando descifrar el origen de esa estrella sin ponerte en peligro."}
			]
		},
		2: {
			"title": "Las Ecuaciones que Coinciden",
			"narrative": "Soren te espera en el observatorio con tres pliegos extendidos y los dedos manchados de tinta de plata. Compara tu pulso de aether con los cálculos prohibidos de su madre: coinciden hasta el último decimal.\n\n«No es casualidad, Renpet. Mi madre midió algo que aún no existía cuando la desterraron... y ahora está respirando frente a mí. No sé si debo celebrarlo o llorar.»",
			"choices": [
				{"kind": "friend", "label": "«Guardemos el secreto y busquemos las pruebas juntos, a tu ritmo y sin presiones.»",
					"affection": 26, "respect": 26, "spark": 0, "stat_effects": {"erudicion": 24, "seal_investigation": 12},
					"outcome": "Soren cierra el cuaderno y, por primera vez en meses, se ríe. Desde esa noche te llama 'colega' en voz alta."},
				{"kind": "rival", "label": "«Quema esos cálculos. Si alguien más los lee, nos condenarás a los dos.»",
					"affection": -30, "respect": 12, "spark": 0, "stat_effects": {"gravedad": 22, "abyssal_sync": 6},
					"outcome": "Soren aprieta los labios. Guarda los pliegos contra el pecho y no vuelve a mirarte como a una amiga."},
				{"kind": "romance", "label": "Quedarte a su lado toda la noche, descifrando juntos las páginas hasta el amanecer.",
					"affection": 24, "respect": 18, "spark": 28, "stat_effects": {"erudicion": 20, "resonancia": 16},
					"outcome": "Cuando amanece sobre la cúpula, Soren se da cuenta de que ha apoyado la cabeza en tu hombro. Ninguno de los dos dice nada."}
			]
		},
		3: {
			"title": "El Dilema del Informe",
			"narrative": "Soren sostiene un informe sellado con el emblema del Emperador. Entregarlo limpiaría el honor de su familia; también condenaría a Renpet.\n\n«Llevo años soñando con este momento, y ahora que lo tengo... pesa como una piedra. Dime qué hago. O dime que no te importa, y lo entregaré.»",
			"choices": [
				{"kind": "friend", "label": "«Quémalo. Tu apellido se limpiará de otra forma: con la verdad, cuando llegue el momento.»",
					"affection": 30, "respect": 30, "spark": 0, "stat_effects": {"erudicion": 30, "human_anchor": 10},
					"outcome": "Soren arroja el informe a las llamas del brasero. «Mi madre habría hecho lo mismo.» Se convierte en tu aliado científico más leal."},
				{"kind": "rival", "label": "«Entrégalo si te atreves. Pero después de eso, no vuelvas a hablarme.»",
					"affection": -40, "respect": 20, "spark": 0, "stat_effects": {"gravedad": 25, "entropia": 8},
					"outcome": "Soren baja la mirada, pero cierra el informe. Al día siguiente su nombre aparece al frente de la Inquisición Científica."},
				{"kind": "romance", "label": "Tomar su mano: «Elige lo que puedas vivir sin remordimientos. Yo estaré aquí, decidas lo que decidas.»",
					"affection": 30, "respect": 24, "spark": 30, "stat_effects": {"erudicion": 24, "human_anchor": 12},
					"outcome": "Soren sonríe, con lágrimas, y rompe el sello del informe delante de ti. Su carrera termina esa noche; su historia contigo empieza."}
			]
		}
	},
	"vespera": {
		1: {
			"title": "Versos Bajo la Armadura de Escarcha",
			"narrative": "Tras el entrenamiento vespertino bajo la lluvia, encuentras a Dama Vespera curando sus nudillos ensangrentados junto a un cuaderno de poemas sobre un pájaro enjaulado.\n\n«Mi padre el Duque dice que si no derroto a la hija del Héroe, no merezco su apellido... Adelante, ríete de mis estúpidos versos.»",
			"choices": [
				{"kind": "friend", "label": "Ofrecer tu mano de camarada: «Peleemos por nuestro propio honor, no por el de nuestros padres.»",
					"affection": 22, "respect": 26, "spark": 0, "stat_effects": {"temple": 22, "human_anchor": 8},
					"outcome": "Vespera choca su antebrazo con el tuyo al estilo de los antiguos caballeros solares."},
				{"kind": "rival", "label": "Desafiarla sin piedad: «Los poemas no detienen una estocada. Levántate y pelea en serio.»",
					"affection": -25, "respect": 22, "spark": 10, "stat_effects": {"temple": 25, "destreza": 15},
					"outcome": "El orgullo de Vespera arde como hielo azul. Empuña su lanza jurando derrotarte en el Festival de Otoño."},
				{"kind": "romance", "label": "Acariciar su mejilla herida: «Tus versos son más fuertes que la lanza de tu padre, Vespera.»",
					"affection": 25, "respect": 18, "spark": 30, "stat_effects": {"destreza": 16, "gracia": 16},
					"outcome": "Vespera contiene el aliento, sonrojándose por primera vez mientras apoya su frente contra tu hombro."}
			]
		},
		2: {
			"title": "La Casa Donde se Ríe",
			"narrative": "Vespera visita la mansión por primera vez, escoltando un mensaje del Ducado. Se queda en la puerta del comedor mientras tu padre te sirve té y te pregunta por tus lecciones, entre bromas.\n\n«En mi casa nadie ríe en la mesa, Renpet. Yo no sabía que existían casas así.» Su voz se quiebra apenas una nota.",
			"choices": [
				{"kind": "friend", "label": "Ofrecerle un asiento a la mesa: «Quédate a cenar. En esta casa siempre sobra un plato.»",
					"affection": 28, "respect": 22, "spark": 0, "stat_effects": {"human_anchor": 12, "gracia": 14},
					"outcome": "Vespera se sienta con la espalda recta, sin saber dónde poner las manos. A los diez minutos se está riendo de verdad."},
				{"kind": "rival", "label": "«No vine a darte lástima, Vespera. Nos veremos en el Festival; ahí sí quiero verte pelear.»",
					"affection": -22, "respect": 28, "spark": 8, "stat_effects": {"destreza": 22, "temple": 14},
					"outcome": "Vespera recupera el aplomo de golpe. «Entonces nos veremos en la arena, hija del Héroe.» Se va sin despedirse."},
				{"kind": "romance", "label": "Quedarte con ella en el jardín al caer la noche, sin hablar, hasta que decida irse.",
					"affection": 24, "respect": 20, "spark": 28, "stat_effects": {"gracia": 18, "human_anchor": 10},
					"outcome": "Vespera mira las estrellas contigo en silencio. Al despedirse susurra tu nombre sin el 'Dama', por primera vez."}
			]
		},
		3: {
			"title": "La Orden del General Morvath",
			"narrative": "El General Morvath ha ordenado a Vespera liderar el escuadrón de captura contra Renpet. Ella llega sola a la mansión, de noche, con la lanza al hombro y el estandarte del Ducado enrollado.\n\n«Tengo una orden firmada. Y tengo una decisión que tomar. Dime qué eres para mí, Renpet, porque yo ya no lo sé.»",
			"choices": [
				{"kind": "friend", "label": "«Eres mi camarada de acero. Pelea a mi lado, no contra mí.»",
					"affection": 32, "respect": 32, "spark": 0, "stat_effects": {"temple": 28, "destreza": 22},
					"outcome": "Vespera clava la lanza en el suelo y renuncia a la orden frente a su padre al día siguiente. Desde ese día, es tu mejor general."},
				{"kind": "rival", "label": "«Cumple tu orden. Pero te advierto que no me capturarás sin una guerra.»",
					"affection": -40, "respect": 24, "spark": 6, "stat_effects": {"temple": 26, "gravedad": 18},
					"outcome": "Vespera asiente, con una dignidad helada. Acepta el ritual de sangre del Ducado y se convierte en tu rival más temible."},
				{"kind": "romance", "label": "Sostener su mirada: «Si renuncias a tu apellido por mí, nunca te dejaré sola.»",
					"affection": 32, "respect": 26, "spark": 30, "stat_effects": {"temple": 20, "gracia": 22},
					"outcome": "Vespera arroja el estandarte a la chimenea. «Entonces seré solo Vespera.» Su voz tiembla, pero su mano en la tuya no."}
			]
		}
	},
	"kaelen": {
		1: {
			"title": "Fiebre de Escoria en los Acueductos",
			"narrative": "La guardia ducal ha bloqueado el puente de medicinas hacia los canales inferiores. Kaelen está acorralado en el tejado con un cargamento de elixires robados para los huérfanos enfermos.\n\n«¡Apártate, princesa! Si te ven ayudándome, mancharás el ilustre nombre de tu padre.»",
			"choices": [
				{"kind": "friend", "label": "Usar tu prestigio para abrir el paso legalmente y curar a los niños.",
					"affection": 26, "respect": 25, "spark": 0, "stat_effects": {"moralidad": 15, "human_anchor": 10},
					"outcome": "Los huérfanos del canal te aclaman como su protectora y Kaelen te jura lealtad eterna."},
				{"kind": "rival", "label": "Entregar el cargamento a la guardia para mantener el orden imperial.",
					"affection": -35, "respect": -10, "spark": 0, "stat_effects": {"gravedad": 20, "gold": 120},
					"outcome": "Kaelen escapa entre las sombras con una mirada de puro rencor que jamás olvidará."},
				{"kind": "romance", "label": "Saltar junto a él y cubrir su huida: «Que hablen lo que quieran; esta noche vuelo contigo, Kaelen.»",
					"affection": 24, "respect": 20, "spark": 28, "stat_effects": {"destreza": 20, "luminiscencia": 15},
					"outcome": "Escapan juntos por las cornisas iluminadas por la luna. Kaelen te besa la mano entre risas de adrenalina."}
			]
		},
		2: {
			"title": "El Agua que Brilla",
			"narrative": "Kaelen te lleva a un canal del barrio bajo donde el agua es gris y espesa. Moja un frasco y te lo ofrece. Al contacto con tu mano, el líquido se aclara por un instante.\n\n«Lo supe en cuanto te vi. Tu luz limpia lo que los nobles ensucian. Los críos del barrio no sobrevivirán otro invierno sin agua limpia, Renpet. Te lo pido, no te lo exijo.»",
			"choices": [
				{"kind": "friend", "label": "«Cuenta conmigo. Haremos un sistema de filtros con el Crisol y con mi luz. Es de todos.»",
					"affection": 30, "respect": 28, "spark": 0, "stat_effects": {"luminiscencia": 24, "human_anchor": 12},
					"outcome": "Los huérfanos te esperan en la orilla cada semana. Kaelen te llama 'socia' y te regala la mitad de una moneda partida."},
				{"kind": "rival", "label": "«No pienso gastar mi poder en barro. Que se ocupen los nobles que lo ensuciaron.»",
					"affection": -32, "respect": -8, "spark": 0, "stat_effects": {"entropia": 8, "gravedad": 14},
					"outcome": "Kaelen guarda el frasco sin decir nada. «Pues ya sé de qué lado estás.» Los huérfanos del canal dejan de saludarte."},
				{"kind": "romance", "label": "Mojar las manos junto a él y quedarte hasta que el agua se vea limpia, aunque amanezca.",
					"affection": 26, "respect": 22, "spark": 28, "stat_effects": {"luminiscencia": 20, "destreza": 12},
					"outcome": "Al amanecer el canal brilla. Kaelen te mira como si acabaras de cambiar el mundo, y quizá lo hayas hecho."}
			]
		},
		3: {
			"title": "La Insurrección de los Bajos Fondos",
			"narrative": "La corona declara la ley marcial. Kaelen irrumpe en tu mansión con la ropa chamuscada y el cuello brillando, y deja caer un mapa de los túneles sobre la mesa.\n\n«Mañana se alza el barrio entero. Puedo hacerlo contigo o sin ti, Renpet. Pero quiero hacerlo contigo.»",
			"choices": [
				{"kind": "friend", "label": "«Cuenta con mi espada y con mi luz. Pero que no muera nadie que no deba.»",
					"affection": 34, "respect": 30, "spark": 0, "stat_effects": {"destreza": 26, "moralidad": 14},
					"outcome": "La insurrección triunfa con pocas bajas. Kaelen te nombra 'Protectora del Barrio' ante los huérfanos."},
				{"kind": "rival", "label": "«No pienso unirme a una revuelta. La ley marcial es la ley.»",
					"affection": -42, "respect": 6, "spark": 0, "stat_effects": {"gravedad": 24, "entropia": 6},
					"outcome": "Kaelen recoge el mapa con calma. «Me lo imaginaba.» Esa misma noche, tu mansión sufre su primer robo."},
				{"kind": "romance", "label": "Decirle: «Voy contigo, y voy hasta el final. No quiero ser libre si tú no lo eres.»",
					"affection": 34, "respect": 26, "spark": 30, "stat_effects": {"destreza": 22, "luminiscencia": 18},
					"outcome": "Kaelen se queda sin palabras, por primera vez en años. Después sonríe con su descaro de siempre: «Entonces gobernemos para el pueblo.»"}
			]
		}
	},
	"cassian": {
		1: {
			"title": "El Decreto Secreto del Solsticio",
			"narrative": "Durante un baile de gala en el Palacio de Alabastro, el Príncipe Cassian te conduce tras las columnas de loto. Tiene el rostro pálido.\n\n«Renpet, acabo de leer los archivos reservados de mi padre y del Sumo Sacerdote... Tu nombre aparece ligado a un rito antiguo cuando cumplas veinte años. La Corona teme lo que oculta la estrella en tu interior.»",
			"choices": [
				{"kind": "friend", "label": "Forjar un pacto político: «Seré tu aliada para reformar el Senado antes del Solsticio.»",
					"affection": 20, "respect": 28, "spark": 0, "stat_effects": {"gracia": 20, "erudicion": 15},
					"outcome": "El Príncipe inclina la cabeza ante tu temple de estadista y te entrega su sello personal."},
				{"kind": "rival", "label": "Rechazar a la familia real: «Dile al Emperador que si intenta tocarme, su palacio caerá.»",
					"affection": -26, "respect": 15, "spark": 0, "stat_effects": {"gravedad": 25, "abyssal_sync": 8},
					"outcome": "Cassian retrocede con tristeza solemne, comprendiendo que la corona y tú podrían terminar en guerra."},
				{"kind": "romance", "label": "Abrazarlo en la penumbra: «Entonces cambiemos el destino del Imperio juntos, Cassian.»",
					"affection": 24, "respect": 18, "spark": 28, "stat_effects": {"magnetismo": 22, "seal_investigation": 10},
					"outcome": "Cassian te estrecha contra su pecho y promete usar todo el poder de la corona para proteger tu vida."}
			]
		},
		2: {
			"title": "La Oferta de Custodia",
			"narrative": "El Emperador, a través de Cassian, ofrece a la familia del Héroe una 'custodia honorífica': Renpet viviría en palacio, bajo la protección de la Corona. Cassian te lo cuenta a solas, en la biblioteca real, con la voz muy baja.\n\n«Dicen que es un honor. Yo creo que es una jaula con cortinas de seda. No les di mi respuesta aún. Quería oír primero la tuya.»",
			"choices": [
				{"kind": "friend", "label": "«Rechaza la custodia por mí, con respeto. Yo te ayudaré con los argumentos ante el Senado.»",
					"affection": 26, "respect": 30, "spark": 0, "stat_effects": {"magnetismo": 22, "erudicion": 16},
					"outcome": "Cassian rechaza la oferta ante todo el Senado y cita tus argumentos. La Corte empieza a susurrar tu nombre con otro tono."},
				{"kind": "rival", "label": "«Acepto. Un palacio es mejor que una mansión sin protección. Y a ti te conviene que esté cerca.»",
					"affection": -28, "respect": 10, "spark": 0, "stat_effects": {"gracia": 14, "abyssal_sync": 8},
					"outcome": "Cassian asiente con una cortesía helada. «Entonces será como dices.» Desde ese día, siempre hay un guardia en tu puerta."},
				{"kind": "romance", "label": "Tomar su mano en el silencio de la biblioteca: «Lo que decidas, lo decidiremos juntos.»",
					"affection": 26, "respect": 20, "spark": 28, "stat_effects": {"magnetismo": 20, "gracia": 16},
					"outcome": "Cassian cierra los ojos un instante, como quien se quita una armadura. «Gracias, Renpet. Hacía mucho que nadie me decía 'juntos'.»"}
			]
		},
		3: {
			"title": "El Pacto de Sangre de la Corona",
			"narrative": "En la sala del trono, el Emperador firma el pergamino de extracción del Sello. Cassian aguarda con el sello real en la mano y la mirada al suelo. Cuando se queda solo contigo, estalla.\n\n«Me pidió que lo ejecutara yo. Que yo le diera la orden a los magos. Tengo una noche para decidir si soy un príncipe o un hijo.»",
			"choices": [
				{"kind": "friend", "label": "«Sé el príncipe que Aethelgard necesita: derriba el pacto desde dentro y yo te protegeré.»",
					"affection": 34, "respect": 34, "spark": 0, "stat_effects": {"magnetismo": 28, "gracia": 20},
					"outcome": "Cassian rompe el sello del decreto frente a la Corte. Es el principio del fin del Pacto de Sangre, y el comienzo de tu mejor alianza."},
				{"kind": "rival", "label": "«Si tu padre intenta tocarme, el trono caerá y tú con él.»",
					"affection": -42, "respect": 18, "spark": 0, "stat_effects": {"gravedad": 28, "abyssal_sync": 10},
					"outcome": "Cassian asiente con un dolor solemne. Firma la orden de caza real. Ya no hay vuelta atrás."},
				{"kind": "romance", "label": "Decirle: «Elige libertad. Yo estaré a tu lado, sea cual sea el precio.»",
					"affection": 34, "respect": 28, "spark": 30, "stat_effects": {"magnetismo": 24, "gracia": 22},
					"outcome": "Cassian rompe el sello del decreto y te ofrece el brazo: «Entonces fundemos una dinastía que no deba nada a nadie.»"}
			]
		}
	},
	"mirari": {
		1: {
			"title": "La Canción de los Dos Latidos",
			"narrative": "En el Anfiteatro vacío al atardecer, Mirari apoya su oído sobre tu pecho mientras pulsa un acorde de plata en su arpa.\n\n«Escucho a la niña que ama a su padre... y escucho una voz antigua susurrando bajo luces doradas. Si ambos siguen peleando, tu alma se romperá.»",
			"choices": [
				{"kind": "friend", "label": "Pedirle que armonice ambos latidos para proteger a tu familia.",
					"affection": 24, "respect": 24, "spark": 0, "stat_effects": {"human_anchor": 10, "seal_integrity": 8},
					"outcome": "Mirari te bendice con el Himno de la Palma Eterna, fortaleciendo tu estrella y tu corazón mortal."},
				{"kind": "rival", "label": "Hacer vibrar las cuerdas con poder abisal: «No necesito que nadie domestique mi tormenta.»",
					"affection": -25, "respect": 10, "spark": 0, "stat_effects": {"resonancia": 25, "abyssal_sync": 10},
					"outcome": "Una cuerda del arpa de Mirari se rompe con un chispazo púrpura. Ella reza en silencio por tu destino."},
				{"kind": "romance", "label": "Cantar a dúo con ella tomando sus manos: «Enséñame a ser una sola melodía contigo, Mirari.»",
					"affection": 25, "respect": 18, "spark": 28, "stat_effects": {"luminiscencia": 20, "seal_integrity": 6},
					"outcome": "Sus voces resuenan en las columnas de cristal, restaurando la paz de tu núcleo y despertando un amor luminoso."}
			]
		},
		2: {
			"title": "El Rito de la Pureza",
			"narrative": "La Alta Matriarca Seraphina exige una purificación pública de Renpet. Mirari te lo cuenta en voz baja, con el arpa envuelta en un paño para que nadie escuche.\n\n«Dice que es solo un rito, que te limpiará la 'sombra'. Pero yo oigo lo que hay debajo: quieren callar a quien vive en tu pecho. Y él no ha hecho nada malo, Renpet. Solo ha estado solo.»",
			"choices": [
				{"kind": "friend", "label": "«No me opongo al rito, pero quiero que tú lo guíes. Hagamos que ambos latidos canten juntos.»",
					"affection": 28, "respect": 28, "spark": 0, "stat_effects": {"luminiscencia": 20, "seal_integrity": 8, "abyssal_sync": 6},
					"outcome": "El rito se convierte en un canto de a tres voces. La Matriarca, desconcertada, no se atreve a interrumpirlo."},
				{"kind": "rival", "label": "«Si quieren purificarme, que lo intenten. No pienso arrodillarme ante nadie.»",
					"affection": -30, "respect": 4, "spark": 0, "stat_effects": {"gravedad": 18, "entropia": 8},
					"outcome": "Mirari baja la cabeza. «Entonces lo harán sin mí, y será peor.» Esa noche el Santuario cierra sus puertas a tu familia."},
				{"kind": "romance", "label": "Sentarte junto a ella frente al arpa y decirle: «Cualquier cosa que cantes, quiero escucharla contigo.»",
					"affection": 26, "respect": 22, "spark": 28, "stat_effects": {"luminiscencia": 22, "human_anchor": 10},
					"outcome": "Mirari sonríe con una dulzura que no necesita ojos. Esa noche compone la primera estrofa de una sinfonía que aún no tiene nombre."}
			]
		},
		3: {
			"title": "El Canto del Origen",
			"narrative": "El Día del Solsticio se acerca. Mirari te espera en el escenario del Anfiteatro con una partitura en braille y las cuerdas recién cambiadas.\n\n«El Canto del Origen puede armonizar tus dos almas. Pero necesita que ambas quieran cantar. Si alguna se niega, el Sello cederá. ¿Estás lista para escucharte a ti misma?»",
			"choices": [
				{"kind": "friend", "label": "«Lo estoy. Cantemos juntas, y que Zephyr cante también.»",
					"affection": 34, "respect": 34, "spark": 0, "stat_effects": {"human_anchor": 14, "seal_integrity": 10, "luminiscencia": 20},
					"outcome": "El Canto resuena en todo el Anfiteatro. Cuando termina, el Sello brilla como nunca y los latidos de tu pecho laten al mismo compás."},
				{"kind": "rival", "label": "«No. No me hace falta una canción para saber quién soy.»",
					"affection": -42, "respect": 6, "spark": 0, "stat_effects": {"resonancia": 24, "abyssal_sync": 12},
					"outcome": "Mirari guarda silencio y recoge su arpa. «Entonces tendré que cantar el Canto de Clausura, y que los dioses me perdonen.»"},
				{"kind": "romance", "label": "Tomar su mano: «Si hay que cantar, que sea contigo. No quiero que nadie más me escuche.»",
					"affection": 34, "respect": 28, "spark": 30, "stat_effects": {"human_anchor": 14, "luminiscencia": 22},
					"outcome": "Mirari compone la 'Sinfonía del Anclaje' sobre la marcha. Tu humanidad queda intacta aunque desates todo tu poder estelar."}
			]
		}
	},
	"zephyr": {
		1: {
			"title": "El Pacto Frente al Espejo del Sueño",
			"narrative": "En sueños, el espejo del observatorio se abre hacia un mar de nebulosas violetas. Zephyr aparece con cadenas de oro egipcio atadas a sus muñecas.\n\n«Me arrebataron el cielo que conocía y me ataron al otro lado de este reflejo. Cada vez que usas tu poder, mis cadenas tiemblan... Dime, niña de la estrella: cuando llegue el Equinoccio, ¿qué harás con la verdad?»",
			"choices": [
				{"kind": "friend", "label": "Proponer una tregua justa: «Préstame tu fuerza para proteger a mi padre y buscaré qué ocurrió realmente.»",
					"affection": 22, "respect": 28, "spark": 0, "stat_effects": {"abyssal_sync": 10, "human_anchor": 8, "seal_investigation": 10},
					"outcome": "Zephyr sonríe con respeto genuino ante tu coraje mortal, sellando la alianza del Tercer Camino."},
				{"kind": "rival", "label": "Reforzar los barrotes dorados: «Este cuerpo y esta vida son míos. ¡Quédate tras el cristal!»",
					"affection": -30, "respect": 20, "spark": 0, "stat_effects": {"seal_integrity": 8, "gravedad": 25},
					"outcome": "Zephyr ruge entre relámpagos carmesíes, jurando que el día que flaquees tomará el control por la fuerza."},
				{"kind": "romance", "label": "Tocar su rostro a través del cristal: «No te dejaré solo en ese espejo, Zephyr. Encontraremos quién te ató.»",
					"affection": 26, "respect": 20, "spark": 30, "stat_effects": {"abyssal_sync": 14, "resonancia": 22},
					"outcome": "Las cadenas doradas dejan de quemar. Zephyr apoya su mano contra la tuya en una simbiosis perfecta."}
			]
		},
		2: {
			"title": "El Sabor del Pan Caliente",
			"narrative": "Esta vez no hay cadenas en el sueño. Zephyr está sentado en una cocina que reconoces: la de tu casa. Sostiene un trozo de pan, absorto, como si fuese una reliquia.\n\n«Lo recordaste tú, anoche. El calor, el olor... Llevo siglos sin sentir nada de esto. No sé si agradecértelo o temerlo. Cuéntame cómo es vivir así.»",
			"choices": [
				{"kind": "friend", "label": "Sentarte con él y contarle, recuerdo por recuerdo, cómo es un día en esta casa.",
					"affection": 28, "respect": 26, "spark": 0, "stat_effects": {"abyssal_sync": 14, "human_anchor": 10},
					"outcome": "Zephyr escucha sin interrumpir, y al despertar sientes el pecho extrañamente tibio. Esa mañana, el Sello no duele."},
				{"kind": "rival", "label": "«No son recuerdos para ti. Esta vida es mía y no voy a compartirla con quien quiere romperme.»",
					"affection": -30, "respect": 14, "spark": 0, "stat_effects": {"seal_integrity": 6, "entropia": 8},
					"outcome": "El pan se deshace en polvo de estrellas entre sus dedos. Zephyr te mira, sin rabia, solo con una amargura inmensa."},
				{"kind": "romance", "label": "Partir el pan y ofrecerle la mitad: «Quiero que lo pruebes conmigo.»",
					"affection": 26, "respect": 22, "spark": 28, "stat_effects": {"abyssal_sync": 14, "resonancia": 16},
					"outcome": "Zephyr lo prueba y cierra los ojos. «Es lo más hermoso que he sentido en mil años.» Y al despertar, tú también sonríes."}
			]
		},
		3: {
			"title": "Dos Almas, Un Destino",
			"narrative": "La víspera del Solsticio, el espejo del sueño se rompe en mil fragmentos de luz. Zephyr aparece sin cadenas, de pie, frente a ti. La Diosa llegará mañana.\n\n«Puedo prestarte todo mi poder y quedarme dentro de ti, o intentar separarnos y enfrentarla cada uno en su cuerpo. Dime qué quieres, Renpet. Esta vez, no es una orden ni una súplica.»",
			"choices": [
				{"kind": "friend", "label": "«Sellemos el Pacto del Eclipse: tu fuerza y mi voluntad, sin que ninguno someta al otro.»",
					"affection": 34, "respect": 34, "spark": 0, "stat_effects": {"abyssal_sync": 20, "human_anchor": 12, "gravedad": 20},
					"outcome": "Zephyr extiende la mano. Cuando la tomas, ambos ríen. «Dos almas, un destino. Qué extraña forma de ser libre.»"},
				{"kind": "rival", "label": "«No pactaré con quien quiso devorar mi mente. Que el sello decida.»",
					"affection": -42, "respect": 10, "spark": 0, "stat_effects": {"seal_integrity": -8, "entropia": 10},
					"outcome": "Los ojos de eclipse de Zephyr se oscurecen. «Entonces será una guerra en tu cabeza, niña.» Sus cadenas empiezan a romperse."},
				{"kind": "romance", "label": "Decirle: «Elijo caminar contigo. Fusionados o separados, no voy a soltarte.»",
					"affection": 34, "respect": 28, "spark": 30, "stat_effects": {"abyssal_sync": 20, "resonancia": 22},
					"outcome": "Zephyr sonríe con una ternura antigua. «Entonces desafiemos juntos al firmamento, carcelera mía.»"}
			]
		}
	}
}

## Devuelve el evento (o {}) de ese personaje y etapa.
static func get_event(npc_id: String, stage: int) -> Dictionary:
	if EVENTS.has(npc_id) and EVENTS[npc_id].has(stage):
		return EVENTS[npc_id][stage]
	return {}
