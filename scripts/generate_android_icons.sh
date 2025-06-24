#!/bin/bash

# Android Icon Generator Script
# Generates all required Android app icon variants from source icon

cd ..

SOURCE_ICON="src/img/icon.png"
ANDROID_RES_DIR="android/app/src/main/res"

# Check if source icon exists
if [ ! -f "$SOURCE_ICON" ]; then
    echo "Error: Source icon $SOURCE_ICON not found!"
    exit 1
fi

# Define density folders and their corresponding sizes
declare -A DENSITIES=(
    ["mdpi"]="48"
    ["hdpi"]="72"
    ["xhdpi"]="96"
    ["xxhdpi"]="144"
    ["xxxhdpi"]="192"
)

echo "Generating Android app icons from $SOURCE_ICON..."
echo "Source image: $(magick identify $SOURCE_ICON)"

# Generate icons for each density
for density in "${!DENSITIES[@]}"; do
    size=${DENSITIES[$density]}
    target_dir="$ANDROID_RES_DIR/mipmap-$density"
    
    echo "Generating icons for $density density (${size}x${size}px)..."
    
    # Create directory if it doesn't exist
    mkdir -p "$target_dir"
    
    # Generate square launcher icon (ic_launcher.png)
    echo "  Creating ic_launcher.png (${size}x${size})"
    magick "$SOURCE_ICON" -resize "${size}x${size}" "$target_dir/ic_launcher.png"
    
    # Generate round launcher icon (ic_launcher_round.png)
    # Add padding (80% of original size) and create a circular mask
    padded_size=$((size * 80 / 100))  # 80% of target size for padding
    echo "  Creating ic_launcher_round.png (${size}x${size}) with padding"
    magick "$SOURCE_ICON" -resize "${padded_size}x${padded_size}" \
        -background transparent -gravity center -extent "${size}x${size}" \
        \( +clone -threshold 50% -negate -fill white -draw "circle $((size/2)),$((size/2)) $((size/2)),0" \) \
        -alpha off -compose copy_opacity -composite \
        "$target_dir/ic_launcher_round.png"
    
    # Generate foreground icon for adaptive icons (ic_launcher_foreground.png)
    # This should be 108x108dp but we'll scale appropriately
    foreground_size=$((size * 108 / 72))  # Scale based on 72dp base
    echo "  Creating ic_launcher_foreground.png (${foreground_size}x${foreground_size})"
    magick "$SOURCE_ICON" -resize "${foreground_size}x${foreground_size}" \
        -background transparent -gravity center -extent "${foreground_size}x${foreground_size}" \
        "$target_dir/ic_launcher_foreground.png"
done

echo ""
echo "✅ Android icons generated successfully!"
echo ""
echo "Generated files:"
for density in "${!DENSITIES[@]}"; do
    size=${DENSITIES[$density]}
    echo "  📁 mipmap-$density/ (${size}x${size}px)"
    echo "     🖼️  ic_launcher.png"
    echo "     🔵 ic_launcher_round.png" 
    echo "     🎭 ic_launcher_foreground.png"
done

echo ""
echo "📝 Note: Adaptive icon XML files in mipmap-anydpi-v26/ were preserved."
echo "💡 You may want to review the generated icons and adjust if needed." 