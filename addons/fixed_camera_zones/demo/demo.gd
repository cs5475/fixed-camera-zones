extends Node
## Demo for Fixed Camera Zones: two rooms, a doorway, three fixed cameras.
## WASD, arrows or a stick to walk. H turns the held direction off so you can
## feel what it fixes. Z shows the zones. --demo walks a bot around,
## --autotest checks the cuts, --show-zones starts with the zones visible.

const W := 320
const H := 240

var view: SubViewport
var director: CameraDirector
var player: CharacterBody3D
var cams: Array = []
var held := HeldDirection.new()
var hold_on := true
var hud: Label
var demo := false
var autotest := false
var bot_i := 0
var game_t := 0.0
var seen := {}
var mats := {}
var zone_marks: Array = []

const BOT_PATH := [Vector3(-3.0, 0, 0.2), Vector3(2.2, 0, 0.0), Vector3(4.6, 0, 3.0), Vector3(4.6, 0, -3.2),
	Vector3(2.0, 0, -0.4), Vector3(-3.5, 0, -0.2), Vector3(-5.2, 0, 3.4)]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	autotest = "--autotest" in args
	demo = autotest or "--demo" in args
	_inputs()
	var box := SubViewportContainer.new()
	box.stretch = true
	box.stretch_shrink = 3
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(box)
	view = SubViewport.new()
	view.size = Vector2i(W, H)
	view.msaa_3d = Viewport.MSAA_DISABLED
	box.add_child(view)
	_room()
	_cameras()
	player = _person()
	player.position = Vector3(-5.2, 0, 3.4)
	view.add_child(player)
	director = CameraDirector.new()
	director.target = player
	director.start_camera = cams[0]
	director.camera_cut.connect(func(_from, to): seen[cams.find(to)] = true)
	view.add_child(director)
	_zones()
	_hud()


func _inputs() -> void:
	var keys := {"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN], "hold": [KEY_H], "zones": [KEY_Z]}
	for a in keys:
		if not InputMap.has_action(a):
			InputMap.add_action(a, 0.2)
		for k in keys[a]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(a, e)
	var axes := {"left": [JOY_AXIS_LEFT_X, -1.0], "right": [JOY_AXIS_LEFT_X, 1.0], "up": [JOY_AXIS_LEFT_Y, -1.0], "down": [JOY_AXIS_LEFT_Y, 1.0]}
	for a in axes:
		var j := InputEventJoypadMotion.new()
		j.axis = axes[a][0]
		j.axis_value = axes[a][1]
		InputMap.action_add_event(a, j)


func _mat(c: Color) -> StandardMaterial3D:
	var key := c.to_html()
	if not mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.9
		mats[key] = m
	return mats[key]


func _block(size: Vector3, pos: Vector3, c: Color, solid := true) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(c)
	if solid:
		var body := StaticBody3D.new()
		body.position = pos
		var col := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		col.shape = sh
		body.add_child(col)
		body.add_child(mi)
		view.add_child(body)
	else:
		mi.position = pos
		view.add_child(mi)


func _room() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.02, 0.02, 0.03)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.16, 0.15, 0.2)
	view.add_child(env)
	var floor_c := Color(0.32, 0.24, 0.18)
	var wall_c := Color(0.42, 0.4, 0.33)
	_block(Vector3(14, 0.2, 10), Vector3(0, -0.1, 0), floor_c)
	_block(Vector3(14, 3, 0.3), Vector3(0, 1.5, -5.15), wall_c)
	_block(Vector3(14, 3, 0.3), Vector3(0, 1.5, 5.15), wall_c)
	_block(Vector3(0.3, 3, 10), Vector3(-7.15, 1.5, 0), wall_c)
	_block(Vector3(0.3, 3, 10), Vector3(7.15, 1.5, 0), wall_c)
	# the partition with a doorway in the middle
	_block(Vector3(0.3, 3, 4.0), Vector3(0, 1.5, -3.0), wall_c)
	_block(Vector3(0.3, 3, 4.0), Vector3(0, 1.5, 3.0), wall_c)
	_block(Vector3(0.3, 0.8, 2.0), Vector3(0, 2.6, 0), wall_c)
	# west room: a table and a shelf
	_block(Vector3(2.2, 0.08, 1.2), Vector3(-3.2, 0.8, -2.6), Color(0.36, 0.2, 0.12))
	for p in [Vector3(-4.2, 0.4, -3.1), Vector3(-2.2, 0.4, -3.1), Vector3(-4.2, 0.4, -2.1), Vector3(-2.2, 0.4, -2.1)]:
		_block(Vector3(0.1, 0.8, 0.1), p, Color(0.3, 0.17, 0.1))
	_block(Vector3(0.5, 2.2, 2.4), Vector3(-6.7, 1.1, 1.0), Color(0.28, 0.18, 0.12))
	# east room: a pillar and crates
	_block(Vector3(0.7, 3, 0.7), Vector3(3.6, 1.5, 0.2), Color(0.5, 0.48, 0.42))
	_block(Vector3(0.9, 0.9, 0.9), Vector3(6.1, 0.45, -4.2), Color(0.45, 0.33, 0.2))
	_block(Vector3(0.9, 0.9, 0.9), Vector3(6.1, 0.45, 4.1), Color(0.45, 0.33, 0.2))
	_block(Vector3(0.7, 0.7, 0.7), Vector3(5.2, 0.35, 4.3), Color(0.4, 0.3, 0.18))
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(-3.0, 2.2, -2.2)
	lamp.light_color = Color(1.0, 0.72, 0.42)
	lamp.light_energy = 2.0
	lamp.omni_range = 8.0
	lamp.shadow_enabled = true
	view.add_child(lamp)
	var lamp2 := OmniLight3D.new()
	lamp2.position = Vector3(4.5, 2.4, 0.0)
	lamp2.light_color = Color(0.6, 0.75, 1.0)
	lamp2.light_energy = 1.4
	lamp2.omni_range = 7.0
	lamp2.shadow_enabled = true
	view.add_child(lamp2)


