extends Node

## ExplorationCombat - Sistema de Exploración en 5 Regiones, Combate Táctico por Cartas,
## Botón "Entreabrir el Sello", Festival de las Constelaciones y Eventos de Historia (Fases 7 y 8).

signal combat_updated()
signal combat_fx(kind: String)
signal combat_finished(victory: bool, summary: String)
signal expedition_node_ready(node_info: Dictionary)

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
		"boss_icon": "res://assets/ui/boss_deer.png",
		"bypass_mut": "paso_de_luz",
		"check_stat": "destreza", "check_val": 160,
		"base_hp": 320,
		"base_atk": 42,
		"stagger_max": 60,
		"gold_reward": 160,
		"loot_id": "comet_dust",
		"shard_id": "shard_1",
		"shard_title": "Vestigio I: El Juramento Antiguo",
		"shard_lore": "Ves un eco de hace doce años: bajo la luz plateada de las ruinas, la Diosa contemplaba la estrella caída sobre el templo con una sonrisa inescrutable..."
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
		"boss_icon": "res://assets/ui/boss_sphinx.png",
		"bypass_mut": "sangre_pesada",
		"check_stat": "temple", "check_val": 210,
		"base_hp": 480,
		"base_atk": 62,
		"stagger_max": 80,
		"gold_reward": 230,
		"loot_id": "mercury_dew",
		"shard_id": "shard_2",
		"shard_title": "Vestigio II: El Mural Borrado",
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
		"boss_icon": "res://assets/ui/boss_colossus.png",
		"bypass_mut": "pulso_cristalino",
		"check_stat": "erudicion", "check_val": 270,
		"base_hp": 680,
		"base_atk": 85,
		"stagger_max": 100,
		"gold_reward": 310,
		"loot_id": "melted_hourglass",
		"shard_id": "shard_3",
		"shard_title": "Vestigio III: El Molde de Carne y Luz",
		"shard_lore": "Una inscripción incompleta describe cómo el cielo antiguo forjó un cuerpo mortal para guardar una luz que no podía apagarse. Quien la porta carga un destino doble."
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
		"boss_icon": "res://assets/ui/boss_herald.png",
		"bypass_mut": "voz_del_prisionero",
		"check_stat": "resonancia", "check_val": 330,
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
		"boss_icon": "res://assets/ui/boss_archon.png",
		"bypass_mut": "bendicion_del_tiempo",
		"check_stat": "luminiscencia", "check_val": 420,
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

# Estado en vivo del Combate Táctico y Ruta de 4 Nodos
var in_expedition: bool = false
var in_combat: bool = false
var current_zone: Dictionary = {}
var current_stage: int = 1
var current_node: int = 1     # 1 = Vanguardia, 2 = Encrucijada, 3 = Santuario, 4 = Jefe
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
var next_atk_bonus_pct: float = 0.0
var bonus_boss_ap: int = 0
var node_event_data: Dictionary = {}
var used_memory_cards: Array[String] = []
var festival_match: Dictionary = {}

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
	in_expedition = false
	in_combat = false
	current_node = 1
	next_atk_bonus_pct = 0.0
	bonus_boss_ap = 0
	node_event_data.clear()
	used_memory_cards.clear()
	festival_match.clear()
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
	if comp_id == "solo" or comp_id == "":
		return true
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
		return {"ok": false, "msg": "%s debe tener al menos %d años para adentrarse en %s." % [GameState.daughter_name, int(z["min_age"]), z["name"]]}
	if explored_this_bimester:
		return {"ok": false, "msg": "%s ya realizó una expedición fuera de las murallas en este bimestre." % GameState.daughter_name}
	if comp_id != "solo" and comp_id != "":
		if not RelationshipManager.is_available(comp_id):
			return {"ok": false, "msg": RelationshipManager.get_locked_reason(comp_id)}
		if not can_recruit_companion(comp_id):
			return {"ok": false, "msg": "%s siente demasiado rencor hacia %s como para acompañarla en batalla." % [comp_display_name, GameState.daughter_name]}

	explored_this_bimester = true
	in_expedition = true
	current_zone = z
	current_stage = 1
	current_node = 1
	companion_id = comp_id
	companion_name = comp_display_name
	companion_bond_bonus = get_companion_affinity_bonus(comp_id)

	var outfit_hp: int = int(round(GameState.get_outfit_mod("combat_hp", 0.0)))
	var outfit_sh: int = int(round(GameState.get_outfit_mod("combat_shield", 0.0)))
	player_max_hp = 180 + GameState.temple * 2 + GameState.gravedad + (40 if GameState.has_mutation("sangre_pesada") else 0) + outfit_hp
	player_hp = player_max_hp
	player_shield = (15 if GameState.has_mutation("paso_de_luz") else 0) + outfit_sh
	player_max_ap = 4 if GameState.has_mutation("paradoja_menor") else 3
	player_ap = player_max_ap + (1 if GameState.has_mutation("bendicion_del_tiempo") else 0)
	rewind_charges = 2 if GameState.unlocked_synergies.has("ephemeris_weaver") else 1
	unsealed_this_combat = false
	next_atk_bonus_pct = 0.0
	bonus_boss_ap = 0
	node_event_data.clear()
	used_memory_cards.clear()

	_setup_stage_enemy(1)
	in_combat = true
	combat_log.clear()
	var bond_note: String = " [Sinergia de Vínculo x%.2f]" % companion_bond_bonus if companion_bond_bonus > 1.0 else ""
	combat_log.append("[color=#FFE082]✦ Expedición de 4 Nodos iniciada en %s junto a %s%s.[/color]" % [z["name"], companion_name, bond_note])
	if outfit_hp > 0:
		combat_log.append("[color=#80DEEA]◈ Cota del Horizonte activa: +%d HP máx. y +%d Escudo inicial.[/color]" % [outfit_hp, outfit_sh])
	combat_updated.emit()
	return {"ok": true}

func _setup_stage_enemy(stage_num: int) -> void:
	current_stage = stage_num
	used_memory_cards.clear()
	enemy_stagger = 0
	enemy_staggered = false
	enemy_max_stagger = int(current_zone["stagger_max"])
	if stage_num == 1:
		current_node = 1
		enemy_name = str(current_zone["enemy_name"])
		enemy_title = "Nodo 1/4 (Vanguardia) — " + str(current_zone["enemy_title"])
		enemy_icon = str(current_zone["enemy_icon"])
		enemy_max_hp = int(current_zone["base_hp"])
		enemy_hp = enemy_max_hp
		enemy_atk = int(current_zone["base_atk"])
	else:
		current_node = 4
		enemy_name = str(current_zone["boss_name"])
		enemy_title = "Nodo 4/4 (JEFE) — " + str(current_zone["boss_title"])
		enemy_icon = str(current_zone.get("boss_icon", "res://assets/ui/enemy_guardian.png"))
		enemy_max_hp = int(round(int(current_zone["base_hp"]) * 1.45))
		enemy_hp = enemy_max_hp
		enemy_atk = int(round(int(current_zone["base_atk"]) * 1.25))

