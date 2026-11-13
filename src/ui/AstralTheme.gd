extends RefCounted
class_name AstralTheme

## Tema visual "Astral Egipcio": lapislázuli profundo, oro, marfil y turquesa (la paleta del arte del juego).
## Centraliza colores, tipografías (con glifos decorativos de respaldo) y fábricas de widgets
## para que ninguna pantalla repita hexadecimales ni estilos.

# --- PALETA ---------------------------------------------------------------
const BG_DEEP := Color("070b24")
const PANEL := Color(0.045, 0.065, 0.17, 0.94)
const PANEL_SOFT := Color(0.085, 0.115, 0.27, 0.92)
const PANEL_DARK := Color(0.03, 0.045, 0.12, 0.96)
const GOLD := Color("e8bd55")
const GOLD_PALE := Color("f7e3a1")
const GOLD_DARK := Color("9a722a")
const IVORY := Color("f3ead7")
const MUTED := Color("a8b1d8")
const TURQ := Color("49d6c8")
const AMETHYST := Color("ab80f7")
const ROSE := Color("f0728f")
const EMBER := Color("ff9f5a")
const GOOD := Color("86e3a6")
const BAD := Color("ff7f7f")
const SKY := Color("6fb7ff")

const STAT_COLORS: Dictionary = {
	"temple": EMBER, "destreza": Color("ffd166"), "erudicion": SKY, "gracia": ROSE, "magnetismo": Color("f59bd0"),
	"luminiscencia": GOLD_PALE, "gravedad": AMETHYST, "resonancia": TURQ, "entropia": Color("c0587a"),
	"moralidad": GOOD, "devocion": Color("9fd8ff"), "stress": Color("ff7b6b"), "affection": ROSE,
	"human_anchor": EMBER, "seal_integrity": TURQ, "abyssal_sync": AMETHYST,
	"astral_saturation": Color("c58cff"), "seal_investigation": SKY, "father_reputation": GOLD
}

const STAT_TOOLTIPS: Dictionary = {
	"temple": "Fortaleza física y resistencia. Define el HP base en combate (Fase 7).",
	"destreza": "Agilidad, puntería y reflejos.",
	"erudicion": "Conocimiento académico y astral.",
	"gracia": "Elegancia, etiqueta y arte escénico.",
	"magnetismo": "Carisma y presencia ante la gente.",
	"luminiscencia": "Poder de la luz estelar de su interior.",
	"gravedad": "Control de la masa y el peso del cosmos.",
	"resonancia": "Sintonía con el aether y el tiempo.",
	"entropia": "Inclinación al caos. Alta y sin arraigo humano despierta una rebeldía astral peligrosa.",
	"moralidad": "Brújula ética de Renpet.",
	"devocion": "Vínculo espiritual con la Palma Celeste.",
	"stress": "Sobre 80 rinde 25% menos; al llegar a 100 se desploma.",
	"affection": "Cariño hacia su padre. Muy alto (+80) con Anclaje alto forma el Orgullo del Hogar.",
	"human_anchor": "Arraigo mortal, amor y empatía. Es lo que la mantiene humana.",
	"seal_integrity": "Equilibrio de la luz estelar que late en su pecho. Si cae demasiado, algo oculto parece agitarse.",
	"abyssal_sync": "Resonancia con la misteriosa voz o sombra que susurra desde el otro lado de sus sueños.",
	"astral_saturation": "Toxicidad cósmica temporal del Horno. Sobre 60 absorbe peor; sobre 100 sobrecarga.",
	"seal_investigation": "Avance de la investigación secreta sobre el verdadero origen de la estrella caída.",
	"father_reputation": "Prestigio del Padre en Aethelgard: descuentos y objetos exclusivos."
}

