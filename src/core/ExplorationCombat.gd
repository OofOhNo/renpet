extends Node

## ExplorationCombat - Sistema de Exploración en 5 Regiones, Combate Táctico por Cartas,
## Botón "Entreabrir el Sello", Festival de las Constelaciones y Eventos de Historia (Fases 7 y 8).

signal combat_updated()
signal combat_finished(victory: bool, summary: String)

var explored_this_bimester: bool = false
var festival_entered_this_year: bool = false
var festival_wins: Array[int] = []
var memory_shards_found: Array[String] = []
var story_acts_seen: Array[int] = []
var unseal_used_count: int = 0

# Las 5 Regiones Concéntricas de Aethelgard
const ZONES: Array[Dictionary] = [
	{
		"id": "zone_1",
		"name": "I. Bosque de los Relojes de Rocío",
		"min_age": 12,
		"difficulty": 1,
		"desc": "Arboledas bioluminiscentes donde antiguos relojes de sol gotean rocío temporal.",
		"enemy_name": "Autómata de Cuarzo Menor",
		"enemy_title": "Centinela de los Jardines",
		"enemy_icon": "res://assets/ui/enemy_construct.png",
		"boss_name": "Ciervo de Relojería Solar",
		"boss_title": "Guardián del Rocío",
		"base_hp": 320,
		"base_atk": 42,
		"stagger_max": 60,
		"gold_reward": 160,
		"loot_id": "comet_dust",
		"shard_id": "shard_1",
		"shard_title": "Esquirla I: El Juramento en la Celda de Cristal",
		"shard_lore": "Ves un eco de hace doce años: cuando tu padre rompió las cadenas de la Diosa Renpet-Neheh, ella sonrió con frialdad al mirar la estrella que ardía sobre el templo..."
	},
	{
		"id": "zone_2",
		"name": "II. Ruinas del Acueducto Solar",
		"min_age": 13,
		"difficulty": 2,
		"desc": "Arcos sumergidos de lapislázuli por donde fluye mercurio líquido y memoria antigua.",
		"enemy_name": "Espectro de Azogue",
		"enemy_title": "Eco de los Canales",
		"enemy_icon": "res://assets/ui/enemy_abyssal.png",
		"boss_name": "Esfinge de los Canales de Plata",
		"boss_title": "Custodia del Acueducto",
		"base_hp": 480,
		"base_atk": 62,
		"stagger_max": 80,
		"gold_reward": 230,
		"loot_id": "mercury_dew",
		"shard_id": "shard_2",
		"shard_title": "Esquirla II: El Mural Borrado",
		"shard_lore": "El mural sumergido muestra a dos luminarias antiguas: la Señora del Oro Inmóvil y un Lucero del Cambio borrado de los anales oficiales. Sus trazos evocan una mirada entrevista en sueños."
	},
	{
		"id": "zone_3",
		"name": "III. Desierto de Cristal Cantante",
		"min_age": 15,
		"difficulty": 3,
		"desc": "Dunas de arena vitrificada que vibran con las canciones de eras congeladas por la Diosa.",
		"enemy_name": "Devorador de Efemérides",
		"enemy_title": "Bestia del Reloj de Arena",
		"enemy_icon": "res://assets/ui/enemy_construct.png",
		"boss_name": "Coloso de Lapislázuli y Oro",
		"boss_title": "Monolito del Desierto",
		"base_hp": 680,
		"base_atk": 85,
		"stagger_max": 100,
		"gold_reward": 310,
		"loot_id": "melted_hourglass",
		"shard_id": "shard_3",
		"shard_title": "Esquirla III: El Molde de Carne y Luz",
		"shard_lore": "Una inscripción secreta describe cómo la Diosa forjó un cuerpo mortal para contener una fuerza que no podía extinguirse. Quien la porta no es solo una elegida: es un receptáculo vivo."
	},
	{
		"id": "zone_4",
		"name": "IV. Cráter de la Primera Caída",
		"min_age": 16,
		"difficulty": 4,
		"desc": "El abismo donde descendió la estrella de Renpet; la gravedad se curva en espirales violetas.",
		"enemy_name": "Sombra del Relicario",
		"enemy_title": "Eco del Lucero Caído",
		"enemy_icon": "res://assets/ui/enemy_abyssal.png",
		"boss_name": "Heraldo del Eclipse Carmesí",
		"boss_title": "Vanguardia Abisal",
		"base_hp": 920,
		"base_atk": 112,
		"stagger_max": 120,
		"gold_reward": 420,
		"loot_id": "sarcophagus_shard",
		"shard_id": "shard_4",
		"shard_title": "Esquirla IV: Las Cadenas del Astro",
		"shard_lore": "En el centro del cráter hallas el primer eslabón dorado: la estrella no cayó por accidente; fue sellada aquí abajo. Si el vínculo permanece intacto a los 20 años, la Diosa reclamará su obra; si se quiebra sin anclaje humano, la oscuridad lo devorará todo."
	},
	{
		"id": "zone_5",
		"name": "V. Observatorio Hundido de Aethel",
		"min_age": 18,
		"difficulty": 5,
		"desc": "El santuario primigenio antes del tiempo, custodiado por los Serafines de la Diosa.",
		"enemy_name": "Serafín del Tiempo Inmóvil",
		"enemy_title": "Inquisidor de la Eternidad",
		"enemy_icon": "res://assets/ui/enemy_guardian.png",
		"boss_name": "Arconte de la Eternidad Dorada",
		"boss_title": "Mano Derecha de la Diosa",
		"base_hp": 1250,
		"base_atk": 145,
		"stagger_max": 150,
		"gold_reward": 600,
		"loot_id": "goddess_tear",
		"shard_id": "shard_5",
		"shard_title": "Esquirla V: El Verdadero Nombre del Tercer Camino",
		"shard_lore": "El códice final revela la Síntesis: cuando el Anclaje Humano y la Sincronía con Zephyr se unen en equilibrio, mortal y estrella dejan de ser jaula y prisionero para volverse soberanos de su propio tiempo."
	}
]

