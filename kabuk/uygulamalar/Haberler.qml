// Windows 8.1 Haberler (Bing Haberler): TRT Haber manşet, dünya, ekonomi, bilim-teknoloji, spor
import QtQuick
HaberUygulamasi {
    baslik: "Haberler"
    renk: "#ae1f23"
    bolumler: [
        { ad: "Manşet", url: "https://www.trthaber.com/manset_articles.rss" },
        { ad: "Türkiye", url: "https://www.trthaber.com/gundem_articles.rss" },
        { ad: "Dünya", url: "https://www.trthaber.com/dunya_articles.rss" },
        { ad: "Ekonomi", url: "https://www.trthaber.com/ekonomi_articles.rss" },
        { ad: "Bilim ve Teknoloji", url: "https://www.trthaber.com/bilim_teknoloji_articles.rss" }
    ]
}
