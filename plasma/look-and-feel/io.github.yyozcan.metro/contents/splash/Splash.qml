/*
    MetroThemePlasma — oturum açılırken Windows 8.1 "Hoş geldiniz" ekranı:
    Başlangıç zemin renginde dönen noktalar ve "Hoş geldiniz"; Plasma hazır olunca solar
    (ardından metro-kabuk Başlangıç ekranını kutucuklar uçuşarak açar).
*/
import QtQuick
import QtCore

Rectangle {
    id: kok
    color: renk.arkaPlan
    property int stage

    Settings {
        id: renk
        location: StandardPaths.writableLocation(StandardPaths.GenericConfigLocation) + "/metrothemeplasma/ayarlar.ini"
        category: "Renk"
        property string arkaPlan: "#180053"
    }

    // Windows 8.1 LogonUI durum satırı (authui.dll StatusMessageStyle): halka 40×40 rp (üstten 5 rp,
    // sağında 10 rp), yazı 20 pt Segoe UI Light (üstten 4 rp); grup ekranın ortasında
    Row {
        id: icerik
        anchors.centerIn: parent
        spacing: 10
        Item { width: 40; height: 45; IlerlemeHalkasi { y: 5; boyut: 40 } }
        Text {
            topPadding: 4
            text: "Hoş geldiniz"
            color: "white"
            font.family: "Segoe UI"; font.weight: 300; font.pointSize: 20
        }
    }
    onStageChanged: {
        if (stage === 6) bitis.start()
    }
    OpacityAnimator { id: bitis; target: icerik; from: 1; to: 0; duration: 400 }
}
