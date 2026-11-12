# MetroThemePlasma

Windows 8.1 deneyimi, KDE Plasma 6.8 (Wayland) üzerinde — AeroThemePlasma'dan ilham alınmıştır.
ATP ile yan yana çalışır: SDDM'de **MetroThemePlasma (Wayland)** oturumunu seçince Windows 8.1, diğer
oturumlarda önceki tema (ör. ATP) geri gelir.

Depoda hiçbir Microsoft dosyası yoktur. Bütün görseller, sesler, yazı tipleri ve metinler kurulumda
**senin kendi Windows 8.1 kopyandan** (ISO ya da install.wim) üretilir.

## Neler var

| Bileşen | Kaynak (kendi kopyandan) |
|---|---|
| Başlangıç ekranı: kutucuklar, gruplar, sürükle-bırak, yeniden boyutlandırma, Özelleştir, canlı kutucuklar (Masaüstü, Hava Durumu, Takvim, Fotoğraflar), kullanıcı/güç/ara düğmeleri, semantik yakınlaştırma (Ctrl+tekerlek), yatay kaydırma çubuğu, alt kenarda görev çubuğu (8.1 Update) | twinui.dll, ImmersiveControlPanel |
| Windows 8.1 animasyonları (PVL eğrisi `cubic-bezier(0.1, 0.9, 0.2, 1)`): kutucuklar sütun sütun sağdan gelir, oturum açılışında döner kapı (turnstile), basınca eğilme, Uygulamalar'a dikey geçiş, kutucuktan açılış ekranına büyüme, tılsımlar/bölmeler/sayfa girişi | — |
| 18 Başlangıç arka planı (paralaks katmanlar, dönen öğeler, vurgu rengine göre yeniden boyama) | imageres.dll RCDATA 20200–22100 (sahne biçimi `tools/gen_desen.py`'de çözüldü) |
| Uygulamalar görünümü (ada / yükleme tarihine / kullanıma / kategoriye göre, arama, "Yeni", harf ızgarası) | — |
| Dosya Gezgini'nde "Başlangıç ekranına sabitle" | — |
| Tılsımlar (Win+C, sağ köşeler), saat paneli, Ara / Paylaş / Aygıtlar / Ayarlar bölmeleri, Kişiselleştir, Kutucuklar, Ağlar, Yansıt | twinui.dll simgeleri, Segoe UI Symbol |
| Hızlı bağlantı menüsü (Win+X) — özgün Türkçe öğeler ve kısayol harfleri | twinui.dll.mui |
| Çalıştır iletişim kutusu (Win+R; geçmiş, Gözat, `cmd`/`notepad`/`calc`… karşılıkları), sol altta | shell32.dll.mui |
| Uygulamalar arasında geçiş (Win+Tab, sol üst köşe), Windows 8.1 Alt+Tab | — |
| Bilgisayar ayarları (kilit ekranı resmi, hesap, köşeler ve kenarlar, Başlangıç renkleri, Renk ve görünüm, Gezinti) | Web/Screen |
| Görev çubuğu: 8.1 Başlat düğmesi; görev düğmeleri (ATP SevenTasks çatalı: renk izleyen parıltı, atlama listeleri, görev çubuğu renginde küçük resimler, grup yığını, ilerleme çubukları); Masaüstünü göster şeridi | aero.msstyles (TaskBand2Composited8, TaskBar2Composited) |
| Bildirim alanı (ATP tepsi çatalı): ok solda, gizli simgeler ızgarada + Özelleştir...; ağ simgesi Ağlar bölmesini açar; ses açılır penceresi (dikey kaydırıcı, Karıştırıcı); saat açılır penceresi (ay takvimi, analog saat) | aero.msstyles (TrackBar), timedate.cpl |
| Görev Yöneticisi "daha az ayrıntı" görünümü (Ctrl+Shift+Esc), UAC (ATP aracısı, arka plan kararır), Otomatik Kullan toast'ı | Taskmgr.exe.mui, twinui.dll.mui |
| Toast bildirimleri (sağ üst, Başlangıç renginde, sağ altta uygulama logosu) — ATP'nin bildirim uygulamacığından çatal | — |
| Ses/parlaklık ekran göstergesi (sol üst, vurgu renginde dikey çubuk) | — |
| Pencere çerçevesi (Aurorae "Metro"; ortalı başlık, DWM düğme atlası), otomatik renklendirme | aero.msstyles DWMWindow atlası |
| Kvantum teması (düğmeler, kaydırma çubukları, sekmeler, menüler …), renk şeması | aero.msstyles |
| Kilit ekranı (perde + saat, oturum açma, "Parola yanlış. Yeniden deneyin.") | authui.dll metinleri, Web/Screen |
| SDDM oturum açma ekranı, "Hoş geldiniz" açılışı, "Oturum kapatılıyor/Kapatılıyor" ekranları, Windows'u Kapat (Alt+F4) | — |
| Plymouth açılış ekranı: Windows logosu + dönen noktalar (WinRT ProgressRing anahtar kareleri) | bootres.dll |
| "Windows 8.1" simge teması, "Windows 8.1 Aero" imleçleri (canlandırmalı), ses teması, duvar kağıtları, Segoe UI | imageres, shell32, pnidui, SndVolSSO, Cursors, Media, Web, Fonts |

## Otomatik Kullan

USB bellek ya da bellek kartı takılınca Windows 8.1 toast'u; tıklanınca sağ üstte Başlangıç rengiyle seçim
paneli (Fotoğrafları ve videoları içeri aktar, Dosyaları görüntülemek için klasörü aç, Hiçbir şey yapma).
Seçilen eylem o medya türünün varsayılanı olur. Bilgisayar ayarları > Bilgisayar ve aygıtlar > Otomatik Kullan.

## Kullanıcı Hesabı Denetimi

Yönetici izni isteyen her işlem (pkexec, Dosya Gezgini/Aygıt Yöneticisi/Sistem Ayarları'nın polkit
istekleri) Windows 8.1 Kullanıcı Hesabı Denetimi ile sorulur: ekran kararır, yayımcıya göre mavi
(onaylanmış) ya da sarı (bilinmeyen yayımcı) bant, program adı ve simgesi, "Ayrıntıları göster",
kullanıcı kutucuğu ve parola kutusu, Evet/Hayır. Metinler ve kalkanlar ISO'dan (authui.dll.mui, imageres.dll).

`uac/`, AeroThemePlasma'nın uac-polkit-agent'ının (KDE polkit-kde-agent-1 çatalı, GPL-2.0-or-later)
çatalıdır. Kullanıcı drop-in'i (`~/.config/systemd/user/plasma-polkit-agent.service.d/zz-metrothemeplasma.conf`)
onu yalnızca Metro oturumunda başlatır; diğer oturumlarda ATP'nin ya da KDE'nin aracısı çalışır, ikili
yoksa da KDE'ninkine düşer. Yeni diyalog yüklenemezse Windows 7 diyaloğu açılır.
Görünüm sınaması: `bash test/uac.sh <çıktı> [bilinmeyen] [ayrinti]` (polkit'e dokunmaz).

## Metro uygulamaları

Windows 8.1'in Modern uygulamaları, ortak bir tam ekran ana programla (`metro-uygulama <ad>`, QML).
**Haberler** ve **Spor** (TRT Haber, NTV Spor; canlı kutucuk), **Finans** (TCMB kurları, 30 günlük grafik;
canlı kutucuk), **Müzik** (`~/Müzik`), **Video** (`~/Videolar`), **Kamera** (`Resimler/Film Rulosu`),
**Takvim** (aylık görünüm, etkinlikler, Türkiye resmi tatilleri), **Yardım ve İpuçları**, **Internet Explorer**
(QtWebEngine ile IE11 Modern: alt adres çubuğu, sekme küçük resimleri, InPrivate; "Masaüstünde görüntüle" Falkon'da açar), **Mağaza** (sistemin
paket yükleyicisine kısayol) ve aşağıdakiler:
**Hesap Makinesi** (Standart/Bilimsel), **Alarmlar** (Alarm, Zamanlayıcı, Kronometre; alarmlar uygulama
kapalıyken de metro-kabuk tarafından bildirim + Windows alarm sesiyle çalınır), **Hava Durumu** (7 günlük ve
saatlik tahmin, open-meteo + wttr.in), **Fotoğraflar** (Resimler kitaplığı, tam ekran görüntüleyici, slayt
gösterisi), **Ses Kaydedici** (`~/Belgeler/Ses Kayıtları`).

Hepsinde Windows 8.1 davranışı: kutucuktan açılınca kutucuk büyüyüp açılış ekranına dönüşür, fare üst
kenara gelince 8.1 Update başlık çubuğu iner, üstten aşağı sürükleyince kapanır, sağ tık uygulama çubuğunu
açar. Kutucuk/simge renkleri ve glifler (ISO'daki Segoe UI Symbol) `kabuk/uygulamalar/uygulamalar.json`'da;
uygulamalar yalnızca Metro oturumunda listelenir. Hava, Fotoğraflar ve saat canlı kutucukları bunları açar.

## AeroThemePlasma'dan yükseltme (Windows 7 → 8.1)

**Windows 8.1'e Yükseltme Yardımcısı:** `bash kur.sh --yukselt` (ya da ATP'nin uygulama listesinde
"Windows 8.1'e Yükselt"). Windows 8.1 Kurulumu gibi mor bir sihirbaz: uyumluluk denetimi (eksik araçlar,
ATP bileşenleri), gerekirse kurulum medyası (ISO kendiliğinden bulunur), "Neyi saklamak istiyorsunuz?"
(Windows ayarları + kişisel dosyalar + uygulamalar / yalnızca kişisel dosyalar / hiçbir şey), ek seçenekler
(varsayılan oturum, oturum açma ekranı, açılış ekranı), "Yüklemeye hazır", ilerleme ve bitiş. Root adımları
tek bir Kullanıcı Hesabı Denetimi onayıyla yapılır.

AeroThemePlasma kuruluysa iki tema yan yana yaşar (SDDM'de iki ayrı oturum); MetroThemePlasma ATP'nin
bileşenlerini (SevenTasks motoru `aeroshell.taskmanager`, UAC aracısı, libAeroQt) bulursa kullanır,
bulamazsa Plasma'nın karşılıklarına düşer. İlk Metro oturumunda Windows 7'den 8.1'e yükseltmedeki gibi
kişisel ayarlar taşınır (`metro-yukselt`):

- görev çubuğuna sabitlenen programlar (Windows Gezgini → Dosya Gezgini)
- Başlat menüsüne sabitlenen programlar → Başlangıç ekranında yeni bir kutucuk grubu
- kişisel masaüstü arka planı (Windows 7'nin varsayılan resmiyse Windows 8.1'inki gelir)

`metro-yukselt --dene` ne taşınacağını gösterir; Metro zaten kullanılıyorsa kendiliğinden dokunmaz,
`metro-yukselt --zorla` ile uygulanır (önceki dosyalar `*.yukseltme-oncesi` olarak yedeklenir).
ATP oturumu ve ayarları değişmez.

## Windows uygulamaları (Türkçe, Windows 8.1'e uyarlanmış)

Aşağıdaki açık kaynak projeler `uygulamalar/` altında git alt modülüdür; kurulumda kopyaları
`uygulamalar/yamalar/` ile Windows 8.1'e uyarlanır ve `uygulamalar/ceviri/` sözlükleriyle Türkçeleştirilir
(`tools/uygulama_cevir.py`; saat dilimi adları kendi kopyandaki tzres.dll.mui'den `tools/gen_tz_sozluk.py`):

| Uygulama | Upstream | Uyarlama |
|---|---|---|
| Dosya Gezgini + Denetim Masası (`explorer`, `control`) | [linux-explorer](https://github.com/actuallyaridan/linux-explorer) (actuallyaridan, GPL-3.0) | Windows 8 gezinti satırı (düz ← → ↑, opak), düz komut çubuğu, "Bu Bilgisayar", Windows 8.1 sesleri ve rozeti, Win+E, klasör ilişkilendirmesi |
| Aygıt Yöneticisi (`devmgmt`) | [linux-devmgmt](https://github.com/actuallyaridan/linux-devmgmt) (actuallyaridan, GPL-3.0) | Türkçe kategoriler alfabetik, Türkçe söz dizimi |
| Windows Hakkında (`winver`) | [linver](https://gitgud.io/wackyideas/linver) (WackyIdeas, catpswin56, AGPL-3.0) | varsayılan Windows 8.1; ad, sürüm, telif ve marka görseli kendi kopyandan (basebrd.dll, shell32.dll.mui) |

[linux-control](https://github.com/actuallyaridan/linux-control)'ün Denetim Masası'nın daha yeni hali
linux-explorer'ın içindedir; Windows'taki gibi `control` komutu onu açar.

## Açılış ve kapanış

Windows 7 gibi yumuşak geçişler: oturum açılınca masaüstü siyahtan belirir; kapatırken önce Windows 8.1
"Kapatılıyor" ekranı belirir, ekran siyaha kararır ve Windows logolu kapanış ekranı siyahtan belirir.
Kapanışta metin konsoluna "The system will power off/reboot now!" yazılmaz (`metro-sessiz-kapanis.service`,
logind duyuruları kapalı). Görev çubuğu saatinde yıl isteğe bağlı kaydırılarak gösterilebilir
(sağ tık > Yapılandır > Yılı kaydır; yalnızca görüntü, sistem saati değişmez).

## Kendiliğinden güncelleme

`sudo bash kur.sh --sistem` bir pacman kancası da kurar (`/etc/pacman.d/hooks/91-metro-guncelle.hook`):
Plasma, KWin, Qt, KDE Frameworks, layer-shell-qt, polkit-qt6, libaero-qt gibi Metro'nun derlendiği bir
paket güncellenince MetroThemePlasma yeni sürümlere karşı yeniden derlenip kurulur (AeroThemePlasma'nın
kancasından sonra), sonuç bildirimle haber verilir. Derleme başarısız olursa önceki kurulum olduğu gibi
kalır. Günlük: `/var/log/metro-guncelle.log`; elle: `sudo metro-guncelle-hook --zorla`.

## Kurulum

Gerekenler (Arch/CachyOS; KDE Plasma 6.8 kurulu bir sistemde):

```bash
sudo pacman -S --needed git base-devel cmake ninja extra-cmake-modules python-pillow python-numpy 7zip \
    qt6-base qt6-declarative qt6-multimedia qt6-webengine qt6-wayland layer-shell-qt polkit-qt6 kvantum
```

İsteğe bağlı: AeroThemePlasma (görev çubuğu düğmeleri onun SevenTasks motorunu kullanır; yoksa Plasma'nın
görev çubuğu), AUR'dan `libaero-qt-git` (yoksa Dosya Gezgini yerine Dolphin). Bir Windows 8.1 ISO'su gerekir.

```bash
git clone --recurse-submodules https://github.com/YYOzcan/metrothemeplasma.git
cd metrothemeplasma
bash kur.sh --yukselt                         # grafik Yükseltme Yardımcısı (aşağıdaki adımların hepsini yapar)
```

ya da elle:

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
Win+K Aygıtlar · Win+H Paylaş · Win+X hızlı bağlantı menüsü · Win+R Çalıştır · Win+Tab geçiş · Win+Yukarı/Aşağı ekranı kapla/geri yükle · Win+M hepsini küçült · Ctrl+Shift+Esc Görev Yöneticisi · Win+PrtSc ekran görüntüsü
(Resimler/Ekran Görüntüleri, ekran kararır) · Win+D masaüstü · Win+E Dosya Gezgini · Ctrl+Esc Başlangıç

## Yapı

- `kabuk/` — **metro-kabuk** (C++/QML): Başlangıç ekranı, tılsımlar, bölmeler, Win+X, geçiş, Bilgisayar ayarları.
  Pencereler wlr-layer-shell yüzeyidir; DBus `io.github.yyozcan.MetroKabuk /Kabuk`. systemd kullanıcı hizmeti
  `metro-kabuk.service` (yalnızca Metro oturumunda koşar, çökerse yeniden başlar) ve DBus etkinleştirmesiyle başlar.
- `plasma/bildirim/` — Windows 8 toast bildirimleri (derlenen Plasma uygulamacığı, yalnızca Metro oturumunda
  `QT_PLUGIN_PATH`'te); `plasma/qml/` — ses göstergesi (`org.kde.plasma.workspace.osd` gölgelenir).
- `plasma/` — kabuk paketi (düzen, kilit ekranı, kapatma ekranı), görünüm-ve-his (açılış), uygulamacıklar
  (Başlat, saat, Masaüstünü göster).
- `kwin/` — sıcak köşe betiği `metro_koseler`, Alt+Tab `metro_alttab`.
- `tools/` — içe aktarıcı ve üreteçler (`msstyles8.py` Windows 8 derlenmiş msstyles okuyucusu).
- `session/` — oturum betikleri; `metro-profil` tema anahtarlarını yalnızca Metro oturumunda değiştirir,
  `metro-renk` pencere rengini (Renk ve görünüm) uygular.
- `plasma/tepsi`, `plasma/gorevler` — ATP'nin sistem tepsisi ve SevenTasks çatalları (görev çubuğu için ATP'nin
  `aeroshell.taskmanager` modülü gerekir; yoksa Plasma'nınkiler kullanılır).
- `test/` — iç içe, başsız KWin oturumunda ekran görüntüsüyle sınama; `test/fare.py` gerçek oturumda uinput ile
  fare/klavye sınaması.
