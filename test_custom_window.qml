import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: 800
    height: 600
    visible: true
    title: "Custom Window Test"
    
    // 使用无边框窗口以自定义窗口 chrome
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowSystemMenuHint | Qt.WindowMinMaxButtonsHint
    
    Material.theme: Material.Light
    Material.primary: "#4285f4"
    Material.accent: "#4285f4"
    
    // 主题颜色
    property color primaryColor: "#4285f4"
    property color backgroundColor: "#ffffff"
    property color surfaceColor: "#ffffff"
    property color textColor: "#333333"
    property color secondaryTextColor: "#666666"
    property color borderColor: "#e0e0e0"
    
    // 自定义标题栏
    Rectangle {
        id: titleBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 32
        color: surfaceColor
        border.color: borderColor
        border.width: 0
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8
            
            // 应用图标和标题
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                spacing: 8
                
                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    color: primaryColor
                }
                
                Label {
                    text: win.title
                    color: textColor
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    Layout.alignment: Qt.AlignVCenter
                }
            }
            
            // 窗口控制按钮
            RowLayout {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                spacing: 0
                
                // 最小化按钮
                Rectangle {
                    id: minimizeButton
                    width: 28
                    height: 28
                    radius: 6
                    color: "transparent"
                    
                    Rectangle {
                        anchors.centerIn: parent
                        width: 10
                        height: 1
                        color: secondaryTextColor
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.showMinimized()
                        onEntered: minimizeButton.color = Qt.rgba(textColor.r, textColor.g, textColor.b, 0.1)
                        onExited: minimizeButton.color = "transparent"
                    }
                }
                
                // 最大化/还原按钮
                Rectangle {
                    id: maximizeButton
                    width: 28
                    height: 28
                    radius: 6
                    color: "transparent"
                    
                    Rectangle {
                        anchors.centerIn: parent
                        width: 10
                        height: 10
                        border.color: secondaryTextColor
                        border.width: 1
                        color: "transparent"
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (win.visibility === Window.Maximized) {
                                win.showNormal()
                            } else {
                                win.showMaximized()
                            }
                        }
                        onEntered: maximizeButton.color = Qt.rgba(textColor.r, textColor.g, textColor.b, 0.1)
                        onExited: maximizeButton.color = "transparent"
                    }
                }
                
                // 关闭按钮
                Rectangle {
                    id: closeButton
                    width: 28
                    height: 28
                    radius: 6
                    color: "transparent"
                    
                    Image {
                        anchors.centerIn: parent
                        width: 10
                        height: 10
                        source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10 10'><path d='M1 1L9 9M9 1L1 9' stroke='%23" + secondaryTextColor.toString().substring(1) + "' stroke-width='1.5' stroke-linecap='round'/></svg>"
                        smooth: false
                        antialiasing: false
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.quit()
                        onEntered: {
                            closeButton.color = "#ef476f"
                            closeButton.children[0].source = "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10 10'><path d='M1 1L9 9M9 1L1 9' stroke='white' stroke-width='1.5' stroke-linecap='round'/></svg>"
                        }
                        onExited: {
                            closeButton.color = "transparent"
                            closeButton.children[0].source = "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10 10'><path d='M1 1L9 9M9 1L1 9' stroke='%23" + secondaryTextColor.toString().substring(1) + "' stroke-width='1.5' stroke-linecap='round'/></svg>"
                        }
                    }
                }
            }
        }
        
        // 窗口拖动功能
        MouseArea {
            anchors.fill: parent
            property var lastMouseX: 0
            property var lastMouseY: 0
            onPressed: {
                lastMouseX = mouseX
                lastMouseY = mouseY
            }
            onMouseXChanged: {
                if (pressedButtons & Qt.LeftButton) {
                    win.x += mouseX - lastMouseX
                }
            }
            onMouseYChanged: {
                if (pressedButtons & Qt.LeftButton) {
                    win.y += mouseY - lastMouseY
                }
            }
        }
    }

    // 窗口调整大小手柄
    Rectangle {
        id: resizeTop
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 4
        color: "transparent"
        MouseArea {
            anchors.fill: parent
            property var lastMouseY: 0
            onPressed: lastMouseY = mouseY
            onMouseYChanged: {
                if (pressedButtons & Qt.LeftButton) {
                    var delta = mouseY - lastMouseY
                    win.height -= delta
                    win.y += delta
                }
            }
            cursorShape: Qt.SizeVerCursor
        }
    }
    
    Rectangle {
        id: resizeBottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 4
        color: "transparent"
        MouseArea {
            anchors.fill: parent
            property var lastMouseY: 0
            onPressed: lastMouseY = mouseY
            onMouseYChanged: {
                if (pressedButtons & Qt.LeftButton) {
                    win.height += mouseY - lastMouseY
                }
            }
            cursorShape: Qt.SizeVerCursor
        }
    }
    
    Rectangle {
        id: resizeLeft
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: 4
        color: "transparent"
        MouseArea {
            anchors.fill: parent
            property var lastMouseX: 0
            onPressed: lastMouseX = mouseX
            onMouseXChanged: {
                if (pressedButtons & Qt.LeftButton) {
                    var delta = mouseX - lastMouseX
                    win.width -= delta
                    win.x += delta
                }
            }
            cursorShape: Qt.SizeHorCursor
        }
    }
    
    Rectangle {
        id: resizeRight
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 4
        color: "transparent"
        MouseArea {
            anchors.fill: parent
            property var lastMouseX: 0
            onPressed: lastMouseX = mouseX
            onMouseXChanged: {
                if (pressedButtons & Qt.LeftButton) {
                    win.width += mouseX - lastMouseX
                }
            }
            cursorShape: Qt.SizeHorCursor
        }
    }

    // 主内容区域
    Rectangle {
        anchors.top: titleBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: "#f5f5f5"
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20
            
            Label {
                text: "自定义窗口组件测试"
                font.pixelSize: 24
                font.weight: Font.Bold
                color: textColor
                Layout.alignment: Qt.AlignHCenter
            }
            
            Label {
                text: "✅ 无边框窗口\n✅ 自定义标题栏\n✅ 窗口控制按钮（最小化、最大化、关闭）\n✅ 窗口拖动功能\n✅ 窗口调整大小手柄\n✅ 主题适配"
                font.pixelSize: 14
                color: secondaryTextColor
                Layout.alignment: Qt.AlignHCenter
            }
            
            Button {
                text: "切换主题"
                onClicked: {
                    Material.theme = Material.theme === Material.Light ? Material.Dark : Material.Light
                }
                Layout.alignment: Qt.AlignHCenter
            }
            
            Label {
                text: "尝试拖动标题栏或调整窗口边缘大小"
                font.pixelSize: 12
                color: secondaryTextColor
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}