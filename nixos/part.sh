#!/bin/bash

read -p "Enter Disk: " disk

# Create a GPT partition table
parted /dev/${disk} -- mklabel gpt

# Partition layout
parted /dev/${disk} -- mkpart ESP fat32 1MB 512MB  # ESP (EFI System Partition)
parted /dev/${disk} -- set 1 esp on               # Set ESP flag
parted /dev/${disk} -- mkpart root ext4 512MB -8GB  # Root partition
parted /dev/${disk} -- mkpart swap linux-swap -8GB 100%  # Swap partition

# Format partitions
mkfs.fat -F 32 -n boot /dev/${disk}1              # Format ESP as FAT32
mkfs.ext4 -L nixos /dev/${disk}2                  # Format root as ext4
mkswap -L swap /dev/${disk}3                      # Format swap

# Enable swap
swapon /dev/${disk}3

# Mount partitions
mount /dev/disk/by-label/nixos /mnt               # Mount root partition
mkdir -p /mnt/boot                                # Create boot directory
mount -o umask=077 /dev/disk/by-label/boot /mnt/boot  # Mount ESP

# Generate NixOS configuration
nixos-generate-config --root /mnt
