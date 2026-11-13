extends BaseWindow
class_name HearthWindow

## Chimenea y Hogar (Fase 3.4 y 3.5): charla nocturna con Renpet, régimen de dieta y mejoras de la mansión.

const FACILITIES: Array[Dictionary] = [
	{"id": "library", "name": "Bóveda Estelar", "desc": "Sala de estudio. +4 por nivel a las ganancias principales de la Torre del Astrolabio."},
	{"id": "armory", "name": "Patio de Lanzas", "desc": "Campo de práctica. +4 por nivel en la Academia de Armas y la Escolta de Caravanas."},
	{"id": "conservatory", "name": "Salón de Lotos y Música", "desc": "+4 por nivel en Conservatorio, Anfiteatro y reposo en casa, y alivia 3 de Estrés por nivel cada bimestre."},
	{"id": "crucible", "name": "Cámara del Crisol", "desc": "Taller del Horno Astral. Cada nivel reduce 2 la Saturación generada, acelera su disipación, abarata la purificación y suma +4 en la Relojería Real."}
]
const MAX_LEVEL: int = 5
const UPGRADE_BASE_COST: int = 300

const ATTITUDE_ORDER: Array[String] = ["warm", "strict", "curious", "protective"]
const ATTITUDE_HINT: Dictionary = {
	"warm": "Consuela y fortalece el vínculo.",
	"strict": "Disciplina y templanza.",
	"curious": "Investiga y profundiza.",
	"protective": "Cuida y pone límites."
}

var _tabs: TabContainer
var _chat_box: VBoxContainer
var _diet_box: VBoxContainer
var _estate_box: VBoxContainer
var _selected_topic: String = ""
var _last_result: String = ""

func _ready() -> void:
	setup("Chimenea y Hogar", false)

func build() -> void:
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_tabs)
	_chat_box = add_tab(_tabs, "  Charla en la Chimenea  ")
	_diet_box = add_tab(_tabs, "  Mesa y Dieta  ")
	_estate_box = add_tab(_tabs, "  Mejoras de la Mansión  ")

func refresh() -> void:
	if _tabs == null:
		return
	_refresh_chat()
	_refresh_diet()
	_refresh_estate()

# ------------------------------------------------------------------------------
# CHARLA
# ------------------------------------------------------------------------------
func _refresh_chat() -> void:
	clear(_chat_box)
	var greet := AstralTheme.panel("GlowPanel")
	var gv := AstralTheme.vbox(4)
	greet.add_child(gv)
	gv.add_child(AstralTheme.label("%s dice:" % GameState.daughter_name, "SubLabel"))
	gv.add_child(AstralTheme.label(GameState.get_dynamic_manor_greeting(), "", AstralTheme.IVORY, true))
	_chat_box.add_child(greet)

	if _last_result != "":
		var res := AstralTheme.panel("CardPanel")
		res.add_child(AstralTheme.rich(_last_result))
		_chat_box.add_child(res)

	if Chronicle.chatted_this_bimester:
		_chat_box.add_child(AstralTheme.label("Ya compartieron la velada de este bimestre. La próxima charla será después del siguiente turno.", "CaptionLabel", AstralTheme.MUTED, true))
		return

	if _selected_topic == "":
		_chat_box.add_child(AstralTheme.label("¿De qué quieres hablar con ella esta noche? (una charla por bimestre)", "HeadingLabel", AstralTheme.GOLD, true))
		for t in Chronicle.get_fireplace_topics():
			var b := AstralTheme.button("%s  %s" % [AstralTheme.G_FLOWER, t["title"]], "")
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.custom_minimum_size.y = 50
			var tid: String = t["id"]
			b.pressed.connect(func() -> void:
				_selected_topic = tid
				_last_result = ""
				_refresh_chat())
			_chat_box.add_child(b)
		return

	var topic: Dictionary = FireplaceTopics.get_topic(_selected_topic)
	var tc := AstralTheme.panel("CardPanel")
	var tv := AstralTheme.vbox(6)
	tc.add_child(tv)
	tv.add_child(AstralTheme.label(str(topic["title"]), "SubLabel"))
	tv.add_child(AstralTheme.label(str(topic["prompt"]), "", AstralTheme.IVORY, true))
	_chat_box.add_child(tc)
	_chat_box.add_child(AstralTheme.label("¿Con qué actitud le respondes?", "HeadingLabel", AstralTheme.GOLD, true))
	for att in ATTITUDE_ORDER:
		var st: Dictionary = topic["stances"][att]
		var b := AstralTheme.button("%s  %s\n%s" % [AstralTheme.G_STAR2, FireplaceTopics.ATTITUDES[att], AstralTheme.G_STAR2 + " " + str(ATTITUDE_HINT[att])], "")
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 64
		b.tooltip_text = str(st["father"])
		var a_key: String = att
		b.pressed.connect(func() -> void: _apply_stance(topic, a_key))
		_chat_box.add_child(b)
	var back := AstralTheme.button("Elegir otro tema", "TabLikeButton")
	back.pressed.connect(func() -> void:
		_selected_topic = ""
		_refresh_chat())
	_chat_box.add_child(back)

