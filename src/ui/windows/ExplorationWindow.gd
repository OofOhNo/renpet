extends BaseWindow
class_name ExplorationWindow

## Ventana VI: Exploración Astral (5 Regiones) y Gran Festival de las Constelaciones de Otoño (Fases 7 y 8).

signal expedition_started()
signal festival_completed(res: Dictionary)

var _tabs: TabContainer
var _comp_opt: OptionButton
var _comp_info: Label
var _zones_box: VBoxContainer
var _shards_lbl: Label

var _fest_banner: PanelContainer
var _fest_banner_lbl: Label
var _fest_result_card: PanelContainer
var _fest_result_lbl: RichTextLabel
var _fest_box: VBoxContainer

func build() -> void:
	setup("%s  EXPEDICIÓN ASTRAL Y FESTIVAL DE OTOÑO" % AstralTheme.G_SWORD, false)

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(_tabs)

	# --- PESTAÑA 1: EXPLORACIÓN DE LAS 5 REGIONES ---
	var exp_v: VBoxContainer = BaseWindow.add_tab(_tabs, "  Exploración (5 Regiones)  ")

	var intro := AstralTheme.label(
		"Explora ruinas y anomalías fuera de la capital junto a un aliado. Cada región custodia Esquirlas de Memoria antiguas.",
		"CaptionLabel", AstralTheme.MUTED
	)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	exp_v.add_child(intro)

	var comp_card := PanelContainer.new()
	comp_card.theme_type_variation = "CardPanel"
	exp_v.add_child(comp_card)

	var cv := AstralTheme.vbox(8)
	comp_card.add_child(cv)

	var ch := AstralTheme.hbox(12)
	cv.add_child(ch)
	ch.add_child(AstralTheme.label("%s  Compañero de Expedición:" % AstralTheme.G_ANKH, "SubLabel"))

	_comp_opt = OptionButton.new()
	_comp_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for npc_id in RelationshipManager.NPC_ORDER:
		var data: Dictionary = RelationshipManager.get_data(npc_id)
		_comp_opt.add_item("%s — %s" % [data["name"], data["title"]])
		_comp_opt.set_item_metadata(_comp_opt.item_count - 1, npc_id)
	_comp_opt.selected = 1   # Vespera por defecto
	_comp_opt.item_selected.connect(_on_companion_changed)
	ch.add_child(_comp_opt)

	_comp_info = AstralTheme.label("", "CaptionLabel", AstralTheme.TURQ)
	_comp_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cv.add_child(_comp_info)

	_shards_lbl = AstralTheme.label("", "SubLabel", AstralTheme.GOLD_PALE)
	exp_v.add_child(_shards_lbl)
	exp_v.add_child(AstralTheme.separator())

	_zones_box = AstralTheme.vbox(10)
	exp_v.add_child(_zones_box)

	# --- PESTAÑA 2: GRAN FESTIVAL DE LAS CONSTELACIONES DE OTOÑO ---
	var fest_v: VBoxContainer = BaseWindow.add_tab(_tabs, "  Festival de Otoño  ")

	_fest_banner = PanelContainer.new()
	_fest_banner.theme_type_variation = "CardPanel"
	fest_v.add_child(_fest_banner)
	_fest_banner_lbl = AstralTheme.label("", "SubLabel", AstralTheme.GOLD_PALE)
	_fest_banner_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fest_banner.add_child(_fest_banner_lbl)

	_fest_result_card = PanelContainer.new()
	_fest_result_card.theme_type_variation = "CardPanel"
	_fest_result_card.visible = false
	fest_v.add_child(_fest_result_card)
	_fest_result_lbl = AstralTheme.rich()
	_fest_result_card.add_child(_fest_result_lbl)

	_fest_box = AstralTheme.vbox(10)
	fest_v.add_child(_fest_box)

func open_festival_tab() -> void:
	if _tabs != null and _tabs.get_tab_count() > 1:
		_tabs.current_tab = 1

func refresh() -> void:
	_refresh_companion_options()
	_update_companion_info()
	_refresh_exploration_tab()
	_refresh_festival_tab()

func _refresh_companion_options() -> void:
	if _comp_opt == null:
		return
	for i in range(_comp_opt.item_count):
		var npc_id: String = str(_comp_opt.get_item_metadata(i))
		var data: Dictionary = RelationshipManager.get_data(npc_id)
		if not RelationshipManager.is_available(npc_id):
			_comp_opt.set_item_text(i, "??? — Presencia oculta [Bloqueado]")
		else:
			_comp_opt.set_item_text(i, "%s — %s" % [data["name"], data["title"]])