func play_combat_card(card_id: String) -> void:
	if not in_combat:
		return
	if card_id.begins_with("mem_"):
		_play_memory_card(card_id)
		return
	var dmg_mult: float = (1.50 if enemy_staggered else 1.0) * (1.0 + GameState.get_outfit_mod("combat_atk_pct", 0.0) + next_atk_bonus_pct)
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
			next_atk_bonus_pct = 0.0
			var stag_d: int = 28 if companion_id == "vespera" else 18
			combat_fx.emit("slash")
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
			combat_fx.emit("shield")

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
			next_atk_bonus_pct = 0.0
			combat_fx.emit("magic")
			_apply_damage_to_enemy(final_d, 32, "✦ Cometa de Sothis")

		"chrono_flux":
			if player_ap < 1:
				combat_log.append("[color=#FF8A80]Requiere 1 PA.[/color]")
				combat_updated.emit()
				return
			player_ap -= 1
			var base_d: int = 40 + int(GameState.resonancia * 0.45)
			var final_d: int = int(round(base_d * dmg_mult))
			next_atk_bonus_pct = 0.0
			player_shield += 25
			combat_fx.emit("magic")
			_apply_damage_to_enemy(final_d, 22, "⏳ Pulso de Relojería")

		"companion_skill":
			if player_ap < 1:
				combat_log.append("[color=#FF8A80]Requiere 1 PA.[/color]")
				combat_updated.emit()
				return
			player_ap -= 1
			combat_fx.emit("magic")
			_execute_companion_active_skill(dmg_mult * companion_bond_bonus)
			next_atk_bonus_pct = 0.0

		"rewind":
			if rewind_charges <= 0:
				combat_log.append("[color=#FF8A80]No te quedan cargas de Rebobinado Temporal en esta expedición.[/color]")
				combat_updated.emit()
				return
			rewind_charges -= 1
			var heal_r: int = int(player_max_hp * 0.40)
			player_hp = mini(player_max_hp, player_hp + heal_r)
			player_ap = mini(player_max_ap + 2, player_ap + 2)
			player_shield += 40
			combat_log.append("[color=#FFF176]☾ REBOBINADO TEMPORAL: El reloj gira hacia atrás (+%d HP, +40 Escudo, +2 PA).[/color]" % heal_r)
			combat_fx.emit("shield")

		"unseal":
			var seal_cost: int = -4 if companion_id == "zephyr" else -8
			GameState.modify_stat("seal_integrity", seal_cost)
			GameState.modify_stat("abyssal_sync", 7)
			unsealed_this_combat = true
			unseal_used_count += 1
			var abyssal_dmg: int = 180 + int((GameState.gravedad + GameState.resonancia + GameState.abyssal_sync * 4) * 0.65)
			if GameState.has_mutation("voz_del_prisionero"):
				abyssal_dmg = int(round(abyssal_dmg * 1.20))
			player_hp = mini(player_max_hp, player_hp + int(player_max_hp * 0.35))
			player_ap += 2
			combat_fx.emit("unseal")
			if GameState.get_secret_tier() >= 2:
				Chronicle.record_event("unseal_combat_%d" % unseal_used_count, "El Sello Entreabierto en Batalla", "Para derrotar a %s, %s liberó el fuego violeta de Nyx-Aethel (%d%% Sello)." % [enemy_name, GameState.daughter_name, seal_cost], "twist", 5)
				combat_log.append("[color=#FF80AB][b]☥ ¡SELLO ENTREABIERTO! Fulgor de Nyx-Aethel (%d%% Sello, +7%% Sincronía, +2 PA)[/b][/color]" % seal_cost)
				_apply_damage_to_enemy(abyssal_dmg, 999, "☥ Eclipse de Nyx-Aethel")
			else:
				Chronicle.record_event("unseal_combat_%d" % unseal_used_count, "Fulgor Violeta en Batalla", "Para derrotar a %s, %s liberó una llamarada desconocida de su propia marca (%d%% Resguardo)." % [enemy_name, GameState.daughter_name, seal_cost], "mystery", 5)
				combat_log.append("[color=#FF80AB][b]☥ ¡RESONANCIA LIBERADA! Llamarada del Eclipse (%d%% %s, +7%% Vínculo, +2 PA)[/b][/color]" % [seal_cost, GameState.get_stat_label("seal_integrity")])
				_apply_damage_to_enemy(abyssal_dmg, 999, "☥ Llamarada del Eclipse")

	_check_enemy_defeat_or_continue()

func _play_memory_card(card_id: String) -> void:
	var card: Dictionary = CatalogDB.get_memory_card(card_id)
	if card.is_empty():
		return
	if used_memory_cards.has(card_id):
		combat_log.append("[color=#FF8A80]Ya empleaste el recuerdo «%s» en este encuentro.[/color]" % card["name"])
		combat_updated.emit()
		return
	var ap_cost: int = int(card.get("ap", 1))
	if player_ap < ap_cost:
		combat_log.append("[color=#FF8A80]«%s» requiere %d PA.[/color]" % [card["name"], ap_cost])
		combat_updated.emit()
		return
	player_ap -= ap_cost
	used_memory_cards.append(card_id)
	var dmg_mult: float = (1.50 if enemy_staggered else 1.0) * (1.0 + GameState.get_outfit_mod("combat_atk_pct", 0.0) + next_atk_bonus_pct)
	next_atk_bonus_pct = 0.0

	match card_id:
		"mem_hearth_vow":
			player_shield += 60
			player_hp = mini(player_max_hp, player_hp + 45)
			next_atk_bonus_pct += 0.25
			combat_fx.emit("shield")
			combat_log.append("[color=#80DEEA]♥ %s: +60 Escudo, +45 HP y +25%% al próximo ataque.[/color]" % card["name"])
		"mem_indomitable":
			var d: int = int(round((95 + GameState.temple * 0.38) * dmg_mult))
			combat_fx.emit("slash")
			_apply_damage_to_enemy(d, 38, "⚔ " + str(card["name"]))
		"mem_eclipse_eyes":
			var d: int = int(round((88 + GameState.gravedad * 0.36) * dmg_mult))
			GameState.modify_stat("abyssal_sync", 4)
			combat_fx.emit("magic")
			_apply_damage_to_enemy(d, 25, "☾ " + str(card["name"]))
		"mem_crystal_mind":
			player_ap += 1
			combat_fx.emit("stagger")
			_apply_damage_to_enemy(20, 35, "✦ " + str(card["name"]))
		"mem_alabaster_rose":
			player_shield += 80
			GameState.modify_stat("stress", -3)
			combat_fx.emit("shield")
			_apply_damage_to_enemy(int(round(35 * dmg_mult)), 15, "❀ " + str(card["name"]))
		"mem_insomnia_echo":
			var cost_hp: int = maxi(1, int(player_max_hp * 0.08))
			player_hp = maxi(1, player_hp - cost_hp)
			player_ap += 2
			combat_fx.emit("magic")
			_apply_damage_to_enemy(int(round(60 * dmg_mult)), 25, "✧ " + str(card["name"]))
		"mem_shard_1":
			player_shield += 55
			player_hp = mini(player_max_hp, player_hp + 50)
			combat_fx.emit("shield")
			combat_log.append("[color=#FFE082]✦ %s: +55 Escudo y +50 HP.[/color]" % card["name"])
		"mem_shard_2":
			player_shield += 25
			var d: int = int(round((75 + GameState.resonancia * 0.38) * dmg_mult))
			combat_fx.emit("magic")
			_apply_damage_to_enemy(d, 25, "✦ " + str(card["name"]))
		"mem_shard_3":
			var d: int = int(round((105 + GameState.destreza * 0.40) * dmg_mult))
			combat_fx.emit("slash")
			_apply_damage_to_enemy(d, 30, "✦ " + str(card["name"]))
		"mem_shard_4":
			var d: int = int(round((165 + GameState.gravedad * 0.55) * dmg_mult))
			combat_fx.emit("magic")
			_apply_damage_to_enemy(d, 50, "✦ " + str(card["name"]))
		"mem_shard_5":
			player_ap += 1
			player_hp = mini(player_max_hp, player_hp + 80)
			player_shield += 80
			combat_fx.emit("stagger")
			_apply_damage_to_enemy(int(round(90 * dmg_mult)), 45, "☥ " + str(card["name"]))
		"mem_bond_soren":
			var d: int = int(round((90 + GameState.erudicion * 0.40) * dmg_mult))
			combat_fx.emit("magic")
			_apply_damage_to_enemy(d, 36, "✦ " + str(card["name"]))
		"mem_bond_vespera":
			var d: int = int(round((110 + GameState.temple * 0.42) * dmg_mult))
			combat_fx.emit("slash")
			_apply_damage_to_enemy(d, 25, "⚔ " + str(card["name"]))
		"mem_bond_kaelen":
			player_shield += 30
			GameState.modify_gold(45)
			var d: int = int(round((80 + GameState.destreza * 0.36) * dmg_mult))
			combat_fx.emit("slash")
			_apply_damage_to_enemy(d, 22, "⚡ " + str(card["name"]) + " (+45G)")
		"mem_bond_cassian":
			player_shield += 75
			var d: int = int(round((80 + GameState.magnetismo * 0.35) * dmg_mult))
			combat_fx.emit("shield")
			_apply_damage_to_enemy(d, 20, "☀ " + str(card["name"]))
		"mem_bond_mirari":
			player_hp = mini(player_max_hp, player_hp + 95)
			player_shield += 55
			GameState.modify_stat("seal_integrity", 2)
			combat_fx.emit("shield")
			combat_log.append("[color=#86e3a6]❀ %s: +95 HP, +55 Escudo y +2%% %s.[/color]" % [card["name"], GameState.get_stat_label("seal_integrity")])
		"mem_bond_zephyr":
			var d: int = int(round((115 + GameState.resonancia * 0.48) * dmg_mult))
			combat_fx.emit("magic")
			_apply_damage_to_enemy(d, 35, "☥ " + str(card["name"]))
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
			var z_skill: String = "☥ Cadenas del Espejo de Zephyr" if GameState.get_secret_tier() >= 2 else "☥ Reflejo del Estanque Nocturno"
			_apply_damage_to_enemy(d, 35, z_skill)
		_:
			var d: int = int(round((60 + (GameState.temple + GameState.destreza) * 0.18) * dmg_mult))
			player_shield += 28
			_apply_damage_to_enemy(d, 25, "⚔ Guardia Solitaria de Aethelgard (+28 Escudo)")

