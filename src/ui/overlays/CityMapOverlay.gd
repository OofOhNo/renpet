extends Control
class_name CityMapOverlay

## Pantalla completa de la Ciudad de Aethelgard (estilo Volcano Princess):
## Al salir de la Mansión, bloquea los controles del hogar hasta regresar.
## Incluye mapa ilustrado con 6 distritos físicos enterables, encuentro/descubrimiento de NPCs,
## tiendas especializadas (Boutique, Joyería/Obsequios, Bazar, Boticario), Expediciones,
## Festival de Otoño de 3 asaltos con minijuego escénico en Ronda 2 y Senado.

signal closed()
signal speak(speaker: String, text: String)
signal toast(text: String, kind: String)
signal bond_event_requested(npc_id: String)
signal expedition_requested(zone_idx: int, comp_id: String, comp_name: String)
signal festival_minigame_requested(mode: String, title_text: String)
signal state_changed()

const NPC_COLORS: Dictionary = {
	"soren": Color("49d6c8"), "vespera": Color("ff9f5a"), "kaelen": Color("86e3a6"),
	"cassian": Color("f7e3a1"), "mirari": Color("ab80f7"), "zephyr": Color("ff6b98"),
	"lyra": Color("f29ec7"), "caelum": Color("aebdcc")
}
const NPC_PORTRAITS: Dictionary = {
	"soren": "res://assets/ui/npc_soren.png",
	"vespera": "res://assets/ui/npc_vespera.png",
	"kaelen": "res://assets/ui/npc_kaelen.png",
	"cassian": "res://assets/ui/npc_cassian.png",
	"mirari": "res://assets/ui/npc_mirari.png",
	"zephyr": "res://assets/ui/npc_zephyr.png",
	"lyra": "res://assets/ui/npc_lyra.png",
	"caelum": "res://assets/ui/npc_caelum.png"
}

const DISTRICTS: Array[Dictionary] = [
	{
		"id": "torre", "npc": "soren", "name": "Torre de Cristal",
		"px": 0.18, "py": 0.24, "stat": "erudicion",
		"facility": "Archivos · Mazo de Recuerdos",
		"ambient": "Telescopios de bronce apuntan al cielo violeta entre manuscritos estelares y astrolabios suspendidos.",
		"stroll": "Suben al mirador estelar y comparten panecillos calientes entre planos celestes."
	},
	{
		"id": "palacio", "npc": "cassian", "secondary_npc": "lyra", "name": "Palacio de Alabastro",
		"px": 0.50, "py": 0.20, "stat": "magnetismo",
		"facility": "Boutique · Joyería · Senado",
		"ambient": "Cúpulas doradas rodean los jardines reales, la sastrería de gala imperial y las escalinatas del Senado.",
		"stroll": "Recorren los rosedales imperiales observando el relevo de la guardia solar."
	},
	{
		"id": "patio", "npc": "vespera", "secondary_npc": "caelum", "name": "Patio Ducal de Armas",
		"px": 0.82, "py": 0.26, "stat": "temple",
		"facility": "Expediciones · Esgrima",
		"ambient": "Estandartes dorados ondean sobre los muros desde donde parten las patrullas hacia las ruinas.",
		"stroll": "Cruzan el patio de armas bajo los estandartes escuchando el chocar lejano de aceros."
	},
	{
		"id": "acueductos", "npc": "kaelen", "name": "Acueductos",
		"px": 0.20, "py": 0.72, "stat": "destreza",
		"facility": "Bazar Nocturno · Boticario",
		"ambient": "Puentes de piedra antigua cubren mercados ocultos, farmacias de hierbas plateadas y faroles de ámbar.",
		"stroll": "Exploran las galerías junto al agua luminiscente repartiendo fruta fresca."
	},
	{
		"id": "espejo", "npc": "zephyr", "name": "Espejo Astral",
		"px": 0.50, "py": 0.76, "stat": "resonancia",
		"facility": "Estanque Sagrado Lunar",
		"ambient": "Un espejo circular de agua quieta refleja constelaciones que no figuran en los mapas diurnos.",
		"stroll": "Contemplan las constelaciones reflejadas en silencio junto al estanque sagrado."
	},
	{
		"id": "anfiteatro", "npc": "mirari", "name": "Anfiteatro de Cristal",
		"px": 0.82, "py": 0.73, "stat": "gracia",
		"facility": "Festival de Otoño · Coro",
		"ambient": "Gradas de mármol blanco envuelven el escenario donde se coronan los certámenes del Solsticio.",
		"stroll": "Escuchan acordes de arpa reverberar en las gradas vacías del coliseo."
	}
]

class _PulseHalo extends Control:
	var col := Color(0.95, 0.80, 0.42, 1.0)
	var _t: float = 0.0

	func _init(p_col: Color) -> void:
		col = p_col
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		_t += delta * 2.8
		queue_redraw()

	func _draw() -> void:
		var phase: float = fmod(_t, 1.0)
		var r_rect := Rect2(Vector2.ZERO, size).grow(phase * 14.0)
		var alpha: float = (1.0 - phase) * 0.62
		draw_rect(r_rect, Color(col.r, col.g, col.b, alpha), false, 2.2)

class _GiftWaxSeal extends Control:
	var gift_id: String = ""

	func _init(p_id: String) -> void:
		gift_id = p_id
		custom_minimum_size = Vector2(44, 44)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c: Vector2 = size * 0.5
		var accent := Color(0.95, 0.78, 0.40, 1.0)
		match gift_id:
			"quartz_lens":
				accent = Color(0.46, 0.86, 0.98, 1.0)
			"star_candy":
				accent = Color(0.98, 0.78, 0.36, 1.0)
			"herbal_elixir":
				accent = Color(0.42, 0.86, 0.64, 1.0)
			"silver_rose":
				accent = Color(0.84, 0.90, 0.98, 1.0)
			"silk_poetry":
				accent = Color(0.90, 0.48, 0.68, 1.0)
			"brass_compass":
				accent = Color(0.96, 0.74, 0.32, 1.0)
		draw_circle(c, 19.0, Color(0.05, 0.08, 0.18, 0.95))
		draw_circle(c, 16.0, Color(accent.r, accent.g, accent.b, 0.18))
		draw_arc(c, 17.5, 0.0, TAU, 32, Color(accent.r, accent.g, accent.b, 0.88), 1.8, true)
		# Ornate diamond gem + ribbon cross inside seal
		var pts := PackedVector2Array([c + Vector2(0, -10), c + Vector2(9, 0), c + Vector2(0, 10), c + Vector2(-9, 0)])
		draw_colored_polygon(pts, accent)
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(1.0, 0.96, 0.85, 0.95), 1.4, true)
		draw_circle(c, 2.8, Color(1.0, 0.98, 0.92, 1.0))

var _root_card: PanelContainer
var _title_lbl: Label
var _res_lbl: Label
var _back_map_btn: Button
var _home_btn: Button

var _map_view: VBoxContainer
var _map_banner_lbl: Label
var _pin_layer: Control

var _location_view: VBoxContainer
var _loc_banner: PanelContainer
var _loc_banner_tex: TextureRect
var _loc_desc_lbl: Label
var _loc_stroll_btn: Button
var _npc_panel: VBoxContainer
var _facility_panel: VBoxContainer

var _current_district: String = ""
var _last_npc_id: String = ""
var _last_reply: String = ""
var _last_effects: String = ""
var _gift_select: OptionButton
var _outing_select: OptionButton
var _selected_npc_by_district: Dictionary = {}
var _cross_result_title: String = ""
var _cross_result_body: String = ""
var _cross_result_fx: String = ""

var _selected_comp: String = "solo"
var _facility_tab_by_district: Dictionary = {}
var _fest_result: Dictionary = {}
var _pending_fest_args: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.08, 0.94)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	_root_card = AstralTheme.panel("MainPanel")
	_root_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(_root_card)

	var main_v := AstralTheme.vbox(10)
	_root_card.add_child(main_v)

	# --- BARRA SUPERIOR DE AETHELGARD ---
	var top_bar := AstralTheme.panel("SunkenPanel")
	main_v.add_child(top_bar)
	var th := AstralTheme.hbox(10)
	top_bar.add_child(th)

	_back_map_btn = AstralTheme.button("◀ Mapa de Distritos", "TabLikeButton")
	_back_map_btn.custom_minimum_size = Vector2(180, 38)
	_back_map_btn.visible = false
	_back_map_btn.pressed.connect(func() -> void: _switch_to_map())
	th.add_child(_back_map_btn)

	_title_lbl = AstralTheme.label("%s  CIUDAD DE AETHELGARD" % AstralTheme.G_DIAMOND2, "HeadingLabel", AstralTheme.GOLD)
	_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	th.add_child(_title_lbl)

	_res_lbl = AstralTheme.label("", "SubLabel", AstralTheme.IVORY)
	th.add_child(_res_lbl)

	_home_btn = AstralTheme.button("%s  Volver a la Mansión" % AstralTheme.G_CROSS, "PrimaryButton")
	_home_btn.custom_minimum_size = Vector2(210, 40)
	_home_btn.pressed.connect(close_overlay)
	th.add_child(_home_btn)

	# --- VISTA 1: MAPA ILUSTRADO INTERACTIVO ---
	_map_view = AstralTheme.vbox(8)
	_map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_v.add_child(_map_view)

	_map_banner_lbl = AstralTheme.label("", "CaptionLabel", AstralTheme.TURQ, true)
	_map_view.add_child(_map_banner_lbl)

	var aspect := AspectRatioContainer.new()
	aspect.ratio = 16.0 / 9.0
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aspect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_view.add_child(aspect)

	var map_frame := AstralTheme.panel("CardPanel")
	map_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	aspect.add_child(map_frame)

	var map_holder := Control.new()
	map_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_frame.add_child(map_holder)

	var map_tex_rect := TextureRect.new()
	map_tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_tex_rect.texture = AstralTheme.load_tex("res://assets/art/bg_town_map.png")
	map_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	map_holder.add_child(map_tex_rect)

	var soft_tint := ColorRect.new()
	soft_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	soft_tint.color = Color(0.02, 0.03, 0.09, 0.14)
	soft_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_holder.add_child(soft_tint)

	_pin_layer = Control.new()
	_pin_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_holder.add_child(_pin_layer)

	# --- VISTA 2: INTERIOR FÍSICO DEL DISTRITO ---
	_location_view = AstralTheme.vbox(8)
	_location_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_location_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_location_view.visible = false
	main_v.add_child(_location_view)

	_loc_banner = AstralTheme.panel("GlowPanel")
	_loc_banner.custom_minimum_size = Vector2(0, 118)
	_loc_banner.clip_contents = true
	_location_view.add_child(_loc_banner)
	_loc_banner_tex = TextureRect.new()
	_loc_banner_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_loc_banner_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_loc_banner_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_loc_banner_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loc_banner.add_child(_loc_banner_tex)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.03, 0.05, 0.14, 0.42)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loc_banner.add_child(shade)
	var loc_ov := MarginContainer.new()
	loc_ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loc_ov.add_theme_constant_override("margin_left", 14)
	loc_ov.add_theme_constant_override("margin_right", 14)
	loc_ov.add_theme_constant_override("margin_top", 10)
	loc_ov.add_theme_constant_override("margin_bottom", 10)
	_loc_banner.add_child(loc_ov)
	var lth := AstralTheme.hbox(12)
	lth.size_flags_vertical = Control.SIZE_EXPAND_FILL
	loc_ov.add_child(lth)
	var desc_pill := AstralTheme.panel("SunkenPanel")
	desc_pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_pill.size_flags_vertical = Control.SIZE_SHRINK_END
	desc_pill.modulate = Color(1, 1, 1, 0.94)
	lth.add_child(desc_pill)
	_loc_desc_lbl = AstralTheme.label("", "CaptionLabel", AstralTheme.IVORY, true)
	desc_pill.add_child(_loc_desc_lbl)
	_loc_stroll_btn = AstralTheme.button("❀ Paseo Padre-Hija (-20 E)", "PrimaryButton")
	_loc_stroll_btn.custom_minimum_size = Vector2(246, 44)
	_loc_stroll_btn.size_flags_vertical = Control.SIZE_SHRINK_END
	_loc_stroll_btn.pressed.connect(_on_stroll_pressed)
	lth.add_child(_loc_stroll_btn)

	var cols := HSplitContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 14)
	_location_view.add_child(cols)

	var left_sc := ScrollContainer.new()
	left_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_sc.custom_minimum_size.x = 320
	cols.add_child(left_sc)
	_npc_panel = AstralTheme.vbox(10)
	_npc_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_sc.add_child(_npc_panel)

	_facility_panel = AstralTheme.vbox(10)
	_facility_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_facility_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_facility_panel.custom_minimum_size = Vector2(460, 0)
	cols.add_child(_facility_panel)

