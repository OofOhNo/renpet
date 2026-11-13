extends Node

## RelationshipManager - Matriz 3D de Vínculos (Fase 6.1 y 6.3).
## Ejes por personaje: Afecto (-100..+100), Respeto (-100..+100) y Chispa Romántica (0..100).
## REGLA DE EDAD: la Chispa Romántica, las citas y las elecciones románticas de las escenas
## solo existen cuando Renpet tiene 18 años o más (GameState.ROMANCE_MIN_AGE) y el personaje
## también es adulto. Antes de eso, las rutas disponibles son Amistad y Rivalidad/Némesis.

signal relationship_updated(npc_id: String)

const NPC_ORDER: Array[String] = ["soren", "vespera", "kaelen", "cassian", "mirari", "zephyr"]

const SOCIAL_COST_GIFT: int = 75
const MAX_SOCIAL_POINTS: int = 3
const MAX_ACTIONS_PER_NPC: int = 2
const STAGE2_THRESHOLD: int = 40   # |Afecto| necesario para la etapa 2
const STAGE3_THRESHOLD: int = 78   # |Afecto| necesario para la etapa 3

## base_age: edad del personaje cuando Renpet tiene 12 (crece a la par de ella). Zephyr es un ser ancestral.
const NPC_DATA: Dictionary = {
	"soren": {
		"name": "Soren de Caelum", "title": "El Astrónomo de la Torre de Cristal", "location": "Torre de Cristal",
		"role_stat": "erudicion", "base_age": 14, "start": {"affection": 2, "respect": 8},
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
		"role_stat": "temple", "base_age": 14, "start": {"affection": -4, "respect": 12},
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
		"role_stat": "destreza", "base_age": 15, "start": {"affection": 0, "respect": 6},
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
		"role_stat": "magnetismo", "base_age": 16, "start": {"affection": 0, "respect": 8},
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
		"role_stat": "gracia", "base_age": 14, "start": {"affection": 4, "respect": 10},
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
		"role_stat": "resonancia", "base_age": 999, "start": {"affection": 0, "respect": 6},
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
	}
}

# Estado mutable: npc_id -> {known, affection, respect, spark, stage, actions_bimester, events_seen}
var state: Dictionary = {}
var social_points_left: int = MAX_SOCIAL_POINTS
var interacted_this_bimester: bool = false
var strolled_this_bimester: bool = false

func _ready() -> void:
	reset_new_game()

func reset_new_game() -> void:
	state.clear()
	for npc_id in NPC_ORDER:
		var start: Dictionary = NPC_DATA[npc_id]["start"]
		state[npc_id] = {
			"known": false,
			"affection": int(start["affection"]), "respect": int(start["respect"]),
			"spark": 0, "stage": 1, "actions_bimester": 0, "events_seen": [] as Array
		}
	social_points_left = MAX_SOCIAL_POINTS
	interacted_this_bimester = false
	strolled_this_bimester = false

func reset_bimester_flags() -> void:
	for npc_id in NPC_ORDER:
		if state.has(npc_id):
			state[npc_id]["actions_bimester"] = 0
	social_points_left = MAX_SOCIAL_POINTS
	interacted_this_bimester = false
	strolled_this_bimester = false

# ------------------------------------------------------------------------------
# CONSULTAS
# ------------------------------------------------------------------------------
func _personalize(text: String) -> String:
	if GameState.daughter_name == "Renpet" or GameState.daughter_name.strip_edges() == "":
		return text
	return text.replace("Renpet-Neheh", "__RN_GODDESS__").replace("Renpet", GameState.daughter_name).replace("__RN_GODDESS__", "Renpet-Neheh")

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

## action_type: meet | chat (alias support) | train | gift_item | gift (legacy) | romance | provoke
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

	var c: Dictionary = state[npc_id]
	var raw: Dictionary = NPC_DATA[npc_id]
	var data: Dictionary = get_data(npc_id)
	var reply: String = ""
	var effect_summary: String = ""
	var norm_action: String = "chat" if action_type == "support" else action_type

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
			reply = str(raw["dialogues"]["support"])
		"train":
			var r_stat: String = str(raw.get("role_stat", "temple"))
			var gain: int = GameState.modify_stat(r_stat, 14)
			GameState.modify_stat("stress", 4)
			_add(c, "affection", 7)
			_add(c, "respect", 12)
			reply = str(raw["dialogues"].get("train", raw["dialogues"]["support"]))
			effect_summary = "+%d %s, +12 Respeto, +7 Afecto (+4 Estrés)" % [gain, GameState.get_stat_label(r_stat)]
		"romance":
			_add(c, "spark", 18)
			_add(c, "affection", 12)
			GameState.modify_stat("stress", -8)
			GameState.modify_stat("human_anchor", 5)
			reply = str(raw["dialogues"]["romance"])
			effect_summary = "+18 Chispa Romántica, +12 Afecto, -8 Estrés, +5 Anclaje"
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
			reply = str(raw["dialogues"]["gift"])
			effect_summary = "%s (%s): +%d Afecto, +%d Respeto" % [
				str(g["name"]), "¡Favorito!" if liked else "Apreciado", aff_g, resp_g
			]
		"gift":
			if not GameState.modify_gold(-SOCIAL_COST_GIFT):
				GameState.end_batch()
				return {"ok": false, "msg": "Necesitas %d G o un obsequio comprado en las tiendas de Aethelgard." % SOCIAL_COST_GIFT}
			_add(c, "affection", 16)
			_add(c, "respect", 8)
			reply = str(raw["dialogues"]["gift"])
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
			reply = str(raw["dialogues"]["provoke"])
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
		"strolled_this_bimester": strolled_this_bimester
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
	# Partidas antiguas pudieron guardar Chispa antes de los 18: se elimina por la regla de edad.
	if GameState.age < GameState.ROMANCE_MIN_AGE:
		for npc_id in NPC_ORDER:
			state[npc_id]["spark"] = 0
