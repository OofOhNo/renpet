extends ModalOverlay
class_name ConstellationOverlay

## El Tapiz de las Constelaciones (Fase 9.3): Carta Estelar Interactiva + Matriz de 65 Finales y Bendiciones NG+.

class _TapestryCanvas extends Control:
	signal star_hovered(info: Dictionary)
	signal star_clicked(bid: String, key: String)

	var nodes: Array[Dictionary] = []
	var branch_polys: Array[Dictionary] = []
	var hovered_key: String = ""
	var selected_key: String = ""
	var branch_filter: String = "all"
	var _t: float = 0.0
	var _bg_stars: Array[Dictionary] = []

	func _init() -> void:
		custom_minimum_size = Vector2(0, 268)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var rng := RandomNumberGenerator.new()
		rng.seed = 90517
		for i in range(64):
			_bg_stars.append({
				"x": rng.randf(),
				"y": rng.randf(),
				"r": rng.randf_range(0.8, 1.9),
				"p": rng.randf() * TAU
			})

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		_t += delta
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if size.x <= 10.0 or size.y <= 10.0:
			return
		if event is InputEventMouseMotion:
			var me: InputEventMouseMotion = event
			var hit: Dictionary = _find_node(me.position, 16.0)
			var next_k: String = str(hit.get("key", ""))
			if next_k != hovered_key:
				hovered_key = next_k
				star_hovered.emit(hit)
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var mb: InputEventMouseButton = event
			var hit: Dictionary = _find_node(mb.position, 18.0)
			if not hit.is_empty():
				star_clicked.emit(str(hit["bid"]), str(hit["key"]))
				accept_event()
			else:
				# Clic cerca del centro de una constelación filtra esa rama
				var best_bid: String = ""
				var best_d: float = 95.0
				for bp in branch_polys:
					var cp: Vector2 = _to_px(bp["center_norm"])
					var d: float = mb.position.distance_to(cp)
					if d < best_d:
						best_d = d
						best_bid = str(bp["bid"])
				if best_bid != "":
					star_clicked.emit(best_bid, "")
					accept_event()

	func _to_px(norm: Vector2) -> Vector2:
		return Vector2(24.0 + norm.x * (size.x - 48.0), 18.0 + norm.y * (size.y - 36.0))

	func _find_node(pos: Vector2, max_dist: float) -> Dictionary:
		var best: Dictionary = {}
		var best_d: float = max_dist
		for n in nodes:
			var p: Vector2 = _to_px(n["pos_norm"])
			var d: float = pos.distance_to(p)
			if d < best_d:
				best_d = d
				best = n
		return best

	func _draw() -> void:
		if size.x <= 10.0 or size.y <= 10.0:
			return
		# Fondo abovedado y retícula celeste
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.04, 0.12, 0.90), true)
		var center: Vector2 = size * 0.5
		draw_arc(center, minf(size.x, size.y) * 0.44, 0.0, TAU, 72, Color(0.84, 0.69, 0.36, 0.16), 1.2, true)
		draw_arc(center, minf(size.x, size.y) * 0.28, 0.0, TAU, 56, Color(0.32, 0.72, 0.68, 0.14), 1.0, true)
		for s in _bg_stars:
			var a: float = 0.18 + 0.16 * sin(_t * 1.9 + float(s["p"]))
			draw_circle(Vector2(float(s["x"]) * size.x, float(s["y"]) * size.y), float(s["r"]), Color(0.92, 0.90, 0.80, a))

		# Líneas de conexión entre las 5 constelaciones
		for bp in branch_polys:
			var bid: String = str(bp["bid"])
			var active_branch: bool = (branch_filter == "all" or branch_filter == bid)
			var col: Color = bp["color"]
			var bunlocked: bool = bool(bp["unlocked"])
			var base_alpha: float = (0.58 if bunlocked else 0.18) if active_branch else 0.07
			var line_col: Color = Color(col.r, col.g, col.b, base_alpha)
			var pts: Array = bp["pts_norm"]
			for e in bp["edges"]:
				var edge: Vector2i = e
				if edge.x < pts.size() and edge.y < pts.size():
					draw_line(_to_px(pts[edge.x]), _to_px(pts[edge.y]), line_col, 1.6 if bunlocked and active_branch else 1.0, true)
			if branch_filter == bid:
				var cpos: Vector2 = _to_px(bp["center_norm"])
				draw_arc(cpos, 68.0, 0.0, TAU, 40, Color(col.r, col.g, col.b, 0.26), 1.5, true)

		# Estrellas individuales (65 nodos)
		for n in nodes:
			var bid: String = str(n["bid"])
			var key: String = str(n["key"])
			var unlocked: bool = bool(n["unlocked"])
			var active_branch: bool = (branch_filter == "all" or branch_filter == bid)
			var p: Vector2 = _to_px(n["pos_norm"])
			var col: Color = n["color"]
			var alpha: float = 1.0 if active_branch else 0.22
			var is_focus: bool = (key == hovered_key or key == selected_key)

			if unlocked:
				var glow_r: float = (10.0 + sin(_t * 3.0 + p.x * 0.05) * 1.8) if is_focus else 8.0
				draw_circle(p, glow_r, Color(col.r, col.g, col.b, 0.28 * alpha))
				draw_line(p + Vector2(-5.5, 0.0), p + Vector2(5.5, 0.0), Color(1.0, 0.96, 0.82, 0.9 * alpha), 1.5, true)
				draw_line(p + Vector2(0.0, -5.5), p + Vector2(0.0, 5.5), Color(1.0, 0.96, 0.82, 0.9 * alpha), 1.5, true)
				draw_circle(p, 3.6, Color(col.r, col.g, col.b, alpha))
				draw_circle(p, 1.8, Color(1.0, 0.98, 0.92, alpha))
			else:
				draw_circle(p, 4.2 if is_focus else 2.5, Color(0.62, 0.68, 0.82, 0.34 * alpha))

			if is_focus:
				draw_arc(p, 11.5, 0.0, TAU, 24, Color(0.98, 0.86, 0.46, 0.92), 1.8, true)

