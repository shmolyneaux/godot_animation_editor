tool
extends Control

var plugin = null setget set_plugin
var default_font

enum EditorState {IDLE, ROTATING}
var _state = EditorState.IDLE
var _state_info = {} # Arbitrary values that only make sense for the current state
var _last_mouse_pos = Vector2()
var _active_bone = null

var _rng = RandomNumberGenerator.new()

func set_plugin(new_plugin):
	plugin = new_plugin
	redraw()


func redraw():
	clear_labels()

	$VBoxContainer.add_child(HSeparator.new())

	if plugin:
		var anim_player: AnimationPlayer = plugin.active_animation_player
		if anim_player:
			var anim = anim_player.get_animation(anim_player.assigned_animation)
			if anim:
				for track_idx in range(anim.get_track_count()):
					var prop_path = anim.track_get_path(track_idx)
					var prop_node = anim_player.get_parent().get_node(prop_path)
					var prop_name = prop_path.get_concatenated_subnames()
					if prop_node is Skeleton:
						var bone_idx = prop_node.find_bone(prop_name)
						var point_up_button = Button.new()
						point_up_button.text = "Rotate " + prop_name
						if _active_bone == prop_path:
							point_up_button.modulate = Color.red
						$VBoxContainer.add_child(point_up_button)
						point_up_button.connect("pressed", self, "set_active_bone", [prop_path])
					else:
						var prop_value = prop_node.get(prop_name)
						add_label(prop_name + ": " + str(prop_value))
			else:
				add_label("Could not get assigned animation: " + anim_player.assigned_animation)
		else:
			add_label("ERROR: no animation player selected for Animation Editor Plugin")


func set_active_bone(prop_path):
	_active_bone = prop_path
	redraw()

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


func process_input(event):
	var consumed = false
	if not plugin.enabled:
		_state = EditorState.IDLE
		return false

	match _state:
		EditorState.IDLE:
			if event is InputEventKey and event.pressed:
				match event.scancode:
					KEY_R:
						if _active_bone:
							print("entering rotating state")

							var res = AnimationEditorUtils.skeleton_bone_from_path(
								plugin.active_animation_player.get_parent(),
								_active_bone
							)

							var bone_screen_pos = plugin.camera.unproject_position(
								res["skeleton"].get_bone_global_pose(res["bone_idx"]).origin
							)


							_state = EditorState.ROTATING
							_state_info["starting_mouse_pos"] = _last_mouse_pos
							_state_info["last_mouse_pos"] = _last_mouse_pos
							_state_info["active_bone"] = _active_bone
							_state_info["active_bone_starting_xform"] = res["skeleton"].get_bone_pose(res["bone_idx"])

							consumed = true
						else:
							print(plugin.active_animation_player)


							print("Can't start rotating when there's no active bone")

			elif event is InputEventMouseMotion:
				_last_mouse_pos = event.position

		EditorState.ROTATING:
			if event is InputEventKey and event.pressed:
				match event.scancode:
					# Revert the change
					KEY_ESCAPE:
						print("entering idle state")
						_state = EditorState.IDLE
						consumed = true

						var res = AnimationEditorUtils.skeleton_bone_from_path(
							plugin.active_animation_player.get_parent(),
							_active_bone
						)

						res["skeleton"].set_bone_pose(res["bone_idx"], _state_info["active_bone_starting_xform"])

					# Accept the change
					KEY_ENTER, KEY_KP_ENTER:
						print("entering idle state")
						_state = EditorState.IDLE
						consumed = true

			elif event is InputEventMouseButton and event.pressed:
				match event.button_index:
					# Accept the change
					BUTTON_LEFT:
						print("entering idle state")
						_state = EditorState.IDLE
						consumed = true

			elif event is InputEventMouseMotion:
				var res = AnimationEditorUtils.skeleton_bone_from_path(
					plugin.active_animation_player.get_parent(),
					_active_bone
				)

				var bone_screen_pos = plugin.camera.unproject_position(
					res["skeleton"].get_bone_global_pose(res["bone_idx"]).origin
				)
				var last_angle = _state_info["last_mouse_pos"] - bone_screen_pos
				var current_angle = event.position - bone_screen_pos
				_state_info["last_mouse_pos"] = event.position


				var rotation_amount = current_angle.angle_to(last_angle)

				var skel: Skeleton = plugin.active_animation_player.get_parent().get_node(_state_info["active_bone"])
				var prop_name = _state_info["active_bone"].get_concatenated_subnames()
				var bone_idx = skel.find_bone(prop_name)

				var inverse_rest = skel.get_bone_rest(bone_idx).affine_inverse()

				var parent = skel.get_bone_parent(bone_idx)
				var inverse_parent_global = Transform.IDENTITY
				if parent != -1:
					inverse_parent_global = skel.get_bone_global_pose(parent).affine_inverse()

				var global_pose = skel.get_bone_global_pose(bone_idx)
				global_pose.basis = global_pose.basis.rotated(plugin.camera.get_global_transform().basis.z, rotation_amount)

				var local_pose = inverse_rest * inverse_parent_global * global_pose

				skel.set_bone_pose(bone_idx, local_pose)

	return consumed


func _process(delta):
	update()


func _draw():
	if plugin and plugin.active_animation_player and _active_bone and _state == EditorState.ROTATING:
		var res = AnimationEditorUtils.skeleton_bone_from_path(
			plugin.active_animation_player.get_parent(),
			_active_bone
		)

		var screen_pos = plugin.camera.unproject_position(res["skeleton"].get_bone_global_pose(res["bone_idx"]).origin)

		# Your draw commands here
		draw_line(_state_info["last_mouse_pos"], screen_pos, Color.red)

		draw_string(default_font, Vector2(64, 64), str(_state_info["last_mouse_pos"]))


func add_label(text):
	var track_label = Label.new()
	track_label.text = str(text)
	$VBoxContainer.add_child(track_label)


func clear_labels():
	for node in $VBoxContainer.get_children():
		node.queue_free()


# Called when the node enters the scene tree for the first time.
func _ready():
	default_font = Control.new().get_font("font")
	_rng.randomize()

