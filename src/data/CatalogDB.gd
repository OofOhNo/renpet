extends Node

## Singleton CatalogDB - Base de datos modular (Fases 2, 4 y 5).
## Única fuente de verdad para: Actividades de Renpet, Tareas del Padre, Regímenes de dieta,
## Materiales del Crisol, Mutaciones, Sinergias de Prestigio y Micro-Eventos de rutina.
## Todo es dato puro: ninguna escena duplica números que vivan aquí.

## Factor de balance para las ganancias de atributos grandes (0-1200) de actividades y materiales de
## rutina. Con 144 bloques en la campaña, sin este factor un especialista llega al tope de 1200 hacia los
## 16 años; con 0.55 lo alcanza cerca del final (edad 19-20), que es lo que pide la Biblia.
const BIG_STAT_GAIN_SCALE: float = 0.55

# ==============================================================================
# ACTIVIDADES DE RENPET (3 bloques de 20 días por bimestre)
# category: class (cuesta oro) | job (paga oro) | rest (descanso)
# facility_bonus: mejora de la mansión que potencia la actividad (+4 por nivel sobre el 1)
# min_age: edad mínima para inscribirse | rival_id: rival presente en el aula/oficio
# ==============================================================================
const ACTIVITIES: Array[Dictionary] = [
	# --- CLASES (cuestan oro) ---
	{
		"id": "class_armory", "name": "Academia de Armas", "mentor": "Maestra Rivena",
		"category": "class", "cost_or_wage": -90, "min_age": 12,
		"stats": {"temple": 22, "destreza": 26, "gravedad": 10},
		"stress": 8, "seal_delta": 0, "rival_id": "vespera", "facility_bonus": "armory",
		"desc": "Esgrima imperial, lanza pesada y condicionamiento físico. Compites en el patio con Dama Vespera."
	},
	{
		"id": "class_astrolabe", "name": "Torre del Astrolabio", "mentor": "Archimago Thalor",
		"category": "class", "cost_or_wage": -100, "min_age": 12,
		"stats": {"erudicion": 26, "luminiscencia": 22, "resonancia": 18},
		"stress": 9, "seal_delta": 0, "rival_id": "soren", "facility_bonus": "library",
		"desc": "Cálculo de efemérides, canalización de luz astral y teoría del tiempo junto a Soren."
	},
	{
		"id": "class_conservatory", "name": "Conservatorio Real", "mentor": "Madame Isolde",
		"category": "class", "cost_or_wage": -95, "min_age": 12,
		"stats": {"gracia": 28, "magnetismo": 24, "human_anchor": 4},
		"stress": 7, "seal_delta": 0, "rival_id": "lyra", "facility_bonus": "conservatory",
		"desc": "Protocolo cortesano, danza de salón, arpa y diplomacia frente a la mirada crítica de Lady Lyra."
	},
	{
		"id": "class_sanctuary", "name": "Santuario de la Palma Celeste", "mentor": "Alta Matriarca Seraphina",
		"category": "class", "cost_or_wage": -70, "min_age": 12,
		"stats": {"luminiscencia": 20, "devocion": 10, "moralidad": 8},
		"stress": 5, "seal_delta": 3, "rival_id": "", "facility_bonus": "",
		"desc": "Meditación sagrada y cánticos antiguos que refuerzan +3% la Integridad del Sello Estelar."
	},

	# --- OFICIOS (generan oro) ---
	{
		"id": "job_sanatorium", "name": "Enfermería en el Sanatorio del Lirio", "mentor": "Doctora Helena",
		"category": "job", "cost_or_wage": 95, "min_age": 12, "urban": true,
		"stats": {"erudicion": 12, "moralidad": 8, "human_anchor": 6},
		"stress": 6, "seal_delta": 1, "rival_id": "", "facility_bonus": "",
		"desc": "Ayudar a la Doctora Helena a cuidar enfermos. Fortalece profundamente el Anclaje Humano."
	},
	{
		"id": "job_clockwork", "name": "Aprendiz en la Relojería Real", "mentor": "Maestro Baelor",
		"category": "job", "cost_or_wage": 130, "min_age": 13, "urban": true,
		"stats": {"erudicion": 18, "resonancia": 20, "destreza": 16},
		"stress": 8, "seal_delta": 1, "rival_id": "soren", "facility_bonus": "crucible",
		"desc": "Ingeniería de precisión y engranajes celestes. Paga bien y estabiliza el núcleo estelar."
	},
	{
		"id": "job_amphitheater", "name": "Recital en el Anfiteatro de Cristal", "mentor": "Mirari",
		"category": "job", "cost_or_wage": 140, "min_age": 12, "urban": true, "recital": true,
		"stats": {"gracia": 18, "magnetismo": 16, "human_anchor": 4},
		"stress": 7, "seal_delta": 0, "rival_id": "lyra", "facility_bonus": "conservatory",
		"desc": "Acompañar a Mirari con música y canto ante los ciudadanos de Aethelgard."
	},
	{
		"id": "job_caravan", "name": "Escolta de Caravanas del Cuarzo", "mentor": "Garrick 'Mano de Hierro'",
		"category": "job", "cost_or_wage": 165, "min_age": 13,
		"stats": {"temple": 18, "destreza": 16, "gravedad": 8},
		"stress": 11, "seal_delta": 0, "rival_id": "caelum", "facility_bonus": "armory",
		"loot_item": "comet_dust", "loot_chance": 25,
		"desc": "Proteger mercaderes en los caminos exteriores. Buena paga y probabilidad de hallar Polvo de Cometa."
	},
	{
		"id": "job_canals", "name": "Contrabando en los Canales de Mercurio", "mentor": "La Liga de Kaelen",
		"category": "job", "cost_or_wage": 225, "min_age": 14,
		"stats": {"destreza": 20, "entropia": 10, "abyssal_sync": 6, "moralidad": -6},
		"stress": 12, "seal_delta": -3, "rival_id": "caelum", "facility_bonus": "",
		"loot_item": "mercury_dew", "loot_chance": 25,
		"desc": "Tráfico nocturno de reliquias con la banda de Kaelen. Altísimo oro, pero erosiona -3% el Sello."
	},

	# --- DESCANSO Y VIDA TERRENAL ---
	{
		"id": "rest_manor", "name": "Reposo y Lectura en el Jardín Familiar", "mentor": "",
		"category": "rest", "cost_or_wage": 0, "min_age": 12,
		"stats": {"human_anchor": 5, "affection": 4},
		"stress": -22, "seal_delta": 1, "rival_id": "", "facility_bonus": "conservatory",
		"desc": "Descansar en casa sin presiones y fortalecer el vínculo familiar."
	},
	{
		"id": "rest_springs", "name": "Retiro en las Termas de Alabastro", "mentor": "",
		"category": "rest", "cost_or_wage": -80, "min_age": 12,
		"stats": {"temple": 10, "gracia": 10, "human_anchor": 6},
		"stress": -36, "seal_delta": 4, "rival_id": "", "facility_bonus": "",
		"desc": "Aguas termales ricas en minerales que alivian el estrés y restauran el Sello."
	}
]