func open_city(district_id: String = "") -> void:
	visible = true
	_fest_result.clear()
	_pending_fest_args.clear()
	if district_id == "":
		_facility_tab_by_district.clear()
	_current_district = district_id
	_last_reply = ""
	_last_effects = ""
	_cross_result_title = ""
	_cross_result_body = ""
	_cross_result_fx = ""
	refresh()
	if DisplayServer.get_name() != "headless":
		modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE)

func close_overlay() -> void:
	if not visible:
		return
	_current_district = ""
	if DisplayServer.get_name() != "headless":
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.14)
		tw.tween_callback(func() -> void:
			visible = false
			modulate.a = 1.0
			closed.emit())
	else:
		visible = false
		closed.emit()

func open_festival_location() -> void:
	open_city("anfiteatro")

func open_expedition_location() -> void:
	open_city("patio")

func _switch_to_map() -> void:
	_current_district = ""
	_last_reply = ""
	_last_effects = ""
	_cross_result_title = ""
	_cross_result_body = ""
	_cross_result_fx = ""
	refresh()

func _enter_district(dist_id: String) -> void:
	AstralAudio.play_ui()
	_current_district = dist_id
	_last_reply = ""
	_last_effects = ""
	_cross_result_title = ""
	_cross_result_body = ""
	_cross_result_fx = ""
	refresh()

func refresh() -> void:
	if _title_lbl == null:
		return
	var gold_s: String = "%d G" % GameState.gold
	var sp: int = RelationshipManager.social_points_left
	_res_lbl.text = "%s %s   ·   Padre %d/%d E   ·   Estrés %d%%   ·   Puntos Sociales: %d/%d" % [
		AstralTheme.G_SUN, gold_s, GameState.father_energy, GameState.father_max_energy,
		GameState.stress, sp, RelationshipManager.MAX_SOCIAL_POINTS
	]

	var in_loc: bool = (_current_district != "")
	_back_map_btn.visible = in_loc
	_map_view.visible = not in_loc
	_location_view.visible = in_loc

	if not in_loc:
		_title_lbl.text = "%s  CIUDAD DE AETHELGARD — %s" % [AstralTheme.G_DIAMOND2, str(TimeManager.get_bimester_info().get("name", ""))]
		_refresh_map_view()
	else:
		_refresh_location_view()

# ------------------------------------------------------------------------------
# VISTA DEL MAPA ILUSTRADO (PINS INTERACTIVOS SOBRE CADA EDIFICIO)
# ------------------------------------------------------------------------------
func _refresh_map_view() -> void:
	var note_bits: Array[String] = []
	note_bits.append("Entra en cualquier distrito para conocer a sus habitantes, visitar tiendas, explorar o competir.")
	if TimeManager.is_festival_bimester() and not ExplorationCombat.festival_entered_this_year:
		note_bits.append("%s ¡Festival de Otoño abierto en el Anfiteatro!" % AstralTheme.G_SUN)
	elif TimeManager.is_bazaar_open():
		note_bits.append("⚗ Feria Nocturna (-15% en Reliquias) abierta en los Acueductos.")
	_map_banner_lbl.text = "  ·  ".join(note_bits)

	for ch in _pin_layer.get_children():
		ch.queue_free()

	for d in DISTRICTS:
		var did: String = str(d["id"])
		var npc_id: String = str(d["npc"])
		var sec_id: String = str(d.get("secondary_npc", ""))
		var avail: bool = RelationshipManager.is_available(npc_id)
		var known: bool = avail and RelationshipManager.is_known(npc_id)
		var sec_avail: bool = (sec_id != "") and RelationshipManager.is_available(sec_id)
		var data: Dictionary = RelationshipManager.get_data(npc_id)
		var bond_ev: Dictionary = RelationshipManager.get_next_bond_event(npc_id) if avail else {}
		var sec_ev: Dictionary = RelationshipManager.get_next_bond_event(sec_id) if sec_avail else {}
		var cross_ev: Dictionary = RelationshipManager.get_available_cross_encounter(did)
		var has_cross: bool = not cross_ev.is_empty()
		var has_ev: bool = bool(bond_ev.get("ok", false)) or bool(sec_ev.get("ok", false)) or has_cross
		var is_fest: bool = (did == "anfiteatro" and TimeManager.is_festival_bimester() and not ExplorationCombat.festival_entered_this_year)

		var marker := PanelContainer.new()
		marker.custom_minimum_size = Vector2(168, 48)
		marker.theme_type_variation = "GlowPanel" if (has_ev or is_fest) else "CardPanel"
		marker.anchor_left = float(d["px"])
		marker.anchor_right = float(d["px"])
		marker.anchor_top = float(d["py"])
		marker.anchor_bottom = float(d["py"])
		marker.offset_left = -84.0
		marker.offset_right = 84.0
		marker.offset_top = -24.0
		marker.offset_bottom = 24.0
		_pin_layer.add_child(marker)
		if has_ev or is_fest:
			var halo := _PulseHalo.new(AstralTheme.GOLD if is_fest else AstralTheme.TURQ)
			halo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			marker.add_child(halo)

		var row := AstralTheme.hbox(6)
		marker.add_child(row)

		if avail:
			var av_bg := PanelContainer.new()
			av_bg.theme_type_variation = "SunkenPanel"
			av_bg.custom_minimum_size = Vector2(36, 36)
			row.add_child(av_bg)

			var av_tex := TextureRect.new()
			av_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			av_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			av_tex.custom_minimum_size = Vector2(30, 30)
			av_tex.texture = AstralTheme.load_tex(str(NPC_PORTRAITS.get(npc_id, "")))
			if not known:
				av_tex.modulate = Color(0.08, 0.10, 0.18, 0.92)
			av_bg.add_child(av_tex)

		var info := AstralTheme.vbox(1)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(info)

		var short_d: String = str(d["name"]).replace("Palacio de Alabastro", "Palacio").replace("Torre de Cristal", "Torre")
		var npc_tag: String = "?" if not known else str(data["name"]).split(" ")[0]
		if sec_avail:
			var sec_known: bool = RelationshipManager.is_known(sec_id)
			var sec_data: Dictionary = RelationshipManager.get_data(sec_id)
			npc_tag += "/" + (str(sec_data.get("name", "?")).split(" ")[0] if sec_known else "?")
		var tag_col: Color = AstralTheme.GOLD if (has_ev or is_fest) else (AstralTheme.GOLD_PALE if (not avail or known) else AstralTheme.TURQ)
		var hdr_txt: String = ("%s · %s" % [short_d, npc_tag]) if avail else short_d
		var hdr := AstralTheme.label(hdr_txt, "CaptionLabel", tag_col)
		hdr.add_theme_font_size_override("font_size", 12)
		hdr.clip_text = true
		info.add_child(hdr)

		var has_story: bool = bool(bond_ev.get("ok", false)) or bool(sec_ev.get("ok", false))
		var sub_txt: String = "✦ FESTIVAL" if is_fest else ("★ Escena" if has_story else ("✦ Encuentro" if has_cross else str(d["facility"])))
		var sub := AstralTheme.label(sub_txt, "CaptionLabel", AstralTheme.GOOD if (is_fest or has_ev) else AstralTheme.MUTED)
		sub.add_theme_font_size_override("font_size", 11)
		sub.clip_text = true
		info.add_child(sub)

		var hit_btn := Button.new()
		hit_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hit_btn.flat = true
		hit_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		hit_btn.tooltip_text = ("%s — %s (%s)" % [str(d["name"]), str(d["facility"]), npc_tag]) if avail else ("%s — %s" % [str(d["name"]), str(d["facility"])])
		hit_btn.pressed.connect(_enter_district.bind(did))
		marker.add_child(hit_btn)

# ------------------------------------------------------------------------------
# VISTA INTERIOR DE CADA DISTRITO
# ------------------------------------------------------------------------------
func _get_current_district_dict() -> Dictionary:
	for d in DISTRICTS:
		if str(d["id"]) == _current_district:
			return d
	return DISTRICTS[0]

func _refresh_location_view() -> void:
	var d: Dictionary = _get_current_district_dict()
	if _loc_banner_tex != null:
		_loc_banner_tex.texture = AstralTheme.load_tex(CatalogDB.get_district_backdrop(str(d["id"])))
	_title_lbl.text = "%s  %s" % [AstralTheme.G_STAR, str(d["name"]).to_upper()]
	var st_lbl: String = GameState.get_stat_label(str(d["stat"]))
	_loc_desc_lbl.text = "%s  (+5 %s en paseo padre-hija)" % [str(d["ambient"]), st_lbl]
	var free_e: int = GameState.father_energy - TurnExecutor.get_father_energy_used()
	_loc_stroll_btn.disabled = RelationshipManager.strolled_this_bimester or free_e < 20
	_loc_stroll_btn.text = "✓ Paseo hecho" if RelationshipManager.strolled_this_bimester else "❀ Paseo Padre-Hija (-20 E)"

	BaseWindow.clear(_npc_panel)
	BaseWindow.clear(_facility_panel)
	_build_npc_encounter(d)
	_build_district_facility(d)

func _on_stroll_pressed() -> void:
	var d: Dictionary = _get_current_district_dict()
	var stat_k: String = str(d["stat"])
	if RelationshipManager.strolled_this_bimester:
		AstralAudio.play_warn()
		toast.emit("Ya pasearon juntos por Aethelgard este bimestre.", "warn")
		return
	var free_e: int = GameState.father_energy - TurnExecutor.get_father_energy_used()
	if free_e < 20:
		AstralAudio.play_warn()
		toast.emit("No queda suficiente Energía Paterna libre (requiere 20).", "warn")
		return
	GameState.begin_batch()
	GameState.modify_stat("father_energy", -20)
	RelationshipManager.strolled_this_bimester = true
	GameState.modify_stat("stress", -5)
	GameState.modify_stat("affection", 5)
	GameState.modify_stat("human_anchor", 3)
	GameState.modify_stat(stat_k, 5)
	GameState.end_batch()
	AstralAudio.play_confirm()
	var st_lbl: String = GameState.get_stat_label(stat_k)
	speak.emit("%s y %s — %s" % [GameState.father_name, GameState.daughter_name, str(d["name"])],
		"%s (-5 Estrés, +5 Afecto, +3 Anclaje, +5 %s)" % [str(d["stroll"]), st_lbl])
	toast.emit("Paseo padre-hija por %s completado (+5 %s)" % [str(d["name"]), st_lbl], "good")
	state_changed.emit()
	refresh()

func _get_district_for_npc(npc_id: String) -> String:
	for d in DISTRICTS:
		if str(d.get("npc", "")) == npc_id or str(d.get("secondary_npc", "")) == npc_id:
			return str(d["id"])
	return "palacio"

