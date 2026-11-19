extends Node
## Efsane Yolu: oyun durumu ve kuralları (autoload "G")

var S = null          # tüm kariyer durumu (Dictionary)
var main = null       # arayüz kökü (main.gd)
var sound := true
var speed := 1.0      # test için zaman çarpanı
const SAVE := "user://kariyer.json"
const HOFP := "user://efsaneler.json"
const SETP := "user://ayarlar.json"

const LEAGUE_WEEKS := 22
const CUP_WEEKS := {4: "Son 16", 9: "Çeyrek Final", 14: "Yarı Final", 19: "Final"}
const NAT_WEEKS := [6, 12, 18]
const TOUR_R := ["Son 16", "Çeyrek Final", "Yarı Final", "Final"]

const AT := {"sut": "Şut", "pas": "Pas", "drip": "Dripling", "hiz": "Hız", "fiz": "Fizik", "kafa": "Kafa", "sav": "Savunma", "duran": "Duran Top"}
const AK := ["sut", "pas", "drip", "hiz", "fiz", "kafa", "sav", "duran"]
const POS := {
	"FV": {"n": "Forvet", "d": "Gol odaklı. Bitiricilik, hız ve kafa.", "w": {"sut": .32, "kafa": .14, "hiz": .18, "drip": .14, "fiz": .1, "pas": .08, "duran": .04}, "main": ["sut", "hiz", "kafa", "drip"],
		"mom": [["shot", 46], ["header", 15], ["dribble", 17], ["pass", 12], ["freekick", 5], ["penalty", 5]]},
	"KN": {"n": "Kanat", "d": "Çalım, hız, orta ve asist.", "w": {"drip": .28, "hiz": .28, "pas": .18, "sut": .16, "fiz": .05, "duran": .05}, "main": ["drip", "hiz", "pas", "sut"],
		"mom": [["dribble", 30], ["pass", 28], ["shot", 27], ["freekick", 10], ["penalty", 5]]},
	"OS": {"n": "Orta Saha", "d": "Oyun kurucu. Pas, duran top, uzaktan şut.", "w": {"pas": .32, "drip": .18, "sut": .14, "duran": .12, "fiz": .1, "sav": .1, "hiz": .04}, "main": ["pas", "duran", "drip", "sut"],
		"mom": [["pass", 42], ["shot", 22], ["freekick", 18], ["dribble", 13], ["penalty", 5]]},
	"DF": {"n": "Stoper", "d": "Savunmanın lideri. Müdahale, fizik, kafa.", "w": {"sav": .38, "fiz": .2, "kafa": .2, "hiz": .1, "pas": .12}, "main": ["sav", "fiz", "kafa", "hiz"],
		"mom": [["tackle", 56], ["header", 20], ["pass", 19], ["freekick", 5]]},
}
const POS_ORDER := ["FV", "KN", "OS", "DF"]
const TIERS := [
	{"n": "Avrupa Elit Lig", "min": 73, "max": 89, "wage": 30000, "cup": "Şampiyonlar Kupası", "fm": 1.0},
	{"n": "Süper Lig", "min": 61, "max": 75, "wage": 6000, "cup": "Ulusal Kupa", "fm": .55},
	{"n": "1. Lig", "min": 51, "max": 63, "wage": 1500, "cup": "Ulusal Kupa", "fm": .3},
	{"n": "Bölgesel Lig", "min": 38, "max": 53, "wage": 350, "cup": "Ulusal Kupa", "fm": .15}]
const TEAMN := [
	["Northbridge City", "Kingsport United", "Milano Nero", "Rhein Adler", "Paris Étoile", "Porto Azul", "Castilla CF", "Amstel Rood", "Riviera AC", "Alpen FC", "Thames Athletic", "Danubia SC"],
	["Boğaziçi SK", "Başkent United", "Anadolu Yıldızı", "Ege Gücü", "Karadeniz FK", "Mezopotamya SK", "Haliç Spor", "Kuzey Rüzgarı", "Turkuaz SK", "Lale Spor", "Kaplanlar FK", "Şimşek SK"],
	["Marmara Yıldızı", "Kapadokya FK", "Akdeniz Gücü", "Trakya SK", "Fırat Spor", "Uludağ FK", "Pamukkale SK", "Erciyes Gücü", "Göller Spor", "Zeytin FK", "Kaçkar SK", "Ilgaz Spor"],
	["Kartal Gençlik", "Bozkır FK", "Çınar Spor", "Yeşilvadi SK", "Toros Gücü", "Kızılırmak SK", "Liman Spor", "Değirmen FK", "Ova Spor", "Yıldırım Gençlik", "Sahil Gücü", "Kale Spor"]]
const COLS := ["#dc2626", "#2563eb", "#16a34a", "#ca8a04", "#9333ea", "#0891b2", "#db2777", "#ea580c", "#4f46e5", "#059669", "#b91c1c", "#1d4ed8", "#65a30d", "#7c3aed", "#f8fafc", "#111827"]
const NATS := {"Türkiye": 72, "Almanya": 85, "Fransa": 87, "İspanya": 86, "İngiltere": 85, "İtalya": 83, "Brezilya": 87, "Arjantin": 88, "Portekiz": 84, "Hollanda": 82, "Belçika": 79, "Hırvatistan": 79, "Uruguay": 79, "Kolombiya": 77, "Fas": 78, "Japonya": 76, "ABD": 74, "Meksika": 75, "Danimarka": 77, "İsviçre": 77, "Senegal": 76, "Polonya": 74, "Sırbistan": 74, "Avusturya": 77, "Ukrayna": 73, "Güney Kore": 74, "Nijerya": 74, "Gürcistan": 68, "Bosna-Hersek": 66, "Azerbaycan": 58, "Mısır": 71, "Cezayir": 72, "İran": 70, "Yunanistan": 71}
const FN_TR := ["Emre", "Burak", "Kaan", "Arda", "Mert", "Cem", "Oğuz", "Serkan", "Hakan", "Volkan", "Yusuf", "Efe", "Barış", "Tolga", "Umut", "Can", "Deniz", "Kerem", "Onur", "Selim", "Alper", "Ozan", "Berk", "Eren"]
const LN_TR := ["Yılmaz", "Kaya", "Demir", "Çelik", "Şahin", "Aydın", "Öztürk", "Arslan", "Doğan", "Koç", "Kurt", "Polat", "Aksoy", "Erdem", "Güneş", "Tekin", "Bulut", "Ateş", "Kılıç", "Uysal", "Kalkan", "Sezer"]
const FN_EU := ["Lucas", "Mateo", "Jonas", "Luca", "Hugo", "Rafael", "Diego", "Marco", "Kai", "Theo", "Liam", "Noah", "Bruno", "Enzo", "Iker", "Milan", "Sander", "João", "Felix", "Nico", "Adrien", "Tomás"]
const LN_EU := ["Silva", "Moreau", "Rossi", "Becker", "Fernandes", "Costa", "Martín", "Novak", "Jansen", "Dubois", "Schmidt", "Romero", "Ricci", "Santos", "Weber", "Varga", "Lindqvist", "Okafor", "Mendes", "Laurent", "Kowalski", "Halvorsen"]

