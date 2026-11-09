extends Node

## Singleton CatalogDB - Base de datos modular (Fase 2 y Fase 5):
## Contiene Clases, Oficios, Descansos, Materiales del Horno Astral, Sinergias de Prestigio y Micro-Eventos.

const ACTIVITIES: Array[Dictionary] = [
	# --- CLASES ACADÉMICAS, MARCIALES Y CÓSMICAS (CUESTAN ORO) ---
	{
		"id": "class_armory",
		"name": "Academia de Armas (Maestra Rivena)",
		"category": "class",
		"cost_or_wage": -90,
		"stats": {"temple": 22, "destreza": 26, "gravedad": 10},
		"stress": 8,
		"seal_delta": 0,
		"rival_id": "vespera",
		"facility_bonus": "armory",
		"desc": "Esgrima imperial, lanza pesada y condicionamiento físico. Compites en el patio con Dama Vespera."
	},
	{
		"id": "class_astrolabe",
		"name": "Torre del Astrolabio (Archimago Thalor)",
		"category": "class",
		"cost_or_wage": -100,
		"stats": {"erudicion": 26, "luminiscencia": 22, "resonancia": 18},
		"stress": 9,
		"seal_delta": 0,
		"rival_id": "soren",
		"facility_bonus": "library",
		"desc": "Cálculo de efemérides, canalización de luz astral y teoría del tiempo junto a Soren."
	},
	{
		"id": "class_conservatory",
		"name": "Conservatorio Real (Madame Isolde)",
		"category": "class",
		"cost_or_wage": -95,
		"stats": {"gracia": 28, "magnetismo": 24, "human_anchor": 4},
		"stress": 7,
		"seal_delta": 0,
		"rival_id": "lyra",
		"facility_bonus": "conservatory",
		"desc": "Protocolo cortesano, danza de salón, arpa y diplomacia frente a la mirada crítica de Lady Lyra."
	},
	{
		"id": "class_sanctuary",
		"name": "Santuario de la Palma Celeste (Teología)",
		"category": "class",
		"cost_or_wage": -70,
		"stats": {"luminiscencia": 20, "devocion": 10, "moralidad": 8},
		"stress": 5,
		"seal_delta": 3,
		"rival_id": "",
		"facility_bonus": "",
		"desc": "Meditación sagrada y cánticos antiguos que refuerzan +3% la Integridad del Sello Estelar."
	},
	{
		"id": "class_clockwork",
		"name": "Taller de Relojería y Crisol (Maestro Baelor)",
		"category": "class",
		"cost_or_wage": -110,
		"stats": {"erudicion": 22, "resonancia": 25, "destreza": 18},
		"stress": 8,
		"seal_delta": 1,
		"rival_id": "soren",
		"facility_bonus": "crucible",
		"desc": "Ingeniería de precisión y alquimia astral; purifica la saturación y estabiliza el núcleo."
	},

	# --- OFICIOS Y TRABAJOS REMUNERADOS (GENERAN ORO) ---
	{
		"id": "job_sanatorium",
		"name": "Enfermería en el Sanatorio del Lirio",
		"category": "job",
		"cost_or_wage": 95,
		"stats": {"erudicion": 12, "moralidad": 8, "human_anchor": 6},
		"stress": 6,
		"seal_delta": 1,
		"rival_id": "",
		"facility_bonus": "",
		"desc": "Ayudar a la Doctora Helena a cuidar enfermos. Fortalece profundamente el Anclaje Humano (+6)."
	},
	{
		"id": "job_amphitheater",
		"name": "Recital en el Anfiteatro de Cristal",
		"category": "job",
		"cost_or_wage": 140,
		"stats": {"gracia": 18, "magnetismo": 16, "human_anchor": 4},
		"stress": 7,
		"seal_delta": 0,
		"rival_id": "lyra",
		"facility_bonus": "conservatory",
		"desc": "Acompañar a Mirari con música y canto ante los ciudadanos de Aethelgard."
	},
	{
		"id": "job_caravan",
		"name": "Escolta de Caravanas del Cuarzo",
		"category": "job",
		"cost_or_wage": 165,
		"stats": {"temple": 18, "destreza": 16, "gravedad": 8},
		"stress": 11,
		"seal_delta": 0,
		"rival_id": "caelum",
		"facility_bonus": "armory",
		"loot_chance_item": "comet_dust",
		"desc": "Proteger mercaderes en los caminos exteriores. Buena paga y probabilidad de hallar Polvo de Cometa."
	},
	{
		"id": "job_canals",
		"name": "Contrabando en los Canales de Mercurio",
		"category": "job",
		"cost_or_wage": 225,
		"stats": {"destreza": 20, "entropia": 10, "abyssal_sync": 6, "moralidad": -6},
		"stress": 12,
		"seal_delta": -3,
		"rival_id": "caelum",
		"facility_bonus": "",
		"loot_chance_item": "mercury_dew",
		"desc": "Tráfico nocturno de reliquias con la banda de Kaelen. Altísimo oro, pero erosiona -3% el Sello."
	},

	# --- DESCANSO, OCIO Y VIDA TERRENAL ---
	{
		"id": "rest_manor",
		"name": "Reposo y Lectura en el Jardín Familiar",
		"category": "rest",
		"cost_or_wage": 0,
		"stats": {"human_anchor": 5, "affection": 4},
		"stress": -22,
		"seal_delta": 1,
		"rival_id": "",
		"facility_bonus": "conservatory",
		"desc": "Descansar en casa sin presiones, reduciendo -22 de Estrés y fortaleciendo el vínculo familiar."
	},
	{
		"id": "rest_springs",
		"name": "Retiro en las Termas de Alabastro",
		"category": "rest",
		"cost_or_wage": -80,
		"stats": {"temple": 10, "gracia": 10, "human_anchor": 6},
		"stress": -36,
		"seal_delta": 4,
		"rival_id": "",
		"facility_bonus": "",
		"desc": "Aguas termales ricas en minerales que alivian -36 de Estrés y restauran +4% de Integridad del Sello."
	}
]

