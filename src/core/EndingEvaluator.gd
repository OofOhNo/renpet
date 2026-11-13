extends Node

## EndingEvaluator - Evaluador Integral de los 4 Vectores y Matriz de 65 Finales (Fase 9).
## Calcula la Rama del Acto III (5 ramas), Vocación (13 carreras = 65 combinaciones únicas),
## Epílogos de Vínculos/Némesis, Destino Político de Aethelgard y el Testamento Paternal.

const BRANCHES: Dictionary = {
	"branch_mortal": {
		"id": "branch_mortal",
		"order": 1,
		"name": "Rama I: El Corazón Mortal Triunfante",
		"short": "Corazón Mortal",
		"color": "#86e3a6",
		"climax_title": "EL TRIUNFO DEL LATIDO HUMANO",
		"climax_body": "En el Horizonte Quebrado, la Diosa Renpet-Neheh desciende entre relojes de oro suspendidos para reclamar el astro que te confió hace ocho años. Sin embargo, al tocar el pecho de %s, su mano divina retrocede quemada por una calidez terrenal.\n\nEl amor mortal y los años vividos bajo tu techo han transformado la naturaleza de la estrella: ya no queda en ella metal celestial que cosechar, sino un alma plenamente humana.",
		"climax_choices": [
			{"label": "♥ «Ella es mi hija, Señora de la Eternidad, y su corazón ya pertenece a este mundo.»",
				"note": "La calidez del hogar sella definitivamente su humanidad frente a la corte celeste."},
			{"label": "⚔ «Si deseas reclamarla, primero tendrás que cruzar el acero del Héroe que te liberó.»",
				"note": "Tu determinación inquebrantable obliga a los heraldos de la Diosa a inclinarse ante el derecho mortal."}
		]
	},
	"branch_dual_star": {
		"id": "branch_dual_star",
		"order": 2,
		"name": "Rama II: La Soberana de la Estrella Dual",
		"short": "Estrella Dual",
		"color": "#5dd2e4",
		"climax_title": "SÍNTESIS DE LUZ Y CAMBIO",
		"climax_body": "Cuando la Diosa abre los cielos para separar el recipiente de su prisionero, %s da un paso al frente sin miedo. A su espalda, la silueta de Zephyr no intenta romperla: entrelaza su mano con la suya.\n\nLa humanidad forjada contigo y el poder primordial de Nyx-Aethel resuenan en una armonía que ni la propia Eternidad había previsto: ni jaula ni carcelera, sino dos voluntades soberanas en un solo fulgor.",
		"climax_choices": [
			{"label": "✦ «Que la luz estática y el cambio libre dancen en equilibrio desde esta noche.»",
				"note": "La fusión voluntaria reescribe la órbita de Aethelgard en un crepúsculo violeta y dorado."},
			{"label": "☾ «Zephyr y %s caminarán juntos como iguales más allá de tus relojes.»",
				"note": "La estrella dual trasciende el decreto antiguo ante los ojos atónitos de la Diosa."}
		]
	},
	"branch_deicide": {
		"id": "branch_deicide",
		"order": 3,
		"name": "Rama III: La Rebelión Deicida (Camino Verdadero)",
		"short": "Rebelión Deicida",
		"color": "#f4c95d",
		"climax_title": "EL JUICIO EN EL HORIZONTE QUEBRADO",
		"climax_body": "La Diosa esperaba hallar un recipiente dócil o una bestia desatada. En su lugar encuentra el mecanismo secreto de su propio Sello invertido por tus años de investigación, las cinco Esquirlas de Memoria vibrando en círculo y a %s rodeada por los aliados que eligió en la tierra.\n\n%s despliega ante la Deidad las pruebas de su traición milenaria a Nyx-Aethel. El cielo entero contiene el aliento mientras los relojes eternos comienzan a girar hacia adelante.",
		"climax_choices": [
			{"label": "✦ «Tu eternidad inmóvil termina hoy. Que el tiempo vuelva a pertenecer a quienes lo viven.»",
				"note": "El mecanismo de las Esquirlas rompe la corona estática de la Diosa sin sacrificar a nadie."},
			{"label": "☥ «Liberamos a Nyx-Aethel como compañero del mundo, no como arma contra él.»",
				"note": "Nyx-Aethel recupera su libertad junto al amor mortal que aprendió junto a vosotros."}
		]
	},
	"branch_sacrifice": {
		"id": "branch_sacrifice",
		"order": 4,
		"name": "Rama IV: El Sacrificio de la Palma",
		"short": "Sacrificio Sagrado",
		"color": "#b79cf8",
		"climax_title": "LA OFRENDA DEL RECIPIENTE PURO",
		"climax_body": "Las campanas del Santuario tañen con solemnidad helada cuando Renpet-Neheh desciende sobre el altar. %s inclina la cabeza en silencio; su devoción ha superado cualquier apego terrenal.\n\nCon lágrimas tranquilas, se despide de ti antes de ascender hacia el cielo dorado para devolver estabilidad al firmamento y silenciar para siempre las grietas del cosmos.",
		"climax_choices": [
			{"label": "❀ «Ve en paz, hija mía. Cada noche buscaré tu luz entre las constelaciones.»",
				"note": "Tu bendición serena acompaña su ascenso hacia la bóveda eterna."},
			{"label": "☥ «Que tu sacrificio sea recordado como el acto más noble de esta era.»",
				"note": "Las hojas de palma dorada cubren el observatorio mientras su estrella ocupa el cenit."}
		]
	},
	"branch_eclipse": {
		"id": "branch_eclipse",
		"order": 5,
		"name": "Rama V: La Emperatriz del Eclipse",
		"short": "Eclipse Eterno",
		"color": "#f26b7a",
		"climax_title": "LA RUPTURA DEL SARCÓFAGO",
		"climax_body": "Antes siquiera de que la Diosa pueda pronunciar la sentencia, el Sello ya hecho añicos estalla en un torbellino de gravedad violeta. Demasiadas heridas, rencores sin sanar o fisuras abiertas a la fuerza han extinguido la frontera entre la niña y la furia del abismo.\n\nEl sol de Aethelgard se apaga tras un anillo carmesí cuando %s reclama la corona caída de la propia Eternidad.",
		"climax_choices": [
			{"label": "☠ «¡Detente, %s! Aunque deba enfrentarte solo, no soltaré lo que queda de mi hija.»",
				"note": "Tu última plegaria atraviesa la noche púrpura como una cicatriz imposible de olvidar."},
			{"label": "⚡ «Si el cielo nos usó como peones, que arda el firmamento entero.»",
				"note": "Padre e hija aceptan la oscuridad absoluta frente a los tronos destrozados."}
		]
	}
}

const BRANCH_ORDER: Array[String] = [
	"branch_deicide", "branch_dual_star", "branch_mortal", "branch_sacrifice", "branch_eclipse"
]

const VOCATION_ORDER: Array[String] = [
	"sovereign", "marshal", "archmage", "weaver", "oracle", "alchemist",
	"muse", "pathfinder", "shadow", "abyssal_warden", "chronicler", "hearthkeeper", "wanderer"
]

const VOCATIONS: Dictionary = {
	"sovereign": {"name": "Soberana de Aethelgard", "tag": "Corte y Liderazgo"},
	"marshal": {"name": "Gran Mariscal de la Lanza", "tag": "Acero y Estrategia"},
	"archmage": {"name": "Archimaga del Observatorio", "tag": "Sabiduría Estelar"},
	"weaver": {"name": "Tejedora de Efemérides", "tag": "Gravedad y Tiempo"},
	"oracle": {"name": "Oráculo del Alba Solar", "tag": "Fe y Profecía"},
	"alchemist": {"name": "Alquimista del Reloj Real", "tag": "Crisol y Precisión"},
	"muse": {"name": "Musa de las Siete Lunas", "tag": "Arte y Esplendor"},
	"pathfinder": {"name": "Cazadora de Horizontes", "tag": "Exploración y Valor"},
	"shadow": {"name": "Voz de las Sombras", "tag": "Sigilo y Canales"},
	"abyssal_warden": {"name": "Custodia del Relicario Oculto", "tag": "Poder Primordial"},
	"chronicler": {"name": "Cronista de las Constelaciones", "tag": "Memoria e Historia"},
	"hearthkeeper": {"name": "Guardiana del Hogar Solar", "tag": "Vínculo Humano"},
	"wanderer": {"name": "Errante del Horizonte Quebrado", "tag": "Camino Libre"}
}

