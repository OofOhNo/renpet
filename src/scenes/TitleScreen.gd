extends Control

## Pantalla de título: Nueva Partida, Continuar (partida más reciente), Cargar y Salir.

const MANOR_SCENE: String = "res://src/scenes/ManorHub.tscn"

var _menu: MenuOverlay
var _tapestry: ConstellationOverlay
var _tap_btn: Button
var _anim: float = 0.0
var _title_label: Label

func _ready() -> void:
	theme = AstralTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := TextureRect.new()
	bg.texture = load("res://assets/art/bg_prologue_goddess.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.02, 0.09, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	add_child(StarField.new())

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := AstralTheme.vbox(14)
	col.custom_minimum_size.x = 520
	center.add_child(col)

	col.add_child(AstralTheme.label(AstralTheme.G_ANKH, "TitleLabel", AstralTheme.GOLD))
	(col.get_child(0) as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	(col.get_child(0) as Label).add_theme_font_size_override("font_size", 64)
	_title_label = AstralTheme.label("RENPET", "TitleLabel")
	_title_label.add_theme_font_size_override("font_size", 92)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title_label)
	var sub := AstralTheme.label("LA SEÑORA DE LA ETERNIDAD", "SubLabel", AstralTheme.GOLD, true)
	sub.add_theme_font_size_override("font_size", 30)
	sub.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.12, 0.95))
	sub.add_theme_constant_override("outline_size", 10)
	sub.add_theme_color_override("font_color", AstralTheme.GOLD_PALE)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	col.add_child(AstralTheme.spacer(false, 26))

	var latest: int = _latest_slot()
	var b_new := AstralTheme.button("Nueva Partida", "PrimaryButton")
	b_new.custom_minimum_size.y = 62
	b_new.pressed.connect(_new_game)
	col.add_child(b_new)
	var b_cont := AstralTheme.button("Continuar")
	b_cont.custom_minimum_size.y = 56
	b_cont.disabled = latest < 0
	b_cont.pressed.connect(func() -> void: _load(latest))
	col.add_child(b_cont)
	var b_load := AstralTheme.button("Cargar partida")
	b_load.custom_minimum_size.y = 56
	b_load.disabled = not SaveManager.has_any_save()
	b_load.pressed.connect(func() -> void: _menu.open_slots(MenuOverlay.Mode.LOAD))
	col.add_child(b_load)
	var total_matrix: int = EndingEvaluator.BRANCH_ORDER.size() * EndingEvaluator.VOCATION_ORDER.size()
	_tap_btn = AstralTheme.button("%s  El Tapiz de las Constelaciones (%d/%d)" % [AstralTheme.G_STAR, ConstellationTapestry.discovered_endings.size(), total_matrix])
	_tap_btn.custom_minimum_size.y = 54
	_tap_btn.pressed.connect(func() -> void: _tapestry.open_tapestry(0))
	col.add_child(_tap_btn)
	if not OS.has_feature("web"):
		var b_quit := AstralTheme.button("Salir", "DangerButton")
		b_quit.custom_minimum_size.y = 52
		b_quit.pressed.connect(func() -> void: get_tree().quit())
		col.add_child(b_quit)

	var foot := AstralTheme.label("Campaña Completa (Fases 1 a 9 · 65 Finales & NG+)  ·  Godot %s" % Engine.get_version_info()["string"], "CaptionLabel", AstralTheme.MUTED)
	foot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_MINSIZE, 14)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(foot)

	_menu = MenuOverlay.new()
	add_child(_menu)
	_menu.load_requested.connect(_load)
	_tapestry = ConstellationOverlay.new()
	add_child(_tapestry)
	ConstellationTapestry.tapestry_updated.connect(_refresh_tap_btn)

	b_new.grab_focus()

func _process(delta: float) -> void:
	_anim += delta
	if _title_label != null:
		var g: float = 0.88 + 0.12 * sin(_anim * 1.4)
		_title_label.modulate = Color(g, g, g * 0.95)

func _latest_slot() -> int:
	var best: int = -1
	var best_t: int = -1
	for e in SaveManager.list_slots():
		if e["exists"] and e["valid"] and int(e["saved_at"]) >= best_t:
			best_t = int(e["saved_at"])
			best = int(e["slot"])
	return best

func _new_game() -> void:
	SaveManager.pending_load_slot = -1
	get_tree().change_scene_to_file(MANOR_SCENE)

func _refresh_tap_btn() -> void:
	if _tap_btn != null:
		var total_matrix: int = EndingEvaluator.BRANCH_ORDER.size() * EndingEvaluator.VOCATION_ORDER.size()
		_tap_btn.text = "%s  El Tapiz de las Constelaciones (%d/%d)" % [AstralTheme.G_STAR, ConstellationTapestry.discovered_endings.size(), total_matrix]

func _load(slot: int) -> void:
	SaveManager.pending_load_slot = slot
	get_tree().change_scene_to_file(MANOR_SCENE)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_F11:
		var full: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
