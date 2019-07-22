// TODO: decompose it. especially, remove magic string & numbers!
// TODO: https://stackoverflow.com/questions/47891156/understanding-markdirty-in-qml
//       for performance optimization

import QtQuick 2.5
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.1
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Window 2.2


ApplicationWindow {
    id: window
    visible: true
    width: 850; height: 750
    //visibility: Window.Maximized

    MessageDialog {
        id: msgDialog
    }
    //-------------------------------------------------------------

    Connections {
        target: main
        onImageUpdate: {
            im.source = "" // unload
            im.source = "image://imageUpdater/" + path
        }
        onWarning: {
            console.log('received warning:', msg)
            msgDialog.title = "project format error"
            msgDialog.text = msg;
            msgDialog.visible = true;
        }
        onProvideMask: {
            console.log('load', path)
            var old_url = canvas.imgpath
            var url = "image://maskProvider/" + path
            canvas.unloadImage(old_url)
            canvas.imgpath = url 
            canvas.loadImage(url) 
        }
        onSaveMask: {
            canvas.save(path)
        }
        onRmtxtPreview: {
            canvas.visible = false
            canvas.mode = canvas.rmtxt_preview
        }
    }

    //=============================================================
    FileDialog {
        id: projectOpenDialog
        selectFolder: true
        onAccepted: {
            main.open_project(projectOpenDialog.fileUrl)
        }
    }

    Action {
        id: openProject
        text: "Open Manga Project Folder" 
        onTriggered: projectOpenDialog.open()
    }

    menuBar: MenuBar {
        Menu {
            title: "&Open"
            MenuItem { action: openProject }
            MenuItem { 
                text: "Open &Mask" 
            }
        }
    }

    //-------------------------------------------------------------
    readonly property double w_icon:41
    readonly property double h_icon:w_icon

    readonly property double x_one: 3.4
    readonly property double y_one: 2.5
    readonly property double w_one: 35
    readonly property double h_one: 32

    readonly property double x_all: 3.1
    readonly property double y_all: 2.5
    readonly property double w_all: 35
    readonly property double h_all: w_all

    toolBar: ToolBar {
        RowLayout {
            // TODO: Refactor: Add SzmcToolBtn type
            // TODO: add disabled icon representation.
            ToolButton {
                Image {
                    source: "../resource/mask_btn.png"
                    x:     x_one; y:      y_one
                    width: w_one; height: h_one
                }
                Layout.preferredHeight: w_icon
                Layout.preferredWidth:  h_icon
                onClicked: { 
                    main.gen_mask()
                }
            }
            ToolButton {
                Image {
                    source: "../resource/rmtxt_btn.png"
                    x:     x_one; y:      y_one
                    width: w_one; height: h_one
                }
                Layout.preferredHeight: w_icon
                Layout.preferredWidth:  h_icon
                onClicked: {
                    main.rm_txt()
                }
            }
            ToolButton {
                Image {
                    source: "../resource/mask_all_btn.png"
                    x:     x_all; y:      y_all
                    width: w_all; height: h_all
                }
                Layout.preferredHeight: w_icon
                Layout.preferredWidth:  h_icon
                onClicked: { }
            }
            ToolButton {
                Image {
                    source: "../resource/rmtxt_all_btn.png"
                    x:     x_all; y:      y_all
                    width: w_all; height: h_all
                }
                Layout.preferredHeight: w_icon
                Layout.preferredWidth:  h_icon
                onClicked: { }
            }
        }
    }

    //-------------------------------------------------------------

    RowLayout {
        anchors.fill: parent
        spacing: 6

        focus: true
        property bool up_pressed: false
        property bool down_pressed: false
        Keys.onPressed: {
            // TODO: if up/down key pressed in startup page, 
            // IT DELETES THIS QML FILE!!!! WTF????
            if(event.key == Qt.Key_Up)   { 
                if(up_pressed == false){ 
                    console.log('up pressed', up_pressed)
                    main.display_prev(); 
                }
                up_pressed = true
            }
            else if(event.key == Qt.Key_Down) { 
                if(! down_pressed){ 
                    console.log('down pressed', down_pressed)
                    main.display_next(); 
                }
                down_pressed = true
            }
            else if(event.key == Qt.Key_Space){ 
                if (canvas.mode == canvas.rmtxt_preview){
                    canvas.mode = canvas.edit
                }
                canvas.visible = !(canvas.visible);
                // TODO: inform canvas visibility to user.
            }
        }
        Keys.onReleased: {
            if(event.key == Qt.Key_Up)   { 
                console.log('up released', up_pressed)
                if (!event.isAutoRepeat) {
                    up_pressed = false
                }
            }
            else if(event.key == Qt.Key_Down) { 
                console.log('down released', down_pressed)
                if (!event.isAutoRepeat) {
                    down_pressed = false
                }
            }
        }


        ScrollView {
            objectName: "view"
            Layout.fillWidth: true
            Layout.fillHeight: true

            Image { 
                id: "im"
                objectName: "image"
                source: "../resource/startup.png"

                MouseArea {
                    id: area
                    anchors.fill: parent
                    onPressed: {
                        canvas.lastX = mouseX
                        canvas.lastY = mouseY
                        if (canvas.mode == canvas.rmtxt_preview){
                            canvas.mode = canvas.edit
                            canvas.visible = true;
                        }
                    }

                    onPositionChanged: {
                        canvas.requestPaint(); // TODO: use markdirty for performance
                        console.log('is dirty!')
                    }

                }

                Canvas {
                    id: canvas
                    anchors.fill: parent

                    readonly property string edit: "edit"
                    readonly property string rmtxt_preview: "rmtxt_preview"
                    property string mode: edit
                    property int lastX: 0
                    property int lastY: 0
                    property string imgpath: ""

                    onImageLoaded: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0,0, width,height)
                        ctx.drawImage(imgpath, 0, 0);
                        requestPaint();
                    }
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.lineCap = 'round'
                        ctx.strokeStyle = "#FF0000"
                        ctx.lineWidth = 10;
                        ctx.beginPath();

                        ctx.moveTo(lastX, lastY);

                        lastX = area.mouseX;
                        lastY = area.mouseY;
                        ctx.lineTo(lastX,lastY);
                        ctx.stroke();
                    }
                } 
            }
        }

        ScrollView {
            Layout.fillHeight: true
            Layout.preferredWidth: 400
            horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
            ListView {
                width: 200; height: 200
                model: ImModel    
                delegate: 
                Button {
                    width: 400
                    height: 20
                    text: image + "      " + mask
                    style: ButtonStyle {
                        background: Rectangle {
                            color: {
                                displayed ? "yellow" : "white"
                            }
                        }
                    }
                    onClicked: { 
                        main.display(index); 
                    }
                }
            }
        }
    }
    
    statusBar: StatusBar {
        RowLayout {
            anchors.fill: parent
            Label { text: "Read Only" }
        }
    }

    //=============================================================
}
