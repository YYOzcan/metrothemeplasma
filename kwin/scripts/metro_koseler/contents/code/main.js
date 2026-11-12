// MetroThemePlasma — Windows 8.1 sıcak köşeleri (metro-kabuk DBus arayüzünü çağırır)
const SERVIS = "io.github.yyozcan.MetroKabuk";
function cagir(yontem) {
    const arg = Array.prototype.slice.call(arguments, 1);
    callDBus.apply(null, [SERVIS, "/Kabuk", SERVIS, yontem].concat(arg));
}
// sağ üst ve sağ alt: tılsım ipucu (simgeler belirir, kenar boyunca inince çubuk açılır)
registerScreenEdge(KWin.ElectricTopRight, function () { cagir("TilsimIpucu", 1); return true; });
registerScreenEdge(KWin.ElectricBottomRight, function () { cagir("TilsimIpucu", 2); return true; });
// sol üst: uygulamalar arasında geçiş
registerScreenEdge(KWin.ElectricTopLeft, function () { cagir("SolUstKose"); return true; });

// Windows 8.1 "Çalıştır" iletişim kutusu (metro-calistir): çalışma alanının sol alt köşesi, görev çubuğunun üstü
function calistirKonumla(w) {
    if (!w || w.resourceClass !== "metro-calistir") return;
    const yerlestir = function () {
        const a = workspace.clientArea(KWin.MaximizeArea, w);
        const g = w.frameGeometry;
        w.frameGeometry = { x: a.x, y: a.y + a.height - g.height, width: g.width, height: g.height };
    };
    yerlestir();
    // ilk boyut sonradan gelebilir
    w.frameGeometryChanged.connect(function () {
        const a = workspace.clientArea(KWin.MaximizeArea, w);
        if (w.frameGeometry.y + w.frameGeometry.height !== a.y + a.height && !w.move) yerlestir();
    });
}
workspace.windowAdded.connect(calistirKonumla);

// Windows 8 pencere kısayolları: Win+Yukarı ekranı kaplar; Win+Aşağı ekranı kaplıyorsa geri yükler, değilse küçültür
function kapliyor(w) {
    const a = workspace.clientArea(KWin.MaximizeArea, w);
    const g = w.frameGeometry;
    return g.width >= a.width && g.height >= a.height;
}
registerShortcut("MetroEkraniKapla", "Windows 8: pencere ekranı kaplasın", "Meta+Up", function () {
    const w = workspace.activeWindow;
    if (w && w.maximizable) w.setMaximize(true, true);
});
registerShortcut("MetroGeriYukleKucult", "Windows 8: geri yükle ya da simge durumuna küçült", "Meta+Down", function () {
    const w = workspace.activeWindow;
    if (!w) return;
    if (w.maximizable && kapliyor(w)) w.setMaximize(false, false);
    else if (w.minimizable) w.minimized = true;
});