var _active_tab: int = 0
var _branch_filter: String = "all"
var _selected_star_key: String = ""
var _status_msg: String = ""
var _status_col: Color = AstralTheme.TURQ
var _inspector_lbl: Label

func open_tapestry(initial_tab: int = 0) -> void:
	_active_tab = initial_tab
	_status_msg = ""
	_render()
	show_overlay()

func _render() -> void:
	set_panel_width(1060)
	var total_matrix: int = EndingEvaluator.BRANCH_ORDER.size() * EndingEvaluator.VOCATION_ORDER.size()
	var found_count: int = ConstellationTapestry.discovered_endings.size()
	var branches_count: int = ConstellationTapestry.discovered_branches.size()
	var bonds_count: int = ConstellationTapestry.discovered_bonds.size()

	rebuild(func() -> void:
		var head := AstralTheme.hbox(14)
		var icon := TextureRect.new()
		icon.texture = load("res://assets/ui/seal_medallion_intact.png")
		icon.custom_minimum_size = Vector2(68, 68)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		head.add_child(icon)

		var hv := AstralTheme.vbox(3)
		hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(hv)
		hv.add_child(AstralTheme.label("%s  EL TAPIZ DE LAS CONSTELACIONES (NEW GAME+)  %s" % [AstralTheme.G_STAR, AstralTheme.G_STAR], "HeadingLabel", AstralTheme.GOLD, true))
		hv.add_child(AstralTheme.label(
			"Finales: %d / %d   ·   Ramas: %d / %d   ·   Vínculos: %d / %d   ·   Campañas: %d   ·   Puntos Astrales: %d ✦" % [
				found_count, total_matrix,
				branches_count, EndingEvaluator.BRANCH_ORDER.size(),
				bonds_count, RelationshipManager.NPC_ORDER.size(),
				ConstellationTapestry.total_campaigns,
				ConstellationTapestry.astral_points
			],
			"SubLabel", AstralTheme.GOLD_PALE, true
		))
		content.add_child(head)

		if _status_msg != "":
			content.add_child(AstralTheme.label(_status_msg, "SubLabel", _status_col, true))

		var tabs := TabContainer.new()
		tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.tab_changed.connect(func(idx: int) -> void:
			_active_tab = idx
			_fit())
		content.add_child(tabs)

		_build_matrix_tab(tabs)
		_build_boons_tab(tabs)
		_build_chronicle_tab(tabs)
		tabs.current_tab = clampi(_active_tab, 0, tabs.get_tab_count() - 1)

		var close_row := AstralTheme.hbox(10)
		close_row.add_child(AstralTheme.spacer())
		var b_close := AstralTheme.button("Cerrar Tapiz", "PrimaryButton")
		b_close.custom_minimum_size = Vector2(220, 50)
		b_close.pressed.connect(hide_overlay)
		close_row.add_child(b_close)
		content.add_child(close_row))

