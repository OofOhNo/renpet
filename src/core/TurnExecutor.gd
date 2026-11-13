extends Node

## TurnExecutor - Planificador de Doble Agenda y Resolución Bimensual (Fase 4).
## Toda la lógica del turno vive aquí (no en la interfaz): la UI solo planifica y muestra el informe.
##
## Agenda de Renpet: 3 bloques de 20 días.   Agenda del Padre: 100 puntos de Energía por bimestre.
## Resolución: Padre -> 3 bloques (cobros, ganancias, choque de aula, micro-evento, colapso por estrés)
##             -> sinergias -> rivales -> mantenimiento -> avance de calendario -> carta anual.

signal plan_changed()

const BLOCKS_PER_BIMESTER: int = 3
const DAYS_PER_BLOCK: int = 20
const STRESS_FATIGUE_THRESHOLD: int = 80   # >= : -25% de ganancias
const STRESS_COLLAPSE_THRESHOLD: int = 100
const MICRO_EVENT_CHANCE: int = 40         # % por bloque
const COLLAPSE_CLINIC_FEE: int = 60
const COLLAPSE_STRESS_AFTER: int = 55

var agenda: Array[String] = ["class_armory", "class_astrolabe", "rest_manor"]
var father_plan: Array[String] = []

func reset_new_game() -> void:
	agenda = ["class_armory", "class_astrolabe", "rest_manor"]
	father_plan.clear()
	plan_changed.emit()

# ------------------------------------------------------------------------------
# PLANIFICACIÓN
# ------------------------------------------------------------------------------
func set_agenda_slot(slot: int, act_id: String) -> void:
	if slot < 0 or slot >= BLOCKS_PER_BIMESTER:
		return
	if CatalogDB.get_activity(act_id).is_empty():
		return
	agenda[slot] = act_id
	plan_changed.emit()

func get_father_energy_used() -> int:
	var used: int = 0
	for tid in father_plan:
		used += int(CatalogDB.get_father_task(tid).get("energy", 0))
	return used

func is_father_task_planned(task_id: String) -> bool:
	return father_plan.has(task_id)

## ¿Se puede añadir esta tarea? {"ok": bool, "msg": String}
func can_plan_father_task(task_id: String) -> Dictionary:
	var task: Dictionary = CatalogDB.get_father_task(task_id)
	if task.is_empty():
		return {"ok": false, "msg": "Tarea desconocida."}
	if father_plan.has(task_id):
		return {"ok": true, "msg": ""}   # se puede quitar
	var energy_left: int = GameState.father_energy - get_father_energy_used()
	if int(task["energy"]) > energy_left:
		return {"ok": false, "msg": "Te quedan %d de Energía Paternal y esta tarea cuesta %d." % [energy_left, int(task["energy"])]}
	for other in father_plan:
		if (CatalogDB.get_father_task(other).get("excludes", []) as Array).has(task_id) or (task["excludes"] as Array).has(other):
			return {"ok": false, "msg": "No puedes hacerlo a la vez que «%s»: el Padre no puede estar en dos sitios." % CatalogDB.get_father_task(other)["name"]}
	return {"ok": true, "msg": ""}

func toggle_father_task(task_id: String) -> Dictionary:
	if father_plan.has(task_id):
		father_plan.erase(task_id)
		plan_changed.emit()
		return {"ok": true, "msg": ""}
	var chk: Dictionary = can_plan_father_task(task_id)
	if not chk["ok"]:
		return chk
	father_plan.append(task_id)
	plan_changed.emit()
	return {"ok": true, "msg": ""}

func is_supervised() -> bool:
	return father_plan.has("supervise")