func _apply_damage_to_enemy(dmg: int, stagger_add: int, skill_label: String) -> void:
	enemy_hp = maxi(0, enemy_hp - dmg)
	if not enemy_staggered:
		var bonus_stagger: int = 15 if companion_id == "soren" else 0
		enemy_stagger += stagger_add + bonus_stagger
		if enemy_stagger >= enemy_max_stagger:
			enemy_stagger = enemy_max_stagger
			enemy_staggered = true
			combat_fx.emit("stagger")
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
			combat_fx.emit("hit")
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
	if not in_expedition and not in_combat:
		return
	in_combat = false
	in_expedition = false
	GameState.modify_stat("stress", 8)
	var msg: String = "%s y %s se retiraron estratégicamente de %s (+8 Estrés)." % [GameState.daughter_name, companion_name, current_zone["name"]]
	combat_finished.emit(false, msg)

func _check_enemy_defeat_or_continue() -> void:
	if enemy_hp > 0:
		combat_updated.emit()
		return

	if current_stage == 1:
		# Avanza del Nodo 1 (Vanguardia) al Nodo 2 (Encrucijada Interactiva)
		in_combat = false
		current_node = 2
		combat_log.append("[color=#81C784]✦ ¡Nodo 1 superado! %s cae ante vuestro avance. Se abre la Encrucijada de %s.[/color]" % [enemy_name, current_zone["name"]])
		node_event_data = _build_node_2_event()
		combat_updated.emit()
		expedition_node_ready.emit(node_event_data)
	else:
		in_combat = false
		in_expedition = false
		var shard_id: String = str(current_zone["shard_id"])
		var shard_msg: String = ""
		if not memory_shards_found.has(shard_id):
			memory_shards_found.append(shard_id)
			GameState.memory_shards_found = memory_shards_found.size()
			GameState.modify_stat("seal_investigation", 15)
			Chronicle.record_event(shard_id, current_zone["shard_title"], current_zone["shard_lore"], "twist", 5)
			shard_msg = "\n[color=#FFF176][b]✦ %s (+15%% %s):[/b]\n%s[/color]" % [
				current_zone["shard_title"], GameState.get_stat_label("seal_investigation"), current_zone["shard_lore"]
			]
		var gold_won: int = int(current_zone["gold_reward"])
		if companion_id == "kaelen":
			gold_won = int(round(gold_won * 1.40))
		GameState.modify_gold(gold_won)
		GameState.modify_stat("temple", 16)
		GameState.modify_stat("resonancia", 16)
		var loot_key: String = current_zone["loot_id"]
		GameState.materials_inventory[loot_key] = GameState.materials_inventory.get(loot_key, 0) + 1
		if RelationshipManager != null and RelationshipManager.state.has(companion_id):
			var st: Dictionary = RelationshipManager.state[companion_id]
			st["affection"] = clampi(int(st["affection"]) + 4, -100, 100)
			st["respect"] = clampi(int(st["respect"]) + 3, -100, 100)
		Chronicle.record_event("exp_win_" + str(current_zone["id"]), "Conquista de " + str(current_zone["name"]), "%s y %s derrotaron a %s." % [GameState.daughter_name, companion_name, enemy_name], "expedition", 4)
		var mat_name: String = str(CatalogDB.get_material(loot_key).get("name", loot_key))
		var win_summary: String = "¡Victoria total en %s! Derrotaste a %s junto a %s.\nRecompensas: +%d Oro, +16 Temple, +16 Resonancia, +1 %s y +4 Afecto/+3 Respeto con %s.%s" % [
			current_zone["name"], enemy_name, companion_name, gold_won, mat_name, companion_name, shard_msg
		]
		combat_fx.emit("victory")
		combat_finished.emit(true, win_summary)

func _build_node_2_event() -> Dictionary:
	var sk: String = str(current_zone.get("check_stat", "destreza"))
	var req_v: int = int(current_zone.get("check_val", 160))
	var my_v: int = GameState.get_stat(sk)
	var mut_id: String = str(current_zone.get("bypass_mut", "paso_de_luz"))
	var mut_name: String = CatalogDB.get_mutation_name(mut_id)
	var has_mut: bool = GameState.has_mutation(mut_id)
	return {
		"node": 2,
		"title": "NODO 2/4 · ENCRUCIJADA EN %s" % str(current_zone["name"]).to_upper(),
		"body": "El pasaje interior se divide ante un umbral sellado por runas solares. ¿Cómo avanzan antes de llegar al santuario del Guardián?",
		"choices": [
			{
				"id": "skill",
				"disabled": false,
				"label": "❖ Prueba de %s (%d/%d): Sortear las trampas arcanas" % [GameState.get_stat_label(sk), my_v, req_v],
				"hint": "Éxito: +85 Oro, +25 Escudo, +18% HP. Fallo: -12% HP, +4 Estrés."
			},
			{
				"id": "mutation",
				"disabled": not has_mut,
				"label": "✦ [Atajo: %s] Cruzar por el plano etéreo%s" % [mut_name, "" if has_mut else " (Requiere mutación)"],
				"hint": "Atajo perfecto sin peligro: +1 material para el Crisol y +35 Escudo."
			},
			{
				"id": "safe",
				"disabled": false,
				"label": "❀ Rodeo táctico junto a %s" % companion_name,
				"hint": "Sin riesgo: +15 Escudo Astral y +12 Resonancia."
			}
		]
	}

func _build_node_3_event() -> Dictionary:
	var shard_id: String = str(current_zone["shard_id"])
	var has_shard: bool = memory_shards_found.has(shard_id)
	return {
		"node": 3,
		"title": "NODO 3/4 · SANTUARIO INTERIOR DE %s" % str(current_zone["name"]).to_upper(),
		"body": "Ante las puertas del %s, descubren un antiguo brasero celeste junto a una grieta con memoria cristalizada." % current_zone["boss_name"],
		"choices": [
			{
				"id": "rest",
				"disabled": false,
				"label": "❀ Encender el brasero y preparar la defensa (+35% HP, +40 Escudo, -6 Estrés)",
				"hint": "Ideal si llegan desgastados de la Vanguardia."
			},
			{
				"id": "shard",
				"disabled": false,
				"label": "✧ Sondear %s (%s)" % [
					"la Esquirla de Memoria" if GameState.get_secret_tier() >= 2 else "el Vestigio Antiguo",
					"Ya hallado: +1 Relicario y +1 PA inicial" if has_shard else "+15% Pesquisa y +1 PA en Turno 1 vs Jefe"
				],
				"hint": "Despierta ecos antiguos antes del combate final."
			}
		]
	}

