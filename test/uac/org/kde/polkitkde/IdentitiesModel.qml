// sınama: polkit kimlik modeli yerine
import QtQuick
ListModel {
    ListElement { display: "Yiğit Yüksel"; userRole: "unix-user:yigit" }
    function iconForIndex(i) { return "" }
}