# ==============================================================================
# DOBLE AGENCIA PATERNAL (100 puntos de Energía por bimestre)
# excludes: tareas incompatibles (el padre no puede estar en dos sitios)
# ==============================================================================
const FATHER_TASKS: Array[Dictionary] = [
	{
		"id": "hero_work", "name": "Oficio de Héroe", "icon": "⚔", "energy": 60,
		"excludes": ["supervise", "cook_home"],
		"summary": "Sales a cumplir contratos de antiguo Héroe: +260 Oro, pero te ausentas del hogar (-4 Afecto).",
		"gold": 260, "effects": {"affection": -4}
	},
	{
		"id": "supervise", "name": "Supervisar el Entrenamiento", "icon": "☥", "energy": 40,
		"excludes": ["hero_work"],
		"summary": "Acompañas a Renpet en cada bloque: +30% de eficacia en sus actividades y +5 de Afecto.",
		"effects": {"affection": 5}
	},
	{
		"id": "cook_home", "name": "Cocinar y Cuidar el Hogar", "icon": "❀", "energy": 30,
		"excludes": ["hero_work"],
		"summary": "Cocinas sus platos favoritos y cuidan juntos el jardín: -25 Estrés, +10 Anclaje Humano, +8 Afecto.",
		"effects": {"stress": -25, "human_anchor": 10, "affection": 8}
	},
	{
		"id": "investigate", "name": "Investigar el Origen Estelar", "icon": "✧", "energy": 50,
		"excludes": [],
		"summary": "Descifras archivos censurados sobre la caída de la estrella y su segundo latido: +15% de Indagación y +18 Resonancia.",
		"effects": {"seal_investigation": 15, "resonancia": 18}
	},
	{
		"id": "diplomacy", "name": "Tejer Diplomacia con Facciones", "icon": "⚖", "energy": 40,
		"excludes": [],
		"summary": "Visitas salones y gremios: +8 Reputación, +60 Oro en regalos de cortesía y descuentos en el bazar.",
		"gold": 60, "effects": {"father_reputation": 8}
	}
]