# Las 4 Competiciones del Gran Festival de las Constelaciones de Otoño (Bimestre 4)
const FESTIVAL_CONTESTS: Array[Dictionary] = [
	{
		"id": "contest_blades",
		"name": "⚔  Justa de las Espadas Solares",
		"rival_id": "vespera",
		"rival_name": "Dama Vespera de Val-Astra",
		"stats": ["temple", "destreza", "gravedad"],
		"reward_gold": 300,
		"reward_item": "quartz_marrow",
		"desc": "Combate de exhibición en el Coliseo Real evaluando Temple, Destreza y Gravedad."
	},
	{
		"id": "contest_astrolabe",
		"name": "✦  Certamen del Gran Astrolabio",
		"rival_id": "soren",
		"rival_name": "Soren de Caelum",
		"stats": ["erudicion", "resonancia", "luminiscencia"],
		"reward_gold": 300,
		"reward_item": "melted_hourglass",
		"desc": "Debate de cálculo estelar y predicción temporal evaluando Erudición, Resonancia y Luminiscencia."
	},
	{
		"id": "contest_moons",
		"name": "❀  Danza de las Siete Lunas",
		"rival_id": "lyra",
		"rival_name": "Lady Lyra de Meridia",
		"stats": ["gracia", "magnetismo", "luminiscencia"],
		"reward_gold": 300,
		"reward_item": "goddess_tear",
		"desc": "Gala imperial de música, danza y protocolo evaluando Gracia, Magnetismo y Luminiscencia."
	},
	{
		"id": "contest_clockwork",
		"name": "⚗  Gala Alquímica del Reloj Real",
		"rival_id": "caelum",
		"rival_name": "Caelum 'El Perro Gris'",
		"stats": ["destreza", "erudicion", "resonancia"],
		"reward_gold": 300,
		"reward_item": "comet_dust",
		"desc": "Prueba de precisión táctica, reliquias y reflejos evaluando Destreza, Erudición y Resonancia."
	}
]

# Estado en vivo del Combate Táctico
var in_combat: bool = false
var current_zone: Dictionary = {}
var current_stage: int = 1
var companion_id: String = "vespera"
var companion_name: String = "Dama Vespera"
var companion_bond_bonus: float = 1.0

var player_hp: int = 450
var player_max_hp: int = 450
var player_shield: int = 0
var player_ap: int = 3
var player_max_ap: int = 3
var rewind_charges: int = 1
var unsealed_this_combat: bool = false

var enemy_name: String = ""
var enemy_title: String = ""
var enemy_icon: String = ""
var enemy_hp: int = 300
var enemy_max_hp: int = 300
var enemy_stagger: int = 0
var enemy_max_stagger: int = 60
var enemy_atk: int = 40
var enemy_staggered: bool = false
var combat_log: Array[String] = []

func reset_new_game() -> void:
	explored_this_bimester = false
	festival_entered_this_year = false
	festival_wins.clear()
	memory_shards_found.clear()
	story_acts_seen.clear()
	unseal_used_count = 0
	in_combat = false
	combat_log.clear()

func reset_bimester_flags() -> void:
	explored_this_bimester = false

func reset_year_flags() -> void:
	festival_entered_this_year = false

func get_companion_affinity_bonus(comp_id: String) -> float:
	if not RelationshipManager.state.has(comp_id):
		return 1.0
	var aff: int = int(RelationshipManager.state[comp_id].get("affection", 0))
	if aff >= 65:
		return 1.25
	if aff >= 35:
		return 1.15
	return 1.0

func can_recruit_companion(comp_id: String) -> bool:
	if not RelationshipManager.is_available(comp_id):
		return false
	if not RelationshipManager.state.has(comp_id):
		return true
	var aff: int = int(RelationshipManager.state[comp_id].get("affection", 0))
	return aff > -45

