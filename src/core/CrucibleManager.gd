extends Node

## CrucibleManager - Horno de Fusión Astral (Fase 5).
## Renpet funde materiales cósmicos: ganan atributos y mutaciones permanentes, pero cada fusión
## varía la Integridad del Sello y acumula Saturación Astral (toxicidad temporal 0-100).
##  - Saturación >= 60: el cuerpo absorbe peor (70% de los atributos). >= 85: 40% y daño extra al Sello.
##  - Pasarse de 100 provoca una Sobrecarga Astral (requiere confirmación).
##  - Mejorar el Crisol de la mansión reduce la saturación generada y acelera su disipación.
##  - El bazar de Zahir el Nómada solo abre en bimestres pares; algunos objetos exigen reputación paterna.

signal crucible_changed()

const SATURATION_SOFT_LIMIT: int = 60
const SATURATION_HARD_LIMIT: int = 85
const NATURAL_DECAY: int = 8
const DISTILL_COST: int = 120
const DISTILL_COST_ARTIFICER: int = 90
const PURIFY_COST: int = 80

var distilled_this_bimester: bool = false

func reset_new_game() -> void:
	distilled_this_bimester = false

func reset_bimester_flags() -> void:
	distilled_this_bimester = false

# ------------------------------------------------------------------------------
# CÁLCULOS
# ------------------------------------------------------------------------------
func get_crucible_level() -> int:
	return int(GameState.estate_levels.get("crucible", 1))

func get_efficiency() -> float:
	var sat: int = GameState.astral_saturation
	if sat >= SATURATION_HARD_LIMIT:
		return 0.4
	if sat >= SATURATION_SOFT_LIMIT:
		return 0.7
	return 1.0

func get_saturation_gain(mat: Dictionary) -> int:
	var base: int = int(mat.get("saturation", 0))
	if base <= 0:
		return 0
	return maxi(4, base - 2 * (get_crucible_level() - 1))

func get_purify_cost() -> int:
	return maxi(40, PURIFY_COST - 8 * (get_crucible_level() - 1))

func get_distill_cost() -> int:
	return DISTILL_COST_ARTIFICER if GameState.unlocked_synergies.has("solar_artificer") else DISTILL_COST

func get_material_price(mat: Dictionary) -> int:
	# La reputación paterna da hasta un 15% de descuento en el bazar.
	var discount: float = clampf(float(GameState.father_reputation) * 0.0015, 0.0, 0.15)
	return int(round(float(mat["price"]) * (1.0 - discount)))

## Vista previa antes de asimilar (efectos reales sobre atributos, Sello y Saturación)
func preview(material_id: String) -> Dictionary:
	var mat: Dictionary = CatalogDB.get_material(material_id)
	if mat.is_empty():
		return {"ok": false}
	var eff: float = get_efficiency()
	var synergy_mult: float = 1.30 if GameState.unlocked_synergies.has("eclipse_sovereign") else 1.0
	var stat_deltas: Dictionary = {}
	for sk in mat["stats"].keys():
		stat_deltas[sk] = int(round(float(mat["stats"][sk]) * eff * synergy_mult))

	var seal_delta: int = int(mat.get("seal_delta", 0))
	if seal_delta < 0 and GameState.has_mutation("bendicion_del_tiempo"):
		seal_delta = int(ceil(float(seal_delta) * 0.5))
	var warnings: Array[String] = []
	if GameState.astral_saturation >= SATURATION_HARD_LIMIT:
		seal_delta -= 4
		warnings.append("Saturación crítica: absorbes solo el 40% y el Sello sufre -4% extra.")
	elif GameState.astral_saturation >= SATURATION_SOFT_LIMIT:
		warnings.append("Saturación alta: absorbes solo el 70% de los atributos.")

	var sat_gain: int = get_saturation_gain(mat)
	var sat_after: int = GameState.astral_saturation + sat_gain
	var overload: bool = sat_after > 100
	if overload:
		warnings.append("¡Sobrecarga Astral! -15% Sello, +20 Estrés, +10 Sincronía, +8 Entropía.")
	var mut_id: String = str(mat.get("mutation", ""))
	return {
		"ok": true, "material": mat, "stat_deltas": stat_deltas, "seal_delta": seal_delta,
		"seal_after": clampi(GameState.seal_integrity + seal_delta, 0, 100),
		"sat_gain": sat_gain, "sat_after": mini(sat_after, 100), "overload": overload,
		"efficiency": eff, "mutation_id": mut_id, "mutation_name": CatalogDB.get_mutation_name(mut_id),
		"new_mutation": mut_id != "" and not GameState.has_mutation(mut_id),
		"warnings": warnings, "count": int(GameState.materials_inventory.get(material_id, 0))
	}

