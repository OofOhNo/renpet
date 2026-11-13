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
		"desc": "Meditación sagrada y cánticos antiguos que refuerzan +3% la armonía interior de su estrella."
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
		"desc": "Tráfico nocturno de reliquias con la banda de Kaelen. Altísimo oro, pero erosiona -3% su equilibrio astral."
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
		"desc": "Aguas termales ricas en minerales que alivian el estrés y estabilizan la luz interior."
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
		"summary": "Sales a cumplir contratos de antiguo Héroe: +260 Oro, pero te ausentas del hogar (-4 Afecto, +Inquieta).",
		"gold": 260, "effects": {"affection": -4, "mood_calm": 8}
	},
	{
		"id": "supervise", "name": "Supervisar el Entrenamiento", "icon": "☥", "energy": 40,
		"excludes": ["hero_work"],
		"summary": "Acompañas a Renpet en cada bloque: +30% de eficacia en sus actividades, +5 Afecto y +Serena.",
		"effects": {"affection": 5, "mood_calm": -6}
	},
	{
		"id": "cook_home", "name": "Cocinar y Cuidar el Hogar", "icon": "❀", "energy": 30,
		"excludes": ["hero_work"],
		"summary": "Cocinas sus platos favoritos y cuidan juntos el jardín: -25 Estrés, +10 Anclaje Humano, +8 Afecto (+Serena y Empática).",
		"effects": {"stress": -25, "human_anchor": 10, "affection": 8, "mood_calm": -8, "mood_pride": -10}
	},
	{
		"id": "investigate", "name": "Investigar el Origen Estelar", "icon": "✧", "energy": 50,
		"excludes": [],
		"summary": "Descifras archivos censurados sobre la caída de la estrella y su segundo latido: +15% Indagación y +18 Resonancia.",
		"effects": {"seal_investigation": 15, "resonancia": 18}
	},
	{
		"id": "diplomacy", "name": "Tejer Diplomacia con Facciones", "icon": "⚖", "energy": 40,
		"excludes": [],
		"summary": "Visitas salones y gremios: +8 Reputación, +60 Oro, descuentos en el bazar y -22 Sospecha del Senado.",
		"gold": 60, "effects": {"father_reputation": 8, "court_suspicion": -22, "mood_pride": 8}
	}
]

# ==============================================================================
# REGÍMENES DE DIETA (se cobran cada bimestre)
# ==============================================================================
const DIETS: Array[Dictionary] = [
	{
		"id": 0, "key": "austere", "name": "Dieta Austera", "icon": "☀", "cost": 30,
		"effects": {"stress": 4, "temple": -2, "mood_calm": 8, "mood_pride": -4},
		"desc": "Ahorro económico: +4 Estrés, -2 Temple (+Inquieta)."
	},
	{
		"id": 1, "key": "balanced", "name": "Mesa Casera del Héroe", "icon": "❀", "cost": 80,
		"effects": {"stress": -5, "human_anchor": 2, "mood_calm": -6, "mood_pride": -6},
		"desc": "Equilibrada: -5 Estrés, +2 Anclaje Humano (+Serena y Empática)."
	},
	{
		"id": 2, "key": "royal", "name": "Banquete Real de Corte", "icon": "♦", "cost": 180,
		"effects": {"stress": -15, "gracia": 8, "temple": 4, "mood_pride": 12},
		"desc": "Opulenta: -15 Estrés, +8 Gracia, +4 Temple (+Arrogante)."
	},
	{
		"id": 3, "key": "purge", "name": "Infusión de Lirio Estelar", "icon": "❀", "cost": 150,
		"effects": {"seal_integrity": 3, "mood_calm": -12},
		"saturation": -15,
		"desc": "Purificadora: -15 Saturación Astral, +3% Armonía Estelar (+Serena)."
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
		"bonus_desc": "El amor terrenal protege su alma: regenera +2% de Armonía Estelar cada bimestre."},
	{"id": "eclipse_sovereign", "title": "Domadora del Eclipse Interior", "stat_a": "abyssal_sync", "req_a": 45, "stat_b": "gravedad", "req_b": 180,
		"bonus_desc": "Pacto consciente con el eco de tus sueños: el Horno Astral otorga un +30% adicional de atributos."},
	{"id": "solar_artificer", "title": "Artífice del Reloj Solar", "stat_a": "destreza", "req_a": 210, "stat_b": "resonancia", "req_b": 210,
		"bonus_desc": "Maestría en engranajes celestes: transmutar cuesta menos y las pesquisas sobre tu origen rinden +15%."}
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
		"id": "sarcophagus_shard", "name": "Fragmento de Obsidiana Antiguo", "origin": "Cráter del Lucero", "price": 260,
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
	"paso_de_luz": {"name": "Paso de Luz", "desc": "Combate: 18% de evasión y +15 Escudo/turno. Mundo: evita toda Sospecha en los Canales y abre atajos furtivos en expediciones."},
	"pulso_cristalino": {"name": "Pulso Cristalino", "desc": "Combate: regenera 8% HP/turno. Mundo: +15% en Astrolabio/Relojería y atajos arcanos en expediciones."},
	"sangre_pesada": {"name": "Sangre Pesada", "desc": "Combate: +40 HP máx. y -15% daño recibido. Mundo: reduce a la mitad el estrés de oficios duros (caravana/canales), pero genera recelo (-10%) en Conservatorio."},
	"voz_del_prisionero": {"name": "Eco del Espejo", "desc": "Combate: +20% daño al Desatar el Fulgor. Mundo: abre visiones nocturnas en el Espejo y revela opciones ocultas."},
	"paradoja_menor": {"name": "Paradoja Menor", "desc": "Combate: 4 PA máximos por turno. Mundo: otorga +25 de Energía Paternal (125 total) cada bimestre y +12% hallazgos."},
	"bendicion_del_tiempo": {"name": "Bendición del Tiempo", "desc": "Combate: +1 PA en el turno 1. Mundo: resiste mejor la saturación del Crisol y protege tu Armonía."}
}