const PRESTIGE_SYNERGIES: Array[Dictionary] = [
	{
		"id": "horizon_valkyrie",
		"title": "Valquiria del Horizonte",
		"stat_a": "temple", "req_a": 240,
		"stat_b": "destreza", "req_b": 240,
		"bonus_desc": "+20% rendimiento marcial y +15 puntos extra en el Torneo de Otoño."
	},
	{
		"id": "ephemeris_weaver",
		"title": "Tejedora de Efemérides",
		"stat_a": "erudicion", "req_a": 240,
		"stat_b": "resonancia", "req_b": 200,
		"bonus_desc": "+25% eficacia en estudios astrales y desbloquea la carta 'Rebobinado Temporal'."
	},
	{
		"id": "alabaster_rose",
		"title": "Estrella de la Corte de Alabastro",
		"stat_a": "gracia", "req_a": 220,
		"stat_b": "magnetismo", "req_b": 220,
		"bonus_desc": "+30% ingresos en recitales y gran ventaja diplomática con el Príncipe Cassian."
	},
	{
		"id": "mortal_beacon",
		"title": "Faro de Humanidad Inquebrantable",
		"stat_a": "human_anchor", "req_a": 85,
		"stat_b": "luminiscencia", "req_b": 200,
		"bonus_desc": "El amor terrenal protege su alma: regenera +2% de Sello Estelar cada bimestre."
	},
	{
		"id": "eclipse_sovereign",
		"title": "Domadora del Sarcófago Astral",
		"stat_a": "abyssal_sync", "req_a": 45,
		"stat_b": "gravedad", "req_b": 180,
		"bonus_desc": "Pacto consciente con Zephyr: el Horno Astral otorga un +30% adicional de atributos."
	},
	{
		"id": "solar_artificer",
		"title": "Artífice del Reloj Solar",
		"stat_a": "destreza", "req_a": 210,
		"stat_b": "resonancia", "req_b": 210,
		"bonus_desc": "Maestría en engranajes celestes: reduce el coste de transmutación y suma +15% a Investigación del Sello."
	}
]

