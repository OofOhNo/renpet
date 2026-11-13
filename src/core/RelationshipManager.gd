extends Node

## RelationshipManager - Matriz 3D de Vínculos (Fase 6.1 y 6.3).
## Ejes por personaje: Afecto (-100..+100), Respeto (-100..+100) y Chispa Romántica (0..100).
## REGLA DE EDAD: la Chispa Romántica, las citas y las elecciones románticas de las escenas
## solo existen cuando Renpet tiene 18 años o más (GameState.ROMANCE_MIN_AGE) y el personaje
## también es adulto. Antes de eso, las rutas disponibles son Amistad y Rivalidad/Némesis.

signal relationship_updated(npc_id: String)

const NPC_ORDER: Array[String] = ["soren", "vespera", "kaelen", "cassian", "mirari", "zephyr"]

const SOCIAL_COST_GIFT: int = 75
const STAGE2_THRESHOLD: int = 45   # |Afecto| necesario para la etapa 2
const STAGE3_THRESHOLD: int = 80   # |Afecto| necesario para la etapa 3

## base_age: edad del personaje cuando Renpet tiene 12 (crece a la par de ella). Zephyr es un ser ancestral.
const NPC_DATA: Dictionary = {
	"soren": {
		"name": "Soren de Caelum", "title": "El Astrónomo de la Torre de Cristal", "location": "Observatorio de la Cumbre",
		"base_age": 14, "start": {"affection": 20, "respect": 25},
		"perk_desc": "Compañero en Expedición: +25% Daño Astral y revela puntos débiles (Guardia -15).",
		"bio": "Prodigio astronómico cuya madre fue desterrada por calcular una anomalía gravitatoria prohibida en la estrella que descendió hace doce años.",
		"dialogues": {
			"support": "\"¿Me trajiste café mientras reviso las tablas lunares? Gracias, Renpet... Contigo aquí, siento que la verdad del cielo no da tanto miedo.\"",
			"romance": "\"Mis manos tiemblan cuando ajustas mis lentes así... He medido mil constelaciones, pero ninguna brilla como tú cuando sonríes.\"",
			"gift": "\"¡Un cristal de cuarzo tallado! Es perfecto para la lente del telescopio de mi madre. Nunca olvidaré este gesto.\"",
			"provoke": "\"¿Te burlas del destierro de mi madre y rompes mis mapas? Escúchame bien, Renpet: demostraré ante el Senado que eres una anomalía peligrosa.\""
		}
	},
	"vespera": {
		"name": "Dama Vespera de Val-Astra", "title": "La Lanza de Escarcha y el Deber", "location": "Patio Ducal de Armas",
		"base_age": 14, "start": {"affection": -5, "respect": 35},
		"perk_desc": "Compañera en Expedición: +25% Daño Físico y rompe +20 de Guardia enemiga por golpe.",
		"bio": "Heredera militar presionada por un padre tiránico para superar a la hija del Héroe; en secreto escribe poesía lírica.",
		"dialogues": {
			"support": "\"¿No le contaste a nadie que estos versos eran míos? Eres más noble de lo que mi padre dice, Renpet. Cruzar lanzas contigo es un honor.\"",
			"romance": "\"Baja el arma un segundo... Cuando me miras de ese modo, toda mi disciplina marcial se derrite como nieve al sol.\"",
			"gift": "\"¿Una cinta de seda y un tomo de poesía antigua? Yo... lo guardaré bajo mi armadura, cerca del corazón.\"",
			"provoke": "\"¡Jamás perdonaré esta humillación! Juro por la sangre de Val-Astra que en nuestro próximo duelo no usaré armas de práctica.\""
		}
	},
	"kaelen": {
		"name": "Kaelen de los Canales", "title": "El Rey de los Huérfanos de Mercurio", "location": "Acueductos Subterráneos",
		"base_age": 15, "start": {"affection": 10, "respect": 15},
		"perk_desc": "Compañero en Expedición: +40% Oro obtenido en mazmorras y +20% Evasión.",
		"bio": "Líder rebelde de los bajos fondos que lucha por curar a los niños afectados por la Fiebre de Escoria que vierte la nobleza.",
		"dialogues": {
			"support": "\"¿Bajaste desde tu cómoda mansión con vendas y luz estelar para curar a los críos del canal? Tienes agallas, princesa de estrella.\"",
			"romance": "\"Sube al tejado conmigo, Renpet. Desde aquí arriba ni los dioses ni el Emperador pueden decirnos a quién amar.\"",
			"gift": "\"¿Medicinas puras y acero bien templado? Esto salvará media docena de vidas esta noche. Te debo una grande.\"",
			"provoke": "\"¿Así que miras por encima del hombro a los que vivimos en el barro? Cuida las cerraduras de tu mansión, hija del Héroe.\""
		}
	},
	"cassian": {
		"name": "Príncipe Cassian Aurelius", "title": "El Heredero del Sol Eclipsado", "location": "Jardines del Palacio de Alabastro",
		"base_age": 16, "start": {"affection": 15, "respect": 20},
		"perk_desc": "Compañero en Expedición: Autoridad Imperial (+20% a todos los daños y escudos).",
		"bio": "Príncipe heredero que descubre que su padre el Emperador planea usar a Renpet como sacrificio en el Solsticio de sus 20 años.",
		"dialogues": {
			"support": "\"En la corte todos me ven como una corona con patas. Solo cuando converso contigo en el jardín recuerdo quién soy en realidad.\"",
			"romance": "\"Si el trono de Aethelgard exige tu sacrificio para sostenerse, entonces prenderé fuego al trono con mis propias manos por ti.\"",
			"gift": "\"Un presente elegido con tanto gusto... Lo llevaré en la solapa durante la sesión del Senado Imperial.\"",
			"provoke": "\"Desprecias mi mano tendida y amenazas la paz del reino. Si eliges ser el enemigo de la Corona, la Corona responderá sin piedad.\""
		}
	},
	"mirari": {
		"name": "Mirari del Anfiteatro", "title": "La Cantora que Escucha el Tiempo", "location": "Anfiteatro de Cristal",
		"base_age": 14, "start": {"affection": 30, "respect": 30},
		"perk_desc": "Compañera en Expedición: Regenera +15% de HP cada turno y protege la Integridad del Sello.",
		"bio": "Oráculo y arpista ciega que escucha dos latidos en el pecho de Renpet: el corazón humano y el astro encadenado.",
		"dialogues": {
			"support": "\"Acércate, Renpet. Puedo oír cómo la canción de tu padre envuelve las cadenas de tu pecho para que no te lastimen.\"",
			"romance": "\"Mis ojos no ven las estrellas del cielo, pero cuando toco tu rostro siento la luz más hermosa de la creación.\"",
			"gift": "\"Cuerdas de plata resonante para mi arpa... El sonido que producen calma hasta los ecos más tristes del tiempo.\"",
			"provoke": "\"Tu corazón suena quebrado y lleno de ceniza cruel, Renpet. Si devoras a los inocentes, mi canto tendrá que sellarte.\""
		}
	},
	"zephyr": {
		"name": "Zephyr", "title": "La Voz Detrás del Espejo", "location": "Espejo Astral del Sueño",
		"base_age": 999, "start": {"affection": 0, "respect": 25},
		"perk_desc": "Simbiosis Interior: Reduce a la mitad el coste astral al liberar el fulgor oculto en combate.",
		"bio": "Una conciencia enigmática de ojos color eclipse que habita al otro lado de los sueños de Renpet desde que su marca estelar comenzó a despertar.",
		"dialogues": {
			"support": "\"¿Compartes tus recuerdos del hogar conmigo en vez de rezar para callarme? Qué extraña guardiana me ha tocado... Cálida y terca.\"",
			"romance": "\"Nos encerraron en el mismo firmamento esperando que la oscuridad nos consumiera, Renpet... y en cambio hiciste que un astro dormido se enamorara de ti.\"",
			"gift": "\"¿Ofreces una esquirla de luz al espejo para calmar este latido? Nadie había tenido piedad de mí en mil años.\"",
			"provoke": "\"¿Me tratas como a una sombra maldita? Sigue cerrando las puertas de tu mente, niña; algún día verás por qué la Diosa me teme.\""
		}
	}
}

