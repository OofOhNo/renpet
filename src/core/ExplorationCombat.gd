extends Node

## ExplorationCombat.gd - Sistema de Exploración en 5 Regiones, Combate Táctico de Cartas,
## Botón "Entreabrir el Sello", Festival de las Constelaciones y Eventos de Historia (Fases 7 y 8).

signal combat_updated()
signal combat_finished(victory: bool, summary: String)

var explored_this_bimester: bool = false
var festival_entered_this_year: bool = false
var memory_shards_found: Array[String] = []
var story_acts_seen: Array[int] = []

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
		"shard_title": "Esquirla II: La Traición al Lucero del Cambio",
		"shard_lore": "El mural sumergido muestra a dos dioses: la Señora de la Eternidad Estática y Nyx-Aethel, el Lucero del Cambio Libre. Ella no lo destruyó; lo encerró dentro de un astro vivo."
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
		"shard_title": "Esquirla III: El Molde de Carne y Estrella",
		"shard_lore": "Una inscripción secreta revela por qué la Diosa convirtió la estrella-prisión en una niña humana: necesitaba que el amor mortal alimentara el Sello durante veinte años."
	},
	{
		"id": "zone_4",
		"name": "IV. Cráter de la Primera Caída",
		"min_age": 16,
		"difficulty": 4,
		"desc": "El abismo donde descendió la estrella de Renpet; la gravedad se curva en espirales violetas.",
		"enemy_name": "Sombra del Sarcófago",
		"enemy_title": "Fragmento de Nyx-Aethel",
		"enemy_icon": "res://assets/ui/enemy_abyssal.png",
		"boss_name": "Heraldo del Eclipse Carmesí",
		"boss_title": "Vanguardia Abisal",
		"base_hp": 920,
		"base_atk": 112,
		"stagger_max": 120,
		"gold_reward": 420,
		"loot_id": "sarcophagus_shard",
		"shard_id": "shard_4",
		"shard_title": "Esquirla IV: Las Cadenas de Renpet-Neheh",
		"shard_lore": "En el centro del cráter hallas el primer eslabón del Sello: si el Sello permanece al 100%, la Diosa absorberá tu alma a los 20 años; si se rompe sin amor humano, el eclipse te consumirá."
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
		"name": "⚔️ Justa de las Espadas Solares",
		"rival_id": "vespera",
		"rival_name": "Dama Vespera de Val-Astra",
		"stats": ["temple", "destreza", "gravedad"],
		"reward_gold": 300,
		"reward_item": "quartz_marrow",
		"desc": "Combate de exhibición en el Coliseo Real evaluando Temple, Destreza y Gravedad."
	},
	{
		"id": "contest_astrolabe",
		"name": "🔭 Certamen del Gran Astrolabio",
		"rival_id": "soren",
		"rival_name": "Soren de Caelum",
		"stats": ["erudicion", "resonancia", "luminiscencia"],
		"reward_gold": 300,
		"reward_item": "melted_hourglass",
		"desc": "Debate de cálculo estelar y predicción temporal evaluando Erudición, Resonancia y Luminiscencia."
	},
	{
		"id": "contest_moons",
		"name": "🪷 Danza de las Siete Lunas",
		"rival_id": "lyra",
		"rival_name": "Lady Lyra de Meridia",
		"stats": ["gracia", "magnetismo", "luminiscencia"],
		"reward_gold": 300,
		"reward_item": "goddess_tear",
		"desc": "Gala imperial de música, danza y protocolo evaluando Gracia, Magnetismo y Luminiscencia."
	},
	{
		"id": "contest_clockwork",
		"name": "⚗️ Gala Alquímica del Reloj Real",
		"rival_id": "caelum",
		"rival_name": "Caelum 'El Lobo Gris'",
		"stats": ["destreza", "erudicion", "resonancia"],
		"reward_gold": 300,
		"reward_item": "comet_dust",
		"desc": "Prueba de precisión táctica, reliquias y reflejos evaluando Destreza, Erudición y Resonancia."
	}
]

# Estado en vivo del Combate Táctico
var in_combat: bool = false
var current_zone: Dictionary = {}
var current_stage: int = 1 # 1: Vanguardia, 2: Santuario/Jefe
var companion_id: String = "vespera"
var companion_name: String = "Dama Vespera"

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

