extends Node

## RelationshipManager - Matriz 3D de Vínculos (Fase 6.1, 6.3 y Profundización Social).
## Ejes por personaje: Afecto (-100..+100), Respeto (-100..+100) y Chispa Romántica (0..100).
## Incluye: variaciones de diálogo por Acto (12-14, 15-17, 18-20), reacciones a atuendo y
## mutaciones visibles (sin spoilers del giro), salidas/citas elegibles y encuentros cruzados.
## REGLA DE EDAD: la Chispa Romántica, las citas y las elecciones románticas de las escenas
## solo existen cuando Renpet tiene 18 años o más (GameState.ROMANCE_MIN_AGE) y el personaje
## también es adulto. Antes de eso, las rutas disponibles son Amistad y Rivalidad/Némesis.

signal relationship_updated(npc_id: String)

const NPC_ORDER: Array[String] = ["soren", "vespera", "kaelen", "cassian", "mirari", "zephyr", "lyra", "caelum"]

const SOCIAL_COST_GIFT: int = 75
const OUTING_MIN_AFFECTION: int = 15
const MAX_SOCIAL_POINTS: int = 3
const MAX_ACTIONS_PER_NPC: int = 2
const STAGE2_THRESHOLD: int = 40   # |Afecto| necesario para la etapa 2
const STAGE3_THRESHOLD: int = 78   # |Afecto| necesario para la etapa 3

const OUTING_SPOT_ORDER: Array[String] = [
	"mirador_torre", "jardin_alabastro", "puente_linternas", "palco_anfiteatro", "orilla_espejo"
]

const OUTING_SPOTS: Dictionary = {
	"mirador_torre": {
		"name": "Mirador de la Torre de Cristal", "cost": 35, "stat": "erudicion", "stat_val": 9, "stress": -10,
		"venue_tag": "Telescopios de latón y mapas bajo la brisa nocturna"
	},
	"jardin_alabastro": {
		"name": "Jardines de Té de Alabastro", "cost": 40, "stat": "gracia", "stat_val": 9, "stress": -12,
		"venue_tag": "Glorietas de loto blanco y pastelería fina de corte"
	},
	"puente_linternas": {
		"name": "Puente de las Linternas (Acueductos)", "cost": 30, "stat": "destreza", "stat_val": 9, "stress": -10,
		"venue_tag": "Puestos callejeros, té especiado y reflejos dorados sobre el canal"
	},
	"palco_anfiteatro": {
		"name": "Galería Acústica del Anfiteatro", "cost": 35, "stat": "magnetismo", "stat_val": 9, "stress": -12,
		"venue_tag": "Butacas altas de mármol entre ecos de ensayo vespertino"
	},
	"orilla_espejo": {
		"name": "Orilla Nocturna del Espejo Astral", "cost": 40, "stat": "resonancia", "stat_val": 8, "stress": -14,
		"venue_tag": "Sendero silencioso junto al estanque de aguas quietas"
	}
}

## base_age: edad del personaje cuando Renpet tiene 12 (crece a la par de ella). Zephyr es un ser ancestral.
const NPC_DATA: Dictionary = {
	"soren": {
		"name": "Soren de Caelum", "title": "El Astrónomo de la Torre de Cristal", "location": "Torre de Cristal",
		"district_id": "torre", "role_stat": "erudicion", "base_age": 14, "start": {"affection": 2, "respect": 8},
		"perk_desc": "Compañero en Expedición: +25% Daño Astral y revela puntos débiles (Guardia -15).",
		"bio": "Prodigio astronómico cuya madre fue desterrada por calcular una anomalía gravitatoria prohibida en los registros del Santuario.",
		"intro": "\"¿La pupila del Observatorio? Pensé que solo subías a mirar las lámparas de gala... Toma asiento, pero no toques mis efemérides húmedas.\"",
		"dialogues": {
			"support": "\"¿Me trajiste café mientras reviso las tablas lunares? Gracias, Renpet... Contigo aquí, siento que la verdad del cielo no da tanto miedo.\"",
			"train": "\"Si trazas el arco de esta ecuación dos veces más deprisa, notarás cómo la órbita revela su fallo sin esfuerzo.\"",
			"romance": "\"Mis manos tiemblan cuando ajustas mis lentes así... He medido mil constelaciones, pero ninguna brilla como tú cuando sonríes.\"",
			"gift": "\"¡Un presente tan pensado para mi mesa de cálculo! Nunca olvidaré este gesto.\"",
			"provoke": "\"¿Te burlas del destierro de mi madre y rompes mis mapas? Escúchame bien, Renpet: demostraré ante el Senado que eres una anomalía peligrosa.\""
		}
	},
	"vespera": {
		"name": "Dama Vespera de Val-Astra", "title": "La Lanza de Escarcha y el Deber", "location": "Patio Ducal de Armas",
		"district_id": "patio", "role_stat": "temple", "base_age": 14, "start": {"affection": -4, "respect": 12},
		"perk_desc": "Compañera en Expedición: +25% Daño Físico y rompe +20 de Guardia enemiga por golpe.",
		"bio": "Heredera militar presionada por un padre exigente para superar a la hija del Héroe; en secreto escribe poesía lírica.",
		"intro": "\"¿La hija de Lord Aurelius en mi patio de prácticas? Mantén la guardia alta si no quieres morder el polvo en tu primera visita.\"",
		"dialogues": {
			"support": "\"¿No le contaste a nadie que estos versos eran míos? Eres más noble de lo que mi padre dice, Renpet. Cruzar lanzas contigo es un honor.\"",
			"train": "\"¡Otra vez la postura de estocada! No dejes que tu muñeca dude cuando mi hoja busque tu flanco.\"",
			"romance": "\"Baja el arma un segundo... Cuando me miras de ese modo, toda mi disciplina marcial se derrite como nieve al sol.\"",
			"gift": "\"¿Esto es para mí? Yo... lo guardaré bajo mi armadura, cerca del corazón.\"",
			"provoke": "\"¡Jamás perdonaré esta humillación! Juro por la sangre de Val-Astra que en nuestro próximo duelo no usaré armas de práctica.\""
		}
	},
	"kaelen": {
		"name": "Kaelen de los Canales", "title": "El Rey de los Huérfanos de Mercurio", "location": "Acueductos Subterráneos",
		"district_id": "acueductos", "role_stat": "destreza", "base_age": 15, "start": {"affection": 0, "respect": 6},
		"perk_desc": "Compañero en Expedición: +40% Oro obtenido en mazmorras y +20% Evasión.",
		"bio": "Líder astuto de los bajos fondos que lucha por conseguir medicinas contra la Fiebre de Escoria en los canales.",
		"intro": "\"Vaya, vaya... Qué hace alguien con zapatos tan limpios bajando a los arcos de azogue. Si vienes a fisgonear, mejor vigila tu bolsa.\"",
		"dialogues": {
			"support": "\"¿Bajaste desde tu cómoda mansión con vendas para ayudar a los críos del canal? Tienes agallas, lucero.\"",
			"train": "\"Aquí abajo nadie te avisa antes de lanzarte un gancho. Muévete entre las sombras de los pilares y sígueme el paso.\"",
			"romance": "\"Sube al tejado conmigo, Renpet. Desde aquí arriba ni los dioses ni el Emperador pueden decirnos a quién amar.\"",
			"gift": "\"¿Te acordaste de nosotros al elegir esto? En los canales aprendemos a devolver cada favor al doble.\"",
			"provoke": "\"¿Así que miras por encima del hombro a los que vivimos en el barro? Cuida las cerraduras de tu mansión, hija del Héroe.\""
		}
	},
	"cassian": {
		"name": "Príncipe Cassian Aurelius", "title": "El Heredero del Sol Eclipsado", "location": "Palacio de Alabastro",
		"district_id": "palacio", "role_stat": "magnetismo", "base_age": 16, "start": {"affection": 0, "respect": 8},
		"perk_desc": "Compañero en Expedición: Autoridad Imperial (+20% a todos los daños y escudos).",
		"bio": "Heredero imperial reservado y sagaz; observa con cautela las tensiones ocultas entre el Senado y la Corona.",
		"intro": "\"Por fin conozco en persona a la joven de la Mansión Solar. Disculpa la rigidez de este jardín; rara vez entra alguien sin un pliego de peticiones.\"",
		"dialogues": {
			"support": "\"En la corte todos me ven como una corona con patas. Solo cuando converso contigo en el jardín recuerdo quién soy en realidad.\"",
			"train": "\"En el Senado una pausa vale más que un discurso largo. Practiquemos el tono y la réplica antes de tu próxima gala.\"",
			"romance": "\"Si el trono de Aethelgard exige tu sacrificio para sostenerse, entonces prenderé fuego al trono con mis propias manos por ti.\"",
			"gift": "\"Un presente elegido con tanto gusto... Lo llevaré conmigo durante la sesión del Senado Imperial.\"",
			"provoke": "\"Desprecias mi mano tendida y amenazas la paz del reino. Si eliges ser el enemigo de la Corona, la Corona responderá sin piedad.\""
		}
	},
	"mirari": {
		"name": "Mirari del Anfiteatro", "title": "La Cantora que Escucha el Tiempo", "location": "Anfiteatro de Cristal",
		"district_id": "anfiteatro", "role_stat": "gracia", "base_age": 14, "start": {"affection": 4, "respect": 10},
		"perk_desc": "Compañera en Expedición: Regenera +15% de HP cada turno y protege su Armonía Interior.",
		"bio": "Oráculo y arpista ciega del Anfiteatro; asegura que el aura de Renpet suena como una melodía con dos voces distintas.",
		"intro": "\"No necesitas anunciar tus pasos, viajera... Tu pulso resuena en la piedra del anfiteatro como una nota clara buscando su acorde.\"",
		"dialogues": {
			"support": "\"Acércate, Renpet. Tu presencia suena hoy mucho más serena, como una tarde tibia frente al hogar.\"",
			"train": "\"Escucha el intervalo antes de pulsar la cuerda: la música verdadera nace del silencio que sostienes.\"",
			"romance": "\"Mis ojos no ven las estrellas del cielo, pero cuando toco tu rostro siento la luz más hermosa de la creación.\"",
			"gift": "\"Qué obsequio tan delicado... Puedo oír la intención afectuosa con la que lo trajiste hasta aquí.\"",
			"provoke": "\"Tu corazón suena quebrado y lleno de ceniza cruel, Renpet. Si hieres a los inocentes, mi canto tendrá que enfrentarte.\""
		}
	},
	"zephyr": {
		"name": "Figura del Espejo", "title": "Presencia Tras el Cristal", "location": "Espejo Astral",
		"district_id": "espejo", "role_stat": "resonancia", "base_age": 999, "start": {"affection": 0, "respect": 6},
		"perk_desc": "Simbiosis Interior: Reduce a la mitad el coste al liberar el fulgor oculto en combate.",
		"bio": "Una silueta enigmática que solo se refleja sobre las aguas quietas cuando cae el crepúsculo sobre Aethelgard.",
		"intro": "\"...Al fin te acercas al estanque sin apartar la vista. Llevo mucho tiempo observando cómo titila tu reflejo desde este lado del agua.\"",
		"dialogues": {
			"support": "\"¿Compartes recuerdos cotidianos con un reflejo en lugar de huir? Qué guardiana tan inesperada... Cálida y terca.\"",
			"train": "\"No luches contra la corriente del aether: déjala rodear tus dedos como agua helada y luego concentra el pulso.\"",
			"romance": "\"Nos arrojaron bajo el mismo cielo creyendo que la distancia nos apagaría, Renpet... y en cambio enseñaste a una sombra a esperar el alba contigo.\"",
			"gift": "\"¿Dejas una ofrenda sobre el borde de piedra para un reflejo? Nadie había tenido un gesto así en mil años.\"",
			"provoke": "\"¿Me tratas como a un espectro hostil? Sigue levantando muros, niña; algún día descubrirás la verdad que te ocultan allá arriba.\""
		}
	},
	"lyra": {
		"name": "Lady Lyra de Meridia", "title": "La Rosa de los Salones de Alabastro", "location": "Palacio de Alabastro / Conservatorio",
		"district_id": "palacio", "role_stat": "gracia", "base_age": 13, "start": {"affection": 12, "respect": 24},
		"perk_desc": "Compañera en Expedición: +18% Escudo con Égida de Loto y arpa sanadora que calma el estrés.",
		"bio": "Heredera de la Casa Meridia y prodigio del arpa de cristal. Domina los rumores de la corte con una sonrisa impecable, pero oculta la presión asfixiante de salvar el patrimonio familiar.",
		"intro": "\"Lady Lyra cierra su abanico de nácar con un chasquido elegante y te mide de pies a cabeza: «¿Así que tú eres la pupila del famoso Aurelius? Veremos si tienes oído para la corte o solo sabes pisar barro».\"",
		"dialogues": {
			"support": "\"No me mires tan seria, Renpet. A veces hasta en los salones de mármol se agradece alguien que no hable con doble filo.\"",
			"train": "\"¡Sostén el mentón en alto! Un paso apresurado arruina toda la entrada al salón antes siquiera de que toques una cuerda.\"",
			"romance": "\"Si alguna vez dejo caer este abanico frente a todo el Palacio, será solo para sostener tu mano sin que me importe quién susurre.\"",
			"gift": "\"¿Has escogido esto pensando en mí? Debo admitir que tienes mucho mejor gusto del que murmuran en la academia.\"",
			"provoke": "\"¿Te atreves a desafiar el nombre de la Casa Meridia ante estos invitados? Pronto aprenderás que un rumor mata más rápido que una lanza.\""
		}
	},
	"caelum": {
		"name": "Caelum 'El Perro Gris'", "title": "Escolta de la Guardia de Ceniza", "location": "Patio Ducal / Rutas de Caravana",
		"district_id": "patio", "role_stat": "destreza", "base_age": 14, "start": {"affection": 14, "respect": 26},
		"perk_desc": "Compañero en Expedición: +20% Daño con Tajo de Horus y mandoble demoledor de guardia.",
		"bio": "Huérfano de las guerras fronterizas criado entre caravanas de cuarzo y canales. Desprecia los títulos vacíos y mide a cada persona por cómo sostiene el acero cuando cae la noche.",
		"intro": "\"Caelum apoya su mandoble embotado sobre el hombro y escupe una brizna de trigo: «Un apellido ilustre no detiene una emboscada en los canales, niña. Muéstrame tus callos antes de hablarme de honor».\"",
		"dialogues": {
			"support": "\"Toma esta manta seca, novata. Quien vigila las puertas del norte aprende rápido que el orgullo no calienta los huesos.\"",
			"train": "\"¡No telegrafíes el giro del hombro! En un camino oscuro, un aviso de medio segundo es todo lo que necesita un bandido.\"",
			"romance": "\"Cuando termine el contrato de invierno voy a colgar esta capa gris... Si quieres venir a ver un amanecer sin alarmas, solo dilo.\"",
			"gift": "\"Bah... no tenías por qué gastar plata en un perro callejero del gremio. Pero gracias, lo guardaré en mi morral.\"",
			"provoke": "\"¿Crees que el oro de tu casa te pone por encima de quienes sangramos en la frontera? Agarra una hoja sin filo y ven a probarlo.\""
		}
	}
}

