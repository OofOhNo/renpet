extends Node
## Simulador de campaña y pruebas de regresión del núcleo (sin interfaz).
## Uso:  godot --headless --path . res://tools/Simulator.tscn
## Juega 48 turnos con varias estrategias, comprueba invariantes y el ciclo guardar/cargar.

var failures: int = 0
var verbose: bool = true

func check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		print("  [FALLO] ", msg)

func _ready() -> void:
	await get_tree().process_frame
	var strategies: Array[String] = ["equilibrada", "marcial", "erudita", "obrera", "descuidada", "social"]
	for s in strategies:
		play(s)
	test_save_roundtrip()
	test_age_gate()
	test_catalog_integrity()
	print("\n==== RESULTADO: %d fallos ====" % failures)
	get_tree().quit(1 if failures > 0 else 0)

# ------------------------------------------------------------------------------
func pick_agenda(strategy: String) -> Array[String]:
	var age: int = GameState.age
	var a: Array[String]
	match strategy:
		"marcial": a = ["class_armory", "job_caravan", "class_armory"]
		"erudita": a = ["class_astrolabe", "class_astrolabe", "rest_manor"]
		"obrera": a = ["job_sanatorium", "job_clockwork", "job_amphitheater"]
		"descuidada": a = ["job_canals", "job_canals", "job_canals"]
		"social": a = ["class_conservatory", "job_amphitheater", "rest_manor"]
		_: a = ["class_armory", "class_astrolabe", "class_conservatory"]
	# Ajustes realistas de un jugador: descansa si el estrés es alto, trabaja si falta oro
	var out: Array[String] = []
	for i in range(3):
		var id: String = a[i]
		var act: Dictionary = CatalogDB.get_activity(id)
		if GameState.stress >= 70 and strategy != "descuidada":
			id = "rest_manor"
		elif act["cost_or_wage"] < 0 and GameState.gold < 400 and strategy != "descuidada":
			id = "job_sanatorium"
		if age < int(CatalogDB.get_activity(id).get("min_age", 12)):
			id = "rest_manor"
		out.append(id)
	return out

func play(strategy: String) -> void:
	print("\n=== Estrategia: %s ===" % strategy)
	SaveManager.new_game()
	GameState.apply_archetype_bonuses(GameState.HeroArchetype.MARTIAL if strategy == "marcial" else GameState.HeroArchetype.SCHOLAR)
	GameState.prologue_completed = true
	var guard: int = 0
	while not TimeManager.campaign_over and guard < 60:
		guard += 1
		var ag: Array[String] = pick_agenda(strategy)
		for i in range(3):
			TurnExecutor.set_agenda_slot(i, ag[i])
		TurnExecutor.father_plan.clear()
		if strategy == "marcial" or strategy == "obrera":
			TurnExecutor.toggle_father_task("hero_work")
			TurnExecutor.toggle_father_task("diplomacy")
		elif strategy == "descuidada":
			TurnExecutor.toggle_father_task("hero_work")
		else:
			TurnExecutor.toggle_father_task("supervise")
			TurnExecutor.toggle_father_task("investigate")
		# Social: descubrir desconocidos primero y luego profundizar vínculos (3 PS/bimestre)
		if strategy == "social" or TimeManager.current_total_turn % 3 == 0:
			var npc: String = RelationshipManager.NPC_ORDER[TimeManager.current_total_turn % 5]
			if not RelationshipManager.is_known(npc):
				RelationshipManager.meet_candidate(npc)
			if RelationshipManager.can_interact_with(npc):
				var evt: Dictionary = RelationshipManager.get_next_bond_event(npc)
				if evt.get("ok", false):
					var ch: Array = evt["choices"]
					RelationshipManager.apply_bond_event_choice(npc, ch[0])
				else:
					RelationshipManager.interact_with_candidate(npc, "chat")
		# Crisol: asimila lo que tenga si no hay riesgo grave
		if TimeManager.current_total_turn % 4 == 0:
			for mid in GameState.materials_inventory.keys():
				if int(GameState.materials_inventory[mid]) > 0 and CrucibleManager.preview(mid)["sat_after"] < 60:
					CrucibleManager.assimilate(mid)
					break
		if TimeManager.current_total_turn % 8 == 0:
			CrucibleManager.purify_saturation()
		var prev_turn: int = TimeManager.current_total_turn
		var rep: Dictionary = TurnExecutor.resolve_bimester()
		if not rep.get("ok", false):
			# Plan inválido: reposo total
			for i in range(3):
				TurnExecutor.set_agenda_slot(i, "rest_manor")
			rep = TurnExecutor.resolve_bimester()
		check(rep.get("ok", false), "resolve_bimester falló en turno %d: %s" % [prev_turn, rep.get("msg", "")])
		check_invariants("turno %d" % prev_turn)
		if prev_turn % 12 == 0 and verbose:
			print("  T%02d edad %d | oro %d estrés %d sello %d anclaje %d sync %d sat %d | T%d D%d E%d G%d Er%d | rasgos: %s | sinergias: %s" % [
				prev_turn, GameState.age, GameState.gold, GameState.stress, GameState.seal_integrity,
				GameState.human_anchor, GameState.abyssal_sync, GameState.astral_saturation,
				GameState.temple, GameState.destreza, GameState.erudicion, GameState.gracia, GameState.resonancia,
				", ".join(GameState.active_traits), ", ".join(GameState.unlocked_synergies)])
	check(TimeManager.campaign_over, "la campaña no terminó tras 48 turnos")
	check(TimeManager.current_total_turn == 48, "turno final esperado 48, fue %d" % TimeManager.current_total_turn)
	check(Chronicle.letters_archive.size() == 8, "se esperaban 8 cartas anuales, hay %d" % Chronicle.letters_archive.size())
	print("  FIN: oro %d | mutaciones %s | cartas %d | vínculos: %s" % [
		GameState.gold, GameState.active_mutations, Chronicle.letters_archive.size(), _bonds()])
	var eval_res: Dictionary = EndingEvaluator.evaluate_campaign()
	check(eval_res.get("ending_id", "") != "", "EndingEvaluator devolvió ending_id vacío")
	print("  FINAL: %s (%s · %s)" % [eval_res["ending_title"], eval_res["branch"]["short"], eval_res["vocation"]["name"]])

