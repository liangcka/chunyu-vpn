import QtQuick
import QtQuick.Controls

/* 安装路径选择组件，提供路径输入框与“选择…”按钮。
 * 接口：
 * - property string pathText: 当前显示的安装路径文本
 * - signal pathEdited(string text): 用户修改安装路径时触发
 * - signal browseClicked(): 用户点击“选择…”按钮时触发
 */

Item {
    id: root
    implicitHeight: pathColumn.implicitHeight

    property string pathText: ""

    signal pathEdited(string text)
    signal browseClicked()

    Column {
        id: pathColumn
        width: parent.width
        spacing: 8

        Text {
            text: qsTr("安装位置")
            font.pixelSize: 13
            color: "#333333"
        }

        Row {
            width: parent.width
            spacing: 8

            TextField {
                id: pathField
                selectByMouse: true
                font.pixelSize: 13
                color: "#111111"
                background: Rectangle {
                    radius: 8
                    color: "#fafafa"
                    border.color: "#d1d1dd"
                }
                onTextChanged: root.pathEdited(text)
                Layout.fillWidth: true
            }

            Button {
                id: browseButton
                text: qsTr("选择…")
                implicitWidth: 88
                background: Rectangle {
                    radius: 8
                    color: "#e7e7f0"
                    border.color: "#c0c0d0"
                }
                contentItem: Text {
                    text: browseButton.text
                    font.pixelSize: 13
                    color: "#222222"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.browseClicked()
            }
        }
    }

    Component.onCompleted: {
        pathField.text = pathText
    }

    onPathTextChanged: {
        pathField.text = pathText
    }
}