func _apply_stance(topic: Dictionary, att: String) -> void:
	var st: Dictionary = topic["stances"][att]
	var labels: Array[String] = []
	GameState.begin_batch()
	for k in st["effects"].keys():
		var applied: int = GameState.modify_stat(k, int(st["effects"][k]))
		if applied != 0:
			labels.append(AstralTheme.colored("%s %s" % [GameState.get_stat_label(k), AstralTheme.signed(applied)], AstralTheme.GOOD if (applied > 0) != (k == "stress" or k == "entropia") else AstralTheme.BAD))
	GameState.end_batch()
	Chronicle.chatted_this_bimester = true
	Chronicle.record_event("chat_" + str(topic["id"]), "Charla en la chimenea: " + str(topic["title"]), str(st["father"]), "family", 2)
	_last_result = "[b]%s[/b] (%s):\n%s\n\n[b]%s[/b]:\n%s\n\n%s" % [
		GameState.father_name, FireplaceTopics.ATTITUDES[att], AstralTheme.colored(str(st["father"]), AstralTheme.GOLD_PALE),
		GameState.daughter_name, AstralTheme.colored(str(st["reply"]), AstralTheme.IVORY), "  ·  ".join(labels)]
	_selected_topic = ""
	speak.emit("%s — junto a la chimenea" % GameState.daughter_name, str(st["reply"]))
	AstralAudio.play_confirm()
	toast.emit("Charla compartida con %s" % GameState.daughter_name, "good")
	refresh()

# ------------------------------------------------------------------------------
# DIETA
# ------------------------------------------------------------------------------
func _refresh_diet() -> void:
	clear(_diet_box)
	_diet_box.add_child(AstralTheme.label("El régimen se paga al cerrar cada bimestre. Si falta oro, la casa cae a Dieta Austera.", "CaptionLabel", AstralTheme.MUTED, true))
	for d in CatalogDB.DIETS:
		var selected: bool = int(GameState.current_diet) == int(d["id"])
		var card := AstralTheme.panel("GlowPanel" if selected else "CardPanel")
		var h := AstralTheme.hbox(14)
		card.add_child(h)
		var icon := AstralTheme.label(str(d["icon"]), "TitleLabel", AstralTheme.GOLD)
		icon.add_theme_font_size_override("font_size", 36)
		icon.custom_minimum_size.x = 50
		h.add_child(icon)
		var mid := AstralTheme.vbox(2)
		mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(mid)
		mid.add_child(AstralTheme.label("%s  (%d G por bimestre)" % [d["name"], int(d["cost"])], "SubLabel"))
		mid.add_child(AstralTheme.label(str(d["desc"]), "", AstralTheme.IVORY, true))
		var btn := AstralTheme.button((AstralTheme.G_CHECK + "  En uso") if selected else "Elegir", "TabLikeButton")
		btn.custom_minimum_size = Vector2(140, 46)
		btn.disabled = selected
		var did: int = int(d["id"])
		btn.pressed.connect(func() -> void:
			GameState.current_diet = did as GameState.DietPlan
			GameState.stats_updated.emit()
			AstralAudio.play_confirm()
			speak.emit("Mesa familiar", "Nuevo régimen: %s." % CatalogDB.get_diet(did)["name"])
			refresh())
		h.add_child(btn)
		_diet_box.add_child(card)

# ------------------------------------------------------------------------------
# MANSIÓN
# ------------------------------------------------------------------------------
func _refresh_estate() -> void:
	clear(_estate_box)
	_estate_box.add_child(AstralTheme.label("Cada mejora cuesta %d G por nivel actual (máximo nivel %d). Tienes %d G." % [UPGRADE_BASE_COST, MAX_LEVEL, GameState.gold], "CaptionLabel", AstralTheme.MUTED, true))
	for f in FACILITIES:
		var lvl: int = int(GameState.estate_levels.get(f["id"], 1))
		var card := AstralTheme.panel("CardPanel")
		var h := AstralTheme.hbox(14)
		card.add_child(h)
		var mid := AstralTheme.vbox(4)
		mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(mid)
		mid.add_child(AstralTheme.label("%s  ·  Nivel %d de %d" % [f["name"], lvl, MAX_LEVEL], "SubLabel"))
		mid.add_child(AstralTheme.label(str(f["desc"]), "", AstralTheme.IVORY, true))
		var pips := AstralTheme.hbox(6)
		for i in range(MAX_LEVEL):
			var pip := ColorRect.new()
			pip.custom_minimum_size = Vector2(34, 8)
			pip.color = AstralTheme.GOLD if i < lvl else Color(1, 1, 1, 0.12)
			pips.add_child(pip)
		mid.add_child(pips)
		var cost: int = UPGRADE_BASE_COST * lvl
		var btn := AstralTheme.button("Mejorar\n%d G" % cost if lvl < MAX_LEVEL else "Nivel máximo", "TabLikeButton")
		btn.custom_minimum_size = Vector2(150, 62)
		btn.disabled = lvl >= MAX_LEVEL or GameState.gold < cost
		if lvl < MAX_LEVEL and GameState.gold < cost:
			btn.tooltip_text = "Necesitas %d G." % cost
		var fid: String = f["id"]
		btn.pressed.connect(func() -> void: _upgrade(fid))
		h.add_child(btn)
		_estate_box.add_child(card)

func _upgrade(fid: String) -> void:
	var lvl: int = int(GameState.estate_levels.get(fid, 1))
	var cost: int = UPGRADE_BASE_COST * lvl
	if lvl >= MAX_LEVEL or not GameState.modify_gold(-cost):
		AstralAudio.play_warn()
		toast.emit("No alcanza el oro para la mejora.", "warn")
		return
	GameState.estate_levels[fid] = lvl + 1
	var fname: String = ""
	for f in FACILITIES:
		if f["id"] == fid:
			fname = f["name"]
	Chronicle.record_event("estate_" + fid, "Mejora de la mansión: " + fname, "%s subió al nivel %d." % [fname, lvl + 1], "family", 2)
	GameState.stats_updated.emit()
	AstralAudio.play_triumph()
	speak.emit("Mansión Solar", "%s ahora es de nivel %d." % [fname, lvl + 1])
	toast.emit("%s → nivel %d" % [fname, lvl + 1], "good")
	refresh()

func reset_view() -> void:
	_selected_topic = ""
	_last_result = ""
