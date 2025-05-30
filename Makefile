# SMOLiX Makefile
# This file compiles the SMOLiX bootloader and kernel
# and builds a bootable floppy image.
# Copyright (C) 2025 Krzysztof Krystian Jankowski

# Tools
ASM = fasm
BOCHS = bochs -q -debugger -f .bochsrc
QEMU = qemu-system-i386 -m 1 -k en-us -rtc base=localtime -vga std -cpu 486 -boot order=a -drive format=raw,file=$(FLOPPY_IMG)
FLATPAL_86BOX = flatpak run net._86box._86Box
DD = dd
MKDIR = mkdir -p
RM = rm -f
RMDIR = rm -rf

# USB floppy device (change this to match your system)
USB_FLOPPY = /dev/sdb

# Directories
BUILD_DIR = build
BIN_DIR = $(BUILD_DIR)/bin
IMG_DIR = $(BUILD_DIR)/img

# Files
BOOTLOADER = $(BIN_DIR)/boot.bin
KERNEL = $(BIN_DIR)/kernel.bin
FLOPPY_IMG = $(IMG_DIR)/floppy.img
OS_FILE_0 = src/textfiles/manual.txt
OS_FILE_1 = src/textfiles/file1.txt
OS_FILE_2 = src/textfiles/file2.txt
OS_FILE_3 = src/textfiles/file3.txt

# Floppy image size (1.44MB = 2880 sectors * 512 bytes/sector)
FLOPPY_SECTORS = 2880

# Kernel details
KERNEL_SECTORS = 16 # Allocate 8KB (16 sectors) for the kernel

# OS File details
OS_FILE_SECTORS = 16 # Allocate 8KB (16 sectors) for each OS file

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
	$(DD) if=/dev/zero of=$@ bs=512 count=$(FLOPPY_SECTORS)

# Write to floppy image
$(FLOPPY_IMG): $(BOOTLOADER) $(KERNEL) $(IMG_DIR)/floppy_empty.img $(OS_FILE_0) $(OS_FILE_1) $(OS_FILE_2) $(OS_FILE_3) | $(IMG_DIR)
	cp $(IMG_DIR)/floppy_empty.img $(FLOPPY_IMG)
	$(DD) if=$(BOOTLOADER) of=$(FLOPPY_IMG) bs=512 count=1 conv=notrunc
	$(DD) if=$(KERNEL) of=$(FLOPPY_IMG) bs=512 seek=1 count=$(KERNEL_SECTORS) conv=notrunc
	$(DD) if=$(OS_FILE_0) of=$(FLOPPY_IMG) bs=512 seek=17 count=$(OS_FILE_SECTORS) conv=notrunc iflag=fullblock
	$(DD) if=$(OS_FILE_1) of=$(FLOPPY_IMG) bs=512 seek=33 count=$(OS_FILE_SECTORS) conv=notrunc iflag=fullblock
	$(DD) if=$(OS_FILE_2) of=$(FLOPPY_IMG) bs=512 seek=49 count=$(OS_FILE_SECTORS) conv=notrunc iflag=fullblock
	$(DD) if=$(OS_FILE_3) of=$(FLOPPY_IMG) bs=512 seek=65 count=$(OS_FILE_SECTORS) conv=notrunc iflag=fullblock

# Run SMOLiX in emulator (default: Bochs)
run: $(FLOPPY_IMG)
	$(FLATPAL_86BOX)

# Run SMOLiX in emulator (default: Bochs)
debug: $(FLOPPY_IMG)
	$(BOCHS)

# Burn SMOLiX to physical floppy disk
burn: $(FLOPPY_IMG)
	@echo "WARNING: This will overwrite all data on $(USB_FLOPPY)!"
	@echo "Make sure $(USB_FLOPPY) is your USB floppy drive, not another drive!"
	@echo "Press Ctrl+C to cancel, or Enter to continue..."
	@read dummy
	sudo $(DD) if=$(FLOPPY_IMG) of=$(USB_FLOPPY) bs=512 conv=notrunc,sync,fsync oflag=direct status=progress
	@echo "Floppy image successfully burned to $(USB_FLOPPY)"
	@echo "You may now safely eject the floppy disk."

# Clean build artifacts
clean:
	$(RM) $(BOOTLOADER) $(KERNEL) $(FLOPPY_IMG) $(IMG_DIR)/floppy_empty.img
	$(RMDIR) $(BUILD_DIR)

# Test floppy drive
test-floppy:
	@echo "Testing floppy drive $(USB_FLOPPY)..."
	@if sudo fdisk -l $(USB_FLOPPY) 2>/dev/null; then \
		echo "Drive detected successfully"; \
	else echo "Drive not detected or accessible"; fi

.PHONY: all run clean burn debug test-floppy