# Títulos y tonos específicos para las 65 combinaciones (5 Ramas x 13 Vocaciones)
const MATRIX_TITLES: Dictionary = {
	"branch_mortal": {
		"sovereign": "Reina Mortal de Aethelgard",
		"marshal": "Gran Mariscal del Juramento Humano",
		"archmage": "Rectora de la Academia Solar",
		"weaver": "Astrónoma del Tiempo Terrenal",
		"oracle": "Sacerdotisa de la Compasión Viva",
		"alchemist": "Maestra Botánica y Relojera Real",
		"muse": "Dama Inmortal de las Siete Lunas",
		"pathfinder": "Capitán de las Fronteras Abiertas",
		"shadow": "Señora Secreta de los Canales",
		"abyssal_warden": "Guardián de las Reliquias Dormidas",
		"chronicler": "Historiadora del Siglo Humano",
		"hearthkeeper": "Heredera del Hogar del Héroe",
		"wanderer": "Viajera de Corazón Libre"
	},
	"branch_dual_star": {
		"sovereign": "Monarca de las Dos Luces",
		"marshal": "Valquiria del Doble Horizonte",
		"archmage": "Arquitecta del Nuevo Firmamento",
		"weaver": "Señora de las Órbitas Enlazadas",
		"oracle": "Profeta del Pacto Celeste",
		"alchemist": "Artífice de la Piedra Estelar",
		"muse": "Cantora de la Armonía Astral",
		"pathfinder": "Viajera de los Planos con Zephyr",
		"shadow": "Tejedora de Espejos y Penumbras",
		"abyssal_warden": "Custodia Viva de Nyx-Aethel",
		"chronicler": "Escriba del Códice Dual",
		"hearthkeeper": "Faro Compartido de la Mansión",
		"wanderer": "Peregrina de Dos Cielos"
	},
	"branch_deicide": {
		"sovereign": "Fundadora de la Era del Tiempo Libre",
		"marshal": "Espada que Rompió la Eternidad",
		"archmage": "Canciller de la República Astronómica",
		"weaver": "Ingeniera del Reloj Sin Cadenas",
		"oracle": "Renovadora de los Templos Libres",
		"alchemist": "Suprema Maestra del Crisol Abierto",
		"muse": "Estrella Viva de la Nueva Capital",
		"pathfinder": "Descubridora del Más Allá del Horizonte",
		"shadow": "Liberadora tras el Trono Caído",
		"abyssal_warden": "Hermana de Armas del Lucero Libre",
		"chronicler": "El Héroe y la Estrella (Leyenda Viva)",
		"hearthkeeper": "El Milagro de la Familia Mortal",
		"wanderer": "Mensajera del Mundo Sin Dueños"
	},
	"branch_sacrifice": {
		"sovereign": "Corona Inmóvil del Sacrificio",
		"marshal": "Mártir de la Guardia Celestial",
		"archmage": "Voz Silenciosa del Astrolabio Eterno",
		"weaver": "Péndulo Sagrado del Cosmos",
		"oracle": "Santa Inmortal del Firmamento",
		"alchemist": "Lágrima Dorada del Relicario",
		"muse": "Eco Eterno de las Siete Lunas",
		"pathfinder": "Estrella Polar de los Navegantes",
		"shadow": "Penitente del Velo Dorado",
		"abyssal_warden": "Sello Viviente de la Palma Eterna",
		"chronicler": "La Constelación de la Hija",
		"hearthkeeper": "Oración Eterna por su Hogar",
		"wanderer": "Luz Lejana en el Cielo de Invierno"
	},
	"branch_eclipse": {
		"sovereign": "Emperatriz de la Noche Eterna",
		"marshal": "Flagelo del Sol Quebrado",
		"archmage": "Señora de la Sabiduría Prohibida",
		"weaver": "Devoradora de los Relojes Divinos",
		"oracle": "Sacerdotisa del Eclipse Carmesí",
		"alchemist": "Forjadora de Quimeras Estelares",
		"muse": "Sirena de las Lunas Rotas",
		"pathfinder": "Calamidad del Horizonte Abisal",
		"shadow": "Sombra Soberana de los Subterráneos",
		"abyssal_warden": "Encarnación Pura de Nyx-Aethel",
		"chronicler": "Testigo del Último Crepúsculo",
		"hearthkeeper": "Tragedia del Padre Caído",
		"wanderer": "Cometa Errante de Perdición"
	}
}

func evaluate_campaign() -> Dictionary:
	var branch_info: Dictionary = _evaluate_branch()
	var branch_id: String = str(branch_info["id"])
	var vocation_info: Dictionary = _evaluate_vocation()
	var vocation_id: String = str(vocation_info["id"])
	var matrix: Dictionary = compose_matrix_ending(branch_id, vocation_id)
	var bond_info: Dictionary = _evaluate_bonds_vector(branch_id)
	var rival_info: Dictionary = _evaluate_rivals_vector()
	var politics_info: Dictionary = _evaluate_politics_vector(branch_id, vocation_id, bond_info)
	var testament: Dictionary = _evaluate_father_testament(branch_id, bond_info)

	return {
		"ending_id": matrix["id"],
		"ending_title": matrix["title"],
		"ending_summary": matrix["summary"],
		"branch_id": branch_id,
		"branch": branch_info,
		"vocation_id": vocation_id,
		"vocation": vocation_info,
		"bond": bond_info,
		"rivals": rival_info,
		"politics": politics_info,
		"testament": testament,
		"metrics": {
			"age": GameState.age,
			"shards": ExplorationCombat.memory_shards_found.size(),
			"festival_wins": ExplorationCombat.festival_wins.size(),
			"unseal_count": ExplorationCombat.unseal_used_count,
			"mutations": GameState.active_mutations.size(),
			"synergies": GameState.unlocked_synergies.size(),
			"letters": Chronicle.letters_archive.size()
		}
	}

func _evaluate_branch() -> Dictionary:
	var anchor: int = GameState.human_anchor
	var seal: int = GameState.seal_integrity
	var sync: int = GameState.abyssal_sync
	var ent: int = GameState.entropia
	var dev: int = GameState.devocion
	var aff: int = GameState.affection
	var inv: int = GameState.seal_investigation_progress
	var shards: int = ExplorationCombat.memory_shards_found.size()
	var strong_allies: int = 0
	var nemesis_count: int = 0
	for npc_id in RelationshipManager.NPC_ORDER:
		var c: Dictionary = RelationshipManager.state.get(npc_id, {})
		var npc_aff: int = int(c.get("affection", 0))
		if npc_aff >= 35:
			strong_allies += 1
		if npc_aff <= -45:
			nemesis_count += 1

	var chosen_id: String = ""
	var exact: bool = true

	# Orden de prioridad fiel a la Biblia de Sistemas e Historia
	if inv >= 80 and shards >= 4 and anchor >= 60 and aff >= 55 and strong_allies >= 1:
		chosen_id = "branch_deicide"
	elif seal <= 15 or (ent >= 75 and anchor < 35) or (anchor < 25 and nemesis_count >= 2):
		chosen_id = "branch_eclipse"
	elif anchor >= 70 and sync >= 65 and (GameState.erudicion + GameState.luminiscencia >= 550 or GameState.resonancia >= 320):
		chosen_id = "branch_dual_star"
	elif dev >= 78 and anchor < 48:
		chosen_id = "branch_sacrifice"
	elif anchor >= 72 and seal >= 60 and aff >= 65:
		chosen_id = "branch_mortal"
	else:
		# Desempate ponderado para partidas intermedias / híbridas
		exact = false
		var scores: Dictionary = {
			"branch_mortal": float(anchor * 1.25 + aff * 0.7 + seal * 0.4),
			"branch_dual_star": float(sync * 1.25 + anchor * 0.65 + (GameState.resonancia + GameState.luminiscencia) * 0.08),
			"branch_deicide": float(inv * 1.1 + shards * 18.0 + strong_allies * 16.0 + anchor * 0.4),
			"branch_sacrifice": float(dev * 1.35 + (100 - anchor) * 0.75 + seal * 0.35),
			"branch_eclipse": float(ent * 1.35 + (100 - seal) * 0.8 + (100 - anchor) * 0.65 + nemesis_count * 22.0)
		}
		var best_s: float = -1.0
		for bid in BRANCH_ORDER:
			if float(scores[bid]) > best_s:
				best_s = float(scores[bid])
				chosen_id = bid

	var d: Dictionary = BRANCHES[chosen_id].duplicate(true)
	d["exact_match"] = exact
	d["climax_body"] = str(d["climax_body"]) % _branch_body_args(chosen_id)
	for c_item in d.get("climax_choices", []):
		if c_item is Dictionary and str(c_item.get("label", "")).contains("%s"):
			c_item["label"] = str(c_item["label"]).replace("%s", GameState.daughter_name)
	return d