# ==============================================================================
# BOUTIQUE DE AETHELGARD (ATUENDOS COMPRABLES Y EQUIPABLES)
# ==============================================================================
const OUTFITS: Array[Dictionary] = [
	{
		"id": "default", "name": "Túnica Familiar del Observatorio", "price": 0,
		"portrait": "res://assets/art/renpet_portrait.png",
		"tag": "Cotidiano",
		"bonus_desc": "Prenda cómoda del hogar que evoluciona visualmente en cada Acto (12, 15 y 18 años).",
		"mods": {}
	},
	{
		"id": "solar", "name": "Uniforme Solar de Justa", "price": 140,
		"portrait": "res://assets/art/renpet_outfit_solar.png",
		"tag": "Marcial y Justa",
		"bonus_desc": "+14% rendimiento marcial, +12% daño en combate y +30 pts en pruebas físicas del Festival.",
		"mods": {"martial_pct": 0.14, "combat_atk_pct": 0.12, "festival_blades": 30}
	},
	{
		"id": "astronomer", "name": "Túnica de Astrónoma Real", "price": 180,
		"portrait": "res://assets/art/renpet_outfit_astronomer.png",
		"tag": "Erudición y Crisol",
		"bonus_desc": "+16% en estudios astrales, -20% Saturación en el Crisol y +30 pts en duelos de Astrolabio.",
		"mods": {"astral_pct": 0.16, "sat_reduction": 0.20, "festival_astro": 30}
	},
	{
		"id": "gala", "name": "Gala Real de Alabastro", "price": 220,
		"portrait": "res://assets/art/renpet_outfit_gala.png",
		"tag": "Corte y Diplomacia",
		"bonus_desc": "+18% en Conservatorio/Recitales, -5 Sospecha del Senado por bimestre y +35 pts en Justa de Gala.",
		"mods": {"court_pct": 0.18, "suspicion_relief": 5, "festival_gala": 35}
	},
	{
		"id": "horizon", "name": "Cota del Horizonte", "price": 260,
		"portrait": "res://assets/art/renpet_outfit_horizon.png",
		"tag": "Expedición y Aguante",
		"bonus_desc": "+60 HP máx., +35 Escudo inicial en expediciones y -25% Estrés en trabajos duros.",
		"mods": {"combat_hp": 60, "combat_shield": 35, "job_stress_red": 0.25}
	}
]

