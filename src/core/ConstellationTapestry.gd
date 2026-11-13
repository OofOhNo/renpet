extends Node

## ConstellationTapestry - El Tapiz de las Constelaciones (Metaprogresión y New Game+, Fase 9.3).
## Persistencia global en user://constellation_tapestry.json independiente de las ranuras de partida.

signal tapestry_updated()

const SAVE_PATH: String = "user://constellation_tapestry.json"

const BOONS: Array[Dictionary] = [
	{
		"id": "hero_treasury",
		"name": "Arca del Héroe Retirado",
		"cost": 60,
		"desc": "+600 de Oro inicial para invertir en la Mansión, dieta y academia desde el Turno 1."
	},
	{
		"id": "ancestral_blade",
		"name": "Memoria del Acero Antiguo",
		"cost": 75,
		"desc": "+60 Temple y +60 Destreza iniciales para dominar el Patio Ducal y las expediciones."
	},
	{
		"id": "solar_library",
		"name": "Códices de la Biblioteca Solar",
		"cost": 75,
		"desc": "+60 Erudición y +50 Luminiscencia iniciales en el Astrolabio."
	},
	{
		"id": "mortal_cradle",
		"name": "Cuna del Corazón Mortal",
		"cost": 80,
		"desc": "+15 Anclaje Humano y +12 Afecto paternal iniciales al comenzar la campaña."
	},
	{
		"id": "observatory_echo",
		"name": "Eco del Observatorio Velado",
		"cost": 90,
		"desc": "+15% Progreso de Indagación inicial y +15 Sincronía con el Espejo."
	},
	{
		"id": "crucible_satchel",
		"name": "Alforja Alquímica del Crisol",
		"cost": 85,
		"desc": "Comienzas con +2 Polvo de Cometa, +2 Médula de Cuarzo y +1 Lágrima de la Diosa."
	},
	{
		"id": "legendary_reputation",
		"name": "Nombre Legendario en Aethelgard",
		"cost": 95,
		"desc": "+20 Reputación Paterna y +15 Afecto inicial con todos los candidatos desbloqueados."
	},
	{
		"id": "tireless_guardian",
		"name": "Vitalidad Incansable del Héroe",
		"cost": 110,
		"desc": "+25 Energía Máxima del Padre (125 PA totales por bimestre para planificar tus tareas)."
	}
]

var astral_points: int = 0
var total_campaigns: int = 0
var discovered_endings: Dictionary = {}     # ending_id -> Dictionary
var discovered_branches: Array[String] = []
var discovered_bonds: Array[String] = []
var purchased_boons: Array[String] = []
var active_boons: Array[String] = []

func _ready() -> void:
	load_tapestry()

func load_tapestry() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var d: Dictionary = parsed
	astral_points = int(d.get("astral_points", 0))
	total_campaigns = int(d.get("total_campaigns", 0))
	discovered_endings = d.get("discovered_endings", {}) if typeof(d.get("discovered_endings", {})) == TYPE_DICTIONARY else {}
	discovered_branches.clear()
	for b in d.get("discovered_branches", []):
		discovered_branches.append(str(b))
	discovered_bonds.clear()
	for nb in d.get("discovered_bonds", []):
		discovered_bonds.append(str(nb))
	purchased_boons.clear()
	for pb in d.get("purchased_boons", []):
		purchased_boons.append(str(pb))
	active_boons.clear()
	for ab in d.get("active_boons", []):
		var s: String = str(ab)
		if purchased_boons.has(s) and not active_boons.has(s):
			active_boons.append(s)

func save_tapestry() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	var payload: Dictionary = {
		"astral_points": astral_points,
		"total_campaigns": total_campaigns,
		"discovered_endings": discovered_endings,
		"discovered_branches": discovered_branches,
		"discovered_bonds": discovered_bonds,
		"purchased_boons": purchased_boons,
		"active_boons": active_boons
	}
	f.store_string(JSON.stringify(payload, "\t"))
	f.close()
	tapestry_updated.emit()

