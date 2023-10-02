extends Node2D

var left: Node
var right: Node

var leash_distance = 96

@onready var line := $Line2D
@onready var label := $Label

# Called when the node enters the scene tree for the first time.
func _ready():
	if !is_instance_valid(left) or !is_instance_valid(right):
		print_debug("WARN WARN proximity warning initialized without proper targets")
		queue_free()
		return
	line.points = [left.position, right.position]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if !is_instance_valid(left) or !is_instance_valid(right):
		queue_free()
		return
	if left.cleared or right.cleared:
		$AudioStreamPlayer.stop()
		queue_free()
	line.points = [left.position, right.position]
	label.position = left.position.lerp(right.position, 0.5)
	if left.position.distance_to(right.position) > leash_distance:
		$AudioStreamPlayer.stop()
		queue_free()


func _on_audio_stream_player_finished():
	$AudioStreamPlayer.play()