func _build_cross_encounter_block(did: String) -> void:
	if _cross_result_body != "":
		var res_p := AstralTheme.panel("GlowPanel")
		_npc_panel.add_child(res_p)
		var rv := AstralTheme.vbox(6)
		res_p.add_child(rv)
		rv.add_child(AstralTheme.label("✦ %s" % _cross_result_title, "SubLabel", AstralTheme.GOLD))
		rv.add_child(AstralTheme.label(_cross_result_body, "", AstralTheme.IVORY, true))
		if _cross_result_fx != "":
			rv.add_child(AstralTheme.label(_cross_result_fx, "CaptionLabel", AstralTheme.GOOD, true))
		var cls_btn := AstralTheme.button("Continuar", "TabLikeButton")
		cls_btn.custom_minimum_size.y = 32
		cls_btn.pressed.connect(func() -> void:
			_cross_result_title = ""
			_cross_result_body = ""
			_cross_result_fx = ""
			refresh())
		rv.add_child(cls_btn)
		return

	var cross_enc: Dictionary = RelationshipManager.get_available_cross_encounter(did)
	if cross_enc.is_empty():
		return
	var ep := AstralTheme.panel("GlowPanel")
	_npc_panel.add_child(ep)
	var ev := AstralTheme.vbox(6)
	ep.add_child(ev)
	ev.add_child(AstralTheme.label("✦ ENCUENTRO EN EL DISTRITO — %s" % str(cross_enc.get("title", "")), "SubLabel", AstralTheme.GOLD))

	var npcs: Array = cross_enc.get("npcs", [])
	if npcs.size() >= 2:
		var por_row := AstralTheme.hbox(8)
		ev.add_child(por_row)
		for cid_v in npcs:
			var cid: String = str(cid_v)
			var c_frame := AstralTheme.panel("CardPanel")
			c_frame.custom_minimum_size = Vector2(44, 44)
			por_row.add_child(c_frame)
			var c_tex := TextureRect.new()
			c_tex.texture = AstralTheme.load_tex(str(NPC_PORTRAITS.get(cid, "")))
			c_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			c_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			c_tex.custom_minimum_size = Vector2(36, 36)
			if not RelationshipManager.is_known(cid):
				c_tex.modulate = Color(0.08, 0.10, 0.18, 0.94)
			c_frame.add_child(c_tex)
		var pair_names: Array[String] = []
		for cid_v in npcs:
			var cid: String = str(cid_v)
			var cdata: Dictionary = RelationshipManager.get_data(cid)
			pair_names.append(str(cdata.get("name", cid)).split(" ")[0] if RelationshipManager.is_known(cid) else "???")
		var pair_lbl := AstralTheme.label(" & ".join(pair_names), "CaptionLabel", AstralTheme.TURQ, true)
		pair_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		por_row.add_child(pair_lbl)

	ev.add_child(AstralTheme.label(str(cross_enc.get("scene", "")), "", AstralTheme.IVORY, true))
	var choices: Array = cross_enc.get("choices", [])
	var enc_id: String = str(cross_enc.get("id", ""))
	for i in range(choices.size()):
		var ch: Dictionary = choices[i]
		var cbtn := AstralTheme.button("%d. %s" % [i + 1, str(ch.get("label", "Intervenir"))], "PrimaryButton" if i == 0 else "TabLikeButton")
		cbtn.custom_minimum_size.y = 36
		var c_idx: int = i
		cbtn.pressed.connect(func() -> void: _trigger_cross_encounter(enc_id, c_idx))
		ev.add_child(cbtn)

func _build_npc_encounter(d: Dictionary) -> void:
	var did: String = str(d["id"])
	_build_cross_encounter_block(did)

	var primary_npc: String = str(d["npc"])
	var sec_npc: String = str(d.get("secondary_npc", ""))
	var npc_id: String = primary_npc

	if sec_npc != "" and RelationshipManager.is_available(sec_npc):
		var chosen: String = str(_selected_npc_by_district.get(did, primary_npc))
		if chosen == primary_npc or chosen == sec_npc:
			npc_id = chosen
		var sw_panel := AstralTheme.panel("CardPanel")
		_npc_panel.add_child(sw_panel)
		var sw_v := AstralTheme.vbox(4)
		sw_panel.add_child(sw_v)
		sw_v.add_child(AstralTheme.label("Presentes en %s:" % str(d["name"]), "CaptionLabel", AstralTheme.GOLD_PALE))
		var sw_h := AstralTheme.hbox(8)
		sw_v.add_child(sw_h)
		for cand_id in [primary_npc, sec_npc]:
			var c_data: Dictionary = RelationshipManager.get_data(cand_id)
			var c_known: bool = RelationshipManager.is_known(cand_id)
			var c_ev: Dictionary = RelationshipManager.get_next_bond_event(cand_id)
			var star_tag: String = " ★" if bool(c_ev.get("ok", false)) else ""
			var raw_name: String = str(c_data.get("name", cand_id))
			var short_name: String = raw_name.replace("Caelum 'El Perro Gris'", "Caelum").replace(" de Caelum", "").replace("Príncipe ", "")
			var disp_name: String = (short_name if c_known else "???") + star_tag
			var sw_btn := AstralTheme.button(disp_name, "PrimaryButton" if npc_id == cand_id else "TabLikeButton")
			sw_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sw_btn.custom_minimum_size.y = 36
			var mini_tex: Texture2D = AstralTheme.load_tex(str(NPC_PORTRAITS.get(cand_id, "")))
			if mini_tex != null:
				sw_btn.icon = mini_tex
				sw_btn.expand_icon = true
			var target_c: String = cand_id
			sw_btn.pressed.connect(func() -> void:
				if npc_id != target_c:
					_selected_npc_by_district[did] = target_c
					_last_reply = ""
					_last_effects = ""
					AstralAudio.play_ui()
					refresh())
			sw_h.add_child(sw_btn)

	var avail: bool = RelationshipManager.is_available(npc_id)
	var data: Dictionary = RelationshipManager.get_data(npc_id)
	var st: Dictionary = RelationshipManager.get_state(npc_id)

	var card := AstralTheme.panel("GlowPanel" if avail else "SunkenPanel")
	_npc_panel.add_child(card)
	var v := AstralTheme.vbox(8)
	card.add_child(v)

	if not avail:
		v.add_child(AstralTheme.label("☾ %s" % str(d["name"]).to_upper(), "HeadingLabel", AstralTheme.GOLD_PALE))
		v.add_child(AstralTheme.label(str(d["facility"]), "CaptionLabel", AstralTheme.TURQ))
		v.add_child(AstralTheme.label(str(d["ambient"]), "", AstralTheme.IVORY, true))
		return

	var known: bool = RelationshipManager.is_known(npc_id)
	var top_h := AstralTheme.hbox(12)
	v.add_child(top_h)

	var p_frame := AstralTheme.panel("CardPanel")
	p_frame.custom_minimum_size = Vector2(88, 88)
	top_h.add_child(p_frame)
	var p_tex := TextureRect.new()
	p_tex.texture = AstralTheme.load_tex(str(NPC_PORTRAITS.get(npc_id, "")))
	p_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p_tex.custom_minimum_size = Vector2(78, 78)
	if not known:
		p_tex.modulate = Color(0.08, 0.10, 0.18, 0.94)
	p_frame.add_child(p_tex)

	var tv := AstralTheme.vbox(3)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_h.add_child(tv)

	if not known:
		tv.add_child(AstralTheme.label("??? — Habitante de %s" % str(d["name"]), "HeadingLabel", AstralTheme.GOLD))
		tv.add_child(AstralTheme.label(str(data["title"]), "CaptionLabel", AstralTheme.TURQ))
		tv.add_child(AstralTheme.label("Todavía no se han presentado en persona.", "CaptionLabel", AstralTheme.MUTED, true))

		var meet_btn := AstralTheme.button("%s  Presentarse y Conocer (1 Punto Social)" % AstralTheme.G_STAR, "PrimaryButton")
		meet_btn.custom_minimum_size.y = 46
		meet_btn.disabled = RelationshipManager.social_points_left <= 0
		meet_btn.pressed.connect(func() -> void: _trigger_social(npc_id, "meet"))
		v.add_child(meet_btn)
		return

	var age_num: int = RelationshipManager.get_npc_age(npc_id)
	var age_txt: String = "%d años" % age_num if age_num < 900 else "Eterno"
	var rem_here: int = RelationshipManager.get_remaining_actions_for_npc(npc_id)
	var stage_n: int = int(st.get("stage", 1))
	p_frame.tooltip_text = "%s\n%s" % [str(data["bio"]), str(data["perk_desc"])]
	tv.add_child(AstralTheme.label("%s" % data["name"], "HeadingLabel", AstralTheme.GOLD))
	tv.add_child(AstralTheme.label(str(data["title"]), "CaptionLabel", AstralTheme.TURQ))
	var npc_chips := HFlowContainer.new()
	npc_chips.add_theme_constant_override("h_separation", 6)
	npc_chips.add_theme_constant_override("v_separation", 4)
	tv.add_child(npc_chips)
	npc_chips.add_child(AstralTheme.chip(age_txt, AstralTheme.IVORY, null, 12))
	npc_chips.add_child(AstralTheme.chip("Etapa %d/3" % stage_n, AstralTheme.GOLD_PALE, AstralTheme.GOLD, 12))
	npc_chips.add_child(AstralTheme.chip(RelationshipManager.get_relationship_status_title(npc_id), AstralTheme.ROSE, null, 12))
	npc_chips.add_child(AstralTheme.chip("Acciones %d/%d" % [rem_here, RelationshipManager.MAX_ACTIONS_PER_NPC], AstralTheme.TURQ if rem_here > 0 else AstralTheme.MUTED, null, 12))

	var aff_bar := StatBar.new()
	aff_bar.setup("Afecto", "aff", -100, 100, AstralTheme.ROSE, "Amistad (+) o Rencor (-).", 95)
	aff_bar.set_value(int(st["affection"]), false)
	v.add_child(aff_bar)
	var res_bar := StatBar.new()
	res_bar.setup("Respeto", "res", -100, 100, AstralTheme.GOLD, "Reconocimiento o desprecio.", 95)
	res_bar.set_value(int(st["respect"]), false)
	v.add_child(res_bar)
	if RelationshipManager.romance_available(npc_id):
		var spk_bar := StatBar.new()
		spk_bar.setup("Chispa", "spk", 0, 100, AstralTheme.AMETHYST, "Vínculo romántico.", 95)
		spk_bar.set_value(int(st["spark"]), false)
		v.add_child(spk_bar)

	v.add_child(AstralTheme.chip("%s %s" % [AstralTheme.G_SWORD, str(data["perk_desc"])], AstralTheme.TURQ, null, 12))

	if _last_npc_id == npc_id and _last_reply != "":
		var reply_p := AstralTheme.panel("SunkenPanel")
		var rv := AstralTheme.vbox(3)
		reply_p.add_child(rv)
		rv.add_child(AstralTheme.label(_last_reply, "", AstralTheme.IVORY, true))
		if _last_effects != "":
			rv.add_child(AstralTheme.label(_last_effects, "CaptionLabel", AstralTheme.GOOD, true))
		v.add_child(reply_p)

	var can_act: bool = RelationshipManager.can_interact_with(npc_id)
	var act_grid := GridContainer.new()
	act_grid.columns = 2
	act_grid.add_theme_constant_override("h_separation", 8)
	act_grid.add_theme_constant_override("v_separation", 8)
	v.add_child(act_grid)

	var b_chat := AstralTheme.button("❀ Conversar (1 Pt)", "PrimaryButton")
	b_chat.disabled = not can_act
	b_chat.pressed.connect(func() -> void: _trigger_social(npc_id, "chat"))
	act_grid.add_child(b_chat)

	var train_lbl: String = GameState.get_stat_label(str(data.get("role_stat", "temple")))
	var b_train := AstralTheme.button("⚔ Practicar %s (1 Pt)" % train_lbl, "TabLikeButton")
	b_train.disabled = not can_act
	b_train.pressed.connect(func() -> void: _trigger_social(npc_id, "train"))
	act_grid.add_child(b_train)

	if RelationshipManager.romance_available(npc_id):
		var b_rom := AstralTheme.button("♥ Cortejar (1 Pt)", "TabLikeButton")
		b_rom.disabled = (not can_act) or int(st["respect"]) < 25 or int(st["affection"]) < 20
		if int(st["respect"]) < 25 or int(st["affection"]) < 20:
			b_rom.tooltip_text = "Requiere al menos +20 Afecto y +25 Respeto."
		b_rom.pressed.connect(func() -> void: _trigger_social(npc_id, "romance"))
		act_grid.add_child(b_rom)

	var b_prov := AstralTheme.button("⚡ Desafiar / Rival (1 Pt)", "DangerButton")
	b_prov.disabled = not can_act
	b_prov.pressed.connect(func() -> void: _trigger_social(npc_id, "provoke"))
	act_grid.add_child(b_prov)

	# --- ENTREGA DE OBSEQUIOS COMPRADOS EN TIENDAS ---
	var gift_row := AstralTheme.hbox(8)
	v.add_child(gift_row)
	_gift_select = OptionButton.new()
	_gift_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var has_gifts: bool = false
	for g in CatalogDB.GIFTS:
		var gid: String = str(g["id"])
		var cnt: int = GameState.get_gift_count(gid)
		if cnt > 0:
			has_gifts = true
			_gift_select.add_item("%s (x%d)" % [str(g["name"]), cnt])
			_gift_select.set_item_metadata(_gift_select.item_count - 1, gid)
	if not has_gifts:
		_gift_select.add_item("Sin obsequios (compra en Palacio o Acueductos)")
		_gift_select.disabled = true
	gift_row.add_child(_gift_select)

	var b_gift := AstralTheme.button("✉ Regalar", "PrimaryButton")
	b_gift.disabled = (not can_act) or (not has_gifts)
	b_gift.pressed.connect(func() -> void:
		if _gift_select == null or _gift_select.selected < 0:
			return
		var gid: String = str(_gift_select.get_item_metadata(_gift_select.selected))
		if gid != "":
			_trigger_social(npc_id, "gift_item", gid))
	gift_row.add_child(b_gift)

	# --- SALIDA O CITA POR LA CIUDAD ---
	var is_rom_open: bool = RelationshipManager.romance_available(npc_id)
	var can_outing: bool = int(st.get("affection", 0)) >= RelationshipManager.OUTING_MIN_AFFECTION
	var out_box := AstralTheme.vbox(4)
	v.add_child(out_box)
	var out_hdr: String = ("♥ Cita en Aethelgard (req. +%d Afecto)" if is_rom_open else "✦ Salida en la Ciudad (req. +%d Afecto)") % RelationshipManager.OUTING_MIN_AFFECTION
	out_box.add_child(AstralTheme.label(out_hdr, "CaptionLabel", AstralTheme.ROSE if is_rom_open else AstralTheme.GOLD_PALE))
	var out_row := AstralTheme.hbox(8)
	out_box.add_child(out_row)
	_outing_select = OptionButton.new()
	_outing_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for spot_id in RelationshipManager.OUTING_SPOT_ORDER:
		var sp: Dictionary = RelationshipManager.OUTING_SPOTS.get(spot_id, {})
		var st_lbl: String = GameState.get_stat_label(str(sp.get("stat", "gracia")))
		var cost_g: int = int(sp.get("cost", 0))
		var cost_s: String = "Gratis" if cost_g <= 0 else ("%d G" % cost_g)
		_outing_select.add_item("%s (%s · +%d %s)" % [str(sp.get("name", spot_id)), cost_s, int(sp.get("stat_val", 5)), st_lbl])
		_outing_select.set_item_metadata(_outing_select.item_count - 1, spot_id)
	out_row.add_child(_outing_select)
	var b_outing := AstralTheme.button("♥ Cita (1 Pt)" if is_rom_open else "✦ Paseo (1 Pt)", "PrimaryButton")
	b_outing.disabled = (not can_act) or (not can_outing)
	if not can_outing:
		b_outing.tooltip_text = "Requiere al menos +%d de Afecto con %s." % [RelationshipManager.OUTING_MIN_AFFECTION, str(data.get("name", npc_id))]
	b_outing.pressed.connect(func() -> void:
		if _outing_select == null or _outing_select.selected < 0:
			return
		var spot_id: String = str(_outing_select.get_item_metadata(_outing_select.selected))
		if spot_id != "":
			_trigger_social(npc_id, "outing", spot_id))
	out_row.add_child(b_outing)

	# --- ESCENA DE HISTORIA SI DISPONIBLE ---
	var ev_chk: Dictionary = RelationshipManager.get_next_bond_event(npc_id)
	if bool(ev_chk.get("ok", false)):
		var b_ev := AstralTheme.button("★ Vivir Escena de Historia (Acto %d)" % int(ev_chk["stage"]), "PrimaryButton")
		b_ev.custom_minimum_size.y = 44
		b_ev.pressed.connect(func() -> void: bond_event_requested.emit(npc_id))
		v.add_child(b_ev)

