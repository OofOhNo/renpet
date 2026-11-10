extends Node

## RivalMirror - Rivales en Espejo (Fase 6.2).
## Los 4 rivales de Aethelgard entrenan cada bimestre en paralelo a Renpet ("Espejo Adaptativo"):
##  - Crecen a un ritmo propio; si Renpet se matricula en SU actividad, entrenan más (Vespera el doble).
##  - Nunca quedan muy por debajo de ella (suelo espejo) ni se disparan si ya la superan por mucho (freno).
##  - En las aulas y oficios compartidos se disparan Choques de Aula (Duelo de Pizarra, etc.).
##  - Pueden ser desafiados a un Duelo de Prestigio (1 por bimestre).

signal rival_ranks_updated()

const RIVAL_ORDER: Array[String] = ["vespera", "soren", "lyra", "caelum"]

const RIVAL_DATA: Dictionary = {
	"vespera": {
		"name": "Dama Vespera", "full_name": "Dama Vespera de Val-Astra",
		"domain": "Marcial (Temple + Destreza)", "stats": ["temple", "destreza"],
		"base_score": 260, "growth": 28, "mirror": 0.92, "train_boost": 2.0,
		"doubles_on": ["class_armory"], "clash_name": "Asalto de Espadas de Madera",
		"train_line": "Dama Vespera te vio inscrita en la Academia de Armas y entrenó el doble este bimestre."
	},
	"soren": {
		"name": "Soren de Caelum", "full_name": "Soren de Caelum",
		"domain": "Académico (Erudición + Resonancia)", "stats": ["erudicion", "resonancia"],
		"base_score": 255, "growth": 26, "mirror": 0.90, "train_boost": 1.5,
		"doubles_on": ["class_astrolabe", "job_clockwork"], "clash_name": "Duelo de Pizarra",
		"train_line": "Soren se encerró en la Torre a estudiar para igualarte en los exámenes."
	},
	"lyra": {
		"name": "Lady Lyra", "full_name": "Lady Lyra de Meridia",
		"domain": "Corte y Gala (Gracia + Magnetismo)", "stats": ["gracia", "magnetismo"],
		"base_score": 245, "growth": 25, "mirror": 0.88, "train_boost": 1.5,
		"doubles_on": ["class_conservatory", "job_amphitheater"], "clash_name": "Crítica de Etiqueta",
		"train_line": "Lady Lyra intensificó sus tardes de té y sus rumores en los salones de la Corte."
	},
	"caelum": {
		"name": "Caelum 'El Perro Gris'", "full_name": "Caelum 'El Perro Gris'",
		"domain": "Caza y Sombra (Destreza + Gravedad)", "stats": ["destreza", "gravedad"],
		"base_score": 240, "growth": 24, "mirror": 0.88, "train_boost": 1.5,
		"doubles_on": ["job_caravan", "job_canals"], "clash_name": "Disputa de Contratos",
		"train_line": "Caelum te vio competir por los contratos de caza y salió a rastrear por su cuenta."
	}
}

var scores: Dictionary = {}                 # rival_id -> puntaje
var challenged_this_bimester: bool = false
var clashed_this_bimester: Dictionary = {}  # rival_id -> true

func _ready() -> void:
	reset_new_game()

func reset_new_game() -> void:
	scores.clear()
	for rid in RIVAL_ORDER:
		scores[rid] = int(RIVAL_DATA[rid]["base_score"])
	challenged_this_bimester = false
	clashed_this_bimester.clear()

func reset_bimester_flags() -> void:
	challenged_this_bimester = false
	clashed_this_bimester.clear()

# ------------------------------------------------------------------------------
# CONSULTAS
# ------------------------------------------------------------------------------
func get_data(rival_id: String) -> Dictionary:
	return RIVAL_DATA.get(rival_id, {})

func get_renpet_score(rival_id: String) -> int:
	if not RIVAL_DATA.has(rival_id):
		return 0
	var total: int = 0
	for sk in RIVAL_DATA[rival_id]["stats"]:
		total += GameState.get_stat(sk)
	return total

