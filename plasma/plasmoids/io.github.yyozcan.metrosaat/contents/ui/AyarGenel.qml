// Saat ayarları: yılı geriden/ileriden gösterme (yalnız görüntü; sistem saati, takvim günleri ve
// dosya tarihleri değişmez)
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_yilKaydir: kaydir.value
    RowLayout {
        Kirigami.FormData.label: "Yılı kaydır:"
        QQC2.SpinBox { id: kaydir; from: -100; to: 100 }
        QQC2.Label { text: "yıl" }
    }
    QQC2.Label {
        Layout.maximumWidth: Kirigami.Units.gridUnit * 24
        wrapMode: Text.WordWrap
        text: "Görev çubuğu saatinde ve takviminde yıl bu kadar kaydırılarak gösterilir (ör. -10: "
              + new Date().getFullYear() + " yerine " + (new Date().getFullYear() + kaydir.value) + "). "
              + "Yalnızca görüntü değişir: sistem saati, günler ve dosya tarihleri olduğu gibi kalır."
        opacity: 0.8
    }
}
