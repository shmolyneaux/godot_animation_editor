tool
extends EditorPlugin

# User has checked the box indicating that they'd like to use the animation editor
# (whether or not they currently can).
var use_anim_editor_checked = false

var _editor_menu_button_scene = preload("animation_editor_menu.tscn")
var _editor_panel_scene = preload("animation_editor_panel.tscn")

# The UI element added to the menu bar when AnimationPlayers are selected.
# Toggling this button enables animation editing.
var _editor_menu_button = null

# The UI element that's drawn over the viewport when editing animations.
# The editor panel always exists after _ready, and its visiblity is toggled as
# needed. Most of the state and interactions of this plugin are implemented in
# the panel to reduce the frequency of issues when Godot reloads the plugin.
var _editor_panel = null

func handles(object):
	print("handles(", object, ")")
	if _editor_panel.anim_player:
		# We've previously selected an animation player, and these are presumably
		# UI elements of the track editor for that player
		if object.get_class() == "AnimationTrackKeyEdit":
			return true
		if object.get_class() == "AnimationMultiTrackKeyEdit":
			return true

	# User initially selects an AnimationPlayer Node
	return object is AnimationPlayer


func edit(object):
	if object is AnimationPlayer:
		print("editing anim player")
		_editor_panel.anim_player = object
	else:
		print("WEIRD: asked to edit ", object)


func make_visible(show):
	_editor_panel.visible = show
	if show:
		_add_editor_menu_button()
	else:
		_remove_editor_menu_button()

	update_overlays()


func _add_editor_menu_button():
	if _editor_menu_button != null:
		print("Internal error: asked to add editor menu button multiple times")
		return

	# Add plugin UI to the editor
	_editor_menu_button = _editor_menu_button_scene.instance()
	_editor_menu_button.text = "Animation Editor"
	_editor_menu_button.pressed = use_anim_editor_checked
	_editor_menu_button.connect("toggled", self, "_set_use_anim_editor_checked")
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _editor_menu_button)


func _remove_editor_menu_button():
	if _editor_menu_button != null:
		# Remove plugin UI from the editor
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _editor_menu_button)

		_editor_menu_button.queue_free()
		_editor_menu_button = null


func forward_spatial_draw_over_viewport(overlay: Control):
	# Executed once the first time this needs to draw over a given viewport
	var old_parent = _editor_panel.get_parent()
	if old_parent != overlay:
		print("Changing animation editor overlay from ", old_parent, " to ", overlay)
		if old_parent != null:
			old_parent.remove_child(_editor_panel)
		overlay.add_child(_editor_panel)

	update_overlays() # TODO: is this needed?


func forward_spatial_gui_input(camera, event):
	_editor_panel.camera = camera
	var res = _editor_panel.process_input(event)
	update_overlays() # TODO: is this needed?
	return res


# The user has checked/unchecked the box indicating that they'd like to use the
# animation editor.
func _set_use_anim_editor_checked(val):
	use_anim_editor_checked = val

	# Visibility should match use_anim_editor_checked when it changes. It can
	# have a different value when use_anim_editor_checked is true, but the user
	# is selecting something unrelated to animation.
	_editor_panel.visible = val
	update_overlays() # TODO: is this needed?


func _ready():
	_editor_panel = _editor_panel_scene.instance()


func _enter_tree():
	pass


func _exit_tree():
	_editor_panel.queue_free()
	_remove_editor_menu_button()