# ==============================================================================
# VARIACIONES DE DIÁLOGO POR ACTO (1: 12-14 | 2: 15-17 | 3: 18-20) Y ACCIÓN
# ==============================================================================
const ACT_DIALOGUES: Dictionary = {
	"soren": {
		1: {
			"support": [
				"«¿Trajiste pasteles de miel hasta el último piso de la Torre? Si el Archimago los huele me confiscará las lentes, pero gracias, Renpet.»",
				"«A veces pienso que todos en la academia solo quieren memorizar fórmulas viejas. Contigo al menos puedo hacer preguntas prohibidas.»",
				"«Mira este boceto lunar que dibujé ayer... Sé que aún tengo tinta en la nariz, no te rías tan fuerte.»"
			],
			"train": [
				"«Cuenta tres respiraciones antes de fijar el prisma: si tiembla tu pulso, la estrella parece saltar de órbita.»",
				"«Vamos a despejar esta ecuación juntos. Tú calculas el ángulo de caída y yo compruebo la refracción celeste.»",
				"«¿Ves cómo se alinea la escala con tu brújula? A tu edad ya deduces más rápido que medio primer año.»"
			],
			"gift_fav": [
				"«¡Un obsequio perfecto para el escritorio de la Torre! Es justo lo que necesitaba para afinar mis tablas de este mes.»",
				"«Soren limpia las gafas emocionado: «¿Cómo sabías que llevaba semanas buscando algo así? No lo soltaré.»»"
			],
			"gift": [
				"«¡Gracias! Aunque no suelo celebrar demasiado entre tanta pizarra, un detalle tuyo siempre ilumina la Torre.»",
				"«Lo pondré junto a mi tintero favorito para acordarme de descansar de vez en cuando.»"
			],
			"provoke": [
				"«¡Cuidado con los mapas de mi madre! Puedes superarme en clase si quieres, pero no te burles de su exilio.»",
				"«Si vienes solo a presumir apellidos, mejor quédate en el Palacio. Aquí hablan los números, no las espadas.»"
			]
		},
		2: {
			"support": [
				"«Con quince años encima ya no me tratan como a un aprendiz inocente... Pero frente a ti sigo bajando los hombros sin darme cuenta.»",
				"«Hoy el Archimago volvió a cerrar el archivo sur con doble sello. Qué extraño alivio saber que al menos tú sospechas lo mismo que yo.»",
				"«Si el invierno te deja libre alguna tarde, preparé té de menta fresca junto al telescopio grande.»"
			],
			"train": [
				"«Hemos dejado atrás los ejercicios básicos: hoy trazaremos anomalías gravitatorias reales sin red de seguridad.»",
				"«Tu intuición para el éter asusta a veces, Renpet... Enséñame cómo sientes la pulsación antes de medirla con tinta.»",
				"«Mantén fija la vista en el cuadrante; el cielo cambia más rápido de lo que admiten los textos del Santuario.»"
			],
			"gift_fav": [
				"«Cada vez que aciertas tanto con un presente me pregunto si llevas notas secretas sobre mis manías... Gracias de corazón.»",
				"«¿Para mí? Hacía meses que no sentía una calidez así entre tanta piedra fría y pergaminos censurados.»"
			],
			"gift": [
				"«Que hayas pensado en traerme esto desde la ciudad vale más que cualquier beca del Senado.»",
				"«Soren ajusta el regalo en su bolso con una sonrisa sincera: «Lo cuidaré mejor que mis cuadrantes».»"
			],
			"provoke": [
				"«¿De verdad crees que no veo cómo se agrietan las mediciones a tu alrededor? No te escudes en sarcasmo, Renpet.»",
				"«Si insistes en despreciar mis advertencias, veremos quién tiene la razón cuando suenen las campanas del Solsticio.»"
			]
		},
		3: {
			"support": [
				"«Míranos ahora: ya no somos los críos que se escondían con linternas bajo el pupitre. Paseo contigo y siento que la Torre al fin respira.»",
				"«Aunque el Senado nos vigile en cada pasillo, mientras estemos en la misma página ningún decreto me hará retroceder.»",
				"«A veces cierro mis libros solo para escucharte contar cómo estuvo el desayuno con tu padre en la mansión.»"
			],
			"train": [
				"«Ya calculamos de igual a igual, Renpet. A veces pienso que tú estás descifrando el firmamento que yo solo sé nombrar.»",
				"«Probemos la triangulación triple al límite: si dominamos esto, ningún inquisidor podrá falsear nuestros cálculos.»",
				"«Con tu ritmo y mi pizarra cubrimos cada ángulo de la bóveda. Nadie en Aethelgard nos sigue el paso.»"
			],
			"romance": [
				"«Mis manos tiemblan cuando ajustas mis lentes así... He medido mil constelaciones, pero ninguna brilla como tú cuando sonríes.»",
				"«No me pidas objetividad científica cuando me miras debajo de la cúpula. Contigo se me olvida hasta la geometría del cielo.»",
				"«Si este invierno cambiara todo nuestro mundo, quiero que sepas que elegí quedarme a tu lado hace ya muchos años.»"
			],
			"gift_fav": [
				"«Solo tú conoces al detalle lo que hace vibrar mi mesa y mi ánimo. Guardaré este tesoro toda la vida, Renpet.»",
				"«Soren sostiene tu regalo contra el pecho con una sonrisa suave: «Parece una estrella envuelta en papel».»"
			],
			"gift": [
				"«Gracias, Renpet. En días tan tensos cerca del Solsticio, un gesto tuyo me devuelve el equilibrio.»",
				"«Todo lo que viene de ti termina ocupando el lugar de honor en mi observatorio.»"
			],
			"provoke": [
				"«Ya no somos niños jugando a discusiones de aula. Si declaras la guerra a mi investigación, responderé con toda mi fuerza.»",
				"«Te empeñas en alejar al único aliado que entiende lo que late bajo el cielo de Aethelgard... Qué lástima das.»"
			]
		}
	},
	"vespera": {
		1: {
			"support": [
				"«Shh... guarda la voz junto a los establos. No quiero que mi padre me vea descansar antes de los cien golpes de lanza.»",
				"«¿Trajiste linimento nuevo sin decirle a nadie? Eres... menos insoportable de lo que esperaba, hija de Aurelius.»",
				"«¿Crees de verdad que la poesía sirve de algo en una casa militar? A veces me da miedo preguntármelo.»"
			],
			"train": [
				"«¡Más bajo el centro de gravedad! Si miras al suelo cuando giro el asta, ya perdiste la iniciativa.»",
				"«Otra serie de cincuenta paradas limpias. Mi padre dice que el acero no perdona el cansancio, y tiene razón.»",
				"«Bien bloqueado... Tu muñeca absorbe el impacto mucho mejor que la semana pasada.»"
			],
			"gift_fav": [
				"«Vespera se congela al ver el paquete y sus mejillas se tiñen de carmesí: «¿Cómo... sabías que adoraba esto? Gracias».»",
				"«¿Para mí? Lo guardaré bajo llave en mi baúl de campaña donde nadie de mi casa pueda requisarlo.»"
			],
			"gift": [
				"«Un detalle honorable. En la Casa Val-Astra devolvemos siempre cada cortesía con creces.»",
				"«Lo aceptaré como reconocimiento entre compañeras de patio... No te hagas ideas raras.»"
			],
			"provoke": [
				"«¡Retira esa sonrisa condescendiente o te arrancaré los guantes de práctica en tres estocadas!»",
				"«¿Crees que mi apellido es solo desfile y escudos lustrados? ¡Ponte en guardia de verdad!»"
			]
		},
		2: {
			"support": [
				"«Desde que te quedaste aquel día bajo la lluvia, ya no siento que deba demostrarte mi fuerza a gritos cada tarde.»",
				"«Mi padre insiste en enviarme a la guardia del norte tras la academia... Hablar contigo es el único momento en que decido yo mi paso.»",
				"«Toma un sorbo de agua fresca. Escribí dos estrofas nuevas anoche, pero solo te las leeré si me prometes crítica honesta.»"
			],
			"train": [
				"«Subamos el ritmo: sin protecciones en los hombros esta vez. Quiero que sientas el peso real de una carga ducal.»",
				"«Tienes una chispa temible cuando encadenas dos amagues seguidos. Oblígame a retroceder, Renpet.»",
				"«Cuando cruzamos lanzas ahora ya no pienso en mi padre. Pienso solo en el sonido limpio del acero entre tú y yo.»"
			],
			"gift_fav": [
				"«Nadie en mi mansión se ha detenido nunca a pensar qué me gusta de verdad... Me desarmas más que cualquier finta, Renpet.»",
				"«Vespera estrecha el obsequio con manos enguantadas: «Lo llevaré conmigo en cada torneo de este año».»"
			],
			"gift": [
				"«Es un obsequio digno. Me recuerdas que la vida fuera del cuartel también tiene momentos luminosos.»",
				"«Gracias. Prometo devolverte el favor la próxima vez que patrullemos las murallas.»"
			],
			"provoke": [
				"«Si buscas humillar el estandarte de Val-Astra ante las reclutas, prepárate para probar la punta roma contra tus costillas.»",
				"«Qué frío tienes el corazón hoy, Renpet. Y pensar que empecé a creerte distinta a la corte.»"
			]
		},
		3: {
			"support": [
				"«Ahora soy yo quien manda en mi escuadrón, y mi primera orden es que mi patio siempre tenga un sitio libre para ti.»",
				"«Cuando nos miramos entre entrenamientos ya no queda miedo ni sombra del Duque. Solo tú, yo y el cielo abierto.»",
				"«¿Recuerdas cuando creíamos que un fallo en el torneo era el fin del mundo? Qué lejos queda aquello junto a lo que enfrentaremos pronto.»"
			],
			"train": [
				"«Pocos en el Imperio sostienen este intercambio diez segundos. Contigo enfrente siento cada músculo despierto al límite.»",
				"«Ajusta tu guardia alta para el remate final: si alguien intenta tocarte en el Solsticio, tendrá que pasar por encima de ambas.»",
				"«Nuestro acero suena ya como un solo instrumento. Confío en tu flanco como en mi propia vista.»"
			],
			"romance": [
				"«Baja el arma un segundo... Cuando me miras de ese modo, toda mi disciplina marcial se derrite como nieve al sol.»",
				"«Juré dedicar mi vida solo a la lanza, hasta que llegaste tú y me hiciste desear un hogar donde volver al caer la tarde.»",
				"«No tengo versos elegantes para lo que siento ahora... Quédate cerca esta noche y deja que mis manos hablen por mí.»"
			],
			"gift_fav": [
				"«Vespera sonríe suave, sin armadura emocional alguna: «Solo tú logras que mi corazón lata tan tranquilo y tan deprisa a la vez».»",
				"«Este regalo se queda junto a mi cama hasta el Solsticio y mucho después. Gracias por conocerme mejor que nadie.»"
			],
			"gift": [
				"«Lo aprecio mucho más de lo que sé decir en voz alta, Renpet. Gracias por pensar en mí.»",
				"«Cada detalle tuyo me recuerda por qué vale la pena defender esta ciudad.»"
			],
			"provoke": [
				"«La etapa de las armas de madera ha terminado. Si nos conviertes en enemigas, lucharé con todo el peso de Val-Astra.»",
				"«Nunca imaginé que la camarada que admiraba terminaría empuñando tanto desprecio. Nos veremos en la arena.»"
			]
		}
	},
	"kaelen": {
		1: {
			"support": [
				"«Oye, no pongas cara de susto por la humedad del canal. Toma una manzana asada que robamos... digo, que intercambiamos en el mercado.»",
				"«Los críos de abajo ya preguntan cuándo vuelve la señorita de la luz amable. Tienes club de admiradores en el subsuelo.»",
				"«No le cuentes a Lord Aurelius que bajas hasta aquí sin escolta, o nos manda media guardia a tapar los puentes.»"
			],
			"train": [
				"«Salta sobre el brocal izquierdo y cae sin hacer ruido. Si salpicas el agua, los centinelas ya saben tu nombre.»",
				"«En la calle no existe el saludo previo de los torneos. Desvía primero la muñeca y luego responde al golpe.»",
				"«¡Bien esquivado! Para crecer rodeada de alfombras, te mueves entre sombras con soltura sorprendente.»"
			],
			"gift_fav": [
				"«¡Ey! ¿De dónde sacaste esto para un bribón de los canales? ¡Se lo voy a presumir a toda la banda hoy mismo!»",
				"«Kaelen silba asombrado: «Con esto no nos falta ánimo ni medicinas en semanas. Me debes dejar devolvértelo al doble, lucero».»"
			],
			"gift": [
				"«Mira qué detalle de la nobleza... Se agradece que te acuerdes de nosotros ahí abajo, Renpet.»",
				"«No estoy acostumbrado a recibir paquetes limpios y sin trampas. Gracias.»"
			],
			"provoke": [
				"«Qué fácil es juzgar el barro desde el observatorio con estómago lleno, ¿verdad? ¡Lárgate antes de que te abramos paso a pedradas!»",
				"«Así que otra heredera engreída más... Cuidado dónde pisas cuando apaguemos los faroles del canal.»"
			]
		},
		2: {
			"support": [
				"«Cada invierno que logramos medicina sin que muera un chico es medio milagro tuyo. Ya no eres una turista aquí abajo.»",
				"«Subamos un rato al arco alto donde corre aire fresco. A veces hasta un rey de los callejones necesita sol.»",
				"«¿Sabes? La gente allá arriba nos mira como plagas, pero contigo siento que Aethelgard todavía tiene arreglo.»"
			],
			"train": [
				"«Atrapa las tres dagas de madera sin mirar la segunda. Los ojos mienten cuando hay niebla de mercurio.»",
				"«Muévete pegada a mi espalda cuando crucemos el puente estrecho: hoy te enseño cómo desaparecer entre patrullas.»",
				"«Cada semana que pasas entrenando aquí eres más rápida. Casi me da pena por el pobre ladronzuelo que intente asaltarte.»"
			],
			"gift_fav": [
				"«¿Ves por qué los chicos darían su último cobre por ti? Siempre aciertas justo con lo que más falta hace.»",
				"«Kaelen guarda el presente bajo el abrigo con una sonrisa ladeada y sincera: «Eres increíble, lucero».»"
			],
			"gift": [
				"«Un gesto enorme de tu parte, Renpet. En los canales la memoria es larga para lo bueno y para lo malo.»",
				"«Gracias por traer un poco de calor a estas bóvedas húmedas.»"
			],
			"provoke": [
				"«No me hables de leyes si luego cierras los ojos ante el hambre del subsuelo. Esta tregua acaba hoy.»",
				"«Si nos traicionas por ganarte una palmadita del Senado, te juro que nuestras sombras no olvidarán tu puerta.»"
			]
		},
		3: {
			"support": [
				"«A veces pienso en dejar los túneles en buenas manos y abrir una botica honesta... Claro, si tuviera cierta socia testaruda.»",
				"«Aunque el Emperador llene de soldados la plaza mayor, en los canales manda nuestra gente y nadie te pondrá un dedo encima.»",
				"«Ven, siéntate en la baranda del canal viejo conmigo. Contigo al lado, hasta el humo de la ciudad huele a futuro.»"
			],
			"train": [
				"«Ya no te entreno, socia: nos cubrimos las espaldas como iguales. Vamos a sincronizar ese giro doble para la emboscada.»",
				"«Tu agilidad combinada con esa energía tuya... Ninguna patrulla de Alabastro podría encerrarnos ya.»",
				"«Rápida, limpia y sin dudar un instante. Eres mejor sombra que la mitad de mi liga.»"
			],
			"romance": [
				"«Sube al tejado conmigo, Renpet. Desde aquí arriba ni los dioses ni el Emperador pueden decirnos a quién amar.»",
				"«Creí que la libertad era correr solo sin deberle nada a nadie, hasta que descubrí que mi hogar es allá donde tú sonríes.»",
				"«Deja que el mundo entero discuta coronas esta noche; dame tu mano y escapemos un par de horas por las azoteas.»"
			],
			"gift_fav": [
				"«¿Cómo haces para hacer que un tipo sin raíz sienta que tiene algo valioso que guardar? Te debo la vida entera, Renpet.»",
				"«Kaelen te rodea los hombros agradecido: «Esto vale más que todo el contrabando dorado del puerto».»"
			],
			"gift": [
				"«Gracias, preciosa. Mientras sigas acordándote de los olvidados, tendrás un ejército en los canales.»",
				"«Lo llevo conmigo desde esta noche. Suerte si alguien intenta quitármelo.»"
			],
			"provoke": [
				"«Se acabaron las medias tintas entre barrios altos y bajos. Si eliges ser nuestro enemigo, cuida cada esquina.»",
				"«Qué decepción más fría, Renpet. Pensé que bajo esa capa elegante había un corazón libre, no otro verdugo de palacio.»"
			]
		}
	},
	"cassian": {
		1: {
			"support": [
				"«Disculpa que llegue con polvo de archivo en los puños. Escapar diez minutos de los tutores imperiales contigo ya es mi momento favorito.»",
				"«En el Palacio todos compiten por halagarme; tú eres la única que me contradice con argumentos reales. Qué alivio.»",
				"«¿Tu padre de verdad te deja elegir qué libros leer antes de dormir? Qué envidia sana le tengo a tu observatorio.»"
			],
			"train": [
				"«En un salón hostil, quien levanta primero la voz suele perder la votación. Aprende a sostener el silencio cinco segundos.»",
				"«Observa cómo se inclinan los senadores cuando quieren ocultar miedo tras cortesía. Repitamos ese saludo diplomático.»",
				"«Tienes un porte natural que ninguna clase de protocolo puede fabricar. Solo te falta medir el momento exacto del golpe.»"
			],
			"gift_fav": [
				"«Cassian examina el detalle con auténtico asombro: «Hacía años que nadie me regalaba algo sin esperar un decreto a cambio».»",
				"«Es extraordinario... Te aseguro que ningún embajador me ha traído un obsequio elegido con tanto tacto.»"
			],
			"gift": [
				"«Un gesto tan refinado como oportuno. Acepto tu presente con gratitud verdadera, Renpet.»",
				"«Lo colocaré en mi escritorio privado del ala sur para recordar esta tarde tranquila.»"
			],
			"provoke": [
				"«Cuida tus palabras dentro de los muros de Alabastro, Renpet. Un desaire así contra la Corona trae consecuencias reales.»",
				"«¿Pretendes intimidar al heredero imperial como si estuvieras en un patio de armas? Qué imprudencia tan cara.»"
			]
		},
		2: {
			"support": [
				"«Las reuniones del Consejo Secreto se vuelven cada mes más turbias... Cuando paseo contigo por los rosedales recupero la claridad.»",
				"«No importa cuántos informes sellados oculte mi padre; te prometí proteger el nombre de tu hogar y sigo cumpliendo.»",
				"«Ponte este té tibio entre las manos, hace viento frío en las galerías. Háblame de tus últimas excursiones.»"
			],
			"train": [
				"«Hoy ensayaremos réplicas bajo presión de tres senadores hostiles: sonríe mientras desarmas su premisa en dos frases.»",
				"«Tu voz tiene ya la autoridad suficiente para silenciar toda una mesa de consejo. Pulamos el remate final.»",
				"«Cada gesto diplomático que dominas aquí nos ahorra sangre mañana. Lo estás haciendo de maravilla.»"
			],
			"gift_fav": [
				"«¿Recuerdas cuando te dije que en palacio todo tiene precio? Contigo olvido esa regla... Gracias, Renpet.»",
				"«Cassian aprieta el obsequio con una sonrisa serena: «Has acertado en lo más profundo de mis gustos».»"
			],
			"gift": [
				"«Aprecio enormemente que hayas cruzado media capital para traerme esto en persona.»",
				"«En tiempos tan tensos, un detalle honesto vale más que un tratado entero.»"
			],
			"provoke": [
				"«Si buscas convertir la Mansión Solar en rival declarada del Trono, el Senado responderá con todo su peso.»",
				"«Me hiere comprobar que prefieres el conflicto abierto a la alianza que te tendí con sinceridad.»"
			]
		},
		3: {
			"support": [
				"«El Palacio entero contiene la respiración ante la llegada de tus veinte años, pero junto a ti soy capaz de desafiar a mi propia sangre.»",
				"«Ya no pienso heredar un imperio cimentado en secretos crueles. Contigo diseñaré un reino donde la luz no exija víctimas.»",
				"«Mira estos mapas nuevos del Senado: la mitad de los votos ya miran hacia nosotros antes que hacia el trono antiguo.»"
			],
			"train": [
				"«En los grandes debates de este año nadie podrá doblegarnos si coordinamos el cierre. Tú marcas la idea, yo sello el decreto.»",
				"«Tu magnetismo llena la sala antes siquiera de abrir los labios. Trabajemos solo la elegancia del golpe final.»",
				"«Actúas como una verdadera estadista, Renpet. A veces pienso que tú mereces esta corona mucho más que yo.»"
			],
			"romance": [
				"«Si el trono de Aethelgard exige tu sacrificio para sostenerse, entonces prenderé fuego al trono con mis propias manos por ti.»",
				"«He aprendido a callar mil deseos por deber, pero frente a ti me declaro vencido: quiero caminar contigo, no reinar solo.»",
				"«Dame la mano bajo las columnas de loto, Renpet. Que los cronistas escriban que el heredero eligió tu corazón sobre cualquier pacto.»"
			],
			"gift_fav": [
				"«Este regalo ocupará el lugar más cercano a mi sello personal. Gracias por darme fuerzas cuando el peso del trono asfixia.»",
				"«Cassian inclina levemente la cabeza tocando tus dedos: «Nadie me ha comprendido como tú en todo el Imperio».»"
			],
			"gift": [
				"«Lo llevaré conmigo durante las sesiones más difíciles de este Solsticio como un recordatorio tuyo.»",
				"«Tu generosidad y nobleza iluminan hasta los pasillos más fríos del Palacio.»"
			],
			"provoke": [
				"«Has cruzado una línea que ni la fama de tu padre podrá excusar ante la Guardia Real.»",
				"«Que así sea entonces. Si rechazas toda salida justa, me encontrarás defendiendo el orden con la espada del trono.»"
			]
		}
	},
	"mirari": {
		1: {
			"support": [
				"«Qué alegre suena hoy el roce de tu capa sobre los escalones, Renpet. Traes olor a hierba tibia y hogar.»",
				"«Los niños del coro preguntan cuándo volverás a sentarte entre los arcos a escuchar nuestras escalas nocturnas.»",
				"«No hace falta hablar si vienes cansada de estudiar... Apoya los brazos en el mármol y escucha el agua correr.»"
			],
			"train": [
				"«Deja que el aliento baje al pecho antes de entonar la primera nota; una voz forzada rompe la armonía del aire.»",
				"«Escucha la vibración de esta cuerda de plata y responde solo cuando la sala entera esté quieta.»",
				"«Tienes un timbre clarísimo, como campana al alba. Cuando confías en tu pulso, todo el anfiteatro escucha.»"
			],
			"gift_fav": [
				"«¡Oh! Siento el perfume y la textura de este regalo entre mis dedos... Es mi favorito de toda Aethelgard, ¿cómo lo supiste?»",
				"«Mirari sonríe luminosa abrazando el presente: «Suena casi como una caricia cálida para el alma».»"
			],
			"gift": [
				"«Qué delicadeza tienes al elegir, Renpet. Mi arpa guardará el eco de esta tarde contigo.»",
				"«Gracias de corazón; hasta la piedra blanca del coliseo parece cantar cuando llegas tú.»"
			],
			"provoke": [
				"«Qué sonido tan áspero y herido brota hoy de tu garganta... Por favor, no conviertas tu fuerza en crueldad.»",
				"«Si eliges pisotear a los débiles, ni la luz más pura podrá disimular la disonancia en tu espíritu.»"
			]
		},
		2: {
			"support": [
				"«Cada mes percibo dos ritmos en ti más nítidos... No tengas miedo de escucharte: ninguna música nació de una sola nota.»",
				"«Las sacerdotisas mayores murmuran demasiado en el Santuario, pero aquí en las gradas el aire sigue siendo sincero.»",
				"«Quédate un momento tomando aire junto al escenario; tu padre estaría orgulloso de cuánto cuidas a quienes te rodean.»"
			],
			"train": [
				"«Hoy armonizaremos a dos voces simultáneas: no temas sostener el intervalo extraño sin perder tu propio compás.»",
				"«Tu gracia en movimiento supera ya a mis mejores recitales. Deja que la música nazca de tu corazón, no del miedo.»",
				"«Cierra los ojos conmigo y escucha el rebote de la nota contra el mármol: ahí reside la calma verdadera.»"
			],
			"gift_fav": [
				"«Mirari inclina el rostro emocionada al palpar el obsequio: «Nunca pensé recibir un detalle tan lleno de ternura».»",
				"«Guardas una gentileza tan rara en un mundo tan rígido... Este regalo cantará conmigo cada recital.»"
			],
			"gift": [
				"«Tu amistad es el acorde más sereno que he oído en años, Renpet. Muchas gracias.»",
				"«Qué obsequio tan cálido. Siento la paz con la que elegiste traerlo hasta aquí.»"
			],
			"provoke": [
				"«Siento una tormenta fría cortando tu aura como vidrio roto. Si no te detienes, nos enfrentarás a todos.»",
				"«Mi deber sagrado me prohíbe callar cuando alguien abraza la oscuridad por orgullo.»"
			]
		},
		3: {
			"support": [
				"«Pronto todo el mundo querrá decidir quién eres en el Solsticio... Ven aquí siempre que necesites recordar tu propia voz.»",
				"«He compuesto un preludio entero pensando en cómo resuenan tus pasos al cruzar el coliseo al atardecer.»",
				"«No importa cuánto ruja el cielo antes del eclipse; nuestras manos juntas encuentran siempre la melodía justa.»"
			],
			"train": [
				"«Sostenemos el Canto Mayor sin vacilar un segundo. Tu espíritu suena fuerte, libre y entero.»",
				"«Pulsa la cuerda al unísono conmigo: esta armonía es capaz de calmar incluso una tormenta estelar.»",
				"«Ya no soy tu maestra en música, Renpet; somos un coro que hace contener el aliento hasta a la alta clerecía.»"
			],
			"romance": [
				"«Mis ojos no ven las estrellas del cielo, pero cuando toco tu rostro siento la luz más hermosa de la creación.»",
				"«He escuchado miles de voces en este anfiteatro y ninguna me ha hecho temblar el pecho como el sonido de tu respiración.»",
				"«Quédate un momento más conmigo al pie del escenario... Quiero aprender cada latido tuyo de memoria.»"
			],
			"gift_fav": [
				"«Mirari sostiene tus manos sobre el regalo con lágrimas suaves: «Me haces sentir vista, amada y entera».»",
				"«Si alguna vez te sientes sola bajo el cielo grande, recuerda que este obsequio y mi canto son siempre tuyos.»"
			],
			"gift": [
				"«Gracias, amor mío... perdón, gracias por acordarte siempre de traer luz a mis gradas.»",
				"«Cada presente tuyo vibra con una sinceridad que ningún dogma podrá imitar jamás.»"
			],
			"provoke": [
				"«El sonido de tu alma se ha vuelto afilado como el acero de un verdugo. Tendré que alzar el Canto de Clausura si sigues así.»",
				"«Qué dolor tan hondo escuchar cómo arrojas lejos toda compasión... Adiós, Renpet.»"
			]
		}
	},
	"zephyr": {
		1: {
			"support": [
				"«...No es común que alguien se asome a este estanque sin miedo ni súplicas vanas. Curiosa niña.»",
				"«El reflejo tiembla cuando ríes por cosas tan simples de la superficie... Supongo que allá arriba el aire sí sabe a algo.»",
				"«Quédate solo un momento mientras cae el crepúsculo. Hasta la quietud del cristal descansa cuando hablas.»"
			],
			"train": [
				"«No intentes forzar la resonancia a golpes. Abre la palma sobre el agua y deja que el eco responda a tu pulso.»",
				"«Equilibra gravedad y aliento al mismo tiempo; si dudas, las ondas se dispersan antes de formar anillo.»",
				"«Curioso... aprendes el ritmo oculto de la corriente más deprisa que los viejos astrólogos de la Torre.»"
			],
			"gift_fav": [
				"«¿Para un reflejo tras el cristal...? Qué objeto tan singular. Su eco vibra exactamente al compás de mis cadenas antiguas.»",
				"«La superficie se ilumina con chispas violetas suaves: «Hacía siglos que nada me traía un recuerdo tan tibio».»"
			],
			"gift": [
				"«Dejas un obsequio mortal al borde del agua... Eres sin duda la guardiana más extraña que haya existido.»",
				"«Acepto tu ofrenda en silencio. No sé si comprendes lo que significa recordar la gentileza.»"
			],
			"provoke": [
				"«Hablas con la soberbia exacta de quienes forjaron estas cadenas de oro... Algún día mirarás el reflejo sin poder mentirte.»",
				"«Si quieres tratarme como a un monstruo encerrado, adelante; veremos quién resiste más cuando cruja el cristal.»"
			]
		},
		2: {
			"support": [
				"«Hoy sentí el olor del pan recién horneado a través de tus manos... Qué extraño milagro resulta vivir cerca del hogar de Aurelius.»",
				"«Las cadenas doradas ya no queman tanto cuando te sientas a conversar al borde del agua en calma.»",
				"«Dime, ¿cómo es elegir una canción o un vestido simplemente porque te gusta al despertar? Cuéntamelo despacio.»"
			],
			"train": [
				"«Sincroniza tu respiración con el segundo latido de tu pulso: ahí se concentra toda la fuerza sin herirte.»",
				"«Suelta la tensión de los hombros y dibuja un círculo sobre el agua; tu resonancia ya responde al pensamiento.»",
				"«Si alguna vez desatas esta tormenta en combate, recuerda mantener tu voluntad humana bien anclada en el centro.»"
			],
			"gift_fav": [
				"«Zephyr inclina la cabeza tocando el cristal frente a tu obsequio: «Casi siento el calor de tus dedos al atravesar este espejo».»",
				"«Nadie en mil inviernos había recordado qué nos une... Guardaré esto donde no llegue el frío.»"
			],
			"gift": [
				"«Tus gestos sencillos desarman más cadenas que cualquier llave arcana, Renpet.»",
				"«Gracias. Cada vez que vuelves al estanque sin desprecio, el agua parece un poco menos oscura.»"
			],
			"provoke": [
				"«¿Miedo? ¿O el desprecio heredado de tus maestros? No levantarás muros eternos sobre una verdad que respira contigo.»",
				"«Sigue apretando los barrotes y comprobarás qué ocurre cuando el cielo decida cobrar su deuda.»"
			]
		},
		3: {
			"support": [
				"«Pronto el firmamento volverá a abrirse sobre esta ciudad. Y por primera vez en eones, no quiero huir: quiero caminar a tu lado.»",
				"«El pan caliente, las lluvias de otoño, las risas junto al fuego... Me enseñaste a amar este mundo frágil sin querer devorarlo.»",
				"«Cuando nos reflejamos juntos en el estanque esta noche, ya no sé dónde empieza mi libertad y dónde tu corazón.»"
			],
			"train": [
				"«Nuestros dos pulsos vibran ya en perfecta armonía: despliega el arco de gravedad y observa cómo el cielo se inclina.»",
				"«Domina el último compás sin ceder ni un ápice de tu conciencia humana. Juntos somos invencibles en cualquier plano.»",
				"«Ni jaula ni carcelera: cuando canalizas mi poder así, siento que volvemos a volar libres bajo las estrellas.»"
			],
			"romance": [
				"«Nos arrojaron bajo el mismo cielo creyendo que la distancia nos apagaría, Renpet... y en cambio enseñaste a una sombra a esperar el alba contigo.»",
				"«Si el cristal al fin se rompe el día del Solsticio, juro que lo primero que sostendré en mis manos será tu rostro.»",
				"«Mil siglos de eternidad vacía no valen un solo minuto en el que apoyas la palma sobre este reflejo y sonríes.»"
			],
			"gift_fav": [
				"«Las aguas reflejan mil destellos dorados y violetas al recibir tu presente: «Eres la estrella más libre de todo este cielo, Renpet».»",
				"«Ningún pacto divino pesa tanto como un regalo dado con tu corazón libre.»"
			],
			"gift": [
				"«Gracias, compañera mía. Cada gesto tuyo me recuerda por qué vale la pena romper la noche.»",
				"«Lo guardaré junto a la luz primera que compartimos.»"
			],
			"provoke": [
				"«Entonces que el día de tu vigésimo cumpleaños decida en llamas cuál de los dos sobrevive a la mentira.»",
				"«Desprecias la única mano que conoce la verdad de tu origen... Que la Diosa tenga compasión de tu orgullo.»"
			]
		}
	},
	"lyra": {
		1: {
			"support": [
				"«Si vas a sentarte en mi glorieta del Conservatorio, al menos dime qué cotilleo corre hoy por la Academia de Armas.»",
				"«Lady Lyra oculta una sonrisa detrás del abanico: «¿Sabes que eres mucho más directa y refrescante que la mitad de estas herederas aburridas?».»",
				"«Toma un macarrón de pistacho antes de que llegue Madame Isolde. Prometo no decir que entrenaste esgrima esta mañana.»"
			],
			"train": [
				"«Gira la muñeca al cambiar de octava, no todo el antebrazo. La gracia consiste en hacer que lo difícil parezca aire.»",
				"«En un salón de baile, tu postura debe anunciar que mandas incluso antes de decir «buenas tardes». Inténtalo otra vez.»",
				"«Mucho mejor... Casi logras engañar a todo el corredor haciéndoles creer que naciste entre sedas reales.»"
			],
			"gift_fav": [
				"«¿Eh...? ¡Esto es de la colección limitada de los plateros reales! Ah... quiero decir, acepto encantada un presente tan distinguido.»",
				"«Los ojos verdes de Lyra brillan genuinos sin pose alguna: «Cómo adivinaste exactamente lo que deseaba, Renpet? Muchas gracias».»"
			],
			"gift": [
				"«Qué atención más gentil. La Casa Meridia sabe valorar a quien demuestra refinamiento.»",
				"«Un obsequio encantador... Tal vez después te invite a mi palco en el próximo recital.»"
			],
			"provoke": [
				"«¿Disculpa? ¿La pupila de un observatorio polvoriento pretende darme lecciones de linaje? Qué vulgaridad.»",
				"«Si buscas enemistarte con la Casa Meridia, pronto descubrirás cuántos salones se cierran con un golpe de abanico.»"
			]
		},
		2: {
			"support": [
				"«Qué respiro poder soltar la sonrisa perfecta cinco minutos cuando te sientas conmigo tras el Conservatorio...»",
				"«Las cuentas de mi casa siguen apretando, pero saber que no me miras por encima del hombro me devuelve el pulso.»",
				"«Toma una taza de té blanco. Hoy practiqué tanto que tengo los dedos dormidos, prefiero solo escucharte hablar.»"
			],
			"train": [
				"«Sincronicemos el compás elegante con una réplica mordaz de salón: la diplomacia es también un duelo, querida.»",
				"«Tu presencia escénica ya opaca a las damas veteranas del Palacio. Ajusta solo ese último giro de mirada al público.»",
				"«Cada ensayo juntas suena más brillante... Ojalá el Senado entero tuviera que aplaudirnos de pie algún día.»"
			],
			"gift_fav": [
				"«Lyra guarda silencio un segundo bajando su abanico con emoción genuina: «Eres la única amiga de verdad que tengo en toda la corte».»",
				"«No sabes cuánto ánimo me da recibir algo así precisamente esta temporada... Gracias, Renpet.»"
			],
			"gift": [
				"«Qué detalle tan cálido. Gracias por acordarte siempre de mí entre tanto estudio y entrenamiento.»",
				"«Lo llevaré en mi estuche de recitales para tener suerte en los eventos del año.»"
			],
			"provoke": [
				"«No confíes tanto en tu fama recién nacida; en los salones de alabastro una caída duele el triple.»",
				"«Si disfrutas viendo a mi familia al borde del abismo, entonces serás la primera en sufrir cuando regresemos a la cima.»"
			]
		},
		3: {
			"support": [
				"«Ahora que la Casa Meridia ha vuelto a ponerse en pie gracias a tu respaldo, mis salones enteros son también tu refugio, Renpet.»",
				"«Me río sola pensando en el primer día que intenté intimidarte en el pasillo... Qué ciega estuve al no ver tu valor.»",
				"«Siéntate conmigo junto al ventanal de alabastro. Hoy no hay acreedores ni rumores: solo dos sobrevivientes mirando la capital.»"
			],
			"train": [
				"«Dominas el salón como una auténtica reina, y aun así seguimos puliendo cada acorde juntas. Nadie se compara contigo.»",
				"«Arpa, voz y elocuencia unidos al milímetro: esta noche dejaremos sin palabras hasta al Consejo Supremo.»",
				"«Contigo en escena siento que puedo tocar cualquier partitura prohibida frente al mismísimo Emperador.»"
			],
			"romance": [
				"«Si alguna vez dejo caer este abanico frente a todo el Palacio, será solo para sostener tu mano sin que me importe quién susurre.»",
				"«Toda mi vida me enseñaron a enamorar a un título conveniente... y entonces llegaste tú y rompiste todas mis reglas con una sonrisa.»",
				"«Quédate un baile más en el jardín privado conmigo, Renpet. Esta noche no interpreto ningún papel para la corte.»"
			],
			"gift_fav": [
				"«Lyra besa el borde de su abanico y te sonríe dulcemente: «Cada día me convences más de que eres el mejor tesoro de Aethelgard».»",
				"«Lo atesoraré frente a todas las joyas de la familia Meridia. Gracias, mi preciosa.»"
			],
			"gift": [
				"«Tu afecto es el único lujo que de verdad necesito en este palacio, Renpet.»",
				"«Qué gesto tan hermoso... Gracias por cuidarme incluso cuando cargas con todo el peso del cielo.»"
			],
			"provoke": [
				"«Que el Gran Salón tome nota: entre tú y yo ya no cabe cortesía alguna, solo guerra abierta de influencia.»",
				"«Has elegido pisotear el último puente entre nuestras casas. Disfruta tu triunfo mientras dure.»"
			]
		}
	},
	"caelum": {
		1: {
			"support": [
				"«Qué haces trayendo pan caliente al puesto de guardia, cachorra? ...Bueno, no digo que no tenga hambre después de dos turnos seguidos.»",
				"«Caelum se rasca la nuca desviando la vista: «No creas que porque eres hija del famoso Aurelius te voy a dejar cargar cajas pesadas... ¡bueno, agarra esa esquina!».»",
				"«En el camino viejo nos contamos historias malas junto a los carros para no dormirnos. Siéntate un minuto en el heno seco.»"
			],
			"train": [
				"«¡Baja la cadera y no cruces los talones! Un terreno lleno de barro y piedras cobra caro los saltos de salón.»",
				"«Mira la sombra de mi hombro antes de intentar el desvío. La velocidad sin equilibrio solo te mete más rápido en el golpe.»",
				"«Tsk... Tienes reflejos endiablados cuando te enfadas. Me gusta cuando dejas de pelear bonito y peleas para ganar.»"
			],
			"gift_fav": [
				"«¿Eh? ¿Esto es de las buenas tiendas para alguien como yo? Caelum suelta una risa breve y agradecida: «Vale, novata, hoy te has ganado mi respeto».»",
				"«Un perro callejero no olvida quién le tira buena carne y buen acero... Te debo una guardia gratis, Renpet.»"
			],
			"gift": [
				"«No hacía falta regalarle nada a un mercenario, pero tampoco soy tan tonto como para rechazar un buen detalle.»",
				"«Lo guardo en mi petate. Si alguna vez te cercan en un camino, grita mi apodo.»"
			],
			"provoke": [
				"«Otra mimada con espada reluciente creyéndose guerrera porque entrenó sobre alfombras... ¡Saca el acero y vamos a ver!»",
				"«Sigue hablando así de los escoltas de caravana y te juro que la próxima emboscada la miras desde el barro.»"
			]
		},
		2: {
			"support": [
				"«Desde que te conté lo de mi hermano en la frontera duermo un poco mejor... Raro en mí confiar algo así a nadie.»",
				"«Tu viejo tenía razones más duras de lo que pintan las canciones de taberna, ¿verdad? Empiezo a respetar al apellido Aurelius.»",
				"«Toma este termo de té especiado que preparan en la parada sur. Pica en la garganta, pero te quita cualquier frío.»"
			],
			"train": [
				"«Hoy entrenamos contra dos ángulos a la vez: aprende a usar la gravedad de tu caída para partir la guardia enemiga.»",
				"«Tu golpe tiene peso de veteranía ya, Renpet. Sigue así y los contratos de alto riesgo serán nuestros sin competencia.»",
				"«Nada de dudas al entrar a distancia corta: el que entra dudando sale en camilla.»"
			],
			"gift_fav": [
				"«Caelum gira el regalo entre sus dedos llenos de cicatrices y sonríe de lado: «Vaya puntería tienes para saber justo lo que necesito en ruta».»",
				"«En la Guardia de Ceniza nadie se toma estas molestias por un compañero. Tú eres distinta a toda esta ciudad.»"
			],
			"gift": [
				"«Gracias, niña. Ya no eres ninguna novata: eres la socia más fiable del patio.»",
				"«Un buen detalle vale oro cuando llevas tres noches seguidas escoltando carros bajo la lluvia.»"
			],
			"provoke": [
				"«Si el orgullo heredado te impide ver la sangre que costó tu paz en esta capital, entonces no somos compañeros ni de camino.»",
				"«Afila esa lengua todo lo que quieras; en cuanto pongas un pie fuera de las murallas resolveremos las cuentas.»"
			]
		},
		3: {
			"support": [
				"«Mis chicos del gremio ya hablan de ti como si fueras su capitana honoraria. Y la verdad... tienen bastante razón.»",
				"«Cuando pase el alboroto de tus veinte años, ven a cabalgar por los collados del norte conmigo aunque sea una tarde entera.»",
				"«Aquí estoy, limpiando el mandoble y guardando espacio junto a la hoguera por si te apetece escapar un rato de tanto protocolo.»"
			],
			"train": [
				"«Filo, paso y cadera en perfecta sintonía. Me cuesta seguirte el ritmo ya, y eso que me llaman el mejor sabueso del gremio.»",
				"«Si alguien del Senado o del cielo intenta acorralarte este año, tendrá que morder mi acero primero.»",
				"«Entrenar contigo dejó hace mucho de ser práctica: es el mejor combate de la semana.»"
			],
			"romance": [
				"«Cuando termine el contrato de invierno voy a colgar esta capa gris... Si quieres venir a ver un amanecer sin alarmas, solo dilo.»",
				"«Caelum te toma suavemente de la barbilla sin apartar sus ojos ámbar: «Nunca pensé desear echar raíces... hasta que apareciste tú».»",
				"«No soy hombre de poemas como los de Palacio, pero mi espada, mi espalda y mi corazón entero te pertenecen, Renpet.»"
			],
			"gift_fav": [
				"«¿Por qué siempre logras desarmar al tipo más arisco del Patio con un solo gesto? Gracias, compañera mía.»",
				"«Caelum sonríe abiertamente guardando el presente cerca del pecho: «Esto vuelve a casa conmigo después de cada viaje».»"
			],
			"gift": [
				"«Gracias por estar ahí siempre, Renpet. Contigo cerca hasta el hierro viejo brilla.»",
				"«Se agradece muchísimo, de verdad. No cambiaría nuestra alianza ni por un ducado.»"
			],
			"provoke": [
				"«Se acabaron las medias sonrisas de entrenamiento. A partir de hoy eres contrato hostil para el Perro Gris.»",
				"«Qué desperdicio de talento echado a perder por arrogancia... Nos veremos las caras cuando caiga la noche.»"
			]
		}
	}
}

