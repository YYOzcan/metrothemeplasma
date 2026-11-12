#pragma once
#include <QHash>
#include <QObject>
#include <QVariantMap>

// Windows 8.1 "Otomatik Kullan" (AutoPlay). Çıkarılabilir sürücü / bellek kartı takılınca:
//  - Otomatik Kullan kapalıysa hiçbir şey,
//  - o medya türü için varsayılan eylem seçilmişse doğrudan o eylem,
//  - "Her seferinde bana sor"da toast ("Bu aygıta ne olacağını seçmek için dokunun.", twinui 9991);
//    toast'a tıklanınca QML sağ üstte seçim panelini açar (panelIste), seçilen eylem varsayılan olur.
// Ayarlar: ~/.config/metrothemeplasma/ayarlar.ini [OtomatikKullan] etkin, cikarilabilir, bellekKarti
// (sor | klasor | fotograf | hicbir).
class OtomatikKullan : public QObject
{
    Q_OBJECT
public:
    explicit OtomatikKullan(QObject *parent = nullptr);

    // panelden ya da ayarlardan: aygıtı bağla ve eylemi yap (udi boşsa yol doğrudan kullanılır)
    Q_INVOKABLE void eylemYap(const QString &udi, const QString &yol, const QString &eylem);
    // seçilen eylemi o medya türünün varsayılanı yap
    Q_INVOKABLE void varsayilanYap(const QString &tur, const QString &eylem);
    Q_INVOKABLE bool programVar(const QString &ad) const;

Q_SIGNALS:
    void panelIste(const QVariantMap &aygit);   // udi, yol, ad, simge, tur

private Q_SLOTS:
    void eylem(uint kimlik, const QString &ad);

private:
    void aygitEklendi(const QString &udi);
    QVariantMap aygitBilgisi(const QString &udi) const;
    QHash<uint, QString> m_bildirimler; // bildirim kimliği -> udi
};
