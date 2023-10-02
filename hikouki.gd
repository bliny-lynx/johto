extends Node2D

signal cleared_from_airspace
signal warn_controller(l: Node, r: Node)
signal near_miss(pos: Vector2)
signal collision(l: Node, r: Node)

@export var base_speed = 30
@export var speed_variance = 40
var flightspeed = 0
# also descend speed
@export var climbspeed = 20
@export var screen_bounds: Vector2 = Vector2(533, 400)

var target_flightlevel: float
var going_right: bool = true
var cleared: bool = false


@onready var fl_diff_line = $FLDiffLine
@onready var tgt_fl_line = $TargetFLLine


func mirror_hitbox():
	var vertices = []
	for vtx in $Hitbox/Shape.polygon:
		vertices.append(Vector2(-vtx.x, vtx.y))
	$Hitbox/Shape.polygon = PackedVector2Array(vertices)

# Called when the node enters the scene tree for the first time.
func _ready():
	flightspeed = base_speed + randf_range(1.0, speed_variance)
	target_flightlevel = position.y
	$Sprite2D.flip_h = !going_right
	if !going_right:
		mirror_hitbox()
	var spawnguard_pos = $Spawnguard.position
	var guard_x = -spawnguard_pos.x if !going_right else spawnguard_pos.x
	$Spawnguard.position = Vector2(guard_x, spawnguard_pos.y)
	$DirectionLine.rotation = 0.0 if going_right else PI
	if is_instance_valid(get_node_or_null("Vaportrail")):
		$Vaportrail.rotation = 0.0 if going_right else PI

func stop_drag():
	if Globals.dragged_plane == self:
		target_flightlevel = clamp(
			get_viewport().get_mouse_position().y, 0, screen_bounds.y)
	Globals.dragged_plane = null

func remove_offscreen(dt):
	if (position.x < -8 or position.x > screen_bounds.x + 8):
		if is_instance_valid(get_node_or_null("Vaportrail")):
			$Vaportrail.modulate.a -= dt * 0.5
			if $Vaportrail.modulate.a < 0.02:
				$Vaportrail.queue_free()
		if !cleared:
			cleared_from_airspace.emit()
			cleared = true
			$Nearmissbox.monitoring = false
			$Nearmissbox.monitorable = false
			$Hitbox.monitoring = false
			$Hitbox.monitorable = false
			$Warnbox.monitoring = false
			$Warnbox.monitorable = false
	if position.x < -800 or position.x > screen_bounds.x + 800:
		queue_free()

func draw_fldiffline():
	fl_diff_line.visible = true
	tgt_fl_line.visible = true
	tgt_fl_line.position.y = target_flightlevel - position.y
	fl_diff_line.points = [Vector2.ZERO, Vector2(0, tgt_fl_line.position.y)]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var move_amount = delta * flightspeed
	position.x += move_amount if going_right else -move_amount
	# descend if changed target
	if abs(target_flightlevel - position.y) > 1:
		$Spawnguard.position.y = lerpf(0, target_flightlevel - position.y, 0.5)
		draw_fldiffline()
		position.y += climbspeed * delta if target_flightlevel > position.y \
		else -climbspeed * delta
	else:
		fl_diff_line.visible = false
		tgt_fl_line.visible = false

	if Globals.dragged_plane == self:
		tgt_fl_line.visible = true
		tgt_fl_line.position = get_viewport().get_mouse_position() - position

	remove_offscreen(delta)

func fall():
	# TODO do something nicer on crash
	pass

func _on_clickbox_input_event(_viewport, event, _shape_idx):
	# print_debug(event)
	if event is InputEventMouseButton and event.pressed:
		Globals.dragged_plane = self


func _on_warnbox_area_entered(area):
	if area.is_in_group("warnbox"):
		warn_controller.emit(self, area.get_parent())


func _on_nearmissbox_area_entered(area):
	if area.is_in_group("nearmiss"):
		near_miss.emit(self.position.lerp(area.get_parent().position, 0.5))


func _on_hitbox_area_entered(area):
	if area.is_in_group("hitbox"):
		collision.emit(self, area.get_parent())
