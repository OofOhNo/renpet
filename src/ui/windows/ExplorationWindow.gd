extends BaseWindow
class_name ExplorationWindow

## Ventana VI: Mapa de Exploración de las 5 Regiones Concéntricas de Aethelgard (Fase 7).
## Permite elegir un compañero entre los 6 candidatos y partir de expedición (1 por bimestre).

signal expedition_started()

var _comp_opt: OptionButton
var _comp_info: Label
var _zones_box: VBoxContainer
var _shards_lbl: Label

func build() -> void:
	setup("%s  EXPEDICIÓN ASTRAL — LAS 5 REGIONES DE AETHELGARD" % AstralTheme.G_SWORD)

	var intro := AstralTheme.label(
		"Explora las ruinas y anomalías fuera de la capital junto a un aliado. Cada región esconde una Esquirla de Memoria sobre la verdad del Sello.",
		"CaptionLabel", AstralTheme.MUTED
	)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(intro)

	# --- PANEL DE SELECCIÓN DE COMPAÑERO ---
	var comp_card := PanelContainer.new()
	comp_card.theme_type_variation = "CardPanel"
	body.add_child(comp_card)

	var cv := AstralTheme.vbox(8)
	comp_card.add_child(cv)

	var ch := AstralTheme.hbox(12)
	cv.add_child(ch)
	ch.add_child(AstralTheme.label("%s  Compañero de Expedición:" % AstralTheme.G_ANKH, "SubLabel"))

	_comp_opt = OptionButton.new()
	_comp_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for npc_id in RelationshipManager.NPC_ORDER:
		var data: Dictionary = RelationshipManager.NPC_DATA[npc_id]
		_comp_opt.add_item("%s — %s" % [data["name"], data["title"]])
		_comp_opt.set_item_metadata(_comp_opt.item_count - 1, npc_id)
	_comp_opt.selected = 1   # Vespera por defecto
	_comp_opt.item_selected.connect(_on_companion_changed)
	ch.add_child(_comp_opt)

	_comp_info = AstralTheme.label("", "CaptionLabel", AstralTheme.TURQ)
	_comp_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cv.add_child(_comp_info)

	_shards_lbl = AstralTheme.label("", "SubLabel", AstralTheme.GOLD_PALE)
	body.add_child(_shards_lbl)

	body.add_child(AstralTheme.separator())

	_zones_box = AstralTheme.vbox(10)
	body.add_child(_zones_box)

func refresh() -> void:
	_update_companion_info()
	_shards_lbl.text = "%s  Esquirlas de Memoria descubiertas: %d / %d   |   Investigación del Sello: %d%%" % [
		AstralTheme.G_STAR, ExplorationCombat.memory_shards_found.size(), ExplorationCombat.ZONES.size(), GameState.seal_investigation_progress
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

func _on_companion_changed(_idx: int) -> void:
	_update_companion_info()

func _update_companion_info() -> void:
	if _comp_opt == null or _comp_info == null:
		return
	var npc_id: String = str(_comp_opt.get_item_metadata(_comp_opt.selected))
	var data: Dictionary = RelationshipManager.NPC_DATA.get(npc_id, {})
	var status: String = RelationshipManager.get_relationship_status_title(npc_id)
	var bonus: float = ExplorationCombat.get_companion_affinity_bonus(npc_id)
	var can_rec: bool = ExplorationCombat.can_recruit_companion(npc_id) and RelationshipManager.is_available(npc_id)
	var extra_tag: String = ""
	if not RelationshipManager.is_available(npc_id):
		extra_tag = "  [%s]" % RelationshipManager.get_locked_reason(npc_id)
	elif not can_rec:
		extra_tag = "  [No disponible: vínculo hostil]"
	elif bonus > 1.0:
		extra_tag = "  [Sinergia de Vínculo: +%d%% eficacia]" % int(round((bonus - 1.0) * 100.0))
	_comp_info.text = "%s — %s%s\n%s" % [data.get("name", ""), status, extra_tag, data.get("perk_desc", "")]
	_comp_info.add_theme_color_override("font_color", AstralTheme.BAD if not can_rec else AstralTheme.TURQ)

func _on_explore_pressed(zone_idx: int) -> void:
	var npc_id: String = str(_comp_opt.get_item_metadata(_comp_opt.selected))
	var npc_name: String = str(RelationshipManager.NPC_DATA[npc_id]["name"])
	var res: Dictionary = ExplorationCombat.start_expedition(zone_idx, npc_id, npc_name)
	if not res.get("ok", false):
		toast.emit(str(res.get("msg", "No se pudo iniciar la expedición.")), "warn")
		return
	close()
	expedition_started.emit()
