#!/usr/bin/env python3
# SMOLiX Tileset to Glyphs Converter
# This tool converts a PNG tileset with 1-bit color sprites
# into byte arrays suitable for VGA font glyphs in SMOLiX OS.
# Copyright (C) 2025 Krzysztof Krystian Jankowski

import sys
from PIL import Image

def usage():
    print("SMOLiX Tileset to Glyphs Converter")
    print("Usage: python tileset2glyphs.py <input_file> [output_file] [options]")
    print("Options:")
    print("  -h, --help     Show this help message")
    print("  -a, --asm      Output assembly format (default)")
    print("  -b, --binary   Output binary format")
    print("  -n <num>       Number of sprites to process (default: all)")
    print("  -w <width>     Width of each sprite (default: 8)")
    print("  -t <height>    Height of each sprite (default: 16)")
    sys.exit(1)

def pixel_to_bit(pixel):
    # For 1-bit color, consider non-zero/non-black pixels as '1'
    if isinstance(pixel, tuple):
        # RGB or RGBA format
        return 1 if sum(pixel[:3]) > 0 else 0
    else:
        # Grayscale
        return 1 if pixel > 0 else 0

def convert_sprite_to_bytes(img, sprite_index, width, height, sprites_per_row):
    sprite_bytes = []
    
    # Calculate sprite position in a grid layout
    row = sprite_index // sprites_per_row
    col = sprite_index % sprites_per_row
    
    # Calculate starting pixel coordinates
    start_x = col * width
    start_y = row * height
    
    # Process each row of the sprite
    for y in range(height):
        byte_value = 0
        
        # Process each pixel in the row (from left to right)
        for x in range(width):
            pixel = img.getpixel((start_x + x, start_y + y))
            bit = pixel_to_bit(pixel)
            # Shift and set the bit (MSB first)
            byte_value = (byte_value << 1) | bit
        
        sprite_bytes.append(byte_value)
    
    return sprite_bytes

def generate_asm_output(sprites_data, output_file=None):
    output = []
    
    # Generate the assembly code for each sprite, starting from index 1 (skip first glyph)
    for i, sprite in enumerate(sprites_data[1:], start=1):

        # Format each glyph on a single line
        byte_str = ", ".join([f"0x{b:02x}" for b in sprite])
        output.append(f"glyph_{i:02x}:  db {byte_str}")
        output.append("")
    
    # Add a table that contains pointers to all glyphs
    output.append("glyph_table:")
    for i in range(1, len(sprites_data)):  # Start from 1 to skip the first glyph
        output.append(f"    dw glyph_{i:02x}")
    
    # Add termination entry (0x0)
    output.append("    dw 0x0000  ; termination entry")
    
    result = "\n".join(output)
    
    if output_file:
        with open(output_file, 'w') as f:
            f.write(result)
        print(f"Assembly output written to {output_file}")
    else:
        print(result)

def generate_binary_output(sprites_data, output_file=None):
    if not output_file:
        print("Error: Binary output requires an output file")
        sys.exit(1)
    
    with open(output_file, 'wb') as f:
        # Write the number of sprites
        f.write(bytes([len(sprites_data)]))
        
        # Write each sprite's data
        for sprite in sprites_data:
            f.write(bytes(sprite))
    
    print(f"Binary output written to {output_file}")

def main():
    # Default parameters
    input_file = None
    output_file = None
    output_format = "asm"
    sprite_width = 8
    sprite_height = 16
    num_sprites = None
    
    # Parse command line arguments
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        arg = args[i]
        if arg in ['-h', '--help']:
            usage()
        elif arg in ['-a', '--asm']:
            output_format = "asm"
        elif arg in ['-b', '--binary']:
            output_format = "bin"
        elif arg == '-n' and i + 1 < len(args):
            num_sprites = int(args[i + 1])
            i += 1
        elif arg == '-w' and i + 1 < len(args):
            sprite_width = int(args[i + 1])
            i += 1
        elif arg == '-t' and i + 1 < len(args):
            sprite_height = int(args[i + 1])
            i += 1
        elif input_file is None:
            input_file = arg
        elif output_file is None:
            output_file = arg
        i += 1
    
    if input_file is None:
        usage()
    
    try:
        img = Image.open(input_file)
    except Exception as e:
        print(f"Error opening image: {e}")
        sys.exit(1)
    
    # Calculate number of sprites in the image
    img_width, img_height = img.size
    sprites_per_row = img_width // sprite_width
    sprites_per_col = img_height // sprite_height
    max_sprites = sprites_per_row * sprites_per_col
    
    if num_sprites is None:
        num_sprites = max_sprites
    else:
        num_sprites = min(num_sprites, max_sprites)
    
    print(f"Image dimensions: {img_width}x{img_height}")
    print(f"Sprite size: {sprite_width}x{sprite_height}")
    print(f"Sprite grid: {sprites_per_row} columns x {sprites_per_col} rows")
    print(f"Processing {num_sprites} sprites from {input_file}")
    
    # Convert sprites to byte arrays
    sprites_data = []
    for i in range(num_sprites):
        sprite_bytes = convert_sprite_to_bytes(img, i, sprite_width, sprite_height, sprites_per_row)
        sprites_data.append(sprite_bytes)
        
        # Calculate the sprite's position for better progress reporting
        row = i // sprites_per_row + 1
        col = i % sprites_per_row + 1
        print(f"Sprite {i+1}/{num_sprites} (row {row}, column {col}) converted")
    
    # Generate output
    if output_format == "asm":
        generate_asm_output(sprites_data, output_file)
    elif output_format == "bin":
        generate_binary_output(sprites_data, output_file)

if __name__ == "__main__":
    main()