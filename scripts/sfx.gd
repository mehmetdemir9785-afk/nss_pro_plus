extends Node
## Ses: CC0 kayıtlar (Meta Open Sound) ve fiziksel modelle üretilmiş tribün/düdük sesleri.
## sounds/ klasöründeki bir dosyayı aynı adla değiştirirsen oyun onu kullanır.

const FILES := {
	"kick": ["kick_hard", "kick_shot"], "shot": ["kick_shot"], "pass": ["pass1", "pass2"], "whoosh": ["whoosh"], "swoosh": ["swoosh"],
	"goal": ["goal_roar"], "ooh": ["crowd_ooh"], "cheer": ["crowd_cheer"], "whistle": ["whistle"], "whistle_end": ["whistle_end"],
	"post": ["post"], "net": ["net"], "save": ["save"],
	"tap": ["ui_tap"], "back": ["ui_back"], "confirm": ["ui_confirm"], "notify": ["ui_notify"], "coin": ["coin"],
	"ach": ["levelup"], "levelup": ["levelup"], "victory": ["victory"], "defeat": ["defeat"], "powerup": ["powerup"], "bad": ["ui_error"],
}
const VOL := {"kick": -2.0, "shot": 0.0, "pass": -5.0, "whoosh": -8.0, "swoosh": -9.0, "goal": -1.0, "ooh": -4.0, "cheer": -4.0, "whistle": -7.0, "whistle_end": -7.0,
	"post": -4.0, "net": -5.0, "save": -3.0, "tap": -9.0, "back": -9.0, "confirm": -7.0, "notify": -8.0, "coin": -8.0, "ach": -6.0, "levelup": -6.0, "victory": -5.0, "defeat": -6.0, "powerup": -7.0, "bad": -9.0}
var bank := {}
var players: Array[AudioStreamPlayer] = []
var crowd_p: AudioStreamPlayer
var crowd_target := -80.0

func _ready() -> void:
	for i in 10:
		var p := AudioStreamPlayer.new(); add_child(p); players.append(p)
	for k in FILES:
		var arr := []
		for n in FILES[k]:
			var path := "res://sounds/%s.ogg" % n
			if ResourceLoader.exists(path): arr.append(load(path))
		bank[k] = arr
	crowd_p = AudioStreamPlayer.new(); add_child(crowd_p)
	if ResourceLoader.exists("res://sounds/crowd_loop.ogg"):
		var s: AudioStreamOggVorbis = load("res://sounds/crowd_loop.ogg")
		s.loop = true
		crowd_p.stream = s
	crowd_p.volume_db = -80.0

func play(k: String, vol := 0.0, pitch_var := .06) -> void:
	if not G.sound or not bank.has(k) or bank[k].is_empty(): return
	var st = bank[k][randi() % bank[k].size()]
	var pl: AudioStreamPlayer = null
	for p in players:
		if not p.playing: pl = p; break
	if pl == null: pl = players[0]
	pl.stream = st
	pl.volume_db = VOL.get(k, -6.0) + vol
	pl.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	pl.play()

## Tribün ambiyansı: on=true maç sırasında; level 0..1 heyecan
func crowd(on: bool, level := .5) -> void:
	if crowd_p.stream == null: return
	if on and G.sound:
		crowd_target = lerp(-24.0, -9.0, clamp(level, 0, 1))
		if not crowd_p.playing: crowd_p.volume_db = -40.0; crowd_p.play()
	else:
		crowd_target = -80.0

func _process(dt: float) -> void:
	if crowd_p.playing:
		crowd_p.volume_db = lerp(crowd_p.volume_db, crowd_target, clamp(dt * 2.5, 0, 1))
		if crowd_target <= -79 and crowd_p.volume_db < -60: crowd_p.stop()
