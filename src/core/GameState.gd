extends Node

## Singleton GameState - Estado maestro de Renpet, el Padre (Héroe), el Sello Estelar y el Horno Astral.

signal stats_updated()
signal seal_state_changed(seal_integrity: int, human_anchor: int, abyssal_sync: int)
signal traits_updated(active_traits: Array[String])
signal gold_changed(new_gold: int)
signal log_added(message: String, category: String)

enum HeroArchetype {
	MARTIAL,  # El Filo del Vértice (+Temple/Destreza inicial, mandoble ancestral)
	SCHOLAR,  # El Archimago del Velo (+Erudición/Resonancia, biblioteca familiar)
	ROGUE,    # El Infiltrador del Silencio (+Oro inicial, contactos en canales, evasión)
	DEVOUT    # El Custodio del Altar Caído (+Anclaje Humano, serenidad, resistencia al estrés)
}

enum DietPlan {
	AUSTERE,      # Dieta Austera (Coste: 30 G | +3 Estrés, -2 Temple)
	BALANCED,     # Mesa Casera del Héroe (Coste: 80 G | -5 Estrés, +2 Anclaje Humano)
	ROYAL_FEAST,  # Banquete de Corte (Coste: 180 G | -15 Estrés, +8 Gracia, +4 Temple)
	ASTRAL_PURGE  # Infusión de Lirio Estelar (Coste: 150 G | Purifica -15 Saturación y +3% Sello)
}

# --- IDENTIDAD Y PERFIL ---
var daughter_name: String = "Renpet"
var age: int = 12
var father_name: String = "Aurelius"
var father_archetype: HeroArchetype = HeroArchetype.MARTIAL

# --- ESFERA MORTAL / HUMANA (0 a 1200) ---
var temple: int = 130         # Vigor físico, salud, aguante
var destreza: int = 120       # Agilidad, esgrima, precisión
var erudicion: int = 135      # Ciencia, lógica, historia, estrategia
var gracia: int = 105         # Elegancia cortesana, danza, arte
var magnetismo: int = 100     # Carisma, liderazgo, elocuencia

# --- ESFERA CÓSMICA / ESTELAR (0 a 1200) ---
var luminiscencia: int = 110  # Magia de luz estelar, curación
var gravedad: int = 90        # Impacto pesado, control de masa
var resonancia: int = 100     # Percepción del tiempo y ecos del pasado
var entropia: int = 5         # Afinidad con el vacío (0 a 100)

# --- EJE MORAL Y ESPIRITUAL (0 a 100) ---
var moralidad: int = 60
var devocion: int = 50

# --- LOS 3 MEDIDORES NUCLEARES DEL TWIST ("LA ESTRELLA ERA UNA PRISIÓN") ---
var human_anchor: int = 70    # Anclaje Humano (0 a 100): Arraigo mortal, amor y empatía
var seal_integrity: int = 92  # Integridad del Sello (100% a 0%): Cadenas que contienen a Nyx-Aethel
var abyssal_sync: int = 10    # Sincronía con el Prisionero (0 a 100): Comprensión de Zephyr/Nyx-Aethel

# --- ESTADO VITAL Y RECURSOS FAMILIARES ---
var stress: int = 15          # Estrés acumulado (0 a 100)
var max_stamina: int = 330
var current_stamina: int = 330
var affection: int = 75       # Vínculo filial con el Padre (0 a 100)
var gold: int = 850           # Oro de la casa
var current_diet: DietPlan = DietPlan.BALANCED

# --- ESTADO DEL PADRE (DOBLE AGENCIA) ---
var father_max_energy: int = 100
var father_energy: int = 100
var father_reputation: int = 60
var seal_investigation_progress: int = 0 # 0 a 100%: Clave para descubrir la mentira de la Diosa

