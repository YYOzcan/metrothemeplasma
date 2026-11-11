#pragma once
#include <QObject>

// Windows 8.1 sesleri ve ekran görüntüsü
class Medya : public QObject
{
    Q_OBJECT
public:
    using QObject::QObject;
    Q_INVOKABLE void sesCal(const QString &ad);   // "Windows Notify System Generic" vb.
    Q_INVOKABLE void ekranGoruntusu();
};
