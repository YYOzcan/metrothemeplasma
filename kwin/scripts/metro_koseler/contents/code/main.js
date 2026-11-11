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
