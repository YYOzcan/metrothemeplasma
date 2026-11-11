#include "medya.h"
#include <QFileInfo>
#include <QProcess>
#include <QStandardPaths>

void Medya::sesCal(const QString &ad)
{
    const QString yol = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
        + QStringLiteral("/metrothemeplasma/win/Windows/Media/") + ad + QStringLiteral(".wav");
    if (!QFileInfo::exists(yol))
        return;
    for (const char *p : {"pw-play", "paplay", "aplay"}) {
        const QString exe = QStandardPaths::findExecutable(QLatin1String(p));
        if (!exe.isEmpty()) {
            QProcess::startDetached(exe, {yol});
            return;
        }
    }
}

void Medya::ekranGoruntusu()
{
    QProcess::startDetached(QStringLiteral("spectacle"), {QStringLiteral("-f"), QStringLiteral("-b"), QStringLiteral("-n")});
}
