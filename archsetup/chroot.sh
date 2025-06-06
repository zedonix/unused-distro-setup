#!/bin/bash
set -euo pipefail

# Configuration
timezone="Asia/Kolkata"

# Load variables from install.conf
source /root/install.conf

# --- Set hostname ---
echo "$hostname" >/etc/hostname
echo "127.0.0.1  localhost" >/etc/hosts
echo "::1        localhost" >>/etc/hosts
echo "127.0.1.1  $hostname.localdomain  $hostname" >>/etc/hosts

# --- Set root password ---
echo "root:$root_password" | chpasswd

# --- Create user and set password ---
if ! id "$user" &>/dev/null; then
    useradd -m -G wheel,storage,video,audio,kvm,libvirt,docker -s /bin/bash "$user"
    echo "$user:$user_password" | chpasswd
else
    echo "User $user already exists, skipping creation."
fi

# Local Setup
ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
hwclock --systohc
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >/etc/locale.conf

# Sudo Configuration
echo "%wheel ALL=(ALL) ALL" >/etc/sudoers.d/wheel
echo "Defaults timestamp_timeout=-1" >/etc/sudoers.d/timestamp
chmod 440 /etc/sudoers.d/wheel /etc/sudoers.d/timestamp

# Bootloader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
#sed -i 's/^#GRUB_DISABLE_SUBMENU=y/GRUB_DISABLE_SUBMENU=y/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Reflector and pacman Setup
sed -i '/^#Color$/c\Color' /etc/pacman.conf
mkdir -p /etc/xdg/reflector
cat >/etc/xdg/reflector/reflector.conf <<REFCONF
--save /etc/pacman.d/mirrorlist
--protocol https
--country India
--latest 10
--age 24
--sort rate
REFCONF
reflector --country 'India' --latest 10 --age 24 --sort rate --save /etc/pacman.d/mirrorlist
systemctl enable reflector.timer

# Copy config and dotfiles as the user
mv /root/git.conf /home/$user/
su - "$user" -c '
  source git.conf
  mkdir -p ~/Desktop ~/Downloads ~/Documents ~/Public ~/Templates ~/Videos ~/Pictures/Screenshots ~/.config ~/.local/state/bash

  git clone https://github.com/zedonix/scripts.git ~/.scripts
  git clone https://github.com/zedonix/dotfiles.git ~/.dotfiles
  git clone https://github.com/zedonix/archsetup.git ~/.archsetup
  git clone https://github.com/CachyOS/ananicy-rules.git ~/Downloads/ananicy-rules
  git clone https://github.com/zedonix/GruvboxGtk.git ~/Downloads/GruvboxGtk
  git clone https://github.com/zedonix/GruvboxQT.git ~/Downloads/GruvboxQT

  cp ~/.dotfiles/.config/sway/archLogo.png ~/Pictures/
  cp ~/.dotfiles/archpfp.png ~/Pictures/
  cp ~/.dotfiles/.local/share/themes/Gruvbox-Dark ~/.local/share/themes
  ln -sf ~/.dotfiles/.bashrc ~/.bashrc

  cd ~/.dotfiles/.config
  for link in $(ls); do
    ln -sf ~/.dotfiles/.config/$link ~/.config
  done
  git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

  # Git config
  git config --global user.email "$git_email"
  git config --global user.name "$git_username"
'
# Root .config
echo '[ -f ~/.bashrc ] && . ~/.bashrc' >/root/.bash_profile
mkdir /root/.config
ln -sf /home/"$user"/.dotfiles/.bashrc ~/.bashrc
ln -sf /home/"$user"/.dotfiles/.config/nvim/ ~/.config

# Setup QT theme
THEME_SRC="/home/piyush/Downloads/GruvboxQT/"
THEME_DEST="/usr/share/Kvantum/Gruvbox"
mkdir -p "$THEME_DEST"
cp "$THEME_SRC/gruvbox-kvantum.kvconfig" "$THEME_DEST/Gruvbox.kvconfig"
cp "$THEME_SRC/gruvbox-kvantum.svg" "$THEME_DEST/Gruvbox.svg"

# Install CachyOS Ananicy Rules
ANANICY_RULES_SRC="/home/$user/Downloads/ananicy-rules"
sudo mkdir -p /etc/ananicy.d

sudo cp -r "$ANANICY_RULES_SRC/00-default" /etc/ananicy.d/
sudo cp "$ANANICY_RULES_SRC/"*.rules /etc/ananicy.d/ 2>/dev/null || true
sudo cp "$ANANICY_RULES_SRC/00-cgroups.cgroups" /etc/ananicy.d/
sudo cp "$ANANICY_RULES_SRC/00-types.types" /etc/ananicy.d/
sudo cp "$ANANICY_RULES_SRC/ananicy.conf" /etc/ananicy.d/

sudo chmod -R 644 /etc/ananicy.d/*
sudo chmod 755 /etc/ananicy.d/00-default

# tldr wiki setup
curl -L "https://raw.githubusercontent.com/filiparag/wikiman/master/Makefile" -o "wikiman-makefile"
make -f ./wikiman-makefile source-tldr
make -f ./wikiman-makefile source-install
make -f ./wikiman-makefile clean

# Firefox policy
mkdir -p /etc/firefox/policies
ln -sf /home/"$user"/.dotfiles/policies.json /etc/firefox/policies/policies.json

# Delete variables
shred -u /root/install.conf
shred -u /home/$user/git.conf

# zram config
# Get total memory in MiB
TOTAL_MEM=$(awk '/MemTotal/ {print int($2 / 1024)}' /proc/meminfo)
ZRAM_SIZE=$((TOTAL_MEM / 2))

# Create zram config
mkdir -p /etc/systemd/zram-generator.conf.d

cat >/etc/systemd/zram-generator.conf.d/00-zram.conf <<EOF
[zram0]
zram-size = ${ZRAM_SIZE}
compression-algorithm = zstd #lzo-rle
swap-priority = 100
fs-type = swap
EOF

# Services
# acpid = ACPI events such as pressing the power button or closing a laptop's lid
# rfkill unblock bluetooth
# modprobe btusb || true
systemctl enable NetworkManager NetworkManager-dispatcher sshd fstrim.timer acpid cronie ananicy-cpp docker # tlp bluetooth libvirtd ollama
systemctl enable btrfs-scrub@-.timer btrfs-scrub@home.timer btrfs-scrub@var.timer
systemctl mask systemd-rfkill systemd-rfkill.socket
systemctl disable NetworkManager-wait-online.service systemd-networkd.service systemd-resolved

# Prevent NetworkManager from using systemd-resolved
sudo mkdir -p /etc/NetworkManager/conf.d
echo -e "[main]\nsystemd-resolved=false" | sudo tee /etc/NetworkManager/conf.d/no-systemd-resolved.conf >/dev/null

# Set DNS handling to 'default'
echo -e "[main]\ndns=default" | sudo tee /etc/NetworkManager/conf.d/dns.conf >/dev/null

# Clamav setup
freshclam
touch /var/log/clamav/freshclam.log
chown clamav:clamav /var/log/clamav/freshclam.log
systemctl enable clamav-daemon clamav-freshclam

# Clean up package cache and Wrapping up
pacman -Scc --noconfirm
