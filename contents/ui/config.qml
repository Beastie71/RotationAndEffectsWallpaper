/* # Copyright 2026 Michael Letourneau
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License. */

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
    property alias cfg_MeltingColumns: meltingColumnsSpin.value
    property string cfg_AppliedEffect
    property int cfg_AnimationFrameRate

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
                { text: "Decay (Animated)", value: "decay_over_time" },
                { text: "Melting (Animated)", value: "melting" },
                { text: "Pixelate (Animated)", value: "pixelate" }
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

        Controls.SpinBox {
            id: meltingColumnsSpin
            Kirigami.FormData.label: "Melting Columns:"
            from: 10
            to: 500
            stepSize: 10
            visible: effectCombo.currentValue === "melting"
        }

        Controls.ComboBox {
            id: fpsCombo
            Kirigami.FormData.label: "Animation Smoothness:"
            Layout.fillWidth: true
            
            model: [
                { text: "Discrete Steps (25%, 50%, 75%)", value: 0 },
                { text: "Almost Dead Lowest (1 FPS - Eco)", value: 1 },
                { text: "Very Low (5 FPS - Eco)", value: 5 },
                { text: "Low (10 FPS)", value: 10 },
                { text: "Medium (15 FPS - Recommended)", value: 15 },
                { text: "High (30 FPS)", value: 30 },
                { text: "Ultra (60 FPS)", value: 60 }
            ]
            
            textRole: "text"
            valueRole: "value"

            currentIndex: indexOfValue(root.cfg_AnimationFrameRate)
            onActivated: root.cfg_AnimationFrameRate = currentValue
            
            visible: effectCombo.currentValue === "shrink" || 
                     effectCombo.currentValue === "blur_over_time" || 
                     effectCombo.currentValue === "darken_over_time" || 
                     effectCombo.currentValue === "decay_over_time" || 
                     effectCombo.currentValue === "melting" ||
                     effectCombo.currentValue === "pixelate"
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
