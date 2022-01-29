class_name AnimationEditorUtils


static func print_stuff():
	print("stuff")


static func skeleton_bone_from_path(from_node, prop_path):
	var bone_name = prop_path.get_concatenated_subnames()
	var skel: Skeleton = from_node.get_node(prop_path)
	var bone_idx = bone_idx_from_path(from_node, prop_path)

	return {"skeleton": skel, "bone_idx": bone_idx}


static func skeleton_from_path(from_node, node_path) -> Skeleton:
	var skel: Skeleton = from_node.get_node(node_path)
	return skel


static func bone_idx_from_path(from_node, prop_path):
	var bone_name = prop_path.get_concatenated_subnames()
	var skel = skeleton_from_path(from_node, prop_path)
	var bone_idx = skel.find_bone(bone_name)

	return bone_idx


static func bone_local_xform_from_path(from_node, prop_path):
	var skel = skeleton_from_path(from_node, prop_path)
	var bone_idx = bone_idx_from_path(from_node, prop_path)

	return skel.get_bone_pose(bone_idx)
