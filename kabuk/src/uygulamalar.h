#pragma once
#include <QAbstractListModel>
#include <QDateTime>
#include <QSet>
#include <QVariantMap>
#include <KService>

// Bütün masaüstü uygulamaları (Başlangıç ekranı, Uygulamalar görünümü, arama)
class Uygulamalar : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int sayi READ sayi NOTIFY sayiDegisti)
    Q_PROPERTY(int yeniSayisi READ yeniSayisi NOTIFY sayiDegisti)
public:
    enum Rol {
        KimlikRol = Qt::UserRole + 1, AdRol, GenelAdRol, AciklamaRol, SimgeRol, KategoriRol,
        HarfRol, KurulumRol, YeniRol, KullanimRol, SiraRol, AnahtarRol
    };
    explicit Uygulamalar(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int sayi() const { return int(m_liste.size()); }
    int yeniSayisi() const;

    Q_INVOKABLE void baslat(const QString &kimlik);
    Q_INVOKABLE void dosyaIleBaslat(const QString &kimlik, const QStringList &urller);
    Q_INVOKABLE void eylemCalistir(const QString &kimlik, const QString &eylem);
    Q_INVOKABLE QVariantList eylemler(const QString &kimlik) const;
    Q_INVOKABLE QVariantMap bilgi(const QString &kimlik) const;
    Q_INVOKABLE bool var(const QString &kimlik) const;
    Q_INVOKABLE void dosyaKonumunuAc(const QString &kimlik);
    Q_INVOKABLE void gorulduIsaretle();
    Q_INVOKABLE QString bul(const QStringList &adaylar) const;   // ilk kurulu olanın kimliği
    Q_INVOKABLE QVariantList ara(const QString &metin, int enFazla = 20) const;
    Q_INVOKABLE QVariantList hepsi() const;

Q_SIGNALS:
    void sayiDegisti();
    void baslatildi(const QString &kimlik);

private:
    struct Kayit {
        KService::Ptr s;
        QString kimlik, ad, harf, kategori, anahtar;
        QDateTime kurulum;
    };
    void yukle();
    void kullanimYukle();
    void kullanimKaydet() const;
    void gorulenYukle();
    QString kategoriBul(const KService::Ptr &s) const;
    const Kayit *kayit(const QString &kimlik) const;

    QList<Kayit> m_liste;
    QHash<QString, int> m_kullanim;
    QSet<QString> m_gorulen;
    bool m_gorulenVar = false;
};