func _cameras() -> void:
	var shots := [
		[Vector3(-6.5, 2.9, 4.6), Vector3(-2.2, 0.5, -1.8), 58.0],   # west room, from the southwest corner
		[Vector3(6.6, 3.0, 4.7), Vector3(2.0, 0.5, -0.4), 60.0],     # east room, south half
		[Vector3(6.6, 3.0, -4.7), Vector3(2.0, 0.5, 0.6), 60.0],     # east room, north half
	]
	for s in shots:
		var c := Camera3D.new()
		c.fov = s[2]
		view.add_child(c)
		c.global_position = s[0]
		c.look_at(s[1])
		cams.append(c)


func _zones() -> void:
	# neighbours overlap by 0.6 m so the camera holds while you stand in a doorway
	var rects := [[Vector3(-3.35, 1.5, 0), Vector3(7.3, 3, 10), 0], [Vector3(3.35, 1.5, 2.35), Vector3(7.3, 3, 5.3), 1],
		[Vector3(3.35, 1.5, -2.35), Vector3(7.3, 3, 5.3), 2]]
	for r in rects:
		var z := CameraZone.new()
		z.position = r[0]
		z.camera = cams[r[2]]
		var col := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = r[1]
		col.shape = sh
		z.add_child(col)
		view.add_child(z)
		# a see-through patch on the floor so you can see where each camera takes over
		var mark := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(r[1].x, r[1].z)
		mark.mesh = pm
		var m := StandardMaterial3D.new()
		m.albedo_color = [Color(1.0, 0.65, 0.2, 0.22), Color(0.2, 0.85, 0.8, 0.22), Color(0.7, 0.4, 1.0, 0.22)][r[2]]
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mark.material_override = m
		mark.position = Vector3(r[0].x, 0.02 + 0.005 * r[2], r[0].z)
		mark.visible = "--show-zones" in OS.get_cmdline_user_args()
		view.add_child(mark)
		zone_marks.append(mark)


