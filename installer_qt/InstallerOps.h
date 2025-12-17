#pragma once

#include <QObject>
#include <QString>

class InstallerOps : public QObject {
    Q_OBJECT
public:
    explicit InstallerOps(QObject* parent = nullptr);

    Q_INVOKABLE QString appDir() const;
    Q_INVOKABLE QString defaultTargetSubdir() const;
    Q_INVOKABLE bool copyTo(const QString& targetRoot);
    Q_INVOKABLE QString lastError() const;

signals:
    void progressChanged(int value);
    void statusChanged(const QString& text);
    void finished(bool ok);
    void lastErrorChanged();

private:
    bool copyTree(const QString& srcDir, const QString& dstDir);
    bool shouldSkip(const QString& path) const;

    QString m_lastError;
};