func _refresh_exploration_tab() -> void:
	var inv_lbl: String = GameState.get_stat_label("seal_investigation")
	_shards_lbl.text = "%s  Esquirlas de Memoria descubiertas: %d / %d   |   %s: %d%%" % [
		AstralTheme.G_STAR, ExplorationCombat.memory_shards_found.size(), ExplorationCombat.ZONES.size(), inv_lbl, GameState.seal_investigation_progress
	]

	BaseWindow.clear(_zones_box)
	for i in range(ExplorationCombat.ZONES.size()):
		var z: Dictionary = ExplorationCombat.ZONES[i]
		var min_age: int = int(z["min_age"])
		var locked_age: bool = GameState.age < min_age
		var has_shard: bool = ExplorationCombat.memory_shards_found.has(z["shard_id"])

		var card := PanelContainer.new()
		card.theme_type_variation = "CardPanel"
		_zones_box.add_child(card)

		var row := AstralTheme.hbox(14)
		card.add_child(row)

		var icon := TextureRect.new()
		icon.texture = load(str(z["enemy_icon"]))
		icon.custom_minimum_size = Vector2(72, 72)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)

		var info := AstralTheme.vbox(4)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var title_col: Color = AstralTheme.MUTED if locked_age else AstralTheme.GOLD_PALE
		var shard_badge: String = "  [%s Esquirla hallada]" % AstralTheme.G_CHECK if has_shard else "  [%s Esquirla oculta]" % AstralTheme.G_STAR2
		info.add_child(AstralTheme.label("%s  (Edad %d+)%s" % [z["name"], min_age, shard_badge], "HeadingLabel", title_col))

		var desc := AstralTheme.label(str(z["desc"]), "CaptionLabel", AstralTheme.IVORY)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(desc)

		var mat_name: String = str(CatalogDB.get_material(str(z["loot_id"])).get("name", z["loot_id"]))
		info.add_child(AstralTheme.label(
			"Recompensa: +%d Oro  •  +1 %s  •  Enemigos: %s / %s" % [int(z["gold_reward"]), mat_name, z["enemy_name"], z["boss_name"]],
			"CaptionLabel", AstralTheme.TURQ
		))

		var btn := AstralTheme.button(
			"Requiere %d años" % min_age if locked_age else ("Ya explorado" if ExplorationCombat.explored_this_bimester else "%s  Explorar" % AstralTheme.G_SWORD),
			"" if (locked_age or ExplorationCombat.explored_this_bimester) else "PrimaryButton"
		)
		btn.custom_minimum_size = Vector2(165, 48)
		btn.disabled = locked_age or ExplorationCombat.explored_this_bimester
		var z_idx: int = i
		btn.pressed.connect(_on_explore_pressed.bind(z_idx))
		row.add_child(btn)

func _refresh_festival_tab() -> void:
	var is_open: bool = TimeManager.is_festival_bimester()
	var entered: bool = ExplorationCombat.festival_entered_this_year
	var wins_count: int = ExplorationCombat.festival_wins.size()

	if not is_open:
		_fest_banner_lbl.text = "%s  El Gran Festival de las Constelaciones abre sus puertas cada 4º Bimestre (Cosecha / Equinoccio de Otoño).\nVictorias acumuladas en campaña: %d. Entrena los atributos clave antes de otoño." % [AstralTheme.G_SUN, wins_count]
		_fest_banner_lbl.add_theme_color_override("font_color", AstralTheme.MUTED)
	elif entered:
		_fest_banner_lbl.text = "%s  %s ya participó en el certamen de este Equinoccio de Otoño.\nVictorias acumuladas en campaña: %d. Regresa el próximo año." % [AstralTheme.G_CHECK, GameState.daughter_name, wins_count]
		_fest_banner_lbl.add_theme_color_override("font_color", AstralTheme.TURQ)
	else:
		_fest_banner_lbl.text = "%s  ¡EL FESTIVAL DE OTOÑO ESTÁ ABIERTO! Elige 1 de los 4 certámenes reales para desafiar a un Rival este bimestre.\nVictorias acumuladas en campaña: %d." % [AstralTheme.G_STAR, wins_count]
		_fest_banner_lbl.add_theme_color_override("font_color", AstralTheme.GOLD_PALE)

	BaseWindow.clear(_fest_box)
	for i in range(ExplorationCombat.FESTIVAL_CONTESTS.size()):
		var c: Dictionary = ExplorationCombat.FESTIVAL_CONTESTS[i]
		var prev: Dictionary = ExplorationCombat.get_festival_preview(i)
		var my_total: int = int(prev["my_total"])
		var target_score: int = int(prev["target_score"])
		var fav: bool = my_total >= target_score

		var card := PanelContainer.new()
		card.theme_type_variation = "CardPanel"
		_fest_box.add_child(card)

		var row := AstralTheme.hbox(14)
		card.add_child(row)

		var info := AstralTheme.vbox(4)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		info.add_child(AstralTheme.label(str(c["name"]), "HeadingLabel", AstralTheme.GOLD_PALE))
		var desc := AstralTheme.label(str(c["desc"]), "CaptionLabel", AstralTheme.IVORY)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(desc)

		var stat_names: Array[String] = []
		for sk in c["stats"]:
			stat_names.append(GameState.get_stat_label(str(sk)))
		var mat_name: String = str(CatalogDB.get_material(str(c["reward_item"])).get("name", c["reward_item"]))

		var score_lbl := AstralTheme.label(
			"Pronóstico: %s %d pts   vs   Meta de %s: %d pts   [%s]" % [
				GameState.daughter_name, my_total, c["rival_name"], target_score,
				"FAVORABLE" if fav else "DESAFÍO DIFÍCIL"
			],
			"SubLabel", AstralTheme.GOOD if fav else AstralTheme.ROSE
		)
		info.add_child(score_lbl)

		info.add_child(AstralTheme.label(
			"Ejes: %s  •  Premio Campeona: +%d Oro, +24 Magnetismo, +10 Afecto, +6 Rep. y +1 %s" % [
				", ".join(stat_names), int(c["reward_gold"]), mat_name
			],
			"CaptionLabel", AstralTheme.TURQ
		))

		var btn := AstralTheme.button(
			"Solo en 4º Bim." if not is_open else ("Ya compitió" if entered else "%s  Participar" % AstralTheme.G_STAR),
			"PrimaryButton" if (is_open and not entered) else ""
		)
		btn.custom_minimum_size = Vector2(165, 52)
		btn.disabled = (not is_open) or entered
		var idx: int = i
		btn.pressed.connect(_on_festival_pressed.bind(idx))
		row.add_child(btn)