# --- GLIFOS (todos incluidos en las fuentes del proyecto) ---------------------
const G_STAR := "✦"
const G_STAR2 := "✧"
const G_ANKH := "☥"
const G_HEART := "♥"
const G_SWORD := "⚔"
const G_SCALES := "⚖"
const G_SUN := "☀"
const G_MOON := "☾"
const G_FLASK := "⚗"
const G_HOURGLASS := "⏳"
const G_FLOWER := "❀"
const G_DIAMOND := "♦"
const G_SKULL := "☠"
const G_CHECK := "✓"
const G_CROSS := "✕"
const G_DIAMOND2 := "❖"
const G_FLEUR := "⚜"
const G_BOLT := "⚡"
const G_QUILL := "✎"
const G_ENVELOPE := "✉"
const G_BOOK := "✠"
const G_ORNAMENT := "❖"

const FONT_DIR := "res://assets/fonts/"

static var _theme: Theme = null
static var _fonts: Dictionary = {}

# ------------------------------------------------------------------------------
# FUENTES
# ------------------------------------------------------------------------------
static func _load_fonts() -> void:
	if not _fonts.is_empty():
		return
	var sym1: FontFile = load(FONT_DIR + "Symbols-subset.ttf")
	var sym2: FontFile = load(FONT_DIR + "Symbols2-subset.ttf")
	var fallbacks: Array[Font] = [sym1, sym2]
	for key in ["Regular", "Medium", "Bold", "Italic"]:
		var f: FontFile = load(FONT_DIR + "AlegreyaSans-%s.ttf" % key)
		f.fallbacks = fallbacks
		_fonts[key] = f
	var cinzel: FontFile = load(FONT_DIR + "Cinzel.ttf")
	cinzel.fallbacks = fallbacks
	var heading := FontVariation.new()
	heading.base_font = cinzel
	heading.variation_opentype = {"weight": 600}
	_fonts["Heading"] = heading
	var title := FontVariation.new()
	title.base_font = cinzel
	title.variation_opentype = {"weight": 700}
	_fonts["Title"] = title

static func font(key: String) -> Font:
	_load_fonts()
	return _fonts[key]

