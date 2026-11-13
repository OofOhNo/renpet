extends BaseWindow
class_name StatusSheet

## Ficha de Renpet (Fase 3): atributos, rasgos, sinergias de prestigio, mutaciones, crónica y cartas.

signal open_letter(letter: Dictionary)

const TRAIT_INFO: Array[Dictionary] = [
	{"prefix": "Insomnio de las Estrellas", "desc": "Duerme mal y comete errores, pero a veces oye al cosmos con claridad.", "cond": "Resguardo astral menor a 50% y Estrés mayor a 65."},
	{"prefix": "Ojos de Eclipse", "desc": "Un brillo enigmático asoma en sus pupilas nocturnas.", "cond": "Armonía estelar baja y Eco nocturno elevado."},
	{"prefix": "Rencor del Sarcófago", "desc": "La Entropía supera a su corazón humano.", "cond": "Entropía alta y Anclaje Humano bajo."},
	{"prefix": "Desdén Astral", "desc": "La Entropía supera a su corazón humano.", "cond": "Entropía alta y Anclaje Humano bajo."},
	{"prefix": "Orgullo del Hogar", "desc": "Quiere ser digna de su padre. +20% de eficacia cuando él supervisa su entrenamiento.", "cond": "Afecto mayor a 80 y Anclaje Humano mayor a 70."},
	{"prefix": "Corazón Indómito", "desc": "No retrocede ante nada. Gana los desafíos físicos con valentía.", "cond": "Temple mayor a 450 y Destreza mayor a 450."},
	{"prefix": "Mente de Cristal Frío", "desc": "Brillante y calculadora, pero distante del calor familiar.", "cond": "Erudición mayor a 400 y Afecto menor a 45."},
	{"prefix": "Rosa de Alabastro", "desc": "La favorita de la Corte: su presencia abre puertas y corazones.", "cond": "Gracia y Magnetismo mayores a 400."}
]

class _ConstellationBadge extends Control:
	var kind: String = "trait"
	var lit: bool = false
	var accent: Color = Color("f7e3a1")

	func _init(p_kind: String, p_lit: bool, p_col: Color) -> void:
		kind = p_kind
		lit = p_lit
		accent = p_col
		custom_minimum_size = Vector2(38, 38)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c: Vector2 = size * 0.5
		var r: float = minf(size.x, size.y) * 0.40
		var col: Color = accent if lit else Color(0.45, 0.50, 0.64, 0.55)
		if lit:
			draw_circle(c, r + 3.0, Color(col.r, col.g, col.b, 0.16))
		draw_arc(c, r, 0.0, TAU, 24, Color(col.r, col.g, col.b, 0.68 if lit else 0.30), 1.4, true)
		if kind == "synergy":
			draw_arc(c, r * 0.62, 0.0, TAU, 20, Color(col.r, col.g, col.b, 0.85 if lit else 0.35), 1.2, true)
			for i in range(6):
				var a: float = -PI * 0.5 + float(i) * (TAU / 6.0)
				draw_circle(c + Vector2.from_angle(a) * r, 2.1 if lit else 1.5, col)
			if lit:
				draw_circle(c, 4.2, Color(1.0, 0.96, 0.82, 0.95))
		elif kind == "mutation":
			var pts := PackedVector2Array([
				c + Vector2(0, -r * 0.82), c + Vector2(r * 0.56, 0),
				c + Vector2(0, r * 0.82), c + Vector2(-r * 0.56, 0)
			])
			draw_polygon(pts, [Color(col.r, col.g, col.b, 0.35)])
			draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), col, 1.8, true)
			draw_circle(c, 3.0, Color(0.85, 0.96, 1.0, 0.95))
		else:
			var d: float = r * (0.76 if lit else 0.55)
			draw_line(c + Vector2(-d, 0), c + Vector2(d, 0), col, 1.8 if lit else 1.2, true)
			draw_line(c + Vector2(0, -d), c + Vector2(0, d), col, 1.8 if lit else 1.2, true)
			if lit:
				var d2: float = d * 0.52
				draw_line(c + Vector2(-d2, -d2), c + Vector2(d2, d2), Color(col.r, col.g, col.b, 0.72), 1.2, true)
				draw_line(c + Vector2(-d2, d2), c + Vector2(d2, -d2), Color(col.r, col.g, col.b, 0.72), 1.2, true)
				draw_circle(c, 3.5, Color(1.0, 0.97, 0.86, 1.0))