func _trigger_cross_encounter(enc_id: String, choice_idx: int) -> void:
	var r: Dictionary = RelationshipManager.resolve_cross_encounter(enc_id, choice_idx)
	if bool(r.get("ok", false)):
		AstralAudio.play_confirm()
		_cross_result_title = str(r.get("speaker", "Encuentro en el Distrito"))
		_cross_result_body = str(r.get("reply", ""))
		_cross_result_fx = str(r.get("effects", ""))
		speak.emit(_cross_result_title, _cross_result_body)
		toast.emit(_cross_result_fx if _cross_result_fx != "" else _cross_result_title, "good")
		state_changed.emit()
		refresh()
	else:
		AstralAudio.play_warn()
		toast.emit(str(r.get("msg", "No fue posible resolver este encuentro.")), "warn")

func _trigger_social(npc_id: String, action_type: String, extra: String = "") -> void:
	var r: Dictionary = RelationshipManager.interact_with_candidate(npc_id, action_type, extra)
	if bool(r.get("ok", false)):
		AstralAudio.play_confirm()
		_last_npc_id = npc_id
		_last_reply = str(r.get("reply", ""))
		_last_effects = str(r.get("effects", ""))
		speak.emit(str(r.get("speaker", "")), _last_reply)
		toast.emit(_last_effects, "good")
		state_changed.emit()
		refresh()
	else:
		AstralAudio.play_warn()
		toast.emit(str(r.get("msg", "")), "warn")

# ------------------------------------------------------------------------------
# INSTALACIONES FÍSICAS DE CADA DISTRITO
# ------------------------------------------------------------------------------
func _make_facility_scroll() -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_facility_panel.add_child(sc)
	var inner := AstralTheme.vbox(10)
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(inner)
	return inner

func _build_district_facility(d: Dictionary) -> void:
	match str(d["id"]):
		"torre":
			_build_torre_facility()
		"patio":
			_build_patio_facility()
		"acueductos":
			_build_acueductos_facility()
		"palacio":
			_build_palacio_facility()
		"anfiteatro":
			_build_anfiteatro_facility()
		"espejo":
			_build_espejo_facility()

func _build_torre_facility() -> void:
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.custom_minimum_size = Vector2(0, 360)
	_facility_panel.add_child(tabs)

	var host: VBoxContainer = BaseWindow.add_tab(tabs, "  Archivos y Mazo  ")
	var p := AstralTheme.panel("CardPanel")
	host.add_child(p)
	var v := AstralTheme.vbox(8)
	p.add_child(v)
	var tier: int = GameState.get_secret_tier()
	v.add_child(AstralTheme.label("✦ ARCHIVOS Y MAZO DE RECUERDOS (%d/4)" % GameState.get_equipped_memory_cards().size(), "HeadingLabel", AstralTheme.GOLD))
	v.add_child(AstralTheme.label("%s: %d%%" % [GameState.get_stat_label("seal_investigation"), GameState.seal_investigation_progress], "SubLabel", AstralTheme.TURQ))
	if tier < 2:
		v.add_child(AstralTheme.label("Las vitrinas de la Torre catalogan vestigios borrados de las antiguas crónicas del firmamento.", "CaptionLabel", AstralTheme.MUTED, true))

	for c in CatalogDB.MEMORY_CARDS:
		var cid: String = str(c["id"])
		var unlocked: bool = GameState.is_memory_card_unlocked(c)
		if not unlocked and cid == "mem_bond_zephyr" and tier < 2:
			continue
		var equipped: bool = GameState.equipped_cards.has(cid)
		var card := AstralTheme.panel("GlowPanel" if equipped else ("CardPanel" if unlocked else "SunkenPanel"))
		var r := AstralTheme.hbox(8)
		card.add_child(r)
		var inf := AstralTheme.vbox(2)
		inf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(inf)
		var ttl: String = "%s  (%s)" % [str(c["name"]), str(c["source_label"])]
		inf.add_child(AstralTheme.label(ttl, "CaptionLabel", AstralTheme.GOLD_PALE if unlocked else AstralTheme.MUTED, true))
		inf.add_child(AstralTheme.label(str(c["desc"]), "CaptionLabel", AstralTheme.IVORY if unlocked else AstralTheme.MUTED, true))
		var b := AstralTheme.button("Quitar" if equipped else ("Equipar" if unlocked else "Bloqueada"), "PrimaryButton" if (unlocked and not equipped) else "")
		b.custom_minimum_size = Vector2(96, 38)
		b.disabled = not unlocked
		b.pressed.connect(func() -> void:
			var res: Dictionary = GameState.toggle_equipped_card(cid)
			AstralAudio.play_confirm() if res.get("ok", false) else AstralAudio.play_warn()
			toast.emit(str(res.get("msg", "")), "good" if res.get("ok", false) else "warn")
			state_changed.emit()
			refresh())
		r.add_child(b)
		v.add_child(card)

	var tome_v: VBoxContainer = BaseWindow.add_tab(tabs, "  Biblioteca de Tratados  ")
	tome_v.add_child(AstralTheme.chip("Tratados antiguos y códices coleccionables · Oro: %d G · %d/%d adquiridos" % [GameState.gold, GameState.owned_tomes.size(), CatalogDB.STUDY_TOMES.size()], AstralTheme.GOLD_PALE, AstralTheme.GOLD, 13))
	for t in CatalogDB.STUDY_TOMES:
		if GameState.age < int(t.get("min_age", 12)):
			continue
		var tid: String = str(t["id"])
		var owned: bool = GameState.owned_tomes.has(tid)
		var price: int = int(t["price"])
		var tc := AstralTheme.panel("GlowPanel" if owned else "CardPanel")
		tc.tooltip_text = str(t["desc"])
		var th := AstralTheme.hbox(10)
		tc.add_child(th)
		var tvign := AstralTheme.vignette_card(str(t.get("icon", "res://assets/art/illus_study_astrolabe.png")), Vector2(64, 54), AstralTheme.TURQ if owned else AstralTheme.GOLD_DARK)
		tvign.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		th.add_child(tvign)
		var tinf := AstralTheme.vbox(3)
		tinf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		th.add_child(tinf)
		tinf.add_child(AstralTheme.label(str(t["name"]), "SubLabel", AstralTheme.TURQ if owned else AstralTheme.GOLD_PALE, true))
		tinf.add_child(AstralTheme.label(str(t["desc"]), "CaptionLabel", AstralTheme.IVORY, true))
		var tb := AstralTheme.button(AstralTheme.G_CHECK + " Archivado" if owned else "Adquirir (%d G)" % price, "PrimaryButton" if (not owned and GameState.gold >= price) else "")
		tb.custom_minimum_size = Vector2(148, 42)
		tb.disabled = owned or GameState.gold < price
		tb.pressed.connect(func() -> void:
			var r: Dictionary = GameState.buy_tome(tid)
			AstralAudio.play_triumph() if bool(r.get("ok", false)) else AstralAudio.play_warn()
			toast.emit(str(r.get("msg", "")), "good" if bool(r.get("ok", false)) else "warn")
			state_changed.emit()
			refresh())
		th.add_child(tb)
		tome_v.add_child(tc)

	tabs.current_tab = clampi(int(_facility_tab_by_district.get("torre", 0)), 0, tabs.get_tab_count() - 1)
	tabs.tab_changed.connect(func(idx: int) -> void:
		_facility_tab_by_district["torre"] = idx)

