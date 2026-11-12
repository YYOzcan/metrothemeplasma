/*  MetroThemePlasma — Windows 8.1 Kullanıcı Hesabı Denetimi (parola istemi).
    AeroThemePlasma'nın uac-polkit-agent'ına (KDE polkit-kde-agent-1 çatalı) dayanır; C++ tarafı aynı
    özellik/sinyal adlarını kullanır: password, identitiesModel, identitiesCurrentIndex, selectedIdentity,
    inlineMessageType/Text, accept(), reject(), userSelected(), request(), authenticationFailure().
    Metinler authui.dll.mui'den (14051, 14053, 14058, 14070, 14082, 14083, 14084, 14085, 14086, 14087,
    14089, 14092, 14094, 14101, 14305, 14311). Arka plan: güvenli masaüstü gibi karartılmış ekran.

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtQuick.Window
import QtCore
import QtMultimedia
import org.kde.polkitkde

Window {
    id: root
    title: "Kullanıcı Hesabı Denetimi"
    flags: Qt.Dialog
    color: "white"
    width: 456
    readonly property int yukseklik: icerik.implicitHeight + alt.height
    height: yukseklik
    minimumWidth: 456; maximumWidth: 456
    minimumHeight: yukseklik; maximumHeight: yukseklik

    property alias password: parola.text
    property IdentitiesModel identitiesModel: IdentitiesModel {}
    property int identitiesCurrentIndex: 0
    readonly property string selectedIdentity: kimlikSurum >= 0 && kimlikler.count > 0 && identitiesCurrentIndex >= 0 && identitiesCurrentIndex < kimlikler.count ? (kimlikler.itemAt(identitiesCurrentIndex) ? kimlikler.itemAt(identitiesCurrentIndex).kimlik : "") : ""
    property bool waitingForAuthentication: false
    property int inlineMessageType: 0
    property string inlineMessageText: ""

    // QuickAuthDialog.cpp'den
    property string mainText
    property string descriptionString
    property string descriptionActionId
    property string descriptionVendorName
    property string descriptionVendorUrl
    property string descriptionIcon
    property var ayrintilar: ({})          // polkit ayrıntıları (program, command_line …)

    signal accept()
    signal reject()
    signal userSelected()
    onSelectedIdentityChanged: userSelected()

    // ------------------------------------------------------------------ yayımcı / program
    // pkexec (org.freedesktop.policykit.exec) ve yayımcısı belirsiz eylemler: sarı "bilinmeyen yayımcı" bandı
    readonly property bool bilinmeyen: descriptionActionId === "org.freedesktop.policykit.exec" || descriptionVendorName === ""
    readonly property string programYolu: ayrintilar["program"] || ""
    readonly property string komutSatiri: ayrintilar["command_line"] || ""
    readonly property string programAdi: {
        if (ayrintilar["programAdi"]) return ayrintilar["programAdi"]
        if (programYolu !== "") return programYolu.split("/").pop()
        return descriptionString !== "" ? descriptionString : "Bilinmeyen program"
    }
    readonly property string programSimge: ayrintilar["programSimge"] || descriptionIcon
    readonly property string yayimci: bilinmeyen ? "Bilinmiyor" : descriptionVendorName

    readonly property string varlik: StandardPaths.writableLocation(StandardPaths.GenericDataLocation) + "/metrothemeplasma/varlik/"

    // ------------------------------------------------------------------ davranış (ATP / KDE ile aynı)
    Shortcut { sequence: StandardKey.Cancel; onActivated: root.reject() }
    function rejectPassword() {
        parola.text = ""
        parola.enabled = true
        parola.forceActiveFocus()
        waitingForAuthentication = false
    }
    function authenticationFailure() {
        hataMetni.text = "Parola yanlış. Yeniden deneyin."
        hataMetni.visible = true
        sarsinti.restart()
        rejectPassword()
    }
    function request() {
        if (parola.text !== "" && waitingForAuthentication) rejectPassword()
    }
    onAccept: {
        waitingForAuthentication = true
        if (parola.text !== "") parola.enabled = false
    }
    onInlineMessageTextChanged: {
        if (inlineMessageText !== "" && inlineMessageType === 3) { hataMetni.text = inlineMessageText; hataMetni.visible = true }
    }
    // güvenli masaüstü: önce karartma, sonra diyalog (diyalog karartmanın geçici çocuğu, hep üstünde kalır)
    function goster() {
        perde.showFullScreen()
        root.transientParent = perde
        root.show()
        root.requestActivate()
        ses.play()
    }
    onVisibleChanged: {
        if (visible) parola.forceActiveFocus()
        else { perde.close(); root.reject() }
    }
    onActiveChanged: if (active) parola.forceActiveFocus()

    MediaPlayer {
        id: ses
        source: StandardPaths.writableLocation(StandardPaths.GenericDataLocation) + "/metrothemeplasma/win/Windows/Media/Windows User Account Control.wav"
        audioOutput: AudioOutput {}
    }

    // karartılmış ekran
    Window {
        id: perde
        title: "metro-uac-perde"
        flags: Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus
        color: "transparent"
        Rectangle {
            id: karartma
            anchors.fill: parent
            color: "black"
            opacity: 0
            NumberAnimation on opacity { running: perde.visible; from: 0; to: 0.55; duration: 250 }
        }
        MouseArea { anchors.fill: parent; onClicked: { root.raise(); root.requestActivate() } }
    }

    // kimlikler (tek yönetici olağan durum; birden çoksa açılır liste)
    property int kimlikSurum: 0
    Repeater {
        id: kimlikler
        model: root.identitiesModel
        onItemAdded: root.kimlikSurum++
        onItemRemoved: root.kimlikSurum++
        delegate: Item {
            required property var model
            required property int index
            readonly property string kimlik: model.userRole || ""
            // Windows yalnızca görünen adı yazar: "Ad Soyad (kullanıcı)" -> "Ad Soyad"
            readonly property string ad: String(model.display || "").replace(/\s*\([^()]*\)$/, "")
        }
    }
    readonly property string kullaniciAdi: (kimlikSurum, kimlikler.itemAt(identitiesCurrentIndex)) ? kimlikler.itemAt(identitiesCurrentIndex).ad : ""

    // ------------------------------------------------------------------ içerik
    Column {
        id: icerik
        width: parent.width
        spacing: 0

        // bant: kalkan + soru
        Rectangle {
            width: parent.width
            height: soru.implicitHeight + 28
            color: root.bilinmeyen ? "#fac026" : "#0e6086"
            Image {
                x: 13; y: 13
                width: 32; height: 32
                source: root.varlik + (root.bilinmeyen ? "uac-bilinmeyen.png" : "uac-kalkan.png")
                sourceSize.width: 32
            }
            Text {
                id: soru
                x: 56; y: 14
                width: parent.width - 70
                wrapMode: Text.WordWrap
                text: root.bilinmeyen
                      ? "Bilinmeyen bir yayımcıya ait aşağıdaki programın bu bilgisayarda değişiklik yapmasına izin vermek istiyor musunuz?"
                      : "Aşağıdaki programın bu bilgisayarda değişiklik yapmasına izin vermek istiyor musunuz?"
                color: root.bilinmeyen ? "black" : "white"
                font.family: "Segoe UI"; font.pixelSize: 16
            }
        }

        // program bilgileri
        Item {
            width: parent.width
            height: bilgi.implicitHeight + 30
            Image {
                x: 56; y: 16
                width: 32; height: 32
                source: root.programSimge !== "" ? (root.programSimge.startsWith("/") ? "file://" + root.programSimge : "image://icon/" + root.programSimge) : root.varlik + "uac-program.png"
                sourceSize.width: 32
                onStatusChanged: if (status === Image.Error) source = root.varlik + "uac-program.png"
            }
            Grid {
                id: bilgi
                x: 100; y: 16
                columns: 2; columnSpacing: 8; rowSpacing: 3
                Text { width: 122; text: "Program adı:"; color: "#000"; font.family: "Segoe UI"; font.pixelSize: 12 }
                Text { width: root.width - 100 - 122 - 8 - 14; text: root.programAdi; elide: Text.ElideMiddle; color: "#000"; font.family: "Segoe UI"; font.pixelSize: 12; font.bold: true }
                Text { width: 122; text: root.bilinmeyen ? "Yayımcı:" : "Onaylanmış yayımcı:"; color: "#000"; font.family: "Segoe UI"; font.pixelSize: 12 }
                Text { width: root.width - 100 - 122 - 8 - 14; text: root.yayimci; elide: Text.ElideRight; color: "#000"; font.family: "Segoe UI"; font.pixelSize: 12; font.bold: !root.bilinmeyen }
                Text { width: 122; text: "Dosya kaynağı:"; color: "#000"; font.family: "Segoe UI"; font.pixelSize: 12 }
                Text { text: "Bu bilgisayardaki sabit sürücü"; color: "#000"; font.family: "Segoe UI"; font.pixelSize: 12 }
                // ayrıntılar açıkken
                Text { visible: root.ayrintiAcik; width: 122; text: root.komutSatiri !== "" ? "Program konumu:" : "Eylem:"; color: "#000"; font.family: "Segoe UI"; font.pixelSize: 12 }
                Text {
                    visible: root.ayrintiAcik; width: root.width - 100 - 122 - 8 - 14; wrapMode: Text.WrapAnywhere
                    text: root.komutSatiri !== "" ? root.komutSatiri : (root.descriptionString + "\n" + root.descriptionActionId)
                    color: "#000"; font.family: "Segoe UI"; font.pixelSize: 12
                }
            }
        }

        Rectangle { x: 13; width: parent.width - 26; height: 1; color: "#dfdfdf" }

        // parola istemi
        Item {
            width: parent.width
            height: istem.implicitHeight + 32
            Column {
                id: istem
                x: 13; y: 14
                width: parent.width - 26
                spacing: 12
                Text {
                    width: parent.width; wrapMode: Text.WordWrap
                    text: "Devam etmek için yönetici parolası yazın ve ardından Evet'i tıklatın."
                    color: "#000"; font.family: "Segoe UI"; font.pixelSize: 12
                }
                Row {
                    x: 30
                    spacing: 12
                    // Windows 8 kullanıcı kutucuğu
                    Rectangle {
                        width: 64; height: 64
                        color: "#e5e5e5"; border.color: "#c3c3c3"
                        Image {
                            anchors.fill: parent; anchors.margins: 1
                            fillMode: Image.PreserveAspectCrop
                            source: {
                                var y = root.identitiesModel && root.identitiesModel.iconForIndex ? root.identitiesModel.iconForIndex(root.identitiesCurrentIndex) : ""
                                return y !== "" ? "file://" + y : root.varlik + "user-200.png"
                            }
                            sourceSize.width: 128
                            onStatusChanged: if (status === Image.Error) source = root.varlik + "user-200.png"
                        }
                    }
                    Column {
                        spacing: 6
                        Row {
                            spacing: 6
                            Text { text: root.kullaniciAdi; color: "#000"; font.family: "Segoe UI"; font.pixelSize: 15 }
                            // birden çok yönetici: değiştir
                            Text {
                                visible: kimlikler.count > 1
                                text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 11; color: "#555"
                                anchors.verticalCenter: parent.verticalCenter
                                MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: root.identitiesCurrentIndex = (root.identitiesCurrentIndex + 1) % kimlikler.count }
                            }
                        }
                        // Windows 8 parola kutusu: göster düğmesiyle
                        Rectangle {
                            id: kutu
                            width: 250; height: 26
                            color: parola.enabled ? "white" : "#f4f4f4"
                            border.color: parola.activeFocus ? "#3399ff" : (km.containsMouse ? "#7eb4ea" : "#ababab")
                            transform: Translate { id: kayma }
                            MouseArea { id: km; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.IBeamCursor; onPressed: parola.forceActiveFocus() }
                            TextInput {
                                id: parola
                                x: 6; width: parent.width - 36; height: parent.height
                                verticalAlignment: TextInput.AlignVCenter
                                echoMode: goz.pressed ? TextInput.Normal : TextInput.Password
                                passwordCharacter: "●"
                                font.family: "Segoe UI"; font.pixelSize: 13
                                clip: true
                                focus: true
                                onAccepted: if (text !== "") root.accept()
                                onTextChanged: if (text !== "") hataMetni.visible = false
                            }
                            Text {
                                visible: parola.text === ""
                                x: 6; anchors.verticalCenter: parent.verticalCenter
                                text: "Parola"; color: "#6d6d6d"; font.family: "Segoe UI"; font.pixelSize: 13; font.italic: false
                            }
                            // göster (göz): basılı tutunca parola görünür
                            Rectangle {
                                visible: parola.text !== ""
                                anchors.right: parent.right; anchors.rightMargin: 1
                                y: 1; width: 28; height: parent.height - 2
                                color: goz.pressed ? "#000000" : (goz.containsMouse ? "#dadada" : "transparent")
                                Text { anchors.centerIn: parent; text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 13; color: goz.pressed ? "white" : "#000" }
                                MouseArea { id: goz; anchors.fill: parent; hoverEnabled: true }
                            }
                            SequentialAnimation {
                                id: sarsinti
                                NumberAnimation { target: kayma; property: "x"; to: -8; duration: 50 }
                                NumberAnimation { target: kayma; property: "x"; to: 8; duration: 80 }
                                NumberAnimation { target: kayma; property: "x"; to: -5; duration: 70 }
                                NumberAnimation { target: kayma; property: "x"; to: 0; duration: 60 }
                            }
                        }
                        Text {
                            id: hataMetni
                            visible: false
                            width: 250; wrapMode: Text.WordWrap
                            color: "#c42b1c"; font.family: "Segoe UI"; font.pixelSize: 12
                        }
                        Text {
                            visible: root.capsLock
                            text: "Caps Lock açık"; color: "#000"; font.family: "Segoe UI"; font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
    property bool ayrintiAcik: false
    property bool capsLock: false

    // ------------------------------------------------------------------ alt şerit: Ayrıntıları göster / Evet / Hayır
    Rectangle {
        id: alt
        anchors.bottom: parent.bottom
        width: parent.width; height: 46
        color: "#f0f0f0"
        Rectangle { width: parent.width; height: 1; color: "#dfdfdf" }
        Row {
            x: 12; anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            Rectangle {
                width: 18; height: 18; radius: 9
                anchors.verticalCenter: parent.verticalCenter
                color: am.containsMouse ? "#e5f3ff" : "transparent"
                border.color: am.containsMouse ? "#3399ff" : "#7a7a7a"
                Canvas {
                    anchors.centerIn: parent; width: 8; height: 5
                    rotation: root.ayrintiAcik ? 180 : 0
                    onPaint: { var c = getContext("2d"); c.reset(); c.strokeStyle = "#333"; c.lineWidth = 1.2
                               c.beginPath(); c.moveTo(0.5, 0.5); c.lineTo(4, 4); c.lineTo(7.5, 0.5); c.stroke() }
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.ayrintiAcik ? "Ayrıntıları gizle" : "Ayrıntıları göster"
                color: am.containsMouse ? "#3399ff" : "#000"
                font.family: "Segoe UI"; font.pixelSize: 12
            }
        }
        MouseArea { id: am; x: 6; width: 150; height: parent.height; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.ayrintiAcik = !root.ayrintiAcik }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Dugme { metin: "Evet"; varsayilan: true; etkin: parola.text !== "" && !root.waitingForAuthentication; onTiklandi: root.accept() }
            Dugme { metin: "Hayır"; onTiklandi: root.reject() }
        }
    }

    // Windows 8 düğmesi (aero.msstyles Button renkleri)
    component Dugme: Rectangle {
        id: d
        property string metin
        property bool varsayilan: false
        property bool etkin: true
        signal tiklandi()
        width: 86; height: 24
        border.color: !etkin ? "#bfbfbf" : (dm.pressed ? "#569de5" : (dm.containsMouse || varsayilan ? "#3c7fb1" : "#acacac"))
        gradient: Gradient {
            GradientStop { position: 0; color: !d.etkin ? "#f4f4f4" : (dm.pressed ? "#daecfc" : (dm.containsMouse ? "#ecf4fc" : "#f0f0f0")) }
            GradientStop { position: 1; color: !d.etkin ? "#f4f4f4" : (dm.pressed ? "#c4e0fc" : (dm.containsMouse ? "#dcecfc" : "#e5e5e5")) }
        }
        Text { anchors.centerIn: parent; text: d.metin; color: d.etkin ? "black" : "#838383"; font.family: "Segoe UI"; font.pixelSize: 12 }
        MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; enabled: d.etkin; onClicked: d.tiklandi() }
    }
}