const SHOP := [
	{"id": "boot1", "cat": "Ekipman", "name": "Pro Krampon", "price": 3000, "desc": "Şut ve Dripling +2", "g": "boot", "lv": 1, "bonus": {"sut": 2, "drip": 2}},
	{"id": "boot2", "cat": "Ekipman", "name": "Elit Krampon", "price": 25000, "desc": "Şut ve Dripling +4, Duran Top +2", "g": "boot", "lv": 2, "bonus": {"sut": 4, "drip": 4, "duran": 2}},
	{"id": "boot3", "cat": "Ekipman", "name": "Efsane Krampon", "price": 180000, "desc": "Şut, Dripling +6, Duran Top +4", "g": "boot", "lv": 3, "bonus": {"sut": 6, "drip": 6, "duran": 4}},
	{"id": "gear1", "cat": "Ekipman", "name": "Performans Seti", "price": 6000, "desc": "Hız ve Fizik +2", "g": "gear", "lv": 1, "bonus": {"hiz": 2, "fiz": 2}},
	{"id": "gear2", "cat": "Ekipman", "name": "Bilimsel Takip Seti", "price": 60000, "desc": "Hız, Fizik +4, Savunma +2", "g": "gear", "lv": 2, "bonus": {"hiz": 4, "fiz": 4, "sav": 2}},
	{"id": "trainer1", "cat": "Ekip", "name": "Kişisel Antrenör", "price": 8000, "desc": "Antrenman verimi %30 artar", "g": "trainer", "lv": 1, "train": 1.3},
	{"id": "trainer2", "cat": "Ekip", "name": "Elit Antrenör Ekibi", "price": 90000, "desc": "Antrenman verimi %65 artar", "g": "trainer", "lv": 2, "train": 1.65},
	{"id": "physio", "cat": "Ekip", "name": "Fizyoterapist", "price": 12000, "desc": "Haftalık enerji +10, sakatlık riski yarıya iner"},
	{"id": "chef", "cat": "Ekip", "name": "Özel Aşçı", "price": 15000, "desc": "Haftalık moral +2, enerji +4"},
	{"id": "agent", "cat": "Ekip", "name": "Süper Menajer", "price": 25000, "desc": "Kontrat teklifleri %25 daha iyi, daha çok sponsor"},
	{"id": "psy", "cat": "Ekip", "name": "Spor Psikoloğu", "price": 40000, "desc": "Büyük anlarda zamanlama alanı %12 genişler"},
	{"id": "house1", "cat": "Ev", "name": "Rezidans Daire", "price": 40000, "desc": "Haftalık moral +3, enerji +4", "g": "house", "lv": 1, "moral": 3, "energy": 4, "fame": 1},
	{"id": "house2", "cat": "Ev", "name": "Deniz Manzaralı Villa", "price": 350000, "desc": "Haftalık moral +5, enerji +7", "g": "house", "lv": 2, "moral": 5, "energy": 7, "fame": 3},
	{"id": "house3", "cat": "Ev", "name": "Malikane", "price": 2500000, "desc": "Haftalık moral +8, enerji +10", "g": "house", "lv": 3, "moral": 8, "energy": 10, "fame": 6},
	{"id": "car1", "cat": "Araba", "name": "Spor Hatchback", "price": 20000, "desc": "Moral +1, ün +1", "g": "car", "lv": 1, "moral": 1, "fame": 1},
	{"id": "car2", "cat": "Araba", "name": "Alman Sedan", "price": 90000, "desc": "Moral +2, ün +3", "g": "car", "lv": 2, "moral": 2, "fame": 3},
	{"id": "car3", "cat": "Araba", "name": "İtalyan Süper Spor", "price": 650000, "desc": "Moral +4, ün +6", "g": "car", "lv": 3, "moral": 4, "fame": 6},
	{"id": "watch", "cat": "Lüks", "name": "Altın Saat", "price": 50000, "desc": "Ün +3", "fame": 3},
	{"id": "yacht", "cat": "Lüks", "name": "Yat", "price": 3000000, "desc": "Moral +4, ün +6", "moral": 4, "fame": 6},
	{"id": "jet", "cat": "Lüks", "name": "Özel Jet", "price": 9000000, "desc": "Moral +5, ün +10, haftalık enerji +5", "moral": 5, "fame": 10, "energy": 5},
	{"id": "inv1", "cat": "Yatırım", "name": "Mahalle Kafesi", "price": 30000, "desc": "Haftalık €550 gelir", "income": 550},
	{"id": "inv2", "cat": "Yatırım", "name": "Spor Salonu Zinciri", "price": 160000, "desc": "Haftalık €2.900 gelir", "income": 2900},
	{"id": "inv3", "cat": "Yatırım", "name": "Butik Otel", "price": 900000, "desc": "Haftalık €16.000 gelir", "income": 16000},
	{"id": "inv4", "cat": "Yatırım", "name": "Futbol Akademisi", "price": 2500000, "desc": "Haftalık €42.000 gelir, ün +5", "income": 42000, "fame": 5},
	{"id": "inv5", "cat": "Yatırım", "name": "Kulüp Hissesi", "price": 12000000, "desc": "Haftalık €210.000 gelir, ün +8", "income": 210000, "fame": 8},
]
const SHOP_CATS := [["Ekipman", "Ekipman"], ["Ekip", "Kişisel ekip"], ["Ev", "Ev"], ["Araba", "Garaj"], ["Lüks", "Lüks"], ["Yatırım", "Yatırımlar"]]
const BRANDS := ["Volt Enerji İçeceği", "Aero Krampon", "Nova Telekom", "Zirve Bank", "Atlas Otomotiv", "Pirinç Saat", "Kuzey Giyim", "Orbit Oyun", "Mavi Su", "Lumen Kulaklık"]
const ACH := [["g1", "İlk Gol", "İlk profesyonel golünü at"], ["hat", "Hat-trick", "Bir maçta 3 gol at"], ["g50", "50 Gol", "50 kariyer golü"], ["g100", "100 Gol", "100 kariyer golü"], ["g250", "250 Gol", "250 kariyer golü"],
	["a50", "50 Asist", "50 kariyer asisti"], ["r10", "Kusursuz Maç", "Bir maçta 10 reyting al"], ["motm10", "10 Kez Maçın Adamı", "10 kez maçın adamı ol"], ["fk", "Frikik Golü", "Serbest vuruştan gol at"], ["pen", "Penaltı Kahramanı", "Seri penaltılarda kendi atışını at ve kazan"],
	["cap1", "Milli Forma", "İlk milli maçına çık"], ["cap50", "50 Milli Maç", "50 milli maça çık"], ["lig", "Lig Şampiyonu", "Lig şampiyonu ol"], ["cup", "Kupa Zaferi", "Kupa kazan"], ["ucl", "Avrupa Fatihi", "Şampiyonlar Kupası kazan"],
	["wc", "Dünya Şampiyonu", "Dünya Şampiyonası kazan"], ["ball", "Altın Top", "Altın Top kazan"], ["gk", "Gol Kralı", "Gol kralı ol"], ["elite", "Elit Transfer", "Avrupa Elit Lig'de oyna"], ["mil", "Milyoner", "€1M biriktir"],
	["ovr80", "80 Güç", "80 genel güce ulaş"], ["ovr90", "90 Güç", "90 genel güce ulaş"], ["fame", "1M Takipçi", "1 milyon takipçiye ulaş"], ["capt", "Kaptan", "Takım kaptanı ol"]]

