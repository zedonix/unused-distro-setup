#!/usr/bin/env bash
set -euo pipefail

cleanup() {
  rc=$?
  # try to unmount /mnt if mounted
  if mountpoint -q /mnt; then
    umount -R /mnt >/dev/null 2>&1 || true
  fi
  if ((rc != 0)); then
    echo "Aborted. Cleaning up..."
  fi
  return $rc
}
# trap cleanup EXIT

SCRIPT_DIR=$(dirname "$(realpath "$0")")
cd "$SCRIPT_DIR"

# Variable set
timezone="Asia/Kolkata"
username="piyush"

# Make passwd shit better
echo "Defaults pwfeedback" >/etc/sudoers.d/pwfeedback

# Installing necessary stuff
# zypper install -y parted

# --- Prompt Section (collect all user input here) ---
# Ecryption
while true; do
  read -p "Encryption (yes/no)? " encryption
  case "$encryption" in
  yes | no) break ;;
  *) echo "Invalid input. Please enter 'yes' or 'no'." ;;
  esac
done

# Disk Selection
disks=($(lsblk -dno NAME,TYPE,RM | awk '$2 == "disk" && $3 == "0" {print $1}'))
echo "Available disks:"
for i in "${!disks[@]}"; do
  info=$(lsblk -dno NAME,SIZE,MODEL "/dev/${disks[$i]}")
  printf "%2d) %s\n" "$((i + 1))" "$info"
