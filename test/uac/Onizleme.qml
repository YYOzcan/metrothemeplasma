// sınama: UAC diyaloğunu polkit olmadan göster (BILINMEYEN=1 pkexec görünümü)
import QtQuick
MetroUac {
    descriptionActionId: Qt.application.arguments.indexOf("bilinmeyen") >= 0 ? "org.freedesktop.policykit.exec" : "org.gnome.gparted"
    descriptionString: Qt.application.arguments.indexOf("bilinmeyen") >= 0 ? "Bir programı başka bir kullanıcı olarak çalıştır" : "GParted Bölüm Düzenleyicisi'ni yönetici olarak çalıştır"
    descriptionVendorName: Qt.application.arguments.indexOf("bilinmeyen") >= 0 ? "The polkit project" : "GParted Projesi"
    descriptionIcon: Qt.application.arguments.indexOf("bilinmeyen") >= 0 ? "" : "gparted"
    ayrintilar: Qt.application.arguments.indexOf("bilinmeyen") >= 0 ? ({ program: "/usr/bin/bash", command_line: "/usr/bin/bash -c 'echo merhaba'" }) : ({})
    ayrintiAcik: Qt.application.arguments.indexOf("ayrinti") >= 0
    Component.onCompleted: goster()
}
