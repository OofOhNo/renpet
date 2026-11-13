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

var _tabs: TabContainer
var _bars: Dictionary = {}   # stat_key -> StatBar
var _head_rich: RichTextLabel
var _traits_box: VBoxContainer
var _synergy_box: VBoxContainer
var _mut_box: VBoxContainer
var _letters_box: VBoxContainer
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
	_head_rich = AstralTheme.rich()
	head_card.add_child(_head_rich)
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
	_section(right, "Estado Vital y Familia", ["stress", "affection", "father_reputation", "seal_investigation"], 100)
	_section(right, "Los 3 Medidores del Sello", ["human_anchor", "seal_integrity", "abyssal_sync"], 100)

	# ------- Pestaña 2: Rasgos y Sinergias -------
	var t2 := add_tab(_tabs, "  Rasgos y Sinergias  ")
	t2.add_child(AstralTheme.label("Rasgos de personalidad (máximo 4 activos a la vez)", "HeadingLabel"))
	_traits_box = AstralTheme.vbox(8)
	t2.add_child(_traits_box)
	t2.add_child(AstralTheme.separator())
	t2.add_child(AstralTheme.label("Sinergias de Prestigio", "HeadingLabel"))
	_synergy_box = AstralTheme.vbox(8)
	t2.add_child(_synergy_box)
	t2.add_child(AstralTheme.separator())
	t2.add_child(AstralTheme.label("Mutaciones astrales", "HeadingLabel"))
	_mut_box = AstralTheme.vbox(6)
	t2.add_child(_mut_box)

	# ------- Pestaña 3: Crónica y Cartas -------
	var t3 := add_tab(_tabs, "  Crónica y Cartas  ")
	t3.add_child(AstralTheme.label("Cartas del Solsticio", "HeadingLabel"))
	_letters_box = AstralTheme.vbox(8)
	t3.add_child(_letters_box)
	t3.add_child(AstralTheme.separator())
	t3.add_child(AstralTheme.label("Hitos recientes", "HeadingLabel"))
	_events_box = AstralTheme.vbox(8)
	t3.add_child(_events_box)

func _section(parent: VBoxContainer, title: String, keys: Array, max_v: int) -> void:
	var card := AstralTheme.panel("CardPanel")
	parent.add_child(card)
	var v := AstralTheme.vbox(8)
	card.add_child(v)
	v.add_child(AstralTheme.label(title, "SubLabel"))
	for k in keys:
		var bar := StatBar.new()
		bar.setup(GameState.get_stat_label(k), k, 0, max_v, AstralTheme.STAT_COLORS.get(k, AstralTheme.TURQ), str(AstralTheme.STAT_TOOLTIPS.get(k, "")))
		v.add_child(bar)
		_bars[k] = bar

func refresh() -> void:
	if _tabs == null:
		return
	for k in _bars.keys():
		(_bars[k] as StatBar).set_title(GameState.get_stat_label(k))
		(_bars[k] as StatBar).set_value(GameState.get_stat(k))
	_head_rich.text = "[b]%s[/b], %d años   ·   Padre: [b]%s[/b], %s\n%s" % [
		GameState.daughter_name, GameState.age, GameState.father_name, GameState.get_archetype_title(),
		AstralTheme.colored(GameState.get_metaphysical_state_title(), AstralTheme.TURQ)]
	_refresh_traits()
	_refresh_synergies()
	_refresh_mutations()
	_refresh_chronicle()

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
		var card := AstralTheme.panel("GlowPanel" if active_name != "" else "SunkenPanel")
		var v := AstralTheme.vbox(2)
		card.add_child(v)
		if active_name != "":
			v.add_child(AstralTheme.label(AstralTheme.G_STAR + "  " + active_name, "SubLabel"))
			v.add_child(AstralTheme.label(str(info["desc"]), "", AstralTheme.IVORY, true))
		else:
			v.add_child(AstralTheme.label(str(info["prefix"]), "", AstralTheme.MUTED))
			v.add_child(AstralTheme.label("Requiere: " + str(info["cond"]), "CaptionLabel", AstralTheme.MUTED, true))
		_traits_box.add_child(card)

