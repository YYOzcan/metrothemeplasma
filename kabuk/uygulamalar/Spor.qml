// Windows 8.1 Spor (Bing Spor): NTV Spor ve TRT Haber spor akışları
import QtQuick
HaberUygulamasi {
    baslik: "Spor"
    renk: "#5c2d91"
    bolumler: [
        { ad: "Spor", url: "https://www.ntvspor.net/rss/anasayfa", kaynak: "NTV Spor" },
        { ad: "Futbol", url: "https://www.ntvspor.net/rss/kategori/futbol", kaynak: "NTV Spor" },
        { ad: "Basketbol", url: "https://www.ntvspor.net/rss/kategori/basketbol", kaynak: "NTV Spor" },
        { ad: "Diğer", url: "https://www.trthaber.com/spor_articles.rss", kaynak: "TRT Haber" }
    ]
}