# ==============================================================================
# REGÍMENES DE DIETA (se cobran cada bimestre)
# ==============================================================================
const DIETS: Array[Dictionary] = [
	{
		"id": 0, "key": "austere", "name": "Dieta Austera", "icon": "❂", "cost": 30,
		"effects": {"stress": 4, "temple": -2},
		"desc": "Ahorro económico: +4 Estrés, -2 Temple."
	},
	{
		"id": 1, "key": "balanced", "name": "Mesa Casera del Héroe", "icon": "❀", "cost": 80,
		"effects": {"stress": -5, "human_anchor": 2},
		"desc": "Equilibrada: -5 Estrés, +2 Anclaje Humano."
	},
	{
		"id": 2, "key": "royal", "name": "Banquete Real de Corte", "icon": "♦", "cost": 180,
		"effects": {"stress": -15, "gracia": 8, "temple": 4},
		"desc": "Opulenta: -15 Estrés, +8 Gracia, +4 Temple."
	},
	{
		"id": 3, "key": "purge", "name": "Infusión de Lirio Estelar", "icon": "✿", "cost": 150,
		"effects": {"seal_integrity": 3},
		"saturation": -15,
		"desc": "Purificadora: -15 Saturación Astral y +3% Sello."
	}
]

# ==============================================================================
# SINERGIAS DE PRESTIGIO (umbrales duales de atributos)
# ==============================================================================
const PRESTIGE_SYNERGIES: Array[Dictionary] = [
	{"id": "horizon_valkyrie", "title": "Valquiria del Horizonte", "stat_a": "temple", "req_a": 240, "stat_b": "destreza", "req_b": 240,
		"bonus_desc": "+20% de rendimiento en actividades marciales y +15 puntos extra en el Torneo de Otoño."},
	{"id": "ephemeris_weaver", "title": "Tejedora de Efemérides", "stat_a": "erudicion", "req_a": 240, "stat_b": "resonancia", "req_b": 200,
		"bonus_desc": "+25% de eficacia en estudios astrales y desbloquea la carta 'Rebobinado Temporal'."},
	{"id": "alabaster_rose", "title": "Estrella de la Corte de Alabastro", "stat_a": "gracia", "req_a": 220, "stat_b": "magnetismo", "req_b": 220,
		"bonus_desc": "+30% de ingresos en recitales y gran ventaja diplomática con el Príncipe Cassian."},
	{"id": "mortal_beacon", "title": "Faro de Humanidad Inquebrantable", "stat_a": "human_anchor", "req_a": 85, "stat_b": "luminiscencia", "req_b": 200,
		"bonus_desc": "El amor terrenal protege su alma: regenera +2% de Sello Estelar cada bimestre."},
	{"id": "eclipse_sovereign", "title": "Domadora del Eclipse Interior", "stat_a": "abyssal_sync", "req_a": 45, "stat_b": "gravedad", "req_b": 180,
		"bonus_desc": "Pacto consciente con el eco de tus sueños: el Horno Astral otorga un +30% adicional de atributos."},
	{"id": "solar_artificer", "title": "Artífice del Reloj Solar", "stat_a": "destreza", "req_a": 210, "stat_b": "resonancia", "req_b": 210,
		"bonus_desc": "Maestría en engranajes celestes: transmutar cuesta menos y la Investigación del Sello rinde +15%."}
]