# ==============================================================================
# COMENTARIOS CONTEXTUALES POR ATUENDO EQUIPADO
# ==============================================================================
const OUTFIT_COMMENTS: Dictionary = {
	"soren": {
		"solar": "«Ese Uniforme Solar te sienta imponente, aunque debo admitir que impone respeto hasta cerca de mis libros.»",
		"astronomer": "«¡Llevas la Túnica de Astrónoma Real! Con esos astrolabios bordados casi pareces colega oficial de la Torre.»",
		"gala": "«¿Esa Gala de Alabastro es para alguna recepción hoy? Luces... verdaderamente deslumbrante, Renpet.»",
		"horizon": "«Esa Cota del Horizonte parece diseñada para expediciones muy largas. Cuídate mucho cuando salgas ahí fuera.»"
	},
	"vespera": {
		"solar": "«¡Así se viste una verdadera rival de armas! Ese Uniforme Solar grita disciplina por cada costura.»",
		"astronomer": "«¿Túnica de erudita hoy? No creas que por cambiar de ropa voy a dejarte ganar la próxima carga en el patio.»",
		"gala": "«Te queda sorprendentemente bien la seda imperial... Aunque me cuesta reconocerte sin guantes de combate.»",
		"horizon": "«Buena cota de frontera. Resistente, ágil y sin adornos inútiles para el combate real.»"
	},
	"kaelen": {
		"solar": "«Uf, brillas tanto con ese Uniforme Solar que hasta los guardias del canal me miran doble si paseo contigo.»",
		"astronomer": "«Pintas muy seria con esa capa azul estrellada... Oye, ¿los bolsillos sirven igual para esconder confituras?»",
		"gala": "«¿Bajaste a los acueductos con Gala de Alabastro?! ¡Cuidado los charcos, princesa, que esa seda cuesta media renta!»",
		"horizon": "«Esa Cota del Horizonte sí es ropa práctica de verdad. Con eso cruzas media ciudad sin rasgarte un pelo.»"
	},
	"cassian": {
		"solar": "«Llevas el porte exacto del Uniforme Solar. Me recuerdas a los mejores días de la caballería de tu padre.»",
		"astronomer": "«La Túnica de Astrónoma Real resalta tu ingenio... Hasta varios senadores comentaron tu distinción académica.»",
		"gala": "«Esa Gala Real de Alabastro ilumina todo el jardín, Renpet... Harías girar cada mirada de la corte entera.»",
		"horizon": "«Esa cota pesada sugiere que planeas salir pronto de las murallas. Te ruego que no corras riesgos innecesarios.»"
	},
	"mirari": {
		"solar": "«Siento el tintinear firme y claro del Uniforme Solar al caminar; suenas decidida y valiente.»",
		"astronomer": "«La tela pesada de tu Túnica de Astrónoma murmura como páginas antiguas pasando suavemente.»",
		"gala": "«¡Qué seda tan fina y luminosa en tu Gala Real! Casi puedo oír las palmas del público rodeándote al caminar.»",
		"horizon": "«Tu Cota del Horizonte tiene aroma de metal limpio y cuero protector... Prométeme volver sana de cada viaje.»"
	},
	"zephyr": {
		"solar": "«Qué irónico verte vestir los emblemas dorados de la corte solar con ese brillo tan vivo en tus ojos...»",
		"astronomer": "«Estrellas cosidas en azul profundo... casi parece que llevaras un retazo de mi propio cielo nocturno.»",
		"gala": "«Elegancia de palacio reflejada sobre el agua nocturna. Hasta los antiguos heraldos quedarían boquiabiertos.»",
		"horizon": "«Armadura para cruzar horizontes perdidos... Estás lista para caminar mucho más allá de estas murallas.»"
	},
	"lyra": {
		"solar": "«Mmm, audaz elección ese Uniforme Solar; le da un aire heroico fascinante a tu presencia incluso en el palacio.»",
		"astronomer": "«Vaya, azul estrellado y bordados dorados... Un estilo académico exquisito, aunque quizá algo serio para la fiesta.»",
		"gala": "«¡Oh, esa Gala Real de Alabastro es de los talleres de primera línea! Con ese corte nos robarías todos los cumplidos de la sala.»",
		"horizon": "«¿Ropa de exploración aquí en el jardín? Te confieso que ese aire aventurero tiene mucho más encanto del que admitiría en público.»"
	},
	"caelum": {
		"solar": "«Lustroso Uniforme Solar... Por suerte sé que no es solo adorno de desfile contigo dentro.»",
		"astronomer": "«¿Bata de estudiosa para venir al patio? Mientras no te tropieces con el dobladillo al esquivar, todo bien.»",
		"gala": "«¿Vienes al establo con Gala Imperial? Cuidado con el polvo de paja o Lady Lyra te va a declarar la guerra.»",
		"horizon": "«¡Ahora sí hablamos! Esa Cota del Horizonte aguanta golpes serios y lluvia fría sin quejarse.»"
	}
}

