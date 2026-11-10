extends BaseWindow
class_name TownMap

## Ciudad y Vínculos (Fase 6): 6 candidatos con matriz de Afecto/Respeto/Chispa y 4 rivales en espejo.
## La Chispa Romántica y las citas aparecen solo cuando Renpet tiene 18 años o más.

signal bond_event_requested(npc_id: String)

var _tabs: TabContainer
var _npc_box: VBoxContainer
var _rival_box: VBoxContainer

func _ready() -> void:
	setup("Ciudad de Aethelgard", false)

func build() -> void:
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_tabs)
	_npc_box = add_tab(_tabs, "  Candidatos y Vínculos  ")
	_rival_box = add_tab(_tabs, "  Rivales de Aethelgard  ")

func refresh() -> void:
	if _tabs == null:
		return
	_refresh_npcs()
	_refresh_rivals()

# ------------------------------------------------------------------------------
func _refresh_npcs() -> void:
	clear(_npc_box)
	var status := AstralTheme.panel("GlowPanel")
	var sv := AstralTheme.vbox(4)
	status.add_child(sv)
	if RelationshipManager.interacted_this_bimester:
		sv.add_child(AstralTheme.label("%s ya realizó su salida a la capital este bimestre." % GameState.daughter_name, "SubLabel", AstralTheme.EMBER, true))
	else:
		sv.add_child(AstralTheme.label("Una salida a la capital por bimestre: apoyar, regalar, provocar o vivir una escena de historia.", "SubLabel", null, true))
	var note: String = RelationshipManager.get_romance_locked_note()
	if note != "":
		sv.add_child(AstralTheme.label(note, "CaptionLabel", AstralTheme.MUTED, true))
	_npc_box.add_child(status)

	for npc_id in RelationshipManager.NPC_ORDER:
		_npc_box.add_child(_npc_card(npc_id))

func _npc_card(npc_id: String) -> Control:
	var data: Dictionary = RelationshipManager.get_data(npc_id)
	var st: Dictionary = RelationshipManager.get_state(npc_id)
	var card := AstralTheme.panel("CardPanel")
	var h := AstralTheme.hbox(16)
	card.add_child(h)

	var icon := TextureRect.new()
	icon.texture = load("res://assets/ui/npc_%s.png" % npc_id)
	icon.custom_minimum_size = Vector2(96, 96)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(icon)

	var mid := AstralTheme.vbox(6)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(mid)
	mid.add_child(AstralTheme.label(str(data["name"]), "HeadingLabel"))
	mid.add_child(AstralTheme.label("%s  ·  %s" % [data["title"], data["location"]], "CaptionLabel", AstralTheme.MUTED, true))

	if not RelationshipManager.is_available(npc_id):
		icon.modulate = Color(0.4, 0.4, 0.5, 0.8)
		mid.add_child(AstralTheme.label(AstralTheme.G_MOON + "  " + RelationshipManager.get_locked_reason(npc_id), "", AstralTheme.EMBER, true))
		return card

	mid.add_child(AstralTheme.label(RelationshipManager.get_relationship_status_title(npc_id), "SubLabel", AstralTheme.GOLD_PALE, true))
	var ba := StatBar.new()
	ba.setup("Afecto", "affection", -100, 100, AstralTheme.ROSE, "Cariño o rencor. Con ±45 se abre la escena del Acto II y con ±80 la del Acto III.", 110)
	mid.add_child(ba)
	ba.set_value(int(st["affection"]), false)
	var br := StatBar.new()
	br.setup("Respeto", "respect", -100, 100, AstralTheme.SKY, "Admiración por su carácter y su fuerza.", 110)
	mid.add_child(br)
	br.set_value(int(st["respect"]), false)
	if RelationshipManager.romance_available(npc_id):
		var bs := StatBar.new()
		bs.setup("Chispa", "spark", 0, 100, AstralTheme.AMETHYST, "Chispa romántica (solo adultos).", 110)
		mid.add_child(bs)
		bs.set_value(int(st["spark"]), false)
	mid.add_child(AstralTheme.label("Etapa %d de 3 · Escenas vividas: %d de 3" % [int(st["stage"]), (st["events_seen"] as Array).size()], "CaptionLabel", AstralTheme.MUTED))
	mid.add_child(AstralTheme.label(str(data["perk_desc"]), "CaptionLabel", AstralTheme.TURQ, true))

	var acts := AstralTheme.vbox(6)
	acts.custom_minimum_size.x = 210
	h.add_child(acts)
	var used: bool = RelationshipManager.interacted_this_bimester
	acts.add_child(_action_btn("%s  Apoyar" % AstralTheme.G_STAR, npc_id, "support", used, "+16 Afecto, +14 Respeto, +5 Anclaje Humano."))
	acts.add_child(_action_btn("%s  Regalar (-%d G)" % [AstralTheme.G_FLOWER, RelationshipManager.SOCIAL_COST_GIFT], npc_id, "gift", used or GameState.gold < RelationshipManager.SOCIAL_COST_GIFT, "+22 Afecto, +10 Respeto."))
	acts.add_child(_action_btn("%s  Provocar" % AstralTheme.G_SWORD, npc_id, "provoke", used, "-30 Afecto y +6 Entropía. Si Renpet es fuerte, el rival la respeta más."))
	if RelationshipManager.romance_available(npc_id):
		acts.add_child(_action_btn("%s  Cita romántica" % AstralTheme.G_HEART, npc_id, "romance", used, "+20 Chispa, +12 Afecto, -10 Estrés."))
	var ev: Dictionary = RelationshipManager.get_next_bond_event(npc_id)
	var scene_btn := AstralTheme.button("%s  Escena de historia" % AstralTheme.G_QUILL, "PrimaryButton")
	scene_btn.disabled = not ev.get("ok", false)
	scene_btn.tooltip_text = "Una escena especial con decisiones." if ev.get("ok", false) else str(ev.get("reason", ""))
	scene_btn.custom_minimum_size.y = 46
	scene_btn.pressed.connect(func() -> void: bond_event_requested.emit(npc_id))
	acts.add_child(scene_btn)
	if not ev.get("ok", false) and str(ev.get("reason", "")) != "":
		acts.add_child(AstralTheme.label(str(ev["reason"]), "CaptionLabel", AstralTheme.MUTED, true))
	return card

