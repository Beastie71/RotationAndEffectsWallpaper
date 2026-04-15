# Rotation and Effects Wallpaper Plugin for KDE 6 (Qt 6)

A dynamic wallpaper plugin for Plasma 6 that uses a Python backend for logic and effects.

## Features

-   **Local Directory Support**: Select any folder on your machine to rotate images from.
-   **Effects Integration**: Apply `blur`, `grayscale`, or `sepia` effects via Python's `Pillow` library, or an animated **`rain`**, **`shrink`**, **`blur_over_time`**, or **`darken_over_time`** overlay directly in QML.
-   **KDE 6 Ready**: Uses the modern `metadata.json` and QML 6 imports.

## Structure

```text
RotationAndEffectsWallpaper/
├── metadata.json               # Plugin metadata (ID, Name, API version)
├── install.sh                  # Installation script for local testing
└── contents/
    ├── config/
    │   └── main.xml            # Configuration schema (includes LocalDirectory)
    ├── ui/
    │   ├── main.qml            # Main wallpaper display and Python bridge
    │   └── config.qml          # Configuration UI (Kirigami-based)
    └── code/
        └── backend.py          # Python logic for image selection and Pillow effects
```

## Installation

1.  **Install dependencies**:
    ```bash
    pip install Pillow
    ```
2.  **Clone or Copy** the project to your local machine.
3.  **Run the installation script**:
    ```bash
    ./install.sh
    ```
3.  **Restart Plasma Shell** (to pick up the new plugin):
    ```bash
    plasmashell --replace &
    ```
4.  **Activate**:
    -   Right-click on your desktop.
    -   Select **Configure Desktop and Wallpaper**.
    -   Under **Wallpaper Type**, choose **"Rotation and Effects Wallpaper"**.

## Development

-   The Python script `contents/code/backend.py` is where the "heavy lifting" happens. It should print the absolute path of the next wallpaper image to `stdout`.
-   The QML logic in `contents/ui/main.qml` uses `PlasmaCore.DataSource` to call this script periodically.
-   Configuration values are automatically synced between the UI, the `main.xml` schema, and the Python call.

## Requirements

-   **KDE Plasma 6**: This plugin is built specifically for the Plasma 6 API.
-   **Qt 6**: Requires `QtQuick.Particles` and `QtQuick.Effects`.
-   **Python 3**: Used for image selection and processing.
-   **Python Pillow**: Required for image-based effects (`blur`, `grayscale`, `sepia`).
    ```bash
    pip install Pillow
    ```

## Troubleshooting

-   **Plugin not showing up**: After running `./install.sh`, you **must** restart the Plasma shell:
    ```bash
    plasmashell --replace &
    ```
-   **Wallpapers not changing**:
    -   Verify the path in the "Wallpaper Directory" setting exists and contains `.jpg`, `.png`, or `.webp` files.
    -   Check the Plasma log for errors from the Python backend:
        ```bash
        journalctl -f | grep RotationAndEffectsWallpaper
        ```
-   **Effects not working**: If `blur`, `grayscale`, or `sepia` don't work, ensure `Pillow` is installed for the `python3` executable used by Plasma.
