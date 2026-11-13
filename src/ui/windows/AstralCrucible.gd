extends BaseWindow
class_name AstralCrucible

## Crisol Astral (Fase 5): inventario cósmico, vista previa de la fusión, bazar de Zahir, destilación y purificación.

var _sat_bar: StatBar
var _sat_note: Label
var _inv_box: VBoxContainer
var _detail_box: VBoxContainer
var _shop_box: VBoxContainer
var _mut_label: RichTextLabel
var _selected: String = ""
var _confirm: ConfirmationDialog

func _ready() -> void:
	setup("Crisol Astral — Horno de Fusión")
	_confirm = ConfirmationDialog.new()
	_confirm.title = "Sobrecarga Astral"
	_confirm.ok_button_text = "Fundir de todos modos"
	_confirm.cancel_button_text = "Cancelar"
	_confirm.theme = AstralTheme.get_theme()
	add_child(_confirm)

func build() -> void:
	var top := AstralTheme.panel("GlowPanel")
	var tv := AstralTheme.vbox(6)
	top.add_child(tv)
	_sat_bar = StatBar.new()
	_sat_bar.setup("Saturación Astral", "astral_saturation", 0, 100, AstralTheme.STAT_COLORS["astral_saturation"], str(AstralTheme.STAT_TOOLTIPS["astral_saturation"]), 190)
	tv.add_child(_sat_bar)
	_sat_note = AstralTheme.label("", "CaptionLabel", AstralTheme.MUTED, true)
	tv.add_child(_sat_note)
	_mut_label = AstralTheme.rich()
	tv.add_child(_mut_label)
	body.add_child(top)

	var cols := AstralTheme.hbox(16)
	body.add_child(cols)
	var left := AstralTheme.vbox(8)
	left.custom_minimum_size.x = 380
	cols.add_child(left)
	left.add_child(AstralTheme.label("Inventario cósmico", "HeadingLabel"))
	_inv_box = AstralTheme.vbox(8)
	left.add_child(_inv_box)

	_detail_box = AstralTheme.vbox(10)
	_detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(_detail_box)

	body.add_child(AstralTheme.separator())
	body.add_child(AstralTheme.label("Bazar de Medianoche y taller", "HeadingLabel"))
	_shop_box = AstralTheme.vbox(8)
	body.add_child(_shop_box)

func refresh() -> void:
	if _sat_bar == null:
		return
	_sat_bar.set_value(GameState.astral_saturation)
	var eff: float = CrucibleManager.get_efficiency()
	var seal_lbl: String = GameState.get_stat_label("seal_integrity")
	if GameState.astral_saturation >= CrucibleManager.SATURATION_HARD_LIMIT:
		_sat_note.text = "Crítica: absorbes solo el 40%% y %s sufre daño extra." % seal_lbl
		_sat_note.add_theme_color_override("font_color", AstralTheme.BAD)
	elif GameState.astral_saturation >= CrucibleManager.SATURATION_SOFT_LIMIT:
		_sat_note.text = "Alta: absorbes solo el 70% de los atributos."
		_sat_note.add_theme_color_override("font_color", AstralTheme.EMBER)
	else:
		_sat_note.text = "Estable: el cuerpo absorbe el 100%% de las reliquias. Sobre 60 el rendimiento cae. Nivel del Crisol: %d." % CrucibleManager.get_crucible_level()
		_sat_note.add_theme_color_override("font_color", AstralTheme.MUTED)
	if GameState.active_mutations.is_empty():
		_mut_label.text = AstralTheme.colored("Mutaciones activas: ninguna todavía.", AstralTheme.MUTED)
	else:
		var names: Array[String] = []
		for m in GameState.active_mutations:
			names.append(CatalogDB.get_mutation_name(m))
		_mut_label.text = "Mutaciones activas: " + AstralTheme.colored(", ".join(names), AstralTheme.AMETHYST)
	_refresh_inventory()
	_refresh_detail()
	_refresh_shop()