func _branch_body_args(branch_id: String) -> Array:
	if branch_id == "branch_deicide":
		return [GameState.daughter_name, GameState.father_name]
	return [GameState.daughter_name]

func get_projected_vocation() -> Dictionary:
	var scores: Dictionary = _score_vocations()
	var best_id: String = "wanderer"
	var best_val: int = -1
	var second_id: String = "wanderer"
	var second_val: int = -1
	for vid in VOCATION_ORDER:
		var val: int = int(scores.get(vid, 0))
		if val > best_val:
			second_val = best_val
			second_id = best_id
			best_val = val
			best_id = vid
		elif val > second_val:
			second_val = val
			second_id = vid
	var out: Dictionary = VOCATIONS[best_id].duplicate()
	out["id"] = best_id
	out["score"] = best_val
	out["runner_up_id"] = second_id
	out["runner_up_name"] = str(VOCATIONS.get(second_id, {}).get("name", ""))
	return out

func _score_vocations() -> Dictionary:
	var t: int = GameState.temple
	var dx: int = GameState.destreza
	var er: int = GameState.erudicion
	var gr: int = GameState.gracia
	var mg: int = GameState.magnetismo
	var lm: int = GameState.luminiscencia
	var gv: int = GameState.gravedad
	var rs: int = GameState.resonancia
	var shards: int = ExplorationCombat.memory_shards_found.size()
	var fest: int = ExplorationCombat.festival_wins.size()
	var muts: int = GameState.active_mutations.size()
	var syns: int = GameState.unlocked_synergies.size()

	return {
		"sovereign": gr + mg + GameState.father_reputation * 5 + fest * 90,
		"marshal": t + dx + GameState.father_reputation * 2 + shards * 45,
		"archmage": er + lm + GameState.seal_investigation_progress * 3,
		"weaver": rs + gv + muts * 120 + syns * 140,
		"oracle": GameState.devocion * 8 + GameState.moralidad * 5 + lm,
		"alchemist": er + dx + GameState.astral_saturation * 4 + muts * 130,
		"muse": gr + mg + fest * 160 + GameState.affection * 3,
		"pathfinder": shards * 210 + dx + t + ExplorationCombat.unseal_used_count * 20,
		"shadow": dx + GameState.entropia * 7 + GameState.seal_investigation_progress * 4,
		"abyssal_warden": gv + GameState.abyssal_sync * 6 + muts * 145,
		"chronicler": er + shards * 130 + Chronicle.letters_archive.size() * 65 + GameState.moralidad * 3,
		"hearthkeeper": GameState.affection * 7 + GameState.human_anchor * 7 + GameState.moralidad * 3,
		"wanderer": 640
	}

func _evaluate_vocation() -> Dictionary:
	return get_projected_vocation()

