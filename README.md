# Fixed Camera Zones (Godot 4)

Fixed cameras have two classic bugs. The view flickers back and forth when the player stops in a doorway. And after a cut, "up" on the stick points somewhere new, so the player walks straight back out of the room they just entered. These three scripts cut between fixed cameras as the player walks and fix both. Built with survival horror in mind; works for any room-camera, security-cam or cutscene setup.

Tested on Godot 4.6. GDScript, no autoloads, no plugin to enable. MIT.

- **CameraZone** (an Area3D). Give it a box shape and a Camera3D. When the player walks in, that camera takes over.
- **CameraDirector**. Add one, set `target` to the player. It finds every zone and makes the right camera current. It fires `camera_cut(from, to)` on each cut, if you want a sound or a fade.
- **HeldDirection**. Camera-relative movement that survives a cut. It keeps the old camera's "up" until the player lets go of the stick or turns it somewhere new. It's a RefCounted, so there's no node to add or free, and it works without the other two, with whatever camera switching you already have.

## Use it

1. Copy `addons/fixed_camera_zones` into your project.
2. Add a CameraDirector node and set its Target to your player body.
3. For each camera angle: a Camera3D, plus a CameraZone with a CollisionShape3D covering the floor that camera should show. Set the zone's Camera.
4. Let neighboring zones overlap by about half a meter. Inside an overlap the current camera stays, so there's no flicker in a doorway. Where you want one zone to win anyway, give it a higher `camera_priority`.
5. In your CharacterBody3D script:

```gdscript
var held := HeldDirection.new()

func _physics_process(delta):
    var stick := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var dir := held.get_direction(stick, get_viewport().get_camera_3d())
    velocity.x = dir.x * 3.0
    velocity.z = dir.z * 3.0   # velocity.y is left alone, so your gravity and jump still work
    move_and_slide()
```

The zones see bodies on their collision mask, so keep the player on a layer they check (layer 1 by default).

## The demo

Open `addons/fixed_camera_zones/demo/demo.tscn` and run it (F6): two rooms, a doorway, three cameras. Press Z to see the zones. Walk through the doorway, then press H to turn HeldDirection off and walk through again to feel the bug it fixes.

Command line: `-- --demo` walks a bot around, `-- --autotest` runs it for 40 seconds and prints the cuts.

## License

MIT, see `LICENSE.txt`. These three scripts are the whole camera system, not a trial.

If you also want the player to walk behind furniture that only exists in a painted background, that's the [Fixed Camera Horror Kit](https://cs5475.itch.io/fixed-camera-horror-kit) (paid, on itch.io): pre-rendered rooms, tank controls and a shambler.