const COSMIC_MATERIALS: Array[Dictionary] = [
	{
		"id": "comet_dust",
		"name": "Polvo de Cometa Plateado",
		"price": 140,
		"desc": "+30 Destreza, +20 Resonancia | Sello: -2% | Mutación: Paso de Luz",
		"stats": {"destreza": 30, "resonancia": 20, "seal_integrity": -2},
		"mutation": "Paso de Luz (Evasión Astral)"
	},
	{
		"id": "quartz_marrow",
		"name": "Médula de Ciervo de Cuarzo",
		"price": 170,
		"desc": "+40 Temple, +25 Luminiscencia | Sello: 0% (Puro) | Mutación: Pulso Cristalino",
		"stats": {"temple": 40, "luminiscencia": 25},
		"mutation": "Pulso Cristalino (Regeneración)"
	},
	{
		"id": "mercury_dew",
		"name": "Azogue de los Acueductos",
		"price": 160,
		"desc": "+35 Erudición, +30 Gravedad | Sello: -4% | Mutación: Sangre Pesada",
		"stats": {"erudicion": 35, "gravedad": 30, "seal_integrity": -4},
		"mutation": "Sangre Pesada (Anti-Ruptura)"
	},
	{
		"id": "sarcophagus_shard",
		"name": "Esquirla del Sarcófago Estelar",
		"price": 260,
		"desc": "+55 Gravedad, +45 Luminiscencia, +15 Sincronía Zephyr | Sello: -10% | Mutación: Voz del Eclipse",
		"stats": {"gravedad": 55, "luminiscencia": 45, "abyssal_sync": 15, "seal_integrity": -10},
		"mutation": "Voz del Eclipse (Llamado de Nyx-Aethel)"
	},
	{
		"id": "melted_hourglass",
		"name": "Reloj de Arena Derretido",
		"price": 240,
		"desc": "+60 Resonancia, +35 Erudición | Sello: -6% | Mutación: Paradoja Menor",
		"stats": {"resonancia": 60, "erudicion": 35, "seal_integrity": -6},
		"mutation": "Paradoja Menor (Doble Turno)"
	},
	{
		"id": "goddess_tear",
		"name": "Lágrima de la Diosa Cautiva",
		"price": 220,
		"desc": "+25 Gracia, +15 Anclaje Humano | Restaura +15% Integridad del Sello",
		"stats": {"gracia": 25, "human_anchor": 15, "seal_integrity": 15},
		"mutation": "Bendición del Tiempo (Ancla Sagrada)"
	}
]

func get_activity_by_id(act_id: String) -> Dictionary:
	for a in ACTIVITIES:
		if a["id"] == act_id:
			return a
	return ACTIVITIES[0]

func check_and_unlock_synergies() -> Array[Dictionary]:
	var newly_unlocked: Array[Dictionary] = []
	for syn in PRESTIGE_SYNERGIES:
		var syn_id: String = syn["id"]
		if GameState.unlocked_synergies.has(syn_id):
			continue
		var val_a: int = int(GameState.get(syn["stat_a"]))
		var val_b: int = int(GameState.get(syn["stat_b"]))
		if val_a >= syn["req_a"] and val_b >= syn["req_b"]:
			GameState.unlocked_synergies.append(syn_id)
			newly_unlocked.append(syn)
			Chronicle.record_event("synergy_" + syn_id, "¡Sinergia de Prestigio Despertada!", "Renpet obtuvo el título '%s': %s" % [syn["title"], syn["bonus_desc"]], "prestige", 5)
	return newly_unlocked