func start_expedition(zone_idx: int, comp_id: String, comp_display_name: String) -> Dictionary:
	if zone_idx < 0 or zone_idx >= ZONES.size():
		return {"ok": false, "msg": "Región inválida."}
	var z: Dictionary = ZONES[zone_idx]
	if GameState.age < int(z["min_age"]):
		return {"ok": false, "msg": "Renpet debe tener al menos %d años para adentrarse en %s." % [int(z["min_age"]), z["name"]]}
	if explored_this_bimester:
		return {"ok": false, "msg": "Renpet ya realizó una expedición fuera de las murallas en este bimestre."}
		
	explored_this_bimester = true
	current_zone = z
	current_stage = 1
	companion_id = comp_id
	companion_name = comp_display_name
	
	player_max_hp = 180 + GameState.temple * 2 + GameState.gravedad
	player_hp = player_max_hp
	player_shield = 0
	player_max_ap = 4 if GameState.has_mutation("paradoja_menor") else 3
	player_ap = player_max_ap
	rewind_charges = 1
	unsealed_this_combat = false
	
	_setup_stage_enemy(1)
	in_combat = true
	combat_log.clear()
	combat_log.append("[color=#FFE082]✦ Expedición iniciada en %s junto a %s.[/color]" % [z["name"], companion_name])
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
		dmg_mult *= 1.20
		
	match card_id:
		"solar_slash":
			if player_ap < 1:
				combat_log.append("[color=#FF8A80]No tienes suficientes Puntos de Acción (PA).[/color]")
				combat_updated.emit()
				return
			player_ap -= 1
			var base_d: int = 45 + int((GameState.temple + GameState.destreza) * 0.35)
			if companion_id == "vespera":
				base_d = int(round(base_d * 1.25))
			var final_d: int = int(round(base_d * dmg_mult))
			var stag_d: int = 28 if companion_id == "vespera" else 18
			_apply_damage_to_enemy(final_d, stag_d, "⚔️ Tajo de Horus")
			
		"lotus_guard":
			if player_ap < 1:
				combat_log.append("[color=#FF8A80]No tienes suficientes PA.[/color]")
				combat_updated.emit()
				return
			player_ap -= 1
			var sh_gain: int = 45 + int((GameState.gracia + GameState.gravedad) * 0.35)
			player_shield += sh_gain
			var heal_v: int = 20 + int(GameState.luminiscencia * 0.12)
			player_hp = mini(player_max_hp, player_hp + heal_v)
			combat_log.append("[color=#80DEEA]🛡️ Égida de Loto: +%d Escudo Astral y +%d HP restaurado.[/color]" % [sh_gain, heal_v])
			
		"starlight_ray":
			if player_ap < 2:
				combat_log.append("[color=#FF8A80]Cometa de Sothis requiere 2 PA.[/color]")
				combat_updated.emit()
				return
			player_ap -= 2
			var base_d: int = 95 + int((GameState.luminiscencia + GameState.erudicion) * 0.52)
			if companion_id == "soren":
				base_d = int(round(base_d * 1.25))
			var final_d: int = int(round(base_d * dmg_mult))
			_apply_damage_to_enemy(final_d, 32, "✨ Cometa de Sothis")
			
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
			_execute_companion_active_skill(dmg_mult)
			
		"rewind":
			if rewind_charges <= 0:
				combat_log.append("[color=#FF8A80]Ya utilizaste el Rebobinado Temporal en esta expedición.[/color]")
				combat_updated.emit()
				return
			rewind_charges -= 1
			var heal_r: int = int(player_max_hp * 0.40)
			player_hp = mini(player_max_hp, player_hp + heal_r)
			player_ap = mini(player_max_ap + 1, player_ap + 2)
			player_shield += 40
			combat_log.append("[color=#FFF176]⏪ REBOBINADO TEMPORAL: El reloj gira hacia atrás (+%d HP, +40 Escudo, +2 PA).[/color]" % heal_r)
			
		"unseal":
			# EL BOTÓN TENTADOR: ENTREABRIR EL SELLO ESTELAR (0 PA)
			var seal_cost: int = -4 if companion_id == "zephyr" else -8
			GameState.modify_stat("seal_integrity", seal_cost)
			GameState.modify_stat("abyssal_sync", 7)
			unsealed_this_combat = true
			var abyssal_dmg: int = 180 + int((GameState.gravedad + GameState.resonancia + GameState.abyssal_sync * 4) * 0.65)
			player_hp = mini(player_max_hp, player_hp + int(player_max_hp * 0.35))
			player_ap += 2
			Chronicle.record_event("unseal_combat", "El Sello Entreabierto en Batalla", "Para derrotar a %s, Renpet liberó el fuego violeta de Nyx-Aethel (%d%% Sello)." % [enemy_name, seal_cost], "twist", 5)
			combat_log.append("[color=#FF80AB][b]☥ ¡SELLO ENTREABIERTO! Fulgor de Nyx-Aethel (%d%% Integridad del Sello, +7%% Sincronía, +2 PA)[/b][/color]" % seal_cost)
			_apply_damage_to_enemy(abyssal_dmg, 999, "☥ Eclipse de Nyx-Aethel")
			
	_check_enemy_defeat_or_continue()