# Actividades que cuentan como "estudio astral" / "marcial" para los bonos de sinergia.
const ASTRAL_STUDY_IDS: Array[String] = ["class_astrolabe", "job_clockwork", "class_sanctuary"]
const MARTIAL_IDS: Array[String] = ["class_armory", "job_caravan"]

# ==============================================================================
# MATERIALES COSMICOS DEL HORNO ASTRAL
# saturation: Saturación Astral que genera asimilarlo | seal_delta: efecto sobre el Sello
# exclusive_rep: reputación paterna mínima para comprarlo en el bazar (0 = libre)
# ==============================================================================
const COSMIC_MATERIALS: Array[Dictionary] = [
	{
		"id": "comet_dust", "name": "Polvo de Cometa Plateado", "origin": "Arboleda de los Relojes", "price": 140,
		"stats": {"destreza": 30, "resonancia": 20}, "seal_delta": -2, "saturation": 14,
		"mutation": "paso_de_luz", "exclusive_rep": 0, "weight": 30
	},
	{
		"id": "quartz_marrow", "name": "Médula de Ciervo de Cuarzo", "origin": "Jefe de la Zona 1", "price": 170,
		"stats": {"temple": 45, "luminiscencia": 25}, "seal_delta": 0, "saturation": 8,
		"mutation": "pulso_cristalino", "exclusive_rep": 0, "weight": 22
	},
	{
		"id": "mercury_dew", "name": "Azogue de los Acueductos", "origin": "Canales de Mercurio", "price": 160,
		"stats": {"erudicion": 40, "gravedad": 30}, "seal_delta": -5, "saturation": 16,
		"mutation": "sangre_pesada", "exclusive_rep": 0, "weight": 25
	},
	{
		"id": "sarcophagus_shard", "name": "Esquirla del Relicario Negro", "origin": "Cráter del Lucero", "price": 260,
		"stats": {"gravedad": 60, "luminiscencia": 50, "abyssal_sync": 15}, "seal_delta": -12, "saturation": 28,
		"mutation": "voz_del_prisionero", "exclusive_rep": 0, "weight": 8
	},
	{
		"id": "melted_hourglass", "name": "Reloj de Arena Derretido", "origin": "Torre Invertida", "price": 240,
		"stats": {"resonancia": 70, "erudicion": 40}, "seal_delta": -8, "saturation": 22,
		"mutation": "paradoja_menor", "exclusive_rep": 0, "weight": 10
	},
	{
		"id": "goddess_tear", "name": "Lágrima de la Diosa Cautiva", "origin": "Reliquia del Padre", "price": 220,
		"stats": {"gracia": 40, "human_anchor": 25}, "seal_delta": 25, "saturation": 0,
		"mutation": "bendicion_del_tiempo", "exclusive_rep": 80, "weight": 5
	}
]

const MUTATIONS: Dictionary = {
	"paso_de_luz": {"name": "Paso de Luz", "desc": "Carta de combate: Evasión + robo de 2 cartas."},
	"pulso_cristalino": {"name": "Pulso Cristalino", "desc": "Regenera 8% de HP por turno en combate."},
	"sangre_pesada": {"name": "Sangre Pesada", "desc": "Inmunidad a empuje y venenos."},
	"voz_del_prisionero": {"name": "Eco del Espejo", "desc": "Despierta una voz enigmática en los sueños de Renpet."},
	"paradoja_menor": {"name": "Paradoja Menor", "desc": "Permite repetir el último ataque."},
	"bendicion_del_tiempo": {"name": "Bendición del Tiempo", "desc": "Ancla Sagrada: el Sello resiste mejor las asimilaciones."}
}

# Migración de partidas antiguas (nombres de mutación -> id)
const LEGACY_MUTATION_NAMES: Dictionary = {
	"Paso de Luz (Evasión Astral)": "paso_de_luz",
	"Pulso Cristalino (Regeneración)": "pulso_cristalino",
	"Sangre Pesada (Anti-Ruptura)": "sangre_pesada",
	"Voz del Eclipse (Llamado de Nyx-Aethel)": "voz_del_prisionero",
	"Paradoja Menor (Doble Turno)": "paradoja_menor",
	"Bendición del Tiempo (Ancla Sagrada)": "bendicion_del_tiempo"
}

