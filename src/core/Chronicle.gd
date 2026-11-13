extends Node

## Singleton Chronicle - Bitácora determinista de hitos, charlas en la chimenea y cartas anuales (100% sin IA).
## Fase 1.4: registro histórico + Fase 3.4: tópicos de la chimenea.

signal event_recorded(entry: Dictionary)
signal annual_letter_generated(letter_data: Dictionary)

const MAX_LEDGER_ENTRIES: int = 400

var events_ledger: Array[Dictionary] = []   # El más reciente primero
var letters_archive: Array[Dictionary] = []
var chatted_this_bimester: bool = false

func _ready() -> void:
	record_prologue_event()

func reset_new_game() -> void:
	events_ledger.clear()
	letters_archive.clear()
	chatted_this_bimester = false
	record_prologue_event()

func record_prologue_event() -> void:
	record_event(
		"prologue_star_prison",
		"El Lucero que Descendió del Cielo",
		"Hace doce años, tras liberar a la Diosa de la Eternidad, recibiste en tus brazos una estrella convertida en niña.",
		"lore", 5
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
	if events_ledger.size() > MAX_LEDGER_ENTRIES:
		events_ledger.resize(MAX_LEDGER_ENTRIES)
	event_recorded.emit(entry)

func get_events_for_year(year: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for ev in events_ledger:
		if int(ev.get("year", 0)) == year:
			result.append(ev)
	return result

func count_events(id_fragment: String, year: int = -1) -> int:
	var n: int = 0
	for ev in events_ledger:
		if str(ev.get("id", "")).contains(id_fragment) and (year < 0 or int(ev.get("year", 0)) == year):
			n += 1
	return n

## ¿Hubo un evento cuyo id contiene el fragmento en los últimos N turnos (incluido el actual)?
func has_recent_event(id_fragment: String, within_turns: int) -> bool:
	var now: int = TimeManager.current_total_turn
	for ev in events_ledger:
		if now - int(ev.get("turn", 0)) > within_turns:
			break   # el ledger está ordenado: ya no hay nada más reciente
		if str(ev.get("id", "")).contains(id_fragment):
			return true
	return false

## Tópicos disponibles esta noche junto a la chimenea (ver FireplaceTopics).
func get_fireplace_topics() -> Array[Dictionary]:
	return FireplaceTopics.get_available()

# ------------------------------------------------------------------------------
# CARTAS ANUALES (Bimestre 6 - Solsticio). Generación 100% determinista.
# ------------------------------------------------------------------------------
func assemble_annual_letter(completed_year: int) -> Dictionary:
	var new_age: int = completed_year + 1   # la carta se escribe la noche en que cumple años
	var parts: Array[String] = []

	# 1. Saludo según Afecto, Anclaje y Estrés
	if GameState.affection >= 75 and GameState.human_anchor >= 70:
		parts.append("Para mi querido Padre, en la noche del Solsticio de mis %d años:" % new_age)
	elif GameState.stress >= 70:
		parts.append("Padre, te dejo esta nota en tu escritorio antes de irme a dormir en mi cumpleaños %d:" % new_age)
	else:
		parts.append("Estimado Padre, al cumplirse mi año número %d en Aethelgard:" % new_age)

	# 2. Presencia o ausencia del Padre ese año
	if TimeManager.father_times_stayed_home_this_year >= 2:
		parts.append("Quiero darte las gracias por todas las tardes que pasaste conmigo este año en la mansión. Ver que dejabas tus propios asuntos para supervisar mis lecciones y preparar la cena me hizo sentir que no soy solo una estrella caída, sino tu verdadera hija.")
	elif TimeManager.father_times_worked_away_this_year >= 3:
		parts.append("Sé que has trabajado sin descanso fuera de casa para que no nos falte el oro, y valoro cada moneda que trajiste. Aun así, hubo noches de invierno en que el salón se sintió demasiado grande y silencioso sin ti.")
	else:
		parts.append("Este año ha pasado entre libros, entrenamientos y el sonido de los relojes de la capital. He intentado aprovechar cada lección para que te sientas orgulloso cuando nos sentamos a conversar.")

	# 3. Lo que descubrió de sí misma (atributo mortal dominante) y sus rivalidades
	parts.append(_paragraph_about_strength())
	var duel_wins: int = count_events("duel_win_", completed_year) + count_events("clash_win_", completed_year)
	var duel_losses: int = count_events("duel_lose_", completed_year) + count_events("clash_lose_", completed_year)
	if duel_wins > duel_losses and duel_wins > 0:
		parts.append("Gané más pulsos de los que perdí frente a mis rivales de la Academia. Sé que no es lo más importante, pero te confieso que me hizo sentir muy viva.")
	elif duel_losses > duel_wins:
		parts.append("Perdí varios duelos con mis rivales. Duele, pero aprendí más en esas derrotas que en cualquier victoria fácil.")

	# 4. Estado del Sello Estelar
	if GameState.seal_integrity >= 80:
		parts.append("La luz en mi interior se siente tranquila y serena. A veces miro las estrellas por la ventana de mi cuarto, pero ya no siento nostalgia del cielo; mi lugar está aquí en la tierra contigo.")
	elif GameState.seal_integrity >= 50:
		parts.append("Últimamente siento un segundo latido bajo mis costillas cuando uso el Horno Astral. En mis sueños aparece aquel joven de ojos de eclipse diciendo que la Diosa nos oculta algo sobre el día en que nací... pero confío en que juntos hallaremos la verdad.")
	else:
		var secret_name: String = "Nyx-Aethel" if GameState.get_secret_tier() >= 2 else "una vida remota bajo un cielo oscuro"
		parts.append("Las cadenas de luz dentro de mi pecho queman cuando me enfado o me agoto. Escucho los recuerdos de %s con tanta claridad que a veces temo olvidar dónde termina la estrella y dónde empiezo yo. No sueltes mi mano el próximo año, Padre." % secret_name)

	# 5. Vínculo más fuerte o más tenso de la ciudad
	var social_line: String = RelationshipManager.get_letter_line()
	if social_line != "":
		parts.append(social_line)

	# 6. Despedida
	if GameState.affection >= 70:
		parts.append("Con todo mi cariño y gratitud,\n— Tu hija, %s." % GameState.daughter_name)
	else:
		parts.append("Atentamente y con empeño para el año entrante,\n— %s." % GameState.daughter_name)

	var letter_obj: Dictionary = {
		"year": completed_year,
		"age": new_age,
		"title": "Carta del Solsticio de los %d Años" % new_age,
		"content": "\n\n".join(parts)
	}
	letters_archive.push_front(letter_obj)
	annual_letter_generated.emit(letter_obj)
	return letter_obj

func _paragraph_about_strength() -> String:
	var best_key: String = "temple"
	var best_val: int = -1
	for k in ["temple", "destreza", "erudicion", "gracia", "magnetismo"]:
		var v: int = GameState.get_stat(k)
		if v > best_val:
			best_val = v
			best_key = k
	match best_key:
		"temple": return "Mi cuerpo se ha vuelto más fuerte y resistente. Cuando termino el entrenamiento, ya no me tiemblan las manos."
		"destreza": return "Me he vuelto rápida y precisa. A veces siento que el tiempo se afloja un poco cuando manejo la espada."
		"erudicion": return "Los libros se me han hecho un hogar. Cada ecuación resuelta me acerca un poco más a entender qué soy."
		"gracia": return "He aprendido a moverme y a hablar con una elegancia que antes me parecía ajena. Madame Isolde ya no suspira tanto al verme."
		_: return "La gente se detiene a escucharme cuando hablo. Aún me sorprende, pero empiezo a entender por qué mi voz importa."

# ------------------------------------------------------------------------------
# GUARDADO
# ------------------------------------------------------------------------------
func serialize() -> Dictionary:
	return {
		"events_ledger": events_ledger.duplicate(true),
		"letters_archive": letters_archive.duplicate(true),
		"chatted_this_bimester": chatted_this_bimester
	}

func deserialize(d: Dictionary) -> void:
	events_ledger.clear()
	for ev in d.get("events_ledger", []):
		if typeof(ev) == TYPE_DICTIONARY:
			events_ledger.append(ev)
	letters_archive.clear()
	for lt in d.get("letters_archive", []):
		if typeof(lt) == TYPE_DICTIONARY:
			letters_archive.append(lt)
	chatted_this_bimester = bool(d.get("chatted_this_bimester", false))