# Prosa y desenlaces específicos para cada una de las 65 combinaciones (5 Ramas x 13 Vocaciones)
const MATRIX_EPILOGUES: Dictionary = {
	"branch_mortal": {
		"sovereign": "Libre de la deuda celeste gracias al latido humano que forjó junto a {F}, {D} asciende al consejo más alto de Aethelgard sin un ápice de arrogancia divina. Sus decretos sustituyen el viejo tributo estelar por cartas civiles para artesanos y provincias, mientras cada primavera regresa sin escolta a cenar a la mesa de su infancia.",
		"marshal": "Al apagarse el metal divino en su pecho, {D} conserva intacta la disciplina aprendida en el patio de armas bajo la mirada de {F}. Nombrada Gran Mariscal de la Guardia Humana, reorganiza las fronteras con acero mortal y rechaza cualquier pacto de vasallaje con los heraldos de la Eternidad.",
		"archmage": "{D} abre las bóvedas selladas de la Torre del Astrolabio a todo aprendiz sin importar su cuna. Despojada de la tutela celeste, demuestra junto a las notas de {F} que el estudio paciente de la bóveda nocturna vale más que mil revelaciones impuestas desde el altar.",
		"weaver": "Con el Sello disuelto en carne mortal, {D} convierte su extraña afinidad con la gravedad en la ciencia exacta de las mareas y los relojes públicos de Aethelgard. Sus cuadrantes miden al fin horas humanas, y {F} conserva en la chimenea el primer astrolabio de latón que calibraron juntos.",
		"oracle": "{D} rechaza el dogma pétreo de los altares dorados para fundar templos abiertos donde se atiende a enfermos y viajeros sin exigir ofrendas celestes. Su fe no invoca a dioses lejanos, sino la compasión terrenal que aprendió viendo a {F} curar heridas junto al fuego.",
		"alchemist": "Sin depender ya del Crisol de emergencia, {D} transforma el laboratorio familiar en una botica y relojería célebre en todo el reino. Sus tónicos de loto y mecanismos de precisión salvan vidas reales cada invierno, mientras {F} aún se encarga de escoger las hierbas más raras del mercado.",
		"muse": "Cuando el telón del Gran Anfiteatro sube cada otoño, la voz de {D} ya no lleva el eco frío de una vasija estelar, sino la emoción imperfecta y viva de la gente común. Sus óperas sobre un padre que desafió al firmamento arrancan lágrimas desde el gallinero hasta el palco real.",
		"pathfinder": "En lugar de encerrarse tras las murallas de Alabastro, {D} calza botas de cuero gasto y traza los primeros mapas completos más allá del Cráter y los acueductos antiguos. De cada expedición envía cartas cargadas de polvo de camino y piedras curiosas para el estante de {F}.",
		"shadow": "{D} conoce cada compuerta, pasadizo y censo manipulado de los canales subterráneos. Desde las sombras amables de los gremios libres protege a los desfavorecidos frente a los recaudadores del Senado, y solo {F} sabe en qué taberna portuaria se sienta cada solsticio.",
		"abyssal_warden": "Incluso convertida en mujer de carne y hueso, {D} no reniega de las reliquias dormidas que estudió en su juventud: las custodia bajo llave en su propia cámara para que ningún ambicioso vuelva a despertar guerras antiguas, compartiendo con {F} la vigilia serena de quien dominó sus miedos.",
		"chronicler": "{D} dedica su vida a reunir actas borradas, cartas privadas y memorias de soldados olvidados en la Biblioteca Nacional. Su obra cumbre relata cómo el orgullo inmortal de la Diosa perdió frente a la terca ternura de un hogar ordinario levantado por {F}.",
		"hearthkeeper": "Aunque las casas nobles la cortejan con títulos, {D} prefiere la tibieza de la mansión Solar, donde convierte los jardines y salones en refugio de aprendices y huérfanos. La risa vuelve a llenar los pasillos cada tarde cuando {F} llega con pan caliente bajo el brazo.",
		"wanderer": "Con el corazón plenamente suyo por primera vez en veinte años, {D} parte sin estandartes ni escoltas hacia los mares del sur y las cordilleras aún sin nombre. Promete volver cada fin de año antes de las heladas, y en la puerta de {F} siempre queda encendida una lámpara de bienvenida."
	},
	"branch_dual_star": {
		"sovereign": "Al ascender con Zephyr en perfecta síntesis de luz y cambio, {D} redefine la corona de Aethelgard desde un trono que respira al ritmo de las estaciones. El reino florece entre leyes justas y prodigios crepusculares, mientras {F} sigue siendo el único consejero al que escucha sin protocolos.",
		"marshal": "Lanza solar en mano y con el pulso violeta de Zephyr protegiendo su retaguardia, {D} se convierte en la protectora suprema del reino entero. Ningún ejército extranjero ni emisario astral osa cruzar el Horizonte Quebrado, aunque cada regreso al patio de {F} sigue oliendo a hierro y sopa caliente.",
		"archmage": "Gracias a los recuerdos primordiales compartidos por Zephyr y al rigor intelectual aprendido con {F}, {D} escribe el Nuevo Canon de la Astrometría. La Torre deja atrás el miedo a los eclipses para estudiar el cosmos como un diálogo vivo entre mortales y estrellas.",
		"weaver": "Las órbitas de Aethelgard obedecen al compás de dos voluntades amigas: {D} enlaza gravedad y luz para estabilizar sequías e inviernos extremos. En mitad del cielo violeta, aún reserva las noches tranquilas para calibrar péndulos en el estudio de {F}.",
		"oracle": "Los viejos sacerdotes caen de rodillas al ver que la profecía dual no trajo destrucción, sino un pacto vivo entre la humanidad y lo infinito. {D} predica una espiritualidad sin miedo ni sacrificios, llevando consigo la humildad terrenal heredada de {F}.",
		"alchemist": "Con el fuego sereno de la Estrella Dual alimentando el alambique, {D} sintetiza aleaciones medicinales y cristales limpios que no generan saturación ni locura. El viejo Crisol de la mansión de {F} se convierte en santuario mundial de la nueva alquimia.",
		"muse": "Cada nota que {D} canta bajo el firmamento bicromático hace vibrar el cristal de las plazas en armonía con el pulso oculto de Zephyr. Sus recitales reconcilian al pueblo con el misterio de la caída estelar, dedicando siempre la primera reverencia al asiento de {F}.",
		"pathfinder": "Junto a Zephyr guiando su brújula a través de brumas dimensionales, {D} explora ruinas anteriores a la propia Diosa sin perder jamás el camino de vuelta. Sobre la mesa de {F} se apilan mapas imposibles dibujados con tinta dorada y ceniza de cometa.",
		"shadow": "{D} camina entre reflejos y penumbras como puente entre el mundo diurno y el reino oculto de los espejos. Resuelve crisis de Estado antes de que lleguen a sangre, sabiendo que el ancla que evita que se disuelva en la niebla es el recuerdo firme de la voz de {F}.",
		"abyssal_warden": "Lo que una vez fue prisión de Nyx-Aethel se transforma bajo la voluntad serena de {D} en una alianza consciente. Ni ella domina a Zephyr ni Zephyr la consume: juntos custodian los límites del abismo mientras visitan a {F} cada estación para no olvidar el sabor de la tierra.",
		"chronicler": "Por primera vez en la historia, un astro consciente y una erudita mortal redactan a cuatro manos la crónica verdadera del firmamento. Sus volúmenes revelan la trampa de Renpet-Neheh y honran el coraje cotidiano de {F} como bisagra entre ambos mundos.",
		"hearthkeeper": "Aunque posee poder capaz de mover constelaciones, {D} ancla la Estrella Dual en la paz cotidiana de la mansión Solar. Zephyr aprende a cuidar rosas de invernadero junto a {F}, demostrando que incluso un ser primordial puede hallar reposo bajo un techo familiar.",
		"wanderer": "Unidos como dos luces viajeras en el crepúsculo violeta, {D} y Zephyr cruzan el horizonte hacia estrellas lejanas que jamás obedecieron a la Diosa. Cada Solsticio, una lluvia suave de chispas turquesas anuncia en la ventana de {F} que su hija sigue libre y feliz."
	},
	"branch_deicide": {
		"sovereign": "Tras hacer trizas los relojes inmóviles de la Diosa ante toda la capital, {D} es coronada sin corona metálica como fundadora de la Era del Tiempo Libre. Abolidos los diezmos astrales, gobierna hombro con hombro junto a los reformistas mientras {F} preside con orgullo silencioso el Consejo de Custodios.",
		"marshal": "Su espada —templada en el recuerdo de cada entrenamiento con {F}— pasará a los cantares como el filo mortal que quebró la arrogancia de una diosa. Al frente de las legiones ciudadanas, {D} garantiza que ningún nuevo tirano celeste o terrenal vuelva a poner precio a una vida humana.",
		"archmage": "Con el mecanismo divino desenmascarado por tus investigaciones y las cinco Esquirlas en su poder, {D} funda la República del Conocimiento en la Gran Biblioteca. La magia estelar deja de ser privilegio secreto para iluminar hospitales, barcos y escuelas en cada distrito.",
		"weaver": "{D} desmonta pieza a pieza las leyes estáticas de gravedad que congelaban el progreso de Aethelgard desde la Antigüedad. Sus nuevos relojes giran libres hacia un porvenir incierto pero vivo, y su primer brindis tras la victoria lo alza en honor a la paciencia incansable de {F}.",
		"oracle": "Sin diosa inmóvil que exija obediencia ciega, {D} refunda el Santuario como Casa de la Aurora Humana. En lugar de temer cometas, los ciudadanos celebran el valor de elegir su propio destino, recitando en las plegarias el juramento de padre e hija.",
		"alchemist": "Con las Esquirlas estabilizadas y el Crisol abierto al fin sin secretos de Estado, {D} libera los remedios astrales que la Corte había acaparado durante siglos. El nombre de su casa y el ejemplo perseverante de {F} quedan grabados en la puerta del nuevo Gremio Médico.",
		"muse": "El Gran Anfiteatro estalla en un himno nuevo que no alaba la eternidad estéril, sino el triunfo fugaz de quienes aman sabiendo que envejecerán. {D} se convierte en la voz inmortal —en memoria, no en piedra— de la noche en que Aethelgard recuperó su mañana.",
		"pathfinder": "Derribadas las barreras celestes que cercaban el continente, {D} encabeza la Primera Caravana hacia tierras más allá del Horizonte Quebrado. Cada hito que clava en el mundo desconocido lleva el emblema de {F}: una brújula rodeada de tres estrellas libres.",
		"shadow": "Pocos cronistas oficiales saben cuánto pesaron los contactos subterráneos y archivos robados de {D} para derribar los sellos de la Diosa en la sombra. Tras la victoria, disuelve la red de espías imperiales y se retira a cenar en calma con {F} en una ciudad que ya no teme a la noche.",
		"abyssal_warden": "En la plaza mayor de la capital, el antiguo prisionero Nyx-Aethel camina bajo el sol por primera vez junto a {D}, no como monstruo ni arma, sino como ciudadano libre. Ambos honran la osadía de {F}, el único héroe que buscó la verdad detrás del mito.",
		"chronicler": "{D} escribe la epopeya definitiva de la Rebelión Deicida sin omitir ni un miedo, ni una duda ni una cicatriz. Generaciones enteras leerán cómo {F} eligió amar y enseñar a su hija antes que entregarla, convirtiendo a una familia humilde en el mito fundacional de un mundo nuevo.",
		"hearthkeeper": "Cuando el estruendo del horizonte se disipa, {D} renuncia a los palacios dorados para volver a encender la chimenea de la mansión junto a {F}. El verdadero milagro que venció a la Eternidad no fueron las armas antiguas, sino ocho años de cuidado cotidiano.",
		"wanderer": "Con el cielo abierto a un futuro sin guion, {D} abandona las ceremonias triunfales al alba siguiente para recorrer caminos donde las estaciones vuelven a cambiar de verdad. Lleva en el equipaje apenas un mapa, una capa vieja y el retrato miniatura de {F}."
	},
	"branch_sacrifice": {
		"sovereign": "Envuelta en túnicas de palma dorada, {D} entrega su aliento terrenal para restaurar la corona del firmamento. Su trono permanece vacío en la Sala de Alabastro como recordatorio silencioso, y cada invierno el Senado entero visita el observatorio donde {F} aún mantiene intacta su silla.",
		"marshal": "Como antaño en la academia, {D} da un paso al frente para recibir el golpe que habría partido el cielo sobre Aethelgard. Su lanza queda clavada ante el Santuario rodeada de laureles; bajo ella, {F} deposita cada aniversario un ramo de loto blanco en silencio.",
		"archmage": "{D} asciende hacia la esfera más alta llevando consigo todo el saber estelar acumulado durante su juventud, convirtiéndose en el astrolabio viviente que guía a la humanidad. En la Torre aún conservan sus cuadernos repletos de anotaciones al margen escritas con la caligrafía de {F}.",
		"weaver": "Su último latido repara las fisuras del tiempo antes de que la gravedad desgarre la capital. Desde entonces, el gran reloj de Aethelgard da exactamente una campanada más cálida cada Solsticio, y solo {F} sabe que es su manera discreta de decir «buenas noches, Padre».",
		"oracle": "Proclamada Santa de la Palma Celeste por los templos de todo el reino, {D} acepta el silencio eterno para que millones despierten a un mañana pacífico. Cuando {F} entra en la nave central, hasta el Sumo Sacerdote se aparta en reverencia silenciosa.",
		"alchemist": "El sacrificio puro de {D} cristaliza en un rocío dorado que purifica para siempre la saturación tóxica de las tierras altas. Sus fórmulas curativas siguen salvando niños en los acueductos, mientras {F} limpia cada tarde los alambiques de cristal que ya no volverán a encenderse.",
		"muse": "El cielo entero vibra desde aquella noche con una nota cristalina que nunca existió en los tratados musicales. Los coros del Anfiteatro guardan siempre un compás en blanco al final de cada pieza para escuchar su eco, mientras {F} cierra los ojos desde el primer palco.",
		"pathfinder": "Su espíritu se fija en el zenit como la Estrella Polar inmutable que guía a marinos y caravanas perdidas en la ventisca. Ningún viajero de Aethelgard se extravía desde su ascenso, y {F} pasa las noches claras en la terraza trazando en papel el rumbo que ella cuida.",
		"shadow": "Nadie en los barrios bajos esperaba que quien caminaba entre sombras diera su luz entera sin pedir estatua ni tumba. Solo unos pocos amigos de los canales y {F} saben quién sostuvo el cielo en silencio para que la ciudad durmiera a salvo.",
		"abyssal_warden": "Para sellar definitivamente el hambre del abismo sin condenar al mundo, {D} cierra el relicario desde dentro consigo misma como llave eterna. El silencio nocturno es al fin sereno, y sobre el espejo del patio {F} aún deja cada primavera una taza de té tibio.",
		"chronicler": "Sus diarios finales son editados y copiados en todo el imperio como testimonio de una ternura capaz de abrazar el sacrificio supremo. Al pie de la última página escrita de su puño y letra se lee únicamente: «Perdóname por hacerte llorar, {F}.»",
		"hearthkeeper": "Incluso convertida en constelación eterna, {D} se negó a partir sin dejar asegurada la mansión, las rentas y la paz de su hogar mortal. Cada Solsticio de Invierno, una tibieza inexplicable envuelve las brasas de la chimenea de {F} hasta el amanecer.",
		"wanderer": "Su paso por el mundo fue breve como un cometa de invierno, pero su estela dorada permanece tendida sobre todas las rutas que un día soñó recorrer. Cuando el viento del norte mueve las cortinas de la casa, {F} sonríe entre lágrimas sabiendo que el cielo es suyo."
	},
	"branch_eclipse": {
		"sovereign": "Con la corte imperial ardiendo a sus pies en llamas violáceas, {D} se sienta sobre el trono destrozado como soberana absoluta de la Noche Eterna. Sus antiguos preceptores suplican clemencia en el mármol, mientras {F} carga con el peso amargo de no haberla detenido antes de la ruptura.",
		"marshal": "El eclipse eterno forja en {D} un arma invencible de rabia y acero cósmico que barre cada fortaleza del continente. Los ejércitos desertan apenas ven su silueta púrpura en la colina, y el viejo patio donde entrenó con {F} yace convertido en ceniza helada.",
		"archmage": "Rotas todas las prohibiciones y sellos éticos del Observatorio, {D} transforma la Torre de Cristal en ciudadela de saber prohibido. Invoca cometas a voluntad bajo un cielo sin sol, mientras los viejos cuadernos familiares de {F} arden lentamente en la chimenea vacía.",
		"weaver": "Al estallar los relojes divinos, {D} dobla la gravedad y el tiempo del reino entero bajo su puño violáceo. Los días ya no siguen el sol sino su humor cambiante, dejando a {F} atrapado entre recuerdos de una niña que alguna vez temía a las tormentas.",
		"oracle": "Con el altar dorado reducido a polvo negro, {D} funda un culto severo que venera la verdad brutal del Eclipse por encima de toda piedad. Su voz hiela la sangre de las multitudes, rota apenas una milésima de segundo cuando distingue el rostro cansado de {F} entre la niebla.",
		"alchemist": "Consumida por la saturación y los experimentos sin freno del Crisol, {D} remodela los hornos de la capital para destilar quimeras estelares. El olor a azahar del jardín desapareció para siempre bajo humo violeta que {F} ya no logra disipar.",
		"muse": "El Gran Anfiteatro vuelve a iluminarse solo bajo reflectores púrpuras mientras la voz irresistible de {D} sume a los nobles en trance. Quienes antaño la juzgaron se arrodillan llorando ante su canto, aunque en su mirada no queda sino el vacío que {F} intenta inútilmente alcanzar.",
		"pathfinder": "No hubo muralla ni cordillera capaz de frenar el avance de {D} una vez que la sombra primordial desbordó el Horizonte Quebrado. Las provincias fronterizas quedan sumergidas en crepúsculo perpetuo mientras {F} cabalga tras sus huellas buscando aún rescatar un fragmento de su alma.",
		"shadow": "Toda Aethelgard aprende a susurrar con terror en la oscuridad, sabiendo que los ojos de {D} están en cada espejo y canal de agua. Los corruptos que persiguieron su infancia desaparecen sin rastro, y solo la vieja mansión de {F} permanece intocable por un decreto mudo.",
		"abyssal_warden": "El Sello desaparece por completo y {D} y la furia desatada de Nyx-Aethel se funden en una sola entidad devastadora. Ningún emisario celeste sobrevive para contar la derrota de la Diosa, pero en la noche eterna {F} sigue llamándola por el nombre cariñoso de su niñez.",
		"chronicler": "{D} arranca las páginas laudatorias de la vieja nobleza para escribir en su lugar la historia implacable de la hipocresía solar. Quien sobrevive al eclipse lee un relato amargo donde ni héroes ni dioses quedan absueltos ante la verdad de lo que la rompieron.",
		"hearthkeeper": "De toda la tragedia que apagó el sol de Aethelgard, lo más desgarrador yace en silencio dentro de la mansión cerrada. A veces, al caer la madrugada púrpura, la silueta de {D} permanece tras la verja mirando la ventana de {F} sin atreverse a llamar a la puerta.",
		"wanderer": "Sin trono que quiera reclamar ni hogar al que sepa volver, {D} cruza los cielos destrozados como un cometa sombrío que oscurece toda comarca a su paso. {F} envejece cuidando una casa silenciosa, negándose hasta el último suspiro a cerrar el portón con llave."
	}
}