func _refresh_inventory() -> void:
	clear(_inv_box)
	var any: bool = false
	for m in CatalogDB.COSMIC_MATERIALS:
		var count: int = int(GameState.materials_inventory.get(m["id"], 0))
		var b := AstralTheme.button("%s   ×%d" % [m["name"], count], "TabLikeButton")
		b.toggle_mode = true
		b.button_pressed = (_selected == m["id"])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 46
		b.disabled = count <= 0
		b.tooltip_text = "%s\nDónde conseguirlo: %s (o en el Bazar de Medianoche / Destilación)." % [str(m.get("origin", "")), "Bazar de Medianoche o Destilación" if int(m.get("exclusive_rep", 0)) == 0 else "Bazar con Reputación Paterna >= %d" % int(m.get("exclusive_rep", 0))]
		var mid: String = m["id"]
		b.pressed.connect(func() -> void:
			AstralAudio.play_ui()
			_selected = mid
			refresh())
		_inv_box.add_child(b)
		if count > 0:
			any = true
	if not any:
		_inv_box.add_child(AstralTheme.label("El inventario está vacío. Compra en el bazar, destila una reliquia o encuentra materiales en oficios peligrosos.", "CaptionLabel", AstralTheme.MUTED, true))
	if _selected != "" and int(GameState.materials_inventory.get(_selected, 0)) <= 0:
		_selected = ""

func _refresh_detail() -> void:
	clear(_detail_box)
	if _selected == "":
		var card := AstralTheme.panel("SunkenPanel")
		card.add_child(AstralTheme.label("Elige un material del inventario para ver la vista previa de la fusión: atributos, efecto sobre su armonía estelar y Saturación resultante.", "", AstralTheme.MUTED, true))
		_detail_box.add_child(card)
		return
	var p: Dictionary = CrucibleManager.preview(_selected)
	if not p.get("ok", false):
		return
	var mat: Dictionary = p["material"]
	var card := AstralTheme.panel("CardPanel")
	var v := AstralTheme.vbox(8)
	card.add_child(v)
	v.add_child(AstralTheme.label(str(mat["name"]), "HeadingLabel"))
	v.add_child(AstralTheme.label("Origen: %s" % mat["origin"], "CaptionLabel", AstralTheme.MUTED))
	var lines: Array[String] = []
	for sk in p["stat_deltas"].keys():
		lines.append(AstralTheme.colored("%s %s" % [GameState.get_stat_label(sk), AstralTheme.signed(int(p["stat_deltas"][sk]))], AstralTheme.GOOD))
	var sd: int = int(p["seal_delta"])
	var seal_lbl: String = GameState.get_stat_label("seal_integrity")
	lines.append(AstralTheme.colored("%s %s%%  (%d%% → %d%%)" % [seal_lbl, AstralTheme.signed(sd), GameState.seal_integrity, int(p["seal_after"])], AstralTheme.GOOD if sd >= 0 else AstralTheme.BAD))
	lines.append(AstralTheme.colored("Saturación %s  (%d → %d)" % [AstralTheme.signed(int(p["sat_gain"])), GameState.astral_saturation, int(p["sat_after"])], AstralTheme.EMBER if int(p["sat_gain"]) > 0 else AstralTheme.GOOD))
	var rich := AstralTheme.rich("\n".join(lines))
	v.add_child(rich)
	var mutation_text: String = "Mutación: [b]%s[/b] — %s" % [p["mutation_name"], CatalogDB.get_mutation(str(p["mutation_id"])).get("desc", "")]
	if not bool(p["new_mutation"]):
		mutation_text += AstralTheme.colored("  (ya la tienes)", AstralTheme.MUTED)
	v.add_child(AstralTheme.rich(AstralTheme.colored(mutation_text, AstralTheme.AMETHYST)))
	for w in p["warnings"]:
		v.add_child(AstralTheme.label(AstralTheme.G_BOLT + " " + str(w), "", AstralTheme.BAD if bool(p["overload"]) else AstralTheme.EMBER, true))
	var go := AstralTheme.button("%s  ASIMILAR EN EL HORNO" % AstralTheme.G_FLASK, "PrimaryButton")
	go.custom_minimum_size.y = 56
	var mid: String = _selected
	go.pressed.connect(func() -> void: _try_assimilate(mid, false))
	v.add_child(go)
	_detail_box.add_child(card)

func _try_assimilate(mid: String, confirmed: bool) -> void:
	var res: Dictionary = CrucibleManager.assimilate(mid, confirmed)
	if res.get("needs_confirm", false):
		_confirm.dialog_text = str(res["msg"]) + "\n\nSufrirá: -15%% %s, +20 Estrés, +10 %s y +8 Entropía." % [
			GameState.get_stat_label("seal_integrity"), GameState.get_stat_label("abyssal_sync")
		]
		for c in _confirm.confirmed.get_connections():
			_confirm.confirmed.disconnect(c["callable"])
		_confirm.confirmed.connect(func() -> void: _try_assimilate(mid, true))
		_confirm.popup_centered(Vector2i(560, 220))
		return
	if not res.get("ok", false):
		AstralAudio.play_warn()
		toast.emit(str(res.get("msg", "No se pudo asimilar.")), "warn")
		return
	var text: String = "Asimilaste %s. %s" % [res["name"], ", ".join(res["gains"])]
	if res["new_mutation"]:
		text += "  ¡Mutación despertada: %s!" % res["mutation_name"]
	if res["overload"]:
		text = "¡SOBRECARGA ASTRAL! " + text
		AstralAudio.play_warn()
	else:
		AstralAudio.play_triumph() if res["new_mutation"] else AstralAudio.play_confirm()
	speak.emit("Horno Astral", text)
	toast.emit(text, "bad" if res["overload"] else "good")
	refresh()