# ==============================================================================
# MICRO-EVENTOS DE AULA Y OFICIO (Fase 4.3)
# Se eligen de forma determinista (semilla de partida + turno + bloque).
# requires: ids / category / trait_prefix / min_age / seal_below / stress_above
# Si el rasgo coincide se usa text_trait y se aplican effects_trait además de effects.
# ============================================================================== 
const MICRO_EVENTS: Array[Dictionary] = [
	{
		"id": "me_armory_unyielding", "title": "El Duelo del Patio", "weight": 3,
		"requires": {"ids": ["class_armory"]}, "trait_prefix": "Corazón Indómito",
		"text": "En el patio de armas, un alumno mayor reta a {D} a un asalto con espadas de madera. Ella acepta con nervios y termina pareja en el marcador.",
		"text_trait": "En el patio de armas, un alumno mayor reta a {D}. Corazón Indómito: ella no retrocede ni un paso y gana el asalto ante todos.",
		"effects": {"destreza": 6}, "effects_trait": {"temple": 8, "magnetismo": 6}
	},
	{
		"id": "me_astrolabe_cold", "title": "La Corrección del Archimago", "weight": 3,
		"requires": {"ids": ["class_astrolabe", "job_clockwork"]}, "trait_prefix": "Mente de Cristal Frío",
		"text": "El Archimago Thalor se equivoca en una efeméride y {D} duda si corregirlo. Termina callando y anotando el error en su cuaderno.",
		"text_trait": "El Archimago Thalor se equivoca en una efeméride. Con fría precisión, {D} lo corrige frente a toda la clase; él, encantado, olvida de qué hablaba.",
		"effects": {"erudicion": 5}, "effects_trait": {"erudicion": 12, "resonancia": 6}
	},
	{
		"id": "me_conservatory_home", "title": "La Danza Dedicada", "weight": 3,
		"requires": {"ids": ["class_conservatory", "job_amphitheater"]}, "trait_prefix": "Orgullo del Hogar",
		"text": "Madame Isolde pide una pieza libre. {D} baila con soltura, aunque sin demasiado alma.",
		"text_trait": "Madame Isolde pide una pieza libre. {D} baila pensando en su padre sentado en la última fila, y hasta Madame Isolde guarda su abanico para aplaudir.",
		"effects": {"gracia": 5}, "effects_trait": {"gracia": 10, "affection": 6}
	},
	{
		"id": "me_sanatorium_fever", "title": "Una Noche de Fiebre de Escoria", "weight": 4,
		"requires": {"ids": ["job_sanatorium"]},
		"text": "Llega al Sanatorio una familia del barrio bajo con los niños ardiendo en fiebre. {D} ayuda a la Doctora Helena toda la noche, sin que nadie le pida nada.",
		"effects": {"human_anchor": 6, "moralidad": 4, "stress": 3}
	},
	{
		"id": "me_caravan_ambush", "title": "Emboscada en el Camino de Cuarzo", "weight": 3,
		"requires": {"ids": ["job_caravan"]}, "trait_prefix": "Corazón Indómito",
		"text": "Unos bandidos tantean la caravana. {D} da la voz de alarma y se atrinchera junto al carro hasta que se retiran.",
		"text_trait": "Unos bandidos tantean la caravana. Corazón Indómito: {D} sale a su encuentro y los dispersa, y el mercader le añade una propina.",
		"effects": {"destreza": 5, "stress": 3}, "effects_trait": {"temple": 8, "gold": 40}
	},
	{
		"id": "me_canals_raid", "title": "Redada de la Guardia Ducal", "weight": 3,
		"requires": {"ids": ["job_canals"]},
		"text": "La guardia irrumpe en los canales. {D} escapa por un tejado, con el corazón desbocado y la sensación de que ya no puede volver a hacerlo.",
		"effects": {"destreza": 4, "entropia": 3, "stress": 6}
	},
	{
		"id": "me_rest_dream", "title": "El Espejo de Agua", "weight": 3,
		"requires": {"category": "rest", "min_age": 15, "seal_below": 70},
		"text": "En las aguas quietas, {D} ve su reflejo cambiar un instante: ojos de eclipse que sonríen con tristeza. No siente miedo, solo curiosidad.",
		"effects": {"abyssal_sync": 5, "resonancia": 5}
	},
	{
		"id": "me_rest_father", "title": "Té al Atardecer", "weight": 3,
		"requires": {"category": "rest"},
		"text": "{D} encuentra a su padre leyendo en el jardín y se sienta a su lado sin decir nada. Es el mejor rato de la semana.",
		"effects": {"affection": 4, "human_anchor": 3}
	},
	{
		"id": "me_sanctuary_matriarch", "title": "La Mirada de la Matriarca", "weight": 3,
		"requires": {"ids": ["class_sanctuary"]},
		"text": "La Alta Matriarca Seraphina observa a {D} durante el cántico más tiempo del necesario. Al terminar le dice que tiene 'una luz especial'. A {D} le queda un escalofrío.",
		"effects": {"devocion": 5, "stress": 3}
	},
	{
		"id": "me_insomnia_whispers", "title": "Susurros de Madrugada", "weight": 4,
		"requires": {"category": "any", "seal_below": 50, "stress_above": 65}, "trait_prefix": "Insomnio de las Estrellas",
		"text": "Apenas ha dormido. {D} oye murmullos del cosmos mientras trabaja y comete un par de errores tontos.",
		"text_trait": "Insomnio de las Estrellas: los murmullos del cosmos se vuelven claros durante un instante y {D} intuye algo que nadie le enseñó.",
		"effects": {"stress": 4}, "effects_trait": {"resonancia": 8, "entropia": 3}
	},
	{
		"id": "me_class_exam", "title": "Examen Sorpresa", "weight": 4,
		"requires": {"category": "class"},
		"text": "El maestro anuncia un examen sorpresa. {D} se queda despierta repasando la noche anterior y lo aprueba con buena nota.",
		"effects": {"erudicion": 3, "stress": 2}
	},
	{
		"id": "me_job_tip", "title": "Una Propina Inesperada", "weight": 3,
		"requires": {"category": "job"},
		"text": "Un cliente agradecido deja una propina generosa a {D}. Ella la guarda para la casa.",
		"effects": {"gold": 35}
	}
]

