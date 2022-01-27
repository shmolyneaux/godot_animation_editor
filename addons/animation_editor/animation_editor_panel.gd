tool
extends Panel

var plugin = null setget set_plugin

var _rng = RandomNumberGenerator.new()

func set_plugin(new_plugin):
	plugin = new_plugin
	redraw()


func redraw():
	clear_labels()
	add_label(str(plugin))
	add_label(str(_rng.randi()))

	var random_animation_button = Button.new()
	random_animation_button.text = str("Random Anim")
	$VBoxContainer.add_child(random_animation_button)
	random_animation_button.connect("pressed", self, "plugin_random_animation")

	var redraw_button = Button.new()
	redraw_button.text = str("Redraw")
	$VBoxContainer.add_child(redraw_button)
	redraw_button.connect("pressed", self, "redraw")

	if plugin:
		if plugin.camera:
			add_label("Camera Translation:" + str(plugin.camera.translation))
			$Canvas.add_debug_xform(plugin.camera.get_global_transform())

		var anim_player: AnimationPlayer = plugin.active_animation_player
		if anim_player:
			add_label("Assigned Anim:" + anim_player.assigned_animation)
			add_label("Current Anim:" + anim_player.current_animation)
			var anim = anim_player.get_animation(anim_player.assigned_animation)
			if anim:
				for track_idx in range(anim.get_track_count()):
					var prop_path = anim.track_get_path(track_idx)
					add_label(str(prop_path))
					var prop_node = anim_player.get_parent().get_node(prop_path)
					var prop_name = prop_path.get_concatenated_subnames()
					if prop_node is Skeleton:
						var bone_idx = prop_node.find_bone(prop_name)
						add_label(str(prop_node.get_bone_pose(bone_idx)))

						var point_up_button = Button.new()
						point_up_button.text = "Rotate " + prop_name
						$VBoxContainer.add_child(point_up_button)
						point_up_button.connect("pressed", self, "rotate_bone_test", [prop_path])
					else:
						var prop_value = prop_node.get(prop_name)
						add_label(prop_name + ": " + str(prop_value))
			else:
				add_label("Could not get assigned animation: " + anim_player.assigned_animation)
		else:
			add_label("ERROR: no animation player selected for Animation Editor Plugin")


func rotate_bone_test(prop_path):
	print("rotate_bone")
	var skel: Skeleton = plugin.active_animation_player.get_parent().get_node(prop_path)
	var prop_name = prop_path.get_concatenated_subnames()
	var bone_idx = skel.find_bone(prop_name)

	var time = OS.get_ticks_msec() / 1000.0
	var time_wrapped = (OS.get_ticks_msec() % 3141) / 3141.0

	var inverse_rest = skel.get_bone_rest(bone_idx).affine_inverse()

	var parent = skel.get_bone_parent(bone_idx)
	var inverse_parent_global = Transform.IDENTITY
	if parent != -1:
		inverse_parent_global = skel.get_bone_global_pose(parent).affine_inverse()

	var global_pose = skel.get_bone_global_pose(bone_idx)
	global_pose.basis = global_pose.basis.rotated(plugin.camera.get_global_transform().basis.z, 3.1415/8)

	var local_pose = inverse_rest * inverse_parent_global * global_pose

	skel.set_bone_pose(bone_idx, local_pose)


	$Canvas.clear_debug()
	$Canvas.add_debug_xform(global_pose)


func _input(event):
	pass


func add_label(text):
	var track_label = Label.new()
	track_label.text = str(text)
	$VBoxContainer.add_child(track_label)

func clear_labels():
	for node in $VBoxContainer.get_children():
		node.queue_free()



func plugin_random_animation():
	if plugin:
		var anim_player: AnimationPlayer = plugin.active_animation_player
		var animation_list = anim_player.get_animation_list()
		var anim_num = _rng.randi() % animation_list.size()
		anim_player.assigned_animation = animation_list[anim_num]

		var anim_length = anim_player.get_animation(animation_list[anim_num]).length
		anim_player.seek(_rng.randf_range(0.0, anim_length), true)

		print("======================= SHM ==================================")
		print("random animation: ", anim_player.assigned_animation, " ", anim_num)
		print("play position: ", anim_player.current_animation_position)
		redraw()

		# The EditorNode has always been the first child of the editor viewport.
		var editor_node = plugin.get_editor_interface().get_base_control().get_viewport().get_children()[0]
		for editor_plugin in editor_node.get_children():
			pass

# Called when the node enters the scene tree for the first time.
func _ready():
	_rng.randomize()

