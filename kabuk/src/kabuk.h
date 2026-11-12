#pragma once
#include <QObject>

class QAction;

// DBus arayüzü (io.github.yyozcan.MetroKabuk /Kabuk) ve Windows 8.1 kısayolları.
// KWin betiği (köşeler) ve panel Başlat düğmesi buradan çağırır; QML sinyalleri dinler.
class Kabuk : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "io.github.yyozcan.MetroKabuk")
public:
    explicit Kabuk(QObject *parent = nullptr);

public Q_SLOTS:
    Q_SCRIPTABLE void Baslangic();                 // aç/kapat (Win)
    Q_SCRIPTABLE void BaslangicAc();
    Q_SCRIPTABLE void BaslangicKapat();
    Q_SCRIPTABLE void Uygulamalar();
    Q_SCRIPTABLE void Tilsimlar();                 // Win+C
    Q_SCRIPTABLE void TilsimIpucu(int kose);       // sağ köşe: 1 üst, 2 alt
    Q_SCRIPTABLE void Ara(const QString &kapsam);  // "" her yerde, "ayarlar", "dosyalar"
    Q_SCRIPTABLE void AraMetin(const QString &metin);  // Ara bölmesini bu metinle aç
    Q_SCRIPTABLE void Ayarlar();
    Q_SCRIPTABLE void Aygitlar();
    Q_SCRIPTABLE void Paylas();
    Q_SCRIPTABLE void GucMenusu(int x, int y);     // Win+X; x<0: Başlat düğmesinin üstü
    Q_SCRIPTABLE void Gecis();                     // Win+Tab / sol üst köşe
    Q_SCRIPTABLE void SolUstKose();
    Q_SCRIPTABLE void SolAltKose();
    Q_SCRIPTABLE void EkranGoruntusu();
    Q_SCRIPTABLE void Kisisellestir();
    Q_SCRIPTABLE void BilgisayarAyarlari(const QString &sayfa);
    Q_SCRIPTABLE void Bolme(const QString &tur);    // aglar, ayarlar, aygitlar, paylas, yansit …
    Q_SCRIPTABLE void BaslangicaSabitle(const QString &yol);  // .desktop yolu ya da kimliği (Dosya Gezgini menüsü)
    Q_SCRIPTABLE bool Calisiyor() const { return true; }      // servis menüsü yalnızca Metro oturumunda görünsün
    Q_SCRIPTABLE void YenidenYukle();
    Q_SCRIPTABLE void IlkOturum();                 // "Merhaba" ilk oturum animasyonunu oynat
    Q_SCRIPTABLE bool BaslangicAcik() const { return m_baslangicAcik; }

    Q_INVOKABLE void setBaslangicAcik(bool a) { m_baslangicAcik = a; }

Q_SIGNALS:
    void baslangicIste(int kip);   // 0 değiştir, 1 aç, 2 kapat, 3 uygulamalar
    void tilsimIste();
    void tilsimIpucuIste(int kose);
    void araIste(const QString &kapsam);
    void ayarlarIste();
    void aygitlarIste();
    void paylasIste();
    void gucMenusuIste(int x, int y);
    void gecisIste();
    void solUstKoseIste();
    void bolmeIste(const QString &tur);
    void sabitleIste(const QString &yol);
    void calistirIste();
    void gezginIste();
    void araMetinIste(const QString &metin);
    void gorevYoneticisiIste();
    void solAltKoseIste();
    void ekranGoruntusuIste();
    void kisisellestirIste();
    void bilgisayarAyarlariIste(const QString &sayfa);
    void yenidenYukleIste();
    void ilkOturumIste();

private:
    QAction *kisayol(const QString &ad, const QString &metin, const QList<QKeySequence> &tuslar, bool zorla = false);
    bool m_baslangicAcik = false;
};
