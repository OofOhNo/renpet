extends Control
class_name StarField

## Campo de estrellas parpadeantes (decoración de fondo, muy barato). Se ajusta a cualquier tamaño de ventana.

@export var star_count: int = 90
var _stars: Array[Dictionary] = []
var _time: float = 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.seed = 7741
	for i in range(star_count):
		_stars.append({
			"p": Vector2(_rng.randf(), _rng.randf()),
			"r": _rng.randf_range(0.8, 2.4),
			"phase": _rng.randf_range(0.0, TAU),
			"speed": _rng.randf_range(0.5, 1.8),
			"drift": _rng.randf_range(0.0003, 0.0012),
			"warm": _rng.randf() < 0.35,
			"sparkle": _rng.randf() < 0.12
		})

func _process(delta: float) -> void:
	_time += delta
	for s in _stars:
		var p: Vector2 = s["p"]
		p.y -= float(s["drift"]) * delta
		if p.y < -0.02:
			p.y = 1.02
			p.x = _rng.randf()
		s["p"] = p
	queue_redraw()

func _draw() -> void:
	for s in _stars:
		var pos: Vector2 = Vector2((s["p"] as Vector2).x * size.x, (s["p"] as Vector2).y * size.y)
		var tw: float = 0.5 + 0.5 * sin(_time * float(s["speed"]) + float(s["phase"]))
		var col: Color = AstralTheme.GOLD_PALE if s["warm"] else Color(0.8, 0.88, 1.0)
		col.a = 0.18 + 0.6 * tw
		draw_circle(pos, float(s["r"]), col)
		if s["sparkle"]:
			var l: float = 4.0 + 5.0 * tw
			var c2: Color = Color(col, col.a * 0.8)
			draw_line(pos - Vector2(l, 0), pos + Vector2(l, 0), c2, 1.0)
			draw_line(pos - Vector2(0, l), pos + Vector2(0, l), c2, 1.0)