func _build_patio_facility() -> void:
	# Práctica de Esgrima directa + Expediciones + Armería de Élite
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.custom_minimum_size = Vector2(0, 360)
	_facility_panel.add_child(tabs)

	var host: VBoxContainer = BaseWindow.add_tab(tabs, "  Esgrima y Expediciones  ")
	var duel_p := AstralTheme.panel("GlowPanel")
	host.add_child(duel_p)
	var dh := AstralTheme.hbox(10)
	duel_p.add_child(dh)
	var dv := AstralTheme.vbox(2)
	dv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dh.add_child(dv)
	dv.add_child(AstralTheme.label("⚔ ARENA DE ESGRIMA DEL PATIO DUCAL", "SubLabel", AstralTheme.GOLD))
	dv.add_child(AstralTheme.label("Minijuego de reflejos en 3 asaltos (guardia, amague y remate).", "CaptionLabel", AstralTheme.MUTED, true))
	var mg_btn := AstralTheme.button(
		"✓ Ya practicado" if TurnExecutor.school_minigame_used_this_bimester else "⚔ Practicar Esgrima",
		"PrimaryButton"
	)
	mg_btn.custom_minimum_size = Vector2(180, 42)
	mg_btn.disabled = TurnExecutor.school_minigame_used_this_bimester
	mg_btn.pressed.connect(func() -> void:
		festival_minigame_requested.emit("fencing", "PATIO DE ARMAS: ASALTO DE ESGRIMA"))
	dh.add_child(mg_btn)

	var exp_p := AstralTheme.panel("CardPanel")
	host.add_child(exp_p)
	var ev := AstralTheme.vbox(8)
	exp_p.add_child(ev)
	ev.add_child(AstralTheme.label("⚔ EXPEDICIONES DESDE LA PUERTA NORTE (4 NODOS)", "HeadingLabel", AstralTheme.GOLD))

	var ch := AstralTheme.hbox(8)
	ev.add_child(ch)
	ch.add_child(AstralTheme.label("Compañero:", "CaptionLabel", AstralTheme.MUTED))
	var comp_opt := OptionButton.new()
	comp_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	comp_opt.add_item("%s — Escolta Solitaria" % GameState.daughter_name)
	comp_opt.set_item_metadata(0, "solo")
	var sel_idx: int = 0
	for nid in RelationshipManager.NPC_ORDER:
		if RelationshipManager.is_available(nid) and RelationshipManager.is_known(nid):
			var ndata: Dictionary = RelationshipManager.get_data(nid)
			comp_opt.add_item("%s — %s" % [ndata["name"], ndata["title"]])
			var idx: int = comp_opt.item_count - 1
			comp_opt.set_item_metadata(idx, nid)
			if nid == _selected_comp:
				sel_idx = idx
	comp_opt.selected = sel_idx
	comp_opt.item_selected.connect(func(idx: int) -> void:
		_selected_comp = str(comp_opt.get_item_metadata(idx)))
	ch.add_child(comp_opt)

	var cur_comp: String = str(comp_opt.get_item_metadata(comp_opt.selected))
	_selected_comp = cur_comp
	var comp_ok: bool = ExplorationCombat.can_recruit_companion(cur_comp)

	var boss_icons: Array[String] = [
		"res://assets/ui/boss_deer.png",
		"res://assets/ui/boss_sphinx.png",
		"res://assets/ui/boss_colossus.png",
		"res://assets/ui/boss_herald.png",
		"res://assets/ui/boss_archon.png"
	]
	var tier: int = GameState.get_secret_tier()
	var relic_word: String = "Esquirla" if tier >= 2 else "Vestigio"
	for i in range(ExplorationCombat.ZONES.size()):
		var z: Dictionary = ExplorationCombat.ZONES[i]
		var min_age: int = int(z["min_age"])
		if GameState.age < min_age:
			continue
		var has_shard: bool = ExplorationCombat.memory_shards_found.has(z["shard_id"])
		var card := AstralTheme.panel("SunkenPanel")
		card.tooltip_text = "%s\nJefe: %s" % [str(z["desc"]), str(z["boss_name"])]
		var zr := AstralTheme.hbox(10)
		card.add_child(zr)
		var b_path: String = boss_icons[i] if i < boss_icons.size() else CatalogDB.get_zone_backdrop(str(z.get("id", "zone_1")))
		zr.add_child(AstralTheme.icon_box(b_path, Vector2(54, 54), Color.WHITE, "GlowPanel" if not has_shard else "CardPanel"))
		var zv := AstralTheme.vbox(4)
		zv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		zr.add_child(zv)
		zv.add_child(AstralTheme.label(str(z["name"]), "SubLabel", AstralTheme.GOLD_PALE, true))
		var z_chips := HFlowContainer.new()
		z_chips.add_theme_constant_override("h_separation", 6)
		z_chips.add_theme_constant_override("v_separation", 4)
		zv.add_child(z_chips)
		z_chips.add_child(AstralTheme.chip("4 Nodos", AstralTheme.IVORY, null, 12))
		z_chips.add_child(AstralTheme.chip("+%d G" % int(z["gold_reward"]), AstralTheme.GOLD, null, 12))
		z_chips.add_child(AstralTheme.chip("%s %s" % [AstralTheme.G_CHECK if has_shard else AstralTheme.G_STAR, relic_word], AstralTheme.GOOD if has_shard else AstralTheme.TURQ, null, 12))
		var b_go := AstralTheme.button(
			"Explorada" if ExplorationCombat.explored_this_bimester else "⚔ Explorar",
			"PrimaryButton"
		)
		b_go.custom_minimum_size = Vector2(124, 46)
		b_go.disabled = ExplorationCombat.explored_this_bimester or not comp_ok
		var zi: int = i
		b_go.pressed.connect(func() -> void:
			var cname: String = GameState.daughter_name if cur_comp == "solo" else str(RelationshipManager.get_data(cur_comp).get("name", cur_comp))
			expedition_requested.emit(zi, cur_comp, cname))
		zr.add_child(b_go)
		ev.add_child(card)

	var arm_v: VBoxContainer = BaseWindow.add_tab(tabs, "  Armería de Élite  ")
	arm_v.add_child(AstralTheme.chip("Forja marcial e instrumental de exploración · Oro: %d G" % GameState.gold, AstralTheme.GOLD_PALE, AstralTheme.GOLD, 13))
	_build_equipment_shop_list(arm_v, "patio")

	tabs.current_tab = clampi(int(_facility_tab_by_district.get("patio", 0)), 0, tabs.get_tab_count() - 1)
	tabs.tab_changed.connect(func(idx: int) -> void:
		_facility_tab_by_district["patio"] = idx)

func _build_equipment_shop_list(parent: VBoxContainer, shop_filter: String) -> void:
	var egrid := GridContainer.new()
	egrid.columns = 2
	egrid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	egrid.add_theme_constant_override("h_separation", 8)
	egrid.add_theme_constant_override("v_separation", 8)
	parent.add_child(egrid)
	for eq in CatalogDB.EQUIPMENT:
		if str(eq.get("shop", "")) != shop_filter:
			continue
		if GameState.age < int(eq.get("min_age", 12)):
			continue
		var eid: String = str(eq["id"])
		var slot: String = str(eq.get("slot", "weapon"))
		var owned: bool = GameState.owned_equipment.has(eid)
		var equipped: bool = (GameState.equipped_weapon == eid) or (GameState.equipped_accessory == eid)
		var price: int = int(eq["price"])
		var ec := AstralTheme.panel("GlowPanel" if equipped else "CardPanel")
		ec.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ec.tooltip_text = str(eq["desc"])
		var ev := AstralTheme.vbox(6)
		ec.add_child(ev)
		var eh := AstralTheme.hbox(8)
		ev.add_child(eh)
		var evign := AstralTheme.vignette_card(str(eq.get("icon", "")), Vector2(54, 48), AstralTheme.TURQ if equipped else AstralTheme.GOLD_DARK)
		evign.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		eh.add_child(evign)
		var einf := AstralTheme.vbox(2)
		einf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		eh.add_child(einf)
		einf.add_child(AstralTheme.label("%s (%s)" % [str(eq["name"]), "Arma" if slot == "weapon" else "Reliquia"], "CaptionLabel", AstralTheme.TURQ if equipped else AstralTheme.GOLD_PALE, true))
		einf.add_child(AstralTheme.label(str(eq["desc"]), "CaptionLabel", AstralTheme.IVORY, true))
		var eb := AstralTheme.button(
			"✓ Equipado (Quitar)" if equipped else ("Equipar" if owned else "Forjar (%d G)" % price),
			"PrimaryButton" if (owned or GameState.gold >= price) else ""
		)
		eb.custom_minimum_size.y = 36
		eb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		eb.disabled = (not owned) and GameState.gold < price
		eb.pressed.connect(func() -> void:
			var r: Dictionary = GameState.buy_equipment(eid) if not owned else GameState.equip_item(eid)
			AstralAudio.play_confirm() if bool(r.get("ok", false)) else AstralAudio.play_warn()
			toast.emit(str(r.get("msg", "")), "good" if bool(r.get("ok", false)) else "warn")
			state_changed.emit()
			refresh())
		ev.add_child(eb)
		egrid.add_child(ec)

