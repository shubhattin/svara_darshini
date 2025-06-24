#!/bin/bash

# Android Splash Screen Generator Script
# Generates splash screens with main icon centered on white background
# 

cd ..

SOURCE_ICON="src/img/icon.png"
ANDROID_RES_DIR="android/app/src/main/res"

# Check if source icon exists
if [ ! -f "$SOURCE_ICON" ]; then
    echo "Error: Source icon $SOURCE_ICON not found!"
    exit 1
fi

# Define splash screen configurations: [directory]="width x height x icon_size"
declare -A SPLASH_CONFIGS=(
    ["drawable"]="480x320x120"
    ["drawable-land-mdpi"]="480x320x120"
    ["drawable-land-hdpi"]="800x480x180"
    ["drawable-land-xhdpi"]="1280x720x240"
    ["drawable-land-xxhdpi"]="1600x960x320"
    ["drawable-land-xxxhdpi"]="1920x1280x400"
    ["drawable-port-mdpi"]="320x480x120"
    ["drawable-port-hdpi"]="480x800x180"
    ["drawable-port-xhdpi"]="720x1280x240"
    ["drawable-port-xxhdpi"]="960x1600x320"
    ["drawable-port-xxxhdpi"]="1280x1920x400"
)

echo "Generating Android splash screens from $SOURCE_ICON..."
echo "Source image: $(magick identify $SOURCE_ICON)"
echo ""

# Generate splash screens for each configuration
for dir in "${!SPLASH_CONFIGS[@]}"; do
    config=${SPLASH_CONFIGS[$dir]}
    
    # Parse width x height x icon_size
    width=$(echo $config | cut -d'x' -f1)
    height=$(echo $config | cut -d'x' -f2)
    icon_size=$(echo $config | cut -d'x' -f3)
    
    target_dir="$ANDROID_RES_DIR/$dir"
    target_file="$target_dir/splash.png"
    
    echo "Generating splash for $dir (${width}x${height}, icon: ${icon_size}px)..."
    
    # Create directory if it doesn't exist
    mkdir -p "$target_dir"
    
    # Create splash screen: white background with centered icon
    magick -size "${width}x${height}" xc:white \
        \( "$SOURCE_ICON" -resize "${icon_size}x${icon_size}" \) \
        -gravity center -composite \
        "$target_file"
    
    echo "  ✓ Created $target_file"
done

echo ""
echo "✅ Android splash screens generated successfully!"
echo ""
echo "Generated splash screens:"
for dir in "${!SPLASH_CONFIGS[@]}"; do
    config=${SPLASH_CONFIGS[$dir]}
    width=$(echo $config | cut -d'x' -f1)
    height=$(echo $config | cut -d'x' -f2)
    icon_size=$(echo $config | cut -d'x' -f3)
    
    orientation="Base"
    if [[ $dir == *"land"* ]]; then
        orientation="Landscape"
    elif [[ $dir == *"port"* ]]; then
        orientation="Portrait"
    fi
    
    echo "  🖼️  $dir/ - $orientation (${width}×${height}, icon: ${icon_size}px)"
done

echo ""
echo "💡 All splash screens now have your main icon centered on a white background!"
echo "🔧 The icon sizes are automatically scaled for optimal visibility on each screen size." 