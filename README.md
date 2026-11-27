# 📻 Telsiz — internetsiz bas-konuş

Telefonlar aynı Wi-Fi'ye (ya da bir telefonun hotspot'una) bağlanınca internet olmadan birbirleriyle telsiz gibi konuşur.

## APK'yı nasıl alırım (GitHub Actions)
1. GitHub'da yeni bir repo aç (ör. `telsiz`) ve bu klasördeki her şeyi yükle (`.github` klasörü dahil).
2. **Actions** sekmesinde "APK oluştur" kendiliğinden çalışır (çalışmazsa **Run workflow**).
3. Bitince en alttaki **Artifacts** kısmından `Telsiz-apk`'yı indir, zip'i aç, `app-debug.apk`'yı herkesin telefonuna kur.

## Sahada kullanım
1. Bir telefon **hotspot** açar (mobil veri gerekmez, kapalı da olabilir).
2. Diğerleri o Wi-Fi'ye bağlanır; "İnternet yok" uyarısında **Bağlı kal** der.
3. Herkes uygulamayı açar, **aynı kanalı** seçer, adını yazar.
4. Büyük düğmeye **basılı tut → konuş → bırak**. "Eller serbest" modunda dokun-aç / dokun-kapat.

İpuçları
- Menzil hotspot telefonunun Wi-Fi'si kadar: açık alanda ~50–100 m. Hotspot'u ortadaki/yüksekteki kişi açsın.
- Bağlantı sorunu olursa diğer telefonlarda **mobil veriyi kapatın**.
- Uygulama arka planda (ekran kapalıyken) dinlemeye devam eder; bildirimdeki **Kapat** ile tamamen kapanır.
- 16 kanal var; farklı kanaldakiler birbirini duymaz.

## Teknik
- Java, ek kütüphane yok. minSdk 26 (Android 8+).
- Keşif: 1,5 sn'de bir UDP yayını (port 50505). Ses: 16 kHz PCM, 20 ms paketler; kanaldaki kişilere doğrudan gönderilir.
