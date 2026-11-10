extends PanelContainer
class_name BaseWindow

## Ventana central de la mansión: barra de título con Cerrar, cuerpo con scroll y animación de entrada.
## Las subclases implementan build() (una vez) y refresh() (cuando cambia el estado).

signal closed()
signal speak(speaker: String, text: String)       # mensaje a la barra de diálogo
signal toast(text: String, kind: String)          # aviso breve

var title_label: Label
var body: VBoxContainer
var scroll: ScrollContainer
var _built: bool = false

func _init() -> void:
	theme_type_variation = "WindowPanel"
	clip_contents = true
	visible = false
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

func setup(title_text: String, use_scroll: bool = true) -> void:
	var root := AstralTheme.vbox(10)
	add_child(root)
	var head := AstralTheme.hbox(10)
	root.add_child(head)
	title_label = AstralTheme.label(title_text, "HeadingLabel")
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.clip_text = true
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.add_child(title_label)
	var close_btn := AstralTheme.button(AstralTheme.G_CROSS + "  Cerrar", "DangerButton", "Cerrar la ventana (Esc)")
	close_btn.pressed.connect(close)
	head.add_child(close_btn)
	root.add_child(AstralTheme.separator())
	if use_scroll:
		scroll = ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		root.add_child(scroll)
		body = AstralTheme.vbox(12)
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(body)
	else:
		body = AstralTheme.vbox(10)
		body.size_flags_vertical = Control.SIZE_EXPAND_FILL
		root.add_child(body)

func open() -> void:
	if not _built:
		build()
		_built = true
	refresh()
	visible = true
	modulate.a = 0.0
	pivot_offset = size * 0.5
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.22)
	scale = Vector2(0.985, 0.985)
	tw.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()

func build() -> void:
	pass

func refresh() -> void:
	pass

## Utilidad: vacía un contenedor (libera los hijos de inmediato para evitar parpadeos de layout).
static func clear(container: Node) -> void:
	for c in container.get_children():
		container.remove_child(c)
		c.queue_free()

## Crea una pestaña con scroll propio dentro de un TabContainer y devuelve su VBox.
static func add_tab(tabs: TabContainer, title: String) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.name = title
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var v := AstralTheme.vbox(12)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 8)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(v)
	sc.add_child(margin)
	tabs.add_child(sc)
	return v