# ==============================================================================
# CONSULTAS
# ==============================================================================
func get_activity(act_id: String) -> Dictionary:
	for a in ACTIVITIES:
		if a["id"] == act_id:
			return a
	push_warning("CatalogDB: actividad desconocida '%s'" % act_id)
	return {}

func get_activities_for_age(age: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for a in ACTIVITIES:
		if age >= int(a.get("min_age", 12)):
			result.append(a)
	return result

func get_father_task(task_id: String) -> Dictionary:
	for t in FATHER_TASKS:
		if t["id"] == task_id:
			return t
	return {}

func get_diet(diet_id: int) -> Dictionary:
	for d in DIETS:
		if int(d["id"]) == diet_id:
			return d
	return DIETS[1]

func get_material(mat_id: String) -> Dictionary:
	for m in COSMIC_MATERIALS:
		if m["id"] == mat_id:
			return m
	return {}

func get_mutation(mut_id: String) -> Dictionary:
	return MUTATIONS.get(mut_id, {})

func get_mutation_name(mut_id: String) -> String:
	return str(MUTATIONS.get(mut_id, {}).get("name", mut_id))

func get_synergy(syn_id: String) -> Dictionary:
	for s in PRESTIGE_SYNERGIES:
		if s["id"] == syn_id:
			return s
	return {}

func check_and_unlock_synergies() -> Array[Dictionary]:
	var newly_unlocked: Array[Dictionary] = []
	for syn in PRESTIGE_SYNERGIES:
		var syn_id: String = syn["id"]
		if GameState.unlocked_synergies.has(syn_id):
			continue
		if GameState.get_stat(syn["stat_a"]) >= int(syn["req_a"]) and GameState.get_stat(syn["stat_b"]) >= int(syn["req_b"]):
			GameState.unlocked_synergies.append(syn_id)
			newly_unlocked.append(syn)
			Chronicle.record_event("synergy_" + syn_id, "¡Sinergia de Prestigio Despertada!",
				"%s obtuvo el título '%s': %s" % [GameState.daughter_name, syn["title"], syn["bonus_desc"]], "prestige", 5)
	return newly_unlocked
