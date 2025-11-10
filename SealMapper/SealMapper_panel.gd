@tool
extends VBoxContainer

# define object for map tracing
const HIGHWAY_SIGN_POLE_01 = preload("res://objects/Global/Generic/Common/Props/HighwaySignPole_01.tscn") # MAP IMPORT OUTLINE 
const WORLD_ICON = preload("res://objects/Gameplay/Common/WorldIcon.tscn") # NAME TAGS
const SHELL_CASINGS_01 = preload("res://objects/Global/Props/ShellCasings_01.tscn") # SPECTATOR
const SHELL_CASINGS_02 = preload("res://objects/Global/Props/ShellCasings_02.tscn") # 
const SHELL_CASINGS_03 = preload("res://objects/Global/Props/ShellCasings_03.tscn") # 
const SHELL_CASINGS_04 = preload("res://objects/Global/Props/ShellCasings_04.tscn") # 

const SPECTATOR_ID = 50
const NAMETAG_ID = 700


func _on_btn_import_pressed() -> void:
	importCoordinates("res://addons/SealMapper/coordinates.csv")


func _on_btn_create_icons_pressed() -> void:
	createTeamNameIcons()

func _on_btn_create_spectators_pressed() -> void:
	createSpectatorSpawns()


func importCoordinates(input: String) -> void:
	# open file
	print("[+][SealMapperPanel] attempting to open coordinates file.")
	var file := FileAccess.open(input, FileAccess.READ)
	if file == null:
		MessageBox("failed to open coordinates file. are you sure it exists? it must be placed in the addons folder.")
		print("[!][SealMapperPanel] failed")
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
		var base_name = "SealMapper_" + str(line_num)
		spawnPlaceholderObject(node, base_name, pos)
		
		line_num += 1
		#continue loop ( reading file )
		
	# Show success dialog ( finished reading file )
	MessageBox("loaded coordinates from file & spawned objects")
	print("[+][SealMapperPanel] finished.")


func spawnPlaceholderObject(node: Node, name_: String, pos: Vector3) -> void:
	## Create a MeshInstance3D node with a visible mesh
	## var instance = MeshInstance3D.new()
	
	## Create a simple box mesh as a marker
	## var box_mesh = BoxMesh.new()
	### var box_mesh = CylinderMesh.new()
	## box_mesh.size = Vector3(2.0, 2.0, 2.0)  # 2x2x2 unit box
	## instance.mesh = box_mesh
	
	# Create a basic material to make it more visible
	## var material = StandardMaterial3D.new()
	## material.albedo_color = Color.RED
	## material.emission_enabled = true
	#material.emission = Color.RED * 0.3  # Add slight glow
	## instance.material_override = material
 	
	## 
	var instance = HIGHWAY_SIGN_POLE_01.instantiate()
	
	# Add to scene
	node.add_child(instance)
	instance.name = name_
	instance.position = pos
	instance.owner = node
	print("[+][SealMapperPanel] spawned object at location: x: %.2f , y: %.2f , z: %.2f" % [pos.x, pos.y, pos.z])
 

# auto genetate name tag icons with team id
func createTeamNameIcons() -> void:
	var origin = Vector3(0,0,0)
	var node = EditorInterface.get_edited_scene_root()
	if (node.has_node("TeamIcon_1")): # try to prevent duplicate auto generate
		MessageBox("ignoring icon generation due to TeamIcon already present.")
		return
	
	var base_name = "WorldIcon_NameTag_"
	print("[+][SealMapperPanel] generating icons for nametags.")
	for i in range(32):
		var ID = NAMETAG_ID + i
		var ICON = WORLD_ICON.instantiate()
		node.add_child(ICON)
		ICON.ObjId = ID
		ICON.name = base_name + str(i + 1)
		ICON.iconTextVisible = true
		ICON.iconImageVisible = true
		ICON.position = origin
		ICON.owner = node
		ICON.scene_file_path = ""
		print("[+][SealMapperPanel] created icon with id: %d" % ID)
	print("[+][SealMapperPanel] completed nametag icon generation.")
	MessageBox("created world icons for name tags.")

# auto generate spectator spawns for each team
func createSpectatorSpawns() -> void:
	var origin = Vector3(10,10,10)
	var node = EditorInterface.get_edited_scene_root()
	if (node.has_node("Spectator_Object_1")):
		MessageBox("")
		return
	
	var base_name = "Spectator_Object_"
	print("[+][SealMapper] generating spectator objects for spawn locations.")
	for i in range(2):
		var ID = SPECTATOR_ID + i
		var OBJ = SHELL_CASINGS_01.instantiate()
		node.add_child(OBJ)
		OBJ.ObjId = ID
		OBJ.name = base_name + str(i)
		OBJ.position = origin
		OBJ.owner = node
		OBJ.scene_file_path = ""
		print("[+][SealMapper] created spectator object with id: %d" % ID)
	print("[+][SealMapper] completed spectator spawn generation.")
	MessageBox("created items for spectator spawns. You still need to reposition the items.")

# display a message box to the user
func MessageBox(msg: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.dialog_text = msg
	EditorInterface.popup_dialog_centered(dialog)
