#!/usr/bin/env python3
import sys
import os
import random
import argparse
import tempfile
import logging
import hashlib
import getpass
import time

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

def cleanup_temp_files(temp_root, max_age_seconds=7200):
    """Deletes temporary files older than max_age_seconds (default 2 hours)."""
    if not os.path.exists(temp_root):
        return
    
    now = time.time()
    try:
        for f in os.listdir(temp_root):
            f_path = os.path.join(temp_root, f)
            if os.path.isfile(f_path) and f.startswith("wp_"):
                if os.stat(f_path).st_mtime < (now - max_age_seconds):
                    os.remove(f_path)
    except Exception as e:
        logging.warning(f"Cleanup failed: {e}")

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
        logging.warning("Pillow not available, returning original image.")
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

        # Determine the best place for temporary processed images
        runtime_dir = os.environ.get('XDG_RUNTIME_DIR')
        if runtime_dir and os.path.isdir(runtime_dir):
            temp_root = os.path.join(runtime_dir, 'rotationandeffectswallpaper')
        else:
            temp_root = os.path.join(tempfile.gettempdir(), f"rotationandeffectswallpaper_{getpass.getuser()}")
        
        try:
            os.makedirs(temp_root, exist_ok=True)
            cleanup_temp_files(temp_root) # Run cleanup during processing
        except Exception:
            temp_root = tempfile.gettempdir()

        # Hash source path + effect + mtime to create a unique but stable filename
        mtime = os.path.getmtime(image_path)
        path_hash = hashlib.md5(f"{image_path}_{effect}_{mtime}".encode()).hexdigest()[:12]
        output_path = os.path.join(temp_root, f"wp_{path_hash}.jpg")
        
        # Cache hit: Return existing file
        if os.path.exists(output_path):
            return output_path

        try:
            # JPEG is much faster to encode/decode than PNG for wallpapers
            img.save(output_path, "JPEG", quality=95)
        except Exception as e:
            logging.error(f"Failed to save processed image to {output_path}: {e}")
            raise
            
        return output_path

def main():
    parser = argparse.ArgumentParser(description="KDE 6 Wallpaper Backend")
    parser.add_argument("--directory", required=True, help="Directory to load wallpapers from")
    parser.add_argument("--effect", default="none", help="Effect to apply")
    args = parser.parse_args()

    if not args.directory:
        logging.error("No directory specified.")
        print("")
        return

    # Expand user paths (e.g., ~)
    directory = os.path.abspath(os.path.expanduser(args.directory))
    
    if not os.path.isdir(directory):
        logging.error(f"Provided path is not a directory: {directory}")
        print("")
        return

    all_images = get_all_wallpapers(directory)
    
    if not all_images:
        logging.error(f"No valid images found in {directory}")
        # Return empty string to signal no image found
        print("")
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

    # If we reached here, all attempts failed to process the image
    logging.error("Failed to process any wallpaper after multiple attempts.")
    
    # If we have images but processing failed, fall back to the first raw image
    if all_images:
        logging.info(f"Falling back to raw image: {all_images[0]}")
        print(all_images[0])
    else:
        print("")

if __name__ == "__main__":
    main()