# --- HORNO DE FUSIÓN ASTRAL (HERENCIA DRAPLINE) & INVENTARIO ---
var astral_saturation: int = 0 # Toxicidad cósmica temporal (0 a 100)
var active_mutations: Array[String] = []
var unlocked_synergies: Array[String] = []
var memory_shards_found: int = 0 # 0 a 5 Esquirlas de las regiones de exploración

# Inventario de materiales cósmicos disponibles (id -> cantidad)
var materials_inventory: Dictionary = {
	"comet_dust": 2,
	"quartz_marrow": 1,
	"mercury_dew": 1,
	"sarcophagus_shard": 0,
	"melted_hourglass": 0,
	"goddess_tear": 1
}

# Mejoras de la Mansión (Nivel 1 a 5)
var estate_levels: Dictionary = {
	"library": 1,      # Biblioteca Astral (+Erudición/Resonancia)
	"armory": 1,       # Patio de Armas (+Temple/Destreza)
	"conservatory": 1, # Salón de Música y Té (-Estrés pasivo, +Gracia)
	"crucible": 1      # Taller del Horno Astral (-Saturación al asimilar)
}

# Rasgos Psicológicos Activos (Motor Determinista sin IA)
var active_traits: Array[String] = []

func _ready() -> void:
	recalculate_derived_stats()
	evaluate_psychological_traits()

func apply_archetype_bonuses(arch: HeroArchetype) -> void:
	# Restablecer base limpia antes de aplicar el arquetipo elegido en el Prólogo
	temple = 130
	destreza = 120
	erudicion = 135
	gracia = 105
	magnetismo = 100
	luminiscencia = 110
	gravedad = 90
	resonancia = 100
	human_anchor = 70
	devocion = 50
	stress = 15
	gold = 850
	father_reputation = 60
	seal_investigation_progress = 0
	
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
	recalculate_derived_stats()
	evaluate_psychological_traits()

func get_archetype_title() -> String:
	match father_archetype:
		HeroArchetype.MARTIAL: return "El Filo del Vértice (Héroe Marcial)"
		HeroArchetype.SCHOLAR: return "El Archimago del Velo (Héroe Sabio)"
		HeroArchetype.ROGUE: return "El Infiltrador del Silencio (Héroe de Sombras)"
		HeroArchetype.DEVOUT: return "El Custodio del Altar (Héroe Devoto)"
	return "Héroe de Aethelgard"

func recalculate_derived_stats() -> void:
	max_stamina = 200 + int(temple * 1.2)
	current_stamina = clampi(current_stamina, 0, max_stamina)
	stats_updated.emit()

func modify_stat(stat_key: String, delta: int) -> void:
	if delta == 0:
		return
	match stat_key:
		"temple": temple = clampi(temple + delta, 0, 1200)
		"destreza": destreza = clampi(destreza + delta, 0, 1200)
		"erudicion": erudicion = clampi(erudicion + delta, 0, 1200)
		"gracia": gracia = clampi(gracia + delta, 0, 1200)
		"magnetismo": magnetismo = clampi(magnetismo + delta, 0, 1200)
		"luminiscencia": luminiscencia = clampi(luminiscencia + delta, 0, 1200)
		"gravedad": gravedad = clampi(gravedad + delta, 0, 1200)
		"resonancia": resonancia = clampi(resonancia + delta, 0, 1200)
		"entropia": entropia = clampi(entropia + delta, 0, 100)
		"moralidad": moralidad = clampi(moralidad + delta, 0, 100)
		"devocion": devocion = clampi(devocion + delta, 0, 100)
		"stress": stress = clampi(stress + delta, 0, 100)
		"affection": affection = clampi(affection + delta, 0, 100)
		"human_anchor": human_anchor = clampi(human_anchor + delta, 0, 100)
		"seal_integrity": seal_integrity = clampi(seal_integrity + delta, 0, 100)
		"abyssal_sync": abyssal_sync = clampi(abyssal_sync + delta, 0, 100)
		"seal_investigation": seal_investigation_progress = clampi(seal_investigation_progress + delta, 0, 100)
	recalculate_derived_stats()
	evaluate_psychological_traits()
	seal_state_changed.emit(seal_integrity, human_anchor, abyssal_sync)