# ==============================================================================
# COMENTARIOS CONTEXTUALES POR MUTACIÓN / ESTADO DEL SELLO (RESPETANDO TIER DE SECRETO)
# ==============================================================================
const MUTATION_COMMENTS_TIER0: Dictionary = {
	"soren": "Soren inclina sus lentes intrigado: «Es curioso... la tinta de mi astrolabio tiembla suavemente cada vez que acercas tu mano.»",
	"vespera": "«¿Sientes frío en la muñeca? Tu aura se sintió un instante tan densa como hierro antiguo antes de empezar.»",
	"kaelen": "«Oye, lucero... ¿siempre destelló así esa chispa extraña en tus pupilas cuando cae la penumbra en el canal?»",
	"cassian": "«Noto un brillo muy singular rodeando tus hombros hoy, Renpet. A veces pareces llevar toda una constelación encima.»",
	"mirari": "«Tu pulso suena distinto esta tarde... más cristalino, como si otra nota armónica vibrara suavemente bajo tu voz.»",
	"zephyr": "«El cristal del estanque responde con fuerza a esa huella nueva sobre tu piel... Estás cambiando deprisa.»",
	"lyra": "«Qué curioso resplandor rodea tus manos bajo la luz de los candelabros... Hasta parece un encantamiento de joyería fina.»",
	"caelum": "«¿No notas las chispas en el aire cerca de tus nudillos? Hay algo salvaje bullendo debajo de esa calma tuya.»"
}

