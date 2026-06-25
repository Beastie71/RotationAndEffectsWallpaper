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
import QtQuick.Layouts
import QtQuick.Particles
import QtQuick.Effects
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support

WallpaperItem {
    id: root
    
    // In Plasma 6, the configuration object is provided by WallpaperItem
    readonly property var config: root.configuration
    
    Component.onCompleted: {
        console.log("org.kde.plasma.rotationandeffects: main.qml loaded");
        if (config) {
            console.log("org.kde.plasma.rotationandeffects: Config keys: " + Object.keys(config));
            console.log("org.kde.plasma.rotationandeffects: Current Directory: " + config.LocalDirectory);
            console.log("org.kde.plasma.rotationandeffects: Current Effect: " + config.AppliedEffect);
        } else {
            console.error("org.kde.plasma.rotationandeffects: Configuration object is null!");
        }
    }

    // Background layer
    Rectangle {
        anchors.fill: parent
        color: "black"
        z: -1
    }

    Connections {
        target: root.configuration
        function onAppliedEffectChanged() {
            progressAnimation.stop();
            root.rotationProgress = 0.0;
            if (root.isIncrementalEffect && imageContainer.opacity > 0) {
                progressAnimation.restart();
            }
        }
        function onRotationIntervalChanged() {
            if (progressAnimation.running) {
                progressAnimation.restart();
            }
        }
    }
    
    property real rotationProgress: 0.0
    
    // Step progress mapper (0%, 25%, 50%, 75%)
    readonly property real effectiveProgress: {
        if (config && config.AnimationFrameRate === 0) {
            let p = rotationProgress;
            if (p < 0.25) return 0.0;
            if (p < 0.50) return 0.25;
            if (p < 0.75) return 0.50;
            return 0.75;
        }
        return rotationProgress;
    }
    
    readonly property bool isIncrementalEffect: config && (config.AppliedEffect === "shrink" || config.AppliedEffect === "blur_over_time" || config.AppliedEffect === "darken_over_time" || config.AppliedEffect === "decay_over_time" || config.AppliedEffect === "melting" || config.AppliedEffect === "pixelate")

    readonly property real discreteScale: {
        if (effectiveProgress < 0.25) return 1.0;
        if (effectiveProgress < 0.50) return 0.75;
        if (effectiveProgress < 0.75) return 0.50;
        return 0.25;
    }

    Timer {
        id: progressAnimation
        
        readonly property int fps: config ? (config.AnimationFrameRate !== undefined ? config.AnimationFrameRate : 15) : 15
        interval: fps === 0 ? 1000 : Math.max(16, Math.round(1000 / fps))
        
        running: isIncrementalEffect
        repeat: true
        triggeredOnStart: false
        
        property real durationMs: Math.max(1000, (config ? (config.RotationInterval || 1) : 1) * 60000)
        property real elapsedMs: 0
        
        onTriggered: {
            elapsedMs += interval;
            if (elapsedMs >= durationMs) {
                root.rotationProgress = 1.0;
                stop();
            } else {
                root.rotationProgress = elapsedMs / durationMs;
            }
        }
        
        function restart() {
            elapsedMs = 0;
            root.rotationProgress = 0.0;
            start();
        }
        
        onRunningChanged: {
            if (!running && elapsedMs < durationMs) {
                elapsedMs = 0;
            }
        }
    }
    
    property string _pendingSource: ""

    SequentialAnimation {
        id: fadeOutAnimation
        NumberAnimation { target: imageContainer; property: "opacity"; to: 0.0; duration: 2000; easing.type: Easing.InOutQuad }
        ScriptAction {
            script: {
                progressAnimation.stop();
                root.rotationProgress = 0.0;
                if (config.ImageSource === _pendingSource) {
                    config.ImageSource = ""; // Force reload
                }
                config.ImageSource = _pendingSource;
                _pendingSource = "";
            }
        }
    }

    NumberAnimation {
        id: fadeInAnimation
        target: imageContainer
        property: "opacity"
        to: 1.0
        duration: 2000
        easing.type: Easing.InOutQuad
        onFinished: {
            if (root.isIncrementalEffect) {
                progressAnimation.restart();
            }
        }
    }

    Image {
        id: wallpaperImage
        anchors.fill: parent
        // Backend now handles unique filenames via hashing, so we don't need random query strings
        source: (config && config.ImageSource) ? ("file://" + config.ImageSource) : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false // Hidden because it's the source for MultiEffect
        
        onStatusChanged: {
            if (status === Image.Error) {
                if (source != "") console.error("org.kde.plasma.rotationandeffects: Image load error: " + source);
            } else if (status === Image.Ready) {
                console.log("org.kde.plasma.rotationandeffects: Image loaded successfully");
                if (imageContainer.opacity === 0) {
                    fadeInAnimation.restart();
                }
            }
        }
    }

    Item {
        id: imageContainer
        anchors.fill: parent
        scale: (config && config.AppliedEffect === "shrink") ? discreteScale : 1.0
        transformOrigin: Item.Center
        visible: ((wallpaperImage.status === Image.Ready) || (opacity > 0)) && (config && config.AppliedEffect !== "melting")
        opacity: 0.0

        // Optimized static display when no animated effects are active
        Image {
            anchors.fill: parent
            source: wallpaperImage.source
            fillMode: Image.PreserveAspectCrop
            visible: !root.isIncrementalEffect && (wallpaperImage.status === Image.Ready)
        }

        MultiEffect {
            source: wallpaperImage
            anchors.fill: parent
            // Only enable MultiEffect features if an animated effect is active
            enabled: root.isIncrementalEffect && (config.AppliedEffect === "blur_over_time" || config.AppliedEffect === "darken_over_time")
            visible: enabled
            blurEnabled: config && config.AppliedEffect === "blur_over_time"
            blurMax: 64
            blur: effectiveProgress
            brightness: (config && config.AppliedEffect === "darken_over_time") ? -effectiveProgress : 0.0
        }

        ShaderEffectSource {
            id: pixelationEffect
            anchors.fill: parent
            sourceItem: wallpaperImage
            live: false // Disable automatic tracking to manually control updates
            smooth: false
            visible: config && config.AppliedEffect === "pixelate"
            
            // Force redraw when rotation progress updates
            Connections {
                target: root
                function onRotationProgressChanged() {
                    if (pixelationEffect.visible) {
                        pixelationEffect.scheduleUpdate();
                    }
                }
            }

            // Force redraw when a new wallpaper image is loaded and ready
            Connections {
                target: wallpaperImage
                function onStatusChanged() {
                    if (wallpaperImage.status === Image.Ready && pixelationEffect.visible) {
                        pixelationEffect.scheduleUpdate();
                    }
                }
            }

            // Force redraw when the effect becomes visible
            onVisibleChanged: {
                if (visible) {
                    scheduleUpdate();
                }
            }

            textureSize: {
                if (!config || config.AppliedEffect !== "pixelate" || root.width <= 0 || root.height <= 0) {
                    return Qt.size(0, 0);
                }
                let p = root.effectiveProgress;
                let minW = 16;
                let minH = Math.max(9, Math.round(minW * (root.height / root.width)));
                
                let factor = Math.pow(1.0 - p, 3.0); 
                let w = minW + (root.width - minW) * factor;
                let h = minH + (root.height - minH) * factor;
                
                return Qt.size(Math.round(w), Math.round(h));
            }
        }
    }

    // GPU-Accelerated Melting Column Slices
    Loader {
        id: meltingEffectLoader
        anchors.fill: parent
        active: config && config.AppliedEffect === "melting"
        visible: active

        sourceComponent: Component {
            Item {
                id: meltingLayoutContainer
                anchors.fill: parent
                readonly property int colCount: config ? (config.MeltingColumns || 100) : 100

                Item {
                    anchors.fill: parent

                    Repeater {
                        model: meltingLayoutContainer.colCount
                        delegate: Image {
                            id: columnStrip
                            width: root.width / meltingLayoutContainer.colCount
                            height: root.height
                            x: index * width
                            y: {
                                let progress = root.effectiveProgress;
                                if (progress < 0.05) return 0;
                                let activeProgress = (progress - 0.05) / 0.95;
                                return Math.pow(activeProgress, 3) * root.height * speedFactor;
                            }

                            // Deterministic speed multiplier per column
                            readonly property real speedFactor: {
                                let hash = Math.sin(index * 12.9898) * 43758.5453;
                                return 0.6 + 0.8 * (hash - Math.floor(hash));
                            }

                            source: wallpaperImage.source
                            asynchronous: false
                            
                            sourceClipRect: {
                                if (!wallpaperImage.sourceSize.width) return Qt.rect(0, 0, 0, 0);
                                let srcColWidth = wallpaperImage.sourceSize.width / meltingLayoutContainer.colCount;
                                return Qt.rect(index * srcColWidth, 0, srcColWidth, wallpaperImage.sourceSize.height);
                            }
                        }
                    }
                }

                // Dark accumulation puddle at the bottom
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: {
                        let progress = root.effectiveProgress;
                        if (progress < 0.05) return 0;
                        let activeProgress = (progress - 0.05) / 0.95;
                        return Math.pow(activeProgress, 2) * 120;
                    }
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: "black" }
                    }
                }
            }
        }
    }

    // TV static/grain overlay for decay_over_time effect
    Item {
        id: noiseOverlay
        anchors.fill: parent
        visible: config && config.AppliedEffect === "decay_over_time"
        opacity: root.effectiveProgress * 0.65
        z: 10 // Force rendering on top of the wallpaper and transitions

        Image {
            id: noiseImage
            source: "noise.png"
            fillMode: Image.Tile
            width: parent.width + 128
            height: parent.height + 128

            property int offsetX: 0
            property int offsetY: 0
            x: -64 + offsetX
            y: -64 + offsetY
        }

        Timer {
            id: staticTimer
            interval: config ? (config.StaticInterval || 1000) : 1000
            running: noiseOverlay.visible && root.rotationProgress > 0
            repeat: true
            onTriggered: {
                noiseImage.offsetX = Math.floor(Math.random() * 64);
                noiseImage.offsetY = Math.floor(Math.random() * 64);
            }
        }
    }

    ParticleSystem {
        id: rainParticles
        anchors.fill: parent
        running: config && config.AppliedEffect === "rain"
        visible: running
        Emitter {
            anchors.fill: parent
            anchors.topMargin: -100
            emitRate: 40 // Reduced from 200 for better performance
            lifeSpan: 1500
            velocity: AngleDirection { angle: 90; magnitude: 1000; magnitudeVariation: 100 }
        }
        ItemParticle {
            delegate: Rectangle { 
                width: 1; height: 20 
                color: "white"
                opacity: 0.2
            }
        }
    }

    Plasma5Support.DataSource {
        id: pythonBackend
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            let stdout = (data.stdout || "").trim();
            if (stdout) {
                // Take the last line in case there's noise on stdout
                let lines = stdout.split("\n");
                let output = lines[lines.length - 1].trim();
                
                if (output && (output.startsWith("/") || output.startsWith("file://"))) {
                    let cleanPath = output.replace(/^file:\/\//, "");
                    if (config) {
                        if (config.ImageSource === "") {
                            config.ImageSource = cleanPath;
                        } else if (config.ImageSource !== cleanPath) {
                            root._pendingSource = cleanPath;
                            fadeOutAnimation.restart();
                        }
                    }
                    console.log("org.kde.plasma.rotationandeffects: New path: " + cleanPath);
                } else {
                    console.warn("org.kde.plasma.rotationandeffects: Unexpected backend output: " + output);
                }
            }
            disconnectSource(sourceName);
        }
    }

    Timer {
        id: rotationTimer
        interval: Math.max(60000, (config ? (config.RotationInterval || 1) : 1) * 60000)
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!config) return;
            try {
                let rawUrl = Qt.resolvedUrl("../code/backend.py").toString();
                let scriptPath = rawUrl.replace(/^file:\/\//, "");
                let command = `python3 "${scriptPath}" --directory "${config.LocalDirectory}" --effect "${config.AppliedEffect}"`;
                console.log("org.kde.plasma.rotationandeffects: Running backend: " + command);
                pythonBackend.connectSource(command);
            } catch (e) {
                console.error("org.kde.plasma.rotationandeffects: Timer Error: " + e.message);
            }
        }
    }
}
