extends Node

## Singleton GameState - Estado maestro de Renpet, el Padre (Héroe), el Sello Estelar y el Horno Astral.
## Fase 1: matemáticas de atributos, 3 medidores nucleares, perfil del Padre y rasgos psicológicos.

signal stats_updated()
signal seal_state_changed(seal_integrity: int, human_anchor: int, abyssal_sync: int)
signal traits_updated(active_traits: Array[String])
signal gold_changed(new_gold: int)

enum HeroArchetype {
	MARTIAL,  # El Filo del Vértice (+Temple/Destreza inicial, mandoble ancestral)
	SCHOLAR,  # El Archimago del Velo (+Erudición/Resonancia, biblioteca familiar)
	ROGUE,    # El Infiltrador del Silencio (+Oro inicial, contactos en canales, evasión)
	DEVOUT    # El Custodio del Altar Caído (+Anclaje Humano, serenidad, resistencia al estrés)
}

# Los valores coinciden con los ids de CatalogDB.DIETS
enum DietPlan {
	AUSTERE,      # Dieta Austera
	BALANCED,     # Mesa Casera del Héroe
	ROYAL_FEAST,  # Banquete de Corte
	ASTRAL_PURGE  # Infusión de Lirio Estelar
}

const MAX_BIG_STAT: int = 1200   # Atributos mortales y cósmicos
const ROMANCE_MIN_AGE: int = 18  # Edad mínima (de Renpet) para cualquier ruta o acción romántica
const MAX_ACTIVE_TRAITS: int = 4

## Atributos 0-1200 (esfera mortal y cósmica)
const BIG_STATS: Array[String] = [
	"temple", "destreza", "erudicion", "gracia", "magnetismo", "luminiscencia", "gravedad", "resonancia"
]
## Todo lo que modify_stat() sabe tocar, con su rango
const STAT_RANGES: Dictionary = {
	"temple": [0, 1200], "destreza": [0, 1200], "erudicion": [0, 1200], "gracia": [0, 1200],
	"magnetismo": [0, 1200], "luminiscencia": [0, 1200], "gravedad": [0, 1200], "resonancia": [0, 1200],
	"entropia": [0, 100], "moralidad": [0, 100], "devocion": [0, 100],
	"stress": [0, 100], "affection": [0, 100],
	"human_anchor": [0, 100], "seal_integrity": [0, 100], "abyssal_sync": [0, 100],
	"seal_investigation": [0, 100], "astral_saturation": [0, 100], "father_reputation": [0, 100]
}
const STAT_LABELS: Dictionary = {
	"temple": "Temple", "destreza": "Destreza", "erudicion": "Erudición", "gracia": "Gracia",
	"magnetismo": "Magnetismo", "luminiscencia": "Luminiscencia", "gravedad": "Gravedad",
	"resonancia": "Resonancia", "entropia": "Entropía", "moralidad": "Moralidad", "devocion": "Devoción",
	"stress": "Estrés", "affection": "Afecto", "human_anchor": "Anclaje Humano",
	"seal_integrity": "Sello", "abyssal_sync": "Sincronía con Zephyr",
	"seal_investigation": "Investigación del Sello", "astral_saturation": "Saturación Astral",
	"father_reputation": "Reputación Paterna", "gold": "Oro"
}

# --- IDENTIDAD Y PERFIL ---
var daughter_name: String = "Renpet"
var age: int = 12
var father_name: String = "Aurelius"
var father_archetype: HeroArchetype = HeroArchetype.MARTIAL
var prologue_completed: bool = false
var run_seed: int = 0   # Semilla de la partida: hace reproducibles los micro-eventos

# --- ESFERA MORTAL / HUMANA (0 a 1200) ---
var temple: int = 130
var destreza: int = 120
var erudicion: int = 135
var gracia: int = 105
var magnetismo: int = 100

# --- ESFERA CÓSMICA / ESTELAR (0 a 1200) ---
var luminiscencia: int = 110
var gravedad: int = 90
var resonancia: int = 100
var entropia: int = 5         # 0 a 100

