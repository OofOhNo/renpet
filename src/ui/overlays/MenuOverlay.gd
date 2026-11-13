extends ModalOverlay
class_name MenuOverlay

## Menú de pausa, guardado/carga con borrado de ranuras, confirmación al salir y Opciones persistentes.

signal save_done(slot: int)
signal load_requested(slot: int)
signal title_requested()
signal tutorial_requested()

enum Mode { PAUSE, SAVE, LOAD, SETTINGS, CONFIRM_TITLE }
var mode: Mode = Mode.PAUSE
var allow_save: bool = true
var _standalone_mode: bool = false
var _delete_confirm_slot: int = -1
var _res_opt: OptionButton

func open_pause(can_save: bool = true) -> void:
	allow_save = can_save
	_standalone_mode = false
	_delete_confirm_slot = -1
	mode = Mode.PAUSE
	_build()
	show_overlay()

func open_slots(m: Mode) -> void:
	_standalone_mode = (m == Mode.LOAD and not visible)
	_delete_confirm_slot = -1
	mode = m
	_build()
	if not visible:
		show_overlay()

func open_settings() -> void:
	_standalone_mode = not visible
	_delete_confirm_slot = -1
	mode = Mode.SETTINGS
	_build()
	if not visible:
		show_overlay()

func _build() -> void:
	set_panel_width(820)
	rebuild(_build_content)

func _build_content() -> void:
	match mode:
		Mode.PAUSE:
			_build_pause()
		Mode.SAVE:
			_build_slots("Guardar partida")
		Mode.LOAD:
			_build_slots("Cargar partida")
		Mode.SETTINGS:
			_build_settings()
		Mode.CONFIRM_TITLE:
			_build_confirm_title()

func _build_pause() -> void:
	content.add_child(AstralTheme.label("%s  MENÚ DEL OBSERVATORIO  %s" % [AstralTheme.G_STAR, AstralTheme.G_STAR], "HeadingLabel", AstralTheme.GOLD, true))
	content.add_child(AstralTheme.separator())
	var b1 := AstralTheme.button("Continuar", "PrimaryButton")
	b1.custom_minimum_size.y = 54
	b1.pressed.connect(hide_overlay)
	content.add_child(b1)
	var b2 := AstralTheme.button("Guardar partida")
	b2.custom_minimum_size.y = 50
	b2.disabled = not allow_save
	b2.pressed.connect(func() -> void:
		AstralAudio.play_ui()
		mode = Mode.SAVE
		_build())
	content.add_child(b2)
	var b3 := AstralTheme.button("Cargar partida")
	b3.custom_minimum_size.y = 50
	b3.disabled = not SaveManager.has_any_save()
	b3.pressed.connect(func() -> void:
		AstralAudio.play_ui()
		mode = Mode.LOAD
		_build())
	content.add_child(b3)
	var b_opt := AstralTheme.button("%s  Opciones de juego y sonido" % AstralTheme.G_ANKH)
	b_opt.custom_minimum_size.y = 50
	b_opt.pressed.connect(func() -> void:
		AstralAudio.play_ui()
		mode = Mode.SETTINGS
		_build())
	content.add_child(b_opt)
	var b_tut := AstralTheme.button("%s  Ver guía / Tutorial" % AstralTheme.G_STAR, "TabLikeButton")
	b_tut.custom_minimum_size.y = 48
	b_tut.pressed.connect(func() -> void:
		AstralAudio.play_ui()
		hide_overlay()
		tutorial_requested.emit())
	content.add_child(b_tut)
	var b4 := AstralTheme.button("Volver al título", "DangerButton")
	b4.custom_minimum_size.y = 50
	b4.pressed.connect(func() -> void:
		AstralAudio.play_warn()
		mode = Mode.CONFIRM_TITLE
		_build())
	content.add_child(b4)

