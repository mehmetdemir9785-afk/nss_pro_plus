# Efsane Yolu

Godot 4.3 ile yazılmış, 2D bir futbol kariyer oyunu. 17 yaşında bölgesel ligde başlıyorsun, hedefin dünyanın en iyisi olmak.

## Oyunda neler var
- **Canlı maç:** kuşbakışı sahada 22 oyuncu diziliş, pres, pas ve koşu yapar; top fizikle uçar, kaleci topun yolunu okur. Skor sahada olanlardan çıkar.
- **NSS tarzı tek parmak kontrol (top sendeyken):**
  - Basılı tutup sürükle: oyuncun topu parmağının gittiği yere sürer.
  - Hızlı kaydır (fiske): kaleye doğruysa şut, değilse o yöndeki arkadaşına pas, kimse yoksa boşluğa ara pası. Fiske ne kadar hızlıysa o kadar sert.
  - Fiskeyi kavisli çiz: falso. Top havada döner, arkasında iz bırakır.
  - Kısa, hızlı kaydırma: çalım. Yakındaki rakibi geçmeye çalışırsın.
  - Arkadaşına dokun: pas.
  - Sahadayken takımının bütün ataklarında top sana gelince kontrol sende.
- **Stoper kontrolü:** basılı sürükle koş, rakibe dokun müdahale, ona doğru fiske at kayarak gir.
- Takip kamerası, radar, gol tekrarı, tribün ambiyansı.
- Penaltı ve frikikte kale arkası şut ekranı, kafa vuruşunda zamanlama.
- **FC Mobile tarzı arayüz:** oyuncu kartı, ikonlu menüler, eğik gradyan butonlar, cam paneller.
- 4 lig kademesi, kupa ve seri penaltılar, milli takım ve Dünya Şampiyonası, transferler, sponsorlar, yatırımlar, ödüller, 24 başarım, emeklilik.

## Sesleri değiştirmek
`sounds/` klasöründeki bir `.ogg` dosyasını aynı adla değiştir, oyun onu kullanır. Örneğin `crowd_loop.ogg` (tribün ambiyansı, döngü), `goal_roar.ogg` (gol coşkusu), `whistle.ogg`, `kick_shot.ogg`.
Kaynaklar ve lisanslar: `fonts/KAYNAKLAR.txt`.

## APK nasıl alınır
`main` dalına her gönderimde GitHub Actions APK'yı derler ve **Releases** sayfasına koyar. Telefonundan Releases'a girip `efsane-yolu.apk` dosyasını indir ve kur.

Elle derlemek için: Actions sekmesi, "Android APK", **Run workflow**.

## Bilgisayarda çalıştırmak
Godot 4.3'ü indir, bu klasörü proje olarak aç ve F5'e bas.

## Klasörler
- `scripts/game.gd`: oyun kuralları ve kayıt
- `scripts/main.gd`: arayüz ve sekmeler
- `scripts/match_screen.gd`: maç akışı
- `scripts/pitch.gd`: canlı saha motoru (yapay zekâ, top fiziği, dokunma kontrolü, tekrar)
- `sounds/`: ses dosyaları
- `scripts/shot.gd`: kaydırarak şut mini oyunu
- `scripts/timing.gd`: zamanlama çubuğu
- `scripts/ui.gd`: renkler, yazı tipleri, forma ve arma çizimleri
- `scripts/sfx.gd`: kodla üretilen sesler
- `tests/`: otomatik sezon simülasyonu ve ekran görüntüsü betikleri
