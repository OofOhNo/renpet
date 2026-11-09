extends Node

## Singleton TimeManager - Reloj bimensual de Aethelgard (48 Turnos / 8 Años: Edades 12 a 20).

signal turn_started(year: int, bimester: int, total_turn: int)
signal year_completed(completed_year: int)
signal era_changed(new_era: Era)
signal campaign_finished()

enum Era {
	AWAKENING,    # Era I (Años 12 a 14 | Turnos 1 a 18): El Lucero en la Cuna Mortal
	FORGE,        # Era II (Años 15 a 17 | Turnos 19 a 36): Las Grietas del Firmamento
	CONSECRATION  # Era III (Años 18 a 20 | Turnos 37 a 48): El Juicio de la Eternidad
}

const TOTAL_TURNS: int = 48
const BIMESTERS_PER_YEAR: int = 6

const BIMESTER_DATA: Array[Dictionary] = [
	{
		"name": "1º Bimestre de la Semilla",
		"season": "Primavera Temprana (Mar-Abr)",
		"phenomenon": "Lluvias de Plata: Deshielo de calzadas y llegada de caravanas.",
		"bonus_desc": "+10% eficacia en estudios de Erudición."
	},
	{
		"name": "2º Bimestre del Florecimiento",
		"season": "Primavera Tardía (May-Jun)",
		"phenomenon": "Rito de la Palma Joven: Brisa templada de polen lumínico.",
		"bonus_desc": "+15% ganancia de Afecto y Anclaje Humano."
	},
	{
		"name": "3º Bimestre de la Marea Alta",
		"season": "Pleno Verano (Jul-Ago)",
		"phenomenon": "Marea Astral: Los ríos de Aethelgard brillan con aether líquido.",
		"bonus_desc": "+25% al crecimiento de atributos cósmicos (Luz, Gravedad, Resonancia)."
	},
	{
		"name": "4º Bimestre de la Cosecha",
		"season": "Equinoccio de Otoño (Sep-Oct)",
		"phenomenon": "Gran Festival de las Constelaciones en la capital.",
		"bonus_desc": "Celebración de los 4 Grandes Certámenes Anuales."
	},
	{
		"name": "5º Bimestre de la Escarcha",
		"season": "Invierno Temprano (Nov-Dic)",
		"phenomenon": "Nieve de Cuarzo: Noches largas y auge de salones políticos.",
		"bonus_desc": "+20% ingresos en empleos urbanos y diplomacia paterna."
	},
	{
		"name": "6º Bimestre del Solsticio",
		"season": "Invierno Profundo (Ene-Feb)",
		"phenomenon": "Noche de la Estrella Caída: Eclipse invernal y cumpleaños de Renpet.",
		"bonus_desc": "Balance anual y entrega de la Carta Manuscrita de Renpet."
	}
]

var current_total_turn: int = 1   # 1 a 48
var current_year: int = 12        # Edad actual de Renpet (12 a 20)
var current_bimester: int = 1     # 1 a 6
var current_era: Era = Era.AWAKENING
var father_times_stayed_home_this_year: int = 0
var father_times_worked_away_this_year: int = 0

func _ready() -> void:
	update_era()

func get_bimester_info() -> Dictionary:
	return BIMESTER_DATA[clampi(current_bimester - 1, 0, 5)]

func get_era_title() -> String:
	match current_era:
		Era.AWAKENING: return "ACTO I: El Lucero en la Cuna (12-14 años)"
		Era.FORGE: return "ACTO II: Las Grietas del Cielo (15-17 años)"
		Era.CONSECRATION: return "ACTO III: El Juicio de la Eternidad (18-20 años)"
	return "Acto I"

func is_festival_bimester() -> bool:
	return current_bimester == 4

func is_solstice_bimester() -> bool:
	return current_bimester == 6

func advance_bimester() -> void:
	if current_total_turn >= TOTAL_TURNS:
		campaign_finished.emit()
		return
		
	# Aplicar efectos de dieta bimensual y pasivas de la mansión
	_apply_bimester_upkeep()
	
	var finished_year: int = current_year
	current_bimester += 1
	current_total_turn += 1
	
	# Restaurar energía del padre para el nuevo bimestre
	GameState.father_energy = GameState.father_max_energy
	
	if current_bimester > BIMESTERS_PER_YEAR:
		current_bimester = 1
		current_year += 1
		GameState.age = current_year
		year_completed.emit(finished_year)
		father_times_stayed_home_this_year = 0
		father_times_worked_away_this_year = 0
		
	update_era()
	turn_started.emit(current_year, current_bimester, current_total_turn)

func _apply_bimester_upkeep() -> void:
	# Reducción pasiva de estrés por el Salón de Música y Té
	var conservatory_bonus: int = GameState.estate_levels.get("conservatory", 1) * 3
	GameState.modify_stat("stress", -conservatory_bonus)
	
	# Coste y efecto del régimen de dieta familiar
	match GameState.current_diet:
		GameState.DietPlan.AUSTERE:
			GameState.modify_gold(-30)
			GameState.modify_stat("stress", 4)
		GameState.DietPlan.BALANCED:
			if GameState.modify_gold(-80):
				GameState.modify_stat("stress", -5)
				GameState.modify_stat("human_anchor", 2)
			else:
				GameState.modify_stat("stress", 5)
		GameState.DietPlan.ROYAL_FEAST:
			if GameState.modify_gold(-180):
				GameState.modify_stat("stress", -14)
				GameState.modify_stat("gracia", 8)
				GameState.modify_stat("temple", 5)
			else:
				GameState.current_diet = GameState.DietPlan.AUSTERE
		GameState.DietPlan.ASTRAL_PURGE:
			if GameState.modify_gold(-150):
				GameState.astral_saturation = maxi(0, GameState.astral_saturation - 15)
				GameState.modify_stat("seal_integrity", 2)
			else:
				GameState.current_diet = GameState.DietPlan.BALANCED

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
