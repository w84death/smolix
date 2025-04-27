# SMOLiX Makefile
# This file compiles the SMOLiX bootloader and kernel
# and builds a bootable floppy image.
# Copyright (C) 2025 Krzysztof Krystian Jankowski

# Tools
ASM = fasm
QEMU = qemu-kvm -m 1 -k en-us -rtc base=localtime -vga std -cpu 486 -boot a 
DD = dd
MKDIR = mkdir -p
RM = rm -f
RMDIR = rm -rf

# Directories
BUILD_DIR = build
BIN_DIR = $(BUILD_DIR)/bin
IMG_DIR = $(BUILD_DIR)/img

# Files
BOOTLOADER = $(BIN_DIR)/boot.bin
KERNEL = $(BIN_DIR)/kernel.bin
FLOPPY_IMG = $(IMG_DIR)/floppy.img

# Assembly flags
# Note: FASM doesn't need format flags like NASM does
# as it determines output format based on file extension

# Floppy image size (1.44MB)
FLOPPY_SIZE = 1474560

# Kernel load address (matching the bootloader's load address)
KERNEL_ORG = 0x0100

# Default target
all: $(FLOPPY_IMG)

# Create directories
$(BIN_DIR) $(IMG_DIR):
	$(MKDIR) $@

# Compile bootloader
$(BOOTLOADER): src/boot.asm | $(BIN_DIR)
	$(ASM) $< $@

# Compile kernel
$(KERNEL): src/kernel.asm | $(BIN_DIR)
	$(ASM) $< $@

# Create empty floppy image
$(IMG_DIR)/floppy_empty.img: | $(IMG_DIR)
	$(DD) if=/dev/zero of=$@ bs=1474560 count=1

# Write bootloader to floppy image
$(FLOPPY_IMG): $(BOOTLOADER) $(KERNEL) $(IMG_DIR)/floppy_empty.img
	cp $(IMG_DIR)/floppy_empty.img $(FLOPPY_IMG)
	$(DD) if=$(BOOTLOADER) of=$(FLOPPY_IMG) bs=512 count=1 conv=notrunc
	$(DD) if=$(KERNEL) of=$(FLOPPY_IMG) bs=512 seek=1 conv=notrunc

# Run SMOLiX in QEMU
run: $(FLOPPY_IMG)
	$(QEMU) $(FLOPPY_IMG)


# Clean build artifacts
clean:
	$(RM) $(BOOTLOADER) $(KERNEL) $(FLOPPY_IMG) $(IMG_DIR)/floppy_empty.img
	$(RMDIR) $(BUILD_DIR)

.PHONY: all run clean