func _execute_companion_active_skill(dmg_mult: float) -> void:
	match companion_id:
		"vespera":
			var d: int = int(round((70 + GameState.temple * 0.35) * dmg_mult))
			_apply_damage_to_enemy(d, 40, "❄️ Lanza Ducal de Vespera")
		"soren":
			var d: int = int(round((65 + GameState.erudicion * 0.35) * dmg_mult))
			player_shield += 35
			_apply_damage_to_enemy(d, 30, "🔭 Refractor Astral de Soren")
		"kaelen":
			var d: int = int(round((65 + GameState.destreza * 0.35) * dmg_mult))
			GameState.modify_gold(35)
			_apply_damage_to_enemy(d, 25, "🗡️ Emboscada de Azogue de Kaelen (+35G)")
		"cassian":
			var d: int = int(round((75 + GameState.magnetismo * 0.35) * dmg_mult))
			player_shield += 40
			_apply_damage_to_enemy(d, 25, "☀️ Mandato Solar de Cassian")
		"mirari":
			var heal_m: int = 75 + int(GameState.luminiscencia * 0.25)
			player_hp = mini(player_max_hp, player_hp + heal_m)
			player_shield += 50
			GameState.modify_stat("seal_integrity", 2)
			combat_log.append("[color=#81C784]🎵 Arpa de Mirari: +%d HP, +50 Escudo y +2%% Integridad del Sello.[/color]" % heal_m)
		"zephyr":
			var d: int = int(round((95 + GameState.resonancia * 0.45) * dmg_mult))
			_apply_damage_to_enemy(d, 35, "🌌 Cadenas del Espejo de Zephyr")

func _apply_damage_to_enemy(dmg: int, stagger_add: int, skill_label: String) -> void:
	enemy_hp = maxi(0, enemy_hp - dmg)
	if not enemy_staggered:
		enemy_stagger += stagger_add
		if enemy_stagger >= enemy_max_stagger:
			enemy_stagger = enemy_max_stagger
			enemy_staggered = true
			combat_log.append("[color=#FFF176]★ ¡QUIEBRE DE GUARDIA! %s queda vulnerable (Daño x1.5 y pierde su ataque).[/color]" % enemy_name)
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
		if companion_id == "kaelen" and (randi() % 100) < 25:
			combat_log.append("[color=#80DEEA]¡Cortina de humo de Kaelen! Esquivaste por completo el ataque de %s.[/color]" % enemy_name)
		else:
			var blocked: int = mini(player_shield, incoming)
			player_shield -= blocked
			var hp_loss: int = incoming - blocked
			player_hp = maxi(0, player_hp - hp_loss)
			combat_log.append("[color=#FF8A80]%s ataca: %d daño (%d absorbido por Escudo).[/color]" % [enemy_name, hp_loss, blocked])
			
	if companion_id == "mirari" and player_hp > 0:
		var regen: int = int(player_max_hp * 0.10)
		player_hp = mini(player_max_hp, player_hp + regen)
		
	if player_hp <= 0:
		in_combat = false
		GameState.modify_stat("stress", 18)
		var defeat_msg: String = "%s tuvo que retirarse de %s tras caer agotada (+18 Estrés)." % [GameState.daughter_name, current_zone["name"]]
		combat_finished.emit(false, defeat_msg)
		return
		
	player_ap = player_max_ap
	player_shield = int(player_shield * 0.35)
	combat_updated.emit()