# ---------------- yardımcılar ----------------
func R(a: float, b: float) -> float: return randf_range(a, b)
func RI(a: int, b: int) -> int: return randi_range(a, b)
func pick(a: Array): return a[randi() % a.size()]
func wpick(list: Array):
	var t := 0.0
	for x in list: t += x[1]
	var r := randf() * t
	for x in list:
		r -= x[1]
		if r <= 0: return x[0]
	return list[0][0]
func poisson(l: float) -> int:
	var L := exp(-l); var k := 0; var p := 1.0
	while true:
		k += 1; p *= randf()
		if p <= L: break
	return k - 1
func shuffled(a: Array) -> Array:
	var b := a.duplicate(); b.shuffle(); return b
func clampf2(v, a, b): return clamp(v, a, b)
func gen_name(eu: bool) -> String: return (pick(FN_EU) + " " + pick(LN_EU)) if eu else (pick(FN_TR) + " " + pick(LN_TR))
func _th(a: int) -> String:
	var s := str(a); var out := ""; var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out; c += 1
		if c % 3 == 0 and i > 0: out = "." + out
	return out
func fmt(n) -> String:
	var v := int(round(float(n))); var neg := v < 0; var a: int = abs(v); var s := ""
	if a >= 1000000: s = (("%.1f" if a >= 10000000 else "%.2f") % (a / 1000000.0)).replace(".", ",") + "M"
	else: s = _th(a)
	return ("-" if neg else "") + "€" + s
func fmtf(n) -> String:
	var v := float(n)
	if v >= 1e6: return ("%.1f" % (v / 1e6)).replace(".", ",") + "M"
	if v >= 1e3: return ("%.1f" % (v / 1e3)).replace(".", ",") + "B"
	return str(int(v))
func r1(v) -> String: return ("%.1f" % float(v))
func r2(v) -> String: return ("%.2f" % float(v))

# ---------------- kayıt ----------------
func save_game() -> void:
	if S == null: return
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(S))
func _norm(v):
	if typeof(v) == TYPE_FLOAT and v == floor(v) and abs(v) < 1e15: return int(v)
	if typeof(v) == TYPE_ARRAY:
		var a := []
		for x in v: a.append(_norm(x))
		return a
	if typeof(v) == TYPE_DICTIONARY:
		var d := {}
		for k in v: d[k] = _norm(v[k])
		return d
	return v
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE): return false
	var txt := FileAccess.get_file_as_string(SAVE)
	var d = JSON.parse_string(txt)
	if typeof(d) != TYPE_DICTIONARY or not d.has("p"): return false
	S = _norm(d)
	return true
func delete_save() -> void:
	if FileAccess.file_exists(SAVE): DirAccess.remove_absolute(SAVE)
func export_code() -> String: return Marshalls.utf8_to_base64(JSON.stringify(S))
func import_code(c: String) -> bool:
	var t := Marshalls.base64_to_utf8(c.strip_edges())
	var d = JSON.parse_string(t)
	if typeof(d) != TYPE_DICTIONARY or not d.has("p"): return false
	S = _norm(d); S.ui = {"tab": "hub", "lt": "tablo"}; save_game(); return true
func hof() -> Array:
	if not FileAccess.file_exists(HOFP): return []
	var d = JSON.parse_string(FileAccess.get_file_as_string(HOFP))
	return d if typeof(d) == TYPE_ARRAY else []
func hof_add(x: Dictionary) -> void:
	var h := hof(); h.push_front(x)
	var f := FileAccess.open(HOFP, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(h.slice(0, 20)))
func save_settings() -> void:
	var f := FileAccess.open(SETP, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify({"sound": sound}))
func _ready() -> void:
	randomize()
	if FileAccess.file_exists(SETP):
		var d = JSON.parse_string(FileAccess.get_file_as_string(SETP))
		if typeof(d) == TYPE_DICTIONARY: sound = d.get("sound", true)

# ---------------- erişim ----------------
func team(id) -> Dictionary: return S.teams[int(id)]
func my_team() -> Dictionary: return team(S.p.team)
func tier() -> int: return int(my_team().tier)
func perks() -> Dictionary:
	var p = S.p
	var k := {"moral": 0.0, "energy": 0.0, "fame": 0.0, "train": 1.0, "income": 0.0, "bonus": {}, "inj": 1.0, "agent": 1.0, "psy": 1.0}
	var best := {}
	var list := []
	for it in SHOP:
		if not p.items.has(it.id): continue
		if it.has("g"):
			if not best.has(it.g) or best[it.g].lv < it.lv: best[it.g] = it
		else: list.append(it)
	list.append_array(best.values())
	for it in list:
		k.moral += it.get("moral", 0); k.energy += it.get("energy", 0); k.fame += it.get("fame", 0); k.income += it.get("income", 0)
		if it.has("train"): k.train = max(k.train, it.train)
		if it.has("bonus"):
			for a in it.bonus: k.bonus[a] = k.bonus.get(a, 0) + it.bonus[a]
	if p.items.has("physio"): k.energy += 10; k.inj = .5
	if p.items.has("chef"): k.moral += 2; k.energy += 4
	if p.items.has("agent"): k.agent = 1.25
	if p.items.has("psy"): k.psy = 1.12
	return k
func eff(a: String) -> int: return clamp(int(S.p.attrs[a]) + int(perks().bonus.get(a, 0)), 1, 99)
func ovr() -> int:
	var w = POS[S.p.pos].w; var s := 0.0; var t := 0.0
	var b = perks().bonus
	for a in w:
		s += clamp(int(S.p.attrs[a]) + int(b.get(a, 0)), 1, 99) * w[a]; t += w[a]
	return int(round(s / t))
func followers() -> int: return int(round(300 + pow(float(S.p.fame), 2.4) * 60))
func market_value() -> int:
	var o := ovr(); var a := int(S.p.age)
	var af := 1.5 if a <= 21 else (1.25 if a <= 24 else (1.0 if a <= 28 else (.65 if a <= 31 else .35)))
	return int(round(8000 * exp((o - 45) / 6.4) * af * (1 + S.p.fame / 60.0) / 1000.0)) * 1000
func form_avg() -> float:
	var r: Array = S.p.ratings
	if r.is_empty(): return 6.0
	var l := r.slice(max(0, r.size() - 5))
	var s := 0.0
	for x in l: s += x
	return s / l.size()
func sponsor_weekly() -> int:
	var s := 0
	for x in S.p.sponsors: s += int(x.w)
	return s
func nat_str() -> int: return int(NATS.get(S.p.nation, 70))
func owned(id: String) -> bool: return S.p.items.has(id)
func item_by(id: String) -> Dictionary:
	for it in SHOP:
		if it.id == id: return it
	return {}
func news(t: String) -> void:
	S.news.push_front({"t": t, "w": "S%d H%d" % [S.season, min(int(S.week), LEAGUE_WEEKS)]})
	if S.news.size() > 30: S.news.resize(30)
func toast(t: String) -> void:
	if main: main.toast(t)
func ach_name(id: String) -> String:
	for a in ACH:
		if a[0] == id: return a[1]
	return id
func unlock(id: String) -> void:
	if S.p.ach.has(id): return
	S.p.ach.append(id); toast("Başarım açıldı: " + ach_name(id)); Sfx.play("ach"); news("Başarım: " + ach_name(id))
