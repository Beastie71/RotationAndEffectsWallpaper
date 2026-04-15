import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: root

    // Required properties for Plasma 6 loader
    property var configDialog
    property var wallpaperConfiguration

    // Automatic configuration mapping (cfg_ prefix)
    property alias cfg_LocalDirectory: directoryField.text
    property alias cfg_RotationInterval: intervalSpin.value
    property alias cfg_AppliedEffect: effectCombo.currentText
    property alias cfg_ImageSource: statusLabel.text

    RowLayout {
        Kirigami.FormData.label: "Wallpaper Directory:"
        Layout.fillWidth: true

        Controls.TextField {
            id: directoryField
            Layout.fillWidth: true
            placeholderText: "/usr/share/wallpapers"
        }

        Controls.Button {
            icon.name: "folder-open"
            onClicked: folderDialog.open()
            ToolTip.text: "Browse for folder"
            ToolTip.visible: hovered
        }
    }

    Controls.SpinBox {
        id: intervalSpin
        Kirigami.FormData.label: "Rotation Interval (minutes):"
        from: 1
        to: 60
        stepSize: 1
    }

    Controls.ComboBox {
        id: effectCombo
        Kirigami.FormData.label: "Effect:"
        model: ["none", "blur", "grayscale", "sepia", "rain", "shrink", "blur_over_time", "darken_over_time"]
        Layout.fillWidth: true
    }

    FolderDialog {
        id: folderDialog
        title: "Select Wallpaper Directory"
        currentFolder: cfg_LocalDirectory ? ("file://" + cfg_LocalDirectory) : ""
        onAccepted: {
            let path = selectedFolder.toString();
            if (path.startsWith("file://")) {
                path = path.substring(7);
            }
            cfg_LocalDirectory = decodeURIComponent(path);
        }
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: "Status"
    }

    Controls.Label {
        id: statusLabel
        Kirigami.FormData.label: "Current Image:"
        elide: Text.ElideMiddle
        Layout.fillWidth: true
        font.pixelSize: 10
        color: Kirigami.Theme.disabledTextColor
    }
}
