#ifndef INSTALLER_BACKEND_H
#define INSTALLER_BACKEND_H

#include <QObject>

class InstallerBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString defaultInstallPath READ defaultInstallPath CONSTANT)

public:
    explicit InstallerBackend(QObject *parent = nullptr);

    QString defaultInstallPath() const;

    Q_INVOKABLE void installTo(const QString &targetPath);

signals:
    void installProgressChanged(double value);
    void installFinished(bool ok, const QString &message);

private:
    void performInstall(const QString &targetPath);
    int countFiles(const QString &sourcePath) const;
    bool copyRecursively(const QString &sourcePath, const QString &targetPath, int totalFiles, int &copiedFiles, QString &errorMessage);
};

#endif // INSTALLER_BACKEND_H

