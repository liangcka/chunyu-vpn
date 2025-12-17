#include "installer_backend.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QStandardPaths>

InstallerBackend::InstallerBackend(QObject *parent)
    : QObject(parent)
{
}

QString InstallerBackend::defaultInstallPath() const
{
#if defined(Q_OS_WIN)
    QString base = qEnvironmentVariable("ProgramFiles");
    if (base.isEmpty())
        base = QStringLiteral("C:/Program Files");
    QDir dir(base);
    return dir.filePath(QStringLiteral("chunyuvpn"));
#elif defined(Q_OS_MACOS)
    QDir dir(QStringLiteral("/Applications"));
    return dir.filePath(QStringLiteral("chunyuvpn.app"));
#else
    QDir dir(QStandardPaths::writableLocation(QStandardPaths::HomeLocation));
    return dir.filePath(QStringLiteral("chunyuvpn"));
#endif
}

void InstallerBackend::installTo(const QString &targetPath)
{
    performInstall(targetPath);
}

void InstallerBackend::performInstall(const QString &targetPath)
{
    QString appDir = QCoreApplication::applicationDirPath();
    QDir baseDir(appDir);
    QString sourcePath = baseDir.filePath(QStringLiteral("payload"));

    QDir sourceDir(sourcePath);
    if (!sourceDir.exists()) {
        emit installFinished(false, tr("未找到安装包内容，请确保与安装器同目录下存在 payload 目录"));
        return;
    }

    QString normalizedTarget = QDir::toNativeSeparators(targetPath.trimmed());
    if (normalizedTarget.isEmpty()) {
        emit installFinished(false, tr("安装路径不能为空"));
        return;
    }

    int totalFiles = countFiles(sourcePath);
    if (totalFiles <= 0) {
        emit installFinished(false, tr("安装包内容为空"));
        return;
    }

    int copiedFiles = 0;
    QString errorMessage;

    if (!copyRecursively(sourcePath, normalizedTarget, totalFiles, copiedFiles, errorMessage)) {
        emit installFinished(false, errorMessage);
        return;
    }

    emit installProgressChanged(1.0);
    emit installFinished(true, tr("安装完成"));
}

int InstallerBackend::countFiles(const QString &sourcePath) const
{
    QDir dir(sourcePath);
    if (!dir.exists())
        return 0;

    int count = 0;
    QFileInfoList entries = dir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QFileInfo &info : entries) {
        if (info.isDir()) {
            count += countFiles(info.absoluteFilePath());
        } else if (info.isFile()) {
            count += 1;
        }
    }
    return count;
}

bool InstallerBackend::copyRecursively(const QString &sourcePath, const QString &targetPath, int totalFiles, int &copiedFiles, QString &errorMessage)
{
    QDir sourceDir(sourcePath);
    if (!sourceDir.exists()) {
        errorMessage = tr("源目录不存在: %1").arg(sourcePath);
        return false;
    }

    QDir targetDir(targetPath);
    if (!targetDir.exists()) {
        if (!QDir().mkpath(targetPath)) {
            errorMessage = tr("无法创建目标目录: %1").arg(targetPath);
            return false;
        }
    }

    QFileInfoList entries = sourceDir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QFileInfo &info : entries) {
        QString srcFilePath = info.absoluteFilePath();
        QString dstFilePath = targetDir.filePath(info.fileName());

        if (info.isDir()) {
            if (!copyRecursively(srcFilePath, dstFilePath, totalFiles, copiedFiles, errorMessage))
                return false;
        } else if (info.isFile()) {
            QFile targetFile(dstFilePath);
            if (targetFile.exists()) {
                if (!targetFile.remove()) {
                    errorMessage = tr("无法覆盖文件: %1").arg(dstFilePath);
                    return false;
                }
            }
            if (!QFile::copy(srcFilePath, dstFilePath)) {
                errorMessage = tr("复制文件失败: %1").arg(srcFilePath);
                return false;
            }
            copiedFiles += 1;
            double progress = 0.0;
            if (totalFiles > 0)
                progress = static_cast<double>(copiedFiles) / static_cast<double>(totalFiles);
            emit installProgressChanged(progress);
        }
    }

    return true;
}
