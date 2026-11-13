extends Control

## Pantalla de título: Nueva Partida, Continuar (partida más reciente), Cargar y Salir.

const MANOR_SCENE: String = "res://src/scenes/ManorHub.tscn"

var _menu: MenuOverlay
var _tapestry: ConstellationOverlay
var _tap_btn: Button
var _boon_hint: Label
var _anim: float = 0.0
var _title_label: Label
var _ring_layer: Control
var _ring_outer: TextureRect
var _ring_inner: TextureRect
var _mute_btn: Button

func _ready() -> void:
	theme = AstralTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	AstralAudio.set_music_mood("title")

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

	_ring_layer = Control.new()
	_ring_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ring_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ring_layer)
	_ring_outer = _make_title_ring("res://assets/ui/astrolabe_ring_outer.png", Color(0.84, 0.69, 0.36, 0.16), 620.0)
	_ring_inner = _make_title_ring("res://assets/ui/astrolabe_ring_inner.png", Color(0.32, 0.72, 0.68, 0.18), 440.0)
	_ring_layer.add_child(_ring_outer)
	_ring_layer.add_child(_ring_inner)
	_ring_layer.resized.connect(_layout_rings)
	call_deferred("_layout_rings")

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
	b_new.pressed.connect(func() -> void:
		AstralAudio.play_confirm()
		_new_game())
	col.add_child(b_new)
	var b_cont := AstralTheme.button("Continuar")
	b_cont.custom_minimum_size.y = 56
	b_cont.disabled = latest < 0
	b_cont.pressed.connect(func() -> void:
		AstralAudio.play_confirm()
		_load(latest))
	col.add_child(b_cont)
	var b_load := AstralTheme.button("Cargar partida")
	b_load.custom_minimum_size.y = 56
	b_load.disabled = not SaveManager.has_any_save()
	b_load.pressed.connect(func() -> void:
		AstralAudio.play_ui()
		_menu.open_slots(MenuOverlay.Mode.LOAD))
	col.add_child(b_load)
	var total_matrix: int = EndingEvaluator.BRANCH_ORDER.size() * EndingEvaluator.VOCATION_ORDER.size()
	_tap_btn = AstralTheme.button("%s  El Tapiz de las Constelaciones (%d/%d)" % [AstralTheme.G_STAR, ConstellationTapestry.discovered_endings.size(), total_matrix])
	_tap_btn.custom_minimum_size.y = 54
	_tap_btn.pressed.connect(func() -> void:
		AstralAudio.play_ui()
		_tapestry.open_tapestry(0))
	col.add_child(_tap_btn)
	var b_opts := AstralTheme.button("%s  Opciones y Audio" % AstralTheme.G_ANKH)
	b_opts.custom_minimum_size.y = 50
	b_opts.pressed.connect(func() -> void:
		AstralAudio.play_ui()
		_menu.open_settings())
	col.add_child(b_opts)
	_boon_hint = AstralTheme.label("", "CaptionLabel", AstralTheme.GOOD, true)
	_boon_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_boon_hint)
	if not OS.has_feature("web"):
		var b_quit := AstralTheme.button("Salir", "DangerButton")
		b_quit.custom_minimum_size.y = 52
		b_quit.pressed.connect(func() -> void: get_tree().quit())
		col.add_child(b_quit)

	var foot := AstralTheme.label("Crónica Estelar · 65 Finales y Tapiz de Constelaciones  ·  Godot %s" % Engine.get_version_info()["string"], "CaptionLabel", AstralTheme.MUTED)
	foot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_MINSIZE, 14)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(foot)

	_mute_btn = AstralTheme.button("", "TabLikeButton", "Activa o silencia los efectos sonoros del observatorio")
	_mute_btn.anchor_left = 1.0
	_mute_btn.anchor_right = 1.0
	_mute_btn.anchor_top = 0.0
	_mute_btn.anchor_bottom = 0.0
	_mute_btn.offset_left = -162
	_mute_btn.offset_right = -20
	_mute_btn.offset_top = 18
	_mute_btn.offset_bottom = 54
	_mute_btn.pressed.connect(func() -> void: AstralAudio.toggle_mute())
	add_child(_mute_btn)
	AstralAudio.mute_changed.connect(_sync_mute_btn)
	_sync_mute_btn(AstralAudio.muted)

	_menu = MenuOverlay.new()
	add_child(_menu)
	_menu.load_requested.connect(_load)
	_tapestry = ConstellationOverlay.new()
	add_child(_tapestry)
	ConstellationTapestry.tapestry_updated.connect(_refresh_tap_btn)
	_refresh_tap_btn()

	b_new.grab_focus()