func start_expedition(zone_idx: int, comp_id: String, comp_display_name: String) -> Dictionary:
	if zone_idx < 0 or zone_idx >= ZONES.size():
		return {"ok": false, "msg": "Región inválida."}
	var z: Dictionary = ZONES[zone_idx]
	if GameState.age < int(z["min_age"]):
		return {"ok": false, "msg": "Renpet debe tener al menos %d años para adentrarse en %s." % [int(z["min_age"]), z["name"]]}
	if explored_this_bimester:
		return {"ok": false, "msg": "Renpet ya realizó una expedición fuera de las murallas en este bimestre."}
	if not can_recruit_companion(comp_id):
		return {"ok": false, "msg": "%s siente demasiado rencor hacia Renpet como para acompañarla en batalla." % comp_display_name}

	explored_this_bimester = true
	current_zone = z
	current_stage = 1
	companion_id = comp_id
	companion_name = comp_display_name
	companion_bond_bonus = get_companion_affinity_bonus(comp_id)

	player_max_hp = 180 + GameState.temple * 2 + GameState.gravedad + (40 if GameState.has_mutation("sangre_pesada") else 0)
	player_hp = player_max_hp
	player_shield = 15 if GameState.has_mutation("paso_de_luz") else 0
	player_max_ap = 4 if GameState.has_mutation("paradoja_menor") else 3
	player_ap = player_max_ap
	rewind_charges = 2 if GameState.unlocked_synergies.has("ephemeris_weaver") else 1
	unsealed_this_combat = false

	_setup_stage_enemy(1)
	in_combat = true
	combat_log.clear()
	var bond_note: String = " [Sinergia de Vínculo x%.2f]" % companion_bond_bonus if companion_bond_bonus > 1.0 else ""
	combat_log.append("[color=#FFE082]✦ Expedición iniciada en %s junto a %s%s.[/color]" % [z["name"], companion_name, bond_note])
	combat_updated.emit()
	return {"ok": true}

func _setup_stage_enemy(stage_num: int) -> void:
	current_stage = stage_num
	enemy_stagger = 0
	enemy_staggered = false
	enemy_max_stagger = int(current_zone["stagger_max"])
	if stage_num == 1:
		enemy_name = str(current_zone["enemy_name"])
		enemy_title = "Encuentro 1/2 — " + str(current_zone["enemy_title"])
		enemy_icon = str(current_zone["enemy_icon"])
		enemy_max_hp = int(current_zone["base_hp"])
		enemy_hp = enemy_max_hp
		enemy_atk = int(current_zone["base_atk"])
	else:
		enemy_name = str(current_zone["boss_name"])
		enemy_title = "JEFE DE REGIÓN (2/2) — " + str(current_zone["boss_title"])
		enemy_icon = "res://assets/ui/enemy_guardian.png"
		enemy_max_hp = int(round(int(current_zone["base_hp"]) * 1.45))
		enemy_hp = enemy_max_hp
		enemy_atk = int(round(int(current_zone["base_atk"]) * 1.25))

