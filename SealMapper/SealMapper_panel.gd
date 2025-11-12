@tool
extends VBoxContainer

# define for hq spawns
const SPAWN_POINT = preload("res://objects/entities/SpawnPoint.tscn")

# define object for map tracing
const HIGHWAY_SIGN_POLE_01 = preload("res://objects/Global/Generic/Common/Props/HighwaySignPole_01.tscn") # MAP IMPORT OUTLINE 
const WORLD_ICON = preload("res://objects/Gameplay/Common/WorldIcon.tscn") # NAME TAGS
const SHELL_CASINGS_01 = preload("res://objects/Global/Props/ShellCasings_01.tscn") # SPECTATOR
const SHELL_CASINGS_02 = preload("res://objects/Global/Props/ShellCasings_02.tscn") # 
const SHELL_CASINGS_03 = preload("res://objects/Global/Props/ShellCasings_03.tscn") # 
const SHELL_CASINGS_04 = preload("res://objects/Global/Props/ShellCasings_04.tscn") # 

# define object ids
const SPECTATOR_ID = 50
const NAMETAG_ID = 700


func _on_btn_import_pressed() -> void:
	importCoordinates("res://addons/SealMapper/coordinates.csv")


func _on_btn_create_icons_pressed() -> void:
	createTeamNameIcons()

func _on_btn_create_spectators_pressed() -> void:
	createSpectatorSpawns()

func _on_btn_create_spawn_points_pressed() -> void:
	createHQPlayerSpawns()


# reads CSV file and spawns objects at the locations obtained from the CSV file
func importCoordinates(input: String) -> void:
	# open file
	print("[+][SealMapper] attempting to open coordinates file.")
	var file := FileAccess.open(input, FileAccess.READ)
	if file == null:
		MessageBox("failed to open coordinates file. are you sure it exists? it must be placed in the addons folder.")
		print("[!][SealMapper] failed")
		return
		
	var node = EditorInterface.get_edited_scene_root()
	var line_num = 0
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line == "" or line.begins_with("["): # skip labels like [1]
			continue
		var parts = line.split(",", false)
		if parts.size() < 3:
			continue
			
		var x = float(parts[0])
		var y = float(parts[1])
		var z = float(parts[2])
		var pos = Vector3(x, y, z) * 1.0
		
		# print locations in output for user
		## print("	- [%d]: x: %.2f , y: %.2f , z: %.2f" % [line_num + 1, x, y, z])
		
		# spawn objects at locations
		__instantiateObj(HIGHWAY_SIGN_POLE_01, "SealMapper_" + str(line_num), pos, node, -1)
		
		line_num += 1
		#continue loop ( reading file )
		
	# Show success dialog ( finished reading file )
	MessageBox("loaded coordinates from file & spawned objects")
	print("[+][SealMapper] finished.")

# auto generate player & ai spawn points for each team (seals & mercs)
func createHQPlayerSpawns() -> void:
	print("[+][SealMapper] generating spawn points for each team.")
	var node = EditorInterface.get_edited_scene_root()
	__generateHQSpawnPoints(node)
	
	print("[+][SealMapper] completed generating spawn points.")
	MessageBox("created spawn points for each team. You will need to manually assign each infantry spawn point as well as assign spawn points for the AI Spawners. Additionally it is required to relocate the item inside of each team hq node within the Scene panel asset viewer.")

# auto genetate name tag icons with team id
func createTeamNameIcons() -> void:
	print("[+][SealMapper] generating icons for nametags.")
	var node = EditorInterface.get_edited_scene_root()
	__generateIcons(node)
	
	print("[+][SealMapper] completed nametag icon generation.")
	MessageBox("created world icons for name tags.")

# auto generate spectator spawns for each team
func createSpectatorSpawns() -> void:
	print("[+][SealMapper] generating spectator objects for spawn locations.")
	var node = EditorInterface.get_edited_scene_root()
	__generateSpectatorObjects(node)
	
	print("[+][SealMapper] completed spectator spawn generation.")
	MessageBox("created objects for spectator spawns. You will need to reposition them.")

# node = SceneRoot
func __generateHQSpawnPoints(node: Node):
	var origin = Vector3(0, 0, 0)
	for i in range(2):
		var ID = i + 1
		var base_name = "TEAM_" + str(ID) + "_HQ" # "TEAM_1_HQ" : "TEAM_2_HQ"
		if (node.has_node(base_name) == false):
			print("[!][SealMapper] unable to find HQ node %s , skipping." % base_name)
			continue
		# create players spawn points until 16 
		var team_hq_node = node.get_node(base_name)
		# name: SpawnPoint_hqID_spawnIndex 
		for j in range(16):
			var node_name = "SpawnPoint_" + str(ID) + "_" + str(j + 1)
			if (team_hq_node.has_node(node_name)):
				print("[~][SealMapper] skipping %s" % node_name)
				continue
			continue
			# create spawn point
			__instantiateObj(SPAWN_POINT, node_name, origin, node, -1)
			print("[+][SealMapper] created spawn point with name %s for team %d" %[node_name, ID])

# node = SceneRoot
func __generateIcons(node: Node) -> void:
	var origin = Vector3(0,0,0)
	for i in range(32):
		var node_name = "WorldIcon_NameTag_" + str(i + 1)
		if (node.has_node(node_name)):
			print("[~][SealMapper] skipping nametag icon %s" % node_name)
			continue
		# create icon
		var ID = NAMETAG_ID + i
		__instantiateObj(WORLD_ICON, node_name, origin, node, ID)
		print("[+][SealMapper] created icon with name %s & id %s" % [node_name, ID])

# node = SceneRoot
func __generateSpectatorObjects(node: Node) -> void:
	var origin = Vector3(10,10,10)
	for i in range(2):
		var node_name = "Spectator_Object_" + str(i)
		if (node.has_node(node_name)):
			print("[~][SealMapper] skipping spectator object %s" % node_name)
			continue
		# create object
		var ID = SPECTATOR_ID + i
		__instantiateObj(SHELL_CASINGS_01, node_name, origin, node, ID)
		print("[+][SealMapper] created spectator object with id: %d" % ID)

# does exactly what the name implies
func __instantiateObj(item: PackedScene, node_name: String, origin: Vector3, parentNode: Node, id: int) -> void:
	var OBJ = item.instantiate()
	parentNode.add_child(OBJ)
	OBJ.ObjId = id
	OBJ.name = node_name
	OBJ.position = origin
	OBJ.owner = parentNode
	OBJ.scene_file_path = ""

# spawns a 2x2x2 red cube with slight glow ( does not render in game )
func __spawnPlaceholderObject(node: Node, name_: String, pos: Vector3) -> void:
	# Create a MeshInstance3D node with a visible mesh
	var instance = MeshInstance3D.new()
	
	# Create a simple box mesh as a marker
	var box_mesh = BoxMesh.new()
	### var box_mesh = CylinderMesh.new()
	box_mesh.size = Vector3(2.0, 2.0, 2.0)  # 2x2x2 unit box
	instance.mesh = box_mesh
	
	# Create a basic material to make it more visible
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.RED
	material.emission_enabled = true
	material.emission = Color.RED * 0.3  # Add slight glow
	instance.material_override = material
	
	# Add to scene
	node.add_child(instance)
	instance.name = name_
	instance.position = pos
	instance.owner = node
	print("[+][SealMapper] spawned object at location: x: %.2f , y: %.2f , z: %.2f" % [pos.x, pos.y, pos.z])

# display a message box to the user
func MessageBox(msg: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.dialog_text = msg
	EditorInterface.popup_dialog_centered(dialog)
