import QtQuick
import QtQuick.Layouts
import QtQuick.Particles
import QtQuick.Effects
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support

WallpaperItem {
    id: root
    
    readonly property var config: root.configuration
    
    // Background layer
    Rectangle {
        anchors.fill: parent
        color: "black"
        z: -1
    }
    
    property real rotationProgress: 0.0
    
    // Check for incremental effects
    readonly property bool isIncrementalEffect: {
        if (!config) return false;
        let effect = config.AppliedEffect;
        return effect === "shrink" || effect === "blur_over_time" || effect === "darken_over_time";
    }

    // DISCRETE SHRINK LOGIC
    // 0-25% time: 1.0 scale
    // 25-50% time: 0.75 scale (25% smaller)
    // 50-75% time: 0.50 scale (50% smaller)
    // 75-100% time: 0.25 scale (75% smaller)
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
        duration: Math.max(1000, (config.RotationInterval || 1) * 60000)
        running: isIncrementalEffect
        loops: Animation.Infinite
    }
    
    Image {
        id: wallpaperImage
        anchors.fill: parent
        source: config.ImageSource ? ("file://" + config.ImageSource + "?" + Math.random()) : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
        
        onStatusChanged: {
            if (status === Image.Error) {
                console.error("org.kde.plasma.rotationandeffects: Image load error: " + source);
            }
        }

        Behavior on source {
            SequentialAnimation {
                NumberAnimation { target: imageContainer; property: "opacity"; from: 1.0; to: 0.0; duration: 250 }
                PropertyAction { target: root; property: "rotationProgress"; value: 0.0 }
                ScriptAction { script: if (isIncrementalEffect) progressAnimation.restart(); }
                NumberAnimation { target: imageContainer; property: "opacity"; from: 0.0; to: 1.0; duration: 250 }
            }
        }
    }

    Item {
        id: imageContainer
        anchors.fill: parent
        
        // Apply the discrete scale only if 'shrink' is selected
        scale: config.AppliedEffect === "shrink" ? discreteScale : 1.0
        transformOrigin: Item.Center

        MultiEffect {
            source: wallpaperImage
            anchors.fill: parent
            
            // Continuous blur/darken if those are selected
            blurEnabled: config.AppliedEffect === "blur_over_time"
            blurMax: 64
            blur: rotationProgress
            brightness: config.AppliedEffect === "darken_over_time" ? -rotationProgress : 0.0
        }
    }

    ParticleSystem {
        id: rainParticles
        anchors.fill: parent
        running: config.AppliedEffect === "rain"
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
            let output = (data.stdout || "").trim();
            if (output && (output.startsWith("/") || output.startsWith("file://"))) {
                let cleanPath = output.replace(/^file:\/\//, "");
                config.ImageSource = cleanPath;
            }
            disconnectSource(sourceName);
        }
    }

    Timer {
        id: rotationTimer
        interval: Math.max(60000, (config.RotationInterval || 1) * 60000)
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            try {
                let rawUrl = Qt.resolvedUrl("../code/backend.py").toString();
                let scriptPath = rawUrl.replace(/^file:\/\//, "");
                let command = `python3 "${scriptPath}" --directory "${config.LocalDirectory}" --effect "${config.AppliedEffect}"`;
                pythonBackend.connectSource(command);
            } catch (e) {
                console.error("org.kde.plasma.rotationandeffects: Timer Error: " + e.message);
            }
        }
    }
    
    Connections {
        target: config
        function onRotationIntervalChanged() {
            rotationTimer.restart();
            if (isIncrementalEffect) progressAnimation.restart();
        }
        function onAppliedEffectChanged() {
            if (isIncrementalEffect) {
                progressAnimation.restart();
            } else {
                progressAnimation.stop();
                rotationProgress = 0.0;
            }
        }
    }
}
