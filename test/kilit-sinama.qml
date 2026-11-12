// Kilit ekranı sınama düzeneği: kscreenlocker bağlamını taklit eder (kimlik doğrulama yok).
//   METRO_KILIT=<lockscreen dizini> qml test/kilit-sinama.qml
import QtQuick
import QtQuick.Window

Window {
    id: pencere
    width: 1920; height: 1080
    visible: true
    visibility: Window.FullScreen
    title: "kilit sınaması"
    Item {
        id: root
        anchors.fill: parent
        property bool viewVisible: true
        signal clearPassword()
        property string kscreenlocker_userName: "Yiğit Yüksel"
        property string kscreenlocker_userImage: ""
        property QtObject authenticator: QtObject {
            property bool unlocked: false
            property bool pamTimeout: false
            property bool hadPrompt: false
            signal failed(int kind)
            signal succeeded()
            function startAuthenticating() {}
            function stopAuthenticating() {}
            function respond(parola) { if (parola === "dogru") succeeded(); else failed(0) }
        }
        Loader {
            id: yukleyici
            anchors.fill: parent
            focus: true
            source: "file://" + Qt.application.arguments[Qt.application.arguments.length - 1] + "/MetroKilit.qml"
            onStatusChanged: if (status === Loader.Error) console.log("YÜKLENEMEDİ")
        }
        Timer { interval: 2500; running: true; onTriggered: yukleyici.item.perdeyiKaldir() }
        Timer { interval: 5000; running: true; onTriggered: { yukleyici.item.hata = true } }
    }
}