func _build_acueductos_facility() -> void:
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.custom_minimum_size = Vector2(0, 360)
	_facility_panel.add_child(tabs)

	# Sub-tab 1: Bazar Nocturno + Obsequios
	var shop_v: VBoxContainer = BaseWindow.add_tab(tabs, "  Bazar y Obsequios  ")
	var feria_par: bool = TimeManager.is_bazaar_open()
	var rep_pct: int = mini(15, int(GameState.father_reputation / 7))
	var total_disc: int = rep_pct + (15 if feria_par else 0)
	shop_v.add_child(AstralTheme.chip(
		"%s Feria de Medianoche (-15%% extra en Reliquias) · Dto. total %d%% · Oro: %d G" % [AstralTheme.G_STAR, total_disc, GameState.gold] if feria_par else "Puesto de Zahir abierto · Oro: %d G · Dto. Reputación %d%%" % [GameState.gold, rep_pct],
		AstralTheme.TURQ if feria_par else AstralTheme.GOLD_PALE, null, 13
	))

	shop_v.add_child(AstralTheme.label("✦ Obsequios del Mercado", "SubLabel", AstralTheme.GOLD))
	var acq_ggrid := GridContainer.new()
	acq_ggrid.columns = 2
	acq_ggrid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	acq_ggrid.add_theme_constant_override("h_separation", 8)
	acq_ggrid.add_theme_constant_override("v_separation", 8)
	shop_v.add_child(acq_ggrid)
	for g in CatalogDB.get_gifts_for_shop("aqueducts"):
		var gc := _make_gift_buy_row(g)
		gc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		acq_ggrid.add_child(gc)

	shop_v.add_child(AstralTheme.separator())
	shop_v.add_child(AstralTheme.label("⚗ Reliquias de Zahir (Bazar de los Acueductos)", "SubLabel", AstralTheme.GOLD))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	shop_v.add_child(grid)
	for m in CatalogDB.COSMIC_MATERIALS:
		var price: int = CrucibleManager.get_material_price(m)
		var need_rep: int = int(m.get("exclusive_rep", 0))
		var locked_rep: bool = GameState.father_reputation < need_rep
		var mid: String = str(m["id"])
		var owned_cnt: int = int(GameState.materials_inventory.get(mid, 0))
		var can_buy: bool = (not locked_rep) and GameState.gold >= price

		var stat_parts: Array[String] = []
		var m_stats: Dictionary = m.get("stats", {})
		for sk in m_stats.keys():
			stat_parts.append("%s +%d" % [GameState.get_stat_label(str(sk)), int(m_stats[sk])])
		var stat_hint: String = ", ".join(stat_parts)

		var rcard := AstralTheme.panel("CardPanel")
		rcard.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rcard.custom_minimum_size = Vector2(210, 128)
		rcard.tooltip_text = "%s\n%s" % [str(m["name"]), stat_hint]
		var rv := AstralTheme.vbox(6)
		rcard.add_child(rv)
		var rh := AstralTheme.hbox(8)
		rv.add_child(rh)
		var rvign := AstralTheme.vignette_card(CatalogDB.get_relic_icon(mid), Vector2(46, 46), AstralTheme.AMETHYST)
		rvign.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rh.add_child(rvign)
		var rvb := AstralTheme.vbox(2)
		rvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rh.add_child(rvb)
		var top_r := AstralTheme.hbox(6)
		rvb.add_child(top_r)
		var rnm := AstralTheme.label(str(m["name"]), "CaptionLabel", AstralTheme.GOLD_PALE, true)
		rnm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_r.add_child(rnm)
		if owned_cnt > 0:
			top_r.add_child(AstralTheme.chip("×%d" % owned_cnt, AstralTheme.TURQ, null, 11))
		if stat_hint != "":
			rvb.add_child(AstralTheme.label(stat_hint, "CaptionLabel", AstralTheme.TURQ, true))
		var btn_txt: String = "Requiere Rep. %d+" % need_rep if locked_rep else "Comprar (%d G)" % price
		var b := AstralTheme.button(btn_txt, "PrimaryButton" if can_buy else "")
		b.custom_minimum_size.y = 36
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = not can_buy
		b.pressed.connect(func() -> void:
			var r: Dictionary = CrucibleManager.buy_material(mid)
			AstralAudio.play_confirm() if r.get("ok", false) else AstralAudio.play_warn()
			toast.emit(str(r.get("msg", "")), "good" if r.get("ok", false) else "warn")
			state_changed.emit()
			refresh())
		rv.add_child(b)
		grid.add_child(rcard)

	# Sub-tab 2: Boticario / Sanatorio Privado
	var doc_v: VBoxContainer = BaseWindow.add_tab(tabs, "  Boticario del Lirio  ")
	doc_v.add_child(AstralTheme.label("Botica y Sanatorio Privado de Aethelgard. Atiende fatiga nerviosa y agotamiento crítico.", "CaptionLabel", AstralTheme.IVORY, true))

	var cure_p := AstralTheme.panel("GlowPanel" if GameState.exhausted_sick else "CardPanel")
	var cv := AstralTheme.vbox(6)
	cure_p.add_child(cv)
	cv.add_child(AstralTheme.label("♥ Sanatorio Privado (-80 G)", "SubLabel", AstralTheme.GOLD))
	cv.add_child(AstralTheme.label("Restaura -28 Estrés y levanta el estado de Agotamiento Crítico." if GameState.exhausted_sick else "Disponible cuando el Agotamiento Crítico bloquee las aulas (90+ Estrés).", "CaptionLabel", AstralTheme.MUTED, true))
	var b_cure := AstralTheme.button("Ingresar al Sanatorio (-80 G)", "PrimaryButton")
	b_cure.disabled = (not GameState.exhausted_sick) or GameState.gold < 80
	b_cure.pressed.connect(func() -> void:
		if not GameState.modify_gold(-80):
			return
		GameState.modify_stat("stress", -28)
		GameState.exhausted_sick = false
		GameState.sick_dialogue_pending = false
		AstralAudio.play_confirm()
		toast.emit("Tratamiento completado en el Boticario (-80 G, -28 Estrés). Renpet vuelve a estar sana.", "good")
		state_changed.emit()
		refresh())
	cv.add_child(b_cure)
	doc_v.add_child(cure_p)

	var ton_p := AstralTheme.panel("CardPanel")
	var tv := AstralTheme.vbox(6)
	ton_p.add_child(tv)
	tv.add_child(AstralTheme.label("❀ Tónico de Azahar y Lirio (-55 G · 1/bimestre)", "SubLabel", AstralTheme.TURQ))
	tv.add_child(AstralTheme.label("Reduce -16 Estrés de inmediato sin gastar energía paternal.", "CaptionLabel", AstralTheme.IVORY, true))
	var b_ton := AstralTheme.button("✓ Tónico usado" if GameState.clinic_tonic_used else "Comprar Tónico (-55 G)", "TabLikeButton")
	b_ton.disabled = GameState.clinic_tonic_used or GameState.gold < 55
	b_ton.pressed.connect(func() -> void:
		if not GameState.modify_gold(-55):
			return
		GameState.clinic_tonic_used = true
		GameState.modify_stat("stress", -16)
		AstralAudio.play_confirm()
		toast.emit("El tónico calma el pulso de %s (-16 Estrés)." % GameState.daughter_name, "good")
		state_changed.emit()
		refresh())
	tv.add_child(b_ton)
	doc_v.add_child(ton_p)

	doc_v.add_child(AstralTheme.separator())
	doc_v.add_child(AstralTheme.label("⚗ Botica de Campaña (Consumibles 0 PA en Expediciones) · Oro: %d G" % GameState.gold, "SubLabel", AstralTheme.GOLD))
	var cgrid := GridContainer.new()
	cgrid.columns = 2
	cgrid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cgrid.add_theme_constant_override("h_separation", 8)
	cgrid.add_theme_constant_override("v_separation", 8)
	doc_v.add_child(cgrid)
	for item in CatalogDB.COMBAT_CONSUMABLES:
		if GameState.age < int(item.get("min_age", 12)):
			continue
		var iid: String = str(item["id"])
		var price: int = int(item["price"])
		var cnt: int = GameState.get_consumable_count(iid)
		var cc := AstralTheme.panel("CardPanel")
		cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cc.tooltip_text = str(item["desc"])
		var cvb := AstralTheme.vbox(6)
		cc.add_child(cvb)
		var ch_row := AstralTheme.hbox(8)
		cvb.add_child(ch_row)
		var cvign := AstralTheme.vignette_card(str(item.get("icon", "")), Vector2(44, 44), AstralTheme.TURQ)
		cvign.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ch_row.add_child(cvign)
		var cinf := AstralTheme.vbox(2)
		cinf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ch_row.add_child(cinf)
		var top_c := AstralTheme.hbox(6)
		cinf.add_child(top_c)
		var cnm := AstralTheme.label(str(item["name"]), "CaptionLabel", AstralTheme.GOLD_PALE, true)
		cnm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_c.add_child(cnm)
		if cnt > 0:
			top_c.add_child(AstralTheme.chip("×%d" % cnt, AstralTheme.TURQ, null, 11))
		cinf.add_child(AstralTheme.label(str(item["desc"]), "CaptionLabel", AstralTheme.IVORY, true))
		var cb := AstralTheme.button("Comprar (%d G)" % price, "PrimaryButton" if GameState.gold >= price else "")
		cb.custom_minimum_size.y = 34
		cb.disabled = GameState.gold < price
		cb.pressed.connect(func() -> void:
			var r: Dictionary = GameState.buy_consumable(iid)
			AstralAudio.play_confirm() if bool(r.get("ok", false)) else AstralAudio.play_warn()
			toast.emit(str(r.get("msg", "")), "good" if bool(r.get("ok", false)) else "warn")
			state_changed.emit()
			refresh())
		cvb.add_child(cb)
		cgrid.add_child(cc)

	tabs.current_tab = clampi(int(_facility_tab_by_district.get("acueductos", 0)), 0, tabs.get_tab_count() - 1)
	tabs.tab_changed.connect(func(idx: int) -> void:
		_facility_tab_by_district["acueductos"] = idx)

