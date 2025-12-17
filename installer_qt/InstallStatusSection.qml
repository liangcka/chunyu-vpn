import QtQuick

/* 安装状态与进度条组件。
 * 接口：
 * - property string statusText: 状态文本内容
 * - property int progressValue: 进度值，范围 0-100
 */

Item {
    id: root
    implicitHeight: statusColumn.implicitHeight

    property string statusText: qsTr("准备就绪")
    property int progressValue: 0

    Column {
        id: statusColumn
        width: parent.width
        spacing: 6

        Text {
            id: statusLabel
            text: root.statusText
            font.pixelSize: 12
            color: "#666677"
        }

        Rectangle {
            width: parent.width
            height: 6
            radius: 3
            color: "#e5e5f0"

            Rectangle {
                width: parent.width * root.progressValue / 100
                height: parent.height
                radius: 3
                color: "#2680ff"
            }
        }
    }
}
