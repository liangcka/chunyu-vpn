#include "installer_backend.h"

#include <QCoreApplication>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QDate>

int main(int argc, char *argv[])
{
    QCoreApplication::setOrganizationName(QStringLiteral("chunyuvpn"));
    QCoreApplication::setApplicationName(QStringLiteral("chunyuvpn-installer"));

    QGuiApplication app(argc, argv);
    const QDate today = QDate::currentDate();
    const QString iconPath =
        (today.month() == 12 && today.day() == 25)
            ? QStringLiteral(":/qt/qml/chunyuvpn/qml/chunyuvpn/logo-Xmas.ico")
            : QStringLiteral(":/qt/qml/chunyuvpn/qml/chunyuvpn/logo.ico");
    app.setWindowIcon(QIcon(iconPath));

    InstallerBackend backend;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("installerBackend"), &backend);

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, []() {
        QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.loadFromModule("ConnectToolInstaller", "InstallerMain");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
