tool
extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func add_debug_xform(xform):
	print("adding debug shape")
	# Create a debug shape for our xform
	var debug_cube = MeshInstance.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0
	mesh.bottom_radius = 0.2
	mesh.height = 0.5
	debug_cube.mesh = mesh
	debug_cube.translation.y = 0.25

	# Position our debug shape to match the input. We use a spatial to wrap the
	# debug shape so that we don't need to account for the translation.
	var spatial = Spatial.new()
	spatial.global_transform = xform
	spatial.add_child(debug_cube)

	add_child(spatial)


func debug(thing):
	pass


func clear_debug():
	print("clearing debug shapes")
	for child in get_children():
		child.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
