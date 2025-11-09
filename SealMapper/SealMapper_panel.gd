@tool
extends VBoxContainer

func _on_btn_import_pressed() -> void:
	importCoordinates("res://addons/SealMapper/coordinates.csv")


func _on_btn_create_icons_pressed() -> void:
	createTeamNameIcons()


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
	
	# 
	## var instance = HighwaySignPole_01.new(); # @TODO: need to figure out how to include the mesh for the item
	
	# Add to scene
	node.add_child(instance)
	instance.name = name_
	instance.position = pos
	instance.owner = node
	print("[+][SealMapperPanel] spawned object at location: x: %.2f , y: %.2f , z: %.2f" % [pos.x, pos.y, pos.z])


func createTeamNameIcons() -> void:
	var origin = Vector3(0,0,0)
	var node = EditorInterface.get_edited_scene_root()
	if (node.has_node("TeamIcon_")):
		MessageBox("ignoring icon generation due to TeamIcon already present.")
		return
	
	var base_name = "TeamIcon_"
	print("[+][SealMapperPanel] generating icons for nametags.")
	for i in range(32):
		var ID = 700 + i
		var ICON = WorldIcon.new()
		node.add_child(ICON)
		ICON.ObjId = ID
		ICON.name = base_name + str(i)
		ICON.position = origin
		ICON.owner = node
		print("[+][SealMapperPanel] created icon with id: %d", % ID)
	MessageBox("created world icons for name tags.")

# display a message box to the user
func MessageBox(msg: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.text = msg
	EditorInterface.popup_dialog_centered(dialog)
