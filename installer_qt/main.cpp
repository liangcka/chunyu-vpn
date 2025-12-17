﻿#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDir>

#include "InstallerOps.h"

int main(int argc, char* argv[]) {
    QGuiApplication app(argc, argv);

    InstallerOps ops;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("InstallerOps"), &ops);

    const QDir binDir(QCoreApplication::applicationDirPath());
    const QString mainQml =
        QDir::cleanPath(binDir.absoluteFilePath(QStringLiteral("../../installer_qt/Main.qml")));

    engine.load(QUrl::fromLocalFile(mainQml));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
