@tool
extends VBoxContainer

# define for hq spawns
const SPAWN_POINT = preload("res://objects/entities/SpawnPoint.tscn")
const AI_SPAWNER = preload("res://objects/Gameplay/AI/AI_Spawner.tscn")
const HQ_PLAYER_SPAWNER = preload("res://objects/Gameplay/Common/HQ_PlayerSpawner.tscn")
const POLYGON_VOLUME = preload("res://addons/bf_portal/portal_tools/types/PolygonVolume/PolygonVolume.tscn")

# define objects
const HIGHWAY_SIGN_POLE_01 = preload("res://objects/Global/Generic/Common/Props/HighwaySignPole_01.tscn") # MAP IMPORT OUTLINE 
const WORLD_ICON = preload("res://objects/Gameplay/Common/WorldIcon.tscn") # NAME TAGS
const SHELL_CASINGS_01 = preload("res://objects/Global/Props/ShellCasings_01.tscn") # SPECTATOR
const SHELL_CASINGS_02 = preload("res://objects/Global/Props/ShellCasings_02.tscn") # 
const SHELL_CASINGS_03 = preload("res://objects/Global/Props/ShellCasings_03.tscn") # 
const SHELL_CASINGS_04 = preload("res://objects/Global/Props/ShellCasings_04.tscn") # 
const BACKPACK_01 = preload("res://objects/Shared/Generic/Common/Props/Backpack_01.tscn") # Bomb
const CRATE_AMMO_01_STACK_A = preload("res://objects/Global/Generic/Military/Props/CrateAmmo_01_StackA.tscn") # demolition site objects
const WEAPON_CASE_PISTOL_01 = preload("res://objects/Global/Generic/Military/Props/WeaponCase_Pistol_01.tscn") # Bomb

# define object ids
const BOMB_ID = 20
const HOSTAGE_ID = 30
const SPECTATOR_ID = 50
const SPAWNER_ID = 100
const NAMETAG_ID = 700

func _on_btn_import_pressed() -> void:
	importCoordinates("res://addons/SealMapper/coordinates.csv")

func _on_btn_create_icons_pressed() -> void:
	createTeamNameIcons()

func _on_btn_create_spectators_pressed() -> void:
	createSpectatorSpawns()

func _on_btn_create_spawn_points_pressed() -> void:
	createHQPlayerSpawns()

func _on_btn_create_demo_pkg_pressed() -> void:
	createDemolitionPackage()

func _on_btn_create_extract_pkg_pressed() -> void:
	createExtractionPackage()

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
	var container_node
	var container_name = "[SealMapper] LAYOUT"
	if (node.has_node(container_name)):
		container_node = node.get_node(container_name)
	else:
		container_node = __createNode(container_name, node)
		
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
		__instantiateObj(HIGHWAY_SIGN_POLE_01, "SealMapper_" + str(line_num), pos, container_node, -1)
		
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

# auto generates all the items required for the demolition game mode
# 1 object for bomb, 2 plant site objects , 3 world icons
func createDemolitionPackage() -> void:
	#@todo: world icons for Bomb & Plant Sites
	var origin = Vector3(0,0,0)
	var rootNode = EditorInterface.get_edited_scene_root()
	# create organizing node
	var demo_node
	var demo_node_name = "[SealMapper] DEMOLITION"
	if (rootNode.has_node(demo_node_name)):
		demo_node = rootNode.get_node(demo_node_name)
	else:
		demo_node = __createNode(demo_node_name, rootNode)
	demo_node.position = Vector3(0, -50, 0)
		
	# create bomb pickup object
	var item_name = "Demolition_Bomb"
	if (demo_node.has_node(item_name)):
		print("[~][SealMapper] skipping object with name %s" % item_name)
	else:
		__instantiateObj(WEAPON_CASE_PISTOL_01, item_name, origin, demo_node, BOMB_ID)
		print("[+][SealMapper] created bomb object with name %s" % item_name)
	
	# create plant site objects for each team
	for i in range(2):
		var node_name = "Demolition_Objective_" + str(i + 1)
		if (demo_node.has_node(node_name)):
			print("[~][SealMapper] skipping objective %s" % node_name)
			continue
		# create objective object
		var ID = i + BOMB_ID
		__instantiateObj(CRATE_AMMO_01_STACK_A, node_name, origin, demo_node, ID)
		print("[+][SealMapper] created objective with name %s & id %d" %[node_name, ID])
	print("[+][SealMapper] completed demolition mode generation.")
	MessageBox("")

