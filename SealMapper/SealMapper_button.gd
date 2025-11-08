@tool
extends Button

# location of the file
@export var coordinate_file: String = "res://addons/SealMapper/coordinates.csv"

# fire event
func _enter_tree():
	pressed.connect(clicked)

# button click event
func clicked():
	# open file
	print("[+][SiB] attempting to open coordinates file.")
	var file := FileAccess.open(coordinate_file, FileAccess.READ)
	if file == null:
		print("[!][SiB] failed to open coordinates file. are you sure it exists?")
		return
		
	# print contents of file
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
		print("	- [%d]: x: %.2f , y: %.2f , z: %.2f" % [line_num + 1, x, y, z])
		
		# spawn objects at locations
		var base_name = "SealMapper_" + str(line_num)
		spawnObject(node, base_name, pos)
		
		line_num += 1
		#continue loop ( reading file )
		
	# Show success dialog ( finished reading file )
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "loaded coordinates from file & spawned objects"
	EditorInterface.popup_dialog_centered(dialog)
	print("[+][SiB] finished.")

func spawnObject(node: Node, name_: String, pos: Vector3):
	# Create a MeshInstance3D node with a visible mesh
	var instance = MeshInstance3D.new()
	
	# Create a simple box mesh as a marker
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(2.0, 2.0, 2.0)  # 2x2x2 unit box
	instance.mesh = box_mesh
	
	# Create a basic material to make it more visible
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.RED  # Make it red so it's easily visible
	material.emission_enabled = true
	material.emission = Color.RED * 0.3  # Add slight glow
	instance.material_override = material
	
	# Add to scene
	node.add_child(instance)
	instance.name = name_
	instance.position = pos
	instance.owner = node