func compose_matrix_ending(branch_id: String, vocation_id: String) -> Dictionary:
	var title: String = str(MATRIX_TITLES.get(branch_id, {}).get(vocation_id, "Destino de las Estrellas"))
	var d_name: String = GameState.daughter_name
	var f_name: String = GameState.father_name
	var raw_prose: String = str(MATRIX_EPILOGUES.get(branch_id, {}).get(vocation_id, ""))
	var summary: String = raw_prose.replace("{D}", d_name).replace("{F}", f_name)

	# Matiz dinámico según el estilo de crianza del padre, obras cívicas e hitos de la mansión
	var extras: Array[String] = []
	if GameState.civic_investments.size() >= 3:
		extras.append("Las fundaciones cívicas financiadas por %s durante aquellos años sostienen el nuevo equilibrio desde los cimientos de la capital." % f_name)
	elif GameState.unlocked_synergies.size() >= 2:
		extras.append("Sus múltiples Maestrías de Prestigio despertadas en vida se estudian ya como proezas únicas de esta generación.")
	var max_wing: int = 1
	for wk in GameState.estate_levels.keys():
		max_wing = maxi(max_wing, int(GameState.estate_levels[wk]))
	if max_wing >= 6:
		extras.append("La propia mansión Solar, elevada por %s a obra arquitectónica de primer orden, permanece como emblema de aquel legado." % f_name)
	if not extras.is_empty():
		summary += "\n\n" + extras[0]

	return {
		"id": "%s__%s" % [branch_id, vocation_id],
		"title": title,
		"summary": summary
	}

