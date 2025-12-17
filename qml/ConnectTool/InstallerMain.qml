import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Qt.labs.platform as Platform

ApplicationWindow {
    id: win
    width: 640
    height: 520
    visible: true
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowSystemMenuHint
    color: "transparent"
    title: "chunyuvpn 安装器"

    property string installPath: installerBackend.defaultInstallPath
    property string state: "welcome"
    property string statusText: ""
    property real progressValue: 0
    property bool busy: false

    Material.theme: Material.Light
    Material.primary: "#007aff"
    Material.accent: "#007aff"

    background: Item {
        anchors.fill: parent

        Rectangle {
            id: container
            anchors.centerIn: parent
            width: 580
            height: 440
            radius: 20
            color: "#f9f9fb"
            border.color: "#d0d3da"
            border.width: 1
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                radius: 24
                samples: 32
                color: Qt.rgba(0, 0, 0, 0.18)
                verticalOffset: 12
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                Item {
                    id: titleBar
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Repeater {
                            model: 3
                            Rectangle {
                                width: 12
                                height: 12
                                radius: 6
                                color: index === 0 ? "#ff5f57" : index === 1 ? "#febc2e" : "#28c840"
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        drag.target: win
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    spacing: 16

                    Rectangle {
                        id: iconWrapper
                        width: 96
                        height: 96
                        radius: 24
                        color: "#ffffff"
                        border.color: "#e0e3eb"
                        border.width: 1
                        anchors.verticalCenter: parent.verticalCenter
                        layer.enabled: true
                        layer.effect: DropShadow {
                            transparentBorder: true
                            radius: 16
                            samples: 24
                            color: Qt.rgba(0, 0, 0, 0.12)
                            verticalOffset: 6
                        }

                        Image {
                            anchors.fill: parent
                            anchors.margins: 16
                            fillMode: Image.PreserveAspectFit
                            source: "qrc:/qt/qml/chunyuvpn/qml/ConnectTool/logo.ico"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 8

                        Label {
                            text: "chunyuvpn"
                            font.pixelSize: 22
                            font.weight: Font.DemiBold
                            color: "#111827"
                        }

                        Label {
                            text: state === "welcome"
                                  ? "将 chunyuvpn 安装到你的电脑上"
                                  : state === "installing"
                                    ? "正在安装 chunyuvpn..."
                                    : state === "finished"
                                      ? "安装已完成"
                                      : "安装遇到问题"
                            font.pixelSize: 14
                            color: "#6b7280"
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#e5e7eb"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    Label {
                        text: "安装位置"
                        font.pixelSize: 13
                        color: "#374151"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        TextField {
                            id: pathField
                            Layout.fillWidth: true
                            text: installPath
                            enabled: !busy
                            onTextChanged: installPath = text
                            font.pixelSize: 13
                            background: Rectangle {
                                color: enabled ? "#ffffff" : "#f3f4f6"
                                radius: 8
                                border.color: "#d1d5db"
                                border.width: 1
                            }
                        }

                        Button {
                            id: browseButton
                            text: "选择…"
                            enabled: !busy
                            onClicked: folderDialog.open()
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        spacing: 8

                        ProgressBar {
                            Layout.fillWidth: true
                            visible: state === "installing" || state === "finished" || state === "error"
                            from: 0
                            to: 1
                            value: state === "finished" ? 1 : progressValue
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                Layout.fillWidth: true
                                text: statusText.length > 0 ? statusText : "准备安装 chunyuvpn"
                                font.pixelSize: 12
                                color: "#9ca3af"
                                elide: Text.ElideRight
                            }

                            BusyIndicator {
                                running: busy
                                visible: busy
                                width: 20
                                height: 20
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#e5e7eb"
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40

                    Item {
                        Layout.fillWidth: true
                    }

                    Button {
                        id: cancelButton
                        text: state === "finished" ? "关闭" : "取消"
                        enabled: !busy
                        background: Rectangle {
                            implicitWidth: 90
                            implicitHeight: 28
                            radius: 8
                            color: "transparent"
                            border.color: "#d1d5db"
                            border.width: 1
                        }
                        onClicked: {
                            if (state === "finished")
                                Qt.quit()
                            else
                                Qt.quit()
                        }
                    }

                    Button {
                        id: primaryButton
                        text: state === "welcome" || state === "ready" ? "安装"
                              : state === "installing" ? "正在安装"
                              : state === "finished" ? "完成"
                              : "重试"
                        enabled: !busy && installPath.length > 0 && (state === "welcome" || state === "ready" || state === "error")
                        onClicked: {
                            if (state === "welcome" || state === "ready" || state === "error") {
                                statusText = "正在准备安装..."
                                busy = true
                                state = "installing"
                                progressValue = 0
                                installerBackend.installTo(installPath)
                            } else if (state === "finished") {
                                Qt.quit()
                            }
                        }
                        background: Rectangle {
                            implicitWidth: 110
                            implicitHeight: 28
                            radius: 999
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#4f8cff" }
                                GradientStop { position: 1.0; color: "#0055ff" }
                            }
                        }
                        contentItem: Text {
                            text: primaryButton.text
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
    }

    Platform.FolderDialog {
        id: folderDialog
        title: "选择安装位置"
        onAccepted: {
            if (folder && folder.toString().length > 0) {
                var path = folder.toString()
                if (path.startsWith("file:///"))
                    path = path.substring(8)
                installPath = path
            }
        }
    }

    Connections {
        target: installerBackend
        function onInstallProgressChanged(value) {
            progressValue = value
        }
        function onInstallFinished(ok, message) {
            busy = false
            statusText = message
            if (ok)
                state = "finished"
            else
                state = "error"
        }
    }
}
