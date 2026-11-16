class_name HeldDirection
extends RefCounted
## Camera-relative movement that survives a camera cut.
##
## With fixed cameras, "up on the stick" points somewhere new after every cut,
## so a player who walks through a doorway gets turned around and walks
## straight back out. HeldDirection keeps reading the stick in the frame of the
## camera that was showing when you started pushing. It lets go when you let go
## of the stick, or when you swing the stick to a clearly new direction.
##
##   var held := HeldDirection.new()
##   func _physics_process(delta):
##       var stick := Input.get_vector("left", "right", "up", "down")
##       var dir := held.get_direction(stick, get_viewport().get_camera_3d())
##       velocity.x = dir.x * speed
##       velocity.z = dir.z * speed

## Stick travel below this counts as let go.
var deadzone := 0.2
## Swing the stick further than this (degrees) from where you started and the
## current camera is read again.
var regrab_angle := 50.0

var _basis := Basis()
var _held := false
var _start := Vector2.ZERO


## Flat world direction for this stick, scaled by how far it's pushed (0 to 1).
func get_direction(stick: Vector2, camera: Camera3D) -> Vector3:
	if stick.length() < deadzone or camera == null:
		_held = false
		return Vector3.ZERO
	if not _held or rad_to_deg(absf(stick.angle_to(_start))) > regrab_angle:
		_basis = camera.global_transform.basis
		_start = stick
		_held = true
	var right := Vector3(_basis.x.x, 0.0, _basis.x.z)
	var back := Vector3(_basis.z.x, 0.0, _basis.z.z)
	if back.length() < 0.01:
		back = Vector3(-_basis.y.x, 0.0, -_basis.y.z)   # a camera looking straight down
	var d := right.normalized() * stick.x + back.normalized() * stick.y
	return d.normalized() * minf(stick.length(), 1.0)


## Forget the held frame, e.g. after a cutscene.
func release() -> void:
	_held = false