func _build_palacio_facility() -> void:
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.custom_minimum_size = Vector2(0, 360)
	_facility_panel.add_child(tabs)

	# Sub-tab 1: Boutique de Atuendos (Galería visual 2 columnas)
	var bout_v: VBoxContainer = BaseWindow.add_tab(tabs, "  Boutique Imperial  ")
	bout_v.add_child(AstralTheme.chip("Sastrería de Alabastro · Oro: %d G · Cambia el retrato y otorga bonos pasivos" % GameState.gold, AstralTheme.GOLD_PALE, AstralTheme.GOLD, 13))
	var bout_grid := GridContainer.new()
	bout_grid.columns = 2
	bout_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bout_grid.add_theme_constant_override("h_separation", 10)
	bout_grid.add_theme_constant_override("v_separation", 10)
	bout_v.add_child(bout_grid)
	for o in CatalogDB.OUTFITS:
		var oid: String = str(o["id"])
		var owned: bool = GameState.owned_outfits.has(oid)
		var equipped: bool = (GameState.equipped_outfit == oid)
		var price: int = int(o.get("price", 0))
		var card := AstralTheme.panel("GlowPanel" if equipped else "CardPanel")
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(220, 148)
		card.tooltip_text = str(o["bonus_desc"])
		var ov := AstralTheme.vbox(8)
		card.add_child(ov)
		var top_r := AstralTheme.hbox(10)
		ov.add_child(top_r)
		var p_path: String = str(o.get("portrait", ""))
		if p_path != "":
			top_r.add_child(AstralTheme.icon_box(p_path, Vector2(76, 92), Color.WHITE, "GlowPanel" if equipped else "SunkenPanel"))
		var inf := AstralTheme.vbox(4)
		inf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inf.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		top_r.add_child(inf)
		inf.add_child(AstralTheme.label(str(o["name"]), "SubLabel", AstralTheme.TURQ if equipped else AstralTheme.GOLD_PALE, true))
		if equipped:
			inf.add_child(AstralTheme.chip(AstralTheme.G_CHECK + " Equipado", AstralTheme.TURQ, null, 12))
		elif owned:
			inf.add_child(AstralTheme.chip("En guardarropa", AstralTheme.IVORY, null, 12))
		else:
			inf.add_child(AstralTheme.chip("%d G" % price, AstralTheme.GOLD_PALE, AstralTheme.GOLD, 12))
		inf.add_child(AstralTheme.label(str(o["bonus_desc"]), "CaptionLabel", AstralTheme.IVORY, true))
		var btn := AstralTheme.button("Equipado" if equipped else ("Equipar" if owned else "Comprar (%d G)" % price), "PrimaryButton" if (owned or GameState.gold >= price) else "")
		btn.custom_minimum_size.y = 42
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.disabled = equipped or (not owned and GameState.gold < price)
		btn.pressed.connect(func() -> void:
			var res: Dictionary
			if not owned:
				res = GameState.buy_outfit(oid)
			else:
				res = GameState.equip_outfit(oid)
			AstralAudio.play_confirm() if bool(res.get("ok", false)) else AstralAudio.play_warn()
			var ok_msg: String = "Atuendo equipado: %s" % str(o["name"]) if owned else "Comprado y equipado: %s" % str(o["name"])
			toast.emit(ok_msg if bool(res.get("ok", false)) else str(res.get("msg", "Oro insuficiente.")), "good" if bool(res.get("ok", false)) else "warn")
			state_changed.emit()
			refresh())
		ov.add_child(btn)
		bout_grid.add_child(card)

	# Sub-tab 2: Joyería y Floristería de Corte
	var gift_v: VBoxContainer = BaseWindow.add_tab(tabs, "  Obsequios Finos  ")
	gift_v.add_child(AstralTheme.chip("Presentes selectos para regalar a tus aliados en el Mapa", AstralTheme.MUTED, null, 13))
	var pal_ggrid := GridContainer.new()
	pal_ggrid.columns = 2
	pal_ggrid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pal_ggrid.add_theme_constant_override("h_separation", 8)
	pal_ggrid.add_theme_constant_override("v_separation", 8)
	gift_v.add_child(pal_ggrid)
	for g in CatalogDB.get_gifts_for_shop("palace"):
		var gc := _make_gift_buy_row(g)
		gc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pal_ggrid.add_child(gc)

	# Sub-tab 3: Senado Imperial y Rivales
	var sen_v: VBoxContainer = BaseWindow.add_tab(tabs, "  Senado y Rivales  ")
	var sus_p := AstralTheme.panel("GlowPanel")
	var sv := AstralTheme.vbox(6)
	sus_p.add_child(sv)
	sv.add_child(AstralTheme.label("⚖ VIGILANCIA DEL SENADO SOLAR", "HeadingLabel", AstralTheme.GOLD))
	var sbar := StatBar.new()
	sbar.setup("Sospecha del Senado", "court_suspicion", 0, 100, AstralTheme.BAD if GameState.court_suspicion >= 60 else AstralTheme.ROSE, "", 165)
	sbar.set_value(GameState.court_suspicion, false)
	sv.add_child(sbar)
	var free_e: int = GameState.father_energy - TurnExecutor.get_father_energy_used()
	var dip_row := AstralTheme.hbox(8)
	sv.add_child(dip_row)
	var b_court := AstralTheme.button("⚖ Audiencia (-15 E, -40 G)", "PrimaryButton")
	b_court.tooltip_text = "Presenta descargos formales ante la corte: -25 Sospecha."
	b_court.disabled = free_e < 15 or GameState.gold < 40 or GameState.court_suspicion <= 0
	b_court.pressed.connect(func() -> void:
		GameState.begin_batch()
		GameState.modify_stat("father_energy", -15)
		GameState.modify_gold(-40)
		GameState.modify_stat("court_suspicion", -25)
		GameState.end_batch()
		AstralAudio.play_confirm()
		toast.emit("Descargos diplomáticos aceptados (-25 Sospecha)", "good")
		state_changed.emit()
		refresh())
	dip_row.add_child(b_court)
	var b_parade := AstralTheme.button("☀ Desfile (-30 E)", "TabLikeButton")
	b_parade.tooltip_text = "Aurelius encabeza una parada cívica: +6 Reputación Paterna y -18 Sospecha."
	b_parade.disabled = free_e < 30
	b_parade.pressed.connect(func() -> void:
		GameState.begin_batch()
		GameState.modify_stat("father_energy", -30)
		GameState.modify_stat("father_reputation", 6)
		GameState.modify_stat("court_suspicion", -18)
		GameState.end_batch()
		AstralAudio.play_confirm()
		toast.emit("Desfile cívico aclamado (+6 Rep. Paterna, -18 Sospecha)", "good")
		state_changed.emit()
		refresh())
	dip_row.add_child(b_parade)
	var b_bribe := AstralTheme.button("Censor (-110 G)", "TabLikeButton")
	b_bribe.tooltip_text = "Regalo discreto a los escribas del Senado: -30 Sospecha sin gastar Energía."
	b_bribe.disabled = GameState.gold < 110 or GameState.court_suspicion <= 0
	b_bribe.pressed.connect(func() -> void:
		GameState.begin_batch()
		GameState.modify_gold(-110)
		GameState.modify_stat("court_suspicion", -30)
		GameState.end_batch()
		AstralAudio.play_confirm()
		toast.emit("Registros archivados discretamente (-30 Sospecha)", "good")
		state_changed.emit()
		refresh())
	dip_row.add_child(b_bribe)
	sen_v.add_child(sus_p)

	sen_v.add_child(AstralTheme.label("Rivales académicos de Aethelgard", "SubLabel", AstralTheme.GOLD_PALE))
	for rid in RivalMirror.RIVAL_ORDER:
		var rinfo: Dictionary = RivalMirror.get_data(rid)
		var rst: Dictionary = RivalMirror.get_standing(rid)
		var r_avail: bool = RelationshipManager.is_available(rid)
		var r_known: bool = r_avail and RelationshipManager.is_known(rid)
		var r_st: Dictionary = RelationshipManager.get_state(rid)
		var r_bond_ev: Dictionary = RelationshipManager.get_next_bond_event(rid) if r_avail else {}
		var r_has_ev: bool = bool(r_bond_ev.get("ok", false))
		var target_did: String = _get_district_for_npc(rid)

		var rc := AstralTheme.panel("GlowPanel" if r_has_ev else "CardPanel")
		var r_main := AstralTheme.vbox(6)
		rc.add_child(r_main)

		var rh := AstralTheme.hbox(10)
		r_main.add_child(rh)

		var r_pframe := AstralTheme.panel("SunkenPanel")
		r_pframe.custom_minimum_size = Vector2(58, 58)
		rh.add_child(r_pframe)
		var r_ptex := TextureRect.new()
		r_ptex.texture = AstralTheme.load_tex(str(NPC_PORTRAITS.get(rid, "")))
		r_ptex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r_ptex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		r_ptex.custom_minimum_size = Vector2(50, 50)
		if not r_known:
			r_ptex.modulate = Color(0.08, 0.10, 0.18, 0.94)
		r_pframe.add_child(r_ptex)

		var rv := AstralTheme.vbox(3)
		rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rh.add_child(rv)
		rv.add_child(AstralTheme.label("%s — %s" % [str(rinfo.get("full_name", rid)), str(rinfo.get("domain", ""))], "CaptionLabel", AstralTheme.GOLD_PALE, true))

		var r_chips := HFlowContainer.new()
		r_chips.add_theme_constant_override("h_separation", 6)
		r_chips.add_theme_constant_override("v_separation", 3)
		rv.add_child(r_chips)
		if r_known:
			r_chips.add_child(AstralTheme.chip(RelationshipManager.get_relationship_status_title(rid), AstralTheme.ROSE, null, 11))
			r_chips.add_child(AstralTheme.chip("Af %d · Resp %d · Et %d/3" % [int(r_st.get("affection", 0)), int(r_st.get("respect", 0)), int(r_st.get("stage", 1))], AstralTheme.TURQ, null, 11))
		else:
			r_chips.add_child(AstralTheme.chip("Sin trato personal", AstralTheme.MUTED, null, 11))
		r_chips.add_child(AstralTheme.chip(str(rst.get("label", "")), AstralTheme.GOLD, null, 11))

		var mine_v: int = int(rst.get("mine", 0))
		var theirs_v: int = int(rst.get("theirs", 0))
		var cap_v: float = maxf(100.0, float(maxi(mine_v, theirs_v) + 40))
		rv.add_child(AstralTheme.label("%s: %d  vs  %d" % [GameState.daughter_name, mine_v, theirs_v], "CaptionLabel", AstralTheme.IVORY, true))
		var cmp_bar := ProgressBar.new()
		cmp_bar.max_value = cap_v
		cmp_bar.value = float(mine_v)
		cmp_bar.show_percentage = false
		cmp_bar.custom_minimum_size = Vector2(0, 7)
		cmp_bar.modulate = AstralTheme.TURQ if mine_v >= theirs_v else AstralTheme.ROSE
		rv.add_child(cmp_bar)

		var quote_s: String = RivalMirror.get_status_quote(rid)
		if quote_s != "":
			r_main.add_child(AstralTheme.label("«%s»" % quote_s, "CaptionLabel", AstralTheme.MUTED, true))

		var btn_row := AstralTheme.hbox(8)
		r_main.add_child(btn_row)
		var target_rid: String = rid

		var b_visit := AstralTheme.button("★ Escena (Acto %d)" % int(r_bond_ev.get("stage", 1)) if r_has_ev else "✦ Visitar en Distrito", "PrimaryButton" if r_has_ev else "TabLikeButton")
		b_visit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b_visit.custom_minimum_size.y = 34
		b_visit.pressed.connect(func() -> void:
			if r_has_ev:
				bond_event_requested.emit(target_rid)
			else:
				_selected_npc_by_district[target_did] = target_rid
				_enter_district(target_did))
		btn_row.add_child(b_visit)

		var rbtn := AstralTheme.button("⚔ Retar a Duelo", "TabLikeButton")
		rbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rbtn.custom_minimum_size.y = 34
		rbtn.disabled = RivalMirror.challenged_this_bimester
		rbtn.pressed.connect(func() -> void:
			var dr: Dictionary = RivalMirror.challenge_rival_duel(target_rid)
			if bool(dr.get("ok", false)):
				AstralAudio.play_triumph() if bool(dr.get("won", false)) else AstralAudio.play_warn()
				speak.emit(str(dr.get("speaker", "")), "%s\n[color=%s]%s[/color]" % [str(dr.get("reply", "")), AstralTheme.hex(AstralTheme.GOLD_PALE), str(dr.get("effects", ""))])
				toast.emit("¡Victoria de prestigio!" if bool(dr.get("won", false)) else "Derrota honorable: aprendizaje valioso", "good" if bool(dr.get("won", false)) else "warn")
				state_changed.emit()
				refresh()
			else:
				AstralAudio.play_warn()
				toast.emit(str(dr.get("msg", "")), "warn"))
		btn_row.add_child(rbtn)
		sen_v.add_child(rc)

	# Sub-tab 4 (después de Tabs 0..2 para conservar índices): Patronazgo Cívico y Joyería Real
	var pat_v: VBoxContainer = BaseWindow.add_tab(tabs, "  Patronazgo y Joyería  ")
	pat_v.add_child(AstralTheme.chip("Altas inversiones en Aethelgard y reliquias de corte · Oro: %d G" % GameState.gold, AstralTheme.GOLD_PALE, AstralTheme.GOLD, 13))
	pat_v.add_child(AstralTheme.label("🏛 Patronazgos e Inversiones Cívicas", "SubLabel", AstralTheme.GOLD))
	for inv in CatalogDB.CIVIC_INVESTMENTS:
		if GameState.age < int(inv.get("min_age", 12)):
			continue
		var iid: String = str(inv["id"])
		var active: bool = GameState.civic_investments.has(iid)
		var price: int = int(inv["price"])
		var ic := AstralTheme.panel("GlowPanel" if active else "CardPanel")
		ic.tooltip_text = str(inv["desc"])
		var ih := AstralTheme.hbox(10)
		ic.add_child(ih)
		var ivign := AstralTheme.vignette_card(str(inv.get("icon", "")), Vector2(64, 52), AstralTheme.GOOD if active else AstralTheme.GOLD_DARK)
		ivign.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ih.add_child(ivign)
		var iinf := AstralTheme.vbox(3)
		iinf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ih.add_child(iinf)
		iinf.add_child(AstralTheme.label(str(inv["name"]), "SubLabel", AstralTheme.GOOD if active else AstralTheme.GOLD_PALE, true))
		iinf.add_child(AstralTheme.label(str(inv["desc"]), "CaptionLabel", AstralTheme.IVORY, true))
		var ib := AstralTheme.button(AstralTheme.G_CHECK + " Activo" if active else "Financiar (%d G)" % price, "PrimaryButton" if (not active and GameState.gold >= price) else "")
		ib.custom_minimum_size = Vector2(154, 42)
		ib.disabled = active or GameState.gold < price
		ib.pressed.connect(func() -> void:
			var r: Dictionary = GameState.invest_civic(iid)
			AstralAudio.play_triumph() if bool(r.get("ok", false)) else AstralAudio.play_warn()
			toast.emit(str(r.get("msg", "")), "good" if bool(r.get("ok", false)) else "warn")
			state_changed.emit()
			refresh())
		ih.add_child(ib)
		pat_v.add_child(ic)
	pat_v.add_child(AstralTheme.separator())
	pat_v.add_child(AstralTheme.label("✦ Joyería e Insignias de Corte", "SubLabel", AstralTheme.GOLD))
	_build_equipment_shop_list(pat_v, "palacio")

	tabs.current_tab = clampi(int(_facility_tab_by_district.get("palacio", 0)), 0, tabs.get_tab_count() - 1)
	tabs.tab_changed.connect(func(idx: int) -> void:
		_facility_tab_by_district["palacio"] = idx)

