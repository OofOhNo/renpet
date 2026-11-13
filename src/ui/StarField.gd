extends Control
class_name StarField

## Campo de estrellas parpadeantes con constelaciones tenues y estrellas fugaces.
## Se ajusta a cualquier tamaño de ventana sin sobrecargar la GPU.

@export var star_count: int = 96
var _stars: Array[Dictionary] = []
var _links: Array[Vector2i] = []
var _meteors: Array[Dictionary] = []
var _next_meteor: float = 2.8
var _time: float = 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.seed = 7741
	var anchor_indices: Array[int] = []
	for i in range(star_count):
		var p := Vector2(_rng.randf(), _rng.randf())
		var sparkle: bool = _rng.randf() < 0.14
		_stars.append({
			"p": p,
			"r": _rng.randf_range(0.8, 2.5),
			"phase": _rng.randf_range(0.0, TAU),
			"speed": _rng.randf_range(0.5, 1.8),
			"drift": _rng.randf_range(0.00025, 0.0010),
			"warm": _rng.randf() < 0.36,
			"sparkle": sparkle
		})
		if sparkle:
			anchor_indices.append(i)
	# Conecta estrellas brillantes cercanas formando constelaciones discretas
	for idx_a in range(anchor_indices.size()):
		for idx_b in range(idx_a + 1, anchor_indices.size()):
			var a: int = anchor_indices[idx_a]
			var b: int = anchor_indices[idx_b]
			var d: float = (_stars[a]["p"] as Vector2).distance_to(_stars[b]["p"] as Vector2)
			if d > 0.06 and d < 0.22 and _links.size() < 16:
				_links.append(Vector2i(a, b))

func _process(delta: float) -> void:
	_time += delta
	for s in _stars:
		var p: Vector2 = s["p"]
		p.y -= float(s["drift"]) * delta
		if p.y < -0.02:
			p.y = 1.02
			p.x = _rng.randf()
		s["p"] = p

	_next_meteor -= delta
	if _next_meteor <= 0.0 and size.x > 100.0:
		_next_meteor = _rng.randf_range(4.5, 9.5)
		var sx: float = _rng.randf_range(0.15, 0.88)
		var sy: float = _rng.randf_range(0.04, 0.35)
		_meteors.append({
			"p": Vector2(sx, sy),
			"v": Vector2(_rng.randf_range(-0.28, -0.15), _rng.randf_range(0.11, 0.20)),
			"life": 0.0,
			"max_life": _rng.randf_range(0.65, 1.05)
		})

	var m_idx: int = _meteors.size() - 1
	while m_idx >= 0:
		var m: Dictionary = _meteors[m_idx]
		m["life"] = float(m["life"]) + delta
		m["p"] = (m["p"] as Vector2) + (m["v"] as Vector2) * delta
		if float(m["life"]) >= float(m["max_life"]):
			_meteors.remove_at(m_idx)
		m_idx -= 1

	queue_redraw()

func _draw() -> void:
	for lk in _links:
		var pa: Vector2 = _stars[lk.x]["p"]
		var pb: Vector2 = _stars[lk.y]["p"]
		if pa.distance_to(pb) < 0.26:
			var a_col := Color(AstralTheme.GOLD_PALE.r, AstralTheme.GOLD_PALE.g, AstralTheme.GOLD_PALE.b, 0.07 + 0.04 * sin(_time * 0.7 + float(lk.x)))
			draw_line(Vector2(pa.x * size.x, pa.y * size.y), Vector2(pb.x * size.x, pb.y * size.y), a_col, 1.0)

	# Velos de nebulosa cósmica suave en movimiento lento
	var neb_defs: Array = [
		[Vector2(0.24 + 0.03 * sin(_time * 0.13), 0.26), 0.26, Color(0.22, 0.62, 0.74, 0.045)],
		[Vector2(0.76 - 0.03 * cos(_time * 0.11), 0.34), 0.30, Color(0.56, 0.34, 0.86, 0.048)],
		[Vector2(0.52 + 0.02 * sin(_time * 0.16), 0.72), 0.28, Color(0.86, 0.68, 0.32, 0.032)]
	]
	for nd in neb_defs:
		var npos := Vector2((nd[0] as Vector2).x * size.x, (nd[0] as Vector2).y * size.y)
		var nr: float = float(nd[1]) * minf(size.x, size.y)
		var nc: Color = nd[2]
		draw_circle(npos, nr, nc)
		draw_circle(npos, nr * 0.56, Color(nc.r, nc.g, nc.b, nc.a * 1.25))

	for s in _stars:
		var pos: Vector2 = Vector2((s["p"] as Vector2).x * size.x, (s["p"] as Vector2).y * size.y)
		var tw: float = 0.5 + 0.5 * sin(_time * float(s["speed"]) + float(s["phase"]))
		var col: Color = AstralTheme.GOLD_PALE if s["warm"] else Color(0.8, 0.88, 1.0)
		col.a = 0.18 + 0.62 * tw
		draw_circle(pos, float(s["r"]), col)
		if s["sparkle"]:
			var l: float = 4.0 + 5.0 * tw
			var c2: Color = Color(col, col.a * 0.82)
			draw_line(pos - Vector2(l, 0), pos + Vector2(l, 0), c2, 1.0)
			draw_line(pos - Vector2(0, l), pos + Vector2(0, l), c2, 1.0)

	for m in _meteors:
		var p: Vector2 = m["p"]
		var v: Vector2 = m["v"]
		var ratio: float = clampf(float(m["life"]) / float(m["max_life"]), 0.0, 1.0)
		var fade: float = sin(ratio * PI)
		var head := Vector2(p.x * size.x, p.y * size.y)
		var tail := head - Vector2(v.x * size.x, v.y * size.y) * 0.18
		draw_line(tail, head, Color(AstralTheme.TURQ.r, AstralTheme.TURQ.g, AstralTheme.TURQ.b, fade * 0.55), 1.6)
		draw_circle(head, 2.2, Color(AstralTheme.GOLD_PALE.r, AstralTheme.GOLD_PALE.g, AstralTheme.GOLD_PALE.b, fade * 0.9))
