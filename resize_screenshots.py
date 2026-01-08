#!/usr/bin/env python3
"""
Script to resize screenshots for App Store Connect submission.
Resizes images to required dimensions for iPhone screenshots.
"""

from PIL import Image
import os
import sys
import glob

# Required dimensions for App Store Connect
REQUIRED_SIZES = {
    'iphone_6_5_portrait': (1242, 2688),   # iPhone 11 Pro Max
    'iphone_6_5_landscape': (2688, 1242),  # iPhone 11 Pro Max landscape
    'iphone_6_7_portrait': (1284, 2778),   # iPhone 14 Pro Max
    'iphone_6_7_landscape': (2778, 1284),  # iPhone 14 Pro Max landscape
}

def resize_image(input_path, output_path, target_size, maintain_aspect=True):
    """
    Resize an image to target size.
    
    Args:
        input_path: Path to input image
        output_path: Path to save resized image
        target_size: Tuple (width, height)
        maintain_aspect: If True, maintain aspect ratio and add padding
    """
    try:
        img = Image.open(input_path)
        
        if maintain_aspect:
            # Calculate scaling to fit within target size
            img_ratio = img.width / img.height
            target_ratio = target_size[0] / target_size[1]
            
            if img_ratio > target_ratio:
                # Image is wider - fit to width
                new_width = target_size[0]
                new_height = int(target_size[0] / img_ratio)
            else:
                # Image is taller - fit to height
                new_height = target_size[1]
                new_width = int(target_size[1] * img_ratio)
            
            # Resize maintaining aspect ratio
            resized = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
            
            # Create new image with target size and white background
            final = Image.new('RGB', target_size, (255, 255, 255))
            
            # Paste resized image centered
            paste_x = (target_size[0] - new_width) // 2
            paste_y = (target_size[1] - new_height) // 2
            final.paste(resized, (paste_x, paste_y))
        else:
            # Stretch to exact size
            final = img.resize(target_size, Image.Resampling.LANCZOS)
        
        final.save(output_path, 'PNG', quality=95)
        print(f"✅ Resized: {os.path.basename(input_path)} -> {os.path.basename(output_path)} ({target_size[0]}x{target_size[1]})")
        return True
        
    except Exception as e:
        print(f"❌ Error processing {input_path}: {e}")
        return False

def process_screenshots(input_dir='screenshots', output_dir='screenshots/appstore'):
    """
    Process all screenshots in input directory.
    
    Args:
        input_dir: Directory containing original screenshots
        output_dir: Directory to save resized screenshots
    """
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    # Find all image files (including subdirectories)
    image_extensions = ['*.png', '*.jpg', '*.jpeg', '*.PNG', '*.JPG', '*.JPEG']
    image_files = []
    for ext in image_extensions:
        # Search in input_dir and subdirectories
        pattern = os.path.join(input_dir, '**', ext)
        image_files.extend(glob.glob(pattern, recursive=True))
        # Also search directly in input_dir
        pattern = os.path.join(input_dir, ext)
        image_files.extend(glob.glob(pattern))
    
    # Remove duplicates
    image_files = list(set(image_files))
    
    if not image_files:
        print(f"⚠️  No images found in {input_dir}/")
        print("   Please add your screenshots to the 'screenshots' folder")
        print("\n💡 Tip: You can also drag and drop screenshots directly into the 'screenshots' folder")
        return
    
    print(f"📸 Found {len(image_files)} screenshot(s) to process\n")
    
    # Process each screenshot
    for idx, img_path in enumerate(image_files, 1):
        base_name = os.path.splitext(os.path.basename(img_path))[0]
        print(f"Processing {idx}/{len(image_files)}: {base_name}")
        
        # Create resized versions for each required size
        for size_name, size in REQUIRED_SIZES.items():
            output_name = f"{base_name}_{size_name}_{size[0]}x{size[1]}.png"
            output_path = os.path.join(output_dir, output_name)
            resize_image(img_path, output_path, size, maintain_aspect=True)
        
        print()
    
    print(f"✅ All screenshots processed! Check '{output_dir}/' folder")
    print("\n📋 Summary of required screenshots for App Store Connect:")
    print("   - iPhone 6.5\" Portrait: 1242 × 2688px")
    print("   - iPhone 6.5\" Landscape: 2688 × 1242px")
    print("   - iPhone 6.7\" Portrait: 1284 × 2778px")
    print("   - iPhone 6.7\" Landscape: 2778 × 1284px")

if __name__ == '__main__':
    # Check if screenshots directory exists
    if not os.path.exists('screenshots'):
        print("📁 Creating 'screenshots' directory...")
        os.makedirs('screenshots')
        print("✅ Created 'screenshots' directory")
        print("\n📝 Instructions:")
        print("   1. Add your screenshot images to the 'screenshots' folder")
        print("   2. Run this script again to resize them")
        sys.exit(0)
    
    process_screenshots()

