#pragma once
#include <QHash>
#include <QObject>

// Windows 8 "Otomatik Kullan" (AutoPlay): çıkarılabilir sürücü takılınca toast gösterir;
// tıklanınca sürücüyü bağlayıp Dosya Gezgini'nde açar. Metin: twinui.dll.mui 9991.
class OtomatikKullan : public QObject
{
    Q_OBJECT
public:
    explicit OtomatikKullan(QObject *parent = nullptr);

private Q_SLOTS:
    void eylem(uint kimlik, const QString &ad);

private:
    void aygitEklendi(const QString &udi);
    QHash<uint, QString> m_bildirimler; // bildirim kimliği -> udi
};
