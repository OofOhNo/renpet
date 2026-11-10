extends Node
## Prueba de humo de la interfaz: recorre el flujo completo (creación, ventanas, 48 turnos, escenas, menú).
## Uso: godot --headless --path . res://tools/UISmoke.tscn

var hub: Control
var failures: int = 0

func check(c: bool, msg: String) -> void:
	if not c:
		failures += 1
		print("  [FALLO] ", msg)

func frames(n: int = 3) -> void:
	for i in range(n):
		await get_tree().process_frame

func _ready() -> void:
	await frames()
	SaveManager.pending_load_slot = -1
	hub = load("res://src/scenes/ManorHub.tscn").instantiate()
	add_child(hub)
	await frames(5)
	check(hub._prologue.visible, "el prólogo debería verse en una partida nueva")
	# Recorre las páginas del prólogo y la creación
	for i in range(8):
		hub._prologue._next_page()
		await frames(2)
	check(hub._prologue._daughter_edit != null, "la creación del héroe debería haberse abierto")
	hub._prologue._daughter_edit.text = "Luna"
	hub._prologue._father_edit.text = "Marco"
	hub._prologue._choose(1)
	hub._prologue._confirm()
	await frames(4)
	check(GameState.daughter_name == "Luna" and GameState.prologue_completed, "creación del héroe")
	check(GameState.erudicion >= 170, "bono del arquetipo Sabio")

	for w in ["schedule", "status", "hearth", "crucible", "town"]:
		hub.debug_open_window(w)
		await frames(3)
		check(hub._windows[w].visible, "ventana %s no visible" % w)

	# Chimenea: elegir tópico y actitud
	hub.debug_open_window("hearth")
	await frames(2)
	var topics: Array = Chronicle.get_fireplace_topics()
	check(topics.size() >= 3, "tópicos de chimenea disponibles")
	hub._windows["hearth"]._selected_topic = topics[0]["id"]
	hub._windows["hearth"]._apply_stance(topics[0], "warm")
	await frames(2)
	check(Chronicle.chatted_this_bimester, "charla marcada")

	# Ciudad: apoyo y escena (a los 12 no debe haber elección romántica)
	hub.debug_open_window("town")
	await frames(2)
	hub._windows["town"]._do_action("soren", "support")
	await frames(2)
	RelationshipManager.reset_bimester_flags()
	hub._bond.play("soren")
	await frames(3)
	check(hub._bond.visible, "escena de historia visible")
	var n_btn: int = 0
	for c in _all_buttons(hub._bond):
		if str(c.text).contains("♥"):
			n_btn += 1
	check(n_btn == 0, "no debe haber botón romántico a los 12 años")
	var ch: Array = RelationshipManager.get_next_bond_event("soren")["choices"]
	hub._bond._choose(ch[0])
	await frames(3)
	hub._bond.hide_overlay()

	# Crisol
	hub.debug_open_window("crucible")
	hub._windows["crucible"]._selected = "comet_dust"
	hub._windows["crucible"]._try_assimilate("comet_dust", false)
	await frames(2)

	# Menú de guardado
	hub._menu.open_pause(true)
	await frames(2)
	hub._menu.open_slots(MenuOverlay.Mode.SAVE)
	await frames(2)
	hub._menu._slot_pressed(3)
	await frames(2)
	check(SaveManager.has_save(3), "guardado manual en ranura 3")

	# 48 turnos completos con la interfaz
	var guard: int = 0
	while not TimeManager.campaign_over and guard < 60:
		guard += 1
		if GameState.stress >= 60:
			for i in range(3):
				TurnExecutor.set_agenda_slot(i, "rest_manor")
		elif GameState.gold < 400:
			TurnExecutor.set_agenda_slot(0, "job_sanatorium")
			TurnExecutor.set_agenda_slot(1, "job_sanatorium")
			TurnExecutor.set_agenda_slot(2, "job_amphitheater")
		else:
			TurnExecutor.set_agenda_slot(0, "class_astrolabe")
			TurnExecutor.set_agenda_slot(1, "job_sanatorium")
			TurnExecutor.set_agenda_slot(2, "class_armory")
		hub._execute_turn()
		await frames(2)
		if not hub._report.visible:
			print("  turno ", TimeManager.current_total_turn, " estrés ", GameState.stress, " oro ", GameState.gold, " validación: ", TurnExecutor.validate_and_preview(), " agenda ", TurnExecutor.agenda)
		check(hub._report.visible, "informe del turno %d" % TimeManager.current_total_turn)
		if not hub._report.visible:
			break
		hub._report.hide_overlay()
		await frames(2)
		if hub._letter.visible:
			hub._letter.hide_overlay()
			await frames(2)
		if hub._ending.visible:
			break
		hub._busy = false
	check(TimeManager.campaign_over, "la campaña debería terminar")
	check(hub._ending.visible, "pantalla final visible")
	check(Chronicle.letters_archive.size() == 8, "8 cartas")
	print("\n==== UI SMOKE: %d fallos ====" % failures)
	get_tree().quit(1 if failures > 0 else 0)

func _all_buttons(n: Node) -> Array:
	var out: Array = []
	for c in n.get_children():
		if c is Button:
			out.append(c)
		out.append_array(_all_buttons(c))
	return out
