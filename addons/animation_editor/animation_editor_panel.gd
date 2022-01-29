tool
extends Control

var camera = null
var default_font = null
var anim_player = null setget set_anim_player

enum EditorState {IDLE, ROTATING}
var _state = EditorState.IDLE
var _state_info = {} # Arbitrary values that only make sense for the current state
var _last_mouse_pos = Vector2()
var _active_bone = null

var _rng = RandomNumberGenerator.new()

func set_anim_player(new_anim_player):
	anim_player = new_anim_player
	redraw()


func redraw():
	if not anim_player:
		print("ERROR: asked to redraw when there's no anim player")
		return

	clear_labels()

	# TODO: add armature picker

	$VBoxContainer.add_child(HSeparator.new())

	var current_animation = anim_player.assigned_animation
	var anim = anim_player.get_animation(current_animation)
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
				add_label("UNEDITABLE " + prop_name + ": " + str(prop_value))
	else:
		print("Could not get assigned animation: ", current_animation)


func set_active_bone(prop_path):
	_active_bone = prop_path
	redraw()


func _accept_rotation_update():
	print("entering idle state")
	_state = EditorState.IDLE

	if not anim_player:
		print("No animation player found for Animation Editor!")
		return

	var anim = anim_player.get_animation(anim_player.assigned_animation)
	if not anim:
		print("No active animation found for Animation Editor!")
		return

	var active_anim_track = null
	for track_idx in range(anim.get_track_count()):
		if _state_info["active_bone"] == anim.track_get_path(track_idx):
			active_anim_track = track_idx

	if active_anim_track == null:
		print("Could not find animation track for Animation Editor!")
		return

	var res = AnimationEditorUtils.skeleton_bone_from_path(
		anim_player.get_parent(),
		_active_bone
	)
	var current_xform = res["skeleton"].get_bone_pose(res["bone_idx"])

	anim.transform_track_insert_key(
		active_anim_track,
		anim_player.current_animation_position,
		current_xform.origin,
		current_xform.basis.get_rotation_quat(),
		current_xform.basis.get_scale()
	)

func process_input(event):
	var consumed = false
	if not visible:
		return consumed

	match _state:
		EditorState.IDLE:
			if event is InputEventKey and event.pressed:
				match event.scancode:
					KEY_R:
						if _active_bone:
							print("entering rotating state")

							var res = AnimationEditorUtils.skeleton_bone_from_path(
								anim_player.get_parent(),
								_active_bone
							)

							var bone_screen_pos = camera.unproject_position(
								res["skeleton"].get_bone_global_pose(res["bone_idx"]).origin
							)


							_state = EditorState.ROTATING
							_state_info["starting_mouse_pos"] = _last_mouse_pos
							_state_info["last_mouse_pos"] = _last_mouse_pos
							_state_info["active_bone"] = _active_bone
							_state_info["active_bone_starting_xform"] = res["skeleton"].get_bone_pose(res["bone_idx"])

							consumed = true
						else:
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
							anim_player.get_parent(),
							_active_bone
						)

						res["skeleton"].set_bone_pose(res["bone_idx"], _state_info["active_bone_starting_xform"])

					KEY_ENTER, KEY_KP_ENTER:
						_accept_rotation_update()
						consumed = true

			elif event is InputEventMouseButton and event.pressed:
				match event.button_index:
					BUTTON_LEFT:
						_accept_rotation_update()
						consumed = true

			elif event is InputEventMouseMotion:
				var res = AnimationEditorUtils.skeleton_bone_from_path(
					anim_player.get_parent(),
					_active_bone
				)

				var bone_screen_pos = camera.unproject_position(
					res["skeleton"].get_bone_global_pose(res["bone_idx"]).origin
				)
				var last_angle = _state_info["last_mouse_pos"] - bone_screen_pos
				var current_angle = event.position - bone_screen_pos
				_state_info["last_mouse_pos"] = event.position


				var rotation_amount = current_angle.angle_to(last_angle)

				var skel: Skeleton = anim_player.get_parent().get_node(_state_info["active_bone"])
				var prop_name = _state_info["active_bone"].get_concatenated_subnames()
				var bone_idx = skel.find_bone(prop_name)

				var inverse_rest = skel.get_bone_rest(bone_idx).affine_inverse()

				var parent = skel.get_bone_parent(bone_idx)
				var inverse_parent_global = Transform.IDENTITY
				if parent != -1:
					inverse_parent_global = skel.get_bone_global_pose(parent).affine_inverse()

				var global_pose = skel.get_bone_global_pose(bone_idx)
				global_pose.basis = global_pose.basis.rotated(camera.get_global_transform().basis.z, rotation_amount)

				var local_pose = inverse_rest * inverse_parent_global * global_pose

				skel.set_bone_pose(bone_idx, local_pose)

	return consumed


func _process(delta):
	update()


func _draw():
	if anim_player and _active_bone and _state == EditorState.ROTATING:
		var res = AnimationEditorUtils.skeleton_bone_from_path(
			anim_player.get_parent(),
			_active_bone
		)

		#var global_pos = res["skeleton"].global_transform * res["skeleton"].get_bone_global_pose(res["bone_idx"]).origin
		#var screen_pos = camera.unproject_position(global_pos)

		var global_pos = res["skeleton"].get_bone_global_pose(res["bone_idx"]).origin
		var screen_pos = camera.unproject_position(global_pos)

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
	visible = false
	default_font = Control.new().get_font("font")
	_rng.randomize()

