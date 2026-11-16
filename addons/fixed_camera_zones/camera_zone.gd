class_name CameraZone
extends Area3D
## A patch of floor that belongs to one fixed camera.
##
## Give it a CollisionShape3D (a box is usual) and pick its camera. When the
## CameraDirector's target walks in, that camera takes over. Let neighboring
## zones overlap by half a meter or so: inside the overlap the camera you
## already have stays put, so the view doesn't flicker when you stop in a doorway.

const GROUP := "camera_zones"

## The camera that shows this zone.
@export var camera: Camera3D
## Where zones overlap, the higher priority wins. On a tie the current camera stays.
@export var camera_priority := 0


func _enter_tree() -> void:
	add_to_group(GROUP)
	monitoring = true
