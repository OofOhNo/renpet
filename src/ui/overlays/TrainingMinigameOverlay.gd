extends "res://src/ui/overlays/ModalOverlay.gd"
class_name TrainingMinigameOverlay

## Minijuegos contextuales multi-estado de Aethelgard:
##   1) "fencing" (3 fases): Guardia móvil -> Finta carmesí y Contraataque -> Remate rápido.
##   2) "rhythm"  (3 fases): Andante -> Acordes Dorados (x2) -> Crescendo final.
## Compatible con práctica en la ciudad, pruebas prácticas de clase/oficio difíciles y Asalto 2 del Festival.

signal minigame_finished(summary: String)
signal challenge_completed(mode: String, score: int, max_score: int, pct: float)

class _ArenaCanvas extends Control:
	var mode: String = "fencing"
	var state_tag: String = ""
	var bg_tex: Texture2D
	var cursor_x: float = 0.1
	var zone_center: float = 0.5
	var zone_half: float = 0.14
	var perfect_half: float = 0.055
	var feint_active: bool = false
	var counter_ready: bool = false
	var hit_flash: float = 0.0
	var flash_col: Color = Color("f7e3a1")
	var feedback_text: String = ""
	var sparks: Array[Dictionary] = []
	var rings: Array[Dictionary] = []

	# Campos de Armonización Coral (3 carriles)
	var notes: Array = []   # {"lane": int, "y": float, "hit": bool, "kind": "normal"|"gold"}
	var hit_y: float = 0.80
	var lane_flash: Array[float] = [0.0, 0.0, 0.0]

	func spawn_hit_fx(pos: Vector2, col: Color, big: bool = false) -> void:
		rings.append({"pos": pos, "col": col, "life": 0.0, "max": 0.42 if big else 0.30, "r": 58.0 if big else 38.0})
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var n: int = 16 if big else 9
		for i in range(n):
			var a: float = (float(i) / float(n)) * TAU + rng.randf_range(-0.2, 0.2)
			sparks.append({"pos": pos, "vel": Vector2.from_angle(a) * rng.randf_range(65.0, 175.0 if big else 120.0), "life": 0.0, "max": rng.randf_range(0.28, 0.48), "col": col})

	func _process(delta: float) -> void:
		for i in range(sparks.size() - 1, -1, -1):
			var s: Dictionary = sparks[i]
			s["life"] = float(s["life"]) + delta
			if float(s["life"]) >= float(s["max"]):
				sparks.remove_at(i)
			else:
				s["pos"] = (s["pos"] as Vector2) + (s["vel"] as Vector2) * delta
				s["vel"] = (s["vel"] as Vector2) * 0.90
		for i in range(rings.size() - 1, -1, -1):
			var r: Dictionary = rings[i]
			r["life"] = float(r["life"]) + delta
			if float(r["life"]) >= float(r["max"]):
				rings.remove_at(i)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.05, 0.12, 0.96), true)
		if bg_tex != null and size.x > 16.0 and size.y > 16.0:
			var tsz: Vector2 = bg_tex.get_size()
			var rect := Rect2(Vector2.ZERO, size)
			if tsz.x > 1.0 and tsz.y > 1.0:
				var sc: float = maxf(size.x / tsz.x, size.y / tsz.y)
				var dw: float = size.x / sc
				var dh: float = size.y / sc
				var src := Rect2((tsz.x - dw) * 0.5, (tsz.y - dh) * 0.5, dw, dh)
				draw_texture_rect_region(bg_tex, rect, src, Color(1, 1, 1, 0.34))
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.05, 0.14, 0.36), true)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.76, 0.64, 0.38, 0.58), false, 1.5)

		if state_tag != "":
			draw_rect(Rect2(10, 8, size.x - 20, 22), Color(0.08, 0.12, 0.22, 0.85), true)

		if mode == "fencing":
			var bar := Rect2(36.0, size.y * 0.50 - 20.0, size.x - 72.0, 40.0)
			draw_rect(bar, Color(0.10, 0.14, 0.28, 0.96), true)
			draw_rect(bar, Color(0.32, 0.42, 0.65, 0.55), false, 1.0)

			var zw_x: float = bar.position.x + bar.size.x * clampf(zone_center - zone_half, 0.0, 1.0)
			var zw_r: float = bar.position.x + bar.size.x * clampf(zone_center + zone_half, 0.0, 1.0)
			var good_col: Color = Color(0.95, 0.28, 0.36, 0.48) if feint_active else (Color(0.22, 0.92, 0.84, 0.46) if counter_ready else Color(0.18, 0.52, 0.52, 0.42))
			draw_rect(Rect2(zw_x, bar.position.y - 3.0, maxf(6.0, zw_r - zw_x), bar.size.y + 6.0), good_col, true)

			var pw_l: float = bar.position.x + bar.size.x * clampf(zone_center - perfect_half, 0.0, 1.0)
			var pw_r: float = bar.position.x + bar.size.x * clampf(zone_center + perfect_half, 0.0, 1.0)
			var core_col: Color = Color(0.96, 0.30, 0.38, 0.78) if feint_active else (Color(0.45, 1.0, 0.92, 0.85) if counter_ready else Color(0.92, 0.78, 0.34, 0.65))
			draw_rect(Rect2(pw_l, bar.position.y - 7.0, maxf(6.0, pw_r - pw_l), bar.size.y + 14.0), core_col, true)

			var center_px: float = bar.position.x + bar.size.x * zone_center
			draw_line(Vector2(center_px, bar.position.y - 11.0), Vector2(center_px, bar.end.y + 11.0), Color(1.0, 0.97, 0.88, 0.88), 2.0)

			var cx: float = bar.position.x + bar.size.x * clampf(cursor_x, 0.0, 1.0)
			var cy: float = bar.position.y + bar.size.y * 0.5
			draw_circle(Vector2(cx, cy), 13.0, Color(0.98, 0.90, 0.56))
			draw_circle(Vector2(cx, cy), 7.0, Color(0.32, 0.86, 0.84))
		else:
			var lane_cols: Array[Color] = [Color("49d6c8"), Color("f7e3a1"), Color("d7a7ff")]
			var lane_w: float = (size.x - 80.0) / 3.0
			var hy: float = size.y * hit_y
			draw_line(Vector2(28.0, hy), Vector2(size.x - 28.0, hy), Color(0.95, 0.84, 0.45, 0.80), 3.0)
			for i in range(3):
				var lx: float = 40.0 + lane_w * (float(i) + 0.5)
				var base_a: float = 0.16 + lane_flash[i] * 0.42
				draw_rect(Rect2(lx - lane_w * 0.38, 12.0, lane_w * 0.76, size.y - 24.0), Color(lane_cols[i].r, lane_cols[i].g, lane_cols[i].b, base_a), true)
				draw_circle(Vector2(lx, hy), 20.0, Color(lane_cols[i].r, lane_cols[i].g, lane_cols[i].b, 0.28))
				draw_arc(Vector2(lx, hy), 20.0, 0.0, TAU, 24, lane_cols[i], 2.0, true)
			for n in notes:
				if bool(n.get("hit", false)):
					continue
				var ny: float = float(n["y"]) * size.y
				if ny < 10.0 or ny > size.y - 10.0:
					continue
				var ln: int = int(n["lane"])
				var lx2: float = 40.0 + lane_w * (float(ln) + 0.5)
				var is_gold: bool = (str(n.get("kind", "normal")) == "gold")
				var ncol: Color = Color("ffcf5a") if is_gold else lane_cols[ln]
				draw_circle(Vector2(lx2, ny), 16.0 if is_gold else 13.0, ncol)
				draw_circle(Vector2(lx2, ny), 7.5 if is_gold else 6.0, Color(1, 1, 1, 0.92))

		for r in rings:
			var rk: float = clampf(float(r["life"]) / float(r["max"]), 0.0, 1.0)
			var rcol: Color = r["col"]
			draw_arc(r["pos"], 8.0 + rk * float(r["r"]), 0.0, TAU, 28, Color(rcol.r, rcol.g, rcol.b, 1.0 - rk), 3.0 * (1.0 - rk) + 0.6, true)
		for s in sparks:
			var sk: float = clampf(float(s["life"]) / float(s["max"]), 0.0, 1.0)
			var scol: Color = s["col"]
			draw_circle(s["pos"], 4.2 * (1.0 - sk) + 1.0, Color(scol.r, scol.g, scol.b, 1.0 - sk))

		if hit_flash > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(flash_col.r, flash_col.g, flash_col.b, hit_flash * 0.24), true)