func _evaluate_bonds_vector(branch_id: String) -> Dictionary:
	var best_id: String = ""
	var best_weight: int = -999
	var nemesis_id: String = ""
	var worst_aff: int = 999

	for npc_id in RelationshipManager.NPC_ORDER:
		if not RelationshipManager.is_available(npc_id):
			continue
		var c: Dictionary = RelationshipManager.state.get(npc_id, {})
		var aff: int = int(c.get("affection", 0))
		var res: int = int(c.get("respect", 0))
		var spk: int = int(c.get("spark", 0))
		var weight: int = aff + int(res * 0.5) + spk * 2
		if weight > best_weight:
			best_weight = weight
			best_id = npc_id
		if aff <= -40 and aff < worst_aff:
			worst_aff = aff
			nemesis_id = npc_id

	var primary_status: String = "Camino Solitario"
	var primary_name: String = "Ningún vínculo dominante"
	var bond_text: String = "%s caminó los ocho años centrada en su propio destino y en el hogar junto a ti, sin atar su corazón a las facciones de la capital." % GameState.daughter_name
	var bond_kind: String = "none"

	if best_id != "":
		var data: Dictionary = RelationshipManager.get_data(best_id)
		primary_name = str(data.get("name", best_id))
		primary_status = RelationshipManager.get_relationship_status_title(best_id)
		var c: Dictionary = RelationshipManager.state[best_id]
		var aff: int = int(c["affection"])
		var res: int = int(c["respect"])
		var spk: int = int(c["spark"])

		if aff >= 65 and res >= 55 and spk >= 60 and RelationshipManager.romance_available(best_id):
			bond_kind = "romance"
			bond_text = _compose_companion_epilogue(best_id, "romance", branch_id)
		elif aff < 20 and spk >= 45 and res >= 45 and RelationshipManager.romance_available(best_id):
			bond_kind = "tension"
			bond_text = _compose_companion_epilogue(best_id, "tension", branch_id)
		elif aff >= 50:
			bond_kind = "friend"
			bond_text = _compose_companion_epilogue(best_id, "friend", branch_id)
		elif best_id != "" and nemesis_id == "":
			bond_kind = "acquaintance"
			bond_text = "Entre todas las figuras de Aethelgard, fue [b]%s[/b] (%s) quien dejó una huella más nítida en la juventud de %s, recordando siempre las largas conversaciones vividas bajo el amparo de %s." % [primary_name, primary_status, GameState.daughter_name, GameState.father_name]

	var nemesis_text: String = ""
	var nemesis_name: String = ""
	if nemesis_id != "":
		nemesis_name = str(RelationshipManager.get_data(nemesis_id).get("name", nemesis_id))
		if nemesis_id == "mirari":
			nemesis_text = "✦ Némesis — %s: Incapaz de perdonar las afrentas al orden solar, Mirari derramó lágrimas heladas y entonó el «Canto de Clausura» junto a los paladines antes de que el Solsticio sellara su fractura definitiva." % nemesis_name
		elif nemesis_id == "vespera":
			nemesis_text = "⚔ Némesis — %s: Su rivalidad de acero culminó en un duelo juramentado bajo la luna llena; incluso tras caer derrotada, Vespera prometió no olvidar jamás aquella hoja." % nemesis_name
		elif nemesis_id == "lyra":
			nemesis_text = "❀ Némesis — %s: El desdén en los salones de alabastro se transformó en guerra abierta; Lady Lyra utilizó todo el peso de su casa para cerrar las puertas de la corte tras el Solsticio." % nemesis_name
		elif nemesis_id == "caelum":
			nemesis_text = "⚡ Némesis — %s: Un contrato roto y cicatrices sin sanar los enfrentaron filo contra filo en los muros de Aethelgard; Caelum juró saldar cuentas allá donde vuelvan a cruzarse." % nemesis_name
		else:
			nemesis_text = "☠ Némesis — %s: La hostilidad acumulada convirtió antiguos encuentros en una fractura irreparable durante la crisis de los veinte años." % nemesis_name

	return {
		"primary_id": best_id,
		"primary_name": primary_name,
		"status": primary_status,
		"kind": bond_kind,
		"text": bond_text,
		"nemesis_id": nemesis_id,
		"nemesis_name": nemesis_name,
		"nemesis_text": nemesis_text
	}

