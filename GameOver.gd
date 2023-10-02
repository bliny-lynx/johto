extends Control

var game = preload("res://atc.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	$score.text = "Score %d" % Globals.score


func _on_texture_button_pressed():
	Globals.score = 0
	get_tree().change_scene_to_packed(game)
