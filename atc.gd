extends Node

var concorde = preload("res://hikouki.tscn")
var cessna = preload("res://skyhawk.tscn")
var warthog = preload("res://warthog.tscn")
var warning_line = preload("res://proximity_warn.tscn")
var expiry_label = preload("res://expiry_label.tscn")
var game_over = load("res://game_over.tscn")

var last_warn_id
var last_miss_id
var last_collision_id

@export var init_spawn_interval = 6.3
@export var min_spawn_interval = 1.0
@export var spawnrate_delta = 0.3

var spawn_ceiling := 200.0
var ceiling_delta := 40.0

func spawn_plane(pos):
	var plane_scene: PackedScene
	if pos.y < 133:
		plane_scene = warthog
	elif pos.y < 266:
		plane_scene = concorde
	else:
		plane_scene = cessna
	var new_plane = plane_scene.instantiate()
	new_plane.position = pos
	new_plane.going_right = pos.x < 1
	new_plane.cleared_from_airspace.connect(_on_cleared_plane)
	new_plane.warn_controller.connect(_on_warn_controller)
	new_plane.near_miss.connect(_on_near_miss)
	new_plane.collision.connect(_on_plane_collision)
	add_child(new_plane)

# can also deduct if amount < 0
func add_score(amount: int):
	Globals.score += amount
	Globals.score = max(Globals.score, 0)
	$ScoreNum.text = "%d" % Globals.score


# Called when the node enters the scene tree for the first time.
func _ready():
	var position = get_random_border_pos()
	spawn_plane(position)
	$Spawner.wait_time = init_spawn_interval
	$Spawner.start()
	$Warner.wait_time = $Spawner.wait_time * 0.75
	$Warner.start()
	new_spawn_pos()
	add_score(0)

func is_dangerous_spawnarea():
	var overlap = $Spawnarea.get_overlapping_areas()
	for n in overlap:
		if n.is_in_group("spawnguard"):
			return true
	return false

func get_random_border_pos():
	var y = randf_range(spawn_ceiling, 400)
	var x = [0.0, 533.0][randi() % 2]
	return Vector2(x, y)

func new_spawn_pos():
	# Give up on safe spawns after some tries
	for i in range(8):
		$Spawnarea.position = get_random_border_pos()
		if is_dangerous_spawnarea():
			continue
		return

func _input(event):
	if event is InputEventMouseButton and !event.pressed:
		if is_instance_valid(Globals.dragged_plane):
			Globals.dragged_plane.stop_drag()
		else:
			# print_debug("no dragged plane set, fishy")
			get_tree().call_group("planes", "stop_drag")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if !$Warner.is_stopped() and is_dangerous_spawnarea():
		print_debug("calling failsafe new spawnarea")
		new_spawn_pos()

func _on_spawner_timeout():
	spawn_plane($Spawnarea.position)
	$Warning.visible = false
	$Warner.start()
	new_spawn_pos()

func _on_near_miss(pos):
	Audio.play("res://sound/NEAR_MISS2_ALTERNATIVE.wav")
	var miss_id = str(pos)
	if miss_id == last_miss_id:
		# luckily this seems to be good enough
		# print_debug("miss already registered, not registering twice")
		return
	last_miss_id = miss_id
	var l = expiry_label.instantiate()
	l.position = pos
	add_child(l)
	add_score(-2)

func _on_warn_controller(l, r):
	var warn_id = l.get_instance_id() ^ r.get_instance_id()
	if warn_id == last_warn_id:
		# print_debug("Warning already registered, not doing twice")
		return
	Audio.play("res://sound/HEADS_UP.wav")
	last_warn_id = warn_id
	var w = warning_line.instantiate()
	w.left = l
	w.right = r
	add_child(w)

func _on_warner_timeout():
	$Warning.visible = true
	$Spawnarea/AudioStreamPlayer2D.play()
	$Warning.flip_h = $Spawnarea.position.x > 1
	$Warning.position = Vector2(clamp($Spawnarea.position.x, 16, 533-16), \
		clamp($Spawnarea.position.y, 0, 400-16))

func _on_cleared_plane():
	add_score(5)

func _on_plane_collision(l, r):
	$Freeze/Explosion.position = l.position.lerp(r.position, 0.5)
	$Freeze/Explosion.visible = true
	$Freeze/Explosion.play()
	Audio.play_crash()
	Audio.clear_effects()
	get_tree().paused = true


func _on_freeze_timeout():
	get_tree().paused = false
	get_tree().change_scene_to_packed(game_over)


func _on_spawn_increaser_timeout():
	# Also raise ceiling
	spawn_ceiling = clamp(spawn_ceiling - ceiling_delta, 16, 400)
	$Spawner.wait_time = max(min_spawn_interval, $Spawner.wait_time - spawnrate_delta)
	$Warner.wait_time = $Spawner.wait_time * 0.75