# auto generates all the items required for the extraction game mode
# 1HQ w/ polygon volume, 3 spawn points & 1 AI Spawner
func createExtractionPackage() -> void:
	var origin = Vector3(0,0,0)
	var rootNode = EditorInterface.get_edited_scene_root()
	# create organizing node
	var extract_node
	var extract_node_name = "[SealMapper] EXTRACT"
	if (rootNode.has_node(extract_node_name)):
		extract_node = rootNode.get_node(extract_node_name)
	else:
		extract_node = __createNode(extract_node_name, rootNode)
	extract_node.position = Vector3(0, -100, 0)
	
	# create HQ object
	var hq_node
	var item_name = "HOSTAGE_HQ"
	if (extract_node.has_node(item_name)):
		hq_node = extract_node.get_node(item_name)
		print("[~][SealMapper] skipping object with name %s")
	else:
		__instantiateObj(HQ_PLAYER_SPAWNER, item_name, origin, extract_node, HOSTAGE_ID)
		hq_node = extract_node.get_node(item_name)
		hq_node.HQEnabled = true
		hq_node.Team = 0
		hq_node.AltTeam = 0
		hq_node.VehicleSpawnersEnabled = false
		hq_node.ForceRedeploy = false
		print("[+][SealMapper] created hostage hq with name %s & id %d" %[item_name, HOSTAGE_ID])
	# create polygon volume
	var polygon_name = "HOSTAGE"
	if (hq_node.has_node(polygon_name)):
		print("[~][SealMapper] skipping object with name %s" % polygon_name)
	else:
		var polygon_obj = POLYGON_VOLUME.instantiate()
		hq_node.add_child(polygon_obj)
		polygon_obj.name = polygon_name
		polygon_obj.owner = rootNode  # Must be scene root for visibility in Scene panel
		polygon_obj.scene_file_path = ""
		print("[+][SealMapper] created polygon object with name %s for hostage hq" % polygon_name)
	# create spawner
	var spawner_name = "Hostage_Spawner"
	if (hq_node.has_node(spawner_name)):
		print("[~][SealMapper] skipping spawner object with name %s" % spawner_name)
	else:
		var spawner_id = SPAWNER_ID + 3
		__instantiateObj(AI_SPAWNER, spawner_name, origin, hq_node, spawner_id)
		print("[+][SealMapper] created spawner object with name %s & id %d for hostage hq" % [spawner_name, spawner_id])
	# create spawn points
	var spawner = hq_node.get_node(spawner_name)
	for i in range(3):
		var spawn_name = "SpawnPoint_3_" + str(i + 1)
		if (hq_node.has_node(spawn_name)):
			print("[~][SealMapper] skipping spawn point object with name %s" % spawn_name)
			continue
		__instantiateObj(SPAWN_POINT, spawn_name, origin, hq_node, -1)
		if (hq_node.InfantrySpawns.size() <= i):
			hq_node.InfantrySpawns.push_back(hq_node.get_node(spawn_name)) # adds the spawn point to the spawns array
		if (spawner.AlternateSpawns.size() <= i):
			spawner.AlternateSpawns.push_back(hq_node.get_node(spawn_name)) # adds the spawn point to the spawner
		print("[+][SealMapper] created spawn point with name %s for hostage hq" % spawn_name)
	print("[+][SealMapper] completed extraction mode generation.")
	MessageBox("")
	