const MUTATION_COMMENTS_DEEP: Dictionary = {
	"voz_del_prisionero": {
		"soren": "«Tus ojos muestran ese halo violeta doble del Eco del Espejo... Cuidado en el Senado si un inquisidor se fija demasiado.»",
		"vespera": "«Ese destello heterocromático impondría miedo hasta a un batallón ducal. Pero sigues siendo tú, Renpet.»",
		"kaelen": "«Vaya mirada violeta gastas ahora... Hasta las sombras del subsuelo parecen apartarse respetuosas a tu paso.»",
		"cassian": "«El Eco del Espejo brilla nítido en tu iris; la Alta Clerecía mataría por ocultar una resonancia así, así que quédate cerca de mí.»",
		"mirari": "«Oigo claramente la voz compañera tras el Eco del Espejo cantando al unísono contigo... No te abandonará jamás.»",
		"zephyr": "«Llevas mi eco despierto en la mirada. Cada paso tuyo estrecha la distancia entre este espejo y el alba.»",
		"lyra": "«Ese matiz violeta en tus ojos es hipnótico y algo inquietante... Prométeme que sabes controlar lo que responde al otro lado.»",
		"caelum": "«Esos ojos de doble luz dicen a gritos que cargas una bestia antigua dentro... Mientras siga de tu lado, bien por mí.»"
	},
	"pulso_cristalino": {
		"soren": "«Las motas cristalinas flotando junto a tu hombro mantienen una frecuencia perfecta... Es alquimia estelar viva.»",
		"vespera": "«Tu resistencia física con esas partículas de cuarzo es absurda; apenas sangras dos segundos antes de cerrar el corte.»",
		"kaelen": "«Brillas entre las columnas como polvo de diamante... Suerte que nadie intenta robarte la luz ya.»",
		"cassian": "«Ese Pulso Cristalino te da una serenidad sobrenatural incluso bajo la mirada más aguda del Consejo.»",
		"mirari": "«Cada mota de cristal suena como una campanilla diminuta sanando tus heridas en silencio.»",
		"zephyr": "«El cuarzo del cráter se ha fundido con tu sangre mortal... Una mezcla fascinante de permanencia y cambio.»",
		"lyra": "«Esas chispas cristalinas en el aire hacen que hasta la luz del palacio parezca seguirte a propósito.»",
		"caelum": "«Con esa regeneración cristalina en tus venas vas a enterrarnos a todos los veteranos del patio.»"
	},
	"sangre_pesada": {
		"soren": "«Tu campo gravitatorio local es tan denso que los relojes de arena de mi mesa se retrasan un segundo contigo cerca.»",
		"vespera": "«Se siente en el impacto contra el escudo... Tienes la firmeza inamovible de una fortaleza.»",
		"kaelen": "«¡Ja! Con ese temple pesado ningún golpe de los guardias ni las marchas largas logran doblarte ya.»",
		"cassian": "«Algunas damas del conservatorio murmuran que tu aura pesa demasiado en los salones, pero a mí me inspira respeto absoluto.»",
		"mirari": "«Tu melodía hoy suena grave, honda y protectora como las raíces mismas de la tierra.»",
		"zephyr": "«La gravedad del abismo responde a tu sangre... Ten cuidado de no olvidar también la ligereza mortal.»",
		"lyra": "«En el baile tu paso suena más grave que de costumbre... Casi parece que la música entera girara alrededor de tu peso.»",
		"caelum": "«Por los clavos... Siento la presión del aire solo al estar a dos pasos de ti. Qué tanque humano te has vuelto.»"
	},
	"paso_de_luz": {
		"soren": "«El polvo estelar difumina tu silueta al girar; casi desapareces del foco del telescopio en pleno día.»",
		"vespera": "«¡Tus fintas con ese rastro de luz son casi imposibles de seguir con la vista!»",
		"kaelen": "«Con ese Paso de Luz pasas frente a tres aduaneros sin que suenen ni sus llaves. Eres la envidia del gremio.»",
		"cassian": "«Apareces en los jardines con una gracia tan veloz y silenciosa que hasta mis escoltas llegan tarde a anunciar tu nombre.»",
		"mirari": "«Tu paso ya no roza la piedra; suena como una ráfaga de aire libre flotando sobre las gradas.»",
		"zephyr": "«El cometa te prestó su velocidad; incluso tus cadenas imaginarias parecen incapaces de alcanzarte ya.»",
		"lyra": "«Desaparecer y aparecer así entre columnas hace que todo el salón gire la cabeza hacia ti sin remedio.»",
		"caelum": "«Para ser hija de caballero pesado te deslizas con más sigilo que cualquier explorador nocturno.»"
	},
	"low_seal": {
		"soren": "«Tu sello muestra fisuras muy finas bajo esa luz, Renpet... Por favor, descansa o busca armonía antes de que crezca la grieta.»",
		"vespera": "«¿Estás herida? Noto ese fulgor agrietado en tu silueta... No te sobreesfuerces sola cuando puedes llamarme.»",
		"kaelen": "«Oye, lucero, no me gusta nada cómo tiembla esa chispa roja alrededor de tus manos... Tómate un respiro esta semana.»",
		"cassian": "«Palideciste al cruzar el dintel, Renpet. Si esa carga estelar empieza a lastimarte, dime cómo ayudar.»",
		"mirari": "«El latido dentro de tu pecho suena tenso como una cuerda a punto de quebrarse... Escúchame cantar un momento, por favor.»",
		"zephyr": "«Las grietas del sello arden contra mi cristal... Ten cuidado, guardiana: si se rompe sin equilibrio no habrá retorno limpio.»",
		"lyra": "«Aunque disimules bien la postura, estás pálida y tensa bajo ese brillo... Deja las apariencias un minuto y respira.»",
		"caelum": "«Pareces estar peleando una guerra entera por dentro antes siquiera de pisar el patio... Descansa un bimestre si hace falta.»"
	}
}

