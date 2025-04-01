#!/bin/bash

# Create all required icon sizes for iOS
mkdir -p DriveAIios/Assets.xcassets/AppIcon.appiconset

# Create a base icon with a black background and a colorful "C"
# This is a very simple representation - in a real app, you would use proper image files

# Function to create a simple colored icon
create_icon() {
    size=$1
    filename=$2
    
    # Create a simple colored square for the icon
    convert -size ${size}x${size} xc:black \
        -fill "gradient:red-orange-yellow-green-blue" \
        -gravity center \
        -pointsize $((size/2)) \
        -font Arial \
        -annotate 0 "C" \
        DriveAIios/Assets.xcassets/AppIcon.appiconset/$filename
    
    echo "Created $filename (${size}x${size})"
}

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "ImageMagick is not installed. Using placeholder icons instead."
    
    # Create placeholder icons (simple colored squares)
    for size in 40 60 58 87 80 120 180 1024; do
        touch DriveAIios/Assets.xcassets/AppIcon.appiconset/Icon-${size}.png
        echo "Created placeholder for Icon-${size}.png"
    done
else
    # Create all required icon sizes
    create_icon 40 "Icon-40.png"
    create_icon 60 "Icon-60.png"
    create_icon 58 "Icon-58.png"
    create_icon 87 "Icon-87.png"
    create_icon 80 "Icon-80.png"
    create_icon 120 "Icon-120.png"
    create_icon 180 "Icon-180.png"
    create_icon 1024 "Icon-1024.png"
fi

echo "All icons created successfully!"