func get_rival_score(rival_id: String) -> int:
	return int(scores.get(rival_id, 0))

## Marcador de rivalidad: {"lead": +n si Renpet gana, "label": texto}
func get_standing(rival_id: String) -> Dictionary:
	var mine: int = get_renpet_score(rival_id)
	var theirs: int = get_rival_score(rival_id)
	var diff: int = mine - theirs
	var label: String = "Empate técnico"
	if diff > 40:
		label = "Vas por delante"
	elif diff > 0:
		label = "Ligera ventaja"
	elif diff < -40:
		label = "Te lleva ventaja"
	elif diff < 0:
		label = "Muy parejo"
	return {"mine": mine, "theirs": theirs, "diff": diff, "label": label}

# ------------------------------------------------------------------------------
# ENTRENAMIENTO EN ESPEJO (cada bimestre)
# executed_ids: ids de las actividades que Renpet ejecutó en el bimestre
# ------------------------------------------------------------------------------
func advance_bimester(executed_ids: Array) -> Array[String]:
	var lines: Array[String] = []
	for rid in RIVAL_ORDER:
		var d: Dictionary = RIVAL_DATA[rid]
		var mine: int = get_renpet_score(rid)
		var old_score: int = int(scores[rid])

		var intensity: float = 1.0
		for act_id in d["doubles_on"]:
			if executed_ids.has(act_id):
				intensity = float(d["train_boost"])
				break
		var growth: float = float(d["growth"]) * intensity
		if old_score > int(mine * 1.15):
			growth *= 0.5   # freno: ya la supera por mucho

		var mirrored: int = int(mine * float(d["mirror"]))   # suelo espejo
		var new_score: int = clampi(maxi(old_score + int(round(growth)), mirrored), 0, 2400)
		scores[rid] = new_score
		if intensity > 1.0:
			lines.append("%s (+%d)" % [d["train_line"], new_score - old_score])
	rival_ranks_updated.emit()
	return lines

# ------------------------------------------------------------------------------
# CHOQUES DE AULA (Fase 6.2): se resuelven dentro del bimestre
# Devuelve {"rival_id","name","clash_name","won": bool,"status": "inspired"|"stung","text": String, "stress": int}
# ------------------------------------------------------------------------------
func resolve_classroom_clash(rival_id: String, activity_name: String, block_idx: int) -> Dictionary:
	if not RIVAL_DATA.has(rival_id) or clashed_this_bimester.has(rival_id):
		return {}
	clashed_this_bimester[rival_id] = true
	var d: Dictionary = RIVAL_DATA[rival_id]
	var mine: int = get_renpet_score(rival_id)
	var theirs: int = get_rival_score(rival_id)
	var rng := GameState.det_rng("clash_" + rival_id, block_idx)
	var factor: float = rng.randf_range(0.94, 1.06)
	var won: bool = float(mine) >= float(theirs) * factor

	var result: Dictionary = {"rival_id": rival_id, "name": d["name"], "clash_name": d["clash_name"], "won": won}
	if won:
		result["status"] = "inspired"
		result["stress"] = -10
		result["text"] = "«%s» en %s: %s se impuso a %s (%d vs %d). Estado: Inspirada (-10 Estrés, +20%% de ganancia el resto del bimestre)." % [
			d["clash_name"], activity_name, GameState.daughter_name, d["name"], mine, theirs]
		_nudge_respect(rival_id, 6)
		Chronicle.record_event("clash_win_" + rival_id, "%s: victoria ante %s" % [d["clash_name"], d["name"]],
			"%s ganó el choque de aula (%d vs %d)." % [GameState.daughter_name, mine, theirs], "rivalry", 3)
	else:
		result["status"] = "stung"
		result["stress"] = 10
		result["text"] = "«%s» en %s: %s se impuso a %s (%d vs %d). Estado: Picada en su Orgullo (+10 Estrés, +35%% de ganancia si repite esta actividad en el siguiente bloque)." % [
			d["clash_name"], activity_name, d["name"], GameState.daughter_name, theirs, mine]
		_nudge_respect(rival_id, 2)
		Chronicle.record_event("clash_lose_" + rival_id, "%s: derrota ante %s" % [d["clash_name"], d["name"]],
			"%s perdió el choque de aula (%d vs %d)." % [GameState.daughter_name, mine, theirs], "rivalry", 3)
	return result