var _mode: String = "fencing"
var _locked_mode: bool = false
var _apply_rewards: bool = true
var _title_override: String = ""

var _canvas: _ArenaCanvas
var _title_lbl: Label
var _phase_lbl: Label
var _status_lbl: Label
var _result_lbl: Label
var _mode_row: HBoxContainer
var _fence_btn: Button
var _rhythm_row: HBoxContainer
var _done_btn: Button
var _btn_fence_mode: Button
var _btn_rhythm_mode: Button

var _running: bool = false
var _round: int = 0
var _score: int = 0
var _streak: int = 0
var _cursor_dir: float = 1.0
var _fence_phase_t: float = 0.0
var _rhythm_t: float = 0.0
var _note_idx: int = 0

const FENCE_ROUNDS: int = 6
const FENCE_MAX_SCORE: int = 12
const RHYTHM_BEATS: int = 8
const RHYTHM_MAX_SCORE: int = 11

func _ready() -> void:
	set_panel_width(820)
	super._ready()
	visible = false

	_title_lbl = AstralTheme.label("", "HeadingLabel", AstralTheme.GOLD)
	content.add_child(_title_lbl)
	content.add_child(AstralTheme.separator())

	_phase_lbl = AstralTheme.label("", "CaptionLabel", AstralTheme.TURQ, true)
	content.add_child(_phase_lbl)

	_mode_row = AstralTheme.hbox(10)
	content.add_child(_mode_row)
	_btn_fence_mode = AstralTheme.button("%s  Esgrima (Temple / Destreza)" % AstralTheme.G_SWORD, "TabLikeButton")
	_btn_fence_mode.pressed.connect(func() -> void:
		if not _locked_mode:
			open_minigame("fencing", false, "", _apply_rewards))
	_btn_rhythm_mode = AstralTheme.button("%s  Armonización (Gracia / -Estrés)" % AstralTheme.G_FLOWER, "TabLikeButton")
	_btn_rhythm_mode.pressed.connect(func() -> void:
		if not _locked_mode:
			open_minigame("rhythm", false, "", _apply_rewards))
	_mode_row.add_child(_btn_fence_mode)
	_mode_row.add_child(_btn_rhythm_mode)

	_status_lbl = AstralTheme.label("", "SubLabel", AstralTheme.GOLD_PALE)
	content.add_child(_status_lbl)

	_canvas = _ArenaCanvas.new()
	_canvas.custom_minimum_size = Vector2(0, 210)
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_canvas)

	_result_lbl = AstralTheme.label("", "SubLabel", AstralTheme.GOLD, true)
	content.add_child(_result_lbl)

	_fence_btn = AstralTheme.button("%s  ESTOCADA / CONTRAATAQUE  [ESPACIO]" % AstralTheme.G_SWORD, "PrimaryButton")
	_fence_btn.custom_minimum_size.y = 52
	_fence_btn.pressed.connect(_do_fencing_strike)
	content.add_child(_fence_btn)

	_rhythm_row = AstralTheme.hbox(10)
	content.add_child(_rhythm_row)
	for i in range(3):
		var col_lbl: String = ["✦ Turquesa [A / 1]", "☀ Ámbar [S / 2]", "☾ Violeta [D / 3]"][i]
		var lb := AstralTheme.button(col_lbl, "TabLikeButton")
		lb.custom_minimum_size.y = 50
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var lane_i: int = i
		lb.pressed.connect(func() -> void: _do_rhythm_lane(lane_i))
		_rhythm_row.add_child(lb)

	_done_btn = AstralTheme.button("Continuar  ▶", "TabLikeButton")
	_done_btn.custom_minimum_size.y = 48
	_done_btn.pressed.connect(_cancel_or_close)
	content.add_child(_done_btn)

