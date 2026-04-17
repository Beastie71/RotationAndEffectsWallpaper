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
    
    readonly property bool isIncrementalEffect: config && (config.AppliedEffect === "shrink" || config.AppliedEffect === "blur_over_time" || config.AppliedEffect === "darken_over_time")

    readonly property real discreteScale: {
        if (rotationProgress < 0.25) return 1.0;
        if (rotationProgress < 0.50) return 0.75;
        if (rotationProgress < 0.75) return 0.50;
        return 0.25;
    }

    NumberAnimation {
        id: progressAnimation
        target: root
        property: "rotationProgress"
        from: 0.0
        to: 1.0
        duration: Math.max(1000, (config ? (config.RotationInterval || 1) : 1) * 60000)
        running: isIncrementalEffect
        loops: 1
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
        source: (config && config.ImageSource) ? ("file://" + config.ImageSource + "?" + Math.random()) : ""
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
        visible: (wallpaperImage.status === Image.Ready) || (opacity > 0)
        opacity: 0.0

        MultiEffect {
            source: wallpaperImage
            anchors.fill: parent
            blurEnabled: config && config.AppliedEffect === "blur_over_time"
            blurMax: 64
            blur: rotationProgress
            brightness: (config && config.AppliedEffect === "darken_over_time") ? -rotationProgress : 0.0
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
            emitRate: 200
            lifeSpan: 2000
            velocity: AngleDirection { angle: 85; magnitude: 800 }
        }
        ItemParticle {
            delegate: Rectangle { width: 1; height: 15; color: "white"; opacity: 0.3 }
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