func record_campaign_completion(evaluation: Dictionary) -> Dictionary:
	total_campaigns += 1
	var ending_id: String = str(evaluation.get("ending_id", ""))
	var branch_id: String = str(evaluation.get("branch_id", ""))
	var branch_name: String = str(evaluation.get("branch", {}).get("name", branch_id))
	var voc_id: String = str(evaluation.get("vocation_id", ""))
	var voc_name: String = str(evaluation.get("vocation", {}).get("name", voc_id))
	var bond_id: String = str(evaluation.get("bond", {}).get("primary_id", ""))

	var is_new_ending: bool = not discovered_endings.has(ending_id)
	var is_new_branch: bool = branch_id != "" and not discovered_branches.has(branch_id)
	var is_new_bond: bool = bond_id != "" and not discovered_bonds.has(bond_id)

	if is_new_ending and ending_id != "":
		discovered_endings[ending_id] = {
			"id": ending_id,
			"title": str(evaluation.get("ending_title", "")),
			"branch_id": branch_id,
			"branch_name": branch_name,
			"vocation_id": voc_id,
			"vocation_name": voc_name,
			"daughter_name": GameState.daughter_name,
			"unlocked_at": int(Time.get_unix_time_from_system())
		}
	if is_new_branch:
		discovered_branches.append(branch_id)
	if is_new_bond:
		discovered_bonds.append(bond_id)

	var metrics: Dictionary = evaluation.get("metrics", {})
	var earned: int = 45
	if is_new_ending:
		earned += 35
	if is_new_branch:
		earned += 40
	if is_new_bond:
		earned += 20
	earned += int(metrics.get("festival_wins", 0)) * 15
	earned += int(metrics.get("shards", 0)) * 10
	astral_points += earned
	save_tapestry()

	return {
		"earned_points": earned,
		"total_points": astral_points,
		"is_new_ending": is_new_ending,
		"is_new_branch": is_new_branch,
		"is_new_bond": is_new_bond,
		"unlocked_count": discovered_endings.size(),
		"total_matrix": EndingEvaluator.BRANCH_ORDER.size() * EndingEvaluator.VOCATION_ORDER.size()
	}

func purchase_boon(boon_id: String) -> Dictionary:
	if purchased_boons.has(boon_id):
		return {"ok": false, "msg": "Esta bendición ya fue desbloqueada."}
	var cost: int = 0
	var bname: String = boon_id
	for b in BOONS:
		if b["id"] == boon_id:
			cost = int(b["cost"])
			bname = str(b["name"])
			break
	if cost <= 0:
		return {"ok": false, "msg": "Bendición desconocida."}
	if astral_points < cost:
		return {"ok": false, "msg": "Necesitas %d Puntos de Constelación (tienes %d)." % [cost, astral_points]}
	astral_points -= cost
	purchased_boons.append(boon_id)
	active_boons.append(boon_id)
	save_tapestry()
	return {"ok": true, "msg": "Bendición desbloqueada y activada: %s" % bname}

func toggle_boon(boon_id: String) -> void:
	if not purchased_boons.has(boon_id):
		return
	if active_boons.has(boon_id):
		active_boons.erase(boon_id)
	else:
		active_boons.append(boon_id)
	save_tapestry()

func get_active_boon_names() -> Array[String]:
	var out: Array[String] = []
	for b in BOONS:
		if active_boons.has(b["id"]):
			out.append(str(b["name"]))
	return out

func apply_active_boons_to_new_game() -> Array[String]:
	if active_boons.is_empty():
		return []
	var applied: Array[String] = []
	GameState.begin_batch()
	for bid in active_boons:
		match bid:
			"hero_treasury":
				GameState.gold += 600
				applied.append("+600 Oro")
			"ancestral_blade":
				GameState.modify_stat("temple", 60)
				GameState.modify_stat("destreza", 60)
				applied.append("+60 Temple/Destreza")
			"solar_library":
				GameState.modify_stat("erudicion", 60)
				GameState.modify_stat("luminiscencia", 50)
				applied.append("+60 Erudición/+50 Lum.")
			"mortal_cradle":
				GameState.modify_stat("human_anchor", 15)
				GameState.modify_stat("affection", 12)
				applied.append("+15 Anclaje/+12 Afecto")
			"observatory_echo":
				GameState.modify_stat("seal_investigation", 15)
				GameState.modify_stat("abyssal_sync", 15)
				applied.append("+15% Indagación/+15 Sincronía")
			"crucible_satchel":
				GameState.materials_inventory["comet_dust"] = int(GameState.materials_inventory.get("comet_dust", 0)) + 2
				GameState.materials_inventory["quartz_marrow"] = int(GameState.materials_inventory.get("quartz_marrow", 0)) + 2
				GameState.materials_inventory["goddess_tear"] = int(GameState.materials_inventory.get("goddess_tear", 0)) + 1
				applied.append("+5 Reliquias del Crisol")
			"legendary_reputation":
				GameState.modify_stat("father_reputation", 20)
				for npc_id in RelationshipManager.NPC_ORDER:
					if RelationshipManager.state.has(npc_id):
						RelationshipManager.state[npc_id]["affection"] = clampi(int(RelationshipManager.state[npc_id]["affection"]) + 15, -100, 100)
				applied.append("+20 Rep./+15 Afecto NPCs")
			"tireless_guardian":
				GameState.father_max_energy = 125
				GameState.father_energy = 125
				applied.append("125 Energía del Padre")
	GameState.end_batch()
	GameState.gold_changed.emit(GameState.gold)
	return applied
