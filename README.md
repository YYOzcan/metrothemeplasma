# MetroThemePlasma

Windows 8.1 deneyimi, KDE Plasma 6.8 (Wayland) üzerinde — AeroThemePlasma'dan ilham alınmıştır.
ATP ile yan yana çalışır: SDDM'de **MetroThemePlasma (Wayland)** oturumunu seçince Windows 8.1, diğer
oturumlarda önceki tema (ör. ATP) geri gelir.

Depoda hiçbir Microsoft dosyası yoktur. Bütün görseller, sesler, yazı tipleri ve metinler kurulumda
**senin kendi Windows 8.1 kopyandan** (ISO ya da install.wim) üretilir.

## Neler var

| Bileşen | Kaynak (kendi kopyandan) |
|---|---|
| Başlangıç ekranı: kutucuklar, gruplar, sürükle-bırak, yeniden boyutlandırma, Özelleştir, canlı kutucuklar (Masaüstü, Hava Durumu, Takvim, Fotoğraflar), kullanıcı/güç/ara düğmeleri, açılışta kutucukların uçuşması | twinui.dll, ImmersiveControlPanel |
| 18 Başlangıç arka planı (paralaks katmanlar, dönen öğeler, vurgu rengine göre yeniden boyama) | imageres.dll RCDATA 20200–22100 (sahne biçimi `tools/gen_desen.py`'de çözüldü) |
| Uygulamalar görünümü (ada / yükleme tarihine / kullanıma / kategoriye göre, arama, "Yeni") | — |
| Tılsımlar (Win+C, sağ köşeler), saat paneli, Ara / Paylaş / Aygıtlar / Ayarlar bölmeleri, Kişiselleştir, Kutucuklar, Ağlar, Yansıt | twinui.dll simgeleri, Segoe UI Symbol |
| Hızlı bağlantı menüsü (Win+X) — özgün Türkçe öğeler ve kısayol harfleri | twinui.dll.mui |
| Uygulamalar arasında geçiş (Win+Tab, sol üst köşe), Windows 8.1 Alt+Tab | — |
| Bilgisayar ayarları (kilit ekranı resmi, hesap, köşeler ve kenarlar, Başlangıç renkleri, Renk ve görünüm, Gezinti) | Web/Screen |
| Görev çubuğu: 8.1 Başlat düğmesi, görev düğmeleri, saat (saat/tarih), Masaüstünü göster şeridi | aero.msstyles (TaskBand2Composited8, TaskBar2Composited) |
| Pencere çerçevesi (Aurorae "Metro"; ortalı başlık, DWM düğme atlası), otomatik renklendirme | aero.msstyles DWMWindow atlası |
| Kvantum teması (düğmeler, kaydırma çubukları, sekmeler, menüler …), renk şeması | aero.msstyles |
| Kilit ekranı (perde + saat, oturum açma, "Parola yanlış. Yeniden deneyin.") | authui.dll metinleri, Web/Screen |
| SDDM oturum açma ekranı, "Hoş geldiniz" açılışı, "Oturum kapatılıyor/Kapatılıyor" ekranları, Windows'u Kapat (Alt+F4) | — |
| Plymouth açılış ekranı: Windows logosu + dönen noktalar (WinRT ProgressRing anahtar kareleri) | bootres.dll |
| "Windows 8.1" simge teması, "Windows 8.1 Aero" imleçleri (canlandırmalı), ses teması, duvar kağıtları, Segoe UI | imageres, shell32, pnidui, SndVolSSO, Cursors, Media, Web, Fonts |

## Kurulum

```bash
bash kur.sh --win "/yol/Windows 8.1.iso"   # içe aktar + üret + kullanıcıya kur (sudo gerekmez)
sudo bash kur.sh --sistem                    # SDDM oturum girdisi + oturum açma teması
sudo bash kur.sh --sddm-metro                # SDDM'yi Windows 8.1 oturum açma ekranı yap
sudo bash kur.sh --plymouth                  # açılış ekranı (geri: --plymouth-geri)
```

Sonra oturumu kapatıp SDDM'de **MetroThemePlasma (Wayland)** seç.

Kaldırmak: `bash kur.sh --kaldir` (yazdığı sistem komutlarını da gösterir).

## Kısayollar

Win: Başlangıç · Win+C tılsımlar · Win+Q/S ara · Win+F dosyalarda · Win+W ayarlarda · Win+I Ayarlar ·
Win+K Aygıtlar · Win+H Paylaş · Win+X hızlı bağlantı menüsü · Win+Tab geçiş · Win+PrtSc ekran görüntüsü
(Resimler/Ekran Görüntüleri, ekran kararır) · Win+D masaüstü · Win+E Dosya Gezgini · Ctrl+Esc Başlangıç

## Yapı

- `kabuk/` — **metro-kabuk** (C++/QML): Başlangıç ekranı, tılsımlar, bölmeler, Win+X, geçiş, Bilgisayar ayarları.
  Pencereler wlr-layer-shell yüzeyidir; DBus `io.github.yyozcan.MetroKabuk /Kabuk`.
- `plasma/` — kabuk paketi (düzen, kilit ekranı, kapatma ekranı), görünüm-ve-his (açılış), uygulamacıklar
  (Başlat, saat, Masaüstünü göster).
- `kwin/` — sıcak köşe betiği `metro_koseler`, Alt+Tab `metro_alttab`.
- `tools/` — içe aktarıcı ve üreteçler (`msstyles8.py` Windows 8 derlenmiş msstyles okuyucusu).
- `session/` — oturum betikleri; `metro-profil` tema anahtarlarını yalnızca Metro oturumunda değiştirir,
  `metro-renk` pencere rengini (Renk ve görünüm) uygular.
- `test/` — iç içe, başsız KWin oturumunda ekran görüntüsüyle sınama.