func _build_confirm_title() -> void:
	content.add_child(AstralTheme.label("%s  ¿VOLVER AL TÍTULO?" % AstralTheme.G_BOLT, "HeadingLabel", AstralTheme.EMBER, true))
	content.add_child(AstralTheme.separator())
	content.add_child(AstralTheme.label("Si no has guardado manualmente tras los cambios de este bimestre, podrías perder tus decisiones pendientes.", "", AstralTheme.IVORY, true))
	if allow_save:
		var b_save_exit := AstralTheme.button("Guardar en Ranura %d y volver al título" % SaveManager.current_slot, "PrimaryButton")
		b_save_exit.custom_minimum_size.y = 54
		b_save_exit.pressed.connect(func() -> void:
			SaveManager.save_game(SaveManager.current_slot)
			hide_overlay()
			title_requested.emit())
		content.add_child(b_save_exit)
	var b_leave := AstralTheme.button("Salir al título sin guardar", "DangerButton")
	b_leave.custom_minimum_size.y = 50
	b_leave.pressed.connect(func() -> void:
		hide_overlay()
		title_requested.emit())
	content.add_child(b_leave)
	var b_cancel := AstralTheme.button("Cancelar y seguir jugando", "TabLikeButton")
	b_cancel.custom_minimum_size.y = 48
	b_cancel.pressed.connect(func() -> void:
		mode = Mode.PAUSE
		_build())
	content.add_child(b_cancel)

