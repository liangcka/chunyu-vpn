#include <QApplication>
#include <QQmlApplicationEngine>
#include <QUrl>
#include <QDebug>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    
    QQmlApplicationEngine engine;
    
    // Load our test QML file
    const QUrl url(QStringLiteral("test_custom_window.qml"));
    
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    
    engine.load(url);
    
    return app.exec();
}