done
while true; do
  read -p "Select disk [1-${#disks[@]}]: " idx
  if [[ "$idx" =~ ^[1-9][0-9]*$ ]] && ((idx >= 1 && idx <= ${#disks[@]})); then
    disk="/dev/${disks[$((idx - 1))]}"
    break
  else
    echo "Invalid selection. Try again."
  fi
done
mount | grep -q "$disk" && echo "Disk appears to be in use!" && exit 1

# Partition Naming
if [[ "$disk" == *nvme* ]] || [[ "$disk" == *mmcblk* ]]; then
  part_prefix="${disk}p"
else
  part_prefix="${disk}"
fi

part1="${part_prefix}1"
part2="${part_prefix}2"

# Which type of install?
#
# First choice: vm or hardware
echo "Choose one:"
select hardware in "vm" "hardware"; do
  [[ -n $hardware ]] && break
  echo "Invalid choice. Please select 1 for vm or 2 for hardware."
done

# Second choice: min or max
echo "Choose one:"
select howMuch in "min" "max"; do
  [[ -n $howMuch ]] && break
  echo "Invalid choice. Please select 1 for min or 2 for max."
done

# extra choice: laptop or bluetooth or none
if [[ "$howMuch" == "max" && "$hardware" == "hardware" ]]; then
  echo "Choose one:"
  select extra in "laptop" "bluetooth" "none"; do
    [[ -n $extra ]] && break
    echo "Invalid choice."
  done
else
  extra="none"
fi

# Hostname
while true; do
  read -p "Hostname: " hostname
  if [[ ! "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]; then
    echo "Invalid hostname. Use 1-63 letters, digits, or hyphens (not starting or ending with hyphen)."
    continue
  fi
  break
done

min=8
echo "Passwords must be minimum $min"
# Root Password
while true; do
  read -s -p "Root password: " root_password
  echo
  if ((${#root_password} < min)); then
    echo "Password must be at least $min characters."
    continue
  fi
  read -s -p "Confirm root password: " root_password2
  echo
  [[ "$root_password" != "$root_password2" ]] && echo "Passwords do not match." && continue
  [[ -z "$root_password" ]] && echo "Password cannot be empty." && continue
  break
done

# User Password
while true; do
  read -s -p "User password: " user_password
  echo
  if ((${#user_password} < min)); then
    echo "Password must be at least $min characters."
    continue
  fi
  read -s -p "Confirm user password: " user_password2
  echo
  [[ "$user_password" != "$user_password2" ]] && echo "Passwords do not match." && continue
  [[ -z "$user_password" ]] && echo "Password cannot be empty." && continue
  break
done

# Partitioning
parted -s "$disk" mklabel gpt
parted -s "$disk" mkpart ESP fat32 1MiB 2049MiB
parted -s "$disk" set 1 esp on
parted -s "$disk" mkpart primary btrfs 2049MiB 100%

# Luks encryption
if [[ "$encryption" == "yes" ]]; then
  cryptsetup luksFormat "$part2"
  cryptsetup open "$part2" cryptroot
fi

# Formatting
mkfs.fat -F 32 -n BOOT "$part1"

if [[ "$encryption" == "no" ]]; then
  mkfs.btrfs -L ROOT "$part2"
else
  mkfs.btrfs -L ROOT /dev/mapper/cryptroot
fi

# Mounting & btfs subvolume
if [[ "$encryption" == "no" ]]; then
  mount "$part2" /mnt
else
  mount /dev/mapper/cryptroot /mnt
fi
mkdir -p /mnt/boot/efi
mount "$part1" /mnt/boot/efi

# Btrfs subvolume shit and mounting it
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@snapshots
mkdir -p /mnt/{home,var,.snapshots}
mount -o noatime,compress=zstd,ssd,space_cache=v2,discard=async,subvol=@home "$part2" /mnt/home
mount -o noatime,compress=zstd,ssd,space_cache=v2,discard=async,subvol=@var "$part2" /mnt/var
mount -o noatime,compress=zstd,ssd,space_cache=v2,discard=async,subvol=@snapshots "$part2" /mnt/.snapshots

# Prepare chroot
mkdir -p /mnt/{proc,sys,dev,run}
mount --types proc /proc /mnt/proc
mount --rbind /sys /mnt/sys
mount --make-rslave /mnt/sys
mount --rbind /dev /mnt/dev
mount --make-rslave /mnt/dev
mount --bind /run /mnt/run
mount --make-slave /mnt/run

# Detect CPU vendor and set microcode package
cpu_vendor=$(lscpu | awk -F: '/Vendor ID:/ {print $2}' | xargs)
if [[ "$cpu_vendor" == "GenuineIntel" ]]; then
  microcode_pkg="ucode-intel"
elif [[ "$cpu_vendor" == "AuthenticAMD" ]]; then
  microcode_pkg="ucode-amd"
fi

cp pkgs.txt pkgss.txt
sed -i "s|microcode|$microcode_pkg|g" pkgss.txt

# Extracting exact firmware packages
mapfile -t drivers < <(lspci -k 2>/dev/null | grep -A1 "Kernel driver in use:" | awk -F': ' '/Kernel driver in use:/ {print $2}' | awk '{print $1}')
declare -A driver_to_pkg=(
  # Graphics
  ["amdgpu"]="kernel-firmware-amdgpu"
  ["radeon"]="kernel-firmware-radeon"
  ["i915"]="kernel-firmware-i915"
  ["nouveau"]="kernel-firmware-nvidia" # nouveau uses nvidia firmware files package on openSUSE
  ["nvidia"]="kernel-firmware-nvidia"

  # Intel wireless / wifi
  ["iwlwifi"]="kernel-firmware-iwlwifi"
  ["iwlmvm"]="kernel-firmware-iwlwifi"
  ["iwldvm"]="kernel-firmware-iwlwifi"

  # Atheros / Qualcomm
  ["ath10k"]="kernel-firmware-ath10k"
  ["ath11k"]="kernel-firmware-ath11k"
  ["ath"]="kernel-firmware-atheros"
  ["ath9k"]="kernel-firmware-atheros"

  # Broadcom
  ["brcmfmac"]="kernel-firmware-brcm"
  ["brcmsmac"]="kernel-firmware-brcm"
  ["brcm"]="kernel-firmware-brcm"

  # Broadcom NICs / Tigon / NetXtreme
  ["bnx2"]="kernel-firmware-bnx2"
  ["bnx2x"]="kernel-firmware-bnx2"
  ["tg3"]="kernel-firmware-bnx2"

  # Chelsio / cxgb
  ["cxgb3"]="kernel-firmware-chelsio"
  ["cxgb4"]="kernel-firmware-chelsio"

  # Marvell, mwifiex
  ["mwl8k"]="kernel-firmware-mwifiex"
  ["mwifiex"]="kernel-firmware-mwifiex"
  ["marvell"]="kernel-firmware-marvell"

  # MediaTek
  ["mt76"]="kernel-firmware-mediatek"
  ["mediatek"]="kernel-firmware-mediatek"

  # Mellanox (mlx)
  ["mlx"]="kernel-firmware-mellanox"
  ["mlx4"]="kernel-firmware-mellanox"
  ["mlx5"]="kernel-firmware-mellanox"

  # Netronome / NFP
  ["nfp"]="kernel-firmware-nfp"

  # QLogic / QED / Qede / QLA2XXX
  ["qla2xxx"]="kernel-firmware-qlogic"
  ["qlogic"]="kernel-firmware-qlogic"
  ["qed"]="kernel-firmware-qlogic"
  ["qede"]="kernel-firmware-qlogic"

  # Qualcomm (some SoC / NIC firmwares)
  ["qcom"]="kernel-firmware-qcom"

  # Realtek
  ["r8169"]="kernel-firmware-realtek"
  ["rtw"]="kernel-firmware-realtek"
  ["realtek"]="kernel-firmware-realtek"

  # LiquidIO / Solarflare
  ["liquidio"]="kernel-firmware-liquidio"

  # Storage / HBA
  ["aacraid"]="kernel-firmware-aacraid"
  ["bfa"]="kernel-firmware-bfa"

  # DPAA2 / NXP
  ["dpaa2"]="kernel-firmware-dpaa2"

  # Prestera (Marvell Ethernet switches)
  ["prestera"]="kernel-firmware-prestera"

  # USB networking / misc USB NIC firmwares
  ["usbnet"]="kernel-firmware-usb-network"
  ["ueagle"]="kernel-firmware-ueagle"

  # Audio / DSP
  ["sof-audio"]="kernel-firmware-sof"
  ["snd_sof"]="kernel-firmware-sof"
  ["sound"]="kernel-firmware-sound"

  # Serial / misc
  ["serial"]="kernel-firmware-serial"

  # Generic network bundles
  ["network"]="kernel-firmware-network"

  # platform/board-specific blobs
  ["platform"]="kernel-firmware-platform"
)

# Identify required packages
required_pkgs=()
for driver in "${drivers[@]}"; do
  if [[ -n "${driver_to_pkg[$driver]:-}" ]]; then
    required_pkgs+=("${driver_to_pkg[$driver]}")
  fi
done

# Deduplication
required_pkgs=($(printf "%s\n" "${required_pkgs[@]}" | sort -u))

# Converting in a single string to replace firmware
firmware_string=""
for pkg in "${required_pkgs[@]}"; do
  firmware_string+="$pkg "
done
firmware_string="${firmware_string% }"
if [[ -z "$firmware_string" ]]; then
  firmware_string="linux-firmware"
fi
sed -i "s|linux-firmware|$firmware_string|g" pkgss.txt

# Which type of packages?
# Main package selection
case "$hardware:$howMuch" in
vm:min)
  sed -n '1p' pkgss.txt | tr ' ' '\n' | grep -v '^$' >pkglists.txt
  ;;
vm:max)
  sed -n '1p;3p' pkgss.txt | tr ' ' '\n' | grep -v '^$' >pkglists.txt
  ;;
hardware:min)
  sed -n '1,2p' pkgss.txt | head -n 2 | tr ' ' '\n' | grep -v '^$' >pkglists.txt
  ;;
hardware:max)
  # For hardware:max, we will add lines 5 and/or 6 later based on $extra
  sed -n '1,4p' pkgss.txt | tr ' ' '\n' | grep -v '^$' >pkglists.txt
  ;;
esac

# For hardware:max, add lines 5 and/or 6 based on $extra
if [[ "$hardware" == "hardware" && "$howMuch" == "max" ]]; then
  case "$extra" in
  laptop)
    # Add both line 5 and 6
    sed -n '5,6p' pkgss.txt | tr ' ' '\n' | grep -v '^$' >>pkglists.txt
    ;;
  bluetooth)
    # Add only line 5
    sed -n '5p' pkgss.txt | tr ' ' '\n' | grep -v '^$' >>pkglists.txt
    ;;
  none)
    # Do not add line 5 or 6
    ;;
  esac
fi

# tumbleweed repo
if [[ "$howMuch" == "max" ]]; then
  zypper --root /mnt --gpg-auto-import-keys ar -cf https://download.opensuse.org/tumbleweed/repo/non-oss/ repo-non-oss
  zypper --root /mnt --gpg-auto-import-keys ar -cf https://download.opensuse.org/update/tumbleweed/ repo-update
  zypper --root /mnt --gpg-auto-import-keys ar -cfp 90 http://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
  zypper --root /mnt --gpg-auto-import-keys ar -cf obs://home:iDesmI/openSUSE_Tumbleweed ananicy-cpp
  # zypper dup --from packman --allow-vendor-change
fi
zypper --root /mnt --gpg-auto-import-keys ar -cf https://download.opensuse.org/tumbleweed/repo/oss/ repo-oss
zypper --root /mnt ref -f

# Packages installation
echo "solver.onlyRequires = true" | sudo tee -a /mnt/etc/zypp/zypp.conf
xargs -a pkglists.txt -r zypper --root /mnt install -y

ESP_UUID=$(blkid -s UUID -o value "$part1")
ROOT_UUID=$(blkid -s UUID -o value "$part2")
cat >/mnt/etc/fstab <<EOF
# <file system>	<mount point>	<type>	<options>	<dump>	<pass>
UUID=$ESP_UUID	/boot/efi	vfat	defaults	0	2
UUID=$ROOT_UUID	/	btrfs	subvol=@,noatime,compress=zstd,space_cache=v2,discard=async	0	0
UUID=$ROOT_UUID	/home	btrfs	subvol=@home,noatime,compress=zstd,space_cache=v2,discard=async	0	0
UUID=$ROOT_UUID	/var	btrfs	subvol=@var,noatime,compress=zstd,space_cache=v2,discard=async	0	0
UUID=$ROOT_UUID	/.snapshots	btrfs	subvol=@snapshots,noatime,compress=zstd,space_cache=v2,discard=async	0	0
EOF

# Exporting variables for chroot
cat >/mnt/root/install.conf <<EOF
hostname=$hostname
hardware=$hardware
howMuch=$howMuch
extra=$extra
timezone=$timezone
username=$username
part2=$part2
encryption=$encryption
EOF
chmod 700 /mnt/root/install.conf

# Run chroot.sh
cp -L /etc/resolv.conf /mnt/etc/resolv.conf
cp chroot.sh /mnt/root/chroot.sh
chmod 700 /mnt/root/chroot.sh
chroot /mnt /bin/bash -s <<EOF
source /etc/profile
echo "root:$root_password" | chpasswd
groupadd wheel
if [[ "$howMuch" == "max" && "$hardware" == "hardware" ]]; then
  useradd -m -G users,wheel,systemd-journal,disk,video,audio,lp,kvm,libvirt,docker -s /bin/bash "$username"
else
  useradd -m -G users,wheel,systemd-journal,disk,video,audio,lp -s /bin/bash "$username"
fi
echo "$username:$user_password" | chpasswd
bash /root/chroot.sh
EOF

# Unmount and finalize
fuser -k /mnt || true
if mountpoint -q /mnt; then
  umount -R /mnt || {
    echo "Failed to unmount /mnt. Please check."
    exit 1
  }
fi