func _person() -> CharacterBody3D:
	var p := CharacterBody3D.new()
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.75
	col.shape = cap
	col.position = Vector3(0, 0.875, 0)
	p.add_child(col)
	var rig := Node3D.new()
	rig.name = "rig"
	p.add_child(rig)
	for part in [[Vector3(0.5, 0.65, 0.3), Vector3(0, 1.2, 0), Color(0.18, 0.3, 0.5)], [Vector3(0.28, 0.3, 0.28), Vector3(0, 1.7, 0), Color(0.85, 0.66, 0.52)],
			[Vector3(0.18, 0.85, 0.2), Vector3(-0.13, 0.43, 0), Color(0.15, 0.14, 0.13)], [Vector3(0.18, 0.85, 0.2), Vector3(0.13, 0.43, 0), Color(0.15, 0.14, 0.13)]]:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = part[0]
		mi.mesh = bm
		mi.position = part[1]
		mi.material_override = _mat(part[2])
		rig.add_child(mi)
	return p


func _hud() -> void:
	hud = Label.new()
	hud.position = Vector2(14, 10)
	hud.add_theme_font_size_override("font_size", 18)
	hud.add_theme_color_override("font_shadow_color", Color.BLACK)
	add_child(hud)
	var tip := Label.new()
	tip.text = "WASD / STICK TO WALK    H: HELD DIRECTION ON / OFF    Z: SHOW ZONES"
	tip.add_theme_font_size_override("font_size", 14)
	tip.add_theme_color_override("font_shadow_color", Color.BLACK)
	tip.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	tip.position = Vector2(14, 690)
	add_child(tip)


func _physics_process(delta: float) -> void:
	game_t += delta
	if Input.is_action_just_pressed("hold"):
		hold_on = not hold_on
		held.release()
	if Input.is_action_just_pressed("zones"):
		for mk in zone_marks:
			mk.visible = not mk.visible
	var dir := Vector3.ZERO
	if demo:
		var to: Vector3 = BOT_PATH[bot_i] - player.global_position
		to.y = 0.0
		if to.length() < 0.4:
			bot_i = (bot_i + 1) % BOT_PATH.size()
		dir = to.normalized()
	else:
		var stick := Input.get_vector("left", "right", "up", "down")
		if hold_on:
			dir = held.get_direction(stick, director.current)
		elif stick.length() > 0.2 and director.current:
			var b := director.current.global_transform.basis
			dir = (Vector3(b.x.x, 0, b.x.z).normalized() * stick.x + Vector3(b.z.x, 0, b.z.z).normalized() * stick.y)
	if dir.length() > 0.05:
		player.rotation.y = lerp_angle(player.rotation.y, atan2(-dir.x, -dir.z), 10.0 * delta)
	player.velocity = dir * 2.2
	player.move_and_slide()
	var rig: Node3D = player.get_node("rig")
	rig.position.y = absf(sin(game_t * 9.0)) * 0.05 * minf(dir.length(), 1.0)
	hud.text = "CAMERA %d    HELD DIRECTION %s" % [cams.find(director.current) + 1, "ON" if hold_on else "OFF"]
	if autotest and game_t > 40.0:
		print("AUTOTEST " + JSON.stringify({"time": snapped(game_t, 0.1), "cuts": director.cuts, "cams_seen": seen.keys(),
			"hold_ok": _hold_check(), "pos": [snapped(player.global_position.x, 0.1), snapped(player.global_position.z, 0.1)]}))
		get_tree().quit()


# HeldDirection: pushing up keeps the same world direction across a cut, and lets go when released.
func _hold_check() -> bool:
	var h := HeldDirection.new()
	var a := h.get_direction(Vector2(0, -1), cams[0])
	var b := h.get_direction(Vector2(0, -1), cams[2])
	h.get_direction(Vector2.ZERO, cams[2])
	var c := h.get_direction(Vector2(0, -1), cams[2])
	return a.is_equal_approx(b) and not c.is_equal_approx(a) and is_equal_approx(a.length(), 1.0)