# ------------------------------------------------------------------------------
# ACCIONES
# ------------------------------------------------------------------------------
func assimilate(material_id: String, confirm_overload: bool = false) -> Dictionary:
	var p: Dictionary = preview(material_id)
	if not p.get("ok", false):
		return {"ok": false, "msg": "Material desconocido."}
	if int(p["count"]) <= 0:
		return {"ok": false, "msg": "No tienes ese material en el inventario."}
	if bool(p["overload"]) and not confirm_overload:
		return {"ok": false, "needs_confirm": true, "msg": "Asimilar esto sobrecargaría el cuerpo de %s. ¿Continuar?" % GameState.daughter_name}

	var mat: Dictionary = p["material"]
	GameState.materials_inventory[material_id] = int(p["count"]) - 1
	GameState.begin_batch()
	var gains: Array[String] = []
	for sk in p["stat_deltas"].keys():
		var applied: int = GameState.modify_stat(sk, int(p["stat_deltas"][sk]))
		if applied != 0:
			gains.append("%s %+d" % [GameState.get_stat_label(sk), applied])
	var seal_applied: int = GameState.modify_stat("seal_integrity", int(p["seal_delta"]))
	if seal_applied != 0:
		gains.append("Sello %+d%%" % seal_applied)

	var overload_happened: bool = bool(p["overload"])
	if overload_happened:
		GameState.modify_stat("seal_integrity", -15)
		GameState.modify_stat("stress", 20)
		GameState.modify_stat("abyssal_sync", 10)
		GameState.modify_stat("entropia", 8)
		GameState.astral_saturation = 60
		Chronicle.record_event("crucible_overload", "Sobrecarga Astral",
			"%s fundió demasiado en poco tiempo y su cuerpo estelar se resquebrajó un instante." % GameState.daughter_name, "cosmic", 5)
	else:
		GameState.modify_stat("astral_saturation", int(p["sat_gain"]))

	var mut_id: String = str(p["mutation_id"])
	var new_mut: bool = mut_id != "" and GameState.add_mutation(mut_id)
	GameState.end_batch()

	Chronicle.record_event("crucible_" + material_id, "Asimilación en el Crisol: " + str(mat["name"]),
		("%s despertó la mutación %s." % [GameState.daughter_name, p["mutation_name"]]) if new_mut else "%s reforzó su cuerpo estelar con %s." % [GameState.daughter_name, mat["name"]],
		"cosmic", 4)
	crucible_changed.emit()
	return {"ok": true, "overload": overload_happened, "new_mutation": new_mut, "mutation_name": p["mutation_name"],
		"gains": gains, "name": mat["name"], "saturation": GameState.astral_saturation}

func buy_material(material_id: String) -> Dictionary:
	var mat: Dictionary = CatalogDB.get_material(material_id)
	if mat.is_empty():
		return {"ok": false, "msg": "Material desconocido."}
	if not TimeManager.is_bazaar_open():
		return {"ok": false, "msg": "Zahir el Nómada solo acampa en el Bazar de Medianoche en los bimestres pares. Mientras tanto puedes destilar reliquias."}
	var need_rep: int = int(mat.get("exclusive_rep", 0))
	if GameState.father_reputation < need_rep:
		return {"ok": false, "msg": "Zahir solo vende «%s» a quienes tienen %d de Reputación Paterna (tienes %d). La Diplomacia del Padre la aumenta." % [mat["name"], need_rep, GameState.father_reputation]}
	var price: int = get_material_price(mat)
	if not GameState.modify_gold(-price):
		return {"ok": false, "msg": "Necesitas %d G para comprar %s." % [price, mat["name"]]}
	GameState.materials_inventory[material_id] = int(GameState.materials_inventory.get(material_id, 0)) + 1
	crucible_changed.emit()
	return {"ok": true, "msg": "Compraste %s por %d G." % [mat["name"], price]}