# Estado mutable: npc_id -> {affection, respect, spark, stage, events_seen}
var state: Dictionary = {}
var interacted_this_bimester: bool = false

func _ready() -> void:
	reset_new_game()

func reset_new_game() -> void:
	state.clear()
	for npc_id in NPC_ORDER:
		var start: Dictionary = NPC_DATA[npc_id]["start"]
		state[npc_id] = {
			"affection": int(start["affection"]), "respect": int(start["respect"]),
			"spark": 0, "stage": 1, "events_seen": [] as Array
		}
	interacted_this_bimester = false

func reset_bimester_flags() -> void:
	interacted_this_bimester = false

# ------------------------------------------------------------------------------
# CONSULTAS
# ------------------------------------------------------------------------------
func get_data(npc_id: String) -> Dictionary:
	var base: Dictionary = NPC_DATA.get(npc_id, {})
	if npc_id == "zephyr" and not base.is_empty() and GameState.get_secret_tier() >= 2:
		var revealed := base.duplicate(true)
		revealed["name"] = "Zephyr (Nyx-Aethel)"
		revealed["title"] = "El Lucero Prisionero Detrás del Espejo"
		revealed["bio"] = "El espíritu primordial del libre albedrío encerrado por la Diosa Renpet-Neheh dentro de la estrella que se convirtió en tu hija."
		return revealed
	return base

