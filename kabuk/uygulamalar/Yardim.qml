// Windows 8.1 Yardım ve İpuçları: yatay panorama; her bölüm büyük bir glif çizimi ve kısa açıklamalar.
import QtQuick

Item {
    id: y
    readonly property string baslik: "Yardım ve İpuçları"
    readonly property color renk: "#00a0b1"
    readonly property color zemin: "#00a0b1"
    readonly property color cubukRengi: "#007b88"
    readonly property var solKomutlar: [{ glif: "", metin: "Ana Sayfa", eylem: function () { kaydir.contentX = 0 } }]
    readonly property var sagKomutlar: []
    readonly property var bolumler: [
        { ad: "Başlangıç ekranı", glif: "", maddeler: [
            ["Başlangıç'a gitme", "Windows tuşuna basın ya da görev çubuğundaki Başlat düğmesine tıklayın."],
            ["Kutucukları düzenleme", "Kutucuğu sürükleyip bırakın. İki grubun arasına bırakırsanız yeni bir grup oluşur."],
            ["Yeniden boyutlandırma", "Kutucuğa sağ tıklayın, Yeniden boyutlandır'ı seçin."],
            ["Grupları adlandırma", "Boş bir alana sağ tıklayıp Özelleştir'i seçin, grubun üstündeki alana bir ad yazın."]] },
        { ad: "Uygulamalar", glif: "", maddeler: [
            ["Tüm uygulamalarınız", "Başlangıç'ın sol altındaki aşağı ok düğmesine tıklayın ya da Ctrl+Sekme'ye basın."],
            ["Uygulama arama", "Başlangıç'tayken yazmaya başlayın; sonuçlar hemen görünür."],
            ["Başlangıç'a sabitleme", "Uygulamalar görünümünde bir uygulamaya sağ tıklayıp Başlangıç ekranına sabitle'yi seçin."],
            ["Uygulamayı kapatma", "Uygulamanın üst kenarından aşağı doğru sürükleyin ya da fareyi üst kenara getirip X'e tıklayın."]] },
        { ad: "Tılsımlar", glif: "", maddeler: [
            ["Tılsımları açma", "Fareyi sağ üst ya da sağ alt köşeye götürün veya Windows+C tuşlarına basın."],
            ["Ara", "Her yerde arama: Windows+S."],
            ["Ayarlar", "Ses, ağ, parlaklık, bildirimler ve güç: Windows+I."],
            ["Aygıtlar ve Paylaş", "Yansıtma ve yazdırma Aygıtlar'da, paylaşma Paylaş'ta."]] },
        { ad: "Masaüstü", glif: "", maddeler: [
            ["Masaüstüne gitme", "Masaüstü kutucuğuna tıklayın ya da Windows+D tuşlarına basın."],
            ["Hızlı bağlantı menüsü", "Başlat düğmesine sağ tıklayın ya da Windows+X'e basın."],
            ["Dosya Gezgini", "Windows+E."],
            ["Uygulamalar arasında geçiş", "Sol üst köşe ya da Windows+Sekme; Alt+Sekme tüm pencereleri gösterir."]] },
        { ad: "Güvenlik ve aygıtlar", glif: "", maddeler: [
            ["Kullanıcı Hesabı Denetimi", "Bilgisayarda değişiklik yapan programlar yönetici parolanızı ister; tanımadığınız programlara izin vermeyin."],
            ["Otomatik Kullan", "USB bellek ya da bellek kartı taktığınızda ne yapılacağını seçin; Bilgisayar ayarları > Otomatik Kullan'dan değiştirebilirsiniz."],
            ["Kilitleme", "Windows+L bilgisayarı kilitler."]] }
    ]

    Flickable {
        id: kaydir
        anchors.fill: parent
        contentWidth: satir.width + 240; contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        MouseArea {
            width: kaydir.contentWidth; height: kaydir.height; acceptedButtons: Qt.NoButton
            onWheel: w => kaydir.contentX = Math.max(0, Math.min(kaydir.contentWidth - kaydir.width, kaydir.contentX - w.angleDelta.y * 1.5))
        }
        Row {
            id: satir
            x: 120; height: kaydir.height; spacing: 100
            Item {
                width: 520; height: parent.height
                Text { y: 50; text: "Yardım ve İpuçları"; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 56 }
                Text { y: 160; text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 220; color: Qt.rgba(1, 1, 1, 0.9) }
                Text { y: 450; width: 480; wrapMode: Text.WordWrap; text: "Windows'u öğrenmenin en hızlı yolu. Sağa kaydırarak temel bilgilere göz atın."; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 24 }
            }
            Repeater {
                model: y.bolumler
                delegate: Item {
                    required property var modelData
                    width: 460; height: parent.height
                    Text { y: 70; text: modelData.ad; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 36 }
                    Rectangle {
                        y: 140; width: 460; height: 170; color: Qt.rgba(0, 0, 0, 0.15)
                        Text { anchors.centerIn: parent; text: modelData.glif; font.family: "Segoe UI Symbol"; font.pixelSize: 100; color: "white" }
                    }
                    Column {
                        y: 335; width: 460; spacing: 16
                        Repeater {
                            model: modelData.maddeler
                            delegate: Column {
                                required property var modelData
                                width: 460; spacing: 2
                                Text { text: modelData[0]; color: "white"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 17 }
                                Text { width: 460; wrapMode: Text.WordWrap; text: modelData[1]; color: Qt.rgba(1, 1, 1, 0.9); font.family: "Segoe UI"; font.pixelSize: 16 }
                            }
                        }
                    }
                }
            }
        }
    }
}