func _compose_companion_epilogue(npc_id: String, mode: String, branch_id: String) -> String:
	var d_name: String = GameState.daughter_name
	var f_name: String = GameState.father_name
	var sac: bool = (branch_id == "branch_sacrifice")
	var ecl: bool = (branch_id == "branch_eclipse")
	var dei: bool = (branch_id == "branch_deicide")
	var dual: bool = (branch_id == "branch_dual_star")
	var pair: bool = (mode == "romance" or mode == "tension")
	var tense: bool = (mode == "tension")

	match npc_id:
		"cassian":
			if sac:
				return "[b]Cassian[/b] rechazó cada alianza dinástica tras el ascenso de %s y convirtió la Sala de Alabastro en un memorial vivo. Cada invierno deja el protocolo real para cenar en silencio con %s junto a la chimenea, compartiendo los recuerdos de quien iluminó sus vidas." % [d_name, f_name]
			if ecl:
				if pair:
					return "Incluso cuando la noche púrpura cubrió palacio, el Príncipe [b]Cassian[/b] se negó a abandonar a %s ni a traicionarla ante los paladines. Entre las ruinas del trono antiguo, él y %s siguen siendo las únicas dos voces humanas capaces de hacerla bajar la espada." % [d_name, f_name]
				return "Atrapado entre la corona hecha cenizas y su antigua lealtad, [b]Cassian[/b] intenta proteger los distritos civiles mientras ayuda en secreto a %s a buscar un camino de regreso hacia %s." % [f_name, d_name]
			if pair:
				var tone: String = "Entre discusiones políticas punzantes y pactos sellados a media voz" if tense else "Con ternura serena frente a toda la corte de Alabastro"
				var era: String = "de la nueva República Real" if dei else ("bajo la armonía de la Estrella Dual" if dual else "en un reino renovado desde sus cimientos")
				return "%s, el Príncipe Heredero [b]Cassian[/b] renunció a las intrigas dinásticas para tomar la mano de %s %s. En la intimidad de la mansión, nunca olvidó pedir formalmente la bendición de %s, a quien aún trata como su primer maestro de estado y suegro." % [tone, d_name, era, f_name]
			return "El Príncipe [b]Cassian[/b] mantuvo una lealtad férrea hacia %s y la casa de %s incluso en los consejos más tensos del Senado. Su amistad se traduce en protección institucional duradera y visitas discretas donde la política queda fuera de la puerta." % [d_name, f_name]

		"vespera":
			if sac:
				return "[b]Dama Vespera[/b] montó guardia sin relevo al pie del Santuario el día del ascenso y juró custodiar el honor de %s en la tierra. Cada primavera visita el patio de armas de %s para entrenar juntos al alba, en homenaje mudo a la compañera que nunca cayó ante acero mortal." % [d_name, f_name]
			if ecl:
				if pair:
					return "Leal hasta el fin a la única oponente que doblegó su orgullo, [b]Vespera[/b] empuña su lanza a la diestra de la Emperatriz del Eclipse. Solo cuando ambos pasan frente a la mansión de %s permite que %s descanse la armadura por unas horas." % [f_name, d_name]
				return "Frente al abismo abierto, [b]Vespera[/b] alzó las murallas de Val-Astra para contener los estragos del eclipse, enviando mensajeros constantes a %s con la esperanza de enfrentar juntos el día en que %s vuelva en sí." % [f_name, d_name]
			if pair:
				var start_v: String = "Cada choque de espadas cargaba un desafío que ninguno quería perder" if tense else "Después de años midiendo fuerzas bajo lluvia y sol"
				return "%s, hasta que [b]Dama Vespera de Val-Astra[/b] apoyó su lanza junto a la de %s para compartir techo y estandarte. En las tardes libres discute tácticas frente al tablero con %s, admitiendo entre risas que solo él supo forjar una guerrera a su altura." % [start_v, d_name, f_name]
			return "[b]Dama Vespera[/b] se convirtió en hermana de armas incondicional de %s y en invitada fija de la mesa de %s. Cuando los duelos terminan, su lealtad hacia ambos vale más que cualquier regimiento del imperio." % [d_name, f_name]

		"soren":
			if sac:
				return "[b]Soren de Caelum[/b] dedicó toda la Torre del Astrolabio a documentar el resplandor constante que %s dejó en el cielo. Sus notas científicas terminan siempre dedicadas a %s, el padre que le enseñó que los números jamás explican el valor de una vida entregada por amor." % [d_name, f_name]
			if ecl:
				return "Horrorizado pero terco ante el eclipse violáceo, [b]Soren[/b] encierra su astrolabio junto a los archivos de %s noche tras noche. No busca destruir a %s sino calcular la ecuación exacta capaz de devolverle el calor humano que compartieron en las aulas." % [f_name, d_name]
			if pair:
				var style_s: String = "Entre debates febriles sobre efemérides donde ninguno daba su brazo a torcer" if tense else "Entre madrugadas tranquilas trazando órbitas compartidas"
				var res_s: String = "las cátedras de la nueva República" if dei else "los observatorios abiertos de la capital"
				return "%s, [b]Soren[/b] y %s acabaron fundiendo bibliotecas enteras en un hogar compartido junto a %s. Mientras ordenan telescopios nuevos, %s insiste en presentar sus resultados a %s con el respeto nervioso de un yerno que quiere estar a la altura del Héroe." % [style_s, d_name, res_s, "Soren", f_name]
			return "[b]Soren[/b] honró el legado de investigación que compartió con %s y %s abriendo las bóvedas del saber a todo el reino. Cada avance científico de Caelum conserva la firma de los tres en su portada." % [d_name, f_name]

		"kaelen":
			if sac:
				return "[b]Kaelen[/b] abandonó el tráfico de los canales para abrir una ruta de ayuda silenciosa hacia los hospicios que %s amaba. A veces deja cajas de té exótico en la puerta trasera de %s sin pedir agradecimiento, recordando juntos a la amiga que iluminó sus noches." % [d_name, f_name]
			if ecl:
				return "Incluso bajo el dominio sombrío del eclipse, [b]Kaelen[/b] mantiene abiertos los túneles secretos para poner a salvo inocentes y traerle a %s noticias reales sobre %s. Sus bromas nacen ya cansadas, pero jamás soltó la lealtad hacia la familia." % [f_name, d_name]
			if pair:
				var tone_k: String = "Después de mil piques sobre botines y contratos donde ninguno fiaba su sombra" if tense else "Dejando atrás los muelles clandestinos y las deudas viejas"
				return "%s, [b]Kaelen[/b] entregó las llaves de los canales para correr hacia horizontes libres junto a %s. Aunque al principio miraba de reojo la reputación severa de %s, hoy pasa las veladas jugando a los dados con su suegro entre carcajadas y mapas." % [tone_k, d_name, f_name]
			return "[b]Kaelen[/b] siguió siendo el contacto más astuto y leal de %s en toda la ciudad baja, e incluso %s acabó apreciando la eficacia implacable con la que aquel antiguo contrabandista protegía a su hija." % [d_name, f_name]

		"mirari":
			if sac:
				return "Con lágrimas serenas en el rostro, la Suma Oráculo [b]Mirari[/b] ofició el himno final de %s sin permitir que la Corte convirtiera su memoria en mercancía política. Desde entonces visita a %s cada cambio de luna para rezar en silencio junto al viejo reloj del vestíbulo." % [d_name, f_name]
			if ecl:
				return "Mientras el Santuario antiguo colapsa bajo nubes carmesí, [b]Mirari[/b] camina descalza hacia las ruinas buscando la chispa compasiva de %s. Reúne a su lado a %s en plegarias que mezclan duelo paternal y fe terca en la redención." % [d_name, f_name]
			if pair:
				var tone_m: String = "Tras cruzar dudas lacerantes entre el voto sagrado y el deseo humano" if tense else "Al descubrir que la luz verdadera nacía de la vida compartida"
				return "%s, [b]Mirari[/b] dejó los velos rígidos del altar para entrelazar su vida con la de %s tras el Solsticio. Juntas reciben a menudo a %s bajo los cerezos del jardín, agradeciendo al Héroe haberles enseñado a no temer a la felicidad mortal." % [tone_m, d_name, f_name]
			return "La sacerdotisa [b]Mirari[/b] se alzó como voz de compasión dentro del Santuario, defendiendo frente a toda sospecha la integridad de %s y el respeto ganado a pulso por %s." % [d_name, f_name]

		"zephyr":
			if sac:
				return "Antes de que el Sello se cerrara para siempre, [b]Zephyr[/b] recogió en un pequeño cristal azul el último suspiro humano de %s y lo depositó en manos de %s. «Mientras quede luz en esa palma», prometió en voz baja, «ni el tiempo borrará su nombre»." % [d_name, f_name]
			if ecl:
				return "Unido sin freno a la furia de la ruptura, [b]Zephyr[/b] envuelve a %s en un abrazo de sombras y estrellas rotas que aísla la ciudad entera. Solo en las madrugadas silenciosas vuelve el rostro hacia la mansión de %s, sintiendo una nostalgia humana que aprendió demasiado tarde." % [d_name, f_name]
			if pair:
				var bridge_z: String = "Después de mil años de desconfianza hacia todo ser de luz estática" if tense else "Tras desarmar juntos cada cerrojo de su antigua cárcel"
				return "%s, [b]Zephyr[/b] —el Lucero del Cambio— eligió quedarse en la tierra para caminar y amar como igual junto a %s. Con la bendición serena de %s en la mesa familiar, aprende cada día el asombro de una sopa caliente, una broma torpe y un mañana que nunca está escrito." % [bridge_z, d_name, f_name]
			return "[b]Zephyr[/b] se convirtió en un compañero insustituible y respetuoso para la casa de %s, descubriendo junto a %s que el cambio no necesita destruir el mundo cuando existe un hogar dispuesto a escuchar." % [f_name, d_name]

		"lyra":
			if sac:
				return "Detrás del abanico cerrado para ocultar las lágrimas, [b]Lady Lyra[/b] empleó toda la fortuna de Meridia para blindar el legado cívico y el buen nombre de %s frente al Senado. Cada gala anual abre con una silla vacía junto a %s, en recuerdo de la única amiga que nunca llevó máscara." % [d_name, f_name]
			if ecl:
				return "Cuando los salones de alabastro cayeron ante la noche eterna, [b]Lady Lyra[/b] no huyó de la capital: reunió archivos y suministros junto a %s para sostener a los barrios exteriores, vigilando el horizonte por si %s aún recuerda los viejos valses del Conservatorio." % [f_name, d_name]
			if pair:
				var tone_l: String = "Tras años de esgrima verbal y miradas desafiantes en cada recital" if tense else "Dejando atrás los muros fríos del protocolo noble"
				return "%s, [b]Lady Lyra de Meridia[/b] bajó la guardia para entrelazar vida, fortuna y escenario con %s sin temor a murmuraciones. En la mansión Solar se gana pronto el afecto de %s, celebrando junto al viejo héroe cómo dos familias reconstruyeron la corte desde la honestidad." % [tone_l, d_name, f_name]
			return "[b]Lady Lyra[/b] salvó el prestigio de la Casa Meridia y se alzó como aliada política irrompible de %s, colaborando mano a mano con %s para frenar cualquier edicto injusto del Senado." % [d_name, f_name]

		"caelum":
			if sac:
				return "El mercenario conocido como [b]Caelum 'El Perro Gris'[/b] clavó su vieja daga frente al cenotafio de %s y no volvió a cobrar por ninguna sangre ajena. Desde entonces patrulla en silencio las inmediaciones de la finca de %s, como un guardián viejo que cuida la paz de la única familia que le importó." % [d_name, f_name]
			if ecl:
				return "Mientras las columnas del orden solar caían, [b]Caelum[/b] cubrió la retirada de civiles en las murallas y llevó hasta la puerta de %s noticias discretas sobre los pasos de %s en la sombra. Incluso el Perro Gris sabe que hay juramentos que el eclipse no pudo quemar." % [f_name, d_name]
			if pair:
				var tone_c: String = "Después de tantos contratos disputados entre gruñidos y acero cruzado" if tense else "Quemando su último pergamino de gremio al pie de la hoguera"
				return "%s, [b]Caelum 'El Perro Gris'[/b] cambió la vida errante por el calor leal de un hogar junto a %s. Con %s comparte largas charlas nocturnas junto al fuego sobre campañas antiguas, encontrando por fin en ambos un motivo para echar raíces." % [tone_c, d_name, f_name]
			return "[b]Caelum[/b] levantó su propia compañía de escoltas honestos junto a %s y se ganó el respeto franco de %s como el hombre más fiable de toda frontera de Aethelgard." % [d_name, f_name]
	return ""

