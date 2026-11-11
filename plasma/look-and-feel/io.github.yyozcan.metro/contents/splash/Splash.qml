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

    Row {
        id: icerik
        anchors.centerIn: parent
        spacing: 18
        IlerlemeHalkasi { anchors.verticalCenter: parent.verticalCenter; boyut: 40 }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Hoş geldiniz"
            color: "white"
            font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 36
        }
    }
    onStageChanged: {
        if (stage === 6) bitis.start()
    }
    OpacityAnimator { id: bitis; target: icerik; from: 1; to: 0; duration: 400 }
}
