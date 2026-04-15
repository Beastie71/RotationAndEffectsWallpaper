import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: root

    // Required Plasma 6 properties
    property var configDialog
    property var wallpaperConfiguration: wallpaper.configuration
    property var parentLayout

    // Binding aliases
    property alias cfg_LocalDirectory: directoryField.text
    property alias cfg_RotationInterval: intervalSpin.value
    property alias cfg_AppliedEffect: effectCombo.currentText
    property alias cfg_ImageSource: statusLabel.text

    Component.onCompleted: {
        console.log("org.kde.plasma.rotationandeffects: Configuration UI Loaded");
        console.log("org.kde.plasma.rotationandeffects: Initial Directory: " + cfg_LocalDirectory);
        console.log("org.kde.plasma.rotationandeffects: Initial Effect: " + cfg_AppliedEffect);
    }

    Kirigami.FormLayout {
        Layout.fillWidth: true

        Controls.TextField {
            id: directoryField
            Kirigami.FormData.label: "Wallpaper Directory:"
            Layout.fillWidth: true
            placeholderText: "/usr/share/wallpapers"
        }

        Controls.SpinBox {
            id: intervalSpin
            Kirigami.FormData.label: "Rotation Interval (minutes):"
            from: 1
            to: 60
        }

        Controls.ComboBox {
            id: effectCombo
            Kirigami.FormData.label: "Effect:"
            model: ["none", "blur", "grayscale", "sepia", "rain", "shrink", "blur_over_time", "darken_over_time"]
            Layout.fillWidth: true
            
            // Manual selection logic to be safe
            onActivated: {
                cfg_AppliedEffect = model[index];
                console.log("org.kde.plasma.rotationandeffects: User selected effect: " + cfg_AppliedEffect);
            }
            
            Component.onCompleted: {
                let idx = model.indexOf(cfg_AppliedEffect);
                if (idx !== -1) currentIndex = idx;
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Debug Info"
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
}