# ------------------------------------------------------------------------------
# ESTILOS BASE
# ------------------------------------------------------------------------------
static func box(bg: Color, border: Color, border_w: int = 2, radius: int = 12, margin: int = 12, shadow: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	sb.anti_aliasing = true
	if shadow:
		sb.shadow_color = Color(0, 0, 0, 0.45)
		sb.shadow_size = 10
		sb.shadow_offset = Vector2(0, 4)
	return sb

static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	_load_fonts()
	var t := Theme.new()
	t.default_font = _fonts["Medium"]
	t.default_font_size = 19

	# --- Label y variantes ---
	t.set_color("font_color", "Label", IVORY)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.35))
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 1)
	t.set_type_variation("HeadingLabel", "Label")
	t.set_font("font", "HeadingLabel", _fonts["Heading"])
	t.set_font_size("font_size", "HeadingLabel", 26)
	t.set_color("font_color", "HeadingLabel", GOLD)
	t.set_type_variation("TitleLabel", "Label")
	t.set_font("font", "TitleLabel", _fonts["Title"])
	t.set_font_size("font_size", "TitleLabel", 54)
	t.set_color("font_color", "TitleLabel", GOLD_PALE)
	t.set_color("font_outline_color", "TitleLabel", Color(0.02, 0.03, 0.12, 0.95))
	t.set_constant("outline_size", "TitleLabel", 12)
	t.set_type_variation("SubLabel", "Label")
	t.set_font("font", "SubLabel", _fonts["Heading"])
	t.set_font_size("font_size", "SubLabel", 20)
	t.set_color("font_color", "SubLabel", TURQ)
	t.set_type_variation("CaptionLabel", "Label")
	t.set_font_size("font_size", "CaptionLabel", 16)
	t.set_color("font_color", "CaptionLabel", MUTED)

	# --- RichTextLabel ---
	t.set_color("default_color", "RichTextLabel", IVORY)
	t.set_font("normal_font", "RichTextLabel", _fonts["Medium"])
	t.set_font("bold_font", "RichTextLabel", _fonts["Bold"])
	t.set_font("italics_font", "RichTextLabel", _fonts["Italic"])
	t.set_font_size("normal_font_size", "RichTextLabel", 19)
	t.set_font_size("bold_font_size", "RichTextLabel", 19)
	t.set_font_size("italics_font_size", "RichTextLabel", 19)
	t.set_stylebox("normal", "RichTextLabel", StyleBoxEmpty.new())

	# --- Paneles ---
	t.set_stylebox("panel", "PanelContainer", box(PANEL, GOLD, 2, 16, 14, true))
	t.set_type_variation("WindowPanel", "PanelContainer")
	t.set_stylebox("panel", "WindowPanel", box(Color(0.04, 0.055, 0.15, 0.97), GOLD, 3, 18, 18, true))
	t.set_type_variation("CardPanel", "PanelContainer")
	t.set_stylebox("panel", "CardPanel", box(PANEL_SOFT, Color(GOLD, 0.55), 1, 12, 12))
	t.set_type_variation("SunkenPanel", "PanelContainer")
	t.set_stylebox("panel", "SunkenPanel", box(PANEL_DARK, Color(GOLD, 0.25), 1, 10, 10))
	t.set_type_variation("GlowPanel", "PanelContainer")
	t.set_stylebox("panel", "GlowPanel", box(Color(0.06, 0.12, 0.2, 0.95), TURQ, 2, 12, 12))
	t.set_type_variation("BarPanel", "PanelContainer")
	t.set_stylebox("panel", "BarPanel", box(PANEL, GOLD, 2, 16, 10, true))
	t.set_type_variation("PillPanel", "PanelContainer")
	t.set_stylebox("panel", "PillPanel", box(Color(0.05, 0.07, 0.19, 0.92), GOLD_DARK, 2, 22, 6))

	# --- Botones ---
	t.set_stylebox("normal", "Button", box(Color(0.08, 0.115, 0.28, 0.96), GOLD_DARK, 2, 10, 10))
	t.set_stylebox("hover", "Button", box(Color(0.12, 0.17, 0.38, 0.98), GOLD, 2, 10, 10))
	t.set_stylebox("pressed", "Button", box(Color(0.2, 0.16, 0.08, 0.98), GOLD_PALE, 2, 10, 10))
	t.set_stylebox("disabled", "Button", box(Color(0.06, 0.07, 0.14, 0.8), Color(0.3, 0.3, 0.38, 0.6), 1, 10, 10))
	t.set_stylebox("focus", "Button", _focus_box())
	t.set_color("font_color", "Button", IVORY)
	t.set_color("font_hover_color", "Button", GOLD_PALE)
	t.set_color("font_pressed_color", "Button", GOLD_PALE)
	t.set_color("font_focus_color", "Button", IVORY)
	t.set_color("font_disabled_color", "Button", Color(0.55, 0.57, 0.68, 0.8))
	t.set_font_size("font_size", "Button", 19)

	t.set_type_variation("PrimaryButton", "Button")
	t.set_stylebox("normal", "PrimaryButton", box(Color(0.52, 0.38, 0.12, 0.98), GOLD_PALE, 2, 12, 12))
	t.set_stylebox("hover", "PrimaryButton", box(Color(0.66, 0.49, 0.16, 1.0), Color.WHITE, 2, 12, 12))
	t.set_stylebox("pressed", "PrimaryButton", box(Color(0.38, 0.27, 0.08, 1.0), GOLD_PALE, 2, 12, 12))
	t.set_color("font_color", "PrimaryButton", Color("fff6d6"))
	t.set_color("font_hover_color", "PrimaryButton", Color.WHITE)
	t.set_font("font", "PrimaryButton", _fonts["Heading"])
	t.set_font_size("font_size", "PrimaryButton", 21)

	t.set_type_variation("DangerButton", "Button")
	t.set_stylebox("normal", "DangerButton", box(Color(0.25, 0.08, 0.12, 0.96), Color("b3485b"), 2, 10, 10))
	t.set_stylebox("hover", "DangerButton", box(Color(0.36, 0.1, 0.16, 0.98), ROSE, 2, 10, 10))

	t.set_type_variation("NavButton", "Button")
	t.set_stylebox("normal", "NavButton", box(Color(0.06, 0.09, 0.22, 0.9), Color(GOLD, 0.45), 1, 12, 8))
	t.set_stylebox("hover", "NavButton", box(Color(0.12, 0.17, 0.38, 0.98), GOLD, 2, 12, 8))
	t.set_stylebox("pressed", "NavButton", box(Color(0.17, 0.14, 0.07, 0.98), GOLD_PALE, 2, 12, 8))

	t.set_type_variation("TabLikeButton", "Button")
	t.set_stylebox("normal", "TabLikeButton", box(Color(0.06, 0.08, 0.2, 0.9), Color(GOLD, 0.35), 1, 8, 8))
	t.set_stylebox("pressed", "TabLikeButton", box(Color(0.2, 0.15, 0.06, 0.98), GOLD, 2, 8, 8))
	t.set_color("font_pressed_color", "TabLikeButton", GOLD_PALE)

	# --- OptionButton / PopupMenu ---
	t.set_stylebox("normal", "OptionButton", box(Color(0.06, 0.085, 0.22, 0.96), GOLD_DARK, 2, 10, 10))
	t.set_stylebox("hover", "OptionButton", box(Color(0.12, 0.17, 0.38, 0.98), GOLD, 2, 10, 10))
	t.set_stylebox("pressed", "OptionButton", box(Color(0.12, 0.17, 0.38, 0.98), GOLD_PALE, 2, 10, 10))
	t.set_stylebox("disabled", "OptionButton", box(Color(0.06, 0.07, 0.14, 0.8), Color(0.3, 0.3, 0.38, 0.6), 1, 10, 10))
	t.set_stylebox("focus", "OptionButton", _focus_box())
	t.set_color("font_color", "OptionButton", IVORY)
	t.set_color("font_hover_color", "OptionButton", GOLD_PALE)
	t.set_font_size("font_size", "OptionButton", 19)
	t.set_stylebox("panel", "PopupMenu", box(Color(0.04, 0.055, 0.15, 0.99), GOLD, 2, 10, 8, true))
	t.set_stylebox("hover", "PopupMenu", box(Color(0.2, 0.17, 0.08, 1.0), GOLD_DARK, 1, 6, 6))
	t.set_stylebox("separator", "PopupMenu", StyleBoxEmpty.new())
	t.set_color("font_color", "PopupMenu", IVORY)
	t.set_color("font_hover_color", "PopupMenu", GOLD_PALE)
	t.set_color("font_disabled_color", "PopupMenu", Color(0.5, 0.52, 0.64))
	t.set_font_size("font_size", "PopupMenu", 18)
	t.set_constant("v_separation", "PopupMenu", 8)

	# --- LineEdit ---
	t.set_stylebox("normal", "LineEdit", box(PANEL_DARK, GOLD_DARK, 2, 8, 10))
	t.set_stylebox("focus", "LineEdit", box(PANEL_DARK, TURQ, 2, 8, 10))
	t.set_stylebox("read_only", "LineEdit", box(PANEL_DARK, Color(GOLD_DARK, 0.5), 1, 8, 10))
	t.set_color("font_color", "LineEdit", IVORY)
	t.set_color("caret_color", "LineEdit", GOLD_PALE)
	t.set_color("selection_color", "LineEdit", Color(GOLD, 0.35))
	t.set_color("font_placeholder_color", "LineEdit", Color(MUTED, 0.6))
	t.set_font_size("font_size", "LineEdit", 20)

	# --- TabContainer ---
	t.set_stylebox("tab_selected", "TabContainer", box(Color(0.2, 0.15, 0.06, 0.98), GOLD, 2, 10, 10))
	t.set_stylebox("tab_unselected", "TabContainer", box(Color(0.06, 0.08, 0.2, 0.92), Color(GOLD, 0.3), 1, 10, 10))
	t.set_stylebox("tab_hovered", "TabContainer", box(Color(0.12, 0.16, 0.34, 0.98), GOLD_DARK, 1, 10, 10))
	t.set_stylebox("tab_focus", "TabContainer", _focus_box())
	t.set_stylebox("panel", "TabContainer", StyleBoxEmpty.new())
	t.set_color("font_selected_color", "TabContainer", GOLD_PALE)
	t.set_color("font_unselected_color", "TabContainer", MUTED)
	t.set_color("font_hovered_color", "TabContainer", IVORY)
	t.set_font_size("font_size", "TabContainer", 19)
	t.set_constant("side_margin", "TabContainer", 0)

	# --- Scroll ---
	for sc in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", sc, box(Color(0.03, 0.04, 0.1, 0.6), Color(0, 0, 0, 0), 0, 6, 0))
		t.set_stylebox("grabber", sc, box(Color(GOLD_DARK, 0.85), Color(0, 0, 0, 0), 0, 6, 0))
		t.set_stylebox("grabber_highlight", sc, box(GOLD, Color(0, 0, 0, 0), 0, 6, 0))
		t.set_stylebox("grabber_pressed", sc, box(GOLD_PALE, Color(0, 0, 0, 0), 0, 6, 0))

	# --- Separadores y tooltips ---
	var sep := StyleBoxLine.new()
	sep.color = Color(GOLD, 0.35)
	sep.thickness = 1
	t.set_stylebox("separator", "HSeparator", sep)
	t.set_constant("separation", "HSeparator", 12)
	t.set_stylebox("panel", "TooltipPanel", box(Color(0.03, 0.04, 0.11, 0.98), GOLD, 1, 8, 10))
	t.set_color("font_color", "TooltipLabel", IVORY)
	t.set_font_size("font_size", "TooltipLabel", 17)

	# --- ProgressBar (base; StatBar la personaliza por color) ---
	t.set_stylebox("background", "ProgressBar", box(Color(0.02, 0.03, 0.09, 0.95), Color(GOLD_DARK, 0.7), 1, 7, 0))
	t.set_stylebox("fill", "ProgressBar", box(TURQ, Color(0, 0, 0, 0), 0, 7, 0))

	_theme = t
	return t

