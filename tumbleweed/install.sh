#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(dirname "$(realpath "$0")")
cd "$SCRIPT_DIR"

username=piyush

# Hostname
while true; do
  read -p "Hostname: " hostname
  if [[ ! "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]; then
    echo "Invalid hostname. Use 1-63 letters, digits, or hyphens (not starting or ending with hyphen)."
    continue
  fi
  break
done
sudo hostnamectl set-hostname "$hostname"
sudo sed -i "s/^127\.0\.1\.1.*/127.0.1.1    $hostname/" /etc/hosts

# Which type of install?
# First choice: vm or hardware
echo "Choose one:"
select hardware in "vm" "hardware"; do
  [[ -n $hardware ]] && break
  echo "Invalid choice. Please select 1 for vm or 2 for hardware."
done

# extra choice: laptop or bluetooth or none
if [[ "$hardware" == "hardware" ]]; then
  echo "Choose one:"
  select extra in "laptop" "bluetooth" "none"; do
    [[ -n $extra ]] && break
    echo "Invalid choice."
  done
else
  extra="none"
fi

# Which type of packages?
# Main package selection
case "$hardware" in
vm)
  sed -n '1p;2p' pkgs.txt | tr ' ' '\n' | grep -v '^$' >>pkglist.txt
  ;;
hardware)
  sed -n '1,3p' pkgs.txt | tr ' ' '\n' | grep -v '^$' >>pkglist.txt
  ;;
esac

# For hardware:max, add lines 5 and/or 6 based on $extra
if [[ "$hardware" == "hardware" ]]; then
  case "$extra" in
  laptop)
    sed -n '4,5p' pkgs.txt | tr ' ' '\n' | grep -v '^$' >>pkglist.txt
    ;;
  bluetooth)
    sed -n '4p' pkgs.txt | tr ' ' '\n' | grep -v '^$' >>pkglist.txt
    ;;
  none) ;;
  esac
fi

# sudo zypper ar -f https://download.opensuse.org/repositories/devel:languages:python/openSUSE_Tumbleweed/devel:languages:python.repo
# sudo zypper ar -f http://codecs.opensuse.org/openh264/openSUSE_Tumbleweed repo-openh264
sudo zypper --gpg-auto-import-keys ar -cf obs://home:iDesmI ananicy-cpp
sudo zypper --gpg-auto-import-keys ar -cf http://download.opensuse.org/update/tumbleweed/ repo-update
sudo zypper --gpg-auto-import-keys ar -cfp 90 http://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
sudo zypper --gpg-auto-import-keys refresh
sudo zypper rr repo-openh264
sudo zypper ref -f
sudo zypper dup --from packman --allow-vendor-change

xargs -a pkglist.txt sudo zypper install -y

sudo npm install -g corepack@latest
corepack enable
corepack prepare pnpm@latest --activate
pipx ensurepath
pipx install thefuck

cd "$(mktemp -d)"
# # wikiman
# RPM_URL=$(curl -s https://api.github.com/repos/filiparag/wikiman/releases/latest |
#   grep "browser_download_url" |
#   grep -E "wikiman.*\.rpm" |
#   cut -d '"' -f 4)
# curl -LO "$RPM_URL"
# RPM_FILE="${RPM_URL##*/}"
# sudo zypper in "$RPM_FILE"
# ly
cd ..
# git clone https://codeberg.org/fairyglade/ly.git
# cd ly
# zig build -Dinit_system=systemd -Dtarget=x86_64-linux-gnu -Denable_x11_support=false 2>&1 | tee ~/ly-build.log
# sudo zig build installexe -Dinit_system=systemd
# Iosevka
mkdir -p ~/.local/share/fonts/iosevka
cd ~/.local/share/fonts/iosevka
curl -LO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/IosevkaTerm.zip
unzip IosevkaTerm.zip
rm IosevkaTerm.zip
# Rustup
# curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# source $HOME/.cargo/env
export PATH="$HOME/.cargo/bin:$PATH"
rustup update stable
rustup default stable
# wl-clip-persist
git clone https://github.com/Linus789/wl-clip-persist.git
cd wl-clip-persist
cargo build --release
sudo install -Dm755 target/release/wl-clip-persist /usr/local/bin/wl-clip-persist
# External
python3 -m pip install --user --break-system-packages unp
cargo install caligula

# Copy config and dotfiles as the user
mkdir -p ~/Downloads ~/Desktop ~/Public ~/Templates ~/Videos ~/Pictures/Screenshots/temp ~/.config
mkdir -p ~/Documents/projects/work ~/Documents/projects/sandbox ~/Documents/personal/wiki
mkdir -p ~/.local/bin ~/.cache/cargo-target ~/.local/state/bash ~/.local/state/zsh ~/.local/share/wineprefixes
touch ~/.local/state/bash/history ~/.local/state/zsh/history ~/Documents/personal/wiki/index.txt

