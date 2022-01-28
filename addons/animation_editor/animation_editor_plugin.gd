tool
extends EditorPlugin

var enabled = false
var visible = false
var camera = null
var active_animation_player = null

var _editor_menu_button_scene = preload("animation_editor_menu.tscn")
var _editor_panel_scene = preload("animation_editor_panel.tscn")

var _editor_menu_button = null
var _editor_panel = null

func handles(object):
	print("handles(", object, ")")
	return object is AnimationPlayer


func edit(object):
	active_animation_player = object


func make_visible(show):
	visible = show
	if visible:
		# Add plugin UI to the editor
		_editor_menu_button = _editor_menu_button_scene.instance()
		_editor_menu_button.text = "Animation Editor"
		_editor_menu_button.pressed = enabled
		_editor_menu_button.connect("toggled", self, "_set_enabled")
		add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _editor_menu_button)

	else:
		_remove_controls()

	update_overlays()


func _remove_controls():
	_remove_overlay()
	_remove_editor_menu_button()

# Remove any overlays this plugin has added.
# Use `update_overlays()` to force a refresh.
func _remove_overlay():
	if _editor_panel:
		print("freeing info panel")
		# TODO: this doesn't seem to be working...
		_editor_panel.queue_free()
		_editor_panel = null
		print("editor panel is now ", _editor_panel)


func _remove_editor_menu_button():
	if _editor_menu_button != null:
		# Remove plugin UI from the editor
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _editor_menu_button)

		_editor_menu_button.queue_free()
		_editor_menu_button = null

		_remove_overlay()


func forward_spatial_draw_over_viewport(overlay: Control):
	if _editor_panel == null and enabled and visible:
		_editor_panel = _editor_panel_scene.instance()
		_editor_panel.plugin = self
		overlay.add_child(_editor_panel)
		print("editor panel is now ", _editor_panel)


func forward_spatial_gui_input(camera, event):
	self.camera = camera
	if _editor_panel:
		return _editor_panel.process_input(event)
	return false

func _set_enabled(val):
	enabled = val

	# Visibility should match enabled when it changes, but does get updated
	# to match the most recent "make_visible" call
	visible = val
	if not enabled:
		_remove_overlay()
	update_overlays()


func _enter_tree():
	add_custom_type("MyButton", "Button", preload("my_button.gd"), preload("animation_editor_node_icon.bmp"))


func _exit_tree():
	remove_custom_type("MyButton")
	_remove_controls()