func _check_enemy_defeat_or_continue() -> void:
	if enemy_hp > 0:
		combat_updated.emit()
		return
		
	if current_stage == 1:
		# Avanzar al Jefe de Región y descubrir Esquirla de Memoria
		var shard_id: String = current_zone["shard_id"]
		var shard_msg: String = ""
		if not memory_shards_found.has(shard_id):
			memory_shards_found.append(shard_id)
			GameState.modify_stat("seal_investigation", 15)
			Chronicle.record_event(shard_id, current_zone["shard_title"], current_zone["shard_lore"], "twist", 5)
			shard_msg = "\n[color=#FFF176][b]★ %s (+15%% Investigación del Sello):[/b]\n%s[/color]" % [
				current_zone["shard_title"], current_zone["shard_lore"]
			]
		_setup_stage_enemy(2)
		player_ap = player_max_ap
		combat_log.append("[color=#81C784]¡Vanguardia derrotada! Avanzas al santuario interior: aparece [b]%s[/b].[/color]%s" % [enemy_name, shard_msg])
		combat_updated.emit()
	else:
		# Victoria Total en la Expedición
		in_combat = false
		var gold_won: int = int(current_zone["gold_reward"])
		if companion_id == "kaelen":
			gold_won = int(round(gold_won * 1.40))
		GameState.modify_gold(gold_won)
		GameState.modify_stat("temple", 16)
		GameState.modify_stat("resonancia", 16)
		var loot_key: String = current_zone["loot_id"]
		GameState.materials_inventory[loot_key] = GameState.materials_inventory.get(loot_key, 0) + 1
		Chronicle.record_event("exp_win_" + str(current_zone["id"]), "Conquista de " + str(current_zone["name"]), "Renpet y %s derrotaron a %s." % [companion_name, enemy_name], "expedition", 4)
		var win_summary: String = "¡Victoria en %s! Derrotaste a %s junto a %s.\nRecompensas: +%d Oro, +16 Temple, +16 Resonancia y +1 reliquia para el Crisol Astral." % [
			current_zone["name"], enemy_name, companion_name, gold_won
		]
		combat_finished.emit(true, win_summary)

# ==============================================================================
# LÓGICA DEL GRAN FESTIVAL DE LAS CONSTELACIONES DE OTOÑO (FASE 8)
# ==============================================================================
func participate_in_festival(contest_idx: int, rival_mirror_dict: Dictionary) -> Dictionary:
	if TimeManager.current_bimester != TimeManager.FESTIVAL_BIMESTER:
		return {"ok": false, "msg": "El Gran Festival de las Constelaciones se celebra en el Bimestre 4 (Cosecha, Equinoccio de Otoño). Aún puedes prepararte."}
	if festival_entered_this_year:
		return {"ok": false, "msg": "Renpet ya compitió en el certamen oficial del Festival de Otoño de este año."}
	if contest_idx < 0 or contest_idx >= FESTIVAL_CONTESTS.size():
		return {"ok": false, "msg": "Certamen inválido."}
		
	festival_entered_this_year = true
	var c: Dictionary = FESTIVAL_CONTESTS[contest_idx]
	var stat_list: Array = c["stats"]
	var my_total: int = 0
	for sk in stat_list:
		my_total += int(GameState.get(sk))
	if GameState.unlocked_synergies.has("horizon_valkyrie") and c["id"] == "contest_blades":
		my_total += 60
		
	var r_id: String = c["rival_id"]
	var riv_base: int = int(rival_mirror_dict.get(r_id, {}).get("score", 250))
	var target_score: int = int(round(riv_base * 1.35))
	
	if my_total >= target_score:
		var g_rew: int = int(c["reward_gold"])
		var item_k: String = c["reward_item"]
		GameState.modify_gold(g_rew)
		GameState.modify_stat("magnetismo", 24)
		GameState.modify_stat("affection", 10)
		GameState.materials_inventory[item_k] = GameState.materials_inventory.get(item_k, 0) + 1
		Chronicle.record_event("festival_champion_" + str(TimeManager.current_year), "Campeona del Festival de Otoño (%s)" % c["name"], "Renpet venció a %s con %d pts frente a %d pts." % [c["rival_name"], my_total, target_score], "festival", 5)
		return {
			"ok": true,
			"title": "👑 ¡CAMPEONA DEL FESTIVAL DE LAS CONSTELACIONES!",
			"summary": "¡%s deslumbró a toda la capital en [b]%s[/b], superando a %s (%d pts vs %d pts)!\n\n[color=#81C784]Premio Imperial: +%d Oro, +24 Magnetismo, +10 Afecto y +1 Reliquia Sagrada para el Crisol.[/color]" % [
				GameState.daughter_name, c["name"], c["rival_name"], my_total, target_score, g_rew
			]
		}
	else:
		GameState.modify_gold(80)
		GameState.modify_stat(stat_list[0], 15)
		Chronicle.record_event("festival_runner_" + str(TimeManager.current_year), "Finalista en el Festival (%s)" % c["name"], "Renpet obtuvo el segundo puesto tras %s (%d vs %d)." % [c["rival_name"], my_total, target_score], "festival", 3)
		return {
			"ok": true,
			"title": "🥈 Segundo Puesto en el Coliseo de las Constelaciones",
			"summary": "%s dio una gran demostración en [b]%s[/b], pero %s se llevó la corona por %d a %d.\n\n[color=#FFD54F]Premio de Finalista: +80 Oro y +15 %s por la experiencia.[/color]" % [
				GameState.daughter_name, c["name"], c["rival_name"], target_score, my_total, str(stat_list[0]).capitalize()
			]
		}