# ==============================================================================
# VACACIONES ESTACIONALES ILUSTRADAS (BIMESTRES 3 Y 5)
# ==============================================================================
const VACATION_RETREATS: Dictionary = {
	3: {
		"id": "amber_coast", "bimester": 3, "name": "Retiro en la Costa de Ámbar (Verano)",
		"cost": 130, "energy": 35, "stress": -34, "human_anchor": 10, "affection": 9, "mood_calm": -18,
		"stat_key": "gracia", "stat_val": 14,
		"bg": "res://assets/art/bg_vacation_amber.png",
		"desc": "Un viaje de diez días entre columnatas bañadas por el sol y olas turquesa: -34 Estrés, +10 Anclaje Humano, +9 Afecto y +14 Gracia."
	},
	5: {
		"id": "boreal_obs", "bimester": 5, "name": "Retiro en el Observatorio Boreal (Invierno)",
		"cost": 150, "energy": 35, "stress": -30, "human_anchor": 8, "affection": 8, "mood_calm": -15,
		"stat_key": "resonancia", "stat_val": 18, "seal_delta": 5,
		"bg": "res://assets/art/bg_vacation_boreal.png",
		"desc": "Cúpulas nevadas bajo la aurora boreal y té caliente frente al firmamento: -30 Estrés, +8 Anclaje, +18 Resonancia y +5% Armonía."
	}
}

# ==============================================================================
# OBSEQUIOS DE AETHELGARD (COMPRABLES EN TIENDAS DEL MAPA PARA CANDIDATOS)
# ==============================================================================
const GIFTS: Array[Dictionary] = [
	{"id": "quartz_lens", "name": "Lente de Cuarzo Tallado", "price": 45, "shop": "aqueducts",
		"desc": "Óptica de precisión para observar astros o mecanismos.", "favs": ["soren", "mirari"]},
	{"id": "star_candy", "name": "Confitura de Miel Estelar", "price": 38, "shop": "aqueducts",
		"desc": "Dulce artesanal muy apreciado entre aprendices y centinelas.", "favs": ["kaelen", "vespera", "zephyr"]},
	{"id": "herbal_elixir", "name": "Infusión de Lirio Plateado", "price": 50, "shop": "aqueducts",
		"desc": "Tisana calmante contra el frío nocturno.", "favs": ["kaelen", "soren"]},
	{"id": "silver_rose", "name": "Rosa Filigranada de Plata", "price": 75, "shop": "palace",
		"desc": "Distinción refinada de la orfebrería imperial.", "favs": ["vespera", "cassian"]},
	{"id": "silk_poetry", "name": "Cantoral Iluminado en Seda", "price": 62, "shop": "palace",
		"desc": "Versos y partituras encuadernadas con hilo dorado.", "favs": ["mirari", "soren", "zephyr"]},
	{"id": "brass_compass", "name": "Brújula Solar de Bolsillo", "price": 68, "shop": "palace",
		"desc": "Instrumento noble de orientación y estrategia.", "favs": ["cassian", "vespera"]}
]