# ------------------------------------------------------------------------------
# DUELO DE PRESTIGIO (1 por bimestre)
# ------------------------------------------------------------------------------
func challenge_rival_duel(rival_id: String) -> Dictionary:
	if not RIVAL_DATA.has(rival_id):
		return {"ok": false, "msg": "Rival no encontrado."}
	if challenged_this_bimester:
		return {"ok": false, "msg": "Ya disputaste un Duelo de Prestigio oficial en este bimestre."}
	challenged_this_bimester = true
	var d: Dictionary = RIVAL_DATA[rival_id]
	var my_score: int = get_renpet_score(rival_id)
	var riv_score: int = get_rival_score(rival_id)
	var main_stat: String = d["stats"][0]
	var main_label: String = GameState.get_stat_label(main_stat)

	GameState.begin_batch()
	var result: Dictionary
	if my_score >= riv_score:
		GameState.modify_gold(150)
		GameState.modify_stat(main_stat, 14)
		GameState.modify_stat("magnetismo", 10)
		_nudge_respect(rival_id, 16)
		Chronicle.record_event("duel_win_" + rival_id, "Victoria de Prestigio contra %s" % d["name"],
			"%s superó a %s en %s (%d vs %d)." % [GameState.daughter_name, d["name"], d["domain"], my_score, riv_score], "rivalry", 4)
		result = {
			"ok": true, "won": true, "speaker": "Duelo de Prestigio — ¡VICTORIA!",
			"reply": "¡%s superó a %s en %s (%d vs %d) ante toda la Academia Real!" % [GameState.daughter_name, d["name"], d["domain"], my_score, riv_score],
			"effects": "+150 Oro, +14 %s, +10 Magnetismo, +16 Respeto" % main_label
		}
	else:
		GameState.modify_stat(main_stat, 10)
		GameState.modify_stat("stress", 8)
		scores[rival_id] = riv_score + 10
		Chronicle.record_event("duel_lose_" + rival_id, "Derrota honorable ante %s" % d["name"],
			"%s cayó ante %s (%d vs %d) y prometió volver más fuerte." % [GameState.daughter_name, d["name"], riv_score, my_score], "rivalry", 3)
		result = {
			"ok": true, "won": false, "speaker": "Duelo de Prestigio — Derrota Honorable",
			"reply": "%s se impuso por %d a %d en %s. %s aprendió de la derrota y prometió volver más fuerte." % [d["name"], riv_score, my_score, d["domain"], GameState.daughter_name],
			"effects": "+10 %s (Aprendizaje), +8 Estrés" % main_label
		}
	GameState.end_batch()
	rival_ranks_updated.emit()
	return result

func _nudge_respect(rival_id: String, amount: int) -> void:
	# Vespera y Soren también son candidatos de vínculo: un buen duelo les gana respeto.
	if RelationshipManager.state.has(rival_id):
		var c: Dictionary = RelationshipManager.state[rival_id]
		c["respect"] = clampi(int(c["respect"]) + amount, -100, 100)

# ------------------------------------------------------------------------------
# GUARDADO
# ------------------------------------------------------------------------------
func serialize() -> Dictionary:
	return {
		"scores": scores.duplicate(),
		"challenged_this_bimester": challenged_this_bimester,
		"clashed_this_bimester": clashed_this_bimester.keys()
	}

func deserialize(d: Dictionary) -> void:
	reset_new_game()
	var saved: Variant = d.get("scores", {})
	if typeof(saved) == TYPE_DICTIONARY:
		for rid in RIVAL_ORDER:
			if saved.has(rid):
				scores[rid] = clampi(int(saved[rid]), 0, 2400)
	challenged_this_bimester = bool(d.get("challenged_this_bimester", false))
	for rid in d.get("clashed_this_bimester", []):
		clashed_this_bimester[str(rid)] = true
