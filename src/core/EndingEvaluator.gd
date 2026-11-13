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

func _evaluate_vocation() -> Dictionary:
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

	var scores: Dictionary = {
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

	var best_id: String = "wanderer"
	var best_val: int = -1
	for vid in VOCATION_ORDER:
		var val: int = int(scores.get(vid, 0))
		if val > best_val:
			best_val = val
			best_id = vid

	var vdata: Dictionary = VOCATIONS[best_id].duplicate()
	vdata["id"] = best_id
	vdata["score"] = best_val
	return vdata

func compose_matrix_ending(branch_id: String, vocation_id: String) -> Dictionary:
	var title: String = str(MATRIX_TITLES.get(branch_id, {}).get(vocation_id, "Destino de las Estrellas"))
	var d_name: String = GameState.daughter_name
	var voc_name: String = str(VOCATIONS.get(vocation_id, {}).get("name", "Hija de la Estrella"))
	var summary: String = ""

	match branch_id:
		"branch_mortal":
			summary = "Libre al fin de la deuda celeste gracias a la fuerza de su corazón humano, %s abraza su vida como [b]%s[/b]. En las calles doradas de Aethelgard, su nombre ya no inspira temor ni reverencia distante, sino la certeza de que un alma mortal puede vencer al destino escrito en los astros." % [d_name, voc_name]
		"branch_dual_star":
			summary = "Unida en pacto voluntario con Zephyr, %s asciende en una forma nunca vista y ejerce como [b]%s[/b]. Portadora de luz humana y cambio cósmico por igual, transforma las viejas leyes del reino con la serenidad de quien conversa con el propio firmamento." % [d_name, voc_name]
		"branch_deicide":
			summary = "Tras derrocar el dogma de la Eternidad Inmóvil junto a ti y sus compañeros, %s se convierte en leyenda viva bajo el título de [b]%s[/b]. El Tiempo vuelve a fluir sin cadenas, y su historia será cantada como la noche en que padre e hija reescribieron la bóveda celeste." % [d_name, voc_name]
		"branch_sacrifice":
			summary = "Al aceptar la ofrenda sagrada del Santuario, el espíritu de %s queda grabado para siempre en el cielo como [b]%s[/b]. Aunque el mundo sigue girando en calma bajo su luz constante, cada Solsticio de Invierno deja en el observatorio una brisa tibia que solo tú reconoces." % [d_name, voc_name]
		_:
			summary = "Al quebrarse las cadenas del Sarcófago en una tormenta violeta, %s emerge sobre las ruinas del orden antiguo como [b]%s[/b]. Temida por nobles y heraldos por igual, gobierna una era donde la luna de eclipse jamás termina de ponerse." % [d_name, voc_name]

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
			bond_text = "Entre todas las figuras de Aethelgard, fue [b]%s[/b] (%s) quien dejó una huella más nítida en la juventud de %s." % [primary_name, primary_status, GameState.daughter_name]

	var nemesis_text: String = ""
	var nemesis_name: String = ""
	if nemesis_id != "":
		nemesis_name = str(RelationshipManager.get_data(nemesis_id).get("name", nemesis_id))
		if nemesis_id == "mirari":
			nemesis_text = "✦ Némesis — %s: Incapaz de perdonar las afrentas al orden solar, Mirari derramó lágrimas heladas y entonó el «Canto de Clausura» junto a los paladines antes de que el Solsticio sellara su fractura definitiva." % nemesis_name
		elif nemesis_id == "vespera":
			nemesis_text = "⚔ Némesis — %s: Su rivalidad de acero culminó en un duelo juramentado bajo la luna llena; incluso tras caer derrotada, Vespera prometió no olvidar jamás aquella hoja." % nemesis_name
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
	var sac: bool = (branch_id == "branch_sacrifice")
	match npc_id:
		"cassian":
			if mode == "romance" or mode == "tension":
				return "El Príncipe Heredero [b]Cassian[/b] rechazó los matrimonios dinásticos impuestos por la Corte para sostener la mano de %s ante el trono." % d_name if not sac else "[b]Cassian[/b] guardó para siempre la corona solar sin casarse jamás, mirando cada noche el lucero donde reposa %s." % d_name
			return "[b]Cassian[/b] se mantuvo como aliado leal en el palacio real, asegurando el respeto de la corona hacia el nombre de tu casa."
		"vespera":
			if mode == "romance" or mode == "tension":
				return "Entre duelos bajo la lluvia y juramentos de honor, [b]Dama Vespera[/b] bajó finalmente la guardia y eligió compartir espada y destino junto a %s." % d_name
			return "[b]Dama Vespera de Val-Astra[/b] se convirtió en hermana de armas incondicional de %s, cubriendo su flanco en cada encrucijada." % d_name
		"soren":
			if mode == "romance" or mode == "tension":
				return "[b]Soren de Caelum[/b] y %s demostraron juntos que la razón humana puede descifrar —y amar— lo que el cielo pretendía mantener oculto." % d_name
			return "[b]Soren[/b] dedicó la Gran Biblioteca y sus astrolabios a descifrar los misterios junto a %s como compañeros de estudio irreemplazables." % d_name
		"kaelen":
			if mode == "romance" or mode == "tension":
				return "El contrabandista [b]Kaelen[/b] dejó atrás las sombras de los canales para correr hacia horizontes libres junto a %s entre bromas y acero." % d_name
			return "[b]Kaelen[/b] siguió siendo el contacto más astuto y fiel de %s, siempre un paso por delante de los espías imperiales." % d_name
		"mirari":
			if mode == "romance" or mode == "tension":
				return "La Oráculo [b]Mirari[/b] eligió la fe viva del corazón antes que los dogmas de mármol, permaneciendo al lado de %s tras el Solsticio." % d_name
			return "La sacerdotisa [b]Mirari[/b] custodió con oraciones sinceras la paz interior de %s frente a los embates del Templo." % d_name
		"zephyr":
			if mode == "romance" or mode == "tension":
				return "[b]Zephyr[/b] —el Lucero del Cambio— dejó atrás mil años de soledad tras el cristal para vivir cada amanecer humano al lado de %s." % d_name
			return "[b]Zephyr[/b] y %s sellaron un pacto de confianza mutua sin cadenas, demostrando que ningún destino debe ser prisión." % d_name
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

func _evaluate_politics_vector(branch_id: String, _vocation_id: String, bond_info: Dictionary) -> Dictionary:
	var title: String = ""
	var text: String = ""
	var soren_aff: int = int(RelationshipManager.state.get("soren", {}).get("affection", 0))
	var cassian_aff: int = int(RelationshipManager.state.get("cassian", {}).get("affection", 0))

	match branch_id:
		"branch_deicide":
			if soren_aff >= 45 or GameState.erudicion >= 450:
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
			else:
				title = "Principado Soberano de Aethelgard"
				text = "Aethelgard conserva sus leyes y orgullo histórico, aunque el Senado y el pueblo jamás olvidan que la verdadera fuerza del reino nació de un hogar humilde."
		"branch_sacrifice":
			title = "Teocracia Serena de la Palma"
			text = "El Santuario consolida su autoridad sobre el reino bajo la luz constante de la nueva constelación. La paz reina en las calles, aunque marcada por una quietud melancólica."
		_:
			title = "Dominio del Eclipse Carmesí"
			text = "La Corte Imperial se disuelve en cenizas doradas. Bajo cielos eternamente violáceos, solo los más fuertes o leales a la sombra sobreviven en las ruinas de la vieja capital."
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