func play_combat_card(card_id: String) -> void:
	if not in_combat:
		return
	var dmg_mult: float = 1.50 if enemy_staggered else 1.0
	if companion_id == "cassian":
		dmg_mult *= 1.20 * companion_bond_bonus

	match card_id:
		"solar_slash":
			if player_ap < 1:
				combat_log.append("[color=#FF8A80]No tienes suficientes Puntos de Acción (PA).[/color]")
				combat_updated.emit()
				return
			player_ap -= 1
			var base_d: int = 45 + int((GameState.temple + GameState.destreza) * 0.35)
			if companion_id == "vespera":
				base_d = int(round(base_d * 1.25 * companion_bond_bonus))
			var final_d: int = int(round(base_d * dmg_mult))
			var stag_d: int = 28 if companion_id == "vespera" else 18
			_apply_damage_to_enemy(final_d, stag_d, "⚔ Tajo de Horus")

		"lotus_guard":
			if player_ap < 1:
				combat_log.append("[color=#FF8A80]No tienes suficientes PA.[/color]")
				combat_updated.emit()
				return
			player_ap -= 1
			var sh_gain: int = 45 + int((GameState.gracia + GameState.gravedad) * 0.35)
			if companion_id == "cassian":
				sh_gain = int(round(sh_gain * 1.20))
			player_shield += sh_gain
			var heal_v: int = 20 + int(GameState.luminiscencia * 0.12)
			player_hp = mini(player_max_hp, player_hp + heal_v)
			combat_log.append("[color=#80DEEA]❀ Égida de Loto: +%d Escudo Astral y +%d HP restaurado.[/color]" % [sh_gain, heal_v])

		"starlight_ray":
			if player_ap < 2:
				combat_log.append("[color=#FF8A80]Cometa de Sothis requiere 2 PA.[/color]")
				combat_updated.emit()
				return
			player_ap -= 2
			var base_d: int = 95 + int((GameState.luminiscencia + GameState.erudicion) * 0.52)
			if companion_id == "soren":
				base_d = int(round(base_d * 1.25 * companion_bond_bonus))
			var final_d: int = int(round(base_d * dmg_mult))
			_apply_damage_to_enemy(final_d, 32, "✦ Cometa de Sothis")

		"chrono_flux":
			if player_ap < 1:
				combat_log.append("[color=#FF8A80]Requiere 1 PA.[/color]")
				combat_updated.emit()
				return
			player_ap -= 1
			var base_d: int = 40 + int(GameState.resonancia * 0.45)
			var final_d: int = int(round(base_d * dmg_mult))
			player_shield += 25
			_apply_damage_to_enemy(final_d, 22, "⏳ Pulso de Relojería")

		"companion_skill":
			if player_ap < 1:
				combat_log.append("[color=#FF8A80]Requiere 1 PA.[/color]")
				combat_updated.emit()
				return
			player_ap -= 1
			_execute_companion_active_skill(dmg_mult * companion_bond_bonus)

		"rewind":
			if rewind_charges <= 0:
				combat_log.append("[color=#FF8A80]No te quedan cargas de Rebobinado Temporal en esta expedición.[/color]")
				combat_updated.emit()
				return
			rewind_charges -= 1
			var heal_r: int = int(player_max_hp * 0.40)
			player_hp = mini(player_max_hp, player_hp + heal_r)
			player_ap = mini(player_max_ap + 1, player_ap + 2)
			player_shield += 40
			combat_log.append("[color=#FFF176]☾ REBOBINADO TEMPORAL: El reloj gira hacia atrás (+%d HP, +40 Escudo, +2 PA).[/color]" % heal_r)

		"unseal":
			# EL BOTÓN TENTADOR: LIBERAR LA RESONANCIA OCULTA / ENTREABRIR EL SELLO (0 PA)
			var seal_cost: int = -4 if companion_id == "zephyr" else -8
			GameState.modify_stat("seal_integrity", seal_cost)
			GameState.modify_stat("abyssal_sync", 7)
			unsealed_this_combat = true
			unseal_used_count += 1
			var abyssal_dmg: int = 180 + int((GameState.gravedad + GameState.resonancia + GameState.abyssal_sync * 4) * 0.65)
			player_hp = mini(player_max_hp, player_hp + int(player_max_hp * 0.35))
			player_ap += 2
			if GameState.get_secret_tier() >= 2:
				Chronicle.record_event("unseal_combat_%d" % unseal_used_count, "El Sello Entreabierto en Batalla", "Para derrotar a %s, %s liberó el fuego violeta de Nyx-Aethel (%d%% Sello)." % [enemy_name, GameState.daughter_name, seal_cost], "twist", 5)
				combat_log.append("[color=#FF80AB][b]☥ ¡SELLO ENTREABIERTO! Fulgor de Nyx-Aethel (%d%% Sello, +7%% Sincronía, +2 PA)[/b][/color]" % seal_cost)
				_apply_damage_to_enemy(abyssal_dmg, 999, "☥ Eclipse de Nyx-Aethel")
			else:
				Chronicle.record_event("unseal_combat_%d" % unseal_used_count, "Fulgor Violeta en Batalla", "Para derrotar a %s, %s liberó una llamarada desconocida de su propia marca (%d%% Resguardo)." % [enemy_name, GameState.daughter_name, seal_cost], "mystery", 5)
				combat_log.append("[color=#FF80AB][b]☥ ¡RESONANCIA LIBERADA! Llamarada del Eclipse (%d%% %s, +7%% Vínculo, +2 PA)[/b][/color]" % [seal_cost, GameState.get_stat_label("seal_integrity")])
				_apply_damage_to_enemy(abyssal_dmg, 999, "☥ Llamarada del Eclipse")

	_check_enemy_defeat_or_continue()

func _execute_companion_active_skill(dmg_mult: float) -> void:
	match companion_id:
		"vespera":
			var d: int = int(round((70 + GameState.temple * 0.35) * dmg_mult))
			_apply_damage_to_enemy(d, 40, "⚔ Lanza Ducal de Vespera")
		"soren":
			var d: int = int(round((65 + GameState.erudicion * 0.35) * dmg_mult))
			player_shield += 35
			_apply_damage_to_enemy(d, 30, "✦ Refractor Astral de Soren")
		"kaelen":
			var d: int = int(round((65 + GameState.destreza * 0.35) * dmg_mult))
			GameState.modify_gold(35)
			_apply_damage_to_enemy(d, 25, "⚡ Emboscada de Azogue de Kaelen (+35G)")
		"cassian":
			var d: int = int(round((75 + GameState.magnetismo * 0.35) * dmg_mult))
			player_shield += 40
			_apply_damage_to_enemy(d, 25, "☀ Mandato Solar de Cassian")
		"mirari":
			var heal_m: int = int(round((75 + GameState.luminiscencia * 0.25) * companion_bond_bonus))
			player_hp = mini(player_max_hp, player_hp + heal_m)
			player_shield += 50
			GameState.modify_stat("seal_integrity", 2)
			combat_log.append("[color=#81C784]❀ Arpa de Mirari: +%d HP, +50 Escudo y +2%% %s.[/color]" % [heal_m, GameState.get_stat_label("seal_integrity")])
		"zephyr":
			var d: int = int(round((95 + GameState.resonancia * 0.45) * dmg_mult))
			_apply_damage_to_enemy(d, 35, "☥ Cadenas del Espejo de Zephyr")