func open_minigame(mode: String = "fencing", locked_mode: bool = false, title_override: String = "", apply_rewards: bool = true) -> void:
	_mode = mode if mode in ["fencing", "rhythm"] else "fencing"
	_locked_mode = locked_mode
	_apply_rewards = apply_rewards
	_title_override = title_override

	_running = true
	_round = 0
	_score = 0
	_streak = 0
	_cursor_dir = 1.0
	_fence_phase_t = 0.0
	_rhythm_t = 0.0
	_note_idx = 0
	_result_lbl.text = ""
	_done_btn.text = "Omitir reto ▶" if not _apply_rewards else "Volver ▶"

	_mode_row.visible = not _locked_mode
	_btn_fence_mode.button_pressed = (_mode == "fencing")
	_btn_rhythm_mode.button_pressed = (_mode == "rhythm")
	_fence_btn.visible = (_mode == "fencing")
	_fence_btn.disabled = false
	_rhythm_row.visible = (_mode == "rhythm")

	_canvas.mode = _mode
	_canvas.bg_tex = AstralTheme.load_tex("res://assets/art/bg_district_patio.png" if _mode == "fencing" else "res://assets/art/bg_coliseum_festival.png")
	_canvas.sparks.clear()
	_canvas.rings.clear()
	_canvas.cursor_x = 0.1
	_canvas.zone_center = 0.5
	_canvas.zone_half = 0.16
	_canvas.perfect_half = 0.055
	_canvas.feint_active = false
	_canvas.counter_ready = false
	_canvas.notes.clear()

	if _title_override != "":
		_title_lbl.text = "%s  %s" % [AstralTheme.G_SWORD if _mode == "fencing" else AstralTheme.G_FLOWER, _title_override]
	elif _mode == "fencing":
		_title_lbl.text = "%s  PATIO DE ARMAS: ESGRIMA EN 3 ESTADOS" % AstralTheme.G_SWORD
	else:
		_title_lbl.text = "%s  ANFITEATRO: ARMONIZACIÓN CORAL" % AstralTheme.G_FLOWER

	if _mode == "rhythm":
		_spawn_rhythm_notes()

	_update_fencing_phase_visuals()
	_update_status()
	show_overlay()

