#include "installer_backend.h"

#include <QCoreApplication>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>

int main(int argc, char *argv[])
{
    QCoreApplication::setOrganizationName(QStringLiteral("chunyuvpn"));
    QCoreApplication::setApplicationName(QStringLiteral("chunyuvpn-installer"));

    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon(QStringLiteral(":/qt/qml/chunyuvpn/qml/ConnectTool/logo.ico")));

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
