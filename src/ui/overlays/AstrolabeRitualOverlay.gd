extends ModalOverlay
class_name AstrolabeRitualOverlay

## AstrolabeRitualOverlay - Minijuego interactivo de Sintonía del Astrolabio (1 vez por bimestre).
## El jugador alinea 3 órbitas estelares en rotación con el cenit dorado (☥) sin paredes de texto.

signal ritual_completed(summary: String, kind: String)

class _WheelCanvas extends Control:
	signal wheel_clicked()

	var angles: Array[float] = [0.0, 2.1, 4.2]
	var speeds: Array[float] = [1.85, -2.55, 3.25]
	var radii: Array[float] = [128.0, 92.0, 56.0]
	var locked: Array[bool] = [false, false, false]
	var grades: Array[int] = [0, 0, 0]   # 0=pendiente, 1=desviado, 2=alineado, 3=perfecto
	var active_ring: int = 0
	var sparks: Array[Dictionary] = []
	var shockwave: float = 0.0
	var shock_col: Color = Color(0.95, 0.80, 0.40, 1.0)
	var time_acc: float = 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(320, 320)
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			wheel_clicked.emit()
			accept_event()

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		time_acc += delta
		for i in range(3):
			if not locked[i]:
				angles[i] = fposmod(angles[i] + speeds[i] * delta, TAU)
		if shockwave > 0.0:
			shockwave = maxf(0.0, shockwave - delta * 2.2)
		for i in range(sparks.size() - 1, -1, -1):
			var sp: Dictionary = sparks[i]
			sp["life"] = float(sp["life"]) - delta
			if float(sp["life"]) <= 0.0:
				sparks.remove_at(i)
			else:
				sp["pos"] = (sp["pos"] as Vector2) + (sp["vel"] as Vector2) * delta
				sp["vel"] = (sp["vel"] as Vector2) * 0.94
		queue_redraw()

	func spawn_burst(pos: Vector2, col: Color, count: int) -> void:
		shockwave = 1.0
		shock_col = col
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		for i in range(count):
			var a: float = rng.randf() * TAU
			var spd: float = rng.randf_range(40.0, 145.0)
			sparks.append({
				"pos": pos,
				"vel": Vector2.from_angle(a) * spd,
				"life": rng.randf_range(0.35, 0.72),
				"max": 0.72,
				"col": col,
				"sz": rng.randf_range(2.2, 4.6)
			})

	func _draw() -> void:
		var c: Vector2 = size * 0.5
		var zenith_ang: float = -PI * 0.5
		var ring_cols: Array[Color] = [
			Color(0.95, 0.80, 0.42, 0.95),
			Color(0.34, 0.84, 0.78, 0.95),
			Color(0.82, 0.64, 0.98, 0.95)
		]

		# Fondo cósmico y retícula del cenit
		draw_circle(c, radii[0] + 18.0, Color(0.05, 0.08, 0.22, 0.68))
		draw_arc(c, radii[0] + 18.0, 0.0, TAU, 64, Color(0.84, 0.69, 0.36, 0.34), 1.8, true)
		for k in range(12):
			var ta: float = zenith_ang + float(k) * (TAU / 12.0)
			var p0: Vector2 = c + Vector2.from_angle(ta) * (radii[0] + 10.0)
			var p1: Vector2 = c + Vector2.from_angle(ta) * (radii[0] + 18.0)
			draw_line(p0, p1, Color(0.84, 0.69, 0.36, 0.55 if k == 0 else 0.22), 2.5 if k == 0 else 1.2, true)

		# Zona objetivo dorada en el cenit (-90°)
		var zen_pos: Vector2 = c + Vector2.from_angle(zenith_ang) * (radii[0] + 14.0)
		draw_line(c, zen_pos, Color(0.98, 0.86, 0.46, 0.32), 2.2, true)
		draw_arc(c, radii[0] + 14.0, zenith_ang - 0.24, zenith_ang + 0.24, 16, Color(0.98, 0.86, 0.46, 0.85), 5.0, true)
		draw_circle(zen_pos, 5.5 + sin(time_acc * 5.0) * 1.2, Color(1.0, 0.92, 0.56, 0.95))

		# Onda expansiva al fijar órbita
		if shockwave > 0.0:
			var sr: float = lerpf(radii[2], radii[0] + 24.0, 1.0 - shockwave)
			draw_arc(c, sr, 0.0, TAU, 48, Color(shock_col.r, shock_col.g, shock_col.b, shockwave * 0.65), 3.0, true)

		# Tres órbitas y sus astros
		for i in range(3):
			var r: float = radii[i]
			var is_cur: bool = (i == active_ring and not locked[i])
			var base_col: Color = ring_cols[i]
			var track_col: Color = Color(base_col.r, base_col.g, base_col.b, 0.85 if is_cur else (0.55 if locked[i] else 0.22))
			draw_arc(c, r, 0.0, TAU, 56, track_col, 3.2 if is_cur else 1.8, true)

			var orb_p: Vector2 = c + Vector2.from_angle(angles[i]) * r
			if locked[i]:
				var beam_col: Color = Color(0.98, 0.86, 0.46, 0.72) if grades[i] == 3 else (Color(0.36, 0.88, 0.82, 0.58) if grades[i] == 2 else Color(0.75, 0.68, 0.82, 0.38))
				draw_line(c, orb_p, beam_col, 2.4, true)
			draw_circle(orb_p, 12.0 if is_cur else 9.0, Color(base_col.r, base_col.g, base_col.b, 0.34))
			draw_circle(orb_p, 6.8 if is_cur else 5.4, Color(1.0, 0.98, 0.90, 1.0) if (is_cur or grades[i] >= 2) else base_col)

		# Conexiones entre astros fijados
		for i in range(2):
			if locked[i] and locked[i + 1]:
				var p_a: Vector2 = c + Vector2.from_angle(angles[i]) * radii[i]
				var p_b: Vector2 = c + Vector2.from_angle(angles[i + 1]) * radii[i + 1]
				draw_line(p_a, p_b, Color(0.95, 0.84, 0.48, 0.60), 1.8, true)

		# Partículas de chispa
		for sp in sparks:
			var a: float = clampf(float(sp["life"]) / float(sp["max"]), 0.0, 1.0)
			var col: Color = sp["col"]
			draw_circle(sp["pos"], float(sp["sz"]) * a, Color(col.r, col.g, col.b, a))

		# Centro del Sol Alado
		draw_circle(c, 10.0, Color(0.95, 0.80, 0.42, 0.92))
		draw_circle(c, 4.5, Color(1.0, 0.98, 0.88, 1.0))