# ==============================================================================
# EVENTOS DE HISTORIA PRINCIPAL Y EL GRAN GIRO DEL AÑO 17 (FASE 8)
# ==============================================================================
func check_pending_main_story_event() -> Dictionary:
	# Acto I -> II (Edad 14): El Primer Latido del Sarcófago
	if GameState.age >= 14 and not story_acts_seen.has(14):
		story_acts_seen.append(14)
		return {
			"has_event": true,
			"act_id": 14,
			"title": "𓇳 ACTO II (EDAD 14): LA RESONANCIA DEL SARCÓFAGO ESTELAR 𓇳",
			"body": "Durante la noche del Equinoccio, el observatorio entero tiembla. El tatuaje solar en el pecho de %s se ilumina con jeroglíficos dorados y, por un instante, su sombra proyecta las alas encadenadas de una entidad ancestral.\n\n«Papá... dentro de mi pecho hay alguien más respirando. Dice que se llama Zephyr, y que la Diosa que salvaste no es quien creemos.»" % GameState.daughter_name,
			"choices": [
				{"label": "♥ Abrazarla con fuerza: «No importa qué haya en esa estrella; tú eres mi hija humana.» (+12 Anclaje Humano, -15 Estrés)", "effects": {"human_anchor": 12, "stress": -15, "affection": 10}},
				{"label": "🔍 Estudiar los jeroglíficos de su pecho juntos en la bóveda (+15% Investigación del Sello, +20 Erudición)", "effects": {"seal_investigation": 15, "erudicion": 20}},
				{"label": "🌌 Enseñarle a escuchar a Zephyr sin miedo (+12 Sincronía con Nyx-Aethel, +20 Resonancia)", "effects": {"abyssal_sync": 12, "resonancia": 20}}
			]
		}
	# Acto II -> III (Edad 17): EL GRAN GIRO — LA ESTRELLA ERA UNA PRISIÓN
	if GameState.age >= 17 and not story_acts_seen.has(17):
		story_acts_seen.append(17)
		Chronicle.record_event("twist_year_17", "EL GRAN GIRO: La Estrella era una Prisión", "Se reveló que la Diosa Renpet-Neheh usó a Renpet como prisión viviente de Nyx-Aethel para cosecharlos a los 20 años.", "twist", 5)
		return {
			"has_event": true,
			"act_id": 17,
			"title": "🌘 EL GRAN GIRO (EDAD 17): «LA ESTRELLA ERA UNA PRISIÓN» 🌘",
			"body": "Un Heraldo de la Diosa de la Eternidad desciende sobre el balcón del observatorio. Con voz de campanas heladas anuncia que quedan tres años para la Cosecha del Solsticio:\n\n«Héroe %s, la estrella que recibiste hace diecisiete años era el Sarcófago Celestial donde encerramos a Nyx-Aethel, el espíritu del Cambio. Tu crianza ha servido para madurar el Sello. Cuando %s cumpla veinte años, la Diosa absorberá a ambos para congelar el tiempo para siempre.»" % [GameState.father_name, GameState.daughter_name],
			"choices": [
				{"label": "⚔️ Desenvainar tu arma de Héroe: «¡Desafiaré a la misma Diosa que liberé antes de entregarle a mi hija!» (+15 Anclaje Humano, +25 Temple)", "effects": {"human_anchor": 15, "temple": 25, "affection": 15}},
				{"label": "☯️ Forjar el Pacto del Tercer Camino con Zephyr y los planos del Sello (+20% Investigación, +15 Sincronía, +10 Anclaje)", "effects": {"seal_investigation": 20, "abyssal_sync": 15, "human_anchor": 10}},
				{"label": "🌑 Dejar que la ira de Nyx-Aethel agriete el Sello frente al Heraldo (-15% Sello, +20 Sincronía, +30 Gravedad)", "effects": {"seal_integrity": -15, "abyssal_sync": 20, "gravedad": 30}}
			]
		}
	return {"has_event": false}