# node = SceneRoot
func __generateHQSpawnPoints(node: Node):
	var origin = Vector3(0, 0, 0)
	for i in range(2):
		var ID = i + 1
		var base_name = "TEAM_" + str(ID) + "_HQ" # "TEAM_1_HQ" : "TEAM_2_HQ"
		if (node.has_node(base_name) == false):
			print("[!][SealMapper] unable to find HQ node %s , skipping." % base_name)
			continue
		# get the team hq node
		var team_hq_node = node.get_node(base_name)
		# add the AI Spawner
		var spawner_name = "AI_Spawner_" + str(ID)
		if (team_hq_node.has_node(spawner_name)):
			print("[~][SealMapper] skipping %s" % spawner_name)
			continue
		__instantiateObj(AI_SPAWNER, spawner_name, origin, team_hq_node, SPAWNER_ID + i)
		var spawner_node = team_hq_node.get_node(spawner_name)
		# create players spawn points until 16 
		# name: SpawnPoint_hqID_spawnIndex 
		for j in range(16):
			var node_name = "SpawnPoint_" + str(ID) + "_" + str(j + 1)
			if (team_hq_node.has_node(node_name)):
				if (spawner_node.AlternateSpawns.size() <= j):
					spawner_node.AlternateSpawns.push_back(team_hq_node.get_node(node_name))
				print("[~][SealMapper] skipping %s" % node_name)
				continue
			# create spawn point
			__instantiateObj(SPAWN_POINT, node_name, origin, team_hq_node, -1)
			if (team_hq_node.InfantrySpawns.size() <= j):
				team_hq_node.InfantrySpawns.push_back(team_hq_node.get_node(node_name))
			if (spawner_node.AlternateSpawns.size() <= j):
				spawner_node.AlternateSpawns.push_back(team_hq_node.get_node(node_name))
			print("[+][SealMapper] created spawn point with name %s for team %d" %[node_name, ID])
		print("[+][SealMapper] created ai spawner with name %s for team %d" %[spawner_name, ID])

# node = SceneRoot
func __generateIcons(node: Node) -> void:
	var origin = Vector3(0,0,0)
	var container_node
	var container_name = "[SealMapper] ICONS"
	if (node.has_node(container_name)):
		container_node = node.get_node(container_name)
	else:
		container_node = __createNode(container_name, node)
	container_node.position = Vector3(0, -10, 0)
	
	for i in range(32):
		var node_name = "WorldIcon_NameTag_" + str(i + 1)
		if (node.has_node(node_name)):
			print("[~][SealMapper] skipping nametag icon %s" % node_name)
			continue
		# create icon
		var ID = NAMETAG_ID + i
		__instantiateObj(WORLD_ICON, node_name, origin, container_node, ID)
		print("[+][SealMapper] created icon with name %s & id %s" % [node_name, ID])

# node = SceneRoot
func __generateSpectatorObjects(node: Node) -> void:
	var origin = Vector3(0,0,0)
	var container_node
	var container_name = "[SealMapper] SPECTATORS"
	if (node.has_node(container_name)):
		container_node = node.get_node(container_name)
	else:
		container_node = __createNode(container_name, node)
	container_node.position = Vector3(0, 10, 0)
	
	for i in range(2):
		var node_name = "Spectator_Object_" + str(i)
		if (node.has_node(node_name)):
			print("[~][SealMapper] skipping spectator object %s" % node_name)
			continue
		# create object
		var ID = SPECTATOR_ID + i
		__instantiateObj(SHELL_CASINGS_01, node_name, origin, container_node, ID)
		print("[+][SealMapper] created spectator object with id: %d" % ID)

# creates a node which will act as a folder
func __createNode(node_name: String, parentNode: Node) -> Node3D:
	var rootNode = EditorInterface.get_edited_scene_root()
	var new_node = Node3D.new()
	parentNode.add_child(new_node)
	new_node.name = node_name
	new_node.owner = rootNode
	new_node.scene_file_path = ""
	return new_node

# does exactly what the name implies
# parentNode is where the object will be added as a child
func __instantiateObj(item: PackedScene, node_name: String, origin: Vector3, parentNode: Node, id: int) -> void:
	var OBJ = item.instantiate()
	var rootNode = EditorInterface.get_edited_scene_root()
	parentNode.add_child(OBJ)
	OBJ.ObjId = id
	OBJ.name = node_name
	OBJ.position = origin
	OBJ.owner = rootNode  # Must be scene root for visibility in Scene panel
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
