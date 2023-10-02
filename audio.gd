extends Node

var num_players = 8
var bus = "Master"

var available = []  # The available players.
var queue = []  # The queue of sounds to play.
var musicplayer = null
var crashplayer = null

func _ready():
	# Create the pool of AudioStreamPlayer nodes.
	musicplayer = AudioStreamPlayer.new()
	musicplayer.bus = "background"
	musicplayer.volume_db = -6
	musicplayer.stream = load("res://sound/MAIN_THEME.wav")
	musicplayer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(musicplayer)
	crashplayer = AudioStreamPlayer.new()
	crashplayer.bus = bus
	crashplayer.volume_db = 3
	crashplayer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	crashplayer.stream = load("res://sound/CRASH.wav")
	add_child(crashplayer)

func play_crash():
	crashplayer.play()

func play_music():
	musicplayer.play()
	musicplayer.finished.connect(func(): musicplayer.play())

	for i in num_players:
		var p = AudioStreamPlayer.new()
		add_child(p)
		available.append(p)
		p.finished.connect(func(): _on_stream_finished(p))
		p.bus = bus

func _on_stream_finished(stream):
	# When finished playing a stream, make the player available again.
	available.append(stream)

func play(sound_path):
	queue.append(sound_path)

func clear_effects():
	for stream_player in get_children():
		if stream_player == musicplayer or stream_player == crashplayer:
			print_debug("stream player is music or crash")
			pass
		else:
			if stream_player.playing:
				stream_player.stop()
				_on_stream_finished(stream_player)

func _process(_delta):
	# Play a queued sound if any players are available.
	if not queue.is_empty() and not available.is_empty():
		available[0].stream = load(queue.pop_front())
		available[0].play()
		available.pop_front()

