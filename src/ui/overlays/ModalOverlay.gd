extends Control
class_name ModalOverlay

## Base de los diálogos modales a pantalla completa (prólogo, informe del turno, cartas, escenas, menús).
## Atenúa el fondo, centra un panel y limita su altura al 78% de la ventana con scroll interno.

signal closed()

var panel: PanelContainer
var scroll: ScrollContainer
var content: VBoxContainer
var _dim: ColorRect
var _panel_width: int = 920
var _max_height_ratio: float = 0.80
var _align_bottom: bool = false

func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim = ColorRect.new()
	_dim.color = Color(0.01, 0.015, 0.06, 0.82)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	var holder := VBoxContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.alignment = BoxContainer.ALIGNMENT_END if _align_bottom else BoxContainer.ALIGNMENT_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _align_bottom:
		holder.add_theme_constant_override("separation", 0)
	add_child(holder)
	panel = PanelContainer.new()
	panel.theme_type_variation = "WindowPanel"
	panel.custom_minimum_size.x = _panel_width
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.add_child(panel)
	if _align_bottom:
		var pad := Control.new()
		pad.custom_minimum_size.y = 36
		pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(pad)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	content = AstralTheme.vbox(14)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	resized.connect(_fit)

func set_panel_width(w: int) -> void:
	_panel_width = w
	if panel != null:
		panel.custom_minimum_size.x = w

## Debe llamarse tras reconstruir el contenido.
func _fit() -> void:
	if scroll == null:
		return
	await get_tree().process_frame
	if scroll == null or content == null:
		return
	var want: float = content.get_combined_minimum_size().y + 4.0
	var cap: float = maxf(240.0, size.y * _max_height_ratio)
	scroll.custom_minimum_size = Vector2(0, minf(want, cap))

func show_overlay() -> void:
	visible = true
	move_to_front()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
	_fit()
	await get_tree().process_frame
	var first: Control = _first_focusable(self)
	if first != null:
		first.grab_focus()

func hide_overlay() -> void:
	visible = false
	closed.emit()

func rebuild(builder: Callable) -> void:
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()
	builder.call()
	_fit()

func _first_focusable(node: Node) -> Control:
	var primary: Control = _find_primary(node)
	if primary != null:
		return primary
	return _first_button(node)

func _find_primary(node: Node) -> Control:
	for c in node.get_children():
		if c is Button and (c as Button).theme_type_variation == "PrimaryButton" and not (c as Button).disabled and (c as Control).is_visible_in_tree():
			return c
		var deeper: Control = _find_primary(c)
		if deeper != null:
			return deeper
	return null

func _first_button(node: Node) -> Control:
	for c in node.get_children():
		if c is Button and not (c as Button).disabled and (c as Control).is_visible_in_tree() and (c as Control).focus_mode != Control.FOCUS_NONE:
			return c
		var deeper: Control = _first_button(c)
		if deeper != null:
			return deeper
	return null
