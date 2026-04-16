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
    property alias cfg_AppliedEffect: effectField.text

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

        Controls.TextField {
            id: effectField
            Kirigami.FormData.label: "Applied Effect:"
            Layout.fillWidth: true
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