func choose_expedition_node(choice_id: String) -> void:
	if not in_expedition:
		return
	if current_node == 2:
		match choice_id:
			"skill":
				var sk: String = str(current_zone.get("check_stat", "destreza"))
				var req_v: int = int(current_zone.get("check_val", 160))
				if GameState.get_stat(sk) >= req_v:
					GameState.modify_gold(85)
					player_shield += 25
					player_hp = mini(player_max_hp, player_hp + int(player_max_hp * 0.18))
					combat_log.append("[color=#86e3a6]✓ Prueba superada (%s): +85 Oro, +25 Escudo y +18%% HP.[/color]" % GameState.get_stat_label(sk))
				else:
					player_hp = maxi(1, player_hp - int(player_max_hp * 0.12))
					GameState.modify_stat("stress", 4)
					combat_log.append("[color=#ff9f5a]✕ Trampa rozada (-12%% HP, +4 Estrés). ¡Toca resistir![/color]")
			"mutation":
				var mut_id: String = str(current_zone.get("bypass_mut", "paso_de_luz"))
				if GameState.has_mutation(mut_id):
					var loot_key: String = str(current_zone["loot_id"])
					GameState.materials_inventory[loot_key] = int(GameState.materials_inventory.get(loot_key, 0)) + 1
					player_shield += 35
					combat_log.append("[color=#ab80f7]✦ Atajo de %s: +35 Escudo y +1 reliquia rescatada sin rasguños.[/color]" % CatalogDB.get_mutation_name(mut_id))
			_:
				player_shield += 15
				GameState.modify_stat("resonancia", 12)
				combat_log.append("[color=#49d6c8]❀ Rodeo seguro: +15 Escudo y +12 Resonancia.[/color]")
		current_node = 3
		node_event_data = _build_node_3_event()
		combat_updated.emit()
		expedition_node_ready.emit(node_event_data)
	elif current_node == 3:
		if choice_id == "rest":
			var heal_v: int = int(player_max_hp * 0.35)
			player_hp = mini(player_max_hp, player_hp + heal_v)
			player_shield += 40
			GameState.modify_stat("stress", -6)
			bonus_boss_ap = 0
			combat_log.append("[color=#86e3a6]❀ Brasero del Santuario: +%d HP, +40 Escudo y -6 Estrés.[/color]" % heal_v)
		else:
			bonus_boss_ap = 1
			var shard_id: String = str(current_zone["shard_id"])
			if not memory_shards_found.has(shard_id):
				memory_shards_found.append(shard_id)
				GameState.memory_shards_found = memory_shards_found.size()
				GameState.modify_stat("seal_investigation", 15)
				Chronicle.record_event(shard_id, current_zone["shard_title"], current_zone["shard_lore"], "twist", 5)
				combat_log.append("[color=#FFF176][b]✦ %s descubierto (+15%% %s, +1 PA en el Turno 1 vs Jefe):[/b]\n%s[/color]" % [
					current_zone["shard_title"], GameState.get_stat_label("seal_investigation"), current_zone["shard_lore"]
				])
			else:
				var loot_key: String = str(current_zone["loot_id"])
				GameState.materials_inventory[loot_key] = int(GameState.materials_inventory.get(loot_key, 0)) + 1
				combat_log.append("[color=#FFE082]✧ Reliquia residual recuperada (+1 material) y +1 PA inicial frente al Jefe.[/color]")
		_setup_stage_enemy(2)
		player_ap = player_max_ap + bonus_boss_ap + (1 if GameState.has_mutation("bendicion_del_tiempo") else 0)
		in_combat = true
		node_event_data.clear()
		combat_log.append("[color=#ff9f5a]☠ NODO 4/4 — ¡Emerge el Guardián Final: [b]%s[/b]![/color]" % enemy_name)
		combat_updated.emit()

# ==============================================================================
# LÓGICA DEL GRAN FESTIVAL DE LAS CONSTELACIONES DE OTOÑO (3 ASALTOS)
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
	# Bonificación de Vestuario de la Boutique y Temperamento
	if c["id"] == "contest_blades":
		my_total += GameState.get_outfit_mod("festival_blades")
	elif c["id"] == "contest_astrolabe":
		my_total += GameState.get_outfit_mod("festival_astro")
	elif c["id"] == "contest_moons":
		my_total += GameState.get_outfit_mod("festival_gala")
	for c_dict in GameState.get_equipped_memory_cards():
		my_total += int(int(c_dict.get("fest_bonus", 0)) * 0.45)
	if GameState.mood_calm >= 18:
		my_total += 15
	if GameState.mood_pride <= -15 and c["id"] == "contest_moons":
		my_total += 15
	elif GameState.mood_pride >= 15 and c["id"] == "contest_blades":
		my_total += 15
	var r_id: String = str(c["rival_id"])
	var riv_base: int = RivalMirror.get_rival_score(r_id)
	var target_score: int = int(round(float(riv_base) * 1.35))
	return {"my_total": my_total, "target_score": target_score}

func start_festival_match(contest_idx: int) -> Dictionary:
	if not TimeManager.is_festival_bimester():
		return {"ok": false, "msg": "El Gran Festival de las Constelaciones se celebra en el 4º Bimestre (Cosecha, Equinoccio de Otoño). Aún puedes prepararte."}
	if festival_entered_this_year:
		return {"ok": false, "msg": "%s ya compitió en el certamen oficial del Festival de Otoño de este año." % GameState.daughter_name}
	if contest_idx < 0 or contest_idx >= FESTIVAL_CONTESTS.size():
		return {"ok": false, "msg": "Certamen inválido."}
	var c: Dictionary = FESTIVAL_CONTESTS[contest_idx]
	var prev: Dictionary = get_festival_preview(contest_idx)
	var r_score: int = int(prev["target_score"])
	var m_score: int = int(prev["my_total"])
	festival_match = {
		"contest_idx": contest_idx,
		"contest_id": c["id"],
		"name": c["name"],
		"rival_name": c["rival_name"],
		"stats": c["stats"].duplicate(),
		"reward_gold": int(c["reward_gold"]),
		"reward_item": str(c["reward_item"]),
		"round": 1,
		"max_rounds": 3,
		"my_base": m_score,
		"rival_base": r_score,
		"player_score": 0,
		"rival_score": 0,
		"used_cards": [],
		"finished": false,
		"log": [
			"✦  Comienza [b]%s[/b] en el Coliseo de las Constelaciones." % c["name"],
			"Rival: [b]%s[/b] (Potencia estimada: %d vs tu base %d)." % [c["rival_name"], r_score, m_score],
			"Asalto 1/3 — Exhibición Inicial: elige tu postura de apertura."
		]
	}
	return {"ok": true, "match": festival_match}

func play_festival_round(tactic_id: String, card_id: String = "", risk_stress: bool = false, minigame_bonus: int = 0) -> Dictionary:
	if festival_match.is_empty() or bool(festival_match.get("finished", false)):
		return {"ok": false, "msg": "No hay un certamen en curso."}
	var rnd: int = int(festival_match["round"])
	var my_base: float = float(festival_match["my_base"])
	var riv_base: float = float(festival_match["rival_base"])
	var my_gain: int = int(round(my_base / 3.0))
	var tactic_note: String = "Ejecución Serena"
	match tactic_id:
		"bravado":
			var swing: float = 1.18 if GameState.mood_pride >= 0 else 1.08
			my_gain = int(round(float(my_gain) * swing))
			tactic_note = "Gambito Audaz"
		"harmony":
			my_gain = int(round(float(my_gain) * 1.04))
			GameState.modify_stat("stress", -3)
			tactic_note = "Cadencia Estelar (-3 Estrés)"
		_:
			my_gain = int(round(float(my_gain) * 1.10))
			tactic_note = "Exhibición de Precisión"
	if risk_stress:
		GameState.modify_stat("stress", 6)
		my_gain += int(maxi(35, round(my_base * 0.12)))
		tactic_note += " + Sobrecarga (+6 Estrés)"
	if minigame_bonus > 0:
		my_gain += minigame_bonus
		tactic_note += " + Destreza en Escena (+%d)" % minigame_bonus
	var eq_ids: Array[String] = []
	for ec in GameState.get_equipped_memory_cards():
		eq_ids.append(str(ec.get("id", "")))
	if card_id != "" and eq_ids.has(card_id) and not festival_match["used_cards"].has(card_id):
		festival_match["used_cards"].append(card_id)
		var card: Dictionary = CatalogDB.get_memory_card(card_id)
		var c_bonus: int = int(round(float(card.get("fest_bonus", 45)) * 1.25))
		my_gain += c_bonus
		tactic_note += " + Recuerdo «%s» (+%d)" % [str(card.get("name", card_id)), c_bonus]

	var riv_mult: float = 0.96 if rnd == 1 else (1.06 if rnd == 2 else 0.98)
	var riv_gain: int = int(round((riv_base / 3.0) * riv_mult))
	festival_match["player_score"] = int(festival_match["player_score"]) + my_gain
	festival_match["rival_score"] = int(festival_match["rival_score"]) + riv_gain
	festival_match["log"].append("[color=#86e3a6]Asalto %d/3 (%s):[/color] +%d pts [color=#a4b0c9](%s +%d)[/color] → Parcial %d vs %d" % [
		rnd, tactic_note, my_gain, festival_match["rival_name"], riv_gain, int(festival_match["player_score"]), int(festival_match["rival_score"])
	])

	if rnd < 3:
		festival_match["round"] = rnd + 1
		var prompt: String = "Asalto 2/3 — Contraataque de %s: ajusta tu estrategia." % festival_match["rival_name"] if rnd == 1 else "Asalto 3/3 — Remate Final ante el jurado imperial."
		festival_match["log"].append("[color=#f7e3a1]%s[/color]" % prompt)
		return {"ok": true, "finished": false, "match": festival_match}

	festival_match["finished"] = true
	return _finish_festival_match(festival_match)

