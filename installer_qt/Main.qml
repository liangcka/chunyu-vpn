import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Qt.labs.platform as Platform

ApplicationWindow {
    id: root
    width: 560
    height: 360
    visible: true
    flags: Qt.FramelessWindowHint | Qt.Window
    color: "transparent"
    title: qsTr("chunyu · vpn 安装")

    property string targetRoot: InstallerOps.appDir()
    property int progressValue: 0
    property string statusText: qsTr("准备就绪")
    property bool installEnabled: true

    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: "#20232a"
        visible: false
    }

    ShaderEffectSource {
        id: blurSource
        anchors.fill: parent
        sourceItem: backdrop
        live: true
        hideSource: false
    }

    Rectangle {
        id: chrome
        anchors.fill: parent
        anchors.margins: 18
        radius: 18
        color: Qt.rgba(1, 1, 1, 0.05)

        FastBlur {
            anchors.fill: parent
            radius: 40
            source: blurSource
            transparentBorder: true
        }

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: Qt.rgba(1, 1, 1, 0.86)
            border.color: Qt.rgba(1, 1, 1, 0.5)
            layer.enabled: true
            layer.samples: 8
        }

        Column {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 18

            InstallHeader {
                width: parent.width
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#e0e0ea"
                opacity: 0.9
            }

            InstallPathSection {
                id: pathSection
                width: parent.width
                pathText: targetRoot
                onPathEdited: {
                    targetRoot = text
                }
                onBrowseClicked: folderDialog.open()
            }

            InstallStatusSection {
                id: statusSection
                width: parent.width
                statusText: root.statusText
                progressValue: root.progressValue
            }

            Item {
                width: parent.width
                height: 1
            }

            InstallActionsSection {
                id: actionsSection
                width: parent.width
                installEnabled: root.installEnabled
                onCancelClicked: Qt.quit()
                onInstallClicked: {
                    root.statusText = qsTr("正在安装…")
                    InstallerOps.copyTo(targetRoot)
                }
            }
        }
    }

    Connections {
        target: InstallerOps
        function onProgressChanged(value) {
            progressValue = Math.max(0, Math.min(100, value))
        }
        function onStatusChanged(text) {
            statusText = text
        }
        function onFinished(ok) {
            statusText = ok ? qsTr("安装完成") : InstallerOps.lastError()
            if (ok) {
                installEnabled = false
            }
        }
    }

    Platform.FolderDialog {
        id: folderDialog
        folder: targetRoot
        onAccepted: {
            if (folder && folder.toString) {
                var url = folder.toString()
                if (url.startsWith("file:///")) {
                    url = decodeURIComponent(url.substring(8))
                }
                targetRoot = url
                pathSection.pathText = targetRoot
            }
        }
    }
}