func check_ach() -> void:
	var p = S.p; var c = p.career
	if c.goals >= 1: unlock("g1")
	if c.goals >= 50: unlock("g50")
	if c.goals >= 100: unlock("g100")
	if c.goals >= 250: unlock("g250")
	if c.assists >= 50: unlock("a50")
	if c.motm >= 10: unlock("motm10")
	if p.nat.caps >= 1: unlock("cap1")
	if p.nat.caps >= 50: unlock("cap50")
	if p.money >= 1e6: unlock("mil")
	var o := ovr()
	if o >= 80: unlock("ovr80")
	if o >= 90: unlock("ovr90")
	if followers() >= 1000000: unlock("fame")
	if p.captain: unlock("capt")
	if tier() == 0: unlock("elite")

# ---------------- dünya ----------------
func gen_teams() -> Array:
	var T := []; var id := 0
	for ti in TEAMN.size():
		var tr = TIERS[ti]
		for nm in TEAMN[ti]:
			T.append({"id": id, "name": nm, "tier": ti, "str": RI(tr.min, tr.max - 2), "star": {"name": gen_name(ti == 0), "goals": 0}, "col": COLS[(id * 7 + 3) % COLS.size()], "pat": id % 5})
			id += 1
	return T
func make_fixtures(ids: Array) -> Array:
	var n := ids.size(); var arr := ids.duplicate(); var rounds := []
	for r in n - 1:
		var rd := []
		for i in n / 2:
			var a = arr[i]; var b = arr[n - 1 - i]
			rd.append([b, a] if r % 2 else [a, b])
		rounds.append(rd)
		var na := [arr[0], arr[n - 1]]; na.append_array(arr.slice(1, n - 1)); arr = na
	var second := []
	for rd in rounds:
		var x := []
		for m in rd: x.append([m[1], m[0]])
		second.append(x)
	return rounds + second
func league_ids(t: int) -> Array:
	var a := []
	for x in S.teams:
		if int(x.tier) == t: a.append(int(x.id))
	return a
func init_league() -> void:
	var ids := league_ids(tier())
	S.table = {}
	for i in ids: S.table[str(i)] = {"p": 0, "w": 0, "d": 0, "l": 0, "gf": 0, "ga": 0, "pts": 0}
	S.fixtures = make_fixtures(shuffled(ids)); S.results = []
	for t in S.teams: t.star.goals = 0
func sorted_table() -> Array:
	var ids := []
	for k in S.table: ids.append(int(k))
	ids.sort_custom(func(a, b):
		var x = S.table[str(a)]; var y = S.table[str(b)]
		if x.pts != y.pts: return x.pts > y.pts
		if x.gf - x.ga != y.gf - y.ga: return x.gf - x.ga > y.gf - y.ga
		return x.gf > y.gf)
	return ids
func add_result(h, a, gh: int, ga: int) -> void:
	if not S.table.has(str(h)) or not S.table.has(str(a)): return
	var H = S.table[str(h)]; var A = S.table[str(a)]
	H.p += 1; A.p += 1; H.gf += gh; H.ga += ga; A.gf += ga; A.ga += gh
	if gh > ga: H.w += 1; H.pts += 3; A.l += 1
	elif gh < ga: A.w += 1; A.pts += 3; H.l += 1
	else: H.d += 1; A.d += 1; H.pts += 1; A.pts += 1
func sim_score(sh: float, sa: float) -> Array:
	var lh := 1.3 * pow(sh / sa, 1.7) * 1.1; var la := 1.3 * pow(sa / sh, 1.7) * .9
	return [poisson(clamp(lh, .2, 4)), poisson(clamp(la, .2, 4))]
func star_goals(tid, g: int) -> void:
	var t := team(tid)
	for i in g:
		if randf() < .42: t.star.goals += 1

func zs() -> Dictionary: return {"apps": 0, "goals": 0, "assists": 0, "lgoals": 0, "rsum": 0.0, "motm": 0}
func new_game(nm: String, nat: String, pos: String, num: int) -> void:
	S = {"v": 1, "season": 1, "year": 2026, "week": 1, "phase": "season", "teams": gen_teams(), "news": [], "ui": {"tab": "hub", "lt": "tablo"}, "wq": [], "pend": [], "cup": {"alive": true}, "tour": null, "tut": {"shot": false}, "sm": null, "offers": []}
	var t3 := []
	for t in S.teams:
		if t.tier == 3: t3.append(t)
	t3.sort_custom(func(a, b): return a.str < b.str)
	var tm = t3[RI(2, 7)]
	var at := {}
	for a in AK: at[a] = RI(34, 44)
	var mn: Array = POS[pos].main
	for i in mn.size(): at[mn[i]] = RI(50, 54) - i
	var axp := {}
	for a in AK: axp[a] = 0.0
	S.p = {"name": nm, "nation": nat, "pos": pos, "num": num, "age": 17, "attrs": at, "axp": axp, "gp": 8, "energy": 100.0, "moral": 70.0, "ratings": [], "fame": 1.0, "money": 1500.0, "wage": 350, "contract": 2, "team": tm.id, "injury": 0,
		"rel": {"coach": 52.0, "team": 50.0, "fans": 30.0, "media": 40.0}, "items": {}, "sponsors": [], "season": zs(), "career": {"apps": 0, "goals": 0, "assists": 0, "motm": 0, "rsum": 0.0}, "trophies": [], "awards": [], "history": [],
		"nat": {"called": false, "caps": 0, "goals": 0}, "actions": 3, "ach": [], "captain": false, "target": null, "clubs": [tm.name]}
	init_league(); set_target()
	news("%s ile ilk profesyonel sözleşmeni imzaladın. Haftalık %s." % [tm.name, fmt(350)])
	start_week(); save_game()
func set_target() -> void:
	var t := tier(); var ps: String = S.p.pos
	if ps == "FV": S.p.target = {"k": "goals", "v": [16, 13, 10, 8][t] + (3 if ovr() > my_team().str + 5 else 0), "n": "gol"}
	elif ps == "KN": S.p.target = {"k": "ga", "v": [16, 13, 10, 8][t], "n": "gol + asist"}
	elif ps == "OS": S.p.target = {"k": "assists", "v": [9, 8, 7, 6][t], "n": "asist"}
	else: S.p.target = {"k": "avg", "v": 6.9, "n": "ortalama reyting"}
func target_val() -> float:
	var s = S.p.season; var t = S.p.target
	if t == null: return 0
	match t.k:
		"goals": return s.goals
		"assists": return s.assists
		"ga": return s.goals + s.assists
	return snapped(s.rsum / s.apps, .01) if s.apps > 0 else 0.0