func _build_settings() -> void:
	content.add_child(AstralTheme.label("%s  OPCIONES DEL OBSERVATORIO" % AstralTheme.G_ANKH, "HeadingLabel", AstralTheme.GOLD, true))
	content.add_child(AstralTheme.separator())

	# --- Bloque 1: Pantalla y Resolución ---
	var card_disp := AstralTheme.panel("CardPanel")
	content.add_child(card_disp)
	var vd := AstralTheme.vbox(10)
	card_disp.add_child(vd)
	vd.add_child(AstralTheme.label("%s  PANTALLA Y RESOLUCIÓN" % AstralTheme.G_SUN, "SubLabel", AstralTheme.GOLD_PALE))

	var row_fs := AstralTheme.hbox(12)
	vd.add_child(row_fs)
	var lbl_fs := AstralTheme.label("Modo de pantalla (F11):", "SubLabel", AstralTheme.IVORY, true)
	lbl_fs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_fs.add_child(lbl_fs)
	var btn_fs := AstralTheme.button("Pantalla Completa" if SettingsManager.fullscreen else "Modo Ventana", "TabLikeButton")
	btn_fs.custom_minimum_size = Vector2(260, 42)
	btn_fs.pressed.connect(func() -> void:
		AstralAudio.play_ui()
		SettingsManager.toggle_fullscreen()
		_build())
	row_fs.add_child(btn_fs)

	var row_res := AstralTheme.hbox(12)
	vd.add_child(row_res)
	var lbl_res := AstralTheme.label("Resolución (10 más usadas):", "SubLabel", AstralTheme.IVORY, true)
	lbl_res.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_res.add_child(lbl_res)
	_res_opt = OptionButton.new()
	_res_opt.custom_minimum_size = Vector2(260, 42)
	_res_opt.tooltip_text = "Ajusta el tamaño de la ventana a una de las 10 resoluciones más habituales."
	for i in range(SettingsManager.RESOLUTIONS.size()):
		_res_opt.add_item(SettingsManager.get_resolution_label(i), i)
	_res_opt.selected = clampi(SettingsManager.resolution_index, 0, SettingsManager.RESOLUTIONS.size() - 1)
	_res_opt.item_selected.connect(func(idx: int) -> void:
		AstralAudio.play_ui()
		SettingsManager.set_resolution_index(idx, true)
		_build())
	row_res.add_child(_res_opt)

	if SettingsManager.fullscreen:
		vd.add_child(AstralTheme.label("En Pantalla Completa usa el monitor nativo; elegir una resolución cambia a Modo Ventana.", "CaptionLabel", AstralTheme.MUTED, true))

	# --- Bloque 2: Ritmo y Animaciones ---
	var card_ux := AstralTheme.panel("CardPanel")
	content.add_child(card_ux)
	var vu := AstralTheme.vbox(10)
	card_ux.add_child(vu)
	vu.add_child(AstralTheme.label("%s  RITMO VISUAL" % AstralTheme.G_HOURGLASS, "SubLabel", AstralTheme.TURQ))

	var row_txt := AstralTheme.hbox(12)
	vu.add_child(row_txt)
	var lbl_txt := AstralTheme.label("Velocidad de diálogo:", "SubLabel", AstralTheme.IVORY, true)
	lbl_txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_txt.add_child(lbl_txt)
	var btn_txt := AstralTheme.button(SettingsManager.get_text_speed_label(), "TabLikeButton")
	btn_txt.custom_minimum_size = Vector2(260, 42)
	btn_txt.pressed.connect(func() -> void:
		AstralAudio.play_ui()
		SettingsManager.set_text_speed((SettingsManager.text_speed + 1) % 3)
		_build())
	row_txt.add_child(btn_txt)

	var row_anim := AstralTheme.hbox(12)
	vu.add_child(row_anim)
	var lbl_anim := AstralTheme.label("Paso de bimestre (60 días):", "SubLabel", AstralTheme.IVORY, true)
	lbl_anim.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_anim.add_child(lbl_anim)
	var btn_anim := AstralTheme.button("Rápida" if SettingsManager.short_turn_anim else "Completa", "TabLikeButton")
	btn_anim.custom_minimum_size = Vector2(260, 42)
	btn_anim.pressed.connect(func() -> void:
		AstralAudio.play_ui()
		SettingsManager.set_short_turn_anim(not SettingsManager.short_turn_anim)
		_build())
	row_anim.add_child(btn_anim)

	var row_rep := AstralTheme.hbox(12)
	vu.add_child(row_rep)
	var lbl_rep := AstralTheme.label("Resumen al cerrar bimestre:", "SubLabel", AstralTheme.IVORY, true)
	lbl_rep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_rep.add_child(lbl_rep)
	var btn_rep := AstralTheme.button("Visual unificado (ágil)" if SettingsManager.unified_turn_end else "Crónica detallada", "TabLikeButton")
	btn_rep.custom_minimum_size = Vector2(260, 42)
	btn_rep.pressed.connect(func() -> void:
		AstralAudio.play_ui()
		SettingsManager.set_unified_turn_end(not SettingsManager.unified_turn_end)
		_build())
	row_rep.add_child(btn_rep)

	# --- Bloque 3: Audio ---
	var card := AstralTheme.panel("CardPanel")
	content.add_child(card)
	var v := AstralTheme.vbox(10)
	card.add_child(v)
	v.add_child(AstralTheme.label("%s  MÚSICA Y EFECTOS" % AstralTheme.G_MOON, "SubLabel", AstralTheme.AMETHYST))

	var row_bgm := AstralTheme.hbox(12)
	v.add_child(row_bgm)
	var lbl_bgm := AstralTheme.label("Música (%d%%):" % int(round(SettingsManager.bgm_volume * 100.0)), "SubLabel", AstralTheme.TURQ)
	lbl_bgm.custom_minimum_size.x = 220
	row_bgm.add_child(lbl_bgm)
	var sl_bgm := HSlider.new()
	sl_bgm.min_value = 0.0
	sl_bgm.max_value = 1.0
	sl_bgm.step = 0.05
	sl_bgm.value = SettingsManager.bgm_volume
	sl_bgm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl_bgm.custom_minimum_size.y = 30
	sl_bgm.value_changed.connect(func(val: float) -> void:
		SettingsManager.set_bgm_volume(val)
		lbl_bgm.text = "Música (%d%%):" % int(round(val * 100.0)))
	row_bgm.add_child(sl_bgm)

	var row_sfx := AstralTheme.hbox(12)
	v.add_child(row_sfx)
	var lbl_sfx := AstralTheme.label("Efectos (%d%%):" % int(round(SettingsManager.sfx_volume * 100.0)), "SubLabel", AstralTheme.GOLD_PALE)
	lbl_sfx.custom_minimum_size.x = 220
	row_sfx.add_child(lbl_sfx)
	var sl_sfx := HSlider.new()
	sl_sfx.min_value = 0.0
	sl_sfx.max_value = 1.0
	sl_sfx.step = 0.05
	sl_sfx.value = SettingsManager.sfx_volume
	sl_sfx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl_sfx.custom_minimum_size.y = 30
	sl_sfx.value_changed.connect(func(val: float) -> void:
		SettingsManager.set_sfx_volume(val)
		lbl_sfx.text = "Efectos (%d%%):" % int(round(val * 100.0)))
	row_sfx.add_child(sl_sfx)

	var row_mute := AstralTheme.hbox(12)
	v.add_child(row_mute)
	var lbl_mute := AstralTheme.label("Audio general:", "SubLabel", AstralTheme.IVORY, true)
	lbl_mute.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_mute.add_child(lbl_mute)
	var btn_mute := AstralTheme.button("Silenciado" if AstralAudio.muted else "Audio Activo", "DangerButton" if AstralAudio.muted else "PrimaryButton")
	btn_mute.custom_minimum_size = Vector2(260, 42)
	btn_mute.pressed.connect(func() -> void:
		AstralAudio.toggle_mute()
		_build())
	row_mute.add_child(btn_mute)

	var back := AstralTheme.button("Volver", "TabLikeButton")
	back.custom_minimum_size.y = 46
	back.pressed.connect(func() -> void:
		if _standalone_mode:
			hide_overlay()
		else:
			mode = Mode.PAUSE
			_build())
	content.add_child(back)

