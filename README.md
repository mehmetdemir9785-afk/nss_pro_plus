# Efsane Yolu

Godot 4.3 ile yazılmış, 2D bir futbol kariyer oyunu. 17 yaşında bölgesel ligde başlıyorsun, hedefin dünyanın en iyisi olmak.

## Oyunda neler var
- Kaydırarak şut: yön nişanı, uzunluk yüksekliği, hız sertliği belirler; kavisli kaydırırsan top falso alır.
- Mevkiye göre maç anları: pas seçimi, çalım, kafa vuruşu, kayarak müdahale, frikik, penaltı.
- 4 lig kademesi, yükselme ve düşme, kupa ve seri penaltılar, milli takım ve iki yılda bir Dünya Şampiyonası.
- Gelişim puanları, mini oyunlu antrenman, enerji, moral, hoca/takım/taraftar/medya ilişkileri.
- Maaş, sponsorlar, ekipman, ev, araba, yatırımlar; sezon sonu transfer teklifleri ve kontratlar.
- Ödüller (gol kralı, sezonun oyuncusu, Altın Top), 24 başarım, yaşlanma, emeklilik ve Efsaneler Salonu.

## APK nasıl alınır
`main` dalına her gönderimde GitHub Actions APK'yı derler ve **Releases** sayfasına koyar. Telefonundan Releases'a girip `efsane-yolu.apk` dosyasını indir ve kur.

Elle derlemek için: Actions sekmesi, "Android APK", **Run workflow**.

## Bilgisayarda çalıştırmak
Godot 4.3'ü indir, bu klasörü proje olarak aç ve F5'e bas.

## Klasörler
- `scripts/game.gd`: oyun kuralları ve kayıt
- `scripts/main.gd`: arayüz ve sekmeler
- `scripts/match_screen.gd`: maç motoru
- `scripts/shot.gd`: kaydırarak şut mini oyunu
- `scripts/timing.gd`: zamanlama çubuğu
- `scripts/ui.gd`: renkler, yazı tipleri, forma ve arma çizimleri
- `scripts/sfx.gd`: kodla üretilen sesler
- `tests/`: otomatik sezon simülasyonu ve ekran görüntüsü betikleri