func _on_companion_changed(_idx: int) -> void:
	_update_companion_info()

func _update_companion_info() -> void:
	if _comp_opt == null or _comp_info == null:
		return
	var npc_id: String = str(_comp_opt.get_item_metadata(_comp_opt.selected))
	var data: Dictionary = RelationshipManager.get_data(npc_id)
	var avail: bool = RelationshipManager.is_available(npc_id)
	var status: String = RelationshipManager.get_relationship_status_title(npc_id)
	var bonus: float = ExplorationCombat.get_companion_affinity_bonus(npc_id)
	var can_rec: bool = ExplorationCombat.can_recruit_companion(npc_id) and avail
	var extra_tag: String = ""
	if not avail:
		extra_tag = "  [%s]" % RelationshipManager.get_locked_reason(npc_id)
		_comp_info.text = "??? — Presencia aún oculta%s\nDescubre el origen de este susurro avanzando la historia." % extra_tag
		_comp_info.add_theme_color_override("font_color", AstralTheme.MUTED)
		return
	if not can_rec:
		extra_tag = "  [No disponible: vínculo hostil]"
	elif bonus > 1.0:
		extra_tag = "  [Sinergia de Vínculo: +%d%% eficacia]" % int(round((bonus - 1.0) * 100.0))
	_comp_info.text = "%s — %s%s\n%s" % [data.get("name", ""), status, extra_tag, data.get("perk_desc", "")]
	_comp_info.add_theme_color_override("font_color", AstralTheme.BAD if not can_rec else AstralTheme.TURQ)

func _on_explore_pressed(zone_idx: int) -> void:
	var npc_id: String = str(_comp_opt.get_item_metadata(_comp_opt.selected))
	var data: Dictionary = RelationshipManager.get_data(npc_id)
	var npc_name: String = str(data.get("name", npc_id))
	var res: Dictionary = ExplorationCombat.start_expedition(zone_idx, npc_id, npc_name)
	if not res.get("ok", false):
		toast.emit(str(res.get("msg", "No se pudo iniciar la expedición.")), "warn")
		return
	close()
	expedition_started.emit()

func _on_festival_pressed(contest_idx: int) -> void:
	var res: Dictionary = ExplorationCombat.participate_in_festival(contest_idx)
	if not res.get("ok", false):
		toast.emit(str(res.get("msg", "No se pudo participar.")), "warn")
		return
	_fest_result_card.visible = true
	_fest_result_lbl.text = "[color=#f7e3a1][b]%s[/b][/color]\n%s" % [str(res.get("title", "")), str(res.get("summary", ""))]
	_refresh_festival_tab()
	festival_completed.emit(res)
	toast.emit("Resultado del Festival de Otoño registrado", "good" if bool(res.get("won", false)) else "info")
