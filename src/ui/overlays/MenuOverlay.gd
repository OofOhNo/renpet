extends ModalOverlay
class_name MenuOverlay

## Menú de pausa y de guardado/carga con ranuras (autoguardado + 3 manuales).

signal save_done(slot: int)
signal load_requested(slot: int)
signal title_requested()

enum Mode { PAUSE, SAVE, LOAD }
var mode: Mode = Mode.PAUSE
var allow_save: bool = true

func open_pause(can_save: bool = true) -> void:
	allow_save = can_save
	mode = Mode.PAUSE
	_build()
	show_overlay()

func open_slots(m: Mode) -> void:
	mode = m
	_build()
	show_overlay()

func _build() -> void:
	set_panel_width(780)
	rebuild(_build_content)

func _build_content() -> void:
	match mode:
		Mode.PAUSE:
			_build_pause()
		Mode.SAVE:
			_build_slots("Guardar partida")
		Mode.LOAD:
			_build_slots("Cargar partida")

func _build_pause() -> void:
	content.add_child(AstralTheme.label("%s  MENÚ DEL OBSERVATORIO  %s" % [AstralTheme.G_STAR, AstralTheme.G_STAR], "HeadingLabel", AstralTheme.GOLD, true))
	content.add_child(AstralTheme.separator())
	var b1 := AstralTheme.button("Continuar", "PrimaryButton")
	b1.custom_minimum_size.y = 56
	b1.pressed.connect(hide_overlay)
	content.add_child(b1)
	var b2 := AstralTheme.button("Guardar partida")
	b2.custom_minimum_size.y = 52
	b2.disabled = not allow_save
	b2.pressed.connect(func() -> void: open_slots(Mode.SAVE))
	content.add_child(b2)
	var b3 := AstralTheme.button("Cargar partida")
	b3.custom_minimum_size.y = 52
	b3.disabled = not SaveManager.has_any_save()
	b3.pressed.connect(func() -> void: open_slots(Mode.LOAD))
	content.add_child(b3)
	var b4 := AstralTheme.button("Volver al título", "DangerButton")
	b4.custom_minimum_size.y = 52
	b4.pressed.connect(func() -> void:
		hide_overlay()
		title_requested.emit())
	content.add_child(b4)

func _build_slots(title: String) -> void:
	content.add_child(AstralTheme.label("%s  %s" % [AstralTheme.G_ENVELOPE, title.to_upper()], "HeadingLabel", AstralTheme.GOLD, true))
	content.add_child(AstralTheme.separator())
	for entry in SaveManager.list_slots():
		var slot: int = int(entry["slot"])
		if mode == Mode.SAVE and slot == SaveManager.AUTOSAVE_SLOT:
			continue
		var card := AstralTheme.panel("CardPanel")
		var h := AstralTheme.hbox(14)
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
		btn.custom_minimum_size = Vector2(140, 48)
		btn.disabled = (mode == Mode.LOAD) and not (entry["exists"] and entry["valid"])
		btn.pressed.connect(func() -> void: _slot_pressed(slot))
		h.add_child(btn)
		content.add_child(card)
	var back := AstralTheme.button("Volver", "TabLikeButton")
	back.pressed.connect(func() -> void:
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