# ---------------- hafta ----------------
func start_week() -> void:
	var p = S.p; S.wq = []
	if S.phase == "tour":
		var r := int(S.tour.round)
		S.wq.append({"type": "tour", "label": "Dünya Şampiyonası, " + TOUR_R[r], "ko": true, "opp": S.tour.opps[r], "home": true}); return
	var w := int(S.week)
	if CUP_WEEKS.has(w) and S.cup.alive:
		var t := tier(); var pool := []
		for x in S.teams:
			if int(x.id) == int(p.team): continue
			if (t == 0 and x.tier <= 1) or (t > 0 and abs(int(x.tier) - t) <= 1 and x.tier > 0): pool.append(x)
		var opp = pick(pool)
		if CUP_WEEKS[w] == "Final" or CUP_WEEKS[w] == "Yarı Final":
			pool.sort_custom(func(a, b): return a.str > b.str); opp = pick(pool.slice(0, 6))
		S.wq.append({"type": "cup", "label": TIERS[t].cup + ", " + CUP_WEEKS[w], "ko": true, "oppId": opp.id, "home": randf() < .5})
	if NAT_WEEKS.has(w) and p.nat.called:
		var opts := []
		for n in NATS:
			if n != p.nation: opts.append(n)
		S.wq.append({"type": "nat", "label": "Milli maç, eleme", "ko": false, "natOpp": pick(opts), "home": randf() < .5})
	if w - 1 < S.fixtures.size():
		var rd: Array = S.fixtures[w - 1]
		for m in rd:
			if int(m[0]) == int(p.team) or int(m[1]) == int(p.team):
				var home: bool = int(m[0]) == int(p.team)
				S.wq.append({"type": "lig", "label": "%s, %d. hafta" % [TIERS[tier()].n, w], "ko": false, "oppId": int(m[1]) if home else int(m[0]), "home": home, "round": w - 1})
				break

func end_week() -> void:
	var p = S.p; var k := perks()
	if S.phase == "tour":
		p.energy = clamp(p.energy + 28 + k.energy, 0, 100); start_week(); save_game(); main.render(); main.show_pending(); return
	p.energy = clamp(p.energy + 18 + k.energy, 0, 100)
	p.moral = clamp(p.moral + (60 - p.moral) * .12 + k.moral, 0, 100)
	var inc: float = p.wage + sponsor_weekly() + k.income
	p.money += inc
	p.fame = clamp(p.fame + k.fame * .02, 0, 100)
	if p.injury > 0:
		p.injury -= 1
		if p.injury == 0: news("Sakatlığın geçti, sahalara dönüyorsun."); toast("Sakatlık bitti, sahalara dönüyorsun")
	p.actions = 3; S.week += 1
	for r in ["team", "fans", "media"]: p.rel[r] = clamp(p.rel[r] + (50 - p.rel[r]) * .02, 0, 100)
	if [5, 11, 17].has(int(S.week)): nat_check()
	sponsor_check()
	if randf() < .38 and S.week <= LEAGUE_WEEKS: S.pend.append(rand_event())
	if S.week == 12: mid_season_news()
	if S.week > LEAGUE_WEEKS:
		if int(S.season) % 2 == 0 and p.nat.called:
			S.phase = "tour"
			var ns := []
			for n in NATS:
				if n != p.nation: ns.append(n)
			ns.sort_custom(func(a, b): return NATS[a] < NATS[b])
			S.tour = {"round": 0, "alive": true, "opps": [ns[RI(8, 14)], ns[RI(16, 22)], ns[RI(24, 28)], ns[RI(29, ns.size() - 1)]]}
			S.pend.append({"title": "Dünya Şampiyonası", "text": "Lig sezonu bitti ama sen %s milli takımıyla Dünya Şampiyonası'na gidiyorsun. Dört maç, hepsi eleme usulü." % p.nation, "ch": [{"t": "Hazırım", "f": {"moral": 10}}]})
			start_week(); save_game(); main.render(); main.show_pending(); return
		season_end(); return
	start_week(); save_game(); main.render(); main.show_pending()

func mid_season_news() -> void:
	var o := ovr(); var t := tier()
	if t > 0 and o >= TIERS[t - 1].min - 2:
		var pool := []
		for x in S.teams:
			if x.tier == t - 1: pool.append(x)
		var tm = pick(pool)
		news("Söylenti: %s seni yakından takip ediyor." % tm.name); toast(tm.name + " seni izliyor")
func nat_check() -> void:
	var p = S.p; var o := ovr(); var ns := nat_str(); var f := form_avg(); var was: bool = p.nat.called
	p.nat.called = (o >= ns - 9 and f >= 6.3) or (was and o >= ns - 12 and f >= 5.9) or (o >= ns - 3)
	if p.nat.called and not was:
		news("%s milli takımına davet edildin." % p.nation)
		S.pend.append({"title": "Milli takım daveti", "text": "%s milli takımının teknik direktörü seni kadroya çağırdı. Ülkeni temsil etme zamanı." % p.nation, "ch": [{"t": "Gururla kabul ediyorum", "f": {"moral": 15, "fame": 2}}]})
	elif not p.nat.called and was: news("Milli takım kadrosuna bu dönem çağrılmadın.")
func sponsor_check() -> void:
	var p = S.p; var mx := 5 if p.items.has("agent") else 4
	if p.sponsors.size() >= mx: return
	var need: float = 6 + p.sponsors.size() * 12
	if p.fame >= need and randf() < (.3 if p.items.has("agent") else .18):
		var opts := []
		for b in BRANDS:
			var used := false
			for s in p.sponsors:
				if s.n == b: used = true
			if not used: opts.append(b)
		var b = pick(opts)
		var w := int(round(pow(p.fame, 1.6) * 8 * R(.8, 1.25) * (1.2 if p.items.has("agent") else 1.0) / 10.0)) * 10 + 50
		S.pend.append({"title": "Sponsorluk teklifi", "text": "%s seninle reklam anlaşması yapmak istiyor: haftalık %s, iki sezon." % [b, fmt(w)], "ch": [{"t": "Kabul et", "f": {"sponsor": {"n": b, "w": w, "s": 2}}}, {"t": "Reddet", "f": {}}]})

