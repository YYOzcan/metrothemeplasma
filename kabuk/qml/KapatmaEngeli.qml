// Windows 8.1 "uygulamalar kapatmayı engelliyor" ekranı (LogonUI BSDR; authui.dll UIFILE 12403):
// Başlangıç zemin renginde; ortada 480 rp sütun (üstten 71, alttan 116 rp): başlık 20 pt Light
// ("1 uygulama kapatılıyor ve bilgisayar kapatılıyor"), 37 rp boşluk, uygulama listesi (en çok 436 rp;
// satır 41 rp, aralık 19 rp; 32 rp simge, 4 rp iç boşluklu vurgu renkli kare, 1 rp argb(26,255,255,255)
// kenarlık; yanında 10 rp boşlukla ad ve soluk "Bu uygulama, kapatmayı engelliyor."), 44 rp boşluk,
// açıklama, 36 rp boşluk, "Yine de kapat" (sağında 20 rp) ve "İptal". Metinler authui.dll.mui 12300–12320.
import QtQuick
import QtQuick.Window
import org.kde.taskmanager as TaskManager
import org.kde.kirigami as Kirigami

Window {
    id: pen
    property var tema
    property string tur: "kapat"     // kapat | yeniden | oturum
    color: "transparent"
    visible: false
    flags: Qt.FramelessWindowHint
    title: "Kapatma engellendi"
    width: Screen.width; height: Screen.height

    Component.onCompleted: KatmanYardimci.ayarla(pen, 3, 15, 1, -1, "metro-kapatma-engeli")

    function ac(t) {
        tur = t
        visible = true
        requestActivate()
        zemin.forceActiveFocus()
        giris.restart()
    }
    function kapat() { visible = false }

    readonly property var metin: ({
        kapat: { bir: "1 uygulama kapatılıyor ve bilgisayar kapatılıyor", cok: "%d uygulama kapatılıyor ve bilgisayar kapatılıyor",
                 neden: "Bu uygulama, kapatmayı engelliyor.", zorla: "Yine de kapat" },
        oturum: { bir: "1 uygulama ve oturum kapatılıyor", cok: "%d uygulama ve oturum kapatılıyor",
                  neden: "Bu uygulama oturumu kapatmanızı engelliyor.", zorla: "Yine de oturumu kapat" },
        yeniden: { bir: "1 uygulama kapatılıyor ve yeniden başlatılıyor", cok: "%d uygulama kapatılıyor ve yeniden başlatılıyor",
                   neden: "Bu uygulama, yeniden başlatmanızı engelliyor.", zorla: "Yine de yeniden başlat" }
    })[tur]

    // açık kalan pencereler = kapanmayı reddeden uygulamalar (diğerleri kapatma sırasında kapandı)
    TaskManager.TasksModel {
        id: gorevler
        groupMode: TaskManager.TasksModel.GroupApplications
        filterByVirtualDesktop: false
        filterByScreen: false
        filterNotMinimized: false
        sortMode: TaskManager.TasksModel.SortAlpha
    }
    readonly property int sayi: Math.max(1, gorevler.count)

    Rectangle {
        id: zemin
        anchors.fill: parent
        color: pen.tema.arkaPlan
        focus: true
        Keys.onEscapePressed: pen.kapat()
        MouseArea { anchors.fill: parent }

        Column {
            id: sutun
            width: 480
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.max(71, (parent.height - height) / 2)
            transform: Translate { id: kayma }

            Text {
                width: parent.width; wrapMode: Text.WordWrap
                text: pen.sayi === 1 ? pen.metin.bir : pen.metin.cok.replace("%d", pen.sayi)
                color: "white"; font.family: "Segoe UI"; font.weight: 300; font.pointSize: 20
            }
            Item { width: 1; height: 37 }
            ListView {
                id: liste
                width: parent.width
                height: Math.min(436, contentHeight)
                clip: true
                spacing: 19
                interactive: contentHeight > height
                model: gorevler
                delegate: Item {
                    id: og
                    required property var model
                    // metro-kabuk'un kendi pencereleri listelenmez
                    readonly property bool kendi: (og.model.AppId || "") === "metro-kabuk"
                    width: liste.width; height: kendi ? 0 : 41
                    visible: !kendi
                    Rectangle {
                        id: kare
                        y: 1; width: 40; height: 40
                        color: Qt.darker(pen.tema.vurgu, 1.0)
                        border.width: 1; border.color: Qt.rgba(1, 1, 1, 26 / 255)
                        Kirigami.Icon { anchors.centerIn: parent; width: 32; height: 32; source: og.model.decoration }
                    }
                    Column {
                        x: kare.width + 10
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -1
                        width: parent.width - x
                        Text { width: parent.width; elide: Text.ElideRight; text: og.model.AppName || og.model.display || ""
                               color: "white"; font.family: "Segoe UI"; font.weight: 350; font.pointSize: 11 }
                        Text { width: parent.width; elide: Text.ElideRight; text: pen.metin.neden
                               color: Qt.rgba(1, 1, 1, 0.6); font.family: "Segoe UI"; font.weight: 350; font.pointSize: 11 }
                    }
                }
            }
            Item { width: 1; height: 44 }
            Text {
                width: parent.width; wrapMode: Text.WordWrap
                text: "Geri gidip işinizi kaydetmek için, İptal’i tıklatın ve işinizi tamamlayın."
                color: "white"; font.family: "Segoe UI"; font.weight: 350; font.pointSize: 11
            }
            Item { width: 1; height: 36 }
            Row {
                spacing: 20
                Dugme { metin: pen.metin.zorla; onTiklandi: { pen.kapat(); Sistem.zorlaKapat(pen.tur) } }
                Dugme { metin: "İptal"; varsayilan: true; onTiklandi: pen.kapat() }
            }
        }
    }
    NumberAnimation { id: giris; target: kayma; property: "x"; from: 40; to: 0; duration: 500; easing.type: Easing.Bezier; easing.bezierCurve: [0.1, 0.9, 0.2, 1, 1, 1] }

    // Windows 8 koyu tema düğmesi (TouchButton): 2 px beyaz kenarlık, basınca beyaz zemin
    component Dugme: Rectangle {
        id: d
        property string metin
        property bool varsayilan: false
        signal tiklandi()
        width: Math.max(100, dt.implicitWidth + 30); height: 32
        color: dm.pressed ? "white" : (dm.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent")
        border.color: "white"; border.width: 2
        Text { id: dt; anchors.centerIn: parent; text: d.metin; color: dm.pressed ? pen.tema.arkaPlan : "white"
               font.family: "Segoe UI"; font.weight: 600; font.pointSize: 11 }
        MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; onClicked: d.tiklandi() }
        Keys.onReturnPressed: d.tiklandi()
    }
}