func get_state(npc_id: String) -> Dictionary:
	return state.get(npc_id, {})

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
	var aff: int = int(c["affection"])
	var res: int = int(c["respect"])
	var spk: int = int(c["spark"])

	if aff >= 65 and res >= 55 and spk >= 60:
		return "♥ AMOR VERDADERO (Amantes Destinados)"
	elif aff < 20 and res >= 50 and spk >= 45:
		return "♦ TENSIÓN ENEMIGOS-A-AMANTES"
	elif aff < 0 and spk >= 50:
		return "♠ OBSESIÓN TRÁGICA"
	elif aff >= 65 and res >= 60 and spk < 60:
		return "★ MEJOR AMIGO / HERMANO DE JURAMENTO"
	elif aff >= 35 and res >= 30:
		return "✦ Confidente y Aliado Leal"
	elif aff <= -45 and res >= 40:
		return "⚔ NÉMESIS HONORABLE (Duelo Jurado)"
	elif aff <= -45 and res < 40:
		return "☠ ODIO MORTAL (Saboteador / Enemigo)"
	elif aff < 0 and res >= 35:
		return "⚡ Rivalidad Feroz"
	return "• Conocido de Aethelgard"

## Personaje más cercano (para cartas y charlas). Devuelve {} si ninguno supera el umbral.
func get_closest_bond() -> Dictionary:
	var best: Dictionary = {}
	var best_aff: int = STAGE2_THRESHOLD - 1
	for npc_id in NPC_ORDER:
		if not is_available(npc_id):
			continue
		var aff: int = int(state[npc_id]["affection"])
		if aff > best_aff:
			best_aff = aff
			best = {"id": npc_id, "name": NPC_DATA[npc_id]["name"], "affection": aff}
	return best