func _spawn_rhythm_notes() -> void:
	var rng := GameState.det_rng("mg_rhythm_v2", TimeManager.current_total_turn + _score)
	_canvas.notes.clear()
	# 8 compases: 1-3 Andante (1 nota), 4-6 Acorde Dorado (nota oro x2), 7-8 Crescendo rápido
	for i in range(RHYTHM_BEATS):
		var kind: String = "gold" if (i in [3, 4, 5]) else "normal"
		var start_y: float = -0.10 - float(i) * 0.25
		if i >= 6:
			start_y = -0.10 - 5.0 * 0.25 - float(i - 5) * 0.19
		_canvas.notes.append({
			"lane": rng.randi_range(0, 2),
			"y": start_y,
			"hit": false,
			"kind": kind,
			"step": i + 1
		})

func _update_fencing_phase_visuals() -> void:
	if _mode != "fencing":
		var phase_r: String = "FASE 1 · ANDANTE" if _note_idx < 3 else ("FASE 2 · ACORDES DORADOS (x2 PTS)" if _note_idx < 6 else "FASE 3 · CRESCENDO FINAL")
		_phase_lbl.text = "%s  —  Pulsa cada esfera al cruzar el aro luminoso." % phase_r
		return
	if _round < 2:
		_canvas.zone_half = 0.17
		_canvas.perfect_half = 0.06
		_canvas.feint_active = false
		_canvas.counter_ready = false
		_phase_lbl.text = "ESTADO 1 · GUARDIA MÓVIL — La zona dorada oscila suavemente. Busca el centro exacto (+2 pts)."
	elif _round < 4:
		_canvas.zone_half = 0.15
		_canvas.perfect_half = 0.065
		_phase_lbl.text = "ESTADO 2 · FINTA Y CONTRAATAQUE — ¡Espera que la zona ROJA vire a TURQUESA para contraatacar!"
	else:
		_canvas.zone_half = 0.13
		_canvas.perfect_half = 0.055
		_canvas.feint_active = false
		_canvas.counter_ready = false
		_phase_lbl.text = "ESTADO 3 · REMATE RELÁMPAGO — Hoja a doble velocidad. Clava el golpe dorado final (+2 pts)."