func _apply_damage_to_enemy(dmg: int, stagger_add: int, skill_label: String) -> void:
	enemy_hp = maxi(0, enemy_hp - dmg)
	if not enemy_staggered:
		var bonus_stagger: int = 15 if companion_id == "soren" else 0
		enemy_stagger += stagger_add + bonus_stagger
		if enemy_stagger >= enemy_max_stagger:
			enemy_stagger = enemy_max_stagger
			enemy_staggered = true
			combat_log.append("[color=#FFF176]✦ ¡QUIEBRE DE GUARDIA! %s queda aturdido (Daño x1.5 y pierde su turno).[/color]" % enemy_name)
	combat_log.append("%s inflige [b]%d[/b] de daño a %s." % [skill_label, dmg, enemy_name])

func end_player_turn() -> void:
	if not in_combat:
		return
	if enemy_staggered:
		combat_log.append("[color=#81C784]%s está aturdido por el Quiebre y no puede atacar este turno.[/color]" % enemy_name)
		enemy_staggered = false
		enemy_stagger = 0
	else:
		var incoming: int = enemy_atk
		if GameState.has_mutation("sangre_pesada"):
			incoming = maxi(1, int(round(incoming * 0.85)))
		var dodge_chance: int = (25 if companion_id == "kaelen" else 0) + (18 if GameState.has_mutation("paso_de_luz") else 0)
		if dodge_chance > 0 and (randi() % 100) < dodge_chance:
			var dodge_src: String = "Cortina de humo de Kaelen" if companion_id == "kaelen" else "Paso de Luz"
			combat_log.append("[color=#80DEEA]¡%s! Esquivaste por completo el ataque de %s.[/color]" % [dodge_src, enemy_name])
		else:
			var blocked: int = mini(player_shield, incoming)
			player_shield -= blocked
			var hp_loss: int = incoming - blocked
			player_hp = maxi(0, player_hp - hp_loss)
			combat_log.append("[color=#FF8A80]%s ataca: %d daño (%d absorbido por Escudo).[/color]" % [enemy_name, hp_loss, blocked])

	if GameState.has_mutation("pulso_cristalino") and player_hp > 0:
		var m_regen: int = maxi(1, int(player_max_hp * 0.08))
		player_hp = mini(player_max_hp, player_hp + m_regen)
		combat_log.append("[color=#80DEEA]✦ Pulso Cristalino regenera +%d HP.[/color]" % m_regen)

	if companion_id == "mirari" and player_hp > 0:
		var regen: int = int(player_max_hp * 0.15)
		player_hp = mini(player_max_hp, player_hp + regen)
		combat_log.append("[color=#81C784]❀ Canto de Mirari regenera +%d HP.[/color]" % regen)

	if player_hp <= 0:
		in_combat = false
		GameState.modify_stat("stress", 18)
		var defeat_msg: String = "%s tuvo que retirarse de %s tras caer agotada (+18 Estrés)." % [GameState.daughter_name, current_zone["name"]]
		combat_finished.emit(false, defeat_msg)
		return

	player_ap = player_max_ap
	player_shield = int(player_shield * 0.35) + (15 if GameState.has_mutation("paso_de_luz") else 0)
	combat_updated.emit()

func retreat_from_combat() -> void:
	if not in_combat:
		return
	in_combat = false
	GameState.modify_stat("stress", 8)
	var msg: String = "%s y %s se retiraron estratégicamente de %s (+8 Estrés)." % [GameState.daughter_name, companion_name, current_zone["name"]]
	combat_finished.emit(false, msg)

func _check_enemy_defeat_or_continue() -> void:
	if enemy_hp > 0:
		combat_updated.emit()
		return

	if current_stage == 1:
		var shard_id: String = current_zone["shard_id"]
		var shard_msg: String = ""
		if not memory_shards_found.has(shard_id):
			memory_shards_found.append(shard_id)
			GameState.memory_shards_found = memory_shards_found.size()
			GameState.modify_stat("seal_investigation", 15)
			Chronicle.record_event(shard_id, current_zone["shard_title"], current_zone["shard_lore"], "twist", 5)
			shard_msg = "\n[color=#FFF176][b]✦ %s (+15%% %s):[/b]\n%s[/color]" % [
				current_zone["shard_title"], GameState.get_stat_label("seal_investigation"), current_zone["shard_lore"]
			]
		_setup_stage_enemy(2)
		player_ap = player_max_ap
		combat_log.append("[color=#81C784]¡Vanguardia derrotada! Avanzas al santuario interior: aparece [b]%s[/b].[/color]%s" % [enemy_name, shard_msg])
		combat_updated.emit()
	else:
		in_combat = false
		var gold_won: int = int(current_zone["gold_reward"])
		if companion_id == "kaelen":
			gold_won = int(round(gold_won * 1.40))
		GameState.modify_gold(gold_won)
		GameState.modify_stat("temple", 16)
		GameState.modify_stat("resonancia", 16)
		var loot_key: String = current_zone["loot_id"]
		GameState.materials_inventory[loot_key] = GameState.materials_inventory.get(loot_key, 0) + 1
		Chronicle.record_event("exp_win_" + str(current_zone["id"]), "Conquista de " + str(current_zone["name"]), "%s y %s derrotaron a %s." % [GameState.daughter_name, companion_name, enemy_name], "expedition", 4)
		var mat_name: String = str(CatalogDB.get_material(loot_key).get("name", loot_key))
		var win_summary: String = "¡Victoria en %s! Derrotaste a %s junto a %s.\nRecompensas: +%d Oro, +16 Temple, +16 Resonancia y +1 %s para el Crisol Astral." % [
			current_zone["name"], enemy_name, companion_name, gold_won, mat_name
		]
		combat_finished.emit(true, win_summary)