# ==============================================================================
# ENCUENTROS CRUZADOS ENTRE DOS PERSONAJES EN UN MISMO DISTRITO
# ==============================================================================
const CROSS_ENCOUNTERS: Dictionary = {
	"enc_torre_soren_cassian": {
		"id": "enc_torre_soren_cassian", "district": "torre", "npcs": ["soren", "cassian"],
		"title": "El Precio de los Mapas Estelares",
		"scene": "Al subir a la Torre de Cristal encuentras a Soren bloqueando el acceso al archivo sur frente al Príncipe Cassian.\n—Soren: «Alteza, estas mediciones pertenecen al Observatorio libre, no a los censores del Senado.»\n—Cassian: «Y si un censor ve esa anomalía sin mi firma antes que yo, clausurarán tu torre entera mañana, Soren.»",
		"choices": [
			{"label": "✦ Mediar: proponer un registro cifrado compartido entre Torre y Corona.",
				"aff_a": 10, "resp_a": 10, "aff_b": 10, "resp_b": 12,
				"stat_effects": {"erudicion": 8, "magnetismo": 8},
				"outcome": "Ambos suspiran aliviados y adoptan tu código cifrado. Soren y Cassian coinciden en que tu criterio supera al del Consejo."},
			{"label": "⚔ Respaldar a Soren: «La ciencia del cielo no responde ante decretos políticos.»",
				"aff_a": 16, "resp_a": 8, "aff_b": -6, "resp_b": 6,
				"stat_effects": {"erudicion": 12, "resonancia": 6},
				"outcome": "Soren sonríe agradecido por tu defensa firme mientras Cassian se retira pensativo reconociendo tu determinación."},
			{"label": "♛ Respaldar a Cassian: «Protejamos primero la Torre desde la política imperial.»",
				"aff_a": -6, "resp_a": 6, "aff_b": 16, "resp_b": 10,
				"stat_effects": {"magnetismo": 12, "gracia": 6},
				"outcome": "Cassian agradece tu visión pragmática y logra archivar el documento bajo inmunidad real, aunque Soren queda inquieto."}
		]
	},
	"enc_torre_soren_zephyr": {
		"id": "enc_torre_soren_zephyr", "district": "torre", "npcs": ["soren", "zephyr"],
		"title": "Ecuaciones para un Fantasma",
		"scene": "En el mirador nocturno de la Torre, el cristal de una lente refracta brevemente la silueta de Zephyr junto al astrolabio mientras Soren retrocede incrédulo.\n—Soren: «¡Ese desfase espectral es idéntico al de los mapas de mi madre! ¿Quién eres?»\n—Zephyr: «Un cálculo antiguo que olvidasteis saludar, joven astrónomo.»",
		"choices": [
			{"label": "✦ Presentarlos como aliados discretos ante tus estudios de la estrella.",
				"aff_a": 12, "resp_a": 12, "aff_b": 12, "resp_b": 10,
				"stat_effects": {"resonancia": 10, "seal_investigation": 8},
				"outcome": "Soren ajusta sus gafas con manos temblorosas de entusiasmo histórico mientras Zephyr asiente con respeto hacia su mente humana."},
			{"label": "☾ Proteger la privacidad de Zephyr pidiendo a Soren cerrar los instrumentos por hoy.",
				"aff_a": 4, "resp_a": 6, "aff_b": 16, "resp_b": 8,
				"stat_effects": {"abyssal_sync": 8, "human_anchor": 4},
				"outcome": "Zephyr sonríe tras el cristal por tu lealtad silenciosa; Soren anota la fecha en silencio respetando tu límite."}
		]
	},
	"enc_palacio_cassian_lyra": {
		"id": "enc_palacio_cassian_lyra", "district": "palacio", "npcs": ["cassian", "lyra"],
		"title": "Duelo de Abanicos y Decretos",
		"scene": "En la rotonda de mármol del Palacio, Lady Lyra cierra con elegancia un abanico frente al Príncipe Cassian.\n—Lyra: «Vuestra Alteza parece preferir los observatorios apartados a nuestros salones de primavera.»\n—Cassian: «Solo donde las conversaciones pesan más que la seda, Lady Lyra. Justo llega quien puede juzgar mejor.»",
		"choices": [
			{"label": "❀ Desarmar la tensión con gracia invitando a ambos a unir patronazgo musical.",
				"aff_a": 10, "resp_a": 10, "aff_b": 12, "resp_b": 10,
				"stat_effects": {"gracia": 10, "magnetismo": 10},
				"outcome": "Tu réplica brillante convierte el cruce en un pacto de gala que despierta admiración tanto en el heredero como en Lyra."},
			{"label": "♛ Seguir el juego cortesano de Lyra elogiando el brillo de la nobleza artística.",
				"aff_a": 2, "resp_a": 4, "aff_b": 16, "resp_b": 12,
				"stat_effects": {"gracia": 14, "stress": -4},
				"outcome": "Lyra alza el mentón triunfante y comparte contigo dos invitaciones privadas para conciertos del Palacio."}
		]
	},
	"enc_patio_vespera_caelum": {
		"id": "enc_patio_vespera_caelum", "district": "patio", "npcs": ["vespera", "caelum"],
		"title": "Doctrina Noble contra Acero Callejero",
		"scene": "Chispas reales saltan en el centro del Patio Ducal cuando la lanza de madera de Vespera traba el mandoble de Caelum.\n—Caelum: «Tus guardias de manual mueren en el primer callejón oscuro con lluvia, Lady Escarcha.»\n—Vespera: «Y tus perros callejeros se quiebran en tres segundos contra una línea imperial disciplinada.»",
		"choices": [
			{"label": "⚔ Proponer un asalto tres-bandas para combinar táctica militar e instinto.",
				"aff_a": 12, "resp_a": 14, "aff_b": 12, "resp_b": 14,
				"stat_effects": {"temple": 10, "destreza": 10},
				"outcome": "Tras diez minutos intensos de esgrima mixta, ambos chocan puños agotados reconociendo lo mucho que aprende uno del otro."},
			{"label": "✦ Dar la razón a Vespera sobre la disciplina de formación.",
				"aff_a": 16, "resp_a": 10, "aff_b": -4, "resp_b": 6,
				"stat_effects": {"temple": 12, "gravedad": 6},
				"outcome": "Vespera endereza su postura agradecida mientras Caelum suelta una risa amarga y vuelve a revisar sus monturas."},
			{"label": "⚡ Dar la razón a Caelum sobre la supervivencia sin reglas.",
				"aff_a": -4, "resp_a": 6, "aff_b": 16, "resp_b": 10,
				"stat_effects": {"destreza": 12, "temple": 4},
				"outcome": "Caelum guiña un ojo satisfecho mientras Vespera jura mostrarte en la próxima justa cuánto pesa la disciplina."}
		]
	},
	"enc_patio_vespera_soren": {
		"id": "enc_patio_vespera_soren", "district": "patio", "npcs": ["vespera", "soren"],
		"title": "La Lanza y el Compás",
		"scene": "Vespera lanza una jabalina al blanco lejano justo cuando Soren cruza midiendo el viento con un péndulo de bronce.\n—Soren: «¡Tu ángulo de salida subió cuatro grados por la brisa lateral!»\n—Vespera: «¿Quieres intentarlo tú con brazos reales en vez de pizarra, ratón de torre?»",
		"choices": [
			{"label": "✦ Traducir las fórmulas de viento de Soren en un ajuste físico exacto para Vespera.",
				"aff_a": 12, "resp_a": 12, "aff_b": 12, "resp_b": 12,
				"stat_effects": {"destreza": 8, "erudicion": 8},
				"outcome": "Tu siguiente tiro clava el centro exacto de la diana; Vespera y Soren se quedan mirándote fascinados como un puente entre ciencia y acero."}
		]
	},
	"enc_acueductos_kaelen_caelum": {
		"id": "enc_acueductos_kaelen_caelum", "district": "acueductos", "npcs": ["kaelen", "caelum"],
		"title": "Peaje en los Canales de Mercurio",
		"scene": "Bajo el arco de piedra húmeda, Caelum retiene la brida de un carro nocturno que Kaelen guía sin sello aduanero.\n—Caelum: «Mi caravana protege medicinas legítimas, ladrón. Si nos comprometes nos cuelgan a ambos.»\n—Kaelen: «Esas cajas llevan tónicos para huérfanos con fiebre que tu aduana dejaría pudrirse diez días.»",
		"choices": [
			{"label": "❀ Avalar el paso con tu palabra asegurando medicina legal sin perder carga.",
				"aff_a": 14, "resp_a": 10, "aff_b": 12, "resp_b": 12,
				"stat_effects": {"moralidad": 8, "human_anchor": 6, "destreza": 6},
				"outcome": "Caelum suelta la rienda con un gruñido respetuoso y Kaelen reparte las cajas limpias antes de la ronda ducal."},
			{"label": "⚔ Cubrir el desvío furtivo de Kaelen distrayendo la patrulla con un truco.",
				"aff_a": 16, "resp_a": 12, "aff_b": 6, "resp_b": 8,
				"stat_effects": {"destreza": 10, "entropia": 4},
				"outcome": "La carga cruza sin dejar rastro y hasta Caelum admite entre dientes que la maniobra fue limpia."}
		]
	},
	"enc_anfiteatro_mirari_lyra": {
		"id": "enc_anfiteatro_mirari_lyra", "district": "anfiteatro", "npcs": ["mirari", "lyra"],
		"title": "La Partitura Prohibida vs. El Canon Imperial",
		"scene": "En el escenario vacío del Anfiteatro, Mirari afina un acorde irregular que hace fruncir el ceño a Lady Lyra desde primera fila.\n—Lyra: «Ese intervalo rompe toda simetría clásica de los salones... aunque su eco pone la piel de gallina.»\n—Mirari: «La verdad del corazón rara vez cabe en cuatro compases simétricos, Lady Meridia.»",
		"choices": [
			{"label": "❀ Unir tu voz como puente entre el arpa clásica de Lyra y la melodía libre de Mirari.",
				"aff_a": 12, "resp_a": 12, "aff_b": 12, "resp_b": 12,
				"stat_effects": {"gracia": 12, "human_anchor": 6, "stress": -8},
				"outcome": "El dúo espontáneo resuena por toda la plaza blanca; Lyra aplaude sinceramente por primera vez sin guantes ni etiquetas."}
		]
	},
	"enc_espejo_zephyr_mirari": {
		"id": "enc_espejo_zephyr_mirari", "district": "espejo", "npcs": ["zephyr", "mirari"],
		"title": "Canción de Cuna sobre el Agua Quieta",
		"scene": "Al caer la tarde junto al Espejo Astral, Mirari apoya su arpa en la piedra sin abrir sus ojos vendados mientras las aguas devuelven un destello violeta suave.\n—Mirari: «Siento dos corazones respirando en este estanque, y por primera vez ninguno suena asustado.»\n—Zephyr: «Canta un compás más, cantora ciega... Esa voz calma memorias de hace diez siglos.»",
		"choices": [
			{"label": "✦ Sentarte entre ambos sosteniendo un acorde sereno bajo la luna menguante.",
				"aff_a": 12, "resp_a": 10, "aff_b": 14, "resp_b": 10,
				"stat_effects": {"resonancia": 10, "seal_integrity": 4, "human_anchor": 6},
				"outcome": "La música y el reflejo crean una quietud luminosa que restaura tu espíritu y fortalece ambos vínculos."}
		]
	}
}

# Estado mutable: npc_id -> {known, affection, respect, spark, stage, actions_bimester, outing_done_bimester, events_seen}
var state: Dictionary = {}
var social_points_left: int = MAX_SOCIAL_POINTS
var interacted_this_bimester: bool = false
var strolled_this_bimester: bool = false
var cross_encounter_used_this_bimester: bool = false
var cross_encounters_seen: Array[String] = []
var _dialogue_seq: int = 0

func _ready() -> void:
	reset_new_game()

func reset_new_game() -> void:
	state.clear()
	for npc_id in NPC_ORDER:
		var start: Dictionary = NPC_DATA[npc_id]["start"]
		state[npc_id] = {
			"known": false,
			"affection": int(start["affection"]), "respect": int(start["respect"]),
			"spark": 0, "stage": 1, "actions_bimester": 0,
			"outing_done_bimester": false,
			"events_seen": [] as Array
		}
	social_points_left = MAX_SOCIAL_POINTS
	interacted_this_bimester = false
	strolled_this_bimester = false
	cross_encounter_used_this_bimester = false
	cross_encounters_seen.clear()
	_dialogue_seq = 0

func reset_bimester_flags() -> void:
	for npc_id in NPC_ORDER:
		if state.has(npc_id):
			state[npc_id]["actions_bimester"] = 0
			state[npc_id]["outing_done_bimester"] = false
	social_points_left = MAX_SOCIAL_POINTS
	interacted_this_bimester = false
	strolled_this_bimester = false
	cross_encounter_used_this_bimester = false

# ------------------------------------------------------------------------------
# CONSULTAS
# ------------------------------------------------------------------------------
func _personalize(text: String) -> String:
	if GameState.daughter_name == "Renpet" or GameState.daughter_name.strip_edges() == "":
		return text
	return text.replace("Renpet-Neheh", "__RN_GODDESS__").replace("Renpet", GameState.daughter_name).replace("__RN_GODDESS__", "Renpet-Neheh")

func get_current_act() -> int:
	if GameState.age >= 18:
		return 3
	if GameState.age >= 15:
		return 2
	return 1

func get_data(npc_id: String) -> Dictionary:
	var base: Dictionary = NPC_DATA.get(npc_id, {})
	if base.is_empty():
		return {}
	var out := base.duplicate(true)
	var tier: int = GameState.get_secret_tier()
	if npc_id == "cassian" and tier >= 2:
		out["bio"] = "Príncipe heredero que descubre que su padre el Emperador planea sacrificar a Renpet en el Solsticio de sus 20 años."
	elif npc_id == "mirari" and tier >= 2:
		out["bio"] = "Oráculo y arpista ciega que escucha los dos latidos dentro de Renpet: su corazón mortal y el espíritu de Nyx-Aethel."
	elif npc_id == "zephyr":
		if tier >= 2:
			out["name"] = "Zephyr (Nyx-Aethel)"
			out["title"] = "El Lucero Prisionero Detrás del Espejo"
			out["bio"] = "El espíritu primordial del libre albedrío encerrado por la Diosa Renpet-Neheh dentro de la estrella que se convirtió en tu hija."
		elif tier == 1 or is_known("zephyr"):
			out["name"] = "Zephyr"
			out["title"] = "La Voz Detrás del Espejo"
			out["bio"] = "Un espíritu misterioso de ojos violáceos que aguarda tras las aguas calmas del estanque sagrado."
	out["bio"] = _personalize(str(out.get("bio", "")))
	return out

func get_state(npc_id: String) -> Dictionary:
	return state.get(npc_id, {})

func is_known(npc_id: String) -> bool:
	return bool(state.get(npc_id, {}).get("known", false))

func get_remaining_actions_for_npc(npc_id: String) -> int:
	if not state.has(npc_id):
		return 0
	return maxi(0, mini(social_points_left, MAX_ACTIONS_PER_NPC - int(state[npc_id].get("actions_bimester", 0))))

func can_interact_with(npc_id: String) -> bool:
	return is_available(npc_id) and get_remaining_actions_for_npc(npc_id) > 0

func _spend_social_point(npc_id: String) -> void:
	if state.has(npc_id):
		state[npc_id]["actions_bimester"] = int(state[npc_id].get("actions_bimester", 0)) + 1
	social_points_left = maxi(0, social_points_left - 1)
	interacted_this_bimester = (social_points_left <= 0)

func get_npc_age(npc_id: String) -> int:
	var base: int = int(NPC_DATA.get(npc_id, {}).get("base_age", 20))
	if base >= 900:
		return base
	return base + (GameState.age - 12)

## Zephyr aparece a partir del Acto II (15 años) o si Renpet ya asimiló la Voz del Prisionero.
func is_available(npc_id: String) -> bool:
	if npc_id == "zephyr":
		return GameState.age >= 15 or GameState.has_mutation("voz_del_prisionero")
	return NPC_DATA.has(npc_id)

func get_locked_reason(npc_id: String) -> String:
	if npc_id == "zephyr" and not is_available(npc_id):
		return "Una presencia enigmática solo responde en sueños a partir de los 15 años (Acto II), o al asimilar el Eco del Espejo en el Crisol."
	return ""

## Regla de edad: solo adultos (Renpet y el personaje) pueden tener ruta romántica.
func romance_available(npc_id: String) -> bool:
	if not NPC_DATA.has(npc_id):
		return false
	return GameState.age >= GameState.ROMANCE_MIN_AGE and get_npc_age(npc_id) >= 18

func get_romance_locked_note() -> String:
	if GameState.age < GameState.ROMANCE_MIN_AGE:
		return "Chispa Romántica: se despierta recién cuando %s cumple %d años. Hasta entonces, su camino es el de la amistad y la rivalidad." % [GameState.daughter_name, GameState.ROMANCE_MIN_AGE]
	return ""

func get_relationship_status_title(npc_id: String) -> String:
	var c: Dictionary = state.get(npc_id, {})
	if c.is_empty():
		return "Desconocido"
	if not bool(c.get("known", false)):
		return "• Desconocido (Sin presentar)"
	var aff: int = int(c["affection"])
	var res: int = int(c["respect"])
	var spk: int = int(c["spark"])

	if aff >= 65 and res >= 55 and spk >= 60:
		return "♥ AMOR VERDADERO (Amantes Destinados)"
	elif aff < 20 and res >= 50 and spk >= 45:
		return "♦ TENSIÓN ENEMIGOS-A-AMANTES"
	elif aff < 0 and spk >= 50:
		return "❖ OBSESIÓN TRÁGICA"
	elif aff >= 65 and res >= 60 and spk < 60:
		return "✦ MEJOR AMIGO / HERMANO DE JURAMENTO"
	elif aff >= 35 and res >= 30:
		return "✦ Confidente y Aliado Leal"
	elif aff <= -45 and res >= 40:
		return "⚔ NÉMESIS HONORABLE (Duelo Jurado)"
	elif aff <= -45 and res < 40:
		return "☠ ODIO MORTAL (Saboteador / Enemigo)"
	elif aff < 0 and res >= 35:
		return "⚡ Rivalidad Feroz"
	return "• Conocido de Aethelgard"