func _action_btn(text: String, npc_id: String, action: String, disabled: bool, tip: String) -> Button:
	var b := AstralTheme.button(text, "TabLikeButton", tip)
	b.disabled = disabled
	b.custom_minimum_size.y = 42
	b.pressed.connect(func() -> void: _do_action(npc_id, action))
	return b

func _do_action(npc_id: String, action: String) -> void:
	var res: Dictionary = RelationshipManager.interact_with_candidate(npc_id, action)
	if not res.get("ok", false):
		toast.emit(str(res.get("msg", "")), "warn")
		return
	speak.emit(str(res["speaker"]), "%s\n[color=%s]%s[/color]" % [res["reply"], AstralTheme.hex(AstralTheme.GOLD_PALE), res["effects"]])
	refresh()

# ------------------------------------------------------------------------------
func _refresh_rivals() -> void:
	clear(_rival_box)
	var info := AstralTheme.panel("GlowPanel")
	info.add_child(AstralTheme.label("Los rivales entrenan en espejo: crecen cada bimestre y entrenan más si te ven en su especialidad. En las aulas compartidas se libran choques de aula; además puedes desafiar a un duelo de prestigio (uno por bimestre).", "", AstralTheme.IVORY, true))
	_rival_box.add_child(info)
	for rid in RivalMirror.RIVAL_ORDER:
		var d: Dictionary = RivalMirror.get_data(rid)
		var s: Dictionary = RivalMirror.get_standing(rid)
		var card := AstralTheme.panel("CardPanel")
		var h := AstralTheme.hbox(16)
		card.add_child(h)
		var mid := AstralTheme.vbox(6)
		mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(mid)
		mid.add_child(AstralTheme.label(str(d["full_name"]), "HeadingLabel"))
		mid.add_child(AstralTheme.label("Especialidad: %s" % d["domain"], "CaptionLabel", AstralTheme.MUTED))
		var b1 := StatBar.new()
		b1.setup(GameState.daughter_name, "me", 0, 2400, AstralTheme.GOLD, "", 120)
		mid.add_child(b1)
		b1.set_value(int(s["mine"]), false)
		var b2 := StatBar.new()
		b2.setup(str(d["name"]).split(" ")[0] if rid != "caelum" else "Caelum", "rival", 0, 2400, AstralTheme.ROSE, "", 120)
		mid.add_child(b2)
		b2.set_value(int(s["theirs"]), false)
		var diff: int = int(s["diff"])
		mid.add_child(AstralTheme.label("%s  (%s)" % [s["label"], AstralTheme.signed(diff)], "SubLabel", AstralTheme.GOOD if diff >= 0 else AstralTheme.EMBER, true))
		var btn := AstralTheme.button("%s  Desafiar a duelo" % AstralTheme.G_SWORD, "TabLikeButton",
			"Si tu puntaje iguala o supera al suyo: +150 Oro y +14 al atributo principal. Si no, aprendes (+10) pero te estresas.")
		btn.custom_minimum_size = Vector2(210, 52)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.disabled = RivalMirror.challenged_this_bimester
		var r_id: String = rid
		btn.pressed.connect(func() -> void: _duel(r_id))
		h.add_child(btn)
		_rival_box.add_child(card)

func _duel(rid: String) -> void:
	var res: Dictionary = RivalMirror.challenge_rival_duel(rid)
	if not res.get("ok", false):
		toast.emit(str(res.get("msg", "")), "warn")
		return
	speak.emit(str(res["speaker"]), "%s\n[color=%s]%s[/color]" % [res["reply"], AstralTheme.hex(AstralTheme.GOLD_PALE), res["effects"]])
	toast.emit("¡Victoria de prestigio!" if res["won"] else "Derrota honorable: a entrenar", "good" if res["won"] else "warn")
	refresh()
