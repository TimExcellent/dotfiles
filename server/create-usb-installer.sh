#!/usr/bin/env bash
# create-usb-installer.sh — Create bootable Ubuntu USB with autoinstall for ExcellentStore
# Run on the server (or any Linux machine) with the USB drive connected.
# Usage: sudo bash create-usb-installer.sh /dev/sdX
#
# The ISO is downloaded if not already cached in /tmp.
# A CIDATA partition is added with the autoinstall config.
# GRUB is patched to add 'autoinstall' kernel parameter so the install
# proceeds fully unattended — no screen or keyboard needed.
set -euo pipefail

USB_DEV="${1:-}"
ISO_URL="https://releases.ubuntu.com/24.04.2/ubuntu-24.04.2-live-server-amd64.iso"
ISO_PATH="/tmp/ubuntu-24.04.2-live-server-amd64.iso"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -z "$USB_DEV" ]; then
    echo "Usage: sudo bash $0 /dev/sdX"
    echo ""
    echo "Available USB devices:"
    lsblk -d -o NAME,SIZE,TYPE,MODEL | grep disk
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "Must run as root"
    exit 1
fi

echo "=== ExcellentStore USB Installer Builder ==="
echo "Target device: $USB_DEV"
echo "WARNING: This will ERASE $USB_DEV"
read -p "Continue? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] || exit 1

# ── 1. Download ISO if needed ─────────────────────────────────────
if [ -f "$ISO_PATH" ]; then
    echo "[1/4] ISO already cached at $ISO_PATH"
else
    echo "[1/4] Downloading Ubuntu 24.04.2 LTS Server..."
    wget -q --show-progress -O "$ISO_PATH" "$ISO_URL"
fi

# ── 2. Write ISO to USB ──────────────────────────────────────────
echo "[2/4] Writing ISO to $USB_DEV..."
umount "${USB_DEV}"* 2>/dev/null || true
dd if="$ISO_PATH" of="$USB_DEV" bs=4M conv=fsync status=progress
sync

# ── 3. Expand GPT and add CIDATA partition ────────────────────────
echo "[3/4] Adding CIDATA partition..."
sleep 2
partprobe "$USB_DEV" 2>/dev/null || true
sleep 1

# Expand GPT to use full disk
sgdisk -e "$USB_DEV"

# Add 100MB CIDATA partition
sgdisk -n 4:0:+100M -t 4:0700 -c 4:cidata "$USB_DEV"
partprobe "$USB_DEV"
sleep 1

# Format as FAT32 (uppercase label for cloud-init compatibility)
CIDATA_PART="${USB_DEV}4"
# Handle NVMe-style partition naming (e.g., /dev/nvme0n1p4)
if [[ "$USB_DEV" == *nvme* ]] || [[ "$USB_DEV" == *mmcblk* ]]; then
    CIDATA_PART="${USB_DEV}p4"
fi
mkfs.vfat -n CIDATA "$CIDATA_PART"

# Mount and write autoinstall files
MOUNT_DIR=$(mktemp -d)
mount "$CIDATA_PART" "$MOUNT_DIR"

cp "$SCRIPT_DIR/autoinstall/user-data" "$MOUNT_DIR/user-data"
cp "$SCRIPT_DIR/autoinstall/meta-data" "$MOUNT_DIR/meta-data"

sync
umount "$MOUNT_DIR"
rmdir "$MOUNT_DIR"

# ── 4. Patch GRUB to add autoinstall parameter ───────────────────
echo "[4/4] Patching GRUB for unattended install..."
ISO_PART="${USB_DEV}1"
GRUB_DIR=$(mktemp -d)
mount -o ro "$ISO_PART" "$GRUB_DIR" 2>/dev/null || true

# The ISO is read-only (ISO9660), so we can't modify GRUB directly.
# Instead, create a GRUB config overlay on the CIDATA partition.
# Ubuntu installer checks for 'autoinstall' on the kernel command line.
# We add it via a grub.cfg on the EFI partition (sda2).
EFI_PART="${USB_DEV}2"
EFI_DIR=$(mktemp -d)
mount "$EFI_PART" "$EFI_DIR" 2>/dev/null || {
    echo "  Note: Could not mount EFI partition to patch GRUB."
    echo "  The installer may prompt for confirmation. Press Enter to continue."
    umount "$GRUB_DIR" 2>/dev/null || true
    rmdir "$GRUB_DIR" "$EFI_DIR" 2>/dev/null || true
    echo ""
    echo "=== USB Installer Ready ==="
    lsblk "$USB_DEV"
    exit 0
}

# Add autoinstall parameter to GRUB
if [ -f "$EFI_DIR/EFI/boot/grub.cfg" ]; then
    sed -i 's|linux\t/casper/vmlinuz ---|linux\t/casper/vmlinuz autoinstall ---|g' "$EFI_DIR/EFI/boot/grub.cfg"
    echo "  GRUB patched with autoinstall parameter"
elif [ -f "$EFI_DIR/boot/grub/grub.cfg" ]; then
    sed -i 's|linux\t/casper/vmlinuz ---|linux\t/casper/vmlinuz autoinstall ---|g' "$EFI_DIR/boot/grub/grub.cfg"
    echo "  GRUB patched with autoinstall parameter"
else
    echo "  Warning: GRUB config not found on EFI partition"
fi

sync
umount "$EFI_DIR"
umount "$GRUB_DIR" 2>/dev/null || true
rmdir "$GRUB_DIR" "$EFI_DIR" 2>/dev/null || true

echo ""
echo "=== USB Installer Ready ==="
lsblk "$USB_DEV"
echo ""
echo "Boot from this USB to install Ubuntu 24.04 LTS automatically."
echo "After install, run setup-excellentstore.sh for full NAS configuration."