# ==============================================================================
# LÓGICA DEL GRAN FESTIVAL DE LAS CONSTELACIONES DE OTOÑO (FASE 8)
# ==============================================================================
func get_festival_preview(contest_idx: int) -> Dictionary:
	if contest_idx < 0 or contest_idx >= FESTIVAL_CONTESTS.size():
		return {"my_total": 0, "target_score": 0}
	var c: Dictionary = FESTIVAL_CONTESTS[contest_idx]
	var stat_list: Array = c["stats"]
	var my_total: int = 0
	for sk in stat_list:
		my_total += int(GameState.get_stat(str(sk)))
	if GameState.unlocked_synergies.has("horizon_valkyrie") and c["id"] == "contest_blades":
		my_total += 60
	var r_id: String = str(c["rival_id"])
	var riv_base: int = RivalMirror.get_rival_score(r_id)
	var target_score: int = int(round(float(riv_base) * 1.35))
	return {"my_total": my_total, "target_score": target_score}

func participate_in_festival(contest_idx: int) -> Dictionary:
	if not TimeManager.is_festival_bimester():
		return {"ok": false, "msg": "El Gran Festival de las Constelaciones se celebra en el 4º Bimestre (Cosecha, Equinoccio de Otoño). Aún puedes prepararte."}
	if festival_entered_this_year:
		return {"ok": false, "msg": "%s ya compitió en el certamen oficial del Festival de Otoño de este año." % GameState.daughter_name}
	if contest_idx < 0 or contest_idx >= FESTIVAL_CONTESTS.size():
		return {"ok": false, "msg": "Certamen inválido."}

	festival_entered_this_year = true
	var c: Dictionary = FESTIVAL_CONTESTS[contest_idx]
	var prev: Dictionary = get_festival_preview(contest_idx)
	var my_total: int = int(prev["my_total"])
	var target_score: int = int(prev["target_score"])
	var won: bool = my_total >= target_score

	if won:
		var g_rew: int = int(c["reward_gold"])
		var item_k: String = str(c["reward_item"])
		GameState.modify_gold(g_rew)
		GameState.modify_stat("magnetismo", 24)
		GameState.modify_stat("affection", 10)
		GameState.modify_stat("father_reputation", 6)
		GameState.materials_inventory[item_k] = int(GameState.materials_inventory.get(item_k, 0)) + 1
		if not festival_wins.has(TimeManager.current_year):
			festival_wins.append(TimeManager.current_year)
		Chronicle.record_event("festival_champion_%d" % TimeManager.current_year, "Campeona del Festival de Otoño (%s)" % c["name"], "%s venció a %s con %d pts frente a %d pts." % [GameState.daughter_name, c["rival_name"], my_total, target_score], "festival", 5)
		var mat_name: String = str(CatalogDB.get_material(item_k).get("name", item_k))
		return {
			"ok": true,
			"won": true,
			"title": "✦  ¡CAMPEONA DEL FESTIVAL DE LAS CONSTELACIONES!  ✦",
			"summary": "¡%s deslumbró a toda la capital en [b]%s[/b], superando a %s (%d pts vs %d pts)!\n\n[color=#86e3a6]Premio Imperial: +%d Oro, +24 Magnetismo, +10 Afecto, +6 Reputación y +1 %s para el Crisol.[/color]" % [
				GameState.daughter_name, c["name"], c["rival_name"], my_total, target_score, g_rew, mat_name
			]
		}
	else:
		GameState.modify_gold(80)
		var stat_list: Array = c["stats"]
		GameState.modify_stat(str(stat_list[0]), 15)
		Chronicle.record_event("festival_runner_%d" % TimeManager.current_year, "Finalista en el Festival (%s)" % c["name"], "%s obtuvo el segundo puesto tras %s (%d vs %d)." % [GameState.daughter_name, c["rival_name"], my_total, target_score], "festival", 3)
		return {
			"ok": true,
			"won": false,
			"title": "✧  Segundo Puesto en el Coliseo de las Constelaciones  ✧",
			"summary": "%s dio una gran demostración en [b]%s[/b], pero %s se llevó la corona por %d a %d.\n\n[color=#f7e3a1]Premio de Finalista: +80 Oro y +15 %s por la experiencia.[/color]" % [
				GameState.daughter_name, c["name"], c["rival_name"], target_score, my_total, GameState.get_stat_label(str(stat_list[0]))
			]
		}