# --- EJE MORAL Y ESPIRITUAL (0 a 100) ---
var moralidad: int = 60
var devocion: int = 50

# --- LOS 3 MEDIDORES NUCLEARES DEL TWIST ---
var human_anchor: int = 70    # Arraigo mortal, amor y empatía
var seal_integrity: int = 92  # Cadenas que contienen a Nyx-Aethel
var abyssal_sync: int = 10    # Comprensión de Zephyr / Nyx-Aethel

# --- ESTADO VITAL Y RECURSOS FAMILIARES ---
var stress: int = 15
var max_stamina: int = 330    # Reservada como HP base para la Fase 7 (combate)
var current_stamina: int = 330
var affection: int = 75
var gold: int = 850
var current_diet: DietPlan = DietPlan.BALANCED

# --- ESTADO DEL PADRE (DOBLE AGENCIA) ---
var father_max_energy: int = 100
var father_energy: int = 100
var father_reputation: int = 60
var seal_investigation_progress: int = 0

# --- HORNO DE FUSIÓN ASTRAL & INVENTARIO ---
var astral_saturation: int = 0
var active_mutations: Array[String] = []     # ids de CatalogDB.MUTATIONS
var unlocked_synergies: Array[String] = []
var memory_shards_found: int = 0
var materials_inventory: Dictionary = {
	"comet_dust": 2, "quartz_marrow": 1, "mercury_dew": 1,
	"sarcophagus_shard": 0, "melted_hourglass": 0, "goddess_tear": 1
}
var estate_levels: Dictionary = {"library": 1, "armory": 1, "conservatory": 1, "crucible": 1}
var active_traits: Array[String] = []

var _batch_depth: int = 0
var _batch_dirty: bool = false
var _batch_seal_dirty: bool = false

func _ready() -> void:
	recalculate_derived_stats()
	evaluate_psychological_traits()

# ------------------------------------------------------------------------------
# NUEVA PARTIDA Y ARQUETIPOS
# ------------------------------------------------------------------------------
## Devuelve TODO el estado a los valores de inicio de campaña.
func reset_new_game() -> void:
	daughter_name = "Renpet"
	father_name = "Aurelius"
	father_archetype = HeroArchetype.MARTIAL
	age = 12
	prologue_completed = false
	run_seed = int(Time.get_unix_time_from_system()) ^ (Time.get_ticks_usec() & 0xFFFFFF)
	temple = 130; destreza = 120; erudicion = 135; gracia = 105; magnetismo = 100
	luminiscencia = 110; gravedad = 90; resonancia = 100; entropia = 5
	moralidad = 60; devocion = 50
	human_anchor = 70; seal_integrity = 92; abyssal_sync = 10
	stress = 15; affection = 75; gold = 850
	current_diet = DietPlan.BALANCED
	father_max_energy = 100; father_energy = 100; father_reputation = 60
	seal_investigation_progress = 0
	astral_saturation = 0
	active_mutations.clear()
	unlocked_synergies.clear()
	memory_shards_found = 0
	materials_inventory = {
		"comet_dust": 2, "quartz_marrow": 1, "mercury_dew": 1,
		"sarcophagus_shard": 0, "melted_hourglass": 0, "goddess_tear": 1
	}
	estate_levels = {"library": 1, "armory": 1, "conservatory": 1, "crucible": 1}
	max_stamina = 200 + int(temple * 1.2)
	current_stamina = max_stamina
	recalculate_derived_stats()
	evaluate_psychological_traits()
	stats_updated.emit()
	seal_state_changed.emit(seal_integrity, human_anchor, abyssal_sync)