func _process(delta: float) -> void:
	if not visible:
		return
	if _canvas.hit_flash > 0.0:
		_canvas.hit_flash = maxf(0.0, _canvas.hit_flash - delta * 3.0)
	for i in range(3):
		if _canvas.lane_flash[i] > 0.0:
			_canvas.lane_flash[i] = maxf(0.0, _canvas.lane_flash[i] - delta * 4.0)

	if _running:
		if _mode == "fencing":
			_fence_phase_t += delta
			var speed: float = 1.25 if _round < 2 else (1.42 if _round < 4 else 1.88)
			_canvas.cursor_x += _cursor_dir * speed * delta
			if _canvas.cursor_x >= 0.96:
				_canvas.cursor_x = 0.96
				_cursor_dir = -1.0
			elif _canvas.cursor_x <= 0.04:
				_canvas.cursor_x = 0.04
				_cursor_dir = 1.0

			if _round < 2:
				_canvas.zone_center = 0.5 + sin(_fence_phase_t * 1.9) * 0.22
				_canvas.feint_active = false
				_canvas.counter_ready = false
			elif _round < 4:
				_canvas.zone_center = 0.5 + sin(_fence_phase_t * 1.3) * 0.14
				var cycle: float = fmod(_fence_phase_t, 1.55)
				_canvas.feint_active = cycle < 0.72
				_canvas.counter_ready = not _canvas.feint_active
			else:
				_canvas.zone_center = 0.5 + sin(_fence_phase_t * 3.1) * 0.24
				_canvas.feint_active = false
				_canvas.counter_ready = false
		else:
			_rhythm_t += delta
			var spd: float = 0.34 if _note_idx < 3 else (0.39 if _note_idx < 6 else 0.48)
			var highest_step: int = _note_idx
			var missed: bool = false
			for n in _canvas.notes:
				if not bool(n["hit"]):
					n["y"] = float(n["y"]) + spd * delta
					if float(n["y"]) >= 0.35:
						highest_step = maxi(highest_step, int(n["step"]))
					if float(n["y"]) > 0.95:
						n["hit"] = true
						missed = true
						_streak = 0
						_canvas.flash_col = AstralTheme.BAD
						_canvas.hit_flash = 0.55
						_note_idx = maxi(_note_idx, int(n["step"]))
			if highest_step != _note_idx:
				_note_idx = highest_step
			if missed:
				_update_fencing_phase_visuals()
				_update_status()
			var all_done: bool = true
			for n in _canvas.notes:
				if not bool(n["hit"]):
					all_done = false
					break
			if all_done:
				_complete_minigame()
	_canvas.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _running:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if _mode == "fencing" and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			_do_fencing_strike()
			get_viewport().set_input_as_handled()
		elif _mode == "rhythm":
			if event.keycode in [KEY_A, KEY_1, KEY_LEFT]:
				_do_rhythm_lane(0)
				get_viewport().set_input_as_handled()
			elif event.keycode in [KEY_S, KEY_2, KEY_DOWN]:
				_do_rhythm_lane(1)
				get_viewport().set_input_as_handled()
			elif event.keycode in [KEY_D, KEY_3, KEY_RIGHT]:
				_do_rhythm_lane(2)
				get_viewport().set_input_as_handled()

