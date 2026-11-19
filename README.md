# Efsane Yolu

Godot 4.3 ile yazılmış, 2D bir futbol kariyer oyunu. 17 yaşında bölgesel ligde başlıyorsun, hedefin dünyanın en iyisi olmak.

## Oyunda neler var
- **Canlı maç anları:** kuşbakışı sahada 22 oyuncu diziliş, pres, pas ve koşu yapar; top fizikle uçar, kaleci topun yolunu okur. Skor sahada olanlardan çıkar.
- **Oyuncu kontrolü:** top sana gelince zaman yavaşlar. Takım arkadaşının üstüne sürükle: pas. Kalenin içine sürükle: şut (ne kadar yukarı bırakırsan o kadar yüksek, kavisli çizersen falso). Boş yere dokun: topla oraya koş. Stopersen dokunduğun yere koşar, rakibe yaklaşınca üstüne dokunup kayarsın.
- Topu takip eden kamera, radar, gollerin ağır çekim tekrarı.
- Penaltı ve frikikte kale arkası kaydırarak şut ekranı: yön nişanı, uzunluk yüksekliği, hız sertliği belirler; kavisli kaydırırsan top falso alır.
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
- `scripts/match_screen.gd`: maç akışı
- `scripts/pitch.gd`: canlı saha motoru (yapay zekâ, top fiziği, kontrol, tekrar)
- `scripts/shot.gd`: kaydırarak şut mini oyunu
- `scripts/timing.gd`: zamanlama çubuğu
- `scripts/ui.gd`: renkler, yazı tipleri, forma ve arma çizimleri
- `scripts/sfx.gd`: kodla üretilen sesler
- `tests/`: otomatik sezon simülasyonu ve ekran görüntüsü betikleri