# ==============================================================================
# EVENTOS DE HISTORIA PRINCIPAL — ACTOS I, II Y III + EL GRAN GIRO (FASE 8)
# ==============================================================================
func check_pending_main_story_event() -> Dictionary:
	# Acto I (Edad 13): La Primera Fisura del Firmamento
	if GameState.age >= 13 and not story_acts_seen.has(13):
		return {
			"has_event": true,
			"act_id": 13,
			"is_twist": false,
			"title": "✦  ACTO I (EDAD 13): LA PRIMERA FISURA DEL FIRMAMENTO  ✦",
			"body": "Durante la lluvia de meteoros de primavera, una corona de chispas doradas brota sin querer de las manos de %s y hace levitar los libros de tu escritorio.\n\n«¡No sé qué acaba de pasar, Padre! Sentí un reloj antiguo haciendo tic-tac dentro de mis costillas... ¿Los demás niños también tienen estrellas bajo la piel?»" % GameState.daughter_name,
			"choices": [
				{
					"label": "♥ Abrazarla y contarle una historia terrenal sobre cómo cayó en tus brazos (+10 Anclaje Humano, +8 Afecto, -10 Estrés)",
					"effects": {"human_anchor": 10, "affection": 8, "stress": -10},
					"outcome": "%s apoya la cabeza en tu pecho hasta que el zumbido estelar se calma en un latido humano." % GameState.daughter_name
				},
				{
					"label": "✦ Medir la frecuencia de su pulso astral con el astrolabio de la casa (+15 Luminiscencia, +12 Resonancia, +10%% Investigación)",
					"effects": {"luminiscencia": 15, "resonancia": 12, "seal_investigation": 10},
					"outcome": "Registras las ecuaciones de su luz: los trazos coinciden con mapas estelares olvidados anteriores al reino de Aethelgard."
				},
				{
					"label": "⚔ Enseñarle a contener la energía mediante disciplina marcial (+15 Temple, +4%% Resguardo Astral)",
					"effects": {"temple": 15, "seal_integrity": 4},
					"outcome": "%s aprende a respirar como un guardián veterano y aplaca las chispas con firmeza." % GameState.daughter_name
				}
			]
		}

	# Acto I -> II (Edad 14): El Despertar del Espejo Estelar
	if GameState.age >= 14 and not story_acts_seen.has(14):
		return {
			"has_event": true,
			"act_id": 14,
			"is_twist": false,
			"title": "☥  ACTO II (EDAD 14): EL DESPERTAR DEL ESPEJO ESTELAR  ☥",
			"body": "En la noche del Equinoccio, el observatorio entero tiembla. La marca estelar en el pecho de %s brilla con jeroglíficos dorados y, por un segundo, el espejo del salón refleja una silueta encadenada tras una bruma violeta.\n\n«Papá... hay alguien más mirando desde mi reflejo. Dice que la Diosa nos oculta algo sobre la noche en que caí del cielo.»" % GameState.daughter_name,
			"choices": [
				{
					"label": "♥ Jurarle protección: «Pase lo que pase, siempre serás mi hija.» (+12 Anclaje Humano, -15 Estrés, +10 Afecto)",
					"effects": {"human_anchor": 12, "stress": -15, "affection": 10},
					"outcome": "Las lágrimas de %s apagan el fulgor frío; tu amor levanta un escudo alrededor de su corazón mortal." % GameState.daughter_name
				},
				{
					"label": "❖ Copiar los jeroglíficos del reflejo para investigarlos en secreto (+15%% Investigación del Enigma, +20 Erudición)",
					"effects": {"seal_investigation": 15, "erudicion": 20},
					"outcome": "Descubres que los glifos pertenecen a una escritura anterior a la corona solar. Alguien borró este capítulo de todas las bibliotecas."
				},
				{
					"label": "☾ Enseñarle a escuchar esa presencia sin temor ni prejuicios (+14 Vínculo con el Espejo, +20 Resonancia)",
					"effects": {"abyssal_sync": 14, "resonancia": 20},
					"outcome": "Por primera vez, la silueta tras el espejo no se oculta: asiente en silencio, expectante."
				}
			]
		}

	# Acto II -> III (Edad 17): EL GRAN GIRO — LA ESTRELLA ERA UNA PRISIÓN
	if GameState.age >= 17 and not story_acts_seen.has(17):
		return {
			"has_event": true,
			"act_id": 17,
			"is_twist": true,
			"title": "☾  EL GRAN GIRO (EDAD 17): «LA ESTRELLA ERA UNA PRISIÓN»  ☾",
			"body": "Un Heraldo de la Diosa de la Eternidad desciende sobre el balcón del observatorio entre relojes de oro suspendidos en el aire. Con voz de campanas heladas anuncia que solo quedan tres años para la Cosecha:\n\n«Héroe %s, la estrella que recibiste hace diecisiete años era el Sarcófago Celestial donde encerramos a Nyx-Aethel, el espíritu del Cambio. Tu crianza ha servido para madurar el Sello. Cuando %s cumpla veinte años, la Diosa absorberá a ambos para congelar el tiempo para siempre.»" % [GameState.father_name, GameState.daughter_name],
			"choices": [
				{
					"label": "⚔ Desenvainar tu arma de Héroe: «¡Desafiaré a la misma Diosa que liberé antes de entregarle a mi hija!» (+15 Anclaje Humano, +25 Temple, +15 Afecto)",
					"effects": {"human_anchor": 15, "temple": 25, "affection": 15},
					"outcome": "El Heraldo retrocede ante tu aura de leyenda. %s toma tu mano, dispuesta a luchar contra el cielo mismo." % GameState.daughter_name
				},
				{
					"label": "✦ Forjar el Pacto del Tercer Camino con Zephyr y los planos del Sello (+20%% Investigación, +15 Sincronía, +10 Anclaje)",
					"effects": {"seal_investigation": 20, "abyssal_sync": 15, "human_anchor": 10},
					"outcome": "Comprendes que la única salida para salvar tanto a %s como a Nyx-Aethel es unir ambos mundos." % GameState.daughter_name
				},
				{
					"label": "☠ Dejar que la ira del Sarcófago agriete el Sello frente al Heraldo (-15%% Sello, +20 Sincronía, +30 Gravedad)",
					"effects": {"seal_integrity": -15, "abyssal_sync": 20, "gravedad": 30},
					"outcome": "Una onda de gravedad violeta rompe las losas del balcón y ahuyenta al Heraldo entre relámpagos oscuros."
				}
			]
		}

	# Acto III (Edad 19): La Víspera del Solsticio Final
	if GameState.age >= 19 and not story_acts_seen.has(19):
		return {
			"has_event": true,
			"act_id": 19,
			"is_twist": false,
			"title": "☀  ACTO III (EDAD 19): LA VÍSPERA DEL SOLSTICIO FINAL  ☀",
			"body": "Queda menos de un año para el vigésimo cumpleaños de %s. Los astrónomos de Aethelgard observan cómo la esfera armilar real gira en sentido inverso. Tu hija te espera en el observatorio mirando el horizonte nocturno:\n\n«Padre... el tiempo casi se agota. ¿Cómo nos recordará el mundo cuando la Diosa descienda a reclamar su deuda?»" % GameState.daughter_name,
			"choices": [
				{
					"label": "♥ «Como una familia que eligió vivir libre cada día que le fue dado.» (+10 Anclaje Humano, +10 Afecto, +15 Luminiscencia)",
					"effects": {"human_anchor": 10, "affection": 10, "luminiscencia": 15},
					"outcome": "El corazón de %s brilla con una calidez dorada que ni la eternidad helada podría apagar." % GameState.daughter_name
				},
				{
					"label": "⏳ «Reescribiremos el mecanismo del Reloj Divino antes de la medianoche.» (+15%% Investigación, +25 Resonancia)",
					"effects": {"seal_investigation": 15, "resonancia": 25},
					"outcome": "Afinan los últimos cálculos de la Bóveda Estelar para el enfrentamiento inevitable de los veinte años."
				},
				{
					"label": "⚡ «Que tiemblen los dioses: nuestro poder unido no se arrodillará.» (+25 Gravedad, +10 Sincronía con Zephyr)",
					"effects": {"gravedad": 25, "abyssal_sync": 10},
					"outcome": "Las estrellas sobre la mansión titilan en rojo y violeta respondiendo a la determinación de padre e hija."
				}
			]
		}

	return {"has_event": false}