func _make_tab_box(tabs: TabContainer, title: String) -> VBoxContainer:
	var m := MarginContainer.new()
	m.name = title
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 6)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := AstralTheme.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(v)
	tabs.add_child(m)
	return v

func _build_matrix_tab(tabs: TabContainer) -> void:
	var v: VBoxContainer = _make_tab_box(tabs, "  Matriz de 65 Finales  ")

	var chart_card := AstralTheme.panel("CardPanel")
	var cv_top := AstralTheme.vbox(6)
	chart_card.add_child(cv_top)
	var chart := _build_constellation_canvas()
	cv_top.add_child(chart)
	_inspector_lbl = AstralTheme.label("Pasa el cursor sobre cualquier estrella del firmamento o haz clic para inspeccionar su destino.", "CaptionLabel", AstralTheme.GOLD_PALE, true)
	_inspector_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv_top.add_child(_inspector_lbl)
	if _selected_star_key != "":
		var parts: PackedStringArray = _selected_star_key.split("__")
		if parts.size() == 2:
			_update_star_inspector({"key": _selected_star_key, "bid": parts[0], "vid": parts[1],
				"unlocked": ConstellationTapestry.discovered_endings.has(_selected_star_key),
				"title": str(ConstellationTapestry.discovered_endings.get(_selected_star_key, {}).get("title", "")),
				"branch_name": str(EndingEvaluator.BRANCHES.get(parts[0], {}).get("name", parts[0])),
				"voc_name": str(EndingEvaluator.VOCATIONS.get(parts[1], {}).get("name", parts[1])),
				"daughter": str(ConstellationTapestry.discovered_endings.get(_selected_star_key, {}).get("daughter_name", "Renpet"))})
	v.add_child(chart_card)

	var total_discovered: int = ConstellationTapestry.discovered_endings.size()
	var filter_flow := HFlowContainer.new()
	filter_flow.add_theme_constant_override("h_separation", 6)
	filter_flow.add_theme_constant_override("v_separation", 6)
	var b_all := AstralTheme.button("Todas (%d/65)" % total_discovered, "PrimaryButton" if _branch_filter == "all" else "")
	b_all.custom_minimum_size = Vector2(0, 34)
	b_all.pressed.connect(func() -> void:
		_branch_filter = "all"
		_render())
	filter_flow.add_child(b_all)

	var branch_counts: Dictionary = {}
	for bid in EndingEvaluator.BRANCH_ORDER:
		var cnt: int = 0
		for vid in EndingEvaluator.VOCATION_ORDER:
			if ConstellationTapestry.discovered_endings.has("%s__%s" % [bid, vid]):
				cnt += 1
		branch_counts[bid] = cnt
		var bdata_f: Dictionary = EndingEvaluator.BRANCHES[bid]
		var b_unlocked_f: bool = ConstellationTapestry.discovered_branches.has(bid)
		var f_label: String = "%s (%d/13)" % [str(bdata_f.get("short", bdata_f["name"])), cnt] if b_unlocked_f else "Rama %d: ??? (%d/13)" % [int(bdata_f["order"]), cnt]
		var bf := AstralTheme.button(f_label, "PrimaryButton" if _branch_filter == bid else "")
		bf.custom_minimum_size = Vector2(0, 34)
		bf.pressed.connect(func() -> void:
			_branch_filter = bid
			_render())
		filter_flow.add_child(bf)
	v.add_child(filter_flow)

	for bid in EndingEvaluator.BRANCH_ORDER:
		if _branch_filter != "all" and bid != _branch_filter:
			continue
		var bdata: Dictionary = EndingEvaluator.BRANCHES[bid]
		var branch_unlocked: bool = ConstellationTapestry.discovered_branches.has(bid)
		var unlocked_in_branch: int = int(branch_counts.get(bid, 0))
		var b_title: String = str(bdata["name"]) if branch_unlocked else "Rama %d: ??? (Aún sin alcanzar)" % int(bdata["order"])
		v.add_child(AstralTheme.label(
			"%s  %s  (%d / 13 descubiertos)" % [AstralTheme.G_ANKH, b_title, unlocked_in_branch],
			"SubLabel",
			Color.html(str(bdata["color"])) if branch_unlocked else AstralTheme.MUTED,
			true
		))

		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(grid)

		for vid in EndingEvaluator.VOCATION_ORDER:
			var key: String = "%s__%s" % [bid, vid]
			var voc_name: String = str(EndingEvaluator.VOCATIONS[vid]["name"])
			var found: Dictionary = ConstellationTapestry.discovered_endings.get(key, {})
			var unlocked: bool = not found.is_empty()
			var is_sel: bool = (_selected_star_key == key)

			var card := AstralTheme.panel("GlowPanel" if (unlocked or is_sel) else "SunkenPanel")
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var cv := AstralTheme.vbox(2)
			card.add_child(cv)
			var prefix: String = "%s " % AstralTheme.G_STAR if is_sel else ""
			if unlocked:
				cv.add_child(AstralTheme.label("%s%s  %s" % [prefix, AstralTheme.G_CHECK, str(found.get("title", ""))], "SubLabel", AstralTheme.GOLD if is_sel else AstralTheme.GOLD_PALE, true))
				cv.add_child(AstralTheme.label("%s  ·  Protagonista: %s" % [voc_name, str(found.get("daughter_name", "Renpet"))], "CaptionLabel", AstralTheme.TURQ, true))
			else:
				cv.add_child(AstralTheme.label("%s%s  Constelación Velada" % [prefix, AstralTheme.G_STAR2], "", AstralTheme.GOLD_PALE if is_sel else AstralTheme.MUTED, true))
				cv.add_child(AstralTheme.label("Vocación asociada: %s" % voc_name, "CaptionLabel", AstralTheme.TURQ if is_sel else AstralTheme.MUTED, true))
			grid.add_child(card)

