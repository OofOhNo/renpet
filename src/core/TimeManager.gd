extends Node

## Singleton TimeManager - Reloj bimensual de Aethelgard (48 Turnos / 8 Años: Edades 12 a 20).
## Fase 1: calendario, Eras/Actos, disparadores de Festival y Solsticio, y mantenimiento bimensual.

signal turn_started(year: int, bimester: int, total_turn: int)
signal year_completed(completed_year: int)
signal era_changed(new_era: Era)
signal campaign_finished()

enum Era {
	AWAKENING,    # Acto I   (Edades 12 a 14 | Turnos 1 a 18):  El Lucero en la Cuna Mortal
	FORGE,        # Acto II  (Edades 15 a 17 | Turnos 19 a 36): Las Grietas del Firmamento
	CONSECRATION  # Acto III (Edades 18 a 20 | Turnos 37 a 48): El Juicio de la Eternidad
}

const TOTAL_TURNS: int = 48
const BIMESTERS_PER_YEAR: int = 6
const FESTIVAL_BIMESTER: int = 4
const SOLSTICE_BIMESTER: int = 6

## "mods": multiplicadores reales que aplica TurnExecutor (ver get_gain_multiplier / get_income_multiplier)
const BIMESTER_DATA: Array[Dictionary] = [
	{
		"name": "1º Bimestre de la Semilla", "season": "Primavera Temprana (Mar-Abr)",
		"phenomenon": "Lluvias de Plata: deshielo de calzadas y llegada de caravanas nómadas.",
		"bonus_desc": "+10% de eficacia en estudios de Erudición.",
		"gain_mods": {"erudicion": 0.10}, "income_mod": 0.0
	},
	{
		"name": "2º Bimestre del Florecimiento", "season": "Primavera Tardía (May-Jun)",
		"phenomenon": "Rito de la Palma Joven: brisa templada de polen lumínico.",
		"bonus_desc": "+15% de ganancia de Afecto y Anclaje Humano.",
		"gain_mods": {"affection": 0.15, "human_anchor": 0.15}, "income_mod": 0.0
	},
	{
		"name": "3º Bimestre de la Marea Alta", "season": "Pleno Verano (Jul-Ago)",
		"phenomenon": "Marea Astral: los ríos de Aethelgard brillan con aether líquido.",
		"bonus_desc": "+25% al crecimiento de atributos cósmicos (Luz, Gravedad, Resonancia).",
		"gain_mods": {"luminiscencia": 0.25, "gravedad": 0.25, "resonancia": 0.25}, "income_mod": 0.0
	},
	{
		"name": "4º Bimestre de la Cosecha", "season": "Equinoccio de Otoño (Sep-Oct)",
		"phenomenon": "Gran Festival de las Constelaciones en la capital.",
		"bonus_desc": "Celebración de los 4 Grandes Certámenes Anuales.",
		"gain_mods": {}, "income_mod": 0.0
	},
	{
		"name": "5º Bimestre de la Escarcha", "season": "Invierno Temprano (Nov-Dic)",
		"phenomenon": "Nieve de Cuarzo: noches largas y auge de intrigas en los salones.",
		"bonus_desc": "+20% de ingresos en empleos urbanos y diplomacia paterna.",
		"gain_mods": {}, "income_mod": 0.20
	},
	{
		"name": "6º Bimestre del Solsticio", "season": "Invierno Profundo (Ene-Feb)",
		"phenomenon": "Noche de la Estrella Caída: eclipse invernal y cumpleaños de Renpet.",
		"bonus_desc": "Balance anual y entrega de la Carta Manuscrita de Renpet.",
		"gain_mods": {}, "income_mod": 0.0
	}
]

var current_total_turn: int = 1   # 1 a 48
var current_year: int = 12        # Edad actual de Renpet (12 a 20)
var current_bimester: int = 1     # 1 a 6
var current_era: Era = Era.AWAKENING
var campaign_over: bool = false
var father_times_stayed_home_this_year: int = 0
var father_times_worked_away_this_year: int = 0

func _ready() -> void:
	update_era()

func reset_new_game() -> void:
	current_total_turn = 1
	current_year = 12
	current_bimester = 1
	campaign_over = false
	father_times_stayed_home_this_year = 0
	father_times_worked_away_this_year = 0
	current_era = Era.AWAKENING
	update_era()

# ------------------------------------------------------------------------------
# CONSULTAS
# ------------------------------------------------------------------------------
func get_bimester_info() -> Dictionary:
	return BIMESTER_DATA[clampi(current_bimester - 1, 0, 5)]

func get_era_title() -> String:
	match current_era:
		Era.AWAKENING: return "ACTO I: El Lucero en la Cuna (12-14 años)"
		Era.FORGE: return "ACTO II: Las Grietas del Cielo (15-17 años)"
		Era.CONSECRATION: return "ACTO III: El Juicio de la Eternidad (18-20 años)"
	return "Acto I"

## 1, 2 o 3 según el Acto en curso
func get_act_number() -> int:
	return int(current_era) + 1

func is_festival_bimester() -> bool:
	return current_bimester == FESTIVAL_BIMESTER

func is_solstice_bimester() -> bool:
	return current_bimester == SOLSTICE_BIMESTER

## Zahir el Nómada solo aparece en los bimestres pares (Biblia §4.3)
func is_bazaar_open() -> bool:
	return current_bimester % 2 == 0

func get_turns_remaining() -> int:
	return TOTAL_TURNS - current_total_turn

## Multiplicador aditivo (>= 0) que el bimestre aplica a las ganancias de un atributo.
func get_gain_bonus(stat_key: String) -> float:
	var mods: Dictionary = get_bimester_info().get("gain_mods", {})
	return float(mods.get(stat_key, 0.0))