static func _focus_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.border_color = TURQ
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(11)
	sb.expand_margin_left = 2
	sb.expand_margin_right = 2
	sb.expand_margin_top = 2
	sb.expand_margin_bottom = 2
	return sb

# ------------------------------------------------------------------------------
# FÁBRICAS DE WIDGETS
# ------------------------------------------------------------------------------
static func label(text: String, variation: String = "", color: Variant = null, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	if variation != "":
		l.theme_type_variation = variation
	if color != null:
		l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

static func rich(bbcode: String = "", min_h: int = 0) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.text = bbcode
	if min_h > 0:
		r.custom_minimum_size.y = min_h
	return r

static func button(text: String, variation: String = "", tooltip: String = "") -> Button:
	var b := Button.new()
	b.text = text
	if variation != "":
		b.theme_type_variation = variation
	if tooltip != "":
		b.tooltip_text = tooltip
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b

static func panel(variation: String = "CardPanel") -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = variation
	return p

static func vbox(sep: int = 10) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

static func hbox(sep: int = 10) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h

static func spacer(expand: bool = true, h: int = 0) -> Control:
	var c := Control.new()
	if expand:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if h > 0:
		c.custom_minimum_size.y = h
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func separator() -> HSeparator:
	return HSeparator.new()

static func hex(c: Color) -> String:
	return "#" + c.to_html(false)

static func colored(text: String, c: Color) -> String:
	return "[color=%s]%s[/color]" % [hex(c), text]

static func signed(n: int) -> String:
	return "+%d" % n if n > 0 else str(n)

## Estilo de barra con relleno de un color (para ProgressBar sueltas)
static func style_bar(bar: ProgressBar, color: Color) -> void:
	bar.add_theme_stylebox_override("fill", box(color, Color(1, 1, 1, 0.18), 1, 7, 0))
	bar.add_theme_stylebox_override("background", box(Color(0.02, 0.03, 0.09, 0.95), Color(GOLD_DARK, 0.7), 1, 7, 0))
	bar.show_percentage = false
