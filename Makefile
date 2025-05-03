# SMOLiX Makefile
# This file compiles the SMOLiX bootloader and kernel
# and builds a bootable floppy image.
# Copyright (C) 2025 Krzysztof Krystian Jankowski

# Tools
ASM = fasm
QEMU = qemu-system-i386 -m 1 -k en-us -rtc base=localtime -vga std -cpu 486 -boot order=a -drive format=raw,file=$(FLOPPY_IMG)
FLATPAL_86BOX = flatpak run net._86box._86Box
DD = dd
MKDIR = mkdir -p
RM = rm -f
RMDIR = rm -rf

# USB floppy device (change this to match your system)
# To identify your USB floppy drive:
#   1. Run 'lsblk' or 'sudo fdisk -l' to list all block devices
#   2. Connect your USB floppy drive and run the command again
#   3. The new device that appears is your floppy drive (usually /dev/sdX where X is a letter)
#   4. Check the size to confirm (~1.4MB for a standard floppy)
# CAUTION: Make sure this is the correct device before using 'make burn'!
USB_FLOPPY = /dev/sdb

# Directories
BUILD_DIR = build
BIN_DIR = $(BUILD_DIR)/bin
IMG_DIR = $(BUILD_DIR)/img

# Files
BOOTLOADER = $(BIN_DIR)/boot.bin
KERNEL = $(BIN_DIR)/kernel.bin
FLOPPY_IMG = $(IMG_DIR)/floppy.img
TEST_FILE = src/file1.txt

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
$(FLOPPY_IMG): $(BOOTLOADER) $(KERNEL) $(IMG_DIR)/floppy_empty.img $(TEST_FILE)
	cp $(IMG_DIR)/floppy_empty.img $(FLOPPY_IMG)
	$(DD) if=$(BOOTLOADER) of=$(FLOPPY_IMG) bs=512 count=1 conv=notrunc
	$(DD) if=$(KERNEL) of=$(FLOPPY_IMG) bs=512 seek=1 conv=notrunc
	$(DD) if=$(TEST_FILE) of=$(FLOPPY_IMG) bs=512 seek=8 conv=notrunc

# Run SMOLiX in QEMU/86Box
run: $(FLOPPY_IMG)
	$(FLATPAL_86BOX)

# Burn SMOLiX to physical floppy disk
burn: $(FLOPPY_IMG)
	@echo "WARNING: This will overwrite all data on $(USB_FLOPPY)!"
	@echo "Make sure $(USB_FLOPPY) is your USB floppy drive, not another drive!"
	@echo "Press Ctrl+C to cancel, or Enter to continue..."
	@read dummy
	sudo $(DD) if=$(FLOPPY_IMG) of=$(USB_FLOPPY) bs=1024 conv=notrunc
	@echo "Floppy image successfully burned to $(USB_FLOPPY)"
	@echo "You may now safely eject the floppy disk."

# Clean build artifacts
clean:
	$(RM) $(BOOTLOADER) $(KERNEL) $(FLOPPY_IMG) $(IMG_DIR)/floppy_empty.img
	$(RMDIR) $(BUILD_DIR)

.PHONY: all run clean burn