// MetroThemePlasma: ilk açılış düzeni — Windows 8.1 görev çubuğu + varsayılan duvar kağıdı
var panel = new Panel("org.kde.panel");
panel.location = "bottom";
panel.height = 40;
panel.floating = false;
panel.hiding = "none";
panel.alignment = "left";

panel.addWidget("io.github.yyozcan.metrobaslat");

var gorevler = panel.addWidget("org.kde.plasma.icontasks");
gorevler.currentConfigGroup = ["General"];
gorevler.writeConfig("groupingStrategy", "1");          // uygulamaya göre grupla (Windows 8)
gorevler.writeConfig("showToolTips", "true");
gorevler.writeConfig("highlightWindows", "false");
gorevler.writeConfig("indicateAudioStreams", "false");
gorevler.writeConfig("middleClickAction", "NewInstance");
gorevler.writeConfig("iconSpacing", "1");
gorevler.writeConfig("maxStripes", "1");
gorevler.writeConfig("fill", "true");
gorevler.writeConfig("launchers", ["applications:org.kde.dolphin.desktop", "applications:firefox.desktop"]);

var tepsi = panel.addWidget("org.kde.plasma.systemtray");
tepsi.currentConfigGroup = ["General"];
// ATP'nin Windows 7 çatalları bu oturumda kendiliğinden eklenmesin
tepsi.writeConfig("knownItems", ["io.gitgud.wackyideas.battery", "io.gitgud.wackyideas.networkmanagement",
    "io.gitgud.wackyideas.volume", "io.gitgud.wackyideas.notifications", "io.gitgud.wackyideas.keyboardlayout",
    "org.kde.plasma.battery", "org.kde.plasma.networkmanagement", "org.kde.plasma.volume",
    "org.kde.plasma.notifications", "org.kde.plasma.keyboardlayout", "org.kde.plasma.devicenotifier",
    "org.kde.plasma.mediacontroller", "org.kde.plasma.clipboard", "org.kde.plasma.bluetooth",
    "org.kde.plasma.printmanager", "org.kde.kdeconnect", "org.kde.plasma.brightness", "org.kde.kscreen",
    "org.kde.plasma.cameraindicator", "org.kde.plasma.manage-inputmethod", "org.kde.plasma.keyboardindicator",
    "org.kde.plasma.weather", "org.kde.plasma.vault", "org.kde.plasma.dwellclicker", "io.github.yyozcan.metrobildirim"]);
// bildirimler: Windows 8 toast'ları (io.github.yyozcan.metrobildirim); derlenmemişse Plasma'nınki
var bildirim = knownWidgetTypes.indexOf("io.github.yyozcan.metrobildirim") >= 0 ? "io.github.yyozcan.metrobildirim" : "org.kde.plasma.notifications";
tepsi.writeConfig("extraItems", ["org.kde.plasma.battery", "org.kde.plasma.networkmanagement", "org.kde.plasma.volume",
    bildirim, "org.kde.plasma.keyboardlayout", "org.kde.plasma.devicenotifier",
    "org.kde.plasma.mediacontroller", "org.kde.plasma.clipboard", "org.kde.plasma.bluetooth",
    "org.kde.plasma.printmanager", "org.kde.kdeconnect"]);
tepsi.writeConfig("hiddenItems", ["org.kde.plasma.clipboard", "org.kde.kdeconnect", "org.kde.plasma.printmanager",
    "org.kde.plasma.mediacontroller", "org.kde.plasma.devicenotifier", "org.kde.plasma.bluetooth"]);

panel.addWidget("io.github.yyozcan.metrosaat");

panel.addWidget("io.github.yyozcan.metromasaustu");

var masaustleri = desktopsForActivity(currentActivity());
for (var j = 0; j < masaustleri.length; j++) {
    var d = masaustleri[j];
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", "file://" + userDataPath() + "/.local/share/wallpapers/Metro-Windows/");
    d.writeConfig("FillMode", "2");
    d.currentConfigGroup = ["General"];
    d.writeConfig("arrangement", "1");
    d.writeConfig("alignment", "0");
    d.writeConfig("iconSize", "2");
}
