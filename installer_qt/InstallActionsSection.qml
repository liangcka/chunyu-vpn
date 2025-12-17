import QtQuick
import QtQuick.Controls

/* 安装操作按钮区组件，包含“稍后再说”和“安装”按钮。
 * 接口：
 * - property bool installEnabled: 控制“安装”按钮是否可用
 * - signal installClicked(): 用户点击“安装”时触发
 * - signal cancelClicked(): 用户点击“稍后再说”时触发
 */

Item {
    id: root
    implicitHeight: actionsRow.implicitHeight

    property bool installEnabled: true

    signal installClicked()
    signal cancelClicked()

    Row {
        id: actionsRow
        width: parent.width
        spacing: 8
        anchors.horizontalCenter: parent.horizontalCenter

        Item {
            width: 1
            height: 1
        }

        Button {
            id: cancelButton
            text: qsTr("稍后再说")
            implicitWidth: 110
            background: Rectangle {
                radius: 8
                color: "#f4f4f7"
                border.color: "#ccccdd"
            }
            contentItem: Text {
                text: cancelButton.text
                font.pixelSize: 13
                color: "#222222"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: root.cancelClicked()
        }

        Button {
            id: installButton
            text: qsTr("安装")
            implicitWidth: 120
            enabled: root.installEnabled
            background: Rectangle {
                radius: 8
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#4e91ff" }
                    GradientStop { position: 1.0; color: "#2c70ff" }
                }
            }
            contentItem: Text {
                text: installButton.text
                font.pixelSize: 13
                font.weight: Font.Medium
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: root.installClicked()
        }
    }
}
