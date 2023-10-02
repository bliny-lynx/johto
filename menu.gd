extends Control

var game = load("res://atc.tscn")


func _ready():
	Audio.play_music()

func _on_texture_button_pressed():
	get_tree().change_scene_to_packed(game)