func _finish_festival_match(m: Dictionary) -> Dictionary:
	festival_entered_this_year = true
	var my_total: int = int(m["player_score"])
	var target_score: int = int(m["rival_score"])
	var won: bool = my_total >= target_score
	var cname: String = str(m["name"])
	var rname: String = str(m["rival_name"])
	var stat_list: Array = m["stats"]
	if won:
		var g_rew: int = int(m["reward_gold"])
		var item_k: String = str(m["reward_item"])
		GameState.modify_gold(g_rew)
		GameState.modify_stat("magnetismo", 24)
		GameState.modify_stat("affection", 10)
		GameState.modify_stat("father_reputation", 6)
		GameState.materials_inventory[item_k] = int(GameState.materials_inventory.get(item_k, 0)) + 1
		if not festival_wins.has(TimeManager.current_year):
			festival_wins.append(TimeManager.current_year)
		Chronicle.record_event("festival_champion_%d" % TimeManager.current_year, "Campeona del Festival de Otoño (%s)" % cname, "%s venció a %s con %d pts frente a %d pts." % [GameState.daughter_name, rname, my_total, target_score], "festival", 5)
		var mat_name: String = str(CatalogDB.get_material(item_k).get("name", item_k))
		return {
			"ok": true,
			"finished": true,
			"won": true,
			"match": m,
			"title": "✦  ¡CAMPEONA DEL FESTIVAL DE LAS CONSTELACIONES!  ✦",
			"summary": "¡%s deslumbró a toda la capital en [b]%s[/b], superando a %s (%d pts vs %d pts)!\n\n[color=#86e3a6]Premio Imperial: +%d Oro, +24 Magnetismo, +10 Afecto, +6 Reputación y +1 %s para el Crisol.[/color]" % [
				GameState.daughter_name, cname, rname, my_total, target_score, g_rew, mat_name
			]
		}
	else:
		GameState.modify_gold(80)
		GameState.modify_stat(str(stat_list[0]), 15)
		Chronicle.record_event("festival_runner_%d" % TimeManager.current_year, "Finalista en el Festival (%s)" % cname, "%s obtuvo el segundo puesto tras %s (%d vs %d)." % [GameState.daughter_name, rname, my_total, target_score], "festival", 3)
		return {
			"ok": true,
			"finished": true,
			"won": false,
			"match": m,
			"title": "✧  Segundo Puesto en el Coliseo de las Constelaciones  ✧",
			"summary": "%s dio una gran demostración en [b]%s[/b], pero %s se llevó la corona por %d a %d.\n\n[color=#f7e3a1]Premio de Finalista: +80 Oro y +15 %s por la experiencia.[/color]" % [
				GameState.daughter_name, cname, rname, target_score, my_total, GameState.get_stat_label(str(stat_list[0]))
			]
		}

func participate_in_festival(contest_idx: int) -> Dictionary:
	var st: Dictionary = start_festival_match(contest_idx)
	if not bool(st.get("ok", false)):
		return st
	play_festival_round("precision", "", false)
	play_festival_round("harmony", "", false)
	return play_festival_round("bravado", "", false)