func modify_gold(delta: int) -> bool:
	if gold + delta < 0:
		return false
	gold += delta
	gold_changed.emit(gold)
	stats_updated.emit()
	return true

## Evalúa de forma 100% determinista los Rasgos Psicológicos y Sinergias de Renpet
func evaluate_psychological_traits() -> void:
	active_traits.clear()
	
	if affection >= 75 and human_anchor >= 70:
		active_traits.append("Orgullo del Hogar (Devota al Padre)")
	if erudicion >= 220 and affection < 50:
		active_traits.append("Mente de Cristal Frío (Analítica)")
	if seal_integrity < 60 and abyssal_sync >= 30:
		active_traits.append("Ojos de Eclipse (Escucha a Zephyr)")
	if stress >= 70:
		active_traits.append("Insomnio de las Estrellas (Agotada)")
	if temple >= 200 and destreza >= 180:
		active_traits.append("Corazón Indómito (Competitiva)")
	if gracia >= 180 and magnetismo >= 180:
		active_traits.append("Rosa de Alabastro (Favorita de la Corte)")
	if entropia >= 40 and human_anchor < 45:
		active_traits.append("Rencor del Sarcófago (Rebelde)")
		
	if active_traits.is_empty():
		active_traits.append("Lucero Curioso (En Formación)")
		
	traits_updated.emit(active_traits)

## Devuelve el estado metafísico actual del Twist de la Estrella-Prisión
func get_metaphysical_state_title() -> String:
	if seal_integrity <= 20 and human_anchor < 40:
		return "CRÍTICO: Despertar del Eclipse Devorador"
	elif seal_integrity < 55 and human_anchor >= 70:
		return "SIMBIOSIS: Domando al Prisionero con Amor Humano"
	elif seal_integrity >= 70 and human_anchor >= 65:
		return "ESTABLE: Corazón Mortal Luminoso"
	elif seal_integrity >= 70 and human_anchor < 40:
		return "FRÍO: Vasija Obediente de la Diosa"
	return "RESONANTE: Fluctuación entre Estrella y Humana"

## Genera un saludo dinámico en personaje 100% determinista según edad, estrés, afecto y sello
func get_dynamic_manor_greeting() -> String:
	if stress >= 75:
		return "\"Padre... me pesan los párpados y siento un zumbido constante dentro del pecho. ¿Podríamos descansar un poco este mes?\""
	if seal_integrity < 50 and abyssal_sync >= 40:
		return "\"Anoche volví a ver a ese chico de ojos de eclipse en mis sueños, Padre. Dice que la Diosa nos mintió a los dos... pero mientras tú estés conmigo, no tengo miedo.\""
	if age >= 17 and seal_investigation_progress >= 60:
		return "\"He estado leyendo tus notas sobre el templo antiguo. Sea lo que sea que encerraron dentro de mí cuando nací, juro que no dejaré que nos separe.\""
	if affection >= 80 and human_anchor >= 75:
		return "\"¡Bienvenido a casa, Padre! He preparado té caliente antes de repasar mis lecciones. Me alegra tanto que cenemos juntos hoy.\""
	if temple >= 250 and destreza >= 220:
		return "\"He estado practicando la postura de corte en el patio. Si Dama Vespera cree que me vencerá en el próximo Festival, se llevará una sorpresa.\""
	if erudicion >= 250:
		return "\"Las efemérides de la Torre del Astrolabio tenían un error de cálculo en la tercera luna; Soren y yo pasamos toda la tarde corrigiéndolo.\""
	return "\"Buenos días, Padre. El cielo de Aethelgard brilla con claridad hoy. ¿Qué planes tenemos para este bimestre?\""