## Bono de ingresos del bimestre para empleos urbanos y diplomacia.
func get_income_bonus() -> float:
	return float(get_bimester_info().get("income_mod", 0.0))

# ------------------------------------------------------------------------------
# AVANCE DEL CALENDARIO
# ------------------------------------------------------------------------------
## Cierra el bimestre actual: mantenimiento, avance de turno y eventos de fin de año.
## Devuelve {"upkeep": Array[String], "year_completed": int (0 si no hubo), "finished": bool}
func advance_bimester() -> Dictionary:
	var result: Dictionary = {"upkeep": [] as Array[String], "year_completed": 0, "finished": false}
	if campaign_over:
		return result

	result["upkeep"] = apply_bimester_upkeep()
	GameState.father_energy = GameState.father_max_energy

	var finished_year: int = current_year
	var is_last_turn: bool = current_total_turn >= TOTAL_TURNS
	var closes_year: bool = current_bimester >= BIMESTERS_PER_YEAR

	if is_last_turn:
		# Turno 48: se entrega la última carta (los 20 años) y termina la campaña.
		current_year = finished_year + 1
		GameState.age = current_year
		campaign_over = true
		result["year_completed"] = finished_year
		result["finished"] = true
		update_era()
		year_completed.emit(finished_year)
		campaign_finished.emit()
		return result

	current_bimester += 1
	current_total_turn += 1
	if closes_year:
		current_bimester = 1
		current_year += 1
		GameState.age = current_year
		result["year_completed"] = finished_year
		year_completed.emit(finished_year)
		father_times_stayed_home_this_year = 0
		father_times_worked_away_this_year = 0

	update_era()
	turn_started.emit(current_year, current_bimester, current_total_turn)
	return result

## Mantenimiento de fin de bimestre. Devuelve líneas legibles para el informe.
func apply_bimester_upkeep() -> Array[String]:
	var lines: Array[String] = []
	GameState.begin_batch()

	# Salón de Música y Té: alivio pasivo de estrés
	var conservatory_bonus: int = int(GameState.estate_levels.get("conservatory", 1)) * 3
	var relieved: int = -GameState.modify_stat("stress", -conservatory_bonus)
	if relieved > 0:
		lines.append("El Salón de Lotos y Música alivió %d de Estrés." % relieved)

	# Régimen de dieta (si no alcanza el oro, la casa cae a Dieta Austera)
	var diet: Dictionary = CatalogDB.get_diet(int(GameState.current_diet))
	var paid: bool = GameState.modify_gold(-int(diet["cost"]))
	if not paid and int(diet["id"]) != int(GameState.DietPlan.AUSTERE):
		lines.append("No alcanzó el oro para «%s»: la casa pasa a Dieta Austera." % diet["name"])
		GameState.current_diet = GameState.DietPlan.AUSTERE
		Chronicle.record_event("diet_downgrade", "La despensa se vació",
			"Sin oro para el régimen elegido, la familia tuvo que apretarse el cinturón.", "family", 3)
		diet = CatalogDB.get_diet(int(GameState.DietPlan.AUSTERE))
		paid = GameState.modify_gold(-int(diet["cost"]))
	if paid:
		for k in diet["effects"].keys():
			GameState.modify_stat(k, int(diet["effects"][k]))
		if diet.has("saturation"):
			GameState.modify_stat("astral_saturation", int(diet["saturation"]))
		lines.append("Régimen «%s» (-%d G): %s" % [diet["name"], int(diet["cost"]), diet["desc"]])
	else:
		GameState.modify_stat("stress", 8)
		GameState.modify_stat("temple", -3)
		lines.append("La familia pasó hambre este bimestre (+8 Estrés, -3 Temple).")

	# Sinergia pasiva: Faro de Humanidad Inquebrantable
	if GameState.unlocked_synergies.has("mortal_beacon"):
		var gained: int = GameState.modify_stat("seal_integrity", 2)
		if gained > 0:
			lines.append("Faro de Humanidad Inquebrantable: %s se regeneró +%d%%." % [GameState.get_stat_label("seal_integrity"), gained])

	# Metabolismo astral y efectos de la saturación
	for l in CrucibleManager.apply_bimester_decay():
		lines.append(l)

	GameState.end_batch()
	return lines

func update_era() -> void:
	var prev_era: Era = current_era
	if current_year <= 14:
		current_era = Era.AWAKENING
	elif current_year <= 17:
		current_era = Era.FORGE
	else:
		current_era = Era.CONSECRATION
	if prev_era != current_era:
		era_changed.emit(current_era)

# ------------------------------------------------------------------------------
# GUARDADO
# ------------------------------------------------------------------------------
func serialize() -> Dictionary:
	return {
		"current_total_turn": current_total_turn, "current_year": current_year,
		"current_bimester": current_bimester, "campaign_over": campaign_over,
		"father_times_stayed_home_this_year": father_times_stayed_home_this_year,
		"father_times_worked_away_this_year": father_times_worked_away_this_year
	}

@warning_ignore("integer_division")
func deserialize(d: Dictionary) -> void:
	current_total_turn = clampi(int(d.get("current_total_turn", 1)), 1, TOTAL_TURNS)
	# La edad y el bimestre se derivan del turno: así un guardado nunca queda incoherente.
	current_year = 12 + (current_total_turn - 1) / BIMESTERS_PER_YEAR
	current_bimester = ((current_total_turn - 1) % BIMESTERS_PER_YEAR) + 1
	campaign_over = bool(d.get("campaign_over", false))
	if campaign_over:
		current_year = 20
	father_times_stayed_home_this_year = int(d.get("father_times_stayed_home_this_year", 0))
	father_times_worked_away_this_year = int(d.get("father_times_worked_away_this_year", 0))
	GameState.age = current_year
	update_era()