# ==============================================================================
# EVENTOS DE HISTORIA PRINCIPAL — ACTOS, EDICTOS, INQUISICIÓN, CRISIS Y OMISIONES
# ==============================================================================
func check_pending_main_story_event() -> Dictionary:
	# 1. Diálogo íntimo por Agotamiento Crítico
	if GameState.sick_dialogue_pending:
		return {
			"has_event": true,
			"act_id": 501,
			"is_twist": false,
			"category": "exhaustion",
			"title": "%s  NOCHE DE AGOTAMIENTO: EL PESO DE LAS ESTRELLAS  %s" % [AstralTheme.G_HEART, AstralTheme.G_HEART],
			"body": "Encuentras a %s sentada al borde de la cama con el pulso tembloroso y ojeras violáceas bajo sus ojos dorados. No puede sostener siquiera la pluma del estudio.\n\n«Lo siento, Padre... prometí esforzarme al máximo, pero hoy siento como si las constelaciones pesaran sobre mis hombros.»" % GameState.daughter_name,
			"choices": [
				{
					"label": "♥ Prepararle té de tilo y prometer una pausa sin deberes (-18 Estrés, +8 Afecto, +5 Anclaje Humano)",
					"effects": {"stress": -18, "affection": 8, "human_anchor": 5},
					"outcome": "Tu hija suspira aliviada entre mantas tibias. Aún necesita cuidados en la Chimenea o el Sanatorio, pero el miedo se disipa."
				},
				{
					"label": "✧ Vigilar el latido estelar durante la madrugada (-10 Estrés, +6% Investigación, +4 Resonancia nocturna)",
					"effects": {"stress": -10, "seal_investigation": 6, "abyssal_sync": 4},
					"outcome": "Anotas las pulsaciones febriles de su marca mientras duerme: la fatiga vuelve visible una bóveda luminosa bajo su piel."
				}
			]
		}

	# 2. Crisis de Apetito Estelar (Saturación >= 70 o asimilaciones seguidas)
	if GameState.pending_astral_crisis:
		var t_crisis: int = GameState.get_secret_tier()
		var crisis_echo: String = "Nyx-Aethel" if t_crisis >= 2 else "la presencia tras el espejo"
		var crisis_arm: String = GameState.get_stat_label("seal_integrity")
		var ch: Array = [
			{
				"label": "♥ Arrodillarte junto a la chimenea y anclarla en el presente (-12 Estrés, +8 Anclaje Humano, +6%% %s, -15 Saturación)" % crisis_arm,
				"effects": {"stress": -12, "human_anchor": 8, "seal_integrity": 6, "astral_saturation": -15},
				"outcome": "Entre aromas de pan tostado y tu voz serena, %s retrocede tras el espejo." % crisis_echo
			},
			{
				"label": "☾ Observar y sintonizar el hambre astral (+10 %s, +18 Resonancia, +12 Luminiscencia)" % GameState.get_stat_label("abyssal_sync"),
				"effects": {"abyssal_sync": 10, "resonancia": 18, "luminiscencia": 12},
				"outcome": "Las pupilas de %s absorben la luz azulada del crisol; aprendes el idioma antiguo de su apetito estelar." % GameState.daughter_name
			}
		]
		if ConstellationTapestry.discovered_branches.size() >= 1:
			ch.append({
				"label": "✦ [Eco del Solsticio] Cantar el contrapunto olvidado (+12% Investigación, +6 Anclaje, -12 Saturación)",
				"is_ng_echo": true,
				"effects": {"seal_investigation": 12, "human_anchor": 6, "astral_saturation": -12},
				"outcome": "De otro ciclo recuerdas exactamente qué calma esa sed sin herir a tu hija."
			})
		return {
			"has_event": true,
			"act_id": 401,
			"is_twist": true,
			"category": "crisis",
			"title": "☠  CRISIS DE APETITO ESTELAR JUNTO AL FUEGO  ☠",
			"body": "El exceso de fragmentos devorados en el Crisol despierta un eco antiguo en el comedor. Las llamas de la chimenea se curvan hacia %s, cuya sombra proyecta astas oscuras sobre la pared.\n\n«Tengo hambre de luz, Padre... pero no es mía. Algo tras el cristal quiere beberse todo el cielo nocturno.»" % GameState.daughter_name,
			"choices": ch
		}

	# 3. Audiencia de la Inquisición Solar (Sospecha del Senado >= 80)
	if GameState.court_suspicion >= 80:
		var ch_inq: Array = [
			{
				"label": "⚖ Defensa protocolaria de linaje heroico (-35 Sospecha si pasas prueba)",
				"req_stat": "gracia",
				"req_val": 180,
				"effects": {"court_suspicion": -35, "father_reputation": 5},
				"outcome": "Tu impecable defensa ante los inquisidores disipa las sospechas del Senado Imperial.",
				"effects_fail": {"court_suspicion": -22, "gold": -90, "stress": 8},
				"outcome_fail": "Los inquisidores dudan de tus argumentos y exigen una multa de 90 Oro por custodia preventiva (-22 Sospecha)."
			},
			{
				"label": "⚖ Sobornar al censor real y archivar el expediente (-110 Oro, -15 Energía Paterna, -45 Sospecha)",
				"effects": {"gold": -110, "father_energy": -15, "court_suspicion": -45},
				"outcome": "Un discreto cofre de oro borra las actas de los canales antes de que lleguen al Emperador."
			},
			{
				"label": "⚔ Confrontar al tribunal con tu aura de Héroe (+15 Temple, -6% Sello, -25 Sospecha)",
				"effects": {"temple": 15, "seal_integrity": -6, "court_suspicion": -25},
				"outcome": "Nadie en la sala se atreve a levantar la mano contra el antiguo salvador de la corona, pero la tensión astral cruje."
			}
		]
		return {
			"has_event": true,
			"act_id": 201,
			"is_twist": false,
			"category": "senate",
			"title": "⚖  AUDIENCIA DE LA INQUISICIÓN SOLAR  ⚖",
			"body": "Las patrullas solares rodean la mansión al amanecer. Tus movimientos en los canales o las fisuras astrales del observatorio dispararon todas las alarmas del Senado.\n\n«Lord %s, el Censor Mayor exige explicaciones inmediatas sobre lo que oculta bajo su techo.»" % GameState.father_name,
			"choices": ch_inq
		}

	# 4. Acto I (Edad 13): La Primera Fisura del Firmamento
	if GameState.age >= 13 and not story_acts_seen.has(13):
		var c13: Array = [
			{
				"label": "♥ Abrazarla y contarle una historia terrenal sobre cómo cayó en tus brazos (+10 Anclaje, +8 Afecto, -10 Estrés)",
				"effects": {"human_anchor": 10, "affection": 8, "stress": -10},
				"outcome": "%s apoya la cabeza en tu pecho hasta que el zumbido estelar se calma en un latido humano." % GameState.daughter_name
			},
			{
				"label": "✦ Medir la frecuencia de su pulso astral (+15 Luminiscencia, +12 Resonancia, +10% Investigación)",
				"effects": {"luminiscencia": 15, "resonancia": 12, "seal_investigation": 10},
				"outcome": "Registras las ecuaciones de su luz: los trazos coinciden con mapas estelares olvidados anteriores al reino de Aethelgard."
			},
			{
				"label": "⚔ Enseñarle a contener la energía mediante disciplina marcial",
				"req_stat": "temple",
				"req_val": 115,
				"effects": {"temple": 16, "seal_integrity": 6},
				"outcome": "%s respira como una guardiana veterana y sella las chispas con maestría.",
				"effects_fail": {"temple": 8, "stress": 4},
				"outcome_fail": "Las chispas aún se le escapan de las manos (+8 Temple, +4 Estrés), pero comprende el valor del autocontrol."
			}
		]
		return {
			"has_event": true,
			"act_id": 13,
			"is_twist": false,
			"title": "✦  ACTO I (EDAD 13): LA PRIMERA FISURA DEL FIRMAMENTO  ✦",
			"body": "Durante la lluvia de meteoros de primavera, una corona de chispas doradas brota sin querer de las manos de %s y hace levitar los libros de tu escritorio.\n\n«¡No sé qué acaba de pasar, Padre! Sentí un reloj antiguo haciendo tic-tac dentro de mis costillas... ¿Los demás niños también tienen estrellas bajo la piel?»" % GameState.daughter_name,
			"choices": c13
		}

	# 5. Acto I -> II (Edad 14): El Despertar del Espejo Estelar
	if GameState.age >= 14 and not story_acts_seen.has(14):
		return {
			"has_event": true,
			"act_id": 14,
			"is_twist": false,
			"title": "☥  ACTO II (EDAD 14): EL DESPERTAR DEL ESPEJO ESTELAR  ☥",
			"body": "En la noche del Equinoccio, el observatorio entero tiembla. La marca estelar en el pecho de %s brilla con jeroglíficos dorados y, por un segundo, el espejo del salón refleja una silueta encadenada tras una bruma violeta.\n\n«Papá... hay alguien más mirando desde mi reflejo. Dice que la Diosa nos oculta algo sobre la noche en que caí del cielo.»" % GameState.daughter_name,
			"choices": [
				{
					"label": "♥ Jurarle protección: «Pase lo que pase, siempre serás mi hija.» (+12 Anclaje, -15 Estrés, +10 Afecto)",
					"effects": {"human_anchor": 12, "stress": -15, "affection": 10},
					"outcome": "Las lágrimas de %s apagan el fulgor frío; tu amor levanta un escudo alrededor de su corazón mortal." % GameState.daughter_name
				},
				{
					"label": "❖ Traducir los jeroglíficos del reflejo para investigarlos en secreto",
					"req_stat": "erudicion",
					"req_val": 165,
					"effects": {"seal_investigation": 18, "erudicion": 22},
					"outcome": "Descifras de inmediato que los glifos son anteriores a la corona solar. Alguien borró este capítulo de todas las bibliotecas.",
					"effects_fail": {"seal_investigation": 9, "erudicion": 10, "stress": 5},
					"outcome_fail": "Solo logras copiar trazos parciales antes de que el espejo se congele (+9% Investigación)."
				},
				{
					"label": "☾ Enseñarle a escuchar esa presencia sin temor (+14 Vínculo con el Espejo, +20 Resonancia)",
					"effects": {"abyssal_sync": 14, "resonancia": 20},
					"outcome": "Por primera vez, la silueta tras el espejo no se oculta: asiente en silencio, expectante."
				}
			]
		}

	# 6. Acto II -> III (Edad 17): EL GRAN GIRO
	if GameState.age >= 17 and not story_acts_seen.has(17):
		var c17: Array = [
			{
				"label": "⚔ Desenvainar tu arma de Héroe: «¡Desafiaré a la misma Diosa antes de entregarle a mi hija!» (+15 Anclaje, +25 Temple, +15 Afecto)",
				"effects": {"human_anchor": 15, "temple": 25, "affection": 15},
				"outcome": "El Heraldo retrocede ante tu aura de leyenda. %s toma tu mano, dispuesta a luchar contra el cielo mismo." % GameState.daughter_name
			},
			{
				"label": "✦ Tercer Camino: Contrastar las escrituras del Sello frente al Heraldo",
				"req_stat": "seal_investigation",
				"req_val": 45,
				"effects": {"seal_investigation": 22, "abyssal_sync": 18, "human_anchor": 12},
				"outcome": "Demuestras conocer la arquitectura oculta de la prisión divina: la única salida real es unir ambos mundos.",
				"effects_fail": {"seal_investigation": 12, "abyssal_sync": 10, "stress": 6},
				"outcome_fail": "Tu hipótesis sorprende al Heraldo, aunque aún te faltan datos sobre el Sarcófago (+12% Investigación)."
			},
			{
				"label": "☠ Dejar que la ira del Sarcófago agriete el Sello (-15% Sello, +20 Sincronía, +30 Gravedad)",
				"effects": {"seal_integrity": -15, "abyssal_sync": 20, "gravedad": 30},
				"outcome": "Una onda de gravedad violeta rompe las losas del balcón y ahuyenta al Heraldo entre relámpagos oscuros."
			}
		]
		if ConstellationTapestry.discovered_branches.size() >= 1:
			c17.append({
				"label": "✦ [Eco del Solsticio] Nombrar a Nyx-Aethel antes de que el Heraldo hable (+20% Inv, +14 Anclaje, +14 Sincronía)",
				"is_ng_echo": true,
				"effects": {"seal_investigation": 20, "human_anchor": 14, "abyssal_sync": 14},
				"outcome": "El Heraldo enmudece aterrado al comprobar que ya recuerdas el verdadero nombre del ciclo astral."
			})
		return {
			"has_event": true,
			"act_id": 17,
			"is_twist": true,
			"title": "☾  EL GRAN GIRO (EDAD 17): «LA ESTRELLA ERA UNA PRISIÓN»  ☾",
			"body": "Un Heraldo de la Diosa de la Eternidad desciende sobre el balcón del observatorio entre relojes de oro suspendidos en el aire. Con voz de campanas heladas anuncia que solo quedan tres años para la Cosecha:\n\n«Héroe %s, la estrella que recibiste hace diecisiete años era el Sarcófago Celestial donde encerramos a Nyx-Aethel, el espíritu del Cambio. Tu crianza ha servido para madurar el Sello. Cuando %s cumpla veinte años, la Diosa absorberá a ambos para congelar el tiempo para siempre.»" % [GameState.father_name, GameState.daughter_name],
			"choices": c17
		}

	# 7. Acto III (Edad 19): La Víspera del Solsticio Final
	if GameState.age >= 19 and not story_acts_seen.has(19):
		var c19: Array = [
			{
				"label": "♥ «Como una familia que eligió vivir libre cada día que le fue dado.» (+10 Anclaje, +10 Afecto, +15 Luminiscencia)",
				"effects": {"human_anchor": 10, "affection": 10, "luminiscencia": 15},
				"outcome": "El corazón de %s brilla con una calidez dorada que ni la eternidad helada podría apagar." % GameState.daughter_name
			},
			{
				"label": "⏳ «Reescribiremos el mecanismo del Reloj Divino antes de la medianoche.»",
				"req_stat": "resonancia",
				"req_val": 280,
				"effects": {"seal_investigation": 18, "resonancia": 28, "seal_integrity": 6},
				"outcome": "Tus ecuaciones resuenan con la bóveda del reino; la mecánica celeste ya admite un desenlace diferente.",
				"effects_fail": {"seal_investigation": 10, "resonancia": 15, "stress": 6},
				"outcome_fail": "Los engranajes astrales aún resisten tu cálculo, pero ganas valiosa ventaja (+10% Investigación)."
			},
			{
				"label": "⚡ «Que tiemblen los dioses: nuestro poder unido no se arrodillará.» (+25 Gravedad, +10 Sincronía)",
				"effects": {"gravedad": 25, "abyssal_sync": 10},
				"outcome": "Las estrellas sobre la mansión titilan en rojo y violeta respondiendo a la determinación de padre e hija."
			}
		]
		if ConstellationTapestry.discovered_branches.size() >= 1:
			c19.append({
				"label": "✦ [Eco del Solsticio] Despertar la memoria de las constelaciones (+15% Inv, +12 Anclaje, +12 Sincronía)",
				"is_ng_echo": true,
				"effects": {"seal_investigation": 15, "human_anchor": 12, "abyssal_sync": 12},
				"outcome": "Tu hija reconoce tu mirada serena: en múltiples futuros ya le prometiste no soltar su mano."
			})
		return {
			"has_event": true,
			"act_id": 19,
			"is_twist": false,
			"title": "☀  ACTO III (EDAD 19): LA VÍSPERA DEL SOLSTICIO FINAL  ☀",
			"body": "Queda menos de un año para el vigésimo cumpleaños de %s. Los astrónomos de Aethelgard observan cómo la esfera armilar real gira en sentido inverso. Tu hija te espera en el observatorio mirando el horizonte nocturno:\n\n«Padre... el tiempo casi se agota. ¿Cómo nos recordará el mundo cuando la Diosa descienda a reclamar su deuda?»" % GameState.daughter_name,
			"choices": c19
		}

	# 8. Edictos Anuales del Senado Imperial (Edades 14, 16 y 18)
	if GameState.age >= 14 and not story_acts_seen.has(104):
		return {
			"has_event": true,
			"act_id": 104,
			"is_twist": false,
			"category": "senate",
			"title": "⚖  EDICTO DEL SENADO (EDAD 14): CENSO DE ASTROMANTES  ⚖",
			"body": "El Senado promulga el Primer Censo de Aptitud Astral para jóvenes nobles. Los alguaciles esperan en la puerta del observatorio.",
			"choices": [
				{
					"label": "❖ Presentar informes académicos impecables para eximirla del examen",
					"req_stat": "erudicion",
					"req_val": 170,
					"effects": {"father_reputation": 6, "court_suspicion": -12, "gold": 80},
					"outcome": "El comisario queda admirado ante la erudición de %s y archiva el expediente con honores." % GameState.daughter_name,
					"effects_fail": {"court_suspicion": 10, "stress": 5},
					"outcome_fail": "Los escribas encuentran lagunas en los registros (+10 Sospecha, +5 Estrés)."
				},
				{
					"label": "⚖ Pagar tasa de exención privada (-75 Oro, -8 Sospecha)",
					"effects": {"gold": -75, "court_suspicion": -8},
					"outcome": "El sello ducal zanja cualquier inspección pública."
				}
			]
		}
	if GameState.age >= 16 and not story_acts_seen.has(106):
		return {
			"has_event": true,
			"act_id": 106,
			"is_twist": false,
			"category": "senate",
			"title": "⚖  EDICTO DEL SENADO (EDAD 16): DIEZMO DE RELIQUIAS  ⚖",
			"body": "Ante las anomalías celestes, la Corona exige un impuesto extraordinario o un informe diplomático en el Palacio de Alabastro.",
			"choices": [
				{
					"label": "❀ Deslumbrar al consejo de nobles con etiqueta cortesana",
					"req_stat": "gracia",
					"req_val": 230,
					"effects": {"father_reputation": 8, "magnetismo": 16, "court_suspicion": -15},
					"outcome": "La corte entera aplaude la elegancia de %s y la dispensa del diezmo." % GameState.daughter_name,
					"effects_fail": {"court_suspicion": 12, "gold": -60},
					"outcome_fail": "Los nobles murmuran tras sus abanicos y exigen 60 Oro de tributo (+12 Sospecha)."
				},
				{
					"label": "❖ Abonar el diezmo real sin hacer preguntas (-100 Oro, -10 Sospecha)",
					"effects": {"gold": -100, "court_suspicion": -10},
					"outcome": "Cumples en silencio para proteger las investigaciones nocturnas."
				}
			]
		}
	if GameState.age >= 18 and not story_acts_seen.has(108):
		return {
			"has_event": true,
			"act_id": 108,
			"is_twist": false,
			"category": "senate",
			"title": "⚖  EDICTO DEL SENADO (EDAD 18): LEY DE CUSTODIA SOLAR  ⚖",
			"body": "Rumores sobre el Sello llegan a los senadores veteranos. Piden garantías sobre tu lealtad antes de los festejos de mayoría de edad.",
			"choices": [
				{
					"label": "⚔ Hacer valer tu autoridad como Héroe Veterano de la Guerra Antigua",
					"req_stat": "father_reputation",
					"req_val": 70,
					"effects": {"court_suspicion": -18, "human_anchor": 8, "gold": 120},
					"outcome": "El propio Canciller desestima las acusaciones y financia vuestro observatorio (+120 Oro).",
					"effects_fail": {"court_suspicion": 15, "stress": 8},
					"outcome_fail": "Sin suficiente peso político, la vigilancia alrededor de la mansión aumenta (+15 Sospecha)."
				},
				{
					"label": "❖ Entregar un dossier censurado de lecturas astronómicas (+10 Investigación, +6 Sospecha)",
					"effects": {"seal_investigation": 10, "court_suspicion": 6},
					"outcome": "Ganas tiempo valioso mientras el Senado analiza tus mapas incompletos."
				}
			]
		}

	# 9. Consecuencias por Omisión en NPCs ignorados
	if GameState.age >= 15 and not story_acts_seen.has(301):
		var k_npc: Dictionary = RelationshipManager.get_state("kaelen")
		if int(k_npc.get("stage", 1)) <= 1 and int(k_npc.get("affection", 0)) <= 28:
			return {
				"has_event": true,
				"act_id": 301,
				"is_twist": false,
				"category": "omission",
				"title": "%s  OMISIÓN EN LOS ACUEDUCTOS: FIEBRE DE ESCORIA  %s" % [AstralTheme.G_BOLT, AstralTheme.G_BOLT],
				"body": "Por haber descuidado los Acueductos, llega la noticia de que la Fiebre de Escoria golpea al taller de Kaelen. Su hermano menor corre peligro sin antídoto.",
				"choices": [
					{
						"label": "%s Financiar suministros médicos de emergencia (-70 Oro, +14 Afecto Kaelen, +6 Empatía)" % AstralTheme.G_HEART,
						"effects": {"gold": -70, "mood_pride": -6},
						"npc_boost": {"id": "kaelen", "aff": 14, "resp": 8},
						"outcome": "Tus medicinas llegan justo a tiempo; Kaelen guarda silencio, pero no olvidará el gesto."
					},
					{
						"label": "☠ Cerrar las compuertas del sector noble (+8 Sospecha, -6 Afecto Kaelen)",
						"effects": {"court_suspicion": 8},
						"npc_boost": {"id": "kaelen", "aff": -6, "resp": -4},
						"omission_tag": "kaelen_plague",
						"outcome": "Los canales bajos quedan sellados; el resentimiento de los artesanos hacia la nobleza crece."
					}
				]
			}
	if GameState.age >= 16 and not story_acts_seen.has(302):
		var v_npc: Dictionary = RelationshipManager.get_state("vespera")
		if int(v_npc.get("stage", 1)) <= 1 and int(v_npc.get("affection", 0)) <= 28:
			return {
				"has_event": true,
				"act_id": 302,
				"is_twist": false,
				"category": "omission",
				"title": "%s  OMISIÓN EN EL PATIO DUCAL: EL ULTIMÁTUM DEL DUQUE  %s" % [AstralTheme.G_BOLT, AstralTheme.G_BOLT],
				"body": "Sin aliados en la corte marcial, el padre de Vespera exige enviarla en una campaña fronteriza sin retorno para endurecer su temple.",
				"choices": [
					{
						"label": "⚔ Interceder en el duelo de honor para retenerla en Aethelgard",
						"req_stat": "temple",
						"req_val": 170,
						"effects": {"father_reputation": 4},
						"npc_boost": {"id": "vespera", "aff": 15, "resp": 10},
						"outcome": "Desarmas al campeón del Duque; Vespera contempla a tu familia con renovado respeto.",
						"effects_fail": {"stress": 6},
						"outcome_fail": "No logras frenar los planes del Duque; Vespera parte brevemente endurecida y distante."
					},
					{
						"label": "❖ No inmiscuirse en asuntos de la Casa Vespera (+5 Reputación, distancia con Vespera)",
						"effects": {"father_reputation": 5},
						"npc_boost": {"id": "vespera", "aff": -6, "resp": 2},
						"omission_tag": "vespera_exile",
						"outcome": "El Duque celebra tu discreción, aunque la joven generala endurece su coraza aún más."
					}
				]
			}
	if GameState.age >= 17 and not story_acts_seen.has(303):
		var c_npc: Dictionary = RelationshipManager.get_state("cassian")
		if int(c_npc.get("stage", 1)) <= 1 and int(c_npc.get("affection", 0)) <= 28:
			return {
				"has_event": true,
				"act_id": 303,
				"is_twist": false,
				"category": "omission",
				"title": "%s  OMISIÓN EN PALACIO: INTRIGAS DEL EMPERADOR  %s" % [AstralTheme.G_BOLT, AstralTheme.G_BOLT],
				"body": "Al mantenerte ajeno a las audiencias de Cassian, una facción rival dentro del Palacio de Alabastro ha tomado el control del comité presupuestario.",
				"choices": [
					{
						"label": "❀ Abrir diálogo tardío enviando credenciales diplomáticas (-80 Oro, +14 Afecto Cassian)",
						"effects": {"gold": -80},
						"npc_boost": {"id": "cassian", "aff": 14, "resp": 10},
						"outcome": "Cassian acepta la tregua con una sonrisa medida y frena el embargo."
					},
					{
						"label": "⚖ Afrontar el recorte de subsidios (+10 Sospecha del Senado)",
						"effects": {"court_suspicion": 10},
						"npc_boost": {"id": "cassian", "aff": -6, "resp": -4},
						"omission_tag": "cassian_embargo",
						"outcome": "El palacio incrementa sus inspecciones fiscales sobre vuestra mansión."
					}
				]
			}

	return {"has_event": false}