# ------------------------------------------------------------------------------
# VALIDACIÓN Y VISTA PREVIA
# ------------------------------------------------------------------------------
## {"ok": bool, "msg": String, "net_gold": int, "stress": int, "fatigue_warning": bool, "multiplier_notes": Array[String]}
func validate_and_preview() -> Dictionary:
	var gold: int = GameState.gold
	var net: int = 0
	var stress_total: int = 0

	for tid in father_plan:
		var t: Dictionary = CatalogDB.get_father_task(tid)
		var g: int = _father_gold(t)
		gold += g
		net += g

	for i in range(BLOCKS_PER_BIMESTER):
		var act: Dictionary = CatalogDB.get_activity(agenda[i])
		if act.is_empty():
			return {"ok": false, "msg": "Falta elegir la actividad del Decano %d." % (i + 1)}
		if GameState.age < int(act.get("min_age", 12)):
			return {"ok": false, "msg": "«%s» requiere %d años de edad." % [act["name"], int(act["min_age"])]}
		var wage: int = _activity_gold(act)
		if gold + wage < 0:
			return {"ok": false, "msg": "No alcanza el oro para «%s» (necesitas %d G y tendrás %d G)." % [act["name"], -wage, gold]}
		gold += wage
		net += wage
		stress_total += int(act["stress"])

	var notes: Array[String] = []
	if is_supervised():
		notes.append("Supervisión paterna: +30%% de eficacia%s" % (" (+20% más por Orgullo del Hogar)" if GameState.has_trait_prefix("Orgullo del Hogar") else ""))
	var bim: Dictionary = TimeManager.get_bimester_info()
	if not (bim["gain_mods"] as Dictionary).is_empty() or float(bim["income_mod"]) > 0.0:
		notes.append("%s: %s" % [bim["name"], bim["bonus_desc"]])
	return {
		"ok": true, "msg": "", "net_gold": net, "stress": stress_total,
		"fatigue_warning": GameState.stress >= STRESS_FATIGUE_THRESHOLD,
		"multiplier_notes": notes
	}