var _wheel: _WheelCanvas
var _status_pills: Array[Label] = []
var _lock_btn: Button
var _close_btn: Button
var _reward_box: HBoxContainer
var _locked_count: int = 0
var _finished: bool = false

func _ready() -> void:
	set_panel_width(680)
	_max_height_ratio = 0.88
	super._ready()
	_build_ui()

func _build_ui() -> void:
	content.add_theme_constant_override("separation", 12)
	var title := AstralTheme.label("%s  SINTONÍA DEL ASTROLABIO CELESTE" % AstralTheme.G_ANKH, "HeadingLabel", AstralTheme.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)

	var hint := AstralTheme.label("Fija cada astro al cruzar el cenit dorado superior (clic, botón o ESPACIO). Un intento por bimestre.", "CaptionLabel", AstralTheme.MUTED, true)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(hint)

	var pills_row := AstralTheme.hbox(10)
	pills_row.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(pills_row)
	for i in range(3):
		var p := AstralTheme.panel("PillPanel")
		var l := AstralTheme.label("Órbita %d: Libre" % (i + 1), "CaptionLabel", AstralTheme.IVORY)
		p.add_child(l)
		pills_row.add_child(p)
		_status_pills.append(l)

	var wheel_wrap := CenterContainer.new()
	content.add_child(wheel_wrap)
	_wheel = _WheelCanvas.new()
	_wheel.wheel_clicked.connect(lock_current_ring)
	wheel_wrap.add_child(_wheel)

	_reward_box = AstralTheme.hbox(8)
	_reward_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_reward_box.visible = false
	content.add_child(_reward_box)

	var btns := AstralTheme.hbox(12)
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(btns)
	_lock_btn = AstralTheme.button("%s  FIJAR ÓRBITA I" % AstralTheme.G_ANKH, "PrimaryButton")
	_lock_btn.custom_minimum_size = Vector2(240, 50)
	_lock_btn.pressed.connect(lock_current_ring)
	btns.add_child(_lock_btn)

	_close_btn = AstralTheme.button("Cancelar", "TabLikeButton")
	_close_btn.custom_minimum_size = Vector2(180, 50)
	_close_btn.pressed.connect(hide_overlay)
	btns.add_child(_close_btn)

func open_ritual() -> void:
	_locked_count = 0
	_finished = false
	var rng := GameState.det_rng("astrolabe", GameState.stress + GameState.gold)
	_wheel.angles = [
		rng.randf_range(0.8, 2.5),
		rng.randf_range(2.9, 4.7),
		rng.randf_range(0.5, 5.2)
	]
	_wheel.speeds = [1.80, -2.50, 3.15]
	_wheel.locked = [false, false, false]
	_wheel.grades = [0, 0, 0]
	_wheel.active_ring = 0
	_wheel.sparks.clear()
	_wheel.shockwave = 0.0
	for i in range(3):
		_status_pills[i].text = "Órbita %d: Esperando" % (i + 1)
		_status_pills[i].add_theme_color_override("font_color", AstralTheme.MUTED)
	for c in _reward_box.get_children():
		c.queue_free()
	_reward_box.visible = false
	_lock_btn.disabled = false
	_lock_btn.text = "%s  FIJAR ÓRBITA I" % AstralTheme.G_ANKH
	_close_btn.text = "Cancelar"
	AstralAudio.play_ui()
	show_overlay()
	_fit()