func _build_anfiteatro_facility() -> void:
	var host := _make_facility_scroll()
	var choir_p := AstralTheme.panel("GlowPanel")
	host.add_child(choir_p)
	var ch := AstralTheme.hbox(10)
	choir_p.add_child(ch)
	var cv := AstralTheme.vbox(2)
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ch.add_child(cv)
	cv.add_child(AstralTheme.label("❀ ENSAYO CORAL DEL ANFITEATRO", "SubLabel", AstralTheme.GOLD))
	cv.add_child(AstralTheme.label("Minijuego de armonización en 3 compases (+Gracia / -Estrés).", "CaptionLabel", AstralTheme.MUTED, true))
	var b_mg := AstralTheme.button(
		"✓ Ensayo hecho" if TurnExecutor.school_minigame_used_this_bimester else "❀ Armonizar",
		"PrimaryButton"
	)
	b_mg.custom_minimum_size = Vector2(160, 42)
	b_mg.disabled = TurnExecutor.school_minigame_used_this_bimester
	b_mg.pressed.connect(func() -> void:
		festival_minigame_requested.emit("rhythm", "ANFITEATRO: ARMONIZACIÓN CORAL"))
	ch.add_child(b_mg)

	var fest_p := AstralTheme.panel("CardPanel")
	host.add_child(fest_p)
	var fv := AstralTheme.vbox(8)
	fest_p.add_child(fv)
	var is_open: bool = TimeManager.is_festival_bimester()
	var can_join: bool = is_open and not ExplorationCombat.festival_entered_this_year
	fv.add_child(AstralTheme.label("☀ GRAN FESTIVAL DE LAS CONSTELACIONES", "HeadingLabel", AstralTheme.GOLD))

	if not _fest_result.is_empty():
		var res_card := AstralTheme.panel("GlowPanel")
		var rv := AstralTheme.vbox(4)
		res_card.add_child(rv)
		rv.add_child(AstralTheme.label(str(_fest_result.get("title", "")), "SubLabel", AstralTheme.GOOD if bool(_fest_result.get("won", false)) else AstralTheme.GOLD_PALE, true))
		rv.add_child(AstralTheme.rich(str(_fest_result.get("summary", ""))))
		fv.add_child(res_card)

	var fm: Dictionary = ExplorationCombat.festival_match
	if not fm.is_empty() and not bool(fm.get("finished", false)):
		var rbox := AstralTheme.panel("GlowPanel")
		var rrv := AstralTheme.vbox(6)
		rbox.add_child(rrv)
		var rnd: int = int(fm.get("round", 1))
		rrv.add_child(AstralTheme.label("%s — Asalto %d / 3" % [str(fm["name"]), rnd], "SubLabel", AstralTheme.GOLD))
		rrv.add_child(AstralTheme.label("Marcador: %s %d  vs  %s %d" % [
			GameState.daughter_name, int(fm["player_score"]), str(fm["rival_name"]), int(fm["rival_score"])
		], "CaptionLabel", AstralTheme.TURQ))
		rrv.add_child(AstralTheme.rich("\n".join(fm.get("log", []))))
		var hint_r2: String = "  (¡Asalto 2 incluye prueba escénica interactiva!)" if rnd == 2 else ""
		rrv.add_child(AstralTheme.label("Elige tu táctica para este asalto:" + hint_r2, "CaptionLabel", AstralTheme.GOLD_PALE, true))
		var brow := AstralTheme.hbox(8)
		rrv.add_child(brow)
		for opt in [
			{"id": "precision", "lbl": "✦ Ejecución Serena"},
			{"id": "bravado", "lbl": "⚔ Gambito Audaz"},
			{"id": "harmony", "lbl": "❀ Cadencia (-3 Estrés)"}
		]:
			var tid: String = str(opt["id"])
			var tb := AstralTheme.button(str(opt["lbl"]), "PrimaryButton" if rnd == 2 else "TabLikeButton")
			tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tb.pressed.connect(func() -> void: _play_festival_round_ui(tid, str(fm.get("id", "")), rnd))
			brow.add_child(tb)
		fv.add_child(rbox)
		return

	var b_msg: String = "¡El Coliseo abre sus puertas este Bimestre 4!" if can_join else ("Ya competiste en el Festival de este año." if ExplorationCombat.festival_entered_this_year else "Se celebra cada año en el 4º Bimestre (Otoño).")
	fv.add_child(AstralTheme.label(b_msg, "CaptionLabel", AstralTheme.TURQ if can_join else AstralTheme.MUTED, true))

	for idx in range(ExplorationCombat.FESTIVAL_CONTESTS.size()):
		var c: Dictionary = ExplorationCombat.FESTIVAL_CONTESTS[idx]
		var prev: Dictionary = ExplorationCombat.get_festival_preview(idx)
		var cc := AstralTheme.panel("SunkenPanel")
		var ch2 := AstralTheme.hbox(10)
		cc.add_child(ch2)
		var cv2 := AstralTheme.vbox(2)
		cv2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ch2.add_child(cv2)
		cv2.add_child(AstralTheme.label(str(c["name"]), "CaptionLabel", AstralTheme.GOLD_PALE))
		cv2.add_child(AstralTheme.label("Tu potencia %d vs %s %d" % [int(prev.get("my_total", 0)), str(c["rival_name"]), int(prev.get("target_score", 0))], "CaptionLabel", AstralTheme.IVORY, true))
		var bc := AstralTheme.button("Competir" if can_join else "Bimestre 4", "PrimaryButton" if can_join else "")
		bc.custom_minimum_size = Vector2(118, 40)
		bc.disabled = not can_join
		var ci: int = idx
		bc.pressed.connect(func() -> void:
			var r: Dictionary = ExplorationCombat.start_festival_match(ci)
			if bool(r.get("ok", false)):
				AstralAudio.play_ui()
				refresh()
			else:
				AstralAudio.play_warn()
				toast.emit(str(r.get("msg", "")), "warn"))
		ch2.add_child(bc)
		fv.add_child(cc)

func _play_festival_round_ui(tactic_id: String, contest_id: String, rnd: int) -> void:
	if rnd == 2 and DisplayServer.get_name() != "headless":
		_pending_fest_args = {"tactic": tactic_id}
		var mode: String = "fencing" if contest_id in ["contest_blades", "contest_clockwork"] else "rhythm"
		var ttl: String = "FESTIVAL ASALTO 2: DUELO DE ACERO" if mode == "fencing" else "FESTIVAL ASALTO 2: CÁNTICO ESTELAR"
		festival_minigame_requested.emit(mode, ttl)
		return
	_commit_festival_round(tactic_id, 0)

func notify_minigame_finished(_mode: String, _score: int, pct: float) -> void:
	if not visible:
		return
	if not _pending_fest_args.is_empty():
		var tid: String = str(_pending_fest_args.get("tactic", "precision"))
		_pending_fest_args.clear()
		var bonus: int = int(round(clampf(pct, 0.0, 1.0) * 60.0))
		_commit_festival_round(tid, bonus)
	else:
		state_changed.emit()
		refresh()

func _commit_festival_round(tactic_id: String, minigame_bonus: int) -> void:
	var r: Dictionary = ExplorationCombat.play_festival_round(tactic_id, "", false, minigame_bonus)
	if not bool(r.get("ok", false)):
		AstralAudio.play_warn()
		toast.emit(str(r.get("msg", "")), "warn")
		return
	if bool(r.get("finished", false)):
		_fest_result = r
		AstralAudio.play_triumph() if bool(r.get("won", false)) else AstralAudio.play_confirm()
		speak.emit("Coliseo de las Constelaciones", str(r.get("title", "")))
	else:
		AstralAudio.play_ui()
	state_changed.emit()
	refresh()

func _build_espejo_facility() -> void:
	var host := _make_facility_scroll()
	var p := AstralTheme.panel("CardPanel")
	host.add_child(p)
	var v := AstralTheme.vbox(8)
	p.add_child(v)
	var tier: int = GameState.get_secret_tier()
	v.add_child(AstralTheme.label("☾ SANTUARIO DEL ESPEJO LUNAR", "HeadingLabel", AstralTheme.AMETHYST))
	var mirror_txt: String = (
		"Las aguas tranquilas reflejan la sombra verdadera tras el Sello Estelar y el nombre de Nyx-Aethel." if tier >= 2 else (
		"A la luz de la luna menguante, el estanque susurra respuestas imposibles de hallar en la Torre." if tier == 1 else
		"Aguas heladas sin fondo visible. Los ciudadanos arrojan pétalos pidiendo serenidad ante el cielo."
	))
	v.add_child(AstralTheme.label(mirror_txt, "", AstralTheme.IVORY, true))
	v.add_child(AstralTheme.label("%s actual: %d  ·  %s: %d%%" % [
		GameState.get_stat_label("abyssal_sync"), GameState.abyssal_sync,
		GameState.get_stat_label("seal_integrity"), GameState.seal_integrity
	], "CaptionLabel", AstralTheme.TURQ))

func _make_gift_buy_row(g: Dictionary) -> PanelContainer:
	var gid: String = str(g["id"])
	var price: int = int(g.get("price", 50))
	var owned: int = GameState.get_gift_count(gid)
	var card := AstralTheme.panel("CardPanel")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(210, 122)
	card.tooltip_text = str(g["desc"])
	var v := AstralTheme.vbox(6)
	card.add_child(v)
	var r := AstralTheme.hbox(8)
	v.add_child(r)
	var seal := _GiftWaxSeal.new(gid)
	seal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.add_child(seal)
	var iv := AstralTheme.vbox(2)
	iv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(iv)
	var top_g := AstralTheme.hbox(6)
	iv.add_child(top_g)
	var nm := AstralTheme.label(str(g["name"]), "CaptionLabel", AstralTheme.GOLD_PALE, true)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_g.add_child(nm)
	if owned > 0:
		top_g.add_child(AstralTheme.chip("×%d" % owned, AstralTheme.TURQ, null, 11))
	iv.add_child(AstralTheme.label(str(g["desc"]), "CaptionLabel", AstralTheme.MUTED, true))
	var b := AstralTheme.button("Comprar (%d G)" % price, "PrimaryButton" if GameState.gold >= price else "")
	b.custom_minimum_size.y = 36
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.disabled = GameState.gold < price
	b.pressed.connect(func() -> void:
		var res: Dictionary = GameState.buy_gift(gid, price)
		AstralAudio.play_confirm() if res.get("ok", false) else AstralAudio.play_warn()
		toast.emit("%s (%d G)" % [str(g["name"]), price], "good" if res.get("ok", false) else "warn")
		state_changed.emit()
		refresh())
	v.add_child(b)
	return card