## Aplica el trasfondo heroico elegido en el Prólogo sobre la base de inicio.
func apply_archetype_bonuses(arch: HeroArchetype) -> void:
	begin_batch()
	temple = 130; destreza = 120; erudicion = 135; gracia = 105; magnetismo = 100
	luminiscencia = 110; gravedad = 90; resonancia = 100
	human_anchor = 70; devocion = 50; stress = 15
	gold = 850; father_reputation = 60; seal_investigation_progress = 0

	father_archetype = arch
	match arch:
		HeroArchetype.MARTIAL:
			temple += 30
			destreza += 25
			father_reputation += 15
		HeroArchetype.SCHOLAR:
			erudicion += 35
			resonancia += 25
			seal_investigation_progress += 10
		HeroArchetype.ROGUE:
			gold += 400
			destreza += 20
			magnetismo += 20
		HeroArchetype.DEVOUT:
			human_anchor = clampi(human_anchor + 15, 0, 100)
			devocion = clampi(devocion + 20, 0, 100)
			stress = maxi(0, stress - 10)
	_batch_dirty = true
	_batch_seal_dirty = true
	end_batch()
	gold_changed.emit(gold)

func get_archetype_title() -> String:
	match father_archetype:
		HeroArchetype.MARTIAL: return "El Filo del Vértice (Héroe Marcial)"
		HeroArchetype.SCHOLAR: return "El Archimago del Velo (Héroe Sabio)"
		HeroArchetype.ROGUE: return "El Infiltrador del Silencio (Héroe de Sombras)"
		HeroArchetype.DEVOUT: return "El Custodio del Altar (Héroe Devoto)"
	return "Héroe de Aethelgard"

# ------------------------------------------------------------------------------
# ESTADÍSTICAS
# ------------------------------------------------------------------------------
func recalculate_derived_stats() -> void:
	max_stamina = 200 + int(temple * 1.2)
	current_stamina = clampi(current_stamina, 0, max_stamina)

func get_stat(stat_key: String) -> int:
	if stat_key == "gold":
		return gold
	if stat_key == "seal_investigation":
		return seal_investigation_progress
	if STAT_RANGES.has(stat_key):
		return int(get(stat_key))
	push_warning("GameState.get_stat: atributo desconocido '%s'" % stat_key)
	return 0

func is_known_stat(stat_key: String) -> bool:
	return STAT_RANGES.has(stat_key) or stat_key == "seal_investigation" or stat_key == "gold"

func get_secret_tier() -> int:
	if seal_investigation_progress >= 85 or memory_shards_found >= 4 or (ExplorationCombat != null and ExplorationCombat.story_acts_seen.has(17)):
		return 2
	if seal_investigation_progress >= 40 or memory_shards_found >= 2 or has_mutation("voz_del_prisionero") or (ExplorationCombat != null and ExplorationCombat.story_acts_seen.has(14)):
		return 1
	return 0

func get_stat_label(stat_key: String) -> String:
	var tier: int = get_secret_tier()
	if stat_key == "seal_integrity":
		return "Armonía Estelar" if tier == 0 else ("Estabilidad del Sello" if tier == 1 else "Sello Estelar")
	if stat_key == "abyssal_sync":
		return "Eco del Eclipse" if tier == 0 else ("Sincronía con Zephyr" if tier == 1 else "Sincronía Nyx-Aethel")
	if stat_key == "seal_investigation":
		return "Indagación del Origen" if tier == 0 else ("Investigación del Sello" if tier == 1 else "Verdad de la Prisión")
	return str(STAT_LABELS.get(stat_key, stat_key.capitalize()))

## Cambia un atributo respetando su rango. Devuelve el cambio REAL aplicado (tras el clamp).
func modify_stat(stat_key: String, delta: int) -> int:
	if delta == 0:
		return 0
	if stat_key == "gold":
		return delta if modify_gold(delta) else 0
	var key: String = "seal_investigation_progress" if stat_key == "seal_investigation" else stat_key
	var range_key: String = "seal_investigation" if stat_key == "seal_investigation_progress" else stat_key
	if not STAT_RANGES.has(range_key):
		push_warning("GameState.modify_stat: atributo desconocido '%s'" % stat_key)
		return 0
	var bounds: Array = STAT_RANGES[range_key]
	var before: int = int(get(key))
	var after: int = clampi(before + delta, int(bounds[0]), int(bounds[1]))
	set(key, after)
	var applied: int = after - before
	if applied != 0:
		_batch_dirty = true
		if key in ["seal_integrity", "human_anchor", "abyssal_sync"]:
			_batch_seal_dirty = true
		if _batch_depth == 0:
			_flush()
	return applied

