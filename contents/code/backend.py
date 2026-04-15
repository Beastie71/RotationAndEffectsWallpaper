#!/usr/bin/env python3
import sys
import os
import random
import argparse
import tempfile
import logging

# Configure logging to stderr so it shows up in Plasma logs
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s', stream=sys.stderr)

# Attempt to import PIL for image effects
try:
    from PIL import Image, ImageFilter, ImageOps
    HAS_PILLOW = True
except ImportError:
    HAS_PILLOW = False
    logging.warning("Python 'Pillow' library not found. Some effects will be disabled.")

def get_all_wallpapers(directory):
    """Finds all wallpaper images in the specified directory."""
    if not os.path.exists(directory):
        logging.error(f"Directory does not exist: {directory}")
        return []
        
    supported_extensions = ('.png', '.jpg', '.jpeg', '.webp')
    images = []
    
    try:
        for root, dirs, files in os.walk(directory):
            for file in files:
                if file.lower().endswith(supported_extensions):
                    images.append(os.path.join(root, file))
    except Exception as e:
        logging.error(f"Error scanning directory: {e}")
    
    return images

def apply_effect(image_path, effect):
    """
    Applies the specified effect using Pillow.
    Returns the path to the processed image in /tmp.
    Raises an exception if processing fails.
    """
    qml_effects = ("none", "rain", "shrink", "blur_over_time", "darken_over_time")
    if effect in qml_effects:
        # Just verify we can open it
        with Image.open(image_path) as img:
            img.verify() 
        return image_path

    if not HAS_PILLOW:
        return image_path

    # Actually process the image
    with Image.open(image_path) as img:
        img = img.convert("RGB") # Ensure consistent format
        if effect == "blur":
            img = img.filter(ImageFilter.GaussianBlur(radius=10))
        elif effect == "grayscale":
            img = ImageOps.grayscale(img)
        elif effect == "sepia":
            sepia_img = ImageOps.grayscale(img)
            sepia_img = ImageOps.colorize(sepia_img, "#704214", "#C0A080")
            img = sepia_img

        temp_dir = tempfile.gettempdir()
        output_path = os.path.join(temp_dir, f"plasma_wallpaper_{effect}.png")
        img.save(output_path, "PNG")
        return output_path

def main():
    parser = argparse.ArgumentParser(description="KDE 6 Wallpaper Backend")
    parser.add_argument("--directory", required=True, help="Directory to load wallpapers from")
    parser.add_argument("--effect", default="none", help="Effect to apply")
    args = parser.parse_args()

    directory = os.path.expanduser(args.directory)
    all_images = get_all_wallpapers(directory)
    
    if not all_images:
        logging.error(f"No valid images found in {directory}")
        # Try a system default as absolute last resort
        print("/usr/share/wallpapers/Next/contents/images/3840x2160.png")
        return

    errors = []
    max_retries = 4
    
    # Shuffle to get random order for retries
    random.shuffle(all_images)
    
    for i in range(min(len(all_images), max_retries + 1)):
        current_image = all_images[i]
        try:
            final_path = apply_effect(current_image, args.effect)
            print(final_path)
            return # Success!
        except Exception as e:
            error_msg = f"Attempt {i+1} failed ({os.path.basename(current_image)}): {str(e)}"
            errors.append(error_msg)
            logging.warning(error_msg)

    # If we reached here, all attempts failed
    logging.error("Failed to load a wallpaper after multiple attempts.")
    for err in errors:
        logging.error(f"  - {err}")
    
    # Print fallback so the desktop isn't blank
    print("/usr/share/wallpapers/Next/contents/images/3840x2160.png")

if __name__ == "__main__":
    main()