var _tabs: TabContainer
var _bars: Dictionary = {}   # stat_key -> StatBar
var _soul_section_lbl: Label
var _head_portrait_slot: Control
var _head_title_lbl: Label
var _head_chips: HFlowContainer
var _traits_box: GridContainer
var _synergy_box: GridContainer
var _mut_box: GridContainer
var _letters_box: GridContainer
var _events_box: VBoxContainer

func _ready() -> void:
	setup("Ficha de Renpet", false)

func build() -> void:
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_tabs)

	# ------- Pestaña 1: Atributos -------
	var t1 := add_tab(_tabs, "  Atributos  ")
	var head_card := AstralTheme.panel("GlowPanel")
	var head_h := AstralTheme.hbox(14)
	head_card.add_child(head_h)
	_head_portrait_slot = Control.new()
	_head_portrait_slot.custom_minimum_size = Vector2(72, 86)
	head_h.add_child(_head_portrait_slot)
	var head_v := AstralTheme.vbox(6)
	head_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head_h.add_child(head_v)
	_head_title_lbl = AstralTheme.label("", "SubLabel", AstralTheme.GOLD_PALE, true)
	head_v.add_child(_head_title_lbl)
	_head_chips = HFlowContainer.new()
	_head_chips.add_theme_constant_override("h_separation", 8)
	_head_chips.add_theme_constant_override("v_separation", 6)
	head_v.add_child(_head_chips)
	t1.add_child(head_card)

	var cols := AstralTheme.hbox(16)
	t1.add_child(cols)
	var left := AstralTheme.vbox(12)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var right := AstralTheme.vbox(12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(left)
	cols.add_child(right)

	_section(left, "Esfera Mortal", ["temple", "destreza", "erudicion", "gracia", "magnetismo"], 1200)
	_section(left, "Eje Moral y Espiritual", ["moralidad", "devocion"], 100)
	_section(right, "Esfera Cósmica", ["luminiscencia", "gravedad", "resonancia"], 1200)
	_section(right, "Cosmos Interior", ["entropia", "astral_saturation"], 100)
	_section(right, "Estado Vital y Familia", ["stress", "affection", "father_reputation", "seal_investigation", "court_suspicion"], 100)
	_soul_section_lbl = _section(right, "Ecos de tu Naturaleza", ["human_anchor", "seal_integrity", "abyssal_sync"], 100)

	# ------- Pestaña 2: Rasgos y Sinergias -------
	var t2 := add_tab(_tabs, "  Rasgos y Sinergias  ")
	t2.add_child(AstralTheme.label("Rasgos activos (máx. 4 simultáneos)", "HeadingLabel"))
	_traits_box = GridContainer.new()
	_traits_box.columns = 2
	_traits_box.add_theme_constant_override("h_separation", 10)
	_traits_box.add_theme_constant_override("v_separation", 8)
	t2.add_child(_traits_box)
	t2.add_child(AstralTheme.separator())
	t2.add_child(AstralTheme.label("Sinergias de Prestigio", "HeadingLabel"))
	_synergy_box = GridContainer.new()
	_synergy_box.columns = 2
	_synergy_box.add_theme_constant_override("h_separation", 10)
	_synergy_box.add_theme_constant_override("v_separation", 8)
	t2.add_child(_synergy_box)
	t2.add_child(AstralTheme.separator())
	t2.add_child(AstralTheme.label("Mutaciones astrales", "HeadingLabel"))
	_mut_box = GridContainer.new()
	_mut_box.columns = 2
	_mut_box.add_theme_constant_override("h_separation", 10)
	_mut_box.add_theme_constant_override("v_separation", 8)
	t2.add_child(_mut_box)

	# ------- Pestaña 3: Crónica y Cartas -------
	var t3 := add_tab(_tabs, "  Crónica y Cartas  ")
	t3.add_child(AstralTheme.label("Cartas del Solsticio", "HeadingLabel"))
	_letters_box = GridContainer.new()
	_letters_box.columns = 2
	_letters_box.add_theme_constant_override("h_separation", 10)
	_letters_box.add_theme_constant_override("v_separation", 8)
	t3.add_child(_letters_box)
	t3.add_child(AstralTheme.separator())
	t3.add_child(AstralTheme.label("Hitos recientes", "HeadingLabel"))
	_events_box = AstralTheme.vbox(6)
	t3.add_child(_events_box)

func _section(parent: VBoxContainer, title: String, keys: Array, max_v: int) -> Label:
	var card := AstralTheme.panel("CardPanel")
	parent.add_child(card)
	var v := AstralTheme.vbox(6)
	card.add_child(v)
	var hdr := AstralTheme.label(title, "SubLabel")
	v.add_child(hdr)
	for k in keys:
		var bar := StatBar.new()
		bar.setup(GameState.get_stat_label(k), k, 0, max_v, AstralTheme.STAT_COLORS.get(k, AstralTheme.TURQ), GameState.get_stat_tooltip(k), 156)
		v.add_child(bar)
		_bars[k] = bar
	return hdr

func refresh() -> void:
	if _tabs == null:
		return
	if title_label != null:
		title_label.text = "Ficha de %s" % GameState.daughter_name
	var tier: int = GameState.get_secret_tier()
	if _soul_section_lbl != null:
		_soul_section_lbl.text = "Ecos de tu Naturaleza" if tier == 0 else ("Armonía y Sombra" if tier == 1 else "Los 3 Medidores del Alma")
	for k in _bars.keys():
		var bar := _bars[k] as StatBar
		bar.set_title(GameState.get_stat_label(k))
		bar.set_tooltip(GameState.get_stat_tooltip(k))
		bar.set_value(GameState.get_stat(k))
	clear(_head_portrait_slot)
	_head_portrait_slot.add_child(AstralTheme.icon_box(GameState.get_active_portrait_path(), Vector2(72, 86), Color.WHITE, "GlowPanel"))
	_head_title_lbl.text = "%s, %d años  ·  Padre: %s (%s)" % [
		GameState.daughter_name, GameState.age, GameState.father_name, GameState.get_archetype_title()
	]
	clear(_head_chips)
	var voc: Dictionary = EndingEvaluator.get_projected_vocation()
	var runner_txt: String = str(voc.get("runner_up_name", ""))
	var outfit_name: String = str(CatalogDB.get_outfit(GameState.equipped_outfit).get("name", "Túnica Inicial"))
	var cards_cnt: int = GameState.get_equipped_memory_cards().size()
	var c_state := AstralTheme.chip(GameState.get_metaphysical_state_title(), AstralTheme.TURQ, null, 13)
	_head_chips.add_child(c_state)
	var c_mood := AstralTheme.chip("Humor: %s" % str(GameState.get_mood_summary()["short_tag"]), AstralTheme.AMETHYST, null, 13)
	_head_chips.add_child(c_mood)
	var c_outfit := AstralTheme.chip(outfit_name, AstralTheme.GOLD, null, 13)
	_head_chips.add_child(c_outfit)
	var c_deck := AstralTheme.chip("Mazo %d/4" % cards_cnt, AstralTheme.SKY, null, 13)
	_head_chips.add_child(c_deck)
	if GameState.equipped_weapon != "":
		var w_name: String = str(CatalogDB.get_equipment(GameState.equipped_weapon).get("name", GameState.equipped_weapon))
		_head_chips.add_child(AstralTheme.chip("Arma: %s" % w_name, AstralTheme.EMBER, null, 13))
	if GameState.equipped_accessory != "":
		var a_name: String = str(CatalogDB.get_equipment(GameState.equipped_accessory).get("name", GameState.equipped_accessory))
		_head_chips.add_child(AstralTheme.chip("Reliquia: %s" % a_name, AstralTheme.ROSE, null, 13))
	if not GameState.owned_tomes.is_empty() or not GameState.civic_investments.is_empty():
		_head_chips.add_child(AstralTheme.chip("Tratados: %d · Patronazgos: %d" % [GameState.owned_tomes.size(), GameState.civic_investments.size()], AstralTheme.GOOD, null, 13))
	var c_voc := AstralTheme.chip("%s %s" % [AstralTheme.G_STAR, str(voc.get("name", ""))], AstralTheme.GOLD_PALE, AstralTheme.GOLD, 13)
	c_voc.tooltip_text = "Vocación proyectada (%s)" % str(voc.get("tag", ""))
	_head_chips.add_child(c_voc)
	if runner_txt != "" and runner_txt != str(voc.get("name", "")):
		var c_run := AstralTheme.chip("2.ª vía: %s" % runner_txt, AstralTheme.MUTED, null, 13)
		_head_chips.add_child(c_run)
	_refresh_traits()
	_refresh_synergies()
	_refresh_mutations()
	_refresh_chronicle()

func _trait_accent(pref: String) -> Color:
	if pref == "Orgullo del Hogar":
		return AstralTheme.ROSE
	if pref == "Corazón Indómito":
		return AstralTheme.EMBER
	if pref == "Rosa de Alabastro":
		return AstralTheme.GOLD_PALE
	if pref == "Mente de Cristal Frío":
		return AstralTheme.SKY
	return AstralTheme.AMETHYST

func _refresh_traits() -> void:
	clear(_traits_box)
	var tier: int = GameState.get_secret_tier()
	for info in TRAIT_INFO:
		var pref: String = str(info["prefix"])
		if pref == "Rencor del Sarcófago" and tier < 2:
			continue
		if pref == "Desdén Astral" and tier >= 2:
			continue
		var active_name: String = ""
		for t in GameState.active_traits:
			if t.begins_with(pref):
				active_name = t
		var is_active: bool = active_name != ""
		var card := AstralTheme.panel("GlowPanel" if is_active else "SunkenPanel")
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.tooltip_text = "%s\nRequisito: %s" % [str(info["desc"]), str(info["cond"])]
		var h := AstralTheme.hbox(10)
		card.add_child(h)
		h.add_child(_ConstellationBadge.new("trait", is_active, _trait_accent(pref)))
		var v := AstralTheme.vbox(3)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(v)
		var top_row := AstralTheme.hbox(6)
		v.add_child(top_row)
		var title_lbl := AstralTheme.label(active_name if is_active else pref, "SubLabel" if is_active else "", AstralTheme.GOLD_PALE if is_active else AstralTheme.MUTED, true)
		title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_row.add_child(title_lbl)
		top_row.add_child(AstralTheme.chip("%s Activo" % AstralTheme.G_CHECK if is_active else "Latente", AstralTheme.GOOD if is_active else AstralTheme.MUTED, null, 12))
		var sub_txt: String = str(info["desc"]) if is_active else str(info["cond"])
		v.add_child(AstralTheme.label(sub_txt, "CaptionLabel", AstralTheme.IVORY if is_active else AstralTheme.MUTED, true))
		_traits_box.add_child(card)

func _refresh_synergies() -> void:
	clear(_synergy_box)
	for syn in CatalogDB.PRESTIGE_SYNERGIES:
		var unlocked: bool = GameState.unlocked_synergies.has(syn["id"])
		var card := AstralTheme.panel("GlowPanel" if unlocked else "SunkenPanel")
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.tooltip_text = "Premio: %s" % str(syn["bonus_desc"])
		var h := AstralTheme.hbox(10)
		card.add_child(h)
		h.add_child(_ConstellationBadge.new("synergy", unlocked, AstralTheme.GOLD_PALE))
		var v := AstralTheme.vbox(4)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		if unlocked:
			var top_row := AstralTheme.hbox(6)
			v.add_child(top_row)
			var tl := AstralTheme.label(str(syn["title"]), "SubLabel", AstralTheme.GOLD_PALE, true)
			tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			top_row.add_child(tl)
			top_row.add_child(AstralTheme.chip(AstralTheme.G_FLEUR + " Lograda", AstralTheme.GOLD_PALE, AstralTheme.GOLD, 12))
			v.add_child(AstralTheme.label(str(syn["bonus_desc"]), "CaptionLabel", AstralTheme.IVORY, true))
		else:
			v.add_child(AstralTheme.label(str(syn["title"]), "", AstralTheme.MUTED, true))
			var ba := StatBar.new()
			ba.setup(GameState.get_stat_label(syn["stat_a"]), syn["stat_a"], 0, int(syn["req_a"]), AstralTheme.STAT_COLORS.get(syn["stat_a"], AstralTheme.TURQ), "", 115)
			ba.show_max = true
			v.add_child(ba)
			ba.set_value(GameState.get_stat(syn["stat_a"]), false)
			var bb := StatBar.new()
			bb.setup(GameState.get_stat_label(syn["stat_b"]), syn["stat_b"], 0, int(syn["req_b"]), AstralTheme.STAT_COLORS.get(syn["stat_b"], AstralTheme.TURQ), "", 115)
			bb.show_max = true
			v.add_child(bb)
			bb.set_value(GameState.get_stat(syn["stat_b"]), false)
		_synergy_box.add_child(card)

func _refresh_mutations() -> void:
	clear(_mut_box)
	if GameState.active_mutations.is_empty():
		var empty_c := AstralTheme.chip("Sin reliquias asimiladas en el Crisol Astral", AstralTheme.MUTED, null, 13)
		_mut_box.add_child(empty_c)
		return
	for mid in GameState.active_mutations:
		var m: Dictionary = CatalogDB.get_mutation(mid)
		var card := AstralTheme.panel("CardPanel")
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.tooltip_text = str(m.get("desc", ""))
		var h := AstralTheme.hbox(10)
		card.add_child(h)
		h.add_child(_ConstellationBadge.new("mutation", true, AstralTheme.AMETHYST))
		var v := AstralTheme.vbox(3)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(v)
		v.add_child(AstralTheme.label(str(m.get("name", mid)), "SubLabel", AstralTheme.AMETHYST, true))
		v.add_child(AstralTheme.label(str(m.get("desc", "")), "CaptionLabel", AstralTheme.IVORY, true))
		_mut_box.add_child(card)

func _refresh_chronicle() -> void:
	clear(_letters_box)
	if Chronicle.letters_archive.is_empty():
		_letters_box.add_child(AstralTheme.chip("Sin cartas todavía (Solsticio · Bim. 6)", AstralTheme.MUTED, null, 13))
	for lt in Chronicle.letters_archive:
		var b := AstralTheme.button("%s  %s" % [AstralTheme.G_ENVELOPE, lt["title"]], "")
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var letter: Dictionary = lt
		b.pressed.connect(func() -> void: open_letter.emit(letter))
		_letters_box.add_child(b)
	clear(_events_box)
	var shown: int = 0
	for ev in Chronicle.events_ledger:
		if ev.get("category", "") == "turn":
			continue
		var card := AstralTheme.panel("SunkenPanel")
		card.tooltip_text = str(ev["summary"])
		var h := AstralTheme.hbox(10)
		card.add_child(h)
		h.add_child(AstralTheme.chip("A%d · B%d" % [int(ev["year"]), int(ev["bimester"])], AstralTheme.GOLD_PALE, AstralTheme.GOLD, 12))
		var v := AstralTheme.vbox(2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(AstralTheme.label(str(ev["title"]), "", AstralTheme.IVORY, true))
		v.add_child(AstralTheme.label(str(ev["summary"]), "CaptionLabel", AstralTheme.MUTED, true))
		_events_box.add_child(card)
		shown += 1
		if shown >= 14:
			break