func _process(delta: float) -> void:
	_anim += delta
	if _title_label != null:
		var g: float = 0.88 + 0.12 * sin(_anim * 1.4)
		_title_label.modulate = Color(g, g, g * 0.95)
	if _ring_outer != null:
		_ring_outer.rotation += delta * 0.045
	if _ring_inner != null:
		_ring_inner.rotation -= delta * 0.072

func _make_title_ring(path: String, tint: Color, sz: float) -> TextureRect:
	var t := TextureRect.new()
	if ResourceLoader.exists(path):
		t.texture = load(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.modulate = tint
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.size = Vector2(sz, sz)
	t.pivot_offset = Vector2(sz * 0.5, sz * 0.5)
	return t

func _layout_rings() -> void:
	if _ring_layer == null:
		return
	var c: Vector2 = _ring_layer.size * 0.5
	for r in [_ring_outer, _ring_inner]:
		if r != null:
			r.pivot_offset = r.size * 0.5
			r.position = c - r.size * 0.5

func _sync_mute_btn(is_muted: bool) -> void:
	if _mute_btn != null:
		_mute_btn.text = "%s  Audio: %s" % [AstralTheme.G_MOON if is_muted else AstralTheme.G_SUN, "OFF" if is_muted else "ON"]

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
	_fade_to_manor()

func _refresh_tap_btn() -> void:
	if _tap_btn != null:
		var total_matrix: int = EndingEvaluator.BRANCH_ORDER.size() * EndingEvaluator.VOCATION_ORDER.size()
		_tap_btn.text = "%s  El Tapiz de las Constelaciones (%d/%d)" % [AstralTheme.G_STAR, ConstellationTapestry.discovered_endings.size(), total_matrix]
	if _boon_hint != null:
		var bnames: Array[String] = ConstellationTapestry.get_active_boon_names()
		_boon_hint.visible = not bnames.is_empty()
		if _boon_hint.visible:
			_boon_hint.text = "%s  NG+ activo (%d): %s" % [AstralTheme.G_STAR2, bnames.size(), ", ".join(bnames)]

func _load(slot: int) -> void:
	SaveManager.pending_load_slot = slot
	_fade_to_manor()

func _fade_to_manor() -> void:
	if DisplayServer.get_name() == "headless":
		get_tree().change_scene_to_file(MANOR_SCENE)
		return
	var curtain := ColorRect.new()
	curtain.color = Color(0.01, 0.015, 0.06, 0.0)
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(curtain)
	var tw := create_tween()
	tw.tween_property(curtain, "color:a", 1.0, 0.30)
	tw.tween_callback(func() -> void: get_tree().change_scene_to_file(MANOR_SCENE))

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var kc: int = (event as InputEventKey).keycode
	if kc == KEY_ESCAPE:
		if _tapestry != null and _tapestry.visible:
			_tapestry.hide_overlay()
			get_viewport().set_input_as_handled()
		elif _menu != null and _menu.visible:
			_menu.hide_overlay()
			get_viewport().set_input_as_handled()
	elif kc == KEY_F11:
		SettingsManager.toggle_fullscreen()
