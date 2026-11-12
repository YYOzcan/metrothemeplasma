"""linux-devmgmt: Türkçe söz dizimi için kaynak dönüşümleri (sözlükten önce çalışır; çalışma dizini = kaynak kopyası).
"on X" -> "X üzerinde", "Battery on X" -> "X pili", "… on GPU" -> "…, GPU üzerinde"."""
import re
from pathlib import Path

for p in Path("src").rglob("*.cpp"):
    s = p.read_text()
    y = re.sub(r'"Battery on " \+ ([\w.]+(?:\(\))?)', r'\1 + " pili"', s)
    y = re.sub(r'(?<![\w"])"on " \+ ([\w.]+(?:\(\))?)', r'\1 + " üzerinde"', y)
    y = re.sub(r'" on " \+ ([\w.]+(?:\(\))?)', r'", " + \1 + " üzerinde"', y)
    if y != s:
        p.write_text(y)

# DeviceOps.cpp: "Could not %1 device" (sözlük: "Aygıt %1") için işlem adı Türkçe edilgen
p = Path("src/model/DeviceOps.cpp")
s = p.read_text()
s = s.replace('blacklist ? "disable" : "enable"', 'blacklist ? "devre dışı bırakılamadı" : "etkinleştirilemedi"')
p.write_text(s)

# Windows kategorileri yerel ada göre alfabetik dizer (Türkçe: Ağ bağdaştırıcıları, Bilgisayar, …)
p = Path("src/scanner/SysfsScanner.cpp")
s = p.read_text()
a = '''    QVector<Device> missing = scanBlacklistedMissing(cats);'''
b = '''    {
        QCollator tr(QLocale(QStringLiteral("tr_TR")));
        std::stable_sort(cats.begin(), cats.end(), [&tr](const DeviceCategory &x, const DeviceCategory &y) {
            return tr.compare(x.name, y.name) < 0;
        });
    }
    QVector<Device> missing = scanBlacklistedMissing(cats);'''
assert a in s
s = s.replace(a, b, 1)
s = "#include <QCollator>\n#include <QLocale>\n#include <algorithm>\n" + s
p.write_text(s)