func _refresh_synergies() -> void:
	clear(_synergy_box)
	for syn in CatalogDB.PRESTIGE_SYNERGIES:
		var unlocked: bool = GameState.unlocked_synergies.has(syn["id"])
		var card := AstralTheme.panel("GlowPanel" if unlocked else "SunkenPanel")
		var v := AstralTheme.vbox(4)
		card.add_child(v)
		if unlocked:
			v.add_child(AstralTheme.label("%s  %s" % [AstralTheme.G_FLEUR, syn["title"]], "SubLabel", AstralTheme.GOLD_PALE, true))
			v.add_child(AstralTheme.label(str(syn["bonus_desc"]), "", AstralTheme.IVORY, true))
		else:
			v.add_child(AstralTheme.label(str(syn["title"]), "", AstralTheme.MUTED))
			var ba := StatBar.new()
			ba.setup(GameState.get_stat_label(syn["stat_a"]), syn["stat_a"], 0, int(syn["req_a"]), AstralTheme.STAT_COLORS.get(syn["stat_a"], AstralTheme.TURQ))
			ba.show_max = true
			v.add_child(ba)
			ba.set_value(GameState.get_stat(syn["stat_a"]), false)
			var bb := StatBar.new()
			bb.setup(GameState.get_stat_label(syn["stat_b"]), syn["stat_b"], 0, int(syn["req_b"]), AstralTheme.STAT_COLORS.get(syn["stat_b"], AstralTheme.TURQ))
			bb.show_max = true
			v.add_child(bb)
			bb.set_value(GameState.get_stat(syn["stat_b"]), false)
			v.add_child(AstralTheme.label("Premio: " + str(syn["bonus_desc"]), "CaptionLabel", AstralTheme.MUTED, true))
		_synergy_box.add_child(card)

func _refresh_mutations() -> void:
	clear(_mut_box)
	if GameState.active_mutations.is_empty():
		_mut_box.add_child(AstralTheme.label("Todavía no ha asimilado ninguna reliquia en el Crisol Astral.", "CaptionLabel", AstralTheme.MUTED, true))
		return
	for mid in GameState.active_mutations:
		var m: Dictionary = CatalogDB.get_mutation(mid)
		var card := AstralTheme.panel("CardPanel")
		var v := AstralTheme.vbox(2)
		card.add_child(v)
		v.add_child(AstralTheme.label("%s  %s" % [AstralTheme.G_BOLT, m.get("name", mid)], "SubLabel", AstralTheme.AMETHYST, true))
		v.add_child(AstralTheme.label(str(m.get("desc", "")), "", AstralTheme.IVORY, true))
		_mut_box.add_child(card)

func _refresh_chronicle() -> void:
	clear(_letters_box)
	if Chronicle.letters_archive.is_empty():
		_letters_box.add_child(AstralTheme.label("Aún no hay cartas. Renpet escribe una cada noche de Solsticio (Bimestre 6).", "CaptionLabel", AstralTheme.MUTED, true))
	for lt in Chronicle.letters_archive:
		var b := AstralTheme.button("%s  %s" % [AstralTheme.G_ENVELOPE, lt["title"]], "")
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var letter: Dictionary = lt
		b.pressed.connect(func() -> void: open_letter.emit(letter))
		_letters_box.add_child(b)
	clear(_events_box)
	var shown: int = 0
	for ev in Chronicle.events_ledger:
		if ev.get("category", "") == "turn":
			continue
		var card := AstralTheme.panel("SunkenPanel")
		var v := AstralTheme.vbox(2)
		card.add_child(v)
		v.add_child(AstralTheme.label("Año %d · Bim. %d  —  %s" % [int(ev["year"]), int(ev["bimester"]), ev["title"]], "", AstralTheme.GOLD_PALE))
		v.add_child(AstralTheme.label(str(ev["summary"]), "CaptionLabel", AstralTheme.MUTED, true))
		_events_box.add_child(card)
		shown += 1
		if shown >= 14:
			break
