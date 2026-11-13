extends HBoxContainer
class_name StatBar

## Barra de atributo reutilizable: nombre + barra animada + valor. Admite rangos con negativos (Afecto -100..100).

var stat_key: String = ""
var min_v: int = 0
var max_v: int = 100
var _name_lbl: Label
var _bar: ProgressBar
var _val_lbl: Label
var _color: Color = AstralTheme.TURQ
var _tween: Tween
var show_max: bool = false

func setup(display_name: String, key: String, min_value: int, max_value: int, color: Color, tooltip: String = "", name_width: int = 168) -> StatBar:
	stat_key = key
	min_v = min_value
	max_v = max_value
	_color = color
	add_theme_constant_override("separation", 10)
	mouse_filter = Control.MOUSE_FILTER_PASS
	tooltip_text = tooltip

	_name_lbl = AstralTheme.label(display_name, "", AstralTheme.MUTED)
	_name_lbl.custom_minimum_size.x = name_width
	_name_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_name_lbl)

	_bar = ProgressBar.new()
	_bar.min_value = min_value
	_bar.max_value = max_value
	_bar.value = min_value
	_bar.custom_minimum_size = Vector2(120, 18)
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	AstralTheme.style_bar(_bar, color)
	add_child(_bar)

	_val_lbl = AstralTheme.label("0", "", AstralTheme.IVORY)
	_val_lbl.custom_minimum_size.x = 84
	_val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_val_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_val_lbl)
	return self

func set_title(t: String) -> void:
	if _name_lbl != null:
		_name_lbl.text = t

func set_value(v: int, animate: bool = true) -> void:
	if _bar == null:
		return
	var clamped: int = clampi(v, min_v, max_v)
	if show_max:
		_val_lbl.text = "%d / %d" % [v, max_v]
	elif min_v < 0:
		_val_lbl.text = AstralTheme.signed(v)
	else:
		_val_lbl.text = str(v)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if animate and is_inside_tree() and is_visible_in_tree():
		_tween = create_tween()
		_tween.tween_property(_bar, "value", float(clamped), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		_bar.value = clamped

func set_color(c: Color) -> void:
	_color = c
	AstralTheme.style_bar(_bar, c)

func set_name_text(t: String) -> void:
	_name_lbl.text = t

func set_dim(dim: bool) -> void:
	modulate = Color(1, 1, 1, 0.45) if dim else Color.WHITE