func _build_boons_tab(tabs: TabContainer) -> void:
	var v: VBoxContainer = _make_tab_box(tabs, "  Bendiciones Hereditarias (NG+)  ")
	v.add_child(AstralTheme.label(
		"Invierte Puntos Astrales ganados al completar campañas para activar ventajas en tus próximas partidas nuevas. Puntos disponibles: %d ✦" % ConstellationTapestry.astral_points,
		"CaptionLabel", AstralTheme.TURQ, true
	))

	for b in ConstellationTapestry.BOONS:
		var bid: String = str(b["id"])
		var cost: int = int(b["cost"])
		var owned: bool = ConstellationTapestry.purchased_boons.has(bid)
		var active: bool = ConstellationTapestry.active_boons.has(bid)

		var card := AstralTheme.panel("GlowPanel" if active else "CardPanel")
		var row := AstralTheme.hbox(12)
		card.add_child(row)

		var info := AstralTheme.vbox(3)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var state_tag: String = " [ACTIVA EN NG+]" if active else (" [ADQUIRIDA]" if owned else " [%d ✦]" % cost)
		info.add_child(AstralTheme.label("%s%s" % [str(b["name"]), state_tag], "SubLabel", AstralTheme.GOOD if active else (AstralTheme.GOLD_PALE if owned else AstralTheme.IVORY), true))
		info.add_child(AstralTheme.label(str(b["desc"]), "CaptionLabel", AstralTheme.MUTED, true))

		if owned:
			var tbtn := AstralTheme.button("Desactivar" if active else "Activar", "PrimaryButton" if not active else "")
			tbtn.custom_minimum_size = Vector2(150, 44)
			tbtn.pressed.connect(func() -> void:
				ConstellationTapestry.toggle_boon(bid)
				_status_msg = "Bendición '%s' %s." % [b["name"], "activada para tu próxima partida" if ConstellationTapestry.active_boons.has(bid) else "desactivada"]
				_status_col = AstralTheme.TURQ
				_render())
			row.add_child(tbtn)
		else:
			var can_buy: bool = ConstellationTapestry.astral_points >= cost
			var bbtn := AstralTheme.button("Desbloquear (%d ✦)" % cost, "PrimaryButton" if can_buy else "")
			bbtn.custom_minimum_size = Vector2(180, 44)
			bbtn.disabled = not can_buy
			bbtn.pressed.connect(func() -> void:
				var res: Dictionary = ConstellationTapestry.purchase_boon(bid)
				_status_msg = str(res.get("msg", ""))
				_status_col = AstralTheme.GOOD if res.get("ok", false) else AstralTheme.BAD
				_render())
			row.add_child(bbtn)
		v.add_child(card)