# ------------------------------------------------------------------------------
# RESOLUCIÓN BIMENSUAL
# ------------------------------------------------------------------------------
## Ejecuta los 60 días. Devuelve un informe estructurado (ver claves al final).
func resolve_bimester() -> Dictionary:
	var check: Dictionary = validate_and_preview()
	if not check["ok"]:
		return {"ok": false, "msg": check["msg"]}

	var report: Dictionary = {
		"ok": true,
		"bimester_name": TimeManager.get_bimester_info()["name"],
		"year": TimeManager.current_year, "turn": TimeManager.current_total_turn,
		"father": [] as Array, "blocks": [] as Array, "synergies": [] as Array,
		"rivals": [] as Array, "upkeep": [] as Array, "year_end": {}, "campaign_finished": false
	}
	var before: Dictionary = _snapshot()
	var executed_ids: Array = []
	var inspired: bool = false
	var stung_activity: String = ""
	var supervised: bool = is_supervised()
	var daughter: String = GameState.daughter_name

	GameState.begin_batch()

	# --- 1. AGENDA DEL PADRE -------------------------------------------------
	for tid in father_plan:
		report["father"].append(_apply_father_task(tid))

	# --- 2. LOS 3 BLOQUES DE 20 DÍAS -----------------------------------------
	var collapsed: bool = false
	for i in range(BLOCKS_PER_BIMESTER):
		var act: Dictionary = CatalogDB.get_activity(agenda[i])
		var block: Dictionary = {"index": i + 1, "notes": [] as Array, "gains": [] as Array}

		# Colapso por estrés del bloque anterior: la Doctora Helena la atiende
		if collapsed:
			act = CatalogDB.get_activity("rest_manor")
			var fee: int = COLLAPSE_CLINIC_FEE if GameState.gold >= COLLAPSE_CLINIC_FEE else 0
			if fee > 0:
				GameState.modify_gold(-fee)
			var now_stress: int = GameState.stress
			GameState.modify_stat("stress", COLLAPSE_STRESS_AFTER - now_stress)
			block["notes"].append("Colapso por agotamiento: la Doctora Helena atendió a %s en secreto%s. Este bloque se convierte en reposo forzoso." % [daughter, (" (-%d G)" % fee) if fee > 0 else ""])
			Chronicle.record_event("stress_collapse", "Colapso por agotamiento",
				"%s cayó rendida tras acumular demasiado estrés. La Doctora Helena la cuidó sin hacer preguntas." % daughter, "family", 4)
			collapsed = false
		block["activity_id"] = act["id"]
		block["name"] = act["name"]
		executed_ids.append(act["id"])

		# Cobro / paga (empleos urbanos con bono de bimestre; recitales con bono de sinergia)
		var money: int = _activity_gold(act)
		if money != 0:
			GameState.modify_gold(money)
		block["gold"] = money

		# Estrés base y variación de Sello de la actividad
		var stress_applied: int = GameState.modify_stat("stress", int(act["stress"]))
		block["stress_delta"] = stress_applied
		var seal_applied: int = 0
		if int(act.get("seal_delta", 0)) != 0:
			seal_applied = GameState.modify_stat("seal_integrity", int(act["seal_delta"]))
		block["seal_delta"] = seal_applied

		# Ganancias de atributos con multiplicadores
		var fac_key: String = str(act.get("facility_bonus", ""))
		var fac_bonus: int = (int(GameState.estate_levels.get(fac_key, 1)) - 1) * 4 if fac_key != "" else 0
		var stung_active: bool = stung_activity == act["id"]
		for sk in act["stats"].keys():
			var base_v: int = int(act["stats"][sk])
			var final_v: int = base_v
			if base_v > 0:
				var main_bonus: int = fac_bonus if base_v >= 15 else 0
				var mult: float = _gain_multiplier(sk, act, supervised, inspired, stung_active)
				final_v = int(round(float(scaled_base(sk, base_v) + main_bonus) * mult))
			var applied: int = GameState.modify_stat(sk, final_v)
			if applied != 0:
				(block["gains"] as Array).append({"stat": sk, "label": GameState.get_stat_label(sk), "delta": applied})
		stung_activity = ""
		if fac_bonus > 0:
			block["notes"].append("%s nivel %d: +%d a las ganancias principales." % [_facility_name(fac_key), int(GameState.estate_levels[fac_key]), fac_bonus])

		# Choque de aula con el rival (Fase 6.2)
		var rival_id: String = str(act.get("rival_id", ""))
		if rival_id != "":
			var clash: Dictionary = RivalMirror.resolve_classroom_clash(rival_id, act["name"], i)
			if not clash.is_empty():
				block["clash"] = clash
				GameState.modify_stat("stress", int(clash["stress"]))
				if clash["status"] == "inspired":
					inspired = true
				else:
					stung_activity = str(act["id"])

		# Botín ocasional
		if act.has("loot_item"):
			var rng_loot := GameState.det_rng("loot", i)
			if rng_loot.randi_range(1, 100) <= int(act.get("loot_chance", 0)):
				var item_id: String = str(act["loot_item"])
				GameState.materials_inventory[item_id] = int(GameState.materials_inventory.get(item_id, 0)) + 1
				block["notes"].append("Hallazgo: +1 %s." % CatalogDB.get_material(item_id).get("name", item_id))

		# Micro-evento de aula u oficio (Fase 4.3)
		var ev_result: Dictionary = _roll_micro_event(act, i)
		if not ev_result.is_empty():
			block["event"] = ev_result

		# ¿Colapsa antes del siguiente bloque?
		if GameState.stress >= STRESS_COLLAPSE_THRESHOLD and i < BLOCKS_PER_BIMESTER - 1:
			collapsed = true
		(report["blocks"] as Array).append(block)

	# --- 3. SINERGIAS, RIVALES, SOCIAL -----------------------------------------
	for syn in CatalogDB.check_and_unlock_synergies():
		(report["synergies"] as Array).append({"title": syn["title"], "desc": syn["bonus_desc"]})
	report["rivals"] = RivalMirror.advance_bimester(executed_ids)

	Chronicle.chatted_this_bimester = false
	RelationshipManager.reset_bimester_flags()
	RivalMirror.reset_bimester_flags()
	CrucibleManager.reset_bimester_flags()
	ExplorationCombat.reset_bimester_flags()
	father_plan.clear()

	# --- 4. MANTENIMIENTO Y AVANCE DE CALENDARIO -----------------------------
	GameState.end_batch()
	var adv: Dictionary = TimeManager.advance_bimester()
	report["upkeep"] = adv["upkeep"]
	if int(adv["year_completed"]) > 0:
		ExplorationCombat.reset_year_flags()
		report["year_end"] = Chronicle.assemble_annual_letter(int(adv["year_completed"]))
	report["campaign_finished"] = bool(adv["finished"])

	Chronicle.record_event("turn_%d" % int(report["turn"]), "Bimestre completado: %s" % report["bimester_name"],
		"%s completó los tres decanos del bimestre." % daughter, "turn", 1)
	report["summary"] = _diff_snapshot(before, _snapshot())
	report["new_turn"] = TimeManager.current_total_turn
	SaveManager.autosave()
	plan_changed.emit()
	return report