func _bonds() -> String:
	var parts: Array[String] = []
	for n in RelationshipManager.NPC_ORDER:
		var c: Dictionary = RelationshipManager.state[n]
		parts.append("%s %d/%d/%d e%d" % [n, c["affection"], c["respect"], c["spark"], c["stage"]])
	return " ".join(parts)

func check_invariants(tag: String) -> void:
	check(GameState.gold >= 0, "%s: oro negativo %d" % [tag, GameState.gold])
	for k in GameState.STAT_RANGES.keys():
		var v: int = GameState.get_stat(k)
		var b: Array = GameState.STAT_RANGES[k]
		check(v >= int(b[0]) and v <= int(b[1]), "%s: %s fuera de rango (%d)" % [tag, k, v])
	check(GameState.active_traits.size() <= GameState.MAX_ACTIVE_TRAITS, "%s: más de 4 rasgos" % tag)
	if GameState.age < GameState.ROMANCE_MIN_AGE:
		for n in RelationshipManager.NPC_ORDER:
			check(int(RelationshipManager.state[n]["spark"]) == 0, "%s: Chispa romántica antes de los 18 en %s" % [tag, n])

func test_save_roundtrip() -> void:
	print("\n=== Prueba guardar/cargar ===")
	SaveManager.new_game()
	GameState.prologue_completed = true
	TurnExecutor.set_agenda_slot(0, "class_armory")
	TurnExecutor.toggle_father_task("diplomacy")
	TurnExecutor.resolve_bimester()
	TurnExecutor.astrolabe_tuned_this_bimester = true
	check(bool(RelationshipManager.meet_candidate("soren").get("ok", false)), "conocer a Soren debe consumir 1 PS")
	check(bool(RelationshipManager.interact_with_candidate("soren", "chat").get("ok", false)), "conversar tras conocer a Soren")
	var before: String = JSON.stringify(SaveManager.build_payload()["game_state"]) + JSON.stringify(SaveManager.build_payload()["relationships"]) + JSON.stringify(SaveManager.build_payload()["rivals"]) + JSON.stringify(SaveManager.build_payload()["plan"])
	check(SaveManager.save_game(2), "no se pudo guardar en la ranura 2")
	GameState.gold = 1
	TurnExecutor.astrolabe_tuned_this_bimester = false
	RelationshipManager.state["soren"]["affection"] = -99
	RelationshipManager.state["soren"]["known"] = false
	RivalMirror.scores["vespera"] = 5
	var res: Dictionary = SaveManager.load_game(2)
	check(res.get("ok", false), "no se pudo cargar: %s" % res.get("msg", ""))
	var after: String = JSON.stringify(SaveManager.build_payload()["game_state"]) + JSON.stringify(SaveManager.build_payload()["relationships"]) + JSON.stringify(SaveManager.build_payload()["rivals"]) + JSON.stringify(SaveManager.build_payload()["plan"])
	check(before == after, "el estado cargado difiere del guardado")
	check(RelationshipManager.is_known("soren"), "no se restauró el descubrimiento de Soren")
	check(RelationshipManager.social_points_left == 1, "no se restauraron los puntos sociales del bimestre")
	check(TurnExecutor.astrolabe_tuned_this_bimester, "no se restauró la sintonía del astrolabio")
	TurnExecutor.resolve_bimester()
	check(not TurnExecutor.astrolabe_tuned_this_bimester, "la sintonía del astrolabio debería resetearse tras resolver el bimestre")
	SaveManager.delete_slot(2)

