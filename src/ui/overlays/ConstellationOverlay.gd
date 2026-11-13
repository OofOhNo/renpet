extends ModalOverlay
class_name ConstellationOverlay

## El Tapiz de las Constelaciones (Fase 9.3): Matriz de 65 Finales, Ramas, Vínculos y Bendiciones NG+.

var _active_tab: int = 0
var _branch_filter: String = "all"
var _status_msg: String = ""
var _status_col: Color = AstralTheme.TURQ

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
	v.add_child(AstralTheme.label(
		"Cada campaña combina 1 de las 5 Ramas Narrativas del Solsticio con 1 de las 13 Vocaciones para forjar 65 desenlaces únicos.",
		"CaptionLabel", AstralTheme.MUTED, true
	))

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

			var card := AstralTheme.panel("GlowPanel" if unlocked else "SunkenPanel")
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var cv := AstralTheme.vbox(2)
			card.add_child(cv)
			if unlocked:
				cv.add_child(AstralTheme.label("%s  %s" % [AstralTheme.G_CHECK, str(found.get("title", ""))], "SubLabel", AstralTheme.GOLD_PALE, true))
				cv.add_child(AstralTheme.label("%s  ·  Protagonista: %s" % [voc_name, str(found.get("daughter_name", "Renpet"))], "CaptionLabel", AstralTheme.TURQ, true))
			else:
				cv.add_child(AstralTheme.label("%s  Constelación Velada" % AstralTheme.G_STAR2, "", AstralTheme.MUTED, true))
				cv.add_child(AstralTheme.label("Vocación asociada: %s" % voc_name, "CaptionLabel", AstralTheme.MUTED, true))
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
