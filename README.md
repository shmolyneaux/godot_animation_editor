# Godot 3 Skeletal Animation Editor

A Godot 3 editor plugin for authoring 3D skeletal animations directly in the viewport. Select bones, rotate and translate them with intuitive mouse controls, and keyframes are automatically inserted into your AnimationPlayer. Built as a workaround while [waiting for Godot 4 skeletal animation editing](https://www.youtube.com/watch?v=_timNOvSm_U).

## Features

- **Visual bone selection** — click on bones rendered as lines in the 3D viewport to select them
- **Rotate bones** — press `R` then move the mouse to rotate around the camera axis; camera-relative rotation keeps things intuitive from any angle
- **Translate bones** — press `G` then move the mouse to translate along the camera-parallel plane
- **Precision mode** — hold `Shift` during rotate/grab for 10× finer control
- **Automatic keyframing** — accept a pose (click or `Enter`) and a transform key is inserted at the current animation time
- **Bulk track creation** — "Add Bones Under Root" button auto-generates transform tracks for every bone under the AnimationPlayer's root node

## Limitations

- Godot 3 only (3.x); not compatible with Godot 4
- Only supports skeletal (bone transform) tracks — no support for property, method, or blend shape tracks
- No undo/redo integration; press `Escape` to cancel the current operation, but previous keyframe edits cannot be undone through this plugin
- Rotation is always around the camera's Z axis; there is no axis-lock (e.g. X/Y/Z constrained rotation)
- No scaling support — only rotation and translation are implemented

## Getting Started

1. Copy the `addons/animation_editor` folder into your Godot 3 project's `addons/` directory.
2. In the Godot editor, go to **Project → Project Settings → Plugins** and enable **AnimationEditor**.
3. Select an `AnimationPlayer` node in the scene tree.
4. Check the **Animation Editor** toggle in the 3D viewport toolbar.
5. If the AnimationPlayer's `root_node` is a parent of a `Skeleton`, press **Add Bones Under Root** to auto-create transform tracks for all bones.

## Usage

1. Click on a bone in the viewport to select it (highlighted in yellow).
2. Press `R` to rotate or `G` to translate.
3. Move the mouse to adjust the bone. Hold `Shift` for fine control.
4. Press `Enter` or left-click to accept the pose — a keyframe is automatically inserted.
5. Press `Escape` to cancel and revert to the original pose.

## Building and Testing

This is a pure GDScript editor plugin — no compilation is required. To try it out:

1. Open the project in Godot 3.x (`project.godot`).
2. Enable the plugin under **Project → Project Settings → Plugins**.
3. Open a scene with a `Skeleton` and an `AnimationPlayer` to test the editing workflow.

There are no automated tests; manual testing in the editor is the primary verification method.

## History

Development started on 2022-01-23, and largely stopped on 2022-01-30:

- **2022-01-23** — Initial commit with the editor plugin scaffold and project setup
- **2022-01-26** — Camera-relative bone rotations implemented; first interactive bone manipulation in the viewport
- **2022-01-27** — Basic editing workflow functional (bone display, selection, rotation with mouse)
- **2022-01-29** — Major feature day: refactored plugin architecture, added skeleton transform support for rotations, bone drawing/picking with click-to-select, bulk track population via "Add Bones Under Root", and full translation (grab) support
- **2022-01-30** — Fixed root bone rendering, updated README with usage instructions

## License

[MIT](LICENSE) — Copyright © 2022 Stephen Molyneaux