# ==============================================================================
# CARTAS DE RECUERDO Y HABILIDADES DE VÍNCULO (EQUIPABLES EN COMBATE Y FESTIVAL)
# unlock: trait:<prefijo> | shard:<id> | bond:<npc_id>:<stage>
# ==============================================================================
const MEMORY_CARDS: Array[Dictionary] = [
	{"id": "mem_hearth_vow", "name": "Juramento de la Chimenea", "unlock": "trait:Orgullo del Hogar",
		"source_label": "Rasgo: Orgullo del Hogar", "ap": 1, "kind": "defense", "fest_bonus": 26,
		"desc": "+60 Escudo Astral, +45 HP y +25% al siguiente ataque."},
	{"id": "mem_indomitable", "name": "Carga Indómita", "unlock": "trait:Corazón Indómito",
		"source_label": "Rasgo: Corazón Indómito", "ap": 1, "kind": "attack", "fest_bonus": 34,
		"desc": "Inflige 95 + (Temple×0.38) daño y +38 de Quiebre."},
	{"id": "mem_eclipse_eyes", "name": "Mirada del Espejo", "unlock": "trait:Ojos de Eclipse",
		"source_label": "Rasgo: Ojos de Eclipse", "ap": 1, "kind": "magic", "fest_bonus": 26,
		"desc": "Inflige 88 + (Gravedad×0.36) daño directo y +4% Sincronía."},
	{"id": "mem_crystal_mind", "name": "Cálculo Cero", "unlock": "trait:Mente de Cristal Frío",
		"source_label": "Rasgo: Mente de Cristal Frío", "ap": 0, "kind": "utility", "fest_bonus": 32,
		"desc": "0 PA: otorga +1 PA inmediato y +35 de Quiebre al enemigo."},
	{"id": "mem_alabaster_rose", "name": "Elegancia de Alabastro", "unlock": "trait:Rosa de Alabastro",
		"source_label": "Rasgo: Rosa de Alabastro", "ap": 1, "kind": "defense", "fest_bonus": 40,
		"desc": "+80 Escudo Astral, +35 daño armónico y reduce estrés tras el duelo."},
	{"id": "mem_insomnia_echo", "name": "Vigilia de Medianoche", "unlock": "trait:Insomnio de las Estrellas",
		"source_label": "Rasgo: Insomnio de las Estrellas", "ap": 0, "kind": "magic", "fest_bonus": 22,
		"desc": "0 PA: sacrifica 8% HP propio a cambio de +2 PA y 60 daño."},
	{"id": "mem_shard_1", "name": "Recuerdo: El Ciervo de Oro", "unlock": "shard:shard_1",
		"source_label": "Vestigio I (Arboleda)", "ap": 1, "kind": "defense", "fest_bonus": 24,
		"desc": "+55 Escudo, +50 HP y limpia un asalto duro."},
	{"id": "mem_shard_2", "name": "Recuerdo: Azogue Vivo", "unlock": "shard:shard_2",
		"source_label": "Vestigio II (Acueducto)", "ap": 1, "kind": "magic", "fest_bonus": 28,
		"desc": "75 + (Resonancia×0.38) daño y +25 Escudo."},
	{"id": "mem_shard_3", "name": "Recuerdo: Arena Cantante", "unlock": "shard:shard_3",
		"source_label": "Vestigio III (Desierto)", "ap": 1, "kind": "attack", "fest_bonus": 30,
		"desc": "105 + (Destreza×0.40) daño y +30 de Quiebre."},
	{"id": "mem_shard_4", "name": "Recuerdo: Eslabón Dorado", "unlock": "shard:shard_4",
		"source_label": "Vestigio IV (Cráter)", "ap": 2, "kind": "magic", "fest_bonus": 36,
		"desc": "2 PA: 165 + (Gravedad×0.55) daño sísmico y +50 de Quiebre."},
	{"id": "mem_shard_5", "name": "Síntesis de Aethel", "unlock": "shard:shard_5",
		"source_label": "Vestigio V (Observatorio)", "ap": 1, "kind": "utility", "fest_bonus": 46,
		"desc": "Armonía Suprema: +1 PA, +80 HP, +80 Escudo y +90 daño radiante."},
	{"id": "mem_bond_soren", "name": "Astrolabio de Soren", "unlock": "bond:soren:2",
		"source_label": "Vínculo Soren (Etapa 2+)", "ap": 1, "kind": "magic", "fest_bonus": 30,
		"desc": "Ecuación precisa: 90 + (Erudición×0.40) daño y +36 Quiebre."},
	{"id": "mem_bond_vespera", "name": "Voto de Acero de Vespera", "unlock": "bond:vespera:2",
		"source_label": "Vínculo Vespera (Etapa 2+)", "ap": 1, "kind": "attack", "fest_bonus": 34,
		"desc": "Doble estocada: 110 + (Temple×0.42) daño y +25 Quiebre."},
	{"id": "mem_bond_kaelen", "name": "Llave de los Canales", "unlock": "bond:kaelen:2",
		"source_label": "Vínculo Kaelen (Etapa 2+)", "ap": 1, "kind": "utility", "fest_bonus": 26,
		"desc": "Emboscada ágil: 80 + (Destreza×0.36) daño, +30 Escudo y +45 Oro."},
	{"id": "mem_bond_cassian", "name": "Edicto Solar de Cassian", "unlock": "bond:cassian:2",
		"source_label": "Vínculo Cassian (Etapa 2+)", "ap": 1, "kind": "defense", "fest_bonus": 38,
		"desc": "Mandato real: +75 Escudo y 80 + (Magnetismo×0.35) daño."},
	{"id": "mem_bond_mirari", "name": "Nocturno de Mirari", "unlock": "bond:mirari:2",
		"source_label": "Vínculo Mirari (Etapa 2+)", "ap": 1, "kind": "defense", "fest_bonus": 38,
		"desc": "Melodía sanadora: +95 HP, +55 Escudo y +2% Sello."},
	{"id": "mem_bond_zephyr", "name": "Espejo Nocturno", "unlock": "bond:zephyr:2",
		"source_label": "Vínculo del Espejo (Etapa 2+)", "ap": 1, "kind": "magic", "fest_bonus": 36,
		"desc": "Fuego dual: 115 + (Resonancia×0.48) daño sin dañar tu armonía."}
]

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

