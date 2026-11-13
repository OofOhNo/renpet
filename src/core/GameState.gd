extends Node

## Singleton GameState - Estado maestro de Renpet, el Padre (Héroe), el Sello Estelar y el Horno Astral.
## Fase 1: matemáticas de atributos, 3 medidores nucleares, perfil del Padre y rasgos psicológicos.

signal stats_updated()
signal seal_state_changed(seal_integrity: int, human_anchor: int, abyssal_sync: int)
signal traits_updated(active_traits: Array[String])
signal gold_changed(new_gold: int)
signal annual_goal_completed(goal: Dictionary)

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
	"seal_investigation": [0, 100], "astral_saturation": [0, 100], "father_reputation": [0, 100],
	"court_suspicion": [0, 100], "mood_calm": [-100, 100], "mood_pride": [-100, 100]
}
const STAT_LABELS: Dictionary = {
	"temple": "Temple", "destreza": "Destreza", "erudicion": "Erudición", "gracia": "Gracia",
	"magnetismo": "Magnetismo", "luminiscencia": "Luminiscencia", "gravedad": "Gravedad",
	"resonancia": "Resonancia", "entropia": "Entropía", "moralidad": "Moralidad", "devocion": "Devoción",
	"stress": "Estrés", "affection": "Afecto", "human_anchor": "Anclaje Humano",
	"seal_integrity": "Armonía Interior", "abyssal_sync": "Brillo Nocturno",
	"seal_investigation": "Pesquisa Astral", "astral_saturation": "Saturación Astral",
	"father_reputation": "Reputación Paterna", "court_suspicion": "Sospecha del Senado",
	"mood_calm": "Inquietud Emocional", "mood_pride": "Altivez Emocional", "gold": "Oro"
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

# --- TEMPERAMENTO, SALUD CRÍTICA Y VIGILANCIA IMPERIAL ---
var mood_calm: int = 0          # -100 Serena ↔ +100 Inquieta
var mood_pride: int = 0         # -100 Empática ↔ +100 Arrogante
var court_suspicion: int = 0    # 0 a 100 Sospecha del Senado / Inquisición Solar
var exhausted_sick: bool = false
var sick_dialogue_pending: bool = false
var pending_astral_crisis: bool = false
var consecutive_assimilations: int = 0
var assimilated_this_bimester: bool = false
var senate_inspections_count: int = 0
var clinic_tonic_used: bool = false
var omitted_npc_events: Array[String] = []
var story_ng_echo_used: bool = false

# --- VESTUARIO, RETIROS, OBJETIVO ANUAL Y MAZO ---
var owned_outfits: Array[String] = ["default"]
var equipped_outfit: String = "default"
var equipped_cards: Array[String] = []
var active_vacation_bg: String = ""
var vacation_used_years: Array[int] = []
var annual_goal: Dictionary = {}

# --- HORNO DE FUSIÓN ASTRAL & INVENTARIO ---
var astral_saturation: int = 0
var active_mutations: Array[String] = []     # ids de CatalogDB.MUTATIONS
var unlocked_synergies: Array[String] = []
var memory_shards_found: int = 0
var materials_inventory: Dictionary = {
	"comet_dust": 2, "quartz_marrow": 1, "mercury_dew": 1,
	"sarcophagus_shard": 0, "melted_hourglass": 0, "goddess_tear": 1
}
var gifts_inventory: Dictionary = {}
var estate_levels: Dictionary = {
	"library": 1, "armory": 1, "conservatory": 1, "crucible": 1,
	"sanctum": 1, "treasury": 1
}
var consumables_inventory: Dictionary = {}
var owned_tomes: Array[String] = []
var owned_equipment: Array[String] = []
var equipped_weapon: String = ""
var equipped_accessory: String = ""
var civic_investments: Array[String] = []
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
	gifts_inventory.clear()
	estate_levels = {
		"library": 1, "armory": 1, "conservatory": 1, "crucible": 1,
		"sanctum": 1, "treasury": 1
	}
	consumables_inventory.clear()
	owned_tomes.clear()
	owned_equipment.clear()
	equipped_weapon = ""
	equipped_accessory = ""
	civic_investments.clear()
	mood_calm = 0; mood_pride = 0; court_suspicion = 0
	exhausted_sick = false; sick_dialogue_pending = false; pending_astral_crisis = false
	consecutive_assimilations = 0; assimilated_this_bimester = false; senate_inspections_count = 0; clinic_tonic_used = false
	omitted_npc_events.clear(); story_ng_echo_used = false
	owned_outfits = ["default"]; equipped_outfit = "default"
	equipped_cards.clear(); active_vacation_bg = ""; vacation_used_years.clear()
	roll_annual_goal_for_year(12)
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
	var outfit_hp: int = 60 if equipped_outfit == "horizon" else 0
	var mut_hp: int = 40 if has_mutation("sangre_pesada") else 0
	var equip_hp: int = int(round(get_equip_mod("combat_hp", 0.0)))
	var sanctum_hp: int = maxi(0, int(estate_levels.get("sanctum", 1)) - 1) * 6
	max_stamina = 200 + int(temple * 1.2) + outfit_hp + mut_hp + equip_hp + sanctum_hp
	current_stamina = clampi(current_stamina, 0, max_stamina)
	father_max_energy = 125 if has_mutation("paradoja_menor") else 100
	father_energy = clampi(father_energy, 0, father_max_energy)

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

## Ocultamiento progresivo del giro: Tier 0 = misterio intacto (años 12-13),
## Tier 1 = primeros indicios reales en Acto II (edad 14+), Tier 2 = revelación completa (edad 16+/Acto III).
func get_secret_tier() -> int:
	var seen_17: bool = (ExplorationCombat != null and ExplorationCombat.story_acts_seen.has(17))
	var seen_14: bool = (ExplorationCombat != null and ExplorationCombat.story_acts_seen.has(14))
	if seen_17 or (age >= 16 and (seal_investigation_progress >= 88 or memory_shards_found >= 4)):
		return 2
	if has_mutation("voz_del_prisionero") or (age >= 14 and (seen_14 or seal_investigation_progress >= 55 or memory_shards_found >= 2)):
		return 1
	return 0

func get_stat_label(stat_key: String) -> String:
	var tier: int = get_secret_tier()
	if stat_key == "seal_integrity":
		return "Armonía Interior" if tier == 0 else ("Resguardo del Cristal" if tier == 1 else "Sello Estelar")
	if stat_key == "abyssal_sync":
		return "Brillo Nocturno" if tier == 0 else ("Eco del Espejo" if tier == 1 else "Sincronía Nyx-Aethel")
	if stat_key == "seal_investigation":
		return "Pesquisa Astral" if tier == 0 else ("Archivos Censurados" if tier == 1 else "Verdad de la Prisión")
	return str(STAT_LABELS.get(stat_key, stat_key.capitalize()))

func get_stat_tooltip(stat_key: String) -> String:
	var tier: int = get_secret_tier()
	if stat_key == "seal_integrity":
		if tier == 0:
			return "Equilibrio de la luz estelar que late en su pecho. Si cae demasiado, sufre pesadillas y desgaste."
		if tier == 1:
			return "Integridad del resguardo cristalino en su pecho. Si desciende demasiado, los ecos nocturnos cobran fuerza."
		return "Integridad del Sello Estelar que contiene a Nyx-Aethel. Determina si la Cosecha o la ruptura se precipita."
	if stat_key == "abyssal_sync":
		if tier == 0:
			return "Afinidad silenciosa con las sombras suaves que aparecen al caer la noche en el observatorio."
		if tier == 1:
			return "Vínculo con la presencia reflejada tras los espejos de agua cuando la luna mengua."
		return "Sincronía mutua con Zephyr (Nyx-Aethel). Clave para comprenderla o abrir la Síntesis."
	if stat_key == "seal_investigation":
		if tier == 0:
			return "Apuntes sobre anomalías astrales e inscripciones antiguas borradas en la capital."
		if tier == 1:
			return "Progreso al cruzar archivos censurados del Santuario con vestigios anteriores a Aethelgard."
		return "Conocimiento real de la prisión astral creada por la Diosa de la Eternidad."
	if stat_key == "astral_saturation":
		return "Densidad cósmica temporal tras usar el Crisol Astral. Conviene purificarla o dejarla reposar."
	return str(AstralTheme.STAT_TOOLTIPS.get(stat_key, ""))

func get_gift_count(gift_id: String) -> int:
	return int(gifts_inventory.get(gift_id, 0))

func buy_gift(gift_id: String, unit_price: int = -1) -> Dictionary:
	var cost: int = unit_price
	if cost < 0:
		var g: Dictionary = CatalogDB.get_gift(gift_id)
		cost = int(g.get("price", 0))
	if cost <= 0 or not modify_gold(-cost):
		return {"ok": false, "msg": "Oro insuficiente para adquirir este obsequio."}
	gifts_inventory[gift_id] = get_gift_count(gift_id) + 1
	stats_updated.emit()
	return {"ok": true, "msg": "Obsequio guardado en el equipaje."}

func consume_gift(gift_id: String) -> bool:
	var cnt: int = get_gift_count(gift_id)
	if cnt <= 0:
		return false
	if cnt == 1:
		gifts_inventory.erase(gift_id)
	else:
		gifts_inventory[gift_id] = cnt - 1
	stats_updated.emit()
	return true

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
		found.append("Ojos de Eclipse (Escucha a Zephyr)" if get_secret_tier() >= 2 else "Ojos de Eclipse (Sueños Nocturnos)")
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

# ------------------------------------------------------------------------------
# TEMPERAMENTO, VESTUARIO, RETRATOS, OBJETIVO ANUAL Y CARTAS DE RECUERDO
# ------------------------------------------------------------------------------
func get_mood_summary() -> Dictionary:
	var c_lbl: String = "Equilibrada"
	var c_col: Color = Color("a8b1d8")
	if mood_calm <= -20:
		c_lbl = "Serena"
		c_col = Color("49d6c8")
	elif mood_calm >= 20:
		c_lbl = "Inquieta"
		c_col = Color("ff9f5a")
	var p_lbl: String = "Ponderada"
	var p_col: Color = Color("a8b1d8")
	if mood_pride <= -20:
		p_lbl = "Empática"
		p_col = Color("86e3a6")
	elif mood_pride >= 20:
		p_lbl = "Arrogante"
		p_col = Color("f7e3a1")
	return {
		"calm": c_lbl, "calm_color": c_col, "calm_val": mood_calm,
		"pride": p_lbl, "pride_color": p_col, "pride_val": mood_pride,
		"short_tag": "%s · %s" % [c_lbl, p_lbl]
	}

## Multiplicador aditivo sobre una actividad según el temperamento (-0.15 a +0.20)
func get_mood_activity_mod(act_id: String) -> float:
	var m: float = 0.0
	if mood_calm <= -20:
		if act_id in ["class_astrolabe", "class_sanctuary", "job_clockwork"]:
			m += 0.20
		elif act_id in ["class_armory", "job_caravan"]:
			m -= 0.15
	elif mood_calm >= 20:
		if act_id in ["class_armory", "job_caravan", "job_canals"]:
			m += 0.20
		elif act_id in ["class_astrolabe", "class_sanctuary"]:
			m -= 0.15
	if mood_pride <= -20:
		if act_id in ["job_sanatorium", "rest_manor"]:
			m += 0.20
		elif act_id == "job_canals":
			m -= 0.15
	elif mood_pride >= 20:
		if act_id in ["class_conservatory", "job_amphitheater"]:
			m += 0.20
		elif act_id == "job_sanatorium":
			m -= 0.15
	return m

func get_active_portrait_path() -> String:
	if equipped_outfit != "default":
		var out_p: String = "res://assets/art/renpet_outfit_%s.png" % equipped_outfit
		if FileAccess.file_exists(out_p) or ResourceLoader.exists(out_p):
			return out_p
	if age >= 18:
		var p3: String = "res://assets/art/renpet_portrait_act3.png"
		if FileAccess.file_exists(p3) or ResourceLoader.exists(p3):
			return p3
	if age >= 15:
		var p2: String = "res://assets/art/renpet_portrait_act2.png"
		if FileAccess.file_exists(p2) or ResourceLoader.exists(p2):
			return p2
	return "res://assets/art/renpet_portrait.png"

func get_outfit_mod(mod_key: String, default_v: float = 0.0) -> float:
	var o: Dictionary = CatalogDB.get_outfit(equipped_outfit)
	var mods: Dictionary = o.get("mods", {})
	return float(mods.get(mod_key, default_v))

func buy_outfit(outfit_id: String) -> Dictionary:
	if owned_outfits.has(outfit_id):
		return equip_outfit(outfit_id)
	var o: Dictionary = CatalogDB.get_outfit(outfit_id)
	if o.get("id", "") != outfit_id:
		return {"ok": false, "msg": "Atuendo desconocido."}
	var price: int = int(o.get("price", 0))
	if not modify_gold(-price):
		return {"ok": false, "msg": "Necesitas %d G para comprar «%s»." % [price, o["name"]]}
	owned_outfits.append(outfit_id)
	equipped_outfit = outfit_id
	recalculate_derived_stats()
	stats_updated.emit()
	return {"ok": true, "msg": "Comprado y equipado: %s (-%d G)." % [o["name"], price]}

func equip_outfit(outfit_id: String) -> Dictionary:
	if not owned_outfits.has(outfit_id):
		return {"ok": false, "msg": "Primero debes adquirir este atuendo en la Boutique de Aethelgard."}
	equipped_outfit = outfit_id
	recalculate_derived_stats()
	stats_updated.emit()
	return {"ok": true, "msg": "Atuendo equipado: %s." % CatalogDB.get_outfit(outfit_id)["name"]}

# ------------------------------------------------------------------------------
# CONSUMIBLES, TOMOS DE ESTUDIO, EQUIPO Y PATRONAZGO CÍVICO
# ------------------------------------------------------------------------------
func get_consumable_count(item_id: String) -> int:
	return int(consumables_inventory.get(item_id, 0))

func buy_consumable(item_id: String) -> Dictionary:
	var item: Dictionary = CatalogDB.get_consumable(item_id)
	if item.is_empty():
		return {"ok": false, "msg": "Consumible desconocido."}
	var price: int = int(item.get("price", 0))
	if not modify_gold(-price):
		return {"ok": false, "msg": "Necesitas %d G para comprar «%s»." % [price, item["name"]]}
	consumables_inventory[item_id] = get_consumable_count(item_id) + 1
	stats_updated.emit()
	return {"ok": true, "msg": "Adquirido: %s (-%d G). Guardado para expediciones." % [item["name"], price]}

func consume_combat_item(item_id: String) -> bool:
	var cnt: int = get_consumable_count(item_id)
	if cnt <= 0:
		return false
	if cnt == 1:
		consumables_inventory.erase(item_id)
	else:
		consumables_inventory[item_id] = cnt - 1
	stats_updated.emit()
	return true

func buy_tome(tome_id: String) -> Dictionary:
	if owned_tomes.has(tome_id):
		return {"ok": false, "msg": "Este tratado ya reposa en tu biblioteca personal."}
	var tome: Dictionary = CatalogDB.get_tome(tome_id)
	if tome.is_empty():
		return {"ok": false, "msg": "Tratado desconocido."}
	var price: int = int(tome.get("price", 0))
	if not modify_gold(-price):
		return {"ok": false, "msg": "Necesitas %d G para adquirir «%s»." % [price, tome["name"]]}
	owned_tomes.append(tome_id)
	begin_batch()
	var effects: Dictionary = tome.get("stats", {})
	for k in effects.keys():
		modify_stat(str(k), int(effects[k]))
	end_batch()
	if Chronicle != null:
		Chronicle.record_event("tome_" + tome_id, "Nuevo tratado en la Bóveda",
			"%s incorporó «%s» a su biblioteca de estudio (-%d G)." % [daughter_name, tome["name"], price], "study", 2)
	return {"ok": true, "msg": "Estudiado y archivado: %s (-%d G)." % [tome["name"], price]}

func get_tome_study_mod() -> float:
	var pct: int = 0
	for tid in owned_tomes:
		var t: Dictionary = CatalogDB.get_tome(tid)
		pct += int(t.get("study_pct", 0))
	for cid in civic_investments:
		var inv: Dictionary = CatalogDB.get_civic_investment(cid)
		pct += int(inv.get("study_bonus_pct", 0))
	return float(pct) / 100.0

func get_tome_sat_reduction() -> int:
	var red: int = 0
	for tid in owned_tomes:
		var t: Dictionary = CatalogDB.get_tome(tid)
		red += int(t.get("sat_red", 0))
	return red

func buy_equipment(equip_id: String) -> Dictionary:
	if owned_equipment.has(equip_id):
		return equip_item(equip_id)
	var eq: Dictionary = CatalogDB.get_equipment(equip_id)
	if eq.is_empty():
		return {"ok": false, "msg": "Pieza de equipo desconocida."}
	var price: int = int(eq.get("price", 0))
	if not modify_gold(-price):
		return {"ok": false, "msg": "Necesitas %d G para forjar o adquirir «%s»." % [price, eq["name"]]}
	owned_equipment.append(equip_id)
	if str(eq.get("slot", "")) == "weapon":
		equipped_weapon = equip_id
	else:
		equipped_accessory = equip_id
	recalculate_derived_stats()
	stats_updated.emit()
	return {"ok": true, "msg": "Adquirido y equipado: %s (-%d G)." % [eq["name"], price]}

func equip_item(equip_id: String) -> Dictionary:
	if equip_id == "":
		return {"ok": false, "msg": "Equipo inválido."}
	if not owned_equipment.has(equip_id):
		return {"ok": false, "msg": "Aún no posees esta pieza."}
	var eq: Dictionary = CatalogDB.get_equipment(equip_id)
	if eq.is_empty():
		return {"ok": false, "msg": "Pieza desconocida."}
	var slot: String = str(eq.get("slot", "weapon"))
	if slot == "weapon":
		if equipped_weapon == equip_id:
			equipped_weapon = ""
			recalculate_derived_stats()
			stats_updated.emit()
			return {"ok": true, "msg": "Arma desequipado: %s." % eq["name"]}
		equipped_weapon = equip_id
	else:
		if equipped_accessory == equip_id:
			equipped_accessory = ""
			recalculate_derived_stats()
			stats_updated.emit()
			return {"ok": true, "msg": "Reliquia desequipado: %s." % eq["name"]}
		equipped_accessory = equip_id
	recalculate_derived_stats()
	stats_updated.emit()
	return {"ok": true, "msg": "Equipado: %s." % eq["name"]}

func get_equip_mod(mod_key: String, default_v: float = 0.0) -> float:
	var total: float = 0.0
	var any_hit: bool = false
	for eid in [equipped_weapon, equipped_accessory]:
		if eid == "":
			continue
		var eq: Dictionary = CatalogDB.get_equipment(eid)
		var mods: Dictionary = eq.get("mods", {})
		if mods.has(mod_key):
			total += float(mods[mod_key])
			any_hit = true
	if not any_hit:
		return default_v
	# Porcentajes almacenados como enteros (ej. 12 -> 0.12); planos como enteros directos
	if mod_key.ends_with("_pct"):
		return total / 100.0
	return total

func invest_civic(inv_id: String) -> Dictionary:
	if civic_investments.has(inv_id):
		return {"ok": false, "msg": "Este patronazgo cívico ya está activo a tu nombre."}
	var inv: Dictionary = CatalogDB.get_civic_investment(inv_id)
	if inv.is_empty():
		return {"ok": false, "msg": "Edicto o patronazgo desconocido."}
	var price: int = int(inv.get("price", 0))
	if not modify_gold(-price):
		return {"ok": false, "msg": "Necesitas %d G en las arcas para sellar «%s»." % [price, inv["name"]]}
	civic_investments.append(inv_id)
	begin_batch()
	if int(inv.get("rep_gain", 0)) > 0:
		modify_stat("father_reputation", int(inv["rep_gain"]))
	if int(inv.get("susp_relief", 0)) > 0:
		modify_stat("court_suspicion", -int(inv["susp_relief"]))
	end_batch()
	if Chronicle != null:
		Chronicle.record_event("civic_" + inv_id, "Patronazgo sellado en Aethelgard",
			"%s financió «%s» (-%d G), ganando respeto duradero ante el Senado." % [father_name, inv["name"], price], "patronage", 4)
	return {"ok": true, "msg": "Carta sellada: %s (-%d G)." % [inv["name"], price]}

func get_civic_dividend() -> int:
	var g: int = maxi(0, int(estate_levels.get("treasury", 1)) - 1) * 18
	for cid in civic_investments:
		var inv: Dictionary = CatalogDB.get_civic_investment(cid)
		g += int(inv.get("dividend", 0))
	return g

func get_civic_suspicion_relief() -> int:
	var s: int = maxi(0, int(estate_levels.get("treasury", 1)) - 1)
	s += int(round(get_equip_mod("suspicion_relief", 0.0)))
	for cid in civic_investments:
		var inv: Dictionary = CatalogDB.get_civic_investment(cid)
		s += int(inv.get("bimester_susp_relief", 0))
	return s

func get_civic_stress_relief() -> int:
	var st: int = maxi(0, int(estate_levels.get("sanctum", 1)) - 1) * 2
	for cid in civic_investments:
		var inv: Dictionary = CatalogDB.get_civic_investment(cid)
		st += int(inv.get("stress_relief", 0))
	return st

func is_memory_card_unlocked(card: Dictionary) -> bool:
	var cond: String = str(card.get("unlock", ""))
	if cond.begins_with("trait:"):
		return has_trait_prefix(cond.substr(6))
	if cond.begins_with("shard:"):
		return ExplorationCombat != null and ExplorationCombat.memory_shards_found.has(cond.substr(6))
	if cond.begins_with("bond:"):
		var parts: PackedStringArray = cond.split(":")
		if parts.size() >= 3 and RelationshipManager != null:
			var st: Dictionary = RelationshipManager.get_state(parts[1])
			return int(st.get("stage", 1)) >= int(parts[2])
	return false

func get_unlocked_memory_cards() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in CatalogDB.MEMORY_CARDS:
		if is_memory_card_unlocked(c):
			out.append(c)
	return out

func get_equipped_memory_cards() -> Array[Dictionary]:
	var unlocked: Array[Dictionary] = get_unlocked_memory_cards()
	var valid_ids: Array[String] = []
	for u in unlocked:
		valid_ids.append(str(u["id"]))
	# Limpia cartas ya no válidas
	for i in range(equipped_cards.size() - 1, -1, -1):
		if not valid_ids.has(equipped_cards[i]):
			equipped_cards.remove_at(i)
	# Autoequipa hasta 4 si el mazo aún tiene hueco
	for u in unlocked:
		if equipped_cards.size() >= 4:
			break
		var cid: String = str(u["id"])
		if not equipped_cards.has(cid):
			equipped_cards.append(cid)
	var out: Array[Dictionary] = []
	for cid in equipped_cards:
		var c: Dictionary = CatalogDB.get_memory_card(cid)
		if not c.is_empty():
			out.append(c)
	return out

func toggle_equipped_card(card_id: String) -> Dictionary:
	var card: Dictionary = CatalogDB.get_memory_card(card_id)
	if card.is_empty() or not is_memory_card_unlocked(card):
		return {"ok": false, "msg": "Esta Carta de Recuerdo aún está bloqueada."}
	if equipped_cards.has(card_id):
		equipped_cards.erase(card_id)
		stats_updated.emit()
		return {"ok": true, "msg": "Carta retirada del mazo: %s." % card["name"]}
	if equipped_cards.size() >= 4:
		return {"ok": false, "msg": "Tu mazo ya lleva el máximo de 4 Cartas de Recuerdo equipadas. Desequipa una primero."}
	equipped_cards.append(card_id)
	stats_updated.emit()
	return {"ok": true, "msg": "Equipada en el mazo: %s." % card["name"]}

func roll_annual_goal_for_year(yr: int) -> void:
	match yr:
		12:
			annual_goal = {"year": 12, "title": "Alcanza 165 en tu atributo principal", "metric": "max_big", "target": 165, "completed": false}
		13:
			annual_goal = {"year": 13, "title": "Halla 1 Vestigio Antiguo o asimila 1 reliquia", "metric": "shards_or_mut", "target": 1, "completed": false}
		14:
			annual_goal = {"year": 14, "title": "Alcanza 230 en tu atributo principal", "metric": "max_big", "target": 230, "completed": false}
		15:
			annual_goal = {"year": 15, "title": "Alcanza 280 en un rasgo y 1 vínculo Etapa 2", "metric": "y15_bond_stats", "target": 280, "completed": false}
		16:
			annual_goal = {"year": 16, "title": "Llega a 360 en tu esfera dominante sin superar 50 de Sospecha", "metric": "y16_focus", "target": 360, "completed": false}
		17:
			annual_goal = {"year": 17, "title": "Desbloquea al menos 1 Sinergia de Prestigio", "metric": "synergies_count", "target": 1, "completed": false}
		18:
			annual_goal = {"year": 18, "title": "Alcanza 540 en tu vocación principal", "metric": "max_big", "target": 540, "completed": false}
		_:
			annual_goal = {"year": yr, "title": "Alcanza 680 en tu esfera dominante para el Solsticio", "metric": "max_big", "target": 680, "completed": false}

func get_annual_goal_status() -> Dictionary:
	if annual_goal.is_empty():
		roll_annual_goal_for_year(age)
	var metric: String = str(annual_goal.get("metric", "max_big"))
	var target: int = maxi(1, int(annual_goal.get("target", 100)))
	var cur: int = 0
	match metric:
		"max_big", "y16_focus":
			for k in BIG_STATS:
				cur = maxi(cur, int(get(k)))
			if metric == "y16_focus" and court_suspicion > 50 and not bool(annual_goal.get("completed", false)):
				cur = mini(cur, target - 1)
		"shards_or_mut":
			cur = maxi(memory_shards_found, active_mutations.size())
		"y15_bond_stats":
			var has_b2: bool = false
			if RelationshipManager != null:
				for nid in RelationshipManager.NPC_ORDER:
					if int(RelationshipManager.get_state(nid).get("stage", 1)) >= 2:
						has_b2 = true
						break
			for k in BIG_STATS:
				cur = maxi(cur, int(get(k)))
			if not has_b2:
				cur = mini(cur, target - 1)
		"synergies_count":
			cur = unlocked_synergies.size()
	var done: bool = bool(annual_goal.get("completed", false)) or cur >= target
	return {
		"title": str(annual_goal.get("title", "")),
		"current": cur, "target": target, "completed": bool(annual_goal.get("completed", false)),
		"ready": done
	}

func check_annual_goal_progress() -> Dictionary:
	var st: Dictionary = get_annual_goal_status()
	if st["ready"] and not bool(annual_goal.get("completed", false)):
		annual_goal["completed"] = true
		modify_gold(100)
		modify_stat("affection", 8)
		if Chronicle != null:
			Chronicle.record_event("annual_goal_%d" % int(annual_goal.get("year", age)),
				"Objetivo del Observatorio Cumplido", "%s completó «%s» (+100 Oro, +8 Afecto)." % [daughter_name, st["title"]], "family", 4)
		annual_goal_completed.emit(annual_goal.duplicate())
		return {"completed_now": true, "title": st["title"]}
	return {"completed_now": false}

## Saludo dinámico determinista según estado crítico, retiro, sospecha, temperamento y logros
func get_dynamic_manor_greeting() -> String:
	if active_vacation_bg == "amber_coast":
		return "\"¡Mira cómo brilla el sol sobre el mar de Ámbar, Padre! Hacía tanto tiempo que no escuchaba el viento sin relojes cerca.\""
	if active_vacation_bg == "boreal_obs":
		return "\"Las auroras boreales se reflejan en el té caliente... Gracias por traerme hasta este rincón tranquilo del invierno, Padre.\""
	if exhausted_sick:
		return "\"Perdóname, Padre... me tiemblan las manos y el médico prohibió las aulas hasta que descansemos en familia o vayamos al Sanatorio.\""
	if court_suspicion >= 70:
		return "\"Padre, vi guardias con el emblema de la Inquisición Solar vigilando nuestra esquina... ¿Debemos preocuparnos por los rumores del Senado?\""
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
	if mood_calm >= 35:
		return "\"Tengo el pulso acelerado hoy, Padre... necesito moverme, entrenar o explorar algo fuera de estas paredes.\""
	if mood_pride >= 35:
		return "\"Cada mirada en Aethelgard mide si somos dignos de tu apellido. Hoy demostraré de qué estamos hechos.\""
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
		"mood_calm": mood_calm, "mood_pride": mood_pride, "court_suspicion": court_suspicion,
		"exhausted_sick": exhausted_sick, "sick_dialogue_pending": sick_dialogue_pending,
		"pending_astral_crisis": pending_astral_crisis, "consecutive_assimilations": consecutive_assimilations,
		"assimilated_this_bimester": assimilated_this_bimester, "senate_inspections_count": senate_inspections_count,
		"clinic_tonic_used": clinic_tonic_used,
		"omitted_npc_events": omitted_npc_events.duplicate(), "story_ng_echo_used": story_ng_echo_used,
		"owned_outfits": owned_outfits.duplicate(), "equipped_outfit": equipped_outfit,
		"equipped_cards": equipped_cards.duplicate(),
		"active_vacation_bg": active_vacation_bg, "vacation_used_years": vacation_used_years.duplicate(),
		"annual_goal": annual_goal.duplicate(true),
		"active_mutations": active_mutations.duplicate(),
		"unlocked_synergies": unlocked_synergies.duplicate(),
		"materials_inventory": materials_inventory.duplicate(),
		"gifts_inventory": gifts_inventory.duplicate(),
		"estate_levels": estate_levels.duplicate(),
		"consumables_inventory": consumables_inventory.duplicate(),
		"owned_tomes": owned_tomes.duplicate(),
		"owned_equipment": owned_equipment.duplicate(),
		"equipped_weapon": equipped_weapon,
		"equipped_accessory": equipped_accessory,
		"civic_investments": civic_investments.duplicate()
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
	father_reputation = clampi(int(d.get("father_reputation", 60)), 0, 100)
	seal_investigation_progress = clampi(int(d.get("seal_investigation_progress", 0)), 0, 100)
	astral_saturation = clampi(int(d.get("astral_saturation", 0)), 0, 100)
	memory_shards_found = clampi(int(d.get("memory_shards_found", 0)), 0, 5)
	mood_calm = clampi(int(d.get("mood_calm", 0)), -100, 100)
	mood_pride = clampi(int(d.get("mood_pride", 0)), -100, 100)
	court_suspicion = clampi(int(d.get("court_suspicion", 0)), 0, 100)
	exhausted_sick = bool(d.get("exhausted_sick", false))
	sick_dialogue_pending = bool(d.get("sick_dialogue_pending", false))
	pending_astral_crisis = bool(d.get("pending_astral_crisis", false))
	consecutive_assimilations = maxi(0, int(d.get("consecutive_assimilations", 0)))
	assimilated_this_bimester = bool(d.get("assimilated_this_bimester", false))
	senate_inspections_count = maxi(0, int(d.get("senate_inspections_count", 0)))
	clinic_tonic_used = bool(d.get("clinic_tonic_used", false))
	story_ng_echo_used = bool(d.get("story_ng_echo_used", false))
	active_vacation_bg = str(d.get("active_vacation_bg", ""))

	omitted_npc_events.clear()
	for o in d.get("omitted_npc_events", []):
		omitted_npc_events.append(str(o))
	owned_outfits = ["default"]
	for oo in d.get("owned_outfits", []):
		var oid: String = str(oo)
		if not owned_outfits.has(oid):
			owned_outfits.append(oid)
	equipped_outfit = str(d.get("equipped_outfit", "default"))
	if not owned_outfits.has(equipped_outfit):
		equipped_outfit = "default"
	equipped_cards.clear()
	for ec in d.get("equipped_cards", []):
		equipped_cards.append(str(ec))
	vacation_used_years.clear()
	for vy in d.get("vacation_used_years", []):
		vacation_used_years.append(int(vy))
	var saved_goal: Variant = d.get("annual_goal", {})
	if typeof(saved_goal) == TYPE_DICTIONARY and not (saved_goal as Dictionary).is_empty():
		var sg: Dictionary = saved_goal
		annual_goal = {
			"year": int(sg.get("year", age)),
			"title": str(sg.get("title", "")),
			"metric": str(sg.get("metric", "max_big")),
			"target": int(sg.get("target", 165)),
			"completed": bool(sg.get("completed", false))
		}
	else:
		roll_annual_goal_for_year(age)

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
	var ginv: Dictionary = {}
	var saved_ginv: Variant = d.get("gifts_inventory", {})
	if typeof(saved_ginv) == TYPE_DICTIONARY:
		for gk in saved_ginv.keys():
			var cnt: int = maxi(0, int(saved_ginv[gk]))
			if cnt > 0:
				ginv[str(gk)] = cnt
	gifts_inventory = ginv
	var est: Dictionary = {"library": 1, "armory": 1, "conservatory": 1, "crucible": 1, "sanctum": 1, "treasury": 1}
	var saved_est: Variant = d.get("estate_levels", {})
	if typeof(saved_est) == TYPE_DICTIONARY:
		for k in saved_est.keys():
			est[str(k)] = clampi(int(saved_est[k]), 1, 8)
	estate_levels = est

	consumables_inventory.clear()
	var saved_cons: Variant = d.get("consumables_inventory", {})
	if typeof(saved_cons) == TYPE_DICTIONARY:
		for ck in saved_cons.keys():
			var cnt: int = maxi(0, int(saved_cons[ck]))
			if cnt > 0:
				consumables_inventory[str(ck)] = cnt
	owned_tomes.clear()
	for tk in d.get("owned_tomes", []):
		var tid: String = str(tk)
		if not CatalogDB.get_tome(tid).is_empty() and not owned_tomes.has(tid):
			owned_tomes.append(tid)
	owned_equipment.clear()
	for ek in d.get("owned_equipment", []):
		var eid: String = str(ek)
		if not CatalogDB.get_equipment(eid).is_empty() and not owned_equipment.has(eid):
			owned_equipment.append(eid)
	equipped_weapon = str(d.get("equipped_weapon", ""))
	if equipped_weapon != "" and not owned_equipment.has(equipped_weapon):
		equipped_weapon = ""
	equipped_accessory = str(d.get("equipped_accessory", ""))
	if equipped_accessory != "" and not owned_equipment.has(equipped_accessory):
		equipped_accessory = ""
	civic_investments.clear()
	for ik in d.get("civic_investments", []):
		var iid: String = str(ik)
		if not CatalogDB.get_civic_investment(iid).is_empty() and not civic_investments.has(iid):
			civic_investments.append(iid)

	recalculate_derived_stats()
	father_energy = clampi(int(d.get("father_energy", father_max_energy)), 0, father_max_energy)
	current_stamina = clampi(int(d.get("current_stamina", max_stamina)), 0, max_stamina)
	evaluate_psychological_traits()
	stats_updated.emit()
	gold_changed.emit(gold)
	seal_state_changed.emit(seal_integrity, human_anchor, abyssal_sync)