## Selección contextual de diálogo no repetitivo: varía por Acto (1/2/3), historial, atuendo y mutación/sello.
func get_contextual_action_dialogue(npc_id: String, action_key: String, is_fav_gift: bool = false, act_override: int = 0) -> String:
	var act: int = act_override if act_override in [1, 2, 3] else get_current_act()
	var pool_key: String = action_key
	if action_key == "chat":
		pool_key = "support"
	elif action_key == "gift_item" or action_key == "gift":
		pool_key = "gift_fav" if is_fav_gift else "gift"

	var lines: Array = []
	if ACT_DIALOGUES.has(npc_id):
		var by_act: Dictionary = ACT_DIALOGUES[npc_id].get(act, {})
		if by_act.has(pool_key):
			lines = by_act[pool_key]
		elif pool_key == "romance":
			lines = ACT_DIALOGUES[npc_id].get(3, {}).get("romance", [])

	var core_line: String = ""
	if lines.size() > 0:
		var actions_done: int = int(state.get(npc_id, {}).get("actions_bimester", 0))
		var idx: int = (actions_done + TimeManager.current_total_turn + _dialogue_seq) % lines.size()
		core_line = str(lines[idx])
	else:
		var fb_key: String = "support" if action_key == "chat" else ("gift" if action_key == "gift_item" else action_key)
		core_line = str(NPC_DATA.get(npc_id, {}).get("dialogues", {}).get(fb_key, ""))

	# Añade observación contextual por Atuendo o Mutación/Sello sin spoilers en Tier 0
	var extra_notes: Array[String] = []
	if action_key in ["chat", "support", "romance", "gift", "gift_item"]:
		var outfit_id: String = str(GameState.equipped_outfit)
		if outfit_id != "default" and OUTFIT_COMMENTS.get(npc_id, {}).has(outfit_id):
			if ((_dialogue_seq + TimeManager.current_total_turn) % 2) == 0:
				extra_notes.append(str(OUTFIT_COMMENTS[npc_id][outfit_id]))

		var mut_line: String = _get_contextual_mutation_comment(npc_id)
		if mut_line != "":
			extra_notes.append(mut_line)

	var combined: String = core_line
	if extra_notes.size() > 0:
		combined += "\n" + " ".join(extra_notes)
	return _personalize(combined)

func _get_contextual_mutation_comment(npc_id: String) -> String:
	var has_any_mut: bool = GameState.active_mutations.size() > 0
	var low_seal: bool = GameState.seal_integrity < 55
	if not has_any_mut and not low_seal:
		return ""
	if GameState.get_secret_tier() == 0:
		return str(MUTATION_COMMENTS_TIER0.get(npc_id, ""))
	if low_seal and (GameState.active_mutations.is_empty() or (TimeManager.current_total_turn % 2 == 1)):
		return str(MUTATION_COMMENTS_DEEP.get("low_seal", {}).get(npc_id, ""))
	for m_id in ["voz_del_prisionero", "pulso_cristalino", "sangre_pesada", "paso_de_luz"]:
		if GameState.has_mutation(m_id):
			var c: String = str(MUTATION_COMMENTS_DEEP.get(m_id, {}).get(npc_id, ""))
			if c != "":
				return c
	return str(MUTATION_COMMENTS_TIER0.get(npc_id, ""))

func _compose_outing_reply(npc_id: String, spot_id: String, romantic_mode: bool) -> String:
	var nname: String = str(get_data(npc_id).get("name", npc_id))
	var sname: String = str(OUTING_SPOTS.get(spot_id, {}).get("name", "Aethelgard"))
	var tone: String = ""
	if romantic_mode:
		match npc_id:
			"soren": tone = "Soren entrelaza sus dedos con los tuyos entre las barandas de %s y admite que hace meses no mira ninguna estrella tanto como a ti." % sname
			"vespera": tone = "Sin armadura ni protocolo, Vespera apoya su frente contra tu hombro bajo las farolas de %s: «Ojalá toda noche terminara así contigo»." % sname
			"kaelen": tone = "Kaelen roba dos guirnaldas de papel iluminadas y te estrecha junto a %s: «Nadie nos manda esta noche, lucero»." % sname
			"cassian": tone = "El Príncipe Cassian despide a sus escoltas en la entrada de %s y camina tomado de tu mano sin ocultar su sonrisa." % sname
			"mirari": tone = "Mirari entona en voz baja una melodía solo para ti mientras descansan codo a codo en %s." % sname
			"zephyr": tone = "La brisa y la luz plateada dibujan la silueta serena de Zephyr a tu lado junto a %s, tan cercana que casi parece respirar tu mismo aire." % sname
			"lyra": tone = "Lady Lyra deja el abanico cerrado sobre tu regazo en %s y sonríe con calidez sincera: «Hoy nadie en la corte importa más que tú»." % sname
			"caelum": tone = "Caelum quita su gruesa capa gris para cubrirte del viento en %s y murmura con una paz nueva: «Contigo no echo de menos ningún camino»." % sname
		return _personalize(tone)

	match npc_id:
		"soren": tone = "Pasean por %s compartiendo anotaciones en servilletas y té caliente; Soren olvida por una tarde entera la presión del Archimago." % sname
		"vespera": tone = "Vespera y tú recorren %s comparando versos escondidos y panecillos recién salidos del horno." % sname
		"kaelen": tone = "Entre bromas en %s, Kaelen enseña a mirar Aethelgard desde las cornizas donde nadie cobra impuestos ni pide títulos." % sname
		"cassian": tone = "Cassian deja atrás los pliegos del Consejo para caminar por %s contigo conversando sobre libros y futuros posibles." % sname
		"mirari": tone = "Junto a %s, Mirari escucha los murmullos amables de la tarde y compone sobre la marcha una variación alegre para ti." % sname
		"zephyr": tone = "Al recorrer %s tras caer la tarde, un destello amable acompaña cada observación tuya como un eco curioso que aprende a amar la ciudad." % sname
		"lyra": tone = "Lady Lyra elige los mejores puestos de %s entre risas suaves y comentarios agudos, agradecida de caminar sin la vigilancia de los senadores." % sname
		"caelum": tone = "Caelum carga las bolsas y señala viejas leyendas de frontera mientras recorren %s sin prisas ni guardias." % sname
	return _personalize("%s (%s)" % [tone, nname])

## Personaje más cercano (para cartas y charlas). Devuelve {} si ninguno supera el umbral.
func get_closest_bond() -> Dictionary:
	var best: Dictionary = {}
	var best_aff: int = STAGE2_THRESHOLD - 1
	for npc_id in NPC_ORDER:
		if not is_available(npc_id) or not is_known(npc_id):
			continue
		var aff: int = int(state[npc_id]["affection"])
		if aff > best_aff:
			best_aff = aff
			best = {"id": npc_id, "name": get_data(npc_id)["name"], "affection": aff}
	return best

func get_worst_bond() -> Dictionary:
	var worst: Dictionary = {}
	var worst_aff: int = -STAGE2_THRESHOLD + 1
	for npc_id in NPC_ORDER:
		if not is_available(npc_id) or not is_known(npc_id):
			continue
		var aff: int = int(state[npc_id]["affection"])
		if aff < worst_aff:
			worst_aff = aff
			worst = {"id": npc_id, "name": get_data(npc_id)["name"], "affection": aff}
	return worst

func get_letter_line() -> String:
	var close: Dictionary = get_closest_bond()
	var worst: Dictionary = get_worst_bond()
	if not close.is_empty() and not worst.is_empty():
		return "En la capital, %s se ha vuelto alguien en quien confío de verdad, mientras que con %s las cosas se pusieron muy tensas. Lo cuento por si te conviene saberlo." % [close["name"], worst["name"]]
	if not close.is_empty():
		return "En la capital, %s se ha vuelto alguien en quien confío de verdad. Me alegra tener un amigo así." % close["name"]
	if not worst.is_empty():
		return "Con %s las cosas se pusieron muy tensas este año. Quizá tarde en perdonar... o en que me perdonen." % worst["name"]
	return ""

# ------------------------------------------------------------------------------
# SALIDAS A LA CAPITAL (Volcano Princess style: 3 Puntos Sociales / bimestre, máx. 2 con la misma persona)
# ------------------------------------------------------------------------------
func meet_candidate(npc_id: String) -> Dictionary:
	if not state.has(npc_id):
		return {"ok": false, "msg": "Personaje no encontrado."}
	if not is_available(npc_id):
		return {"ok": false, "msg": get_locked_reason(npc_id)}
	if is_known(npc_id):
		return {"ok": false, "msg": "%s ya se presentó ante %s." % [GameState.daughter_name, get_data(npc_id)["name"]]}
	if social_points_left <= 0:
		return {"ok": false, "msg": "No quedan Puntos Sociales este bimestre."}

	var c: Dictionary = state[npc_id]
	c["known"] = true
	GameState.begin_batch()
	_add(c, "affection", 8)
	_add(c, "respect", 8)
	GameState.modify_stat("magnetismo", 6)
	_spend_social_point(npc_id)
	GameState.end_batch()

	var data: Dictionary = get_data(npc_id)
	var reply: String = _personalize(str(NPC_DATA[npc_id].get("intro", "\"Encantado de conocerte.\"")))
	var st_lbl: String = get_relationship_status_title(npc_id)
	Chronicle.record_event("meet_" + npc_id, "Primer encuentro con %s" % data["name"], reply, "social", 4)
	relationship_updated.emit(npc_id)
	return {
		"ok": true,
		"speaker": "%s — %s" % [data["name"], st_lbl],
		"reply": reply,
		"effects": "¡Nuevo vínculo abierto! (+8 Afecto, +8 Respeto, +6 Magnetismo)"
	}

## action_type: meet | chat (alias support) | train | gift_item | gift (legacy) | romance | provoke | outing
func interact_with_candidate(npc_id: String, action_type: String, extra: String = "") -> Dictionary:
	if action_type == "meet":
		return meet_candidate(npc_id)
	if not state.has(npc_id):
		return {"ok": false, "msg": "Personaje no encontrado."}
	if not is_available(npc_id):
		return {"ok": false, "msg": get_locked_reason(npc_id)}
	if not is_known(npc_id):
		return {"ok": false, "msg": "Aún no te has presentado a esta persona."}
	if social_points_left <= 0:
		return {"ok": false, "msg": "%s agotó sus %d Puntos Sociales este bimestre." % [GameState.daughter_name, MAX_SOCIAL_POINTS]}
	if int(state[npc_id].get("actions_bimester", 0)) >= MAX_ACTIONS_PER_NPC:
		return {"ok": false, "msg": "Ya dedicaste el máximo de %d encuentros a %s este bimestre." % [MAX_ACTIONS_PER_NPC, get_data(npc_id)["name"]]}
	if action_type == "romance":
		if not romance_available(npc_id):
			return {"ok": false, "msg": "Esa opción todavía no está disponible: " + get_romance_locked_note()}
		if int(state[npc_id]["respect"]) < 25 or int(state[npc_id]["affection"]) < 20:
			return {"ok": false, "msg": "Necesitas primero al menos +20 Afecto y +25 Respeto antes de declarar un cortejo."}
	if action_type == "outing":
		if int(state[npc_id]["affection"]) < OUTING_MIN_AFFECTION:
			return {"ok": false, "msg": "Necesitas al menos +%d de Afecto para invitar a %s a pasear por la ciudad." % [OUTING_MIN_AFFECTION, get_data(npc_id)["name"]]}
		if bool(state[npc_id].get("outing_done_bimester", false)):
			return {"ok": false, "msg": "%s ya salió de paseo por la ciudad contigo este bimestre." % get_data(npc_id)["name"]}

	var c: Dictionary = state[npc_id]
	var raw: Dictionary = NPC_DATA[npc_id]
	var data: Dictionary = get_data(npc_id)
	var reply: String = ""
	var effect_summary: String = ""
	var norm_action: String = "chat" if action_type == "support" else action_type
	_dialogue_seq += 1

	GameState.begin_batch()
	match norm_action:
		"chat":
			_add(c, "affection", 10)
			_add(c, "respect", 8)
			GameState.modify_stat("human_anchor", 3)
			GameState.modify_stat("stress", -3)
			effect_summary = "+10 Afecto, +8 Respeto, +3 Anclaje, -3 Estrés"
			if npc_id == "zephyr":
				GameState.modify_stat("abyssal_sync", 8)
				effect_summary += ", +8 %s" % GameState.get_stat_label("abyssal_sync")
			reply = get_contextual_action_dialogue(npc_id, "support")
		"train":
			var r_stat: String = str(raw.get("role_stat", "temple"))
			var gain: int = GameState.modify_stat(r_stat, 14)
			GameState.modify_stat("stress", 4)
			_add(c, "affection", 7)
			_add(c, "respect", 12)
			reply = get_contextual_action_dialogue(npc_id, "train")
			effect_summary = "+%d %s, +12 Respeto, +7 Afecto (+4 Estrés)" % [gain, GameState.get_stat_label(r_stat)]
		"romance":
			_add(c, "spark", 18)
			_add(c, "affection", 12)
			GameState.modify_stat("stress", -8)
			GameState.modify_stat("human_anchor", 5)
			reply = get_contextual_action_dialogue(npc_id, "romance")
			effect_summary = "+18 Chispa Romántica, +12 Afecto, -8 Estrés, +5 Anclaje"
		"outing":
			var spot_id: String = extra if OUTING_SPOTS.has(extra) else OUTING_SPOT_ORDER[0]
			var spot: Dictionary = OUTING_SPOTS[spot_id]
			var cost_g: int = int(spot["cost"])
			if not GameState.modify_gold(-cost_g):
				GameState.end_batch()
				return {"ok": false, "msg": "La salida a %s cuesta %d G." % [spot["name"], cost_g]}
			c["outing_done_bimester"] = true
			var rom_date: bool = romance_available(npc_id) and (int(c["spark"]) >= 15 or int(c["affection"]) >= 45)
			_add(c, "affection", 12)
			_add(c, "respect", 6)
			if rom_date:
				_add(c, "spark", 12)
			var st_gain: int = GameState.modify_stat(str(spot["stat"]), int(spot["stat_val"]))
			GameState.modify_stat("stress", int(spot["stress"]))
			GameState.modify_stat("human_anchor", 4)
			reply = _compose_outing_reply(npc_id, spot_id, rom_date)
			effect_summary = "%s (-%d G): +12 Afecto, +6 Respeto%s, +%d %s, %d Estrés, +4 Anclaje" % [
				spot["name"], cost_g, (", +12 Chispa" if rom_date else ""),
				st_gain, GameState.get_stat_label(str(spot["stat"])), int(spot["stress"])
			]
		"gift_item":
			var g: Dictionary = CatalogDB.get_gift(extra)
			if g.is_empty() or not GameState.consume_gift(extra):
				GameState.end_batch()
				return {"ok": false, "msg": "No tienes ese obsequio en tu equipaje. Adquiérelo en las tiendas del Mapa."}
			var liked: bool = (g.get("favs", []) as Array).has(npc_id)
			var aff_g: int = 20 if liked else 10
			var resp_g: int = 12 if liked else 6
			_add(c, "affection", aff_g)
			_add(c, "respect", resp_g)
			reply = get_contextual_action_dialogue(npc_id, "gift_item", liked)
			effect_summary = "%s (%s): +%d Afecto, +%d Respeto" % [
				str(g["name"]), "¡Favorito!" if liked else "Apreciado", aff_g, resp_g
			]
		"gift":
			if not GameState.modify_gold(-SOCIAL_COST_GIFT):
				GameState.end_batch()
				return {"ok": false, "msg": "Necesitas %d G o un obsequio comprado en las tiendas de Aethelgard." % SOCIAL_COST_GIFT}
			_add(c, "affection", 16)
			_add(c, "respect", 8)
			reply = get_contextual_action_dialogue(npc_id, "gift", false)
			effect_summary = "-%d Oro | +16 Afecto, +8 Respeto" % SOCIAL_COST_GIFT
		"provoke":
			_add(c, "affection", -24)
			if GameState.temple + GameState.erudicion >= 260:
				_add(c, "respect", 12)
				effect_summary = "-24 Afecto, +12 Respeto (Rivalidad), +5 Entropía"
			else:
				_add(c, "respect", -12)
				effect_summary = "-24 Afecto, -12 Respeto (Desprecio), +5 Entropía"
			GameState.modify_stat("entropia", 5)
			reply = get_contextual_action_dialogue(npc_id, "provoke")
		_:
			GameState.end_batch()
			return {"ok": false, "msg": "Acción desconocida."}
	_spend_social_point(npc_id)
	GameState.end_batch()

	_update_stage(npc_id)
	reply = _personalize(reply)
	var new_status: String = get_relationship_status_title(npc_id)
	Chronicle.record_event("bond_%s_%s" % [norm_action, npc_id], "Encuentro con %s (%s)" % [data["name"], new_status], reply, "social", 3)
	relationship_updated.emit(npc_id)
	return {"ok": true, "speaker": "%s — %s" % [data["name"], new_status], "reply": reply, "effects": effect_summary}