func rand_event() -> Dictionary:
	var p = S.p; var cm: String = my_team().name
	var g := int(max(500, round(p.money * .15))); var don := int(max(200, round(p.money * .05)))
	var E := [
		{"title": "Basın toplantısı", "text": "Gazeteciler son maçlardaki süren hakkında soru soruyor.", "ch": [{"t": "Takımımı ve hocamı savunurum", "f": {"media": 3, "coach": 5}}, {"t": "Daha fazla süre hak ediyorum", "f": {"fans": 4, "coach": -8, "media": 5, "fame": 1}}]},
		{"title": "Doğum günü partisi", "text": "Bir takım arkadaşın seni doğum günü partisine çağırdı. Yarın antrenman var.", "ch": [{"t": "Gidiyorum", "f": {"team": 8, "energy": -12, "moral": 8}}, {"t": "Kibarca reddet", "f": {"team": -4}}]},
		{"title": "Sosyal medya krizi", "text": "Bir taraftar performansını sert bir dille eleştirdi ve paylaşım çok yayıldı.", "ch": [{"t": "Esprili bir cevap ver", "f": {"fame": 2, "media": -3, "fans": 2}}, {"t": "Görmezden gel", "f": {"moral": -3}}, {"t": "Daha çok çalışacağım de", "f": {"fans": 4, "media": 2}}]},
		{"title": "Okul ziyareti", "text": "Yerel bir ilkokul seni çocuklarla tanışmaya davet ediyor.", "ch": [{"t": "Seve seve katılırım", "f": {"fans": 6, "media": 5, "energy": -5, "fame": 1}}, {"t": "Vaktim yok", "f": {"media": -2}}]},
		{"title": "Ekstra antrenman", "text": "Hocan maçtan sonra ekstra çalışma yapmanı istiyor.", "ch": [{"t": "Kabul ediyorum", "f": {"energy": -15, "coach": 6, "xp": 45}}, {"t": "Yorgunum", "f": {"coach": -3}}]},
		{"title": "Yatırım teklifi", "text": "Bir tanıdığın bir girişime %s yatırmanı öneriyor. Riskli ama kazandırabilir." % fmt(g), "ch": [{"t": "Riske gir", "f": {"gamble": g}}, {"t": "Hayır, teşekkürler", "f": {}}]},
		{"title": "Transfer söylentisi", "text": "Gazeteler rakip bir kulübün seni istediğini yazıyor. Takım arkadaşların ne diyeceğini merak ediyor.", "ch": [{"t": "%s'de mutluyum" % cm, "f": {"team": 5, "coach": 4, "fans": 5}}, {"t": "Kapıyı aralık bırak", "f": {"fame": 3, "coach": -6, "fans": -4}}]},
		{"title": "Reklam çekimi", "text": "Bir giyim markası tek seferlik bir çekim teklif ediyor.", "ch": [{"t": "Çekime katıl", "f": {"money": int(300 + p.fame * p.fame * 6), "energy": -10, "fame": 1}}, {"t": "Odaklanmalıyım", "f": {"coach": 2}}]},
		{"title": "Gece hayatı", "text": "Arkadaşların seni şehrin en popüler kulübüne çağırıyor.", "ch": [{"t": "Bir gecelik eğlence", "f": {"moral": 12, "energy": -20, "risk": 1}}, {"t": "Evde kal", "f": {}}]},
		{"title": "Bağış kampanyası", "text": "Bir dernek, çocuk hastanesi için destek istiyor.", "ch": [{"t": "%s bağışla" % fmt(don), "f": {"money": -don, "fans": 8, "media": 6, "fame": 2, "moral": 5}}, {"t": "Şimdilik değil", "f": {}}]},
		{"title": "Soyunma odası", "text": "Takımda iki oyuncu tartıştı. Herkes sana bakıyor.", "ch": [{"t": "Arayı bul, takımı topla", "f": {"team": 7, "coach": 4}}, {"t": "Karışmam", "f": {"team": -2}}]},
		{"title": "Oyun yayını", "text": "Popüler bir yayıncı seni canlı yayına davet ediyor.", "ch": [{"t": "Katıl", "f": {"fame": 3, "energy": -6, "moral": 4}}, {"t": "Reddet", "f": {}}]},
	]
	return pick(E)
func apply_fx(f: Dictionary) -> void:
	var p = S.p
	for k in ["coach", "team", "fans", "media"]:
		if f.has(k): p.rel[k] = clamp(p.rel[k] + f[k], 0, 100)
	if f.has("energy"): p.energy = clamp(p.energy + f.energy, 0, 100)
	if f.has("moral"): p.moral = clamp(p.moral + f.moral, 0, 100)
	if f.has("fame"): p.fame = clamp(p.fame + f.fame, 0, 100)
	if f.has("money"):
		p.money += f.money
		if f.money > 0: toast("+" + fmt(f.money))
	if f.has("xp"):
		var a = pick(POS[p.pos].main); add_xp(a, f.xp); toast(AT[a] + " gelişti")
	if f.has("sponsor"):
		p.sponsors.append(f.sponsor); news("%s ile sponsorluk anlaşması imzaladın (haftalık %s)." % [f.sponsor.n, fmt(f.sponsor.w)]); Sfx.play("coin")
	if f.has("gamble"):
		p.money -= f.gamble
		if randf() < .4:
			p.money += f.gamble * 2.4; toast("Yatırım tuttu: +" + fmt(f.gamble * 1.4)); news("Riskli yatırım büyük kazandırdı.")
		else:
			toast("Yatırım battı: -" + fmt(f.gamble)); news("Riskli yatırımda para kaybettin.")
	if f.has("risk") and randf() < .3:
		p.rel.coach = clamp(p.rel.coach - 10, 0, 100); p.rel.media = clamp(p.rel.media - 8, 0, 100); p.fame = clamp(p.fame + 2, 0, 100)
		S.pend.append({"title": "Objektiflere yakalandın", "text": "Gece kulübünden çıkarken fotoğrafların çekildi. Hocan hiç memnun değil.", "ch": [{"t": "Anladım", "f": {}}]})

func add_xp(a: String, amt: float) -> int:
	var p = S.p; var g: float = amt * (1.55 - p.attrs[a] / 100.0)
	if p.age > 30: g *= .7
	elif p.age < 23: g *= 1.2
	p.axp[a] = p.axp.get(a, 0) + g
	var up := 0
	while p.axp[a] >= 100 and p.attrs[a] < 99:
		p.axp[a] -= 100; p.attrs[a] += 1; up += 1
	return up
func gp_cost(v: int) -> int:
	if v < 55: return 1
	if v < 65: return 2
	if v < 74: return 3
	if v < 82: return 4
	if v < 88: return 6
	return 8
func train_base(a: String) -> float:
	var p = S.p; var k := perks()
	return 24.0 * k.train * (0.55 + 0.45 * p.energy / 100.0) * (1.25 if a == "fiz" and p.items.has("chef") else 1.0)

# ---------------- maç ön bilgisi ----------------
func selection(m) -> String:
	var p = S.p
	if p.injury > 0: return "inj"
	if m != null and (m.type == "nat" or m.type == "tour"):
		var d := ovr() - nat_str() + (form_avg() - 6.5) * 3
		return "xi" if d >= -6 else ("sub" if d >= -14 else "out")
	var sc: float = ovr() - my_team().str + (p.rel.coach - 50) / 5.0 + (form_avg() - 6.5) * 3 + (p.moral - 50) / 20.0 + (5 if p.captain else 0)
	return "xi" if sc >= -4 else ("sub" if sc >= -12 else "out")
const SELN := {"xi": ["İlk 11", "g"], "sub": ["Yedek", "y"], "out": ["Kadro dışı", "r"], "inj": ["Sakat", "r"]}
func match_sides(m) -> Dictionary:
	var p = S.p
	if m.type == "nat" or m.type == "tour":
		var on: String = m.get("opp", m.get("natOpp", ""))
		return {"me": {"name": p.nation, "str": nat_str(), "col": "#b91c1c"}, "op": {"name": on, "str": NATS[on], "col": "#1e3a8a"}, "home": m.home}
	return {"me": my_team(), "op": team(m.oppId), "home": m.home}

