import os
from PIL import Image, ImageDraw, ImageFont

# Create directory for icons
os.makedirs("icons", exist_ok=True)

# Define icon sizes needed
icon_sizes = {
    "Icon-40.png": 40,
    "Icon-60.png": 60,
    "Icon-58.png": 58,
    "Icon-87.png": 87,
    "Icon-80.png": 80,
    "Icon-120.png": 120,
    "Icon-180.png": 180,
    "Icon-1024.png": 1024
}

# Generate a simple icon with a gradient background and "C" letter
for icon_name, size in icon_sizes.items():
    # Create a new image with a black background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    
    # Draw a rounded rectangle for the icon background
    corner_radius = size // 5
    draw.rounded_rectangle([(0, 0), (size, size)], corner_radius, fill=(0, 0, 0, 255))
    
    # Draw a colorful "C" in the center
    # Use a font size proportional to the icon size
    font_size = int(size * 0.7)
    try:
        font = ImageFont.truetype("Arial.ttf", font_size)
    except IOError:
        # Fallback to default font if Arial is not available
        font = ImageFont.load_default()
    
    # Calculate text position to center it
    text = "C"
    text_width, text_height = draw.textsize(text, font=font) if hasattr(draw, 'textsize') else (font_size, font_size)
    position = ((size - text_width) // 2, (size - text_height) // 2)
    
    # Draw the text with a gradient color
    for y in range(position[1], position[1] + text_height):
        # Create a gradient from pink to orange to green
        progress = (y - position[1]) / text_height
        if progress < 0.5:
            # Pink to orange gradient for the top half
            r = int(255 - progress * 2 * 0)
            g = int(20 + progress * 2 * 150)
            b = int(100 - progress * 2 * 100)
        else:
            # Orange to green gradient for the bottom half
            adjusted_progress = (progress - 0.5) * 2
            r = int(255 - adjusted_progress * 255)
            g = int(170 + adjusted_progress * 85)
            b = int(0 + adjusted_progress * 150)
        
        # Draw a single line of the text with the calculated color
        draw.text(position, text, fill=(r, g, b), font=font)
    
    # Save the icon
    img.save(f"icons/{icon_name}")
    print(f"Generated {icon_name} ({size}x{size})")

print("All icons generated successfully!")