func _refresh_shop() -> void:
	clear(_shop_box)
	var open: bool = TimeManager.is_bazaar_open()
	var info := AstralTheme.label(
		("Zahir el Nómada ha montado su puesto en el Bazar de Medianoche (bimestres pares)." if open else "Zahir el Nómada no está en la ciudad este bimestre: solo acampa en los bimestres pares."),
		"CaptionLabel", AstralTheme.TURQ if open else AstralTheme.EMBER, true)
	_shop_box.add_child(info)
	_shop_box.add_child(AstralTheme.label("Tu Reputación Paterna (%d) da hasta 15%% de descuento." % GameState.father_reputation, "CaptionLabel", AstralTheme.MUTED, true))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shop_box.add_child(grid)
	for m in CatalogDB.COSMIC_MATERIALS:
		var price: int = CrucibleManager.get_material_price(m)
		var need_rep: int = int(m.get("exclusive_rep", 0))
		var locked_rep: bool = GameState.father_reputation < need_rep
		var b := AstralTheme.button("%s\n%d G%s" % [m["name"], price, ("   (requiere Reputación %d)" % need_rep) if need_rep > 0 else ""], "")
		b.custom_minimum_size.y = 62
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = (not open) or locked_rep or GameState.gold < price
		var tips: Array[String] = []
		if not open: tips.append("El bazar está cerrado este bimestre.")
		if locked_rep: tips.append("Necesitas %d de Reputación Paterna (la Diplomacia del Padre la sube)." % need_rep)
		if GameState.gold < price: tips.append("Faltan %d G." % (price - GameState.gold))
		b.tooltip_text = " ".join(tips)
		var mid: String = m["id"]
		b.pressed.connect(func() -> void:
			var r: Dictionary = CrucibleManager.buy_material(mid)
			AstralAudio.play_confirm() if r.get("ok", false) else AstralAudio.play_warn()
			toast.emit(str(r.get("msg", "")), "good" if r.get("ok", false) else "warn")
			refresh())
		grid.add_child(b)

	var row := AstralTheme.hbox(12)
	_shop_box.add_child(row)
	var dist := AstralTheme.button("%s  Destilar reliquia (%d G)" % [AstralTheme.G_HOURGLASS, CrucibleManager.get_distill_cost()], "TabLikeButton",
		"Condensa luz de la esfera armilar en una reliquia al azar (determinista). Una vez por bimestre; +8 Resonancia.")
	dist.custom_minimum_size.y = 56
	dist.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dist.disabled = CrucibleManager.distilled_this_bimester or GameState.gold < CrucibleManager.get_distill_cost()
	dist.pressed.connect(func() -> void:
		var r: Dictionary = CrucibleManager.distill_relic()
		AstralAudio.play_triumph() if r.get("ok", false) else AstralAudio.play_warn()
		speak.emit("Horno Astral", str(r.get("msg", "")))
		toast.emit(str(r.get("msg", "")), "good" if r.get("ok", false) else "warn")
		refresh())
	row.add_child(dist)
	var pur := AstralTheme.button("%s  Purificar Saturación (%d G)" % [AstralTheme.G_FLOWER, CrucibleManager.get_purify_cost()], "TabLikeButton",
		"-25 Saturación, +3%% %s, -10 Estrés." % GameState.get_stat_label("seal_integrity"))
	pur.custom_minimum_size.y = 56
	pur.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pur.disabled = GameState.astral_saturation <= 0 or GameState.gold < CrucibleManager.get_purify_cost()
	pur.pressed.connect(func() -> void:
		var r: Dictionary = CrucibleManager.purify_saturation()
		AstralAudio.play_confirm() if r.get("ok", false) else AstralAudio.play_warn()
		speak.emit("Termas de Alabastro", str(r.get("msg", "")))
		toast.emit(str(r.get("msg", "")), "good" if r.get("ok", false) else "warn")
		refresh())
	row.add_child(pur)