# ---------------- maç sonucu ----------------
## r: {g,a,rat,played,sel,score_me,score_op,pens,fk,pk,on_minutes}
func apply_match(m: Dictionary, r: Dictionary) -> Dictionary:
	var p = S.p; var played: bool = r.played
	var res := "W" if r.me > r.op else ("L" if r.me < r.op else "D")
	var won: bool = res == "W" or (r.pens != null and r.pens[0] > r.pens[1])
	var rating = null
	if played:
		rating = r.rat + (.3 if res == "W" else (-.3 if res == "L" else 0.0)) + (.45 if p.pos == "DF" and r.op == 0 else 0.0) + (.1 if p.captain else 0.0)
		rating = clamp(round(rating * 10) / 10.0, 3.0, 10.0)
	var motm: bool = played and rating >= 8
	var gp := 0; var bonus := 0; var extra := ""
	if played:
		p.season.apps += 1; p.career.apps += 1; p.season.goals += r.g; p.career.goals += r.g; p.season.assists += r.a; p.career.assists += r.a
		p.season.rsum += rating; p.career.rsum += rating
		if m.type == "lig": p.season.lgoals += r.g
		if m.type == "nat" or m.type == "tour": p.nat.caps += 1; p.nat.goals += r.g
		p.ratings.append(rating)
		if p.ratings.size() > 12: p.ratings.pop_front()
		if motm: p.season.motm += 1; p.career.motm += 1
		gp = max(0, int(round((rating - 5.6) * .9))) + (1 if motm else 0)
		if p.age >= 28: gp = int(gp / 2)
		p.gp += gp
		p.energy = clamp(p.energy - r.minutes * .38, 0, 100)
		p.rel.coach = clamp(p.rel.coach + (rating - 6.4) * 3.2, 0, 100)
		p.rel.fans = clamp(p.rel.fans + r.g * 2 + r.a + (rating - 6.5) * 2, 0, 100)
		if motm: p.rel.media = clamp(p.rel.media + 2, 0, 100)
		var tm: float = .6 if (m.type == "nat" or m.type == "tour") else TIERS[tier()].fm
		p.fame = clamp(p.fame + (r.g * 1.1 + r.a * .6 + (1 if motm else 0)) * tm, 0, 100)
		p.moral = clamp(p.moral + (5 if won else (-5 if res == "L" else 0)) + (rating - 6.5) * 2, 0, 100)
		if r.g >= 3: unlock("hat")
		if rating >= 10: unlock("r10")
		if r.fk: unlock("fk")
		if won and m.type != "nat" and m.type != "tour":
			bonus = int(round(p.wage * .5)); p.money += bonus
		if randf() < (.012 + (.06 if p.energy < 25 else 0.0)) * perks().inj:
			p.injury = RI(1, 5); news("Maçta sakatlandın: %d hafta yoksun." % p.injury)
			S.pend.append({"title": "Sakatlık", "text": "Maçta sakatlandın. Doktorlar %d hafta sahalardan uzak kalacağını söylüyor." % p.injury, "ch": [{"t": "Hızla döneceğim", "f": {"moral": -5}}]})
	else:
		p.energy = clamp(p.energy + 5, 0, 100)
		if r.sel != "inj": p.rel.coach = clamp(p.rel.coach + 1, 0, 100)
	if won: p.rel.team = clamp(p.rel.team + 1.5, 0, 100)
	if m.type == "lig":
		var my := int(p.team); var opid := int(m.oppId)
		var gh: int = r.me if m.home else r.op; var ga: int = r.op if m.home else r.me
		var h := my if m.home else opid; var a := opid if m.home else my
		add_result(h, a, gh, ga)
		S.results.append({"r": int(m.round), "s": "%d-%d" % [gh, ga]})
		star_goals(my, max(0, r.me - r.g)); star_goals(opid, r.op)
		for x in S.fixtures[int(m.round)]:
			if int(x[0]) == my or int(x[1]) == my: continue
			var sc := sim_score(team(x[0]).str, team(x[1]).str)
			add_result(x[0], x[1], sc[0], sc[1]); star_goals(x[0], sc[0]); star_goals(x[1], sc[1])
	if m.type == "cup":
		var rn: String = CUP_WEEKS.get(int(S.week), "")
		if not won:
			S.cup.alive = false; news("%s yolculuğu %s turunda bitti." % [TIERS[tier()].cup, rn])
		elif rn == "Final":
			var n: String = TIERS[tier()].cup
			p.trophies.append("%s %d" % [n, S.year]); unlock("cup")
			if tier() == 0: unlock("ucl")
			extra = n + " şampiyonu oldun!"; news(n + " kazandın."); S.cup.alive = false
	if m.type == "tour":
		if not won:
			S.tour.alive = false; news("Dünya Şampiyonası %s turunda veda ettin." % TOUR_R[int(S.tour.round)])
		elif int(S.tour.round) == 3:
			p.trophies.append("Dünya Şampiyonası %d" % S.year); unlock("wc"); extra = "Dünya şampiyonu oldun!"; news("Dünya şampiyonu oldun."); S.tour.alive = false; p.fame = clamp(p.fame + 12, 0, 100)
		else: S.tour.round += 1
	if won and r.get("pk", false) and r.pens != null: unlock("pen")
	var sd := match_sides(m)
	var desc := "%s %d - %d %s" % [sd.me.name, r.me, r.op, sd.op.name]
	if r.pens != null: desc += " (pen. %d-%d)" % [r.pens[0], r.pens[1]]
	news(m.label.split(",")[0] + ": " + desc + ((", reyting " + r1(rating)) if played else ""))
	check_ach()
	S.wq.pop_front()
	save_game()
	return {"res": res, "won": won, "rating": rating, "gp": gp, "bonus": bonus, "motm": motm, "extra": extra, "desc": desc, "played": played}

func after_match_continue() -> void:
	S.ui.tab = "hub"
	if S.phase == "tour":
		if not S.tour.alive:
			S.phase = "season"; season_end(); return
		end_week(); return
	if S.wq.is_empty(): end_week()
	else:
		save_game(); main.render(); main.show_pending()

# ---------------- sezon sonu ----------------
func season_end() -> void:
	var p = S.p; var t := tier(); var st := sorted_table(); var pos := st.find(int(p.team)) + 1; var s = p.season
	var avg: float = s.rsum / s.apps if s.apps > 0 else 0.0
	var lines := []
	if pos == 1:
		p.trophies.append("%s %d" % [TIERS[t].n, S.year]); unlock("lig"); lines.append("%s şampiyonu oldun!" % TIERS[t].n); p.fame = clamp(p.fame + [8, 5, 3, 2][t], 0, 100)
	elif pos <= 2 and t > 0: lines.append("Takımın %s'e yükseldi." % TIERS[t - 1].n)
	elif pos >= st.size() - 1 and t < 3: lines.append("Takımın küme düştü.")
	var mx := 0
	for i in league_ids(t): mx = max(mx, int(team(i).star.goals))
	if s.lgoals > 0 and s.lgoals >= mx:
		p.awards.append("%s Gol Kralı %d" % [TIERS[t].n, S.year]); unlock("gk"); lines.append("Gol kralı oldun (%d gol)." % s.lgoals)
	if avg >= 7.3 and s.apps >= 12 and (pos <= 4 or s.goals + s.assists >= 15):
		p.awards.append("%s Sezonun Oyuncusu %d" % [TIERS[t].n, S.year]); lines.append("Sezonun oyuncusu seçildin.")
	if p.age <= 21 and avg >= 6.9 and s.apps >= 10:
		p.awards.append("Yılın Genç Oyuncusu %d" % S.year); lines.append("Yılın genç oyuncusu ödülünü aldın.")
	var trY := 0
	for x in p.trophies:
		if str(x).ends_with(str(S.year)): trY += 1
	var bscore: float = s.goals * 1.2 + s.assists * .7 + avg * 6 + (10 if pos == 1 else 0) + trY * 8 + [22, 0, -40, -80][t] + (ovr() - 80) * 1.5
	if t <= 1 and bscore >= 98:
		p.awards.append("Altın Top %d" % S.year); unlock("ball"); lines.append("ALTIN TOP SENİN. Dünyanın en iyi oyuncususun."); p.fame = clamp(p.fame + 10, 0, 100)
	elif t <= 1 and bscore >= 80: lines.append("Altın Top oylamasında ilk 10'a girdin.")
	var tg = p.target; var tv := target_val()
	if tg != null:
		if tv >= tg.v:
			var b: int = p.wage * 8; p.money += b; p.rel.coach = clamp(p.rel.coach + 10, 0, 100); lines.append("Sezon hedefini tutturdun. Prim: +%s" % fmt(b))
		else:
			p.rel.coach = clamp(p.rel.coach - 8, 0, 100); lines.append("Sezon hedefi tutmadı (%s / %s %s)." % [str(tv), str(tg.v), tg.n])
	p.history.append({"y": S.year, "t": my_team().name, "a": s.apps, "g": s.goals, "as": s.assists, "r": r2(avg) if s.apps > 0 else "-", "pos": pos})
	promo_relegate(st, t)
	p.age += 1
	var drop := 0
	if p.age >= 31:
		for a in AK:
			var f: float = (p.age - 30) / 3.0
			var d := int(round(R(.6, 1.8) * f + .4)) if (a == "hiz" or a == "fiz") else int(round(R(0, 1) * f))
			var nv: int = max(25, p.attrs[a] - d); drop += p.attrs[a] - nv; p.attrs[a] = nv
	elif p.age <= 23:
		for i in 2:
			var a = pick(POS[p.pos].main); p.attrs[a] = min(99, p.attrs[a] + 1)
	if drop > 0: lines.append("Yaş ilerliyor: özelliklerin toplam %d puan düştü." % drop)
	var ex := []; var keep := []
	for x in p.sponsors:
		x.s -= 1
		if x.s <= 0: ex.append(x.n)
		else: keep.append(x)
	p.sponsors = keep
	if not ex.is_empty(): lines.append("Biten sponsorluklar: " + ", ".join(ex))
	var was_c: bool = p.captain
	p.captain = p.rel.team >= 75 and p.rel.coach >= 65 and p.age >= 22
	if p.captain and not was_c: lines.append("Yeni sezonda takım kaptanı sensin.")
	p.contract -= 1
	check_ach()
	if p.age >= 40:
		S.offers = []; S.sm = {"ret": true, "lines": lines, "pos": pos}; save_game(); main.show_season(); return
	S.offers = gen_offers(); S.sm = {"lines": lines, "pos": pos}; save_game(); main.show_season()