func get_outfit(outfit_id: String) -> Dictionary:
	for o in OUTFITS:
		if o["id"] == outfit_id:
			return o
	return OUTFITS[0]

func get_vacation_for_bimester(bim: int) -> Dictionary:
	return VACATION_RETREATS.get(bim, {})

func get_memory_card(card_id: String) -> Dictionary:
	for c in MEMORY_CARDS:
		if c["id"] == card_id:
			return c
	return {}

func get_gift(gift_id: String) -> Dictionary:
	for g in GIFTS:
		if g["id"] == gift_id:
			return g
	return {}

func get_gifts_for_shop(shop_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for g in GIFTS:
		if str(g.get("shop", "")) == shop_id:
			out.append(g)
	return out

func get_activity_illustration(act_id: String, cat: String = "class") -> String:
	match act_id:
		"class_armory", "job_caravan":
			return "res://assets/art/illus_martial_courtyard.png"
		"class_astrolabe", "job_clockwork":
			return "res://assets/art/illus_study_astrolabe.png"
		"class_conservatory", "job_amphitheater":
			return "res://assets/art/illus_conservatory_harp.png"
		"class_sanctuary":
			return "res://assets/art/bg_district_espejo.png"
		"job_sanatorium", "rest_springs":
			return "res://assets/art/illus_sanatorium_garden.png"
		"rest_manor":
			return "res://assets/art/bg_hearth_night.png"
		"job_canals":
			return "res://assets/art/bg_district_acueductos.png"
	if cat == "job":
		return "res://assets/art/bg_district_acueductos.png"
	if cat == "rest":
		return "res://assets/art/bg_hearth_night.png"
	return "res://assets/art/illus_study_astrolabe.png"

func get_father_task_illustration(task_id: String) -> String:
	match task_id:
		"hero_work":
			return "res://assets/art/illus_martial_courtyard.png"
		"supervise":
			return "res://assets/art/illus_study_astrolabe.png"
		"cook_home":
			return "res://assets/art/bg_hearth_night.png"
		"investigate":
			return "res://assets/art/bg_district_espejo.png"
		"diplomacy":
			return "res://assets/art/bg_district_palacio.png"
	return "res://assets/art/father_portrait.png"

func get_relic_icon(mat_id: String) -> String:
	match mat_id:
		"comet_dust":
			return "res://assets/ui/relic_comet_dust.png"
		"quartz_marrow":
			return "res://assets/ui/relic_quartz_marrow.png"
		"mercury_dew":
			return "res://assets/ui/relic_mercury_dew.png"
		"sarcophagus_shard", "obsidian_shard":
			return "res://assets/ui/relic_obsidian_shard.png"
		"melted_hourglass":
			return "res://assets/ui/relic_melted_hourglass.png"
		"goddess_tear":
			return "res://assets/ui/relic_goddess_tear.png"
	return "res://assets/ui/relic_comet_dust.png"

func get_district_backdrop(dist_id: String) -> String:
	match dist_id:
		"torre":
			return "res://assets/art/bg_district_torre.png"
		"palacio":
			return "res://assets/art/bg_district_palacio.png"
		"patio":
			return "res://assets/art/bg_district_patio.png"
		"acueductos":
			return "res://assets/art/bg_district_acueductos.png"
		"espejo":
			return "res://assets/art/bg_district_espejo.png"
		"anfiteatro":
			return "res://assets/art/bg_coliseum_festival.png"
	return "res://assets/art/bg_town_map.png"

func get_zone_backdrop(zone_id: String) -> String:
	match zone_id:
		"zone_1":
			return "res://assets/art/bg_zone_clocks.png"
		"zone_2":
			return "res://assets/art/bg_district_acueductos.png"
		"zone_3":
			return "res://assets/art/bg_zone_crystal.png"
		"zone_4":
			return "res://assets/art/bg_zone_crater.png"
		"zone_5":
			return "res://assets/art/bg_prologue_goddess.png"
	return "res://assets/art/bg_zone_clocks.png"

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