func lock_current_ring() -> void:
	if _finished or _locked_count >= 3:
		return
	var idx: int = _locked_count
	var diff: float = absf(angle_difference(_wheel.angles[idx], -PI * 0.5))
	var grade: int = 1
	var grade_txt: String = "Desviado"
	var grade_col: Color = AstralTheme.MUTED
	if diff <= 0.24:
		grade = 3
		grade_txt = "%s Perfecto" % AstralTheme.G_STAR
		grade_col = AstralTheme.GOLD
		AstralAudio.play_triumph()
	elif diff <= 0.58:
		grade = 2
		grade_txt = "%s Alineado" % AstralTheme.G_STAR2
		grade_col = AstralTheme.TURQ
		AstralAudio.play_confirm()
	else:
		grade = 1
		grade_txt = "%s Desviado" % AstralTheme.G_MOON
		grade_col = AstralTheme.EMBER
		AstralAudio.play_ui()

	_wheel.locked[idx] = true
	_wheel.grades[idx] = grade
	var orb_pos: Vector2 = _wheel.size * 0.5 + Vector2.from_angle(_wheel.angles[idx]) * _wheel.radii[idx]
	_wheel.spawn_burst(orb_pos, grade_col, 14 if grade == 3 else (9 if grade == 2 else 5))

	_status_pills[idx].text = "Órbita %d: %s" % [idx + 1, grade_txt]
	_status_pills[idx].add_theme_color_override("font_color", grade_col)

	_locked_count += 1
	_wheel.active_ring = mini(2, _locked_count)
	var roman: Array[String] = ["I", "II", "III"]
	if _locked_count < 3:
		_lock_btn.text = "%s  FIJAR ÓRBITA %s" % [AstralTheme.G_ANKH, roman[_locked_count]]
	else:
		_complete_ritual()

func _complete_ritual() -> void:
	_finished = true
	_lock_btn.disabled = true
	_lock_btn.text = "%s  Sintonía Completada" % AstralTheme.G_CHECK
	_close_btn.text = "%s  Volver al Observatorio" % AstralTheme.G_CHECK

	var score: int = 0
	for g in _wheel.grades:
		score += maxi(0, g - 1)   # max 6 (3 perfectos)

	var lum_g: int = 3
	var res_g: int = 3
	var stress_d: int = 0
	var tier_title: String = "Órbita Inestable"
	var kind: String = "info"
	if score >= 5:
		lum_g = 12; res_g = 12; stress_d = -5
		tier_title = "✦ Alineación Suprema"
		kind = "good"
	elif score >= 3:
		lum_g = 8; res_g = 8; stress_d = -2
		tier_title = "✧ Armonía Celeste"
		kind = "good"
	elif score >= 1:
		lum_g = 4; res_g = 6
		tier_title = "✦ Destello Estelar"

	TurnExecutor.astrolabe_tuned_this_bimester = true
	GameState.begin_batch()
	var d_lum: int = GameState.modify_stat("luminiscencia", lum_g)
	var d_res: int = GameState.modify_stat("resonancia", res_g)
	var d_str: int = GameState.modify_stat("stress", stress_d) if stress_d != 0 else 0
	GameState.end_batch()

	var badges: Array[Array] = [
		[tier_title, AstralTheme.GOLD if score >= 5 else AstralTheme.TURQ],
		["Luminiscencia +%d" % d_lum, AstralTheme.GOOD],
		["Resonancia +%d" % d_res, AstralTheme.TURQ]
	]
	if d_str != 0:
		badges.append(["Estrés %s" % AstralTheme.signed(d_str), AstralTheme.GOOD])
	for b in badges:
		var p := AstralTheme.panel("PillPanel")
		p.add_child(AstralTheme.label(str(b[0]), "CaptionLabel", b[1]))
		_reward_box.add_child(p)
	_reward_box.visible = true
	_fit()

	var summary: String = "%s: Luminiscencia +%d, Resonancia +%d%s" % [
		tier_title, d_lum, d_res, (", Estrés %s" % AstralTheme.signed(d_str)) if d_str != 0 else ""
	]
	ritual_completed.emit(summary, kind)

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var kc: int = (event as InputEventKey).keycode
		if kc == KEY_SPACE or kc == KEY_ENTER:
			if not _finished:
				lock_current_ring()
			else:
				hide_overlay()
			get_viewport().set_input_as_handled()
		elif kc == KEY_ESCAPE:
			hide_overlay()
			get_viewport().set_input_as_handled()