# ------------------------------------------------------------------------------
# ENCUENTROS CRUZADOS ENTRE DOS PERSONAJES POR DISTRITO
# ------------------------------------------------------------------------------
func get_available_cross_encounter(district_id: String) -> Dictionary:
	if cross_encounter_used_this_bimester or social_points_left <= 0:
		return {}
	# Prioriza encuentros no vistos primero; luego permite cualquiera en el distrito
	var candidates: Array[Dictionary] = []
	for enc_id in CROSS_ENCOUNTERS.keys():
		var enc: Dictionary = CROSS_ENCOUNTERS[enc_id]
		if str(enc.get("district", "")) != district_id:
			continue
		var npcs: Array = enc.get("npcs", [])
		if npcs.size() < 2:
			continue
		var a_id: String = str(npcs[0])
		var b_id: String = str(npcs[1])
		if is_available(a_id) and is_available(b_id) and is_known(a_id) and is_known(b_id):
			candidates.append(enc)
	for c_enc in candidates:
		if not cross_encounters_seen.has(str(c_enc["id"])):
			return c_enc.duplicate(true)
	return {}

func resolve_cross_encounter(enc_id: String, choice_idx: int) -> Dictionary:
	if not CROSS_ENCOUNTERS.has(enc_id):
		return {"ok": false, "msg": "Encuentro cruzado desconocido."}
	if cross_encounter_used_this_bimester:
		return {"ok": false, "msg": "Ya interviniste en un encuentro cruzado este bimestre."}
	if social_points_left <= 0:
		return {"ok": false, "msg": "%s ya agotó sus Puntos Sociales este bimestre." % GameState.daughter_name}
	var enc: Dictionary = CROSS_ENCOUNTERS[enc_id]
	var choices: Array = enc.get("choices", [])
	if choice_idx < 0 or choice_idx >= choices.size():
		return {"ok": false, "msg": "Opción inválida."}
	var ch: Dictionary = choices[choice_idx]
	var a_id: String = str(enc["npcs"][0])
	var b_id: String = str(enc["npcs"][1])

	cross_encounter_used_this_bimester = true
	if not cross_encounters_seen.has(enc_id):
		cross_encounters_seen.append(enc_id)

	GameState.begin_batch()
	if state.has(a_id):
		_add(state[a_id], "affection", int(ch.get("aff_a", 0)))
		_add(state[a_id], "respect", int(ch.get("resp_a", 0)))
	if state.has(b_id):
		_add(state[b_id], "affection", int(ch.get("aff_b", 0)))
		_add(state[b_id], "respect", int(ch.get("resp_b", 0)))

	var eff_parts: Array[String] = []
	var name_a: String = str(get_data(a_id).get("name", a_id)).split(" ")[0]
	var name_b: String = str(get_data(b_id).get("name", b_id)).split(" ")[0]
	eff_parts.append("%s (%+d Afec, %+d Resp)" % [name_a, int(ch.get("aff_a", 0)), int(ch.get("resp_a", 0))])
	eff_parts.append("%s (%+d Afec, %+d Resp)" % [name_b, int(ch.get("aff_b", 0)), int(ch.get("resp_b", 0))])

	var s_eff: Dictionary = ch.get("stat_effects", {})
	for k in s_eff.keys():
		var applied: int = GameState.modify_stat(str(k), int(s_eff[k]))
		if applied != 0:
			eff_parts.append("%s %+d" % [GameState.get_stat_label(str(k)), applied])

	social_points_left = maxi(0, social_points_left - 1)
	interacted_this_bimester = (social_points_left <= 0)
	GameState.end_batch()

	_update_stage(a_id)
	_update_stage(b_id)
	relationship_updated.emit(a_id)
	relationship_updated.emit(b_id)
	var out_msg: String = _personalize(str(ch.get("outcome", "")))
	Chronicle.record_event("cross_" + enc_id, str(enc["title"]), out_msg, "social", 4)
	return {
		"ok": true,
		"speaker": str(enc["title"]),
		"reply": out_msg,
		"effects": ", ".join(eff_parts)
	}

# ------------------------------------------------------------------------------
# ESCENAS DE HISTORIA (una por etapa; consumen un punto social)
# ------------------------------------------------------------------------------
## Devuelve {"ok": bool, "stage": int, "reason": String, "event": Dictionary}
func get_next_bond_event(npc_id: String) -> Dictionary:
	if not state.has(npc_id):
		return {"ok": false, "reason": "Personaje no encontrado."}
	if not is_available(npc_id):
		return {"ok": false, "reason": get_locked_reason(npc_id)}
	var c: Dictionary = state[npc_id]
	var next_stage: int = (c["events_seen"] as Array).size() + 1
	if next_stage > 3:
		return {"ok": false, "reason": "Ya viviste las tres escenas de historia de %s." % NPC_DATA[npc_id]["name"]}
	if not is_known(npc_id):
		return {"ok": false, "reason": "Aún no conoces a %s en persona. Preséntate primero en su distrito." % NPC_DATA[npc_id]["name"]}
	if TimeManager.get_act_number() < next_stage:
		return {"ok": false, "reason": "La escena del Acto %d con %s se desbloquea cuando comience ese Acto." % [next_stage, NPC_DATA[npc_id]["name"]]}
	if int(c["stage"]) < next_stage:
		var needed: int = STAGE2_THRESHOLD if next_stage == 2 else STAGE3_THRESHOLD
		return {"ok": false, "reason": "Necesitas un vínculo más profundo con %s (Afecto o Rencor de ±%d) para vivir su escena del Acto %d." % [NPC_DATA[npc_id]["name"], needed, next_stage]}
	if social_points_left <= 0:
		return {"ok": false, "reason": "%s ya agotó sus %d Puntos Sociales de este bimestre." % [GameState.daughter_name, MAX_SOCIAL_POINTS]}
	var ev: Dictionary = BondEvents.get_event(npc_id, next_stage)
	if ev.is_empty():
		return {"ok": false, "reason": "Escena no disponible."}
	return {"ok": true, "stage": next_stage, "event": ev, "choices": get_visible_choices(npc_id, ev)}

## Filtra las elecciones: la romántica solo aparece si está permitida por edad.
func get_visible_choices(npc_id: String, ev: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for ch in ev["choices"]:
		if ch["kind"] == "romance" and not romance_available(npc_id):
			continue
		out.append(ch)
	return out

func apply_bond_event_choice(npc_id: String, choice: Dictionary) -> Dictionary:
	var check: Dictionary = get_next_bond_event(npc_id)
	if not check.get("ok", false):
		return {"ok": false, "msg": check.get("reason", "")}
	if choice.get("kind", "") == "romance" and not romance_available(npc_id):
		return {"ok": false, "msg": "Esa elección no está disponible todavía."}
	var c: Dictionary = state[npc_id]
	var ev: Dictionary = check["event"]
	var stage_idx: int = int(check["stage"])

	GameState.begin_batch()
	_add(c, "affection", int(choice["affection"]))
	_add(c, "respect", int(choice["respect"]))
	_add(c, "spark", int(choice["spark"]))
	var eff_labels: Array[String] = ["Afecto %+d" % int(choice["affection"]), "Respeto %+d" % int(choice["respect"])]
	if int(choice["spark"]) != 0:
		eff_labels.append("Chispa %+d" % int(choice["spark"]))
	var s_eff: Dictionary = choice.get("stat_effects", {})
	for k in s_eff.keys():
		var applied: int = GameState.modify_stat(k, int(s_eff[k]))
		if k == "gold":
			eff_labels.append("Oro %+d G" % int(s_eff[k]))
		elif applied != 0:
			eff_labels.append("%s %+d" % [GameState.get_stat_label(k), applied])
	_spend_social_point(npc_id)
	GameState.end_batch()

	(c["events_seen"] as Array).append(stage_idx)
	_update_stage(npc_id)
	var st_title: String = get_relationship_status_title(npc_id)
	var kind: String = str(choice["kind"])
	Chronicle.record_event("bond_%s_%s" % [kind, npc_id],
		"Escena con %s: %s" % [NPC_DATA[npc_id]["name"], ev["title"]], str(choice["outcome"]),
		"romance" if kind == "romance" else "social", 5)
	relationship_updated.emit(npc_id)
	return {"ok": true, "speaker": "%s — %s" % [NPC_DATA[npc_id]["name"], st_title],
		"outcome": choice["outcome"], "effects": ", ".join(eff_labels)}

# ------------------------------------------------------------------------------
# INTERNOS
# ------------------------------------------------------------------------------
func modify_npc_relation(npc_id: String, aff_delta: int, resp_delta: int) -> void:
	if not state.has(npc_id):
		return
	var c: Dictionary = state[npc_id]
	_add(c, "affection", aff_delta)
	_add(c, "respect", resp_delta)
	_update_stage(npc_id)
	relationship_updated.emit(npc_id)

func _add(c: Dictionary, key: String, delta: int) -> void:
	var lo: int = 0 if key == "spark" else -100
	c[key] = clampi(int(c[key]) + delta, lo, 100)

func _update_stage(npc_id: String) -> void:
	if not state.has(npc_id):
		return
	var c: Dictionary = state[npc_id]
	var aff: int = absi(int(c["affection"]))
	if aff >= STAGE3_THRESHOLD:
		c["stage"] = maxi(int(c["stage"]), 3)
	elif aff >= STAGE2_THRESHOLD:
		c["stage"] = maxi(int(c["stage"]), 2)

# ------------------------------------------------------------------------------
# GUARDADO
# ------------------------------------------------------------------------------
func serialize() -> Dictionary:
	return {
		"state": state.duplicate(true),
		"social_points_left": social_points_left,
		"interacted_this_bimester": interacted_this_bimester,
		"strolled_this_bimester": strolled_this_bimester,
		"cross_encounter_used_this_bimester": cross_encounter_used_this_bimester,
		"cross_encounters_seen": cross_encounters_seen.duplicate(),
		"dialogue_seq": _dialogue_seq
	}

func deserialize(d: Dictionary) -> void:
	reset_new_game()
	var saved: Variant = d.get("state", {})
	if typeof(saved) == TYPE_DICTIONARY:
		for npc_id in NPC_ORDER:
			if not saved.has(npc_id) or typeof(saved[npc_id]) != TYPE_DICTIONARY:
				continue
			var s: Dictionary = saved[npc_id]
			var c: Dictionary = state[npc_id]
			c["affection"] = clampi(int(s.get("affection", c["affection"])), -100, 100)
			c["respect"] = clampi(int(s.get("respect", c["respect"])), -100, 100)
			c["spark"] = clampi(int(s.get("spark", 0)), 0, 100)
			c["stage"] = clampi(int(s.get("stage", 1)), 1, 3)
			# Migración limpia: si ya tenía trato avanzado en partida vieja, márquese conocido.
			var legacy_known: bool = (absi(int(c["affection"])) >= 15 or int(c["respect"]) >= 20 or int(c["stage"]) >= 2)
			c["known"] = bool(s.get("known", legacy_known))
			c["actions_bimester"] = clampi(int(s.get("actions_bimester", 0)), 0, MAX_ACTIONS_PER_NPC)
			c["outing_done_bimester"] = bool(s.get("outing_done_bimester", false))
			var seen: Array = []
			for e in s.get("events_seen", []):
				if int(e) in [1, 2, 3] and not seen.has(int(e)):
					seen.append(int(e))
			c["events_seen"] = seen
	if d.has("social_points_left"):
		social_points_left = clampi(int(d.get("social_points_left", MAX_SOCIAL_POINTS)), 0, MAX_SOCIAL_POINTS)
		interacted_this_bimester = (social_points_left <= 0)
	else:
		interacted_this_bimester = bool(d.get("interacted_this_bimester", false))
		social_points_left = 0 if interacted_this_bimester else MAX_SOCIAL_POINTS
	strolled_this_bimester = bool(d.get("strolled_this_bimester", false))
	cross_encounter_used_this_bimester = bool(d.get("cross_encounter_used_this_bimester", false))
	cross_encounters_seen.clear()
	for eid in d.get("cross_encounters_seen", []):
		var se: String = str(eid)
		if se != "" and not cross_encounters_seen.has(se):
			cross_encounters_seen.append(se)
	_dialogue_seq = int(d.get("dialogue_seq", 0))
	# Partidas antiguas pudieron guardar Chispa antes de los 18: se elimina por la regla de edad.
	if GameState.age < GameState.ROMANCE_MIN_AGE:
		for npc_id in NPC_ORDER:
			state[npc_id]["spark"] = 0
