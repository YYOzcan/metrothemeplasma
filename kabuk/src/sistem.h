#pragma once
#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QDateTime>

// Kullanıcı bilgisi, güç düğmeleri, kilit, bildirim gizleme, klavye düzeni, komut çalıştırma
class Sistem : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString adSoyad READ adSoyad CONSTANT)
    Q_PROPERTY(QString kullanici READ kullanici CONSTANT)
    Q_PROPERTY(QString avatar READ avatar NOTIFY avatarDegisti)
    Q_PROPERTY(QString bilgisayarAdi READ bilgisayarAdi CONSTANT)
    Q_PROPERTY(bool bildirimGizli READ bildirimGizli NOTIFY bildirimDegisti)
    Q_PROPERTY(QString bildirimBitis READ bildirimBitis NOTIFY bildirimDegisti)
    Q_PROPERTY(QVariantList klavyeDuzenleri READ klavyeDuzenleri NOTIFY klavyeDegisti)
    Q_PROPERTY(int klavyeDuzeni READ klavyeDuzeni NOTIFY klavyeDegisti)
public:
    explicit Sistem(QObject *parent = nullptr);
    QString adSoyad() const;
    QString kullanici() const;
    QString avatar() const;
    QString bilgisayarAdi() const;
    bool bildirimGizli() const { return m_gizlemeCerez != 0; }
    QString bildirimBitis() const;
    QVariantList klavyeDuzenleri() const { return m_duzenler; }
    int klavyeDuzeni() const { return m_duzen; }

    Q_INVOKABLE void kilitle();
    Q_INVOKABLE void oturumuKapat();
    Q_INVOKABLE void kapat();
    Q_INVOKABLE void yenidenBaslat();
    Q_INVOKABLE void uyku();
    Q_INVOKABLE void kullaniciDegistir();
    Q_INVOKABLE void ac(const QString &url);
    Q_INVOKABLE void calistir(const QString &komut);
    Q_INVOKABLE void ayarAc(const QString &modul);           // kcm adı ("" = Sistem Ayarları)
    Q_INVOKABLE void bildirimleriGizle(int saat);            // 0 = yeniden göster
    Q_INVOKABLE void klavyeSec(int i);
    Q_INVOKABLE QString komutCiktisi(const QString &program, const QStringList &arg, int zamanAsimi = 1500) const;
    Q_INVOKABLE bool programVar(const QString &ad) const;

Q_SIGNALS:
    void avatarDegisti();
    void bildirimDegisti();
    void klavyeDegisti();

private Q_SLOTS:
    void klavyeOku();

private:
    uint m_gizlemeCerez = 0;
    QTimer m_gizlemeZamanlayici;
    QDateTime *m_bitis = nullptr;
    QVariantList m_duzenler;
    int m_duzen = 0;
};