func wage_for(t: int, o: int) -> int:
	var tr = TIERS[t]; var mid: float = (tr.min + tr.max) / 2.0
	return int(round(tr.wage * pow(1.075, o - mid) * (1 + S.p.fame / 150.0) / 10.0)) * 10
func renewal():
	var p = S.p; var s = p.season; var avg: float = s.rsum / s.apps if s.apps > 0 else 0.0
	if avg >= 6.3 or p.rel.coach >= 45 or (s.apps < 4 and p.age < 20):
		return {"wage": int(round(wage_for(tier(), ovr()) * R(1, 1.15) * perks().agent / 10.0)) * 10, "years": RI(2, 4)}
	return null
func gen_offers() -> Array:
	var p = S.p; var o := ovr()
	var tg := 0 if o >= 79 else (1 if o >= 67 else (2 if o >= 56 else 3))
	var out := []; var used := {int(p.team): true}
	for i in RI(2, 4):
		var t: int = clamp(tg + pick([0, 0, 0, 1, -1, 0]), 0, 3)
		if t < tg and randf() < .6: continue
		var pool := []
		for x in S.teams:
			if x.tier == t and not used.has(int(x.id)): pool.append(x)
		if pool.is_empty(): continue
		var tm = pick(pool); used[int(tm.id)] = true
		var w: int = max(200, int(round(wage_for(t, o) * R(.92, 1.3) * perks().agent / 10.0)) * 10)
		out.append({"team": tm.id, "wage": w, "years": RI(2, 4), "sign": int(round(w * RI(3, 10) / 100.0)) * 100})
	if out.is_empty():
		var t: int = min(3, tg + 1); var pool := []
		for x in S.teams:
			if x.tier == t and int(x.id) != int(p.team): pool.append(x)
		var tm = pick(pool); var w := wage_for(t, o)
		out.append({"team": tm.id, "wage": w, "years": 2, "sign": w * 3})
	out.sort_custom(func(a, b):
		if team(a.team).tier != team(b.team).tier: return team(a.team).tier < team(b.team).tier
		return a.wage > b.wage)
	return out
func accept_offer(i: int) -> void:
	var p = S.p
	if i == -2:
		var r = renewal()
		if r == null: r = {"wage": p.wage, "years": 1}
		p.wage = r.wage; p.contract = r.years; news("%s ile kontratını %d sezon uzattın." % [my_team().name, r.years])
	elif i >= 0:
		var x = S.offers[i]; var old: String = my_team().name
		p.team = int(x.team); p.wage = x.wage; p.contract = x.years; p.money += x.sign; p.rel.coach = 50.0; p.rel.team = 45.0; p.captain = false
		p.clubs.append(team(x.team).name); news("%s'dan %s'a transfer oldun. Haftalık %s." % [old, team(x.team).name, fmt(x.wage)]); Sfx.play("coin")
	new_season()
func promo_relegate(st: Array, t: int) -> void:
	var up := st.slice(0, 2); var dn := st.slice(st.size() - 2)
	if t > 0:
		var above := []
		for x in S.teams:
			if x.tier == t - 1: above.append(x)
		above.sort_custom(func(a, b): return a.str < b.str)
		var go := shuffled(above.slice(0, 4)).slice(0, 2)
		for id in up: team(id).tier = t - 1; team(id).str += 2
		for x in go: x.tier = t; x.str -= 2
	if t < 3:
		var below := []
		for x in S.teams:
			if x.tier == t + 1: below.append(x)
		below.sort_custom(func(a, b): return a.str > b.str)
		var go := shuffled(below.slice(0, 4)).slice(0, 2)
		for id in dn: team(id).tier = t + 1; team(id).str -= 2
		for x in go: x.tier = t; x.str += 2
	for x in S.teams:
		var tr = TIERS[int(x.tier)]
		x.str = clamp(int(x.str) + RI(-2, 2), tr.min - 3, tr.max + 1)
		if randf() < .15: x.star = {"name": gen_name(x.tier == 0), "goals": 0}
func new_season() -> void:
	var p = S.p
	S.sm = null; S.season += 1; S.year += 1; S.week = 1; S.phase = "season"; S.tour = null; S.cup = {"alive": true}; S.pend = []
	init_league(); p.season = zs(); p.energy = 100.0; p.moral = max(p.moral, 62); p.actions = 3; set_target(); nat_check()
	news("Sezon %d başladı. %s, %s." % [S.season, my_team().name, TIERS[tier()].n]); check_ach(); start_week(); S.ui.tab = "hub"; save_game(); main.render(); main.show_pending()
func retire() -> Dictionary:
	var p = S.p; var c = p.career
	var leg: float = c.goals + c.assists * .7 + p.nat.caps * 1.5 + p.trophies.size() * 15 + p.awards.size() * 20 + c.motm * .5
	var title := "Mahalle Efsanesi" if leg < 80 else ("Kulüp Efsanesi" if leg < 250 else ("Ulusal Kahraman" if leg < 500 else ("Dünya Yıldızı" if leg < 900 else "Tüm Zamanların En İyisi")))
	hof_add({"n": p.name, "pos": POS[p.pos].n, "t": title, "g": c.goals, "y": S.year})
	var out := {"name": p.name, "age": p.age, "apps": c.apps, "goals": c.goals, "assists": c.assists, "trophies": p.trophies.size(), "title": title, "leg": int(round(leg))}
	delete_save(); S = null
	return out
