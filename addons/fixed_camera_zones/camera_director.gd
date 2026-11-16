class_name CameraDirector
extends Node
## Cuts between fixed cameras as one body walks through CameraZones.
##
## Add one CameraDirector anywhere in the scene, set `target` to your player,
## and add CameraZone areas. It finds every zone in the tree, including ones
## added later, and makes the right camera current.

## Fired on every change of camera. `from` is null for the first one.
signal camera_cut(from: Camera3D, to: Camera3D)

## The body whose position decides the camera (usually the player).
@export var target: Node3D
## Shown until the target has entered a zone. Optional.
@export var start_camera: Camera3D

## The camera showing now.
var current: Camera3D
## How many cuts so far (the first camera doesn't count).
var cuts := 0

var _inside: Array = []


func _ready() -> void:
	for z in get_tree().get_nodes_in_group(CameraZone.GROUP):
		_watch(z)
	get_tree().node_added.connect(_on_node_added)
	if start_camera:
		cut_to(start_camera)


## Cut straight to a camera, for a scripted shot. The zones take over again
## the next time the target crosses into one.
func cut_to(cam: Camera3D) -> void:
	if cam == null or cam == current:
		return
	var from := current
	current = cam
	cam.make_current()
	if from != null:
		cuts += 1
	camera_cut.emit(from, cam)


func _on_node_added(n: Node) -> void:
	if n is CameraZone:
		_watch(n)


func _watch(z: CameraZone) -> void:
	if z.body_entered.is_connected(_on_enter):
		return
	z.body_entered.connect(_on_enter.bind(z))
	z.body_exited.connect(_on_exit.bind(z))
	z.tree_exiting.connect(_on_gone.bind(z))


func _on_enter(body: Node3D, z: CameraZone) -> void:
	if body != target:
		return
	_inside.erase(z)
	_inside.append(z)
	_pick()


func _on_exit(body: Node3D, z: CameraZone) -> void:
	if body != target:
		return
	_inside.erase(z)
	_pick()


func _on_gone(z: CameraZone) -> void:
	_inside.erase(z)


func _pick() -> void:
	var top := -2147483648
	for z in _inside:
		if z.camera and z.camera_priority > top:
			top = z.camera_priority
	var best: CameraZone = null
	for z in _inside:
		if z.camera == null or z.camera_priority != top:
			continue
		if z.camera == current:
			return
		best = z   # the most recently entered of the top priority
	if best:
		cut_to(best.camera)