git clone https://github.com/zedonix/scripts.git ~/Documents/projects/default/scripts
git clone https://github.com/zedonix/dotfiles.git ~/Documents/projects/default/dotfiles
git clone https://github.com/zedonix/archsetup.git ~/Documents/projects/default/archsetup
git clone https://github.com/zedonix/notes.git ~/Documents/projects/default/notes
git clone https://github.com/zedonix/GruvboxGtk.git ~/Documents/projects/default/GruvboxGtk
git clone https://github.com/zedonix/GruvboxQT.git ~/Documents/projects/default/GruvboxQT

if [[ -d ~/Documents/projects/default/dotfiles ]]; then
  cp ~/Documents/projects/default/dotfiles/.config/sway/archLogo.png ~/Pictures/
  cp ~/Documents/projects/default/dotfiles/pics/* ~/Pictures/
  ln -sf ~/Documents/projects/default/dotfiles/.bashrc ~/.bashrc
  ln -sf ~/Documents/projects/default/dotfiles/.zshrc ~/.zshrc

  for link in ~/Documents/projects/default/dotfiles/.config/*; do
    ln -sf "$link" ~/.config/
  done
  for link in ~/Documents/projects/default/dotfiles/.copy/*; do
    cp -r "$link" ~/.config/
  done
  for link in ~/Documents/projects/default/scripts/bin/*; do
    ln -sf "$link" ~/.local/bin/
  done
fi

# Clone tpm
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

sudo env hardware="$hardware" extra="$extra" username="$username" bash <<'EOF'
  # User setup
  if [[ "$hardware" == "hardware" ]]; then
      usermod -aG wheel,video,audio,lp,scanner,kvm,libvirt,docker "$username"
  else
      usermod -aG wheel,video,audio,lp "$username"
  fi

  # Sudo Configuration
  echo "%wheel ALL=(ALL) ALL" >/etc/sudoers.d/wheel
  echo "Defaults timestamp_timeout=-1" >/etc/sudoers.d/timestamp
  chmod 440 /etc/sudoers.d/wheel /etc/sudoers.d/timestamp

  # Root .config
  mkdir -p ~/.config ~/.local/state/bash ~/.local/state/zsh
  echo '[[ -f ~/.bashrc ]] && . ~/.bashrc' >~/.bash_profile
  touch ~/.local/state/zsh/history ~/.local/state/bash/history
  ln -sf /home/$username/Documents/projects/default/dotfiles/.bashrc ~/.bashrc
  ln -sf /home/$username/Documents/projects/default/dotfiles/.zshrc ~/.zshrc
  ln -sf /home/$username/Documents/projects/default/dotfiles/.config/starship.toml ~/.config
  ln -sf /home/$username/Documents/projects/default/dotfiles/.config/nvim/ ~/.config

  # ly config
  # -e 's/^bigclock *= *.*/bigclock = en/' \
  # mkdir -p /etc/ly
  # cp extra/config.ini /etc/ly/
  # cp extra/pam.d/ly /etc/pam.d/
  # cp extra/ly.service /etc/systemd/system/
  # sed -i \
  #   -e 's/^allow_empty_password *= *.*/allow_empty_password = false/' \
  #   -e 's/^clear_password *= *.*/clear_password = true/' \
  #   -e 's/^clock *= *.*/clock = %a %d\/%m %H:%M/' \
  #   /etc/ly/config.ini
  # Greetd
  cp -f /home/$username/Documents/projects/default/dotfiles/config.toml /etc/greetd/

  # Setup Gruvbox theme
  THEME_SRC="/home/$username/Documents/projects/default/GruvboxQT"
  THEME_DEST="/usr/share/Kvantum/Gruvbox"
  mkdir -p "$THEME_DEST"
  cp "$THEME_SRC/gruvbox-kvantum.kvconfig" "$THEME_DEST/Gruvbox.kvconfig"
  cp "$THEME_SRC/gruvbox-kvantum.svg" "$THEME_DEST/Gruvbox.svg"

  THEME_SRC="/home/$username/Documents/projects/default/GruvboxGtk"
  THEME_DEST="/usr/share"
  cp -r "$THEME_SRC/themes/Gruvbox-Material-Dark" "$THEME_DEST/themes"
  cp -r "$THEME_SRC/icons/Gruvbox-Material-Dark" "$THEME_DEST/icons"

  # Anancy-cpp rules
  git clone --depth=1 https://github.com/RogueScholar/ananicy.git
  git clone --depth=1 https://github.com/CachyOS/ananicy-rules.git
  mkdir -p /etc/ananicy.d/roguescholar /etc/ananicy.d/zz-cachyos
  cp -r ananicy/ananicy.d/* /etc/ananicy.d/roguescholar/
  cp -r ananicy-rules/00-default/* /etc/ananicy.d/zz-cachyos/
  cp -r ananicy-rules/00-types.types /etc/ananicy.d/zz-cachyos/
  cp -r ananicy-rules/00-cgroups.cgroups /etc/ananicy.d/zz-cachyos/
  tee /etc/ananicy.d/ananicy.conf >/dev/null <<'ananicy'
check_freq = 15
cgroup_load = false
type_load = true
rule_load = true
apply_nice = true
apply_latnice = true
apply_ionice = true
apply_sched = true
apply_oom_score_adj = true
apply_cgroup = true
loglevel = info
log_applied_rule = false
cgroup_realtime_workaround = false
ananicy

# Firefox policy
mkdir -p /etc/firefox/policies
ln -sf "/home/$username/Documents/projects/default/dotfiles/policies.json" /etc/firefox/policies/policies.json

# tldr wiki setup
curl -L "https://raw.githubusercontent.com/filiparag/wikiman/master/Makefile" -o "wikiman-makefile"
make -f ./wikiman-makefile source-tldr
make -f ./wikiman-makefile source-install
make -f ./wikiman-makefile clean

# zram config
mkdir -p /etc/systemd/zram-generator.conf.d
printf "[zram0]\nzram-size=min(ram/2,4096)\ncompression-algorithm=zstd\nswap-priority=100\nfs-type=swap\n" | tee /etc/systemd/zram-generator.conf.d/00-zram.conf >/dev/null

# services
# rfkill unblock bluetooth
# modprobe btusb || true
systemctl enable NetworkManager NetworkManager-dispatcher greetd crond ananicy-cpp
systemctl set-default graphical.target
if [[ "$hardware" == "hardware" ]]; then
  systemctl enable fstrim.timer acpid libvirtd.socket cups ipp-usb docker.socket
  if [[ "$extra" == "laptop" || "$extra" == "bluetooth" ]]; then
    systemctl enable bluetooth
  fi
  if [[ "$extra" == "laptop" ]]; then
    systemctl enable tlp
  fi
fi
systemctl mask systemd-rfkill systemd-rfkill.socket
systemctl disable NetworkManager-wait-online.service systemd-networkd.service systemd-resolved getty@tty1.service

# prevent networkmanager from using systemd-resolved
# mkdir -p /etc/networkmanager/conf.d
# printf "[main]\nsystemd-resolved=false\n" | sudo tee /etc/networkmanager/conf.d/no-systemd-resolved.conf

# firewalld setup
# firewall-cmd --set-default-zone=public
firewall-cmd --permanent --remove-service=dhcpv6-client
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
# firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=dns
firewall-cmd --permanent --add-service=dhcp
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.0.0/24" accept'
firewall-cmd --set-log-denied=all
# Create and assign a zone for virbr0
firewall-cmd --permanent --new-zone=libvirt
firewall-cmd --permanent --zone=libvirt --add-interface=virbr0
# Allow DHCP (ports 67, 68 UDP) and DNS (53 UDP)
# firewall-cmd --permanent --zone=libvirt --add-port=67/udp
# firewall-cmd --permanent --zone=libvirt --add-port=68/udp
# firewall-cmd --permanent --zone=libvirt --add-port=53/udp
# Enable masquerading for routed traffic (NAT)
firewall-cmd --permanent --add-masquerade
firewall-cmd --reload
systemctl enable firewalld
# echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.d/99-firewalld.conf
# sysctl -p /etc/sysctl.d/99-firewalld.conf
EOF

# Configure static IP, gateway, and custom DNS
# sudo tee /etc/NetworkManager/conf.d/dns.conf >/dev/null <<EOF
# [main]
# dns=none
# systemd-resolved=false
# EOF
# sudo systemctl restart NetworkManager

# gsettings stuff
export $(dbus-launch)
gsettings set org.gnome.desktop.interface gtk-theme 'Gruvbox-Material-Dark'
gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
declare -A gsettings_keys=(
  ["org.virt-manager.virt-manager.new-vm firmware"]="uefi"
  ["org.virt-manager.virt-manager.new-vm cpu-default"]="host-passthrough"
  ["org.virt-manager.virt-manager.new-vm graphics-type"]="spice"
)

for key in "${!gsettings_keys[@]}"; do
  schema="${key% *}"
  subkey="${key#* }"
  value="${gsettings_keys[$key]}"

  if gsettings describe "$schema" "$subkey" &>/dev/null; then
    gsettings set "$schema" "$subkey" "$value"
  fi
done

# Libvirt setup
if pacman -Qq libvirt &>/dev/null; then
  sudo virsh net-autostart default
  sudo virsh net-start default
fi

# Flatpak setup
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# A cron job
(
  crontab -l 2>/dev/null
  echo "*/5 * * * * battery-alert.sh"
  echo "@daily $(which trash-empty) 30"
) | crontab -

echo "finally its done"