## Devuelve true si se pudo aplicar (nunca deja el oro en negativo).
func modify_gold(delta: int) -> bool:
	if gold + delta < 0:
		return false
	gold += delta
	gold_changed.emit(gold)
	_batch_dirty = true
	if _batch_depth == 0:
		_flush()
	return true

## Agrupa varias modificaciones en una sola actualización de interfaz.
func begin_batch() -> void:
	_batch_depth += 1

func end_batch() -> void:
	_batch_depth = maxi(0, _batch_depth - 1)
	if _batch_depth == 0 and _batch_dirty:
		_flush()

func _flush() -> void:
	_batch_dirty = false
	recalculate_derived_stats()
	evaluate_psychological_traits()
	stats_updated.emit()
	if _batch_seal_dirty:
		_batch_seal_dirty = false
		seal_state_changed.emit(seal_integrity, human_anchor, abyssal_sync)

func has_mutation(mut_id: String) -> bool:
	return active_mutations.has(mut_id)

func add_mutation(mut_id: String) -> bool:
	if active_mutations.has(mut_id):
		return false
	active_mutations.append(mut_id)
	return true

func has_trait_prefix(prefix: String) -> bool:
	for t in active_traits:
		if t.begins_with(prefix):
			return true
	return false

func is_adult() -> bool:
	return age >= ROMANCE_MIN_AGE

## Generador determinista: misma partida + mismo turno + misma sal => misma tirada.
func det_rng(salt: String, extra: int = 0) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	var turn: int = TimeManager.current_total_turn if TimeManager != null else 1
	rng.seed = hash([run_seed, turn, salt, extra])
	return rng

# ------------------------------------------------------------------------------
# RASGOS PSICOLÓGICOS (motor determinista sin IA) - máximo 4 activos, por prioridad
# Umbrales de los 4 rasgos principales según la Biblia (§1.3); los 3 extra son del proyecto.
# ------------------------------------------------------------------------------
func evaluate_psychological_traits() -> void:
	var found: Array[String] = []
	# Prioridad 1: estados de crisis
	if seal_integrity < 50 and stress > 65:
		found.append("Insomnio de las Estrellas (Inestable)")
	if seal_integrity < 60 and abyssal_sync >= 30:
		found.append("Ojos de Eclipse (Escucha a Zephyr)" if get_secret_tier() >= 1 else "Ojos de Eclipse (Sueños Nocturnos)")
	if entropia >= 40 and human_anchor < 45:
		found.append("Rencor del Sarcófago (Rebelde)" if get_secret_tier() >= 2 else "Desdén Astral (Rebelde)")
	# Prioridad 2: carácter forjado
	if affection > 80 and human_anchor > 70:
		found.append("Orgullo del Hogar (Devota)")
	if temple > 450 and destreza > 450:
		found.append("Corazón Indómito (Guerrera)")
	if erudicion > 400 and affection < 45:
		found.append("Mente de Cristal Frío (Calculadora)")
	if gracia > 400 and magnetismo > 400:
		found.append("Rosa de Alabastro (Favorita de la Corte)")

	if found.size() > MAX_ACTIVE_TRAITS:
		found = found.slice(0, MAX_ACTIVE_TRAITS)
	if found.is_empty():
		found.append("Lucero Curioso (En Formación)")

	var changed: bool = found != active_traits
	active_traits = found
	if changed:
		traits_updated.emit(active_traits)