func _evaluate_rivals_vector() -> Dictionary:
	var beaten: int = 0
	var lines: Array[String] = []
	for rid in RivalMirror.RIVAL_ORDER:
		var rd: Dictionary = RivalMirror.RIVAL_DATA[rid]
		var st: Dictionary = RivalMirror.get_standing(rid)
		var win: bool = int(st["diff"]) >= 0
		if win:
			beaten += 1
		lines.append("%s %s: %s (%d vs %d)" % [
			AstralTheme.G_CHECK if win else AstralTheme.G_CROSS,
			rd["name"], "Superado" if win else "Invicto", int(st["mine"]), int(st["theirs"])
		])
	return {"beaten": beaten, "total": RivalMirror.RIVAL_ORDER.size(), "lines": lines}

func _evaluate_politics_vector(branch_id: String, vocation_id: String, bond_info: Dictionary) -> Dictionary:
	var title: String = ""
	var text: String = ""
	var soren_aff: int = int(RelationshipManager.state.get("soren", {}).get("affection", 0))
	var cassian_aff: int = int(RelationshipManager.state.get("cassian", {}).get("affection", 0))
	var f_name: String = GameState.father_name

	match branch_id:
		"branch_deicide":
			if soren_aff >= 45 or GameState.erudicion >= 450 or GameState.civic_investments.has("civic_academy_chair"):
				title = "República Astronómica de Caelum"
				text = "Sin el yugo de la Eternidad Inmóvil, los senadores ilustrados y el Observatorio instauran la República Astronómica: el conocimiento y los astrolabios pasan a servir a todos los ciudadanos."
			else:
				title = "Mancomunidad Libre del Horizonte"
				text = "El Imperio Solar abre sus fronteras por primera vez en siglos; las provincias y los gremios firman una Carta del Tiempo Libre donde cada generación decide su rumbo."
		"branch_dual_star":
			title = "Monarquía Iluminada de los Dos Astros"
			text = "Aethelgard entra en una edad dorada de equilibrio entre la tradición humana y el cambio estelar. Los antiguos templos reescriben sus tratados para honrar la armonía dual."
		"branch_mortal":
			if str(bond_info.get("primary_id", "")) == "cassian" and cassian_aff >= 55:
				title = "Reino Renovado de la Corona Mortal"
				text = "Con la casa del Héroe unida a la familia real, Aethelgard inicia una era de prosperidad humanista centrada en el bienestar de los súbditos."
			elif GameState.civic_investments.has("civic_senate_seat") or vocation_id == "sovereign":
				title = "Consejo Civil de las Tres Casas"
				text = "El Senado reforma sus viejos privilegios bajo la influencia directa de la familia del Héroe, convirtiendo las rutas comerciales y la ley civil en escudo de la ciudadanía."
			else:
				title = "Principado Soberano de Aethelgard"
				text = "Aethelgard conserva sus leyes y orgullo histórico, aunque el Senado y el pueblo jamás olvidan que la verdadera fuerza del reino nació de un hogar humilde."
		"branch_sacrifice":
			title = "Teocracia Serena de la Palma"
			text = "El Santuario consolida su autoridad sobre el reino bajo la luz constante de la nueva constelación. La paz reina en las calles, aunque marcada por una quietud melancólica."
		_:
			title = "Dominio del Eclipse Carmesí"
			text = "La Corte Imperial se disuelve en cenizas doradas. Bajo cielos eternamente violáceos, solo los más fuertes o leales a la sombra sobreviven en las ruinas de la vieja capital."

	var legacy_parts: Array[String] = []
	if GameState.civic_investments.has("civic_orphanage_endowment"):
		legacy_parts.append("el Hospicio de la Aurora")
	if GameState.civic_investments.has("civic_aqueduct_charter"):
		legacy_parts.append("las obras de los Acueductos Altos")
	if GameState.civic_investments.has("civic_academy_chair"):
		legacy_parts.append("la Cátedra de Astrometría")
	if GameState.civic_investments.has("civic_senate_seat"):
		legacy_parts.append("su escaño reformista en el Consejo")
	if GameState.civic_investments.has("civic_obsidian_sanctuary"):
		legacy_parts.append("el Bastión del Solsticio")
	if not legacy_parts.is_empty():
		text += " El legado cívico levantado por %s (%s) perdura como pilar de la nueva ciudad." % [f_name, ", ".join(legacy_parts)]
	return {"title": title, "text": text}

func _evaluate_father_testament(branch_id: String, bond_info: Dictionary) -> Dictionary:
	var aff: int = GameState.affection
	var anchor: int = GameState.human_anchor
	var stress: int = GameState.stress
	var rep: int = GameState.father_reputation
	var unseals: int = ExplorationCombat.unseal_used_count
	var sat: int = GameState.astral_saturation
	var d_name: String = GameState.daughter_name
	var f_name: String = GameState.father_name

	var verdict: String = ""
	var letter_body: String = ""

	if branch_id == "branch_eclipse":
		verdict = "Padre en la Tormenta (Juicio Agridulce)"
		letter_body = "«%s... Sé que en algún momento intentaste ser un escudo, pero el peso de las heridas y las grietas del Sello me alcanzó antes que tu abrazo (%d veces forzamos la oscuridad en batalla). No te odio, Padre, pero ya no puedo volver a la niña que fuimos en la mansión.»" % [f_name, unseals]
	elif aff >= 80 and anchor >= 70 and stress <= 55:
		verdict = "Héroe y Padre Inquebrantable (Calificación Suprema)"
		letter_body = "«Querido Padre %s: Cuando la Diosa me dejó en tus brazos hace ocho años, esperaban que me criaras como un instrumento o una jaula. En cambio me diste hogar, pan caliente junto a la chimenea y el derecho a elegir quién soy. Si volvieran a darme mil vidas bajo las estrellas, te volvería a elegir como padre en todas ellas.»" % f_name
	elif aff >= 60 and rep >= 70:
		verdict = "Mentor de Luz y Gloria"
		letter_body = "«Padre %s: Fuiste firme cuando el entrenamiento dolía y exigente ante la Corte, pero nunca soltaste mi mano en las noches difíciles. Todo Aethelgard pronuncia nuestro apellido con respeto, y ese orgullo también lleva tu cicatriz y tu ejemplo.»" % f_name
	elif sat >= 60 or unseals >= 3:
		verdict = "Custodio que Arriesgó el Abismo"
		letter_body = "«%s: Muchas veces sentí arder el Crisol o romperse mis cadenas para sobrevivir a tus planes. Llegamos vivos a los veinte años y admiro tu audacia, aunque todavía despierto buscando el calor de las tardes sencillas sin alquimia ni peligro.»" % f_name
	else:
		verdict = "Distancia que Aprendió a Perdonar"
		letter_body = "«Padre %s: Nuestros silencios en la mansión pesaron tanto como mis clases en la capital. No siempre supimos entendernos, pero al mirar atrás hasta la primera primavera, sé que hiciste lo que creíste necesario para mantenernos en pie.»" % f_name

	if str(bond_info.get("kind", "")) == "romance":
		letter_body += "\n\n(P. D.: %s te manda sus respetos; promete cuidar de mí tanto como tú me enseñaste a cuidar de este mundo.)" % str(bond_info.get("primary_name", ""))

	return {"verdict": verdict, "letter": letter_body}