func apply_story_event_choice(act_id: int, choice: Dictionary) -> String:
	var passed: bool = true
	var req_stat: String = str(choice.get("req_stat", ""))
	if req_stat != "":
		passed = GameState.get_stat(req_stat) >= int(choice.get("req_val", 0))

	if act_id == 501:
		GameState.sick_dialogue_pending = false
	elif act_id == 401:
		GameState.pending_astral_crisis = false
	elif act_id == 201:
		GameState.senate_inspections_count += 1
	elif not story_acts_seen.has(act_id):
		story_acts_seen.append(act_id)

	var effects: Dictionary = choice.get("effects", {}) if passed else choice.get("effects_fail", {})
	var labels: Array[String] = []
	for k in effects.keys():
		var delta: int = int(effects[k])
		if str(k) == "gold":
			if delta < 0:
				GameState.gold = maxi(0, GameState.gold + delta)
				GameState.stats_updated.emit()
			else:
				GameState.modify_gold(delta)
			labels.append("Oro %+d G" % delta)
		else:
			GameState.modify_stat(str(k), delta)
			labels.append("%s %+d" % [GameState.get_stat_label(str(k)), delta])
	var npc_boost: Dictionary = choice.get("npc_boost", {})
	if not npc_boost.is_empty() and (passed or effects.is_empty()):
		var nid: String = str(npc_boost.get("id", ""))
		RelationshipManager.modify_npc_relation(nid, int(npc_boost.get("aff", 0)), int(npc_boost.get("resp", 0)))
	var om_tag: String = str(choice.get("omission_tag", ""))
	if om_tag != "" and not GameState.omitted_npc_events.has(om_tag):
		GameState.omitted_npc_events.append(om_tag)

	var outcome: String = str(choice.get("outcome", "")) if passed else str(choice.get("outcome_fail", choice.get("outcome", "")))
	if act_id == 17:
		Chronicle.record_event("twist_year_17", "EL GRAN GIRO: La Estrella era una Prisión", outcome, "twist", 5)
	elif act_id == 201:
		Chronicle.record_event("inquisition_%d" % GameState.senate_inspections_count, "Audiencia de Inquisición Solar", outcome, "senate", 4)
	elif act_id == 401:
		Chronicle.record_event("astral_crisis_%d_%d" % [TimeManager.current_year, TimeManager.current_bimester], "Crisis de Apetito Estelar", outcome, "twist", 4)
	elif act_id == 501:
		Chronicle.record_event("exhaustion_%d_%d" % [TimeManager.current_year, TimeManager.current_bimester], "Noche de Agotamiento", outcome, "family", 4)
	else:
		Chronicle.record_event("story_act_%d" % act_id, "Hito de Historia (%d)" % act_id, outcome, "lore", 5)
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
