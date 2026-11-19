extends Node
## Kodla üretilen ses efektleri (dosya gerekmez).
const RATE := 22050
var bank := {}
var players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	for i in 6:
		var p := AudioStreamPlayer.new(); add_child(p); players.append(p)
	bank.tap = _synth([{"f": 660, "d": .08, "w": "tri", "v": .35}])
	bank.bad = _synth([{"f": 220, "f2": 120, "d": .25, "w": "saw", "v": .2}])
	bank.kick = _synth([{"noise": true, "d": .12, "v": .6, "lp": .25}, {"f": 120, "f2": 60, "d": .12, "v": .5}])
	bank.goal = _synth([{"noise": true, "d": 2.4, "v": .45, "lp": .12, "att": .4}, {"f": 523, "d": .15, "w": "sq", "v": .12, "t0": .05}, {"f": 659, "d": .15, "w": "sq", "v": .12, "t0": .2}, {"f": 784, "d": .35, "w": "sq", "v": .12, "t0": .35}])
	bank.save = _synth([{"noise": true, "d": .9, "v": .3, "lp": .1, "att": .2}, {"f": 300, "f2": 180, "d": .3, "v": .2}])
	bank.whistle = _synth([{"f": 2300, "d": .18, "v": .2}, {"f": 2500, "d": .35, "v": .2, "t0": .22}])
	bank.ach = _synth([{"f": 880, "d": .12, "w": "tri", "v": .3}, {"f": 1175, "d": .2, "w": "tri", "v": .3, "t0": .12}])
	bank.coin = _synth([{"f": 988, "d": .08, "w": "sq", "v": .12}, {"f": 1319, "d": .2, "w": "sq", "v": .12, "t0": .08}])

func _synth(parts: Array) -> AudioStreamWAV:
	var total := 0.0
	for p in parts: total = max(total, p.get("t0", 0.0) + p.d + .02)
	var n := int(total * RATE)
	var buf := PackedFloat32Array(); buf.resize(n)
	for p in parts:
		var s0 := int(p.get("t0", 0.0) * RATE); var len := int(p.d * RATE)
		var ph := 0.0; var lp := 0.0; var att: float = p.get("att", .005)
		for i in len:
			var t := float(i) / RATE
			var env: float = min(1.0, t / max(att, .001)) * exp(-4.5 * t / p.d)
			var smp := 0.0
			if p.get("noise", false):
				lp += (randf() * 2 - 1 - lp) * p.get("lp", .2); smp = lp * 2.2
			else:
				var f: float = p.f if not p.has("f2") else lerp(float(p.f), float(p.f2), t / p.d)
				ph += f / RATE
				match p.get("w", "sin"):
					"tri": smp = 1 - 4 * abs(fmod(ph, 1.0) - .5)
					"sq": smp = 1.0 if fmod(ph, 1.0) < .5 else -1.0
					"saw": smp = fmod(ph, 1.0) * 2 - 1
					_: smp = sin(ph * TAU)
			if s0 + i < n: buf[s0 + i] += smp * env * p.v
	var bytes := PackedByteArray(); bytes.resize(n * 2)
	for i in n: bytes.encode_s16(i * 2, int(clamp(buf[i], -1.0, 1.0) * 32000))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS; w.mix_rate = RATE; w.stereo = false; w.data = bytes
	return w

func play(k: String) -> void:
	if not G.sound or not bank.has(k): return
	for p in players:
		if not p.playing:
			p.stream = bank[k]; p.play(); return
	players[0].stream = bank[k]; players[0].play()
