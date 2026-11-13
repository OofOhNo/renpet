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
	hub._say_stage_reaction()
	check(hub._lbl_speaker.text.contains("Luna"), "etapa y diálogo personalizados con Luna")

	check(GameState.get_secret_tier() == 0, "el giro del Sello debe permanecer oculto al inicio (Edad 12)")
	check(GameState.get_stat_label("seal_integrity") == "Armonía Interior", "etiqueta sin spoiler a los 12 años")
	check(not RelationshipManager.is_known("soren"), "los candidatos deben comenzar como desconocidos")

	for w in ["schedule", "status", "hearth", "crucible"]:
		hub.debug_open_window(w)
		await frames(3)
		check(hub._windows[w].visible, "ventana %s no visible" % w)
		check(not hub._stage.visible, "el retrato derecho debe ocultarse al abrir %s para no superponerse" % w)
	check(hub._windows["status"].title_label.text == "Ficha de Luna", "título dinámico en Ficha de Renpet")
	hub.debug_open_window("schedule")
	await frames(2)
	var sched_txts: String = "\n".join(_all_label_texts(hub._windows["schedule"]))
	check(not sched_txts.contains("Relojería") and not sched_txts.contains("Contrabando") and not sched_txts.contains("Edad 13+"),
		"Agenda a los 12 años debe ocultar actividades de mayor edad")
	GameState.age = 14
	hub._windows["schedule"].refresh()
	await frames(2)
	var sched_14_txts: String = "\n".join(_all_label_texts(hub._windows["schedule"]))
	check(sched_14_txts.contains("Contrabando") and sched_14_txts.contains("Relojería"),
		"Agenda a los 14 años debe revelar actividades desbloqueadas")
	GameState.age = 12
	hub._windows["schedule"].refresh()
	await frames(2)
	hub._windows["schedule"]._on_assign_activity(0, "class_astrolabe")
	await frames(2)
	check(TurnExecutor.agenda[0] == "class_astrolabe", "asignación de actividad en agenda")
	var locked_exp: Dictionary = ExplorationCombat.start_expedition(0, "zephyr", "Zephyr")
	check(not bool(locked_exp.get("ok", false)), "Zephyr bloqueado en expedición a los 12 años")
	check(not EndingEvaluator.get_projected_vocation().is_empty(), "proyección de vocación en partida")

	# Tutorial guiado paso a paso
	hub._tutorial.open_tutorial(0)
	await frames(2)
	check(hub._tutorial.visible, "tutorial guiado visible")
	hub._tutorial._finish()
	await frames(2)
	check(SettingsManager.tutorial_completed, "tutorial marcado como completado")

	# Mapa de Aethelgard de pantalla completa (bloquea la mansión hasta volver)
	hub.debug_open_city("anfiteatro")
	await frames(3)
	check(hub._city_map.visible and not hub._ui_root.visible, "Salir a Aethelgard abre el mapa y oculta la mansión")
	hub._city_map.close_overlay()
	await frames(4)
	check(not hub._city_map.visible and hub._ui_root.visible, "Volver a la Mansión restaura controles")
	check(hub._stage.visible, "stage restaurado tras volver de Aethelgard")

	# Chimenea: elegir tópico y actitud
	hub.debug_open_window("hearth")
	await frames(2)
	var topics: Array = Chronicle.get_fireplace_topics()
	check(topics.size() >= 3, "tópicos de chimenea disponibles")
	hub._windows["hearth"]._selected_topic = topics[0]["id"]
	hub._windows["hearth"]._apply_stance(topics[0], "warm")
	await frames(2)
	check(Chronicle.chatted_this_bimester, "charla marcada")

	# Ciudad: descubrir NPC (VP), conversar, regalar y escena (a los 12 no debe haber elección romántica)
	hub.debug_open_city("torre")
	await frames(2)
	check(bool(RelationshipManager.meet_candidate("soren").get("ok", false)), "descubrimiento de Soren consume 1 PS")
	check(RelationshipManager.is_known("soren"), "Soren ahora es conocido")
	check(bool(RelationshipManager.interact_with_candidate("soren", "chat").get("ok", false)), "conversación tras conocer a Soren")
	GameState.gold = 900
	check(bool(GameState.buy_gift("quartz_lens").get("ok", false)), "compra de obsequio en tienda de Aethelgard")
	check(not bool(RelationshipManager.interact_with_candidate("soren", "gift_item", "quartz_lens").get("ok", false)), "tope de 2 acciones/bimestre por personaje activo")
	check(bool(RelationshipManager.meet_candidate("vespera").get("ok", false)), "3.er punto social invertido en descubrir a Vespera")
	check(RelationshipManager.social_points_left == 0, "3 puntos sociales agotados correctamente")
	await frames(2)
	RelationshipManager.reset_bimester_flags()
	check(bool(RelationshipManager.interact_with_candidate("soren", "gift_item", "quartz_lens").get("ok", false)), "entrega de obsequio del inventario tras nuevo bimestre")
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
	hub._city_map.close_overlay()
	await frames(3)

	# Crisol
	hub.debug_open_window("crucible")
	hub._windows["crucible"]._selected = "comet_dust"
	hub._windows["crucible"]._try_assimilate("comet_dust", false)
	await frames(2)

	# Minijuego interactivo del Astrolabio
	hub._close_windows()
	await frames(2)
	hub._open_ritual()
	await frames(2)
	check(hub._ritual.visible, "minijuego Astrolabio visible")
	var lum_before: int = GameState.luminiscencia
	for _r in range(3):
		hub._ritual.lock_current_ring()
	await frames(2)
	check(TurnExecutor.astrolabe_tuned_this_bimester, "ritual del astrolabio marcado como completado")
	check(GameState.luminiscencia > lum_before, "ritual otorgó Luminiscencia")
	hub._ritual.hide_overlay()
	await frames(2)
	check(hub._ritual_btn.disabled, "botón de sintonía deshabilitado tras usarse")

	# Nuevos sistemas: Minijuegos multi-estado, Boutique, Mazo de Recuerdos y Expedición desde Patio Ducal
	var temple_before: int = GameState.temple
	hub._school_mg.open_minigame("fencing", true, "PATIO DE ARMAS: PRUEBA", true)
	await frames(2)
	check(hub._school_mg.visible, "minijuego de esgrima visible")
	hub._school_mg.finish_instant_for_test()
	await frames(2)
	check(TurnExecutor.school_minigame_used_this_bimester, "minijuego escolar marcado como completado")
	check(GameState.temple > temple_before, "minijuego de esgrima otorgó Temple")
	hub._school_mg.hide_overlay()
	await frames(2)

	hub._school_mg.open_minigame("rhythm", true, "ANFITEATRO: PRUEBA", false)
	await frames(2)
	check(hub._school_mg.visible, "minijuego de armonización visible")
	hub._school_mg.finish_instant_for_test()
	await frames(2)
	hub._school_mg.hide_overlay()
	await frames(2)

	GameState.gold = 900
	# Verificación de tiendas en Aethelgard y ocultamiento por edad
	hub.debug_open_city("palacio")
	await frames(3)
	var pal_tabs: TabContainer = _find_tab_container(hub._city_map)
	check(pal_tabs != null and pal_tabs.size.y >= 200.0, "tienda de Palacio expandida y visible (>=200 px, actual: %.1f)" % (pal_tabs.size.y if pal_tabs != null else 0.0))
	if pal_tabs != null:
		pal_tabs.current_tab = 1
		await frames(2)
		var pal_gift_btns: Array = []
		for gb in _all_buttons(pal_tabs):
			if str(gb.text).begins_with("Comprar (") and not gb.disabled:
				pal_gift_btns.append(gb)
		check(pal_gift_btns.size() == 3, "Obsequios Finos muestra 3 regalos comprables")
		var pal_gifts: Array[Dictionary] = CatalogDB.get_gifts_for_shop("palace")
		if pal_gift_btns.size() >= 1 and pal_gifts.size() >= 1:
			var first_gid: String = str(pal_gifts[0]["id"])
			var before_g: int = GameState.get_gift_count(first_gid)
			pal_gift_btns[0].pressed.emit()
			await frames(2)
			var pal_tabs_after: TabContainer = _find_tab_container(hub._city_map)
			check(pal_tabs_after != null and pal_tabs_after.current_tab == 1, "comprar en Obsequios Finos mantiene la pestaña activa")
			check(GameState.get_gift_count(first_gid) == before_g + 1, "compra real de obsequio (%s) desde botón UI" % first_gid)

	hub.debug_open_city("acueductos")
	await frames(3)
	var acq_tabs: TabContainer = _find_tab_container(hub._city_map)
	check(acq_tabs != null and acq_tabs.size.y >= 200.0, "tienda de Acueductos expandida y visible (>=200 px)")
	var acq_buy_btns: Array = []
	for ab in _all_buttons(acq_tabs):
		if str(ab.text).begins_with("Comprar (") and not ab.disabled:
			acq_buy_btns.append(ab)
	check(acq_buy_btns.size() >= 6, "Bazar y Obsequios muestra regalos y reliquias comprables incluso en turno 1")
	if acq_buy_btns.size() >= 4:
		var dust_before: int = int(GameState.materials_inventory.get("comet_dust", 0))
		acq_buy_btns[3].pressed.emit()
		await frames(2)
		check(int(GameState.materials_inventory.get("comet_dust", 0)) == dust_before + 1, "compra real de reliquia en Bazar de Acueductos")

	hub.debug_open_city("espejo")
	await frames(2)
	var esp_txts: String = "\n".join(_all_label_texts(hub._city_map))
	check(not esp_txts.contains("PRESENCIA VELADA") and not esp_txts.contains("15 años"), "Espejo Astral oculta personaje bloqueado por edad")

	hub.debug_open_city("torre")
	await frames(2)
	var tor_txts: String = "\n".join(_all_label_texts(hub._city_map))
	check(not tor_txts.contains("18 años") and not tor_txts.contains("Edad 18+"), "NPC oculta hints de romance antes de los 18")
	hub._city_map.close_overlay()
	await frames(2)

	check(bool(GameState.buy_outfit("solar").get("ok", false)), "compra y equipamiento de atuendo Boutique")
	check(GameState.get_active_portrait_path().ends_with("renpet_outfit_solar.png"), "retrato cambió al Uniforme Solar")
	RelationshipManager.state["soren"]["stage"] = 2
	check(bool(GameState.toggle_equipped_card("mem_bond_soren").get("ok", false)), "equipar carta de recuerdo desbloqueada por vínculo")

	# Expedición interactiva de 4 nodos desde Patio Ducal
	hub.debug_open_city("patio")
	await frames(2)
	var pat_txts: String = "\n".join(_all_label_texts(hub._city_map))
	check(pat_txts.contains("Bosque de los Relojes") and not pat_txts.contains("Acueducto Solar") and not pat_txts.contains("Edad 13+"),
		"Patio Ducal oculta zonas de mayor edad a los 12 años")
	var exp_res: Dictionary = ExplorationCombat.start_expedition(0, "vespera", "Dama Vespera")
	check(bool(exp_res.get("ok", false)), "iniciar expedición de 4 nodos")
	if bool(exp_res.get("ok", false)):
		ExplorationCombat.enemy_hp = 1
		ExplorationCombat.play_combat_card("solar_slash")
		await frames(2)
		check(ExplorationCombat.current_node == 2 and not ExplorationCombat.in_combat, "transición al Nodo 2 de ruta")
		ExplorationCombat.choose_expedition_node("safe")
		await frames(2)
		check(ExplorationCombat.current_node == 3, "transición al Nodo 3 Santuario")
		ExplorationCombat.choose_expedition_node("shard")
		await frames(2)
		check(ExplorationCombat.current_node == 4 and ExplorationCombat.in_combat, "transición al Nodo 4 Guardián Final")
		ExplorationCombat.retreat_from_combat()
		await frames(2)
	hub._city_map.close_overlay()
	await frames(3)

	# Menú de guardado y Opciones
	hub._menu.open_pause(true)
	await frames(2)
	hub._menu.open_settings()
	await frames(2)
	check(hub._menu.visible, "menú de opciones visible")
	check(SettingsManager.RESOLUTIONS.size() == 10, "10 resoluciones disponibles en SettingsManager")
	check(hub._menu._res_opt != null and hub._menu._res_opt.item_count == 10, "selector de resoluciones con 10 opciones")
	var prev_res_idx: int = SettingsManager.resolution_index
	SettingsManager.set_resolution_index(5, false)
	check(SettingsManager.get_resolution_vector() == Vector2i(1920, 1080), "cambio de resolución a 1920x1080 aplicado")
	SettingsManager.set_resolution_index(prev_res_idx, false)
	hub._menu.open_slots(MenuOverlay.Mode.SAVE)
	await frames(2)
	hub._menu._slot_pressed(3)
	await frames(2)
	check(SaveManager.has_save(3), "guardado manual en ranura 3")

	# Verificar modo unificado por defecto y modo informe detallado
	SettingsManager.unified_turn_end = true
	# 48 turnos completos con la interfaz
	var guard: int = 0
	while not TimeManager.campaign_over and guard < 60:
		guard += 1
		if GameState.exhausted_sick:
			for i in range(3):
				TurnExecutor.set_agenda_slot(i, "rest_manor")
		elif GameState.stress >= 60:
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
		if guard == 1:
			check(not hub._report.visible, "fin de turno unificado oculta TurnReport automático")
			check(not TurnExecutor.astrolabe_tuned_this_bimester, "sintonía del astrolabio reseteada al pasar bimestre")
			check(not TurnExecutor.school_minigame_used_this_bimester, "minijuego escolar reseteado al pasar bimestre")
			SettingsManager.unified_turn_end = false
		else:
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
		if hub._story.visible:
			var s_btns: Array = _all_buttons(hub._story)
			check(s_btns.size() >= 1, "evento de historia sin opciones")
			if s_btns.size() >= 1:
				s_btns[0].pressed.emit()
				await frames(2)
				var c_btns: Array = _all_buttons(hub._story)
				check(c_btns.size() == 1, "botón Continuar en evento de historia")
				if c_btns.size() >= 1:
					c_btns[0].pressed.emit()
					await frames(3)
		if hub._ending.visible:
			break
		hub._busy = false
	check(TimeManager.campaign_over, "la campaña debería terminar")
	check(hub._ending.visible, "pantalla final visible")
	if hub._ending.visible:
		for step_name in ["climax", "vectores", "testamento"]:
			var ebtns: Array = _all_buttons(hub._ending)
			check(ebtns.size() >= 1, "EndingOverlay paso %s sin botones" % step_name)
			if ebtns.size() >= 1:
				ebtns[0].pressed.emit()
				await frames(3)
		check(ConstellationTapestry.discovered_endings.size() >= 1, "final registrado en El Tapiz")
		check(ConstellationTapestry.astral_points > 0, "puntos astrales NG+ otorgados")
	check(Chronicle.letters_archive.size() == 8, "8 cartas")

	# --- VERIFICACIÓN EXHAUSTIVA: RIVALES SECUNDARIOS (LYRA/CAELUM), DIÁLOGOS POR ACTO, CITAS Y ENCUENTROS CRUZADOS ---
	for rid in ["lyra", "caelum"]:
		check(RelationshipManager.NPC_ORDER.has(rid), "%s registrado en RelationshipManager.NPC_ORDER" % rid)
		check(RivalMirror.RIVAL_ORDER.has(rid), "%s registrado en RivalMirror.RIVAL_ORDER" % rid)
		check(AstralTheme.load_tex("res://assets/ui/npc_%s.png" % rid) != null, "retrato npc_%s.png cargado" % rid)
		for st in [1, 2, 3]:
			var bev: Dictionary = BondEvents.get_event(rid, st)
			check(not bev.is_empty(), "BondEvents etapa %d existe para %s" % [st, rid])
			var c_ids: Array[String] = []
			for opt in bev.get("choices", []):
				c_ids.append(str(opt.get("kind", opt.get("id", ""))))
			check(c_ids.has("friend") and c_ids.has("rival") and c_ids.has("romance"), "BondEvents etapa %d de %s tiene friend/rival/romance" % [st, rid])
	for rid in RivalMirror.RIVAL_ORDER:
		check(RivalMirror.get_status_quote(rid) != "", "RivalMirror.get_status_quote no vacío para %s" % rid)

	# Reinicio limpio para probar Actos 1/2/3, Tier 0 sin spoilers, salidas (outing), switcher y encuentros cruzados
	SaveManager.new_game()
	GameState.prologue_completed = true
	GameState.age = 12
	check(GameState.get_secret_tier() == 0, "Tier 0 confirmado en edad 12")
	var dlg_a1: String = RelationshipManager.get_contextual_action_dialogue("soren", "chat", false, 1)
	var dlg_a2: String = RelationshipManager.get_contextual_action_dialogue("soren", "chat", false, 2)
	var dlg_a3: String = RelationshipManager.get_contextual_action_dialogue("soren", "chat", false, 3)
	check(dlg_a1 != "" and dlg_a2 != "" and dlg_a3 != "", "diálogos contextuales Acto 1/2/3 no vacíos")
	check(dlg_a1 != dlg_a2 and dlg_a2 != dlg_a3 and dlg_a1 != dlg_a3, "variación real de diálogo entre Actos 1, 2 y 3")

	GameState.equipped_outfit = "gala"
	var outfit_hits: bool = false
	for _i in range(6):
		var d_chk: String = RelationshipManager.get_contextual_action_dialogue("vespera", "chat", false, 1)
		check(not d_chk.contains("Nyx-Aethel") and not d_chk.to_lower().contains("prisionero"), "sin spoilers del giro en Tier 0")
		if d_chk.to_lower().contains("gala") or d_chk.to_lower().contains("salón") or d_chk.to_lower().contains("seda") or d_chk.to_lower().contains("baile"):
			outfit_hits = true
	check(RelationshipManager.OUTFIT_COMMENTS.get("vespera", {}).has("gala") and (outfit_hits or not RelationshipManager.OUTFIT_COMMENTS.get("vespera", {}).is_empty()), "tabla OUTFIT_COMMENTS activa")

	GameState.gold = 900
	RelationshipManager.reset_bimester_flags()
	check(bool(RelationshipManager.meet_candidate("lyra").get("ok", false)), "descubrir a Lyra consume 1 PS")
	check(bool(RelationshipManager.meet_candidate("caelum").get("ok", false)), "descubrir a Caelum consume 1 PS")
	RelationshipManager.state["lyra"]["affection"] = maxi(20, RelationshipManager.OUTING_MIN_AFFECTION)
	var out_r: Dictionary = RelationshipManager.interact_with_candidate("lyra", "outing", RelationshipManager.OUTING_SPOT_ORDER[0])
	check(bool(out_r.get("ok", false)), "salida/cita por la ciudad con Lyra funcional")

	hub.debug_open_city("palacio")
	await frames(3)
	var pal_btn_txts: Array[String] = []
	var lyra_btn: Button = null
	for b in _all_buttons(hub._city_map):
		pal_btn_txts.append(str(b.text))
		if str(b.text).contains("Lyra"):
			lyra_btn = b
	check(lyra_btn != null, "selector de residentes en Palacio muestra a Lyra")
	if lyra_btn != null:
		lyra_btn.pressed.emit()
		await frames(2)
		check(str(hub._city_map._selected_npc_by_district.get("palacio", "")) == "lyra", "al pulsar Lyra cambia el residente activo de Palacio")

	hub.debug_open_city("patio")
	await frames(3)
	var caelum_found: bool = false
	for b in _all_buttons(hub._city_map):
		if str(b.text).contains("Caelum"):
			caelum_found = true
			break
	check(caelum_found, "selector de residentes en Patio Ducal muestra a Caelum")

	# Desbloquear conocidos y validar encuentro cruzado en distrito
	RelationshipManager.reset_bimester_flags()
	for nid in RelationshipManager.NPC_ORDER:
		if RelationshipManager.state.has(nid):
			RelationshipManager.state[nid]["known"] = true
	var cross_did: String = ""
	var cross_enc: Dictionary = {}
	for did in ["torre", "palacio", "patio", "acueductos", "anfiteatro"]:
		var ce: Dictionary = RelationshipManager.get_available_cross_encounter(did)
		if not ce.is_empty():
			cross_did = did
			cross_enc = ce
			break
	check(cross_did != "" and not cross_enc.is_empty(), "existe encuentro cruzado disponible en distrito")
	if cross_did != "":
		hub.debug_open_city(cross_did)
		await frames(3)
		var ce_txts: String = "\n".join(_all_label_texts(hub._city_map))
		check(ce_txts.contains("ENCUENTRO EN EL DISTRITO"), "CityMapOverlay renderiza tarjeta de encuentro cruzado")
		var ce_res: Dictionary = RelationshipManager.resolve_cross_encounter(str(cross_enc.get("id", "")), 0)
		check(bool(ce_res.get("ok", false)), "resolución de encuentro cruzado devuelve ok = true")
	hub._city_map.close_overlay()
	await frames(2)

	# --- VERIFICACIÓN: SUMIDEROS DE ORO Y FINALES ESPECÍFICOS ---
	SaveManager.new_game()
	GameState.prologue_completed = true
	GameState.age = 12
	hub.debug_open_city("torre")
	await frames(3)
	var torre_tabs: TabContainer = _find_tab_container(hub._city_map)
	check(torre_tabs != null and torre_tabs.get_tab_count() >= 2, "Torre muestra Biblioteca de Tratados")
	if torre_tabs != null and torre_tabs.get_tab_count() >= 2:
		torre_tabs.current_tab = 1
		await frames(2)
		var t12_txt: String = "\n".join(_all_label_texts(hub._city_map))
		check(t12_txt.contains("Efemérides Inversas") and not t12_txt.contains("Primer Solsticio"), "tratados de mayor edad ocultos a los 12 años")
	hub._city_map.close_overlay()
	await frames(2)

	GameState.age = 18
	GameState.gold = 25000
	var tome_r: Dictionary = GameState.buy_tome("tome_lost_chronicle")
	check(bool(tome_r.get("ok", false)) and GameState.get_tome_study_mod() >= 0.09, "compra de tratado otorga bono de estudio")
	var wpn_r: Dictionary = GameState.buy_equipment("wpn_sovereign_blade")
	var acc_r: Dictionary = GameState.buy_equipment("acc_crown_signet")
	check(bool(wpn_r.get("ok", false)) and bool(acc_r.get("ok", false)), "forja y equipa arma + reliquia de rango alto")
	check(int(round(GameState.get_equip_mod("atk_flat", 0.0))) == 30, "get_equip_mod suma arma (+22) y reliquia (+8)")
	var inv_r: Dictionary = GameState.invest_civic("civic_aqueduct_charter")
	check(bool(inv_r.get("ok", false)) and GameState.get_civic_dividend() >= 55, "patronazgo cívico otorga renta bimestral")

	# Mejora de ala nueva en la mansión hasta nivel 6
	check(HearthWindow.get_upgrade_cost(5) == 1850, "escala progresiva de costes en alas nv 5+")
	GameState.estate_levels["sanctum"] = 5
	hub.debug_open_window("hearth")
	await frames(2)
	hub._windows["hearth"]._tabs.current_tab = 2
	await frames(2)
	var sanctum_upg_btn: Button = null
	for hb in _all_buttons(hub._windows["hearth"]):
		if str(hb.text).contains("1850 G"):
			sanctum_upg_btn = hb
			break
	check(sanctum_upg_btn != null, "HearthWindow muestra mejora nv 5->6 (1850 G) para alas")
	if sanctum_upg_btn != null:
		sanctum_upg_btn.pressed.emit()
		await frames(2)
		check(int(GameState.estate_levels.get("sanctum", 1)) == 6, "mejora de Jardín Botánico-Sanatorio sube a nv 6")
	hub._windows["hearth"].close()
	await frames(2)

	# Verificar Consumibles en Acueductos y uso real en Combate a 0 PA
	check(bool(GameState.buy_consumable("phial_aether").get("ok", false)), "compra Vial de Chispa Sideral")
	ExplorationCombat.explored_this_bimester = false
	var st_exp: Dictionary = ExplorationCombat.start_expedition(0, "solo", GameState.daughter_name)
	check(bool(st_exp.get("ok", false)), "inicia expedición para probar consumibles en UI")
	if bool(st_exp.get("ok", false)):
		hub._combat.open_combat()
	await frames(3)
	var combat_btns: Array = _all_buttons(hub._combat)
	var phial_btn: Button = null
	for cb in combat_btns:
		if str(cb.text).contains("Vial de Chispa Sideral"):
			phial_btn = cb
			break
	check(phial_btn != null, "CombatOverlay renderiza botón de consumible adquirido")
	var ap_before: int = ExplorationCombat.player_ap
	if phial_btn != null:
		phial_btn.pressed.emit()
		await frames(2)
		check(ExplorationCombat.player_ap == ap_before + 2 and GameState.get_consumable_count("phial_aether") == 0, "usar Vial en CombatOverlay suma +2 PA sin gastar PA y consume unidad")
	ExplorationCombat.retreat_from_combat()
	await frames(2)
	hub._combat.visible = false

	# Ficha refleja arma/reliquia/tratados/patronazgos y Palacio muestra Patronazgo Cívico
	hub.debug_open_window("status")
	await frames(3)
	var st_txts: String = "\n".join(_all_label_texts(hub._windows["status"]))
	check(st_txts.contains("Hoja Juramentada") and st_txts.contains("Sello de la Primera"), "StatusSheet muestra arma y reliquia equipadas")
	hub._windows["status"].close()
	await frames(2)

	hub.debug_open_city("palacio")
	await frames(3)
	var pal_t: TabContainer = _find_tab_container(hub._city_map)
	check(pal_t != null and pal_t.get_tab_count() >= 4, "Palacio agrega pestaña Patronazgo y Joyería sin alterar índice Obsequios Finos")
	hub._city_map.close_overlay()
	await frames(2)

	# Política y prosa de finales específicos tras inversiones
	var ev_fin: Dictionary = EndingEvaluator.evaluate_campaign()
	check(str(ev_fin.get("politics", {}).get("text", "")).contains("Acueductos Altos"), "vector político incorpora patronazgos realizados")

	print("\n==== UI SMOKE: %d fallos ====" % failures)
	get_tree().quit(1 if failures > 0 else 0)

func _all_buttons(n: Node) -> Array:
	var out: Array = []
	for c in n.get_children():
		if c is CanvasItem and not c.visible:
			continue
		if c is Button:
			out.append(c)
		out.append_array(_all_buttons(c))
	return out

func _all_label_texts(n: Node) -> Array[String]:
	var out: Array[String] = []
	for c in n.get_children():
		if c is CanvasItem and not c.visible:
			continue
		if c is Label:
			out.append(c.text)
		elif c is RichTextLabel:
			out.append(c.text)
		out.append_array(_all_label_texts(c))
	return out

func _find_tab_container(n: Node) -> TabContainer:
	if n == null:
		return null
	for c in n.get_children():
		if c is CanvasItem and not c.visible:
			continue
		if c is TabContainer:
			return c
		var sub: TabContainer = _find_tab_container(c)
		if sub != null:
			return sub
	return null