func get_worst_bond() -> Dictionary:
	var worst: Dictionary = {}
	var worst_aff: int = -STAGE2_THRESHOLD + 1
	for npc_id in NPC_ORDER:
		if not is_available(npc_id):
			continue
		var aff: int = int(state[npc_id]["affection"])
		if aff < worst_aff:
			worst_aff = aff
			worst = {"id": npc_id, "name": NPC_DATA[npc_id]["name"], "affection": aff}
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
# SALIDAS A LA CAPITAL (1 por bimestre)
# ------------------------------------------------------------------------------
## action_type: support | romance | gift | provoke
func interact_with_candidate(npc_id: String, action_type: String) -> Dictionary:
	if not state.has(npc_id):
		return {"ok": false, "msg": "Personaje no encontrado."}
	if not is_available(npc_id):
		return {"ok": false, "msg": get_locked_reason(npc_id)}
	if interacted_this_bimester:
		return {"ok": false, "msg": "%s ya realizó su salida social en la capital durante este bimestre. Espera al siguiente turno." % GameState.daughter_name}
	if action_type == "romance" and not romance_available(npc_id):
		return {"ok": false, "msg": "Esa opción todavía no está disponible: " + get_romance_locked_note()}

	var c: Dictionary = state[npc_id]
	var data: Dictionary = NPC_DATA[npc_id]
	var reply: String = ""
	var effect_summary: String = ""

	GameState.begin_batch()
	match action_type:
		"support":
			_add(c, "affection", 16)
			_add(c, "respect", 14)
			GameState.modify_stat("human_anchor", 5)
			var summary: String = "+16 Afecto, +14 Respeto, +5 Anclaje Humano"
			if npc_id == "zephyr":
				GameState.modify_stat("abyssal_sync", 10)
				summary += ", +10 Sincronía"
			reply = data["dialogues"]["support"]
			effect_summary = summary
		"romance":
			_add(c, "spark", 20)
			_add(c, "affection", 12)
			GameState.modify_stat("stress", -10)
			GameState.modify_stat("human_anchor", 6)
			reply = data["dialogues"]["romance"]
			effect_summary = "+20 Chispa Romántica, +12 Afecto, -10 Estrés, +6 Anclaje Humano"
		"gift":
			if not GameState.modify_gold(-SOCIAL_COST_GIFT):
				GameState.end_batch()
				return {"ok": false, "msg": "Necesitas %d G para comprar un regalo especial en el Bazar." % SOCIAL_COST_GIFT}
			_add(c, "affection", 22)
			_add(c, "respect", 10)
			reply = data["dialogues"]["gift"]
			effect_summary = "-%d Oro | +22 Afecto, +10 Respeto" % SOCIAL_COST_GIFT
		"provoke":
			_add(c, "affection", -30)
			if GameState.temple + GameState.erudicion >= 300:
				_add(c, "respect", 12)
				effect_summary = "-30 Afecto, +12 Respeto (Rivalidad/Némesis), +6 Entropía"
			else:
				_add(c, "respect", -18)
				effect_summary = "-30 Afecto, -18 Respeto (Odio/Desprecio), +6 Entropía"
			GameState.modify_stat("entropia", 6)
			reply = data["dialogues"]["provoke"]
		_:
			GameState.end_batch()
			return {"ok": false, "msg": "Acción desconocida."}
	interacted_this_bimester = true
	GameState.end_batch()

	_update_stage(npc_id)
	var new_status: String = get_relationship_status_title(npc_id)
	Chronicle.record_event("bond_%s_%s" % [action_type, npc_id], "Salida con %s (%s)" % [data["name"], new_status], reply, "social", 3)
	relationship_updated.emit(npc_id)
	return {"ok": true, "speaker": "%s — %s" % [data["name"], new_status], "reply": reply, "effects": effect_summary}

# ------------------------------------------------------------------------------
# ESCENAS DE HISTORIA (una por etapa; consumen la salida del bimestre)
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
	if TimeManager.get_act_number() < next_stage:
		return {"ok": false, "reason": "La escena del Acto %d con %s se desbloquea cuando comience ese Acto." % [next_stage, NPC_DATA[npc_id]["name"]]}
	if int(c["stage"]) < next_stage:
		var needed: int = STAGE2_THRESHOLD if next_stage == 2 else STAGE3_THRESHOLD
		return {"ok": false, "reason": "Necesitas un vínculo más profundo con %s (Afecto o Rencor de ±%d) para vivir su escena del Acto %d." % [NPC_DATA[npc_id]["name"], needed, next_stage]}
	if interacted_this_bimester:
		return {"ok": false, "reason": "%s ya realizó su salida social este bimestre." % GameState.daughter_name}
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
	interacted_this_bimester = true
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
func _add(c: Dictionary, key: String, delta: int) -> void:
	var lo: int = 0 if key == "spark" else -100
	c[key] = clampi(int(c[key]) + delta, lo, 100)

func _update_stage(npc_id: String) -> void:
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
	return {"state": state.duplicate(true), "interacted_this_bimester": interacted_this_bimester}

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
			var seen: Array = []
			for e in s.get("events_seen", []):
				if int(e) in [1, 2, 3] and not seen.has(int(e)):
					seen.append(int(e))
			c["events_seen"] = seen
	interacted_this_bimester = bool(d.get("interacted_this_bimester", false))
	# Partidas antiguas pudieron guardar Chispa antes de los 18: se elimina por la regla de edad.
	if GameState.age < GameState.ROMANCE_MIN_AGE:
		for npc_id in NPC_ORDER:
			state[npc_id]["spark"] = 0
