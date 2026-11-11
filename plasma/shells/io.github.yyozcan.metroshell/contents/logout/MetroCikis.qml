/*
    MetroThemePlasma — Windows 8.1 oturum kapatma / kapatma ekranı
    Başlat > Güç ya da Win+X'ten gelen istekler onay sormadan Windows 8'in durum ekranını gösterir
    ("Oturum kapatılıyor", "Kapatılıyor", "Yeniden başlatılıyor" + dönen noktalar) ve işlemi başlatır.
    Masaüstünde Alt+F4 gibi genel istek (ShutdownTypeDefault) Windows'un "Windows'u Kapat"
    iletişim kutusunu açar.
*/
import QtQuick
import QtQuick.Controls
import QtCore
import org.kde.plasma.private.sessions as Sessions

Item {
    id: root
    signal logoutRequested()
    signal haltRequested()
    signal haltUpdateRequested()
    signal suspendRequested(int spdMethod)
    signal rebootRequested()
    signal rebootRequested2(int opt)
    signal rebootUpdateRequested()
    signal cancelRequested()
    signal lockScreenRequested()
    signal cancelSoftwareUpdateRequested()
    property real timeout: 30
    property real remainingTime: 30

    Settings {
        id: renk
        location: StandardPaths.writableLocation(StandardPaths.GenericConfigLocation) + "/metrothemeplasma/ayarlar.ini"
        category: "Renk"
        property string arkaPlan: "#180053"
        property string vurgu: "#4617b4"
    }
    Sessions.SessionManagement { id: oturum }

    property string durum: sdtype === ShutdownType.ShutdownTypeNone ? "oturum"
                         : sdtype === ShutdownType.ShutdownTypeHalt ? "kapat"
                         : sdtype === ShutdownType.ShutdownTypeReboot ? "yeniden" : ""
    readonly property string metin: ({ oturum: "Oturum kapatılıyor", kapat: "Kapatılıyor", yeniden: "Yeniden başlatılıyor" })[durum] || ""

    function basla(d) {
        durum = d
        calistir.restart()
    }
    Timer {
        id: calistir
        interval: 900
        running: root.durum !== ""
        onTriggered: {
            if (root.durum === "oturum") oturum.requestLogout(0)
            else if (root.durum === "yeniden") oturum.requestReboot(0)
            else oturum.requestShutdown(0)
            bekci.start()
        }
    }
    Timer { id: bekci; interval: 20000; onTriggered: root.cancelRequested() }

    // durum ekranı
    Rectangle {
        anchors.fill: parent
        visible: root.durum !== ""
        color: renk.arkaPlan
        Row {
            anchors.centerIn: parent
            spacing: 18
            IlerlemeHalkasi { anchors.verticalCenter: parent.verticalCenter; boyut: 40 }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.metin
                color: "white"
                font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 36
            }
        }
    }

    // "Windows'u Kapat" (Alt+F4) iletişim kutusu
    Rectangle {
        anchors.fill: parent
        visible: root.durum === ""
        color: Qt.rgba(0, 0, 0, 0.35)
        MouseArea { anchors.fill: parent }
        Rectangle {
            id: kutu
            anchors.centerIn: parent
            width: 420; height: 236
            color: "#f0f0f0"
            border.color: "#9a9a9a"
            Rectangle {
                id: baslik
                width: parent.width; height: 30
                color: Qt.lighter(renk.vurgu, 1.6)
                Text { anchors.centerIn: parent; text: "Windows'u Kapat"; font.family: "Segoe UI"; font.pixelSize: 15; color: "black" }
            }
            Rectangle {
                y: 30; width: parent.width; height: 74
                color: "white"
                Text {
                    x: 20; anchors.verticalCenter: parent.verticalCenter
                    text: "Windows 8.1"
                    font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 30; color: "#1e74b8"
                }
            }
            Text {
                x: 20; y: 118
                text: "Bilgisayarın ne yapmasını istiyorsunuz?"
                font.family: "Segoe UI"; font.pixelSize: 12
            }
            ComboBox {
                id: secim
                x: 20; y: 140; width: 260; height: 24
                font.family: "Segoe UI"; font.pixelSize: 12
                model: ["Oturumu kapat", "Kullanıcı değiştir", "Uyku", "Kapat", "Yeniden başlat"]
                currentIndex: 3
            }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 12
                anchors.bottom: parent.bottom; anchors.bottomMargin: 12
                spacing: 8
                Button {
                    text: "Tamam"; width: 75; height: 24
                    font.family: "Segoe UI"; font.pixelSize: 12
                    onClicked: {
                        switch (secim.currentIndex) {
                        case 0: root.basla("oturum"); break
                        case 1: oturum.switchUser(); root.cancelRequested(); break
                        case 2: root.suspendRequested(2); break
                        case 3: root.basla("kapat"); break
                        case 4: root.basla("yeniden"); break
                        }
                    }
                }
                Button { text: "İptal"; width: 75; height: 24; font.family: "Segoe UI"; font.pixelSize: 12; onClicked: root.cancelRequested() }
                Button { text: "Yardım"; width: 75; height: 24; font.family: "Segoe UI"; font.pixelSize: 12; enabled: false }
            }
        }
    }
    Keys.onEscapePressed: if (root.durum === "") root.cancelRequested()
}
