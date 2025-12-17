import QtQuick

/* 安装窗口顶部标题区组件，包含图标、标题与说明文案。
 * 接口：
 * - 无外部属性或信号，仅用于展示静态内容。
 */

Item {
    id: root
    implicitWidth: headerRow.implicitWidth
    implicitHeight: headerRow.implicitHeight

    Row {
        id: headerRow
        width: parent.width
        spacing: 16

        Rectangle {
            width: 72
            height: 72
            radius: 18
            color: "#f3f3f7"
            border.color: "#d0d0dd"

            Image {
                anchors.centerIn: parent
                width: 56
                height: 56
                source: "../qml/ConnectTool/logo.ico"
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Text {
                text: qsTr("安装 chunyu · vpn")
                font.pixelSize: 22
                font.weight: Font.DemiBold
                color: "#111111"
            }

            Text {
                width: parent.width
                text: qsTr("将应用复制到目标磁盘位置。推荐安装到系统盘的应用目录或你常用的软件目录。")
                color: "#555555"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }
        }
    }
}