func distill_relic() -> Dictionary:
	if distilled_this_bimester:
		return {"ok": false, "msg": "El Crisol ya destiló una reliquia este bimestre."}
	var cost: int = get_distill_cost()
	if GameState.gold < cost:
		return {"ok": false, "msg": "Necesitas %d G para destilar una reliquia en el Horno Astral." % cost}
	# Selección ponderada determinista (excluye reliquias exclusivas del Padre)
	var pool: Array[Dictionary] = []
	var total_w: int = 0
	for m in CatalogDB.COSMIC_MATERIALS:
		if int(m.get("exclusive_rep", 0)) == 0:
			pool.append(m)
			total_w += int(m["weight"])
	var rng := GameState.det_rng("distill", GameState.materials_inventory.size())
	var roll: int = rng.randi_range(1, total_w)
	var picked: Dictionary = pool[0]
	for m in pool:
		roll -= int(m["weight"])
		if roll <= 0:
			picked = m
			break
	GameState.modify_gold(-cost)
	distilled_this_bimester = true
	var id_s: String = str(picked["id"])
	GameState.materials_inventory[id_s] = int(GameState.materials_inventory.get(id_s, 0)) + 1
	GameState.modify_stat("resonancia", 8)
	crucible_changed.emit()
	return {"ok": true, "name": picked["name"], "msg": "Condensaste la luz de la esfera armilar y obtuviste %s (+8 Resonancia)." % picked["name"]}

func purify_saturation() -> Dictionary:
	var cost: int = get_purify_cost()
	if GameState.astral_saturation <= 0:
		return {"ok": false, "msg": "El cuerpo de %s no tiene saturación que purificar." % GameState.daughter_name}
	if not GameState.modify_gold(-cost):
		return {"ok": false, "msg": "Necesitas %d G en sales de loto para purificar la Saturación Astral." % cost}
	GameState.begin_batch()
	GameState.modify_stat("astral_saturation", -25)
	GameState.modify_stat("seal_integrity", 3)
	GameState.modify_stat("stress", -10)
	GameState.end_batch()
	crucible_changed.emit()
	return {"ok": true, "msg": "El baño de vapor de alabastro redujo -25%% la Saturación Astral, restauró +3%% del Sello y alivió -10 de Estrés (-%d G)." % cost}

# ------------------------------------------------------------------------------
# METABOLISMO ASTRAL (se llama desde el mantenimiento de fin de bimestre)
# ------------------------------------------------------------------------------
func apply_bimester_decay() -> Array[String]:
	var lines: Array[String] = []
	if GameState.astral_saturation > 0:
		var decay: int = NATURAL_DECAY + 2 * (get_crucible_level() - 1)
		var removed: int = -GameState.modify_stat("astral_saturation", -decay)
		if removed > 0:
			lines.append("El metabolismo estelar disipó %d%% de Saturación Astral." % removed)
	if GameState.astral_saturation >= 70:
		GameState.modify_stat("stress", 4)
		lines.append("La Saturación Astral sigue alta: +4 Estrés. Conviene purificar.")
	reset_bimester_flags()
	return lines

# ------------------------------------------------------------------------------
# GUARDADO
# ------------------------------------------------------------------------------
func serialize() -> Dictionary:
	return {"distilled_this_bimester": distilled_this_bimester}

func deserialize(d: Dictionary) -> void:
	distilled_this_bimester = bool(d.get("distilled_this_bimester", false))
