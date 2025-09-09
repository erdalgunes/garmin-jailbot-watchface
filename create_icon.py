#!/usr/bin/env python3
from PIL import Image, ImageDraw

# Create a new 64x64 image with transparent background
img = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Define colors
outline = (45, 39, 64, 255)  # #2d2740
body = (126, 119, 160, 255)  # #7e77a0
highlight = (169, 163, 199, 255)  # #a9a3c7
eye = (227, 59, 59, 255)  # #e33b3b
mouth = (74, 68, 96, 255)  # #4a4460

# Scale factor (4x the original 16x16)
scale = 4

# Draw the robot head (scaled from 16x16 to 64x64)
# Outline
draw.rectangle([8, 8, 56, 56], fill=outline)
# Body fill
draw.rectangle([12, 12, 52, 52], fill=body)
# Highlight on top left
draw.rectangle([12, 12, 24, 20], fill=highlight)
# Left eye
draw.rectangle([20, 24, 28, 32], fill=eye)
# Right eye
draw.rectangle([36, 24, 44, 32], fill=eye)
# Mouth
draw.rectangle([24, 40, 40, 44], fill=mouth)

# Save the icon
img.save('resources/drawables/launcher_icon.png')
print("Launcher icon created successfully!")