extends Node

## Singleton Chronicle - Bitácora determinista de hitos, charlas en la chimenea y ensamblador de cartas anuales (100% sin IA).

signal event_recorded(entry: Dictionary)
signal annual_letter_generated(letter_data: Dictionary)

var events_ledger: Array[Dictionary] = []
var letters_archive: Array[Dictionary] = []
var chatted_this_bimester: bool = false

func _ready() -> void:
	record_event(
		"prologue_star_prison",
		"El Lucero que Descendió del Cielo",
		"Hace doce años, tras liberar a la Diosa de la Eternidad, recibiste en tus brazos una estrella convertida en niña.",
		"lore",
		5
	)

func record_event(event_id: String, title: String, summary: String, category: String = "general", importance: int = 3) -> void:
	var entry: Dictionary = {
		"year": TimeManager.current_year,
		"bimester": TimeManager.current_bimester,
		"turn": TimeManager.current_total_turn,
		"id": event_id,
		"title": title,
		"summary": summary,
		"category": category,
		"importance": importance
	}
	events_ledger.push_front(entry)
	event_recorded.emit(entry)

func get_events_for_year(year: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for ev in events_ledger:
		if ev.get("year", 0) == year:
			result.append(ev)
	return result

## Devuelve los tópicos reactivos disponibles esta noche junto a la chimenea
func get_fireplace_topics() -> Array[Dictionary]:
	var topics: Array[Dictionary] = []
	
	# Tópico 1: Estado del Sello y sueños astrales
	topics.append({
		"id": "dream_of_chains",
		"title": "Sus extraños sueños sobre cadenas de luz y un espejo oscuro",
		"prompt": "\"Padre... anoche soñé de nuevo con un cielo sin luna. Había una voz detrás de un cristal preguntándome por qué los humanos tememos tanto al cambio.\"",
		"stances": [
			{
				"stance": "Cálido y Afectuoso",
				"father_line": "\"Mientras estés bajo este techo, ningún sueño podrá hacerte daño. Toma mi mano; yo estoy aquí contigo.\"",
				"daughter_reply": "\"Gracias, Padre. Cuando escucho tu voz, el zumbido en mi pecho se vuelve cálido y silencioso.\"",
				"effects": {"affection": 8, "human_anchor": 7, "stress": -10}
			},
			{
				"stance": "Curioso y Analítico",
				"father_line": "\"Cuéntame cada detalle de esa voz, Renpet. Quizá la estrella de la que naciste guarda recuerdos antiguos.\"",
				"daughter_reply": "\"¿Tú también crees que no es una pesadilla común? La voz se llama a sí misma Zephyr... dice que lleva siglos esperando.\"",
				"effects": {"erudicion": 12, "abyssal_sync": 8, "seal_investigation": 6}
			},
			{
				"stance": "Estricto y Firme",
				"father_line": "\"Cierra tu mente a esos murmullos. El control espiritual es la primera muralla de un guerrero.\"",
				"daughter_reply": "\"Entendido, Padre. Meditaré antes de dormir para que ninguna grieta perturbe mi concentración.\"",
				"effects": {"temple": 10, "seal_integrity": 4, "stress": 5}
			},
			{
				"stance": "Protector y Cauto",
				"father_line": "\"No se lo menciones a nadie de la Corte ni del Santuario. Hay oídos en la capital que no comprenderían tu don.\"",
				"daughter_reply": "\"Lo guardaré como nuestro secreto familiar. Confío más en ti que en todos los sacerdotes del templo.\"",
				"effects": {"affection": 5, "human_anchor": 5, "resonancia": 10}
			}
		]
	})
	
	# Tópico 2: Progreso, estudios y rivales en Aethelgard
	topics.append({
		"id": "academy_and_rivals",
		"title": "Sus lecciones en la capital y la competencia con sus pares",
		"prompt": "\"En la ciudad todos murmuran cuando paso diciendo que soy 'la hija del Héroe que salvó a la Diosa'. A veces siento que Dama Vespera y Soren esperan que tropiece.\"",
		"stances": [
			{
				"stance": "Alentador (Orgullo Paternal)",
				"father_line": "\"No tienes que cargar con mi leyenda, Renpet. Cualquier camino que elijas por ti misma me llenará de orgullo.\"",
				"daughter_reply": "\"¡Eso me quita un peso enorme de encima! Pero aun así... quiero esforzarme para estar a tu altura.\"",
				"effects": {"affection": 7, "stress": -12, "human_anchor": 6}
			},
			{
				"stance": "Exigente (Forjar Excelencia)",
				"father_line": "\"Que murmuren cuanto quieran. Demuéstrales en el próximo Festival de Otoño de qué está hecha tu voluntad.\"",
				"daughter_reply": "\"¡Tienes razón! Entrenaré el doble mañana. Nadie dirá que la casa del Héroe se ha ablandado.\"",
				"effects": {"destreza": 15, "magnetismo": 12, "stress": 6}
			},
			{
				"stance": "Consejo Diplomático",
				"father_line": "\"Observa a tus rivales con empatía. Vespera y Soren también cargan con expectativas familiares muy pesadas.\"",
				"daughter_reply": "\"Nunca lo había pensado así... La próxima vez que vea a Soren en la biblioteca, intentaré hablar con él sin competir.\"",
				"effects": {"gracia": 14, "moralidad": 6, "erudicion": 8}
			}
		]
	})
	
	# Tópico 3: Vida cotidiana en la mansión y recuerdos juntos
	topics.append({
		"id": "hearth_and_future",
		"title": "El paso del tiempo en la mansión y sus deseos para el futuro",
		"prompt": "\"Miraba las muescas que tallamos en la columna de madera del jardín por cada año que cumplo. El tiempo pasa tan rápido cuando estamos juntos, Padre...\"",
		"stances": [
			{
				"stance": "Promesa Incondicional",
				"father_line": "\"Por muchos años que marquemos en esa madera, esta casa siempre será tu refugio contra el mundo entero.\"",
				"daughter_reply": "\"Prométeme que cuando cumpla veinte años seguiremos cenando juntos frente a esta misma chimenea.\"",
				"effects": {"affection": 10, "human_anchor": 10, "stress": -8}
			},
			{
				"stance": "Enseñanza sobre el Tiempo",
				"father_line": "\"Por eso te llamé Renpet: porque cada año no es algo que se pierde, sino una rama nueva que florece en ti.\"",
				"daughter_reply": "\"Me gusta mi nombre, Padre. Siento que cuando lo pronuncias tu voz me ata a la tierra firme.\"",
				"effects": {"resonancia": 15, "seal_integrity": 3, "human_anchor": 5}
			}
		]
	})
	
	return topics

## Ensamblador Sintáctico Determinista de Cartas Anuales (Bimestre 6 - Solsticio)
func assemble_annual_letter(year: int) -> Dictionary:
	var greeting: String = ""
	var body_father: String = ""
	var body_seal: String = ""
	var closing: String = ""
	
	# 1. Saludo según Afecto y Anclaje Humano
	if GameState.affection >= 75 and GameState.human_anchor >= 70:
		greeting = "Para mi querido Padre, en la noche del Solsticio de mis %d años:" % year
	elif GameState.stress >= 70:
		greeting = "Padre, te dejo esta nota en tu escritorio antes de irme a dormir en mi cumpleaños %d:" % year
	else:
		greeting = "Estimado Padre, al cumplirse mi año número %d en Aethelgard:" % year
		
	# 2. Párrafo sobre la presencia o ausencia del Padre ese año
	if TimeManager.father_times_stayed_home_this_year >= 2:
		body_father = "Quiero darte las gracias por todas las tardes que pasaste conmigo este año en la mansión. Ver que dejabas tus propios asuntos para supervisar mis lecciones y preparar la cena me hizo sentir que no soy solo una estrella caída, sino tu verdadera hija."
	elif TimeManager.father_times_worked_away_this_year >= 3:
		body_father = "Sé que has trabajado sin descanso fuera de casa para que no nos falte el oro, y valoro cada moneda que trajiste. Aun así, hubo noches de invierno en que el salón se sintió demasiado grande y silencioso sin ti."
	else:
		body_father = "Este año ha pasado entre libros, entrenamientos y el sonido de los relojes de la capital. He intentado aprovechar cada lección para que te sientas orgulloso cuando nos sentamos a conversar."
		
	# 3. Párrafo sobre el estado del Sello Estelar y su interior
	if GameState.seal_integrity >= 80:
		body_seal = "La luz en mi interior se siente tranquila y serena. A veces miro las estrellas por la ventana de mi cuarto, pero ya no siento nostalgia del cielo; mi lugar está aquí en la tierra contigo."
	elif GameState.seal_integrity >= 50:
		body_seal = "Últimamente siento un segundo latido bajo mis costillas cuando uso el Horno Astral. En mis sueños aparece aquel joven de ojos de eclipse diciendo que la Diosa nos oculta algo sobre el día en que nací... pero confío en que juntos hallaremos la verdad."
	else:
		body_seal = "Las cadenas de luz dentro de mi pecho queman cuando me enfado o me agoto. Escucho los recuerdos de Nyx-Aethel con tanta claridad que a veces temo olvidar dónde termina la estrella y dónde empiezo yo. No sueltes mi mano el próximo año, Padre."
		
	# 4. Despedida según rasgos psicológicos
	if GameState.affection >= 70:
		closing = "Con todo mi cariño y gratitud,\n— Tu hija, %s." % GameState.daughter_name
	else:
		closing = "Atentamente y con empeño para el año entrante,\n— %s." % GameState.daughter_name
		
	var full_text: String = "%s\n\n%s\n\n%s\n\n%s" % [greeting, body_father, body_seal, closing]
	var letter_obj: Dictionary = {
		"year": year,
		"title": "Carta del Solsticio de los %d Años" % year,
		"content": full_text
	}
	letters_archive.push_front(letter_obj)
	annual_letter_generated.emit(letter_obj)
	return letter_obj
