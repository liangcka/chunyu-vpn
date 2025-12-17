#include "InstallerOps.h"

#include <QCoreApplication>
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>

InstallerOps::InstallerOps(QObject* parent)
    : QObject(parent) {
}

QString InstallerOps::appDir() const {
    return QCoreApplication::applicationDirPath();
}

QString InstallerOps::defaultTargetSubdir() const {
    return QStringLiteral("chunyu · vpn");
}

QString InstallerOps::lastError() const {
    return m_lastError;
}

bool InstallerOps::shouldSkip(const QString& path) const {
    const QString base = QFileInfo(path).fileName().toLower();
    if (base == QStringLiteral("chunyu_installer.exe"))
        return true;
    return false;
}

bool InstallerOps::copyTree(const QString& srcDir, const QString& dstDir) {
    QDir dst(dstDir);
    if (!dst.exists()) {
        if (!dst.mkpath(QStringLiteral("."))) {
            m_lastError = QStringLiteral("无法创建目标目录: %1").arg(dstDir);
            emit lastErrorChanged();
            return false;
        }
    }

    QDirIterator it(srcDir, QDir::AllEntries | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);
    int step = 0;
    while (it.hasNext()) {
        it.next();

        const QFileInfo fi = it.fileInfo();
        const QString srcPath = fi.filePath();

        if (shouldSkip(srcPath))
            continue;

        const QString relPath = QDir(srcDir).relativeFilePath(srcPath);
        const QString dstPath = dst.filePath(relPath);

        if (fi.isDir()) {
            QDir d(dstPath);
            if (!d.exists()) {
                if (!dst.mkpath(relPath)) {
                    m_lastError = QStringLiteral("无法创建目录: %1").arg(dstPath);
                    emit lastErrorChanged();
                    return false;
                }
            }
        } else {
            QDir parentDir = QFileInfo(dstPath).dir();
            if (!parentDir.exists()) {
                if (!dst.mkpath(QDir(srcDir).relativeFilePath(parentDir.path()))) {
                    m_lastError = QStringLiteral("无法创建目录: %1").arg(parentDir.path());
                    emit lastErrorChanged();
                    return false;
                }
            }
            if (!QFile::copy(srcPath, dstPath)) {
                m_lastError = QStringLiteral("复制失败: %1 → %2").arg(srcPath, dstPath);
                emit lastErrorChanged();
                return false;
            }
        }

        step += 1;
        if (step % 16 == 0) {
            emit progressChanged(step);
        }
    }

    emit progressChanged(100);
    return true;
}

bool InstallerOps::copyTo(const QString& targetRoot) {
    QString root = targetRoot;
    if (root.isEmpty())
        return false;

    QDir rootDir(root);
    if (!rootDir.exists()) {
        if (!rootDir.mkpath(QStringLiteral("."))) {
            m_lastError = QStringLiteral("无法创建安装根目录: %1").arg(root);
            emit lastErrorChanged();
            emit finished(false);
            return false;
        }
    }

    const QString dstDir = rootDir.filePath(defaultTargetSubdir());
    emit statusChanged(QStringLiteral("正在安装到 %1").arg(dstDir));

    const QString srcDir = appDir();
    const bool ok = copyTree(srcDir, dstDir);
    emit finished(ok);
    return ok;
}