func _build_slots(title: String) -> void:
	content.add_child(AstralTheme.label("%s  %s" % [AstralTheme.G_ENVELOPE, title.to_upper()], "HeadingLabel", AstralTheme.GOLD, true))
	content.add_child(AstralTheme.separator())
	for entry in SaveManager.list_slots():
		var slot: int = int(entry["slot"])
		if mode == Mode.SAVE and slot == SaveManager.AUTOSAVE_SLOT:
			continue
		var card := AstralTheme.panel("CardPanel")
		var h := AstralTheme.hbox(10)
		card.add_child(h)
		var v := AstralTheme.vbox(2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(AstralTheme.label(str(entry["label"]), "SubLabel"))
		if entry["exists"] and entry["valid"]:
			v.add_child(AstralTheme.label("%s · %d años · Turno %d/48 · %s · %d G" % [entry["daughter_name"], int(entry["age"]), int(entry["turn"]), entry["bimester_name"], int(entry["gold"])], "CaptionLabel", AstralTheme.IVORY, true))
			if int(entry["saved_at"]) > 0:
				v.add_child(AstralTheme.label(Time.get_datetime_string_from_unix_time(int(entry["saved_at"]), true), "CaptionLabel", AstralTheme.MUTED))
		elif entry["exists"]:
			v.add_child(AstralTheme.label("Archivo dañado", "CaptionLabel", AstralTheme.BAD))
		else:
			v.add_child(AstralTheme.label("Vacía", "CaptionLabel", AstralTheme.MUTED))
		var btn := AstralTheme.button("Guardar" if mode == Mode.SAVE else "Cargar", "PrimaryButton" if mode == Mode.SAVE else "")
		btn.custom_minimum_size = Vector2(126, 48)
		btn.disabled = (mode == Mode.LOAD) and not (entry["exists"] and entry["valid"])
		btn.pressed.connect(func() -> void: _slot_pressed(slot))
		h.add_child(btn)
		if entry["exists"]:
			var confirming: bool = (_delete_confirm_slot == slot)
			var del_btn := AstralTheme.button("¿Borrar?" if confirming else AstralTheme.G_CROSS, "DangerButton", "Eliminar esta ranura guardada")
			del_btn.custom_minimum_size = Vector2(96 if confirming else 48, 48)
			del_btn.pressed.connect(func() -> void:
				if _delete_confirm_slot == slot:
					SaveManager.delete_slot(slot)
					_delete_confirm_slot = -1
					AstralAudio.play_warn()
					_build()
				else:
					_delete_confirm_slot = slot
					AstralAudio.play_ui()
					_build())
			h.add_child(del_btn)
		content.add_child(card)
	var back := AstralTheme.button("Volver", "TabLikeButton")
	back.custom_minimum_size.y = 48
	back.pressed.connect(func() -> void:
		_delete_confirm_slot = -1
		if _standalone_mode:
			hide_overlay()
		else:
			mode = Mode.PAUSE
			_build())
	content.add_child(back)

func _slot_pressed(slot: int) -> void:
	if mode == Mode.SAVE:
		if SaveManager.save_game(slot):
			save_done.emit(slot)
			hide_overlay()
	elif mode == Mode.LOAD:
		hide_overlay()
		load_requested.emit(slot)
