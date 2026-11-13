extends SceneTree
## Uso: godot --path . --script tools/screenshot.gd -- <escena> <salida.png> [acciones separadas por coma]
## Carga una escena, espera unos fotogramas y guarda una captura del viewport.
## Acciones soportadas: open:<ventana> (schedule, status, hearth, crucible, town, explore), prologue_off

func _init() -> void:
	await process_frame
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var scene_path: String = args[0] if args.size() > 0 else "res://src/scenes/ManorHub.tscn"
	var out_path: String = args[1] if args.size() > 1 else "/tmp/shot.png"
	var actions: PackedStringArray = args[2].split(",") if args.size() > 2 else PackedStringArray()
	var scene: PackedScene = load(scene_path)
	var inst: Node = scene.instantiate()
	root.add_child(inst)
	for i in range(10):
		await process_frame
	for a in actions:
		if a == "prologue_off" and inst.has_method("debug_skip_prologue"):
			inst.call("debug_skip_prologue")
		elif a.begins_with("open:") and inst.has_method("debug_open_window"):
			inst.call("debug_open_window", a.substr(5))
		elif a.begins_with("call:") and inst.has_method(a.substr(5)):
			inst.call(a.substr(5))
		for i in range(6):
			await process_frame
	for i in range(30):
		await process_frame
	var img: Image = root.get_texture().get_image()
	img.save_png(out_path)
	print("captura guardada: ", out_path, " ", img.get_size())
	quit()