func _build_chronicle_tab(tabs: TabContainer) -> void:
	var v: VBoxContainer = _make_tab_box(tabs, "  Ramas y Vínculos  ")
	v.add_child(AstralTheme.label("Las 5 Grandes Ramas del Destino:", "SubLabel", AstralTheme.GOLD_PALE))
	for bid in EndingEvaluator.BRANCH_ORDER:
		var bdata: Dictionary = EndingEvaluator.BRANCHES[bid]
		var unlocked: bool = ConstellationTapestry.discovered_branches.has(bid)
		var card := AstralTheme.panel("GlowPanel" if unlocked else "SunkenPanel")
		var cv := AstralTheme.vbox(2)
		card.add_child(cv)
		if unlocked:
			cv.add_child(AstralTheme.label("%s  %s" % [AstralTheme.G_CHECK, str(bdata["name"])], "SubLabel", Color.html(str(bdata["color"])), true))
			cv.add_child(AstralTheme.label(str(bdata["climax_title"]), "CaptionLabel", AstralTheme.IVORY, true))
		else:
			cv.add_child(AstralTheme.label("Rama %d: Constelación aún velada" % int(bdata["order"]), "", AstralTheme.MUTED, true))
		v.add_child(card)

	v.add_child(AstralTheme.separator())
	v.add_child(AstralTheme.label("Epílogos de Compañeros desbloqueados:", "SubLabel", AstralTheme.GOLD_PALE))
	for npc_id in RelationshipManager.NPC_ORDER:
		var unlocked: bool = ConstellationTapestry.discovered_bonds.has(npc_id)
		var data: Dictionary = RelationshipManager.NPC_DATA[npc_id]
		var card := AstralTheme.panel("GlowPanel" if unlocked else "SunkenPanel")
		var cv := AstralTheme.vbox(2)
		card.add_child(cv)
		if unlocked:
			cv.add_child(AstralTheme.label("%s  %s — %s" % [AstralTheme.G_HEART, data["name"], data["title"]], "SubLabel", AstralTheme.GOLD_PALE, true))
		else:
			var masked: String = "??? — Epílogo oculto" if npc_id == "zephyr" else "%s — Epílogo aún sin vivir" % data["name"]
			cv.add_child(AstralTheme.label(masked, "", AstralTheme.MUTED, true))
		v.add_child(card)