func get_metaphysical_state_title() -> String:
	var tier: int = get_secret_tier()
	if seal_integrity <= 20 and human_anchor < 40:
		return "CRÍTICO: Despertar del Eclipse Devorador" if tier >= 2 else "CRÍTICO: Tormenta Estelar Incontrolable"
	elif seal_integrity < 55 and human_anchor >= 70:
		return "SIMBIOSIS: Domando al Prisionero con Amor Humano" if tier >= 2 else "ARMONÍA DUAL: El Latido Oculto en Calma"
	elif seal_integrity >= 70 and human_anchor >= 65:
		return "ESTABLE: Corazón Mortal Luminoso"
	elif seal_integrity >= 70 and human_anchor < 40:
		return "FRÍO: Vasija Obediente de la Diosa" if tier >= 2 else "DISTANTE: Pureza Astral Silenciosa"
	return "RESONANTE: Fluctuación entre Estrella y Humana"

## Saludo dinámico determinista según estrés, sello, edad, afecto y logros
func get_dynamic_manor_greeting() -> String:
	if stress >= 75:
		return "\"Padre... me pesan los párpados y siento un zumbido constante dentro del pecho. ¿Podríamos descansar un poco este mes?\""
	if seal_integrity < 50 and abyssal_sync >= 40:
		if get_secret_tier() >= 1:
			return "\"Anoche volví a ver a ese chico de ojos de eclipse en mis sueños, Padre. Dice que la Diosa nos mintió a los dos... pero mientras tú estés conmigo, no tengo miedo.\""
		return "\"Anoche volví a soñar con un espejo de agua violeta, Padre. Hay una mirada antigua detrás... pero mientras tú estés conmigo, no tengo miedo.\""
	if age >= 17 and seal_investigation_progress >= 60:
		return "\"He estado leyendo tus notas sobre el templo antiguo. Sea lo que sea que encerraron dentro de mí cuando nací, juro que no dejaré que nos separe.\""
	if astral_saturation >= 70:
		return "\"Siento la luz demasiado cerca de la piel, Padre. Creo que me excedí con el Horno... ¿me ayudas con la infusión de lirio?\""
	if affection >= 80 and human_anchor >= 75:
		return "\"¡Bienvenido a casa, Padre! He preparado té caliente antes de repasar mis lecciones. Me alegra tanto que cenemos juntos hoy.\""
	if temple >= 250 and destreza >= 220:
		return "\"He estado practicando la postura de corte en el patio. Si Dama Vespera cree que me vencerá en el próximo Festival, se llevará una sorpresa.\""
	if erudicion >= 250:
		return "\"Las efemérides de la Torre del Astrolabio tenían un error de cálculo en la tercera luna; Soren y yo pasamos toda la tarde corrigiéndolo.\""
	if gold < 120:
		return "\"Padre, vi las cuentas de la casa. No quiero preocuparte, pero este bimestre tendremos que apretarnos el cinturón.\""
	return "\"Buenos días, Padre. El cielo de Aethelgard brilla con claridad hoy. ¿Qué planes tenemos para este bimestre?\""

# ------------------------------------------------------------------------------
# GUARDADO
# ------------------------------------------------------------------------------
func serialize() -> Dictionary:
	return {
		"daughter_name": daughter_name, "age": age, "father_name": father_name,
		"father_archetype": int(father_archetype), "prologue_completed": prologue_completed, "run_seed": run_seed,
		"temple": temple, "destreza": destreza, "erudicion": erudicion, "gracia": gracia, "magnetismo": magnetismo,
		"luminiscencia": luminiscencia, "gravedad": gravedad, "resonancia": resonancia, "entropia": entropia,
		"moralidad": moralidad, "devocion": devocion,
		"human_anchor": human_anchor, "seal_integrity": seal_integrity, "abyssal_sync": abyssal_sync,
		"stress": stress, "current_stamina": current_stamina, "affection": affection, "gold": gold,
		"current_diet": int(current_diet),
		"father_energy": father_energy, "father_reputation": father_reputation,
		"seal_investigation_progress": seal_investigation_progress,
		"astral_saturation": astral_saturation, "memory_shards_found": memory_shards_found,
		"active_mutations": active_mutations.duplicate(),
		"unlocked_synergies": unlocked_synergies.duplicate(),
		"materials_inventory": materials_inventory.duplicate(),
		"estate_levels": estate_levels.duplicate()
	}