# ------------------------------------------------------------------------------
# INTERNOS
# ------------------------------------------------------------------------------
## Vista previa de un bloque con los multiplicadores actuales (sin estados de choque, que dependen del azar determinista).
## {"gold": int, "stress": int, "seal_delta": int, "gains": [{"stat","label","value"}]}
func preview_block(act_id: String) -> Dictionary:
	var act: Dictionary = CatalogDB.get_activity(act_id)
	if act.is_empty():
		return {}
	var fac_key: String = str(act.get("facility_bonus", ""))
	var fac_bonus: int = (int(GameState.estate_levels.get(fac_key, 1)) - 1) * 4 if fac_key != "" else 0
	var gains: Array = []
	for sk in act["stats"].keys():
		var base_v: int = int(act["stats"][sk])
		var v: int = base_v
		if base_v > 0:
			var main_bonus: int = fac_bonus if base_v >= 15 else 0
			v = int(round(float(scaled_base(sk, base_v) + main_bonus) * _gain_multiplier(sk, act, is_supervised(), false, false)))
		gains.append({"stat": sk, "label": GameState.get_stat_label(sk), "value": v})
	return {"gold": _activity_gold(act), "stress": int(act["stress"]), "seal_delta": int(act.get("seal_delta", 0)), "gains": gains}

## Valor base de una ganancia de actividad tras el factor de balance (solo atributos 0-1200).
func scaled_base(stat_key: String, value: int) -> int:
	if value > 0 and GameState.BIG_STATS.has(stat_key):
		return maxi(1, int(round(float(value) * CatalogDB.BIG_STAT_GAIN_SCALE)))
	return value

func _father_gold(task: Dictionary) -> int:
	var g: int = int(task.get("gold", 0))
	if task.get("id", "") == "diplomacy":
		g = int(round(float(g) * (1.0 + TimeManager.get_income_bonus())))
	return g

func _activity_gold(act: Dictionary) -> int:
	var money: int = int(act["cost_or_wage"])
	if money > 0:
		var mult: float = 1.0
		if act.get("urban", false):
			mult += TimeManager.get_income_bonus()
		if act.get("recital", false) and GameState.unlocked_synergies.has("alabaster_rose"):
			mult += 0.30
		money = int(round(float(money) * mult))
	return money

func _gain_multiplier(stat_key: String, act: Dictionary, supervised: bool, inspired: bool, stung: bool) -> float:
	var m: float = 1.0
	if supervised:
		m += 0.30
		if GameState.has_trait_prefix("Orgullo del Hogar"):
			m += 0.20
	m += TimeManager.get_gain_bonus(stat_key)
	if GameState.unlocked_synergies.has("horizon_valkyrie") and CatalogDB.MARTIAL_IDS.has(act["id"]):
		m += 0.20
	if GameState.unlocked_synergies.has("ephemeris_weaver") and CatalogDB.ASTRAL_STUDY_IDS.has(act["id"]):
		m += 0.25
	if inspired:
		m += 0.20
	if stung:
		m += 0.35
	if GameState.stress >= STRESS_FATIGUE_THRESHOLD:
		m -= 0.25
	return maxf(m, 0.3)

func _apply_father_task(task_id: String) -> Dictionary:
	var t: Dictionary = CatalogDB.get_father_task(task_id)
	var parts: Array[String] = []
	if int(t.get("gold", 0)) > 0:
		var g: int = _father_gold(t)
		GameState.modify_gold(g)
		parts.append("+%d Oro" % g)
	for k in t["effects"].keys():
		var delta: int = int(t["effects"][k])
		if task_id == "investigate" and k == "seal_investigation" and GameState.unlocked_synergies.has("solar_artificer"):
			delta = int(round(float(delta) * 1.15))
		if delta > 0:
			delta = int(round(float(delta) * (1.0 + TimeManager.get_gain_bonus(k))))
		var applied: int = GameState.modify_stat(k, delta)
		if applied != 0:
			parts.append("%s %+d" % [GameState.get_stat_label(k), applied])
	if task_id == "hero_work":
		TimeManager.father_times_worked_away_this_year += 1
	elif task_id == "supervise" or task_id == "cook_home":
		TimeManager.father_times_stayed_home_this_year += 1
	if task_id == "investigate":
		var clue_txt: String = "Encontraste actas censuradas del Observatorio que mencionan un enigma celeste oculto desde la noche de los siete cometas."
		if GameState.seal_investigation_progress >= 85:
			clue_txt = "Descifraste el acta secreta del templo: la estrella era el Sarcófago Celestial de Nyx-Aethel."
		elif GameState.seal_investigation_progress >= 45:
			clue_txt = "Los cálculos antiguos revelan que algo consciente —llamado Nyx-Aethel— yacía dormido dentro del astro."
		elif GameState.seal_investigation_progress >= 30:
			clue_txt = "Encontraste crónicas censuradas que sugieren que la estrella caída portaba un Sello antiguo."
		Chronicle.record_event("father_investigate", "Cámara de los Relojes Rotos", clue_txt, "twist", 3)
	return {"task_id": task_id, "name": t["name"], "icon": t["icon"], "text": ", ".join(parts)}