func _do_fencing_strike() -> void:
	if not _running or _mode != "fencing":
		return
	_round += 1
	var dist: float = absf(_canvas.cursor_x - _canvas.zone_center)
	if _canvas.feint_active:
		_streak = 0
		_canvas.flash_col = AstralTheme.BAD
		_result_lbl.text = "¡Caíste en la finta carmesí! Espera el destello turquesa (+0 pts)."
		AstralAudio.play_warn()
	elif dist <= _canvas.perfect_half or (_canvas.counter_ready and dist <= _canvas.zone_half):
		_score += 2
		_streak += 1
		_canvas.flash_col = AstralTheme.GOLD
		_canvas.spawn_hit_fx(Vector2(36.0 + (_canvas.size.x - 72.0) * clampf(_canvas.cursor_x, 0.0, 1.0), _canvas.size.y * 0.5), AstralTheme.GOLD, true)
		_result_lbl.text = "✦ ¡CONTRAATAQUE / CRÍTICO PERFECTO! (+2 pts · Racha %d)" % _streak if _canvas.counter_ready else "✦ ¡ESTOCADA PERFECTA! (+2 pts · Racha %d)" % _streak
		AstralAudio.play_triumph()
	elif dist <= _canvas.zone_half:
		_score += 1
		_streak += 1
		_canvas.flash_col = AstralTheme.TURQ
		_canvas.spawn_hit_fx(Vector2(36.0 + (_canvas.size.x - 72.0) * clampf(_canvas.cursor_x, 0.0, 1.0), _canvas.size.y * 0.5), AstralTheme.TURQ, false)
		_result_lbl.text = "✓ Golpe limpio en guardia (+1 pt)."
		AstralAudio.play_confirm()
	else:
		_streak = 0
		_canvas.flash_col = AstralTheme.EMBER
		_result_lbl.text = "✕ Estocada desviada (0 pts)."
		AstralAudio.play_warn()
	_canvas.hit_flash = 0.9
	if _round >= FENCE_ROUNDS:
		_complete_minigame()
	else:
		_update_fencing_phase_visuals()
		_update_status()

func _do_rhythm_lane(lane_idx: int) -> void:
	if not _running or _mode != "rhythm":
		return
	_canvas.lane_flash[lane_idx] = 1.0
	var best_note: Dictionary = {}
	var best_d: float = 99.0
	for n in _canvas.notes:
		if bool(n["hit"]) or int(n["lane"]) != lane_idx:
			continue
		var d: float = absf(float(n["y"]) - _canvas.hit_y)
		if d < best_d:
			best_d = d
			best_note = n
	if best_note.is_empty() or best_d > 0.16:
		_streak = 0
		_canvas.flash_col = AstralTheme.EMBER
		_canvas.hit_flash = 0.4
		_result_lbl.text = "Compás fuera de tiempo..."
		AstralAudio.play_warn()
		return
	best_note["hit"] = true
	_note_idx = maxi(_note_idx, int(best_note.get("step", _note_idx + 1)))
	var pts: int = 2 if (str(best_note.get("kind", "normal")) == "gold" and best_d <= 0.11) else 1
	_score += pts
	_streak += 1
	_canvas.flash_col = AstralTheme.GOLD if pts == 2 else AstralTheme.GOOD
	_canvas.hit_flash = 0.85
	var lx_hit: float = 40.0 + ((_canvas.size.x - 80.0) / 3.0) * (float(lane_idx) + 0.5)
	_canvas.spawn_hit_fx(Vector2(lx_hit, _canvas.size.y * _canvas.hit_y), _canvas.flash_col, pts == 2)
	_result_lbl.text = "✦ ¡ACORDE DORADO (+2 pts · Racha %d)!" % _streak if pts == 2 else "✓ Nota resonante (+1 pt · Racha %d)" % _streak
	AstralAudio.play_confirm()
	_update_fencing_phase_visuals()
	_update_status()