func test_age_gate() -> void:
	print("\n=== Prueba regla de edad (romance solo 18+) ===")
	SaveManager.new_game()
	for age in [12, 15, 17]:
		GameState.age = age
		check((GameState.get_secret_tier() == 0) if age == 12 else true, "a los 12 años el giro debe permanecer oculto (tier 0)")
		for n in RelationshipManager.NPC_ORDER:
			RelationshipManager.state[n]["known"] = true
			check(not RelationshipManager.romance_available(n), "romance disponible a los %d con %s" % [age, n])
			RelationshipManager.reset_bimester_flags()
			var r: Dictionary = RelationshipManager.interact_with_candidate(n, "romance")
			check(not r.get("ok", false), "cita romántica aceptada a los %d con %s" % [age, n])
			for stage in [1, 2, 3]:
				var ev: Dictionary = BondEvents.get_event(n, stage)
				for ch in RelationshipManager.get_visible_choices(n, ev):
					check(ch["kind"] != "romance", "elección romántica visible a los %d (%s etapa %d)" % [age, n, stage])
	GameState.age = 18
	check(RelationshipManager.romance_available("soren"), "romance debería estar disponible con Soren a los 18")
	check(not RelationshipManager.romance_available("nadie"), "personaje inexistente")
	GameState.age = 12
	check(not ExplorationCombat.start_expedition(0, "zephyr", "Zephyr").get("ok", false), "Zephyr no debería ser reclutable a los 12")
	check(not EndingEvaluator.get_projected_vocation().is_empty(), "proyección de vocación disponible")

func test_catalog_integrity() -> void:
	print("\n=== Integridad de catálogos ===")
	check(CatalogDB.GIFTS.size() >= 6, "catálogo de obsequios completo")
	for a in CatalogDB.ACTIVITIES:
		for k in a["stats"].keys():
			check(GameState.is_known_stat(k), "actividad %s usa atributo desconocido %s" % [a["id"], k])
		if a.get("rival_id", "") != "":
			check(RivalMirror.RIVAL_DATA.has(a["rival_id"]), "actividad %s: rival inexistente" % a["id"])
		if a.has("loot_item"):
			check(not CatalogDB.get_material(a["loot_item"]).is_empty(), "actividad %s: botín inexistente" % a["id"])
	for m in CatalogDB.COSMIC_MATERIALS:
		check(CatalogDB.MUTATIONS.has(m["mutation"]), "material %s: mutación inexistente" % m["id"])
		for k in m["stats"].keys():
			check(GameState.is_known_stat(k), "material %s usa atributo desconocido %s" % [m["id"], k])
	for t in CatalogDB.FATHER_TASKS:
		for k in t["effects"].keys():
			check(GameState.is_known_stat(k), "tarea %s usa atributo desconocido %s" % [t["id"], k])
	for d in CatalogDB.DIETS:
		for k in d.get("effects", {}).keys():
			check(GameState.is_known_stat(k), "dieta %s usa atributo desconocido %s" % [d["id"], k])
	for vac in CatalogDB.VACATION_RETREATS.values():
		check(GameState.is_known_stat(str(vac.get("stat_key", ""))), "vacación %s usa stat_key desconocido" % str(vac.get("id", "")))
	check(CatalogDB.OUTFITS.size() >= 5, "catálogo de atuendos completo")
	check(CatalogDB.MEMORY_CARDS.size() >= 15, "catálogo de cartas de recuerdo completo")
	for ev in CatalogDB.MICRO_EVENTS:
		for k in ev["effects"].keys():
			check(GameState.is_known_stat(k), "micro-evento %s: atributo desconocido %s" % [ev["id"], k])
		for k in ev.get("effects_trait", {}).keys():
			check(GameState.is_known_stat(k), "micro-evento %s: atributo (rasgo) desconocido %s" % [ev["id"], k])
	for npc in RelationshipManager.NPC_ORDER:
		for stage in [1, 2, 3]:
			var ev: Dictionary = BondEvents.get_event(npc, stage)
			check(not ev.is_empty(), "falta evento %s etapa %d" % [npc, stage])
			var kinds: Array = []
			for ch in ev.get("choices", []):
				kinds.append(ch["kind"])
				for k in ch["stat_effects"].keys():
					check(GameState.is_known_stat(k), "evento %s/%d: atributo desconocido %s" % [npc, stage, k])
			check(kinds.has("friend") and kinds.has("rival") and kinds.has("romance"), "evento %s/%d: faltan ramas" % [npc, stage])
	for t in FireplaceTopics.TOPICS:
		for att in FireplaceTopics.ATTITUDES.keys():
			check(t["stances"].has(att), "tópico %s sin actitud %s" % [t["id"], att])
			for k in t["stances"][att]["effects"].keys():
				check(GameState.is_known_stat(k), "tópico %s/%s: atributo desconocido %s" % [t["id"], att, k])
	var matrix_count: int = 0
	for bid in EndingEvaluator.BRANCH_ORDER:
		check(EndingEvaluator.BRANCHES.has(bid), "falta rama %s" % bid)
		for vid in EndingEvaluator.VOCATION_ORDER:
			check(EndingEvaluator.VOCATIONS.has(vid), "falta vocación %s" % vid)
			var m_res: Dictionary = EndingEvaluator.compose_matrix_ending(bid, vid)
			check(str(m_res.get("title", "")) != "", "falta título matriz %s/%s" % [bid, vid])
			matrix_count += 1
	check(matrix_count == 65, "matriz debería tener 65 finales (5x13), tiene %d" % matrix_count)