func deserialize(d: Dictionary) -> void:
	daughter_name = str(d.get("daughter_name", "Renpet"))
	age = clampi(int(d.get("age", 12)), 12, 20)
	father_name = str(d.get("father_name", "Aurelius"))
	father_archetype = clampi(int(d.get("father_archetype", 0)), 0, 3) as HeroArchetype
	prologue_completed = bool(d.get("prologue_completed", true))
	run_seed = int(d.get("run_seed", 12345))
	for k in BIG_STATS:
		var defaults: Dictionary = {"temple": 130, "destreza": 120, "erudicion": 135, "gracia": 105,
			"magnetismo": 100, "luminiscencia": 110, "gravedad": 90, "resonancia": 100}
		set(k, clampi(int(d.get(k, defaults[k])), 0, MAX_BIG_STAT))
	entropia = clampi(int(d.get("entropia", 5)), 0, 100)
	moralidad = clampi(int(d.get("moralidad", 60)), 0, 100)
	devocion = clampi(int(d.get("devocion", 50)), 0, 100)
	human_anchor = clampi(int(d.get("human_anchor", 70)), 0, 100)
	seal_integrity = clampi(int(d.get("seal_integrity", 92)), 0, 100)
	abyssal_sync = clampi(int(d.get("abyssal_sync", 10)), 0, 100)
	stress = clampi(int(d.get("stress", 15)), 0, 100)
	affection = clampi(int(d.get("affection", 75)), 0, 100)
	gold = maxi(0, int(d.get("gold", 850)))
	current_diet = clampi(int(d.get("current_diet", 1)), 0, 3) as DietPlan
	father_energy = clampi(int(d.get("father_energy", 100)), 0, 100)
	father_reputation = clampi(int(d.get("father_reputation", 60)), 0, 100)
	seal_investigation_progress = clampi(int(d.get("seal_investigation_progress", 0)), 0, 100)
	astral_saturation = clampi(int(d.get("astral_saturation", 0)), 0, 100)
	memory_shards_found = clampi(int(d.get("memory_shards_found", 0)), 0, 5)

	active_mutations.clear()
	for m in d.get("active_mutations", []):
		var mid: String = str(m)
		mid = str(CatalogDB.LEGACY_MUTATION_NAMES.get(mid, mid))   # migra partidas antiguas
		if CatalogDB.MUTATIONS.has(mid) and not active_mutations.has(mid):
			active_mutations.append(mid)
	unlocked_synergies.clear()
	for s in d.get("unlocked_synergies", []):
		if not unlocked_synergies.has(str(s)):
			unlocked_synergies.append(str(s))

	var inv: Dictionary = {"comet_dust": 0, "quartz_marrow": 0, "mercury_dew": 0,
		"sarcophagus_shard": 0, "melted_hourglass": 0, "goddess_tear": 0}
	var saved_inv: Variant = d.get("materials_inventory", {})
	if typeof(saved_inv) == TYPE_DICTIONARY:
		for k in saved_inv.keys():
			inv[str(k)] = maxi(0, int(saved_inv[k]))
	materials_inventory = inv
	var est: Dictionary = {"library": 1, "armory": 1, "conservatory": 1, "crucible": 1}
	var saved_est: Variant = d.get("estate_levels", {})
	if typeof(saved_est) == TYPE_DICTIONARY:
		for k in saved_est.keys():
			est[str(k)] = clampi(int(saved_est[k]), 1, 5)
	estate_levels = est

	recalculate_derived_stats()
	current_stamina = clampi(int(d.get("current_stamina", max_stamina)), 0, max_stamina)
	evaluate_psychological_traits()
	stats_updated.emit()
	gold_changed.emit(gold)
	seal_state_changed.emit(seal_integrity, human_anchor, abyssal_sync)