func _update_status() -> void:
	var cur: int = mini(_round + 1, FENCE_ROUNDS) if _mode == "fencing" else clampi(_note_idx + 1, 1, RHYTHM_BEATS)
	var tot: int = FENCE_ROUNDS if _mode == "fencing" else RHYTHM_BEATS
	var mx: int = FENCE_MAX_SCORE if _mode == "fencing" else RHYTHM_MAX_SCORE
	_status_lbl.text = "ASALTO: %d / %d   ·   PUNTOS: %d / %d   ·   RACHA: %d" % [cur, tot, _score, mx, _streak]

func finish_instant_for_test() -> void:
	_score = FENCE_MAX_SCORE - 2 if _mode == "fencing" else RHYTHM_MAX_SCORE - 1
	_complete_minigame()

func _complete_minigame() -> void:
	_running = false
	_fence_btn.disabled = true
	_done_btn.text = "Completado — Continuar ▶"

	var max_s: int = FENCE_MAX_SCORE if _mode == "fencing" else RHYTHM_MAX_SCORE
	var pct: float = clampf(float(_score) / maxf(1.0, float(max_s)), 0.0, 1.0)
	_status_lbl.text = "✦ PRUEBA CONCLUIDA   ·   RESULTADO: %d / %d pts (%d%%)" % [_score, max_s, int(round(pct * 100.0))]

	var msg: String = ""
	if _apply_rewards:
		TurnExecutor.school_minigame_used_this_bimester = true
		if _mode == "fencing":
			var dt: int = 8 + int(round(pct * 16.0))
			var dd: int = 5 + int(round(pct * 12.0))
			GameState.begin_batch()
			GameState.modify_stat("temple", dt)
			GameState.modify_stat("destreza", dd)
			GameState.end_batch()
			msg = "Asalto de Esgrima (%d/%d pts): +%d Temple y +%d Destreza." % [_score, max_s, dt, dd]
		else:
			var dg: int = 8 + int(round(pct * 16.0))
			var ds: int = -(4 + int(round(pct * 10.0)))
			GameState.begin_batch()
			GameState.modify_stat("gracia", dg)
			GameState.modify_stat("stress", ds)
			GameState.end_batch()
			msg = "Armonización Coral (%d/%d pts): +%d Gracia y %d Estrés." % [_score, max_s, dg, ds]
		AstralAudio.play_triumph()
	else:
		msg = "Desempeño en prueba (%d/%d pts · %d%%)." % [_score, max_s, int(round(pct * 100.0))]
		AstralAudio.play_triumph() if pct >= 0.5 else AstralAudio.play_confirm()

	_result_lbl.text = "✦ " + msg
	challenge_completed.emit(_mode, _score, max_s, pct)
	minigame_finished.emit(msg)

func _cancel_or_close() -> void:
	if _running and not _apply_rewards:
		_running = false
		challenge_completed.emit(_mode, _score, FENCE_MAX_SCORE if _mode == "fencing" else RHYTHM_MAX_SCORE, float(_score) / float(FENCE_MAX_SCORE if _mode == "fencing" else RHYTHM_MAX_SCORE))
	hide_overlay()
