import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Qt.labs.platform as Platform

ApplicationWindow {
    id: win
    width: 1080
    height: 700
    minimumWidth: 1080
    minimumHeight: 700
    visible: true
    title: qsTr("chunyu · vpn")
    
    // 使用无边框窗口以自定义窗口 chrome
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowSystemMenuHint | Qt.WindowMinMaxButtonsHint

    Material.theme: backend.darkThemeEnabled ? Material.Dark : Material.Light
    Material.primary: "#4285f4"
    Material.accent: "#4285f4"

    property string friendFilter: ""
    property string copyHint: ""
    property string currentPage: "room"
    property var navItems: [
        { key: "room", title: qsTr("房间"), subtitle: qsTr("主持或加入到房间") },
        { key: "lobby", title: qsTr("大厅"), subtitle: qsTr("浏览房间列表") },
        { key: "node", title: qsTr("节点"), subtitle: qsTr("中继延迟与切换") }
    ]

    // 主题颜色管理
    property color primaryColor: backend.darkThemeEnabled ? "#4285f4" : "#1976d2"
    property color backgroundColor: backend.darkThemeEnabled ? "#121212" : "#ffffff"
    property color surfaceColor: backend.darkThemeEnabled ? "#1e1e1e" : "#ffffff"
    property color textColor: backend.darkThemeEnabled ? "#e6efff" : "#333333"
    property color secondaryTextColor: backend.darkThemeEnabled ? "#b0b0b0" : "#666666"
    property color borderColor: backend.darkThemeEnabled ? "#333333" : "#e0e0e0"
    property color hoverColor: backend.darkThemeEnabled ? "#1a365d" : "#e3f2fd"
    property color inputBackgroundColor: backend.darkThemeEnabled ? "#2d2d2d" : "#f5f5f5"
    property color inputBorderColor: backend.darkThemeEnabled ? "#444444" : "#cccccc"
    
    // 特殊高亮颜色（用于置顶消息等）
    property color highlightBackgroundColor: backend.darkThemeEnabled ? "#2b2410" : "#fff8e1"
    property color highlightBorderColor: backend.darkThemeEnabled ? "#eab308" : "#f57f17"
    property color highlightTextColor: backend.darkThemeEnabled ? "#facc15" : "#f57f17"
    property color highlightAccentColor: backend.darkThemeEnabled ? "#facc15" : "#ff8f00"

    function syncStartSwitch() {
        if (!startSwitch) {
            return;
        }
        startSwitch.checked = Qt.binding(() => backend.isHost || backend.isConnected)
    }

    function syncJoinField() {
        if (!joinField) {
            return;
        }
        if (joinField.text !== backend.joinTarget) {
            joinField.text = backend.joinTarget
        }
    }

    function copyBadge(label, value) {
        if (!value || value.length === 0) {
            return;
        }
        backend.copyToClipboard(value);
        win.copyHint = qsTr("%1 已复制").arg(label);
        copyTimer.restart();
    }

    function maskId(value) {
        if (!value) {
            return "";
        }
        var s = String(value);
        if (s.length <= 6) {
            return s;
        }
        var prefix = s.slice(0, 2);
        var suffix = s.slice(-4);
        return prefix + "******" + suffix;
    }

    // 添加透明背景支持
    color: "transparent"
    
    background: Item {
        anchors.fill: parent
        
        Rectangle {
            id: windowBackground
            anchors.fill: parent
            anchors.margins: 8  // 增加边距，确保圆角可见
            color: backgroundColor
            radius: 16  // 标准圆角半径
            
            // 平滑过渡动画
            Behavior on color {
                ColorAnimation { 
                    duration: 300 
                    easing.type: Easing.InOutQuad 
                }
            }
            Behavior on radius {
                NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
            }
            
            // 边框效果
            border.color: Qt.rgba(0, 0, 0, 0.1)
            border.width: 1
            
            // 阴影效果 - 增强视觉深度
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                radius: 12
                samples: 24
                color: Qt.rgba(0, 0, 0, 0.2)
                verticalOffset: 4
            }
        }
    }

    Rectangle {
        id: titleBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8  // 与背景边距保持一致
        height: 32
        color: "transparent"
        border.color: borderColor
        border.width: 0
        
        radius: 0
        
        // 确保标题栏内容不超出圆角
        clip: true
        
        // 平滑过渡动画
        Behavior on color {
            ColorAnimation { duration: 300; easing.type: Easing.InOutQuad }
        }
        Behavior on border.color {
            ColorAnimation { duration: 300; easing.type: Easing.InOutQuad }
        }
        Behavior on radius {
            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
        }
        
        // 简化布局，使用单个RowLayout
        RowLayout {
            anchors.fill: parent
            anchors.margins: 0  // 移除内部边距
            spacing: 8
            
            // 应用图标和标题 - 垂直居中
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                spacing: 8
                
                Item {
                    width: 10
                    Layout.alignment: Qt.AlignVCenter
                }
                
                // 应用图标
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter  // 布局管理的项目使用Layout.alignment
                    width: 16
                    height: 16
                    radius: 8
                    color: primaryColor
                }
                
                // 标题文本 - 垂直居中
                Label {
                    Layout.alignment: Qt.AlignVCenter  // 布局管理的项目使用Layout.alignment
                    text: win.title
                    color: textColor
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    verticalAlignment: Text.AlignVCenter  // 文字垂直居中
                }
                
                // 在标题区域添加不可见的拖动区域
                MouseArea {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    property var lastMouseX: 0
                    property var lastMouseY: 0
                    
                    onPressed: {
                        console.log("Title drag area pressed")
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
            
        // 窗口控制按钮
        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.rightMargin: 8
            spacing: 0
                
                // 在按钮前添加可拖动区域
                MouseArea {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    property var lastMouseX: 0
                    property var lastMouseY: 0
                    
                    onPressed: {
                        console.log("Button area drag pressed")
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
                        onClicked: {
                            console.log("Minimize button clicked")
                            win.showMinimized()
                        }
                        onEntered: minimizeButton.color = Qt.rgba(textColor.r, textColor.g, textColor.b, 0.1)
                        onExited: minimizeButton.color = "transparent"
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
                        onClicked: {
                            console.log("Close button clicked")
                            Qt.quit()
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: backend
        function onAdminPrivilegesRequired() {
            adminDialog.open()
        }
        function onTunStartDenied() {
            startSwitch.checked = false
            syncStartSwitch()
        }
        function onStateChanged() {
            syncStartSwitch()
        }
        function onJoinTargetChanged() {
            syncJoinField()
        }
    }

    Timer {
        id: copyTimer
        interval: 1600
        repeat: false
        onTriggered: win.copyHint = ""
    }

    Platform.FileDialog {
        id: updateDirDialog
        title: qsTr("选择更新保存目录")
        folder: Platform.StandardPaths.writableLocation(Platform.StandardPaths.DownloadLocation)
        fileMode: Platform.FileDialog.SaveFile
        nameFilters: ["*.zip", "*"]
        onAccepted: {
            var url = ""
            if (file) {
                url = file.toString()
            } else if (files && files.length > 0) {
                url = files[0].toString()
            } else if (folder) {
                url = folder.toString()
            }
            if (!url || url.length === 0) {
                return;
            }
            backend.downloadUpdate(downloadSource.currentIndex === 1, url)
        }
    }

    Dialog {
        id: adminDialog
        title: qsTr("需要管理员权限")
        modal: true
        standardButtons: Dialog.Ok
        implicitWidth: 360
        x: (win.width - width) / 2
        y: (win.height - height) / 2
        Overlay.modal: Rectangle {
            anchors.fill: parent
            anchors.margins: 8
            radius: 16
            color: Qt.rgba(0, 0, 0, backend.darkThemeEnabled ? 0.35 : 0.18)
        }
        contentItem: Column {
            spacing: 12
            Label {
                text: qsTr("请使用管理员身份重新打开程序后再尝试启用TUN模式")
                wrapMode: Text.WordWrap
                width: 300
            }
            // TextArea {
            //     width: 300
            //     readOnly: true
            //     text: qsTr("Current input: %1").arg(backend.inputText)
            // }
        }
    }

    Dialog {
        id: aboutDialog
        parent: win
        modal: true
        standardButtons: Dialog.NoButton
        implicitWidth: 420
        x: (win.width - width) / 2
        y: (win.height - height) / 2
        padding: 20
        background: Rectangle {
            radius: 12
            color: surfaceColor
            border.color: borderColor
        }
        Overlay.modal: Rectangle {
            anchors.fill: parent
            anchors.margins: 8
            radius: 16
            color: Qt.rgba(0, 0, 0, backend.darkThemeEnabled ? 0.35 : 0.18)
        }
        contentItem: ColumnLayout {
            spacing: 12
            width: 380
            Label {
                text: qsTr("chunyu · vpn")
                font.pixelSize: 20
                color: textColor
            }
            Label {
                text: qsTr("版本:%1").arg(backend.appVersion)
                color: secondaryTextColor
                font.pixelSize: 16
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                Label {
                    text: qsTr("作者:")
                    color: secondaryTextColor
                    font.pixelSize: 16
                }
                Label {
                    id: authorLink
                    text: "xingyu"
                    color: primaryColor
                    font.pixelSize: 16
                    font.underline: true
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally("https://xingyu.ink")
                    }
                }
            }
            Label {
                text: qsTr("GPL 开源协议")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                color: secondaryTextColor
                font.pixelSize: 15
            }
            Label {
                text: qsTr("感谢使用，本工具仅供个人学习与交流。")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                color: secondaryTextColor
                font.pixelSize: 15
            }
            Item { Layout.fillHeight: true }
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                Button {
                    text: qsTr("确定")
                    onClicked: aboutDialog.close()
                }
            }
        }
    }

    Rectangle {
        id: dimOverlay
        anchors.fill: parent
        anchors.margins: 8
        radius: 16
        color: Qt.rgba(0, 0, 0, 0.35)
        visible: backend.darkThemeEnabled && navDrawer.visible
        z: 0

        MouseArea {
            anchors.fill: parent
            onClicked: navDrawer.close()
        }
    }

    Drawer {
        id: navDrawer
        edge: Qt.LeftEdge
        width: Math.min(win.width * 0.6, 300)
        height: win.height
        modal: false
        interactive: true

        background: Rectangle {
            anchors.fill: parent
            anchors.margins: 8
            color: surfaceColor
            border.color: borderColor
            radius: 12
            clip: true
            Behavior on color {
                ColorAnimation { 
                    duration: 300 
                    easing.type: Easing.InOutQuad 
                }
            }
            Behavior on border.color {
                ColorAnimation { 
                    duration: 300 
                    easing.type: Easing.InOutQuad 
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Label {
                text: qsTr("chunyu·vpn")
                color: textColor
                font.pixelSize: 18
            }

            Repeater {
                model: win.navItems
                delegate: Rectangle {
                    required property string key
                    required property string title
                    required property string subtitle
                    Layout.fillWidth: true
                    radius: 10
                    implicitHeight: 56
                    color: win.currentPage === key ? hoverColor : "transparent"
                    border.color: win.currentPage === key ? primaryColor : borderColor
                    Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.InOutQuad } }
                    Behavior on border.color { ColorAnimation { duration: 250; easing.type: Easing.InOutQuad } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Rectangle {
                            width: 6
                            height: 24
                            radius: 3
                            color: primaryColor
                            opacity: win.currentPage === key ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                            Label {
                                text: title
                                color: textColor
                                font.pixelSize: 15
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignLeft
                            }
                            Label {
                                text: subtitle
                                color: secondaryTextColor
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignLeft
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            win.currentPage = key
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            Rectangle {
                id: aboutButton
                Layout.fillWidth: true
                height: 44
                radius: 10
                color: "transparent"
                border.color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12

                    Label {
                        text: qsTr("关于")
                        color: textColor
                        font.pixelSize: 14
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        color: "transparent"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        aboutDialog.open()
                        navDrawer.close()
                    }
                }
            }

            // 主题切换按钮 - 重新设计布局
            Rectangle {
                id: themeToggleRect
                Layout.fillWidth: true
                height: 52  // 增加高度提供更好的点击区域
                radius: 12  // 稍微增加圆角
                color: backend.darkThemeEnabled
                       ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.18)
                       : Qt.rgba(0, 0, 0, 0.02)
                border.color: backend.darkThemeEnabled ? primaryColor : borderColor
                border.width: 1
                
                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter  // 精确垂直居中
                    anchors.margins: 12  // 统一的边距
                    spacing: 10
                    
                    // 图标容器 - 确保完美对齐
                    Item {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        Layout.alignment: Qt.AlignVCenter
                        
                        Image {
                            id: themeIcon
                            anchors.centerIn: parent
                            width: 20
                            height: 20
                            source: backend.darkThemeEnabled ? "moon.svg" : "sun.svg"
                            fillMode: Image.PreserveAspectFit
                            smooth: false
                            antialiasing: false
                            
                            ColorOverlay {
                                anchors.fill: parent
                                source: parent
                                color: backend.darkThemeEnabled ? primaryColor : secondaryTextColor
                                antialiasing: false
                                smooth: false
                            }
                        }
                    }
                    
                    // 文字标签 - 精确对齐
                    Label {
                        text: backend.darkThemeEnabled ? qsTr("深色模式") : qsTr("浅色模式")
                        color: backend.darkThemeEnabled ? primaryColor : textColor
                        font.pixelSize: 14  // 稍微增大字体
                        font.weight: Font.Medium  // 中等字重
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        verticalAlignment: Text.AlignVCenter
                        height: 24  // 固定高度确保对齐
                    }
                    
                    // 开关 - 精确对齐
                    Switch {
                        id: themeSwitch
                        checked: backend.darkThemeEnabled
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 48  // 固定宽度
                        Layout.preferredHeight: 26  // 固定高度
                        onCheckedChanged: {
                            if (checked !== backend.darkThemeEnabled) {
                                backend.setDarkThemeEnabled(checked)
                            }
                        }
                        
                        // 主题切换动画
                        Behavior on checked {
                            NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
                        }
                    }
                }
                
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        backend.setDarkThemeEnabled(!backend.darkThemeEnabled)
                    }
                }
                
                // 悬停效果
                states: [
                    State {
                        name: "hovered"
                        when: mouseArea.containsMouse
                        PropertyChanges { 
                            target: themeToggleRect
                            color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.1) 
                        }
                    }
                ]
                
                transitions: [
                    Transition {
                        from: ""; to: "hovered"
                        ColorAnimation { duration: 200; easing.type: Easing.InOutQuad }
                    },
                    Transition {
                        from: "hovered"; to: ""
                        ColorAnimation { duration: 200; easing.type: Easing.InOutQuad }
                    }
                ]
            }
        }
    }

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
    
    Rectangle {
        id: resizeTopLeft
        anchors.top: parent.top
        anchors.left: parent.left
        width: 8
        height: 8
        color: "transparent"
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
                    var delta = mouseX - lastMouseX
                    win.width -= delta
                    win.x += delta
                }
            }
            onMouseYChanged: {
                if (pressedButtons & Qt.LeftButton) {
                    var delta = mouseY - lastMouseY
                    win.height -= delta
                    win.y += delta
                }
            }
            cursorShape: Qt.SizeFDiagCursor
        }
    }
    
    Rectangle {
        id: resizeTopRight
        anchors.top: parent.top
        anchors.right: parent.right
        width: 8
        height: 8
        color: "transparent"
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
                    win.width += mouseX - lastMouseX
                }
            }
            onMouseYChanged: {
                if (pressedButtons & Qt.LeftButton) {
                    var delta = mouseY - lastMouseY
                    win.height -= delta
                    win.y += delta
                }
            }
            cursorShape: Qt.SizeBDiagCursor
        }
    }
    
    Rectangle {
        id: resizeBottomLeft
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: 8
        height: 8
        color: "transparent"
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
                    var delta = mouseX - lastMouseX
                    win.width -= delta
                    win.x += delta
                }
            }
            onMouseYChanged: {
                if (pressedButtons & Qt.LeftButton) {
                    win.height += mouseY - lastMouseY
                }
            }
            cursorShape: Qt.SizeBDiagCursor
        }
    }
    
    Rectangle {
        id: resizeBottomRight
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 8
        height: 8
        color: "transparent"
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
                    win.width += mouseX - lastMouseX
                }
            }
            onMouseYChanged: {
                if (pressedButtons & Qt.LeftButton) {
                    win.height += mouseY - lastMouseY
                }
            }
            cursorShape: Qt.SizeFDiagCursor
        }
    }

    Rectangle {
        id: contentContainer
        anchors.top: titleBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 8  // 与窗口背景边距保持一致
        color: "transparent"
        
        radius: 0
        clip: true
        
        // 添加轻微的背景色变化，增强层次感
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(surfaceColor.r, surfaceColor.g, surfaceColor.b, 0.05) }
            GradientStop { position: 1.0; color: "transparent" }
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16  // 内部边距，确保内容不贴边
            spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            ToolButton {
                id: menuButton
                implicitWidth: 44
                implicitHeight: 44
                contentItem: ColorOverlay {
                    anchors.centerIn: parent
                    source: Image {
                        source: Qt.resolvedUrl("Menu.svg")
                        width: 22
                        height: 22
                        sourceSize.width: 128
                        sourceSize.height: 128
                        asynchronous: false
                        fillMode: Image.PreserveAspectFit
                        smooth: false
                        mipmap: false
                        antialiasing: false
                    }
                    color: textColor
                    opacity: menuButton.enabled ? 1.0 : 0.4
                    antialiasing: false
                    smooth: false
                }
                background: Rectangle {
                    color: "transparent"
                    border.width: 0
                }
                Layout.alignment: Qt.AlignVCenter
                Accessible.name: qsTr("打开导航")
                onClicked: navDrawer.open()
            }

            Rectangle {
                radius: 12
                Layout.fillWidth: true
                implicitHeight: 56
                color: surfaceColor
                border.color: borderColor
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12
                    Label {
                        text: backend.status
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                        color: textColor
                        font.pixelSize: 16
                    }
                    Label {
                        visible: win.copyHint.length > 0
                        text: win.copyHint
                        color: primaryColor
                        font.pixelSize: 13
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Rectangle {
                        radius: 8
                        color: backend.steamReady ? "#2dd6c1" : "#ef476f"
                        implicitWidth: 12
                        implicitHeight: 12
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Label {
                        text: backend.steamReady ? qsTr("Steam 已就绪") : qsTr("Steam 未登录")
                        color: secondaryTextColor
                        font.pixelSize: 14
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: win.currentPage === "room"
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }

            ColumnLayout {
                anchors.fill: parent
                spacing: 16

                Frame {
                    Layout.fillWidth: true
                    padding: 18
                    Material.elevation: 6
                    background: Rectangle { 
                        radius: 12 
                        color: surfaceColor
                        border.color: borderColor
                        
                        // 平滑过渡动画
                        Behavior on color {
                            ColorAnimation { 
                                duration: 300 
                                easing.type: Easing.InOutQuad 
                            }
                        }
                        Behavior on border.color {
                            ColorAnimation { 
                                duration: 300 
                                easing.type: Easing.InOutQuad 
                            }
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12
                        Layout.fillWidth: true

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            TextField {
                                id: joinField
                                Layout.fillWidth: true
                                Layout.minimumWidth: 320
                                placeholderText: qsTr("输入房间 ID 或房主 SteamID64 或留空以主持房间")
                                text: backend.joinTarget
                                enabled: !(backend.isHost || backend.isConnected)
                                onTextChanged: backend.joinTarget = text
                                color: textColor
                                selectByMouse: true
                                
                                // 文本字段背景色适应主题
                                background: Rectangle {
                                    radius: 6
                                    color: inputBackgroundColor
                                    border.color: inputBorderColor
                                    
                                    Behavior on color {
                                        ColorAnimation { duration: 300; easing.type: Easing.InOutQuad }
                                    }
                                    Behavior on border.color {
                                        ColorAnimation { duration: 300; easing.type: Easing.InOutQuad }
                                    }
                                }
                            }

                            ComboBox {
                                id: modeCombo
                                Layout.preferredWidth: 140
                                Layout.alignment: Qt.AlignVCenter
                                model: [
                                    { text: qsTr("TCP 模式"), value: 0 },
                                    { text: qsTr("TUN 模式"), value: 1 }
                                ]
                                textRole: "text"
                                valueRole: "value"
                                currentIndex: Math.max(0, Math.min(model.length - 1, backend.connectionMode))
                                enabled: !(backend.isHost || backend.isConnected)
                                onActivated: backend.connectionMode = model[currentIndex].value
                            }

                            Switch {
                                id: startSwitch
                                text: qsTr("启动")
                                checked: backend.isHost || backend.isConnected
                                Layout.alignment: Qt.AlignVCenter
                                onToggled: {
                                    if (checked && !backend.isConnected && !backend.isHost) {
                                        backend.joinHost()
                                    } else if (!checked && (backend.isConnected || backend.isHost)) {
                                        backend.disconnect()
                                    }
                                }
                            }

                            Switch {
                                id: publishSwitch
                                text: qsTr("公开到大厅")
                                checked: backend.publishLobby
                                enabled: (!backend.isConnected) || backend.isHost
                                Layout.alignment: Qt.AlignVCenter
                                onToggled: backend.publishLobby = checked
                            }
                        }

                        TextField {
                            id: roomNameField
                            Layout.fillWidth: true
                            placeholderText: qsTr("房间名（主持时展示在大厅列表中）")
                            text: backend.roomName
                            onTextChanged: backend.roomName = text
                            color: textColor
                            selectByMouse: true
                            enabled: !backend.isConnected
                            visible: publishSwitch.checked && !backend.isConnected
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                                Repeater {
                                    model: [
                                        { title: qsTr("房间名"), value: backend.lobbyName, copyValue: backend.lobbyName, accent: "#7fded1" },
                                        { title: qsTr("房间 ID"), value: backend.lobbyId, copyValue: backend.lobbyId, accent: "#4285f4" },
                                        backend.connectionMode === 1
                                    ? {
                                        title: qsTr("TUN 信息"),
                                        value: backend.tunLocalIp.length > 0
                                        ? (backend.tunDeviceName.length > 0
                                        ? qsTr("%1 · %2").arg(backend.tunLocalIp).arg(backend.tunDeviceName)
                                        : backend.tunLocalIp)
                                        : (backend.tunDeviceName.length > 0
                                        ? qsTr("%1 · 待分配 IP").arg(backend.tunDeviceName)
                                        : qsTr("未启动")),
                                        copyValue: backend.tunLocalIp,
                                        accent: "#2ad2ff"
                                    }
                                    : {
                                        title: qsTr("连接 IP"),
                                        value: backend.localBindPort > 0 ? qsTr("127.0.0.1:%1").arg(backend.localBindPort) : "",
                                        copyValue: backend.localBindPort > 0 ? qsTr("127.0.0.1:%1").arg(backend.localBindPort) : "",
                                        accent: "#2ad2ff"
                                    }
                                ]
                                delegate: Rectangle {
                                    required property string title
                                    required property string value
                                    required property string accent
                                    property string copyValue: (typeof modelData !== "undefined" && modelData.copyValue !== undefined) ? modelData.copyValue : ""
                                    property bool isTunCard: title === qsTr("TUN 信息")
                                    property string effectiveCopyValue: isTunCard ? backend.tunLocalIp : copyValue
                                    property bool canCopy: effectiveCopyValue.length > 0 || value.length > 0
                                    property bool revealValue: false
                                    property bool isSensitive: title === qsTr("房间 ID")
                                    property string displayValue: value.length > 0 ? (isSensitive && !revealValue ? win.maskId(value) : value) : ""
                                    radius: 10
                                    color: surfaceColor
                                    border.color: borderColor
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 58
                                    opacity: value.length > 0 ? 1.0 : 0.4

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 4
                                        Label {
                                            text: title
                                            color: accent
                                            font.pixelSize: 12
                                        }
                                        RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 6
                                                Label {
                                                    id: valueLabel
                                                    text: value.length > 0 ? displayValue : qsTr("未加入")
                                                    color: textColor
                                                    font.pixelSize: 15
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                                Label {
                                                    text: qsTr("点击复制")
                                                    visible: value.length > 0
                                                    color: secondaryTextColor
                                                    font.pixelSize: 12
                                                }
                                            }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: canCopy
                                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: {
                                            if (!canCopy) {
                                                return;
                                            }
                                            if (isSensitive && !revealValue) {
                                                revealValue = true;
                                                return;
                                            }
                                            const text = effectiveCopyValue.length > 0 ? effectiveCopyValue : value
                                            win.copyBadge(title, text)
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            visible: backend.connectionMode === 0
                            Layout.fillWidth: true
                            spacing: 10

                            Label {
                                text: qsTr("本地转发端口")
                                color: secondaryTextColor
                            }

                            SpinBox {
                                id: portField
                                from: 0
                                to: 65535
                                value: backend.localPort
                                editable: true
                                enabled: backend.connectionMode === 0 && !(backend.isHost || backend.isConnected)
                                onValueChanged: backend.localPort = value
                            }

                            Item { width: 24; height: 1 }

                            Label {
                                text: qsTr("本地绑定端口")
                                color: secondaryTextColor
                            }

                            SpinBox {
                                id: bindPortField
                                from: 1
                                to: 65535
                                value: backend.localBindPort
                                editable: true
                                enabled: backend.connectionMode === 0 && !(backend.isHost || backend.isConnected)
                                onValueChanged: backend.localBindPort = value
                            }

                            Rectangle { Layout.fillWidth: true; color: "transparent" }

                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 16

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 16
                        Frame {
                            id: chatFrame
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredHeight: 320
                            padding: 16
                            Material.elevation: 6
                            background: Rectangle { radius: 12; color: surfaceColor; border.color: borderColor }

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Label {
                                        text: qsTr("房间聊天")
                                        font.pixelSize: 18
                                        color: textColor
                                    }
                                    Rectangle { Layout.fillWidth: true; color: "transparent" }
                                    Label {
                                        text: qsTr("共 %1 条").arg(backend.chatModel ? backend.chatModel.count : 0)
                                        color: secondaryTextColor
                                        font.pixelSize: 12
                                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredHeight: 280

                                    id: chatColumn
                                    property var pinnedMessageData: ({})
                                    function refreshPinned() {
                                        const raw = backend.chatModel ? backend.chatModel.pinnedMessage : ({});
                                        pinnedMessageData = {
                                            avatar: raw.avatar || "",
                                            displayName: raw.displayName || "",
                                            message: raw.message || "",
                                            timestamp: raw.timestamp || null
                                        };
                                    }
                                    Component.onCompleted: refreshPinned()
                                    Connections {
                                        target: backend.chatModel
                                        function onPinnedChanged() {
                                            chatColumn.refreshPinned()
                                        }
                                    }

                                    ColumnLayout {
                                        anchors.fill: parent
                                        spacing: 8

                                        Rectangle {
                                            id: pinnedMessageBox
                                            Layout.fillWidth: true
                                            visible: backend.chatModel && backend.chatModel.hasPinned
                                            radius: 12
                                            color: highlightBackgroundColor
                                            border.color: highlightBorderColor
                                            implicitHeight: pinnedContent.implicitHeight + 16

                                            RowLayout {
                                                id: pinnedContent
                                                anchors.fill: parent
                                                anchors.margins: 10
                                                spacing: 10

                                                Item {
                                                    width: 36
                                                    height: 36
                                                    Rectangle {
                                                        id: pinnedAvatarFrame
                                                        anchors.fill: parent
                                                        radius: width / 2
                                                        color: !!chatColumn.pinnedMessageData.avatar && chatColumn.pinnedMessageData.avatar.length > 0 ? "transparent" : "#1f2b3c"
                                                        border.color: highlightAccentColor
                                                        layer.enabled: !!chatColumn.pinnedMessageData.avatar && chatColumn.pinnedMessageData.avatar.length > 0
                                                        layer.effect: OpacityMask {
                                                            source: pinnedAvatarFrame
                                                            maskSource: Rectangle {
                                                                width: pinnedAvatarFrame.width
                                                                height: pinnedAvatarFrame.height
                                                                radius: width / 2
                                                                color: "white"
                                                            }
                                                        }
                                                        Image {
                                                            anchors.fill: parent
                                                            source: String(chatColumn.pinnedMessageData.avatar || "")
                                                            visible: !!chatColumn.pinnedMessageData.avatar && chatColumn.pinnedMessageData.avatar.length > 0
                                                            fillMode: Image.PreserveAspectCrop
                                                            smooth: true
                                                        }
                                                        Label {
                                                            anchors.centerIn: parent
                                                            visible: !(!!chatColumn.pinnedMessageData.avatar && chatColumn.pinnedMessageData.avatar.length > 0)
                                                            text: chatColumn.pinnedMessageData.displayName && chatColumn.pinnedMessageData.displayName.length > 0 ? chatColumn.pinnedMessageData.displayName[0] : "?"
                                                            color: highlightTextColor
                                                            font.pixelSize: 14
                                                        }
                                                    }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 4

                                                    RowLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 8
                                                        Label {
                                                            text: chatColumn.pinnedMessageData.displayName || qsTr("未知用户")
                                                            color: highlightTextColor
                                                            font.pixelSize: 12
                                                            elide: Text.ElideRight
                                                            Layout.fillWidth: true
                                                        }
                                                        Rectangle {
                                                            radius: 6
                                                            color: highlightBorderColor
                                                            Layout.preferredWidth: 44
                                                            Layout.preferredHeight: 20
                                                            Label {
                                                                anchors.centerIn: parent
                                                                text: qsTr("置顶")
                                                                color: backgroundColor
                                                                font.pixelSize: 11
                                                            }
                                                        }
                                                        Label {
                                                            color: highlightTextColor
                                                            font.pixelSize: 11
                                                            text: chatColumn.pinnedMessageData.timestamp ? Qt.formatTime(chatColumn.pinnedMessageData.timestamp, "HH:mm") : ""
                                                            visible: text.length > 0
                                                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                                        }
                                                    }
                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: chatColumn.pinnedMessageData.message || ""
                                                        color: highlightTextColor
                                                        font.pixelSize: 14
                                                        wrapMode: Text.Wrap
                                                        textFormat: Text.PlainText
                                                    }
                                                }
                                            }

                                            Menu {
                                                id: pinnedMenu
                                                parent: chatFrame
                                                MenuItem {
                                                    text: qsTr("取消置顶")
                                                    enabled: backend.isHost
                                                    onTriggered: chatFrame.clearPinned()
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                acceptedButtons: Qt.RightButton
                                                enabled: backend.isHost
                                                hoverEnabled: true
                                                onPressed: function(mouse) {
                                                    if (mouse.button !== Qt.RightButton) {
                                                        return;
                                                    }
                                                    const pos = chatFrame.mapFromItem(pinnedMessageBox, mouse.x, mouse.y);
                                                    pinnedMenu.x = pos.x;
                                                    pinnedMenu.y = pos.y;
                                                    pinnedMenu.open();
                                                }
                                            }
                                        }

                                        ListView {
                                            id: chatList
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.margins: 6
                                            model: backend.chatModel
                                            spacing: 12
                                            clip: true
                                            ScrollBar.vertical: ScrollBar {}
                                            onCountChanged: chatFrame.scrollToBottom()
                                            onModelChanged: chatFrame.scrollToBottom()
                                            Component.onCompleted: chatFrame.scrollToBottom()

                                            delegate: Item {
                                                required property string displayName
                                                required property string avatar
                                                required property string message
                                                required property bool isSelf
                                                required property bool isPinned
                                                required property string steamId
                                                required property var timestamp
                                                width: chatList.width
                                                implicitHeight: bubbleRow.implicitHeight + 8

                                                Row {
                                                    id: bubbleRow
                                                    anchors.left: isSelf ? undefined : parent.left
                                                    anchors.right: isSelf ? parent.right : undefined
                                                    anchors.margins: 6
                                                    spacing: 10
                                                    width: parent.width
                                                    layoutDirection: isSelf ? Qt.RightToLeft : Qt.LeftToRight

                                                    Item {
                                                        width: 40
                                                        height: 40
                                                        Rectangle {
                                                            id: chatAvatarFrame
                                                            anchors.fill: parent
                                                            radius: width / 2
                                                            color: avatar.length > 0 ? "transparent" : (isPinned ? highlightBackgroundColor : Qt.rgba(surfaceColor.r, surfaceColor.g, surfaceColor.b, 0.9))
                                                            border.color: isPinned ? highlightBorderColor : (avatar.length > 0 ? "transparent" : borderColor)
                                                            layer.enabled: avatar.length > 0
                                                            layer.effect: OpacityMask {
                                                                source: chatAvatarFrame
                                                                maskSource: Rectangle {
                                                                    width: chatAvatarFrame.width
                                                                    height: chatAvatarFrame.height
                                                                    radius: chatAvatarFrame.width / 2
                                                                    color: "white"
                                                                }
                                                            }
                                                            Image {
                                                                anchors.fill: parent
                                                                source: avatar
                                                                visible: avatar.length > 0
                                                                fillMode: Image.PreserveAspectCrop
                                                                smooth: true
                                                            }
                                                            Label {
                                                                anchors.centerIn: parent
                                                                visible: avatar.length === 0
                                                                text: displayName.length > 0 ? displayName[0] : "?"
                                                                color: isPinned ? highlightTextColor : secondaryTextColor
                                                                font.pixelSize: 16
                                                            }
                                                        }
                                                    }

                                                    Rectangle {
                                                        id: bubble
                                                        radius: 12
                                                        color: isPinned ? highlightBackgroundColor : (isSelf ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.16) : Qt.rgba(surfaceColor.r, surfaceColor.g, surfaceColor.b, 0.9))
                                                        border.color: isPinned ? highlightBorderColor : (isSelf ? primaryColor : borderColor)
                                                        width: Math.min(chatList.width * 0.72, Math.max(messageText.implicitWidth, headerRow.implicitWidth) + 28)
                                                        implicitHeight: bubbleContent.implicitHeight + 16

                                                        ColumnLayout {
                                                            id: bubbleContent
                                                            anchors.fill: parent
                                                            anchors.margins: 10
                                                            spacing: 6

                                                            RowLayout {
                                                                id: headerRow
                                                                Layout.fillWidth: true
                                                                spacing: 6
                                                                Label {
                                                                    text: displayName
                                                                    color: isPinned ? highlightTextColor : (isSelf ? primaryColor : textColor)
                                                                    font.pixelSize: 12
                                                                    elide: Text.ElideRight
                                                                    Layout.fillWidth: true
                                                                }
                                                                Label {
                                                                    visible: isPinned
                                                                    text: qsTr("置顶")
                                                                    color: highlightTextColor
                                                                    font.pixelSize: 11
                                                                    padding: 4
                                                                    background: Rectangle { radius: 6; color: highlightBackgroundColor }
                                                                }
                                                                Label {
                                                                    color: isPinned ? highlightTextColor : secondaryTextColor
                                                                    font.pixelSize: 11
                                                                    text: timestamp ? Qt.formatTime(timestamp, "HH:mm") : ""
                                                                    visible: text.length > 0
                                                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                                                }
                                                            }
                                                            Text {
                                                                id: messageText
                                                                Layout.fillWidth: true
                                                                text: message
                                                                color: isPinned ? highlightTextColor : textColor
                                                                font.pixelSize: 14
                                                                wrapMode: Text.Wrap
                                                                textFormat: Text.PlainText
                                                                width: bubble.width - 20
                                                            }
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            acceptedButtons: Qt.RightButton
                                                            propagateComposedEvents: true
                                                            enabled: backend.isHost
                                                            onPressed: function(mouse) {
                                                                if (mouse.button !== Qt.RightButton) {
                                                                    return;
                                                                }
                                                                const pos = chatFrame.mapFromItem(bubble, mouse.x, mouse.y);
                                                                pinMenu.x = pos.x;
                                                                pinMenu.y = pos.y;
                                                                pinMenu.open();
                                                            }
                                                        }
                                                    }
                                                }

                                                Menu {
                                                    id: pinMenu
                                                    parent: chatFrame
                                                    MenuItem {
                                                        text: isPinned ? qsTr("取消置顶") : qsTr("置顶")
                                                        enabled: backend.isHost
                                                        onTriggered: {
                                                            if (isPinned) {
                                                                chatFrame.clearPinned()
                                                            } else {
                                                                chatFrame.pinMessage({
                                                                    steamId: steamId,
                                                                    displayName: displayName,
                                                                    avatar: avatar,
                                                                    message: message,
                                                                    timestamp: timestamp
                                                                })
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        visible: chatList.count === 0 && !(backend.chatModel && backend.chatModel.hasPinned)
                                        Label { text: qsTr("暂无消息"); color: secondaryTextColor }
                                        Label { text: qsTr("加入房间后即可在此聊天。"); color: secondaryTextColor; font.pixelSize: 12 }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    TextField {
                                        id: chatInput
                                        Layout.fillWidth: true
                                        placeholderText: qsTr("输入要发送的内容…")
                                        enabled: backend.lobbyId.length > 0
                                        onAccepted: chatFrame.sendMessage()
                                    }

                                    Button {
                                        text: qsTr("发送")
                                        enabled: backend.lobbyId.length > 0 && chatInput.text.trim().length > 0
                                        Layout.alignment: Qt.AlignVCenter
                                        onClicked: chatFrame.sendMessage()
                                    }

                                    Switch {
                                        id: reminderSwitch
                                        text: qsTr("提醒")
                                        Layout.alignment: Qt.AlignVCenter
                                        checked: backend.chatReminderEnabled
                                        onToggled: backend.chatReminderEnabled = checked
                                    }
                                }
                            }

                            function sendMessage() {
                                if (chatInput.text.trim().length === 0) {
                                    return;
                                }
                                backend.sendChatMessage(chatInput.text);
                                chatInput.text = "";
                                chatInput.forceActiveFocus();
                            }

                            function scrollToBottom() {
                                Qt.callLater(function() { chatList.positionViewAtEnd(); });
                            }

                            function pinMessage(entry) {
                                if (!entry || !entry.message) {
                                    return;
                                }
                                backend.pinChatMessage(entry.steamId || "",
                                entry.displayName || "",
                                entry.avatar || "",
                                entry.message,
                                entry.timestamp);
                            }

                            function clearPinned() {
                                backend.clearPinnedChatMessage();
                            }
                        }
                    }

                    Frame {
                        Layout.preferredWidth: 485
                        Layout.fillHeight: true
                        padding: 16
                        Material.elevation: 6
                        background: Rectangle { radius: 12; color: surfaceColor; border.color: borderColor }

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 12
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            TabBar {
                                id: sidebarTabBar
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                spacing: 8
                                background: Rectangle { color: "transparent" }
                                TabButton {
                                    text: qsTr("房间成员")
                                    width: implicitWidth
                                    // 自定义简单的样式以匹配深色主题
                                    contentItem: Label {
                                        text: parent.text
                                        font.pixelSize: 15
                                        color: parent.checked ? primaryColor : secondaryTextColor
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        color: parent.checked ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.1) : "transparent"
                                        radius: 6
                                    }
                                }
        TabButton {
            text: qsTr("Steam 好友")
            width: implicitWidth
            contentItem: Label {
                text: parent.text
                font.pixelSize: 15
                color: parent.checked ? primaryColor : secondaryTextColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: parent.checked
                       ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b,
                                 backend.darkThemeEnabled ? 0.25 : 0.08)
                       : "transparent"
                radius: 6
            }
        }
                            }

                            StackLayout {
                                id: sidebarStack
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                currentIndex: sidebarTabBar.currentIndex

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    ColumnLayout {
                                        anchors.fill: parent
                                        spacing: 12

                                        Item {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.preferredHeight: 320

                                            Flickable {
                                                id: memberFlick
                                                anchors.fill: parent
                                                anchors.margins: 6
                                                clip: true
                                                interactive: contentHeight > height
                                                contentHeight: membersColumn.implicitHeight
                                                ScrollBar.vertical: ScrollBar {}

                                                Column {
                                                    id: membersColumn
                                                    width: parent.width
                                                    spacing: 12
                                                    Repeater {
                                                        id: memberRepeater
                                                        model: backend.membersModel
                                                        delegate: Rectangle {
                                                            id: memberItem // 给这个矩形加个 ID 方便引用
                                                            required property string displayName
                                                            required property string steamId
                                                            required property string avatar
                                                            required property string ip
                                                            required property var ping
                                                            required property string relay
                                                            required property bool isFriend
                                                            required property bool isSelf
                                                            property bool showSteamId: false
                                                            property string maskedSteamId: win.maskId(steamId)

                                                            radius: 10
                                                            // 修改颜色逻辑:增加鼠标悬停变色效果，提示用户可交互
                                                            color: memberMouseArea.containsMouse ? hoverColor : surfaceColor
                                                            border.color: borderColor
                                                            width: parent ? parent.width : 0
                                                            implicitHeight: rowLayout.implicitHeight + 24

                                                            Menu {
                                                                id: memberMenu
                                                                MenuItem {
                                                                    id: addFriendItem
                                                                    text: qsTr("添加好友")
                                                                    visible: !isFriend
                                                                    height: visible ? implicitHeight : 0
                                                                    onTriggered: backend.addFriend(steamId)
                                                                }

                                                                MenuItem {
                                                                    text: qsTr("复制 IP")
                                                                    visible: backend.connectionMode === 1 && ip && ip.length > 0
                                                                    height: visible ? implicitHeight : 0
                                                                    onTriggered: backend.copyToClipboard(ip)
                                                                }

                                                            }

                                                            MouseArea {
                                                                id: memberMouseArea
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                acceptedButtons: Qt.RightButton
                                                                onClicked: (mouse) => {
                                                                    if (mouse.button === Qt.RightButton) {
                                                                        const hasMenu =
                                                                            addFriendItem.visible ||
                                                                            (backend.connectionMode === 1 && ip && ip.length > 0)

                                                                        if (hasMenu)
                                                                            memberMenu.popup()
                                                                    }
                                                                }
                                                            }

                                                            RowLayout {
                                                                id: rowLayout
                                                                anchors.fill: parent
                                                                anchors.margins: 12
                                                                spacing: 12
                                                                // Force-resolve "自己" even if role binding fails; fallback to backend.selfSteamId match.
                                                                property bool selfFlag: isSelf || (backend.selfSteamId.length > 0 && steamId === backend.selfSteamId)

                                            // ---头像部分 (保持不变)---
                                            Item {
                                                width: 48
                                                height: 48
                                                                    Layout.alignment: Qt.AlignVCenter
                                                                    Layout.preferredWidth: 48
                                                                    Layout.preferredHeight: 48
                                                                    Rectangle {
                                                                        id: memberAvatarFrame
                                                                        anchors.fill: parent
                                                                        radius: width / 2
                                                                        color: avatar.length > 0 ? "transparent" : "#1a2436"
                                                                        border.color: avatar.length > 0 ? "transparent" : "#1f2f45"
                                                                        layer.enabled: avatar.length > 0
                                                                        layer.effect: OpacityMask {
                                                                            source: memberAvatarFrame
                                                                            maskSource: Rectangle {
                                                                                width: memberAvatarFrame.width
                                                                                height: memberAvatarFrame.height
                                                                                radius: memberAvatarFrame.width / 2
                                                                                color: "white"
                                                                            }
                                                                        }
                                                                        Image {
                                                                            anchors.fill: parent
                                                                            source: avatar
                                                                            visible: avatar.length > 0
                                                                            fillMode: Image.PreserveAspectCrop
                                                                            smooth: true
                                                                        }
                                                                        Label {
                                                                            anchors.centerIn: parent
                                                                            visible: avatar.length === 0
                                                                            text: displayName.length > 0 ? displayName[0] : "?"
                                                                            color: secondaryTextColor
                                                                            font.pixelSize: 18
                                                                        }
                                                                    }
                                                                }

                                                                // ---文字信息部分 (保持不变)---
                                                                ColumnLayout {
                                                                    spacing: 4
                                                                    Layout.fillWidth: false
                                                                    Layout.alignment: Qt.AlignVCenter

                                                                    RowLayout {
                                                                        spacing: 8
                                                                        Label {
                                                                            text: displayName
                                                                            font.pixelSize: 16
                                                                            color: textColor
                                                                            elide: Text.ElideRight
                                                                        }
                                                                        Rectangle {
                                                                            radius: 8
                                                                            color: Qt.rgba(surfaceColor.r, surfaceColor.g, surfaceColor.b, 0.8)
                                                                            border.color: rowLayout.selfFlag ? "#7fded1" : (isFriend ? primaryColor : "#ef476f")
                                                                            implicitHeight: 22
                                                                            implicitWidth: relationLabel.implicitWidth + 14
                                                                            Layout.alignment: Qt.AlignVCenter
                                                                            Label {
                                                                                id: relationLabel
                                                                                anchors.centerIn: parent
                                                                                text: rowLayout.selfFlag ? qsTr("自己") : (isFriend ? qsTr("好友") : qsTr("陌生人"))
                                                                                color: rowLayout.selfFlag ? "#7fded1" : (isFriend ? "#4285f4" : "#ef476f")
                                                                                font.pixelSize: 11
                                                                            }
                                                                        }
                                                                    }
                                                                    Label {
                                                                        id: memberSteamIdLabel
                                                                        text: qsTr("SteamID: %1").arg(showSteamId ? steamId : maskedSteamId)
                                                                        font.pixelSize: 12
                                                                        color: secondaryTextColor
                                                                        elide: Text.ElideRight
                                                                        MouseArea {
                                                                            anchors.fill: parent
                                                                            cursorShape: Qt.PointingHandCursor
                                                                            onClicked: memberItem.showSteamId = !memberItem.showSteamId
                                                                        }
                                                                    }
                                                                    Label {
                                                                        visible: backend.connectionMode === 1
                                                                        text: qsTr("IP: %1").arg(ip && ip.length > 0 ? ip : qsTr("-"))
                                                                        font.pixelSize: 12
                                                                        color: secondaryTextColor
                                                                        elide: Text.ElideRight
                                                                    }
                                                                }

                                                                // --- 关键占位符 ---
                                                                // 占据剩余空间，把后面的 Ping 推到最右边
                                                                Item {
                                                                    Layout.fillWidth: true
                                                                }

                                                                // 【注意】这里删除了之前的 Button 代码

                                                                // --- Ping 信息列 (保持不变) ---
                                                                ColumnLayout {
                                                                    spacing: 2
                                                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                                                    Label {
                                                                        text: (ping === undefined || ping === null) ? qsTr("-") : qsTr("%1 ms").arg(ping)
                                                                        color: primaryColor
                                                                        font.pixelSize: 14
                                                                        horizontalAlignment: Text.AlignRight
                                                                        Layout.alignment: Qt.AlignRight
                                                                    }
                                                                    Label {
                                                                        text: relay.length > 0 ? relay : "-"
                                                                        color: secondaryTextColor
                                                                        font.pixelSize: 12
                                                                        horizontalAlignment: Text.AlignRight
                                                                        Layout.alignment: Qt.AlignRight
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                                                Column {
                                                    visible: memberRepeater.count === 0
                                                    anchors.centerIn: parent
                                                    spacing: 6
                                                    Label { text: qsTr("暂无成员"); color: secondaryTextColor }
                                                    Label { text: qsTr("创建房间或等待邀请即可出现。"); color: secondaryTextColor; font.pixelSize: 12 }
                                                }
                                            }
                                        }
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    ColumnLayout {
                                        anchors.fill: parent
                                        spacing: 12

                                        RowLayout {

                                            TextField {
                                                id: filterField
                                                Layout.fillWidth: true
                                                placeholderText: qsTr("搜索好友…")
                                                text: win.friendFilter
                                                onTextChanged: {
                                                    win.friendFilter = text
                                                    backend.friendFilter = text
                                                }
                                            }
                                            Rectangle { Layout.fillWidth: true; color: "transparent" }
                                            Item {
                                                implicitWidth: 35
                                                implicitHeight: 35
                                                Layout.alignment: Qt.AlignVCenter

                                                BusyIndicator {
                                                    anchors.fill: parent
                                                    running: backend.friendsRefreshing
                                                    visible: running
                                                }
                                            }
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.preferredHeight: 320

                                            ListView {
                                                id: friendList
                                                anchors.fill: parent
                                                anchors.margins: 8
                                                clip: true
                                                spacing: 10
                                                model: backend.friendsModel
                                                ScrollBar.vertical: ScrollBar {}

                                                Component.onCompleted: {
                                                    console.log("[QML] friendList completed, model count", model ? model.count : "<null>")
                                                }
                                                onModelChanged: console.log("[QML] friendList model changed", model)

                                                onCountChanged: console.log("[QML] friendList count", count)

                                                delegate: Rectangle {
                                                    id: friendItem
                                                    required property string displayName
                                                    required property string steamId
                                                    required property string avatar
                                                    required property bool online
                                                    required property string status
                                                    required property int inviteCooldown
                                                    width: friendList.width
                                                    property bool showSteamId: false
                                                    property string maskedSteamId: win.maskId(steamId)

                                                    Component.onCompleted: {
                                                        console.log("[QML] delegate", displayName, steamId)
                                                    }

                                                    visible: true // ordering handled by proxy, we keep all items
                                                    radius: 10
                                                    color: surfaceColor
                                                    border.color: borderColor
                                                    implicitHeight: 60
                                                    Layout.fillWidth: true

                                                    RowLayout {
                                                        anchors.left: parent.left
                                                        anchors.right: parent.right
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        anchors.margins: 10
                                                        spacing: 10
                                                        Layout.alignment: Qt.AlignVCenter
                                                        Item {
                                                            id: avatarContainer
                                                            width: 44
                                                            height: 44
                                                            Layout.alignment: Qt.AlignVCenter
                                                            Layout.preferredWidth: 44
                                                            Layout.preferredHeight: 44
                                                            Rectangle {
                                                                id: avatarFrame
                                                                anchors.fill: parent
                                                                radius: width / 2
                                                                color: avatar.length > 0 ? "transparent" : "#1a2436"
                                                                border.color: avatar.length > 0 ? "transparent" : "#1f2f45"
                                                                clip: false
                                                                layer.enabled: avatar.length > 0
                                                                layer.effect: OpacityMask {
                                                                    source: avatarFrame
                                                                    maskSource: Rectangle {
                                                                        width: avatarFrame.width
                                                                        height: avatarFrame.height
                                                                        radius: avatarFrame.width / 2
                                                                        color: "white"
                                                                    }
                                                                }
                                                                Image {
                                                                    anchors.fill: parent
                                                                    source: avatar
                                                                    visible: avatar.length > 0
                                                                    fillMode: Image.PreserveAspectCrop
                                                                    smooth: true
                                                                }
                                                                Label {
                                                                    anchors.centerIn: parent
                                                                    visible: avatar.length === 0
                                                                    text: displayName.length > 0 ? displayName[0] : "?"
                                                                    color: secondaryTextColor
                                                                    font.pixelSize: 16
                                                                }
                                                            }
                                                            Rectangle {
                                                                width: 12
                                                                height: 12
                                                                radius: 6
                                                                color: primaryColor
                                                                border.color: borderColor
                                                                border.width: 2
                                                                anchors.top: parent.top
                                                                anchors.right: parent.right
                                                                anchors.margins: -2
                                                                z: 2
                                                                visible: online
                                                            }
                                                        }
                                                        ColumnLayout {
                                                            spacing: 2
                                                            Layout.fillWidth: true
                                                            Layout.alignment: Qt.AlignVCenter
                                                            RowLayout {
                                                                Layout.fillWidth: true
                                                                spacing: 6
                                                                Label {
                                                                    text: displayName
                                                                    color: textColor
                                                                    font.pixelSize: 15
                                                                    elide: Text.ElideRight
                                                                    Layout.fillWidth: true
                                                                }
                                                                Label {
                                                                    text: status
                                                                    color: online ? "#2dd6c1" : "#7f8cab"
                                                                    font.pixelSize: 12
                                                                    visible: status.length > 0
                                                                }
                                                            }
                                                            Label {
                                                                id: friendSteamIdLabel
                                                                text: showSteamId ? steamId : maskedSteamId
                                                                color: secondaryTextColor
                                                                font.pixelSize: 12
                                                                elide: Text.ElideRight
                                                                MouseArea {
                                                                    anchors.fill: parent
                                                                    cursorShape: Qt.PointingHandCursor
                                                                    onClicked: friendItem.showSteamId = !friendItem.showSteamId
                                                                }
                                                            }
                                                        }
                                                        Item { Layout.fillWidth: true }
                                                        Button {
                                                            text: inviteCooldown === 0
                                                            ? qsTr("邀请")
                                                            : qsTr("等待 %1s").arg(inviteCooldown)
                                                            enabled: (backend.isHost || backend.isConnected) && inviteCooldown === 0
                                                            Layout.alignment: Qt.AlignVCenter
                                                            onClicked: backend.inviteFriend(steamId)
                                                        }
                                                    }
                                                }
                                            }

                                            Column {
                                                visible: friendList.count === 0
                                                anchors.centerIn: parent
                                                spacing: 6
                                                Label { text: qsTr("未获取到好友列表"); color: secondaryTextColor }
                                                Label { text: qsTr("确保已登录 Steam 并允许好友可见。"); color: secondaryTextColor; font.pixelSize: 12 }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: win.currentPage === "lobby"
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }

            onVisibleChanged: {
                if (visible) {
                    backend.refreshLobbies()
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Label {
                        text: qsTr("大厅")
                        font.pixelSize: 20
                        color: textColor
                    }
                    Rectangle { Layout.fillWidth: true; color: "transparent" }
                    Item {
                        implicitWidth: 28
                        implicitHeight: 28
                        Layout.alignment: Qt.AlignVCenter

                        BusyIndicator {
                            anchors.fill: parent
                            running: backend.lobbyRefreshing
                            visible: running
                        }
                    }
                    Label {
                        text: qsTr("房间数: %1").arg(backend.lobbiesModel ? backend.lobbiesModel.count : 0)
                        color: secondaryTextColor
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Button {
                        text: qsTr("刷新")
                        enabled: backend.steamReady && !backend.lobbyRefreshing
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: backend.refreshLobbies()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    TextField {
                        id: lobbySearchField
                        Layout.fillWidth: true
                        placeholderText: qsTr("搜索房间名 / 房主 / 房间 ID …")
                        text: backend.lobbyFilter
                        onTextChanged: backend.lobbyFilter = text
                    }

                    ComboBox {
                        id: lobbySortBox
                        Layout.preferredWidth: 160
                        model: [
                            { text: qsTr("按人数"), value: 0 },
                            { text: qsTr("按房间名"), value: 1 }
                        ]
                        textRole: "text"
                        valueRole: "value"
                        currentIndex: Math.min(model.length - 1, Math.max(0, backend.lobbySortMode))
                        onActivated: backend.lobbySortMode = model[currentIndex].value
                    }
                }

                Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    padding: 16
                    Material.elevation: 6
                    background: Rectangle { radius: 12; color: surfaceColor; border.color: borderColor }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10

                        Label {
                            text: qsTr("浏览当前可见的房间，点击加入或复制房间 ID。")
                            color: secondaryTextColor
                            font.pixelSize: 13
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Flickable {
                                id: lobbyFlick
                                anchors.fill: parent
                                anchors.margins: 4
                                clip: true
                                contentHeight: lobbyColumn.implicitHeight
                                interactive: contentHeight > height
                                ScrollBar.vertical: ScrollBar {}

                                Column {
                                    id: lobbyColumn
                                    width: parent.width
                                    spacing: 10

                                    Repeater {
                                        id: lobbyRepeater
                                        model: backend.lobbiesModel
                                        delegate: Rectangle {
                                            required property string lobbyId
                                            required property string name
                                            required property string hostName
                                            required property string hostId
                                            required property int members
                                            required property var ping
                                            property bool isCurrentLobby: backend.lobbyId && backend.lobbyId === lobbyId
                                            property bool canJoin: backend.steamReady && !isCurrentLobby
                                            property bool showLobbyId: false
                                            property string maskedLobbyId: win.maskId(lobbyId)
                                            radius: 10
                                            color: surfaceColor
                                    border.color: borderColor
                                            width: parent ? parent.width : 0
                                            height: implicitHeight
                                            implicitHeight: row.implicitHeight + 16

                                            RowLayout {
                                                id: row
                                                anchors.fill: parent
                                                anchors.margins: 10
                                                spacing: 10

                                                ColumnLayout {
                                                    spacing: 4
                                                    Layout.fillWidth: true

                                                    RowLayout {
                                                        spacing: 8
                                                        Layout.fillWidth: true
                                                        Label {
                                                            text: name.length > 0
                                                            ? name
                                                            : (hostName.length > 0
                                                            ? qsTr("%1的房间").arg(hostName)
                                                            : qsTr("未命名房间"))
                                                            font.pixelSize: 16
                                                            color: textColor
                                                            elide: Text.ElideRight
                                                            Layout.fillWidth: true
                                                        }
                                                        Rectangle {
                                                            visible: isCurrentLobby && backend.isHost
                                                            radius: 8
                                                            color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.1)
                                                            border.color: primaryColor
                                                            implicitHeight: 22
                                                            implicitWidth: badgeText.implicitWidth + 14
                                                            Label {
                                                                id: badgeText
                                                                anchors.centerIn: parent
                                                                text: qsTr("你正在主持")
                                                                color: primaryColor
                                                                font.pixelSize: 11
                                                            }
                                                        }
                                                        Rectangle {
                                                            visible: isCurrentLobby && backend.isConnected && !backend.isHost
                                                            radius: 8
                                                            color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.1)
                                                            border.color: primaryColor
                                                            implicitHeight: 22
                                                            implicitWidth: joinedText.implicitWidth + 14
                                                            Label {
                                                                id: joinedText
                                                                anchors.centerIn: parent
                                                                text: qsTr("已加入此房间")
                                                                color: primaryColor
                                                                font.pixelSize: 11
                                                            }
                                                        }
                                                    }

                                                    RowLayout {
                                                        spacing: 6
                                                        Layout.fillWidth: true
                                                        Label {
                                                            text: qsTr("房主: %1").arg(hostName.length > 0 ? hostName : win.maskId(hostId))
                                                            color: secondaryTextColor
                                                            font.pixelSize: 12
                                                            elide: Text.ElideRight
                                                            Layout.fillWidth: true
                                                        }
                                                        Label {
                                                            id: lobbyIdLabel
                                                            text: qsTr("房间 ID: %1").arg(showLobbyId ? lobbyId : maskedLobbyId)
                                                            color: secondaryTextColor
                                                            font.pixelSize: 12
                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: showLobbyId = true
                                                            }
                                                        }
                                                    }
                                                }

                                                Item { Layout.fillWidth: true } // push right

                                                RowLayout {
                                                    spacing: 10
                                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                                    Label {
                                                        text: qsTr("共有 %1 人").arg(members)
                                                        color: primaryColor
                                                        font.pixelSize: 13
                                                        horizontalAlignment: Text.AlignRight
                                                        Layout.alignment: Qt.AlignVCenter
                                                    }
                                                    Button {
                                                        text: isCurrentLobby ? qsTr("已在此房间") : qsTr("加入")
                                                        Layout.alignment: Qt.AlignVCenter
                                                        enabled: canJoin
                                                        onClicked: backend.joinLobby(lobbyId)
                                                    }
                                                    Button {
                                                        text: qsTr("复制 ID")
                                                        flat: true
                                                        Layout.alignment: Qt.AlignVCenter
                                                        onClicked: win.copyBadge(qsTr("房间 ID"), lobbyId)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 6
                                visible: !backend.lobbyRefreshing && lobbyRepeater.count === 0
                                Label { text: qsTr("暂无大厅数据"); color: secondaryTextColor }
                                Label { text: qsTr("点击右上角刷新获取房间列表。"); color: secondaryTextColor; font.pixelSize: 12 }
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: win.currentPage === "node"
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
            id: nodePage
            property bool isWindows: Qt.platform.os === "windows"

            RowLayout {
                anchors.fill: parent
                spacing: 12

                Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.width * 0.55
                    padding: 16
                    Material.elevation: 6
                    background: Rectangle { radius: 12; color: surfaceColor; border.color: borderColor }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Label {
                            text: qsTr("中继节点延迟")
                            font.pixelSize: 20
                            color: textColor
                        }
                        Label {
                            text: qsTr("展示当前 Steam 环境下的中继 POP 往返延迟估计值。")
                            color: secondaryTextColor
                            font.pixelSize: 13
                            wrapMode: Text.WordWrap
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 140
                            radius: 12
                            color: surfaceColor
                            border.color: borderColor

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 8

                                Label {
                                    text: backend.relayPing >= 0 ? qsTr("%1 ms").arg(backend.relayPing)
                                    : qsTr("未获取")
                                    color: backend.relayPing >= 0 ? primaryColor : secondaryTextColor
                                    font.pixelSize: 38
                                    font.bold: true
                                }

                                Label {
                                    text: backend.relayPing >= 0
                                    ? qsTr("每 2 秒自动刷新，取最优中继的双向往返时延估算。")
                                    : qsTr("需要 Steam 运行后才能探测中继延迟。")
                                    color: secondaryTextColor
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        Label {
                            text: qsTr("可用中继节点（%1 个）").arg(backend.relayPops.length)
                            color: secondaryTextColor
                            font.pixelSize: 13
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredHeight: 280

                            ListView {
                                id: relayList
                                anchors.fill: parent
                                anchors.margins: 6
                                model: backend.relayPops
                                clip: true
                                spacing: 10
                                ScrollBar.vertical: ScrollBar {}

                                delegate: Rectangle {
                                    width: relayList.width
                                    radius: 10
                                    color: Qt.rgba(surfaceColor.r, surfaceColor.g, surfaceColor.b, 0.8)
                                    border.color: borderColor
                                    implicitHeight: 64

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 10

                                        ColumnLayout {
                                            spacing: 2
                                            Layout.fillWidth: true
                                            Label {
                                                text: modelData.name
                                                color: textColor
                                                font.pixelSize: 15
                                                elide: Text.ElideRight
                                            }
                                            Label {
                                                visible: modelData.via !== undefined && modelData.via.length > 0
                                                text: qsTr("经由 %1").arg(modelData.via)
                                                color: secondaryTextColor
                                                font.pixelSize: 12
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        ColumnLayout {
                                            spacing: 2
                                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                            Label {
                                                text: modelData.ping >= 0 ? qsTr("%1 ms").arg(modelData.ping) : qsTr("-")
                                                color: modelData.ping < 0 ? "#b0b0b0"
                                                : (modelData.ping <= 100 ? "#4285f4"
                                                : (modelData.ping <= 200 ? "#fbbc05" : "#ea4335"))
                                                font.pixelSize: 16
                                            }
                                            Label {
                                                text: modelData.ping >= 0 ? qsTr("往返估计") : qsTr("不可达")
                                                color: secondaryTextColor
                                                font.pixelSize: 11
                                                horizontalAlignment: Text.AlignRight
                                                Layout.alignment: Qt.AlignRight
                                            }
                                        }
                                    }
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 6
                                visible: relayList.count === 0
                                Label { text: qsTr("暂无中继节点数据"); color: secondaryTextColor }
                        Label { text: qsTr("等待 Steam 网络初始化或正在探测中…"); color: secondaryTextColor; font.pixelSize: 12 }
                            }
                        }
                    }
                }

                Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    // 修复 1: 减小宽度比例 (0.45 -> 0.43)，为中间的 spacing (12px) 留出空间
                    Layout.preferredWidth: parent.width * 0.43
                    padding: 16
                    Material.elevation: 6
                    background: Rectangle { radius: 12; color: surfaceColor; border.color: borderColor }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Label {
                            text: qsTr("Steam 切换")
                            font.pixelSize: 20
                            color: textColor
                        }
                        Label {
                            text: qsTr("仅 Windows 生效:为 Steam.exe 启动添加或移除 \"-steamchina\" 参数。")
                            color: secondaryTextColor
                            font.pixelSize: 13
                            wrapMode: Text.WordWrap
                            // 修复 2: 显式设置填满宽度，确保文本能根据面板宽度正确换行
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            id: steamSwitchRow
                            Layout.fillWidth: true
                            spacing: 10

                            Button {
                                id: steamGlobalButton
                                text: qsTr("国际版启动")
                                enabled: nodePage.isWindows
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                
                                // 添加调试输出
                                onEnabledChanged: console.log("Steam Global Button enabled:", enabled, "Platform:", Qt.platform.os)
                                onClicked: {
                                    console.log("Steam Global Button clicked, calling backend.launchSteam(false)")
                                    backend.launchSteam(false)
                                }
                            }

                            Button {
                                id: steamChinaButton
                                text: qsTr("蒸汽平台 (-steamchina)")
                                enabled: nodePage.isWindows
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                
                                // 添加调试输出
                                onEnabledChanged: console.log("Steam China Button enabled:", enabled)
                                onClicked: {
                                    console.log("Steam China Button clicked, calling backend.launchSteam(true)")
                                    backend.launchSteam(true)
                                }
                            }
                        }

                        Label {
                            text: nodePage.isWindows
                            ? qsTr("如果 Steam 已在运行，将尝试以对应参数重新唤起。")
                            : qsTr("当前平台不支持自动切换，按钮已禁用。")
                            color: secondaryTextColor
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            // 修复 3: 底部提示文本也需要宽度约束
                            Layout.fillWidth: true
                        }

                        // 修复 4: 添加一个透明填充项，占据底部剩余的空白高度
                        // 这能保证上方的内容始终靠顶对齐，不会因为高度拉伸而出现奇怪的垂直分布
                        Item { Layout.fillHeight: true }
                    }
                }

            }
        }
    }


    }

}