func _facility_name(key: String) -> String:
	match key:
		"library": return "Bóveda Estelar"
		"armory": return "Patio de Lanzas"
		"conservatory": return "Salón de Lotos"
		"crucible": return "Cámara del Crisol"
	return key

## Micro-eventos deterministas (misma partida + turno + bloque => mismo resultado)
func _roll_micro_event(act: Dictionary, block_idx: int) -> Dictionary:
	var rng := GameState.det_rng("micro", block_idx)
	if rng.randi_range(1, 100) > MICRO_EVENT_CHANCE:
		return {}
	var eligible: Array[Dictionary] = []
	var total_w: int = 0
	for ev in CatalogDB.MICRO_EVENTS:
		if _micro_event_matches(ev["requires"], act):
			eligible.append(ev)
			total_w += int(ev["weight"])
	if eligible.is_empty():
		return {}
	var roll: int = rng.randi_range(1, total_w)
	var chosen: Dictionary = eligible[0]
	for ev in eligible:
		roll -= int(ev["weight"])
		if roll <= 0:
			chosen = ev
			break

	var trait_hit: bool = chosen.has("trait_prefix") and GameState.has_trait_prefix(str(chosen["trait_prefix"]))
	var effects: Dictionary = (chosen["effects"] as Dictionary).duplicate()
	var text: String = str(chosen["text"])
	if trait_hit:
		text = str(chosen.get("text_trait", text))
		var extra: Dictionary = chosen.get("effects_trait", {})
		for k in extra.keys():
			effects[k] = int(effects.get(k, 0)) + int(extra[k])
	var labels: Array[String] = []
	for k in effects.keys():
		var applied: int = GameState.modify_stat(k, int(effects[k]))
		if applied != 0:
			labels.append("%s %+d%s" % [GameState.get_stat_label(k), applied, " G" if k == "gold" else ""])
	return {"id": chosen["id"], "title": chosen["title"], "text": text.replace("{D}", GameState.daughter_name),
		"effects": ", ".join(labels), "trait": trait_hit}

func _micro_event_matches(req: Dictionary, act: Dictionary) -> bool:
	if req.has("ids") and not (req["ids"] as Array).has(act["id"]):
		return false
	if req.has("category") and req["category"] != "any" and req["category"] != act["category"]:
		return false
	if req.has("min_age") and GameState.age < int(req["min_age"]):
		return false
	if req.has("seal_below") and GameState.seal_integrity >= int(req["seal_below"]):
		return false
	if req.has("stress_above") and GameState.stress <= int(req["stress_above"]):
		return false
	return true

const _SNAPSHOT_KEYS: Array[String] = [
	"gold", "stress", "affection", "human_anchor", "seal_integrity", "abyssal_sync", "astral_saturation",
	"temple", "destreza", "erudicion", "gracia", "magnetismo", "luminiscencia", "gravedad", "resonancia", "entropia",
	"moralidad", "devocion", "seal_investigation", "father_reputation"
]

func _snapshot() -> Dictionary:
	var s: Dictionary = {}
	for k in _SNAPSHOT_KEYS:
		s[k] = GameState.get_stat(k)
	return s

func _diff_snapshot(a: Dictionary, b: Dictionary) -> Array:
	var out: Array = []
	for k in _SNAPSHOT_KEYS:
		var d: int = int(b[k]) - int(a[k])
		if d != 0:
			out.append({"stat": k, "label": GameState.get_stat_label(k), "delta": d, "after": int(b[k])})
	return out

# ------------------------------------------------------------------------------
# GUARDADO
# ------------------------------------------------------------------------------
func serialize() -> Dictionary:
	return {"agenda": agenda.duplicate(), "father_plan": father_plan.duplicate()}

func deserialize(d: Dictionary) -> void:
	agenda = ["class_armory", "class_astrolabe", "rest_manor"]
	var saved: Array = d.get("agenda", [])
	for i in range(mini(saved.size(), BLOCKS_PER_BIMESTER)):
		if not CatalogDB.get_activity(str(saved[i])).is_empty():
			agenda[i] = str(saved[i])
	father_plan.clear()
	for t in d.get("father_plan", []):
		if not CatalogDB.get_father_task(str(t)).is_empty():
			father_plan.append(str(t))
	plan_changed.emit()