func apply_story_event_choice(act_id: int, choice: Dictionary) -> String:
	if not story_acts_seen.has(act_id):
		story_acts_seen.append(act_id)
	var effects: Dictionary = choice.get("effects", {})
	var labels: Array[String] = []
	for k in effects.keys():
		var delta: int = int(effects[k])
		GameState.modify_stat(str(k), delta)
		labels.append("%s %+d" % [GameState.get_stat_label(str(k)), delta])
	var outcome: String = str(choice.get("outcome", ""))
	if act_id == 17:
		Chronicle.record_event("twist_year_17", "EL GRAN GIRO: La Estrella era una Prisión", outcome, "twist", 5)
	else:
		Chronicle.record_event("story_act_%d" % act_id, "Hito de Historia (Edad %d)" % act_id, outcome, "lore", 5)
	return ", ".join(labels)

# ==============================================================================
# SERIALIZACIÓN PARA GUARDADO Y CARGA
# ==============================================================================
func serialize() -> Dictionary:
	return {
		"explored_this_bimester": explored_this_bimester,
		"festival_entered_this_year": festival_entered_this_year,
		"festival_wins": festival_wins.duplicate(),
		"memory_shards_found": memory_shards_found.duplicate(),
		"story_acts_seen": story_acts_seen.duplicate(),
		"unseal_used_count": unseal_used_count
	}

func deserialize(d: Dictionary) -> void:
	reset_new_game()
	explored_this_bimester = bool(d.get("explored_this_bimester", false))
	festival_entered_this_year = bool(d.get("festival_entered_this_year", false))
	unseal_used_count = int(d.get("unseal_used_count", 0))
	for w in d.get("festival_wins", []):
		festival_wins.append(int(w))
	for s in d.get("memory_shards_found", []):
		memory_shards_found.append(str(s))
	GameState.memory_shards_found = memory_shards_found.size()
	for a in d.get("story_acts_seen", []):
		story_acts_seen.append(int(a))