func _build_constellation_canvas() -> _TapestryCanvas:
	var canvas := _TapestryCanvas.new()
	canvas.branch_filter = _branch_filter
	canvas.selected_key = _selected_star_key
	var centers: Array[Vector2] = [
		Vector2(0.11, 0.50), Vector2(0.305, 0.44), Vector2(0.50, 0.52), Vector2(0.695, 0.44), Vector2(0.89, 0.50)
	]
	# 13 desplazamientos astronómicos locales distintos por rama para las 13 vocaciones
	var offsets: Array[Vector2] = [
		Vector2(0.0, -0.30), Vector2(-0.045, -0.18), Vector2(0.048, -0.17),
		Vector2(-0.072, -0.04), Vector2(0.0, -0.05), Vector2(0.070, -0.02),
		Vector2(-0.052, 0.11), Vector2(0.012, 0.10), Vector2(0.062, 0.13),
		Vector2(-0.068, 0.25), Vector2(-0.010, 0.24), Vector2(0.055, 0.27),
		Vector2(0.002, 0.36)
	]
	var edges: Array[Vector2i] = [
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 4), Vector2i(2, 4),
		Vector2i(1, 3), Vector2i(2, 5), Vector2i(3, 6), Vector2i(4, 7),
		Vector2i(5, 8), Vector2i(6, 7), Vector2i(7, 8), Vector2i(6, 9),
		Vector2i(7, 10), Vector2i(8, 11), Vector2i(9, 10), Vector2i(10, 12), Vector2i(11, 12)
	]
	for b_i in range(EndingEvaluator.BRANCH_ORDER.size()):
		var bid: String = EndingEvaluator.BRANCH_ORDER[b_i]
		var bdata: Dictionary = EndingEvaluator.BRANCHES[bid]
		var bcol: Color = Color.html(str(bdata["color"]))
		var bunlocked: bool = ConstellationTapestry.discovered_branches.has(bid)
		var bcenter: Vector2 = centers[b_i % centers.size()]
		var poly_pts: Array[Vector2] = []
		for v_i in range(EndingEvaluator.VOCATION_ORDER.size()):
			var vid: String = EndingEvaluator.VOCATION_ORDER[v_i]
			var key: String = "%s__%s" % [bid, vid]
			var found: Dictionary = ConstellationTapestry.discovered_endings.get(key, {})
			var unlocked: bool = not found.is_empty()
			var raw_off: Vector2 = offsets[v_i % offsets.size()]
			# Variación armónica sutil para que cada constelación dibuje silueta propia
			var rot: float = float(b_i - 2) * 0.16
			var rot_off := Vector2(raw_off.x * cos(rot) - raw_off.y * 0.18 * sin(rot), raw_off.y * cos(rot) + raw_off.x * sin(rot))
			var pnorm: Vector2 = (bcenter + rot_off).clamp(Vector2(0.03, 0.06), Vector2(0.97, 0.94))
			poly_pts.append(pnorm)
			canvas.nodes.append({
				"key": key, "bid": bid, "vid": vid,
				"pos_norm": pnorm, "color": bcol, "unlocked": unlocked,
				"title": str(found.get("title", "")),
				"branch_name": str(bdata.get("short", bdata["name"])),
				"voc_name": str(EndingEvaluator.VOCATIONS[vid]["name"]),
				"daughter": str(found.get("daughter_name", "Renpet"))
			})
		canvas.branch_polys.append({
			"bid": bid, "color": bcol, "unlocked": bunlocked,
			"pts_norm": poly_pts, "edges": edges, "center_norm": bcenter
		})
	canvas.star_hovered.connect(_update_star_inspector)
	canvas.star_clicked.connect(func(bid: String, key: String) -> void:
		AstralAudio.play_ui()
		if key != "":
			_selected_star_key = key
			_branch_filter = bid
		else:
			_branch_filter = "all" if _branch_filter == bid else bid
		_render())
	return canvas

func _update_star_inspector(info: Dictionary) -> void:
	if _inspector_lbl == null:
		return
	if info.is_empty():
		_inspector_lbl.text = "Pasa el cursor sobre cualquier estrella del firmamento o haz clic para enfocar su constelación."
		_inspector_lbl.add_theme_color_override("font_color", AstralTheme.MUTED)
		return
	var unlocked: bool = bool(info.get("unlocked", false))
	var bname: String = str(info.get("branch_name", ""))
	var vname: String = str(info.get("voc_name", ""))
	if unlocked:
		_inspector_lbl.text = "%s  %s  (%s · %s · %s)" % [AstralTheme.G_STAR, str(info.get("title", "")), bname, vname, str(info.get("daughter", "Renpet"))]
		_inspector_lbl.add_theme_color_override("font_color", AstralTheme.GOLD)
	else:
		_inspector_lbl.text = "%s  Estrella Velada  —  Constelación: %s  ·  Vocación: %s" % [AstralTheme.G_STAR2, bname, vname]
		_inspector_lbl.add_theme_color_override("font_color", AstralTheme.TURQ)
