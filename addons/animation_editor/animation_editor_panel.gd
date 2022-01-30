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


class UIBone:
	var start: Vector2 = Vector2()
	var end: Vector2 = Vector2()
	var name = ""
	var path = null

	func _init(new_bone_start, new_bone_end, new_name, new_path):
		self.start = new_bone_start
		self.end = new_bone_end
		self.name = new_name
		self.path = new_path


func set_anim_player(new_anim_player):
	anim_player = new_anim_player
	redraw()


func redraw():
	if not anim_player:
		print("ERROR: asked to redraw when there's no anim player")
		return

	clear_labels()

	var bones_under_root_button = Button.new()
	bones_under_root_button.text = "Add Bones Under Root"
	bones_under_root_button.connect("pressed", self, "add_bones_under_root")
	$VBoxContainer.add_child(bones_under_root_button)
	$VBoxContainer.add_child(HSeparator.new())


# Recurse through all the children of the root node of the animation player, and
# add transform tracks for all the bones in all the armatures that are found
func add_bones_under_root():
	if not anim_player:
		print("No anim player selected")
		return

	var current_animation = anim_player.assigned_animation
	var anim: Animation = anim_player.get_animation(current_animation)
	if not anim:
		print("No animation on anim player")
		return

	var anim_track_path_set = {}
	for track_idx in range(anim.get_track_count()):
		var track_path = str(anim.track_get_path(track_idx))
		anim_track_path_set[track_path] = 1

	var root = anim_player.get_node(anim_player.root_node)
	var skeletons = skeletons_under_node(root)
	for skeleton in skeletons:
		var skeleton_path = root.get_path_to(skeleton)
		for bone_idx in skeleton.get_bone_count():
			var track_path = str(skeleton_path) + ":" + skeleton.get_bone_name(bone_idx)
			if anim_track_path_set.has(track_path):
				print(track_path, " already in player")
			else:
				var track_idx = anim.add_track(Animation.TYPE_TRANSFORM)
				anim.track_set_path(track_idx, track_path)

	redraw()


func skeletons_under_node(node):
	if node is Skeleton:
		return [node]

	var skeletons = []
	for child in node.get_children():
		skeletons.append_array(skeletons_under_node(child))

	return skeletons


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
		anim_player.get_node(anim_player.root_node),
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
								anim_player.get_node(anim_player.root_node),
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

			elif event is InputEventMouseButton and event.pressed:
				match event.button_index:
					BUTTON_LEFT:
						var ui_bone = _nearest_ui_bone(event.position, 20.0)
						if ui_bone:
							_active_bone = ui_bone.path
							# Need to redraw since the active bone changed
							redraw()
							consumed = true
						else:
							_active_bone = null

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
							anim_player.get_node(anim_player.root_node),
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
					anim_player.get_node(anim_player.root_node),
					_active_bone
				)

				var bone_screen_pos = camera.unproject_position(
					res["skeleton"].global_transform * res["skeleton"].get_bone_global_pose(res["bone_idx"]).origin
				)
				var last_angle = _state_info["last_mouse_pos"] - bone_screen_pos
				var current_angle = event.position - bone_screen_pos
				_state_info["last_mouse_pos"] = event.position

				var rotation_amount = current_angle.angle_to(last_angle)
				if Input.is_key_pressed(KEY_SHIFT):
					rotation_amount *= 0.1

				var skel: Skeleton = anim_player.get_node(anim_player.root_node).get_node(_state_info["active_bone"])
				var prop_name = _state_info["active_bone"].get_concatenated_subnames()
				var bone_idx = skel.find_bone(prop_name)

				var inverse_rest = skel.get_bone_rest(bone_idx).affine_inverse()

				var parent = skel.get_bone_parent(bone_idx)
				var inverse_parent_global = Transform.IDENTITY
				if parent != -1:
					inverse_parent_global = skel.get_bone_global_pose(parent).affine_inverse()

				var global_pose = res["skeleton"].global_transform * skel.get_bone_global_pose(bone_idx)
				global_pose.basis = global_pose.basis.rotated(camera.get_global_transform().basis.z, rotation_amount)

				var local_pose = inverse_rest * inverse_parent_global * res["skeleton"].global_transform.inverse() * global_pose

				skel.set_bone_pose(bone_idx, local_pose)

	return consumed


func _process(delta):
	update()


func _ui_bones():
	var ui_bones = []
	if anim_player:
		var current_animation = anim_player.assigned_animation
		var anim = anim_player.get_animation(current_animation)
		if anim:
			for track_idx in range(anim.get_track_count()):
				var path_to_bone = anim.track_get_path(track_idx)
				var skel = anim_player.get_node(anim_player.root_node).get_node(path_to_bone)
				var bone_name = path_to_bone.get_concatenated_subnames()
				if skel is Skeleton:
					var bone_idx = skel.find_bone(bone_name)
					if skel.get_bone_parent(bone_idx) != -1:
						var bone_xform = skel.global_transform * skel.get_bone_global_pose(bone_idx)
						var bone_end = bone_xform.origin + bone_xform.basis.y * 0.25

						var bone_start_screen_pos = camera.unproject_position(bone_xform.origin)
						var bone_end_screen_pos = camera.unproject_position(bone_end)

						ui_bones.append(
							UIBone.new(
								bone_start_screen_pos,
								bone_end_screen_pos,
								bone_name,
								path_to_bone
							)
						)

	return ui_bones


func _nearest_ui_bone(point: Vector2, threshold: float):
	var nearest_bone = null
	var nearest_bone_distance = threshold
	for bone in _ui_bones():
		var closest_point = Geometry.get_closest_point_to_segment_2d(point, bone.start, bone.end)
		var distance = (closest_point - point).length()
		if distance <= nearest_bone_distance:
			nearest_bone = bone
			nearest_bone_distance = distance
	return nearest_bone


func _draw():
	for bone in _ui_bones():
		var width = 3.0
		var color = Color.white
		if bone.path == _active_bone:
			color = Color.yellow
		draw_line(bone.start, bone.end, color, width, true)
		draw_string(get_default_font(), (bone.start+bone.end)/2, bone.name)

	if anim_player and _active_bone and _state == EditorState.ROTATING:
		var res = AnimationEditorUtils.skeleton_bone_from_path(
			anim_player.get_node(anim_player.root_node),
			_active_bone
		)

		var global_pos = res["skeleton"].global_transform * res["skeleton"].get_bone_global_pose(res["bone_idx"]).origin
		var screen_pos = camera.unproject_position(global_pos)

		draw_line(_state_info["last_mouse_pos"], screen_pos, Color.red)
		draw_string(get_default_font(), _state_info["last_mouse_pos"], str(_state_info["last_mouse_pos"]))


func add_label(text):
	var track_label = Label.new()
	track_label.text = str(text)
	$VBoxContainer.add_child(track_label)


func clear_labels():
	for node in $VBoxContainer.get_children():
		node.queue_free()


func get_default_font():
	if not default_font:
		default_font = Control.new().get_font("font")
	return default_font

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	default_font = Control.new().get_font("font")
	_rng.randomize()

