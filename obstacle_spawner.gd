extends Node2D

@export var obstacle_scene: PackedScene
@export var player_path: NodePath

# World/tunnel settings
@export var spawn_distance: float = 800.0
@export var start_offset_x: float = 220.0
@export var min_section_dx: int = 140
@export var max_section_dx: int = 220

@export var min_gap: float = 140.0
@export var max_gap: float = 380.0
@export var start_gap: float = 260.0
@export var tunnel_center_y: float = 256.0

# If auto-detect fails, set this in the Inspector (> 0) to force a height
@export var spike_visual_height_override: float = 0.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var next_spawn_x: float = 0.0
var player_node: Node2D = null
var current_gap: float = 0.0
var spike_h: float = 0.0

func _ready() -> void:
	rng.randomize()
	

	if player_path == null or String(player_path) == "":
		push_error("ObstacleSpawner: player_path not assigned!")
		set_process(false)
		return

	player_node = get_node(player_path) as Node2D
	if player_node == null:
		push_error("ObstacleSpawner: could not resolve player node from player_path!")
		set_process(false)
		return

	current_gap = start_gap

	# Detect spike height automatically (Sprite2D or CollisionShape2D). Fallback to 32.
	spike_h = spike_visual_height_override
	if spike_h <= 0.0:
		spike_h = _detect_spike_height()
	if spike_h <= 0.0:
		spike_h = 32.0
		push_warning("ObstacleSpawner: could not detect spike height automatically; using 32.")

	# Start spawning a bit in front of the player and prefill the view
	next_spawn_x = player_node.global_position.x + start_offset_x
	while next_spawn_x < player_node.global_position.x + spawn_distance:
		_spawn_section()

func _process(delta: float) -> void:
	if player_node == null:
		return

	# Always keep the tunnel generated ahead of the player
	while next_spawn_x < player_node.global_position.x + spawn_distance:
		_spawn_section()

	# Cleanup: remove spikes far behind the player
	for c in get_children():
		if c is Node2D:
			var n2d: Node2D = c as Node2D
			if n2d.global_position.x < player_node.global_position.x - 600.0 and n2d.is_in_group("obstacle"):
				n2d.queue_free()

func _spawn_section() -> void:
	# Smoothly vary the tunnel thickness
	current_gap += rng.randi_range(-30, 30)
	current_gap = clamp(current_gap, min_gap, max_gap)

	# Tunnel boundaries (lines where the inner walls would be)
	var top_y: float = tunnel_center_y - current_gap * 0.5
	var bottom_y: float = tunnel_center_y + current_gap * 0.5

	# --- Top spike: tip should touch the top boundary, so center sits spike_h/2 above it
	var top_obstacle: Node2D = obstacle_scene.instantiate() as Node2D
	top_obstacle.position = Vector2(next_spawn_x, top_y - spike_h * 0.5)
	top_obstacle.rotation = PI                     # 180°, points downward
	add_child(top_obstacle)
	top_obstacle.add_to_group("obstacle")

	# --- Bottom spike: tip should touch bottom boundary, so center sits spike_h/2 below it
	var bottom_obstacle: Node2D = obstacle_scene.instantiate() as Node2D
	bottom_obstacle.position = Vector2(next_spawn_x, bottom_y + spike_h * 0.5)
	bottom_obstacle.rotation = 0.0                 # points upward
	add_child(bottom_obstacle)
	bottom_obstacle.add_to_group("obstacle")

	# Advance the x position for the next section
	next_spawn_x += rng.randi_range(min_section_dx, max_section_dx)
	print("Spawned spikes at X =", next_spawn_x, " gap =", current_gap)


# --- Helpers -----------------------------------------------------------------

func _detect_spike_height() -> float:
	if obstacle_scene == null:
		return 0.0
	var inst: Node = obstacle_scene.instantiate()
	
	
	# Try to find any Sprite2D in the spike scene tree
	var spr := _find_first_sprite2d(inst)
	if spr != null and spr.texture != null:
		var tex_h: float = float(spr.texture.get_height())
		var scaled_h: float = tex_h * abs(spr.scale.y)
		inst.queue_free()
		return scaled_h

	# If no Sprite2D/texture, try a CollisionShape2D's shape size
	var cshape := _find_first_collisionshape2d(inst)
	if cshape != null and cshape.shape != null:
		var sh = cshape.shape
		var h: float = 0.0
		if sh is RectangleShape2D:
			h = (sh as RectangleShape2D).size.y * abs(cshape.scale.y)
		elif sh is CapsuleShape2D:
			h = (sh as CapsuleShape2D).height + (sh as CapsuleShape2D).radius * 2.0
		elif sh is CircleShape2D:
			h = (sh as CircleShape2D).radius * 2.0
		inst.queue_free()
		return h
	print("detected spike_h =", spike_h)
	
	inst.queue_free()
	return 0.0

func _find_first_sprite2d(n: Node) -> Sprite2D:
	if n is Sprite2D:
		return n as Sprite2D
	for child in n.get_children():
		var found := _find_first_sprite2d(child)
		if found:
			return found
	return null

func _find_first_collisionshape2d(n: Node) -> CollisionShape2D:
	if n is CollisionShape2D:
		return n as CollisionShape2D
	for child in n.get_children():
		var found := _find_first_collisionshape2d(child)
		if found:
			return found
	return null
