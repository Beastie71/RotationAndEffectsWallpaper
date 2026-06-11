import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: root
    
    implicitWidth: Kirigami.Units.gridUnit * 25
    implicitHeight: Kirigami.Units.gridUnit * 20

    // Properties required for Plasma wallpaper configuration
    property var configDialog
    property var wallpaperConfiguration
    property var parentLayout
    
    // Automatic configuration mapping (cfg_ prefix)
    property alias cfg_LocalDirectory: directoryField.text
    property alias cfg_RotationInterval: intervalSpin.value
    property alias cfg_StaticInterval: staticIntervalSpin.value
    property string cfg_AppliedEffect

    spacing: 0

    Kirigami.FormLayout {
        id: formLayout
        Layout.fillWidth: true

        Controls.TextField {
            id: directoryField
            Kirigami.FormData.label: "Wallpaper Directory:"
            Layout.fillWidth: true
        }

        Controls.SpinBox {
            id: intervalSpin
            Kirigami.FormData.label: "Rotation Interval (minutes):"
            from: 1
            to: 60
        }

        Controls.ComboBox {
            id: effectCombo
            Kirigami.FormData.label: "Applied Effect:"
            Layout.fillWidth: true
            
            model: [
                { text: "None", value: "none" },
                { text: "Blur (Static)", value: "blur" },
                { text: "Grayscale (Static)", value: "grayscale" },
                { text: "Sepia (Static)", value: "sepia" },
                { text: "Rain (Overlay)", value: "rain" },
                { text: "Shrink (Animated)", value: "shrink" },
                { text: "Blur (Animated)", value: "blur_over_time" },
                { text: "Darken (Animated)", value: "darken_over_time" },
                { text: "Decay (Animated)", value: "decay_over_time" }
            ]
            
            textRole: "text"
            valueRole: "value"

            currentIndex: indexOfValue(root.cfg_AppliedEffect)
            onActivated: root.cfg_AppliedEffect = currentValue
        }

        Controls.SpinBox {
            id: staticIntervalSpin
            Kirigami.FormData.label: "Static Speed (ms):"
            from: 50
            to: 5000
            stepSize: 50
            visible: effectCombo.currentValue === "decay_over_time"
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
